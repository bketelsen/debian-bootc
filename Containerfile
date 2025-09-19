# Allow build scripts to be referenced without being copied into the final image
FROM scratch
COPY mkosi.output/base/ /

RUN ls -la /

### Prepare final image
RUN rm -rf /var /boot && \
    ln -s /var/home /home && \
    ln -s /var/roothome /root && \
    ln -s /var/srv /srv && \
    ln -s sysroot/ostree ostree && \
    ln -s /var/usrlocal /usr/local && \
    mkdir -p /sysroot /var/home /boot && \
    rm -rf /var/log /home /root /usr/local /srv

RUN rm microsoft-edge.gpg

RUN systemd-tmpfiles --create /usr/lib/tmpfiles.d/bootc.conf

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
LABEL containers.bootc 1
