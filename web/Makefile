include ../Makefile.inc

ENTRY_POINTS=$(addprefix out/,$(wildcard options/*.html background/*.html))

all: dwc js

dwc: entries out/packages pack_options pack_background

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

SCRIPTS=$(addsuffix .js,$(shell find -P out/ -name '*.dart' ! -path "*/_from_packages/*" \
				        ! -name 'editors.dart'))

js: entries $(SCRIPTS)

out/options/options.html: options/options.dart options/editors.dart \
	$(shell find ../lib -name "*.dart")

out/background/background.html: background/background.dart background/upgrade.dart \
	$(shell find ../lib -name "*.dart")

options/packages background/packages: entries
	@if [ "`readlink $@`" != '../../ipackages' ]; then \
		ln -sfT ../../ipackages $@; \
	fi

out/options/packages out/background/packages: entries
	@if [ "`readlink $@`" != '../../../ipackages' ]; then \
		ln -sfT ../../../ipackages $@; \
	fi

pack_options pack_background: background/packages
	@if [ -n `readlink out/$</web_ui | grep -o '^/'` ]; then \
		rm -rf out/$<; \
		ln -sfT ../../../ipackages out/$<; \
	fi
