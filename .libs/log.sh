#!/bin/bash

source "`dirname "$0"`/env.sh"

export LOG_DIR="$LIB_DIR/.logs"
logfile="$LOG_DIR/zw.log"
rotate_threshold=$((1*1024*1024)) # 1MiB in bytes

log() {
    if [ ! -x "$1" ]; then
        echo "Arg1 must be an excutable file path." >&2
        exit 1
    fi
    [ ! -d "$LOG_DIR" ] && mkdir -p "$LOG_DIR"    
    head=""
    if [ -f "$logfile" ]; then
        bytes="`stat --printf="%s" "$logfile"`"
        if [ $bytes -ge $rotate_threshold ]; then
            rotate
        else
            head+=$'\n\n\n'
            [ -n "`tail -c 1 "$logfile"`" ] && head+=$'\n'
        fi
    fi
    head+="[`date --rfc-3339=seconds`] Start working by '$@':"
    echo "$head" >> "$logfile"
    "$@" |& tee -a "$logfile"
}

rotate() {
    mv -fv "$logfile" "$LOG_DIR/zw-`date '+%Y%m%dT%H%M'`.log"
    echo "Rotate completed."
}

gzip_rotated() {
    find "$LOG_DIR" -name zw-*.log -exec bash -c 'file="{}"; tar -czvf "$file.tgz" -C"$LOG_DIR/" "$(echo "${file/"$LOG_DIR/"/}")"; rm -fv "$file"' \;
    echo "Compression completed."
}

method="$1"
[[ "$method" == --* ]] && shift
case "$method" in
    "--rotate") rotate ;;
    "--gzip") gzip_rotated ;;
    *) log "$@" ;;
esac