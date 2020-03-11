
# NOTE: these are needed by the configure.in inside the packages folder
N2N_VERSION_SHORT=2.5.1
GIT_COMMITS=247

########

CC=mipsel-linux-uclibc-gcc
DEBUG?=-g3
#OPTIMIZATION?=-O2
WARN?=-Wall

#Ultrasparc64 users experiencing SIGBUS should try the following gcc options
#(thanks to Robert Gibbon)
PLATOPTS_SPARC64=-mcpu=ultrasparc -pipe -fomit-frame-pointer -ffast-math -finline-functions -fweb -frename-registers -mapp-regs

N2N_OBJS_OPT=
LIBS_EDGE_OPT=-lcrypto

#OPENSSL_CFLAGS=$(shell pkg-config openssl; echo $$?)
#ifeq ($(OPENSSL_CFLAGS), 0)
#	CFLAGS+=$(shell pkg-config --cflags-only-I openssl)
#endif
CFLAGS+=-static
CFLAGS+="-I/home/starx/openssl-1.1.1d/include"
#
CFLAGS+=$(DEBUG) $(OPTIMIZATION) $(WARN) $(OPTIONS) $(PLATOPTS)

INSTALL=install
MKDIR=mkdir -p
OS := $(shell uname -s)

INSTALL_PROG=$(INSTALL) -m755
INSTALL_DOC=$(INSTALL) -m644

# DESTDIR set in debian make system
PREFIX?=$(DESTDIR)/usr
#BINDIR=$(PREFIX)/bin
ifeq ($(OS),Darwin)
SBINDIR=$(PREFIX)/local/sbin
else
SBINDIR=$(PREFIX)/sbin
endif

MANDIR?=$(PREFIX)/share/man
MAN1DIR=$(MANDIR)/man1
MAN7DIR=$(MANDIR)/man7
MAN8DIR=$(MANDIR)/man8

N2N_LIB=libn2n.a
N2N_OBJS=n2n.o wire.o minilzo.o twofish.o \
	 edge_utils.o \
         transform_null.o transform_tf.o transform_aes.o \
         tuntap_freebsd.o tuntap_netbsd.o tuntap_linux.o \
	 tuntap_osx.o
LIBS_EDGE+=$(LIBS_EDGE_OPT)
LIBS_SN=

#For OpenSolaris (Solaris too?)
ifeq ($(shell uname), SunOS)
LIBS_EDGE+=-lsocket -lnsl
LIBS_SN+=-lsocket -lnsl
endif

APPS=edge
APPS+=supernode
APPS+=example_edge_embed

DOCS=edge.8.gz supernode.1.gz n2n.7.gz

.PHONY: steps build push all clean install tools
all: $(APPS) $(DOCS) tools

tools: $(N2N_LIB)
	$(MAKE) -C $@

edge: edge.c $(N2N_LIB) n2n_wire.h n2n.h Makefile
	$(CC) $(CFLAGS) $< $(N2N_LIB) $(LIBS_EDGE) -o $@

supernode: sn.c $(N2N_LIB) n2n.h Makefile
	$(CC) $(CFLAGS) $< $(N2N_LIB) $(LIBS_SN) -o $@

example_edge_embed: example_edge_embed.c $(N2N_LIB) n2n.h
	$(CC) $(CFLAGS) $< $(N2N_LIB) $(LIBS_EDGE) -o $@

.c.o: n2n.h n2n_transforms.h n2n_wire.h twofish.h Makefile
	$(CC) $(CFLAGS) -c $< -o $@

%.gz : %
	gzip -c $< > $@

$(N2N_LIB): $(N2N_OBJS)
	ar rcs $(N2N_LIB) $(N2N_OBJS)
#	$(RANLIB) $@

clean:
	rm -rf $(N2N_OBJS) $(N2N_LIB) $(APPS) $(DOCS) test n2n-decode *.dSYM *~
	$(MAKE) -C tools clean

install: edge supernode edge.8.gz supernode.1.gz n2n.7.gz
	echo "MANDIR=$(MANDIR)"
	$(MKDIR) $(SBINDIR) $(MAN1DIR) $(MAN7DIR) $(MAN8DIR)
	$(INSTALL_PROG) supernode $(SBINDIR)/
	$(INSTALL_PROG) edge $(SBINDIR)/
	$(INSTALL_DOC) edge.8.gz $(MAN8DIR)/
	$(INSTALL_DOC) supernode.1.gz $(MAN1DIR)/
	$(INSTALL_DOC) n2n.7.gz $(MAN7DIR)/
	$(MAKE) -C tools install

# Docker builder section
DOCKER_IMAGE_NAME=ntop/supernode
DOCKER_IMAGE_VERSION=$N2N_VERSION_SHORT
N2N_COMMIT_HASH=d8871c2

default: steps

steps:
	if [ "$(TARGET_ARCHITECTURE)" = "arm32v7" ] || [ "$(TARGET_ARCHITECTURE)" = "" ]; then DOCKER_IMAGE_FILENAME="Dockerfile.arm32v7" DOCKER_IMAGE_TAGNAME=$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)-arm32v7 make build; fi
	if [ "$(TARGET_ARCHITECTURE)" = "x86_64" ] || [ "$(TARGET_ARCHITECTURE)" = "" ]; then DOCKER_IMAGE_FILENAME="Dockerfile.x86_64" DOCKER_IMAGE_TAGNAME=$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)-x86_64 make build; fi

build:
	$(eval OS := $(shell uname -s))
	$(eval ARCHITECTURE := $(shell export DOCKER_IMAGE_TAGNAME="$(DOCKER_IMAGE_TAGNAME)"; echo $$DOCKER_IMAGE_TAGNAME | grep -oe -.*))

	docker build --target builder --build-arg COMMIT_HASH=$(N2N_COMMIT_HASH) -t $(DOCKER_IMAGE_TAGNAME) -f image-platforms/$(DOCKER_IMAGE_FILENAME) .

	docker container create --name builder $(DOCKER_IMAGE_TAGNAME)
	if [ ! -d "./build" ]; then mkdir ./build; fi
	docker container cp builder:/usr/src/n2n/supernode ./build/supernode-$(OS)$(ARCHITECTURE)
	docker container cp builder:/usr/src/n2n/edge ./build/edge-$(OS)$(ARCHITECTURE)
	docker container rm -f builder

	docker build --build-arg COMMIT_HASH=$(N2N_COMMIT_HASH) -t $(DOCKER_IMAGE_TAGNAME) -f image-platforms/$(DOCKER_IMAGE_FILENAME) .
	docker tag $(DOCKER_IMAGE_TAGNAME) $(DOCKER_IMAGE_NAME):latest$(ARCHITECTURE)

push:
	if [ ! "$(TARGET_ARCHITECTURE)" = "" ]; then \
		docker push $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)-$(TARGET_ARCHITECTURE); \
		docker push $(DOCKER_IMAGE_NAME):latest-$(TARGET_ARCHITECTURE); \
	else \
		echo "Please pass TARGET_ARCHITECTURE, see README.md."; \
	fi

# End Docker builder section
