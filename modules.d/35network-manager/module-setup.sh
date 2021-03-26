#!/bin/bash

# called by dracut
check() {
    require_binaries sed grep || return 1

    # do not add this module by default
    return 255
}

# called by dracut
depends() {
    echo dbus
    return 0
}

# called by dracut
installkernel() {
    return 0
}

# called by dracut
install() {
    local _nm_version

    _nm_version=${NM_VERSION:-$(NetworkManager --version)}

    # We don't need `ip` but having it is *really* useful for people debugging
    # in an emergency shell.
    inst_multiple ip sed grep

    inst NetworkManager
    inst /usr/libexec/nm-initrd-generator
    inst_multiple -o teamd dhclient
    inst_hook cmdline 99 "$moddir/nm-config.sh"
    if dracut_module_included "systemd"; then

        inst_multiple \
            /usr/lib/systemd/system/NetworkManager.service \
            /usr/lib/systemd/system/NetworkManager-wait-online.service \
            "$dbussystem/org.freedesktop.NetworkManager.conf"

        inst_multiple nmcli nm-online

        inst_simple "$moddir/initrd-no-auto-default.conf" "/usr/lib/NetworkManager/conf.d/"

        mkdir -p "${initdir}/$systemdsystemunitdir/NetworkManager.service.d"
        (
            echo "[Unit]"
            echo "DefaultDependencies=no"
            echo "Before=shutdown.target"
            echo "After=systemd-udev-trigger.service systemd-udev-settle.service"
            echo "ConditionPathExistsGlob=|/usr/lib/NetworkManager/system-connections/*"
            echo "ConditionPathExistsGlob=|/run/NetworkManager/system-connections/*"
            echo "ConditionPathExistsGlob=|/etc/NetworkManager/system-connections/*"
            echo "ConditionPathExistsGlob=|/etc/sysconfig/network-scripts/ifcfg-*"

            echo "[Service]"
            echo "ExecStart="
            echo "ExecStart=/usr/sbin/NetworkManager --debug"
            echo "StandardOutput=journal+console"
            echo "Environment=NM_CONFIG_ENABLE_TAG=initrd"

            echo "[Install]"
            echo "WantedBy=sysinit.target"
        ) > "${initdir}/$systemdsystemunitdir/NetworkManager.service.d/dracut.conf"

        mkdir -p "${initdir}/$systemdsystemunitdir/NetworkManager-wait-online.service.d"
        (
            echo "[Unit]"
            echo "DefaultDependencies=no"
            echo "Before=shutdown.target"
            echo "Before=dracut-initqueue.service"
            echo "ConditionPathExists=/tmp/nm-wait-online"
            echo
            echo "[Service]"
            echo "Environment=NM_ONLINE_TIMEOUT=3600"
            echo
            echo "[Install]"
            echo "WantedBy=sysinit.target"
        ) > "${initdir}/$systemdsystemunitdir/NetworkManager-wait-online.service.d/dracut.conf"

        $SYSTEMCTL -q --root "$initdir" enable NetworkManager.service
        $SYSTEMCTL -q --root "$initdir" enable NetworkManager-wait-online.service
    fi

    inst_hook initqueue/settled 99 "$moddir/nm-run.sh"

    inst_rules 85-nm-unmanaged.rules
    inst_libdir_file "NetworkManager/$_nm_version/libnm-device-plugin-team.so"
    inst_simple "$moddir/nm-lib.sh" "/lib/nm-lib.sh"

    if [[ -x "$initdir/usr/sbin/dhclient" ]]; then
        inst /usr/libexec/nm-dhcp-helper
    elif ! [[ -e "$initdir/etc/machine-id" ]]; then
        # The internal DHCP client silently fails if we
        # have no machine-id
        systemd-machine-id-setup --root="$initdir"
    fi

    # We don't install the ifcfg files from the host automatically.
    # But the user might choose to include them, so we pull in the machinery to read them.
    inst_libdir_file "NetworkManager/$_nm_version/libnm-settings-plugin-ifcfg-rh.so"

    _arch=${DRACUT_ARCH:-$(uname -m)}

    inst_libdir_file {"tls/$_arch/",tls/,"$_arch/",}"libnss_dns.so.*" \
        {"tls/$_arch/",tls/,"$_arch/",}"libnss_mdns4_minimal.so.*"
}
