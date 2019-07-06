-- logging for debugging
-- local dprint = function(...) end -- OFF
local dprint = function(...) print(...) end -- ON

-- common module initialization
cron.schedule("*/5 * * * *", function(e) OVL["nwfnet-sntp"]().dosntp(nil) end)
local nwfnet = require "nwfnet"

-- MQTT plumbing
local mqttLocnTopic  = string.format("ctfws/devc/%s/location",mqttUser)
local mqttBootTopic  = string.format("ctfws/dev/%s/beat",mqttUser)
mqc:lwt(mqttBootTopic,"dead",1,1)

local myBSSID = "00:00:00:00:00:00"

local mqtt_reconn_cronentry
local function mqtt_reconn()
  dprint("main", "Trying reconn...")
  mqtt_reconn_cronentry = cron.schedule("* * * * *", function(e)
    mqc:close(); OVL.nwfmqtt().connect(mqc,"nwfmqtt.conf")
  end)
  OVL.nwfmqtt().connect(mqc,"nwfmqtt.conf")
end

local mqtt_beat_tmr = tmr.create()
mqtt_beat_tmr:register(20000, tmr.ALARM_AUTO, function(t)
    mqc:publish(mqttBootTopic,string.format("beat %d %s",rtctime.get(),myBSSID),1,1)
  end)

nwfnet.onmqtt["main"] = function(c,t,m)
  dprint("main", "MQTT", t, m)
  if t == "ctfws/game/config" then
    if not m or m == "none"
     then ctfws:deconfig()
     else local st,     -- start time
	        sd,     -- setup duration
		nr,     -- number of rounds
		rd,     -- round duration
		nf,     -- number of flags
		gn,     -- game number
		tc      -- territory configuration string
	                --   st      sd      nr      rd      nf      gn      tc
	     = m:match("^%s*(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%S+).*$")
          if st == nil
           then ctfws:deconfig()
           else -- the game's afoot!
                ctfws:config(tonumber(st), tonumber(sd), tonumber(nr),
                             tonumber(rd), tonumber(nf), tonumber(gn), tc)
          end
    end
  elseif t == "ctfws/game/endtime" then
    ctfws:setEndTime(tonumber(m))
  elseif t == "ctfws/game/flags" then
   if not m or m == "" then
     ctfws:setFlags("?","?")
     return
   end
   local ts, fr, fy = m:match("^%s*(%d+)%s+(-?%d+)%s+(-?%d+).*$")
   if ts ~= nil then
     ctfws:setFlags(tonumber(fr),tonumber(fy))
     return
   end
   -- we used to match on the ? explicitly, as in:
   --   if m:match("^%s*(%d+)%s+%?.*$") then ... end
   -- but for now, let's just take any ill-formed message
   ctfws:setFlags("?","?")
  elseif t == mqttLocnTopic then
   ctfws:setTerritory(m)
  end
end

-- network callbacks

nwfnet.onnet["main"] = function(e,c)
  dprint("main", "NET", e)
  if     e == "mqttdscn" and c == mqc then
    mqtt_beat_tmr:stop()
    if not mqtt_reconn_cronentry then mqtt_reconn() end
  elseif e == "mqttconn" and c == mqc then
    if mqtt_reconn_cronentry then mqtt_reconn_cronentry:unschedule() mqtt_reconn_cronentry = nil end
    mqtt_beat_tmr:start()
    mqc:publish(mqttBootTopic,"alive",1,1)
    mqc:subscribe({
      ["ctfws/game/config"] = 2,
      ["ctfws/game/endtime"] = 2,
      ["ctfws/game/flags"] = 2,
      [mqttLocnTopic] = 2,             -- my location
    })
  elseif e == "wstagoip"              then
    if not mqtt_reconn_cronentry then mqtt_reconn() end
  elseif e == "wstaconn"              then
    myBSSID = c.BSSID
  elseif e == "sntpsync"              then
    -- If we have a game configuration and just got SNTP sync, it might
    -- be that we just lept far into the future, so go ahead and start
    -- the game!
    if ctfws.startT then ctfws:reconfig() end
  end
end

-- OVL["nwfnet-diag"]()(true)
OVL["nwfnet-go"]()
