-- 로비 시스템 (서버)
local autoStartTimer = 0
local autoStartActive = false

-- 로비 업데이트
RegisterServerEvent('bumbercar:server:updateLobby')
AddEventHandler('bumbercar:server:updateLobby', function()
    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        return
    end

    local lobbyData = {
        players = {},
        currentMap = BumberCar.CurrentMap,
        currentGameMode = BumberCar.CurrentGameMode,
        maps = {},
        gameModes = {}
    }

    -- 플레이어 목록
    for playerId, playerData in pairs(BumberCar.Players) do
        table.insert(lobbyData.players, {
            id = playerId,
            name = playerData.name,
            ready = playerData.ready,
            spectating = playerData.spectating
        })
    end

    -- 맵 목록
    for mapId, mapData in pairs(Config.Maps) do
        table.insert(lobbyData.maps, {
            id = mapId,
            name = mapData.name,
            description = mapData.description,
            icon = mapData.icon
        })
    end

    -- 게임 모드 목록
    local gameModes = {
        {id = Constants.GameMode.ITEM_FFA, name = '아이템전 (개인전)', description = '아이템을 사용하여 싸우는 개인전'},
        {id = Constants.GameMode.ITEM_TEAM, name = '아이템전 (팀전)', description = '아이템을 사용하여 싸우는 팀전'},
        {id = Constants.GameMode.CLASSIC_FFA, name = '노아이템전 (개인전)', description = '아이템 없이 싸우는 개인전'},
        {id = Constants.GameMode.CLASSIC_TEAM, name = '노아이템전 (팀전)', description = '아이템 없이 싸우는 팀전'},
        {id = Constants.GameMode.BOMB_FFA, name = '폭탄 건내기 (개인전)', description = '폭탄을 넘기는 개인전'},
        {id = Constants.GameMode.BOMB_TEAM, name = '폭탄 건내기 (팀전)', description = '폭탄을 넘기는 팀전'},
        {id = Constants.GameMode.BOSS, name = '보스 모드', description = '한 명의 보스 vs 나머지 플레이어'}
    }
    lobbyData.gameModes = gameModes

    -- 모든 플레이어에게 업데이트
    TriggerClientEvent('bumbercar:client:lobbyUpdate', -1, lobbyData)

    -- 자동 시작 체크
    CheckAutoStart()
end)

-- 준비 완료/해제
RegisterServerEvent('bumbercar:server:toggleReady')
AddEventHandler('bumbercar:server:toggleReady', function(isReady)
    local source = source
    if not BumberCar.Players[source] then return end

    BumberCar.Players[source].ready = isReady

    local playerName = GetPlayerName(source)
    if isReady then
        BumberCar.NotifyAll(string.format(Config.Notifications.PlayerReady, playerName), 'info')
    else
        BumberCar.NotifyAll(string.format(Config.Notifications.PlayerNotReady, playerName), 'info')
    end

    TriggerEvent('bumbercar:server:updateLobby')
    CheckReadyStart()
end)

-- 관전 모드 토글
RegisterServerEvent('bumbercar:server:toggleSpectate')
AddEventHandler('bumbercar:server:toggleSpectate', function(isSpectating)
    local source = source
    if not BumberCar.Players[source] then return end

    BumberCar.Players[source].spectating = isSpectating

    if isSpectating then
        BumberCar.Players[source].ready = false
    end

    TriggerEvent('bumbercar:server:updateLobby')
end)

-- 맵 선택
RegisterServerEvent('bumbercar:server:selectMap')
AddEventHandler('bumbercar:server:selectMap', function(mapId)
    local source = source

    if Config.Maps[mapId] then
        BumberCar.CurrentMap = mapId
        BumberCar.NotifyAll(string.format('%s 맵이 선택되었습니다', Config.Maps[mapId].name), 'info')
        TriggerEvent('bumbercar:server:updateLobby')
    else
        BumberCar.Notify(source, '존재하지 않는 맵입니다', 'error')
    end
end)

