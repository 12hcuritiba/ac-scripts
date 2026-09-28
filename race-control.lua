-- race-control.lua — CSP online script (12h Curitiba)
--
-- ============================================================================================================
-- LEGAL NOTICE
--
-- Copyright (c) 2026 12h Curitiba, amx racing, amx mods and Max Schrappe. All rights reserved.
--
-- This software, including its source code, rules logic, texts, layouts and documentation, is the exclusive
-- property of 12h Curitiba, amx racing, amx mods and Max Schrappe. It is proprietary and confidential, and it is
-- NOT open source.
--
-- No license is granted. Without the prior written authorization of the copyright holders, it is prohibited to:
--   - use, run or host this software, in whole or in part, on any server, event or championship other than the
--     ones organized or authorized by 12h Curitiba;
--   - copy, reproduce, modify, adapt, translate or create derivative works from it;
--   - distribute, publish, sell, rent, sublicense or otherwise make it available to third parties;
--   - remove, alter or hide this notice or any other ownership or authorship information.
--
-- Its publication at a public address exists only so that the game clients of the 12h Curitiba servers can
-- download it, and does not grant any right of use, copy or distribution.
--
-- This software is protected by copyright law, including the Brazilian Copyright Law (Lei nº 9.610/1998) and the
-- Brazilian Software Law (Lei nº 9.609/1998), and by international treaties, including the Berne Convention.
-- Unauthorized use, copy or distribution is a copyright infringement and may result in civil and criminal
-- liability, including damages, under the applicable law.
--
-- THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED. IN NO EVENT SHALL THE
-- COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY ARISING FROM ITS USE.
--
-- Authorization requests: 12hcuritiba@gmail.com
-- ============================================================================================================
--
-- Rules: document "Penalty rules — 12h Curitiba".
--   1. DT0 = serve on the lap it was given. DT1 = serve on this lap or the next.
--   2. Every DT loses one lap at each line crossing, including the one received in the pit pass itself.
--   3. Serving order: DT0 before DT1; same deadline, the oldest first. One pit pass serves one DT.
--   4. A slowdown that becomes a DT at the line crossing counts for the next lap.
--   5. Two DT0 pending on the same lap: hold of holdShortSeconds, clears the list. Exception: if one of them is
--      the PSE that became DT0 crossing the line on track: hold of holdLongSeconds, clears the list.
--   6. Crossing the line outside the pits with a DT0 pending: DSQ applied by the script (ac.PenaltyType.BlackFlag).
--      The DT0 of an end-of-lap slowdown does not count.
--   7. Two DT0 do not become one DT1; two DT1 do not become one DT2.
--
-- List categories: PSE = Pit Speed Exceeded, pit lane speeding measured by the script; SDn = unpaid slowdown
-- of cut zone n.
-- Nothing of the list goes to the game: the Race Control panel shows it.
-- DSQ for leaving the pits with the session closed is outside the list (applied directly, with its own message).
-- Any DSQ clears the list; the script keeps running (the DSQ may be lifted by Race Control).

-- ============================================================
-- Configuration
-- ============================================================

-- Keys read from the script's own [SCRIPT_n] server section (ac.configValues uses the section that created it).
-- Every key below can be set in that section; the value here is the default used when the key is missing.
-- Session prefixes: practice / qualify / race (the session type reported by the game).
-- Same order as config/server/ACSM-CSP.txt: 1. script operation, 2. optional general data, 3. ACSM server,
-- 4. holds, tow and repair, 5. penalty control (pit exit, exclusion zone 1, exclusion zone 2, slowdown).
-- Struct keys: one key with several fields, read by ac.configValues as one text and split by structKey
-- (config/settings.lua):
--   key = field:value | field:value   (no quotes, no commas: the CSP turns a comma-separated value into several values
--   (ac.INIFormat.Extended) and a text read gets only the first one; ';' starts a comment and '[' a section)
-- A field left out keeps its default. Keys and fields (defaults):
--   stopAndGo = mode:SG | secondsPerDT:30 | maxDT:7 | deadlineLaps:1 | returnSeconds:0
--     mode: HOLD = two pending DT0 give the hold (holdShortSeconds / holdLongSeconds); SG = stop & go: stop at the own
--     pit place and stay stopped (the driver holds the car; no service) for secondsPerDT per drive-through; it holds
--     the whole list and every later penalty adds secondsPerDT, up to maxDT drive-throughs (one more = DSQ);
--     deadlineLaps: laps to serve it (1 = this lap or the next, like a DT1); returnSeconds: time the same driver has to
--     come back after a disconnection while stopped (0 = no limit). Without the key: HOLD.
--   practiceTow = mode:RESET        qualifyTow = mode:TOW | towSeconds:120 | repairFactor:1.5
--   raceTow = mode:TOW | towSeconds:120 | repairFactor:1.5
--     Back to the pits from the track (tow), per session. TOW = the car is locked in the pits (TeleportToPits) for
--     towSeconds + repair; repair chosen in the pit menu = repair only. RESET = the tow clears the penalties and the
--     slowdowns in progress (not a DSQ). NONE = nothing. With TOW, set ENFORCE_BACK_TO_PITS_PENALTY = 0 in
--     [EXTRA_RULES], or the driver also gets the AC back-to-pits penalty.
--   repairFormula = baseSeconds:180 | weightEngine:1.0 | weightSuspension:0.5 | weightBody:0.25
--     repair = repairFactor x (baseSeconds x (weightEngine x powertrain + weightSuspension x suspension) + weightBody x
--     body). Only damage from collisions counts (within COLLISION_DAMAGE_WINDOW seconds after ac.onCarCollision);
--     powertrain = engine and gearbox together (the larger increase); suspension = increase of the 4 wheels (0..1
--     each); body = increase of the body damage zones in km/h.
--   damage = toeBent:10 | toeBroken:20 | camberBent:10 | camberBroken:20 | bodyRepair:150 | maxPunctured:2 | repairLaps:2 |
--            beyondTowSeconds:180 | dsqTowSeconds:180
--     Qualifying and race. Toe and camber over the setup, per wheel, in degrees: over the bent limit = black flag with
--     orange disc (repair required); over the broken limit = damage beyond the safety limit (stop off track, tow).
--     bodyRepair: body damage of a side over which the repair is required; maxPunctured: punctured tyres that still
--     drive (the repair changes the 4; more = beyond the limit); repairLaps: line crossings to do the required
--     repair (not done by the last one = DSQ at the line). Beyond the safety limit, internal timers (not shown):
--     beyondTowSeconds without the tow = DSQ (safety hazard) that asks for the tow; dsqTowSeconds more = game black
--     flag (unsporting behaviour).
local cfg = ac.configValues({
  -- ------------------------------------------------------------
  -- 1. Script operation
  -- ------------------------------------------------------------
  -- announce
  --   1: public chat lines sent by the driver's client ("Exclusion zone cut - slow down", "- drive-through",
  --      "- disqualified", "Pit lane left with the session closed - disqualified").
  --   0: no public lines. The hidden [RC] lines for the server log are always sent.
  announce = 0,
  -- penaltyMode
  --   'CSP': every client checks its own car and applies the penalties in the game (cut zones, DT list, holds,
  --          DSQ). This is the mode the rules document describes.
  --   'KMR': only the Race Control client (raceControlSteamID) checks every car, and only for the closed pit exit:
  --          it sends '/kmr player_kick <id>' through the chat (that client must be logged in as a KMR admin).
  --          Cut zones, slowdowns and the DT list are not used in this mode.
  penaltyMode = 'CSP',
  -- Car controls
  -- forceCockpit: 1 = the cockpit camera is forced (every cockpitCheckInterval seconds, except with the game paused or
  --   in a replay); 0 = off. Replaces the separate forcecockpitonline.lua script.
  forceCockpit = 0,
  -- cockpitCameraMode: camera forced (0 = cockpit, first person view; ac.CameraMode).
  cockpitCameraMode = 0,
  -- cockpitCheckInterval: seconds between checks.
  cockpitCheckInterval = 0.05,
  -- CODE-80 (VSC / SC / full course yellow): no penalty can be served while it lasts. Started and ended by the server
  -- chat messages (start: "vsc", "virtual safety car", "safety car", "code-80", "code 80", "full course yellow";
  -- end: "green flag", "bandeira verde"). While it lasts: a pit pass pays nothing (the drive-through goes back to the
  -- game at the pit exit), slowdowns are not paid, and the hold for two pending DT0 waits for the green flag.
  -- code80FreezeDeadlines: 1 = deadlines stop: the line crossing does not take laps from the drive-throughs nor
  --   disqualify, and the slowdown deadline stops. 0 = deadlines keep running.
  code80FreezeDeadlines = 1,
  -- screenScale = exponent:0.45 | max:1.5
  --   Size of the pit stop box, setup status and car status on screens bigger than 1080p: (height / 1080) ^ exponent,
  --   from 1x at 1080p (the approved size) up to max. The Race Control panel keeps its own growth (^0.3, up to 1.3x),
  --   so these screens grow slightly more on a big screen (1440p: 1.14x; 4K: 1.37x).
  screenScale = '',

  -- ------------------------------------------------------------
  -- 2. General data (optional, filled in by the organizer)
  -- ------------------------------------------------------------
  -- raceControlSteamID: Steam ID of the race director client, logged in as admin. In any mode it sends the ban of an
  --   edited record file (/ban <car ID>); in 'KMR' mode it also checks every car. Empty = nobody.
  raceControlSteamID = '',
  -- cockpitExemptSteamIDs: Steam IDs not forced (for example, Race Control / broadcast), separated by '|' (not ';':
  --   it starts a comment in the INI; not ',': the CSP splits the value there and the script gets only the first).
  cockpitExemptSteamIDs = '',

  -- ------------------------------------------------------------
  -- 3. ACSM server: must match the ACSM race settings
  -- ------------------------------------------------------------
  -- Driver swap panel (green, below the slowdown box; race sessions only). ACSM runs the swap itself: its timer
  -- starts when the driver disconnects and it tells the next driver "please wait ..." / "Free to leave pits in ..."
  -- / "You are clear to leave the pits, go go go!" through the chat; those chat lines are kept as they are.
  -- <session>DriverSwap: driver swap in that session (optional; the regulation says who may do what). 1 = when the
  --   car stops at its pit place, the panel tells the driver to disconnect and shows the time since the stop and the
  --   total; the next driver sees the countdown sent by ACSM; the penalties stay with the driver who caused them
  --   (wrongDriverSeconds). 0 = no driver swap in that session.
  practiceDriverSwap = 0,
  qualifyDriverSwap = 0,
  raceDriverSwap = 0,
  -- driverSwapMinSeconds: total swap time; must be the same value as "Minimum Driver Swap Time" in ACSM.
  driverSwapMinSeconds = 120,
  -- driverSwapRequired: number of mandatory driver swaps in the race (same as "Minimum number of driver swaps" in ACSM).
  --   Empty = not informed: the SWAP cell of the Race Control panel stays off. 0 = driver swaps allowed, none
  --   mandatory (valid server setup): the cell shows done | 0. The cell is shown whenever the panel is on, but it
  --   turns the panel on only inside the pit lane. Only with the driver swap on in the session.
  driverSwapRequired = '',

  -- ------------------------------------------------------------
  -- 4.1 Holds (rule 5): seconds stopped in the pits with locked controls; the hold clears the whole list
  -- ------------------------------------------------------------
  -- holdShortSeconds: two pending DT0.
  holdShortSeconds = 45,
  -- holdLongSeconds: two pending DT0 when one of them is the PSE that became DT0 crossing the line on track.
  holdLongSeconds = 90,
  -- stopAndGo (struct key, see "Struct keys" above): what two pending DT0 give and the stop & go.
  stopAndGo = '',
  -- wrongDriverSeconds: the penalty is paid only by the driver who caused it; the swap is not allowed while there is
  --   anything to pay. Another driver who enters the car anyway has this many seconds to leave (countdown); not gone:
  --   DSQ, and the original driver cannot come back. 0 = another driver is not allowed (DSQ as he enters). Empty = no
  --   time defined: the new driver takes the penalties over and pays them (not the world standard).
  wrongDriverSeconds = '120',
  -- dsqBlackFlagLaps: our DSQ (informative) asks the driver to stop at the pit place; not stopped, the game black flag
  --   (controls locked) comes after this many line crossings.
  dsqBlackFlagLaps = 3,
  -- pitStopOrder: order of the operations of the own pit stop box (the AC pit menu is off, so the script times the
  --   stop). Same notation as PITS_ORDER of the CSP [EXTRA_RULES]: F fuel, T tyres, R repair, one after the other;
  --   letters inside < > at the same time. F<TR> = fuel first, then tyres and repair together.
  pitStopOrder = 'F<TR>',
  -- pitWindowStartMinutes / pitWindowEndMinutes: driver swap window of the race, in minutes after the race start (the
  --   script's own; off in the ACSM). A driver swap is valid only if the car crossed the pit entry line inside it; the
  --   pit lane is a neutral zone. Closed without a valid swap: DSQ. 0 = no window.
  pitWindowStartMinutes = 0,
  pitWindowEndMinutes = 0,
  -- pitStopsEnabled: 1 = pit stops are counted and recorded (one per pit pass with service, repair or a stop & go
  --   served, at any time; the driver swap is not a stop). pitStopsRequired: stops required in the race; 0 = counted,
  --   not validated, no penalty; missing at the end of the race = DSQ.
  pitStopsEnabled = 0,
  pitStopsRequired = 0,

  -- ------------------------------------------------------------
  -- 4.2 Tow and repair, 4.3 car damage: struct keys (see "Struct keys" above)
  -- ------------------------------------------------------------
  practiceTow = '',
  qualifyTow = '',
  raceTow = '',
  repairFormula = '',
  damage = '',

  -- ------------------------------------------------------------
  -- 5.1 Penalty control: pit exit while closed
  -- ------------------------------------------------------------
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

  -- ------------------------------------------------------------
  -- 5.2 Penalty control: cut zone 1 (category SD1)
  -- ------------------------------------------------------------
  -- cutZoneStart / cutZoneEnd: track spline position of the zone, 0..1. Start = end disables the zone.
  --   Start > end means the zone crosses the start/finish line.
  cutZoneStart = 0.16,
  cutZoneEnd = 0.24,
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
  -- cutMaxWheelsOut: penalty when more wheels than this are outside the track (3 = all four wheels out).
  --   At most one penalty per pass through the zone; not checked in the pit lane.
  cutMaxWheelsOut = 3,
  -- cutSlowdownMaxGas: highest throttle (0..1) that still counts as lifting.
  cutSlowdownMaxGas = 0.2,
  -- Gain filter (slowdown only). Reference = the driver's best clean passage through the zone in this session.
  -- cutGainTolerance: % over the reference. A cut with the car back on track in less than reference x (1 + %) gets
  --   the slowdown; slower (lost time), no slowdown. No reference yet: slowdown as before.
  cutGainTolerance = 6,

  -- ------------------------------------------------------------
  -- 5.3 Penalty control: cut zone 2 (category SD2), same meaning as zone 1; slowdown 9 s, deadline 18 s
  -- ------------------------------------------------------------
  cutZone2Start = 0.81,
  cutZone2End = 0.91,
  practiceCutZone2Penalty = 'SLOW DOWN',
  qualifyCutZone2Penalty = 'SLOW DOWN',
  raceCutZone2Penalty = 'SLOW DOWN',
  practiceCutZone2PenaltyParam = 9,
  qualifyCutZone2PenaltyParam = 9,
  raceCutZone2PenaltyParam = 9,
  cutZone2SlowdownDeadline = 18,
  cutZone2MaxWheelsOut = 3,
  cutZone2SlowdownMaxGas = 0.1,
  cutZone2GainTolerance = 6,

  -- ------------------------------------------------------------
  -- 5.4 Penalty control: slowdown, both zones
  -- ------------------------------------------------------------
  -- Overlapping slowdowns (zone 2 while zone 1 is still running, or the other way round) are merged into one:
  -- the times add up, with the newest deadline; unpaid, each zone becomes its own DT0.
  -- <session>SlowdownUnpaidPenalty
  --   'DT': DT0 of the category (SD1 / SD2). Deadline expired mid-lap: DT0 of the current lap (crossing the line on
  --         track without serving it = DSQ). Expired at the line, or inside the pit lane: DT0 of the next lap.
  --   'DSQ': black flag at once. 'NONE': nothing.
  practiceSlowdownUnpaidPenalty = 'DT',
  qualifySlowdownUnpaidPenalty = 'DT',
  raceSlowdownUnpaidPenalty = 'DT',
  -- cutSpinAngle: degrees between where the car points and where it moves; above it during the cut = spin, cut discarded
  cutSpinAngle = 90,
  -- <session>SlowdownUnpaidParam: not used (the DT is always DT0).
  practiceSlowdownUnpaidParam = 0,
  qualifySlowdownUnpaidParam = 0,
  raceSlowdownUnpaidParam = 0,
  -- pitSlowdownDeadline / pitSlowdownMaxGas: not used.
  pitSlowdownDeadline = 0,
  pitSlowdownMaxGas = 0,

  -- ------------------------------------------------------------
  -- 5.5 Penalty control: pit lane speeding (measured by the script; SPEEDING_PENALTY = NONE on the server)
  -- ------------------------------------------------------------
  -- pitSpeedLimit: pit lane speed limit of the rule, km/h (the script's own; SPEED_KMH of [PITS_SPEED_LIMITER] on the
  --   server only sets the car's limiter and should be the same). pitSpeedTolerance: km/h over it before it is
  --   speeding. pitSpeedDeadlineLaps: laps to serve the PSE (1 = DT1).
  pitSpeedLimit = 60,
  pitSpeedTolerance = 2,
  pitSpeedDeadlineLaps = 1,
})


-- Version shown in the opening of the Race Control panel (date of the release)
local RC_VERSION = '2026.09.26'

local TEXTS = {
  pit = {
    DSQ = 'Pit lane left with the session closed - disqualified',
  },
  cut = {
    SLOWDOWN = 'Exclusion zone cut - slow down',
    DT = 'Exclusion zone cut - drive-through',
    DSQ = 'Exclusion zone cut - disqualified',
  },
  -- slowdown box line, in pieces: the two numbers pulse (see slowdown.lua)
  timerPay = 'SLOW DOWN  ',
  timerSeconds = '%.1f s',
  timerDeadline = '   deadline ',
  timerDeadlineSeconds = '%.0f s',
  timerEnd = ' or end of lap',
  -- slowdown box and gain check box (same size, same font)
  sdTitle = 'EXCLUSION ZONE CUT - slow down',
  liftTitle = 'EXCLUSION ZONE CUT - lift to avoid a slowdown',
  liftSlower = 'slower - no penalty',
  liftFaster = 'faster - slowdown',
  liftLimit = '+%g%% ref',
  -- Race Control: server log line (chat, hidden from every client) and the box on the penalized driver's screen
  rcPrefix = '[RC] ',
  rcTitle = 'RACE CONTROL',
  -- opening of the panel (panel/intro.lua): name and version
  introText = 'RACE CONTROL  v' .. RC_VERSION,
  introStatus = 'STATUS OK',
  -- Race Control panel cells
  cellPit = 'PIT WINDOW',
  cellSwap = 'SWAP',
  cellTrack = 'TRACK',
  cellPenalties = 'PENALTIES',
  pitOpen = 'OPEN %s',
  pitDone = 'DONE',
  pitMissed = 'MISSED',
  pitOpenMsg = 'Pit window open - driver swap before it closes',
  swapCount = '%d | %d',
  trackYellow = 'YELLOW',
  trackBlue = 'BLUE',
  penHold = 'HOLD',
  penDsq = 'DSQ',
  penSG = 'SG%d · %d DTs',
  -- stop & go (message line)
  sgPending = 'Stop & go %d s - stop at your pit this lap or next',
  sgLastLap = 'LAST LAP - Stop & go %d s - stop at your pit now',
  sgOverdue = 'OVERDUE - Stop & go %d s - stop at your pit',
  sgServiced = 'Service at the pit - stop & go not served in this pit pass',
  sgStopped = 'Stop & go %s - stay stopped, no service',
  sgInterrupted = 'Stop & go interrupted - %s left - only the same driver may continue',
  -- own pit stop box (approved screen 11)
  pitMissedLog = 'MISSED - no valid driver swap inside the pit window',
  pitBoxTitle = 'PIT STOP',
  pitBoxTotal = 'Total %s',
  pitBoxConfirm = 'Enter to confirm',
  pitBoxServing = 'Pit stop in progress',
  pitFuel = 'Fuel',
  pitFuelValue = '+%d L (to %d L)',
  pitCompound = 'Compound',
  pitTyres = 'Tyres',
  pitPressureFront = 'Pressure front',
  pitPressureRear = 'Pressure rear',
  pitWing = 'Wing',
  pitRepairSuspension = 'Suspension repair',
  pitRepairPowertrain = 'Powertrain repair',
  pitRepairBody = 'Bodywork repair',
  pitRepairYes = 'Repair',
  pitRepairNo = 'No',
  pitRepairNone = 'None',
  -- setup status (approved screen 14) and car status (approved screen 12)
  setupTitle = 'SETUP STATUS',
  setupLap = 'Lap %d',
  setupAero = 'Aero',
  setupWing = 'Wing',
  setupDrive = 'Drive train',
  setupDiffPower = 'Diff power',
  setupDiffCoast = 'Diff coast',
  setupPreload = 'Preload',
  setupBrakeBias = 'Brake bias',
  setupChassis = 'Chassis',
  setupHeight = 'Height',
  setupArb = 'ARB',
  setupToe = 'Toe',
  setupCamber = 'Camber',
  setupSuspension = 'Suspension',
  setupSpring = 'Spring',
  setupBump = 'Bump',
  setupRebound = 'Reb.',
  setupTyres = 'Tyres',
  setupPsi = 'PSI',
  setupLife = 'Life',
  setupKm = 'Km',
  setupElectronics = 'ABS %d  TC %d  TC2 %d  MAP %d  EB %d  ERS %d  REC %d',
  statusTitle = 'CAR STATUS',
  statusRepair = 'REPAIR',
  statusBeyond = 'UNSAFE',
  statusWheels = 'Wheels & suspension',
  statusPunct = 'PUNCT',
  statusBent = 'BENT +%.0f°',
  statusBroken = 'BROKEN +%.0f°',
  statusBrokenShort = 'BROKEN',
  statusPowertrain = 'Powertrain',
  statusEngine = 'ENGINE',
  statusGearbox = 'GEARBOX',
  statusOk = 'OK',
  statusBody = 'Body',
  -- stop & go box (approved screens 3 and 4)
  sgBoxTitle = 'STOP & GO',
  sgBoxStay = 'Stay stopped - no service during stop & go',
  sgBoxTimes = 'Stopped %s / Total %s',
  sgBoxInterrupted = 'STOP & GO INTERRUPTED',
  sgBoxLeft = '%s left',
  sgBoxSameDriver = 'Only the same driver may continue',
  sgBoxReturnWithin = 'Only the same driver may continue - return within %s',
  sgBoxResume = 'Stop at your pit place to resume',
  sgServed = 'Stop & go served',
  sgLimit = 'Stop & go limit - more than %d penalties',
  swapBlocked = 'Swap not allowed - serve the penalties first',
  wrongDriverTitle = 'WRONG DRIVER',
  wrongDriverLeave = 'Penalties of another driver pending - leave the car',
  wrongDriverTime = 'Leave within %s',
  -- car damage (black flag with orange disc; beyond the safety limit)
  damageRepairLaps = 'REPAIR REQUIRED - %d LAPS',
  damageRepairLast = 'REPAIR REQUIRED - LAST LAP',
  damageBent = 'Suspension bent - %s',
  damageSuspension = 'Suspension %s',
  damageAngle = '%s +%.1f° over setup',
  damageBody = 'Bodywork damage %s %d',
  damageBodyLimit = 'limit %d',
  damageTyre = 'Tyre punctured - %s',
  damageTyres = 'Tyres punctured - %d',
  damageTyresAllowed = '%d of %d allowed',
  damageBeyondTitle = 'DAMAGE BEYOND SAFETY LIMIT',
  damageBeyond = 'Stop off track and return to pits (tow)',
  damageWheel = 'Wheel missing - %s',
  -- DSQ (black flag drawn by the script until the game black flag)
  dsqTitle = 'DISQUALIFIED',
  dsqStop = 'Stop at your pit before the line',
  dsqTow = 'Tow to the pits - otherwise disqualified for unsporting behaviour',
  dsqSafety = 'Safety hazard - damage beyond the safety limit',
  -- edited record file (ban)
  editedFile = 'Edited file',
  editedFileDetail = 'record %s - car %d - ban pending',
  kmrTitle = 'KMR',
  -- driver swap panel
  swapActive = 'DRIVER SWAP ACTIVE',
  swapTitle = 'DRIVER SWAP',
  swapDisconnect = 'Disconnect to perform the driver swap',
  swapWait = 'You are now driving - wait %s before leaving the pits',
  swapClear = 'You are clear to leave the pits - GO GO!',
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
    PSE = 'Pit lane speeding',
    RC = 'Race Control decision',
  },
  -- KMR drive-through reasons (category K<n>); on screen with " (KMR)", in the log with " (issued by KMR)"
  kmrReasons = {
    K0 = 'KMR penalty', K1 = 'Pit exit line crossing', K2 = 'Pit lane speeding', K3 = 'Infraction limit',
    K4 = 'Collision with a car lapping you', K5 = 'Collision with a car in a hot lap', K6 = 'Hot lap disturbed',
    K7 = 'Reverse gear', K8 = 'Car parked near the track', K9 = 'Too many collisions', K10 = 'Speeding under VSC',
    K11 = 'Slowing under VSC', K12 = 'Overtaking under VSC', K13 = 'Cut line', K14 = 'Blue flags ignored',
    K15 = 'Rejoining the track at high speed',
  },
  pitDsq = "You've been disqualified for leaving the pit lane with the session closed.",
  dtDsq = "You've been disqualified for not serving the drive-through.",
  dsqGame = "You've been disqualified - %s.",
  dsqBlackFlag = 'Black flag',
  dsqDtReason = 'Drive-through not served',
  -- drive-through flag box
  dtTitle = 'DRIVE-THROUGH',
  dtMore = '  +%d',
  dtThisLap = 'Serve it this lap',
  dtNextLap = 'Serve it this lap or the next',
  dtWithinLaps = 'Serve it within %d laps',
  dtOverdue = 'OVERDUE - serve it at the next pit pass',
  pitWindowDsq = 'Mandatory pit stop missed',
  swapEarlyDsq = 'Left the pits before the driver swap time',
  swapsMissingDsq = 'Driver swaps missing (%d of %d)',
  stopsMissingDsq = 'Pit stops missing (%d of %d)',
  -- driver and pit stop tables (lines in the server log)
  driverRow = 'Driver',
  driverRowText = 'swap %d%s - team %s - GUID %s',
  driverRowRejoin = ' (rejoin)',
  pitStopRow = 'Pit',
  pitStopRowText = 'line %d - stop %s - in %s - out %s - %s - %s - %s - flags %s/%s - team %s - GUID %s',
  pitStopRowInPits = 'in the pits',
  pitStopRowNoService = 'no service',
  pitStopRowNoPenalty = 'no penalty',
}

for cat, base in pairs(TEXTS.kmrReasons) do TEXTS.reason[cat] = base .. ' (KMR)' end

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

-- Struct key of this script's section: "key = field:value | field:value" (no quotes, no commas), read by
-- ac.configValues as one text (cfg) and split here at '|' and ':'. Fields over the defaults; numbers as numbers, text
-- in upper case; an unknown field goes to the log.
local function structKey(key, defaults)
  local out = {}
  for k, v in pairs(defaults) do out[k] = v end
  for item in tostring(cfg[key] or ''):gmatch('[^|]+') do
    local k, v = item:match('^%s*([%w_]+)%s*:%s*(.-)%s*$')
    if k and out[k] ~= nil then
      out[k] = type(out[k]) == 'number' and (tonumber(v) or out[k]) or v:upper()
    else
      ac.log('race-control: key ' .. key .. ': field not known: ' .. item:match('^%s*(.-)%s*$'))
    end
  end
  return out
end

local STOP_AND_GO = structKey('stopAndGo', { mode = 'HOLD', secondsPerDT = 30, maxDT = 7, deadlineLaps = 1,
  returnSeconds = 0 })
local TOW_RULE = { mode = 'TOW', towSeconds = 120, repairFactor = 1.5 }
local REPAIR_FORMULA = structKey('repairFormula', { baseSeconds = 180, weightEngine = 1.0, weightSuspension = 0.5,
  weightBody = 0.25 })
