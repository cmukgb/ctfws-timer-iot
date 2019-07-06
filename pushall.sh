#!/bin/zsh

set -e -u

. ./core/host/pushcommon.sh

pushsrc() {
  dopushlua     ctfws.lua
  dopushlua     ui-lcd-view.lua
  dopushlua     ui-lcd-ctrl.lua
  dopushlua     main.lua
  dopushcompile init2.lua
}

if [ -n "${2:-}" ]; then
  if [ -d conf/$2 ]; then CONFDIR=conf/$2
  elif [ -d $2 ]; then CONFDIR=$2
  else echo "Not a directory: $2"; exit 1
  fi
fi

pushconf() {
  if [ -z "${CONFDIR:-}" ]; then
    echo "Asked to push config without specifying?"
    exit 1
  fi
  for f in ${CONFDIR}/*; do
    dopushtext "$f"
  done
}

pushlfs() {
    if [ -z ${LUACROSS:-} ]; then
      ./core/host/pushinit.sh
    else
      ./mklfs.sh
      dopushtext _lfs_build/luac.out
    fi
}

case "${1:-}" in
  all)
    pushconf
    pushsrc
    pushlfs
    ;;
  both)
    pushconf
    pushsrc
    ;;
  src)
    pushsrc
    ;;
  srcmore)
    pushsrc
    pushlfs
    ;;
  conf)
    pushconf
    ;;
  *)
    echo "Please specify push mode: {conf,src,srcmore,both,all}"
    exit 1
    ;;
esac