-- 게임 모드 선택
RegisterServerEvent('bumbercar:server:selectGameMode')
AddEventHandler('bumbercar:server:selectGameMode', function(gameMode)
    local source = source

    -- 보스 모드 인원 체크
    if gameMode == Constants.GameMode.BOSS then
        local playerCount = 0
        for _ in pairs(BumberCar.Players) do
            playerCount = playerCount + 1
        end

        if playerCount < Config.Boss.MinPlayers then
            BumberCar.Notify(source,
                string.format('보스 모드는 최소 %d명이 필요합니다', Config.Boss.MinPlayers),
                'error')
            return
        end
    end

    BumberCar.CurrentGameMode = gameMode

    local modeName = '알 수 없음'
    if gameMode == Constants.GameMode.ITEM_FFA then modeName = '아이템전 (개인전)'
    elseif gameMode == Constants.GameMode.ITEM_TEAM then modeName = '아이템전 (팀전)'
    elseif gameMode == Constants.GameMode.CLASSIC_FFA then modeName = '노아이템전 (개인전)'
    elseif gameMode == Constants.GameMode.CLASSIC_TEAM then modeName = '노아이템전 (팀전)'
    elseif gameMode == Constants.GameMode.BOMB_FFA then modeName = '폭탄 건내기 (개인전)'
    elseif gameMode == Constants.GameMode.BOMB_TEAM then modeName = '폭탄 건내기 (팀전)'
    elseif gameMode == Constants.GameMode.BOSS then modeName = '보스 모드'
    end

    BumberCar.NotifyAll(string.format('%s 모드가 선택되었습니다', modeName), 'info')
    TriggerEvent('bumbercar:server:updateLobby')
end)

-- 준비 완료 체크
function CheckReadyStart()
    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        return
    end

    local totalPlayers = 0
    local readyPlayers = 0

    for playerId, playerData in pairs(BumberCar.Players) do
        if not playerData.spectating then
            totalPlayers = totalPlayers + 1
            if playerData.ready then
                readyPlayers = readyPlayers + 1
            end
        end
    end

    -- 최소 인원 미달
    if totalPlayers < Config.Lobby.MinPlayers then
        return
    end

    -- 과반수 이상 준비 완료
    local readyPercentage = readyPlayers / totalPlayers
    if readyPercentage >= Config.Lobby.ReadyPercentage then
        TriggerEvent('bumbercar:server:startGame')
    end
end

-- 자동 시작 체크
function CheckAutoStart()
    local totalPlayers = 0

    for playerId, playerData in pairs(BumberCar.Players) do
        if not playerData.spectating then
            totalPlayers = totalPlayers + 1
        end
    end

    -- 최소 인원 충족
    if totalPlayers >= Config.Lobby.MinPlayers and not autoStartActive then
        autoStartTimer = Config.Lobby.AutoStartTime
        autoStartActive = true
        Utils.Debug('Auto-start timer activated:', autoStartTimer, 'seconds')

    -- 최소 인원 미달
    elseif totalPlayers < Config.Lobby.MinPlayers and autoStartActive then
        autoStartActive = false
        autoStartTimer = 0
        Utils.Debug('Auto-start timer deactivated')
    end

    -- 자동 시작 타이머 전송
    if autoStartActive then
        TriggerClientEvent('bumbercar:client:autoStartTimer', -1, autoStartTimer)
    end
end

-- 자동 시작 타이머
Citizen.CreateThread(function()
    while true do
        Wait(1000)

        if autoStartActive and autoStartTimer > 0 and BumberCar.GameState == Constants.RoundState.LOBBY then
            autoStartTimer = autoStartTimer - 1

            -- 타이머 업데이트
            TriggerClientEvent('bumbercar:client:autoStartTimer', -1, autoStartTimer)

            -- 카운트다운 알림 (10초, 5초, 3초, 2초, 1초)
            if autoStartTimer == 10 or autoStartTimer == 5 or autoStartTimer <= 3 then
                BumberCar.NotifyAll(string.format('게임이 %d초 후 시작됩니다', autoStartTimer), 'warning')
            end

            -- 타이머 종료
            if autoStartTimer <= 0 then
                autoStartActive = false
                TriggerEvent('bumbercar:server:startGame')
            end
        end
    end
end)

-- 로비 상태 초기화
AddEventHandler('bumbercar:server:lobbyReset', function()
    autoStartActive = false
    autoStartTimer = 0
end)