local SCREEN_SCALE = structKey('screenScale', { exponent = 0.45, max = 1.5 })
local DAMAGE = structKey('damage', { toeBent = 10, toeBroken = 20, camberBent = 10, camberBroken = 20, bodyRepair = 150,
  maxPunctured = 2, repairLaps = 2, beyondTowSeconds = 180, dsqTowSeconds = 180 })

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
  sg = STOP_AND_GO.mode == 'SG',
  sgSecondsPerDT = STOP_AND_GO.secondsPerDT,
  sgMaxDT = STOP_AND_GO.maxDT,
  sgDeadlineLaps = STOP_AND_GO.deadlineLaps,
  sgReturnSeconds = STOP_AND_GO.returnSeconds,
  wrongDriver = tonumber(cfg.wrongDriverSeconds),
  dsqBlackFlagLaps = math.max(math.floor(tonumber(cfg.dsqBlackFlagLaps) or 3), 1),
  pitStopOrder = tostring(cfg.pitStopOrder or 'F<TR>'),
  beyondTowSeconds = DAMAGE.beyondTowSeconds,
  dsqTowSeconds = DAMAGE.dsqTowSeconds,
  swap = bySession(tonumber(cfg.practiceDriverSwap) == 1, tonumber(cfg.qualifyDriverSwap) == 1,
    tonumber(cfg.raceDriverSwap) == 1),
  swapMinSeconds = tonumber(cfg.driverSwapMinSeconds) or 120,
  -- nil = not informed (cell off); 0 or more = shown
  swapRequired = tonumber(cfg.driverSwapRequired) and math.floor(tonumber(cfg.driverSwapRequired)) or nil,
  cutSpinAngle = tonumber(cfg.cutSpinAngle) or 90,
  pitSpeedLimit = tonumber(cfg.pitSpeedLimit) or 60,
  pitSpeedTolerance = tonumber(cfg.pitSpeedTolerance) or 2,
  pitWindowStart = tonumber(cfg.pitWindowStartMinutes) or 0,
  pitStopsEnabled = tonumber(cfg.pitStopsEnabled) == 1,
  pitStopsRequired = math.floor(tonumber(cfg.pitStopsRequired) or 0),
  pitWindowEnd = tonumber(cfg.pitWindowEndMinutes) or 0,
  pitSpeedDeadlineLaps = math.floor(tonumber(cfg.pitSpeedDeadlineLaps) or 1),
  code80Freeze = tonumber(cfg.code80FreezeDeadlines) == 1,
  screenScale = SCREEN_SCALE,
  -- Tow per session: mode ('TOW', 'RESET', 'NONE'), towSeconds, repairFactor
  tow = bySession(
    structKey('practiceTow', { mode = 'RESET', towSeconds = 0, repairFactor = 0 }),
    structKey('qualifyTow', TOW_RULE),
    structKey('raceTow', TOW_RULE)),
  repair = {
    base = REPAIR_FORMULA.baseSeconds,
    wEngine = REPAIR_FORMULA.weightEngine,
    wSuspension = REPAIR_FORMULA.weightSuspension,
    wBody = REPAIR_FORMULA.weightBody,
  },
  damage = {
    toeBent = DAMAGE.toeBent,
    toeBroken = DAMAGE.toeBroken,
    camberBent = DAMAGE.camberBent,
    camberBroken = DAMAGE.camberBroken,
    bodyRepair = DAMAGE.bodyRepair,
    maxPunctured = DAMAGE.maxPunctured,
    repairLaps = DAMAGE.repairLaps,
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

-- Driver swap on in the session now
function config.swapOn() return config.swap[ac.getSim().raceSessionType] == true end

-- Race director client (raceControlSteamID), in any mode: sends the admin commands (ban of an edited file)
config.isDirector = config.raceControlSteamID ~= '' and ac.getUserSteamID() == config.raceControlSteamID
config.isRaceControl = config.mode == 'KMR' and config.isDirector

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
  onJumped = {},
  kmrMessages = {},
  rcCommands = {},       -- Race Control commands from the server (ACSM live timing), read in script.update
  pitService = nil,       -- own pit stop in progress: { startMs, untilMs, plan } (PitBox)       -- KMR drive-through messages to this driver, read in script.update (KmrDT)
  -- Car damage class (DamageClass): 'normal', 'repair' (orange disc) or 'beyond'; lapsLeft = line crossings left to
  -- do the required repair (nil = none running; kept in the car record)
  -- beyondSince = server ms of the warning of damage beyond the safety limit (internal timer, kept in the car record)
  repair = { class = 'normal', lapsLeft = nil, text = nil, detail = nil, beyondSince = nil },          -- functions called on a teleport or car reset, before anything else (car state saved)
  -- active slowdowns, one per zone (category SD1, SD2)
  slowdowns = {},
  list = {
    items = {},           -- { cat, kind, laps, givenLap, expireLap, seq, dt0OnTrack }; items[1] = position 0
    curLap = 0,           -- current lap (car.lapCount)
    seq = 0,
    inPitNow = false,     -- car in the pit lane in the current frame
    jumped = false,       -- car teleported (ac.onCarJumped): the penalty stays until a real pit pass pays it
    endOfLap = {},        -- slowdowns that expired at the line crossing (count for the next lap)
    lastLap = 0,
    prevGame = { t = 0, p = 0 },  -- last processed game state (its black flag)
    prevInPit = false,
    -- The penalty is the car's, but only the driver who caused it pays it (international rules): the list keeps that
    -- driver, and the car is not handed to another driver while the list has anything to pay
    owner = nil,          -- name code of the driver who has to pay the list
    dsq = 0,              -- DSQ of the car in this session: 0 none, 1 disqualified, 2 pit exit with session closed
    -- The game black flag only comes when the driver does not do what the DSQ asks: 0 = stop at the pit place before
    -- the line (black flag at the pit place or at the line), 2 = tow to the pits before dsqUntil, 1 = game black flag
    dsqStage = 0,
    dsqUntil = 0,         -- server ms: end of the time to tow to the pits (stage 2)
    dsqLap = 0,           -- lap count when the DSQ was given (the line of that lap does not count)
    dsqReason = nil,      -- reason shown with the drawn black flag
    wrong = nil,          -- another driver in the car with the list pending: { driver = name code, since = server ms }
    invalidLap = nil,     -- lap count of the lap already made invalid (practice and qualifying, penalty unpaid)
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
    entered = false,      -- this driver took over the car in a driver swap (no panel opening)
    clearUntil = nil,     -- "clear to leave" shown until this clock
    lastNames = {},       -- [carIndex] = last known driver name (other cars)
    left = {},            -- [carIndex] = { sessionID, driver = name code, t = clock } drivers that left a car
    relay = {},           -- pending SWAP_INFO sends: { target, car, driver, swaps, leftT, dueT }
    count = 0,            -- driver swaps done by this car (swap number of the last one)
    valid = 0,            -- valid driver swaps (pit entry inside the pit window, decision 112): the SWAP cell
    swapNo = 0,           -- swap number of the driver in command (driver table)
    driver = 0,           -- name code of the driver in command (0 = none yet)
    swapInfo = nil,       -- swap told by the other drivers in this connection: { inWindow }
    carSwaps = {},        -- [carIndex] = swaps done by other cars, seen by this client (sent to the next driver)
    carValid = {},        -- [carIndex] = valid swaps of other cars, seen by this client
    pitEntryValid = {},   -- [carIndex] = the last pit entry of another car was inside the pit window (or no window)
    carLists = {},        -- [carIndex] = penalty list published by the driver of another car when parked
    listSent = nil,       -- signature of the own list last published while parked
    listApplied = false,  -- penalty list of the previous driver already received (this session)
    pendingList = nil,    -- received list waiting to be applied in script.update
  },
  code80 = nil,           -- CODE-80 in progress: 'VSC', 'SC' or 'CODE-80' (from the server chat); nil = green
  code80Ended = false,    -- green flag received: the rules deferred during CODE-80 run in the next frame
  hold = nil,             -- hold in progress (locked in the pits): { untilT, text }; drive-throughs are not written
  pit = { done = false, missed = false }, -- mandatory pit stop inside the pit window: done, or missed (logged once)
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
  for _, fn in ipairs(state.onJumped) do fn() end
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
-- Struct keys as the server sent them (one text each) and the stop & go mode in force
for _, key in ipairs({ 'screenScale', 'stopAndGo', 'practiceTow', 'qualifyTow', 'raceTow', 'repairFormula', 'damage' }) do
  ac.log('race-control: key ' .. key .. ' = ' .. tostring(cfg[key]))
end
ac.log('race-control: stopAndGo mode in force: ' .. (config.sg and 'SG' or 'HOLD'))
-- Pit limit of the rule (pitSpeedLimit) against the car's limiter set by the server (SPEED_KMH): the SDK cannot set the
-- limiter, so both have to be the same
if math.abs((tonumber(sim.pitsSpeedLimit) or 0) - config.pitSpeedLimit) > 0.5 then
  ac.log(string.format('race-control: WARNING pitSpeedLimit %d differs from the server pit limiter (SPEED_KMH) %d',
    config.pitSpeedLimit, (tonumber(sim.pitsSpeedLimit) or 0)))
end
-- ============================================================
-- Utilities
-- ============================================================

-- Server command (admin), sent through the chat queue whatever the announcements setting
local function queueCommand(msg)
  state.chat.queue[#state.chat.queue + 1] = msg
end

-- Public announcement (announce = 1)
local function queueChat(msg)
  if config.announce then queueCommand(msg) end
end

-- Laps of this car in the server leaderboard of the current session (they do not start again from zero on a new
-- connection, unlike car.lapCount); nil if the leaderboard does not have the car (SDK: not all data is available online).
-- The line crossing is still detected with car.lapCount (local and immediate).
local function leaderboardLaps()
  local session = ac.getSession(sim.currentSessionIndex)
  local board = session and session.leaderboard
  if not board then return nil end
  for i = 0, #board do
    local entry = board[i]
    if entry and entry.car and entry.car.index == 0 then return entry.laps end
  end
  return nil
end

-- Server time: session time in milliseconds, synced on all clients (the same on every computer, unlike os.clock)
local function serverTimeMs() return sim.currentSessionTime or 0 end

-- Car readings shared by the modules
local CarRead = {}
-- Number, or 0
function CarRead.num(v) return tonumber(v) or 0 end
-- Flag of the car (SDK strings such as isRepairing; true, number or text in practice)
function CarRead.flagOn(v)
  return v == true or (type(v) == 'number' and v ~= 0)
    or (type(v) == 'string' and v ~= '' and v ~= '0' and v:lower() ~= 'false')
end
-- The car as it arrived at its pit place: fuel, compound, tyre km, body, suspension and engine
function CarRead.snapshot(car)
  local s = { fuel = CarRead.num(car.fuel), compound = CarRead.num(car.compoundIndex), km = {}, body = {}, susp = {},
    engine = CarRead.num(car.engineLifeLeft) }
  for i = 0, 3 do
    s.km[i] = CarRead.num(car.wheels and car.wheels[i] and car.wheels[i].tyreVirtualKM)
    s.susp[i] = CarRead.num(car.suspensionDamage[i])
  end
  for i = 0, 4 do s.body[i] = CarRead.num(car.damage[i]) end
  return s
end
-- Service at the pit place: the own pit stop box running a stop, or a real change in the car since it arrived (fuel
-- added, compound or tyres changed, damage repaired). Without a change in the car there is no service (the game flags
-- and the AC pit screen opened and closed do not count)
function CarRead.serviced(car, s)
  if state.pitService ~= nil then return true end
  if CarRead.num(car.fuel) > s.fuel or CarRead.num(car.compoundIndex) ~= s.compound
    or CarRead.num(car.engineLifeLeft) > s.engine then
    return true
  end
  for i = 0, 3 do
    if CarRead.num(car.wheels and car.wheels[i] and car.wheels[i].tyreVirtualKM) < s.km[i]
      or CarRead.num(car.suspensionDamage[i]) < s.susp[i] then
      return true
    end
  end
  for i = 0, 4 do
    if CarRead.num(car.damage[i]) < s.body[i] then return true end
  end
  return false
end
-- Stopped at its own pit place: the game's own reading (SDK car.isInPit: "parked in its pit stop place")
function CarRead.parked(car) return car.isInPit end
-- Moving: any speed
function CarRead.moving(car) return car.speedKmh > 0 end

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

-- ============================================================
-- Car record
-- Every control list (penalties, pit window, driver swaps and the track; the car later) is saved as one record:
-- list name, race key, version (seq) and checksum. A record from another race, another session, another car or with a
-- wrong checksum is ignored. Each record is kept in three places: ac.store (survives a script reload), ac.storage (a
-- file on this computer: survives leaving the server and restarting the game) and the other drivers (RecordSync:
-- survives a driver swap to another computer).
-- Text format: RC1|<list>|<key>|<seq>|<checksum>|<body>
-- Key: <server ip>:<tcp port>/<session index>/<session start, minutes>/<car slot>
-- ============================================================

local Record = {}
local RECORD_VERSION = 'RC1'
local RECORD_PREFIX = 'race-control.rec.'
local STORAGE_PREFIX = 'rc.'
-- Clients' clocks differ: the session start of two records of the same race may differ by this much
local SESSION_START_TOLERANCE_MIN = 2

-- Session start in server time, rounded to the minute: system time minus the session time (synced on all clients)
local function sessionStartMinutes()
  return math.floor(((sim.systemTime or 0) - (sim.currentSessionTime or 0) / 1000) / 60 + 0.5)
end

-- Race key of this car in the current session
function Record.key()
  return string.format('%s:%s/%d/%d/%d', tostring(ac.getServerIP() or ''), tostring(ac.getServerPortTCP() or ''),
    sim.currentSessionIndex, sessionStartMinutes(), ac.getCar(0).sessionID)
end

local function parseKey(key)
  local server, session, start, slot = tostring(key):match('^(.-)/(%-?%d+)/(%-?%d+)/(%-?%d+)$')
  if not server then return nil end
  return { server = server, session = tonumber(session), start = tonumber(start), slot = tonumber(slot) }
end

-- Same server and session, session start within the tolerance (any car: lists of the race, like the track)
function Record.sameSession(keyA, keyB)
  local a, b = parseKey(keyA), parseKey(keyB)
  if not a or not b then return false end
  return a.server == b.server and a.session == b.session and math.abs(a.start - b.start) <= SESSION_START_TOLERANCE_MIN
end

-- Same server, session and car, session start within the tolerance
function Record.sameRace(keyA, keyB)
  local a, b = parseKey(keyA), parseKey(keyB)
  return Record.sameSession(keyA, keyB) and a.slot == b.slot
end

local function checksum(list, key, seq, body)
  return tostring(ac.checksumXXH(table.concat({ list, key, tostring(seq), body }, '|')))
end

function Record.encode(list, seq, body)
  local key = Record.key()
  return table.concat({ RECORD_VERSION, list, key, tostring(seq), checksum(list, key, seq, body), body }, '|')
end

-- Returns { list, key, seq, body }, or nil and 'checksum' (the text was changed) or nil (not a record)
function Record.decode(text)
  if type(text) ~= 'string' then return nil end
  local version, list, key, seq, sum, body = text:match('^(%w+)|(%w+)|([^|]+)|(%d+)|([^|]+)|(.*)$')
  if version ~= RECORD_VERSION then return nil end
  if checksum(list, key, tonumber(seq), body) ~= sum then
    ac.log('race-control: record ' .. tostring(list) .. ' ignored: wrong checksum')
    return nil, 'checksum'
  end
  return { list = list, key = key, seq = tonumber(seq), body = body }
end

-- Set by RecordSync: sends every saved record to the other drivers
Record.onSave = nil
-- Set by Ban: a record of this computer with a wrong checksum (the file was edited)
Record.onTampered = nil

function Record.save(list, seq, body)
  local text = Record.encode(list, seq, body)
  ac.store(RECORD_PREFIX .. list, text)
  ac.storage[STORAGE_PREFIX .. list] = text
  if Record.onSave then Record.onSave(list, seq, text) end
end

local function valid(rec, list)
  if not rec or rec.list ~= list or not Record.sameRace(rec.key, Record.key()) then return nil end
  return rec
end

-- Body, seq and source of the saved record of this list, if it belongs to this race and this car. Same process first
-- (ac.store), then this computer (ac.storage)
function Record.load(list)
  local rec = valid(Record.decode(ac.load(RECORD_PREFIX .. list)), list)
  if rec then return rec.body, rec.seq, 'store' end
  local fileRec, err = Record.decode(ac.storage[STORAGE_PREFIX .. list])
  if err == 'checksum' and Record.onTampered then Record.onTampered(list) end
  rec = valid(fileRec, list)
  if rec then return rec.body, rec.seq, 'storage' end
  return nil
end
-- ============================================================
-- Online messages (ac.OnlineEvent) of every module go through this one queue. SDK: "At least 200 ms should pass
-- between sending messages", and the send returns false when a limit is exceeded. So one message is sent at a time,
-- ONLINE_GAP apart, and a message refused stays first in the queue and is sent again.
-- ============================================================

local OnlineQueue = { items = {}, nextT = 0 }
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local ONLINE_GAP = 0.25   -- seconds between two sends (the SDK asks for at least 0.2)

  -- A message to send: send = the function returned by ac.OnlineEvent; target = session ID, or nil for everybody
  function OnlineQueue.push(send, msg, target)
    OnlineQueue.items[#OnlineQueue.items + 1] = { send = send, msg = msg, target = target }
  end

  function OnlineQueue.update()
    local clock = state.ui.clock
    local q = OnlineQueue.items[1]
    if not q or clock < OnlineQueue.nextT then return end
    OnlineQueue.nextT = clock + ONLINE_GAP
    if q.send(q.msg, false, q.target) then table.remove(OnlineQueue.items, 1) end
  end
end
-- ============================================================
-- Record sync
-- Every record saved by this car goes to the other drivers, and every client keeps the last valid record of each car
-- and list. A client that starts (reconnection, restarted game, driver swap on another computer) asks the others for
-- the records of its car. The answer of the others wins over the local file when it is as new or newer: the local file
-- never removes what the others keep. Original AC server limits (SDK): messages under 175 bytes and at least 200 ms
-- apart, so records travel in parts through the online queue (OnlineQueue).
-- The track list belongs to the race: it is not sent at every change (each client reads the chat); a client that
-- starts gets the track record of every other client, and the latest change wins (TrackList).
-- ============================================================

local RecordSync = {
  peers = {},       -- [car slot][list] = { seq, text } last valid record of each car
  parts = {},       -- [car/list/seq] = { count, [part] = text } records arriving in parts
  restorers = {},   -- [list] = function(body, seq, source): applies a record of the own car
  pending = {},     -- [list] = { body, seq } own records from the others, applied in script.update
  askedT = nil,     -- clock when the own records were asked for
  ownTrack = nil,   -- { seq, text } track record of this client, sent to a client that starts
}
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local SYNC_PART = 120         -- characters of record text per message
  local SYNC_ANSWER_WINDOW = 30 -- seconds after asking in which the answers of the others are applied
  local SYNC_REQUEST = 255
  local SYNC_LISTS = { 'penalties', 'window', 'swap', 'track', 'car', 'gain', 'pit' }
  local SYNC_CODES = { penalties = 1, window = 2, swap = 3, track = 4, car = 5, gain = 6, pit = 7 }

  local sendRecordEvent = ac.OnlineEvent({
    ac.StructItem.key('12hcuritiba.race-control.rec'),
    rcCar = ac.StructItem.uint8(),
    rcList = ac.StructItem.uint8(),
    rcSeq = ac.StructItem.uint16(),
    rcPart = ac.StructItem.uint8(),
    rcParts = ac.StructItem.uint8(),
    rcText = ac.StructItem.string(SYNC_PART),
  }, function(sender, msg) RecordSync.receive(sender, msg) end, nil, nil, { processPostponed = true })

  local function ownSlot() return ac.getCar(0).sessionID end

  local function queueRecord(car, list, seq, text, target)
    local parts = math.max(1, math.ceil(#text / SYNC_PART))
    for i = 1, parts do
      OnlineQueue.push(sendRecordEvent, { rcCar = car, rcList = SYNC_CODES[list], rcSeq = seq % 65536, rcPart = i,
        rcParts = parts, rcText = text:sub((i - 1) * SYNC_PART + 1, i * SYNC_PART) }, target)
    end
  end

  -- A record of this car was saved: the others keep it
  function RecordSync.publish(list, seq, text)
    if not SYNC_CODES[list] then return end
    if list == 'track' then
      RecordSync.ownTrack = { seq = seq, text = text }
      return
    end
    queueRecord(ownSlot(), list, seq, text, nil)
  end

  -- New start of this script: ask the others for the records of this car
  function RecordSync.askOwn()
    RecordSync.askedT = state.ui.clock
    OnlineQueue.push(sendRecordEvent, { rcCar = ownSlot(), rcList = SYNC_REQUEST }, nil)
  end

  local function keepPeer(car, list, seq, text)
    local byCar = RecordSync.peers[car] or {}
    RecordSync.peers[car] = byCar
    local old = byCar[list]
    if not old or seq >= old.seq then byCar[list] = { seq = seq, text = text } end
  end

  local function onRecordText(car, list, text)
    local rec = Record.decode(text)
    if not rec or rec.list ~= list then return end
    if list == 'track' then
      -- Track record of another client, answering this start: the latest change wins (TrackList)
      if not RecordSync.askedT or state.ui.clock - RecordSync.askedT > SYNC_ANSWER_WINDOW then return end
      if not Record.sameSession(rec.key, Record.key()) then return end
      local p = RecordSync.pending.track
      if not p or rec.seq >= p.seq then RecordSync.pending.track = { body = rec.body, seq = rec.seq } end
      return
    end
    keepPeer(car, list, rec.seq, text)
    if car ~= ownSlot() or not RecordSync.askedT then return end
    if state.ui.clock - RecordSync.askedT > SYNC_ANSWER_WINDOW then return end
    if not Record.sameRace(rec.key, Record.key()) then return end
    local p = RecordSync.pending[list]
    if not p or rec.seq >= p.seq then RecordSync.pending[list] = { body = rec.body, seq = rec.seq } end
  end

  function RecordSync.receive(sender, msg)
    if sender and sender.index == 0 then return end
    if msg.rcList == SYNC_REQUEST then
      -- Another client asks for the records of its car: answer only to it
      if not sender then return end
      local own = RecordSync.ownTrack
      if own then queueRecord(ownSlot(), 'track', own.seq, own.text, sender.sessionID) end
      local byCar = RecordSync.peers[msg.rcCar]
      if not byCar then return end
      for _, list in ipairs(SYNC_LISTS) do
        local r = byCar[list]
        if r then queueRecord(msg.rcCar, list, r.seq, r.text, sender.sessionID) end
      end
      return
    end
    local list = SYNC_LISTS[msg.rcList]
    if not list or msg.rcParts < 1 then return end
    local id = msg.rcCar .. '/' .. list .. '/' .. msg.rcSeq
    local p = RecordSync.parts[id] or { count = 0 }
    RecordSync.parts[id] = p
    if not p[msg.rcPart] then
      p[msg.rcPart] = msg.rcText
      p.count = p.count + 1
    end
    if p.count < msg.rcParts then return end
    RecordSync.parts[id] = nil
    local chunks = {}
    for i = 1, msg.rcParts do chunks[i] = p[i] or '' end
    onRecordText(msg.rcCar, list, table.concat(chunks))
  end

  -- Applies the own records received from the others (sending is done by OnlineQueue)
  function RecordSync.update()
    for list, p in pairs(RecordSync.pending) do
      RecordSync.pending[list] = nil
      local restore = RecordSync.restorers[list]
      if restore then restore(p.body, p.seq, 'peers') end
    end
  end

  Record.onSave = RecordSync.publish
end
-- ============================================================
-- Pit record of the car: stops with service and the tow / repair hold in progress. Kept in the three layers of the
-- car record (this process, this computer, the other drivers), so a hold keeps counting in server time while one
-- driver leaves and another enters, or through a crash (the new connection gets the time left).
-- Body: <stops with service>|<last stop: lap/fuel added/tyres/repair>|<hold end, server ms (0 = none)>|<hold text>|
--       <pit stop in progress: start ms/end ms/plan (PitBox), or ->
-- ============================================================

local PitRecord = { stops = 0, last = '-' }
-- Set by PitBox: a pit stop in progress kept in the record goes on (start ms, end ms, plan)
PitRecord.onService = nil
local startHold

function PitRecord.save()
  local h = state.hold
  local text = h and tostring(h.text):gsub('|', '/') or ''
  PitRecord.seq = (PitRecord.seq or 0) + 1
  local sv = state.pitService
  Record.save('pit', PitRecord.seq, string.format('%d|%s|%d|%s|%s', PitRecord.stops, PitRecord.last,
    h and math.floor(h.untilMs) or 0, text,
    sv and string.format('%d/%d/%s', math.floor(sv.startMs), math.floor(sv.untilMs), sv.plan) or '-'))
end

-- A record of this process (script reload: the game hold is still running) or of another connection (the hold is
-- applied again for the time left)
local function pitApply(body, seq, newConnection)
  local stops, last, untilMs, text, service = tostring(body):match('^(%d+)|([^|]*)|(%d+)|([^|]*)|(.*)$')
  if not stops then return end
  local svStart, svUntil, svPlan = service:match('^(%d+)/(%d+)/(.+)$')
  if svStart and not state.pitService and PitRecord.onService then
    PitRecord.onService(tonumber(svStart), tonumber(svUntil), svPlan)
  end
  PitRecord.seq = math.max(PitRecord.seq or 0, seq or 0)
  PitRecord.stops = math.max(PitRecord.stops, tonumber(stops))
  PitRecord.last = last
  local left = (tonumber(untilMs) - serverTimeMs()) / 1000
  if left <= 0 or state.hold then return end
  if newConnection then
    startHold(left, text)
    ac.log(string.format('race-control: hold goes on after the new connection, %.0f s left', left))
  else
    state.hold = { untilMs = tonumber(untilMs), text = text }
  end
end

-- Session start or script reload
function PitRecord.load()
  PitRecord.stops, PitRecord.last, PitRecord.seq = 0, '-', 0
  local body, seq, source = Record.load('pit')
  if body then pitApply(body, seq, source ~= 'store') end
end

-- Locks the car in the pits (TeleportToPits) and shows the countdown in the message box. The teleport it causes is
-- not a driver teleport (ac.onCarJumped ignores it). The end is in server time and goes to the pit record.
startHold = function(seconds, text)
  state.tow.ownJumpUntil = state.ui.clock + 2
  physics.setCarPenalty(TELEPORT_TO_PITS, seconds)
  state.hold = { untilMs = serverTimeMs() + seconds * 1000, text = text }
  PitRecord.save()
end

-- Seconds left of the hold in progress
function PitRecord.holdLeft()
  return state.hold and math.max((state.hold.untilMs - serverTimeMs()) / 1000, 0) or 0
end

RecordSync.restorers.pit = function(body, seq)
  if seq < (PitRecord.seq or 0) then return end
  pitApply(body, seq, true)
end
-- Server message dictionary (lowercase, plain text; no bare "DT" so names and other words are not caught)
local DICT = {
  driveThrough = { 'drive-through', 'drive through', 'drivethrough', 'stop and go', 'stop-and-go', 'stop & go' },
  vsc = { 'virtual safety car' },   -- plus the whole word "vsc"
  sc = { 'safety car' },            -- checked after VSC
  code80 = { 'code-80', 'code 80', 'código-80', 'codigo-80', 'código 80', 'codigo 80', 'full course yellow' },
  green = { 'green flag', 'bandeira verde' },   -- end of CODE-80; checked first
  ended = { 'ended' },              -- with VSC / virtual safety car: end of CODE-80 (KMR: "Virtual Safety Car ended!")
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
  local isVSC = low:find('%f[%w]vsc%f[%W]') or hasAny(low, DICT.vsc)
  if isVSC and hasAny(low, DICT.ended) then return 'GREEN FLAG' end
  if isVSC then return 'VSC' end
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

-- ============================================================
-- Track list: CODE-80 (VSC / SC / CODE-80) or green, with the server time of the last change. It belongs to the race,
-- not to the car: it comes from the server chat, which the SDK does not keep, so a driver who enters during a CODE-80
-- (reconnection, restarted game, driver swap, first connection) gets it from the other drivers. Each client keeps its
-- own record; when a client starts, the others answer with theirs and the one with the latest change wins.
-- A script reload keeps it (ac.store). The file on this computer (ac.storage) is not used: while the game was closed
-- the chat was missed, so it may be old.
-- Body: <VSC|SC|CODE-80|GREEN>|<server time of the change, ms>
-- ============================================================

local TrackList = {
  since = -1,   -- server time (ms) of the change in force; -1 = nothing known
}

-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local function trackBody() return string.format('%s|%d', state.code80 or 'GREEN', math.floor(TrackList.since)) end

  local function trackSave()
    Record.save('track', math.floor(TrackList.since / 1000), trackBody())
  end

  -- CODE-80 started or ended in the chat of this client
  function TrackList.changed()
    TrackList.since = serverTimeMs()
    trackSave()
  end

  -- A track record (from this process or from the other drivers): applied when its change is newer than the one in force
  local function trackApply(body, source)
    local kind, since = tostring(body):match('^([%w%-]+)|(%d+)$')
    since = tonumber(since)
    if not since or since <= TrackList.since then return false end
    local code80 = kind ~= 'GREEN' and kind or nil
    if code80 and not CODE80_KINDS[code80] then return false end
    if state.code80 and not code80 then state.code80Ended = true end
    if code80 and not state.code80 then ac.log('race-control: CODE-80 start (' .. code80 .. ', ' .. source .. ')') end
    if not code80 and state.code80 then ac.log('race-control: CODE-80 end (' .. source .. ')') end
    state.code80 = code80
    TrackList.since = since
    return true
  end

  -- Session start or script reload: only the record of this process (ac.store)
  function TrackList.load()
    TrackList.since = -1
    local body, _, source = Record.load('track')
    if not body then return end
    if source == 'store' then
      trackApply(body, 'script reload')
    else
      ac.log('race-control: track record of this computer not used (the chat was missed): ' .. tostring(body))
    end
  end

  RecordSync.restorers.track = function(body)
    if trackApply(body, 'other drivers') then
      ac.log('race-control: track restored from the other drivers: ' .. trackBody())
      trackSave()
    end
  end
end
-- ACSM driver swap messages to the driver taking the car (race_control.go, handleDriverSwap). Returns true if handled.
local function onDriverSwapMessage(message)
  local low = message:lower()
  local wait = low:match('please wait (%S+) before leaving the pits') or low:match('^free to leave pits in (%S+)')
  if wait then
    local seconds = parseGoDuration(wait)
    state.swap.entered = true
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
    -- ACSM penalty for leaving the pits early (time penalty, or kick = DSQ by the ACSM): shown in the penalty message box
    -- and kept in the log; applied by the ACSM, not by this script
    state.swap.remaining = nil
    showNotice(TEXTS.rcTitle, message, nil, SERVER_NOTICE_SECONDS)
    local kicked = low:find('kicked', 1, true) ~= nil
    ac.log('race-control: ACSM driver swap penalty: ' .. message)
    rcLog(kicked and 'Disqualified by ACSM' or 'ACSM penalty', message)
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
-- Seconds after the connection at which SWAP_INFO is sent (again), in case the new driver's script is not running yet
local SWAP_RELAY_DELAYS = { 1, 4, 10 }

-- Name code: same number on every client, to compare drivers without sending their names
local function nameCode(name)
  local h = 5381
  name = tostring(name or '')
  for i = 1, #name do h = (h * 33 + name:byte(i)) % 4294967296 end
  return h
end

-- Swap record of the car: <swaps>|<valid swaps>|<swap number of the driver in command>|<name code of that driver>
local SwapRecord = {}
function SwapRecord.save()
  local sw = state.swap
  Record.save('swap', math.floor(serverTimeMs() / 1000), string.format('%d|%d|%d|%d', sw.count, sw.valid, sw.swapNo,
    sw.driver))
end
-- A swap record (this computer or the other drivers; an old one holds only the swaps): the higher counts win, and the
-- driver in command comes from the record with the most swaps
function SwapRecord.apply(body)
  local sw = state.swap
  local count, valid, swapNo, driver = tostring(body or ''):match('^(%d+)|?(%d*)|?(%d*)|?(%d*)$')
  if not count then return end
  count = tonumber(count)
  if count >= sw.count then
    sw.swapNo = tonumber(swapNo) or count
    sw.driver = tonumber(driver) or 0
  end
  sw.count = math.max(sw.count, count)
  sw.valid = math.max(sw.valid, tonumber(valid) or count)
end

local function onSwapInfo(msg)
  local sw = state.swap
  if not config.swapOn() then return end
  if msg.pcType ~= MSG_SWAP_INFO or msg.pcCar ~= ac.getCar(0).sessionID then return end
  if msg.pcDriver == nameCode(ac.getDriverName(0)) then
    ac.log('race-control: swap relay: same driver reconnected, no countdown')
    return
  end
  -- The swap itself, the same in every repeated message: counted once (the peers already counted this one). Valid only
  -- if the car entered the pit lane inside the pit window (decision 112); the driver table records it (DriverTable)
  if not sw.swapInfo then
    sw.swapInfo = { inWindow = msg.pcInWindow == 1 }
    sw.entered = true
    sw.count = math.max(sw.count, msg.pcSwaps or 0)
    sw.valid = math.max(sw.valid, msg.pcValid or 0)
    ac.log(string.format('race-control: driver swap %d, %s', sw.count,
      sw.swapInfo.inWindow and 'valid' or 'pit entry outside the pit window: not valid'))
  end
  -- Already counting (first message received, or the ACSM message): the others are the same information
  if sw.remaining or sw.clearUntil then return end
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
  pcValid = ac.StructItem.uint8(),
  pcInWindow = ac.StructItem.uint8(),
}, function(sender, msg)
  -- Own messages come back too (sender.index 0): ignored
  if sender and sender.index == 0 then return end
  onSwapInfo(msg)
end, nil, nil, { processPostponed = true })

ac.onClientDisconnected(function(carIndex, sessionID)
  if not config.swapOn() or carIndex == 0 then return end
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
  -- Valid swap: the car entered the pit lane inside the pit window (PitStops; unknown entry = valid)
  local inWindow = sw.pitEntryValid[carIndex] ~= false
  if inWindow then sw.carValid[carIndex] = (sw.carValid[carIndex] or 0) + 1 end
  for _, delay in ipairs(SWAP_RELAY_DELAYS) do
    sw.relay[#sw.relay + 1] = { target = sessionID, car = sessionID, driver = rec.driver, leftT = rec.t,
      swaps = sw.carSwaps[carIndex] or 0, valid = sw.carValid[carIndex] or 0, inWindow = inWindow,
      list = sw.carLists[carIndex], dueT = state.ui.clock + delay }
  end
end)

local sendPenaltyList, publishOwnList
-- Penalty list carried to the next driver (penalties belong to the car). The driver parked at the pit place publishes
-- the list; every other client keeps the last list of each car and, when a different driver enters that car, sends
-- it only to the new driver together with SWAP_INFO. Fixed size: up to PENALTY_LIST_MAX items, category code + laps.
-- The new driver takes it over only with wrongDriverSeconds empty: otherwise only the driver who caused a penalty pays
-- it (WrongDriver).
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local PENALTY_LIST_MAX = 4
  local CAT_CODES = { PSE = 1, SD1 = 2, SD2 = 3 }
  local CAT_NAMES = { 'PSE', 'SD1', 'SD2' }

  local function applyPenaltyList(msg)
    local sw = state.swap
    if not config.swapOn() then return end
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
      if sender and config.swapOn() then
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
    OnlineQueue.push(sendPenaltyListEvent, msg, target)
  end

  -- Driver parked at the pit place in a race: publishes the own list (again if it changes while parked)
  publishOwnList = function(car)
    local sw = state.swap
    if not config.swapOn() or not car.isInPit then
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
end
-- Sends the scheduled SWAP_INFO messages and keeps the last known name of each driver
local function updateSwapRelay()
  local sw = state.swap
  if not config.swapOn() then return end
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
      OnlineQueue.push(sendSwapInfo, { pcType = MSG_SWAP_INFO, pcCar = r.car, pcDriver = r.driver, pcElapsed = elapsed,
        pcSwaps = math.min(r.swaps, 255), pcValid = math.min(r.valid, 255), pcInWindow = r.inWindow and 1 or 0 }, r.target)
      if r.list and r.list.count > 0 then sendPenaltyList(r.list, r.car, r.target) end
    end
  end
end

-- Chat: Race Control lines are for the server log only, hidden from the chat of every client. Server messages
-- (senderCarIndex = -1, KMR or ACSM) that match the dictionary are also shown in the penalty message box, and the
-- ACSM driver swap messages feed the driver swap panel; everything stays in the chat.
ac.onChatMessage(function(message, senderCarIndex)
  if type(message) ~= 'string' then return false end
  if message:sub(1, #TEXTS.rcPrefix) == TEXTS.rcPrefix then
    -- Race director client (admin): an edited record file is banned (/ban <car ID>, ACSM)
    local car = config.isDirector and message:find(TEXTS.editedFile, 1, true)
      and message:match('car (%d+) %- ban pending')
    if car then
      queueCommand('/ban ' .. car)
      ac.log('race-control: ban sent for car ' .. car .. ' (edited file)')
    end
    return true
  end
  -- Race Control command (RcCommand): only from the server (ACSM live timing, admin); hidden from the chat
  if senderCarIndex == -1 and message:match('^%s*[Rr][Cc]%s') then
    state.rcCommands[#state.rcCommands + 1] = message
    return true
  end
  if senderCarIndex == -1 and onDriverSwapMessage(message) then return false end
  if senderCarIndex == -1 then
    local kind = classifyServerMessage(message)
    if kind == 'DT' then
      local prefix = tostring(ac.getDriverName(0) or '') .. ':'
      local text = message
      if message:sub(1, #prefix) == prefix then text = message:sub(#prefix + 1):gsub('^%s+', '') end
      showNotice(TEXTS.kmrTitle, text, nil, SERVER_NOTICE_SECONDS)
      state.kmrMessages[#state.kmrMessages + 1] = text
    elseif kind then
      if CODE80_KINDS[kind] then
        if not state.code80 then ac.log('race-control: CODE-80 start (' .. kind .. ')') end
        if state.code80 ~= kind then
          state.code80 = kind
          TrackList.changed()
        end
      elseif kind == 'GREEN FLAG' and state.code80 then
        state.code80 = nil
        state.code80Ended = true
        TrackList.changed()
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
-- Nothing of the list goes to the game (decision 78): the panel shows it. The script writes to the game only for the
-- hold and for the DSQs (the game black flag).
-- Pit pass payment: at the line inside the pit, position 0 leaves the table (rule 3).
-- PSE: pit lane speeding measured by the script (PitSpeed), entered at the pit exit.
-- ============================================================

local Rules = {}

-- Body: seq|0 (was the item in the game; kept for the record format)|lap|owner|dsq|dsq stage|dsq until (server ms)|
-- wrong driver|wrong since (server ms)|items
local function listSave()
  local l = state.list
  local parts = {}
  for _, it in ipairs(l.items) do
    parts[#parts + 1] = string.format('%s,%s,%d,%d,%d,%d,%d', it.cat, it.kind, it.laps, it.givenLap, it.expireLap,
      it.seq, it.dt0OnTrack and 1 or 0)
  end
  local w = l.wrong
  Record.save('penalties', l.seq, string.format('%d|0|%d|%d|%d|%d|%d|%d|%d|%s', l.seq, l.curLap,
    l.owner or 0, l.dsq, l.dsqStage, math.floor(l.dsqUntil), w and w.driver or 0, w and math.floor(w.since) or 0,
    table.concat(parts, ';')))
end

-- Applies a saved list. From another process (the game was closed: car.lapCount started again from zero) the laps of
-- each item are moved to the current lap count, keeping the deadlines.
local function listApply(data, source)
  local l = state.list
  l.items = {}
  l.seq = 0
  l.owner = nil
  l.dsq = 0
  l.dsqStage = 0
  l.dsqUntil = 0
  l.wrong = nil
  if type(data) ~= 'string' then return end
  local seqPart, _, lapPart, ownerPart, dsqPart, stagePart, untilPart, wrongPart, sincePart, itemsPart =
    data:match('^(%d+)|(%d+)|(%-?%d+)|(%d+)|(%d)|(%d)|(%d+)|(%d+)|(%d+)|(.*)$')
  if not itemsPart then return end
  l.seq = tonumber(seqPart)
  l.owner = tonumber(ownerPart) ~= 0 and tonumber(ownerPart) or nil
  l.dsq = tonumber(dsqPart)
  l.dsqStage = tonumber(stagePart)
  l.dsqUntil = tonumber(untilPart)
  l.dsqLap = ac.getCar(0).lapCount
  if tonumber(wrongPart) ~= 0 then l.wrong = { driver = tonumber(wrongPart), since = tonumber(sincePart) } end
  local lapNow = ac.getCar(0).lapCount
  local shift = lapNow < tonumber(lapPart) and lapNow - tonumber(lapPart) or 0
  for cat, kind, laps, givenLap, expireLap, seq, onTrack in
      itemsPart:gmatch('(%w+),(%w+),(%-?%d+),(%-?%d+),(%-?%d+),(%d+),(%d)') do
    l.items[#l.items + 1] = { cat = cat, kind = kind, laps = tonumber(laps), givenLap = tonumber(givenLap) + shift,
      expireLap = tonumber(expireLap) + shift, seq = tonumber(seq), dt0OnTrack = onTrack == '1' }
  end
  if shift ~= 0 then
    ac.log(string.format('race-control: penalty list moved %d laps (new connection)', shift))
  end
end

local function listLoad()
  local data, _, source = Record.load('penalties')
  listApply(data, source)
end

-- Rule 3: DT0 before DT1; same deadline, the oldest first
local function listSort()
  table.sort(state.list.items, function(a, b)
    if a.laps ~= b.laps then return a.laps < b.laps end
    return a.seq < b.seq
  end)
end

-- Stop & go item of the list (stopAndGo mode SG), if any. Category 'SG<n>' (n = drive-throughs it holds), kind 'SG'
-- or, once the car has stopped for it, 'SGs<ms served>t<server s>d<driver code>'
local function sgItem()
  for _, it in ipairs(state.list.items) do
    if it.kind:sub(1, 2) == 'SG' then return it end
  end
  return nil
end
local function sgCount(it) return tonumber(it.cat:match('^SG(%d+)$')) or 0 end
-- KMR categories held by the stop & go: kind suffix "x<n>x<n>..." (for the served lines in the log)
local function sgKmrSuffix(it) return it.kind:match('(x[%dx]+)$') or '' end
local function sgSeconds(it) return sgCount(it) * config.sgSecondsPerDT end

-- Reason of a category in the log: the KMR ones say who issued them
local function reasonLog(cat)
  local base = TEXTS.kmrReasons[cat]
  return base and (base .. ' (issued by KMR)') or tostring(TEXTS.reason[cat] or cat)
end

-- Given lap = current lap; expire lap = given lap + deadline (the DSQ applies when that lap ends unpaid).
-- With a stop & go in the list, a new penalty is added to it (+secondsPerDT), with no new item; over maxDT: DSQ at
-- once (rule 21). After a DSQ a new infraction is only logged (decision 17).
local function listAdd(cat, laps)
  local l = state.list
  if state.dtDsqActive or state.pitDsqActive then
    ac.log(string.format('race-control: %s after the DSQ: logged, not applied', cat))
    return nil
  end
  local sg = config.sg and sgItem()
  if sg then
    local n = sgCount(sg) + 1
    sg.cat = 'SG' .. n
    if TEXTS.kmrReasons[cat] then sg.kind = sg.kind .. 'x' .. cat:sub(2) end
    l.seq = l.seq + 1
    sg.seq = l.seq
    ac.log(string.format('race-control: stop & go +1 (%s): %d DT, %d s', cat, n, sgSeconds(sg)))
    rcLog(string.format('Stop & go %d s', sgSeconds(sg)), 'includes ' .. reasonLog(cat))
    if n == config.sgMaxDT + 1 then Rules.sgOverLimit(n) end
    return sg
  end
  l.seq = l.seq + 1
  -- The driver in the car when the list starts is the one who pays it
  if #l.items == 0 or not l.owner then l.owner = nameCode(ac.getDriverName(0)) end
  local item = { cat = cat, kind = 'DT', laps = laps, givenLap = l.curLap, expireLap = l.curLap + laps, seq = l.seq,
    dt0OnTrack = false }
  l.items[#l.items + 1] = item
  return item
end

-- Table in the log: position:category/kind/deadline/given lap/expire lap
local function listDump()
  local l = state.list
  local parts = {}
  for i, it in ipairs(l.items) do
    parts[#parts + 1] = string.format('%d:%s/%s/%d/%d/%d', i - 1, it.cat, it.kind, it.laps, it.givenLap,
      it.expireLap)
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
  if #l.items == 0 then
    l.owner = nil
    l.wrong = nil
  end
end

-- The list is void: clear it, including the slowdowns in progress
function Rules.zero()
  local l = state.list
  l.items = {}
  l.endOfLap = {}
  l.owner = nil
  l.wrong = nil
  state.slowdowns = {}
  listSave()
end

-- Removes a DT from the game (only one an older version left there: nothing of the list goes to the game).
-- MandatoryPits with parameter 0 removes the DT (original script header); None did not remove it (log 25/09 02:25).
local function clearGamePenalty()
  physics.setCarPenalty(MANDATORY_PITS, 0)
end

-- DSQ of the car (kind 1; 2 = pit exit with the session closed): list cleared, black flag drawn by the script with
-- the reason and what to do. The game black flag comes only if the driver does not do it (DsqFlow): stop at the pit
-- place before the line (mode 'line'), or tow to the pits within dsqTowSeconds (mode 'tow'). Kept in the car record for
-- the session: a driver who connects to the car later is still disqualified
local function carDsq(kind, reason, mode, detail)
  local l = state.list
  l.dsq = kind or 1
  l.dsqStage = mode == 'tow' and 2 or 0
  l.dsqUntil = mode == 'tow' and serverTimeMs() + config.dsqTowSeconds * 1000 or 0
  l.dsqLap = ac.getCar(0).lapCount
  l.dsqReason = reason
  l.seq = l.seq + 1
  if l.dsq == 2 then state.pitDsqActive = true else state.dtDsqActive = true end
  Rules.zero()
  rcLog('Disqualified', detail and (reason .. ' - ' .. detail) or reason)
end

-- Game black flag (the game DSQ): always with the controls locked; the car cannot go back to the race
local DSQ_LOCK_SECONDS = 86400
local function dsqGameFlag(why, rcReason, inGame)
  local l = state.list
  -- A black flag the game already shows is not written again (inGame); the controls are locked either way
  if not inGame then physics.setCarPenalty(BLACK_FLAG) end
  physics.lockUserControlsFor(DSQ_LOCK_SECONDS)
  l.dsqStage = 1
  listSave()
  ac.log('race-control: DSQ black flag in the game, controls locked (' .. why .. ')')
  if rcReason then rcLog('Disqualified', rcReason) end
end


-- Pending DT0. Race: deadline 0 (as in the published version). Practice and qualifying: an overdue one (below 0) is
-- still a DT0, since the deadline over does not disqualify there (rule 25)
local function pendingDT0()
  local race = sim.raceSessionType == ac.SessionType.Race
  local out = {}
  for _, it in ipairs(state.list.items) do
    if it.laps == 0 or (not race and it.laps < 0) then out[#out + 1] = it end
  end
  return out
end

local function hasLongHold(items)
  for _, it in ipairs(items) do
    if it.cat == 'PSE' and it.dt0OnTrack then return true end
  end
  return false
end

-- Rule 5: hold, clears the list
local function applyHold(long)
  local seconds = long and config.holdLong or config.holdShort
  local reason = long and TEXTS.holdTwoDTLong or TEXTS.holdTwoDT
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
  local r = config.repair
  local factor = (config.tow[sim.raceSessionType] or {}).repairFactor or 0
  if not d then return 0 end
  local s = factor * (r.base * (r.wEngine * d.powertrain + r.wSuspension * d.suspension) + r.wBody * d.body)
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

-- ============================================================
-- Car state (front B): the physical state belongs to the car, not to the driver. The game gives a new car on every new
-- connection (reconnection, restarted game) and on a driver swap ("Driver swaps currently reset all vehicle damage, fuel
-- status etc."), so the script keeps the car record and puts it back with the game physics (the car mod is untouched).
-- Saved: at every line crossing, when the car stops at its pit place (the driver leaving on a swap), 2 s after the
-- damage changes, and before a teleport (the state of the frame before it). Kept in the three layers of the car record
-- (this process, this computer, the other drivers).
-- Applied after a new start, once, with the car stopped at its pit place (car.isInPit) before it drives off; a record
-- that arrives later from the other drivers (newer) is applied while the car is still stopped. The new car is never
-- saved before that: it would overwrite the record. Practice: leaving and coming back resets (nothing is applied).
-- Put back: fuel, compound, tyre wear (virtual km per wheel), body, engine, suspension, and the collision damage not
-- repaired yet (charged by the tow and repair hold). Gearbox: recorded, no game function to put it back.
-- Suspension damage by angle: per wheel, % = max(|toe - toe0|, |camber - camber0|) / 90 deg * 100 (max 100), toe0 and
-- camber0 = the wheel with no suspension damage (setup). The game function takes a hit speed in km/h, so the script
-- searches the km/h that gives the recorded % (doubling, then halving), with the car stopped at its pit place. The km/h
-- found is kept in the table (V) and written directly the next time (checked against the angle; searched again if
-- the angle does not match). A new suspension damage on the wheel clears it.
-- Body: F<fuel l>|C<compound>|K<km FL,FR,RL,RR>|B<body 0..4 km/h>|S<suspension % per wheel>|R<suspension 0..1 read>|
--       O<toe0/camber0 per wheel>|E<engine life>|G<gearbox>|T<collision damage powertrain,suspension,body>|
--       D<line crossings left for the required repair, -1 = none>|V<suspension km/h per wheel, -1 = not known>|
--       H<server ms of the warning of damage beyond the safety limit, -1 = none>
-- ============================================================

local CarState = {
  seq = 0,
  restoring = false,   -- new start: waiting to put the record back before saving the car
  startT = 0,
  pending = nil,       -- { body, seq, source } record to put back
  appliedSeq = -1,
  prevParked = false,
  damageSig = nil,
  dirtyT = nil,        -- clock of the last damage change not saved yet
  lastBody = nil,      -- state of the last frame (saved on a teleport, before the game changes the car)
  orig = {},           -- [wheel] = { toe, camber } with no suspension damage
  search = nil,        -- suspension being put back: [wheel] = { target %, lo, hi, kmh, steps, wait }
  suspKmh = {},        -- [wheel] = km/h that gives the suspension damage of the wheel (known after putting it back)
  suspRaw = {},        -- [wheel] = suspension damage read (0..1) when suspKmh was known
}
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local CAR_RESTORE_WINDOW = 30   -- seconds after the start in which a record of the other drivers is still applied
  local CAR_DAMAGE_SETTLE = 2     -- seconds after the last damage change before saving
  local SUSP_MAX_ANGLE = 90       -- degrees: 100% suspension damage
  local SUSP_TOLERANCE = 0.1      -- % of difference accepted when putting the suspension back
  local SUSP_FIRST_KMH = 50
  local SUSP_MAX_KMH = 3200
  local SUSP_STEPS = 16           -- halvings after the doubling
  local SUSP_WAIT_FRAMES = 2      -- frames for the physics to show a new suspension damage

  local num = CarRead.num

  local function list(text)
    local out = {}
    for v in tostring(text or ''):gmatch('[^,]+') do out[#out + 1] = v end
    return out
  end

  -- Suspension damage of a wheel in %, by angle (nil while the wheel has no reference)
  local function suspPercent(car, i, orig)
    local w = car.wheels and car.wheels[i]
    local o = orig or CarState.orig[i]
    if not w or not o then return nil end
    local dev = math.max(math.abs(num(w.toeIn) - o.toe), math.abs(num(w.camber) - o.camber))
    return math.min(dev / SUSP_MAX_ANGLE, 1) * 100
  end
  CarState.suspPercent = suspPercent

  local function carBody(car)
    local km, body, pct, raw, orig, kmh = {}, {}, {}, {}, {}, {}
    for i = 0, 3 do
      km[#km + 1] = string.format('%.2f', num(car.wheels and car.wheels[i] and car.wheels[i].tyreVirtualKM))
      pct[#pct + 1] = string.format('%.2f', suspPercent(car, i) or 0)
      raw[#raw + 1] = string.format('%.3f', num(car.suspensionDamage[i]))
      local o = CarState.orig[i]
      orig[#orig + 1] = o and string.format('%.3f/%.3f', o.toe, o.camber) or '-'
      kmh[#kmh + 1] = string.format('%.3f', CarState.suspKmh[i] or -1)
    end
    for i = 0, 4 do body[#body + 1] = string.format('%.1f', num(car.damage[i])) end
    local d = state.tow.damage or { powertrain = 0, suspension = 0, body = 0 }
    return string.format('F%.1f|C%d|K%s|B%s|S%s|R%s|O%s|E%.0f|G%.3f|T%.3f,%.3f,%.1f|D%d|V%s|H%d', num(car.fuel),
      num(car.compoundIndex), table.concat(km, ','), table.concat(body, ','), table.concat(pct, ','),
      table.concat(raw, ','), table.concat(orig, ','), num(car.engineLifeLeft), num(car.gearboxDamage), d.powertrain,
      d.suspension, d.body, state.repair.lapsLeft or -1, table.concat(kmh, ','),
      state.repair.beyondSince and math.floor(state.repair.beyondSince) or -1)
  end

  local function carParse(body)
    local f, c, k, b, s, r, o, e, g, t, dl, v, h = tostring(body):match(
      '^F([%d%.]+)|C(%d+)|K([^|]*)|B([^|]*)|S([^|]*)|R([^|]*)|O([^|]*)|E([%d%.]+)|G([%d%.]+)|T([^|]*)|D(%-?%d+)|V([^|]*)|H(%-?%d+)$')
    if not f then return nil end
    local orig = {}
    for i, v in ipairs(list(o)) do
      local toe, camber = v:match('^([%-%d%.]+)/([%-%d%.]+)$')
      if toe then orig[i - 1] = { toe = tonumber(toe), camber = tonumber(camber) } end
    end
    local function nums(text)
      local out = {}
      for i, v in ipairs(list(text)) do out[i] = tonumber(v) or 0 end
      return out
    end
    return { fuel = tonumber(f), compound = tonumber(c), km = nums(k), body = nums(b), pct = nums(s), raw = nums(r),
      orig = orig, engine = tonumber(e), gearbox = tonumber(g), tow = nums(t), repairLaps = tonumber(dl), kmh = nums(v),
      beyondSince = tonumber(h) }
  end

  local function damageSig(car)
    local parts = {}
    for i = 0, 4 do parts[#parts + 1] = string.format('%.1f', num(car.damage[i])) end
    for i = 0, 3 do parts[#parts + 1] = string.format('%.3f', num(car.suspensionDamage[i])) end
    parts[#parts + 1] = string.format('%.0f|%.3f', num(car.engineLifeLeft), num(car.gearboxDamage))
    return table.concat(parts, ',')
  end

  local function saveBody(body)
    CarState.seq = CarState.seq + 1
    Record.save('car', CarState.seq, body)
    CarState.dirtyT = nil
  end

  local function carSave(car)
    saveBody(carBody(car))
    CarState.damageSig = damageSig(car)
  end

  -- Teleport (ac.onCarJumped): the state of the frame before it goes to the record
  state.onJumped[#state.onJumped + 1] = function()
    if CarState.restoring or not CarState.lastBody then return end
    saveBody(CarState.lastBody)
    ac.log('race-control: car state saved before the teleport')
  end

  -- Suspension being put back: one step of the km/h search per wheel, every SUSP_WAIT_FRAMES frames
  local function suspSearch(car)
    local open = false
    for i, s in pairs(CarState.search) do
      if s.wait > 0 then
        s.wait = s.wait - 1
        open = true
      else
        local got = suspPercent(car, i) or 0
        local done = math.abs(got - s.target) <= SUSP_TOLERANCE
        if not done then
          if s.growing then
            if got < s.target and s.kmh < SUSP_MAX_KMH then
              s.lo, s.kmh = s.kmh, s.kmh * 2
            else
              s.growing = false
              s.hi = s.kmh
            end
          else
            if got < s.target then s.lo = s.kmh else s.hi = s.kmh end
            s.steps = s.steps + 1
          end
          if not s.growing then
            if s.steps >= SUSP_STEPS then done = true else s.kmh = (s.lo + s.hi) / 2 end
          end
        end
        if not done and s.direct then
          -- The km/h of the table did not give the angle: search it
          s.direct, s.growing, s.lo, s.kmh, s.steps = false, true, 0, SUSP_FIRST_KMH, 0
        elseif done then
          ac.log(string.format('race-control: suspension %d put back: %.2f%% (record %.2f%%, %.3f km/h%s)', i, got,
            s.target, s.kmh, s.direct and ', from the table' or ''))
          CarState.suspKmh[i] = s.kmh
          CarState.suspRaw[i] = num(car.suspensionDamage[i])
          CarState.search[i] = nil
        else
          physics.setSuspensionDamage(0, i, s.kmh)
          s.wait = SUSP_WAIT_FRAMES
          open = true
        end
      end
    end
    if not open then CarState.search = nil end
  end

  -- Puts the record back on the car of this driver
  local function carApply(car, p)
    local r = carParse(p.body)
    if not r then
      ac.log('race-control: car record not understood: ' .. tostring(p.body))
      return
    end
    physics.setCarFuel(0, r.fuel)
    if r.compound ~= num(car.compoundIndex) then physics.setTyresCompound(0, nil, r.compound) end
    for i = 0, 3 do physics.setTyresVirtualKM(0, i, r.km[i + 1] or 0) end
    physics.setCarBodyDamage(0, vec4(r.body[1] or 0, r.body[2] or 0, r.body[3] or 0, r.body[4] or 0))
    physics.setCarEngineLife(0, r.engine)
    local t = r.tow
    if (t[1] or 0) > 0 or (t[2] or 0) > 0 or (t[3] or 0) > 0 then
      state.tow.damage = { powertrain = t[1] or 0, suspension = t[2] or 0, body = t[3] or 0 }
    end
    -- Suspension: reference of this car (setup of this driver) or, without it, the one in the record
    CarState.search = nil
    for i = 0, 3 do
      if not CarState.orig[i] then CarState.orig[i] = r.orig[i] end
      local target = r.pct[i + 1] or 0
      local now = suspPercent(car, i) or 0
      if CarState.orig[i] and math.abs(target - now) > SUSP_TOLERANCE then
        CarState.search = CarState.search or {}
        local known = r.kmh[i + 1] and r.kmh[i + 1] >= 0 and r.kmh[i + 1] or nil
        CarState.search[i] = { target = target, lo = 0, kmh = known or (target > 0 and SUSP_FIRST_KMH or 0), steps = 0,
          growing = not known and target > 0, direct = known ~= nil, wait = SUSP_WAIT_FRAMES }
        physics.setSuspensionDamage(0, i, CarState.search[i].kmh)
      end
    end
    -- Required repair still running (orange disc): the deadline goes on where it was
    if r.repairLaps and r.repairLaps >= 0 then state.repair.lapsLeft = r.repairLaps end
    -- Warning of damage beyond the safety limit: the internal timer goes on where it was
    if r.beyondSince and r.beyondSince >= 0 then state.repair.beyondSince = r.beyondSince end
    -- The damage put back is not collision damage of this connection
    state.tow.lastRead = nil
    CarState.appliedSeq = p.seq
    CarState.seq = math.max(CarState.seq, p.seq)
    ac.log(string.format('race-control: car state put back (%s, seq %d): %s', p.source, p.seq, p.body))
    if (r.gearbox or 0) > 0 then ac.log('race-control: car state not put back (no game function for it): gearbox') end
  end

  -- The car is the car of the record: nothing waiting to be put back (or the record already put back)
  function CarState.ready()
    return not CarState.restoring or (CarState.pending ~= nil and CarState.pending.seq == CarState.appliedSeq
      and not CarState.search)
  end

  -- Session start or script reload
  function CarState.load()
    CarState.pending = nil
    CarState.appliedSeq = -1
    CarState.dirtyT = nil
    CarState.damageSig = nil
    CarState.lastBody = nil
    CarState.search = nil
    CarState.startT = state.ui.clock
    local body, seq, source = Record.load('car')
    CarState.seq = seq or 0
    if source == 'store' then
      -- Script reload in the same connection: the car is the same; the suspension reference comes from the record
      CarState.restoring = false
      local r = carParse(body)
      if r then
        for i = 0, 3 do CarState.orig[i] = CarState.orig[i] or r.orig[i] end
      end
      return
    end
    CarState.restoring = true
    if body then CarState.pending = { body = body, seq = seq, source = 'this computer' } end
  end

  -- The car record kept by the other drivers: only while the car is waiting to be put back
  RecordSync.restorers.car = function(body, seq)
    if not CarState.restoring then return end
    if CarState.pending and seq < CarState.pending.seq then return end
    CarState.pending = { body = body, seq = seq, source = 'other drivers' }
    CarState.seq = math.max(CarState.seq, seq)
  end

  function CarState.update(car, lineFrame)
    local parked = CarRead.parked(car)
    -- Suspension reference: each wheel while it has no suspension damage. A new damage clears the km/h kept
    for i = 0, 3 do
      local w = car.wheels and car.wheels[i]
      local searching = CarState.search and CarState.search[i]
      if w and num(car.suspensionDamage[i]) == 0 and not searching then
        CarState.orig[i] = { toe = num(w.toeIn), camber = num(w.camber) }
      end
      if not searching and CarState.suspKmh[i] and num(car.suspensionDamage[i]) ~= CarState.suspRaw[i] then
        CarState.suspKmh[i] = nil
        CarState.suspRaw[i] = nil
      end
    end
    if CarState.restoring then
      local practice = sim.raceSessionType == ac.SessionType.Practice
      if practice then
        CarState.restoring = false
        if CarState.pending then ac.log('race-control: car state not put back: practice resets on leaving') end
        CarState.pending = nil
      elseif not CarRead.parked(car) then
        CarState.restoring = false
        if CarState.search then ac.log('race-control: suspension not put back: the car left the pit place') end
        CarState.search = nil
        if CarState.pending and CarState.pending.seq ~= CarState.appliedSeq then
          ac.log('race-control: car state not put back: the car left the pit place')
        end
        CarState.pending = nil
      elseif parked and CarState.pending and CarState.pending.seq ~= CarState.appliedSeq then
        carApply(car, CarState.pending)
      elseif CarState.search then
        suspSearch(car)
      elseif state.ui.clock - CarState.startT > CAR_RESTORE_WINDOW then
        CarState.restoring = false
      end
      if CarState.restoring then return end
      CarState.prevParked = parked
      CarState.damageSig = damageSig(car)
      CarState.lastBody = carBody(car)
      return
    end
    -- Saving: line crossing, stop at the pit place, damage settled
    local sig = damageSig(car)
    if sig ~= CarState.damageSig then
      CarState.damageSig = sig
      CarState.dirtyT = state.ui.clock
    end
    -- During a tow or repair hold the car is not saved: it is repaired there and the repair is paid by the hold; saved
    -- when the hold ends (the damage change is still pending)
    if state.hold then
      if parked then CarState.dirtyT = CarState.dirtyT or state.ui.clock end
    elseif lineFrame then
      carSave(car)
    elseif parked and not CarState.prevParked then
      carSave(car)
    elseif CarState.dirtyT and state.ui.clock - CarState.dirtyT >= CAR_DAMAGE_SETTLE then
      carSave(car)
    end
    CarState.prevParked = parked
    CarState.lastBody = carBody(car)
  end
end
-- ============================================================
-- Damage class (front B, qualifying and race, like the tow and repair):
--   Normal: toe and camber up to damage toeBent / camberBent over the setup, body up to bodyRepair, no puncture.
--   Repair required (black flag with orange disc, drawn by the script: the game flag "does not work yet"): toe or camber
--     over the bent limit, body over bodyRepair on a side, or 1 to maxPunctured punctured tyres (the repair
--     changes the 4). repairLaps line crossings to repair it; still not repaired at the last one: DSQ (at the
--     line). The disc goes when the car is back to Normal (repaired in a stop, or by the tow).
--   Beyond the safety limit: toe or camber over toeBroken / camberBroken, or more than maxPunctured
--     punctured: stop off track and return to the pits by the tow (the repair is charged in the pits). Internal timers
--     (not shown), by the driver's attitude: beyondTowSeconds after the warning without the tow = our DSQ (safety
--     hazard) asking for the tow and warning of unsporting behaviour; dsqTowSeconds more = game black flag (DsqFlow).
-- Toe and camber over the setup: CarState.orig (the wheel with no suspension damage). Body sides: car.damage[0..3]
-- = front, rear, left, right (AC shared memory order). Missing wheel: the game physics has no detached wheel and the
-- SDK no field for it (only the punctured tyre, isBlown); the check is kept for a future physics and has no effect today.
-- CODE-80: a stop is allowed under yellow, SC and VSC for everything, so the repair deadline does not stop.
-- ============================================================

local DamageClass = {}
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local WHEEL_NAMES = { [0] = 'front left', 'front right', 'rear left', 'rear right' }
  local BODY_SIDES = { [0] = 'front', 'rear', 'left', 'right' }

  local num = CarRead.num

  -- Missing wheel: always false with the current game physics (no detached wheel, no SDK field)
  local function wheelMissing(car, i) return false end

  -- Class and reason of the car now: 'normal', 'repair' or 'beyond', with the texts of the box
  local function classify(car)
    local worst = { class = 'normal' }
    local function consider(class, text, detail)
      local rank = { normal = 0, repair = 1, beyond = 2 }
      if rank[class] > rank[worst.class] then worst = { class = class, text = text, detail = detail } end
    end
    for i = 0, 3 do
      local w = car.wheels and car.wheels[i]
      local o = CarState.orig[i]
      if w and o then
        local toe = math.abs(num(w.toeIn) - o.toe)
        local camber = math.abs(num(w.camber) - o.camber)
        local what, dev, bent, broken = 'toe', toe, config.damage.toeBent, config.damage.toeBroken
        if camber / config.damage.camberBent > toe / config.damage.toeBent then
          what, dev, bent, broken = 'camber', camber, config.damage.camberBent, config.damage.camberBroken
        end
        local detail = string.format(TEXTS.damageAngle, what, dev)
        if dev > broken then
          consider('beyond', string.format(TEXTS.damageSuspension, WHEEL_NAMES[i]), detail)
        elseif dev > bent then
          consider('repair', string.format(TEXTS.damageBent, WHEEL_NAMES[i]), detail)
        end
      end
    end
    for i = 0, 3 do
      local d = num(car.damage[i])
      if d > config.damage.bodyRepair then
        consider('repair', string.format(TEXTS.damageBody, BODY_SIDES[i], d),
          string.format(TEXTS.damageBodyLimit, config.damage.bodyRepair))
      end
    end
    for i = 0, 3 do
      if wheelMissing(car, i) then
        consider('beyond', string.format(TEXTS.damageWheel, WHEEL_NAMES[i]), '')
      end
    end
    local blown, first = 0, nil
    for i = 0, 3 do
      local w = car.wheels and car.wheels[i]
      if w and w.isBlown then
        blown = blown + 1
        first = first or i
      end
    end
    if blown > config.damage.maxPunctured then
      consider('beyond', string.format(TEXTS.damageTyres, blown),
        string.format(TEXTS.damageTyresAllowed, blown, config.damage.maxPunctured))
    elseif blown > 0 then
      consider('repair', string.format(TEXTS.damageTyre, WHEEL_NAMES[first]),
        string.format(TEXTS.damageTyresAllowed, blown, config.damage.maxPunctured))
    end
    return worst
  end

  function DamageClass.update(car, lineFrame)
    local r = state.repair
    local race = sim.raceSessionType == ac.SessionType.Race or sim.raceSessionType == ac.SessionType.Qualify
    if not race or state.dtDsqActive or state.pitDsqActive then
      r.class = 'normal'
      return
    end
    -- New connection: the car is new until its record is put back (CarState)
    if CarState.restoring then return end
    local c = classify(car)
    -- Repair relaxed by a Race Control command: not required again until the car is repaired
    if r.waived then
      if c.class ~= 'normal' then
        r.class = 'normal'
        return
      end
      r.waived = nil
    end
    -- Line crossing with the repair deadline running
    if lineFrame and r.lapsLeft then
      r.lapsLeft = r.lapsLeft - 1
      if r.lapsLeft <= 0 and c.class ~= 'normal' then
        r.lapsLeft = nil
        r.class = 'normal'
        carDsq(1, 'Mandatory repair not done', nil, r.text)
        ac.log('race-control: DSQ, mandatory repair not done')
        return
      end
    end
    if c.class == 'normal' then
      if r.lapsLeft then
        ac.log('race-control: mandatory repair done')
        rcLog('Repair done', tostring(r.text))
      end
      r.lapsLeft = nil
    elseif c.class == 'repair' and not r.lapsLeft then
      r.lapsLeft = config.damage.repairLaps
      ac.log(string.format('race-control: repair required (%s, %s), %d laps', c.text, c.detail, r.lapsLeft))
      rcLog('Repair required', string.format('%s - %s - %d laps', c.text, c.detail, r.lapsLeft))
    end
    if c.class == 'beyond' and r.class ~= 'beyond' then
      ac.log(string.format('race-control: damage beyond the safety limit (%s, %s)', c.text, c.detail))
      rcLog('Damage beyond safety limit', string.format('%s - %s', c.text, c.detail))
    end
    -- Tow not done after the warning: DSQ (safety hazard) that asks for the tow
    if c.class == 'beyond' then
      r.beyondSince = r.beyondSince or serverTimeMs()
      if serverTimeMs() - r.beyondSince >= config.beyondTowSeconds * 1000 then
        r.beyondSince = nil
        r.class = 'normal'
        carDsq(1, TEXTS.dsqSafety, 'tow', 'no tow')
        ac.log('race-control: DSQ, damage beyond the safety limit and no tow (safety hazard)')
        return
      end
    else
      r.beyondSince = nil
    end
    r.class, r.text, r.detail = c.class, c.text, c.detail
  end
end
-- ============================================================
-- Pit stops (decisions 102, 103, 107, 109, 112). A stop is a stop at the own pit place for service (fuel, tyres,
-- compound, setup), repair or a penalty (stop & go served), at any time: it has nothing to do with the driver swap.
-- One pit pass counts at most one stop (pitStopsEnabled; pitStopsRequired stops, 0 = counted, not validated).
-- Pit stop table (Arquitetura — persistência, 11.11.2): one line per pit pass, opened at the pit entry and closed at the
-- pit exit, sent as a [RC] line to the server log; the car record keeps the count (PitRecord).
-- Mandatory pit window (decisions 81, 91, 92, 98, 112): the driver swap window, the script's own (off in the ACSM).
-- Race only, from pitWindowStartMinutes to pitWindowEndMinutes after the race start (0 = no window). A driver swap is
-- valid only if the car entered the pit lane inside the window (the pit lane is a neutral zone); only a valid swap
-- fulfils the window and counts for driverSwapRequired. Window closed without a valid swap: DSQ.
-- End of the race (car.isRaceFinished): valid swaps or stops below the required: DSQ.
-- ============================================================

local PitStops = {
  passInWindow = false,   -- the pit pass in progress started inside the window
  wasInPitlane = nil,     -- own car in the pit lane in the previous frame (nil = not read yet in this session)
  pass = nil,             -- line of the pit stop table in progress
  line = 0,               -- lines of the pit stop table in this session (ID)
  otherInPitlane = {},    -- [carIndex] = another car in the pit lane in the previous frame
  endChecked = false,     -- end of the race already checked
  lastIsInPit = nil,      -- car.isInPit in the previous frame (log of the changes)
  stopLogged = false,     -- stop in the pit lane without isInPit already logged in this pass
}
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  -- Race time as h:mm:ss
  local function raceTime(ms)
    local s = math.max(math.floor((ms or 0) / 1000), 0)
    return string.format('%d:%02d:%02d', math.floor(s / 3600), math.floor(s / 60) % 60, s % 60)
  end

  -- Flag of the race (track list) and flag shown to the driver
  local function raceFlag() return state.code80 or 'green' end
  local function driverFlag()
    local f = sim.raceFlagType
    if f == ac.FlagType.Caution then return 'yellow' end
    if f == ac.FlagType.FasterCar then return 'blue' end
    return 'none'
  end

  -- The window in ms after the race start, or nil (not a race, or no window)
  function PitStops.window()
    if sim.raceSessionType ~= ac.SessionType.Race then return nil end
    local s, e = config.pitWindowStart * 60000, config.pitWindowEnd * 60000
    if s <= 0 or e <= s then return nil end
    return s, e
  end

  -- Pit window open now
  function PitStops.windowOpen()
    local s, e = PitStops.window()
    if not s or not sim.isSessionStarted then return false end
    local t = sessionElapsedMs()
    return t >= s and t <= e
  end

  -- A pit pass entering now makes a valid driver swap: inside the window, or no window
  local function swapValidNow() return PitStops.window() == nil or PitStops.windowOpen() end

  local function openPass(jumped, entryMs)
    PitStops.line = PitStops.line + 1
    PitStops.pass = { id = PitStops.line, entryMs = entryMs, jumped = jumped, service = nil, paid = {}, stop = nil,
      raceFlag = raceFlag(), driverFlag = driverFlag(), snap = nil }
  end

  local function closePass()
    local p = PitStops.pass
    PitStops.pass = nil
    if not p or not config.pitStopsEnabled then return end
    rcLog(TEXTS.pitStopRow, string.format(TEXTS.pitStopRowText, p.id, p.stop and tostring(p.stop) or '-',
      p.entryMs and raceTime(p.entryMs) or TEXTS.pitStopRowInPits, raceTime(sessionElapsedMs()),
      p.service or TEXTS.pitStopRowNoService, #p.paid > 0 and table.concat(p.paid, ', ') or TEXTS.pitStopRowNoPenalty,
      p.jumped and 'tow' or 'driven', p.raceFlag, p.driverFlag, tostring(ac.getDriverTeam(0) or '-'),
      tostring(ac.getUserSteamID() or '-')))
  end

  -- One stop for this pit pass (the first service, repair or stop & go served in it)
  function PitStops.countStop()
    local p = PitStops.pass
    if not config.pitStopsEnabled or not p or p.stop then return end
    PitRecord.stops = PitRecord.stops + 1
    p.stop = PitRecord.stops
    PitRecord.save()
    ac.log(string.format('race-control: pit stop %d counted', p.stop))
  end

  -- What the pit pass served and paid (pit stop table)
  function PitStops.noteService(text)
    local p = PitStops.pass
    if p then p.service = p.service and (p.service .. '; ' .. text) or text end
  end
  function PitStops.notePaid(text)
    local p = PitStops.pass
    if p then p.paid[#p.paid + 1] = text end
  end

  -- A stop with service done by the box: fuel added, wheels changed (count), compound changed, repair
  function PitStops.record(lap, fuel, wheels, compoundChanged, repair)
    PitRecord.last = string.format('%d/%.1f/%d/%s', lap, fuel, wheels, repair and 'repair' or '-')
    local text = string.format('fuel +%.1f L%s%s%s', fuel, wheels > 0 and string.format(', tyres %d', wheels) or '',
      compoundChanged and ', compound' or '', repair and ', repair' or '')
    ac.log('race-control: pit stop with service: ' .. text)
    PitStops.noteService(text)
    PitStops.countStop()
    PitRecord.save()
  end

  -- A valid driver swap (the new driver's side): the window is fulfilled
  function PitStops.validSwap()
    PitStops.passInWindow = true
    if PitStops.window() and not state.pit.done then
      state.pit.done = true
      Record.save('window', 1, 'done')
      ac.log('race-control: mandatory pit window: valid driver swap')
    end
  end

  -- End of the race of this car: valid swaps and stops against the required
  local function raceEnd(car)
    if PitStops.endChecked or sim.raceSessionType ~= ac.SessionType.Race or not car.isRaceFinished then return end
    PitStops.endChecked = true
    local why
    local req = config.swapRequired or 0
    if config.swapOn() and req > 0 and state.swap.valid < req then
      why = string.format(TEXTS.swapsMissingDsq, state.swap.valid, req)
    end
    if config.pitStopsEnabled and config.pitStopsRequired > 0 and PitRecord.stops < config.pitStopsRequired then
      local s = string.format(TEXTS.stopsMissingDsq, PitRecord.stops, config.pitStopsRequired)
      why = why and (why .. ' - ' .. s) or s
    end
    if not why then return end
    ac.log('race-control: DSQ at the end of the race: ' .. why)
    if not (state.dtDsqActive or state.pitDsqActive) then carDsq(1, why) end
  end

  -- Every frame: other cars' pit entries (driver swap relay), the own pit pass (table, stops), the window, the end
  function PitStops.update(car)
    for i = 1, sim.carsCount - 1 do
      local c = ac.getCar(i)
      local inP = c and c.isInPitlane or false
      if inP and not PitStops.otherInPitlane[i] then state.swap.pitEntryValid[i] = swapValidNow() end
      PitStops.otherInPitlane[i] = inP
    end
    local inPit = car.isInPitlane
    -- What the game reports at the pit place: every change of car.isInPit, and a stop in the pit lane without it, with
    -- the speed and the distance to the own pit position (car.pitTransform)
    local dist = -1
    if car.position and car.pitTransform and car.pitTransform.position then
      local a, b = car.position, car.pitTransform.position
      dist = math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
    end
    if car.isInPit ~= PitStops.lastIsInPit then
      ac.log(string.format('race-control: isInPit %s (speed %.2f km/h, %.2f m from the pit position)',
        tostring(car.isInPit), car.speedKmh, dist))
      PitStops.lastIsInPit = car.isInPit
    end
    if inPit and not car.isInPit and car.speedKmh < 0.5 and not PitStops.stopLogged then
      PitStops.stopLogged = true
      ac.log(string.format('race-control: stopped in the pit lane without isInPit (speed %.2f km/h, %.2f m from the pit position)',
        car.speedKmh, dist))
    end
    if not inPit or car.speedKmh > 5 then PitStops.stopLogged = false end
    if PitStops.wasInPitlane == nil then
      PitStops.wasInPitlane = inPit
      -- Already in the pits at the start (connection, driver swap): a pass without entry time
      if inPit then openPass(state.list.jumped, nil) end
    end
    if inPit and not PitStops.wasInPitlane then
      PitStops.passInWindow = PitStops.windowOpen()
      openPass(state.list.jumped, sessionElapsedMs())
    end
    if not inPit and PitStops.wasInPitlane then
      closePass()
      PitStops.passInWindow = false
    end
    PitStops.wasInPitlane = inPit
    -- A real change in the car at its pit place (the AC pit screen, for example) is a stop with service
    local p = PitStops.pass
    if p and car.isInPit and not CarState.restoring then
      p.snap = p.snap or CarRead.snapshot(car)
      if not p.stop and state.pitService == nil and CarRead.serviced(car, p.snap) then
        PitStops.noteService('service')
        PitStops.countStop()
      end
    end
    raceEnd(car)
    local s, e = PitStops.window()
    if not s or not config.swapOn() or not sim.isSessionStarted or state.pit.done or state.pit.missed
      or sessionElapsedMs() <= e then
      return
    end
    -- Neutral zone: the pass that started inside the window goes on
    if inPit and PitStops.passInWindow then return end
    state.pit.missed = true
    Record.save('window', 2, 'missed')
    ac.log('race-control: mandatory pit window missed (no valid driver swap): DSQ')
    rcLog('Pit window', TEXTS.pitMissedLog)
    if not (state.dtDsqActive or state.pitDsqActive) then carDsq(1, TEXTS.pitWindowDsq) end
  end
end

-- Pit window of this car kept by the other drivers
RecordSync.restorers.window = function(body)
  if body == 'done' and not state.pit.done then
    state.pit.done = true
    ac.log('race-control: mandatory pit window done (from the other drivers)')
  elseif body == 'missed' then
    state.pit.missed = true
  end
end
-- ============================================================
-- Table of drivers in command (decisions 104, 105, 108; Arquitetura — persistência, 11.11.1). One line per driver who
-- takes the car, sent as a [RC] line to the server log; the car record (swap) keeps the swaps, the valid swaps, the swap
-- number of the driver in command and who he is. Swap 0 = the driver who started the session; a driver other than the
-- one who left = one more swap (the same driver who drove before, coming back after another, is a new swap); the same
-- driver coming back after a disconnection = the same swap number, marked as a rejoin (no swap counted). Only a swap
-- whose pit entry was inside the pit window is valid (decision 112). Sessions with the driver swap on.
-- ============================================================

local DriverTable = { done = false, swapDone = false, startT = nil }
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local DECIDE_SECONDS = 12   -- the last SWAP_INFO resend is 10 s after the connection

  function DriverTable.reset()
    DriverTable.done = false
    DriverTable.swapDone = false
    DriverTable.startT = nil
  end

  function DriverTable.update()
    if not config.swapOn() then return end
    local sw = state.swap
    -- A swap told by the other drivers (SWAP_INFO), already counted; also when it arrives after the table decided
    local swapNow = sw.swapInfo and not DriverTable.swapDone
    if DriverTable.done and not swapNow then return end
    DriverTable.startT = DriverTable.startT or state.ui.clock
    local me = nameCode(ac.getDriverName(0))
    local swapNo, rejoin = nil, false
    if swapNow then
      DriverTable.swapDone = true
      swapNo = sw.count
      if sw.swapInfo.inWindow then PitStops.validSwap() end
    elseif state.ui.clock - DriverTable.startT < DECIDE_SECONDS then
      return
    elseif sw.driver == me then
      swapNo, rejoin = sw.swapNo, true
    elseif sw.driver == 0 then
      swapNo = 0
    else
      -- A driver other than the one in the record, without SWAP_INFO (he came long after the other left): a swap,
      -- valid only without a pit window (the pit entry is not known here)
      sw.count = sw.count + 1
      swapNo = sw.count
      if PitStops.window() == nil then sw.valid = sw.valid + 1 end
    end
    DriverTable.done = true
    sw.swapNo, sw.driver = swapNo, me
    SwapRecord.save()
    rcLog(TEXTS.driverRow, string.format(TEXTS.driverRowText, swapNo, rejoin and TEXTS.driverRowRejoin or '',
      tostring(ac.getDriverTeam(0) or '-'), tostring(ac.getUserSteamID() or '-')))
  end
end
-- ============================================================
-- Own pit stop box (front B, approved screen 11). The AC quick pit menu is off (decision 30): the stop is chosen here,
-- with the car stopped at its own pit place (car.isInPit), and done with the game physics.
-- Rows: fuel to add; compound (another compound than the one fitted changes the 4 tyres, no mixing); tyres (none, one
-- wheel, a pair 2F / 2B / 2L / 2R, or the 4: 2A); pressure and wing only shown (they need the bridge app, decisions 31
-- and 34); repair by group (suspension, powertrain, bodywork).
-- Times: fuel and tyres from the car (car.ini [PIT_STOP]: FUEL_LITER_TIME_SEC per litre, TYRE_CHANGE_TIME_SEC per
-- tyre); repair by the repair formula of the session on the collision damage (rule 18, the same as the hold). Total by
-- the order of the operations (key pitStopOrder, the same notation as PITS_ORDER of the CSP: letters F fuel, T tyres,
-- R repair one after the other; letters inside < > at the same time; default F<TR> = fuel first, then tyres and repair
-- together). The stop is applied at the end, not little by little.
-- Enter starts the stop: the controls are locked for the total time, counted in server time and kept in the pit record
-- (a crash or a driver swap in the middle goes on with the time left); at the end the stop is applied to the car.
-- Controls (controls.ini, configurable): arrows up / down / left / right and Enter; gamepad D-pad and A.
-- ============================================================

local PitBox = { row = 1, fuel = 0, compound = nil, tyres = 1, repair = {}, open = false }
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local num = CarRead.num
  local WHEELS = { [0] = 'FL', 'FR', 'RL', 'RR' }
  -- Tyre choices: name and wheels changed
  local TYRE_CHOICES = {
    { '-', {} }, { 'FL', { 0 } }, { 'FR', { 1 } }, { 'RL', { 2 } }, { 'RR', { 3 } },
    { '2F', { 0, 1 } }, { '2B', { 2, 3 } }, { '2L', { 0, 2 } }, { '2R', { 1, 3 } }, { '2A', { 0, 1, 2, 3 } },
  }
  local ALL_TYRES = #TYRE_CHOICES
  -- Rows that take a choice (the others are only shown)
  local ROWS = { 'fuel', 'compound', 'tyres', 'suspension', 'powertrain', 'body' }
  local SERVICE_LOCK_EXTRA = 1   -- seconds added to the lock so the stop ends with the car still locked

  local function button(name, key, pad, period)
    return ac.ControlButton('12hcuritiba.race-control/Pit stop ' .. name,
      { keyboard = { key = key }, gamepad = pad, period = period })
  end
  local KEYS = {
    up = button('up', ui.KeyIndex.Up, ac.GamepadButton.DPadUp),
    down = button('down', ui.KeyIndex.Down, ac.GamepadButton.DPadDown),
    left = button('left', ui.KeyIndex.Left, ac.GamepadButton.DPadLeft, 0.08),
    right = button('right', ui.KeyIndex.Right, ac.GamepadButton.DPadRight, 0.08),
    enter = button('confirm', ui.KeyIndex.Return, ac.GamepadButton.A),
  }

  -- Service times of the car (car.ini [PIT_STOP])
  local rates
  local function carRates()
    if rates then return rates end
    local ini = ac.INIConfig.carData(0, 'car.ini')
    rates = {
      fuel = ini and ini:get('PIT_STOP', 'FUEL_LITER_TIME_SEC', 0) or 0,
      tyre = ini and ini:get('PIT_STOP', 'TYRE_CHANGE_TIME_SEC', 0) or 0,
    }
    return rates
  end

  -- Compounds of the car: short names by index
  local function compounds()
    local out = {}
    for i = 0, 15 do
      local name = ac.getTyresName(0, i)
      if not name then break end
      out[i] = name
    end
    return out
  end

  -- Total of the stop by the order of the operations: letters in sequence add, letters inside < > run together
  local function orderTotal(times)
    local total, group, inGroup = 0, 0, false
    for ch in tostring(config.pitStopOrder):upper():gmatch('.') do
      if ch == '<' then
        inGroup, group = true, 0
      elseif ch == '>' then
        inGroup, total = false, total + group
      elseif times[ch] then
        if inGroup then group = math.max(group, times[ch]) else total = total + times[ch] end
      end
    end
    if inGroup then total = total + group end
    return total
  end

  -- Repair seconds of a group (repair formula of the session, collision damage)
  local function repairTime(group)
    local d = state.tow.damage
    if not d then return 0 end
    local r = config.repair
    local factor = (config.tow[sim.raceSessionType] or {}).repairFactor or 0
    local s = group == 'suspension' and r.base * r.wSuspension * d.suspension
      or group == 'powertrain' and r.base * r.wEngine * d.powertrain
      or r.wBody * d.body
    return math.max(math.floor(factor * s + 0.5), 0)
  end

  -- Damage of the car by group (something to repair)
  local function damaged(car, group)
    if group == 'suspension' then
      for i = 0, 3 do if num(car.suspensionDamage[i]) > 0 then return true end end
      return false
    elseif group == 'powertrain' then
      return num(car.engineLifeLeft) < 1000 or num(car.gearboxDamage) > 0
    end
    for i = 0, 4 do if num(car.damage[i]) > 0 then return true end end
    return false
  end

  -- The stop chosen now: what is done and how long it takes
  function PitBox.plan(car)
    local r = carRates()
    local mounted = num(car.compoundIndex)
    local compound = PitBox.compound or mounted
    local tyres = compound ~= mounted and ALL_TYRES or PitBox.tyres
    local fuel = math.min(PitBox.fuel, math.max(num(car.maxFuel) - num(car.fuel), 0))
    local p = { fuel = fuel, compound = compound, tyres = tyres, repair = {}, times = {} }
    p.times.fuel = fuel * r.fuel
    p.times.tyres = #TYRE_CHOICES[tyres][2] * r.tyre
    for _, g in ipairs({ 'suspension', 'powertrain', 'body' }) do
      p.repair[g] = PitBox.repair[g] and damaged(car, g) or false
      p.times[g] = p.repair[g] and repairTime(g) or 0
    end
    p.total = orderTotal({ F = p.times.fuel, T = p.times.tyres,
      R = p.times.suspension + p.times.powertrain + p.times.body })
    return p
  end

  -- Plan as text for the pit record: fuel/compound/tyres/repair groups (s, p, b)
  local function planText(p)
    return string.format('%.1f/%d/%d/%s%s%s', p.fuel, p.compound, p.tyres, p.repair.suspension and 's' or '',
      p.repair.powertrain and 'p' or '', p.repair.body and 'b' or '')
  end
  local function planParse(text)
    local fuel, compound, tyres, groups = tostring(text):match('^([%d%.]+)/(%d+)/(%d+)/(%a*)$')
    if not fuel then return nil end
    return { fuel = tonumber(fuel), compound = tonumber(compound), tyres = tonumber(tyres),
      repair = { suspension = groups:find('s') ~= nil, powertrain = groups:find('p') ~= nil,
        body = groups:find('b') ~= nil } }
  end

  -- The stop done: fuel, tyres, compound and repair put on the car with the game physics
  local function applyPlan(car, p)
    local fuelBefore, mounted = num(car.fuel), num(car.compoundIndex)
    local fuel = math.min(num(car.fuel) + p.fuel, num(car.maxFuel) > 0 and num(car.maxFuel) or math.huge)
    local wheels = TYRE_CHOICES[p.tyres][2]
    local km = {}
    for i = 0, 3 do km[i] = num(car.wheels[i].tyreVirtualKM) end
    for _, w in ipairs(wheels) do km[w] = 0 end
    local body = {}
    for i = 0, 3 do body[i] = p.repair.body and 0 or num(car.damage[i]) end
    -- Gearbox: only a full reset repairs it (no other game function); everything else is put back after it
    if p.repair.powertrain and num(car.gearboxDamage) > 0 then physics.resetCarState(0, 1) end
    physics.setCarFuel(0, fuel)
    if p.compound ~= num(car.compoundIndex) then physics.setTyresCompound(0, nil, p.compound) end
    for i = 0, 3 do physics.setTyresVirtualKM(0, i, km[i]) end
    physics.setCarBodyDamage(0, vec4(body[0], body[1], body[2], body[3]))
    if p.repair.suspension then
      for i = 0, 3 do physics.setSuspensionDamage(0, i, 0) end
    end
    if p.repair.powertrain then physics.setCarEngineLife(0, 1000) end
    -- The damage repaired is paid: not charged again
    local d = state.tow.damage
    if d then
      if p.repair.suspension then d.suspension = 0 end
      if p.repair.powertrain then d.powertrain = 0 end
      if p.repair.body then d.body = 0 end
    end
    ac.log(string.format('race-control: pit stop done (%s)', planText(p)))
    local repaired = p.repair.suspension or p.repair.powertrain or p.repair.body
    PitStops.record(car.lapCount, fuel - fuelBefore, #wheels, p.compound ~= mounted, repaired)
  end

  -- Start of the stop: controls locked for the total, end in server time in the pit record
  local function startStop(p)
    state.pitService = { startMs = serverTimeMs(), untilMs = serverTimeMs() + p.total * 1000, plan = planText(p) }
    physics.lockUserControlsFor(p.total + SERVICE_LOCK_EXTRA)
    PitRecord.save()
    ac.log(string.format('race-control: pit stop started, %.1f s (%s)', p.total, planText(p)))
  end

  -- A stop kept in the pit record (new connection, driver swap): goes on with the time left
  function PitBox.resume(startMs, untilMs, plan)
    if not planParse(plan) then return end
    state.pitService = { startMs = startMs, untilMs = untilMs, plan = plan }
    local left = (untilMs - serverTimeMs()) / 1000
    if left > 0 then physics.lockUserControlsFor(left + SERVICE_LOCK_EXTRA) end
    ac.log(string.format('race-control: pit stop goes on, %.1f s left', math.max(left, 0)))
  end

  local function reset()
    PitBox.row, PitBox.fuel, PitBox.compound, PitBox.tyres, PitBox.repair = 1, 0, nil, 1, {}
  end

  local function choose(car, dir)
    local what = ROWS[PitBox.row]
    if what == 'fuel' then
      PitBox.fuel = math.max(0, math.min(PitBox.fuel + dir, math.max(num(car.maxFuel) - num(car.fuel), 0)))
    elseif what == 'compound' then
      local list = compounds()
      local n = 0
      for _ in pairs(list) do n = n + 1 end
      if n > 0 then PitBox.compound = ((PitBox.compound or num(car.compoundIndex)) + dir) % n end
    elseif what == 'tyres' then
      PitBox.tyres = (PitBox.tyres - 1 + dir) % ALL_TYRES + 1
    else
      PitBox.repair[what] = not PitBox.repair[what]
    end
  end

  -- Menu of the AC off, once (decision 30)
  local menuOff = false
  function PitBox.update(car)
    if not menuOff then
      ac.disableQuickMenuPitstop(true)
      ac.disableExtraHUDElements('quickPitsMenu', true)
      menuOff = true
    end
    local sv = state.pitService
    if sv then
      if serverTimeMs() >= sv.untilMs and CarState.ready() then
        local p = planParse(sv.plan)
        state.pitService = nil
        if p then applyPlan(car, p) end
        PitRecord.save()
        reset()
      end
      return
    end
    PitBox.open = CarRead.parked(car) and not state.hold and not state.dtDsqActive and not state.pitDsqActive
      and not CarState.restoring
    if not PitBox.open then
      if not car.isInPit then reset() end
      return
    end
    if KEYS.up:pressed() then PitBox.row = (PitBox.row - 2) % #ROWS + 1 end
    if KEYS.down:pressed() then PitBox.row = PitBox.row % #ROWS + 1 end
    if KEYS.left:pressed() then choose(car, -1) end
    if KEYS.right:pressed() then choose(car, 1) end
    if KEYS.enter:pressed() then
      local p = PitBox.plan(car)
      if p.total > 0 or p.fuel > 0 or #TYRE_CHOICES[p.tyres][2] > 0 then startStop(p) end
    end
  end

  PitRecord.onService = PitBox.resume

  -- For the drawing: rows, their text and time
  PitBox.WHEELS = WHEELS
  PitBox.TYRE_CHOICES = TYRE_CHOICES
  PitBox.ROWS = ROWS
  PitBox.compounds = compounds
  PitBox.damaged = damaged
end
-- ============================================================
-- Pit lane speeding (decisions 79, 89, 90, 101). The game does not penalize it ([PITS_SPEED_LIMITER] SPEEDING_PENALTY =
-- NONE on the server); the script measures it with its own limit (pitSpeedLimit, like RealPenalty's PIT_LANE_SPEED:
-- nothing of the rule comes from the server). In the pit lane, a speed above pitSpeedLimit plus pitSpeedTolerance km/h
-- is one PSE for the pit pass, with pitSpeedDeadlineLaps laps. It enters the list at the
-- pit exit, when the pass ends; every line crossed in that pit pass takes one lap from it (rule 2: including the DT
-- received in the pit pass itself).
-- After a DSQ a new infraction is not applied (decision 17).
-- ============================================================

local PitSpeed = {
  entryLap = nil, -- car.lapCount when the car entered the pit lane (nil = not in the pit lane)
  over = false,   -- speeding measured in this pit pass
  maxKmh = 0,     -- highest speed in this pit pass since the speeding
}

function PitSpeed.update(car, inPit, lapCount)
  if inPit then
    PitSpeed.entryLap = PitSpeed.entryLap or lapCount
    local limit = config.pitSpeedLimit
    if limit > 0 and car.speedKmh > limit + config.pitSpeedTolerance and not state.list.jumped then
      if not PitSpeed.over then
        PitSpeed.over = true
        ac.log(string.format('race-control: pit lane speeding %.1f km/h (limit %d + %d)', car.speedKmh, limit,
          config.pitSpeedTolerance))
      end
      PitSpeed.maxKmh = math.max(PitSpeed.maxKmh, car.speedKmh)
    end
    return
  end
  local entryLap = PitSpeed.entryLap
  PitSpeed.entryLap = nil
  if not PitSpeed.over then return end
  local lost = math.max(lapCount - (entryLap or lapCount), 0)
  local speed = PitSpeed.maxKmh
  PitSpeed.over = false
  PitSpeed.maxKmh = 0
  if state.dtDsqActive or state.pitDsqActive then
    ac.log('race-control: pit lane speeding after the DSQ: not applied')
    return
  end
  local before = listDump()
  listAdd('PSE', math.max(config.pitSpeedDeadlineLaps - lost, 0))
  ac.log(string.format('race-control: PSE pit exit %.1f km/h before=%s after=%s', speed, before, listDump()))
  rcLog('Drive-through', string.format('%s - %.1f km/h', TEXTS.reason.PSE, speed))
  Rules.finalize()
end
-- Rule 6: DT0 unpaid when the lap ends: DSQ (true). Practice and qualifying (rule 25): no DSQ; the laps are invalid
-- until the penalty is paid (Rules.invalidLaps) and the list goes on (false).
local function applyExpiredDSQ(expired, viaPit)
  if sim.raceSessionType ~= ac.SessionType.Race then
    ac.log('race-control: deadline over in practice or qualifying: laps invalid until paid')
    return false
  end
  local cats, kmr = {}, nil
  for _, it in ipairs(expired) do
    cats[#cats + 1] = it.cat
    if TEXTS.kmrReasons[it.cat] then kmr = kmr or reasonLog(it.cat) end
  end
  carDsq(1, TEXTS.dsqDtReason, nil, kmr)
  ac.log(string.format('race-control: DSQ for unpaid DT0 (%s), lap completed %s',
    table.concat(cats, ','), viaPit and 'via pit' or 'on track'))
  return true
end

-- Stop & go (stopAndGo mode SG): two pending DT0 turn the whole list into one stop & go of secondsPerDT per
-- drive-through, to serve by stopping at the own pit place within deadlineLaps (like a DT1). Nothing goes to the game
-- (decision 78): the panel shows it.
function Rules.sgForm()
  local l = state.list
  local n = #l.items
  local reasons = {}
  local kmr = ''
  for _, it in ipairs(l.items) do
    reasons[#reasons + 1] = reasonLog(it.cat)
    if TEXTS.kmrReasons[it.cat] then kmr = kmr .. 'x' .. it.cat:sub(2) end
  end
  l.seq = l.seq + 1
  local laps = config.sgDeadlineLaps
  l.items = { { cat = 'SG' .. n, kind = 'SG' .. kmr, laps = laps, givenLap = l.curLap, expireLap = l.curLap + laps, seq = l.seq,
    dt0OnTrack = false } }
  ac.log(string.format('race-control: stop & go %d s (%d DT)', n * config.sgSecondsPerDT, n))
  rcLog(string.format('Stop & go %d s', n * config.sgSecondsPerDT), 'includes ' .. table.concat(reasons, ', '))
  if n > config.sgMaxDT then Rules.sgOverLimit(n) end
  listSave()
end

-- More penalties than a stop & go can hold: our DSQ at once (rule 21). The game black flag comes as in every DSQ
-- (DsqFlow): stopped at the pit place, or at the dsqBlackFlagLaps-th line; never in the middle of the track
function Rules.sgOverLimit(n)
  ac.log(string.format('race-control: DSQ, stop & go limit exceeded (%d DT)', n))
  carDsq(1, string.format(TEXTS.sgLimit, config.sgMaxDT))
end

-- After any list change: rule 3 (order), rule 5 (two DT0 = hold, or stop & go; during CODE-80 it waits for the green
-- flag) and saving
function Rules.finalize()
  listSort()
  local dt0 = pendingDT0()
  if #dt0 >= 2 and not state.code80 then
    if config.sg then
      Rules.sgForm()
    else
      applyHold(hasLongHold(dt0))
    end
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

-- Line crossing. g = the game now (only its black flag matters). Before = the table before the rules, after = the table
-- after them. Nothing is written to the game (decision 78), except the DSQs.
function Rules.line(viaPit, g, lapCount)
  local l = state.list
  if g.t == BLACK_FLAG then
    Rules.zero()
    return
  end
  local before = listDump()
  l.curLap = lapCount
  -- CODE-80 with frozen deadlines: no lap is taken and nobody is disqualified at this line
  local frozen = state.code80 ~= nil and config.code80Freeze
  if viaPit then
    -- Rule 3: the pit pass serves one DT, position 0 (DT0 before DT1; same deadline, the oldest first).
    -- After a teleport there is no pit pass: nothing is paid. During CODE-80 nothing is paid either.
    if state.code80 and l.items[1] then
      ac.log('race-control: pit pass during CODE-80, nothing paid')
    elseif l.wrong and l.items[1] then
      -- Only the driver who caused the penalty pays it
      ac.log('race-control: pit pass by another driver, nothing paid')
    elseif not l.jumped then
      local head = l.items[1]
      if head and head.kind:sub(1, 2) == 'SG' then
        -- A pit pass does not serve the stop & go (only stopping does). On its last lap: DSQ, as on track
        if not frozen and head.expireLap <= l.curLap - 1 and applyExpiredDSQ({ head }, true) then return end
      elseif head then
        listRemove(head)
        PitStops.notePaid(head.cat .. ' DT')
        if TEXTS.kmrReasons[head.cat] then
          rcLog('Drive-through served', TEXTS.kmrReasons[head.cat] .. ' - issued by KMR, served under Race Control')
        end
      end
    end
  elseif not frozen then
    -- Rule 6 / condition 9: DT0 pending when crossing on track (the end-of-lap SD is not in the table yet)
    local completedLap = l.curLap - 1
    local expired = {}
    for _, it in ipairs(l.items) do
      if it.expireLap <= completedLap then expired[#expired + 1] = it end
    end
    if #expired > 0 and applyExpiredDSQ(expired, false) then return end
  end
  -- Rule 2: every DT loses one lap (frozen by CODE-80: the expire lap moves one lap instead)
  for _, it in ipairs(l.items) do
    if frozen then
      it.expireLap = it.expireLap + 1
    else
      it.laps = it.laps - 1
      if it.cat == 'PSE' and it.laps == 0 and not viaPit then it.dt0OnTrack = true end
    end
  end
  -- Rule 4: end-of-lap slowdowns enter as DT0 of the next lap
  for _, cat in ipairs(l.endOfLap) do
    listAdd(cat, 0)
  end
  l.endOfLap = {}
  ac.log(string.format('race-control: line %s table before=%s after=%s', viaPit and 'pit' or 'track', before,
    listDump()))
  Rules.finalize()
end

-- The penalty list of this car kept by the other drivers: it wins over the local one when as new or newer
RecordSync.restorers.penalties = function(body, seq)
  local l = state.list
  if seq < l.seq then
    ac.log(string.format('race-control: penalty list of the other drivers older than the local one (%d < %d): kept local',
      seq, l.seq))
    return
  end
  listApply(body, 'peers')
  ac.log('race-control: penalty list restored from the other drivers ' .. listDump())
  Rules.keepDsq('other drivers')
  if l.dsq > 0 then return end
  Rules.finalize()
end

-- DSQ kept in the car record (reconnection, restarted game, another driver): the new connection starts without the black
-- flag, so it is applied again
function Rules.keepDsq(source)
  local l = state.list
  if l.dsq == 0 or state.dtDsqActive or state.pitDsqActive then return end
  if l.dsq == 2 then state.pitDsqActive = true else state.dtDsqActive = true end
  -- Game black flag already given: again; otherwise the drawn flag and what the DSQ asks go on
  if l.dsqStage == 1 then dsqGameFlag('kept from the car record') end
  ac.log('race-control: DSQ kept from the car record (' .. source .. ')')
end

-- Practice and qualifying (rule 25): with a penalty unpaid, every lap is invalid. The SDK has no call for it outside the
-- race (markLapAsSpoiled works only in the race); physics.setCarFuel invalidates the current lap ("Sets car fuel and
-- invalidates current lap"), so the fuel the car already has is set again, once per lap.
function Rules.invalidLaps(car)
  local l = state.list
  if sim.raceSessionType == ac.SessionType.Race or #l.items == 0 or l.invalidLap == car.lapCount then return end
  l.invalidLap = car.lapCount
  physics.setCarFuel(0, car.fuel)
  ac.log('race-control: lap invalid (penalty not paid, practice or qualifying)')
end

-- Session start or script reload: the list of this car. Nothing goes to the game (decision 78): a drive-through an
-- older version left in the game is taken out
function Rules.sessionSync(g)
  local l = state.list
  listLoad()
  if g.t == GAME_DT and g.p > 0 then
    clearGamePenalty()
    ac.log('race-control: drive-through left in the game removed (nothing goes to the game)')
  end
  Rules.keepDsq('this computer')
  if l.dsq > 0 then return end
  Rules.finalize()
end
-- ============================================================
-- Stop & go: serving it by stopping at the own pit place (stopAndGo mode SG)
-- The car has to reach its pit place (car.isInPit) driving through the pit lane in this connection (a teleport, or the
-- car shown in the pits after connecting, does not count), stop, and stay stopped for the whole stop & go time. The
-- controls are not locked: the driver holds the car. The car moves and stops again inside the pit place: the time
-- starts again. It leaves the pit place: not served; the line decides (another lap to serve it, or DSQ). Stopping
-- during CODE-80 does not serve it; a stop already counting when the CODE-80 starts ends normally.
-- Service: a stop with service (fuel, tyres, repair) is allowed with a stop & go pending and does not serve it (the
-- stop & go never has service); that pit pass cannot serve it any more: the limit is the deadline. Service is a real
-- change in the car (CarRead.serviced), and the driver is told on screen.
-- Only the driver who caused it pays it: a wrong driver in the car (WrongDriver) does not serve it.
-- Interrupted (the driver disconnects while stopped): the time served stays in the car record; the same driver coming
-- back resumes it where it stopped (stopAndGo returnSeconds: time limit to come back, 0 = no limit). Another driver: the wrong
-- driver rule.
-- Over the limit (stopAndGo maxDT): our DSQ at once (Rules.sgOverLimit, rule 21).
-- ============================================================

local StopAndGo = {
  drove = false,      -- the car is in the pit lane having driven into it in this connection
  serviced = false,   -- service seen at the pit place in this pit pass: it cannot serve the stop & go
  snap = nil,         -- the car as it arrived at its pit place in this pit pass (CarRead.snapshot)
  stopping = false,   -- stopped at the pit place serving it
  base = 0,           -- ms already served when this stop started
  startMs = 0,        -- server time when this stop started
  lastSaveMs = 0,
  resume = false,     -- interrupted stop & go of the same driver: stopping at the pit place resumes it
  checkedKind = nil,  -- stop & go state already checked for an interruption (a start, or a list restored)
}
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local SG_SAVE_EVERY_MS = 1000

  -- Time served (ms), server time of the last save (s) and driver of an interrupted stop & go
  local function sgFields(it)
    local served, t, d = it.kind:match('^SGs(%d+)t(%d+)d(%d+)')
    return tonumber(served) or 0, tonumber(t), tonumber(d)
  end

  local function sgMark(it, served)
    it.kind = string.format('SGs%dt%dd%d', math.floor(served), math.floor(serverTimeMs() / 1000),
      nameCode(ac.getDriverName(0))) .. sgKmrSuffix(it)
  end

  -- Remaining ms of the stop & go
  function StopAndGo.remainingMs(sg)
    local total = sgSeconds(sg) * 1000
    if StopAndGo.stopping then return math.max(total - StopAndGo.base - (serverTimeMs() - StopAndGo.startMs), 0) end
    return math.max(total - sgFields(sg), 0)
  end

  -- Seconds left for the same driver to come back to an interrupted stop & go (returnSeconds > 0)
  function StopAndGo.returnLeft()
    local sg = sgItem()
    if not sg or not StopAndGo.resume then return nil end
    local _, t = sgFields(sg)
    return math.max(config.sgReturnSeconds - (serverTimeMs() / 1000 - (t or 0)), 0)
  end

  -- A stop & go that was being served before this start (reconnection, restarted game, driver swap)
  local function checkInterrupted(sg)
    StopAndGo.checkedKind = sg.kind
    local served, t, driver = sgFields(sg)
    if served <= 0 then return end
    local away = serverTimeMs() / 1000 - (t or 0)
    if driver ~= nameCode(ac.getDriverName(0)) then
      -- Another driver: only the driver who stopped resumes it (WrongDriver)
      ac.log('race-control: stop & go interrupted: another driver in the car')
    elseif config.sgReturnSeconds > 0 and away > config.sgReturnSeconds then
      StopAndGo.stopping = false
      StopAndGo.resume = false
      carDsq(1, 'Stop & go interrupted')
      ac.log(string.format('race-control: DSQ, stop & go interrupted for %d s', math.floor(away)))
    else
      StopAndGo.resume = true
      ac.log(string.format('race-control: stop & go interrupted %d s ago, %.1f s served: resumes at the pit place',
        math.floor(away), served / 1000))
    end
  end

  -- The stop in progress does not serve it: nothing served (a new stop starts the time again)
  local function notServed(sg, why, done)
    StopAndGo.stopping = false
    StopAndGo.resume = false
    sg.kind = 'SG' .. sgKmrSuffix(sg)
    StopAndGo.checkedKind = sg.kind
    listSave()
    ac.log(string.format('race-control: stop & go not served: %s after %.1f s', why, done / 1000))
  end

  function StopAndGo.update(car)
    if not config.sg then return end
    local sg = sgItem()
    if not car.isInPitlane then
      StopAndGo.drove = false
      StopAndGo.serviced = false
      StopAndGo.snap = nil
    elseif not car.isInPit and CarRead.moving(car) and not state.list.jumped then
      StopAndGo.drove = true
    end
    if car.isInPit and not CarState.restoring then
      StopAndGo.snap = StopAndGo.snap or CarRead.snapshot(car)
      if not StopAndGo.serviced and CarRead.serviced(car, StopAndGo.snap) then
        StopAndGo.serviced = true
        if sg then
          showNotice(TEXTS.rcTitle, TEXTS.sgServiced, sg)
          ac.log('race-control: service at the pit place: stop & go not served in this pit pass')
        end
      end
    end
    if not sg then
      StopAndGo.stopping = false
      StopAndGo.resume = false
      StopAndGo.checkedKind = nil
      return
    end
    if sg.kind ~= StopAndGo.checkedKind and not StopAndGo.stopping then
      checkInterrupted(sg)
      sg = sgItem()
      if not sg then return end
    end
    -- Only the driver who caused it serves it
    if state.list.wrong then
      StopAndGo.stopping = false
      return
    end
    local now = serverTimeMs()
    if StopAndGo.stopping then
      local done = StopAndGo.base + (now - StopAndGo.startMs)
      if StopAndGo.serviced then
        notServed(sg, 'service during the stop', done)
      elseif done >= sgSeconds(sg) * 1000 then
        StopAndGo.stopping = false
        StopAndGo.resume = false
        listRemove(sg)
        ac.log(string.format('race-control: stop & go served (%d s)', sgSeconds(sg)))
        PitStops.notePaid(string.format('stop & go %d s', sgSeconds(sg)))
        PitStops.countStop()
        rcLog(TEXTS.sgServed, string.format('%d s', sgSeconds(sg)))
        for n in sgKmrSuffix(sg):gmatch('x(%d+)') do
          rcLog('Drive-through served in stop & go', reasonLog('K' .. n))
        end
        Rules.finalize()
      elseif not CarRead.parked(car) then
        -- Stopping again inside the pit place starts the time again; out of the pit place the line decides
        -- Moving, the car is no longer parked at its pit place (SDK isInPit): moved or left, the same
        notServed(sg, 'the car moved', done)
      elseif now - StopAndGo.lastSaveMs >= SG_SAVE_EVERY_MS then
        StopAndGo.lastSaveMs = now
        sgMark(sg, done)
        StopAndGo.checkedKind = sg.kind
        listSave()
      end
      return
    end
    -- Stop at the own pit place: driven into it now, or resuming the same driver's interrupted stop & go
    if state.code80 or StopAndGo.serviced or not CarRead.parked(car) then return end
    if not (StopAndGo.drove or StopAndGo.resume) then return end
    StopAndGo.stopping = true
    StopAndGo.base = sgFields(sg)
    StopAndGo.startMs = now
    StopAndGo.lastSaveMs = now
    local remaining = sgSeconds(sg) * 1000 - StopAndGo.base
    sgMark(sg, StopAndGo.base)
    StopAndGo.checkedKind = sg.kind
    listSave()
    ac.log(string.format('race-control: stop & go stopped at the pit place, %.1f s to serve', remaining / 1000))
  end
end
-- ============================================================
-- Wrong driver: the penalty is the car's, but only the driver who caused it pays it (international rules). The swap is
-- not allowed while the list has anything to pay. When another driver enters the car anyway (the script cannot stop a
-- disconnection), he is told to leave within wrongDriverSeconds, with a countdown; not gone by then: DSQ, and the
-- original driver cannot come back (the DSQ stays in the car record). If he leaves in time, the original driver can
-- still come back and pay. wrongDriverSeconds = 0: another driver is not allowed at all (DSQ as he enters). Empty: no
-- time defined, the new driver takes the list over and pays it (a possible regulation, not the world standard).
-- Only in a session with the driver swap on.
-- ============================================================

local WrongDriver = {}
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  -- Seconds left for the wrong driver to leave (nil = no wrong driver)
  function WrongDriver.remaining()
    local w = state.list.wrong
    if not w or not config.wrongDriver then return nil end
    return math.max(config.wrongDriver - (serverTimeMs() - w.since) / 1000, 0)
  end

  function WrongDriver.update()
    local l = state.list
    if not config.swapOn() then return end
    local me = nameCode(ac.getDriverName(0))
    if l.dsq > 0 or #l.items == 0 or not l.owner or l.owner == me then
      -- Nothing to pay, or the driver who has to pay it is back
      if l.wrong then
        l.wrong = nil
        listSave()
        ac.log('race-control: wrong driver gone: the driver who has to pay the penalties is in the car')
      end
      return
    end
    if not config.wrongDriver then
      -- Empty key: the penalties may be paid by another driver
      l.owner = me
      l.wrong = nil
      listSave()
      ac.log('race-control: penalties taken over by the new driver (wrongDriverSeconds empty)')
      rcLog('Driver swap', 'Pending penalties taken over by the new driver')
      return
    end
    if not l.wrong or l.wrong.driver ~= me then
      l.wrong = { driver = me, since = serverTimeMs() }
      listSave()
      ac.log(string.format('race-control: wrong driver: pending penalties of another driver, %d s to leave',
        config.wrongDriver))
      rcLog('Wrong driver', string.format('pending penalties of another driver - %d s to leave', config.wrongDriver))
    end
    if WrongDriver.remaining() <= 0 then
      carDsq(1, 'Driver swap with pending penalties')
      ac.log('race-control: DSQ, wrong driver did not leave the car')
    end
  end
end
-- ============================================================
-- DSQ flow. Two different things:
--   our DSQ (informative): black flag drawn by the script with the reason and what to do; the controls are not locked;
--   the game black flag (physics.setCarPenalty(BlackFlag)): the game DSQ. The controls are always locked with it: the
--   car cannot go back to the race.
-- The game black flag comes only if the driver does not do what our DSQ asks, or stops at the pit place with it:
--   stage 0 (stop at the pit place before the line): stopped at the pit place, or dsqBlackFlagLaps line crossings;
--   stage 2 (tow to the pits within damage dsqTowSeconds): stopped at the pit place (after the tow), or the time over.
-- A black flag from outside the script (KMR, admin) is a game black flag too: controls locked.
-- ============================================================

local DsqFlow = {}

-- Our DSQ pending: the game black flag (dsqGameFlag, penalties/list.lua) when the driver does not do what it asks
function DsqFlow.update(car, lineFrame)
  local l = state.list
  if l.dsq == 0 or l.dsqStage == 1 then return end
  if CarRead.parked(car) then
    dsqGameFlag('stopped at the pit place')
  elseif l.dsqStage == 0 and lineFrame and car.lapCount >= l.dsqLap + config.dsqBlackFlagLaps then
    dsqGameFlag('line crossing')
  elseif l.dsqStage == 2 and serverTimeMs() >= l.dsqUntil then
    dsqGameFlag('tow not done', 'Unsporting behaviour - no tow to the pits')
  end
end
-- ============================================================
-- Edited file: a record on this computer with a wrong checksum was edited (decision: edited file = broken checksum =
-- ban). The car is disqualified at once (game black flag, controls locked) and the [RC] line asks for the ban. The
-- race director client (race control mode, logged as admin) reads that line and sends /ban <car ID> (ACSM); without
-- it connected, the line stays in the server log as a pending ban.
-- ============================================================

local Ban = { pending = nil, done = false }

-- Seen while loading the records (session start); applied in the next update, after the records are loaded
Record.onTampered = function(list)
  if not Ban.done then Ban.pending = Ban.pending or list end
end

function Ban.update()
  if not Ban.pending or Ban.done then return end
  local list = Ban.pending
  Ban.pending = nil
  Ban.done = true
  ac.log('race-control: edited record file (' .. list .. '): DSQ and ban pending')
  carDsq(1, TEXTS.editedFile, nil, string.format(TEXTS.editedFileDetail, list, ac.getCar(0).sessionID))
  dsqGameFlag('edited file')
end
-- ============================================================
-- Drive-through of the KMR. The KMR stays as it is (drive_through_no_kick on): it gives the DT and tells the driver in
-- the chat. In the race, the script puts that DT in the list (category K<n>, deadline from the message) and it follows
-- these rules: paid by a pit pass, added to the stop & go, DSQ if not served. In practice and qualifying the KMR DT
-- (carried by the KMR to the next race) is relaxed: not in the list, only in the log. Except the pit exit line crossing
-- (K1): always a DT0 in the list, in every session, whatever deadline the KMR message gives (rule 24).
-- Messages (KMR language file v1.6f): "Penalty: drive-through before the end of this lap <reason>." = DT0;
-- "Penalty: drive-through within <n> lap(s) <reason>." = DT<n>; "... to clear during the next race <reason>." = relaxed.
-- The chat handler only keeps the message (state.kmrMessages); it is read here, in script.update.
-- ============================================================

local KmrDT = {}
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  -- Reason of the message -> category (TEXTS.kmrReasons)
  local KMR_REASONS = {
    { 'crossing the pit exit line', 'K1' },
    { 'pit lane speeding', 'K2' },
    { 'reaching the infraction limit', 'K3' },
    { 'colliding with a car that was lapping you', 'K4' },
    { 'colliding with a car in the hotlap', 'K5' },
    { 'disturbing another driver hotlap', 'K6' },
    { 'driving in reverse gear', 'K7' },
    { 'parking the car in proximity of the track', 'K8' },
    { 'too many collisions', 'K9' },
    { 'speeding during the virtual safety car', 'K10' },
    { 'slowing down too much during the virtual safety car', 'K11' },
    { 'violating the overtake restriction', 'K12' },
    { 'cutting', 'K13' },
    { 'ignoring the blue flags', 'K14' },
    { 'rejoining the track at high speed', 'K15' },
  }

  local function category(low)
    for _, r in ipairs(KMR_REASONS) do
      if low:find(r[1], 1, true) then return r[2] end
    end
    return 'K0'
  end

  -- Deadline of the message: laps (0 = this lap), 'next race', or nil (not a DT given now)
  local function deadline(low)
    if low:find('next race', 1, true) then return 'next race' end
    if low:find('this lap', 1, true) then return 0 end
    local n = low:match('within (%d+) lap')
    if n then return tonumber(n) end
    return nil
  end

  function KmrDT.update()
    local msgs = state.kmrMessages
    if #msgs == 0 then return end
    state.kmrMessages = {}
    for _, text in ipairs(msgs) do
      local low = text:lower()
      local laps = low:find('penalty', 1, true) and deadline(low)
      if laps then
        local cat = category(low)
        local base = TEXTS.kmrReasons[cat]
        if cat == 'K1' then laps = 0 end
        if cat ~= 'K1' and (laps == 'next race' or sim.raceSessionType ~= ac.SessionType.Race) then
          ac.log('race-control: KMR drive-through relaxed (' .. cat .. '): ' .. text)
          rcLog('Drive-through relaxed', base .. ' - issued by KMR for the next race, not carried over by Race Control')
        elseif not (state.dtDsqActive or state.pitDsqActive) then
          ac.log(string.format('race-control: KMR drive-through DT%d (%s): %s', laps, cat, text))
          rcLog('Drive-through DT' .. laps, base .. ' - issued by KMR, recorded by Race Control')
          listAdd(cat, laps)
          Rules.finalize()
        end
      end
    end
  end
end
-- ============================================================
-- Race Control commands: sent by an admin from the ACSM live timing (send chat to the driver, or broadcast chat to
-- everyone). Only a message from the server (senderCarIndex = -1) is a command: a line typed in the chat by a driver
-- is not. The chat handler keeps the line (state.rcCommands, hidden from the chat); it is read here, in script.update.
--   RC <ACTION> <ID> [value] [- reason]
--   ID: Car ID of the server (entry list slot, the same as in /kick 4: car.sessionID) or GUID of the driver (17
--   digits; only while that driver is in the car). The number of the livery is not an ID (it can repeat).
--   Relaxing:  RELAX <ID> ALL | DT | SD | HOLD | REPAIR | DSQ     UNLOCK <ID>
--   Penalties: DT <ID> [laps]   HOLD <ID> <seconds>   TELEPORT <ID>   DSQ <ID>   LOCK <ID> <seconds>
-- Every command goes to the server log ([RC] line) and to the driver's message box; the car record is kept up to date.
-- ============================================================

local RcCommand = {}
do
  local LOCK_MAX_SECONDS = 86400

  -- The command is for this car: Car ID of the server or GUID of the driver in the car
  local function isMine(id)
    if #id >= 17 then return id == tostring(ac.getUserSteamID() or '') end
    return tonumber(id) == ac.getCar(0).sessionID
  end

  local function done(what, detail)
    local text = detail and detail ~= '' and (what .. ' - ' .. detail) or what
    rcLog('Race Control command', text)
    showNotice(TEXTS.rcTitle, text, nil, SERVER_NOTICE_SECONDS)
  end

  local function relax(what, reason)
    local l = state.list
    local before = listDump()
    if what == 'ALL' then
      Rules.zero()
      l.invalidLap = nil
    elseif what == 'DT' then
      if l.items[1] then listRemove(l.items[1]) end
      listSave()
    elseif what == 'SD' then
      state.slowdowns = {}
      state.cutChecks = {}
      l.endOfLap = {}
      listSave()
    elseif what == 'HOLD' then
      state.hold = nil
      physics.lockUserControlsFor(0)
      PitRecord.save()
    elseif what == 'REPAIR' then
      local r = state.repair
      r.lapsLeft, r.beyondSince, r.class, r.waived = nil, nil, 'normal', true
    elseif what == 'DSQ' then
      local game = l.dsqStage == 1
      l.dsq, l.dsqStage, l.dsqUntil, l.dsqReason = 0, 0, 0, nil
      l.seq = l.seq + 1
      state.dtDsqActive, state.pitDsqActive = false, false
      if game or ac.getCar(0).currentPenaltyType == BLACK_FLAG then physics.setCarPenalty(ac.PenaltyType.ReleaseBlackFlag) end
      physics.lockUserControlsFor(0)
      listSave()
    else
      return false
    end
    done('Relaxed ' .. what, string.format('before %s%s', before, reason ~= '' and (' - ' .. reason) or ''))
    return true
  end

  local function penalty(what, value, reason)
    local why = reason ~= '' and reason or TEXTS.reason.RC
    if what == 'DT' then
      local laps = math.max(math.floor(tonumber(value) or 0), 0)
      if not listAdd('RC', laps) then return true end
      Rules.finalize()
      done('Drive-through DT' .. laps, why)
    elseif what == 'HOLD' then
      local seconds = tonumber(value)
      if not seconds or seconds <= 0 then return false end
      startHold(seconds, why)
      done(string.format('Hold %d s', seconds), why)
    elseif what == 'TELEPORT' then
      -- Not a driver teleport (no tow hold), but no pit pass either: leaving the pits after it pays nothing
      state.tow.ownJumpUntil = state.ui.clock + 2
      state.list.jumped = true
      physics.teleportCarTo(0, ac.SpawnSet.Pits, true)
      done('Teleport to the pits', why)
    elseif what == 'DSQ' then
      carDsq(1, why)
      ac.log('race-control: DSQ by Race Control command')
      showNotice(TEXTS.rcTitle, 'Disqualified - ' .. why, nil, SERVER_NOTICE_SECONDS)
    elseif what == 'LOCK' then
      local seconds = tonumber(value)
      if not seconds or seconds <= 0 then return false end
      physics.lockUserControlsFor(math.min(seconds, LOCK_MAX_SECONDS))
      done(string.format('Controls locked %d s', seconds), why)
    else
      return false
    end
    return true
  end

  function RcCommand.update()
    local cmds = state.rcCommands
    if #cmds == 0 then return end
    state.rcCommands = {}
    for _, line in ipairs(cmds) do
      local body, reason = line, ''
      local cut = line:find(' - ', 1, true)
      if cut then body, reason = line:sub(1, cut - 1), line:sub(cut + 3):gsub('^%s+', ''):gsub('%s+$', '') end
      local action, id, value = body:match('^%s*[Rr][Cc]%s+(%a+)%s+(%d+)%s*(%S*)')
      if action and isMine(id) then
        action, value = action:upper(), value:upper()
        local ok
        if action == 'RELAX' then ok = relax(value, reason)
        elseif action == 'UNLOCK' then
          state.hold = nil
          physics.lockUserControlsFor(0)
          PitRecord.save()
          done('Unlocked', reason)
          ok = true
        else ok = penalty(action, value, reason) end
        ac.log('race-control: command ' .. line .. (ok and '' or ' (not understood)'))
        if not ok then rcLog('Race Control command not understood', line) end
      end
    end
  end
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

-- Unpaid slowdown: rule set per session (DT -> DT0 of the category; DSQ -> direct)
local function onSlowdownUnpaid(cat, endOfLap, inPit)
  local unpaid = config.unpaid[sim.raceSessionType]
  if not unpaid or unpaid.penalty == 'NONE' then return end
  if unpaid.penalty == 'DSQ' then
    carDsq(1, TEXTS.reason[cat] .. ' - slowdown not served')
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

local SLOWDOWN_PULSE_MAX_HZ = 6
local SLOWDOWN_PULSE_MIN_HZ = 1

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
  -- Pulse of the numbers in the slowdown box: SLOWDOWN_PULSE_MAX_HZ x (time to pay / deadline left), faster the closer
  -- the deadline; steady while the driver is paying, and below SLOWDOWN_PULSE_MIN_HZ (deadline still long)
  for cat, sd in pairs(current) do
    -- A hold or DSQ cleared the list and the slowdowns: nothing else is processed
    if state.slowdowns ~= current then return end
    if sd.active then
      local finished = false
      sd.paying = car.gas <= sd.maxGas and canPay
      local hz = SLOWDOWN_PULSE_MAX_HZ * math.min(math.max(sd.toPay / math.max(sd.deadlineLeft, 0.001), 0), 1)
      sd.pulseHz = (sd.paying or hz < SLOWDOWN_PULSE_MIN_HZ) and 0 or hz
      sd.phase = sd.pulseHz > 0 and ((sd.phase or 0) + 2 * math.pi * sd.pulseHz * dt) % (2 * math.pi) or 0
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
-- Detection: leaving the pit lane (end of the pit lane, isInPitlane) with the session closed. This is not the pit exit
-- line (the line that bounds the pit exit area, detected by the KMR and applied as a KMR drive-through, KmrDT).
-- ============================================================

local function applyKMR(car, r)
  if r.penalty == 'DSQ' then
    queueCommand(string.format('/kmr player_kick %d', car.sessionID))
  end
end

local function onPitViolation(car, r)
  if r.penalty ~= 'DSQ' then return end
  if config.mode == 'CSP' then
    carDsq(2, 'Pit lane left with the session closed')
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
-- Time constant of the gain meter (seconds)
local LIFT_SMOOTH_SECONDS = 0.35
local SPIN_MIN_SPEED_KMH = 5

-- The reference belongs to the car (decision of 26/09): saved in the car record (list 'gain'), so it survives a
-- reconnection and goes to the next driver in a driver swap. Body: <zone>:<t0>,<t1>,...;<zone>:... (ms)
local GainRef = { seq = 0 }

function GainRef.encode()
  local parts = {}
  for zi, ref in pairs(state.zoneRef) do
    local t = {}
    for i = 0, GAIN_SAMPLES do t[#t + 1] = tostring(math.floor(ref[i] + 0.5)) end
    parts[#parts + 1] = zi .. ':' .. table.concat(t, ',')
  end
  return table.concat(parts, ';')
end

function GainRef.apply(body)
  local refs = {}
  for zi, values in tostring(body or ''):gmatch('(%d+):([%d,]+)') do
    local ref, i = {}, 0
    for v in values:gmatch('%d+') do ref[i] = tonumber(v); i = i + 1 end
    if i == GAIN_SAMPLES + 1 then refs[tonumber(zi)] = ref end
  end
  state.zoneRef = refs
end

function GainRef.save()
  GainRef.seq = GainRef.seq + 1
  Record.save('gain', GainRef.seq, GainRef.encode())
end

function GainRef.load()
  local body, seq = Record.load('gain')
  state.zoneRef = {}
  GainRef.seq = seq or 0
  if body then GainRef.apply(body) end
end

RecordSync.restorers.gain = function(body, seq)
  if seq < GainRef.seq then return end
  GainRef.seq = seq
  GainRef.apply(body)
  ac.log('race-control: gain filter references from the other drivers')
end

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
            -- Loss of control anywhere in the zone passage: a cut in it is discarded
            if car.speedKmh > SPIN_MIN_SPEED_KMH and driftAngle(car) > config.cutSpinAngle then pass.spun = true end
            if not inZone then
              state.zonePass[zi] = nil
              if not pass.dirty and pass.nextIdx > GAIN_SAMPLES then
                local ref = state.zoneRef[zi]
                if not ref or pass.samples[GAIN_SAMPLES] < ref[GAIN_SAMPLES] then
                  state.zoneRef[zi] = pass.samples
                  GainRef.save()
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
    local limit = cc.ref and refAt(cc.ref, p) * (1 + zone.gainTolerance / 100) or 0
    cc.margin = limit > 0 and (elapsed / limit - 1) or 0
    -- Meter value: follows the margin smoothly (LIFT_SMOOTH_SECONDS), so it can be read
    local k = cc.lastT and math.min((sim.time - cc.lastT) / 1000 / LIFT_SMOOTH_SECONDS, 1) or 1
    cc.shown = cc.shown and (cc.shown + (cc.margin - cc.shown) * k) or cc.margin
    cc.lastT = sim.time
    if car.speedKmh > SPIN_MIN_SPEED_KMH and driftAngle(car) > config.cutSpinAngle then cc.spun = true end
    local back = car.wheelsOutside <= zone.maxWheelsOut
    if car.isInPitlane then
      state.cutChecks[zi] = nil
    elseif back or not inZone then
      state.cutChecks[zi] = nil
      if cc.spun then
        ac.log(string.format('race-control: cut %s discarded: spin', zone.category))
      elseif not cc.ref then
        -- No reference yet: slowdown (the car is back on track without a spin)
        startSlowdown(zone, cc.rule, cc.lapCount)
        queueChat(TEXTS.cut.SLOWDOWN)
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
    -- After the DSQ a new infraction is only logged (decision 17)
    if state.dtDsqActive or state.pitDsqActive then
      ac.log(string.format('race-control: cut %s after the DSQ: logged, not applied', zone.category))
      return
    end
    local ref = state.zoneRef[zoneIndex]
    local pass = state.zonePass[zoneIndex]
    if r.penalty == 'SLOWDOWN' then
      -- Decided when the car is back on track: a spin in the zone passage discards the cut; with a reference, the gain
      -- decides (gain filter); without one, slowdown
      state.cutChecks[zoneIndex] = { zone = zone, rule = r, lapCount = lapCount, t0 = pass and pass.t0 or sim.time,
        ref = pass and ref or nil, margin = 0, spun = pass and pass.spun or false }
    elseif r.penalty == 'DT' then
      rcLog('Drive-through', TEXTS.reason[zone.category])
      if car.isInPitlane then Rules.slowdownEndOfLap(zone.category) else Rules.slowdownMidLap(zone.category) end
      queueChat(TEXTS.cut.DT)
    elseif r.penalty == 'DSQ' then
      carDsq(1, TEXTS.reason[zone.category])
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

-- Stop & go (red): stopped at the pit place, interrupted, last lap, overdue or pending
local function sgText(it)
  if StopAndGo.stopping then return string.format(TEXTS.sgStopped, mmss(StopAndGo.remainingMs(it) / 1000)) end
  if StopAndGo.resume then return string.format(TEXTS.sgInterrupted, mmss(StopAndGo.remainingMs(it) / 1000)) end
  -- Practice and qualifying: the deadline over does not disqualify (rule 25), the stop & go is overdue
  if it.laps < 0 and sim.raceSessionType ~= ac.SessionType.Race then
    return string.format(TEXTS.sgOverdue, sgSeconds(it))
  end
  return string.format(it.laps <= 0 and TEXTS.sgLastLap or TEXTS.sgPending, sgSeconds(it))
end

local function itemText(it)
  if it.kind:sub(1, 2) == 'SG' then return sgText(it) end
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
-- A cell returns nil (off) or { value = text, color = key of PANEL_COLORS, quiet = true when it is shown while the
-- panel is on but does not turn the panel on by itself }.
-- ============================================================

local Panel = {}

-- Driver swaps of this car kept by the other drivers
RecordSync.restorers.swap = function(body)
  local before = state.swap.count
  SwapRecord.apply(body)
  if state.swap.count > before then
    ac.log('race-control: driver swaps ' .. state.swap.count .. ' (from the other drivers)')
  end
end

function Panel.cellPit()
  local s, e = PitStops.window()
  if not s or not sim.isSessionStarted then return nil end
  local t = sessionElapsedMs()
  if t < s then return nil end
  if state.pit.done then return { value = TEXTS.pitDone, color = 'dim' } end
  if t <= e then return { value = string.format(TEXTS.pitOpen, mmss2((e - t) / 1000)), color = 'yellow' } end
  return { value = TEXTS.pitMissed, color = 'red' }
end

-- SWAP: driver swaps, done | required (0 required = swaps allowed, none mandatory: done | 0). Off when driver swaps
-- are disabled or the required number is not informed. Always shown while the panel is on, but it turns the panel on
-- only inside the pit lane, where it lights up green; on track it is gray and quiet (the countdown, WAIT and GO stay
-- in the driver swap panel).
function Panel.cellSwap()
  if not config.swapOn() or not config.swapRequired then
    return nil
  end
  local lit = ac.getCar(0).isInPitlane
  return { value = string.format(TEXTS.swapCount, state.swap.valid, config.swapRequired), color = lit and 'green' or 'dim',
    quiet = not lit }
end

-- TRACK: CODE-80 (VSC / SC / CODE-80) or the flag shown to the driver
function Panel.cellTrack()
  if state.code80 then return { value = state.code80, color = 'yellow' } end
  local flag = sim.raceFlagType
  if flag == ac.FlagType.Caution then return { value = TEXTS.trackYellow, color = 'yellow' } end
  if flag == ac.FlagType.FasterCar then return { value = TEXTS.trackBlue, color = 'blue' } end
  return nil
end

-- PENALTIES: DSQ, hold, or the first two drive-throughs with origin and deadline ("SD1 DT0 · PSE DT1 +1")
function Panel.cellPenalties()
  if state.dtDsqActive or state.pitDsqActive then return { value = TEXTS.penDsq, color = 'red' } end
  if state.hold then return { value = TEXTS.penHold, color = 'red' } end
  local items = state.list.items
  if #items == 0 then return nil end
  local sg = config.sg and sgItem()
  if sg then return { value = string.format(TEXTS.penSG, sgSeconds(sg), sgCount(sg)), color = 'red' } end
  local parts = {}
  for i = 1, math.min(#items, 2) do parts[#parts + 1] = items[i].cat .. ' ' .. itemPriority(items[i]) end
  local text = table.concat(parts, ' · ')
  if #items > 2 then text = text .. string.format(' +%d', #items - 2) end
  return { value = text, color = 'yellow' }
end

-- Shared: message line. A new penalty or a server message is shown for a few seconds; otherwise the most important
-- thing now: hold, penalty being paid, CODE-80, open pit window.
function Panel.message()
  -- Stopped serving the stop & go: the countdown comes before any notice
  local sg = config.sg and sgItem()
  if sg and StopAndGo.stopping then return itemText(sg), 'red' end
  local notice = state.ui.notice
  -- A stop & go is red from its first notice; other notices yellow
  if notice then return notice.text, (notice.item and notice.item.kind:sub(1, 2) == 'SG') and 'red' or 'yellow' end
  if state.hold then
    return string.format(TEXTS.hold, mmss(PitRecord.holdLeft()), state.hold.text), 'red'
  end
  local items = state.list.items
  if sg then return itemText(sg), 'red' end
  if items[1] then return itemText(items[1]), 'yellow' end
  if state.code80 then return TEXTS.code80, 'yellow' end
  local pit = Panel.cellPit()
  if pit and not state.pit.done and pit.color == 'yellow' then return TEXTS.pitOpenMsg, 'yellow' end
  return nil
end

-- Shared: frame color. Red with a hold, a stop & go or DSQ; fixed yellow during CODE-80; green for the green flag message;
-- yellow / blue flag: blinks in the flag color (back to light gray when the blink is off).
function Panel.frameColor()
  if state.hold or state.dtDsqActive or state.pitDsqActive or (config.sg and sgItem()) then return BORDER_RED end
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
-- RACE CONTROL 112 (15 px), OPEN 00:00 71, 88 | 88 40, CODE-80 54, PENALTIES "PSE DT1 · PSE DT1 +9" 140 (13 px):
-- 128 + 87 + 56 + 70 + 156 = 497 px, plus 20 px of borders = 517 px
local PANEL_WIDTH = 520

-- ============================================================
-- Dot matrix text (5 x 7 dots per character), like the display of an old car stereo. Drawn dot by dot, so it looks
-- the same on every computer (no font file is needed). Unknown characters are drawn as a space.
-- ============================================================

local DOT_MATRIX_GLYPHS = {
  ['0'] = { '.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.' },
  ['1'] = { '..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.' },
  ['2'] = { '.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####' },
  ['3'] = { '#####', '...#.', '..#..', '...#.', '....#', '#...#', '.###.' },
  ['4'] = { '...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.' },
  ['5'] = { '#####', '#....', '####.', '....#', '....#', '#...#', '.###.' },
  ['6'] = { '..##.', '.#...', '#....', '####.', '#...#', '#...#', '.###.' },
  ['7'] = { '#####', '....#', '...#.', '..#..', '.#...', '.#...', '.#...' },
  ['8'] = { '.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.' },
  ['9'] = { '.###.', '#...#', '#...#', '.####', '....#', '...#.', '.##..' },
  A = { '.###.', '#...#', '#...#', '#...#', '#####', '#...#', '#...#' },
  B = { '####.', '#...#', '#...#', '####.', '#...#', '#...#', '####.' },
  C = { '.###.', '#...#', '#....', '#....', '#....', '#...#', '.###.' },
  D = { '###..', '#..#.', '#...#', '#...#', '#...#', '#..#.', '###..' },
  E = { '#####', '#....', '#....', '####.', '#....', '#....', '#####' },
  F = { '#####', '#....', '#....', '####.', '#....', '#....', '#....' },
  G = { '.###.', '#...#', '#....', '#.###', '#...#', '#...#', '.####' },
  H = { '#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#' },
  I = { '.###.', '..#..', '..#..', '..#..', '..#..', '..#..', '.###.' },
  J = { '..###', '...#.', '...#.', '...#.', '...#.', '#..#.', '.##..' },
  K = { '#...#', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#' },
  L = { '#....', '#....', '#....', '#....', '#....', '#....', '#####' },
  M = { '#...#', '##.##', '#.#.#', '#.#.#', '#...#', '#...#', '#...#' },
  N = { '#...#', '#...#', '##..#', '#.#.#', '#..##', '#...#', '#...#' },
  O = { '.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.' },
  P = { '####.', '#...#', '#...#', '####.', '#....', '#....', '#....' },
  Q = { '.###.', '#...#', '#...#', '#...#', '#.#.#', '#..#.', '.##.#' },
  R = { '####.', '#...#', '#...#', '####.', '#.#..', '#..#.', '#...#' },
  S = { '.####', '#....', '#....', '.###.', '....#', '....#', '####.' },
  T = { '#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..' },
  U = { '#...#', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.' },
  V = { '#...#', '#...#', '#...#', '#...#', '#...#', '.#.#.', '..#..' },
  W = { '#...#', '#...#', '#...#', '#.#.#', '#.#.#', '#.#.#', '.#.#.' },
  X = { '#...#', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '#...#' },
  Y = { '#...#', '#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..' },
  Z = { '#####', '....#', '...#.', '..#..', '.#...', '#....', '#####' },
  ['.'] = { '.....', '.....', '.....', '.....', '.....', '.##..', '.##..' },
  ['-'] = { '.....', '.....', '.....', '#####', '.....', '.....', '.....' },
}
local DOT_MATRIX_COLS = 6   -- 5 dots + 1 dot of spacing per character

local DotMatrix = {}

-- Width of a text in dot-pitch units (multiply by the pitch in px)
function DotMatrix.width(text)
  return #text * DOT_MATRIX_COLS - 1
end

-- Draws the text with its top-left corner at pos. pitch: distance between dots (px); on: lit dots; off: unlit dots
-- of each character cell (nil = not drawn)
function DotMatrix.draw(text, pos, pitch, on, off)
  local size = pitch * 0.72
  local up = text:upper()
  for i = 1, #up do
    local glyph = DOT_MATRIX_GLYPHS[up:sub(i, i)]
    local x0 = pos.x + (i - 1) * DOT_MATRIX_COLS * pitch
    for row = 1, 7 do
      local line = glyph and glyph[row] or '.....'
      for col = 1, 5 do
        local lit = line:sub(col, col) == '#'
        local color = lit and on or off
        if color then
          local x = x0 + (col - 1) * pitch
          local y = pos.y + (row - 1) * pitch
          ui.drawRectFilled(vec2(x, y), vec2(x + size, y + size), color, size * 0.3)
        end
      end
    end
  end
end

-- ============================================================
-- Race Control panel: opening
-- Full opening the first time this computer connects to this server (mark kept in ac.storage, per server); on the
-- next connections, the short opening: the panel lights up off, STATUS OK in green dot matrix, then goes to sleep;
-- if there is already something to show (restored penalties, CODE-80), no opening: the panel shows it directly.
-- It starts when the driver leaves the setup menu (the pits menu with the Drive button;
-- the menu has to be seen open first, since sim.isInMainMenu is still false in the first frames after the script
-- loads; if the menu is never seen, it starts when the car moves):
-- like the dashboard of a car when it is switched on, here cosmetic, in this order:
-- 1. wake: the panel fades in with everything off (no border light, no text);
-- 2. light: the border lights up, then the title, then the cell titles, these still off (dark, no value);
-- 3. lamp test, as if checking every system: everything cycles through all it can show (every cell with each of its
--    values and colors, the frame colors and the message line texts);
-- 4. the message line shows the name and version in dot matrix, like the display of an old car stereo: it fades in
--    centered, then scrolls to the left, disappearing at the edge of the panel, until it is all gone;
-- 5. status: STATUS OK in green dot matrix, green frame;
-- then the panel goes to sleep: hidden, unless there is something to show. It
-- does not repeat between sessions, on reconnections or on script reloads, and there is none for a driver taking over
-- the car in a driver swap (the session is already running): if the swap is known only during the opening, it
-- stops there. From the lamp test on, the other boxes do theirs one after the
-- other, each in its own place and never on top of each other, with all their content moving: slowdown box (numbers
-- counting down and pulsing), gain filter box (mark sweeping the bar), driver swap panel (countdown; only when driver
-- swaps are on). After it, the
-- panel is shown only when a cell or the message line has something to show.
-- ============================================================

local Intro
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local INTRO_WAKE = 0.6        -- seconds of the fade in, everything off
  local INTRO_LIGHT_STEP = 0.25 -- seconds between border, title and cell titles lighting up
  local INTRO_LIGHT = 3 * INTRO_LIGHT_STEP
  local INTRO_BULB = 2.4        -- seconds of the lamp test of the main panel
  local INTRO_CYCLE_STEP = 0.3  -- seconds each value stays lit while cycling
  local INTRO_FADE_IN = 0.6     -- seconds of the fade in
  local INTRO_HOLD = 0.8        -- seconds standing still before scrolling
  local INTRO_SCROLL_SPEED = 180  -- px per second at 1080p
  local INTRO_DOT_PITCH = 3     -- px at 1080p between two dots of the dot matrix
  local INTRO_TEXT_AREA = PANEL_WIDTH - 32  -- px at 1080p of the message line inside the panel
  -- Text start (centered in the message line) and the scroll needed to take it all out of the panel, px at 1080p
  local INTRO_TEXT_W = DotMatrix.width(TEXTS.introText) * INTRO_DOT_PITCH
  local INTRO_TEXT_X = (INTRO_TEXT_AREA - INTRO_TEXT_W) / 2
  local INTRO_SCROLL = (16 + INTRO_TEXT_X + INTRO_TEXT_W) / INTRO_SCROLL_SPEED
  local INTRO_STATUS = 1.5      -- seconds of STATUS OK
  local INTRO_STATUS_X = (INTRO_TEXT_AREA - DotMatrix.width(TEXTS.introStatus) * INTRO_DOT_PITCH) / 2
  local INTRO_TOTAL = INTRO_WAKE + INTRO_LIGHT + INTRO_BULB + INTRO_FADE_IN + INTRO_HOLD + INTRO_SCROLL + INTRO_STATUS
  local INTRO_MOVING_KMH = 5    -- the car moving counts as out of the menu when the menu was never seen
  local INTRO_BOX_STEP = 1.2    -- seconds each secondary box stays lit, one after the other

  -- Shown once per process (ac.store survives script reloads, not leaving the server); full opening once per server
  -- on this computer (ac.storage survives closing the game)
  local INTRO_SHOWN_KEY = 'race-control.intro'
  local INTRO_SERVER_PREFIX = 'rc.intro.'
  local INTRO_SHORT_TOTAL = INTRO_WAKE + INTRO_STATUS

  local function introServerKey()
    return INTRO_SERVER_PREFIX .. tostring(ac.getServerIP() or '') .. ':' .. tostring(ac.getServerPortTCP() or '')
  end

  Intro = { t0 = nil, done = ac.load(INTRO_SHOWN_KEY) == 1, menuSeen = false,
    short = ac.storage[introServerKey()] == '1' }

  -- Something to show already (restored penalties, slowdown, CODE-80, hold, DSQ): no short opening
  local function introHasInfo()
    return #state.list.items > 0 or next(state.slowdowns) ~= nil or state.code80 ~= nil or state.hold ~= nil
      or state.dtDsqActive or state.pitDsqActive
  end

  -- Lamp test: what each titled cell, the frame and the message line cycle through (value, color key)
  local INTRO_CYCLE = {
    [TEXTS.cellPit] = { { string.format(TEXTS.pitOpen, '00:00'), 'yellow' }, { TEXTS.pitDone, 'dim' },
      { TEXTS.pitMissed, 'red' } },
    [TEXTS.cellSwap] = { { string.format(TEXTS.swapCount, 0, 1), 'dim' }, { string.format(TEXTS.swapCount, 1, 1), 'green' } },
    [TEXTS.cellTrack] = { { TEXTS.trackYellow, 'yellow' }, { TEXTS.trackBlue, 'blue' }, { 'VSC', 'yellow' },
      { 'SC', 'yellow' }, { 'CODE-80', 'yellow' } },
    [TEXTS.cellPenalties] = { { 'SD1 DT0', 'yellow' }, { 'SD1 DT0 · PSE DT1 +1', 'yellow' },{ TEXTS.penHold, 'red' }, { TEXTS.penDsq, 'red' } },
  }
  local INTRO_FRAMES = { 'base', 'yellow', 'blue', 'red', 'green' }
  local INTRO_MESSAGES = {
    { 'DT0 - Drive-through - ' .. TEXTS.reason.SD1, 'yellow' },
    { string.format(TEXTS.hold, mmss(45), TEXTS.holdTwoDT), 'red' },
    { TEXTS.code80, 'yellow' },
    { TEXTS.pitOpenMsg, 'yellow' },
  }

  local function cycled(list, t)
    return list[math.floor(t / INTRO_CYCLE_STEP) % #list + 1]
  end

  -- Lamp test values at time t of the opening (pure): cell value and color for a title, frame color key, message
  function Intro.lampCell(title, t)
    local item = INTRO_CYCLE[title] and cycled(INTRO_CYCLE[title], t)
    return item and { value = item[1], color = item[2] } or nil
  end
  function Intro.lampFrame(t) return cycled(INTRO_FRAMES, t) end
  function Intro.lampMessage(t)
    local item = cycled(INTRO_MESSAGES, t)
    return item[1], item[2]
  end

  -- Starts when the setup menu closes (or the car moves, if the menu was never seen); ends after INTRO_TOTAL
  function Intro.update(car)
    if Intro.done then return end
    if state.swap.entered then
      Intro.done = true
      ac.store(INTRO_SHOWN_KEY, 1)
      return
    end
    if not Intro.t0 then
      if sim.isInMainMenu then
        Intro.menuSeen = true
      elseif Intro.menuSeen or car.speedKmh > INTRO_MOVING_KMH then
        ac.store(INTRO_SHOWN_KEY, 1)
        ac.storage[introServerKey()] = '1'
        if Intro.short and introHasInfo() then
          Intro.done = true
          ac.log('race-control: opening skipped: information to show')
          return
        end
        Intro.t0 = state.ui.clock
        ac.log('race-control: opening ' .. (Intro.short and 'short' or 'full'))
      end
    elseif state.ui.clock - Intro.t0 >= (Intro.short and INTRO_SHORT_TOTAL or INTRO_TOTAL) then
      Intro.done = true
    end
  end

  -- Current frame of the opening (reads only its own state): nil when not running; otherwise, by phase:
  -- { phase = 'wake', alpha } fading in, everything off;
  -- { phase = 'light', title, items } border lit; title and cell titles (off mode) once their flags are true;
  -- { phase = 'bulb', bulb = true, t } lamp test (values from Intro.lampCell / lampFrame / lampMessage);
  -- { phase = 'text' or 'status', text, x = px at 1080p from the start of the message line (goes negative while
  --   scrolling), pitch, alpha }.
  -- From the lamp test on, with box = secondary box lit now ('slowdown', 'lift', 'swap' or nil) and boxK = 0..1 inside
  -- its slot
  function Intro.frame()
    if Intro.done or not Intro.t0 then return nil end
    local t = state.ui.clock - Intro.t0
    if t < INTRO_WAKE then return { phase = 'wake', alpha = t / INTRO_WAKE } end
    t = t - INTRO_WAKE
    -- Short opening: straight to STATUS OK
    if Intro.short then
      if t < INTRO_STATUS then
        return { phase = 'status', text = TEXTS.introStatus, x = INTRO_STATUS_X, pitch = INTRO_DOT_PITCH, alpha = 1 }
      end
      return nil
    end
    if t < INTRO_LIGHT then
      return { phase = 'light', title = t >= INTRO_LIGHT_STEP, items = t >= 2 * INTRO_LIGHT_STEP }
    end
    t = t - INTRO_LIGHT
    -- Secondary boxes: one after the other from the start of the lamp test
    local boxes = { 'slowdown', 'lift' }
    if config.swapOn() then boxes[#boxes + 1] = 'swap' end
    local slot = math.floor(t / INTRO_BOX_STEP)
    local box = boxes[slot + 1]
    local boxK = (t - slot * INTRO_BOX_STEP) / INTRO_BOX_STEP   -- 0..1 inside the box slot
    if t < INTRO_BULB then return { phase = 'bulb', bulb = true, t = t, box = box, boxK = boxK } end
    local text = { phase = 'text', text = TEXTS.introText, x = INTRO_TEXT_X, pitch = INTRO_DOT_PITCH, alpha = 1, box = box,
      boxK = boxK }
    t = t - INTRO_BULB
    if t < INTRO_FADE_IN then
      text.alpha = t / INTRO_FADE_IN
      return text
    end
    t = t - INTRO_FADE_IN
    if t < INTRO_HOLD then return text end
    t = t - INTRO_HOLD
    if t < INTRO_SCROLL then
      text.x = INTRO_TEXT_X - INTRO_SCROLL_SPEED * t
      return text
    end
    t = t - INTRO_SCROLL
    if t < INTRO_STATUS then
      return { phase = 'status', text = TEXTS.introStatus, x = INTRO_STATUS_X, pitch = INTRO_DOT_PITCH, alpha = 1,
        box = box, boxK = boxK }
    end
    return nil
  end
end
-- ============================================================
-- Screens moved by the driver with the mouse: click on a screen, hold and drag (move cursor, the four arrows).
-- Double click puts it back in its place. Groups: 'panel' (Race Control panel with the boxes below it, moved together),
-- 'pitbox' (pit stop box), 'setup' (setup status), 'status' (car status). The position is an offset from the default
-- place, in px at 1080p (the same place on any resolution), kept in this computer (ac.storage) for every session.
-- ============================================================

local Drag = {}
do
  local GROUPS = { 'panel', 'pitbox', 'setup', 'status' }
  local layout = {}
  for _, g in ipairs(GROUPS) do layout[g .. 'X'] = 0; layout[g .. 'Y'] = 0 end
  local stored = ac.storage(layout, 'screen_')
  local offsets = {}
  for _, g in ipairs(GROUPS) do offsets[g] = vec2(tonumber(stored[g .. 'X']) or 0, tonumber(stored[g .. 'Y']) or 0) end

  Drag.group = nil       -- group of the boxes being drawn now (drawPanel registers their area)
  local rects = {}       -- area of each group drawn in this frame: { min = vec2, max = vec2 }
  local active           -- { group, grab = mouse - offset (px), min, max, offset (px) at the start }

  -- Offset of a group in px on this screen
  function Drag.offset(group, h)
    local o = offsets[group]
    return vec2(o.x * h / 1080, o.y * h / 1080)
  end

  -- Area drawn by the current group (called by drawPanel)
  function Drag.hit(p1, p2)
    local g = Drag.group
    if not g then return end
    local r = rects[g]
    if r then
      r.min = vec2(math.min(r.min.x, p1.x), math.min(r.min.y, p1.y))
      r.max = vec2(math.max(r.max.x, p2.x), math.max(r.max.y, p2.y))
    else
      rects[g] = { min = vec2(p1.x, p1.y), max = vec2(p2.x, p2.y) }
    end
  end

  local function save(g)
    stored[g .. 'X'] = offsets[g].x
    stored[g .. 'Y'] = offsets[g].y
  end

  -- End of the frame: hover shows the move cursor; click, hold and drag moves the group (kept on screen); release keeps
  -- the place; double click puts it back
  function Drag.finish(w, h)
    Drag.group = nil
    local k = h / 1080
    local m = ui.mousePos()
    if active then
      local a = active
      if ui.mouseDown() then
        local nx = math.min(math.max(m.x - a.grab.x, a.o.x - a.min.x), a.o.x + w - a.max.x)
        local ny = math.min(math.max(m.y - a.grab.y, a.o.y - a.min.y), a.o.y + h - a.max.y)
        offsets[a.group] = vec2(nx / k, ny / k)
      else
        save(a.group)
        active = nil
      end
      ui.setMouseCursor(ui.MouseCursor.ResizeAll)
      ui.captureMouse(true)
      rects = {}
      return
    end
    if m.x >= 0 then
      for g, r in pairs(rects) do
        if m.x >= r.min.x and m.x <= r.max.x and m.y >= r.min.y and m.y <= r.max.y then
          ui.setMouseCursor(ui.MouseCursor.ResizeAll)
          ui.captureMouse(true)
          if ui.mouseDoubleClicked() then
            offsets[g] = vec2(0, 0)
            save(g)
          elseif ui.mouseClicked() then
            local o = Drag.offset(g, h)
            active = { group = g, grab = vec2(m.x - o.x, m.y - o.y), min = r.min, max = r.max, o = o }
          end
          break
        end
      end
    end
    rects = {}
  end
end
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
local COLOR_ORANGE = rgbm(1, 0.54, 0.11, 1)
local COLOR_LIFT_FAST = rgbm(1, 0.3, 0.3, 0.45)
local COLOR_LIFT_SLOW = rgbm(0.2, 0.8, 0.3, 0.35)
local COLOR_DIM = rgbm(0.6, 0.63, 0.65, 1)
-- Race Control panel: dark title of a cell with nothing to show; value colors
local COLOR_CELL_OFF = rgbm(0.23, 0.25, 0.27, 1)
local PANEL_COLORS = {
  title = rgbm(0.96, 0.96, 0.96, 1), dim = rgbm(0.6, 0.63, 0.65, 1), yellow = rgbm(1, 0.85, 0.25, 1),
  red = rgbm(1, 0.3, 0.3, 1), blue = rgbm(0.56, 0.7, 1, 1), green = rgbm(0.45, 1, 0.55, 1),
}
-- Gain meter: position of the limit line and how much margin (fraction of the limit) spans from it to the edge
local LIFT_LIMIT_POS = 0.55
local LIFT_SCALE = 1.8
-- Mark of the gain meter: pulses in white at this rate
local LIFT_CARET_HZ = 2

local function px(v) return math.floor(v + 0.5) end

local function drawText(text, font, size, pos, color)
  ui.pushDWriteFont(font)
  ui.dwriteDrawText(text, size, vec2(px(pos.x), px(pos.y)), color)
  ui.popDWriteFont()
end

-- alpha (optional, default 1): the whole panel fades with it (opening)
local function drawPanel(p1, p2, border, s, alpha)
  Drag.hit(p1, p2)
  local a = alpha or 1
  local r = px(8 * s)
  local o = px(3 * s)
  ui.drawRectFilled(vec2(p1.x + o, p1.y + o), vec2(p2.x + o, p2.y + o), rgbm(0, 0, 0, 0.35 * a), r)
  ui.drawRectFilled(p1, p2, rgbm(0.04, 0.04, 0.05, 0.9 * a), r)
  local i = px(4 * s)
  ui.drawRectFilledMultiColor(vec2(p1.x + i, p1.y + i), vec2(p2.x - i, p2.y - i),
    rgbm(1, 1, 1, 0.06 * a), rgbm(1, 1, 1, 0.06 * a), rgbm(1, 1, 1, 0), rgbm(1, 1, 1, 0))
  if a < 1 then border = rgbm(border.r, border.g, border.b, (border.mult or 1) * a) end
  ui.drawRectFilled(vec2(p1.x + px(3 * s), p1.y + px(8 * s)), vec2(p1.x + px(7 * s), p2.y - px(8 * s)), border,
    px(2 * s))
  ui.drawRect(p1, p2, border, r, nil, 1.5 * s)
end

-- Box with a flag drawn by the script (black flag, or black flag with orange disc) and three lines of text
-- Flag box: the flag on the left, title and two lines. Flag: black (DSQ; with disc = black flag with orange disc), or
-- 'dt' = drive-through flag, split on the diagonal from the bottom left corner to the top right one: white above,
-- black below (the game no longer shows its drive-through message)
local function drawFlagBox(p1, p2, s, border, disc, title, titleColor, line1, line2, flag)
  drawPanel(p1, p2, border, s)
  local f1 = vec2(p1.x + 20 * s, p1.y + 12 * s)
  local f2 = vec2(f1.x + 46 * s, f1.y + 32 * s)
  local dt = flag == 'dt'
  ui.drawRectFilled(vec2(px(f1.x), px(f1.y)), vec2(px(f2.x), px(f2.y)), rgbm(0.02, 0.02, 0.02, 1), px(2 * s))
  if dt then
    ui.drawTriangleFilled(vec2(px(f1.x), px(f1.y)), vec2(px(f2.x), px(f1.y)), vec2(px(f1.x), px(f2.y)),
      rgbm(0.95, 0.95, 0.95, 1))
  end
  ui.drawRect(vec2(px(f1.x), px(f1.y)), vec2(px(f2.x), px(f2.y)), rgbm(0.33, 0.33, 0.33, 1), px(2 * s))
  if disc then ui.drawCircleFilled(vec2(px((f1.x + f2.x) / 2), px((f1.y + f2.y) / 2)), 9 * s, disc, 24) end
  local tx = f2.x + 12 * s
  drawText(title, FONT_TITLE, 14 * s, vec2(tx, p1.y + 5 * s), titleColor)
  drawText(line1 or '', FONT_TEXT, 12 * s, vec2(tx, p1.y + 23 * s), COLOR_TITLE)
  drawText(line2 or '', FONT_MONO, 12 * s, vec2(tx, p1.y + 38 * s), COLOR_TEXT)
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

-- ============================================================
-- Pit stop box on screen (approved screen 11, 80%: 288 x 195 px at 1080p, bottom right corner, 48 px margin).
-- Rows with their value and time; the chosen row is lit; tyre chips lit for the wheels changed; pressure and wing only
-- shown. During the stop: elapsed / total at the bottom.
-- ============================================================

local drawPitBox
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local BOX_W, BOX_H = 288, 195          -- px at 1080p (80% size)
  local BOX_RIGHT, BOX_BOTTOM = 1920 - 1397 - 288, 48
  -- Car status on its right (status_draw.lua: 171 px wide, 48 px from the right edge at 1080p) and the gap between them
  local STATUS_W, STATUS_RIGHT, STATUS_GAP = 171, 48, 1920 - 1397 - 288 - 48 - 171
  local ROW_H = 15
  local COLOR_SEL = rgbm(1, 0.85, 0.25, 1)
  local COLOR_OFF = rgbm(0.45, 0.48, 0.5, 1)
  local num = CarRead.num

  local function wing()
    local out = {}
    for _, sp in ipairs(ac.getSetupSpinners() or {}) do
      if tostring(sp.name):upper():find('WING', 1, true) then out[#out + 1] = tostring(sp.value) end
    end
    return #out > 0 and table.concat(out, ' / ') or '-'
  end

  drawPitBox = function(car, w, h, s)
    local sv = state.pitService
    if not PitBox.open and not sv then return end
    local k = h / 1080
    local bw, bh = BOX_W * s, BOX_H * s
    local o = Drag.offset('pitbox', h)
    -- Its right edge never over the car status, whatever the size of both (screenScale, screens below 1080p)
    local right = math.min(w - BOX_RIGHT * k, w - STATUS_RIGHT * k - STATUS_W * s - STATUS_GAP * k)
    local p1 = vec2(math.floor(right - bw + o.x), math.floor(h - BOX_BOTTOM * k - bh + o.y))
    Drag.group = 'pitbox'
    local p2 = vec2(p1.x + bw, p1.y + bh)
    local p = PitBox.plan(car)
    if sv then p.total = (sv.untilMs - sv.startMs) / 1000 end
    drawPanel(p1, p2, BORDER_GREEN, s)
    drawText(TEXTS.pitBoxTitle, FONT_TITLE, 12 * s, vec2(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    drawTextRight(string.format(TEXTS.pitBoxTotal, mmss(p.total)), FONT_MONO, 11 * s, p2.x - 12 * s, p1.y + 5 * s,
      COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local names = PitBox.compounds()
    local chips = {}
    for _, wIdx in ipairs(PitBox.TYRE_CHOICES[p.tyres][2]) do chips[wIdx] = true end
    local wh = car.wheels or {}
    local rows = {
      { 'fuel', TEXTS.pitFuel, string.format(TEXTS.pitFuelValue, p.fuel, num(car.fuel) + p.fuel), p.times.fuel },
      { 'compound', TEXTS.pitCompound, '< ' .. tostring(ac.getTyresLongName(0, p.compound) or names[p.compound] or '-')
        .. ' >', nil },
      { 'tyres', TEXTS.pitTyres, nil, p.times.tyres },
      { nil, TEXTS.pitPressureFront, string.format('%.1f  %.1f', num(wh[0] and wh[0].tyrePressure),
        num(wh[1] and wh[1].tyrePressure)), nil },
      { nil, TEXTS.pitPressureRear, string.format('%.1f  %.1f', num(wh[2] and wh[2].tyrePressure),
        num(wh[3] and wh[3].tyrePressure)), nil },
      { nil, TEXTS.pitWing, wing(), nil },
      { 'suspension', TEXTS.pitRepairSuspension, nil, p.times.suspension },
      { 'powertrain', TEXTS.pitRepairPowertrain, nil, p.times.powertrain },
      { 'body', TEXTS.pitRepairBody, nil, p.times.body },
    }
    local chosen = PitBox.ROWS[PitBox.row]
    for i, r in ipairs(rows) do
      local y = p1.y + (21 + 4 + (i - 1) * ROW_H) * s
      local sel = not sv and r[1] ~= nil and r[1] == chosen
      local vx = p1.x + 110 * s
      drawText(r[2], FONT_TEXT, 10 * s, vec2(p1.x + 14 * s, y), r[1] and COLOR_TITLE or COLOR_OFF)
      if r[1] == 'tyres' then
        for wIdx = 0, 3 do
          drawText(PitBox.WHEELS[wIdx], FONT_MONO, 10 * s, vec2(vx + wIdx * 24 * s, y),
            chips[wIdx] and (sel and COLOR_SEL or COLOR_SWAP) or COLOR_OFF)
        end
      elseif r[1] == 'suspension' or r[1] == 'powertrain' or r[1] == 'body' then
        local value = p.repair[r[1]] and TEXTS.pitRepairYes
          or (PitBox.damaged(car, r[1]) and TEXTS.pitRepairNo or TEXTS.pitRepairNone)
        drawText(value, FONT_MONO, 10 * s, vec2(vx, y), sel and COLOR_SEL or COLOR_TITLE)
      else
        drawText(r[3], FONT_MONO, 10 * s, vec2(vx, y), sel and COLOR_SEL or (r[1] and COLOR_TITLE or COLOR_OFF))
      end
      if r[4] then drawTextRight(mmss(r[4]), FONT_MONO, 10 * s, p2.x - 12 * s, y, COLOR_TITLE) end
    end
    local elapsed = sv and math.max(p.total - (sv.untilMs - serverTimeMs()) / 1000, 0) or 0
    drawText(sv and TEXTS.pitBoxServing or TEXTS.pitBoxConfirm, FONT_TEXT, 10 * s,
      vec2(p1.x + 14 * s, p2.y - 16 * s), sv and COLOR_SWAP or COLOR_OFF)
    drawTextRight(string.format('%s / %s', mmss(elapsed), mmss(p.total)), FONT_MONO, 10 * s, p2.x - 12 * s,
      p2.y - 16 * s, COLOR_TITLE)
  end
end
-- ============================================================
-- Setup status (approved screen 14, 80%: 384 x 224 px at 1080p, bottom left, mirroring the pit stop box) and car status
-- (approved screen 12, 80%: 171 x 283 px at 1080p, right of the pit stop box, in the corner). Only information, shown
-- with the pit stop box. Setup values from the setup spinners (names of the setup file sections; a value the car does
-- not have shows "-"); the rest from the car state.
-- ============================================================

local drawStatus
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local num = CarRead.num
  local SETUP_W, SETUP_H, SETUP_LEFT = 384, 224, 235
  local STATUS_W, STATUS_H, STATUS_RIGHT = 171, 283, 1920 - 1701 - 171
  local MARGIN = 48
  local COLOR_OFF = rgbm(0.45, 0.48, 0.5, 1)
  local COLOR_OK = rgbm(0.45, 1, 0.55, 1)
  local COLOR_WARN = rgbm(1, 0.85, 0.25, 1)
  local WHEEL = { [0] = 'FL', 'FR', 'RL', 'RR' }

  -- Setup spinner value shown (value x displayMultiplier), or '-'
  local function spinners()
    local out = {}
    for _, sp in ipairs(ac.getSetupSpinners() or {}) do
      local v = num(sp.value) * (tonumber(sp.displayMultiplier) or 1)
      out[tostring(sp.name):upper()] = (math.floor(v) == v) and tostring(v) or string.format('%.1f', v)
    end
    return out
  end

  local function textWidth(text, font, size)
    ui.pushDWriteFont(font)
    local tw = ui.measureDWriteText(text, size).x
    ui.popDWriteFont()
    return tw
  end

  -- Column of rows { line, label, values }: the values start after the widest label of the column and each value after
  -- the widest value of the column, so no label or value runs into the next one
  local function column(p1, s, y0, lh, x, rows)
    local labelW, valueW = 0, 0
    for _, r in ipairs(rows) do
      labelW = math.max(labelW, textWidth(r[2], FONT_TEXT, 9 * s))
      for _, v in ipairs(r[3]) do valueW = math.max(valueW, textWidth(tostring(v or '-'), FONT_MONO, 9 * s)) end
    end
    local vx = p1.x + x * s + labelW + 7 * s
    for _, r in ipairs(rows) do
      local y = y0 + r[1] * lh
      drawText(r[2], FONT_TEXT, 9 * s, vec2(p1.x + x * s, y), COLOR_OFF)
      for i, v in ipairs(r[3]) do
        drawText(tostring(v or '-'), FONT_MONO, 9 * s, vec2(vx + (i - 1) * (valueW + 6 * s), y), COLOR_TITLE)
      end
    end
  end

  local function drawSetup(car, w, h, s)
    local k = h / 1080
    local o = Drag.offset('setup', h)
    local p1 = vec2(math.floor(SETUP_LEFT * k + o.x), math.floor(h - MARGIN * k - SETUP_H * s + o.y))
    Drag.group = 'setup'
    local p2 = vec2(p1.x + SETUP_W * s, p1.y + SETUP_H * s)
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.setupTitle, FONT_TITLE, 12 * s, vec2(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    drawTextRight(string.format(TEXTS.setupLap, car.lapCount + 1), FONT_MONO, 10 * s, p2.x - 12 * s, p1.y + 5 * s,
      COLOR_OFF)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local sp = spinners()
    local wh = car.wheels or {}
    local y0 = p1.y + 26 * s
    local lh = 11 * s
    -- Aero and drive train
    drawText(TEXTS.setupAero, FONT_TITLE, 9 * s, vec2(p1.x + 14 * s, y0), COLOR_TITLE)
    drawText(TEXTS.setupDrive, FONT_TITLE, 9 * s, vec2(p1.x + 14 * s, y0 + 2 * lh), COLOR_TITLE)
    column(p1, s, y0, lh, 14, {
      { 1, TEXTS.setupWing, { sp.WING_1, sp.WING_2 } },
      { 3, TEXTS.setupDiffPower, { string.format('%.0f%%', num(car.differentialPower) * 100) } },
      { 4, TEXTS.setupDiffCoast, { string.format('%.0f%%', num(car.differentialCoast) * 100) } },
      { 5, TEXTS.setupPreload, { string.format('%.0f', num(car.differentialPreload)) } },
      { 6, TEXTS.setupBrakeBias, { string.format('%.1f', num(car.brakeBias) * 100),
        string.format('%.1f', 100 - num(car.brakeBias) * 100) } },
    })
    -- Chassis
    drawText(TEXTS.setupChassis, FONT_TITLE, 9 * s, vec2(p1.x + 130 * s, y0), COLOR_TITLE)
    column(p1, s, y0, lh, 130, {
      { 1, TEXTS.setupHeight, { sp.ROD_LENGTH_LF, sp.ROD_LENGTH_LR } },
      { 2, TEXTS.setupArb, { sp.ARB_FRONT, sp.ARB_REAR } },
      { 3, TEXTS.setupToe .. ' F', { string.format('%.2f', num(wh[0] and wh[0].toeIn)),
        string.format('%.2f', num(wh[1] and wh[1].toeIn)) } },
      { 4, TEXTS.setupToe .. ' R', { string.format('%.2f', num(wh[2] and wh[2].toeIn)),
        string.format('%.2f', num(wh[3] and wh[3].toeIn)) } },
      { 5, TEXTS.setupCamber .. ' F', { string.format('%.1f', num(wh[0] and wh[0].camber)),
        string.format('%.1f', num(wh[1] and wh[1].camber)) } },
      { 6, TEXTS.setupCamber .. ' R', { string.format('%.1f', num(wh[2] and wh[2].camber)),
        string.format('%.1f', num(wh[3] and wh[3].camber)) } },
    })
    -- Suspension
    drawText(TEXTS.setupSuspension, FONT_TITLE, 9 * s, vec2(p1.x + 250 * s, y0), COLOR_TITLE)
    column(p1, s, y0, lh, 250, {
      { 1, TEXTS.setupSpring .. ' F', { sp.SPRING_RATE_LF, sp.SPRING_RATE_RF } },
      { 2, TEXTS.setupSpring .. ' R', { sp.SPRING_RATE_LR, sp.SPRING_RATE_RR } },
      { 3, TEXTS.setupBump .. ' F', { sp.DAMP_BUMP_LF, sp.DAMP_BUMP_RF } },
      { 4, TEXTS.setupBump .. ' R', { sp.DAMP_BUMP_LR, sp.DAMP_BUMP_RR } },
      { 5, TEXTS.setupRebound .. ' F', { sp.DAMP_REBOUND_LF, sp.DAMP_REBOUND_RF } },
      { 6, TEXTS.setupRebound .. ' R', { sp.DAMP_REBOUND_LR, sp.DAMP_REBOUND_RR } },
    })
    -- Tyres band: compound fitted; pressure, life and km of each wheel (a tyre can be changed alone)
    local ty = y0 + 8 * lh
    drawText(TEXTS.setupTyres, FONT_TITLE, 9 * s, vec2(p1.x + 14 * s, ty), COLOR_TITLE)
    drawText(tostring(ac.getTyresLongName(0, -1) or '-'), FONT_TEXT, 9 * s, vec2(p1.x + 60 * s, ty), COLOR_TITLE)
    for i = 0, 3 do
      local x = p1.x + (150 + i * 56) * s
      local life = (1 - num(wh[i] and wh[i].tyreWear)) * 100
      drawText(WHEEL[i], FONT_MONO, 9 * s, vec2(x, ty), COLOR_OFF)
      drawText(string.format('%.1f', num(wh[i] and wh[i].tyrePressure)), FONT_MONO, 9 * s, vec2(x, ty + lh), COLOR_TITLE)
      drawText(string.format('%.0f%%', life), FONT_MONO, 9 * s, vec2(x, ty + 2 * lh), life < 70 and COLOR_WARN or COLOR_TITLE)
      drawText(string.format('%.0f', num(wh[i] and wh[i].tyreVirtualKM)), FONT_MONO, 9 * s, vec2(x, ty + 3 * lh),
        COLOR_TITLE)
    end
    drawText(TEXTS.setupPsi, FONT_TEXT, 9 * s, vec2(p1.x + 100 * s, ty + lh), COLOR_OFF)
    drawText(TEXTS.setupLife, FONT_TEXT, 9 * s, vec2(p1.x + 100 * s, ty + 2 * lh), COLOR_OFF)
    drawText(TEXTS.setupKm, FONT_TEXT, 9 * s, vec2(p1.x + 100 * s, ty + 3 * lh), COLOR_OFF)
    -- Electronics
    drawText(string.format(TEXTS.setupElectronics, num(car.absMode), num(car.tractionControlMode),
      num(car.tractionControl2), num(car.fuelMap), num(car.currentEngineBrakeSetting), num(car.mgukDelivery),
      num(car.mgukRecovery)), FONT_MONO, 9 * s, vec2(p1.x + 14 * s, p2.y - 15 * s), COLOR_TITLE)
  end

  -- Tile of a wheel: text and color (bent / broken / punctured / suspension damage %)
  local function wheelTile(car, i)
    local wh = car.wheels and car.wheels[i]
    if wh and wh.isBlown then return TEXTS.statusPunct, COLOR_WARN end
    local pct = CarState.suspPercent(car, i) or 0
    local o = CarState.orig[i]
    if o and wh then
      local dev = math.max(math.abs(num(wh.toeIn) - o.toe), math.abs(num(wh.camber) - o.camber))
      local d = config.damage
      if dev > math.min(d.toeBroken, d.camberBroken) then return string.format(TEXTS.statusBroken, dev), BORDER_RED end
      if dev > math.min(d.toeBent, d.camberBent) then return string.format(TEXTS.statusBent, dev), COLOR_ORANGE end
    end
    return string.format('%.0f%%', pct), COLOR_OK
  end

  -- 1960s F1 seen from above, nose up (units of s from the center of the body area):
  -- cigar body as approved (only the cylinder in front of the nose removed); front wheels slightly narrower than the
  -- rear; triangular wishbones (apex at the
  -- wheel, base on the body); cockpit around the middle of the body, with the steering wheel line inside its front edge;
  -- right behind it the V8 block with its 8 intake trumpets in two banks, the left bank higher (half a trumpet: the crank
  -- pin offset between the banks); behind the block 4 exhausts, one pair per bank, the central ones longer, all past
  -- the end of the body
  -- Body: the nose reaches ahead of the front wheels almost the span of the wishbone base (8); the tail goes back 1/5
  -- of what the nose went forward. The whole car sits 4 higher, clear of the B value below it
  local F1_BODY = { -6, -34, 6, 33 }   -- { left x, top y, right x, bottom y }
  local F1_SHIFT = -4
  local F1_WHEELS = { { 11.5, 17, -27, -15 }, { 10, 17, 16, 31 } }   -- { inner x, outer x, top y, bottom y }
  local function drawF1(cx, cy, s)
    local body = COLOR_TITLE
    local function P(x, y) return vec2(cx + x * s, cy + y * s) end
    ui.drawRect(P(F1_BODY[1], F1_BODY[2]), P(F1_BODY[3], F1_BODY[4]), body, 6 * s, nil, 1)
    for _, wl in ipairs(F1_WHEELS) do
      local mid = (wl[3] + wl[4]) / 2
      for _, sd in ipairs({ -1, 1 }) do
        local x1, x2 = sd < 0 and -wl[2] or wl[1], sd < 0 and -wl[1] or wl[2]
        ui.drawRectFilled(P(x1, wl[3]), P(x2, wl[4]), body, 2 * s)
        ui.drawLine(P(sd * wl[1], mid), P(sd * F1_BODY[3], mid - 4), body, 1)
        ui.drawLine(P(sd * wl[1], mid), P(sd * F1_BODY[3], mid + 4), body, 1)
      end
    end
    -- Cockpit and steering wheel
    ui.drawRect(P(-4, -9.2), P(4, 5.2), body, 2 * s, nil, 1)
    ui.drawSimpleLine(P(-2.5, -7), P(2.5, -7), body, 1)
    -- Engine block, intake trumpets (left bank higher) and exhausts
    ui.drawRect(P(-4, 6.5), P(4, 24), body, 0, nil, 1)
    for j = 0, 3 do
      ui.drawCircle(P(-2, 9 + j * 3.6), 1.3 * s, body, 10, 1)
      ui.drawCircle(P(2, 10.8 + j * 3.6), 1.3 * s, body, 10, 1)
    end
    for _, ex in ipairs({ { -3, 36 }, { -1.2, 39.5 }, { 1.2, 39.5 }, { 3, 36 } }) do
      ui.drawSimpleLine(P(ex[1], 24), P(ex[1], ex[2]), body, 1)
    end
  end

  local function drawCar(car, w, h, s)
    local k = h / 1080
    local o = Drag.offset('status', h)
    local p1 = vec2(math.floor(w - STATUS_RIGHT * k - STATUS_W * s + o.x), math.floor(h - MARGIN * k - STATUS_H * s + o.y))
    Drag.group = 'status'
    local p2 = vec2(p1.x + STATUS_W * s, p1.y + STATUS_H * s)
    local rp = state.repair
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.statusTitle, FONT_TITLE, 12 * s, vec2(p1.x + 12 * s, p1.y + 4 * s), COLOR_TITLE)
    if rp.class == 'repair' then
      drawTextRight(TEXTS.statusRepair, FONT_TITLE, 10 * s, p2.x - 10 * s, p1.y + 5 * s, COLOR_ORANGE)
    elseif rp.class == 'beyond' then
      drawTextRight(TEXTS.statusBeyond, FONT_TITLE, 10 * s, p2.x - 10 * s, p1.y + 5 * s, BORDER_RED)
    end
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    -- Wheels & suspension: one tile per wheel
    local y = p1.y + 26 * s
    drawText(TEXTS.statusWheels, FONT_TEXT, 9 * s, vec2(p1.x + 12 * s, y), COLOR_OFF)
    for i = 0, 3 do
      local tx = p1.x + (12 + (i % 2) * 76) * s
      local ty = y + (12 + math.floor(i / 2) * 26) * s
      local text, color = wheelTile(car, i)
      drawText(WHEEL[i], FONT_TITLE, 9 * s, vec2(tx, ty), COLOR_TITLE)
      drawText(text, FONT_MONO, 9 * s, vec2(tx, ty + 11 * s), color)
    end
    -- Powertrain
    y = y + 68 * s
    drawText(TEXTS.statusPowertrain, FONT_TEXT, 9 * s, vec2(p1.x + 12 * s, y), COLOR_OFF)
    local engine = num(car.engineLifeLeft)
    drawText(TEXTS.statusEngine, FONT_TITLE, 9 * s, vec2(p1.x + 12 * s, y + 12 * s), COLOR_TITLE)
    drawText(engine >= 1000 and TEXTS.statusOk or string.format('%.0f%%', engine / 10), FONT_MONO, 9 * s,
      vec2(p1.x + 12 * s, y + 23 * s), engine >= 1000 and COLOR_OK or COLOR_WARN)
    local gear = num(car.gearboxDamage)
    drawText(TEXTS.statusGearbox, FONT_TITLE, 9 * s, vec2(p1.x + 88 * s, y + 12 * s), COLOR_TITLE)
    drawText(gear >= 1 and TEXTS.statusBrokenShort or (gear > 0 and string.format('%.0f%%', (1 - gear) * 100)
      or TEXTS.statusOk), FONT_MONO, 9 * s, vec2(p1.x + 88 * s, y + 23 * s), gear >= 1 and BORDER_RED
      or (gear > 0 and COLOR_WARN or COLOR_OK))
    -- Body (approved screen 12): F bar and value on top, the car outline (a 1960s F1: cigar body, wheels outside) in the
    -- middle, B value and bar at the bottom; L and R values beside the car, their bars outside them. Bar = damage of the
    -- side over the repair limit (bodyRepair); color: over the limit orange, over half yellow, some damage green
    y = y + 40 * s
    drawText(TEXTS.statusBody, FONT_TEXT, 9 * s, vec2(p1.x + 12 * s, y), COLOR_OFF)
    local limit = config.damage.bodyRepair
    local function side(i)
      local v = num(car.damage[i])
      return v, math.min(v / limit, 1),
        v > limit and COLOR_ORANGE or (v > limit / 2 and COLOR_WARN or (v > 0 and COLOR_OK or COLOR_OFF))
    end
    local cx, cy = (p1.x + p2.x) / 2, y + 66 * s
    local track = rgbm(1, 1, 1, 0.1)
    local function hbar(yb, k, color)
      local x1, x2 = cx - 30 * s, cx + 30 * s
      ui.drawRectFilled(vec2(px(x1), px(yb)), vec2(px(x2), px(yb + 3 * s)), track, 1)
      ui.drawRectFilled(vec2(px(x1), px(yb)), vec2(px(x1 + (x2 - x1) * k), px(yb + 3 * s)), color, 1)
    end
    local function vbar(xb, k, color)
      local y1, y2 = cy - 30 * s, cy + 30 * s
      ui.drawRectFilled(vec2(px(xb), px(y1)), vec2(px(xb + 3 * s), px(y2)), track, 1)
      ui.drawRectFilled(vec2(px(xb), px(y2 - (y2 - y1) * k)), vec2(px(xb + 3 * s), px(y2)), color, 1)
    end
    local vF, kF, cF = side(0)
    local vB, kB, cB = side(1)
    local vL, kL, cL = side(2)
    local vR, kR, cR = side(3)
    hbar(cy - 58 * s, kF, cF)
    drawText(string.format('F %.0f', vF), FONT_MONO, 9 * s, vec2(cx - 12 * s, cy - 53 * s), cF)
    drawText(string.format('B %.0f', vB), FONT_MONO, 9 * s, vec2(cx - 12 * s, cy + 40 * s), cB)
    hbar(cy + 54 * s, kB, cB)
    vbar(p1.x + 12 * s, kL, cL)
    drawText(string.format('L %.0f', vL), FONT_MONO, 9 * s, vec2(p1.x + 19 * s, cy - 5 * s), cL)
    drawText(string.format('R %.0f', vR), FONT_MONO, 9 * s, vec2(p2.x - 50 * s, cy - 5 * s), cR)
    vbar(p2.x - 15 * s, kR, cR)
    drawF1(cx, cy + F1_SHIFT * s, s)
  end

  drawStatus = function(car, w, h, s)
    if not PitBox.open and not state.pitService then return end
    drawSetup(car, w, h, s)
    drawCar(car, w, h, s)
  end
end
function script.drawUI()
  local size = ac.getUI().windowSize
  local w = size.x
  local h = size.y

  -- Game-style DSQ text only once the game black flag is given; before it, our drawn black flag (below)
  local gameFlag = state.list.dsqStage == 1
  -- Every game black flag has its text (decision 85): the reason of the DSQ, or the generic one for a black flag from
  -- outside the script
  local dsqReason = state.list.dsqReason
  local dsqText = gameFlag and (state.pitDsqActive and TEXTS.pitDsq
    or (dsqReason == TEXTS.dsqDtReason and TEXTS.dtDsq)
    or string.format(TEXTS.dsqGame, dsqReason or TEXTS.dsqBlackFlag)) or nil
  if dsqText then
    -- Same style as the native AC message: one line, centered on screen, red with a dark outline
    local scale = h / 1080
    local fontSize = 16 * math.min(math.max(scale ^ 0.3, 1), 1.3)
    ui.pushDWriteFont('Segoe UI;Weight=Bold')
    local textSize = ui.measureDWriteText(dsqText, fontSize)
    if textSize.x > w * 0.6 then
      fontSize = fontSize * w * 0.6 / textSize.x
      textSize = ui.measureDWriteText(dsqText, fontSize)
    end
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

  -- Fixed layout: Race Control panel on top (only when it has something to show, or during its opening), slowdown box
  -- right below it, driver swap panel below.
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
  -- Moved by the driver: the panel and the boxes below it go together (Drag)
  Drag.group = 'panel'
  local po = Drag.offset('panel', h)
  local x = math.floor(w * 0.5 - boxW * 0.5 + po.x)
  -- 10 px lower than 18% of the height: clear of the AC virtual mirror
  local yMsg = math.floor(h * 0.18 + 10 * s + po.y)
  local ySd = yMsg + msgH + gap

  -- Notice timing (new penalty / server message): ends after its time or when its penalty leaves the list
  local notice = state.ui.notice
  if notice and (state.ui.clock >= notice.untilT or (notice.item and not listHas(notice.item))) then
    state.ui.notice = nil
  end

  -- Race Control panel: cells and message first; with nothing to show anywhere (and no opening), no panel at all.
  -- Before the opening (driver still in the setup menu, before Drive) nothing is shown: the first thing on screen is
  -- the opening; with no opening (driver swap, already shown), the panel works normally.
  local intro = Intro.frame()
  local values, anyOn = {}, false
  for i, c in ipairs(PANEL_CELLS) do
    values[i] = c.fn()
    if c.title and values[i] and not values[i].quiet then anyOn = true end
  end
  local text, color = Panel.message()
  if intro or (Intro.done and (anyOn or text)) then
    local p1 = vec2(x, yMsg)
    local p2 = vec2(x + boxW, yMsg + msgH)
    local INTRO_BORDERS = { base = BORDER_BASE, yellow = BORDER_YELLOW, blue = BORDER_BLUE, red = BORDER_RED,
      green = BORDER_GREEN }
    local phase = intro and intro.phase
    local border = Panel.frameColor()
    if phase == 'wake' then border = COLOR_CELL_OFF
    elseif phase == 'bulb' then border = INTRO_BORDERS[Intro.lampFrame(intro.t)]
    elseif phase == 'status' then border = BORDER_GREEN
    elseif phase then border = BORDER_BASE end
    drawPanel(p1, p2, border, s, phase == 'wake' and intro.alpha or 1)
    -- Opening, wake and light: what is not lit yet is not drawn (title; cell titles, dividers and separator)
    local showTitle = not (phase == 'wake' or (phase == 'light' and not intro.title))
    local showItems = not (phase == 'wake' or (phase == 'light' and not intro.items))
    local cx = p1.x + 12 * s
    local innerW = boxW - 20 * s
    for i, c in ipairs(PANEL_CELLS) do
      local cw = cellW[i] or (innerW - fixedW)
      if i > 1 and showItems then
        ui.drawSimpleLine(vec2(px(cx), px(p1.y + 6 * s)), vec2(px(cx), px(p1.y + 32 * s)), rgbm(1, 1, 1, 0.12), 1)
      end
      local cell = values[i]
      -- Opening: during the lamp test every cell cycles through its values; afterwards the titled cells are off
      local bulb = intro and intro.bulb
      if intro and c.title then cell = bulb and Intro.lampCell(c.title, intro.t) or nil end
      if not c.title and not showTitle then cell = nil end
      local function put(t, font, size, y, col)
        ui.pushDWriteFont(font)
        local tw = ui.measureDWriteText(t, size).x
        local tx = c.center and (cx + (cw - tw) / 2) or (cx + 6 * s)
        ui.dwriteDrawText(t, size, vec2(px(tx), px(y)), col)
        ui.popDWriteFont()
      end
      if c.title and showItems then
        put(c.title, FONT_TITLE, 10 * s, p1.y + 5 * s, (cell or bulb) and PANEL_COLORS.dim or COLOR_CELL_OFF)
        if cell then put(cell.value, FONT_TITLE, 13 * s, p1.y + 17 * s, PANEL_COLORS[cell.color]) end
      elseif cell then
        put(cell.value, FONT_TITLE, 15 * s, p1.y + 10 * s, PANEL_COLORS[cell.color])
      end
      cx = cx + cw
    end
    if showItems then drawSeparator(p1, p2, p1.y + 36 * s, s) end
    if intro and intro.text then
      -- Opening, name and version in dot matrix: drawn only inside the message line of the panel, so it disappears
      -- at the edge of the panel while scrolling to the left
      ui.pushClipRect(vec2(p1.x + 8 * s, p1.y + 37 * s), vec2(p2.x - 8 * s, p2.y - 3 * s))
      local on = phase == 'status' and PANEL_COLORS.green or COLOR_TITLE
      DotMatrix.draw(intro.text, vec2(p1.x + (16 + intro.x) * s, p1.y + 42 * s), intro.pitch * s,
        rgbm(on.r, on.g, on.b, intro.alpha), rgbm(1, 1, 1, 0.06 * intro.alpha))
      ui.popClipRect()
    elseif intro and intro.bulb then
      local lampText, lampColor = Intro.lampMessage(intro.t)
      ui.pushDWriteFont(FONT_TEXT)
      ui.setCursor(vec2(math.floor(p1.x + 16 * s), math.floor(p1.y + 41 * s)))
      ui.dwriteTextAligned(lampText, 14 * s, ui.Alignment.Start, ui.Alignment.Start,
        vec2(boxW - 32 * s, msgH - 43 * s), true, PANEL_COLORS[lampColor])
      ui.popDWriteFont()
    elseif text and not intro then
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
  for _, check in pairs(state.cutChecks) do if check.ref then cc = check end end
  if cc then
    local p1 = vec2(x, ySd)
    local p2 = vec2(x + boxW, ySd + sdH)
    drawPanel(p1, p2, BORDER_YELLOW, s)
    drawText(TEXTS.liftTitle, FONT_TITLE, 14 * s, vec2(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + 24 * s, s)
    -- Meter: left of the limit line = slower than reference x (1 + tolerance), no slowdown (green); right = faster,
    -- slowdown (red). The white mark is where the driver is now (smoothed); about +/-30% of the limit spans the bar.
    local bx1, bx2 = p1.x + 16 * s, p2.x - 16 * s
    local by1, by2 = p1.y + 30 * s, p1.y + 38 * s
    local lim = bx1 + (bx2 - bx1) * LIFT_LIMIT_POS
    ui.drawRectFilled(vec2(px(bx1), px(by1)), vec2(px(lim), px(by2)), COLOR_LIFT_SLOW, px(4 * s))
    ui.drawRectFilled(vec2(px(lim), px(by1)), vec2(px(bx2), px(by2)), COLOR_LIFT_FAST, px(4 * s))
    ui.drawSimpleLine(vec2(px(lim), px(by1 - 2 * s)), vec2(px(lim), px(by2 + 2 * s)), rgbm(1, 1, 1, 0.8), 1)
    local f = math.min(math.max(LIFT_LIMIT_POS - (cc.shown or cc.margin) * LIFT_SCALE, 0), 1)
    local mx = bx1 + (bx2 - bx1) * f
    -- Mark: white, with a glow pulsing at LIFT_CARET_HZ
    local pulse = 0.5 + 0.5 * math.sin(2 * math.pi * LIFT_CARET_HZ * state.ui.clock)
    ui.drawRectFilled(vec2(px(mx - 4 * s), px(by1 - 5 * s)), vec2(px(mx + 4 * s), px(by2 + 5 * s)),
      rgbm(1, 1, 1, 0.15 + 0.35 * pulse), px(3 * s))
    ui.drawRectFilled(vec2(px(mx - 1.5 * s), px(by1 - 3 * s)), vec2(px(mx + 1.5 * s), px(by2 + 3 * s)),
      rgbm(1, 1, 1, 0.75 + 0.25 * pulse), px(1 * s))
    local ly = p1.y + 41 * s
    drawText(TEXTS.liftSlower, FONT_MONO, 10 * s, vec2(bx1, ly), COLOR_DIM)
    local mid = string.format(TEXTS.liftLimit, cc.zone.gainTolerance)
    ui.pushDWriteFont(FONT_MONO)
    local mw = ui.measureDWriteText(mid, 10 * s).x
    ui.dwriteDrawText(mid, 10 * s, vec2(px(lim - mw / 2), px(ly)), COLOR_DIM)
    ui.popDWriteFont()
    drawTextRight(TEXTS.liftFaster, FONT_MONO, 10 * s, bx2, ly, COLOR_DIM)
  end

  -- Opening: the secondary boxes light up one after the other (frame and title only), unless a real one is showing
  -- Car at its pit place: the slowdown box is hidden, the slowdown keeps counting (decisions 87, 94)
  local sdHidden = ac.getCar(0).isInPit
  local anySd = false
  if not sdHidden then
    for _, sd in pairs(state.slowdowns) do if sd.active then anySd = true end end
  end
  if intro and intro.box and not cc and not anySd then
    local k = intro.boxK or 0
    local pulse = 0.5 + 0.5 * math.cos(2 * math.pi * 3 * state.ui.clock)
    if intro.box == 'swap' then
      local p1 = vec2(x, ySd + sdH + gap)
      local p2 = vec2(x + boxW, ySd + sdH + gap + msgH)
      drawPanel(p1, p2, BORDER_GREEN, s)
      drawText(TEXTS.swapTitle, FONT_TITLE, 14 * s, vec2(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
      drawSeparator(p1, p2, p1.y + 24 * s, s)
      local total = config.swapMinSeconds
      local left = total * (1 - k)
      drawText(string.format(TEXTS.swapWait, mmss(left)), FONT_TEXT, 12 * s, vec2(p1.x + 16 * s, p1.y + 29 * s), COLOR_SWAP)
      drawText(string.format(TEXTS.swapTimes, mmss(total - left), mmss(total)), FONT_MONO, 12 * s,
        vec2(p1.x + 16 * s, p1.y + 45 * s), COLOR_TITLE)
    else
      local p1 = vec2(x, ySd)
      local p2 = vec2(x + boxW, ySd + sdH)
      drawPanel(p1, p2, BORDER_YELLOW, s)
      drawText(intro.box == 'lift' and TEXTS.liftTitle or TEXTS.sdTitle, FONT_TITLE, 14 * s,
        vec2(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
      drawSeparator(p1, p2, p1.y + 24 * s, s)
      if intro.box == 'lift' then
        local bx1, bx2 = p1.x + 16 * s, p2.x - 16 * s
        local by1, by2 = p1.y + 30 * s, p1.y + 38 * s
        local lim = bx1 + (bx2 - bx1) * LIFT_LIMIT_POS
        ui.drawRectFilled(vec2(px(bx1), px(by1)), vec2(px(lim), px(by2)), COLOR_LIFT_SLOW, px(4 * s))
        ui.drawRectFilled(vec2(px(lim), px(by1)), vec2(px(bx2), px(by2)), COLOR_LIFT_FAST, px(4 * s))
        ui.drawSimpleLine(vec2(px(lim), px(by1 - 2 * s)), vec2(px(lim), px(by2 + 2 * s)), rgbm(1, 1, 1, 0.8), 1)
        local mx = bx1 + (bx2 - bx1) * k
        ui.drawRectFilled(vec2(px(mx - 1.5 * s), px(by1 - 3 * s)), vec2(px(mx + 1.5 * s), px(by2 + 3 * s)),
          rgbm(1, 1, 1, 0.75 + 0.25 * pulse), px(1 * s))
        local ly = p1.y + 41 * s
        drawText(TEXTS.liftSlower, FONT_MONO, 10 * s, vec2(bx1, ly), COLOR_DIM)
        drawTextRight(TEXTS.liftFaster, FONT_MONO, 10 * s, bx2, ly, COLOR_DIM)
      else
        local num = rgbm(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 0.3 + 0.7 * pulse)
        local pieces = {
          { TEXTS.timerPay, COLOR_TEXT },
          { string.format(TEXTS.timerSeconds, 8 * (1 - k)), num },
          { TEXTS.timerDeadline, COLOR_TEXT },
          { string.format(TEXTS.timerDeadlineSeconds, 16 * (1 - k)), num },
          { TEXTS.timerEnd, COLOR_TEXT },
        }
        local tx = p1.x + 16 * s
        ui.pushDWriteFont(FONT_MONO)
        for _, piece in ipairs(pieces) do
          ui.dwriteDrawText(piece[1], 12 * s, vec2(px(tx), px(p1.y + 29 * s)), piece[2])
          tx = tx + ui.measureDWriteText(piece[1], 12 * s).x
        end
        ui.popDWriteFont()
      end
    end
  end

  -- Slowdown box (one slowdown at a time; overlapping ones are merged)
  for _, zone in ipairs(config.cutZones) do
    local sd = state.slowdowns[zone.category]
    if not cc and not sdHidden and sd and sd.active then
      local p1 = vec2(x, ySd)
      local p2 = vec2(x + boxW, ySd + sdH)
      drawPanel(p1, p2, BORDER_YELLOW, s)
      drawText(sd.title, FONT_TITLE, 14 * s, vec2(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
      drawSeparator(p1, p2, p1.y + 24 * s, s)
      -- Line in pieces: the time to pay and the deadline pulse together (rate set in slowdown.lua)
      local numColor = COLOR_TEXT
      if (sd.pulseHz or 0) > 0 then
        numColor = rgbm(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 0.3 + 0.7 * (0.5 + 0.5 * math.cos(sd.phase or 0)))
      end
      local pieces = {
        { TEXTS.timerPay, COLOR_TEXT },
        { string.format(TEXTS.timerSeconds, math.max(sd.toPay, 0)), numColor },
        { TEXTS.timerDeadline, COLOR_TEXT },
        { string.format(TEXTS.timerDeadlineSeconds, math.max(sd.deadlineLeft, 0)), numColor },
        { TEXTS.timerEnd, COLOR_TEXT },
      }
      local tx = p1.x + 16 * s
      ui.pushDWriteFont(FONT_MONO)
      for _, piece in ipairs(pieces) do
        ui.dwriteDrawText(piece[1], 12 * s, vec2(px(tx), px(p1.y + 29 * s)), piece[2])
        tx = tx + ui.measureDWriteText(piece[1], 12 * s).x
      end
      ui.popDWriteFont()
      break
    end
  end

  -- Car damage box, below the slowdown box (or in its place): black flag with orange disc (repair required, drawn by
  -- the script) or damage beyond the safety limit; our DSQ (black flag drawn, informative) in the same place
  local yNext = ySd + (anySd and not cc and (sdH + gap) or 0)
  local rp = state.repair
  local dl = state.list
  -- Stop & go box (approved screens 3 and 4): stopped at the pit place, or interrupted waiting for the same driver
  local sgIt = config.sg and sgItem()
  if not cc and sgIt and (StopAndGo.stopping or StopAndGo.resume) then
    local total = sgSeconds(sgIt)
    local left = StopAndGo.remainingMs(sgIt) / 1000
    local h = msgH + math.floor(10 * s)
    local p1 = vec2(x, yNext)
    local p2 = vec2(x + boxW, yNext + h)
    drawPanel(p1, p2, BORDER_RED, s)
    local stopping = StopAndGo.stopping
    drawText(stopping and TEXTS.sgBoxTitle or TEXTS.sgBoxInterrupted, FONT_TITLE, 14 * s,
      vec2(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
    drawTextRight(stopping and mmss(left) or string.format(TEXTS.sgBoxLeft, mmss(left)), FONT_MONO, 14 * s,
      p2.x - 16 * s, p1.y + 5 * s, COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + 24 * s, s)
    local line1 = TEXTS.sgBoxStay
    if not stopping then
      local back = config.sgReturnSeconds > 0 and StopAndGo.returnLeft and StopAndGo.returnLeft()
      line1 = back and string.format(TEXTS.sgBoxReturnWithin, mmss(back)) or TEXTS.sgBoxSameDriver
    end
    drawText(line1, FONT_TEXT, 12 * s, vec2(p1.x + 16 * s, p1.y + 29 * s), BORDER_RED)
    if stopping then
      local bx1, bx2, by = p1.x + 16 * s, p2.x - 16 * s, p1.y + 47 * s
      ui.drawRectFilled(vec2(px(bx1), px(by)), vec2(px(bx2), px(by + 5 * s)), rgbm(1, 1, 1, 0.12), px(2 * s))
      local k = total > 0 and math.min(math.max((total - left) / total, 0), 1) or 0
      ui.drawRectFilled(vec2(px(bx1), px(by)), vec2(px(bx1 + (bx2 - bx1) * k), px(by + 5 * s)), BORDER_RED, px(2 * s))
      drawText(string.format(TEXTS.sgBoxTimes, mmss(total - left), mmss(total)), FONT_MONO, 12 * s,
        vec2(p1.x + 16 * s, p1.y + 56 * s), COLOR_TITLE)
    else
      drawText(TEXTS.sgBoxResume, FONT_MONO, 12 * s, vec2(p1.x + 16 * s, p1.y + 45 * s), COLOR_TITLE)
    end
    yNext = p2.y + gap
  end
  -- Drive-through flag (the game no longer shows its drive-through message): the drive-through to serve now, with the
  -- reason and the deadline; +n = more drive-throughs in the list
  local dtHead = dl.items[1]
  if not cc and dl.dsq == 0 and dtHead and dtHead.kind:sub(1, 2) ~= 'SG' then
    local p2 = vec2(x + boxW, yNext + sdH)
    local more = #dl.items > 1 and string.format(TEXTS.dtMore, #dl.items - 1) or ''
    local deadline = dtHead.laps < 0 and TEXTS.dtOverdue or dtHead.laps == 0 and TEXTS.dtThisLap
      or dtHead.laps == 1 and TEXTS.dtNextLap or string.format(TEXTS.dtWithinLaps, dtHead.laps)
    drawFlagBox(vec2(x, yNext), p2, s, BORDER_BASE, nil, TEXTS.dtTitle .. more, COLOR_TITLE,
      TEXTS.reason[dtHead.cat] or dtHead.cat, deadline, 'dt')
    yNext = p2.y + gap
  end
  if not cc and dl.dsq > 0 and dl.dsqStage ~= 1 then
    local p2 = vec2(x + boxW, yNext + sdH)
    drawFlagBox(vec2(x, yNext), p2, s, BORDER_RED, nil, TEXTS.dsqTitle, BORDER_RED, dl.dsqReason,
      dl.dsqStage == 2 and TEXTS.dsqTow or TEXTS.dsqStop)
    yNext = p2.y + gap
  elseif not cc and rp.lapsLeft and rp.class == 'repair' then
    local p2 = vec2(x + boxW, yNext + sdH)
    local title = rp.lapsLeft <= 1 and TEXTS.damageRepairLast or string.format(TEXTS.damageRepairLaps, rp.lapsLeft)
    drawFlagBox(vec2(x, yNext), p2, s, COLOR_ORANGE, COLOR_ORANGE, title, COLOR_ORANGE, rp.text, rp.detail)
    yNext = p2.y + gap
  elseif not cc and rp.class == 'beyond' then
    local p1 = vec2(x, yNext)
    local p2 = vec2(x + boxW, yNext + msgH)
    drawPanel(p1, p2, BORDER_RED, s)
    drawText(TEXTS.damageBeyondTitle, FONT_TITLE, 14 * s, vec2(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + 24 * s, s)
    drawText(TEXTS.damageBeyond, FONT_TEXT, 12 * s, vec2(p1.x + 16 * s, p1.y + 29 * s), BORDER_RED)
    drawText(string.format('%s - %s', rp.text or '', rp.detail or ''), FONT_MONO, 12 * s,
      vec2(p1.x + 16 * s, p1.y + 45 * s), COLOR_TITLE)
    yNext = p2.y + gap
  end

  -- Driver swap panel (green), below the slowdown and damage boxes; also the wrong driver countdown
  if config.swapOn() or state.list.wrong then
    local sw = state.swap
    local clock = state.ui.clock
    local total = config.swapMinSeconds
    local title, line1, line2
    local wrongLeft = WrongDriver.remaining()
    if wrongLeft and not (state.dtDsqActive or state.pitDsqActive) then
      title, line1 = TEXTS.wrongDriverTitle, TEXTS.wrongDriverLeave
      line2 = string.format(TEXTS.wrongDriverTime, mmss(wrongLeft))
    elseif sw.clearUntil and clock < sw.clearUntil then
      title, line1 = TEXTS.swapTitle, TEXTS.swapClear
    elseif sw.remaining then
      local left = math.max(sw.remaining - (clock - sw.remainingT), 0)
      title = TEXTS.swapTitle
      line1 = string.format(TEXTS.swapWait, mmss(left))
      line2 = string.format(TEXTS.swapTimes, mmss(math.max(total - left, 0)), mmss(total))
    elseif sw.stopT and #state.list.items > 0 then
      -- Penalties pending: only the driver who caused them pays them, so no swap
      title, line1 = TEXTS.swapActive, TEXTS.swapBlocked
    elseif sw.stopT then
      title, line1 = TEXTS.swapActive, TEXTS.swapDisconnect
      line2 = string.format(TEXTS.swapTimes, mmss(clock - sw.stopT), mmss(total))
    end
    if title then
      local ySwap = math.max(ySd + sdH + gap, yNext)
      local p1 = vec2(x, ySwap)
      local p2 = vec2(x + boxW, ySwap + msgH)
      drawPanel(p1, p2, BORDER_GREEN, s)
      drawText(title, FONT_TITLE, 14 * s, vec2(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
      drawSeparator(p1, p2, p1.y + 24 * s, s)
      drawText(line1, FONT_TEXT, 12 * s, vec2(p1.x + 16 * s, p1.y + 29 * s), COLOR_SWAP)
      if line2 then drawText(line2, FONT_MONO, 12 * s, vec2(p1.x + 16 * s, p1.y + 45 * s), COLOR_TITLE) end
    end
  end

  -- Own pit stop box, bottom right corner (stopped at the own pit place, or during the stop)
  -- with the setup status (bottom left) and the car status (right of it)
  if config.mode == 'CSP' then
    -- Their own growth on screens bigger than 1080p, slightly more than the panel (screenScale); 1x at 1080p
    local sb = math.min(math.max((h / 1080) ^ config.screenScale.exponent, 1), math.max(config.screenScale.max, 1))
    drawPitBox(ac.getCar(0), w, h, sb)
    drawStatus(ac.getCar(0), w, h, sb)
  end
  -- Mouse: move cursor over a screen, click, hold and drag to move it; double click puts it back
  Drag.finish(w, h)
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
  for id in tostring(cfg.cockpitExemptSteamIDs or ''):gmatch('[^|]+') do
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
  OnlineQueue.update()
  RecordSync.update()
  if state.hold and serverTimeMs() >= state.hold.untilMs then
    state.hold = nil
    PitRecord.save()
  end

  -- Driver swap: the stop at the pit place starts the elapsed time of the driver leaving the car (only a stop seen
  -- by this client: a driver who connects with the car already parked does not get the "disconnect" panel)
  local sw = state.swap
  local parked = car.isInPit
  -- New driver leaving the pit place before the minimum swap time: DSQ (decisions 80, 97). The ACSM penalty is
  -- neutralized on the server (penalty and DSQ windows equal to the swap time); the control is the script's
  if sw.prevInPit and not parked and sw.remaining and sw.remaining - (state.ui.clock - sw.remainingT) > 0
      and not (state.dtDsqActive or state.pitDsqActive) then
    ac.log(string.format('race-control: DSQ, left the pits %.1f s before the driver swap time',
      sw.remaining - (state.ui.clock - sw.remainingT)))
    sw.remaining = nil
    carDsq(1, TEXTS.swapEarlyDsq)
  end
  if sw.prevInPit == false and parked then sw.stopT = state.ui.clock end
  if not parked then sw.stopT = nil end
  if not inPit then sw.remaining = nil end
  sw.prevInPit = parked
  updateSwapRelay()
  publishOwnList(car)
  PitStops.update(car)
  DriverTable.update()
  if config.mode == 'CSP' then PitBox.update(car) end
  -- Penalty list of the previous driver (driver swap): only the driver who caused a penalty pays it, so it is taken
  -- over only with wrongDriverSeconds empty (the regulation lets another driver pay it), and if this driver has none
  if sw.pendingList then
    local items = sw.pendingList
    sw.pendingList = nil
    if config.wrongDriver then
      ac.log('race-control: swap: penalties of the previous driver not taken over (paid only by that driver)')
    elseif #state.list.items == 0 then
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
    GainRef.load()
    state.cutChecks = {}
    state.slowdowns = {}
    state.pitDsqActive = false
    state.dtDsqActive = false
    state.code80 = nil
    state.code80Ended = false
    -- CODE-80 in force: kept on a script reload; otherwise it comes from the other drivers (RecordSync.askOwn below)
    TrackList.load()
    -- Car state: put back after a new connection or a driver swap (from this computer or the other drivers)
    CarState.load()
    -- Stops with service and the hold in progress (it goes on after a new connection)
    state.hold = nil
    PitRecord.load()
    PitStops.wasInPitlane = nil
    PitStops.passInWindow = false
    PitStops.pass = nil
    PitStops.line = 0
    PitStops.endChecked = false
    DriverTable.reset()
    state.swap.swapInfo = nil
    state.tow.jumpPending = false
    state.tow.repairDone = false
    state.tow.damage = nil
    state.tow.lastRead = nil
    l.endOfLap = {}
    l.lastLap = lapCount
    l.prevInPit = inPit
    -- A DSQ belongs to its session: the controls locked and the game black flag of the session before are released
    -- (Rules.sessionSync puts them back if the record of this session has a DSQ)
    physics.lockUserControlsFor(0)
    if g.t == BLACK_FLAG then
      physics.setCarPenalty(ac.PenaltyType.ReleaseBlackFlag)
      g = { t = 0, p = 0 }
    end
    l.prevGame = { t = g.t, p = g.p }
    -- Sync with the game on session start or reload
    Rules.sessionSync(g)
    -- Panel records of this session (script reload keeps them)
    local window = Record.load('window')
    state.pit.done = window == 'done'
    state.pit.missed = window == 'missed'
    SwapRecord.apply(Record.load('swap'))
    -- The records of this car kept by the other drivers (reconnection, restarted game, driver swap)
    RecordSync.askOwn()
    ac.log(string.format('race-control: laps car=%d leaderboard=%s server time=%d ms', lapCount,
      tostring(leaderboardLaps()), serverTimeMs()))
    state.ui.lastSeq = l.seq
    state.ui.notice = nil
  end
  -- Opening: after the session records are loaded (it may skip the short opening when there is something to show)
  Intro.update(car)

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
    -- DSQ in the game: the list is cleared; the script keeps running
    if g.t == BLACK_FLAG and l.prevGame.t ~= BLACK_FLAG then
      -- A black flag from outside the script (the game, KMR, admin) is a DSQ of the car too: kept in the car record,
      -- and shown with its text like every black flag (decision 85)
      if l.dsq == 0 then
        l.dsq = 1
        l.seq = l.seq + 1
        l.dsqReason = TEXTS.dsqBlackFlag
      end
      if not (state.dtDsqActive or state.pitDsqActive) then state.dtDsqActive = true end
      if l.dsqStage ~= 1 then dsqGameFlag('black flag from outside the script', nil, true) end
      Rules.zero()
    end
    local dsqActive = state.dtDsqActive or state.pitDsqActive

    -- Green flag after CODE-80: the hold for two pending DT0 deferred during CODE-80 is applied now
    if state.code80Ended then
      state.code80Ended = false
      if not dsqActive then Rules.finalize() end
    end

    -- Tow per session (keys practiceTow / qualifyTow / raceTow): TOW = tow and repair hold, collision damage counted
    -- outside the pit lane; RESET = the tow from the track clears the penalties and the slowdowns in progress (not a DSQ)
    local tw = state.tow
    local towRule = config.tow[sim.raceSessionType] or { mode = 'NONE' }
    local towOn = towRule.mode == 'TOW' and (towRule.towSeconds > 0 or towRule.repairFactor > 0)
    if towRule.mode == 'RESET' and tw.jumpPending and inPit and not dsqActive
        and (#l.items > 0 or next(state.slowdowns)) then
      Rules.zero()
      l.invalidLap = nil
      ac.log('race-control: tow in practice: penalties cleared')
      rcLog('Tow', 'Practice - pending penalties cleared')
    end
    -- Practice (decisions 13, 14, 86): the car at its pit place (back to the session, tow, or driven in) clears the
    -- penalties and the slowdowns in progress; a DSQ stays
    if sim.raceSessionType == ac.SessionType.Practice and CarRead.parked(car) and not dsqActive
        and (#l.items > 0 or next(state.slowdowns) or #l.endOfLap > 0) then
      Rules.zero()
      l.invalidLap = nil
      ac.log('race-control: practice, car at its pit place: penalties cleared')
      rcLog('Pit', 'Practice - pending penalties cleared at the pit place')
    end
    local repairing = CarRead.flagOn(car.isRepairing)
    if towOn and not dsqActive and not state.hold then
      if tw.jumpPending and inPit then
        applyTowHold(towRule.towSeconds, tw.damage, TEXTS.towReason)
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
    -- KMR drive-throughs received in the chat (race: into the list; practice and qualifying: relaxed)
    KmrDT.update()
    -- Race Control commands sent by an admin from the ACSM live timing
    RcCommand.update()

    -- Pit pass, even if the exit falls in the same processed frame
    local viaPit = inPit or l.prevInPit
    l.inPitNow = inPit

    local lineFrame = lapCount > l.lastLap
    if lineFrame then
      Rules.line(viaPit, g, lapCount)
      l.lastLap = lapCount
    end
    DamageClass.update(car, lineFrame)
    CarState.update(car, lineFrame)
    DsqFlow.update(car, lineFrame)
    Ban.update()

    -- Pit lane speeding measured by the script: the PSE enters at the pit exit (decisions 79, 89, 90)
    PitSpeed.update(car, inPit, lapCount)
    Rules.invalidLaps(car)
    if not (state.dtDsqActive or state.pitDsqActive) then
      WrongDriver.update()
      StopAndGo.update(car)
    end

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
