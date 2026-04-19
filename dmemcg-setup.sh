#!/bin/bash
# dmemcg-setup.sh — runs as root, enables dmem and fixes user slice ownership
# Called by dmemcg-setup.service (triggered at boot and on login via path unit)

set -euo pipefail

# Step 1: Enable dmem at the root cgroup level
# (tmpfiles.d also does this, but belt-and-suspenders for timing)
echo "+dmem" > /sys/fs/cgroup/cgroup.subtree_control || true

# Step 2: Propagate dmem down into user.slice
if ! grep -q "dmem" /sys/fs/cgroup/user.slice/cgroup.subtree_control 2>/dev/null; then
    echo "+dmem" > /sys/fs/cgroup/user.slice/cgroup.subtree_control || true
fi

# Step 3: Fix ownership for all currently active user slices
for slice_dir in /sys/fs/cgroup/user.slice/user-*.slice; do
    [ -d "$slice_dir" ] || continue

    uid=$(basename "$slice_dir" | grep -oP '(?<=user-)\d+(?=\.slice)')
    [ -z "$uid" ] && continue

    username=$(id -nu "$uid" 2>/dev/null) || {
        echo "dmemcg-setup: no user found for uid=$uid, skipping"
        continue
    }

    # Recursively chown the entire slice subtree
    chown -R "${username}:${username}" "$slice_dir"
    echo "dmemcg-setup: ownership fixed for uid=$uid ($username) on $slice_dir"
done
