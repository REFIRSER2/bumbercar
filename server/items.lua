-- 아이템 시스템 (서버)
local activeItems = {}
local bombHolder = nil
local bombTimer = 0

-- 아이템 스폰
RegisterServerEvent('bumbercar:server:spawnItems')
AddEventHandler('bumbercar:server:spawnItems', function(map)
    if not map.itemSpawns then return end

    -- 기존 아이템 제거
    activeItems = {}

    -- 게임 모드별 사용 가능 아이템
    local availableItems = Config.ItemsByGameMode[BumberCar.CurrentGameMode] or {}
    if #availableItems == 0 then return end

    -- 아이템 스폰
    for i, spawnPos in ipairs(map.itemSpawns) do
        local itemId = SelectRandomItem(availableItems)
        if itemId then
            local itemData = Config.ItemList[itemId]

            activeItems[i] = {
                id = i,
                itemId = itemId,
                position = spawnPos,
                active = true,
                respawnTime = Config.Items.RespawnTime
            }

            -- 클라이언트에 아이템 스폰 알림
            TriggerClientEvent('bumbercar:client:spawnItem', -1, i, itemId, spawnPos, itemData)
        end
    end

    Utils.Debug('Items spawned:', #activeItems)
end)

-- 랜덤 아이템 선택 (가중치 기반)
function SelectRandomItem(availableItems)
    local totalWeight = 0
    local weights = {}

    for _, itemId in ipairs(availableItems) do
        local weight = Config.ItemDropWeights[itemId] or 50
        totalWeight = totalWeight + weight
        table.insert(weights, {itemId = itemId, weight = weight})
    end

    if totalWeight == 0 then return nil end

    local random = math.random(1, totalWeight)
    local currentWeight = 0

    for _, weightData in ipairs(weights) do
        currentWeight = currentWeight + weightData.weight
        if random <= currentWeight then
            return weightData.itemId
        end
    end

    return availableItems[1]
end

-- 아이템 획득
RegisterServerEvent('bumbercar:server:pickupItem')
AddEventHandler('bumbercar:server:pickupItem', function(itemIndex)
    local source = source
    if not BumberCar.Players[source] or not activeItems[itemIndex] then return end

    local item = activeItems[itemIndex]
    if not item.active then return end

    local itemData = Config.ItemList[item.itemId]
    if not itemData then return end

    -- 아이템 비활성화
    item.active = false
    TriggerClientEvent('bumbercar:client:removeItem', -1, itemIndex)

    -- 아이템 효과 적용
    ApplyItemEffect(source, item.itemId, itemData)

    -- 알림
    BumberCar.Notify(source, string.format(Config.Notifications.ItemPickup, itemData.name), 'success')

    -- 리스폰 타이머
    Citizen.SetTimeout(item.respawnTime * 1000, function()
        if BumberCar.GameState == Constants.RoundState.PLAYING then
            item.active = true
            item.itemId = SelectRandomItem(Config.ItemsByGameMode[BumberCar.CurrentGameMode])
            local newItemData = Config.ItemList[item.itemId]
            TriggerClientEvent('bumbercar:client:spawnItem', -1, itemIndex, item.itemId, item.position, newItemData)
        end
    end)
end)

-- 아이템 효과 적용
function ApplyItemEffect(playerId, itemId, itemData)
    if not BumberCar.Players[playerId] then return end

    local effect = itemData.effect

    -- 즉발형 아이템
    if itemData.type == Constants.ItemType.INSTANT then
        if effect == Constants.ItemEffect.REPAIR then
            TriggerEvent('bumbercar:server:repairVehicle', playerId, itemData.maxHealth and 'max' or itemData.healAmount)

        elseif effect == Constants.ItemEffect.RANDOM_VEHICLE then
            TriggerClientEvent('bumbercar:client:changeToRandomVehicle', playerId, itemData.keepStats)
        end

    -- 사용형 아이템
    elseif itemData.type == Constants.ItemType.USABLE then
        -- 아이템 슬롯에 추가
        local items = BumberCar.Players[playerId].items
        if not items[1] then
            items[1] = itemId
            TriggerClientEvent('bumbercar:client:updateItemSlot', playerId, 1, itemId, itemData)
        elseif not items[2] then
            items[2] = itemId
            TriggerClientEvent('bumbercar:client:updateItemSlot', playerId, 2, itemId, itemData)
        else
            -- 슬롯이 꽉 찬 경우 첫 번째 슬롯 교체
            items[1] = itemId
            TriggerClientEvent('bumbercar:client:updateItemSlot', playerId, 1, itemId, itemData)
        end
    end
end

-- 아이템 사용
RegisterServerEvent('bumbercar:server:useItem')
AddEventHandler('bumbercar:server:useItem', function(slotIndex)
    local source = source
    if not BumberCar.Players[source] then return end

    local items = BumberCar.Players[source].items
    local itemId = items[slotIndex]

    if not itemId then return end

    local itemData = Config.ItemList[itemId]
    if not itemData then return end

    local effect = itemData.effect

    -- 효과 적용
    if effect == Constants.ItemEffect.DAMAGE_BOOST then
        ApplyBuff(source, 'damage_boost', itemData.duration)
        TriggerEvent('bumbercar:server:modifyVehicleStats', source, 'damage',
            BumberCar.Players[source].vehicleData.damage * itemData.multiplier,
            itemData.duration)

    elseif effect == Constants.ItemEffect.DEFENSE_BOOST then
        ApplyBuff(source, 'defense_boost', itemData.duration)
        TriggerEvent('bumbercar:server:modifyVehicleStats', source, 'defense',
            BumberCar.Players[source].vehicleData.defense * itemData.multiplier,
            itemData.duration)

    elseif effect == Constants.ItemEffect.SPEED_BOOST then
        ApplyBuff(source, 'speed_boost', itemData.duration)
        TriggerClientEvent('bumbercar:client:applySpeedBoost', source, itemData.multiplier, itemData.duration)

    elseif effect == Constants.ItemEffect.BOOST then
        TriggerClientEvent('bumbercar:client:applyBoost', source, itemData.force, itemData.duration)

    elseif effect == Constants.ItemEffect.JUMP then
        TriggerClientEvent('bumbercar:client:applyJump', source, itemData.force)

    elseif effect == Constants.ItemEffect.FREEZE then
        TriggerClientEvent('bumbercar:client:applyFreeze', source, itemData.range, itemData.duration)

    elseif effect == Constants.ItemEffect.EXPLOSION then
        TriggerClientEvent('bumbercar:client:applyExplosion', source, itemData.radius, itemData.damage)
    end

    -- 아이템 슬롯에서 제거
    items[slotIndex] = nil
    TriggerClientEvent('bumbercar:client:updateItemSlot', source, slotIndex, nil, nil)
end)

-- 버프 적용
function ApplyBuff(playerId, buffName, duration)
    if not BumberCar.Players[playerId] then return end

    BumberCar.Players[playerId].effects[buffName] = true
    TriggerClientEvent('bumbercar:client:addEffect', playerId, buffName, duration)

    -- 지속 시간 후 제거
    Citizen.SetTimeout(duration * 1000, function()
        if BumberCar.Players[playerId] then
            BumberCar.Players[playerId].effects[buffName] = nil
            TriggerClientEvent('bumbercar:client:removeEffect', playerId, buffName)
        end
    end)
end

-- 폭탄 모드 시작
RegisterServerEvent('bumbercar:server:startBombMode')
AddEventHandler('bumbercar:server:startBombMode', function()
    -- 랜덤 플레이어에게 폭탄 부여
    local alivePlayers = {}
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.state == Constants.PlayerState.PLAYING then
            table.insert(alivePlayers, playerId)
        end
    end

    if #alivePlayers > 0 then
        bombHolder = Utils.GetRandomElement(alivePlayers)
        bombTimer = Config.Bomb.ExplosionTime

        TriggerClientEvent('bumbercar:client:receiveBomb', bombHolder, bombTimer)
        BumberCar.Notify(bombHolder, Config.Notifications.BombReceived, 'warning')

        Utils.Debug('Bomb given to:', GetPlayerName(bombHolder))
    end
end)

-- 폭탄 전달
RegisterServerEvent('bumbercar:server:transferBomb')
AddEventHandler('bumbercar:server:transferBomb', function(targetPlayerId)
    local source = source

    if source ~= bombHolder then return end
    if not BumberCar.Players[targetPlayerId] or BumberCar.Players[targetPlayerId].state ~= Constants.PlayerState.PLAYING then return end

    -- 팀전에서 같은 팀이면 전달 불가
    if (BumberCar.CurrentGameMode == Constants.GameMode.BOMB_TEAM) and
       (BumberCar.Players[source].team == BumberCar.Players[targetPlayerId].team) then
        return
    end

    -- 폭탄 전달
    bombHolder = targetPlayerId

    TriggerClientEvent('bumbercar:client:removeBomb', source)
    TriggerClientEvent('bumbercar:client:receiveBomb', targetPlayerId, bombTimer)

    BumberCar.Notify(source, Config.Notifications.BombTransferred, 'success')
    BumberCar.Notify(targetPlayerId, Config.Notifications.BombReceived, 'warning')

    Utils.Debug('Bomb transferred:', GetPlayerName(source), '->', GetPlayerName(targetPlayerId))
end)

-- 폭탄 타이머
Citizen.CreateThread(function()
    while true do
        Wait(1000)

        if bombHolder and BumberCar.GameState == Constants.RoundState.PLAYING then
            bombTimer = bombTimer - 1

            TriggerClientEvent('bumbercar:client:updateBombTimer', bombHolder, bombTimer)

            if bombTimer <= 0 then
                -- 폭탄 폭발
                local coords = GetEntityCoords(GetPlayerPed(bombHolder))
                TriggerClientEvent('bumbercar:client:explodeBomb', -1, coords, Config.Bomb.ExplosionRadius)
                TriggerEvent('bumbercar:server:playerDied', bombHolder, nil, coords)

                bombHolder = nil
                bombTimer = 0
            end
        end
    end
end)
