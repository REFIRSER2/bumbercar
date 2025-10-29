-- 아이템 시스템 (서버)
-- 아이템 스폰, 획득, 효과 적용, 폭탄 모드 관리

local activeItems = {} -- 활성 아이템 {index = {id, itemId, position, active}}
local playerEffects = {} -- 플레이어 효과 타이머 {playerId = {effectId = timerId}}
local bombHolder = nil -- 현재 폭탄 소유자
local bombTimer = 0 -- 폭탄 타이머
local bombTimerActive = false -- 폭탄 타이머 활성화

-- 아이템 스폰 (라운드 시작 시 호출됨)
RegisterServerEvent('bumbercar:server:spawnItems')
AddEventHandler('bumbercar:server:spawnItems', function(map)
    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.PLAYING then
        return
    end

    -- 맵에 아이템 스폰 포인트가 없으면 중단
    if not map or not map.itemSpawns or #map.itemSpawns == 0 then
        Utils.Debug('No item spawns in this map')
        return
    end

    -- 게임 모드별 사용 가능 아이템 목록 가져오기
    local availableItems = Config.ItemsByGameMode[BumberCar.CurrentGameMode] or {}

    if #availableItems == 0 then
        Utils.Debug('No items enabled for game mode:', BumberCar.CurrentGameMode)
        return
    end

    -- 기존 아이템 제거
    ClearAllItems()

    -- 아이템 스폰
    local spawnCount = math.min(#map.itemSpawns, Config.ItemSpawn.MaxActive or 10)

    for i = 1, spawnCount do
        local spawnPos = map.itemSpawns[i]
        local itemId = SelectRandomItem(availableItems)

        if itemId and spawnPos then
            local itemData = Config.ItemList[itemId]

            if itemData then
                activeItems[i] = {
                    id = i,
                    itemId = itemId,
                    position = spawnPos,
                    active = true
                }

                -- 클라이언트에 아이템 스폰 알림
                TriggerClientEvent('bumbercar:client:itemSpawned', -1, i, itemId, spawnPos, itemData)

                Utils.Debug('Item spawned:', itemData.name, 'at position', i)
            end
        end
    end

    Utils.Success('Items spawned:', Utils.TableCount(activeItems), 'items')
end)

-- 랜덤 아이템 선택 (가중치 기반)
function SelectRandomItem(availableItems)
    if not availableItems or #availableItems == 0 then
        return nil
    end

    local totalWeight = 0
    local weights = {}

    -- 가중치 계산
    for _, itemId in ipairs(availableItems) do
        local weight = Config.ItemDropWeights[itemId] or 50
        totalWeight = totalWeight + weight
        table.insert(weights, {itemId = itemId, weight = weight})
    end

    if totalWeight == 0 then
        return availableItems[1]
    end

    -- 가중치 기반 랜덤 선택
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

    -- 유효성 검사
    if not BumberCar.Players[source] then
        return
    end

    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.PLAYING then
        return
    end

    -- 플레이어 상태 체크
    if BumberCar.Players[source].state ~= Constants.PlayerState.PLAYING then
        return
    end

    -- 아이템 존재 및 활성화 체크
    local item = activeItems[itemIndex]
    if not item or not item.active then
        return
    end

    local itemData = Config.ItemList[item.itemId]
    if not itemData then
        Utils.Error('Invalid item ID:', item.itemId)
        return
    end

    -- 거리 체크 (치팅 방지)
    local playerPed = GetPlayerPed(source)
    local playerPos = GetEntityCoords(playerPed)
    local distance = #(vector3(playerPos.x, playerPos.y, playerPos.z) - item.position)

    if distance > Config.Items.PickupDistance then
        Utils.Debug('Player too far from item:', distance)
        return
    end

    -- 아이템 비활성화
    item.active = false

    -- 클라이언트에 아이템 제거 알림
    TriggerClientEvent('bumbercar:client:itemPickedUp', -1, itemIndex)

    -- 아이템 효과 적용
    ApplyItemEffect(source, item.itemId, itemData)

    -- 알림
    BumberCar.Notify(source, string.format(Config.Notifications.ItemPickup, itemData.name), 'success')

    Utils.Debug('Item picked up:', itemData.name, 'by', GetPlayerName(source))

    -- 리스폰 타이머 설정
    Citizen.SetTimeout(Config.Items.RespawnTime * 1000, function()
        -- 게임이 아직 진행 중이면 리스폰
        if BumberCar.GameState == Constants.RoundState.PLAYING and activeItems[itemIndex] then
            local availableItems = Config.ItemsByGameMode[BumberCar.CurrentGameMode] or {}
            if #availableItems > 0 then
                local newItemId = SelectRandomItem(availableItems)
                local newItemData = Config.ItemList[newItemId]

                if newItemData then
                    activeItems[itemIndex].itemId = newItemId
                    activeItems[itemIndex].active = true

                    -- 클라이언트에 아이템 리스폰 알림
                    TriggerClientEvent('bumbercar:client:itemSpawned', -1, itemIndex, newItemId, item.position, newItemData)

                    Utils.Debug('Item respawned:', newItemData.name, 'at position', itemIndex)
                end
            end
        end
    end)
end)

