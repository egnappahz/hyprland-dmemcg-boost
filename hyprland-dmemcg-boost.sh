#!/bin/bash
# hyprland-dmemcg-boost.sh — runs as the logged-in user via systemd user service
# Listens to Hyprland socket events and boosts VRAM for the focused window's cgroup

# --- CONFIGURATION ---
BOOST_SIZE="${DMEMCG_BOOST_SIZE:-4G}"

to_bytes() { echo "$1" | numfmt --from=iec; }
BYTES=$(to_bytes "$BOOST_SIZE")

# --- GPU RESOURCE DISCOVERY ---
DRM_RESOURCE=$(sort -nk2 /sys/fs/cgroup/dmem.capacity | tail -n 1 | awk '{print $1}')
if [ -z "$DRM_RESOURCE" ]; then
    echo "Error: Could not find any dmem resources." >&2
    exit 1
fi

echo "Targeting GPU Resource: $DRM_RESOURCE"
echo "Boost set to: $BOOST_SIZE ($BYTES bytes)"

# --- THE HYPRLAND EVENT LOOP ---
LAST_CGROUP=""

socat -U - "UNIX-CONNECT:${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock" \
| while read -r line; do
    if [[ $line == activewindow* ]]; then
        PID=$(hyprctl activewindow -j | jq -r '.pid')

        if [[ "$PID" == "null" || "$PID" == "0" || -z "$PID" ]]; then
            continue
        fi

        CGROUP_RELATIVE=$(cut -d: -f3 /proc/"$PID"/cgroup)
        CGROUP_FULL="/sys/fs/cgroup${CGROUP_RELATIVE}"

        if [ ! -d "$CGROUP_FULL" ]; then continue; fi

        # --- DEBOUNCE: skip if cgroup hasn't changed ---
        if [ "$CGROUP_FULL" == "$LAST_CGROUP" ]; then continue; fi
        LAST_CGROUP="$CGROUP_FULL"

        # --- RECURSIVE SUBTREE ENABLEMENT ---
        curr="$CGROUP_FULL"
        while [ "$curr" != "/sys/fs/cgroup" ]; do
            parent=$(dirname "$curr")
            if ! grep -q "dmem" "$parent/cgroup.subtree_control" 2>/dev/null; then
                echo "+dmem" | /usr/lib/hyprland-dmemcg-boost/cgwrite "$parent/cgroup.subtree_control"
            fi
            curr="$parent"
        done

        # --- THE CRITICAL WRITE ---
        if [ -f "$CGROUP_FULL/dmem.low" ]; then
            echo "Applying Boost: PID=$PID -> $CGROUP_RELATIVE"
            echo "$DRM_RESOURCE $BYTES" | /usr/lib/hyprland-dmemcg-boost/cgwrite "$CGROUP_FULL/dmem.low"
        fi
    fi
done
