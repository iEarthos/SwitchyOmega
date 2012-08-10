include Makefile.inc

all : pac_gen_test options

subdir:
	true

pac_gen_test : pac_gen_test.dart.js

pac_gen_test.dart.js : pac_gen_test.dart profile/* condition/* utils/* lang/*
	$(DART_COMPILER) $(DART_COMPILER_OPTIONS) -o$@ $<

options : subdir
	cd options;	$(MAKE) $(MFLAGS)
