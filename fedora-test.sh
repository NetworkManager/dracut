#!/bin/bash

set -ex

[[ -d ${0%/*} ]] && cd ${0%/*}

RUN_ID="$1"
TESTS=$2

dnf -vvv -y update --best --allowerasing
#&>/dev/null

dnf -vvv -y install --best --allowerasing \
    dash \
    asciidoc \
    mdadm \
    lvm2 \
    dmraid \
    cryptsetup \
    nfs-utils \
    nbd \
    dhcp-server \
    scsi-target-utils \
    iscsi-initiator-utils \
    strace \
    btrfs-progs \
    kmod-devel \
    gcc \
    bzip2 \
    xz \
    tar \
    wget \
    rpm-build \
    make \
    git \
    bash-completion \
    sudo \
    kernel \
    dhcp-client \
    /usr/bin/qemu-kvm \
    /usr/bin/qemu-system-$(uname -i) \
    e2fsprogs \
    tcpdump \
    $NULL
#&>/dev/null

# https://koji.fedoraproject.org/koji/taskinfo?taskID=35815954
xargs rpm -Fvh <<PKGS
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-container-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-container-debuginfo-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-debuginfo-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-debugsource-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-devel-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-journal-remote-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-journal-remote-debuginfo-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-libs-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-libs-debuginfo-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-pam-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-pam-debuginfo-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-rpm-macros-241-9.git9ef65cb.fc30.lr1.noarch.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-tests-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-tests-debuginfo-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-udev-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
https://kojipkgs.fedoraproject.org//work/tasks/7984/35817984/systemd-udev-debuginfo-241-9.git9ef65cb.fc30.lr1.x86_64.rpm
PKGS

./configure

NCPU=$(getconf _NPROCESSORS_ONLN)

if ! [[ $TESTS ]]; then
    make -j$NCPU all syncheck rpm logtee
else
    make -j$NCPU all logtee

    cd test

    time sudo make \
         KVERSION=$(rpm -qa kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -rn | head -1) \
         TEST_RUN_ID=$RUN_ID \
         ${TESTS:+TESTS="$TESTS"} \
         -k V=1 \
         check
fi