-- 아이템 효과 적용
function ApplyItemEffect(playerId, itemId, itemData)
    if not BumberCar.Players[playerId] then
        return
    end

    local effect = itemData.effect

    -- 즉발형 아이템 (획득 즉시 효과)
    if itemData.type == Constants.ItemType.INSTANT then
        if effect == Constants.ItemEffect.REPAIR then
            -- 수리: 체력 회복
            local healAmount = itemData.maxHealth and BumberCar.Players[playerId].vehicleData.maxHealth or itemData.healAmount
            TriggerEvent('bumbercar:server:healVehicle', playerId, healAmount)

        elseif effect == Constants.ItemEffect.RANDOM_VEHICLE then
            -- 랜덤 차량: 차량 변경
            ChangeToRandomVehicle(playerId, itemData.keepStats)
        end

    -- 사용형 아이템 (슬롯에 저장)
    elseif itemData.type == Constants.ItemType.USABLE then
        local items = BumberCar.Players[playerId].items

        -- 빈 슬롯 찾기
        if not items[1] then
            items[1] = itemId
            TriggerClientEvent('bumbercar:client:itemAdded', playerId, 1, itemId, itemData)
        elseif not items[2] then
            items[2] = itemId
            TriggerClientEvent('bumbercar:client:itemAdded', playerId, 2, itemId, itemData)
        else
            -- 슬롯이 꽉 찬 경우 첫 번째 슬롯 교체
            items[1] = itemId
            TriggerClientEvent('bumbercar:client:itemAdded', playerId, 1, itemId, itemData)
            BumberCar.Notify(playerId, '아이템 슬롯이 가득 차서 첫 번째 슬롯이 교체되었습니다', 'info')
        end
    end
end

-- 랜덤 차량으로 변경
function ChangeToRandomVehicle(playerId, keepStats)
    local player = BumberCar.Players[playerId]
    if not player then
        return
    end

    -- 랜덤 차량 선택
    local vehicles = Config.Vehicles.Regular
    local randomVehicle = Utils.GetRandomElement(vehicles)

    if not randomVehicle then
        return
    end

    -- 스탯 유지 여부
    local oldHealth = player.vehicleData.health
    local oldMaxHealth = player.vehicleData.maxHealth

    -- 새 차량 데이터 설정
    player.vehicleData.model = randomVehicle.model
    player.vehicleData.damage = randomVehicle.damage
    player.vehicleData.defense = randomVehicle.defense
    player.vehicleData.speed = randomVehicle.speed

    if keepStats then
        -- 스탯 유지: 체력 비율 유지
        local healthRatio = oldHealth / oldMaxHealth
        player.vehicleData.maxHealth = randomVehicle.health
        player.vehicleData.health = randomVehicle.health * healthRatio
    else
        -- 스탯 초기화
        player.vehicleData.maxHealth = randomVehicle.health
        player.vehicleData.health = randomVehicle.health
    end

    -- 클라이언트에 차량 변경 요청
    TriggerClientEvent('bumbercar:client:changeVehicle', playerId, randomVehicle.model, player.vehicleData)

    Utils.Debug('Vehicle changed for', GetPlayerName(playerId), 'to', randomVehicle.model)
