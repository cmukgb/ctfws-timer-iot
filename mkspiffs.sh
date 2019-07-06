#!/bin/bash

FWIMG=${FWIMG:-firm/bin/nodemcu_integer_test.bin}
BOARDNAME=${BOARDNAME:-home}

[ -r firm ] || {
	echo "./firm should be a symlink to a built firmware repo"
	exit 1
}

[ -r ${FWIMG} ] || {
	echo "No firmware image ${FWIMG}"
	exit 1
}

FWSZ=$(stat --printf="%s" ${FWIMG})

# Now made external
# LUACROSS=$(readlink -f ./firm/luac.cross) ./mklfs.sh

(
	# Init is the only core Lua that does not live in LFS
	echo import core/init.lua init.lua

	# Grab our configuration
	if [ -r conf/${BOARDNAME}/rewrites.sed ]; then
		for i in conf/_common/*.conf.in; do
			sed -f conf/${BOARDNAME}/rewrites.sed < $i \
				> `dirname $i`/`basename $i .in`
		done
	elif [ ! -r conf/${BOARDNAME}/nwfmqtt.conf ]; then
		echo 'NO MQTT CONFIGURATION KNOWN; THIS IS UNLIKELY TO WORK!'
	fi
	for i in conf/${BOARDNAME}/*.conf; do echo import $i `basename $i`; done
	[ -r conf/${BOARDNAME}/nwfnet.cert ] && echo import conf/${BOARDNAME}/nwfnet.cert nwfnet.cert

	# And all our Lua files
	for i in *.lua; do echo import $i $i; done

	# And the LFS image with the rest of everything
	#  We could, and used to, but we now go via the nodemcu partition tool
	# echo import _lfs_build/luac.out luac.out
) | ./firm/tools/spiffsimg/spiffsimg \
     -f spiffs-${BOARDNAME}.img \
     -c 262144 \
     -r /dev/fd/0
