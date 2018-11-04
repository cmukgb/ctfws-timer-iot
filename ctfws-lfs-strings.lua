local modload = "cron", "cron.entry", "schedule", "unschedule",
  "gpio", "HIGH", "LOW", "ALARM_AUTO",
  "mqtt.socket",
  "math", "floor", "unregister",
  "error", "self"

local ctfws = "ctfws", "ctfws_lcd", "ctfws_tmr",
  "setupD", "roundD", "rounds", "startT", "endT", "flagsN", "flagsR", "flagsY",
  "times", "config", "deconfig", "setFlags", "setEndTime",
  "GAME NOT CONFIGURED!",
  "GAME OVER @ %02d:%02d",
  "START TIME IN FUTURE",
  "TIME IS UP",
  "CTFWS"

local lcdpreload =
  "define_char",
  "lcd", "mtmr", "ftmr", "dl_elapsed", "dl_elapsed", "dl_remain", "dl_round",
  "attnState", "reset", "drawTimes", "drawFlags", "drawMessage", "drawFlagsMessage",
  "%02d:%02d.%d", "%02d.%d", "%d", "%-20s", "%d\000: R=%s Y=%s",
  " CMUKGB CTFWS TIMER ", "                    ",
  "GAME      :",
  "SETUP     :",
  "START IN  :",
  "GAME END  :",
  "JAILBREAK :",
  "JB#   %d/%d :",
  "JB# %2d/%2d :"

local init3load =
  "flg_tmr", "lastMsgTime", "mqttUser", "msg_tmr", "dprint", "mqc",
  "nwfmqtt.conf",
  "* * * * *",
  "ctfws/game/config",
  "ctfws/game/endtime",
  "ctfws/game/flags",
  "ctfws/game/message",
  "ctfws/game/message/jail",
  "none",
  "^%s*(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+).*$",
  "^%s*(%d+)%s+(-?%d+)%s+(-?%d+).*$",
  "^%s*(%d+)%s*(.*)$",
  "^%s*%?.*$",
  "^ctfws/game/message",
  "CONNECTING...", "MQTT", "MQTT CONNECTED", "MQTT Disconnected", "DHCP %s",
  "WIFI %s", "NET", "Trying reconn...",
  "alive", "beat %d %s"