end

-- 아이템 사용 (슬롯에서 사용)
RegisterServerEvent('bumbercar:server:useItem')
AddEventHandler('bumbercar:server:useItem', function(slotIndex)
    local source = source

    -- 유효성 검사
    if not BumberCar.Players[source] then
        return
    end

    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.PLAYING then
        return
    end

    -- 플레이어 상태 체크
    if BumberCar.Players[source].state ~= Constants.PlayerState.PLAYING then
        return
    end

    -- 슬롯 확인
    local items = BumberCar.Players[source].items
    local itemId = items[slotIndex]

    if not itemId then
        return
    end

    local itemData = Config.ItemList[itemId]
    if not itemData then
        return
    end

    -- 효과 적용
    UseItemEffect(source, itemId, itemData)

    -- 아이템 슬롯에서 제거
    items[slotIndex] = nil
    TriggerClientEvent('bumbercar:client:itemRemoved', source, slotIndex)

    Utils.Debug('Item used:', itemData.name, 'by', GetPlayerName(source))
end)

-- 아이템 사용 효과 적용
function UseItemEffect(playerId, itemId, itemData)
    local effect = itemData.effect

    if effect == Constants.ItemEffect.DAMAGE_BOOST then
        -- 공격력 증가
        ApplyStatBoost(playerId, 'damage', itemData.multiplier, itemData.duration, itemData.stackable)

    elseif effect == Constants.ItemEffect.DEFENSE_BOOST then
        -- 방어력 증가
        ApplyStatBoost(playerId, 'defense', itemData.multiplier, itemData.duration, itemData.stackable)

    elseif effect == Constants.ItemEffect.SPEED_BOOST then
        -- 속도 증가
        ApplySpeedBoost(playerId, itemData.multiplier, itemData.duration, itemData.stackable)

    elseif effect == Constants.ItemEffect.BOOST then
        -- 부스트 (전방 가속)
        TriggerClientEvent('bumbercar:client:applyForce', playerId, 'forward', itemData.force)

    elseif effect == Constants.ItemEffect.JUMP then
        -- 점프 (상승)
        TriggerClientEvent('bumbercar:client:applyForce', playerId, 'up', itemData.force)

    elseif effect == Constants.ItemEffect.FREEZE then
        -- 정지 (가장 가까운 적)
        ApplyFreeze(playerId, itemData.range, itemData.duration)

    elseif effect == Constants.ItemEffect.EXPLOSION then
        -- 폭발
        ApplyExplosion(playerId, itemData.radius, itemData.damage, itemData.knockback)
    end
end

-- 스탯 부스트 적용
function ApplyStatBoost(playerId, statType, multiplier, duration, stackable)
    local player = BumberCar.Players[playerId]
    if not player then
        return
    end

    local effectId = statType .. '_boost'

    -- 이미 효과가 있으면 중첩 체크
    if player.effects[effectId] and not stackable then
        BumberCar.Notify(playerId, '이미 해당 효과가 적용 중입니다', 'error')
        return
    end

    -- 기본 스탯 저장 (처음 적용 시)
    if not player.effects[effectId] then
        player.effects[effectId] = {
            originalValue = player.vehicleData[statType],
            active = true
        }
    end

    -- 스탯 증가
    local newValue = player.effects[effectId].originalValue * multiplier
    player.vehicleData[statType] = newValue

    -- 클라이언트에 효과 알림
    TriggerClientEvent('bumbercar:client:effectApplied', playerId, effectId, duration)

    -- 클라이언트에 스탯 업데이트
    TriggerEvent('bumbercar:server:updateVehicleStats', playerId, {
        [statType] = newValue
    })

    Utils.Debug('Stat boost applied:', statType, 'x', multiplier, 'for', duration, 'seconds to', GetPlayerName(playerId))

    -- 지속 시간 후 효과 제거
    Citizen.SetTimeout(duration * 1000, function()
        if BumberCar.Players[playerId] and player.effects[effectId] then
            -- 원래 스탯으로 복구
            player.vehicleData[statType] = player.effects[effectId].originalValue
            player.effects[effectId] = nil

            -- 클라이언트에 효과 제거 알림
            TriggerClientEvent('bumbercar:client:effectRemoved', playerId, effectId)

            -- 클라이언트에 스탯 업데이트
            TriggerEvent('bumbercar:server:updateVehicleStats', playerId, {
                [statType] = player.vehicleData[statType]
            })

            Utils.Debug('Stat boost removed:', statType, 'for', GetPlayerName(playerId))
        end
    end)
