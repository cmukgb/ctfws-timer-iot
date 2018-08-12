-- game logic dictionary values:
--
--   setupD  -- deciseconds for setup round
--   roundD  -- deciseconds per round
--   rounds* -- number of rounds of game play
--   startT* -- POSIX seconds of game start
--   endT    -- POSIX seconds of game end (if set)
--
--   flagsN* -- total flags
--   flagsR* -- flags captured by the red team
--   flagsY* -- flags captured by the yellow team
--
-- *'d fields are publicly read; startT ~= nil is used as a proxy for "is
-- game configured"

-- returns round index, this round duration, elapsed time
-- round index: 0 for setup, 1-N for game play, and nil for game over / no game
-- all return times in deciseconds
local function times(self, nowf)
  if self.startT == nil then
    return nil, "GAME NOT CONFIGURED!"
  end

  -- Game declared over; show total elapsed time
  if self.endT and self.endT >= self.startT then
    local t = self.endT - self.startT
    return nil, string.format("GAME OVER @ %02d:%02d", t/60, t%60)
  end

  local now_sec, now_usec = nowf()

  if now_sec < self.startT then
    return nil, "START TIME IN FUTURE"
  end

  local elapsed = (now_sec - self.startT) * 10 + math.floor(now_usec / 100000)

  if elapsed < self.setupD then
    return 0, self.setupD, elapsed
  end

  elapsed = elapsed - self.setupD

  local rounds = math.floor(elapsed / self.roundD)
  if rounds >= self.rounds
   then return nil, "TIME IS UP"
   else -- game still in progress
     local roundElapsed = elapsed - rounds * self.roundD
     return rounds + 1, self.roundD, roundElapsed
  end
end

local function config(self, st, sd, nr, rd, nf)
  self.startT = st
  self.setupD = sd * 10
  self.rounds = nr
  self.roundD = rd * 10
  self.flagsN = nf
end

local function deconfig(self)
  self.startT = nil
  self.rounds = nil
  -- leave flagsN alone for end-of-game display logic
end

-- return whether or not a change took place, for duplicate message
-- suppression
local function setFlags(self, fr, fy)
  if (self.flagsR == fr) and (self.flagsY == fy) then return false end
  self.flagsR = fr
  self.flagsY = fy
  return true
end

local function setEndTime(self,t)
  self.endT = t
end

return function() 
  local self = {}
  self.times = times
  self.config = config
  self.deconfig = deconfig
  self.setFlags = setFlags
  self.setEndTime = setEndTime
  return self
end
