-- 로비 시스템 (서버)
local autoStartTimer = 0
local autoStartActive = false

-- 로비 데이터 생성 함수
function GetLobbyData()
    local lobbyData = {
        players = {},
        currentMap = BumberCar.CurrentMap,
        currentGameMode = BumberCar.CurrentGameMode,
        maps = {},
        gameModes = {},
        autoStartTimer = autoStartActive and autoStartTimer or 0
    }

    -- 플레이어 목록 (source 순서대로 정렬)
    local playerList = {}
    for playerId, playerData in pairs(BumberCar.Players) do
        table.insert(playerList, {
            id = playerId,
            name = playerData.name,
            ready = playerData.ready or false,
            spectating = playerData.spectating or false,
            team = playerData.team or Constants.Team.NONE
        })
    end

    -- ID 순으로 정렬
    table.sort(playerList, function(a, b)
        return a.id < b.id
    end)

    lobbyData.players = playerList

    -- 맵 목록 (ID 순서대로 정렬)
    for mapId, mapData in pairs(Config.Maps) do
        table.insert(lobbyData.maps, {
            id = mapId,
            name = mapData.name,
            description = mapData.description,
            icon = mapData.icon
        })
    end

    -- 게임 모드 목록 (9가지 모드 모두 포함)
    local gameModes = {
        {id = Constants.GameMode.ITEM_FFA, name = '아이템전 (개인전)', description = '아이템을 사용하여 싸우는 개인전'},
        {id = Constants.GameMode.ITEM_TEAM, name = '아이템전 (팀전)', description = '아이템을 사용하여 싸우는 팀전'},
        {id = Constants.GameMode.CLASSIC_FFA, name = '노아이템전 (개인전)', description = '아이템 없이 싸우는 개인전'},
        {id = Constants.GameMode.CLASSIC_TEAM, name = '노아이템전 (팀전)', description = '아이템 없이 싸우는 팀전'},
        {id = Constants.GameMode.BOMB_FFA, name = '폭탄 건내기 (개인전)', description = '폭탄을 넘기는 개인전'},
        {id = Constants.GameMode.BOMB_TEAM, name = '폭탄 건내기 (팀전)', description = '폭탄을 넘기는 팀전'},
        {id = Constants.GameMode.BOSS, name = '보스 모드', description = '한 명의 보스 vs 나머지 플레이어'},
        {id = 'weapon_ffa', name = '무기전 (개인전)', description = '무기를 사용하여 싸우는 개인전'},
        {id = 'weapon_team', name = '무기전 (팀전)', description = '무기를 사용하여 싸우는 팀전'}
    }
    lobbyData.gameModes = gameModes

    return lobbyData
end

