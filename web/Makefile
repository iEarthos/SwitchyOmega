include ../Makefile.inc

ENTRY_POINTS=$(shell ls -1 options/*.html | sed -e "s/^/out\//")

all: entries out/packages pack_options js

entries: $(ENTRY_POINTS)

out/%.html: %.html
	$(DART_WEB_COMPILER) --basedir=. -o out/ $<
	sed -i 's/\/OUTDIR\///g' $@
	# Remove dart script from the safe wrappers.
	# These scripts do not have actual effects but they break CSP.
	if echo $@ | grep '_safe.html$$'; then \
		sed -i 's/^.*\.html_bootstrap\.dart".*\/script>//g' $@; \
		sed -i 's/^.*\/dart\.js".*\/script>//g' $@; \
	fi

SCRIPTS=$(shell find -P out/options/ -name '*.dart' ! -path "*/_from_packages/*" \
				        ! -name 'editors.dart' | sed -e "s/$$/.js/")

js: entries $(SCRIPTS)

out/options/options.html: options/options.dart options/editors.dart \
	$(shell find ../lib -name "*.dart")

options/packages: entries
	@if [ "`readlink $@`" != '../../ipackages' ]; then \
		ln -sfT ../../ipackages $@; \
	fi

pack_options: options/packages
	@if [ -n `readlink out/options/packages/web_ui | grep -o '^/'` ]; then \
		rm -rf out/options/packages; \
		ln -sfT ../../../ipackages out/options/packages; \
	fi
