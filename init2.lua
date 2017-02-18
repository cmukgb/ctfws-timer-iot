-- It's early in boot, so we have plenty of RAM.  Compile
-- the rest of the firmware from source if it's there.
local k,v
for k,v in pairs(file.list()) do
  local ix, _ = k:find("^.*%.lua$")
  if ix and k ~= "init.lua" then
    print("early compile",k)
    node.compile(k); file.remove(k)
  end
end

-- Grab some configuration parameters we might need,
-- notably, the LCD address
local ctfwshw = {}
if file.open("ctfws-misc.conf","r") then
  local conf = cjson.decode(file.read() or "")
  if type(conf) == "table"
   then ctfwshw = conf
   else print("ctfws-misc.conf malformed")
  end
end

-- Hardware initialization
print("init2 hw")
gpio.mode(5,gpio.OUTPUT)   -- beeper on GPIO14
i2c.setup(0,2,1,i2c.SLOW)  -- init i2c on GPIO4 and GPIO5
lcd = dofile("lcd1602.lc")(ctfwshw.lcd or 0x27)

tq = (dofile "tq.lc")(tmr.create())

-- give the LCD time to initialize properly
tq:queue(125, function() print("init2 go3") dofile("init3.lc") end)
