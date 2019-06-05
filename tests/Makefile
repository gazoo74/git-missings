#
# Copyright (c) 2017 Gaël PORTAY <gael.portay@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0
#

.PHONY: all
all: tests

linux-ramips/Makefile: | openwrt-0.5/Makefile
	$(MAKE) -sf kernel.mk TOPDIR=openwrt-0.5 TARGET=ramips

linux-ramips/.git: | linux-ramips/Makefile
	( cd linux-ramips/ && git init .)

linux-ramips/.git/index: | linux-ramips/Makefile linux-ramips/.git
	( cd linux-ramips/ && git add --all )

.SECONDARY: linux-ramips/.git/logs/refs/heads/master
linux-ramips/.git/logs/refs/heads/master: | linux-ramips/.git/index
	( cd linux-ramips/ && git commit --message "Initial commit" )

.SECONDARY: linux-ramips/.git/logs/refs/heads/generic
linux-ramips/.git/logs/refs/heads/generic: | linux-ramips/.git/logs/refs/heads/master
	( cd linux-ramips/ && git checkout -b generic  && \
	  rsync -ai ../openwrt-0.5/target/linux/generic/files/ . | \
	  while read opts file; do \
		git add "$$file"; \
	  done && \
	  git commit --message "Import linux generic files" )

.SECONDARY: linux-ramips/.git/logs/refs/heads/ramips
linux-ramips/.git/logs/refs/heads/ramips: | linux-ramips/.git/logs/refs/heads/generic
	( cd linux-ramips/ && git checkout -b ramips generic && \
	  rsync -ai ../openwrt-0.5/target/linux/ramips/files/ . | \
	  while read opts file; do \
		git add "$$file"; \
	  done && \
	  git commit --message "Import linux ramips files" )

.SECONDARY: linux-ramips/.git/logs/refs/heads/testing
linux-ramips/.git/logs/refs/heads/testing: | linux-ramips/.git/logs/refs/heads/ramips
	( cd linux-ramips/ && git checkout -b testing master )

0.5.tar.gz:
	wget https://github.com/gportay/openwrt/archive/$@

openwrt-0.5/Makefile: | 0.5.tar.gz
	tar xzf 0.5.tar.gz

.PHONY: tests
tests: | linux-ramips/.git/logs/refs/heads/testing
	-( cd linux-ramips/ && ( \
	   git am --abort; \
	   git rebase --abort; \
           git reset --hard master; \
           git clean -fdx; \
           rm -r .git/patch-apply/ ) \
        ) >/dev/null 2>&1
	@./tests.sh

.PHONY: clean
clean:
	rm -rf linux-ramips/

.PHONY: mrproper
mrproper: clean
	rm -rf openwrt-0.5/ 0.5.tar.gz linux-*.tar.*

