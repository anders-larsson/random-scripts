# Update kernel scripts

Scripts are written on a Gentoo system. Uses `dracut` to generate initramfs and
add boot entries to systemd-boot automatically.
Allows customization for command arguments, locations etc. with environment
variables.

### Example

Shell function `update_kernel` takes new kernel (as location of it or kernel
identifier) e.g. 5.10.7-gentoo.

It executes update_kernel.sh to build a new kernel based on the currently
running kernel and creates a initramfs image using `dracut`. In addition find
is used to remove old kernels and dracut images. Finally update_efi_boot is used
to generate systemd-boot entries using environment variables. See scripts for
all available options.

```bash
function update_kernel
{
  if [ -n "${1}" ]; then
    kernel="${1}"
    sudo -- sh -c "eclean-kernel -n 3 -x config \
      && MAKEOPTIONS='-j7' /usr/local/sbin/update_kernel.sh ${kernel} \
      && IDENTIFIER=Gentoo KERNEL_CMDLINE='init=/lib/systemd/systemd dolvm rootfstype=ext4 rootflags=rw,noatime,data=ordered root=/dev/mapper/vg00-root rd.driver.pre=vfio-pci,pci-stub pci-stub.ids=10de:1189,10de:10de:0e0a iommu=1 amd_iommu=on quiet' /usr/local/sbin/update_efi_boot.sh"
  else
    echo 'update_kernel <kernel>'
  fi
}
```
