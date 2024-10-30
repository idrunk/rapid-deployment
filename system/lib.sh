set_hostname() {
    read -p "Modify the hostname (Directly enter if don't want to modify) [`hostname`]: " name
    if [ -n "${name// /}" ]; then
        echo "${name// /}" > /etc/hostname
    fi
}

set_tz_shanghai() {
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

set_dns() {
    mapping="
tencent     119.29.29.29
baidu       180.76.76.76
ali         223.5.5.5
huawei      122.112.208.1
"
    pool="
tencent     'tencent baidu ali huawei'
baidu       'baidu tencent ali huawei'
ali         'ali tencent baidu huawei'
huawei      'huawei tencent baidu ali'
"
    while read line <&3; do
        readarray -t parts < <(xargs -n1 <<< "$line")
        pool="`echo "$pool" | sed -r "s/('| )${parts[0]}\b/\1${parts[1]}/g"`"
    done 3< <(echo "$mapping" | grep -P "^\w+\s+.+")
    echo "The dns pool mapping:$pool"    
    type="$(select_dialog "`echo "$pool" | grep -Po "^\w+" | paste -s -d "/" | sed -r "s/\w+/[\0]/"`" "Choose one order type dns pool you want to set:")"
    set_ip4_dns "`echo "$pool" | grep -P "^$type\b" | sed -r "s/^\w+\s+'|'$//g"`"
}

disable_selinux() {
    if func_exists getenforce && getenforce | grep -qi disabled; then
        setenforce 0
        sed -ri "s/^\s*(SELINUX=(enforcing|permissive))/# \1\nSELINUX=disabled/" /etc/selinux/config
    fi
}

disable_swap() {
    if [ -n "`swapon --show`" ]; then
        sed -i '/swap/s/^/#/' /etc/fstab
        swapoff -a
    fi
}

enable_cgroup2() {
    if ! grep -q cgroup2 /proc/filesystems; then
        sed -i -e 's/^GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1 /' /etc/default/grub
        update-grub
    fi
}

enable_cockpit() {
    pkgm_install cockpit
    systemctl enable cockpit.socket --now
    cockpit_port=`assemble_port $COCKPIT_TOP_PORT`
    sed -ri "s/(ListenStream=)[0-9]+/\1$cockpit_port/" /etc/systemd/system/sockets.target.wants/cockpit.socket
    /bin/cp -fv /etc/systemd/system/sockets.target.wants/cockpit.socket /lib/systemd/system/cockpit.socket
    systemctl daemon-reload
    [ -f /etc/cockpit/disallowed-users ] && mv /etc/cockpit/disallowed-users /etc/cockpit/disallowed-users.bak
    systemctl restart cockpit.socket
    systemctl restart cockpit
    echo "Cockpit enabled, you can access via: http://`get_ip4_local`:$cockpit_port"
}

remove_cockpit() {
    systemctl disable cockpit.socket --now
    systemctl disable cockpit --now
    pkgm_uninstall cockpit
}

set_sshd_config() {
    conf="/etc/ssh/sshd_config.d/00-zw.conf"
    match_replace_or_append "$conf" "^\s*PubkeyAuthentication\s.+$" "PubkeyAuthentication `select_dialog "[yes]/no" "Allow pubkey to login?"`"
    match_replace_or_append "$conf" "^\s*PasswordAuthentication\s.+$" "PasswordAuthentication `select_dialog "yes/no" "Allow password to login?"`"
    match_replace_or_append "$conf" "^\s*PermitRootLogin\s.+$" "PermitRootLogin `select_dialog "yes/[no]" "Allow root login?"`"
    confirm_dialog "yes/[no]" "Want to set ClientAliveInterval to 60 secs?" && match_replace_or_append "$conf" "^\s*ClientAliveInterval\s.+$" "ClientAliveInterval 60"
    os_like | grep -q rhel && systemctl restart sshd || systemctl restart ssh
}

user_list_password_completion() {
    list_file="$1"
    [ ! -f "$list_file" ] && return 1
    lines=""
    local IFS=$'\n'
    for line in `grep -v "^\s*$" "$list_file" | sed "s/\r//"`; do
        [ -n "$lines" ] && lines+=$'\n'
        lines+="$line"
        if echo "$line" | grep -qP "^\S+$"; then
            lines+="        "`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`
        fi
    done
    tee "$list_file" <<< "$lines"
}

create_sys_user() {
    userinfo=(`echo "$1" | xargs -d ";"`)
    userattrs="`echo "${userinfo[1]}" | tr "," "\n"`"
    user_and_group=(`echo "${userinfo[0]}" | xargs -d ":"`)
    user="${user_and_group[0]}"
    groups=(`echo "${user_and_group[1]}" | xargs -d ","`)
    pubkey="${3:-$2}"
    ! echo "$pubkey" | grep -qP "^ssh-\w+\s+" && pubkey=""
    [ -z "$3" -a -n "$pubkey" ] && password="" || password="$2"

    echo "$user '$password' '$pubkey'"
    exists_user="`grep -oP "^$user\b" /etc/passwd`"
    [ -n "$exists_user" ] && ! confirm_dialog "y/n" "User '$exists_user' already exists, do you want to continue set groups and password?" && return

    arg_m=(-Ms '/usr/sbin/nologin')
    if echo "$userattrs" | grep -q ^login$; then
        arg_m=(-ms '/bin/bash')
        if echo "$userattrs" | grep -q ^sudo; then
            nopass=""
            echo "$userattrs" | grep -q ^sudo_nopass$ && nopass="NOPASSWD:"
            sudoer="$user ALL=(ALL) $nopass ALL"
            match_replace_or_append "/etc/sudoers.d/zwsudoers" "^\s*$user\s.+$" "$sudoer"
        fi
    fi
    arg_u="-U"
    if grep -qP "^$user\b" /etc/group; then
        arg_u="-g $user"
    fi
    [ -z "$exists_user" ] && useradd $arg_u "${arg_m[@]}" "$user"

    for group in "${groups[@]}"; do
        groupadd -f "$group"
        usermod -aG "$group" "$user"
    done

    if [ -z "$password" ]; then
        # directly set to '*' to allow private key login, if not specified and never set yet
        passwd -S test11 2>/dev/null | grep -qP "^\w+\s+L" && usermod -p '*' "$user"
    else
        echo "$user:$password" | chpasswd
    fi
    
    if [ -n "$pubkey" -a -d "/home/$user" ] && ! grep -sqF "$pubkey" "/home/$user/.ssh/authorized_keys"; then
        mkdir -p "/home/$user/.ssh"
        echo "$pubkey" >> "/home/$user/.ssh/authorized_keys"
        chmod -R 0700 "/home/$user/.ssh"
        chmod 0600 "/home/$user/.ssh/authorized_keys"
        chown -R "$user:$user" "/home/$user/.ssh"
    fi
}

delete_sys_user() {
    userdel "$1"
    sed -ri "s/^\s*$1\s.+$//g" "/etc/sudoers.d/zwsudoers"
}

get_default_gateway() {
    ip route list default | grep -oP "(?<=via )\d+(\.\d+){3}"
}

get_default_addr() {
    ip route list default | grep -oP "(?<=dev\s)\S+" | xargs ip addr show
}

get_ip4_local() {
    get_default_addr | grep -Pom 1 "(?<=\binet\s)\d+(\.\d+){3}(?=/\d+\b)"
}

get_ip6() {
    get_default_addr | grep -Pom 1 "(?<=\binet6\s)[\da-f]+(:[\da-f]+){5,8}(?=/\d+\b)"
}

get_ip4_list_local() {
    get_ip4_local
}

get_ip6_list() {
    get_ip6
}

try_load_os_libs "$SYSTEM_DIR"
