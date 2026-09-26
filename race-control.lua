-- race-control.lua — CSP online script (12h Curitiba)
--
-- Rules: document "Penalty rules — 12h Curitiba".
--   1. DT0 = serve on the lap it was given. DT1 = serve on this lap or the next.
--   2. Every DT loses one lap at each line crossing, including the one received in the pit pass itself.
--   3. Serving order: DT0 before DT1; same deadline, the oldest first. One pit pass serves one DT.
--   4. A slowdown that becomes a DT at the line crossing counts for the next lap.
--   5. Two DT0 pending on the same lap: hold of holdShortSeconds, clears the list. Exception: if one of them is
--      the PAC that became DT0 crossing the line on track: hold of holdLongSeconds, clears the list.
--   6. Crossing the line outside the pits with a DT0 pending: DSQ applied by the script (ac.PenaltyType.BlackFlag).
--      The DT0 of an end-of-lap slowdown does not count.
--   7. Two DT0 do not become one DT1; two DT1 do not become one DT2.
--
-- List categories: PAC = pit speeding DT applied by the game; SDn = unpaid slowdown of cut zone n.
-- In the game, a DT with k laps of deadline is sent with parameter k + 1.
-- The game DT (PAC) is detected by comparing the table with the game state before and after the line,
-- at pit exit and before the script writes to the game.
-- DSQ for leaving the pits with the session closed is outside the list (applied directly, with its own message).
-- Any DSQ clears the list; the script keeps running (the DSQ may be lifted by Race Control).

-- ============================================================
-- Configuration
-- ============================================================

-- Keys read from the script's own [SCRIPT_n] server section (ac.configValues uses the section that created it).
-- Every key below can be set in that section; the value here is the default used when the key is missing.
-- Session prefixes: practice / qualify / race (the session type reported by the game).
local cfg = ac.configValues({
  -- Car controls
  -- forceCockpit: 1 = the cockpit camera is forced (every cockpitCheckInterval seconds, except with the game paused or
  --   in a replay); 0 = off. Replaces the separate forcecockpitonline.lua script.
  forceCockpit = 0,
  -- cockpitCameraMode: camera forced (0 = cockpit, first person view; ac.CameraMode).
  cockpitCameraMode = 0,
  -- cockpitCheckInterval: seconds between checks.
  cockpitCheckInterval = 0.05,
  -- cockpitExemptSteamIDs: Steam IDs not forced (for example, Race Control / broadcast), separated by semicolons.
  cockpitExemptSteamIDs = '',

  -- penaltyMode
  --   'CSP': every client checks its own car and applies the penalties in the game (cut zones, DT list, holds,
  --          DSQ). This is the mode the rules document describes.
  --   'KMR': only the Race Control client (raceControlSteamID) checks every car, and only for the closed pit exit:
  --          it sends '/kmr player_kick <id>' through the chat (that client must be logged in as a KMR admin).
  --          Cut zones, slowdowns and the DT list are not used in this mode.
  penaltyMode = 'CSP',
  -- raceControlSteamID: Steam ID of the Race Control client ('KMR' mode only). Empty = nobody.
  raceControlSteamID = '',
  -- announce
  --   1: public chat lines sent by the driver's client ("Exclusion zone cut - slow down", "- drive-through",
  --      "- disqualified", "Pit exit with session closed - disqualified").
  --   0: no public lines. The hidden [RC] lines for the server log are always sent.
  announce = 0,

  -- Pit exit while closed
  -- <session>ClosedSeconds: seconds after the session start during which leaving the pit lane is forbidden.
  --   0 = the pit is never closed. Before the session starts, the pit counts as closed when the value is > 0.
  practiceClosedSeconds = 0,
  qualifyClosedSeconds = 120,
  raceClosedSeconds = 0,
  -- <session>Penalty: 'DSQ' = black flag + on-screen message (KMR mode: kick). 'NONE' = nothing.
  --   Any other value is ignored.
  practicePenalty = 'NONE',
  qualifyPenalty = 'DSQ',
  racePenalty = 'NONE',
  -- <session>PenaltyParam: not used (DSQ has no parameter).
  practicePenaltyParam = -1,
  qualifyPenaltyParam = -1,
  racePenaltyParam = -1,
  -- pitSlowdownDeadline / pitSlowdownMaxGas: not used.
  pitSlowdownDeadline = 0,
  pitSlowdownMaxGas = 0,

  -- Cut zone 1 (category SD1)
  -- cutZoneStart / cutZoneEnd: track spline position of the zone, 0..1. Start = end disables the zone.
  --   Start > end means the zone crosses the start/finish line.
  cutZoneStart = 0.16,
  cutZoneEnd = 0.24,
  -- cutMaxWheelsOut: penalty when more wheels than this are outside the track (3 = all four wheels out).
  --   At most one penalty per pass through the zone; not checked in the pit lane.
  cutMaxWheelsOut = 3,
  -- <session>CutPenalty
  --   'SLOWDOWN': the driver must lift (throttle <= cutSlowdownMaxGas, outside the pit lane) for
  --               <session>CutPenaltyParam seconds, within cutSlowdownDeadline seconds or before the end of the lap.
  --               Unpaid: <session>SlowdownUnpaidPenalty.
  --   'DT': drive-through DT0 at once. 'DSQ': black flag at once. 'NONE': nothing.
  --   The default 'SLOW DOWN' (with a space) is not a valid value: without the server key the zone does nothing.
  practiceCutPenalty = 'SLOW DOWN',
  qualifyCutPenalty = 'SLOW DOWN',
  raceCutPenalty = 'SLOW DOWN',
  -- <session>CutPenaltyParam: 'SLOWDOWN' seconds to pay. 0 = paid at once. Not used by 'DT' / 'DSQ'.
  practiceCutPenaltyParam = 0,
  qualifyCutPenaltyParam = 0,
  raceCutPenaltyParam = 0,
  -- cutSlowdownDeadline: seconds to pay the slowdown. The deadline keeps running in the pit lane; the payment
  --   does not. The line crossing also ends it (the DT0 then counts for the next lap).
  cutSlowdownDeadline = 10,
  -- cutSlowdownMaxGas: highest throttle (0..1) that still counts as lifting.
  cutSlowdownMaxGas = 0.2,

  -- Cut zone 2 (category SD2): same meaning as zone 1
  cutZone2Start = 0.81,
  cutZone2End = 0.91,
  cutZone2MaxWheelsOut = 3,
  practiceCutZone2Penalty = 'SLOW DOWN',
  qualifyCutZone2Penalty = 'SLOW DOWN',
  raceCutZone2Penalty = 'SLOW DOWN',
  practiceCutZone2PenaltyParam = 0,
  qualifyCutZone2PenaltyParam = 0,
  raceCutZone2PenaltyParam = 0,
  cutZone2SlowdownDeadline = 10,
  cutZone2SlowdownMaxGas = 0.1,

  -- Gain filter (slowdown only). Reference = the driver's best clean passage through the zone in this session.
  -- cutGainTolerance / cutZone2GainTolerance: % over the reference. A cut with the car back on track in less than
  --   reference x (1 + %) gets the slowdown; slower (lost time), no slowdown. No reference yet: slowdown as before.
  cutGainTolerance = 6,
  cutZone2GainTolerance = 6,
  -- cutSpinAngle: degrees between where the car points and where it moves; above it during the cut = spin, cut discarded
  cutSpinAngle = 90,
  -- Overlapping slowdowns (zone 2 while zone 1 is still running, or the other way round) are merged into one:
  -- the times add up, with the newest deadline; unpaid, each zone becomes its own DT0.

  -- Unpaid slowdown
  -- <session>SlowdownUnpaidPenalty
  --   'DT': DT0 of the category (SD1 / SD2). Deadline expired mid-lap: DT0 of the current lap (crossing the line on
  --         track without serving it = DSQ). Expired at the line, or inside the pit lane: DT0 of the next lap.
  --   'DSQ': black flag at once. 'NONE': nothing.
  practiceSlowdownUnpaidPenalty = 'DT',
  qualifySlowdownUnpaidPenalty = 'DT',
  raceSlowdownUnpaidPenalty = 'DT',
  -- <session>SlowdownUnpaidParam: not used (the DT is always DT0).
  practiceSlowdownUnpaidParam = 0,
  qualifySlowdownUnpaidParam = 0,
  raceSlowdownUnpaidParam = 0,

  -- Holds (rule 5): seconds stopped in the pits with locked controls; the hold clears the whole list
  -- holdShortSeconds: two pending DT0.
  holdShortSeconds = 45,
  -- holdLongSeconds: two pending DT0 when one of them is the PAC that became DT0 crossing the line on track.
  holdLongSeconds = 90,

  -- Driver swap panel (green, below the slowdown box; race sessions only). ACSM runs the swap itself: its timer
  -- starts when the driver disconnects and it tells the next driver "please wait ..." / "Free to leave pits in ..."
  -- / "You are clear to leave the pits, go go go!" through the chat; those chat lines are kept as they are.
  -- driverSwapEnabled: 1 = when the car stops at its pit place, the panel tells the driver to disconnect and shows
  --   the time since the stop and the total; the next driver sees the countdown sent by ACSM. 0 = no panel.
  driverSwapEnabled = 0,
  -- driverSwapMinSeconds: total swap time; must be the same value as "Minimum Driver Swap Time" in ACSM.
  driverSwapMinSeconds = 120,
  -- driverSwapRequired: number of mandatory driver swaps in the race (same as "Minimum number of driver swaps" in ACSM).
  --   Empty = not informed: the SWAP cell of the Race Control panel stays off. 0 = driver swaps allowed, none
  --   mandatory (valid server setup): the cell shows done | 0. Only with driverSwapEnabled = 1, race sessions.
  driverSwapRequired = '',

  -- CODE-80 (VSC / SC / full course yellow): no penalty can be served while it lasts. Started and ended by the server
  -- chat messages (start: "vsc", "virtual safety car", "safety car", "code-80", "code 80", "full course yellow";
  -- end: "green flag", "bandeira verde"). While it lasts: a pit pass pays nothing (the drive-through goes back to the
  -- game at the pit exit), slowdowns are not paid, and the hold for two pending DT0 waits for the green flag.
  -- code80FreezeDeadlines: 1 = deadlines stop: the line crossing does not take laps from the drive-throughs nor
  --   disqualify, and the slowdown deadline stops. 0 = deadlines keep running.
  code80FreezeDeadlines = 1,

  -- Tow and repair hold (race sessions only): the car is locked in the pits (TeleportToPits) for
  --   back to pits from the track (teleport): raceTowSeconds + repair;
  --   repair chosen in the pit menu (car driven to its pit place): repair.
  -- repair = raceRepairFactor x (repairBaseSeconds x (repairWeightEngine x powertrain + repairWeightSuspension x
  --          suspension) + repairWeightBody x body)
  -- Only damage from collisions counts: the damage that appears within COLLISION_DAMAGE_WINDOW seconds after a
  -- collision (ac.onCarCollision). Normal wear (engine life going down with use and revs) is not charged.
  --   powertrain = engine and gearbox together (the gearbox cannot be set by the script and breaks at 1): each frame,
  --     the larger of the engine damage increase (engineLifeLeft / 1000) and the gearbox damage increase;
  --   suspension = increase of the 4 wheels (0..1 each); body = increase of the body damage zones in km/h (car.damage).
  -- Counted until the car is repaired (the hold). raceTowSeconds = 0 and raceRepairFactor = 0 disable it. With it on,
  -- set ENFORCE_BACK_TO_PITS_PENALTY = 0 in [EXTRA_RULES], or the driver also gets the AC back-to-pits penalty.
  raceTowSeconds = 120,
  raceRepairFactor = 1.5,
  repairBaseSeconds = 180,
  -- repairWeightEngine: weight of the powertrain (engine + gearbox)
  repairWeightEngine = 1.0,
  repairWeightSuspension = 0.5,
  repairWeightBody = 0.25,
})


