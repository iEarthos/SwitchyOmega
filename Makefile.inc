DART_BIN = ~/dart/dart-sdk/bin
DART_COMPILER = $(DART_BIN)/dart2js
DART_COMPILER_OPTIONS = -c
DART_RUNTIME = $(DART_BIN)/dart
DART_WEB_COMPILER = $(DART_RUNTIME) --package-root=packages/ packages/web_ui/dwc.dart 
DART2DART = $(DART_COMPILER) --output-type=dart
CHROMIUM = chromium-browser
CHROMIUM_EXTENSION_KEY = SwitchyOmega.pem
PUB=$(DART_BIN)/pub

.PHONY: dwc

%.dart.js: %.dart
	$(DART_COMPILER) $(DART_COMPILER_OPTIONS) -o$@ $<
