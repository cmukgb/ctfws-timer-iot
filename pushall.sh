#!/bin/zsh

set -e -u

. ./host/pushcommon.sh

#dopushcompile net/nwfmqtt.lua
#dopush        examples/ctfws/conf/nwfnet.conf
dopush        examples/ctfws/conf/nwfnet.conf2
dopush        examples/ctfws/conf/nwfmqtt.conf
#dopushcompile _external/dvv-nodemcu-thingies/lcd1602.lua
dopushcompile examples/ctfws/ctfws.lua
dopushcompile examples/ctfws/ctfws-lcd.lua
dopushcompile examples/ctfws/init2.lua

echo "SUCCESS"
