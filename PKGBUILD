# Maintainer: spark <spark@eieren>
pkgname=hyprland-dmemcg-boost
pkgver=1.0.0
pkgrel=1
pkgdesc="Dynamic dmem cgroup GPU VRAM boost for focused windows under Hyprland"
arch=('x86_64')
url="https://github.com/egnappahz/hyprland-dmemcg-boost"
license=('MIT')
depends=('hyprland' 'socat' 'jq' 'bash')
backup=()
install="${pkgname}.install"

source=(
    "dmemcg-setup.sh"
    "dmemcg-setup.service"
    "dmemcg-setup.path"
    "dmemcg-permissions.conf"
    "hyprland-dmemcg-boost.sh"
    "hyprland-dmemcg-boost@.service"
)
sha256sums=('SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP')

package() {
    # Helper script (runs as root via service)
    install -Dm755 "${srcdir}/dmemcg-setup.sh" \
        "${pkgdir}/usr/lib/${pkgname}/dmemcg-setup.sh"

    # The main booster script (runs as user via systemd user service)
    install -Dm755 "${srcdir}/hyprland-dmemcg-boost.sh" \
        "${pkgdir}/usr/lib/${pkgname}/hyprland-dmemcg-boost.sh"

    # Systemd system units (root-level setup)
    install -Dm644 "${srcdir}/dmemcg-setup.service" \
        "${pkgdir}/usr/lib/systemd/system/dmemcg-setup.service"
    install -Dm644 "${srcdir}/dmemcg-setup.path" \
        "${pkgdir}/usr/lib/systemd/system/dmemcg-setup.path"

    # Systemd user unit (per-user booster, instantiated per seat/display)
    install -Dm644 "${srcdir}/hyprland-dmemcg-boost@.service" \
        "${pkgdir}/usr/lib/systemd/user/hyprland-dmemcg-boost@.service"

    # tmpfiles.d — only the root cgroup write, safe at boot
    install -Dm644 "${srcdir}/dmemcg-permissions.conf" \
        "${pkgdir}/etc/tmpfiles.d/dmemcg-permissions.conf"

    # sudoers drop-in so the user service can call the setup script
    install -Dm440 /dev/stdin \
        "${pkgdir}/etc/sudoers.d/${pkgname}" <<EOF
# Allow any user to run the dmemcg setup script as root (no password)
%users ALL=(root) NOPASSWD: /usr/lib/${pkgname}/dmemcg-setup.sh
# Allow any user to write to cgroup dmem.low files
%users ALL=(root) NOPASSWD: /usr/bin/tee /sys/fs/cgroup/*/dmem.low
%users ALL=(root) NOPASSWD: /usr/bin/tee /sys/fs/cgroup/*/*/dmem.low
%users ALL=(root) NOPASSWD: /usr/bin/tee /sys/fs/cgroup/*/*/*/dmem.low
%users ALL=(root) NOPASSWD: /usr/bin/tee /sys/fs/cgroup/cgroup.subtree_control
%users ALL=(root) NOPASSWD: /usr/bin/tee /sys/fs/cgroup/*/cgroup.subtree_control
%users ALL=(root) NOPASSWD: /usr/bin/tee /sys/fs/cgroup/*/*/cgroup.subtree_control
%users ALL=(root) NOPASSWD: /usr/bin/tee /sys/fs/cgroup/*/*/*/cgroup.subtree_control
EOF
}
