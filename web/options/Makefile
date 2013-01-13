include ../Makefile.inc

all : options.dart.js

options.dart.js: options.dart ../html/* ../lang/*
	$(DART_COMPILER) $(DART_COMPILER_OPTIONS) -o$@ $<
