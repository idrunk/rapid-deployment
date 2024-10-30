set_source_mirror() {
    site="`select_dialog "[tencent]/ali/huawei/original" "Please choose one mirror source"`"
    if [ "$site" != "original" ]; then
        baseurl="`case "$site" in
            "tencent") echo "https://mirrors.cloud.tencent.com/ubuntu" ;;
            "ali") echo "https://mirrors.aliyun.com/ubuntu" ;;
            "huawei") echo "https://repo.huaweicloud.com/ubuntu" ;;
        esac`"
        [ ! -f /etc/apt/sources.list.bak ] && bak=.bak
        sed -E "s|https?://[^/]+/ubuntu|$baseurl|g" -i"$bak" /etc/apt/sources.list
        apt-get update -y
    fi
}