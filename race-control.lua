-- race-control.lua — Racing Control, CSP online script (AMX Racing)
--
-- ============================================================================================================
-- LEGAL NOTICE
--
-- Copyright (c) 2026 AMX RACING, amx racing, amx mods, 12h Curitiba and Codice - Sistemas. All rights reserved.
--
-- This software, including its source code, rules logic, texts, layouts and documentation, is the exclusive
-- property of AMX RACING, amx racing, amx mods, 12h Curitiba and Codice - Sistemas. It is proprietary and
-- confidential, and it is NOT open source.
--
-- No license is granted. Without the prior written authorization of the copyright holders, it is prohibited to:
--   - use, run or host this software, in whole or in part, on any server, event or championship other than the
--     ones organized or authorized by AMX RACING or 12h Curitiba;
--   - copy, reproduce, modify, adapt, translate or create derivative works from it;
--   - distribute, publish, sell, rent, sublicense or otherwise make it available to third parties;
--   - remove, alter or hide this notice or any other ownership or authorship information.
--
-- Its publication at a public address exists only so that the game clients of the AMX RACING and 12h Curitiba servers can
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
-- Authorization requests: amxracingg@gmail.com / 12hcuritiba@gmail.com / suporte@codice-ti.com.br
-- ============================================================================================================
local cfg = ac.configValues({
  control = '', cockpit = '', event = '', roles = '', staffPits = '', kmr = '', base = '', driverSwap = '', pitStops = '',
  pitWindow = '', pitExit = '', pitSpeed = '', dsq = '', cutZone1 = '', cutZone2 = '', slowdown = '',
  announce = 0,
  penaltyMode = 'CSP',
  forceCockpit = 0,
  cockpitCameraMode = 0,
  cockpitCheckInterval = 0.05,
  code80FreezeDeadlines = 1,
  dataCheck = 1,
  screenScale = '',
  screens = '',
  tyreLife = '',
  tyreTemp = '',
  flags = '',
  restart = '',
  formation = '',
  eventName = '',
  raceControlSteamID = '',
  staffSteamIDs = '',
  broadcastSteamIDs = '',
  cockpitExemptSteamIDs = '',
  classes = '',
  kmrPoints = '',
  kmrRating = '',
  kmrStatsUrl = '',
  baseUrl = '',
  gameHud = 'hide',
  lobbyPos = '',
  practiceDriverSwap = 0,
  qualifyDriverSwap = 0,
  raceDriverSwap = 0,
  driverSwapMinSeconds = 120,
  driverSwapRequired = '',
  wrongDriverSeconds = '120',
  driverStint = '',
  pitStopOrder = 'F<TR>',
  pitStopMode = 'AUTO',
  swapWindowStartMinutes = 0,
  swapWindowEndMinutes = 0,
  pitWindowStartMinutes = 0,
  pitWindowEndMinutes = 0,
  pitStopsEnabled = 0,
  pitStopsRequired = 0,
  practiceClosedSeconds = 60,
  qualifyClosedSeconds = 120,
  raceClosedSeconds = 60,
  practicePenalty = 'REPRIMAND',
  qualifyPenalty = 'DSQ',
  racePenalty = 'SG:10',
  practicePenaltyParam = -1,
  qualifyPenaltyParam = -1,
  racePenaltyParam = -1,
  pitSpeedLimit = 60,
  pitSpeedTolerance = 2,
  pitSpeedDeadlineLaps = 1,
  wrongWay = '',
  parkedCar = '',
  stopAndGo = '',
  holdShortSeconds = 45,
  holdLongSeconds = 90,
  practiceTow = '',
  qualifyTow = '',
  raceTow = '',
  repairFormula = '',
  damage = '',
  dsqBlackFlagLaps = 3,
  cutZoneStart = 0.16,
  cutZoneEnd = 0.24,
  practiceCutPenalty = 'SLOW DOWN',
  qualifyCutPenalty = 'SLOW DOWN',
  raceCutPenalty = 'SLOW DOWN',
  practiceCutPenaltyParam = 0,
  qualifyCutPenaltyParam = 0,
  raceCutPenaltyParam = 0,
  cutSlowdownDeadline = 10,
  cutMaxWheelsOut = 3,
  cutSlowdownMaxGas = 0.2,
  cutGainTolerance = 6,
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
  practiceSlowdownUnpaidPenalty = 'DT',
  qualifySlowdownUnpaidPenalty = 'DT',
  raceSlowdownUnpaidPenalty = 'DT',
  cutSpinAngle = 90,
})
local RC_VERSION = 'V166 - 2026.10.10'
local TEXTS = {
  rc = {
    baseOff = 'Base offline', chatSeen = 'Chat seen', damageBeyond = 'Damage beyond safety limit',
    dataCheck = 'Data check', diag = 'Diagnostic', dsq = 'Disqualified', dt = 'Drive-through',
    dtKmr = 'Drive-through DT', dtAfterDsq = 'Drive-through after the DSQ', dtCancelled = 'Drive-through cancelled',
    dtCancelledKmr = 'Drive-through cancelled by KMR', dtNotServed = 'Drive-through not served',
    dtRelaxed = 'Drive-through relaxed', dtServed = 'Drive-through served',
    dtServedSg = 'Drive-through served in stop & go', swap = 'Driver swap', formation = 'Formation lap',
    green = 'Green flag', incident = 'Incident', kmrUnread = 'KMR message not read', lastLap = 'Last lap', pit = 'Pit',
    pitPlan = 'Pit stop plan', pitWindow = 'Pit window', stopWindow = 'Pit stop window', qualiEnd = 'Qualifying ended', raceRestart = 'Race restart',
    command = 'Racing Control command', commandUnread = 'Racing Control command not understood', red = 'Red flag',
    redOff = 'Red flag off', regIncomplete = 'Registration incomplete', repairDone = 'Repair done',
    repairReq = 'Repair required', rollingStart = 'Rolling start', sessionEnd = 'Session end',
    editedFileDetail = 'record %s - car %d - ban pending',
    standingRestart = 'Standing restart', standingRestartOff = 'Standing restart cancelled',
    standingStart = 'Standing start', start = 'Start', teamSetup = 'Team setup', tow = 'Tow', lights = 'Track lights',
    wrongDriver = 'Wrong driver', wrongWay = 'Wrong way', wrongWayOff = 'Wrong way cleared',
    hold = 'Hold %d s', sgServed = 'Stop & go served', sgServiced = 'Service at the pit - stop & go not served in this pit pass',
    parked = 'Car stopped on track', swapBox = 'DRIVER SWAP', swapInvalid = 'INVALID DRIVER SWAP', conn = 'Connection',
    driver = 'Driver', timePenalty = 'Time penalty', sgSeconds = 'Stop & go %d s', reprimand = 'Reprimand',
  },
  pit = {
    DSQ = 'Pit lane left with the pit closed - disqualified',
    REPRIMAND = 'Pit lane left with the pit closed - reprimand',
  },
  cut = {
    SLOWDOWN = 'Exclusion zone cut - slow down',
    DT = 'Exclusion zone cut - drive-through',
    DSQ = 'Exclusion zone cut - disqualified',
  },
  timerPay = 'SLOW DOWN  ',
  timerSeconds = '%.1f s',
  timerDeadline = '   deadline ',
  timerDeadlineSeconds = '%.0f s',
  timerEnd = ' or end of lap',
  sdTitle = 'EXCLUSION ZONE CUT - slow down',
  liftTitle = 'EXCLUSION ZONE CUT - lift to avoid a slowdown',
  liftSlower = 'slower - no penalty',
  liftFaster = 'faster - slowdown',
  liftLimit = '+%g%% ref',
  rcPrefix = '[RC] ',
  rcTitle = 'RACING CONTROL',
  introText = 'RACING CONTROL  ' .. RC_VERSION,
  introStatus = 'STATUS OK',
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
  sgPending = 'Stop & go %d s - stop at your pit this lap or next',
  sgLastLap = 'LAST LAP - Stop & go %d s - stop at your pit now',
  sgOverdue = 'OVERDUE - Stop & go %d s - stop at your pit',
  sgServiced = 'Service at the pit - stop & go not served in this pit pass',
  sgAnnulled = 'Service started - stop & go payment annulled',
  practiceCleared = 'Practice - penalties cleared at the pit place',
  pitSpeedNotPaid = 'Pit lane speeding - the drive-through of this pass does not count', practiceTowCleared = 'Practice - penalties cleared by the tow',
  practiceDsqCleared = 'Practice - disqualification cleared at the pit place',
  sgStopped = 'Stop & go %s - stay stopped, no service',
  sgInterrupted = 'Stop & go interrupted - %s left - only the same driver may continue',
  pitMissedLog = 'MISSED - no valid driver swap inside the pit window',
  stopWindowMissedLog = 'MISSED - no pit stop inside the window of the mandatory pit stop',
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
  pitStrategy = 'Strategy', pitStrategyTab = 'STRATEGY', pitPresetN = 'Preset %d', pitBack = 'Back',
  pitStrategyHint = 'Right: use it   Left: back',
  pitPressure = 'Pressure',
  pitRepairSuspension = 'Suspension repair',
  pitRepairPowertrain = 'Powertrain repair',
  pitRepairBody = 'Bodywork repair',
  pitRepairYes = 'Repair',
  pitRepairNo = 'No',
  pitRepairNone = 'None',
  pitFuelLocked = 'Locked - red flag', pitRepairLocked = 'After the restart',
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
  damageRepairLaps = 'REPAIR REQUIRED - %d LAPS',
  damageRepairLast = 'REPAIR REQUIRED - LAST LAP',
  damageBent = 'Suspension bent - %s',
  damageSuspension = 'Suspension %s',
  damageAngle = '%s +%.1f°',
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
  dsqTitle = 'DISQUALIFIED',
  dsqStop = 'Stop at your pit before the line',
  dsqTow = 'Car withdrawn - return to pits',
  dsqOut = 'Out of the session - controls locked',
  dsqSafety = 'Safety hazard - damage beyond the safety limit',
  editedFile = 'Edited file',
  kmrTitle = 'KMR',
  swapActive = 'DRIVER SWAP ACTIVE',
  swapTitle = 'DRIVER SWAP',
  swapDisconnect = 'Disconnect to perform the driver swap',
  swapWait = 'You are now driving - wait %s before leaving the pits',
  swapClear = 'You are clear to leave the pits - GO GO!',
  swapTimes = 'Elapsed %s / Total %s',
  code80 = 'CODE 80 - no penalty can be served until the green flag',
  holdTitle = 'HOLD',
  hold = 'Hold %s - %s',
  holdTwoDT = 'Two pending drive-throughs',
  holdTwoDTLong = 'Two pending drive-throughs (pit lane speeding expired on track)',
  towReason = 'Back to pits',
  qualiEndTow = 'tow', qualiEndHold = 'Qualifying ended - %s',
  qualiEndNotice = 'Qualifying ended (%s) - your best valid lap counts',
  repairReason = 'Repair in the pit stop',
  parkedFlagTitle = 'CAR STOPPED ON TRACK', parkedMove = 'Move on - %d s', parkedLeft = 'Stops tolerated left: %d of %d - over: disqualified', parkedNoGrace = 'Not moving on: disqualified',
  parkedTitle = 'Car stopped on track', parkedLog = 'stop %d of %d tolerated', parkedDsq = 'Car stopped on track',
  parkedDsqDetail = 'over %d stops of %d s', parkedTimeLog = '%d s - out of fuel on track',
  parkedFuelRace = 'Out of fuel on track - %d s added to your race time', parkedFuelLaps = 'Out of fuel on track - your laps are invalid from now on',
  parkedFuelLapsLog = 'out of fuel - laps invalid from now on',
  timeNotServedLog = '%d s - %s not served at the end of the race', timeNotServedTitle = 'PENALTY NOT SERVED',
  dtServedWhy = '%s - served in the pit pass (deadline DT%d)', holdIncludes = 'includes %s', dsqVoided = 'pending when the DSQ came: %s',
  practiceClearedWhat = 'Practice - cleared at the pit place: %s',
  timeNotServed = '%d s added to your final time: %s not served',
  reason = {
    SD1 = 'Exclusion zone cut - zone 1',
    SD2 = 'Exclusion zone cut - zone 2',
    PSE = 'Pit lane speeding',
    RC = 'Racing Control decision',
    JS = 'Jump start at the standing restart',
    JSS = 'Jump start at the race start',
    FS = 'Over the speed limit on the formation lap',
    FL = 'Under the minimum speed on the formation lap',
    FP = 'Overtaking on the formation lap not given back',
    PX = 'Left the pits before the car ahead at the race restart',
  },
  kmrReasons = {
    K0 = 'KMR penalty', K1 = 'Pit exit line crossing', K2 = 'Pit lane speeding', K3 = 'Infraction limit',
    K4 = 'Collision with a car lapping you', K5 = 'Collision with a car in a hot lap', K6 = 'Hot lap disturbed',
    K7 = 'Reverse gear', K8 = 'Car parked near the track', K9 = 'Too many collisions', K10 = 'Speeding under VSC',
    K11 = 'Slowing under VSC', K12 = 'Overtaking under VSC', K13 = 'Cut line', K14 = 'Blue flags ignored',
    K15 = 'Rejoining the track at high speed',
  },
  dsqBlackFlag = 'Black flag',
  dsqDtReason = 'Drive-through not served',
  wrongWayDsq = 'Driving the wrong way',
  swapVoidService = 'Driver swap not valid - service in the same pit stop',
  swapVoidSg = 'Driver swap not valid - stop & go served in the same pit stop',
  swapInvalidTitle = 'INVALID DRIVER SWAP',
  swapInvalidLeave = 'Stop & go served in this stop - leave the car, do not leave the pits',
  swapInvalidDsq = 'Driver swap in the stop where the stop & go was served',
  swapInvalidLeftDsq = 'Left the pits after an invalid driver swap',
  wrongWayTitle = 'WRONG WAY',
  wrongWayTurn = 'Turn around - %.0f / %d m',
  wrongWayLimit = 'Over %d m: disqualified',
  dtTitle = 'DRIVE-THROUGH',
  dtMore = '  +%d',
  dtThisLap = 'Serve it this lap',
  dtNextLap = 'Serve it this lap or the next',
  dtWithinLaps = 'Serve it within %d laps',
  dtOverdue = 'OVERDUE - serve it at the next pit pass',
  pitWindowDsq = 'Driver swap window missed', stopWindowDsq = 'Mandatory pit stop missed',
  swapEarlyDsq = 'Left the pits before the driver swap time',
  swapsMissingDsq = 'Driver swaps missing (%d of %d)',
  stopsMissingDsq = 'Pit stops missing (%d of %d)',
  driverRow = 'Driver',
  driverRowText = 'swap %d%s - team %s - GUID %s',
  driverRowRejoin = ' (rejoin)',
  pitStopRow = 'Pit',
  pitStopRowText = 'line %d - stop %s - in %s - out %s - %s - %s - %s - flags %s/%s - team %s - GUID %s',
  pitStopRowInPits = 'in the pits',
  pitStopRowNoService = 'no service',
  pitStopRowNoPenalty = 'no penalty',
  stintMinDsq = 'Driving time under the minimum (%s of %d min, whole race)',
  stintMaxDsq = 'Driving time over the maximum (%d min, whole race)',
  kmrRatingDsq = 'KMR safety rating %s (limit %s)',
  scrRelative = 'RELATIVE', scrStandings = 'STANDINGS', scrLapTime = 'LAP TIME', scrDelta = 'DELTA', scrVsBest = 'vs BEST',
  scrLaps = 'LAPS', scrLapN = 'Lap %d', scrStint = 'STINT - %s - %d laps', scrRace = 'RACE STATUS',
  scrCurrent = 'Current', scrNow = 'Now', scrBest = 'Best', scrOptimal = 'Optimal', scrLast = 'Last',
  scrSession = 'Session', scrInvalid = 'INVALID', scrTime = 'Time left', scrPosition = 'Position', scrLap = 'Lap',
  scrLeader = 'Leader', scrAhead = 'Ahead', scrBehind = 'Behind', scrStops = 'STOPS', scrSwaps = 'SWAPS',
  scrWindow = 'PIT WINDOW', scrStintLine = 'STINT', scrTyres = 'Tyres', scrPending = 'Pending',
  scrOpt = 'Opt.', scrCarBest = 'Car best', scrStintN = 'STINT %d - %s', scrStintInfo = '%d laps - %s',
  scrStintMin = ' / min %d', scrDriveTotal = 'race %s', scrBestAvg = 'Best %s - avg %s', scrDeltaButton = 'Δ',
  scrDeltaRefs = { best = 'BEST', session = 'SESS', optimal = 'OPT', alltime = 'ALL' }, scrDeltaSectors = 'SECTORS',
  cmWatch = 'WATCH ON BOARD', cmMine = 'MY CAR', cmNoWatch = 'watch on board: off on this server (roles watch:1)',
  scrGaps = 'GAPS', scrObligations = 'OBLIGATIONS', scrTrack = 'Track', scrKmr = 'KMR points',
  exitTitle = 'RACE RESTART', exitLine1 = 'Pit exit in single file - restart order',
  exitWait = 'Wait at your pit place - leave after %s passes', exitGo = 'Your turn - leave the pits now, single file',
  exitFirst = 'First of the restart order - leave the pits now', exitEarlyLog = 'Left the pits before %s passed (out of the restart order)',
  scrKmrRating = 'KMR rating', scrKmrCrashes = 'KMR crashes', scrKmrInfr = 'KMR infractions', scrKmrKm = 'KMR distance',
  scrKmrNone = 'none yet',
  sessionName = { [ac.SessionType.Practice] = 'PRACTICE', [ac.SessionType.Qualify] = 'QUALIFY', [ac.SessionType.Race] = 'RACE' },
  edTitle = 'SCREENS', edPitDesk = 'Pit desktop', edDeskOf = 'Desktop %s of %d', edHint = 'drag a screen to its place - title line moves this window',
  edAll = 'all', edScreens = 'Screens', edReset = 'Reset desktop', edDefault = 'Default desktop',
  edCopy = 'Copy from 1', edDelete = 'Delete desktop',
  edPitOn = 'PIT desktop on', edPitOff = 'PIT desktop off',
  edPitWarning = 'PIT desktop off: nothing more is shown in the pit lane - at your own risk',
  edButtons = 'Next screen %s - Previous screen %s - Next desktop %s - Previous desktop %s (CSP controls)',
  edIndicator = 'DESKTOP %d / %d - %s',
  menuButtons = 'Buttons', navTitle = 'BUTTONS', navOwn = 'RECORDED BY THE TOOL', navCsp = 'CSP CONTROLS',
  navTabs = { nav = 'Navigation', screens = 'Open / close screens' },
  navNextScreen = 'Next screen', navPrevScreen = 'Previous screen', navNextDesktop = 'Next desktop',
  navPrevDesktop = 'Previous desktop', navShowPanel = 'Show panel (5 s)', navSet = 'Set', navClear = 'Clear', navPress = 'Press a button... %d s',
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
  dirNextSession = 'NEXT SESSION', dirRestart = 'RESTART SESSION', dirCancelDt = 'NO DT', dirToPit = 'TO PIT', dirFuel = 'FUEL', dirMenu = 'MENU 5 MIN',
  setTitle = 'SETTINGS', setTabs = { messages = 'Messages', controls = 'Controls', text = 'Text', design = 'Design', app = 'App', room = 'Racing Room' },
  setFontSample = 'RACING CONTROL  P3  Slow down', setFontMissing = 'not installed', setTextMin = 'Small text at least', setTextMinOff = 'Off', setOpacity = 'Opacity', setPreset = 'Preset',
  setPresets = { verbose = 'Verbose', race = 'Race', minimal = 'Minimal', custom = 'Custom' }, setAlways = 'always - on the Racing Control panel',
  setAreas = { rc = 'Racing Control, flags, driver swap, race director', limits = 'Track limits and invalid laps',
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
  dirLightsRed = 'LIGHTS RED', dirLightsGreen = 'LIGHTS GREEN', dirLightsAuto = 'LIGHTS AUTO',
  redGreen = 'GREEN', dirVsc = 'VSC %d s', dirMoney = 'RESET POINTS', dirStats = 'RESET STATS', dirBan = 'BAN', dirUnban = 'UNBAN', dirNoSg = 'NO S&G', dirNoDsq = 'NO DSQ',
  dirKmrLine = 'KMR  points %s / %d  -  safety %s  -  %s  -  infractions %s (%s / 100 km)',
  dirPrompt = 'Prompt', dirPromptSent = 'Sent: %s', dirKmrCrashes = 'crashes %s (%s / 100 km)', dirBalRes = 'ballast %.0f kg  restrictor %.0f', dirKmrLaps = '  -  laps %d best %s', dirKmrNoStats = 'stats: none yet (not driven enough)',
  dirKmrNone = 'KMR  no numbers from this driver yet',
  dirPenNone = 'Penalties  none', dirPenTitle = 'Penalties  ', dirPenDt = '%s DT%d', dirPenSg = 'S&G %d s', dirPenDsq = 'DSQ',
  dirPenUnknown = 'Penalties  no list from this driver yet',
  dirDriver = 'Driver',
  dirWebLine = 'points %s - %s - infr %s (%s/100km) - crashes %s (%s/100km) - laps %d best %s',
  dirWebOthers = 'Registered in the KMR',
  dirWebErr = 'KMR web stats not read: %s', dirWebOff = 'KMR web stats: key kmrStatsUrl empty', dirValue = 'Value', dirBallast = 'BALLAST', dirRestrictor = 'RESTRICTOR',
  kmrEvBtn = 'KMR EVENTS', kmrEvTitle = 'KMR EVENTS - RACE CONTROL OF THE SESSION', kmrEvConnecting = 'Connecting to the KMR race control...',
  kmrEvErr = 'KMR race control not reached: %s', kmrEvNone = 'No event', kmrEvReplay = 'REPLAY', kmrEvBack = '< LIST', kmrEvLoading = 'Loading the replay from the KMR...',
  kmrEvNoData = 'The KMR gave no replay for this event', kmrEvPlay = 'PLAY', kmrEvPause = 'PAUSE', kmrEvToEvent = 'EVENT', kmrEvGear = 'gear',
  kmrEvLap = 'lap ', kmrEvReviewed = 'reviewed ', kmrEvLast = 'THIS SESSION', kmrEvAll = 'ALL SESSIONS',
  kmrEvKinds = { collision = 'COLLISION', cut = 'CUT', generic = 'INFO', overtake = 'OVERTAKE' },
  kmrEvFilters = { all = 'ALL', collision = 'COLLISIONS', cut = 'CUTS', generic = 'INFO' },
  dirNeedCarValue = 'Ballast / restrictor: a driver on the server in the field and a value', dirList = 'DRIVERS', dirListBtn = 'LIST', dirCmdBtn = 'COMMANDS', dirCmdTitle = 'COMMANDS', dirCmdHow = 'How: ', dirSessionTime = '%s elapsed / %s left',
  dirSessionLaps = 'lap %d', dirSessionLapsOf = 'lap %d / %d - %d left',
  dirLeft = 'Left the server', dirGuidAsk = 'Asking the KMR the GUID of %s',
  dirGuidNone = 'The KMR gave no GUID for %s (the name is case sensitive)', dirGuidGot = 'GUID of %s: %s',
  dirNoRed = 'No red flag nor VSC on', redKmrOn = 'KMR admin: logged in', redKmrOff = 'KMR admin: type /kmr login <password> in the chat',
  redPlace = 'pit place', redLane = 'pit lane', redTrack = 'track',
  where = { menu = 'MENU (ESC)', box = 'BOX (LOBBY)', pit = 'PIT', pitlane = 'PIT LANE', grid = 'GRID', stopped = 'STOPPED',
    track = 'TRACK' }, redCount = 'In the pits %d / %d - over the limit %d',
  scrPerf = 'PERFORMANCE', perfRows = { fps = 'FPS', cpu = 'CPU', gpu = 'GPU' },
  scrCalc = 'STRATEGY CALCULATOR', calcNotCar = 'not sent to the car', calcFuel = 'Fuel/lap', calcWear = 'Wear/lap (worst tyre)',
  calcLap = 'Mean lap', calcLaps = 'Flying laps',
  calcNoData = 'no data', calcNoDataShort = 'no data', calcNeedFlying = 'No data: %d of %d flying laps', calcMissing = 'No data: %s',
  calcParams = { race = 'Race length', lap = 'Lap used', tank = 'Tank', reserve = 'Reserve (laps)', pitloss = 'Pit lane loss',
    refuel = 'Refuel', tyres = 'Tyre change (each)' },
  calcRaceLaps = '%d laps', calcHead = { 'SC', 'WEAR', 'LIM', 'L/LAP', 'STP', 'L/ST', 'FUEL/ST', 'TYRE', 'PIT', 'TOTAL' },
  calcFields = { wear = 'wear %/lap', limit = 'tyre down to %', fuel = 'fuel L/lap', stops = 'stops' },
  calcAuto = 'AUTO', calcNo = 'NO', calcBest = 'Best scenario: %s', calcNone = 'No scenario fits in the tank and the tyre',
  scrCockpit = 'COCKPIT', cockpitCar = 'Settings of this car: %s', cockpitSave = 'SAVE', cockpitSaved = 'SAVED', cockpitNoApp = 'app not running', cockpitMore = '+ ALL', cockpitAudio = 'VOLUME - EVERY CHANNEL',
  cockpitRows = { ffb = 'Force feedback', y = 'Seat up / down', x = 'Seat left / right', z = 'Seat forward / back', pitch = 'Pitch up / down',
    fov = 'Field of view', ['vol.main'] = 'Volume (master)', ['hide.wheel'] = 'Steering wheel', ['hide.arms'] = 'Arms' },
  cockpitSections = { pos = 'DRIVING POSITION', ctl = 'CONTROL', view = 'DISPLAY', snd = 'SOUND' },
  cockpitShown = 'SHOWN', cockpitHidden = 'HIDDEN', menuCockpit = 'Cockpit',
  cockpitChannels = { engine = 'Engine', transmission = 'Transmission', tyres = 'Tyres', surfaces = 'Surfaces', dirt = 'Dirt',
    wind = 'Wind', opponents = 'Opponents', carComponents = 'Car components', track = 'Track', weather = 'Weather',
    rain = 'Rain', wipers = 'Wipers' },
  dirLogout = 'LOGOUT', dirLoggedOut = 'Logged out on this screen - the KMR has no logout: it forgets the login when you leave the server',
  dirKmrLost = 'KMR login not answered - it fell: log in again',
  dirResetBtn = 'RESET', dirReset = 'Window reset - fields, lists and place back to the start; KMR login checked',
  connLap = 'LAP ', connSector = 'S%d', connSpline = 'SPL %.3f', connPing = 'PING %d ms', connPingNone = 'PING -',
  connOk = 'CONNECTION OK', connHigh = 'PING HIGH', connKick = 'KMR KICK LIKELY - avg %.0f / dev %.0f ms', connStalled = 'DATA STALLED - DROP LIKELY',
  connAlert = 'ALERT  ', connAlertCar = '#%s %s: %s',
  connPitTitle = 'PIT  ', connStopped = 'stopped at the pit place %s', connOutAfter = 'driver out %s after the stop',
  connOutNoStop = 'driver out away from the pit place', connSwapTime = 'swap time %s / %s',
  connBackSame = 'same driver back after %s (swap time %s)', connBackOther = 'new driver in after %s (swap time %s)',
  connInTime = 'within the swap time', connLate = 'after the swap time',
  connCause = { pitPlace = 'left at the pit place', menu = 'ESC / menu - left the session', lost = 'connection lost',
    pingHigh = 'kicked by the KMR - high ping', pingUnstable = 'kicked by the KMR - unstable ping', kick = 'kicked',
    unknown = 'left - no menu seen, connection fine' },
  connGoneTitle = 'LEFT THE SERVER', connLeft = 'left', connTitle = 'Connection', connLog = '%s left the server - %s',
  lobbyTitle = 'RACING CONTROL', lobbyStops = 'Stops', lobbyKmr = 'KMR points / rating', lobbyWeather = 'Air / track',
  lobbyMessages = 'MESSAGES', lobbyWindow = 'Racing Control - lobby',
  scrShare = 'RACING ROOM', shareOn = 'GAME SCREEN SHARED', shareOff = 'GAME SCREEN NOT SHARED', shareHint = '< off   on >',
  ownOn = 'MY SCREENS SHOWN TO ME', ownOff = 'MY SCREENS HIDDEN FROM ME', ownHint = 'Hidden: less traffic and load; the others still see them',
  focusOn = 'FOCUS ON', focusOff = 'FOCUS OFF', focusWith = 'Talking to you: %s', focusNobody = 'Choose who talks to you', focusHint = 'Only one person talks to you',
  focusNoRoom = 'Focus: Racing Room in a private room',
  rrRoom = '%s - %s', rrNone = 'Not connected - no voice/video', rrOther = 'On another PC - no voice/video',
  rrOffline = 'Base of the event not answering', shareAsking = 'Asking the Racing Room...', shareSent = 'Asked - the Racing Room is opening the capture',
  shareNoRoom = 'Racing Room not in a room - open a room there', shareNoAnswer = 'The Racing Room did not share the game screen',
  shareFailed = 'Not shared: %s', rrNoRoom = 'Not in a room - no voice/video', rrWait = 'Checking...',
  rrAreas = { pitwall = 'Pitwall', anteroom = 'Anteroom', control = 'Control room', individual = 'Private room', workshop = 'Workshop' },
  lobbyRc = 'RACING CONTROL', lobbyAccount = 'Account', lobbyRegistration = 'Registration', lobbyBase = 'Base of the event',
  lobbyApp = 'Racing Control app', lobbyRoom = 'Racing Room', lobbyShare = 'Game screen', lobbyOk = 'ok', lobbyMissing = 'missing: %s',
  lobbyOnline = 'online', lobbyOffline = 'offline', lobbyRunning = 'running', lobbyNotRunning = 'not running', lobbyShared = 'shared',
  lobbyNotShared = 'not shared', lobbyOff = 'not used on this server',
  setShareSource = 'Source', setShareLayout = 'Screens', setShareVr = 'VR: Game window (the mirror of the headset on the PC)',
  setShareSources = { game = 'Game window', screen1 = 'Screen 1', screen2 = 'Screen 2', screen3 = 'Screen 3' },
  setShareLayouts = { single = 'Single', triple = 'Triple (all)', center = 'Triple (middle)' },
  setShareScope = 'Show in', setShareScopes = { all = 'Every room with Screens', room = 'Only your room' },
  setShareGo = 'SHARE GAME SCREEN', setShareStop = 'STOP SHARING',
  menuDesktops = 'Desktops', menuAudit = 'Audit', auditTitle = 'AUDIT', auditPoints = 'KMR points %d / %d',
  auditRating = 'KMR rating %s',
  auditCount = '%d messages', auditEmpty = 'No messages in this session',
  edStrip = 'CONTROLS - MESSAGES (on demand)', edFlagStrip = 'FLAGS (on demand)', edPin = 'Pin to all', edPinned = 'On all desktops', edMode = 'Mode: %s', edRemove = 'Remove',
  edChoose = 'Click a screen to choose it and drag it to its place',
  screenNames = { pitbox = 'Pit stop', setup = 'Setup status', status = 'Car status', race = 'Race status', laps = 'Laps',
    standings = 'Standings', relative = 'Relative', laptime = 'Lap time', delta = 'Delta', event = 'Event',
    weather = 'Weather', map = 'Track map', telemetry = 'Telemetry', share = 'Racing Room', cockpit = 'Cockpit', perf = 'Performance',
    calc = 'Strategy calculator' },
  scrTelemetry = 'TELEMETRY',
  teleChannels = { thr = 'THR', brk = 'BRK', clu = 'CLU', str = 'STR', spd = 'SPD', gear = 'GEAR', glat = 'G LAT', glon = 'G LON' },
  teleShort = { thr = 'T', brk = 'B', clu = 'C', str = 'S', spd = 'V', gear = 'G', glat = 'X', glon = 'Z' },
  scrClassSel = '< CLASS: %s >', scrLapsCar = 'LAPS - CAR #%s', scrLapsMore = 'MORE', scrLapsLess = 'LESS',
  scrCompare = 'COMPARE', scrDriverSel = '< DRIVER: %s >', scrStintShort = 'ST %d', scrMap = 'TRACK MAP', scrNoMap = 'No map of this track',
  scrMapLegend = { 'yellow you - blue lap ahead - beige lap down', 'grey pit - red stopped' },
  scrWeather = 'WEATHER', scrWeatherModes = { forecast = 'FORECAST', map = 'RADAR' }, scrRadarZoom = '%g KM',scrRadarBig = '+', scrRadarSmall = '-',
  scrRadarPrec = 'PRECIPITATION', scrRadarLight = 'light', scrRadarHeavy = 'heavy', scrRadarExtreme = 'extreme', scrRadarClouds = 'clouds: white = light, grey = thick',
  scrRadarLoop = '%s - 1 hour in 6 segments of 10 min, one a second', scrRadarNoTrack = 'No AI spline on this track',
  scrWeatherAnim = 'forecast in segments of 10 min', scrWeatherStatic = 'no forecast', scrWxPage = '< %d/%d >',
  scrWxTime = 'Local Time', scrWxSky = 'Sky', scrWxAir = 'Air / track', scrWxWind = 'Wind', scrWxRain = 'Rain', scrWxNext = 'Next',
  scrEvent = 'EVENT', scrEventInfo = 'event info', evStops = 'Pit stops required', evSwaps = 'Driver swaps required',
  evStint = 'Stint', evOrder = 'Pit stop order', evPitSpeed = 'Pit lane speed', evRating = 'KMR rating',
  flagRed = 'RED FLAG',
  flagRedLine = 'Slow down - no overtaking - complete the lap on track, then the pits',
  flagRedNeutral = 'Race neutralized by Racing Control',
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
  flagRaceControl = 'Racing Control',
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
  osTitle = 'RACE START', osLocked = 'Controls locked until %s', osLockedLight = 'light %d',
  gameDtTaken = 'Drive-through of the game taken out - the Racing Control decides the penalty',
  startPassedBy = ' - %s passed you', startGiveBack = 'GIVE THE PLACE BACK TO %s', startPassAllowed = 'P%d - %s can be passed (KMR)',
  flagRedLocked = 'Stay at your pit place - controls locked until the restart',
  ssTitle = 'STANDING START', dirStart = 'START', fmTitle = 'FORMATION LAP', fmEnd = 'Formation lap over - stop on your grid place',
  fmToGrid = 'Grid P%d - stop on your place', fmAligned = 'Grid P%d - on your place, controls locked',
  fmCountdown = 'Start in %s', fmCountdownLine = 'Formation lap opens at the release of the game',
  fmPitStart = 'Start from the pit lane, after the field', fmPlace = 'P%d - stay behind %s',
  fmGiveBack = 'Give the place back to %s - %d s', fmGivenBack = 'Place given back to %s',
  fmMissedStart = 'Not on the grid place when the start lights began',
  srTitle = 'STANDING RESTART', srGrid = 'Grid P%d - controls locked', srGridFree = 'Grid P%d', srGridSoon = 'Grid in %d s - stay at your pit place',
  srSwap = 'Driver swap: leave the pit lane at the green', srLightsIn = 'Lights in %d s', srLights = 'Lights %d / %d',
  srFree = 'Controls free - do not move before the lights go out', srGo = 'GREEN FLAG - GO GO',
  srGoLine = 'Standing restart', srCancelled = 'Standing restart cancelled - red flag',
  srGridLocked = 'Stay on the grid - controls locked', srNoNode = 'no grid place AC_START_%d on this track',
  dirStanding = 'STANDING RESTART', dirStandingOff = 'CANCEL RESTART',
  flagRestart = 'Restart P%d - behind %s', flagRestartFirst = 'Restart P%d - first car',
  flagRestartSwap = 'Restart P%d - driver swap: back of the field, behind %s',
  appMissing = 'Racing Control app not running - install it from the event page - the game closes in %d s',
  cspOld = 'CSP 4130 required - install it with the 12h app - the game closes in %d s',
  teamSetup = 'Setup from your team: %s - open the setup menu in the pits to apply or refuse it',
  remotePitStart = 'Your team started the pit stop from the Racing Room: stop at your pit place',
  realNameMissing = 'Registration incomplete - you cannot take part in this session - missing: %s - complete it in the 12h Curitiba app',
  realNameWhat = { cadastro = 'registration', steam = 'Steam account confirmed', nome = 'real name' },
  realNameOffline = 'Registration not confirmed - the base of the event does not answer - wait for it before the session starts',
  redTowDeferred = 'Tow under the red flag: the tow and repair time starts at the restart',
  redNoLineSG = 'Pit entry with the red flag not received at the line', redFuelUnlocked = 'Fuel unlocked by Racing Control',
  menuFree = 'Game menu free for %d min - adjust and get ready', menuFreeOff = 'Game menu closed again',
  redFlagNoPitDsq = 'Not in the pits at the restart after the red flag',
  flagChequered = 'CHEQUERED FLAG', flagChequeredMine = 'Session over for you', flagChequeredPos = 'P%d - %d laps',
  flagTimeOver = 'SESSION TIME OVER', flagRaceOver = 'RACE OVER', flagFinishLap = 'Finish your lap - the chequered flag is at the line',
  flagChequeredLine = 'Session finished',
  relPit = '  PIT',
  hdr = { pos = 'P', classPos = 'CL', driver = 'DRIVER', class = 'CLASS', laps = 'LAPS', gap = 'GAP', int = 'INT', best = 'BEST', pit = 'PIT',
    sr = 'SR', pts = 'PTS', time = 'TIME', sky = 'SKY', air = 'AIR', track = 'TRACK', avg = 'AVG', lap = 'LAP', delta = 'DELTA', precip = 'PRECIP.' },
  wxProb = '%d%%',
  lapsShort = '%d L', lapTag = { cut = 'cut', pit = 'pit', best = 'best' },
  wxSky = { clear = 'Clear', few = 'Few clouds', scattered = 'Scattered clouds', broken = 'Broken clouds', overcast = 'Overcast', thunder = 'Thunderstorm' },
  wxPrecip = { lightDrizzle = 'light drizzle', drizzle = 'drizzle', lightRain = 'light rain', rain = 'rain', heavyRain = 'heavy rain', violentRain = 'violent rain' },
  compass = { 'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW' },
  wxBulletin = { now = '%s now: %s, air %d°C, track %d°C, wind %s %s.', rain = 'Precipitation expected from %s (%s), %d%% chance, up to %.2f mm/h.',
    dry = 'No precipitation expected.', by = 'By %s: %s%s, air %d°C, track %d°C; wind %s %s.', falling = 'Track temperature falling %d°C: less grip expected.',
    rising = 'Track temperature rising %d°C.' },
  wxWindFmt = '%.0f km/h %03.0f deg', wxRainFmt = '%.0f%% - wet %.0f%%', wxGripFmt = 'grip %.0f%%',
  evStintFmt = 'min %d - max %d min', evRatingFmt = 'DSQ at %s', posClassFmt = ' - class P%d %s',
  tyreLapsFmt = '%d laps%s', trackGripFmt = '%s - grip %d%%', trackWet = 'WET', trackDry = 'DRY',
  edPitTag = 'PIT', edTrackTag = 'TRACK', edTrackDesk = 'Track desktop',
  ctlGroup = { elec = 'ELECTRONICS', engine = 'ENGINE - BRAKES', hybrid = 'HYBRID' },
  ctlBox = { aero = 'AERO', drs = 'DRS', open = 'OPEN', closed = 'CLOSED', pit = 'PIT', limiter = 'LIMITER', on = 'ON', off = 'OFF',
    recov = 'RECOV.', batt = 'BATT', motor = 'MOTOR' },
  dirNoData = 'no data', kmrEvNoAnswer = 'no answer',
  dirChip = { dt = 'DT', kick = 'KICK', ban60 = 'BAN 60', dsq = 'DSQ' },
  dirAct = { money = 'reset money', stats = 'reset stats', ban = 'ban', unban = 'unban', ballast = 'ballast kg', restrictor = 'restrictor',
    dt = 'DT %s', cancelDt = 'cancel DT %s', relaxSg = 'relax S&G %s', kick = 'kick %s', ban60 = 'ban 60 min %s', toPit = 'to the pits %s',
    dsq = 'DSQ %s', relaxDsq = 'relax DSQ %s', fuel = 'fuel unlocked %s', menu = 'menu free %s' },
  wheelCode = { FL = 'FL', FR = 'FR', RL = 'RL', RR = 'RR', F = 'F', R = 'R' },
  wheelNames = { [0] = 'front left', 'front right', 'rear left', 'rear right' }, bodySides = { [0] = 'front', 'rear', 'left', 'right' },
  side = { front = 'F', back = 'B', left = 'L', right = 'R' },
  dtLine = '%s - Drive-through - %s', holdTowRepair = 'Tow %s + Repair %s', holdRepair = 'Repair %s', dirDsqNotice = 'Disqualified - %s',
  dsqWhy = { repairNotDone = 'Mandatory repair not done', sgInterrupted = 'Stop & go interrupted', swapPending = 'Driver swap with pending penalties',
    pitClosed = 'Pit lane left with the pit closed', slowdown = '%s - slowdown not served' },
  cmdHelp = {
    rc = { title = 'RACING CONTROL', how = 'KMR chat: /kmr admin_say RC ... (the buttons of this window) - ACSM live timing: Chat to the driver or Broadcast Chat', rows = {
      'clears the list: drive-throughs, stop & go and slowdowns',
      'removes the first item of the list',
      'removes the stop & go (NO S&G button)',
      'cancels the slowdown in progress',
      'ends the hold (or tow / repair) and frees the controls',
      'removes the repair required (black flag with orange disc)',
      'cancels the disqualification and frees the controls (NO DSQ button)',
      'frees the controls and ends the hold (list and DSQ kept)',
      'drive-through within the laps (0 = this lap)',
      'hold: the car locked at its pit place',
      'the car to the pits, damage kept (TO PIT button)',
      'disqualification of the Racing Control (DSQ button)',
      'locks the controls (up to 86400 s)',
      'fuel unlocked under the red flag (FUEL button)',
      'the car asks its KMR numbers again',
      'the game menu back to that driver (5 min; up to 60; 0 ends it) (MENU 5 MIN button)',
      'red flag to every car (RED FLAG button)',
      'red flag off: rolling restart under the VSC',
      'standing restart, red flag up (STANDING RESTART button)',
      'cancels the standing restart before the green',
      'track green at once: red flag down, CODE-80 over (GREEN button)',
      'pit exit and start lights of the track held red (LIGHTS RED button)',
      'pit exit and start lights of the track held green (LIGHTS GREEN button)',
      'track lights back to the state of the track (LIGHTS AUTO button)' } },
    kmr = { title = 'KMR', how = 'KMR chat: /kmr login <password> once, then /kmr <command> - or the KMR console' },
    server = { title = 'AC SERVER (ACSM)', how = 'Chat: /admin <password> once, then the command - or /kmr admin_send_command /<command> - or ACSM Admin Command', rows = {
      'logs in as server admin (chat)',
      'list of the server commands',
      'goes to the next session',
      'restarts the current session',
      'car IDs with the drivers\' names',
      'kicks the driver by the name',
      'kicks the driver of the car ID',
      'bans the driver by the name',
      'bans the driver of the car ID',
      'ballast on the car (BALLAST button)',
      'restrictor on the car (RESTRICTOR button)' } },
    player = { title = 'KMR PLAYERS', how = 'Any driver in the chat, no slash: kmr <command>' },
  },
}
local Lang = { hooks = {} }
do
  local function fill(dst, src)
    for k, v in pairs(src) do
      if type(v) == 'table' then
        if type(dst[k]) ~= 'table' then dst[k] = {} end
        fill(dst[k], v)
      else
        dst[k] = v
      end
    end
  end
  local function unescape(v) return (v:gsub('\\(.)', function(c) return c == 'n' and '\n' or c == 't' and '\t' or c end)) end
  function Lang.apply(text)
    local tbl, n = {}, 0
    for line in tostring(text or ''):gmatch('[^\n]+') do
      local path, kind, value = line:match('^([^\t]+)\t([sn])(.*)$')
      if path then
        local keys = {}
        for name in path:gmatch('[^.]+') do
          keys[#keys + 1] = tonumber(name:match('^#(%-?%d+)$')) or (name:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end))
        end
        local node = tbl
        for i = 1, #keys - 1 do
          if type(node[keys[i]]) ~= 'table' then node[keys[i]] = {} end
          node = node[keys[i]]
        end
        value = unescape(value)
        node[keys[#keys]] = kind == 'n' and (tonumber(value) or 0) or value
        n = n + 1
      end
    end
    if n == 0 then return 0 end
    tbl.rc = nil
    fill(TEXTS, tbl)
    for cat, base in pairs(TEXTS.kmrReasons) do TEXTS.reason[cat] = base .. ' (KMR)' end
    for _, h in ipairs(Lang.hooks) do h() end
    return n
  end
end
for cat, base in pairs(TEXTS.kmrReasons) do TEXTS.reason[cat] = base .. ' (KMR)' end
local MANDATORY_PITS = ac.PenaltyType.MandatoryPits
local BLACK_FLAG = ac.PenaltyType.BlackFlag
local TELEPORT_TO_PITS = ac.PenaltyType.TeleportToPits
local NONE = ac.PenaltyType.None
local GAME_DT = 2
local config = (function()
  local OLD = {
    penaltyMode = { 'control', 'mode', nil, 'CSP' }, announce = { 'control', 'announce', nil, 0 },
    code80FreezeDeadlines = { 'control', 'code80Freeze', nil, 1 }, dataCheck = { 'control', 'dataCheck', nil, 1 },
    forceCockpit = { 'cockpit', 'force', nil, 0 }, cockpitCameraMode = { 'cockpit', 'camera', nil, 0 },
    cockpitCheckInterval = { 'cockpit', 'interval', nil, 0.05 }, cockpitExemptSteamIDs = { 'cockpit', 'exempt', nil, '' },
    eventName = { 'event', 'name', nil, '' }, gameHud = { 'event', 'gameHud', nil, 'hide' },
    raceControlSteamID = { 'roles', 'director', nil, '' }, staffSteamIDs = { 'roles', 'staff', nil, '' },
    broadcastSteamIDs = { 'roles', 'broadcast', nil, '' },
    kmrStatsUrl = { 'kmr', 'statsUrl', nil, '' },
    baseUrl = { 'base', 'url', nil, '' },
    practiceDriverSwap = { 'driverSwap', 'practice', nil, 0 }, qualifyDriverSwap = { 'driverSwap', 'qualify', nil, 0 },
    raceDriverSwap = { 'driverSwap', 'race', nil, 0 }, driverSwapMinSeconds = { 'driverSwap', 'minSeconds', nil, 120 },
    driverSwapRequired = { 'driverSwap', 'required', nil, '' },
    wrongDriverSeconds = { 'driverSwap', 'wrongDriverSeconds', nil, '120' },
    swapWindowStartMinutes = { 'driverSwap', 'windowStartMinutes', nil, 0 }, swapWindowEndMinutes = { 'driverSwap', 'windowEndMinutes', nil, 0 },
    pitStopsEnabled = { 'pitStops', 'enabled', nil, 0 }, pitStopsRequired = { 'pitStops', 'required', nil, 0 },
    pitStopOrder = { 'pitStops', 'order', nil, 'F<TR>' }, pitStopMode = { 'pitStops', 'mode', nil, 'AUTO' },
    pitWindowStartMinutes = { 'pitWindow', 'startMinutes', nil, 0 }, pitWindowEndMinutes = { 'pitWindow', 'endMinutes', nil, 0 },
    practiceClosedSeconds = { 'pitExit', 'practiceSeconds', nil, 60 }, qualifyClosedSeconds = { 'pitExit', 'qualifySeconds', nil, 120 },
    raceClosedSeconds = { 'pitExit', 'raceSeconds', nil, 60 },
    practicePenalty = { 'pitExit', 'practice', nil, 'REPRIMAND' }, qualifyPenalty = { 'pitExit', 'qualify', nil, 'DSQ' },
    racePenalty = { 'pitExit', 'race', nil, 'SG:10' },
    pitSpeedLimit = { 'pitSpeed', 'limit', nil, 60 }, pitSpeedTolerance = { 'pitSpeed', 'tolerance', nil, 2 },
    pitSpeedDeadlineLaps = { 'pitSpeed', 'deadlineLaps', nil, 1 },
    holdShortSeconds = { 'stopAndGo', 'holdShort', nil, 45 }, holdLongSeconds = { 'stopAndGo', 'holdLong', nil, 90 },
    dsqBlackFlagLaps = { 'dsq', 'blackFlagLaps', nil, 3 },
    cutZoneStart = { 'cutZone1', 'start', nil, 0.16 }, cutZoneEnd = { 'cutZone1', 'end', nil, 0.24 },
    cutMaxWheelsOut = { 'cutZone1', 'maxWheelsOut', nil, 3 }, cutSlowdownMaxGas = { 'cutZone1', 'maxGas', nil, 0.2 },
    cutGainTolerance = { 'cutZone1', 'gainTolerance', nil, 6 }, cutSlowdownDeadline = { 'cutZone1', 'deadline', nil, 10 },
    practiceCutPenalty = { 'cutZone1', 'practice', 1, 'SLOW DOWN' }, practiceCutPenaltyParam = { 'cutZone1', 'practice', 2, 0 },
    qualifyCutPenalty = { 'cutZone1', 'qualify', 1, 'SLOW DOWN' }, qualifyCutPenaltyParam = { 'cutZone1', 'qualify', 2, 0 },
    raceCutPenalty = { 'cutZone1', 'race', 1, 'SLOW DOWN' }, raceCutPenaltyParam = { 'cutZone1', 'race', 2, 0 },
    cutZone2Start = { 'cutZone2', 'start', nil, 0.81 }, cutZone2End = { 'cutZone2', 'end', nil, 0.91 },
    cutZone2MaxWheelsOut = { 'cutZone2', 'maxWheelsOut', nil, 3 }, cutZone2SlowdownMaxGas = { 'cutZone2', 'maxGas', nil, 0.1 },
    cutZone2GainTolerance = { 'cutZone2', 'gainTolerance', nil, 6 }, cutZone2SlowdownDeadline = { 'cutZone2', 'deadline', nil, 18 },
    practiceCutZone2Penalty = { 'cutZone2', 'practice', 1, 'SLOW DOWN' }, practiceCutZone2PenaltyParam = { 'cutZone2', 'practice', 2, 9 },
    qualifyCutZone2Penalty = { 'cutZone2', 'qualify', 1, 'SLOW DOWN' }, qualifyCutZone2PenaltyParam = { 'cutZone2', 'qualify', 2, 9 },
    raceCutZone2Penalty = { 'cutZone2', 'race', 1, 'SLOW DOWN' }, raceCutZone2PenaltyParam = { 'cutZone2', 'race', 2, 9 },
    practiceSlowdownUnpaidPenalty = { 'slowdown', 'practiceUnpaid', nil, 'DT' },
    qualifySlowdownUnpaidPenalty = { 'slowdown', 'qualifyUnpaid', nil, 'DT' },
    raceSlowdownUnpaidPenalty = { 'slowdown', 'raceUnpaid', nil, 'DT' },
    cutSpinAngle = { 'slowdown', 'spinAngle', nil, 90 },
  }
  local THEMES = { control = 1, cockpit = 1, event = 1, roles = 1, staffPits = 1, kmr = 1, base = 1, driverSwap = 1, pitStops = 1,
    pitWindow = 1, pitExit = 1, pitSpeed = 1, dsq = 1, cutZone1 = 1, cutZone2 = 1, slowdown = 1, stopAndGo = 1 }
  local FIELDS = { kmr = { points = 1, ratingDsq = 1 }, base = { realName = 1, offline = 1 }, roles = { watch = 1 }, staffPits = { org = 1, tv = 1 },
    stopAndGo = { mode = 1, secondsPerDT = 1, maxDT = 1, deadlineLaps = 1, returnSeconds = 1 } }
  for _, m in pairs(OLD) do
    if THEMES[m[1]] then FIELDS[m[1]] = FIELDS[m[1]] or {}; FIELDS[m[1]][m[2]] = 1 end
  end
  local raw = {}
  local function theme(key)
    if raw[key] == nil then
      local text = tostring(cfg[key] or '')
      if not text:match('%S') then
        raw[key] = false
      else
        local t = {}
        for item in text:gmatch('[^|]+') do
          local k, v = item:match('^%s*([%w_]+)%s*:%s*(.-)%s*$')
          if k and FIELDS[key] and FIELDS[key][k] then t[k] = v
          elseif key ~= 'stopAndGo' then ac.log('race-control: key ' .. key .. ': field not known: ' .. item:match('^%s*(.-)%s*$')) end
        end
        raw[key] = t
      end
    end
    return raw[key] or nil
  end
  local oldUsed = {}
  local function K(old)
    local m = OLD[old]
    local t = m and THEMES[m[1]] and theme(m[1])
    if t then
      local v = t[m[2]]
      if v == nil then return m[1] == 'stopAndGo' and cfg[old] or m[4] end
      if m[3] then v = (v .. '/'):match(string.rep('[^/]*/', m[3] - 1) .. '([^/]*)/') or '' end
      if v == '' and type(m[4]) == 'number' and m[3] then return m[4] end
      return v
    end
    if m and THEMES[m[1]] and tostring(cfg[old] or '') ~= tostring(m[4]) and not oldUsed[m[1]] then
      oldUsed[m[1]] = true
      ac.log('race-control: old keys of ' .. m[1] .. ' in use (theme key ' .. m[1] .. ' not on the server)')
    end
    return cfg[old]
  end
  local function rule(penalty, param)
    local p = string.upper(tostring(penalty))
    local n = tonumber(param)
    local base, arg = p:match('^(.-):(%d+)$')
    if base then
      p = base
      if not n or n < 0 then n = tonumber(arg) end
    end
    return {
      penalty = p,
      param = math.floor(n or -1),
    }
  end
  local function bySession(practice, qualify, race)
    return {
      [ac.SessionType.Practice] = practice,
      [ac.SessionType.Qualify] = qualify,
      [ac.SessionType.Race] = race,
    }
  end
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
  local STOP_AND_GO = structKey('stopAndGo', { mode = 'HOLD', secondsPerDT = 30, maxDT = 7, deadlineLaps = 1,
    returnSeconds = 0, holdShort = 45, holdLong = 90, unservedDT = 20 })
  local TOW_RULE = { mode = 'TOW', towSeconds = 120, repairFactor = 1.5 }
  local QUALIFY_RULE = { mode = 'END', towSeconds = 0, repairFactor = 0 }
  local REPAIR_FORMULA = structKey('repairFormula', { baseSeconds = 180, weightEngine = 1.0, weightSuspension = 0.5,
    weightBody = 0.25 })
  local DAMAGE = structKey('damage', { toeBent = 10, toeBroken = 20, camberBent = 10, camberBroken = 20, bodyRepair = 150,
    powertrainRepair = 45, maxPunctured = 2, repairLaps = 2, beyondTowSeconds = 180, dsqTowSeconds = 180, settleSeconds = 1 })
  local clean = function(v) return (tostring(v or ''):gsub('^%s+', ''):gsub('%s+$', ''):gsub('/+$', '')) end
  local kmrTheme = theme('kmr')
  local kmrPoints = kmrTheme and { limit = tonumber(kmrTheme.points) or 100 } or structKey('kmrPoints', { limit = 100 })
  local kmrRating
  if kmrTheme then
    kmrRating = { dsqAt = tonumber(kmrTheme.ratingDsq) or 0, on = tostring(kmrTheme.ratingDsq or ''):match('%S') ~= nil }
  else
    kmrRating = structKey('kmrRating', { dsqAt = 0 })
    kmrRating.on = tostring(cfg.kmrRating or ''):match('%S') ~= nil
  end
  local c = {
    mode = string.upper(tostring(K('penaltyMode'))),
    raceControlSteamID = tostring(K('raceControlSteamID') or ''),
    announce = tonumber(K('announce')) == 1,
    holdShort = tonumber(K('holdShortSeconds')) or 45,
    holdLong = tonumber(K('holdLongSeconds')) or 90,
    sg = STOP_AND_GO.mode == 'SG',
    sgSecondsPerDT = STOP_AND_GO.secondsPerDT,
    sgMaxDT = STOP_AND_GO.maxDT,
    sgDeadlineLaps = STOP_AND_GO.deadlineLaps,
    sgReturnSeconds = STOP_AND_GO.returnSeconds,
    sgUnservedDT = STOP_AND_GO.unservedDT,
    wrongDriver = tonumber(K('wrongDriverSeconds')),
    dsqBlackFlagLaps = math.max(math.floor(tonumber(K('dsqBlackFlagLaps')) or 3), 1),
    pitStopOrder = tostring(K('pitStopOrder') or 'F<TR>'),
    pitStopAuto = string.upper(tostring(K('pitStopMode') or 'AUTO')) ~= 'MANUAL',
    beyondTowSeconds = DAMAGE.beyondTowSeconds,
    dsqTowSeconds = DAMAGE.dsqTowSeconds,
    swap = bySession(tonumber(K('practiceDriverSwap')) == 1, tonumber(K('qualifyDriverSwap')) == 1,
      tonumber(K('raceDriverSwap')) == 1),
    swapMinSeconds = tonumber(K('driverSwapMinSeconds')) or 120,
    swapRequired = tonumber(K('driverSwapRequired')) and math.floor(tonumber(K('driverSwapRequired'))) or nil,
    cutSpinAngle = tonumber(K('cutSpinAngle')) or 90,
    pitSpeedLimit = tonumber(K('pitSpeedLimit')) or 60,
    pitSpeedTolerance = tonumber(K('pitSpeedTolerance')) or 2,
    swapWindowStart = tonumber(K('swapWindowStartMinutes')) or 0,
    swapWindowEnd = tonumber(K('swapWindowEndMinutes')) or 0,
    pitWindowStart = tonumber(K('pitWindowStartMinutes')) or 0,
    pitStopsEnabled = tonumber(K('pitStopsEnabled')) == 1,
    pitStopsRequired = math.floor(tonumber(K('pitStopsRequired')) or 0),
    pitWindowEnd = tonumber(K('pitWindowEndMinutes')) or 0,
    pitSpeedDeadlineLaps = math.floor(tonumber(K('pitSpeedDeadlineLaps')) or 1),
    code80Freeze = tonumber(K('code80FreezeDeadlines')) == 1,
    dataCheck = tonumber(K('dataCheck')) ~= 0,
    screenScale = structKey('screenScale', { exponent = 0.45, max = 1.5 }),
    tyreLife = structKey('tyreLife', { ok = 70, worn = 30 }),
    tyreTemp = structKey('tyreTemp', { edge = 98 }),
    wrongWay = structKey('wrongWay', { maxMeters = 60, penalty = 'DSQ', showMeters = 2, angle = 110 }),
    parkedCar = structKey('parkedCar', { seconds = 6, distance = 24, grace = 0, fuelRaceSeconds = 60, moveSeconds = 10 }),
    flags = structKey('flags', { slowMeters = 300, yellowMeters = 500, oilSeconds = 300, rainSlippery = 0.2,
      greenSeconds = 5, redSpeedKmh = 65, redGraceSeconds = 10, passSlowKmh = 40, passFarM = 75, redSpeedSG = 30,
      redOverSeconds = 10, redNoLineSG = 120, yellowPassSG = 10, yellowGiveBackSeconds = 10 }),
    restart = structKey('restart', { gridDelay = 5, gridSeconds = 30, lights = 5, stepSeconds = 1, releaseLight = 3,
      randomMin = 0.2, randomMax = 3, jumpMeters = 0.5, jumpLaps = 2, screenLightsFrom = 22, prestartSeconds = 5,
      abortSeconds = 8 }),
    formation = structKey('formation', { procedure = 'KMR', maxKmh = 150, overSeconds = 10, speedLaps = 1, minKmh = 30,
      slowSeconds = 15, slowLaps = 3, giveBackSeconds = 20, passLaps = 3, passFarM = 100, leaderSlowKmh = 30, slowFarKmh = 40,
      slowFarM = 75, alignMeters = 5, alignKmh = 20, alignSeconds = 60, approachM = 400 }),
    driverStint = structKey('driverStint', { minMinutes = 0, maxMinutes = 0 }),
    kmrPoints = kmrPoints,
    kmrRating = kmrRating,
    lobbyPos = structKey('lobbyPos', { x = -1, y = -1 }),
    eventName = tostring(K('eventName') or ''),
    kmrStatsUrl = clean(K('kmrStatsUrl')),
    baseUrl = clean(K('baseUrl')),
    realName = tostring((theme('base') or {}).realName or ''):match('^%s*1%s*$') ~= nil,
    watch = tostring((theme('roles') or {}).watch or ''):match('^%s*1%s*$') ~= nil,
    realNameOffline = tostring((theme('base') or {}).offline or ''):lower():match('lock') and 'lock' or 'free',
    gameHud = (function()
      local v = tostring(K('gameHud') or ''):lower():gsub('%s', '')
      return (v == 'show' or v == 'hideall') and v or 'hide'
    end)(),
    screens = structKey('screens', { autoSeconds = 5, closeGap = 2.5, noticeSeconds = 3, serverNoticeSeconds = 5,
      messageSeconds = 5, pitBoxSeconds = 5, indicatorSeconds = 2, buttonSeconds = 10, controlSeconds = 3 }),
    cockpit = { force = tonumber(K('forceCockpit')) == 1, camera = tonumber(K('cockpitCameraMode')) or 0,
      interval = tonumber(K('cockpitCheckInterval')) or 0.05, exempt = tostring(K('cockpitExemptSteamIDs') or '') },
    tow = bySession(
      structKey('practiceTow', { mode = 'RESET', towSeconds = 0, repairFactor = 0, clearDsq = 1 }),
      structKey('qualifyTow', QUALIFY_RULE),
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
        tonumber(K('practiceClosedSeconds')) or 0,
        tonumber(K('qualifyClosedSeconds')) or 0,
        tonumber(K('raceClosedSeconds')) or 0),
      rules = bySession(rule(K('practicePenalty'), -1), rule(K('qualifyPenalty'), -1), rule(K('racePenalty'), -1)),
    },
    cutZones = {
      makeZone('SD1', K('cutZoneStart'), K('cutZoneEnd'), K('cutMaxWheelsOut'),
        bySession(
          rule(K('practiceCutPenalty'), K('practiceCutPenaltyParam')),
          rule(K('qualifyCutPenalty'), K('qualifyCutPenaltyParam')),
          rule(K('raceCutPenalty'), K('raceCutPenaltyParam'))),
        K('cutSlowdownDeadline'), K('cutSlowdownMaxGas'), K('cutGainTolerance')),
      makeZone('SD2', K('cutZone2Start'), K('cutZone2End'), K('cutZone2MaxWheelsOut'),
        bySession(
          rule(K('practiceCutZone2Penalty'), K('practiceCutZone2PenaltyParam')),
          rule(K('qualifyCutZone2Penalty'), K('qualifyCutZone2PenaltyParam')),
          rule(K('raceCutZone2Penalty'), K('raceCutZone2PenaltyParam'))),
        K('cutZone2SlowdownDeadline'), K('cutZone2SlowdownMaxGas'), K('cutZone2GainTolerance')),
    },
    unpaid = bySession(rule(K('practiceSlowdownUnpaidPenalty'), 0), rule(K('qualifySlowdownUnpaidPenalty'), 0),
      rule(K('raceSlowdownUnpaidPenalty'), 0)),
  }
  c.staffSteamIDs = tostring(K('staffSteamIDs') or '')
  local staffPits = theme('staffPits') or {}
  c.staffPits = { org = math.max(math.floor(tonumber(staffPits.org) or 0), 0), tv = math.max(math.floor(tonumber(staffPits.tv) or 0), 0) }
  c.broadcastSteamIDs = tostring(K('broadcastSteamIDs') or '')
  c.themesOnServer = {}
  for k in pairs(THEMES) do if theme(k) then c.themesOnServer[#c.themesOnServer + 1] = k end end
  table.sort(c.themesOnServer)
  function c.inForce()
    local byTheme = {}
    for old, m in pairs(OLD) do
      byTheme[m[1]] = byTheme[m[1]] or {}
      local v = K(old)
      if old:match('Penalty$') or old:match('Unpaid') or old == 'pitStopMode' or old == 'penaltyMode' then v = tostring(v):upper() end
      if type(m[4]) == 'number' and tonumber(v) then v = tonumber(v) end
      byTheme[m[1]][#byTheme[m[1]] + 1] = old .. '=' .. tostring(v)
    end
    local lines = {}
    for name, list in pairs(byTheme) do
      table.sort(list)
      lines[#lines + 1] = name .. ': ' .. table.concat(list, ' ')
    end
    table.sort(lines)
    lines[#lines + 1] = string.format('kmr: points=%s ratingDsq=%s', tostring(kmrPoints.limit), kmrRating.on and tostring(kmrRating.dsqAt) or '-')
    lines[#lines + 1] = 'base: realName=' .. (c.realName and 1 or 0) .. ' offline=' .. c.realNameOffline
    lines[#lines + 1] = string.format('staffPits: org=%d tv=%d', c.staffPits.org, c.staffPits.tv)
    return lines
  end
  return c
end)()
function config.swapOn() return config.swap[ac.getSim().raceSessionType] == true end
config.isDirector = config.raceControlSteamID ~= '' and ac.getUserSteamID() == config.raceControlSteamID
do
  local me = tostring(ac.getUserSteamID() or '')
  local function listed(keyText)
    for id in tostring(keyText or ''):gmatch('[^|/]+') do
      if me ~= '' and id:match('^%s*(.-)%s*$') == me then return true end
    end
    return false
  end
  config.role = config.isDirector and 'director' or (listed(config.staffSteamIDs) and 'staff')
    or (listed(config.broadcastSteamIDs) and 'broadcast') or nil
  config.canCommand = config.role == 'director' or config.role == 'staff'
  config.watchCars = config.role ~= nil and config.watch
end
config.isRaceControl = config.mode == 'KMR' and config.isDirector
local sim = ac.getSim()
local state = {
  lastSessionIndex = -1,
  prevInPitlane = {},
  cutPassPenalized = {},
  zonePass = {},
  zoneRef = {},
  cutChecks = {},
  lapCut = false,
  pitDsqActive = false,
  dtDsqActive = false,
  onJumped = {},
  sessionStartPending = false,
  jumpSinceUpdate = false,
  kmrMessages = {},
  tyreLaps = { [0] = 0, 0, 0, 0 },
  tyreKm = { [0] = 0, 0, 0, 0 },
  tyreLineKm = { [0] = 0, 0, 0, 0 },
  pitPassServiced = false,
  pitPassSgPaid = nil,
  swapInvalid = nil,
  postRed = nil,
  rcCommands = {},
  pitService = nil,
  repair = { class = 'normal', lapsLeft = nil, text = nil, detail = nil, beyondSince = nil },
  slowdowns = {},
  list = {
    items = {},
    curLap = 0,
    seq = 0,
    inPitNow = false,
    jumped = false,
    endOfLap = {},
    lastLap = 0,
    prevGame = { t = 0, p = 0 },
    prevInPit = false,
    owner = nil,
    dsq = 0,
    dsqStage = 0,
    dsqUntil = 0,
    dsqLap = 0,
    dsqReason = nil,
    wrong = nil,
    invalidLap = nil,
  },
  chat = {
    queue = {},
    seq = 0,
  },
  rcOut = {},
  lapOut = {},
  swap = {
    prevInPit = nil,
    stopT = nil,
    remaining = nil,
    remainingT = 0,
    fromPeers = false,
    entered = false,
    clearUntil = nil,
    lastNames = {},
    left = {},
    relay = {},
    count = 0,
    valid = 0,
    voids = 0,
    passSwap = false,
    passSwapValid = false,
    passVoided = false,
    swapNo = 0,
    driver = 0,
    swapInfo = nil,
    carSwaps = {},
    carValid = {},
    pitEntryValid = {},
    carLists = {},
    listSent = nil,
    listApplied = false,
    pendingList = nil,
  },
  dsqFlagPutBack = nil,
  code80 = nil,
  code80Ended = false,
  hold = nil,
  pit = { done = false, missed = false },
  tow = {
    damage = nil,
    lastRead = nil,
    collisionUntil = -1,
    jumpPending = false,
    ownJumpUntil = -1,
    repairDone = false,
    prevRepairing = false,
  },
  ui = {
    clock = 0,
    notice = nil,
    lastSeq = 0,
  },
}
local zoneLog = {}
for _, zone in ipairs(config.cutZones) do
  zoneLog[#zoneLog + 1] = zone.category .. '=' .. tostring(zone.enabled) .. ' ' .. zone.startPos .. '-' .. zone.endPos
end
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
  state.lapCut = false
  if not state.list.prevInPit then state.tow.jumpPending = true end
  ac.log('race-control: car jumped')
end)
ac.log('race-control: section=' .. tostring(__cfgSection__)
  .. ' mode=' .. config.mode
  .. ' physics.allowed=' .. tostring(physics.allowed())
  .. ' ' .. table.concat(zoneLog, ' '))
for _, key in ipairs({ 'screenScale', 'tyreLife', 'tyreTemp', 'wrongWay', 'stopAndGo', 'practiceTow', 'qualifyTow', 'raceTow', 'repairFormula', 'damage' }) do
  ac.log('race-control: key ' .. key .. ' = ' .. tostring(cfg[key]))
end
ac.log('race-control: theme keys on the server: ' .. (#config.themesOnServer > 0 and table.concat(config.themesOnServer, ' ') or 'none (old keys)'))
for _, line in ipairs(config.inForce()) do ac.log('race-control: in force ' .. line) end
ac.log('race-control: stopAndGo mode in force: ' .. (config.sg and 'SG' or 'HOLD'))
if math.abs((tonumber(sim.pitsSpeedLimit) or 0) - config.pitSpeedLimit) > 0.5 then
  ac.log(string.format('race-control: WARNING pitSpeedLimit %d differs from the server pit limiter (SPEED_KMH) %d',
    config.pitSpeedLimit, (tonumber(sim.pitsSpeedLimit) or 0)))
end
function state.chat.stamp()
  state.chat.seq = state.chat.seq + 1
  return os.preciseClock(), state.chat.seq
end
local function queueCommand(msg)
  local t, n = state.chat.stamp()
  state.chat.queue[#state.chat.queue + 1] = { text = msg, t = t, n = n }
end
local function queueChat(msg)
  if config.announce then queueCommand(msg) end
end
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
local function serverTimeMs() return sim.currentSessionTime or 0 end
local CarRead = {}
CarRead.staffLogged = {}
CarRead.staffIndex = nil
function CarRead.isStaff(i)
  local idx = CarRead.staffIndex
  if not idx then
    idx = {}
    local slotOf = ac.getCar.serverSlot
    if slotOf then
      for what, n in pairs(config.staffPits) do
        local c = n > 0 and slotOf(n - 1) or nil
        if c then idx[c.index] = { what = what, n = n } end
      end
    end
    CarRead.staffIndex = idx
  end
  local s = idx[i]
  if not s then return false end
  if not CarRead.staffLogged[i] then
    CarRead.staffLogged[i] = true
    ac.log(string.format('race-control: car %d (position %d of the entry list, %s): out of the race', i, s.n, s.what))
  end
  return true
end
function CarRead.num(v) return tonumber(v) or 0 end
function CarRead.flagOn(v)
  return v == true or (type(v) == 'number' and v ~= 0)
    or (type(v) == 'string' and v ~= '' and v ~= '0' and v:lower() ~= 'false')
end
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
  for i = 0, 3 do
    if num(car.damage[i]) < s.body[i] then
      return true, string.format('body %d %.1f -> %.1f', i, s.body[i], num(car.damage[i]))
    end
  end
  return false
end
CarRead.PARKED_KMH = 1
function CarRead.parked(car) return car.isInPit and CarRead.num(car.speedKmh) < CarRead.PARKED_KMH end
function CarRead.moving(car) return car.speedKmh > 0 end
function CarRead.setupValues()
  local out = setmetatable({}, { __index = function() return '-' end })
  for _, sp in ipairs(ac.getSetupSpinners() or {}) do
    local v = CarRead.num(sp.value) * (tonumber(sp.displayMultiplier) or 1)
    out[tostring(sp.name):upper()] = (math.floor(v) == v) and tostring(v) or string.format('%.1f', v)
  end
  return out
end
do
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
function CarRead.tyreLife(car, i, km)
  return (tyreWearState(car, i, km))
end
function CarRead.tyreLapLimit(car, i, laps, km)
  local life, endKm = tyreWearState(car, i, km)
  if not life then return nil end
  local limit = endKm and laps > 0 and km > 0 and math.floor(endKm * laps / km) or nil
  return life, limit
end
function CarRead.tyreThermal(car, i)
  local lut = tyreCurve(car, i, 'THERMAL_', 'PERFORMANCE_CURVE')
  local w = car.wheels and car.wheels[i]
  if not lut or not w then return nil end
  local n = CarRead.num
  local t = 0.75 * n(w.tyreCoreTemperature) + 0.25 * (n(w.tyreInsideTemperature) + n(w.tyreMiddleTemperature)
    + n(w.tyreOutsideTemperature)) / 3
  local _, hi = lut:bounds()
  if not hi or hi.y <= 0 then return nil end
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
CarRead.motion = { x = nil, z = nil, dx = 0, dz = 0, dist = 0 }
do
local MOTION_JUMP_M = 50
local TRACK_PROBE_M = 10
function CarRead.updateMotion(car)
  local m, p = CarRead.motion, car.position
  if m.x then
    m.dx, m.dz = p.x - m.x, p.z - m.z
    m.dist = math.sqrt(m.dx * m.dx + m.dz * m.dz)
    if m.dist > MOTION_JUMP_M then m.dx, m.dz, m.dist = 0, 0, 0 end
  end
  m.x, m.z = p.x, p.z
end
function CarRead.trackAngle(car, x, z)
  local len = tonumber(sim.trackLengthM) or 0
  local n = math.sqrt(x * x + z * z)
  if len <= 0 or n <= 0 or not car.position then return nil end
  local a = ac.worldCoordinateToTrackProgress(car.position)
  if not a or a < 0 then return nil end
  local p1 = ac.trackProgressToWorldCoordinate(a, true)
  local p2 = ac.trackProgressToWorldCoordinate((a + TRACK_PROBE_M / len) % 1, true)
  if not p1 or not p2 then return nil end
  local tx, tz = p2.x - p1.x, p2.z - p1.z
  local tn = math.sqrt(tx * tx + tz * tz)
  if tn <= 0 then return nil end
  return math.deg(math.acos(math.min(math.max((tx * x + tz * z) / (tn * n), -1), 1)))
end
end
function CarRead.slipAngle(car)
  local v, l = car.velocity, car.look
  if not v or not l then return nil end
  local vn, ln = math.sqrt(v.x * v.x + v.z * v.z), math.sqrt(l.x * l.x + l.z * l.z)
  if vn <= 0 or ln <= 0 then return nil end
  return math.deg(math.acos(math.min(math.max((v.x * l.x + v.z * l.z) / (vn * ln), -1), 1)))
end
Lang.letters = {}
function Lang.letters.count(text) return select(2, tostring(text or ''):gsub('[^\128-\191]', '')) end
function Lang.letters.head(text, n)
  text = tostring(text or '')
  local k = 0
  for e in text:gmatch('[^\128-\191][\128-\191]*()') do
    k = k + 1
    if k == n then return text:sub(1, e - 1) end
  end
  return text
end
function Lang.letters.upper(text)
  return (tostring(text or ''):upper():gsub('\195([\160-\190])', function(b)
    if b ~= '\183' then return '\195' .. string.char(b:byte() - 32) end
  end))
end
local function mmss(seconds, fixed)
  local s = math.max(math.floor(seconds + 0.5), 0)
  if fixed then return string.format('%02d:%02d', math.min(math.floor(s / 60), 99), s % 60) end
  return string.format('%d:%02d', math.floor(s / 60), s % 60)
end
local function driverTag()
  return string.format('#%d %s', ac.getDriverNumber(0) or 0, tostring(ac.getDriverName(0) or ''))
end
local function rcLog(what, reason)
  local msg = string.format('%s%s - %s - %s', TEXTS.rcPrefix, what, driverTag(), reason)
  queueCommand(msg)
  if config.baseUrl ~= '' then
    state.rcOut[#state.rcOut + 1] = string.format('%d|%s', math.floor(serverTimeMs()), msg)
    if #state.rcOut > 400 then table.remove(state.rcOut, 1) end
  end
  ac.log('race-control: ' .. msg)
end
local NOTICE_SECONDS = config.screens.noticeSeconds
local SERVER_NOTICE_SECONDS = config.screens.serverNoticeSeconds
local function showNotice(title, text, item, seconds, flag)
  state.ui.notice = { title = title, text = text, item = item, flag = flag,
    untilT = state.ui.clock + (seconds or NOTICE_SECONDS) }
end
local Record = {}
local RECORD_VERSION = 'RC1'
local RECORD_PREFIX = 'race-control.rec.'
local STORAGE_PREFIX = 'rc.'
local SESSION_START_TOLERANCE_MIN = 2
local function sessionStartMinutes()
  return math.floor(((sim.systemTime or 0) - (sim.currentSessionTime or 0) / 1000) / 60 + 0.5)
end
function Record.key()
  return string.format('%s:%s/%d/%d/%d', tostring(ac.getServerIP() or ''), tostring(ac.getServerPortTCP() or ''),
    sim.currentSessionIndex, sessionStartMinutes(), ac.getCar(0).sessionID)
end
local function parseKey(key)
  local server, session, start, slot = tostring(key):match('^(.-)/(%-?%d+)/(%-?%d+)/(%-?%d+)$')
  if not server then return nil end
  return { server = server, session = tonumber(session), start = tonumber(start), slot = tonumber(slot) }
end
function Record.sameSession(keyA, keyB)
  local a, b = parseKey(keyA), parseKey(keyB)
  if not a or not b then return false end
  return a.server == b.server and a.session == b.session and math.abs(a.start - b.start) <= SESSION_START_TOLERANCE_MIN
end
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
Record.onSave = nil
Record.onTampered = nil
Record.floor = 0
function Record.fresh() Record.floor = math.floor(serverTimeMs() / 1000) end
function Record.save(list, seq, body)
  if seq < Record.floor then seq = Record.floor + seq end
  local text = Record.encode(list, seq, body)
  ac.store(RECORD_PREFIX .. list, text)
  ac.storage[STORAGE_PREFIX .. list] = text
  if Record.onSave then Record.onSave(list, seq, text) end
  return seq
end
local function valid(rec, list)
  if not rec or rec.list ~= list or not Record.sameRace(rec.key, Record.key()) or rec.seq < Record.floor then return nil end
  return rec
end
function Record.load(list)
  local rec = valid(Record.decode(ac.load(RECORD_PREFIX .. list)), list)
  if rec then return rec.body, rec.seq, 'store' end
  local fileRec, err = Record.decode(ac.storage[STORAGE_PREFIX .. list])
  if err == 'checksum' and Record.onTampered then Record.onTampered(list) end
  rec = valid(fileRec, list)
  if rec then return rec.body, rec.seq, 'storage' end
  return nil
end
local OnlineQueue = { items = {}, lastT = -1e9, chatT = -1e9 }
do
  local GAP_ONLINE = 0.25
  local GAP_CHAT = 1
  function OnlineQueue.push(send, msg, target)
    local t, n = state.chat.stamp()
    OnlineQueue.items[#OnlineQueue.items + 1] = { send = send, msg = msg, target = target, t = t, n = n }
  end
  local function oldest(list)
    local best, at = nil, nil
    for i, x in ipairs(list) do
      if not best or x.t < best.t or (x.t == best.t and x.n < best.n) then best, at = x, i end
    end
    return best, at
  end
  function OnlineQueue.update()
    local now = os.preciseClock()
    if now - OnlineQueue.lastT >= GAP_ONLINE then
      local e, i = oldest(OnlineQueue.items)
      if e then
        OnlineQueue.lastT = now
        table.remove(OnlineQueue.items, i)
        if not e.send(e.msg, false, e.target) then
          ac.log(string.format('race-control: online message refused by the game, left out (stamp %.3f #%d)', e.t, e.n))
        end
      end
    end
    if now - OnlineQueue.chatT >= GAP_CHAT then
      local c, j = oldest(state.chat.queue)
      if c then
        OnlineQueue.chatT = now
        table.remove(state.chat.queue, j)
        if not ac.sendChatMessage(c.text) then
          ac.log('race-control: chat line refused by the game, left out: ' .. Lang.letters.head(c.text, 90))
        end
      end
    end
  end
end
local WebQueue = { items = {}, running = {} }
do
  local MAX = 2
  local STALL = 45
  local function count()
    local n = 0
    for _ in pairs(WebQueue.running) do n = n + 1 end
    return n
  end
  local function pump()
    local now = state.ui.clock
    for item, t in pairs(WebQueue.running) do
      if now - t > STALL then
        WebQueue.running[item] = nil
        ac.log('race-control: web request without answer for ' .. STALL .. ' s, place freed: ' .. tostring(item.url))
      end
    end
    while count() < MAX and #WebQueue.items > 0 do
      local q = table.remove(WebQueue.items, 1)
      WebQueue.running[q] = now
      local done = false
      local function finish(err, res)
        if done then return end
        done = true
        WebQueue.running[q] = nil
        if q.cb then q.cb(err, res) end
      end
      local ok, err = pcall(web.request, q.method, q.url, q.headers, q.body, finish)
      if not ok then finish(tostring(err), nil) end
    end
  end
  function WebQueue.request(method, url, headers, body, cb, first)
    if not web or not web.request then
      if cb then cb('web not available', nil) end
      return
    end
    local item = { method = method, url = url, headers = headers, body = body, cb = cb }
    if first then table.insert(WebQueue.items, 1, item) else WebQueue.items[#WebQueue.items + 1] = item end
    pump()
  end
  WebQueue.update = pump
  OnlineQueue.web = WebQueue
end
ServerGuard = { state = 'wait', waited = 0, asked = false }
do
  local MANIFEST_URL = 'https://api.12hcuritiba.com/manifest'
  local WAIT_SECONDS = 10
  local G = ServerGuard
  local function decide(st, why)
    G.state = st
    ac.log('race-control: server of the session ' .. tostring(ac.getServerIP() or '') .. ':' .. tostring(ac.getServerPortTCP() or '') .. ' - ' .. why)
  end
  local function onAnswer(err, res)
    if G.state ~= 'wait' then return end
    local body = not err and res and tonumber(res.status) == 200 and tostring(res.body or '') or nil
    if not body then decide('unknown', 'manifest of the base not read (' .. tostring(err or (res and res.status)) .. '): the script acts') return end
    local ip = body:match('"server"%s*:%s*{.-"ip"%s*:%s*"([^"]+)"')
    local port = body:match('"server"%s*:%s*{.-"tcpPort"%s*:%s*"?(%d+)"?')
    if not ip then decide('unknown', 'manifest without the server: the script acts') return end
    local hereIp, herePort = tostring(ac.getServerIP() or ''), tostring(ac.getServerPortTCP() or '')
    if hereIp == ip and (not port or herePort == port) then decide('ours', 'the server of the event: the script acts')
    else decide('other', 'not the server of the event (' .. ip .. (port and (':' .. port) or '') .. '): the script stays still') end
  end
  function ServerGuard.check(dt)
    if G.state == 'ours' or G.state == 'unknown' then return true end
    if G.state == 'other' then return false end
    if not G.asked then
      G.asked = true
      if not (web and web.request) then decide('unknown', 'no web: the script acts') return true end
      web.request('GET', MANIFEST_URL, nil, nil, onAnswer)
      if G.state ~= 'wait' then return G.state ~= 'other' end
    end
    G.waited = G.waited + (dt or 0)
    if G.waited >= WAIT_SECONDS then decide('unknown', 'no answer of the manifest in ' .. WAIT_SECONDS .. ' s: the script acts') return true end
    return false
  end
  function ServerGuard.ok() return G.state == 'ours' or G.state == 'unknown' end
end
local Connection = { cars = {}, menu = {}, kicks = {}, hudMode = nil }
do
  local PING_WARN = 250
  local PING_KICK = 270
  local DEV_KICK = 100
  local CHECK_SECONDS = 18
  local STALL_SECONDS = 2
  local MENU_SECONDS = 30
  local KICK_SECONDS = 10
  local KEEP_SECONDS = 900
  local sendMenu = ac.OnlineEvent({
    ac.StructItem.key('amxracing.race-control.menu'),
    mnOpen = ac.StructItem.uint8(),
  }, function(sender, msg)
    if not sender or sender.index == 0 then return end
    Connection.menu[sender.index] = { open = msg.mnOpen > 0, box = msg.mnOpen == 2, t = state.ui.clock }
  end, nil, nil, { processPostponed = true })
  local ownOpen = 0
  local function ownMenu(code)
    if code == ownOpen then return end
    ownOpen = code
    local open = code > 0
    local msg = { mnOpen = code }
    if not sendMenu(msg) then OnlineQueue.push(sendMenu, msg, nil) end
    ac.log('race-control: menu of the game ' .. (open and 'opened' or 'closed') .. ' (told to the other clients)')
  end
  local function car(i)
    local e = Connection.cars[i]
    if not e then
      e = { pings = {}, pingT = -1e9, last = nil, stillT = nil, moving = false, parkedT = nil, name = '' }
      Connection.cars[i] = e
    end
    return e
  end
  local function stats(list)
    local n = #list
    if n == 0 then return nil, nil end
    local sum = 0
    for _, v in ipairs(list) do sum = sum + v end
    local avg = sum / n
    local sq = 0
    for _, v in ipairs(list) do sq = sq + (v - avg) ^ 2 end
    return avg, math.sqrt(sq / n)
  end
  function Connection.chat(message)
    local low = message:lower()
    if not (low:find('kicked ', 1, true) or low:find('removido ', 1, true)) then return end
    local why = (low:find('high ping', 1, true) or low:find('ping elevado', 1, true)) and 'pingHigh'
      or (low:find('unstable ping', 1, true) or low:find('ping instavel', 1, true)) and 'pingUnstable' or 'kick'
    for i = 1, (sim.carsCount or 1) - 1 do
      local name = tostring(ac.getDriverName(i) or '')
      if name ~= '' and message:find(name, 1, true) then
        Connection.kicks[name] = { why = why, t = state.ui.clock, text = message }
      end
    end
  end
  function Connection.level(i)
    local e = Connection.cars[i]
    if not e then return 'ok' end
    local avg, dev = stats(e.pings)
    local stalled = e.stillT and e.moving and state.ui.clock - e.stillT >= STALL_SECONDS
    local full = #e.pings >= 4
    if stalled or (full and avg > PING_KICK) or (full and dev > DEV_KICK) then return 'bad', avg, dev, stalled end
    if (e.ping or 0) > PING_WARN then return 'warn', avg, dev, false end
    return 'ok', avg, dev, false
  end
  local HEAT_FROM = 80
  function Connection.heat(i)
    local lvl, avg, dev = Connection.level(i)
    if lvl == 'bad' then return 1 end
    local e = Connection.cars[i]
    local p = math.max(e and e.ping or 0, avg or 0)
    local h = math.max((p - HEAT_FROM) / (PING_KICK - HEAT_FROM), (dev or 0) / DEV_KICK)
    return math.min(math.max(h, 0), 1)
  end
  local function causeOf(i, e)
    local k = Connection.kicks[e.name]
    if k and math.abs(state.ui.clock - k.t) <= KICK_SECONDS then return k.why end
    if e.parked then return 'pitPlace' end
    local m = Connection.menu[i]
    if m and m.open and state.ui.clock - m.t <= MENU_SECONDS then return 'menu' end
    local lvl = Connection.level(i)
    if lvl == 'bad' or lvl == 'warn' then return 'lost' end
    return 'unknown'
  end
  ac.onClientDisconnected(function(i)
    if i == 0 then return end
    local e = car(i)
    e.leftT, e.leftCause, e.inT, e.sameDriver = state.ui.clock, causeOf(i, e), nil, nil
    e.leftAfterStop = e.parkedT and (state.ui.clock - e.parkedT) or nil
    ac.log(string.format('race-control: connection: car %d (%s) left - %s', i, e.name, e.leftCause))
    if config.isDirector then rcLog(TEXTS.rc.conn, string.format(TEXTS.connLog, e.name, TEXTS.connCause[e.leftCause] or e.leftCause)) end
  end)
  ac.onClientConnected(function(i)
    if i == 0 then return end
    local e = car(i)
    local name = tostring(ac.getDriverName(i) or '')
    if e.leftT then
      e.inT = state.ui.clock
      e.sameDriver = name == e.name
    end
    e.name, e.pings, e.ping, e.stillT, e.moving, e.last = name, {}, nil, nil, false, nil
    Connection.menu[i] = nil
    ac.log(string.format('race-control: connection: car %d (%s) connected%s', i, name,
      e.leftT and (e.sameDriver and ' - same driver back' or ' - another driver (driver swap)') or ''))
  end)
  function Connection.update()
    local mode = Connection.hudMode
    ownMenu((sim.isInMainMenu == true or mode == 'menu') and 2 or (mode == 'pause' or ac.isKeyDown(27) == true) and 1 or 0)
    local now = state.ui.clock
    for i = 1, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and c.isConnected then
        local e = car(i)
        e.name = tostring(ac.getDriverName(i) or e.name)
        e.ping = CarRead.num(c.ping)
        if now - e.pingT >= CHECK_SECONDS and e.ping > 0 then
          e.pingT = now
          table.insert(e.pings, e.ping)
          while #e.pings > 4 do table.remove(e.pings, 1) end
        end
        local p = c.position
        if p and e.last and (p.x ~= e.last.x or p.z ~= e.last.z) then
          e.stillT = nil
          e.moving = CarRead.num(c.speedKmh) > 5
        elseif p and not e.stillT then
          e.stillT = now
        end
        if p then e.last = vec2(p.x, p.z) end
        local parked = CarRead.parked(c)
        if parked and not e.parked then e.parkedT = now end
        if not c.isInPitlane then e.parkedT = nil end
        if e.inT and not c.isInPitlane and now - e.inT > 5 then
          e.leftT, e.inT, e.leftCause, e.sameDriver, e.leftAfterStop = nil, nil, nil, nil, nil
        end
        e.parked = parked
        e.seenT = now
      end
    end
  end
  function Connection.where(i, c)
    local m = Connection.menu[i]
    if m and m.open then return m.box and 'box' or 'menu' end
    if c.isInPit then return 'pit' end
    if c.isInPitlane then return 'pitlane' end
    if sim.raceSessionType == ac.SessionType.Race and not sim.isSessionStarted then return 'grid' end
    if CarRead.num(c.speedKmh) < 5 then return 'stopped' end
    return 'track'
  end
  function Connection.gone()
    local out = {}
    for i, e in pairs(Connection.cars) do
      local c = ac.getCar(i)
      if e.leftT and not e.inT and not (c and c.isConnected) and state.ui.clock - e.leftT <= KEEP_SECONDS then
        out[#out + 1] = { i = i, e = e }
      end
    end
    table.sort(out, function(a, b) return a.e.leftT > b.e.leftT end)
    return out
  end
  Connection.PING_WARN, Connection.PING_KICK, Connection.DEV_KICK = PING_WARN, PING_KICK, DEV_KICK
end
local Trust = { refused = {} }
do
  local TRUST_POS_M = 250
  local TRUST_STOPPED_KMH = 30
  function Trust.on() return config.dataCheck end
  local function refuse(kind, sender, why)
    local who = sender and tostring(sender.sessionID) or '?'
    ac.log(string.format('race-control: data check: %s from car %s refused (%s)', kind, who, why))
    local key = kind .. '/' .. who
    if not Trust.refused[key] then
      Trust.refused[key] = true
      rcLog(TEXTS.rc.dataCheck, string.format('%s from car %s refused - %s', kind, who, why))
    end
    return false
  end
  function Trust.record(sender, car, ownAnswer)
    if not Trust.on() then return true end
    if not sender then return refuse('record', sender, 'no sender') end
    if sender.sessionID == car then return true end
    if ownAnswer then return true end
    return refuse('record', sender, 'about car ' .. tostring(car))
  end
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
  function Trust.list(sender, car)
    if not Trust.on() then return true end
    if sender and sender.sessionID == car then return true end
    return refuse('penalty list', sender, 'about car ' .. tostring(car))
  end
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
local RecordSync = {
  peers = {},
  parts = {},
  restorers = {},
  pending = {},
  askedT = nil,
  ownTrack = nil,
}
do
  local SYNC_PART = 120
  local SYNC_ANSWER_WINDOW = 30
  local SYNC_REQUEST = 255
  local SYNC_LISTS = { 'penalties', 'window', 'swap', 'track', 'car', 'gain', 'pit', 'stint', 'pass', 'kmr', 'stopwindow' }
  local SYNC_CODES = { penalties = 1, window = 2, swap = 3, track = 4, car = 5, gain = 6, pit = 7, stint = 8, pass = 9, kmr = 10 }
  local sendRecordEvent = ac.OnlineEvent({
    ac.StructItem.key('amxracing.race-control.rec'),
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
  function RecordSync.publish(list, seq, text)
    if not SYNC_CODES[list] then return end
    if list == 'track' then
      RecordSync.ownTrack = { seq = seq, text = text }
      return
    end
    queueRecord(ownSlot(), list, seq, text, nil)
  end
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
      if not RecordSync.askedT or state.ui.clock - RecordSync.askedT > SYNC_ANSWER_WINDOW then return end
      if not Record.sameSession(rec.key, Record.key()) then return end
      local p = RecordSync.pending.track
      if not p or rec.seq >= p.seq then RecordSync.pending.track = { body = rec.body, seq = rec.seq, key = rec.key } end
      return
    end
    keepPeer(car, list, rec.seq, text)
    if car ~= ownSlot() or not RecordSync.askedT then return end
    if state.ui.clock - RecordSync.askedT > SYNC_ANSWER_WINDOW then return end
    if not Record.sameRace(rec.key, Record.key()) then return end
    if Trust.on() then
      Trust.vote(list, rec.seq, text, sender)
      return
    end
    local p = RecordSync.pending[list]
    if not p or rec.seq >= p.seq then RecordSync.pending[list] = { body = rec.body, seq = rec.seq, key = rec.key } end
  end
  function RecordSync.receive(sender, msg)
    if sender and sender.index == 0 then return end
    if msg.rcList == SYNC_REQUEST then
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
  function RecordSync.update()
    for list, best in pairs(Trust.settled()) do
      local rec = Record.decode(best.text)
      if rec then RecordSync.pending[list] = { body = rec.body, seq = rec.seq, key = rec.key } end
    end
    local key = Record.key()
    for list, p in pairs(RecordSync.pending) do
      RecordSync.pending[list] = nil
      local restore = RecordSync.restorers[list]
      local here = p.key and (list == 'track' and Record.sameSession(p.key, key) or (list ~= 'track' and Record.sameRace(p.key, key)))
      if not here then
        ac.log('race-control: record ' .. list .. ' ' .. tostring(p.seq) .. ' of another session not applied (' .. tostring(p.key) .. ')')
      elseif restore and (p.seq or 0) >= Record.floor then restore(p.body, p.seq, 'peers') end
    end
  end
  Record.onSave = RecordSync.publish
end
RecordSync.base = { queue = {}, nextT = 0, busy = false, failLogged = false }
do
  local BASE_GAP = 5
  local B = RecordSync.base
  local function on() return config.baseUrl ~= '' and web ~= nil and web.request ~= nil end
  local function jsonStr(s)
    return '"' .. tostring(s):gsub('[%c"\\]', function(c)
      if c == '"' then return '\\"' elseif c == '\\' then return '\\\\' end
      return string.format('\\u%04x', c:byte())
    end) .. '"'
  end
  local function urlEncode(s)
    return (tostring(s):gsub('[^%w%-%._~]', function(c) return string.format('%%%02X', c:byte()) end))
  end
  function B.push(list, seq, text)
    if on() then B.queue[list] = text end
  end
  local LINES_MAX = 30
  function B.update()
    if not on() or B.busy or state.ui.clock < B.nextT or (next(B.queue) == nil and #state.rcOut == 0 and #state.lapOut == 0) then
      return
    end
    local sent, parts = B.queue, {}
    B.queue = {}
    for _, text in pairs(sent) do parts[#parts + 1] = jsonStr(text) end
    local lines, lineParts = {}, {}
    while #lines < LINES_MAX and #state.rcOut > 0 do lines[#lines + 1] = table.remove(state.rcOut, 1) end
    for _, l in ipairs(lines) do lineParts[#lineParts + 1] = jsonStr(l) end
    local lapLines, lapParts = {}, {}
    while #lapLines < LINES_MAX and #state.lapOut > 0 do lapLines[#lapLines + 1] = table.remove(state.lapOut, 1) end
    for _, l in ipairs(lapLines) do lapParts[#lapParts + 1] = jsonStr(l) end
    B.busy, B.nextT = true, state.ui.clock + BASE_GAP
    local body = '{"key":' .. jsonStr(Record.key()) .. ',"steam":' .. jsonStr(ac.getUserSteamID() or '')
      .. ',"records":[' .. table.concat(parts, ',') .. '],"lines":[' .. table.concat(lineParts, ',') .. '],"laps":['
      .. table.concat(lapParts, ',') .. ']}'
    WebQueue.request('POST', config.baseUrl .. '/v1/batch', { ['Content-Type'] = 'application/json' }, body,
      function(err, res)
        B.busy = false
        if err or not res or (tonumber(res.status) or 0) >= 300 then
          for list, text in pairs(sent) do if B.queue[list] == nil then B.queue[list] = text end end
          for i = #lines, 1, -1 do table.insert(state.rcOut, 1, lines[i]) end
          for i = #lapLines, 1, -1 do table.insert(state.lapOut, 1, lapLines[i]) end
          if not B.failLogged then
            B.failLogged = true
            ac.log('race-control: base online not reached (' .. tostring(err or (res and res.status)) .. '): kept to send again')
          end
        elseif B.failLogged then
          B.failLogged = false
          ac.log('race-control: base online reached again')
        end
      end)
  end
  function B.askOwn()
    if not on() then return end
    local key = Record.key()
    local function ask(path, apply)
      WebQueue.request('GET', config.baseUrl .. path .. '?key=' .. urlEncode(key), nil, nil, function(err, res)
        if err or not res or tonumber(res.status) ~= 200 then
          ac.log('race-control: base online ' .. path .. ' not read (' .. tostring(err or (res and res.status)) .. ')')
          return
        end
        for line in tostring(res.body or ''):gmatch('[^\r\n]+') do
          local rec = Record.decode(line)
          if rec then apply(rec) end
        end
      end)
    end
    local function keep(rec, from)
      local p = RecordSync.pending[rec.list]
      if not p or rec.seq >= p.seq then
        RecordSync.pending[rec.list] = { body = rec.body, seq = rec.seq, key = rec.key }
        ac.log('race-control: record ' .. rec.list .. ' ' .. rec.seq .. ' from the base online (' .. from .. ')')
      end
    end
    ask('/v1/record', function(rec)
      if rec.list ~= 'track' and Record.sameRace(rec.key, key) then keep(rec, 'own car') end
    end)
    ask('/v1/track', function(rec)
      if rec.list == 'track' and Record.sameSession(rec.key, key) then keep(rec, 'track of the session') end
    end)
  end
  local NAME_GAP = 30
  B.name = { status = nil, nextT = 0, busy = false, lockT = -1e9, told = nil, failLogged = false, offline = false, alertDue = nil }
  local function sendAlert(text)
    local body = '{"kind":"base_offline","steam":' .. jsonStr(ac.getUserSteamID() or '') .. ',"text":' .. jsonStr(text) .. '}'
    WebQueue.request('POST', config.baseUrl .. '/v1/alert', { ['Content-Type'] = 'application/json' }, body, function(err, res)
      if not err and res and tonumber(res.status) == 200 then B.name.alertDue = nil end
    end)
  end
  local function missingText(list)
    local out = {}
    for w in tostring(list or ''):gmatch('[^,]+') do out[#out + 1] = TEXTS.realNameWhat[w] or w end
    return table.concat(out, ', ')
  end
  function B.nameUpdate()
    if not config.realName or not on() then return end
    local N = B.name
    if not N.busy and N.status ~= 'ok' and state.ui.clock >= N.nextT then
      N.busy, N.nextT = true, state.ui.clock + NAME_GAP
      WebQueue.request('GET', config.baseUrl .. '/v1/name?s=' .. urlEncode(ac.getUserSteamID() or ''), nil, nil, function(err, res)
        N.busy = false
        if err or not res or tonumber(res.status) ~= 200 then
          N.offline = true
          if not N.failLogged then
            N.failLogged = true
            local started = sim.isSessionStarted
            local lock = config.realNameOffline == 'lock' and not started
            ac.log('race-control: real name not read from the base (' .. tostring(err or (res and res.status)) .. '): '
              .. (lock and 'controls locked until it answers' or 'nothing locked'))
            local what = string.format('base of the event not answering - real name not confirmed - %s',
              lock and 'controls locked (session not started)' or (started and 'session started, driving' or 'not locked'))
            rcLog(TEXTS.rc.baseOff, what)
            N.alertDue = what
          end
          return
        end
        if N.offline then
          N.offline = false
          if N.told == TEXTS.realNameOffline then physics.lockUserControlsFor(0); N.told = nil end
        end
        if N.alertDue then sendAlert(N.alertDue) end
        local kind, rest = tostring(res.body or ''):match('^(%u+)|([^\r\n]*)')
        if kind == 'OK' and rest:match('%S') then
          N.status, N.missing = 'ok', nil
          if N.told then physics.lockUserControlsFor(0) end
          local was = tostring(ac.getDriverName(0) or '')
          if was ~= rest and physics.setDriverName then physics.setDriverName(rest) end
          ac.log('race-control: real name ' .. rest .. ' (name of the AC: ' .. was .. ')')
        elseif kind == 'MISSING' then
          N.status, N.missing = 'missing', missingText(rest)
          if N.told ~= N.missing then
            N.told = N.missing
            rcLog(TEXTS.rc.regIncomplete, 'missing: ' .. N.missing)
          end
        end
      end)
    end
    if N.status == 'missing' then
      if state.ui.clock - N.lockT >= 2 then
        N.lockT = state.ui.clock
        physics.lockUserControlsFor(3)
      end
      showNotice(TEXTS.rcTitle, string.format(TEXTS.realNameMissing, N.missing), nil, 1)
    elseif N.offline and N.status ~= 'ok' and config.realNameOffline == 'lock' then
      if not sim.isSessionStarted then
        N.told = TEXTS.realNameOffline
        if state.ui.clock - N.lockT >= 2 then
          N.lockT = state.ui.clock
          physics.lockUserControlsFor(3)
        end
        showNotice(TEXTS.rcTitle, TEXTS.realNameOffline, nil, 1)
      elseif N.told == TEXTS.realNameOffline then
        N.told = nil
        physics.lockUserControlsFor(0)
      end
    end
  end
  local BEST_GAP = 120
  B.best = { value = nil, nextT = 0, busy = false }
  function B.trackKey()
    local layout = tostring(ac.getTrackLayout and ac.getTrackLayout() or '')
    return (tostring(ac.getTrackID() or '') .. (layout ~= '' and ('-' .. layout) or '')):gsub('[|%s]', '_')
  end
  function B.carKey() return (tostring(ac.getCarID(0) or ''):gsub('[|%s]', '_')) end
  function B.bestUpdate()
    local W = B.best
    if not on() or W.busy or state.ui.clock < W.nextT then return end
    W.busy, W.nextT = true, state.ui.clock + BEST_GAP
    WebQueue.request('GET', config.baseUrl .. '/v1/best?track=' .. urlEncode(B.trackKey()) .. '&car=' .. urlEncode(B.carKey()), nil, nil,
      function(err, res)
        W.busy = false
        if err or not res or tonumber(res.status) ~= 200 then return end
        local ms, s = tostring(res.body or ''):match('^OK|(%d+)|([%d/]*)')
        if not ms then W.value = nil return end
        local sec = {}
        for v in s:gmatch("%d+") do sec[#sec + 1] = tonumber(v) end
        W.value = { ms = tonumber(ms), s = sec }
      end)
  end
  local SERVER_GAP = 300
  B.server = { nextT = 0, busy = false }
  function B.serverUpdate()
    local V = B.server
    if not on() or V.busy or state.ui.clock < V.nextT then return end
    V.busy, V.nextT = true, state.ui.clock + SERVER_GAP
    WebQueue.request('GET', config.baseUrl .. '/v1/server', nil, nil, function(err, res)
      V.busy = false
      if err or not res or tonumber(res.status) ~= 200 then return end
      local body = tostring(res.body or '')
      if not body:match('^OK|') then return end
      local url = body:match('kmrStatsUrl=([^|%s]*)')
      if url and url ~= '' and url ~= config.kmrStatsUrl then
        ac.log('race-control: KMR web stats from the base: ' .. url .. ' (before: ' .. (config.kmrStatsUrl ~= '' and config.kmrStatsUrl or 'none') .. ')')
        config.kmrStatsUrl = url
      end
      for name, field in pairs({ pitStopsRequired = 'pitStopsRequired', pitWindowStart = 'pitWindowStart', pitWindowEnd = 'pitWindowEnd',
          swapWindowStart = 'swapWindowStart', swapWindowEnd = 'swapWindowEnd' }) do
        local v = tonumber(body:match(name .. '=(%-?%d+)'))
        if v and v ~= config[field] then
          ac.log(string.format('race-control: %s from the tool of the organization: %d (key of the server: %s)', name, v, tostring(config[field])))
          config[field] = v
        end
      end
    end)
  end
  local FORECAST_GAP = 60
  B.forecast = { list = nil, race = nil, session = nil, nextT = 0, busy = false, index = nil }
  function B.forecastUpdate()
    local F = B.forecast
    local index = sim.currentSessionIndex or 0
    if F.index ~= index then F.index, F.list, F.nextT = index, nil, 0 end
    if not on() or F.busy or state.ui.clock < F.nextT then return end
    F.busy, F.nextT = true, state.ui.clock + FORECAST_GAP
    WebQueue.request('GET', config.baseUrl .. '/v1/forecast?session=' .. index .. '&all=1', nil, nil, function(err, res)
      F.busy = false
      if err or not res or tonumber(res.status) ~= 200 or F.index ~= index then return end
      local body = tostring(res.body or '')
      local race, session = body:match('^OK|([^|\n]*)|([^|\n]*)')
      if not race then F.list, F.race, F.session = nil, nil, nil return end
      local list = {}
      for line in body:gmatch('[^\n]+') do
        local f = {}
        for v in (line .. '|'):gmatch('([^|]*)|') do f[#f + 1] = v end
        if #f >= 9 and f[1]:match('^%d+:%d+$') then
          list[#list + 1] = { time = f[1], type = f[2], sky = f[3]:gsub('%s*%(Sol%)', ''), wind = f[4], road = tonumber(f[5]),
            air = tonumber(f[6]), rain = tonumber(f[7]), wet = tonumber(f[8]), water = tonumber(f[9]), trans = tonumber(f[10]) or 0,
            tsec = tonumber(f[11]) or 0 }
        end
      end
      F.list, F.race, F.session = list, race, session
    end)
  end
  local RR_GAP = 5
  B.rr = { state = 'unknown', nextT = 0, busy = false, garage = '', area = '', screen = false, game = false, logged = nil, err = '',
    source = tostring(ac.storage['rc.share.source'] or 'game'), layout = tostring(ac.storage['rc.share.layout'] or 'single'),
    scope = tostring(ac.storage['rc.share.scope'] or 'all') == 'room' and 'room' or 'all' }
  function B.rrSet(source, layout, scope)
    local R = B.rr
    if source then R.source = source; ac.storage['rc.share.source'] = source end
    if layout then R.layout = layout; ac.storage['rc.share.layout'] = layout end
    if scope then R.scope = scope; ac.storage['rc.share.scope'] = scope end
  end
  function B.rrUpdate()
    local R = B.rr
    if not on() or R.busy or state.ui.clock < R.nextT then return end
    R.busy, R.nextT = true, state.ui.clock + RR_GAP
    WebQueue.request('GET', config.baseUrl .. '/v1/rr?s=' .. urlEncode(ac.getUserSteamID() or ''), nil, nil, function(err, res)
      R.busy = false
      if err or not res or tonumber(res.status) ~= 200 then R.state = 'offline'
      else
        local body = tostring(res.body or '')
        local garage, area, screen, game = body:match('^OK|([^|]*)|([^|]*)|(%d)|(%d)')
        if garage then
          R.state, R.garage, R.area, R.screen, R.game = 'on', garage, area, screen == '1', game == '1'
          R.err = body:match('^OK|[^|]*|[^|]*|%d|%d|([^\r\n]*)') or ''
          R.own = body:match('\nOWN|(%d)') == '1'
          local fr, fon, fwith, flist = body:match('\nFOCUS|(%d)|(%d)|(%d*)|([^\r\n]*)')
          R.focus = { room = fr == '1', on = fon == '1', with = fwith or '', people = {} }
          for st, nm in tostring(flist or ''):gmatch('(%d+):([^;]*)') do R.focus.people[#R.focus.people + 1] = { steam = st, name = nm } end
        else
          R.state, R.screen, R.game, R.err = body:find('^OTHER') and 'other' or 'none', false, false, ''
          R.focus = nil
        end
      end
      local now = R.state .. '|' .. R.garage .. '|' .. R.area .. '|' .. tostring(R.game) .. '|' .. R.err
      if R.logged ~= now then
        R.logged = now
        ac.log('race-control: Racing Room ' .. R.state .. (R.state == 'on' and (' - ' .. R.garage .. ' / ' .. R.area .. (R.game and ' - game screen shared' or '')
          .. (R.err ~= '' and (' - game screen failed: ' .. R.err) or '')) or ''))
      end
    end)
  end
  function B.rrRoom()
    local R = B.rr
    if R.state == 'on' and R.area ~= '' then return string.format(TEXTS.rrRoom, R.garage, TEXTS.rrAreas[R.area] or R.area), 'ok' end
    if R.state == 'on' then return TEXTS.rrNoRoom, 'warn' end
    if R.state == 'other' then return TEXTS.rrOther, 'warn' end
    if R.state == 'offline' then return TEXTS.rrOffline, 'bad' end
    if R.state == 'unknown' then return TEXTS.rrWait, 'dim' end
    return TEXTS.rrNone, 'bad'
  end
  function B.rrShare(share)
    local R = B.rr
    if not on() then return end
    local body = '{"steam":' .. jsonStr(ac.getUserSteamID() or '') .. ',"share":' .. (share and 'true' or 'false')
      .. ',"source":' .. jsonStr(R.source) .. ',"layout":' .. jsonStr(R.layout) .. ',"scope":' .. jsonStr(R.scope) .. '}'
    R.asked, R.answer, R.askedT = share, 'wait', state.ui.clock
    ac.log('race-control: game screen ' .. (share and 'on' or 'off') .. ' asked to the Racing Room (' .. R.source .. ', ' .. R.layout .. ')')
    WebQueue.request('POST', config.baseUrl .. '/v1/rr/share', { ['Content-Type'] = 'application/json' }, body, function(err, res)
      R.answer = (not err and res and tostring(res.body or '')) or 'offline'
      ac.log('race-control: game screen ask answered: ' .. R.answer)
      R.nextT = 0
    end)
  end
  function B.rrOwn(hide)
    local R = B.rr
    if not on() then return end
    local body = '{"steam":' .. jsonStr(ac.getUserSteamID() or '') .. ',"hideOwn":' .. (hide and 'true' or 'false') .. '}'
    ac.log('race-control: own screens ' .. (hide and 'hidden' or 'shown') .. ' asked to the Racing Room')
    WebQueue.request('POST', config.baseUrl .. '/v1/rr/share', { ['Content-Type'] = 'application/json' }, body, function() R.nextT = 0 end)
  end
  function B.rrFocus(isOn, withSteam)
    local R = B.rr
    if not on() then return end
    local body = '{"steam":' .. jsonStr(ac.getUserSteamID() or '') .. ',"on":' .. (isOn and 'true' or 'false') .. ',"with":' .. jsonStr(withSteam or '') .. '}'
    if R.focus then R.focus.on, R.focus.with = isOn, withSteam or '' end
    ac.log('race-control: focus ' .. (isOn and 'on' or 'off') .. ' asked to the Racing Room' .. ((withSteam or '') ~= '' and (' with ' .. withSteam) or ''))
    WebQueue.request('POST', config.baseUrl .. '/v1/rr/focus', { ['Content-Type'] = 'application/json' }, body, function(err, res)
      R.focusAnswer = (not err and res and tostring(res.body or '')) or 'offline'
      R.nextT = 0
    end)
  end
  function B.rrAsk()
    local R = B.rr
    if R.err ~= '' then return string.format(TEXTS.shareFailed, R.err), 'bad' end
    if R.asked == nil then return nil end
    if R.answer == 'wait' then return TEXTS.shareAsking, 'dim' end
    if R.answer == 'OTHER' then return TEXTS.rrOther, 'warn' end
    if R.answer == 'NONE' then return TEXTS.shareNoRoom, 'warn' end
    if R.answer == 'offline' then return TEXTS.rrOffline, 'bad' end
    if R.asked ~= R.game and state.ui.clock - (R.askedT or 0) < 20 then return TEXTS.shareSent, 'dim' end
    if R.asked ~= R.game then return TEXTS.shareNoAnswer, 'warn' end
    return nil
  end
  local STRAT_GAP, PLAN_GAP = 5, 10
  local SETUP_STORE = '.amxracing.race-control.setup'
  local clean = function(s) return (tostring(s or ''):gsub('[|;,/=\r\n]', ' ')) end
  B.strat = { sig = nil, nextT = 0, setupSig = nil }
  function B.stratUpdate()
    local T = B.strat
    if not on() or state.ui.clock < T.nextT then return end
    T.nextT = state.ui.clock + STRAT_GAP
    local parts = {}
    for _, sp in ipairs(ac.getPitstopSpinners and ac.getPitstopSpinners() or {}) do
      local vals = {}
      if type(sp.values) == 'table' then for k = 1, #sp.values do vals[#vals + 1] = tostring(math.floor(tonumber(sp.values[k]) or 0)) end end
      parts[#parts + 1] = table.concat({ clean(sp.name), clean(sp.type), tostring(math.floor(tonumber(sp.min) or 0)), tostring(math.floor(tonumber(sp.max) or 0)),
        tostring(math.floor(tonumber(sp.value) or 0)), table.concat(vals, '/') }, ',')
    end
    if #parts > 0 then
      local body = tostring(sim.currentQuickPitPreset or 0) .. '|' .. table.concat(parts, ';')
      if body ~= T.sig then T.sig = body; Record.save('strat', math.floor(serverTimeMs() / 1000), body) end
    end
    local kept = ac.load and ac.load(SETUP_STORE)
    if type(kept) == 'string' and kept ~= '' then
      local legal, why = 'legal', ''
      if ac.getCarSetupState then local ok, s, r = pcall(ac.getCarSetupState); if ok and s then legal, why = tostring(s), clean(r) end end
      local body = legal .. '|' .. why .. '|' .. kept
      if body ~= T.setupSig then T.setupSig = body; Record.save('setup', math.floor(serverTimeMs() / 1000), body) end
    end
    local raw = ac.load and ac.load('.amxracing.race-control.setupraw')
    if type(raw) == 'string' and raw ~= '' and raw ~= T.rawSig then T.rawSig = raw; Record.save('setupraw', math.floor(serverTimeMs() / 1000), raw) end
    local def = ac.load and ac.load('.amxracing.race-control.setupdef')
    if type(def) == 'string' and def ~= '' and def ~= T.defSig then T.defSig = def; Record.save('setupdef', math.floor(serverTimeMs() / 1000), def) end
  end
  local BOX_GAP = 2
  B.box = { sig = nil, nextT = 0 }
  function B.boxUpdate()
    local T = B.box
    if not on() or not B.pitBox or state.ui.clock < T.nextT then return end
    T.nextT = state.ui.clock + BOX_GAP
    local car = ac.getCar(0)
    if not car then return end
    local ok, body = pcall(B.pitBox.stateBody, car)
    if ok and body and body ~= T.sig then T.sig = body; Record.save('box', math.floor(serverTimeMs() / 1000), body) end
  end
  local STATUS_GAP = 5
  B.status = { sig = nil, nextT = 0 }
  function B.statusUpdate()
    local T = B.status
    if not on() or not B.statusBody or state.ui.clock < T.nextT then return end
    T.nextT = state.ui.clock + STATUS_GAP
    local car = ac.getCar(0)
    if not car then return end
    local ok, body = pcall(B.statusBody, car)
    if ok and body and body ~= T.sig then T.sig = body; Record.save('status', math.floor(serverTimeMs() / 1000), body) end
  end
  local ELEC_GAP, ELEC_ERS_GAP = 2, 60
  B.elec = { sig = nil, nextT = 0, ersT = 0 }
  function B.elecUpdate()
    local T = B.elec
    if not on() or state.ui.clock < T.nextT then return end
    T.nextT = state.ui.clock + ELEC_GAP
    local car = ac.getCar(0)
    if not car then return end
    local n = function(v) return math.floor(tonumber(v) or 0) end
    local hybrid = n(car.mgukDeliveryCount) > 0 or car.kersPresent == true
    local settings = table.concat({ n(car.absMode), n(car.absModes), n(car.tractionControlMode), n(car.tractionControlModes), string.format('%g', tonumber(car.tractionControl2) or 0),
      n(car.tractionControl2Modes), n(car.fuelMap), n(car.fuelMaps), n(car.currentEngineBrakeSetting), n(car.engineBrakeSettingsCount),
      string.format('%.1f', (tonumber(car.brakeBias) or 0) * 100), hybrid and 1 or 0, n(car.mgukDelivery), n(car.mgukDeliveryCount), n(car.mgukRecovery),
      car.mguhChargingBatteries and 1 or 0 }, '|')
    local ers = hybrid and string.format('%.0f', (tonumber(car.kersCharge) or 0) * 100) or ''
    local ersDue = hybrid and state.ui.clock >= T.ersT
    if settings ~= T.sig or ersDue then
      T.sig, T.ersT = settings, state.ui.clock + ELEC_ERS_GAP
      Record.save('elec', math.floor(serverTimeMs() / 1000), settings .. '|' .. ers)
    end
  end
  B.stab = { done = nil, nextT = 0 }
  function B.setupTabUpdate()
    local T = B.stab
    local key = tostring(ac.getCarID and ac.getCarID(0) or '')
    if not on() or key == '' or T.done == key or state.ui.clock < T.nextT then return end
    T.nextT = state.ui.clock + 30
    local ok, ini = pcall(ac.INIConfig.carData, 0, 'setup.ini')
    if not ok or not ini or type(ini.sections) ~= 'table' then return end
    local parts = {}
    for sec, keys in pairs(ini.sections) do
      local name = type(keys) == 'table' and type(keys.NAME) == 'table' and keys.NAME[1]
      local tab = type(keys) == 'table' and type(keys.TAB) == 'table' and keys.TAB[1]
      if name and tab then
        parts[#parts + 1] = (tostring(name):gsub('[|;=%c]', ' ')) .. '=' .. (tostring(tab):gsub('[|;=%c]', ' ')) .. '|' .. (tostring(sec):gsub('[|;=%c]', ' '))
      end
    end
    table.sort(parts)
    if #parts > 0 then T.done = key; Record.save('setuptab', math.floor(serverTimeMs() / 1000), table.concat(parts, ';')) end
  end
  B.plan = { nextT = 0, busy = false, done = tostring(ac.storage['rc.pitplan'] or '') }
  local PLAN_PIT_GAP = 2
  function B.planUpdate()
    local P = B.plan
    if not on() or P.busy or state.ui.clock < P.nextT then return end
    local car = ac.getCar(0)
    P.busy, P.nextT = true, state.ui.clock + ((car and car.isInPitlane) and PLAN_PIT_GAP or PLAN_GAP)
    WebQueue.request('GET', config.baseUrl .. '/v1/pitplan?s=' .. urlEncode(ac.getUserSteamID() or ''), nil, nil, function(err, res)
      P.busy = false
      if err or not res or tonumber(res.status) ~= 200 then return end
      local id, preset, list, box = tostring(res.body or ''):match('^OK|([%w%-]+)|(%d+)|([^|\r\n]*)|?([^\r\n]*)')
      if not id or id == P.done then return end
      local changes = {}
      for name, value in list:gmatch('([^;=]+)=(%-?%d+)') do changes[#changes + 1] = { name = name, value = tonumber(value) } end
      P.done = id
      ac.storage['rc.pitplan'] = id
      if box ~= '' and B.pitBox then
        local f = {}
        for k, v in box:gmatch('(%a+)=([^;]*)') do f[k] = v end
        for _, c in ipairs(changes) do B.pitBox.preset[c.name] = c.value end
        B.pitBox.remote({ fuel = tonumber(f.fuel), compound = tonumber(f.compound), tyres = tonumber(f.tyres), repair = f.repair,
          preset = tonumber(f.preset), auto = f.mode == 'auto' and true or f.mode == 'manual' and false or nil, start = f.start == '1', press = f.press })
        B.box.nextT, B.box.sig = state.ui.clock + 1, nil
        rcLog(TEXTS.rc.pitPlan, 'box from the Racing Room: ' .. box .. (list ~= '' and ('; ' .. list) or ''))
        if f.start == '1' then showNotice(TEXTS.rcTitle, TEXTS.remotePitStart, nil, 6) end
      else
        if #changes == 0 then return end
        if not (B.app and B.app.alive) then P.done = nil; ac.storage['rc.pitplan'] = ''; return end
        B.app.setPreset(changes, tonumber(preset) or 0)
        B.strat.nextT, B.strat.sig = state.ui.clock + 2, nil
        rcLog(TEXTS.rc.pitPlan, string.format('from the Racing Room, preset %d: %s', (tonumber(preset) or 0) + 1, list))
      end
      WebQueue.request('POST', config.baseUrl .. '/v1/pitplan/done', { ['Content-Type'] = 'application/json' },
        '{"steam":' .. jsonStr(ac.getUserSteamID() or '') .. ',"id":' .. jsonStr(id) .. '}', function() end)
    end)
  end
  local PUSH_STORE, PUSH_DONE, PUSH_EVENT = '.amxracing.race-control.setuppush', '.amxracing.race-control.setuppush.done', 'amxracing.race-control.setuppush'
  B.spush = { nextT = 0, busy = false, id = nil, answered = nil }
  local function pushDone(id, st, reason)
    WebQueue.request('POST', config.baseUrl .. '/v1/setuppush/done', { ['Content-Type'] = 'application/json' },
      '{"steam":' .. jsonStr(ac.getUserSteamID() or '') .. ',"id":' .. jsonStr(id) .. ',"state":' .. jsonStr(st) .. ',"reason":' .. jsonStr(reason or '') .. '}',
      function() end)
  end
  function B.setupPushUpdate()
    local P = B.spush
    if not on() or not (B.app and B.app.alive) then return end
    local done = ac.load and ac.load(PUSH_DONE)
    if type(done) == 'string' then
      local id, st, why = done:match('^([%w%-]+)|(%a+)|(.*)$')
      if id and id ~= P.answered then
        P.answered = id
        rcLog(TEXTS.rc.teamSetup, string.format('answer of the driver: %s%s', st, why ~= '' and (' - ' .. why) or ''))
        pushDone(id, st, why)
      end
    end
    if P.busy or state.ui.clock < P.nextT then return end
    P.busy, P.nextT = true, state.ui.clock + PLAN_GAP
    WebQueue.request('GET', config.baseUrl .. '/v1/setuppush?s=' .. urlEncode(ac.getUserSteamID() or ''), nil, nil, function(err, res)
      P.busy = false
      if err or not res or tonumber(res.status) ~= 200 then return end
      local id, name, ini = tostring(res.body or ''):match('^OK|([%w%-]+)|([^\r\n]*)\r?\n(.*)$')
      if not id or id == P.id then return end
      P.id = id
      ac.store(PUSH_STORE, id .. '|' .. name .. '\n' .. ini)
      ac.broadcastSharedEvent(PUSH_EVENT, id)
      rcLog(TEXTS.rc.teamSetup, string.format('from the Racing Room: %s - apply it in the setup menu', name))
      showNotice(TEXTS.rcTitle, string.format(TEXTS.teamSetup, name), nil, 8)
      pushDone(id, 'entregue', '')
    end)
  end
  local publish = Record.onSave
  Record.onSave = function(list, seq, text)
    if publish then publish(list, seq, text) end
    B.push(list, seq, text)
  end
end
local AppLink = { alive = false }
RecordSync.base.app = AppLink
do
  local APP_REQUEST = 'amxracing.race-control.preset'
  local APP_ANSWER = 'amxracing.race-control.preset.done'
  function AppLink.setSetup(values)
    local parts = {}
    for name, v in pairs(values) do parts[#parts + 1] = name .. '=' .. math.floor(v) end
    table.sort(parts)
    local text = table.concat(parts, ';')
    ac.broadcastSharedEvent('amxracing.race-control.setupvalues', text)
    ac.log('race-control: pit stop pressure sent to the app (setup): ' .. text)
  end
  function AppLink.setPreset(changes, preset)
    local parts = { '@' .. math.floor(preset or 0) }
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
  function AppLink.waiting() return not AppLink.alive and state.ui.clock - pingT < 3 end
  local PING_SECONDS, CHECK_SECONDS, CLOSE_SECONDS = 2, 30, 10
  local CSP_MIN = 4130
  local function cspOld()
    local ok, code = pcall(function() return ac.getPatchVersionCode and ac.getPatchVersionCode() end)
    code = ok and tonumber(code) or 0
    return code > 0 and code < CSP_MIN, code
  end
  local lastPing, lockT, missingLogged = -1e9, -1e9, false
  function AppLink.update()
    local clock = state.ui.clock
    if clock - lastPing >= PING_SECONDS then
      lastPing = clock
      ac.broadcastSharedEvent(APP_REQUEST, '')
    end
    local old, code = cspOld()
    if (AppLink.alive and not old) or clock < CHECK_SECONDS then return end
    local text = old and TEXTS.cspOld or TEXTS.appMissing
    if not missingLogged then
      missingLogged = true
      ac.log(old and string.format('race-control: CSP build %d below %d: controls locked, the game closes', code, CSP_MIN)
        or 'race-control: the Racing Control app is not running: controls locked, the game closes')
      rcLog(old and 'CSP old' or 'App missing', string.format(text, CLOSE_SECONDS))
    end
    if clock - lockT >= 2 then
      lockT = clock
      physics.lockUserControlsFor(3)
    end
    local left = math.max(math.ceil(CHECK_SECONDS + CLOSE_SECONDS - clock), 0)
    showNotice(TEXTS.rcTitle, string.format(text, left), nil, 1)
    if left <= 0 and not AppLink.closed then
      AppLink.closed = true
      ac.shutdownAssettoCorsa()
    end
  end
  local COCKPIT_REQUEST = 'amxracing.race-control.cockpit'
  local COCKPIT_ANSWER = 'amxracing.race-control.cockpit.state'
  AppLink.cockpitState = {}
  local COCKPIT_CHANNELS = { 'main', 'engine', 'transmission', 'tyres', 'surfaces', 'dirt', 'wind', 'opponents',
    'carComponents', 'track', 'weather', 'rain', 'wipers' }
  local COCKPIT_STORE = '.amxracing.race-control.cockpit'
  local storeLogged = false
  function AppLink.cockpitRead(car)
    local st = {}
    local kept = ac.load and ac.load(COCKPIT_STORE)
    if type(kept) == 'string' and kept ~= '' then
      for item, value in kept:gmatch('([%w%.]+)=(%-?[%d%.]+)') do st[item] = tonumber(value) end
      if not storeLogged then
        storeLogged = true
        ac.log('race-control: cockpit: values of the app read from the shared storage: ' .. Lang.letters.head(kept, 160))
      end
    end
    for k, v in pairs(AppLink.cockpitState) do st[k] = v end
    local function num(v) v = tonumber(v); return v and v == v and v or nil end
    st.ffb = num(car and car.ffbMultiplier) or st.ffb
    st.fov = num(ac.getSim().firstPersonCameraFOV) or st.fov
    local eyes = car and car.driverEyesPosition
    if eyes then st.x, st.y = num(eyes.x) or st.x, num(eyes.y) or st.y end
    if ac.getAudioVolume then
      for _, ch in ipairs(COCKPIT_CHANNELS) do
        local v = num(ac.getAudioVolume(ch, nil, -1))
        if v and v >= 0 then st['vol.' .. ch] = v end
      end
    end
    return st
  end
  AppLink.cockpitSavedT = nil
  local cockpitAsk = { t = nil, answered = false, warned = false }
  function AppLink.cockpit(text)
    ac.broadcastSharedEvent(COCKPIT_REQUEST, text)
    if text == 'state' and not cockpitAsk.t then cockpitAsk.t = state.ui.clock end
    if cockpitAsk.t and not cockpitAsk.answered and not cockpitAsk.warned and state.ui.clock - cockpitAsk.t >= 5 then
      cockpitAsk.warned = true
      ac.log('race-control: cockpit: no answer of the app to the values asked 5 s ago')
    end
  end
  ac.onSharedEvent(COCKPIT_ANSWER, function(data, senderName, senderType)
    local st, n = {}, 0
    for item, value in tostring(data or ''):gmatch('([%w%.]+)=(%-?[%d%.]+)') do st[item] = tonumber(value); n = n + 1 end
    if not cockpitAsk.answered then
      cockpitAsk.answered = true
      ac.log(string.format('race-control: cockpit: first answer of the app (%s, %s): %d values, %d characters: %s', tostring(senderName),
        tostring(senderType), n, #tostring(data or ''), Lang.letters.head(data, 160)))
    end
    if st.saved then
      st.saved = nil
      AppLink.cockpitSavedT = state.ui.clock
      ac.log('race-control: cockpit: values saved by the app for the car')
    end
    AppLink.cockpitState = st
  end)
  local LANG_EVENT, LANG_STORE, LANG_OK = 'amxracing.race-control.lang', '.amxracing.race-control.lang', 'amxracing.race-control.lang.ok'
  AppLink.lang = nil
  ac.onSharedEvent(LANG_EVENT, function(data)
    local code = tostring(data or '')
    if code ~= 'pt' and code ~= 'en' then return end
    if not AppLink.lang then
      local n = 0
      if code == 'pt' then
        n = Lang.apply(ac.load and ac.load(LANG_STORE))
        if n == 0 then
          ac.log('race-control: language pt told by the app, its texts not in the shared storage yet')
          return
        end
      end
      AppLink.lang = code
      ac.log(string.format('race-control: language %s from the app of the game (%d texts)', code, n))
    end
    ac.broadcastSharedEvent(LANG_OK, AppLink.lang)
  end)
  ac.onSharedEvent(APP_ANSWER, function(data, senderName, senderType, senderID)
    AppLink.alive = true
    if tostring(data or '') == '' then return end
    ac.log(string.format('race-control: pit stop preset written by the app (%s, %s, %s): %s', tostring(senderName),
      tostring(senderType), tostring(senderID), tostring(data)))
    local cb = AppLink.onWritten
    AppLink.onWritten = nil
    if cb then cb(tostring(data)) end
  end)
end
local PitRecord = { stops = 0, last = '-', HOLD_MAX = 86400, HOLD_GRACE = 2000 }
PitRecord.onService = nil
local startHold
function PitRecord.save()
  local h = state.hold
  local text = h and tostring(h.text):gsub('|', '/') or ''
  PitRecord.seq = (PitRecord.seq or 0) + 1
  local sv = state.pitService
  local rt = state.redTow
  local inv = state.swapInvalid
  Record.save('pit', PitRecord.seq, string.format('%d|%s|%d|%s|%s|%d|%s|%d|%s|%s', PitRecord.stops, PitRecord.last,
    h and math.floor(h.untilMs) or 0, text,
    sv and string.format('%d/%d/%s', math.floor(sv.startMs), math.floor(sv.untilMs), sv.plan) or '-',
    state.pitPassServiced and 1 or 0, rt and string.format('%d/%.4f/%.4f/%.2f', rt.tow, rt.damage.powertrain,
    rt.damage.suspension, rt.damage.body) or '', state.pitPassSgPaid or 0,
    inv and string.format('%d/%d', inv.driver, math.floor(inv.since)) or '',
    h and tostring(h.cause or ''):gsub('[|]', '/') or ''))
end
function PitRecord.apply(body, seq, newConnection)
  local f = {}
  for v in (tostring(body) .. '|'):gmatch('([^|]*)|') do f[#f + 1] = v end
  local stops, last, untilMs, text, service, serviced, redTow, sgPaid, invalid, cause =
    f[1], f[2] or '', f[3], f[4] or '', f[5] or '', f[6] or '', f[7] or '', f[8] or '', f[9] or '', f[10] or ''
  if not (stops and tonumber(stops) and untilMs and tonumber(untilMs)) then return end
  if tonumber(sgPaid or '') and tonumber(sgPaid) ~= 0 then state.pitPassSgPaid = tonumber(sgPaid) end
  local invDriver, invSince = tostring(invalid or ''):match('^(%d+)/(%d+)$')
  if invDriver and not state.swapInvalid then
    state.swapInvalid = { driver = tonumber(invDriver), since = tonumber(invSince) }
  end
  local rtTow, rtP, rtS, rtB = tostring(redTow or ''):match('^(%d+)/([%d%.]+)/([%d%.]+)/([%d%.]+)$')
  if rtTow and not state.redTow then
    state.redTow = { tow = tonumber(rtTow), damage = { powertrain = tonumber(rtP), suspension = tonumber(rtS),
      body = tonumber(rtB) } }
  end
  if serviced == '1' then state.pitPassServiced = true end
  local svStart, svUntil, svPlan = service:match('^(%d+)/(%d+)/(.+)$')
  if svStart and not state.pitService and PitRecord.onService then
    PitRecord.onService(tonumber(svStart), tonumber(svUntil), svPlan)
  end
  PitRecord.seq = math.max(PitRecord.seq or 0, seq or 0)
  PitRecord.stops = math.max(PitRecord.stops, tonumber(stops))
  PitRecord.last = last
  local left = (tonumber(untilMs) - serverTimeMs()) / 1000
  if left <= 0 or state.hold then return end
  if left > PitRecord.HOLD_MAX then
    ac.log(string.format('race-control: hold of %.0f s left not put back (over %d s: not of this session)', left, PitRecord.HOLD_MAX))
    return
  end
  if newConnection then
    startHold(left, text, cause)
    ac.log(string.format('race-control: hold goes on after the new connection, %.0f s left', left))
  else
    state.hold = { untilMs = tonumber(untilMs), text = text, cause = cause ~= '' and cause or nil }
  end
end
function PitRecord.load(fresh)
  PitRecord.stops, PitRecord.last, PitRecord.seq = 0, '-', 0
  if fresh then
    PitRecord.seq = math.floor(serverTimeMs() / 1000)
    PitRecord.save()
    ac.log('race-control: pit record of the session before not carried over')
    return
  end
  local body, seq, source = Record.load('pit')
  if body then PitRecord.apply(body, seq, source ~= 'store') end
end
startHold = function(seconds, text, cause)
  state.tow.ownJumpUntil = state.ui.clock + 2
  physics.setCarPenalty(TELEPORT_TO_PITS, seconds)
  state.hold = { untilMs = serverTimeMs() + seconds * 1000, text = text, cause = cause }
  PitRecord.save()
end
function PitRecord.holdText()
  local h = state.hold
  if not h then return '' end
  local c = tostring(h.cause or '')
  if c == 'dt2' then return TEXTS.holdTwoDT end
  if c == 'dt2long' then return TEXTS.holdTwoDTLong end
  local tow, repair = c:match('^tow/(%d+)/(%d+)$')
  if tow then return string.format(TEXTS.holdTowRepair, mmss(tonumber(tow)), mmss(tonumber(repair))) end
  local only = c:match('^repair/(%d+)$')
  if only then return string.format(TEXTS.holdRepair, mmss(tonumber(only))) end
  local why = c:match('^quali/(.*)$')
  if why then return string.format(TEXTS.qualiEndHold, why) end
  return tostring(h.text or '')
end
function PitRecord.holdLeft()
  return state.hold and math.max((state.hold.untilMs - serverTimeMs()) / 1000, 0) or 0
end
function PitRecord.holdOver()
  return PitRecord.holdEnded ~= nil and serverTimeMs() <= PitRecord.holdEnded + PitRecord.HOLD_GRACE
end
RecordSync.restorers.pit = function(body, seq)
  if seq < (PitRecord.seq or 0) then return end
  PitRecord.apply(body, seq, true)
end
local DICT
do
  local N = '[^%d%-%+%s]*([%-%+]?%d[%d,]*%.?%d*)'
  DICT = {
    flags = {
      green = { en = { 'green flag' }, pt = { 'bandeira verde' } },
      vsc = { en = { 'virtual safety car' }, pt = { 'safety car virtual' } },
      sc = { en = { 'safety car' } },
      code80 = { en = { 'code-80', 'code 80', 'full course yellow' },
        pt = { 'código-80', 'codigo-80', 'código 80', 'codigo 80' } },
      ended = { en = { 'ended' }, pt = { 'terminado' } },
      rolling = { en = { 'rolling start', 'formation lap' }, pt = { 'largada em movimento', 'volta de formacao' } },
    },
    kmr = {
      penalty = { en = { 'penalty' }, pt = { 'penalidade' } },
      driveThrough = { en = { 'drive-through', 'drive through', 'drivethrough', 'stop and go', 'stop-and-go', 'stop & go' } },
      nextRace = { en = { 'next race' }, pt = { 'proxima corrida' } },
      thisLap = { en = { 'this lap' }, pt = { 'desta volta' } },
      withinLaps = { en = { 'within (%d+) lap' }, pt = { 'dentro de no maximo (%d+)' } },
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
      points = { en = { '^%s*penalty%s*%+%d+%s*%((%d+)/(%d+)%)' }, pt = { '^%s*penalidade%s*%+%d+%s*%((%d+)/(%d+)%)' } },
      crashes = { en = { 'crashes: (%d+) %(per 100km: ([%d%.,]+)', 'crashes: (%d+) %(crashes per 100km: ([%d%.,]+)' },
        pt = { 'acidentes: (%d+) %(per 100km: ([%d%.,]+)', 'batidas: (%d+) %(batidas por 100km: ([%d%.,]+)' } },
      infractions = { en = { 'driving infractions: (%d+) %(per 100km: ([%d%.,]+)' },
        pt = { 'infrações de pilotagem: (%d+) %(per 100km: ([%d%.,]+)', 'infracoes de pilotagem: (%d+) %(per 100km: ([%d%.,]+)' } },
      distance = { en = { 'driven distance: ([%d%.,]+)%s*km' }, pt = { 'distância pilotada: ([%d%.,]+)%s*km', 'distancia pilotada: ([%d%.,]+)%s*km' } },
      noStats = { en = { 'no stats to show yet' }, pt = { 'sem status para mostrar ainda' } },
      ratingNow = { en = { 'you now have ' .. N, 'you have ' .. N .. '%S* in your account' },
        pt = { 'voce agora possui ' .. N, 'agora voce possui ' .. N, 'voce possui ' .. N .. '%S* na sua conta' } },
      ratingAdded = { en = { 'you have been paid ' .. N, 'paid you additional ' .. N, 'you earned ' .. N },
        pt = { 'voce foi pago ' .. N, 'pagaram um adicional de ' .. N, 'voce ganhou ' .. N } },
      dtCancelled = { en = { "drive-through penalty for event" }, pt = { 'drive-through pelo evento' } },
      directorPenalty = { en = { 'money penalty', 'points penalty', 'point penalty' },
        pt = { 'penalidade em dinheiro', 'penalidade de pontos', 'pontos de penalidade', 'dinheiro de penalidade' } },
      lapInvalid = { en = { 'laptime invalidated' }, pt = { 'tempo de volta invalidado' } },
    },
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
      { 'director', en = { 'race control:' }, pt = { 'direcao de prova:' } },
      { 'warnings', en = { 'being lapped', 'make room for', 'overtaking is not permitted', 'do not speed over',
          'do not slow down under', 'you can\'t stop here', 'ping is too high', 'times do not match', 'warning' },
        pt = { 'tomando uma volta', 'abra espaco', 'ultrapassagens nao sao permitidas', 'nao exceda a velocidade',
          'nao ande abaixo', 'voce nao pode parar aqui', 'ping esta muito alto', 'relogio nao esta', 'alerta', 'atencao' } },
    },
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
    acsm = {
      swapWait = { en = { 'please wait (%S+) before leaving the pits', '^free to leave pits in (%S+)' } },
      swapClear = { en = { 'you are clear to leave the pits' } },
      swapEarly = { en = { 'during a driver swap' } },
      kicked = { en = { 'kicked' } },
    },
  }
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
  function DICT.area(low)
    for _, a in ipairs(DICT.areas) do
      for _, w in ipairs(a.words) do
        if low:find(w, 1, true) then return a.id end
      end
    end
    return nil
  end
  function DICT.match(text, patterns)
    for _, p in ipairs(patterns) do
      local a, b = text:match(p)
      if a then return a, b end
    end
    return nil
  end
end
DICT.rcActions = { REDFLAG = true, RELAX = true, UNLOCK = true, DT = true, HOLD = true, TELEPORT = true, DSQ = true,
  LOCK = true, FUEL = true, KMR = true }
DICT.code80Kinds = { VSC = true, SC = true, ['CODE-80'] = true }
local function hasAny(text, words)
  for _, word in ipairs(words) do
    if text:find(word, 1, true) then return true end
  end
  return false
end
local function namesAnother(message)
  for i = 1, (sim.carsCount or 1) - 1 do
    local c = ac.getCar(i)
    local n = c and c.isConnected and ac.getDriverName(i)
    if n and n ~= '' and message:find(n, 1, true) then return true end
  end
  return false
end
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
    local head = message:match('^%s*([^:]+):%s')
    if head and hasAny(head:lower(), DICT.kmr.penalty) then head = nil end
    if hasAny(low, DICT.kmr.penalty) and not head and not namesAnother(message) then
      return 'DT'
    end
  end
  return nil
end
local function parseGoDuration(text)
  local total, found = 0, false
  for num, unit in text:gmatch('([%d%.]+)([hms])') do
    total = total + tonumber(num) * (unit == 'h' and 3600 or unit == 'm' and 60 or 1)
    found = true
  end
  return found and total or nil
end
local TrackList = {
  since = -1,
  frozenMs = 0,
  frozenSince = nil,
}
do
  local function trackBody()
    local red = state.redFlag
    return string.format('%s|%d|%s|%s|%s|%d|%s|%d|%s', state.code80 or 'GREEN', math.floor(TrackList.since),
      red and 'RED' or '-', red and red.reason and (red.reason:gsub('[|\r\n]', ' ')) or '',
      state.restart and math.floor(state.restart.t0) or '', math.floor(TrackList.frozenMs),
      TrackList.frozenSince and math.floor(TrackList.frozenSince) or '', state.postRed and 1 or 0,
      state.lights or '')
  end
  local function trackSave()
    Record.save('track', math.floor(TrackList.since / 1000), trackBody())
  end
  local function windowStill() return state.redFlag ~= nil or state.restart ~= nil or state.postRed == true end
  local function freezeUpdate(now)
    if windowStill() and not TrackList.frozenSince then
      TrackList.frozenSince = now
      ac.log('race-control: pit window clock stopped (red flag)')
    elseif not windowStill() and TrackList.frozenSince then
      TrackList.frozenMs = TrackList.frozenMs + math.max(now - TrackList.frozenSince, 0)
      TrackList.frozenSince = nil
      ac.log(string.format('race-control: pit window clock goes on (restart, green flag); stood still %.0f s in total',
        TrackList.frozenMs / 1000))
    end
  end
  function TrackList.frozenNowMs()
    return TrackList.frozenMs + (TrackList.frozenSince and math.max(serverTimeMs() - TrackList.frozenSince, 0) or 0)
  end
  function TrackList.changed()
    TrackList.since = serverTimeMs()
    freezeUpdate(TrackList.since)
    trackSave()
  end
  local function trackApply(body, source)
    local kind, since, red, reason, rt, frozen, frozenSince, postRed, lights =
      tostring(body):match('^([%w%-]+)|(%d+)|?([%w%-]*)|?([^|]*)|?(%d*)|?(%d*)|?(%d*)|?(%d?)|?(%a*)$')
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
    state.restart = (rt or '') ~= '' and { t0 = tonumber(rt) } or nil
    state.postRed = postRed == '1' or nil
    state.lights = (lights == 'RED' or lights == 'GREEN') and lights or nil
    TrackList.frozenMs = tonumber(frozen) or 0
    TrackList.frozenSince = (frozenSince or '') ~= '' and tonumber(frozenSince) or nil
    TrackList.since = since
    return true
  end
  function TrackList.load()
    TrackList.since = -1
    TrackList.frozenMs, TrackList.frozenSince = 0, nil
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
    state.swap.remaining = nil
    showNotice(TEXTS.rcTitle, message, nil, SERVER_NOTICE_SECONDS)
    local kicked = hasAny(low, A.kicked)
    ac.log('race-control: ACSM driver swap penalty: ' .. message)
    rcLog(kicked and 'Disqualified by ACSM' or 'ACSM penalty', message)
    return true
  end
  return false
end
local MSG_SWAP_INFO = 1
local SWAP_RELAY_DELAYS = { 1, 4, 10 }
local function nameCode(name)
  local h = 5381
  name = tostring(name or '')
  for i = 1, #name do h = (h * 33 + name:byte(i)) % 4294967296 end
  return h
end
local SwapRecord = {}
function SwapRecord.save()
  local sw = state.swap
  Record.save('swap', math.floor(serverTimeMs() / 1000), string.format('%d|%d|%d|%d|%d', sw.count, sw.valid, sw.swapNo,
    sw.driver, sw.voids))
end
function SwapRecord.validNow()
  local sw = state.swap
  return math.max(sw.valid - sw.voids, 0)
end
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
  if not sw.swapInfo then
    sw.swapInfo = { inWindow = msg.pcInWindow == 1 }
    sw.entered = true
    sw.count = math.max(sw.count, msg.pcSwaps or 0)
    sw.valid = math.max(sw.valid, msg.pcValid or 0)
    ac.log(string.format('race-control: driver swap %d, %s', sw.count,
      sw.swapInfo.inWindow and 'valid' or 'pit entry outside the pit window: not valid'))
  end
  if sw.remaining or sw.clearUntil then return end
  local left = config.swapMinSeconds - msg.pcElapsed / 10
  ac.log(string.format('race-control: swap relay: previous driver left %.1f s ago, wait %.1f s',
    msg.pcElapsed / 10, math.max(left, 0)))
  if left <= 0 then
    sw.clearUntil = state.ui.clock + SERVER_NOTICE_SECONDS
    sw.clearElapsed = msg.pcElapsed / 10
    return
  end
  sw.remaining = left
  sw.remainingT = state.ui.clock
  sw.fromPeers = true
end
local sendSwapInfo = ac.OnlineEvent({
  ac.StructItem.key('amxracing.race-control.swap'),
  pcType = ac.StructItem.uint8(),
  pcCar = ac.StructItem.uint8(),
  pcDriver = ac.StructItem.uint32(),
  pcElapsed = ac.StructItem.uint16(),
  pcSwaps = ac.StructItem.uint8(),
  pcValid = ac.StructItem.uint8(),
  pcInWindow = ac.StructItem.uint8(),
}, function(sender, msg)
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
  if nameCode(ac.getDriverName(carIndex)) == rec.driver then
    sw.carLists[carIndex] = nil
    return
  end
  sw.carSwaps[carIndex] = (sw.carSwaps[carIndex] or 0) + 1
  local inWindow = sw.pitEntryValid[carIndex] ~= false
  if inWindow then sw.carValid[carIndex] = (sw.carValid[carIndex] or 0) + 1 end
  for _, delay in ipairs(SWAP_RELAY_DELAYS) do
    sw.relay[#sw.relay + 1] = { target = sessionID, car = sessionID, driver = rec.driver, leftT = rec.t,
      swaps = sw.carSwaps[carIndex] or 0, valid = sw.carValid[carIndex] or 0, inWindow = inWindow,
      list = sw.carLists[carIndex], dueT = state.ui.clock + delay }
  end
end)
local sendPenaltyList, publishOwnList
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
    if #items > 0 then sw.pendingList = items end
  end
  local penaltyListLayout = {
    ac.StructItem.key('amxracing.race-control.list'),
    pcCar = ac.StructItem.uint8(),
    pcCount = ac.StructItem.uint8(),
    pcTarget = ac.StructItem.uint8(),
  }
  for i = 1, PENALTY_LIST_MAX do
    penaltyListLayout['pcCat' .. i] = ac.StructItem.uint8()
    penaltyListLayout['pcLaps' .. i] = ac.StructItem.uint8()
  end
  local sendPenaltyListEvent = ac.OnlineEvent(penaltyListLayout, function(sender, msg)
    if sender and sender.index == 0 then return end
    if msg.pcTarget == 255 then
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
  function Audit.num(v)
    return (v == math.floor(v)) and string.format('%d', v) or (string.format('%.2f', v):gsub('0+$', ''))
  end
  function Audit.per100(n, rate)
    if Audit.noStats then return TEXTS.scrKmrNone end
    if n == nil then return '-' end
    return rate and string.format('%d - %.2f / 100 km', n, rate) or tostring(n)
  end
  Audit.allow = function(area) return true end
  function Audit.blank(text)
    local t = tostring(text or ''):gsub('[%c]', ''):gsub('\194\160', ''):gsub('\226\128[\139-\143]', '')
      :gsub('\226\129\160', ''):gsub('\239\187\191', '')
    return t:match('^%s*$') ~= nil
  end
  function Audit.add(src, text, window, area)
    if Audit.blank(text) then return end
    Audit.items[#Audit.items + 1] = { t = serverTimeMs(), src = src, text = tostring(text), area = area }
    if #Audit.items > MAX_ITEMS then table.remove(Audit.items, 1) end
    if window and (area == nil or area == 'rc') then
      showNotice(TEXTS.rcTitle, tostring(text), nil, SERVER_NOTICE_SECONDS)
    elseif window and Audit.allow(area) then
      Audit.window = { { src = src, text = tostring(text) } }
    end
    ac.log('race-control: audit ' .. src .. ': ' .. tostring(text))
    save()
  end
  function Audit.current()
    local w = Audit.window[1]
    if not w then return nil end
    if Audit.blank(w.text) then table.remove(Audit.window, 1) return Audit.current() end
    w.untilT = w.untilT or (state.ui.clock + config.screens.messageSeconds)
    if state.ui.clock >= w.untilT then
      table.remove(Audit.window, 1)
      return Audit.current()
    end
    return w
  end
  function Audit.kmrPointsReset()
    Audit.points = 0
    kmrSave()
    ac.log('race-control: KMR infraction limit reached: points back to 0')
  end
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
  function Audit.kmrStats(message)
    local low = tostring(message):lower()
    local c, cr = DICT.match(low, DICT.kmr.crashes)
    local i, ir = DICT.match(low, DICT.kmr.infractions)
    local function n(x) return tonumber((tostring(x or ''):gsub(',', '.'))) end
    if c then Audit.crashes, Audit.crashRate, Audit.noStats = tonumber(c), n(cr), false end
    if i then Audit.infractions, Audit.infractionRate = tonumber(i), n(ir) end
    local km = DICT.match(low, DICT.kmr.distance)
    if km then Audit.km = n(km) end
    if c or i then ac.log('race-control: KMR driving stats: ' .. message) end
    if not c and DICT.match(low, DICT.kmr.noStats) then
      Audit.noStats = true
      ac.log('race-control: KMR driving stats: none yet')
      return state.ui.clock < (Audit.askedUntil or 0)
    end
    local answer = low:find('crashes per 100km', 1, true) or low:find('batidas por 100km', 1, true)
    return (c ~= nil) and answer ~= nil and state.ui.clock < (Audit.askedUntil or 0)
  end
  local ASK_GAP = 8
  local askedT = -1e9
  Audit.askPending = false
  ac.onCarCollision(0, function() Audit.askPending = true end)
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
    queueCommand('kmr stats')
    queueCommand('kmr money')
  end
  local KMR_RESEND = 20
  Audit.others = {}
  local sentText, sentT = nil, -1e9
  local sendKmr = ac.OnlineEvent({
    ac.StructItem.key('amxracing.race-control.kmrstats'),
    kPoints = ac.StructItem.int16(), kRating = ac.StructItem.int32(), kCrashes = ac.StructItem.int16(),
    kCrashRate = ac.StructItem.int16(), kInfr = ac.StructItem.int16(), kInfrRate = ac.StructItem.int16(),
  }, function(sender, msg)
    if not sender or sender.index == 0 then return end
    local function v(x) x = tonumber(x) or -1; return x >= 0 and x or nil end
    Audit.others[sender.index] = { points = v(msg.kPoints), rating = tonumber(msg.kRating) ~= -2147483647
      and tonumber(msg.kRating) or nil, crashes = v(msg.kCrashes), noStats = tonumber(msg.kCrashes) == -2, crashRate = v(msg.kCrashRate) and v(msg.kCrashRate) / 100,
      infractions = v(msg.kInfr), infractionRate = v(msg.kInfrRate) and v(msg.kInfrRate) / 100, t = state.ui.clock }
  end, nil, nil, { processPostponed = true })
  function Audit.kmrOf(i)
    if i == 0 then
      return { points = Audit.points, rating = Audit.rating, crashes = Audit.crashes, crashRate = Audit.crashRate,
        infractions = Audit.infractions, infractionRate = Audit.infractionRate, noStats = Audit.noStats }
    end
    return Audit.others[i]
  end
  function Audit.kmrSend()
    if Audit.points == nil and Audit.rating == nil and Audit.crashes == nil and Audit.infractions == nil
      and not Audit.noStats then return end
    local function n(x, k) return x and math.floor(x * (k or 1) + 0.5) or -1 end
    local data = { kPoints = n(Audit.points), kRating = Audit.rating and math.floor(Audit.rating) or -2147483647,
      kCrashes = Audit.noStats and -2 or n(Audit.crashes), kCrashRate = n(Audit.crashRate, 100), kInfr = n(Audit.infractions),
      kInfrRate = n(Audit.infractionRate, 100) }
    local text = table.concat({ data.kPoints, data.kRating, data.kCrashes, data.kCrashRate, data.kInfr, data.kInfrRate }, '|')
    if text == sentText and state.ui.clock - sentT < KMR_RESEND then return end
    sentText, sentT = text, state.ui.clock
    OnlineQueue.push(sendKmr, data, nil)
  end
end
local Diag = { inputs = {}, acts = {}, last = nil,
  on = false }
do
  local WINDOW = 1.0
  local held = {}
  local ENGINE_ON, ENGINE_OFF, STABLE = 300, 50, 2.0
  local engineState, enginePending, engineSince = nil, nil, 0
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
  local function read(car)
    return {
      headlights = car.headlightsActive and 'on' or 'off',
      lowBeams = car.lowBeams and 'on' or 'off',
      hazard = car.hazardLights and 'on' or 'off',
      limiter = car.manualPitsSpeedLimiterEnabled and 'on' or 'off',
      engine = engineState or 'off',
      reverse = CarRead.num(car.gear) == -1 and 'R' or 'not R',
      camera = tostring(sim.cameraMode) .. ((ac.CameraMode and sim.cameraMode == ac.CameraMode.Car) and ('/' .. tostring(sim.carCameraIndex)) or ''),
    }
  end
  local LABEL = { headlights = 'Headlights', lowBeams = 'Low beams', hazard = 'Hazard lights', limiter = 'Pit limiter',
    engine = 'Engine', reverse = 'Gear', camera = 'Camera' }
  local ORDER = { 'headlights', 'lowBeams', 'hazard', 'limiter', 'engine', 'reverse', 'camera' }
  function Diag.update(car)
    if not Diag.on then return end
    local clock = state.ui.clock
    local now = readInputs()
    for name in pairs(now) do
      if not held[name] then Diag.inputs[#Diag.inputs + 1] = { t = clock, name = name } end
    end
    held = now
    while Diag.inputs[1] and clock - Diag.inputs[1].t > WINDOW do table.remove(Diag.inputs, 1) end
    local rpm = CarRead.num(car.rpm)
    local raw = rpm > ENGINE_ON and 'running' or (rpm < ENGINE_OFF and 'off' or (enginePending or engineState or 'off'))
    if engineState == nil then engineState = raw end
    if raw ~= enginePending then enginePending, engineSince = raw, clock end
    if raw ~= engineState and clock - engineSince >= STABLE then engineState = raw end
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
        local text = string.format('%s %s -> %s - inputs: %s - Racing Control: %s', LABEL[k], before[k], cur[k],
          #ins > 0 and table.concat(ins, ', ') or 'none', #acts > 0 and table.concat(acts, ', ') or 'none')
        Audit.add('DIAG', text, true, 'diag')
        rcLog(TEXTS.rc.diag, text)
      end
    end
  end
end
local Start = { phase = nil, maxKmh = nil, minKmh = nil, farM = nil, slowFarM = nil, slowKmh = nil, locked = {},
  goUntil = 0, sent = 'off', sentT = -1e9, GREEN_SPLINE = 0.95 }
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
    rcLog(TEXTS.rc.rollingStart, p .. ' - ' .. tostring(message))
  end
  function Start.chat(message)
    local low = message:lower()
    local S = DICT.start
    if hasAny(low, DICT.kmr.penalty) then return false end
    local taken = true
    if Start.phase == 'go' and hasAny(low, S.go) then
      Audit.add('KMR', message, true, 'rc')
      rcLog(TEXTS.rc.rollingStart, 'go (KMR) - ' .. tostring(message))
      return true
    end
    if hasAny(low, S.rules) then phaseTo('rules', message)
    elseif DICT.match(low, S.speed) then
      local mx, mn = DICT.match(low, S.speed)
      Start.maxKmh, Start.minKmh = tonumber(mx), tonumber(mn)
    elseif DICT.match(low, S.slowFar) then
      local d, v = DICT.match(low, S.slowFar)
      Start.slowFarM, Start.slowKmh = tonumber(d), tonumber(v)
    elseif DICT.match(low, S.far) then Start.farM = tonumber((DICT.match(low, S.far)))
    elseif hasAny(low, S.noOvertake) then
    elseif hasAny(low, S.formation) then phaseTo('formation', message)
    elseif hasAny(low, S.release) then phaseTo('release', message)
    elseif hasAny(low, S.go) then phaseTo('go', message)
    elseif hasAny(low, S.giveBack) or hasAny(low, S.warning) then
    else taken = false end
    if taken then Audit.add('KMR', message, true, 'rc') end
    return taken
  end
  local function gapM(a, b)
    return ((CarRead.num(b.splinePosition) - CarRead.num(a.splinePosition)) % 1) * (tonumber(sim.trackLengthM) or 0)
  end
  local function tag(i) return string.format('#%s', tostring(ac.getDriverNumber(i) or i)) end
  local function byPlace()
    local out = {}
    for i, p in pairs(Start.locked) do out[p] = i end
    return out
  end
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
    if (Start.phase == 'formation' or Start.phase == 'release') and next(Start.locked) == nil then
      local list = {}
      for i = 0, (sim.carsCount or 1) - 1 do
        local c = ac.getCar(i)
        if c and c.isConnected and CarRead.num(c.racePosition) > 0 and not CarRead.isStaff(i) then list[#list + 1] = { i = i, p = CarRead.num(c.racePosition) } end
      end
      table.sort(list, function(a, b) return a.p < b.p end)
      for k, x in ipairs(list) do Start.locked[x.i] = k end
    end
    if Start.phase == 'release' then
      local lead = byPlace()[1]
      if not lead then
        for i = 0, (sim.carsCount or 1) - 1 do
          local c = ac.getCar(i)
          if c and (i == 0 or c.isConnected) and CarRead.num(c.racePosition) == 1 and not CarRead.isStaff(i) then lead = i end
        end
      end
      local lc = lead and ac.getCar(lead)
      if lc and (lead == 0 or lc.isConnected) and not lc.isInPitlane and CarRead.num(lc.splinePosition) >= Start.GREEN_SPLINE then
        phaseTo('go', string.format('the leader at %.2f of the lap', CarRead.num(lc.splinePosition)))
      end
    end
    if Start.phase == 'go' and state.ui.clock >= Start.goUntil then Start.phase = nil end
    local ev = (Start.phase == 'rules' or Start.phase == 'formation' or Start.phase == 'release') and 'hold:rolling'
      or (Start.phase == 'go' and 'go' or 'off')
    if ev ~= Start.sent or (ev ~= 'off' and state.ui.clock - Start.sentT >= 2) then
      Start.sent, Start.sentT = ev, state.ui.clock
      ac.broadcastSharedEvent(TRACK_EVENT, ev)
    end
  end
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
local function fromServer(sender)
  if sender == nil or sender < 0 then return true end
  local c = ac.getCar(sender)
  return not c or not c.isConnected
end
do
  local LOG_ONLY = { 'SERVER', 'ABS', 'TC', 'TC2', 'Engine Map', 'Pit limiter' }
  if ac.onMessage then
    ac.onMessage(function(title, description)
      if not ServerGuard.ok() then return end
      local t, d = tostring(title or ''), tostring(description or '')
      local text = d ~= '' and (t ~= '' and (t .. ' - ' .. d) or d) or t
      if Audit.blank(text) then return end
      if text:match('^%s*SERVER%s*:') then
        if not Audit.blank((text:gsub('^%s*SERVER%s*:', ''))) then
          ac.log('race-control: game message (log only): ' .. text)
        end
        return
      end
      for _, k in ipairs(LOG_ONLY) do
        if t == k then
          ac.log('race-control: game message (log only): ' .. text)
          return
        end
      end
      Audit.add('GAME', text, true, DICT.area(text:lower()) or 'server')
    end)
  end
end
ac.onChatMessage(function(message, senderCarIndex)
  if not ServerGuard.ok() then return end
  if type(message) ~= 'string' then return false end
  local server = fromServer(senderCarIndex)
  if server and Audit.blank(message) then return true end
  local low = message:lower()
  if server then Connection.chat(message) end
  if server and hasAny(low, DICT.kmr.lapInvalid) then
    if not state.lapCut then ac.log('race-control: lap invalidated by the KMR (track limits): cut lap') end
    state.lapCut = true
  end
  if message:sub(1, #TEXTS.rcPrefix) ~= TEXTS.rcPrefix and (hasAny(low, DICT.kmr.driveThrough)
      or hasAny(low, DICT.kmr.penalty)) then
    rcLog(TEXTS.rc.chatSeen, string.format('sender %s - %s', tostring(senderCarIndex), Lang.letters.head(message, 90)))
  end
  if message:sub(1, #TEXTS.rcPrefix) == TEXTS.rcPrefix then
    local car = config.isDirector and message:find(TEXTS.editedFile, 1, true)
      and message:match('car (%d+) %- ban pending')
    if car then
      queueCommand('/ban ' .. car)
      ac.log('race-control: ban sent for car ' .. car .. ' (edited file)')
    end
    return true
  end
  if message:lower():match('^%s*kmr%s+stats%s*$') or message:lower():match('^%s*kmr%s+money%s*$')
      or (server and message:lower():find('is not recognized as a server command', 1, true)
        and message:lower():find('kmr', 1, true)) then
    return true
  end
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
    local t, n = state.chat.stamp()
    state.rcCommands[#state.rcCommands + 1] = { text = command, t = t, n = n }
    return true
  end
  local myName = tostring(ac.getDriverName(0) or '')
  if server and myName ~= '' and message:find(myName, 1, true) and hasAny(low, DICT.kmr.dtCancelled) then
    local t, n = state.chat.stamp()
    state.kmrMessages[#state.kmrMessages + 1] = { text = message, sender = senderCarIndex, cancel = true, t = t, n = n }
    Audit.add('KMR', message, true, 'rc')
    return true
  end
  if (server or senderCarIndex == 0) and classifyServerMessage(message) == 'DT' then
    local prefix = tostring(ac.getDriverName(0) or '') .. ':'
    local text = message
    if message:sub(1, #prefix) == prefix then text = message:sub(#prefix + 1):gsub('^%s+', '') end
    local nextRace = hasAny(low, DICT.kmr.nextRace)
    if not nextRace then showNotice(TEXTS.kmrTitle, text, nil, SERVER_NOTICE_SECONDS) end
    local t, n = state.chat.stamp()
    state.kmrMessages[#state.kmrMessages + 1] = { text = text, sender = senderCarIndex, t = t, n = n }
    if not nextRace then Audit.add('KMR', text) end
    return true
  end
  if server and onDriverSwapMessage(message) then
    Audit.add('ACSM', message)
    return true
  end
  if server or senderCarIndex == 0 then
    if Audit.kmrStats(message) then return true end
    if Audit.kmrMoneyAnswer(message) and Audit.kmrRating(message) then return true end
    local points = Audit.kmrPoints(message)
    local rating = Audit.kmrRating(message)
    if points or rating then
      Audit.add('KMR', message, true, DICT.area(low) == 'damage' and 'damage' or 'points')
      return true
    end
  end
  local name = tostring(ac.getDriverName(0) or '')
  local mine = name ~= '' and message:find(name, 1, true) ~= nil
  if server and mine and hasAny(low, DICT.kmr.directorPenalty) then
    Audit.add('KMR', message, true, 'points')
    return true
  end
  if server and Start.chat(message) then return true end
  if server then
    local kind = classifyServerMessage(message)
    if kind then
      if DICT.code80Kinds[kind] then
        if not state.code80 then ac.log('race-control: CODE-80 start (' .. kind .. ')') end
        local redDown = state.redFlag ~= nil and not state.restart
        if redDown then
          state.redFlag = nil
          state.postRed = true
          ac.log('race-control: red flag off: restart under the ' .. kind)
          rcLog(TEXTS.rc.redOff, 'restart under the ' .. kind)
        end
        if state.code80 ~= kind or redDown then
          state.code80 = kind
          TrackList.changed()
        end
      elseif kind == 'GREEN FLAG' and state.code80 then
        state.code80 = nil
        state.code80Ended = true
        state.postRed = nil
        TrackList.changed()
        ac.log('race-control: CODE-80 end')
      end
      showNotice(TEXTS.rcTitle .. '  ' .. kind, message, nil, SERVER_NOTICE_SECONDS, kind)
      Audit.add('KMR', message)
      return true
    end
    local fromDirection = message:match('^%s*%b()') ~= nil
    local area = (not fromDirection) and DICT.area(low) or nil
    if area == 'director' then area = mine and 'rc' or 'others' end
    if low:find('logged in as kissmyrank admin', 1, true) or low:find('logado como kissmyrank admin', 1, true) then
      state.kmrAdmin = true
    end
    if state.directionAnswer and config.canCommand then state.directionAnswer(message) end
    if not area and hasAny(low, DICT.kmr.driveThrough) then area = 'others' end
    if area then
      Audit.add('KMR', message, true, area)
    else
      ac.log(string.format('race-control: server message of no area (sender %s, %s): %s', tostring(senderCarIndex),
        fromDirection and 'race direction' or 'server', message))
      Audit.add('SERVER', message, true, fromDirection and 'rc' or 'server')
    end
    return true
  end
  if Audit.allow('chat') and senderCarIndex and senderCarIndex > 0 and not Audit.blank(message) then
    Audit.window = { { src = tostring(ac.getDriverName(senderCarIndex) or 'CHAT'), text = message } }
  end
  return false
end)
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
local PitStops
local Rules = {}
function Rules.itemEncode(it)
  return string.format('%s,%s,%d,%d,%d,%d,%d,%d', it.cat, it.kind, it.laps, it.givenLap, it.expireLap, it.seq,
    it.dt0OnTrack and 1 or 0, it.id or it.seq)
end
function Rules.itemDecode(text, shift)
  local f = {}
  for v in tostring(text or ''):gmatch('[^,]+') do f[#f + 1] = v end
  if #f < 7 or not (f[1]:match('^%w+$') and tonumber(f[3]) and tonumber(f[4]) and tonumber(f[5]) and tonumber(f[6])) then
    return nil
  end
  shift = shift or 0
  return { cat = f[1], kind = f[2], laps = tonumber(f[3]), givenLap = tonumber(f[4]) + shift,
    expireLap = tonumber(f[5]) + shift, seq = tonumber(f[6]), dt0OnTrack = f[7] == '1',
    id = tonumber(f[8]) or tonumber(f[6]) }
end
function Rules.lapShift(lap)
  local lapNow = ac.getCar(0).lapCount
  lap = tonumber(lap) or lapNow
  return lapNow < lap and lapNow - lap or 0
end
local function listSave()
  local l = state.list
  local parts = {}
  for _, it in ipairs(l.items) do parts[#parts + 1] = Rules.itemEncode(it) end
  local w = l.wrong
  Record.save('penalties', l.seq, string.format('%d|0|%d|%d|%d|%d|%d|%d|%d|%s', l.seq, l.curLap,
    l.owner or 0, l.dsq, l.dsqStage, math.floor(l.dsqUntil), w and w.driver or 0, w and math.floor(w.since) or 0,
    table.concat(parts, ';')))
end
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
  local shift = Rules.lapShift(lapPart)
  for text in itemsPart:gmatch('[^;]+') do
    local it = Rules.itemDecode(text, shift)
    if it then l.items[#l.items + 1] = it end
  end
  if shift ~= 0 then
    ac.log(string.format('race-control: penalty list moved %d laps (new connection)', shift))
  end
end
local function listLoad()
  local data, _, source = Record.load('penalties')
  listApply(data, source)
end
local function listSort()
  table.sort(state.list.items, function(a, b)
    if a.laps ~= b.laps then return a.laps < b.laps end
    return a.seq < b.seq
  end)
end
local function sgItem()
  for _, it in ipairs(state.list.items) do
    if it.kind:sub(1, 2) == 'SG' then return it end
  end
  return nil
end
local function sgCount(it) return tonumber(it.cat:match('^SG(%d+)$')) or 0 end
local function sgKmrSuffix(it) return it.kind:match('(x[%dx]+)$') or '' end
local function sgSeconds(it) return sgCount(it) * config.sgSecondsPerDT + (tonumber(it.kind:match('e(%d+)')) or 0) end
local function reasonLog(cat)
  local base = TEXTS.kmrReasons[cat]
  return base and (base .. ' (issued by KMR)') or tostring(TEXTS.reason[cat] or cat)
end
local function listAdd(cat, laps)
  local l = state.list
  if Rules.dsqOn() then
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
    rcLog(string.format(TEXTS.rc.sgSeconds, sgSeconds(sg)), 'includes ' .. reasonLog(cat))
    if sgSeconds(sg) > config.sgMaxDT * config.sgSecondsPerDT then Rules.sgOverLimit(n) end
    return sg
  end
  l.seq = l.seq + 1
  if #l.items == 0 or not l.owner then l.owner = nameCode(ac.getDriverName(0)) end
  local item = { cat = cat, kind = 'DT', laps = laps, givenLap = l.curLap, expireLap = l.curLap + laps, seq = l.seq,
    dt0OnTrack = false, id = l.seq }
  l.items[#l.items + 1] = item
  return item
end
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
function Rules.zero()
  local l = state.list
  l.items = {}
  l.endOfLap = {}
  l.owner = nil
  l.wrong = nil
  state.slowdowns = {}
  listSave()
end
local function clearGamePenalty()
  physics.setCarPenalty(MANDATORY_PITS, 0)
end
local function carDsq(kind, reason, mode, detail)
  local l = state.list
  l.dsq = kind or 1
  l.dsqStage = mode == 'tow' and 2 or 0
  l.dsqUntil = mode == 'tow' and serverTimeMs() + config.dsqTowSeconds * 1000 or 0
  l.dsqLap = ac.getCar(0).lapCount
  l.dsqReason = reason
  l.seq = l.seq + 1
  if l.dsq == 2 then state.pitDsqActive = true else state.dtDsqActive = true end
  local voided = {}
  for _, it in ipairs(l.items) do voided[#voided + 1] = reasonLog(it.cat) end
  Rules.zero()
  local why = detail and (reason .. ' - ' .. detail) or reason
  if #voided > 0 then why = why .. ' - ' .. string.format(TEXTS.dsqVoided, table.concat(voided, ', ')) end
  rcLog(TEXTS.rc.dsq, why)
end
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
local DSQ_LOCK_SECONDS = 86400
local function dsqGameFlag(why, rcReason, inGame)
  local l = state.list
  if not inGame then physics.setCarPenalty(BLACK_FLAG) end
  physics.lockUserControlsFor(DSQ_LOCK_SECONDS)
  l.dsqStage = 1
  listSave()
  ac.log('race-control: DSQ black flag in the game, controls locked (' .. why .. ')')
  if rcReason then rcLog(TEXTS.rc.dsq, rcReason) end
end
function Rules.dsqOn()
  return state.dtDsqActive or state.pitDsqActive
end
function Rules.raceEndTime(car)
  if Rules.endTimeDone or sim.raceSessionType ~= ac.SessionType.Race or not car.isRaceFinished then return end
  if Rules.dsqOn() then
    Rules.endTimeDone = true
    return
  end
  local l = state.list
  if #l.items == 0 then return end
  Rules.endTimeDone = true
  local total, what = 0, {}
  for _, it in ipairs(l.items) do
    local sgItemHere = it.kind:sub(1, 2) == 'SG'
    local seconds = config.sgUnservedDT + (sgItemHere and sgSeconds(it) or 0)
    local why = sgItemHere and string.format(TEXTS.rc.sgSeconds, sgSeconds(it)) or reasonLog(it.cat)
    total = total + seconds
    what[#what + 1] = why
    rcLog(TEXTS.rc.timePenalty, string.format(TEXTS.timeNotServedLog, seconds, why))
  end
  ac.log(string.format('race-control: race over with %d penalties pending: %d s added to the final time',
    #l.items, total))
  showNotice(TEXTS.timeNotServedTitle, string.format(TEXTS.timeNotServed, total, table.concat(what, ', ')), nil,
    config.screens.serverNoticeSeconds)
  Rules.zero()
end
function Rules.practiceClear(car)
  if sim.raceSessionType ~= ac.SessionType.Practice or not CarRead.parked(car) then return nil end
  local l = state.list
  local dsqActive = Rules.dsqOn()
  if dsqActive then
    if (config.tow[ac.SessionType.Practice].clearDsq or 0) ~= 1 then return nil end
    carDsqClear('practice, car at its pit place')
    Rules.zero()
    l.invalidLap = nil
    rcLog(TEXTS.rc.pit, 'Practice - disqualification cleared at the pit place')
    showNotice(TEXTS.rcTitle, TEXTS.practiceDsqCleared)
    return 'dsq'
  end
  if #l.items == 0 and not next(state.slowdowns) and #l.endOfLap == 0 then return nil end
  local cleared = {}
  for _, it in ipairs(l.items) do cleared[#cleared + 1] = reasonLog(it.cat) end
  Rules.zero()
  l.invalidLap = nil
  ac.log('race-control: practice, car at its pit place: penalties cleared')
  rcLog(TEXTS.rc.pit, #cleared > 0 and string.format(TEXTS.practiceClearedWhat, table.concat(cleared, ', '))
    or 'Practice - pending penalties cleared at the pit place')
  showNotice(TEXTS.rcTitle, TEXTS.practiceCleared)
  return 'penalties'
end
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
local function applyHold(long)
  local seconds = long and config.holdLong or config.holdShort
  local reason = long and TEXTS.holdTwoDTLong or TEXTS.holdTwoDT
  local held = {}
  for _, it in ipairs(state.list.items) do held[#held + 1] = reasonLog(it.cat) end
  startHold(seconds, reason, long and 'dt2long' or 'dt2')
  Rules.zero()
  ac.log(string.format('race-control: hold %d s', seconds))
  rcLog(string.format(TEXTS.rc.hold, seconds),
    #held > 0 and (reason .. ' - ' .. string.format(TEXTS.holdIncludes, table.concat(held, ', '))) or reason)
end
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
    givenLap = l.curLap, expireLap = l.curLap + laps, seq = l.seq, dt0OnTrack = false, id = l.seq } }
  local seconds = n * config.sgSecondsPerDT + extra
  ac.log(string.format('race-control: stop & go %d s (%d DT)', seconds, n))
  rcLog(string.format(TEXTS.rc.sgSeconds, seconds), 'includes ' .. table.concat(reasons, ', '))
  if seconds > config.sgMaxDT * config.sgSecondsPerDT then Rules.sgOverLimit(n) end
  listSave()
end
function Rules.sgAddSeconds(seconds, why)
  local l = state.list
  if Rules.dsqOn() then
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
    rcLog(string.format(TEXTS.rc.sgSeconds, sgSeconds(sg)), 'includes ' .. why)
    if sgSeconds(sg) > config.sgMaxDT * config.sgSecondsPerDT then Rules.sgOverLimit(sgCount(sg)) end
    listSave()
  else
    Rules.sgForm(seconds, why)
  end
  sg = sgItem()
  if sg then showNotice(TEXTS.rcTitle, string.format(TEXTS.sgFlagGiven, sgSeconds(sg), why), sg) end
end
function Rules.sgOverLimit(n)
  ac.log(string.format('race-control: DSQ, stop & go limit exceeded (%d DT)', n))
  carDsq(1, string.format(TEXTS.sgLimit, config.sgMaxDT))
end
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
function Rules.slowdownMidLap(cat)
  listAdd(cat, 0)
  Rules.finalize()
end
function Rules.slowdownEndOfLap(cat)
  local l = state.list
  l.endOfLap[#l.endOfLap + 1] = cat
end
function Rules.line(viaPit, g, lapCount)
  local l = state.list
  if g.t == BLACK_FLAG then
    Rules.zero()
    return
  end
  local before = listDump()
  l.curLap = lapCount
  local frozen = (state.code80 ~= nil and config.code80Freeze) or state.redFlag ~= nil or state.restart ~= nil
  if viaPit then
    if state.code80 and l.items[1] then
      ac.log('race-control: pit pass during CODE-80, nothing paid')
    elseif state.redFlag and not state.redCommitted and l.items[1] then
      ac.log('race-control: pit pass with the red flag, nothing paid')
    elseif l.wrong and l.items[1] then
      ac.log('race-control: pit pass by another driver, nothing paid')
    elseif PitStops.pass and PitStops.pass.stopped and l.items[1] and l.items[1].kind:sub(1, 2) ~= 'SG' then
      ac.log('race-control: pit pass with a stop at the pit place: the drive-through is not served')
    elseif not l.jumped then
      local head = l.items[1]
      if head and head.kind:sub(1, 2) == 'SG' then
        if not frozen and head.expireLap <= l.curLap - 1 and applyExpiredDSQ({ head }, true) then return end
      elseif head then
        listRemove(head)
        state.pitPaid = head
        PitStops.notePaid(head.cat .. ' DT')
        rcLog(TEXTS.rc.dtServed, string.format(TEXTS.dtServedWhy, reasonLog(head.cat), math.max(head.laps, 0)))
      end
    end
  elseif not frozen then
    local completedLap = l.curLap - 1
    local expired = {}
    for _, it in ipairs(l.items) do
      if it.expireLap <= completedLap then expired[#expired + 1] = it end
    end
    if #expired > 0 and applyExpiredDSQ(expired, false) then return end
  end
  for _, it in ipairs(l.items) do
    if frozen then
      it.expireLap = it.expireLap + 1
    else
      it.laps = it.laps - 1
      if it.cat == 'PSE' and it.laps == 0 and not viaPit then it.dt0OnTrack = true end
    end
  end
  for _, cat in ipairs(l.endOfLap) do
    listAdd(cat, 0)
  end
  l.endOfLap = {}
  ac.log(string.format('race-control: line %s table before=%s after=%s', viaPit and 'pit' or 'track', before,
    listDump()))
  Rules.finalize()
end
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
function Rules.keepDsq(source)
  local l = state.list
  if l.dsq == 0 or Rules.dsqOn() then return end
  if l.dsq == 2 then state.pitDsqActive = true else state.dtDsqActive = true end
  if l.dsqStage == 1 then dsqGameFlag('kept from the car record') end
  ac.log('race-control: DSQ kept from the car record (' .. source .. ')')
end
function Rules.invalidLaps(car)
  local l = state.list
  if sim.raceSessionType == ac.SessionType.Race or #l.items == 0 or l.invalidLap == car.lapCount then return end
  l.invalidLap = car.lapCount
  physics.setCarFuel(0, car.fuel)
  ac.log('race-control: lap invalid (penalty not paid, practice or qualifying)')
end
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
do
  Rules.catalog = {}
  for cat in pairs(TEXTS.reason) do
    if not TEXTS.kmrReasons[cat] then Rules.catalog[cat] = { kind = 'DT', rc = 'dt' } end
  end
  function Rules.penalty(cat, laps, detail)
    local entry = Rules.catalog[cat]
    if not entry then
      ac.log('race-control: penalty of a category out of the catalogue: ' .. tostring(cat))
      return nil
    end
    local item = listAdd(cat, laps)
    if not item then return nil end
    Rules.finalize()
    local reason = TEXTS.reason[cat]
    rcLog(TEXTS.rc[entry.rc], detail and (reason .. ' - ' .. detail) or reason)
    showNotice(TEXTS.rcTitle, reason)
    return item
  end
end
local COLLISION_DAMAGE_WINDOW = 1.5
ac.onCarCollision(0, function()
  state.tow.collisionUntil = state.ui.clock + COLLISION_DAMAGE_WINDOW
end)
local function readDamage(car)
  local body, suspension = 0, 0
  for i = 0, 3 do body = body + math.max(tonumber(car.damage[i]) or 0, 0) end
  for i = 0, 3 do suspension = suspension + math.max(tonumber(car.suspensionDamage[i]) or 0, 0) end
  return {
    engine = math.min(math.max(1 - (tonumber(car.engineLifeLeft) or 1000) / 1000, 0), 1),
    gearbox = math.max(tonumber(car.gearboxDamage) or 0, 0),
    suspension = suspension,
    body = body,
  }
end
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
function PitRecord.endQualifying(reason)
  local left = CarRead.num(sim.sessionTimeLeft) / 1000
  state.tow.repairDone = true
  state.tow.damage = nil
  startHold(left > 0 and math.ceil(left) + 5 or 86400, string.format(TEXTS.qualiEndHold, reason), 'quali/' .. reason)
  ac.log('race-control: qualifying ended - ' .. reason)
  rcLog(TEXTS.rc.qualiEnd, reason)
  showNotice(TEXTS.rcTitle, string.format(TEXTS.qualiEndNotice, reason))
end
local function applyTowHold(tow, damage, reason)
  local repair = repairSeconds(damage)
  local seconds = tow + repair
  state.tow.repairDone = true
  state.tow.damage = nil
  if seconds <= 0 then return end
  local text = tow > 0 and string.format(TEXTS.holdTowRepair, mmss(tow), mmss(repair))
    or string.format(TEXTS.holdRepair, mmss(repair))
  startHold(seconds, text, tow > 0 and string.format('tow/%d/%d', tow, repair) or string.format('repair/%d', repair))
  local d = damage or { powertrain = 0, suspension = 0, body = 0 }
  ac.log(string.format('race-control: tow hold %d s (tow %d, repair %d; collision damage: powertrain %.3f'
    .. ' suspension %.3f body %.1f km/h)', seconds, tow, repair, d.powertrain, d.suspension, d.body))
  rcLog(string.format(TEXTS.rc.hold, seconds), string.format('%s - tow %d s + repair %d s', reason, tow, repair))
end
local TyreUse = {}
do
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
local CarState = {
  seq = 0,
  restoring = false,
  startT = 0,
  pending = nil,
  appliedSeq = -1,
  prevParked = false,
  damageSig = nil,
  dirtyT = nil,
  lastBody = nil,
  orig = {},
  peak = {},
  held = {},
  search = nil,
  suspKmh = {},
  suspRaw = {},
}
do
  local CAR_RESTORE_WINDOW = 30
  local CAR_DAMAGE_SETTLE = 2
  local SUSP_MAX_ANGLE = 90
  local SUSP_TOLERANCE = 0.1
  local SUSP_FIRST_KMH = 50
  local SUSP_MAX_KMH = 3200
  local SUSP_STEPS = 16
  local SUSP_WAIT_FRAMES = 2
  local num = CarRead.num
  local function list(text)
    local out = {}
    for v in tostring(text or ''):gmatch('[^,]+') do out[#out + 1] = v end
    return out
  end
  local function suspPercent(car, i, orig)
    local w = car.wheels and car.wheels[i]
    local o = orig or CarState.orig[i]
    if not w or not o then return nil end
    local dev = math.max(math.abs(num(w.toeIn) - o.toe), math.abs(num(w.camber) - o.camber))
    return math.min(dev / SUSP_MAX_ANGLE, 1) * 100
  end
  function CarState.deviation(car, i)
    local w = car.wheels and car.wheels[i]
    local o = CarState.orig[i]
    if not w or not o then return nil end
    if num(car.suspensionDamage[i]) <= 0 then return 0, 0 end
    local pk = CarState.peak[i] or { toe = 0, camber = 0 }
    return pk.toe, pk.camber, pk.slip or 0
  end
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
  state.onJumped[#state.onJumped + 1] = function()
    if CarState.restoring or not CarState.lastBody then return end
    saveBody(CarState.lastBody)
    ac.log('race-control: car state saved before the teleport')
  end
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
    if r.repairLaps and r.repairLaps >= 0 then state.repair.lapsLeft = r.repairLaps end
    if r.beyondSince and r.beyondSince >= 0 then state.repair.beyondSince = r.beyondSince end
    state.tow.lastRead = nil
    CarState.appliedSeq = p.seq
    CarState.seq = math.max(CarState.seq, p.seq)
    ac.log(string.format('race-control: car state put back (%s, seq %d): %s', p.source, p.seq, p.body))
    if (r.gearbox or 0) > 0 then ac.log('race-control: car state not put back (no game function for it): gearbox') end
  end
  function CarState.ready()
    return not CarState.restoring or (CarState.pending ~= nil and CarState.pending.seq == CarState.appliedSeq
      and not CarState.search)
  end
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
  RecordSync.restorers.car = function(body, seq)
    if not CarState.restoring then return end
    if CarState.pending and seq < CarState.pending.seq then return end
    CarState.pending = { body = body, seq = seq, source = 'other drivers' }
    CarState.seq = math.max(CarState.seq, seq)
  end
  function CarState.update(car, lineFrame)
    local parked = CarRead.parked(car)
    for i = 0, 3 do
      local w = car.wheels and car.wheels[i]
      local searching = CarState.search and CarState.search[i]
      if w and num(car.suspensionDamage[i]) == 0 and not searching then
        CarState.orig[i] = { toe = num(w.toeIn), camber = num(w.camber) }
        CarState.peak[i] = nil
        CarState.held[i] = nil
      elseif w and CarState.orig[i] and not searching then
        local o = CarState.orig[i]
        local now = state.ui.clock
        local list = CarState.held[i] or {}
        CarState.held[i] = list
        list[#list + 1] = { t = now, toe = math.abs(num(w.toeIn) - o.toe), slip = math.abs(num(w.slipAngle)), camber = math.abs(num(w.camber) - o.camber) }
        local settle = config.damage.settleSeconds
        while #list > 1 and now - list[2].t >= settle do table.remove(list, 1) end
        if now - list[1].t >= settle then
          local toe, camber = math.huge, math.huge
          local slip = math.huge
          for _, v in ipairs(list) do toe, slip, camber = math.min(toe, v.toe), math.min(slip, v.slip or 0), math.min(camber, v.camber) end
          local pk = CarState.peak[i] or { toe = 0, camber = 0 }
          CarState.peak[i] = { toe = math.max(pk.toe, toe), slip = math.max(pk.slip or 0, slip), camber = math.max(pk.camber, camber) }
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
    local sig = damageSig(car)
    if sig ~= CarState.damageSig then
      CarState.damageSig = sig
      CarState.dirtyT = state.ui.clock
    end
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
local DamageClass = {}
do
  local num = CarRead.num
  local function wheelMissing(car, i) return false end
  local function classify(car)
    local worst = { class = 'normal' }
    local function consider(class, text, detail)
      local rank = { normal = 0, repair = 1, beyond = 2 }
      if rank[class] > rank[worst.class] then worst = { class = class, text = text, detail = detail } end
    end
    for i = 0, 3 do
      local toe, camber, slip = CarState.deviation(car, i)
      if toe then
        local what = 'toe'
        if (slip or 0) > toe then what, toe = 'slip', slip end
        local dev, bent, broken = toe, config.damage.toeBent, config.damage.toeBroken
        if camber / config.damage.camberBent > toe / config.damage.toeBent then
          what, dev, bent, broken = 'camber', camber, config.damage.camberBent, config.damage.camberBroken
        end
        local detail = string.format(TEXTS.damageAngle, what, dev)
        if dev > broken then
          consider('beyond', string.format(TEXTS.damageSuspension, TEXTS.wheelNames[i]), detail)
        elseif dev > bent then
          consider('repair', string.format(TEXTS.damageBent, TEXTS.wheelNames[i]), detail)
        end
      end
    end
    for i = 0, 3 do
      local d = num(car.damage[i])
      if d > config.damage.bodyRepair then
        consider('repair', string.format(TEXTS.damageBody, TEXTS.bodySides[i], d),
          string.format(TEXTS.damageBodyLimit, config.damage.bodyRepair))
      end
    end
    for i = 0, 3 do
      if wheelMissing(car, i) then
        consider('beyond', string.format(TEXTS.damageWheel, TEXTS.wheelNames[i]), '')
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
    local powertrain = math.max((1000 - num(car.engineLifeLeft)) / 10, num(car.gearboxDamage) * 100)
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
      consider('repair', string.format(TEXTS.damageTyre, TEXTS.wheelNames[first]),
        string.format(TEXTS.damageTyresAllowed, blown, config.damage.maxPunctured))
    end
    return worst
  end
  function DamageClass.reset()
    local r = state.repair
    if r.lapsLeft then r.lapsLeft = config.damage.repairLaps end
    r.beyondSince = nil
  end
  function DamageClass.update(car, lineFrame)
    local r = state.repair
    if Rules.dsqOn() then
      r.class = 'normal'
      return
    end
    if CarState.restoring then return end
    local c = classify(car)
    if r.waived then
      if c.class ~= 'normal' then
        r.class = 'normal'
        return
      end
      r.waived = nil
    end
    if lineFrame and r.lapsLeft then
      r.lapsLeft = r.lapsLeft - 1
      if r.lapsLeft <= 0 and c.class ~= 'normal' then
        r.lapsLeft = nil
        r.class = 'normal'
        carDsq(1, TEXTS.dsqWhy.repairNotDone, nil, r.text)
        ac.log('race-control: DSQ, mandatory repair not done')
        return
      end
    end
    if c.class == 'normal' then
      if r.lapsLeft then
        ac.log('race-control: mandatory repair done')
        rcLog(TEXTS.rc.repairDone, tostring(r.text))
      end
      r.lapsLeft = nil
    elseif c.class == 'repair' and not r.lapsLeft then
      r.lapsLeft = config.damage.repairLaps
      ac.log(string.format('race-control: repair required (%s, %s), %d laps', c.text, c.detail, r.lapsLeft))
      rcLog(TEXTS.rc.repairReq, string.format('%s - %s - %d laps', c.text, c.detail, r.lapsLeft))
    end
    if c.class == 'beyond' and r.class ~= 'beyond' then
      ac.log(string.format('race-control: damage beyond the safety limit (%s, %s)', c.text, c.detail))
      rcLog(TEXTS.rc.damageBeyond, string.format('%s - %s', c.text, c.detail))
    end
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
PitStops = {
  passInWindow = false,
  passInStopWindow = false,
  wasInPitlane = nil,
  pass = nil,
  line = 0,
  otherInPitlane = {},
  endChecked = false,
  lastIsInPit = nil,
  stopLogged = false,
  settleUntil = 0,
}
PitStops.SETTLE_SECONDS = 5
do
  local function raceTime(ms)
    local s = math.max(math.floor((ms or 0) / 1000), 0)
    return string.format('%d:%02d:%02d', math.floor(s / 3600), math.floor(s / 60) % 60, s % 60)
  end
  local function raceFlag() return state.code80 or 'green' end
  local function driverFlag()
    local f = sim.raceFlagType
    if f == ac.FlagType.Caution then return 'yellow' end
    if f == ac.FlagType.FasterCar then return 'blue' end
    return 'none'
  end
  local function windowOf(startMin, endMin)
    if sim.raceSessionType ~= ac.SessionType.Race then return nil end
    local s, e = (startMin or 0) * 60000, (endMin or 0) * 60000
    if s <= 0 or e <= s then return nil end
    return s, e
  end
  function PitStops.window() return windowOf(config.swapWindowStart, config.swapWindowEnd) end
  function PitStops.stopWindow() return windowOf(config.pitWindowStart, config.pitWindowEnd) end
  function PitStops.windowTime()
    return sessionElapsedMs() - TrackList.frozenNowMs()
  end
  function PitStops.windowOpen()
    local s, e = PitStops.window()
    if not s or not sim.isSessionStarted then return false end
    local t = PitStops.windowTime()
    return t >= s and t <= e
  end
  local function swapValidNow() return PitStops.window() == nil or PitStops.windowOpen() end
  function PitStops.stopWindowOpen()
    local s, e = PitStops.stopWindow()
    if not s or not sim.isSessionStarted then return false end
    local t = PitStops.windowTime()
    return t >= s and t <= e
  end
  local function openPass(jumped, entryMs)
    PitStops.line = PitStops.line + 1
    PitStops.pass = { id = PitStops.line, entryMs = entryMs, jumped = jumped, service = nil, paid = {}, stop = nil,
      raceFlag = raceFlag(), driverFlag = driverFlag(), snap = nil }
  end
  local function closePass()
    local p = PitStops.pass
    PitStops.pass = nil
    if not p or not config.pitStopsEnabled then return end
    rcLog(TEXTS.rc.pit, string.format(TEXTS.pitStopRowText, p.id, p.stop and tostring(p.stop) or '-',
      p.entryMs and raceTime(p.entryMs) or TEXTS.pitStopRowInPits, raceTime(sessionElapsedMs()),
      p.service or TEXTS.pitStopRowNoService, #p.paid > 0 and table.concat(p.paid, ', ') or TEXTS.pitStopRowNoPenalty,
      p.jumped and 'tow' or 'driven', p.raceFlag, p.driverFlag, tostring(ac.getDriverTeam(0) or '-'),
      tostring(ac.getUserSteamID() or '-')))
  end
  function PitStops.countStop()
    local p = PitStops.pass
    if not config.pitStopsEnabled or not p or p.stop then return end
    if PitStops.stopWindow() and not PitStops.passInStopWindow then
      if not p.outside then
        p.outside = true
        ac.log('race-control: pit stop outside the window of the mandatory pit stop: not counted')
      end
      return
    end
    if PitStops.stopWindow() and not state.pit.stopDone then
      state.pit.stopDone = true
      Record.save('stopwindow', math.floor(serverTimeMs() / 1000), 'done')
      ac.log('race-control: mandatory pit stop window: stop counted')
    end
    PitRecord.stops = PitRecord.stops + 1
    p.stop = PitRecord.stops
    PitRecord.save()
    ac.log(string.format('race-control: pit stop %d counted', p.stop))
  end
  function PitStops.noteService(text)
    PitStops.markService()
    local p = PitStops.pass
    if p then p.service = p.service and (p.service .. '; ' .. text) or text end
  end
  function PitStops.notePaid(text)
    local p = PitStops.pass
    if p then p.paid[#p.paid + 1] = text end
  end
  function PitStops.record(lap, fuel, wheels, compoundChanged, repair)
    PitRecord.last = string.format('%d/%.1f/%d/%s', lap, fuel, wheels, repair and 'repair' or '-')
    local text = string.format('fuel +%.1f L%s%s%s', fuel, wheels > 0 and string.format(', tyres %d', wheels) or '',
      compoundChanged and ', compound' or '', repair and ', repair' or '')
    ac.log('race-control: pit stop with service: ' .. text)
    PitStops.noteService(text)
    PitStops.countStop()
    PitRecord.save()
  end
  function PitStops.validSwap()
    PitStops.passInWindow = true
    if PitStops.window() and not state.pit.done then
      state.pit.done = true
      Record.save('window', math.floor(serverTimeMs() / 1000), 'done')
      ac.log('race-control: mandatory pit window: valid driver swap')
    end
  end
  function PitStops.voidSwap(sgPaid)
    local sw = state.swap
    if not sw.passSwap or not sw.passSwapValid or sw.passVoided then return end
    sw.passVoided = true
    sw.voids = sw.voids + 1
    if state.pit.done then
      state.pit.done = false
      Record.save('window', math.floor(serverTimeMs() / 1000), 'open')
    end
    SwapRecord.save()
    ac.log('race-control: driver swap not valid: ' .. (sgPaid and 'stop & go served in the same pit stop'
      or 'service in the same pit stop'))
    rcLog(TEXTS.rc.swapBox, sgPaid and TEXTS.swapVoidSg or TEXTS.swapVoidService)
  end
  function PitStops.markService()
    if not state.pitPassServiced then
      state.pitPassServiced = true
      PitRecord.save()
    end
    PitStops.voidSwap()
    local p = PitStops.pass
    if p and p.sgPaid and not p.sgServiced then
      p.sgServiced = true
      ac.log(string.format('race-control: service in the same stop: the payment of the stop & go served in it (%s) is annulled; it applies again when the car leaves the pit place',
        p.sgPaid.cat))
      showNotice(TEXTS.rcTitle, TEXTS.sgAnnulled)
    end
  end
  local function sgBack(why)
    local p = PitStops.pass
    if not (p and p.sgPaid and p.sgServiced) then return end
    local sg = p.sgPaid
    p.sgPaid, p.sgServiced, p.sgParked = nil, nil, nil
    local l = state.list
    l.seq = l.seq + 1
    sg.seq = l.seq
    table.insert(l.items, 1, sg)
    if #l.items > 0 and not l.owner then l.owner = nameCode(ac.getDriverName(0)) end
    listSave()
    ac.log(string.format('race-control: %s with a service after the stop & go served (%s): the stop & go applies again', why, sg.cat))
    rcLog(TEXTS.rc.sgServiced, sg.cat)
    Rules.finalize()
    state.ui.lastSeq = state.list.seq
    showNotice(TEXTS.rcTitle, TEXTS.sgServiced, sg)
  end
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
    if not Rules.dsqOn() then carDsq(1, why) end
  end
  function PitStops.update(car)
    for i = 1, sim.carsCount - 1 do
      local c = ac.getCar(i)
      local inP = c and c.isInPitlane or false
      if inP and not PitStops.otherInPitlane[i] then state.swap.pitEntryValid[i] = swapValidNow() end
      PitStops.otherInPitlane[i] = inP
    end
    local inPit = car.isInPitlane
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
      if inPit then openPass(state.list.jumped, nil) end
    end
    if inPit and not PitStops.wasInPitlane then
      PitStops.passInWindow = PitStops.windowOpen()
      PitStops.passInStopWindow = PitStops.stopWindowOpen()
      openPass(state.list.jumped, sessionElapsedMs())
    end
    if not inPit and PitStops.wasInPitlane then
      sgBack('left the pit lane')
      closePass()
      PitStops.passInWindow = false
      PitStops.passInStopWindow = false
      local sw = state.swap
      sw.passSwap, sw.passSwapValid, sw.passVoided = false, false, false
      if state.pitPassServiced then
        state.pitPassServiced = false
        PitRecord.save()
      end
      if state.pitPassSgPaid or state.swapInvalid then
        state.pitPassSgPaid, state.swapInvalid = nil, nil
        PitRecord.save()
      end
    end
    PitStops.wasInPitlane = inPit
    if not inPit and (state.pitPassServiced or state.pitPassSgPaid or state.swapInvalid) then
      state.pitPassServiced, state.pitPassSgPaid, state.swapInvalid = false, nil, nil
      PitRecord.save()
      ac.log('race-control: marks of a pit pass already over cleared')
    end
    if PitStops.pass and PitStops.pass.entryMs and CarRead.parked(car) and state.ui.clock >= PitStops.settleUntil then
      PitStops.pass.stopped = true
    end
    local p = PitStops.pass
    if p and p.sgServiced then
      if car.isInPit then
        p.sgParked = true
      elseif p.sgParked and state.pitService == nil then
        sgBack('left the pit place')
      end
    end
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
    local ss, se = PitStops.stopWindow()
    if ss and config.pitStopsEnabled and sim.isSessionStarted and not state.pit.stopDone and not state.pit.stopMissed
        and PitStops.windowTime() > se and not (inPit and PitStops.passInStopWindow) then
      state.pit.stopMissed = true
      Record.save('stopwindow', 2, 'missed')
      ac.log('race-control: mandatory pit stop window missed (no stop counted in it): DSQ')
      rcLog(TEXTS.rc.stopWindow, TEXTS.stopWindowMissedLog)
      if not Rules.dsqOn() then carDsq(1, TEXTS.stopWindowDsq) end
    end
    local s, e = PitStops.window()
    if not s or not config.swapOn() or not sim.isSessionStarted or state.pit.done or state.pit.missed
      or PitStops.windowTime() <= e then
      return
    end
    if inPit and PitStops.passInWindow then return end
    state.pit.missed = true
    Record.save('window', 2, 'missed')
    ac.log('race-control: mandatory pit window missed (no valid driver swap): DSQ')
    rcLog(TEXTS.rc.pitWindow, TEXTS.pitMissedLog)
    if not Rules.dsqOn() then carDsq(1, TEXTS.pitWindowDsq) end
  end
end
RecordSync.restorers.stopwindow = function(body)
  if body == 'done' then state.pit.stopDone = true elseif body == 'missed' then state.pit.stopMissed = true end
end
RecordSync.restorers.window = function(body)
  if body == 'done' and not state.pit.done then
    state.pit.done = true
    ac.log('race-control: mandatory pit window done (from the other drivers)')
  elseif body == 'missed' then
    state.pit.missed = true
  end
end
local DriverTable = { done = false, swapDone = false, startT = nil }
do
  local DECIDE_SECONDS = 12
  function DriverTable.reset()
    DriverTable.done = false
    DriverTable.swapDone = false
    DriverTable.startT = nil
  end
  function DriverTable.update()
    if not config.swapOn() then return end
    local sw = state.swap
    local swapNow = sw.swapInfo and not DriverTable.swapDone
    if DriverTable.done and not swapNow then return end
    DriverTable.startT = DriverTable.startT or state.ui.clock
    local me = nameCode(ac.getDriverName(0))
    local swapNo, rejoin = nil, false
    if swapNow then
      DriverTable.swapDone = true
      swapNo = sw.count
      if sw.swapInfo.inWindow then PitStops.validSwap() end
      sw.passSwap, sw.passSwapValid, sw.passVoided = true, sw.swapInfo.inWindow, false
      if state.pitPassServiced then PitStops.voidSwap() end
      if state.pitPassSgPaid then PitStops.voidSwap(true) end
    elseif state.ui.clock - DriverTable.startT < DECIDE_SECONDS then
      return
    elseif sw.driver == me then
      swapNo, rejoin = sw.swapNo, true
    elseif sw.driver == 0 then
      swapNo = 0
    else
      sw.count = sw.count + 1
      swapNo = sw.count
      if PitStops.window() == nil then sw.valid = sw.valid + 1 end
      sw.passSwap, sw.passSwapValid, sw.passVoided = true, PitStops.window() == nil, false
      if state.pitPassSgPaid then PitStops.voidSwap(true) end
    end
    DriverTable.done = true
    if not rejoin and swapNo and swapNo > 0 then DriverTable.swapMs = serverTimeMs() end
    sw.swapNo, sw.driver = swapNo, me
    SwapRecord.save()
    rcLog(TEXTS.rc.driver, string.format(TEXTS.driverRowText, swapNo, rejoin and TEXTS.driverRowRejoin or '',
      tostring(ac.getDriverTeam(0) or '-'), tostring(ac.getUserSteamID() or '-')))
  end
end
local PitBox = { row = 1, fuel = 0, compound = nil, tyres = 1, repair = {}, open = false, touched = false,
  shownUntil = 0, auto = nil }
do
  local num = CarRead.num
  local WHEELS = { [0] = 'FL', 'FR', 'RL', 'RR' }
  local TYRE_CHOICES = {
    { '-', {} }, { 'FL', { 0 } }, { 'FR', { 1 } }, { 'RL', { 2 } }, { 'RR', { 3 } },
    { '2F', { 0, 1 } }, { '2B', { 2, 3 } }, { '2L', { 0, 2 } }, { '2R', { 1, 3 } }, { '2A', { 0, 1, 2, 3 } },
  }
  local ALL_TYRES = #TYRE_CHOICES
  local ROWS = { 'fuel', 'compound', 'tyres', 'suspension', 'powertrain', 'body', 'mode' }
  PitBox.preset = {}
  PitBox.setupPress = {}
  PitBox.tab = 'stop'
  PitBox.presetIdx = nil
  local function presetCount()
    local n = 1
    for _, sp in ipairs(ac.getPitstopSpinners and ac.getPitstopSpinners() or {}) do
      if type(sp.values) == 'table' then n = math.max(n, #sp.values) end
    end
    return n
  end
  PitBox.presetCount = presetCount
  function PitBox.presetIndex()
    local n = presetCount()
    if n <= 1 then return 0 end
    local i = PitBox.presetIdx
    if i == nil then i = num(sim.currentQuickPitPreset) end
    return math.min(math.max(math.floor(i), 0), n - 1)
  end
  local function presetValue(sp, idx)
    if type(sp.values) == 'table' and sp.values[idx + 1] ~= nil then return sp.values[idx + 1] end
    return sp.value
  end
  PitBox.presetValue = presetValue
  local function presetSpinners()
    local out, byName = {}, {}
    local idx = PitBox.presetIndex()
    for _, sp in ipairs(ac.getPitstopSpinners and ac.getPitstopSpinners() or {}) do
      if (sp.type == 'pressure' or sp.type == 'wing') and not sp.readOnly then
        local same = byName[sp.name]
        if same then same.n = same.n + 1
        else
          local e = { name = sp.name, type = sp.type, min = sp.min, max = sp.max, value = presetValue(sp, idx), values = sp.values,
            readOnly = sp.readOnly, n = 1 }
          byName[sp.name] = e
          out[#out + 1] = e
        end
      end
    end
    return out
  end
  PitBox.presetSpinners = presetSpinners
  local WHEEL_WORDS = { { 'FL', { 'LF', 'FL', 'FRONTLEFT', 'LEFTFRONT' } }, { 'FR', { 'RF', 'FR', 'FRONTRIGHT', 'RIGHTFRONT' } },
    { 'RL', { 'LR', 'RL', 'REARLEFT', 'LEFTREAR' } }, { 'RR', { 'RR', 'REARRIGHT', 'RIGHTREAR' } } }
  function PitBox.spinnerWheel(name)
    local up = tostring(name or ''):upper()
    local flat = up:gsub('[^A-Z]', '')
    for _, w in ipairs(WHEEL_WORDS) do
      for _, k in ipairs(w[2]) do
        if #k > 2 and flat:find(k, 1, true) then return w[1] end
        if #k == 2 and (up:match('[^A-Z]' .. k .. '$') or up:match('^' .. k .. '[^A-Z]') or up:match('[^A-Z]' .. k .. '[^A-Z]')) then return w[1] end
      end
    end
    if flat:find('FRONT', 1, true) then return 'F' end
    if flat:find('REAR', 1, true) then return 'R' end
    return nil
  end
  local loggedSession = nil
  function PitBox.logSpinners(why)
    local parts = {}
    for i, sp in ipairs(ac.getPitstopSpinners and ac.getPitstopSpinners() or {}) do
      local vals = {}
      if type(sp.values) == 'table' then for k = 1, #sp.values do vals[#vals + 1] = tostring(sp.values[k]) end end
      parts[#parts + 1] = string.format('%d:%s/%s=%s[%s..%s]%s{%s:%s}', i, tostring(sp.name), tostring(sp.type), tostring(sp.value),
        tostring(sp.min), tostring(sp.max), sp.readOnly and 'ro' or '', type(sp.values), table.concat(vals, ','))
    end
    ac.log('race-control: pit stop spinners (' .. why .. '): ' .. (#parts > 0 and table.concat(parts, ' ') or 'none')
      .. string.format('; presets %d, preset of the game %s', presetCount(), tostring(sim.currentQuickPitPreset)))
  end
  function PitBox.logSpinnersOnce()
    local n = #(ac.getPitstopSpinners and ac.getPitstopSpinners() or {})
    local key = tostring(sim.currentSessionIndex) .. '|' .. n
    if loggedSession == key then return end
    loggedSession = key
    PitBox.logSpinners('session')
  end
  local function buildRows()
    if PitBox.tab == 'strategy' then
      local rows = {}
      for i = 0, presetCount() - 1 do rows[#rows + 1] = 'preset:' .. i end
      rows[#rows + 1] = 'back'
      return rows
    end
    local rows = { 'fuel', 'compound', 'tyres' }
    if presetCount() > 1 then table.insert(rows, 1, 'strategy') end
    for _, sp in ipairs(presetSpinners()) do rows[#rows + 1] = 'set:' .. sp.name end
    for _, r in ipairs({ 'suspension', 'powertrain', 'body', 'mode' }) do rows[#rows + 1] = r end
    return rows
  end
  local function presetChanges()
    local out = {}
    for _, sp in ipairs(presetSpinners()) do
      local v = PitBox.preset[sp.name]
      if v and v ~= sp.value then out[#out + 1] = { name = sp.name, value = v, type = sp.type } end
    end
    return out
  end
  local SERVICE_LOCK_EXTRA = 1
  local function button(name, key, period)
    return ac.ControlButton('amxracing.race-control/Pit stop ' .. name, { keyboard = { key = key }, period = period })
  end
  local function padButton(name, pad, period)
    return ac.ControlButton('amxracing.race-control/Pit stop pad ' .. name, { gamepad = pad, period = period })
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
  local function compounds()
    local out = {}
    for i = 0, 15 do
      local name = ac.getTyresName(0, i)
      if not name or name == '' then break end
      out[i] = name
    end
    return out
  end
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
  function PitBox.calcRates()
    local ini = ac.INIConfig.carData(0, 'car.ini')
    local f = ini and ini:get('PIT_STOP', 'FUEL_LITER_TIME_SEC', -1) or -1
    local ty = ini and ini:get('PIT_STOP', 'TYRE_CHANGE_TIME_SEC', -1) or -1
    return { fuel = f >= 0 and f or nil, tyre = ty >= 0 and ty or nil }
  end
  function PitBox.stopTime(fuelS, tyresS) return orderTotal({ F = fuelS, T = tyresS, R = 0 }) end
  PitBox.calcData = function() return nil end
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
  local function damaged(car, group)
    if group == 'suspension' then
      for i = 0, 3 do if num(car.suspensionDamage[i]) > 0 then return true end end
      return false
    elseif group == 'powertrain' then
      return num(car.engineLifeLeft) < 1000 or num(car.gearboxDamage) > 0
    end
    for i = 0, 3 do if num(car.damage[i]) > 0 then return true end end
    return false
  end
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
    p.preset = {}
    for _, c in ipairs(presetChanges()) do
      if c.type == 'wing' or #TYRE_CHOICES[tyres][2] > 0 then p.preset[#p.preset + 1] = c end
    end
    p.setupPress = {}
    if #TYRE_CHOICES[tyres][2] > 0 then for k, v in pairs(PitBox.setupPress) do p.setupPress[k] = v end end
    p.presetIdx = PitBox.presetIndex()
    p.switch = presetCount() > 1 and PitBox.presetIdx ~= nil and p.presetIdx ~= num(sim.currentQuickPitPreset)
    return p
  end
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
    if p.repair.powertrain and num(car.gearboxDamage) > 0 then physics.resetCarState(0, 1) end
    physics.setCarFuel(0, fuel)
    if p.compound ~= num(car.compoundIndex) then physics.setTyresCompound(0, nil, p.compound) end
    for i = 0, 3 do physics.setTyresVirtualKM(0, i, km[i]) end
    physics.setCarBodyDamage(0, vec4(body[0], body[1], body[2], body[3]))
    if p.repair.suspension then
      for i = 0, 3 do physics.setSuspensionDamage(0, i, 0) end
    end
    if p.repair.powertrain then physics.setCarEngineLife(0, 1000) end
    local d = state.tow.damage
    if d then
      if p.repair.suspension then d.suspension = 0 end
      if p.repair.powertrain then d.powertrain = 0 end
      if p.repair.body then d.body = 0 end
    end
    ac.log(string.format('race-control: pit stop done (%s)', planText(p)))
    PitBox.gameStop(false, 'end of the box stop')
    local repaired = p.repair.suspension or p.repair.powertrain or p.repair.body
    PitStops.record(car.lapCount, fuel - fuelBefore, #wheels, p.compound ~= mounted, repaired)
  end
  PitBox.gameStopOn = false
  local function gameStop(on, why)
    if PitBox.gameStopOn == on then return end
    PitBox.gameStopOn = on
    ac.disableQuickMenuPitstop(not on)
    local wh, parts = ac.getCar(0).wheels, {}
    for i = 0, 3 do parts[#parts + 1] = string.format('%.1f', num(wh[i] and wh[i].tyrePressure)) end
    ac.log(string.format('race-control: game pit stop %s (%s); tyre pressure %s psi', on and 'on' or 'off', why,
      table.concat(parts, ' / ')))
  end
  PitBox.gameStop = gameStop
  local function gameNeeded(p) return #p.preset > 0 or p.switch end
  local function presetRequest(p)
    local req = {}
    for _, c in ipairs(p.preset) do req[#req + 1] = c end
    for _, sp in ipairs(ac.getPitstopSpinners() or {}) do
      if sp.type == 'fuel' and not sp.readOnly then req[#req + 1] = { name = sp.name, value = 0, type = 'fuel' } end
    end
    local parts = { tostring(p.presetIdx) }
    for _, c in ipairs(req) do parts[#parts + 1] = c.name .. '=' .. math.floor(c.value) end
    return req, table.concat(parts, ';')
  end
  PitBox.sentSig = nil
  local NUDGE_MS = 0.3
  local function writePreset(p, why, nudge)
    local req, sig = presetRequest(p)
    if sig == PitBox.sentSig and PitBox.gameStopOn then return end
    PitBox.sentSig = sig
    AppLink.onWritten = function()
      PitBox.logSpinners('after the write')
      if PitBox.sentSig ~= sig then return end
      gameStop(true, why)
      local car = ac.getCar(0)
      if nudge and car and car.look and CarRead.parked(car) then
        physics.setCarVelocity(0, vec3(car.look.x * NUDGE_MS, 0, car.look.z * NUDGE_MS))
        ac.log(string.format('race-control: game pit stop: the car moved %.1f m/s at its place, to stop there with the stop of the game on', NUDGE_MS))
      end
    end
    PitBox.logSpinners('before the write')
    AppLink.setPreset(req, p.presetIdx)
  end
  local function startStop(p)
    state.pitService = { startMs = serverTimeMs(), untilMs = serverTimeMs() + p.total * 1000, plan = planText(p) }
    PitStops.markService()
    if gameNeeded(p) then writePreset(p, 'preset written by the app', CarRead.parked(ac.getCar(0))) end
    if next(p.setupPress) then AppLink.setSetup(p.setupPress) end
    physics.lockUserControlsFor(p.total + SERVICE_LOCK_EXTRA)
    PitRecord.save()
    ac.log(string.format('race-control: pit stop started, %.1f s (%s)', p.total, planText(p)))
  end
  function PitBox.resume(startMs, untilMs, plan)
    if not planParse(plan) then return end
    state.pitService = { startMs = startMs, untilMs = untilMs, plan = plan }
    local left = (untilMs - serverTimeMs()) / 1000
    if left > 0 then physics.lockUserControlsFor(left + SERVICE_LOCK_EXTRA) end
    ac.log(string.format('race-control: pit stop goes on, %.1f s left', math.max(left, 0)))
  end
  local function reset()
    PitBox.row, PitBox.fuel, PitBox.compound, PitBox.tyres, PitBox.repair = 1, 0, nil, 1, {}
    PitBox.preset, PitBox.setupPress = {}, {}
    PitBox.touched = false
    PitBox.tab, PitBox.presetIdx, PitBox.sentSig = 'stop', nil, nil
    PitBox.remoteUntil = 0
  end
  PitBox.reset = reset
  function PitBox.isAuto()
    if PitBox.auto == nil then return config.pitStopAuto end
    return PitBox.auto
  end
  local function chosen(p)
    return p.fuel > 0 or #TYRE_CHOICES[p.tyres][2] > 0 or p.repair.suspension or p.repair.powertrain or p.repair.body
      or #p.preset > 0 or p.switch
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
      PitBox.auto = not PitBox.isAuto()
      return
    elseif what == 'strategy' then
      PitBox.tab, PitBox.row = 'strategy', PitBox.presetIndex() + 1
      return
    elseif what == 'back' then
      PitBox.tab, PitBox.row = 'stop', 1
      return
    elseif what:sub(1, 7) == 'preset:' then
      if dir > 0 then
        PitBox.presetIdx = tonumber(what:sub(8))
        PitBox.preset = {}
        PitBox.touched = true
        ac.log(string.format('race-control: pit stop: preset %d of the quick pit menu chosen for the stop', PitBox.presetIdx + 1))
      end
      PitBox.tab, PitBox.row = 'stop', 1
      return
    elseif what:sub(1, 4) == 'set:' then
      local name = what:sub(5)
      for _, sp in ipairs(presetSpinners()) do
        if sp.name == name then
          PitBox.preset[name] = math.max(sp.min, math.min((PitBox.preset[name] or sp.value) + dir, sp.max))
        end
      end
    else
      PitBox.repair[what] = dir > 0
    end
    PitBox.touched = true
  end
  local menuOff = false
  function PitBox.update(car)
    if PitBox.gameStopOn and not car.isInPitlane then gameStop(false, 'left the pit lane') end
    if not car.isInPitlane then PitBox.sentSig = nil end
    if not menuOff then
      ac.disableQuickMenuPitstop(true)
      ac.disableExtraHUDElements('quickPitsMenu', true)
      menuOff = true
    end
    PitBox.logSpinnersOnce()
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
    ROWS = buildRows()
    PitBox.ROWS = ROWS
    if PitBox.row > #ROWS then PitBox.row = #ROWS end
    local wasOpen = PitBox.open
    PitBox.open = CarRead.parked(car) and not state.hold and not Rules.dsqOn()
      and not CarState.restoring
    local padOn = not PitBox.padFor or PitBox.padFor('pitbox')
    local function hit(name)
      local own = PitBox.ownDir and PitBox.ownDir(name)
      return (padOn and (PAD[name]:pressed() or own)) or (KEYS[name]:pressed() and PitBox.open)
    end
    local up, down, left, right = hit('up'), hit('down'), hit('left'), hit('right')
    if up then PitBox.row = (PitBox.row - 2) % #ROWS + 1 end
    if down then PitBox.row = PitBox.row % #ROWS + 1 end
    local confirm = right and ROWS[PitBox.row] == 'mode' and PitBox.tab == 'stop'
    if left then choose(car, -1) end
    if right and not confirm then choose(car, 1) end
    if (up or down or left or right) and not PitBox.open then PitBox.shownUntil = state.ui.clock + config.screens.pitBoxSeconds end
    if not PitBox.open and car.isInPitlane and PitBox.isAuto() and PitBox.touched then
      local p = PitBox.plan(car)
      if chosen(p) and gameNeeded(p) then writePreset(p, 'AUTO: preset written before the arrival', false)
      elseif PitBox.gameStopOn then
        PitBox.sentSig = nil
        gameStop(false, 'AUTO: nothing for the stop of the game')
      end
    end
    if not PitBox.open then return end
    local p = PitBox.plan(car)
    if not chosen(p) then return end
    local remoteGo = PitBox.remoteUntil > state.ui.clock
    if confirm or remoteGo or (PitBox.isAuto() and not wasOpen and PitBox.touched) then
      if remoteGo and not confirm then ac.log('race-control: pit stop started from the Racing Room') end
      PitBox.remoteUntil = 0
      startStop(p)
    end
  end
  local REMOTE_START_S = 120
  PitBox.remoteUntil = 0
  function PitBox.remote(b)
    local car = ac.getCar(0)
    if not car then return end
    if b.fuel then PitBox.fuel = math.max(0, math.min(b.fuel, math.max(num(car.maxFuel) - num(car.fuel), 0))) end
    if b.compound and compounds()[b.compound] then PitBox.compound = b.compound end
    if b.tyres and TYRE_CHOICES[b.tyres] then PitBox.tyres = b.tyres end
    if b.repair then
      PitBox.repair = { suspension = b.repair:find('s') ~= nil, powertrain = b.repair:find('p') ~= nil, body = b.repair:find('b') ~= nil }
    end
    if b.auto ~= nil then PitBox.auto = b.auto end
    if b.press then
      PitBox.setupPress = {}
      for k, v in tostring(b.press):gmatch('([%w_]+):(%-?%d+)') do PitBox.setupPress[k] = tonumber(v) end
    end
    if b.preset and b.preset >= 0 and b.preset < presetCount() then PitBox.presetIdx = b.preset end
    if b.fuel or b.compound or b.tyres or b.repair or b.press or b.preset then PitBox.touched = true end
    if b.start then PitBox.remoteUntil = state.ui.clock + REMOTE_START_S end
  end
  function PitBox.stateBody(car)
    local p = PitBox.plan(car)
    local sv = state.pitService
    local names, list = {}, compounds()
    for i = 0, 15 do
      if not list[i] then break end
      names[#names + 1] = (tostring(list[i]):gsub('[|;,]', ' '))
    end
    local function groups(t) return (t.suspension and 's' or '') .. (t.powertrain and 'p' or '') .. (t.body and 'b' or '') end
    local dmg = { suspension = damaged(car, 'suspension'), powertrain = damaged(car, 'powertrain'), body = damaged(car, 'body') }
    return table.concat({ PitBox.open and 1 or 0, PitBox.isAuto() and 1 or 0, PitBox.touched and 1 or 0, p.presetIdx,
      string.format('%.0f', PitBox.fuel), p.compound, num(car.compoundIndex), p.tyres, groups(p.repair), string.format('%.1f', p.total),
      string.format('%.1f', p.times.fuel), string.format('%.1f', p.times.tyres), string.format('%.1f', p.times.suspension + p.times.powertrain + p.times.body),
      sv and math.floor(sv.startMs) or 0, sv and math.floor(sv.untilMs) or 0, groups(dmg), table.concat(names, ','),
      string.format('%.0f', num(car.maxFuel)), car.isInPitlane and 1 or 0, PitBox.remoteUntil > state.ui.clock and 1 or 0, PitBox.calcBody(car) }, '|')
  end
  function PitBox.calcBody(car)
    local d = PitBox.calcData(car) or {}
    local function f(v, fmt) return v and string.format(fmt, v) or '' end
    return table.concat({ f(d.rateFuel, '%.3f'), f(d.rateTyre, '%.2f'), (tostring(config.pitStopOrder):gsub('[|;]', '')), f(d.lapMs, '%.0f'), tostring(d.flying or 0),
      f(d.fuel, '%.3f'), f(d.wear, '%.3f'), f(d.pitLoss, '%.0f'), tostring(d.losses or 0), f(d.raceMin, '%.0f') }, '|')
  end
  PitRecord.onService = PitBox.resume
  RecordSync.base.pitBox = PitBox
  PitBox.WHEELS = WHEELS
  PitBox.TYRE_CHOICES = TYRE_CHOICES
  PitBox.PAD = PAD
  PitBox.ROWS = ROWS
  PitBox.compounds = compounds
  PitBox.damaged = damaged
end
local PitSpeed = {
  entryLap = nil,
  over = false,
  maxKmh = 0,
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
  if Rules.dsqOn() then
    ac.log('race-control: pit lane speeding after the DSQ: not applied')
    return
  end
  local before = listDump()
  if paid then
    listAdd(paid.cat, math.max(paid.laps - lost, 0))
    ac.log(string.format('race-control: pit lane speeding: %s DT paid in this pass does not count', paid.cat))
    rcLog(TEXTS.rc.dtNotServed, string.format('%s - pit lane speeding %.1f km/h', paid.cat, speed))
    showNotice(TEXTS.rcTitle, TEXTS.pitSpeedNotPaid)
  end
  listAdd('PSE', math.max(config.pitSpeedDeadlineLaps - lost, 0))
  ac.log(string.format('race-control: PSE pit exit %.1f km/h before=%s after=%s', speed, before, listDump()))
  rcLog(TEXTS.rc.dt, string.format('%s - %.1f km/h', TEXTS.reason.PSE, speed))
  Rules.finalize()
end
local StopAndGo = {
  drove = false,
  serviced = false,
  snap = nil,
  stopping = false,
  base = 0,
  startMs = 0,
  lastSaveMs = 0,
  resume = false,
  checkedKind = nil,
}
do
  local SG_SAVE_EVERY_MS = 1000
  local function sgFields(it)
    local served, t, d = it.kind:match('^SGs(%d+)t(%d+)d(%d+)')
    return tonumber(served) or 0, tonumber(t), tonumber(d)
  end
  local function sgTail(it)
    local e = it.kind:match('e(%d+)')
    return (e and ('e' .. e) or '') .. sgKmrSuffix(it)
  end
  local function sgMark(it, served)
    it.kind = string.format('SGs%dt%dd%d', math.floor(served), math.floor(serverTimeMs() / 1000),
      nameCode(ac.getDriverName(0))) .. sgTail(it)
  end
  function StopAndGo.remainingMs(sg)
    local total = sgSeconds(sg) * 1000
    if StopAndGo.stopping then return math.max(total - StopAndGo.base - (serverTimeMs() - StopAndGo.startMs), 0) end
    return math.max(total - sgFields(sg), 0)
  end
  function StopAndGo.returnLeft()
    local sg = sgItem()
    if not sg or not StopAndGo.resume then return nil end
    local _, t = sgFields(sg)
    return math.max(config.sgReturnSeconds - (serverTimeMs() / 1000 - (t or 0)), 0)
  end
  local function checkInterrupted(sg)
    StopAndGo.checkedKind = sg.kind
    local served, t, driver = sgFields(sg)
    if served <= 0 then return end
    local away = serverTimeMs() / 1000 - (t or 0)
    if driver ~= nameCode(ac.getDriverName(0)) then
      ac.log('race-control: stop & go interrupted: another driver in the car')
    elseif config.sgReturnSeconds > 0 and away > config.sgReturnSeconds then
      StopAndGo.stopping = false
      StopAndGo.resume = false
      carDsq(1, TEXTS.dsqWhy.sgInterrupted)
      ac.log(string.format('race-control: DSQ, stop & go interrupted for %d s', math.floor(away)))
    else
      StopAndGo.resume = true
      ac.log(string.format('race-control: stop & go interrupted %d s ago, %.1f s served: resumes at the pit place',
        math.floor(away), served / 1000))
    end
  end
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
        if PitStops.pass then
          PitStops.pass.sgPaid = sg
          sg.kind = 'SG' .. sgTail(sg)
        end
        state.pitPassSgPaid = nameCode(ac.getDriverName(0))
        PitRecord.save()
        ac.log(string.format('race-control: stop & go served (%d s)', sgSeconds(sg)))
        PitStops.notePaid(string.format('stop & go %d s', sgSeconds(sg)))
        PitStops.countStop()
        rcLog(TEXTS.rc.sgServed, string.format('%d s', sgSeconds(sg)))
        for n in sgKmrSuffix(sg):gmatch('x(%d+)') do
          rcLog(TEXTS.rc.dtServedSg, reasonLog('K' .. n))
        end
        Rules.finalize()
      elseif not CarRead.parked(car) then
        notServed(sg, 'the car moved', done)
      elseif now - StopAndGo.lastSaveMs >= SG_SAVE_EVERY_MS then
        StopAndGo.lastSaveMs = now
        sgMark(sg, done)
        StopAndGo.checkedKind = sg.kind
        listSave()
      end
      return
    end
    if state.code80 or state.redFlag or state.restart or StopAndGo.serviced or not CarRead.parked(car) then return end
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
local WrongDriver = {}
do
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
      if l.wrong then
        l.wrong = nil
        listSave()
        ac.log('race-control: wrong driver gone: the driver who has to pay the penalties is in the car')
      end
      return
    end
    if not config.wrongDriver then
      l.owner = me
      l.wrong = nil
      listSave()
      ac.log('race-control: penalties taken over by the new driver (wrongDriverSeconds empty)')
      rcLog(TEXTS.rc.swap, 'Pending penalties taken over by the new driver')
      return
    end
    if not l.wrong or l.wrong.driver ~= me then
      l.wrong = { driver = me, since = serverTimeMs() }
      listSave()
      ac.log(string.format('race-control: wrong driver: pending penalties of another driver, %d s to leave',
        config.wrongDriver))
      rcLog(TEXTS.rc.wrongDriver, string.format('pending penalties of another driver - %d s to leave', config.wrongDriver))
    end
    if WrongDriver.remaining() <= 0 then
      carDsq(1, TEXTS.dsqWhy.swapPending)
      ac.log('race-control: DSQ, wrong driver did not leave the car')
    end
  end
  function WrongDriver.invalidLeft()
    local inv = state.swapInvalid
    if not inv or not config.wrongDriver then return nil end
    return math.max(config.wrongDriver - (serverTimeMs() - inv.since) / 1000, 0)
  end
  function WrongDriver.invalidSwap(car)
    if not config.swapOn() then return end
    local payer = state.pitPassSgPaid
    local me = nameCode(ac.getDriverName(0))
    local inv = state.swapInvalid
    if inv and inv.driver ~= me then
      state.swapInvalid, inv = nil, nil
      PitRecord.save()
      ac.log('race-control: invalid driver swap over: another driver in the car')
    end
    if payer and state.swap.passSwap then PitStops.voidSwap(true) end
    if not payer or payer == me then return end
    if not inv then
      inv = { driver = me, since = serverTimeMs() }
      state.swapInvalid = inv
      PitRecord.save()
      ac.log(string.format('race-control: invalid driver swap: stop & go served in this stop by another driver, %s s to leave',
        tostring(config.wrongDriver or '-')))
      rcLog(TEXTS.rc.swapInvalid, TEXTS.swapInvalidLeave)
    end
    if car.isInPit then
      inv.parked = true
    elseif inv.parked then
      ac.log('race-control: DSQ, the car left the pits after an invalid driver swap')
      carDsq(1, TEXTS.swapInvalidLeftDsq)
      return
    end
    local left = WrongDriver.invalidLeft()
    if left and left <= 0 then
      ac.log('race-control: DSQ, invalid driver swap: the driver did not leave the car')
      carDsq(1, TEXTS.swapInvalidDsq)
    end
  end
end
local WrongWay = { back = 0 }
do
  local STOPPED_KMH = 1
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
    if rule.penalty ~= 'DSQ' or car.isInPitlane or Rules.dsqOn() then
      WrongWay.reset()
      return
    end
    local m = CarRead.motion
    local pointing = CarRead.trackAngle(car, car.look.x, car.look.z)
    local moving = m.dist > 0 and CarRead.trackAngle(car, m.dx, m.dz) or nil
    local before = WrongWay.back
    if car.speedKmh < STOPPED_KMH or (pointing and pointing <= rule.angle) then
      WrongWay.back = 0
      if before >= rule.showMeters then
        rcLog(TEXTS.rc.wrongWayOff, string.format('%.0f m - %s', before, car.speedKmh < STOPPED_KMH and 'car stopped'
          or string.format('back within %d deg (%.0f deg)', rule.angle, pointing)))
      end
    elseif pointing and moving and moving > rule.angle then
      WrongWay.back = WrongWay.back + m.dist
      if before < rule.showMeters and WrongWay.back >= rule.showMeters then
        rcLog(TEXTS.rc.wrongWay, string.format('%.0f deg from the track - %.0f m', pointing, WrongWay.back))
      end
    end
    if WrongWay.back > rule.maxMeters then
      ac.log(string.format('race-control: DSQ, wrong way %.0f m (limit %d m)', WrongWay.back, rule.maxMeters))
      WrongWay.reset()
      carDsq(1, TEXTS.wrongWayDsq, nil, string.format('over %d m', rule.maxMeters))
    end
  end
end
local DsqFlow = {}
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
local Ban = { pending = nil, done = false }
Record.onTampered = function(list)
  if not Ban.done then Ban.pending = Ban.pending or list end
end
function Ban.update()
  if not Ban.pending or Ban.done then return end
  local list = Ban.pending
  Ban.pending = nil
  Ban.done = true
  ac.log('race-control: edited record file (' .. list .. '): DSQ and ban pending')
  carDsq(1, TEXTS.editedFile, nil, string.format(TEXTS.rc.editedFileDetail, list, ac.getCar(0).sessionID))
  dsqGameFlag('edited file')
end
local KmrDT = {}
do
  local function category(low)
    for _, r in ipairs(DICT.kmr.reasons) do
      if hasAny(low, r.words) then return r.cat end
    end
    return 'K0'
  end
  local function deadline(low)
    local K = DICT.kmr
    if hasAny(low, K.nextRace) then return 'next race' end
    if hasAny(low, K.thisLap) then return 0 end
    local n = DICT.match(low, K.withinLaps)
    if n then return tonumber(n) end
    return nil
  end
  local ratingDone = nil
  function KmrDT.sessionReset() ratingDone = nil end
  local function ratingCheck()
    local r = config.kmrRating
    if not r.on or Audit.rating == nil then return end
    if Audit.rating > r.dsqAt then
      ratingDone = nil
      return
    end
    if ratingDone == Audit.rating or Rules.dsqOn() then return end
    ratingDone = Audit.rating
    ac.log(string.format('race-control: DSQ, KMR safety rating %s (limit %s)', Audit.num(Audit.rating), Audit.num(r.dsqAt)))
    carDsq(1, string.format(TEXTS.kmrRatingDsq, Audit.num(Audit.rating), Audit.num(r.dsqAt)))
  end
  local function cancelled(text, via)
    local low = text:lower()
    local cat = category(low)
    local base = TEXTS.kmrReasons[cat]
    local l = state.list
    for i = #l.items, 1, -1 do
      local it = l.items[i]
      if it.cat == cat then
        listRemove(it)
        ac.log(string.format('race-control: KMR drive-through cancelled by the KMR (%s): %s', cat, text))
        rcLog(TEXTS.rc.dtCancelled, base .. ' - cancelled by the KMR race director' .. via)
        Rules.finalize()
        return
      end
    end
    local sg = sgItem()
    local n = cat:match('^K(%d+)$')
    if sg and n and sg.kind:find('x' .. n, 1, true) and sgCount(sg) > 2 then
      sg.kind = sg.kind:gsub('x' .. n, '', 1)
      sg.cat = 'SG' .. (sgCount(sg) - 1)
      l.seq = l.seq + 1
      sg.seq = l.seq
      listSave()
      ac.log(string.format('race-control: KMR drive-through cancelled by the KMR (%s): one DT less in the stop & go', cat))
      rcLog(TEXTS.rc.dtCancelled, base .. ' - cancelled by the KMR race director, one DT less in the stop & go' .. via)
      return
    end
    ac.log(string.format('race-control: KMR drive-through cancelled by the KMR (%s), not in the list as a DT: %s', cat, text))
    rcLog(TEXTS.rc.dtCancelledKmr, base .. ' - not a DT of the list (stop & go of two DTs or paid): race direction' .. via)
  end
  function KmrDT.update()
    ratingCheck()
    local msgs = state.kmrMessages
    if #msgs == 0 then return end
    state.kmrMessages = {}
    table.sort(msgs, function(a, b) return (a.t or 0) < (b.t or 0) or ((a.t or 0) == (b.t or 0) and (a.n or 0) < (b.n or 0)) end)
    for _, m in ipairs(msgs) do
      local text = m.text
      local via = ' - chat sender ' .. tostring(m.sender)
      local low = text:lower()
      local laps = not m.cancel and hasAny(low, DICT.kmr.penalty) and deadline(low)
      if m.cancel then
        cancelled(text, via)
      elseif laps then
        local cat = category(low)
        local base = TEXTS.kmrReasons[cat]
        if cat == 'K3' then Audit.kmrPointsReset() end
        if cat == 'K1' then laps = 0 end
        if cat ~= 'K1' and (laps == 'next race' or sim.raceSessionType ~= ac.SessionType.Race) then
          ac.log('race-control: KMR drive-through relaxed (' .. cat .. '): ' .. text)
          rcLog(TEXTS.rc.dtRelaxed, base .. ' - issued by KMR for the next race, not carried over by Racing Control' .. via)
        elseif not Rules.dsqOn() then
          ac.log(string.format('race-control: KMR drive-through DT%d (%s): %s', laps, cat, text))
          rcLog(TEXTS.rc.dtKmr .. laps, base .. ' - issued by KMR, recorded by Racing Control' .. via)
          listAdd(cat, laps)
          Rules.finalize()
        else
          rcLog(TEXTS.rc.dtAfterDsq, base .. ' - issued by KMR, logged only' .. via)
        end
      else
        rcLog(TEXTS.rc.kmrUnread, text .. via)
      end
    end
  end
end
local RcCommand = {}
do
  local LOCK_MAX_SECONDS = 86400
  local MENU_FREE_MINUTES = 5
  local MENU_MAX_MINUTES = 60
  local function isMine(id)
    if #id >= 17 then return id == tostring(ac.getUserSteamID() or '') end
    return tonumber(id) == ac.getCar(0).sessionID
  end
  local function holdOff()
    if state.hold then PitRecord.holdEnded = math.min(state.hold.untilMs, serverTimeMs()) end
    state.hold = nil
    local car = ac.getCar(0)
    if car and car.currentPenaltyType ~= BLACK_FLAG and not Rules.dsqOn() then
      physics.setCarPenalty(NONE, 0)
      ac.log('race-control: hold of the game taken off (penalty of the game set to none)')
    end
    physics.lockUserControlsFor(0)
    PitRecord.save()
  end
  local function done(what, detail)
    local text = detail and detail ~= '' and (what .. ' - ' .. detail) or what
    rcLog(TEXTS.rc.command, text)
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
      holdOff()
    elseif what == 'REPAIR' then
      local r = state.repair
      r.lapsLeft, r.beyondSince, r.class, r.waived = nil, nil, 'normal', true
    elseif what == 'DSQ' then
      carDsqClear('Racing Control command')
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
      state.tow.ownJumpUntil = state.ui.clock + 2
      state.list.jumped = true
      physics.teleportCarTo(0, ac.SpawnSet.Pits, true)
      done('Teleport to the pits', why)
    elseif what == 'DSQ' then
      carDsq(1, why)
      ac.log('race-control: DSQ by Racing Control command')
      showNotice(TEXTS.rcTitle, string.format(TEXTS.dirDsqNotice, why), nil, SERVER_NOTICE_SECONDS)
    elseif what == 'KMR' then
      Audit.askPending = true
      return true
    elseif what == 'FUEL' then
      state.redFuelOk = true
      done(TEXTS.redFuelUnlocked, why)
    elseif what == 'MENU' then
      local minutes = value ~= '' and tonumber(value) or MENU_FREE_MINUTES
      if not minutes or minutes < 0 then return false end
      minutes = math.min(minutes, MENU_MAX_MINUTES)
      state.menuFreeUntil = minutes > 0 and state.ui.clock + minutes * 60 or nil
      done(minutes > 0 and string.format(TEXTS.menuFree, minutes) or TEXTS.menuFreeOff, why)
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
    table.sort(cmds, function(a, b) return a.t < b.t or (a.t == b.t and a.n < b.n) end)
    for _, e in ipairs(cmds) do
      local line = e.text
      local body, reason = line, ''
      local cut = line:find(' - ', 1, true)
      if cut then body, reason = line:sub(1, cut - 1), line:sub(cut + 3):gsub('^%s+', ''):gsub('%s+$', '') end
      local red = body:upper():match('^%s*RC%s+REDFLAG%s+(%a+)')
      if red == 'ALL' or red == 'OFF' then
        local on = red == 'ALL'
        if on ~= (state.redFlag ~= nil) then
          state.redFlag = on and { reason = reason ~= '' and reason or nil } or nil
          state.postRed = (not on) or nil
          TrackList.changed()
          rcLog(on and 'Red flag' or 'Red flag off', reason ~= '' and reason or '-')
          ac.log('race-control: red flag ' .. (on and 'on' or 'off') .. (reason ~= '' and (' - ' .. reason) or ''))
        end
      end
      if body:upper():match('^%s*RC%s+GREEN%s+ALL') and not state.restart
          and (state.redFlag or state.code80 or state.postRed) then
        if state.code80 then state.code80Ended = true end
        state.redFlag, state.code80, state.postRed = nil, nil, nil
        TrackList.changed()
        rcLog(TEXTS.rc.green, reason ~= '' and reason or '-')
        ac.log('race-control: green flag by Racing Control command (red flag down, CODE-80 over)')
      end
      local lights = body:upper():match('^%s*RC%s+LIGHTS%s+(%a+)%s+ALL')
      if (lights == 'RED' or lights == 'GREEN' or lights == 'AUTO') and (state.lights or 'AUTO') ~= lights then
        state.lights = lights ~= 'AUTO' and lights or nil
        TrackList.changed()
        rcLog(TEXTS.rc.lights, lights)
        ac.log('race-control: track lights ' .. lights .. ' by Racing Control command')
      end
      local rs, rsT = body:upper():match('^%s*RC%s+RESTART%s+(%a+)%s*@?(%d*)')
      if rs == 'ALL' and state.redFlag and not state.restart then
        state.restart = { t0 = tonumber(rsT) or math.ceil(serverTimeMs() / 5000) * 5000 }
        state.redFlag = nil
        state.postRed = nil
        TrackList.changed()
        rcLog(TEXTS.rc.standingRestart, reason ~= '' and reason or '-')
        ac.log('race-control: standing restart command, time ' .. math.floor(state.restart.t0))
      elseif rs == 'OFF' and state.restart then
        state.restart = nil
        state.redFlag = { reason = reason ~= '' and reason or nil }
        TrackList.changed()
        rcLog(TEXTS.rc.standingRestartOff, reason ~= '' and reason or '-')
      end
      if body:upper():match('^%s*RC%s+START%s+ABORT%s+ALL%s*$') and state.formationAbort
        and state.formationAbort(reason) then
        TrackList.changed()
      end
      local stT = body:upper():match('^%s*RC%s+START%s+ALL%s*@?(%d*)')
      if stT and state.formationStart and state.formationStart(tonumber(stT)) then
        TrackList.changed()
      end
      local action, id, value = body:match('^%s*[Rr][Cc]%s+(%a+)%s+(%d+)%s*(%S*)')
      if action and not red and isMine(id) then
        action, value = action:upper(), value:upper()
        local ok
        if action == 'RELAX' then ok = relax(value, reason)
        elseif action == 'UNLOCK' then
          holdOff()
          done('Unlocked', reason)
          ok = true
        else ok = penalty(action, value, reason) end
        ac.log('race-control: command ' .. line .. (ok and '' or ' (not understood)'))
        if not ok then rcLog(TEXTS.rc.commandUnread, line) end
      end
    end
  end
end
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
    cats = cats,
  }
end
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
local function onSlowdownUnpaid(cat, endOfLap, inPit)
  local unpaid = config.unpaid[sim.raceSessionType]
  if not unpaid or unpaid.penalty == 'NONE' then return end
  if unpaid.penalty == 'DSQ' then
    carDsq(1, string.format(TEXTS.dsqWhy.slowdown, TEXTS.reason[cat]))
    return
  end
  if unpaid.penalty ~= 'DT' then return end
  rcLog(TEXTS.rc.dt, TEXTS.reason[cat] .. ' - slowdown not served')
  if endOfLap or inPit then
    Rules.slowdownEndOfLap(cat)
  else
    Rules.slowdownMidLap(cat)
  end
  queueChat(TEXTS.cut.DT)
  ac.log(string.format('race-control: slowdown %s unpaid, end of lap=%s', cat, tostring(endOfLap)))
end
local SLOWDOWN_PULSE_MAX_HZ = 6
local SLOWDOWN_PULSE_MIN_HZ = 1
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
local Flags = { incidents = {}, own = 0, ownSince = nil, sentKind = 0, sentT = -1e9, greenUntil = 0, lastGroup = nil,
  sector = nil, lastLap = nil, lastLapSession = nil, ending = nil, endSession = nil, overLeader = nil,
  prevPitlane = nil, hudOff = false, redSent = 'off', redSentT = -1e9, redLocked = false, redLockT = 0, redWasUp = false,
  redSince = nil, redReceived = false, redPrevLane = nil, redSwaps = {}, mySwapMs = nil, restartUntil = nil,
  swapSentT = -1e9, lightsSent = nil, lightsSentT = -1e9, redOver = false, redOverSince = nil, localYellow = false, giveBack = {} }
do
  local INC = { none = 0, slow = 1, stopped = 2, broken = 3, oil = 4 }
  local INC_RESEND = 20
  local INC_EXPIRE = 45
  local STOPPED_KMH = 5
  local STOPPED_SECONDS = 3
  local incNames = { [1] = 'slow', [2] = 'stopped', [3] = 'broken', [4] = 'oil' }
  local sendIncident = ac.OnlineEvent({
    ac.StructItem.key('amxracing.race-control.inc'),
    incKind = ac.StructItem.uint8(),
    incPos = ac.StructItem.uint16(),
  }, function(sender, msg) Flags.receive(sender, msg) end, nil, nil, { processPostponed = true })
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
    if CarRead.isStaff(i) then Flags.incidents[i] = nil return end
    local kind = tonumber(msg.incKind) or 0
    local pos = (tonumber(msg.incPos) or 0) / 65535
    if not Trust.incident(sender, kind, pos) then return end
    local old = Flags.incidents[i]
    local oilPos = kind == INC.oil and pos or (old and old.oilPos)
    local oilT = kind == INC.oil and state.ui.clock or (old and old.oilT)
    Flags.incidents[i] = { kind = kind, pos = pos, t = state.ui.clock, oilPos = oilPos, oilT = oilT }
  end
  local function publish(car)
    local kind = CarRead.isStaff(0) and INC.none or ownKind(car)
    local clock = state.ui.clock
    if kind ~= Flags.sentKind or (kind ~= INC.none and clock - Flags.sentT >= INC_RESEND) then
      if kind ~= Flags.sentKind then
        rcLog(TEXTS.rc.incident, kind == INC.none and 'cleared' or incNames[kind])
      end
      Flags.sentKind, Flags.sentT = kind, clock
      OnlineQueue.push(sendIncident, { incKind = kind,
        incPos = math.floor(math.min(math.max(CarRead.num(car.splinePosition), 0), 1) * 65535) }, nil)
    end
    Flags.own = kind
  end
  local function ahead(car, pos)
    local len = tonumber(sim.trackLengthM) or 0
    return ((pos - CarRead.num(car.splinePosition)) % 1) * len
  end
  local function carTag(i)
    return string.format('#%d', ac.getDriverNumber(i) or i)
  end
  local SWAP_RESEND = 5
  local sendRedSwap = ac.OnlineEvent({
    ac.StructItem.key('amxracing.race-control.redorder'),
    swapS = ac.StructItem.uint32(),
  }, function(sender, msg)
    if sender and sender.index ~= 0 and Flags.restartUntil then Flags.redSwaps[sender.index] = tonumber(msg.swapS) end
  end, nil, nil, { processPostponed = true })
  local function restartPlace()
    local list = {}
    for i = 0, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and (i == 0 or c.isConnected) and not CarRead.isStaff(i) then
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
  Flags.restartPlace = restartPlace
  local function restartText()
    if not Flags.restartUntil or sim.raceSessionType ~= ac.SessionType.Race then return nil end
    local k, ahead = restartPlace()
    if not k then return nil end
    if not ahead then return string.format(TEXTS.flagRestartFirst, k) end
    return string.format(Flags.mySwapMs and TEXTS.flagRestartSwap or TEXTS.flagRestart, k, carTag(ahead))
  end
  local RESTART_WAIT = 10
  local function restartUpdate()
    local clock = state.ui.clock
    if state.redFlag or state.restart then
      Flags.restartUntil = math.huge
      if state.redFlag and DriverTable.swapMs and DriverTable.swapMs >= TrackList.since and not Flags.mySwapMs then
        Flags.mySwapMs = DriverTable.swapMs
        rcLog(TEXTS.rc.red, 'driver swap: restart at the back of the field')
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
  local function pick(car)
    local cfg = config.flags
    local clock = state.ui.clock
    local red, yellow, info, normal
    Flags.localYellow = false
    if state.redFlag then
      local kmh = CarRead.num(car.speedKmh)
      local over = not car.isInPitlane and cfg.redSpeedKmh > 0 and kmh > cfg.redSpeedKmh
      local atPlace = CarRead.parked(car) and restartText()
      red = { 1, 'red', TEXTS.flagRed, atPlace and TEXTS.flagRedLocked or TEXTS.flagRedLine, over and string.format(TEXTS.flagRedSpeed, cfg.redSpeedKmh, kmh)
        or atPlace or (CarRead.parked(car) and TEXTS.flagRedLocked)
        or ((state.ui.clock - (Flags.redSince or clock)) < cfg.redGraceSeconds and string.format(TEXTS.flagRedGrace,
          math.ceil(cfg.redGraceSeconds - (state.ui.clock - (Flags.redSince or clock)))))
        or (not car.isInPitlane and not Flags.redReceived and TEXTS.flagRedToLine)
        or (not car.isInPitlane and TEXTS.flagRedToBox)
        or (state.redFlag.reason or TEXTS.flagRedNeutral), over }
    end
    if red and Flags.onGrid then red[4], red[5] = TEXTS.srCancelled, TEXTS.srGridLocked end
    if not red and Flags.standingFlag then red = Flags.standingFlag(car) end
    if state.code80 and not yellow then
      yellow = { 2, 'yellow', TEXTS.flagCode80[state.code80] or state.code80, TEXTS.flagCode80Line,
        restartText() or TEXTS.flagRaceControl }
    end
    if Flags.exitLine then
      if yellow then yellow[5] = Flags.exitLine
      else yellow = { 2, 'yellow', TEXTS.exitTitle, TEXTS.exitLine1, Flags.exitLine } end
    end
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
    local g, cause = sim.raceFlagType, sim.raceFlagCause
    if cause and cause >= 0 and CarRead.isStaff(cause) then g = nil end
    if g == ac.FlagType.Caution and not yellow then
      yellow = { 2, 'yellow', TEXTS.flagYellow, TEXTS.flagYellowLine,
        cause and cause >= 0 and string.format(TEXTS.flagCausedBy, carTag(cause)) or '' }
      Flags.localYellow = true
    end
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
    local top = red or yellow
    if Flags.lastGroup and Flags.lastGroup <= 2 and not top then Flags.greenUntil = clock + cfg.greenSeconds end
    Flags.lastGroup = top and top[1] or nil
    if not normal and clock < (Flags.srGoUntil or 0) then
      normal = { 5, 'green', TEXTS.srGo, TEXTS.srGoLine, '', nil, true }
    end
    if not normal and clock < Flags.greenUntil then
      normal = { 5, 'green', TEXTS.flagGreen, TEXTS.flagGreenLine, '' }
    end
    local st = Start.flag() or (Flags.formationFlag and Flags.formationFlag(car))
    local osl = Flags.officialStartLine and Flags.officialStartLine()
    if osl and not st then st = { 2, 'start', TEXTS.osTitle, osl, '' } end
    if st and st[1] == 2 and not yellow then yellow = st end
    if st and st[1] == 5 then normal = st end
    if not red and not yellow and Flags.parkedFlag then yellow = Flags.parkedFlag() end
    local f = red or yellow or info or normal
    if not f then return nil end
    return { group = f[1], kind = f[2], title = f[3], line1 = f[4], line2 = f[5], alert = f[6], lights = f[7] }
  end
  local RED_PASS_SPLINE = 0.02
  local RED_MOVING_KMH = 10
  local function passAllowed(i, c)
    local kmh = CarRead.num(c.speedKmh)
    if kmh <= RED_MOVING_KMH then return true end
    if kmh >= config.flags.passSlowKmh then return false end
    local len = tonumber(sim.trackLengthM) or 0
    local nearest = math.huge
    for j = 1, (sim.carsCount or 1) - 1 do
      local o = ac.getCar(j)
      if j ~= i and o and o.isConnected and not o.isInPitlane and not CarRead.isStaff(j) then
        nearest = math.min(nearest, ((CarRead.num(o.splinePosition) - CarRead.num(c.splinePosition)) % 1) * len)
      end
    end
    return nearest > config.flags.passFarM
  end
  local function sideOf(car, c)
    local d = CarRead.num(car.splinePosition) - CarRead.num(c.splinePosition)
    if d > 0.5 then d = d - 1 elseif d < -0.5 then d = d + 1 end
    return d
  end
  local function exitQueue(car)
    if not state.postRed or not car.isInPitlane or sim.raceSessionType ~= ac.SessionType.Race
        or Rules.dsqOn() then
      Flags.exitLine, Flags.exitWait = nil, nil
      return
    end
    local k, aheadI = restartPlace()
    local wait = false
    if k and aheadI then
      local c = ac.getCar(aheadI)
      wait = c ~= nil and c.isConnected and (CarRead.parked(c) or (c.isInPitlane and sideOf(car, c) > 0))
    end
    if CarRead.parked(car) then
      if wait ~= Flags.exitWait then
        ac.log(string.format('race-control: race restart pit exit: %s', wait and ('waits for car ' .. aheadI)
          or 'leaves now'))
      end
      Flags.exitWait = wait and aheadI or false
      Flags.exitLine = wait and string.format(TEXTS.exitWait, carTag(aheadI))
        or (aheadI and TEXTS.exitGo or TEXTS.exitFirst)
    elseif Flags.exitWait ~= nil then
      if Flags.exitWait then
        ac.log('race-control: race restart: left the pits before car ' .. Flags.exitWait .. ' passed')
        rcLog(TEXTS.rc.raceRestart, string.format(TEXTS.exitEarlyLog, carTag(Flags.exitWait)))
        Rules.penalty('PX', config.restart.jumpLaps)
      end
      Flags.exitLine, Flags.exitWait = nil, nil
    end
  end
  local yellowSide = {}
  local function yellowRules(car)
    if state.redFlag or Rules.dsqOn() then
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
      if c and c.isConnected and not c.isInPitlane and not car.isInPitlane and not CarRead.isStaff(i) then
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
    if not state.redFlag or Rules.dsqOn() then
      redSide = {}
      Flags.redOver, Flags.redOverSince, Flags.redPrevLane = false, nil, nil
      return
    end
    if lineFrame and car.isInPitlane and state.redCommitted then
      state.redCommitted = nil
      Flags.redReceived = true
      ac.log('race-control: drive-through concluded at the line in the pit lane; red flag received at this line')
      rcLog(TEXTS.rc.red, 'received at the line in the pit lane, drive-through concluded')
    elseif lineFrame and car.isInPitlane then
      ac.log('race-control: DSQ, line crossed in the pit lane with the red flag (leaving the pits)')
      carDsq(1, TEXTS.redFlagLineDsq)
      return
    elseif lineFrame and not Flags.redReceived then
      Flags.redReceived = true
      ac.log('race-control: red flag received at the line on track')
      rcLog(TEXTS.rc.red, 'received at the line on track')
    elseif lineFrame then
      ac.log('race-control: DSQ, line crossed again on track with the red flag (did not go to the pits)')
      carDsq(1, TEXTS.redFlagLineAgainDsq)
      return
    end
    local grace = state.ui.clock - (Flags.redSince or state.ui.clock) < config.flags.redGraceSeconds
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
      if c and c.isConnected and not c.isInPitlane and not car.isInPitlane and not CarRead.isStaff(i) then
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
          rcLog(TEXTS.rc.dsq, string.format(TEXTS.redFlagPassDsq, carTag(i)))
          carDsq(1, string.format(TEXTS.redFlagPassDsq, carTag(i)))
          return
        end
        redSide[i] = side
      else
        redSide[i] = nil
      end
    end
  end
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
      rcLog(TEXTS.rc.lastLap, string.format('lap %d - %.0f s left, best last sector %.1f s', car.lapCount + 2, left / 1000,
        lastSector / 1000))
    end
  end
  local function leaderLaps()
    for i = 0, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and (i == 0 or c.isConnected) and CarRead.num(c.racePosition) == 1 and not CarRead.isStaff(i) then return CarRead.num(c.lapCount) end
    end
    return nil
  end
  function Flags.sessionReset()
    Flags.endSession, Flags.ending, Flags.overLeader, Flags.prevPitlane, Flags.prevSp = nil, nil, nil, nil, nil
    Flags.lastLap, Flags.lastLapSession, Flags.sector, Flags.greenUntil, Flags.lastGroup = nil, nil, nil, 0, nil
    if Flags.parkedReset then Flags.parkedReset() end
  end
  local function sessionEnd(car, lineFrame)
    if Flags.endSession ~= sim.currentSessionIndex then
      Flags.endSession, Flags.ending, Flags.overLeader, Flags.prevPitlane = sim.currentSessionIndex, nil, nil, nil
    end
    local enteredPit = car.isInPitlane and Flags.prevPitlane == false
    Flags.prevPitlane = car.isInPitlane
    local sp = CarRead.num(car.splinePosition)
    local crossedLine = Flags.prevSp ~= nil and Flags.prevSp > 0.9 and sp < 0.1 and not car.isInPitlane
    Flags.prevSp = sp
    lineFrame = lineFrame or crossedLine
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
    if now == 'timeOver' or now == 'raceOver' then
      local startedNow = was ~= now
      if (startedNow and car.isInPitlane) or (not startedNow and (lineFrame or enteredPit)) then
        now = 'finished'
      end
    end
    if now ~= was then
      Flags.ending = now
      if now then rcLog(TEXTS.rc.sessionEnd, now) end
    end
  end
  local START_LIGHTS_FROM = 22
  function Flags.startLights(car)
    if Start.phase then return nil end
    if sim.raceSessionType ~= ac.SessionType.Race or sim.isSessionStarted then return nil end
    if CarRead.num(car.racePosition) < START_LIGHTS_FROM then return nil end
    local t = CarRead.num(sim.timeToSessionStart)
    if t <= 0 or t > 5000 then return nil end
    return math.min(5, 6 - math.ceil(t / 1000))
  end
  local RED_TRACK_EVENT = 'race-control.redflag'
  local function redPit(car)
    local up = state.redFlag ~= nil
    if Flags.redWasUp and not up and not car.isInPitlane and not Flags.onGrid
        and not Rules.dsqOn() then
      ac.log('race-control: DSQ, not in the pits at the restart after the red flag')
      carDsq(1, TEXTS.redFlagNoPitDsq)
    end
    if up ~= Flags.redWasUp then state.redFuelOk = false end
    if up and not Flags.redWasUp then
      Flags.redSince, Flags.redReceived = state.ui.clock, false
      local head = state.list.items[1]
      state.redCommitted = (car.isInPitlane and PitStops.pass ~= nil and PitStops.pass.entryMs ~= nil
        and not PitStops.pass.stopped and head ~= nil and head.kind:sub(1, 2) ~= 'SG') or nil
      if state.redCommitted then
        ac.log('race-control: red flag with the car in the pit lane serving a drive-through: it concludes at the line')
      end
    end
    if not up then state.redCommitted = nil end
    Flags.redWasUp = up
    local ev = up and 'on' or 'off'
    if ev ~= Flags.redSent or (up and state.ui.clock - Flags.redSentT >= 2) then
      Flags.redSent, Flags.redSentT = ev, state.ui.clock
      ac.broadcastSharedEvent(RED_TRACK_EVENT, ev)
    end
    local lt = state.lights and state.lights:lower() or 'auto'
    if lt ~= Flags.lightsSent or (state.lights and state.ui.clock - Flags.lightsSentT >= 2) then
      Flags.lightsSent, Flags.lightsSentT = lt, state.ui.clock
      ac.broadcastSharedEvent('race-control.lights', lt)
    end
    local ownLock = state.pitService or Rules.dsqOn()
    if up and CarRead.parked(car) and not ownLock then
      if not Flags.redLocked or state.ui.clock >= Flags.redLockT then
        physics.lockUserControlsFor(3)
        Flags.redLocked, Flags.redLockT = true, state.ui.clock + 2
      end
    elseif Flags.redLocked and not up then
      Flags.redLocked = false
      if not ownLock and not state.restart then physics.lockUserControlsFor(0) end
      rcLog(TEXTS.rc.red, 'controls released at the pit place')
    end
    if state.redTow and not up then
      local rt = state.redTow
      state.redTow = nil
      applyTowHold(rt.tow, rt.damage, TEXTS.towReason)
      PitRecord.save()
    end
  end
  function Flags.update(car, lineFrame)
    if CarRead.isStaff(0) then
      sessionEnd(car, lineFrame)
      Flags.current = pick(car)
      return
    end
    redPit(car)
    if Flags.hudOff ~= sim.currentSessionIndex or state.ui.clock >= (Flags.hudT or 0) then
      Flags.hudOff, Flags.hudT = sim.currentSessionIndex, state.ui.clock + 5
      ac.disableExtraHUDElements('sessionTime', true)
      ac.disableExtraHUDElements('startingLights', true)
    end
    sessionEnd(car, lineFrame)
    lastLapCheck(car)
    publish(car)
    redRules(car, lineFrame)
    restartUpdate()
    exitQueue(car)
    if Flags.standingUpdate then Flags.standingUpdate(car) end
    if Flags.parkedUpdate then Flags.parkedUpdate(car) end
    if Flags.formationUpdate then Flags.formationUpdate(car) end
    yellowRules(car)
    Flags.current = pick(car)
  end
end
do
  local TRACK_EVENT = 'race-control.restart'
  Flags.sr = {}
  Flags.onGrid, Flags.srGoUntil = false, 0
  local function reset(t0)
    Flags.sr = { t0 = t0, placed = false, released = false, go = false, jumped = false, gridPos = nil, k = nil,
      sent = Flags.sr.sent, sentT = Flags.sr.sentT or -1e9, lockT = -1e9, goT = nil, relPos = nil, relLook = nil,
      creep = 0 }
  end
  local function randomDelay(t0)
    local c = config.restart
    local x = ((math.floor(t0) % 100000) * 16807 + 12345) % 2147483647 / 2147483647
    return c.randomMin + (c.randomMax - c.randomMin) * x
  end
  local function timeline(t0, start)
    local c = config.restart
    local gridAt = start and 0 or c.gridDelay * 1000
    local lightsAt = start and 0 or gridAt + c.gridSeconds * 1000
    local step = c.stepSeconds * 1000
    local lastAt = lightsAt + (c.lights - 1) * step
    return gridAt, lightsAt, step, lastAt + randomDelay(t0) * 1000
  end
  local function lit(d, lightsAt, step)
    if d < lightsAt then return 0 end
    return math.min(config.restart.lights, math.floor((d - lightsAt) / step) + 1)
  end
  local function send(ev)
    local sr = Flags.sr
    if ev ~= sr.sent or state.ui.clock - (sr.sentT or -1e9) >= 2 then
      if ev ~= sr.sent then ac.log('race-control: standing restart: track told ' .. ev) end
      sr.sent, sr.sentT = ev, state.ui.clock
      ac.broadcastSharedEvent(TRACK_EVENT, ev)
    end
  end
  local function ownLock() return state.pitService or Rules.dsqOn() end
  local function place(k)
    k = k or Flags.restartPlace()
    if not k then return end
    local node = ac.findNodes('AC_START_' .. (k - 1))
    local m = node and node:size() > 0 and node:getWorldTransformationRaw()
    local pos = m and m.position
    if not pos then
      ac.log('race-control: standing restart: ' .. string.format(TEXTS.srNoNode, k - 1))
      rcLog(TEXTS.rc.standingRestart, string.format(TEXTS.srNoNode, k - 1))
      return
    end
    physics.setCarPosition(0, pos, nil)
    Flags.sr.gridPos, Flags.sr.k = { x = pos.x, y = pos.y, z = pos.z }, k
    Flags.onGrid = true
    ac.log(string.format('race-control: standing restart: grid place P%d (AC_START_%d)', k, k - 1))
    rcLog(TEXTS.rc.standingRestart, string.format('grid place P%d', k))
  end
  function Flags.placeOnGrid(k) place(k) end
  local function forward(pos, from, look)
    local lx, lz = look.x or 0, look.z or 0
    local n = math.sqrt(lx * lx + lz * lz)
    if n < 1e-6 then return 0 end
    return (((pos.x or 0) - from.x) * lx + ((pos.z or 0) - from.z) * lz) / n
  end
  function Flags.standingUpdate(car)
    local r = state.restart
    local sr = Flags.sr
    local clock = state.ui.clock
    if not r then
      if sr.t0 and not sr.go then
        ac.log('race-control: standing restart cancelled: red flag again, controls locked')
        rcLog(TEXTS.rc.standingRestart, 'cancelled')
        sr.t0 = nil
        send('off')
      end
      if Flags.onGrid and state.redFlag then
        if clock >= sr.lockT and not ownLock() then
          physics.lockUserControlsFor(3)
          sr.lockT = clock + 2
        end
      elseif Flags.onGrid then
        Flags.onGrid = false
      end
      if sr.go and sr.sent == 'go' and clock - sr.goT > 3 then send('off') end
      if Flags.abortUntil then
        if clock < Flags.abortUntil then
          send('abort')
          return
        end
        Flags.abortUntil = nil
        send('off')
      end
      if not sr.go and Flags.formation and Flags.formation.phase == 'end' and Flags.formation.on() then send('grid') end
      return
    end
    if sr.t0 ~= r.t0 then
      reset(r.t0)
      sr = Flags.sr
      ac.log('race-control: standing restart: command at server time ' .. math.floor(r.t0))
    end
    local c = config.restart
    local d = serverTimeMs() - r.t0
    local gridAt, lightsAt, step, offAt = timeline(r.t0, r.start)
    local releaseAt = lightsAt + (c.releaseLight - 1) * step
    local swap = Flags.mySwapMs ~= nil
    if d >= offAt then
      sr.go, sr.goT = true, clock
      if sr.relPos then
        ac.log(string.format('race-control: standing restart: largest forward movement before the green %.2f m (tolerance %.2f m)',
          sr.creep, config.restart.jumpMeters))
      end
      state.restart = nil
      TrackList.changed()
      Flags.onGrid = false
      Flags.srGoUntil = clock + config.flags.greenSeconds
      if not ownLock() then physics.lockUserControlsFor(0) end
      send('go')
      ac.log('race-control: standing ' .. (r.start and 'start' or 'restart') .. ': lights out, green flag')
      rcLog(r.start and 'Standing start' or 'Standing restart', 'green flag')
      return
    end
    if not sr.placed and d >= gridAt then
      sr.placed = true
      if swap then
        rcLog(TEXTS.rc.standingRestart, 'driver swap: leaves the pit lane at the green')
      elseif not Rules.dsqOn() and ((car.isInPitlane and not r.start) or Flags.onGrid) then
        place(r.start and r.k or nil)
      end
    end
    if (d < releaseAt or swap or not Flags.onGrid) and not ownLock() then
      if clock >= sr.lockT then
        physics.lockUserControlsFor(3)
        sr.lockT = clock + 2
      end
    elseif not sr.released then
      sr.released = true
      if not ownLock() then physics.lockUserControlsFor(0) end
      if car.position and car.look then
        sr.relPos = { x = car.position.x, z = car.position.z }
        sr.relLook = { x = car.look.x, z = car.look.z }
      end
      ac.log(string.format('race-control: standing restart: controls free at light %d', c.releaseLight))
    end
    local moved = Flags.onGrid and sr.relPos and car.position and forward(car.position, sr.relPos, sr.relLook) or 0
    sr.creep = math.max(sr.creep or 0, moved)
    if Flags.onGrid and sr.relPos and not sr.jumped and moved > c.jumpMeters then
      sr.jumped = true
      ac.log(string.format('race-control: standing restart: jump start (%.2f m forward before the lights went out)', moved))
      Rules.penalty(r.start and 'JSS' or 'JS', c.jumpLaps)
    end
    local n = lit(d, lightsAt, step)
    if n > 0 then
      send('lights:' .. n)
    elseif lightsAt - d <= c.prestartSeconds * 1000 then
      send('prestart')
    else
      send('grid')
    end
  end
  function Flags.standingFlag(car)
    local r = state.restart
    if not r then return nil end
    local c = config.restart
    local d = serverTimeMs() - r.t0
    local gridAt, lightsAt, step = timeline(r.t0, r.start)
    local releaseAt = lightsAt + (c.releaseLight - 1) * step
    local k = Flags.onGrid and Flags.sr.k
    local line1 = (Flags.mySwapMs and TEXTS.srSwap)
      or (k and string.format(d >= releaseAt and TEXTS.srGridFree or TEXTS.srGrid, k))
      or string.format(TEXTS.srGridSoon, math.max(math.ceil((gridAt - d) / 1000), 0))
    local n = lit(d, lightsAt, step)
    local line2 = (n == 0 and string.format(TEXTS.srLightsIn, math.max(math.ceil((lightsAt - d) / 1000), 0)))
      or (d >= releaseAt and not Flags.mySwapMs and TEXTS.srFree)
      or string.format(TEXTS.srLights, n, c.lights)
    return { 1, 'start', r.start and TEXTS.ssTitle or TEXTS.srTitle, line1, line2 }
  end
  local raceStartLights = Flags.startLights
  function Flags.startLights(car)
    local r = state.restart
    local k = Flags.onGrid and Flags.sr.k
    if r and Flags.sr.t0 == r.t0 and k and k >= config.restart.screenLightsFrom then
      local _, lightsAt, step = timeline(r.t0, r.start)
      local n = lit(serverTimeMs() - r.t0, lightsAt, step)
      if n > 0 then return n end
    end
    return raceStartLights(car)
  end
  local os_ = { session = nil }
  local function osReset(idx)
    os_ = { session = idx, lockT = -1e9, held = false, released = false, relPos = nil, relLook = nil, jumped = false,
      creep = 0, startLogged = false }
  end
  local lastGame = nil
  function Flags.officialStart(car, g)
    local gameNow = tostring(g.t) .. '/' .. tostring(g.p)
    if gameNow ~= lastGame then
      if lastGame then ac.log('race-control: game penalty ' .. lastGame .. ' -> ' .. gameNow) end
      lastGame = gameNow
    end
    local gp = tonumber(g.p) or 0
    local dtGame = g.t == GAME_DT and gp > 0 and not state.hold and not PitRecord.holdOver()
    if dtGame then
      physics.setCarPenalty(MANDATORY_PITS, 0)
      if not Flags.dtTaking then
        ac.log(string.format('race-control: drive-through of the game taken out (%s, session %s)', gameNow,
          sim.isSessionStarted and 'started' or 'not started'))
        rcLog(TEXTS.rc.start, TEXTS.gameDtTaken)
      end
    end
    Flags.dtTaking = dtGame
    local idx = sim.currentSessionIndex
    if os_.session ~= idx then osReset(idx) end
    if Flags.formation and Flags.formation.on() then return end
    local c = config.restart
    local race = sim.raceSessionType == ac.SessionType.Race
    local t = CarRead.num(sim.timeToSessionStart)
    local before = race and not sim.isSessionStarted and t > 0
    if not before or car.isInPitlane or state.restart or Flags.onGrid then
      if os_.held and not os_.startLogged then
        os_.startLogged = true
        if not ownLock() then physics.lockUserControlsFor(0) end
        ac.log(string.format('race-control: race start: green (largest forward movement %.2f m, tolerance %.2f m)',
          os_.creep, c.jumpMeters))
      end
      return
    end
    local releaseMs = (c.lights - c.releaseLight + 1) * c.stepSeconds * 1000
    if t > releaseMs then
      if not ownLock() and state.ui.clock >= os_.lockT then
        physics.lockUserControlsFor(3)
        os_.lockT = state.ui.clock + 2
        if not os_.held then
          os_.held = true
          ac.log(string.format('race-control: race start: controls locked on the grid (%.1f s to the start)', t / 1000))
        end
      end
      return
    end
    if not os_.released then
      os_.released = true
      if not ownLock() then physics.lockUserControlsFor(0) end
      if car.position and car.look then
        os_.relPos = { x = car.position.x, z = car.position.z }
        os_.relLook = { x = car.look.x, z = car.look.z }
      end
      ac.log(string.format('race-control: race start: controls free at light %d', c.releaseLight))
    end
    local moved = os_.relPos and car.position and forward(car.position, os_.relPos, os_.relLook) or 0
    os_.creep = math.max(os_.creep, moved)
    if os_.relPos and not os_.jumped and moved > c.jumpMeters then
      os_.jumped = true
      ac.log(string.format('race-control: race start: jump start (%.2f m forward before the start)', moved))
      Rules.penalty('JSS', c.jumpLaps)
    end
  end
  function Flags.officialStartLine()
    if not os_.held or os_.startLogged or os_.released then return nil end
    local c = config.restart
    return string.format(TEXTS.osLocked, string.format(TEXTS.osLockedLight, c.releaseLight))
  end
end
do
  local P = { count = 0, slowT = nil, fuelStop = false, fuelInvalid = false, invLap = nil, elapsed = 0, detected = false,
    armed = false, hist = {}, odo = 0, last = nil }
  local JUMP_M = 50
  local ARM_KMH = 30
  function Flags.parkedReset()
    P.count, P.slowT, P.fuelStop, P.fuelInvalid, P.invLap, P.elapsed, P.detected, P.armed = 0, nil, false, false, nil, 0, false, false
    P.hist, P.odo, P.last = {}, 0, nil
    Flags.parkedLine = nil
  end
  local function watched(car)
    return P.armed and sim.isSessionStarted and not car.isInPitlane and not car.isInPit and not CarRead.parked(car) and not state.hold
      and not state.redFlag and not state.restart
      and not Flags.onGrid and Flags.ending ~= 'finished' and not Rules.dsqOn()
  end
  local function detection(car)
    local rule = config.parkedCar
    if state.repair.class == 'beyond' then
      ac.log('race-control: car stopped on track: broken (beyond the safety limit), no penalty')
      return
    end
    if CarRead.num(car.fuel) <= 0.1 then
      if P.fuelStop then return end
      P.fuelStop = true
      if sim.raceSessionType == ac.SessionType.Race then
        ac.log(string.format('race-control: car stopped on track out of fuel: %d s added to the final time', rule.fuelRaceSeconds))
        rcLog(TEXTS.rc.timePenalty, string.format(TEXTS.parkedTimeLog, rule.fuelRaceSeconds))
        showNotice(TEXTS.rcTitle, string.format(TEXTS.parkedFuelRace, rule.fuelRaceSeconds))
      else
        P.fuelInvalid = true
        ac.log('race-control: car stopped on track out of fuel: laps invalid from now on')
        rcLog(TEXTS.rc.parked, TEXTS.parkedFuelLapsLog)
        showNotice(TEXTS.rcTitle, TEXTS.parkedFuelLaps)
      end
      return
    end
    P.count = P.count + 1
    ac.log(string.format('race-control: car stopped on track on purpose: stop %d of %d tolerated', P.count, rule.grace))
    rcLog(TEXTS.rc.parked, string.format(TEXTS.parkedLog, P.count, rule.grace))
    if P.count > rule.grace then
      ac.log('race-control: DSQ, car stopped on track over the stops tolerated')
      carDsq(1, TEXTS.parkedDsq, nil, string.format(TEXTS.parkedDsqDetail, rule.grace, rule.seconds))
    end
  end
  function Flags.parkedUpdate(car)
    local rule = config.parkedCar
    if P.fuelInvalid then
      if sim.raceSessionType == ac.SessionType.Practice and CarRead.parked(car) then
        P.fuelInvalid = false
        ac.log('race-control: practice, car at its pit place: laps valid again')
      elseif P.invLap ~= car.lapCount then
        P.invLap = car.lapCount
        physics.setCarFuel(0, car.fuel)
        ac.log('race-control: lap invalid (out of fuel on track)')
      end
    end
    Flags.parkedLine = nil
    if car.isInPitlane or car.isInPit or CarRead.parked(car) then P.armed = false
    elseif not P.armed and CarRead.num(car.speedKmh) > ARM_KMH then P.armed = true end
    if rule.grace < 0 or not watched(car) or not car.position then
      P.slowT, P.elapsed, P.detected, P.hist, P.last = nil, 0, false, {}, nil
      return
    end
    local clock = state.ui.clock
    local pos = car.position
    local kmh = CarRead.num(car.speedKmh)
    if P.last then
      local d = math.sqrt((pos.x - P.last.x) ^ 2 + (pos.z - P.last.z) ^ 2)
      if d < JUMP_M or d <= kmh / 3.6 * (clock - P.last.t) + JUMP_M then P.odo = P.odo + d end
    end
    P.last = { x = pos.x, z = pos.z, t = clock }
    P.hist[#P.hist + 1] = { t = clock, odo = P.odo }
    while #P.hist > 2 and P.hist[2].t <= clock - rule.seconds do table.remove(P.hist, 1) end
    local first = P.hist[1]
    local stopped = first.t <= clock - rule.seconds and P.odo - first.odo < rule.distance and kmh <= ARM_KMH
    if not stopped then
      P.slowT, P.elapsed, P.detected, P.fuelStop = nil, 0, false, false
      return
    end
    if P.detected then return end
    P.slowT = P.slowT or clock
    P.elapsed = clock - P.slowT
    if P.elapsed >= rule.moveSeconds then
      P.detected = true
      detection(car)
      return
    end
    if state.repair.class ~= 'beyond' and CarRead.num(car.fuel) > 0.1 and not Rules.dsqOn() then
      Flags.parkedLine = { string.format(TEXTS.parkedMove, math.max(math.ceil(rule.moveSeconds - P.elapsed), 0)),
        rule.grace > 0 and string.format(TEXTS.parkedLeft, math.max(rule.grace - P.count, 0), rule.grace) or TEXTS.parkedNoGrace }
    end
  end
  function Flags.parkedFlag()
    local l = Flags.parkedLine
    if not l then return nil end
    return { 2, 'yellow', TEXTS.parkedFlagTitle, l[1], l[2], false }
  end
end
local Formation = { phase = nil, session = nil, locked = {}, leader = nil, prog = 0, lastSp = nil, endT = nil,
  overSince = nil, slowSince = nil, overDone = false, slowDone = false, giveBack = {}, side = {}, k = nil,
  aligned = false, t0 = nil, t0Sent = -1e9, firstAligned = nil, pitStart = false, missed = false, lockT = 0,
  armed = false,
  trackSent = 'off', trackT = -1e9, goT = nil }
do
  local ALIGNED_METERS, ALIGNED_KMH = 3, 1
  local T0_RESEND = 2
  local T0_AFTER_ALL_MS = 2000
  local FALLBACK_SECONDS = 20
  local PASS_SPLINE = 0.02
  local TRACK_EVENT = 'race-control.start'
  local sendT0 = ac.OnlineEvent({
    ac.StructItem.key('amxracing.race-control.start'),
    startMs = ac.StructItem.uint32(),
  }, function(sender, msg)
    if sender and sender.index ~= 0 and Formation.phase == 'end' and not Formation.t0 then
      Formation.t0 = tonumber(msg.startMs)
      ac.log('race-control: standing start: lights at session time ' .. math.floor(Formation.t0) .. ' (from car ' .. sender.index .. ')')
    end
  end, nil, nil, { processPostponed = true })
  local function rule() return config.formation end
  function Formation.on()
    local p = rule().procedure
    return (p == 'ROLLING' or p == 'STANDING') and sim.raceSessionType == ac.SessionType.Race
  end
  local function reset(idx)
    Formation.phase, Formation.session, Formation.locked, Formation.leader = nil, idx, {}, nil
    Formation.prog, Formation.lastSp, Formation.endT = 0, nil, nil
    Formation.overSince, Formation.slowSince, Formation.overDone, Formation.slowDone = nil, nil, false, false
    Formation.giveBack, Formation.side, Formation.k, Formation.aligned = {}, {}, nil, false
    Formation.t0, Formation.t0Sent, Formation.firstAligned = nil, -1e9, nil
    Formation.pitStart, Formation.missed, Formation.lockT, Formation.goT = false, false, 0, nil
    Formation.armed = false
  end
  local function tag(i) return string.format('#%s', tostring(ac.getDriverNumber(i) or i)) end
  local function lapLen() return tonumber(sim.trackLengthM) or 0 end
  local function gapM(a, b) return ((CarRead.num(b.splinePosition) - CarRead.num(a.splinePosition)) % 1) * lapLen() end
  local function byPlace()
    local out = {}
    for i, p in pairs(Formation.locked) do out[p] = i end
    return out
  end
  local function alive(i)
    local c = ac.getCar(i)
    return c and (i == 0 or c.isConnected) and c or nil
  end
  local function firstConnected()
    local best, bi = math.huge, nil
    for i, p in pairs(Formation.locked) do
      if alive(i) and p < best then best, bi = p, i end
    end
    return bi
  end
  local function penalty(cat, laps, text)
    ac.log('race-control: formation lap: ' .. text)
    Rules.penalty(cat, laps)
  end
  local function passAllowed(i, p, at)
    local r = rule()
    local c = alive(i)
    if not c then return true end
    local kmh = CarRead.num(c.speedKmh)
    if p == 1 then return kmh < r.leaderSlowKmh end
    local prev = at[p - 1] and alive(at[p - 1])
    if not prev then return true end
    local gap = gapM(c, prev)
    return gap > r.passFarM or (kmh < r.slowFarKmh and gap > r.slowFarM)
  end
  local function lapRules(car)
    local r = rule()
    local clock = state.ui.clock
    if car.isInPitlane or Rules.dsqOn() then
      Formation.overSince, Formation.slowSince, Formation.giveBack, Formation.side = nil, nil, {}, {}
      return
    end
    local kmh = CarRead.num(car.speedKmh)
    if kmh > r.maxKmh then
      Formation.overSince = Formation.overSince or clock
      if not Formation.overDone and clock - Formation.overSince > r.overSeconds then
        Formation.overDone = true
        penalty('FS', r.speedLaps, string.format('over %d km/h for more than %d s', r.maxKmh, r.overSeconds))
      end
    else
      Formation.overSince = nil
    end
    if kmh < r.minKmh then
      Formation.slowSince = Formation.slowSince or clock
      if not Formation.slowDone and clock - Formation.slowSince > r.slowSeconds then
        Formation.slowDone = true
        penalty('FL', r.slowLaps, string.format('under %d km/h for more than %d s', r.minKmh, r.slowSeconds))
      end
    else
      Formation.slowSince = nil
    end
    local me = Formation.locked[0]
    if not me then return end
    local at = byPlace()
    for i, t in pairs(Formation.giveBack) do
      local c = alive(i)
      local d = c and (CarRead.num(car.splinePosition) - CarRead.num(c.splinePosition)) or 0
      if d > 0.5 then d = d - 1 elseif d < -0.5 then d = d + 1 end
      if not c or c.isInPitlane then
        Formation.giveBack[i] = nil
      elseif d < 0 then
        Formation.giveBack[i] = nil
        ac.log(string.format('race-control: formation lap: place given back to car %d', i))
        showNotice(TEXTS.rcTitle, string.format(TEXTS.fmGivenBack, tag(i)))
      elseif clock - t >= r.giveBackSeconds then
        Formation.giveBack[i] = nil
        penalty('FP', r.passLaps, string.format('car %d passed and the place not given back in %d s', i, r.giveBackSeconds))
      end
    end
    for i, p in pairs(Formation.locked) do
      local c = alive(i)
      if i ~= 0 and p < me and c and not c.isInPitlane then
        local d = CarRead.num(car.splinePosition) - CarRead.num(c.splinePosition)
        if d > 0.5 then d = d - 1 elseif d < -0.5 then d = d + 1 end
        local side = d > 0 and 1 or -1
        if Formation.side[i] == -1 and side == 1 and math.abs(d) < PASS_SPLINE and not Formation.giveBack[i] then
          if passAllowed(i, p, at) then
            ac.log(string.format('race-control: formation lap: car %d passed, allowed (the exceptions of the KMR)', i))
          else
            Formation.giveBack[i] = clock
            showNotice(TEXTS.rcTitle, string.format(TEXTS.fmGiveBack, tag(i), r.giveBackSeconds))
          end
        end
        Formation.side[i] = side
      end
    end
  end
  local function slotPos(k)
    local node = k and ac.findNodes('AC_START_' .. (k - 1))
    local m = node and node:size() > 0 and node:getWorldTransformationRaw()
    return m and m.position
  end
  local function dist(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2) end
  local function align(car)
    local r = rule()
    local clock = state.ui.clock
    if not Formation.aligned and not Formation.pitStart and not car.isInPitlane and Formation.k then
      local pos = slotPos(Formation.k)
      if pos and car.position and dist(car.position, pos) <= r.alignMeters and CarRead.num(car.speedKmh) <= r.alignKmh then
        Flags.placeOnGrid(Formation.k)
        Formation.aligned = true
        rcLog(TEXTS.rc.standingStart, string.format('aligned on grid place P%d', Formation.k))
      end
    end
    if Formation.aligned and not state.restart and not (state.pitService or Rules.dsqOn()) then
      if clock >= Formation.lockT then
        physics.lockUserControlsFor(3)
        Formation.lockT = clock + 2
      end
    end
    if Formation.t0 or state.restart then return end
    if firstConnected() == 0 then
      local all, any = true, false
      for i, p in pairs(Formation.locked) do
        local c = alive(i)
        if c and not c.isInPitlane then
          local pos = slotPos(p)
          local ok = (i == 0 and Formation.aligned)
            or (i ~= 0 and pos and c.position and dist(c.position, pos) <= ALIGNED_METERS and CarRead.num(c.speedKmh) <= ALIGNED_KMH)
          if ok then any = true else all = false end
        end
      end
      if any and not Formation.firstAligned then Formation.firstAligned = serverTimeMs() end
      local now = serverTimeMs()
      local t0 = (all and any and now + T0_AFTER_ALL_MS)
        or (Formation.firstAligned and now >= Formation.firstAligned + r.alignSeconds * 1000 and now)
      if t0 then
        Formation.t0 = t0
        ac.log(string.format('race-control: standing start: lights at session time %d (%s)', math.floor(t0),
          all and 'every car aligned' or 'line-up time over'))
      end
    elseif Formation.endT and clock - Formation.endT > r.alignSeconds + FALLBACK_SECONDS then
      Formation.t0 = serverTimeMs()
      ac.log('race-control: standing start: no time from the leader, lights now')
    end
  end
  function Formation.startNow(t0)
    if Formation.phase ~= 'end' or Formation.t0 or state.restart then return false end
    Formation.t0 = t0 or serverTimeMs()
    ac.log('race-control: standing start: lights by the race direction at session time ' .. math.floor(Formation.t0))
    rcLog(TEXTS.rc.standingStart, 'start given by the race direction')
    return true
  end
  function Formation.abort(reason)
    if not Formation.on() or (Formation.phase ~= 'lap' and Formation.phase ~= 'end') then return false end
    Formation.t0, Formation.t0Sent, Formation.armed, Formation.goT = nil, -1e9, false, nil
    Formation.endT, Formation.aligned, Formation.firstAligned = nil, false, nil
    Formation.prog, Formation.lastSp = 0, nil
    Formation.phase = 'lap'
    state.restart = nil
    Flags.abortUntil = state.ui.clock + config.restart.abortSeconds
    ac.log('race-control: standing start aborted by the race direction: formation lap again')
    rcLog(TEXTS.rc.standingStart, 'start aborted - formation lap again' .. (reason and reason ~= '' and (' - ' .. reason) or ''))
    return true
  end
  local function trackTell()
    local ev = 'off'
    if rule().procedure == 'ROLLING' and (Formation.phase == 'pre' or Formation.phase == 'lap') then ev = 'hold:rolling' end
    if Formation.goT and state.ui.clock - Formation.goT < config.flags.greenSeconds then ev = 'go' end
    if ev ~= Formation.trackSent or (ev ~= 'off' and state.ui.clock - Formation.trackT >= 2) then
      Formation.trackSent, Formation.trackT = ev, state.ui.clock
      ac.broadcastSharedEvent(TRACK_EVENT, ev)
    end
  end
  function Flags.formationUpdate(car)
    local idx = sim.currentSessionIndex
    if Formation.session ~= idx then reset(idx) end
    if not Formation.on() then
      if Formation.phase then reset(idx) end
      return
    end
    local r = rule()
    trackTell()
    if not sim.isSessionStarted then
      Formation.phase = 'pre'
      return
    end
    if Formation.phase == nil or Formation.phase == 'pre' then
      Formation.phase = 'lap'
      local list = {}
      for i = 0, (sim.carsCount or 1) - 1 do
        local c = alive(i)
        if c and CarRead.num(c.racePosition) > 0 and not CarRead.isStaff(i) then list[#list + 1] = { i = i, p = CarRead.num(c.racePosition) } end
      end
      table.sort(list, function(a, b) return a.p < b.p end)
      for k, x in ipairs(list) do Formation.locked[x.i] = k end
      Formation.k = Formation.locked[0]
      Formation.leader = firstConnected()
      Formation.prog, Formation.lastSp = 0, nil
      ac.log(string.format('race-control: formation lap (%s): order locked, place P%s', r.procedure, tostring(Formation.k)))
      rcLog(TEXTS.rc.formation, string.format('%s - place P%s', r.procedure, tostring(Formation.k)))
    end
    if Formation.phase == 'lap' then
      lapRules(car)
      Formation.leader = firstConnected()
      local lc = Formation.leader and alive(Formation.leader)
      local sp = lc and CarRead.num(lc.splinePosition)
      local crossed = false
      if sp then
        if Formation.lastSp then
          local d = sp - Formation.lastSp
          if d > 0.5 then d = d - 1 elseif d < -0.5 then d = d + 1 end
          if d > 0 and Formation.lastSp > 0.9 and sp < 0.1 and Formation.prog >= 0.5 then crossed = true end
          if r.procedure == 'ROLLING' and d > 0 and sp >= Start.GREEN_SPLINE and Formation.prog >= 0.5 then crossed = true end
          Formation.prog = Formation.prog + math.max(d, 0)
        end
        Formation.lastSp = sp
      end
      if r.procedure == 'ROLLING' and crossed then
        Formation.phase = 'done'
        Formation.goT = state.ui.clock
        Flags.srGoUntil = state.ui.clock + config.flags.greenSeconds
        ac.log(string.format('race-control: rolling start: the leader at %.2f of the lap, green flag', sp))
        rcLog(TEXTS.rc.rollingStart, 'green flag')
      elseif r.procedure == 'STANDING' and lc and Formation.prog >= 0.5 then
        local lp = slotPos(Formation.locked[Formation.leader])
        local left = lp and ((CarRead.num(ac.worldCoordinateToTrackProgress(lp)) - sp) % 1) * lapLen() or 0
        if left <= r.approachM or crossed then
          Formation.phase = 'end'
          Formation.endT = state.ui.clock
          Formation.giveBack, Formation.side = {}, {}
          Formation.pitStart = car.isInPitlane
          ac.log('race-control: standing start: formation lap over, to the grid' .. (Formation.pitStart and ' (start from the pit lane)' or ''))
          rcLog(TEXTS.rc.standingStart, Formation.pitStart and 'start from the pit lane' or 'to the grid')
        end
      end
    end
    if Formation.phase == 'end' then
      align(car)
      if Formation.t0 and firstConnected() == 0 and state.ui.clock - Formation.t0Sent >= T0_RESEND and not state.restart then
        Formation.t0Sent = state.ui.clock
        OnlineQueue.push(sendT0, { startMs = math.floor(Formation.t0) }, nil)
      end
      if Formation.t0 and not state.restart and not Formation.armed then
        Formation.armed = true
        state.restart = { t0 = Formation.t0, start = true, k = Formation.k }
        TrackList.changed()
        ac.log('race-control: standing start: lights')
      end
      if state.restart and state.restart.start and serverTimeMs() >= state.restart.t0 and not Formation.missed then
        Formation.missed = true
        if not Formation.aligned and not car.isInPitlane and not Rules.dsqOn() then
          ac.log('race-control: DSQ, not on the grid place when the start lights began')
          carDsq(1, TEXTS.fmMissedStart)
        end
      end
      if Formation.armed and not state.restart then Formation.phase = 'done' end
    end
  end
  function Flags.formationFlag(car)
    local p = Formation.phase
    if p == 'pre' then
      local left = math.max(math.floor((sim.timeToSessionStart or 0) / 1000), 0)
      if left <= 0 then return nil end
      return { 2, 'start', TEXTS.fmTitle, string.format(TEXTS.fmCountdown, mmss(left)), TEXTS.fmCountdownLine }
    end
    if p ~= 'lap' and p ~= 'end' then return nil end
    local r = rule()
    if p == 'end' then
      if state.restart then return nil end
      local line2 = Formation.pitStart and TEXTS.fmPitStart or (Formation.aligned and string.format(TEXTS.fmAligned, Formation.k or 0))
        or string.format(TEXTS.fmToGrid, Formation.k or 0)
      return { 2, 'start', TEXTS.fmTitle, TEXTS.fmEnd, line2 }
    end
    local at = byPlace()
    local me = Formation.locked[0]
    local line2 = me and string.format(TEXTS.fmPlace, me, at[me - 1] and tag(at[me - 1]) or TEXTS.startLeader) or TEXTS.startNoPlace
    local alert = false
    for i, t in pairs(Formation.giveBack) do
      line2 = string.format(TEXTS.fmGiveBack, tag(i), math.max(math.ceil(r.giveBackSeconds - (state.ui.clock - t)), 0))
      alert = true
      break
    end
    return { 2, 'start', TEXTS.fmTitle, string.format(TEXTS.startLimits, r.maxKmh, r.minKmh), line2, alert }
  end
  Flags.formation = Formation
  state.formationStart = Formation.startNow
  state.formationAbort = Formation.abort
end
local PassMirror = { seq = 0, loaded = 0, last = nil, red = nil }
do
  local FIELDS = 23
  local SPEED_FIELD = 17
  local function flag(v) return v and '1' or '0' end
  local function text(v) return (tostring(v or ''):gsub('|', '/')) end
  local function fields(car)
    local p, sw = PitStops.pass, state.swap
    local lapNow = CarRead.num(car.lapCount)
    return {
      p and p.id or PitStops.line, flag(p), p and p.entryMs and math.floor(p.entryMs) or -1, flag(p and p.jumped),
      flag(p and p.stopped), p and p.stop or 0, text(p and p.raceFlag), text(p and p.driverFlag), text(p and p.service),
      text(p and table.concat(p.paid, ';')), p and p.sgPaid and Rules.itemEncode(p.sgPaid) or '',
      flag(p and p.sgServiced), flag(p and p.sgParked), flag(sw.passSwap) .. flag(sw.passSwapValid) .. flag(sw.passVoided),
      state.pitPaid and Rules.itemEncode(state.pitPaid) or '', flag(PitSpeed.over), math.floor(PitSpeed.maxKmh),
      PitSpeed.entryLap and math.max(lapNow - PitSpeed.entryLap, 0) or -1, flag(state.list.jumped),
      flag(Flags.redReceived), flag(state.redCommitted), math.floor(TrackList.frozenSince or 0), lapNow }
  end
  function PassMirror.update(car)
    local red = PassMirror.red
    if red and state.redFlag and TrackList.frozenSince and math.floor(TrackList.frozenSince) == red.since then
      PassMirror.red = nil
      Flags.redReceived = Flags.redReceived or red.received
      state.redCommitted = state.redCommitted or red.committed or nil
      ac.log('race-control: pass mirror: red flag at the line taken back (received ' .. tostring(Flags.redReceived) .. ')')
    elseif red and not state.redFlag then
      PassMirror.red = nil
    end
    local f = fields(car)
    local key = table.concat(f, '|', 1, SPEED_FIELD - 1) .. '|' .. table.concat(f, '|', SPEED_FIELD + 1)
    if key == PassMirror.last then return end
    PassMirror.last = key
    PassMirror.seq = Record.save('pass', PassMirror.seq + 1, table.concat(f, '|'))
  end
  local function apply(body, seq, source)
    if seq <= PassMirror.loaded then return end
    local f = {}
    for v in (tostring(body) .. '|'):gmatch('([^|]*)|') do f[#f + 1] = v end
    if #f < FIELDS then return end
    PassMirror.loaded = seq
    PassMirror.seq = math.max(PassMirror.seq, seq)
    local shift = Rules.lapShift(f[23])
    if f[19] == '1' then state.list.jumped = true end
    if tonumber(f[22]) ~= 0 then
      PassMirror.red = { received = f[20] == '1', committed = f[21] == '1', since = tonumber(f[22]) }
    end
    if f[2] ~= '1' then return end
    local paid = {}
    for v in f[10]:gmatch('[^;]+') do paid[#paid + 1] = v end
    local entry, stop = tonumber(f[3]), tonumber(f[6])
    PitStops.line = math.max(PitStops.line, tonumber(f[1]) or 0)
    PitStops.pass = { id = tonumber(f[1]), entryMs = entry >= 0 and entry or nil, jumped = f[4] == '1',
      stopped = f[5] == '1', stop = stop ~= 0 and stop or nil, raceFlag = f[7], driverFlag = f[8],
      service = f[9] ~= '' and f[9] or nil, paid = paid, sgPaid = Rules.itemDecode(f[11], shift),
      sgServiced = f[12] == '1' or nil, sgParked = f[13] == '1' or nil, snap = nil }
    local sw = state.swap
    sw.passSwap, sw.passSwapValid, sw.passVoided = f[14]:sub(1, 1) == '1', f[14]:sub(2, 2) == '1', f[14]:sub(3, 3) == '1'
    state.pitPaid = Rules.itemDecode(f[15], shift)
    PitSpeed.over, PitSpeed.maxKmh = f[16] == '1', tonumber(f[17]) or 0
    local lines = tonumber(f[18]) or -1
    PitSpeed.entryLap = lines >= 0 and CarRead.num(ac.getCar(0).lapCount) - lines or nil
    PitStops.wasInPitlane = true
    ac.log(string.format('race-control: pass mirror: pit pass %s taken back (%s, version %d)', f[1], source, seq))
  end
  function PassMirror.load()
    PassMirror.seq, PassMirror.loaded, PassMirror.last, PassMirror.red = 0, 0, nil, nil
    local body, seq, source = Record.load('pass')
    if body then apply(body, seq, source) end
  end
  RecordSync.restorers.pass = function(body, seq) apply(body, seq, 'other drivers') end
end
local RaceTable = { rows = {}, byIndex = {}, order = {}, laps = {}, nextT = 0, stops = {}, passes = {}, seen = {},
  stint = { driver = 0, startMs = -1, parkMs = -1, seq = 0, totals = {} }, stintDone = false, maxDsq = false, minDone = false, prevParked = nil }
do
  local REFRESH = 0.25
  local MAX_LAPS = 600
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
  local SEEN_KEY = 'rc.seen'
  local function seenSave()
    local parts = {}
    for i in pairs(RaceTable.seen) do parts[#parts + 1] = tostring(i) end
    ac.storage[SEEN_KEY] = Record.key() .. '\n' .. table.concat(parts, ';')
  end
  local function seenLoad()
    RaceTable.seen = {}
    local key, body = tostring(ac.storage[SEEN_KEY] or ''):match('^([^\n]*)\n(.*)$')
    if not key or not Record.sameSession(key, Record.key()) then return end
    for i in body:gmatch('%d+') do RaceTable.seen[tonumber(i)] = true end
  end
  local function stopsWatch(c)
    local ps = RaceTable.passes[c.index] or {}
    RaceTable.passes[c.index] = ps
    if c.isInPitlane then
      ps.lane = true
      if CarRead.parked(c) then ps.parked = true end
    elseif ps.lane then
      if ps.parked then
        RaceTable.stops[c.index] = (RaceTable.stops[c.index] or 0) + 1
        stopsSave()
      end
      ps.lane, ps.parked = false, false
    end
  end
  function RaceTable.refresh()
    local session = ac.getSession(sim.currentSessionIndex)
    local board = session and session.leaderboard
    local rows, byIndex, classPos, absent, added = {}, {}, {}, {}, false
    if board then
      for k = 0, #board do
        local e = board[k]
        local c = e and e.car
        if c and not CarRead.isStaff(c.index) then
          stopsWatch(c)
          local cls = RaceTable.classOf(c.index)
          local laps, best = e.laps or 0, e.bestLapTimeMs or 0
          if (c.index == 0 or c.isConnected) and not RaceTable.seen[c.index] then
            RaceTable.seen[c.index], added = true, true
          end
          local r = { index = c.index, class = cls,
            number = ac.getDriverNumber(c.index) or c.index, name = tostring(ac.getDriverName(c.index) or ''),
            team = tostring(ac.getDriverTeam(c.index) or ''), laps = laps, best = best,
            spline = CarRead.num(c.splinePosition), inPit = c.isInPitlane, connected = c.isConnected,
            stops = RaceTable.stops[c.index] or 0 }
          if RaceTable.seen[c.index] or laps > 0 or best > 0 then
            if cls then classPos[cls] = (classPos[cls] or 0) + 1 end
            r.pos, r.classPos = #rows + 1, cls and classPos[cls] or nil
            rows[#rows + 1] = r
          else
            r.absent, r.laps, r.best, r.stops = true, 0, 0, 0
            absent[#absent + 1] = r
          end
          byIndex[c.index] = r
        end
      end
    end
    if added then seenSave() end
    RaceTable.present = #rows
    for _, r in ipairs(absent) do rows[#rows + 1] = r end
    RaceTable.rows, RaceTable.byIndex = rows, byIndex
  end
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
    local parts = {}
    for code, ms in pairs(st.totals) do parts[#parts + 1] = string.format('%d:%d', code, math.floor(ms)) end
    table.sort(parts)
    Record.save('stint', st.seq, string.format('%d|%d|%d|%s', st.driver, math.floor(st.startMs), math.floor(st.parkMs), table.concat(parts, ',')))
  end
  local function stintApply(body, seq)
    local d, s, p, rest = tostring(body or ''):match('^(%d+)|(%-?%d+)|(%-?%d+)|?([%d:,]*)$')
    if not d then return end
    local totals = {}
    for code, ms in rest:gmatch('(%d+):(%d+)') do totals[tonumber(code)] = tonumber(ms) end
    RaceTable.stint = { driver = tonumber(d), startMs = tonumber(s), parkMs = tonumber(p), seq = seq or 0, totals = totals }
  end
  RecordSync.restorers.stint = function(body, seq)
    if not RaceTable.stintDone then stintApply(body, seq) end
  end
  function RaceTable.load()
    lapsApply(Record.load('laps'))
    stopsLoad()
    seenLoad()
    local body, seq = Record.load('stint')
    RaceTable.stint = { driver = 0, startMs = -1, parkMs = -1, seq = 0, totals = {} }
    if body then stintApply(body, seq) end
    RaceTable.stintDone, RaceTable.maxDsq, RaceTable.minDone, RaceTable.prevParked = false, false, false, nil
    RaceTable.passReset()
  end
  function RaceTable.stintMs()
    local st = RaceTable.stint
    if not RaceTable.stintDone or st.startMs < 0 then return nil end
    return serverTimeMs() - st.startMs
  end
  function RaceTable.driveMs()
    local ms = RaceTable.stintMs()
    if not ms then return nil end
    return (RaceTable.stint.totals[RaceTable.stint.driver] or 0) + ms
  end
  local function stintUpdate(car)
    local rule = config.driverStint
    local st = RaceTable.stint
    if not RaceTable.stintDone then
      if not DriverTable.done then return end
      RaceTable.stintDone = true
      local me = nameCode(ac.getDriverName(0))
      if st.driver ~= me then
        local prev = st.driver ~= 0 and st.startMs >= 0 and st.parkMs >= st.startMs and (st.parkMs - st.startMs) or nil
        local totals = st.totals or {}
        if prev then totals[st.driver] = (totals[st.driver] or 0) + prev end
        RaceTable.stint = { driver = me, startMs = serverTimeMs(), parkMs = -1, seq = st.seq, totals = totals }
        stintSave()
      end
    end
    local parked = CarRead.parked(car)
    if parked and RaceTable.prevParked == false then
      RaceTable.stint.parkMs = serverTimeMs()
      stintSave()
    end
    RaceTable.prevParked = parked
    local race = sim.raceSessionType == ac.SessionType.Race
    local ms = RaceTable.driveMs()
    if ms and rule.maxMinutes > 0 and race and not parked and ms > rule.maxMinutes * 60000 and not RaceTable.maxDsq then
      RaceTable.maxDsq = true
      carDsq(1, string.format(TEXTS.stintMaxDsq, rule.maxMinutes))
    end
    if race and rule.minMinutes > 0 and Flags.ending == 'finished' and not RaceTable.minDone and RaceTable.stintDone then
      RaceTable.minDone = true
      local sums = {}
      for code, v in pairs(RaceTable.stint.totals) do sums[code] = v end
      sums[RaceTable.stint.driver] = ms or sums[RaceTable.stint.driver] or 0
      local low
      for _, v in pairs(sums) do if v < rule.minMinutes * 60000 and (not low or v < low) then low = v end end
      if low then carDsq(1, string.format(TEXTS.stintMinDsq, mmss(low / 1000), rule.minMinutes)) end
    end
  end
  local MIN_FLYING = 2
  RaceTable.MIN_FLYING = MIN_FLYING
  local touched = false
  local PL = { was = nil, on = false, ms = {}, park = 0, out = false, tow = false, t = nil }
  local LOSS_KEY = 'rc.pitloss'
  local function lossKey() return RecordSync.base.trackKey() .. '|' .. RecordSync.base.carKey() end
  local function lossLoad()
    local key, body = tostring(ac.storage[LOSS_KEY] or ''):match('^([^\n]*)\n(.*)$')
    local out = {}
    if key == lossKey() then for v in body:gmatch('%d+') do out[#out + 1] = tonumber(v) end end
    return out
  end
  RaceTable.losses = nil
  function RaceTable.flying()
    local laps, sum, n = RaceTable.laps, 0, 0
    for i = #laps, 2, -1 do
      local l, p = laps[i], laps[i - 1]
      if l.valid and not l.pit and not l.touched and l.ms > 0 and p.lap == l.lap - 1 and not p.pit then sum, n = sum + l.ms, n + 1 end
      if n >= 10 then break end
    end
    return n >= MIN_FLYING and sum / n or nil, n
  end
  local function raceMinutes()
    for i = 0, (sim.sessionsCount or 0) - 1 do
      local ss = ac.getSession(i)
      if ss and ss.type == ac.SessionType.Race and CarRead.num(ss.durationMinutes) > 0 then return ss.durationMinutes end
    end
    return nil
  end
  function RaceTable.calcData(car)
    RaceTable.losses = RaceTable.losses or lossLoad()
    local lapMs, n = RaceTable.flying()
    local worst, wl = nil, 0
    for wh = 0, 3 do
      local lf = CarRead.tyreLife(car, wh, state.tyreLineKm[wh] or 0)
      if lf and (not worst or lf < worst) then worst, wl = lf, state.tyreLaps[wh] or 0 end
    end
    local fpl = CarRead.num(car.fuelPerLap)
    local L = RaceTable.losses
    local loss
    if #L > 0 then loss = 0; for _, v in ipairs(L) do loss = loss + v end; loss = loss / #L end
    local r = PitBox.calcRates()
    local enough = lapMs ~= nil
    return { lapMs = lapMs, flying = n, fuel = enough and fpl > 0 and fpl or nil, wear = enough and worst and wl > 0 and (100 - worst) / wl or nil,
      pitLoss = loss, losses = #L, rateFuel = r.fuel, rateTyre = r.tyre, raceMin = raceMinutes(), tank = CarRead.num(car.maxFuel) > 0 and CarRead.num(car.maxFuel) or nil }
  end
  PitBox.calcData = RaceTable.calcData
  function RaceTable.passReset() PL.was, PL.on, touched = nil, false, false end
  local function passUpdate(car)
    local inPL = car.isInPitlane == true
    local now = state.ui.clock
    if PL.was == false and inPL then PL.on, PL.ms, PL.park, PL.out, PL.tow = true, {}, 0, false, false end
    if PL.on and inPL then
      if CarRead.parked(car) and PL.t then PL.park = PL.park + (now - PL.t) end
      if state.tow.jumpPending or (PitStops.pass and PitStops.pass.jumped) then PL.tow = true end
    end
    if PL.on and PL.was and not inPL then PL.out = true end
    PL.was, PL.t = inPL, now
  end
  local function passLap(ms)
    if not PL.on then return end
    PL.ms[#PL.ms + 1] = ms
    if not PL.out then return end
    PL.on = false
    local mean = RaceTable.flying()
    if not mean or PL.tow then return end
    local sum = 0
    for _, v in ipairs(PL.ms) do sum = sum + v end
    local loss = sum - #PL.ms * mean - PL.park * 1000
    if loss <= 0 then return end
    RaceTable.losses = RaceTable.losses or lossLoad()
    local L = RaceTable.losses
    L[#L + 1] = math.floor(loss + 0.5)
    while #L > 5 do table.remove(L, 1) end
    ac.storage[LOSS_KEY] = lossKey() .. '\n' .. table.concat(L, ',')
    ac.log(string.format('race-control: pit lane loss measured %.1f s (%d laps, parked %.1f s)', loss / 1000, #PL.ms, PL.park))
  end
  function RaceTable.update(car, lineFrame, viaPit)
    if car.isInPitlane then touched = true end
    if lineFrame and CarRead.num(car.previousLapTimeMs) > 0 then
      local s = {}
      local splits = car.lastSplits or {}
      for k = 0, #splits do
        local v = splits[k]
        if v then s[#s + 1] = math.floor(CarRead.num(v)) end
      end
      local laps = RaceTable.laps
      laps[#laps + 1] = { lap = leaderboardLaps() or car.lapCount, ms = math.floor(CarRead.num(car.previousLapTimeMs)),
        valid = car.isLastLapValid ~= false and CarRead.num(car.lastLapCutsCount) == 0 and not state.lapCut, pit = viaPit == true, s = s,
        driver = tostring(ac.getDriverName(0) or ''):gsub('[,;|]', ' ') }
      laps[#laps].touched = touched
      touched = car.isInPitlane == true
      passLap(laps[#laps].ms)
      if #laps > MAX_LAPS then table.remove(laps, 1) end
      lapsSave()
      if config.baseUrl ~= '' then
        local life, vkm = {}, {}
        for w = 0, 3 do
          local lf = CarRead.tyreLife(car, w, state.tyreLineKm[w] or 0)
          life[#life + 1] = lf and string.format('%.0f', lf) or '-'
          vkm[#vkm + 1] = string.format('%.2f', state.tyreLineKm[w] or 0)
        end
        local l = laps[#laps]
        state.lapOut[#state.lapOut + 1] = string.format('L2|%d|%d|%d|%d|%s|%.2f|%.3f|%s|%s|%.1f|%.1f|%.0f|%s|%s|%s', l.lap, l.ms,
          l.valid and 1 or 0, l.pit and 1 or 0, table.concat(l.s, '/'), CarRead.num(car.fuel), CarRead.num(car.fuelPerLap),
          table.concat(life, ','), table.concat(vkm, ','), CarRead.num(sim.ambientTemperature), CarRead.num(sim.roadTemperature),
          CarRead.num(sim.roadGrip) * 100, RecordSync.base.trackKey(), RecordSync.base.carKey(), l.driver)
        if #state.lapOut > 200 then table.remove(state.lapOut, 1) end
      end
      state.lapCut = false
    end
    passUpdate(car)
    stintUpdate(car)
    if state.ui.clock >= RaceTable.nextT then
      RaceTable.nextT = state.ui.clock + REFRESH
      RaceTable.refresh()
    end
  end
end
local function applyKMR(car, r)
  if r.penalty == 'DSQ' then
    queueCommand(string.format('/kmr player_kick %d', car.sessionID))
  else
    ac.log(string.format('race-control: pit car.index=%d sessionID=%d %s: KMR mode, the client of the car applies it',
      car.index, car.sessionID, r.penalty))
  end
end
local function onPitViolation(car, r)
  if r.penalty == 'NONE' then return end
  if config.mode == 'CSP' then
    if r.penalty == 'DSQ' then
      carDsq(2, TEXTS.dsqWhy.pitClosed)
      queueChat(TEXTS.pit.DSQ)
    elseif r.penalty == 'REPRIMAND' then
      rcLog(TEXTS.rc.reprimand, TEXTS.dsqWhy.pitClosed)
      showNotice(TEXTS.rcTitle, TEXTS.pit.REPRIMAND)
    elseif r.penalty == 'SG' and r.param > 0 then
      Rules.sgAddSeconds(r.param, TEXTS.dsqWhy.pitClosed)
    else
      ac.log(string.format('race-control: pit: punishment of the key pitExit not applied: %s (parameter %d)',
        tostring(r.penalty), r.param))
      return
    end
  elseif config.isRaceControl then
    applyKMR(car, r)
  else
    return
  end
  ac.log(string.format('race-control: pit car.index=%d sessionID=%d %s', car.index, car.sessionID, r.penalty))
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
  if was == true and inPitlane == false and closed then
    onPitViolation(car, r)
  end
end
local GAIN_SAMPLES = 20
local LIFT_SMOOTH_SECONDS = 0.35
local SPIN_MIN_SPEED_KMH = 5
local SPIN_SETTLE_MS = 1000
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
local function zoneProgress(zone, pos)
  local len = (zone.endPos - zone.startPos) % 1
  if len <= 0 then return 0 end
  return ((pos - zone.startPos) % 1) / len
end
local function refAt(ref, p)
  local x = math.min(math.max(p, 0), 1) * GAIN_SAMPLES
  local i = math.floor(x)
  if i >= GAIN_SAMPLES then return ref[GAIN_SAMPLES] end
  return ref[i] + (ref[i + 1] - ref[i]) * (x - i)
end
local function spinning(car)
  local angle = CarRead.slipAngle(car)
  return car.speedKmh > SPIN_MIN_SPEED_KMH and angle ~= nil and angle > config.cutSpinAngle
end
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
            state.zonePass[zi] = nil
          else
            while pass.nextIdx <= GAIN_SAMPLES and p >= pass.nextIdx / GAIN_SAMPLES do
              pass.samples[pass.nextIdx] = now - pass.t0
              pass.nextIdx = pass.nextIdx + 1
            end
            if car.wheelsOutside > zone.maxWheelsOut then pass.dirty = true end
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
local function updateCutChecks()
  local car = ac.getCar(0)
  for zi, cc in pairs(state.cutChecks) do
    local zone = cc.zone
    local inZone = isInZone(zone, car.splinePosition)
    local p = inZone and zoneProgress(zone, car.splinePosition) or 1
    local elapsed = sim.time - cc.t0
    local limit = cc.ref and refAt(cc.ref, p) * (1 + zone.gainTolerance / 100) or 0
    cc.margin = limit > 0 and (elapsed / limit - 1) or 0
    local k = cc.lastT and math.min((sim.time - cc.lastT) / 1000 / LIFT_SMOOTH_SECONDS, 1) or 1
    cc.shown = cc.shown and (cc.shown + (cc.margin - cc.shown) * k) or cc.margin
    cc.lastT = sim.time
    if spinning(car) then cc.spun = true end
    if car.wheelsOutside == 0 and not spinning(car) then
      if not cc.okT then cc.okT, cc.okElapsed, cc.okLimit = sim.time, elapsed, limit end
    else
      cc.okT = nil
    end
    local back = cc.okT ~= nil and sim.time - cc.okT >= SPIN_SETTLE_MS
    if cc.given then
      if cc.spun then
        state.cutChecks[zi] = nil
        cancelSlowdown(zone, cc.rule)
        ac.log(string.format('race-control: cut %s discarded: spin, slowdown cancelled', zone.category))
      elseif car.isInPitlane or back then
        state.cutChecks[zi] = nil
      end
    elseif car.isInPitlane then
      state.cutChecks[zi] = nil
    elseif back then
      state.cutChecks[zi] = nil
      elapsed, limit = cc.okElapsed, cc.okLimit
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
    state.lapCut = true
    if Rules.dsqOn() then
      ac.log(string.format('race-control: cut %s after the DSQ: logged, not applied', zone.category))
      return
    end
    local ref = state.zoneRef[zoneIndex]
    local pass = state.zonePass[zoneIndex]
    if r.penalty == 'SLOWDOWN' then
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
      rcLog(TEXTS.rc.dt, TEXTS.reason[zone.category])
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
local function itemPriority(it)
  return string.format('DT%d', math.max(it.laps, 0))
end
local function sgText(it)
  if StopAndGo.stopping then return string.format(TEXTS.sgStopped, mmss(StopAndGo.remainingMs(it) / 1000)) end
  if StopAndGo.resume then return string.format(TEXTS.sgInterrupted, mmss(StopAndGo.remainingMs(it) / 1000)) end
  if it.laps < 0 and sim.raceSessionType ~= ac.SessionType.Race then
    return string.format(TEXTS.sgOverdue, sgSeconds(it))
  end
  return string.format(it.laps <= 0 and TEXTS.sgLastLap or TEXTS.sgPending, sgSeconds(it))
end
local function itemText(it)
  if it.kind:sub(1, 2) == 'SG' then return sgText(it) end
  return string.format(TEXTS.dtLine, itemPriority(it), TEXTS.reason[it.cat] or it.cat)
end
local BORDER_RED = rgbm(1, 0.3, 0.3, 1)
local Panel = {}
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
  local t = PitStops.windowTime()
  if t < s then return nil end
  if state.pit.done then return { value = TEXTS.pitDone, color = 'dim' } end
  if t <= e then return { value = string.format(TEXTS.pitOpen, mmss((e - t) / 1000, true)), color = 'yellow' } end
  return { value = TEXTS.pitMissed, color = 'red' }
end
function Panel.cellSwap()
  if not config.swapOn() or not config.swapRequired then
    return nil
  end
  local lit = ac.getCar(0).isInPitlane
  return { value = string.format(TEXTS.swapCount, SwapRecord.validNow(), config.swapRequired), color = lit and 'green' or 'dim',
    quiet = not lit }
end
function Panel.cellTrack()
  if state.code80 then return { value = state.code80, color = 'yellow' } end
  local flag = sim.raceFlagType
  if flag == ac.FlagType.Caution then return { value = TEXTS.trackYellow, color = 'yellow' } end
  if flag == ac.FlagType.FasterCar then return { value = TEXTS.trackBlue, color = 'blue' } end
  return nil
end
function Panel.cellPenalties()
  if Rules.dsqOn() then return { value = TEXTS.penDsq, color = 'red' } end
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
function Panel.message()
  local sg = config.sg and sgItem()
  if sg and StopAndGo.stopping then return itemText(sg), 'red' end
  local notice = state.ui.notice
  if notice then return notice.text, (notice.item and notice.item.kind:sub(1, 2) == 'SG') and 'red' or 'yellow' end
  if state.hold then
    return string.format(TEXTS.hold, mmss(PitRecord.holdLeft()), PitRecord.holdText()), 'red'
  end
  local items = state.list.items
  if sg then return itemText(sg), 'red' end
  if items[1] then return itemText(items[1]), 'yellow' end
  if state.code80 then return TEXTS.code80, 'yellow' end
  local pit = Panel.cellPit()
  if pit and not state.pit.done and pit.color == 'yellow' then return TEXTS.pitOpenMsg, 'yellow' end
  return nil
end
function Panel.frameColor()
  if state.hold or Rules.dsqOn() or (config.sg and sgItem()) then return BORDER_RED end
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
local PANEL_CELLS = {
  { title = nil, fn = function() return { value = TEXTS.rcTitle, color = 'title' } end, widest = TEXTS.rcTitle },
  { title = TEXTS.cellPit, fn = Panel.cellPit, center = true, widest = string.format(TEXTS.pitOpen, '00:00') },
  { title = TEXTS.cellSwap, fn = Panel.cellSwap, center = true, widest = string.format(TEXTS.swapCount, 88, 88) },
  { title = TEXTS.cellTrack, fn = Panel.cellTrack, center = true, widest = 'CODE-80' },
  { title = TEXTS.cellPenalties, fn = Panel.cellPenalties },
}
Lang.hooks[#Lang.hooks + 1] = function()
  local c = PANEL_CELLS
  c[1].widest = TEXTS.rcTitle
  c[2].title, c[2].widest = TEXTS.cellPit, string.format(TEXTS.pitOpen, '00:00')
  c[3].title, c[3].widest = TEXTS.cellSwap, string.format(TEXTS.swapCount, 88, 88)
  c[4].title, c[5].title = TEXTS.cellTrack, TEXTS.cellPenalties
end
local PANEL_WIDTH = 540
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
local DOT_MATRIX_COLS = 6
local DotMatrix = {}
function DotMatrix.width(text)
  return #text * DOT_MATRIX_COLS - 1
end
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
local Intro
do
  local INTRO_WAKE = 0.6
  local INTRO_LIGHT_STEP = 0.25
  local INTRO_LIGHT = 3 * INTRO_LIGHT_STEP
  local INTRO_BULB = 2.4
  local INTRO_CYCLE_STEP = 0.3
  local INTRO_FADE_IN = 0.6
  local INTRO_HOLD = 0.8
  local INTRO_SCROLL_SPEED = 180
  local INTRO_DOT_PITCH = 3
  local INTRO_TEXT_AREA = PANEL_WIDTH - 32
  local INTRO_TEXT_W = DotMatrix.width(TEXTS.introText) * INTRO_DOT_PITCH
  local INTRO_TEXT_X = (INTRO_TEXT_AREA - INTRO_TEXT_W) / 2
  local INTRO_SCROLL = (16 + INTRO_TEXT_X + INTRO_TEXT_W) / INTRO_SCROLL_SPEED
  local INTRO_STATUS = 1.5
  local INTRO_STATUS_X = (INTRO_TEXT_AREA - DotMatrix.width(TEXTS.introStatus) * INTRO_DOT_PITCH) / 2
  local INTRO_TOTAL = INTRO_WAKE + INTRO_LIGHT + INTRO_BULB + INTRO_FADE_IN + INTRO_HOLD + INTRO_SCROLL + INTRO_STATUS
  local INTRO_MOVING_KMH = 5
  local INTRO_BOX_STEP = 1.2
  local INTRO_SHOWN_KEY = 'race-control.intro'
  local INTRO_SERVER_PREFIX = 'rc.intro.'
  local INTRO_SHORT_TOTAL = INTRO_WAKE + INTRO_STATUS
  local function introServerKey()
    return INTRO_SERVER_PREFIX .. tostring(ac.getServerIP() or '') .. ':' .. tostring(ac.getServerPortTCP() or '')
  end
  Intro = { t0 = nil, done = ac.load(INTRO_SHOWN_KEY) == 1, menuSeen = false,
    short = ac.storage[introServerKey()] == '1' }
  local function introHasInfo()
    return #state.list.items > 0 or next(state.slowdowns) ~= nil or state.code80 ~= nil or state.hold ~= nil
      or Rules.dsqOn()
  end
  local INTRO_CYCLE, INTRO_MESSAGES
  local function introTexts()
    INTRO_CYCLE = {
      [TEXTS.cellPit] = { { string.format(TEXTS.pitOpen, '00:00'), 'yellow' }, { TEXTS.pitDone, 'dim' },
        { TEXTS.pitMissed, 'red' } },
      [TEXTS.cellSwap] = { { string.format(TEXTS.swapCount, 0, 1), 'dim' }, { string.format(TEXTS.swapCount, 1, 1), 'green' } },
      [TEXTS.cellTrack] = { { TEXTS.trackYellow, 'yellow' }, { TEXTS.trackBlue, 'blue' }, { 'VSC', 'yellow' },
        { 'SC', 'yellow' }, { 'CODE-80', 'yellow' } },
      [TEXTS.cellPenalties] = { { 'SD1 DT0', 'yellow' }, { 'SD1 DT0 · PSE DT1 +1', 'yellow' },{ TEXTS.penHold, 'red' }, { TEXTS.penDsq, 'red' } },
    }
    INTRO_MESSAGES = {
      { string.format(TEXTS.dtLine, 'DT0', TEXTS.reason.SD1), 'yellow' },
      { string.format(TEXTS.hold, mmss(45), TEXTS.holdTwoDT), 'red' },
      { TEXTS.code80, 'yellow' },
      { TEXTS.pitOpenMsg, 'yellow' },
    }
  end
  introTexts()
  Lang.hooks[#Lang.hooks + 1] = introTexts
  local INTRO_FRAMES = { 'base', 'yellow', 'blue', 'red', 'green' }
  local function cycled(list, t)
    return list[math.floor(t / INTRO_CYCLE_STEP) % #list + 1]
  end
  function Intro.lampCell(title, t)
    local item = INTRO_CYCLE[title] and cycled(INTRO_CYCLE[title], t)
    return item and { value = item[1], color = item[2] } or nil
  end
  function Intro.lampFrame(t) return cycled(INTRO_FRAMES, t) end
  function Intro.lampMessage(t)
    local item = cycled(INTRO_MESSAGES, t)
    return item[1], item[2]
  end
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
  function Intro.frame()
    if Intro.done or not Intro.t0 then return nil end
    local t = state.ui.clock - Intro.t0
    if t < INTRO_WAKE then return { phase = 'wake', alpha = t / INTRO_WAKE } end
    t = t - INTRO_WAKE
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
    local boxes = { 'slowdown', 'lift' }
    if config.swapOn() then boxes[#boxes + 1] = 'swap' end
    local slot = math.floor(t / INTRO_BOX_STEP)
    local box = boxes[slot + 1]
    local boxK = (t - slot * INTRO_BOX_STEP) / INTRO_BOX_STEP
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
local Desktop = { current = 1, count = 1, pitOn = true, place = {}, focus = nil, editor = false, editDesk = 1,
  indicatorUntil = 0, drawnOrder = {}, wasInPit = nil }
do
  local SCREENS = { 'pitbox', 'setup', 'status', 'race', 'laps', 'standings', 'relative', 'laptime', 'delta', 'event',
    'weather', 'map', 'telemetry', 'share', 'cockpit', 'perf', 'calc' }
  local MODE_NEXT = { visible = 'auto', auto = 'hidden', hidden = 'visible' }
  local STORAGE_KEY = 'rc.desktops'
  local OFF_KEY = 'rc.desktopsOff'
  Desktop.off = {}
  Desktop.SCREENS = SCREENS
  local function button(name) return ac.ControlButton('amxracing.race-control/' .. name) end
  local NAV = { nextScreen = button('Next screen'), prevScreen = button('Previous screen'),
    nextDesktop = button('Next desktop'), prevDesktop = button('Previous desktop'), showPanel = button('Show panel') }
  Desktop.panelUntil = 0
  for _, g in ipairs(SCREENS) do NAV['scr' .. g] = button('Screen ' .. g) end
  local TITLE_KEY = 'rc.titleBars'
  Desktop.TITLE_HIDE = { delta = true, telemetry = true, map = true, weather = true, share = true, perf = true }
  Desktop.titleHidden = {}
  for g in tostring(ac.storage[TITLE_KEY] or ''):gmatch('[^,]+') do
    if Desktop.TITLE_HIDE[g] then Desktop.titleHidden[g] = true end
  end
  function Desktop.toggleTitle(g)
    if not Desktop.TITLE_HIDE[g] then return end
    Desktop.titleHidden[g] = not Desktop.titleHidden[g] or nil
    local list = {}
    for name in pairs(Desktop.TITLE_HIDE) do if Desktop.titleHidden[name] then list[#list + 1] = name end end
    table.sort(list)
    ac.storage[TITLE_KEY] = table.concat(list, ',')
  end
  Desktop.NAV = NAV
  local function trackDefault()
    return { standings = { x = -697, y = -450, mode = 'visible' }, laptime = { x = -1564, y = 30, mode = 'visible' },
      relative = { x = -1174, y = 290, mode = 'visible' }, telemetry = { x = 350, y = -78, mode = 'visible' },
      delta = { x = 466, y = -237, mode = 'visible' }, pitbox = { x = 0, y = 0, mode = 'visible' },
      race = { x = 1524, y = 0, mode = 'visible' } }
  end
  local function pitDefault()
    return { pitbox = { x = 0, y = 0, mode = 'auto' }, status = { x = 0, y = 0, mode = 'auto' },
      setup = { x = 0, y = 0, mode = 'auto' }, standings = { x = 0, y = 0, mode = 'auto' },
      share = { x = 26, y = 689, mode = 'visible' } }
  end
  Desktop.trackDefault, Desktop.pitDefault = trackDefault, pitDefault
  local function defaults()
    Desktop.current, Desktop.count, Desktop.pitOn = 1, 1, true
    Desktop.place = { [1] = {}, all = {}, pit = pitDefault(), track = trackDefault() }
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
    ac.storage[STORAGE_KEY] = string.format('2|%d|%d|%d|%s', Desktop.current, Desktop.count, Desktop.pitOn and 1 or 0,
      table.concat(parts, ';'))
  end
  local function load()
    local text = ac.storage[STORAGE_KEY]
    local ver, cur, count, pit, body = tostring(text or ''):match('^([12])|(%d+)|(%d+)|(%d)|(.*)$')
    if not cur then
      defaults()
      return
    end
    Desktop.count = math.max(1, tonumber(count))
    Desktop.current = math.min(math.max(1, tonumber(cur)), Desktop.count)
    Desktop.pitOn = pit == '1'
    Desktop.place = { all = {}, pit = {}, track = {} }
    for i = 1, Desktop.count do Desktop.place[i] = {} end
    for d, g, x, y, mode in body:gmatch('([%w]+):(%a+):(%-?%d+):(%-?%d+):(%a+)') do
      local key = tonumber(d) or d
      if Desktop.place[key] and MODE_NEXT[mode] then
        Desktop.place[key][g] = { x = tonumber(x), y = tonumber(y), mode = mode }
      end
    end
    if ver == '1' then Desktop.place.track = trackDefault() end
  end
  load()
  function Desktop.has(g)
    for _, s in ipairs(SCREENS) do if s == g then return true end end
    return false
  end
  local function pitNow() return Desktop.pitOn and ac.getCar(0).isInPitlane end
  function Desktop.activeKey()
    local cur = Desktop.place[Desktop.current]
    if (not cur or next(cur) == nil) and Desktop.place.track and next(Desktop.place.track) ~= nil then return 'track' end
    return Desktop.current
  end
  function Desktop.entry(g)
    local p = Desktop.place
    if p.all[g] then return p.all[g] end
    if Desktop.editor then return p[Desktop.editDesk] and p[Desktop.editDesk][g] or nil end
    if pitNow() then return p.pit[g] end
    local key = Desktop.activeKey()
    local cur = p[key] and p[key][g]
    if cur then return cur end
    if g == 'pitbox' and p.pit[g] then return p.pit[g], true end
    return nil
  end
  function Desktop.mode(g)
    local e, away = Desktop.entry(g)
    if e and Desktop.editor then return 'visible' end
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
  function Desktop.stepMode(g, nextOf)
    local e = Desktop.entry(g)
    if e then e.mode = nextOf[e.mode] or e.mode; Desktop.save() end
  end
  function Desktop.setMode(g, mode)
    local e, away = Desktop.entry(g)
    if not e or away then
      e = { x = 0, y = 0, mode = mode }
      Desktop.place[Desktop.activeKey()][g] = e
    end
    e.mode = mode
    Desktop.save()
  end
  local function offSave()
    local parts = {}
    for d, list in pairs(Desktop.off) do
      for g, e in pairs(list) do parts[#parts + 1] = string.format('%s:%s:%d:%d', tostring(d), g, math.floor(e.x), math.floor(e.y)) end
    end
    ac.storage[OFF_KEY] = table.concat(parts, ';')
  end
  for d, g, x, y in tostring(ac.storage[OFF_KEY] or ''):gmatch('([%w]+):(%a+):(%-?%d+):(%-?%d+)') do
    local key = tonumber(d) or d
    Desktop.off[key] = Desktop.off[key] or {}
    Desktop.off[key][g] = { x = tonumber(x), y = tonumber(y) }
  end
  function Desktop.remove(d, g)
    local e = Desktop.place[d][g]
    if e then
      Desktop.off[d] = Desktop.off[d] or {}
      Desktop.off[d][g] = { x = e.x, y = e.y }
      offSave()
    end
    Desktop.place[d][g] = nil
    Desktop.save()
  end
  function Desktop.toggle(d, g)
    local list = Desktop.place[d]
    if list[g] then Desktop.remove(d, g) return end
    local was = Desktop.off[d] and Desktop.off[d][g]
    list[g] = { x = was and was.x or 0, y = was and was.y or 0, mode = 'visible' }
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
    for i = d, Desktop.count - 1 do Desktop.place[i] = Desktop.place[i + 1]; Desktop.off[i] = Desktop.off[i + 1] end
    Desktop.place[Desktop.count] = nil
    Desktop.off[Desktop.count] = nil
    offSave()
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
  local function valueStep(g, dir)
    if g == 'weather' then
      if Desktop.filter.weather == 'map' then
        if not Desktop.radarZoom(dir) and dir < 0 then Desktop.weatherMode('forecast') end
      elseif not Desktop.weatherStep(dir) then Desktop.weatherMode('map') end
    elseif g == 'laps' then
      Desktop.lapsStep(dir)
    elseif g == 'relative' or g == 'standings' or g == 'map' then
      local list, seen = { 'ALL' }, {}
      for _, r in ipairs(RaceTable.rows) do
        if r.class and not r.absent and not seen[r.class] then seen[r.class] = true; list[#list + 1] = r.class end
      end
      local at = 1
      for i, c in ipairs(list) do if c == Desktop.filter[g] then at = i end end
      Desktop.filter[g] = list[(at - 1 + dir) % #list + 1]
    elseif g == 'laptime' then
      Desktop.setMode('delta', Desktop.mode('delta') == 'hidden' and 'visible' or 'hidden')
    elseif g == 'delta' then
      Desktop.deltaStep(dir)
    elseif g == 'share' then
      Desktop.shareStep(dir)
    elseif g == 'cockpit' then
      Desktop.cockpitStep(dir)
    elseif g == 'calc' then
      Desktop.calcStep(dir)
    end
  end
  local WX_KEY = 'rc.weatherMode'
  Desktop.filter = { relative = 'ALL', standings = 'ALL', map = 'ALL',
    weather = tostring(ac.storage[WX_KEY] or '') == 'forecast' and 'forecast' or 'map' }
  function Desktop.weatherMode(mode)
    Desktop.filter.weather = mode
    ac.storage[WX_KEY] = mode
  end
  Desktop.lapsStep = function() end
  Desktop.weatherStep = function() end
  Desktop.radarZoom = function() end
  Desktop.deltaStep = function() end
  Desktop.cockpitStep = function() end
  Desktop.cockpitMove = function() end
  Desktop.calcStep = function() end
  Desktop.calcMove = function() end
  Desktop.shareStep = function(dir) RecordSync.base.rrShare(dir > 0) end
  Desktop.shareMove = function() end
  function Desktop.padFor(g)
    if Desktop.focus == nil then return g == 'pitbox' end
    return Desktop.focus == g
  end
  PitBox.padFor = Desktop.padFor
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
    local total = (1000 - CarRead.num(car.engineLifeLeft)) / 10 + CarRead.num(car.gearboxDamage) * 100
    for i = 0, 3 do total = total + CarRead.num(car.damage[i]) + CarRead.num(car.suspensionDamage[i]) * 100 end
    if (last.damage and total > last.damage + 0.5) or (last.class and state.repair.class ~= last.class) then pulse('damage') end
    last.damage, last.class = total, state.repair.class
    local me = RaceTable.byIndex[0]
    if me and last.pos and me.pos ~= last.pos then pulse('position') end
    last.pos = me and me.pos or last.pos
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
  local BIND_KEY = 'rc.nav'
  Desktop.binds = {}
  local down = {}
  local function bindSave()
    local parts = {}
    for name, b in pairs(Desktop.binds) do parts[#parts + 1] = name .. '=' .. b end
    ac.storage[BIND_KEY] = table.concat(parts, ';')
  end
  for name, b in tostring(ac.storage[BIND_KEY] or ''):gmatch('(%a+)=([^;]+)') do Desktop.binds[name] = b end
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
  local DIRS = { up = 'k:38', down = 'k:40', left = 'k:37', right = 'k:39' }
  local DIR_REPEAT = { left = true, right = true }
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
  Desktop.firedAt = {}
  Desktop.FIRED_SECONDS = 0.4
  local function fire(name) Desktop.firedAt[name] = state.ui.clock end
  function Desktop.fired(name) return state.ui.clock - (Desktop.firedAt[name] or -1e9) < Desktop.FIRED_SECONDS end
  if PitBox.PAD then
    for _, d in ipairs({ 'up', 'down', 'left', 'right' }) do
      local orig = PitBox.PAD[d]
      if orig then
        PitBox.PAD[d] = setmetatable({}, { __index = function(_, k)
          if k == 'pressed' then return function() local hit = orig:pressed(); if hit then fire(d) end; return hit end end
          local v = orig[k]
          if type(v) == 'function' then return function(_, ...) return v(orig, ...) end end
          return v
        end })
      end
    end
  end
  Desktop.dir = {}
  local dirOwn = {}
  local dirNext = {}
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
      if Desktop.dir[name] then fire(name) end
    end
  end
  function Desktop.ownDir(name)
    return dirOwn[name] == true
  end
  PitBox.ownDir = Desktop.ownDir
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
  local POV_DIR = { [0] = 'left', 'up', 'right', 'down' }
  local XBOX = { [1] = 'DPAD_UP', [2] = 'DPAD_DOWN', [4] = 'DPAD_LEFT', [8] = 'DPAD_RIGHT', [16] = 'START', [32] = 'BACK',
    [64] = 'LTHUMB_PRESS', [128] = 'RTHUMB_PRESS', [256] = 'LSHOULDER', [512] = 'RSHOULDER', [4096] = 'A', [8192] = 'B',
    [16384] = 'X', [32768] = 'Y' }
  local acUsed = nil
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
  local function bindUse(b, name)
    if not acUsed then loadAcUsed() end
    local kind, a, c, d = tostring(b):match('^(%a):([^:]*):?([^:]*):?([^:]*)$')
    local key = b
    if kind == 'j' then key = 'j:' .. normGuid(a) .. ':' .. c
    elseif kind == 'p' then key = 'p:' .. normGuid(a) .. ':' .. c .. ':' .. tostring(povDir(d))
    elseif kind == 'g' then key = 'x:' .. tostring(XBOX[tonumber(c) or 0]) end
    if acUsed[key] then return string.format(TEXTS.navInUseAc, acUsed[key]) end
    for other, ob in pairs(Desktop.binds) do
      local scr = other:match('^scr(%a+)$')
      if other ~= name and ob == b then return string.format(TEXTS.navInUseOwn, scr and TEXTS.screenNames[scr] or other) end
    end
    return nil
  end
  function Desktop.bindConflict(name)
    local b = Desktop.binds[name]
    if not b or b == 'none' then return nil end
    return bindUse(b, name)
  end
  Desktop.capture = nil
  function Desktop.startCapture(name)
    acUsed = nil
    Desktop.capture = { name = name, before = snapshot(), untilT = state.ui.clock + config.screens.buttonSeconds }
  end
  function Desktop.clearBind(name) Desktop.binds[name] = DIRS[name] and 'none' or nil; bindSave() end
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
        cap.conflict = use
        cap.before = now
        return
      end
      if not cap.before[b] then
        Desktop.binds[cap.name] = b
        down[cap.name] = true
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
    if Desktop.controlsUpdate then Desktop.controlsUpdate(car) end
    if Desktop.lobbyUpdate then Desktop.lobbyUpdate() end
    local nav = not Desktop.capture
    local function given(name) local hit = nav and (NAV[name]:pressed() or bindPressed(name)); if hit then fire(name) end; return hit end
    if given('nextDesktop') then Desktop.go(1) end
    if given('prevDesktop') then Desktop.go(-1) end
    if given('nextScreen') then moveFocus(1) end
    if given('prevScreen') then moveFocus(-1) end
    if given('showPanel') then Desktop.panelUntil = state.ui.clock + config.screens.autoSeconds end
    for _, g in ipairs(SCREENS) do
      if given('scr' .. g) then Desktop.setMode(g, Desktop.mode(g) == 'hidden' and 'visible' or 'hidden') end
    end
    if car.isInPitlane and Desktop.wasInPit == false then Desktop.focus, Desktop.focusByNav = 'pitbox', false end
    Desktop.wasInPit = car.isInPitlane
    local g = Desktop.focus
    if g and g ~= 'pitbox' and PitBox.PAD then
      if PitBox.PAD.left:pressed() or Desktop.dir.left then valueStep(g, -1) end
      if PitBox.PAD.right:pressed() or Desktop.dir.right then valueStep(g, 1) end
      if g == 'cockpit' then
        if PitBox.PAD.up:pressed() or Desktop.dir.up then Desktop.cockpitMove(-1) end
        if PitBox.PAD.down:pressed() or Desktop.dir.down then Desktop.cockpitMove(1) end
      end
      if g == 'share' then
        if PitBox.PAD.up:pressed() or Desktop.dir.up then Desktop.shareMove(-1) end
        if PitBox.PAD.down:pressed() or Desktop.dir.down then Desktop.shareMove(1) end
      end
      if g == 'calc' then
        if PitBox.PAD.up:pressed() or Desktop.dir.up then Desktop.calcMove(-1) end
        if PitBox.PAD.down:pressed() or Desktop.dir.down then Desktop.calcMove(1) end
      end
    end
  end
end
Desktop.commands = {
  { key = 'rc', title = '', how = '', rows = {
    { 'RC RELAX <ID> ALL', '' },
    { 'RC RELAX <ID> DT', '' },
    { 'RC RELAX <ID> SG', '' },
    { 'RC RELAX <ID> SD', '' },
    { 'RC RELAX <ID> HOLD', '' },
    { 'RC RELAX <ID> REPAIR', '' },
    { 'RC RELAX <ID> DSQ', '' },
    { 'RC UNLOCK <ID>', '' },
    { 'RC DT <ID> [laps]', '' },
    { 'RC HOLD <ID> <seconds>', '' },
    { 'RC TELEPORT <ID>', '' },
    { 'RC DSQ <ID>', '' },
    { 'RC LOCK <ID> <seconds>', '' },
    { 'RC FUEL <ID>', '' },
    { 'RC KMR <ID>', '' },
    { 'RC MENU <ID> [minutes]', '' },
    { 'RC REDFLAG ALL [- reason]', '' },
    { 'RC REDFLAG OFF ALL', '' },
    { 'RC RESTART ALL', '' },
    { 'RC RESTART OFF ALL', '' },
    { 'RC GREEN ALL', '' },
    { 'RC LIGHTS RED ALL', '' },
    { 'RC LIGHTS GREEN ALL', '' },
    { 'RC LIGHTS AUTO ALL', '' },
  } },
  { key = 'kmr', title = '', how = '', rows = {
    { 'help', 'shows a full list of commands' },
    { 'help config_get', 'shows help for the config_get command' },
    { 'json_verify {"PRACTICE"', '"remove", "QUALIFY": {"TIME": 10}, "RACE": {"LAPS": 10}}: verifies if the provided string is valid JSON to be used for any command that requires this kind of format' },
    { 'config_get max_ping', 'gets the current value of the max_ping configuration entry' },
    { 'config_set id|value', 'sets the config_id config.json entry to value' },
    { 'config_set max_ping|300', 'sets max_ping to 300 and saves the config.json' },
    { 'config_set currency_symbol|"$"', 'sets the currency_symbol to "$" and saves the config.json' },
    { 'backup_list', 'lists the available backup dates to be used with the backup_restore command' },
    { 'backup_create', 'creates a new backup' },
    { 'backup_restore 2017-11-24_165120', 'restores the backup with id 2017-11-24_165120 and exits the plugin. You will have to relaunch the plugin after the restore is complete' },
    { 'database_sharing_active_connections_list', 'shows a list of the active Database Sharing connections' },
    { 'database_sharing_overwrite_local_data_with_remote', 'overwrites the local database with the remote database' },
    { 'refresh', 'reinitializes session and connections' },
    { 'save', 'saves all the data in memory to files' },
    { 'exit', 'quits and saves the stats' },
    { 'admin_next_session', 'skips to next session' },
    { 'admin_restart_session', 'restart the current session' },
    { 'admin_send_command /ballast 0 100', 'sends the "/ballast 0 100" command to the Assetto Corsa server just like if you typed it in the chat' },
    { 'admin_say hello', 'broadcast "hello" to all players' },
    { 'rolling_start_toggle', 'toggles the rolling start flag for the next races' },
    { 'virtual_safety_car_deploy 60', 'deploys the Virtual Safety Car for 60 seconds' },
    { 'player_list', 'gives a list of the online players' },
    { 'player_name 0', 'returns the player name associated with the slot number 0' },
    { 'player_parking_permit_toggle 0', 'allows/disallows the player in slot 0 to park everywhere on the track' },
    { 'player_give_drive_through 0|1', 'gives a drive through to be served within 1 lap to the player associated with the slot number 0' },
    { 'player_cancel_drive_through 0', 'cancels the drive through penalty for the player associated with the slot number 0' },
    { 'player_drive_through_list', 'lists all the drive-through penalties that haven\'t been cleared yet' },
    { 'player_kick 0', 'kicks the player associated with the slot number 0' },
    { 'player_temporary_ban 0|60', 'bans the player in slot number 0 for 60 minutes' },
    { 'player_temporary_ban_guid 12345678901234567|60', 'bans the player with GUID 12345678901234567 for 60 minutes (BAN of the race direction: 5256000 minutes, 10 years)' },
    { 'player_ban_list', 'lists all the banned players' },
    { 'player_unban 12345678901234567', 'unbans the player with GUID 12345678901234567' },
    { 'reserved_slots_list', 'shows a list of the reserved slots' },
    { 'reserved_slots_add 12345678901234567', 'adds a reserved slot for steam GUID 12345678901234567' },
    { 'reserved_slots_remove 1', 'removes the reserved slots that has id = 1 in the output of the reserved_slots_list command' },
    { 'reserved_slots_announce', 'announces the reserved slots list to the Kissmyrank Master server' },
    { 'driver_get_guid Rockfeller', 'shows the GUID of "Rockfeller"' },
    { 'driver_reset_money 12345678901234567', 'resets the money for Steam GUID 12345678901234567' },
    { 'driver_reset_times 12345678901234567', 'clears all the times for Steam GUID 12345678901234567' },
    { 'driver_reset_driving_stats 12345678901234567', 'clears the driving stats' },
    { 'driver_privacy_erase_personal_data_and_ban 12345678901234567', 'removes the driver with Steam GUID 12345678901234567 from the stats and bans him from the server' },
    { 'driver_privacy_cancel_ban 12345678901234567', 'cancels the privacy ban for the driver with Steam GUID 12345678901234567 allowing him to join the server again' },
    { 'track_get_length', 'returns the current track length in meters' },
    { 'track_set_length 5422', 'sets the current track length to 5422m' },
    { 'track_get_name', 'returns the name of the current track' },
    { 'track_set_name Monza', 'sets the current track human friendly name to Monza' },
    { 'pit_origin_remove 6', 'unsets the pit origin for slot id 6. This can help when for whatever reason the pit origin is not correct. Kissmyrank will then rebuild the pit origin in time' },
    { 'tracks_list', 'return a list of all the tracks defined in tracks.json' },
    { 'tracks_export monza_|ks_silverstone_national|mugello_|imola_', 'exports the selected tracks to a JSON file in the "export" folder' },
    { 'tracks_import tracks_to_import.json', 'imports the "tracks_to_import.json" file from the "import" folder to the tracks database' },
    { 'track_rotation_next_track', 'switches to the next track in the server rotation' },
    { 'track_rotation_list', 'shows a list of all the tracks in the rotation in the id|track|config|races format' },
    { 'track_rotation_current_track', 'shows the current track in the rotation' },
    { 'track_rotation_rotate_to 0', 'rotates to the track with id 0' },
    { 'track_rotation_vote_reset', 'cancels the current track rotation vote' },
    { 'track_rotation_get_races', 'shows the amount of races set for the current track in the rotation' },
    { 'track_rotation_set_races 10', 'sets to 10 the amount of races for the current track in the rotation' },
    { 'track_rotation_add vallelunga|extended_circuit|3|keep|{"PRACTICE"', '"remove", "QUALIFY": {"TIME": 10}, "RACE": {"LAPS": 10}}: adds {track: "vallelunga", config: "extended_circuit", "races": 3, entry_list_ini_path: "keep", ""ini_options": {"PRACTICE": "remove", "QUALIFY": {"TIME": 10}, "RACE": {"LAPS": 10}}} to the track list' },
    { 'track_rotation_edit 1|vallelunga|extended_circuit|3|keep|{"PRACTICE"', '"remove", "QUALIFY": {"TIME": 10}, "RACE": {"LAPS": 10}}: sets track 1 to {track: "vallelunga", config: "extended_circuit", "races": 3, entry_list_ini_path: "keep", ""ini_options": {"PRACTICE": "remove", "QUALIFY": {"TIME": 10}, "RACE": {"LAPS": 10}}}' },
    { 'track_rotation_remove 0', 'removes the track with id 0 from the rotation' },
    { 'track_rotation_save', 'saves the current track list to the config.json making it permanent' },
    { 'cut_line_list', 'shows a list of the cut_lines defined for the current track' },
    { 'cut_line_remove 1', 'removes the cut line that has id 1 in the output of the cut_line_list_command' },
    { 'cut_line_edit 1|pit entry speed limit line|80|0|0|0', 'updates the cut_line with id 1 in the cut_line_list with name=pit entry speed limit line, max_speed_kmh=80, outlap_only = 0, qualify_only= 0,race_only=0' },
    { 'cut_line_drawer_begin', 'starts a new cut_line sketch' },
    { 'cut_line_drawer_set_first_point 6', 'sets the first point of the cut line sketch on the current position of the car in the slot 6' },
    { 'cut_line_drawer_set_second_point 6', 'sets the second point of the cut line sketch on the current position of the car in the slot 6' },
    { 'cut_line_drawer_set_name pit entry speed limit line', 'set the name of the cut line sketch to pit entry' },
    { 'cut_line_drawer_set_max_speed 80', 'sets the max speed of the cut line sketch to 80km/h' },
    { 'cut_line_drawer_toggle_outlap_only', 'toggles the outlap only flag for the cut line sketch' },
    { 'cut_line_drawer_toggle_qualify_only', 'toggles the qualify only flag for the cut line sketch' },
    { 'cut_line_drawer_toggle_race_only', 'toggles the race only flag for the cut line sketch' },
    { 'cut_line_drawer_save', 'saves the current sketch to a permanent cut line' },
    { 'track_boundary_set_left 6', 'starts recording the left track boundary' },
    { 'track_boundary_set_right 6', 'starts recording the right track boundary' },
    { 'track_boundary_set_offset 1.0', 'sets the rendering offset of the track border to 1.0. This is not needed for regular tracks' },
    { 'track_boundary_clear_left', 'clears all the left track boundary data' },
    { 'track_boundary_clear_right', 'clears all the right track boundary data' },
    { 'track_boundary_exclude_left_begin 6', 'starts recording of the left track boundary exclusion' },
    { 'track_boundary_exclude_right_begin 6', 'starts recording of the right track boundary exclusion' },
    { 'track_boundary_exclude_left_end 6', 'ends recording the left track boundary exclusion' },
    { 'track_boundary_exclude_right_end 6', 'ends recording the right track boundary exclusion' },
    { 'track_boundary_include_left_begin 6', 'starts recording of the left track boundary inclusion' },
    { 'track_boundary_include_right_begin 6', 'starts recording of the right track boundary inclusion' },
    { 'track_boundary_include_left_end 6', 'ends recording the left track boundary inclusion' },
    { 'track_boundary_include_right_end 6', 'ends recording the right track boundary inclusion' },
    { 'track_boundary_all_track_exclude_left', 'excludes the whole left track boundary' },
    { 'track_boundary_all_track_exclude_right', 'excludes the whole right track boundary' },
    { 'track_boundary_all_track_include_left', 'includes the whole left track boundary' },
    { 'track_boundary_all_track_include_right', 'includes the whole right track boundary' },
    { 'pit_boundary_set_left_begin 6', 'starts recording the left pit boundary' },
    { 'pit_boundary_set_right_begin 6', 'starts recording the right pit boundary' },
    { 'pit_boundary_set_left_end 6', 'ends recording the left pit boundary' },
    { 'pit_boundary_set_right_end 6', 'ends recording the right pit boundary' },
    { 'pit_boundary_clear_left', 'clears the left pit boundary data for the current track' },
    { 'pit_boundary_clear_right', 'clears the right pit boundary data for the current track' },
    { 'accessory_boundary_set_left_begin 6|Pit Entry Junction', 'starts recording the left Pit Entry Junction boundary' },
    { 'accessory_boundary_set_right_begin 6|Pit Entry Junction', 'starts recording the right Pit Entry Junction boundary' },
    { 'accessory_boundary_set_left_end 6', 'ends recording of the left Accessory Boundary area started by the car in slot 6' },
    { 'accessory_boundary_set_right_end 6', 'ends recording of the right Accessory Boundary area started by the car in slot 6' },
    { 'accessory_boundary_clear_left Pit Entry Junction', 'clears the left Pit Entry Junction boundary data for the current track' },
    { 'accessory_boundary_clear_right Pit Entry Junction', 'clears the right Pit Entry Junction boundary data for the current track' },
    { 'heuristic_all_tracks_all_data_clear', 'clears the heuristic data of all tracks (changelog)' },
  } },
  { key = 'server', title = '', how = '', rows = {
    { '/admin <password>', '' },
    { '/help', '' },
    { '/next_session', '' },
    { '/restart_session', '' },
    { '/client_list', '' },
    { '/kick <name>', '' },
    { '/kick_id <car ID>', '' },
    { '/ban <name>', '' },
    { '/ban_id <car ID>', '' },
    { '/ballast <car ID> <kg>', '' },
    { '/restrictor <car ID> <%>', '' },
  } },
  { key = 'player', title = '', how = '', rows = {
    { 'kmr help', 'shows a list of commands' },
    { 'kmr language it', 'sets the language to "it" = Italian' },
    { 'kmr leaderboard', 'shows the fastest time on the server with the car that the player is driving' },
    { 'kmr level', 'shows the player level in the laptime challenge' },
    { 'kmr money', 'shows the amount of money that a player has' },
    { 'kmr best', 'shows the driver personal best with the car that the player is driving' },
    { 'kmr next_track', 'shows the next track in the server rotation' },
    { 'kmr rules', 'shows the server rules' },
    { 'kmr stats', 'shows the driver\'s driving stats' },
    { 'kmr toggle_notifications', 'toggles notifications while driving' },
    { 'kmr vote_track', 'vote for track change' },
    { 'kmr erase_my_personal_data_and_ban_myself', 'removes the player\'s personal data from the stats and prevents further access to the server' },
  } },
}
local function commandTexts()
  local T = TEXTS.cmdHelp
  for _, g in ipairs(Desktop.commands) do
    g.title, g.how = T[g.key].title, T[g.key].how
    local d = T[g.key].rows
    if d then for i, r in ipairs(g.rows) do r[2] = d[i] or r[2] end end
  end
end
commandTexts()
Lang.hooks[#Lang.hooks + 1] = commandTexts
local Drag = {}
do
  local GROUPS = { 'panel', 'pitbox', 'setup', 'status', 'laps', 'race', 'laptime', 'delta', 'relative', 'standings',
    'event', 'weather', 'map', 'telemetry', 'share', 'cockpit', 'perf', 'calc' }
  local DEFAULT_MODE = { laps = 'hidden', telemetry = 'hidden', cockpit = 'hidden', perf = 'hidden', calc = 'hidden' }
  local MODES = { visible = true, auto = true, hidden = true }
  Drag.EYE_NEXT = { visible = 'hidden', auto = 'hidden', hidden = 'visible' }
  Drag.GHOST_NEXT = { visible = 'auto', auto = 'visible', hidden = 'auto' }
  local ICON_SIZE, ICON_GAP = 12, 3
  local ICON_COLOR = rgbm(0.85, 0.87, 0.9, 0.9)
  local ICON_ON = rgbm(1, 0.2, 0.15, 1)
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
  Drag.group = nil
  local rects = {}
  local zones = {}
  local hover = {}
  local buttons = {}
  local active
  local function getOff(g) return Desktop.has(g) and Desktop.offset(g) or offsets[g] end
  local function setOff(g, v) if Desktop.has(g) then Desktop.setOffset(g, v) else offsets[g] = v end end
  local offUsed = {}
  function Drag.offset(group, h)
    local o = getOff(group)
    local v = vec2(o.x * h / 1080, o.y * h / 1080)
    offUsed[group] = v
    return v
  end
  Drag.lastRects = {}
  function Drag.mode(group) return Desktop.has(group) and Desktop.mode(group) or modes[group] end
  function Drag.setMode(group, m)
    if Desktop.has(group) then Desktop.setMode(group, m) elseif MODES[m] then modes[group] = m; stored[group .. 'Mode'] = m end
  end
  Drag.modal = nil
  function Drag.hovered(group) return hover[group] == true end
  local function grow(t, g, p1, p2)
    local r = t[g]
    if r then
      r.min:set(math.min(r.min.x, p1.x), math.min(r.min.y, p1.y))
      r.max:set(math.max(r.max.x, p2.x), math.max(r.max.y, p2.y))
    else
      t[g] = { min = vec2(p1.x, p1.y), max = vec2(p2.x, p2.y) }
    end
  end
  local zoneKept = { at = vec2(0, 0) }
  local function growZone(g, p1, p2)
    if zones[g] then return grow(zones, g, p1, p2) end
    local z = zoneKept[g] or { min = vec2(0, 0), max = vec2(0, 0) }
    zoneKept[g] = z
    z.min:set(p1.x, p1.y)
    z.max:set(p2.x, p2.y)
    zones[g] = z
  end
  function Drag.hit(p1, p2)
    local g = Drag.group
    if not g then return end
    grow(rects, g, p1, p2)
    growZone(g, p1, p2)
  end
  function Drag.zone(group, p1, p2) growZone(group, p1, p2) end
  local function icon(id, x, y, size, color, action)
    local p1, p2 = vec2(x, y), vec2(x + size, y + size)
    ui.drawRectFilled(vec2(p1.x - 1, p1.y - 1), vec2(p2.x + 1, p2.y + 1), rgbm(0.04, 0.04, 0.05, 0.85), 2)
    ui.drawIcon(id, p1, p2, color)
    buttons[#buttons + 1] = { p1 = p1, p2 = p2, action = action }
  end
  function Drag.icons(group, p1, p2, s)
    local size, gap = ICON_SIZE * s, ICON_GAP * s
    local row = {}
    if group == 'panel' then
      row[#row + 1] = { ui.Icons.Settings, (Desktop.menu or Desktop.editor or Audit.open or Desktop.buttons or Desktop.settingsOpen or Desktop.redOpen or Desktop.cockpitOpen)
        and ICON_ON or ICON_COLOR,
        function() Desktop.menu = not Desktop.menu end }
      row[#row + 1] = { ui.Icons.Monitor, ICON_COLOR, function() Desktop.go(1) end }
      for _, it in ipairs({ { ui.Icons.Sliders, 'setup' }, { ui.Icons.PitStop, 'pitbox' },
          { ui.Icons.CarFront, 'status' }, { ui.Icons.Flag, 'race' }, { ui.Icons.List, 'laps' },
          { ui.Icons.Leaderboard, 'standings' }, { ui.Icons.Group, 'relative' }, { ui.Icons.Stopwatch, 'laptime' },
          { ui.Icons.Stats, 'delta' }, { ui.Icons.Info, 'event' }, { ui.Icons.Weather, 'weather' },
          { ui.Icons.Map, 'map' }, { ui.Icons.Pedals, 'telemetry' }, { ui.Icons.VideoCamera, 'share' },
          { ui.Icons.SteeringWheel, 'cockpit' }, { ui.Icons.Speedometer, 'perf' }, { ui.Icons.Calculator, 'calc' } }) do
        row[#row + 1] = { it[1], Drag.mode(it[2]) == 'visible' and ICON_COLOR or ICON_OFF, 'show:' .. it[2] }
      end
    end
    if Desktop.TITLE_HIDE[group] then
      row[#row + 1] = { ui.Icons.AppWindow, Desktop.titleHidden[group] and ICON_ON or ICON_COLOR,
        function() Desktop.toggleTitle(group) end }
    end
    local m = Drag.mode(group)
    row[#row + 1] = { m == 'hidden' and ui.Icons.Hide or ui.Icons.Eye, m == 'hidden' and ICON_OFF or ICON_COLOR, 'eye:' .. group }
    row[#row + 1] = { ui.Icons.Ghost, m == 'auto' and ICON_COLOR or ICON_OFF, 'ghost:' .. group }
    row[#row + 1] = { ui.Icons.Pin, pins[group] and ICON_ON or ICON_COLOR, 'pin:' .. group }
    if group == 'panel' then row[#row + 1] = { ui.Icons.Reset, ICON_COLOR, 'reset' } end
    local y = p1.y - size - gap
    local x = p2.x - #row * size - (#row - 1) * gap
    growZone(group, zoneKept.at:set(x, y), p2)
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
    if what == 'eye' or what == 'ghost' then
      local nextOf = what == 'eye' and Drag.EYE_NEXT or Drag.GHOST_NEXT
      if Desktop.has(g) then Desktop.stepMode(g, nextOf) else modes[g] = nextOf[modes[g]] or modes[g] end
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
  function Drag.pinned(g) return pins[g] == true end
  function Drag.setOffset(g, v)
    if pins[g] then return end
    setOff(g, v)
    save(g)
  end
  function Drag.clickable(p1, p2, fn) buttons[#buttons + 1] = { p1 = p1, p2 = p2, action = fn } end
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
        active = nil
        pcall(save, a.group)
      end
      ui.setMouseCursor(ui.MouseCursor.ResizeAll)
      ui.captureMouse(true)
    elseif ok then
      local done = false
      for bi = #buttons, 1, -1 do
        local b = buttons[bi]
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
local FONT_TITLE = 'Segoe UI;Weight=Bold'
local FONT_TEXT = 'Segoe UI;Weight=SemiBold'
local FONT_MONO = 'Consolas'
do
  local function face(file, style, names)
    local out = {}
    for _, n in ipairs(names) do out[#out + 1] = n .. style end
    for _, n in ipairs(names) do out[#out + 1] = n .. ':@System' .. style end
    out[#out + 1] = names[1] .. ':content/fonts/race-control-' .. file .. '.ttf' .. style
    out[#out + 1] = names[1] .. ':apps/lua/race-control/fonts/' .. file .. '.ttf' .. style
    out[#out + 1] = names[1] .. ':content/fonts' .. style
    out[#out + 1] = names[1] .. ':apps/lua/race-control/fonts' .. style
    return out
  end
  local MONO = face('roboto-mono-500', ';Weight=Medium', { 'Roboto Mono', 'Roboto Mono Medium' })
  Desktop.text = { id = 'segoe', min = 0, minPx = 0, sets = {
    { id = 'segoe', name = 'Segoe UI', title = 'Segoe UI;Weight=Bold', text = 'Segoe UI;Weight=SemiBold', mono = 'Consolas' },
    { id = '12h', name = '12h Curitiba', title = face('oswald-600', ';Weight=SemiBold', { 'Oswald', 'Oswald SemiBold' }),
      text = face('raleway-600', ';Weight=SemiBold', { 'Raleway Thin', 'Raleway Thin SemiBold', 'Raleway' }), mono = MONO, files = true },
    { id = 'titillium', name = 'Titillium Web', title = face('titillium-web-700', ';Weight=Bold', { 'Titillium Web', 'Titillium Web Bold' }),
      text = face('titillium-web-600', ';Weight=SemiBold', { 'Titillium Web', 'Titillium Web SemiBold' }), mono = MONO, files = true },
    { id = 'barlow', name = 'Barlow', title = face('barlow-condensed-600', ';Weight=SemiBold;Stretch=Condensed', { 'Barlow', 'Barlow Condensed' }),
      text = face('barlow-600', ';Weight=SemiBold', { 'Barlow', 'Barlow SemiBold' }), mono = MONO, files = true },
    { id = 'rajdhani', name = 'Rajdhani', title = face('rajdhani-700', ';Weight=Bold', { 'Rajdhani', 'Rajdhani Bold' }),
      text = face('rajdhani-600', ';Weight=SemiBold', { 'Rajdhani', 'Rajdhani SemiBold' }), mono = MONO, files = true },
    { id = 'bahnschrift', name = 'Bahnschrift', title = 'Bahnschrift:@System;Weight=Bold',
      text = 'Bahnschrift:@System;Weight=SemiBold', mono = 'Consolas:@System' },
  } }
  for _, f in ipairs(Desktop.text.sets) do
    f.ready = f.files == nil
    if f.files then
      f.names = { title = f.title, text = f.text, mono = f.mono }
      f.title, f.text, f.mono = f.title[1], f.text[1], f.mono[1]
    end
  end
end
local FONT_PROBE = 'RACING CONTROL Wim 1:40.123'
function Desktop.fontCheck()
  if Desktop.text.checked then return end
  Desktop.text.checked = true
  local function width(spec)
    ui.pushDWriteFont(spec)
    local w = ui.measureDWriteText(FONT_PROBE, 20).x
    ui.popDWriteFont()
    return w
  end
  local none = {}
  local function absent(spec)
    local style = spec:match(';.*$') or ''
    none[style] = none[style] or width('Racing Control No Font' .. style)
    return math.abs(width(spec) - none[style]) < 0.01
  end
  for _, f in ipairs(Desktop.text.sets) do
    if f.files then
      local missing = {}
      for _, face in ipairs({ 'title', 'text', 'mono' }) do
        local got
        for _, spec in ipairs(f.names[face]) do
          if not absent(spec) then got = spec break end
        end
        if got then f[face] = got
        elseif face == 'mono' then f.mono = 'Consolas'
        else missing[#missing + 1] = table.concat(f.names[face], ' / ') end
      end
      f.ready = #missing == 0
    end
  end
  if Desktop.text.wanted then Desktop.textApply(Desktop.text.wanted) end
  if Desktop.widthReset then Desktop.widthReset() end
end
function Desktop.textApply(id, min)
  for _, f in ipairs(Desktop.text.sets) do
    if f.id == id and f.ready then
      FONT_TITLE, FONT_TEXT, FONT_MONO = f.title, f.text, f.mono
      Desktop.text.id = id
    end
  end
  if min then Desktop.text.min = min end
  if Desktop.widthReset then Desktop.widthReset() end
  if not Desktop.text.checked then return end
  ac.storage['rc.font'] = Desktop.text.id
  ac.storage['rc.textMin'] = tostring(Desktop.text.min)
end
do
  local id = tostring(ac.storage['rc.font'] or '')
  Desktop.text.min = tonumber(ac.storage['rc.textMin'] or '') or 0
  if id ~= '' and id ~= 'segoe' then Desktop.text.wanted = id; Desktop.textApply(id) end
end
local COLOR_TITLE = rgbm(0.96, 0.96, 0.96, 1)
local COLOR_TEXT = rgbm(1, 0.85, 0.25, 1)
local COLOR_SWAP = rgbm(0.45, 1, 0.55, 1)
local COLOR_ORANGE = rgbm(1, 0.54, 0.11, 1)
local COLOR_LIFT_FAST = rgbm(1, 0.3, 0.3, 0.45)
local COLOR_LIFT_SLOW = rgbm(0.2, 0.8, 0.3, 0.35)
local COLOR_DIM = rgbm(0.6, 0.63, 0.65, 1)
local COLOR_CELL_OFF = rgbm(0.23, 0.25, 0.27, 1)
local PANEL_COLORS = {
  title = rgbm(0.96, 0.96, 0.96, 1), dim = rgbm(0.6, 0.63, 0.65, 1), yellow = rgbm(1, 0.85, 0.25, 1),
  red = rgbm(1, 0.3, 0.3, 1), blue = rgbm(0.56, 0.7, 1, 1), green = rgbm(0.45, 1, 0.55, 1),
}
local LIFT_LIMIT_POS = 0.55
local LIFT_SCALE = 1.8
local LIFT_CARET_HZ = 2
local function px(v) return math.floor(v + 0.5) end
local TMP = { text = vec2(0, 0), a = vec2(0, 0), b = vec2(0, 0) }
local function drawText(text, font, size, pos, color)
  size = math.max(size, Desktop.text.minPx)
  ui.pushDWriteFont(font)
  ui.dwriteDrawText(text, size, TMP.text:set(px(pos.x), px(pos.y)), color)
  ui.popDWriteFont()
end
do
  local WIDTH_MAX = 2000
  local cache, count = {}, 0
  function Desktop.widthReset() cache, count = {}, 0 end
  function TMP.width(text, font, size)
    local byFont = cache[font]
    local bySize = byFont and byFont[size]
    local w = bySize and bySize[text]
    if w then return w end
    ui.pushDWriteFont(font)
    w = ui.measureDWriteText(text, size).x
    ui.popDWriteFont()
    if count >= WIDTH_MAX then cache, count = {}, 0 end
    byFont = cache[font] or {}
    cache[font] = byFont
    bySize = byFont[size] or {}
    byFont[size] = bySize
    bySize[text] = w
    count = count + 1
    return w
  end
end
local function textWidth(text, font, size)
  return TMP.width(text, font, math.max(size, Desktop.text.minPx))
end
local FIT_MAX = 200
local fitCache, fitCount = {}, 0
local function fitText(text, font, size, maxW, tail)
  text = tostring(text or '')
  tail = tail or '...'
  local px_ = math.max(size, Desktop.text.minPx)
  local key = table.concat({ text, tostring(font), tostring(px_), tostring(maxW), tail }, '\1')
  local hit = fitCache[key]
  if hit then return hit end
  local out
  if textWidth(text, font, size) <= maxW then
    out = text
  else
    local ends = {}
    for e in text:gmatch('[^\128-\191][\128-\191]*()') do ends[#ends + 1] = e - 1 end
    if textWidth(tail, font, size) > maxW then
      out = ''
    else
      local lo, hi = 0, #ends - 1
      while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if textWidth(text:sub(1, ends[mid]) .. tail, font, size) <= maxW then lo = mid else hi = mid - 1 end
      end
      out = (lo > 0 and text:sub(1, ends[lo]) or '') .. tail
    end
  end
  if fitCount >= FIT_MAX then fitCache, fitCount = {}, 0 end
  fitCache[key], fitCount = out, fitCount + 1
  return out
end
local function dropLastLetter(text)
  return (tostring(text or ''):gsub('[^\128-\191][\128-\191]*$', '', 1))
end
Desktop.opacity = math.min(math.max(tonumber(ac.storage['rc.opacity'] or '') or 1, 0.2), 1)
function Desktop.setOpacity(v)
  Desktop.opacity = math.min(math.max(v, 0.2), 1)
  ac.storage['rc.opacity'] = string.format('%.2f', Desktop.opacity)
end
do
  local byF, nF = {}, 0
  local CLEAR = rgbm(1, 1, 1, 0)
  function TMP.panelColors(f, border)
    local c = byF[f]
    if not c then
      if nF >= 64 then byF, nF = {}, 0 end
      c = { shadow = rgbm(0, 0, 0, 0.35 * f), fill = rgbm(0.04, 0.04, 0.05, 0.9 * f), light = rgbm(1, 1, 1, 0.06 * f), clear = CLEAR, borders = {} }
      byF[f], nF = c, nF + 1
    end
    if f >= 1 then return c, border end
    local b = c.borders[border]
    if not b then
      b = rgbm(border.r, border.g, border.b, (border.mult or 1) * f)
      c.borders[border] = b
    end
    return c, b
  end
end
local function drawPanel(p1, p2, border, s, alpha)
  Drag.hit(p1, p2)
  local a = alpha or 1
  local f = a * Desktop.opacity
  local r = px(8 * s)
  local o = px(3 * s)
  local C
  C, border = TMP.panelColors(f, border)
  ui.drawRectFilled(TMP.a:set(p1.x + o, p1.y + o), TMP.b:set(p2.x + o, p2.y + o), C.shadow, r)
  ui.drawRectFilled(p1, p2, C.fill, r)
  local i = px(4 * s)
  ui.drawRectFilledMultiColor(TMP.a:set(p1.x + i, p1.y + i), TMP.b:set(p2.x - i, p2.y - i), C.light, C.light, C.clear, C.clear)
  ui.drawRectFilled(TMP.a:set(p1.x + px(3 * s), p1.y + px(8 * s)), TMP.b:set(p1.x + px(7 * s), p2.y - px(8 * s)), border,
    px(2 * s))
  ui.drawRect(p1, p2, border, r, nil, 1.5 * s)
end
local function drawLedLight(c, r, color, lit, s)
  ui.drawCircleFilled(c, r + 1.5 * s, rgbm(0.02, 0.02, 0.025, 1), 32)
  ui.drawCircle(c, r + 1.5 * s, rgbm(0.28, 0.28, 0.3, 1), 32, 1 * s)
  if lit then ui.drawCircleFilled(c, r, rgbm(color.r, color.g, color.b, 0.18), 32) end
  local pitch = r / 3.6
  local dot = pitch * 0.36
  local m = math.floor((r - pitch * 0.55) / pitch)
  local cut = m * m + 1.01
  local n = m + 1
  for iy = -n, n do
    for ix = -n, n do
      local dx, dy = ix * pitch, iy * pitch
      if ix * ix + iy * iy <= cut then
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
local function drawFlagBox(p1, p2, s, border, disc, title, titleColor, line1, line2, flag, line2Color)
  drawPanel(p1, p2, border, s)
  local f1 = vec2(p1.x + 20 * s, p1.y + 12 * s)
  local f2 = vec2(f1.x + 46 * s, f1.y + 32 * s)
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
TMP.sepColor = rgbm(1, 1, 1, 0.12)
TMP.dark, TMP.edge30, TMP.edge35 = rgbm(0.07, 0.07, 0.07, 1), rgbm(1, 1, 1, 0.3), rgbm(1, 1, 1, 0.35)
local function drawSeparator(p1, p2, y, s)
  ui.drawSimpleLine(TMP.a:set(p1.x + px(16 * s), px(y)), TMP.b:set(p2.x - px(16 * s), px(y)), TMP.sepColor, 1)
end
local function drawTextRight(text, font, size, xRight, y, color)
  size = math.max(size, Desktop.text.minPx)
  local tw = TMP.width(text, font, size)
  ui.pushDWriteFont(font)
  ui.dwriteDrawText(text, size, TMP.text:set(px(xRight - tw), px(y)), color)
  ui.popDWriteFont()
end
local drawPitBox
do
  local BOX_W, BOX_H = 288, 195
  local BOX = { font = 11, head = 21, side = 14 }
  local BOX_RIGHT, BOX_BOTTOM = 1920 - 1397 - 288, 48
  local STATUS_W, STATUS_RIGHT, STATUS_GAP = 171, 48, 1920 - 1397 - 288 - 48 - 171
  local ROW_H = 15
  local COLOR_SEL = rgbm(1, 0.85, 0.25, 1)
  local COLOR_OFF = rgbm(0.45, 0.48, 0.5, 1)
  local num = CarRead.num
  local function wing()
    local sp = CarRead.setupValues()
    if sp.WING_1 == '-' and sp.WING_2 == '-' then return '-' end
    return sp.WING_1 .. ' / ' .. sp.WING_2
  end
  drawPitBox = function(car, w, h, s)
    local sv = state.pitService
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
    local presets = PitBox.presetCount()
    if presets > 1 then
      table.insert(rows, 1, { 'strategy', TEXTS.pitStrategy, '< ' .. string.format(TEXTS.pitPresetN, PitBox.presetIndex() + 1) .. ' >', nil })
    end
    local spinners = PitBox.presetSpinners()
    if #spinners > 0 then PitBox.logSpinnersOnce() end
    if #spinners > 0 then
      local count, seen = {}, {}
      for _, sp in ipairs(spinners) do count[sp.type] = (count[sp.type] or 0) + 1 end
      local tyresOn = #PitBox.TYRE_CHOICES[p.tyres][2] > 0
      for _, sp in ipairs(spinners) do
        seen[sp.type] = (seen[sp.type] or 0) + 1
        local names4 = count[sp.type] == 4 and { 'FL', 'FR', 'RL', 'RR' } or count[sp.type] == 2 and { 'F', 'R' } or nil
        local wheel = sp.type == 'pressure' and PitBox.spinnerWheel(sp.name) or nil
        wheel = wheel and TEXTS.wheelCode[wheel] or wheel
        local label = (sp.type == 'wing' and TEXTS.pitWing or TEXTS.pitPressure) .. ' '
          .. (wheel or ((sp.n or 1) > 1 and string.format('x%d', sp.n)) or (names4 and TEXTS.wheelCode[names4[seen[sp.type]]]) or tostring(seen[sp.type]))
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
    local boxH = BOX_H + math.max(#rows - 9, 0) * ROW_H
    local fs = BOX.font * s
    local fuelWidest = string.format(TEXTS.pitFuelValue, 999, 999, 999)
    local labelW = 0
    for _, r in ipairs(rows) do labelW = math.max(labelW, textWidth(r[2], FONT_TEXT, fs)) end
    local need = 0
    for _, r in ipairs(rows) do
      local vw = r[1] == 'tyres' and (3 * 26 * s + textWidth('RR', FONT_MONO, fs)) or textWidth(r[3] or TEXTS.pitRepairYes, FONT_MONO, fs)
      if r[1] == 'fuel' then vw = math.max(vw, textWidth(fuelWidest, FONT_MONO, fs)) end
      local tw = r[4] and (textWidth(mmss(r[4]), FONT_MONO, fs) + 12 * s) or 0
      need = math.max(need, BOX.side * s + labelW + 8 * s + vw + tw + BOX.side * s)
    end
    local bw, bh = math.max(BOX_W * s, math.ceil(need)), boxH * s
    local strategy = PitBox.tab == 'strategy' and presets > 1
    local stopN = #rows
    if strategy then
      local all = ac.getPitstopSpinners and ac.getPitstopSpinners() or {}
      local list = {}
      for i = 0, presets - 1 do
        local press, wingV = {}, {}
        for _, sp in ipairs(all) do
          local v = PitBox.presetValue(sp, i)
          if sp.type == 'pressure' then press[#press + 1] = tostring(v) elseif sp.type == 'wing' then wingV[#wingV + 1] = tostring(v) end
        end
        local value = table.concat(press, ' ') .. (#wingV > 0 and ('  ' .. TEXTS.pitWing .. ' ' .. table.concat(wingV, '/')) or '')
        list[#list + 1] = { 'preset:' .. i, string.format(TEXTS.pitPresetN, i + 1) .. (i == PitBox.presetIndex() and ' *' or ''), value, nil }
      end
      list[#list + 1] = { 'back', TEXTS.pitBack, '', nil }
      rows = list
    end
    local o = Drag.offset('pitbox', h)
    local right = math.min(w - BOX_RIGHT * k, w - STATUS_RIGHT * k - STATUS_W * s - STATUS_GAP * k)
    local p1 = vec2(math.floor(right - bw + o.x), math.floor(h - BOX_BOTTOM * k - bh + o.y))
    Drag.group = 'pitbox'
    local p2 = vec2(p1.x + bw, p1.y + bh)
    drawPanel(p1, p2, Desktop.focus == 'pitbox' and BORDER_YELLOW or BORDER_GREEN, s)
    local gap = (boxH - BOX.head - (math.max(#rows, stopN) + 1) * ROW_H) / 4 * s
    drawText(TEXTS.pitBoxTitle, FONT_TITLE, 12 * s, TMP.a:set(p1.x + BOX.side * s, p1.y + 4 * s), strategy and COLOR_DIM or COLOR_TITLE)
    if presets > 1 then
      local tx = p1.x + BOX.side * s + textWidth(TEXTS.pitBoxTitle, FONT_TITLE, 12 * s) + 8 * s
      drawText('|  ' .. TEXTS.pitStrategyTab, FONT_TITLE, 12 * s, TMP.a:set(tx, p1.y + 4 * s), strategy and COLOR_SEL or COLOR_DIM)
    end
    local total = string.format(TEXTS.pitBoxTotal, mmss(p.total))
    drawTextRight(total, FONT_MONO, 11 * s, p2.x - BOX.side * s, p1.y + 5 * s, COLOR_TITLE)
    ui.pushDWriteFont(FONT_MONO)
    local tw = ui.measureDWriteText(total, 11 * s).x
    ui.popDWriteFont()
    drawTextRight(config.pitStopOrder, FONT_MONO, 11 * s, p2.x - BOX.side * s - tw - 10 * s, p1.y + 5 * s, COLOR_DIM)
    drawSeparator(p1, p2, p1.y + BOX.head * s, s)
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
    local vx = p1.x + BOX.side * s + labelW + 8 * s
    local function cursorLine(x1, x2, y)
      local ly, dash, gapD = y + fs + 2 * s, 4 * s, 3 * s
      local x = x1
      while x < x2 do
        ui.drawSimpleLine(TMP.a:set(x, ly), TMP.b:set(math.min(x + dash, x2), ly), COLOR_SEL, 1)
        x = x + dash + gapD
      end
    end
    local rowsTop = p1.y + BOX.head * s + gap
    for i, r in ipairs(rows) do
      local y = rowsTop + (i - 1) * ROW_H * s
      local sel = not sv and r[1] ~= nil and r[1] == chosen
      drawText(r[2], FONT_TEXT, fs, TMP.a:set(p1.x + BOX.side * s, y), (r[1] and not r.off) and COLOR_TITLE or COLOR_OFF)
      if r[1] == 'tyres' then
        for wIdx = 0, 3 do
          drawText(TEXTS.wheelCode[PitBox.WHEELS[wIdx]], FONT_MONO, fs, TMP.a:set(vx + wIdx * 26 * s, y),
            chips[wIdx] and (sel and COLOR_SEL or COLOR_SWAP) or COLOR_OFF)
        end
        if sel then cursorLine(vx, vx + 3 * 26 * s + textWidth(TEXTS.wheelCode[PitBox.WHEELS[3]], FONT_MONO, fs), y) end
      elseif r[1] == 'suspension' or r[1] == 'powertrain' or r[1] == 'body' then
        local value = p.repair[r[1]] and TEXTS.pitRepairYes
          or (PitBox.damaged(car, r[1]) and (PitBox.repairLocked() and TEXTS.pitRepairLocked or TEXTS.pitRepairNo)
          or TEXTS.pitRepairNone)
        drawText(value, FONT_MONO, fs, TMP.a:set(vx, y), sel and COLOR_SEL or COLOR_TITLE)
        if sel then cursorLine(vx, vx + textWidth(value, FONT_MONO, fs), y) end
      else
        drawText(r[3], FONT_MONO, fs, TMP.a:set(vx, y), sel and COLOR_SEL or ((r[1] and not r.off) and COLOR_TITLE or COLOR_OFF))
        if sel then cursorLine(vx, vx + textWidth(tostring(r[3] or ''), FONT_MONO, fs), y) end
      end
      if r[4] then
        local rest = sv and left[r[1]]
        drawTextRight(mmss(rest or r[4]), FONT_MONO, fs, p2.x - BOX.side * s, y,
          rest and rest > 0 and COLOR_SWAP or COLOR_TITLE)
      end
    end
    local sep = rowsTop + math.max(#rows, stopN) * ROW_H * s + gap
    drawSeparator(p1, p2, sep, s)
    local fy = sep + gap
    local elapsed = sv and math.max(p.total - (sv.untilMs - serverTimeMs()) / 1000, 0) or 0
    local modeSel = not sv and chosen == 'mode'
    local footer = sv and TEXTS.pitBoxServing or strategy and TEXTS.pitStrategyHint
      or string.format(TEXTS.pitBoxMode, PitBox.isAuto() and TEXTS.pitModeAuto or TEXTS.pitModeManual) .. TEXTS.pitBoxStart
    drawText(footer, FONT_TEXT, fs, TMP.a:set(p1.x + BOX.side * s, fy),
      sv and COLOR_SWAP or (modeSel and COLOR_SEL or COLOR_TITLE))
    if modeSel then cursorLine(p1.x + BOX.side * s, p1.x + BOX.side * s + textWidth(footer, FONT_TEXT, fs), fy) end
    drawTextRight(string.format('%s / %s', mmss(elapsed), mmss(p.total)), FONT_MONO, fs, p2.x - BOX.side * s, fy,
      COLOR_TITLE)
    Drag.icons('pitbox', p1, p2, s)
  end
end
local drawStatus
(function()
  local num = CarRead.num
  local SETUP = { font = 9.5, title = 10, lh = 12, head = 21, side = 14, colGap = 11, valueW = 22, pairGap = 7,
    tyreLabelW = 46, wheelGap = 6, rows = 9 }
  local SETUP_W, SETUP_H, SETUP_LEFT = 384, 224 + SETUP.lh, 235
  SETUP.gap = (SETUP_H - SETUP.head - 16 * SETUP.lh) / 6
  SETUP.axisColor = rgbm(0.29, 0.31, 0.33, 1)
  local STATUS_W, STATUS_RIGHT = 171, 1920 - 1701 - 171
  local MARGIN = 48
  local COLOR_OFF = rgbm(0.45, 0.48, 0.5, 1)
  local COLOR_OK = rgbm(0.45, 1, 0.55, 1)
  local COLOR_WARN = rgbm(1, 0.85, 0.25, 1)
  local WHEEL = { [0] = 'FL', 'FR', 'RL', 'RR' }
  local function wheelLabel(i) return TEXTS.wheelCode[WHEEL[i]] end
  local COLOR_COLD = rgbm(0.35, 0.65, 1, 1)
  local function blend(a, b, k)
    k = math.min(math.max(k, 0), 1)
    return rgbm(a.r + (b.r - a.r) * k, a.g + (b.g - a.g) * k, a.b + (b.b - a.b) * k, 1)
  end
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
  local Area = {}
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
          local tw = textWidth(tostring(v) .. '0', FONT_MONO, fs)
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
        drawText(r.title, FONT_TITLE, SETUP.title * s, TMP.a:set(x1, y - (SETUP.title - SETUP.font) * s / 2), COLOR_DIM)
      else
        if r[1] then drawText(r[1], FONT_TEXT, fs, TMP.a:set(x1, y), COLOR_OFF) end
        if r[2] then drawText(r[2], FONT_MONO, fs, TMP.a:set(axisX, y), SETUP.axisColor) end
        local vals = r[3]
        local at = #vals == 1 and { m.cols } or (#vals == 2 and m.cols == 4 and { 2, 4 }) or nil
        for i, v in ipairs(vals) do
          drawTextRight(tostring(v), FONT_MONO, fs, right(at and at[i] or i), y, COLOR_TITLE)
        end
      end
    end
  end
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
    local function four(name) return { sp[name .. 'LF'], sp[name .. 'RF'], sp[name .. 'LR'], sp[name .. 'RR'] } end
    local function heave(name) return { sp[name .. 'HF'], sp[name .. 'HR'] } end
    local T = TEXTS
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
        { T.setupBrakeBias, { { nil, { string.format('%.0f/%.0f', num(car.brakeBias) * 100,
          100 - num(car.brakeBias) * 100) } } } },
        { T.setupDeploy, { { nil, { deploy } } } },
        { T.setupErs, { { nil, { ers, recovery } } } },
      }), 2, s),
      Area.measure(Area.rows({
        { title = T.setupChassis },
        { T.setupCamber, { { T.wheelCode.F, { f('%.1f', wh[0] and wh[0].camber), f('%.1f', wh[1] and wh[1].camber) } },
          { T.wheelCode.R, { f('%.1f', wh[2] and wh[2].camber), f('%.1f', wh[3] and wh[3].camber) } } } },
        { T.setupToe, { { T.wheelCode.F, { f('%.2f', wh[0] and wh[0].toeIn), f('%.2f', wh[1] and wh[1].toeIn) } },
          { T.wheelCode.R, { f('%.2f', wh[2] and wh[2].toeIn), f('%.2f', wh[3] and wh[3].toeIn) } } } },
        { T.setupArb, { { T.setupAxes, { sp.ARB_FRONT, sp.ARB_REAR } } } },
        { T.setupHeight, { { T.setupAxes, { sp.ROD_LENGTH_LF, sp.ROD_LENGTH_LR } } } },
        { T.setupHeaveHeight, { { T.setupAxes, { sp.ROD_LENGTH_HF, sp.ROD_LENGTH_HR } } } },
      }), 2, s),
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
    drawText(TEXTS.setupTitle, FONT_TITLE, 12 * s, TMP.a:set(x0, p1.y + 4 * s), COLOR_TITLE)
    drawTextRight(string.format(TEXTS.setupLap, car.lapCount + 1), FONT_MONO, 11 * s, xr, p1.y + 5 * s, COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + SETUP.head * s, s)
    local y0 = p1.y + SETUP.head * s + gap
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
    local sep1 = y0 + rowsTop * lh + gap
    drawSeparator(p1, p2, sep1, s)
    local ty = sep1 + gap
    local tx = x0
    local gears, final = gearsOf(car)
    if gears then
      local pairW = textWidth('8', FONT_MONO, fs) + 4 * s + textWidth('0.000', FONT_MONO, fs)
      local gw = math.max(2 * pairW + 10 * s, textWidth(TEXTS.setupGears, FONT_TITLE, SETUP.title * s) + textWidth('  F 0.000', FONT_MONO, fs))
      local half = gw / 2
      drawText(TEXTS.setupGears, FONT_TITLE, SETUP.title * s, TMP.a:set(x0, ty - (SETUP.title - SETUP.font) * s / 2), COLOR_DIM)
      drawTextRight(string.format('F %.3f', final), FONT_MONO, fs, x0 + gw, ty, COLOR_TITLE)
      for g, r in ipairs(gears) do
        local col, line = (g - 1) % 2, math.floor((g - 1) / 2)
        if line < 5 then
          local cx = x0 + col * (half + 5 * s)
          local gy = ty + (line + 1) * lh
          drawText(tostring(g), FONT_MONO, fs, TMP.a:set(cx, gy), SETUP.axisColor)
          drawTextRight(string.format('%.3f', r), FONT_MONO, fs, cx + half - 5 * s, gy, COLOR_TITLE)
        end
      end
      tx = x0 + gw + colGap
      local lx = math.floor(x0 + gw + colGap / 2 + 0.5)
      ui.drawSimpleLine(vec2(lx, ty), vec2(lx, ty + 6 * lh - 2 * s), rgbm(1, 1, 1, 0.12), 1)
    end
    drawText(TEXTS.setupTyres, FONT_TITLE, SETUP.title * s, TMP.a:set(tx, ty - (SETUP.title - SETUP.font) * s / 2), COLOR_DIM)
    local wx1 = tx + (SETUP.tyreLabelW + SETUP.wheelGap) * s
    drawText(tostring(ac.getTyresLongName(0, -1) or '-'), FONT_MONO, fs, TMP.a:set(wx1, ty), COLOR_TITLE)
    local wGap = SETUP.wheelGap * s
    local cw = (xr - wx1 - 3 * wGap) / 4
    for i = 0, 3 do
      local x = wx1 + (i + 1) * cw + i * wGap
      local life = CarRead.tyreLife(car, i, state.tyreLineKm[i] or 0)
      local color = life and lifeColor(life) or COLOR_TITLE
      life = life or (1 - num(wh[i] and wh[i].tyreWear)) * 100
      drawTextRight(wheelLabel(i), FONT_MONO, fs, x, ty + lh, SETUP.axisColor)
      local th = CarRead.tyreThermal(car, i)
      drawTextRight(string.format('%.1f', num(wh[i] and wh[i].tyrePressure)), FONT_MONO, fs, x, ty + 2 * lh,
        th and thermalColor(th) or COLOR_TITLE)
      drawTextRight(string.format('%.0f%%', life), FONT_MONO, fs, x, ty + 3 * lh, color)
      drawTextRight(string.format('%.1f', state.tyreKm[i] or 0), FONT_MONO, fs, x, ty + 4 * lh, COLOR_TITLE)
      local laps = state.tyreLaps[i] or 0
      local lapLife, lapLimit = CarRead.tyreLapLimit(car, i, laps, state.tyreLineKm[i] or 0)
      drawTextRight(lapLife and string.format(TEXTS.setupLapsOf, laps, lapLimit and tostring(lapLimit) or '--')
        or tostring(laps), FONT_MONO, fs, x, ty + 5 * lh, lapLife and lifeColor(lapLife) or COLOR_TITLE)
    end
    drawText(TEXTS.setupPsi, FONT_TEXT, fs, TMP.a:set(tx, ty + 2 * lh), COLOR_OFF)
    drawText(TEXTS.setupLife, FONT_TEXT, fs, TMP.a:set(tx, ty + 3 * lh), COLOR_OFF)
    drawText(TEXTS.setupKm, FONT_TEXT, fs, TMP.a:set(tx, ty + 4 * lh), COLOR_OFF)
    drawText(TEXTS.setupLaps, FONT_TEXT, fs, TMP.a:set(tx, ty + 5 * lh), COLOR_OFF)
    local sep2 = ty + 6 * lh + gap
    drawSeparator(p1, p2, sep2, s)
    local ex = x0
    for _, e in ipairs({ { 'ABS', car.absMode }, { 'TC', car.tractionControlMode }, { 'TC2', car.tractionControl2 },
        { 'EB', car.currentEngineBrakeSetting }, { 'MAP', car.fuelMap } }) do
      drawText(e[1], FONT_MONO, fs, TMP.a:set(ex, sep2 + gap), COLOR_OFF)
      ex = ex + textWidth(e[1] .. ' ', FONT_MONO, fs)
      local v = string.format('%d', num(e[2]))
      drawText(v, FONT_MONO, fs, TMP.a:set(ex, sep2 + gap), COLOR_TITLE)
      ex = ex + textWidth(v, FONT_MONO, fs) + 9 * s
    end
    Drag.icons('setup', p1, p2, s)
  end
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
  local F1 = {}
  F1.BODY = { -6, -36, 6, 33 }
  F1.NOSE_HALF, F1.COCKPIT_Y, F1.NOSE_R = 5.1, -9.2, 1.5
  F1.NOSE_EXTRA, F1.EXTRA_Y = 0.6, -21
  F1.NOSE_EXTRA2, F1.EXTRA2_Y = 0.6, -25
  F1.SHIFT = -4
  F1.WHEELS = { { 11.5, 17, -27, -15 }, { 10, 17, 16, 31 } }
  F1.RING, F1.at = { vec2(0, 0), vec2(0, 0), vec2(0, 0), vec2(0, 0) }, 0
  local function drawF1(cx, cy, s)
    local body = COLOR_TITLE
    local function P(x, y)
      F1.at = F1.at % 4 + 1
      return F1.RING[F1.at]:set(cx + x * s, cy + y * s)
    end
    local noseY = F1.BODY[2] + F1.NOSE_R
    local function half(y)
      if y >= F1.COCKPIT_Y then return F1.BODY[3] end
      local k = math.max((y - noseY) / (F1.COCKPIT_Y - noseY), 0)
      local extra = y < F1.EXTRA_Y and F1.NOSE_EXTRA * (1 - math.max((y - noseY) / (F1.EXTRA_Y - noseY), 0)) or 0
      if y < F1.EXTRA2_Y then extra = extra + F1.NOSE_EXTRA2 * (1 - math.max((y - noseY) / (F1.EXTRA2_Y - noseY), 0)) end
      return F1.NOSE_HALF + (F1.BODY[3] - F1.NOSE_HALF) * k - extra
    end
    local tip = half(noseY)
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
    ui.drawRect(P(-4, -9.2), P(4, 5.2), body, 2 * s, nil, 1)
    ui.drawSimpleLine(P(-2.5, -7), P(2.5, -7), body, 1)
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
    local L = { head = 21, gap = 5, title = 16, tileH = 25, tileGap = 4, bopH = 15, side = 14, font = 9 }
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
    drawText(TEXTS.statusTitle, FONT_TITLE, 12 * s, TMP.a:set(p1.x + L.side * s, p1.y + 4 * s), COLOR_TITLE)
    if rp.class == 'repair' then
      drawTextRight(TEXTS.statusRepair, FONT_MONO, 11 * s, p2.x - L.side * s, p1.y + 5 * s, COLOR_ORANGE)
    elseif rp.class == 'beyond' then
      drawTextRight(TEXTS.statusBeyond, FONT_MONO, 11 * s, p2.x - L.side * s, p1.y + 5 * s, BORDER_RED)
    end
    drawSeparator(p1, p2, p1.y + L.head * s, s)
    local x1, x2 = p1.x + L.side * s, p2.x - L.side * s
    local tileW = (x2 - x1 - L.tileGap * s) / 2
    local function blockTitle(text, y)
      drawText(text, FONT_TITLE, SETUP.title * s, TMP.a:set(x1, y), COLOR_DIM)
    end
    local function tile(tx, ty, tw, name, value, color)
      local strong = color == COLOR_ORANGE or color == BORDER_RED
      local q1, q2 = vec2(px(tx), px(ty)), vec2(px(tx + tw), px(ty + L.tileH * s))
      if strong then ui.drawRectFilled(q1, q2, rgbm(color.r, color.g, color.b, 0.1), 3 * s) end
      local border = (strong or color == COLOR_WARN) and rgbm(color.r, color.g, color.b, 0.65) or rgbm(0.23, 0.25, 0.27, 1)
      ui.drawRect(q1, q2, border, 3 * s, nil, 1)
      ui.drawCircleFilled(vec2(px(tx + 8 * s), px(ty + L.tileH * s / 2)), 3 * s, color, 12)
      drawText(name, FONT_TEXT, L.font * s, TMP.a:set(tx + 15 * s, ty + 2 * s), COLOR_TITLE)
      drawText(value, FONT_MONO, L.font * s, TMP.a:set(tx + 15 * s, ty + 13 * s), color)
    end
    local y = p1.y + (L.head + L.gap) * s
    blockTitle(TEXTS.statusWheels, y)
    y = y + L.title * s
    for i = 0, 3 do
      local text, color = wheelTile(car, i)
      tile(x1 + (i % 2) * (tileW + L.tileGap * s), y + math.floor(i / 2) * (L.tileH + L.tileGap) * s, tileW, wheelLabel(i),
        text, color)
    end
    y = y + (2 * L.tileH + L.tileGap + L.gap) * s
    drawSeparator(p1, p2, y, s)
    y = y + L.gap * s
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
    local kg, rs = num(car.ballast), num(car.restrictor)
    ui.drawRect(vec2(px(x1), px(y)), vec2(px(x2), px(y + L.bopH * s)), rgbm(0.23, 0.25, 0.27, 1), 3 * s, nil, 1)
    drawText(TEXTS.statusBop, FONT_TEXT, L.font * s, TMP.a:set(x1 + 6 * s, y + 2 * s), COLOR_TITLE)
    drawTextRight((kg == 0 and rs == 0) and '-' or string.format('%.0f kg  %.0f%%', kg, rs), FONT_MONO, L.font * s,
      x2 - 6 * s, y + 2 * s, (kg == 0 and rs == 0) and COLOR_OFF or COLOR_TITLE)
    y = y + (L.bopH + L.gap) * s
    drawSeparator(p1, p2, y, s)
    y = y + L.gap * s
    blockTitle(TEXTS.statusBody, y)
    local limit = config.damage.bodyRepair
    local function side(i)
      local v = num(car.damage[i])
      return v, math.min(v / limit, 1),
        v > limit and COLOR_ORANGE or (v > limit / 2 and COLOR_WARN or (v > 0 and COLOR_OK or COLOR_OFF))
    end
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
    local fText, bText = string.format('%s %.0f', TEXTS.side.front, vF), string.format('%s %.0f', TEXTS.side.back, vB)
    drawText(fText, FONT_MONO, bf, TMP.a:set(cx - textWidth(fText, FONT_MONO, bf) / 2, cy - 53 * s), cF)
    drawText(bText, FONT_MONO, bf, TMP.a:set(cx - textWidth(bText, FONT_MONO, bf) / 2, cy + 40 * s), cB)
    hbar(cy + 54 * s, kB, cB)
    vbar(p1.x + 12 * s, kL, cL)
    drawText(string.format('%s %.0f', TEXTS.side.left, vL), FONT_MONO, bf, TMP.a:set(p1.x + 19 * s, cy - 6 * s), cL)
    drawTextRight(string.format('%s %.0f', TEXTS.side.right, vR), FONT_MONO, bf, p2.x - 19 * s, cy - 6 * s, cR)
    vbar(p2.x - 15 * s, kR, cR)
    drawF1(cx, cy + F1.SHIFT * s, s)
    Drag.icons('status', p1, p2, s)
  end
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
local drawRaceScreens = (function()
  local PURPLE = rgbm(0.78, 0.49, 1, 1)
  local COLOR_AXIS = rgbm(0.29, 0.31, 0.33, 1)
  local COLOR_OFF = rgbm(0.45, 0.48, 0.5, 1)
  local LAPDOWN = rgbm(0.79, 0.73, 0.6, 1)
  local GREEN = PANEL_COLORS.green
  local RED = PANEL_COLORS.red
  local BLUE = PANEL_COLORS.blue
  local YELLOW = PANEL_COLORS.yellow
  local ORANGE = rgbm(1, 0.54, 0.11, 1)
  local ROW = 13
  local FS = 10
  local PLACE = { relative = { 1572, 380, 300 }, laptime = { 1612, 640, 260 }, delta = { 860, 880, 200 },
    race = { 48, 110, 300 }, laps = { 48, 420, 330 }, standings = { 745, 560, 510 }, event = { 770, 200, 380 },
    weather = { 48, 620, 300 }, map = { 1572, 110, 300 }, telemetry = { 48, 890, 600 }, share = { 1300, 30, 250 }, cockpit = { 1300, 110, 260 }, perf = { 1300, 400, 130 },
    calc = { 380, 110, 380 } }
  local filter = Desktop.filter
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
  local function frame(g, w, h, s, rows, title, right, width, dx)
    local pl = PLACE[g]
    local k = h / 1080
    local bw = (width or pl[3]) * s
    local bh = (26 + rows * ROW + 2) * s
    local o = Drag.offset(g, h)
    local p1 = vec2(math.floor(pl[1] * k + o.x - (dx or 0)), math.floor(pl[2] * k + o.y))
    local baseW = pl[3] * s
    if bw ~= baseW then
      if p1.x + baseW / 2 > w / 2 then p1.x = p1.x + baseW - bw end
      p1.x = math.floor(math.min(math.max(p1.x, 0), w - bw))
    end
    local p2 = vec2(p1.x + bw, p1.y + bh)
    Drag.group = g
    if Desktop.titleHidden[g] and not Drag.hovered(g) then
      local top = vec2(p1.x, p1.y + 20 * s)
      drawPanel(top, p2, Desktop.focus == g and BORDER_YELLOW or BORDER_BASE, s)
      return top, p2, p1.y + 26 * s, true
    end
    drawPanel(p1, p2, Desktop.focus == g and BORDER_YELLOW or BORDER_BASE, s)
    drawText(title, FONT_TITLE, 12 * s, TMP.a:set(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    if right then drawTextRight(right, FONT_MONO, 11 * s, p2.x - 14 * s, p1.y + 5 * s, COLOR_TITLE) end
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    return p1, p2, p1.y + 26 * s
  end
  local function chips(g, p1, p2, s)
    local list = { 'ALL' }
    local seen = {}
    for _, r in ipairs(RaceTable.rows) do
      if r.class and not r.absent and not seen[r.class] then seen[r.class] = true; list[#list + 1] = r.class end
    end
    if #list > 4 then
      local t = string.format(TEXTS.scrClassSel, filter[g] or 'ALL')
      local tw = textWidth(t, FONT_MONO, 9 * s)
      local a, b = vec2(p2.x - 14 * s - tw - 6 * s, p1.y + 5 * s), vec2(p2.x - 14 * s, p1.y + 18 * s)
      ui.drawRectFilled(a, b, YELLOW, 2 * s)
      drawText(t, FONT_MONO, 9 * s, TMP.a:set(a.x + 3 * s, a.y + 1 * s), TMP.dark)
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
      if on then ui.drawRectFilled(a, b, YELLOW, 2 * s) else ui.drawRect(a, b, TMP.edge30, 2 * s) end
      drawText(t, FONT_MONO, 9 * s, TMP.a:set(a.x + 3 * s, a.y + 1 * s), on and TMP.dark or COLOR_DIM)
      Drag.clickable(a, b, function() filter[g] = t end)
      x = a.x - 4 * s
    end
  end
  local function row(p1, y, s, cells)
    for _, c in ipairs(cells) do
      local font = c[5] or FONT_MONO
      local col = c[1] == '-' and COLOR_OFF or (c[3] or COLOR_TITLE)
      if c[4] then drawTextRight(c[1], font, FS * s, p1.x + c[2] * s, y, col)
      else drawText(c[1], font, FS * s, TMP.a:set(p1.x + c[2] * s, y), col) end
    end
  end
  local function carClick(index, a, b)
    if not config.role then return end
    local function open() Desktop.carMenu = { index = index, x = a.x, y = b.y } end
    Drag.clickable(a, b, open)
    local m = ui.mousePos()
    if ui.MouseButton and m.x >= a.x and m.x <= b.x and m.y >= a.y and m.y <= b.y and ui.mouseClicked(ui.MouseButton.Right) then
      open()
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
      carClick(r.index, vec2(p1.x + 40 * s, y), vec2(p1.x + 248 * s, y + ROW * s))
      row(p1, y, s, {
        { pos, 36, mine and YELLOW or COLOR_DIM, true },
        { '#' .. r.number, 42, col },
        { r.name .. (r.inPit and TEXTS.relPit or ''), 76, col, false, mine and FONT_TITLE or FONT_TEXT },
        { r.class or '', 250, COLOR_OFF, true },
        { string.format('%+.1f', gap), 286, col, true },
      })
      y = y + ROW * s
    end
    Drag.icons('relative', p1, p2, s)
  end
  local function kmrOf(r)
    if r.index == 0 then return Audit.points, Audit.rating end
    local c = ac.getCar(r.index)
    local byCar = c and RecordSync.peers[c.sessionID]
    local rec = byCar and byCar.kmr and Record.decode(byCar.kmr.text)
    if not rec then return nil, nil end
    local driver, points, rating = tostring(rec.body or ''):match('^(%d+)|([^|]*)|?([^|]*)$')
    if not driver or tonumber(driver) ~= nameCode(ac.getDriverName(r.index)) then return nil, nil end
    return tonumber(points), tonumber(rating)
  end
  local function standingsScreen(car, w, h, s)
    local list = {}
    for _, r in ipairs(RaceTable.rows) do
      if filter.standings == 'ALL' or r.class == filter.standings then list[#list + 1] = r end
    end
    local mine = 1
    for i, r in ipairs(list) do if r.index == 0 then mine = i end end
    local first = math.max(1, math.min(mine - 4, #list - 9))
    local last = math.min(#list, first + 9)
    local p1, p2, y = frame('standings', w, h, s, last - first + 2, TEXTS.scrStandings, nil)
    chips('standings', p1, p2, s)
    local H = TEXTS.hdr
    row(p1, y, s, { { H.pos, 32, COLOR_AXIS, true }, { H.classPos, 52, COLOR_AXIS, true }, { '#', 58, COLOR_AXIS },
      { H.driver, 88, COLOR_AXIS }, { H.class, 214, COLOR_AXIS }, { H.laps, 270, COLOR_AXIS, true },
      { H.gap, 306, COLOR_AXIS, true }, { H.int, 346, COLOR_AXIS, true }, { H.best, 398, COLOR_AXIS, true },
      { H.pit, 424, COLOR_AXIS, true }, { H.sr, 456, COLOR_AXIS, true }, { H.pts, 492, COLOR_AXIS, true } })
    y = y + ROW * s
    local leader = list[1]
    local sessionBest = CarRead.num(sim.bestLapTimeMs)
    local function gapTo(r, front)
      if not front or r == front then return '-' end
      local dl = front.laps - r.laps
      return dl >= 1 and string.format(TEXTS.lapsShort, dl) or string.format('%.1f', math.abs(ac.getGapBetweenCars(r.index, front.index)))
    end
    local cutBest = {}
    for _, l in ipairs(RaceTable.laps) do if not l.valid then cutBest[l.ms] = true end end
    for i = first, last do
      local r = list[i]
      local me = r.index == 0
      local col = me and YELLOW or COLOR_TITLE
      if r.absent then
        row(p1, y, s, { { '#' .. r.number, 58, COLOR_OFF }, { r.name, 88, COLOR_OFF, false, FONT_TEXT },
          { r.class or '', 214, COLOR_OFF } })
      else
      carClick(r.index, vec2(p1.x + 56 * s, y), vec2(p1.x + 212 * s, y + ROW * s))
      row(p1, y, s, {
        { tostring(r.pos), 32, col, true }, { tostring(r.classPos or '-'), 52, COLOR_DIM, true },
        { '#' .. r.number, 58, col }, { r.name, 88, col, false, me and FONT_TITLE or FONT_TEXT },
        { r.class or '', 214, COLOR_OFF }, { tostring(r.laps), 270, col, true }, { gapTo(r, leader), 306, col, true },
        { gapTo(r, list[i - 1]), 346, col, true },
        { lapTime(r.best), 398, (me and cutBest[r.best]) and RED or (r.best > 0 and r.best == sessionBest) and PURPLE or col, true },
        { tostring(r.stops or 0), 424, col, true },
        { (function() local _, sr = kmrOf(r); return sr and Audit.num(sr) or '-' end)(), 456, col, true },
        { (function() local pts = kmrOf(r); return pts and tostring(pts) or '-' end)(), 492, col, true },
      })
      end
      y = y + ROW * s
    end
    Drag.icons('standings', p1, p2, s)
  end
  local function lapTimeScreen(car, w, h, s)
    local p1, p2, y = frame('laptime', w, h, s, 10.2, TEXTS.scrLapTime, nil)
    local on = Drag.mode('delta') ~= 'hidden'
    local a, b = vec2(p2.x - 34 * s, p1.y + 5 * s), vec2(p2.x - 14 * s, p1.y + 18 * s)
    if on then ui.drawRectFilled(a, b, YELLOW, 2 * s) else ui.drawRect(a, b, TMP.edge30, 2 * s) end
    drawText(TEXTS.scrDeltaButton, FONT_TEXT, 9 * s, TMP.a:set(a.x + 6 * s, a.y), on and TMP.dark or COLOR_DIM)
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
    local kept = RaceTable.laps[#RaceTable.laps]
    local lastValid = CarRead.num(car.previousLapTimeMs) <= 0 or (car.isLastLapValid ~= false and CarRead.num(car.lastLapCutsCount) == 0
      and not (kept and kept.ms == math.floor(CarRead.num(car.previousLapTimeMs)) and not kept.valid))
    for _, l in ipairs({
      { TEXTS.scrLast, lapTime(CarRead.num(car.previousLapTimeMs)) .. (lastValid and '' or (' ' .. TEXTS.lapTag.cut)), lastValid and COLOR_TITLE or RED },
      { TEXTS.scrBest, lapTime(best), (best > 0 and best == sessionBest) and PURPLE or GREEN },
      { TEXTS.scrSession, sessionBest > 0 and (lapTime(sessionBest) .. owner) or '-', PURPLE },
      { TEXTS.scrOptimal, optimal > 0 and lapTime(optimal) or '-', COLOR_TITLE } }) do
      row(p1, y, s, { { l[1], 14, COLOR_DIM }, { l[2], 246, l[3], true } })
      y = y + ROW * s
    end
    Drag.icons('laptime', p1, p2, s)
  end
  local DELTA_REFS = { 'best', 'session', 'optimal', 'alltime' }
  local function refOn(r) return r ~= 'alltime' or RecordSync.base.best.value ~= nil end
  local deltaRef = tostring(ac.storage['rc.deltaRef'] or '')
  if not TEXTS.scrDeltaRefs[deltaRef] then deltaRef = 'best' end
  local function setDeltaRef(r) deltaRef = r; ac.storage['rc.deltaRef'] = r end
  Desktop.deltaStep = function(dir)
    local at = 1
    for i, r in ipairs(DELTA_REFS) do if r == deltaRef then at = i end end
    for _ = 1, #DELTA_REFS do
      at = (at - 1 + dir) % #DELTA_REFS + 1
      if refOn(DELTA_REFS[at]) then break end
    end
    setDeltaRef(DELTA_REFS[at])
  end
  local function sumSplits(list)
    local t = 0
    for k = 0, 2 do t = t + (list and CarRead.num(list[k]) or 0) end
    return t
  end
  local function deltaScreen(car, w, h, s)
    local p1, p2, y, bare = frame('delta', w, h, s, 2.9, TEXTS.scrDelta, nil)
    if not bare then
      local x = p2.x - 14 * s
      for i = #DELTA_REFS, 1, -1 do
        local r = DELTA_REFS[i]
        local t = TEXTS.scrDeltaRefs[r]
        local tw = textWidth(t, FONT_MONO, 9 * s)
        local a, b = vec2(x - tw - 6 * s, p1.y + 5 * s), vec2(x, p1.y + 18 * s)
        local avail = refOn(r)
        if deltaRef == r and avail then ui.drawRectFilled(a, b, YELLOW, 2 * s)
        else ui.drawRect(a, b, avail and TMP.edge30 or rgbm(1, 1, 1, 0.12), 2 * s) end
        drawText(t, FONT_MONO, 9 * s, TMP.a:set(a.x + 3 * s, a.y + 1 * s), (deltaRef == r and avail) and TMP.dark
          or avail and COLOR_DIM or COLOR_OFF)
        if avail then Drag.clickable(a, b, function() setDeltaRef(r) end) end
        x = a.x - 4 * s
      end
    end
    local d0 = CarRead.num(car.performanceMeter)
    local own = CarRead.num(car.bestLapTimeMs)
    local all = RecordSync.base.best.value
    local ref = deltaRef == 'session' and CarRead.num(sim.bestLapTimeMs) or deltaRef == 'optimal' and sumSplits(car.bestSplits)
      or deltaRef == 'alltime' and (all and all.ms or 0) or own
    local d = nil
    if deltaRef == 'best' then d = d0
    elseif own > 0 and ref > 0 then d = d0 + (CarRead.num(car.lapTimeMs) / 1000 - d0) * (1 - ref / own) end
    local bx1, bx2 = p1.x + 14 * s, p2.x - 14 * s
    local mid = (bx1 + bx2) / 2
    ui.drawRectFilled(vec2(bx1, y), vec2(bx2, y + 7 * s), rgbm(1, 1, 1, 0.06), 2 * s)
    local f = math.min(math.abs(d or 0), 1) * (bx2 - bx1) / 2
    if (d or 0) > 0 then ui.drawRectFilled(vec2(mid, y), vec2(mid + f, y + 7 * s), RED, 2 * s)
    elseif (d or 0) < 0 then ui.drawRectFilled(vec2(mid - f, y), vec2(mid, y + 7 * s), GREEN, 2 * s) end
    ui.drawSimpleLine(vec2(mid, y - 2 * s), vec2(mid, y + 9 * s), COLOR_TITLE, 1)
    y = y + 10 * s
    if car.isLapValid == false then drawText(TEXTS.scrInvalid, FONT_MONO, 9 * s, TMP.a:set(bx1, y + 2 * s), RED) end
    drawTextRight(d and string.format('%+.3f', d) or '-', FONT_MONO, 13 * s, bx2, y, not d and COLOR_OFF or d > 0 and RED or GREEN)
    y = y + 15 * s
    local refSplit = deltaRef == 'optimal' and car.bestSplits or car.bestLapSplits
    local scale = (deltaRef == 'session' and own > 0 and ref > 0) and ref / own or 1
    if deltaRef == 'alltime' then
      refSplit, scale = {}, 1
      for k, v in ipairs(all and all.s or {}) do refSplit[k - 1] = v end
    end
    local cells = { { TEXTS.scrDeltaSectors, 14, COLOR_DIM } }
    for k = 0, 2 do
      local cur = car.currentSplits and CarRead.num(car.currentSplits[k]) or 0
      local rs = refSplit and CarRead.num(refSplit[k]) * scale or 0
      local v = (cur > 0 and rs > 0) and (cur - rs) / 1000 or nil
      cells[#cells + 1] = { v and string.format('%+.2f', v) or '-', 94 + k * 46, v and (v > 0 and RED or GREEN) or nil, true }
    end
    row(p1, y, s, cells)
    Drag.icons('delta', p1, p2, s)
  end
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
      drawText(TEXTS.scrNoMap, FONT_MONO, 9 * s, TMP.a:set(p1.x + 14 * s, y), COLOR_OFF)
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
    drawText(TEXTS.scrMapLegend[1], FONT_MONO, 8.5 * s, TMP.a:set(p1.x + 14 * s, p2.y - 27 * s), COLOR_DIM)
    drawText(TEXTS.scrMapLegend[2], FONT_MONO, 8.5 * s, TMP.a:set(p1.x + 14 * s, p2.y - 15 * s), COLOR_DIM)
    Drag.icons('map', p1, p2, s)
  end
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
  local Radar = { geo = nil, loop = nil, canvas = nil, canvasT = nil, NORTH = 3 }
  Radar.STOPS = { { 0, 120, 215, 240 }, { 0.30, 40, 120, 230 }, { 0.55, 250, 220, 40 }, { 0.78, 240, 120, 40 }, { 1, 170, 60, 220 } }
  function Radar.pcolor(v)
    v = math.min(math.max(v, 0), 1)
    local S = Radar.STOPS
    for i = 1, #S - 1 do
      local a, b = S[i], S[i + 1]
      if v <= b[1] then
        local u = (v - a[1]) / (b[1] - a[1])
        return a[2] + (b[2] - a[2]) * u, a[3] + (b[3] - a[3]) * u, a[4] + (b[4] - a[4]) * u
      end
    end
    return S[#S][2], S[#S][3], S[#S][4]
  end
  function Radar.geometry()
    if Radar.geo ~= nil then return Radar.geo or nil end
    Radar.geo = false
    if not ac.hasTrackSpline or not ac.hasTrackSpline() then return nil end
    local N = 360
    local P, W = {}, {}
    for i = 0, N - 1 do
      local okP, q = pcall(ac.trackProgressToWorldCoordinate, i / N)
      local okW, sd = pcall(ac.getTrackAISplineSides, i / N)
      if not okP or not q then return nil end
      P[i + 1] = { q.x, q.z }
      W[i + 1] = okW and sd and { sd.x, sd.y } or { 6, 6 }
    end
    local hd = {}
    for i = 1, N do local a, b = P[i], P[i % N + 1]; hd[i] = math.atan2(b[2] - a[2], b[1] - a[1]) end
    local function diff(a, b) local d = (a - b) % (2 * math.pi); if d > math.pi then d = d - 2 * math.pi end; return math.abs(d) end
    local best, bi = 0, 1
    for i = 1, N do
      local len = 0
      while len < N - 1 and diff(hd[(i + len - 1) % N + 1], hd[i]) < math.rad(5) do len = len + 1 end
      if len > best then best, bi = len, i end
    end
    local A, B = P[bi], P[(bi + best - 1) % N + 1]
    local rot = math.pi / 2 - math.atan2(B[2] - A[2], B[1] - A[1])
    local function turned(r)
      local c, s = math.cos(r), math.sin(r)
      local Q = {}
      for i = 1, N do Q[i] = { P[i][1] * c - P[i][2] * s, P[i][1] * s + P[i][2] * c } end
      return Q
    end
    local Q = turned(rot)
    local sx, rx, ns, nr = 0, 0, 0, 0
    for i = 1, N do
      local inS = ((i - bi) % N) < best
      if inS then sx, ns = sx + Q[i][1], ns + 1 else rx, nr = rx + Q[i][1], nr + 1 end
    end
    if nr > 0 and ns > 0 and rx / nr > sx / ns then rot = rot + math.pi end
    rot = rot - math.rad(Radar.NORTH)
    Q = turned(rot)
    local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
    for i = 1, N do x0 = math.min(x0, Q[i][1]); x1 = math.max(x1, Q[i][1]); z0 = math.min(z0, Q[i][2]); z1 = math.max(z1, Q[i][2]) end
    local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    local L, R = {}, {}
    for i = 1, N do
      Q[i][1], Q[i][2] = Q[i][1] - cx, Q[i][2] - cz
    end
    for i = 1, N do
      local a, b = Q[(i - 2) % N + 1], Q[i % N + 1]
      local dx, dz = b[1] - a[1], b[2] - a[2]
      local len = math.sqrt(dx * dx + dz * dz) + 1e-9
      local nx, nz = -dz / len, dx / len
      L[i] = { Q[i][1] + nx * W[i][1], Q[i][2] + nz * W[i][1] }
      R[i] = { Q[i][1] - nx * W[i][2], Q[i][2] - nz * W[i][2] }
    end
    Radar.geo = { Q = Q, L = L, R = R }
    return Radar.geo
  end
  local OKTA_PCT = { [0] = { 0, 0 }, { 1, 12 }, { 13, 25 }, { 26, 38 }, { 39, 50 }, { 51, 62 }, { 63, 75 }, { 76, 99 }, { 100, 100 } }
  local function low(name) return (tostring(name or ''):lower():gsub('_', ' ')) end
  function Radar.scheme(name)
    local n = low(name)
    local function s(o1, o2, wet, conv, vv) return { o1 = o1, o2 = o2, wet = wet, conv = conv and 1 or 0, vv = vv and 1 or 0 } end
    if n:find('thunder', 1, true) then return s(8, 8, n:find('heavy', 1, true) and 'heavyThunder' or n:find('light', 1, true) and 'lightThunder' or 'thunder', true, true) end
    if n:find('shower', 1, true) or n:find('squall', 1, true) then return s(8, 8, 'showers', true) end
    if n:find('drizzle', 1, true) then
      if n:find('heavy', 1, true) then return s(8, 8, 'heavyDrizzle') end
      return s(8, 8, n:find('light', 1, true) and 'lightDrizzle' or 'drizzle')
    end
    if n:find('rain', 1, true) then return s(8, 8, n:find('heavy', 1, true) and 'heavyRain' or n:find('light', 1, true) and 'lightRain' or 'rain') end
    if n:find('overcast', 1, true) then return s(8, 8) end
    if n:find('broken', 1, true) then return s(5, 7) end
    if n:find('scattered', 1, true) then return s(3, 4) end
    if n:find('few', 1, true) then return s(1, 2) end
    if n:find('clear', 1, true) or n:find('no clouds', 1, true) then return s(0, 0) end
    return s(4, 4)
  end
  local function oktaMid(o) return (OKTA_PCT[o][1] + OKTA_PCT[o][2]) / 200 end
  function Radar.slotCover(name, nextName)
    return oktaMid(Radar.scheme(name).o2)
  end
  local MMH = { lightDrizzle = { 0, 0.30 }, drizzle = { 0.30, 0.50 }, heavyDrizzle = { 0.50, 1.0 }, lightRain = { 0, 2.5 }, rain = { 2.6, 10.0 },
    heavyRain = { 10.1, 50.0 }, showers = { 1.0, 30.0 }, lightThunder = { 15, 40 }, thunder = { 15, 70 }, heavyThunder = { 15, 100 } }
  function Radar.intensity(name, rainPct)
    local c = Radar.scheme(name).wet
    if not c then return 0 end
    local r = MMH[c]
    return r[1] + (r[2] - r[1]) * math.min(math.max(CarRead.num(rainPct), 0), 100) / 100
  end
  function Radar.slots(fc)
    local out = {}
    for _, f in ipairs(fc or {}) do
      local h, m = tostring(f.time or ''):match('^(%d+):(%d+)$')
      if h then
        local w = tostring(f.wind or '')
        local v1, v2 = w:match('(%d+%.?%d*)%s*%-%s*(%d+%.?%d*)%s*m/s')
        out[#out + 1] = { minute = tonumber(h) * 60 + tonumber(m), name = f.sky or f.type or '', rain = CarRead.num(f.rain), air = CarRead.num(f.air),
          road = CarRead.num(f.road), vmin = tonumber(v1) or 0, vmax = tonumber(v2) or tonumber(v1) or 0,
          dir = tonumber(w:match('(%d+)%s*°') or w:match('at%s*(%d+)')) or 0, trans = CarRead.num(f.trans), tsec = CarRead.num(f.tsec) }
      end
    end
    if #out == 0 then
      local name
      for k, v in pairs(ac.WeatherType or {}) do if v == sim.weatherType then name = k end end
      local v = CarRead.num(sim.windSpeedKmh) / 3.6
      out[1] = { minute = 0, name = name and name:gsub('(%l)(%u)', '%1 %2') or '-', rain = CarRead.num(sim.rainIntensity) * 100, vmin = v, vmax = v,
        dir = CarRead.num(sim.windDirectionDeg) % 360, air = CarRead.num(sim.ambientTemperature), road = CarRead.num(sim.roadTemperature), trans = 0 }
    end
    return out
  end
  local function lerp(a, b, u) return a + (b - a) * u end
  local function turn(a, b, u) return (a + ((b - a + 540) % 360 - 180) * u + 360) % 360 end
  local function line(slots)
    local sl, add = {}, 0
    for _, x in ipairs(slots) do
      local m = x.minute + add
      if #sl > 0 and m < sl[#sl].minute then add = add + 1440; m = x.minute + add end
      local y = {}
      for kk, vv in pairs(x) do y[kk] = vv end
      y.minute = m
      sl[#sl + 1] = y
    end
    for i, s in ipairs(sl) do
      local nx = sl[math.min(i + 1, #sl)]
      local sc = Radar.scheme(s.name)
      s.q = { cover = Radar.slotCover(s.name, nx.name), wet = sc.wet and 1 or 0, mmh = Radar.intensity(s.name, s.rain), conv = sc.conv, vv = sc.vv }
      local tr = math.min(math.max(CarRead.num(s.trans), 0), 99) / 100
      s.trFrom = (tr > 0 and nx ~= s) and (nx.minute - (nx.minute - s.minute) / (1 - tr)) or nil
      s.idx = i
    end
    for i, s in ipairs(sl) do
      local T = CarRead.num(s.tsec) / 60
      local tr = math.min(math.max(CarRead.num(s.trans), 0), 100) / 100
      if T > 0 and tr > 0 then
        local tg
        for j = i + 1, #sl do if low(sl[j].name) ~= low(s.name) then tg = sl[j]; break end end
        if tg then s.trFrom, s.trTo, s.tg = s.minute - tr * T, s.minute - tr * T + T, tg else s.trFrom = nil end
      end
    end
    return sl
  end
  local function mixQ(a, b, w)
    return { cover = lerp(a.cover, b.cover, w), wet = lerp(a.wet, b.wet, w), mmh = lerp(a.mmh, b.mmh, w), conv = lerp(a.conv, b.conv, w), vv = lerp(a.vv, b.vv, w) }
  end
  local function stateAt(sl, M)
    local i = 1
    while i + 1 <= #sl and sl[i + 1].minute <= M do i = i + 1 end
    local a, b = sl[i], sl[math.min(i + 1, #sl)]
    local span = b.minute - a.minute
    local u = span > 0 and math.min(math.max((M - a.minute) / span, 0), 1) or 0
    local q, name = a.q, a.name
    if a.trTo then
      local w = math.min(math.max((M - a.trFrom) / (a.trTo - a.trFrom), 0), 1)
      q = mixQ(a.q, a.tg.q, w)
      if w >= 0.5 then name = a.tg.name end
    elseif b.trTo and b ~= a then
      if M >= b.trFrom then
        local w = math.min(math.max((M - b.trFrom) / (b.trTo - b.trFrom), 0), 1)
        q = mixQ(a.q, b.tg.q, w)
        if w >= 0.5 then name = b.tg.name end
      end
    elseif a.trFrom and b ~= a then
      local w = math.min(math.max((M - a.trFrom) / (b.minute - a.trFrom), 0), 1)
      q = mixQ(a.q, b.q, w)
      if w >= 0.5 then name = b.name end
    elseif b.trFrom and b ~= a then
      local c = sl[math.min(b.idx + 1, #sl)]
      if c ~= b and M >= b.trFrom then q = mixQ(a.q, c.q, math.min(math.max((M - b.trFrom) / (c.minute - b.trFrom), 0), 1)) end
    end
    return { cover = q.cover, wet = q.wet, mmh = q.mmh, conv = q.conv, vv = q.vv, name = name, air = lerp(a.air or 0, b.air or 0, u),
      road = lerp(a.road or 0, b.road or 0, u), vmin = lerp(a.vmin, b.vmin, u), vmax = lerp(a.vmax, b.vmax, u), dir = turn(a.dir, b.dir, u) }
  end
  local NEAR, TAU = 60, 10
  local function nearness(d) return math.max(0, 1 - math.log(1 + d / TAU) / math.log(1 + NEAR / TAU)) end
  local function windowOf(sl, M0)
    local wet, cover, conv, vv, inMm = 0, 0, 0, 0, 0
    for m = 0, 9 do
      local s = stateAt(sl, M0 + m + 0.5)
      wet, cover, conv, vv = wet + s.wet / 10, cover + s.cover / 10, conv + s.conv / 10, vv + s.vv / 10
      if s.wet > 0 then inMm = inMm + s.mmh / 10 end
    end
    local g, nearMm, after = 0, 0, false
    for d = 0, NEAR do
      local before, aft = stateAt(sl, M0 - d - 0.5), stateAt(sl, M0 + 10 + d + 0.5)
      for _, x in ipairs({ before, aft }) do
        local v = nearness(d) * x.wet
        if x.wet > 0 and v > g then g, nearMm = v, x.mmh / x.wet end
      end
      if aft.wet > 0 and d <= 20 then after = true end
    end
    local ref = wet > 0 and (inMm + nearMm * (1 - wet)) or nearMm
    local dryAfter = (wet > 0 and not after) and 1 or 0
    local p = math.floor(math.min(math.max(0.9 * wet + 0.45 * g * (1 - wet) - 0.15 * wet * dryAfter, 0), 0.95) * 20 + 1e-9) / 20
    local s0 = stateAt(sl, M0)
    return { minute = M0 % 1440, cover = cover, conv = conv, vv = vv, chance = p, mmh = p * ref, ref = ref, air = s0.air, road = s0.road, vmin = s0.vmin,
      vmax = s0.vmax, dir = s0.dir, name = stateAt(sl, M0 + 5).name }
  end
  function Radar.segments(slots, m0, count)
    local sl = line(slots)
    if #sl == 0 then return {} end
    local start = m0
    if start < sl[1].minute - 720 then start = start + 1440 end
    local out = {}
    for k = 0, count - 1 do out[#out + 1] = windowOf(sl, start + k * 10) end
    return out
  end
  local SKY_OKTA = { [0] = 'clear', 'few', 'few', 'scattered', 'scattered', 'broken', 'broken', 'broken', 'overcast' }
  function Radar.skyOf(seg)
    if seg.vv >= 0.5 then return TEXTS.wxSky.thunder end
    local o = 0
    for k = 0, 8 do if seg.cover * 100 >= OKTA_PCT[k][1] - 0.5 then o = k end end
    return TEXTS.wxSky[SKY_OKTA[o]]
  end
  function Radar.precipOf(mm)
    if mm < 0.01 then return '' end
    local P = TEXTS.wxPrecip
    if mm < 0.30 then return P.lightDrizzle elseif mm <= 0.50 then return P.drizzle elseif mm <= 2.5 then return P.lightRain
    elseif mm <= 10 then return P.rain elseif mm <= 50 then return P.heavyRain end
    return P.violentRain
  end
  local function compass(d) return TEXTS.compass[math.floor(((d % 360) + 11.25) / 22.5) % 16 + 1] end
  local function hhmm(m) return string.format('%02d:%02d', math.floor(m / 60) % 24, math.floor(m + 0.5) % 60) end
  function Radar.bulletin(seg)
    if #seg == 0 then return {} end
    local a, z = seg[1], seg[#seg]
    local function kmh(s) return string.format('%d-%d km/h', math.floor(s.vmin * 3.6 + 0.5), math.floor(s.vmax * 3.6 + 0.5)) end
    local out = { string.format(TEXTS.wxBulletin.now, hhmm(a.minute), Radar.skyOf(a), math.floor(a.air + 0.5), math.floor(a.road + 0.5),
      compass(a.dir), kmh(a)) }
    local r
    for _, s in ipairs(seg) do if not r and s.chance >= 0.2 and s.mmh >= 0.01 then r = s end end
    out[#out + 1] = r and string.format(TEXTS.wxBulletin.rain, hhmm(r.minute), Radar.precipOf(r.ref),
      math.floor(r.chance * 100 + 0.5), r.mmh) or TEXTS.wxBulletin.dry
    out[#out + 1] = string.format(TEXTS.wxBulletin.by, hhmm(z.minute), Radar.skyOf(z):lower(),
      z.mmh >= 0.01 and string.format(', %s %d%%', Radar.precipOf(z.ref), math.floor(z.chance * 100 + 0.5)) or '', math.floor(z.air + 0.5),
      math.floor(z.road + 0.5), compass(z.dir), kmh(z))
    local drop = math.floor(a.road - z.road + 0.5)
    if math.abs(drop) >= 3 then
      out[#out + 1] = drop > 0 and string.format(TEXTS.wxBulletin.falling, drop) or string.format(TEXTS.wxBulletin.rising, -drop)
    end
    return out
  end
  local PRE, POST = 240, 360
  function Radar.gAt(FL, T)
    local p = math.min(math.max((T - FL.G0) / 10, 0), FL.N - 1)
    local i = math.floor(p)
    local u = p - i
    local a, b = FL.grid[i + 1], FL.grid[math.min(i + 2, FL.N)]
    return { cover = lerp(a.cover, b.cover, u), mmh = lerp(a.mmh, b.mmh, u), conv = lerp(a.conv, b.conv, u), vv = lerp(a.vv, b.vv, u),
      dir = turn(a.dir, b.dir, u), v = (lerp(a.vmin, b.vmin, u) + lerp(a.vmax, b.vmax, u)) / 2 }
  end
  function Radar.forecastLine(slots)
    local sl = line(slots)
    if #sl == 0 then return nil end
    local first, last = sl[1].minute, sl[#sl].minute
    local hour0 = math.floor(first / 60) * 60
    local FL = { sl = sl, first = first, last = last, hour0 = hour0, G0 = hour0 - PRE, grid = {}, ax = { 0 }, ay = { 0 } }
    FL.N = math.ceil((last + POST - FL.G0) / 10) + 1
    for k = 0, FL.N - 1 do FL.grid[k + 1] = windowOf(sl, FL.G0 + k * 10) end
    for k = 1, FL.N * 10 do
      local w = Radar.gAt(FL, FL.G0 + k - 0.5)
      local r = math.rad(w.dir + 180)
      FL.ax[k + 1] = FL.ax[k] + math.sin(r) * w.v * 60
      FL.ay[k + 1] = FL.ay[k] - math.cos(r) * w.v * 60
    end
    return FL
  end
  function Radar.airAt(FL, T)
    local n = #FL.ax
    local x = math.min(math.max(T - FL.G0, 0), n - 1)
    local i = math.min(math.floor(x), n - 2)
    local u = x - i
    return lerp(FL.ax[i + 1], FL.ax[i + 2], u), lerp(FL.ay[i + 1], FL.ay[i + 2], u)
  end
  function Radar.lineMinute(FL, m)
    local best, bd = m, math.huge
    for d = -1, 2 do
      local x = m + d * 1440
      local e = math.abs(x - math.min(math.max(x, FL.first), FL.last))
      if e < bd then best, bd = x, e end
    end
    return best
  end
  function Radar.segAt(FL, M) return FL.grid[math.min(math.max(math.floor((M - FL.G0) / 10 + 0.5), 0), FL.N - 1) + 1] end
  function Radar.nowMinute() return math.floor(CarRead.num(sim.timeHours) * 60 + CarRead.num(sim.timeMinutes)) end
  function Radar.lineOf(slots)
    local key = {}
    for _, x in ipairs(slots) do
      key[#key + 1] = string.format('%d|%s|%g|%g|%g|%g|%g|%g|%g', x.minute, tostring(x.name), x.rain or 0, x.vmin or 0, x.vmax or 0, x.dir or 0, x.trans or 0, x.road or 0,
        x.tsec or 0)
    end
    key = table.concat(key, ';')
    if Radar.flKey ~= key then Radar.flKey, Radar.fl = key, Radar.forecastLine(slots) end
    return Radar.fl
  end
  function Radar.fixed(fc)
    local T = Radar.tbl
    if T and T.fc == fc and #fc > 0 then return T end
    local slots = Radar.slots(fc)
    T = { fc = fc, slots = slots, fl = Radar.lineOf(slots) }
    Radar.tbl = T
    return T
  end
  function Radar.textSegments(fc)
    local FL = Radar.fixed(fc).fl
    if not FL then return {} end
    local H = math.floor(Radar.lineMinute(FL, Radar.nowMinute()) / 60) * 60
    local out = {}
    local M = H
    while M <= math.max(FL.last, H + 50) and #out < 144 do out[#out + 1] = Radar.segAt(FL, M); M = M + 10 end
    return out
  end
  local RADAR_BACK, RADAR_STEPS = 24, 60
  local function radarShader()
    local w, d = {}, {}
    for i = 0, RADAR_STEPS do w[#w + 1] = 'gW' .. i end
    for i = 0, RADAR_STEPS / 2 do d[#d + 1] = 'gD' .. i end
    return [[
uint rhash(int x, int y, int seed) {
  uint h = ((uint)x * 0x8da6b343u) ^ ((uint)y * 0xd8163841u) ^ ((uint)seed * 0xcb1ab31fu);
  h ^= h >> 13; h *= 0x85ebca6bu; h ^= h >> 16;
  return h;
}
float rval(int x, int y, int seed) { return (float)rhash(x, y, seed) / 4294967295.0 * 2 - 1; }
float vnoise(float2 p, int seed) {
  float2 i = floor(p); float2 f = p - i;
  float2 u = f * f * f * (f * (f * 6 - 15) + 10);
  int ix = (int)i.x, iy = (int)i.y;
  float a = rval(ix, iy, seed), b = rval(ix + 1, iy, seed), c = rval(ix, iy + 1, seed), d = rval(ix + 1, iy + 1, seed);
  return a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y;
}
float field(float2 p, int seed, float gain, float norm, int oct, float wave) {
  float sum = 0, amp = 1, fr = 1.0 / wave;
  [loop] for (int o = 0; o < 11; o++) { if (o >= oct) break; sum += amp * vnoise(p * fr, seed * 131 + o * 1013); amp *= gain; fr *= 2; }
  return sum / norm;
}
float3 pcolor(float v) {
  v = saturate(v);
  if (v <= 0.30) return lerp(float3(120, 215, 240), float3(40, 120, 230), v / 0.30);
  if (v <= 0.55) return lerp(float3(40, 120, 230), float3(250, 220, 40), (v - 0.30) / 0.25);
  if (v <= 0.78) return lerp(float3(250, 220, 40), float3(240, 120, 40), (v - 0.55) / 0.23);
  return lerp(float3(240, 120, 40), float3(170, 60, 220), (v - 0.78) / 0.22);
}
float rankOf(float nc) {
  float Q[21] = { -3.6373, -1.5227, -1.1635, -0.9344, -0.7436, -0.5829, -0.4423, -0.3051, -0.1743, -0.0519, 0.0697, 0.193, 0.3197, 0.4493, 0.5842, 0.7342, 0.8983, 1.0897, 1.3166, 1.6456, 3.6192 };
  if (nc <= Q[0]) return 0;
  if (nc >= Q[20]) return 1;
  int i = 0;
  [loop] for (int k = 0; k < 19; k++) { if (nc > Q[k + 1]) i = k + 1; }
  return (i + (nc - Q[i]) / (Q[i + 1] - Q[i])) / 20;
}
float4 main(PS_IN pin) {
  float4 W[]] .. (RADAR_STEPS + 1) .. [[] = { ]] .. table.concat(w, ', ') .. [[ };
  float4 D[]] .. (RADAR_STEPS / 2 + 1) .. [[] = { ]] .. table.concat(d, ', ') .. [[ };
  float2 P = float2(-gHalf + pin.Tex.x * 2 * gHalf, -gHalf + pin.Tex.y * 2 * gHalf);
  float best = 1e30, at = 0;
  float2 prev = P + D[0].xy;
  [loop] for (int i = 1; i <= ]] .. RADAR_STEPS .. [[; i++) {
    float4 dd = D[i / 2];
    float2 cur = P + ((i % 2) == 0 ? dd.xy : dd.zw);
    float2 e = cur - prev;
    float ll = dot(e, e);
    float u = ll > 0 ? saturate(-dot(prev, e) / ll) : 0;
    float2 x = prev + e * u;
    float dist = dot(x, x);
    if (dist < best) { best = dist; at = i - 1 + u; }
    prev = cur;
  }
  int ia = min((int)floor(at), ]] .. (RADAR_STEPS - 1) .. [[);
  float4 w = lerp(W[ia], W[ia + 1], at - ia);
  float cover = w.x, mmh = w.y, conv = w.z, vv = w.w;
  float2 q = P - gOff;
  float rank = rankOf(field(q, 9, 0.757858, 0.6831, 11, 2000.0));
  float cov = max(cover, vv);
  float3 col = float3(9, 13, 18);
  if (cov <= 0 || rank < 1 - cov) return float4(col / 255, 1);
  float th = pow(saturate((rank - (1 - cov)) / cov), 1 - 0.5 * conv);
  th = saturate(th + 0.22 * field(q, 13, 0.6, 0.6, 6, 700.0) * (0.4 + th));
  float edge = saturate(th / 0.06);
  float shade = (240 - 125 * th) * (1 - vv) + (92 - 60 * th) * vv;
  col = lerp(col, float3(shade, shade, shade + 5), edge * (0.82 + 0.15 * th));
  if (mmh > 0.005) {
    float bub = saturate(0.5 + 0.5 * field(q, 5, 0.55, 0.5412, 6, 1600.0));
    float rate = mmh * pow(bub, 2 + 2 * conv) * pow(th, 1 + conv) * (3 + 5 * conv);
    if (rate >= max(0.02, mmh * 0.9)) {
      float pos = saturate(log(rate / 0.05) / log(100.0 / 0.05));
      col = lerp(col, pcolor(pos), saturate(0.45 + (rate / mmh - 0.9) * 0.4));
    }
  }
  return float4(col / 255, 1);
}
]]
  end
  local RADAR_SHADER = radarShader()
  function Radar.values(FL, t, half)
    local v = { gHalf = half }
    local ox, oy = Radar.airAt(FL, t)
    v.gOff = vec2(ox, oy)
    local px, py = {}, {}
    for i = 0, RADAR_STEPS do
      local T = t + (i - RADAR_BACK) * 10
      local w = Radar.gAt(FL, T)
      v['gW' .. i] = vec4(w.cover, w.mmh, w.conv, w.vv)
      local bx, by = Radar.airAt(FL, T)
      px[i], py[i] = bx - ox, by - oy
    end
    for j = 0, RADAR_STEPS / 2 do
      local a, b = 2 * j, math.min(2 * j + 1, RADAR_STEPS)
      v['gD' .. j] = vec4(px[a], py[a], px[b], py[b])
    end
    return v
  end
  Radar.ZOOM = { 150, 300, 600, 900, 1500, 2500, 5000, 10000 }
  Radar.RING = { [150] = 50, [300] = 100, [600] = 200, [900] = 250, [1500] = 500, [2500] = 1000, [5000] = 1000, [10000] = 2500 }
  Radar.zoomAt = 4
  function Radar.half() return Radar.ZOOM[Radar.zoomAt] end
  function Radar.zoomStep(dir)
    local n = Radar.zoomAt - dir
    if n < 1 or n > #Radar.ZOOM then return false end
    Radar.zoomAt = n
    return true
  end
  Desktop.radarZoom = Radar.zoomStep
  function Radar.draw(a, side, s, fc, big)
    local half = Radar.half()
    local zoom = half <= 2500 and 'track' or 'wide'
    local FL = Radar.fixed(fc).fl
    local H = math.floor(Radar.lineMinute(FL, Radar.nowMinute()) / 60) * 60
    local k = math.floor(state.ui.clock) % 6
    local t = H + k * 10
    local sl = Radar.segAt(FL, t)
    local minute = t % 1440
    local b = vec2(a.x + side, a.y + side)
    ui.pushClipRect(a, b, true)
    if ui.ExtraCanvas then
      Radar.canvas = Radar.canvas or ui.ExtraCanvas(vec2(256, 256))
      local key = half .. '|' .. t .. '|' .. #Radar.flKey
      if Radar.canvasT ~= key then
        local ok = Radar.canvas:updateWithShader({ values = Radar.values(FL, t, half), shader = RADAR_SHADER, async = true, cacheKey = 676 })
        if ok ~= false then Radar.canvasT = key end
      end
      ui.drawImage(Radar.canvas, a, b)
    end
    local c = vec2(a.x + side / 2, a.y + side / 2)
    local kk = side / (2 * half)
    if big then
      local stepM = Radar.RING[half] or 250
      local r = stepM
      while r < half * 1.5 do
        ui.drawCircle(c, r * kk, rgbm(0.27, 0.35, 0.39, 1), 48, 1)
        if r % (stepM * 2) == 0 and r * kk < side / 2 - 8 * s then
          drawText(string.format('%g km', r / 1000), FONT_MONO, 8 * s, TMP.a:set(c.x + r * kk * 0.707 + 2 * s, c.y - r * kk * 0.707 - 11 * s), rgbm(0.51, 0.59, 0.63, 1))
        end
        r = r + stepM
      end
      ui.drawSimpleLine(vec2(c.x, a.y), vec2(c.x, b.y), rgbm(0.18, 0.24, 0.27, 1), 1)
      ui.drawSimpleLine(vec2(a.x, c.y), vec2(b.x, c.y), rgbm(0.18, 0.24, 0.27, 1), 1)
    end
    local geo = Radar.geometry()
    if geo then
      local function sp(q) return vec2(c.x + q[1] * kk, c.y + q[2] * kk) end
      local lines = zoom == 'track' and { geo.L, geo.R } or { geo.Q }
      for _, list in ipairs(lines) do
        for i = 1, #list do ui.pathLineTo(sp(list[i])) end
        ui.pathStroke(rgbm(1, 1, 1, 1), true, (zoom == 'track' and 1.2 or 1.6) * s)
      end
    else
      drawText(TEXTS.scrRadarNoTrack, FONT_MONO, 9 * s, TMP.a:set(a.x + 8 * s, a.y + 8 * s), COLOR_OFF)
    end
    drawText(TEXTS.compass[1], FONT_TITLE, 10 * s, TMP.a:set(b.x - 13 * s, a.y + 3 * s), rgbm(1, 1, 1, 1))
    ui.drawTriangleFilled(vec2(b.x - 9 * s, a.y + 16 * s), vec2(b.x - 13 * s, a.y + 25 * s), vec2(b.x - 5 * s, a.y + 25 * s), rgbm(1, 1, 1, 1))
    if big then
      local w = vec2(a.x + 20 * s, b.y - 20 * s)
      local bb = math.rad(sl.dir)
      ui.drawCircle(w, 13 * s, rgbm(0.8, 0.8, 0.8, 1), 24, 1)
      local e = vec2(w.x - 10 * s * math.sin(bb), w.y + 10 * s * math.cos(bb))
      ui.drawSimpleLine(vec2(w.x + 10 * s * math.sin(bb), w.y - 10 * s * math.cos(bb)), e, rgbm(1, 1, 1, 1), 2 * s)
      ui.drawCircleFilled(e, 2.5 * s, rgbm(1, 1, 1, 1), 8)
      drawText(string.format('%s %.0f-%.0f km/h', compass(sl.dir), sl.vmin * 3.6, sl.vmax * 3.6),
        FONT_MONO, 9 * s, TMP.a:set(w.x + 18 * s, w.y - 6 * s), rgbm(1, 1, 1, 1))
    else
      drawText(string.format('%02d:%02d', math.floor(minute / 60) % 24, minute % 60), FONT_MONO, 9 * s, TMP.a:set(a.x + 5 * s, b.y - 14 * s), YELLOW)
      local x1, x2 = a.x + 46 * s, b.x - 6 * s
      ui.drawRect(vec2(x1, b.y - 9 * s), vec2(x2, b.y - 5 * s), rgbm(0.35, 0.35, 0.35, 1))
      ui.drawRectFilled(vec2(x1, b.y - 9 * s), vec2(x1 + (x2 - x1) * k / 5, b.y - 5 * s), YELLOW)
    end
    ui.popClipRect()
    ui.drawRect(a, b, big and rgbm(0.27, 0.3, 0.35, 1) or rgbm(0.16, 0.43, 0.9, 1))
    return minute, sl
  end
  local WX_PAGE = 6
  local wxPage = 1
  local function wxPages(fc) return math.max(math.ceil(#fc / WX_PAGE), 1) end
  Desktop.weatherStep = function(dir)
    local fc = Weather.forecast or RecordSync.base.forecast.list or {}
    if #fc > 0 then fc = Radar.textSegments(fc) end
    local n = wxPage + dir
    if n < 1 or n > wxPages(fc) then return false end
    wxPage = n
    return true
  end
  local function weatherScreen(car, w, h, s)
    local mode = filter.weather or 'forecast'
    local fc = Weather.forecast or RecordSync.base.forecast.list or {}
    local big = filter.radarBig ~= false
    local segs = #fc > 0 and Radar.textSegments(fc) or {}
    wxPage = math.min(wxPage, wxPages(segs))
    local paged = #segs > WX_PAGE
    local rows = mode == 'map' and (big and 30 or 21.5) or (7 + (#segs > 0 and (math.min(#segs, WX_PAGE) + 2) or 0))
    local p1, p2, y = frame('weather', w, h, s, rows, TEXTS.scrWeather, nil)
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
      drawText(clock, FONT_MONO, 11 * s, TMP.a:set(p1.x + 14 * s + textWidth(TEXTS.scrWeather, FONT_TITLE, 12 * s) + 10 * s, p1.y + 5 * s),
        COLOR_TITLE)
    end
    local x = p2.x - 14 * s
    for i = 2, 1, -1 do
      local m = i == 1 and 'forecast' or 'map'
      local t = TEXTS.scrWeatherModes[m]
      local tw = textWidth(t, FONT_MONO, 9 * s)
      local a, b = vec2(x - tw - 6 * s, p1.y + 5 * s), vec2(x, p1.y + 18 * s)
      if mode == m then ui.drawRectFilled(a, b, YELLOW, 2 * s) else ui.drawRect(a, b, TMP.edge30, 2 * s) end
      drawText(t, FONT_MONO, 9 * s, TMP.a:set(a.x + 3 * s, a.y + 1 * s), mode == m and TMP.dark or COLOR_DIM)
      Drag.clickable(a, b, function() Desktop.weatherMode(m) end)
      x = a.x - 4 * s
    end
    local okC, cs = pcall(ac.getConditionsSet)
    local nowName = weatherName(sim.weatherType)
    if mode == 'map' then
      local side = p2.x - p1.x - 20 * s
      local zx = p1.x + 10 * s
      local zt = string.format(TEXTS.scrRadarZoom, 2 * Radar.half() / 1000)
      for _, z in ipairs({ { -1, '-' }, { 0, zt }, { 1, '+' } }) do
        local tw = textWidth(z[2], FONT_MONO, 9 * s)
        local za, zb = vec2(zx, y), vec2(zx + tw + 8 * s, y + 13 * s)
        if z[1] ~= 0 then
          ui.drawRect(za, zb, TMP.edge30, 2 * s)
          Drag.clickable(za, zb, function() Radar.zoomStep(z[1]) end)
        end
        drawText(z[2], FONT_MONO, 9 * s, TMP.a:set(za.x + 4 * s, za.y + 1 * s), z[1] == 0 and YELLOW or COLOR_DIM)
        zx = zb.x + 4 * s
      end
      local st = big and TEXTS.scrRadarSmall or TEXTS.scrRadarBig
      local sw = textWidth(st, FONT_MONO, 9 * s)
      local sa, sb = vec2(p2.x - 10 * s - sw - 8 * s, y), vec2(p2.x - 10 * s, y + 13 * s)
      ui.drawRect(sa, sb, TMP.edge30, 2 * s)
      drawText(st, FONT_MONO, 9 * s, TMP.a:set(sa.x + 4 * s, sa.y + 1 * s), COLOR_DIM)
      Drag.clickable(sa, sb, function() filter.radarBig = not big end)
      local minute, sl = Radar.draw(vec2(p1.x + 10 * s, y + 18 * s), side, s, fc, big)
      if big then
        drawText(string.format('%02d:%02d', math.floor(minute / 60) % 24, minute % 60), FONT_MONO, 10 * s, TMP.a:set(zx + 6 * s, y), YELLOW)
        local wet = sl.mmh >= 0.01
        local xr = sa.x - 6 * s
        local xc = xr - textWidth('0.00 mm/h', FONT_MONO, 9 * s) - 6 * s
        if wet then
          drawTextRight(string.format('%.2f mm/h', sl.mmh), FONT_MONO, 9 * s, xr, y + 1 * s, COLOR_TITLE)
          drawTextRight(string.format('%d%%', math.floor(sl.chance * 100 + 0.5)), FONT_MONO, 9 * s, xc, y + 1 * s, YELLOW)
        end
        local nm, room = Radar.skyOf(sl), xc - textWidth('100%', FONT_MONO, 9 * s) - 6 * s - (zx + 46 * s)
        nm = fitText(nm, FONT_MONO, 9 * s, room)
        drawText(nm, FONT_MONO, 9 * s, TMP.a:set(zx + 46 * s, y + 1 * s), COLOR_TITLE)
        local ly = y + 18 * s + side + 8 * s
        drawText(TEXTS.scrRadarPrec, FONT_MONO, 8.5 * s, TMP.a:set(p1.x + 14 * s, ly), COLOR_DIM)
        local bx1, bx2 = p1.x + 100 * s, p2.x - 14 * s
        local n = 64
        for i = 0, n - 1 do
          local r, g, b = Radar.pcolor(i / (n - 1))
          ui.drawRectFilled(vec2(bx1 + (bx2 - bx1) * i / n, ly + 2 * s), vec2(bx1 + (bx2 - bx1) * (i + 1) / n + 0.5, ly + 9 * s), rgbm(r / 255, g / 255, b / 255, 1))
        end
        if wet then
          local pos = math.min(math.max(math.log(sl.mmh / 0.05) / math.log(100 / 0.05), 0), 1)
          local cx = bx1 + (bx2 - bx1) * pos
          ui.drawRect(vec2(bx1, ly + 1 * s), vec2(cx, ly + 10 * s), rgbm(1, 1, 1, 1), 0, nil, 1)
          ui.drawSimpleLine(vec2(cx, ly), vec2(cx, ly + 11 * s), rgbm(1, 1, 1, 1), 2 * s)
          ui.drawTriangleFilled(vec2(cx - 4 * s, ly - 5 * s), vec2(cx + 4 * s, ly - 5 * s), vec2(cx, ly), rgbm(1, 1, 1, 1))
        end
        drawText(TEXTS.scrRadarLight, FONT_MONO, 8 * s, TMP.a:set(bx1, ly + 11 * s), COLOR_DIM)
        drawText(TEXTS.scrRadarHeavy, FONT_MONO, 8 * s, TMP.a:set(bx1 + (bx2 - bx1) * 0.55 - 12 * s, ly + 11 * s), COLOR_DIM)
        drawTextRight(TEXTS.scrRadarExtreme, FONT_MONO, 8 * s, bx2, ly + 11 * s, COLOR_DIM)
        local lroom = p2.x - 14 * s - (p1.x + 14 * s)
        local function fit(text) return fitText(text, FONT_MONO, 8 * s, lroom) end
        drawText(fit(TEXTS.scrRadarClouds), FONT_MONO, 8 * s, TMP.a:set(p1.x + 14 * s, ly + 25 * s), COLOR_DIM)
        drawText(fit(string.format(TEXTS.scrRadarLoop, #fc > 0 and TEXTS.scrWeatherAnim or TEXTS.scrWeatherStatic)), FONT_MONO, 8 * s, TMP.a:set(p1.x + 14 * s, ly + 37 * s), COLOR_DIM)
      end
    else
      local kmhW = CarRead.num(sim.windSpeedKmh)
      local lines = {
        { TEXTS.scrWxTime, clock },
        { TEXTS.scrWxSky, nowName or '-' },
        { TEXTS.scrWxAir, string.format('%.0f / %.0f C', CarRead.num(sim.ambientTemperature), CarRead.num(sim.roadTemperature)) },
        { TEXTS.scrWxWind, string.format(TEXTS.wxWindFmt, kmhW, CarRead.num(sim.windDirectionDeg) % 360) },
        { TEXTS.scrWxRain, string.format(TEXTS.wxRainFmt, CarRead.num(sim.rainIntensity) * 100, CarRead.num(sim.rainWetness) * 100) },
        { TEXTS.scrTrack, string.format(TEXTS.wxGripFmt, CarRead.num(sim.roadGrip) * 100) },
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
        row(p1, y, s, { { TEXTS.hdr.time, 14, COLOR_AXIS }, { TEXTS.hdr.sky, 70, COLOR_AXIS }, { TEXTS.hdr.precip, 210, COLOR_AXIS, true },
          { TEXTS.hdr.air, 240, COLOR_AXIS, true }, { TEXTS.hdr.track, 286, COLOR_AXIS, true } })
        if paged then
          local t = string.format(TEXTS.scrWxPage, wxPage, wxPages(segs))
          local tw = textWidth(t, FONT_MONO, FS * s)
          local cx = p1.x + 145 * s
          drawText(t, FONT_MONO, FS * s, TMP.a:set(cx - tw / 2, y), COLOR_DIM)
          Drag.clickable(vec2(cx - tw / 2 - 4 * s, y), vec2(cx, y + ROW * s), function() Desktop.weatherStep(-1) end)
          Drag.clickable(vec2(cx, y), vec2(cx + tw / 2 + 4 * s, y + ROW * s), function() Desktop.weatherStep(1) end)
        end
        y = y + ROW * s
        for k = (wxPage - 1) * WX_PAGE + 1, math.min(wxPage * WX_PAGE, #segs) do
          local f = segs[k]
          local sky = Radar.skyOf(f)
          row(p1, y, s, { { string.format('%02d:%02d', math.floor(f.minute / 60) % 24, f.minute % 60), 14 }, { sky, 70 },
            { string.format(TEXTS.wxProb, math.floor(f.chance * 100 + 0.5)), 210, nil, true },
            { string.format('%.0f', f.air), 240, nil, true }, { string.format('%.0f', f.road), 286, nil, true } })
          y = y + ROW * s
        end
      end
    end
    Drag.icons('weather', p1, p2, s)
  end
  local function eventLines()
    local out = {}
    for i = 0, (sim.sessionsCount or 0) - 1 do
      local ss = ac.getSession(i)
      if ss then
        local total = ss.durationMinutes and ss.durationMinutes > 0 and hms(ss.durationMinutes * 60000)
          or (ss.laps and ss.laps > 0 and string.format(TEXTS.lapsShort, ss.laps)) or '-'
        local now = i == sim.currentSessionIndex
        if now then total = hms(sessionElapsedMs()) .. ' / ' .. total end
        out[#out + 1] = { TEXTS.sessionName[ss.type] or '-', total, now }
      end
    end
    out[#out + 1] = false
    local st = config.driverStint
    local rules = {
      { TEXTS.evStops, config.pitStopsEnabled and tostring(config.pitStopsRequired) or '-' },
      { TEXTS.evSwaps, config.swapOn() and tostring(config.swapRequired or 0) or '-' },
      { TEXTS.evStint, (st.minMinutes > 0 or st.maxMinutes > 0) and string.format(TEXTS.evStintFmt, st.minMinutes, st.maxMinutes) or '-' },
      { TEXTS.evOrder, config.pitStopOrder },
      { TEXTS.evPitSpeed, string.format('%d km/h', config.pitSpeedLimit or 0) },
      { TEXTS.evRating, config.kmrRating.on and string.format(TEXTS.evRatingFmt, Audit.num(config.kmrRating.dsqAt)) or '-' },
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
  local function eventTitle() return config.eventName ~= '' and Lang.letters.upper(config.eventName) or TEXTS.scrEvent end
  local function eventScreen(car, w, h, s)
    local n = #eventLines()
    local p1, p2, y = frame('event', w, h, s, n + 0.6, eventTitle(), TEXTS.scrEventInfo)
    eventDraw(p1, p2, y, s)
    Drag.icons('event', p1, p2, s)
  end
  Desktop.eventBox = function(pr, s)
    local n = #eventLines()
    local p2 = vec2(pr.x, pr.y + (26 + n * ROW + 10) * s)
    local p1 = vec2(pr.x - 380 * s, pr.y)
    drawPanel(p1, p2, BORDER_YELLOW, s)
    drawText(eventTitle(), FONT_TITLE, 12 * s, TMP.a:set(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    drawTextRight(TEXTS.scrEventInfo, FONT_MONO, 11 * s, p2.x - 14 * s, p1.y + 5 * s, COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    eventDraw(p1, p2, p1.y + 26 * s, s)
    return p2.y
  end
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
    local x = p2.x - 14 * s
    local function button(t, on, fn)
      local tw = textWidth(t, FONT_MONO, 9 * s)
      local a, b = vec2(x - tw - 6 * s, p1.y + 5 * s), vec2(x, p1.y + 18 * s)
      if on then ui.drawRectFilled(a, b, YELLOW, 2 * s) else ui.drawRect(a, b, TMP.edge30, 2 * s) end
      drawText(t, FONT_MONO, 9 * s, TMP.a:set(a.x + 3 * s, a.y + 1 * s), on and TMP.dark or COLOR_DIM)
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
    row(p1, y, s, { { '#', 14, COLOR_AXIS }, { TEXTS.hdr.driver, 30, COLOR_AXIS }, { TEXTS.hdr.laps, 128, COLOR_AXIS, true },
      { TEXTS.hdr.best, 180, COLOR_AXIS, true }, { TEXTS.hdr.avg, 228, COLOR_AXIS, true } })
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
    local best = 0
    for _, l in ipairs(RaceTable.laps) do if l.valid and (best == 0 or l.ms < best) then best = l.ms end end
    local sessionBest = CarRead.num(sim.bestLapTimeMs)
    local function lapCells(l, x0)
      local col = not l.valid and RED or (l.ms == sessionBest and PURPLE) or (l.ms == best and GREEN) or COLOR_TITLE
      return { lapTime(l.ms), x0, col, true }, { not l.valid and TEXTS.lapTag.cut or l.pit and TEXTS.lapTag.pit or (l.ms == best and TEXTS.lapTag.best)
        or string.format('%+.3f', (l.ms - best) / 1000), x0 + 50, not l.valid and RED or (l.ms == best and GREEN) or RED, true }
    end
    local head = { { TEXTS.hdr.lap, 246, COLOR_AXIS }, { TEXTS.hdr.time, 336, COLOR_AXIS, true }, { TEXTS.hdr.delta, 386, COLOR_AXIS, true },
      { 'S1', 434, COLOR_AXIS, true }, { 'S2', 482, COLOR_AXIS, true }, { 'S3', 530, COLOR_AXIS, true } }
    if cmp then
      head[#head + 1] = { string.format(TEXTS.scrStintShort, cmp.n), 640, BLUE, true }
      head[#head + 1] = { TEXTS.hdr.delta, 690, COLOR_AXIS, true }
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
  local function lapsScreen(car, w, h, s)
    if LapsView.big then return lapsBig(car, w, h, s) end
    local laps = RaceTable.laps
    local sessionBest = CarRead.num(sim.bestLapTimeMs)
    local driver = tostring(ac.getDriverName(0) or ''):gsub('[,;|]', ' ')
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
    local et = TEXTS.scrLapsMore
    local etw = textWidth(et, FONT_MONO, 9 * s)
    local ea, eb = vec2(p2.x - 14 * s - etw - 6 * s, p1.y + 5 * s), vec2(p2.x - 14 * s, p1.y + 18 * s)
    ui.drawRect(ea, eb, TMP.edge30, 2 * s)
    drawText(et, FONT_MONO, 9 * s, TMP.a:set(ea.x + 3 * s, ea.y + 1 * s), COLOR_DIM)
    Drag.clickable(ea, eb, function() LapsView.big = true end)
    drawTextRight(string.format(TEXTS.scrLapN, car.lapCount + 1), FONT_MONO, 11 * s, ea.x - 8 * s, p1.y + 5 * s, COLOR_TITLE)
    local function sum(list) local t = 0; for _, l in ipairs(list) do t = t + l.ms end; return t end
    local ms = RaceTable.stintMs() or sum(now.laps)
    local rule = config.driverStint
    local tot = RaceTable.driveMs() or ms
    local stintCol = (rule.minMinutes <= 0 and rule.maxMinutes <= 0) and COLOR_DIM or ((rule.maxMinutes > 0 and tot > rule.maxMinutes * 60000) and RED)
      or ((rule.minMinutes > 0 and tot < rule.minMinutes * 60000) and YELLOW) or GREEN
    drawText(string.format(TEXTS.scrStintN, #stints, now.driver), FONT_TITLE, 10.5 * s, TMP.a:set(p1.x + 14 * s, y), COLOR_DIM)
    drawTextRight(string.format(TEXTS.scrStintInfo, #now.laps, hms(ms)) .. ((rule.minMinutes > 0 or rule.maxMinutes > 0) and
      (' - ' .. string.format(TEXTS.scrDriveTotal, hms(tot)) .. (rule.minMinutes > 0 and string.format(TEXTS.scrStintMin, rule.minMinutes) or '')) or ''),
      FONT_MONO, 10 * s, p2.x - 14 * s, y, stintCol)
    y = y + ROW * 1.5 * s
    row(p1, y, s, { { TEXTS.hdr.lap, 14, COLOR_AXIS }, { TEXTS.hdr.time, 118, COLOR_AXIS, true }, { TEXTS.hdr.delta, 172, COLOR_AXIS, true },
      { 'S1', 220, COLOR_AXIS, true }, { 'S2', 268, COLOR_AXIS, true }, { 'S3', 316, COLOR_AXIS, true } })
    y = y + ROW * s
    for k = #now.laps, #now.laps - n + 1, -1 do
      local l = now.laps[k]
      local col = not l.valid and RED or (l.ms == sessionBest and PURPLE) or (l.ms == best and GREEN) or COLOR_TITLE
      local cells = { { tostring(l.lap) .. (l.pit and ' P' or ''), 14, l.pit and YELLOW or COLOR_TITLE },
        { lapTime(l.ms), 118, col, true },
        { not l.valid and TEXTS.lapTag.cut or l.pit and TEXTS.lapTag.pit or (l.ms == best and TEXTS.lapTag.best) or string.format('%+.3f', (l.ms - best) / 1000),
          172, not l.valid and RED or (l.ms == best and GREEN) or (l.pit and COLOR_DIM) or RED, true } }
      for q = 1, 3 do cells[#cells + 1] = { secs(l.s[q]), 172 + q * 48, COLOR_TITLE, true } end
      row(p1, y, s, cells)
      y = y + ROW * s
    end
    if prev then
      drawSeparator(p1, p2, y + 3 * s, s)
      y = y + 8 * s
      local pb, total = 0, 0
      for _, l in ipairs(prev.laps) do
        total = total + l.ms
        if l.valid and (pb == 0 or l.ms < pb) then pb = l.ms end
      end
      drawText(string.format(TEXTS.scrStintN, #stints - 1, prev.driver), FONT_TITLE, 10.5 * s, TMP.a:set(p1.x + 14 * s, y), COLOR_DIM)
      drawTextRight(string.format(TEXTS.scrStintInfo, #prev.laps, hms(total)), FONT_MONO, 10 * s, p2.x - 14 * s, y, COLOR_DIM)
      y = y + ROW * s
      row(p1, y, s, { { string.format(TEXTS.scrBestAvg, lapTime(pb), lapTime(#prev.laps > 0 and total / #prev.laps or 0)), 14,
        COLOR_DIM } })
      y = y + ROW * 1.6 * s
    end
    drawSeparator(p1, p2, y + 3 * s, s)
    y = y + 8 * s
    row(p1, y, s, { { TEXTS.scrCarBest, 14, COLOR_DIM }, { best > 0 and (lapTime(best) .. ' (' .. bestDriver .. ')') or '-', 316,
      (best > 0 and best == sessionBest) and PURPLE or GREEN, true } })
    Drag.icons('laps', p1, p2, s)
  end
  local CHIP_H, CHIP_GAP, SEP = 30, 6, 10
  local function chip2(p, wdt, s, title, value, light)
    local a, b = vec2(p.x, p.y), vec2(p.x + wdt, p.y + CHIP_H * s)
    ui.drawRect(a, b, rgbm(1, 1, 1, 0.2), 3 * s)
    ui.drawCircleFilled(vec2(a.x + 10 * s, a.y + CHIP_H * s / 2), 3 * s, light, 12)
    drawText(title, FONT_TITLE, 9 * s, TMP.a:set(a.x + 19 * s, a.y + 3 * s), COLOR_TITLE)
    drawText(value, FONT_MONO, FS * s, TMP.a:set(a.x + 19 * s, a.y + 15 * s), value == '-' and COLOR_OFF or light)
  end
  local function raceScreen(car, w, h, s)
    local me = RaceTable.byIndex[0]
    local session = ac.getSession(sim.currentSessionIndex)
    local content = 3 * ROW + SEP + ROW + 3 * ROW + SEP + ROW + 2 * CHIP_H + CHIP_GAP + 4 + SEP + 8 * ROW + 4
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
      or (session and session.laps > 0 and string.format(TEXTS.lapsShort, session.laps)) or nil
    line(TEXTS.scrTime, hms(sessionElapsedMs()) .. (total and (' / ' .. total) or ''))
    line(TEXTS.scrPosition, me and (('P' .. me.pos) .. (me.class and string.format(TEXTS.posClassFmt, me.classPos, me.class)
      or '')) or '-')
    line(TEXTS.scrLap, tostring(me and me.laps + 1 or car.lapCount + 1))
    sep()
    drawText(TEXTS.scrGaps, FONT_TITLE, 9 * s, TMP.a:set(x0, y), COLOR_DIM)
    y = y + ROW * s
    local rows = RaceTable.rows
    local function gapRow(label, r)
      local gap = '-'
      if me and r and r ~= me then
        local dl = math.abs(r.laps - me.laps)
        local g = ac.getGapBetweenCars(0, r.index)
        gap = dl >= 1 and ('+' .. string.format(TEXTS.lapsShort, dl)) or string.format('%+.3f', -g)
      end
      row(p1, y, s, { { label, 14, COLOR_DIM, false, FONT_TEXT }, { r and r ~= me and ('#' .. r.number) or '-', 90 },
        { gap, 272, COLOR_TITLE, true } })
      y = y + ROW * s
    end
    gapRow(TEXTS.scrLeader, rows[1])
    gapRow(TEXTS.scrAhead, me and me.pos and rows[me.pos - 1])
    gapRow(TEXTS.scrBehind, me and me.pos and me.pos < (RaceTable.present or 0) and rows[me.pos + 1] or nil)
    sep()
    drawText(TEXTS.scrObligations, FONT_TITLE, 9 * s, TMP.a:set(x0, y), COLOR_DIM)
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
    local ms = RaceTable.driveMs()
    local rule = config.driverStint
    local stint = ms and (mmss(ms / 1000) .. (rule.minMinutes > 0 and string.format(TEXTS.scrStintMin, rule.minMinutes) or '')) or '-'
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
    local life = CarRead.tyreLife(car, 0, state.tyreLineKm[0] or 0)
    local wet = CarRead.num(sim.rainWetness) > 0.05
    local pen = Panel.cellPenalties()
    local kmr = Audit.points and string.format('%d / %d', Audit.points, config.kmrPoints.limit) or '-'
    local rt = config.kmrRating
    local rating = Audit.rating and Audit.num(Audit.rating) or '-'
    for _, l in ipairs({
      { TEXTS.scrTyres, string.format(TEXTS.tyreLapsFmt, state.tyreLaps[0] or 0, life and string.format(' - %d%%', math.floor(life)) or '') },
      { TEXTS.scrTrack, string.format(TEXTS.trackGripFmt, wet and TEXTS.trackWet or TEXTS.trackDry, math.floor(CarRead.num(sim.roadGrip) * 100)) },
      { TEXTS.scrPending, pen and pen.value or '-', pen and ORANGE },
      { TEXTS.scrKmr, kmr, Audit.points and Audit.points >= config.kmrPoints.limit * 0.8 and RED or nil },
      { TEXTS.scrKmrRating, rating, rt.on and Audit.rating and Audit.rating <= rt.dsqAt and RED or nil },
      { TEXTS.scrKmrCrashes, Audit.per100(Audit.crashes, Audit.crashRate) },
      { TEXTS.scrKmrInfr, Audit.per100(Audit.infractions, Audit.infractionRate) },
      { TEXTS.scrKmrKm, Audit.km and string.format('%.1f km', Audit.km) or '-' } }) do
      row(p1, y, s, { { l[1], 14, COLOR_DIM, false, FONT_TEXT }, { l[2], 286, l[3] or COLOR_TITLE, true } })
      y = y + ROW * s
    end
    Drag.icons('race', p1, p2, s)
  end
  RecordSync.base.statusBody = function(car)
    local ws, we = PitStops.window()
    local rule = config.driverStint
    local life = CarRead.tyreLife(car, 0, state.tyreLineKm[0] or 0)
    return string.format('%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d', config.pitStopsEnabled and 1 or 0, config.pitStopsRequired or 0,
      (config.swapOn() and config.swapRequired) and 1 or 0, config.swapRequired or 0, rule.minMinutes or 0, rule.maxMinutes or 0,
      math.floor(ws or 0), math.floor(we or 0), math.floor(math.max(sessionElapsedMs() - PitStops.windowTime(), 0) / 1000) * 1000,
      state.tyreLaps[0] or 0, life and math.floor(life) or -1, CarRead.num(sim.rainWetness) > 0.05 and 1 or 0, math.floor(CarRead.num(sim.roadGrip) * 100))
  end
  local Tele = { WINDOW = 8, RATE = 30, n = 0, at = 0, t = -1, buf = {} }
  local TELE_ORDER = { 'thr', 'brk', 'clu', 'str', 'spd', 'gear', 'glat', 'glon' }
  local TELE_COLOR = { thr = rgbm(0.16, 1, 0, 1), brk = rgbm(1, 0.16, 0, 1), clu = rgbm(0.16, 0.6, 1, 1),
    str = rgbm(0.9, 0.9, 0.9, 1), spd = rgbm(1, 0.6, 0.1, 1), gear = rgbm(0.6, 0.6, 0.6, 1),
    glat = rgbm(1, 0.9, 0, 1), glon = rgbm(0.6, 0.3, 1, 1), ffb = rgbm(1, 0.54, 0.11, 1) }
  local TELE_ON = { thr = true, brk = true, clu = true, str = true }
  do
    local kept = tostring(ac.storage['rc.telemetry'] or '')
    if kept ~= '' then
      TELE_ON = {}
      for k in kept:gmatch('[^,]+') do TELE_ON[k] = true end
    end
  end
  local function teleSave()
    local on = {}
    for _, k in ipairs(TELE_ORDER) do if TELE_ON[k] then on[#on + 1] = k end end
    ac.storage['rc.telemetry'] = #on > 0 and table.concat(on, ',') or 'none'
  end
  local TELE_MAX = 8 * 30
  local function teleSample(car)
    local now = CarRead.num(sim.time) / 1000
    if now - Tele.t < 1 / Tele.RATE and now >= Tele.t then return end
    Tele.t = now
    local acc = car.acceleration
    local lock = math.max(CarRead.num(car.steerLock), 1)
    Tele.at = Tele.at % TELE_MAX + 1
    local v = Tele.buf[Tele.at] or {}
    v.thr, v.brk, v.clu = CarRead.num(car.gas), CarRead.num(car.brake), 1 - CarRead.num(car.clutch == nil and 1 or car.clutch)
    v.str = 0.5 + 0.5 * math.max(-1, math.min(1, CarRead.num(car.steer) / lock))
    v.spd, v.gear = math.min(CarRead.num(car.speedKmh) / 320, 1), math.max(0, math.min(CarRead.num(car.gear), 8)) / 8
    v.glat = 0.5 + 0.5 * math.max(-1, math.min(1, (acc and CarRead.num(acc.x) or 0) / 3))
    v.glon = 0.5 + 0.5 * math.max(-1, math.min(1, (acc and CarRead.num(acc.z) or 0) / 3))
    v.ffb = math.min(math.abs(CarRead.num(car.ffbFinal)), 1)
    Tele.buf[Tele.at] = v
    Tele.n = math.min(Tele.n + 1, TELE_MAX)
  end
  Desktop.teleSample = teleSample
  local teleSmall = tostring(ac.storage['rc.telemetrySmall'] or '1') ~= '0'
  local function telemetryScreen(car, w, h, s)
    local small = teleSmall
    local GH = small and 40 or 92
    local fs = small and 7.5 or 8.5
    local p1, p2, y, bare = frame('telemetry', w, h, s, (GH + 6) / ROW, TEXTS.scrTelemetry, nil, small and 270 or nil)
    local x = p2.x - (small and 8 or 14) * s
    local pad = small and 2 or 3
    local function chip(t, on, color, fn)
      if bare then return end
      local tw = textWidth(t, FONT_MONO, fs * s)
      local a, b = vec2(x - tw - 2 * pad * s, p1.y + 5 * s), vec2(x, p1.y + 18 * s)
      if on then ui.drawRectFilled(a, b, color, 2 * s) else ui.drawRect(a, b, TMP.edge30, 2 * s) end
      drawText(t, FONT_MONO, fs * s, TMP.a:set(a.x + pad * s, a.y + 1 * s), on and TMP.dark or COLOR_DIM)
      Drag.clickable(a, b, fn)
      x = a.x - (small and 2 or 4) * s
    end
    for i = #TELE_ORDER, 1, -1 do
      local k = TELE_ORDER[i]
      chip(small and TEXTS.teleShort[k] or TEXTS.teleChannels[k], TELE_ON[k], TELE_COLOR[k],
        function() TELE_ON[k] = not TELE_ON[k]; teleSave() end)
    end
    x = x - (small and 3 or 6) * s
    chip(small and '+' or '-', false, nil, function()
      teleSmall = not teleSmall
      ac.storage['rc.telemetrySmall'] = teleSmall and '1' or '0'
    end)
    local barW, barGap = (small and 6 or 14) * s, (small and 9 or 22) * s
    local r = (GH / 2 - (small and 3 or 6)) * s
    local right = (small and 8 or 14) * s + 2 * r + (small and 6 or 10) * s + 4 * barGap + (small and 4 or 0) * s
    local gx1, gy1 = p1.x + (small and 8 or 14) * s, y + 2 * s
    local gx2, gy2 = p2.x - right, y + (GH - 2) * s
    ui.drawRectFilled(vec2(gx1, gy1), vec2(gx2, gy2), rgbm(1, 1, 1, 0.04), 2 * s)
    for q = 1, 3 do
      local ly = gy2 - (gy2 - gy1) * q / 4
      ui.drawSimpleLine(vec2(gx1, ly), vec2(gx2, ly), rgbm(1, 1, 1, q == 2 and 0.14 or 0.07), 1)
    end
    local n = Tele.n
    if n > 1 then
      local pt = Tele.pt or vec2(0, 0)
      Tele.pt = pt
      for _, k in ipairs(TELE_ORDER) do
        if TELE_ON[k] then
          for i = 1, n do
            local v = Tele.buf[(Tele.at - n + i - 1) % TELE_MAX + 1]
            local px_ = gx1 + (gx2 - gx1) * (i - 1) / (TELE_MAX - 1) + (gx2 - gx1) * (TELE_MAX - n) / (TELE_MAX - 1)
            ui.pathLineTo(pt:set(px_, gy2 - (gy2 - gy1) * (v and v[k] or 0)))
          end
          ui.pathStroke(TELE_COLOR[k], false, (small and 1.2 or 1.6) * s)
        end
      end
    end
    local last = Tele.buf[Tele.at] or {}
    local bx = gx2 + (small and 6 or 14) * s
    for _, k in ipairs({ 'clu', 'brk', 'thr', 'ffb' }) do
      local val = math.max(0, math.min(1, last[k] or 0))
      local a, b = vec2(bx, gy1 + (small and 0 or 12) * s), vec2(bx + barW, gy2)
      ui.drawRectFilled(a, b, rgbm(1, 1, 1, 0.08), 2 * s)
      ui.drawRectFilled(vec2(a.x, b.y - (b.y - a.y) * val), b, TELE_COLOR[k], 2 * s)
      if not small then drawText(string.format('%d', math.floor(val * 100 + 0.5)), FONT_MONO, 8 * s, TMP.a:set(a.x, gy1), COLOR_DIM) end
      bx = bx + barGap
    end
    local c = vec2(p2.x - (small and 8 or 14) * s - r - (small and 2 or 10) * s, (gy1 + gy2) / 2)
    ui.drawCircle(c, r, rgbm(1, 1, 1, 0.85), 40, (small and 2.5 or 5) * s)
    local ang = math.rad(CarRead.num(car.steer)) - math.pi / 2
    local m1 = vec2(c.x + math.cos(ang) * (r - (small and 3 or 6) * s), c.y + math.sin(ang) * (r - (small and 3 or 6) * s))
    local m2 = vec2(c.x + math.cos(ang) * (r + (small and 1.5 or 3) * s), c.y + math.sin(ang) * (r + (small and 1.5 or 3) * s))
    ui.drawLine(m1, m2, TELE_COLOR.brk, (small and 2.5 or 5) * s)
    local gear = math.floor(CarRead.num(car.gear))
    local gt = gear < 0 and 'R' or gear == 0 and 'N' or tostring(gear)
    local gsz = (small and 13 or 30) * s
    local gw = textWidth(gt, FONT_TITLE, gsz)
    drawText(gt, FONT_TITLE, gsz, TMP.a:set(c.x - gw / 2, c.y - gsz * (small and 0.9 or 0.57)), COLOR_TITLE)
    local kmh = math.floor(CarRead.num(car.speedKmh) + 0.5)
    local st = small and tostring(kmh) or string.format('%d km/h', kmh)
    local ssz = (small and 6.5 or 9) * s
    local sw = textWidth(st, FONT_MONO, ssz)
    drawText(st, FONT_MONO, ssz, TMP.a:set(c.x - sw / 2, small and (c.y + 1 * s) or (c.y - r + 8 * s)), COLOR_DIM)
    Drag.icons('telemetry', p1, p2, s)
  end
  local Perf = { fps = 0, cpu = 0, gpu = 0, top = 60 }
  local function perfScreen(car, w, h, s)
    local p1, p2, y = frame('perf', w, h, s, 3, TEXTS.scrPerf, nil)
    local fps = CarRead.num(sim.fps)
    local cap = CarRead.num(sim.fpsCapped)
    local gpuMs = 0
    if ac.getPerformanceCPUAndGPUTime then
      local ok, _, g = pcall(ac.getPerformanceCPUAndGPUTime)
      if ok then gpuMs = CarRead.num(g) end
    end
    local k = math.min(math.max(state.ui.clock - (Perf.t or -1e9), 0) * 2, 1)
    Perf.t = state.ui.clock
    Perf.fps = Perf.fps + (fps - Perf.fps) * k
    Perf.cpu = Perf.cpu + (CarRead.num(sim.cpuOccupancy) - Perf.cpu) * k
    Perf.gpu = Perf.gpu + ((fps > 0 and gpuMs * fps / 10 or 0) - Perf.gpu) * k
    Perf.top = cap > 0 and cap or math.max(Perf.top, fps)
    local rows = {
      { TEXTS.perfRows.fps, Perf.fps / math.max(Perf.top, 1), string.format('%.0f', Perf.fps) },
      { TEXTS.perfRows.cpu, Perf.cpu / 100, string.format('%.0f%%', Perf.cpu) },
      { TEXTS.perfRows.gpu, Perf.gpu / 100, string.format('%.0f%%', Perf.gpu) },
    }
    for _, r in ipairs(rows) do
      drawText(r[1], FONT_MONO, FS * s, TMP.a:set(p1.x + 8 * s, y), COLOR_DIM)
      local a, b = vec2(p1.x + 34 * s, y + 3 * s), vec2(p2.x - 42 * s, y + 10 * s)
      ui.drawRectFilled(a, b, rgbm(1, 1, 1, 0.08), 2 * s)
      ui.drawRectFilled(a, vec2(a.x + (b.x - a.x) * math.max(0, math.min(1, r[2])), b.y), BORDER_BLUE, 2 * s)
      drawTextRight(r[3], FONT_MONO, FS * s, p2.x - 8 * s, y, COLOR_TITLE)
      y = y + ROW * s
    end
    Drag.icons('perf', p1, p2, s)
  end
  local shareRow = 1
  local function shareRows()
    local f = RecordSync.base.rr.focus
    return f and f.room and (3 + #f.people) or 3
  end
  Desktop.shareMove = function(dir) shareRow = (shareRow - 1 + dir) % shareRows() + 1 end
  Desktop.shareStep = function(dir)
    local B, f = RecordSync.base, RecordSync.base.rr.focus
    if shareRow > shareRows() then shareRow = 1 end
    if shareRow == 1 then B.rrShare(dir > 0)
    elseif shareRow == 2 then B.rrOwn(dir < 0)
    elseif shareRow == 3 then if f and f.room then B.rrFocus(dir > 0, dir > 0 and f.with or '') end
    elseif f then
      local p = f.people[shareRow - 3]
      if p then B.rrFocus(true, dir > 0 and p.steam or '') end
    end
  end
  local function shareScreen(car, w, h, s)
    local Rr = RecordSync.base.rr
    local fo = Rr.focus
    local ask, askLevel = RecordSync.base.rrAsk()
    local lines = {}
    if ask then
      local maxW = (PLACE.share[3] - 70) * s
      local cur = ''
      for word in ask:gmatch('%S+') do
        local try = cur == '' and word or (cur .. ' ' .. word)
        if textWidth(try, FONT_TEXT, 9 * s) <= maxW or cur == '' then cur = try
        else lines[#lines + 1] = cur; cur = word end
      end
      if cur ~= '' then lines[#lines + 1] = cur end
      if #lines > 2 then
        lines[2] = lines[2] .. ' ' .. table.concat(lines, ' ', 3)
        for i = #lines, 3, -1 do lines[i] = nil end
        lines[2] = fitText(lines[2], FONT_TEXT, 9 * s, maxW)
      end
    end
    if shareRow > shareRows() then shareRow = 1 end
    local focusRows = 4 + (fo and fo.room and #fo.people or 0)
    local p1, p2, y, noTitle = frame('share', w, h, s, 2 + #lines + focusRows, TEXTS.scrShare, TEXTS.shareHint)
    if not noTitle then
      local hw = textWidth(TEXTS.shareHint, FONT_MONO, 11 * s)
      local hx = p2.x - 14 * s - hw
      Drag.clickable(vec2(hx, p1.y + 2 * s), vec2(hx + hw / 2, p1.y + 19 * s), function() RecordSync.base.rrShare(false) end)
      Drag.clickable(vec2(hx + hw / 2, p1.y + 2 * s), vec2(hx + hw, p1.y + 19 * s), function() RecordSync.base.rrShare(true) end)
    end
    local isz = 22 * s
    local a = vec2(p1.x + 14 * s, y)
    local b = vec2(a.x + isz, a.y + isz)
    local on = Rr.game
    ui.drawRectFilled(a, b, on and rgbm(0.2, 0.6, 0.3, 0.9) or rgbm(1, 1, 1, 0.08), 3 * s)
    ui.drawIcon(ui.Icons.VideoCamera, vec2(a.x + 3 * s, a.y + 3 * s), vec2(b.x - 3 * s, b.y - 3 * s), on and COLOR_TITLE or COLOR_DIM)
    Drag.clickable(a, b, function() RecordSync.base.rrShare(not on) end)
    drawText(on and TEXTS.shareOn or TEXTS.shareOff, FONT_TITLE, 10 * s, TMP.a:set(b.x + 10 * s, y), on and GREEN or COLOR_DIM)
    local room, level = RecordSync.base.rrRoom()
    local roomW = p2.x - 14 * s - (b.x + 10 * s)
    room = fitText(room, FONT_TEXT, 9 * s, roomW)
    drawText(room, FONT_TEXT, 9 * s, TMP.a:set(b.x + 10 * s, y + 13 * s), ({ ok = COLOR_TITLE, warn = YELLOW, bad = RED })[level] or COLOR_DIM)
    for i, line in ipairs(lines) do
      drawText(line, FONT_TEXT, 9 * s, TMP.a:set(b.x + 10 * s, y + (13 + 13 * i) * s), ({ warn = YELLOW, bad = RED })[askLevel] or COLOR_DIM)
    end
    local function mark(row, ry, rh) if shareRow == row then ui.drawRectFilled(vec2(p1.x + 9 * s, ry + 2 * s), vec2(p1.x + 11 * s, ry + (rh - 2) * s), YELLOW) end end
    mark(1, y, 22)
    local oy = y + (2 + #lines) * ROW * s
    local oa = vec2(p1.x + 14 * s, oy)
    local ob = vec2(oa.x + isz, oa.y + isz)
    local hidden = Rr.own == true
    ui.drawRectFilled(oa, ob, hidden and rgbm(1, 1, 1, 0.08) or rgbm(0.2, 0.6, 0.3, 0.9), 3 * s)
    ui.drawIcon(hidden and ui.Icons.Hide or ui.Icons.Eye, vec2(oa.x + 3 * s, oa.y + 3 * s), vec2(ob.x - 3 * s, ob.y - 3 * s), hidden and COLOR_DIM or COLOR_TITLE)
    Drag.clickable(oa, ob, function() RecordSync.base.rrOwn(not hidden) end)
    drawText(hidden and TEXTS.ownOff or TEXTS.ownOn, FONT_TITLE, 10 * s, TMP.a:set(ob.x + 10 * s, oy), hidden and COLOR_DIM or GREEN)
    local osubW = p2.x - 14 * s - (ob.x + 10 * s)
    local osub = fitText(TEXTS.ownHint, FONT_TEXT, 9 * s, osubW)
    drawText(osub, FONT_TEXT, 9 * s, TMP.a:set(ob.x + 10 * s, oy + 13 * s), COLOR_DIM)
    mark(2, oy, 22)
    local fy = oy + 2 * ROW * s
    local fa = vec2(p1.x + 14 * s, fy)
    local fb = vec2(fa.x + isz, fa.y + isz)
    local fon = fo and fo.on
    ui.drawRectFilled(fa, fb, fon and rgbm(0.2, 0.6, 0.3, 0.9) or rgbm(1, 1, 1, 0.08), 3 * s)
    ui.drawIcon(ui.Icons.Headphones, vec2(fa.x + 3 * s, fa.y + 3 * s), vec2(fb.x - 3 * s, fb.y - 3 * s), fon and COLOR_TITLE or COLOR_DIM)
    Drag.clickable(fa, fb, function() if fo and fo.room then RecordSync.base.rrFocus(not fon, fo.with) end end)
    mark(3, fy, 22)
    local chosen
    if fo then for _, p in ipairs(fo.people) do if p.steam == fo.with then chosen = p.name end end end
    drawText(fon and TEXTS.focusOn or TEXTS.focusOff, FONT_TITLE, 10 * s, TMP.a:set(fb.x + 10 * s, fy), fon and GREEN or COLOR_DIM)
    local sub = not (fo and fo.room) and TEXTS.focusNoRoom or fon and (chosen and string.format(TEXTS.focusWith, chosen) or TEXTS.focusNobody) or TEXTS.focusHint
    local subW = p2.x - 14 * s - (fb.x + 10 * s)
    sub = fitText(sub, FONT_TEXT, 9 * s, subW)
    drawText(sub, FONT_TEXT, 9 * s, TMP.a:set(fb.x + 10 * s, fy + 13 * s), (fo and fo.room) and COLOR_DIM or YELLOW)
    if fo and fo.room then
      local ny = fy + 2 * ROW * s
      for i, p in ipairs(fo.people) do
        local on = fon and p.steam == fo.with
        local nm = fitText(p.name, FONT_TEXT, FS * s, subW, '')
        drawText(nm, FONT_TEXT, FS * s, TMP.a:set(fb.x + 10 * s, ny), on and GREEN or COLOR_TITLE)
        if on then drawText('>', FONT_MONO, FS * s, TMP.a:set(fa.x + 6 * s, ny), GREEN) end
        mark(3 + i, ny, ROW)
        Drag.clickable(vec2(p1.x + 10 * s, ny), vec2(p2.x - 10 * s, ny + ROW * s), function() shareRow = 3 + i; RecordSync.base.rrFocus(true, p.steam) end)
        ny = ny + ROW * s
      end
    end
    Drag.icons('share', p1, p2, s)
  end
  local COCKPIT_SECTIONS = {
    { key = 'pos', rows = { { key = 'y', step = 0.005 }, { key = 'x', step = 0.005 }, { key = 'z', step = 0.005 }, { key = 'pitch', step = 0.5 } } },
    { key = 'ctl', rows = { { key = 'ffb', step = 0.01 } } },
    { key = 'view', rows = { { key = 'fov', step = 1 }, { key = 'hide.wheel', toggle = true }, { key = 'hide.arms', toggle = true } } },
    { key = 'snd', rows = { { key = 'vol.main', step = 0.05 } } } }
  local CHANNELS = { 'engine', 'transmission', 'tyres', 'surfaces', 'dirt', 'wind', 'opponents', 'carComponents', 'track',
    'weather', 'rain', 'wipers' }
  local COCKPIT_CLOSED_KEY = 'rc.cockpitClosed'
  local cockpit = { row = 1, askT = -1e9, audio = false, closed = {} }
  for k in tostring(ac.storage[COCKPIT_CLOSED_KEY] or ''):gmatch('[^,]+') do cockpit.closed[k] = true end
  local function cockpitSection(key, open)
    cockpit.closed[key] = not open or nil
    local list = {}
    for _, sec in ipairs(COCKPIT_SECTIONS) do if cockpit.closed[sec.key] then list[#list + 1] = sec.key end end
    ac.storage[COCKPIT_CLOSED_KEY] = table.concat(list, ',')
  end
  local function cockpitLines()
    local out = {}
    for _, sec in ipairs(COCKPIT_SECTIONS) do
      out[#out + 1] = { title = sec.key }
      if not cockpit.closed[sec.key] then for _, r in ipairs(sec.rows) do out[#out + 1] = r end end
    end
    return out
  end
  local function cockpitSend(key, dir, step) AppLink.cockpit(string.format('%s=%g', key, dir * step)) end
  local function cockpitHide(key, on) AppLink.cockpit(string.format('%s=%d', key, on and 1 or 0)) end
  Desktop.cockpitMove = function(dir) cockpit.row = (cockpit.row - 1 + dir) % #cockpitLines() + 1 end
  Desktop.cockpitStep = function(dir)
    local lines = cockpitLines()
    local r = lines[math.min(cockpit.row, #lines)]
    if r.title then cockpitSection(r.title, dir > 0)
    elseif r.toggle then cockpitHide(r.key, dir > 0)
    else cockpitSend(r.key, dir, r.step) end
  end
  local function cockpitValue(key, v)
    if v == nil then return '-' end
    if key == 'ffb' or key:match('^vol%.') then return string.format('%.0f %%', v * 100) end
    if key == 'x' or key == 'y' or key == 'z' then return string.format('%.1f cm', v * 100) end
    if key == 'pitch' then return string.format('%.1f deg', v) end
    return string.format('%.0f deg', v)
  end
  local SLIDE = { ffb = { 0, 2 }, fov = { 10, 120 }, pitch = { -30, 30 } }
  local seat0 = {}
  local function slideRange(key, v)
    if SLIDE[key] then return SLIDE[key][1], SLIDE[key][2] end
    if key:match('^vol%.') then return 0, 1 end
    if seat0[key] == nil then seat0[key] = v end
    return seat0[key] - 0.3, seat0[key] + 0.3
  end
  local function slider(key, v, a, b, s, on)
    ui.drawRectFilled(a, b, rgbm(1, 1, 1, 0.10), 2 * s)
    local t = '-'
    if v ~= nil then
      local lo, hi = slideRange(key, v)
      local f = math.min(math.max((v - lo) / (hi - lo), 0), 1)
      ui.drawRectFilled(a, vec2(a.x + (b.x - a.x) * f, b.y), on and rgbm(1, 0.85, 0.25, 0.9) or rgbm(0.36, 0.38, 0.98, 0.9), 2 * s)
      Drag.clickable(a, b, function()
        local m = ui.mousePos()
        local k = math.min(math.max((m.x - a.x) / (b.x - a.x), 0), 1)
        local d = lo + (hi - lo) * k - v
        if math.abs(d) > 1e-6 then AppLink.cockpit(string.format('%s=%g', key, d)) end
      end)
      local own = key == 'ffb' or key:match('^vol%.')
      t = string.format('%.0f %%', own and v * 100 or f * 100)
      if not own then
        drawText(cockpitValue(key, v), FONT_MONO, FS * s, TMP.a:set(b.x + 22 * s, a.y), COLOR_DIM)
      end
    end
    ui.drawRect(a, b, TMP.edge35, 2 * s)
    local tw = textWidth(t, FONT_MONO, FS * s)
    drawText(t, FONT_MONO, FS * s, TMP.a:set((a.x + b.x) / 2 - tw / 2, a.y), on and TMP.dark or COLOR_TITLE)
  end
  local function stepBox(text, a, s, fn)
    local b = vec2(a.x + 14 * s, a.y + 12 * s)
    ui.drawRect(a, b, TMP.edge35, 2 * s)
    local tw = textWidth(text, FONT_MONO, 10 * s)
    drawText(text, FONT_MONO, 10 * s, TMP.a:set(a.x + (14 * s - tw) / 2, a.y), COLOR_TITLE)
    Drag.clickable(a, b, fn)
  end
  local COCKPIT_RIGHT = 50
  Desktop.cockpitHeight = function() return 26 + (1 + #cockpitLines()) * ROW + 2 end
  local function cockpitBody(car, p1, p2, y, s, focus)
    if state.ui.clock - cockpit.askT >= 2 then cockpit.askT = state.ui.clock; AppLink.cockpit('state') end
    local st = AppLink.cockpitRead(car)
    do
      local a = vec2(p2.x - 14 * s - COCKPIT_RIGHT * s, y)
      local b = vec2(p2.x - 14 * s, y + 12 * s)
      local name = tostring(ac.getCarName and ac.getCarName(0) or ac.getCarID(0) or '')
      local tw = a.x - 8 * s - (p1.x + 14 * s)
      local t = fitText(string.format(TEXTS.cockpitCar, name), FONT_TEXT, FS * s, tw)
      drawText(t, FONT_TEXT, FS * s, TMP.a:set(p1.x + 14 * s, y), COLOR_DIM)
      local lit = AppLink.cockpitSavedT and state.ui.clock - AppLink.cockpitSavedT < 3
      if lit then ui.drawRectFilled(a, b, YELLOW, 2 * s) else ui.drawRect(a, b, TMP.edge35, 2 * s) end
      local label = lit and TEXTS.cockpitSaved or TEXTS.cockpitSave
      local lw = textWidth(label, FONT_MONO, 9 * s)
      drawText(label, FONT_MONO, 9 * s, TMP.a:set((a.x + b.x) / 2 - lw / 2, a.y + 0.5 * s), lit and TMP.dark or COLOR_TITLE)
      Drag.clickable(a, b, function()
        AppLink.cockpit('save')
        if AppLink.alive then AppLink.cockpitSavedT = state.ui.clock end
      end)
      y = y + ROW * s
    end
    for i, r in ipairs(cockpitLines()) do
      local on = focus and cockpit.row == i
      local vx = p2.x - 14 * s - 70 * s
      if r.title then
        local open = not cockpit.closed[r.title]
        local col = on and YELLOW or COLOR_TITLE
        local cx, cy = p1.x + 18 * s, y + 6 * s
        if open then ui.drawTriangleFilled(vec2(cx - 4 * s, cy - 2 * s), vec2(cx + 4 * s, cy - 2 * s), vec2(cx, cy + 3 * s), col)
        else ui.drawTriangleFilled(vec2(cx - 2 * s, cy - 4 * s), vec2(cx + 3 * s, cy), vec2(cx - 2 * s, cy + 4 * s), col) end
        drawText(TEXTS.cockpitSections[r.title], FONT_TITLE, 9 * s, TMP.a:set(p1.x + 28 * s, y + 1 * s), col)
        local key = r.title
        Drag.clickable(vec2(p1.x + 10 * s, y), vec2(p2.x - 10 * s, y + 12 * s), function() cockpit.row = i; cockpitSection(key, not open) end)
      elseif r.toggle then
        drawText(TEXTS.cockpitRows[r.key], FONT_TEXT, FS * s, TMP.a:set(p1.x + 14 * s, y), on and YELLOW or COLOR_DIM)
        local a, b = vec2(vx - 70 * s, y), vec2(vx + 14 * s, y + 12 * s)
        local v = st[r.key]
        local hidden = v ~= nil and v >= 0.5
        if hidden then ui.drawRectFilled(a, b, on and YELLOW or rgbm(0.36, 0.38, 0.98, 0.9), 2 * s) else ui.drawRect(a, b, TMP.edge35, 2 * s) end
        local t = v == nil and '-' or (hidden and TEXTS.cockpitHidden or TEXTS.cockpitShown)
        local tw = textWidth(t, FONT_MONO, FS * s)
        drawText(t, FONT_MONO, FS * s, TMP.a:set((a.x + b.x) / 2 - tw / 2, a.y), hidden and TMP.dark or COLOR_TITLE)
        local key = r.key
        Drag.clickable(a, b, function() cockpit.row = i; cockpitHide(key, not hidden) end)
      else
        drawText(TEXTS.cockpitRows[r.key], FONT_TEXT, FS * s, TMP.a:set(p1.x + 14 * s, y), on and YELLOW or COLOR_DIM)
        stepBox('-', vec2(vx - 70 * s, y), s, function() cockpit.row = i; cockpitSend(r.key, -1, r.step) end)
        slider(r.key, st[r.key], vec2(vx - 54 * s, y), vec2(vx - 2 * s, y + 12 * s), s, on)
        stepBox('+', vec2(vx, y), s, function() cockpit.row = i; cockpitSend(r.key, 1, r.step) end)
        if r.key == 'vol.main' then
          local a = vec2(p2.x - 14 * s - COCKPIT_RIGHT * s, y)
          local b = vec2(p2.x - 14 * s, a.y + 12 * s)
          if cockpit.audio then ui.drawRectFilled(a, b, YELLOW, 2 * s) else ui.drawRect(a, b, TMP.edge35, 2 * s) end
          drawText(TEXTS.cockpitMore, FONT_MONO, 9 * s, TMP.a:set(a.x + 4 * s, a.y + 0.5 * s), cockpit.audio and TMP.dark or COLOR_TITLE)
          Drag.clickable(a, b, function() cockpit.audio = not cockpit.audio end)
        end
      end
      y = y + ROW * s
    end
    if cockpit.audio and not cockpit.closed.snd then
      local a1 = vec2(p2.x + 6 * s, p1.y)
      local a2 = vec2(a1.x + (p2.x - p1.x), a1.y + (26 + #CHANNELS * ROW + 2) * s)
      drawPanel(a1, a2, BORDER_BASE, s)
      drawText(TEXTS.cockpitAudio, FONT_TITLE, 12 * s, TMP.a:set(a1.x + 14 * s, a1.y + 4 * s), COLOR_TITLE)
      drawSeparator(a1, a2, a1.y + 21 * s, s)
      local ay = a1.y + 26 * s
      for _, ch in ipairs(CHANNELS) do
        local key = 'vol.' .. ch
        drawText(TEXTS.cockpitChannels[ch] or ch, FONT_TEXT, FS * s, TMP.a:set(a1.x + 14 * s, ay), COLOR_DIM)
        local vx = a2.x - 14 * s - 70 * s
        stepBox('-', vec2(vx - 70 * s, ay), s, function() cockpitSend(key, -1, 0.05) end)
        slider(key, st[key], vec2(vx - 54 * s, ay), vec2(vx - 2 * s, ay + 12 * s), s, false)
        stepBox('+', vec2(vx, ay), s, function() cockpitSend(key, 1, 0.05) end)
        ay = ay + ROW * s
      end
    end
  end
  Desktop.cockpitBody = cockpitBody
  Desktop.cockpitWide = function() return cockpit.audio and not cockpit.closed.snd end
  local function cockpitScreen(car, w, h, s)
    local dx = 0
    if Desktop.cockpitWide() then
      local o = Drag.offset('cockpit', h)
      local right = PLACE.cockpit[1] * h / 1080 + o.x + (2 * PLACE.cockpit[3] + 6) * s
      dx = math.max(right - w, 0)
    end
    local p1, p2, y = frame('cockpit', w, h, s, 1 + #cockpitLines(), TEXTS.scrCockpit, AppLink.alive and nil or TEXTS.cockpitNoApp, nil, dx)
    cockpitBody(car, p1, p2, y, s, Desktop.focus == 'cockpit')
    Drag.icons('cockpit', p1, p2, s)
  end
  local calcScreen = (function()
    local PARAMS = { { k = 'race', step = 5, fmt = '%.0f min' }, { k = 'lap', step = 0.1, fmt = '%.1f s' }, { k = 'tank', step = 1, fmt = '%.0f L' },
      { k = 'reserve', step = 1, fmt = '%.0f' }, { k = 'pitloss', step = 0.5, fmt = '%.1f s' }, { k = 'refuel', step = 0.05, fmt = '%.2f s/L' },
      { k = 'tyres', step = 0.1, fmt = '%.1f s' } }
    local FIELDS = { { k = 'wear', step = 0.1, fmt = '%.2f' }, { k = 'limit', step = 5, fmt = '%.0f' }, { k = 'fuel', step = 0.05, fmt = '%.2f' },
      { k = 'stops', step = 1, fmt = '%.0f' } }
    local NAMES = { 'A', 'B', 'C', 'D' }
    local items = {}
    for _, p in ipairs(PARAMS) do items[#items + 1] = { key = p.k, p = p } end
    for i, n in ipairs(NAMES) do
      for _, f in ipairs(FIELDS) do items[#items + 1] = { key = n .. '.' .. f.k, p = f, sc = i, name = n } end
    end
    local V, sel, cur = {}, 1, {}
    for k, v in tostring(ac.storage['rc.calc'] or ''):gmatch('([%w%.]+)=(%-?[%d%.]+)') do V[k] = tonumber(v) end
    local function save()
      local parts = {}
      for k, v in pairs(V) do parts[#parts + 1] = string.format('%s=%g', k, v) end
      table.sort(parts)
      ac.storage['rc.calc'] = table.concat(parts, ';')
    end
    local function measured(car) return RaceTable.calcData(car) end
    local function default(it)
      local k, m = it.p.k, cur.m
      if it.sc then
        if k == 'wear' then return m.wear elseif k == 'fuel' then return m.fuel end
        return nil
      end
      if k == 'race' then return m.raceMin end
      if k == 'lap' then return m.lapMs and math.floor(m.lapMs / 100 + 0.5) / 10 end
      if k == 'tank' then return m.tank end
      if k == 'pitloss' then return m.pitLoss and math.floor(m.pitLoss / 100 + 0.5) / 10 end
      if k == 'refuel' then return m.rateFuel end
      if k == 'tyres' then return m.rateTyre end
      return nil
    end
    local function value(it)
      if V[it.key] ~= nil then return V[it.key] end
      return default(it)
    end
    local function step(dir)
      local it = items[sel]
      if not cur.m then return end
      local v = (value(it) or 0) + dir * it.p.step
      V[it.key] = math.max(0, math.floor(v / it.p.step + 0.5) * it.p.step)
      save()
    end
    Desktop.calcStep = step
    Desktop.calcMove = function(dir) sel = (sel - 1 + dir) % #items + 1 end
    local function results()
      local P, missing = {}, {}
      for _, it in ipairs(items) do
        if not it.sc then
          P[it.p.k] = value(it)
          if P[it.p.k] == nil then missing[#missing + 1] = TEXTS.calcParams[it.p.k] end
        end
      end
      local raceLaps = P.race and P.lap and P.lap > 0 and math.ceil(P.race * 60000 / (P.lap * 1000)) or nil
      local out, best = {}, nil
      for i = 1, #NAMES do
        local f, miss = {}, {}
        for j, fd in ipairs(FIELDS) do
          f[fd.k] = value(items[#PARAMS + (i - 1) * #FIELDS + j])
          if f[fd.k] == nil then miss[#miss + 1] = TEXTS.calcFields[fd.k] end
        end
        local r = { miss = miss }
        if #missing == 0 and #miss == 0 then
          local lapMs = P.lap * 1000
          local stops = math.max(0, math.floor(f.stops + 0.5))
          local per = math.ceil(raceLaps / (stops + 1))
          local fuelLaps = f.fuel > 0 and math.floor(P.tank / f.fuel) - P.reserve or math.huge
          local tyreLaps = f.wear > 0 and math.floor(f.limit / f.wear) or math.huge
          local fuelStint = f.fuel * per
          local pit = stops * (P.pitloss + PitBox.stopTime(math.min(fuelStint, P.tank) * P.refuel, 4 * P.tyres))
          r = { per = per, fuelLaps = fuelLaps, tyreLaps = tyreLaps, okFuel = per <= fuelLaps, okTyre = per <= tyreLaps,
            fuelStint = fuelStint, pit = pit, total = raceLaps * lapMs + pit * 1000, miss = miss }
          r.ok = r.okFuel and r.okTyre
          if r.ok and (not best or r.total < out[best].total) then best = i end
        end
        out[i] = r
      end
      return out, best, raceLaps, missing
    end
    local function laps(v) return v == math.huge and 'inf' or tostring(v) end
    return function(car, w, h, s)
      cur.m, cur.car = measured(car), car
      local m = cur.m
      local res, best, raceLaps, missing = results()
      local p1, p2, y = frame('calc', w, h, s, 17.9, TEXTS.scrCalc, TEXTS.calcNotCar)
      local function u(v, fmt) return v and string.format(fmt, v) or '-' end
      row(p1, y, s, { { TEXTS.calcFuel, 14, COLOR_DIM, false, FONT_TEXT }, { u(m.fuel, '%.2f L'), 176, nil, true },
        { TEXTS.calcWear, 196, COLOR_DIM, false, FONT_TEXT }, { u(m.wear, '%.2f %%'), 366, nil, true } })
      y = y + ROW * s
      row(p1, y, s, { { TEXTS.calcLap, 14, COLOR_DIM, false, FONT_TEXT }, { m.lapMs and lapTime(m.lapMs) or '-', 176, nil, true },
        { TEXTS.calcLaps, 196, COLOR_DIM, false, FONT_TEXT }, { string.format('%d/%d', m.flying, RaceTable.MIN_FLYING), 366, m.lapMs and COLOR_TITLE or RED, true } })
      y = y + ROW * s
      drawSeparator(p1, p2, y + 3 * s, s)
      y = y + 8 * s
      for i, p in ipairs(PARAMS) do
        local it = items[i]
        local on = sel == i
        row(p1, y, s, { { TEXTS.calcParams[p.k], 14, on and YELLOW or COLOR_DIM, false, FONT_TEXT },
          { value(it) and string.format(p.fmt, value(it)) or TEXTS.calcNoData, 250, on and YELLOW or (value(it) == nil and RED or V[it.key] ~= nil and COLOR_TITLE or COLOR_DIM), true },
          { p.k == 'race' and raceLaps and string.format(TEXTS.calcRaceLaps, raceLaps) or '', 366, COLOR_DIM, true } })
        Drag.clickable(vec2(p1.x + 10 * s, y), vec2(p1.x + 254 * s, y + ROW * s), function() sel = i end)
        y = y + ROW * s
      end
      drawSeparator(p1, p2, y + 3 * s, s)
      y = y + 8 * s
      local HX = { 14, 66, 96, 132, 156, 190, 252, 282, 318, 366 }
      local head = {}
      for k, tx in ipairs(TEXTS.calcHead) do head[k] = { tx, HX[k], COLOR_AXIS, k > 1 } end
      row(p1, y, s, head)
      y = y + ROW * s
      for i, n in ipairs(NAMES) do
        local r = res[i]
        local cells = { { n, 14, best == i and GREEN or COLOR_TITLE } }
        for j, fd in ipairs(FIELDS) do
          local at = #PARAMS + (i - 1) * #FIELDS + j
          local it = items[at]
          cells[#cells + 1] = { value(it) and string.format(fd.fmt, value(it)) or '-', HX[j + 1], sel == at and YELLOW or (value(it) == nil and RED or V[it.key] ~= nil and COLOR_TITLE or COLOR_DIM), true }
          Drag.clickable(vec2(p1.x + (HX[j + 1] - 28) * s, y), vec2(p1.x + HX[j + 1] * s, y + ROW * s), function() sel = at end)
        end
        if r.per then
          cells[#cells + 1] = { tostring(r.per), HX[6], COLOR_TITLE, true }
          cells[#cells + 1] = { string.format('%.1f(%s)', r.fuelStint, laps(r.fuelLaps)), HX[7], r.okFuel and COLOR_TITLE or RED, true }
          cells[#cells + 1] = { laps(r.tyreLaps), HX[8], r.okTyre and COLOR_TITLE or RED, true }
          cells[#cells + 1] = { string.format('%.0f', r.pit), HX[9], COLOR_TITLE, true }
          cells[#cells + 1] = { r.ok and hms(r.total) or TEXTS.calcNo, HX[10], r.ok and (best == i and GREEN or COLOR_TITLE) or RED, true }
        else
          cells[#cells + 1] = { TEXTS.calcNoData, HX[10], COLOR_DIM, true }
        end
        row(p1, y, s, cells)
        y = y + ROW * s
      end
      drawSeparator(p1, p2, y + 3 * s, s)
      y = y + 8 * s
      local it = items[sel]
      local label = it.sc and (it.name .. ' - ' .. TEXTS.calcFields[it.p.k]) or TEXTS.calcParams[it.p.k]
      drawText(label, FONT_TEXT, FS * s, TMP.a:set(p1.x + 14 * s, y), YELLOW)
      local vx = p2.x - 14 * s - 50 * s
      stepBox('-', vec2(vx - 84 * s, y), s, function() step(-1) end)
      local vt = value(it) and string.format(it.p.fmt, value(it)) or TEXTS.calcNoDataShort
      local vw = textWidth(vt, FONT_MONO, FS * s)
      drawText(vt, FONT_MONO, FS * s, TMP.a:set(vx - 42 * s - vw / 2, y), COLOR_TITLE)
      stepBox('+', vec2(vx - 14 * s, y), s, function() step(1) end)
      local a, b = vec2(vx + 6 * s, y), vec2(p2.x - 14 * s, y + 12 * s)
      ui.drawRect(a, b, TMP.edge35, 2 * s)
      local aw = textWidth(TEXTS.calcAuto, FONT_MONO, 9 * s)
      drawText(TEXTS.calcAuto, FONT_MONO, 9 * s, TMP.a:set((a.x + b.x) / 2 - aw / 2, a.y + 0.5 * s), V[it.key] == nil and COLOR_DIM or COLOR_TITLE)
      Drag.clickable(a, b, function() V[it.key] = nil; save() end)
      y = y + ROW * s
      local msg
      if not m.lapMs then msg = string.format(TEXTS.calcNeedFlying, m.flying, RaceTable.MIN_FLYING)
      elseif #missing > 0 then msg = string.format(TEXTS.calcMissing, table.concat(missing, ', '))
      elseif not best and #res[1].miss > 0 then msg = string.format(TEXTS.calcMissing, NAMES[1] .. ': ' .. table.concat(res[1].miss, ', '))
      else msg = best and string.format(TEXTS.calcBest, NAMES[best]) or TEXTS.calcNone end
      drawText(msg, FONT_TEXT, FS * s, TMP.a:set(p1.x + 14 * s, y), best and GREEN or RED)
      Drag.icons('calc', p1, p2, s)
    end
  end)()
  return function(car, w, h, s)
    local line, sector = Desktop.recent('line'), Desktop.recent('sector')
    if shown('race', car.isInPitlane or line) then raceScreen(car, w, h, s) end
    if shown('laps', line) then lapsScreen(car, w, h, s) end
    if shown('standings', line or Desktop.recent('position')) then standingsScreen(car, w, h, s) end
    if shown('relative', Desktop.close or Desktop.recent('closeEnd') or line) then relativeScreen(car, w, h, s) end
    if shown('laptime', line or sector) then lapTimeScreen(car, w, h, s) end
    if shown('delta', sector) then deltaScreen(car, w, h, s) end
    if shown('event', car.isInPitlane) then eventScreen(car, w, h, s) end
    if shown('weather', line) then weatherScreen(car, w, h, s) end
    if shown('map', Desktop.close or line) then mapScreen(car, w, h, s) end
    if shown('telemetry', false) then telemetryScreen(car, w, h, s) end
    if shown('share', car.isInPitlane) then shareScreen(car, w, h, s) end
    if shown('cockpit', car.isInPitlane) then cockpitScreen(car, w, h, s) end
    if shown('perf', false) then perfScreen(car, w, h, s) end
    if shown('calc', false) then calcScreen(car, w, h, s) end
  end
end)()
local KmrEvents = (function()
  local M = { open = false, view = nil, filter = 'all', last = true, scroll = 0 }
  local io = { sid = nil, busy = false, err = nil, retryT = 0, pingT = 0, events = {}, tracks = {}, data = {}, asked = {} }
  local PING_EVERY, RETRY_AFTER = 20, 5
  local COLORS = { rgbm(0.4, 0.6, 1, 1), rgbm(1, 0.35, 0.35, 1), rgbm(1, 0.85, 0.25, 1), rgbm(0.45, 1, 0.55, 1), rgbm(0.9, 0.5, 1, 1) }
  local function base() return config.kmrStatsUrl ~= '' and (config.kmrStatsUrl .. '/socket.io/?EIO=3&transport=polling') or nil end
  local function packets(body)
    local out, i, n = {}, 1, #body
    while i <= n do
      local c = body:find(':', i, true)
      local len = c and tonumber(body:sub(i, c - 1))
      if not len then break end
      local j, units = c + 1, 0
      while units < len and j <= n do
        local b = body:byte(j)
        local w = b >= 240 and 4 or b >= 224 and 3 or b >= 192 and 2 or 1
        units = units + (w == 4 and 2 or 1)
        j = j + w
      end
      out[#out + 1] = body:sub(c + 1, j - 1)
      i = j
    end
    return out
  end
  local function enc(v)
    local t = type(v)
    if t == 'table' then
      if #v > 0 or next(v) == nil then
        local parts = {}
        for _, x in ipairs(v) do parts[#parts + 1] = enc(x) end
        return '[' .. table.concat(parts, ',') .. ']'
      end
      local parts = {}
      for k, x in pairs(v) do parts[#parts + 1] = enc(tostring(k)) .. ':' .. enc(x) end
      return '{' .. table.concat(parts, ',') .. '}'
    elseif t == 'string' then
      return '"' .. v:gsub('[%c"\\]', function(ch) return string.format('\\u%04x', ch:byte()) end) .. '"'
    elseif t == 'number' then
      return (v == math.floor(v) and math.abs(v) < 2^53) and string.format('%d', v) or tostring(v)
    elseif t == 'boolean' then return tostring(v) end
    return 'null'
  end
  local function send(text)
    if not io.sid or not web or not web.request then return end
    WebQueue.request('POST', base() .. '&sid=' .. io.sid, { ['Content-Type'] = 'text/plain;charset=UTF-8' }, (#text) .. ':' .. text, function(err)
      if err then ac.log('race-control: KMR race control ask not sent: ' .. tostring(err)) end
    end, true)
  end
  local function onEvent(name, data)
    if name == 'race.control.set.events' and type(data) == 'table' then
      io.events = data
    elseif name and name:find('^race%.control%.add%.') and type(data) == 'table' then
      io.events[#io.events + 1] = data
    elseif name == 'race.control.update.event' and type(data) == 'table' then
      for i, e in ipairs(io.events) do if e.ts == data.ts and e.type == data.type then io.events[i] = data end end
    elseif name == 'race.control.set.track' and type(data) == 'table' and data.track then
      io.tracks[tostring(data.track)] = data.data
    elseif name and name:find('^race%.control%.set%.%a+%.data$') and type(data) == 'table' and data.ts then
      io.data[tostring(data.ts)] = data
    end
  end
  local function handle(body)
    for _, p in ipairs(packets(tostring(body or ''))) do
      if p:sub(1, 1) == '0' then
        local d = JSON.parse(p:sub(2))
        if type(d) == 'table' and d.sid then io.sid = tostring(d.sid) end
      elseif p:sub(1, 2) == '42' then
        local d = JSON.parse(p:sub(3))
        if type(d) == 'table' then onEvent(d[1], d[2]) end
      elseif p == '1' then
        io.sid = nil
      end
    end
  end
  local function fail(err)
    io.busy, io.sid, io.err, io.retryT = false, nil, tostring(err or TEXTS.kmrEvNoAnswer), state.ui.clock + RETRY_AFTER
    ac.log('race-control: KMR race control not read: ' .. io.err)
  end
  local function pump()
    if not base() or not web or not web.request or not JSON or io.busy or state.ui.clock < io.retryT then return end
    io.busy = true
    local url = base() .. (io.sid and ('&sid=' .. io.sid) or '')
    WebQueue.request('GET', url, nil, nil, function(err, res)
      if err or not res or (tonumber(res.status) or 200) >= 400 then fail(err or (res and res.status)); return end
      local had = io.sid
      handle(res.body)
      io.busy, io.err = false, nil
      if not had and io.sid then ac.log('race-control: KMR race control connected') end
    end)
    if io.sid and state.ui.clock >= io.pingT then io.pingT = state.ui.clock + PING_EVERY; send('2') end
  end
  local function ask(e)
    local key = tostring(e.ts)
    if io.data[key] or io.asked[key] then return end
    io.asked[key] = state.ui.clock
    if e.track and not io.tracks[tostring(e.track)] then send('42' .. enc({ 'race.control.request.track', e.track })) end
    send('42' .. enc({ 'race.control.request.' .. e.type .. '.data', e }))
  end
  local function hhmmss(ts) return os.date('%H:%M:%S', math.floor((tonumber(ts) or 0) / 1000)) end
  local function hasReplay(e) return e.type == 'collision' or e.type == 'cut' end
  local function who(e)
    local a = tostring(e.car_driver_name or '')
    if e.other_car_driver_name then a = a .. ' x ' .. tostring(e.other_car_driver_name) end
    return a ~= '' and a or tostring(e.text or '')
  end
  local function detail(e)
    if e.type == 'cut' then
      local cc = type(e.cut_count) == 'table' and string.format(' %s/%s', tostring(e.cut_count[1] or '-'), tostring(e.cut_count[2] or '-')) or ''
      return tostring(e.cut_type or ''):gsub('%$%d+$', '') .. cc
    end
    return ''
  end
  local function penalty(e)
    local m = type(e.moderated) == 'table' and e.moderated or {}
    local out = {}
    for _, p in pairs(type(m.penalties) == 'table' and m.penalties or {}) do
      if type(p) == 'table' and p.penalty_hr and p.penalty_hr ~= '0p' then out[#out + 1] = tostring(p.penalty_hr) end
    end
    return (m.reviewed == 1 and TEXTS.kmrEvReviewed or '') .. table.concat(out, ' ')
  end
  local SESSION_SLACK_MS = 60000
  local function rows()
    local lastId
    for _, e in ipairs(io.events) do
      local id = type(e.session_info) == 'table' and e.session_info.id
      if id and (not lastId or id > lastId) then lastId = id end
    end
    local out = {}
    for i = #io.events, 1, -1 do
      local e = io.events[i]
      local okKind = M.filter == 'all' or (M.filter == 'collision' and e.type == 'collision') or (M.filter == 'cut' and e.type == 'cut')
        or (M.filter == 'generic' and e.type ~= 'collision' and e.type ~= 'cut')
      local id = type(e.session_info) == 'table' and tonumber(e.session_info.id)
      local okSession = not M.last or (id ~= nil and lastId - id <= SESSION_SLACK_MS)
      if okKind and okSession then out[#out + 1] = e end
    end
    return out
  end
  local function posAt(samples, t)
    if #samples == 0 then return nil end
    if t <= samples[1].ts then return samples[1].world_position, samples[1] end
    for i = 1, #samples - 1 do
      local a, b = samples[i], samples[i + 1]
      if t <= b.ts then
        local dt = math.max((b.ts - a.ts) / 1000, 0.001)
        local u = (t - a.ts) / (b.ts - a.ts)
        local h00, h10, h01, h11 = 2 * u ^ 3 - 3 * u ^ 2 + 1, u ^ 3 - 2 * u ^ 2 + u, -2 * u ^ 3 + 3 * u ^ 2, u ^ 3 - u ^ 2
        local pa, pb = a.world_position, b.world_position
        local va, vb = a.velocity or { x = 0, z = 0 }, b.velocity or { x = 0, z = 0 }
        return { x = h00 * pa.x + h10 * dt * (va.x or 0) + h01 * pb.x + h11 * dt * (vb.x or 0),
          z = h00 * pa.z + h10 * dt * (va.z or 0) + h01 * pb.z + h11 * dt * (vb.z or 0) }, (u < 0.5 and a or b)
      end
    end
    return samples[#samples].world_position, samples[#samples]
  end
  local ZOOMS = { 25, 50, 100, 200, 400, 1500 }
  local function replay(p1, p2, s, chip, e)
    local d = io.data[tostring(e.ts)]
    local v = M.view
    local x0 = p1.x + 12 * s
    local y = p1.y + 26 * s
    local tx = chip(TEXTS.kmrEvBack, vec2(x0, y), s, false, nil, function() M.view = nil end)
    drawText(string.format('%s  %s  -  %s  %s', hhmmss(e.ts), (TEXTS.kmrEvKinds[e.type] or e.type), who(e), detail(e)),
      FONT_TEXT, 10 * s, TMP.a:set(tx + 8 * s, y + 1 * s), COLOR_TITLE)
    y = y + 22 * s
    if not d then
      ask(e)
      drawText(io.asked[tostring(e.ts)] and state.ui.clock - io.asked[tostring(e.ts)] > 15 and TEXTS.kmrEvNoData or TEXTS.kmrEvLoading,
        FONT_MONO, 9.5 * s, TMP.a:set(x0, y), COLOR_DIM)
      return
    end
    local track = io.tracks[tostring(d.track or e.track)] or {}
    local cars, tmin, tmax = {}, math.huge, -math.huge
    local k = 0
    for guid, list in pairs(type(d.lap_logs) == 'table' and d.lap_logs or {}) do
      if type(list) == 'table' and #list > 0 then
        k = k + 1
        table.sort(list, function(a, b) return (a.ts or 0) < (b.ts or 0) end)
        local name = (type(d.drivers) == 'table' and type(d.drivers[guid]) == 'table' and d.drivers[guid].name) or guid
        cars[#cars + 1] = { name = tostring(name), list = list, color = COLORS[(k - 1) % #COLORS + 1] }
        tmin, tmax = math.min(tmin, list[1].ts), math.max(tmax, list[#list].ts)
      end
    end
    local evT = tonumber(d.ts or e.ts) or tmin
    if tmin == math.huge then tmin, tmax = evT - 2000, evT + 1000 end
    tmax = math.max(tmax, evT + 500)
    v.t = v.t or tmin
    local now = state.ui.clock
    if v.playing then
      v.t = v.t + (now - (v.lastClock or now)) * 1000 * v.speed
      if v.t >= tmax then v.t, v.playing = tmax, false end
    end
    v.lastClock = now
    local cx = x0
    cx = chip('<< 1s', vec2(cx, y), s, false, nil, function() v.t = math.max(tmin, v.t - 1000) end)
    cx = chip(v.playing and TEXTS.kmrEvPause or TEXTS.kmrEvPlay, vec2(cx, y), s, v.playing, nil, function()
      if not v.playing and v.t >= tmax then v.t = tmin end
      v.playing = not v.playing
    end)
    cx = chip('1s >>', vec2(cx, y), s, false, nil, function() v.t = math.min(tmax, v.t + 1000) end)
    cx = cx + 8 * s
    for _, sp in ipairs({ 0.25, 0.5, 1 }) do
      cx = chip(sp .. 'x', vec2(cx, y), s, v.speed == sp, nil, function() v.speed = sp end)
    end
    cx = chip(TEXTS.kmrEvToEvent, vec2(cx + 8 * s, y), s, false, PANEL_COLORS.red, function() v.t, v.playing = evT, false end)
    cx = chip('-', vec2(cx + 8 * s, y), s, false, nil, function() v.zoom = math.min(#ZOOMS, v.zoom + 1) end)
    chip('+', vec2(cx, y), s, false, nil, function() v.zoom = math.max(1, v.zoom - 1) end)
    y = y + 22 * s
    local ta, tb = vec2(x0, y), vec2(p2.x - 12 * s, y + 8 * s)
    ui.drawRectFilled(ta, tb, rgbm(1, 1, 1, 0.1), 2 * s)
    local function xOf(t) return ta.x + (tb.x - ta.x) * (t - tmin) / math.max(tmax - tmin, 1) end
    ui.drawRectFilled(ta, vec2(xOf(v.t), tb.y), rgbm(0.4, 0.6, 1, 0.6), 2 * s)
    ui.drawLine(vec2(xOf(evT), ta.y - 3 * s), vec2(xOf(evT), tb.y + 3 * s), PANEL_COLORS.red, 2 * s)
    local SEG = 40
    for i = 0, SEG - 1 do
      local a = vec2(ta.x + (tb.x - ta.x) * i / SEG, ta.y - 3 * s)
      local b = vec2(ta.x + (tb.x - ta.x) * (i + 1) / SEG, tb.y + 3 * s)
      Drag.clickable(a, b, function() v.t, v.playing = tmin + (tmax - tmin) * (i + 0.5) / SEG, false end)
    end
    drawTextRight(string.format('%+.1f s', (v.t - evT) / 1000), FONT_MONO, 9 * s, p2.x - 12 * s, y + 10 * s, COLOR_DIM)
    y = y + 24 * s
    local ma, mb = vec2(x0, y), vec2(p2.x - 12 * s, p2.y - 12 * s)
    ui.drawRectFilled(ma, mb, rgbm(0, 0, 0, 0.55), 2 * s)
    local ep = d.event_position or { x = 0, z = 0 }
    local half = ZOOMS[v.zoom]
    local scale = math.min(mb.x - ma.x, mb.y - ma.y) / (2 * half)
    local mc = vec2((ma.x + mb.x) / 2, (ma.y + mb.y) / 2)
    local function sp(p) return vec2(mc.x + (p.x - ep.x) * scale, mc.y - (p.z - ep.z) * scale) end
    ui.pushClipRect(ma, mb)
    local function line(list, col, w)
      if type(list) ~= 'table' then return end
      local prev
      local keys = {}
      for key in pairs(list) do if tonumber(key) then keys[#keys + 1] = tonumber(key) end end
      table.sort(keys)
      for _, key in ipairs(keys) do
        local q = list[key] or list[tostring(key)]
        local wp = type(q) == 'table' and (q.wp or q) or nil
        if wp and wp.x then
          local pt = sp(wp)
          if prev and math.abs(pt.x - prev.x) + math.abs(pt.y - prev.y) < 400 * s then ui.drawLine(prev, pt, col, w) end
          prev = pt
        end
      end
    end
    local b = type(track.boundary) == 'table' and track.boundary or {}
    line(b.left, rgbm(0.85, 0.85, 0.85, 0.9), 1.5 * s)
    line(b.right, rgbm(0.85, 0.85, 0.85, 0.9), 1.5 * s)
    local pa = type(track.pit_area) == 'table' and track.pit_area or {}
    line(pa.left, rgbm(0.5, 0.55, 0.6, 0.8), 1 * s)
    line(pa.right, rgbm(0.5, 0.55, 0.6, 0.8), 1 * s)
    for _, cl in ipairs(type(track.cut_lines) == 'table' and track.cut_lines or {}) do
      if type(cl) == 'table' and cl.a and cl.b then ui.drawLine(sp(cl.a), sp(cl.b), rgbm(1, 0.85, 0.25, 0.7), 1.5 * s) end
    end
    ui.drawCircle(sp(ep), 9 * s, PANEL_COLORS.red, 24, 2 * s)
    local ly = ma.y + 6 * s
    for _, c in ipairs(cars) do
      local prev
      for _, q in ipairs(c.list) do
        local pt = sp(q.world_position)
        if prev then ui.drawLine(prev, pt, rgbm(c.color.r, c.color.g, c.color.b, 0.35), 1 * s) end
        prev = pt
      end
      local pos, q = posAt(c.list, v.t)
      if pos then
        local pt = sp(pos)
        ui.drawCircleFilled(pt, 5 * s, c.color, 16)
        drawText(c.name, FONT_TEXT, 9 * s, TMP.a:set(pt.x + 8 * s, pt.y - 7 * s), c.color)
        drawText(string.format('%s  %d km/h  %s %s  %d rpm', c.name, math.floor((q.velocity_modulus or 0) + 0.5), TEXTS.kmrEvGear,
          tostring(q.gear or '-'), math.floor(q.engine_rpm or 0)), FONT_MONO, 9 * s, TMP.a:set(ma.x + 8 * s, ly), c.color)
        ly = ly + 13 * s
      end
    end
    ui.popClipRect()
  end
  function M.draw(w, h, s, dp1, dp2, chip)
    pump()
    local LW, LH, ROWE = 820 * s, 520 * s, 14 * s
    local x = math.min(math.max(dp1.x, 4 * s), w - LW - 4 * s)
    local yTop = dp2.y + 8 * s
    if yTop + LH > h then yTop = math.max(4 * s, h - LH - 4 * s) end
    local p1 = vec2(math.floor(x), math.floor(yTop))
    local p2 = vec2(p1.x + LW, p1.y + LH)
    drawPanel(p1, p2, BORDER_BASE, s)
    local m = ui.mousePos()
    local over = m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y
    if over then ui.captureMouse(true) end
    drawText(TEXTS.kmrEvTitle, FONT_TITLE, 12 * s, TMP.a:set(p1.x + 12 * s, p1.y + 4 * s), COLOR_TITLE)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() M.open = false end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    if M.view then
      replay(p1, p2, s, chip, M.view.e)
      return
    end
    local x0 = p1.x + 12 * s
    local y = p1.y + 26 * s
    local tx = x0
    for _, f in ipairs({ 'all', 'collision', 'cut', 'generic' }) do
      tx = chip(TEXTS.kmrEvFilters[f], vec2(tx, y), s, M.filter == f, nil, function() M.filter, M.scroll = f, 0 end)
    end
    tx = chip(M.last and TEXTS.kmrEvLast or TEXTS.kmrEvAll, vec2(tx + 10 * s, y), s, M.last, nil, function() M.last, M.scroll = not M.last, 0 end)
    local status = config.kmrStatsUrl == '' and TEXTS.dirWebOff or io.err and string.format(TEXTS.kmrEvErr, io.err)
      or (not io.sid and #io.events == 0) and TEXTS.kmrEvConnecting or nil
    if status then drawTextRight(status, FONT_MONO, 8.5 * s, p2.x - 12 * s, y + 2 * s, io.err and PANEL_COLORS.red or COLOR_DIM) end
    y = y + 22 * s
    local list = rows()
    local top = y
    local fit = math.max(math.floor((p2.y - 8 * s - top) / ROWE), 1)
    if over then M.scroll = M.scroll - math.floor(ui.mouseWheel() * 3) end
    M.scroll = math.min(math.max(M.scroll, 0), math.max(#list - fit, 0))
    if #list == 0 then drawText(TEXTS.kmrEvNone, FONT_MONO, 9.5 * s, TMP.a:set(x0, y), COLOR_DIM) end
    ui.pushClipRect(vec2(p1.x, top), vec2(p2.x, p2.y - 4 * s))
    for i = M.scroll + 1, math.min(#list, M.scroll + fit) do
      local e = list[i]
      local col = e.type == 'collision' and PANEL_COLORS.red or e.type == 'cut' and PANEL_COLORS.yellow or COLOR_DIM
      drawText(hhmmss(e.ts), FONT_MONO, 9 * s, TMP.a:set(x0, y), COLOR_DIM)
      drawText(TEXTS.kmrEvKinds[e.type] or tostring(e.type), FONT_MONO, 9 * s, TMP.a:set(x0 + 66 * s, y), col)
      drawText(who(e), FONT_TEXT, 9 * s, TMP.a:set(x0 + 150 * s, y), COLOR_TITLE)
      drawText((e.car_lap and (TEXTS.kmrEvLap .. tostring(e.car_lap) .. '  ') or '') .. detail(e), FONT_MONO, 9 * s, TMP.a:set(x0 + 440 * s, y), COLOR_DIM)
      drawTextRight(penalty(e), FONT_MONO, 9 * s, p2.x - 90 * s, y, COLOR_TITLE)
      if hasReplay(e) then
        chip(TEXTS.kmrEvReplay, vec2(p2.x - 80 * s, y - 2 * s), s, false, nil, function() M.view = { e = e, speed = 0.5, zoom = 2 } ; ask(e) end)
      end
      y = y + ROWE
    end
    ui.popClipRect()
  end
  M._test = { packets = packets, enc = enc, posAt = posAt, io = io, rows = rows }
  return M
end)()
local drawDesktopUI = (function()
  local W = 780
  local CANVAS_W = 422
  local drag = nil
  local moving = nil
  local sizing = nil
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
  local function panelGuard(w, h)
    local k = h / 1080
    local pr = Drag.lastRects.panel
    local x1 = pr and pr.min.x or (w / 2 - PANEL_WIDTH / 2 * k)
    local x2 = pr and pr.max.x or (w / 2 + PANEL_WIDTH / 2 * k)
    local top = pr and pr.min.y or (h * 0.18 + 10 * k)
    local bottom = pr and pr.max.y or (top + 66 * k)
    local extra = Drag.panelExtra or 0
    local sTop = top - extra
    local sBottom = top
    if sTop < 0 then sTop, sBottom = bottom, bottom + extra end
    local s = math.min(math.max((h / 1080) ^ 0.3, 1), 1.3)
    local fTop = math.max(bottom, sBottom) + math.floor(6 * s)
    local fBottom = fTop + math.floor(56 * s)
    return { x1 = x1, x2 = x2, top = top, bottom = bottom, sTop = sTop, sBottom = sBottom, fTop = fTop,
      fBottom = fBottom, gTop = math.min(top, sTop), gBottom = math.max(bottom, sBottom, fBottom) }
  end
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
    if on then ui.drawRectFilled(a, b, PANEL_COLORS.yellow, 3 * s) else ui.drawRect(a, b, TMP.edge30, 3 * s) end
    local cs = math.max(9 * s, Desktop.text.minPx)
    ui.pushDWriteFont(FONT_MONO)
    local th = ui.measureDWriteText(text, cs).y
    ui.popDWriteFont()
    drawText(text, FONT_MONO, 9 * s, TMP.a:set(a.x + 5 * s, a.y + (b.y - a.y - th) / 2), on and TMP.dark or (color or COLOR_DIM))
    if fn then Drag.clickable(a, b, fn) end
    return b.x + 4 * s
  end
  local function where(g)
    local p, out = Desktop.place, {}
    if p.all[g] then return TEXTS.edAll end
    for d = 1, Desktop.count do if p[d] and p[d][g] then out[#out + 1] = tostring(d) end end
    if p.track and p.track[g] then out[#out + 1] = TEXTS.edTrackTag end
    if p.pit[g] then out[#out + 1] = TEXTS.edPitTag end
    return #out > 0 and table.concat(out, ' ') or '-'
  end
  local function editor(w, h, s)
    local canvasH = CANVAS_W * h / w
    local listRows = math.ceil(#Desktop.SCREENS / 2)
    local H = math.max(canvasH + (Desktop.pitOn and 96 or 110), 47 + 15 + listRows * 18 + 12)
    local p1, p2 = windowAt('editor', W, H, w, h, s)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    if m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y then ui.captureMouse(true) end
    local move = moving and moving.id == 'editor'
    drawPanel(p1, p2, BORDER_BASE, s)
    local desk = Desktop.editDesk
    drawText(TEXTS.edTitle, FONT_TITLE, 12 * s, TMP.a:set(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    local right = desk == 'pit' and TEXTS.edPitDesk or desk == 'track' and TEXTS.edTrackDesk or string.format(TEXTS.edDeskOf, desk, Desktop.count)
    drawTextRight(right, FONT_MONO, 11 * s, p2.x - 34 * s, p1.y + 5 * s, COLOR_TITLE)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Desktop.editor = false end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local x = p1.x + 14 * s
    local ty = p1.y + 27 * s
    for d = 1, Desktop.count do
      x = chip(tostring(d), vec2(x, ty), s, desk == d, nil, function() Desktop.editDesk = d end)
    end
    x = chip('+', vec2(x, ty), s, false, nil, Desktop.addDesktop)
    x = chip(TEXTS.edTrackTag, vec2(x, ty), s, desk == 'track', PANEL_COLORS.green, function() Desktop.editDesk = 'track' end)
    x = chip(TEXTS.edPitTag, vec2(x, ty), s, desk == 'pit', PANEL_COLORS.green, function() Desktop.editDesk = 'pit' end)
    drawText(TEXTS.edHint, FONT_MONO, 8.5 * s, TMP.a:set(x + 6 * s, ty + 2 * s), COLOR_DIM)
    local c1 = vec2(p1.x + 14 * s, p1.y + 47 * s)
    local c2 = vec2(c1.x + CANVAS_W * s, c1.y + canvasH * s)
    ui.drawRectFilled(c1, c2, rgbm(0.06, 0.07, 0.09, 1), 3 * s)
    ui.drawRect(c1, c2, rgbm(1, 1, 1, 0.2), 3 * s)
    local k = h / 1080
    local cs = CANVAS_W * s / w
    local function toCanvas(px, py) return vec2(c1.x + px * cs, c1.y + py * cs) end
    local pr = Drag.lastRects.panel
    local pa = pr and toCanvas(pr.min.x, pr.min.y) or toCanvas(w / 2 - PANEL_WIDTH / 2 * k, h * 0.18)
    local pb = pr and toCanvas(pr.max.x, pr.min.y + 66 * k) or toCanvas(w / 2 + PANEL_WIDTH / 2 * k, h * 0.18 + 66 * k)
    ui.drawRectFilled(pa, pb, rgbm(0.24, 0.25, 0.28, 0.95), 2 * s)
    ui.drawRect(pa, pb, (drag and drag.g == 'panel') and PANEL_COLORS.yellow or rgbm(1, 1, 1, 0.45), 2 * s)
    if pr and not drag and not move and not Drag.pinned('panel') and ui.mouseClicked() and m.x >= pa.x and m.x <= pb.x
        and m.y >= pa.y and m.y <= pb.y then
      drag = { g = 'panel', dx = (m.x - pa.x) / cs, dy = (m.y - pa.y) / cs, base = pr.base,
        size = vec2(pr.max.x - pr.min.x, pr.max.y - pr.min.y) }
    end
    drawText(TEXTS.rcTitle, FONT_TEXT, 7.5 * s, TMP.a:set(pa.x + 3 * s, pa.y + 1 * s), COLOR_DIM)
    local guard = panelGuard(w, h)
    local sa, sb = toCanvas(guard.x1, guard.sTop), toCanvas(guard.x2, guard.sBottom)
    dashedRect(sa, sb, rgbm(1, 1, 1, 0.45), s)
    drawText(TEXTS.edStrip, FONT_TEXT, 6.5 * s, TMP.a:set(sa.x + 3 * s, sa.y + 0.5 * s), COLOR_DIM)
    local fa, fb = toCanvas(guard.x1, guard.fTop), toCanvas(guard.x2, guard.fBottom)
    dashedRect(fa, fb, rgbm(1, 1, 1, 0.45), s)
    drawText(TEXTS.edFlagStrip, FONT_TEXT, 6.5 * s, TMP.a:set(fa.x + 3 * s, fa.y + 0.5 * s), COLOR_DIM)
    local lists = { { Desktop.place.all, true } }
    if Desktop.place[desk] then lists[#lists + 1] = { Desktop.place[desk], false } end
    for _, L in ipairs(lists) do
      for g, e in pairs(L[1]) do
        local r = Drag.lastRects[g]
        if r then
          local rmin, rmax, base = r.min, r.max, r.base
          local a, b = toCanvas(rmin.x, rmin.y), toCanvas(rmax.x, rmax.y)
          local size = vec2(rmax.x - rmin.x, rmax.y - rmin.y)
          b = vec2(math.max(b.x, a.x + 56 * s), math.max(b.y, a.y + 22 * s))
          if b.x > c2.x then a = vec2(a.x - (b.x - c2.x), a.y); b = vec2(c2.x, b.y) end
          if b.y > c2.y then a = vec2(a.x, a.y - (b.y - c2.y)); b = vec2(b.x, c2.y) end
          local dragging = drag and drag.g == g
          ui.drawRectFilled(a, b, rgbm(0.16, 0.17, 0.2, 0.95), 2 * s)
          ui.drawRect(a, b, dragging and PANEL_COLORS.yellow or (L[2] and PANEL_COLORS.green or rgbm(1, 1, 1, 0.45)), 2 * s)
          ui.pushClipRect(a, b)
          drawText(TEXTS.screenNames[g] or g, FONT_TEXT, 7.5 * s, TMP.a:set(a.x + 3 * s, a.y + 1 * s), COLOR_TITLE)
          ui.popClipRect()
          local isz = 9 * s
          local ix, iy = b.x - 4 * (isz + 2 * s) - 1 * s, b.y - isz - 2 * s
          local function icon(id, col, fn)
            local q1, q2 = vec2(ix, iy), vec2(ix + isz, iy + isz)
            ui.drawIcon(id, q1, q2, col)
            Drag.clickable(vec2(q1.x - 1 * s, q1.y - 1 * s), vec2(q2.x + 1 * s, q2.y + 1 * s), fn)
            ix = ix + isz + 2 * s
          end
          icon(ui.Icons.Monitor, L[2] and PANEL_COLORS.green or COLOR_DIM, function() Desktop.pinAll(L[2] and 'all' or desk, g) end)
          icon(e.mode == 'hidden' and ui.Icons.Hide or ui.Icons.Eye, e.mode == 'hidden' and COLOR_DIM or COLOR_TITLE,
            function() e.mode = Drag.EYE_NEXT[e.mode] or e.mode; Desktop.save() end)
          icon(ui.Icons.Ghost, e.mode == 'auto' and COLOR_TITLE or COLOR_DIM,
            function() e.mode = Drag.GHOST_NEXT[e.mode] or e.mode; Desktop.save() end)
          icon(ui.Icons.Trash, PANEL_COLORS.red, function() Desktop.remove(L[2] and 'all' or desk, g) end)
          local onIcons = m.x >= b.x - 4 * (isz + 2 * s) - 2 * s and m.y >= iy - 1 * s
          if not drag and not move and not onIcons and ui.mouseClicked() and m.x >= a.x and m.x <= b.x
              and m.y >= a.y and m.y <= b.y then
            drag = { g = g, entry = e, dx = (m.x - a.x) / cs, dy = (m.y - a.y) / cs, base = base, size = size }
          end
        end
      end
    end
    if drag then
      if ui.mouseDown() then
        local tx = math.min(math.max((m.x - c1.x) / cs - drag.dx, 0), w - drag.size.x)
        local ty = math.min(math.max((m.y - c1.y) / cs - drag.dy, 0), h - drag.size.y)
        if drag.g == 'panel' then
          ty = Drag.fitPanel(ty, drag.size.y, h)
          Drag.setOffset('panel', vec2((tx - drag.base.x) / k, (ty - drag.base.y) / k))
        else
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
    local lx, ly = c2.x + 12 * s, c1.y
    drawText(TEXTS.edScreens, FONT_TITLE, 10 * s, TMP.a:set(lx, ly), COLOR_DIM)
    ly = ly + 15 * s
    local colGap = 6 * s
    local colW = (p2.x - 14 * s - lx - colGap) / 2
    for i, g in ipairs(Desktop.SCREENS) do
      local col, row = math.floor((i - 1) / listRows), (i - 1) % listRows
      local on = Desktop.place[desk] and Desktop.place[desk][g] or Desktop.place.all[g]
      local a = vec2(lx + col * (colW + colGap), ly + row * 18 * s)
      local b = vec2(a.x + colW, a.y + 15 * s)
      ui.drawRect(a, b, on and PANEL_COLORS.yellow or rgbm(1, 1, 1, 0.2), 3 * s)
      local wtext = where(g)
      local ww = textWidth(wtext, FONT_MONO, 8.5 * s)
      ui.pushClipRect(a, vec2(b.x - ww - 8 * s, b.y))
      drawText(TEXTS.screenNames[g] or g, FONT_TEXT, 8.5 * s, TMP.a:set(a.x + 5 * s, a.y + 1.5 * s), COLOR_TITLE)
      ui.popClipRect()
      drawTextRight(wtext, FONT_MONO, 8.5 * s, b.x - 5 * s, a.y + 1.5 * s, on and PANEL_COLORS.yellow or COLOR_DIM)
      Drag.clickable(a, b, function() Desktop.toggle(desk, g) end)
    end
    local by = c2.y + 8 * s
    local bx = c1.x
    bx = chip(TEXTS.edReset, vec2(bx, by), s, false, nil, function()
      for _, e in pairs(Desktop.place[desk] or {}) do e.x, e.y = 0, 0 end
      Desktop.save()
    end)
    bx = chip(TEXTS.edDefault, vec2(bx, by), s, false, nil, function()
      Desktop.place[desk] = desk == 'pit' and Desktop.pitDefault() or Desktop.trackDefault()
      Desktop.save()
    end)
    bx = chip(TEXTS.edCopy, vec2(bx, by), s, false, nil, function() Desktop.copyFrom(1, desk) end)
    bx = chip(TEXTS.edDelete, vec2(bx, by), s, false, PANEL_COLORS.red, function() Desktop.deleteDesktop(desk) end)
    chip(Desktop.pitOn and TEXTS.edPitOn or TEXTS.edPitOff, vec2(bx, by), s, false,
      Desktop.pitOn and PANEL_COLORS.green or PANEL_COLORS.red, function() Desktop.pitOn = not Desktop.pitOn; Desktop.save() end)
    if not Desktop.pitOn then
      drawText(TEXTS.edPitWarning, FONT_MONO, 8.5 * s, TMP.a:set(c1.x, by + 18 * s), PANEL_COLORS.yellow)
    end
    local ny = by + (Desktop.pitOn and 20 or 34) * s
    local nav = Desktop.NAV
    local function bound(b) return b.boundTo and b:boundTo() or nil end
    drawText(string.format(TEXTS.edButtons, bound(nav.nextScreen) or '-', bound(nav.prevScreen) or '-',
      bound(nav.nextDesktop) or '-', bound(nav.prevDesktop) or '-'), FONT_MONO, 8.5 * s, TMP.a:set(c1.x, ny), COLOR_DIM)
  end
  local function indicator(w, h, s)
    local names = {}
    for g in pairs(Desktop.place[Desktop.activeKey()] or {}) do names[#names + 1] = TEXTS.screenNames[g] or g end
    table.sort(names)
    local text = string.format(TEXTS.edIndicator, Desktop.current, Desktop.count, table.concat(names, ' - '))
    local tw = textWidth(text, FONT_MONO, 11 * s)
    local gd = panelGuard(w, h)
    local top = gd.gTop - 6 * s - 22 * s
    if top < 0 then top = gd.gBottom + 6 * s end
    local p1 = vec2(math.floor((gd.x1 + gd.x2) / 2 - tw / 2 - 12 * s), math.floor(top))
    local p2 = vec2(p1.x + tw + 24 * s, p1.y + 22 * s)
    Drag.group = nil
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(text, FONT_MONO, 11 * s, TMP.a:set(p1.x + 12 * s, p1.y + 4 * s), COLOR_TITLE)
  end
  local function closeWindows()
    Desktop.editor, Audit.open, Desktop.buttons, Desktop.settingsOpen, Desktop.redOpen = false, false, false, false, false
    Desktop.cockpitOpen = false
  end
  local function menu(w, h, s)
    local pr = Drag.lastRects.panel
    if not pr then return end
    local items = { { TEXTS.menuDesktops, function() closeWindows(); Desktop.editor = true end },
      { TEXTS.menuAudit, function() closeWindows(); Audit.open = true end },
      { TEXTS.menuButtons, function() closeWindows(); Desktop.buttons = true end },
      { TEXTS.menuSettings, function() closeWindows(); Desktop.settingsOpen = true end },
      { TEXTS.menuCockpit, function() closeWindows(); Desktop.cockpitOpen = true end } }
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
      drawText(it[1], FONT_TEXT, 10 * s, TMP.a:set(a.x + 6 * s, a.y + 2 * s), COLOR_TITLE)
      Drag.clickable(a, b, function() it[2](); Desktop.menu = false end)
    end
  end
  local function cockpitWindow(w, h, s)
    local wide = Desktop.cockpitWide()
    local p1, p2 = windowAt('cockpit', wide and 526 or 260, Desktop.cockpitHeight(), w, h, s)
    if wide then p2 = vec2(p1.x + 260 * s, p2.y) end
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    if m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y then ui.captureMouse(true) end
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.scrCockpit, FONT_TITLE, 12 * s, TMP.a:set(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    if not AppLink.alive then drawTextRight(TEXTS.cockpitNoApp, FONT_MONO, 11 * s, p2.x - 34 * s, p1.y + 5 * s, COLOR_TITLE) end
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Desktop.cockpitOpen = false end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    Desktop.cockpitBody(ac.getCar(0), p1, p2, p1.y + 26 * s, s, false)
  end
  local AUDIT_ROWS = 16
  local SRC_COLOR = { KMR = PANEL_COLORS.yellow, ACSM = PANEL_COLORS.blue }
  local function audit(w, h, s)
    local W2, ROW2 = 620, 14
    local H2 = 44 + AUDIT_ROWS * ROW2 + 10
    local p1, p2, _, hNow = windowAt('audit', W2, H2, w, h, s, true)
    local AUDIT_ROWS = math.max(math.floor((hNow - 54) / ROW2), 1)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    local over = m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y
    if over then ui.captureMouse(true) end
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.auditTitle, FONT_TITLE, 12 * s, TMP.a:set(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    local pts = Audit.points and string.format(TEXTS.auditPoints, Audit.points, config.kmrPoints.limit)
      or string.format(TEXTS.auditPoints, 0, config.kmrPoints.limit):gsub('^(%S+ %S+ )0', '%1-')
    local rating = string.format(TEXTS.auditRating, Audit.rating and Audit.num(Audit.rating) or '-')
    drawTextRight(pts .. '   ' .. rating .. '   ' .. string.format(TEXTS.auditCount, #Audit.items), FONT_MONO, 11 * s, p2.x - 34 * s,
      p1.y + 5 * s, COLOR_TITLE)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Audit.open = false end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
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
        9.5 * s, TMP.a:set(p1.x + 14 * s, y), COLOR_DIM)
      drawText(it.src, FONT_MONO, 9.5 * s, TMP.a:set(p1.x + 76 * s, y), SRC_COLOR[it.src] or COLOR_TITLE)
      drawText(it.text, FONT_TEXT, 9.5 * s, TMP.a:set(p1.x + 118 * s, y), COLOR_TITLE)
      y = y + ROW2 * s
    end
    ui.popClipRect()
    if n == 0 then drawText(TEXTS.auditEmpty, FONT_MONO, 9.5 * s, TMP.a:set(p1.x + 14 * s, y), COLOR_DIM) end
  end
  local function NAV_ROWS() return { { 'nextScreen', TEXTS.navNextScreen }, { 'prevScreen', TEXTS.navPrevScreen },
    { 'nextDesktop', TEXTS.navNextDesktop }, { 'prevDesktop', TEXTS.navPrevDesktop },
    { 'showPanel', TEXTS.navShowPanel }, { 'up', TEXTS.navUp }, { 'down', TEXTS.navDown }, { 'left', TEXTS.navLeft }, { 'right', TEXTS.navRight } } end
  local function SCREEN_ROWS()
    local out = {}
    for _, g in ipairs(Desktop.SCREENS) do out[#out + 1] = { 'scr' .. g, TEXTS.screenNames[g] or g } end
    return out
  end
  Desktop.buttonsTab = 'nav'
  local function buttonsScreen(w, h, s)
    local LIST = Desktop.buttonsTab == 'screens' and SCREEN_ROWS() or NAV_ROWS()
    local rows, ownW, cspW = {}, textWidth(TEXTS.navOwn, FONT_TITLE, 9 * s), textWidth(TEXTS.navCsp, FONT_TITLE, 9 * s)
    for _, r in ipairs(LIST) do
      local name = r[1]
      local cap = Desktop.capture and Desktop.capture.name == name
      local own = cap and string.format(TEXTS.navPress, math.max(math.ceil(Desktop.capture.untilT - state.ui.clock), 0))
        or Desktop.bindText(name) or '-'
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
    local W3, H3 = math.max(560, (cspX + cspW + 16 * s) / s), 44 + #LIST * 22 + 22
    local p1, p2 = windowAt('buttons', W3, H3, w, h, s)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    if m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y then ui.captureMouse(true) end
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.navTitle, FONT_TITLE, 12 * s, TMP.a:set(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    local tx = p1.x + 150 * s
    for _, k in ipairs({ 'nav', 'screens' }) do
      tx = chip(TEXTS.navTabs[k], vec2(tx, p1.y + 4 * s), s, Desktop.buttonsTab == k, nil, function()
        Desktop.buttonsTab = k
        Desktop.capture = nil
      end)
    end
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Desktop.buttons = false; Desktop.capture = nil end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local y = p1.y + 30 * s
    drawText(TEXTS.navOwn, FONT_TITLE, 9 * s, TMP.a:set(p1.x + ownX, y), COLOR_DIM)
    drawText(TEXTS.navCsp, FONT_TITLE, 9 * s, TMP.a:set(p1.x + cspX, y), COLOR_DIM)
    y = y + 16 * s
    for _, r in ipairs(rows) do
      local name, cap, own, conflict = r.name, r.cap, r.own, r.conflict
      local lit = Desktop.fired(name)
      if lit then
        ui.drawRectFilled(vec2(p1.x + 8 * s, y - 2 * s), vec2(p2.x - 8 * s, y + 18 * s), rgbm(0.1, 0.55, 0.25, 0.35), 2 * s)
      end
      drawText(r.label, FONT_TEXT, 10 * s, TMP.a:set(p1.x + 14 * s, y + 1 * s), lit and PANEL_COLORS.green or COLOR_TITLE)
      drawText(own, FONT_MONO, 9.5 * s, TMP.a:set(p1.x + ownX, y + 1.5 * s), conflict and PANEL_COLORS.red
        or (cap and PANEL_COLORS.yellow or (own == '-' and COLOR_OFF or COLOR_TITLE)))
      if conflict then
        drawText(conflict, FONT_MONO, 8.5 * s, TMP.a:set(p1.x + ownX, y + 12 * s), PANEL_COLORS.red)
      end
      local x = chip(TEXTS.navSet, vec2(p1.x + setX, y), s, cap, nil, function() Desktop.startCapture(name) end)
      chip(TEXTS.navClear, vec2(x, y), s, false, PANEL_COLORS.red, function() Desktop.clearBind(name) end)
      drawText(r.csp, FONT_MONO, 9.5 * s, TMP.a:set(p1.x + cspX, y + 1.5 * s), r.csp == '-' and COLOR_OFF or COLOR_TITLE)
      y = y + 22 * s
    end
  end
  local AREAS = { 'limits', 'damage', 'points', 'warnings', 'others', 'server', 'results', 'welcome', 'admin', 'chat',
    'diag' }
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
  local Controls = { last = nil, changed = nil, group = nil, untilT = 0, list = {}, drs = nil, aeroUntil = 0, pit = nil,
    pitUntil = 0 }
  local BLOCK = { elec = 'ABS|TC|TC2', engine = 'Engine Map', pit = 'Pit limiter' }
  local blockOff, blockKey = nil, ''
  local allBlock = nil
  local function blockUpdate()
    if not allBlock and ac.blockSystemMessages then allBlock = ac.blockSystemMessages('.') end
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
    if absN > 0 then add('elec', 'abs', 'ABS', abs > 0 and string.format('%d', abs) or TEXTS.ctlBox.off) end
    if tcN > 0 then add('elec', 'tc', 'TC', tc > 0 and string.format('%d', tc) or TEXTS.ctlBox.off) end
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
      add('hybrid', 'recov', TEXTS.ctlBox.recov, string.format('%d%%', CarRead.num(c.mgukRecovery) * 10))
      add('hybrid', 'mguh', 'MGU-H', c.mguhChargingBatteries and TEXTS.ctlBox.batt or TEXTS.ctlBox.motor)
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
    local drs = nil
    if car.drsPresent then drs = car.drsActive == true end
    if drs == false and Controls.drs == true then Controls.aeroUntil = state.ui.clock + config.screens.controlSeconds end
    Controls.drs = drs
    local pit = nil
    if car.manualPitsSpeedLimiterEnabled ~= nil then pit = car.manualPitsSpeedLimiterEnabled == true end
    if pit == false and Controls.pit == true then Controls.pitUntil = state.ui.clock + config.screens.controlSeconds end
    Controls.pit = pit
    blockUpdate()
  end
  Desktop.controlsUpdate = controlsUpdate
  local function controlsBox(p1, s)
    local items = {}
    for _, it in ipairs(Controls.list) do if it.group == Controls.group then items[#items + 1] = it end end
    local p2 = vec2(p1.x + 196 * s, p1.y + 56 * s)
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.ctlGroup[Controls.group] or '', FONT_TITLE, 9 * s, TMP.a:set(p1.x + 12 * s, p1.y + 5 * s), PANEL_COLORS.yellow)
    local cw = (p2.x - p1.x - 20 * s) / 3
    for i, it in ipairs(items) do
      local x = p1.x + 12 * s + (i - 1) * cw
      local on = it.key == Controls.changed
      drawText(it.label, FONT_TITLE, 9 * s, TMP.a:set(x, p1.y + 19 * s), on and PANEL_COLORS.yellow or COLOR_DIM)
      drawText(it.value, FONT_MONO, 12 * s, TMP.a:set(x, p1.y + 31 * s), on and PANEL_COLORS.yellow or COLOR_TITLE)
    end
  end
  local function aeroBox(p1, s)
    local B = TEXTS.ctlBox
    local vw = math.max(textWidth(B.aero, FONT_TITLE, 9 * s), textWidth(B.drs, FONT_TITLE, 9 * s),
      textWidth(B.closed, FONT_MONO, 12 * s), textWidth(B.open, FONT_MONO, 12 * s))
    local p2 = vec2(p1.x + vw + 24 * s, p1.y + 56 * s)
    local open = Controls.drs == true
    drawPanel(p1, p2, open and BORDER_GREEN or BORDER_BASE, s)
    drawText(B.aero, FONT_TITLE, 9 * s, TMP.a:set(p1.x + 12 * s, p1.y + 5 * s), open and PANEL_COLORS.green or COLOR_TITLE)
    drawText(B.drs, FONT_TITLE, 9 * s, TMP.a:set(p1.x + 12 * s, p1.y + 19 * s), COLOR_DIM)
    drawText(open and B.open or B.closed, FONT_MONO, 12 * s, TMP.a:set(p1.x + 12 * s, p1.y + 31 * s),
      open and PANEL_COLORS.green or COLOR_TITLE)
  end
  local function pitBox(p1, s)
    local B = TEXTS.ctlBox
    local vw = math.max(textWidth(B.limiter, FONT_TITLE, 9 * s), textWidth(B.off, FONT_MONO, 12 * s), textWidth(B.on, FONT_MONO, 12 * s), textWidth(B.pit, FONT_TITLE, 9 * s))
    local p2 = vec2(p1.x + vw + 24 * s, p1.y + 56 * s)
    local on = Controls.pit == true
    drawPanel(p1, p2, on and BORDER_GREEN or BORDER_BASE, s)
    drawText(B.pit, FONT_TITLE, 9 * s, TMP.a:set(p1.x + 12 * s, p1.y + 5 * s), on and PANEL_COLORS.green or COLOR_TITLE)
    drawText(B.limiter, FONT_TITLE, 9 * s, TMP.a:set(p1.x + 12 * s, p1.y + 19 * s), COLOR_DIM)
    drawText(on and B.on or B.off, FONT_MONO, 12 * s, TMP.a:set(p1.x + 12 * s, p1.y + 31 * s), on and PANEL_COLORS.green or COLOR_TITLE)
  end
  local function controlsShown()
    local ctl = Settings.ctl
    if not ctl.on then return nil end
    if state.ui.clock < Controls.untilT and Controls.group and ctl[Controls.group] then return 'group' end
    if ctl.aero and Controls.drs ~= nil and (Controls.drs or state.ui.clock < Controls.aeroUntil) then return 'aero' end
    if ctl.pit and Controls.pit ~= nil and (Controls.pit or state.ui.clock < Controls.pitUntil) then return 'pit' end
    return nil
  end
  local function tick(p, on, s, locked)
    local a, b = vec2(p.x, p.y + 1 * s), vec2(p.x + 10 * s, p.y + 11 * s)
    ui.drawRect(a, b, locked and COLOR_OFF or rgbm(1, 1, 1, 0.6), 2 * s)
    if on then ui.drawRectFilled(vec2(a.x + 2 * s, a.y + 2 * s), vec2(b.x - 2 * s, b.y - 2 * s),
      locked and COLOR_OFF or PANEL_COLORS.green, 1 * s) end
  end
  local function settingsWindow(w, h, s)
    if not Settings.shown then Settings.appT = nil end
    Settings.shown = true
    local W4 = 520
    local H4 = 30 + math.max(#AREAS + 3, #CTL, 6, #Desktop.text.sets + 3) * 18 + 10
    local p1, p2 = windowAt('settings', W4, H4, w, h, s)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    if m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y then ui.captureMouse(true) end
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.setTitle, FONT_TITLE, 12 * s, TMP.a:set(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    local x = p1.x + 150 * s
    for _, t in ipairs({ 'messages', 'controls', 'text', 'design', 'app', 'room' }) do
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
      drawText(TEXTS.setPreset, FONT_TITLE, 9 * s, TMP.a:set(x0, y + 1 * s), COLOR_DIM)
      for _, name in ipairs(PRESET_ORDER) do
        px = chip(TEXTS.setPresets[name], vec2(px, y), s, Settings.preset == name, nil, function()
          applyPreset(name)
          settingsSave()
        end)
      end
      y = y + 22 * s
      tick(vec2(x0, y), true, s, true)
      drawText(TEXTS.setAreas.rc, FONT_TEXT, 10 * s, TMP.a:set(x0 + 16 * s, y), COLOR_TITLE)
      drawTextRight(TEXTS.setAlways, FONT_MONO, 9 * s, p2.x - 14 * s, y + 1 * s, COLOR_OFF)
      y = y + 18 * s
      for _, a in ipairs(AREAS) do
        local on = Settings.areas[a] == true
        tick(vec2(x0, y), on, s)
        drawText(TEXTS.setAreas[a], FONT_TEXT, 10 * s, TMP.a:set(x0 + 16 * s, y), on and COLOR_TITLE or COLOR_DIM)
        drawTextRight(TEXTS.setAreaHint[a], FONT_MONO, 9 * s, p2.x - 14 * s, y + 1 * s, COLOR_OFF)
        Drag.clickable(vec2(x0, y), vec2(p2.x - 14 * s, y + 14 * s), function()
          Settings.areas[a] = not on or nil
          Settings.preset = 'custom'
          settingsSave()
        end)
        y = y + 18 * s
      end
    elseif Settings.tab == 'text' then
      for _, f in ipairs(Desktop.text.sets) do
        local on = Desktop.text.id == f.id
        tick(vec2(x0, y), on, s, not f.ready)
        drawText(f.name, FONT_TEXT, 10 * s, TMP.a:set(x0 + 16 * s, y), on and COLOR_TITLE or COLOR_DIM)
        if not f.ready then
          drawText(TEXTS.setFontMissing, FONT_MONO, 9 * s, TMP.a:set(x0 + 150 * s, y + 1 * s), COLOR_OFF)
          y = y + 18 * s
          goto nextFont
        end
        ui.pushDWriteFont(f.title)
        ui.dwriteDrawText(TEXTS.setFontSample, 12 * s, vec2(math.floor(x0 + 150 * s), math.floor(y - 1 * s)), COLOR_TITLE)
        ui.popDWriteFont()
        ui.pushDWriteFont(f.mono)
        ui.dwriteDrawText('1:40.123', 12 * s, vec2(math.floor(p2.x - 80 * s), math.floor(y - 1 * s)), PANEL_COLORS.yellow)
        ui.popDWriteFont()
        Drag.clickable(vec2(x0, y), vec2(p2.x - 14 * s, y + 14 * s), function() Desktop.textApply(f.id) end)
        y = y + 18 * s
        ::nextFont::
      end
      y = y + 6 * s
      drawText(TEXTS.setTextMin, FONT_TITLE, 9 * s, TMP.a:set(x0, y + 1 * s), COLOR_DIM)
      local cx = x0 + 110 * s
      for _, v in ipairs({ 0, 10, 11, 12 }) do
        cx = chip(v == 0 and TEXTS.setTextMinOff or (v .. ' px'), vec2(cx, y), s, Desktop.text.min == v, nil,
          function() Desktop.textApply(Desktop.text.id, v) end)
      end
    elseif Settings.tab == 'design' then
      drawText(TEXTS.setOpacity, FONT_TITLE, 9 * s, TMP.a:set(x0, y + 1 * s), COLOR_DIM)
      local ba = vec2(x0 + 110 * s, y)
      local bb = vec2(p2.x - 14 * s, y + 14 * s)
      local frac = (Desktop.opacity - 0.2) / 0.8
      ui.drawRectFilled(ba, bb, rgbm(1, 1, 1, 0.10), 2 * s)
      ui.drawRectFilled(ba, vec2(ba.x + (bb.x - ba.x) * frac, bb.y), rgbm(0.36, 0.38, 0.98, 0.9), 2 * s)
      ui.drawRect(ba, bb, TMP.edge35, 2 * s)
      local ot = string.format('%.0f %%', Desktop.opacity * 100)
      drawText(ot, FONT_MONO, 9 * s, TMP.a:set((ba.x + bb.x) / 2 - textWidth(ot, FONT_MONO, 9 * s) / 2, y + 1.5 * s), COLOR_TITLE)
      Drag.clickable(ba, bb, function()
        local mx = ui.mousePos().x
        Desktop.setOpacity(0.2 + 0.8 * math.min(math.max((mx - ba.x) / (bb.x - ba.x), 0), 1))
      end)
    elseif Settings.tab == 'room' then
      local Rr = RecordSync.base.rr
      drawText(TEXTS.setShareSource, FONT_TITLE, 9 * s, TMP.a:set(x0, y + 1 * s), COLOR_DIM)
      local cx = x0 + 70 * s
      for _, k in ipairs({ 'game', 'screen1', 'screen2', 'screen3' }) do
        cx = chip(TEXTS.setShareSources[k], vec2(cx, y), s, Rr.source == k, nil, function() RecordSync.base.rrSet(k, nil) end)
      end
      y = y + 22 * s
      drawText(TEXTS.setShareLayout, FONT_TITLE, 9 * s, TMP.a:set(x0, y + 1 * s), COLOR_DIM)
      cx = x0 + 70 * s
      for _, k in ipairs({ 'single', 'triple', 'center' }) do
        cx = chip(TEXTS.setShareLayouts[k], vec2(cx, y), s, Rr.layout == k, nil, function() RecordSync.base.rrSet(nil, k) end)
      end
      y = y + 22 * s
      drawText(TEXTS.setShareScope, FONT_TITLE, 9 * s, TMP.a:set(x0, y + 1 * s), COLOR_DIM)
      cx = x0 + 70 * s
      for _, k in ipairs({ 'all', 'room' }) do
        cx = chip(TEXTS.setShareScopes[k], vec2(cx, y), s, Rr.scope == k, nil, function() RecordSync.base.rrSet(nil, nil, k) end)
      end
      y = y + 22 * s
      drawText(TEXTS.setShareVr, FONT_MONO, 9 * s, TMP.a:set(x0, y), COLOR_DIM)
      y = y + 20 * s
      local room, level = RecordSync.base.rrRoom()
      drawText(TEXTS.lobbyRoom, FONT_TITLE, 9 * s, TMP.a:set(x0, y + 1 * s), COLOR_DIM)
      drawText(room, FONT_TEXT, 10 * s, TMP.a:set(x0 + 70 * s, y), ({ ok = PANEL_COLORS.green, warn = PANEL_COLORS.yellow, bad = PANEL_COLORS.red })[level] or COLOR_DIM)
      y = y + 20 * s
      chip(Rr.game and TEXTS.setShareStop or TEXTS.setShareGo, vec2(x0, y), s, Rr.game, nil, function() RecordSync.base.rrShare(not Rr.game) end)
    elseif Settings.tab == 'controls' then
      for _, c in ipairs(CTL) do
        local on = Settings.ctl[c]
        tick(vec2(x0, y), on, s)
        drawText(TEXTS.setCtl[c], FONT_TEXT, 10 * s, TMP.a:set(x0 + 16 * s, y), on and COLOR_TITLE or COLOR_DIM)
        Drag.clickable(vec2(x0, y), vec2(p2.x - 14 * s, y + 14 * s), function()
          Settings.ctl[c] = not on
          settingsSave()
        end)
        y = y + 18 * s
      end
    else
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
        drawText(ok and 'OK' or '--', FONT_MONO, 10 * s, TMP.a:set(x0, y), ok and PANEL_COLORS.green or PANEL_COLORS.red)
        drawText(r[1], FONT_TEXT, 10 * s, TMP.a:set(x0 + 30 * s, y), COLOR_TITLE)
        drawTextRight(ok and r[2] or (r[1] == TEXTS.setApp and AppLink.waiting() and TEXTS.setChecking or TEXTS.setMissing), FONT_MONO, 10 * s, p2.x - 14 * s, y, ok and COLOR_TITLE or PANEL_COLORS.red)
        y = y + 18 * s
      end
      y = y + 4 * s
      if all then
        Settings.appT = Settings.appT or state.ui.clock
        local left = math.max(math.ceil(5 - (state.ui.clock - Settings.appT)), 0)
        drawText(string.format(TEXTS.setAllGood, left), FONT_MONO, 9 * s, TMP.a:set(x0, y), COLOR_DIM)
        if left <= 0 then Desktop.settingsOpen = false end
      else
        drawText(TEXTS.setNotGood, FONT_MONO, 9 * s, TMP.a:set(x0, y), PANEL_COLORS.red)
      end
    end
  end
  local redArm, armKey = 0, nil
  local Direction = { pwd = '', status = nil, statusT = 0, waitLogin = false, seen = nil, guidJob = nil, target = '',
    focus = nil, guids = {}, listOpen = false }
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
  local PROBE_WAIT, PROBE_EVERY = 6, 300
  local function probeKmr()
    if not state.kmrAdmin or Direction.probe then return end
    local me = tostring(ac.getDriverName(0) or '')
    Direction.probe = { t = state.ui.clock, name = me }
    Direction.probeT = state.ui.clock
    queueCommand('/kmr player_name ' .. tostring(ac.getCar(0).sessionID or 0))
    ac.log('race-control: race direction: KMR login checked')
  end
  local function sendKmr(command, label)
    queueCommand('/kmr ' .. command)
    Direction.status, Direction.statusT = string.format(TEXTS.dirSent, label or command), state.ui.clock
    Direction.statusColor = PANEL_COLORS.yellow
    ac.log('race-control: race direction command sent: ' .. (label or command))
  end
  local function refreshDriver(name)
    for i = 0, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and (i == 0 or c.isConnected) and tostring(ac.getDriverName(i) or '') == name then
        queueCommand('/kmr admin_say RC KMR ' .. tostring(c.sessionID or i))
        return
      end
    end
  end
  local BAN_MINUTES = 5256000
  local function releaseDriver(action, name, label, suffix)
    if name == '' then return end
    local known = Direction.guids[name]
    if known then
      queueCommand('/kmr ' .. action .. ' ' .. known .. (suffix or ''))
      refreshDriver(name)
      Direction.status, Direction.statusT = string.format(TEXTS.dirSent, label .. ' ' .. name), state.ui.clock
      Direction.statusColor = PANEL_COLORS.yellow
      ac.log('race-control: race direction command sent: ' .. action .. ' for ' .. name)
      return
    end
    Direction.guidJob = { action = action, name = name, label = label, suffix = suffix, t = state.ui.clock }
    queueCommand('/kmr driver_get_guid ' .. name)
    Direction.status, Direction.statusT = string.format(TEXTS.dirGuidAsk, name), state.ui.clock
    Direction.statusColor = PANEL_COLORS.yellow
    ac.log('race-control: race direction: GUID asked for ' .. name .. ' (' .. action .. ')')
  end
  state.directionAnswer = function(message)
    local pr = Direction.probe
    if pr and pr.name ~= '' and message:find(pr.name, 1, true) and state.ui.clock - pr.t <= PROBE_WAIT then
      Direction.probe = nil
      state.kmrAdmin = true
      return
    end
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
      Direction.guids[job.name] = guid
      if not job.action then
        Direction.status, Direction.statusT, Direction.statusColor = string.format(TEXTS.dirGuidGot, job.name, guid),
          state.ui.clock, COLOR_TITLE
        return
      end
      queueCommand('/kmr ' .. job.action .. ' ' .. guid .. (job.suffix or ''))
      refreshDriver(job.name)
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
  local function armed(key) return armKey == key and state.ui.clock < redArm end
  local function confirmChip(text, key, p, s, color, fn)
    local on = armed(key)
    return chip(on and (text .. ' ?') or text, p, s, on, color, function()
      if armed(key) then armKey, redArm = nil, 0; fn()
      else armKey, redArm = key, state.ui.clock + 5 end
    end)
  end
  local function rowY(text, font, size, y, s)
    size = math.max(size, Desktop.text.minPx)
    ui.pushDWriteFont(font)
    local th = ui.measureDWriteText(text, size).y
    ui.popDWriteFont()
    return y - 1 * s + (14 * s - th) / 2
  end
  local function rowLabel(text, font, size, x, y, s, color)
    drawText(text, font, size, TMP.a:set(x, rowY(text, font, size, y, s)), color)
  end
  local function ownField(key, fa, fb, value, masked, s)
    local on = Direction.focus == key
    ui.drawRectFilled(fa, fb, rgbm(0, 0, 0, 0.5), 2 * s)
    ui.drawRect(fa, fb, on and PANEL_COLORS.yellow or TMP.edge35, 2 * s)
    local caret = on and math.floor(state.ui.clock * 2) % 2 == 0 and '|' or ''
    ui.pushClipRect(fa, fb)
    local shown = (masked and string.rep('*', Lang.letters.count(value)) or value) .. caret
    local ms = math.max(10 * s, Desktop.text.minPx)
    ui.pushDWriteFont(FONT_MONO)
    local th = ui.measureDWriteText(shown ~= '' and shown or 'X', ms).y
    ui.popDWriteFont()
    drawText(shown, FONT_MONO, 10 * s, TMP.a:set(fa.x + 4 * s, fa.y + (fb.y - fa.y - th) / 2), COLOR_TITLE)
    ui.popClipRect()
    Drag.clickable(fa, fb, function() Direction.focus = key end)
    local enter = false
    if on and ui.captureKeyboard then
      local kb = ui.captureKeyboard(true, true, true)
      local typed = kb and kb:queue() or ''
      for ch in typed:gmatch('[^\128-\191][\128-\191]*') do if not ch:match('^%c') then value = value .. ch end end
      for k = 0, (kb and kb.pressedCount or 0) - 1 do
        local k2 = kb.pressed[k]
        if k2 == ui.KeyIndex.Back then value = dropLastLetter(value)
        elseif k2 == ui.KeyIndex.Return then enter = true
        elseif k2 == ui.KeyIndex.Escape then Direction.focus = nil end
      end
    end
    if enter then Direction.focus = nil end
    return value, enter
  end
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
      if c and (i == 0 or c.isConnected) and not CarRead.isStaff(i) then lead = math.max(lead, CarRead.num(c.lapCount)) end
    end
    local total = session and session.laps or 0
    if total > 0 then
      parts[#parts + 1] = string.format(TEXTS.dirSessionLapsOf, lead, total, math.max(total - lead, 0))
    else
      parts[#parts + 1] = string.format(TEXTS.dirSessionLaps, lead)
    end
    return table.concat(parts, '  -  ')
  end
  local WEB_EVERY = 60
  Direction.web = { list = nil, byName = {}, t = -1e9, busy = false, err = nil }
  local function trackKey()
    local id, layout = tostring(ac.getTrackID() or ''), tostring(ac.getTrackLayout and ac.getTrackLayout() or '')
    return id .. (layout ~= '' and ('-' .. layout) or '') .. '_', id
  end
  local function lapTimeText(ms)
    ms = tonumber(ms) or 0
    if ms <= 0 then return '-' end
    return string.format('%d:%06.3f', math.floor(ms / 60000), (ms % 60000) / 1000)
  end
  local function webFetch(page, acc)
    local url = config.kmrStatsUrl .. '/?drivers=true&page=' .. page
    WebQueue.request('GET', url, nil, nil, function(err, res)
      local data = not err and res and res.body and JSON.parse(res.body)
      if type(data) ~= 'table' or type(data.rank) ~= 'table' then
        Direction.web.busy, Direction.web.err = false, tostring(err or TEXTS.dirNoData)
        ac.log('race-control: KMR web stats not read: ' .. Direction.web.err)
        return
      end
      local full = {}
      for _, r in ipairs(type(data.full_rank) == 'table' and data.full_rank or {}) do
        if r.guid then full[tostring(r.guid)] = r end
      end
      local key, id = trackKey()
      for _, r in ipairs(data.rank) do
        local g = tostring(r.guid or '')
        local e = { name = tostring(r.name or ''), guid = g, money = tostring(r.points or '-'), km = tostring(r.driven or '-'),
          infr = tonumber(r.infr), infrRate = tostring(r['infr/100km'] or '-'), crashes = tonumber(r.crashes),
          crRate = tostring(r['cr/100km'] or '-'), cars = {} }
        local lb = full[g] and full[g].leaderboard
        local track = type(lb) == 'table' and (lb[key] or lb[id .. '_']) or nil
        if type(track) == 'table' then
          for car, t in pairs(track) do
            if type(t) == 'table' then e.cars[car] = { laps = tonumber(t.laps) or 0, best = tonumber(t.laptime) or 0 } end
          end
        end
        acc[#acc + 1] = e
      end
      if page < (tonumber(data.pages) or 1) and page < 20 then
        webFetch(page + 1, acc)
      else
        local w = Direction.web
        w.list, w.byName, w.busy, w.err = acc, {}, false, nil
        for _, e in ipairs(acc) do
          w.byName[e.name] = e
          if e.guid ~= '' then Direction.guids[e.name] = e.guid end
        end
        ac.log(string.format('race-control: KMR web stats read: %d drivers', #acc))
      end
    end)
  end
  local function webUpdate()
    local w = Direction.web
    if config.kmrStatsUrl == '' or not web or not web.get or not JSON or w.busy then return end
    if state.ui.clock - w.t < WEB_EVERY then return end
    w.t, w.busy = state.ui.clock, true
    webFetch(1, {})
  end
  local function webLaps(e, carId)
    local laps, best = 0, 0
    if carId and e.cars[carId] then laps, best = e.cars[carId].laps, e.cars[carId].best
    else
      for _, t in pairs(e.cars) do if t.laps > laps then laps, best = t.laps, t.best end end
    end
    return laps, lapTimeText(best)
  end
  local function webLine(e, carId)
    local laps, best = webLaps(e, carId)
    return string.format(TEXTS.dirWebLine, e.money, e.km, e.infr and tostring(e.infr) or '-', e.infrRate,
      e.crashes and tostring(e.crashes) or '-', e.crRate, laps, best)
  end
  Direction.webLine = webLine
  local function driversList(w, h, s, dp1, dp2)
    webUpdate()
    local names, on, onCar = {}, {}, {}
    for i = 0, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and (i == 0 or c.isConnected) then
        local n = tostring(ac.getDriverName(i) or '')
        if n ~= '' and not on[n] then on[n] = true; onCar[n] = c; names[#names + 1] = n end
      end
    end
    local off = {}
    local webList = Direction.web.list
    if webList then
      for _, e in ipairs(webList) do if not on[e.name] then off[#off + 1] = e.name end end
    else
      for _, n in ipairs(seenList()) do if not on[n] then off[#off + 1] = n end end
    end
    table.sort(names)
    table.sort(off)
    local LW, ROWL = 600 * s, 27 * s
    local rows = #names + #off + (#off > 0 and 1 or 0)
    local lh = 30 * s + math.max(rows, 1) * ROWL + 10 * s + (Direction.web.err and 14 * s or 0)
    local x = dp2.x + 8 * s
    if x + LW > w then x = w - LW - 8 * s end
    local p1 = vec2(math.floor(x), math.floor(dp1.y))
    local p2 = vec2(p1.x + LW, math.min(p1.y + lh, h - 4 * s))
    drawPanel(p1, p2, BORDER_BASE, s)
    drawText(TEXTS.dirList, FONT_TITLE, 12 * s, TMP.a:set(p1.x + 12 * s, p1.y + 4 * s), COLOR_TITLE)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Direction.listOpen = false end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local y = p1.y + 26 * s
    ui.pushClipRect(vec2(p1.x, y), vec2(p2.x, p2.y - 4 * s))
    local function row(n, col)
      local a, b = vec2(p1.x + 8 * s, y - 1 * s), vec2(p2.x - 8 * s, y + ROWL - 2 * s)
      if Direction.target == n then ui.drawRectFilled(a, b, rgbm(1, 1, 1, 0.12), 2 * s) end
      drawText(n, FONT_TEXT, 9.5 * s, TMP.a:set(p1.x + 12 * s, y), col)
      drawTextRight(Direction.guids[n] or '-', FONT_MONO, 9 * s, p2.x - 12 * s, y + 1 * s,
        Direction.guids[n] and COLOR_TITLE or COLOR_OFF)
      local we = Direction.web.byName[n]
      local car = onCar[n]
      local extra = car and string.format(TEXTS.dirBalRes, CarRead.num(car.ballast), CarRead.num(car.restrictor)) or nil
      if we then
        drawText((extra and (extra .. '  -  ') or '') .. webLine(we), FONT_MONO, 8 * s, TMP.a:set(p1.x + 12 * s, y + 12 * s), COLOR_DIM)
      elseif extra then
        drawText(extra, FONT_MONO, 8 * s, TMP.a:set(p1.x + 12 * s, y + 12 * s), COLOR_DIM)
      end
      Drag.clickable(a, b, function()
        Direction.target = n
        if not Direction.guids[n] and state.kmrAdmin and not Direction.guidJob then
          Direction.guidJob = { name = n, t = state.ui.clock }
          queueCommand('/kmr driver_get_guid ' .. n)
        end
      end)
      y = y + ROWL
    end
    for _, n in ipairs(names) do row(n, COLOR_TITLE) end
    if #off > 0 then
      drawText(webList and TEXTS.dirWebOthers or TEXTS.dirLeft, FONT_TITLE, 8.5 * s, TMP.a:set(p1.x + 12 * s, y), COLOR_DIM)
      y = y + ROWL
      for _, n in ipairs(off) do row(n, COLOR_DIM) end
    end
    ui.popClipRect()
    if Direction.web.err then
      drawText(string.format(TEXTS.dirWebErr, Direction.web.err), FONT_MONO, 8.5 * s, TMP.a:set(p1.x + 12 * s, p2.y - 16 * s),
        PANEL_COLORS.red)
    elseif config.kmrStatsUrl == '' then
      drawText(TEXTS.dirWebOff, FONT_MONO, 8.5 * s, TMP.a:set(p1.x + 12 * s, p2.y - 16 * s), COLOR_DIM)
    end
  end
  Direction.cmdTab, Direction.cmdScroll = 'rc', 0
  local function commandsList(w, h, s, dp1, dp2)
    local LW, ROWC = 860 * s, 14 * s
    local x = dp1.x - LW - 8 * s
    if x < 4 * s then x = 4 * s end
    local p1 = vec2(math.floor(x), math.floor(dp1.y))
    local p2 = vec2(p1.x + LW, math.floor(math.max(dp2.y, math.min(p1.y + 560 * s, h - 4 * s))))
    drawPanel(p1, p2, BORDER_BASE, s)
    local m = ui.mousePos()
    local over = m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y
    if over then ui.captureMouse(true) end
    drawText(TEXTS.dirCmdTitle, FONT_TITLE, 12 * s, TMP.a:set(p1.x + 12 * s, p1.y + 4 * s), COLOR_TITLE)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Direction.cmdOpen = false end)
    local tx = p1.x + 110 * s
    local group
    for _, g in ipairs(Desktop.commands) do
      if g.key == Direction.cmdTab then group = g end
      tx = chip(g.title, vec2(tx, p1.y + 4 * s), s, g.key == Direction.cmdTab, nil, function()
        Direction.cmdTab, Direction.cmdScroll = g.key, 0
      end)
    end
    group = group or Desktop.commands[1]
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    drawText(TEXTS.dirCmdHow .. group.how, FONT_MONO, 8.5 * s, TMP.a:set(p1.x + 12 * s, p1.y + 25 * s), PANEL_COLORS.yellow)
    local top = p1.y + 42 * s
    local rowsFit = math.max(math.floor((p2.y - 6 * s - top) / ROWC), 1)
    local maxScroll = math.max(#group.rows - rowsFit, 0)
    if over then Direction.cmdScroll = Direction.cmdScroll - math.floor(ui.mouseWheel() * 3) end
    if maxScroll > 0 then
      local ax = chip('^', vec2(p2.x - 64 * s, p1.y + 23 * s), s, false, nil, function() Direction.cmdScroll = Direction.cmdScroll - rowsFit end)
      chip('v', vec2(ax, p1.y + 23 * s), s, false, nil, function() Direction.cmdScroll = Direction.cmdScroll + rowsFit end)
    end
    Direction.cmdScroll = math.min(math.max(Direction.cmdScroll, 0), maxScroll)
    ui.pushClipRect(vec2(p1.x, top), vec2(p2.x, p2.y - 4 * s))
    local y = top
    for i = Direction.cmdScroll + 1, math.min(#group.rows, Direction.cmdScroll + rowsFit) do
      local r = group.rows[i]
      drawText(r[1], FONT_MONO, 9 * s, TMP.a:set(p1.x + 12 * s, y), COLOR_TITLE)
      drawText(r[2], FONT_TEXT, 9 * s, TMP.a:set(p1.x + 380 * s, y), COLOR_DIM)
      y = y + ROWC
    end
    ui.popClipRect()
  end
  local function kmrLine(e, c)
    local k = Audit.kmrOf(e.i) or {}
    local we = Direction.web.byName[tostring(ac.getDriverName(e.i) or '')]
    local function nv(x) return x and Audit.num(x) or nil end
    local rate = function(x) return x and string.format('%.2f', x) or nil end
    local safety = nv(k.rating) or (we and we.money)
    local crashes, crRate = nv(k.crashes), rate(k.crashRate)
    if not crashes and we then crashes, crRate = we.crashes and tostring(we.crashes), we.crRate end
    local infr, infrRate = nv(k.infractions), rate(k.infractionRate)
    if not infr and we then infr, infrRate = we.infr and tostring(we.infr), we.infrRate end
    local crashText = (not crashes and k.noStats) and TEXTS.dirKmrNoStats
      or string.format(TEXTS.dirKmrCrashes, crashes or '-', crRate or '-')
    local kline = TEXTS.dirKmrNone
    if k.points or safety or crashes or infr or k.noStats then
      kline = string.format(TEXTS.dirKmrLine, nv(k.points) or '-', config.kmrPoints.limit, safety or '-', crashText,
        infr or '-', infrRate or '-')
      if we then
        local laps, best = webLaps(we, ac.getCarID and ac.getCarID(e.i) or nil)
        kline = kline .. string.format(TEXTS.dirKmrLaps, laps, best)
      end
    end
    kline = string.format(TEXTS.dirBalRes, CarRead.num(c.ballast), CarRead.num(c.restrictor)) .. '  -  ' .. kline
    return kline
  end
  local function fitLines(text, size, width)
    local out, cur = {}, ''
    for piece in (tostring(text) .. '  -  '):gmatch('(.-)  %-  ') do
      local try = cur == '' and piece or (cur .. '  -  ' .. piece)
      if cur ~= '' and textWidth(try, FONT_MONO, size) > width then out[#out + 1] = cur; cur = piece else cur = try end
    end
    if cur ~= '' or #out == 0 then out[#out + 1] = cur end
    return out
  end
  local function penaltyLine(i, c)
    local items, dsq
    if i == 0 then
      items, dsq = state.list.items, state.list.dsq
    else
      local peer = RecordSync.peers[c.sessionID]
      local rec = peer and peer.penalties and Record.decode(peer.penalties.text)
      if not rec or not Record.sameSession(rec.key, Record.key()) then return TEXTS.dirPenUnknown, COLOR_OFF end
      local d, list = rec.body:match('^%d+|%d+|%-?%d+|%d+|(%d)|%d|%d+|%d+|%d+|(.*)$')
      dsq, items = tonumber(d) or 0, {}
      for cat, kind, laps in (list or ''):gmatch('(%w+),(%w+),(%-?%d+),[^;]*') do
        items[#items + 1] = { cat = cat, kind = kind, laps = tonumber(laps) }
      end
    end
    local parts = {}
    for _, it in ipairs(items) do
      parts[#parts + 1] = it.cat:match('^SG%d+$') and string.format(TEXTS.dirPenSg, sgSeconds(it))
        or string.format(TEXTS.dirPenDt, it.cat, math.max(it.laps or 0, 0))
    end
    if (dsq or 0) > 0 then parts[#parts + 1] = TEXTS.dirPenDsq end
    if #parts == 0 then return TEXTS.dirPenNone, COLOR_DIM end
    return TEXTS.dirPenTitle .. table.concat(parts, '  -  '), (dsq or 0) > 0 and PANEL_COLORS.red or PANEL_COLORS.yellow
  end
  local function mmss(sec)
    sec = math.max(math.floor(sec or 0), 0)
    return string.format('%d:%02d', math.floor(sec / 60), sec % 60)
  end
  local function connLight(c, s, heat)
    local g = heat < 0.5 and 1 or 1 - (heat - 0.5) * 2
    local r = heat < 0.5 and heat * 2 or 1
    local col = rgbm(0.15 + 0.85 * r, 0.85 * g, 0.2 * (1 - heat), 1)
    local pulse = 0.5 + 0.5 * math.sin(2 * math.pi * (0.6 + 1.8 * heat) * state.ui.clock)
    ui.drawCircleFilled(c, 6 * s, rgbm(col.r, col.g, col.b, 0.12 + 0.3 * pulse), 16)
    ui.drawCircleFilled(c, 3.5 * s, rgbm(col.r, col.g, col.b, 0.55 + 0.45 * pulse), 16)
  end
  local WHERE_COLOR = { menu = PANEL_COLORS.red, box = COLOR_DIM, pit = PANEL_COLORS.green, pitlane = PANEL_COLORS.yellow,
    grid = COLOR_TITLE, stopped = PANEL_COLORS.red, track = COLOR_TITLE }
  local function dataCells(i, c)
    local lvl, avg, dev, stalled = Connection.level(i)
    local ping = CarRead.num(c.ping)
    local conn = stalled and TEXTS.connStalled
      or lvl == 'bad' and string.format(TEXTS.connKick, avg or 0, dev or 0)
      or lvl == 'warn' and TEXTS.connHigh or TEXTS.connOk
    local col = lvl == 'bad' and PANEL_COLORS.red or lvl == 'warn' and PANEL_COLORS.yellow or COLOR_DIM
    return {
      { 'P' .. tostring(CarRead.num(c.racePosition)), COLOR_TITLE },
      { TEXTS.connLap .. lapTimeText(c.lapTimeMs), COLOR_DIM },
      { string.format(TEXTS.connSector, CarRead.num(c.currentSector) + 1), COLOR_DIM },
      { string.format(TEXTS.connSpline, CarRead.num(c.splinePosition)), COLOR_DIM },
      { TEXTS.where[Connection.where(i, c)], WHERE_COLOR[Connection.where(i, c)] },
      { ping > 0 and string.format(TEXTS.connPing, ping) or TEXTS.connPingNone, ping > Connection.PING_WARN and col or COLOR_DIM },
      { conn, col },
    }, lvl
  end
  local function swapLine(i, c)
    local e = Connection.cars[i]
    if not e then return nil end
    local now, min = state.ui.clock, config.swapMinSeconds
    local parts, col = {}, COLOR_DIM
    if c and c.isConnected and e.parked and e.parkedT and not e.leftT then
      parts[#parts + 1] = string.format(TEXTS.connStopped, mmss(now - e.parkedT))
      col = PANEL_COLORS.green
    end
    if e.leftT then
      parts[#parts + 1] = e.leftAfterStop and string.format(TEXTS.connOutAfter, mmss(e.leftAfterStop)) or TEXTS.connOutNoStop
      parts[#parts + 1] = TEXTS.connCause[e.leftCause] or e.leftCause
      if e.inT then
        local took = e.inT - e.leftT
        parts[#parts + 1] = string.format(e.sameDriver and TEXTS.connBackSame or TEXTS.connBackOther, mmss(took), mmss(min))
        parts[#parts + 1] = took <= min and TEXTS.connInTime or TEXTS.connLate
        col = took <= min and PANEL_COLORS.green or PANEL_COLORS.yellow
      else
        parts[#parts + 1] = string.format(TEXTS.connSwapTime, mmss(now - e.leftT), mmss(min))
        col = (e.leftCause == 'menu' or e.leftCause == 'lost' or e.leftCause:match('^ping')) and PANEL_COLORS.red
          or (now - e.leftT > min and PANEL_COLORS.yellow or PANEL_COLORS.green)
      end
    end
    if #parts == 0 then return nil end
    return TEXTS.connPitTitle .. table.concat(parts, '  -  '), col
  end
  local function resetDirection()
    Direction.pwd, Direction.prompt, Direction.target, Direction.value = '', '', '', ''
    Direction.status, Direction.statusColor, Direction.focus, Direction.guidJob = nil, nil, nil, nil
    Direction.listOpen, Direction.cmdOpen, Direction.waitLogin, Direction.probe = false, false, false, nil
    Direction.cmdTab, Direction.cmdScroll = 'rc', 0
    Direction.web.t, Direction.web.err = -1e9, nil
    KmrEvents.open = false
    armKey, redArm = nil, 0
    ac.storage['rc.win.redflag'], ac.storage['rc.winsz.redflag'] = '', ''
    probeKmr()
    Direction.status, Direction.statusT, Direction.statusColor = TEXTS.dirReset, state.ui.clock, COLOR_TITLE
    ac.log('race-control: race direction window reset')
  end
  local function redWindow(w, h, s)
    if not Direction.openSeen or Direction.session ~= sim.currentSessionIndex
        or state.ui.clock - (Direction.probeT or -1e9) >= PROBE_EVERY then
      Direction.openSeen, Direction.session = true, sim.currentSessionIndex
      probeKmr()
      Direction.probeT = state.ui.clock
    end
    if Direction.probe and state.ui.clock - Direction.probe.t > PROBE_WAIT then
      Direction.probe = nil
      state.kmrAdmin = false
      Direction.status, Direction.statusT, Direction.statusColor = TEXTS.dirKmrLost, state.ui.clock, PANEL_COLORS.red
      ac.log('race-control: race direction: KMR login not answered - fell')
    end
    local cars = {}
    for i = 0, (sim.carsCount or 1) - 1 do
      local c = ac.getCar(i)
      if c and c.isConnected and not CarRead.isStaff(i) then cars[#cars + 1] = { i = i, c = c } end
    end
    local cmd = config.canCommand
    if Direction.guidJob and state.ui.clock - Direction.guidJob.t > 6 then
      Direction.status, Direction.statusColor = string.format(TEXTS.dirGuidNone, Direction.guidJob.name), PANEL_COLORS.red
      Direction.statusT, Direction.guidJob = state.ui.clock, nil
    end
    local gone = Connection.gone()
    local cells, alerts = {}, {}
    for _, e in ipairs(cars) do
      local list, lvl = dataCells(e.i, e.c)
      cells[e.i] = list
      if lvl == 'bad' then alerts[#alerts + 1] = string.format(TEXTS.connAlertCar, tostring(ac.getDriverNumber(e.i) or e.i),
        tostring(ac.getDriverName(e.i) or ''), list[6][1]) end
    end
    local colW = {}
    for _, list in pairs(cells) do
      for k, cell in ipairs(list) do colW[k] = math.max(colW[k] or 0, textWidth(cell[1], FONT_MONO, 8.5 * s)) end
    end
    local W5, H5 = cmd and 940 or 560, 30 + (cmd and 22 or 16) + (cmd and (22 + 22 + 22 + 22) or 0) + 18 + 16 + #cars * 56 + 22
    H5 = H5 + (#alerts > 0 and 14 or 0) + (#gone > 0 and (16 + #gone * 30) or 0)
    for _, e in ipairs(cars) do
      local n = #fitLines((penaltyLine(e.i, e.c)), 8.5 * s, (W5 - 74) * s) + #fitLines(kmrLine(e, e.c), 8.5 * s, (W5 - 74) * s)
      H5 = H5 + math.max(n - 2, 0) * 12 + (swapLine(e.i, e.c) and 12 or 0)
    end
    local p1, p2 = windowAt('redflag', W5, H5, w, h, s, true)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    if m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y then ui.captureMouse(true) end
    drawPanel(p1, p2, state.redFlag and BORDER_RED or BORDER_BASE, s)
    drawText(TEXTS.dirTitle, FONT_TITLE, 12 * s, TMP.a:set(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    drawText(TEXTS.dirRole[config.role] or '', FONT_MONO, 10 * s, TMP.a:set(p1.x + 170 * s, p1.y + 5 * s), COLOR_DIM)
    local flagText = state.redFlag and TEXTS.flagRed or TEXTS.redNone
    drawTextRight(flagText, FONT_MONO, 10 * s, p2.x - 40 * s, p1.y + 5 * s, state.redFlag and PANEL_COLORS.red or COLOR_DIM)
    chip(TEXTS.dirResetBtn, vec2(p2.x - 40 * s - textWidth(flagText, FONT_MONO, 10 * s) - textWidth(TEXTS.dirResetBtn, FONT_MONO, 9 * s) - 24 * s,
      p1.y + 4 * s), s, false, nil, resetDirection)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Desktop.redOpen = false end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local y = p1.y + 28 * s
    local x0 = p1.x + 14 * s
    drawText(sessionLine(), FONT_MONO, 10 * s, TMP.a:set(x0, y), COLOR_TITLE)
    local cbx = p2.x - 14 * s - textWidth(TEXTS.dirCmdBtn, FONT_MONO, 9 * s) - 10 * s
    chip(TEXTS.dirCmdBtn, vec2(cbx, y - 1 * s), s, Direction.cmdOpen, nil, function() Direction.cmdOpen = not Direction.cmdOpen end)
    chip(TEXTS.kmrEvBtn, vec2(cbx - textWidth(TEXTS.kmrEvBtn, FONT_MONO, 9 * s) - 20 * s, y - 1 * s), s, KmrEvents.open, nil,
      function() KmrEvents.open = not KmrEvents.open end)
    y = y + (cmd and 22 or 16) * s
    if cmd then
      if state.kmrAdmin then
        rowLabel(TEXTS.redKmrOn, FONT_MONO, 9.5 * s, x0, y, s, PANEL_COLORS.green)
        chip(TEXTS.dirLogout, vec2(x0 + textWidth(TEXTS.redKmrOn, FONT_MONO, 9.5 * s) + 10 * s, y - 1 * s), s, false, PANEL_COLORS.red, function()
          state.kmrAdmin, Direction.probe = false, nil
          Direction.status, Direction.statusT, Direction.statusColor = TEXTS.dirLoggedOut, state.ui.clock, COLOR_TITLE
          ac.log('race-control: race direction: KMR login no longer used (logout on this screen)')
        end)
      else
        rowLabel(TEXTS.dirLogin, FONT_TEXT, 10 * s, x0, y, s, COLOR_TITLE)
        local enter
        Direction.pwd, enter = ownField('pwd', vec2(x0 + 110 * s, y - 1 * s), vec2(x0 + 270 * s, y + 13 * s),
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
      do
        local px = x0 + 340 * s
        rowLabel(TEXTS.dirPrompt, FONT_TEXT, 10 * s, px, y, s, COLOR_TITLE)
        local fx = px + textWidth(TEXTS.dirPrompt, FONT_TEXT, 10 * s) + 8 * s
        local enter
        Direction.prompt, enter = ownField('prompt', vec2(fx, y - 1 * s), vec2(p2.x - 14 * s, y + 13 * s),
          Direction.prompt or '', false, s)
        if enter and (Direction.prompt or ''):match('%S') then
          queueCommand(Direction.prompt)
          local shown = Direction.prompt:lower():find('login', 1, true) and (Direction.prompt:match('^(.-login)') .. ' ***') or Direction.prompt
          ac.log('race-control: race direction: prompt sent: ' .. shown)
          Direction.status, Direction.statusT, Direction.statusColor = string.format(TEXTS.dirPromptSent, shown),
            state.ui.clock, PANEL_COLORS.yellow
          Direction.prompt = ''
        end
      end
      if Direction.waitLogin and state.ui.clock - Direction.statusT >= 5 then
        Direction.waitLogin = false
        Direction.status, Direction.statusColor = TEXTS.dirNoAnswer, PANEL_COLORS.red
      end
      y = y + 22 * s
      rowLabel(TEXTS.dirDriver, FONT_TEXT, 10 * s, x0, y, s, COLOR_TITLE)
      Direction.target = ownField('name', vec2(x0 + 110 * s, y - 1 * s), vec2(x0 + 330 * s, y + 13 * s), Direction.target,
        false, s)
      local tx = x0 + 340 * s
      tx = confirmChip(TEXTS.dirMoney, 'tmoney', vec2(tx, y - 1 * s), s, nil, function()
        releaseDriver('driver_reset_money', Direction.target, TEXTS.dirAct.money) end)
      tx = confirmChip(TEXTS.dirStats, 'tstats', vec2(tx, y - 1 * s), s, nil, function()
        releaseDriver('driver_reset_driving_stats', Direction.target, TEXTS.dirAct.stats) end)
      tx = confirmChip(TEXTS.dirBan, 'tban', vec2(tx, y - 1 * s), s, PANEL_COLORS.red, function()
        releaseDriver('player_temporary_ban_guid', Direction.target, TEXTS.dirAct.ban, '|' .. BAN_MINUTES) end)
      tx = confirmChip(TEXTS.dirUnban, 'tunban', vec2(tx, y - 1 * s), s, nil, function()
        releaseDriver('player_unban', Direction.target, TEXTS.dirAct.unban) end)
      tx = chip(TEXTS.dirListBtn, vec2(tx, y - 1 * s), s, Direction.listOpen, nil, function()
        Direction.listOpen = not Direction.listOpen
        if Direction.listOpen and state.kmrAdmin then queueCommand('/kmr player_list') end
      end)
      local vx = tx + 10 * s
      rowLabel(TEXTS.dirValue, FONT_TEXT, 10 * s, vx, y, s, COLOR_TITLE)
      Direction.value = (ownField('value', vec2(vx + 40 * s, y - 1 * s), vec2(vx + 90 * s, y + 13 * s),
        Direction.value or '', false, s):gsub('%D', ''))
      local function acsm(cmd, label)
        local slot
        for i = 0, (sim.carsCount or 1) - 1 do
          local c = ac.getCar(i)
          if c and (i == 0 or c.isConnected) and tostring(ac.getDriverName(i) or '') == Direction.target then
            slot = tostring(c.sessionID or i)
          end
        end
        if not slot or Direction.value == '' then
          Direction.status, Direction.statusT, Direction.statusColor = TEXTS.dirNeedCarValue, state.ui.clock, PANEL_COLORS.red
          return
        end
        sendKmr('admin_send_command /' .. cmd .. ' ' .. slot .. ' ' .. Direction.value,
          string.format('%s %s %s', label, Direction.value, Direction.target))
      end
      vx = confirmChip(TEXTS.dirBallast, 'ballast', vec2(vx + 96 * s, y - 1 * s), s, nil, function() acsm('ballast', TEXTS.dirAct.ballast) end)
      confirmChip(TEXTS.dirRestrictor, 'restrictor', vec2(vx, y - 1 * s), s, nil, function() acsm('restrictor', TEXTS.dirAct.restrictor) end)
      y = y + 22 * s
      local x = confirmChip(TEXTS.flagRed, 'red', vec2(x0, y), s, PANEL_COLORS.red, function()
        sendKmr('admin_say RC REDFLAG ALL', TEXTS.flagRed)
      end)
      local red = state.redFlag ~= nil
      for _, sec in ipairs({ 60, 120, 180 }) do
        x = chip(string.format(red and TEXTS.redVsc or TEXTS.dirVsc, sec), vec2(x, y), s, false, nil, function()
          sendKmr('virtual_safety_car_deploy ' .. sec, string.format(TEXTS.dirVsc, sec))
          if state.redFlag then queueCommand('/kmr admin_say RC REDFLAG OFF ALL') end
        end)
      end
      x = chip(TEXTS.redGreen, vec2(x, y), s, false, (red or state.code80 or state.postRed) and PANEL_COLORS.green or COLOR_OFF, function()
        if state.redFlag or state.code80 or state.postRed then
          if state.code80 then queueCommand('/kmr virtual_safety_car_deploy 1') end
          sendKmr('admin_say RC GREEN ALL', TEXTS.redGreen)
        else
          Direction.status, Direction.statusT, Direction.statusColor = TEXTS.dirNoRed, state.ui.clock, PANEL_COLORS.yellow
        end
      end)
      if Flags.formation and Flags.formation.phase == 'end' and not state.restart then
        x = confirmChip(TEXTS.dirStart, 'start', vec2(x, y), s, PANEL_COLORS.green, function()
          sendKmr(string.format('admin_say RC START ALL @%d', math.ceil(serverTimeMs() / 1000) * 1000 + 2000), TEXTS.dirStart)
        end)
      end
      if red then
        confirmChip(TEXTS.dirStanding, 'standing', vec2(x, y), s, PANEL_COLORS.yellow, function()
          sendKmr(string.format('admin_say RC RESTART ALL @%d', math.ceil(serverTimeMs() / 1000) * 1000 + 2000),
            TEXTS.dirStanding)
        end)
      elseif state.restart then
        confirmChip(TEXTS.dirStandingOff, 'standingOff', vec2(x, y), s, PANEL_COLORS.red, function()
          sendKmr('admin_say RC RESTART OFF ALL', TEXTS.dirStandingOff)
        end)
      end
      y = y + 22 * s
      x = confirmChip(TEXTS.dirNextSession, 'next', vec2(x0, y), s, nil, function() sendKmr('admin_next_session', TEXTS.dirNextSession) end)
      x = confirmChip(TEXTS.dirRestart, 'restart', vec2(x, y), s, nil, function() sendKmr('admin_restart_session', TEXTS.dirRestart) end)
      x = x + 10 * s
      for _, lt in ipairs({ { 'RED', TEXTS.dirLightsRed, PANEL_COLORS.red }, { 'GREEN', TEXTS.dirLightsGreen, PANEL_COLORS.green },
          { 'AUTO', TEXTS.dirLightsAuto, nil } }) do
        local on = (state.lights or 'AUTO') == lt[1]
        x = chip(lt[2], vec2(x, y), s, on, on and lt[3] or nil, function()
          sendKmr('admin_say RC LIGHTS ' .. lt[1] .. ' ALL', lt[2])
        end)
      end
      y = y + 22 * s
    end
    local status = Direction.status or (cmd and not state.kmrAdmin and TEXTS.redKmrOff or '')
    local maxW = p2.x - x0 - 14 * s
    status = fitText(status, FONT_MONO, 9 * s, maxW)
    drawText(status, FONT_MONO, 9 * s, TMP.a:set(x0, y), Direction.statusColor or PANEL_COLORS.yellow)
    y = y + 18 * s
    if #alerts > 0 then
      local text = fitText(TEXTS.connAlert .. table.concat(alerts, '  -  '), FONT_MONO, 9 * s, maxW, '')
      drawText(text, FONT_MONO, 9 * s, TMP.a:set(x0, y), PANEL_COLORS.red)
      y = y + 14 * s
    end
    local inPits, over = 0, 0
    for _, e in ipairs(cars) do
      local c = e.c
      local where = c.isInPit and TEXTS.redPlace or (c.isInPitlane and TEXTS.redLane or TEXTS.redTrack)
      local kmh = CarRead.num(c.speedKmh)
      if c.isInPitlane then inPits = inPits + 1 end
      local fast = not c.isInPitlane and kmh > config.flags.redSpeedKmh
      if fast then over = over + 1 end
      drawText('#' .. tostring(ac.getDriverNumber(e.i) or e.i), FONT_MONO, 9.5 * s, TMP.a:set(x0, y), COLOR_TITLE)
      connLight(vec2(p1.x + 50 * s, y + 6.5 * s), s, Connection.heat(e.i))
      local carName = tostring(ac.getDriverName(e.i) or '')
      drawText(carName, FONT_TEXT, 9.5 * s, TMP.a:set(p1.x + 60 * s, y), Direction.target == carName and PANEL_COLORS.yellow or COLOR_TITLE)
      if cmd then Drag.clickable(vec2(x0, y - 1 * s), vec2(p1.x + 205 * s, y + 13 * s), function() Direction.target = carName end) end
      drawText(where, FONT_MONO, 9.5 * s, TMP.a:set(p1.x + 210 * s, y),
        c.isInPit and PANEL_COLORS.green or (c.isInPitlane and PANEL_COLORS.yellow or PANEL_COLORS.red))
      drawTextRight(string.format('%.0f', kmh), FONT_MONO, 9.5 * s, p1.x + 300 * s, y, fast and PANEL_COLORS.red or COLOR_TITLE)
      if cmd then
        local slot = tostring(c.sessionID or e.i)
        local name = tostring(ac.getDriverName(e.i) or slot)
        local ax = p1.x + 312 * s
        ax = confirmChip(TEXTS.dirChip.dt, 'dt' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('player_give_drive_through ' .. slot .. '|1', string.format(TEXTS.dirAct.dt, name)) end)
        ax = confirmChip(TEXTS.dirCancelDt, 'cdt' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('player_cancel_drive_through ' .. slot, string.format(TEXTS.dirAct.cancelDt, name)) end)
        ax = confirmChip(TEXTS.dirNoSg, 'nosg' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('admin_say RC RELAX ' .. slot .. ' SG', string.format(TEXTS.dirAct.relaxSg, name)) end)
        ax = confirmChip(TEXTS.dirChip.kick, 'kick' .. slot, vec2(ax, y - 1 * s), s, PANEL_COLORS.red, function()
          sendKmr('player_kick ' .. slot, string.format(TEXTS.dirAct.kick, name)) end)
        ax = confirmChip(TEXTS.dirChip.ban60, 'ban' .. slot, vec2(ax, y - 1 * s), s, PANEL_COLORS.red, function()
          sendKmr('player_temporary_ban ' .. slot .. '|60', string.format(TEXTS.dirAct.ban60, name)) end)
        ax = confirmChip(TEXTS.dirToPit, 'pit' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('admin_say RC TELEPORT ' .. slot, string.format(TEXTS.dirAct.toPit, name)) end)
        ax = confirmChip(TEXTS.dirChip.dsq, 'dsq' .. slot, vec2(ax, y - 1 * s), s, PANEL_COLORS.red, function()
          sendKmr('admin_say RC DSQ ' .. slot, string.format(TEXTS.dirAct.dsq, name)) end)
        ax = confirmChip(TEXTS.dirNoDsq, 'nodsq' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('admin_say RC RELAX ' .. slot .. ' DSQ', string.format(TEXTS.dirAct.relaxDsq, name)) end)
        ax = confirmChip(TEXTS.dirFuel, 'fuel' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('admin_say RC FUEL ' .. slot, string.format(TEXTS.dirAct.fuel, name)) end)
        ax = confirmChip(TEXTS.dirMenu, 'menu' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          sendKmr('admin_say RC MENU ' .. slot, string.format(TEXTS.dirAct.menu, name)) end)
        ax = confirmChip(TEXTS.dirMoney, 'money' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          releaseDriver('driver_reset_money', name, TEXTS.dirAct.money) end)
        confirmChip(TEXTS.dirStats, 'stats' .. slot, vec2(ax, y - 1 * s), s, nil, function()
          releaseDriver('driver_reset_driving_stats', name, TEXTS.dirAct.stats) end)
      end
      local kline = kmrLine(e, c)
      local pen, penColor = penaltyLine(e.i, c)
      local lw = p2.x - p1.x - 74 * s
      local ly = y + 16 * s
      local cx = p1.x + 60 * s
      for k, cell in ipairs(cells[e.i] or {}) do
        drawText(cell[1], FONT_MONO, 8.5 * s, TMP.a:set(cx, ly), cell[2])
        cx = cx + (colW[k] or 0) + 14 * s
      end
      ly = ly + 12 * s
      local sl, slColor = swapLine(e.i, c)
      if sl then drawText(sl, FONT_MONO, 8.5 * s, TMP.a:set(p1.x + 60 * s, ly), slColor); ly = ly + 12 * s end
      for _, t in ipairs(fitLines(pen, 8.5 * s, lw)) do drawText(t, FONT_MONO, 8.5 * s, TMP.a:set(p1.x + 60 * s, ly), penColor); ly = ly + 12 * s end
      for _, t in ipairs(fitLines(kline, 8.5 * s, lw)) do drawText(t, FONT_MONO, 8.5 * s, TMP.a:set(p1.x + 60 * s, ly), COLOR_DIM); ly = ly + 12 * s end
      y = math.max(y + 44 * s, ly + 4 * s)
    end
    if #gone > 0 then
      drawText(TEXTS.connGoneTitle, FONT_TITLE, 8.5 * s, TMP.a:set(x0, y), COLOR_DIM)
      y = y + 16 * s
      for _, g in ipairs(gone) do
        drawText('#' .. tostring(ac.getDriverNumber(g.i) or g.i), FONT_MONO, 9.5 * s, TMP.a:set(x0, y), COLOR_DIM)
        drawText(g.e.name, FONT_TEXT, 9.5 * s, TMP.a:set(p1.x + 60 * s, y), COLOR_DIM)
        drawText(TEXTS.connLeft, FONT_MONO, 9.5 * s, TMP.a:set(p1.x + 210 * s, y), PANEL_COLORS.red)
        local sl, slColor = swapLine(g.i, nil)
        if sl then drawText(sl, FONT_MONO, 8.5 * s, TMP.a:set(p1.x + 60 * s, y + 14 * s), slColor) end
        y = y + 30 * s
      end
    end
    drawText(string.format(TEXTS.redCount, inPits, #cars, over), FONT_MONO, 9 * s, TMP.a:set(x0, y + 2 * s), COLOR_DIM)
    if cmd and Direction.listOpen then driversList(w, h, s, p1, p2) end
    if Direction.cmdOpen then commandsList(w, h, s, p1, p2) end
    if KmrEvents.open then KmrEvents.draw(w, h, s, p1, p2, chip) end
    webUpdate()
  end
  local LOBBY_W, EVENT_W = 380, 380
  local function lobbyAt(p1, s)
    local me = RaceTable.byIndex[0]
    local LW = LOBBY_W * s
    local msgs = {}
    for i = #Audit.items, 1, -1 do
      local it = Audit.items[i]
      if it.area == nil or it.area == 'rc' or Audit.allow(it.area) then msgs[#msgs + 1] = it end
      if #msgs >= 8 then break end
    end
    local Rr, Nm = RecordSync.base.rr, RecordSync.base.name
    local room, level = RecordSync.base.rrRoom()
    local LEVEL = { ok = PANEL_COLORS.green, warn = PANEL_COLORS.yellow, bad = PANEL_COLORS.red }
    local baseOff = Rr.state == 'offline' or Nm.offline
    local rcRows = {
      { TEXTS.lobbyAccount, tostring(ac.getDriverName(0) or '') .. ' - ' .. tostring(ac.getUserSteamID() or ''), COLOR_TITLE },
      { TEXTS.lobbyRegistration, not config.realName and TEXTS.lobbyOff or Nm.status == 'ok' and TEXTS.lobbyOk
        or Nm.status == 'missing' and string.format(TEXTS.lobbyMissing, Nm.missing or '') or '-',
        Nm.status == 'missing' and PANEL_COLORS.red or Nm.status == 'ok' and PANEL_COLORS.green or COLOR_DIM },
      { TEXTS.lobbyBase, config.baseUrl == '' and TEXTS.lobbyOff or baseOff and TEXTS.lobbyOffline or TEXTS.lobbyOnline,
        config.baseUrl == '' and COLOR_DIM or baseOff and PANEL_COLORS.red or PANEL_COLORS.green },
      { TEXTS.lobbyApp, AppLink.alive and TEXTS.lobbyRunning or TEXTS.lobbyNotRunning, AppLink.alive and PANEL_COLORS.green or PANEL_COLORS.red },
      { TEXTS.lobbyRoom, room, LEVEL[level] or COLOR_DIM },
      { TEXTS.lobbyShare, Rr.game and TEXTS.lobbyShared or TEXTS.lobbyNotShared, Rr.game and PANEL_COLORS.green or COLOR_DIM },
    }
    local p2 = vec2(p1.x + LW, p1.y + (30 + 8 * 13 + 22 + 22 + #rcRows * 13 + math.max(#msgs, 1) * 24 + 8) * s)
    Drag.group = nil
    drawPanel(p1, p2, BORDER_BLUE, s)
    drawText(config.eventName ~= '' and Lang.letters.upper(config.eventName) or TEXTS.lobbyTitle, FONT_TITLE, 12 * s,
      TMP.a:set(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    local when = ''
    local stamp = tonumber(sim.timestamp)
    if stamp and stamp > 0 then
      local okD, d = pcall(os.dateGlobal or function(f, t) return os.date('!' .. f, t) end, '%d/%m/%Y %H:%M', stamp)
      if okD and d then when = '  ' .. d end
    end
    drawTextRight((TEXTS.sessionName[sim.raceSessionType] or '') .. when, FONT_MONO, 10 * s, p2.x - 14 * s, p1.y + 5 * s, COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local y = p1.y + 27 * s
    local pen = Panel.cellPenalties()
    local rows = {
      { TEXTS.scrPosition, me and ('P' .. me.pos .. (me.class and string.format(TEXTS.posClassFmt, me.classPos, me.class) or '')) or '-' },
      { TEXTS.lobbyStops, string.format('%d / %d', PitRecord.stops, config.pitStopsRequired) },
      { TEXTS.scrPending, pen and pen.value or '-' },
      { TEXTS.lobbyKmr, string.format('%s / %d - %s', Audit.points and tostring(Audit.points) or '-', config.kmrPoints.limit,
        Audit.rating and Audit.num(Audit.rating) or '-') },
      { TEXTS.scrKmrCrashes, Audit.per100(Audit.crashes, Audit.crashRate) },
      { TEXTS.scrKmrInfr, Audit.per100(Audit.infractions, Audit.infractionRate) },
      { TEXTS.scrKmrKm, Audit.km and string.format('%.1f km', Audit.km) or '-' },
      { TEXTS.lobbyWeather, string.format('%.0f / %.0f C', CarRead.num(sim.ambientTemperature), CarRead.num(sim.roadTemperature)) },
    }
    for _, r in ipairs(rows) do
      drawText(r[1], FONT_TEXT, 10 * s, TMP.a:set(p1.x + 14 * s, y), COLOR_DIM)
      drawTextRight(r[2], FONT_MONO, 10 * s, p2.x - 14 * s, y, r[2] == '-' and COLOR_OFF or COLOR_TITLE)
      y = y + 13 * s
    end
    drawSeparator(p1, p2, y + 3 * s, s)
    y = y + 8 * s
    drawText(TEXTS.lobbyRc, FONT_TITLE, 10 * s, TMP.a:set(p1.x + 14 * s, y), COLOR_DIM)
    y = y + 14 * s
    for _, r in ipairs(rcRows) do
      drawText(r[1], FONT_TEXT, 10 * s, TMP.a:set(p1.x + 14 * s, y), COLOR_DIM)
      drawTextRight(r[2], FONT_MONO, 10 * s, p2.x - 14 * s, y, r[3])
      y = y + 13 * s
    end
    drawSeparator(p1, p2, y + 3 * s, s)
    y = y + 8 * s
    drawText(TEXTS.lobbyMessages, FONT_TITLE, 10 * s, TMP.a:set(p1.x + 14 * s, y), COLOR_DIM)
    y = y + 14 * s
    if #msgs == 0 then drawText(TEXTS.auditEmpty, FONT_MONO, 9 * s, TMP.a:set(p1.x + 14 * s, y), COLOR_OFF) end
    for _, it in ipairs(msgs) do
      drawText(it.src, FONT_TITLE, 9 * s, TMP.a:set(p1.x + 14 * s, y), SRC_COLOR[it.src] or COLOR_TITLE)
      ui.pushDWriteFont(FONT_TEXT)
      ui.setCursor(vec2(p1.x + 60 * s, y))
      ui.dwriteTextAligned(it.text, 9 * s, ui.Alignment.Start, ui.Alignment.Start, vec2(LW - 74 * s, 22 * s), true, COLOR_TITLE)
      ui.popDWriteFont()
      y = y + 24 * s
    end
  end
  local function lobbyStack(right, top, s)
    local bottom = Desktop.eventBox and Desktop.eventBox(vec2(right, top), s, true) or top
    lobbyAt(vec2(math.floor(right - LOBBY_W * s), math.floor((bottom or top) + 8 * s)), s)
  end
  local chatRight, chatT, chatLogged = nil, -1e9, nil
  local function chatEdge()
    if state.ui.clock - chatT < 1 then return chatRight end
    chatT, chatRight = state.ui.clock, nil
    if not ac.getAppWindows or not ac.accessAppWindow then return nil end
    if Desktop.windowsLogged ~= sim.isInMainMenu and sim.isInMainMenu then
      local size = ac.getUI().windowSize
      ac.log(string.format('race-control: lobby, screen %.0f x %.0f, app windows:', size.x, size.y))
      for _, w in ipairs(ac.getAppWindows() or {}) do
        local ok, acc = pcall(ac.accessAppWindow, w.name)
        if ok and acc and acc:valid() then
          local pos, sz = acc:position(), acc:size()
          ac.log(string.format('race-control: window %s | %s | visible %s | x %.0f y %.0f | w %.0f h %.0f',
            tostring(w.name), tostring(w.title), tostring(acc:visible()), pos.x, pos.y, sz.x, sz.y))
        else
          ac.log(string.format('race-control: window %s | %s | no access', tostring(w.name), tostring(w.title)))
        end
      end
    end
    Desktop.windowsLogged = sim.isInMainMenu
    for _, w in ipairs(ac.getAppWindows() or {}) do
      local tag = (tostring(w.name) .. ' ' .. tostring(w.title)):lower()
      if tag:find('chat', 1, true) then
        local ok, acc = pcall(ac.accessAppWindow, w.name)
        if ok and acc and acc:valid() and acc:visible() then
          local pos, size = acc:position(), acc:size()
          local right = pos.x + size.x
          if not chatRight or right > chatRight then chatRight = right end
          if chatLogged ~= w.name then
            chatLogged = w.name
            ac.log(string.format('race-control: lobby next to the chat window %s (right edge %.0f px)', tostring(w.name), right))
          end
        end
      end
    end
    return chatRight
  end
  local LOBBY_POS_KEY = 'rc.lobbyPos'
  local lobbyFrac, lobbyGrab = nil, nil
  do
    local fx, fy = tostring(ac.storage[LOBBY_POS_KEY] or ''):match('^([%d%.]+),([%d%.]+)$')
    if fx then lobbyFrac = vec2(tonumber(fx), tonumber(fy)) end
  end
  local function lobby(w, h, s)
    chatEdge()
    local frac = lobbyFrac or (config.lobbyPos.x >= 0 and config.lobbyPos.y >= 0 and vec2(config.lobbyPos.x, config.lobbyPos.y))
    local right, top = math.floor(w - 24 * s), math.floor(h * 0.12)
    if frac then right, top = math.floor(frac.x * w + LOBBY_W * s), math.floor(frac.y * h) end
    local bottom = Desktop.eventBox and Desktop.eventBox(vec2(right, top), s, true) or top
    lobbyAt(vec2(math.floor(right - LOBBY_W * s), math.floor((bottom or top) + 8 * s)), s)
    local m = ui.mousePos()
    local a, b = vec2(right - LOBBY_W * s, top), vec2(right, bottom or top)
    if lobbyGrab then
      ui.setMouseCursor(ui.MouseCursor.ResizeAll)
      local nx = math.min(math.max(m.x - lobbyGrab.x, 0), w - LOBBY_W * s)
      local ny = math.min(math.max(m.y - lobbyGrab.y, 0), h - 40 * s)
      lobbyFrac = vec2(nx / w, ny / h)
      if not ui.mouseDown() then
        lobbyGrab = nil
        ac.storage[LOBBY_POS_KEY] = string.format('%.4f,%.4f', lobbyFrac.x, lobbyFrac.y)
        ac.log(string.format('race-control: lobby moved, server key: lobbyPos = x:%.4f|y:%.4f', lobbyFrac.x, lobbyFrac.y))
      end
    elseif m.x >= a.x and m.x <= b.x and m.y >= a.y and m.y <= b.y then
      ui.setMouseCursor(ui.MouseCursor.ResizeAll)
      if ui.mouseDoubleClicked() then
        lobbyFrac = nil
        ac.storage[LOBBY_POS_KEY] = ''
        ac.log('race-control: lobby back to the default place')
      elseif ui.mouseClicked() then
        lobbyGrab = vec2(m.x - a.x, m.y - a.y)
      end
    end
  end
  local lobbyWin, lobbyOpen, lobbyHud = nil, false, false
  Desktop.lobbyUpdate = function()
    if config.canCommand then
      for i = 0, (sim.carsCount or 1) - 1 do
        local c = ac.getCar(i)
        if c and (i == 0 or c.isConnected) then seenAdd(tostring(ac.getDriverName(i) or '')) end
      end
    end
    if not lobbyHud and ui.onExclusiveHUD then
      lobbyHud = true
      ui.onExclusiveHUD(function(mode)
        if not ServerGuard.ok() then return end
        Connection.hudMode = mode
        if mode == 'menu' then
          local size = ac.getUI().windowSize
          local sm = math.min(math.max((size.y / 1080) ^ 0.3, 1), 1.3)
          Desktop.text.minPx = Desktop.text.min * sm
          lobby(size.x, size.y, sm)
          return
        end
        local free = state.menuFreeUntil and state.ui.clock < state.menuFreeUntil
        if mode ~= 'game' or config.gameHud == 'show' or free then return end
        script.drawUI(true)
        Desktop.hudDrawn = true
        return config.gameHud == 'hideall' and true or 'apps'
      end)
      ac.log('race-control: lobby drawn in the pits menu (exclusive HUD, menu mode); game UI ' .. config.gameHud)
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
  local CONTROLS_W = 196
  local function messageWindow(w, h, s)
    local mh, gapW = 56 * s, 6 * s
    Drag.panelExtra = mh + gapW
    local msg = Audit.current()
    local controls = controlsShown()
    if not msg and not controls then return end
    local pr = Drag.lastRects.panel
    local o = Drag.offset('panel', h)
    local rw = pr and (pr.max.x - pr.min.x) or PANEL_WIDTH * s
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
    drawText(TEXTS.msgTitle, FONT_TITLE, 10 * s, TMP.a:set(p1.x + 14 * s, p1.y + 4 * s), COLOR_TITLE)
    drawTextRight(msg.src, FONT_MONO, 9 * s, p2.x - 14 * s, p1.y + 5 * s, SRC_COLOR[msg.src] or COLOR_DIM)
    ui.pushDWriteFont(FONT_TEXT)
    ui.setCursor(vec2(p1.x + 14 * s, p1.y + 17 * s))
    ui.dwriteTextAligned(msg.text, 10 * s, ui.Alignment.Start, ui.Alignment.Start, vec2(p2.x - p1.x - 26 * s, 36 * s), true,
      COLOR_TITLE)
    ui.popDWriteFont()
  end
  local function carMenu(w, h, s)
    local cm = Desktop.carMenu
    local c = cm and ac.getCar(cm.index)
    if not c or not config.role then Desktop.carMenu = nil return end
    local name = tostring(ac.getDriverName(cm.index) or '')
    local slot = tostring(c.sessionID or cm.index)
    local W6 = config.canCommand and 520 or 260
    local p1 = vec2(math.floor(math.min(math.max(cm.x, 4 * s), w - W6 * s - 4 * s)), math.floor(math.min(cm.y + 2 * s, h - 80 * s)))
    local p2 = vec2(p1.x + W6 * s, p1.y + (config.canCommand and 74 or 52) * s)
    Drag.group = nil
    Drag.modal = { p1, p2 }
    local m = ui.mousePos()
    if m.x >= p1.x and m.x <= p2.x and m.y >= p1.y and m.y <= p2.y then ui.captureMouse(true) end
    drawPanel(p1, p2, BORDER_YELLOW, s)
    drawText('#' .. tostring(ac.getDriverNumber(cm.index) or cm.index) .. '  ' .. name, FONT_TITLE, 11 * s,
      TMP.a:set(p1.x + 12 * s, p1.y + 4 * s), COLOR_TITLE)
    chip('X', vec2(p2.x - 28 * s, p1.y + 4 * s), s, false, COLOR_TITLE, function() Desktop.carMenu = nil end)
    drawSeparator(p1, p2, p1.y + 21 * s, s)
    local y = p1.y + 27 * s
    local x = p1.x + 12 * s
    if config.watchCars and ac.focusCar then
      x = chip(TEXTS.cmWatch, vec2(x, y), s, false, PANEL_COLORS.green, function()
        ac.focusCar(cm.index)
        if ac.setCurrentCamera and ac.CameraMode then ac.setCurrentCamera(ac.CameraMode.Cockpit) end
        ac.log('race-control: watching car ' .. slot .. ' on board')
      end)
      chip(TEXTS.cmMine, vec2(x, y), s, false, nil, function() ac.focusCar(0) end)
    else
      drawText(TEXTS.cmNoWatch, FONT_MONO, 8.5 * s, TMP.a:set(x, y + 2 * s), COLOR_DIM)
    end
    if config.canCommand and cm.index ~= 0 then
      y = y + 22 * s
      local ax = p1.x + 12 * s
      ax = confirmChip(TEXTS.dirChip.dt, 'mdt' .. slot, vec2(ax, y), s, nil, function() sendKmr('player_give_drive_through ' .. slot .. '|1', string.format(TEXTS.dirAct.dt, name)) end)
      ax = confirmChip(TEXTS.dirCancelDt, 'mcdt' .. slot, vec2(ax, y), s, nil, function() sendKmr('player_cancel_drive_through ' .. slot, string.format(TEXTS.dirAct.cancelDt, name)) end)
      ax = confirmChip(TEXTS.dirNoSg, 'mnosg' .. slot, vec2(ax, y), s, nil, function() sendKmr('admin_say RC RELAX ' .. slot .. ' SG', string.format(TEXTS.dirAct.relaxSg, name)) end)
      ax = confirmChip(TEXTS.dirToPit, 'mpit' .. slot, vec2(ax, y), s, nil, function() sendKmr('admin_say RC TELEPORT ' .. slot, string.format(TEXTS.dirAct.toPit, name)) end)
      ax = confirmChip(TEXTS.dirChip.dsq, 'mdsq' .. slot, vec2(ax, y), s, PANEL_COLORS.red, function() sendKmr('admin_say RC DSQ ' .. slot, string.format(TEXTS.dirAct.dsq, name)) end)
      ax = confirmChip(TEXTS.dirNoDsq, 'mnodsq' .. slot, vec2(ax, y), s, nil, function() sendKmr('admin_say RC RELAX ' .. slot .. ' DSQ', string.format(TEXTS.dirAct.relaxDsq, name)) end)
      ax = confirmChip(TEXTS.dirMenu, 'mmenu' .. slot, vec2(ax, y), s, nil, function() sendKmr('admin_say RC MENU ' .. slot, string.format(TEXTS.dirAct.menu, name)) end)
      confirmChip(TEXTS.dirChip.kick, 'mkick' .. slot, vec2(ax, y), s, PANEL_COLORS.red, function() sendKmr('player_kick ' .. slot, string.format(TEXTS.dirAct.kick, name)) end)
    end
    if Direction.status and state.ui.clock - Direction.statusT < 5 then
      drawText(Direction.status, FONT_MONO, 8.5 * s, TMP.a:set(p1.x + 12 * s, p2.y - 14 * s), Direction.statusColor or PANEL_COLORS.yellow)
    end
  end
  return function(w, h, s)
    messageWindow(w, h, s)
    if Desktop.carMenu then carMenu(w, h, s) end
    if Desktop.editor then editor(w, h, s) end
    if Audit.open then audit(w, h, s) end
    if Desktop.buttons then buttonsScreen(w, h, s) end
    if Desktop.settingsOpen then settingsWindow(w, h, s) else Settings.shown = false end
    if Desktop.redOpen and config.role then redWindow(w, h, s) else Direction.openSeen = false end
    if Desktop.cockpitOpen then cockpitWindow(w, h, s) end
    if sim.isInMainMenu then lobby(w, h, s) end
    if Desktop.menu then menu(w, h, s) end
    if state.ui.clock < Desktop.indicatorUntil then indicator(w, h, s) end
  end
end)()
function script.drawUI(exclusive)
  if not ServerGuard.ok() then return end
  if not exclusive and Desktop.hudDrawn then
    Desktop.hudDrawn = false
    if not Desktop.hudBoth then
      Desktop.hudBoth = true
      ac.log('race-control: game UI cut, the script drawing called too (drawn once)')
    end
    return
  end
  Desktop.fontCheck()
  local size = ac.getUI().windowSize
  local w = size.x
  local h = size.y
  local s = math.min(math.max((h / 1080) ^ 0.3, 1), 1.3)
  Desktop.text.minPx = Desktop.text.min * s
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
  Drag.group = 'panel'
  local po = Drag.offset('panel', h)
  local x = math.floor(w * 0.5 - boxW * 0.5 + po.x)
  local yMsg = math.floor(h * 0.18 + 10 * s + po.y)
  local ySd = yMsg + msgH + gap
  local notice = state.ui.notice
  if notice and (state.ui.clock >= notice.untilT or (notice.item and not listHas(notice.item))) then
    state.ui.notice = nil
  end
  local intro = Intro.frame()
  local values, anyOn = {}, false
  for i, c in ipairs(PANEL_CELLS) do
    values[i] = c.fn()
    if c.title and values[i] and not values[i].quiet then anyOn = true end
  end
  local text, color = Panel.message()
  local pm = Drag.mode('panel')
  local panelPlace = { vec2(x, yMsg), vec2(x + boxW, yMsg + msgH) }
  Drag.zone('panel', panelPlace[1], panelPlace[2])
  local forced = Drag.hovered('panel') or ac.getCar(0).isInPit or state.ui.clock < Desktop.panelUntil
    or Desktop.menu or Desktop.editor or Audit.open or Desktop.buttons or Desktop.settingsOpen or Desktop.redOpen
    or Desktop.cockpitOpen
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
      local bulb = intro and intro.bulb
      if intro and c.title then cell = bulb and Intro.lampCell(c.title, intro.t) or nil end
      if not c.title and not showTitle then cell = nil end
      local function put(t, font, size, y, col)
        size = math.max(size, Desktop.text.minPx)
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
  local flag = Flags.current
  local FLAG_COLORS = { red = BORDER_RED, yellow = BORDER_YELLOW, slippery = BORDER_YELLOW, blue = BORDER_BLUE,
    green = BORDER_GREEN, white = COLOR_TITLE, checkered = COLOR_TITLE, start = BORDER_YELLOW }
  local function drawFlag(yTop)
    local p2 = vec2(x + boxW, yTop + sdH)
    local col = FLAG_COLORS[flag.kind] or COLOR_TITLE
    local border = (flag.kind == 'white' or flag.kind == 'checkered') and BORDER_BASE or col
    drawFlagBox(vec2(x, yTop), p2, s, border, nil,
      flag.title, col, flag.line1, flag.line2, flag.kind, flag.alert and BORDER_RED or nil)
    if flag.kind == 'red' or flag.lights then
      local r = 6.5 * s
      local lit = flag.kind == 'red' and rgbm(1, 0.1, 0.08, 1) or rgbm(0.15, 1, 0.3, 1)
      for i = 1, 5 do
        local c = vec2(p2.x - 10 * s - r - (5 - i) * (2 * r + 3.5 * s), (yTop + p2.y) / 2)
        drawLedLight(c, r, lit, true, s)
      end
    end
    return p2.y + gap
  end
  local dlTop = state.list
  if stackOn and dlTop.dsq > 0 then
    local p2 = vec2(x + boxW, ySd + sdH)
    drawFlagBox(vec2(x, ySd), p2, s, BORDER_RED, nil, TEXTS.dsqTitle, BORDER_RED, dlTop.dsqReason,
      dlTop.dsqStage == 1 and TEXTS.dsqOut or dlTop.dsqStage == 2 and TEXTS.dsqTow or TEXTS.dsqStop, nil, BORDER_RED)
    ySd = p2.y + gap
  end
  if stackOn and flag then ySd = drawFlag(ySd) end
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
  local cc
  for _, check in pairs(state.cutChecks) do if check.ref then cc = check end end
  local sdHidden = ac.getCar(0).isInPit
  local anySd = false
  if not sdHidden then
    for _, sd in pairs(state.slowdowns) do if sd.active then anySd = true end end
  end
  local function drawCutBoxes(ySd)
    if cc and stackOn then
      local p1 = vec2(x, ySd)
      local p2 = vec2(x + boxW, ySd + sdH)
      drawPanel(p1, p2, BORDER_YELLOW, s)
      drawText(TEXTS.liftTitle, FONT_TITLE, 14 * s, TMP.a:set(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
      drawSeparator(p1, p2, p1.y + 24 * s, s)
      local bx1, bx2 = p1.x + 16 * s, p2.x - 16 * s
      local by1, by2 = p1.y + 30 * s, p1.y + 38 * s
      local lim = bx1 + (bx2 - bx1) * LIFT_LIMIT_POS
      ui.drawRectFilled(vec2(px(bx1), px(by1)), vec2(px(lim), px(by2)), COLOR_LIFT_SLOW, px(4 * s))
      ui.drawRectFilled(vec2(px(lim), px(by1)), vec2(px(bx2), px(by2)), COLOR_LIFT_FAST, px(4 * s))
      ui.drawSimpleLine(vec2(px(lim), px(by1 - 2 * s)), vec2(px(lim), px(by2 + 2 * s)), rgbm(1, 1, 1, 0.8), 1)
      local f = math.min(math.max(LIFT_LIMIT_POS - (cc.shown or cc.margin) * LIFT_SCALE, 0), 1)
      local mx = bx1 + (bx2 - bx1) * f
      local pulse = 0.5 + 0.5 * math.sin(2 * math.pi * LIFT_CARET_HZ * state.ui.clock)
      ui.drawRectFilled(vec2(px(mx - 4 * s), px(by1 - 5 * s)), vec2(px(mx + 4 * s), px(by2 + 5 * s)),
        rgbm(1, 1, 1, 0.15 + 0.35 * pulse), px(3 * s))
      ui.drawRectFilled(vec2(px(mx - 1.5 * s), px(by1 - 3 * s)), vec2(px(mx + 1.5 * s), px(by2 + 3 * s)),
        rgbm(1, 1, 1, 0.75 + 0.25 * pulse), px(1 * s))
      local ly = p1.y + 41 * s
      drawText(TEXTS.liftSlower, FONT_MONO, 10 * s, TMP.a:set(bx1, ly), COLOR_DIM)
      local mid = string.format(TEXTS.liftLimit, cc.zone.gainTolerance)
      local ms = math.max(10 * s, Desktop.text.minPx)
      ui.pushDWriteFont(FONT_MONO)
      local mw = ui.measureDWriteText(mid, ms).x
      ui.dwriteDrawText(mid, ms, vec2(px(lim - mw / 2), px(ly)), COLOR_DIM)
      ui.popDWriteFont()
      drawTextRight(TEXTS.liftFaster, FONT_MONO, 10 * s, bx2, ly, COLOR_DIM)
    end
    if intro and intro.box and not cc and not anySd then
      local k = intro.boxK or 0
      local pulse = 0.5 + 0.5 * math.cos(2 * math.pi * 3 * state.ui.clock)
      if intro.box == 'swap' then
        local p1 = vec2(x, ySd + sdH + gap)
        local p2 = vec2(x + boxW, ySd + sdH + gap + msgH)
        drawPanel(p1, p2, BORDER_GREEN, s)
        drawText(TEXTS.swapTitle, FONT_TITLE, 14 * s, TMP.a:set(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
        drawSeparator(p1, p2, p1.y + 24 * s, s)
        local total = config.swapMinSeconds
        local left = total * (1 - k)
        drawText(string.format(TEXTS.swapWait, mmss(left)), FONT_TEXT, 12 * s, TMP.a:set(p1.x + 16 * s, p1.y + 29 * s), COLOR_SWAP)
        drawText(string.format(TEXTS.swapTimes, mmss(total - left), mmss(total)), FONT_MONO, 12 * s,
          TMP.a:set(p1.x + 16 * s, p1.y + 45 * s), COLOR_TITLE)
      else
        local p1 = vec2(x, ySd)
        local p2 = vec2(x + boxW, ySd + sdH)
        drawPanel(p1, p2, BORDER_YELLOW, s)
        drawText(intro.box == 'lift' and TEXTS.liftTitle or TEXTS.sdTitle, FONT_TITLE, 14 * s,
          TMP.a:set(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
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
          drawText(TEXTS.liftSlower, FONT_MONO, 10 * s, TMP.a:set(bx1, ly), COLOR_DIM)
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
    for _, zone in ipairs(config.cutZones) do
      local sd = state.slowdowns[zone.category]
      if stackOn and not cc and not sdHidden and sd and sd.active then
        local p1 = vec2(x, ySd)
        local p2 = vec2(x + boxW, ySd + sdH)
        drawPanel(p1, p2, BORDER_YELLOW, s)
        drawText(sd.title, FONT_TITLE, 14 * s, TMP.a:set(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
        drawSeparator(p1, p2, p1.y + 24 * s, s)
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
  end
  local yNext = ySd
  local rp = state.repair
  local dl = state.list
  local sgIt = config.sg and sgItem()
  if stackOn and sgIt and (StopAndGo.stopping or StopAndGo.resume) then
    local total = sgSeconds(sgIt)
    local left = StopAndGo.remainingMs(sgIt) / 1000
    local h = msgH + math.floor(10 * s)
    local p1 = vec2(x, yNext)
    local p2 = vec2(x + boxW, yNext + h)
    drawPanel(p1, p2, BORDER_RED, s)
    local stopping = StopAndGo.stopping
    drawText(stopping and TEXTS.sgBoxTitle or TEXTS.sgBoxInterrupted, FONT_TITLE, 14 * s,
      TMP.a:set(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
    drawTextRight(stopping and mmss(left) or string.format(TEXTS.sgBoxLeft, mmss(left)), FONT_MONO, 14 * s,
      p2.x - 16 * s, p1.y + 5 * s, COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + 24 * s, s)
    local line1 = TEXTS.sgBoxStay
    if not stopping then
      local back = config.sgReturnSeconds > 0 and StopAndGo.returnLeft and StopAndGo.returnLeft()
      line1 = back and string.format(TEXTS.sgBoxReturnWithin, mmss(back)) or TEXTS.sgBoxSameDriver
    end
    drawText(line1, FONT_TEXT, 12 * s, TMP.a:set(p1.x + 16 * s, p1.y + 29 * s), BORDER_RED)
    if stopping then
      local bx1, bx2, by = p1.x + 16 * s, p2.x - 16 * s, p1.y + 47 * s
      ui.drawRectFilled(vec2(px(bx1), px(by)), vec2(px(bx2), px(by + 5 * s)), rgbm(1, 1, 1, 0.12), px(2 * s))
      local k = total > 0 and math.min(math.max((total - left) / total, 0), 1) or 0
      ui.drawRectFilled(vec2(px(bx1), px(by)), vec2(px(bx1 + (bx2 - bx1) * k), px(by + 5 * s)), BORDER_RED, px(2 * s))
      drawText(string.format(TEXTS.sgBoxTimes, mmss(total - left), mmss(total)), FONT_MONO, 12 * s,
        TMP.a:set(p1.x + 16 * s, p1.y + 56 * s), COLOR_TITLE)
    else
      drawText(TEXTS.sgBoxResume, FONT_MONO, 12 * s, TMP.a:set(p1.x + 16 * s, p1.y + 45 * s), COLOR_TITLE)
    end
    yNext = p2.y + gap
  end
  local dtHead = dl.items[1]
  if stackOn and dl.dsq == 0 and dtHead and dtHead.kind:sub(1, 2) ~= 'SG' then
    local p2 = vec2(x + boxW, yNext + sdH)
    local more = #dl.items > 1 and string.format(TEXTS.dtMore, #dl.items - 1) or ''
    local deadline = dtHead.laps < 0 and TEXTS.dtOverdue or dtHead.laps == 0 and TEXTS.dtThisLap
      or dtHead.laps == 1 and TEXTS.dtNextLap or string.format(TEXTS.dtWithinLaps, dtHead.laps)
    drawFlagBox(vec2(x, yNext), p2, s, BORDER_BASE, nil, TEXTS.dtTitle .. more, COLOR_TITLE,
      TEXTS.reason[dtHead.cat] or dtHead.cat, deadline, 'dt')
    yNext = p2.y + gap
  end
  if not stackOn then
  elseif dl.dsq > 0 then
  elseif rp.lapsLeft and rp.class == 'repair' then
    local p2 = vec2(x + boxW, yNext + sdH)
    local title = rp.lapsLeft <= 1 and TEXTS.damageRepairLast or string.format(TEXTS.damageRepairLaps, rp.lapsLeft)
    drawFlagBox(vec2(x, yNext), p2, s, COLOR_ORANGE, COLOR_ORANGE, title, COLOR_ORANGE, rp.text, rp.detail)
    yNext = p2.y + gap
  elseif rp.class == 'beyond' then
    local p1 = vec2(x, yNext)
    local p2 = vec2(x + boxW, yNext + msgH)
    drawPanel(p1, p2, BORDER_RED, s)
    drawText(TEXTS.damageBeyondTitle, FONT_TITLE, 14 * s, TMP.a:set(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
    drawSeparator(p1, p2, p1.y + 24 * s, s)
    drawText(TEXTS.damageBeyond, FONT_TEXT, 12 * s, TMP.a:set(p1.x + 16 * s, p1.y + 29 * s), BORDER_RED)
    drawText(string.format('%s - %s', rp.text or '', rp.detail or ''), FONT_MONO, 12 * s,
      TMP.a:set(p1.x + 16 * s, p1.y + 45 * s), COLOR_TITLE)
    yNext = p2.y + gap
  end
  local ww = WrongWay.back or 0
  if stackOn and dl.dsq == 0 and ww >= config.wrongWay.showMeters and ww > 0 then
    local p2 = vec2(x + boxW, yNext + sdH)
    local lim = config.wrongWay.maxMeters
    drawFlagBox(vec2(x, yNext), p2, s, BORDER_RED, nil, TEXTS.wrongWayTitle, BORDER_RED,
      string.format(TEXTS.wrongWayTurn, ww, lim), string.format(TEXTS.wrongWayLimit, lim), 'noentry')
    yNext = p2.y + gap
  end
  if (cc or anySd or (intro and intro.box)) and stackOn then
    drawCutBoxes(yNext)
    if cc or anySd then yNext = yNext + sdH + gap end
  end
  if config.swapOn() or state.list.wrong then
    local sw = state.swap
    local clock = state.ui.clock
    local total = config.swapMinSeconds
    local title, line1, line2
    local wrongLeft = WrongDriver.remaining()
    if state.swapInvalid and not Rules.dsqOn() then
      title, line1 = TEXTS.swapInvalidTitle, TEXTS.swapInvalidLeave
      local left = WrongDriver.invalidLeft()
      if left then line2 = string.format(TEXTS.wrongDriverTime, mmss(left)) end
    elseif wrongLeft and not Rules.dsqOn() then
      title, line1 = TEXTS.wrongDriverTitle, TEXTS.wrongDriverLeave
      line2 = string.format(TEXTS.wrongDriverTime, mmss(wrongLeft))
    elseif sw.clearUntil and clock < sw.clearUntil then
      title, line1 = TEXTS.swapTitle, TEXTS.swapClear
      if sw.clearElapsed then line2 = string.format(TEXTS.swapTimes, mmss(sw.clearElapsed), mmss(total)) end
    elseif sw.remaining then
      local left = math.max(sw.remaining - (clock - sw.remainingT), 0)
      title = TEXTS.swapTitle
      line1 = string.format(TEXTS.swapWait, mmss(left))
      line2 = string.format(TEXTS.swapTimes, mmss(math.max(total - left, 0)), mmss(total))
    elseif sw.stopT and #state.list.items > 0 then
      title, line1 = TEXTS.swapActive, TEXTS.swapBlocked
    elseif sw.stopT and sw.allowT then
      title, line1 = TEXTS.swapActive, TEXTS.swapDisconnect
      line2 = string.format(TEXTS.swapTimes, mmss(clock - sw.allowT), mmss(total))
    end
    if title and stackOn then
      local ySwap = math.max(ySd + sdH + gap, yNext)
      local p1 = vec2(x, ySwap)
      local p2 = vec2(x + boxW, ySwap + msgH)
      drawPanel(p1, p2, BORDER_GREEN, s)
      drawText(title, FONT_TITLE, 14 * s, TMP.a:set(p1.x + 16 * s, p1.y + 5 * s), COLOR_TITLE)
      drawSeparator(p1, p2, p1.y + 24 * s, s)
      drawText(line1, FONT_TEXT, 12 * s, TMP.a:set(p1.x + 16 * s, p1.y + 29 * s), COLOR_SWAP)
      if line2 then drawText(line2, FONT_MONO, 12 * s, TMP.a:set(p1.x + 16 * s, p1.y + 45 * s), COLOR_TITLE) end
    end
  end
  if config.mode == 'CSP' and Intro.done then
    local sb = math.min(math.max((h / 1080) ^ config.screenScale.exponent, 1), math.max(config.screenScale.max, 1))
    drawPitBox(ac.getCar(0), w, h, sb)
    drawStatus(ac.getCar(0), w, h, sb)
    drawRaceScreens(ac.getCar(0), w, h, sb)
  end
  drawDesktopUI(w, h, s)
  Drag.icons('panel', panelPlace[1], panelPlace[2], s)
  Drag.finish(w, h)
end
local CarControls = {
  enabled = config.cockpit.force,
  mode = config.cockpit.camera,
  interval = config.cockpit.interval,
  exempt = false,
  timer = 0,
}
do
  local me = tostring(ac.getUserSteamID() or '')
  for id in config.cockpit.exempt:gmatch('[^|/]+') do
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
  if not ServerGuard.check(dt) then return end
  local car = ac.getCar(0)
  local l = state.list
  local g = { t = car.currentPenaltyType, p = car.currentPenaltyParameter }
  local inPit = car.isInPitlane
  local lapCount = car.lapCount
  state.ui.clock = state.ui.clock + dt
  OnlineQueue.update()
  AppLink.update()
  RecordSync.base.nameUpdate()
  if car.lapCount > (Audit.askLap or car.lapCount) then Audit.askPending = true end
  if Audit.askAt == nil then Audit.askAt = state.ui.clock + 15 end
  if state.ui.clock >= Audit.askAt and Audit.askAt > 0 then Audit.askPending, Audit.askAt = true, 0 end
  Audit.askLap = car.lapCount
  if sim.isOnlineRace ~= false then Audit.kmrAsk() end
  Audit.kmrSend()
  local jumpedNow = state.jumpSinceUpdate
  state.jumpSinceUpdate = false
  if sim.currentSessionIndex ~= state.lastSessionIndex or state.sessionStartPending then
    local transition = state.lastSessionIndex ~= -1
    ac.log(string.format('race-control: session start (index %d%s%s)', sim.currentSessionIndex,
      state.sessionStartPending and ', start event' or '', transition and '' or ', script start'))
    state.sessionStartPending = false
    if transition then
      Record.fresh()
      state.redFlag = nil
      state.restart = nil
      state.postRed = nil
      state.lights = nil
    end
    l.curLap = lapCount
    state.lastSessionIndex = sim.currentSessionIndex
    l.jumped = false
    state.prevInPitlane = {}
    state.cutPassPenalized = {}
    state.lapCut = false
    state.zonePass = {}
    GainRef.load()
    state.cutChecks = {}
    state.slowdowns = {}
    state.pitDsqActive = false
    state.dtDsqActive = false
    state.code80 = nil
    state.code80Ended = false
    Flags.sessionReset()
    Start.reset()
    state.pitPaid = nil
    Audit.askAt = nil
    state.dsqFlagPutBack = nil
    TrackList.load()
    CarState.load(transition and jumpedNow)
    state.hold = nil
    PitRecord.holdEnded = nil
    PitRecord.load(transition)
    PitStops.wasInPitlane = nil
    PitStops.passInWindow = false
    PitStops.pass = nil
    PitStops.line = 0
    PitStops.endChecked = false
    Rules.endTimeDone = false
    KmrDT.sessionReset()
    PassMirror.load()
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
    physics.lockUserControlsFor(0)
    if g.t == BLACK_FLAG then
      physics.setCarPenalty(ac.PenaltyType.ReleaseBlackFlag)
      g = { t = 0, p = 0 }
    end
    l.prevGame = { t = g.t, p = g.p }
    Rules.sessionSync(g)
    local window = Record.load('window')
    state.pit.done = window == 'done'
    state.pit.missed = window == 'missed'
    local stopWindow = Record.load('stopwindow')
    state.pit.stopDone = stopWindow == 'done'
    state.pit.stopMissed = stopWindow == 'missed'
    SwapRecord.apply(Record.load('swap'))
    RecordSync.askOwn()
    RecordSync.base.askOwn()
    ac.log(string.format('race-control: laps car=%d leaderboard=%s server time=%d ms', lapCount,
      tostring(leaderboardLaps()), serverTimeMs()))
    state.ui.lastSeq = l.seq
    state.ui.notice = nil
  end
  CarControls.update(dt)
  Diag.update(car)
  CarRead.updateMotion(car)
  OnlineQueue.web.update()
  Connection.update()
  RecordSync.update()
  RecordSync.base.update()
  RecordSync.base.bestUpdate()
  RecordSync.base.serverUpdate()
  RecordSync.base.forecastUpdate()
  RecordSync.base.rrUpdate()
  RecordSync.base.stratUpdate()
  RecordSync.base.planUpdate()
  RecordSync.base.boxUpdate()
  RecordSync.base.statusUpdate()
  RecordSync.base.elecUpdate()
  RecordSync.base.setupTabUpdate()
  RecordSync.base.setupPushUpdate()
  if state.hold and serverTimeMs() >= state.hold.untilMs then
    PitRecord.holdEnded = state.hold.untilMs
    state.hold = nil
    PitRecord.save()
  end
  local sw = state.swap
  local parked = car.isInPit
  if sw.prevInPit and not parked and sw.remaining and sw.remaining - (state.ui.clock - sw.remainingT) > 0
      and not Rules.dsqOn() then
    ac.log(string.format('race-control: DSQ, left the pits %.1f s before the driver swap time',
      sw.remaining - (state.ui.clock - sw.remainingT)))
    sw.remaining = nil
    carDsq(1, TEXTS.swapEarlyDsq)
  end
  if sw.prevInPit == false and parked then sw.stopT = state.ui.clock end
  if not parked then sw.stopT = nil end
  local swapAllowed = sw.stopT and #state.list.items == 0 and not state.pitPassServiced
    and not Rules.dsqOn()
  if not swapAllowed then sw.allowT = nil elseif not sw.allowT then sw.allowT = state.ui.clock end
  if not inPit then sw.remaining = nil end
  sw.prevInPit = parked
  updateSwapRelay()
  publishOwnList(car)
  PitStops.update(car)
  Rules.raceEndTime(car)
  DriverTable.update()
  Desktop.update(car)
  if Desktop.teleSample then Desktop.teleSample(car) end
  if config.mode == 'CSP' then PitBox.update(car) end
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
      rcLog(TEXTS.rc.swap, 'Pending penalties taken over: ' .. table.concat(parts, ', '))
      state.ui.lastSeq = state.list.seq
      Rules.finalize()
    end
  end
  if sw.remaining and state.ui.clock - sw.remainingT >= sw.remaining then
    sw.remaining = nil
    sw.clearUntil = state.ui.clock + SERVER_NOTICE_SECONDS
  end
  l.curLap = l.lastLap
  Intro.update(car)
  if CarRead.isStaff(0) then
    local lineFrame = lapCount > l.lastLap
    if lineFrame then l.lastLap = lapCount end
    Start.update(car)
    Flags.update(car, lineFrame)
    if state.ui.clock >= RaceTable.nextT then
      RaceTable.nextT = state.ui.clock + 0.25
      RaceTable.refresh()
    end
    l.prevInPit = inPit
    l.prevGame = { t = g.t, p = g.p }
    return
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
    if g.t == BLACK_FLAG and l.prevGame.t ~= BLACK_FLAG then
      if l.dsq == 0 then
        l.dsq = 1
        l.seq = l.seq + 1
        l.dsqReason = TEXTS.dsqBlackFlag
      end
      if not Rules.dsqOn() then state.dtDsqActive = true end
      if l.dsqStage ~= 1 then dsqGameFlag('black flag from outside the script', nil, true) end
      Rules.zero()
    end
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
    local dsqActive = Rules.dsqOn()
    if state.code80Ended then
      state.code80Ended = false
      if not dsqActive then Rules.finalize() end
    end
    local tw = state.tow
    local towRule = config.tow[sim.raceSessionType] or { mode = 'NONE' }
    local towOn = towRule.mode == 'TOW' and (towRule.towSeconds > 0 or towRule.repairFactor > 0)
    if towRule.mode == 'RESET' and tw.jumpPending and inPit and not dsqActive
        and (#l.items > 0 or next(state.slowdowns)) then
      Rules.zero()
      l.invalidLap = nil
      ac.log('race-control: tow in practice: penalties cleared')
      rcLog(TEXTS.rc.tow, 'Practice - pending penalties cleared')
      showNotice(TEXTS.rcTitle, TEXTS.practiceTowCleared)
    end
    if sim.raceSessionType == ac.SessionType.Practice and CarRead.parked(car) then DamageClass.reset() end
    if Rules.practiceClear(car) == 'dsq' then dsqActive = false end
    if towRule.mode == 'END' and not dsqActive and not state.hold and tw.jumpPending and inPit then
      PitRecord.endQualifying(TEXTS.qualiEndTow)
    end
    local repairing = CarRead.flagOn(car.isRepairing)
    if towOn and not dsqActive and not state.hold then
      if tw.jumpPending and inPit and state.redFlag then
        local d = tw.damage or { powertrain = 0, suspension = 0, body = 0 }
        state.redTow = { tow = towRule.towSeconds, damage = { powertrain = d.powertrain, suspension = d.suspension,
          body = d.body } }
        PitRecord.save()
        ac.log('race-control: tow under the red flag: tow and repair time at the restart')
        rcLog(TEXTS.rc.tow, TEXTS.redTowDeferred)
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
    KmrDT.update()
    RcCommand.update()
    local viaPit = inPit or l.prevInPit
    l.inPitNow = inPit
    local lineFrame = lapCount > l.lastLap
    if lineFrame then
      Rules.line(viaPit, g, lapCount)
      l.lastLap = lapCount
    end
    TyreUse.update(car, lineFrame)
    DamageClass.update(car, lineFrame)
    Start.update(car)
    Flags.officialStart(car, g)
    Flags.update(car, lineFrame)
    RaceTable.update(car, lineFrame, viaPit)
    CarState.update(car, lineFrame)
    DsqFlow.update(car, lineFrame)
    Ban.update()
    PitSpeed.update(car, inPit, lapCount)
    Rules.invalidLaps(car)
    if not Rules.dsqOn() then
      WrongDriver.update()
      WrongDriver.invalidSwap(car)
      WrongWay.update(car)
      StopAndGo.update(car)
    end
    if l.seq > state.ui.lastSeq then
      for _, it in ipairs(l.items) do
        if it.seq == l.seq then showNotice(TEXTS.rcTitle, itemText(it), it) end
      end
      state.ui.lastSeq = l.seq
    end
    if l.jumped and ((not inPit and l.prevInPit) or (lineFrame and not viaPit)) then l.jumped = false end
    l.prevInPit = inPit
    l.prevGame = { t = g.t, p = g.p }
    PassMirror.update(car)
  end
end
