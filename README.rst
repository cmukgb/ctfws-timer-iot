########################################
Capture The Flag With Stuff Glyph Module
########################################

This is a hardware device designed to assist the `CMU KGB
<http://www.cmukgb.org/>`_ game of `Capture The Flag With Stuff
<http://www.cmukgb.org/activities/ctfws.php>`_.

Protocol
########

The protocol documentation has been moved to a more central location,
namely http://www.ietfng.org/nwf/ee/ctfws-iot.html

.. note::

   Due to a bug in nodemcu (https://github.com/nodemcu/nodemcu-firmware/issues/1773),
   do not send empty messages or messages with QoS 2; stick to QoS 1 and it
   appears to work.

 
Jail Glyph Timers
#################

At each jail glyph, we would install a device consisting of

* an ESP8266 module
* a beeper
* a LCD (probably a small I2C graphics display or 4x20 text or similar)
* a small lipo battery (and charging circuitry, likely)

This device is not intended to be interactive in any way; turn it on and let
it do its thing.

The device would join CMU's wireless network, perform SNTP to get an
accurate clock, and associate with a MQTT server managed by the KGB to
receive updates about the game for display, namely:

* game configuration (setup duration, N rounds M seconds long)
* game start time
* team scores / flag capture counts
* game over

It's likely beneficial (or at least, not harmful) for the devices to
heartbeat into their own MQTT topics as well, and may wish to announce which
AP they're associated with.

The device should otherwise function more or less as a glorified stopwatch
under centralized control.

NodeMCU modules used
====================

Please ensure that your build of NodeMCU supports LFS and the following modules:

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

* ``mDNS`` may be a good idea, too, if you want to talk to your device over,
  e.g. telnet, and want it to have a somewhat friendly name.

* ``rtcmem`` may be useful if you wish to stash a little bit of state
  frequently and don't want to write to flash.

* ``uart`` is in most default builds but is not necessary, if you need space.

This has only been tested with integer builds.

BOM
===

One possible instantiation, just as a baseline:

+---+-------------------------------------------------------------+-------+
| 1 | NodeMCU board (ESP8266+USB serial)                          |  4.00 |
+---+-------------------------------------------------------------+-------+
| 1 | 2.5Ah USB power stick                                       |  5.50 |
+---+-------------------------------------------------------------+-------+
| 1 | 4x20 LCD display                                            |  4.50 |
+---+-------------------------------------------------------------+-------+
| 1 | Buzzer                                                      |  0.20 |
+---+-------------------------------------------------------------+-------+
| 1 | Small breadboard                                            |  0.80 |
+---+-------------------------------------------------------------+-------+
|   | Jumper wire                                                 |  0.50 |
+---+-------------------------------------------------------------+-------+
|   | TOTAL                                                       | 15.50 |
+---+-------------------------------------------------------------+-------+

We have found it necessary, on occasion, to add a 100-ohm resistor between
power and ground to keep the USB power sticks from automagically turning
off due to low draw.  It's not great, but it works.

NodeMCU Pinout
==============

+------+--------------------------------------+
| GPIO | Purpose                              |
+------+--------------------------------------+
|    0 | FLASH (button)                       |
+------+--------------------------------------+
|    1 | Reserved for Lua console TX via USB  |
+------+--------------------------------------+
|    2 | Free for good use                    |
+------+--------------------------------------+
|    3 | Reserved for Lua console RX via USB  |
+------+--------------------------------------+
|    4 | I2C SDA for LCD-driving I/O expander |
+------+--------------------------------------+
|    5 | I2C SCL for LCD-driving I/O expander |
+------+--------------------------------------+
|    9 | Free for good use                    |
+------+--------------------------------------+
|   10 | Free for good use                    |
+------+--------------------------------------+
|   12 | free for good use                    |
+------+--------------------------------------+
|   13 | free for good use                    |
+------+--------------------------------------+
|   14 | beeper active-low                    |
+------+--------------------------------------+
|   15 | free for good use                    |
+------+--------------------------------------+
|   16 | ESP8266 WAKE; free for good use      |
+------+--------------------------------------+

* ADC0 is also free at the moment.


Character Display
=================

Setup time display::

    0         1         
    01234567890123456789
    SETUP    :   MM:SS.s
       NN⚑: R=0 Y=0
    messagemessagemessag
    START IN :   MM:SS.s

Steady state display::

    0         1         
    01234567890123456789
    JB#   n/N :  MM:SS.s
       NN⚑: R=NN Y=NN
    messagemessagemessag
    JAILBREAK :  MM:SS.s

Last round display::

    0         1         
    01234567890123456789
    GAME      :  MM:SS.s
       NN⚑: R=NN Y=NN
    messagemessagemessag
    GAME END  :  MM:SS.s

Game over::

    0         1         
    01234567890123456789
     CMUKGB CTFWS TIMER
       NN⚑: R=NN Y=NN
    messagemessagemessag
     GAME OVER @ MM:SS

Game not configured::

    0         1         
    01234567890123456789
     CMUKGB CTFWS TIMER
       
    messagemessagemessag
     GAME NOT CONFIGURED

Configuration Files
===================

* ``nwfnet.conf`` has details of how to get connectivity to the network.
* ``nwfnet.conf2`` sets the SNTP server to use
* ``nwfmqtt.conf`` sets the MQTT server and credentials


