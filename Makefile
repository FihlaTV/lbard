BINDIR=.
EXECS = $(BINDIR)/lbard $(BINDIR)/manifesttest $(BINDIR)/fakecsmaradio

all:	$(EXECS)

clean:
	rm -rf version.h $(EXECS) echotest

SRCDIR=src
INCLUDEDIR=include

RADIODRIVERS=	$(SRCDIR)/drivers/drv_*.c
RADIOHEADERS=	$(SRCDIR)/drivers/drv_*.h

SRCS=	$(SRCDIR)/main.c \
	$(SRCDIR)/rhizome.c \
	$(SRCDIR)/txmessages.c \
	$(SRCDIR)/rxmessages.c \
	$(SRCDIR)/bundle_cache.c \
	$(SRCDIR)/json.c \
	$(SRCDIR)/peers.c \
	\
	$(SRCDIR)/serial.c \
	$(SRCDIR)/radio.c \
	$(SRCDIR)/golay.c \
	$(SRCDIR)/httpclient.c \
	$(SRCDIR)/progress.c \
	$(SRCDIR)/rank.c \
	$(SRCDIR)/bundles.c \
	$(SRCDIR)/partials.c \
	\
	$(SRCDIR)/manifests.c \
	$(SRCDIR)/monitor.c \
	$(SRCDIR)/timesync.c \
	$(SRCDIR)/httpd.c \
	$(SRCDIR)/meshms.c \
	\
	$(SRCDIR)/energy_experiment.c \
	$(SRCDIR)/status_dump.c \
	\
	$(SRCDIR)/fec-3.0.1/ccsds_tables.c \
	$(SRCDIR)/fec-3.0.1/encode_rs_8.c \
	$(SRCDIR)/fec-3.0.1/init_rs_char.c \
	$(SRCDIR)/fec-3.0.1/decode_rs_8.c \
	\
	$(SRCDIR)/bundle_tree.c \
	$(SRCDIR)/sha1.c \
	$(SRCDIR)/sync.c \
	\
	$(SRCDIR)/eeprom.c \
	$(SRCDIR)/sha3.c \
	$(SRCDIR)/otaupdate.c \
	\
	$(SRCDIR)/util.c \
	\
	$(SRCDIR)/hf_ale.c \
	$(SRCDIR)/hf_config.c \
	$(SRCDIR)/radio_types.c \
	$(RADIODRIVERS)


HDRS=	$(INCLUDEDIR)/lbard.h \
	$(INCLUDEDIR)/serial.h \
	Makefile \
	$(INCLUDEDIR)/sync.h \
	$(INCLUDEDIR)/sha3.h \
	$(INCLUDEDIR)/util.h \
	$(INCLUDEDIR)/radios.h \
	$(RADIOHEADERS) \
	$(SRCDIR)/miniz.c

#CC=/usr/local/Cellar/llvm/3.6.2/bin/clang
#LDFLAGS= -lgmalloc
#CFLAGS= -fno-omit-frame-pointer -fsanitize=address
#CC=clang
#LDFLAGS= -lefence
LDFLAGS=
# -I$(SRCDIR) is required for fec-3.0.1
CFLAGS= -g -std=gnu99 -Wall -fno-omit-frame-pointer -D_GNU_SOURCE=1 -I$(INCLUDEDIR) -I$(SRCDIR)

$(INCLUDEDIR)/version.h:	$(SRCS) $(HDRS)
	echo "#define VERSION_STRING \""`./md5 $(SRCS)`"\"" >$(INCLUDEDIR)/version.h
	echo "#define GIT_VERSION_STRING \""`git describe --always --abbrev=10 --dirty=+DIRTY`"\"" >>$(INCLUDEDIR)/version.h
	echo "#define GIT_BRANCH \""`git rev-parse --abbrev-ref HEAD`"\"" >>$(INCLUDEDIR)/version.h
	echo "#define BUILD_DATE \""`date`"\"" >>$(INCLUDEDIR)/version.h

lbard:	$(SRCS) $(HDRS) $(INCLUDEDIR)/version.h
	$(CC) $(CFLAGS) -o lbard $(SRCS) $(LDFLAGS)

echotest:	Makefile echotest.c
	$(CC) $(CFLAGS) -o echotest echotest.c

FAKERADIOSRCS=	$(SRCDIR)/fakeradio/fakecsmaradio.c \
		$(SRCDIR)/drivers/fake_*.c \
		\
		$(SRCDIR)/fec-3.0.1/ccsds_tables.c \
		$(SRCDIR)/fec-3.0.1/encode_rs_8.c \
		$(SRCDIR)/fec-3.0.1/init_rs_char.c \
		$(SRCDIR)/fec-3.0.1/decode_rs_8.c
fakecsmaradio:	\
	Makefile $(FAKERADIOSRCS) $(INCLUDEDIR)/fakecsmaradio.h
	$(CC) $(CFLAGS) -o fakecsmaradio $(FAKERADIOSRCS)

$(BINDIR)/manifesttest:	Makefile $(SRCDIR)/manifests.c $(SRCDIR)/util.c
	$(CC) $(CFLAGS) -DTEST -o $(BINDIR)/manifesttest $(SRCDIR)/manifests.c $(SRCDIR)/util.c

$(INCLUDEDIR)/radios.h:	$(RADIODRIVERS) Makefile
	echo "Radio driver files: $(RADIODRIVERS)"
	echo '#include "radio_type.h"' > $(INCLUDEDIR)/radios.h
	echo "" >> $(INCLUDEDIR)/radios.h
	grep "^RADIO TYPE:" src/drivers/*.c | cut -f3 -d: | cut -f1 -d, | awk '{ printf("#define RADIOTYPE_%s %d\n",$$1,n); n++; }' >> $(INCLUDEDIR)/radios.h
	echo "" >> $(INCLUDEDIR)/radios.h
	for fn in `(cd $(SRCDIR); echo drivers/drv_*.h)`; do echo "#include \"$$fn\""; done >> $(INCLUDEDIR)/radios.h
	echo "" >> $(INCLUDEDIR)/radios.h

$(SRCDIR)/radio_types.c:	$(RADIODRIVERS) Makefile
	echo '#include <stdio.h>' > $(SRCDIR)/radio_types.c
	echo '#include <fcntl.h>' >> $(SRCDIR)/radio_types.c
	echo '#include <sys/uio.h>' >> $(SRCDIR)/radio_types.c
	echo '#include <sys/socket.h>' >> $(SRCDIR)/radio_types.c
	echo '#include <time.h>' >> $(SRCDIR)/radio_types.c
	echo '#include "sync.h"' >> $(SRCDIR)/radio_types.c
	echo '#include "lbard.h"' >> $(SRCDIR)/radio_types.c
	echo '#include "hf.h"' >> $(SRCDIR)/radio_types.c
	echo '#include "radios.h"' >> $(SRCDIR)/radio_types.c
	echo '' >> $(SRCDIR)/radio_types.c
	echo "radio_type radio_types[]={" >> $(SRCDIR)/radio_types.c
	grep "^RADIO TYPE:" $(RADIODRIVERS) | cut -f3- -d: | sed -e 's/^ /  {RADIOTYPE_/' -e 's/$$/\},/' >> $(SRCDIR)/radio_types.c
	echo "  {-1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,-1}" >> $(SRCDIR)/radio_types.c
	echo "};" >> $(SRCDIR)/radio_types.c

