#!/usr/bin/env bash
set -euo pipefail

# Simple launcher for the debian-bootc image with optional UEFI (OVMF) support.
# Usage: ./launch.sh [--uefi|-u] [--firmware-code PATH] [--firmware-vars PATH] [-- help qemu args...]

UEFI=1
FIRMWARE_CODE="/usr/share/ovmf/OVMF.fd"
FIRMWARE_VARS="/usr/share/OVMF/OVMF_VARS_4M.fd"
EXTRA_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --uefi|-u)
      UEFI=1
      shift
      ;;
    --firmware-code)
      FIRMWARE_CODE="$2"
      shift 2
      ;;
    --firmware-vars)
      FIRMWARE_VARS="$2"
      shift 2
      ;;
    --help|-h)
      cat <<EOF
Usage: $0 [--uefi|-u] [--firmware-code PATH] [--firmware-vars PATH] [extra qemu args]

Options:
  --uefi, -u             Enable UEFI (OVMF) firmware. If enabled the script will search
                         common system locations for OVMF_CODE and OVMF_VARS files.
  --firmware-code PATH   Use the specified OVMF code file.
  --firmware-vars PATH   Use the specified OVMF vars file (will be copied to a writable temp file).
  extra qemu args        Any remaining args are appended to the qemu command.

If UEFI is requested but OVMF files are not found the script exits with an error.
EOF
      exit 0
      ;;
    --)
      shift
      while [ $# -gt 0 ]; do
        EXTRA_ARGS+=("$1")
        shift
      done
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

IMG=/tmp/debian-bootc.img

# Common locations to look for OVMF firmware on various distros
CODE_CANDIDATES=(
  /usr/share/OVMF/OVMF_CODE.fd
  /usr/share/ovmf/OVMF_CODE.fd
  /usr/share/OVMF/OVMF.fd
  /usr/share/qemu/OVMF.fd
  /usr/share/qemu/ovmf-x64-code.bin
)
VARS_CANDIDATES=(
  /usr/share/OVMF/OVMF_VARS.fd
  /usr/share/ovmf/OVMF_VARS.fd
  /usr/share/qemu/ovmf-x64-vars.bin
)

TMP_VARS=""
cleanup() {
  if [ -n "${TMP_VARS}" ] && [ -f "${TMP_VARS}" ]; then
    rm -f "${TMP_VARS}"
  fi
}
trap cleanup EXIT

QEMU_UEFI_ARGS=()
if [ "$UEFI" -eq 1 ]; then
  # choose code file
  if [ -n "${FIRMWARE_CODE}" ]; then
    CODE_FILE="$FIRMWARE_CODE"
  else
    for p in "${CODE_CANDIDATES[@]}"; do
      if [ -f "$p" ]; then
        CODE_FILE="$p"
        break
      fi
    done
  fi

  # choose vars file
  if [ -n "${FIRMWARE_VARS}" ]; then
    VARS_FILE="$FIRMWARE_VARS"
  else
    for p in "${VARS_CANDIDATES[@]}"; do
      if [ -f "$p" ]; then
        VARS_FILE="$p"
        break
      fi
    done
  fi

  if [ -z "${CODE_FILE-}" ] || [ -z "${VARS_FILE-}" ]; then
    echo "UEFI requested but OVMF firmware not found. Searched common locations."
    echo "Install the 'ovmf' package or pass --firmware-code and --firmware-vars to the launcher."
    exit 1
  fi

  # copy the vars file to a writable temp so each VM has an independent NVRAM
  TMP_VARS=$(mktemp /tmp/ovmf_vars.XXXXXXXX)
  cp "$VARS_FILE" "$TMP_VARS"
  chmod 666 "$TMP_VARS" || true

  QEMU_UEFI_ARGS=(
    "-drive" "if=pflash,format=raw,readonly=on,file=$CODE_FILE"
    "-drive" "if=pflash,format=raw,file=$TMP_VARS"
  )
  echo "Starting QEMU with UEFI (OVMF) using code=$CODE_FILE vars=$TMP_VARS"
fi

# Build the qemu command as an array so we can safely append options
QEMU_CMD=(
  "qemu-system-x86_64"
  "-enable-kvm"
  "-m" "4G"
  "-smp" "2"
  "-hda" "$IMG"
  "-boot" "d"
  "-netdev" "user,id=net0,net=192.168.0.0/24,dhcpstart=192.168.0.9"
  "-device" "virtio-net-pci,netdev=net0"
  "-vga" "qxl"
  "-device" "AC97"
)

# Append UEFI args (if any) and any extra args passed through
if [ ${#QEMU_UEFI_ARGS[@]} -gt 0 ]; then
  QEMU_CMD+=("${QEMU_UEFI_ARGS[@]}")
fi
if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
  QEMU_CMD+=("${EXTRA_ARGS[@]}")
fi

# Execute the assembled command
printf '%s ' "${QEMU_CMD[@]}"
printf '\n'
exec "${QEMU_CMD[@]}"