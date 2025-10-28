-- 라운드 시스템 (클라이언트)
local roundTimer = 0
local autoStartTimer = 0

-- 맵 설정
RegisterNetEvent('bumbercar:client:setMap')
AddEventHandler('bumbercar:client:setMap', function(mapId, mapData)
    BumberCar.CurrentMap = mapId

    Utils.Debug('Map set:', mapId)

    -- UI 업데이트
    SendNUIMessage({
        type = 'setMap',
        mapId = mapId,
        mapData = mapData
    })
end)

-- 라운드 타이머 시작
RegisterNetEvent('bumbercar:client:startRoundTimer')
AddEventHandler('bumbercar:client:startRoundTimer', function(time)
    roundTimer = time

    SendNUIMessage({
        type = 'startRoundTimer',
        time = time
    })
end)

-- 라운드 타이머 업데이트
RegisterNetEvent('bumbercar:client:updateRoundTimer')
AddEventHandler('bumbercar:client:updateRoundTimer', function(time)
    roundTimer = time

    SendNUIMessage({
        type = 'updateRoundTimer',
        time = time
    })
end)

-- 자동 시작 타이머
RegisterNetEvent('bumbercar:client:autoStartTimer')
AddEventHandler('bumbercar:client:autoStartTimer', function(time)
    autoStartTimer = time

    SendNUIMessage({
        type = 'autoStartTimer',
        time = time
    })
end)

-- 결과 표시
RegisterNetEvent('bumbercar:client:showResults')
AddEventHandler('bumbercar:client:showResults', function(results, winner)
    SendNUIMessage({
        type = 'showResults',
        results = results,
        winner = winner
    })

    SetNuiFocus(false, false)
end)

-- 로비로 복귀
RegisterNetEvent('bumbercar:client:returnToLobby')
AddEventHandler('bumbercar:client:returnToLobby', function()
    -- 차량 제거
    if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
        DeleteVehicle(BumberCar.CurrentVehicle)
        BumberCar.CurrentVehicle = nil
    end

    -- 상태 초기화
    BumberCar.PlayerState = Constants.PlayerState.LOBBY
    BumberCar.Items = {nil, nil}
    BumberCar.Effects = {}
    BumberCar.InBoundary = true
    BumberCar.IsReady = false

    -- 플레이어 리셋
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, 200)
    ClearPedTasksImmediately(playerPed)
    SetEntityVisible(playerPed, true, false)
    SetEntityCollision(playerPed, true, true)
    FreezeEntityPosition(playerPed, false)

    -- 로비 위치로 텔레포트
    local lobbySpawn = Config.Lobby.SpawnPoint
    SetEntityCoords(playerPed, lobbySpawn.x, lobbySpawn.y, lobbySpawn.z)
    SetEntityHeading(playerPed, lobbySpawn.w)

    -- UI 초기화
    SendNUIMessage({
        type = 'returnToLobby'
    })

    Utils.Debug('Returned to lobby')
end)

-- 라운드 타이머 표시
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if BumberCar.GameState == Constants.RoundState.PLAYING and roundTimer > 0 then
            -- 화면 상단에 타이머 표시
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString('시간: ' .. Utils.FormatTime(roundTimer))
            DrawText(0.5, 0.02)

            -- 마지막 30초 경고
            if roundTimer <= 30 then
                SetTextColour(255, 200, 0, 255)
            end

            -- 마지막 10초 경고
            if roundTimer <= 10 then
                SetTextColour(255, 0, 0, 255)
                SetTextScale(0.7, 0.7)
            end
        else
            Wait(500)
        end
    end
end)
