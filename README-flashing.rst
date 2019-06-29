Prepare the Firmware
####################

Not yet really documented; build a NodeMCU firmware with the modules listed in
``README.rst``.  Ensure that ``./firm`` points to your firmware build directory,
as we're going to pull ``luac.cross`` and the firmware ``.bin`` therefrom.

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

