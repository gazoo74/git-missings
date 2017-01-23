#!/bin/sh
#
# Copyright (c) 2017 Gaël PORTAY <gael.portay@savoirfairelinux.com>
#
# This program is free software: you can redistribute it and/or modify
# the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#

PREFIX ?= /usr/local

all: git-patch.1.gz

man: git-patch.1.gz

install:
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 git-patch $(DESTDIR)$(PREFIX)/bin
	install -d $(DESTDIR)$(PREFIX)/share/man/man1/
	install -m 644 git-patch.1.gz $(DESTDIR)$(PREFIX)/share/man/man1/

uninstall:
	rm -rf $(DESTDIR)$(PREFIX)/bin/git-patch
	rm -rf $(DESTDIR)$(PREFIX)/share/man/man1/git-patch.1.gz

clean:
	rm -f git-patch.1.gz

%.1: %.1.adoc
	asciidoctor -b manpage -o $@ $<

%.gz: %
	gzip -c $^ >$@
