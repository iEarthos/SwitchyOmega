include ../Makefile.inc

ENTRY_POINTS=$(shell ls -1 options/*.html | sed -e "s/^/out\//")

all: entries out/packages pack_options js

entries: $(ENTRY_POINTS)

out/%.html: %.html
	$(DART_WEB_COMPILER) --basedir=. -o out/ $<

SCRIPTS=$(shell find -P out/options/ -name '*.dart' | sed -e "s/$$/.js/")

js: entries $(SCRIPTS)

out/options/options.html: options/options.dart

out/packages: entries
	@if [ ! -d $@ ]; then \
		mkdir -p $@; \
		ln -sfT ../../../lib/ $@/switchyomega; \
		cp -rnL $(shell ls -d packages/* | grep -v 'switchyomega') $@; \
	fi

pack_options: out/packages
	@if [ -n `readlink out/options/packages/web_ui | grep -o '^/'` ]; then \
		rm -rf out/options/packages; \
		mkdir -p out/options/packages/; \
		cd out/options/packages && ln -sf ../../packages/* .; \
	fi
