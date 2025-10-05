#!/bin/bash

# bootc install to-disk --composefs-native --filesystem btrfs --wipe --bootloader systemd /dev/nvme0n1

sudo podman run \
    --rm --privileged --pid=host \
    -it \
    -e RUST_LOG=debug \
    -v /etc/containers:/etc/containers:Z \
    -v /var/lib/containers:/var/lib/containers \
    -v /dev:/dev \
    -v "/tmp:/data" \
    --security-opt label=type:unconfined_t \
    "localhost/debian-bootc:latest" /bin/bash