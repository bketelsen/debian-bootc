#!/bin/bash

set -ouex pipefail
export DEBIAN_FRONTEND=noninteractive
### Install packages
apt install -y \
        gnome-browser-connector \
        gnome-core \
        gnome-initial-setup \
        gnome-keyring-pkcs11 \
        gnome-session-xsession \
        gnome-software-plugin-flatpak \
        gnome-software-plugin-fwupd \
        baobab \
        evince \
        gnome-backgrounds \
        gnome-calculator \
        gnome-calendar \
        gnome-characters \
        gnome-clocks \
        gnome-color-manager \
        gnome-contacts \
        gnome-control-center \
        gnome-disk-utility \
        gnome-font-viewer \
        gnome-keyring \
        gnome-logs \
        gnome-maps \
        gnome-menus \
        gnome-music \
        gnome-remote-desktop \
        gnome-session \
        gnome-settings-daemon \
        gnome-shell \
        gnome-software \
        gnome-system-monitor \
        gnome-terminal \
        gnome-text-editor \
        gnome-tour \
        ibus \
        nautilus \
        snapshot \
        tecla \
        loupe \
        xdg-desktop-portal-gnome \
        xdg-desktop-portal-gtk \
        xdg-user-dirs-gtk



### Enable services
ln -s /usr/lib/systemd/system/gdm3.service /etc/systemd/system/display-manager.service

### Filesystem changes

cp /ctx/10-particleos.preset /usr/lib/systemd/system-preset/10-particleos.preset
systemctl preset-all

### Cleanup