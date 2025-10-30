-- ============================================
-- 범퍼카 아이템 시스템 (클라이언트)
-- 아이템 스폰, 획득, 사용, 효과
-- ============================================

local activeItems = {}  -- 필드에 스폰된 아이템
local playerItems = {nil, nil}  -- 플레이어 슬롯 [1], [2]
local activeEffects = {}  -- 활성화된 버프/디버프
local itemCooldowns = {}  -- 아이템 쿨다운

-- 폭탄 모드 관련
local hasBomb = false
local bombTimer = 0
local bombHolder = nil

-- ============================================
-- 아이템 스폰 및 제거
-- ============================================

-- 아이템 스폰
RegisterNetEvent('bumbercar:client:spawnItem')
AddEventHandler('bumbercar:client:spawnItem', function(itemIndex, itemId, position, itemData)
    activeItems[itemIndex] = {
        id = itemIndex,
        itemId = itemId,
        position = vector3(position.x, position.y, position.z),
        data = itemData,
        active = true
    }

    Utils.Debug('Item spawned:', itemData.name, 'at index', itemIndex)
end)

-- 아이템 제거
RegisterNetEvent('bumbercar:client:removeItem')
AddEventHandler('bumbercar:client:removeItem', function(itemIndex)
    if activeItems[itemIndex] then
        activeItems[itemIndex].active = false
        activeItems[itemIndex] = nil
        Utils.Debug('Item removed:', itemIndex)
    end
end)

-- 모든 아이템 클리어
RegisterNetEvent('bumbercar:client:clearAllItems')
AddEventHandler('bumbercar:client:clearAllItems', function()
    activeItems = {}
    Utils.Debug('All items cleared')
end)

-- ============================================
-- 아이템 획득 감지
-- ============================================

-- 아이템 획득 체크 루프
Citizen.CreateThread(function()
    while true do
        Wait(200)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING and
           Config.Items.Enabled then

            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            -- 가장 가까운 아이템 찾기
            local nearestItem = nil
            local nearestDistance = Config.Items.PickupDistance

            for itemIndex, item in pairs(activeItems) do
                if item.active then
                    local distance = #(playerCoords - item.position)

                    if distance <= nearestDistance then
                        nearestDistance = distance
                        nearestItem = item
                    end
                end
            end

            -- 아이템 획득
            if nearestItem then
                -- E 키 힌트 표시
                SendNUIMessage({
                    type = 'showItemHint',
                    data = {
                        itemName = nearestItem.data.name,
                        distance = nearestDistance
                    }
                })

                -- E 키로 획득
                if IsControlJustPressed(0, 38) then -- E 키
                    TriggerServerEvent('bumbercar:server:pickupItem', nearestItem.id)
                    activeItems[nearestItem.id] = nil
                end
            else
                -- 힌트 숨기기
                SendNUIMessage({
                    type = 'hideItemHint'
                })
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================
-- 아이템 획득 확인
-- ============================================

-- 아이템 획득 확인 (서버에서)
RegisterNetEvent('bumbercar:client:itemPickedUp')
AddEventHandler('bumbercar:client:itemPickedUp', function(itemIndex)
    if activeItems[itemIndex] then
        activeItems[itemIndex].active = false
        activeItems[itemIndex] = nil
    end
end)

-- 아이템 슬롯에 추가
RegisterNetEvent('bumbercar:client:itemAdded')
AddEventHandler('bumbercar:client:itemAdded', function(slot, itemId, itemData)
    playerItems[slot] = {
        itemId = itemId,
        data = itemData
    }

    BumberCar.Items[slot] = itemId

    Utils.Debug('Item added to slot', slot, ':', itemData.name)

    -- UI 업데이트
    SendNUIMessage({
        type = 'updateItemSlot',
        data = {
            slot = slot,
            itemId = itemId,
            itemData = itemData
        }
    })

    -- 알림
    TriggerEvent('bumbercar:client:notify',
        string.format(Config.Notifications.ItemPickup, itemData.name),
        'success')
end)

-- 아이템 슬롯에서 제거
RegisterNetEvent('bumbercar:client:itemRemoved')
AddEventHandler('bumbercar:client:itemRemoved', function(slot)
    playerItems[slot] = nil
    BumberCar.Items[slot] = nil

    Utils.Debug('Item removed from slot', slot)

    -- UI 업데이트
    SendNUIMessage({
        type = 'updateItemSlot',
        data = {
            slot = slot,
            itemId = nil,
            itemData = nil
        }
    })
end)

-- ============================================
-- 아이템 사용
-- ============================================

-- 아이템 사용 키 입력
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING then

            -- 슬롯 1 (G 키)
            if IsControlJustPressed(0, Constants.Keys.ITEM_SLOT_1) then
                if playerItems[1] then
                    UseItem(1)
                end
            end

            -- 슬롯 2 (H 키)
            if IsControlJustPressed(0, Constants.Keys.ITEM_SLOT_2) then
                if playerItems[2] then
                    UseItem(2)
                end
            end

        else
            Wait(500)
        end
    end
end)

