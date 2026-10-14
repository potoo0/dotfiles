#!/bin/sh

case "$1" in
    *.tar.gz|*.tgz)
        tar tzf "$1"
        ;;
    *.tar.bz2|*.tbz2)
        tar tjf "$1"
        ;;
    *.tar.xz|*.txz)
        tar tJf "$1"
        ;;
    *.zip)
        unzip -l "$1"
        ;;
    *.rar)
        unrar l "$1"
        ;;
    *.7z)
        7z l "$1"
        ;;
    *)
        head -n "${3:-200}" "$1"
        ;;
esac

