-- ============================================================
-- Race Control app (front E, decision 189): only what the online script cannot do. The online script runs the tool
-- (rules, screens); this app writes the pit stop preset of pressure and wing (decision 201), which only apps can do
-- (ac.setPitstopSpinnerValue, measured in M7). Request from the online script: "<name>=<value>;..."; answer:
-- "<name>=<ok|fail>;...". No window, no screen.
-- ============================================================

-- The game flags are hidden online: every flag is shown by the Race Control flag box (decisions 173, 194). CSP option
-- HIDE_RACE_FLAGS of the user gui.ini, written live (measured in M4); the value before is kept once (ac.storage) for
-- the restore rule, still to decide (E-D10)
if ac.getSim().isOnlineRace then
  local guiPath = ac.getFolder(ac.FolderID.ExtCfgUser) .. '\\gui.ini'
  local ini = ac.INIConfig.load(guiPath)
  local before = ini:get('HIDE', 'HIDE_RACE_FLAGS', 0)
  if ac.storage.hideRaceFlagsBefore == nil then ac.storage.hideRaceFlagsBefore = tostring(before) end
  if tonumber(before) ~= 1 then
    ini:setAndSave('HIDE', 'HIDE_RACE_FLAGS', 1)
    ac.log('race-control app: HIDE_RACE_FLAGS ' .. tostring(before) .. ' -> 1')
  end
  -- The pit limiter icons of the game are hidden too (decision 277): the Race Control shows the limiter in its own
  -- box of the car controls. [HIDE_ICONS] of the same gui.ini; the values before are kept once
  for _, key in ipairs({ 'MANUAL_PIT_LIMITER', 'PIT_LIMITER_WARNING' }) do
    local was = ini:get('HIDE_ICONS', key, 0)
    if ac.storage['hideIcon' .. key] == nil then ac.storage['hideIcon' .. key] = tostring(was) end
    if tonumber(was) ~= 1 then
      ini:setAndSave('HIDE_ICONS', key, 1)
      ac.log('race-control app: HIDE_ICONS ' .. key .. ' ' .. tostring(was) .. ' -> 1')
    end
  end
end

local APP_REQUEST = '12hcuritiba.race-control.preset'
local APP_ANSWER = '12hcuritiba.race-control.preset.done'

-- Mutual check (decision 271): online, on the track of the event, the online script must run. It sends the empty
-- request every 2 s; without it for CHECK_SECONDS after the app starts the controls are locked, the driver is told and,
-- CLOSE_SECONDS later, the game is closed (the car does not stay on the server without the Race Control). Once the
-- script was heard, a loss later is only told (a race is not ended by it)
local TRACK_ID = 'amx_curitiba'
local CHECK_SECONDS, CLOSE_SECONDS = 60, 10
local heard, elapsed, closed = false, 0, false
if ac.getSim().isOnlineRace and tostring(ac.getTrackID() or ''):lower() == TRACK_ID then
  setInterval(function()
    elapsed = elapsed + 1
    if heard or closed or elapsed < CHECK_SECONDS then return end
    local left = math.max(CHECK_SECONDS + CLOSE_SECONDS - elapsed, 0)
    if elapsed == CHECK_SECONDS then ac.log('race-control app: the online script is not running: the game closes') end
    ac.setMessage('RACE CONTROL NOT RUNNING', string.format('The online script of the event did not start - the game '
      .. 'closes in %d s. Tell the organizer.', left), 'illegal', 1.5)
    pcall(physics.lockUserControlsFor, 3)
    if left <= 0 then
      closed = true
      ac.shutdownAssettoCorsa()
    end
  end, 1)
end

ac.onSharedEvent(APP_REQUEST, function(data, senderName, senderType, senderID)
  -- Only from a server script (the online script), never from another app (M9: other apps can use the same key)
  if senderType ~= 'server_script' then
    ac.log('race-control app: preset request ignored, sender ' .. tostring(senderName) .. ' / ' .. tostring(senderType))
    return
  end
  heard = true
  -- The empty request: the check of the app (the answer says the app runs), nothing written, no log
  if tostring(data or '') == '' then
    ac.broadcastSharedEvent(APP_ANSWER, '')
    return
  end
  local answer = {}
  for name, value in tostring(data):gmatch('([^=;]+)=(%-?%d+)') do
    local ok, res = pcall(ac.setPitstopSpinnerValue, name, tonumber(value))
    answer[#answer + 1] = name .. '=' .. ((ok and res) and 'ok' or 'fail')
  end
  local text = table.concat(answer, ';')
  ac.log('race-control app: preset ' .. tostring(data) .. ' -> ' .. text)
  ac.broadcastSharedEvent(APP_ANSWER, text)
end)
