-- ============================================
-- 범퍼카 클라이언트 메인 파일
-- 전역 상태 관리, 초기화, NUI 콜백 처리
-- ============================================

-- 전역 BumberCar 테이블 초기화
BumberCar = {
    -- 게임 상태
    GameState = Constants.RoundState.LOBBY,
    PlayerState = Constants.PlayerState.LOBBY,

    -- 차량 및 맵 정보
    CurrentVehicle = nil,
    CurrentMap = nil,
    CurrentGameMode = nil,

    -- 플레이어 상태
    IsReady = false,
    IsSpectating = false,

    -- 아이템 및 효과
    Items = {nil, nil},
    Effects = {},

    -- 경계 체크
    InBoundary = true,

    -- 차량 데이터
    VehicleData = {
        health = Config.Vehicle.DefaultHealth,
        defense = Config.Vehicle.DefaultDefense,
        damage = Config.Vehicle.DefaultDamage,
        maxHealth = Config.Vehicle.DefaultHealth
    },

    -- 무기 데이터 (무기전용)
    Weapon = {
        id = nil,
        ammo = 0
    },

    -- 라운드 정보
    RoundTime = 0,
    RoundStartTime = 0
}

-- ============================================
-- 초기화 및 클린업
-- ============================================

-- 클라이언트 초기화
RegisterNetEvent('bumbercar:client:initialize')
AddEventHandler('bumbercar:client:initialize', function(autoOpenLobby)
    Utils.Debug('Client initialized, auto open lobby:', autoOpenLobby)

    -- 로비 스폰 위치로 텔레포트
    local lobbySpawn = Config.Lobby.SpawnPoint
    local playerPed = PlayerPedId()

    SetEntityCoords(playerPed, lobbySpawn.x, lobbySpawn.y, lobbySpawn.z, false, false, false, true)
    SetEntityHeading(playerPed, lobbySpawn.w)

    -- 플레이어 기본 설정
    SetEntityHealth(playerPed, 200)
    SetEntityInvincible(playerPed, false)

    -- UI 초기화
    SendNUIMessage({
        type = 'initialize',
        data = {
            config = {
                debug = Config.Debug,
                language = Config.UI.Language
            }
        }
    })

    -- 로비가 대기 상태면 자동으로 열기 (1초 딜레이)
    if autoOpenLobby then
        Citizen.SetTimeout(1000, function()
            Utils.Debug('Auto-opening lobby after initialization')
            TriggerEvent('bumbercar:client:openLobby')
        end)
    end
end)

-- 클린업
RegisterNetEvent('bumbercar:client:cleanup')
AddEventHandler('bumbercar:client:cleanup', function()
    Utils.Debug('Client cleanup initiated')

    -- 차량 제거
    if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
        DeleteVehicle(BumberCar.CurrentVehicle)
        BumberCar.CurrentVehicle = nil
    end

    -- 상태 초기화
    BumberCar.GameState = Constants.RoundState.LOBBY
    BumberCar.PlayerState = Constants.PlayerState.LOBBY
    BumberCar.Items = {nil, nil}
    BumberCar.Effects = {}
    BumberCar.InBoundary = true

    -- NUI 정리
    SendNUIMessage({
        type = 'cleanup'
    })

    SetNuiFocus(false, false)
end)

-- ============================================
-- 게임 상태 관리
-- ============================================

-- 게임 상태 변경
RegisterNetEvent('bumbercar:client:stateChanged')
AddEventHandler('bumbercar:client:stateChanged', function(newState, data)
    local oldState = BumberCar.GameState
    BumberCar.GameState = newState

    Utils.Debug('Game state changed:', oldState, '->', newState)

    -- UI 업데이트
    SendNUIMessage({
        type = 'stateChanged',
        state = newState,
        data = data or {}
    })

    -- 상태별 처리
    if newState == Constants.RoundState.LOBBY then
        -- 로비로 돌아감
        BumberCar.PlayerState = Constants.PlayerState.LOBBY

    elseif newState == Constants.RoundState.STARTING then
        -- 게임 시작 준비
        Utils.Debug('Game starting soon...')

    elseif newState == Constants.RoundState.PREPARE then
        -- 준비 시간
        BumberCar.PlayerState = Constants.PlayerState.PLAYING

    elseif newState == Constants.RoundState.PLAYING then
        -- 게임 진행 중
        if BumberCar.PlayerState ~= Constants.PlayerState.SPECTATING then
            BumberCar.PlayerState = Constants.PlayerState.PLAYING
        end

    elseif newState == Constants.RoundState.ENDING then
        -- 게임 종료
        Utils.Debug('Game ending...')
    end
end)

