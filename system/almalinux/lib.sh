set_source_mirror() {
    site="`select_dialog "[tencent]/ali/huawei/original" "Please choose one mirror source"`"
    if [ "$site" != "original" ]; then
        baseurl="`case "$site" in
            "tencent") echo "https://mirrors.cloud.tencent.com" ;;
            "ali") echo "https://mirrors.aliyun.com" ;;
            "huawei") echo "https://repo.huaweicloud.com" ;;
        esac`"
        [ ! -f /etc/yum.repos.d/almalinux-appstream.repo.bak ] && bak=.bak
        sed -Ee "s|^mirrorlist=.+appstream$|# \0|g" -Ee "s|^(#\s*)?baseurl=https?://[^/]+/almalinux/|baseurl=$baseurl/almalinux/|g" -i"$bak" /etc/yum.repos.d/almalinux*.repo
        if [ ! -f /etc/yum.repos.d/epel.repo.bak ]; then
            dnf install epel-release -y
            epelbak=.bak
        fi
        sed -Ee "s|^metalink=|# \0|g" -Ee "s|^(#\s*)?baseurl=https?://[^/]+/(pub/)?epel/|baseurl=$baseurl/epel/|g" -i"$epelbak" /etc/yum.repos.d/epel.repo
        dnf update -y
    fi
}