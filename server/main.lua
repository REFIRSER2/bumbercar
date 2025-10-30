-- 서버 메인 파일
BumberCar = {}
BumberCar.Players = {}
BumberCar.GameState = Constants.RoundState.LOBBY
BumberCar.CurrentMap = nil
BumberCar.CurrentGameMode = Constants.GameMode.ITEM_FFA

-- 플레이어 데이터 초기화
function BumberCar.InitPlayer(source)
    BumberCar.Players[source] = {
        source = source,
        name = GetPlayerName(source),
        state = Constants.PlayerState.LOBBY,
        team = Constants.Team.NONE,
        ready = false,
        spectating = false,
        vehicle = nil,
        vehicleData = {
            health = Config.Vehicle.DefaultHealth,
            defense = Config.Vehicle.DefaultDefense,
            damage = Config.Vehicle.DefaultDamage,
            maxHealth = Config.Vehicle.DefaultHealth
        },
        items = {nil, nil}, -- 아이템 슬롯
        effects = {},       -- 활성 효과
        stats = {
            kills = 0,
            deaths = 0,
            damageDealt = 0,
            damageTaken = 0
        }
    }

    Utils.Debug('Player initialized:', source, GetPlayerName(source))
end

-- 플레이어 제거
function BumberCar.RemovePlayer(source)
    if BumberCar.Players[source] then
        BumberCar.Players[source] = nil
        Utils.Debug('Player removed:', source)

        -- 로비 업데이트
        TriggerEvent('bumbercar:server:updateLobby')
    end
end

-- 플레이어 데이터 가져오기
function BumberCar.GetPlayer(source)
    return BumberCar.Players[source]
end

-- 모든 플레이어 가져오기
function BumberCar.GetAllPlayers()
    return BumberCar.Players
end

-- 살아있는 플레이어 수 가져오기
function BumberCar.GetAlivePlayers()
    local count = 0
    for _, player in pairs(BumberCar.Players) do
        if player.state == Constants.PlayerState.PLAYING then
            count = count + 1
        end
    end
    return count
end

-- 팀별 살아있는 플레이어 수
function BumberCar.GetAlivePlayersByTeam(team)
    local count = 0
    for _, player in pairs(BumberCar.Players) do
        if player.state == Constants.PlayerState.PLAYING and player.team == team then
            count = count + 1
        end
    end
    return count
end

-- 알림 전송
function BumberCar.Notify(source, message, type)
    TriggerClientEvent('bumbercar:client:notify', source, message, type or 'info')
end

-- 모든 플레이어에게 알림
function BumberCar.NotifyAll(message, type)
    TriggerClientEvent('bumbercar:client:notify', -1, message, type or 'info')
end

-- 게임 상태 설정
function BumberCar.SetGameState(state)
    BumberCar.GameState = state
    TriggerClientEvent('bumbercar:client:stateChanged', -1, state)
    Utils.Debug('Game state changed to:', state)
end

-- 플레이어 연결
AddEventHandler('playerConnecting', function()
    local source = source
    BumberCar.InitPlayer(source)
end)

-- 플레이어 준비 완료
AddEventHandler('playerJoining', function()
    local source = source
    Citizen.Wait(1000)

    if BumberCar.Players[source] then
        -- 로비 상태면 자동으로 로비 열기
        local autoOpenLobby = (BumberCar.GameState == Constants.RoundState.LOBBY)
        TriggerClientEvent('bumbercar:client:initialize', source, autoOpenLobby)

        -- 로비 업데이트
        if BumberCar.GameState == Constants.RoundState.LOBBY then
            TriggerEvent('bumbercar:server:updateLobby')
        end
    end
end)

-- 플레이어 퇴장
AddEventHandler('playerDropped', function(reason)
    local source = source
    BumberCar.RemovePlayer(source)
end)

-- 리소스 시작
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Utils.Success('BumberCar resource started!')

        -- 모든 플레이어 초기화
        local players = GetPlayers()
        for _, playerId in ipairs(players) do
            local source = tonumber(playerId)
            BumberCar.InitPlayer(source)
            local autoOpenLobby = (BumberCar.GameState == Constants.RoundState.LOBBY)
            TriggerClientEvent('bumbercar:client:initialize', source, autoOpenLobby)
        end

        -- 첫 맵 설정
        BumberCar.CurrentMap = Config.DefaultMap

        -- 로비 업데이트
        TriggerEvent('bumbercar:server:updateLobby')
    end
end)

-- 리소스 종료
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Utils.Success('BumberCar resource stopped!')

        -- 모든 플레이어 정리
        for source, _ in pairs(BumberCar.Players) do
            TriggerClientEvent('bumbercar:client:cleanup', source)
        end
    end
end)

-- 커맨드: 로비 열기
RegisterCommand(Config.Commands.OpenLobby, function(source, args, rawCommand)
    if BumberCar.GameState == Constants.RoundState.LOBBY then
        TriggerClientEvent('bumbercar:client:openLobby', source)
    else
        BumberCar.Notify(source, '게임이 진행 중입니다', 'error')
    end
end)

-- 커맨드: 강제 시작 (관리자)
RegisterCommand(Config.Commands.ForceStart, function(source, args, rawCommand)
    if IsPlayerAceAllowed(source, Config.AdminPermissions[1]) then
        if BumberCar.GameState == Constants.RoundState.LOBBY then
            TriggerEvent('bumbercar:server:startGame')
        end
    else
        BumberCar.Notify(source, '권한이 없습니다', 'error')
    end
end)

-- 커맨드: 강제 종료 (관리자)
RegisterCommand(Config.Commands.ForceEnd, function(source, args, rawCommand)
    if IsPlayerAceAllowed(source, Config.AdminPermissions[1]) then
        if BumberCar.GameState ~= Constants.RoundState.LOBBY then
            TriggerEvent('bumbercar:server:endRound', nil)
        end
    else
        BumberCar.Notify(source, '권한이 없습니다', 'error')
    end
end)

-- 디버그 정보
if Config.Debug then
    RegisterCommand('bcdebug', function(source, args, rawCommand)
        print('======= BumberCar Debug Info =======')
        print('Game State:', BumberCar.GameState)
        print('Current Map:', BumberCar.CurrentMap)
        print('Game Mode:', BumberCar.CurrentGameMode)
        print('Total Players:', Utils.TableCount(BumberCar.Players))
        print('Alive Players:', BumberCar.GetAlivePlayers())
        print('===================================')
    end)
end

-- 테이블 카운트 유틸리티
function Utils.TableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end
