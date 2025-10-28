-- 차량 시스템 (클라이언트)

-- 차량 스폰 완료 알림
RegisterNetEvent('bumbercar:server:vehicleSpawned')
AddEventHandler('bumbercar:server:vehicleSpawned', function(vehicleNet)
    -- 서버에 차량 네트워크 ID 전송 완료
end)

-- 팀 색상 설정
RegisterNetEvent('bumbercar:client:setTeamColor')
AddEventHandler('bumbercar:client:setTeamColor', function(team)
    if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
        SetVehicleTeamColor(BumberCar.CurrentVehicle, team)
    end
end)

-- 보스 차량 설정
RegisterNetEvent('bumbercar:client:setBossVehicle')
AddEventHandler('bumbercar:client:setBossVehicle', function(isBoss)
    if isBoss and BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
        -- 보스 차량 무적 (밀림 방지)
        if Config.Boss.BossImmovable then
            SetEntityInvincible(BumberCar.CurrentVehicle, true)
            SetVehicleCanBeVisiblyDamaged(BumberCar.CurrentVehicle, false)
        end
    end
end)

-- 폭탄 모드 관련
local hasBomb = false
local bombTimerValue = 0

-- 폭탄 받기
RegisterNetEvent('bumbercar:client:receiveBomb')
AddEventHandler('bumbercar:client:receiveBomb', function(timer)
    hasBomb = true
    bombTimerValue = timer

    SendNUIMessage({
        type = 'receiveBomb',
        timer = timer
    })

    Utils.Debug('Received bomb, timer:', timer)
end)

-- 폭탄 제거
RegisterNetEvent('bumbercar:client:removeBomb')
AddEventHandler('bumbercar:client:removeBomb', function()
    hasBomb = false
    bombTimerValue = 0

    SendNUIMessage({
        type = 'removeBomb'
    })

    Utils.Debug('Bomb removed')
end)

-- 폭탄 타이머 업데이트
RegisterNetEvent('bumbercar:client:updateBombTimer')
AddEventHandler('bumbercar:client:updateBombTimer', function(timer)
    bombTimerValue = timer

    SendNUIMessage({
        type = 'updateBombTimer',
        timer = timer
    })
end)

-- 폭탄 폭발
RegisterNetEvent('bumbercar:client:explodeBomb')
AddEventHandler('bumbercar:client:explodeBomb', function(coords, radius)
    AddExplosion(coords.x, coords.y, coords.z, 7, 10.0, true, false, radius)
end)

-- 폭탄 전달 체크
Citizen.CreateThread(function()
    while true do
        Wait(100)

        if hasBomb and BumberCar.GameState == Constants.RoundState.PLAYING and BumberCar.CurrentVehicle then
            local myVehicle = BumberCar.CurrentVehicle
            local myCoords = GetEntityCoords(myVehicle)

            -- 주변 차량 체크
            local nearbyVehicles = GetNearbyVehicles(myCoords, 5.0)
            for _, vehicle in ipairs(nearbyVehicles) do
                if vehicle ~= myVehicle then
                    -- 충돌 체크
                    if HasEntityCollidedWithEntity(myVehicle, vehicle, false) then
                        -- 다른 플레이어 찾기
                        local players = GetActivePlayers()
                        for _, playerId in ipairs(players) do
                            if playerId ~= PlayerId() then
                                local targetPed = GetPlayerPed(playerId)
                                local targetVehicle = GetVehiclePedIsIn(targetPed, false)

                                if targetVehicle == vehicle then
                                    -- 폭탄 전달
                                    TriggerServerEvent('bumbercar:server:transferBomb', GetPlayerServerId(playerId))
                                    hasBomb = false
                                    break
                                end
                            end
                        end
                        break
                    end
                end
            end
        else
            Wait(500)
        end
    end
end)

-- 폭탄 타이머 표시
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if hasBomb and bombTimerValue > 0 then
            -- 화면 중앙에 크게 표시
            SetTextFont(4)
            SetTextScale(1.5, 1.5)
            SetTextColour(255, 0, 0, 255)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString('폭탄: ' .. bombTimerValue .. '초')
            DrawText(0.5, 0.3)

            -- 경고 화면 효과
            if bombTimerValue <= 10 then
                DrawRect(0.5, 0.5, 1.0, 1.0, 255, 0, 0, math.floor(math.sin(GetGameTimer() / 100.0) * 50 + 50))
            end
        else
            Wait(500)
        end
    end
end)

-- 보조 함수: 주변 차량 가져오기
function GetNearbyVehicles(coords, radius)
    local vehicles = {}
    local handle, vehicle = FindFirstVehicle()
    local success

    repeat
        local vehCoords = GetEntityCoords(vehicle)
        if #(coords - vehCoords) <= radius then
            table.insert(vehicles, vehicle)
        end
        success, vehicle = FindNextVehicle(handle)
    until not success

    EndFindVehicle(handle)
    return vehicles
end
