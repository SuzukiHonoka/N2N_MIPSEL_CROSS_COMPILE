CC=mipsel-linux-uclibc-gcc
DEBUG?=-g3
#OPTIMIZATION?=-O2
WARN?=-Wall

INSTALL=install
INSTALL_PROG=$(INSTALL) -m755
MKDIR=mkdir -p

PREFIX?=$(DESTDIR)/usr
ifeq ($(OS),Darwin)
SBINDIR=$(PREFIX)/local/sbin
else
SBINDIR=$(PREFIX)/sbin
endif

LIBS_EDGE_OPT=-lcrypto
LIBS_EDGE+=$(LIBS_EDGE_OPT)
HEADERS=../n2n_wire.h ../n2n.h ../twofish.h ../n2n_transforms.h
CFLAGS+=-I..
LDFLAGS+=-L..
CFLAGS+=$(DEBUG) $(OPTIMIZATION) $(WARN)

N2N_LIB=../libn2n.a

TOOLS=n2n-benchmark
TOOLS+=

.PHONY: all clean install
all: $(TOOLS)

n2n-benchmark: benchmark.c $(N2N_LIB) $(HEADERS)
	$(CC) $(CFLAGS) $< $(N2N_LIB) $(LIBS_EDGE) -o $@

n2n-decode: n2n_decode.c $(N2N_LIB) $(HEADERS)
	$(CC) $(CFLAGS) $< $(N2N_LIB) $(LIBS_EDGE) -lpcap -o $@

.c.o: $(HEADERS) ../Makefile Makefile
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(TOOLS) $(N2N_LIB) *.o *.dSYM *~

install: $(TOOLS)
	$(INSTALL_PROG) $(TOOLS) $(SBINDIR)/