end

-- 속도 부스트 적용
function ApplySpeedBoost(playerId, multiplier, duration, stackable)
    local player = BumberCar.Players[playerId]
    if not player then
        return
    end

    local effectId = 'speed_boost'

    -- 이미 효과가 있으면 중첩 체크
    if player.effects[effectId] and not stackable then
        BumberCar.Notify(playerId, '이미 속도 부스트가 적용 중입니다', 'error')
        return
    end

    -- 효과 설정
    player.effects[effectId] = true

    -- 클라이언트에 속도 부스트 적용
    TriggerClientEvent('bumbercar:client:applySpeedBoost', playerId, multiplier, duration)
    TriggerClientEvent('bumbercar:client:effectApplied', playerId, effectId, duration)

    Utils.Debug('Speed boost applied:', multiplier, 'x for', duration, 'seconds to', GetPlayerName(playerId))

    -- 지속 시간 후 효과 제거
    Citizen.SetTimeout(duration * 1000, function()
        if BumberCar.Players[playerId] then
            player.effects[effectId] = nil
            TriggerClientEvent('bumbercar:client:effectRemoved', playerId, effectId)
            Utils.Debug('Speed boost removed for', GetPlayerName(playerId))
        end
    end)
end

-- 프리즈 적용 (가장 가까운 적)
function ApplyFreeze(playerId, range, duration)
    local player = BumberCar.Players[playerId]
    if not player then
        return
    end

    local playerPed = GetPlayerPed(playerId)
    local playerPos = GetEntityCoords(playerPed)
    local closestEnemy = nil
    local closestDistance = range + 1

    -- 가장 가까운 적 찾기
    for targetId, targetData in pairs(BumberCar.Players) do
        if targetId ~= playerId and targetData.state == Constants.PlayerState.PLAYING then
            -- 팀전이면 다른 팀만
            if IsTeamMode(BumberCar.CurrentGameMode) then
                if player.team ~= targetData.team and player.team ~= Constants.Team.NONE then
                    local targetPed = GetPlayerPed(targetId)
                    local targetPos = GetEntityCoords(targetPed)
                    local distance = #(playerPos - targetPos)

                    if distance <= range and distance < closestDistance then
                        closestEnemy = targetId
                        closestDistance = distance
                    end
                end
            else
                -- 개인전이면 모든 플레이어
                local targetPed = GetPlayerPed(targetId)
                local targetPos = GetEntityCoords(targetPed)
                local distance = #(playerPos - targetPos)

                if distance <= range and distance < closestDistance then
                    closestEnemy = targetId
                    closestDistance = distance
                end
            end
        end
    end

    if closestEnemy then
        -- 프리즈 효과 적용
        TriggerClientEvent('bumbercar:client:freezeVehicle', closestEnemy, duration)
        BumberCar.Notify(playerId, '가장 가까운 적을 정지시켰습니다!', 'success')
        BumberCar.Notify(closestEnemy, '정지 효과를 받았습니다!', 'error')
        Utils.Debug('Freeze applied to', GetPlayerName(closestEnemy), 'by', GetPlayerName(playerId))
    else
        BumberCar.Notify(playerId, '범위 내에 적이 없습니다', 'error')
    end
end

