#!/bin/sh

/usr/sbin/NetworkManager --configure-and-quit=initrd --debug
/sbin/netroot dummy
