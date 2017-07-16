#
# Copyright (c) 2017 Gaël PORTAY <gael.portay@savoirfairelinux.com>
#
# This program is free software: you can redistribute it and/or modify
# the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
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

