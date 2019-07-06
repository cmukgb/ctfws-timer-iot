#!/bin/bash

set -e -u

[ -d firm ] || {
	echo "./firm should be a symbolic link to the nodemcu firmware"
	exit 1
}

[ -d core ] || {
	echo "./core should be a checkout of nwf's core modules"
	exit 1
}

SOURCES=(
  *.lua
  core/_external/lcd1602.lua
  firm/lua_modules/fifo/fifo.lua
  firm/lua_modules/fifo/fifosock.lua
  core/net/{nwfmqtt,nwfnet*}.lua
  core/telnetd/telnetd{,-{diag,file}}.lua
  core/util/compileall.lua
  core/util/diag.lua
  core/util/lfs-strings.lua
)

rm -rf _lfs_build
mkdir _lfs_build

# for i in ${SOURCES[@]}; do
#   lua5.1 -e "package.path=package.path..';core/_external/luasrcdiet/?.lua'" \
#     core/_external/luasrcdiet/bin/luasrcdiet $i -o _lfs_build/`basename $i` --quiet
# done
cp ${SOURCES[@]} _lfs_build/

if [ -z "${LUACROSS:-}" ]; then
  LUACROSS=$(readlink -f $(dirname $0)/luac.cross)
fi

if ! [ -x "${LUACROSS}" ]; then
  echo "Need cross compiler!  Tried non-existant ${LUACROSS}."
  exit 1
fi

(cd _lfs_build; $LUACROSS -f *.lua)
# ls -l _lfs_build/luac.out
