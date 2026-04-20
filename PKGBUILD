# Maintainer: spark <spark@eieren>
pkgname=hyprland-dmemcg-boost
pkgver=1.0.0
pkgrel=1
pkgdesc="Dynamic dmem cgroup GPU VRAM boost for focused windows under Hyprland"
arch=('x86_64')
url="https://github.com/egnappahz/hyprland-dmemcg-boost"
license=('MIT')
depends=('hyprland' 'socat' 'jq' 'bash')
makedepends=('gcc')
backup=()
install="${pkgname}.install"

source=(
    "dmemcg-setup.sh"
    "dmemcg-setup.service"
    "dmemcg-setup.path"
    "dmemcg-permissions.conf"
    "hyprland-dmemcg-boost.sh"
    "hyprland-dmemcg-boost@.service"
    "cgwrite.c"
)
sha256sums=('SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP')

build() {
    gcc -O2 -o "${srcdir}/cgwrite" "${srcdir}/cgwrite.c"
}

package() {
    # Root helper script (runs via dmemcg-setup.service)
    install -Dm755 "${srcdir}/dmemcg-setup.sh" \
        "${pkgdir}/usr/lib/${pkgname}/dmemcg-setup.sh"

    # Main booster script (runs as user via systemd user service)
    install -Dm755 "${srcdir}/hyprland-dmemcg-boost.sh" \
        "${pkgdir}/usr/lib/${pkgname}/hyprland-dmemcg-boost.sh"

    # setuid root helper — writes to cgroup files without sudo/PAM overhead
    install -Dm4755 "${srcdir}/cgwrite" \
        "${pkgdir}/usr/lib/${pkgname}/cgwrite"

    # Systemd system units (root-level setup)
    install -Dm644 "${srcdir}/dmemcg-setup.service" \
        "${pkgdir}/usr/lib/systemd/system/dmemcg-setup.service"
    install -Dm644 "${srcdir}/dmemcg-setup.path" \
        "${pkgdir}/usr/lib/systemd/system/dmemcg-setup.path"

    # Systemd user unit (per-user booster, instantiated per Hyprland session)
    install -Dm644 "${srcdir}/hyprland-dmemcg-boost@.service" \
        "${pkgdir}/usr/lib/systemd/user/hyprland-dmemcg-boost@.service"

    # tmpfiles.d — root cgroup subtree_control write, safe at boot
    install -Dm644 "${srcdir}/dmemcg-permissions.conf" \
        "${pkgdir}/etc/tmpfiles.d/dmemcg-permissions.conf"
}