local TEXTS = {
  pit = {
    DSQ = 'Pit exit with session closed - disqualified',
  },
  cut = {
    SLOWDOWN = 'Exclusion zone cut - slow down',
    DT = 'Exclusion zone cut - drive-through',
    DSQ = 'Exclusion zone cut - disqualified',
  },
  timer = 'SLOW DOWN  %.1f s   deadline %.0f s or end of lap',
  -- slowdown box and gain check box (same size, same font)
  sdTitle = 'EXCLUSION ZONE CUT - slow down',
  liftTitle = 'EXCLUSION ZONE CUT - lift to avoid a slowdown',
  liftSlower = 'slower - no penalty',
  liftFaster = 'faster - slowdown',
  liftLimit = '+%g%% ref',
  -- Race Control: server log line (chat, hidden from every client) and the box on the penalized driver's screen
  rcPrefix = '[RC] ',
  rcTitle = 'RACE CONTROL',
  -- Race Control panel cells
  cellPit = 'PIT WINDOW',
  cellSwap = 'SWAP',
  cellTrack = 'TRACK',
  cellPenalties = 'PENALTIES',
  pitOpen = 'OPEN %s',
  pitDone = 'DONE',
  pitMissed = 'MISSED',
  pitOpenMsg = 'Mandatory pit window open - stop before it closes',
  swapCount = '%d | %d',
  trackYellow = 'YELLOW',
  trackBlue = 'BLUE',
  penHold = 'HOLD',
  penDsq = 'DSQ',
  kmrTitle = 'KMR',
  -- driver swap panel
  swapActive = 'DRIVER SWAP ACTIVE',
  swapTitle = 'DRIVER SWAP',
  swapDisconnect = 'Disconnect to perform the driver swap',
  swapWait = 'You are now driving - wait %s before leaving the pits',
  swapClear = 'You are clear to leave the pits - GO GO GO!',
  swapTimes = 'Elapsed %s / Total %s',
  -- CODE-80 and holds (message box)
  code80 = 'CODE 80 - no penalty can be served until the green flag',
  holdTitle = 'HOLD',
  hold = 'Hold %s - %s',
  holdTwoDT = 'Two pending drive-throughs',
  holdTwoDTLong = 'Two pending drive-throughs (pit lane speeding expired on track)',
  towReason = 'Back to pits',
  repairReason = 'Repair in the pit stop',
  reason = {
    SD1 = 'Exclusion zone cut - zone 1',
    SD2 = 'Exclusion zone cut - zone 2',
    PAC = 'Pit lane speeding',
  },
  pitDsq = "You've been disqualified for leaving the pit lane with the session closed.",
  dtDsq = "You've been disqualified for not serving the drive-through.",
}

