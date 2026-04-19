# hyprland-dmemcg-boost

Hyprland implementation of N. Vock dmem cgroup GPU VRAM boost concept. Dynamically prioritizes VRAM for the focused window by writing to the kernel's dmem cgroup controller via Hyprland's event socket. Packaged as a clean Arch Linux PKGBUILD with automatic systemd setup.
There is no reason why us Hyperland cannot join the KDE fun on this amazing work!

---

## How it works

The Linux kernel's dmem cgroup controller allows setting a `dmem.low` watermark on a cgroup, telling the kernel to prefer keeping that cgroup's GPU allocations in VRAM over others. This package hooks into Hyprland's focus events and dynamically writes to `dmem.low` for whatever window is currently focused — giving the active window priority on GPU memory.

---

## Files

### `hyprland-dmemcg-boost.sh`
The main booster script. Runs as your user via systemd. Connects to Hyprland's event socket using `socat`, listens for `activewindow` events, resolves the focused process's cgroup path, and writes the VRAM boost value to `dmem.low`.

### `hyprland-dmemcg-boost@.service`
Systemd **user** service that runs the booster script. Instantiated with your `$HYPRLAND_INSTANCE_SIGNATURE` so it connects to the correct Hyprland socket. Restarts automatically on failure.

### `dmemcg-setup.sh`
Root helper script. Enables dmem at the root and `user.slice` cgroup levels, then recursively fixes ownership of all active user slices so the user service can write to them. Called by the system service below.

### `dmemcg-setup.service`
Systemd **system** service that runs `dmemcg-setup.sh` as root. Runs after `systemd-logind` is up. Re-triggered automatically on new logins by the path unit below.

### `dmemcg-setup.path`
Systemd **path unit** that watches `/sys/fs/cgroup/user.slice` for changes. Re-triggers `dmemcg-setup.service` whenever a new user logs in and their slice is created — no hardcoded UIDs.

### `dmemcg-permissions.conf`
A `tmpfiles.d` config that writes `+dmem` to the root cgroup's `subtree_control` at boot. Only handles the root level — per-user slice ownership is handled dynamically by `dmemcg-setup.service`.

---

## Installation

```bash
git clone https://github.com/egnappahz/hyprland-dmemcg-boost
cd hyprland-dmemcg-boost
makepkg -si
```

The system services (`dmemcg-setup.path` and `dmemcg-setup.service`) are enabled automatically on install.

---

## Usage

Add this to your `~/.config/hypr/hyprland.conf`:

```
exec-once = systemctl --user start hyprland-dmemcg-boost@$HYPRLAND_INSTANCE_SIGNATURE
```

Or start it manually for the current session:

```bash
systemctl --user start hyprland-dmemcg-boost@$HYPRLAND_INSTANCE_SIGNATURE
```

---

## Configuration

The boost size defaults to `4G`. Override it by editing the user service or setting `DMEMCG_BOOST_SIZE` in a drop-in:

```bash
# /etc/systemd/user/hyprland-dmemcg-boost@.service.d/override.conf
[Service]
Environment="DMEMCG_BOOST_SIZE=8G"
```

### Gaming

For the booster to properly target a game and its entire process tree (Proton, Wine, pressure-vessel, etc.), the game needs to run inside its own cgroup scope.

#### Heroic
Use a wrapper script. Add the following to your wrapper and set it as the launcher wrapper in Heroic settings:

```bash
exec systemd-run --user --scope --slice=app.slice -- "$@"
```

#### Steam
Add this to the individual game's launch options in Steam:

```bash
systemd-run --user --scope %command%
```

`%command%` is Steam's placeholder for the game command — this wraps the entire game and its Proton/Wine children into a clean cgroup scope that the booster can target.


### Verification
You can verify it worked after launch with:

```bash
systemctl --user status
```

Look for a `run-uXXXX.scope` entry under `app.slice` containing your game's processes. Then confirm the booster is targeting it by watching the logs while focusing the game window:

```bash
journalctl --user -fu hyprland-dmemcg-boost@$HYPRLAND_INSTANCE_SIGNATURE
```

---

## Dependencies

- `hyprland`
- `socat`
- `jq`
- `bash`

---

## Credits

- **Natalie Vock** — original dmem cgroup boost concept and KDE Plasma implementation
- **Maarten Lankhorst** — initial work of cgroup controller managing GPU memory
- **Maxime Ripard** — dmem cgroup controller work
