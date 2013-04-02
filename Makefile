include Makefile.inc

SUBDIRS = test web

all: $(SUBDIRS)

.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@
