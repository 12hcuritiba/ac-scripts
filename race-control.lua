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
-- Same order as config/server/ACSM-CSP.txt (normalized, docs/projeto/Arquitetura — módulos e expansão.md, 5):
-- 1. script operation, 2. optional general data, 3. driver swap and pit stops, 4. penalty control: pit exit, pit lane
-- speeding, wrong way, 5. holds, tow and repair, 6. penalty control: disqualification, exclusion zone 1, exclusion
-- zone 2, slowdown. Each theme whole, in one place.
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
--   practiceTow = mode:RESET | clearDsq:1        qualifyTow = mode:TOW | towSeconds:120 | repairFactor:1.5
--   raceTow = mode:TOW | towSeconds:120 | repairFactor:1.5
--     Back to the pits from the track (tow), per session. TOW = the car is locked in the pits (TeleportToPits) for
--     towSeconds + repair; repair chosen in the own pit stop box = repair only. RESET = the tow clears the penalties and the
--     slowdowns in progress (not a DSQ). NONE = nothing. With TOW, set ENFORCE_BACK_TO_PITS_PENALTY = 0 in
--     [EXTRA_RULES], or the driver also gets the AC back-to-pits penalty. practiceTow clearDsq: 1 = in practice the car
--     at its pit place (after the tow, forced or by the driver, or back to the session) also clears the DSQ: the game
--     black flag is taken off and the controls released; 0 = the DSQ stays for the session.
--   repairFormula = baseSeconds:180 | weightEngine:1.0 | weightSuspension:0.5 | weightBody:0.25
--     repair = repairFactor x (baseSeconds x (weightEngine x powertrain + weightSuspension x suspension) + weightBody x
--     body). Only damage from collisions counts (within COLLISION_DAMAGE_WINDOW seconds after ac.onCarCollision);
--     powertrain = engine and gearbox together (the larger increase); suspension = increase of the 4 wheels (0..1
--     each); body = increase of the body damage zones in km/h.
--   damage = toeBent:10 | toeBroken:20 | camberBent:10 | camberBroken:20 | bodyRepair:150 | powertrainRepair:45 |
--            maxPunctured:2 | repairLaps:2 |
--            beyondTowSeconds:180 | dsqTowSeconds:180 | settleSeconds:1
--     settleSeconds: toe and camber count only with the game reporting suspension damage on the wheel and held this long
--     (a kerb bends the suspension for an instant and it comes back: elastic, not damage).
--     Qualifying and race. Toe and camber over the setup, per wheel, in degrees: over the bent limit = black flag with
--     orange disc (repair required); over the broken limit = damage beyond the safety limit (stop off track, tow).
--     bodyRepair: body damage of a side over which the repair is required; powertrainRepair: powertrain damage in %
--     (the larger of engine, 1 - life / 1000, and gearbox) from which the repair is required (a blown engine or a
--     broken gearbox is beyond the safety limit: the game does not stop the car before); maxPunctured: punctured tyres that still
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
  -- dataCheck: 1 = the data that comes from the other cars is checked (a record or penalty list only from its own car,
  --   the answers about this car confirmed by the others, an incident where the car really is); 0 = off, as before
  --   (decision 249).
  dataCheck = 1,
  -- screenScale = exponent:0.45 | max:1.5
  --   Size of the pit stop box, setup status and car status on screens bigger than 1080p: (height / 1080) ^ exponent,
  --   from 1x at 1080p (the approved size) up to max. The Race Control panel keeps its own growth (^0.3, up to 1.3x),
  --   so these screens grow slightly more on a big screen (1440p: 1.14x; 4K: 1.37x).
  screenScale = '',
  -- screens = autoSeconds:5 | closeGap:2.5 | noticeSeconds:3 | serverNoticeSeconds:5 | messageSeconds:5 |
  --           pitBoxSeconds:5 | indicatorSeconds:2 | buttonSeconds:10 | controlSeconds:3
  --   Times of the screens (decisions 212, 219): auto-hide shows a screen by an event (line, sector, damage, position)
  --   for autoSeconds; the relative while a car is within closeGap seconds; a new penalty in the panel noticeSeconds, a
  --   server message serverNoticeSeconds; the message window over the panel messageSeconds; the pit stop box after
  --   a D-pad press away from the pit place pitBoxSeconds; the desktop indicator indicatorSeconds; the time to press
  --   the button being recorded buttonSeconds; the car controls after a change controlSeconds.
  screens = '',
  -- tyreLife = ok:70 | worn:30
  --   Colors of the tyre life in the setup status (remaining life from the wear curve of the compound), graded: green
  --   from ok % up (ok), yellow in the middle of the half life band (worn % to ok %), orange at worn %, red at 0 (end).
  tyreLife = '',
  -- tyreTemp = edge:98
  --   Colors of the tyre temperature (shown on the pressure in the setup status), from the thermal curve of the
  --   compound: green on its top (ideal); cold side graded to blue at edge % of the top grip; hot side graded to yellow
  --   at edge % (overheating), then to red at the lowest grip of its hot end (cliff).
  tyreTemp = '',
  -- flags = slowMeters:300 | yellowMeters:500 | oilSeconds:300 | rainSlippery:0.2 | greenSeconds:5 | redSpeedKmh:65 |
  --   redGraceSeconds:10 | passSlowKmh:40 | passFarM:75 | redSpeedSG:30 | redOverSeconds:10 | redNoLineSG:120 | yellowPassSG:10 | yellowGiveBackSeconds:10
  --   Flag box (every flag is the Race Control's; the game ones are hidden by the app). A car ahead that is slow
  --   (repair required) within slowMeters = white flag; stopped on track, broken down or with a blown engine within
  --   yellowMeters = yellow; the oil of a blown engine stays as the slippery flag (yellow and red) for oilSeconds;
  --   rain intensity (0..1) from rainSlippery up = slippery (0 = off); green flag for greenSeconds after a yellow or a
  --   neutralization ends. With the red flag (RC REDFLAG ALL), CODE-65: over redSpeedKmh on track = warning in the
  --   flag box (no limiter) and, over it for more than redOverSeconds (as the KMR under the VSC), a stop & go of
  --   redSpeedSG seconds, served after the restart and added to the pending penalties; a pit entry without the red flag
  --   received at the line on track (after redGraceSeconds) = a stop & go of redNoLineSG seconds after the restart;
  --   overtaking forbidden after redGraceSeconds from the red flag (a manoeuvre already under way: warning only); a car
  --   stopped, or slower than passSlowKmh and farther than passFarM from the car ahead of it, can be passed (the KMR
  --   regime; the KMR exception of the slow leader does not apply to the red flag). Under the yellow flag of an
  --   incident, the same exceptions; a car passed has to get the place back within yellowGiveBackSeconds, otherwise a
  --   stop & go of yellowPassSG seconds (VSC, SC and FCY: the KMR rules). The stop & go needs stopAndGo mode SG.
  flags = '',

  -- ------------------------------------------------------------
  -- 2. General data (optional, filled in by the organizer)
  -- ------------------------------------------------------------
  -- eventName = 12h Curitiba: name of the event, on the lobby and the event information (decision 222).
  eventName = '',
  -- raceControlSteamID: Steam ID of the race director client, logged in as admin. In any mode it sends the ban of an
  --   edited record file (/ban <car ID>); in 'KMR' mode it also checks every car. Empty = nobody.
  raceControlSteamID = '',
  -- staffSteamIDs: Steam IDs of the staff chosen by the director, separated by '|': they open the race direction window
  --   and give its commands (red flag, VSC, session, actions on a car) like the director (decision 243).
  staffSteamIDs = '',
  -- broadcastSteamIDs: Steam IDs of the broadcast, separated by '|': they see the race direction window, read only
  --   (no command, no login field).
  broadcastSteamIDs = '',
  -- cockpitExemptSteamIDs: Steam IDs not forced (for example, Race Control / broadcast), separated by '|' (not ';':
  --   it starts a comment in the INI; not ',': the CSP splits the value there and the script gets only the first).
  cockpitExemptSteamIDs = '',
  -- classes = GT3:model/model | GT4:model (optional): class of each car model (car folder name), for the relative and
  --   the standings (the SDK has no car class). Empty = no classes.
  classes = '',
  -- kmrPoints = limit:100: limit of the KMR infraction points of a driver (shown with his points in the race status;
  --   the points come from the KMR message of each infraction).
  kmrPoints = '',
  -- kmrRating = dsqAt:0: the KMR safety rating of a driver (the KMR money: shown in the race status, read from every
  --   KMR message with the balance, the welcome message at the entry included); at or under dsqAt = DSQ. Empty = the
  --   rating is only shown, no DSQ.
  kmrRating = '',

  -- ------------------------------------------------------------
  -- 3. Driver swap and pit stops (the ACSM keys must match the ACSM race settings)
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
  -- wrongDriverSeconds: the penalty is paid only by the driver who caused it; the swap is not allowed while there is
  --   anything to pay. Another driver who enters the car anyway has this many seconds to leave (countdown); not gone:
  --   DSQ, and the original driver cannot come back. 0 = another driver is not allowed (DSQ as he enters). Empty = no
  --   time defined: the new driver takes the penalties over and pays them (not the world standard).
  wrongDriverSeconds = '120',
  -- driverStint = minMinutes:0 | maxMinutes:0 (optional; race only; decision 198)
  --   Stint of each driver, from taking the car to the stop at the pit place where he leaves it. Under minMinutes at a
  --   driver swap, or over maxMinutes while driving: DSQ. 0 = no limit.
  driverStint = '',
  -- pitStopOrder: order of the operations of the own pit stop box (the AC pit menu is off, so the script times the
  --   stop). Same notation as PITS_ORDER of the CSP [EXTRA_RULES]: F fuel, T tyres, R repair, one after the other;
  --   letters inside < > at the same time. F<TR> = fuel first, then tyres and repair together.
  pitStopOrder = 'F<TR>',
  -- pitStopMode: how the own pit stop box starts the stop by default (the driver changes it in the last line of the
  --   box). AUTO = stopping at the pit place with the box touched and something chosen starts it; MANUAL = only the
  --   start on the last line of the box (D-pad right). The box not touched is a plain stop: it serves the stop & go and allows
  --   the driver swap; a service allows neither in the same stop.
  pitStopMode = 'AUTO',
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
  -- 4.1 Penalty control: pit exit while closed
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
  -- 4.2 Penalty control: pit lane speeding (measured by the script; SPEEDING_PENALTY = NONE on the server)
  -- ------------------------------------------------------------
  -- pitSpeedLimit: pit lane speed limit of the rule, km/h (the script's own; SPEED_KMH of [PITS_SPEED_LIMITER] on the
  --   server only sets the car's limiter and should be the same). pitSpeedTolerance: km/h over it before it is
  --   speeding. pitSpeedDeadlineLaps: laps to serve the PSE (1 = DT1).
  pitSpeedLimit = 60,
  pitSpeedTolerance = 2,
  pitSpeedDeadlineLaps = 1,

  -- ------------------------------------------------------------
  -- 4.3 Penalty control: driving the wrong way (ours; ALLOW_WRONG_WAY = 1 in [EXTRA_RULES] turns the CSP one off)
  -- ------------------------------------------------------------
  -- wrongWay = maxMeters:30 | penalty:DSQ | showMeters:2 | angle:90
  --   maxMeters: metres against the direction of the track allowed to manoeuvre; more = penalty. penalty: DSQ (our DSQ,
  --   usual flow: stop at the pit place or the game black flag at the line; no teleport) or NONE. showMeters: metres
  --   against the direction of the track from which the wrong way box (no entry sign) is on screen. angle: degrees
  --   between where the car points and the direction of the track above which it counts (moving back along the
  --   track); within it the manoeuvre is over and the count is cleared.
  wrongWay = '',

  -- ------------------------------------------------------------
  -- 5.1 Two pending DT0: stop & go (SG) or hold (HOLD, rule 5: seconds stopped in the pits with locked controls; the
  --     hold clears the whole list)
  -- ------------------------------------------------------------
  -- stopAndGo (struct key, see "Struct keys" above): what two pending DT0 give and the stop & go.
  stopAndGo = '',
  -- holdShortSeconds: two pending DT0.
  holdShortSeconds = 45,
  -- holdLongSeconds: two pending DT0 when one of them is the PSE that became DT0 crossing the line on track.
  holdLongSeconds = 90,

  -- ------------------------------------------------------------
  -- 5.2 Tow and repair, 5.3 car damage: struct keys (see "Struct keys" above)
  -- ------------------------------------------------------------
  practiceTow = '',
  qualifyTow = '',
  raceTow = '',
  repairFormula = '',
  damage = '',

  -- ------------------------------------------------------------
  -- 6.1 Penalty control: disqualification
  -- ------------------------------------------------------------
  -- dsqBlackFlagLaps: our DSQ (informative) asks the driver to stop at the pit place; not stopped, the game black flag
  --   (controls locked) comes after this many line crossings.
  dsqBlackFlagLaps = 3,

  -- ------------------------------------------------------------
  -- 6.2 Penalty control: cut zone 1 (category SD1)
  -- ------------------------------------------------------------
  -- cutZoneStart / cutZoneEnd: track spline position of the zone, 0..1. Start = end disables the zone.
  --   Start > end means the zone crosses the start/finish line.
  cutZoneStart = 0.16,
  cutZoneEnd = 0.24,
  -- <session>CutPenalty
  --   'SLOWDOWN': the driver must lift (throttle <= cutSlowdownMaxGas, outside the pit lane) for
  --               <session>CutPenaltyParam seconds, within cutSlowdownDeadline seconds or before the end of the lap.
  --               Unpaid: <session>SlowdownUnpaidPenalty.
  --   'DT': drive-through DT0 at once. 'DSQ': our DSQ at once, in the usual flow (stop at the pit place; game black
  --          flag there or after dsqBlackFlagLaps line crossings). 'NONE': nothing.
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
  -- 6.3 Penalty control: cut zone 2 (category SD2), same meaning as zone 1; slowdown 9 s, deadline 18 s
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
  -- 6.4 Penalty control: slowdown, both zones
  -- ------------------------------------------------------------
  -- Overlapping slowdowns (zone 2 while zone 1 is still running, or the other way round) are merged into one:
  -- the times add up, with the newest deadline; unpaid, each zone becomes its own DT0.
  -- <session>SlowdownUnpaidPenalty
  --   'DT': DT0 of the category (SD1 / SD2). Deadline expired mid-lap: DT0 of the current lap (crossing the line on
  --         track without serving it = DSQ). Expired at the line, or inside the pit lane: DT0 of the next lap.
  --   'DSQ': our DSQ at once, in the usual flow. 'NONE': nothing.
  practiceSlowdownUnpaidPenalty = 'DT',
  qualifySlowdownUnpaidPenalty = 'DT',
  raceSlowdownUnpaidPenalty = 'DT',
  -- <session>SlowdownUnpaidParam: not used (the DT is always DT0).
  practiceSlowdownUnpaidParam = 0,
  qualifySlowdownUnpaidParam = 0,
  raceSlowdownUnpaidParam = 0,
  -- cutSpinAngle: degrees between where the car points and the way of the track at the car; above it during the cut =
  --   spin, cut discarded
  cutSpinAngle = 90,
  -- pitSlowdownDeadline / pitSlowdownMaxGas: not used.
  pitSlowdownDeadline = 0,
  pitSlowdownMaxGas = 0,
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
  practiceCleared = 'Practice - penalties cleared at the pit place',
  pitSpeedNotPaid = 'Pit lane speeding - the drive-through of this pass does not count', practiceTowCleared = 'Practice - penalties cleared by the tow',
  practiceDsqCleared = 'Practice - disqualification cleared at the pit place',
  sgStopped = 'Stop & go %s - stay stopped, no service',
  sgInterrupted = 'Stop & go interrupted - %s left - only the same driver may continue',
  -- own pit stop box (approved screen 11)
  pitMissedLog = 'MISSED - no valid driver swap inside the pit window',
  pitBoxTitle = 'PIT STOP',
  pitBoxTotal = 'Total %s',
  pitBoxConfirm = 'Enter to confirm',
  pitBoxMode = '< %s >',
  pitBoxStart = '   START >',
  pitModeAuto = 'AUTO',
  pitModeManual = 'MANUAL',
  pitBoxServing = 'Pit stop in progress',
  pitFuel = 'Fuel',
  pitFuelValue = '+%d L (to %d / %d L)',
  pitCompound = 'Compound',
  pitTyres = 'Tyres',
  pitPressureFront = 'Pressure front',
  pitPressureRear = 'Pressure rear',
  pitWing = 'Wing',
  pitPressure = 'Pressure',
  pitRepairSuspension = 'Suspension repair',
  pitRepairPowertrain = 'Powertrain repair',
  pitRepairBody = 'Bodywork repair',
  pitRepairYes = 'Repair',
  pitRepairNo = 'No',
  pitRepairNone = 'None',
  pitFuelLocked = 'Locked - red flag', pitRepairLocked = 'After the restart',
  -- setup status (approved screen 14) and car status (approved screen 12)
  setupTitle = 'SETUP STATUS',
  setupLap = 'Lap %d',
  setupAero = 'AERO',
  setupWing = 'Wing',
  setupDrive = 'DRIVE TRAIN',
  setupDiffPower = 'Diff power',
  setupDiffCoast = 'Diff coast',
  setupPreload = 'Preload',
  setupPreloadValue = '%.0f Nm',
  setupBrakeBias = 'Brake bias',
  setupChassis = 'CHASSIS',
  setupHeight = 'Height',
  setupHeaveHeight = 'Heave height',
  setupDeploy = 'Deploy',
  setupErs = 'ERS / Rec.',
  setupArb = 'ARB',
  setupToe = 'Toe',
  setupCamber = 'Camber',
  setupSuspension = 'SUSPENSION',
  setupSpring = 'Spring',
  setupAxes = 'F/R',
  setupBumpSlow = 'Bump S',
  setupReboundSlow = 'Reb. S',
  setupBumpFast = 'Bump F',
  setupReboundFast = 'Reb. F',
  setupHeaveSpring = 'Heave spring',
  setupHeaveBumpSlow = 'Heave bump S',
  setupHeaveReboundSlow = 'Heave reb. S',
  setupHeaveBumpFast = 'Heave bump F',
  setupHeaveReboundFast = 'Heave reb. F',
  setupTyres = 'TYRES', setupGears = 'GEARS',
  setupPsi = 'PSI',
  setupLife = 'Life',
  setupKm = 'Km',
  setupLaps = 'Laps',
  setupLapsOf = '%d/%s',
  statusTitle = 'CAR STATUS',
  statusRepair = 'REPAIR',
  statusBeyond = 'UNSAFE',
  statusWheels = 'WHEELS & SUSPENSION',
  statusPunct = 'PUNCT',
  statusBent = 'BENT +%.0f°',
  statusBroken = 'BROKEN +%.0f°',
  statusBrokenShort = 'BROKEN',
  statusPowertrain = 'POWERTRAIN',
  statusEngine = 'ENGINE',
  statusGearbox = 'GEARBOX',
  statusBop = 'BOP',
  statusOk = 'OK',
  statusBody = 'BODY',
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
  damageEngine = 'Engine blown',
  damageGearbox = 'Gearbox broken',
  damagePowertrain = 'Powertrain damage %.0f%%',
  damagePowertrainLimit = 'repair from %d%%',
  -- DSQ (black flag drawn by the script until the game black flag)
  dsqTitle = 'DISQUALIFIED',
  dsqStop = 'Stop at your pit before the line',
  dsqTow = 'Car withdrawn - return to pits',
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
  wrongWayDsq = 'Driving the wrong way',
  swapVoidService = 'Driver swap not valid - service in the same pit stop',
  wrongWayTitle = 'WRONG WAY',
  wrongWayTurn = 'Turn around - %.0f / %d m',
  wrongWayLimit = 'Over %d m: disqualified',
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
  -- flag box (flags/flags.lua)
  stintMinDsq = 'Stint under the minimum (%s of %d min)',
  stintMaxDsq = 'Stint over the maximum (%d min)',
  kmrRatingDsq = 'KMR safety rating %s (limit %s)',
  -- screens of front E, E3 (draw/race_screens.lua)
  scrRelative = 'RELATIVE', scrStandings = 'STANDINGS', scrLapTime = 'LAP TIME', scrDelta = 'DELTA', scrVsBest = 'vs BEST',
  scrLaps = 'LAPS', scrLapN = 'Lap %d', scrStint = 'STINT - %s - %d laps', scrRace = 'RACE STATUS',
  scrCurrent = 'Current', scrNow = 'Now', scrBest = 'Best', scrOptimal = 'Optimal', scrLast = 'Last',
  scrSession = 'Session', scrInvalid = 'INVALID', scrTime = 'Time left', scrPosition = 'Position', scrLap = 'Lap',
  scrLeader = 'Leader', scrAhead = 'Ahead', scrBehind = 'Behind', scrStops = 'STOPS', scrSwaps = 'SWAPS',
  scrWindow = 'PIT WINDOW', scrStintLine = 'STINT', scrTyres = 'Tyres', scrPending = 'Pending',
  scrOpt = 'Opt.', scrCarBest = 'Car best', scrStintN = 'STINT %d - %s', scrStintInfo = '%d laps - %s',
  scrStintMin = ' / min %d', scrBestAvg = 'Best %s - avg %s', scrDeltaButton = 'Δ',
  scrGaps = 'GAPS', scrObligations = 'OBLIGATIONS', scrTrack = 'Track', scrKmr = 'KMR points',
  scrKmrRating = 'KMR rating',
  sessionName = { [ac.SessionType.Practice] = 'PRACTICE', [ac.SessionType.Qualify] = 'QUALIFY', [ac.SessionType.Race] = 'RACE' },
  -- desktop editor and indicator (draw/desktop_editor.lua)
  edTitle = 'SCREENS', edPitDesk = 'Pit desktop', edDeskOf = 'Desktop %s of %d', edHint = 'drag a screen to its place - title line moves this window',
  edAll = 'all', edScreens = 'Screens', edReset = 'Reset desktop', edCopy = 'Copy from 1', edDelete = 'Delete desktop',
  edPitOn = 'PIT desktop on', edPitOff = 'PIT desktop off',
  edPitWarning = 'PIT desktop off: nothing more is shown in the pit lane - at your own risk',
  edButtons = 'Next screen %s - Previous screen %s - Next desktop %s - Previous desktop %s (CSP controls)',
  edIndicator = 'DESKTOP %d / %d - %s',
  menuButtons = 'Buttons', navTitle = 'BUTTONS', navOwn = 'RECORDED BY THE TOOL', navCsp = 'CSP CONTROLS',
  navNextScreen = 'Next screen', navPrevScreen = 'Previous screen', navNextDesktop = 'Next desktop',
  navPrevDesktop = 'Previous desktop', navSet = 'Set', navClear = 'Clear', navPress = 'Press a button... %d s',
  navInUseAc = 'in use by the AC: %s - choose another', navInUseOwn = 'in use by %s of this tool - choose another',
  navButton = '%s - button %d', navPov = '%s - D-pad %d deg', navGamepad = 'Gamepad %d - %s', navKey = 'Key %s',
  navDeviceOff = 'device off',
  navUp = 'Up', navDown = 'Down', navLeft = 'Left (value -)', navRight = 'Right (value +)',
  navKeyNames = { [37] = 'Left arrow', [38] = 'Up arrow', [39] = 'Right arrow', [40] = 'Down arrow' },
  menuSettings = 'Settings', menuRedFlag = 'Race direction',
  dirTitle = 'RACE DIRECTION', dirRole = { director = 'DIRECTOR', staff = 'STAFF', broadcast = 'BROADCAST - read only' },
  dirLogin = 'KMR admin login', dirLoginSent = 'Login sent - waiting for the KMR', dirLoginOk = 'KMR admin: logged in',
  dirNoAnswer = 'No answer from the KMR in 5 s - login or command failed',
  dirFailed = 'Failed: %s', dirSent = 'Sent: %s - waiting for the KMR', dirAnswer = 'KMR: %s',
  dirNextSession = 'NEXT SESSION', dirRestart = 'RESTART SESSION', dirCancelDt = 'NO DT', dirToPit = 'TO PIT', dirFuel = 'FUEL',
  setTitle = 'SETTINGS', setTabs = { messages = 'Messages', controls = 'Controls', app = 'App' }, setPreset = 'Preset',
  setPresets = { verbose = 'Verbose', race = 'Race', minimal = 'Minimal', custom = 'Custom' }, setAlways = 'always - on the Race Control panel',
  setAreas = { rc = 'Race Control, flags, driver swap, race director', limits = 'Track limits and invalid laps',
    damage = 'Collisions and damage', points = 'Points and rating (KMR)', warnings = 'Behaviour warnings',
    others = 'Penalties of other drivers', results = 'Session results and records', welcome = 'Welcome and stats',
    admin = 'Server administration', chat = "Drivers' chat", server = 'Other server messages',
    diag = 'Diagnostics: car changes and the button' },
  setAreaHint = { limits = 'laptime invalidated', damage = 'Damage: -3p', points = 'reward, cost, balance',
    warnings = 'lapped, hotlap, speed', others = 'KMR, race director', results = 'winner, pole, fastest lap',
    welcome = 'at the entry', admin = 'kick, ban, track vote', chat = 'in our window', server = 'not the race direction', diag = 'lights, limiter, engine, camera' },
  setCtl = { on = 'Show car controls', elec = 'Electronics', engine = 'Engine and brakes', hybrid = 'Hybrid',
    aero = 'Aero (DRS)', pit = 'Pit limiter' },
  setServer = 'Server', setCsp = 'CSP', setScript = 'Script', setApp = 'App', setRunning = 'running',
  msgTitle = 'MESSAGES', setMissing = 'missing', setChecking = 'checking', setAllGood = 'All good - closes in %d s', setNotGood = 'Not all good - close it yourself',
  redTitle = 'RED FLAG CONTROL', redNone = 'no red flag', redConfirm = 'CONFIRM RED FLAG', redVsc = 'RESUME VSC %d s',
  redGreen = 'GREEN', dirVsc = 'VSC %d s', dirMoney = 'RESET MONEY', dirStats = 'RESET STATS', dirNoSg = 'NO S&G',
  dirKmrLine = 'KMR  points %s / %d  -  safety %s  -  crashes %s (%s / 100 km)  -  infractions %s (%s / 100 km)',
  dirKmrNone = 'KMR  no numbers from this driver yet',
  dirDriver = 'Driver', dirList = 'DRIVERS', dirListBtn = 'LIST', dirSessionTime = '%s elapsed / %s left',
  dirSessionLaps = 'lap %d', dirSessionLapsOf = 'lap %d / %d - %d left',
  dirLeft = 'Left the server', dirGuidAsk = 'Asking the KMR the GUID of %s',
  dirGuidNone = 'The KMR gave no GUID for %s (the name is case sensitive)',
  dirNoRed = 'No red flag nor VSC on', redKmrOn = 'KMR admin: logged in', redKmrOff = 'KMR admin: type /kmr login <password> in the chat',
  redPlace = 'pit place', redLane = 'pit lane', redTrack = 'track', redCount = 'In the pits %d / %d - over the limit %d',
  lobbyTitle = 'RACE CONTROL', lobbyStops = 'Stops', lobbyKmr = 'KMR points / rating', lobbyWeather = 'Air / track',
  lobbyMessages = 'MESSAGES', lobbyWindow = 'Race Control - lobby',
  menuDesktops = 'Desktops', menuAudit = 'Audit', auditTitle = 'AUDIT', auditPoints = 'KMR points %d / %d',
  auditRating = 'KMR rating %s',
  auditCount = '%d messages', auditEmpty = 'No messages in this session',
  edStrip = 'CONTROLS - MESSAGES (on demand)', edFlagStrip = 'FLAGS (on demand)', edPin = 'Pin to all', edPinned = 'On all desktops', edMode = 'Mode: %s', edRemove = 'Remove',
  edChoose = 'Click a screen to choose it and drag it to its place',
  screenNames = { pitbox = 'Pit stop', setup = 'Setup status', status = 'Car status', race = 'Race status', laps = 'Laps',
    standings = 'Standings', relative = 'Relative', laptime = 'Lap time', delta = 'Delta', event = 'Event',
    weather = 'Weather', map = 'Track map' },
  scrClassSel = '< CLASS: %s >', scrLapsCar = 'LAPS - CAR #%s', scrLapsMore = 'MORE', scrLapsLess = 'LESS',
  scrCompare = 'COMPARE', scrDriverSel = '< DRIVER: %s >', scrStintShort = 'ST %d', scrMap = 'TRACK MAP', scrNoMap = 'No map of this track',
  scrMapLegend = { 'yellow you - blue lap ahead - beige lap down', 'grey pit - red stopped' },
  scrWeather = 'WEATHER', scrWeatherModes = { forecast = 'FORECAST', map = 'MAP' },
  scrWeatherAnim = 'forecast hour by hour', scrWeatherStatic = 'no forecast',
  scrWxTime = 'Local Time', scrWxSky = 'Sky', scrWxAir = 'Air / track', scrWxWind = 'Wind', scrWxRain = 'Rain', scrWxNext = 'Next',
  scrEvent = 'EVENT', scrEventInfo = 'event info', evStops = 'Pit stops required', evSwaps = 'Driver swaps required',
  evStint = 'Stint', evOrder = 'Pit stop order', evPitSpeed = 'Pit lane speed', evRating = 'KMR rating',
  flagRed = 'RED FLAG',
  flagRedLine = 'Slow down - no overtaking - return to the pit lane',
  flagRedNeutral = 'Race neutralized by Race Control',
  flagRedSpeed = 'Max %d km/h - you: %.0f km/h',
  redFlagLineDsq = 'Line crossed in the pit lane with the red flag (leaving the pits)',
  flagRedGrace = 'No overtaking from now on - %d s', flagRedToLine = 'Complete your lap: cross the line on track',
  flagRedToBox = 'Red flag received - go to your pit place',
  redFlagLineAgainDsq = 'Line crossed again with the red flag - did not go to the pits',
  redFlagPassDsq = 'Overtake with the red flag (%s)',
  redFlagSpeedSG = 'CODE-65: over %d km/h for more than %d s with the red flag', yellowPassSG = 'Overtake under the yellow flag (%s) not given back',
  flagGiveBack = 'GIVE THE PLACE BACK TO %s - %d s', sgFlagGiven = 'Stop & go %d s - %s',
  yellowGivenBack = 'Place given back to %s',
  flagCode80 = { VSC = 'VIRTUAL SAFETY CAR', SC = 'SAFETY CAR', ['CODE-80'] = 'FULL COURSE YELLOW' },
  flagCode80Line = 'Full course - no overtaking',
  flagRaceControl = 'Race Control',
  flagYellow = 'YELLOW FLAG',
  flagYellowLine = 'Slow down - no overtaking',
  flagIncidentAhead = '%s %s %.0f m ahead',
  flagIncident = { stopped = 'stopped', broken = 'broken down', oil = 'engine failure' },
  flagCausedBy = 'Incident - %s',
  flagWhite = 'WHITE FLAG',
  flagWhiteLine = 'Slow car ahead',
  flagSlowAhead = '%s - %.0f m - %.0f km/h',
  flagSlippery = 'SLIPPERY TRACK',
  flagOil = 'Oil on track',
  flagOilCar = '%s engine failure',
  flagWet = 'Wet track',
  flagBlue = 'BLUE FLAG',
  flagBlueLine = 'Faster car behind - let it pass',
  flagLastLap = 'LAST LAP',
  flagLastLapLine = 'One lap to go',
  flagGreen = 'GREEN FLAG',
  flagGreenLine = 'Track clear - racing', flagStart = 'GREEN FLAG - GO GO', flagStartLine = 'Rolling start - racing',
  startTitle = 'ROLLING START - FORMATION LAP', startLimits = 'Max %d / min %d km/h - no overtaking',
  startNoOvertake = 'No overtaking before the green flag', startRelease = 'Speed limit off - start when the leader crosses the line',
  startWaiting = 'Formation lap about to start', startNoPlace = 'Keep your place',
  startPlace = 'P%d - stay behind %s', startLeader = 'nobody: you lead', startBehindYou = ' - %s behind you',
  startPassedBy = ' - %s passed you', startGiveBack = 'GIVE THE PLACE BACK TO %s', startPassAllowed = 'P%d - %s can be passed (KMR)',
  flagRedLocked = 'Stay at your pit place - controls locked until the restart',
  flagRestart = 'Restart P%d - behind %s', flagRestartFirst = 'Restart P%d - first car',
  flagRestartSwap = 'Restart P%d - driver swap: back of the field, behind %s',
  appMissing = 'Race Control app not running - install it from the event page - the game closes in %d s',
  redTowDeferred = 'Tow under the red flag: the tow and repair time starts at the restart',
  redNoLineSG = 'Pit entry with the red flag not received at the line', redFuelUnlocked = 'Fuel unlocked by Race Control',
  redFlagNoPitDsq = 'Not in the pits at the restart after the red flag',
  flagChequered = 'CHEQUERED FLAG', flagChequeredMine = 'Session over for you', flagChequeredPos = 'P%d - %d laps',
  flagTimeOver = 'SESSION TIME OVER', flagRaceOver = 'RACE OVER', flagFinishLap = 'Finish your lap - the chequered flag is at the line',
  flagChequeredLine = 'Session finished',
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
local TYRE_LIFE = structKey('tyreLife', { ok = 70, worn = 30 })
local TYRE_TEMP = structKey('tyreTemp', { edge = 98 })
local WRONG_WAY = structKey('wrongWay', { maxMeters = 30, penalty = 'DSQ', showMeters = 2, angle = 90 })
local DAMAGE = structKey('damage', { toeBent = 10, toeBroken = 20, camberBent = 10, camberBroken = 20, bodyRepair = 150,
  powertrainRepair = 45,
  maxPunctured = 2, repairLaps = 2, beyondTowSeconds = 180, dsqTowSeconds = 180, settleSeconds = 1 })

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
  pitStopAuto = string.upper(tostring(cfg.pitStopMode or 'AUTO')) ~= 'MANUAL',
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
  dataCheck = tonumber(cfg.dataCheck) ~= 0,
  screenScale = SCREEN_SCALE,
  tyreLife = TYRE_LIFE,
  tyreTemp = TYRE_TEMP,
  wrongWay = WRONG_WAY,
  flags = structKey('flags', { slowMeters = 300, yellowMeters = 500, oilSeconds = 300, rainSlippery = 0.2,
    greenSeconds = 5, redSpeedKmh = 65, redGraceSeconds = 10, passSlowKmh = 40, passFarM = 75, redSpeedSG = 30, redOverSeconds = 10, redNoLineSG = 120,
    yellowPassSG = 10, yellowGiveBackSeconds = 10 }),
  driverStint = structKey('driverStint', { minMinutes = 0, maxMinutes = 0 }),
  kmrPoints = structKey('kmrPoints', { limit = 100 }),
  eventName = tostring(cfg.eventName or ''),
  -- KMR safety rating (decision 215): dsqAt; on = the key is set (empty = the rating is only shown)
  kmrRating = (function()
    local r = structKey('kmrRating', { dsqAt = 0 })
    r.on = tostring(cfg.kmrRating or ''):match('%S') ~= nil
    return r
  end)(),
  screens = structKey('screens', { autoSeconds = 5, closeGap = 2.5, noticeSeconds = 3, serverNoticeSeconds = 5,
    messageSeconds = 5, pitBoxSeconds = 5, indicatorSeconds = 2, buttonSeconds = 10, controlSeconds = 3 }),
  -- Tow per session: mode ('TOW', 'RESET', 'NONE'), towSeconds, repairFactor
  tow = bySession(
    structKey('practiceTow', { mode = 'RESET', towSeconds = 0, repairFactor = 0, clearDsq = 1 }),
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
    powertrainRepair = DAMAGE.powertrainRepair,
    maxPunctured = DAMAGE.maxPunctured,
    repairLaps = DAMAGE.repairLaps,
    settleSeconds = DAMAGE.settleSeconds,
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
-- Role of this client (decision 243): 'director', 'staff' (commands like the director), 'broadcast' (read only) or nil.
-- The director's own duties (ban of an edited file, the checks of the KMR mode) stay with the director only
do
  local me = tostring(ac.getUserSteamID() or '')
  local function listed(keyText)
    for id in tostring(keyText or ''):gmatch('[^|]+') do
      if me ~= '' and id:match('^%s*(.-)%s*$') == me then return true end
    end
    return false
  end
  config.role = config.isDirector and 'director' or (listed(cfg.staffSteamIDs) and 'staff')
    or (listed(cfg.broadcastSteamIDs) and 'broadcast') or nil
  config.canCommand = config.role == 'director' or config.role == 'staff'
end
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
  sessionStartPending = false,  -- start / restart of a session (ac.onSessionStart), read by the session start
  jumpSinceUpdate = false,      -- a reset of the car (ac.onCarJumped) since the last frame
  kmrMessages = {},
  tyreLaps = { [0] = 0, 0, 0, 0 },   -- laps of each tyre since it was fitted (car record)
  tyreKm = { [0] = 0, 0, 0, 0 },     -- km driven by each tyre since it was fitted (car record)
  tyreLineKm = { [0] = 0, 0, 0, 0 }, -- virtual km of each tyre at its last line crossing, never down (car record)
  pitPassServiced = false,   -- a service in the pit pass in progress (kept in the pit record: the next driver sees it)
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
    voids = 0,            -- valid swaps taken back: a service in the same pit stop (decision 161); valid - voids
    passSwap = false,     -- a driver swap in the pit pass in progress (this driver took the car in it)
    passSwapValid = false, -- ... and it was a valid one
    passVoided = false,   -- ... and it was already taken back
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
  dsqFlagPutBack = nil,   -- game black flag put back in this session after the game took it off (decision 175)
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
-- The reset of the car by a new session (another session index, or the start event before it) is no teleport of the
-- driver (decision 218): no tow, no hold, the car state not saved; the session start takes care of the car. A restart
-- whose event comes after the reset is caught by the session start (state.jumpSinceUpdate)
ac.onSessionStart(function(index, restarted)
  state.sessionStartPending = true
  ac.log(string.format('race-control: session start event (index %d, restarted %s)', index, tostring(restarted)))
end)

ac.onCarJumped(0, function()
  state.jumpSinceUpdate = true
  if state.lastSessionIndex ~= -1 and (sim.currentSessionIndex ~= state.lastSessionIndex or state.sessionStartPending) then
    ac.log('race-control: car reset by the session start (not a tow)')
    return
  end
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
for _, key in ipairs({ 'screenScale', 'tyreLife', 'tyreTemp', 'wrongWay', 'stopAndGo', 'practiceTow', 'qualifyTow', 'raceTow', 'repairFormula', 'damage' }) do
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
  for i = 0, 3 do s.body[i] = CarRead.num(car.damage[i]) end
  return s
end
-- Service at the pit place: the own pit stop box running a stop, or a real change in the car since it arrived (fuel
-- added, compound or tyres changed, damage repaired). Without a change in the car there is no service (the game flags
-- and the AC pit screen opened and closed do not count)
-- Second value: what changed, for the log (decision 218)
function CarRead.serviced(car, s)
  if state.pitService ~= nil then return true, 'pit stop box' end
  local num = CarRead.num
  if num(car.fuel) > s.fuel then return true, string.format('fuel %.2f -> %.2f L', s.fuel, num(car.fuel)) end
  if num(car.compoundIndex) ~= s.compound then return true, 'compound ' .. s.compound .. ' -> ' .. num(car.compoundIndex) end
  if num(car.engineLifeLeft) > s.engine then
    return true, string.format('engine %.0f -> %.0f', s.engine, num(car.engineLifeLeft))
  end
  for i = 0, 3 do
    local km = num(car.wheels and car.wheels[i] and car.wheels[i].tyreVirtualKM)
    if km < s.km[i] then return true, string.format('tyre %d %.3f -> %.3f km', i, s.km[i], km) end
    if num(car.suspensionDamage[i]) < s.susp[i] then
      return true, string.format('suspension %d %.3f -> %.3f', i, s.susp[i], num(car.suspensionDamage[i]))
    end
  end
  -- Body: the 4 zones of the damage screen (the fifth "is not really used", SDK; decision 168)
  for i = 0, 3 do
    if num(car.damage[i]) < s.body[i] then
      return true, string.format('body %d %.1f -> %.1f', i, s.body[i], num(car.damage[i]))
    end
  end
  return false
end
-- Stopped at its own pit place: the game's own reading (SDK car.isInPit: "parked in its pit stop place")
function CarRead.parked(car) return car.isInPit end
-- Moving: any speed
function CarRead.moving(car) return car.speedKmh > 0 end
-- Setup values as shown (value x displayMultiplier), by setup section name (WING_1, SPRING_RATE_LF ...); '-' for an item
-- the car does not have. One reading for the setup status and the pit stop box
function CarRead.setupValues()
  local out = setmetatable({}, { __index = function() return '-' end })
  for _, sp in ipairs(ac.getSetupSpinners() or {}) do
    local v = CarRead.num(sp.value) * (tonumber(sp.displayMultiplier) or 1)
    out[tostring(sp.name):upper()] = (math.floor(v) == v) and tostring(v) or string.format('%.1f', v)
  end
  return out
end

-- Tyre readings: helpers kept inside this block (the whole script is one chunk, limited to 200 local variables)
do
-- A curve of the tyre of the car (tyres.ini of the car data, section of the compound fitted and the axle of wheel i:
-- prefix FRONT / REAR, _n for compound n; key WEAR_CURVE or PERFORMANCE_CURVE), read once (false = none)
local tyreCurves = {}
local function tyreCurve(car, i, prefix, key)
  local compound = CarRead.num(car.compoundIndex)
  local axle = prefix .. (i < 2 and 'FRONT' or 'REAR')
  local section = compound == 0 and axle or (axle .. '_' .. compound)
  local id = section .. '/' .. key
  local lut = tyreCurves[id]
  if lut == nil then
    lut = false
    local ini = ac.INIConfig.carData(0, 'tyres.ini')
    local file = ini and ini:get(section, key, '') or ''
    if file ~= '' then
      local ok, l = pcall(ac.DataLUT11.carData, 0, file)
      if ok and l then lut = l end
    end
    tyreCurves[id] = lut
  end
  return lut
end

-- Wear of a tyre by the wear curve of the compound fitted (decision 166): the curve (WEAR_CURVE of tyres.ini, [FRONT] /
-- [REAR], _n for compound n) gives the grip % by virtual km, and the game wears the tyre along it by its virtual km
-- (wheel tyreVirtualKM: "not an actual distance, rate of change depends on wear multiplier"). Life in %: 100 up to the
-- end of the top of the curve (highest grip), then the grip at the virtual km between the top (100) and the lowest
-- grip of the curve (0, end of life). Also the virtual km of the end of life (first point at the lowest grip after the
-- top). km: the virtual km of the tyre taken at the line (TyreUse, decision 170), not the reading of the frame. nil when
-- the car data has no wear curve
local function tyreWearState(car, i, km)
  local lut = tyreCurve(car, i, '', 'WEAR_CURVE')
  if not lut then return nil end
  local lo, hi = lut:bounds()
  if not lo or not hi or hi.y <= lo.y then return nil end
  local pts, k = {}, 0
  while true do
    local x, y = lut:getPointInput(k), lut:getPointOutput(k)
    if x == nil or x ~= x then break end
    pts[#pts + 1] = { x = x, y = y }
    k = k + 1
  end
  local topEnd, endKm = -math.huge, nil
  for _, p in ipairs(pts) do
    if p.y >= hi.y then topEnd = p.x end
  end
  for _, p in ipairs(pts) do
    if not endKm and p.x > topEnd and p.y <= lo.y then endKm = p.x end
  end
  local life = km <= topEnd and 100 or math.min(math.max((lut:get(km) - lo.y) / (hi.y - lo.y) * 100, 0), 100)
  return life, endKm
end

-- Remaining life of a tyre in % at the virtual km km (decision 166): tyreWearState. nil when the car data has no wear
-- curve
function CarRead.tyreLife(car, i, km)
  return (tyreWearState(car, i, km))
end

-- Laps of a tyre against its wear curve (decisions 165, 170): the life (tyreWearState) and the expected laps of the
-- tyre: virtual km of the end of life, at the virtual km per lap of the laps run (km: the virtual km at the last line).
-- limit nil before a lap with virtual km; nil when the car data has no wear curve
function CarRead.tyreLapLimit(car, i, laps, km)
  local life, endKm = tyreWearState(car, i, km)
  if not life then return nil end
  local limit = endKm and laps > 0 and km > 0 and math.floor(endKm * laps / km) or nil
  return life, limit
end

-- Thermal state of a tyre (decision 164), the way proTyres does it: temperature = 75% core + 25% average of the tread
-- (inside, middle, outside); grip at that temperature from the thermal curve of the compound fitted (tyres.ini
-- [THERMAL_FRONT] / [THERMAL_REAR], _n for compound n: PERFORMANCE_CURVE), in % of its highest grip. Side: 'ideal'
-- on the top of the curve, 'cold' before it, 'hot' after it. Also the lowest grip of the hot end (the cliff reaches it).
-- nil when the car data has no thermal curve
function CarRead.tyreThermal(car, i)
  local lut = tyreCurve(car, i, 'THERMAL_', 'PERFORMANCE_CURVE')
  local w = car.wheels and car.wheels[i]
  if not lut or not w then return nil end
  local n = CarRead.num
  local t = 0.75 * n(w.tyreCoreTemperature) + 0.25 * (n(w.tyreInsideTemperature) + n(w.tyreMiddleTemperature)
    + n(w.tyreOutsideTemperature)) / 3
  local _, hi = lut:bounds()
  if not hi or hi.y <= 0 then return nil end
  -- The top of the curve: first and last point at its highest grip; the grip at its hot end
  local top1, top2, hotEnd, k = nil, nil, nil, 0
  while true do
    local x, y = lut:getPointInput(k), lut:getPointOutput(k)
    if x == nil or x ~= x then break end
    if y >= hi.y then top1 = top1 or x; top2 = x end
    hotEnd = y
    k = k + 1
  end
  if not top1 then return nil end
  local side = t < top1 and 'cold' or (t > top2 and 'hot' or 'ideal')
  return { grip = lut:get(t) / hi.y * 100, side = side, hotEnd = (hotEnd or hi.y) / hi.y * 100, temp = t }
end
end

-- Movement of the car, from documented world readings only: where it is frame to frame (SDK car.position: "Car position
-- in the world"), where it points (car.look: "Vector facing forward") and where a point is on the track
-- (ac.worldCoordinateToTrackProgress: "Finds nearest point on track AI spline and returns its normalized position").
-- Read once a frame (CarRead.updateMotion, script.update). The reference of every angle is the way of the track at
-- the car (CarRead.trackAngle), never the car's own movement: used by the spin check and the wrong way rule.
CarRead.motion = { x = nil, z = nil, dx = 0, dz = 0, dist = 0 }
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
local MOTION_JUMP_M = 50     -- a move this big in one frame is a teleport or a car reset, not driving
local TRACK_PROBE_M = 10     -- the direction along the track is read this many metres away from the car

function CarRead.updateMotion(car)
  local m, p = CarRead.motion, car.position
  if m.x then
    m.dx, m.dz = p.x - m.x, p.z - m.z
    m.dist = math.sqrt(m.dx * m.dx + m.dz * m.dz)
    if m.dist > MOTION_JUMP_M then m.dx, m.dz, m.dist = 0, 0, 0 end
  end
  m.x, m.z = p.x, p.z
end

-- Angle between a direction on the ground (x, z) and the way of the track at the car, degrees (0 = the way of the
-- track, 180 = against it): how much the track progress changes TRACK_PROBE_M metres along that direction; nil when
-- it cannot be read (no AI spline)
function CarRead.trackAngle(car, x, z)
  local len = tonumber(sim.trackLengthM) or 0
  local n = math.sqrt(x * x + z * z)
  if len <= 0 or n <= 0 then return nil end
  local p = car.position
  local a = ac.worldCoordinateToTrackProgress(p)
  local b = ac.worldCoordinateToTrackProgress(vec3(p.x + x / n * TRACK_PROBE_M, p.y, p.z + z / n * TRACK_PROBE_M))
  if not a or not b or a < 0 or b < 0 then return nil end
  local d = b - a
  if d > 0.5 then d = d - 1 elseif d < -0.5 then d = d + 1 end
  return math.deg(math.acos(math.min(math.max(d * len / TRACK_PROBE_M, -1), 1)))
end
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
-- (key screens: noticeSeconds, serverNoticeSeconds)
local NOTICE_SECONDS = config.screens.noticeSeconds
local SERVER_NOTICE_SECONDS = config.screens.serverNoticeSeconds

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

-- A new session or a restart within the running script (decision 275): a restart soon after the start has the same
-- key (session start within the tolerance), so the records of the run before would come back. Record.floor = server
-- seconds of that start: a record with a version under it is of the run before and is ignored (here and in
-- RecordSync); the versions saved from then on are raised over it (floor + the list's own version)
Record.floor = 0
function Record.fresh() Record.floor = math.floor(serverTimeMs() / 1000) end

function Record.save(list, seq, body)
  if seq < Record.floor then seq = Record.floor + seq end
  local text = Record.encode(list, seq, body)
  ac.store(RECORD_PREFIX .. list, text)
  ac.storage[STORAGE_PREFIX .. list] = text
  if Record.onSave then Record.onSave(list, seq, text) end
end

local function valid(rec, list)
  if not rec or rec.list ~= list or not Record.sameRace(rec.key, Record.key()) or rec.seq < Record.floor then return nil end
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
-- Check of the data that comes from the other cars (decision 249; Segurança, risk 3). The server tells who sent each
-- message (sender), so a car cannot pass for another; what is checked is the content, with what this computer sees:
--   1. A record of a car only from that car (rcCar = the sender's own slot), or the answer about this car when it
--      asked for its records (the others keep them for it).
--   2. The answers about this car are confirmed by the others: during the answer window the one the most drivers sent
--      wins (with only one driver answering, his).
--   3. An incident told by a car (slow, stopped, broken, oil) where that car really is: its place on the track within
--      TRUST_POS_M of the place it tells; stopped and broken, with the car really slow.
--   4. The penalty list of a car only from that car.
-- Key dataCheck (1 = on, the default; 0 = off: everything as before, nothing refused). A message refused is only
-- dropped and logged (the first of each kind and car also goes to the server log), nothing else changes.
-- ============================================================

local Trust = { refused = {} }
do
  local TRUST_POS_M = 250          -- metres between the place a car tells and where it is
  local TRUST_STOPPED_KMH = 30     -- a car telling it is stopped or broken is below this

  function Trust.on() return config.dataCheck end

  local function refuse(kind, sender, why)
    local who = sender and tostring(sender.sessionID) or '?'
    ac.log(string.format('race-control: data check: %s from car %s refused (%s)', kind, who, why))
    local key = kind .. '/' .. who
    if not Trust.refused[key] then
      Trust.refused[key] = true
      rcLog('Data check', string.format('%s from car %s refused - %s', kind, who, why))
    end
    return false
  end

  -- 1. A record about car (server slot) from sender; ownAnswer: this car asked the others for its own records
  function Trust.record(sender, car, ownAnswer)
    if not Trust.on() then return true end
    if not sender then return refuse('record', sender, 'no sender') end
    if sender.sessionID == car then return true end
    if ownAnswer then return true end
    return refuse('record', sender, 'about car ' .. tostring(car))
  end

  -- 3. An incident: kind (1 slow, 2 stopped, 3 broken, 4 oil), pos (0..1 of the lap)
  function Trust.incident(sender, kind, pos)
    if not Trust.on() or kind == 0 then return true end
    local c = sender and ac.getCar(sender.index)
    if not c or not c.isConnected then return refuse('incident', sender, 'car not connected') end
    local len = tonumber(sim.trackLengthM) or 0
    local d = math.abs(CarRead.num(c.splinePosition) - pos)
    d = math.min(d, 1 - d) * len
    if len > 0 and d > TRUST_POS_M then return refuse('incident', sender, string.format('%.0f m from the car', d)) end
    if (kind == 2 or kind == 3) and CarRead.num(c.speedKmh) > TRUST_STOPPED_KMH then
      return refuse('incident', sender, string.format('stopped at %.0f km/h', CarRead.num(c.speedKmh)))
    end
    return true
  end

  -- 4. The penalty list published for a car (server slot)
  function Trust.list(sender, car)
    if not Trust.on() then return true end
    if sender and sender.sessionID == car then return true end
    return refuse('penalty list', sender, 'about car ' .. tostring(car))
  end

  -- 2. Votes of the answers about this car: [list] = { [text] = { seq, senders = {}, count } }; the winner of a list
  -- once its answers settled: every other connected car answered, or TRUST_SETTLE seconds after the first answer
  local TRUST_SETTLE = 3
  local votes, firstT, answered = {}, {}, {}
  local function othersConnected()
    local n = 0
    for i = 1, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and c.isConnected then n = n + 1 end
    end
    return n
  end
  function Trust.vote(list, seq, text, sender)
    local byText = votes[list] or {}
    votes[list] = byText
    firstT[list] = firstT[list] or state.ui.clock
    answered[list] = answered[list] or {}
    answered[list][sender and sender.sessionID or -1] = true
    local v = byText[text] or { seq = seq, senders = {}, count = 0 }
    byText[text] = v
    local who = sender and sender.sessionID or -1
    if not v.senders[who] then
      v.senders[who] = true
      v.count = v.count + 1
    end
  end
  -- Lists whose answers settled: { [list] = { text, seq } }, cleared once read
  function Trust.settled()
    local out = {}
    local others = othersConnected()
    for list, byText in pairs(votes) do
      local n = 0
      for _ in pairs(answered[list]) do n = n + 1 end
      if n >= others or state.ui.clock - firstT[list] >= TRUST_SETTLE then
        local best
        for text, v in pairs(byText) do
          if not best or v.count > best.count or (v.count == best.count and v.seq > best.seq) then
            best = { text = text, seq = v.seq, count = v.count }
          end
        end
        if best then
          out[list] = best
          if next(byText, next(byText)) then
            ac.log(string.format('race-control: data check: %s answered in different versions; %d driver(s) agree',
              list, best.count))
          end
        end
        votes[list], firstT[list], answered[list] = nil, nil, nil
      end
    end
    return out
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
  local SYNC_LISTS = { 'penalties', 'window', 'swap', 'track', 'car', 'gain', 'pit', 'stint' }
  local SYNC_CODES = { penalties = 1, window = 2, swap = 3, track = 4, car = 5, gain = 6, pit = 7, stint = 8 }

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

  local function onRecordText(car, list, text, sender)
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
    -- Data check on (Trust): the answers about this car are voted, the most confirmed one is applied (RecordSync.update)
    if Trust.on() then
      Trust.vote(list, rec.seq, text, sender)
      return
    end
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
    -- A record only from its own car, or the answer about this car after it asked (Trust)
    if not Trust.record(sender, msg.rcCar, msg.rcCar == ownSlot() and RecordSync.askedT ~= nil) then return end
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
    onRecordText(msg.rcCar, list, table.concat(chunks), sender)
  end

  -- Applies the own records received from the others (sending is done by OnlineQueue)
  function RecordSync.update()
    -- The answers about this car confirmed by the others (Trust, data check on)
    for list, best in pairs(Trust.settled()) do
      local rec = Record.decode(best.text)
      if rec then RecordSync.pending[list] = { body = rec.body, seq = rec.seq } end
    end
    for list, p in pairs(RecordSync.pending) do
      RecordSync.pending[list] = nil
      local restore = RecordSync.restorers[list]
      -- A record of the run before a restart (decision 275: Record.floor) is not taken back
      if restore and (p.seq or 0) >= Record.floor then restore(p.body, p.seq, 'peers') end
    end
  end

  Record.onSave = RecordSync.publish
end
-- ============================================================
-- Link with the Race Control app (front E, decision 189: the app does only what the online script cannot). One channel,
-- shared events (measured in M1: online script and app see each other's shared events; the sender comes with its ID,
-- M9). Today: the pressure and wing of the pit stop preset (decision 201), written by the app with
-- ac.setPitstopSpinnerValue (M7). Request: "<name>=<value>;..." on APP_REQUEST; answer: "<name>=<ok|fail>;..." on
-- APP_ANSWER, only for the log. An empty request is the check of the app (settings, App tab): the app answers it with
-- nothing written, so an answer means the app is running (no change in the app)
-- Mutual check (decision 271): nobody drives on the server without the online script and the app both running. The
-- script sends the empty request every PING_SECONDS (the app takes it as the sign that the script runs, and closes the
-- game without it); without an answer of the app within CHECK_SECONDS the controls are locked, the driver is told and,
-- after CLOSE_SECONDS more, the game is closed (ac.shutdownAssettoCorsa). Once the app answered, it is not checked
-- again (a loss later is only logged: a race is not ended by it).
-- ============================================================

local AppLink = { alive = false }
do
  local APP_REQUEST = '12hcuritiba.race-control.preset'
  local APP_ANSWER = '12hcuritiba.race-control.preset.done'

  -- Values changed in the pit stop box: { { name, value } }
  function AppLink.setPreset(changes)
    local parts = {}
    for _, c in ipairs(changes) do parts[#parts + 1] = c.name .. '=' .. math.floor(c.value) end
    local text = table.concat(parts, ';')
    ac.broadcastSharedEvent(APP_REQUEST, text)
    ac.log('race-control: pit stop preset sent to the app: ' .. text)
  end

  local pingT = -1e9
  function AppLink.ping()
    pingT = state.ui.clock
    ac.broadcastSharedEvent(APP_REQUEST, '')
  end
  -- Waiting for the answer (3 s); after it with no answer the app is not running (the settings say missing)
  function AppLink.waiting() return not AppLink.alive and state.ui.clock - pingT < 3 end

  local PING_SECONDS, CHECK_SECONDS, CLOSE_SECONDS = 2, 30, 10
  local lastPing, lockT, missingLogged = -1e9, -1e9, false
  function AppLink.update()
    local clock = state.ui.clock
    if clock - lastPing >= PING_SECONDS then
      lastPing = clock
      ac.broadcastSharedEvent(APP_REQUEST, '')
    end
    if AppLink.alive or clock < CHECK_SECONDS then return end
    if not missingLogged then
      missingLogged = true
      ac.log('race-control: the Race Control app is not running: controls locked, the game closes')
      rcLog('App missing', string.format(TEXTS.appMissing, CLOSE_SECONDS))
    end
    if clock - lockT >= 2 then
      lockT = clock
      physics.lockUserControlsFor(3)
    end
    local left = math.max(math.ceil(CHECK_SECONDS + CLOSE_SECONDS - clock), 0)
    showNotice(TEXTS.rcTitle, string.format(TEXTS.appMissing, left), nil, 1)
    if left <= 0 and not AppLink.closed then
      AppLink.closed = true
      ac.shutdownAssettoCorsa()
    end
  end

  ac.onSharedEvent(APP_ANSWER, function(data, senderName, senderType, senderID)
    AppLink.alive = true
    if tostring(data or '') == '' then return end
    ac.log(string.format('race-control: pit stop preset written by the app (%s, %s, %s): %s', tostring(senderName),
      tostring(senderType), tostring(senderID), tostring(data)))
  end)
end
-- ============================================================
-- Pit record of the car: stops with service and the tow / repair hold in progress. Kept in the three layers of the
-- car record (this process, this computer, the other drivers), so a hold keeps counting in server time while one
-- driver leaves and another enters, or through a crash (the new connection gets the time left).
-- Body: <stops with service>|<last stop: lap/fuel added/tyres/repair>|<hold end, server ms (0 = none)>|<hold text>|
--       <pit stop in progress: start ms/end ms/plan (PitBox), or ->|<service in the pit pass in progress: 1 / 0>|
--       <tow under the red flag waiting for the restart: tow s/powertrain/suspension/body, or empty>
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
  local rt = state.redTow
  Record.save('pit', PitRecord.seq, string.format('%d|%s|%d|%s|%s|%d|%s', PitRecord.stops, PitRecord.last,
    h and math.floor(h.untilMs) or 0, text,
    sv and string.format('%d/%d/%s', math.floor(sv.startMs), math.floor(sv.untilMs), sv.plan) or '-',
    state.pitPassServiced and 1 or 0, rt and string.format('%d/%.4f/%.4f/%.2f', rt.tow, rt.damage.powertrain,
    rt.damage.suspension, rt.damage.body) or ''))
end

-- A record of this process (script reload: the game hold is still running) or of another connection (the hold is
-- applied again for the time left)
local function pitApply(body, seq, newConnection)
  local stops, last, untilMs, text, service, serviced, redTow =
    tostring(body):match('^(%d+)|([^|]*)|(%d+)|([^|]*)|([^|]*)|?(%d?)|?([^|]*)$')
  if not stops then return end
  -- A tow under the red flag waiting for the restart (decision 270)
  local rtTow, rtP, rtS, rtB = tostring(redTow or ''):match('^(%d+)/([%d%.]+)/([%d%.]+)/([%d%.]+)$')
  if rtTow and not state.redTow then
    state.redTow = { tow = tonumber(rtTow), damage = { powertrain = tonumber(rtP), suspension = tonumber(rtS),
      body = tonumber(rtB) } }
  end
  -- A new connection in the same pit pass (driver swap, crash): a service already done in it counts (decision 161)
  if newConnection and serviced == '1' then state.pitPassServiced = true end
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

-- Session start or script reload. A new session or a restart within the running script (fresh, decision 275): nothing
-- of the run before (a restart soon after the start has the same record key: session start within its tolerance); the
-- record starts again with a version over any kept by the other drivers (server seconds), so theirs are not taken back
function PitRecord.load(fresh)
  PitRecord.stops, PitRecord.last, PitRecord.seq = 0, '-', 0
  if fresh then
    PitRecord.seq = math.floor(serverTimeMs() / 1000)
    PitRecord.save()
    ac.log('race-control: pit record of the session before not carried over')
    return
  end
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
-- ============================================================
-- Dictionary (decision 214): the one place of the texts that come from outside the script (KMR, ACSM, the race
-- direction), by source and theme; no other module keeps a term of its own. Each term by language: en, pt (the KMR sends
-- each driver the message in the driver's language: KMR language files v1.6f, language/en.json and pt.json; the ACSM,
-- race_control.go, writes English only). Lower case and no accents, as the KMR writes them; no bare "DT", so names and
-- other words are not caught. Another language later = one more key (xx = { ... }) in each entry. At the load each
-- entry becomes one list with every language. Words: plain text (hasAny); patterns: Lua patterns, a capture where a
-- value is read (DICT.match)
-- ============================================================
local DICT
do
  -- A number of the KMR money (the safety rating): sign, digits, thousands comma, decimals; a unit before it is skipped
  local N = '[^%d%-%+%s]*([%-%+]?%d[%d,]*%.?%d*)'
  DICT = {
    -- 1. Race direction: flags and CODE-80 (KMR, ACSM, the race direction)
    flags = {
      green = { en = { 'green flag' }, pt = { 'bandeira verde' } },           -- end of CODE-80; checked first
      vsc = { en = { 'virtual safety car' }, pt = { 'safety car virtual' } }, -- plus the whole word "vsc"
      sc = { en = { 'safety car' } },                                         -- checked after VSC
      code80 = { en = { 'code-80', 'code 80', 'full course yellow' },
        pt = { 'código-80', 'codigo-80', 'código 80', 'codigo 80' } },
      -- With VSC: end of CODE-80 (KMR virtual_safety_car_ended: "Virtual Safety Car ended!", "... terminado!")
      ended = { en = { 'ended' }, pt = { 'terminado' } },
      rolling = { en = { 'rolling start', 'formation lap' }, pt = { 'largada em movimento', 'volta de formacao' } },
    },
    -- 2. KMR
    kmr = {
      -- 2.1 Penalty and drive-through
      penalty = { en = { 'penalty' }, pt = { 'penalidade' } },
      driveThrough = { en = { 'drive-through', 'drive through', 'drivethrough', 'stop and go', 'stop-and-go', 'stop & go' } },
      -- Deadline of the drive-through (penalty_drive_through_*): next race, this lap, within n laps (pattern)
      nextRace = { en = { 'next race' }, pt = { 'proxima corrida' } },
      thisLap = { en = { 'this lap' }, pt = { 'desta volta' } },
      withinLaps = { en = { 'within (%d+) lap' }, pt = { 'dentro de no maximo (%d+)' } },
      -- Reason of the drive-through (for_* entries) -> category (TEXTS.kmrReasons), in this order
      reasons = {
        { 'K1', en = { 'crossing the pit exit line' }, pt = { 'por cruzar o pitlane na pista' } },
        { 'K2', en = { 'pit lane speeding' }, pt = { 'excesso de velocidade no pit lane' } },
        { 'K3', en = { 'reaching the infraction limit' }, pt = { 'atingir o limite de infracoes' } },
        { 'K4', en = { 'colliding with a car that was lapping you' }, pt = { 'estava lhe aplicando uma volta' } },
        { 'K5', en = { 'colliding with a car in the hotlap' }, pt = { 'colidir com um carro em volta rapida' } },
        { 'K6', en = { 'disturbing another driver hotlap' }, pt = { 'atrapalhar a volta rapida' } },
        { 'K7', en = { 'driving in reverse gear' }, pt = { 'pilotar em marcha re' } },
        { 'K8', en = { 'parking the car in proximity of the track' }, pt = { 'parar o carro nas proximidades da pista' } },
        { 'K9', en = { 'too many collisions' }, pt = { 'muitas colisoes' } },
        { 'K10', en = { 'speeding during the virtual safety car' },
          pt = { 'excesso de velocidade durante o safety car virtual' } },
        { 'K11', en = { 'slowing down too much during the virtual safety car' },
          pt = { 'lento durante muito tempo no safety car virtual' } },
        { 'K12', en = { 'violating the overtake restriction' }, pt = { 'violar a restricao de ultrapassagem' } },
        { 'K13', en = { 'cutting' }, pt = { 'por cortar' } },
        { 'K14', en = { 'ignoring the blue flags' }, pt = { 'ignorar a bandeira azul' } },
        { 'K15', en = { 'rejoining the track at high speed' }, pt = { 'retornar a pista em alta velocidade' } },
      },
      -- 2.2 Infraction points (money_penalty, "Penalty +1 (3/100): ..."): points and limit (pattern, decision 210)
      points = { en = { '^%s*penalty%s*%+%d+%s*%((%d+)/(%d+)%)' }, pt = { '^%s*penalidade%s*%+%d+%s*%((%d+)/(%d+)%)' } },
      -- 2.2a Driving stats of the driver (welcome_driving_stats, kmr_stats_output_1, welcome_winning_stats): crashes and
      -- driving infractions, each with its rate per 100 km (decision 278)
      crashes = { en = { 'crashes: (%d+) %(per 100km: ([%d%.]+)', 'crashes: (%d+) %(crashes per 100km: ([%d%.]+)' },
        pt = { 'acidentes: (%d+) %(per 100km: ([%d%.]+)', 'batidas: (%d+) %(batidas por 100km: ([%d%.]+)' } },
      infractions = { en = { 'driving infractions: (%d+) %(per 100km: ([%d%.]+)' },
        pt = { 'infrações de pilotagem: (%d+) %(per 100km: ([%d%.]+)', 'infracoes de pilotagem: (%d+) %(per 100km: ([%d%.]+)' } },
      -- 2.3 Safety rating (the KMR money; decision 215). The balance after the message (patterns): welcome_money,
      -- kmr_money_output, money_penalty, damage_*_notification, towing_cost, race_entry_fee, qualify_top_3_prize,
      -- all_times_fastest_lap_prize, session_balance_overview
      ratingNow = { en = { 'you now have ' .. N, 'you have ' .. N .. '%S* in your account' },
        pt = { 'voce agora possui ' .. N, 'agora voce possui ' .. N, 'voce possui ' .. N .. '%S* na sua conta' } },
      -- Amount added with no balance in the message (patterns): race_pay, race_fastest_lap_prize,
      -- race_clean_gain_reward, laptime_challenge_reward
      ratingAdded = { en = { 'you have been paid ' .. N, 'paid you additional ' .. N, 'you earned ' .. N },
        pt = { 'voce foi pago ' .. N, 'pagaram um adicional de ' .. N, 'voce ganhou ' .. N } },
      -- The race director's points or money penalty (race_control_*_money_penalty, *_points_penalty): sent to everyone
      -- with the driver's name and no balance (decision 221)
      directorPenalty = { en = { 'money penalty', 'points penalty', 'point penalty' },
        pt = { 'penalidade em dinheiro', 'penalidade de pontos', 'pontos de penalidade', 'dinheiro de penalidade' } },
    },
    -- 3. Areas of the server messages (decision 227): the driver chooses which ones the message window shows. Checked in
    -- this order; a message of no area from the server is the race direction's free text (always shown)
    areas = {
      { 'limits', en = { 'laptime invalidated', 'do not improve your laptime' },
        pt = { 'tempo de volta invalidado', 'nao melhorou seu tempo' } },
      { 'damage', en = { 'for the damage on your car', 'first collisions of the race', 'were involved in a collision' },
        pt = { 'pelo dano no seu carro', 'primeira colisao da corrida', 'foram envolvidos em uma colisao' } },
      { 'rc', en = { 'penalties have been cleared', 'drive-through aborted', 'you must clear the drive-through',
          'left to take your drive-through', 'pass through pits', 'rolling start', 'max speed:', 'do not overtake before',
          'you might overtake', 'speed limit off', 'green flag' },
        pt = { 'penalidades foram cumpridas', 'drive-through abortado', 'voce deve cumprir o drive-through',
          'restantes para cumprir seu drive-through', 'passagem pelos pits', 'largada em movimento', 'velocidade maxima:',
          'nao ultrapassar antes', 'voce pode ultrapassar', 'limitador de velocidade desligado', 'bandeira verde' } },
      { 'results', en = { 'race over', 'start pos:', 'did not qualify', 'won the race', ' is 2nd', ' is 3rd',
          'is in pole position', 'set the fastest lap', 'collected a total competition prize', 'new personal best',
          'drivers are required to race', 'there is no prize' },
        pt = { 'fim da corrida', 'posicao inicial', 'nao se qualificou', 'venceu a corrida', ' e o 2', ' e o 3',
          'esta na pole position', 'fez a volta mais rapida', 'fez a melhor volta de todos os tempos',
          'coletou um total de premios', 'novo recorde pessoal', 'pilotos sao necessarios', 'nao ha premios' } },
      { 'welcome', en = { 'driven distance', 'your personal best', 'you are level', 'wins:', 'for a list of available commands',
          'live race control running', 'available commands', 'best times for', 'language changed', 'available languages',
          'no times recorded', 'you haven\'t set a time', 'no stats to show', 'the next track is', 'driving notifications' },
        pt = { 'distancia pilotada', 'seu recorde pessoal', 'voce esta no nivel', 'podios:', 'para a lista de comandos',
          'direcao de prova ativa em', 'comandos disponiveis', 'melhor tempo para', 'idioma modificado', 'idiomas disponiveis',
          'nao ha tempos registrados', 'voce nao registrou tempo', 'sem status para mostrar', 'a proxima pista sera',
          'notificacoes de pilotagem' } },
      { 'admin', en = { 'is now banned for', 'the track will rotate', 'voted to change the track', 'track change vote',
          'has won the vote', 'logged in as kissmyrank admin', 'kicked ' },
        pt = { 'esta banido por', 'a pista ira modificar', 'votou para modificar a pista', 'votacao para troca de pista',
          'venceu a votacao', 'logado como kissmyrank admin', 'removido ' } },
      -- Actions of the race director (race_control_*): about this driver = Race Control; about another = others
      { 'director', en = { 'race control:' }, pt = { 'direcao de prova:' } },
      { 'warnings', en = { 'being lapped', 'make room for', 'overtaking is not permitted', 'do not speed over',
          'do not slow down under', 'you can\'t stop here', 'ping is too high', 'times do not match', 'warning' },
        pt = { 'tomando uma volta', 'abra espaco', 'ultrapassagens nao sao permitidas', 'nao exceda a velocidade',
          'nao ande abaixo', 'voce nao pode parar aqui', 'ping esta muito alto', 'relogio nao esta', 'alerta', 'atencao' } },
    },
    -- 3A. Rolling start of the KMR (start/start_control.lua; en.json and pt.json lines 13 to 17, 88, 96, 98, 122, 129,
    -- 133; the Portuguese texts with accents are matched by a part without them). Patterns where a value is read
    start = {
      rules = { en = { 'rolling start. formation lap rules' }, pt = { 'regras da volta de forma' } },
      speed = { en = { '%- max speed: ([%d%.]+)[^,]*, min speed: ([%d%.]+)' },
        pt = { '%- velocidade maxima: ([%d%.]+)[^,]*, velocidade minima: ([%d%.]+)' } },
      far = { en = { 'car ahead is farther than ([%d%.]+)' }, pt = { 'mais longe do que ([%d%.]+)' } },
      slowFar = { en = { 'is ahead farther than ([%d%.]+)[^%d]+slower than ([%d%.]+)' },
        pt = { 'frente do que ([%d%.]+)[^%d]+lento do que ([%d%.]+)' } },
      noOvertake = { en = { 'do not overtake before the green flag' }, pt = { 'nao ultrapassar antes do sinal' } },
      formation = { en = { 'formation lap starts' }, pt = { 'volta de formacao iniciada' } },
      release = { en = { 'race starts when the leader crosses' }, pt = { 'a corrida inicia quando o lider' } },
      go = { en = { 'race start! go go go' }, pt = { 'corrida iniciada! go go go' } },
      giveBack = { en = { 'overtaking is not permitted right now' }, pt = { 'ultrapassagens nao sao permitidas neste momento' } },
      warning = { en = { 'during the formation lap' }, pt = { 'durante a volta de formacao' } },
    },
    -- 4. ACSM driver swap (race_control.go, handleDriverSwap; English only)
    acsm = {
      swapWait = { en = { 'please wait (%S+) before leaving the pits', '^free to leave pits in (%S+)' } },   -- patterns
      swapClear = { en = { 'you are clear to leave the pits' } },
      swapEarly = { en = { 'during a driver swap' } },
      kicked = { en = { 'kicked' } },
    },
  }
  -- Each entry: one list with every language (en first); the reasons keep their category in [1]
  local LANGS = { 'en', 'pt' }
  local function merge(t)
    local out = {}
    if t[1] then out[1] = t[1] end
    for _, l in ipairs(LANGS) do
      for _, w in ipairs(t[l] or {}) do out[#out + 1] = w end
    end
    return out
  end
  local function walk(t)
    for k, v in pairs(t) do
      if type(v) == 'table' then
        if v.en or v.pt then t[k] = merge(v) else walk(v) end
      end
    end
  end
  walk(DICT)
  -- Reasons and areas: { id, word, word, ... } -> { cat / id, words }
  for i, r in ipairs(DICT.kmr.reasons) do
    local words = {}
    for j = 2, #r do words[#words + 1] = r[j] end
    DICT.kmr.reasons[i] = { cat = r[1], words = words }
  end
  for i, r in ipairs(DICT.areas) do
    local words = {}
    for j = 2, #r do words[#words + 1] = r[j] end
    DICT.areas[i] = { id = r[1], words = words }
  end
  -- Area of a KMR message (lower case), or nil
  function DICT.area(low)
    for _, a in ipairs(DICT.areas) do
      for _, w in ipairs(a.words) do
        if low:find(w, 1, true) then return a.id end
      end
    end
    return nil
  end
  -- The captures of the first pattern of the list that matches the text (lower case), or nil
  function DICT.match(text, patterns)
    for _, p in ipairs(patterns) do
      local a, b = text:match(p)
      if a then return a, b end
    end
    return nil
  end
end

-- Kinds that start CODE-80
-- Actions of the Race Control commands (penalties/commands.lua), for a command with a prefix of the server
DICT.rcActions = { REDFLAG = true, RELAX = true, UNLOCK = true, DT = true, HOLD = true, TELEPORT = true, DSQ = true,
  LOCK = true, FUEL = true }
DICT.code80Kinds = { VSC = true, SC = true, ['CODE-80'] = true }

local function hasAny(text, words)
  for _, word in ipairs(words) do
    if text:find(word, 1, true) then return true end
  end
  return false
end

-- Another connected driver named in the message
local function namesAnother(message)
  for i = 1, (sim.carsCount or 1) - 1 do
    local c = ac.getCar(i)
    local n = c and c.isConnected and ac.getDriverName(i)
    if n and n ~= '' and message:find(n, 1, true) then return true end
  end
  return false
end

-- Classifies a server message: 'GREEN FLAG', 'VSC', 'SC', 'CODE-80', 'ROLLING START', 'DT' or nil. DT: a drive-through
-- that names this driver, or a drive-through penalty sent to this car without a name (the KMR message in the game chat
-- has no name: "drive-through penalty to clear during the next race for ..."; the name is only in the KMR log), as long
-- as it names no other connected driver
local function classifyServerMessage(message)
  local low = message:lower()
  local F = DICT.flags
  if hasAny(low, F.green) then return 'GREEN FLAG' end
  local isVSC = low:find('%f[%w]vsc%f[%W]') or hasAny(low, F.vsc)
  if isVSC and hasAny(low, F.ended) then return 'GREEN FLAG' end
  if isVSC then return 'VSC' end
  if hasAny(low, F.sc) then return 'SC' end
  if hasAny(low, F.code80) then return 'CODE-80' end
  if hasAny(low, F.rolling) then return 'ROLLING START' end
  local name = tostring(ac.getDriverName(0) or '')
  if hasAny(low, DICT.kmr.driveThrough) then
    if name ~= '' and message:find(name, 1, true) then return 'DT' end
    -- "Other Name: ..." is the KMR line of another driver (also after that driver left); "Penalty: ..." and
    -- "Penalidade: ..." are the KMR messages to this car (en.json / pt.json)
    local head = message:match('^%s*([^:]+):%s')
    if head and hasAny(head:lower(), DICT.kmr.penalty) then head = nil end
    if hasAny(low, DICT.kmr.penalty) and not head and not namesAnother(message) then
      return 'DT'
    end
  end
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
-- Body: <VSC|SC|CODE-80|GREEN>|<server time of the change, ms>|<RED or ->|<reason of the red flag>
-- The red flag (decision 196) goes in the same record: who enters during it gets it from the other drivers
-- ============================================================

local TrackList = {
  since = -1,   -- server time (ms) of the change in force; -1 = nothing known
}

-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  local function trackBody()
    local red = state.redFlag
    return string.format('%s|%d|%s|%s', state.code80 or 'GREEN', math.floor(TrackList.since), red and 'RED' or '-',
      red and red.reason and (red.reason:gsub('[|\r\n]', ' ')) or '')
  end

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
    local kind, since, red, reason = tostring(body):match('^([%w%-]+)|(%d+)|?([%w%-]*)|?(.*)$')
    since = tonumber(since)
    if not since or since <= TrackList.since then return false end
    local code80 = kind ~= 'GREEN' and kind or nil
    if code80 and not DICT.code80Kinds[code80] then return false end
    if state.code80 and not code80 then state.code80Ended = true end
    if code80 and not state.code80 then ac.log('race-control: CODE-80 start (' .. code80 .. ', ' .. source .. ')') end
    if not code80 and state.code80 then ac.log('race-control: CODE-80 end (' .. source .. ')') end
    state.code80 = code80
    if (red == 'RED') ~= (state.redFlag ~= nil) then
      ac.log('race-control: red flag ' .. (red == 'RED' and 'on' or 'off') .. ' (' .. source .. ')')
    end
    state.redFlag = red == 'RED' and { reason = reason ~= '' and reason or nil } or nil
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
-- ACSM driver swap messages to the driver taking the car (race_control.go, handleDriverSwap; texts in DICT.acsm).
-- Returns true if handled.
local function onDriverSwapMessage(message)
  local low = message:lower()
  local A = DICT.acsm
  local wait = DICT.match(low, A.swapWait)
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
  if hasAny(low, A.swapClear) then
    state.swap.remaining = nil
    state.swap.clearUntil = state.ui.clock + SERVER_NOTICE_SECONDS
    return true
  end
  if hasAny(low, A.swapEarly) then
    -- ACSM penalty for leaving the pits early (time penalty, or kick = DSQ by the ACSM): shown in the penalty message box
    -- and kept in the log; applied by the ACSM, not by this script
    state.swap.remaining = nil
    showNotice(TEXTS.rcTitle, message, nil, SERVER_NOTICE_SECONDS)
    local kicked = hasAny(low, A.kicked)
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

-- Swap record of the car: <swaps>|<valid swaps>|<swap number of the driver in command>|<name code of that driver>|
-- <valid swaps taken back: a service in the same pit stop, decision 161>
local SwapRecord = {}
function SwapRecord.save()
  local sw = state.swap
  Record.save('swap', math.floor(serverTimeMs() / 1000), string.format('%d|%d|%d|%d|%d', sw.count, sw.valid, sw.swapNo,
    sw.driver, sw.voids))
end
-- Valid swaps now: valid ones less those taken back
function SwapRecord.validNow()
  local sw = state.swap
  return math.max(sw.valid - sw.voids, 0)
end
-- A swap record (this computer or the other drivers; an old one holds only the swaps): the higher counts win, and the
-- driver in command comes from the record with the most swaps
function SwapRecord.apply(body)
  local sw = state.swap
  local count, valid, swapNo, driver, voids = tostring(body or ''):match('^(%d+)|?(%d*)|?(%d*)|?(%d*)|?(%d*)$')
  if not count then return end
  count = tonumber(count)
  if count >= sw.count then
    sw.swapNo = tonumber(swapNo) or count
    sw.driver = tonumber(driver) or 0
  end
  sw.count = math.max(sw.count, count)
  sw.valid = math.max(sw.valid, tonumber(valid) or count)
  sw.voids = math.max(sw.voids, tonumber(voids) or 0)
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
      -- Published by the driver of another car: kept for the next driver of that car; only from that car (Trust)
      if sender and config.swapOn() and Trust.list(sender, msg.pcCar) then
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

-- ============================================================
-- Audit (decision 209): the server messages taken off the chat (KMR, ACSM: with the chat minimized the CSP shows them on
-- top of the screen) are kept here, shown for a few seconds in our message window under the panel and listed in the
-- Audit screen (gear of the panel). Kept on this computer for the session (ac.storage), so a crash does not lose them.
-- KMR points (decision 210): the KMR message of an infraction ("Penalty +1 (3/100): ... You now have 21p.",
-- Portuguese "Penalidade +1 (3/100): ..."; KMR language file, money_penalty) gives the driver's infraction points
-- before the bar; the limit is the key kmrPoints (limit:100); a limit in the message that differs goes to the log.
-- KMR safety rating (decision 215): the KMR money, used as the safety rating of the driver. Every KMR message with the
-- balance gives it (the welcome message at the entry, damage, tow, entry fee, prizes, the infraction); a reward with
-- no balance adds its amount (texts in DICT.kmr). At or under the key kmrRating (dsqAt:0) it is a DSQ (KmrDT).
-- Both kept per driver in the car record 'kmr' on this computer: back after a crash; another driver starts at '-'.
-- ============================================================

local Audit = { items = {}, window = {}, open = false, scroll = 0, points = nil, pointsDriver = nil, rating = nil,
  ratingSeq = 0 }
do
  local MAX_ITEMS = 200
  local STORAGE_KEY = 'rc.audit'

  local function save()
    local lines = { Record.key() }
    for _, it in ipairs(Audit.items) do
      lines[#lines + 1] = string.format('%d|%s|%s', math.floor(it.t), it.src, (it.text:gsub('[\r\n]', ' ')))
    end
    ac.storage[STORAGE_KEY] = table.concat(lines, '\n')
  end

  -- Session start or reload: the messages of this session on this computer
  function Audit.load()
    Audit.items, Audit.window, Audit.scroll = {}, {}, 0
    local text = tostring(ac.storage[STORAGE_KEY] or '')
    local first = true
    for line in text:gmatch('[^\n]+') do
      if first then
        first = false
        if not Record.sameRace(line, Record.key()) then break end
      else
        local t, src, msg = line:match('^(%-?%d+)|(%w+)|(.*)$')
        if t then Audit.items[#Audit.items + 1] = { t = tonumber(t), src = src, text = msg } end
      end
    end
    -- KMR points and safety rating of the driver in the car (driver|points|rating, '-' = not known)
    local body = Record.load('kmr')
    local driver, points, rating = tostring(body or ''):match('^(%d+)|([^|]*)|?([^|]*)$')
    local me = nameCode(ac.getDriverName(0))
    if driver and tonumber(driver) == me then
      Audit.points, Audit.rating, Audit.pointsDriver = tonumber(points), tonumber(rating), me
    else
      Audit.points, Audit.rating, Audit.pointsDriver = nil, nil, nil
    end
    Audit.ratingSeq = Audit.ratingSeq + 1
  end

  local function kmrSave()
    Audit.pointsDriver = nameCode(ac.getDriverName(0))
    Record.save('kmr', math.floor(serverTimeMs()), string.format('%d|%s|%s', Audit.pointsDriver,
      Audit.points and tostring(Audit.points) or '-', Audit.rating and Audit.num(Audit.rating) or '-'))
  end

  -- A number of the KMR as the KMR writes it: whole, or with its decimals
  function Audit.num(v)
    return (v == math.floor(v)) and string.format('%d', v) or (string.format('%.2f', v):gsub('0+$', ''))
  end

  -- Areas the driver sees in the message window (decision 227): set by the settings (later in the script); the Race
  -- Control area ('rc') always
  Audit.allow = function(area) return true end

  -- A message taken off the chat: kept; shown in the message window for a few seconds only when no other part of our
  -- screen shows it (window = true: the KMR points; the drive-through and the flags are already in the panel) and its
  -- area is one the driver chose
  function Audit.add(src, text, window, area)
    -- An empty line (the server sends them: finding 4 of 29-30/09) is nothing
    if tostring(text or ''):match('^%s*$') then return end
    Audit.items[#Audit.items + 1] = { t = serverTimeMs(), src = src, text = tostring(text), area = area }
    if #Audit.items > MAX_ITEMS then table.remove(Audit.items, 1) end
    -- The newest takes the window at once (finding 12 of 29-30/09: one after the other came late); all stay in the Audit.
    -- What belongs to the race control (area 'rc': the race direction, penalties, start) is not shown in the MESSAGES
    -- window but on the Race Control panel (order of 30/09)
    if window and (area == nil or area == 'rc') then
      showNotice(TEXTS.rcTitle, tostring(text), nil, SERVER_NOTICE_SECONDS)
    elseif window and Audit.allow(area) then
      Audit.window = { { src = src, text = tostring(text) } }
    end
    ac.log('race-control: audit ' .. src .. ': ' .. tostring(text))
    save()
  end

  -- The message of the window now (one at a time, each screens.messageSeconds, in order)
  function Audit.current()
    local w = Audit.window[1]
    if not w then return nil end
    w.untilT = w.untilT or (state.ui.clock + config.screens.messageSeconds)
    if state.ui.clock >= w.untilT then
      table.remove(Audit.window, 1)
      return Audit.current()
    end
    return w
  end

  -- The KMR limit of infraction points reached: the KMR gives its drive-through ("for reaching the infraction limit")
  -- and starts the points again from zero (decision 247)
  function Audit.kmrPointsReset()
    Audit.points = 0
    kmrSave()
    ac.log('race-control: KMR infraction limit reached: points back to 0')
  end

  -- KMR infraction message: points of this driver (the number before the bar), limit checked against the key
  function Audit.kmrPoints(message)
    local points, limit = DICT.match(tostring(message):lower(), DICT.kmr.points)
    if not points then return false end
    Audit.askPending = true
    Audit.points = tonumber(points)
    kmrSave()
    if tonumber(limit) ~= config.kmrPoints.limit then
      ac.log(string.format('race-control: KMR limit in the message %s differs from the key kmrPoints (%d)', limit,
        config.kmrPoints.limit))
    end
    return true
  end

  -- KMR message with the safety rating of this driver: the balance after it, or a reward added to the balance known
  function Audit.kmrRating(message)
    local low = tostring(message):lower()
    local now = DICT.match(low, DICT.kmr.ratingNow)
    local added = not now and DICT.match(low, DICT.kmr.ratingAdded)
    local v = tonumber((tostring(now or added or ''):gsub(',', '')))
    if not v then return false end
    if added then
      if Audit.rating == nil then
        ac.log('race-control: KMR reward with no balance known: ' .. message)
        return true
      end
      v = Audit.rating + v
    end
    Audit.rating = v
    Audit.ratingSeq = Audit.ratingSeq + 1
    kmrSave()
    ac.log('race-control: KMR safety rating ' .. Audit.num(v))
    return true
  end

  -- KMR driving stats of this driver (decision 278): crashes and driving infractions with their rate per 100 km, from
  -- the welcome lines and the answer of "kmr stats". Returns true for a line the script asked (not shown)
  function Audit.kmrStats(message)
    local low = tostring(message):lower()
    local c, cr = DICT.match(low, DICT.kmr.crashes)
    local i, ir = DICT.match(low, DICT.kmr.infractions)
    if c then Audit.crashes, Audit.crashRate = tonumber(c), tonumber(cr) end
    if i then Audit.infractions, Audit.infractionRate = tonumber(i), tonumber(ir) end
    if c or i then ac.log('race-control: KMR driving stats: ' .. message) end
    -- Only the answer of "kmr stats" (kmr_stats_output_1: "crashes per 100km"), not the welcome line
    local answer = low:find('crashes per 100km', 1, true) or low:find('batidas por 100km', 1, true)
    return (c ~= nil) and answer ~= nil and state.ui.clock < (Audit.askedUntil or 0)
  end

  -- The numbers asked to the KMR by the client of the driver (order of 30/09: "É PARA DAR UM COMANDO E RECUPERAR"): the
  -- player commands "kmr stats" (crashes, per 100 km) and "kmr money" (the safety rating), once a lap and after each
  -- infraction or crash (ASK_GAP seconds apart at least); their answers are read and not shown
  local ASK_GAP = 8
  local askedT = -1e9
  Audit.askPending = false
  ac.onCarCollision(0, function() Audit.askPending = true end)
  -- The answer of "kmr money" (kmr_money_output: "You now have X (rank: N)."), not the other money lines
  function Audit.kmrMoneyAnswer(message)
    local low = tostring(message):lower()
    return state.ui.clock < (Audit.askedUntil or 0) and low:find('%(rank:') ~= nil
      and (low:match('^%s*you now have') ~= nil or low:match('^%s*voce agora possui') ~= nil or low:match('^%s*você agora possui') ~= nil)
  end
  function Audit.kmrAsk()
    if not Audit.askPending or state.ui.clock - askedT < ASK_GAP then return end
    Audit.askPending = false
    askedT = state.ui.clock
    Audit.askedUntil = state.ui.clock + ASK_GAP
    queueCommand('/kmr stats')
    queueCommand('/kmr money')
  end

  -- The KMR numbers of each driver for the race direction (decision 278): every client sends its own (points, safety
  -- rating, crashes and infractions per 100 km) on a change and again every KMR_RESEND seconds (who connects later);
  -- the race direction window shows them under each car. Unknown: -1
  local KMR_RESEND = 20
  Audit.others = {}
  local sentText, sentT = nil, -1e9
  local sendKmr = ac.OnlineEvent({
    ac.StructItem.key('12hcuritiba.race-control.kmrstats'),
    kPoints = ac.StructItem.int16(), kRating = ac.StructItem.int32(), kCrashes = ac.StructItem.int16(),
    kCrashRate = ac.StructItem.int16(), kInfr = ac.StructItem.int16(), kInfrRate = ac.StructItem.int16(),
  }, function(sender, msg)
    if not sender or sender.index == 0 then return end
    local function v(x) x = tonumber(x) or -1; return x >= 0 and x or nil end
    Audit.others[sender.index] = { points = v(msg.kPoints), rating = tonumber(msg.kRating) ~= -2147483647
      and tonumber(msg.kRating) or nil, crashes = v(msg.kCrashes), crashRate = v(msg.kCrashRate) and v(msg.kCrashRate) / 100,
      infractions = v(msg.kInfr), infractionRate = v(msg.kInfrRate) and v(msg.kInfrRate) / 100, t = state.ui.clock }
  end, nil, nil, { processPostponed = true })
  -- The numbers of a car: this one, or what its client sent
  function Audit.kmrOf(i)
    if i == 0 then
      return { points = Audit.points, rating = Audit.rating, crashes = Audit.crashes, crashRate = Audit.crashRate,
        infractions = Audit.infractions, infractionRate = Audit.infractionRate }
    end
    return Audit.others[i]
  end
  function Audit.kmrSend()
    if Audit.points == nil and Audit.rating == nil and Audit.crashes == nil and Audit.infractions == nil then return end
    local function n(x, k) return x and math.floor(x * (k or 1) + 0.5) or -1 end
    local data = { kPoints = n(Audit.points), kRating = Audit.rating and math.floor(Audit.rating) or -2147483647,
      kCrashes = n(Audit.crashes), kCrashRate = n(Audit.crashRate, 100), kInfr = n(Audit.infractions),
      kInfrRate = n(Audit.infractionRate, 100) }
    local text = table.concat({ data.kPoints, data.kRating, data.kCrashes, data.kCrashRate, data.kInfr, data.kInfrRate }, '|')
    if text == sentText and state.ui.clock - sentT < KMR_RESEND then return end
    sentText, sentT = text, state.ui.clock
    OnlineQueue.push(sendKmr, data, nil)
  end
end
-- ============================================================
-- Detector of the car changes nobody asked for (finding 8 of 29-30/09: lights, pit limiter, ignition and camera
-- changing by themselves). Every frame it watches the car of this driver: headlights, low beams, hazard lights, pit
-- limiter, engine running, reverse gear, camera. Each change is shown at once in the message window (area
-- Diagnostics) and kept in the Audit, with every input held or pressed in the last second (button and D-pad of each
-- device by its name, gamepad, key) and every action of this script on the car in the same second (controls locked,
-- camera forced, penalty, teleport, reset). The same line goes to the server log ([RC], Diagnostic), so the test
-- machine is not needed. The script's actions are seen by wrapping those SDK functions once, here, before any use.
-- ============================================================

local Diag = { inputs = {}, acts = {}, last = nil }
do
  local WINDOW = 1.0              -- seconds: inputs and actions counted before a change
  local held = {}                 -- input held in the frame before: name = true

  -- The script's own actions on the car
  local function act(text)
    Diag.acts[#Diag.acts + 1] = { t = state.ui.clock, text = text }
    if #Diag.acts > 40 then table.remove(Diag.acts, 1) end
  end
  local function wrap(tbl, name, describe)
    local f = tbl and tbl[name]
    if type(f) ~= 'function' then return end
    pcall(function()
      tbl[name] = function(...)
        local ok, text = pcall(describe, ...)
        if ok and text then act(text) end
        return f(...)
      end
    end)
  end
  wrap(physics, 'lockUserControlsFor', function(t) return string.format('controls locked %.0f s', tonumber(t) or 0) end)
  wrap(physics, 'setCarPenalty', function(p, v) return 'game penalty ' .. tostring(p) .. '/' .. tostring(v) end)
  wrap(physics, 'teleportCarTo', function() return 'teleport to the pits' end)
  wrap(physics, 'resetCarState', function() return 'car state reset' end)
  wrap(ac, 'setCurrentCamera', function(mode)
    if sim.cameraMode ~= mode then return 'camera forced to cockpit (key forceCockpit)' end
  end)
  wrap(ac, 'disableQuickMenuPitstop', function(v) return 'AC quick pit menu ' .. (v == false and 'on' or 'off') end)

  -- Names of the inputs
  local KEY_NAMES = { [8] = 'Backspace', [9] = 'Tab', [13] = 'Enter', [16] = 'Shift', [17] = 'Ctrl', [18] = 'Alt',
    [27] = 'Esc', [32] = 'Space', [37] = 'Left arrow', [38] = 'Up arrow', [39] = 'Right arrow', [40] = 'Down arrow',
    [160] = 'Left Shift', [161] = 'Right Shift', [162] = 'Left Ctrl', [163] = 'Right Ctrl', [164] = 'Left Alt',
    [165] = 'Right Alt' }
  local function keyName(k)
    if KEY_NAMES[k] then return KEY_NAMES[k] end
    if (k >= 48 and k <= 57) or (k >= 65 and k <= 90) then return string.char(k) end
    if k >= 112 and k <= 123 then return 'F' .. (k - 111) end
    return string.format('key 0x%02X', k)
  end
  local PAD_NAMES = {}
  for n, id in pairs(ac.GamepadButton or {}) do PAD_NAMES[id] = n end

  -- Every input held now: name = true
  local function readInputs()
    local out = {}
    if ac.getJoystickCount then
      for j = 0, ac.getJoystickCount() - 1 do
        local dev = tostring(ac.getJoystickName and ac.getJoystickName(j) or ('device ' .. j))
        for b = 0, (ac.getJoystickButtonsCount and ac.getJoystickButtonsCount(j) or 0) - 1 do
          if ac.isJoystickButtonPressed(j, b) then out[dev .. ' button ' .. (b + 1)] = true end
        end
        for pv = 0, (ac.getJoystickDpadsCount and ac.getJoystickDpadsCount(j) or 0) - 1 do
          local v = ac.getJoystickDpadValue(j, pv)
          if v and v >= 0 then out[string.format('%s D-pad %d at %d deg', dev, pv + 1, v / 100)] = true end
        end
      end
    end
    if ac.isGamepadButtonPressed then
      for pad = 0, 3 do
        for id, n in pairs(PAD_NAMES) do
          if ac.isGamepadButtonPressed(pad, id) then out['gamepad ' .. (pad + 1) .. ' ' .. n] = true end
        end
      end
    end
    for k = 8, 254 do if ac.isKeyDown(k) then out['key ' .. keyName(k)] = true end end
    return out
  end

  -- The car now: what is watched, as text
  local function read(car)
    return {
      headlights = car.headlightsActive and 'on' or 'off',
      lowBeams = car.lowBeams and 'on' or 'off',
      hazard = car.hazardLights and 'on' or 'off',
      limiter = car.manualPitsSpeedLimiterEnabled and 'on' or 'off',
      engine = CarRead.num(car.rpm) > 100 and 'running' or 'off',
      reverse = CarRead.num(car.gear) == -1 and 'R' or 'not R',
      camera = tostring(sim.cameraMode) .. ((ac.CameraMode and sim.cameraMode == ac.CameraMode.Car) and ('/' .. tostring(sim.carCameraIndex)) or ''),
    }
  end
  local LABEL = { headlights = 'Headlights', lowBeams = 'Low beams', hazard = 'Hazard lights', limiter = 'Pit limiter',
    engine = 'Engine', reverse = 'Gear', camera = 'Camera' }
  local ORDER = { 'headlights', 'lowBeams', 'hazard', 'limiter', 'engine', 'reverse', 'camera' }

  function Diag.update(car)
    local clock = state.ui.clock
    -- Inputs: a press (down now, not before) is kept for WINDOW seconds; the ones held count too
    local now = readInputs()
    for name in pairs(now) do
      if not held[name] then Diag.inputs[#Diag.inputs + 1] = { t = clock, name = name } end
    end
    held = now
    while Diag.inputs[1] and clock - Diag.inputs[1].t > WINDOW do table.remove(Diag.inputs, 1) end
    local cur = read(car)
    local before = Diag.last
    Diag.last = cur
    if not before or sim.isReplayActive then return end
    for _, k in ipairs(ORDER) do
      if cur[k] ~= before[k] then
        local ins, seen = {}, {}
        for name in pairs(now) do seen[name] = true; ins[#ins + 1] = name end
        for _, p in ipairs(Diag.inputs) do if not seen[p.name] then seen[p.name] = true; ins[#ins + 1] = p.name end end
        local acts = {}
        for _, a in ipairs(Diag.acts) do if clock - a.t <= WINDOW then acts[#acts + 1] = a.text end end
        table.sort(ins)
        local text = string.format('%s %s -> %s - inputs: %s - Race Control: %s', LABEL[k], before[k], cur[k],
          #ins > 0 and table.concat(ins, ', ') or 'none', #acts > 0 and table.concat(acts, ', ') or 'none')
        Audit.add('DIAG', text, true, 'diag')
        rcLog('Diagnostic', text)
      end
    end
  end
end
-- ============================================================
-- Start control (order of 30/09: a module of its own; decision 234 moved here). Rolling start coordinated by the KMR
-- in the chat (KMR v1.6f, language/en.json and pt.json, readme: "Positions are locked during the formation lap. The
-- race starts when the leader crosses the line"; config rolling_start):
--   rules      "Rolling start. Formation Lap rules:" / "Largada em movimento. Regras da volta de formação:", then the
--              speed limits ("- max speed: %s, min speed: %s") and when a car can be passed ("farther than %s from the
--              previous one"; "ahead farther than %s and slower than %s"): read and kept
--   formation  "Formation Lap starts!" / "Volta de formacao iniciada!": the order of the cars is locked (race position of
--              every car at that moment); each driver sees his place, the car he must stay behind and the one behind him,
--              and an alert when he is ahead of the car he must stay behind (the KMR gives a penalty if the place is not
--              given back, "overtaking is not permitted right now"), unless the KMR allows passing that car
--   release    "Speed limit off. Race starts when the leader crosses the start/finish line."
--   go         "Green flag! Race Start! Go go go!": GREEN FLAG - GO with the five lights green for flags.greenSeconds
-- The panel tells every phase (Race Control message) and the flag box shows it all the time. The track lights: the
-- script tells the track script by a shared event (race-control.start: 'hold' from the rules to the start,
-- 'go' at the start, 'off' otherwise), sent at every change and every 2 s while not 'off'; the track decides what to do with it
-- (panelinfo.ini of the track, START_PROCEDURE). A standing start: nothing here.
-- ============================================================

local Start = { phase = nil, maxKmh = nil, minKmh = nil, farM = nil, slowFarM = nil, slowKmh = nil, locked = {},
  goUntil = 0, sent = 'off', sentT = -1e9 }
do
  local TRACK_EVENT = 'race-control.start'

  function Start.reset()
    Start.phase, Start.locked, Start.goUntil = nil, {}, 0
    Start.maxKmh, Start.minKmh, Start.farM, Start.slowFarM, Start.slowKmh = nil, nil, nil, nil, nil
  end

  local function phaseTo(p, message)
    Start.phase = p
    if p == 'formation' then Start.locked = {} end
    if p == 'go' then Start.goUntil = state.ui.clock + config.flags.greenSeconds end
    ac.log('race-control: rolling start: ' .. p .. ' (' .. tostring(message) .. ')')
    rcLog('Rolling start', p .. ' - ' .. tostring(message))
  end

  -- A message of the KMR about the rolling start (lower case); true = taken (kept in the Audit, on the panel)
  function Start.chat(message)
    local low = message:lower()
    local S = DICT.start
    -- A drive-through or an infraction of the formation lap is a penalty message, not ours
    if hasAny(low, DICT.kmr.penalty) then return false end
    local taken = true
    if hasAny(low, S.rules) then phaseTo('rules', message)
    elseif DICT.match(low, S.speed) then
      local mx, mn = DICT.match(low, S.speed)
      Start.maxKmh, Start.minKmh = tonumber(mx), tonumber(mn)
    elseif DICT.match(low, S.slowFar) then
      local d, v = DICT.match(low, S.slowFar)
      Start.slowFarM, Start.slowKmh = tonumber(d), tonumber(v)
    elseif DICT.match(low, S.far) then Start.farM = tonumber((DICT.match(low, S.far)))
    elseif hasAny(low, S.noOvertake) then -- the rule line itself: kept
    elseif hasAny(low, S.formation) then phaseTo('formation', message)
    elseif hasAny(low, S.release) then phaseTo('release', message)
    elseif hasAny(low, S.go) then phaseTo('go', message)
    elseif hasAny(low, S.giveBack) or hasAny(low, S.warning) then -- warnings of the formation lap: shown
    else taken = false end
    if taken then Audit.add('KMR', message, true, 'rc') end
    return taken
  end

  -- Metres from car b ahead to car a on the track (a behind b), 0 .. track length
  local function gapM(a, b)
    return ((CarRead.num(b.splinePosition) - CarRead.num(a.splinePosition)) % 1) * (tonumber(sim.trackLengthM) or 0)
  end
  local function tag(i) return string.format('#%s', tostring(ac.getDriverNumber(i) or i)) end

  -- The cars in the locked order: index by locked place
  local function byPlace()
    local out = {}
    for i, p in pairs(Start.locked) do out[p] = i end
    return out
  end

  -- Guidance of this car in the formation: line of text, alert (true = give the place back)
  local function guide()
    local me = Start.locked[0]
    if not me then return TEXTS.startNoPlace, false end
    local at = byPlace()
    local ahead, behind = at[me - 1], at[me + 1]
    local my = ac.getCar(0)
    local livePos = function(i) local c = ac.getCar(i); return c and CarRead.num(c.racePosition) or 0 end
    if ahead then
      local a = ac.getCar(ahead)
      if a and livePos(ahead) > livePos(0) then
        -- Ahead of the car I must stay behind: allowed only as the KMR allows it
        local prev = at[me - 2] and ac.getCar(at[me - 2])
        local far = prev and Start.farM and gapM(a, prev) > Start.farM
        local slow = prev and Start.slowFarM and Start.slowKmh and gapM(a, prev) > Start.slowFarM
          and CarRead.num(a.speedKmh) < Start.slowKmh
        if far or slow then return string.format(TEXTS.startPassAllowed, me, tag(ahead)), false end
        return string.format(TEXTS.startGiveBack, tag(ahead)), true
      end
    end
    local line = string.format(TEXTS.startPlace, me, ahead and tag(ahead) or TEXTS.startLeader)
    if behind and livePos(behind) > 0 and livePos(behind) < livePos(0) then
      line = line .. string.format(TEXTS.startPassedBy, tag(behind))
    elseif behind then
      line = line .. string.format(TEXTS.startBehindYou, tag(behind))
    end
    return line, false
  end

  function Start.update(car)
    -- The order is locked once the formation starts (a driver who connects in it locks it at his first frame)
    if (Start.phase == 'formation' or Start.phase == 'release') and next(Start.locked) == nil then
      for i = 0, (sim.carsCount or 1) - 1 do
        local c = ac.getCar(i)
        if c and c.isConnected and CarRead.num(c.racePosition) > 0 then Start.locked[i] = CarRead.num(c.racePosition) end
      end
    end
    if Start.phase == 'go' and state.ui.clock >= Start.goUntil then Start.phase = nil end
    -- The track script (lights): the phase at every change, and every 2 s while it is not 'off' (a track script that
    -- starts later gets it)
    local ev = (Start.phase == 'rules' or Start.phase == 'formation' or Start.phase == 'release') and 'hold'
      or (Start.phase == 'go' and 'go' or 'off')
    if ev ~= Start.sent or (ev ~= 'off' and state.ui.clock - Start.sentT >= 2) then
      Start.sent, Start.sentT = ev, state.ui.clock
      ac.broadcastSharedEvent(TRACK_EVENT, ev)
    end
  end

  -- The flag of the start now for the flag box: { group, kind, title, line1, line2, alert, lights } or nil
  function Start.flag()
    local p = Start.phase
    if p == 'go' then
      return { 5, 'green', TEXTS.flagStart, TEXTS.flagStartLine, '', nil, true }
    end
    if p ~= 'rules' and p ~= 'formation' and p ~= 'release' then return nil end
    local limits = (Start.maxKmh and Start.minKmh) and string.format(TEXTS.startLimits, Start.maxKmh, Start.minKmh)
      or TEXTS.startNoOvertake
    if p == 'release' then limits = TEXTS.startRelease end
    local line, alert = TEXTS.startWaiting, false
    if p ~= 'rules' then line, alert = guide() end
    return { 2, 'start', TEXTS.startTitle, limits, line, alert }
  end
end
-- Chat: Race Control lines are for the server log only, hidden from the chat of every client. Server messages
-- (fromServer: KMR or ACSM) that match the dictionary (DICT, the one place of the outside texts) are also shown in the
-- penalty message box, and the ACSM driver swap messages feed the driver swap panel. Those, the KMR infraction points
-- and the KMR safety rating (every message with the balance) are taken off the chat (decision 209: with the chat
-- minimized the CSP shows the chat on top of the screen): they go to the Audit and to our message window over the
-- panel. Other server messages (free text of the Race Control) stay in the chat, with a line in the log.
-- A message from the server: -1 (SDK: "or -1 if message comes from server"; a broadcast, e.g. VSC), or a sender that
-- is no connected car: a message the server sends to one car (ACSM chat to the driver, udp SendChat; KMR messages to
-- the driver) arrives with no name in the chat. A driver's message always comes from the driver's own car.
local function fromServer(sender)
  if sender == nil or sender < 0 then return true end
  local c = ac.getCar(sender)
  return not c or not c.isConnected
end

ac.onChatMessage(function(message, senderCarIndex)
  if type(message) ~= 'string' then return false end
  local server = fromServer(senderCarIndex)
  -- The empty lines the server sends (every ~20 s, and after each hidden RC line): off the chat, nowhere
  if server and message:match('^%s*$') then return true end
  -- Audit: every chat line about a drive-through or a penalty goes to the server log with the sender the game gives
  -- (the SDK documents only -1 for the server; a KMR message to this car may come another way)
  local low = message:lower()
  if message:sub(1, #TEXTS.rcPrefix) ~= TEXTS.rcPrefix and (hasAny(low, DICT.kmr.driveThrough)
      or hasAny(low, DICT.kmr.penalty)) then
    rcLog('Chat seen', string.format('sender %s - %s', tostring(senderCarIndex), message:sub(1, 90)))
  end
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
  -- Race Control command (RcCommand): only from the server (ACSM live timing, admin; KMR admin_say of the race
  -- direction window); hidden from the chat. ACSM broadcast chat puts "(account name) " before the text; any other short
  -- prefix a server puts is taken too, when an RC action follows it (finding of 30/09)
  local command = server and (message:match('^%s*%b()%s*([Rr][Cc]%s.*)$') or message:match('^%s*([Rr][Cc]%s.*)$'))
  if server and not command then
    local at = message:find('%f[%w][Rr][Cc]%s+%a')
    local cand = at and at <= 40 and message:sub(at)
    local action = cand and cand:match('^[Rr][Cc]%s+(%a+)')
    if action and DICT.rcActions[action:upper()] then command = cand end
  end
  if command then
    ac.log(string.format('race-control: command received (sender %s): %s [raw: %s]', tostring(senderCarIndex), command,
      message))
    state.rcCommands[#state.rcCommands + 1] = command
    return true
  end
  -- KMR drive-through to this driver: from the server, or with this car as the sender (the SDK documents only -1 for
  -- the server; a message the server sends to one car may carry that car). Taking it from this car is safe: it can only
  -- add a penalty to this driver. The sender goes to the audit line
  if (server or senderCarIndex == 0) and classifyServerMessage(message) == 'DT' then
    local prefix = tostring(ac.getDriverName(0) or '') .. ':'
    local text = message
    if message:sub(1, #prefix) == prefix then text = message:sub(#prefix + 1):gsub('^%s+', '') end
    showNotice(TEXTS.kmrTitle, text, nil, SERVER_NOTICE_SECONDS)
    state.kmrMessages[#state.kmrMessages + 1] = { text = text, sender = senderCarIndex }
    Audit.add('KMR', text)
    return true
  end
  if server and onDriverSwapMessage(message) then
    Audit.add('ACSM', message)
    return true
  end
  -- KMR messages of this driver: the infraction points (decision 210) and the safety rating (decision 215); an
  -- infraction message carries both
  if server or senderCarIndex == 0 then
    -- The answers of "kmr stats" / "kmr money" the script asked: read, not shown (decision 278)
    if Audit.kmrStats(message) then return true end
    if Audit.kmrMoneyAnswer(message) and Audit.kmrRating(message) then return true end
    local points = Audit.kmrPoints(message)
    local rating = Audit.kmrRating(message)
    if points or rating then
      Audit.add('KMR', message, true, DICT.area(low) == 'damage' and 'damage' or 'points')
      return true
    end
  end
  -- The race director's points or money penalty to this driver (decision 221): it changes the driver's score
  local name = tostring(ac.getDriverName(0) or '')
  local mine = name ~= '' and message:find(name, 1, true) ~= nil
  if server and mine and hasAny(low, DICT.kmr.directorPenalty) then
    Audit.add('KMR', message, true, 'points')
    return true
  end
  -- The rolling start of the KMR (start/start_control.lua)
  if server and Start.chat(message) then return true end
  if server then
    local kind = classifyServerMessage(message)
    if kind then
      if DICT.code80Kinds[kind] then
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
      Audit.add('KMR', message)
      return true
    end
    -- Every other server message leaves the chat too (decision 227: the chat can stay empty) and goes to the message
    -- window by its area; the race director's actions about another driver are 'others'. Of no area: the race
    -- direction's free text is the ACSM broadcast, "(account name) text", always shown; any other is 'server' (finding
    -- 12 of 29-30/09: shown with the preset Race)
    local area = DICT.area(low)
    if area == 'director' then area = mine and 'rc' or 'others' end
    -- The KMR admin login of this client (the race direction window sends through it) and the answers to its commands
    if low:find('logged in as kissmyrank admin', 1, true) or low:find('logado como kissmyrank admin', 1, true) then
      state.kmrAdmin = true
    end
    if state.directionAnswer and config.canCommand then state.directionAnswer(message) end
    -- A drive-through that is not this driver's (classifyServerMessage above): another driver's penalty
    if not area and hasAny(low, DICT.kmr.driveThrough) then area = 'others' end
    if area then
      Audit.add('KMR', message, true, area)
    else
      local direction = message:match('^%s*%b()') ~= nil
      ac.log(string.format('race-control: server message of no area (sender %s, %s): %s', tostring(senderCarIndex),
        direction and 'race direction' or 'server', message))
      Audit.add('SERVER', message, true, direction and 'rc' or 'server')
    end
    return true
  end
  -- Drivers' chat: stays in the chat; in the message window too when the driver chose it
  if Audit.allow('chat') and senderCarIndex and senderCarIndex > 0 and not message:match('^%s*$') then
    Audit.window = { { src = tostring(ac.getDriverName(senderCarIndex) or 'CHAT'), text = message } }
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
-- or, once the car has stopped for it, 'SGs<ms served>t<server s>d<driver code>'; then 'e<s>' = seconds of the flag
-- infractions it holds (red flag speed, yellow flag overtake: decision 267), then the KMR categories 'x<n>'
local function sgItem()
  for _, it in ipairs(state.list.items) do
    if it.kind:sub(1, 2) == 'SG' then return it end
  end
  return nil
end
local function sgCount(it) return tonumber(it.cat:match('^SG(%d+)$')) or 0 end
-- KMR categories held by the stop & go: kind suffix "x<n>x<n>..." (for the served lines in the log)
local function sgKmrSuffix(it) return it.kind:match('(x[%dx]+)$') or '' end
local function sgSeconds(it) return sgCount(it) * config.sgSecondsPerDT + (tonumber(it.kind:match('e(%d+)')) or 0) end

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
    -- The limit in seconds (maxDT x secondsPerDT): the flag infractions count by their seconds
    if sgSeconds(sg) > config.sgMaxDT * config.sgSecondsPerDT then Rules.sgOverLimit(n) end
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

-- The DSQ taken off (Race Control command RC RELAX DSQ; practice at the pit place, decision 148): our DSQ and the game
-- black flag, controls released, the car record written
local function carDsqClear(why)
  local l = state.list
  local game = l.dsqStage == 1 or ac.getCar(0).currentPenaltyType == BLACK_FLAG
  l.dsq, l.dsqStage, l.dsqUntil, l.dsqReason = 0, 0, 0, nil
  l.seq = l.seq + 1
  state.dtDsqActive, state.pitDsqActive = false, false
  if game then physics.setCarPenalty(ac.PenaltyType.ReleaseBlackFlag) end
  physics.lockUserControlsFor(0)
  listSave()
  ac.log('race-control: disqualification cleared (' .. why .. ')')
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
  -- Body: the 4 zones of the damage screen (SDK: the fifth "is not really used"; decision 168)
  for i = 0, 3 do body = body + math.max(tonumber(car.damage[i]) or 0, 0) end
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

-- Tow and repair hold (qualifying and race, keys qualifyTow / raceTow). The penalties stay in the list after the hold;
-- nothing goes to the game (decision 78)
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
-- Use of each tyre since it was fitted (decisions 162, 166, 170), shown in the setup status: laps (one at each line
-- crossing); km driven (the car's own distance, SDK car.distanceDrivenSessionKm, added frame by frame; the virtual km
-- of the game is not a distance); virtual km of the tyre taken at each line crossing and never going down (the wear on
-- the curve of the compound: life and expected laps are a measure of the laps run, so nothing changes between two
-- lines, with the car stopped or not). Kept in the car record (crash, driver swap). A tyre fitted starts at 0: by the
-- own pit stop box (TyreUse.fitted), or by any other way the game changes it (its virtual km falling at once to less
-- than half: game pit, reset, new session; a slow change of the reading is not a new tyre).
-- ============================================================

local TyreUse = {}
do
  -- Largest distance of one frame that is driving (more: a teleport or a new session count)
  local MAX_STEP_KM = 0.1
  local lastVirtual, lastDist = {}, nil

  function TyreUse.fitted(i)
    state.tyreLaps[i], state.tyreKm[i], state.tyreLineKm[i] = 0, 0, 0
  end

  function TyreUse.update(car, lineFrame)
    local dist = CarRead.num(car.distanceDrivenSessionKm)
    local step = lastDist and dist - lastDist or 0
    lastDist = dist
    if step < 0 or step > MAX_STEP_KM then step = 0 end
    for i = 0, 3 do
      local virtual = CarRead.num(car.wheels and car.wheels[i] and car.wheels[i].tyreVirtualKM)
      if lastVirtual[i] and virtual < lastVirtual[i] * 0.5 then TyreUse.fitted(i) end
      lastVirtual[i] = virtual
      state.tyreKm[i] = (state.tyreKm[i] or 0) + step
      if lineFrame then
        state.tyreLaps[i] = (state.tyreLaps[i] or 0) + 1
        state.tyreLineKm[i] = math.max(state.tyreLineKm[i] or 0, virtual)
      end
    end
    -- Audit of the tyres at the line (the virtual km is measured in the game from these lines)
    if lineFrame then
      local parts = {}
      for i = 0, 3 do
        local virtual = CarRead.num(car.wheels and car.wheels[i] and car.wheels[i].tyreVirtualKM)
        parts[#parts + 1] = string.format('%d laps %.2f km virtual %.3f', state.tyreLaps[i], state.tyreKm[i], virtual)
      end
      ac.log('race-control: tyres at the line: ' .. table.concat(parts, ' / '))
    end
  end
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
  peak = {},           -- [wheel] = { toe, camber }: highest deviation over orig since the damage (decision 167)
  held = {},           -- [wheel] = readings of the last settleSeconds with damage (decision 208)
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

  -- Suspension damage of a wheel in %, by the angle read now (nil while the wheel has no reference): what the record
  -- keeps and the search puts back on the car (the physical state); the damage that counts is CarState.suspPercent
  local function suspPercent(car, i, orig)
    local w = car.wheels and car.wheels[i]
    local o = orig or CarState.orig[i]
    if not w or not o then return nil end
    local dev = math.max(math.abs(num(w.toeIn) - o.toe), math.abs(num(w.camber) - o.camber))
    return math.min(dev / SUSP_MAX_ANGLE, 1) * 100
  end
  -- Deviation of a wheel over the setup that counts for the damage (decisions 167, 208): only with the game reporting
  -- damage on that wheel (suspensionDamage above 0: the damage that stays), and only a deviation held for
  -- damage.settleSeconds (the kerb bends the suspension for an instant and it comes back: elastic, not damage); the
  -- highest held since the damage (the angle read changes with the steering). 0, 0 with no damage; nil while the wheel
  -- has no reference
  function CarState.deviation(car, i)
    local w = car.wheels and car.wheels[i]
    local o = CarState.orig[i]
    if not w or not o then return nil end
    if num(car.suspensionDamage[i]) <= 0 then return 0, 0 end
    local pk = CarState.peak[i] or { toe = 0, camber = 0 }
    return pk.toe, pk.camber
  end
  -- Suspension damage % shown (decision 167): by the deviation that counts
  function CarState.suspPercent(car, i)
    local toe, camber = CarState.deviation(car, i)
    if not toe then return nil end
    return math.min(math.max(toe, camber) / SUSP_MAX_ANGLE, 1) * 100
  end

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
    local laps, tkm, lkm, peak = {}, {}, {}, {}
    for i = 0, 3 do
      laps[#laps + 1] = tostring(state.tyreLaps[i] or 0)
      tkm[#tkm + 1] = string.format('%.2f', state.tyreKm[i] or 0)
      lkm[#lkm + 1] = string.format('%.3f', state.tyreLineKm[i] or 0)
      local pk = CarState.peak[i]
      peak[#peak + 1] = pk and string.format('%.3f/%.3f', pk.toe, pk.camber) or '-'
    end
    return string.format('F%.1f|C%d|K%s|B%s|S%s|R%s|O%s|E%.0f|G%.3f|T%.3f,%.3f,%.1f|D%d|V%s|H%d|L%s|M%s|P%s|W%s',
      num(car.fuel),
      num(car.compoundIndex), table.concat(km, ','), table.concat(body, ','), table.concat(pct, ','),
      table.concat(raw, ','), table.concat(orig, ','), num(car.engineLifeLeft), num(car.gearboxDamage), d.powertrain,
      d.suspension, d.body, state.repair.lapsLeft or -1, table.concat(kmh, ','),
      state.repair.beyondSince and math.floor(state.repair.beyondSince) or -1, table.concat(laps, ','),
      table.concat(tkm, ','), table.concat(peak, ','), table.concat(lkm, ','))
  end

  local function carParse(body)
    -- After H, the fields added later (L laps, M km and W virtual km at the line of each tyre, P suspension peak); a
    -- record without them (older version) still reads, with 0 and no peak
    local f, c, k, b, s, r, o, e, g, t, dl, v, h, rest = tostring(body):match(
      '^F([%d%.]+)|C(%d+)|K([^|]*)|B([^|]*)|S([^|]*)|R([^|]*)|O([^|]*)|E([%d%.]+)|G([%d%.]+)|T([^|]*)|D(%-?%d+)|V([^|]*)|H(%-?%d+)(.*)$')
    if not f then return nil end
    local extra = {}
    for key, value in rest:gmatch('|(%u)([^|]*)') do extra[key] = value end
    local function pairsOf(text)
      local out = {}
      for i, v in ipairs(list(text or '')) do
        local toe, camber = v:match('^([%-%d%.]+)/([%-%d%.]+)$')
        if toe then out[i - 1] = { toe = tonumber(toe), camber = tonumber(camber) } end
      end
      return out
    end
    local orig = pairsOf(o)
    local function nums(text)
      local out = {}
      for i, v in ipairs(list(text)) do out[i] = tonumber(v) or 0 end
      return out
    end
    return { fuel = tonumber(f), compound = tonumber(c), km = nums(k), body = nums(b), pct = nums(s), raw = nums(r),
      orig = orig, engine = tonumber(e), gearbox = tonumber(g), tow = nums(t), repairLaps = tonumber(dl), kmh = nums(v),
      beyondSince = tonumber(h), laps = nums(extra.L or ''), tyreKm = nums(extra.M or ''), peak = pairsOf(extra.P),
      lineKm = nums(extra.W or '') }
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
    for i = 0, 3 do
      state.tyreLaps[i], state.tyreKm[i], state.tyreLineKm[i] = r.laps[i + 1] or 0, r.tyreKm[i + 1] or 0,
        r.lineKm[i + 1] or 0
      CarState.peak[i] = r.peak[i]
    end
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

  -- Session start or script reload. dropReset: a new session within the running script whose start came after the reset
  -- of the car (restart): the record that reset saved under the new session key is the car of the session before; the
  -- new session starts with no record, and the car is saved once it settles (decision 218)
  function CarState.load(dropReset)
    CarState.pending = nil
    CarState.appliedSeq = -1
    CarState.dirtyT = nil
    CarState.damageSig = nil
    CarState.lastBody = nil
    CarState.search = nil
    CarState.startT = state.ui.clock
    local body, seq, source = Record.load('car')
    CarState.seq = seq or 0
    if dropReset then
      CarState.restoring = false
      CarState.dirtyT = state.ui.clock
      ac.log('race-control: car state of the session before not carried over')
      return
    end
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
        CarState.peak[i] = nil
        CarState.held[i] = nil
      elseif w and CarState.orig[i] and not searching then
        -- Damaged: the deviation counts once held for settleSeconds (the lowest of that window: a kerb spike does not
        -- last); the highest held one stays (the angle read changes with the steering, decisions 167, 208)
        local o = CarState.orig[i]
        local now = state.ui.clock
        local list = CarState.held[i] or {}
        CarState.held[i] = list
        list[#list + 1] = { t = now, toe = math.abs(num(w.toeIn) - o.toe), camber = math.abs(num(w.camber) - o.camber) }
        local settle = config.damage.settleSeconds
        while #list > 1 and now - list[2].t >= settle do table.remove(list, 1) end
        if now - list[1].t >= settle then
          local toe, camber = math.huge, math.huge
          for _, v in ipairs(list) do toe, camber = math.min(toe, v.toe), math.min(camber, v.camber) end
          local pk = CarState.peak[i] or { toe = 0, camber = 0 }
          CarState.peak[i] = { toe = math.max(pk.toe, toe), camber = math.max(pk.camber, camber) }
        end
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
-- Toe and camber over the setup: CarState.orig (the wheel with no suspension damage), the highest since the damage
-- (CarState.deviation, decision 167). Body sides: car.damage[0..3]
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
      -- The highest deviation since the damage (decision 167): the angle read changes with the steering
      local toe, camber = CarState.deviation(car, i)
      if toe then
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
    -- Powertrain (engine and gearbox as one: the larger damage of the two, decision 153): from powertrainRepair % the
    -- repair is required; a blown engine (engineLifeLeft 0 or below; 1000 = whole) or a broken gearbox (gearboxDamage 1)
    -- does not drive: beyond the safety limit (the game does not stop the car before)
    local powertrain = math.max((1000 - num(car.engineLifeLeft)) / 10, num(car.gearboxDamage) * 100)   -- %
    if num(car.engineLifeLeft) <= 0 then
      consider('beyond', TEXTS.damageEngine, '')
    elseif num(car.gearboxDamage) >= 1 then
      consider('beyond', TEXTS.damageGearbox, '')
    elseif powertrain >= config.damage.powertrainRepair then
      consider('repair', string.format(TEXTS.damagePowertrain, powertrain),
        string.format(TEXTS.damagePowertrainLimit, config.damage.powertrainRepair))
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

  -- Practice, the car at its pit place (after the tow, back to the session, or driven in): the repair deadline and the
  -- beyond-the-limit timer start again (decision 152)
  function DamageClass.reset()
    local r = state.repair
    r.lapsLeft, r.beyondSince, r.class = nil, nil, 'normal'
  end

  -- Every session (decision 152)
  function DamageClass.update(car, lineFrame)
    local r = state.repair
    if state.dtDsqActive or state.pitDsqActive then
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
  settleUntil = 0,        -- clock until which a change of the car at the pit place is the game's own reset
}
-- Session start or restart (decision 275): the game puts the car back (fuel, tyres, damage) at its pit place over a few
-- frames; for SETTLE_SECONDS that change is no service and no stop (it counted as a pit stop on the race screen)
PitStops.SETTLE_SECONDS = 5
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
    PitStops.markService()
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
      Record.save('window', math.floor(serverTimeMs() / 1000), 'done')
      ac.log('race-control: mandatory pit window: valid driver swap')
    end
  end

  -- A service in a pit stop does not allow the driver swap nor the penalty in the same stop (decision 161): the valid
  -- swap of this pit pass is taken back at once (the window goes back to open if it fulfilled it); only after leaving
  -- the pit lane can it be done again
  function PitStops.voidSwap()
    local sw = state.swap
    if not sw.passSwap or not sw.passSwapValid or sw.passVoided then return end
    sw.passVoided = true
    sw.voids = sw.voids + 1
    if state.pit.done then
      state.pit.done = false
      Record.save('window', math.floor(serverTimeMs() / 1000), 'open')
    end
    SwapRecord.save()
    ac.log('race-control: driver swap not valid: service in the same pit stop')
    rcLog(TEXTS.swapTitle, TEXTS.swapVoidService)
  end

  -- A service started or seen in the pit pass in progress: marked (pit record), and the swap of this pass taken back
  function PitStops.markService()
    if not state.pitPassServiced then
      state.pitPassServiced = true
      PitRecord.save()
    end
    PitStops.voidSwap()
  end

  -- End of the race of this car: valid swaps and stops against the required
  local function raceEnd(car)
    if PitStops.endChecked or sim.raceSessionType ~= ac.SessionType.Race or not car.isRaceFinished then return end
    PitStops.endChecked = true
    local why
    local req = config.swapRequired or 0
    if config.swapOn() and req > 0 and SwapRecord.validNow() < req then
      why = string.format(TEXTS.swapsMissingDsq, SwapRecord.validNow(), req)
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
      -- Leaving the pit lane ends the pit stop: the next one may swap drivers and serve penalties again
      local sw = state.swap
      sw.passSwap, sw.passSwapValid, sw.passVoided = false, false, false
      if state.pitPassServiced then
        state.pitPassServiced = false
        PitRecord.save()
      end
    end
    PitStops.wasInPitlane = inPit
    -- A real change in the car at its pit place (the AC pit screen, for example) is a stop with service
    local p = PitStops.pass
    if p and state.ui.clock < PitStops.settleUntil then
      p.snap = nil
    elseif p and car.isInPit and not CarState.restoring then
      p.snap = p.snap or CarRead.snapshot(car)
      local serviced, what = false, nil
      if not p.stop and state.pitService == nil then serviced, what = CarRead.serviced(car, p.snap) end
      if serviced then
        ac.log('race-control: change in the car at the pit place: ' .. tostring(what))
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
      -- The swap of this pit pass: a service in it (before, by the driver who left; or later, by this one) takes it back
      sw.passSwap, sw.passSwapValid, sw.passVoided = true, sw.swapInfo.inWindow, false
      if state.pitPassServiced then PitStops.voidSwap() end
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
    -- A new driver in the car (not a rejoin): its server time, for the restart order after a red flag (decision 264)
    if not rejoin and swapNo and swapNo > 0 then DriverTable.swapMs = serverTimeMs() end
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
-- wheel, a pair 2F / 2B / 2L / 2R, or the 4: 2A); pressure and wing of the AC pit stop presets (decisions 31, 34, 201:
-- one row per spinner of the quick pit menu, ac.getPitstopSpinners; the online script reads them, only the app can write
-- them, ac.setPitstopSpinnerValue, M7; the menu has them only with a controller with a D-pad: without them the rows are
-- only shown, from the setup); repair by group (suspension, powertrain, bodywork).
-- Pressure is chosen only with tyres chosen in this stop (a new tyre goes out with it); the wing in any stop. When the
-- stop starts, the values changed go to the app (AppLink), which writes them in the preset; the answer goes to the log.
-- Times: fuel and tyres from the car (car.ini [PIT_STOP]: FUEL_LITER_TIME_SEC per litre, TYRE_CHANGE_TIME_SEC per
-- tyre); repair by the repair formula of the session on the collision damage (rule 18, the same as the hold). Total by
-- the order of the operations (key pitStopOrder, the same notation as PITS_ORDER of the CSP: letters F fuel, T tyres,
-- R repair one after the other; letters inside < > at the same time; default F<TR> = fuel first, then tyres and repair
-- together). The stop is applied at the end, not little by little.
-- The stop is chosen anywhere (decision 159): on track and in the pit lane with the gamepad D-pad (a key press shows
-- the box for a few seconds); at the pit place also with the keyboard arrows (on track the arrows may be the steering).
-- No button (decision 160): the last line is the start mode and the start itself: left changes the mode, right starts
-- the stop. AUTO: stopping at the pit place with the box touched and something chosen starts it at once.
-- The box not touched is a plain stop (it serves the stop & go and allows the driver swap); a service allows neither the
-- stop & go nor the driver swap in the same stop (decision 161). The choice is kept until the stop is done or the
-- session changes. The controls are locked for the total time, counted in server time and kept in the pit record (a
-- crash or a driver swap in the middle goes on with the time left); at the end the stop is applied to the car.
-- Controls (controls.ini, configurable): keyboard arrows, gamepad D-pad.
-- Red flag (decision 270): no fuel (unless the race direction unlocks it for the car: RC FUEL); a car that came to the
-- pits by the tow under the red flag repairs after the restart (the tow hold, with the repair, starts then).
-- ============================================================

local PitBox = { row = 1, fuel = 0, compound = nil, tyres = 1, repair = {}, open = false, touched = false,
  shownUntil = 0, auto = nil }
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
  -- Rows that take a choice (the others are only shown); 'set:<spinner name>' = a pressure or wing spinner of the preset
  local ROWS = { 'fuel', 'compound', 'tyres', 'suspension', 'powertrain', 'body', 'mode' }
  PitBox.preset = {}   -- [spinner name] = value chosen (spinner units)

  -- Pressure and wing spinners of the quick pit menu that can be changed now, in the order of the menu
  local function presetSpinners()
    local out = {}
    for _, sp in ipairs(ac.getPitstopSpinners and ac.getPitstopSpinners() or {}) do
      if (sp.type == 'pressure' or sp.type == 'wing') and not sp.readOnly then out[#out + 1] = sp end
    end
    return out
  end
  PitBox.presetSpinners = presetSpinners

  -- The rows now: the spinners go after the tyres
  local function buildRows()
    local rows = { 'fuel', 'compound', 'tyres' }
    for _, sp in ipairs(presetSpinners()) do rows[#rows + 1] = 'set:' .. sp.name end
    for _, r in ipairs({ 'suspension', 'powertrain', 'body', 'mode' }) do rows[#rows + 1] = r end
    return rows
  end

  -- Values chosen that differ from the preset: { { name, value, type } }
  local function presetChanges()
    local out = {}
    for _, sp in ipairs(presetSpinners()) do
      local v = PitBox.preset[sp.name]
      if v and v ~= sp.value then out[#out + 1] = { name = sp.name, value = v, type = sp.type } end
    end
    return out
  end
  local SERVICE_LOCK_EXTRA = 1   -- seconds added to the lock so the stop ends with the car still locked

  -- Keyboard buttons (at the pit place) and gamepad buttons (anywhere), each configurable in the CSP controls
  local function button(name, key, period)
    return ac.ControlButton('12hcuritiba.race-control/Pit stop ' .. name, { keyboard = { key = key }, period = period })
  end
  local function padButton(name, pad, period)
    return ac.ControlButton('12hcuritiba.race-control/Pit stop pad ' .. name, { gamepad = pad, period = period })
  end
  local KEYS = {
    up = button('up', ui.KeyIndex.Up),
    down = button('down', ui.KeyIndex.Down),
    left = button('left', ui.KeyIndex.Left, 0.08),
    right = button('right', ui.KeyIndex.Right, 0.08),
  }
  local PAD = {
    up = padButton('up', ac.GamepadButton.DPadUp),
    down = padButton('down', ac.GamepadButton.DPadDown),
    left = padButton('left', ac.GamepadButton.DPadLeft, 0.08),
    right = padButton('right', ac.GamepadButton.DPadRight, 0.08),
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

  -- Compounds of the car: short names by index; the SDK gives an empty name past the last one (finding 6 of 29-30/09:
  -- empty items in the list)
  local function compounds()
    local out = {}
    for i = 0, 15 do
      local name = ac.getTyresName(0, i)
      if not name or name == '' then break end
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

  -- Start of each operation (seconds after the stop is authorized) by the same order: F, T and R
  function PitBox.starts(times)
    local starts, total, groupStart, group, inGroup = {}, 0, 0, 0, false
    for ch in tostring(config.pitStopOrder):upper():gmatch('.') do
      if ch == '<' then
        inGroup, groupStart, group = true, total, 0
      elseif ch == '>' then
        inGroup, total = false, groupStart + group
      elseif times[ch] then
        if inGroup then
          starts[ch] = groupStart
          group = math.max(group, times[ch])
        else
          starts[ch] = total
          total = total + times[ch]
        end
      end
    end
    return starts
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
    -- Body: the 4 zones (SDK: the fifth "is not really used"; physics.setCarBodyDamage sets only the 4)
    for i = 0, 3 do if num(car.damage[i]) > 0 then return true end end
    return false
  end

  -- The stop chosen now: what is done and how long it takes
  function PitBox.fuelLocked() return state.redFlag ~= nil and not state.redFuelOk end
  function PitBox.repairLocked() return state.redFlag ~= nil and state.redTow ~= nil end

  function PitBox.plan(car)
    local r = carRates()
    local mounted = num(car.compoundIndex)
    local compound = PitBox.compound or mounted
    local tyres = compound ~= mounted and ALL_TYRES or PitBox.tyres
    local fuel = PitBox.fuelLocked() and 0 or math.min(PitBox.fuel, math.max(num(car.maxFuel) - num(car.fuel), 0))
    local p = { fuel = fuel, compound = compound, tyres = tyres, repair = {}, times = {} }
    p.times.fuel = fuel * r.fuel
    p.times.tyres = #TYRE_CHOICES[tyres][2] * r.tyre
    for _, g in ipairs({ 'suspension', 'powertrain', 'body' }) do
      p.repair[g] = PitBox.repair[g] and damaged(car, g) and not PitBox.repairLocked() or false
      p.times[g] = p.repair[g] and repairTime(g) or 0
    end
    p.total = orderTotal({ F = p.times.fuel, T = p.times.tyres,
      R = p.times.suspension + p.times.powertrain + p.times.body })
    -- Pressure and wing (no time of their own): pressure only with tyres changed in this stop
    p.preset = {}
    for _, c in ipairs(presetChanges()) do
      if c.type == 'wing' or #TYRE_CHOICES[tyres][2] > 0 then p.preset[#p.preset + 1] = c end
    end
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
    for _, w in ipairs(wheels) do
      km[w] = 0
      TyreUse.fitted(w)
    end
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
    -- Pressure and wing: written in the preset by the app now (decision 201)
    if #p.preset > 0 then AppLink.setPreset(p.preset) end
    state.pitService = { startMs = serverTimeMs(), untilMs = serverTimeMs() + p.total * 1000, plan = planText(p) }
    -- A service: no driver swap nor penalty in this stop (decision 161)
    PitStops.markService()
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
    PitBox.preset = {}
    PitBox.touched = false
  end
  PitBox.reset = reset

  -- Automatic start: the driver's choice in the box, else the key pitStopMode
  function PitBox.isAuto()
    if PitBox.auto == nil then return config.pitStopAuto end
    return PitBox.auto
  end

  -- Something to do in the plan: fuel, tyres (a new compound changes the 4) or a repair
  local function chosen(p)
    return p.fuel > 0 or #TYRE_CHOICES[p.tyres][2] > 0 or p.repair.suspension or p.repair.powertrain or p.repair.body
      or #p.preset > 0
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
    elseif what == 'mode' then
      -- Automatic / manual start (left): the driver's own choice, not a service (the box is not touched by it)
      PitBox.auto = not PitBox.isAuto()
      return
    elseif what:sub(1, 4) == 'set:' then
      -- Pressure or wing spinner: one step of the spinner, inside its limits
      local name = what:sub(5)
      for _, sp in ipairs(presetSpinners()) do
        if sp.name == name then
          PitBox.preset[name] = math.max(sp.min, math.min((PitBox.preset[name] or sp.value) + dir, sp.max))
        end
      end
    else
      PitBox.repair[what] = not PitBox.repair[what]
    end
    PitBox.touched = true
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
    -- The rows now (the preset spinners come and go with the controller); the chosen row stays inside them
    ROWS = buildRows()
    PitBox.ROWS = ROWS
    if PitBox.row > #ROWS then PitBox.row = #ROWS end
    local wasOpen = PitBox.open
    PitBox.open = CarRead.parked(car) and not state.hold and not state.dtDsqActive and not state.pitDsqActive
      and not CarState.restoring
    -- Choosing: the D-pad anywhere, the keyboard only at the pit place
    -- The D-pad only with the focus on the box (or no focus, decision 205); the keyboard at the pit place
    -- (set by the desktops, which come later in the script: PitBox.padFor); the arrows recorded by the tool act like
    -- the D-pad (PitBox.ownDir, decision 217)
    local padOn = not PitBox.padFor or PitBox.padFor('pitbox')
    local function hit(name)
      local own = PitBox.ownDir and PitBox.ownDir(name)
      return (padOn and (PAD[name]:pressed() or own)) or (KEYS[name]:pressed() and PitBox.open)
    end
    local up, down, left, right = hit('up'), hit('down'), hit('left'), hit('right')
    if up then PitBox.row = (PitBox.row - 2) % #ROWS + 1 end
    if down then PitBox.row = PitBox.row % #ROWS + 1 end
    -- Last line: left changes the mode, right is the start (both modes); on the other lines left / right change the value
    local confirm = right and ROWS[PitBox.row] == 'mode'
    if left then choose(car, -1) end
    if right and not confirm then choose(car, 1) end
    if (up or down or left or right) and not PitBox.open then PitBox.shownUntil = state.ui.clock + config.screens.pitBoxSeconds end
    if not PitBox.open then return end
    -- Anything chosen starts the stop: fuel, tyres or a repair (a repair can take 0 s: only collision damage is
    -- charged, and none is recorded without the tow of the session). AUTO: arriving at the pit place with the box
    -- touched and something chosen starts it at once; both: the start on the last line. Box not touched: a plain stop,
    -- nothing is started (it serves the stop & go and allows the driver swap)
    local p = PitBox.plan(car)
    if not chosen(p) then return end
    if confirm or (PitBox.isAuto() and not wasOpen and PitBox.touched) then startStop(p) end
  end

  PitRecord.onService = PitBox.resume

  -- For the drawing: rows, their text and time
  PitBox.WHEELS = WHEELS
  PitBox.TYRE_CHOICES = TYRE_CHOICES
  PitBox.PAD = PAD
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
-- A pit pass with speeding does not serve the drive-through it paid (decision 248, like the KMR aborts its own above
-- its pit limit): at the pit exit the DT paid goes back to the list, with the lap it lost at the line, and the PSE of
-- the pass comes on top of it. Otherwise a driver could go through the pit flat out every lap and never pay.
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
  local paid = state.pitPaid
  state.pitPaid = nil
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
  if paid then
    listAdd(paid.cat, math.max(paid.laps - lost, 0))
    ac.log(string.format('race-control: pit lane speeding: %s DT paid in this pass does not count', paid.cat))
    rcLog('Drive-through not served', string.format('%s - pit lane speeding %.1f km/h', paid.cat, speed))
    showNotice(TEXTS.rcTitle, TEXTS.pitSpeedNotPaid)
  end
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
-- (decision 78): the panel shows it. A flag infraction (extra seconds, why) forms it too, with the list pending.
function Rules.sgForm(extra, why)
  local l = state.list
  local n = #l.items
  extra = extra or 0
  local reasons = {}
  local kmr = ''
  for _, it in ipairs(l.items) do
    reasons[#reasons + 1] = reasonLog(it.cat)
    if TEXTS.kmrReasons[it.cat] then kmr = kmr .. 'x' .. it.cat:sub(2) end
  end
  if why then reasons[#reasons + 1] = why end
  if not l.owner then l.owner = nameCode(ac.getDriverName(0)) end
  l.seq = l.seq + 1
  local laps = config.sgDeadlineLaps
  l.items = { { cat = 'SG' .. n, kind = 'SG' .. (extra > 0 and ('e' .. extra) or '') .. kmr, laps = laps,
    givenLap = l.curLap, expireLap = l.curLap + laps, seq = l.seq, dt0OnTrack = false } }
  local seconds = n * config.sgSecondsPerDT + extra
  ac.log(string.format('race-control: stop & go %d s (%d DT)', seconds, n))
  rcLog(string.format('Stop & go %d s', seconds), 'includes ' .. table.concat(reasons, ', '))
  if seconds > config.sgMaxDT * config.sgSecondsPerDT then Rules.sgOverLimit(n) end
  listSave()
end

-- Flag infraction (decision 267): red flag speed (flags.redSpeedSG) or yellow flag overtake not given back
-- (flags.yellowPassSG). A stop & go of those seconds, added to the pending penalties (the list becomes one stop & go,
-- or the stop & go grows): progressive, up to the limit. Under the red flag it is served after the restart.
-- stopAndGo mode HOLD has no stop & go: logged, not applied.
function Rules.sgAddSeconds(seconds, why)
  local l = state.list
  if state.dtDsqActive or state.pitDsqActive then
    ac.log('race-control: ' .. why .. ' after the DSQ: logged, not applied')
    return
  end
  if not config.sg then
    ac.log('race-control: ' .. why .. ': stopAndGo mode HOLD, logged, not applied')
    rcLog(why, 'not applied (stopAndGo mode HOLD)')
    return
  end
  local sg = sgItem()
  if sg then
    local suffix = sgKmrSuffix(sg)
    local extra = (tonumber(sg.kind:match('e(%d+)')) or 0) + seconds
    sg.kind = (sg.kind:sub(1, #sg.kind - #suffix):gsub('e%d+', '')) .. 'e' .. extra .. suffix
    l.seq = l.seq + 1
    sg.seq = l.seq
    ac.log(string.format('race-control: stop & go +%d s (%s): %d s', seconds, why, sgSeconds(sg)))
    rcLog(string.format('Stop & go %d s', sgSeconds(sg)), 'includes ' .. why)
    if sgSeconds(sg) > config.sgMaxDT * config.sgSecondsPerDT then Rules.sgOverLimit(sgCount(sg)) end
    listSave()
  else
    Rules.sgForm(seconds, why)
  end
  sg = sgItem()
  if sg then showNotice(TEXTS.rcTitle, string.format(TEXTS.sgFlagGiven, sgSeconds(sg), why), sg) end
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
  -- CODE-80 with frozen deadlines: no lap is taken and nobody is disqualified at this line. The red flag too (decision
  -- 267): every car crosses the line on track to receive it, and the penalties are served after the restart
  local frozen = (state.code80 ~= nil and config.code80Freeze) or state.redFlag ~= nil
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
        -- Kept until the pit exit: speeding in this pit pass takes the payment back (pit_speed.lua, decision 248)
        state.pitPaid = head
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
-- during CODE-80 or the red flag does not serve it (decision 267: under the red flag it is served after the restart); a
-- stop already counting when the CODE-80 starts ends normally.
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

  -- What follows the served time in the kind: the flag seconds and the KMR categories
  local function sgTail(it)
    local e = it.kind:match('e(%d+)')
    return (e and ('e' .. e) or '') .. sgKmrSuffix(it)
  end

  local function sgMark(it, served)
    it.kind = string.format('SGs%dt%dd%d', math.floor(served), math.floor(serverTimeMs() / 1000),
      nameCode(ac.getDriverName(0))) .. sgTail(it)
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
    sg.kind = 'SG' .. sgTail(sg)
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
    -- The game's own reset at a session start is no service (decision 275: PitStops.settleUntil)
    if state.ui.clock < PitStops.settleUntil then
      StopAndGo.snap, StopAndGo.serviced = nil, false
    elseif car.isInPit and not CarState.restoring then
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
    if state.code80 or state.redFlag or StopAndGo.serviced or not CarRead.parked(car) then return end
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
-- Driving the wrong way (rule 33). The game's penalty is off (ALLOW_WRONG_WAY = 1 on the server, and below): the rule
-- is ours. Wrong way = the car points and moves more than wrongWay angle (default 90 degrees) away from the way of the
-- track (CarRead.trackAngle, from the car's world position and ac.worldCoordinateToTrackProgress). The distance
-- actually driven like that is added up (CarRead.motion); pointing the way of the track within the angle, or stopping,
-- ends the manoeuvre and clears it. Reversing with the car pointing the right way is not counted (the KMR reverse
-- gear rule), nor a spin sliding the right way. Up to maxMeters (default 30) is a manoeuvre; more = our DSQ in the
-- usual flow (stop at the pit place, or the game black flag at the line; no teleport). Not counted in the pit lane
-- nor across a teleport or a car reset (a jump is not a move).
-- ============================================================

local WrongWay = { back = 0 }
do
  local STOPPED_KMH = 1          -- below this the car is stopped: the count is cleared

  -- The game's own wrong way: its icon on screen hidden (SDK ac.disableExtraHUDElements 'wrongWay') and its penalty
  -- off (SDK physics.setWrongWayPenalty; ALLOW_WRONG_WAY = 1 on the server too). Once
  local gameOff = false

  function WrongWay.reset()
    WrongWay.back = 0
  end

  function WrongWay.update(car)
    if not gameOff then
      gameOff = true
      ac.disableExtraHUDElements('wrongWay', true)
      if physics.setWrongWayPenalty then physics.setWrongWayPenalty(false) end
      ac.log('race-control: game wrong way icon hidden and penalty off (it was ' .. tostring(sim.wrongWayPenaltyEnabled)
        .. ')')
    end
    local rule = config.wrongWay
    if rule.penalty ~= 'DSQ' or car.isInPitlane or state.dtDsqActive or state.pitDsqActive then
      WrongWay.reset()
      return
    end
    local m = CarRead.motion
    local pointing = CarRead.trackAngle(car, car.look.x, car.look.z)
    local moving = m.dist > 0 and CarRead.trackAngle(car, m.dx, m.dz) or nil
    local before = WrongWay.back
    if car.speedKmh < STOPPED_KMH or (pointing and pointing <= rule.angle) then
      -- The manoeuvre ends pointing the way of the track within the angle, or with the car stopped (decision 146)
      WrongWay.back = 0
      if before >= rule.showMeters then
        rcLog('Wrong way cleared', string.format('%.0f m - %s', before, car.speedKmh < STOPPED_KMH and 'car stopped'
          or string.format('back within %d deg (%.0f deg)', rule.angle, pointing)))
      end
    elseif pointing and moving and moving > rule.angle then
      -- Pointing and moving against the track: the distance driven counts (reversing with the car pointing the right
      -- way is the KMR reverse gear rule; a spin sliding the right way does not count)
      WrongWay.back = WrongWay.back + m.dist
      if before < rule.showMeters and WrongWay.back >= rule.showMeters then
        rcLog('Wrong way', string.format('%.0f deg from the track - %.0f m', pointing, WrongWay.back))
      end
    end
    if WrongWay.back > rule.maxMeters then
      ac.log(string.format('race-control: DSQ, wrong way %.0f m (limit %d m)', WrongWay.back, rule.maxMeters))
      WrongWay.reset()
      carDsq(1, TEXTS.wrongWayDsq, nil, string.format('over %d m', rule.maxMeters))
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
-- Messages (KMR language files v1.6f, language/en.json and pt.json: the KMR sends each driver the message in the
-- driver's language, so the game chat can be in Portuguese while the server log is in English):
--   "Penalty: drive-through before the end of this lap <reason>." / "Penalidade: drive-through antes do final desta
--   volta <reason>." = DT0; "... within <n> ..." / "... dentro de no maximo <n> ..." = DT<n>; "... to clear during the
--   next race <reason>." / "... a ser pago na proxima corrida <reason>." = relaxed (except the pit exit line).
-- The chat handler only keeps the message (state.kmrMessages); it is read here, in script.update.
-- ============================================================

local KmrDT = {}
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
do
  -- Reason of the message -> category (TEXTS.kmrReasons; the words in DICT.kmr.reasons)
  local function category(low)
    for _, r in ipairs(DICT.kmr.reasons) do
      if hasAny(low, r.words) then return r.cat end
    end
    return 'K0'
  end

  -- Deadline of the message: laps (0 = this lap), 'next race', or nil (not a DT given now)
  local function deadline(low)
    local K = DICT.kmr
    if hasAny(low, K.nextRace) then return 'next race' end
    if hasAny(low, K.thisLap) then return 0 end
    local n = DICT.match(low, K.withinLaps)
    if n then return tonumber(n) end
    return nil
  end

  -- Safety rating of the KMR at or under the limit of the key kmrRating (decision 215): our DSQ, once for each new
  -- balance (a DSQ taken off by the race direction is not given again for the same balance)
  local ratingSeen = nil
  local function ratingCheck()
    local r = config.kmrRating
    if not r.on or Audit.rating == nil or Audit.ratingSeq == ratingSeen then return end
    ratingSeen = Audit.ratingSeq
    if Audit.rating > r.dsqAt or state.dtDsqActive or state.pitDsqActive then return end
    ac.log(string.format('race-control: DSQ, KMR safety rating %s (limit %s)', Audit.num(Audit.rating), Audit.num(r.dsqAt)))
    carDsq(1, string.format(TEXTS.kmrRatingDsq, Audit.num(Audit.rating), Audit.num(r.dsqAt)))
  end

  function KmrDT.update()
    ratingCheck()
    local msgs = state.kmrMessages
    if #msgs == 0 then return end
    state.kmrMessages = {}
    for _, m in ipairs(msgs) do
      local text = m.text
      local via = ' - chat sender ' .. tostring(m.sender)
      local low = text:lower()
      local laps = hasAny(low, DICT.kmr.penalty) and deadline(low)
      if laps then
        local cat = category(low)
        local base = TEXTS.kmrReasons[cat]
        -- The infraction limit: the drive-through below, and the points start again from zero (decision 247)
        if cat == 'K3' then Audit.kmrPointsReset() end
        if cat == 'K1' then laps = 0 end
        if cat ~= 'K1' and (laps == 'next race' or sim.raceSessionType ~= ac.SessionType.Race) then
          ac.log('race-control: KMR drive-through relaxed (' .. cat .. '): ' .. text)
          rcLog('Drive-through relaxed', base .. ' - issued by KMR for the next race, not carried over by Race Control' .. via)
        elseif not (state.dtDsqActive or state.pitDsqActive) then
          ac.log(string.format('race-control: KMR drive-through DT%d (%s): %s', laps, cat, text))
          rcLog('Drive-through DT' .. laps, base .. ' - issued by KMR, recorded by Race Control' .. via)
          listAdd(cat, laps)
          Rules.finalize()
        else
          rcLog('Drive-through after the DSQ', base .. ' - issued by KMR, logged only' .. via)
        end
      else
        rcLog('KMR message not read', text .. via)
      end
    end
  end
end
-- ============================================================
-- Race Control commands: sent by an admin from the ACSM live timing (send chat to the driver, or broadcast chat to
-- everyone; a broadcast comes with "(account name) " before it). Only a message from the server is a command (chat.lua,
-- fromServer): a line typed in the chat by a driver is not. The chat handler keeps the line (state.rcCommands, hidden
-- from the chat); it is read here, in script.update.
--   RC <ACTION> <ID> [value] [- reason]
--   ID: Car ID of the server (entry list slot, the same as in /kick 4: car.sessionID) or GUID of the driver (17
--   digits; only while that driver is in the car). The number of the livery is not an ID (it can repeat).
--   Relaxing:  RELAX <ID> ALL | DT | SG | SD | HOLD | REPAIR | DSQ     UNLOCK <ID>   (SG: the stop & go, decision 274)
--   Penalties: DT <ID> [laps]   HOLD <ID> <seconds>   TELEPORT <ID>   DSQ <ID>   LOCK <ID> <seconds>
--   Red flag (decisions 174, 196, 203): REDFLAG ALL [- reason] gives it to every car; REDFLAG OFF ALL takes it off;
--   FUEL <ID> unlocks the fuel of the car under the red flag (decision 270: a car already going to the pits)
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
    elseif what == 'SG' then
      local sg = sgItem()
      if not sg then return false end
      listRemove(sg)
      StopAndGo.stopping, StopAndGo.resume = false, false
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
      carDsqClear('Race Control command')
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
    elseif what == 'FUEL' then
      state.redFuelOk = true
      done(TEXTS.redFuelUnlocked, why)
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
      local red = body:upper():match('^%s*RC%s+REDFLAG%s+(%a+)')
      if red == 'ALL' or red == 'OFF' then
        local on = red == 'ALL'
        if on ~= (state.redFlag ~= nil) then
          state.redFlag = on and { reason = reason ~= '' and reason or nil } or nil
          TrackList.changed()
          rcLog(on and 'Red flag' or 'Red flag off', reason ~= '' and reason or '-')
          ac.log('race-control: red flag ' .. (on and 'on' or 'off') .. (reason ~= '' and (' - ' .. reason) or ''))
        end
      end
      local action, id, value = body:match('^%s*[Rr][Cc]%s+(%a+)%s+(%d+)%s*(%S*)')
      if action and not red and isMine(id) then
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

-- Cut discarded after its slowdown was given (spin before the car is back on track): its seconds and its category
-- leave the slowdown in progress (merged or alone)
local function cancelSlowdown(zone, r)
  for key, sd in pairs(state.slowdowns) do
    for i, c in ipairs(sd.cats) do
      if c == zone.category then
        table.remove(sd.cats, i)
        sd.toPay = math.max(sd.toPay - math.max(r.param, 0), 0)
        if #sd.cats == 0 or sd.toPay <= 0 then state.slowdowns[key] = nil end
        return
      end
    end
  end
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
-- Flags of the Race Control (front E, E2; decisions 194, 195, 206). Every flag is ours: the game ones are hidden by the
-- app (HIDE_RACE_FLAGS, decision 173) and read here; one flag at a time, by the priority of the international rules:
--   1 red (Race Control command, E5); 2 yellow and neutralizations (yellow of a sector, SC, VSC, CODE-80 / FCY);
--   3 penalty and individual command (the boxes of today: DSQ, orange disc, drive-through, stop & go, wrong way; drawn
--   by screen.lua, not here); 4 information (blue, white = slow car, last lap, yellow and red = slippery);
--   5 green and chequered. Same group: the most recent one.
-- Incident table (decision 195): each car tells the others only when its own state changes (and again every
-- INC_RESEND seconds while it lasts, for who connects later), through the one online queue: slow (repair required:
-- the car drives damaged), stopped on track, broken (beyond the safety limit), oil (blown engine), with its track
-- position. Ahead of this car: slow within flags.slowMeters = white; stopped or broken within flags.yellowMeters =
-- yellow; oil = yellow while the car is there, then slippery for flags.oilSeconds; rain intensity over
-- flags.rainSlippery = slippery (scale to measure, M13). Game flags read: Caution (yellow, the car that caused it in
-- raceFlagCause), FasterCar (blue): SDK. The last lap and the chequered flag are ours (decision 257: the game's last
-- lap, chequered flag and session time are not shown): the end of the session below.
-- End of the session (decision 257, design 14): when the time ends (session by time), the cars on track see SESSION
-- TIME OVER; the race by laps, when the leader completes them: RACE OVER; the race by time with an additional lap:
-- LAST LAP for everyone from the leader's line after the time, RACE OVER after the leader's next line. The
-- chequered flag is of each driver: at his line after that, when he enters the pit lane, or at once if he is already
-- in the pit lane. The last lap of the race by laps: when the leader starts it, LAST LAP for everyone. The start
-- lights of the game are hidden; ours from the 22nd place back (Flags.startLights, drawn by screen.lua).
-- Last lap of a session by time (finding 9 of 29-30/09: the game gave no last lap flag in a qualifying by time): when
-- the car enters the last sector, with the time left over its own best of that sector (it reaches the line before the
-- end) and under that best plus its best lap (the time ends in the lap after), the lap after is the last one: LAST LAP
-- from the line. Sessions by laps and the race with an additional lap: the game flag only.
-- The start (rolling start: the formation and the green with the five lights) comes from the start control
-- (start/start_control.lua, Start.flag).
-- ============================================================

local Flags = { incidents = {}, own = 0, ownSince = nil, sentKind = 0, sentT = -1e9, greenUntil = 0, lastGroup = nil,
  sector = nil, lastLap = nil, lastLapSession = nil, ending = nil, endSession = nil, overLeader = nil,
  prevPitlane = nil, hudOff = false, redSent = 'off', redSentT = -1e9, redLocked = false, redLockT = 0, redWasUp = false,
  redSince = nil, redReceived = false, redPrevLane = nil, redSwaps = {}, mySwapMs = nil, restartUntil = nil,
  swapSentT = -1e9, redOver = false, redOverSince = nil, localYellow = false, giveBack = {} }
do
  local INC = { none = 0, slow = 1, stopped = 2, broken = 3, oil = 4 }
  local INC_RESEND = 20        -- seconds: an incident in progress is told again (for who connects later)
  local INC_EXPIRE = 45        -- seconds without news: the incident of another car is dropped
  local STOPPED_KMH = 5
  local STOPPED_SECONDS = 3
  local incNames = { [1] = 'slow', [2] = 'stopped', [3] = 'broken', [4] = 'oil' }

  local sendIncident = ac.OnlineEvent({
    ac.StructItem.key('12hcuritiba.race-control.inc'),
    incKind = ac.StructItem.uint8(),
    incPos = ac.StructItem.uint16(),
  }, function(sender, msg) Flags.receive(sender, msg) end, nil, nil, { processPostponed = true })

  -- Incident of this car now
  local function ownKind(car)
    if car.isInPitlane then return INC.none end
    if CarRead.num(car.engineLifeLeft) <= 0 then return INC.oil end
    if state.repair.class == 'beyond' then return INC.broken end
    if car.speedKmh < STOPPED_KMH and sim.isSessionStarted and not state.hold then
      Flags.ownSince = Flags.ownSince or state.ui.clock
      if state.ui.clock - Flags.ownSince >= STOPPED_SECONDS then return INC.stopped end
    else
      Flags.ownSince = nil
    end
    if state.repair.class == 'repair' then return INC.slow end
    return INC.none
  end

  function Flags.receive(sender, msg)
    if not sender or sender.index == 0 then return end
    local i = sender.index
    local kind = tonumber(msg.incKind) or 0
    local pos = (tonumber(msg.incPos) or 0) / 65535
    -- An incident only where the car really is (Trust, data check on)
    if not Trust.incident(sender, kind, pos) then return end
    local old = Flags.incidents[i]
    -- Oil stays on the track after the car goes (slippery), the rest ends with the incident
    local oilPos = kind == INC.oil and pos or (old and old.oilPos)
    local oilT = kind == INC.oil and state.ui.clock or (old and old.oilT)
    Flags.incidents[i] = { kind = kind, pos = pos, t = state.ui.clock, oilPos = oilPos, oilT = oilT }
  end

  -- Tell the others about this car (on change, and again while it lasts)
  local function publish(car)
    local kind = ownKind(car)
    local clock = state.ui.clock
    if kind ~= Flags.sentKind or (kind ~= INC.none and clock - Flags.sentT >= INC_RESEND) then
      if kind ~= Flags.sentKind then
        rcLog('Incident', kind == INC.none and 'cleared' or incNames[kind])
      end
      Flags.sentKind, Flags.sentT = kind, clock
      OnlineQueue.push(sendIncident, { incKind = kind,
        incPos = math.floor(math.min(math.max(CarRead.num(car.splinePosition), 0), 1) * 65535) }, nil)
    end
    Flags.own = kind
  end

  -- Metres from this car to a point ahead on the track (0 .. track length)
  local function ahead(car, pos)
    local len = tonumber(sim.trackLengthM) or 0
    return ((pos - CarRead.num(car.splinePosition)) % 1) * len
  end

  local function carTag(i)
    return string.format('#%d', ac.getDriverNumber(i) or i)
  end

  -- Restart order after a red flag (decision 264): the cars in their race position, then the cars whose driver was
  -- swapped under the red flag, at the back of the field in the order of the swaps. Each car tells the others the
  -- server time of its swap (again every SWAP_RESEND seconds, for who connects later) until the green of the restart
  local SWAP_RESEND = 5
  local sendRedSwap = ac.OnlineEvent({
    ac.StructItem.key('12hcuritiba.race-control.redorder'),
    swapS = ac.StructItem.uint32(),
  }, function(sender, msg)
    if sender and sender.index ~= 0 and Flags.restartUntil then Flags.redSwaps[sender.index] = tonumber(msg.swapS) end
  end, nil, nil, { processPostponed = true })

  -- Place of this car at the restart and the car ahead of it (index), or nil
  local function restartPlace()
    local list = {}
    for i = 0, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and (i == 0 or c.isConnected) then
        list[#list + 1] = { i = i, pos = CarRead.num(c.racePosition),
          sw = i == 0 and Flags.mySwapMs and math.floor(Flags.mySwapMs / 1000) or Flags.redSwaps[i] }
      end
    end
    table.sort(list, function(a, b)
      if (a.sw ~= nil) ~= (b.sw ~= nil) then return a.sw == nil end
      if a.sw and a.sw ~= b.sw then return a.sw < b.sw end
      if a.pos ~= b.pos then return a.pos < b.pos end
      return a.i < b.i
    end)
    for k, e in ipairs(list) do
      if e.i == 0 then return k, list[k - 1] and list[k - 1].i end
    end
    return nil
  end
  local function restartText()
    if not Flags.restartUntil or sim.raceSessionType ~= ac.SessionType.Race then return nil end
    local k, ahead = restartPlace()
    if not k then return nil end
    if not ahead then return string.format(TEXTS.flagRestartFirst, k) end
    return string.format(Flags.mySwapMs and TEXTS.flagRestartSwap or TEXTS.flagRestart, k, carTag(ahead))
  end

  -- The restart order is kept from the red flag until the green of the restart: the CODE-80 of the restart (VSC of the
  -- KMR) ends, or RESTART_WAIT seconds after the red flag without a CODE-80 (restart with the green at once)
  local RESTART_WAIT = 10
  local function restartUpdate()
    local clock = state.ui.clock
    if state.redFlag then
      Flags.restartUntil = math.huge
      -- A driver swap under this red flag (its start: TrackList.since)
      if DriverTable.swapMs and DriverTable.swapMs >= TrackList.since and not Flags.mySwapMs then
        Flags.mySwapMs = DriverTable.swapMs
        rcLog('Red flag', 'driver swap: restart at the back of the field')
      end
    elseif Flags.restartUntil then
      if Flags.restartUntil == math.huge then Flags.restartUntil = clock + RESTART_WAIT end
      if state.code80 then Flags.restartUntil = clock + 1 end
      if clock > Flags.restartUntil then
        Flags.restartUntil, Flags.redSwaps, Flags.mySwapMs = nil, {}, nil
      end
    end
    if Flags.mySwapMs and Flags.restartUntil and clock - Flags.swapSentT >= SWAP_RESEND then
      Flags.swapSentT = clock
      OnlineQueue.push(sendRedSwap, { swapS = math.floor(Flags.mySwapMs / 1000) }, nil)
    end
  end

  -- The flag of this car now: { group, kind, title, line1, line2 } or nil (group 3 is drawn by screen.lua)
  local function pick(car)
    local cfg = config.flags
    local clock = state.ui.clock
    local red, yellow, info, normal
    Flags.localYellow = false
    -- 1 red (decisions 196, 224): the speed over the limit on track, or the reason of the Race Control
    if state.redFlag then
      local kmh = CarRead.num(car.speedKmh)
      local over = not car.isInPitlane and cfg.redSpeedKmh > 0 and kmh > cfg.redSpeedKmh
      -- At the pit place: the lock on the first line, the restart place on the second (decision 264)
      local atPlace = car.isInPit and restartText()
      red = { 1, 'red', TEXTS.flagRed, atPlace and TEXTS.flagRedLocked or TEXTS.flagRedLine, over and string.format(TEXTS.flagRedSpeed, cfg.redSpeedKmh, kmh)
        or atPlace or (car.isInPit and TEXTS.flagRedLocked)
        or ((state.ui.clock - (Flags.redSince or clock)) < cfg.redGraceSeconds and string.format(TEXTS.flagRedGrace,
          math.ceil(cfg.redGraceSeconds - (state.ui.clock - (Flags.redSince or clock)))))
        or (not car.isInPitlane and not Flags.redReceived and TEXTS.flagRedToLine)
        or (not car.isInPitlane and TEXTS.flagRedToBox)
        or (state.redFlag.reason or TEXTS.flagRedNeutral), over }
    end
    -- 2 neutralizations from the chat (KMR) or the Race Control
    if state.code80 then
      yellow = { 2, 'yellow', TEXTS.flagCode80[state.code80] or state.code80, TEXTS.flagCode80Line,
        restartText() or TEXTS.flagRaceControl }
    end
    -- Incidents of the other cars ahead
    local slow, slip
    for i, inc in pairs(Flags.incidents) do
      if clock - inc.t > INC_EXPIRE then
        Flags.incidents[i] = nil
      else
        local c = ac.getCar(i)
        local d = ahead(car, inc.pos)
        if (inc.kind == INC.stopped or inc.kind == INC.broken or inc.kind == INC.oil) and d <= cfg.yellowMeters
            and not yellow then
          yellow = { 2, 'yellow', TEXTS.flagYellow, TEXTS.flagYellowLine,
            string.format(TEXTS.flagIncidentAhead, carTag(i), TEXTS.flagIncident[incNames[inc.kind]], d) }
          Flags.localYellow = true
        elseif inc.kind == INC.slow and d <= cfg.slowMeters and not slow and not (c and c.isInPitlane) then
          slow = { 4, 'white', TEXTS.flagWhite, TEXTS.flagWhiteLine,
            string.format(TEXTS.flagSlowAhead, carTag(i), d, CarRead.num(c and c.speedKmh)) }
        end
        if inc.oilPos and clock - inc.oilT <= cfg.oilSeconds and not slip and ahead(car, inc.oilPos) <= cfg.yellowMeters then
          slip = { 4, 'slippery', TEXTS.flagSlippery, TEXTS.flagOil, string.format(TEXTS.flagOilCar, carTag(i)) }
        end
      end
    end
    -- Game flags (hidden by the app, shown here)
    local g, cause = sim.raceFlagType, sim.raceFlagCause
    if g == ac.FlagType.Caution and not yellow then
      yellow = { 2, 'yellow', TEXTS.flagYellow, TEXTS.flagYellowLine,
        cause and cause >= 0 and string.format(TEXTS.flagCausedBy, carTag(cause)) or '' }
      Flags.localYellow = true
    end
    -- A place to give back (overtake under the yellow flag): the count on the yellow flag box
    for i, t in pairs(Flags.giveBack) do
      if yellow and Flags.localYellow then
        yellow[5] = string.format(TEXTS.flagGiveBack, carTag(i), math.max(math.ceil(cfg.yellowGiveBackSeconds - (clock - t)), 0))
      end
      break
    end
    if not slip and cfg.rainSlippery > 0 and CarRead.num(sim.rainIntensity) >= cfg.rainSlippery then
      slip = { 4, 'slippery', TEXTS.flagSlippery, TEXTS.flagWet, '' }
    end
    if g == ac.FlagType.FasterCar then
      info = { 4, 'blue', TEXTS.flagBlue, TEXTS.flagBlueLine,
        cause and cause >= 0 and string.format('%s - %.1f s', carTag(cause), math.abs(ac.getGapBetweenCars(0, cause))) or '' }
    elseif Flags.ending == 'lastLap' or (Flags.lastLap and Flags.lastLapSession == sim.currentSessionIndex
        and car.lapCount == Flags.lastLap) then
      info = { 4, 'white', TEXTS.flagLastLap, TEXTS.flagLastLapLine, '' }
    end
    if Flags.ending == 'timeOver' then
      info = { 4, 'white', TEXTS.flagTimeOver, TEXTS.flagFinishLap, '' }
    elseif Flags.ending == 'raceOver' then
      info = { 4, 'white', TEXTS.flagRaceOver, TEXTS.flagFinishLap, '' }
    end
    info = info or slow or slip
    if Flags.ending == 'finished' then
      normal = { 5, 'checkered', TEXTS.flagChequered, TEXTS.flagChequeredMine,
        string.format(TEXTS.flagChequeredPos, CarRead.num(car.racePosition), CarRead.num(car.lapCount)) }
    end
    -- Green: some seconds after a neutralization or a yellow ends
    local top = red or yellow
    if Flags.lastGroup and Flags.lastGroup <= 2 and not top then Flags.greenUntil = clock + cfg.greenSeconds end
    Flags.lastGroup = top and top[1] or nil
    if not normal and clock < Flags.greenUntil then
      normal = { 5, 'green', TEXTS.flagGreen, TEXTS.flagGreenLine, '' }
    end
    -- The start control: the formation of the rolling start with the neutralizations, its green over the others
    local st = Start.flag()
    if st and st[1] == 2 and not yellow then yellow = st end
    if st and st[1] == 5 then normal = st end
    local f = red or yellow or info or normal
    if not f then return nil end
    return { group = f[1], kind = f[2], title = f[3], line1 = f[4], line2 = f[5], alert = f[6], lights = f[7] }
  end

  -- Red flag rules (decisions 196, 203, 263): the line inside the pit lane is after the boxes, so crossing it there
  -- with the red flag is leaving the pits: DSQ. On track the line is crossed on purpose: every car completes the lap it
  -- was doing (the game cannot take laps back, so the laps of the cars stay aligned) and receives the red flag there,
  -- then goes to its box (Flags.redReceived). Overtaking a moving car on track with the red flag: DSQ, after
  -- flags.redGraceSeconds from the red flag (a manoeuvre already under way: the flag box warns only); a car stopped or
  -- in the pit lane is no overtake. Relative place on track of each car: ahead of this one within half a lap or behind it
  local RED_PASS_SPLINE = 0.02    -- a pass is a change of side this close (about 2% of the lap)
  local RED_MOVING_KMH = 10
  -- A car that can be passed (decision 266, the KMR regime without the slow leader): stopped, or slower than
  -- flags.passSlowKmh and farther than flags.passFarM from the car ahead of it on track
  local function passAllowed(i, c)
    local kmh = CarRead.num(c.speedKmh)
    if kmh <= RED_MOVING_KMH then return true end
    if kmh >= config.flags.passSlowKmh then return false end
    local len = tonumber(sim.trackLengthM) or 0
    local nearest = math.huge
    -- The cars ahead of it other than this one (the car passing it)
    for j = 1, (sim.carsCount or 1) - 1 do
      local o = ac.getCar(j)
      if j ~= i and o and o.isConnected and not o.isInPitlane then
        nearest = math.min(nearest, ((CarRead.num(o.splinePosition) - CarRead.num(c.splinePosition)) % 1) * len)
      end
    end
    return nearest > config.flags.passFarM
  end
  -- Metres the car c is ahead of this one (negative: behind), within half a lap
  local function sideOf(car, c)
    local d = CarRead.num(car.splinePosition) - CarRead.num(c.splinePosition)
    if d > 0.5 then d = d - 1 elseif d < -0.5 then d = d + 1 end
    return d
  end

  -- Yellow flag (decision 267): while the flag box shows the yellow of an incident (or of the game), no overtaking,
  -- with the exceptions of the red flag (passAllowed); until the green shows when the area is clear. A car passed has
  -- to get the place back within flags.yellowGiveBackSeconds (the count on the yellow flag box), otherwise a stop &
  -- go of flags.yellowPassSG seconds. The neutralizations (VSC, SC, FCY) stay with the KMR rules.
  local yellowSide = {}
  local function yellowRules(car)
    if state.redFlag or state.dtDsqActive or state.pitDsqActive then
      yellowSide, Flags.giveBack = {}, {}
      return
    end
    local clock = state.ui.clock
    for i, t in pairs(Flags.giveBack) do
      local c = ac.getCar(i)
      if not c or not c.isConnected or c.isInPitlane or car.isInPitlane then
        Flags.giveBack[i] = nil
        ac.log(string.format('race-control: yellow flag overtake of car %d: the car left the track, nothing to give back', i))
      elseif sideOf(car, c) < 0 then
        Flags.giveBack[i] = nil
        ac.log(string.format('race-control: yellow flag overtake of car %d: place given back', i))
        showNotice(TEXTS.rcTitle, string.format(TEXTS.yellowGivenBack, carTag(i)))
      elseif clock - t >= config.flags.yellowGiveBackSeconds then
        Flags.giveBack[i] = nil
        ac.log(string.format('race-control: yellow flag overtake of car %d not given back: stop & go', i))
        Rules.sgAddSeconds(config.flags.yellowPassSG, string.format(TEXTS.yellowPassSG, carTag(i)))
      end
    end
    if not Flags.localYellow or state.code80 then
      yellowSide = {}
      return
    end
    for i = 1, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and c.isConnected and not c.isInPitlane and not car.isInPitlane then
        local d = sideOf(car, c)
        local side = d > 0 and 1 or -1
        if yellowSide[i] == -1 and side == 1 and math.abs(d) < RED_PASS_SPLINE and not Flags.giveBack[i] then
          if passAllowed(i, c) then
            ac.log(string.format('race-control: car %d passed under the yellow flag: allowed (stopped, or slow and far)', i))
          else
            Flags.giveBack[i] = clock
            ac.log(string.format('race-control: overtake under the yellow flag (car %d): give the place back', i))
            showNotice(TEXTS.rcTitle, string.format(TEXTS.flagGiveBack, carTag(i), config.flags.yellowGiveBackSeconds))
          end
        end
        yellowSide[i] = side
      else
        yellowSide[i] = nil
      end
    end
  end

  local redSide = {}
  local function redRules(car, lineFrame)
    if not state.redFlag or state.dtDsqActive or state.pitDsqActive then
      redSide = {}
      Flags.redOver, Flags.redOverSince, Flags.redPrevLane = false, nil, nil
      return
    end
    if lineFrame and car.isInPitlane then
      ac.log('race-control: DSQ, line crossed in the pit lane with the red flag (leaving the pits)')
      carDsq(1, TEXTS.redFlagLineDsq)
      return
    elseif lineFrame and not Flags.redReceived then
      Flags.redReceived = true
      ac.log('race-control: red flag received at the line on track')
      rcLog('Red flag', 'received at the line on track')
    elseif lineFrame then
      -- The red flag received at the line, the car goes to its box: the line on track again is DSQ (decision 265)
      ac.log('race-control: DSQ, line crossed again on track with the red flag (did not go to the pits)')
      carDsq(1, TEXTS.redFlagLineAgainDsq)
      return
    end
    local grace = state.ui.clock - (Flags.redSince or state.ui.clock) < config.flags.redGraceSeconds
    -- CODE-65 (decisions 267, 269): speed on track over flags.redSpeedKmh, no limiter, the driver controls it; as the
    -- KMR does under the VSC, over the limit for more than flags.redOverSeconds = a stop & go of flags.redSpeedSG
    -- seconds, served after the restart; back under the limit, a new time over it counts again
    local cfg = config.flags
    local over = not car.isInPitlane and cfg.redSpeedKmh > 0 and CarRead.num(car.speedKmh) > cfg.redSpeedKmh
    if not over then
      Flags.redOver, Flags.redOverSince = false, nil
    else
      Flags.redOverSince = Flags.redOverSince or state.ui.clock
      if not Flags.redOver and state.ui.clock - Flags.redOverSince > cfg.redOverSeconds then
        Flags.redOver = true
        ac.log(string.format('race-control: CODE-65, over %d km/h for more than %d s with the red flag: stop & go %d s',
          cfg.redSpeedKmh, cfg.redOverSeconds, cfg.redSpeedSG))
        Rules.sgAddSeconds(cfg.redSpeedSG, string.format(TEXTS.redFlagSpeedSG, cfg.redSpeedKmh, cfg.redOverSeconds))
      end
    end
    -- Pit entry driving in without the red flag received at the line on track (decision 270): the lap is not complete
    -- and the game cannot take it back, so a stop & go of flags.redNoLineSG seconds, served after the restart. Not a
    -- tow or a teleport of the race direction (they are not driven in), not in the grace time (a car already going in)
    local entered = car.isInPitlane and Flags.redPrevLane == false
    Flags.redPrevLane = car.isInPitlane
    if entered and not Flags.redReceived and not grace and not car.isInPit and not state.list.jumped
        and state.ui.clock > (state.tow.ownJumpUntil or 0) then
      ac.log('race-control: pit entry with the red flag not received at the line: stop & go ' .. cfg.redNoLineSG .. ' s')
      Rules.sgAddSeconds(cfg.redNoLineSG, TEXTS.redNoLineSG)
    end
    local me = CarRead.num(car.splinePosition)
    for i = 1, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and c.isConnected and not c.isInPitlane and not car.isInPitlane then
        local d = me - CarRead.num(c.splinePosition)
        if d > 0.5 then d = d - 1 elseif d < -0.5 then d = d + 1 end
        local side = d > 0 and 1 or -1
        local was = redSide[i]
        local passed = was == -1 and side == 1 and math.abs(d) < RED_PASS_SPLINE
        if passed and passAllowed(i, c) then
          ac.log(string.format('race-control: car %d passed with the red flag: allowed (stopped, or slow and far)', i))
        elseif passed and grace then
          ac.log(string.format('race-control: overtake with the red flag in the grace time (car %d): warning only', i))
        elseif passed then
          ac.log(string.format('race-control: DSQ, overtake with the red flag (car %d)', i))
          rcLog('Disqualified', string.format(TEXTS.redFlagPassDsq, carTag(i)))
          carDsq(1, string.format(TEXTS.redFlagPassDsq, carTag(i)))
          return
        end
        redSide[i] = side
      else
        redSide[i] = nil
      end
    end
  end

  -- Last lap of a session by time: decided when the car enters the last sector
  local function lastLapCheck(car)
    local sec = CarRead.num(car.currentSector)
    if sec == Flags.sector then return end
    Flags.sector = sec
    local best = car.bestSplits
    local n = best and #best or 0
    if n < 2 or sec ~= n - 1 then return end
    local session = ac.getSession(sim.currentSessionIndex)
    local byTime = session and ((session.durationMinutes or 0) > 0) and (session.type ~= ac.SessionType.Race
      or (session.isTimedRace and not session.hasAdditionalLap))
    if not byTime then return end
    local lastSector, bestLap = CarRead.num(best[n - 1]), CarRead.num(car.bestLapTimeMs)
    local left = CarRead.num(sim.sessionTimeLeft)
    if lastSector <= 0 or bestLap <= 0 or left <= 0 then return end
    if left > lastSector and left < lastSector + bestLap then
      Flags.lastLap, Flags.lastLapSession = car.lapCount + 1, sim.currentSessionIndex
      rcLog('Last lap', string.format('lap %d - %.0f s left, best last sector %.1f s', car.lapCount + 2, left / 1000,
        lastSector / 1000))
    end
  end

  -- Laps of the leader (race position 1) now, or nil
  local function leaderLaps()
    for i = 0, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and (i == 0 or c.isConnected) and CarRead.num(c.racePosition) == 1 then return CarRead.num(c.lapCount) end
    end
    return nil
  end
  -- End of the session and the last lap of the race by laps (decision 257)
  local function sessionEnd(car, lineFrame)
    if Flags.endSession ~= sim.currentSessionIndex then
      Flags.endSession, Flags.ending, Flags.overLeader, Flags.prevPitlane = sim.currentSessionIndex, nil, nil, nil
    end
    local enteredPit = car.isInPitlane and Flags.prevPitlane == false
    Flags.prevPitlane = car.isInPitlane
    if Flags.ending == 'finished' or not sim.isSessionStarted then return end
    local session = ac.getSession(sim.currentSessionIndex)
    if not session then return end
    local race = session.type == ac.SessionType.Race
    local timed = (session.durationMinutes or 0) > 0 and (not race or session.isTimedRace)
    local lead = leaderLaps()
    local was = Flags.ending
    local now = was
    if timed and CarRead.num(sim.sessionTimeLeft) <= 0 then
      if race and session.hasAdditionalLap then
        Flags.overLeader = Flags.overLeader or lead
        if lead and Flags.overLeader and lead >= Flags.overLeader + 2 then now = 'raceOver'
        elseif lead and Flags.overLeader and lead >= Flags.overLeader + 1 then now = 'lastLap'
        else now = now or nil end
      else
        now = 'timeOver'
      end
    elseif not timed and race and (session.laps or 0) > 0 and lead then
      if lead >= session.laps then now = 'raceOver'
      elseif lead == session.laps - 1 then now = 'lastLap' end
    end
    -- Over: the chequered flag at this car's line, entering the pit lane, or at once already in the pit lane
    if now == 'timeOver' or now == 'raceOver' then
      local startedNow = was ~= now
      if (startedNow and car.isInPitlane) or (not startedNow and (lineFrame or enteredPit)) then
        now = 'finished'
      end
    end
    if now ~= was then
      Flags.ending = now
      if now then rcLog('Session end', now) end
    end
  end

  -- Own start lights (decision 257, design 10): standing start of the race, this car from the 22nd place back; in
  -- the last 5 s before the start one column more lit each second, all off at the start. Number of columns lit, or nil
  local START_LIGHTS_FROM = 22
  function Flags.startLights(car)
    if Start.phase then return nil end
    if sim.raceSessionType ~= ac.SessionType.Race or sim.isSessionStarted then return nil end
    if CarRead.num(car.racePosition) < START_LIGHTS_FROM then return nil end
    local t = CarRead.num(sim.timeToSessionStart)
    if t <= 0 or t > 5000 then return nil end
    return math.min(5, 6 - math.ceil(t / 1000))
  end

  -- Red flag at the pit place and the pit lights (decision 261): the car stopped at its pit place has the controls locked
  -- until the red flag goes down (service and driver swap stay allowed: regulation 13.3.3; a service or a DSQ keeps its
  -- own lock); the track script is told ('race-control.redflag': 'on' every 2 s while it is up, 'off' when it goes
  -- down) and lights the pit exit red, then green
  local RED_TRACK_EVENT = 'race-control.redflag'
  local function redPit(car)
    local up = state.redFlag ~= nil
    -- The restart (the red flag goes down): a car that did not enter the pits under the red flag is disqualified
    -- (decision 262); before it the race direction can disqualify it or send it to the pits (RC DSQ / RC TELEPORT)
    if Flags.redWasUp and not up and not car.isInPitlane and not (state.dtDsqActive or state.pitDsqActive) then
      ac.log('race-control: DSQ, not in the pits at the restart after the red flag')
      carDsq(1, TEXTS.redFlagNoPitDsq)
    end
    if up ~= Flags.redWasUp then state.redFuelOk = false end
    if up and not Flags.redWasUp then Flags.redSince, Flags.redReceived = state.ui.clock, false end
    Flags.redWasUp = up
    local ev = up and 'on' or 'off'
    if ev ~= Flags.redSent or (up and state.ui.clock - Flags.redSentT >= 2) then
      Flags.redSent, Flags.redSentT = ev, state.ui.clock
      ac.broadcastSharedEvent(RED_TRACK_EVENT, ev)
    end
    local ownLock = state.pitService or state.dtDsqActive or state.pitDsqActive
    if up and car.isInPit and not ownLock then
      if not Flags.redLocked or state.ui.clock >= Flags.redLockT then
        physics.lockUserControlsFor(3)
        Flags.redLocked, Flags.redLockT = true, state.ui.clock + 2
      end
    elseif Flags.redLocked and not up then
      Flags.redLocked = false
      if not ownLock then physics.lockUserControlsFor(0) end
      rcLog('Red flag', 'controls released at the pit place')
    end
    -- A tow under the red flag (decision 270): its hold, tow and repair, starts at the restart
    if state.redTow and not up then
      local rt = state.redTow
      state.redTow = nil
      applyTowHold(rt.tow, rt.damage, TEXTS.towReason)
      PitRecord.save()
    end
  end

  function Flags.update(car, lineFrame)
    redPit(car)
    -- The game's session time and start lights are not shown (ours only), once
    if not Flags.hudOff then
      Flags.hudOff = true
      ac.disableExtraHUDElements('sessionTime', true)
      ac.disableExtraHUDElements('startingLights', true)
    end
    sessionEnd(car, lineFrame)
    lastLapCheck(car)
    publish(car)
    redRules(car, lineFrame)
    restartUpdate()
    yellowRules(car)
    Flags.current = pick(car)
  end
end
-- ============================================================
-- Race table (front E, E3; decisions 197, 198, 207). Read locally, never sent car by car (the online queue sends one
-- message every 0.25 s): the session leaderboard (order, laps that do not start again on a reconnection, best lap) and
-- each car (number, driver, team, class, track position, pit lane), refreshed REFRESH seconds apart, not every frame.
-- Laps of this car: one line per line crossing (time, sectors, valid, pit pass, driver), kept on this computer
-- (record 'laps', not sent to the others: only this car shows them).
-- Stint of the driver (decision 198, key driverStint, optional): start of the driver in the car and the last stop at
-- the pit place, in server time, in the car record 'stint' (kept by the others: a driver swap to another computer
-- gets it). Over maxMinutes while driving: DSQ. A driver swap with the stint of the driver who left under minMinutes:
-- DSQ. Race only.
-- ============================================================

local RaceTable = { rows = {}, byIndex = {}, order = {}, laps = {}, nextT = 0, stops = {}, passes = {},
  stint = { driver = 0, startMs = -1, parkMs = -1, seq = 0 }, stintDone = false, maxDsq = false, prevParked = nil }
do
  local REFRESH = 0.25
  local MAX_LAPS = 600

  -- Class of a car model: key classes = GT3:model/model | GT4:model (the SDK has no car class)
  local classes = {}
  for item in tostring(cfg.classes or ''):gmatch('[^|]+') do
    local name, models = item:match('^%s*([^:]+)%s*:%s*(.-)%s*$')
    if name then
      for m in models:gmatch('[^/]+') do classes[m:match('^%s*(.-)%s*$'):lower()] = name:match('^%s*(.-)%s*$') end
    end
  end
  function RaceTable.classOf(i)
    return classes[tostring(ac.getCarID(i) or ''):lower()]
  end

  -- Stops of each car (the PIT column): a pass through the pit lane in which the car stopped at its own pit place
  -- (car.isInPitlane, car.isInPit: read for every car), seen by this client; kept on this computer for the session
  local STOPS_KEY = 'rc.stops'
  local function stopsSave()
    local parts = {}
    for i, n in pairs(RaceTable.stops) do parts[#parts + 1] = i .. ':' .. n end
    ac.storage[STOPS_KEY] = Record.key() .. '\n' .. table.concat(parts, ';')
  end
  local function stopsLoad()
    RaceTable.stops, RaceTable.passes = {}, {}
    local key, body = tostring(ac.storage[STOPS_KEY] or ''):match('^([^\n]*)\n(.*)$')
    if not key or not Record.sameSession(key, Record.key()) then return end
    for i, n in body:gmatch('(%d+):(%d+)') do RaceTable.stops[tonumber(i)] = tonumber(n) end
  end
  local function stopsWatch(c)
    local ps = RaceTable.passes[c.index] or {}
    RaceTable.passes[c.index] = ps
    if c.isInPitlane then
      ps.lane = true
      if c.isInPit then ps.parked = true end
    elseif ps.lane then
      if ps.parked then
        RaceTable.stops[c.index] = (RaceTable.stops[c.index] or 0) + 1
        stopsSave()
      end
      ps.lane, ps.parked = false, false
    end
  end

  -- Standings and the cars around, from the leaderboard and each car
  function RaceTable.refresh()
    local session = ac.getSession(sim.currentSessionIndex)
    local board = session and session.leaderboard
    local rows, byIndex, classPos = {}, {}, {}
    if board then
      for k = 0, #board do
        local e = board[k]
        local c = e and e.car
        if c then
          stopsWatch(c)
          local cls = RaceTable.classOf(c.index)
          if cls then classPos[cls] = (classPos[cls] or 0) + 1 end
          local r = { index = c.index, pos = #rows + 1, classPos = cls and classPos[cls] or nil, class = cls,
            number = ac.getDriverNumber(c.index) or c.index, name = tostring(ac.getDriverName(c.index) or ''),
            team = tostring(ac.getDriverTeam(c.index) or ''), laps = e.laps or 0, best = e.bestLapTimeMs or 0,
            spline = CarRead.num(c.splinePosition), inPit = c.isInPitlane, connected = c.isConnected,
            stops = RaceTable.stops[c.index] or 0 }
          rows[#rows + 1] = r
          byIndex[c.index] = r
        end
      end
    end
    RaceTable.rows, RaceTable.byIndex = rows, byIndex
  end

  -- Progress of a car on the track: laps + position on the lap (to compare laps between cars)
  function RaceTable.progress(r) return r.laps + r.spline end

  local function lapsSave()
    local parts = {}
    for _, l in ipairs(RaceTable.laps) do
      parts[#parts + 1] = string.format('%d,%d,%d,%d,%s,%s', l.lap, l.ms, l.valid and 1 or 0, l.pit and 1 or 0,
        table.concat(l.s, '/'), l.driver)
    end
    Record.save('laps', #RaceTable.laps, table.concat(parts, ';'))
  end
  local function lapsApply(body)
    RaceTable.laps = {}
    for lap, ms, valid, pit, s, driver in tostring(body or ''):gmatch('(%d+),(%d+),(%d),(%d),([%d/]*),([^;]*)') do
      local sec = {}
      for v in s:gmatch('%d+') do sec[#sec + 1] = tonumber(v) end
      RaceTable.laps[#RaceTable.laps + 1] = { lap = tonumber(lap), ms = tonumber(ms), valid = valid == '1',
        pit = pit == '1', s = sec, driver = driver }
    end
  end

  local function stintSave()
    local st = RaceTable.stint
    st.seq = st.seq + 1
    Record.save('stint', st.seq, string.format('%d|%d|%d', st.driver, math.floor(st.startMs), math.floor(st.parkMs)))
  end
  local function stintApply(body, seq)
    local d, s, p = tostring(body or ''):match('^(%d+)|(%-?%d+)|(%-?%d+)$')
    if not d then return end
    RaceTable.stint = { driver = tonumber(d), startMs = tonumber(s), parkMs = tonumber(p), seq = seq or 0 }
  end
  RecordSync.restorers.stint = function(body, seq)
    if not RaceTable.stintDone then stintApply(body, seq) end
  end

  -- Session start or reload: this car's laps and stint of this session
  function RaceTable.load()
    lapsApply(Record.load('laps'))
    stopsLoad()
    local body, seq = Record.load('stint')
    RaceTable.stint = { driver = 0, startMs = -1, parkMs = -1, seq = 0 }
    if body then stintApply(body, seq) end
    RaceTable.stintDone, RaceTable.maxDsq, RaceTable.prevParked = false, false, nil
  end

  -- Stint of the driver in the car now, ms (nil before it is known)
  function RaceTable.stintMs()
    local st = RaceTable.stint
    if not RaceTable.stintDone or st.startMs < 0 then return nil end
    return serverTimeMs() - st.startMs
  end

  local function stintUpdate(car)
    local rule = config.driverStint
    local st = RaceTable.stint
    -- Who drives is decided with the driver table (other drivers' records arrive in its first seconds)
    if not RaceTable.stintDone then
      if not DriverTable.done then return end
      RaceTable.stintDone = true
      local me = nameCode(ac.getDriverName(0))
      if st.driver ~= me then
        -- A new driver in the car: the one who left had his stint from startMs to his last stop at the pit place
        local prev = st.driver ~= 0 and st.startMs >= 0 and st.parkMs >= st.startMs and (st.parkMs - st.startMs) or nil
        if prev and rule.minMinutes > 0 and sim.raceSessionType == ac.SessionType.Race and prev < rule.minMinutes * 60000 then
          carDsq(1, string.format(TEXTS.stintMinDsq, mmss(prev / 1000), rule.minMinutes))
        end
        RaceTable.stint = { driver = me, startMs = serverTimeMs(), parkMs = -1, seq = st.seq }
        stintSave()
      end
    end
    local parked = CarRead.parked(car)
    if parked and RaceTable.prevParked == false then
      RaceTable.stint.parkMs = serverTimeMs()
      stintSave()
    end
    RaceTable.prevParked = parked
    local ms = RaceTable.stintMs()
    if ms and rule.maxMinutes > 0 and sim.raceSessionType == ac.SessionType.Race and not parked
        and ms > rule.maxMinutes * 60000 and not RaceTable.maxDsq then
      RaceTable.maxDsq = true
      carDsq(1, string.format(TEXTS.stintMaxDsq, rule.maxMinutes))
    end
  end

  function RaceTable.update(car, lineFrame, viaPit)
    if lineFrame and CarRead.num(car.previousLapTimeMs) > 0 then
      local s = {}
      local splits = car.lastSplits or {}
      for k = 0, #splits do
        local v = splits[k]
        if v then s[#s + 1] = math.floor(CarRead.num(v)) end
      end
      local laps = RaceTable.laps
      laps[#laps + 1] = { lap = leaderboardLaps() or car.lapCount, ms = math.floor(CarRead.num(car.previousLapTimeMs)),
        valid = car.isLastLapValid ~= false and CarRead.num(car.lastLapCutsCount) == 0, pit = viaPit == true, s = s,
        driver = tostring(ac.getDriverName(0) or ''):gsub('[,;|]', ' ') }
      if #laps > MAX_LAPS then table.remove(laps, 1) end
      lapsSave()
    end
    stintUpdate(car)
    if state.ui.clock >= RaceTable.nextT then
      RaceTable.nextT = state.ui.clock + REFRESH
      RaceTable.refresh()
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
-- Cut without a reference yet: the slowdown is given at the cut; a spin before the car is back on track cancels it.
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

-- Spin (loss of control): the car pointing more than cutSpinAngle away from the way of the track at the car
-- (CarRead.trackAngle: the reference is the track, not the car's own movement), above SPIN_MIN_SPEED_KMH
local function spinning(car)
  local angle = CarRead.trackAngle(car, car.look.x, car.look.z)
  return car.speedKmh > SPIN_MIN_SPEED_KMH and angle ~= nil and angle > config.cutSpinAngle
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
            if spinning(car) then pass.spun = true end
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
    if spinning(car) then cc.spun = true end
    -- Back on track = the four wheels on it (one wheel back is not back: a loss of control on the way back counts)
    local back = car.wheelsOutside == 0
    if cc.given then
      -- No reference: the slowdown was given at the cut; a spin before the car is back on track cancels it
      if cc.spun then
        state.cutChecks[zi] = nil
        cancelSlowdown(zone, cc.rule)
        ac.log(string.format('race-control: cut %s discarded: spin, slowdown cancelled', zone.category))
      elseif car.isInPitlane or back or not inZone then
        state.cutChecks[zi] = nil
      end
    elseif car.isInPitlane then
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
    -- After the DSQ a new infraction is only logged (decision 17)
    if state.dtDsqActive or state.pitDsqActive then
      ac.log(string.format('race-control: cut %s after the DSQ: logged, not applied', zone.category))
      return
    end
    local ref = state.zoneRef[zoneIndex]
    local pass = state.zonePass[zoneIndex]
    if r.penalty == 'SLOWDOWN' then
      -- A spin in the zone passage before the cut discards it. With a reference: decided when the car is back on track
      -- (gain filter). Without one: slowdown at the cut, cancelled by a spin before the car is back on track
      local withRef = pass and ref or nil
      if pass and pass.spun then
        ac.log(string.format('race-control: cut %s discarded: spin', zone.category))
      else
        if not withRef then
          startSlowdown(zone, r, lapCount)
          queueChat(TEXTS.cut.SLOWDOWN)
        end
        state.cutChecks[zoneIndex] = { zone = zone, rule = r, lapCount = lapCount, t0 = pass and pass.t0 or sim.time,
          ref = withRef, given = not withRef, margin = 0, spun = false }
      end
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
  return { value = string.format(TEXTS.swapCount, SwapRecord.validNow(), config.swapRequired), color = lit and 'green' or 'dim',
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
  if state.code80 or DICT.code80Kinds[nflag] then return BORDER_YELLOW end
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
-- Virtual desktops of the screens (front E, E4; decisions 191, 192, 199, 204, 205). The screens stay in the online
-- script (no app windows): each desktop is a list of screens with their place and mode (visible / auto-hide /
-- hidden); a screen can be on several desktops, or pinned to all of them (one place); the Race Control panel and the
-- flag box are fixed on every desktop (not in the list). The pit desktop is shown over the current one in the pit
-- lane (off by the driver's own choice, at his own risk). Kept on this computer (ac.storage), written at every change
-- and read again on the way back (crash, restarted game, another session).
-- Focus (decision 205): the D-pad works only on the screen in focus (its border lights up): up / down on its rows,
-- left / right on its values. Buttons of the tool (CSP controls): next / previous screen (focus, by the place on screen:
-- top to bottom, left to right), next / previous desktop. In the pit lane the pit stop box takes the focus. No focus
-- = the pit stop box (decision 159: the stop is chosen anywhere with the D-pad).
-- Text kept: 1|<current>|<count>|<pit on>|<desk>:<screen>:<x>:<y>:<mode>;... (desk = number, 'all' or 'pit'; x, y =
-- offset from the screen's own place, px at 1080p)
-- ============================================================

local Desktop = { current = 1, count = 1, pitOn = true, place = {}, focus = nil, editor = false, editDesk = 1,
  indicatorUntil = 0, drawnOrder = {}, wasInPit = nil }
do
  local SCREENS = { 'pitbox', 'setup', 'status', 'race', 'laps', 'standings', 'relative', 'laptime', 'delta', 'event',
    'weather', 'map' }
  local MODE_NEXT = { visible = 'auto', auto = 'hidden', hidden = 'visible' }
  local STORAGE_KEY = 'rc.desktops'
  Desktop.SCREENS = SCREENS

  local function button(name) return ac.ControlButton('12hcuritiba.race-control/' .. name) end
  local NAV = { nextScreen = button('Next screen'), prevScreen = button('Previous screen'),
    nextDesktop = button('Next desktop'), prevDesktop = button('Previous desktop') }
  Desktop.NAV = NAV

  local function defaults()
    Desktop.current, Desktop.count, Desktop.pitOn = 1, 1, true
    Desktop.place = {
      [1] = { relative = { x = 0, y = 0, mode = 'auto' }, laptime = { x = 0, y = 0, mode = 'auto' },
        race = { x = 0, y = 0, mode = 'auto' } },
      all = {},
      -- Pit desktop suggested (decision 199): pit stop box, car status, standings, and the setup status
      pit = { pitbox = { x = 0, y = 0, mode = 'auto' }, status = { x = 0, y = 0, mode = 'auto' },
        setup = { x = 0, y = 0, mode = 'auto' }, standings = { x = 0, y = 0, mode = 'auto' } },
    }
    -- The places the driver had given to the pit screens before the desktops (screen control, prefix screen_)
    for _, g in ipairs({ 'pitbox', 'setup', 'status' }) do
      local e = Desktop.place.pit[g]
      e.x, e.y = tonumber(ac.storage['screen_' .. g .. 'X']) or 0, tonumber(ac.storage['screen_' .. g .. 'Y']) or 0
      local m = ac.storage['screen_' .. g .. 'Mode']
      if MODE_NEXT[tostring(m)] then e.mode = tostring(m) end
    end
  end

  function Desktop.save()
    local parts = {}
    for d, list in pairs(Desktop.place) do
      for g, e in pairs(list) do
        parts[#parts + 1] = string.format('%s:%s:%d:%d:%s', tostring(d), g, math.floor(e.x), math.floor(e.y), e.mode)
      end
    end
    ac.storage[STORAGE_KEY] = string.format('1|%d|%d|%d|%s', Desktop.current, Desktop.count, Desktop.pitOn and 1 or 0,
      table.concat(parts, ';'))
  end

  local function load()
    local text = ac.storage[STORAGE_KEY]
    local cur, count, pit, body = tostring(text or ''):match('^1|(%d+)|(%d+)|(%d)|(.*)$')
    if not cur then
      defaults()
      return
    end
    Desktop.count = math.max(1, tonumber(count))
    Desktop.current = math.min(math.max(1, tonumber(cur)), Desktop.count)
    Desktop.pitOn = pit == '1'
    Desktop.place = { all = {}, pit = {} }
    for i = 1, Desktop.count do Desktop.place[i] = {} end
    for d, g, x, y, mode in body:gmatch('([%w]+):(%a+):(%-?%d+):(%-?%d+):(%a+)') do
      local key = tonumber(d) or d
      if Desktop.place[key] and MODE_NEXT[mode] then
        Desktop.place[key][g] = { x = tonumber(x), y = tonumber(y), mode = mode }
      end
    end
  end
  load()

  -- A screen of the desktops (the panel is not one)
  function Desktop.has(g)
    for _, s in ipairs(SCREENS) do if s == g then return true end end
    return false
  end

  -- The pit desktop is shown now (in the pit lane, unless the driver turned it off)
  local function pitNow() return Desktop.pitOn and ac.getCar(0).isInPitlane end

  -- Where a screen is now: pinned to all (green); with the editor open, the desktop being edited (to see it while
  -- editing); in the pit lane the pit desktop instead of the current one (not both); else the current desktop.
  -- The pit stop box of the pit desktop also counts on track: its own auto-hide rule shows it after a D-pad press
  -- (decision 159) and during the stop
  -- Second value: true when it is the pit stop box of the pit desktop used away from the pit lane
  function Desktop.entry(g)
    local p = Desktop.place
    if p.all[g] then return p.all[g] end
    if Desktop.editor then return p[Desktop.editDesk] and p[Desktop.editDesk][g] or nil end
    if pitNow() then return p.pit[g] end
    local cur = p[Desktop.current] and p[Desktop.current][g]
    if cur then return cur end
    if g == 'pitbox' and p.pit[g] then return p.pit[g], true end
    return nil
  end
  -- Mode of a screen now; with the editor open every screen of the desktop being edited is shown. The pit stop box of
  -- the pit desktop away from the pit lane only by its auto-hide rule (D-pad press, stop running), whatever its mode
  function Desktop.mode(g)
    local e, away = Desktop.entry(g)
    if e and Desktop.editor then return 'visible' end
    -- The screen the driver reached by the navigation is shown, hidden or auto-hide (decision 228); the focus the pit
    -- lane gives to the pit stop box does not change its mode
    if e and Desktop.focus == g and Desktop.focusByNav then return 'visible' end
    if away then return e.mode == 'hidden' and 'hidden' or 'auto' end
    return e and e.mode or 'hidden'
  end
  function Desktop.offset(g)
    local e = Desktop.entry(g)
    return e and vec2(e.x, e.y) or vec2(0, 0)
  end
  function Desktop.setOffset(g, v)
    local e = Desktop.entry(g)
    if not e then return end
    e.x, e.y = v.x, v.y
    Desktop.save()
  end
  function Desktop.cycleMode(g)
    local e = Desktop.entry(g)
    if e then e.mode = MODE_NEXT[e.mode]; Desktop.save() end
  end
  -- Shown / auto-hide of a screen on the current desktop (the panel icons, the delta button): added when missing
  function Desktop.setMode(g, mode)
    local e, away = Desktop.entry(g)
    if not e or away then
      e = { x = 0, y = 0, mode = mode }
      Desktop.place[Desktop.current][g] = e
    end
    e.mode = mode
    Desktop.save()
  end
  function Desktop.remove(d, g) Desktop.place[d][g] = nil; Desktop.save() end

  -- Editor: a screen on a desktop (or pinned to all)
  function Desktop.toggle(d, g)
    local list = Desktop.place[d]
    if list[g] then list[g] = nil else list[g] = { x = 0, y = 0, mode = 'visible' } end
    Desktop.save()
  end
  function Desktop.pinAll(d, g)
    local p = Desktop.place
    if p.all[g] then
      p[d == 'all' and Desktop.current or d][g] = p.all[g]
      p.all[g] = nil
    elseif p[d][g] then
      p.all[g] = p[d][g]
      for k, list in pairs(p) do if k ~= 'all' then list[g] = nil end end
    end
    Desktop.save()
  end
  function Desktop.addDesktop()
    if Desktop.count >= #SCREENS then return end
    Desktop.count = Desktop.count + 1
    Desktop.place[Desktop.count] = {}
    Desktop.editDesk = Desktop.count
    Desktop.save()
  end
  function Desktop.deleteDesktop(d)
    if type(d) ~= 'number' or Desktop.count <= 1 then return end
    for i = d, Desktop.count - 1 do Desktop.place[i] = Desktop.place[i + 1] end
    Desktop.place[Desktop.count] = nil
    Desktop.count = Desktop.count - 1
    Desktop.current = math.min(Desktop.current, Desktop.count)
    Desktop.editDesk = math.min(d, Desktop.count)
    Desktop.save()
  end
  function Desktop.copyFrom(from, to)
    if type(to) ~= 'number' or from == to then return end
    Desktop.place[to] = {}
    for g, e in pairs(Desktop.place[from] or {}) do Desktop.place[to][g] = { x = e.x, y = e.y, mode = e.mode } end
    Desktop.save()
  end
  function Desktop.go(dir)
    Desktop.current = (Desktop.current - 1 + dir) % Desktop.count + 1
    Desktop.indicatorUntil = state.ui.clock + config.screens.indicatorSeconds
    Desktop.focus = nil
    Desktop.save()
  end

  -- Screens drawn in the last frame, in the focus order (by their place: top to bottom, left to right); the last place
  -- of each screen is kept for the navigation while it is hidden
  local function byPlace(a, b)
    if math.abs(a.y - b.y) > 20 then return a.y < b.y end
    return a.x < b.x
  end
  Desktop.lastPlace = {}
  function Desktop.setDrawn(list)
    table.sort(list, byPlace)
    Desktop.drawnOrder = list
    for _, e in ipairs(list) do Desktop.lastPlace[e.g] = { x = e.x, y = e.y } end
  end

  -- Next / previous screen (decision 228): every screen of the desktop, shown or hidden, by its last place (never
  -- drawn: after the others, in the order of the list of screens). The one in focus is shown (Desktop.mode); the one
  -- left goes back to its own mode
  local function moveFocus(dir)
    local list = {}
    for i, g in ipairs(SCREENS) do
      if Desktop.entry(g) then
        local p = Desktop.lastPlace[g]
        list[#list + 1] = { g = g, x = p and p.x or 1e6 + i, y = p and p.y or 1e6 }
      end
    end
    table.sort(list, byPlace)
    Desktop.focusByNav = true
    if #list == 0 then Desktop.focus = nil return end
    local at = 0
    for i, e in ipairs(list) do if e.g == Desktop.focus then at = i end end
    at = (at - 1 + dir) % #list + 1
    Desktop.focus = list[at].g
  end

  -- Left / right on the screen in focus: the gamepad D-pad or the arrows recorded (the pit stop box reads them itself)
  local function valueStep(g, dir)
    if g == 'weather' then
      Desktop.filter.weather = Desktop.filter.weather == 'map' and 'forecast' or 'map'
    elseif g == 'laps' then
      Desktop.lapsStep(dir)
    elseif g == 'relative' or g == 'standings' or g == 'map' then
      local list, seen = { 'ALL' }, {}
      for _, r in ipairs(RaceTable.rows) do
        if r.class and not seen[r.class] then seen[r.class] = true; list[#list + 1] = r.class end
      end
      local at = 1
      for i, c in ipairs(list) do if c == Desktop.filter[g] then at = i end end
      Desktop.filter[g] = list[(at - 1 + dir) % #list + 1]
    elseif g == 'laptime' then
      Desktop.setMode('delta', Desktop.mode('delta') == 'hidden' and 'visible' or 'hidden')
    end
  end
  Desktop.filter = { relative = 'ALL', standings = 'ALL', map = 'ALL', weather = 'forecast' }
  Desktop.lapsStep = function() end   -- set by the laps screen (race_screens.lua, later in the script)

  -- The D-pad acts on this screen now
  function Desktop.padFor(g)
    if Desktop.focus == nil then return g == 'pitbox' end
    return Desktop.focus == g
  end
  PitBox.padFor = Desktop.padFor

  -- Auto-hide events (decision 212): each one shows its screens for screens.autoSeconds
  Desktop.events = {}
  local last = { lap = nil, sector = nil, damage = nil, class = nil, pos = nil, closeT = 0 }
  local function pulse(k) Desktop.events[k] = state.ui.clock + config.screens.autoSeconds end
  function Desktop.recent(k) return state.ui.clock < (Desktop.events[k] or 0) end
  Desktop.close = false
  local function events(car)
    if last.lap and car.lapCount ~= last.lap then pulse('line') end
    last.lap = car.lapCount
    local sector = CarRead.num(car.currentSector)
    if last.sector and sector ~= last.sector then pulse('sector') end
    last.sector = sector
    -- Damage: grows, or its class changes (tyres and temperatures do not count: they change all the time)
    local total = (1000 - CarRead.num(car.engineLifeLeft)) / 10 + CarRead.num(car.gearboxDamage) * 100
    for i = 0, 3 do total = total + CarRead.num(car.damage[i]) + CarRead.num(car.suspensionDamage[i]) * 100 end
    if (last.damage and total > last.damage + 0.5) or (last.class and state.repair.class ~= last.class) then pulse('damage') end
    last.damage, last.class = total, state.repair.class
    local me = RaceTable.byIndex[0]
    if me and last.pos and me.pos ~= last.pos then pulse('position') end
    last.pos = me and me.pos or last.pos
    -- A car within closeGap seconds (4 times a second): the relative stays while it lasts, then autoSeconds more
    if state.ui.clock >= last.closeT then
      last.closeT = state.ui.clock + 0.25
      local close = false
      for _, r in ipairs(RaceTable.rows) do
        if r.index ~= 0 and r.connected and not r.inPit and math.abs(ac.getGapBetweenCars(0, r.index)) <= config.screens.closeGap then
          close = true
        end
      end
      if Desktop.close and not close then pulse('closeEnd') end
      Desktop.close = close
    end
  end

  -- Own buttons of the navigation (decision 212): recorded by the tool itself on any device (DirectInput button or
  -- D-pad of a wheel or button box, gamepad button, key), kept on this computer; the CSP controls binding still works.
  -- Device by its instance GUID (the same in every session; SDK). The SDK reads a button held: the press is the change
  local BIND_KEY = 'rc.nav'
  Desktop.binds = {}
  local down = {}
  local function bindSave()
    local parts = {}
    for name, b in pairs(Desktop.binds) do parts[#parts + 1] = name .. '=' .. b end
    ac.storage[BIND_KEY] = table.concat(parts, ';')
  end
  for name, b in tostring(ac.storage[BIND_KEY] or ''):gmatch('(%a+)=([^;]+)') do Desktop.binds[name] = b end
  -- Is the input of a binding held now: j:<guid>:<button>, p:<guid>:<pov>:<angle>, g:<pad>:<id>, k:<key>
  local function held(b)
    local kind, a, c, d = b:match('^(%a):([^:]*):?([^:]*):?([^:]*)$')
    if kind == 'j' or kind == 'p' then
      local j = ac.getJoystickIndexByInstanceGUID and ac.getJoystickIndexByInstanceGUID(a)
      if not j then return false end
      if kind == 'j' then return ac.isJoystickButtonPressed(j, tonumber(c)) == true end
      return ac.getJoystickDpadValue(j, tonumber(c)) == tonumber(d)
    elseif kind == 'g' then return ac.isGamepadButtonPressed(tonumber(a), tonumber(c)) == true
    elseif kind == 'k' then return ac.isKeyDown(tonumber(a)) == true end
    return false
  end
  local function bindPressed(name)
    local b = Desktop.binds[name]
    if not b then return false end
    local now = held(b)
    local was = down[name]
    down[name] = now
    return now and not was
  end
  -- Arrows (decision 217): up / down / left / right recorded by the tool like the navigation, on any device (keyboard,
  -- D-pad or button of a wheel or button box, gamepad); the keyboard arrows by default, so a driver with no D-pad can
  -- record any button. They act on the screen in focus and on the pit stop box. Cleared: 'none' (the default does not
  -- come back). Left / right held: again every 0.08 s after 0.4 s (the value rows of the box)
  -- The D-pad of any device (a POV of a wheel, button box or joystick; finding 14 of 29-30/09: "it has to work like the
  -- AC works") acts too, with nothing recorded, as the quick pit menu of the AC takes it (CSP gui.ini
  -- CONTROLLER_INTEGRATION: "use D-pad on a wheel or gamepad")
  local DIRS = { up = 'k:38', down = 'k:40', left = 'k:37', right = 'k:39' }
  local DIR_REPEAT = { left = true, right = true }
  -- Direction of a D-pad value as the AC and Content Manager read it (DirectInputPovDirection: diagonals count)
  local function povDir(v)
    v = tonumber(v) or -1
    if v < 0 then return nil end
    if v <= 4500 or v > 31500 then return 'up' elseif v <= 13500 then return 'right' elseif v <= 22500 then return 'down' end
    return 'left'
  end
  local ARROW_KEYS = { ['k:37'] = true, ['k:38'] = true, ['k:39'] = true, ['k:40'] = true }
  for name, b in pairs(DIRS) do Desktop.binds[name] = Desktop.binds[name] or b end
  local function anyPov(name)
    if not (ac.getJoystickCount and ac.getJoystickDpadsCount and ac.getJoystickDpadValue) then return false end
    for j = 0, ac.getJoystickCount() - 1 do
      for pv = 0, (ac.getJoystickDpadsCount(j) or 0) - 1 do
        if povDir(ac.getJoystickDpadValue(j, pv)) == name then return true end
      end
    end
    return false
  end
  Desktop.dir = {}
  local dirOwn = {}            -- the press of this frame came from a D-pad or a button recorded (not a keyboard arrow)
  local dirNext = {}           -- held: clock of the next repeat (math.huge = the press that recorded it)
  local function dirUpdate()
    for name in pairs(DIRS) do
      local b = Desktop.binds[name]
      local key = b and ARROW_KEYS[b] and held(b) or false
      local own = (b and not ARROW_KEYS[b] and held(b)) or anyPov(name)
      local now = key or own
      local hit = false
      if not now then dirNext[name] = nil
      elseif not dirNext[name] then dirNext[name], hit = state.ui.clock + 0.4, true
      elseif DIR_REPEAT[name] and state.ui.clock >= dirNext[name] then dirNext[name], hit = state.ui.clock + 0.08, true end
      Desktop.dir[name] = hit and not Desktop.capture
      dirOwn[name] = Desktop.dir[name] and own and true or false
    end
  end
  -- For the pit stop box (it comes before in the script: PitBox.ownDir): the D-pad and the arrow recorded, not a
  -- keyboard arrow, which the box already reads by its own buttons (CSP controls) at the pit place: one press, one step
  function Desktop.ownDir(name)
    return dirOwn[name] == true
  end
  PitBox.ownDir = Desktop.ownDir
  -- Every input held now: the snapshot of the recording (the first input that changes is the button)
  local function snapshot()
    local out = {}
    for j = 0, (ac.getJoystickCount and ac.getJoystickCount() or 0) - 1 do
      local guid = ac.getJoystickInstanceGUID(j)
      if guid then
        for bt = 0, ac.getJoystickButtonsCount(j) - 1 do
          if ac.isJoystickButtonPressed(j, bt) then out['j:' .. guid .. ':' .. bt] = true end
        end
        for pv = 0, ac.getJoystickDpadsCount(j) - 1 do
          local v = ac.getJoystickDpadValue(j, pv)
          if v and v >= 0 then out['p:' .. guid .. ':' .. pv .. ':' .. v] = true end
        end
      end
    end
    for pad = 0, 7 do
      for _, id in pairs(ac.GamepadButton) do
        if ac.isGamepadButtonPressed(pad, id) then out['g:' .. pad .. ':' .. id] = true end
      end
    end
    for key = 8, 254 do if ac.isKeyDown(key) then out['k:' .. key] = true end end
    return out
  end
  -- Conflicts (finding of 30/09: a button of the AC recorded with no complaint): a button, D-pad, gamepad button or key
  -- the AC already uses (cfg/controls.ini, SDK ac.INIConfig.controlsConfig; the format Content Manager writes: JOY and
  -- BUTTON, __CM_POV and __CM_POV_DIR (0 left, 1 up, 2 right, 3 down), the __CM_ALT_ ones, KEY with KEY_MODIFICATOR,
  -- XBOXBUTTON, the keys of [KEYBOARD]), or another command of this tool, is not recorded; the ones kept are marked
  local POV_DIR = { [0] = 'left', 'up', 'right', 'down' }
  local XBOX = { [1] = 'DPAD_UP', [2] = 'DPAD_DOWN', [4] = 'DPAD_LEFT', [8] = 'DPAD_RIGHT', [16] = 'START', [32] = 'BACK',
    [64] = 'LTHUMB_PRESS', [128] = 'RTHUMB_PRESS', [256] = 'LSHOULDER', [512] = 'RSHOULDER', [4096] = 'A', [8192] = 'B',
    [16384] = 'X', [32768] = 'Y' }
  local acUsed = nil     -- binding text of ours = AC section that uses it
  local function normGuid(g) return tostring(g or ''):gsub('[{}]', ''):upper() end
  local function loadAcUsed()
    acUsed = {}
    local ok, ini = pcall(ac.INIConfig.controlsConfig)
    if not ok or not ini or not ini.sections then return end
    local function v(sec, key)
      local t = sec[key]
      local s = type(t) == 'table' and t[1] or t
      return s and tostring(s):match('^%s*([^;%s]+)') or nil
    end
    local guids = {}
    local ctl = ini.sections.CONTROLLERS or {}
    for n = 0, 31 do
      local g = v(ctl, '__IGUID' .. n)
      if g then guids[n] = normGuid(g) end
    end
    local function num(x) return tonumber(x) end
    for name, sec in pairs(ini.sections) do
      local function joy(jKey, bKey, pKey, dKey)
        local g = guids[num(v(sec, jKey)) or -1]
        if not g then return end
        local pov = num(v(sec, pKey)) or -1
        if pov >= 0 then
          local d = POV_DIR[num(v(sec, dKey)) or 1]
          acUsed['p:' .. g .. ':' .. pov .. ':' .. d] = name
        else
          local b = num(v(sec, bKey)) or -1
          if b >= 0 then acUsed['j:' .. g .. ':' .. b] = name end
        end
      end
      joy('JOY', 'BUTTON', '__CM_POV', '__CM_POV_DIR')
      joy('__CM_ALT_JOY', '__CM_ALT_BUTTON', '__CM_ALT_POV', '__CM_ALT_POV_DIR')
      local key = num(v(sec, 'KEY'))
      if key and key > 0 and not v(sec, 'KEY_MODIFICATOR') then acUsed['k:' .. key] = name end
      local xb = v(sec, 'XBOXBUTTON')
      if xb and xb ~= '-1' then acUsed['x:' .. xb] = name end
      if name == 'KEYBOARD' then
        for k2, t in pairs(sec) do
          local kv = num(type(t) == 'table' and t[1] or t)
          if kv and kv > 0 and tostring(type(t) == 'table' and t[1] or t):find('^%s*0x') then acUsed['k:' .. kv] = 'KEYBOARD ' .. k2 end
        end
      end
    end
  end
  -- What else uses this binding: an AC function, or another command of this tool; nil = free
  local function bindUse(b, name)
    if not acUsed then loadAcUsed() end
    local kind, a, c, d = tostring(b):match('^(%a):([^:]*):?([^:]*):?([^:]*)$')
    local key = b
    if kind == 'j' then key = 'j:' .. normGuid(a) .. ':' .. c
    elseif kind == 'p' then key = 'p:' .. normGuid(a) .. ':' .. c .. ':' .. tostring(povDir(d))
    elseif kind == 'g' then key = 'x:' .. tostring(XBOX[tonumber(c) or 0]) end
    if acUsed[key] then return string.format(TEXTS.navInUseAc, acUsed[key]) end
    for other, ob in pairs(Desktop.binds) do
      if other ~= name and ob == b then return string.format(TEXTS.navInUseOwn, other) end
    end
    return nil
  end
  function Desktop.bindConflict(name)
    local b = Desktop.binds[name]
    if not b or b == 'none' then return nil end
    return bindUse(b, name)
  end

  Desktop.capture = nil      -- { name, before, untilT, conflict }: recording the button of a command
  function Desktop.startCapture(name)
    acUsed = nil       -- controls.ini read again: the driver may have changed it
    Desktop.capture = { name = name, before = snapshot(), untilT = state.ui.clock + config.screens.buttonSeconds }
  end
  function Desktop.clearBind(name) Desktop.binds[name] = DIRS[name] and 'none' or nil; bindSave() end
  -- Name of the device and the button of a binding, for the screen
  function Desktop.bindText(name)
    local b = Desktop.binds[name]
    if not b or b == 'none' then return nil end
    local kind, a, c, d = b:match('^(%a):([^:]*):?([^:]*):?([^:]*)$')
    if kind == 'j' or kind == 'p' then
      local j = ac.getJoystickIndexByInstanceGUID and ac.getJoystickIndexByInstanceGUID(a)
      local dev = j and ac.getJoystickName(j) or TEXTS.navDeviceOff
      return kind == 'j' and string.format(TEXTS.navButton, dev, tonumber(c) + 1)
        or string.format(TEXTS.navPov, dev, tonumber(d) / 100)
    elseif kind == 'g' then return string.format(TEXTS.navGamepad, tonumber(a) + 1, c)
    elseif kind == 'k' then return string.format(TEXTS.navKey, TEXTS.navKeyNames[tonumber(a)] or a) end
    return b
  end
  local function captureUpdate()
    local cap = Desktop.capture
    if not cap then return end
    if state.ui.clock > cap.untilT then Desktop.capture = nil return end
    local now = snapshot()
    for b in pairs(now) do
      local use = not cap.before[b] and bindUse(b, cap.name)
      if use then
        -- In use: not recorded; the driver is told and presses another
        cap.conflict = use
        cap.before = now
        return
      end
      if not cap.before[b] then
        Desktop.binds[cap.name] = b
        down[cap.name] = true         -- the press that recorded it does not act
        if DIRS[cap.name] then dirNext[cap.name] = math.huge end
        bindSave()
        Desktop.capture = nil
        return
      end
    end
    cap.before = now
  end

  function Desktop.update(car)
    events(car)
    captureUpdate()
    dirUpdate()
    -- Car controls (decision 219; set by the desktop editor, later in the script)
    if Desktop.controlsUpdate then Desktop.controlsUpdate(car) end
    -- The lobby window over the pits menu (set by the desktop editor)
    if Desktop.lobbyUpdate then Desktop.lobbyUpdate() end
    local nav = not Desktop.capture
    if nav and (NAV.nextDesktop:pressed() or bindPressed('nextDesktop')) then Desktop.go(1) end
    if nav and (NAV.prevDesktop:pressed() or bindPressed('prevDesktop')) then Desktop.go(-1) end
    if nav and (NAV.nextScreen:pressed() or bindPressed('nextScreen')) then moveFocus(1) end
    if nav and (NAV.prevScreen:pressed() or bindPressed('prevScreen')) then moveFocus(-1) end
    -- In the pit lane the pit stop box takes the focus
    if car.isInPitlane and Desktop.wasInPit == false then Desktop.focus, Desktop.focusByNav = 'pitbox', false end
    Desktop.wasInPit = car.isInPitlane
    local g = Desktop.focus
    if g and g ~= 'pitbox' and PitBox.PAD then
      if PitBox.PAD.left:pressed() or Desktop.dir.left then valueStep(g, -1) end
      if PitBox.PAD.right:pressed() or Desktop.dir.right then valueStep(g, 1) end
    end
  end
end
-- ============================================================
-- Screens controlled by the driver with the mouse. Groups: 'panel' (Race Control panel with the boxes below it, moved
-- together), 'pitbox' (pit stop box), 'setup' (setup status), 'status' (car status).
--   Move: click on a screen, hold and drag (move cursor, the four arrows); double click puts it back in its place.
--   Icons (smallest readable size, outside the screen, shown only with the mouse over the screen or over them):
--     one row outside the top right corner of every screen: mode (visible / auto-hide / always hidden; a click goes to
--     the next) and pin (locks the position); on the panel, before them, setup (sliders; the gear is kept for the
--     settings of the app), pit stop box and car status: a click shows that screen anywhere (visible), a click with it
--     visible goes back to auto-hide; last on the right, reset (every screen back to its place; later, the setup of the
--     screens).
--   Auto-hide = the rule of each screen (panel: something to show; setup, pit stop box and car status: in the pit lane
--   or during the stop, decision 154). The panel is also shown with the mouse over its place and stopped at the pit place, in any mode.
-- Position (offset from the default place, px at 1080p), mode and pin are kept on this computer (ac.storage).
-- ============================================================

local Drag = {}
do
  local GROUPS = { 'panel', 'pitbox', 'setup', 'status', 'laps', 'race', 'laptime', 'delta', 'relative', 'standings',
    'event', 'weather', 'map' }
  -- Mode of a screen before the driver changes it (the screens of front E, E3: laps hidden until chosen)
  local DEFAULT_MODE = { laps = 'hidden' }
  local MODES = { visible = 'auto', auto = 'hidden', hidden = 'visible' }   -- next mode on a click
  local MODE_ICON = { visible = ui.Icons.Eye, auto = ui.Icons.Ghost, hidden = ui.Icons.Hide }
  local ICON_SIZE, ICON_GAP = 12, 3            -- px at 1080p (times the screen scale)
  local ICON_COLOR = rgbm(0.85, 0.87, 0.9, 0.9)
  local ICON_ON = rgbm(1, 0.2, 0.15, 1)   -- pin on: red
  local ICON_OFF = rgbm(0.45, 0.48, 0.5, 0.8)
  local layout = {}
  for _, g in ipairs(GROUPS) do
    layout[g .. 'X'] = 0; layout[g .. 'Y'] = 0; layout[g .. 'Mode'] = DEFAULT_MODE[g] or 'auto'; layout[g .. 'Pin'] = false
  end
  local stored = ac.storage(layout, 'screen_')
  local offsets, modes, pins = {}, {}, {}
  for _, g in ipairs(GROUPS) do
    offsets[g] = vec2(tonumber(stored[g .. 'X']) or 0, tonumber(stored[g .. 'Y']) or 0)
    local m = tostring(stored[g .. 'Mode'])
    modes[g] = MODES[m] and m or (DEFAULT_MODE[g] or 'auto')
    pins[g] = stored[g .. 'Pin'] == true or stored[g .. 'Pin'] == 'true'
  end

  Drag.group = nil       -- group of the boxes being drawn now (drawPanel registers their area)
  local rects = {}       -- area of each group drawn in this frame: { min = vec2, max = vec2 }
  local zones = {}       -- area of each group with its icons (hover), this frame
  local hover = {}       -- group under the mouse in the previous frame (its icons shown)
  local buttons = {}     -- icons drawn in this frame: { p1, p2, action }
  local active           -- { group, grab = mouse - offset (px), min, max, offset (px) at the start }

  -- Offset of a group in px on this screen
  -- Offset of a group: the screens of the desktops keep it per desktop (Desktop), the panel here
  local function getOff(g) return Desktop.has(g) and Desktop.offset(g) or offsets[g] end
  local function setOff(g, v) if Desktop.has(g) then Desktop.setOffset(g, v) else offsets[g] = v end end
  local offUsed = {}    -- offset (px) each group was drawn with in this frame
  function Drag.offset(group, h)
    local o = getOff(group)
    local v = vec2(o.x * h / 1080, o.y * h / 1080)
    offUsed[group] = v
    return v
  end
  -- Area of each screen drawn in the last frame, px, with its own place without the offset (base): the desktop editor
  -- draws the cards from them, so a card is the screen as it really is on this screen
  Drag.lastRects = {}

  function Drag.mode(group) return Desktop.has(group) and Desktop.mode(group) or modes[group] end
  function Drag.setMode(group, m)
    if Desktop.has(group) then Desktop.setMode(group, m) elseif MODES[m] then modes[group] = m; stored[group .. 'Mode'] = m end
  end
  -- An area where the screens below do not take the mouse (the desktop editor)
  Drag.modal = nil
  function Drag.hovered(group) return hover[group] == true end

  local function grow(t, g, p1, p2)
    local r = t[g]
    if r then
      r.min = vec2(math.min(r.min.x, p1.x), math.min(r.min.y, p1.y))
      r.max = vec2(math.max(r.max.x, p2.x), math.max(r.max.y, p2.y))
    else
      t[g] = { min = vec2(p1.x, p1.y), max = vec2(p2.x, p2.y) }
    end
  end

  -- Area drawn by the current group (called by drawPanel)
  function Drag.hit(p1, p2)
    local g = Drag.group
    if not g then return end
    grow(rects, g, p1, p2)
    grow(zones, g, p1, p2)
  end

  -- Area of a group for the mouse even when it is not drawn (the panel shows up with the mouse over its place)
  function Drag.zone(group, p1, p2) grow(zones, group, p1, p2) end

  local function icon(id, x, y, size, color, action)
    local p1, p2 = vec2(x, y), vec2(x + size, y + size)
    ui.drawRectFilled(vec2(p1.x - 1, p1.y - 1), vec2(p2.x + 1, p2.y + 1), rgbm(0.04, 0.04, 0.05, 0.85), 2)
    ui.drawIcon(id, p1, p2, color)
    buttons[#buttons + 1] = { p1 = p1, p2 = p2, action = action }
  end

  -- Icons of a screen in one row outside its top right corner: mode and pin; on the panel, before them, the setup, pit
  -- stop box and car status icons (dim while that screen is always hidden) and, last on the right, reset. Drawn only
  -- with the mouse over the screen or over them.
  function Drag.icons(group, p1, p2, s)
    local size, gap = ICON_SIZE * s, ICON_GAP * s
    local row = {}
    if group == 'panel' then
      -- The gear: options of the tool, the desktop editor (decision 192)
      row[#row + 1] = { ui.Icons.Settings, (Desktop.menu or Desktop.editor or Audit.open or Desktop.buttons or Desktop.settingsOpen or Desktop.redOpen)
        and ICON_ON or ICON_COLOR,
        function() Desktop.menu = not Desktop.menu end }
      for _, it in ipairs({ { ui.Icons.Sliders, 'setup' }, { ui.Icons.PitStop, 'pitbox' },
          { ui.Icons.CarFront, 'status' } }) do
        row[#row + 1] = { it[1], Drag.mode(it[2]) == 'visible' and ICON_COLOR or ICON_OFF, 'show:' .. it[2] }
      end
    end
    row[#row + 1] = { MODE_ICON[Drag.mode(group)], ICON_COLOR, 'mode:' .. group }
    row[#row + 1] = { ui.Icons.Pin, pins[group] and ICON_ON or ICON_COLOR, 'pin:' .. group }
    if group == 'panel' then row[#row + 1] = { ui.Icons.Reset, ICON_COLOR, 'reset' } end
    local y = p1.y - size - gap
    local x = p2.x - #row * size - (#row - 1) * gap
    grow(zones, group, vec2(x, y), p2)
    if not hover[group] then return end
    for i, it in ipairs(row) do icon(it[1], x + (i - 1) * (size + gap), y, size, it[2], it[3]) end
  end

  local function save(g)
    stored[g .. 'Pin'] = pins[g]
    if Desktop.has(g) then Desktop.save() return end
    stored[g .. 'X'] = offsets[g].x
    stored[g .. 'Y'] = offsets[g].y
    stored[g .. 'Mode'] = modes[g]
    stored[g .. 'Pin'] = pins[g]
  end

  local function press(action)
    local what, g = action:match('^(%a+):?(%a*)$')
    if what == 'mode' then
      if Desktop.has(g) then Desktop.cycleMode(g) else modes[g] = MODES[modes[g]] end
    elseif what == 'pin' then pins[g] = not pins[g]
    elseif what == 'show' then Drag.setMode(g, Drag.mode(g) == 'visible' and 'auto' or 'visible')
    elseif what == 'reset' then
      for _, x in ipairs(GROUPS) do
        if Desktop.has(x) then
          for _, list in pairs(Desktop.place) do if list[x] then list[x].x, list[x].y = 0, 0 end end
        else offsets[x] = vec2(0, 0) end
        save(x)
      end
      return
    end
    save(g)
  end

  local function inside(m, a, b) return m.x >= a.x and m.x <= b.x and m.y >= a.y and m.y <= b.y end

  -- Top of the panel and its boxes on the screen with room for the message window (decision 213): the window goes over
  -- the panel, or under its boxes when there is no room over it, so the panel keeps Drag.panelExtra px free on one of
  -- the two sides. top, height: px; returns the top that fits
  Drag.panelExtra = 0
  function Drag.fitPanel(top, height, h)
    top = math.min(math.max(top, 0), math.max(h - height, 0))
    local extra = Drag.panelExtra
    if extra > 0 and top < extra and top + height > h - extra then
      local over, under = math.min(extra, math.max(h - height, 0)), math.max(h - extra - height, 0)
      top = (math.abs(top - over) <= math.abs(top - under)) and over or under
    end
    return top
  end

  -- Position set from outside (the desktop editor), px at 1080p; a pinned (locked) screen does not move
  function Drag.pinned(g) return pins[g] == true end
  function Drag.setOffset(g, v)
    if pins[g] then return end
    setOff(g, v)
    save(g)
  end

  -- A clickable area of a screen this frame (a chip of a filter, a button of a title): calls fn on a click
  function Drag.clickable(p1, p2, fn) buttons[#buttons + 1] = { p1 = p1, p2 = p2, action = fn } end

  -- End of the frame: icons first (hand cursor, click); then hover shows the move cursor; click, hold and drag moves
  -- the group (kept on screen; not when pinned); release keeps the place; double click puts it back
  function Drag.finish(w, h)
    Drag.group = nil
    local k = h / 1080
    local m = ui.mousePos()
    local ok = m.x >= 0
    hover = {}
    for g, z in pairs(zones) do hover[g] = ok and inside(m, z.min, z.max) end
    if active then
      local a = active
      if ui.mouseDown() then
        local nx = math.min(math.max(m.x - a.grab.x, a.o.x - a.min.x), a.o.x + w - a.max.x)
        local ny = math.min(math.max(m.y - a.grab.y, a.o.y - a.min.y), a.o.y + h - a.max.y)
        if a.group == 'panel' then
          local top = a.min.y + (ny - a.o.y)
          ny = ny + (Drag.fitPanel(top, a.max.y - a.min.y, h) - top)
        end
        setOff(a.group, vec2(nx / k, ny / k))
      else
        save(a.group)
        active = nil
      end
      ui.setMouseCursor(ui.MouseCursor.ResizeAll)
      ui.captureMouse(true)
    elseif ok then
      local done = false
      for _, b in ipairs(buttons) do
        if inside(m, b.p1, b.p2) then
          ui.setMouseCursor(ui.MouseCursor.Hand)
          ui.captureMouse(true)
          if ui.mouseClicked() then
            if type(b.action) == 'function' then b.action() else press(b.action) end
          end
          done = true
          break
        end
      end
      local modal = Drag.modal and inside(m, Drag.modal[1], Drag.modal[2])
      if not done and not modal then
        for g, r in pairs(rects) do
          if inside(m, r.min, r.max) then
            ui.captureMouse(true)
            if not pins[g] then
              ui.setMouseCursor(ui.MouseCursor.ResizeAll)
              if ui.mouseDoubleClicked() then
                setOff(g, vec2(0, 0))
                save(g)
              elseif ui.mouseClicked() then
                local o = Drag.offset(g, h)
                active = { group = g, grab = vec2(m.x - o.x, m.y - o.y), min = r.min, max = r.max, o = o }
              end
            end
            break
          end
        end
      end
    end
    -- Screens of the desktops drawn in this frame: the order of the focus (next / previous screen)
    local drawn = {}
    for g, r in pairs(rects) do if Desktop.has(g) then drawn[#drawn + 1] = { g = g, x = r.min.x, y = r.min.y } end end
    Desktop.setDrawn(drawn)
    Drag.lastRects = {}
    for g, r in pairs(rects) do
      local o = offUsed[g] or vec2(0, 0)
      Drag.lastRects[g] = { min = r.min, max = r.max, base = vec2(r.min.x - o.x, r.min.y - o.y) }
    end
    rects, zones, buttons = {}, {}, {}
    Drag.modal = nil
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

-- Width of a text in a font and size (the layout of every screen measures with it)
local function textWidth(text, font, size)
  ui.pushDWriteFont(font)
  local tw = ui.measureDWriteText(text, size).x
  ui.popDWriteFont()
  return tw
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

-- One light of a start gantry drawn as a real LED light (order of 30/09): a round light in a black housing, and inside
-- it many small LEDs in straight rows and columns (a square grid cut round), each with its glow when lit; off, the
-- LEDs stay visible, dark. c: centre, r: radius of the light
local function drawLedLight(c, r, color, lit, s)
  ui.drawCircleFilled(c, r + 1.5 * s, rgbm(0.02, 0.02, 0.025, 1), 32)
  ui.drawCircle(c, r + 1.5 * s, rgbm(0.28, 0.28, 0.3, 1), 32, 1 * s)
  if lit then ui.drawCircleFilled(c, r, rgbm(color.r, color.g, color.b, 0.18), 32) end
  local pitch = r / 4.5
  local dot = pitch * 0.3
  local n = math.ceil(r / pitch)
  for iy = -n, n do
    for ix = -n, n do
      local dx, dy = ix * pitch, iy * pitch
      if dx * dx + dy * dy <= (r - pitch * 0.45) ^ 2 then
        local p = vec2(c.x + dx, c.y + dy)
        if lit then
          ui.drawCircleFilled(p, dot * 1.9, rgbm(color.r, color.g, color.b, 0.25), 8)
          ui.drawCircleFilled(p, dot, rgbm(math.min(color.r + 0.3, 1), math.min(color.g + 0.3, 1), math.min(color.b + 0.3, 1), 1), 8)
        else
          ui.drawCircleFilled(p, dot, rgbm(color.r * 0.14, color.g * 0.14, color.b * 0.14, 1), 8)
        end
      end
    end
  end
end

-- Box with a flag drawn by the script (black flag, or black flag with orange disc) and three lines of text
-- Flag box: the flag on the left, title and two lines. Flag: black (DSQ; with disc = black flag with orange disc), or
-- 'dt' = drive-through flag, split on the diagonal from the bottom left corner to the top right one: white above,
-- black below (the game no longer shows its drive-through message); 'noentry' = wrong way: the international sign, a
-- white circle with a red border and a red horizontal bar in the middle, in the place of the flag
local function drawFlagBox(p1, p2, s, border, disc, title, titleColor, line1, line2, flag, line2Color)
  drawPanel(p1, p2, border, s)
  local f1 = vec2(p1.x + 20 * s, p1.y + 12 * s)
  local f2 = vec2(f1.x + 46 * s, f1.y + 32 * s)
  -- Flags of the flag box (flags/flags.lua, decision 206): plain colors; slippery = 4 yellow and 3 red vertical stripes,
  -- yellow at both ends; chequered = 6 x 4 squares
  local FILL = { red = rgbm(0.88, 0.09, 0.09, 1), yellow = rgbm(1, 0.83, 0, 1), blue = rgbm(0.12, 0.37, 1, 1),
    green = rgbm(0.12, 0.77, 0.23, 1), white = rgbm(0.95, 0.95, 0.95, 1) }
  local kind = type(flag) == 'string' and flag or nil
  if FILL[kind] or kind == 'slippery' or kind == 'checkered' then
    local a, b = vec2(px(f1.x), px(f1.y)), vec2(px(f2.x), px(f2.y))
    if kind == 'slippery' then
      local sw = (b.x - a.x) / 7
      for i = 0, 6 do
        ui.drawRectFilled(vec2(a.x + i * sw, a.y), vec2(a.x + (i + 1) * sw, b.y), i % 2 == 0 and FILL.yellow or FILL.red)
      end
    elseif kind == 'checkered' then
      local cw, ch = (b.x - a.x) / 6, (b.y - a.y) / 4
      ui.drawRectFilled(a, b, rgbm(0.02, 0.02, 0.02, 1))
      for r = 0, 3 do
        for c = 0, 5 do
          if (r + c) % 2 == 0 then
            ui.drawRectFilled(vec2(a.x + c * cw, a.y + r * ch), vec2(a.x + (c + 1) * cw, a.y + (r + 1) * ch), FILL.white)
          end
        end
      end
    else
      ui.drawRectFilled(a, b, FILL[kind], px(2 * s))
    end
    ui.drawRect(a, b, rgbm(0.33, 0.33, 0.33, 1), px(2 * s))
  elseif flag == 'start' then
    -- Rolling start: the board of the formation lap, a black board with two amber LED lights (the pace of the field)
    local a, b = vec2(px(f1.x), px(f1.y)), vec2(px(f2.x), px(f2.y))
    ui.drawRectFilled(a, b, rgbm(0.02, 0.02, 0.02, 1), px(2 * s))
    ui.drawRect(a, b, rgbm(0.33, 0.33, 0.33, 1), px(2 * s))
    local r = 7 * s
    for i = -1, 1, 2 do
      drawLedLight(vec2((a.x + b.x) / 2 + i * 11 * s, (a.y + b.y) / 2), r, rgbm(1, 0.62, 0.05, 1), true, s)
    end
  elseif flag == 'noentry' then
    local c, r = vec2(px((f1.x + f2.x) / 2), px((f1.y + f2.y) / 2)), 16 * s
    local red = rgbm(0.86, 0.1, 0.1, 1)
    ui.drawCircleFilled(c, r, rgbm(0.97, 0.97, 0.97, 1), 32)
    ui.drawCircle(c, r - 1.5 * s, red, 32, 3 * s)
    ui.drawRectFilled(vec2(c.x - r * 0.62, c.y - 2.5 * s), vec2(c.x + r * 0.62, c.y + 2.5 * s), red, 1 * s)
  else
    local dt = flag == 'dt'
    ui.drawRectFilled(vec2(px(f1.x), px(f1.y)), vec2(px(f2.x), px(f2.y)), rgbm(0.02, 0.02, 0.02, 1), px(2 * s))
    if dt then
      ui.drawTriangleFilled(vec2(px(f1.x), px(f1.y)), vec2(px(f2.x), px(f1.y)), vec2(px(f1.x), px(f2.y)),
        rgbm(0.95, 0.95, 0.95, 1))
    end
    ui.drawRect(vec2(px(f1.x), px(f1.y)), vec2(px(f2.x), px(f2.y)), rgbm(0.33, 0.33, 0.33, 1), px(2 * s))
    if disc then ui.drawCircleFilled(vec2(px((f1.x + f2.x) / 2), px((f1.y + f2.y) / 2)), 9 * s, disc, 24) end
  end
  local tx = f2.x + 12 * s
  drawText(title, FONT_TITLE, 14 * s, vec2(tx, p1.y + 5 * s), titleColor)
  drawText(line1 or '', FONT_TEXT, 12 * s, vec2(tx, p1.y + 23 * s), COLOR_TITLE)
  drawText(line2 or '', FONT_MONO, 12 * s, vec2(tx, p1.y + 38 * s), line2Color or COLOR_TEXT)
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
  -- Layout (decision 158): the size stays; font 11 and one gap everywhere: under the title line, between the 9 rows and
  -- the footer line, and to the bottom (10 lines of ROW_H; the rest shared by the 4 gaps)
  local BOX = { font = 11, head = 21, side = 14 }
  local BOX_RIGHT, BOX_BOTTOM = 1920 - 1397 - 288, 48
  -- Car status on its right (status_draw.lua: 171 px wide, 48 px from the right edge at 1080p) and the gap between them
  local STATUS_W, STATUS_RIGHT, STATUS_GAP = 171, 48, 1920 - 1397 - 288 - 48 - 171
  local ROW_H = 15
  local COLOR_SEL = rgbm(1, 0.85, 0.25, 1)
  local COLOR_OFF = rgbm(0.45, 0.48, 0.5, 1)
  local num = CarRead.num

  -- Wing F / R as in the setup status (WING_1 / WING_2); other setup items named WING_n are not the adjustable wings
  local function wing()
    local sp = CarRead.setupValues()
    if sp.WING_1 == '-' and sp.WING_2 == '-' then return '-' end
    return sp.WING_1 .. ' / ' .. sp.WING_2
  end

  drawPitBox = function(car, w, h, s)
    local sv = state.pitService
    -- Mode (Drag): always hidden = never; auto-hide = in the pit lane, during the stop, or for a few seconds after a
    -- D-pad press away from the pit place (decisions 154 and 159); visible = always
    local mode = Drag.mode('pitbox')
    local recent = state.ui.clock < PitBox.shownUntil
    if mode == 'hidden' or (mode == 'auto' and not car.isInPitlane and not PitBox.open and not sv and not recent) then
      return
    end
    local k = h / 1080
    local p = PitBox.plan(car)
    if sv then p.total = (sv.untilMs - sv.startMs) / 1000 end
    local names = PitBox.compounds()
    local chips = {}
    for _, wIdx in ipairs(PitBox.TYRE_CHOICES[p.tyres][2]) do chips[wIdx] = true end
    local wh = car.wheels or {}
    local rows = {
      { 'fuel', TEXTS.pitFuel, PitBox.fuelLocked() and TEXTS.pitFuelLocked
        or string.format(TEXTS.pitFuelValue, p.fuel, num(car.fuel) + p.fuel, num(car.maxFuel)), p.times.fuel,
        off = PitBox.fuelLocked() },
      { 'compound', TEXTS.pitCompound, '< ' .. tostring((ac.getTyresLongName(0, p.compound) or '') ~= ''
        and ac.getTyresLongName(0, p.compound) or names[p.compound] or '-') .. ' >', nil },
      { 'tyres', TEXTS.pitTyres, nil, p.times.tyres },
    }
    -- Pressure and wing: one row per spinner of the pit stop preset, chosen like the others (decision 201); pressure
    -- dim without tyres chosen. Without the spinners (no controller with a D-pad, M7): only shown, from the car
    local spinners = PitBox.presetSpinners()
    if #spinners > 0 then
      local count, seen = {}, {}
      for _, sp in ipairs(spinners) do count[sp.type] = (count[sp.type] or 0) + 1 end
      local tyresOn = #PitBox.TYRE_CHOICES[p.tyres][2] > 0
      for _, sp in ipairs(spinners) do
        seen[sp.type] = (seen[sp.type] or 0) + 1
        local names4 = count[sp.type] == 4 and { 'FL', 'FR', 'RL', 'RR' } or count[sp.type] == 2 and { 'F', 'R' } or nil
        local label = (sp.type == 'wing' and TEXTS.pitWing or TEXTS.pitPressure) .. ' '
          .. (names4 and names4[seen[sp.type]] or tostring(seen[sp.type]))
        local on = sp.type == 'wing' or tyresOn
        rows[#rows + 1] = { 'set:' .. sp.name, label, on and ('< ' .. tostring(PitBox.preset[sp.name] or sp.value) .. ' >')
          or tostring(sp.value), nil, off = not on }
      end
    else
      rows[#rows + 1] = { nil, TEXTS.pitPressureFront, string.format('%.1f  %.1f', num(wh[0] and wh[0].tyrePressure),
        num(wh[1] and wh[1].tyrePressure)), nil }
      rows[#rows + 1] = { nil, TEXTS.pitPressureRear, string.format('%.1f  %.1f', num(wh[2] and wh[2].tyrePressure),
        num(wh[3] and wh[3].tyrePressure)), nil }
      rows[#rows + 1] = { nil, TEXTS.pitWing, wing(), nil }
    end
    rows[#rows + 1] = { 'suspension', TEXTS.pitRepairSuspension, nil, p.times.suspension }
    rows[#rows + 1] = { 'powertrain', TEXTS.pitRepairPowertrain, nil, p.times.powertrain }
    rows[#rows + 1] = { 'body', TEXTS.pitRepairBody, nil, p.times.body }
    -- The box grows one row per row over the 9 of the approved size (decision 158: same gaps)
    local boxH = BOX_H + math.max(#rows - 9, 0) * ROW_H
    -- Width (finding 2 of 29-30/09): the approved 288 px, wider when a row does not fit (label, value, time), measured
    local fs = BOX.font * s
    local labelW = 0
    for _, r in ipairs(rows) do labelW = math.max(labelW, textWidth(r[2], FONT_TEXT, fs)) end
    local need = 0
    for _, r in ipairs(rows) do
      local vw = r[1] == 'tyres' and (3 * 26 * s + textWidth('RR', FONT_MONO, fs)) or textWidth(r[3] or TEXTS.pitRepairYes, FONT_MONO, fs)
      local tw = r[4] and (textWidth(mmss(r[4]), FONT_MONO, fs) + 12 * s) or 0
      need = math.max(need, BOX.side * s + labelW + 8 * s + vw + tw + BOX.side * s)
    end
    local bw, bh = math.max(BOX_W * s, math.ceil(need)), boxH * s
    local o = Drag.offset('pitbox', h)
    -- Its right edge never over the car status, whatever the size of both (screenScale, screens below 1080p)
    local right = math.min(w - BOX_RIGHT * k, w - STATUS_RIGHT * k - STATUS_W * s - STATUS_GAP * k)
    local p1 = vec2(math.floor(right - bw + o.x), math.floor(h - BOX_BOTTOM * k - bh + o.y))
    Drag.group = 'pitbox'
    local p2 = vec2(p1.x + bw, p1.y + bh)
    drawPanel(p1, p2, Desktop.focus == 'pitbox' and BORDER_YELLOW or BORDER_GREEN, s)
    local gap = (boxH - BOX.head - (#rows + 1) * ROW_H) / 4 * s
    drawText(TEXTS.pitBoxTitle, FONT_TITLE, 12 * s, vec2(p1.x + BOX.side * s, p1.y + 4 * s), COLOR_TITLE)
    local total = string.format(TEXTS.pitBoxTotal, mmss(p.total))
    drawTextRight(total, FONT_MONO, 11 * s, p2.x - BOX.side * s, p1.y + 5 * s, COLOR_TITLE)
    -- The order of the operations, as the key pitStopOrder has it (decision 220), before the total
    ui.pushDWriteFont(FONT_MONO)
    local tw = ui.measureDWriteText(total, 11 * s).x
    ui.popDWriteFont()
    drawTextRight(config.pitStopOrder, FONT_MONO, 11 * s, p2.x - BOX.side * s - tw - 10 * s, p1.y + 5 * s, COLOR_DIM)
    drawSeparator(p1, p2, p1.y + BOX.head * s, s)
    -- During the stop each item counts down from the authorization: its start by the order (pitStopOrder), repair
    -- groups one after the other inside R
    local left = {}
    if sv then
      local elapsed = (serverTimeMs() - sv.startMs) / 1000
      local t = p.times
      local st = PitBox.starts({ F = t.fuel, T = t.tyres, R = t.suspension + t.powertrain + t.body })
      local function remain(start, dur) return math.min(math.max(start + dur - elapsed, 0), dur) end
      left.fuel = remain(st.F or 0, t.fuel)
      left.tyres = remain(st.T or 0, t.tyres)
      local r0 = st.R or 0
      left.suspension = remain(r0, t.suspension)
      left.powertrain = remain(r0 + t.suspension, t.powertrain)
      left.body = remain(r0 + t.suspension + t.powertrain, t.body)
    end
    local chosen = PitBox.ROWS[PitBox.row]
    -- Values start after the widest row label
    local vx = p1.x + BOX.side * s + labelW + 8 * s
    local rowsTop = p1.y + BOX.head * s + gap
    for i, r in ipairs(rows) do
      local y = rowsTop + (i - 1) * ROW_H * s
      local sel = not sv and r[1] ~= nil and r[1] == chosen
      drawText(r[2], FONT_TEXT, fs, vec2(p1.x + BOX.side * s, y), (r[1] and not r.off) and COLOR_TITLE or COLOR_OFF)
      if r[1] == 'tyres' then
        for wIdx = 0, 3 do
          drawText(PitBox.WHEELS[wIdx], FONT_MONO, fs, vec2(vx + wIdx * 26 * s, y),
            chips[wIdx] and (sel and COLOR_SEL or COLOR_SWAP) or COLOR_OFF)
        end
      elseif r[1] == 'suspension' or r[1] == 'powertrain' or r[1] == 'body' then
        local value = p.repair[r[1]] and TEXTS.pitRepairYes
          or (PitBox.damaged(car, r[1]) and (PitBox.repairLocked() and TEXTS.pitRepairLocked or TEXTS.pitRepairNo)
          or TEXTS.pitRepairNone)
        drawText(value, FONT_MONO, fs, vec2(vx, y), sel and COLOR_SEL or COLOR_TITLE)
      else
        drawText(r[3], FONT_MONO, fs, vec2(vx, y), sel and COLOR_SEL or ((r[1] and not r.off) and COLOR_TITLE or COLOR_OFF))
      end
      if r[4] then
        local rest = sv and left[r[1]]
        drawTextRight(mmss(rest or r[4]), FONT_MONO, fs, p2.x - BOX.side * s, y,
          rest and rest > 0 and COLOR_SWAP or COLOR_TITLE)
      end
    end
    -- Footer under its line, the same gap to the bottom
    local sep = rowsTop + #rows * ROW_H * s + gap
    drawSeparator(p1, p2, sep, s)
    local fy = sep + gap
    local elapsed = sv and math.max(p.total - (sv.untilMs - serverTimeMs()) / 1000, 0) or 0
    -- Last line: the start mode (left changes it) and the start (right). A row that takes a choice like the others
    -- (decision 202): white, the choice color when chosen; never the dim color of the rows only shown
    local modeSel = not sv and chosen == 'mode'
    local footer = sv and TEXTS.pitBoxServing
      or string.format(TEXTS.pitBoxMode, PitBox.isAuto() and TEXTS.pitModeAuto or TEXTS.pitModeManual) .. TEXTS.pitBoxStart
    drawText(footer, FONT_TEXT, fs, vec2(p1.x + BOX.side * s, fy),
      sv and COLOR_SWAP or (modeSel and COLOR_SEL or COLOR_TITLE))
    drawTextRight(string.format('%s / %s', mmss(elapsed), mmss(p.total)), FONT_MONO, fs, p2.x - BOX.side * s, fy,
      COLOR_TITLE)
    Drag.icons('pitbox', p1, p2, s)
  end
end
-- ============================================================
-- Setup status (approved screen 14, 80%: 384 x 224 px at 1080p, bottom left, mirroring the pit stop box) and car status
-- (approved screen 12, 80%: 171 px wide at 1080p, right of the pit stop box, in the corner; height fitted to its
-- content, decision 158). Only information, shown
-- with the pit stop box. Setup values from the setup spinners (names of the setup file sections; a value the car does
-- not have shows "-"); the rest from the car state.
-- ============================================================

local drawStatus
-- Helpers kept inside this block: the whole script is one chunk, limited to 200 local variables
(function()
  local num = CarRead.num
  -- Setup status layout (approved screen 14, decisions 158, 176 and 177): the size of the approved screen (384 x 224)
  -- plus one line of the tyres band (Laps). 16 lines of SETUP.lh: 9 of the three areas (Aero and Drive train, Chassis,
  -- Suspension), 6 of the tyres band (title and compound, wheels, PSI, Life, Km, Laps), 1 of the electronics; SETUP.gap
  -- = what is left, shared by the 6 gaps (under the title line, above and under the line of the tyres band and of the
  -- electronics, to the bottom). Area titles in a larger bold font. A suspension with more lines than the other areas
  -- (heave) makes the screen taller by those lines (upwards); areas that need more than the width make it wider (to the
  -- right, clear of the pit stop box). Measures at 1080p: vertical line between the areas (colGap), value columns of
  -- the two-column areas at least valueW, gap of the front and rear pairs of the suspension (pairGap), the label column
  -- of the tyres band (tyreLabelW) and the gap of its wheel columns
  local SETUP = { font = 9.5, title = 10, lh = 12, head = 21, side = 14, colGap = 11, valueW = 22, pairGap = 7,
    tyreLabelW = 46, wheelGap = 6, rows = 9 }
  local SETUP_W, SETUP_H, SETUP_LEFT = 384, 224 + SETUP.lh, 235
  SETUP.gap = (SETUP_H - SETUP.head - 16 * SETUP.lh) / 6
  SETUP.axisColor = rgbm(0.29, 0.31, 0.33, 1)   -- F / R letters and wheel names
  -- Car status: 171 wide; height from its blocks (drawCar, decision 178)
  local STATUS_W, STATUS_RIGHT = 171, 1920 - 1701 - 171
  local MARGIN = 48
  local COLOR_OFF = rgbm(0.45, 0.48, 0.5, 1)
  local COLOR_OK = rgbm(0.45, 1, 0.55, 1)
  local COLOR_WARN = rgbm(1, 0.85, 0.25, 1)
  local WHEEL = { [0] = 'FL', 'FR', 'RL', 'RR' }

  -- Color of the tyre life, graded (no hard cut, decision 163): green at 100, yellow in the middle of the half life
  -- band, orange at its end (tyreLife worn), red at 0; between two stops the color blends
  local COLOR_COLD = rgbm(0.35, 0.65, 1, 1)
  local function blend(a, b, k)
    k = math.min(math.max(k, 0), 1)
    return rgbm(a.r + (b.r - a.r) * k, a.g + (b.g - a.g) * k, a.b + (b.b - a.b) * k, 1)
  end

  -- Color of the tyre temperature (decision 164), graded along the thermal curve of the compound: ideal green; cold
  -- side green to blue at edge %; hot side green to yellow at edge % (overheating), then yellow to red down to the
  -- lowest grip of the hot end (cliff)
  local function thermalColor(th)
    local edge = config.tyreTemp.edge
    if th.side == 'ideal' then return COLOR_OK end
    local k = (100 - th.grip) / math.max(100 - edge, 0.01)
    if th.side == 'cold' then return blend(COLOR_OK, COLOR_COLD, k) end
    if th.grip >= edge then return blend(COLOR_OK, COLOR_WARN, k) end
    return blend(COLOR_WARN, BORDER_RED, (edge - th.grip) / math.max(edge - th.hotEnd, 0.01))
  end

  local function lifeColor(life)
    local ok, worn = config.tyreLife.ok, config.tyreLife.worn
    local stops = { { 100, COLOR_OK }, { ok, COLOR_OK }, { (ok + worn) / 2, COLOR_WARN }, { worn, COLOR_ORANGE },
      { 0, BORDER_RED } }
    for n = 2, #stops do
      local a, b = stops[n - 1], stops[n]
      if life >= b[1] then
        local k = a[1] > b[1] and (a[1] - life) / (a[1] - b[1]) or 0
        return rgbm(a[2].r + (b[2].r - a[2].r) * k, a[2].g + (b[2].g - a[2].g) * k, a[2].b + (b[2].b - a[2].b) * k, 1)
      end
    end
    return BORDER_RED
  end

  -- Areas of the setup (approved screen 14, decision 177). An area is a list of items: { title = text }, or
  -- { label, { { axis, values }, ... } } with one line per axis group. Label on the left, axis (F / R, F/R) in its own
  -- column, values right-aligned in value columns at the right edge of the area: cols = 2 (the wheels of an axle; one
  -- value spans both) or 4 (the four wheels, front pair and rear pair; two values = front and rear, under the right
  -- column of each pair). The value columns are as wide as the widest value, so nothing runs into the axis
  local Area = {}

  -- Lines of an area: a line whose values are all '-' (the car does not have it) is left out; the label goes on the
  -- first line kept; an item with no line kept is left out, and a title with no item kept under it too
  function Area.rows(items)
    local rows = {}
    for _, it in ipairs(items) do
      if it.title then
        if rows[#rows] and rows[#rows].title then rows[#rows] = nil end
        rows[#rows + 1] = it
      else
        local label = it[1]
        for _, ln in ipairs(it[2]) do
          local has = false
          for _, v in ipairs(ln[2]) do if v ~= '-' then has = true end end
          if has then
            rows[#rows + 1] = { label, ln[1], ln[2] }
            label = nil
          end
        end
      end
    end
    if rows[#rows] and rows[#rows].title then rows[#rows] = nil end
    return rows
  end

  -- Measures of an area and the width it needs
  function Area.measure(rows, cols, s)
    local fs = SETUP.font * s
    local m = { rows = rows, cols = cols, gapV = 4 * s, pairGap = cols == 4 and SETUP.pairGap * s or 0,
      valueW = cols == 2 and SETUP.valueW * s or 0, labelW = 0, axisW = 0, titleW = 0 }
    for _, r in ipairs(rows) do
      if r.title then
        m.titleW = math.max(m.titleW, textWidth(r.title, FONT_TITLE, SETUP.title * s))
      else
        if r[1] then m.labelW = math.max(m.labelW, textWidth(r[1], FONT_TEXT, fs)) end
        if r[2] then m.axisW = math.max(m.axisW, textWidth(r[2], FONT_MONO, fs)) end
        for _, v in ipairs(r[3]) do
          local tw = textWidth(tostring(v), FONT_MONO, fs)
          m.valueW = math.max(m.valueW, #r[3] == 1 and (tw - (cols - 1) * m.gapV - m.pairGap) / cols or tw)
        end
      end
    end
    local span = cols * m.valueW + (cols - 1) * m.gapV + m.pairGap
    m.need = math.max(m.titleW, m.labelW + 6 * s + m.axisW + 3 * s + span)
    return m
  end

  function Area.draw(m, x1, x2, y0, lh, s)
    local fs = SETUP.font * s
    local function right(c)
      return x2 - (m.cols - c) * (m.valueW + m.gapV) - ((m.cols == 4 and c <= 2) and m.pairGap or 0)
    end
    local axisX = right(1) - m.valueW - 3 * s - m.axisW
    for n, r in ipairs(m.rows) do
      local y = y0 + (n - 1) * lh
      if r.title then
        drawText(r.title, FONT_TITLE, SETUP.title * s, vec2(x1, y - (SETUP.title - SETUP.font) * s / 2), COLOR_DIM)
      else
        if r[1] then drawText(r[1], FONT_TEXT, fs, vec2(x1, y), COLOR_OFF) end
        if r[2] then drawText(r[2], FONT_MONO, fs, vec2(axisX, y), SETUP.axisColor) end
        local vals = r[3]
        local at = #vals == 1 and { m.cols } or (#vals == 2 and m.cols == 4 and { 2, 4 }) or nil
        for i, v in ipairs(vals) do
          drawTextRight(tostring(v), FONT_MONO, fs, right(at and at[i] or i), y, COLOR_TITLE)
        end
      end
    end
  end

  -- Gear ratios of the car (decision 277): the forward gears of the physics (the ratios before them: reverse and
  -- neutral) and the final drive; nil without the physics of the car
  local function gearsOf(car)
    local ph = ac.getCarPhysics and ac.getCarPhysics(0)
    if not ph or ph.isAvailable == false or not ph.gearRatios then return nil end
    local n, fwd = #ph.gearRatios, num(car.gearCount)
    if n <= 0 or fwd <= 0 then return nil end
    local first = math.max(n - fwd, 0)
    local out = {}
    for g = 1, math.min(fwd, n) do out[g] = num(ph.gearRatios[first + g - 1]) end
    return out, num(ph.finalRatio)
  end

  local function drawSetup(car, w, h, s)
    local sp = CarRead.setupValues()
    local wh = car.wheels or {}
    local function f(fmt, v) return string.format(fmt, num(v)) end
    -- The four wheels of a setup item (LF, RF, LR, RR) and the heave of the two axles (HF, HR)
    local function four(name) return { sp[name .. 'LF'], sp[name .. 'RF'], sp[name .. 'LR'], sp[name .. 'RR'] } end
    local function heave(name) return { sp[name .. 'HF'], sp[name .. 'HR'] } end
    local T = TEXTS
    -- MGU-K of a hybrid car (decision 179), what the game gives for every car: deploy (the MGU-K delivery program, the
    -- deploy map: 1 to count), ERS (battery charge, kersCharge 0 to 1) and recovery (0 to 10 = 0 to 100%). '-' on a car
    -- without MGU-K (not shown)
    local hybrid = num(car.mgukDeliveryCount) > 0 or car.kersPresent == true
    local deploy, ers, recovery = '-', '-', '-'
    if hybrid then
      deploy = string.format('%d/%d', num(car.mgukDelivery) + 1, num(car.mgukDeliveryCount))
      ers = string.format('%.0f%%', num(car.kersCharge) * 100)
      recovery = string.format('%d%%', num(car.mgukRecovery) * 10)
    end
    local areas = {
      Area.measure(Area.rows({
        { title = T.setupAero },
        { T.setupWing, { { T.setupAxes, { sp.WING_1, sp.WING_2 } } } },
        { title = T.setupDrive },
        { T.setupDiffPower, { { nil, { f('%.0f%%', num(car.differentialPower) * 100) } } } },
        { T.setupDiffCoast, { { nil, { f('%.0f%%', num(car.differentialCoast) * 100) } } } },
        { T.setupPreload, { { nil, { f(T.setupPreloadValue, car.differentialPreload) } } } },
        -- Brake bias front / rear in one (48/52, the front first); brake migration % under it (decision 179)
        { T.setupBrakeBias, { { nil, { string.format('%.0f/%.0f', num(car.brakeBias) * 100,
          100 - num(car.brakeBias) * 100) } } } },
        -- MGU-K under the drive train (decision 179)
        { T.setupDeploy, { { nil, { deploy } } } },
        { T.setupErs, { { nil, { ers, recovery } } } },
      }), 2, s),
      Area.measure(Area.rows({
        { title = T.setupChassis },
        -- Order (decision 179): camber, toe, ARB, height, heave height
        { T.setupCamber, { { 'F', { f('%.1f', wh[0] and wh[0].camber), f('%.1f', wh[1] and wh[1].camber) } },
          { 'R', { f('%.1f', wh[2] and wh[2].camber), f('%.1f', wh[3] and wh[3].camber) } } } },
        { T.setupToe, { { 'F', { f('%.2f', wh[0] and wh[0].toeIn), f('%.2f', wh[1] and wh[1].toeIn) } },
          { 'R', { f('%.2f', wh[2] and wh[2].toeIn), f('%.2f', wh[3] and wh[3].toeIn) } } } },
        { T.setupArb, { { T.setupAxes, { sp.ARB_FRONT, sp.ARB_REAR } } } },
        { T.setupHeight, { { T.setupAxes, { sp.ROD_LENGTH_LF, sp.ROD_LENGTH_LR } } } },
        { T.setupHeaveHeight, { { T.setupAxes, { sp.ROD_LENGTH_HF, sp.ROD_LENGTH_HR } } } },
      }), 2, s),
      -- Suspension, one line per item (decision 177): the four wheels (front pair, rear pair); heave front and rear
      Area.measure(Area.rows({
        { title = T.setupSuspension },
        { T.setupSpring, { { T.setupAxes, four('SPRING_RATE_') } } },
        { T.setupBumpSlow, { { T.setupAxes, four('DAMP_BUMP_') } } },
        { T.setupReboundSlow, { { T.setupAxes, four('DAMP_REBOUND_') } } },
        { T.setupBumpFast, { { T.setupAxes, four('DAMP_FAST_BUMP_') } } },
        { T.setupReboundFast, { { T.setupAxes, four('DAMP_FAST_REBOUND_') } } },
        { T.setupHeaveSpring, { { T.setupAxes, heave('SPRING_RATE_') } } },
        { T.setupHeaveBumpSlow, { { T.setupAxes, heave('DAMP_BUMP_') } } },
        { T.setupHeaveReboundSlow, { { T.setupAxes, heave('DAMP_REBOUND_') } } },
        { T.setupHeaveBumpFast, { { T.setupAxes, heave('DAMP_FAST_BUMP_') } } },
        { T.setupHeaveReboundFast, { { T.setupAxes, heave('DAMP_FAST_REBOUND_') } } },
      }), 4, s),
    }
    -- Widths: each area what it needs plus an equal share of what is left; the screen wider when they need more
    local colGap = SETUP.colGap * s
    local inner = (SETUP_W - 2 * SETUP.side) * s - 2 * colGap
    local need, rowsTop = 0, SETUP.rows
    for _, m in ipairs(areas) do
      need = need + m.need
      rowsTop = math.max(rowsTop, #m.rows)
    end
    local extra = math.max(inner - need, 0) / 3
    local boxW = SETUP_W * s + math.max(need - inner, 0)
    local boxH = (SETUP_H + (rowsTop - SETUP.rows) * SETUP.lh) * s
    local k = h / 1080
    local o = Drag.offset('setup', h)
    local p1 = vec2(math.floor(SETUP_LEFT * k + o.x), math.floor(h - MARGIN * k - boxH + o.y))
    Drag.group = 'setup'
    local p2 = vec2(p1.x + boxW, p1.y + boxH)
    drawPanel(p1, p2, Desktop.focus == 'setup' and BORDER_YELLOW or BORDER_BASE, s)
    local fs, gap, lh = SETUP.font * s, SETUP.gap * s, SETUP.lh * s
    local x0, xr = p1.x + SETUP.side * s, p2.x - SETUP.side * s
    drawText(TEXTS.setupTitle, FONT_TITLE, 12 * s, vec2(x0, p1.y + 4 * s), COLOR_TITLE)
    drawTextRight(string.format(TEXTS.setupLap, car.lapCount + 1), FONT_MONO, 11 * s, xr, p1.y + 5 * s, COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + SETUP.head * s, s)
    local y0 = p1.y + SETUP.head * s + gap
    -- The three areas, a vertical line between them
    local ax = x0
    for i, m in ipairs(areas) do
      local aw = m.need + extra
      if i > 1 then
        local lx = math.floor(ax - colGap / 2 + 0.5)
        ui.drawSimpleLine(vec2(lx, y0), vec2(lx, y0 + rowsTop * lh - 2 * s), rgbm(1, 1, 1, 0.12), 1)
      end
      Area.draw(m, ax, ax + aw, y0, lh, s)
      ax = ax + aw + colGap
    end
    -- Tyres band, under its line (a tyre can be changed alone): title and compound fitted; the wheels on the line below;
    -- PSI, Life, Km and Laps left-aligned under the title, the values right-aligned in 4 equal wheel columns
    local sep1 = y0 + rowsTop * lh + gap
    drawSeparator(p1, p2, sep1, s)
    local ty = sep1 + gap
    -- Gear ratios (decision 277, order of 30/09): a section of their own on the left of the tyres band (the drive train
    -- area has no room in every car), the tyres pushed to the right, a vertical line between them as between the areas
    -- above: GEARS and the final drive on the title line, then the gears two by two
    local tx = x0
    local gears, final = gearsOf(car)
    if gears then
      local pairW = textWidth('8', FONT_MONO, fs) + 4 * s + textWidth('0.000', FONT_MONO, fs)
      local gw = math.max(2 * pairW + 10 * s, textWidth(TEXTS.setupGears .. '  F 0.000', FONT_MONO, fs))
      local half = gw / 2
      drawText(TEXTS.setupGears, FONT_TITLE, SETUP.title * s, vec2(x0, ty - (SETUP.title - SETUP.font) * s / 2), COLOR_DIM)
      drawTextRight(string.format('F %.3f', final), FONT_MONO, fs, x0 + gw, ty, COLOR_TITLE)
      for g, r in ipairs(gears) do
        local col, line = (g - 1) % 2, math.floor((g - 1) / 2)
        if line < 5 then
          local cx = x0 + col * (half + 5 * s)
          local gy = ty + (line + 1) * lh
          drawText(tostring(g), FONT_MONO, fs, vec2(cx, gy), SETUP.axisColor)
          drawTextRight(string.format('%.3f', r), FONT_MONO, fs, cx + half - 5 * s, gy, COLOR_TITLE)
        end
      end
      tx = x0 + gw + colGap
      local lx = math.floor(x0 + gw + colGap / 2 + 0.5)
      ui.drawSimpleLine(vec2(lx, ty), vec2(lx, ty + 6 * lh - 2 * s), rgbm(1, 1, 1, 0.12), 1)
    end
    drawText(TEXTS.setupTyres, FONT_TITLE, SETUP.title * s, vec2(tx, ty - (SETUP.title - SETUP.font) * s / 2), COLOR_DIM)
    local wx1 = tx + (SETUP.tyreLabelW + SETUP.wheelGap) * s
    drawText(tostring(ac.getTyresLongName(0, -1) or '-'), FONT_MONO, fs, vec2(wx1, ty), COLOR_TITLE)
    local wGap = SETUP.wheelGap * s
    local cw = (xr - wx1 - 3 * wGap) / 4
    for i = 0, 3 do
      local x = wx1 + (i + 1) * cw + i * wGap
      -- Remaining life by the wear curve of the compound at the virtual km of the tyre taken at the last line
      -- (CarRead.tyreLife, TyreUse), color graded green / yellow / red; without a curve, 100 - the wear of the game
      -- (tyreWear, 0 to 1) in %, white
      local life = CarRead.tyreLife(car, i, state.tyreLineKm[i] or 0)
      local color = life and lifeColor(life) or COLOR_TITLE
      life = life or (1 - num(wh[i] and wh[i].tyreWear)) * 100
      drawTextRight(WHEEL[i], FONT_MONO, fs, x, ty + lh, SETUP.axisColor)
      -- Pressure, colored by the temperature of the tyre (thermal curve of the compound); without it, white
      local th = CarRead.tyreThermal(car, i)
      drawTextRight(string.format('%.1f', num(wh[i] and wh[i].tyrePressure)), FONT_MONO, fs, x, ty + 2 * lh,
        th and thermalColor(th) or COLOR_TITLE)
      drawTextRight(string.format('%.0f%%', life), FONT_MONO, fs, x, ty + 3 * lh, color)
      -- km driven by the tyre (TyreUse; the virtual km of the game is not a distance)
      drawTextRight(string.format('%.1f', state.tyreKm[i] or 0), FONT_MONO, fs, x, ty + 4 * lh, COLOR_TITLE)
      -- Laps run / laps expected by the wear curve of the compound, colored by the phase of the curve at the km of the
      -- tyre (max grip, half life, end of life, graded as the life); without a curve, the laps run, white
      local laps = state.tyreLaps[i] or 0
      local lapLife, lapLimit = CarRead.tyreLapLimit(car, i, laps, state.tyreLineKm[i] or 0)
      drawTextRight(lapLife and string.format(TEXTS.setupLapsOf, laps, lapLimit and tostring(lapLimit) or '--')
        or tostring(laps), FONT_MONO, fs, x, ty + 5 * lh, lapLife and lifeColor(lapLife) or COLOR_TITLE)
    end
    drawText(TEXTS.setupPsi, FONT_TEXT, fs, vec2(tx, ty + 2 * lh), COLOR_OFF)
    drawText(TEXTS.setupLife, FONT_TEXT, fs, vec2(tx, ty + 3 * lh), COLOR_OFF)
    drawText(TEXTS.setupKm, FONT_TEXT, fs, vec2(tx, ty + 4 * lh), COLOR_OFF)
    drawText(TEXTS.setupLaps, FONT_TEXT, fs, vec2(tx, ty + 5 * lh), COLOR_OFF)
    -- Electronics, under its line: each name dim and its value bright; the same gap to the bottom
    local sep2 = ty + 6 * lh + gap
    drawSeparator(p1, p2, sep2, s)
    local ex = x0
    for _, e in ipairs({ { 'ABS', car.absMode }, { 'TC', car.tractionControlMode }, { 'TC2', car.tractionControl2 },
        { 'EB', car.currentEngineBrakeSetting }, { 'MAP', car.fuelMap } }) do
      drawText(e[1], FONT_MONO, fs, vec2(ex, sep2 + gap), COLOR_OFF)
      ex = ex + textWidth(e[1] .. ' ', FONT_MONO, fs)
      local v = string.format('%d', num(e[2]))
      drawText(v, FONT_MONO, fs, vec2(ex, sep2 + gap), COLOR_TITLE)
      ex = ex + textWidth(v, FONT_MONO, fs) + 9 * s
    end
    Drag.icons('setup', p1, p2, s)
  end

  -- Tile of a wheel: text and color (bent / broken / punctured / suspension damage %)
  local function wheelTile(car, i)
    local wh = car.wheels and car.wheels[i]
    if wh and wh.isBlown then return TEXTS.statusPunct, COLOR_WARN end
    local pct = CarState.suspPercent(car, i) or 0
    local toe, camber = CarState.deviation(car, i)
    if toe then
      local dev = math.max(toe, camber)
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
  -- Measures of the drawing, one table (units of s from the center of the body area)
  local F1 = {}
  F1.BODY = { -6, -36, 6, 33 }   -- { left x, top y, right x, bottom y }
  -- The nose narrows 15% in total at its tip, back to the full width where the cockpit starts (y -9.2); flat front with
  -- slightly rounded corners (radius F1.NOSE_R)
  F1.NOSE_HALF, F1.COCKPIT_Y, F1.NOSE_R = 5.1, -9.2, 1.5
  -- Plus 10% more at the tip (0.6 each side), back to nothing at the middle of the front wishbone base (y -21); in
  -- front of the tip, the radiator inlet: a white bar as thick as the steering wheel line
  F1.NOSE_EXTRA, F1.EXTRA_Y = 0.6, -21
  -- And 10% more (0.6 each side) from the front point of the front wishbone base (y -25) to the tip
  F1.NOSE_EXTRA2, F1.EXTRA2_Y = 0.6, -25
  F1.SHIFT = -4
  F1.WHEELS = { { 11.5, 17, -27, -15 }, { 10, 17, 16, 31 } }   -- { inner x, outer x, top y, bottom y }
  local function drawF1(cx, cy, s)
    local body = COLOR_TITLE
    local function P(x, y) return vec2(cx + x * s, cy + y * s) end
    -- Half width of the body at y: tapered nose, straight from the cockpit back
    local noseY = F1.BODY[2] + F1.NOSE_R
    local function half(y)
      if y >= F1.COCKPIT_Y then return F1.BODY[3] end
      local k = math.max((y - noseY) / (F1.COCKPIT_Y - noseY), 0)
      local extra = y < F1.EXTRA_Y and F1.NOSE_EXTRA * (1 - math.max((y - noseY) / (F1.EXTRA_Y - noseY), 0)) or 0
      if y < F1.EXTRA2_Y then extra = extra + F1.NOSE_EXTRA2 * (1 - math.max((y - noseY) / (F1.EXTRA2_Y - noseY), 0)) end
      return F1.NOSE_HALF + (F1.BODY[3] - F1.NOSE_HALF) * k - extra
    end
    local tip = half(noseY)
    -- Outline: flat nose with rounded corners, tapered sides (two slopes) to the cockpit, straight sides, round tail
    ui.pathArcTo(P(tip - F1.NOSE_R, noseY), F1.NOSE_R * s, 0, -math.pi / 2, 4)
    ui.pathArcTo(P(-tip + F1.NOSE_R, noseY), F1.NOSE_R * s, -math.pi / 2, -math.pi, 4)
    ui.pathLineTo(P(-half(F1.EXTRA2_Y), F1.EXTRA2_Y))
    ui.pathLineTo(P(-half(F1.EXTRA_Y), F1.EXTRA_Y))
    ui.pathLineTo(P(-F1.BODY[3], F1.COCKPIT_Y))
    ui.pathArcTo(P(0, F1.BODY[4] - F1.BODY[3]), F1.BODY[3] * s, math.pi, 0, 12)
    ui.pathLineTo(P(F1.BODY[3], F1.COCKPIT_Y))
    ui.pathLineTo(P(half(F1.EXTRA_Y), F1.EXTRA_Y))
    ui.pathLineTo(P(half(F1.EXTRA2_Y), F1.EXTRA2_Y))
    ui.pathStroke(body, true, 1)
    -- Radiator inlet: white bar on the front, as thick as the steering wheel line (1 px), almost to the corners
    local a, b = P(-tip + 0.3, F1.BODY[2]), P(tip - 0.3, F1.BODY[2])
    ui.drawRectFilled(vec2(a.x, a.y - 1), b, rgbm(1, 1, 1, 1))
    for _, wl in ipairs(F1.WHEELS) do
      local mid = (wl[3] + wl[4]) / 2
      for _, sd in ipairs({ -1, 1 }) do
        local x1, x2 = sd < 0 and -wl[2] or wl[1], sd < 0 and -wl[1] or wl[2]
        ui.drawRectFilled(P(x1, wl[3]), P(x2, wl[4]), body, 2 * s)
        ui.drawLine(P(sd * wl[1], mid), P(sd * half(mid - 4), mid - 4), body, 1)
        ui.drawLine(P(sd * wl[1], mid), P(sd * half(mid + 4), mid + 4), body, 1)
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
    -- Layout (approved screen 12, decision 178), px at 1080p: title line; WHEELS & SUSPENSION (2 x 2 tiles);
    -- hairline; POWERTRAIN (ENGINE and GEARBOX tiles, the BOP strip under them); hairline; BODY (bars and the car:
    -- 135 from its title to the bottom). Block titles as in the setup status (capitals, bold, SETUP.title)
    -- title: the block title (SETUP.title, baseline about 11 under its top) and the same 5 px gap as under the chips
    -- Fonts in the style of the pit stop box (decision 178): names Segoe SemiBold, values Consolas, 9; block titles
    -- as in the setup status (capitals, SETUP.title)
    local L = { head = 21, gap = 5, title = 16, tileH = 25, tileGap = 4, bopH = 15, side = 14, font = 9 }
    -- BODY: from its title the F bar (L.title below it, like the chips), the car, the B bar and 8 px to the bottom
    L.body = L.title + 58 + 54 + 3 + 8
    local bodyTop = L.head + L.gap + L.title + 2 * L.tileH + L.tileGap + 2 * L.gap + L.title + L.tileH + L.tileGap
      + L.bopH + 2 * L.gap
    local statusH = bodyTop + L.body
    local k = h / 1080
    local o = Drag.offset('status', h)
    local p1 = vec2(math.floor(w - STATUS_RIGHT * k - STATUS_W * s + o.x), math.floor(h - MARGIN * k - statusH * s + o.y))
    Drag.group = 'status'
    local p2 = vec2(p1.x + STATUS_W * s, p1.y + statusH * s)
    local rp = state.repair
    drawPanel(p1, p2, Desktop.focus == 'status' and BORDER_YELLOW or BORDER_BASE, s)
    drawText(TEXTS.statusTitle, FONT_TITLE, 12 * s, vec2(p1.x + L.side * s, p1.y + 4 * s), COLOR_TITLE)
    if rp.class == 'repair' then
      drawTextRight(TEXTS.statusRepair, FONT_MONO, 11 * s, p2.x - L.side * s, p1.y + 5 * s, COLOR_ORANGE)
    elseif rp.class == 'beyond' then
      drawTextRight(TEXTS.statusBeyond, FONT_MONO, 11 * s, p2.x - L.side * s, p1.y + 5 * s, BORDER_RED)
    end
    drawSeparator(p1, p2, p1.y + L.head * s, s)
    local x1, x2 = p1.x + L.side * s, p2.x - L.side * s
    local tileW = (x2 - x1 - L.tileGap * s) / 2
    local function blockTitle(text, y)
      drawText(text, FONT_TITLE, SETUP.title * s, vec2(x1, y), COLOR_DIM)
    end
    -- Tile (chip) of the approved screen: border, lamp of the state on the left, name on top and value below. The color
    -- of the state lights the lamp and the value; repair (orange) and unsafe (red) also tint the border and the inside
    local function tile(tx, ty, tw, name, value, color)
      local strong = color == COLOR_ORANGE or color == BORDER_RED
      local q1, q2 = vec2(px(tx), px(ty)), vec2(px(tx + tw), px(ty + L.tileH * s))
      if strong then ui.drawRectFilled(q1, q2, rgbm(color.r, color.g, color.b, 0.1), 3 * s) end
      local border = (strong or color == COLOR_WARN) and rgbm(color.r, color.g, color.b, 0.65) or rgbm(0.23, 0.25, 0.27, 1)
      ui.drawRect(q1, q2, border, 3 * s, nil, 1)
      ui.drawCircleFilled(vec2(px(tx + 8 * s), px(ty + L.tileH * s / 2)), 3 * s, color, 12)
      drawText(name, FONT_TEXT, L.font * s, vec2(tx + 15 * s, ty + 2 * s), COLOR_TITLE)
      drawText(value, FONT_MONO, L.font * s, vec2(tx + 15 * s, ty + 13 * s), color)
    end
    -- WHEELS & SUSPENSION: one tile per wheel
    local y = p1.y + (L.head + L.gap) * s
    blockTitle(TEXTS.statusWheels, y)
    y = y + L.title * s
    for i = 0, 3 do
      local text, color = wheelTile(car, i)
      tile(x1 + (i % 2) * (tileW + L.tileGap * s), y + math.floor(i / 2) * (L.tileH + L.tileGap) * s, tileW, WHEEL[i],
        text, color)
    end
    y = y + (2 * L.tileH + L.tileGap + L.gap) * s
    drawSeparator(p1, p2, y, s)
    y = y + L.gap * s
    -- POWERTRAIN: engine (engineLifeLeft: 1000 = whole; 0 or below = blown, the game goes under 0) and gearbox tiles
    blockTitle(TEXTS.statusPowertrain, y)
    y = y + L.title * s
    local engine = num(car.engineLifeLeft)
    tile(x1, y, tileW, TEXTS.statusEngine, engine >= 1000 and TEXTS.statusOk
      or (engine <= 0 and TEXTS.statusBrokenShort or string.format('%.0f%%', engine / 10)),
      engine >= 1000 and COLOR_OK or (engine <= 0 and BORDER_RED or COLOR_WARN))
    local gear = num(car.gearboxDamage)
    tile(x1 + tileW + L.tileGap * s, y, tileW, TEXTS.statusGearbox, gear >= 1 and TEXTS.statusBrokenShort
      or (gear > 0 and string.format('%.0f%%', (1 - gear) * 100) or TEXTS.statusOk),
      gear >= 1 and BORDER_RED or (gear > 0 and COLOR_WARN or COLOR_OK))
    y = y + (L.tileH + L.tileGap) * s
    -- BOP strip: balance of performance set by the organizer (ballast kg, restrictor %); '-' when none
    local kg, rs = num(car.ballast), num(car.restrictor)
    ui.drawRect(vec2(px(x1), px(y)), vec2(px(x2), px(y + L.bopH * s)), rgbm(0.23, 0.25, 0.27, 1), 3 * s, nil, 1)
    drawText(TEXTS.statusBop, FONT_TEXT, L.font * s, vec2(x1 + 6 * s, y + 2 * s), COLOR_TITLE)
    drawTextRight((kg == 0 and rs == 0) and '-' or string.format('%.0f kg  %.0f%%', kg, rs), FONT_MONO, L.font * s,
      x2 - 6 * s, y + 2 * s, (kg == 0 and rs == 0) and COLOR_OFF or COLOR_TITLE)
    y = y + (L.bopH + L.gap) * s
    drawSeparator(p1, p2, y, s)
    y = y + L.gap * s
    -- BODY (approved screen 12): F bar and value on top, the car outline (a 1960s F1: cigar body, wheels outside) in the
    -- middle, B value and bar at the bottom; L and R values beside the car, their bars outside them. Bar = damage of the
    -- side over the repair limit (bodyRepair); color: over the limit orange, over half yellow, some damage green
    blockTitle(TEXTS.statusBody, y)
    local limit = config.damage.bodyRepair
    local function side(i)
      local v = num(car.damage[i])
      return v, math.min(v / limit, 1),
        v > limit and COLOR_ORANGE or (v > limit / 2 and COLOR_WARN or (v > 0 and COLOR_OK or COLOR_OFF))
    end
    -- The F bar (cy - 58) L.title under the BODY title, like the chips; 8 px left under the B bar (L.body)
    local cx, cy = (p1.x + p2.x) / 2, y + (L.title + 58) * s
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
    local bf = L.font * s
    local fText, bText = string.format('F %.0f', vF), string.format('B %.0f', vB)
    drawText(fText, FONT_MONO, bf, vec2(cx - textWidth(fText, FONT_MONO, bf) / 2, cy - 53 * s), cF)
    drawText(bText, FONT_MONO, bf, vec2(cx - textWidth(bText, FONT_MONO, bf) / 2, cy + 40 * s), cB)
    hbar(cy + 54 * s, kB, cB)
    vbar(p1.x + 12 * s, kL, cL)
    drawText(string.format('L %.0f', vL), FONT_MONO, bf, vec2(p1.x + 19 * s, cy - 6 * s), cL)
    drawTextRight(string.format('R %.0f', vR), FONT_MONO, bf, p2.x - 19 * s, cy - 6 * s, cR)
    vbar(p2.x - 15 * s, kR, cR)
    drawF1(cx, cy + F1.SHIFT * s, s)
    Drag.icons('status', p1, p2, s)
  end

  -- Mode of each screen (Drag): always hidden = never; auto-hide = in the pit lane or during the stop (decision 154);
  -- visible = always
  -- Auto-hide: in the pit lane and during the stop; the car status also for screens.autoSeconds after the damage grows
  -- or changes class (decision 212)
  local function shown(group, car)
    local mode = Drag.mode(group)
    local event = group == 'status' and Desktop.recent('damage')
    return mode == 'visible' or (mode == 'auto' and (car.isInPitlane or PitBox.open or state.pitService ~= nil or event))
  end

  drawStatus = function(car, w, h, s)
    if shown('setup', car) then drawSetup(car, w, h, s) end
    if shown('status', car) then drawCar(car, w, h, s) end
  end
end)()
-- ============================================================
-- Screens of front E, E3 (decisions 190, 193; approved model "Frente E — modelo das telas", screens 3 to 8): laps of
-- the driver, race status, lap time, delta (its own screen, shown by the button next to the lap time title), relative
-- (5 above and 5 below, overall or class position by the filter) and standings. They only read (RaceTable, CarRead,
-- state): nothing is decided here. Each one is a screen of the screen control (Drag): moved, mode, pin.
-- Auto-hide (decision 212): each screen by the events of the race (line, sector, position, a car close), for
-- screens.autoSeconds; the relative while a car is within screens.closeGap seconds.
-- Colors of times: purple = best of the session, green = best of this car, red = cut or slower.
-- ============================================================

-- Helpers inside a function: the script is one chunk, limited to 200 local variables at any point
local drawRaceScreens = (function()
  local PURPLE = rgbm(0.78, 0.49, 1, 1)
  local COLOR_AXIS = rgbm(0.29, 0.31, 0.33, 1)   -- column titles (as the setup status)
  local COLOR_OFF = rgbm(0.45, 0.48, 0.5, 1)
  local LAPDOWN = rgbm(0.79, 0.73, 0.6, 1)   -- a lap behind you (decision 193: not orange)
  local GREEN = PANEL_COLORS.green
  local RED = PANEL_COLORS.red
  local BLUE = PANEL_COLORS.blue
  local YELLOW = PANEL_COLORS.yellow
  local ORANGE = rgbm(1, 0.54, 0.11, 1)
  local ROW = 13          -- px at 1080p
  local FS = 10           -- font of the rows
  -- Place of each screen at 1080p (top left) and its width; the height comes from its rows
  local PLACE = { relative = { 1572, 380, 300 }, laptime = { 1612, 640, 260 }, delta = { 860, 880, 200 },
    race = { 48, 110, 300 }, laps = { 48, 420, 330 }, standings = { 745, 560, 430 }, event = { 770, 200, 380 },
    weather = { 48, 620, 300 }, map = { 1572, 110, 300 } }
  local filter = Desktop.filter   -- ALL or a class, per screen (the D-pad on the screen in focus, or a click)

  local function lapTime(ms)
    if not ms or ms <= 0 then return '-' end
    local s = ms / 1000
    return string.format('%d:%06.3f', math.floor(s / 60), s % 60)
  end
  local function hms(ms)
    local t = math.max(math.floor((ms or 0) / 1000), 0)
    return string.format('%d:%02d:%02d', math.floor(t / 3600), math.floor(t / 60) % 60, t % 60)
  end
  local function secs(ms) return (ms and ms > 0) and string.format('%.3f', ms / 1000) or '-' end

  local function shown(g, auto)
    local m = Drag.mode(g)
    return m == 'visible' or (m == 'auto' and auto)
  end

  -- Frame of a screen: title on the left, text or chips on the right; returns p1, p2 and the y of the first row
  local function frame(g, w, h, s, rows, title, right, width)
    local pl = PLACE[g]
    local k = h / 1080
    local bw = (width or pl[3]) * s
    -- Rows start 5 px under the title line; the same visual margin under the last one (a row is 13 px for a 10 px
    -- font, so 3 px of it are already under the text)
    local bh = (26 + rows * ROW + 2) * s
    local o = Drag.offset(g, h)
    local p1 = vec2(math.floor(pl[1] * k + o.x), math.floor(pl[2] * k + o.y))
    local p2 = vec2(p1.x + bw, p1.y + bh)
    Drag.group = g
    drawPanel(p1, p2, Desktop.focus == g and BORDER_YELLOW or BORDER_BASE, s)
    drawText(title, FONT_TITLE, 12 * s, vec2(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    if right then drawTextRight(right, FONT_MONO, 11 * s, p2.x - 14 * s, p1.y + 5 * s, COLOR_TITLE) end
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    return p1, p2, p1.y + 26 * s
  end

  -- Filter chips on the title line (ALL and each class present): a click selects. More than 3 classes (decision 229):
  -- one selector, < CLASS: GT3 >, a click (or left / right on the screen in focus) passes to the next
  local function chips(g, p1, p2, s)
    local list = { 'ALL' }
    local seen = {}
    for _, r in ipairs(RaceTable.rows) do
      if r.class and not seen[r.class] then seen[r.class] = true; list[#list + 1] = r.class end
    end
    if #list > 4 then
      local t = string.format(TEXTS.scrClassSel, filter[g] or 'ALL')
      local tw = textWidth(t, FONT_MONO, 9 * s)
      local a, b = vec2(p2.x - 14 * s - tw - 6 * s, p1.y + 5 * s), vec2(p2.x - 14 * s, p1.y + 18 * s)
      ui.drawRectFilled(a, b, YELLOW, 2 * s)
      drawText(t, FONT_MONO, 9 * s, vec2(a.x + 3 * s, a.y + 1 * s), rgbm(0.07, 0.07, 0.07, 1))
      Drag.clickable(a, b, function()
        local at = 1
        for i, c in ipairs(list) do if c == filter[g] then at = i end end
        filter[g] = list[at % #list + 1]
      end)
      return
    end
    local x = p2.x - 14 * s
    for i = #list, 1, -1 do
      local t = list[i]
      local tw = textWidth(t, FONT_MONO, 9 * s)
      local a, b = vec2(x - tw - 6 * s, p1.y + 5 * s), vec2(x, p1.y + 18 * s)
      local on = filter[g] == t
      if on then ui.drawRectFilled(a, b, YELLOW, 2 * s) else ui.drawRect(a, b, rgbm(1, 1, 1, 0.3), 2 * s) end
      drawText(t, FONT_MONO, 9 * s, vec2(a.x + 3 * s, a.y + 1 * s), on and rgbm(0.07, 0.07, 0.07, 1) or COLOR_DIM)
      Drag.clickable(a, b, function() filter[g] = t end)
      x = a.x - 4 * s
    end
  end

  -- One row: cells { text, x (px at 1080p from the left), color, right-aligned, font }
  -- A value not known ('-') has no color: always the dim color
  local function row(p1, y, s, cells)
    for _, c in ipairs(cells) do
      local font = c[5] or FONT_MONO
      local col = c[1] == '-' and COLOR_OFF or (c[3] or COLOR_TITLE)
      if c[4] then drawTextRight(c[1], font, FS * s, p1.x + c[2] * s, y, col)
      else drawText(c[1], font, FS * s, vec2(p1.x + c[2] * s, y), col) end
    end
  end

  local function relativeScreen(car, w, h, s)
    local me = RaceTable.byIndex[0]
    if not me then return end
    local list = {}
    for _, r in ipairs(RaceTable.rows) do
      if r.index ~= 0 and r.connected and (filter.relative == 'ALL' or r.class == filter.relative) then
        local d = (r.spline - me.spline) % 1
        if d > 0.5 then d = d - 1 end
        list[#list + 1] = { r = r, d = d }
      end
    end
    table.sort(list, function(a, b) return a.d > b.d end)
    local above, below = {}, {}
    for _, e in ipairs(list) do if e.d > 0 then above[#above + 1] = e end end
    for _, e in ipairs(list) do if e.d <= 0 then below[#below + 1] = e end end
    local show = {}
    for i = math.min(5, #above), 1, -1 do show[#show + 1] = above[#above - i + 1] end
    show[#show + 1] = { r = me, d = 0 }
    for i = 1, math.min(5, #below) do show[#show + 1] = below[i] end
    local p1, p2, y = frame('relative', w, h, s, #show, TEXTS.scrRelative, nil)
    chips('relative', p1, p2, s)
    for _, e in ipairs(show) do
      local r = e.r
      local mine = r.index == 0
      local lapDiff = RaceTable.progress(r) - RaceTable.progress(me)
      local col = mine and YELLOW or r.inPit and COLOR_OFF or (lapDiff >= 1 and BLUE) or (lapDiff <= -1 and LAPDOWN) or COLOR_TITLE
      local pos = filter.relative == 'ALL' and ('P' .. r.pos) or ('C' .. tostring(r.classPos or '-'))
      local gap = mine and 0 or -ac.getGapBetweenCars(0, r.index)
      row(p1, y, s, {
        { pos, 36, mine and YELLOW or COLOR_DIM, true },
        { '#' .. r.number, 42, col },
        { r.name .. (r.inPit and '  PIT' or ''), 76, col, false, mine and FONT_TITLE or FONT_TEXT },
        { r.class or '', 250, COLOR_OFF, true },
        { string.format('%+.1f', gap), 286, col, true },
      })
      y = y + ROW * s
    end
    Drag.icons('relative', p1, p2, s)
  end

  local function standingsScreen(car, w, h, s)
    local list = {}
    for _, r in ipairs(RaceTable.rows) do
      if filter.standings == 'ALL' or r.class == filter.standings then list[#list + 1] = r end
    end
    -- 10 lines around your line, opening at it
    local mine = 1
    for i, r in ipairs(list) do if r.index == 0 then mine = i end end
    local first = math.max(1, math.min(mine - 4, #list - 9))
    local last = math.min(#list, first + 9)
    local p1, p2, y = frame('standings', w, h, s, last - first + 2, TEXTS.scrStandings, nil)
    chips('standings', p1, p2, s)
    row(p1, y, s, { { 'P', 32, COLOR_AXIS, true }, { 'CL', 52, COLOR_AXIS, true }, { '#', 58, COLOR_AXIS },
      { 'DRIVER', 88, COLOR_AXIS }, { 'CLASS', 214, COLOR_AXIS }, { 'LAPS', 266, COLOR_AXIS, true },
      { 'GAP', 306, COLOR_AXIS, true }, { 'INT', 346, COLOR_AXIS, true }, { 'BEST', 398, COLOR_AXIS, true },
      { 'PIT', 416, COLOR_AXIS, true } })
    y = y + ROW * s
    local leader = list[1]
    local sessionBest = CarRead.num(sim.bestLapTimeMs)
    -- Gap to a car in front: laps of difference, or the seconds
    local function gapTo(r, front)
      if not front or r == front then return '-' end
      local dl = front.laps - r.laps
      return dl >= 1 and string.format('%d L', dl) or string.format('%.1f', math.abs(ac.getGapBetweenCars(r.index, front.index)))
    end
    for i = first, last do
      local r = list[i]
      local me = r.index == 0
      local col = me and YELLOW or COLOR_TITLE
      row(p1, y, s, {
        { tostring(r.pos), 32, col, true }, { tostring(r.classPos or '-'), 52, COLOR_DIM, true },
        { '#' .. r.number, 58, col }, { r.name, 88, col, false, me and FONT_TITLE or FONT_TEXT },
        { r.class or '', 214, COLOR_OFF }, { tostring(r.laps), 266, col, true }, { gapTo(r, leader), 306, col, true },
        { gapTo(r, list[i - 1]), 346, col, true },
        { lapTime(r.best), 398, (r.best > 0 and r.best == sessionBest) and PURPLE or col, true },
        { tostring(r.stops or 0), 416, col, true },
      })
      y = y + ROW * s
    end
    Drag.icons('standings', p1, p2, s)
  end

  -- Lap time by the approved model (screen 5): current; sectors now / best / optimal; last, best, session (with the
  -- car), optimal; the delta button next to the title
  local function lapTimeScreen(car, w, h, s)
    local p1, p2, y = frame('laptime', w, h, s, 10.2, TEXTS.scrLapTime, nil)
    local on = Drag.mode('delta') ~= 'hidden'
    local a, b = vec2(p2.x - 34 * s, p1.y + 5 * s), vec2(p2.x - 14 * s, p1.y + 18 * s)
    if on then ui.drawRectFilled(a, b, YELLOW, 2 * s) else ui.drawRect(a, b, rgbm(1, 1, 1, 0.3), 2 * s) end
    drawText(TEXTS.scrDeltaButton, FONT_TEXT, 9 * s, vec2(a.x + 6 * s, a.y), on and rgbm(0.07, 0.07, 0.07, 1) or COLOR_DIM)
    Drag.clickable(a, b, function() Drag.setMode('delta', on and 'hidden' or 'auto') end)
    row(p1, y, s, { { TEXTS.scrCurrent, 14, COLOR_DIM, false, FONT_TEXT },
      { lapTime(CarRead.num(car.lapTimeMs)), 246, car.isLapValid == false and RED or COLOR_TITLE, true } })
    y = y + ROW * s
    drawSeparator(p1, p2, y + 3 * s, s)
    y = y + 8 * s
    row(p1, y, s, { { 'S1', 110, COLOR_AXIS, true }, { 'S2', 178, COLOR_AXIS, true }, { 'S3', 246, COLOR_AXIS, true } })
    y = y + ROW * s
    local lines = { { TEXTS.scrNow, car.currentSplits }, { TEXTS.scrBest, car.bestLapSplits }, { TEXTS.scrOpt, car.bestSplits } }
    for li, l in ipairs(lines) do
      local cells = { { l[1], 14, COLOR_DIM } }
      for k = 0, 2 do
        local v = l[2] and CarRead.num(l[2][k]) or 0
        local col = COLOR_TITLE
        if li == 1 and v > 0 then
          local best = car.bestSplits and CarRead.num(car.bestSplits[k]) or 0
          col = (best > 0 and v <= best) and GREEN or RED
        elseif li == 3 then col = PURPLE end
        cells[#cells + 1] = { secs(v), 110 + k * 68, col, true }
      end
      row(p1, y, s, cells)
      y = y + ROW * s
    end
    drawSeparator(p1, p2, y + 3 * s, s)
    y = y + 8 * s
    local best = CarRead.num(car.bestLapTimeMs)
    local sessionBest = CarRead.num(sim.bestLapTimeMs)
    local owner = ''
    for _, r in ipairs(RaceTable.rows) do if sessionBest > 0 and r.best == sessionBest then owner = '  #' .. r.number end end
    local optimal = 0
    for k = 0, 2 do optimal = optimal + (car.bestSplits and CarRead.num(car.bestSplits[k]) or 0) end
    -- No last lap yet: only the dash (no color, no cut)
    local lastValid = CarRead.num(car.previousLapTimeMs) <= 0 or (car.isLastLapValid ~= false and CarRead.num(car.lastLapCutsCount) == 0)
    for _, l in ipairs({
      { TEXTS.scrLast, lapTime(CarRead.num(car.previousLapTimeMs)) .. (lastValid and '' or ' cut'), lastValid and COLOR_TITLE or RED },
      { TEXTS.scrBest, lapTime(best), (best > 0 and best == sessionBest) and PURPLE or GREEN },
      { TEXTS.scrSession, sessionBest > 0 and (lapTime(sessionBest) .. owner) or '-', PURPLE },
      { TEXTS.scrOptimal, optimal > 0 and lapTime(optimal) or '-', COLOR_TITLE } }) do
      row(p1, y, s, { { l[1], 14, COLOR_DIM }, { l[2], 246, l[3], true } })
      y = y + ROW * s
    end
    Drag.icons('laptime', p1, p2, s)
  end

  -- Delta of the game (car.performanceMeter, decision 193), bar of +/- 1 s
  local function deltaScreen(car, w, h, s)
    local p1, p2, y = frame('delta', w, h, s, 1.9, TEXTS.scrDelta, TEXTS.scrVsBest)
    local d = CarRead.num(car.performanceMeter)
    local bx1, bx2 = p1.x + 14 * s, p2.x - 14 * s
    local mid = (bx1 + bx2) / 2
    ui.drawRectFilled(vec2(bx1, y), vec2(bx2, y + 7 * s), rgbm(1, 1, 1, 0.06), 2 * s)
    local f = math.min(math.abs(d), 1) * (bx2 - bx1) / 2
    if d > 0 then ui.drawRectFilled(vec2(mid, y), vec2(mid + f, y + 7 * s), RED, 2 * s)
    elseif d < 0 then ui.drawRectFilled(vec2(mid - f, y), vec2(mid, y + 7 * s), GREEN, 2 * s) end
    ui.drawSimpleLine(vec2(mid, y - 2 * s), vec2(mid, y + 9 * s), COLOR_TITLE, 1)
    y = y + 10 * s
    if car.isLapValid == false then drawText(TEXTS.scrInvalid, FONT_MONO, 9 * s, vec2(bx1, y + 2 * s), RED) end
    drawTextRight(string.format('%+.3f', d), FONT_MONO, 13 * s, bx2, y, d > 0 and RED or GREEN)
    Drag.icons('delta', p1, p2, s)
  end

  -- Track map (decision 229; map.png and data/map.ini of the track layout): the image fitted in a box, and the place of a
  -- car on it (map.ini: position in the world + offset, over the scale factor = pixel of the image)
  local Map = nil
  local function mapInfo()
    if Map ~= nil then return Map or nil end
    Map = false
    local id = ac.FolderID and ac.FolderID.CurrentTrackLayout
    if not id then return nil end
    local okF, dir = pcall(ac.getFolder, id)
    if not okF or not dir then return nil end
    local okI, ini = pcall(ac.INIConfig.load, dir .. '/data/map.ini')
    if not okI or not ini then return nil end
    local function get(k, d) local ok, v = pcall(ini.get, ini, 'PARAMETERS', k, d); return ok and tonumber(v) or d end
    local m = { image = dir .. '/map.png', w = get('WIDTH', 0), h = get('HEIGHT', 0), x = get('X_OFFSET', 0),
      z = get('Z_OFFSET', 0), scale = get('SCALE_FACTOR', 1), margin = get('MARGIN', 0) }
    if m.w <= 0 or m.h <= 0 or m.scale == 0 then return nil end
    Map = m
    return m
  end
  -- Draws the map in the box a..b (aspect kept); returns the function that turns a world position into a screen point
  local function drawMap(a, b)
    local m = mapInfo()
    if not m then return nil end
    local bw, bh = b.x - a.x, b.y - a.y
    local k = math.min(bw / m.w, bh / m.h)
    local o = vec2(a.x + (bw - m.w * k) / 2, a.y + (bh - m.h * k) / 2)
    pcall(ui.drawImage, m.image, o, vec2(o.x + m.w * k, o.y + m.h * k))
    return function(pos)
      return vec2(o.x + (pos.x + m.x) / m.scale * k, o.y + (pos.z + m.z) / m.scale * k)
    end, o, k, m
  end

  local function mapScreen(car, w, h, s)
    local p1, p2, y = frame('map', w, h, s, 16, TEXTS.scrMap, nil)
    chips('map', p1, p2, s)
    local toScreen = drawMap(vec2(p1.x + 10 * s, y), vec2(p2.x - 10 * s, p2.y - 30 * s))
    if not toScreen then
      drawText(TEXTS.scrNoMap, FONT_MONO, 9 * s, vec2(p1.x + 14 * s, y), COLOR_OFF)
    else
      local me = RaceTable.byIndex[0]
      for _, r in ipairs(RaceTable.rows) do
        local c = ac.getCar(r.index)
        if c and r.connected and (filter.map == 'ALL' or r.class == filter.map) and c.position then
          local col = r.index == 0 and YELLOW or (r.inPit and COLOR_OFF) or (CarRead.num(c.speedKmh) < 5 and RED)
            or (me and r.laps > me.laps and BLUE) or (me and r.laps < me.laps and LAPDOWN) or COLOR_TITLE
          ui.drawCircleFilled(toScreen(c.position), (r.index == 0 and 5 or 3.5) * s, col, 12)
        end
      end
    end
    -- The legend in two lines, inside the box (finding 13 of 29-30/09)
    drawText(TEXTS.scrMapLegend[1], FONT_MONO, 8.5 * s, vec2(p1.x + 14 * s, p2.y - 27 * s), COLOR_DIM)
    drawText(TEXTS.scrMapLegend[2], FONT_MONO, 8.5 * s, vec2(p1.x + 14 * s, p2.y - 15 * s), COLOR_DIM)
    Drag.icons('map', p1, p2, s)
  end

  -- Weather (decisions 169, 229): FORECAST = the line of now (SDK) and the next weather (ac.getConditionsSet), then the
  -- weather of the session hour by hour when a forecast is delivered (Weather.forecast, P-E23; with none, only now);
  -- MAP = the track map with the sky of the forecast drawn over it (clouds by the cover, rain by its intensity),
  -- animated hour by hour, 4 frames per hour at 4 Hz (Desenho E, 6.7); with no forecast only the map and "no forecast"
  -- (finding 3 of 29-30/09: no cloud is drawn without one). The game time of now in both modes (finding 9)
  local Weather = { forecast = nil }
  Desktop.weather = Weather
  local COVER = { Clear = 0, FewClouds = 0.2, ScatteredClouds = 0.4, BrokenClouds = 0.65, OvercastClouds = 0.9 }
  local function weatherName(t)
    for k, v in pairs(ac.WeatherType or {}) do if v == t then return k end end
    return nil
  end
  local function cover(name)
    if not name then return 0.3 end
    if COVER[name] then return COVER[name] end
    if name:find('Rain') or name:find('Drizzle') or name:find('Thunder') or name:find('Snow') or name:find('Sleet') then return 0.9 end
    return 0.5
  end
  local function weatherScreen(car, w, h, s)
    local mode = filter.weather or 'forecast'
    local fc = Weather.forecast or {}
    local rows = mode == 'map' and 16 or (7 + (#fc > 0 and (#fc + 2) or 0))
    local p1, p2, y = frame('weather', w, h, s, rows, TEXTS.scrWeather, nil)
    -- Local time of the track with its UTC offset (the timezone of the track: TIMEZONE_ID of the server, CSP)
    local off = nil
    if ac.getTimeZoneOffset then off = CarRead.num(ac.getTimeZoneOffset())
    elseif ac.getTrackTimezoneBaseDst then
      local ok, tz = pcall(ac.getTrackTimezoneBaseDst, sim.timestamp)
      if ok and tz then off = CarRead.num(tz.x) + CarRead.num(tz.y) end
    end
    local utc = ''
    if off then
      local m = math.floor(math.abs(off) / 60 + 0.5)
      utc = string.format(' UTC%s%d', off < 0 and '-' or '+', math.floor(m / 60)) .. (m % 60 > 0 and string.format(':%02d', m % 60) or '')
    end
    local clock = string.format('%02d:%02d', CarRead.num(sim.timeHours), CarRead.num(sim.timeMinutes)) .. utc
    if mode == 'map' then
      drawText(clock, FONT_MONO, 11 * s, vec2(p1.x + 14 * s + textWidth(TEXTS.scrWeather, FONT_TITLE, 12 * s) + 10 * s, p1.y + 5 * s),
        COLOR_TITLE)
    end
    local x = p2.x - 14 * s
    for i = 2, 1, -1 do
      local m = i == 1 and 'forecast' or 'map'
      local t = TEXTS.scrWeatherModes[m]
      local tw = textWidth(t, FONT_MONO, 9 * s)
      local a, b = vec2(x - tw - 6 * s, p1.y + 5 * s), vec2(x, p1.y + 18 * s)
      if mode == m then ui.drawRectFilled(a, b, YELLOW, 2 * s) else ui.drawRect(a, b, rgbm(1, 1, 1, 0.3), 2 * s) end
      drawText(t, FONT_MONO, 9 * s, vec2(a.x + 3 * s, a.y + 1 * s), mode == m and rgbm(0.07, 0.07, 0.07, 1) or COLOR_DIM)
      Drag.clickable(a, b, function() filter.weather = m end)
      x = a.x - 4 * s
    end
    local okC, cs = pcall(ac.getConditionsSet)
    local nowName = weatherName(sim.weatherType)
    if mode == 'map' then
      local toScreen, o, k, m = drawMap(vec2(p1.x + 10 * s, y), vec2(p2.x - 10 * s, p2.y - 18 * s))
      if not toScreen then
        drawText(TEXTS.scrNoMap, FONT_MONO, 9 * s, vec2(p1.x + 14 * s, y), COLOR_OFF)
      elseif #fc > 0 then
        -- The sky over the map: cloud cells by the cover, darker and blue with the rain (fixed pattern: the same on every
        -- client). The frames of the forecast come with it (P-E23); until then the weather of now
        local cv = cover(nowName)
        local rain = math.min(CarRead.num(sim.rainIntensity) * 2, 1)
        local cw, ch = m.w * k / 8, m.h * k / 6
        for gx = 0, 7 do
          for gy = 0, 5 do
            local seed = ((gx * 7 + gy * 13) % 10) / 10
            if seed < cv then
              local c = vec2(o.x + (gx + 0.5) * cw, o.y + (gy + 0.5) * ch)
              ui.drawCircleFilled(c, math.min(cw, ch) * 0.7, rain > 0 and rgbm(0.45, 0.55, 0.8, 0.25 + 0.3 * rain)
                or rgbm(0.85, 0.87, 0.9, 0.22), 16)
            end
          end
        end
      end
      if toScreen then ui.drawCircleFilled(toScreen(car.position), 5 * s, YELLOW, 12) end
      drawText(#fc > 0 and TEXTS.scrWeatherAnim or TEXTS.scrWeatherStatic, FONT_MONO, 8.5 * s, vec2(p1.x + 14 * s, p2.y - 15 * s),
        COLOR_DIM)
    else
      local kmhW = CarRead.num(sim.windSpeedKmh)
      local lines = {
        { TEXTS.scrWxTime, clock },
        { TEXTS.scrWxSky, nowName or '-' },
        { TEXTS.scrWxAir, string.format('%.0f / %.0f C', CarRead.num(sim.ambientTemperature), CarRead.num(sim.roadTemperature)) },
        { TEXTS.scrWxWind, string.format('%.0f km/h %03.0f deg', kmhW, CarRead.num(sim.windDirectionDeg) % 360) },
        { TEXTS.scrWxRain, string.format('%.0f%% - wet %.0f%%', CarRead.num(sim.rainIntensity) * 100, CarRead.num(sim.rainWetness) * 100) },
        { TEXTS.scrTrack, string.format('grip %.0f%%', CarRead.num(sim.roadGrip) * 100) },
        { TEXTS.scrWxNext, okC and cs and weatherName(cs.upcomingType) and string.format('%s - %.0f%%', weatherName(cs.upcomingType),
          CarRead.num(cs.transition) * 100) or '-' },
      }
      for _, l in ipairs(lines) do
        row(p1, y, s, { { l[1], 14, COLOR_DIM, false, FONT_TEXT }, { l[2], 286, COLOR_TITLE, true } })
        y = y + ROW * s
      end
      if #fc > 0 then
        drawSeparator(p1, p2, y + 3 * s, s)
        y = y + 8 * s
        row(p1, y, s, { { 'TIME', 14, COLOR_AXIS }, { 'SKY', 70, COLOR_AXIS }, { 'AIR', 220, COLOR_AXIS, true },
          { 'TRACK', 286, COLOR_AXIS, true } })
        y = y + ROW * s
        for _, f in ipairs(fc) do
          row(p1, y, s, { { f.time or '-', 14 }, { f.sky or '-', 70 }, { f.air and string.format('%.0f', f.air) or '-', 220, nil, true },
            { f.road and string.format('%.0f', f.road) or '-', 286, nil, true } })
          y = y + ROW * s
        end
      end
    end
    Drag.icons('weather', p1, p2, s)
  end

  -- Event information (decisions 222, 229): the name (key eventName), the sessions of the server, the rules from the
  -- keys (nothing typed twice). Its own screen, and on the lobby next to the column (Desktop.eventBox)
  local function eventLines()
    local out = {}
    for i = 0, (sim.sessionsCount or 0) - 1 do
      local ss = ac.getSession(i)
      if ss then
        out[#out + 1] = { TEXTS.sessionName[ss.type] or '-', ss.durationMinutes and ss.durationMinutes > 0
          and hms(ss.durationMinutes * 60000) or (ss.laps and ss.laps > 0 and string.format('%d L', ss.laps)) or '-',
          i == sim.currentSessionIndex }
      end
    end
    out[#out + 1] = false
    local st = config.driverStint
    local rules = {
      { TEXTS.evStops, config.pitStopsEnabled and tostring(config.pitStopsRequired) or '-' },
      { TEXTS.evSwaps, config.swapOn() and tostring(config.swapRequired or 0) or '-' },
      { TEXTS.evStint, (st.minMinutes > 0 or st.maxMinutes > 0) and string.format('min %d - max %d min', st.minMinutes, st.maxMinutes) or '-' },
      { TEXTS.evOrder, config.pitStopOrder },
      { TEXTS.evPitSpeed, string.format('%d km/h', config.pitSpeedLimit or 0) },
      { TEXTS.evRating, config.kmrRating.on and string.format('DSQ at %s', Audit.num(config.kmrRating.dsqAt)) or '-' },
    }
    for _, r in ipairs(rules) do out[#out + 1] = r end
    return out
  end
  local function eventDraw(p1, p2, y, s)
    for _, l in ipairs(eventLines()) do
      if l == false then
        drawSeparator(p1, p2, y + 3 * s, s)
        y = y + 8 * s
      else
        row(p1, y, s, { { l[1], 14, l[3] and YELLOW or COLOR_DIM, false, FONT_TEXT }, { l[2], 366, l[3] and YELLOW or COLOR_TITLE, true } })
        y = y + ROW * s
      end
    end
  end
  local function eventTitle() return config.eventName ~= '' and config.eventName:upper() or TEXTS.scrEvent end
  local function eventScreen(car, w, h, s)
    local n = #eventLines()
    local p1, p2, y = frame('event', w, h, s, n + 0.6, eventTitle(), TEXTS.scrEventInfo)
    eventDraw(p1, p2, y, s)
    Drag.icons('event', p1, p2, s)
  end
  -- On the lobby: right edge at pr (top right), 380 wide
  Desktop.eventBox = function(pr, s)
    local n = #eventLines()
    local p2 = vec2(pr.x, pr.y + (26 + n * ROW + 10) * s)
    local p1 = vec2(pr.x - 380 * s, pr.y)
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(eventTitle(), FONT_TITLE, 12 * s, vec2(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    drawTextRight(TEXTS.scrEventInfo, FONT_MONO, 11 * s, p2.x - 14 * s, p1.y + 5 * s, COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    eventDraw(p1, p2, p1.y + 26 * s, s)
    return p2.y
  end

  -- Laps expanded (decision 229): every stint of the car, any number of drivers (the laps of the car come from every
  -- driver: record 'laps'). Left the list of stints (driver, laps, best, average), right the laps of the one chosen;
  -- Compare picks a second stint shown next to it. The driver selector (a click or left / right on the screen in focus),
  -- up / down choose the stint; - and + fewer or more rows; the button on the title line expands and collapses
  local LapsView = { big = false, sel = nil, cmp = nil, comparing = false, driver = 'ALL', rows = 10 }
  local function stintsOf(laps)
    local stints = {}
    for _, l in ipairs(laps) do
      local cur = stints[#stints]
      if not cur or cur.driver ~= l.driver then cur = { driver = l.driver, laps = {} }; stints[#stints + 1] = cur end
      cur.laps[#cur.laps + 1] = l
    end
    for i, st in ipairs(stints) do
      st.n, st.best, st.total = i, 0, 0
      for _, l in ipairs(st.laps) do
        st.total = st.total + l.ms
        if l.valid and (st.best == 0 or l.ms < st.best) then st.best = l.ms end
      end
    end
    return stints
  end
  Desktop.lapsStep = function(dir)
    local list, seen = { 'ALL' }, {}
    for _, l in ipairs(RaceTable.laps) do
      if not seen[l.driver] then seen[l.driver] = true; list[#list + 1] = l.driver end
    end
    local at = 1
    for i, d in ipairs(list) do if d == LapsView.driver then at = i end end
    LapsView.driver = list[(at - 1 + dir) % #list + 1]
    LapsView.sel = nil
  end
  local function lapsBig(car, w, h, s)
    local all = stintsOf(RaceTable.laps)
    local stints = {}
    for _, st in ipairs(all) do if LapsView.driver == 'ALL' or st.driver == LapsView.driver then stints[#stints + 1] = st end end
    local sel = LapsView.sel and all[LapsView.sel] or stints[#stints]
    -- Up / down on the screen in focus: the stint before / after in the list
    if Desktop.focus == 'laps' and (Desktop.dir.up or Desktop.dir.down) and #stints > 0 then
      local at = #stints
      for i, st in ipairs(stints) do if st == sel then at = i end end
      at = math.min(math.max(at + (Desktop.dir.up and -1 or 1), 1), #stints)
      sel = stints[at]
      LapsView.sel = sel.n
    end
    local cmp = LapsView.cmp and all[LapsView.cmp] or nil
    local width = cmp and 760 or 600
    local n = LapsView.rows
    local p1, p2, y = frame('laps', w, h, s, n + 1.4, string.format(TEXTS.scrLapsCar, tostring(ac.getDriverNumber(0) or '')), nil, width)
    -- Title line: driver selector, compare, fewer / more rows, collapse
    local x = p2.x - 14 * s
    local function button(t, on, fn)
      local tw = textWidth(t, FONT_MONO, 9 * s)
      local a, b = vec2(x - tw - 6 * s, p1.y + 5 * s), vec2(x, p1.y + 18 * s)
      if on then ui.drawRectFilled(a, b, YELLOW, 2 * s) else ui.drawRect(a, b, rgbm(1, 1, 1, 0.3), 2 * s) end
      drawText(t, FONT_MONO, 9 * s, vec2(a.x + 3 * s, a.y + 1 * s), on and rgbm(0.07, 0.07, 0.07, 1) or COLOR_DIM)
      Drag.clickable(a, b, fn)
      x = a.x - 4 * s
    end
    button(TEXTS.scrLapsLess, false, function() LapsView.big = false end)
    button('+', false, function() LapsView.rows = math.min(LapsView.rows + 2, 30) end)
    button('-', false, function() LapsView.rows = math.max(LapsView.rows - 2, 4) end)
    button(TEXTS.scrCompare, LapsView.comparing, function()
      LapsView.comparing = not LapsView.comparing
      if not LapsView.comparing then LapsView.cmp = nil end
    end)
    button(string.format(TEXTS.scrDriverSel, LapsView.driver), true, function() Desktop.lapsStep(1) end)
    -- List of stints, newest first
    row(p1, y, s, { { '#', 14, COLOR_AXIS }, { 'DRIVER', 30, COLOR_AXIS }, { 'LAPS', 128, COLOR_AXIS, true },
      { 'BEST', 180, COLOR_AXIS, true }, { 'AVG', 228, COLOR_AXIS, true } })
    local yl = y + ROW * s
    local shown = 0
    for i = #stints, 1, -1 do
      if shown >= n then break end
      local st = stints[i]
      local on = st == sel
      local col = on and YELLOW or (st == cmp and BLUE or COLOR_TITLE)
      row(p1, yl, s, { { tostring(st.n), 14, col }, { st.driver, 30, col, false, FONT_TEXT }, { tostring(#st.laps), 128, col, true },
        { lapTime(st.best), 180, col, true }, { lapTime(#st.laps > 0 and st.total / #st.laps or 0), 228, col, true } })
      Drag.clickable(vec2(p1.x + 10 * s, yl), vec2(p1.x + 232 * s, yl + ROW * s), function()
        if LapsView.comparing and st ~= sel then LapsView.cmp = st.n else LapsView.sel = st.n end
      end)
      yl = yl + ROW * s
      shown = shown + 1
    end
    if #stints == 0 then row(p1, yl, s, { { '-', 14 } }) end
    -- Laps of the stint chosen (and of the one compared)
    local best = 0
    for _, l in ipairs(RaceTable.laps) do if l.valid and (best == 0 or l.ms < best) then best = l.ms end end
    local sessionBest = CarRead.num(sim.bestLapTimeMs)
    local function lapCells(l, x0)
      local col = not l.valid and RED or (l.ms == sessionBest and PURPLE) or (l.ms == best and GREEN) or COLOR_TITLE
      return { lapTime(l.ms), x0, col, true }, { not l.valid and 'cut' or l.pit and 'pit' or (l.ms == best and 'best')
        or string.format('%+.3f', (l.ms - best) / 1000), x0 + 50, not l.valid and RED or (l.ms == best and GREEN) or RED, true }
    end
    local head = { { 'LAP', 246, COLOR_AXIS }, { 'TIME', 336, COLOR_AXIS, true }, { 'DELTA', 386, COLOR_AXIS, true },
      { 'S1', 434, COLOR_AXIS, true }, { 'S2', 482, COLOR_AXIS, true }, { 'S3', 530, COLOR_AXIS, true } }
    if cmp then
      head[#head + 1] = { string.format(TEXTS.scrStintShort, cmp.n), 640, BLUE, true }
      head[#head + 1] = { 'DELTA', 690, COLOR_AXIS, true }
    end
    row(p1, y, s, head)
    local yr = y + ROW * s
    if sel then
      local first = math.max(#sel.laps - n + 1, 1)
      for k = #sel.laps, first, -1 do
        local l = sel.laps[k]
        local t, d = lapCells(l, 336)
        local cells = { { tostring(l.lap) .. (l.pit and ' P' or ''), 246, l.pit and YELLOW or COLOR_TITLE }, t, d }
        for q = 1, 3 do cells[#cells + 1] = { secs(l.s and l.s[q]), 386 + q * 48, COLOR_TITLE, true } end
        local cl = cmp and cmp.laps[k] or nil
        if cl then
          local ct, cd = lapCells(cl, 640)
          cells[#cells + 1] = ct
          cells[#cells + 1] = cd
        end
        row(p1, yr, s, cells)
        yr = yr + ROW * s
      end
    end
    Drag.icons('laps', p1, p2, s)
  end

  -- Laps by the approved model (screen 3): the current stint (number, driver, laps, time / minimum) with its laps; the
  -- stint before, closed (best and average); the best lap of the car and its driver
  local function lapsScreen(car, w, h, s)
    if LapsView.big then return lapsBig(car, w, h, s) end
    local laps = RaceTable.laps
    local sessionBest = CarRead.num(sim.bestLapTimeMs)
    local driver = tostring(ac.getDriverName(0) or ''):gsub('[,;|]', ' ')
    -- Stints: consecutive laps of the same driver
    local stints = {}
    for _, l in ipairs(laps) do
      local cur = stints[#stints]
      if not cur or cur.driver ~= l.driver then cur = { driver = l.driver, laps = {} }; stints[#stints + 1] = cur end
      cur.laps[#cur.laps + 1] = l
    end
    if not stints[#stints] or stints[#stints].driver ~= driver then stints[#stints + 1] = { driver = driver, laps = {} } end
    local now, prev = stints[#stints], stints[#stints - 1]
    local best, bestDriver = 0, '-'
    for _, l in ipairs(laps) do if l.valid and (best == 0 or l.ms < best) then best, bestDriver = l.ms, l.driver end end
    local n = math.min(#now.laps, 8)
    local p1, p2, y = frame('laps', w, h, s, 2.5 + n + (prev and 2.6 or 0) + 1.6, TEXTS.scrLaps, nil)
    -- Lap number and the button that expands (decision 229)
    local et = TEXTS.scrLapsMore
    local etw = textWidth(et, FONT_MONO, 9 * s)
    local ea, eb = vec2(p2.x - 14 * s - etw - 6 * s, p1.y + 5 * s), vec2(p2.x - 14 * s, p1.y + 18 * s)
    ui.drawRect(ea, eb, rgbm(1, 1, 1, 0.3), 2 * s)
    drawText(et, FONT_MONO, 9 * s, vec2(ea.x + 3 * s, ea.y + 1 * s), COLOR_DIM)
    Drag.clickable(ea, eb, function() LapsView.big = true end)
    drawTextRight(string.format(TEXTS.scrLapN, car.lapCount + 1), FONT_MONO, 11 * s, ea.x - 8 * s, p1.y + 5 * s, COLOR_TITLE)
    local function sum(list) local t = 0; for _, l in ipairs(list) do t = t + l.ms end; return t end
    -- Current stint
    local ms = RaceTable.stintMs() or sum(now.laps)
    local rule = config.driverStint
    local stintCol = (rule.minMinutes <= 0) and COLOR_DIM or (ms < rule.minMinutes * 60000 and YELLOW)
      or ((rule.maxMinutes > 0 and ms > rule.maxMinutes * 60000) and RED) or GREEN
    drawText(string.format(TEXTS.scrStintN, #stints, now.driver), FONT_TITLE, 10.5 * s, vec2(p1.x + 14 * s, y), COLOR_DIM)
    drawTextRight(string.format(TEXTS.scrStintInfo, #now.laps, hms(ms)) .. (rule.minMinutes > 0 and
      string.format(TEXTS.scrStintMin, rule.minMinutes) or ''), FONT_MONO, 10 * s, p2.x - 14 * s, y, stintCol)
    y = y + ROW * 1.5 * s
    row(p1, y, s, { { 'LAP', 14, COLOR_AXIS }, { 'TIME', 118, COLOR_AXIS, true }, { 'DELTA', 172, COLOR_AXIS, true },
      { 'S1', 220, COLOR_AXIS, true }, { 'S2', 268, COLOR_AXIS, true }, { 'S3', 316, COLOR_AXIS, true } })
    y = y + ROW * s
    for k = #now.laps, #now.laps - n + 1, -1 do
      local l = now.laps[k]
      local col = not l.valid and RED or (l.ms == sessionBest and PURPLE) or (l.ms == best and GREEN) or COLOR_TITLE
      local cells = { { tostring(l.lap) .. (l.pit and ' P' or ''), 14, l.pit and YELLOW or COLOR_TITLE },
        { lapTime(l.ms), 118, col, true },
        { not l.valid and 'cut' or l.pit and 'pit' or (l.ms == best and 'best') or string.format('%+.3f', (l.ms - best) / 1000),
          172, not l.valid and RED or (l.ms == best and GREEN) or (l.pit and COLOR_DIM) or RED, true } }
      for q = 1, 3 do cells[#cells + 1] = { secs(l.s[q]), 172 + q * 48, COLOR_TITLE, true } end
      row(p1, y, s, cells)
      y = y + ROW * s
    end
    -- The stint before, closed
    if prev then
      drawSeparator(p1, p2, y + 3 * s, s)
      y = y + 8 * s
      local pb, total = 0, 0
      for _, l in ipairs(prev.laps) do
        total = total + l.ms
        if l.valid and (pb == 0 or l.ms < pb) then pb = l.ms end
      end
      drawText(string.format(TEXTS.scrStintN, #stints - 1, prev.driver), FONT_TITLE, 10.5 * s, vec2(p1.x + 14 * s, y), COLOR_DIM)
      drawTextRight(string.format(TEXTS.scrStintInfo, #prev.laps, hms(total)), FONT_MONO, 10 * s, p2.x - 14 * s, y, COLOR_DIM)
      y = y + ROW * s
      row(p1, y, s, { { string.format(TEXTS.scrBestAvg, lapTime(pb), lapTime(#prev.laps > 0 and total / #prev.laps or 0)), 14,
        COLOR_DIM } })
      y = y + ROW * 1.6 * s
    end
    -- Best lap of the car and who drove it
    drawSeparator(p1, p2, y + 3 * s, s)
    y = y + 8 * s
    row(p1, y, s, { { TEXTS.scrCarBest, 14, COLOR_DIM }, { best > 0 and (lapTime(best) .. ' (' .. bestDriver .. ')') or '-', 316,
      (best > 0 and best == sessionBest) and PURPLE or GREEN, true } })
    Drag.icons('laps', p1, p2, s)
  end

  -- Race status by the approved model (screen 4, decision 211): session lines; GAPS; OBLIGATIONS in 2 x 2 chips with
  -- the state light; tyres, track and pending; the KMR points (decision 210) and safety rating (decision 215).
  -- A chip with nothing to check (nothing required: 0 stops, 0 swaps, no stint limit) is grey, count shown (decision 216)
  -- Style of the screens (finding of 30/09: the screen got tight when the KMR lines came in): rows of ROW with the row
  -- font, a category with its own line, the same margin before and after each separator, chips with room for their
  -- two lines
  local CHIP_H, CHIP_GAP, SEP = 30, 6, 10
  local function chip2(p, wdt, s, title, value, light)
    local a, b = vec2(p.x, p.y), vec2(p.x + wdt, p.y + CHIP_H * s)
    ui.drawRect(a, b, rgbm(1, 1, 1, 0.2), 3 * s)
    ui.drawCircleFilled(vec2(a.x + 10 * s, a.y + CHIP_H * s / 2), 3 * s, light, 12)
    drawText(title, FONT_TITLE, 9 * s, vec2(a.x + 19 * s, a.y + 3 * s), COLOR_TITLE)
    drawText(value, FONT_MONO, FS * s, vec2(a.x + 19 * s, a.y + 15 * s), value == '-' and COLOR_OFF or light)
  end
  local function raceScreen(car, w, h, s)
    local me = RaceTable.byIndex[0]
    local session = ac.getSession(sim.currentSessionIndex)
    -- Height: 3 rows, a category and 3 gap rows, a category and 2 rows of chips, 5 rows, the 3 separators
    local content = 3 * ROW + SEP + ROW + 3 * ROW + SEP + ROW + 2 * CHIP_H + CHIP_GAP + 4 + SEP + 5 * ROW + 4
    local p1, p2, y = frame('race', w, h, s, content / ROW, TEXTS.scrRace, TEXTS.sessionName[sim.raceSessionType] or '')
    local x0, xr = p1.x + 14 * s, p2.x - 14 * s
    local function line(label, value, color)
      row(p1, y, s, { { label, 14, COLOR_DIM, false, FONT_TEXT }, { value, 286, color or COLOR_TITLE, true } })
      y = y + ROW * s
    end
    local function sep()
      drawSeparator(p1, p2, y + (SEP / 2 - 2) * s, s)
      y = y + SEP * s
    end
    local total = session and session.durationMinutes > 0 and hms(session.durationMinutes * 60000)
      or (session and session.laps > 0 and string.format('%d L', session.laps)) or nil
    line(TEXTS.scrTime, hms(sessionElapsedMs()) .. (total and (' / ' .. total) or ''))
    line(TEXTS.scrPosition, me and (('P' .. me.pos) .. (me.class and string.format(' - class P%d %s', me.classPos, me.class)
      or '')) or '-')
    line(TEXTS.scrLap, tostring(me and me.laps + 1 or car.lapCount + 1))
    sep()
    -- GAPS: leader, ahead, behind (standings order)
    drawText(TEXTS.scrGaps, FONT_TITLE, 9 * s, vec2(x0, y), COLOR_DIM)
    y = y + ROW * s
    local rows = RaceTable.rows
    local function gapRow(label, r)
      local gap = '-'
      if me and r and r ~= me then
        local dl = math.abs(r.laps - me.laps)
        local g = ac.getGapBetweenCars(0, r.index)
        gap = dl >= 1 and string.format('+%d L', dl) or string.format('%+.3f', -g)
      end
      row(p1, y, s, { { label, 14, COLOR_DIM, false, FONT_TEXT }, { r and r ~= me and ('#' .. r.number) or '-', 90 },
        { gap, 272, COLOR_TITLE, true } })
      y = y + ROW * s
    end
    gapRow(TEXTS.scrLeader, rows[1])
    gapRow(TEXTS.scrAhead, me and rows[me.pos - 1])
    gapRow(TEXTS.scrBehind, me and rows[me.pos + 1])
    sep()
    -- OBLIGATIONS: 2 x 2 chips with the state light
    drawText(TEXTS.scrObligations, FONT_TITLE, 9 * s, vec2(x0, y), COLOR_DIM)
    y = y + ROW * s
    local cw = (p2.x - p1.x - 28 * s - CHIP_GAP * s) / 2
    local req = config.pitStopsRequired
    local stops = config.pitStopsEnabled and string.format('%d / %d', PitRecord.stops, req) or '-'
    local stopsLight = (not config.pitStopsEnabled or req <= 0) and COLOR_OFF or (PitRecord.stops >= req and GREEN or YELLOW)
    local swapReq = config.swapOn() and config.swapRequired
    local swaps = swapReq and string.format('%d / %d', SwapRecord.validNow(), swapReq) or '-'
    local swapsLight = (not swapReq or swapReq <= 0) and COLOR_OFF or (SwapRecord.validNow() >= swapReq and GREEN or YELLOW)
    local pit = Panel.cellPit()
    local pitLight = not pit and COLOR_OFF or (pit.color == 'red' and RED or pit.color == 'yellow' and YELLOW or GREEN)
    local ms = RaceTable.stintMs()
    local rule = config.driverStint
    local stint = ms and (mmss(ms / 1000) .. (rule.minMinutes > 0 and string.format(' / min %d', rule.minMinutes) or '')) or '-'
    local stintLight = (not ms or (rule.minMinutes <= 0 and rule.maxMinutes <= 0)) and COLOR_OFF
      or (rule.minMinutes > 0 and ms < rule.minMinutes * 60000 and YELLOW)
      or ((rule.maxMinutes > 0 and ms > rule.maxMinutes * 60000) and RED) or GREEN
    local cy = (CHIP_H + CHIP_GAP) * s
    chip2(vec2(x0, y), cw, s, TEXTS.scrStops, stops, stopsLight)
    chip2(vec2(x0 + cw + CHIP_GAP * s, y), cw, s, TEXTS.scrSwaps, swaps, swapsLight)
    chip2(vec2(x0, y + cy), cw, s, TEXTS.scrWindow, pit and pit.value or '-', pitLight)
    chip2(vec2(x0 + cw + CHIP_GAP * s, y + cy), cw, s, TEXTS.scrStintLine, stint, stintLight)
    y = y + (2 * CHIP_H + CHIP_GAP + 4) * s
    sep()
    -- Tyres, track, pending, KMR points and safety rating
    local life = CarRead.tyreLife(car, 0, state.tyreLineKm[0] or 0)
    local wet = CarRead.num(sim.rainWetness) > 0.05
    local pen = Panel.cellPenalties()
    local kmr = Audit.points and string.format('%d / %d', Audit.points, config.kmrPoints.limit) or '-'
    local rt = config.kmrRating
    local rating = Audit.rating and Audit.num(Audit.rating) or '-'
    for _, l in ipairs({
      { TEXTS.scrTyres, string.format('%d laps%s', state.tyreLaps[0] or 0, life and string.format(' - %d%%', math.floor(life)) or '') },
      { TEXTS.scrTrack, string.format('%s - grip %d%%', wet and 'WET' or 'DRY', math.floor(CarRead.num(sim.roadGrip) * 100)) },
      { TEXTS.scrPending, pen and pen.value or '-', pen and ORANGE },
      { TEXTS.scrKmr, kmr, Audit.points and Audit.points >= config.kmrPoints.limit * 0.8 and RED or nil },
      { TEXTS.scrKmrRating, rating, rt.on and Audit.rating and Audit.rating <= rt.dsqAt and RED or nil } }) do
      row(p1, y, s, { { l[1], 14, COLOR_DIM, false, FONT_TEXT }, { l[2], 286, l[3] or COLOR_TITLE, true } })
      y = y + ROW * s
    end
    Drag.icons('race', p1, p2, s)
  end

  return function(car, w, h, s)
    -- Auto-hide by the events of the race (decision 212)
    local line, sector = Desktop.recent('line'), Desktop.recent('sector')
    if shown('race', car.isInPitlane or line) then raceScreen(car, w, h, s) end
    if shown('laps', line) then lapsScreen(car, w, h, s) end
    if shown('standings', line or Desktop.recent('position')) then standingsScreen(car, w, h, s) end
    if shown('relative', Desktop.close or Desktop.recent('closeEnd') or line) then relativeScreen(car, w, h, s) end
    if shown('laptime', line or sector) then lapTimeScreen(car, w, h, s) end
    if shown('delta', sector) then deltaScreen(car, w, h, s) end
    -- Screens of the second round (decision 229): by their mode only (auto-hide: the event in the pit lane, the
    -- weather at the line, the map with a car close)
    if shown('event', car.isInPitlane) then eventScreen(car, w, h, s) end
    if shown('weather', line) then weatherScreen(car, w, h, s) end
    if shown('map', Desktop.close or line) then mapScreen(car, w, h, s) end
  end
end)()
-- ============================================================
-- Desktop editor (front E, E4; decisions 191, 192, 199; approved model, screen 10), opened by the gear of the Race
-- Control panel, with the mouse (decision 204): tabs of the desktops (+ adds one) and the pit desktop; the canvas is
-- the screen in small: a card per screen, dragged to its place; on each card: pin to all desktops, mode (V visible,
-- A auto-hide, H hidden), X removes it; the list on the right adds or removes a screen on the desktop being edited;
-- reset, copy from desktop 1, delete; pit desktop on / off (off: at the driver's own risk). The Race Control panel is
-- fixed on every desktop (locked card). The navigation buttons are set in the CSP controls (Race Control).
-- Desktop indicator: 2 s after changing the desktop, above the panel.
-- ============================================================

-- Helpers inside a function: the script is one chunk, limited to 200 local variables at any point
local drawDesktopUI = (function()
  local W = 660                        -- editor width, px at 1080p (the height comes from its content)
  local CANVAS_W = 422                 -- canvas width, px at 1080p (its height has the shape of the screen)
  -- Own place and size of each screen at 1080p (with no offset): only to draw the cards
  local RECT = { pitbox = { 1397, 837, 288, 195 }, setup = { 48, 772, 474, 260 }, status = { 1701, 718, 171, 314 },
    race = { 48, 110, 300, 190 }, laps = { 48, 420, 330, 160 }, standings = { 745, 560, 430, 180 },
    relative = { 1572, 380, 300, 180 }, laptime = { 1612, 640, 260, 150 }, delta = { 830, 860, 260, 70 },
    event = { 770, 200, 380, 160 }, weather = { 48, 620, 300, 110 }, map = { 1572, 110, 300, 240 } }
  local MODE_ICON = { visible = ui.Icons.Eye, auto = ui.Icons.Ghost, hidden = ui.Icons.Hide }   -- as the screen icons
  local MODE_NEXT = { visible = 'auto', auto = 'hidden', hidden = 'visible' }
  local drag = nil                      -- card being dragged: { g, entry, dx, dy }
  -- Windows of the tool (editor, Audit, Buttons) move by their title line (decision 213): offset from the middle of the
  -- screen, px at 1080p, kept on this computer (ac.storage 'rc.win.<id>'); always inside the screen
  local moving = nil                    -- { id, grab } window being moved
  local sizing = nil                    -- { id, m0, W0, H0, x, y } window being resized by its corner
  -- resizable: the window takes a size of its own (W, H at scale 1, kept on this computer, 'rc.winsz.<id>') by the grip
  -- of its bottom right corner (the director's report, order of 29/09: "precisa permitir expandir a tela"); W, H given
  -- are the smallest. Returns p1, p2 and the size in use
  local function windowAt(id, W, H, w, h, s, resizable)
    local k = h / 1080
    local ox, oy = tostring(ac.storage['rc.win.' .. id] or ''):match('^(%-?[%d%.]+),(%-?[%d%.]+)$')
    local o = vec2((tonumber(ox) or 0) * k, (tonumber(oy) or 0) * k)
    local m = ui.mousePos()
    if resizable then
      local sw, sh = tostring(ac.storage['rc.winsz.' .. id] or ''):match('^([%d%.]+),([%d%.]+)$')
      local minW, minH = W, H
      W, H = math.max(tonumber(sw) or W, minW), math.max(tonumber(sh) or H, minH)
      if sizing and sizing.id == id then
        if ui.mouseDown() then
          W = math.min(math.max(sizing.W0 + (m.x - sizing.m0.x) / s, minW), (w - sizing.x) / s)
          H = math.min(math.max(sizing.H0 + (m.y - sizing.m0.y) / s, minH), (h - sizing.y) / s)
          -- The top left corner stays where it is
          o = vec2(sizing.x - (w / 2 - W * s / 2), sizing.y - (h / 2 - H * s / 2))
          ac.storage['rc.winsz.' .. id] = string.format('%.0f,%.0f', W, H)
          ac.storage['rc.win.' .. id] = string.format('%.0f,%.0f', o.x / k, o.y / k)
        else
          sizing = nil
        end
      end
    end
    local bw, bh = W * s, H * s
    if moving and moving.id == id then
      if ui.mouseDown() then o = vec2(m.x - moving.grab.x, m.y - moving.grab.y)
      else moving = nil end
    end
    -- Inside the screen
    local x = math.min(math.max(w / 2 - bw / 2 + o.x, 0), math.max(w - bw, 0))
    local y = math.min(math.max(h / 2 - bh / 2 + o.y, 0), math.max(h - bh, 0))
    o = vec2(x - (w / 2 - bw / 2), y - (h / 2 - bh / 2))
    if moving and moving.id == id then ac.storage['rc.win.' .. id] = string.format('%.0f,%.0f', o.x / k, o.y / k) end
    local p1 = vec2(math.floor(x), math.floor(y))
    local p2 = vec2(p1.x + bw, p1.y + bh)
    local onTitle = m.x >= p1.x and m.x <= p2.x - 34 * s and m.y >= p1.y and m.y <= p1.y + 21 * s
    if onTitle then ui.setMouseCursor(ui.MouseCursor.ResizeAll) end
    if not moving and onTitle and ui.mouseClicked() then moving = { id = id, grab = vec2(m.x - o.x, m.y - o.y) } end
    if resizable then
      -- The grip: three lines in the bottom right corner
      local g = 12 * s
      for i = 1, 3 do
        local d = i * g / 3
        ui.drawSimpleLine(vec2(p2.x - d, p2.y - 2 * s), vec2(p2.x - 2 * s, p2.y - d), rgbm(1, 1, 1, 0.45), 1)
      end
      local onGrip = m.x >= p2.x - g and m.x <= p2.x and m.y >= p2.y - g and m.y <= p2.y
      if onGrip or (sizing and sizing.id == id) then ui.setMouseCursor(ui.MouseCursor.ResizeNWSE) end
      if not sizing and not moving and onGrip and ui.mouseClicked() then
        sizing = { id = id, m0 = vec2(m.x, m.y), W0 = W, H0 = H, x = p1.x, y = p1.y }
      end
    end
    return p1, p2, W, H
  end

  -- Guard of the Race Control (order of 30/09): the panel and, over it (under its boxes when there is no room), the
  -- strip shown on demand with the car controls and the MESSAGES window (Drag.panelExtra px); under the panel, the
  -- flag box shown on demand (the red and yellow flags come first under the panel: screen.lua). Screen px:
  -- { x1, x2, panel top / bottom, strip sTop / sBottom, flag box fTop / fBottom, whole guard gTop / gBottom }
  local function panelGuard(w, h)
    local k = h / 1080
    local pr = Drag.lastRects.panel
    local x1 = pr and pr.min.x or (w / 2 - 260 * k)
    local x2 = pr and pr.max.x or (w / 2 + 260 * k)
    local top = pr and pr.min.y or (h * 0.18 + 10 * k)
    local bottom = pr and pr.max.y or (top + 66 * k)
    local extra = Drag.panelExtra or 0
    local sTop = top - extra
    local sBottom = top
    if sTop < 0 then sTop, sBottom = bottom, bottom + extra end
    -- The flag box: the size and gap of the boxes under the panel (screen.lua: 56 and 6 at the screen scale)
    local s = math.min(math.max((h / 1080) ^ 0.3, 1), 1.3)
    local fTop = math.max(bottom, sBottom) + math.floor(6 * s)
    local fBottom = fTop + math.floor(56 * s)
    return { x1 = x1, x2 = x2, top = top, bottom = bottom, sTop = sTop, sBottom = sBottom, fTop = fTop,
      fBottom = fBottom, gTop = math.min(top, sTop), gBottom = math.max(bottom, sBottom, fBottom) }
  end
  -- A rectangle with a dashed border (the part shown on demand)
  local function dashedRect(a, b, col, s)
    local seg, gap = 4 * s, 3 * s
    local function line(p, q)
      local len = math.sqrt((q.x - p.x) ^ 2 + (q.y - p.y) ^ 2)
      local d = 0
      while d < len do
        local e = math.min(d + seg, len)
        ui.drawSimpleLine(vec2(p.x + (q.x - p.x) * d / len, p.y + (q.y - p.y) * d / len),
          vec2(p.x + (q.x - p.x) * e / len, p.y + (q.y - p.y) * e / len), col, 1)
        d = e + gap
      end
    end
    line(a, vec2(b.x, a.y)); line(vec2(b.x, a.y), b); line(b, vec2(a.x, b.y)); line(vec2(a.x, b.y), a)
  end

  local function chip(text, p, s, on, color, fn)
    local tw = textWidth(text, FONT_MONO, 9 * s)
    local a, b = vec2(p.x, p.y), vec2(p.x + tw + 10 * s, p.y + 14 * s)
    if on then ui.drawRectFilled(a, b, PANEL_COLORS.yellow, 3 * s) else ui.drawRect(a, b, rgbm(1, 1, 1, 0.3), 3 * s) end
    drawText(text, FONT_MONO, 9 * s, vec2(a.x + 5 * s, a.y + 1.5 * s), on and rgbm(0.07, 0.07, 0.07, 1) or (color or COLOR_DIM))
    if fn then Drag.clickable(a, b, fn) end
    return b.x + 4 * s
  end

  local function where(g)
    local p, out = Desktop.place, {}
    if p.all[g] then return TEXTS.edAll end
    for d = 1, Desktop.count do if p[d] and p[d][g] then out[#out + 1] = tostring(d) end end
    if p.pit[g] then out[#out + 1] = 'PIT' end
    return #out > 0 and table.concat(out, ' ') or '-'
  end

  local function editor(w, h, s)
    -- The canvas has the shape of this screen; the editor height follows it
    local canvasH = CANVAS_W * h / w
    local H = canvasH + (Desktop.pitOn and 96 or 110)
    local p1, p2 = windowAt('editor', W, H, w, h, s)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    if m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y then ui.captureMouse(true) end
    local move = moving and moving.id == 'editor'
    drawPanel(p1, p2, BORDER_BASE, s)
    local desk = Desktop.editDesk
    drawText(TEXTS.edTitle, FONT_TITLE, 12 * s, vec2(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    local right = desk == 'pit' and TEXTS.edPitDesk or string.format(TEXTS.edDeskOf, desk, Desktop.count)
    drawTextRight(right, FONT_MONO, 11 * s, p2.x - 34 * s, p1.y + 5 * s, COLOR_TITLE)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Desktop.editor = false end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    -- Tabs
    local x = p1.x + 14 * s
    local ty = p1.y + 27 * s
    for d = 1, Desktop.count do
      x = chip(tostring(d), vec2(x, ty), s, desk == d, nil, function() Desktop.editDesk = d end)
    end
    x = chip('+', vec2(x, ty), s, false, nil, Desktop.addDesktop)
    x = chip('PIT', vec2(x, ty), s, desk == 'pit', PANEL_COLORS.green, function() Desktop.editDesk = 'pit' end)
    drawText(TEXTS.edHint, FONT_MONO, 8.5 * s, vec2(x + 6 * s, ty + 2 * s), COLOR_DIM)
    -- Canvas: the screen in small
    local c1 = vec2(p1.x + 14 * s, p1.y + 47 * s)
    local c2 = vec2(c1.x + CANVAS_W * s, c1.y + canvasH * s)
    ui.drawRectFilled(c1, c2, rgbm(0.06, 0.07, 0.09, 1), 3 * s)
    ui.drawRect(c1, c2, rgbm(1, 1, 1, 0.2), 3 * s)
    -- Screen px to the canvas: the cards are the screens as they are drawn (Drag.lastRects), same margins and size
    local k = h / 1080
    local cs = CANVAS_W * s / w
    local function toCanvas(px, py) return vec2(c1.x + px * cs, c1.y + py * cs) end
    -- Real area of a screen (px): drawn in the last frame, or its own place from the table when not drawn
    local function area(g, e)
      local r = Drag.lastRects[g]
      if r then return r.min, r.max, r.base end
      local t = RECT[g]
      local base = vec2(t[1] * k, t[2] * k)
      local a = vec2(base.x + e.x * k, base.y + e.y * k)
      return a, vec2(a.x + t[3] * k, a.y + t[4] * k), base
    end
    -- The Race Control panel: fixed on every desktop
    local pr = Drag.lastRects.panel
    local pa = pr and toCanvas(pr.min.x, pr.min.y) or toCanvas(w / 2 - 260 * k, h * 0.18)
    local pb = pr and toCanvas(pr.max.x, pr.min.y + 66 * k) or toCanvas(w / 2 + 260 * k, h * 0.18 + 66 * k)
    ui.drawRectFilled(pa, pb, rgbm(0.24, 0.25, 0.28, 0.95), 2 * s)
    ui.drawRect(pa, pb, (drag and drag.g == 'panel') and PANEL_COLORS.yellow or rgbm(1, 1, 1, 0.45), 2 * s)
    -- The panel moves (one place on every desktop) but cannot be removed
    if pr and not drag and not move and not Drag.pinned('panel') and ui.mouseClicked() and m.x >= pa.x and m.x <= pb.x
        and m.y >= pa.y and m.y <= pb.y then
      drag = { g = 'panel', dx = (m.x - pa.x) / cs, dy = (m.y - pa.y) / cs, base = pr.base,
        size = vec2(pr.max.x - pr.min.x, pr.max.y - pr.min.y) }
    end
    drawText(TEXTS.rcTitle, FONT_TEXT, 7.5 * s, vec2(pa.x + 3 * s, pa.y + 1 * s), COLOR_DIM)
    -- The strip of the car controls and MESSAGES, shown on demand: dashed, part of the guard of the panel
    local guard = panelGuard(w, h)
    local sa, sb = toCanvas(guard.x1, guard.sTop), toCanvas(guard.x2, guard.sBottom)
    dashedRect(sa, sb, rgbm(1, 1, 1, 0.45), s)
    drawText(TEXTS.edStrip, FONT_TEXT, 6.5 * s, vec2(sa.x + 3 * s, sa.y + 0.5 * s), COLOR_DIM)
    -- The flag box under the panel, shown on demand: dashed too
    local fa, fb = toCanvas(guard.x1, guard.fTop), toCanvas(guard.x2, guard.fBottom)
    dashedRect(fa, fb, rgbm(1, 1, 1, 0.45), s)
    drawText(TEXTS.edFlagStrip, FONT_TEXT, 6.5 * s, vec2(fa.x + 3 * s, fa.y + 0.5 * s), COLOR_DIM)
    local lists = { { Desktop.place.all, true } }
    if Desktop.place[desk] then lists[#lists + 1] = { Desktop.place[desk], false } end
    for _, L in ipairs(lists) do
      for g, e in pairs(L[1]) do
        if RECT[g] then
          local rmin, rmax, base = area(g, e)
          local a, b = toCanvas(rmin.x, rmin.y), toCanvas(rmax.x, rmax.y)
          local size = vec2(rmax.x - rmin.x, rmax.y - rmin.y)
          -- Room for the name and the icons on a small card
          b = vec2(math.max(b.x, a.x + 44 * s), math.max(b.y, a.y + 22 * s))
          -- ... kept inside the canvas (a small screen at the edge of the screen)
          if b.x > c2.x then a = vec2(a.x - (b.x - c2.x), a.y); b = vec2(c2.x, b.y) end
          if b.y > c2.y then a = vec2(a.x, a.y - (b.y - c2.y)); b = vec2(b.x, c2.y) end
          local dragging = drag and drag.g == g
          ui.drawRectFilled(a, b, rgbm(0.16, 0.17, 0.2, 0.95), 2 * s)
          ui.drawRect(a, b, dragging and PANEL_COLORS.yellow or (L[2] and PANEL_COLORS.green or rgbm(1, 1, 1, 0.45)), 2 * s)
          ui.pushClipRect(a, b)
          drawText(TEXTS.screenNames[g] or g, FONT_TEXT, 7.5 * s, vec2(a.x + 3 * s, a.y + 1 * s), COLOR_TITLE)
          ui.popClipRect()
          -- Icons at the bottom right of the card: on all desktops (green), mode (visible / auto-hide / hidden), remove
          local isz = 9 * s
          local ix, iy = b.x - 3 * (isz + 2 * s) - 1 * s, b.y - isz - 2 * s
          local function icon(id, col, fn)
            local q1, q2 = vec2(ix, iy), vec2(ix + isz, iy + isz)
            ui.drawIcon(id, q1, q2, col)
            Drag.clickable(vec2(q1.x - 1 * s, q1.y - 1 * s), vec2(q2.x + 1 * s, q2.y + 1 * s), fn)
            ix = ix + isz + 2 * s
          end
          icon(ui.Icons.Monitor, L[2] and PANEL_COLORS.green or COLOR_DIM, function() Desktop.pinAll(L[2] and 'all' or desk, g) end)
          icon(MODE_ICON[e.mode] or ui.Icons.Eye, COLOR_TITLE, function() e.mode = MODE_NEXT[e.mode]; Desktop.save() end)
          icon(ui.Icons.Trash, PANEL_COLORS.red, function() Desktop.remove(L[2] and 'all' or desk, g) end)
          -- Drag the card by its body (not the icons)
          local onIcons = m.x >= b.x - 3 * (isz + 2 * s) - 2 * s and m.y >= iy - 1 * s
          if not drag and not move and not onIcons and ui.mouseClicked() and m.x >= a.x and m.x <= b.x
              and m.y >= a.y and m.y <= b.y then
            drag = { g = g, entry = e, dx = (m.x - a.x) / cs, dy = (m.y - a.y) / cs, base = base, size = size }
          end
        end
      end
    end
    if drag then
      if ui.mouseDown() then
        -- New top left on the screen (px), kept on the screen like the real drag; offset = from its own place
        local tx = math.min(math.max((m.x - c1.x) / cs - drag.dx, 0), w - drag.size.x)
        local ty = math.min(math.max((m.y - c1.y) / cs - drag.dy, 0), h - drag.size.y)
        if drag.g == 'panel' then
          ty = Drag.fitPanel(ty, drag.size.y, h)
          Drag.setOffset('panel', vec2((tx - drag.base.x) / k, (ty - drag.base.y) / k))
        else
          -- Not over the guard of the Race Control (panel and its strip on demand): out by the nearest side
          local gd = panelGuard(w, h)
          if tx < gd.x2 and tx + drag.size.x > gd.x1 and ty < gd.gBottom and ty + drag.size.y > gd.gTop then
            local up, down = gd.gTop - drag.size.y, gd.gBottom
            ty = (up >= 0 and (math.abs(ty - up) <= math.abs(ty - down) or down + drag.size.y > h)) and up or down
          end
          drag.entry.x = math.floor((tx - drag.base.x) / k)
          drag.entry.y = math.floor((ty - drag.base.y) / k)
        end
      else
        drag = nil
        Desktop.save()
      end
    end
    -- List of the screens: a click adds or removes it on the desktop being edited
    local lx, ly = c2.x + 12 * s, c1.y
    drawText(TEXTS.edScreens, FONT_TITLE, 10 * s, vec2(lx, ly), COLOR_DIM)
    ly = ly + 15 * s
    for _, g in ipairs(Desktop.SCREENS) do
      local on = Desktop.place[desk] and Desktop.place[desk][g] or Desktop.place.all[g]
      local a, b = vec2(lx, ly), vec2(p2.x - 14 * s, ly + 15 * s)
      ui.drawRect(a, b, on and PANEL_COLORS.yellow or rgbm(1, 1, 1, 0.2), 3 * s)
      drawText(TEXTS.screenNames[g] or g, FONT_TEXT, 8.5 * s, vec2(a.x + 5 * s, a.y + 1.5 * s), COLOR_TITLE)
      drawTextRight(where(g), FONT_MONO, 8.5 * s, b.x - 5 * s, a.y + 1.5 * s, on and PANEL_COLORS.yellow or COLOR_DIM)
      Drag.clickable(a, b, function() Desktop.toggle(desk, g) end)
      ly = ly + 18 * s
    end
    -- Buttons of the desktop and the pit desktop
    local by = c2.y + 8 * s
    local bx = c1.x
    bx = chip(TEXTS.edReset, vec2(bx, by), s, false, nil, function()
      for _, e in pairs(Desktop.place[desk] or {}) do e.x, e.y = 0, 0 end
      Desktop.save()
    end)
    bx = chip(TEXTS.edCopy, vec2(bx, by), s, false, nil, function() Desktop.copyFrom(1, desk) end)
    bx = chip(TEXTS.edDelete, vec2(bx, by), s, false, PANEL_COLORS.red, function() Desktop.deleteDesktop(desk) end)
    chip(Desktop.pitOn and TEXTS.edPitOn or TEXTS.edPitOff, vec2(bx, by), s, false,
      Desktop.pitOn and PANEL_COLORS.green or PANEL_COLORS.red, function() Desktop.pitOn = not Desktop.pitOn; Desktop.save() end)
    if not Desktop.pitOn then
      drawText(TEXTS.edPitWarning, FONT_MONO, 8.5 * s, vec2(c1.x, by + 18 * s), PANEL_COLORS.yellow)
    end
    -- Navigation buttons (CSP controls)
    local ny = by + (Desktop.pitOn and 20 or 34) * s
    local nav = Desktop.NAV
    local function bound(b) return b.boundTo and b:boundTo() or nil end
    drawText(string.format(TEXTS.edButtons, bound(nav.nextScreen) or '-', bound(nav.prevScreen) or '-',
      bound(nav.nextDesktop) or '-', bound(nav.prevDesktop) or '-'), FONT_MONO, 8.5 * s, vec2(c1.x, ny), COLOR_DIM)
  end

  -- Desktop indicator after a change: number and the screens on it
  local function indicator(w, h, s)
    local names = {}
    for g in pairs(Desktop.place[Desktop.current] or {}) do names[#names + 1] = TEXTS.screenNames[g] or g end
    table.sort(names)
    local text = string.format(TEXTS.edIndicator, Desktop.current, Desktop.count, table.concat(names, ' - '))
    local tw = textWidth(text, FONT_MONO, 11 * s)
    -- Over the guard of the Race Control (the panel and its strip on demand), under it when there is no room
    local gd = panelGuard(w, h)
    local top = gd.gTop - 6 * s - 22 * s
    if top < 0 then top = gd.gBottom + 6 * s end
    local p1 = vec2(math.floor((gd.x1 + gd.x2) / 2 - tw / 2 - 12 * s), math.floor(top))
    local p2 = vec2(p1.x + tw + 24 * s, p1.y + 22 * s)
    Drag.group = nil
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(text, FONT_MONO, 11 * s, vec2(p1.x + 12 * s, p1.y + 4 * s), COLOR_TITLE)
  end

  -- Menu of the gear (decision 192): the options of the tool; one window of the tool at a time. Settings for every
  -- driver (decision 227); the red flag control only on the race director's client (decision 229)
  local function closeWindows()
    Desktop.editor, Audit.open, Desktop.buttons, Desktop.settingsOpen, Desktop.redOpen = false, false, false, false, false
  end
  local function menu(w, h, s)
    local pr = Drag.lastRects.panel
    if not pr then return end
    local items = { { TEXTS.menuDesktops, function() closeWindows(); Desktop.editor = true end },
      { TEXTS.menuAudit, function() closeWindows(); Audit.open = true end },
      { TEXTS.menuButtons, function() closeWindows(); Desktop.buttons = true end },
      { TEXTS.menuSettings, function() closeWindows(); Desktop.settingsOpen = true end } }
    if config.role then
      items[#items + 1] = { TEXTS.menuRedFlag, function() closeWindows(); Desktop.redOpen = true end }
    end
    local p1 = vec2(math.floor(pr.max.x - 150 * s), math.floor(pr.min.y))
    local p2 = vec2(p1.x + 150 * s, p1.y + (14 + #items * 22) * s)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    drawPanel(p1, p2, BORDER_BASE, s)
    for i, it in ipairs(items) do
      local a = vec2(p1.x + 12 * s, p1.y + (8 + (i - 1) * 22) * s)
      local b = vec2(p2.x - 10 * s, a.y + 18 * s)
      ui.drawRect(a, b, rgbm(1, 1, 1, 0.25), 3 * s)
      drawText(it[1], FONT_TEXT, 10 * s, vec2(a.x + 6 * s, a.y + 2 * s), COLOR_TITLE)
      Drag.clickable(a, b, function() it[2](); Desktop.menu = false end)
    end
  end

  -- Audit screen (decision 209): the server messages taken off the chat, newest first, the KMR points and rating
  local AUDIT_ROWS = 16
  local SRC_COLOR = { KMR = PANEL_COLORS.yellow, ACSM = PANEL_COLORS.blue }
  local function audit(w, h, s)
    local W2, ROW2 = 620, 14
    local H2 = 44 + AUDIT_ROWS * ROW2 + 10
    local p1, p2, _, hNow = windowAt('audit', W2, H2, w, h, s, true)
    -- Rows by the height chosen (resizable window)
    local AUDIT_ROWS = math.max(math.floor((hNow - 54) / ROW2), 1)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    local over = m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y
    if over then ui.captureMouse(true) end
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.auditTitle, FONT_TITLE, 12 * s, vec2(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    local pts = Audit.points and string.format(TEXTS.auditPoints, Audit.points, config.kmrPoints.limit)
      or string.format(TEXTS.auditPoints, 0, config.kmrPoints.limit):gsub('^(%S+ %S+ )0', '%1-')
    local rating = string.format(TEXTS.auditRating, Audit.rating and Audit.num(Audit.rating) or '-')
    drawTextRight(pts .. '   ' .. rating .. '   ' .. string.format(TEXTS.auditCount, #Audit.items), FONT_MONO, 11 * s, p2.x - 34 * s,
      p1.y + 5 * s, COLOR_TITLE)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Audit.open = false end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    -- Newest first; mouse wheel or the arrows scroll
    local n = #Audit.items
    local maxScroll = math.max(n - AUDIT_ROWS, 0)
    if over then Audit.scroll = Audit.scroll - math.floor(ui.mouseWheel() * 3) end
    local x = chip('^', vec2(p1.x + 14 * s, p1.y + 25 * s), s, false, nil, function() Audit.scroll = Audit.scroll - AUDIT_ROWS end)
    chip('v', vec2(x, p1.y + 25 * s), s, false, nil, function() Audit.scroll = Audit.scroll + AUDIT_ROWS end)
    Audit.scroll = math.min(math.max(Audit.scroll, 0), maxScroll)
    local y = p1.y + 44 * s
    ui.pushClipRect(vec2(p1.x + 8 * s, y), vec2(p2.x - 8 * s, p2.y - 4 * s))
    for k = 1, AUDIT_ROWS do
      local it = Audit.items[n - Audit.scroll - k + 1]
      if not it then break end
      local sec = math.max(math.floor(it.t / 1000), 0)
      drawText(string.format('%d:%02d:%02d', math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60), FONT_MONO,
        9.5 * s, vec2(p1.x + 14 * s, y), COLOR_DIM)
      drawText(it.src, FONT_MONO, 9.5 * s, vec2(p1.x + 76 * s, y), SRC_COLOR[it.src] or COLOR_TITLE)
      drawText(it.text, FONT_TEXT, 9.5 * s, vec2(p1.x + 118 * s, y), COLOR_TITLE)
      y = y + ROW2 * s
    end
    ui.popClipRect()
    if n == 0 then drawText(TEXTS.auditEmpty, FONT_MONO, 9.5 * s, vec2(p1.x + 14 * s, y), COLOR_DIM) end
  end

  -- Buttons screen (decisions 212, 217): each command of the navigation and the arrows, the button recorded by the tool
  -- (Set: press it on any device within 10 s; Clear), and the binding in the CSP controls, which also works (the arrows:
  -- the gamepad D-pad of the pit stop box)
  local NAV_ROWS = { { 'nextScreen', TEXTS.navNextScreen }, { 'prevScreen', TEXTS.navPrevScreen },
    { 'nextDesktop', TEXTS.navNextDesktop }, { 'prevDesktop', TEXTS.navPrevDesktop },
    { 'up', TEXTS.navUp }, { 'down', TEXTS.navDown }, { 'left', TEXTS.navLeft }, { 'right', TEXTS.navRight } }
  local function buttonsScreen(w, h, s)
    -- Columns measured from their texts (finding of 30/09: a long button name ran over SET and CLEAR): the recorded
    -- button (and its conflict), then SET / CLEAR, then the CSP binding; the window as wide as they need
    local rows, ownW, cspW = {}, textWidth(TEXTS.navOwn, FONT_TITLE, 9 * s), textWidth(TEXTS.navCsp, FONT_TITLE, 9 * s)
    for _, r in ipairs(NAV_ROWS) do
      local name = r[1]
      local cap = Desktop.capture and Desktop.capture.name == name
      local own = cap and string.format(TEXTS.navPress, math.max(math.ceil(Desktop.capture.untilT - state.ui.clock), 0))
        or Desktop.bindText(name) or '-'
      -- A button in use by the AC or by another command: not recorded (while recording), or marked (kept from before)
      local conflict = cap and Desktop.capture.conflict or (not cap and Desktop.bindConflict(name))
      local b = Desktop.NAV[name] or PitBox.PAD[name]
      local csp = b and b.boundTo and b:boundTo() or '-'
      rows[#rows + 1] = { name = name, label = r[2], cap = cap, own = own, conflict = conflict, csp = csp }
      ownW = math.max(ownW, textWidth(own, FONT_MONO, 9.5 * s), conflict and textWidth(conflict, FONT_MONO, 8.5 * s) or 0)
      cspW = math.max(cspW, textWidth(csp, FONT_MONO, 9.5 * s))
    end
    local chipsW = textWidth(TEXTS.navSet, FONT_MONO, 9 * s) + textWidth(TEXTS.navClear, FONT_MONO, 9 * s) + 28 * s
    local ownX = 150 * s
    local setX = ownX + ownW + 14 * s
    local cspX = setX + chipsW + 14 * s
    local W3, H3 = math.max(560, (cspX + cspW + 16 * s) / s), 44 + #NAV_ROWS * 22 + 22
    local p1, p2 = windowAt('buttons', W3, H3, w, h, s)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    if m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y then ui.captureMouse(true) end
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.navTitle, FONT_TITLE, 12 * s, vec2(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Desktop.buttons = false; Desktop.capture = nil end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local y = p1.y + 30 * s
    drawText(TEXTS.navOwn, FONT_TITLE, 9 * s, vec2(p1.x + ownX, y), COLOR_DIM)
    drawText(TEXTS.navCsp, FONT_TITLE, 9 * s, vec2(p1.x + cspX, y), COLOR_DIM)
    y = y + 16 * s
    for _, r in ipairs(rows) do
      local name, cap, own, conflict = r.name, r.cap, r.own, r.conflict
      drawText(r.label, FONT_TEXT, 10 * s, vec2(p1.x + 14 * s, y + 1 * s), COLOR_TITLE)
      drawText(own, FONT_MONO, 9.5 * s, vec2(p1.x + ownX, y + 1.5 * s), conflict and PANEL_COLORS.red
        or (cap and PANEL_COLORS.yellow or (own == '-' and COLOR_OFF or COLOR_TITLE)))
      if conflict then
        drawText(conflict, FONT_MONO, 8.5 * s, vec2(p1.x + ownX, y + 12 * s), PANEL_COLORS.red)
      end
      local x = chip(TEXTS.navSet, vec2(p1.x + setX, y), s, cap, nil, function() Desktop.startCapture(name) end)
      chip(TEXTS.navClear, vec2(x, y), s, false, PANEL_COLORS.red, function() Desktop.clearBind(name) end)
      drawText(r.csp, FONT_MONO, 9.5 * s, vec2(p1.x + cspX, y + 1.5 * s), r.csp == '-' and COLOR_OFF or COLOR_TITLE)
      y = y + 22 * s
    end
  end

  -- Settings of the driver (decisions 225, 226, 227), kept on this computer (ac.storage 'rc.settings'): the areas of the
  -- messages the message window shows (presets and each area; the Race Control area always), the car controls shown
  local AREAS = { 'limits', 'damage', 'points', 'warnings', 'others', 'server', 'results', 'welcome', 'admin', 'chat',
    'diag' }
  -- Diagnostics (the detector of the car changes, core/diag.lua) on in every preset while the cause is searched
  local PRESETS = { verbose = { limits = 1, damage = 1, points = 1, warnings = 1, others = 1, server = 1, results = 1,
    welcome = 1, admin = 1, chat = 1, diag = 1 }, race = { limits = 1, damage = 1, points = 1, warnings = 1, diag = 1 },
    minimal = { points = 1, diag = 1 } }
  local PRESET_ORDER = { 'verbose', 'race', 'minimal', 'custom' }
  local CTL = { 'on', 'elec', 'engine', 'hybrid', 'aero', 'pit' }
  local Settings = { preset = 'race', areas = {}, ctl = {}, tab = 'messages', appT = nil, sha = nil }
  local function applyPreset(name)
    Settings.preset = name
    if PRESETS[name] then
      Settings.areas = {}
      for k in pairs(PRESETS[name]) do Settings.areas[k] = true end
    end
  end
  local function settingsSave()
    local on, ctl = {}, {}
    for _, a in ipairs(AREAS) do if Settings.areas[a] then on[#on + 1] = a end end
    for _, c in ipairs(CTL) do ctl[#ctl + 1] = Settings.ctl[c] and '1' or '0' end
    ac.storage['rc.settings'] = string.format('1|%s|%s|%s', Settings.preset, table.concat(on, ','), table.concat(ctl))
  end
  do
    local preset, on, ctl = tostring(ac.storage['rc.settings'] or ''):match('^1|(%a+)|([%a,]*)|([01]*)$')
    applyPreset(PRESETS[preset or ''] and preset or 'race')
    if preset == 'custom' then
      Settings.preset = 'custom'
      for a in on:gmatch('%a+') do Settings.areas[a] = true end
    end
    for i, c in ipairs(CTL) do Settings.ctl[c] = not ctl or ctl:sub(i, i) ~= '0' end
  end
  Audit.allow = function(area) return Settings.areas[area] == true end

  -- Car controls (decisions 219, 226), by group: ELECTRONICS (ABS, TC, TC2), ENGINE AND BRAKES (engine map, engine brake,
  -- brake bias), HYBRID (MGU-K delivery and recovery, MGU-H); only what the car has. A change shows its group for
  -- screens.controlSeconds, the group title and the control changed in yellow. AERO (DRS) is apart and first: lit while
  -- the DRS is open (a group changed meanwhile shows over it, then the DRS comes back), CLOSED for controlSeconds after.
  -- The first reading of a car is the reference, not a change. The driver chooses the groups shown (settings). The
  -- levels as the game counts them (test T1: "Set on level : 0/2" for the first of 3 engine maps). PIT LIMITER is apart
  -- like the AERO (finding 7 of 29-30/09): lit while on, OFF for controlSeconds after. The game's own messages of the
  -- groups shown are blocked (ac.blockSystemMessages; the titles read in test T1)
  local GROUP_TITLE = { elec = 'ELECTRONICS', engine = 'ENGINE - BRAKES', hybrid = 'HYBRID' }
  local Controls = { last = nil, changed = nil, group = nil, untilT = 0, list = {}, drs = nil, aeroUntil = 0, pit = nil,
    pitUntil = 0 }
  -- The game's messages of the controls shown: blocked while ours show them (titles of test T1)
  local BLOCK = { elec = 'ABS|TC|TC2', engine = 'Engine Map', pit = 'Pit limiter' }
  local blockOff, blockKey = nil, ''
  -- The game's message of the pit place that sends to the ESC menu (the AC pit menu is off, decision 30; order of
  -- 30/09: "NADA DISSO DEVERIA ESTAR APARECENDO"): blocked all the time (decision 277)
  local escBlock = nil
  local function blockUpdate()
    if not escBlock and ac.blockSystemMessages then escBlock = ac.blockSystemMessages('ESC|Esc') end
    local parts = {}
    if Settings.ctl.on then
      for _, g in ipairs({ 'elec', 'engine', 'pit' }) do if Settings.ctl[g] then parts[#parts + 1] = BLOCK[g] end end
    end
    local key = table.concat(parts, '|')
    if key == blockKey then return end
    if blockOff then pcall(blockOff) end
    blockOff, blockKey = nil, key
    if key ~= '' and ac.blockSystemMessages then blockOff = ac.blockSystemMessages('^(' .. key .. ')$') end
  end
  local function controlList(c)
    local list = {}
    local function add(group, key, label, value) list[#list + 1] = { group = group, key = key, label = label, value = value } end
    local absN, tcN = CarRead.num(c.absModes), CarRead.num(c.tractionControlModes)
    local abs, tc = CarRead.num(c.absMode), CarRead.num(c.tractionControlMode)
    if absN > 0 then add('elec', 'abs', 'ABS', abs > 0 and string.format('%d', abs) or 'OFF') end
    if tcN > 0 then add('elec', 'tc', 'TC', tc > 0 and string.format('%d', tc) or 'OFF') end
    local tc2N = CarRead.num(c.tractionControl2Modes)
    if tc2N > 0 then
      add('elec', 'tc2', 'TC2', string.format('%g/%d', CarRead.num(c.tractionControl2), math.max(tc2N - 1, 0)))
    end
    local maps = CarRead.num(c.fuelMaps)
    if maps > 1 then add('engine', 'map', 'MAP', string.format('%d/%d', CarRead.num(c.fuelMap), maps - 1)) end
    local eb = CarRead.num(c.engineBrakeSettingsCount)
    if eb > 1 then add('engine', 'eb', 'EB', string.format('%d/%d', CarRead.num(c.currentEngineBrakeSetting), eb - 1)) end
    local bb = CarRead.num(c.brakeBias)
    if bb > 0 then add('engine', 'bb', 'BB', string.format('%.1f', bb <= 1 and bb * 100 or bb)) end
    local mgu = CarRead.num(c.mgukDeliveryCount)
    if mgu > 0 then
      add('hybrid', 'mguk', 'MGU-K', string.format('%d/%d', CarRead.num(c.mgukDelivery), mgu - 1))
      add('hybrid', 'recov', 'RECOV.', string.format('%d%%', CarRead.num(c.mgukRecovery) * 10))
      add('hybrid', 'mguh', 'MGU-H', c.mguhChargingBatteries and 'BATT' or 'MOTOR')
    end
    return list
  end
  local function controlsUpdate(car)
    local list = controlList(car)
    local now = {}
    for _, it in ipairs(list) do now[it.key] = it.value end
    if Controls.last then
      for _, it in ipairs(list) do
        if Controls.last[it.key] ~= nil and Controls.last[it.key] ~= it.value then
          Controls.changed, Controls.group = it.key, it.group
          Controls.untilT = state.ui.clock + config.screens.controlSeconds
        end
      end
    end
    Controls.last = now
    Controls.list = list
    -- DRS: open = lit; closed = CLOSED for a few seconds
    local drs = nil
    if car.drsPresent then drs = car.drsActive == true end
    if drs == false and Controls.drs == true then Controls.aeroUntil = state.ui.clock + config.screens.controlSeconds end
    Controls.drs = drs
    -- Pit limiter (manual): on = lit; off = OFF for a few seconds
    local pit = nil
    if car.manualPitsSpeedLimiterEnabled ~= nil then pit = car.manualPitsSpeedLimiterEnabled == true end
    if pit == false and Controls.pit == true then Controls.pitUntil = state.ui.clock + config.screens.controlSeconds end
    Controls.pit = pit
    blockUpdate()
  end
  -- Read every frame by the desktops (Desktop.update), drawn or not
  Desktop.controlsUpdate = controlsUpdate
  local function controlsBox(p1, s)
    local items = {}
    for _, it in ipairs(Controls.list) do if it.group == Controls.group then items[#items + 1] = it end end
    local p2 = vec2(p1.x + 196 * s, p1.y + 56 * s)
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(GROUP_TITLE[Controls.group] or '', FONT_TITLE, 9 * s, vec2(p1.x + 12 * s, p1.y + 5 * s), PANEL_COLORS.yellow)
    local cw = (p2.x - p1.x - 20 * s) / 3
    for i, it in ipairs(items) do
      local x = p1.x + 12 * s + (i - 1) * cw
      local on = it.key == Controls.changed
      drawText(it.label, FONT_TITLE, 9 * s, vec2(x, p1.y + 19 * s), on and PANEL_COLORS.yellow or COLOR_DIM)
      drawText(it.value, FONT_MONO, 12 * s, vec2(x, p1.y + 31 * s), on and PANEL_COLORS.yellow or COLOR_TITLE)
    end
  end
  -- AERO (decisions 226, 229, 256): a box of its own, in the fonts of the other boxes of the controls place (the groups
  -- and the pit limiter): the title AERO, DRS as the item and OPEN / CLOSED as the value; as wide as CLOSED needs
  local function aeroBox(p1, s)
    -- The fonts of the other boxes of this place (the groups and the pit limiter): title 9, item 9, value 12
    local vw = math.max(textWidth('AERO', FONT_TITLE, 9 * s), textWidth('DRS', FONT_TITLE, 9 * s),
      textWidth('CLOSED', FONT_MONO, 12 * s))
    local p2 = vec2(p1.x + vw + 24 * s, p1.y + 56 * s)
    local open = Controls.drs == true
    drawPanel(p1, p2, open and BORDER_GREEN or BORDER_BASE, s)
    drawText('AERO', FONT_TITLE, 9 * s, vec2(p1.x + 12 * s, p1.y + 5 * s), open and PANEL_COLORS.green or COLOR_TITLE)
    drawText('DRS', FONT_TITLE, 9 * s, vec2(p1.x + 12 * s, p1.y + 19 * s), COLOR_DIM)
    drawText(open and 'OPEN' or 'CLOSED', FONT_MONO, 12 * s, vec2(p1.x + 12 * s, p1.y + 31 * s),
      open and PANEL_COLORS.green or COLOR_TITLE)
  end
  -- PIT LIMITER: alone like the AERO, as wide as its words need
  local function pitBox(p1, s)
    local vw = math.max(textWidth('LIMITER', FONT_TITLE, 9 * s), textWidth('OFF', FONT_MONO, 12 * s), textWidth('PIT', FONT_TITLE, 9 * s))
    local p2 = vec2(p1.x + vw + 24 * s, p1.y + 56 * s)
    local on = Controls.pit == true
    drawPanel(p1, p2, on and BORDER_GREEN or BORDER_BASE, s)
    drawText('PIT', FONT_TITLE, 9 * s, vec2(p1.x + 12 * s, p1.y + 5 * s), on and PANEL_COLORS.green or COLOR_TITLE)
    drawText('LIMITER', FONT_TITLE, 9 * s, vec2(p1.x + 12 * s, p1.y + 19 * s), COLOR_DIM)
    drawText(on and 'ON' or 'OFF', FONT_MONO, 12 * s, vec2(p1.x + 12 * s, p1.y + 31 * s), on and PANEL_COLORS.green or COLOR_TITLE)
  end
  -- What the controls place shows now: 'group', 'aero', 'pit' or nil. The DRS has priority over the others (decision
  -- 226): only a group that changes shows over it, for its seconds, and then the DRS comes back
  local function controlsShown()
    local ctl = Settings.ctl
    if not ctl.on then return nil end
    if state.ui.clock < Controls.untilT and Controls.group and ctl[Controls.group] then return 'group' end
    if ctl.aero and Controls.drs ~= nil and (Controls.drs or state.ui.clock < Controls.aeroUntil) then return 'aero' end
    if ctl.pit and Controls.pit ~= nil and (Controls.pit or state.ui.clock < Controls.pitUntil) then return 'pit' end
    return nil
  end

  -- A box to mark, drawn (the font may not have the box characters)
  local function tick(p, on, s, locked)
    local a, b = vec2(p.x, p.y + 1 * s), vec2(p.x + 10 * s, p.y + 11 * s)
    ui.drawRect(a, b, locked and COLOR_OFF or rgbm(1, 1, 1, 0.6), 2 * s)
    if on then ui.drawRectFilled(vec2(a.x + 2 * s, a.y + 2 * s), vec2(b.x - 2 * s, b.y - 2 * s),
      locked and COLOR_OFF or PANEL_COLORS.green, 1 * s) end
  end

  -- Settings window (decisions 225, 226, 227): Messages (presets and each area), Controls (groups), App (validation;
  -- all good: closes in 5 s, decision 225)
  local function settingsWindow(w, h, s)
    -- Opened now: the App tab counts its 5 s again
    if not Settings.shown then Settings.appT = nil end
    Settings.shown = true
    local W4 = 520
    local H4 = 30 + math.max(#AREAS + 3, #CTL, 6) * 18 + 10
    local p1, p2 = windowAt('settings', W4, H4, w, h, s)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    if m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y then ui.captureMouse(true) end
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.setTitle, FONT_TITLE, 12 * s, vec2(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    local x = p1.x + 150 * s
    for _, t in ipairs({ 'messages', 'controls', 'app' }) do
      x = chip(TEXTS.setTabs[t], vec2(x, p1.y + 4 * s), s, Settings.tab == t, nil, function()
        Settings.tab = t
        Settings.appT = nil
      end)
    end
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Desktop.settingsOpen = false end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local y = p1.y + 28 * s
    local x0 = p1.x + 14 * s
    if Settings.tab == 'messages' then
      local px = x0 + 50 * s
      drawText(TEXTS.setPreset, FONT_TITLE, 9 * s, vec2(x0, y + 1 * s), COLOR_DIM)
      for _, name in ipairs(PRESET_ORDER) do
        px = chip(TEXTS.setPresets[name], vec2(px, y), s, Settings.preset == name, nil, function()
          applyPreset(name)
          settingsSave()
        end)
      end
      y = y + 22 * s
      tick(vec2(x0, y), true, s, true)
      drawText(TEXTS.setAreas.rc, FONT_TEXT, 10 * s, vec2(x0 + 16 * s, y), COLOR_TITLE)
      drawTextRight(TEXTS.setAlways, FONT_MONO, 9 * s, p2.x - 14 * s, y + 1 * s, COLOR_OFF)
      y = y + 18 * s
      for _, a in ipairs(AREAS) do
        local on = Settings.areas[a] == true
        tick(vec2(x0, y), on, s)
        drawText(TEXTS.setAreas[a], FONT_TEXT, 10 * s, vec2(x0 + 16 * s, y), on and COLOR_TITLE or COLOR_DIM)
        drawTextRight(TEXTS.setAreaHint[a], FONT_MONO, 9 * s, p2.x - 14 * s, y + 1 * s, COLOR_OFF)
        Drag.clickable(vec2(x0, y), vec2(p2.x - 14 * s, y + 14 * s), function()
          Settings.areas[a] = not on or nil
          Settings.preset = 'custom'
          settingsSave()
        end)
        y = y + 18 * s
      end
    elseif Settings.tab == 'controls' then
      for _, c in ipairs(CTL) do
        local on = Settings.ctl[c]
        tick(vec2(x0, y), on, s)
        drawText(TEXTS.setCtl[c], FONT_TEXT, 10 * s, vec2(x0 + 16 * s, y), on and COLOR_TITLE or COLOR_DIM)
        Drag.clickable(vec2(x0, y), vec2(p2.x - 14 * s, y + 14 * s), function()
          Settings.ctl[c] = not on
          settingsSave()
        end)
        y = y + 18 * s
      end
    else
      -- The app: running = it answered the online script (AppLink.ping, the channel of the preset: finding 17 of
      -- 29-30/09, the file was there and the check said missing); its SHA256, read once, only shown (the server checks
      -- it: [VERIFY_INTEGRITY_1])
      if Settings.sha == nil then
        Settings.sha = false
        AppLink.ping()
        if io.checksumSHA256 and ac.getFolder then
          pcall(io.checksumSHA256, ac.getFolder(ac.FolderID.Root) .. '/apps/lua/race-control/race-control.lua',
            function(err, sum) Settings.sha = (not err and sum) and sum or '' end)
        end
      end
      local okV, csp = pcall(ac.getPatchVersion)
      local okS, server = pcall(ac.getServerName)
      local sha = type(Settings.sha) == 'string' and Settings.sha ~= '' and Settings.sha:sub(1, 8) or nil
      local app = AppLink.alive and (sha and (TEXTS.setRunning .. ' - ' .. sha) or TEXTS.setRunning) or nil
      local list = {
        { TEXTS.setServer, sim.isOnlineRace and okS and tostring(server or '') or nil },
        { TEXTS.setCsp, okV and tostring(csp or '') or nil },
        { TEXTS.setScript, TEXTS.setRunning },
        { TEXTS.setApp, app },
      }
      local all = true
      for _, r in ipairs(list) do
        local ok = r[2] ~= nil and r[2] ~= ''
        all = all and ok
        drawText(ok and 'OK' or '--', FONT_MONO, 10 * s, vec2(x0, y), ok and PANEL_COLORS.green or PANEL_COLORS.red)
        drawText(r[1], FONT_TEXT, 10 * s, vec2(x0 + 30 * s, y), COLOR_TITLE)
        drawTextRight(ok and r[2] or (r[1] == TEXTS.setApp and AppLink.waiting() and TEXTS.setChecking or TEXTS.setMissing), FONT_MONO, 10 * s, p2.x - 14 * s, y, ok and COLOR_TITLE or PANEL_COLORS.red)
        y = y + 18 * s
      end
      y = y + 4 * s
      if all then
        Settings.appT = Settings.appT or state.ui.clock
        local left = math.max(math.ceil(5 - (state.ui.clock - Settings.appT)), 0)
        drawText(string.format(TEXTS.setAllGood, left), FONT_MONO, 9 * s, vec2(x0, y), COLOR_DIM)
        if left <= 0 then Desktop.settingsOpen = false end
      else
        drawText(TEXTS.setNotGood, FONT_MONO, 9 * s, vec2(x0, y), PANEL_COLORS.red)
      end
    end
  end

  -- Race direction (decisions 196, 203, 229, 243), for the roles: director and staff give the commands, the broadcast
  -- only sees. The commands go to the KMR through the chat ("/kmr <command>", KMR readme: chat admin), after the login
  -- typed here ("/kmr login <password>", never written to a log; the field is cleared once sent). Each command is
  -- answered on the window: sent, then the KMR answer or none in 5 s. RED FLAG, the session ones and the actions on a
  -- car ask for a second press within 5 s. Actions on a car by its server slot (KMR readme: player_give_drive_through
  -- <slot>|1, player_cancel_drive_through, player_kick, player_temporary_ban <slot>|60)
  local redArm, armKey = 0, nil
  local Direction = { pwd = '', status = nil, statusT = 0, waitLogin = false, seen = nil, guidJob = nil, target = '',
    focus = nil, guids = {}, listOpen = false }
  -- Drivers seen on the server by this client (names, kept on this computer): the ones who left (kicked by the KMR for
  -- the money or the minimum driving standard) can be released from here (decision 274)
  local SEEN_MAX = 40
  local function seenList()
    if not Direction.seen then
      Direction.seen = {}
      for name in tostring(ac.storage['rc.dir.seen'] or ''):gmatch('[^\n]+') do Direction.seen[#Direction.seen + 1] = name end
    end
    return Direction.seen
  end
  local function seenAdd(name)
    if name == '' then return end
    local list = seenList()
    for _, n in ipairs(list) do if n == name then return end end
    table.insert(list, 1, name)
    while #list > SEEN_MAX do table.remove(list) end
    ac.storage['rc.dir.seen'] = table.concat(list, '\n')
  end
  local function sendKmr(command, label)
    queueCommand('/kmr ' .. command)
    Direction.status, Direction.statusT = string.format(TEXTS.dirSent, label or command), state.ui.clock
    Direction.statusColor = PANEL_COLORS.yellow
    ac.log('race-control: race direction command sent: ' .. (label or command))
  end
  -- Release of a driver (decision 274): the KMR commands take the Steam GUID; the KMR gives it by the name, also of a
  -- driver no longer on the server (driver_get_guid, case sensitive), and the answer brings the command
  local function releaseDriver(action, name, label)
    if name == '' then return end
    local known = Direction.guids[name]
    if known then
      queueCommand('/kmr ' .. action .. ' ' .. known)
      Direction.status, Direction.statusT = string.format(TEXTS.dirSent, label .. ' ' .. name), state.ui.clock
      Direction.statusColor = PANEL_COLORS.yellow
      ac.log('race-control: race direction command sent: ' .. action .. ' for ' .. name)
      return
    end
    Direction.guidJob = { action = action, name = name, label = label, t = state.ui.clock }
    queueCommand('/kmr driver_get_guid ' .. name)
    Direction.status, Direction.statusT = string.format(TEXTS.dirGuidAsk, name), state.ui.clock
    Direction.statusColor = PANEL_COLORS.yellow
    ac.log('race-control: race direction: GUID asked for ' .. name .. ' (' .. action .. ')')
  end

  -- Answers of the KMR read from the chat (chat.lua): the login, a command not known by the server
  state.directionAnswer = function(message)
    -- The KMR player_list (car_id:name:guid): the names and GUIDs for the list of drivers
    local listed = false
    for _, name, g in message:gmatch('(%d+):([^:\n]+):(%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d)') do
      name = name:gsub('^%s+', ''):gsub('%s+$', '')
      Direction.guids[name] = g
      seenAdd(name)
      listed = true
    end
    if listed then return end
    local job = Direction.guidJob
    local guid = job and message:match('%f[%d](%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d)%f[%D]')
    if guid then
      Direction.guidJob = nil
      queueCommand('/kmr ' .. job.action .. ' ' .. guid)
      Direction.status, Direction.statusT = string.format(TEXTS.dirSent, job.label .. ' ' .. job.name), state.ui.clock
      Direction.statusColor = PANEL_COLORS.yellow
      ac.log('race-control: race direction command sent: ' .. job.action .. ' for ' .. job.name)
      return
    end
    local low = message:lower()
    if low:find('logged in as kissmyrank admin', 1, true) or low:find('logado como kissmyrank admin', 1, true) then
      Direction.waitLogin = false
      Direction.status, Direction.statusT, Direction.statusColor = TEXTS.dirLoginOk, state.ui.clock, PANEL_COLORS.green
    elseif low:find('not a recognised', 1, true) or low:find('not recognized', 1, true) then
      Direction.waitLogin = false
      Direction.status, Direction.statusT, Direction.statusColor = string.format(TEXTS.dirFailed, message), state.ui.clock,
        PANEL_COLORS.red
    elseif Direction.status and state.ui.clock - Direction.statusT < 5 then
      Direction.status, Direction.statusColor = string.format(TEXTS.dirAnswer, message), COLOR_TITLE
    end
  end
  -- A button that asks for a second press within 5 s (key: what it confirms)
  local function armed(key) return armKey == key and state.ui.clock < redArm end
  local function confirmChip(text, key, p, s, color, fn)
    local on = armed(key)
    return chip(on and (text .. ' ?') or text, p, s, on, color, function()
      if armed(key) then armKey, redArm = nil, 0; fn()
      else armKey, redArm = key, state.ui.clock + 5 end
    end)
  end
  -- Own text field (finding of 30/09: the ImGui text field of the full screen drawing took no keys): a click on it takes
  -- the keyboard from the game (ui.captureKeyboard); the characters typed, Backspace, Enter, Esc leaves. Returns the
  -- text and whether Enter was pressed
  local function ownField(key, fa, fb, value, masked, s)
    local on = Direction.focus == key
    ui.drawRectFilled(fa, fb, rgbm(0, 0, 0, 0.5), 2 * s)
    ui.drawRect(fa, fb, on and PANEL_COLORS.yellow or rgbm(1, 1, 1, 0.35), 2 * s)
    local caret = on and math.floor(state.ui.clock * 2) % 2 == 0 and '|' or ''
    ui.pushClipRect(fa, fb)
    drawText((masked and string.rep('*', #value) or value) .. caret, FONT_MONO, 10 * s, vec2(fa.x + 4 * s, fa.y + 1 * s),
      COLOR_TITLE)
    ui.popClipRect()
    Drag.clickable(fa, fb, function() Direction.focus = key end)
    local enter = false
    if on and ui.captureKeyboard then
      local kb = ui.captureKeyboard(true, true, true)
      local typed = kb and kb:queue() or ''
      for ch in typed:gmatch('[%g ]') do value = value .. ch end
      for k = 0, (kb and kb.pressedCount or 0) - 1 do
        local k2 = kb.pressed[k]
        if k2 == ui.KeyIndex.Back then value = value:sub(1, -2)
        elseif k2 == ui.KeyIndex.Return then enter = true
        elseif k2 == ui.KeyIndex.Escape then Direction.focus = nil end
      end
    end
    if enter then Direction.focus = nil end
    return value, enter
  end

  -- Session data (order of 30/09): name, time elapsed / left, laps done / left when the session has laps
  local function hms(ms)
    local t = math.max(math.floor((ms or 0) / 1000), 0)
    return string.format('%d:%02d:%02d', math.floor(t / 3600), math.floor(t / 60) % 60, t % 60)
  end
  local function sessionLine()
    local session = ac.getSession(sim.currentSessionIndex)
    local parts = { TEXTS.sessionName[sim.raceSessionType] or '-' }
    parts[#parts + 1] = string.format(TEXTS.dirSessionTime, hms(sessionElapsedMs()), hms(CarRead.num(sim.sessionTimeLeft)))
    local lead = 0
    for i = 0, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and (i == 0 or c.isConnected) then lead = math.max(lead, CarRead.num(c.lapCount)) end
    end
    local total = session and session.laps or 0
    if total > 0 then
      parts[#parts + 1] = string.format(TEXTS.dirSessionLapsOf, lead, total, math.max(total - lead, 0))
    else
      parts[#parts + 1] = string.format(TEXTS.dirSessionLaps, lead)
    end
    return table.concat(parts, '  -  ')
  end

  -- List of the drivers (order of 30/09): on the server, the ones who left and the ones of the KMR player_list; a click
  -- puts the name in the field of the race direction window. Beside that window when there is room, else over it on the
  -- right of the screen
  local function driversList(w, h, s, dp1, dp2)
    local names, on = {}, {}
    for i = 0, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and (i == 0 or c.isConnected) then
        local n = tostring(ac.getDriverName(i) or '')
        if n ~= '' and not on[n] then on[n] = true; names[#names + 1] = n end
      end
    end
    local off = {}
    for _, n in ipairs(seenList()) do if not on[n] then off[#off + 1] = n end end
    table.sort(names)
    table.sort(off)
    local LW, ROWL = 240 * s, 15 * s
    local rows = #names + #off + (#off > 0 and 1 or 0)
    local lh = 30 * s + math.max(rows, 1) * ROWL + 10 * s
    local x = dp2.x + 8 * s
    if x + LW > w then x = w - LW - 8 * s end
    local p1 = vec2(math.floor(x), math.floor(dp1.y))
    local p2 = vec2(p1.x + LW, math.min(p1.y + lh, h - 4 * s))
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.dirList, FONT_TITLE, 12 * s, vec2(p1.x + 12 * s, p1.y + 4 * s), COLOR_TITLE)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Direction.listOpen = false end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local y = p1.y + 26 * s
    ui.pushClipRect(vec2(p1.x, y), vec2(p2.x, p2.y - 4 * s))
    local function row(n, col)
      local a, b = vec2(p1.x + 8 * s, y - 1 * s), vec2(p2.x - 8 * s, y + ROWL - 2 * s)
      if Direction.target == n then ui.drawRectFilled(a, b, rgbm(1, 1, 1, 0.12), 2 * s) end
      drawText(n, FONT_TEXT, 9.5 * s, vec2(p1.x + 12 * s, y), col)
      if Direction.guids[n] then drawTextRight('GUID', FONT_MONO, 8 * s, p2.x - 12 * s, y + 1 * s, COLOR_DIM) end
      Drag.clickable(a, b, function() Direction.target = n end)
      y = y + ROWL
    end
    for _, n in ipairs(names) do row(n, COLOR_TITLE) end
    if #off > 0 then
      drawText(TEXTS.dirLeft, FONT_TITLE, 8.5 * s, vec2(p1.x + 12 * s, y), COLOR_DIM)
      y = y + ROWL
      for _, n in ipairs(off) do row(n, COLOR_DIM) end
    end
    ui.popClipRect()
  end

  local function redWindow(w, h, s)
    local cars = {}
    for i = 0, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and c.isConnected then cars[#cars + 1] = { i = i, c = c } end
    end
    local cmd = config.canCommand
    if Direction.guidJob and state.ui.clock - Direction.guidJob.t > 6 then
      Direction.status, Direction.statusColor = string.format(TEXTS.dirGuidNone, Direction.guidJob.name), PANEL_COLORS.red
      Direction.statusT, Direction.guidJob = state.ui.clock, nil
    end
    local W5, H5 = cmd and 940 or 560, 30 + 16 + (cmd and (22 + 22 + 22 + 22) or 0) + 18 + 16 + #cars * 28 + 22
    local p1, p2 = windowAt('redflag', W5, H5, w, h, s)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    if m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y then ui.captureMouse(true) end
    drawPanel(p1, p2, state.redFlag and BORDER_RED or BORDER_BASE, s)
    drawText(TEXTS.dirTitle, FONT_TITLE, 12 * s, vec2(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    drawText(TEXTS.dirRole[config.role] or '', FONT_MONO, 10 * s, vec2(p1.x + 170 * s, p1.y + 5 * s), COLOR_DIM)
    drawTextRight(state.redFlag and TEXTS.flagRed or TEXTS.redNone, FONT_MONO, 10 * s, p2.x - 40 * s, p1.y + 5 * s,
      state.redFlag and PANEL_COLORS.red or COLOR_DIM)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Desktop.redOpen = false end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local y = p1.y + 28 * s
    local x0 = p1.x + 14 * s
    drawText(sessionLine(), FONT_MONO, 10 * s, vec2(x0, y), COLOR_TITLE)
    y = y + 16 * s
    if cmd then
      -- KMR admin: logged in, or the password field (Enter sends the login)
      if state.kmrAdmin then
        drawText(TEXTS.redKmrOn, FONT_MONO, 9.5 * s, vec2(x0, y + 1 * s), PANEL_COLORS.green)
      else
        drawText(TEXTS.dirLogin, FONT_TEXT, 10 * s, vec2(x0, y), COLOR_TITLE)
        -- The password as dots; Enter sends the login
        local enter
        Direction.pwd, enter = ownField('pwd', vec2(x0 + 110 * s, y - 2 * s), vec2(x0 + 270 * s, y + 13 * s),
          Direction.pwd, true, s)
        do
          if enter and Direction.pwd ~= '' then
            queueCommand('/kmr login ' .. Direction.pwd)
            Direction.pwd = ''
            Direction.waitLogin = true
            Direction.status, Direction.statusT, Direction.statusColor = TEXTS.dirLoginSent, state.ui.clock, PANEL_COLORS.yellow
            ac.log('race-control: race direction: KMR login sent')
          end
        end
      end
      if Direction.waitLogin and state.ui.clock - Direction.statusT >= 5 then
        Direction.waitLogin = false
        Direction.status, Direction.statusColor = TEXTS.dirNoAnswer, PANEL_COLORS.red
      end
      y = y + 22 * s
      -- Driver by the name (decision 276): typed, or chosen in the list of drivers; the KMR commands by the GUID act on
      -- it, also for a driver no longer on the server
      drawText(TEXTS.dirDriver, FONT_TEXT, 10 * s, vec2(x0, y), COLOR_TITLE)
      Direction.target = ownField('name', vec2(x0 + 110 * s, y - 2 * s), vec2(x0 + 330 * s, y + 13 * s), Direction.target,
        false, s)
      local tx = x0 + 340 * s
      tx = confirmChip(TEXTS.dirMoney, 'tmoney', vec2(tx, y - 1 * s), s, nil, function()
        releaseDriver('driver_reset_money', Direction.target, 'reset money') end)
      tx = confirmChip(TEXTS.dirStats, 'tstats', vec2(tx, y - 1 * s), s, nil, function()
        releaseDriver('driver_reset_driving_stats', Direction.target, 'reset stats') end)
      chip(TEXTS.dirListBtn, vec2(tx, y - 1 * s), s, Direction.listOpen, nil, function()
        Direction.listOpen = not Direction.listOpen
        if Direction.listOpen and state.kmrAdmin then queueCommand('/kmr player_list') end
      end)
      y = y + 22 * s
      -- Flags and neutralizations
      local x = confirmChip(TEXTS.flagRed, 'red', vec2(x0, y), s, PANEL_COLORS.red, function()
        sendKmr('admin_say RC REDFLAG ALL', 'RED FLAG')
      end)
      -- VSC: with the red flag up, the restart under the VSC (the red flag goes down with it); without it, only the VSC
      -- (finding of 30/09: the red flag off sent without a red flag looked like a second command undoing the first)
      local red = state.redFlag ~= nil
      for _, sec in ipairs({ 60, 120, 180 }) do
        x = chip(string.format(red and TEXTS.redVsc or TEXTS.dirVsc, sec), vec2(x, y), s, false, nil, function()
          sendKmr('virtual_safety_car_deploy ' .. sec, string.format('VSC %d s', sec))
          if state.redFlag then queueCommand('/kmr admin_say RC REDFLAG OFF ALL') end
        end)
      end
      -- GREEN takes the red flag off (restart with the green at once). With the VSC of the KMR on (no command of the KMR
      -- ends it), the VSC is deployed again for 1 s so that it ends at once (finding of 30/09; to measure in the game)
      chip(TEXTS.redGreen, vec2(x, y), s, false, (red or state.code80) and PANEL_COLORS.green or COLOR_OFF, function()
        if state.redFlag then
          sendKmr('admin_say RC REDFLAG OFF ALL', 'GREEN')
        elseif state.code80 then
          sendKmr('virtual_safety_car_deploy 1', 'GREEN - VSC 1 s')
        else
          Direction.status, Direction.statusT, Direction.statusColor = TEXTS.dirNoRed, state.ui.clock, PANEL_COLORS.yellow
        end
      end)
      y = y + 22 * s
      -- Session
      x = confirmChip(TEXTS.dirNextSession, 'next', vec2(x0, y), s, nil, function() sendKmr('admin_next_session', 'NEXT SESSION') end)
      confirmChip(TEXTS.dirRestart, 'restart', vec2(x, y), s, nil, function() sendKmr('admin_restart_session', 'RESTART SESSION') end)
      y = y + 22 * s
    end
    -- The answer of the KMR can be long (finding of 30/09: a hash out of the window): cut to the width of the window
    local status = Direction.status or (cmd and not state.kmrAdmin and TEXTS.redKmrOff or '')
    local maxW = p2.x - x0 - 14 * s
    if textWidth(status, FONT_MONO, 9 * s) > maxW then
      while #status > 1 and textWidth(status .. '...', FONT_MONO, 9 * s) > maxW do status = status:sub(1, -2) end
      status = status .. '...'
    end
    drawText(status, FONT_MONO, 9 * s, vec2(x0, y), Direction.statusColor or PANEL_COLORS.yellow)
    y = y + 18 * s
    local inPits, over = 0, 0
    for _, e in ipairs(cars) do
      local c = e.c
      local where = c.isInPit and TEXTS.redPlace or (c.isInPitlane and TEXTS.redLane or TEXTS.redTrack)
      local kmh = CarRead.num(c.speedKmh)
      if c.isInPitlane then inPits = inPits + 1 end
      local fast = not c.isInPitlane and kmh > config.flags.redSpeedKmh
      if fast then over = over + 1 end
      drawText('#' .. tostring(ac.getDriverNumber(e.i) or e.i), FONT_MONO, 9.5 * s, vec2(x0, y), COLOR_TITLE)
      drawText(tostring(ac.getDriverName(e.i) or ''), FONT_TEXT, 9.5 * s, vec2(p1.x + 60 * s, y), COLOR_TITLE)
      drawText(where, FONT_MONO, 9.5 * s, vec2(p1.x + 210 * s, y),
        c.isInPit and PANEL_COLORS.green or (c.isInPitlane and PANEL_COLORS.yellow or PANEL_COLORS.red))
      drawTextRight(string.format('%.0f', kmh), FONT_MONO, 9.5 * s, p1.x + 300 * s, y, fast and PANEL_COLORS.red or COLOR_TITLE)
      -- Actions on the car (two presses), by its server slot
      if cmd then
        local slot = tostring(c.sessionID or e.i)
        local name = tostring(ac.getDriverName(e.i) or slot)
        local ax = p1.x + 312 * s
        ax = confirmChip('DT', 'dt' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('player_give_drive_through ' .. slot .. '|1', 'DT ' .. name) end)
        ax = confirmChip(TEXTS.dirCancelDt, 'cdt' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('player_cancel_drive_through ' .. slot, 'cancel DT ' .. name) end)
        ax = confirmChip('KICK', 'kick' .. slot, vec2(ax, y - 1 * s), s, PANEL_COLORS.red, function()
          sendKmr('player_kick ' .. slot, 'kick ' .. name) end)
        ax = confirmChip('BAN 60', 'ban' .. slot, vec2(ax, y - 1 * s), s, PANEL_COLORS.red, function()
          sendKmr('player_temporary_ban ' .. slot .. '|60', 'ban 60 min ' .. name) end)
        -- The car to the pits or disqualified by the race direction (RC commands of the platform, decision 262)
        ax = confirmChip(TEXTS.dirToPit, 'pit' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('admin_say RC TELEPORT ' .. slot, 'to the pits ' .. name) end)
        ax = confirmChip('DSQ', 'dsq' .. slot, vec2(ax, y - 1 * s), s, PANEL_COLORS.red, function()
          sendKmr('admin_say RC DSQ ' .. slot, 'DSQ ' .. name) end)
        -- Fuel under the red flag for a car already going to the pits (decision 270)
        ax = confirmChip(TEXTS.dirFuel, 'fuel' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('admin_say RC FUEL ' .. slot, 'fuel unlocked ' .. name) end)
        -- Release by the KMR (decision 274): money and driving stats back to zero
        ax = confirmChip(TEXTS.dirMoney, 'money' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          releaseDriver('driver_reset_money', name, 'reset money') end)
        ax = confirmChip(TEXTS.dirStats, 'stats' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          releaseDriver('driver_reset_driving_stats', name, 'reset stats') end)
        -- The stop & go of the platform relaxed (RC RELAX SG, decision 274)
        confirmChip(TEXTS.dirNoSg, 'nosg' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('admin_say RC RELAX ' .. slot .. ' SG', 'relax S&G ' .. name) end)
      end
      -- The KMR numbers of the driver (decision 278), sent by his client: points, safety rating, crashes and
      -- infractions with the rate per 100 km
      local k = Audit.kmrOf(e.i)
      local function nv(x) return x and Audit.num(x) or '-' end
      local kline = k and string.format(TEXTS.dirKmrLine, nv(k.points), config.kmrPoints.limit, nv(k.rating),
        nv(k.crashes), k.crashRate and string.format('%.2f', k.crashRate) or '-', nv(k.infractions),
        k.infractionRate and string.format('%.2f', k.infractionRate) or '-') or TEXTS.dirKmrNone
      drawText(kline, FONT_MONO, 8.5 * s, vec2(p1.x + 60 * s, y + 12 * s), COLOR_DIM)
      y = y + 28 * s
    end
    drawText(string.format(TEXTS.redCount, inPits, #cars, over), FONT_MONO, 9 * s, vec2(x0, y + 2 * s), COLOR_DIM)
    if cmd and Direction.listOpen then driversList(w, h, s, p1, p2) end
  end

  -- Lobby (the pits menu with Drive, Setup, Laptimes, Info; decisions 227, 229): on the right of the screen, in the part
  -- the menu leaves free (order of 30/09), the event information on top (race_screens: Desktop.eventBox) and under it
  -- the column with the event, the car and the messages (the chat can stay empty)
  local LOBBY_W, EVENT_W = 360, 380
  local function lobbyAt(p1, s)
    local me = RaceTable.byIndex[0]
    local LW = LOBBY_W * s
    local msgs = {}
    for i = #Audit.items, 1, -1 do
      local it = Audit.items[i]
      if it.area == nil or it.area == 'rc' or Audit.allow(it.area) then msgs[#msgs + 1] = it end
      if #msgs >= 8 then break end
    end
    local p2 = vec2(p1.x + LW, p1.y + (30 + 5 * 13 + 22 + math.max(#msgs, 1) * 24 + 8) * s)
    Drag.group = nil
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(config.eventName ~= '' and config.eventName:upper() or TEXTS.lobbyTitle, FONT_TITLE, 12 * s,
      vec2(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    drawTextRight(TEXTS.sessionName[sim.raceSessionType] or '', FONT_MONO, 10 * s, p2.x - 14 * s, p1.y + 5 * s, COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local y = p1.y + 27 * s
    local pen = Panel.cellPenalties()
    local rows = {
      { TEXTS.scrPosition, me and ('P' .. me.pos .. (me.class and string.format(' - class P%d %s', me.classPos, me.class) or '')) or '-' },
      { TEXTS.lobbyStops, string.format('%d / %d', PitRecord.stops, config.pitStopsRequired) },
      { TEXTS.scrPending, pen and pen.value or '-' },
      { TEXTS.lobbyKmr, string.format('%s / %d - %s', Audit.points and tostring(Audit.points) or '-', config.kmrPoints.limit,
        Audit.rating and Audit.num(Audit.rating) or '-') },
      { TEXTS.lobbyWeather, string.format('%.0f / %.0f C', CarRead.num(sim.ambientTemperature), CarRead.num(sim.roadTemperature)) },
    }
    for _, r in ipairs(rows) do
      drawText(r[1], FONT_TEXT, 10 * s, vec2(p1.x + 14 * s, y), COLOR_DIM)
      drawTextRight(r[2], FONT_MONO, 10 * s, p2.x - 14 * s, y, r[2] == '-' and COLOR_OFF or COLOR_TITLE)
      y = y + 13 * s
    end
    drawSeparator(p1, p2, y + 3 * s, s)
    y = y + 8 * s
    drawText(TEXTS.lobbyMessages, FONT_TITLE, 10 * s, vec2(p1.x + 14 * s, y), COLOR_DIM)
    y = y + 14 * s
    if #msgs == 0 then drawText(TEXTS.auditEmpty, FONT_MONO, 9 * s, vec2(p1.x + 14 * s, y), COLOR_OFF) end
    for _, it in ipairs(msgs) do
      drawText(it.src, FONT_TITLE, 9 * s, vec2(p1.x + 14 * s, y), SRC_COLOR[it.src] or COLOR_TITLE)
      ui.pushDWriteFont(FONT_TEXT)
      ui.setCursor(vec2(p1.x + 60 * s, y))
      ui.dwriteTextAligned(it.text, 9 * s, ui.Alignment.Start, ui.Alignment.Start, vec2(LW - 74 * s, 22 * s), true, COLOR_TITLE)
      ui.popDWriteFont()
      y = y + 24 * s
    end
  end
  -- The two, one over the other, right edges at `right`, from `top`
  local function lobbyStack(right, top, s)
    local bottom = Desktop.eventBox and Desktop.eventBox(vec2(right, top), s, true) or top
    lobbyAt(vec2(math.floor(right - LOBBY_W * s), math.floor((bottom or top) + 8 * s)), s)
  end
  local function lobby(w, h, s)
    lobbyStack(math.floor(w - 24 * s), math.floor(h * 0.12), s)
  end
  -- The same in a window of the CSP (finding 18 of 29-30/09: the drawing of the script does not show over the pits
  -- menu): opened when the pits menu opens, closed when it closes. Read every frame by the desktops (Desktop.update)
  -- Also drawn by the exclusive HUD callback of the CSP in the 'menu' mode (finding of 30/09: the window did not show
  -- over the pits menu): the event and the column on the right of the menu, under the AC menu itself
  local lobbyWin, lobbyOpen, lobbyHud = nil, false, false
  Desktop.lobbyUpdate = function()
    -- The race direction keeps the names of the drivers seen (decision 274)
    if config.canCommand then
      for i = 0, (sim.carsCount or 1) - 1 do
        local c = ac.getCar(i)
        if c and (i == 0 or c.isConnected) then seenAdd(tostring(ac.getDriverName(i) or '')) end
      end
    end
    if not lobbyHud and ui.onExclusiveHUD then
      lobbyHud = true
      ui.onExclusiveHUD(function(mode)
        if mode ~= 'menu' then return end
        local size = ac.getUI().windowSize
        lobby(size.x, size.y, math.min(math.max((size.y / 1080) ^ 0.3, 1), 1.3))
      end)
      ac.log('race-control: lobby drawn in the pits menu (exclusive HUD, menu mode)')
    end
    if not ui.addSettings then return end
    if not lobbyWin then
      local ok, win = pcall(ui.addSettings, { icon = ui.Icons.Settings, name = TEXTS.lobbyWindow, id = 'rc.lobby',
        category = 'main', keepClosed = true, padding = vec2(0, 0),
        size = { default = vec2(EVENT_W + 8, 760), min = vec2(300, 200), max = vec2(1400, 1200) } },
        function() lobbyStack(EVENT_W, 0, 1) end)
      lobbyWin = ok and win or false
    end
    if not lobbyWin or sim.isInMainMenu == lobbyOpen then return end
    lobbyOpen = sim.isInMainMenu
    pcall(lobbyWin, lobbyOpen and 'open' or 'close')
    ac.log('race-control: lobby window ' .. (lobbyOpen and 'opened' or 'closed'))
  end

  -- Over the panel (decisions 209, 213, 219): the car controls on the left and the server message taken off the chat on
  -- the right, each for a few seconds, together as wide as the panel; under the panel and its boxes when there is no
  -- room over it. 56 px high: the source and three lines of the message. Their room is kept in the limit of the panel
  -- drag (Drag.fitPanel), shown or not
  local CONTROLS_W = 196
  local function messageWindow(w, h, s)
    local mh, gapW = 56 * s, 6 * s
    Drag.panelExtra = mh + gapW
    local msg = Audit.current()
    local controls = controlsShown()
    if not msg and not controls then return end
    -- The panel and its boxes; with the panel off, its place (screen.lua: 18% of the height + 10 px, 520 x 66)
    local pr = Drag.lastRects.panel
    local o = Drag.offset('panel', h)
    local rw = pr and (pr.max.x - pr.min.x) or 520 * s
    local cx = pr and (pr.min.x + pr.max.x) / 2 or (w / 2 + o.x)
    local top = pr and pr.min.y or (h * 0.18 + 10 * s + o.y)
    local bottom = pr and pr.max.y or (top + 66 * s)
    local y = top - gapW - mh
    if y < 0 then y = bottom + gapW end
    local x0 = math.floor(math.min(math.max(cx - rw / 2, 0), w - rw))
    Drag.group = nil
    local cw = CONTROLS_W * s
    if controls == 'group' then controlsBox(vec2(x0, math.floor(y)), s)
    elseif controls == 'pit' then pitBox(vec2(x0, math.floor(y)), s)
    elseif controls == 'aero' then aeroBox(vec2(x0, math.floor(y)), s) end
    if not msg then return end
    local p1 = vec2(x0 + cw + gapW, math.floor(y))
    local p2 = vec2(x0 + rw, p1.y + mh)
    drawPanel(p1, p2, BORDER_BASE, s)
    -- The window is MESSAGES (order of 30/09); where the message came from on the right
    drawText(TEXTS.msgTitle, FONT_TITLE, 10 * s, vec2(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    drawTextRight(msg.src, FONT_MONO, 9 * s, p2.x - 14 * s, p1.y + 5 * s, SRC_COLOR[msg.src] or COLOR_DIM)
    ui.pushDWriteFont(FONT_TEXT)
    ui.setCursor(vec2(p1.x + 14 * s, p1.y + 17 * s))
    ui.dwriteTextAligned(msg.text, 10 * s, ui.Alignment.Start, ui.Alignment.Start, vec2(p2.x - p1.x - 26 * s, 36 * s), true,
      COLOR_TITLE)
    ui.popDWriteFont()
  end

  return function(w, h, s)
    messageWindow(w, h, s)
    if Desktop.editor then editor(w, h, s) end
    if Audit.open then audit(w, h, s) end
    if Desktop.buttons then buttonsScreen(w, h, s) end
    if Desktop.settingsOpen then settingsWindow(w, h, s) else Settings.shown = false end
    if Desktop.redOpen and config.role then redWindow(w, h, s) end
    if sim.isInMainMenu then lobby(w, h, s) end
    if Desktop.menu then menu(w, h, s) end
    if state.ui.clock < Desktop.indicatorUntil then indicator(w, h, s) end
  end
end)()
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
    -- 20 px at 1080p (decision 142)
    local fontSize = 20 * math.min(math.max(scale ^ 0.3, 1), 1.3)
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
  local cellW, fixedW = {}, 0
  for i, c in ipairs(PANEL_CELLS) do
    if c.widest then
      local vw = textWidth(c.widest, FONT_TITLE, (c.title and 13 or 15) * s)
      local tw = c.title and textWidth(c.title, FONT_TITLE, 10 * s) or 0
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
  -- Mode chosen by the driver (Drag): visible / auto-hide (something to show) / always hidden. In any mode the panel
  -- shows up with the mouse over its place and stopped at the pit place. Always hidden: the boxes below it too
  local pm = Drag.mode('panel')
  local panelPlace = { vec2(x, yMsg), vec2(x + boxW, yMsg + msgH) }
  Drag.zone('panel', panelPlace[1], panelPlace[2])
  local forced = Drag.hovered('panel') or ac.getCar(0).isInPit
  local stackOn = pm ~= 'hidden' or forced
  if intro or (Intro.done and (pm == 'visible' or (pm == 'auto' and (anyOn or text)) or forced)) then
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

  -- Flag box (E2, decision 194): red and yellow first, above the slowdown and the penalty boxes (finding 7 of 29-30/09:
  -- the flag over the slowdown); information and green / chequered below them; one flag at a time
  local flag = Flags.current
  local FLAG_COLORS = { red = BORDER_RED, yellow = BORDER_YELLOW, slippery = BORDER_YELLOW, blue = BORDER_BLUE,
    green = BORDER_GREEN, white = COLOR_TITLE, checkered = COLOR_TITLE, start = BORDER_YELLOW }
  local function drawFlag(yTop)
    local p2 = vec2(x + boxW, yTop + sdH)
    local col = FLAG_COLORS[flag.kind] or COLOR_TITLE
    local border = (flag.kind == 'white' or flag.kind == 'checkered') and BORDER_BASE or col
    drawFlagBox(vec2(x, yTop), p2, s, border, nil,
      flag.title, col, flag.line1, flag.line2, flag.kind, flag.alert and BORDER_RED or nil)
    -- Red flag (decision 224): the five lights lit on the right, reinforcing the alert of the panel; the start of the
    -- rolling start: the five lights green
    -- The lights as a real LED matrix (order of 30/09)
    if flag.kind == 'red' or flag.lights then
      local r = 10.5 * s
      local lit = flag.kind == 'red' and rgbm(1, 0.1, 0.08, 1) or rgbm(0.15, 1, 0.3, 1)
      for i = 1, 5 do
        local c = vec2(p2.x - 14 * s - r - (5 - i) * (2 * r + 5 * s), (yTop + p2.y) / 2)
        drawLedLight(c, r, lit, true, s)
      end
    end
    return p2.y + gap
  end
  if stackOn and flag and flag.group <= 2 then ySd = drawFlag(ySd) end
  -- Own start lights (decision 257, design 10): the gantry of the AC, 5 columns of 2 LED lights, over the guard of the
  -- panel (the strip on demand), not in a box; from the 22nd place back, in the last 5 s of a standing start
  local litColumns = Flags.startLights(ac.getCar(0))
  if litColumns then
    local r = 12 * s
    local g = 6 * s
    local colW = 2 * r + g
    local gw, gh = 5 * colW + g, 4 * r + 3 * g
    local cx = x + boxW / 2
    local top = math.max(yMsg - (Drag.panelExtra or 0) - 6 * s - gh, 0)
    ui.drawRectFilled(vec2(cx - gw / 2, top), vec2(cx + gw / 2, top + gh), rgbm(0.04, 0.04, 0.05, 0.92), 6 * s)
    for i = 1, 5 do
      local lx = cx - gw / 2 + g + r + (i - 1) * colW
      for j = 0, 1 do
        drawLedLight(vec2(lx, top + g + r + j * (2 * r + g)), r, rgbm(1, 0.1, 0.08, 1), i <= litColumns, s)
      end
    end
  end

  -- Gain check box (cut with a reference), in the place of the slowdown box, same size. The bar is the time
  -- advantage still left over the reference x (1 + tolerance): red while the car is faster than allowed, empty when
  -- slower. It only disappears when the car is back on track (never in the middle, so it does not blink).
  local cc
  for _, check in pairs(state.cutChecks) do if check.ref then cc = check end end
  if cc and stackOn then
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
    if stackOn and not cc and not sdHidden and sd and sd.active then
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
  if stackOn and not cc and sgIt and (StopAndGo.stopping or StopAndGo.resume) then
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
  if stackOn and not cc and dl.dsq == 0 and dtHead and dtHead.kind:sub(1, 2) ~= 'SG' then
    local p2 = vec2(x + boxW, yNext + sdH)
    local more = #dl.items > 1 and string.format(TEXTS.dtMore, #dl.items - 1) or ''
    local deadline = dtHead.laps < 0 and TEXTS.dtOverdue or dtHead.laps == 0 and TEXTS.dtThisLap
      or dtHead.laps == 1 and TEXTS.dtNextLap or string.format(TEXTS.dtWithinLaps, dtHead.laps)
    drawFlagBox(vec2(x, yNext), p2, s, BORDER_BASE, nil, TEXTS.dtTitle .. more, COLOR_TITLE,
      TEXTS.reason[dtHead.cat] or dtHead.cat, deadline, 'dt')
    yNext = p2.y + gap
  end
  if not stackOn then
    -- always hidden: no box below the panel
  elseif not cc and dl.dsq > 0 and dl.dsqStage ~= 1 then
    local p2 = vec2(x + boxW, yNext + sdH)
    drawFlagBox(vec2(x, yNext), p2, s, BORDER_RED, nil, TEXTS.dsqTitle, BORDER_RED, dl.dsqReason,
      dl.dsqStage == 2 and TEXTS.dsqTow or TEXTS.dsqStop, nil, BORDER_RED)
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

  -- Wrong way (rule 33), below the flag boxes: while the car goes against the direction of the track, the no entry sign with the metres so
  -- far and the limit
  local ww = WrongWay.back or 0
  if stackOn and not cc and dl.dsq == 0 and ww >= config.wrongWay.showMeters and ww > 0 then
    local p2 = vec2(x + boxW, yNext + sdH)
    local lim = config.wrongWay.maxMeters
    drawFlagBox(vec2(x, yNext), p2, s, BORDER_RED, nil, TEXTS.wrongWayTitle, BORDER_RED,
      string.format(TEXTS.wrongWayTurn, ww, lim), string.format(TEXTS.wrongWayLimit, lim), 'noentry')
    yNext = p2.y + gap
  end
  if stackOn and flag and flag.group >= 4 then yNext = drawFlag(yNext) end
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
    if title and stackOn then
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
  -- Before the opening nothing is on screen (the first thing is the opening): the pit screens wait for it too
  if config.mode == 'CSP' and Intro.done then
    -- Their own growth on screens bigger than 1080p, slightly more than the panel (screenScale); 1x at 1080p
    local sb = math.min(math.max((h / 1080) ^ config.screenScale.exponent, 1), math.max(config.screenScale.max, 1))
    drawPitBox(ac.getCar(0), w, h, sb)
    drawStatus(ac.getCar(0), w, h, sb)
    drawRaceScreens(ac.getCar(0), w, h, sb)
  end
  -- Desktop editor (gear of the panel) and desktop indicator (E4)
  drawDesktopUI(w, h, s)
  -- Icons of the panel (mode, pin, the other screens, reset), with the mouse over it
  Drag.icons('panel', panelPlace[1], panelPlace[2], s)
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
  -- The app must run with the script (decision 271)
  AppLink.update()
  -- The KMR numbers of this driver to the race direction (decision 278): asked to the KMR, then sent
  if car.lapCount > (Audit.askLap or car.lapCount) then Audit.askPending = true end
  Audit.askLap = car.lapCount
  if sim.isOnlineRace ~= false then Audit.kmrAsk() end
  Audit.kmrSend()
  -- A reset of the car seen since the last frame (ac.onCarJumped): read by the session start below, then cleared
  local jumpedNow = state.jumpSinceUpdate
  state.jumpSinceUpdate = false
  -- Session start (decision 218): another session index (and the first frame of the script), or the start / restart
  -- event of the SDK (a restarted session keeps its index). First thing in the frame: nothing of the session before
  -- reaches the new one (the pit pass, the stops, the car record)
  if sim.currentSessionIndex ~= state.lastSessionIndex or state.sessionStartPending then
    -- Within the running script (not its first frame): the car was reset by the game, not moved by the driver
    local transition = state.lastSessionIndex ~= -1
    ac.log(string.format('race-control: session start (index %d%s%s)', sim.currentSessionIndex,
      state.sessionStartPending and ', start event' or '', transition and '' or ', script start'))
    state.sessionStartPending = false
    -- A new session or a restart within the running script: the records of the run before are not taken (decision 275)
    if transition then
      Record.fresh()
      -- The red flag belongs to its session (a script reload keeps it: the track record of this process)
      state.redFlag = nil
    end
    l.curLap = lapCount
    state.lastSessionIndex = sim.currentSessionIndex
    -- The reset of the car by the session start is no tow (a tow of the session before does not go on)
    l.jumped = false
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
    Start.reset()
    state.pitPaid = nil
    state.dsqFlagPutBack = nil
    -- CODE-80 in force: kept on a script reload; otherwise it comes from the other drivers (RecordSync.askOwn below)
    TrackList.load()
    -- Car state: put back after a new connection or a driver swap (from this computer or the other drivers)
    CarState.load(transition and jumpedNow)
    -- Stops with service and the hold in progress (it goes on after a new connection)
    state.hold = nil
    PitRecord.load(transition)
    PitStops.wasInPitlane = nil
    PitStops.passInWindow = false
    PitStops.pass = nil
    PitStops.line = 0
    PitStops.endChecked = false
    -- A new session or a restart within the running script: the game puts the car back (not the script's first frame)
    if transition then PitStops.settleUntil = state.ui.clock + PitStops.SETTLE_SECONDS end
    DriverTable.reset()
    RaceTable.load()
    Audit.load()
    WrongWay.reset()
    PitBox.reset()
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
  CarControls.update(dt)
  -- Detector of the car changes (lights, limiter, engine, reverse, camera) with the inputs and our actions
  Diag.update(car)
  -- Movement of the car (position frame to frame): shared by the spin check and the wrong way rule
  CarRead.updateMotion(car)
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
  -- Desktops: next / previous desktop and screen, and the D-pad on the screen in focus (E4)
  Desktop.update(car)
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
    -- The game took its black flag off while the DSQ of this session is in force (seen after the checkered flag of a
    -- qualifying): logged with the session state; put back once in the session (decision 175); taken off again, only
    -- logged. The controls stay locked and the text stays (the DSQ belongs to the session)
    if g.t ~= BLACK_FLAG and l.prevGame.t == BLACK_FLAG and l.dsqStage == 1 then
      local putBack = not state.dsqFlagPutBack
      ac.log(string.format('race-control: game black flag taken off by the game (session type %s, time left %.0f s, '
        .. 'session finished %s, game penalty %s/%s)%s', tostring(sim.raceSessionType), (sim.sessionTimeLeft or 0) / 1000,
        tostring(sim.isSessionFinished), tostring(g.t), tostring(g.p), putBack and ', put back' or ''))
      if putBack then
        state.dsqFlagPutBack = true
        physics.setCarPenalty(BLACK_FLAG)
      end
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
      showNotice(TEXTS.rcTitle, TEXTS.practiceTowCleared)
    end
    -- Practice (decisions 13, 14, 86): the car at its pit place (back to the session, tow, or driven in) clears the
    -- penalties and the slowdowns in progress. With practiceTow clearDsq:1 (decision 148) also the DSQ: the game black
    -- flag is taken off and the controls released after the tow (forced or by the driver) or back to the session; the
    -- DSQ rules themselves do not change. The driver is told on screen (finding 15 of 29-30/09: a stop & go cleared this
    -- way showed nothing)
    local practice = sim.raceSessionType == ac.SessionType.Practice
    if practice and CarRead.parked(car) then DamageClass.reset() end
    if practice and CarRead.parked(car) and dsqActive and (config.tow[ac.SessionType.Practice].clearDsq or 0) == 1 then
      carDsqClear('practice, car at its pit place')
      Rules.zero()
      l.invalidLap = nil
      dsqActive = false
      rcLog('Pit', 'Practice - disqualification cleared at the pit place')
      showNotice(TEXTS.rcTitle, TEXTS.practiceDsqCleared)
    elseif practice and CarRead.parked(car) and not dsqActive
        and (#l.items > 0 or next(state.slowdowns) or #l.endOfLap > 0) then
      Rules.zero()
      l.invalidLap = nil
      ac.log('race-control: practice, car at its pit place: penalties cleared')
      rcLog('Pit', 'Practice - pending penalties cleared at the pit place')
      showNotice(TEXTS.rcTitle, TEXTS.practiceCleared)
    end
    local repairing = CarRead.flagOn(car.isRepairing)
    if towOn and not dsqActive and not state.hold then
      if tw.jumpPending and inPit and state.redFlag then
        -- Red flag (decision 270): the car waits at its pit place; the tow and repair time starts at the restart
        local d = tw.damage or { powertrain = 0, suspension = 0, body = 0 }
        state.redTow = { tow = towRule.towSeconds, damage = { powertrain = d.powertrain, suspension = d.suspension,
          body = d.body } }
        PitRecord.save()
        ac.log('race-control: tow under the red flag: tow and repair time at the restart')
        rcLog('Tow', TEXTS.redTowDeferred)
        showNotice(TEXTS.rcTitle, TEXTS.redTowDeferred)
      elseif tw.jumpPending and inPit then
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
    TyreUse.update(car, lineFrame)
    DamageClass.update(car, lineFrame)
    -- Flags: this car's incident told to the others; the flag of this car now (E2)
    Start.update(car)
    Flags.update(car, lineFrame)
    -- Race table, this car's laps and the driver's stint (E3)
    RaceTable.update(car, lineFrame, viaPit)
    CarState.update(car, lineFrame)
    DsqFlow.update(car, lineFrame)
    Ban.update()

    -- Pit lane speeding measured by the script: the PSE enters at the pit exit (decisions 79, 89, 90)
    PitSpeed.update(car, inPit, lapCount)
    Rules.invalidLaps(car)
    if not (state.dtDsqActive or state.pitDsqActive) then
      WrongDriver.update()
      -- Driving the wrong way: our rule (the CSP penalty is off on the server)
      WrongWay.update(car)
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
