
SCRIPTPATH=/usr/local/bin/perl
APPS=`ls *.pl`

install:
	@if test ! -d ../../../bin ; then mkdir ../../../bin ; fi
	@for a in $(APPS) ; \
	do \
		if test -f ../../../bin/$$a ; then \
			if test ! -w ../../../bin/$$a ; then \
				chmod 777 ../../../bin/$$a ; \
			fi ; \
		fi ; \
		echo "#!$(SCRIPTPATH)" > ../../../bin/$$a ; \
		cat $$a >> ../../../bin/$$a ; \
		chmod 555 ../../../bin/$$a ; \
	done


