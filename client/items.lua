-- 아이템 시스템 (클라이언트)
local items = {}
local playerItems = {nil, nil}
local activeEffects = {}

-- 아이템 스폰
RegisterNetEvent('bumbercar:client:spawnItem')
AddEventHandler('bumbercar:client:spawnItem', function(itemIndex, itemId, position, itemData)
    items[itemIndex] = {
        id = itemIndex,
        itemId = itemId,
        position = position,
        data = itemData,
        active = true
    }

    Utils.Debug('Item spawned:', itemData.name, 'at', position)
end)

-- 아이템 제거
RegisterNetEvent('bumbercar:client:removeItem')
AddEventHandler('bumbercar:client:removeItem', function(itemIndex)
    if items[itemIndex] then
        items[itemIndex].active = false
    end
end)

-- 아이템 획득 체크
Citizen.CreateThread(function()
    while true do
        Wait(200)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING then

            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for itemIndex, item in pairs(items) do
                if item.active then
                    local distance = #(playerCoords - item.position)

                    if distance <= Config.ItemSpawn.PickupRadius then
                        -- 아이템 획득
                        TriggerServerEvent('bumbercar:server:pickupItem', itemIndex)
                        items[itemIndex].active = false
                        break
                    end
                end
            end
        end
    end
end)

-- 아이템 렌더링
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if BumberCar.GameState == Constants.RoundState.PLAYING and Config.ItemSpawn.ShowMarker then
            local playerCoords = GetEntityCoords(PlayerPedId())

            for _, item in pairs(items) do
                if item.active then
                    local distance = #(playerCoords - item.position)

                    if distance <= Config.ItemSpawn.ShowRadius then
                        local pos = item.position

                        -- 마커 표시
                        if Config.ItemSpawn.ShowMarker then
                            local markerZ = pos.z
                            if Config.ItemSpawn.BobMarker then
                                markerZ = markerZ + math.sin(GetGameTimer() / 500.0) * 0.3
                            end

                            local color = Utils.HexToRGB(item.data.color)
                            DrawMarker(
                                Config.ItemSpawn.MarkerType,
                                pos.x, pos.y, markerZ,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, Config.ItemSpawn.RotateMarker and (GetGameTimer() / 10.0) or 0.0,
                                Config.ItemSpawn.MarkerSize.x,
                                Config.ItemSpawn.MarkerSize.y,
                                Config.ItemSpawn.MarkerSize.z,
                                color.r, color.g, color.b, color.a,
                                true, true, 2, false, nil, nil, false
                            )
                        end

                        -- 3D 텍스트 (아이템 이름)
                        if Config.ItemSpawn.ShowText and distance <= 20.0 then
                            SendNUIMessage({
                                type = 'show3DText',
                                id = 'item_' .. item.id,
                                text = item.data.icon .. ' ' .. item.data.name,
                                position = {x = pos.x, y = pos.y, z = pos.z + 1.0}
                            })
                        end
                    end
                end
            end
        else
            Wait(500)
        end
    end
end)

-- 아이템 슬롯 업데이트
RegisterNetEvent('bumbercar:client:updateItemSlot')
AddEventHandler('bumbercar:client:updateItemSlot', function(slotIndex, itemId, itemData)
    playerItems[slotIndex] = itemId

    SendNUIMessage({
        type = 'updateItemSlot',
        slot = slotIndex,
        itemId = itemId,
        itemData = itemData
    })
end)

-- 아이템 사용 키 입력
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING then

            -- 슬롯 1 (G 키)
            if IsControlJustPressed(0, Constants.Keys.ITEM_SLOT_1) then
                if playerItems[1] then
                    TriggerServerEvent('bumbercar:server:useItem', 1)
                end
            end

            -- 슬롯 2 (H 키)
            if IsControlJustPressed(0, Constants.Keys.ITEM_SLOT_2) then
                if playerItems[2] then
                    TriggerServerEvent('bumbercar:server:useItem', 2)
                end
            end
        else
            Wait(500)
        end
    end
end)

-- 효과 추가
RegisterNetEvent('bumbercar:client:addEffect')
AddEventHandler('bumbercar:client:addEffect', function(effectName, duration)
    activeEffects[effectName] = {
        endTime = GetGameTimer() + (duration * 1000)
    }

    SendNUIMessage({
        type = 'addEffect',
        effectName = effectName,
        duration = duration
    })
end)

