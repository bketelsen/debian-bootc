#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1-or-later
set -e

echo "Running mkosi finalize script in chroot..."
exit 1
# Capture the entirety of /etc in /usr/share/factory/etc so we can use
# systemd-tmpfiles to symlink individual directories from it to /etc.
mkdir -p "$BUILDROOT/usr/share/factory/"
cp --archive --no-target-directory --update=none "$BUILDROOT/etc" "$BUILDROOT/usr/share/factory/etc"
mkdir -p "$BUILDROOT/usr/share/factory/opt/microsoft/msedge"
cp --archive --no-target-directory --update=none "$BUILDROOT/opt/microsoft/msedge" "$BUILDROOT/usr/share/factory/opt/microsoft/msedge"



export KERNEL_VERSION="$(basename "$(find $BUILDROOT/usr/lib/modules -maxdepth 1 -type d | tail -n 1)")"
dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "$BUILDROOT/usr/lib/modules/$KERNEL_VERSION/initramfs.img"
