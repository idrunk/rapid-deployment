os_pkg_install() {
    rpm -hvi "$1"
}

os_pkg_uninstall() {
    rpm -hve "`label_to_pkg "$1"`"
}

os_pkgm_install() {
    dnf install -y "$1"
}

os_pkgm_uninstall() {
    dnf remove -y "$1"
}
