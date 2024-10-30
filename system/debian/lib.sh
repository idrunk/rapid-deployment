set_source_mirror() {
    site="`select_dialog "[tencent]/ali/huawei/original" "Please choose one mirror source"`"
    if [ "$site" != "original" ]; then
        baseurl="`case "$site" in
            "tencent") echo "https://mirrors.cloud.tencent.com/debian" ;;
            "ali") echo "https://mirrors.aliyun.com/debian" ;;
            "huawei") echo "https://repo.huaweicloud.com/debian" ;;
        esac`"
        codename="`grep -oP "(?<=VERSION_CODENAME=).+" /etc/os-release`"
        cat << EOF > /etc/apt/sources.list
deb $baseurl/ $codename main contrib non-free non-free-firmware
# deb-src $baseurl/ $codename main contrib non-free non-free-firmware

deb $baseurl/ $codename-updates main contrib non-free non-free-firmware
# deb-src $baseurl/ $codename-updates main contrib non-free non-free-firmware

deb $baseurl/ $codename-backports main contrib non-free non-free-firmware
# deb-src $baseurl/ $codename-backports main contrib non-free non-free-firmware

deb https://security.debian.org/debian-security $codename-security main contrib non-free non-free-firmware
# deb-src https://security.debian.org/debian-security $codename-security main contrib non-free non-free-firmware
EOF
        apt-get update -y
    fi
}

set_ip4_dns() {
    # ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    echo "You can edit in /etc/netplan/00-installer-config.yaml, and then run 'netplan apply'"
    echo "The hierarchy should be 'ethernets.enp1s0.nameservers.addresses=[${1// /,}]'"
}