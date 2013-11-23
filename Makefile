include Makefile.inc

SUBDIRS = test web

all: ipackages $(SUBDIRS)

dwc: subdirs

.PHONY: subdirs $(SUBDIRS)

packages:
	$(PUB) install

ipackages: packages
	if [ -d "ipackages" -a -L "ipackages/switchyomega" ]; then \
		unlink ipackages/switchyomega; \
		rm -r ipackages/; \
	fi
	mkdir ipackages
	ln -s ../lib/ ipackages/switchyomega
	cp -rnL `echo packages/* | sed -e "s/packages\/switchyomega//"` ipackages/
	make -C web out/packages out/options/packages out/background/packages

release: all
	make -f release.Makefile

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) $(findstring dwc,$(MAKECMDGOALS)) -C $@
