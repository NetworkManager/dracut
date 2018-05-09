#!/bin/bash

# called by dracut
check() {
    return 255
}

# called by dracut
depends() {
    echo "kernel-network-modules"
    return 0
}

# called by dracut
installkernel() {
    return 0
}

# called by dracut
install() {
    inst /usr/libexec/nm-initrd-generator
    inst /usr/sbin/NetworkManager
    inst /usr/sbin/iscsiadm
    inst_simple "$moddir/net-lib.sh" "/lib/net-lib.sh"
    inst_script "$moddir/netroot.sh" "/sbin/netroot"
    inst_hook cmdline 99 "$moddir/nm-config.sh"
    inst_hook initqueue/settled 99 "$moddir/nm-run.sh"
}
