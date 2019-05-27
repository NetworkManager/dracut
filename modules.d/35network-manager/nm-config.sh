#!/bin/sh

[ -z "$netroot" ] || echo rd.neednet >> /etc/cmdline.d/35-neednet.conf

/usr/libexec/nm-initrd-generator -- $(getcmdline)
