set_ip4_dns() {
    conn="`nmcli c show | grep -m 1 ethernet | grep -oP "^\w+"`"
    if [ -n "$conn" ]; then
        echo "Dns setted, suggest you set a static ip by using:
nmcli c mod $conn ipv4.method manual
nmcli c mod $conn ipv4.gateway `get_default_gateway`
nmcli c mod $conn ipv4.addresses `get_ip4_local`/24
nmcli networking off && nmcli networking on"
        nmcli c mod "$conn" ipv4.dns "$1"        
    fi
}