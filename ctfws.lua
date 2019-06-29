-- game logic dictionary values:
--
--   setupD  -- deciseconds for setup round
--   roundD  -- deciseconds per round
--   rounds* -- number of rounds of game play
--   startT* -- POSIX seconds of game start
--   endT    -- POSIX seconds of game end (if set)
--   tercfg  -- The territory config string
--   ter     -- My territory
--
--   flagsN* -- total flags
--   flagsR* -- flags captured by the red team
--   flagsY* -- flags captured by the yellow team
--
-- *'d fields are publicly read; startT ~= nil is used as a proxy for "is
-- game configured"

local v = {}

-- returns round index, this round duration, elapsed time
-- round index: 0 for setup, 1-N for game play, and nil for game over / no game
-- all return times in deciseconds
function v:times(nowf)
  if self.startT == nil then
    return nil, "GAME NOT CONFIGURED!"
  end

  -- Game declared over; show total elapsed time in game (excluding setup)
  if self.endT and self.endT >= self.startT then
    local t = (self.endT - self.startT) - (self.setupD / 10)
    if t < 0
      then return nil, "GAME OVER"
      else return nil, string.format("GAME OVER @ %02d:%02d", t/60, t%60)
    end
  end

  local now_sec, now_usec = nowf()

  if now_sec < self.startT then
    return nil, "START TIME IN FUTURE"
  end

  local elapsed = (now_sec - self.startT) * 10 + math.floor(now_usec / 100000)

  if elapsed < self.setupD then
    return 0, self.setupD, elapsed, elapsed -- treat setup (round 0) as a self-contained "game"
  end

  local gameElapsed = elapsed - self.setupD

  local rounds = math.floor(gameElapsed / self.roundD)
  if rounds >= self.rounds
   then return nil, "TIME IS UP"
   else -- game still in progress
     local roundElapsed = gameElapsed - rounds * self.roundD
     return rounds + 1, self.roundD, roundElapsed, gameElapsed
  end
end

function v:config(st, sd, nr, rd, nf, tc)
  self.startT = st
  self.setupD = sd * 10
  self.rounds = nr
  self.roundD = rd * 10
  self.flagsN = nf
  self.tercfg = tc
end

function v:deconfig()
  self.startT = nil
  self.rounds = nil
  -- leave flagsN alone for end-of-game display logic
end

-- return whether or not a change took place, for duplicate message
-- suppression
function v:setFlags(fr, fy)
  if (self.flagsR == fr) and (self.flagsY == fy) then return false end
  self.flagsR = fr
  self.flagsY = fy
  return true
end

function v:setEndTime(t)
  self.endT = t
end

function v:setTerritory(t)
  self.ter = t
end

function v:myTeam()
  if self.ter    == nil then return nil end
  if self.tercfg == nil then return nil end
  return ({ 'r', 'y' })[self.tercfg:find(self.ter)]
end

return v
