#!/bin/bash
# flashrom programmer driver skeleton builder.
# Copyright 2012 Carl-Daniel Hailfinger
# Licensed under the GNU GPL v2

# Fill in all info in the block below, and don't touch anything else.
# The data provided here is just an example.
# Name of the programmer. Needs to be an all-lowercase valid C identifier
PROGRAMMERNAME=ezo
# Short description of the programmer. Please do not use / inside the name, it will break the sed expressions.
PROGRAMMERDESCR="EZo+Willem Programmer"
# Name of the programmer manufacturer.
PROGRAMMERMANUF="EZo and Willem"
# Website for the programmer.
PROGRAMMERURL="http://www.ezoflash.com/"
# Fill in your name here.
AUTHORNAME="Carl-Daniel Hailfinger"
# Does the programmer need a map/unmap function?
HAVE_MAP=no
# Does the programmer have its own delay function?
HAVE_DELAY=no
# Does the programmer need some sort of direct hardware access?
NEED_PCI=yes
# Does the programmer need some sort of serial port access?
NEED_SERIAL=no
# Is the programmer a PCI device, USB device, or something else?
# You have to specify exactly one of PCI, USB, OTHER
DEVICETYPE=USB
# Note: Usually a programmer only has one of NEED_PARLPCFWH, NEED_SPI or NEED_SPI_BITBANG set to yes.
# Does the programmer use Parallel/LPC/FWH functionality?
NEED_PARLPCFWH=yes
# Which of PARALLEL/LPC/FWH buses does the programer use?
BUS_PARLPCFWH=LPC
# Does the programmer use SPI functionality without bitbanging?
NEED_SPI=yes
# Does the programmer use the bitbanging SPI infrastructure?
NEED_SPI_BITBANG=yes

# No user serviceable parts below.
if test $HAVE_MAP = yes; then MAPNAME=$PROGRAMMERNAME; else MAPNAME=fallback; fi
if test $HAVE_DELAY = yes; then DELAYNAME=$PROGRAMMERNAME; else DELAYNAME=internal; fi
PROGRAMMERNAMECAPS=$(echo -n $PROGRAMMERNAME|tr "[[:lower:]]" "[[:upper:]]")
CONFIGNAME=CONFIG_$PROGRAMMERNAMECAPS
ENUMNAME=PROGRAMMER_$PROGRAMMERNAMECAPS
SPI_CONTROLLERNAME=SPI_CONTROLLER_$PROGRAMMERNAMECAPS
BITBANG_SPI_ENUMNAME=BITBANG_SPI_MASTER_$PROGRAMMERNAMECAPS
if test $NEED_PCI = yes; then NEEDS="NEED_PCI := yes\n"; fi
if test $NEED_SERIAL = yes; then NEEDS+="NEED_SERIAL := yes\n"; fi

sed "s-^//PLACEHOLDER_NEWPROG_PROGRAMMER_ARRAY-\
#if ${CONFIGNAME} == 1\n\
	{\n\
		.name			= \"${PROGRAMMERNAME}\",\n\
\0-" flashrom.c >flashrom.c.mine
if test $DEVICETYPE = OTHER; then
sed "s-^//PLACEHOLDER_NEWPROG_PROGRAMMER_ARRAY-\
		.type			= OTHER,\n\
		.devs.note		= \"Textual list of usable devices\\\\n\",\n\
\0-" flashrom.c.mine >flashrom.c.mine1
mv flashrom.c.mine1 flashrom.c.mine
else
sed "s-^//PLACEHOLDER_NEWPROG_PROGRAMMER_ARRAY-\
		.type			= ${DEVICETYPE},\n\
		.devs.dev		= devs_${PROGRAMMERNAME},\n\
\0-" flashrom.c.mine >flashrom.c.mine1
mv flashrom.c.mine1 flashrom.c.mine
fi
sed "s-^//PLACEHOLDER_NEWPROG_PROGRAMMER_ARRAY-\
		.init			= ${PROGRAMMERNAME}_init,\n\
		.map_flash_region	= ${MAPNAME}_map,\n\
		.unmap_flash_region	= ${MAPNAME}_unmap,\n\
		.delay			= ${DELAYNAME}_delay,\n\
	},\n\
#endif\n\
\n\0-" flashrom.c.mine >flashrom.c.mine1
mv flashrom.c.mine1 flashrom.c.mine

