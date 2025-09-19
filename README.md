# Debian Bootc

Avert your eyes! What you see before you is the unholy union of [mkosi](https://github.com/systemd/mkosi) and [bootc](https://github.com/bootc-dev/bootc). A _mostly_ declarative image generated with `mkosi` is subsequently added to a SCRATCH container. Sprinkle in a little `bootc` magic and you have a container image that can be installed to disk and booted.

You should not use this, nor should you try to learn from what has been done here. Instead, weep...

## Building

Build uses podman. The `bootc` tooling is very heavily skewed towards this, docker may work, but I haven't tested it.

In order to get a running debian-bootc system you can run the following steps:

```shell
just build-containerfile # This will build the containerfile and all the dependencies you need
just generate-bootable-image # Generates a bootable image for you using bootc!
```

The bootable image file is saved in `/tmp` as `/tmp/debian-bootc.img`. Assuming your `/tmp` is tmpfs, this is significantly faster for the image generation step.

Then you can run the `/tmp/debian-bootc.img` as your boot disk in your preferred hypervisor.

## Running

### QEMU

```
./launch.sh
```

## Fixes

- `mount /dev/vda2 /sysroot/boot` - You need this to get `bootc status` and other stuff working. This can be fixed with a mount file or something similar inside the image later.

## Inspirations, and Copy-Pasta

- [ParticleOS](https://github.com/systemd/particleos) - 90% of the mkosi image is original particleos configuration. License LGPL v2.1
