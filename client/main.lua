-- 클라이언트 메인 파일
BumberCar = {}
BumberCar.GameState = Constants.RoundState.LOBBY
BumberCar.PlayerState = Constants.PlayerState.LOBBY
BumberCar.CurrentVehicle = nil
BumberCar.CurrentMap = nil
BumberCar.Items = {nil, nil}
BumberCar.Effects = {}
BumberCar.InBoundary = true
BumberCar.IsReady = false
BumberCar.IsSpectating = false

-- 초기화
RegisterNetEvent('bumbercar:client:initialize')
AddEventHandler('bumbercar:client:initialize', function()
    Utils.Debug('Client initialized')

    -- 로비로 텔레포트
    local lobbySpawn = Config.Lobby.SpawnPoint
    SetEntityCoords(PlayerPedId(), lobbySpawn.x, lobbySpawn.y, lobbySpawn.z)
    SetEntityHeading(PlayerPedId(), lobbySpawn.w)

    -- UI 초기화
    SendNUIMessage({
        type = 'initialize'
    })
end)

-- 정리
RegisterNetEvent('bumbercar:client:cleanup')
AddEventHandler('bumbercar:client:cleanup', function()
    Utils.Debug('Client cleanup')

    -- 차량 제거
    if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
        DeleteVehicle(BumberCar.CurrentVehicle)
    end

    -- UI 닫기
    SendNUIMessage({
        type = 'cleanup'
    })
end)

-- 게임 상태 변경
RegisterNetEvent('bumbercar:client:stateChanged')
AddEventHandler('bumbercar:client:stateChanged', function(state)
    BumberCar.GameState = state
    Utils.Debug('Game state changed:', state)

    -- UI 업데이트
    SendNUIMessage({
        type = 'stateChanged',
        state = state
    })
end)

-- 알림
RegisterNetEvent('bumbercar:client:notify')
AddEventHandler('bumbercar:client:notify', function(message, notifType)
    -- FiveM 기본 알림
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)

    -- NUI 알림 (커스텀)
    SendNUIMessage({
        type = 'notify',
        message = message,
        notifType = notifType
    })
end)

-- 로비 열기
RegisterNetEvent('bumbercar:client:openLobby')
AddEventHandler('bumbercar:client:openLobby', function()
    if BumberCar.GameState == Constants.RoundState.LOBBY then
        SendNUIMessage({
            type = Constants.UIEvent.SHOW_LOBBY
        })
        SetNuiFocus(true, true)
    end
end)

-- 로비 닫기
RegisterNUICallback('closeLobby', function(data, cb)
    SendNUIMessage({
        type = Constants.UIEvent.HIDE_LOBBY
    })
    SetNuiFocus(false, false)
    cb('ok')
end)

-- 준비 완료/해제
RegisterNUICallback('toggleReady', function(data, cb)
    BumberCar.IsReady = not BumberCar.IsReady
    TriggerServerEvent('bumbercar:server:toggleReady', BumberCar.IsReady)
    cb('ok')
end)

-- 관전 모드 토글
RegisterNUICallback('toggleSpectate', function(data, cb)
    BumberCar.IsSpectating = not BumberCar.IsSpectating
    TriggerServerEvent('bumbercar:server:toggleSpectate', BumberCar.IsSpectating)
    cb('ok')
end)

-- 맵 선택
RegisterNUICallback('selectMap', function(data, cb)
    TriggerServerEvent('bumbercar:server:selectMap', data.map)
    cb('ok')
end)

-- 게임 모드 선택
RegisterNUICallback('selectGameMode', function(data, cb)
    TriggerServerEvent('bumbercar:server:selectGameMode', data.gameMode)
    cb('ok')
end)

-- 차량 스폰
RegisterNetEvent('bumbercar:client:spawnVehicle')
AddEventHandler('bumbercar:client:spawnVehicle', function(vehicleModel, spawnPoint, vehicleData)
    -- 기존 차량 제거
    if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
        DeleteVehicle(BumberCar.CurrentVehicle)
    end

    -- 모델 로드
    local modelHash = GetHashKey(vehicleModel)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end

    -- 차량 생성
    local vehicle = CreateVehicle(modelHash, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, true, false)

    -- 차량 설정
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleNumberPlateText(vehicle, 'BUMPER')

    -- 무적 시간
    if Config.Vehicle.InvincibleOnSpawn then
        SetEntityInvincible(vehicle, true)
        Citizen.SetTimeout(Config.Vehicle.InvincibleTime * 1000, function()
            if DoesEntityExist(vehicle) then
                SetEntityInvincible(vehicle, false)
            end
        end)
    end

    -- 플레이어 탑승
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

    BumberCar.CurrentVehicle = vehicle

    Utils.Debug('Vehicle spawned:', vehicleModel, 'at', spawnPoint)

    -- 서버에 차량 알림
    TriggerServerEvent('bumbercar:server:vehicleSpawned', VehToNet(vehicle))
end)

-- 차량 색상 설정
function SetVehicleTeamColor(vehicle, team)
    if not DoesEntityExist(vehicle) then return end

    local colors = Config.TeamColors[team]
    if colors then
        SetVehicleCustomPrimaryColour(vehicle, colors.primary.r, colors.primary.g, colors.primary.b)
        SetVehicleCustomSecondaryColour(vehicle, colors.secondary.r, colors.secondary.g, colors.secondary.b)
    end
end

-- 차량 업그레이드 적용
function ApplyVehicleUpgrades(vehicle)
    if not DoesEntityExist(vehicle) then return end

    if Config.VehicleCustomization.MaxUpgrades then
        SetVehicleModKit(vehicle, 0)
        for i = 0, 49 do
            local maxMod = GetNumVehicleMods(vehicle, i) - 1
            SetVehicleMod(vehicle, i, maxMod, false)
        end
    end

    if Config.VehicleCustomization.Turbo then
        ToggleVehicleMod(vehicle, 18, true)
    end
end

-- 메인 루프
Citizen.CreateThread(function()
    while true do
        Wait(0)

        local playerPed = PlayerPedId()

        -- 게임 진행 중일 때만
        if BumberCar.GameState == Constants.RoundState.PLAYING and BumberCar.PlayerState == Constants.PlayerState.PLAYING then
            -- 차량 체크
            if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
                local vehicle = BumberCar.CurrentVehicle

                -- 물 체크
                if IsEntityInWater(vehicle) then
                    TriggerServerEvent('bumbercar:server:boundaryDeath')
                end
            end
        end
    end
end)

-- 리소스 종료 시
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- 차량 제거
        if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
            DeleteVehicle(BumberCar.CurrentVehicle)
        end

        -- NUI 정리
        SetNuiFocus(false, false)
    end
end)