-- 아이템 사용 함수
function UseItem(slot)
    local item = playerItems[slot]

    if not item then
        return
    end

    -- 쿨다운 체크
    local cooldownKey = 'slot_' .. slot
    if itemCooldowns[cooldownKey] and GetGameTimer() < itemCooldowns[cooldownKey] then
        local remaining = math.ceil((itemCooldowns[cooldownKey] - GetGameTimer()) / 1000)
        TriggerEvent('bumbercar:client:notify',
            string.format('아이템 쿨다운: %d초', remaining),
            'warning')
        return
    end

    Utils.Debug('Using item from slot', slot, ':', item.data.name)

    -- 서버에 아이템 사용 알림
    TriggerServerEvent('bumbercar:server:useItem', slot)

    -- 쿨다운 설정 (아이템에 쿨다운이 있으면)
    if item.data.cooldown then
        itemCooldowns[cooldownKey] = GetGameTimer() + (item.data.cooldown * 1000)
    end
end)

-- ============================================
-- 효과 적용
-- ============================================

-- 효과 추가
RegisterNetEvent('bumbercar:client:effectApplied')
AddEventHandler('bumbercar:client:effectApplied', function(effectType, duration, data)
    activeEffects[effectType] = {
        endTime = GetGameTimer() + (duration * 1000),
        data = data or {}
    }

    BumberCar.Effects[effectType] = activeEffects[effectType]

    Utils.Debug('Effect applied:', effectType, 'Duration:', duration)

    -- UI 업데이트
    SendNUIMessage({
        type = 'addEffect',
        data = {
            effectType = effectType,
            duration = duration,
            data = data
        }
    })

    -- 시각 효과 적용
    ApplyVisualEffect(effectType, data)
end)

-- 효과 제거
RegisterNetEvent('bumbercar:client:effectRemoved')
AddEventHandler('bumbercar:client:effectRemoved', function(effectType)
    activeEffects[effectType] = nil
    BumberCar.Effects[effectType] = nil

    Utils.Debug('Effect removed:', effectType)

    -- UI 업데이트
    SendNUIMessage({
        type = 'removeEffect',
        data = {
            effectType = effectType
        }
    })

    -- 시각 효과 제거
    RemoveVisualEffect(effectType)
end)

