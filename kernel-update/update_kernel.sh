#!/bin/bash

set -ue

if [ $(whoami) != root ]; then
	echo "This script needs to be run as root."
	exit 1
fi

if [ $# -ne 1 ]; then
	echo "$0 kernelrelease"
	exit 1
fi

BOOT_DIR=${BOOT_DIR:-/boot}

findmnt ${BOOT_DIR} 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "${BOOT_DIR} does not seem to be mounted"
	exit 1
fi

KERNEL="${1##*/}"
KVER="${KERNEL#*-}"
MAKEOPTIONS="${MAKEOPTS:--j$(nproc)}"
DRACUTOPTIONS="${DRACUTOPTIONS:---hostonly --force --kver ${KVER}}"

LOGFILE="/tmp/updatekernel-${KERNEL}"
>"${LOGFILE}"

echo "### Setting kernel release ${KERNEL}"
eselect kernel set "${KERNEL}" &>> "${LOGFILE}"
if [ $? -ne 0 ]; then
	echo "Failed to set kernel release"
	exit 1
fi

echo "### Changing directory and copying previous config."
echo "Using kernel config: ${BOOT_DIR}/config-$(uname -r)"
cd /usr/src/linux &>> "${LOGFILE}"
cp ${BOOT_DIR}/config-$(uname -r) /usr/src/linux/.config  &>> "${LOGFILE}"
if [ $? -ne 0 ]; then
	echo "Failed to copy previous kernel config"
	exit 1
fi
echo "### Building and installing kernel"
make oldconfig | tee -a "${LOGFILE}"
( make "${MAKEOPTIONS}" && \
	make modules_install && \
	make install
) &>> "${LOGFILE}"

if [ $? -ne 0 ]; then
	echo "Build failed... Please advise"
	exit 1
fi

echo "### Build complete. Rebuilding kernel modules"
emerge -1 @module-rebuild &>> "${LOGFILE}"
if [ $? -ne 0 ];then
	echo "Rebuilding kernel modules failed"
	exit 1
fi

echo "### Generating initramfs using dracut"
dracut ${DRACUTOPTIONS}

echo "### All done!"
