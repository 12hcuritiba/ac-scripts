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
local LANG_PT = {
  pit = {
    DSQ = 'Saiu do pit lane com o pit fechado - desclassificado',
    REPRIMAND = 'Saiu do pit lane com o pit fechado - reprimenda',
  },
  cut = {
    SLOWDOWN = 'Corte da zona de exclusão - slowdown',
    DT = 'Corte da zona de exclusão - drive-through',
    DSQ = 'Corte da zona de exclusão - desclassificado',
  },
  timerPay = 'SLOWDOWN  ',
  timerSeconds = '%.1f s',
  timerDeadline = '   prazo ',
  timerDeadlineSeconds = '%.0f s',
  timerEnd = ' ou fim da volta',
  sdTitle = 'CORTE DA ZONA DE EXCLUSÃO - slowdown',
  liftTitle = 'CORTE DA ZONA DE EXCLUSÃO - tire o pé para evitar o slowdown',
  liftSlower = 'mais lento - sem penalidade',
  liftFaster = 'mais rápido - slowdown',
  liftLimit = '+%g%% ref',
  rcPrefix = '[RC] ',
  rcTitle = 'RACING CONTROL',
  cellPit = 'JANELA',
  cellSwap = 'TROCA',
  cellTrack = 'PISTA',
  cellPenalties = 'PENALIDADES',
  pitOpen = 'ABERTA %s',
  pitDone = 'FEITA',
  pitMissed = 'PERDIDA',
  pitOpenMsg = 'Janela de parada aberta - troca de piloto antes de fechar',
  swapCount = '%d | %d',
  trackYellow = 'AMARELA',
  trackBlue = 'AZUL',
  penHold = 'RETIDO',
  penDsq = 'DSQ',
  penSG = 'SG%d · %d DTs',
  sgPending = 'Stop & go %d s - pare no seu box nesta volta ou na próxima',
  sgLastLap = 'ÚLTIMA VOLTA - Stop & go %d s - pare no seu box agora',
  sgOverdue = 'VENCIDO - Stop & go %d s - pare no seu box',
  sgServiced = 'Serviço no box - stop & go não cumprido nesta passagem',
  sgAnnulled = 'Serviço iniciado - pagamento do stop & go anulado',
  practiceCleared = 'Treino - penalidades zeradas na vaga',
  pitSpeedNotPaid = 'Excesso de velocidade no pit lane - o drive-through desta passagem não conta', practiceTowCleared = 'Treino - penalidades zeradas pelo reboque',
  practiceDsqCleared = 'Treino - desclassificação retirada na vaga',
  sgStopped = 'Stop & go %s - fique parado, sem serviço',
  sgInterrupted = 'Stop & go interrompido - faltam %s - só o mesmo piloto pode continuar',
  pitMissedLog = 'PERDIDA - nenhuma troca de piloto válida dentro da janela de parada',
  pitBoxTitle = 'PARADA NO BOX',
  pitBoxTotal = 'Total %s',
  pitBoxConfirm = 'Enter para confirmar',
  pitBoxMode = '< %s >',
  pitBoxStart = '   INICIAR >',
  pitModeAuto = 'AUTO',
  pitModeManual = 'MANUAL',
  pitBoxServing = 'Parada em andamento',
  pitFuel = 'Combustível',
  pitFuelValue = '+%d L (para %d / %d L)',
  pitCompound = 'Composto',
  pitTyres = 'Pneus',
  pitPressureFront = 'Pressão dianteira',
  pitPressureRear = 'Pressão traseira',
  pitWing = 'Asa',
  pitStrategy = 'Estratégia', pitStrategyTab = 'ESTRATÉGIA', pitPresetN = 'Preset %d', pitBack = 'Voltar',
  pitStrategyHint = 'Direita: usar   Esquerda: voltar',
  pitPressure = 'Pressão',
  pitRepairSuspension = 'Reparo da suspensão',
  pitRepairPowertrain = 'Reparo do motor e câmbio',
  pitRepairBody = 'Reparo da carroceria',
  pitRepairYes = 'Reparar',
  pitRepairNo = 'Não',
  pitRepairNone = 'Nenhum',
  pitFuelLocked = 'Travado - bandeira vermelha', pitRepairLocked = 'Depois da relargada',
  setupTitle = 'SETUP',
  setupLap = 'Volta %d',
  setupAero = 'AERO',
  setupWing = 'Asa',
  setupDrive = 'TRANSMISSÃO',
  setupDiffPower = 'Diferencial tração',
  setupDiffCoast = 'Diferencial desac.',
  setupPreload = 'Pré-carga',
  setupPreloadValue = '%.0f Nm',
  setupBrakeBias = 'Balanço de freio',
  setupChassis = 'CHASSI',
  setupHeight = 'Altura',
  setupHeaveHeight = 'Altura heave',
  setupDeploy = 'Deploy',
  setupErs = 'ERS / Rec.',
  setupArb = 'Barra estab.',
  setupToe = 'Convergência',
  setupCamber = 'Cambagem',
  setupSuspension = 'SUSPENSÃO',
  setupSpring = 'Mola',
  setupAxes = 'D/T',
  setupBumpSlow = 'Comp. L',
  setupReboundSlow = 'Ret. L',
  setupBumpFast = 'Comp. R',
  setupReboundFast = 'Ret. R',
  setupHeaveSpring = 'Mola heave',
  setupHeaveBumpSlow = 'Heave comp. L',
  setupHeaveReboundSlow = 'Heave ret. L',
  setupHeaveBumpFast = 'Heave comp. R',
  setupHeaveReboundFast = 'Heave ret. R',
  setupTyres = 'PNEUS', setupGears = 'MARCHAS',
  setupPsi = 'PSI',
  setupLife = 'Vida',
  setupKm = 'Km',
  setupLaps = 'Voltas',
  setupLapsOf = '%d/%s',
  statusTitle = 'EST. DO CARRO',
  statusRepair = 'REPARO',
  statusBeyond = 'INSEGURO',
  statusWheels = 'RODAS E SUSPENSÃO',
  statusPunct = 'FURADO',
  statusBent = 'TORTA +%.0f°',
  statusBroken = 'QUEBRADA +%.0f°',
  statusBrokenShort = 'QUEBRADO',
  statusPowertrain = 'MOTOR E CÂMBIO',
  statusEngine = 'MOTOR',
  statusGearbox = 'CÂMBIO',
  statusBop = 'BOP',
  statusOk = 'OK',
  statusBody = 'CARROCERIA',
  sgBoxTitle = 'STOP & GO',
  sgBoxStay = 'Fique parado - sem serviço durante o stop & go',
  sgBoxTimes = 'Parado %s / Total %s',
  sgBoxInterrupted = 'STOP & GO INTERROMPIDO',
  sgBoxLeft = 'faltam %s',
  sgBoxSameDriver = 'Só o mesmo piloto pode continuar',
  sgBoxReturnWithin = 'Só o mesmo piloto pode continuar - volte em até %s',
  sgBoxResume = 'Pare na sua vaga para continuar',
  sgServed = 'Stop & go cumprido',
  sgLimit = 'Limite de stop & go - mais de %d penalidades',
  swapBlocked = 'Troca não permitida - cumpra as penalidades antes',
  wrongDriverTitle = 'PILOTO ERRADO',
  wrongDriverLeave = 'Penalidades de outro piloto pendentes - saia do carro',
  wrongDriverTime = 'Saia em até %s',
  damageRepairLaps = 'REPARO OBRIGATÓRIO - %d VOLTAS',
  damageRepairLast = 'REPARO OBRIGATÓRIO - ÚLTIMA VOLTA',
  damageBent = 'Suspensão torta - %s',
  damageSuspension = 'Suspensão %s',
  damageAngle = '%s +%.1f°',
  damageBody = 'Dano na carroceria %s %d',
  damageBodyLimit = 'limite %d',
  damageTyre = 'Pneu furado - %s',
  damageTyres = 'Pneus furados - %d',
  damageTyresAllowed = '%d de %d permitidos',
  damageBeyondTitle = 'DANO ALÉM DO LIMITE DE SEGURANÇA',
  damageBeyond = 'Pare fora da pista e volte ao box (reboque)',
  damageWheel = 'Roda solta - %s',
  damageEngine = 'Motor quebrado',
  damageGearbox = 'Câmbio quebrado',
  damagePowertrain = 'Dano no motor e câmbio %.0f%%',
  damagePowertrainLimit = 'reparo a partir de %d%%',
  dsqTitle = 'DESCLASSIFICADO',
  dsqStop = 'Pare no seu box antes da linha',
  dsqTow = 'Carro retirado - volte ao box',
  dsqOut = 'Fora da sessão - controles travados',
  dsqSafety = 'Risco à segurança - dano além do limite de segurança',
  editedFile = 'Arquivo editado',
  kmrTitle = 'KMR',
  swapActive = 'TROCA DE PILOTO ATIVA',
  swapTitle = 'TROCA DE PILOTO',
  swapDisconnect = 'Desconecte para fazer a troca de piloto',
  swapWait = 'Você está pilotando agora - espere %s antes de sair do box',
  swapClear = 'Pode sair do box - VAI VAI!',
  swapTimes = 'Decorrido %s / Total %s',
  code80 = 'CODE 80 - nenhuma penalidade pode ser cumprida até a bandeira verde',
  holdTitle = 'RETIDO',
  hold = 'Retido %s - %s',
  holdTwoDT = 'Dois drive-throughs pendentes',
  holdTwoDTLong = 'Dois drive-throughs pendentes (excesso de velocidade no pit lane vencido na pista)',
  towReason = 'De volta ao box',
  qualiEndTow = 'reboque', qualiEndHold = 'Classificação encerrada - %s',
  qualiEndNotice = 'Classificação encerrada (%s) - vale sua melhor volta válida',
  repairReason = 'Reparo na parada',
  parkedFlagTitle = 'CARRO PARADO NA PISTA', parkedMove = 'Siga - %d s', parkedLeft = 'Paradas toleradas restantes: %d de %d - acima: desclassificado', parkedNoGrace = 'Não seguiu: desclassificado',
  parkedTitle = 'Carro parado na pista', parkedLog = 'parada %d de %d tolerada', parkedDsq = 'Carro parado na pista',
  parkedDsqDetail = 'mais de %d paradas de %d s', parkedTimeLog = '%d s - sem combustível na pista',
  parkedFuelRace = 'Sem combustível na pista - %d s somados ao seu tempo de prova', parkedFuelLaps = 'Sem combustível na pista - suas voltas são inválidas daqui em diante',
  parkedFuelLapsLog = 'sem combustível - voltas inválidas daqui em diante',
  timeNotServedLog = '%d s - %s não cumprido no fim da prova', timeNotServedTitle = 'PENALIDADE NÃO CUMPRIDA',
  dtServedWhy = '%s - cumprido na passagem pelo pit (prazo DT%d)', holdIncludes = 'inclui %s', dsqVoided = 'pendente quando a DSQ veio: %s',
  practiceClearedWhat = 'Treino - zerado na vaga: %s',
  timeNotServed = '%d s somados ao seu tempo final: %s não cumprido',
  reason = {
    SD1 = 'Corte da zona de exclusão - zona 1',
    SD2 = 'Corte da zona de exclusão - zona 2',
    PSE = 'Excesso de velocidade no pit lane',
    RC = 'Decisão do Racing Control',
    JS = 'Largada queimada na relargada parada',
    JSS = 'Largada queimada na largada',
    FS = 'Acima da velocidade máxima na volta de apresentação',
    FL = 'Abaixo da velocidade mínima na volta de apresentação',
    FP = 'Ultrapassagem na volta de apresentação não devolvida',
    PX = 'Saiu do box antes do carro da frente na relargada',
  },
  kmrReasons = {
    K0 = 'Penalidade do KMR', K1 = 'Cruzou a linha da saída do box', K2 = 'Excesso de velocidade no pit lane', K3 = 'Limite de infrações',
    K4 = 'Colisão com um carro dando volta em você', K5 = 'Colisão com um carro em volta rápida', K6 = 'Atrapalhou volta rápida',
    K7 = 'Marcha à ré', K8 = 'Carro parado perto da pista', K9 = 'Colisões demais', K10 = 'Excesso de velocidade sob VSC',
    K11 = 'Lentidão sob VSC', K12 = 'Ultrapassagem sob VSC', K13 = 'Linha de corte', K14 = 'Bandeira azul ignorada',
    K15 = 'Voltou à pista em alta velocidade',
  },
  dsqBlackFlag = 'Bandeira preta',
  dsqDtReason = 'Drive-through não cumprido',
  wrongWayDsq = 'Contramão',
  swapVoidService = 'Troca de piloto inválida - serviço na mesma parada',
  swapVoidSg = 'Troca de piloto inválida - stop & go cumprido na mesma parada',
  swapInvalidTitle = 'TROCA DE PILOTO INVÁLIDA',
  swapInvalidLeave = 'Stop & go cumprido nesta parada - saia do carro, não saia do box',
  swapInvalidDsq = 'Troca de piloto na parada em que o stop & go foi cumprido',
  swapInvalidLeftDsq = 'Saiu do box depois de uma troca de piloto inválida',
  wrongWayTitle = 'CONTRAMÃO',
  wrongWayTurn = 'Dê a volta - %.0f / %d m',
  wrongWayLimit = 'Acima de %d m: desclassificado',
  dtTitle = 'DRIVE-THROUGH',
  dtMore = '  +%d',
  dtThisLap = 'Cumpra nesta volta',
  dtNextLap = 'Cumpra nesta volta ou na próxima',
  dtWithinLaps = 'Cumpra em até %d voltas',
  dtOverdue = 'VENCIDO - cumpra na próxima passagem pelo box',
  pitWindowDsq = 'Parada obrigatória não feita',
  swapEarlyDsq = 'Saiu do box antes do tempo da troca de piloto',
  swapsMissingDsq = 'Trocas de piloto faltando (%d de %d)',
  stopsMissingDsq = 'Paradas faltando (%d de %d)',
  driverRow = 'Piloto',
  driverRowText = 'troca %d%s - equipe %s - GUID %s',
  driverRowRejoin = ' (reentrada)',
  pitStopRow = 'Box',
  pitStopRowText = 'linha %d - parada %s - entrada %s - saída %s - %s - %s - %s - bandeiras %s/%s - equipe %s - GUID %s',
  pitStopRowInPits = 'no box',
  pitStopRowNoService = 'sem serviço',
  pitStopRowNoPenalty = 'sem penalidade',
  stintMinDsq = 'Tempo de condução abaixo do mínimo (%s de %d min, prova inteira)',
  stintMaxDsq = 'Tempo de condução acima do máximo (%d min, prova inteira)',
  kmrRatingDsq = 'Nota de segurança do KMR %s (limite %s)',
  scrRelative = 'RELATIVO', scrStandings = 'CLASSIFICAÇÃO', scrLapTime = 'TEMPO DE VOLTA', scrDelta = 'DELTA', scrVsBest = 'vs MELHOR',
  scrLaps = 'VOLTAS', scrLapN = 'Volta %d', scrStint = 'STINT - %s - %d voltas', scrRace = 'SITUAÇÃO DA PROVA',
  scrCurrent = 'Atual', scrNow = 'Agora', scrBest = 'Melhor', scrOptimal = 'Ideal', scrLast = 'Última',
  scrSession = 'Sessão', scrInvalid = 'INVÁLIDA', scrTime = 'Tempo', scrPosition = 'Posição', scrLap = 'Volta',
  scrLeader = 'Líder', scrAhead = 'À frente', scrBehind = 'Atrás', scrStops = 'PARADAS', scrSwaps = 'TROCAS',
  scrWindow = 'JANELA', scrStintLine = 'STINT', scrTyres = 'Pneus', scrPending = 'Pendentes',
  scrOpt = 'Ideal', scrCarBest = 'Melhor do carro', scrStintN = 'STINT %d - %s', scrStintInfo = '%d voltas - %s',
  scrStintMin = ' / mín %d', scrDriveTotal = 'prova %s', scrBestAvg = 'Melhor %s - média %s', scrDeltaButton = 'Δ',
  scrDeltaRefs = { best = 'MELH.', session = 'SESS.', optimal = 'IDEAL', alltime = 'REC.' }, scrDeltaSectors = 'SETORES',
  cmWatch = 'VER A BORDO', cmMine = 'MEU CARRO', cmNoWatch = 'ver a bordo: desligado neste servidor (roles watch:1)',
  scrGaps = 'DIFERENÇAS', scrObligations = 'OBRIGAÇÕES', scrTrack = 'Pista', scrKmr = 'Pontos KMR',
  exitTitle = 'RELARGADA', exitLine1 = 'Saída do box em fila - ordem da relargada',
  exitWait = 'Espere na sua vaga - saia depois que %s passar', exitGo = 'Sua vez - saia do box agora, em fila',
  exitFirst = 'Primeiro da ordem da relargada - saia do box agora', exitEarlyLog = 'Saiu do box antes de %s passar (fora da ordem da relargada)',
  scrKmrRating = 'Nota KMR', scrKmrCrashes = 'Batidas KMR', scrKmrInfr = 'Infrações KMR', scrKmrKm = 'Distância KMR',
  scrKmrNone = 'ainda nenhuma',
  sessionName = { [1] = 'TREINO', [2] = 'CLASSIFICAÇÃO', [3] = 'CORRIDA' },
  edTitle = 'TELAS', edPitDesk = 'Área do box', edDeskOf = 'Área %s de %d', edHint = 'arraste uma tela para o lugar - a linha do título move esta janela',
  edAll = 'todas', edScreens = 'Telas', edReset = 'Reiniciar a área', edDefault = 'Área padrão',
  edCopy = 'Copiar da 1', edDelete = 'Apagar a área',
  edPitOn = 'Área do BOX ligada', edPitOff = 'Área do BOX desligada',
  edPitWarning = 'Área do BOX desligada: nada mais aparece no pit lane - por sua conta',
  edButtons = 'Próxima tela %s - Tela anterior %s - Próxima área %s - Área anterior %s (controles do CSP)',
  edIndicator = 'ÁREA %d / %d - %s',
  menuButtons = 'Botões', navTitle = 'BOTÕES', navOwn = 'GRAVADO PELA FERRAMENTA', navCsp = 'CONTROLES DO CSP',
  navTabs = { nav = 'Navegação', screens = 'Abrir / fechar telas' },
  navNextScreen = 'Próxima tela', navPrevScreen = 'Tela anterior', navNextDesktop = 'Próxima área',
  navPrevDesktop = 'Área anterior', navShowPanel = 'Mostrar o painel (5 s)', navSet = 'Gravar', navClear = 'Limpar', navPress = 'Aperte um botão... %d s',
  navInUseAc = 'em uso pelo AC: %s - escolha outro', navInUseOwn = 'em uso por %s desta ferramenta - escolha outro',
  navButton = '%s - botão %d', navPov = '%s - D-pad %d graus', navGamepad = 'Controle %d - %s', navKey = 'Tecla %s',
  navDeviceOff = 'dispositivo desligado',
  navUp = 'Cima', navDown = 'Baixo', navLeft = 'Esquerda (valor -)', navRight = 'Direita (valor +)',
  navKeyNames = { [37] = 'Seta esquerda', [38] = 'Seta para cima', [39] = 'Seta direita', [40] = 'Seta para baixo' },
  menuSettings = 'Ajustes', menuRedFlag = 'Direção de prova',
  dirTitle = 'DIREÇÃO DE PROVA', dirRole = { director = 'DIRETOR', staff = 'EQUIPE', broadcast = 'TRANSMISSÃO - só leitura' },
  dirLogin = 'Login admin do KMR', dirLoginSent = 'Login enviado - esperando o KMR', dirLoginOk = 'Admin do KMR: conectado',
  dirNoAnswer = 'Sem resposta do KMR em 5 s - o login ou o comando falhou',
  dirFailed = 'Falhou: %s', dirSent = 'Enviado: %s - esperando o KMR', dirAnswer = 'KMR: %s',
  dirNextSession = 'PRÓXIMA SESSÃO', dirRestart = 'REINICIAR SESSÃO', dirCancelDt = 'SEM DT', dirToPit = 'AO BOX', dirFuel = 'COMBUSTÍVEL', dirMenu = 'MENU 5 MIN',
  setTitle = 'AJUSTES', setTabs = { messages = 'Mensagens', controls = 'Controles', text = 'Texto', design = 'Visual', app = 'App', room = 'Racing Room' },
  setFontSample = 'RACING CONTROL  P3  Reduza', setFontMissing = 'não instalada', setTextMin = 'Texto pequeno no mínimo', setTextMinOff = 'Desligado', setOpacity = 'Opacidade', setPreset = 'Predefinição',
  setPresets = { verbose = 'Completo', race = 'Corrida', minimal = 'Mínimo', custom = 'Personalizado' }, setAlways = 'sempre - no painel do Racing Control',
  setAreas = { rc = 'Racing Control, bandeiras, troca de piloto, diretor de prova', limits = 'Limites de pista e voltas inválidas',
    damage = 'Colisões e danos', points = 'Pontos e nota (KMR)', warnings = 'Avisos de comportamento',
    others = 'Penalidades de outros pilotos', results = 'Resultados e recordes da sessão', welcome = 'Boas-vindas e estatísticas',
    admin = 'Administração do servidor', chat = 'Chat dos pilotos', server = 'Outras mensagens do servidor',
    diag = 'Diagnóstico: mudanças no carro e o botão' },
  setAreaHint = { limits = 'volta invalidada', damage = 'Dano: -3p', points = 'prêmio, custo, saldo',
    warnings = 'retardatário, volta rápida, velocidade', others = 'KMR, diretor de prova', results = 'vencedor, pole, volta mais rápida',
    welcome = 'na entrada', admin = 'kick, ban, voto de pista', chat = 'na nossa janela', server = 'não a direção de prova', diag = 'faróis, limitador, motor, câmera' },
  setCtl = { on = 'Mostrar os controles do carro', elec = 'Eletrônica', engine = 'Motor e freios', hybrid = 'Híbrido',
    aero = 'Aero (DRS)', pit = 'Limitador do box' },
  setServer = 'Servidor', setCsp = 'CSP', setScript = 'Script', setApp = 'App', setRunning = 'rodando',
  msgTitle = 'MENSAGENS', setMissing = 'faltando', setChecking = 'conferindo', setAllGood = 'Tudo certo - fecha em %d s', setNotGood = 'Nem tudo certo - feche você',
  redTitle = 'CONTROLE DA BANDEIRA VERMELHA', redNone = 'sem bandeira vermelha', redConfirm = 'CONFIRMAR BANDEIRA VERMELHA', redVsc = 'RETOMAR VSC %d s',
  dirLightsRed = 'LUZES VERMELHAS', dirLightsGreen = 'LUZES VERDES', dirLightsAuto = 'LUZES AUTO',
  redGreen = 'VERDE', dirVsc = 'VSC %d s', dirMoney = 'ZERAR PONTOS', dirStats = 'ZERAR ESTAT.', dirBan = 'BANIR', dirUnban = 'DESBANIR', dirNoSg = 'SEM S&G', dirNoDsq = 'SEM DSQ',
  dirKmrLine = 'KMR  pontos %s / %d  -  segurança %s  -  %s  -  infrações %s (%s / 100 km)',
  dirPrompt = 'Comando', dirPromptSent = 'Enviado: %s', dirKmrCrashes = 'batidas %s (%s / 100 km)', dirBalRes = 'lastro %.0f kg  restritor %.0f', dirKmrLaps = '  -  voltas %d melhor %s', dirKmrNoStats = 'estatísticas: ainda nenhuma (pouco rodado)',
  dirKmrNone = 'KMR  ainda sem números deste piloto',
  dirPenNone = 'Penalidades  nenhuma', dirPenTitle = 'Penalidades  ', dirPenDt = '%s DT%d', dirPenSg = 'S&G %d s', dirPenDsq = 'DSQ',
  dirPenUnknown = 'Penalidades  ainda sem lista deste piloto',
  dirDriver = 'Piloto',
  dirWebLine = 'pontos %s - %s - infr %s (%s/100km) - batidas %s (%s/100km) - voltas %d melhor %s',
  dirWebOthers = 'Registrados no KMR',
  dirWebErr = 'Estatísticas do KMR na web não lidas: %s', dirWebOff = 'Estatísticas do KMR na web: chave kmrStatsUrl vazia', dirValue = 'Valor', dirBallast = 'LASTRO', dirRestrictor = 'RESTRITOR',
  kmrEvBtn = 'EVENTOS KMR', kmrEvTitle = 'EVENTOS KMR - CONTROLE DE PROVA DA SESSÃO', kmrEvConnecting = 'Conectando ao controle de prova do KMR...',
  kmrEvErr = 'Controle de prova do KMR fora de alcance: %s', kmrEvNone = 'Nenhum evento', kmrEvReplay = 'REPLAY', kmrEvBack = '< LISTA', kmrEvLoading = 'Carregando o replay do KMR...',
  kmrEvNoData = 'O KMR não deu replay deste evento', kmrEvPlay = 'PLAY', kmrEvPause = 'PAUSA', kmrEvToEvent = 'EVENTO', kmrEvGear = 'marcha',
  kmrEvLap = 'volta ', kmrEvReviewed = 'revisado ', kmrEvLast = 'ESTA SESSÃO', kmrEvAll = 'TODAS AS SESSÕES',
  kmrEvKinds = { collision = 'COLISÃO', cut = 'CORTE', generic = 'INFO', overtake = 'ULTRAPASSAGEM' },
  kmrEvFilters = { all = 'TODOS', collision = 'COLISÕES', cut = 'CORTES', generic = 'INFO' },
  dirNeedCarValue = 'Lastro / restritor: um piloto do servidor no campo e um valor', dirList = 'PILOTOS', dirListBtn = 'LISTA', dirCmdBtn = 'COMANDOS', dirCmdTitle = 'COMANDOS', dirCmdHow = 'Como: ', dirSessionTime = '%s decorrido / faltam %s',
  dirSessionLaps = 'volta %d', dirSessionLapsOf = 'volta %d / %d - faltam %d',
  dirLeft = 'Saiu do servidor', dirGuidAsk = 'Pedindo ao KMR o GUID de %s',
  dirGuidNone = 'O KMR não deu GUID para %s (o nome diferencia maiúsculas)', dirGuidGot = 'GUID de %s: %s',
  dirNoRed = 'Nem bandeira vermelha nem VSC ligados', redKmrOn = 'Admin do KMR: conectado', redKmrOff = 'Admin do KMR: digite /kmr login <senha> no chat',
  redPlace = 'vaga', redLane = 'pit lane', redTrack = 'pista',
  where = { menu = 'MENU (ESC)', box = 'BOX (LOBBY)', pit = 'BOX', pitlane = 'PIT LANE', grid = 'GRID', stopped = 'PARADO',
    track = 'PISTA' }, redCount = 'No box %d / %d - acima do limite %d',
  scrPerf = 'DESEMPENHO', perfRows = { fps = 'FPS', cpu = 'CPU', gpu = 'GPU' },
  scrCalc = 'CALCULADORA DE ESTRATÉGIA', calcNotCar = 'não enviado ao carro', calcFuel = 'Combustível/volta', calcWear = 'Desgaste/volta (pior pneu)',
  calcLap = 'Volta média', calcLaps = 'Voltas lançadas',
  calcNoData = 'sem dados', calcNoDataShort = 's/ dados', calcNeedFlying = 'Sem dados: %d de %d voltas lançadas', calcMissing = 'Sem dados: %s',
  calcParams = { race = 'Duração da prova', lap = 'Volta usada', tank = 'Tanque', reserve = 'Reserva (voltas)', pitloss = 'Perda no pit lane',
    refuel = 'Reabastecer', tyres = 'Troca de pneu (cada)' },
  calcRaceLaps = '%d voltas', calcHead = { 'CEN', 'DESG', 'LIM', 'L/V', 'PAR', 'V/ST', 'COMB/ST', 'PNEU', 'BOX', 'TOTAL' },
  calcFields = { wear = 'desgaste %/volta', limit = 'pneu até %', fuel = 'comb. L/volta', stops = 'paradas' },
  calcAuto = 'AUTO', calcNo = 'NÃO', calcBest = 'Melhor cenário: %s', calcNone = 'Nenhum cenário cabe no tanque e no pneu',
  scrCockpit = 'COCKPIT', cockpitCar = 'Ajustes deste carro: %s', cockpitSave = 'SALVAR', cockpitSaved = 'SALVO', cockpitNoApp = 'app não está rodando', cockpitMore = '+ TODOS', cockpitAudio = 'VOLUME - CADA CANAL',
  cockpitRows = { ffb = 'Force feedback', y = 'Banco cima / baixo', x = 'Banco esq. / dir.', z = 'Banco frente / trás', pitch = 'Inclin. cima / baixo',
    fov = 'Campo de visão', ['vol.main'] = 'Volume (geral)' },
  cockpitChannels = { engine = 'Motor', transmission = 'Transmissão', tyres = 'Pneus', surfaces = 'Superfícies', dirt = 'Terra',
    wind = 'Vento', opponents = 'Adversários', carComponents = 'Peças do carro', track = 'Pista', weather = 'Clima',
    rain = 'Chuva', wipers = 'Limpadores' },
  dirLogout = 'SAIR', dirLoggedOut = 'Desconectado nesta tela - o KMR não tem logout: ele esquece o login quando você sai do servidor',
  dirKmrLost = 'Login do KMR sem resposta - caiu: entre de novo',
  dirResetBtn = 'REINICIAR', dirReset = 'Janela reiniciada - campos, listas e posição de volta ao início; login do KMR conferido',
  connLap = 'VOLTA ', connSector = 'S%d', connSpline = 'SPL %.3f', connPing = 'PING %d ms', connPingNone = 'PING -',
  connOk = 'CONEXÃO OK', connHigh = 'PING ALTO', connKick = 'KICK DO KMR PROVÁVEL - média %.0f / desvio %.0f ms', connStalled = 'DADOS PARADOS - QUEDA PROVÁVEL',
  connAlert = 'ALERTA  ', connAlertCar = '#%s %s: %s',
  connPitTitle = 'BOX  ', connStopped = 'parado na vaga %s', connOutAfter = 'piloto saiu %s depois da parada',
  connOutNoStop = 'piloto saiu longe da vaga', connSwapTime = 'tempo de troca %s / %s',
  connBackSame = 'o mesmo piloto voltou depois de %s (tempo de troca %s)', connBackOther = 'piloto novo entrou depois de %s (tempo de troca %s)',
  connInTime = 'dentro do tempo de troca', connLate = 'depois do tempo de troca',
  connCause = { pitPlace = 'saiu na vaga', menu = 'ESC / menu - saiu da sessão', lost = 'conexão perdida',
    pingHigh = 'kick do KMR - ping alto', pingUnstable = 'kick do KMR - ping instável', kick = 'kick',
    unknown = 'saiu - sem menu visto, conexão boa' },
  connGoneTitle = 'SAIU DO SERVIDOR', connLeft = 'saiu', connTitle = 'Conexão', connLog = '%s saiu do servidor - %s',
  lobbyTitle = 'RACING CONTROL', lobbyStops = 'Paradas', lobbyKmr = 'Pontos / nota KMR', lobbyWeather = 'Ar / pista',
  lobbyMessages = 'MENSAGENS', lobbyWindow = 'Racing Control - lobby',
  scrShare = 'RACING ROOM', shareOn = 'TELA DO JOGO COMPARTILHADA', shareOff = 'TELA DO JOGO NÃO COMPARTILHADA', shareHint = '< desl.   lig. >',
  ownOn = 'MINHAS TELAS À MINHA VISTA', ownOff = 'MINHAS TELAS ESCONDIDAS DE MIM', ownHint = 'Escondidas: menos tráfego e carga; os outros continuam vendo',
  focusOn = 'FOCO LIGADO', focusOff = 'FOCO DESLIGADO', focusWith = 'Falando com você: %s', focusNobody = 'Escolha quem fala com você', focusHint = 'Só uma pessoa fala com você',
  focusNoRoom = 'Foco: Racing Room numa sala privada',
  rrRoom = '%s - %s', rrNone = 'Não conectado - sem voz/vídeo', rrOther = 'Em outro PC - sem voz/vídeo',
  rrOffline = 'Base do evento não responde', shareAsking = 'Pedindo ao Racing Room...', shareSent = 'Pedido - o Racing Room está abrindo a captura',
  shareNoRoom = 'Racing Room fora de uma sala - abra uma sala lá', shareNoAnswer = 'O Racing Room não compartilhou a tela do jogo',
  shareFailed = 'Não compartilhada: %s', rrNoRoom = 'Fora de uma sala - sem voz/vídeo', rrWait = 'Conferindo...',
  rrAreas = { pitwall = 'Mureta', anteroom = 'Antessala', control = 'Sala de controle', individual = 'Sala particular', workshop = 'Oficina' },
  lobbyRc = 'RACING CONTROL', lobbyAccount = 'Conta', lobbyRegistration = 'Cadastro', lobbyBase = 'Base do evento',
  lobbyApp = 'App do Racing Control', lobbyRoom = 'Racing Room', lobbyShare = 'Tela do jogo', lobbyOk = 'ok', lobbyMissing = 'faltando: %s',
  lobbyOnline = 'online', lobbyOffline = 'offline', lobbyRunning = 'rodando', lobbyNotRunning = 'não está rodando', lobbyShared = 'compartilhada',
  lobbyNotShared = 'não compartilhada', lobbyOff = 'não usado neste servidor',
  setShareSource = 'Fonte', setShareLayout = 'Telas', setShareVr = 'VR: janela do jogo (o espelho do óculos no PC)',
  setShareSources = { game = 'Janela do jogo', screen1 = 'Tela 1', screen2 = 'Tela 2', screen3 = 'Tela 3' },
  setShareLayouts = { single = 'Única', triple = 'Tripla (todas)', center = 'Tripla (meio)' },
  setShareScope = 'Mostrar em', setShareScopes = { all = 'Toda sala com Telas', room = 'Só a sua sala' },
  setShareGo = 'COMPARTILHAR A TELA DO JOGO', setShareStop = 'PARAR DE COMPARTILHAR',
  menuDesktops = 'Áreas', menuAudit = 'Auditoria', auditTitle = 'AUDITORIA', auditPoints = 'Pontos KMR %d / %d',
  auditRating = 'Nota KMR %s',
  auditCount = '%d mensagens', auditEmpty = 'Nenhuma mensagem nesta sessão',
  edStrip = 'CONTROLES - MENSAGENS (quando houver)', edFlagStrip = 'BANDEIRAS (quando houver)', edPin = 'Fixar em todas', edPinned = 'Em todas as áreas', edMode = 'Modo: %s', edRemove = 'Remover',
  edChoose = 'Clique numa tela para escolher e arraste para o lugar',
  screenNames = { pitbox = 'Parada no box', setup = 'Setup', status = 'Estado do carro', race = 'Situação da prova', laps = 'Voltas',
    standings = 'Classificação', relative = 'Relativo', laptime = 'Tempo de volta', delta = 'Delta', event = 'Evento',
    weather = 'Clima', map = 'Mapa da pista', telemetry = 'Telemetria', share = 'Racing Room', cockpit = 'Cockpit', perf = 'Desempenho',
    calc = 'Calculadora de estratégia' },
  scrTelemetry = 'TELEMETRIA',
  teleChannels = { thr = 'ACEL', brk = 'FREIO', clu = 'EMBR', str = 'DIR', spd = 'VEL', gear = 'MARCHA', glat = 'G LAT', glon = 'G LON' },
  teleShort = { thr = 'A', brk = 'F', clu = 'E', str = 'D', spd = 'V', gear = 'M', glat = 'X', glon = 'Z' },
  scrClassSel = '< CLASSE: %s >', scrLapsCar = 'VOLTAS - CARRO #%s', scrLapsMore = 'MAIS', scrLapsLess = 'MENOS',
  scrCompare = 'COMPARAR', scrDriverSel = '< PILOTO: %s >', scrStintShort = 'ST %d', scrMap = 'MAPA DA PISTA', scrNoMap = 'Sem mapa desta pista',
  scrMapLegend = { 'amarelo você - azul volta à frente - bege volta atrás', 'cinza box - vermelho parado' },
  scrWeather = 'CLIMA / PISTA', scrWeatherModes = { forecast = 'PREVISÃO', map = 'RADAR' }, scrRadarZoom = '%g KM', scrRadarBig = '+', scrRadarSmall = '-',
  scrRadarPrec = 'PRECIPITAÇÃO', scrRadarLight = 'leve', scrRadarHeavy = 'forte', scrRadarExtreme = 'extrema', scrRadarClouds = 'nuvens: branca = leve, cinza = densa',
  scrRadarLoop = '%s - 1 hora em 6 segmentos de 10 min, um por segundo', scrRadarNoTrack = 'Sem a linha da IA nesta pista',
  scrWeatherAnim = 'previsão em segmentos de 10 min', scrWeatherStatic = 'sem previsão', scrWxPage = '< %d/%d >',
  scrWxTime = 'Hora local', scrWxSky = 'Céu', scrWxAir = 'Ar / pista', scrWxWind = 'Vento', scrWxRain = 'Chuva', scrWxNext = 'Próximo',
  scrEvent = 'EVENTO', scrEventInfo = 'informações', evStops = 'Paradas exigidas', evSwaps = 'Trocas de piloto exigidas',
  evStint = 'Stint', evOrder = 'Ordem da parada', evPitSpeed = 'Velocidade no pit lane', evRating = 'Nota KMR',
  flagRed = 'BANDEIRA VERMELHA',
  flagRedLine = 'Reduza - sem ultrapassar - complete a volta na pista, depois o box',
  flagRedNeutral = 'Prova neutralizada pelo Racing Control',
  flagRedSpeed = 'Máx %d km/h - você: %.0f km/h',
  redFlagLineDsq = 'Cruzou a linha no pit lane com a bandeira vermelha (saindo do box)',
  flagRedGrace = 'Sem ultrapassar daqui em diante - %d s', flagRedToLine = 'Complete a volta: cruze a linha na pista',
  flagRedToBox = 'Bandeira vermelha recebida - vá para a sua vaga',
  redFlagLineAgainDsq = 'Cruzou a linha de novo com a bandeira vermelha - não foi ao box',
  redFlagPassDsq = 'Ultrapassagem com a bandeira vermelha (%s)',
  redFlagSpeedSG = 'CODE-65: acima de %d km/h por mais de %d s com a bandeira vermelha', yellowPassSG = 'Ultrapassagem sob bandeira amarela (%s) não devolvida',
  flagGiveBack = 'DEVOLVA A POSIÇÃO A %s - %d s', sgFlagGiven = 'Stop & go %d s - %s',
  yellowGivenBack = 'Posição devolvida a %s',
  flagCode80 = { VSC = 'VIRTUAL SAFETY CAR', SC = 'SAFETY CAR', ['CODE-80'] = 'AMARELA NA PISTA TODA' },
  flagCode80Line = 'Pista toda - sem ultrapassar',
  flagRaceControl = 'Racing Control',
  flagYellow = 'BANDEIRA AMARELA',
  flagYellowLine = 'Reduza - sem ultrapassar',
  flagIncidentAhead = '%s %s a %.0f m',
  flagIncident = { stopped = 'parado', broken = 'quebrado', oil = 'motor estourado' },
  flagCausedBy = 'Incidente - %s',
  flagWhite = 'BANDEIRA BRANCA',
  flagWhiteLine = 'Carro lento à frente',
  flagSlowAhead = '%s - %.0f m - %.0f km/h',
  flagSlippery = 'PISTA ESCORREGADIA',
  flagOil = 'Óleo na pista',
  flagOilCar = '%s motor estourado',
  flagWet = 'Pista molhada',
  flagBlue = 'BANDEIRA AZUL',
  flagBlueLine = 'Carro mais rápido atrás - deixe passar',
  flagLastLap = 'ÚLTIMA VOLTA',
  flagLastLapLine = 'Falta uma volta',
  flagGreen = 'BANDEIRA VERDE',
  flagGreenLine = 'Pista livre - corrida', flagStart = 'BANDEIRA VERDE - VAI VAI', flagStartLine = 'Largada lançada - corrida',
  startTitle = 'LARGADA LANÇADA - VOLTA DE APRESENTAÇÃO', startLimits = 'Máx %d / mín %d km/h - sem ultrapassar',
  startNoOvertake = 'Sem ultrapassar antes da bandeira verde', startRelease = 'Limite de velocidade desligado - largue quando o líder cruzar a linha',
  startWaiting = 'A volta de apresentação vai começar', startNoPlace = 'Mantenha a posição',
  startPlace = 'P%d - fique atrás de %s', startLeader = 'ninguém: você lidera', startBehindYou = ' - %s atrás de você',
  osTitle = 'LARGADA', osLocked = 'Controles travados até %s', osLockedLight = 'luz %d',
  gameDtTaken = 'Drive-through do jogo retirado - o Racing Control decide a penalidade',
  startPassedBy = ' - %s passou você', startGiveBack = 'DEVOLVA A POSIÇÃO A %s', startPassAllowed = 'P%d - %s pode ser ultrapassado (KMR)',
  flagRedLocked = 'Fique na sua vaga - controles travados até a relargada',
  ssTitle = 'LARGADA PARADA', dirStart = 'LARGAR', fmTitle = 'VOLTA DE APRESENTAÇÃO', fmEnd = 'Fim da volta de apresentação - pare no seu lugar do grid',
  fmToGrid = 'Grid P%d - pare no seu lugar', fmAligned = 'Grid P%d - no seu lugar, controles travados',
  fmCountdown = 'Largada em %s', fmCountdownLine = 'A volta de formação abre na liberação do jogo',
  fmPitStart = 'Largada do pit lane, depois do pelotão', fmPlace = 'P%d - fique atrás de %s',
  fmGiveBack = 'Devolva a posição a %s - %d s', fmGivenBack = 'Posição devolvida a %s',
  fmMissedStart = 'Fora do lugar do grid quando as luzes da largada começaram',
  srTitle = 'RELARGADA PARADA', srGrid = 'Grid P%d - controles travados', srGridFree = 'Grid P%d', srGridSoon = 'Grid em %d s - fique na sua vaga',
  srSwap = 'Troca de piloto: saia do pit lane na verde', srLightsIn = 'Luzes em %d s', srLights = 'Luzes %d / %d',
  srFree = 'Controles livres - não se mova antes de as luzes apagarem', srGo = 'BANDEIRA VERDE - VAI VAI',
  srGoLine = 'Relargada parada', srCancelled = 'Relargada parada cancelada - bandeira vermelha',
  srGridLocked = 'Fique no grid - controles travados', srNoNode = 'sem lugar de grid AC_START_%d nesta pista',
  dirStanding = 'RELARGADA PARADA', dirStandingOff = 'CANCELAR RELARGADA',
  flagRestart = 'Relargada P%d - atrás de %s', flagRestartFirst = 'Relargada P%d - primeiro carro',
  flagRestartSwap = 'Relargada P%d - troca de piloto: fim do pelotão, atrás de %s',
  appMissing = 'App do Racing Control não está rodando - instale pela página do evento - o jogo fecha em %d s',
  cspOld = 'CSP 4130 exigido - instale pelo app das 12h - o jogo fecha em %d s',
  teamSetup = 'Setup da sua equipe: %s - abra o menu de setup no box para aplicar ou recusar',
  remotePitStart = 'Sua equipe iniciou a parada pelo Racing Room: pare na sua vaga',
  realNameMissing = 'Cadastro incompleto - você não pode participar desta sessão - falta: %s - complete no app das 12h Curitiba',
  realNameWhat = { cadastro = 'cadastro', steam = 'conta Steam confirmada', nome = 'nome verdadeiro' },
  realNameOffline = 'Cadastro não confirmado - a base do evento não responde - espere por ela antes de a sessão começar',
  redTowDeferred = 'Reboque sob bandeira vermelha: o tempo de reboque e reparo começa na relargada',
  redNoLineSG = 'Entrada no box com a bandeira vermelha não recebida na linha', redFuelUnlocked = 'Combustível liberado pelo Racing Control',
  menuFree = 'Menu do jogo livre por %d min - ajuste e prepare-se', menuFreeOff = 'Menu do jogo fechado de novo',
  redFlagNoPitDsq = 'Fora do box na relargada depois da bandeira vermelha',
  flagChequered = 'BANDEIRA QUADRICULADA', flagChequeredMine = 'Sessão encerrada para você', flagChequeredPos = 'P%d - %d voltas',
  flagTimeOver = 'TEMPO DA SESSÃO ESGOTADO', flagRaceOver = 'PROVA ENCERRADA', flagFinishLap = 'Termine sua volta - a quadriculada está na linha',
  flagChequeredLine = 'Sessão encerrada',
  relPit = '  BOX',
  hdr = { pos = 'P', classPos = 'CL', driver = 'PILOTO', class = 'CLASSE', laps = 'VLT', gap = 'DIF', int = 'INT', best = 'MELHOR', pit = 'BOX',
    sr = 'SR', pts = 'PTS', time = 'TEMPO', sky = 'CÉU', air = 'AR', track = 'PISTA', avg = 'MÉDIA', lap = 'VOLTA', delta = 'DELTA', precip = 'PRECIP.' },
  wxProb = '%d%%',
  lapsShort = '%d V', lapTag = { cut = 'corte', pit = 'box', best = 'melhor' },
  wxSky = { clear = 'Céu limpo', few = 'Poucas nuvens', scattered = 'Nuvens esparsas', broken = 'Nublado', overcast = 'Encoberto', thunder = 'Tempestade' },
  wxPrecip = { lightDrizzle = 'garoa fraca', drizzle = 'garoa', lightRain = 'chuva fraca', rain = 'chuva', heavyRain = 'chuva forte', violentRain = 'chuva violenta' },
  compass = { 'N', 'NNE', 'NE', 'ENE', 'L', 'ESE', 'SE', 'SSE', 'S', 'SSO', 'SO', 'OSO', 'O', 'ONO', 'NO', 'NNO' },
  wxBulletin = { now = '%s agora: %s, ar %d°C, pista %d°C, vento %s %s.', rain = 'Precipitação esperada a partir de %s (%s), %d%% de chance, até %.2f mm/h.',
    dry = 'Sem precipitação esperada.', by = 'Até %s: %s%s, ar %d°C, pista %d°C; vento %s %s.', falling = 'Temperatura da pista caindo %d°C: menos aderência esperada.',
    rising = 'Temperatura da pista subindo %d°C.' },
  wxWindFmt = '%.0f km/h %03.0f°', wxRainFmt = '%.0f%% - molhada %.0f%%', wxGripFmt = 'aderência %.0f%%',
  evStintFmt = 'mín %d - máx %d min', evRatingFmt = 'DSQ em %s', posClassFmt = ' - classe P%d %s',
  tyreLapsFmt = '%d voltas%s', trackGripFmt = '%s - aderência %d%%', trackWet = 'MOLHADA', trackDry = 'SECA',
  edPitTag = 'BOX',
  ctlGroup = { elec = 'ELETRÔNICA', engine = 'MOTOR - FREIOS', hybrid = 'HÍBRIDO' },
  ctlBox = { aero = 'AERO', drs = 'DRS', open = 'ABERTO', closed = 'FECHADO', pit = 'BOX', limiter = 'LIMITADOR', on = 'LIG', off = 'DESL',
    recov = 'RECUP.', batt = 'BATERIA', motor = 'MOTOR' },
  dirNoData = 'sem dados', kmrEvNoAnswer = 'sem resposta',
  dirChip = { dt = 'DT', kick = 'KICK', ban60 = 'BAN 60', dsq = 'DSQ' },
  dirAct = { money = 'zerar pontos', stats = 'zerar estatísticas', ban = 'banir', unban = 'desbanir', ballast = 'lastro kg', restrictor = 'restritor',
    dt = 'DT %s', cancelDt = 'cancelar DT %s', relaxSg = 'retirar S&G %s', kick = 'kick %s', ban60 = 'ban 60 min %s', toPit = 'ao box %s',
    dsq = 'DSQ %s', relaxDsq = 'retirar DSQ %s', fuel = 'combustível liberado %s', menu = 'menu livre %s' },
  wheelCode = { FL = 'DE', FR = 'DD', RL = 'TE', RR = 'TD', F = 'D', R = 'T' },
  wheelNames = { [0] = 'dianteira esquerda', 'dianteira direita', 'traseira esquerda', 'traseira direita' }, bodySides = { [0] = 'dianteira', 'traseira', 'esquerda', 'direita' },
  side = { front = 'F', back = 'T', left = 'E', right = 'D' },
  dtLine = '%s - Drive-through - %s', holdTowRepair = 'Reboque %s + Reparo %s', holdRepair = 'Reparo %s', dirDsqNotice = 'Desclassificado - %s',
  dsqWhy = { repairNotDone = 'Reparo obrigatório não feito', sgInterrupted = 'Stop & go interrompido', swapPending = 'Troca de piloto com penalidades pendentes',
    pitClosed = 'Saiu do pit lane com o pit fechado', slowdown = '%s - slowdown não cumprido' },
  cmdHelp = {
    rc = { title = 'RACING CONTROL', how = 'Chat do KMR: /kmr admin_say RC ... (os botões desta janela) - live timing do ACSM: Chat ao piloto ou Broadcast Chat', rows = {
      'limpa a lista: drive-throughs, stop & go e slowdowns',
      'retira o primeiro item da lista',
      'retira o stop & go (botão SEM S&G)',
      'cancela o slowdown em andamento',
      'encerra a retenção (ou reboque / reparo) e libera os controles',
      'retira o reparo obrigatório (bandeira preta com disco laranja)',
      'cancela a desclassificação e libera os controles (botão SEM DSQ)',
      'libera os controles e encerra a retenção (lista e DSQ mantidos)',
      'drive-through em até as voltas (0 = nesta volta)',
      'retenção: o carro travado na vaga',
      'o carro ao box, com o dano mantido (botão AO BOX)',
      'desclassificação pelo Racing Control (botão DSQ)',
      'trava os controles (até 86400 s)',
      'combustível liberado sob bandeira vermelha (botão COMBUSTÍVEL)',
      'o carro pede de novo os números do KMR',
      'o menu do jogo de volta para esse piloto (5 min; até 60; 0 encerra) (botão MENU 5 MIN)',
      'bandeira vermelha para todos (botão BANDEIRA VERMELHA)',
      'fim da bandeira vermelha: relargada lançada sob VSC',
      'relargada parada, com a bandeira vermelha (botão RELARGADA PARADA)',
      'cancela a relargada parada antes da verde',
      'pista verde na hora: bandeira vermelha abaixada, CODE-80 encerrado (botão VERDE)',
      'luzes de saída do box e de largada da pista em vermelho (botão LUZES VERMELHAS)',
      'luzes de saída do box e de largada da pista em verde (botão LUZES VERDES)',
      'luzes da pista de volta ao estado da pista (botão LUZES AUTO)' } },
    kmr = { title = 'KMR', how = 'Chat do KMR: /kmr login <senha> uma vez, depois /kmr <comando> - ou o console do KMR' },
    server = { title = 'SERVIDOR DO AC (ACSM)', how = 'Chat: /admin <senha> uma vez, depois o comando - ou /kmr admin_send_command /<comando> - ou ACSM Admin Command', rows = {
      'entra como admin do servidor (chat)',
      'lista dos comandos do servidor',
      'vai para a próxima sessão',
      'reinicia a sessão atual',
      'IDs dos carros com os nomes dos pilotos',
      'kick do piloto pelo nome',
      'kick do piloto pelo ID do carro',
      'bane o piloto pelo nome',
      'bane o piloto pelo ID do carro',
      'lastro no carro (botão LASTRO)',
      'restritor no carro (botão RESTRITOR)' } },
    player = { title = 'JOGADORES NO KMR', how = 'Qualquer piloto no chat, sem barra: kmr <comando>' },
  },
}
local function LANG_PACK(t)
  local out = {}
  local function esc(v) return (tostring(v):gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('\t', '\\t')) end
  local function walk(tb, path)
    local keys = {}
    for k in pairs(tb) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(keys) do
      local v = tb[k]
      local name = type(k) == 'number' and ('#' .. k) or (tostring(k):gsub('[%%%.#]', function(c) return string.format('%%%02X', c:byte()) end))
      local at = path == '' and name or (path .. '.' .. name)
      if type(v) == 'table' then walk(v, at)
      else out[#out + 1] = at .. '\t' .. (type(v) == 'number' and 'n' or 's') .. esc(v) end
    end
  end
  walk(t, '')
  return table.concat(out, '\n')
end
local LANG_EVENT, LANG_STORE, LANG_OK = 'amxracing.race-control.lang', '.amxracing.race-control.lang', 'amxracing.race-control.lang.ok'
local function winLocale()
  local before = os.setlocale(nil, 'collate')
  local name = os.setlocale('', 'collate')
  os.setlocale(before or 'C', 'collate')
  return name
end
local okLocale, WIN_LOCALE = pcall(winLocale)
local WIN_WHY = okLocale and 'Windows' or tostring(WIN_LOCALE)
if not okLocale then WIN_LOCALE = nil end
local LANG = (type(WIN_LOCALE) == 'string' and (WIN_LOCALE:lower():match('^portuguese') or WIN_LOCALE:lower():match('^pt'))) and 'pt' or 'en'
local LANG_TEXT = LANG == 'pt' and LANG_PACK(LANG_PT) or ''
ac.log(string.format('race-control app: language %s (locale: %s, %s), %d characters for the online script', LANG, tostring(WIN_LOCALE), WIN_WHY,
  #LANG_TEXT))
local APP_TEXTS = {
  en = { loading = 'RACING CONTROL - LOADING', waiting = 'Waiting for the Racing Control of the event - please wait (the game closes in %d s if it does not load)',
    pingUnknown = 'Connection: ping not known yet', pingHigh = 'Connection problem: ping %d ms, over the limit of %d ms of the server - check your internet',
    pingUnstable = 'Connection problem: unstable ping (%d ms, varying %d ms) - check your internet', pingOk = 'Connection: ping %d ms',
    held = '%d messages held for the Racing Control', notRunning = 'RACING CONTROL NOT RUNNING',
    notRunningText = 'The online script of the event did not start - the game closes in %d s. Tell the organizer.',
    teamSetup = 'Setup from your team: %s', apply = 'Apply', refuse = 'Refuse' },
  pt = { loading = 'RACING CONTROL - CARREGANDO', waiting = 'Esperando o Racing Control do evento - aguarde (o jogo fecha em %d s se ele não carregar)',
    pingUnknown = 'Conexão: ping ainda desconhecido', pingHigh = 'Problema de conexão: ping %d ms, acima do limite de %d ms do servidor - confira sua internet',
    pingUnstable = 'Problema de conexão: ping instável (%d ms, variando %d ms) - confira sua internet', pingOk = 'Conexão: ping %d ms',
    held = '%d mensagens retidas para o Racing Control', notRunning = 'RACING CONTROL NÃO ESTÁ RODANDO',
    notRunningText = 'O script online do evento não começou - o jogo fecha em %d s. Avise a organização.',
    teamSetup = 'Setup da sua equipe: %s', apply = 'Aplicar', refuse = 'Recusar' },
}
local function T(key) return APP_TEXTS[LANG][key] end
do
  local root = ac.getFolder(ac.FolderID.Root)
  local from = root .. '\\apps\\lua\\race-control\\fonts'
  local to = root .. '\\content\\fonts'
  for _, name in ipairs(io.scanDir(from, '*.ttf') or {}) do
    local src, dst = from .. '\\' .. name, to .. '\\race-control-' .. name
    if io.fileSize(dst) ~= io.fileSize(src) then io.copyFile(src, dst, false) end
  end
end
local MANIFEST_URL = 'https://api.12hcuritiba.com/manifest'
local SERVER_KEY = 'rc.server'
local LEARNED_KEY = 'rc.serverSeen'
local active = false
local starts = {}
local function hereId()
  if not ac.getSim().isOnlineRace then return nil end
  local okI, ip = pcall(ac.getServerIP)
  local okP, port = pcall(ac.getServerPortHTTP)
  if not okI or type(ip) ~= 'string' or ip == '' or not okP or tonumber(port) == nil or tonumber(port) < 0 then return nil end
  return ip .. ':' .. math.floor(tonumber(port))
end
local HERE = hereId()
local function onOurServer(fn) starts[#starts + 1] = fn end
local function activate(why)
  if active then return end
  active = true
  ac.log('race-control app: server of the event (' .. tostring(HERE) .. ', ' .. why .. '): the app acts')
  for _, fn in ipairs(starts) do fn() end
end
local GUI_ITEMS = { { 'hideRaceFlagsBefore', 'HIDE', 'HIDE_RACE_FLAGS', 1, 0 },
  { 'hideIconMANUAL_PIT_LIMITER', 'HIDE_ICONS', 'MANUAL_PIT_LIMITER', 1, 0 }, { 'hideIconPIT_LIMITER_WARNING', 'HIDE_ICONS', 'PIT_LIMITER_WARNING', 1, 0 },
  { 'extraHudPIT_SPEED_LIMIT', 'EXTRA_HUD_ELEMENTS', 'PIT_SPEED_LIMIT', 0, 1 }, { 'extraHudMANUAL_PIT_SPEED_LIMITER', 'EXTRA_HUD_ELEMENTS', 'MANUAL_PIT_SPEED_LIMITER', 0, 1 },
  { 'extraHudWARN_ABOUT_MANUAL_LIMITER', 'EXTRA_HUD_ELEMENTS', 'WARN_ABOUT_MANUAL_LIMITER', 0, 1 } }
local function guiIni() return ac.INIConfig.load(ac.getFolder(ac.FolderID.ExtCfgUser) .. '\\gui.ini') end
onOurServer(function()
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
end)
local function guiRestore()
  local ini = guiIni()
  for _, it in ipairs(GUI_ITEMS) do
    local before = ac.storage[it[1]]
    if before ~= nil then
      local now = ini:get(it[2], it[3], it[5])
      if tonumber(now) == it[4] and tonumber(before) ~= it[4] then
        ini:setAndSave(it[2], it[3], tonumber(before))
        ac.log('race-control app: not the server of the event: ' .. it[2] .. ' ' .. it[3] .. ' back to ' .. tostring(before))
      end
      ac.storage[it[1]] = nil
    end
  end
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
  line(T('loading'), 'Segoe UI;Weight=Bold', 14, 6, rgbm(0.96, 0.96, 0.96, 1))
  line(string.format(T('waiting'), left + CLOSE_SECONDS),
    'Segoe UI;Weight=SemiBold', 11, 28, rgbm(1, 0.85, 0.25, 1))
  local ping
  if not now or now < 0 then ping = T('pingUnknown')
  elseif high then ping = string.format(T('pingHigh'), now, guard.pingLimit)
  elseif unstable then ping = string.format(T('pingUnstable'), now, math.floor(dev + 0.5))
  else ping = string.format(T('pingOk'), now) end
  line(ping, 'Consolas', 11, 50, bad and rgbm(1, 0.3, 0.3, 1) or rgbm(0.6, 0.63, 0.65, 1))
  line(string.format(T('held'), guard.swallowed), 'Consolas', 10, 68, rgbm(0.6, 0.63, 0.65, 1))
end
onOurServer(function()
  if tostring(ac.getTrackID() or ''):lower() ~= TRACK_ID then return end
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
    ac.setMessage(T('notRunning'), string.format(T('notRunningText'), left), 'illegal', 1.5)
    pcall(physics.lockUserControlsFor, 3)
    if left <= 0 then
      closed = true
      ac.shutdownAssettoCorsa()
    end
  end, 1)
end)
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
  if ok and p then out[#out + 1] = string.format('x=%.4f;y=%.4f;z=%.4f;pitch=%.2f', p.position.x, p.position.y, p.position.z, p.pitch) end
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
      elseif item == 'x' or item == 'y' or item == 'z' or item == 'pitch' then
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
onOurServer(function()
  if tostring(ac.getTrackID() or ''):lower() ~= TRACK_ID then return end
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
end)
ac.onSharedEvent(COCKPIT_REQUEST, function(data, senderName, senderType)
  if not active or senderType ~= 'server_script' then return end
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
    elseif item == 'x' or item == 'y' or item == 'z' or item == 'pitch' then
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
local langStored, langTold = false, false
ac.onSharedEvent(LANG_OK, function(data, senderName, senderType)
  if senderType ~= 'server_script' or langTold then return end
  langTold = true
  ac.log('race-control app: language ' .. tostring(data) .. ' taken by the online script')
end)
ac.onSharedEvent(APP_REQUEST, function(data, senderName, senderType, senderID)
  if senderType ~= 'server_script' then
    ac.log('race-control app: preset request ignored, sender ' .. tostring(senderName) .. ' / ' .. tostring(senderType))
    return
  end
  if not active and HERE then
    ac.storage[LEARNED_KEY] = HERE
    activate('online script of the event')
  end
  if not active then return end
  heard = true
  if guard.on then guardEnd('online script running, ' .. guard.swallowed .. ' messages held') end
  if not langTold then
    if not langStored then
      langStored = true
      ac.store(LANG_STORE, LANG_TEXT)
    end
    ac.broadcastSharedEvent(LANG_EVENT, LANG)
  end
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
  if not active or senderType ~= 'server_script' then
    ac.log('race-control app: setup values ignored, sender ' .. tostring(senderName) .. ' / ' .. tostring(senderType) .. (active and '' or ', not the server of the event'))
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
onOurServer(function()
  if tostring(ac.getTrackID() or ''):lower() ~= TRACK_ID then return end
  setTimeout(function() keepSetup('load') end, 3)
  setInterval(function() keepSetup() end, SETUP_SECONDS)
  if ac.onSetupFile then ac.onSetupFile(function(op) keepSetup(tostring(op)) end) end
end)
local PUSH_STORE, PUSH_DONE = '.amxracing.race-control.setuppush', '.amxracing.race-control.setuppush.done'
local PUSH_TOLD_SECONDS = 15
onOurServer(function()
  if tostring(ac.getTrackID() or ''):lower() ~= TRACK_ID then return end
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
    local toast = ui.toast(ui.Icons.Wrench, string.format(T('teamSetup'), name) .. '###rc-team-setup')
    toast:button(ui.Icons.Confirm, T('apply'), function()
      if push.answered[id] then return end
      local ok, res = pcall(ac.loadSetup, ini)
      if ok and res then answer(id, 'aplicado', '')
      else answer(id, 'falhou', ok and 'refused by the game: not in the setup menu or the setup is fixed' or tostring(res)) end
    end)
    toast:button(ui.Icons.Cancel, T('refuse'), function()
      if not push.answered[id] then answer(id, 'recusado', 'refused by the driver') end
    end)
  end, 1)
end)
local function idOf(body)
  local s = tostring(body or '')
  local ip = s:match('"server"%s*:%s*{.-"ip"%s*:%s*"([^"]+)"')
  local port = s:match('"server"%s*:%s*{.-"httpPort"%s*:%s*"?(%d+)"?')
  return ip and port and (ip .. ':' .. port) or nil
end
local kept, learned = ac.storage[SERVER_KEY], ac.storage[LEARNED_KEY]
if HERE and (kept == HERE or learned == HERE) then activate(kept == HERE and 'manifest kept from the last load' or 'last server where the online script spoke') end
if not ac.getSim().isOnlineRace then guiRestore() end
if HERE and web and web.get then
  web.get(MANIFEST_URL, function(err, res)
    local id = not err and res and tonumber(res.status) == 200 and idOf(res.body) or nil
    if not id then
      ac.log('race-control app: manifest of the base not read (' .. tostring(err or (res and res.status)) .. ')')
      return
    end
    if ac.storage[SERVER_KEY] and ac.storage[SERVER_KEY] ~= id then ac.storage[LEARNED_KEY] = nil end
    ac.storage[SERVER_KEY] = id
    if id == HERE then activate('manifest of the base')
    elseif not active and ac.storage[LEARNED_KEY] ~= HERE then
      ac.log('race-control app: not the server of the event (' .. HERE .. '): nothing acts')
      guiRestore()
    end
  end)
end
