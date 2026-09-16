#!/usr/bin/env bash

# Cli for MicroBin (https://github.com/szabodanika/microbin)
# Add to rc file:
#   export MICROBIN_URL=https://self-hosted-microbin
#   export MICROBIN_EXPIRATION=72hour
#   export MICROBIN_PRIVACY=public
#   source "$HOME/.local/lib/shell/microbin.sh" 2>/dev/null || true
mb() {
    local action="${1:-}" bad=0 rc=2
    local base="${MICROBIN_URL:-https://microbin.eu}" expiration="${MICROBIN_EXPIRATION:-24hour}" privacy="${MICROBIN_PRIVACY:-unlisted}"
    base="${base%/}"

    case "$action" in
        put) (( $# <= 2 )) || bad=1; (( $# == 2 )) || [[ ! -t 0 ]] || bad=1 ;;
        get) (( $# == 2 || $# == 3 )) || bad=1 ;;
        list) (( $# == 1 )) || bad=1 ;;
        help|--help|-h) bad=1; rc=0 ;;
        *) bad=1 ;;
    esac
    if (( bad )); then
        cat <<'EOF'
Usage:
  command | mb put
  mb put < input-file
  mb put <file-path>
  mb get <ID-or-share-URL> [output-file]
  mb list

Environment:
  MICROBIN_URL                 Server URL
  MICROBIN_EXPIRATION          1min, 10min, 1hour, 24hour, 3days, or 1week
  MICROBIN_PRIVACY             public or unlisted
  MICROBIN_UPLOADER_PASSWORD   Optional uploader password

Examples:
  printf '%s\n' 'hello world' | mb put
  mb put < notes.txt
  mb put ./archive.tar.gz
  mb get fox-cat-dog
  mb get fox-cat-dog ./output
  mb list
EOF
        return "$rc"
    fi
    shift

    case "$action" in
        put)
            local result http_status redirect file="${1:-}"
            local -a form=(--form-string "expiration=$expiration" --form-string "privacy=$privacy" --form-string burn_after=0) payload
            [[ -z "${MICROBIN_UPLOADER_PASSWORD:-}" ]] || form+=(--form-string "uploader_password=$MICROBIN_UPLOADER_PASSWORD")
            if [[ -n "$file" ]]; then
                [[ -f "$file" ]] || { printf 'Not a regular file: %s\n' "$file" >&2; return 1; }
                payload=(--form-string content= --form "file=@$file")
            else
                payload=(--form-string syntax_highlight=auto --form 'content=<-')
            fi
            result="$(command curl -fsS -o /dev/null -w $'%{http_code}\n%{redirect_url}' "${form[@]}" "${payload[@]}" "$base/upload")" || return
            http_status="${result%%$'\n'*}"; redirect="${result#*$'\n'}"
            case "$http_status" in 301|302|303|307|308) ;; *) printf 'Unexpected HTTP status: %s\n' "$http_status" >&2; return 1 ;; esac
            [[ -n "$redirect" ]] || { printf 'MicroBin did not return an upload URL.\n' >&2; return 1; }
            printf '%s\n' "$redirect"
            ;;

        get)
            local ref="$1" output="${2:-}" value slug url type probe
            local -a options=(-fLsS)
            case "$ref" in
                http://*/file/*|https://*/file/*) type=file; url="$ref" ;;
                http://*/raw/*|https://*/raw/*) type=text; url="$ref" ;;
                *)
                    value="${ref%%#*}"; value="${value%%\?*}"; value="${value%/}"; slug="${value##*/}"
                    [[ -n "$slug" ]] || { printf 'Unable to extract an ID from: %s\n' "$ref" >&2; return 1; }
                    probe="$(command curl -sS -o /dev/null -w '%{http_code}' -H 'Range: bytes=0-0' "$base/file/$slug")" || return
                    if [[ "$probe" == 200 || "$probe" == 206 ]]; then type=file; url="$base/file/$slug"
                    else type=text; url="$base/raw/$slug"; fi
                    ;;
            esac
            if [[ -n "$output" ]]; then options+=(-o "$output")
            elif [[ "$type" == file ]]; then options+=(-OJ); fi
            command curl "${options[@]}" "$url"
            ;;

        list)
            local html
            html="$(command curl -fLsS "$base/list")" || return
            printf '%s\n' "$html" | command awk '
                BEGIN { RS="</tr>"; print "ID\tTYPE" }
                /href="[^"]*\/upload\// {
                    row=$0; gsub(/[[:space:]]+/, " ", row)
                    id=row; sub(/^.*href="[^"]*\/upload\//, "", id); sub(/".*$/, "", id)
                    text=row~/href="[^"]*\/raw\//
                    file=row~/href="[^"]*\/file\// || row~/>[[:space:]]*[0-9]+ Files[[:space:]]*</
                    url=row~/href="[^"]*\/url\//
                    type=url ? "url" : text&&file ? "text+file" : file ? "file" : "text"
                    print id "\t" type
                }'
            ;;
    esac
}
