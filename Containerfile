FROM docker.io/library/debian:unstable

COPY files/ostree/prepare-root.conf /usr/lib/ostree/prepare-root.conf

ARG DEBIAN_FRONTEND=noninteractive
# Antipattern but we are doing this since `apt`/`debootstrap` does not allow chroot installation on unprivileged podman builds
ENV DEV_DEPS="libzstd-dev libssl-dev pkg-config libostree-dev curl git build-essential meson libfuse3-dev go-md2man dracut whois"

RUN rm /etc/apt/apt.conf.d/docker-gzip-indexes /etc/apt/apt.conf.d/docker-no-languages && \
    apt update -y && \
    apt install -y $DEV_DEPS ostree

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"
ENV CARGO_FEATURES="composefs-backend"

RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/bootc-dev/bootc.git bootc && \
    cd bootc && \
    git fetch --all && \
    git switch origin/composefs-backend-15-09-2025 -d && \
    make && \
    make install-all && \
    make install-initramfs-dracut

RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/p5/coreos-bootupd.git bootupd && \
    cd bootupd && \
    git fetch --all && \
    git switch origin/sdboot-support -d && \
    /root/.cargo/bin/cargo build --release --bins --features systemd-boot && \
    install -Dpm0755 -t /usr/bin ./target/release/bootupd && \
    ln -s ./bootupd /usr/bin/bootupctl

RUN --mount=type=tmpfs,dst=/tmp cd /tmp && \
    git clone https://github.com/containers/composefs.git composefs && \
    cd composefs && \
    git fetch --all && \
    meson setup build --prefix=/usr --default-library=shared -Dfuse=enabled && \
    ninja -C build && \
    ninja -C build install

ENV DRACUT_NO_XATTR=1
RUN apt install -y \
  dracut \
  podman \
  linux-image-generic \
  firmware-linux-free \
  systemd \
  btrfs-progs \
  e2fsprogs \
  xfsprogs \
  udev \
  cpio \
  zstd \
  binutils \
  dosfstools \
  conmon \
  crun \
  netavark \
  skopeo \
  dbus \
  fdisk \
  systemd-boot*


RUN echo "$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" > kernel_version.txt && \
    dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$(cat kernel_version.txt)"  "/usr/lib/modules/$(cat kernel_version.txt)/initramfs.img" && \
    cp /boot/vmlinuz-$(cat kernel_version.txt) "/usr/lib/modules/$(cat kernel_version.txt)/vmlinuz" && \
    rm kernel_version.txt


RUN apt remove -y $DEV_DEPS && \
    apt autoremove -y
ENV DEV_DEPS=


# If you want a desktop :)
RUN apt install -y gnome gnome-initial-setup

# Alter root file structure a bit for ostree
RUN rm -rf /var/log /home /root /usr/local /srv /opt
RUN mkdir -p /boot /sysroot /var/home /var/roothome /var/usrlocal /var/srv /var/opt && \
    ln -s /var/home /home && \
    ln -s /var/roothome /root && \
    ln -s /var/usrlocal /usr/local && \
    ln -s /var/srv /srv && \
    ln -s /var/opt /opt

# Add our tmpfiles.d config for bootc
COPY files/usr/lib/tmpfiles.d/bootc.conf /usr/lib/tmpfiles.d/bootc.conf
RUN systemd-tmpfiles --create /usr/lib/tmpfiles.d/bootc.conf

# Update useradd default to /var/home instead of /home for User Creation
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd"

# Setup a temporary root passwd (changeme) for dev purposes
# TODO: Replace this for a more robust option when in prod
RUN usermod -p '$6$AJv9RHlhEXO6Gpul$5fvVTZXeM0vC03xckTIjY8rdCofnkKSzvF5vEzXDKAby5p3qaOGTHDypVVxKsCE3CbZz7C3NXnbpITrEUvN/Y/' root

# Necessary labels
LABEL containers.bootc 1
