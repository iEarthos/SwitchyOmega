include ../Makefile.inc

ENTRY_POINTS=$(addprefix out/,$(wildcard options/*.html background/*.html))

all: dwc js

dwc: entries out/packages out/options/packages out/background/packages

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

# Disable checked mode to workaround dart2js issues with ObservableSet.
out/background/background.html_bootstrap.dart.js: out/background/background.html_bootstrap.dart
	$(DART_COMPILER) -o$@ $<

out/options/options.html: options/options.dart options/editors.dart \
	$(shell find ../lib -name "*.dart")

out/background/background.html: background/background.dart background/upgrade.dart \
	$(shell find ../lib -name "*.dart")

options/packages background/packages out/packages: ../ipackages | entries
	@if [ "`readlink $@`" != '../$<' ]; then \
		ln -sfT ../$< $@; \
	fi

out/options/packages out/background/packages: ../ipackages | entries
	@if [ "`readlink $@`" != '../../$<' ]; then \
		ln -sfT ../../$< $@; \
	fi
