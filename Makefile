#
# Makefile.local must define the following variables
#  BINDIR
#  LIBDIR
#  INCDIR
#  PYDIR
#  CPP
#
# See site/Makefile.local.* for an example (in fact, you may just be able to
# symlink or copy one of these files to ./Makefile.local)
#
include Makefile.local

EXE_NOINSTALL=run-unit-tests
SCRIPT_INSTALL=frb-compare.py frb-dump.py
PY_INSTALL=frb_olympics.py frb_combiner.py frb_downsample.py frb_rechunk.py frb_fdmt.py

all: libfrb_olympics.so frb_olympics_c.so $(EXE_NOINSTALL)

%.o: %.cpp frb_olympics.hpp
	$(CPP) -c -o $@ $<

libfrb_olympics.so: frb_misc.o frb_pulse.o frb_rng.o frb_search_params.o frb_simple_direct.o frb_sloth.o frb_bonsai.o
	$(CPP) $(LDFLAGS) -o $@ -shared $^ -lbonsai -lfftw3 -lhdf5

frb_olympics_c.cpp: frb_olympics_c.pyx _frb_olympics_c.pxd frb_olympics.hpp
	cython --cplus $<

frb_olympics_c.so: frb_olympics_c.cpp libfrb_olympics.so
	$(CPP) -Wno-unused-function $(LDFLAGS) -shared -o $@ $< -lfrb_olympics -lbonsai -lfftw3 -lhdf5 $(LIBS_PYMODULE)

run-unit-tests: run-unit-tests.o libfrb_olympics.so
	$(CPP) -o $@ $^

install: libfrb_olympics.so frb_olympics_c.so
	cp -f frb_olympics.hpp $(INCDIR)/frb_olympics.hpp
	cp -f libfrb_olympics.so $(LIBDIR)/libfrb_olympics.so
	cp -f frb_olympics_c.so $(PYDIR)/frb_olympics_c.so
	cp -f $(SCRIPT_INSTALL) $(BINDIR)/
	cp -f $(PY_INSTALL) $(PYDIR)/

clean:
	rm -f *~ *.o *.so frb_olympics_c.cpp $(EXE_NOINSTALL)

uninstall:
	for f in $(SCRIPT_INSTALL); do rm -f $(BINDIR)/$$f; done
	for f in $(PY_INSTALL); do rm -f $(PYDIR)/$$f; done
	rm -f $(INCDIR)/frb_olympics.hpp $(LIBDIR)/libfrb_olympics.so $(PYDIR)/frb_olympics_c.so

