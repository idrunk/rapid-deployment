os_like() {
    if [ ! -e "/etc/os-release" ]; then
        echo win
    elif [ -n "`cat /etc/os-release | grep -om 1 rhel`" ]; then
        echo rhel
    elif [ -n "`cat /etc/os-release | grep -om 1 debian`" ]; then
        echo debian
    else
        echo unknow
    fi
}

os_name() {
    cat /etc/os-release 2> /dev/null | grep -P "^(ID|VERSION_ID)=.+" | sed -r "s/^\w+=\"?|(\.[0-9]+)?\"$//g" | sort -r | sed -r ':a; N; $!ba; s/\n/ /g'
}

try_load_os_libs() {
    os_root="$1"
    lib_name="${2:-lib.sh}"
    os_like="`os_like`"
    os_name=(`os_name`)
    if [ -f "$os_root/$os_like/$lib_name" ]; then
        source "$os_root/$os_like/$lib_name"
    fi
    [ ${#os_name[@]} -eq 0 ] && return
    if [ -f "$os_root/${os_name[0]}/$lib_name" ]; then
        source "$os_root/${os_name[0]}/$lib_name"
    fi
    if [ -f "$os_root/${os_name[0]}${os_name[1]}/$lib_name" ]; then
        source "$os_root/${os_name[0]}${os_name[1]}/$lib_name"
    fi
}

func_exists() {
    type -t "$1" | grep -q "^function$"
}

call_with_input_args() {
    func="$1"
    read -p "Args for func $func(): " args
    $func $args
}

match_replace_or_append() {
    file="$1"
    pattern="$2"
    newline="$3"
    if [ -z "$newline" ]; then
        [ -f "$file" ] && sed -ri "/$pattern/d" "$file"
    elif grep -sqP "$pattern" "$file"; then
        [ -f "$file" ] && sed -ri "s/$pattern/$newline/" "$file"
    else
        mkdir -p "`dirname "$file"`"
        echo "$newline" >> "$file"
    fi
}

rewrite_to() {
    target="$1"
    source="$2"
    flag="$3" # -n: not overwrite
    if [[ "$2" == -* ]]; then
        source=""
        flag="$2"
    fi
    if [ -t 0 -a -z "$source" ]; then
        rm -rfv "$target"
        return
    fi
    [ "$flag" == "-n" -a -e "$target" ] && return 1
    target_dir="`dirname "$target"`"
    [ ! -d "$target_dir" ] && mkdir -p "$target_dir"
    if [ -t 0 ]; then
        /bin/cp -rfv "$source" "$target"
    else
        cat > "$target"
    fi
}

rewrite_to_try_load_env() {
    ! rewrite_to "$@" && return 1
    try_load_env "$1"
}

subj_clear() {
    rm -rfv "$INSTL_SUBJ_DIR"
    rm -rfv "$SUBJ_ENV"
}

assemble_host_port() {
    echo "$BASE_DOMAIN:`assemble_port $1`"
}

assemble_port() {
    echo "${BASE_PORT:-99}$1"
}

# $1: $operation, $2: determine based on $1
pack_handle() {
    case "$1" in
    "--download")
        func_exists pkg_download_list && pkg_download_list
        func_exists __before_docker_download && __before_docker_download "$@"
        func_exists docker_pull_save_list && docker_pull_save_list
        func_exists __pack_dependent && __pack_dependent "$@"
    ;;
    "--remove")
        pkg_remove_list
        docker_remove_pkg_list
    ;;
    "--pack-to")
        pack_handle "--download" "$2"
        /bin/cp -rnv "$SUBJ_DIR" "$2/"
        func_exists pkg_pack_list_to && pkg_pack_list_to "$2"
        func_exists docker_pack_list_to && docker_pack_list_to "$2"
        func_exists __pack_dependent && __pack_dependent "$@"
    ;;
    esac
}