-- 시각 효과 적용
function ApplyVisualEffect(effectType, data)
    if not BumberCar.CurrentVehicle or not DoesEntityExist(BumberCar.CurrentVehicle) then
        return
    end

    local vehicle = BumberCar.CurrentVehicle

    if effectType == Constants.ItemEffect.DAMAGE_BOOST then
        -- 공격력 증가 - 빨간 네온
        SetVehicleNeonLightEnabled(vehicle, 0, true)
        SetVehicleNeonLightEnabled(vehicle, 1, true)
        SetVehicleNeonLightEnabled(vehicle, 2, true)
        SetVehicleNeonLightEnabled(vehicle, 3, true)
        SetVehicleNeonLightsColour(vehicle, 255, 0, 0)

    elseif effectType == Constants.ItemEffect.DEFENSE_BOOST then
        -- 방어력 증가 - 파란 네온
        SetVehicleNeonLightEnabled(vehicle, 0, true)
        SetVehicleNeonLightEnabled(vehicle, 1, true)
        SetVehicleNeonLightEnabled(vehicle, 2, true)
        SetVehicleNeonLightEnabled(vehicle, 3, true)
        SetVehicleNeonLightsColour(vehicle, 0, 0, 255)

    elseif effectType == Constants.ItemEffect.SPEED_BOOST then
        -- 속도 증가 - 노란 네온
        SetVehicleNeonLightEnabled(vehicle, 0, true)
        SetVehicleNeonLightEnabled(vehicle, 1, true)
        SetVehicleNeonLightEnabled(vehicle, 2, true)
        SetVehicleNeonLightEnabled(vehicle, 3, true)
        SetVehicleNeonLightsColour(vehicle, 255, 255, 0)
    end
end

-- 시각 효과 제거
function RemoveVisualEffect(effectType)
    if not BumberCar.CurrentVehicle or not DoesEntityExist(BumberCar.CurrentVehicle) then
        return
    end

    local vehicle = BumberCar.CurrentVehicle

    -- 네온 끄기 (다른 효과가 있으면 유지)
    if not activeEffects[Constants.ItemEffect.DAMAGE_BOOST] and
       not activeEffects[Constants.ItemEffect.DEFENSE_BOOST] and
       not activeEffects[Constants.ItemEffect.SPEED_BOOST] then
        SetVehicleNeonLightEnabled(vehicle, 0, false)
        SetVehicleNeonLightEnabled(vehicle, 1, false)
        SetVehicleNeonLightEnabled(vehicle, 2, false)
        SetVehicleNeonLightEnabled(vehicle, 3, false)
    end
end

-- ============================================
-- 폭탄 모드
-- ============================================

-- 폭탄 할당
RegisterNetEvent('bumbercar:client:bombAssigned')
AddEventHandler('bumbercar:client:bombAssigned', function(timer)
    hasBomb = true
    bombTimer = timer

    Utils.Debug('Bomb assigned, timer:', timer)

    -- UI 업데이트
    SendNUIMessage({
        type = 'showBombTimer',
        data = {
            timer = timer
        }
    })

    -- 알림
    TriggerEvent('bumbercar:client:notify',
        Config.Notifications.BombReceived,
        'error')
end)

-- 폭탄 전달됨
RegisterNetEvent('bumbercar:client:bombTransferred')
AddEventHandler('bumbercar:client:bombTransferred', function(newHolderId)
    if hasBomb then
        hasBomb = false
        bombTimer = 0

        Utils.Debug('Bomb transferred to player', newHolderId)

        -- UI 업데이트
        SendNUIMessage({
            type = 'hideBombTimer'
        })

        -- 알림
        TriggerEvent('bumbercar:client:notify',
            Config.Notifications.BombTransferred,
            'success')
    end

    -- 다른 플레이어가 폭탄을 받음
    bombHolder = newHolderId
end)

-- 폭탄 타이머 업데이트
RegisterNetEvent('bumbercar:client:bombTimerUpdate')
AddEventHandler('bumbercar:client:bombTimerUpdate', function(timer)
    if hasBomb then
        bombTimer = timer

        -- UI 업데이트
        SendNUIMessage({
            type = 'updateBombTimer',
            data = {
                timer = timer
            }
        })
    end
end)

-- 폭탄 폭발
RegisterNetEvent('bumbercar:client:bombExplode')
AddEventHandler('bumbercar:client:bombExplode', function(coords, radius)
    Utils.Debug('Bomb exploded at', coords)

    -- 폭발 효과
    AddExplosion(coords.x, coords.y, coords.z, 7, 10.0, true, false, radius)

    -- 폭탄 상태 리셋
    hasBomb = false
    bombTimer = 0
    bombHolder = nil

    -- UI 업데이트
    SendNUIMessage({
        type = 'hideBombTimer'
    })
end)

