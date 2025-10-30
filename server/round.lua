-- 라운드 시스템 (서버)
local roundTimer = 0
local roundTimerActive = false
local winConditionCheckInterval = 2000 -- 승리 조건 체크 주기 (밀리초)

-- 게임 시작 (로비에서 트리거됨)
RegisterServerEvent('bumbercar:server:startGame')
AddEventHandler('bumbercar:server:startGame', function()
    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.LOBBY then
        Utils.Debug('Cannot start game - not in lobby state')
        return
    end

    -- 활성 플레이어 수집 (관전자 제외)
    local activePlayers = {}
    for playerId, playerData in pairs(BumberCar.Players) do
        if not playerData.spectating then
            table.insert(activePlayers, playerId)
        end
    end

    -- 최소 인원 체크
    if #activePlayers < Config.Lobby.MinPlayers then
        BumberCar.NotifyAll(
            string.format('플레이어가 부족합니다! (%d/%d)', #activePlayers, Config.Lobby.MinPlayers),
            'error'
        )
        Utils.Error('Not enough players to start game:', #activePlayers, '/', Config.Lobby.MinPlayers)
        return
    end

    -- 맵 유효성 체크
    if not BumberCar.CurrentMap or not Config.Maps[BumberCar.CurrentMap] then
        BumberCar.CurrentMap = Config.DefaultMap
        Utils.Debug('Invalid map, using default:', Config.DefaultMap)
    end

    -- 보스 모드 인원 체크
    if BumberCar.CurrentGameMode == Constants.GameMode.BOSS and #activePlayers < Config.Boss.MinPlayers then
        BumberCar.NotifyAll(
            string.format('보스 모드는 최소 %d명이 필요합니다', Config.Boss.MinPlayers),
            'error'
        )
        return
    end

    local map = Config.Maps[BumberCar.CurrentMap]
    Utils.Success('Game starting! Players:', #activePlayers, 'Map:', BumberCar.CurrentMap, 'Mode:', BumberCar.CurrentGameMode)

    -- 게임 상태 변경: STARTING (준비 단계)
    BumberCar.SetGameState(Constants.RoundState.STARTING)

    -- 팀 배정 (팀전 모드인 경우)
    if IsTeamMode(BumberCar.CurrentGameMode) then
        AssignTeams()
    end

    -- 준비 시간 카운트다운 알림
    for i = Config.Round.PrepareTime, 1, -1 do
        Citizen.SetTimeout((Config.Round.PrepareTime - i) * 1000, function()
            BumberCar.NotifyAll(string.format(Config.Notifications.GameStarting, i), 'info')
        end)
    end

    -- 준비 시간 후 라운드 시작
    Citizen.SetTimeout(Config.Round.PrepareTime * 1000, function()
        StartRound(activePlayers, map)
    end)
end)

-- 라운드 시작 (실제 게임 플레이 시작)
function StartRound(players, map)
    -- 게임 상태 변경: PLAYING
    BumberCar.SetGameState(Constants.RoundState.PLAYING)
    BumberCar.NotifyAll(Config.Notifications.GameStarted, 'success')

    Utils.Success('Round started with', #players, 'players')

    -- 보스 모드는 특별 처리
    if BumberCar.CurrentGameMode == Constants.GameMode.BOSS then
        SpawnBossMode(players, map)
    else
        -- 일반 모드: 모든 플레이어 스폰
        SpawnPlayers(players, map)
    end

    -- 맵 정보 전송 (경계 체크용)
    TriggerClientEvent('bumbercar:client:setMap', -1, BumberCar.CurrentMap, map)

    -- 라운드 시작 알림 (HUD 표시 등)
    TriggerClientEvent('bumbercar:client:roundStart', -1, {
        gameMode = BumberCar.CurrentGameMode,
        map = BumberCar.CurrentMap,
        roundTime = Config.Round.RoundTime
    })

    -- 아이템 스폰 (아이템 모드)
    if BumberCar.CurrentGameMode == Constants.GameMode.ITEM_FFA or
       BumberCar.CurrentGameMode == Constants.GameMode.ITEM_TEAM or
       BumberCar.CurrentGameMode == 'weapon_ffa' or
       BumberCar.CurrentGameMode == 'weapon_team' then
        Citizen.SetTimeout(1000, function()
            TriggerEvent('bumbercar:server:spawnItems', map)
        end)
    end

    -- 폭탄 모드 시작
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

    -- 승리 조건 체크 시작
    StartWinConditionCheck()
end

-- 플레이어 스폰 (일반 모드)
function SpawnPlayers(players, map)
    local spawnPoints = Utils.ShuffleTable(map.spawnPoints)
    local vehicles = Config.Vehicles.Regular

    for i, playerId in ipairs(players) do
        -- 스폰 포인트 선택 (순환)
        local spawnPoint = spawnPoints[((i - 1) % #spawnPoints) + 1]

        -- 랜덤 차량 선택
        local randomVehicle = Utils.GetRandomElement(vehicles)

        -- 플레이어 데이터 설정
        BumberCar.Players[playerId].state = Constants.PlayerState.PLAYING
        BumberCar.Players[playerId].vehicleData = {
            model = randomVehicle.model,
            health = randomVehicle.health,
            defense = randomVehicle.defense,
            damage = randomVehicle.damage,
            maxHealth = randomVehicle.health,
            speed = randomVehicle.speed
        }

        -- 차량 스폰 요청
        TriggerClientEvent('bumbercar:client:spawnVehicle', playerId,
            randomVehicle.model,
            spawnPoint,
            BumberCar.Players[playerId].vehicleData
        )

        -- 팀 색상 적용 (팀전인 경우)
        if BumberCar.Players[playerId].team ~= Constants.Team.NONE then
            Citizen.SetTimeout(500, function()
                ApplyTeamColor(playerId, BumberCar.Players[playerId].team)
            end)
        end

        Utils.Debug('Spawned player', playerId, 'at', spawnPoint, 'with vehicle', randomVehicle.model)
    end
end

-- 보스 모드 스폰
function SpawnBossMode(players, map)
    -- 랜덤으로 보스 선택
    local bossId = Utils.GetRandomElement(players)
    local bossVehicle = Config.Vehicles.Boss and Utils.GetRandomElement(Config.Vehicles.Boss) or {
        model = Config.Boss.BossVehicle or 'rhino',
        health = Config.Vehicle.DefaultHealth * Config.Boss.BossHealthMultiplier,
        defense = Config.Vehicle.DefaultDefense * Config.Boss.BossHealthMultiplier,
        damage = Config.Vehicle.DefaultDamage * Config.Boss.BossDamageMultiplier,
        speed = 0.7
    }

    Utils.Success('Boss selected:', GetPlayerName(bossId))

    local spawnPoints = Utils.ShuffleTable(map.spawnPoints)
    local spawnIndex = 1

    for _, playerId in ipairs(players) do
        if playerId == bossId then
            -- 보스 플레이어
            BumberCar.Players[playerId].team = Constants.Team.RED
            BumberCar.Players[playerId].state = Constants.PlayerState.PLAYING
            BumberCar.Players[playerId].vehicleData = {
                model = bossVehicle.model,
                health = bossVehicle.health,
                defense = bossVehicle.defense,
                damage = bossVehicle.damage,
                maxHealth = bossVehicle.health,
                speed = bossVehicle.speed or 0.7,
                isBoss = true
            }

            -- 중앙 스폰
            local spawnPoint = spawnPoints[1]
            TriggerClientEvent('bumbercar:client:spawnVehicle', playerId,
                bossVehicle.model,
                spawnPoint,
                BumberCar.Players[playerId].vehicleData
            )

            TriggerClientEvent('bumbercar:client:setBossVehicle', playerId, true)
            BumberCar.Notify(playerId, '당신이 보스입니다! 모든 플레이어를 물리치세요!', 'success')

        else
            -- 일반 플레이어
            BumberCar.Players[playerId].team = Constants.Team.BLUE
            BumberCar.Players[playerId].state = Constants.PlayerState.PLAYING

            local randomVehicle = Utils.GetRandomElement(Config.Vehicles.Regular)
            BumberCar.Players[playerId].vehicleData = {
                model = randomVehicle.model,
                health = randomVehicle.health,
                defense = randomVehicle.defense,
                damage = randomVehicle.damage,
                maxHealth = randomVehicle.health,
                speed = randomVehicle.speed
            }

            -- 보스 주변에 스폰
            spawnIndex = spawnIndex + 1
            local spawnPoint = spawnPoints[spawnIndex] or Utils.GetRandomSpawnPoint(spawnPoints)
            TriggerClientEvent('bumbercar:client:spawnVehicle', playerId,
                randomVehicle.model,
                spawnPoint,
                BumberCar.Players[playerId].vehicleData
            )

            BumberCar.Notify(playerId, '보스를 물리치세요!', 'info')
        end
    end
end

-- 플레이어 사망 처리
RegisterServerEvent('bumbercar:server:playerDeath')
AddEventHandler('bumbercar:server:playerDeath', function(killerId)
    local source = source

    -- 플레이어 유효성 체크
    if not BumberCar.Players[source] then
        Utils.Error('Invalid player death:', source)
        return
    end

    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.PLAYING then
        Utils.Debug('Player death ignored - not in playing state')
        return
    end

    -- 이미 사망한 플레이어면 무시
    if BumberCar.Players[source].state == Constants.PlayerState.DEAD then
        return
    end

    local victimName = GetPlayerName(source)
    local killerName = killerId and BumberCar.Players[killerId] and GetPlayerName(killerId) or nil

    -- 통계 업데이트
    BumberCar.Players[source].stats.deaths = (BumberCar.Players[source].stats.deaths or 0) + 1
    if killerId and BumberCar.Players[killerId] then
        BumberCar.Players[killerId].stats.kills = (BumberCar.Players[killerId].stats.kills or 0) + 1
    end

    -- 플레이어 상태 변경
    BumberCar.Players[source].state = Constants.PlayerState.DEAD

    -- 사망 알림
    if killerName then
        BumberCar.NotifyAll(string.format('%s님이 %s님에게 탈락당했습니다', victimName, killerName), 'info')
        Utils.Debug('Player', victimName, 'killed by', killerName)
    else
        BumberCar.NotifyAll(string.format(Config.Notifications.PlayerDied, victimName), 'info')
        Utils.Debug('Player', victimName, 'died')
    end

    -- 관전 모드로 전환
    Citizen.SetTimeout(Config.Round.RespawnDelay * 1000, function()
        if BumberCar.Players[source] then
            BumberCar.Players[source].state = Constants.PlayerState.SPECTATING
            TriggerClientEvent('bumbercar:client:startSpectating', source)
            Utils.Debug('Player', source, 'switched to spectating')
        end
    end)

    -- 승리 조건 즉시 체크 (누군가 죽었으므로)
    CheckWinCondition()
end)

-- 승리 조건 체크 시작 (주기적으로 실행)
function StartWinConditionCheck()
    Citizen.CreateThread(function()
        while BumberCar.GameState == Constants.RoundState.PLAYING do
            Wait(winConditionCheckInterval)
            CheckWinCondition()
        end
    end)
end

-- 승리 조건 체크
function CheckWinCondition()
    if BumberCar.GameState ~= Constants.RoundState.PLAYING then
        return
    end

    local gameMode = BumberCar.CurrentGameMode

    -- FFA 모드 (개인전)
    if gameMode == Constants.GameMode.ITEM_FFA or
       gameMode == Constants.GameMode.CLASSIC_FFA or
       gameMode == 'weapon_ffa' then
        CheckFFAWinCondition()

    -- Team 모드 (팀전)
    elseif gameMode == Constants.GameMode.ITEM_TEAM or
           gameMode == Constants.GameMode.CLASSIC_TEAM or
           gameMode == 'weapon_team' then
        CheckTeamWinCondition()

    -- Boss 모드
    elseif gameMode == Constants.GameMode.BOSS then
        CheckBossWinCondition()

    -- Bomb 모드는 별도 처리 (items.lua에서 처리)
    elseif gameMode == Constants.GameMode.BOMB_FFA or
           gameMode == Constants.GameMode.BOMB_TEAM then
        -- Bomb 모드는 폭발 시 승자가 결정됨
        -- 하지만 모든 플레이어가 죽었는지는 체크
        local aliveCount = BumberCar.GetAlivePlayers()
        if aliveCount == 0 then
            TriggerEvent('bumbercar:server:endRound', nil)
        end
    end
end

-- FFA 승리 조건 체크 (마지막 생존자 승리)
function CheckFFAWinCondition()
    local alivePlayers = {}

    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.state == Constants.PlayerState.PLAYING then
            table.insert(alivePlayers, playerId)
        end
    end

    -- 생존자가 1명 이하면 게임 종료
    if #alivePlayers == 1 then
        Utils.Success('FFA Winner:', GetPlayerName(alivePlayers[1]))
        TriggerEvent('bumbercar:server:endRound', alivePlayers[1])
    elseif #alivePlayers == 0 then
        Utils.Debug('No survivors - draw')
        TriggerEvent('bumbercar:server:endRound', nil)
    end
end

-- Team 승리 조건 체크 (마지막 생존 팀 승리)
function CheckTeamWinCondition()
    local redAlive = GetTeamAliveCount(Constants.Team.RED)
    local blueAlive = GetTeamAliveCount(Constants.Team.BLUE)

    -- 한 팀만 생존 시 승리
    if redAlive > 0 and blueAlive == 0 then
        Utils.Success('Team Winner: RED')
        TriggerEvent('bumbercar:server:endRound', Constants.Team.RED)
    elseif blueAlive > 0 and redAlive == 0 then
        Utils.Success('Team Winner: BLUE')
        TriggerEvent('bumbercar:server:endRound', Constants.Team.BLUE)
    elseif redAlive == 0 and blueAlive == 0 then
        Utils.Debug('No team survivors - draw')
        TriggerEvent('bumbercar:server:endRound', nil)
    end
end

-- Boss 승리 조건 체크
function CheckBossWinCondition()
    local bossId = nil
    local bossAlive = false
    local othersAlive = 0

    -- 보스 찾기 및 생존자 카운트
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == Constants.Team.RED and playerData.vehicleData and playerData.vehicleData.isBoss then
            bossId = playerId
            if playerData.state == Constants.PlayerState.PLAYING then
                bossAlive = true
            end
        elseif playerData.team == Constants.Team.BLUE then
            if playerData.state == Constants.PlayerState.PLAYING then
                othersAlive = othersAlive + 1
            end
        end
    end

    -- 보스가 죽으면 일반 플레이어들 승리
    if bossId and not bossAlive then
        Utils.Success('Boss defeated! Others win')
        TriggerEvent('bumbercar:server:endRound', Constants.Team.BLUE)

    -- 일반 플레이어들이 모두 죽으면 보스 승리
    elseif bossAlive and othersAlive == 0 then
        Utils.Success('Boss wins!')
        TriggerEvent('bumbercar:server:endRound', bossId)
    end
end

-- 라운드 종료
RegisterServerEvent('bumbercar:server:endRound')
AddEventHandler('bumbercar:server:endRound', function(winner)
    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.PLAYING then
        Utils.Debug('Cannot end round - not in playing state')
        return
    end

    -- 타이머 중지
    roundTimerActive = false

    -- 게임 상태 변경: ENDING
    BumberCar.SetGameState(Constants.RoundState.ENDING)

    Utils.Success('Round ended! Winner:', winner or 'None (Draw)')

    -- 승자 발표
    if winner then
        if type(winner) == 'number' then
            -- 개인 승리
            local winnerName = GetPlayerName(winner)
            BumberCar.NotifyAll(string.format(Config.Notifications.Winner, winnerName), 'success')
        elseif winner == Constants.Team.RED then
            -- 레드 팀 승리
            BumberCar.NotifyAll(string.format(Config.Notifications.TeamWinner, '레드'), 'success')
        elseif winner == Constants.Team.BLUE then
            -- 블루 팀 승리
            BumberCar.NotifyAll(string.format(Config.Notifications.TeamWinner, '블루'), 'success')
        end
    else
        -- 무승부
        BumberCar.NotifyAll('무승부!', 'info')
    end

    -- 결과 수집 및 전송
    local results = CollectRoundResults()
    TriggerClientEvent('bumbercar:client:roundEnd', -1, {
        winner = winner,
        results = results,
        gameMode = BumberCar.CurrentGameMode
    })

    -- 엔딩 시간 후 로비로 복귀
    Citizen.SetTimeout(Config.Round.EndingTime * 1000, function()
        ReturnToLobby()
    end)
end)

-- 결과 수집
function CollectRoundResults()
    local results = {}

    for playerId, playerData in pairs(BumberCar.Players) do
        -- 관전자는 결과에서 제외
        if not playerData.spectating then
            table.insert(results, {
                id = playerId,
                name = playerData.name,
                team = playerData.team,
                kills = playerData.stats.kills or 0,
                deaths = playerData.stats.deaths or 0,
                damageDealt = playerData.stats.damageDealt or 0,
                damageTaken = playerData.stats.damageTaken or 0
            })
        end
    end

    -- 킬 수 기준으로 정렬
    table.sort(results, function(a, b)
        if a.kills == b.kills then
            return a.deaths < b.deaths
        end
        return a.kills > b.kills
    end)

    Utils.Debug('Results collected for', #results, 'players')
    return results
end

-- 로비로 복귀
function ReturnToLobby()
    Utils.Debug('Returning to lobby...')

    -- 게임 상태 변경: LOBBY
    BumberCar.SetGameState(Constants.RoundState.LOBBY)

    -- 모든 플레이어 초기화
    for playerId, playerData in pairs(BumberCar.Players) do
        playerData.state = playerData.spectating and Constants.PlayerState.SPECTATING or Constants.PlayerState.LOBBY
        playerData.team = Constants.Team.NONE
        playerData.ready = false
        playerData.vehicle = nil
        playerData.vehicleData = {
            health = Config.Vehicle.DefaultHealth,
            defense = Config.Vehicle.DefaultDefense,
            damage = Config.Vehicle.DefaultDamage,
            maxHealth = Config.Vehicle.DefaultHealth
        }
        playerData.items = {nil, nil}
        playerData.effects = {}
        playerData.stats = {
            kills = 0,
            deaths = 0,
            damageDealt = 0,
            damageTaken = 0
        }

        -- 클라이언트에 로비 복귀 알림
        TriggerClientEvent('bumbercar:client:returnToLobby', playerId)
    end

    -- 로비 리셋 트리거
    TriggerEvent('bumbercar:server:lobbyReset')

    Utils.Success('Returned to lobby')
end

-- 라운드 타이머 (1초마다 감소)
Citizen.CreateThread(function()
    while true do
        Wait(1000)

        if roundTimerActive and roundTimer > 0 and BumberCar.GameState == Constants.RoundState.PLAYING then
            roundTimer = roundTimer - 1

            -- 타이머 업데이트 전송
            TriggerClientEvent('bumbercar:client:updateRoundTimer', -1, roundTimer)

            -- 타이머 종료 시 라운드 종료 (시간 초과)
            if roundTimer <= 0 then
                roundTimerActive = false
                Utils.Debug('Round time expired')

                -- 시간 초과 승자 결정
                local winner = DetermineWinnerByTime()
                TriggerEvent('bumbercar:server:endRound', winner)
            end
        end
    end
end)

-- 시간 초과 시 승자 결정
function DetermineWinnerByTime()
    local gameMode = BumberCar.CurrentGameMode

    -- FFA 모드: 가장 많은 킬을 한 플레이어
    if gameMode == Constants.GameMode.ITEM_FFA or
       gameMode == Constants.GameMode.CLASSIC_FFA or
       gameMode == 'weapon_ffa' then
        local topPlayer = nil
        local topKills = -1

        for playerId, playerData in pairs(BumberCar.Players) do
            if not playerData.spectating then
                local kills = playerData.stats.kills or 0
                if kills > topKills then
                    topKills = kills
                    topPlayer = playerId
                end
            end
        end

        return topPlayer

    -- Team 모드: 가장 많은 킬을 한 팀
    elseif gameMode == Constants.GameMode.ITEM_TEAM or
           gameMode == Constants.GameMode.CLASSIC_TEAM or
           gameMode == 'weapon_team' then
        return GetWinningTeam()

    -- Boss 모드: 보스가 살아있으면 보스 승리, 죽었으면 일반 플레이어 승리
    elseif gameMode == Constants.GameMode.BOSS then
        for playerId, playerData in pairs(BumberCar.Players) do
            if playerData.team == Constants.Team.RED and
               playerData.vehicleData and playerData.vehicleData.isBoss then
                if playerData.state == Constants.PlayerState.PLAYING then
                    return playerId -- 보스 승리
                else
                    return Constants.Team.BLUE -- 일반 플레이어 승리
                end
            end
        end
    end

    return nil -- 무승부
end

-- 강제 라운드 종료 이벤트
RegisterServerEvent('bumbercar:server:checkWinCondition')
AddEventHandler('bumbercar:server:checkWinCondition', function()
    CheckWinCondition()
end)

-- 데미지 기록 (통계용)
RegisterServerEvent('bumbercar:server:recordDamage')
AddEventHandler('bumbercar:server:recordDamage', function(targetId, damage)
    local source = source

    -- 플레이어 유효성 체크
    if not BumberCar.Players[source] or not BumberCar.Players[targetId] then
        return
    end

    -- 통계 업데이트
    BumberCar.Players[source].stats.damageDealt = (BumberCar.Players[source].stats.damageDealt or 0) + damage
    BumberCar.Players[targetId].stats.damageTaken = (BumberCar.Players[targetId].stats.damageTaken or 0) + damage

    Utils.Debug('Damage recorded:', GetPlayerName(source), '->', GetPlayerName(targetId), '=', damage)
end)

Utils.Success('Round system loaded!')
