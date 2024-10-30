#!/bin/bash

source "`dirname "$0"`/../.libs/env.sh"
source "$LIB_DIR/gui.sh"
source "$LIB_DIR/lib.sh"
source "$LIB_DIR/pkg-lib.sh"
source "$LIB_DIR/docker-lib.sh"

init_env() {    
    check_confirm_envs "$SUBJ_ENV" CONTAINERD_DATA_ROOT/
}

k8s_install() {
    os_like="`os_like`"
    case "$os_like" in
        "rhel") pkg_install container-selinux containerd.io libnetfilter_cthelper libnetfilter_cttimeout libnetfilter_queue conntrack socat ;;
        "debian")
            os_name=(`os_name`)
            [ "${os_name[0]}" == "debian" ] && pkgm_install libnfnetlink0 iptables
            pkg_install containerd.io conntrack socat
        ;;
        *) return
        ;;
    esac

    containerd config default | sed -re 's/(SystemdCgroup\s*=\s*)[a-z]+/\1true/' \
        -e 's|root = "/var/lib/containerd"|root = "$CONTAINERD_DATA_ROOT"|' \
        -re 's|(registry\.k8s\.io/pause:)[0-9.]+|\1$K8S_PAUSE_VERSION|' \
        | envsubst > /etc/containerd/config.toml
    systemctl restart containerd
    # runc
    mkdir -p /usr/local/sbin/runc
    install -m 755 "`label_to_pkg runc`" /usr/local/sbin/runc/
    # cni
    mkdir -p "/opt/cni/bin"
    tar -C "/opt/cni/bin" -xzf "`label_to_pkg cni-plugins`"
    # crictl
    mkdir -p "$INSTL_SUBJ_DIR"
    tar -C "$INSTL_SUBJ_DIR" -xzf "`label_to_pkg crictl`"
    rewrite_to /etc/crictl.yaml < "$SUBJ_RES_DIR/crictl.yaml"
    # helm
    tar -C "$INSTL_SUBJ_DIR" -xzf "`label_to_pkg helm`" --strip-components 1
    # kubeadm,kubelet,kubectl
    install -o root -g root -m 0755 "$LIB_DIR/.packages/"{kubeadm,kubelet,kubectl} "${INSTL_SUBJ_DIR}/"
    ln -sf "$INSTL_SUBJ_DIR/"{crictl,helm,kubelet,kubeadm,kubectl} /usr/local/bin/
    rewrite_to /etc/systemd/system/kubelet.service < <(envsubst < "$SUBJ_RES_DIR/kubelet.service")
    rewrite_to /etc/systemd/system/kubelet.service.d/10-kubeadm.conf < <(sed "s|/usr/bin|${INSTL_SUBJ_DIR}|g" "$SUBJ_RES_DIR/10-kubeadm.conf")
    systemctl enable --now kubelet
    # Init control plane
    if [ "$os_like" == "rhel" ] && ! firewall-cmd --list-port | grep -q '6443'; then
        firewall-cmd --add-port 6443/tcp --add-port 10250/tcp --permanent --zone=public
        firewall-cmd --reload
    fi
    if [ -n "$KUBE_JOIN_COMMAND" ]; then
        join_command="`base64 -d <<< "$KUBE_JOIN_COMMAND"`"
        node_name="`echo "$join_command" | grep -oP "(?<=join\s)\S+"`"
        if confirm_dialog "[y]/n" "Do you want to join the cluster with node '$node_name'? (Type in 'n' if want to init a cluster)"; then
            join_cluster "$join_command"
            return
        fi
    fi
    init_control_plane
}

