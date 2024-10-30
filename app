#!/bin/bash
libdir="`dirname "$0"`/.libs"
"$libdir/log.sh" "$libdir/app.sh" "$@"