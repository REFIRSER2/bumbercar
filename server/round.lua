-- 라운드 시스템 (서버)
local roundTimer = 0
local roundTimerActive = false

-- 게임 시작
RegisterServerEvent('bumbercar:server:startGame')
AddEventHandler('bumbercar:server:startGame', function()
    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        return
    end

    local activePlayers = {}
    for playerId, playerData in pairs(BumberCar.Players) do
        if not playerData.spectating then
            table.insert(activePlayers, playerId)
        end
    end

    -- 최소 인원 체크
    if #activePlayers < Config.Lobby.MinPlayers then
        BumberCar.NotifyAll('플레이어가 부족합니다! (' .. #activePlayers .. '/' .. Config.Lobby.MinPlayers .. ')', 'error')
        return
    end

    -- 맵 체크
    if not BumberCar.CurrentMap or not Config.Maps[BumberCar.CurrentMap] then
        BumberCar.CurrentMap = Config.DefaultMap
    end

    local map = Config.Maps[BumberCar.CurrentMap]

    Utils.Success('Game starting! Players:', #activePlayers, 'Map:', BumberCar.CurrentMap, 'Mode:', BumberCar.CurrentGameMode)

    -- 게임 상태 변경
    BumberCar.SetGameState(Constants.RoundState.STARTING)

    -- 팀 배정 (팀전인 경우)
    if BumberCar.CurrentGameMode == Constants.GameMode.ITEM_TEAM or
       BumberCar.CurrentGameMode == Constants.GameMode.BOMB_TEAM or
       BumberCar.CurrentGameMode == Constants.GameMode.CLASSIC_TEAM then
        AssignTeams(activePlayers)
    end

    -- 준비 시간
    Citizen.SetTimeout(Config.Round.PrepareTime * 1000, function()
        StartRound(activePlayers, map)
    end)

    -- 준비 시간 알림
    for i = Config.Round.PrepareTime, 1, -1 do
        Citizen.SetTimeout((Config.Round.PrepareTime - i) * 1000, function()
            BumberCar.NotifyAll(string.format(Config.Notifications.GameStarting, i), 'info')
        end)
    end
end)

-- 라운드 시작
function StartRound(players, map)
    BumberCar.SetGameState(Constants.RoundState.PLAYING)
    BumberCar.NotifyAll(Config.Notifications.GameStarted, 'success')

    -- 플레이어 스폰
    local spawnPoints = Utils.ShuffleTable(map.spawnPoints)
    local vehicles = Config.Vehicles.Regular

    -- 보스 모드
    if BumberCar.CurrentGameMode == Constants.GameMode.BOSS then
        SpawnBossMode(players, map)
    else
        -- 일반 모드
        for i, playerId in ipairs(players) do
            local spawnPoint = spawnPoints[((i - 1) % #spawnPoints) + 1]
            local randomVehicle = Utils.GetRandomElement(vehicles)

            -- 플레이어 상태 설정
            BumberCar.Players[playerId].state = Constants.PlayerState.PLAYING
            BumberCar.Players[playerId].vehicleData = {
                health = randomVehicle.health,
                defense = randomVehicle.defense,
                damage = randomVehicle.damage,
                maxHealth = randomVehicle.health
            }

            -- 차량 스폰
            TriggerClientEvent('bumbercar:client:spawnVehicle', playerId,
                randomVehicle.model,
                spawnPoint,
                BumberCar.Players[playerId].vehicleData
            )

            -- 팀 색상 적용
            if BumberCar.Players[playerId].team ~= Constants.Team.NONE then
                TriggerClientEvent('bumbercar:client:setTeamColor', playerId, BumberCar.Players[playerId].team)
            end
        end
    end

    -- 맵 정보 전송
    TriggerClientEvent('bumbercar:client:setMap', -1, BumberCar.CurrentMap, map)

    -- 아이템 스폰 (아이템 모드)
    if BumberCar.CurrentGameMode == Constants.GameMode.ITEM_FFA or
       BumberCar.CurrentGameMode == Constants.GameMode.ITEM_TEAM then
        TriggerEvent('bumbercar:server:spawnItems', map)
    end

    -- 폭탄 모드
    if BumberCar.CurrentGameMode == Constants.GameMode.BOMB_FFA or
       BumberCar.CurrentGameMode == Constants.GameMode.BOMB_TEAM then
        Citizen.SetTimeout(3000, function()
            TriggerEvent('bumbercar:server:startBombMode')
        end)
    end

    -- 라운드 타이머 시작
    roundTimer = Config.Round.RoundTime
    roundTimerActive = true
    TriggerClientEvent('bumbercar:client:startRoundTimer', -1, roundTimer)
end

-- 팀 배정
function AssignTeams(players)
    local shuffled = Utils.ShuffleTable(players)
    local halfSize = math.ceil(#shuffled / 2)

    for i, playerId in ipairs(shuffled) do
        if i <= halfSize then
            BumberCar.Players[playerId].team = Constants.Team.RED
        else
            BumberCar.Players[playerId].team = Constants.Team.BLUE
        end
    end

    Utils.Debug('Teams assigned - Red:', halfSize, 'Blue:', #shuffled - halfSize)
end

-- 보스 모드 스폰
function SpawnBossMode(players, map)
    -- 랜덤으로 보스 선택
    local bossId = Utils.GetRandomElement(players)
    local bossVehicle = Utils.GetRandomElement(Config.Vehicles.Boss)

    for _, playerId in ipairs(players) do
        if playerId == bossId then
            -- 보스
            BumberCar.Players[playerId].team = Constants.Team.RED
            BumberCar.Players[playerId].state = Constants.PlayerState.PLAYING
            BumberCar.Players[playerId].vehicleData = {
                health = bossVehicle.health,
                defense = bossVehicle.defense,
                damage = bossVehicle.damage,
                maxHealth = bossVehicle.health
            }

            local spawnPoint = map.spawnPoints[1]
            TriggerClientEvent('bumbercar:client:spawnVehicle', playerId,
                bossVehicle.model,
                spawnPoint,
                BumberCar.Players[playerId].vehicleData
            )

            TriggerClientEvent('bumbercar:client:setBossVehicle', playerId, true)
            BumberCar.Notify(playerId, '당신이 보스입니다!', 'success')
        else
            -- 일반 플레이어
            BumberCar.Players[playerId].team = Constants.Team.BLUE
            BumberCar.Players[playerId].state = Constants.PlayerState.PLAYING

            local randomVehicle = Utils.GetRandomElement(Config.Vehicles.Regular)
            BumberCar.Players[playerId].vehicleData = {
                health = randomVehicle.health,
                defense = randomVehicle.defense,
                damage = randomVehicle.damage,
                maxHealth = randomVehicle.health
            }

            local spawnPoint = Utils.GetRandomSpawnPoint(map.spawnPoints)
            TriggerClientEvent('bumbercar:client:spawnVehicle', playerId,
                randomVehicle.model,
                spawnPoint,
                BumberCar.Players[playerId].vehicleData
            )
        end
    end
end

-- 라운드 종료
RegisterServerEvent('bumbercar:server:endRound')
AddEventHandler('bumbercar:server:endRound', function(winner)
    if BumberCar.GameState ~= Constants.RoundState.PLAYING then
        return
    end

    roundTimerActive = false
    BumberCar.SetGameState(Constants.RoundState.ENDING)

    -- 승자 발표
    if winner then
        if type(winner) == 'number' then
            -- 개인 승리
            local winnerName = GetPlayerName(winner)
            BumberCar.NotifyAll(string.format(Config.Notifications.Winner, winnerName), 'success')
        elseif winner == Constants.Team.RED then
            BumberCar.NotifyAll(string.format(Config.Notifications.TeamWinner, '레드'), 'success')
        elseif winner == Constants.Team.BLUE then
            BumberCar.NotifyAll(string.format(Config.Notifications.TeamWinner, '블루'), 'success')
        end
    else
        BumberCar.NotifyAll('무승부!', 'info')
    end

    -- 결과 화면 표시
    local results = CollectRoundResults()
    TriggerClientEvent('bumbercar:client:showResults', -1, results, winner)

    -- 로비로 복귀
    Citizen.SetTimeout(Config.Round.EndingTime * 1000, function()
        ReturnToLobby()
    end)
end)

-- 결과 수집
function CollectRoundResults()
    local results = {}

    for playerId, playerData in pairs(BumberCar.Players) do
        table.insert(results, {
            name = playerData.name,
            kills = playerData.stats.kills,
            deaths = playerData.stats.deaths,
            damageDealt = playerData.stats.damageDealt,
            damageTaken = playerData.stats.damageTaken
        })
    end

    -- 킬 수 기준 정렬
    table.sort(results, function(a, b)
        return a.kills > b.kills
    end)

    return results
end

-- 로비 복귀
function ReturnToLobby()
    BumberCar.SetGameState(Constants.RoundState.LOBBY)

    -- 모든 플레이어 초기화
    for playerId, playerData in pairs(BumberCar.Players) do
        playerData.state = Constants.PlayerState.LOBBY
        playerData.team = Constants.Team.NONE
        playerData.ready = false
        playerData.spectating = false
        playerData.items = {nil, nil}
        playerData.effects = {}
        playerData.stats = {
            kills = 0,
            deaths = 0,
            damageDealt = 0,
            damageTaken = 0
        }

        -- 클라이언트 초기화
        TriggerClientEvent('bumbercar:client:returnToLobby', playerId)
    end

    Utils.Debug('Returned to lobby')
end

-- 라운드 타이머
Citizen.CreateThread(function()
    while true do
        Wait(1000)

        if roundTimerActive and roundTimer > 0 then
            roundTimer = roundTimer - 1

            -- 타이머 업데이트
            TriggerClientEvent('bumbercar:client:updateRoundTimer', -1, roundTimer)

            -- 타이머 종료
            if roundTimer <= 0 then
                roundTimerActive = false
                TriggerEvent('bumbercar:server:endRound', nil) -- 시간 초과 = 무승부
            end
        end
    end
end)