sed -e "s/^#PLACEHOLDER_NEWPROG_DEFAULTCONFIG/\
# Enable ${PROGRAMMERDESCR} for now.\n\
${CONFIGNAME} ?= yes\n\
\n\0/" \
-e "s/^#PLACEHOLDER_NEWPROG_COMPILERULE/\
ifeq (\$(${CONFIGNAME}), yes)\n\
FEATURE_CFLAGS += -D'${CONFIGNAME}=1'\n\
PROGRAMMER_OBJS += ${PROGRAMMERNAME}.o\n\
${NEEDS}\
endif\n\
\n\0/" Makefile >Makefile.mine

if test $NEED_SPI_BITBANG = yes; then
sed -e "s/^#PLACEHOLDER_NEWPROG_BITBANGSPICONFIG1/\
ifeq (\$(${CONFIGNAME}), yes)\n\
override CONFIG_BITBANG_SPI = yes\n\
else\n\
\0/" \
-e "s/^#PLACEHOLDER_NEWPROG_BITBANGSPICONFIG2/\
\0\n\
endif/;" Makefile.mine >Makefile.mine1
mv Makefile.mine1 Makefile.mine
fi

sed -e "s-^//PLACEHOLDER_NEWPROG_PROGRAMMER_ENUM-\
#if ${CONFIGNAME} == 1\n\
	${ENUMNAME},\n\
#endif\n\
\0-" \
-e "s-^//PLACEHOLDER_NEWPROG_PUBLICFUNCTIONS-\
/* ${PROGRAMMERNAME}.c */\n\
#if ${CONFIGNAME} == 1\n\
int ${PROGRAMMERNAME}_init(void);\n\
\0-" programmer.h >programmer.h.mine

if test $DEVICETYPE = PCI -o $DEVICETYPE = USB; then
sed -e "s-^//PLACEHOLDER_NEWPROG_PUBLICFUNCTIONS-\
extern const struct dev_entry devs_${PROGRAMMERNAME}[];\n\
\n\0-" programmer.h.mine >programmer.h.mine1
mv programmer.h.mine1 programmer.h.mine
fi

sed -e "s-^//PLACEHOLDER_NEWPROG_PUBLICFUNCTIONS-\
#endif\n\
\n\0-" programmer.h.mine >programmer.h.mine1
mv programmer.h.mine1 programmer.h.mine

if test $NEED_SPI_BITBANG = yes; then
sed -e "s-^//PLACEHOLDER_NEWPROG_PROGRAMMER_BITBANG_ENUM-\
#if ${CONFIGNAME} == 1\n\
	${BITBANG_SPI_ENUMNAME},\n\
#endif\n\
\0-" \
-e "s-//PLACEHOLDER_NEWPROG_SELECT_SPI_BITBANG\$-\
|| ${CONFIGNAME} == 1 \0-" programmer.h.mine >programmer.h.mine1
mv programmer.h.mine1 programmer.h.mine
fi

if test $NEED_SPI = yes; then
sed -e "s-^//PLACEHOLDER_NEWPROG_SPI_CONTROLLER_ENUM-\
#if ${CONFIGNAME} == 1\n\
	${SPI_CONTROLLERNAME},\n\
#endif\n\
\0-" programmer.h.mine >programmer.h.mine1
mv programmer.h.mine1 programmer.h.mine
fi

