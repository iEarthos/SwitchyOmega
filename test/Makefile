include ../Makefile.inc

all: pac_gen_test.dart.js

pac_gen_test.dart.js: pac_gen_test.dart \
	../lib/code_writer.dart ../lib/profile/* ../lib/condition/* ../lib/html/* \
	../lib/lang/*
	$(DART_COMPILER) $(DART_COMPILER_OPTIONS) -o$@ $<
