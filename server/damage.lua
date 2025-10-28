-- 데미지 시스템 (서버)
local lastCollisionTime = {}

-- 충돌 데미지 처리
RegisterNetEvent('bumbercar:server:vehicleCollision')
AddEventHandler('bumbercar:server:vehicleCollision', function(attackerVehicle, victimVehicle, speed, position)
    local attacker = source
    local victim = nil

    -- 피해자 찾기
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.vehicle == victimVehicle then
            victim = playerId
            break
        end
    end

    if not victim or not BumberCar.Players[attacker] then
        return
    end

    -- 같은 팀이면 데미지 없음 (팀전 모드)
    if BumberCar.CurrentGameMode == Constants.GameMode.ITEM_TEAM or
       BumberCar.CurrentGameMode == Constants.GameMode.BOMB_TEAM or
       BumberCar.CurrentGameMode == Constants.GameMode.CLASSIC_TEAM then
        if BumberCar.Players[attacker].team == BumberCar.Players[victim].team then
            return
        end
    end

    -- 쿨다운 체크
    local currentTime = GetGameTimer()
    local cooldownKey = attacker .. '_' .. victim

    if lastCollisionTime[cooldownKey] and
       (currentTime - lastCollisionTime[cooldownKey]) < (Config.Vehicle.CollisionCooldown * 1000) then
        return
    end

    lastCollisionTime[cooldownKey] = currentTime

    -- 데미지 계산
    local attackerData = BumberCar.Players[attacker].vehicleData
    local victimData = BumberCar.Players[victim].vehicleData

    local baseDamage = attackerData.damage
    local damage = Utils.CalculateCollisionDamage(speed, baseDamage, 1.0)

    -- 공격자 버프 적용
    if BumberCar.Players[attacker].effects.damage_boost then
        damage = damage * Config.ItemList.damage_boost.multiplier
    end

    -- 방어력 계산
    local defense = victimData.defense
    if BumberCar.Players[victim].effects.defense_boost then
        defense = defense * Config.ItemList.defense_boost.multiplier
    end

    -- 최종 데미지 = 데미지 - (방어력 * 0.5)
    local finalDamage = math.max(1, damage - (defense * 0.5))

    -- 체력 감소
    victimData.health = math.max(0, victimData.health - finalDamage)

    -- 통계 업데이트
    BumberCar.Players[attacker].stats.damageDealt = BumberCar.Players[attacker].stats.damageDealt + finalDamage
    BumberCar.Players[victim].stats.damageTaken = BumberCar.Players[victim].stats.damageTaken + finalDamage

    Utils.Debug(string.format('Collision: %s -> %s | Speed: %.1f | Damage: %.0f | Health: %.0f',
        GetPlayerName(attacker), GetPlayerName(victim), speed, finalDamage, victimData.health))

    -- 클라이언트에 업데이트 전송
    TriggerClientEvent('bumbercar:client:updateVehicleHealth', victim, victimData.health, victimData.maxHealth)
    TriggerClientEvent('bumbercar:client:damageEffect', victim, finalDamage)

    -- 차량 파괴
    if victimData.health <= 0 then
        TriggerEvent('bumbercar:server:playerDied', victim, attacker, position)
    end
end)

-- 플레이어 사망 처리
RegisterServerEvent('bumbercar:server:playerDied')
AddEventHandler('bumbercar:server:playerDied', function(victim, attacker, position)
    if not BumberCar.Players[victim] then return end

    local victimName = GetPlayerName(victim)
    local attackerName = attacker and GetPlayerName(attacker) or nil

    -- 상태 변경
    BumberCar.Players[victim].state = Constants.PlayerState.DEAD

    -- 통계 업데이트
    BumberCar.Players[victim].stats.deaths = BumberCar.Players[victim].stats.deaths + 1
    if attacker and BumberCar.Players[attacker] then
        BumberCar.Players[attacker].stats.kills = BumberCar.Players[attacker].stats.kills + 1
    end

    -- 알림
    if attackerName then
        BumberCar.NotifyAll(string.format(Config.Notifications.PlayerDied, victimName), 'info')
    else
        BumberCar.NotifyAll(string.format('%s님이 탈락했습니다', victimName), 'info')
    end

    -- 차량 폭발
    TriggerClientEvent('bumbercar:client:explodeVehicle', victim)

    -- 관전 모드로 전환
    Citizen.SetTimeout(Config.Round.RespawnDelay * 1000, function()
        if BumberCar.Players[victim] and BumberCar.GameState == Constants.RoundState.PLAYING then
            TriggerClientEvent('bumbercar:client:startSpectating', victim)
        end
    end)

    -- 게임 종료 체크
    Citizen.SetTimeout(1000, function()
        TriggerEvent('bumbercar:server:checkRoundEnd')
    end)
end)