-- 로비 데이터 요청 (단일 플레이어)
RegisterServerEvent('bumbercar:server:requestLobbyData')
AddEventHandler('bumbercar:server:requestLobbyData', function()
    local source = source
    Utils.Debug('Lobby data requested by player:', source)

    -- 플레이어 유효성 체크
    if not BumberCar.Players[source] then
        Utils.Error('Invalid player requesting lobby data:', source)
        return
    end

    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        Utils.Debug('Not in lobby state, ignoring request')
        return
    end

    local lobbyData = GetLobbyData()
    TriggerClientEvent('bumbercar:client:lobbyUpdate', source, lobbyData)

    Utils.Debug('Sent lobby data to player:', source, 'with', #lobbyData.players, 'players')
end)

-- 로비 업데이트 (모든 플레이어)
RegisterServerEvent('bumbercar:server:updateLobby')
AddEventHandler('bumbercar:server:updateLobby', function()
    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        Utils.Debug('Not in lobby state, skipping lobby update')
        return
    end

    local lobbyData = GetLobbyData()
    Utils.Debug('Updating lobby for all players with', #lobbyData.players, 'players')

    -- 모든 플레이어에게 업데이트 전송
    TriggerClientEvent('bumbercar:client:lobbyUpdate', -1, lobbyData)

    -- 자동 시작 체크
    CheckAutoStart()
end)

-- 준비 완료/해제 토글
RegisterServerEvent('bumbercar:server:toggleReady')
AddEventHandler('bumbercar:server:toggleReady', function(isReady)
    local source = source

    -- 플레이어 유효성 체크
    if not BumberCar.Players[source] then
        Utils.Error('Invalid player toggling ready:', source)
        return
    end

    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        BumberCar.Notify(source, '게임이 진행 중입니다', 'error')
        return
    end

    -- 관전 모드 중에는 준비 불가
    if BumberCar.Players[source].spectating then
        BumberCar.Notify(source, '관전 모드에서는 준비할 수 없습니다', 'error')
        return
    end

    -- 준비 상태 변경
    BumberCar.Players[source].ready = isReady
    BumberCar.Players[source].state = isReady and Constants.PlayerState.READY or Constants.PlayerState.LOBBY

    local playerName = GetPlayerName(source)
    if isReady then
        BumberCar.NotifyAll(string.format(Config.Notifications.PlayerReady, playerName), 'info')
        Utils.Debug('Player ready:', playerName)
    else
        BumberCar.NotifyAll(string.format(Config.Notifications.PlayerNotReady, playerName), 'info')
        Utils.Debug('Player unready:', playerName)
    end

    -- 로비 업데이트
    TriggerEvent('bumbercar:server:updateLobby')

    -- 준비 완료 체크 (과반수 이상 준비 시 자동 시작)
    CheckReadyStart()
end)

-- 관전 모드 토글
RegisterServerEvent('bumbercar:server:toggleSpectate')
AddEventHandler('bumbercar:server:toggleSpectate', function(isSpectating)
    local source = source

    -- 플레이어 유효성 체크
    if not BumberCar.Players[source] then
        Utils.Error('Invalid player toggling spectate:', source)
        return
    end

    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        BumberCar.Notify(source, '로비에서만 관전 모드를 설정할 수 있습니다', 'error')
        return
    end

    -- 관전 모드 설정
    BumberCar.Players[source].spectating = isSpectating
    BumberCar.Players[source].state = isSpectating and Constants.PlayerState.SPECTATING or Constants.PlayerState.LOBBY

    -- 관전 모드 활성화 시 준비 상태 해제
    if isSpectating then
        BumberCar.Players[source].ready = false
        BumberCar.Notify(source, '관전 모드로 전환되었습니다', 'info')
        Utils.Debug('Player spectating:', GetPlayerName(source))
    else
        BumberCar.Notify(source, '관전 모드가 해제되었습니다', 'info')
        Utils.Debug('Player stopped spectating:', GetPlayerName(source))
    end

    -- 로비 업데이트
    TriggerEvent('bumbercar:server:updateLobby')
end)

-- 맵 선택
RegisterServerEvent('bumbercar:server:selectMap')
AddEventHandler('bumbercar:server:selectMap', function(mapId)
    local source = source

    -- 플레이어 유효성 체크
    if not BumberCar.Players[source] then
        Utils.Error('Invalid player selecting map:', source)
        return
    end

    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        BumberCar.Notify(source, '게임이 진행 중입니다', 'error')
        return
    end

    -- 맵 유효성 체크
    if not Config.Maps[mapId] then
        BumberCar.Notify(source, '존재하지 않는 맵입니다', 'error')
        Utils.Error('Invalid map selected:', mapId, 'by player:', source)
        return
    end

    -- 맵 변경
    BumberCar.CurrentMap = mapId
    BumberCar.NotifyAll(string.format('%s 맵이 선택되었습니다', Config.Maps[mapId].name), 'info')
    Utils.Success('Map selected:', mapId, 'by player:', GetPlayerName(source))

    -- 로비 업데이트
    TriggerEvent('bumbercar:server:updateLobby')
end)

-- 게임 모드 선택
RegisterServerEvent('bumbercar:server:selectGameMode')
AddEventHandler('bumbercar:server:selectGameMode', function(gameMode)
    local source = source

    -- 플레이어 유효성 체크
    if not BumberCar.Players[source] then
        Utils.Error('Invalid player selecting game mode:', source)
        return
    end

    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        BumberCar.Notify(source, '게임이 진행 중입니다', 'error')
        return
    end

    -- 보스 모드 인원 체크
    if gameMode == Constants.GameMode.BOSS then
        local playerCount = 0
        for _, playerData in pairs(BumberCar.Players) do
            if not playerData.spectating then
                playerCount = playerCount + 1
            end
        end

        if playerCount < Config.Boss.MinPlayers then
            BumberCar.Notify(source,
                string.format('보스 모드는 최소 %d명이 필요합니다 (현재: %d명)', Config.Boss.MinPlayers, playerCount),
                'error')
            return
        end
    end

    -- 게임 모드 변경
    BumberCar.CurrentGameMode = gameMode

    -- 모드명 변환
    local modeName = GetGameModeName(gameMode)
    BumberCar.NotifyAll(string.format('%s 모드가 선택되었습니다', modeName), 'info')
    Utils.Success('Game mode selected:', gameMode, 'by player:', GetPlayerName(source))

    -- 로비 업데이트
    TriggerEvent('bumbercar:server:updateLobby')
end)

-- 게임 모드명 가져오기
function GetGameModeName(gameMode)
    if gameMode == Constants.GameMode.ITEM_FFA then return '아이템전 (개인전)'
    elseif gameMode == Constants.GameMode.ITEM_TEAM then return '아이템전 (팀전)'
    elseif gameMode == Constants.GameMode.CLASSIC_FFA then return '노아이템전 (개인전)'
    elseif gameMode == Constants.GameMode.CLASSIC_TEAM then return '노아이템전 (팀전)'
    elseif gameMode == Constants.GameMode.BOMB_FFA then return '폭탄 건내기 (개인전)'
    elseif gameMode == Constants.GameMode.BOMB_TEAM then return '폭탄 건내기 (팀전)'
    elseif gameMode == Constants.GameMode.BOSS then return '보스 모드'
    elseif gameMode == 'weapon_ffa' then return '무기전 (개인전)'
    elseif gameMode == 'weapon_team' then return '무기전 (팀전)'
    else return '알 수 없음'
    end
end

-- 로비 채팅
RegisterServerEvent('bumbercar:server:lobbyChat')
AddEventHandler('bumbercar:server:lobbyChat', function(message)
    local source = source

    -- 플레이어 유효성 체크
    if not BumberCar.Players[source] then
        Utils.Error('Invalid player sending lobby chat:', source)
        return
    end

    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        return
    end

    -- 메시지 유효성 체크 및 길이 제한
    if not message or type(message) ~= 'string' or message == '' then
        return
    end

    message = string.sub(message, 1, 100)
    message = message:gsub('[<>]', '') -- XSS 방지

    -- 모든 플레이어에게 채팅 메시지 전송
    local author = GetPlayerName(source)
    TriggerClientEvent('bumbercar:client:lobbyChatMessage', -1, author, message)

    Utils.Debug('Lobby chat from', author, ':', message)
end)

-- 준비 완료 체크 (과반수 이상 준비 시 게임 시작)
function CheckReadyStart()
    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        return
    end

    local totalPlayers = 0
    local readyPlayers = 0

    -- 관전자를 제외한 플레이어 수 계산
    for playerId, playerData in pairs(BumberCar.Players) do
        if not playerData.spectating then
            totalPlayers = totalPlayers + 1
            if playerData.ready then
                readyPlayers = readyPlayers + 1
            end
        end
    end

    -- 최소 인원 미달 시 중단
    if totalPlayers < Config.Lobby.MinPlayers then
        Utils.Debug('Not enough players for ready check:', totalPlayers, '/', Config.Lobby.MinPlayers)
        return
    end

    -- 과반수 이상 준비 완료 체크
    local readyPercentage = readyPlayers / totalPlayers
    Utils.Debug('Ready check:', readyPlayers, '/', totalPlayers, '=', math.floor(readyPercentage * 100) .. '%')

    if readyPercentage >= Config.Lobby.ReadyPercentage then
        Utils.Success('Ready threshold reached! Starting game...')
        TriggerEvent('bumbercar:server:startGame')
    end
end

-- 자동 시작 체크 (최소 인원 충족 시 타이머 시작)
function CheckAutoStart()
    local totalPlayers = 0

    -- 관전자를 제외한 플레이어 수 계산
    for playerId, playerData in pairs(BumberCar.Players) do
        if not playerData.spectating then
            totalPlayers = totalPlayers + 1
        end
    end

    -- 최소 인원 충족 시 자동 시작 타이머 활성화
    if totalPlayers >= Config.Lobby.MinPlayers and not autoStartActive then
        autoStartTimer = Config.Lobby.AutoStartTime
        autoStartActive = true
        Utils.Debug('Auto-start timer activated:', autoStartTimer, 'seconds')
        TriggerClientEvent('bumbercar:client:autoStartTimer', -1, autoStartTimer)

    -- 최소 인원 미달 시 타이머 비활성화
    elseif totalPlayers < Config.Lobby.MinPlayers and autoStartActive then
        autoStartActive = false
        autoStartTimer = 0
        Utils.Debug('Auto-start timer deactivated (not enough players)')
        TriggerClientEvent('bumbercar:client:autoStartTimer', -1, 0)
    end
end

-- 자동 시작 타이머 (1초마다 감소)
Citizen.CreateThread(function()
    while true do
        Wait(1000)

        if autoStartActive and autoStartTimer > 0 and BumberCar.GameState == Constants.RoundState.LOBBY then
            autoStartTimer = autoStartTimer - 1

            -- 타이머 업데이트 전송
            TriggerClientEvent('bumbercar:client:autoStartTimer', -1, autoStartTimer)

            -- 카운트다운 알림 (10초, 5초, 3~1초)
            if autoStartTimer == 10 or autoStartTimer == 5 or (autoStartTimer <= 3 and autoStartTimer > 0) then
                BumberCar.NotifyAll(string.format(Config.Notifications.GameStarting, autoStartTimer), 'warning')
            end

            -- 타이머 종료 시 게임 시작
            if autoStartTimer <= 0 then
                autoStartActive = false
                Utils.Success('Auto-start timer expired! Starting game...')
                TriggerEvent('bumbercar:server:startGame')
            end
        end
    end
end)

-- 주기적인 로비 업데이트 (2초마다 플레이어 목록 동기화)
Citizen.CreateThread(function()
    while true do
        Wait(2000)

        if BumberCar.GameState == Constants.RoundState.LOBBY then
            -- 조용히 업데이트 (이벤트 트리거 없이 직접 전송)
            local lobbyData = GetLobbyData()
            TriggerClientEvent('bumbercar:client:lobbyUpdate', -1, lobbyData)
        end
    end
end)

-- 로비 상태 초기화 (게임 종료 후 로비로 돌아올 때)
AddEventHandler('bumbercar:server:lobbyReset', function()
    autoStartActive = false
    autoStartTimer = 0
    Utils.Debug('Lobby reset complete')

    -- 모든 플레이어 상태 초기화
    for playerId, playerData in pairs(BumberCar.Players) do
        playerData.ready = false
        playerData.state = playerData.spectating and Constants.PlayerState.SPECTATING or Constants.PlayerState.LOBBY
    end

    -- 로비 업데이트
    TriggerEvent('bumbercar:server:updateLobby')
end)

Utils.Success('Lobby system loaded!')
