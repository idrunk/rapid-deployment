get_ip4_list_local() {
    ips="`netsh interface ipv4 show route | grep -aoP '\b(?!127)\d+(\.\d+){2}\.(?!255|0)\d+\b(?=/\d+)'`"
    echo "$ips" | grep -P '\b(?!1)\d+$'
    echo "$ips" | grep -vP '\b(?!1)\d+$'
}

get_ip6_list() {
    netsh interface ipv6 show route | grep -aoP '\b[23][\da-f]+(:[\da-f]+){4,7}'
}

portproxy() {
    target=v6tov4
    if [[ "$1" == v*tov* ]]; then
        target=$1
        shift
    fi
    listenport="$1"
    listenaddress="$2"
    connectport="$3"
    connectaddress="$4"
    netsh interface portproxy add $target listenport="$listenport" listenaddress="$listenaddress" connectport="$connectport" connectaddress="$connectaddress"
}

portproxy_del() {
    target=v6tov4
    if [[ "$1" == v*tov* ]]; then
        target=$1
        shift
    fi
    listenport="$1"
    listenaddress="$2"
    netsh interface portproxy delete $target listenport="$listenport" listenaddress="$listenaddress"
}

portproxy_showall() {
    netsh interface portproxy show all
}