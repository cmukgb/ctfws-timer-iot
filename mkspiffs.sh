#!/bin/bash

FWDIR=${FWDIR:-/home/nwf/ee/esp/nodemcu-firmware}
FWIMG=${FWIMG:-${FWDIR}/bin/nodemcu_integer_test.bin}
CONFNAME=${CONFNAME:-home}

FWSZ=$(stat --printf="%s" ${FWIMG})

LUACROSS=${FWDIR}/luac.cross ./mklfs.sh

(
	# Init is the only core Lua that does not live in LFS
	echo import core/init.lua init.lua

	# Grab our configuration
	for i in conf/${CONFNAME}/*; do echo import $i `basename $i`; done

	# And all our Lua files
	for i in *.lua; do echo import $i $i; done

	# And the LFS image with the rest of everything
	echo import _lfs_build/luac.out luac.out
) | ${FWDIR}/tools/spiffsimg/spiffsimg \
     -f spiffs-${CONFNAME}.img \
     -S 32m -U ${FWSZ} \
     -o /dev/fd/1 -r /dev/fd/0

echo