-- 폭탄 타이머 표시
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if hasBomb and bombTimer > 0 then
            -- 화면 중앙에 크게 표시
            SetTextFont(4)
            SetTextScale(1.5, 1.5)
            SetTextColour(255, 0, 0, 255)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString('폭탄: ' .. bombTimer .. '초')
            DrawText(0.5, 0.3)

            -- 경고 화면 효과 (마지막 10초)
            if bombTimer <= Config.Bomb.WarningTime then
                local alpha = math.floor(math.abs(math.sin(GetGameTimer() / 200.0)) * 100)
                DrawRect(0.5, 0.5, 1.0, 1.0, 255, 0, 0, alpha)
            end

            -- 틱톡 사운드
            if bombTimer <= 10 and Config.Sounds.Enabled then
                if GetGameTimer() % 1000 < 50 then
                    PlaySound(-1, 'BOMB_TICK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false, 0, true)
                end
            end

        else
            Wait(500)
        end
    end
end)

-- ============================================
-- 3D 아이템 마커
-- ============================================

-- 아이템 마커 및 3D 텍스트 렌더링
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           Config.Items.Enabled and
           Config.ItemSpawn.ShowMarker then

            local playerCoords = GetEntityCoords(PlayerPedId())

            for _, item in pairs(activeItems) do
                if item.active then
                    local distance = #(playerCoords - item.position)

                    -- 표시 범위 내
                    if distance <= Config.ItemSpawn.ShowRadius then
                        local pos = item.position

                        -- 마커 Z 좌표 (상하 움직임)
                        local markerZ = pos.z
                        if Config.ItemSpawn.BobMarker then
                            markerZ = markerZ + math.sin(GetGameTimer() / 500.0) * 0.5
                        end

                        -- 회전 각도
                        local rotation = 0.0
                        if Config.ItemSpawn.RotateMarker then
                            rotation = (GetGameTimer() / 10.0) % 360.0
                        end

                        -- 색상
                        local color = Utils.HexToRGB(item.data.color)

                        -- 마커 그리기
                        DrawMarker(
                            Config.ItemSpawn.MarkerType,
                            pos.x, pos.y, markerZ,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, rotation,
                            Config.ItemSpawn.MarkerSize.x,
                            Config.ItemSpawn.MarkerSize.y,
                            Config.ItemSpawn.MarkerSize.z,
                            color.r, color.g, color.b, color.a,
                            false, true, 2, false, nil, nil, false
                        )

                        -- 3D 텍스트 (가까이 있을 때만)
                        if Config.ItemSpawn.ShowText and distance <= 20.0 then
                            local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(
                                pos.x, pos.y, pos.z + 1.5
                            )

                            if onScreen then
                                SetTextScale(0.4, 0.4)
                                SetTextFont(4)
                                SetTextProportional(1)
                                SetTextColour(255, 255, 255, 255)
                                SetTextOutline()
                                SetTextCentre(true)
                                SetTextEntry('STRING')
                                AddTextComponentString(item.data.icon .. ' ' .. item.data.name)
                                DrawText(screenX, screenY)
                            end
                        end
                    end
                end
            end

        else
            Wait(500)
        end
    end
end)

-- ============================================
-- 라운드 종료 시 정리
-- ============================================

-- 라운드 종료 시 아이템 클리어
RegisterNetEvent('bumbercar:client:returnToLobby')
AddEventHandler('bumbercar:client:returnToLobby', function()
    -- 아이템 클리어
    activeItems = {}
    playerItems = {nil, nil}
    activeEffects = {}
    itemCooldowns = {}

    -- 폭탄 리셋
    hasBomb = false
    bombTimer = 0
    bombHolder = nil

    Utils.Debug('Items system reset')
end)

Utils.Debug('Items system loaded')
