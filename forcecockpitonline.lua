-- forcecockpitonline.lua
-- Script ONLINE do CSP. Forca a camera de cockpit como diretiva da sessao.
--
-- Guardas ativas (campos de ac.StateSim, via global "sim"):
--   sim.isPaused        -> menu do ESC aberto
--   sim.isReplayActive  -> replay em andamento
-- Sem guarda para teleporte, reset e outros apps: nesses casos forca mesmo.

local cfg = ac.configValues({
  CHECK_INTERVAL  = 0.05,
  CAMERA_MODE      = 0,    
  ADMIN_STEAM_IDS = ''
})

local exempt = false
do
  local me = ac.getUserSteamID()
  if me and cfg.ADMIN_STEAM_IDS ~= '' then
    for id in string.gmatch(cfg.ADMIN_STEAM_IDS, '[^;]+') do
      if id:match('^%s*(.-)%s*$') == me then exempt = true end
    end
  end
end

local timer = 0

function script.update(dt)
  if exempt then return end
  if sim.isPaused or sim.isReplayActive then return end

  timer = timer + dt
  if timer < cfg.CHECK_INTERVAL then return end
  timer = 0

  ac.setCurrentCamera(cfg.CAMERA_MODE)
end