-- 라운드 종료 체크
RegisterServerEvent('bumbercar:server:checkRoundEnd')
AddEventHandler('bumbercar:server:checkRoundEnd', function()
    if BumberCar.GameState ~= Constants.RoundState.PLAYING then
        return
    end

    local gameMode = BumberCar.CurrentGameMode

    -- 팀전
    if gameMode == Constants.GameMode.ITEM_TEAM or
       gameMode == Constants.GameMode.BOMB_TEAM or
       gameMode == Constants.GameMode.CLASSIC_TEAM then

        local redAlive = BumberCar.GetAlivePlayersByTeam(Constants.Team.RED)
        local blueAlive = BumberCar.GetAlivePlayersByTeam(Constants.Team.BLUE)

        if redAlive == 0 and blueAlive > 0 then
            TriggerEvent('bumbercar:server:endRound', Constants.Team.BLUE)
        elseif blueAlive == 0 and redAlive > 0 then
            TriggerEvent('bumbercar:server:endRound', Constants.Team.RED)
        elseif redAlive == 0 and blueAlive == 0 then
            TriggerEvent('bumbercar:server:endRound', nil) -- 무승부
        end

    -- 개인전
    else
        local alivePlayers = {}
        for playerId, playerData in pairs(BumberCar.Players) do
            if playerData.state == Constants.PlayerState.PLAYING then
                table.insert(alivePlayers, playerId)
            end
        end

        if #alivePlayers == 1 then
            TriggerEvent('bumbercar:server:endRound', alivePlayers[1])
        elseif #alivePlayers == 0 then
            TriggerEvent('bumbercar:server:endRound', nil) -- 무승부
        end
    end
end)

-- 차량 수리
RegisterNetEvent('bumbercar:server:repairVehicle')
AddEventHandler('bumbercar:server:repairVehicle', function(amount)
    local source = source
    if not BumberCar.Players[source] then return end

    local vehicleData = BumberCar.Players[source].vehicleData
    local oldHealth = vehicleData.health

    if amount == 'max' or amount >= vehicleData.maxHealth then
        vehicleData.health = vehicleData.maxHealth
    else
        vehicleData.health = math.min(vehicleData.maxHealth, vehicleData.health + amount)
    end

    local healed = vehicleData.health - oldHealth

    Utils.Debug(string.format('Vehicle repaired: %s | +%.0f HP | Current: %.0f/%.0f',
        GetPlayerName(source), healed, vehicleData.health, vehicleData.maxHealth))

    TriggerClientEvent('bumbercar:client:updateVehicleHealth', source, vehicleData.health, vehicleData.maxHealth)
    TriggerClientEvent('bumbercar:client:repairVehicle', source)
end)

-- 차량 스탯 변경
RegisterNetEvent('bumbercar:server:modifyVehicleStats')
AddEventHandler('bumbercar:server:modifyVehicleStats', function(stat, value, duration)
    local source = source
    if not BumberCar.Players[source] then return end

    local vehicleData = BumberCar.Players[source].vehicleData

    if stat == 'damage' then
        vehicleData.damage = value
    elseif stat == 'defense' then
        vehicleData.defense = value
    end

    Utils.Debug(string.format('Vehicle stat modified: %s | %s = %.0f',
        GetPlayerName(source), stat, value))

    TriggerClientEvent('bumbercar:client:updateVehicleStats', source, vehicleData)

    -- 지속 시간 후 복구
    if duration then
        Citizen.SetTimeout(duration * 1000, function()
            if BumberCar.Players[source] then
                if stat == 'damage' then
                    vehicleData.damage = Config.Vehicle.DefaultDamage
                elseif stat == 'defense' then
                    vehicleData.defense = Config.Vehicle.DefaultDefense
                end
                TriggerClientEvent('bumbercar:client:updateVehicleStats', source, vehicleData)
            end
        end)
    end
end)

-- 경계 이탈로 인한 사망
RegisterNetEvent('bumbercar:server:boundaryDeath')
AddEventHandler('bumbercar:server:boundaryDeath', function()
    local source = source
    if not BumberCar.Players[source] then return end

    if BumberCar.Players[source].state == Constants.PlayerState.PLAYING then
        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)

        TriggerEvent('bumbercar:server:playerDied', source, nil, coords)
    end
end)