# No idea if roff supports hidden comments. Hook up to hopefully unchanged sequences.
sed -e "s/.*PLACEHOLDER_NEWPROG_MAN_SHORTDESCRIPTION/\
.BR \"* ${PROGRAMMERNAME}\" \" (${PROGRAMMERDESCR})\"\n\
.sp\n\
\0/" \
-e "s/.*PLACEHOLDER_NEWPROG_MAN_LONGDESCRIPTION/\
.SS\n\
.BR \"${PROGRAMMERNAME} \" programmer\n\
Please describe the programmer parameters here.\n\
\0/" \
-e "s/.*PLACEHOLDER_NEWPROG_MAN_REQUIREMENTS/\
.B ${PROGRAMMERNAME}\n\
Please describe the programmer requirements here.\n\
.sp\n\
\0/" flashrom.8.tmpl > flashrom.8.mine

cat >$PROGRAMMERNAME.c.mine <<EOF
/*
 * This file is part of the flashrom project.
 *
 * Copyright (C) $(date +%Y) ${AUTHORNAME}
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
 */

/* Driver for the ${PROGRAMMERDESCR} hardware by ${PROGRAMMERMANUF}.
 * See ${PROGRAMMERURL} for more info.
 */

#include "flash.h"
#include "programmer.h"

EOF

if test $DEVICETYPE = PCI -o $DEVICETYPE = USB; then
cat >>$PROGRAMMERNAME.c.mine <<EOF
const struct dev_entry devs_${PROGRAMMERNAME}[] = {
	{0xdead, 0xbeef, NT, "Vendor name", "Device name"},

	{0},
};

EOF
fi

if test $NEED_PARLPCFWH = yes; then
cat >>$PROGRAMMERNAME.c.mine <<EOF
static void ${PROGRAMMERNAME}_chip_writeb(const struct flashctx *flash, uint8_t val, chipaddr addr)
{
	/* Write a byte to the flash chip. */
}

static uint8_t ${PROGRAMMERNAME}_chip_readb(const struct flashctx *flash, const chipaddr addr)
{
	/* Read a byte from the flash chip and return it. */
	/* Set it to 0xff to get the template to compile. */
	uint8_t val = 0xff;

	return val;
}

static const struct par_master par_master_${PROGRAMMERNAME} = {
		.chip_readb		= ${PROGRAMMERNAME}_chip_readb,
		/* If your programmer supports word/long accesses, change the lines below. */
		.chip_readw		= fallback_chip_readw,
		.chip_readl		= fallback_chip_readl,
		.chip_readn		= fallback_chip_readn,
		.chip_writeb		= ${PROGRAMMERNAME}_chip_writeb,
		.chip_writew		= fallback_chip_writew,
		.chip_writel		= fallback_chip_writel,
		.chip_writen		= fallback_chip_writen,
};

EOF
fi

if test $NEED_SPI_BITBANG = yes; then
cat >>$PROGRAMMERNAME.c.mine <<EOF
static void ${PROGRAMMERNAME}_bitbang_set_cs(int val)
{
	/* Set/clear the CS# line. */
}

static void ${PROGRAMMERNAME}_bitbang_set_sck(int val)
{
	/* Set/clear the SCLK line. */
}

static void ${PROGRAMMERNAME}_bitbang_set_mosi(int val)
{
	/* Set/clear the MOSI line. */
}

static int ${PROGRAMMERNAME}_bitbang_get_miso(void)
{
	/* Get the state of the MISO line and return it. */
	/* Set it to 1 to get the template to compile. */
	int misoval = 1;

	return misoval;
}

/* If this programmer does not support requesting/releasing the SPI bus, remove
 * the functions ${PROGRAMMERNAME}_request_spibus and ${PROGRAMMERNAME}_release_spibus
 * and set bitbang_spi_master_${PROGRAMMERNAME} members .request_bus and .release_bus
 * to NULL.
 */
static void ${PROGRAMMERNAME}_request_spibus(void)
{
}

static void ${PROGRAMMERNAME}_release_spibus(void)
{
}

