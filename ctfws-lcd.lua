-- fields:
--   dl_* fields are "drawn last", used to avoid writing things that are
--   already correct on screen.  They can be set to nil to force refresh.
--   Certain things (flags, messages) are considered rare enough that we
--   don't cache like this.
--
--     dl_round
--     dl_elapsed
--     dl_remain

local function drawDScond(max, last, decisec, thresh)
  return (max >= thresh) and ((last == nil) or math.floor(last / thresh) ~= math.floor(decisec / thresh))
end

-- Save I2C bandwidth by only drawing what we have to, to some approximation
local function drawDS(lcd, row, col, max, last, decisec)
  -- If we wanted to support hour-long times, we might do something like
  -- this.  As we don't, at the moment...
  -- if drawDScond(max, last, decisec, 36000) then -- hours and all the way down
  --   lcd:put(lcd:locate(row,col), string.format("%02d:%02d:%02d.%d",
  --     decisec/3600, decisec/600, (decisec/10)%60, decisec%10))
  -- else
  if drawDScond(max, last, decisec, 600) then -- minutes, seconds, and deci
     lcd:put(lcd:locate(row,col), string.format("%02d:%02d.%d", decisec/600, (decisec/10)%60, decisec%10))
  elseif drawDScond(max, last, decisec, 10) then -- seconds and deci
     lcd:put(lcd:locate(row,col+3), string.format("%02d.%d", (decisec/10)%60, decisec%10))
  else -- just deci
     lcd:put(lcd:locate(row,col+6), string.format("%d",decisec%10))
  end
end

local function drawNoGame(lcd, msg)
  local k,r; for k,r in pairs({0,3}) do
    lcd:put(lcd:locate(r,0), "                    ")
    lcd:put(lcd:locate(r,(20-#msg)/2), msg)
  end
end

local function drawSteadyTopLine(self,rix,maxt,ela)
  local lcd = self.lcd
  local ctfws = self.ctfws
  if self.dl_elapsed == nil then
    lcd:put(lcd:locate(0,0), "                    ")
    if rix == 0 then
      lcd:put(lcd:locate(0,0), "SETUP    :")
    else
      if ctfws.rounds >= 10
       then lcd:put(lcd:locate(0,0), string.format("RND %2d/%2d :",rix,ctfws.rounds))
       else lcd:put(lcd:locate(0,0), string.format("ROUND %d/%d :",rix,ctfws.rounds))
      end
    end
  end
  drawDS(lcd,0,13,maxt,self.dl_elapsed,ela); self.dl_elapsed = ela
end

local function drawSteadyBotLine(self,rix,maxt,rem)
  local lcd = self.lcd
  if self.dl_remain == nil then
    lcd:put(lcd:locate(3,0), "                    ")
    if rix == 0 then
      lcd:put(lcd:locate(3,0), "START IN :")
    elseif rix < ctfws.rounds then
      lcd:put(lcd:locate(3,0), "JAILBREAK :")
    else
      lcd:put(lcd:locate(3,0), "GAME END  :")
    end
  end
  drawDS(lcd,3,13,maxt,self.dl_remain ,rem); self.dl_remain  = rem
end

local function attention(self,long)
  if self.attnState then return end

  local tq = self.tq
  local lcd = self.lcd

  local function doBlink()
    if self.attnState <= 0 then
      self.attnState = nil
      gpio.write(5,gpio.HIGH) -- silence beeper always
      return
    end
    self.attnState = self.attnState - 1
    -- blink
    lcd:light(false)
    tq:queue(250, function() lcd:light(true); tq:queue(500, doBlink) end)
    -- chirp or scream
    gpio.write(5,gpio.LOW)
    if not long then tq:queue(100, function() gpio.write(5,gpio.HIGH) end) end
  end

  self.attnState = 2
  tq:queue(250, doBlink)
end

-- returns true if timers should keep going or false if we should wait for
-- the next message or event
local function drawTimes(self)
  local ctfws = self.ctfws
  local rix, maxt, ela = ctfws:times(rtctime.get)
  if rix == nil then
    drawNoGame(self.lcd, maxt)
    if rix ~= self.dl_round then
      self.dl_round = rix
      attention(self,true)
    end
    return false
  end
  if rix ~= self.dl_round then
    if self.dl_round ~= nil then attention(self,true) end
    self.dl_round = rix
    self.dl_elapsed = nil -- force redraws of times on round boundaries
    self.dl_remain  = nil
  end
  drawSteadyTopLine(self,rix,maxt,ela)
  drawSteadyBotLine(self,rix,maxt,maxt-ela)
  return true
end

local function drawFlags(self)
  local lcd = self.lcd
  local ctfws = self.ctfws
  if ctfws.flagsN then -- try not to blank a flagsmessage unless we have reason
    lcd:put(lcd:locate(1,0),"                    ")
  end
  if ctfws.startT then
    local str = string.format("%d\000: R=%s Y=%s",
                               ctfws.flagsN, tostring(ctfws.flagsR), tostring(ctfws.flagsY))
              :sub(1,20)
    lcd:put(lcd:locate(1,(20-#str)/2), str)
    attention(self,false)
  end
end

-- Displays only when the game is not configured; useful for initial
-- boot, perhaps.
local function drawFlagsMessage(self, msg)
  if self.ctfws.flagsN then return end -- NOP on game configured
  lcd:put(lcd:locate(1,0),string.format("%-20s", msg:sub(1,20)))
end

local function drawMessage(self, msg)
  local lcd = self.lcd
  local mlen = (msg and #msg) or 0
  self.mtmr:unregister()
  lcd:put(lcd:locate(2,0),"                    ")
  if not msg then return end
  if mlen <= 20
   then lcd:put(lcd:locate(2,(20-#msg)/2),msg)
   else
     -- inspired by lcd:run(), but corrected
     local ix = 1
     local function scroller()
       if     ix <= 20   then lcd:put(lcd:locate(2,20-ix),msg:sub(1,ix))
       elseif ix >  mlen then lcd:put(lcd:locate(2,0),msg:sub(ix-19)," ")
       else                   lcd:put(lcd:locate(2,0),msg:sub(ix-19,ix))
       end
       if ix >= mlen + 20 then ix = 1 else ix = ix + 1 end
     end
     self.mtmr:alarm(300, tmr.ALARM_AUTO, scroller)
  end
  attention(self,false)
end

local function reset(self)
  self.dl_elapsed = nil
  self.dl_remain  = nil
  self.dl_round   = nil
end

return function(ctfws, lcd, tq, t)
  self = {}
  self.ctfws = ctfws
  self.lcd = lcd
  self.tq = tq
  self.mtmr = t

  self.attnState        = nil

  self.reset            = reset
  self.drawTimes        = drawTimes
  self.drawFlags        = drawFlags
  self.drawMessage      = drawMessage
  self.drawFlagsMessage = drawFlagsMessage

  -- load custom flag glyph
  lcd:define_char(0,{ 0x1F, 0x15, 0x1B, 0x15, 0x1F, 0x10, 0x10, 0x0 })

  return self
end
