-- common module initialization
cron.schedule("*/5 * * * *", function(e) dofile("nwfnet-sntp.lc").dosntp(nil) end)
nwfnet = require "nwfnet"

tq = (dofile "tq.lc")(tmr.create())

-- Hardware initialization
i2c.setup(0,2,1,i2c.SLOW)  -- init i2c as per silk screen (GPIO4, GPIO5)
lcd = dofile("lcd1602.lc")(0x27)

-- Game logic modules
ctfws = dofile("ctfws.lc")()
ctfws:setFlags(0,0)

msg_tmr = tmr.create()
ctfws_lcd = dofile("ctfws-lcd.lc")(ctfws, lcd, tq, msg_tmr)
ctfws_tmr = tmr.create()

-- Draw the default display
ctfws_lcd:drawTimes()
ctfws_lcd:drawFlagsMessage("BOOT...")

-- MQTT plumbing

mqc, mqttUser = dofile("nwfmqtt.lc").mkclient("nwfmqtt.conf")
local mqttBootTopic  = string.format("ctfws/dev/%s/beat",mqttUser)
mqc:lwt(mqttBootTopic,"dead",1,1)

-- This is not, properly speaking, OK, but it's so convenient
ctfws_lcd:drawMessage(string.format("I am: %s", mqttUser))

local myBSSID = "00:00:00:00:00:00"

local mqtt_reconn_cronentry
local function mqtt_reconn()
  mqtt_reconn_cronentry = cron.schedule("* * * * *", function(e)
    mqc:close(); dofile("nwfmqtt.lc").connect(mqc,"nwfmqtt.conf")
  end)
  dofile("nwfmqtt.lc").connect(mqc,"nwfmqtt.conf")
end

local mqtt_beat_cronentry
local function mqtt_beat()
  mqtt_beat_cronentry = cron.schedule("*/5 * * * *", function(e) 
    mqc:publish(mqttBootTopic,string.format("beat %d %s",rtctime.get(),myBSSID),1,1)
  end)
end

local function ctfws_lcd_draw_all()
    ctfws_lcd:reset()
    ctfws_lcd:drawFlags()
    ctfws_lcd:drawTimes()
end

local function ctfws_start_tmr()
  ctfws_tmr:alarm(100,tmr.ALARM_AUTO,function()
    if not ctfws_lcd:drawTimes() then ctfws_tmr:unregister() end
  end)
end

nwfnet.onmqtt["init"] = function(c,t,m)
  if t == "ctfws/game/config" then
    ctfws_tmr:unregister()
    if not m or m == "none"
     then ctfws:deconfig()
     else local st, sd, nr, rd, nf = m:match("^%s*(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+).*$")
          if st == nil
           then ctfws:deconfig()
           else -- the game's afoot!
                ctfws:config(tonumber(st), tonumber(sd), tonumber(nr),
                             tonumber(rd), tonumber(nf))
                ctfws_start_tmr()
          end
    end
    ctfws_lcd_draw_all()
  elseif t == "ctfws/game/endtime" then
    ctfws:setEndTime(tonumber(m))
    ctfws_lcd_draw_all()
    ctfws_start_tmr() -- might have been unset; restart display if so
  elseif t == "ctfws/game/flags" then
   if not m then ctfws:setFlags(0,0); return end
   local fr, fy = m:match("^%s*(%d+)%s+(%d+).*$")
   if fr ~= nil then
     ctfws:setFlags(tonumber(fr),tonumber(fy))
     ctfws_lcd:drawFlags()
   end
  elseif t:match("^ctfws/game/message") then
    ctfws_lcd:drawMessage(m)
  end
end
nwfnet.onnet["init"] = function(e,c)
  if     e == "mqttdscn" and c == mqc then
    if mqtt_beat_cronentry then mqtt_beat_cronentry:unschedule() mqtt_beat_cronentry = nil end
    if not mqtt_reconn_cronentry then mqtt_reconn() end
    ctfws_lcd:drawFlagsMessage("MQTT Disconnected")
  elseif e == "mqttconn" and c == mqc then
    if mqtt_reconn_cronentry then mqtt_reconn_cronentry:unschedule() mqtt_reconn_cronentry = nil end
    if not mqtt_beat_cronentry then mqtt_beat() end
    mqc:publish(mqttBootTopic,"alive",1,1)
    mqc:subscribe("ctfws/game/config",1)
    mqc:subscribe("ctfws/game/endtime",1)
    mqc:subscribe("ctfws/game/flags",1)
    mqc:subscribe("ctfws/game/message",1)      -- broadcast messages
    mqc:subscribe("ctfws/game/message/jail",1) -- jail-specific messages
    ctfws_lcd:drawFlagsMessage("MQTT CONNECTED")
  elseif e == "wstagoip"              then
    if not mqtt_reconn_cronentry then mqtt_reconn() end
    ctfws_lcd:drawFlagsMessage(string.format("DHCP %s",c.IP))
  elseif e == "wstaconn"              then
    myBSSID = c.BSSID
    ctfws_lcd:drawFlagsMessage(string.format("WIFI %s",c.SSID))
  elseif e == "sntpsync"              then
    -- If we have a game configuration and just got SNTP sync, it might
    -- be that we just lept far into the future, so go ahead and start
    -- the game!
    if ctfws.startT then ctfws_start_tmr() end
  end
end

ctfws_lcd:drawFlagsMessage("CONNECTING...")
dofile("nwfnet-diag.lc")(true)
dofile("nwfnet-go.lc")
