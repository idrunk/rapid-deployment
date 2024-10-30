try_load_os_libs "$LIB_DIR/os" pkg-lib.sh

# $1: $url
name_from_url() {
    basename "$1" | grep -oP "^[^?]+"
}

pkg_list_of_os() {
    os_like="`os_like`"
    os_name=(`os_name`)
    find "$SUBJ_DIR" -regextype egrep -regex "$SUBJ_DIR(/($os_like|${os_name[0]}(${os_name[1]})?))?/pkg-url.list" -exec sh -c "envsubst < '{}' | sed 's/\r//' | grep -P '^\S+(\s+https?://.+)?$'" \;
}

pkg_url_list() {
    find "$SUBJ_DIR" -name pkg-url.list -exec sh -c "envsubst < '{}' | grep -oP 'https?://.+$' | sed 's/\r//'" \; | sort -u
}

pkg_download() {
    url="$1"
    target="$2/`name_from_url $url`"
    if [ -e "$target" ]; then
        echo "File "$target" was already exists, will not be download again"
        return 0
    fi
    echo "'$url' will download to '$target'"
    curl -L "$url" -o "$target"
}

pkg_download_list() {
    pkg_url_list | while read url; do
        pkg_download "$url" "$LIB_DIR/.packages"
    done
}

pkg_remove_list() {
    pkg_url_list | while read url; do
        target="$LIB_DIR/.packages/`name_from_url "$url"`"
        rm -fv "$target"
    done
}

# $1: $pack_target_root
pkg_pack_list_to() {
    packages_target="$1/.libs/.packages/"
    pkg_url_list | while read url; do
        src="$LIB_DIR/.packages/`name_from_url "$url"`"
        /bin/cp -rnv "$src" "$packages_target"
    done
}

label_to_pkg() {
    label="$1"
    flag="$2" # -n
    if [ "$flag" == "-n" ]; then # get pkg name
        pkg_list_of_os | grep -oP "(?<=^$label)\s+.+?(?=(\.(rpm|deb))?($|\?))" | sed -Ee "s/^.+\/([^/]+)/\1/" -e 's/\r//'
    else # get package absolute path
        pkg_list_of_os | grep -oP "(?<=^$label)\s+[^?]+" | sed -Ee "s/^.+(\/[^/]+)/${LIB_DIR//\//\\/}\/.packages\1/" -e 's/\r//'
    fi
}

pkg_install() {
    for label in $@; do
        pkg="`label_to_pkg "$label"`"
        [ -n "$pkg" ] && os_pkg_install "$pkg"
    done
}

pkg_uninstall() {
    for label in $@; do
        os_pkg_uninstall "$label"
    done
}

pkgm_install() {
    for label in $@; do
        pkg="`label_to_pkg "$label"`"
        os_pkgm_install "${pkg:-$label}"
    done
}

pkgm_uninstall() {
    for label in $@; do
        os_pkgm_uninstall "$label"
    done
}

pkg_label_list_of_os() {
    pkg_list_of_os | grep -oP "^\S+"
}

pkg_install_list() {
    [ "$1" == "-m" ] && pkgm_install `pkg_label_list_of_os | xargs` || pkg_install `pkg_label_list_of_os | xargs`
}

pkg_uninstall_list() {
    [ "$1" == "-m" ] && pkgm_uninstall `pkg_label_list_of_os | tac | xargs` || pkg_uninstall `pkg_label_list_of_os | tac | xargs`
}

pkg_handle() {
    case "$1" in
    "--init-env")
        [ -e "$INSTL_SUBJ_LOCK" ] && return
        func_exists __init_env && __init_env
        [ -f "$SUBJ_ENV" -a -d "$INSTL_SUBJ_DIR" ] && rewrite_to "$INSTL_SUBJ_DIR/.env" "$SUBJ_ENV"
    ;;
    "--install")
        func_exists __install && __install
        func_exists __after_install && __after_install || cat_subj_env
        [ -d "$INSTL_SUBJ_DIR" ] && touch "$INSTL_SUBJ_LOCK"
    ;;
    "--uninstall")
        func_exists __uninstall && __uninstall
        [ -e "$INSTL_SUBJ_LOCK" ] && rm -rfv "$INSTL_SUBJ_LOCK"
    ;;
    "--clear-data")
        if [ -e "$INSTL_SUBJ_LOCK" ]; then
            echo "Subject '$SUBJ_NAME' was locked, please uninstall first then do clear." >&2
            return 1
        fi
        func_exists __clear_data && __clear_data || subj_clear
    ;;
    esac
}