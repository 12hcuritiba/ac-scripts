-- race-control app (apps/lua/race-control) — Racing Control, CSP Lua app (AMX Racing)
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
do
  local root = ac.getFolder(ac.FolderID.Root)
  local from = root .. '\\apps\\lua\\race-control\\fonts'
  local to = root .. '\\content\\fonts'
  for _, name in ipairs(io.scanDir(from, '*.ttf') or {}) do
    local src, dst = from .. '\\' .. name, to .. '\\race-control-' .. name
    if io.fileSize(dst) ~= io.fileSize(src) then io.copyFile(src, dst, false) end
  end
end
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
local APP_REQUEST = 'amxracing.race-control.preset'
local APP_ANSWER = 'amxracing.race-control.preset.done'
local TRACK_ID = 'amx_curitiba'
local CHECK_SECONDS, CLOSE_SECONDS = 60, 10
local heard, elapsed, closed = false, 0, false
local PING_SAMPLES = 10
local guard = {}
local function guardEnd(why)
  if not guard.on then return end
  guard.on = false
  for _, d in ipairs(guard.list) do pcall(d) end
  guard.list = {}
  ac.log('race-control app: guard off (' .. why .. ')')
end
local function pingState()
  local s = guard.pings or {}
  local now = s[#s]
  local dev = 0
  if #s >= 3 then
    local sum = 0
    for _, v in ipairs(s) do sum = sum + v end
    local mean = sum / #s
    local sq = 0
    for _, v in ipairs(s) do sq = sq + (v - mean) ^ 2 end
    dev = math.sqrt(sq / #s)
  end
  local high = now and guard.pingLimit and now > guard.pingLimit
  local unstable = guard.pingDeviation and #s >= 3 and dev > guard.pingDeviation
  return now, dev, high, unstable
end
local function guardBox()
  local size = ac.getUI().windowSize
  local s = math.min(math.max((size.y / 1080) ^ 0.3, 1), 1.3)
  local w, h = 560 * s, 92 * s
  local p1 = vec2(math.floor(size.x / 2 - w / 2), math.floor(size.y * 0.18))
  local p2 = vec2(p1.x + w, p1.y + h)
  local now, dev, high, unstable = pingState()
  local bad = high or unstable
  local border = bad and rgbm(1, 0.3, 0.3, 1) or rgbm(1, 0.85, 0.25, 1)
  ui.drawRectFilled(p1, p2, rgbm(0.04, 0.04, 0.05, 0.92), 8 * s)
  ui.drawRect(p1, p2, border, 8 * s, nil, 1.5 * s)
  local function line(text, font, size_, y, color)
    ui.pushDWriteFont(font)
    ui.dwriteDrawText(text, size_ * s, vec2(p1.x + 16 * s, p1.y + y * s), color)
    ui.popDWriteFont()
  end
  local left = math.max(CHECK_SECONDS - elapsed, 0)
  line('RACING CONTROL - LOADING', 'Segoe UI;Weight=Bold', 14, 6, rgbm(0.96, 0.96, 0.96, 1))
  line(string.format('Waiting for the Racing Control of the event - please wait (the game closes in %d s if it does not load)', left + CLOSE_SECONDS),
    'Segoe UI;Weight=SemiBold', 11, 28, rgbm(1, 0.85, 0.25, 1))
  local ping
  if not now or now < 0 then ping = 'Connection: ping not known yet'
  elseif high then ping = string.format('Connection problem: ping %d ms, over the limit of %d ms of the server - check your internet', now, guard.pingLimit)
  elseif unstable then ping = string.format('Connection problem: unstable ping (%d ms, varying %d ms) - check your internet', now, math.floor(dev + 0.5))
  else ping = string.format('Connection: ping %d ms', now) end
  line(ping, 'Consolas', 11, 50, bad and rgbm(1, 0.3, 0.3, 1) or rgbm(0.6, 0.63, 0.65, 1))
  line(string.format('%d messages held for the Racing Control', guard.swallowed), 'Consolas', 10, 68, rgbm(0.6, 0.63, 0.65, 1))
end
if ac.getSim().isOnlineRace and tostring(ac.getTrackID() or ''):lower() == TRACK_ID then
  local mode = 'hide'
  local okX, extras = pcall(ac.INIConfig.onlineExtras)
  local function key(name)
    local ok, v = pcall(function() return extras and extras:get('SCRIPT_1', name, '') end)
    return ok and v and tostring(v) or ''
  end
  local hud = key('event'):match('gameHud%s*:%s*(%a+)') or key('gameHud'):match('^%s*(%a+)')
  if okX and hud then mode = hud:lower() end
  guard = { on = true, list = {}, swallowed = 0, pings = {} }
  local pingKey = key('ping')
  guard.pingLimit = tonumber(pingKey:match('limit%s*:%s*(%d+)'))
  guard.pingDeviation = tonumber(pingKey:match('deviation%s*:%s*(%d+)'))
  local function keep(d) if d then guard.list[#guard.list + 1] = d end end
  keep(ac.onChatMessage(function(message, carIndex)
    if not guard.on then return end
    guard.swallowed = guard.swallowed + 1
    ac.log('race-control app: guard, chat held (car ' .. tostring(carIndex) .. '): ' .. tostring(message))
    return true
  end))
  if ac.onMessage then
    keep(ac.onMessage(function(title, description)
      if not guard.on then return end
      guard.swallowed = guard.swallowed + 1
      ac.log('race-control app: guard, game message held: ' .. tostring(title or '') .. ' - ' .. tostring(description or ''))
    end))
  end
  keep(ac.blockSystemMessages('.'))
  if ui.onExclusiveHUD then
    keep(ui.onExclusiveHUD(function(m)
      if not guard.on or (m ~= 'game' and m ~= 'menu') then return end
      guardBox()
      if m ~= 'game' or mode == 'show' then return end
      return mode == 'hideall' and true or 'apps'
    end))
  end
  ac.log('race-control app: guard on until the online script runs (gameHud ' .. mode .. ', ping key '
    .. (pingKey ~= '' and pingKey or 'none') .. ', server options ' .. (okX and extras and 'read' or 'not read') .. ')')
  setInterval(function()
    elapsed = elapsed + 1
    if guard.on then
      local car = ac.getCar(0)
      local ping = car and tonumber(car.ping)
      if ping and ping >= 0 then
        guard.pings[#guard.pings + 1] = ping
        if #guard.pings > PING_SAMPLES then table.remove(guard.pings, 1) end
        local _, dev, high, unstable = pingState()
        if (high or unstable) and not guard.pingTold then
          guard.pingTold = true
          ac.log(string.format('race-control app: guard, connection problem: ping %d ms, deviation %.0f ms', ping, dev))
        end
      end
    end
    if heard then guardEnd('online script running, ' .. guard.swallowed .. ' messages held') end
    if heard or closed or elapsed < CHECK_SECONDS then return end
    local left = math.max(CHECK_SECONDS + CLOSE_SECONDS - elapsed, 0)
    if elapsed == CHECK_SECONDS then
      local now, dev = pingState()
      guardEnd('online script not running')
      ac.log(string.format('race-control app: the online script is not running: the game closes (ping %s ms, deviation %.0f ms)',
        tostring(now or '-'), dev))
    end
    ac.setMessage('RACING CONTROL NOT RUNNING', string.format('The online script of the event did not start - the game '
      .. 'closes in %d s. Tell the organizer.', left), 'illegal', 1.5)
    pcall(physics.lockUserControlsFor, 3)
    if left <= 0 then
      closed = true
      ac.shutdownAssettoCorsa()
    end
  end, 1)
end
local COCKPIT_REQUEST = 'amxracing.race-control.cockpit'
local COCKPIT_ANSWER = 'amxracing.race-control.cockpit.state'
local CHANNELS = { 'main', 'engine', 'transmission', 'tyres', 'surfaces', 'dirt', 'wind', 'opponents', 'carComponents',
  'track', 'weather', 'rain', 'wipers' }
local function cockpitState()
  local out = {}
  local car = ac.getCar(0)
  out[#out + 1] = string.format('ffb=%.3f', car and car.ffbMultiplier or 1)
  out[#out + 1] = string.format('fov=%.1f', ac.getSim().firstPersonCameraFOV or 56)
  local ok, p = pcall(ac.getOnboardCameraParams, 0)
  if ok and p then out[#out + 1] = string.format('x=%.4f;y=%.4f;pitch=%.2f', p.position.x, p.position.y, p.pitch) end
  for _, ch in ipairs(CHANNELS) do
    local v = ac.getAudioVolume(ch, nil, -1)
    if v and v >= 0 then out[#out + 1] = string.format('vol.%s=%.3f', ch, v) end
  end
  return table.concat(out, ';')
end
local function clamp(v, a, b) return math.min(math.max(v, a), b) end
local COCKPIT_APPLY_SECONDS = 3
local COCKPIT_STORE = '.amxracing.race-control.cockpit'
local function cockpitKey() return 'cockpit.' .. tostring(ac.getCarID(0) or 'car') end
local function cockpitApply(text)
  local seat, n = nil, 0
  for item, value in tostring(text or ''):gmatch('([%w%.]+)=(%-?[%d%.]+)') do
    local v = tonumber(value)
    if v then
      n = n + 1
      if item == 'ffb' then ac.setFFBMultiplier(clamp(v, 0, 2))
      elseif item == 'fov' then ac.setFirstPersonCameraFOV(clamp(v, 10, 120))
      elseif item == 'x' or item == 'y' or item == 'pitch' then
        if not seat then local ok, p = pcall(ac.getOnboardCameraParams, 0); seat = ok and p or false end
        if seat then
          if item == 'pitch' then seat.pitch = clamp(v, -30, 30) else seat.position[item] = v end
        end
      elseif item:match('^vol%.') then ac.setAudioVolume(item:sub(5), clamp(v, 0, 1))
      end
    end
  end
  if seat then pcall(ac.setOnboardCameraParams, 0, seat, true) end
  return n
end
if ac.getSim().isOnlineRace and tostring(ac.getTrackID() or ''):lower() == TRACK_ID then
  local waited, applied = 0, false
  setInterval(function()
    if applied then return end
    waited = waited + 1
    if waited < COCKPIT_APPLY_SECONDS then return end
    applied = true
    local saved = ac.storage[cockpitKey()]
    if saved and saved ~= '' then
      ac.log(string.format('race-control app: cockpit values saved for %s applied: %d', cockpitKey(), cockpitApply(saved)))
    end
  end, 1)
end
ac.onSharedEvent(COCKPIT_REQUEST, function(data, senderName, senderType)
  if senderType ~= 'server_script' then return end
  if tostring(data or '') == 'save' then
    local now = cockpitState()
    ac.storage[cockpitKey()] = now
    ac.log('race-control app: cockpit values saved for ' .. cockpitKey() .. ': ' .. now)
    ac.store(COCKPIT_STORE, now)
    ac.broadcastSharedEvent(COCKPIT_ANSWER, now .. ';saved=1')
    return
  end
  local seat = nil
  for item, delta in tostring(data or ''):gmatch('([%w%.]+)=(%-?[%d%.]+)') do
    local d = tonumber(delta) or 0
    if item == 'ffb' then
      local car = ac.getCar(0)
      ac.setFFBMultiplier(clamp((car and car.ffbMultiplier or 1) + d, 0, 2))
    elseif item == 'fov' then
      ac.setFirstPersonCameraFOV(clamp((ac.getSim().firstPersonCameraFOV or 56) + d, 10, 120))
    elseif item == 'x' or item == 'y' or item == 'pitch' then
      if not seat then local ok, p = pcall(ac.getOnboardCameraParams, 0); seat = ok and p or false end
      if seat then
        if item == 'pitch' then seat.pitch = clamp(seat.pitch + d, -30, 30)
        else seat.position[item] = seat.position[item] + d end
      end
    elseif item:match('^vol%.') then
      local ch = item:sub(5)
      local v = ac.getAudioVolume(ch, nil, -1)
      if v and v >= 0 then ac.setAudioVolume(ch, clamp(v + d, 0, 1)) end
    end
  end
  if seat then pcall(ac.setOnboardCameraParams, 0, seat, true) end
  if tostring(data or '') ~= 'state' then ac.log('race-control app: cockpit ' .. tostring(data)) end
  local now = cockpitState()
  ac.store(COCKPIT_STORE, now)
  ac.broadcastSharedEvent(COCKPIT_ANSWER, now)
end)
ac.onSharedEvent(APP_REQUEST, function(data, senderName, senderType, senderID)
  if senderType ~= 'server_script' then
    ac.log('race-control app: preset request ignored, sender ' .. tostring(senderName) .. ' / ' .. tostring(senderType))
    return
  end
  heard = true
  if guard.on then guardEnd('online script running, ' .. guard.swallowed .. ' messages held') end
  if tostring(data or '') == '' then
    ac.broadcastSharedEvent(APP_ANSWER, '')
    return
  end
  local answer = {}
  local preset = tonumber(tostring(data):match('^@(%d+)'))
  if preset then
    local okP, resP = pcall(ac.setCurrentQuickPitPreset, preset)
    answer[#answer + 1] = '@' .. preset .. '=' .. ((okP and resP) and 'ok' or 'fail')
  end
  for name, value in tostring(data):gsub('^@%d+;?', ''):gmatch('([^=;]+)=(%-?%d+)') do
    local ok, res = pcall(ac.setPitstopSpinnerValue, name, tonumber(value), preset)
    answer[#answer + 1] = name .. '=' .. ((ok and res) and 'ok' or 'fail')
  end
  local back = {}
  local okList, list = pcall(ac.getPitstopSpinners)
  for i, sp in ipairs(okList and list or {}) do back[#back + 1] = string.format('%d:%s=%s', i, tostring(sp.name), tostring(sp.value)) end
  ac.log('race-control app: spinners after the write: ' .. table.concat(back, ' '))
  local text = table.concat(answer, ';')
  ac.log('race-control app: preset ' .. tostring(data) .. ' -> ' .. text)
  ac.broadcastSharedEvent(APP_ANSWER, text)
end)
local SETUP_VALUES = 'amxracing.race-control.setupvalues'
ac.onSharedEvent(SETUP_VALUES, function(data, senderName, senderType)
  if senderType ~= 'server_script' then
    ac.log('race-control app: setup values ignored, sender ' .. tostring(senderName) .. ' / ' .. tostring(senderType))
    return
  end
  local function tyres()
    local car, parts = ac.getCar(0), {}
    for i = 0, 3 do local w = car and car.wheels and car.wheels[i]; parts[#parts + 1] = string.format('%.1f', tonumber(w and w.tyrePressure) or 0) end
    return table.concat(parts, ' / ')
  end
  local before, answer = tyres(), {}
  local editable = ac.isSetupAvailableToEdit and ac.isSetupAvailableToEdit()
  for name, value in tostring(data or ''):gmatch('([%w_]+)=(%-?%d+)') do
    local ok, res = pcall(ac.setSetupSpinnerValue, name, tonumber(value))
    answer[#answer + 1] = name .. '=' .. ((ok and res) and 'ok' or 'fail')
  end
  local text = table.concat(answer, ';')
  ac.log('race-control app: setup values ' .. tostring(data) .. ' -> ' .. text .. ' (setup editable: ' .. tostring(editable) .. '; tyres ' .. before .. ' -> ' .. tyres() .. ' psi)')
  ac.broadcastSharedEvent(SETUP_VALUES .. '.done', text)
end)
local SETUP_STORE = '.amxracing.race-control.setup'
local SETUP_SECONDS = 15
local function setupText()
  local ok, list = pcall(ac.getSetupSpinners)
  if not ok or type(list) ~= 'table' then return '' end
  local out = {}
  for _, s in ipairs(list) do
    local raw = tonumber(s.value) or 0
    local shown
    if type(s.items) == 'table' and s.items[raw - (tonumber(s.min) or 0) + 1] then shown = tostring(s.items[raw - (tonumber(s.min) or 0) + 1])
    else shown = string.format('%g', raw * (tonumber(s.displayMultiplier) or 1)) end
    local label = tostring(s.label or s.name or ''):gsub('[|;=%c]', ' ')
    out[#out + 1] = label .. '=' .. shown:gsub('[|;=%c]', ' ') .. (s.units and s.units ~= '' and (' ' .. tostring(s.units):gsub('[|;=%c]', ' ')) or '')
  end
  return table.concat(out, ';')
end
local SETUP_RAW_STORE = '.amxracing.race-control.setupraw'
local function setupRaw()
  local ok, list = pcall(ac.getSetupSpinners)
  if not ok or type(list) ~= 'table' then return '' end
  local out = {}
  for _, s in ipairs(list) do
    local name = tostring(s.name or ''):gsub('[|;=%c]', ' ')
    if name ~= '' then out[#out + 1] = name .. '=' .. string.format('%d', math.floor(tonumber(s.value) or 0)) end
  end
  return table.concat(out, ';')
end
local SETUP_DEF_STORE = '.amxracing.race-control.setupdef'
local function setupDefault()
  local ok, list = pcall(ac.getSetupSpinners)
  if not ok or type(list) ~= 'table' then return '' end
  local out = {}
  for _, s in ipairs(list) do
    local name = tostring(s.name or ''):gsub('[|;=%c]', ' ')
    if name ~= '' and tonumber(s.defaultValue) then out[#out + 1] = name .. '=' .. string.format('%d', math.floor(tonumber(s.defaultValue))) end
  end
  return table.concat(out, ';')
end
local function keepSetup(why)
  local def = setupDefault()
  if def ~= '' then ac.store(SETUP_DEF_STORE, def) end
  local text = setupText()
  if text ~= '' then ac.store(SETUP_STORE, text) end
  local raw = setupRaw()
  if raw ~= '' then ac.store(SETUP_RAW_STORE, raw) end
  if why then ac.log('race-control app: setup kept (' .. why .. '): ' .. #text .. ' characters') end
end
if ac.getSim().isOnlineRace and tostring(ac.getTrackID() or ''):lower() == TRACK_ID then
  setTimeout(function() keepSetup('load') end, 3)
  setInterval(function() keepSetup() end, SETUP_SECONDS)
  if ac.onSetupFile then ac.onSetupFile(function(op) keepSetup(tostring(op)) end) end
end
local PUSH_STORE, PUSH_DONE = '.amxracing.race-control.setuppush', '.amxracing.race-control.setuppush.done'
local PUSH_TOLD_SECONDS = 15
if ac.getSim().isOnlineRace and tostring(ac.getTrackID() or ''):lower() == TRACK_ID then
  local push = { id = nil, answered = {}, toldT = -1e9, clock = 0 }
  local function answer(id, st, why)
    push.answered[id] = true
    local reason = tostring(why or ''):gsub('[|%c]', ' ')
    ac.store(PUSH_DONE, id .. '|' .. st .. '|' .. reason)
    ac.log('race-control app: team setup ' .. id .. ': ' .. st .. (reason ~= '' and (' (' .. reason .. ')') or ''))
  end
  setInterval(function()
    push.clock = push.clock + 1
    local raw = ac.load and ac.load(PUSH_STORE)
    if type(raw) ~= 'string' or raw == '' then return end
    local id, name, ini = raw:match('^([%w%-]+)|([^\n]*)\n(.*)$')
    if not id or push.answered[id] then return end
    if push.id ~= id then
      push.id, push.toldT = id, -1e9
      ac.log('race-control app: team setup received: ' .. id .. ' ' .. name .. ', ' .. #ini .. ' characters')
    end
    local okE, editable = pcall(ac.isSetupAvailableToEdit)
    if not (okE and editable) or push.clock - push.toldT < PUSH_TOLD_SECONDS then return end
    push.toldT = push.clock
    local toast = ui.toast(ui.Icons.Wrench, 'Setup from your team: ' .. name .. '###rc-team-setup')
    toast:button(ui.Icons.Confirm, 'Apply', function()
      if push.answered[id] then return end
      local ok, res = pcall(ac.loadSetup, ini)
      if ok and res then answer(id, 'aplicado', '')
      else answer(id, 'falhou', ok and 'refused by the game: not in the setup menu or the setup is fixed' or tostring(res)) end
    end)
    toast:button(ui.Icons.Cancel, 'Refuse', function()
      if not push.answered[id] then answer(id, 'recusado', 'refused by the driver') end
    end)
  end, 1)
end
