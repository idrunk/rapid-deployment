os_pkg_install() {
    dpkg -i "$1"
}

os_pkg_uninstall() {
    dpkg -r "$1"
    dpkg --purge "$1"
}

os_pkgm_install() {
    apt-get install -fy "$1"
}

os_pkgm_uninstall() {
    apt-get remove -y "$1"
}
