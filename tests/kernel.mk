#
# Copyright (c) 2017 Gaël PORTAY <gael.portay@gmail.com>
#
# SPDX-License-Identifier: GPL-3.0
#

include $(TOPDIR)/target/linux/$(TARGET)/Makefile
include $(TOPDIR)/include/kernel-version.mk

.PHONY: all
all: linux-$(TARGET)/Makefile

linux%:
	mkdir -p $@

linux-$(TARGET)/Makefile: $(LINUX_SOURCE) | linux-$(TARGET)
	tar xf $< --strip-components=1 -C $(@D)

$(LINUX_SOURCE):
	wget https://$(subst @KERNEL,cdn.kernel.org/pub,$(LINUX_SITE)/$(LINUX_SOURCE))

