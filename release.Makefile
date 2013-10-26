include Makefile.inc

DEPLOY_FILES = $(addprefix deploy/, $(shell cd web && find ! -type l)) $(EXTRA_FILES)
EXTRA_FILES = deploy/out/background/packages/browser/dart.js \
							deploy/out/options/packages/browser/dart.js

all: SwitchyOmega.crx

deploy:
	mkdir -p deploy

SCRIPTS=$(addprefix deploy/,$(shell cd web && find -name '*.dart' \
				! -path "*/_from_packages/*" ! -name 'editors.dart'))

deploy/%.dart: web/%.dart
	@if (echo $@ | grep -q '_from_packages') || (echo $@ | grep -q 'editors.dart'); \
		then cp $< $@; \
		else $(DART2DART) -o$@ $<; \
	fi

deploy/%/packages/browser/dart.js :: web/%/packages/browser/dart.js
	@mkdir -p $(dir $@)
	@cp $< $@

deploy/% :: web/%
	@if [ -f $< ]; then cp $< $@; fi;
	@if [ -d $< ]; then mkdir -p $@; fi;

release: deploy $(DEPLOY_FILES)
	sed 's_"web/_"_g' < manifest.json > deploy/manifest.json
	
	sed -si -e '/^_convertNativeToDart_EventTarget/,/setInterval/ s/"setInterval" in e/"postMessage" in e \&\& "self" in e/' \
		$(shell find deploy/ -name "*.html_bootstrap.dart.js")

	find deploy/ -name "*.html" -exec \
		sed -i 's/\/OUTDIR\///g' {} +
	# Remove dart script from the safe wrappers.
	# These scripts do not have actual effects but they break CSP.
	find deploy/ -name "*_safe.html" -exec \
		sed -i -e 's/^.*\.html_bootstrap\.dart".*\/script>//g' \
		-e 's/^.*\/dart\.js".*\/script>//g' {} +
	cp -r _locales AUTHORS COPYING -t deploy/

SwitchyOmega.crx: release
	$(CHROMIUM) --pack-extension="$(realpath deploy)" \
		--pack-extension-key="$(shell readlink -f $(CHROMIUM_EXTENSION_KEY))"
	mv deploy.crx $@