-- 플레이어 상태 업데이트
RegisterNetEvent('bumbercar:client:updatePlayerState')
AddEventHandler('bumbercar:client:updatePlayerState', function(newState)
    BumberCar.PlayerState = newState
    Utils.Debug('Player state updated:', newState)
end)

-- ============================================
-- 알림 시스템
-- ============================================

-- 알림 표시
RegisterNetEvent('bumbercar:client:notify')
AddEventHandler('bumbercar:client:notify', function(message, notifType)
    notifType = notifType or 'info'

    -- FiveM 기본 알림
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)

    -- NUI 커스텀 알림
    SendNUIMessage({
        type = 'notify',
        data = {
            message = message,
            notifType = notifType
        }
    })

    Utils.Debug('Notification:', message, '(', notifType, ')')
end)

-- ============================================
-- 로비 시스템
-- ============================================

-- 로비 열기
RegisterNetEvent('bumbercar:client:openLobby')
AddEventHandler('bumbercar:client:openLobby', function()
    Utils.Debug('Attempting to open lobby, current state:', BumberCar.GameState)

    -- 로비 상태일 때만 열기
    if BumberCar.GameState == Constants.RoundState.LOBBY then
        -- 서버에서 로비 데이터 요청
        TriggerServerEvent('bumbercar:server:requestLobbyData')

        -- 로비 UI 표시
        SendNUIMessage({
            type = Constants.UIEvent.SHOW_LOBBY
        })

        SetNuiFocus(true, true)

        Utils.Debug('Lobby opened successfully')
    else
        Utils.Debug('Cannot open lobby - not in lobby state')
        TriggerEvent('bumbercar:client:notify', '현재 로비를 열 수 없습니다', 'error')
    end
end)

-- 로비 닫기 (NUI 콜백)
RegisterNUICallback('closeLobby', function(data, cb)
    Utils.Debug('Closing lobby')

    SendNUIMessage({
        type = Constants.UIEvent.HIDE_LOBBY
    })

    SetNuiFocus(false, false)
    cb('ok')
end)

-- 준비 완료/해제 토글 (NUI 콜백)
RegisterNUICallback('toggleReady', function(data, cb)
    local ready = data.ready or false
    BumberCar.IsReady = ready

    Utils.Debug('Toggle ready:', ready)
    TriggerServerEvent('bumbercar:server:toggleReady', ready)

    cb('ok')
end)

-- 관전 모드 토글 (NUI 콜백)
RegisterNUICallback('toggleSpectate', function(data, cb)
    local spectate = data.spectate or false
    BumberCar.IsSpectating = spectate

    Utils.Debug('Toggle spectate:', spectate)
    TriggerServerEvent('bumbercar:server:toggleSpectate', spectate)

    cb('ok')
end)

-- 맵 선택 (NUI 콜백)
RegisterNUICallback('selectMap', function(data, cb)
    local mapId = data.map

    Utils.Debug('Selecting map:', mapId)
    TriggerServerEvent('bumbercar:server:selectMap', mapId)

    cb('ok')
end)

-- 게임 모드 선택 (NUI 콜백)
RegisterNUICallback('selectGameMode', function(data, cb)
    local gameMode = data.gameMode

    Utils.Debug('Selecting game mode:', gameMode)
    TriggerServerEvent('bumbercar:server:selectGameMode', gameMode)

    cb('ok')
end)

-- 로비 채팅 전송 (NUI 콜백)
RegisterNUICallback('sendLobbyChat', function(data, cb)
    local message = data.message

    if message and #message > 0 then
        Utils.Debug('Sending lobby chat:', message)
        TriggerServerEvent('bumbercar:server:lobbyChat', message)
    end

    cb('ok')
end)

-- 로비 채팅 메시지 수신
RegisterNetEvent('bumbercar:client:lobbyChatMessage')
AddEventHandler('bumbercar:client:lobbyChatMessage', function(author, message, timestamp)
    SendNUIMessage({
        type = 'lobbyChatMessage',
        data = {
            author = author,
            message = message,
            timestamp = timestamp or os.time()
        }
    })
end)

-- ============================================
-- 라운드 이벤트
-- ============================================

-- 라운드 시작
RegisterNetEvent('bumbercar:client:roundStart')
AddEventHandler('bumbercar:client:roundStart', function(roundData)
    Utils.Debug('Round started:', roundData.mode, 'on map:', roundData.map)

    -- 라운드 정보 저장
    BumberCar.CurrentGameMode = roundData.mode
    BumberCar.CurrentMap = roundData.map
    BumberCar.RoundTime = roundData.time or Config.Round.RoundTime
    BumberCar.RoundStartTime = GetGameTimer()

    -- UI 업데이트
    SendNUIMessage({
        type = 'roundStart',
        data = roundData
    })

    -- 로비 닫기
    SetNuiFocus(false, false)
end)

