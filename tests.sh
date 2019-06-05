#!/bin/bash
#
# Copyright (c) 2017 Gaël PORTAY <gael.portay@gmail.com>
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
}

fix() {
	fix="$((fix+1))"
	echo -e "\e[1m$test: \e[34m[FIX]\e[0m"
}

bug() {
	bug="$((bug+1))"
	echo -e "\e[1m$test: \e[33m[BUG]\e[0m"
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

