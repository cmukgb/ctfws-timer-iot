########################################
Capture The Flag With Stuff Glyph Module
########################################

This is a hardware device designed to assist the `CMU KGB
<http://www.cmukgb.org/>`_ game of `Capture The Flag With Stuff
<http://www.cmukgb.org/activities/ctfws.php>`_.

MQTT
####

Topic Tree
==========

All numbers herein are base-10 encoded and devoid of leading zeros for ease
of parsing.

Centrally-set topics:

* ``ctfws/game/config`` the string ``none`` or a whitespace-separated text field:
  * ``starttime`` -- NTP seconds indicating start state
  * ``setupduration`` -- setup duration, in seconds
  * ``rounds`` -- number of rounds
  * ``roundduration`` -- seconds per round
  * ``nflags`` -- number of flags per team
  * any additional fields are to be ignored.

* ``ctfws/game/flags`` -- whitespace-separated text field:
  * ``red`` -- red team flag capture count (int)
  * ``yel`` -- yellow team flag capture count (int)
  * any additional fields are to be ignored.

* ``ctfws/game/endtime`` -- a single number, denoting NTP seconds of a
  forced game end.  If this is larger than the last ``starttime`` gotten
  in a ``config`` message, then the game is considered over.

* ``ctfws/game/message`` -- Message to be displayed everywhere

* ``ctfws/game/message/player`` -- Message to be displayed specifically
  to players, if they ever come to have their own devices (e.g. apps)

* ``ctfws/game/message/jail`` -- Message to be displayed specifically at
  jail glyph units.  For the moment, that's all of them, but maybe we
  want to allow other things in the future.

Messages should be set persistent so that devices that reboot or lose their
connection will display the right thing upon reconnection.

.. todo:: Flag bitmaps?

   Do we want to publish a bitmap of captured flags or are we happy with
   counts?

Optionally, we may wish to grant read-only views of the above topics to a
guest account for a hypothetical CtFwS app.

Device-set topics:

* ``ctfws/dev/$DEVICENAME/beat``
  * one of ``alive``, ``beat``, or ``dead`` (LWT; no further fields)
  * ``time`` (UNIX time, from local clock)
  * ``ap`` (MAC addr)
  * any additional fields are to be ignored.

  The device should publish ``alive`` at gain of MQTT connectivity and
  having registered a last will and testament to set the message ``dead``.
  Thereafter, it should periodically publish to ``beat`` messages.

ACL Configuration
=================

For example::

  # global read permissions
  pattern read ctfws/#

  # master write to all ctfws parameters
  user ctfwsmaster
  pattern write ctfws/game/#

  # Per-device permissions to post to their own sub-trees.
  user ctfwsdev1
  pattern write ctfws/dev/%u/#

Example Command Line Usage
==========================

To watch what's going on in the world::

  mosquitto_sub -h $MQTT_SERVER -u ctfwsmaster -P asdf -q 1 -t ctfws/\# -v

To send MQTT messages, try variants of these.  Note that in all cases, we
set messages persistent so that devices that (re)connect mid-way into a game
get the latest messages automatically.

  * To start a game::

    mosquitto_pub -h $MQTT_SERVER -u ctfwsmaster -P asdf -q 1 -t ctfws/game/flags -r -m '0 0'
    mosquitto_pub -h $MQTT_SERVER -u ctfwsmaster -P asdf -q 1 -t ctfws/game/config -r -m `date +%s`' 900 3 900 10'

  * To post information::

    mosquitto_pub -h $MQTT_SERVER -u ctfwsmaster -P asdf -q 1 -t ctfws/game/flags -r -m '1 2'
    mosquitto_pub -h $MQTT_SERVER -u ctfwsmaster -P asdf -q 1 -t ctfws/game/message -r -m 'Red team captured a flag!'

  * To end a game::

    mosquitto_pub -h $MQTT_SERVER -u ctfwsmaster -P asdf -q 1 -t ctfws/game/endtime -r -m `date +%s` 

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

BOM
===

One possible instantiation, just as a baseline:

+---+-------------------------------------------------------------+-------+
| 1 | NodeMCU board (ESP8266+USB serial)                          |  3.00 |
+---+-------------------------------------------------------------+-------+
| 1 | 2.5Ah USB power stick                                       |  6.00 |
+---+-------------------------------------------------------------+-------+
| 1 | 4x20 LCD display                                            |  7.00 |
+---+-------------------------------------------------------------+-------+
| 1 | Buzzer                                                      |  1.00 |
+---+-------------------------------------------------------------+-------+
| 1 | Small breadboard                                            |  1.00 |
+---+-------------------------------------------------------------+-------+
|   | Jumper wire                                                 |  1.00 |
+---+-------------------------------------------------------------+-------+
|   | TOTAL                                                       | 19.00 |
+---+-------------------------------------------------------------+-------+

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
    ROUND r/R :  MM:SS.s
    NN⚑: R=NN Y=NN
    messagemessagemessag
    JAILBREAK :  MM:SS.s

Last round display::

    0         1         
    01234567890123456789
    ROUND r/R :  MM:SS.s
       NN⚑: R=NN Y=NN
    messagemessagemessag
    GAME END  :  MM:SS.s

Game over::

    0         1         
    01234567890123456789
         GAME OVER
       NN⚑: R=NN Y=NN
    messagemessagemessag
         GAME OVER

Game not configured::

    0         1         
    01234567890123456789
     GAME NOT CONFIGURED
       
    messagemessagemessag
     GAME NOT CONFIGURED

Configuration Files
===================

* ``nwfnet.conf`` has details of how to get connectivity to the network.
* ``nwfnet.conf2`` sets the SNTP server to use
* ``nwfmqtt.conf`` sets the MQTT server and credentials
