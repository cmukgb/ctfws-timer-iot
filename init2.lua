-- It's early in boot, so we have plenty of RAM.  Compile
-- the rest of the firmware from source if it's there.
dofile("compileall.lc")

-- Grab some configuration parameters we might need,
-- notably, the LCD address
local ctfwshw = {}
if file.open("ctfws-misc.conf","r") then
  local conf = sjson.decode(file.read() or "")
  if type(conf) == "table"
   then ctfwshw = conf
   else print("ctfws-misc.conf malformed")
  end
end

-- Hardware initialization
print("init2 hw")
wifi.sta.sleeptype(wifi.NONE_SLEEP) -- don't power down radio
gpio.mode(5,gpio.OUTPUT)   -- beeper on GPIO14
i2c.setup(0,2,1,i2c.SLOW)  -- init i2c on GPIO4 and GPIO5
lcd = dofile("lcd1602.lc")(ctfwshw.lcd or 0x27)

-- give the LCD time to initialize properly
tmr.create():alarm(125, tmr.ALARM_SINGLE, function() print("init2 go3") dofile("init3.lc") end)