-- 라운드 종료
RegisterNetEvent('bumbercar:client:roundEnd')
AddEventHandler('bumbercar:client:roundEnd', function(results)
    Utils.Debug('Round ended')

    -- 결과 화면 표시
    SendNUIMessage({
        type = 'showResults',
        data = results
    })

    SetNuiFocus(false, false)
end)

-- 로비로 복귀
RegisterNetEvent('bumbercar:client:returnToLobby')
AddEventHandler('bumbercar:client:returnToLobby', function()
    Utils.Debug('Returning to lobby')

    -- 차량 제거
    if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
        DeleteVehicle(BumberCar.CurrentVehicle)
        BumberCar.CurrentVehicle = nil
    end

    -- 상태 초기화
    BumberCar.GameState = Constants.RoundState.LOBBY
    BumberCar.PlayerState = Constants.PlayerState.LOBBY
    BumberCar.Items = {nil, nil}
    BumberCar.Effects = {}
    BumberCar.InBoundary = true
    BumberCar.IsReady = false
    BumberCar.CurrentMap = nil
    BumberCar.CurrentGameMode = nil
    BumberCar.VehicleData = {
        health = Config.Vehicle.DefaultHealth,
        defense = Config.Vehicle.DefaultDefense,
        damage = Config.Vehicle.DefaultDamage,
        maxHealth = Config.Vehicle.DefaultHealth
    }

    -- 플레이어 리셋
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, 200)
    ClearPedTasksImmediately(playerPed)
    SetEntityVisible(playerPed, true, false)
    SetEntityAlpha(playerPed, 255, false)
    SetEntityCollision(playerPed, true, true)
    FreezeEntityPosition(playerPed, false)
    NetworkSetInSpectatorMode(false, playerPed)

    -- 로비 위치로 텔레포트
    local lobbySpawn = Config.Lobby.SpawnPoint
    SetEntityCoords(playerPed, lobbySpawn.x, lobbySpawn.y, lobbySpawn.z, false, false, false, true)
    SetEntityHeading(playerPed, lobbySpawn.w)

    -- UI 초기화
    SendNUIMessage({
        type = 'returnToLobby'
    })
end)

-- ============================================
-- 차량 체력 업데이트
-- ============================================

-- 차량 체력 업데이트
RegisterNetEvent('bumbercar:client:updateHealth')
AddEventHandler('bumbercar:client:updateHealth', function(health, maxHealth, damage, defense)
    BumberCar.VehicleData.health = health
    BumberCar.VehicleData.maxHealth = maxHealth

    if damage then
        BumberCar.VehicleData.damage = damage
    end

    if defense then
        BumberCar.VehicleData.defense = defense
    end

    -- UI 업데이트
    SendNUIMessage({
        type = 'updateHealth',
        data = {
            health = health,
            maxHealth = maxHealth,
            percentage = Utils.GetPercentage(health, maxHealth),
            damage = BumberCar.VehicleData.damage,
            defense = BumberCar.VehicleData.defense
        }
    })
end)

-- ============================================
-- 메인 루프
-- ============================================

-- 물 체크 및 기타 지속적인 체크
Citizen.CreateThread(function()
    while true do
        Wait(500)

        -- 게임 진행 중일 때만
        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING then

            -- 차량이 있을 때
            if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
                local vehicle = BumberCar.CurrentVehicle

                -- 물에 빠졌는지 체크
                if IsEntityInWater(vehicle) then
                    Utils.Debug('Vehicle entered water - boundary death')
                    TriggerServerEvent('bumbercar:server:boundaryDeath')
                end

                -- 차량이 뒤집혔는지 체크 (10초 이상)
                if IsVehicleOnAllWheels(vehicle) == false then
                    -- 뒤집힌 차량 처리는 서버에서 관리
                end
            end
        end
    end
end)

-- ============================================
-- 리소스 종료 처리
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Utils.Debug('Resource stopping - cleanup')

        -- 차량 제거
        if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
            DeleteVehicle(BumberCar.CurrentVehicle)
        end

        -- NUI 정리
        SetNuiFocus(false, false)

        -- 플레이어 상태 복구
        local playerPed = PlayerPedId()
        SetEntityVisible(playerPed, true, false)
        SetEntityAlpha(playerPed, 255, false)
        SetEntityCollision(playerPed, true, true)
        FreezeEntityPosition(playerPed, false)
        NetworkSetInSpectatorMode(false, playerPed)
    end
end)

Utils.Debug('Main client file loaded')