-- 폭발 적용
function ApplyExplosion(playerId, radius, damage, knockback)
    local player = BumberCar.Players[playerId]
    if not player then
        return
    end

    local playerPed = GetPlayerPed(playerId)
    local playerPos = GetEntityCoords(playerPed)

    -- 클라이언트에 폭발 효과
    TriggerClientEvent('bumbercar:client:createExplosion', -1, playerPos, radius)

    -- 범위 내 모든 플레이어에게 데미지
    for targetId, targetData in pairs(BumberCar.Players) do
        if targetId ~= playerId and targetData.state == Constants.PlayerState.PLAYING then
            local targetPed = GetPlayerPed(targetId)
            local targetPos = GetEntityCoords(targetPed)
            local distance = #(playerPos - targetPos)

            if distance <= radius then
                -- 거리에 따른 데미지 감소
                local damageMultiplier = 1.0 - (distance / radius)
                local finalDamage = math.floor(damage * damageMultiplier)

                -- 데미지 적용
                TriggerEvent('bumbercar:server:applyDamage', targetId, finalDamage, playerId)

                -- 넉백 적용
                if knockback and knockback > 0 then
                    TriggerClientEvent('bumbercar:client:applyKnockback', targetId, playerPos, knockback)
                end

                Utils.Debug('Explosion damage:', finalDamage, 'to', GetPlayerName(targetId))
            end
        end
    end

    Utils.Debug('Explosion applied by', GetPlayerName(playerId), 'at', playerPos)
end

-- 모든 아이템 제거
RegisterServerEvent('bumbercar:server:clearItems')
AddEventHandler('bumbercar:server:clearItems', function()
    ClearAllItems()
end)

function ClearAllItems()
    -- 모든 아이템 제거
    for itemIndex, _ in pairs(activeItems) do
        TriggerClientEvent('bumbercar:client:itemPickedUp', -1, itemIndex)
    end

    activeItems = {}
    Utils.Debug('All items cleared')
end

-- 폭탄 모드 시작
RegisterServerEvent('bumbercar:server:startBombMode')
AddEventHandler('bumbercar:server:startBombMode', function()
    -- 살아있는 플레이어 찾기
    local alivePlayers = {}
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.state == Constants.PlayerState.PLAYING then
            table.insert(alivePlayers, playerId)
        end
    end

    if #alivePlayers == 0 then
        Utils.Error('No alive players for bomb mode')
        return
    end

    -- 랜덤 플레이어에게 폭탄 부여
    bombHolder = Utils.GetRandomElement(alivePlayers)
    bombTimer = Config.Bomb.ExplosionTime
    bombTimerActive = true

    -- 클라이언트에 폭탄 알림
    TriggerClientEvent('bumbercar:client:bombAssigned', bombHolder, bombTimer)
    TriggerClientEvent('bumbercar:client:bombHolderChanged', -1, bombHolder)

    BumberCar.Notify(bombHolder, Config.Notifications.BombReceived, 'error')
    Utils.Success('Bomb assigned to:', GetPlayerName(bombHolder))
end)

-- 폭탄 전달 (충돌 시)
RegisterServerEvent('bumbercar:server:bombTransfer')
AddEventHandler('bumbercar:server:bombTransfer', function(targetPlayerId)
    local source = source

    -- 폭탄 소유자 확인
    if source ~= bombHolder then
        return
    end

    -- 대상 유효성 확인
    if not BumberCar.Players[targetPlayerId] or
       BumberCar.Players[targetPlayerId].state ~= Constants.PlayerState.PLAYING then
        return
    end

    -- 팀전에서 같은 팀이면 전달 불가
    if IsTeamMode(BumberCar.CurrentGameMode) and
       BumberCar.Players[source].team == BumberCar.Players[targetPlayerId].team and
       BumberCar.Players[source].team ~= Constants.Team.NONE then
        return
    end

    -- 폭탄 전달
    local oldHolder = bombHolder
    bombHolder = targetPlayerId

    -- 클라이언트에 폭탄 전달 알림
    TriggerClientEvent('bumbercar:client:bombRemoved', oldHolder)
    TriggerClientEvent('bumbercar:client:bombAssigned', bombHolder, bombTimer)
    TriggerClientEvent('bumbercar:client:bombHolderChanged', -1, bombHolder)

    BumberCar.Notify(oldHolder, Config.Notifications.BombTransferred, 'success')
    BumberCar.Notify(bombHolder, Config.Notifications.BombReceived, 'error')

    Utils.Debug('Bomb transferred from', GetPlayerName(oldHolder), 'to', GetPlayerName(bombHolder))
end)

