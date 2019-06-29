Prepare the Firmware
####################

Not yet really documented; build a NodeMCU firmware with the modules listed
below.  Ensure that ``./firm`` points to your firmware build directory, as
we're going to pull ``luac.cross`` and the firmware ``.bin`` therefrom.

You'll want to run the following to build the CtFwS-specific LFS image for
NodeMCU::

  LUACROSS=$(readlink -f ./firm/luac.cross.int) ./mklfs.sh

NodeMCU modules used
====================

Please ensure that your build of NodeMCU supports LFS and the following
modules:

* ``bit`` (for LCD)
* ``cron``
* ``file``
* ``i2c`` (for LCD)
* ``mqtt``
* ``net``
* ``node``
* ``rtctime``
* ``sjson``
* ``sntp``
* ``tmr``
* ``wifi``

Additionally,

* If you are developing on this software, the ``mDNS`` module may be a good
  idea, too; the emergency telnet server can be reached with a more friendly
  name.

* This has only been tested with integer builds.

Configuration Files
###################

* ``nwfnet.conf`` has details of how to get connectivity to the network.
* ``nwfnet.conf2`` sets the SNTP server to use
* ``nwfmqtt.conf`` sets the MQTT server and credentials; it is derived from
  ``nwfmqtt.conf.in`` via ``rewrites.sed`` in the configuration directories;
  note that the latter of which is deliberately not checked in.
* ``ctfws-misc.conf`` can be used to assign the LCD I2C address

Flashing
########

Clone this: https://github.com/espressif/esptool

For each of the three timers (clear, yellow, and red), hook them to USB and run
one of ::

    export BOARDNAME=red
    export BOARDNAME=yel
    export BOARDNAME=clr

and then ::

    ./mkspiffs.sh

    ./esptool/esptool.py write_flash \
     --flash_size 4MB --flash_mode dio --verify \
     0x0      ./firm/bin/nodemcu_integer_test.bin \
     0x3fc000 ./firm/sdk/esp_iot_sdk_v3.0/bin/esp_init_data_default_v05.bin

    ./firm/tools/nodemcu-partition.py \
     --flash_size 4MB \
     --lfs_size 65536 --lfs_file _lfs_build/luac.out \
     --spiffs_size 262144 --spiffs_file spiffs-${BOARDNAME}.img

After flashing, the device will reboot, apply some internal changes, and reboot
again.  By default, it hangs out for a minute after the second reboot before
rebooting again into the CtFwS logic.  This is less than ideal but is (at least
partly) due to an upstream issue; for the less patient, after flashing, count
15, and then hit the RST button and the device should come up into its CtFwS
logic.

Serial Console
##############

You may want to get a serial console on the device for a little more visibility
into what's going on.  While nwf prefers the use of kermit for this, one can
also just use screen, as in ::

    screen /dev/ttyUSB0 115200

Disconnect with the screen attention chord, ``ctrl+a``, followed by the command
``:quit``.

At the Lua prompt, many things are possible.  By default, the device provides
some visibility into internal events by emitting log messages like so::

    NET	wstaconn
    NET	wstagoip
    CTFWS	Trying reconn...
    NET	sntpsync
    NET	mqttconn
    MQTT	ctfws/game/endtime	1540688900

The function ``OVL.diag()`` will provide a summary of much of the device's
internal state.

