return function(nwfnet, ctfws, lcd, mqc)

  local msg_tmr = tmr.create()
  local flg_tmr = tmr.create()
  local fla_tmr = tmr.create()

  local ctfws_lcd = OVL["ui-lcd-view"]()(ctfws, lcd, msg_tmr, flg_tmr, fla_tmr)
  local ctfws_tmr = tmr.create()

  -- Draw the default display
  ctfws_lcd:drawTimes()
  ctfws_lcd:drawFlagsMessage("BOOT...")

  -- This is not, properly speaking, OK, but it's so convenient
  local boot_message_hack = 1
  ctfws_lcd.attnState = 1 -- hackishly suppress attention() call
  ctfws_lcd:drawMessage(string.format("I am: %s", mqttUser))
  ctfws_lcd.attnState = nil

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

  -- ctfws callbacks
  ctfws.cbs[ctfws_lcd] = function(e,gs)
    print("UI", "CTFWS", e)
    if     e == "config"    then
      ctfws_start_tmr()
      ctfws_lcd_draw_all()
    elseif e == "reconfig"  then
      -- The game state has not changed, but the world (e.g., clock) might have
      ctfws_start_tmr()
    elseif e == "deconfig"  then
      ctfws_tmr:unregister()
      ctfws_lcd_draw_all()
    elseif e == "flags"     then
      ctfws_lcd:drawFlags()
    elseif e == "endtime"   then
      -- might have been unset; restart display if so
      ctfws_lcd_draw_all()
      ctfws_start_tmr()
    elseif e == "territory" then
      ctfws_lcd:drawFlags()
    end
  end

  -- non-core game callbacks hook MQTT directly

  nwfnet.onmqtt[ctfws_lcd] = function(c,t,m)
    print("UI", "MQTT", t, m)
    if t:match("^ctfws/game/message") then
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

  nwfnet.onnet[ctfws_lcd] = function(e,c)
    print("UI", "NET", e)
    if     e == "mqttdscn" and c == mqc then
      ctfws_lcd:drawFlagsMessage("MQTT Disconnected")
      ctfws_lcd.connected = false
      ctfws_lcd.dl_elapsed = nil -- force full redraw
    elseif e == "mqttconn" and c == mqc then
      ctfws_lcd:drawFlagsMessage("MQTT CONNECTED")
      mqc:subscribe({
        ["ctfws/game/message"] = 2,      -- broadcast messages
        ["ctfws/game/message/jail"] = 2, -- jail-specific messages (XXX role!)
      })
      ctfws_lcd.connected = true
      ctfws_lcd.dl_elapsed = nil -- force full redraw
    elseif e == "wstagoip"              then
      ctfws_lcd:drawFlagsMessage(string.format("DHCP %s",c.IP))
    elseif e == "wstaconn"              then
      ctfws_lcd:drawFlagsMessage(string.format("WIFI %s",c.SSID))
    end
  end

  return ctfws_lcd
end
