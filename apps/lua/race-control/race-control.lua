-- race-control app (apps/lua/race-control) — CSP Lua app (12h Curitiba)
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
if ac.getSim().isOnlineRace then
  local guiPath = ac.getFolder(ac.FolderID.ExtCfgUser) .. '\\gui.ini'
  local ini = ac.INIConfig.load(guiPath)
  local before = ini:get('HIDE', 'HIDE_RACE_FLAGS', 0)
  if ac.storage.hideRaceFlagsBefore == nil then ac.storage.hideRaceFlagsBefore = tostring(before) end
  if tonumber(before) ~= 1 then
    ini:setAndSave('HIDE', 'HIDE_RACE_FLAGS', 1)
    ac.log('race-control app: HIDE_RACE_FLAGS ' .. tostring(before) .. ' -> 1')
  end
  for _, key in ipairs({ 'MANUAL_PIT_LIMITER', 'PIT_LIMITER_WARNING' }) do
    local was = ini:get('HIDE_ICONS', key, 0)
    if ac.storage['hideIcon' .. key] == nil then ac.storage['hideIcon' .. key] = tostring(was) end
    if tonumber(was) ~= 1 then
      ini:setAndSave('HIDE_ICONS', key, 1)
      ac.log('race-control app: HIDE_ICONS ' .. key .. ' ' .. tostring(was) .. ' -> 1')
    end
  end
  for _, key in ipairs({ 'PIT_SPEED_LIMIT', 'MANUAL_PIT_SPEED_LIMITER', 'WARN_ABOUT_MANUAL_LIMITER' }) do
    local was = ini:get('EXTRA_HUD_ELEMENTS', key, 1)
    if ac.storage['extraHud' .. key] == nil then ac.storage['extraHud' .. key] = tostring(was) end
    if tonumber(was) ~= 0 then
      ini:setAndSave('EXTRA_HUD_ELEMENTS', key, 0)
      ac.log('race-control app: EXTRA_HUD_ELEMENTS ' .. key .. ' ' .. tostring(was) .. ' -> 0')
    end
  end
  local refused = {}
  setInterval(function()
    for _, id in ipairs({ 'sessionTime', 'startingLights', 'wrongWay' }) do
      local ok, err = pcall(ac.disableExtraHUDElements, id, true)
      if not ok and not refused[id] then
        refused[id] = true
        ac.log('race-control app: disableExtraHUDElements ' .. id .. ' refused: ' .. tostring(err))
      end
    end
  end, 5)
end
local APP_REQUEST = '12hcuritiba.race-control.preset'
local APP_ANSWER = '12hcuritiba.race-control.preset.done'
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
  if senderType ~= 'server_script' then
    ac.log('race-control app: preset request ignored, sender ' .. tostring(senderName) .. ' / ' .. tostring(senderType))
    return
  end
  heard = true
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
