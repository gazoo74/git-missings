#!/bin/bash
#
# Copyright (c) 2017 Gaël PORTAY
#
# SPDX-License-Identifier: GPL-3.0
#

run() {
	test="$@"
	echo -e "\e[1mRunning $test...\e[0m"
}

ok() {
	ok="$((ok+1))"
	echo -e "\e[1m$test: \e[32m[OK]\e[0m"
}

ko() {
	ko="$((ko+1))"
	echo -e "\e[1m$test: \e[31m[KO]\e[0m"
	exit 1
}

fix() {
	fix="$((fix+1))"
	echo -e "\e[1m$test: \e[34m[FIX]\e[0m"
}

bug() {
	bug="$((bug+1))"
	echo -e "\e[1m$test: \e[33m[BUG]\e[0m"
	exit 1
}

result() {
	if [ -n "$ok" ]; then
		echo -e "\e[1m\e[32m$ok test(s) succeed!\e[0m"
	fi

	if [ -n "$fix" ]; then
		echo -e "\e[1m\e[33m$fix test(s) fixed!\e[0m" >&2
	fi

	if [ -n "$bug" ]; then
		echo -e "\e[1mWarning: \e[33m$bug test(s) bug!\e[0m" >&2
	fi

	if [ -n "$ko" ]; then
		echo -e "\e[1mError: \e[31m$ko test(s) failed!\e[0m" >&2
		exit 1
	fi
}

PATH="$PWD:$PATH"
trap result 0

git-apply() {
	cat <<EOF
Applied patch a/clean cleanly.
error: b/unpatched: does not exist in index
Applying patch c/rejected with 1 reject...
Applying patch d/rejecteds with 10 rejects...
EOF
}

get_patched_files() {
	sed -n '/^Applied patch /s,Applied patch \(.*\) cleanly.$,\1,p'
}

get_reject_files() {
	sed -n '/Applying patch/s,Applying patch \(.*\) with [0-9]* rejects\?...$,\1.rej,p'
}

get_unpatched_files() {
	sed -n '/error: /s,^error: \(.*\): does not exist in index$,\1,p'
}

run "Test patched files"
if git-apply | get_patched_files | tee /dev/stderr \
   | grep 'a/clean' | wc -l | grep -q 1
then
	ok
else
	ko
fi
echo

run "Test unpatched files"
if git-apply | get_unpatched_files | tee /dev/stderr \
   | grep 'b/unpatched' | wc -l | grep -q 1
then
	ok
else
	ko
fi
echo

run "Test reject files"
if git-apply | get_reject_files | tee /dev/stderr \
   | grep '[cd]/rejecteds\?\.rej' | wc -l | grep -q 2
then
	ok
else
	ko
fi
echo

PATH="$PWD/..:$PATH"
cd linux-ramips/

clean_and_rebase_to() {
	git reset --hard "$1"
	git clean -fdx
	rm -rf .git/patch-apply/
}

PATCHOPTS+="--quiet"

# Scenario A

clean_and_rebase_to master >/dev/null

run "Test patching OpenWRT linux generic: missing files are rejected"
if ! git-patch $PATCHOPTS ../openwrt-0.5/target/linux/generic/patches-3.18/*.patch && \
   ! [ -e fs/yaffs2/yaffs_vfs.c ] && \
     [ -e fs/yaffs2/yaffs_vfs.c.rej ] && \
     git status --porcelain |
     diff - <(echo -n "\
?? fs/yaffs2/
")
then
	ok
else
	ko
fi

run "Test patching OpenWRT linux generic: --continue fails if rejected files remains"
if [ -e fs/yaffs2/yaffs_vfs.c.rej ] && \
   ! git-patch --continue && \
     git-patch --continue 2>&1 | \
     diff - <(echo -n "\
Remaining unpatched artifact fs/yaffs2/yaffs_vfs.c.rej!
")
then
	ok
else
	ko
fi
git status --porcelain

run "Test patching OpenWRT linux generic: --skip continues until next failure"
[ -e fs/yaffs2/yaffs_vfs.c.rej ]
if ! git-patch --skip && \
   ! [ -e fs/yaffs2/yaffs_tagscompat.c ] && \
     [ -e fs/yaffs2/yaffs_tagscompat.c.rej ] && \
     git status --porcelain | \
     diff - <(echo -n "\
?? fs/yaffs2/
")
then
	ok
else
	ko
fi
git status --porcelain

run "Test patching OpenWRT linux generic: --abort gives up and resets"
[ -e fs/yaffs2/yaffs_vfs.c.rej ]
[ -e fs/yaffs2/yaffs_tagscompat.c.rej ]
if git-patch --abort | \
   grep -q "HEAD is now at [a-f0-9]* Initial commit" && \
   git status --porcelain | \
   diff - <(echo -n "")
then
	ok
else
	ko
fi
git status --porcelain

# Scenario B

clean_and_rebase_to master >/dev/null

run "Test patching OpenWRT linux ramips: hunk fails"
if ! git-patch $PATCHOPTS ../openwrt-0.5/target/linux/ramips/patches-3.18/*.patch && \
     [ -e drivers/usb/host/Kconfig.rej ] && \
     [ -e drivers/usb/host/pci-quirks.h.rej ] && \
     git status --porcelain |
     diff - <(echo "\
M  drivers/usb/core/hcd-pci.c
M  drivers/usb/core/hub.c
M  drivers/usb/core/port.c
 M drivers/usb/host/Kconfig
M  drivers/usb/host/Makefile
A  drivers/usb/host/mtk-phy-7621.c
A  drivers/usb/host/mtk-phy-7621.h
A  drivers/usb/host/mtk-phy-ahb.c
A  drivers/usb/host/mtk-phy.c
A  drivers/usb/host/mtk-phy.h
M  drivers/usb/host/xhci-dbg.c
M  drivers/usb/host/xhci-mem.c
A  drivers/usb/host/xhci-mtk-power.c
A  drivers/usb/host/xhci-mtk-power.h
A  drivers/usb/host/xhci-mtk-scheduler.c
A  drivers/usb/host/xhci-mtk-scheduler.h
A  drivers/usb/host/xhci-mtk.c
A  drivers/usb/host/xhci-mtk.h
M  drivers/usb/host/xhci-plat.c
M  drivers/usb/host/xhci-ring.c
M  drivers/usb/host/xhci.c
M  drivers/usb/host/xhci.h
?? drivers/usb/host/Kconfig.rej
?? drivers/usb/host/pci-quirks.h.rej")
then
	ok
else
	ko
fi
echo
git status --porcelain

# Scenario C

clean_and_rebase_to master >/dev/null
git cherry-pick generic >/dev/null

run "Test patching OpenWRT linux generic: with files imported"
if git-patch $PATCHOPTS ../openwrt-0.5/target/linux/generic/patches-3.18/*.patch
then
	ok
else
	ko
fi
echo
git status --porcelain

git cherry-pick ramips
! [ -d .git/patch-apply/ ]
run "Test patching OpenWRT linux ramips: with files imported"
if git-patch $PATCHOPTS ../openwrt-0.5/target/linux/ramips/patches-3.18/*.patch
then
	ok
else
	ko
fi
echo
git status --porcelain

cd -
