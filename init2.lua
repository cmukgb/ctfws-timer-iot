if node.flashindex() == nil then
  -- no LFS image.  Perhaps it failed to flash?
  if file.exists("luac.out.stage") and not file.exists("luac.out") then
    -- Looks like we tried once before, indeed.  Try again.
    node.flashreload("luac.out.stage")
  end
end
file.remove("luac.out.stage") -- remove stage file from last attempt
-- Do we have a new LFS blob?  If so, install it.
if file.exists("luac.out") then
  print("INIT2","Updating LFS image.  Will reboot if things go well.")
  file.rename("luac.out", "luac.out.stage")
  node.flashreload("luac.out.stage")
  error("INIT2", "Failed to update LFS!")
end

-- It's early in boot, so we have plenty of RAM.  Compile
-- the rest of the firmware from source if it's there.
OVL.compileall()

-- Grab some configuration parameters we might need,
-- notably, the LCD address
local ctfwshw = {}
if file.open("ctfws-misc.conf","r") then
  local conf = sjson.decode(file.read() or "")
  if type(conf) == "table"
   then ctfwshw = conf
   else print("INIT2", "ctfws-misc.conf malformed")
  end
end

-- While we're getting configuration, go ahead and build our MQTT client
-- and set the global holding our name
mqc, mqttUser = OVL.nwfmqtt().mkclient("nwfmqtt.conf")
if mqc == nil then
  print("INIT2", "You forgot your MQTT configuration file")
end

-- Game logic modules
ctfws = OVL.ctfws()
ctfws:setFlags(0,0)

-- Hardware initialization
print("INIT2", "hw")
wifi.sta.sleeptype(wifi.NONE_SLEEP) -- don't power down radio
gpio.mode(5,gpio.OUTPUT)   -- beeper on GPIO14
i2c.setup(0,2,1,i2c.SLOW)  -- init i2c on GPIO4 and GPIO5

if ctfwshw.lcd then
  print("LCD ADDR", ctfwshw.lcd)
  lcd = OVL.lcd1602()(ctfwshw.lcd)
  ctfws_lcd = OVL["ui-lcd-ctrl"]()(require "nwfnet", ctfws, lcd, mqc)
end

-- give the LCD time to initialize properly
tmr.create():alarm(125, tmr.ALARM_SINGLE, function() print("INIT2", "main") OVL.main() end)
