-- logging for debugging
-- dprint = function(...) end -- OFF
dprint = function(...) print(...) end -- ON

-- common module initialization
cron.schedule("*/5 * * * *", function(e) dofile("nwfnet-sntp.lc").dosntp(nil) end)
nwfnet = require "nwfnet"

-- Game logic modules
ctfws = dofile("ctfws.lc")()
ctfws:setFlags(0,0)

msg_tmr = tmr.create()
flg_tmr = tmr.create()
ctfws_lcd = dofile("ctfws-lcd.lc")(ctfws, lcd, msg_tmr, flg_tmr)
ctfws_tmr = tmr.create()

-- Draw the default display
ctfws_lcd:drawTimes()
ctfws_lcd:drawFlagsMessage("BOOT...")

-- MQTT plumbing
mqc, mqttUser = dofile("nwfmqtt.lc").mkclient("nwfmqtt.conf")
local mqttBootTopic  = string.format("ctfws/dev/%s/beat",mqttUser)
mqc:lwt(mqttBootTopic,"dead",1,1)

-- This is not, properly speaking, OK, but it's so convenient
local boot_message_hack = 1
ctfws_lcd.attnState = 1 -- hackishly suppress attention() call
ctfws_lcd:drawMessage(string.format("I am: %s", mqttUser))
ctfws_lcd.attnState = nil

local myBSSID = "00:00:00:00:00:00"

local mqtt_reconn_cronentry
local function mqtt_reconn()
  dprint("Trying reconn...")
  mqtt_reconn_cronentry = cron.schedule("* * * * *", function(e)
    mqc:close(); dofile("nwfmqtt.lc").connect(mqc,"nwfmqtt.conf")
  end)
  dofile("nwfmqtt.lc").connect(mqc,"nwfmqtt.conf")
end

local mqtt_beat_cronentry
local function mqtt_beat()
  mqtt_beat_cronentry = cron.schedule("* * * * *", function(e)
    mqc:publish(mqttBootTopic,string.format("beat %d %s",rtctime.get(),myBSSID),1,1)
  end)
end

local function ctfws_lcd_draw_all()
    ctfws_lcd:reset()
    ctfws_lcd:drawFlags()
    ctfws_lcd:drawTimes()

    -- clear the message display if it hasn't been already after boot
    if boot_message_hack then
      ctfws_lcd:drawMessage("")
      boot_message_hack = nil
    end
end

local ctfws_start_tmr
local function ctfws_tmr_cb()
  -- draw the display, and if it tells us that the game is not in progress,
  -- wait a little longer before trying again, but don't unregister (like we
  -- used to).  This means we'll paint error messages periodically, but
  -- won't hammer the i2c bus with too many unnecessary updates.  It also
  -- means that a little NTP drift is OK.
  if not ctfws_lcd:drawTimes() then
    ctfws_tmr:alarm(3000,tmr.ALARM_AUTO,ctfws_start_tmr)
  end
end
function ctfws_start_tmr()
  ctfws_tmr:alarm(100,tmr.ALARM_AUTO,ctfws_tmr_cb)
end

nwfnet.onmqtt["init"] = function(c,t,m)
  dprint("MQTT", t, m)
  if t == "ctfws/game/config" then
    ctfws_tmr:unregister()
    if not m or m == "none"
     then ctfws:deconfig()
          ctfws_lcd_draw_all()
     else local st, sd, nr, rd, nf = m:match("^%s*(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+).*$")
          if st == nil
           then ctfws:deconfig()
           else -- the game's afoot!
                ctfws:config(tonumber(st), tonumber(sd), tonumber(nr),
                             tonumber(rd), tonumber(nf))
                ctfws_start_tmr()
          end
          ctfws_lcd_draw_all()
    end
  elseif t == "ctfws/game/endtime" then
    ctfws:setEndTime(tonumber(m))
    ctfws_lcd_draw_all()
    ctfws_start_tmr() -- might have been unset; restart display if so
  elseif t == "ctfws/game/flags" then
   if not m or m == "" then
     if ctfws:setFlags("?","?") then ctfws_lcd:drawFlags() end
     return
   end
   local fr, fy = m:match("^%s*(%d+)%s+(%d+).*$")
   if fr ~= nil then
     if ctfws:setFlags(tonumber(fr),tonumber(fy)) then ctfws_lcd:drawFlags() end
     return
   end
   if m:match("^%s*%?.*$") then
     if ctfws:setFlags("?","?") then ctfws_lcd:drawFlags() end
   end
  elseif t:match("^ctfws/game/message") then
    boot_message_hack = nil
    local mt, ms = m:match("^%s*(%d+)%s*(.*)$")
    if mt == nil then -- maybe they forgot a timestamp?
      lastMsgTime = rtctime.get() - 30 -- subtract some wiggle room
      ctfws_lcd:drawMessage(m)
    else
      mt = tonumber(mt)
      if (ctfws.startT == nil or ctfws.startT <= mt)  -- message for this game
         and (lastMsgTime == nil or lastMsgTime < mt) -- latest message (strict)
       then
        lastMsgTime = mt
        ctfws_lcd:drawMessage(ms)
      end
    end
  end
end

-- network callbacks

nwfnet.onnet["init"] = function(e,c)
  dprint("NET", e)
  if     e == "mqttdscn" and c == mqc then
    if mqtt_beat_cronentry then mqtt_beat_cronentry:unschedule() mqtt_beat_cronentry = nil end
    if not mqtt_reconn_cronentry then mqtt_reconn() end
    ctfws_lcd:drawFlagsMessage("MQTT Disconnected")
  elseif e == "mqttconn" and c == mqc then
    if mqtt_reconn_cronentry then mqtt_reconn_cronentry:unschedule() mqtt_reconn_cronentry = nil end
    if not mqtt_beat_cronentry then mqtt_beat() end
    mqc:publish(mqttBootTopic,"alive",1,1)
    mqc:subscribe({
      ["ctfws/game/config"] = 2,
      ["ctfws/game/endtime"] = 2,
      ["ctfws/game/flags"] = 2,
      ["ctfws/game/message"] = 2,      -- broadcast messages
      ["ctfws/game/message/jail"] = 2, -- jail-specific messages
    })
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

-- hook us up to the network!
ctfws_lcd:drawFlagsMessage("CONNECTING...")
-- dofile("nwfnet-diag.lc")(true)
dofile("nwfnet-go.lc")