init_control_plane() {
    echo "Hostname '`hostname`' will be the control-plane-endpoint, and the following is the hosts mapping:"
    [ ! -f "/etc/hosts.bak" ] && /bin/cp -f /etc/hosts /etc/hosts.bak
    confirm_hosts
    # log the edited hosts to convenient for setting up other nodes
    CONTROL_PLANE_HOSTS="`base64 -w 0 < /etc/hosts`"
    # Load images
    k8s_load_list
    kubeadm init --control-plane-endpoint "`hostname`" --pod-network-cidr 10.244.0.0/16 --kubernetes-version=$KUBERNETES_VERSION --v=5
    home_token
    confirm_dialog "[y]/n" "Want to remove taint 'control-plane'?" && kubectl taint nodes --all node-role.kubernetes.io/control-plane-
    if confirm_dialog "[y]/n" "Want to use kuberouter?"; then
        kubectl -n kube-system delete ds kube-proxy
        sed -r 's/(imagePullPolicy: )Always/\1IfNotPresent/g' "$SUBJ_RES_DIR/kubeadm-kuberouter-all-features.yaml" > "$INSTL_SUBJ_DIR/kubeadm-kuberouter-all-features.yaml"
        kubectl apply -f "$INSTL_SUBJ_DIR/kubeadm-kuberouter-all-features.yaml"
    fi
    sed 's/(--service-cluster-ip-range[^\n]+)/\1\n    - --service-node-port-range=1-65535/' -ri /etc/kubernetes/manifests/kube-apiserver.yaml
    KUBE_JOIN_COMMAND="`kubeadm token create --print-join-command | base64 -w 0`"
    persistence_env "$SUBJ_ENV" "KUBE_JOIN_COMMAND=$KUBE_JOIN_COMMAND" "CONTROL_PLANE_HOSTS=$CONTROL_PLANE_HOSTS"
    echo "Kubernetes installation completed and initialized as control-plane node."
}

join_cluster() {
    echo "Please confirm the hosts mapping first:"
    confirm_hosts
    k8s_load "registry.k8s.io/pause:$K8S_PAUSE_VERSION"
    k8s_load "docker.io/cloudnativelabs/kube-router"
    $1
    home_token
    echo "Kubernetes installation completed and successfully joined to the cluster."
}

k8s_uninstall() {
    kubeadm reset -f
    systemctl disable kubelet
    rm -rvf /etc/systemd/system/kubelet.service*
    systemctl daemon-reload
    rm -vf /usr/local/bin/{crictl,helm,kubelet,kubeadm,kubectl}
}

confirm_hosts() {
    # https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/names/#dns-subdomain-names
    # https://tools.ietf.org/html/rfc1123
    # echo "$input" | grep -qP "^((^|\.)(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])){4}\s+([a-z\d]([a-z\d-]{0,61}[a-z\d])?\.)*[a-z]([a-z\d-]{0,61}[a-z\d])?$"
    cat /etc/hosts
    select_dialog "[y]" "Confirm the hosts, you can modify it by a new tty."
    # case "`select_dialog "y/n/c" "'y' to continue, 'n' to edit hosts, and 'c' to exit"`" in
    #     "n") nano /etc/hosts ;;
    #     "c") exit
    # esac
}

home_token() {
    mkdir -p "$HOME/.kube"
    if [ -f "/etc/kubernetes/admin.conf" ] && confirm_dialog '[y]/n' "Want install 'admin.conf' to '.kube/config'?"; then
        install -g `id -g` -o `id -u` -m 0700 /etc/kubernetes/admin.conf "$HOME/.kube/config"
        KUBE_CONFIG="`base64 -w 0 /etc/kubernetes/admin.conf`"
        persistence_env "$SUBJ_ENV" "KUBE_CONFIG=$KUBE_CONFIG"
    elif confirm_dialog '[y]/n' "Want install '.kube/config' from .env?"; then
        base64 -d <<< "$KUBE_CONFIG" > "$HOME/.kube/config"
        chown `whoami`:`groups` "$HOME/.kube/config"
        chmod 0700 "$HOME/.kube/config"
    fi
    mkdir -p /etc/bash_completion.d
    kubectl completion bash > /etc/bash_completion.d/kubectl
}

certs_renew() {
    # kubeadm certs check-expiration
    /bin/cp -rfv /etc/kubernetes /etc/kubernetes.old
    kubeadm certs renew all
    systemctl restart kubelet
    home_token
}

menu_route_or_rendor '
    --init-env          init_env
    --install           k8s_install
    --uninstall         k8s_uninstall
    --home-token        home_token          "Install an admin token to home"
    --certs-renew       certs_renew         "Kubeadm certs renew all"
                        return              "0. Return to parent"
    ##1 Your choice:
' "$@"