-- 효과 제거
RegisterNetEvent('bumbercar:client:removeEffect')
AddEventHandler('bumbercar:client:removeEffect', function(effectName)
    activeEffects[effectName] = nil

    SendNUIMessage({
        type = 'removeEffect',
        effectName = effectName
    })
end)

-- 차량 변경
RegisterNetEvent('bumbercar:client:changeToRandomVehicle')
AddEventHandler('bumbercar:client:changeToRandomVehicle', function(keepStats)
    if not BumberCar.CurrentVehicle or not DoesEntityExist(BumberCar.CurrentVehicle) then return end

    local oldVehicle = BumberCar.CurrentVehicle
    local pos = GetEntityCoords(oldVehicle)
    local heading = GetEntityHeading(oldVehicle)

    -- 랜덤 차량 선택
    local randomVehicle = Utils.GetRandomElement(Config.Vehicles.Regular)
    local modelHash = GetHashKey(randomVehicle.model)

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end

    -- 새 차량 생성
    local newVehicle = CreateVehicle(modelHash, pos.x, pos.y, pos.z, heading, true, false)
    SetVehicleEngineOn(newVehicle, true, true, false)

    -- 플레이어 탑승
    TaskWarpPedIntoVehicle(PlayerPedId(), newVehicle, -1)

    -- 기존 차량 제거
    DeleteVehicle(oldVehicle)

    BumberCar.CurrentVehicle = newVehicle

    -- 스탯 유지하지 않는 경우 서버에 알림
    if not keepStats then
        TriggerServerEvent('bumbercar:server:vehicleChanged', VehToNet(newVehicle), randomVehicle)
    end
end)

-- 속도 부스트
RegisterNetEvent('bumbercar:client:applySpeedBoost')
AddEventHandler('bumbercar:client:applySpeedBoost', function(multiplier, duration)
    if not BumberCar.CurrentVehicle then return end

    SetVehicleEnginePowerMultiplier(BumberCar.CurrentVehicle, multiplier * 100.0)

    Citizen.SetTimeout(duration * 1000, function()
        if DoesEntityExist(BumberCar.CurrentVehicle) then
            SetVehicleEnginePowerMultiplier(BumberCar.CurrentVehicle, 100.0)
        end
    end)
end)

-- 부스트
RegisterNetEvent('bumbercar:client:applyBoost')
AddEventHandler('bumbercar:client:applyBoost', function(force, duration)
    if not BumberCar.CurrentVehicle then return end

    local vehicle = BumberCar.CurrentVehicle
    local forwardVector = GetEntityForwardVector(vehicle)

    SetVehicleForwardSpeed(vehicle, GetVehicleEstimatedMaxSpeed(vehicle))
    ApplyForceToEntity(vehicle, 1, forwardVector.x * force, forwardVector.y * force, 0.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
end)

-- 점프
RegisterNetEvent('bumbercar:client:applyJump')
AddEventHandler('bumbercar:client:applyJump', function(force)
    if not BumberCar.CurrentVehicle then return end

    ApplyForceToEntity(BumberCar.CurrentVehicle, 1, 0.0, 0.0, force, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
end)

-- 정지 (다른 플레이어)
RegisterNetEvent('bumbercar:client:applyFreeze')
AddEventHandler('bumbercar:client:applyFreeze', function(range, duration)
    local playerCoords = GetEntityCoords(PlayerPedId())

    -- 가장 가까운 적 찾기
    local nearestEnemy = nil
    local nearestDistance = range

    for playerId, _ in pairs(BumberCar.Players or {}) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)

            if distance < nearestDistance then
                nearestDistance = distance
                nearestEnemy = targetPed
            end
        end
    end

    if nearestEnemy then
        local vehicle = GetVehiclePedIsIn(nearestEnemy, false)
        if vehicle and vehicle ~= 0 then
            FreezeEntityPosition(vehicle, true)

            Citizen.SetTimeout(duration * 1000, function()
                if DoesEntityExist(vehicle) then
                    FreezeEntityPosition(vehicle, false)
                end
            end)
        end
    end
end)

-- 폭발
RegisterNetEvent('bumbercar:client:applyExplosion')
AddEventHandler('bumbercar:client:applyExplosion', function(radius, damage)
    local playerCoords = GetEntityCoords(PlayerPedId())
    AddExplosion(playerCoords.x, playerCoords.y, playerCoords.z, 7, damage / 100.0, true, false, radius)
end)
