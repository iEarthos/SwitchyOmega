include ../Makefile.inc

ENTRY_POINTS=$(shell ls -1 options/*.html | sed -e "s/^/out\//")

all: entries out/packages pack_options

entries: $(ENTRY_POINTS)

out/%.html: %.html
	$(DART_WEB_COMPILER) --basedir=. -o out/ $<
	sed -i 's/\/OUTDIR\///g' $@

SCRIPTS=$(shell find -P out/options/ -name '*.dart' ! -path "*/_from_packages/*" \
				        | sed -e "s/$$/.js/")

js: entries $(SCRIPTS)

out/options/options.html: options/options.dart options/editors.dart ../lib

options/packages: entries
	@if [ "`readlink $@`" != '../../ipackages' ]; then \
		ln -sfT ../../ipackages $@; \
	fi

pack_options: options/packages
	@if [ -n `readlink out/options/packages/web_ui | grep -o '^/'` ]; then \
		rm -rf out/options/packages; \
		ln -sfT ../../../ipackages out/options/packages; \
	fi