local MANDATORY_PITS = ac.PenaltyType.MandatoryPits
local BLACK_FLAG = ac.PenaltyType.BlackFlag
local TELEPORT_TO_PITS = ac.PenaltyType.TeleportToPits
local NONE = ac.PenaltyType.None
-- Value the game reports in car.currentPenaltyType for a drive-through (written with MandatoryPits):
-- 2/N while pending, 2/0 once served (verified in game by Oval Racing System and in this script's log)
local GAME_DT = 2

local function rule(penalty, param)
  return {
    penalty = string.upper(tostring(penalty)),
    param = math.floor(tonumber(param) or -1),
  }
end

local function bySession(practice, qualify, race)
  return {
    [ac.SessionType.Practice] = practice,
    [ac.SessionType.Qualify] = qualify,
    [ac.SessionType.Race] = race,
  }
end

local function makeZone(category, startPos, endPos, maxWheelsOut, rules, deadline, maxGas, gainTolerance)
  local s = tonumber(startPos) or 0
  local e = tonumber(endPos) or 0
  return {
    category = category,
    enabled = s ~= e,
    startPos = s,
    endPos = e,
    maxWheelsOut = math.floor(tonumber(maxWheelsOut) or 4),
    rules = rules,
    deadline = tonumber(deadline) or 0,
    maxGas = tonumber(maxGas) or 0,
    gainTolerance = tonumber(gainTolerance) or 6,
  }
end

local config = {
  mode = string.upper(tostring(cfg.penaltyMode)),
  raceControlSteamID = tostring(cfg.raceControlSteamID),
  announce = tonumber(cfg.announce) == 1,
  holdShort = tonumber(cfg.holdShortSeconds) or 45,
  holdLong = tonumber(cfg.holdLongSeconds) or 90,
  swapEnabled = tonumber(cfg.driverSwapEnabled) == 1,
  swapMinSeconds = tonumber(cfg.driverSwapMinSeconds) or 120,
  -- nil = not informed (cell off); 0 or more = shown
  swapRequired = tonumber(cfg.driverSwapRequired) and math.floor(tonumber(cfg.driverSwapRequired)) or nil,
  cutSpinAngle = tonumber(cfg.cutSpinAngle) or 90,
  code80Freeze = tonumber(cfg.code80FreezeDeadlines) == 1,
  tow = {
    seconds = tonumber(cfg.raceTowSeconds) or 0,
    factor = tonumber(cfg.raceRepairFactor) or 0,
    base = tonumber(cfg.repairBaseSeconds) or 0,
    wEngine = tonumber(cfg.repairWeightEngine) or 0,
    wSuspension = tonumber(cfg.repairWeightSuspension) or 0,
    wBody = tonumber(cfg.repairWeightBody) or 0,
  },

  pit = {
    closedSeconds = bySession(
      tonumber(cfg.practiceClosedSeconds) or 0,
      tonumber(cfg.qualifyClosedSeconds) or 0,
      tonumber(cfg.raceClosedSeconds) or 0),
    rules = bySession(
      rule(cfg.practicePenalty, cfg.practicePenaltyParam),
      rule(cfg.qualifyPenalty, cfg.qualifyPenaltyParam),
      rule(cfg.racePenalty, cfg.racePenaltyParam)),
  },

  cutZones = {
    makeZone('SD1', cfg.cutZoneStart, cfg.cutZoneEnd, cfg.cutMaxWheelsOut,
      bySession(
        rule(cfg.practiceCutPenalty, cfg.practiceCutPenaltyParam),
        rule(cfg.qualifyCutPenalty, cfg.qualifyCutPenaltyParam),
        rule(cfg.raceCutPenalty, cfg.raceCutPenaltyParam)),
      cfg.cutSlowdownDeadline, cfg.cutSlowdownMaxGas, cfg.cutGainTolerance),
    makeZone('SD2', cfg.cutZone2Start, cfg.cutZone2End, cfg.cutZone2MaxWheelsOut,
      bySession(
        rule(cfg.practiceCutZone2Penalty, cfg.practiceCutZone2PenaltyParam),
        rule(cfg.qualifyCutZone2Penalty, cfg.qualifyCutZone2PenaltyParam),
        rule(cfg.raceCutZone2Penalty, cfg.raceCutZone2PenaltyParam)),
      cfg.cutZone2SlowdownDeadline, cfg.cutZone2SlowdownMaxGas, cfg.cutZone2GainTolerance),
  },

  unpaid = bySession(
    rule(cfg.practiceSlowdownUnpaidPenalty, cfg.practiceSlowdownUnpaidParam),
    rule(cfg.qualifySlowdownUnpaidPenalty, cfg.qualifySlowdownUnpaidParam),
    rule(cfg.raceSlowdownUnpaidPenalty, cfg.raceSlowdownUnpaidParam)),
}

config.isRaceControl = config.mode == 'KMR'
  and config.raceControlSteamID ~= ''
  and ac.getUserSteamID() == config.raceControlSteamID

-- ============================================================
-- State
-- ============================================================

local sim = ac.getSim()

local state = {
  lastSessionIndex = -1,
  prevInPitlane = {},
  cutPassPenalized = {},
  zonePass = {},          -- [zone] passage in progress: { t0, samples, nextIdx, dirty }
  zoneRef = {},           -- [zone] reference passage (samples, ms), this session
  cutChecks = {},         -- [zone] cut being checked against the reference: { zone, rule, lapCount, t0, ref, margin, spun }
  pitDsqActive = false,
  dtDsqActive = false,
  -- active slowdowns, one per zone (category SD1, SD2)
  slowdowns = {},
  list = {
    items = {},           -- { cat, kind, laps, givenLap, expireLap, seq, dt0OnTrack }; items[1] = position 0
    curLap = 0,           -- current lap (car.lapCount)
    seq = 0,
    inGameItem = nil,     -- table item that is in the game
    written = 0,          -- game parameter of the inGameItem DT (written by the script, or read from the game for a PAC)
    paying = nil,         -- parameter of the DT the game is clearing in the pit pass in progress
    inPitNow = false,     -- car in the pit lane in the current frame
    jumped = false,       -- car teleported (ac.onCarJumped): the penalty stays until a real pit pass pays it
    endOfLap = {},        -- slowdowns that expired at the line crossing (count for the next lap)
    lastLap = 0,
    prevGame = { t = 0, p = 0 },  -- last processed game state
    prevInPit = false,
    wrote = false,        -- the script wrote to the game in this frame
  },
  chat = {
    queue = {},
    cooldown = 0,
  },
  -- driver swap panel
  swap = {
    prevInPit = nil,      -- car parked at its pit place in the previous frame (nil = first frame)
    stopT = nil,          -- clock when the car stopped at its pit place (driver leaving the car)
    remaining = nil,      -- seconds left in the ACSM countdown (driver taking the car), at remainingT
    remainingT = 0,
    fromPeers = false,    -- remaining came from the other clients (relay), not from the ACSM message
    clearUntil = nil,     -- "clear to leave" shown until this clock
    lastNames = {},       -- [carIndex] = last known driver name (other cars)
    left = {},            -- [carIndex] = { sessionID, driver = name code, t = clock } drivers that left a car
    relay = {},           -- pending SWAP_INFO sends: { target, car, driver, swaps, leftT, dueT }
    count = 0,            -- driver swaps done by this car in the race (SWAP cell)
    carSwaps = {},        -- [carIndex] = swaps done by other cars, seen by this client (sent to the next driver)
    carLists = {},        -- [carIndex] = penalty list published by the driver of another car when parked
    listSent = nil,       -- signature of the own list last published while parked
    listApplied = false,  -- penalty list of the previous driver already received (this session)
    pendingList = nil,    -- received list waiting to be applied in script.update
  },
  code80 = nil,           -- CODE-80 in progress: 'VSC', 'SC' or 'CODE-80' (from the server chat); nil = green
  code80Ended = false,    -- green flag received: the rules deferred during CODE-80 run in the next frame
  hold = nil,             -- hold in progress (locked in the pits): { untilT, text }; drive-throughs are not written
  pit = { done = false }, -- mandatory pit stop done inside the pit window (PIT WINDOW cell)
  -- tow and repair hold
  tow = {
    damage = nil,         -- collision damage not repaired yet: { powertrain, suspension, body }
    lastRead = nil,       -- damage read in the previous frame outside the pit lane
    collisionUntil = -1,  -- damage increases until this clock come from a collision
    jumpPending = false,  -- teleport from the track to process in the next frame
    ownJumpUntil = -1,    -- teleports until this clock are the script's own holds
    repairDone = false,   -- repair hold already applied in this pit stop
    prevRepairing = false,
  },
  -- penalty message box
  ui = {
    clock = 0,            -- seconds since the script started (blink and notice timing)
    notice = nil,         -- { title, text, item, untilT }: new penalty shown for a few seconds
    lastSeq = 0,          -- last table seq already announced in the box
  },
}

local zoneLog = {}
for _, zone in ipairs(config.cutZones) do
  zoneLog[#zoneLog + 1] = zone.category .. '=' .. tostring(zone.enabled) .. ' ' .. zone.startPos .. '-' .. zone.endPos
end
-- Teleport or car reset (SDK: ac.onCarJumped). The script's own holds (TeleportToPits) are ignored: the car is
-- already where the hold was applied. A teleport from the track gets the tow hold in the next frame.
ac.onCarJumped(0, function()
  if state.ui.clock <= state.tow.ownJumpUntil then
    ac.log('race-control: car jumped (hold)')
    return
  end
  state.list.jumped = true
  if not state.list.prevInPit then state.tow.jumpPending = true end
  ac.log('race-control: car jumped')
end)

ac.log('race-control: section=' .. tostring(__cfgSection__)
  .. ' mode=' .. config.mode
  .. ' physics.allowed=' .. tostring(physics.allowed())
  .. ' ' .. table.concat(zoneLog, ' '))

-- ============================================================
-- Utilities
-- ============================================================

local function queueChat(msg)
  if not config.announce then return end
  state.chat.queue[#state.chat.queue + 1] = msg
end

-- Seconds as m:ss
local function mmss(seconds)
  local s = math.max(math.floor(seconds + 0.5), 0)
  return string.format('%d:%02d', math.floor(s / 60), s % 60)
end

-- Driver identification for Race Control lines: "#<number> <name>"
local function driverTag()
  return string.format('#%d %s', ac.getDriverNumber(0) or 0, tostring(ac.getDriverName(0) or ''))
end

-- Race Control log: always sent through the chat so it reaches the server log; every client hides it (see onChatMessage)
local function rcLog(what, reason)
  local msg = string.format('%s%s - %s - %s', TEXTS.rcPrefix, what, driverTag(), reason)
  state.chat.queue[#state.chat.queue + 1] = msg
  ac.log('race-control: ' .. msg)
end

-- Penalty message box: a new penalty is shown for NOTICE_SECONDS, then the box goes back to the one being paid.
-- Server messages (KMR, ACSM) are shown for SERVER_NOTICE_SECONDS.
local NOTICE_SECONDS = 3
local SERVER_NOTICE_SECONDS = 5

local function showNotice(title, text, item, seconds, flag)
  state.ui.notice = { title = title, text = text, item = item, flag = flag,
    untilT = state.ui.clock + (seconds or NOTICE_SECONDS) }
end

-- Server message dictionary (lowercase, plain text; no bare "DT" so names and other words are not caught)
local DICT = {
  driveThrough = { 'drive-through', 'drive through', 'drivethrough', 'stop and go', 'stop-and-go', 'stop & go' },
  vsc = { 'virtual safety car' },   -- plus the whole word "vsc"
  sc = { 'safety car' },            -- checked after VSC
  code80 = { 'code-80', 'code 80', 'código-80', 'codigo-80', 'código 80', 'codigo 80', 'full course yellow' },
  green = { 'green flag', 'bandeira verde' },   -- end of CODE-80; checked first
  rolling = { 'rolling start', 'formation lap' },
}

-- Kinds that start CODE-80
local CODE80_KINDS = { VSC = true, SC = true, ['CODE-80'] = true }

local function hasAny(text, words)
  for _, word in ipairs(words) do
    if text:find(word, 1, true) then return true end
  end
  return false
end

-- Classifies a server message: 'GREEN FLAG', 'VSC', 'SC', 'CODE-80', 'ROLLING START', 'DT' (only when it names this
-- driver) or nil
local function classifyServerMessage(message)
  local low = message:lower()
  if hasAny(low, DICT.green) then return 'GREEN FLAG' end
  if low:find('%f[%w]vsc%f[%W]') or hasAny(low, DICT.vsc) then return 'VSC' end
  if hasAny(low, DICT.sc) then return 'SC' end
  if hasAny(low, DICT.code80) then return 'CODE-80' end
  if hasAny(low, DICT.rolling) then return 'ROLLING START' end
  local name = tostring(ac.getDriverName(0) or '')
  if name ~= '' and message:find(name, 1, true) and hasAny(low, DICT.driveThrough) then return 'DT' end
  return nil
end

-- ACSM sends durations in Go format: "1m35s", "45s", "2m0s"
local function parseGoDuration(text)
  local total, found = 0, false
  for num, unit in text:gmatch('([%d%.]+)([hms])') do
    total = total + tonumber(num) * (unit == 'h' and 3600 or unit == 'm' and 60 or 1)
    found = true
  end
  return found and total or nil
end

-- ACSM driver swap messages to the driver taking the car (race_control.go, handleDriverSwap). Returns true if handled.
local function onDriverSwapMessage(message)
  local low = message:lower()
  local wait = low:match('please wait (%S+) before leaving the pits') or low:match('^free to leave pits in (%S+)')
  if wait then
    local seconds = parseGoDuration(wait)
    if seconds then
      state.swap.remaining = seconds
      state.swap.remainingT = state.ui.clock
      state.swap.fromPeers = false
      state.swap.clearUntil = nil
    end
    return true
  end
  if low:find('you are clear to leave the pits', 1, true) then
    state.swap.remaining = nil
    state.swap.clearUntil = state.ui.clock + SERVER_NOTICE_SECONDS
    return true
  end
  if low:find('during a driver swap', 1, true) then
    -- kicked / penalty for leaving the pits early: shown in the penalty message box
    state.swap.remaining = nil
    showNotice(TEXTS.rcTitle, message, nil, SERVER_NOTICE_SECONDS)
    return true
  end
  return false
end

-- Driver swap relay between clients. ACSM sends "please wait ... before leaving the pits" only once, when the new
-- driver's car first reports its position (race_control.go, handleDriverSwap), possibly before the new driver's
-- script runs, and the SDK has no chat history. So every connected client records when a driver leaves a car
-- (ac.onClientDisconnected) and, when a driver enters that car (ac.onClientConnected), sends only to the new driver
-- how long ago the previous driver left and who it was. The new driver's script starts the countdown from it; if the
-- previous driver is the new driver himself, it is a reconnection and no countdown is shown. The ACSM message, when
-- received, takes over. Fixed-size message (message codes: 1 = SWAP_INFO; 2 = CAR_STATE, 3 = PIT_DONE reserved).
local MSG_SWAP_INFO = 1
local SWAP_COUNT_KEY = 'race-control.swaps'
-- Seconds after the connection at which SWAP_INFO is sent (again), in case the new driver's script is not running yet
local SWAP_RELAY_DELAYS = { 1, 4, 10 }

-- Name code: same number on every client, to compare drivers without sending their names
local function nameCode(name)
  local h = 5381
  name = tostring(name or '')
  for i = 1, #name do h = (h * 33 + name:byte(i)) % 4294967296 end
  return h
end

local function onSwapInfo(msg)
  local sw = state.swap
  if not config.swapEnabled or sim.raceSessionType ~= ac.SessionType.Race then return end
  if msg.pcType ~= MSG_SWAP_INFO or msg.pcCar ~= ac.getCar(0).sessionID then return end
  -- Already counting (first message received, or the ACSM message): the others are the same information
  if sw.remaining or sw.clearUntil then return end
  if msg.pcDriver == nameCode(ac.getDriverName(0)) then
    ac.log('race-control: swap relay: same driver reconnected, no countdown')
    return
  end
  -- Swaps done by this car (the peers already counted this one)
  sw.count = math.max(sw.count, msg.pcSwaps or 0)
  ac.store(SWAP_COUNT_KEY, string.format('%d|%d', sim.currentSessionIndex, sw.count))
  local left = config.swapMinSeconds - msg.pcElapsed / 10
  ac.log(string.format('race-control: swap relay: previous driver left %.1f s ago, wait %.1f s',
    msg.pcElapsed / 10, math.max(left, 0)))
  if left <= 0 then return end
  sw.remaining = left
  sw.remainingT = state.ui.clock
  sw.fromPeers = true
end

local sendSwapInfo = ac.OnlineEvent({
  ac.StructItem.key('12hcuritiba.race-control.swap'),
  pcType = ac.StructItem.uint8(),
  pcCar = ac.StructItem.uint8(),
  pcDriver = ac.StructItem.uint32(),
  pcElapsed = ac.StructItem.uint16(),
  pcSwaps = ac.StructItem.uint8(),
}, function(sender, msg)
  -- Own messages come back too (sender.index 0): ignored
  if sender and sender.index == 0 then return end
  onSwapInfo(msg)
end, nil, nil, { processPostponed = true })

ac.onClientDisconnected(function(carIndex, sessionID)
  if not config.swapEnabled or sim.raceSessionType ~= ac.SessionType.Race or carIndex == 0 then return end
  local name = state.swap.lastNames[carIndex] or ac.getDriverName(carIndex)
  state.swap.left[carIndex] = { sessionID = sessionID, driver = nameCode(name), t = state.ui.clock }
end)

ac.onClientConnected(function(carIndex, sessionID)
  local sw = state.swap
  local rec = sw.left[carIndex]
  if not rec or carIndex == 0 then return end
  sw.left[carIndex] = nil
  -- Only while the swap can still be running
  if state.ui.clock - rec.t > config.swapMinSeconds then return end
  -- A different driver in the car: one more swap for it. Same driver (reconnection): no swap, nothing carried
  if nameCode(ac.getDriverName(carIndex)) == rec.driver then
    sw.carLists[carIndex] = nil
    return
  end
  sw.carSwaps[carIndex] = (sw.carSwaps[carIndex] or 0) + 1
  for _, delay in ipairs(SWAP_RELAY_DELAYS) do
    sw.relay[#sw.relay + 1] = { target = sessionID, car = sessionID, driver = rec.driver, leftT = rec.t,
      swaps = sw.carSwaps[carIndex] or 0, list = sw.carLists[carIndex], dueT = state.ui.clock + delay }
  end
end)

local sendPenaltyList
-- Penalty list carried to the next driver (penalties belong to the car). The driver parked at the pit place publishes
-- the list; every other client keeps the last list of each car and, when a different driver enters that car, sends
-- it only to the new driver together with SWAP_INFO. Fixed size: up to PENALTY_LIST_MAX items, category code + laps.
local PENALTY_LIST_MAX = 4
local CAT_CODES = { PAC = 1, SD1 = 2, SD2 = 3 }
local CAT_NAMES = { 'PAC', 'SD1', 'SD2' }

local function applyPenaltyList(msg)
  local sw = state.swap
  if not config.swapEnabled or sim.raceSessionType ~= ac.SessionType.Race then return end
  if msg.pcCar ~= ac.getCar(0).sessionID or sw.listApplied then return end
  sw.listApplied = true
  local items = {}
  for i = 1, math.min(msg.pcCount, PENALTY_LIST_MAX) do
    local cat = CAT_NAMES[msg['pcCat' .. i]]
    if cat then items[#items + 1] = { cat = cat, laps = msg['pcLaps' .. i] } end
  end
  -- Applied in script.update, where the list functions are available
  if #items > 0 then sw.pendingList = items end
end

local penaltyListLayout = {
  ac.StructItem.key('12hcuritiba.race-control.list'),
  pcCar = ac.StructItem.uint8(),
  pcCount = ac.StructItem.uint8(),
  pcTarget = ac.StructItem.uint8(),   -- 255 = published by the driver of pcCar; else relayed to this session
}
for i = 1, PENALTY_LIST_MAX do
  penaltyListLayout['pcCat' .. i] = ac.StructItem.uint8()
  penaltyListLayout['pcLaps' .. i] = ac.StructItem.uint8()
end
local sendPenaltyListEvent = ac.OnlineEvent(penaltyListLayout, function(sender, msg)
  if sender and sender.index == 0 then return end
  if msg.pcTarget == 255 then
    -- Published by the driver of another car: kept for the next driver of that car
    if sender and config.swapEnabled then
      local list = { count = math.min(msg.pcCount, PENALTY_LIST_MAX) }
      for i = 1, list.count do list[i] = { cat = msg['pcCat' .. i], laps = msg['pcLaps' .. i] } end
      state.swap.carLists[sender.index] = list
    end
  else
    applyPenaltyList(msg)
  end
end, nil, nil, { processPostponed = true })

sendPenaltyList = function(list, car, target)
  local msg = { pcCar = car, pcCount = list.count, pcTarget = target and 0 or 255 }
  for i = 1, list.count do
    msg['pcCat' .. i] = list[i].cat
    msg['pcLaps' .. i] = list[i].laps
  end
  sendPenaltyListEvent(msg, false, target)
end

-- Driver parked at the pit place in a race: publishes the own list (again if it changes while parked)
local function publishOwnList(car)
  local sw = state.swap
  if not config.swapEnabled or sim.raceSessionType ~= ac.SessionType.Race or not car.isInPit then
    sw.listSent = nil
    return
  end
  local list = { count = 0 }
  local sig = {}
  for _, it in ipairs(state.list.items) do
    if list.count < PENALTY_LIST_MAX and CAT_CODES[it.cat] then
      list.count = list.count + 1
      list[list.count] = { cat = CAT_CODES[it.cat], laps = math.max(it.laps, 0) }
      sig[#sig + 1] = it.cat .. it.laps
    end
  end
  local signature = table.concat(sig, ',')
  if sw.listSent == signature then return end
  sw.listSent = signature
  sendPenaltyList(list, car.sessionID, nil)
end

-- Sends the scheduled SWAP_INFO messages and keeps the last known name of each driver
local function updateSwapRelay()
  local sw = state.swap
  if not config.swapEnabled or sim.raceSessionType ~= ac.SessionType.Race then return end
  for i = 1, sim.carsCount - 1 do
    local c = ac.getCar(i)
    if c and c.isConnected then sw.lastNames[i] = ac.getDriverName(i) end
  end
  local clock = state.ui.clock
  for i = #sw.relay, 1, -1 do
    local r = sw.relay[i]
    if clock >= r.dueT then
      table.remove(sw.relay, i)
      local elapsed = math.min(math.floor((clock - r.leftT) * 10 + 0.5), 65535)
      sendSwapInfo({ pcType = MSG_SWAP_INFO, pcCar = r.car, pcDriver = r.driver, pcElapsed = elapsed,
        pcSwaps = math.min(r.swaps, 255) }, false, r.target)
      if r.list and r.list.count > 0 then sendPenaltyList(r.list, r.car, r.target) end
    end
  end
end

-- Chat: Race Control lines are for the server log only, hidden from the chat of every client. Server messages
-- (senderCarIndex = -1, KMR or ACSM) that match the dictionary are also shown in the penalty message box, and the
-- ACSM driver swap messages feed the driver swap panel; everything stays in the chat.
ac.onChatMessage(function(message, senderCarIndex)
  if type(message) ~= 'string' then return false end
  if message:sub(1, #TEXTS.rcPrefix) == TEXTS.rcPrefix then return true end
  if senderCarIndex == -1 and onDriverSwapMessage(message) then return false end
  if senderCarIndex == -1 then
    local kind = classifyServerMessage(message)
    if kind == 'DT' then
      local prefix = tostring(ac.getDriverName(0) or '') .. ':'
      local text = message
      if message:sub(1, #prefix) == prefix then text = message:sub(#prefix + 1):gsub('^%s+', '') end
      showNotice(TEXTS.kmrTitle, text, nil, SERVER_NOTICE_SECONDS)
    elseif kind then
      if CODE80_KINDS[kind] then
        if not state.code80 then ac.log('race-control: CODE-80 start (' .. kind .. ')') end
        state.code80 = kind
      elseif kind == 'GREEN FLAG' and state.code80 then
        state.code80 = nil
        state.code80Ended = true
        ac.log('race-control: CODE-80 end')
      end
      showNotice(TEXTS.rcTitle .. '  ' .. kind, message, nil, SERVER_NOTICE_SECONDS, kind)
    end
  end
  return false
end)

local function updateChat(dt)
  local chat = state.chat
  chat.cooldown = chat.cooldown - dt
  if #chat.queue > 0 and chat.cooldown <= 0 then
    if ac.sendChatMessage(chat.queue[1]) then
      table.remove(chat.queue, 1)
    end
    chat.cooldown = 1
  end
end

local function sessionElapsedMs()
  local s = ac.getSession(sim.currentSessionIndex)
  if not s then return 0 end
  if s.durationMinutes > 0 then
    return s.durationMinutes * 60000 - sim.sessionTimeLeft
  end
  return sim.time - s.startTime
end

local function isPitClosed()
  local closedSeconds = config.pit.closedSeconds[sim.raceSessionType] or 0
  if closedSeconds <= 0 then return false end
  if not sim.isSessionStarted then return true end
  return sessionElapsedMs() < closedSeconds * 1000
end

local function isInZone(zone, p)
  if zone.startPos < zone.endPos then
    return p >= zone.startPos and p <= zone.endPos
  end
  return p >= zone.startPos or p <= zone.endPos
end

-- ============================================================
-- Rules module
-- The only place that changes the DT list and applies the rules of the "Penalty rules" document.
-- Every event enters through a Rules.* function; after any change, Rules.finalize applies,
-- always in the same order: sorting (rule 3), two pending DT0 (rule 5) and saving.
-- Position 0 goes to the game in Rules.tick: outside the pit lane and never on the line crossing frame.
-- The game applies and resolves the DT; the script writes to the game only to set position 0,
-- for the hold and for the DSQs (rule 6 and closed pit).
-- Pit pass payment: at the line inside the pit, position 0 leaves the table (rule 3).
-- PAC: game DT (GAME_DT with parameter > 0) the table does not explain (nothing sent, or a parameter other than
-- the written one and the one being paid); the deadline comes from the game. Read only at events: before the line,
-- after the line on track, at pit exit and before the script writes to the game.
-- ============================================================

local LIST_KEY = 'race-control.list'
local Rules = {}

local function listSave()
  local l = state.list
  local parts = {}
  local inGameIndex = 0
  for i, it in ipairs(l.items) do
    parts[#parts + 1] = string.format('%s,%s,%d,%d,%d,%d,%d', it.cat, it.kind, it.laps, it.givenLap, it.expireLap,
      it.seq, it.dt0OnTrack and 1 or 0)
    if it == l.inGameItem then inGameIndex = i end
  end
  ac.store(LIST_KEY, string.format('%d|%d|%d|%s', sim.currentSessionIndex, l.seq, inGameIndex, table.concat(parts, ';')))
end

local function listLoad()
  local l = state.list
  l.items = {}
  l.seq = 0
  l.inGameItem = nil
  local data = ac.load(LIST_KEY)
  if type(data) ~= 'string' then return end
  local sessionPart, seqPart, inGamePart, itemsPart = data:match('^(%-?%d+)|(%d+)|(%d+)|(.*)$')
  if tonumber(sessionPart) ~= sim.currentSessionIndex or not itemsPart then return end
  l.seq = tonumber(seqPart)
  for cat, kind, laps, givenLap, expireLap, seq, onTrack in
      itemsPart:gmatch('(%w+),(%w+),(%-?%d+),(%-?%d+),(%-?%d+),(%d+),(%d)') do
    l.items[#l.items + 1] = { cat = cat, kind = kind, laps = tonumber(laps), givenLap = tonumber(givenLap),
      expireLap = tonumber(expireLap), seq = tonumber(seq), dt0OnTrack = onTrack == '1' }
  end
  l.inGameItem = l.items[tonumber(inGamePart)]
end

-- Rule 3: DT0 before DT1; same deadline, the oldest first
local function listSort()
  table.sort(state.list.items, function(a, b)
    if a.laps ~= b.laps then return a.laps < b.laps end
    return a.seq < b.seq
  end)
end

-- Given lap = current lap; expire lap = given lap + deadline (the DSQ applies when that lap ends unpaid)
local function listAdd(cat, laps)
  local l = state.list
  l.seq = l.seq + 1
  local item = { cat = cat, kind = 'DT', laps = laps, givenLap = l.curLap, expireLap = l.curLap + laps, seq = l.seq,
    dt0OnTrack = false }
  l.items[#l.items + 1] = item
  return item
end

-- Table in the log: position:category/kind/deadline/given lap/expire lap (* = in the game)
local function listDump()
  local l = state.list
  local parts = {}
  for i, it in ipairs(l.items) do
    parts[#parts + 1] = string.format('%d:%s/%s/%d/%d/%d%s', i - 1, it.cat, it.kind, it.laps, it.givenLap,
      it.expireLap, it == l.inGameItem and '*' or '')
  end
  return '[' .. table.concat(parts, ' ') .. ']'
end

local function listRemove(item)
  local l = state.list
  for i, it in ipairs(l.items) do
    if it == item then
      table.remove(l.items, i)
      break
    end
  end
  if l.inGameItem == item then l.inGameItem = nil end
end

-- The list is void: clear it, including the slowdowns in progress
function Rules.zero()
  local l = state.list
  l.items = {}
  l.inGameItem = nil
  l.paying = nil
  l.endOfLap = {}
  state.slowdowns = {}
  listSave()
end

-- Removes the DT from the game (position 0 is part of the list that is cleared).
-- MandatoryPits with parameter 0 removes the DT (original script header); None did not remove it (log 25/09 02:25).
local function clearGamePenalty()
  physics.setCarPenalty(MANDATORY_PITS, 0)
end

-- Pending DT0
local function pendingDT0()
  local out = {}
  for _, it in ipairs(state.list.items) do
    if it.laps == 0 then out[#out + 1] = it end
  end
  return out
end

local function hasLongHold(items)
  for _, it in ipairs(items) do
    if it.cat == 'PAC' and it.dt0OnTrack then return true end
  end
  return false
end

-- Locks the car in the pits (TeleportToPits) and shows the countdown in the message box. The teleport it causes is
-- not a driver teleport (ac.onCarJumped ignores it).
local function startHold(seconds, text)
  state.tow.ownJumpUntil = state.ui.clock + 2
  physics.setCarPenalty(TELEPORT_TO_PITS, seconds)
  state.list.wrote = true
  state.hold = { untilT = state.ui.clock + seconds, text = text }
end

-- Rule 5: hold, clears the list; only the hold remains in the game
local function applyHold(long)
  local seconds = long and config.holdLong or config.holdShort
  local reason = long and TEXTS.holdTwoDTLong or TEXTS.holdTwoDT
  clearGamePenalty()
  startHold(seconds, reason)
  Rules.zero()
  ac.log(string.format('race-control: hold %d s', seconds))
  rcLog(string.format('Hold %d s', seconds), reason)
end

-- Seconds after a collision in which damage increases are charged as collision damage
local COLLISION_DAMAGE_WINDOW = 1.5

ac.onCarCollision(0, function()
  state.tow.collisionUntil = state.ui.clock + COLLISION_DAMAGE_WINDOW
end)

-- Damage read from the car (see the tow and repair keys)
local function readDamage(car)
  local body, suspension = 0, 0
  for i = 0, 4 do body = body + math.max(tonumber(car.damage[i]) or 0, 0) end
  for i = 0, 3 do suspension = suspension + math.max(tonumber(car.suspensionDamage[i]) or 0, 0) end
  return {
    engine = math.min(math.max(1 - (tonumber(car.engineLifeLeft) or 1000) / 1000, 0), 1),
    gearbox = math.max(tonumber(car.gearboxDamage) or 0, 0),
    suspension = suspension,
    body = body,
  }
end

-- Adds the collision damage of this frame (only inside the window after a collision)
local function updateCollisionDamage(car)
  local tw = state.tow
  local cur = readDamage(car)
  local prev = tw.lastRead
  tw.lastRead = cur
  if not prev or state.ui.clock > tw.collisionUntil then return end
  local d = tw.damage or { powertrain = 0, suspension = 0, body = 0 }
  d.powertrain = d.powertrain + math.max(cur.engine - prev.engine, cur.gearbox - prev.gearbox, 0)
  d.suspension = d.suspension + math.max(cur.suspension - prev.suspension, 0)
  d.body = d.body + math.max(cur.body - prev.body, 0)
  tw.damage = d
end

local function repairSeconds(d)
  local t = config.tow
  if not d then return 0 end
  local s = t.factor * (t.base * (t.wEngine * d.powertrain + t.wSuspension * d.suspension) + t.wBody * d.body)
  return math.max(math.floor(s + 0.5), 0)
end

-- Tow and repair hold (race only). The drive-throughs stay in the table and go back to the game after the hold.
local function applyTowHold(tow, damage, reason)
  local repair = repairSeconds(damage)
  local seconds = tow + repair
  state.tow.repairDone = true
  -- The car leaves the hold repaired: collision damage counted from zero again
  state.tow.damage = nil
  if seconds <= 0 then return end
  local text = tow > 0 and string.format('Tow %s + Repair %s', mmss(tow), mmss(repair))
    or string.format('Repair %s', mmss(repair))
  startHold(seconds, text)
  local d = damage or { powertrain = 0, suspension = 0, body = 0 }
  ac.log(string.format('race-control: tow hold %d s (tow %d, repair %d; collision damage: powertrain %.3f'
    .. ' suspension %.3f body %.1f km/h)', seconds, tow, repair, d.powertrain, d.suspension, d.body))
  rcLog(string.format('Hold %d s', seconds), string.format('%s - tow %d s + repair %d s', reason, tow, repair))
end

-- Rule 6: DT0 unpaid when the lap ends. The DSQ is applied by the script; only the black flag remains in the game.
local function applyExpiredDSQ(expired, viaPit)
  clearGamePenalty()
  physics.setCarPenalty(BLACK_FLAG)
  state.list.wrote = true
  local cats = {}
  for _, it in ipairs(expired) do cats[#cats + 1] = it.cat end
  state.dtDsqActive = true
  Rules.zero()
  ac.log(string.format('race-control: DSQ for unpaid DT0 (%s), lap completed %s',
    table.concat(cats, ','), viaPit and 'via pit' or 'on track'))
  rcLog('Disqualified', 'Drive-through not served')
end

-- After any list change: rule 3 (order), rule 5 (two DT0 = hold; during CODE-80 it waits for the green flag)
-- and saving
function Rules.finalize()
  listSort()
  local dt0 = pendingDT0()
  if #dt0 >= 2 and not state.code80 then
    applyHold(hasLongHold(dt0))
    return
  end
  listSave()
end

-- Slowdown unpaid mid-lap, outside the pits: DT0 of the current lap
function Rules.slowdownMidLap(cat)
  listAdd(cat, 0)
  Rules.finalize()
end

-- Slowdown unpaid at the end of the lap, or with the deadline expired inside the pits: DT0 of the next lap,
-- enters the list at the line crossing (rule 4)
function Rules.slowdownEndOfLap(cat)
  local l = state.list
  l.endOfLap[#l.endOfLap + 1] = cat
end

-- DT active in the game: the drive-through is written with MandatoryPits, but the game reports it as
-- currentPenaltyType = GAME_DT with the parameter in laps; once served the parameter goes to 0 (2/N -> 2/0).
local function gameHasDT(gs)
  return gs.t == GAME_DT and gs.p > 0
end

-- Compares the game with the table. Called only at events: before the line, after the line on track,
-- at pit exit and before the script writes to the game.
--   game without DT: nothing is being paid and the DT sent is no longer in the game (goes back via tick if still listed)
--   game with the DT sent or the DT being paid (same or lower parameter, lowered by the game at the line): nothing changes
--   game with another DT: pit speeding (PAC), with the game's deadline
-- lapsLost: laps the PAC already lost at the line before showing up in the game. Received while another DT was
-- being paid, the game only shows it after the line; since it was received in the pass, it loses that line's lap (rule 2).
function Rules.sync(gs, where, lapsLost)
  local l = state.list
  if state.dtDsqActive or state.pitDsqActive then return false end
  if not gameHasDT(gs) then
    l.paying = nil
    l.inGameItem = nil
    return false
  end
  -- Same DT: the game only lowers the parameter (at the line). A new DT is a parameter that goes up.
  if l.inGameItem and gs.p <= l.written then
    l.written = gs.p
    return false
  end
  if l.paying and gs.p <= l.paying then return false end
  local before = listDump()
  l.inGameItem = listAdd('PAC', math.max(gs.p - 1 - (lapsLost or 0), 0))
  l.written = gs.p
  ac.log(string.format('race-control: PAC %s game=%d/%d before=%s after=%s', where, gs.t, gs.p, before,
    listDump()))
  rcLog('Drive-through', TEXTS.reason.PAC)
  return true
end

-- Line crossing. prev = game before the line (last processed frame); g = game after the line.
-- Before = the table with what the game showed before the line; after = the table after the rules,
-- compared with the game after the line. No writes to the game, except the hold and the deadline DSQ.
function Rules.line(viaPit, prev, g, lapCount)
  local l = state.list
  if g.t == BLACK_FLAG then
    Rules.zero()
    return
  end
  -- Before: a game DT the table does not have yet enters with the lap being completed
  Rules.sync(prev, 'before line')
  local before = listDump()
  l.curLap = lapCount
  -- CODE-80 with frozen deadlines: no lap is taken and nobody is disqualified at this line
  local frozen = state.code80 ~= nil and config.code80Freeze
  if viaPit then
    -- Rule 3: the pit pass serves one DT, position 0 (DT0 before DT1; same deadline, the oldest first).
    -- The game clears the DT it shows at the end of the pass: until then, that parameter is the DT being paid.
    -- After a teleport there is no pit pass: nothing is paid. During CODE-80 nothing is paid either: the game still
    -- clears its DT, and position 0 goes back to the game at the pit exit.
    if state.code80 and l.items[1] then
      ac.log('race-control: pit pass during CODE-80, nothing paid')
    elseif not l.jumped then
      if l.inGameItem then l.paying = l.written end
      if l.items[1] then listRemove(l.items[1]) end
    end
  elseif not frozen then
    -- Rule 6 / condition 9: DT0 pending when crossing on track (the end-of-lap SD is not in the table yet)
    local completedLap = l.curLap - 1
    local expired = {}
    for _, it in ipairs(l.items) do
      if it.expireLap <= completedLap then expired[#expired + 1] = it end
    end
    if #expired > 0 then
      applyExpiredDSQ(expired, false)
      return
    end
  end
  -- Rule 2: every DT loses one lap (frozen by CODE-80: the expire lap moves one lap instead)
  for _, it in ipairs(l.items) do
    if frozen then
      it.expireLap = it.expireLap + 1
    else
      it.laps = it.laps - 1
      if it.cat == 'PAC' and it.laps == 0 and not viaPit then it.dt0OnTrack = true end
    end
  end
  -- Rule 4: end-of-lap slowdowns enter as DT0 of the next lap
  for _, cat in ipairs(l.endOfLap) do
    listAdd(cat, 0)
  end
  l.endOfLap = {}
  -- After: on track, the game after the line against the table. Via pit, the comparison is at pit exit,
  -- when the pass has ended (if the exit fell in this same frame, it is done here)
  if not viaPit then
    Rules.sync(g, 'after line')
  elseif not l.inPitNow then
    local paid = l.paying ~= nil
    l.paying = nil
    Rules.sync(g, 'pit exit', paid and 1 or 0)
  end
  ac.log(string.format('race-control: line %s game before=%d/%d after=%d/%d table before=%s after=%s',
    viaPit and 'pit' or 'track', prev.t, prev.p, g.t, g.p, before, listDump()))
  Rules.finalize()
end

-- Session start or script reload: sync with the game
function Rules.sessionSync(g)
  local l = state.list
  listLoad()
  l.paying = nil
  if gameHasDT(g) then
    if #l.items == 0 then l.inGameItem = listAdd('PAC', math.max(g.p - 1, 0)) end
    if not l.inGameItem then l.inGameItem = l.items[1] end
    l.written = g.p
  else
    l.inGameItem = nil
  end
  Rules.finalize()
end

-- Keeps position 0 in the game: outside the pit lane and outside the line crossing frame.
-- After a teleport also inside the pits: the game drops the DT, but the penalty is still in the table,
-- so it goes back to the game at once (the alert stays on screen).
-- Before writing, a game DT the table does not explain enters the table (it is never overwritten).
function Rules.tick(inPit, lineFrame, g)
  local l = state.list
  if state.hold or lineFrame or (inPit and not l.jumped) then return end
  local head = l.items[1]
  if not head then return end
  if l.inGameItem == head then
    if not (l.jumped and not gameHasDT(g)) then return end
  elseif Rules.sync(g, 'before write') then
    Rules.finalize()
    head = l.items[1]
    if not head or l.inGameItem == head then return end
  end
  -- One lap more than the rule in the game: the game disqualifies by itself a drive-through with 1 lap left that
  -- crosses the line unpaid, and labels it "jump start" (setCarPenalty has no reason; log 25/09 06:54). With one lap
  -- more, the game never gets there and the DSQ is always this script's (rule 6), with its own message. The game
  -- alert shows one lap more than the Race Control panel; the panel is the reference.
  l.written = math.max(head.laps, 0) + 2
  physics.setCarPenalty(MANDATORY_PITS, l.written)
  l.wrote = true
  l.inGameItem = head
  listSave()
end

-- ============================================================
-- Slowdown (one per zone)
-- ============================================================

-- Overlap: a new slowdown while another is active adds the times into a single slowdown (what is left of the
-- previous one plus the new one), with the newest deadline. Both are paid or neither; never both at the same time.
local function startSlowdown(zone, r, lapCount)
  local toPay = math.max(r.param, 0)
  local cats = {}
  for cat, sd in pairs(state.slowdowns) do
    if sd.active then
      toPay = toPay + sd.toPay
      for _, c in ipairs(sd.cats) do cats[#cats + 1] = c end
    end
    state.slowdowns[cat] = nil
  end
  cats[#cats + 1] = zone.category
  state.slowdowns[zone.category] = {
    active = true,
    toPay = toPay,
    deadlineLeft = zone.deadline,
    maxGas = zone.maxGas,
    startLap = lapCount,
    title = TEXTS.sdTitle,
    cats = cats,          -- categories added into this slowdown; each becomes its own DT0 if unpaid
  }
end

local function applyDirectDSQ(reason)
  clearGamePenalty()
  physics.setCarPenalty(BLACK_FLAG)
  state.list.wrote = true
  Rules.zero()
  rcLog('Disqualified', reason)
end

-- Unpaid slowdown: rule set per session (DT -> DT0 of the category; DSQ -> direct)
local function onSlowdownUnpaid(cat, endOfLap, inPit)
  local unpaid = config.unpaid[sim.raceSessionType]
  if not unpaid or unpaid.penalty == 'NONE' then return end
  if unpaid.penalty == 'DSQ' then
    applyDirectDSQ(TEXTS.reason[cat] .. ' - slowdown not served')
    return
  end
  if unpaid.penalty ~= 'DT' then return end
  rcLog('Drive-through', TEXTS.reason[cat] .. ' - slowdown not served')
  if endOfLap or inPit then
    -- End of lap, or deadline expired with the car inside the pits (where the payment timer stops):
    -- the DT0 counts for the next lap and enters the list at the line crossing (rule 4)
    Rules.slowdownEndOfLap(cat)
  else
    Rules.slowdownMidLap(cat)
  end
  queueChat(TEXTS.cut.DT)
  ac.log(string.format('race-control: slowdown %s unpaid, end of lap=%s', cat, tostring(endOfLap)))
end

-- Counts down only with throttle <= maxGas and outside the pit lane; deadline: seconds or end of lap.
-- CODE-80: nothing is paid; with frozen deadlines the deadline (seconds and lap) stops too.
local function updateSlowdowns(dt, inPit, lapCount)
  local car = ac.getCar(0)
  local current = state.slowdowns
  if state.code80 then
    for _, sd in pairs(current) do
      if sd.active and config.code80Freeze then sd.startLap = lapCount end
    end
    if config.code80Freeze then return end
  end
  local canPay = not inPit and not state.code80
  for cat, sd in pairs(current) do
    -- A hold or DSQ cleared the list and the slowdowns: nothing else is processed
    if state.slowdowns ~= current then return end
    if sd.active then
      local finished = false
      if car.gas <= sd.maxGas and canPay then
        sd.toPay = sd.toPay - dt
        if sd.toPay <= 0 then
          sd.active = false
          finished = true
        end
      end
      if not finished then
        sd.deadlineLeft = sd.deadlineLeft - dt
        -- Deadline expired before the line is penalized, even if the line falls in the same processed frame
        local endOfLap = nil
        if sd.deadlineLeft <= 0 then
          endOfLap = false
        elseif lapCount > sd.startLap then
          endOfLap = true
        end
        if endOfLap ~= nil then
          sd.active = false
          for _, c in ipairs(sd.cats) do
            if state.slowdowns ~= current then return end
            onSlowdownUnpaid(c, endOfLap, inPit)
          end
        end
      end
    end
  end
end

-- ============================================================
-- Detection
-- ============================================================

local function applyKMR(car, r)
  if r.penalty == 'DSQ' then
    queueChat(string.format('/kmr player_kick %d', car.sessionID))
  end
end

local function onPitViolation(car, r)
  if r.penalty ~= 'DSQ' then return end
  if config.mode == 'CSP' then
    applyDirectDSQ('Pit exit with session closed')
    state.pitDsqActive = true
    queueChat(TEXTS.pit.DSQ)
  elseif config.isRaceControl then
    applyKMR(car, r)
  end
  ac.log(string.format('race-control: pit car.index=%d sessionID=%d DSQ', car.index, car.sessionID))
end

local function checkPitExit(i, closed, r)
  local car = ac.getCar(i)
  if not car or not car.isConnected then
    state.prevInPitlane[i] = nil
    return
  end
  local inPitlane = car.isInPitlane
  local was = state.prevInPitlane[i]
  state.prevInPitlane[i] = inPitlane
  -- Transition inside -> outside the pit lane with the pit closed. The first frame only records the state.
  if was == true and inPitlane == false and closed then
    onPitViolation(car, r)
  end
end

-- ============================================================
-- Gain filter for the slowdown
-- Reference: the driver's own best clean passage through the zone in this session (same car, same moment), as the
-- time taken to reach GAIN_SAMPLES + 1 evenly spaced points of the zone. A passage with a cut never becomes the
-- reference. Cut with a reference: the slowdown is given only if, when the car is back on track (or the zone ends),
-- the time taken is below the reference at that point x (1 + tolerance). A spin during the cut discards it.
-- Cut without a reference yet: the slowdown is given, as before.
-- ============================================================

local GAIN_SAMPLES = 20
local SPIN_MIN_SPEED_KMH = 5

-- Position inside the zone, 0 at the start and 1 at the end (zones may cross the line)
local function zoneProgress(zone, pos)
  local len = (zone.endPos - zone.startPos) % 1
  if len <= 0 then return 0 end
  return ((pos - zone.startPos) % 1) / len
end

-- Reference time (ms) to reach position p of the zone
local function refAt(ref, p)
  local x = math.min(math.max(p, 0), 1) * GAIN_SAMPLES
  local i = math.floor(x)
  if i >= GAIN_SAMPLES then return ref[GAIN_SAMPLES] end
  return ref[i] + (ref[i + 1] - ref[i]) * (x - i)
end

-- Angle between where the car points and where it moves, in degrees (0 = straight, 180 = backwards)
local function driftAngle(car)
  local v = car.localVelocity
  local speed = math.sqrt(v.x * v.x + v.z * v.z)
  if speed <= 0 then return 0 end
  return math.deg(math.acos(math.min(math.max(v.z / speed, -1), 1)))
end

-- Records the passage through each zone; a clean, complete and faster passage becomes the reference
local function updateZonePassages()
  local car = ac.getCar(0)
  local now = sim.time
  for zi, zone in ipairs(config.cutZones) do
    local pass = state.zonePass[zi]
    if zone.enabled then
      local inZone = not car.isInPitlane and isInZone(zone, car.splinePosition)
      if inZone and not pass then
        pass = { t0 = now, samples = { [0] = 0 }, nextIdx = 1, dirty = false }
        state.zonePass[zi] = pass
      end
      if pass then
        if car.isInPitlane then
          state.zonePass[zi] = nil
        else
          local p = inZone and zoneProgress(zone, car.splinePosition) or 1
          local pos = car.splinePosition
          if not inZone and (zone.startPos - pos) % 1 < (pos - zone.endPos) % 1 then
            -- left the zone backwards (through its start): passage void
            state.zonePass[zi] = nil
          else
            while pass.nextIdx <= GAIN_SAMPLES and p >= pass.nextIdx / GAIN_SAMPLES do
              pass.samples[pass.nextIdx] = now - pass.t0
              pass.nextIdx = pass.nextIdx + 1
            end
            if car.wheelsOutside > zone.maxWheelsOut then pass.dirty = true end
            if not inZone then
              state.zonePass[zi] = nil
              if not pass.dirty and pass.nextIdx > GAIN_SAMPLES then
                local ref = state.zoneRef[zi]
                if not ref or pass.samples[GAIN_SAMPLES] < ref[GAIN_SAMPLES] then
                  state.zoneRef[zi] = pass.samples
                  ac.log(string.format('race-control: %s reference %.3f s', zone.category,
                    pass.samples[GAIN_SAMPLES] / 1000))
                end
              end
            end
          end
        end
      end
    end
  end
end

-- Cut with a reference: follows the gain until the car is back on track or the zone ends, then decides
local function updateCutChecks()
  local car = ac.getCar(0)
  for zi, cc in pairs(state.cutChecks) do
    local zone = cc.zone
    local inZone = isInZone(zone, car.splinePosition)
    local p = inZone and zoneProgress(zone, car.splinePosition) or 1
    local elapsed = sim.time - cc.t0
    local limit = refAt(cc.ref, p) * (1 + zone.gainTolerance / 100)
    cc.margin = limit > 0 and (elapsed / limit - 1) or 0
    if car.speedKmh > SPIN_MIN_SPEED_KMH and driftAngle(car) > config.cutSpinAngle then cc.spun = true end
    local back = car.wheelsOutside <= zone.maxWheelsOut
    if car.isInPitlane then
      state.cutChecks[zi] = nil
    elseif back or not inZone then
      state.cutChecks[zi] = nil
      if cc.spun then
        ac.log(string.format('race-control: cut %s discarded: spin', zone.category))
      elseif elapsed >= limit then
        ac.log(string.format('race-control: cut %s discarded: %.3f s, limit %.3f s', zone.category,
          elapsed / 1000, limit / 1000))
      else
        ac.log(string.format('race-control: cut %s gained: %.3f s, limit %.3f s', zone.category,
          elapsed / 1000, limit / 1000))
        startSlowdown(zone, cc.rule, cc.lapCount)
        queueChat(TEXTS.cut.SLOWDOWN)
      end
    end
  end
end

local function checkCutZone(zoneIndex, zone, lapCount)
  if not zone.enabled then return end
  local r = zone.rules[sim.raceSessionType]
  if not r or r.penalty == 'NONE' then return end
  local car = ac.getCar(0)
  if not car or car.isInPitlane or not isInZone(zone, car.splinePosition) then
    state.cutPassPenalized[zoneIndex] = false
    return
  end
  if not state.cutPassPenalized[zoneIndex] and car.wheelsOutside > zone.maxWheelsOut then
    state.cutPassPenalized[zoneIndex] = true
    local ref = state.zoneRef[zoneIndex]
    local pass = state.zonePass[zoneIndex]
    if r.penalty == 'SLOWDOWN' and ref and pass then
      -- Reference available: the gain decides when the car is back on track
      state.cutChecks[zoneIndex] = { zone = zone, rule = r, lapCount = lapCount, t0 = pass.t0, ref = ref,
        margin = 0, spun = false }
    elseif r.penalty == 'SLOWDOWN' then
      startSlowdown(zone, r, lapCount)
      queueChat(TEXTS.cut.SLOWDOWN)
    elseif r.penalty == 'DT' then
      rcLog('Drive-through', TEXTS.reason[zone.category])
      if car.isInPitlane then Rules.slowdownEndOfLap(zone.category) else Rules.slowdownMidLap(zone.category) end
      queueChat(TEXTS.cut.DT)
    elseif r.penalty == 'DSQ' then
      applyDirectDSQ(TEXTS.reason[zone.category])
      queueChat(TEXTS.cut.DSQ)
    end
    ac.log(string.format('race-control: cut %s spline=%.4f wheelsOut=%d penalty=%s',
      zone.category, car.splinePosition, car.wheelsOutside, r.penalty))
  end
end

-- ============================================================
-- Penalty message box helpers
-- ============================================================

local BORDER_BASE = rgbm(0.78, 0.78, 0.78, 1)
local BORDER_YELLOW = rgbm(1, 0.85, 0, 1)
local BORDER_BLUE = rgbm(0.2, 0.45, 1, 1)
local BORDER_GREEN = rgbm(0.2, 0.8, 0.3, 1)
local BLINK_SECONDS = 0.5
local PIT_DONE_KEY = 'race-control.pitdone'

local function listHas(item)
  for _, it in ipairs(state.list.items) do
    if it == item then return true end
  end
  return false
end

-- Priority = laps left to serve it (DT0 = this lap)
local function itemPriority(it)
  return string.format('DT%d', math.max(it.laps, 0))
end

local function itemText(it)
  return string.format('%s - Drive-through - %s', itemPriority(it), TEXTS.reason[it.cat] or it.cat)
end

local BORDER_RED = rgbm(1, 0.3, 0.3, 1)

-- Seconds as mm:ss (fixed width: "00:00")
local function mmss2(seconds)
  local v = math.max(math.floor(seconds + 0.5), 0)
  return string.format('%02d:%02d', math.min(math.floor(v / 60), 99), v % 60)
end

-- ============================================================
-- Race Control panel
-- Works like the dashboard of a car: every cell has a fixed place. With nothing to show, the cell title is dark and
-- the value is off; with something to show, the title is gray and the value lights up in its color.
-- Each cell is its own function, reads only its own state and changes nothing (safe to call any number of times).
-- Shared by the whole panel: the message line and the frame color.
-- A cell returns nil (off) or { value = text, color = key of PANEL_COLORS }.
-- ============================================================

local Panel = {}

-- PIT WINDOW: mandatory pit window from the server (RACE_PIT_WINDOW_START/END). The game tells the window but not
-- whether the stop was made, so this cell keeps its own record: car parked at its pit place inside the window.
function Panel.updatePit(car)
  local startT, endT = sim.pitWindowStartTime or 0, sim.pitWindowEndTime or 0
  if startT > 0 and endT > startT and sim.time >= startT and sim.time <= endT and car.isInPit and not state.pit.done then
    state.pit.done = true
    ac.store(PIT_DONE_KEY, sim.currentSessionIndex)
    ac.log('race-control: mandatory pit stop done')
  end
end

function Panel.cellPit()
  local startT, endT = sim.pitWindowStartTime or 0, sim.pitWindowEndTime or 0
  if startT <= 0 or endT <= startT or sim.time < startT then return nil end
  if state.pit.done then return { value = TEXTS.pitDone, color = 'dim' } end
  if sim.time <= endT then return { value = string.format(TEXTS.pitOpen, mmss2((endT - sim.time) / 1000)), color = 'yellow' } end
  return { value = TEXTS.pitMissed, color = 'red' }
end

-- SWAP: driver swaps, done | required (0 required = swaps allowed, none mandatory). Off when driver swaps are disabled
-- or the required number is not informed. Gray during the race; lit only inside the pit lane (the countdown, WAIT and
-- GO stay in the driver swap panel).
function Panel.cellSwap()
  if not config.swapEnabled or config.swapRequired == nil or sim.raceSessionType ~= ac.SessionType.Race then
    return nil
  end
  local lit = ac.getCar(0).isInPitlane
  return { value = string.format(TEXTS.swapCount, state.swap.count, config.swapRequired), color = lit and 'green' or 'dim' }
end

-- TRACK: CODE-80 (VSC / SC / CODE-80) or the flag shown to the driver
function Panel.cellTrack()
  if state.code80 then return { value = state.code80, color = 'yellow' } end
  local flag = sim.raceFlagType
  if flag == ac.FlagType.Caution then return { value = TEXTS.trackYellow, color = 'yellow' } end
  if flag == ac.FlagType.FasterCar then return { value = TEXTS.trackBlue, color = 'blue' } end
  return nil
end

-- PENALTIES: DSQ, hold, or the first two drive-throughs with origin and deadline ("SD1 DT0 · PAC DT1 +1")
function Panel.cellPenalties()
  if state.dtDsqActive or state.pitDsqActive then return { value = TEXTS.penDsq, color = 'red' } end
  if state.hold then return { value = TEXTS.penHold, color = 'red' } end
  local items = state.list.items
  if #items == 0 then return nil end
  local parts = {}
  for i = 1, math.min(#items, 2) do parts[#parts + 1] = items[i].cat .. ' ' .. itemPriority(items[i]) end
  local text = table.concat(parts, ' · ')
  if #items > 2 then text = text .. string.format(' +%d', #items - 2) end
  return { value = text, color = 'yellow' }
end

-- Shared: message line. A new penalty or a server message is shown for a few seconds; otherwise the most important
-- thing now: hold, penalty being paid, CODE-80, open pit window.
function Panel.message()
  local notice = state.ui.notice
  if notice then return notice.text, 'yellow' end
  if state.hold then
    return string.format(TEXTS.hold, mmss(state.hold.untilT - state.ui.clock), state.hold.text), 'red'
  end
  local items = state.list.items
  if items[1] then return itemText(items[1]), 'yellow' end
  if state.code80 then return TEXTS.code80, 'yellow' end
  local pit = Panel.cellPit()
  if pit and not state.pit.done and pit.color == 'yellow' then return TEXTS.pitOpenMsg, 'yellow' end
  return nil
end

-- Shared: frame color. Red with a hold or DSQ; fixed yellow during CODE-80; green for the green flag message;
-- yellow / blue flag: blinks in the flag color (back to light gray when the blink is off).
function Panel.frameColor()
  if state.hold or state.dtDsqActive or state.pitDsqActive then return BORDER_RED end
  local notice = state.ui.notice
  local nflag = notice and notice.flag
  if state.code80 or CODE80_KINDS[nflag] then return BORDER_YELLOW end
  if nflag == 'GREEN FLAG' then return BORDER_GREEN end
  local on = math.floor(state.ui.clock / BLINK_SECONDS) % 2 == 0
  local flag = sim.raceFlagType
  if on and flag == ac.FlagType.Caution then return BORDER_YELLOW end
  if on and flag == ac.FlagType.FasterCar then return BORDER_BLUE end
  return BORDER_BASE
end

-- Panel cells, left to right: title, function, alignment and the widest value the cell can show. A cell is never
-- narrower than its widest value (nothing is ever cut); PENALTIES takes the rest of the fixed width.
local PANEL_CELLS = {
  { title = nil, fn = function() return { value = TEXTS.rcTitle, color = 'title' } end, widest = TEXTS.rcTitle },
  { title = TEXTS.cellPit, fn = Panel.cellPit, center = true, widest = string.format(TEXTS.pitOpen, '00:00') },
  { title = TEXTS.cellSwap, fn = Panel.cellSwap, center = true, widest = string.format(TEXTS.swapCount, 88, 88) },
  { title = TEXTS.cellTrack, fn = Panel.cellTrack, center = true, widest = 'CODE-80' },
  { title = TEXTS.cellPenalties, fn = Panel.cellPenalties },
}
-- Fixed width of the Race Control panel at 1080p. Widest texts measured with Segoe UI Bold (cell = text + 16 px):
-- RACE CONTROL 112 (15 px), OPEN 00:00 71, 88 | 88 40, CODE-80 54, PENALTIES "PAC DT1 · PAC DT1 +9" 140 (13 px):
-- 128 + 87 + 56 + 70 + 156 = 497 px, plus 20 px of borders = 517 px
local PANEL_WIDTH = 520

-- ============================================================
-- Callbacks
-- ============================================================

-- Box style: Segoe UI (bold titles, semibold text, Consolas for the times), soft shadow, dark gradient,
-- thin border, colored bar on the left, separator under the title; coordinates on whole pixels
local FONT_TITLE = 'Segoe UI;Weight=Bold'
local FONT_TEXT = 'Segoe UI;Weight=SemiBold'
local FONT_MONO = 'Consolas'
local COLOR_TITLE = rgbm(0.96, 0.96, 0.96, 1)
local COLOR_TEXT = rgbm(1, 0.85, 0.25, 1)
local COLOR_SWAP = rgbm(0.45, 1, 0.55, 1)
local COLOR_LIFT_FAST = rgbm(1, 0.3, 0.3, 0.45)
local COLOR_LIFT_SLOW = rgbm(0.2, 0.8, 0.3, 0.35)
local COLOR_DIM = rgbm(0.6, 0.63, 0.65, 1)
-- Race Control panel: dark title of a cell with nothing to show; value colors
local COLOR_CELL_OFF = rgbm(0.23, 0.25, 0.27, 1)
-- Frame of the panel with nothing to show at all
local COLOR_PANEL_OFF = rgbm(0.23, 0.25, 0.27, 1)
local PANEL_COLORS = {
  title = rgbm(0.96, 0.96, 0.96, 1), dim = rgbm(0.6, 0.63, 0.65, 1), yellow = rgbm(1, 0.85, 0.25, 1),
  red = rgbm(1, 0.3, 0.3, 1), blue = rgbm(0.56, 0.7, 1, 1), green = rgbm(0.45, 1, 0.55, 1),
}
-- Gain meter: position of the limit line and how much margin (fraction of the limit) spans from it to the edge
local LIFT_LIMIT_POS = 0.55
local LIFT_SCALE = 4.5

local function px(v) return math.floor(v + 0.5) end

local function drawText(text, font, size, pos, color)
  ui.pushDWriteFont(font)
  ui.dwriteDrawText(text, size, vec2(px(pos.x), px(pos.y)), color)
  ui.popDWriteFont()
end

local function drawPanel(p1, p2, border, s)
  local r = px(8 * s)
  local o = px(3 * s)
  ui.drawRectFilled(vec2(p1.x + o, p1.y + o), vec2(p2.x + o, p2.y + o), rgbm(0, 0, 0, 0.35), r)
  ui.drawRectFilled(p1, p2, rgbm(0.04, 0.04, 0.05, 0.9), r)
  local i = px(4 * s)
  ui.drawRectFilledMultiColor(vec2(p1.x + i, p1.y + i), vec2(p2.x - i, p2.y - i),
    rgbm(1, 1, 1, 0.06), rgbm(1, 1, 1, 0.06), rgbm(1, 1, 1, 0), rgbm(1, 1, 1, 0))
  ui.drawRectFilled(vec2(p1.x + px(3 * s), p1.y + px(8 * s)), vec2(p1.x + px(7 * s), p2.y - px(8 * s)), border,
    px(2 * s))
  ui.drawRect(p1, p2, border, r, nil, 1.5 * s)
end

local function drawSeparator(p1, p2, y, s)
  ui.drawSimpleLine(vec2(p1.x + px(16 * s), px(y)), vec2(p2.x - px(16 * s), px(y)), rgbm(1, 1, 1, 0.12), 1)
end

-- Text right-aligned at xRight
local function drawTextRight(text, font, size, xRight, y, color)
  ui.pushDWriteFont(font)
  local tw = ui.measureDWriteText(text, size).x
  ui.dwriteDrawText(text, size, vec2(px(xRight - tw), px(y)), color)
  ui.popDWriteFont()
end

function script.drawUI()
  local size = ac.getUI().windowSize
  local w = size.x
  local h = size.y

  local dsqText = state.pitDsqActive and TEXTS.pitDsq or (state.dtDsqActive and TEXTS.dtDsq) or nil
  if dsqText then
    -- Same style as the native AC message: one line, centered on screen, red with a dark outline
    local scale = h / 1080
    local fontSize = 26 * scale
    ui.pushDWriteFont('Segoe UI;Weight=Bold')
    local textSize = ui.measureDWriteText(dsqText, fontSize)
    local pos = vec2(w * 0.5 - textSize.x * 0.5, h * 0.5 + 7 * scale - textSize.y * 0.5)
    local outline = rgbm(0.1, 0, 0, 1)
    local o = 1.5 * scale
    ui.dwriteDrawText(dsqText, fontSize, pos + vec2(-o, 0), outline)
    ui.dwriteDrawText(dsqText, fontSize, pos + vec2(o, 0), outline)
    ui.dwriteDrawText(dsqText, fontSize, pos + vec2(0, -o), outline)
    ui.dwriteDrawText(dsqText, fontSize, pos + vec2(0, o), outline)
    ui.dwriteDrawText(dsqText, fontSize, pos, rgbm(0.9, 0, 0, 1))
    ui.popDWriteFont()
  end

  -- Fixed layout: Race Control panel on top (always shown), slowdown box right below it, driver swap panel below.
  -- Legibility correction only (no proportional scaling): sizes grow with the resolution to the power 0.3, from 1x
  -- at 1080p up to 1.3x (1.23x at 4K), so on a big screen the boxes are bigger but take a smaller part of it.
  local s = math.min(math.max((h / 1080) ^ 0.3, 1), 1.3)
  -- Race Control panel cell widths: measured from their widest text, so no text is cut (the panel width is fixed)
  local function textW(text, size)
    ui.pushDWriteFont(FONT_TITLE)
    local tw = ui.measureDWriteText(text, size).x
    ui.popDWriteFont()
    return tw
  end
  local cellW, fixedW = {}, 0
  for i, c in ipairs(PANEL_CELLS) do
    if c.widest then
      local vw = textW(c.widest, (c.title and 13 or 15) * s)
      local tw = c.title and textW(c.title, 10 * s) or 0
      cellW[i] = math.ceil(math.max(vw, tw) + 16 * s)
      fixedW = fixedW + cellW[i]
    end
  end
  local boxW = math.floor(PANEL_WIDTH * s)
  local msgH, sdH = math.floor(66 * s), math.floor(56 * s)
  local gap = math.floor(6 * s)
  local x = math.floor(w * 0.5 - boxW * 0.5)
  -- 10 px lower than 18% of the height: clear of the AC virtual mirror
  local yMsg = math.floor(h * 0.18 + 10 * s)
  local ySd = yMsg + msgH + gap

  -- Notice timing (new penalty / server message): ends after its time or when its penalty leaves the list
  local notice = state.ui.notice
  if notice and (state.ui.clock >= notice.untilT or (notice.item and not listHas(notice.item))) then
    state.ui.notice = nil
  end

  do
    local p1 = vec2(x, yMsg)
    local p2 = vec2(x + boxW, yMsg + msgH)
    -- Cells and message first: with nothing to show anywhere, the RACE CONTROL title and the frame are off too
    local values, anyOn = {}, false
    for i, c in ipairs(PANEL_CELLS) do
      values[i] = c.fn()
      if c.title and values[i] then anyOn = true end
    end
    local text, color = Panel.message()
    local idle = not anyOn and not text
    drawPanel(p1, p2, idle and COLOR_PANEL_OFF or Panel.frameColor(), s)
    local cx = p1.x + 12 * s
    local innerW = boxW - 20 * s
    for i, c in ipairs(PANEL_CELLS) do
      local cw = cellW[i] or (innerW - fixedW)
      if i > 1 then
        ui.drawSimpleLine(vec2(px(cx), px(p1.y + 6 * s)), vec2(px(cx), px(p1.y + 32 * s)), rgbm(1, 1, 1, 0.12), 1)
      end
      local cell = values[i]
      local function put(text, font, size, y, color)
        ui.pushDWriteFont(font)
        local tw = ui.measureDWriteText(text, size).x
        local tx = c.center and (cx + (cw - tw) / 2) or (cx + 6 * s)
        ui.dwriteDrawText(text, size, vec2(px(tx), px(y)), color)
        ui.popDWriteFont()
      end
      if c.title then
        put(c.title, FONT_TITLE, 10 * s, p1.y + 5 * s, cell and PANEL_COLORS.dim or COLOR_CELL_OFF)
        if cell then put(cell.value, FONT_TITLE, 13 * s, p1.y + 17 * s, PANEL_COLORS[cell.color]) end
      elseif cell then
        put(cell.value, FONT_TITLE, 15 * s, p1.y + 10 * s, idle and COLOR_CELL_OFF or PANEL_COLORS[cell.color])
      end
      cx = cx + cw
    end
    drawSeparator(p1, p2, p1.y + 36 * s, s)
    if text then
      ui.pushDWriteFont(FONT_TEXT)
      ui.setCursor(vec2(math.floor(p1.x + 16 * s), math.floor(p1.y + 41 * s)))
      ui.dwriteTextAligned(text, 14 * s, ui.Alignment.Start, ui.Alignment.Start,
        vec2(boxW - 32 * s, msgH - 43 * s), true, PANEL_COLORS[color])
      ui.popDWriteFont()
    end
  end

  -- Gain check box (cut with a reference), in the place of the slowdown box, same size. The bar is the time
  -- advantage still left over the reference x (1 + tolerance): red while the car is faster than allowed, empty when
  -- slower. It only disappears when the car is back on track (never in the middle, so it does not blink).
  local cc
  for _, check in pairs(state.cutChecks) do cc = check end
  if cc then
    local p1 = vec2(x, ySd)
    local p2 = vec2(x + boxW, ySd + sdH)
    drawPanel(p1, p2, BORDER_YELLOW, s)
    drawText(TEXTS.liftTitle, FONT_TITLE, 14 * s, vec2(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + 24 * s, s)
    -- Meter: left of the limit line = slower than reference x (1 + tolerance), no slowdown (green); right = faster,
    -- slowdown (red). The white mark is where the driver is now; +/-10% of the limit spans the whole bar.
    local bx1, bx2 = p1.x + 16 * s, p2.x - 16 * s
    local by1, by2 = p1.y + 30 * s, p1.y + 38 * s
    local lim = bx1 + (bx2 - bx1) * LIFT_LIMIT_POS
    ui.drawRectFilled(vec2(px(bx1), px(by1)), vec2(px(lim), px(by2)), COLOR_LIFT_SLOW, px(4 * s))
    ui.drawRectFilled(vec2(px(lim), px(by1)), vec2(px(bx2), px(by2)), COLOR_LIFT_FAST, px(4 * s))
    ui.drawSimpleLine(vec2(px(lim), px(by1 - 2 * s)), vec2(px(lim), px(by2 + 2 * s)), rgbm(1, 1, 1, 0.8), 1)
    local f = math.min(math.max(LIFT_LIMIT_POS - cc.margin * LIFT_SCALE, 0), 1)
    local mx = bx1 + (bx2 - bx1) * f
    ui.drawRectFilled(vec2(px(mx - 1.5 * s), px(by1 - 3 * s)), vec2(px(mx + 1.5 * s), px(by2 + 3 * s)),
      rgbm(1, 1, 1, 1), px(1 * s))
    local ly = p1.y + 41 * s
    drawText(TEXTS.liftSlower, FONT_MONO, 10 * s, vec2(bx1, ly), COLOR_DIM)
    local mid = string.format(TEXTS.liftLimit, cc.zone.gainTolerance)
    ui.pushDWriteFont(FONT_MONO)
    local mw = ui.measureDWriteText(mid, 10 * s).x
    ui.dwriteDrawText(mid, 10 * s, vec2(px(lim - mw / 2), px(ly)), COLOR_DIM)
    ui.popDWriteFont()
    drawTextRight(TEXTS.liftFaster, FONT_MONO, 10 * s, bx2, ly, COLOR_DIM)
  end

  -- Slowdown box (one slowdown at a time; overlapping ones are merged)
  for _, zone in ipairs(config.cutZones) do
    local sd = state.slowdowns[zone.category]
    if not cc and sd and sd.active then
      local timerText = string.format(TEXTS.timer, math.max(sd.toPay, 0), math.max(sd.deadlineLeft, 0))
      local p1 = vec2(x, ySd)
      local p2 = vec2(x + boxW, ySd + sdH)
      drawPanel(p1, p2, BORDER_YELLOW, s)
      drawText(sd.title, FONT_TITLE, 14 * s, vec2(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
      drawSeparator(p1, p2, p1.y + 24 * s, s)
      drawText(timerText, FONT_MONO, 12 * s, vec2(p1.x + 16 * s, p1.y + 29 * s), COLOR_TEXT)
      break
    end
  end

  -- Driver swap panel (green), below the slowdown box
  if config.swapEnabled and sim.raceSessionType == ac.SessionType.Race then
    local sw = state.swap
    local clock = state.ui.clock
    local total = config.swapMinSeconds
    local title, line1, line2
    if sw.clearUntil and clock < sw.clearUntil then
      title, line1 = TEXTS.swapTitle, TEXTS.swapClear
    elseif sw.remaining then
      local left = math.max(sw.remaining - (clock - sw.remainingT), 0)
      title = TEXTS.swapTitle
      line1 = string.format(TEXTS.swapWait, mmss(left))
      line2 = string.format(TEXTS.swapTimes, mmss(math.max(total - left, 0)), mmss(total))
    elseif sw.stopT then
      title, line1 = TEXTS.swapActive, TEXTS.swapDisconnect
      line2 = string.format(TEXTS.swapTimes, mmss(clock - sw.stopT), mmss(total))
    end
    if title then
      local ySwap = ySd + sdH + gap
      local p1 = vec2(x, ySwap)
      local p2 = vec2(x + boxW, ySwap + msgH)
      drawPanel(p1, p2, BORDER_GREEN, s)
      drawText(title, FONT_TITLE, 14 * s, vec2(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
      drawSeparator(p1, p2, p1.y + 24 * s, s)
      drawText(line1, FONT_TEXT, 12 * s, vec2(p1.x + 16 * s, p1.y + 29 * s), COLOR_SWAP)
      if line2 then drawText(line2, FONT_MONO, 12 * s, vec2(p1.x + 16 * s, p1.y + 45 * s), COLOR_TITLE) end
    end
  end
end

-- ============================================================
-- Car controls: cockpit camera forced by the server (key forceCockpit)
-- ============================================================

local CarControls = {
  enabled = tonumber(cfg.forceCockpit) == 1,
  mode = tonumber(cfg.cockpitCameraMode) or 0,
  interval = tonumber(cfg.cockpitCheckInterval) or 0.05,
  exempt = false,
  timer = 0,
}
do
  local me = tostring(ac.getUserSteamID() or '')
  for id in tostring(cfg.cockpitExemptSteamIDs or ''):gmatch('[^;]+') do
    if id:match('^%s*(.-)%s*$') == me and me ~= '' then CarControls.exempt = true end
  end
end

function CarControls.update(dt)
  if not CarControls.enabled or CarControls.exempt then return end
  if sim.isPaused or sim.isReplayActive then return end
  CarControls.timer = CarControls.timer + dt
  if CarControls.timer < CarControls.interval then return end
  CarControls.timer = 0
  ac.setCurrentCamera(CarControls.mode)
end

function script.update(dt)
  local car = ac.getCar(0)
  local l = state.list
  local g = { t = car.currentPenaltyType, p = car.currentPenaltyParameter }
  local inPit = car.isInPitlane
  local lapCount = car.lapCount
  state.ui.clock = state.ui.clock + dt
  CarControls.update(dt)
  if state.hold and state.ui.clock >= state.hold.untilT then state.hold = nil end

  -- Driver swap: the stop at the pit place starts the elapsed time of the driver leaving the car (only a stop seen
  -- by this client: a driver who connects with the car already parked does not get the "disconnect" panel)
  local sw = state.swap
  local parked = car.isInPit
  if sw.prevInPit == false and parked then sw.stopT = state.ui.clock end
  if not parked then sw.stopT = nil end
  if not inPit then sw.remaining = nil end
  sw.prevInPit = parked
  updateSwapRelay()
  publishOwnList(car)
  Panel.updatePit(car)
  -- Penalty list of the previous driver (driver swap): taken over only if this driver has none
  if sw.pendingList then
    local items = sw.pendingList
    sw.pendingList = nil
    if #state.list.items == 0 then
      local parts = {}
      for _, it in ipairs(items) do
        listAdd(it.cat, it.laps)
        parts[#parts + 1] = it.cat .. ' DT' .. it.laps
      end
      ac.log('race-control: swap: penalties of the previous driver taken over: ' .. table.concat(parts, ', '))
      rcLog('Driver swap', 'Pending penalties taken over: ' .. table.concat(parts, ', '))
      state.ui.lastSeq = state.list.seq
      Rules.finalize()
    end
  end
  -- Countdown over (ACSM or estimate): clear to leave, even if the ACSM "clear" message is not received
  if sw.remaining and state.ui.clock - sw.remainingT >= sw.remaining then
    sw.remaining = nil
    sw.clearUntil = state.ui.clock + SERVER_NOTICE_SECONDS
  end
  -- Table lap: only advances after the line crossing is processed
  l.curLap = l.lastLap

  if sim.currentSessionIndex ~= state.lastSessionIndex then
    l.curLap = lapCount
    state.lastSessionIndex = sim.currentSessionIndex
    state.prevInPitlane = {}
    state.cutPassPenalized = {}
    state.zonePass = {}
    state.zoneRef = {}
    state.cutChecks = {}
    state.slowdowns = {}
    state.pitDsqActive = false
    state.dtDsqActive = false
    state.code80 = nil
    state.code80Ended = false
    state.hold = nil
    state.tow.jumpPending = false
    state.tow.repairDone = false
    state.tow.damage = nil
    state.tow.lastRead = nil
    l.endOfLap = {}
    l.lastLap = lapCount
    l.prevInPit = inPit
    l.prevGame = { t = g.t, p = g.p }
    -- Sync with the game on session start or reload
    Rules.sessionSync(g)
    -- Panel records of this session (script reload keeps them)
    state.pit.done = ac.load(PIT_DONE_KEY) == sim.currentSessionIndex
    local swaps = ac.load(SWAP_COUNT_KEY)
    local sess, cnt = tostring(swaps or ''):match('^(%-?%d+)|(%d+)$')
    state.swap.count = tonumber(sess) == sim.currentSessionIndex and tonumber(cnt) or 0
    state.ui.lastSeq = l.seq
    state.ui.notice = nil
  end

  local pitRule = config.pit.rules[sim.raceSessionType]
  if pitRule then
    local closed = isPitClosed()
    if config.mode == 'CSP' then
      checkPitExit(0, closed, pitRule)
    elseif config.isRaceControl then
      for i = 0, sim.carsCount - 1 do
        checkPitExit(i, closed, pitRule)
      end
    end
  end

  if config.mode == 'CSP' then
    l.wrote = false
    -- DSQ in the game: the list is cleared; the script keeps running
    if g.t == BLACK_FLAG and l.prevGame.t ~= BLACK_FLAG then
      Rules.zero()
    end
    local dsqActive = state.dtDsqActive or state.pitDsqActive

    -- Green flag after CODE-80: the hold for two pending DT0 deferred during CODE-80 is applied now
    if state.code80Ended then
      state.code80Ended = false
      if not dsqActive then Rules.finalize() end
    end

    -- Tow and repair hold (race only): collision damage counted outside the pit lane
    local tw = state.tow
    local towOn = sim.raceSessionType == ac.SessionType.Race and (config.tow.seconds > 0 or config.tow.factor > 0)
    local rep = car.isRepairing
    local repairing = rep == true or (type(rep) == 'number' and rep ~= 0)
      or (type(rep) == 'string' and rep ~= '' and rep ~= '0' and rep:lower() ~= 'false')
    if towOn and not dsqActive and not state.hold then
      if tw.jumpPending and inPit then
        applyTowHold(config.tow.seconds, tw.damage, TEXTS.towReason)
      elseif repairing and not tw.prevRepairing and inPit and not tw.repairDone then
        applyTowHold(0, tw.damage, TEXTS.repairReason)
      end
    end
    tw.jumpPending = false
    tw.prevRepairing = repairing
    if not inPit then
      tw.repairDone = false
      if towOn then updateCollisionDamage(car) end
    else
      tw.lastRead = nil
    end

    updateZonePassages()
    for zoneIndex, zone in ipairs(config.cutZones) do
      checkCutZone(zoneIndex, zone, lapCount)
    end
    updateCutChecks()
    updateSlowdowns(dt, inPit, lapCount)

    -- Pit pass, even if the exit falls in the same processed frame
    local viaPit = inPit or l.prevInPit
    l.inPitNow = inPit

    local lineFrame = lapCount > l.lastLap
    if lineFrame then
      Rules.line(viaPit, l.prevGame, g, lapCount)
      l.lastLap = lapCount
    end

    -- Pit exit: the pass has ended; the DT being paid left the game. If there is still a DT the table does not
    -- explain, it is new (PAC). If a DT was being paid, it was received in the pass and lost that line's lap.
    if not inPit and l.prevInPit and not lineFrame and not l.wrote then
      local paid = l.paying ~= nil
      l.paying = nil
      if Rules.sync(g, 'pit exit', paid and 1 or 0) then Rules.finalize() end
    end

    Rules.tick(inPit, lineFrame, g)

    -- New penalty in the table: shown in the message box for a few seconds
    if l.seq > state.ui.lastSeq then
      for _, it in ipairs(l.items) do
        if it.seq == l.seq then showNotice(TEXTS.rcTitle, itemText(it), it) end
      end
      state.ui.lastSeq = l.seq
    end

    -- The teleport ends when the car leaves the pit lane, or at a line crossing on track (reset outside the pits)
    if l.jumped and ((not inPit and l.prevInPit) or (lineFrame and not viaPit)) then l.jumped = false end

    l.prevInPit = inPit
    l.prevGame = { t = g.t, p = g.p }
  end

  updateChat(dt)
end
