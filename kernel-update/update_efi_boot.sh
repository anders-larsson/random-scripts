#!/bin/bash

set -eu

if [ $(whoami) != root ]; then
	echo "This script needs to be run as root."
	exit 1
fi

required_env_variable() {
  if [ -z "${3}" ]; then
    echo "Environment variable ${1} is required." 1>&2
    test -z "${3}" && echo "Descriptipn: ${2}" 1>&2
    exit 1
  fi
  echo "${3}"
}

set +u
IDENTIFIER=$(required_env_variable IDENTIFIER 'IDENTIFIER is used to match entries in UEFI' $IDENTIFIER)
BOOT_DIR=${BOOT_DIR:-/boot}
KERNEL_CMDLINE=${KERNEL_CMDLINE:-""}
test -z "${KERNEL_CMDLINE}" && echo '$KERNEL_CMDLINE not set. Assuming no kernel arguments required'
set -u

# Get kernel images to install
pushd "${BOOT_DIR}" 1>/dev/null 2>&1
KERNELS=''

# Remove old entries
rm -f ${BOOT_DIR}/loader/entries/${IDENTIFIER}*

for kernel in $(find -name '*vmlinuz*'); do
  kernel_basedir=$(dirname $kernel)
	kname=${kernel##*/}
	kver=$(echo $kname | sed -e 's/vmlinuz-//')
  initrd=$(echo $kver | sed -e 's/\.old//')

  echo "${KERNELS}" | grep -q "${kver}" || KERNELS="${KERNELS} $kver"

	if [ -f "${kernel_basedir}/initramfs-${initrd}.img" ]; then
		kernel_cmdline="initrd=${kernel_basedir:1}/initramfs-${initrd}.img ${KERNEL_CMDLINE}"
	else
		kernel_cmdline="${KERNEL_CMDLINE}"
	fi

  cat << EOF > "${BOOT_DIR}/loader/entries/${IDENTIFIER}-$kver.conf"
title ${IDENTIFIER} ${kver}
linux ${kernel:1}
options ${kernel_cmdline}
EOF
done

popd 1>/dev/null 2>&1

LATEST_KERNEL=$(echo $KERNELS | tr ' ' $'\n' | grep -v .old | sort | tail -1)
bootctl set-default "${IDENTIFIER}-${LATEST_KERNEL}.conf"

PAGER=cat bootctl list