-- 폭탄 타이머 (1초마다 감소)
Citizen.CreateThread(function()
    while true do
        Wait(1000)

        if bombTimerActive and bombHolder and BumberCar.GameState == Constants.RoundState.PLAYING then
            bombTimer = bombTimer - 1

            -- 타이머 업데이트
            TriggerClientEvent('bumbercar:client:bombTimerUpdate', bombHolder, bombTimer)

            -- 경고 알림 (10초 남았을 때)
            if bombTimer == Config.Bomb.WarningTime then
                BumberCar.Notify(bombHolder, string.format('폭탄이 %d초 후 폭발합니다!', bombTimer), 'error')
            end

            -- 폭탄 폭발
            if bombTimer <= 0 then
                ExplodeBomb()
            end
        end
    end
end)

-- 폭탄 폭발
RegisterServerEvent('bumbercar:server:bombExplode')
AddEventHandler('bumbercar:server:bombExplode', function()
    ExplodeBomb()
end)

function ExplodeBomb()
    if not bombHolder or not BumberCar.Players[bombHolder] then
        bombTimerActive = false
        return
    end

    Utils.Success('Bomb exploded! Holder:', GetPlayerName(bombHolder))

    -- 폭발 위치
    local holderPed = GetPlayerPed(bombHolder)
    local explosionPos = GetEntityCoords(holderPed)

    -- 클라이언트에 폭발 효과
    TriggerClientEvent('bumbercar:client:createExplosion', -1, explosionPos, Config.Bomb.ExplosionRadius)

    -- 범위 내 모든 플레이어에게 데미지
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.state == Constants.PlayerState.PLAYING then
            local playerPed = GetPlayerPed(playerId)
            local playerPos = GetEntityCoords(playerPed)
            local distance = #(explosionPos - playerPos)

            if distance <= Config.Bomb.ExplosionRadius then
                -- 폭탄 소유자는 즉사
                if playerId == bombHolder then
                    BumberCar.Players[playerId].vehicleData.health = 0
                    TriggerEvent('bumbercar:server:playerDeath', playerId, nil)
                else
                    -- 다른 플레이어는 거리 기반 데미지
                    local damageMultiplier = 1.0 - (distance / Config.Bomb.ExplosionRadius)
                    local damage = math.floor(Config.Bomb.ExplosionDamage * damageMultiplier)
                    TriggerEvent('bumbercar:server:applyDamage', playerId, damage, nil)
                end
            end
        end
    end

    -- 폭탄 초기화
    bombHolder = nil
    bombTimer = 0
    bombTimerActive = false

    -- 승리 조건 체크
    Citizen.SetTimeout(1000, function()
        TriggerEvent('bumbercar:server:checkWinCondition')
    end)
end

-- 플레이어가 떠났을 때 폭탄 처리
AddEventHandler('playerDropped', function()
    local source = source

    -- 폭탄 소유자가 떠났으면 랜덤 플레이어에게 전달
    if source == bombHolder and bombTimerActive then
        local alivePlayers = {}
        for playerId, playerData in pairs(BumberCar.Players) do
            if playerId ~= source and playerData.state == Constants.PlayerState.PLAYING then
                table.insert(alivePlayers, playerId)
            end
        end

        if #alivePlayers > 0 then
            bombHolder = Utils.GetRandomElement(alivePlayers)
            TriggerClientEvent('bumbercar:client:bombAssigned', bombHolder, bombTimer)
            TriggerClientEvent('bumbercar:client:bombHolderChanged', -1, bombHolder)
            BumberCar.Notify(bombHolder, '폭탄 소유자가 떠나서 당신에게 폭탄이 넘어왔습니다!', 'error')
            Utils.Debug('Bomb transferred to', GetPlayerName(bombHolder), 'due to player disconnect')
        else
            -- 살아있는 플레이어가 없으면 폭탄 제거
            bombHolder = nil
            bombTimer = 0
            bombTimerActive = false
        end
    end
end)

function Utils.TableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

Utils.Success('Item system loaded!')
