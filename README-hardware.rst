Jail Glyph Timers
#################

At each jail glyph, we install a device consisting of

* an ESP8266 module
* a beeper
* a 4x20 text LCD
* a small lipo battery

This device is not intended to be interactive in any way; turn it on and let
it do its thing.

The device joins CMU's wireless network, performs SNTP to get an
accurate clock, and connects to a MQTT server managed by the KGB to
receive updates about the game for display, namely:

* game configuration (setup duration, N rounds M seconds long)
* game start time
* team scores / flag capture counts
* game over

The devices heartbeat into their own MQTT topics as well, so judges can know
they are still running and, as a test, include in the heartbeat message which
AP they're associated with.

BOM
===

The first instantiation, just as a baseline:

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
|   | Jumper wire, double-stick tape, twist-ties                  |  0.50 |
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

* I2C is, of course, a multi-tap (and multi-master...) bus.