static const struct bitbang_spi_master bitbang_spi_master_${PROGRAMMERNAME} = {
	.type = ${BITBANG_SPI_ENUMNAME},
	.set_cs = ${PROGRAMMERNAME}_bitbang_set_cs,
	.set_sck = ${PROGRAMMERNAME}_bitbang_set_sck,
	.set_mosi = ${PROGRAMMERNAME}_bitbang_set_mosi,
	.get_miso = ${PROGRAMMERNAME}_bitbang_get_miso,
	.request_bus = ${PROGRAMMERNAME}_request_spibus,
	.release_bus = ${PROGRAMMERNAME}_release_spibus,
	.half_period = 1, /* Delay in microseconds before each SCLK level change. */
};

EOF
fi

if test $NEED_SPI = yes; then
cat >>$PROGRAMMERNAME.c.mine <<EOF
/* Include string.h for memset to get the template to compile . Remove this. */
#include <string.h>
static int ${PROGRAMMERNAME}_spi_send_command(struct flashctx *flash,
			unsigned int writecnt, unsigned int readcnt,
			const unsigned char *writearr,
			unsigned char *readarr)
{
	/* Send a SPI command to the flash chip. */
	/* Set readarr to 0xff to get the template to compile and run without segfaults. */
	memset(readarr, 0xff, readcnt);

	return 0;
}

static const struct spi_master spi_master_${PROGRAMMERNAME} = {
	.type		= ${SPI_CONTROLLERNAME},
	.max_data_read	= 64 * 1024, /* Maximum data read size in one go (excluding opcode+address). */
	.max_data_write	= 256, /* Maximum data write size in one go (excluding opcode+address). */
	.command	= ${PROGRAMMERNAME}_spi_send_command,
	.multicommand	= default_spi_send_multicommand,
	.read		= default_spi_read,
	.write_256	= default_spi_write_256,
	.write_aai	= default_spi_write_aai,
};

EOF
fi

cat >>$PROGRAMMERNAME.c.mine <<EOF
static int ${PROGRAMMERNAME}_shutdown(void *data)
{
	/* Shutdown stuff. */
	return 0;
}

int ${PROGRAMMERNAME}_init(void)
{
	/* Init stuff (i.e. parameter parsing) here which does not need to be
	 * undone.
	 */

	/* If your shutdown function takes a parameter, replace NULL with it. */
	register_shutdown(${PROGRAMMERNAME}_shutdown, NULL);

	/* Init stuff which needs to be undone on shutdown. */

EOF

if test $NEED_SPI_BITBANG = yes; then
cat >>$PROGRAMMERNAME.c.mine <<EOF
	/* 1 usec halfperiod delay, change as needed. */
	if (bitbang_spi_init(&bitbang_spi_master_${PROGRAMMERNAME}))
		return 1;

EOF
fi

if test $NEED_SPI = yes; then
cat >>$PROGRAMMERNAME.c.mine <<EOF
	register_spi_master(&spi_master_${PROGRAMMERNAME});

EOF
fi

if test $NEED_PARLPCFWH = yes; then
cat >>$PROGRAMMERNAME.c.mine <<EOF
	register_par_master(&par_master_${PROGRAMMERNAME}, BUS_${BUS_PARLPCFWH});

EOF
fi

cat >>$PROGRAMMERNAME.c.mine <<EOF
	return 0;
}
EOF

echo "The driver skeleton has been created in $PROGRAMMERNAME.c.mine"
echo "Modified versions of existing files have been created with extension .mine"
echo "You can replace the original files with the modified versions by running"
echo "for a in *; do test -f \$a.mine && mv \$a.mine \$a; done"
echo "If you want to use the newly generated skeleton $PROGRAMMERNAME.c.mine , run"
echo "mv $PROGRAMMERNAME.c.mine $PROGRAMMERNAME.c"
echo
echo "WARNING: Please note that rerunning build_new_driver.sh will overwrite"
echo "all *.mine files, but it won't touch $PROGRAMMERNAME.c ."
echo "If something goes wrong, you can svn revert all files which look odd and"
echo "run this script again."
