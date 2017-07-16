#
# Copyright (c) 2017-2019 Gaël PORTAY
#
# SPDX-License-Identifier: GPL-3.0
#

PREFIX ?= /usr/local

.PHONY: all
all: man

.PHONY: man
man: git-patch.1.gz git-format-mbox.1.gz git-ad.1.gz

.PHONY: check
check: git-patch git-format-mbox git-ad
	shellcheck $^

.PHONY: alias
alias:
	git config --global alias.last 'log -1 HEAD'
	git config --global alias.unstage 'reset HEAD --'
	git config --global alias.cached 'diff --cached'
	git config --global alias.fixup '!f() { git commit --fixup=$${1:-HEAD}; }; f'
	git config --global alias.autosquash 'rebase -i --autosquash --autostash'
	git config --global alias.upstream 'rev-parse --abbrev-ref --symbolic-full-name @{u}'
	git config --global alias.oneline 'log --oneline'
	git config --global alias.k 'log --graph --oneline'
	git config --global alias.graph 'log --graph --oneline --decorate'
	git config --global alias.ahead '!f() { br="$$(git upstream)"; git graph $${br:+$$br..}$${1:-HEAD}; }; f'
	git config --global alias.amend 'commit --amend'
	git config --global alias.sign-off 'commit --amend --signoff'
	git config --global alias.unstage 'reset HEAD --'
	git config --global alias.autoresolve 'patch --autoresolve'
	git config --global alias.reword 'commit --amend'
	git config --global alias.author 'commit --amend --author "Gaël PORTAY <gael.portay@savoirfairelinux.com>"'
	git config --global alias.sign-off 'commit --amend --signoff'
	git config --global alias.unstage 'reset HEAD --'

.PHONY: variables
variables:
	git config --global rebase.autoStash true
	git config --global pull.rebase true
	git config --global status.short true

.PHONY: install-all
install-all: install install-bash-completion

.PHONY: install
install:
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 git-patch git-format-mbox git-ad \
	           $(DESTDIR)$(PREFIX)/bin
	install -d $(DESTDIR)$(PREFIX)/lib
	for bin in git-patch git-format-mbox git-ad; do \
		ln -sf ../bin/$$bin $(DESTDIR)$(PREFIX)/lib/; \
	done
	install -d $(DESTDIR)$(PREFIX)/share/man/man1/
	install -m 644 git-patch.1.gz git-format-mbox.1.gz git-ad.1.gz \
	           $(DESTDIR)$(PREFIX)/share/man/man1/

.PHONY: install-bash-completion
install-bash-completion:
	completionsdir="$${BASHCOMPLETIONSDIR:-$$(pkg-config --define-variable=prefix=$(PREFIX) \
	                                                     --variable=completionsdir \
	                                                     bash-completion)}"; \
	if [ -n "$$completionsdir" ]; then \
		install -d $(DESTDIR)$$completionsdir/; \
		for bash in git-patch git-format-mbox git-ad; do \
			install -m 644 bash-completion/$$bash \
			        $(DESTDIR)$$completionsdir/; \
		done; \
	fi

.PHONY: uninstall
uninstall:
	for bin in git-patch git-format-mbox git-ad; do \
		rm -f $(DESTDIR)$(PREFIX)/bin/$$bin; \
	done
	for lib in git-patch git-format-mbox git-ad; do \
		rm -f $(DESTDIR)$(PREFIX)/lib/$$lib; \
	done
	for man in git-patch.1.gz git-format-mbox.1.gz git-ad.1.gz; do \
		rm -f $(DESTDIR)$(PREFIX)/share/man/man1/$$man; \
	done

.PHONY: uninstall-bash-completion
uninstall-bash-completion:
	completionsdir="$${BASHCOMPLETIONSDIR:-$$(pkg-config --define-variable=prefix=$(PREFIX) \
	                                                     --variable=completionsdir \
	                                                     bash-completion)}"; \
	if [ -n "$$completionsdir" ]; then \
		for bash in git-patch git-format-mbox git-ad; do \
			rm -f $(DESTDIR)$$completionsdir/$$bash; \
		done
	fi

.PHONY: user-install-all
user-install-all: user-install user-install-bash-completion

user-install user-install-bash-completion user-uninstall user-uninstall-bash-completion:
user-%:
	$(MAKE) $* PREFIX=$$HOME/.local BASHCOMPLETIONSDIR=$$HOME/.local/share/bash-completion/completions

.PHONY: tests
tests:
	$(MAKE) -sC $@

.PHONY: clean
clean:
	$(MAKE) -sC tests mrproper
	rm -f git-patch.1.gz git-format-mbox.1.gz git-ad.1.gz

.PHONY: mrproper
mrproper: clean
	$(MAKE) -sC tests mrproper

%.1: %.1.adoc
	asciidoctor -b manpage -o $@ $<

%.gz: %
	gzip -c $^ >$@

