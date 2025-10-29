-- 데미지 시스템 (서버)
-- 차량 충돌 데미지, 체력 관리, 사망 처리

local collisionCooldowns = {} -- 충돌 쿨다운 추적 {attackerId_defenderId = timestamp}

-- 충돌 이벤트 수신 (클라이언트에서 트리거)
RegisterServerEvent('bumbercar:server:vehicleCollision')
AddEventHandler('bumbercar:server:vehicleCollision', function(defenderId, attackerSpeed)
    local attackerId = source

    -- 유효성 검사
    if not BumberCar.Players[attackerId] or not BumberCar.Players[defenderId] then
        return
    end

    -- 게임 상태 체크 (게임 중이 아니면 무시)
    if BumberCar.GameState ~= Constants.RoundState.PLAYING then
        return
    end

    -- 플레이어 상태 체크 (둘 다 살아있어야 함)
    if BumberCar.Players[attackerId].state ~= Constants.PlayerState.PLAYING or
       BumberCar.Players[defenderId].state ~= Constants.PlayerState.PLAYING then
        return
    end

    -- 무적 상태 체크
    if BumberCar.Players[defenderId].invincible then
        return -- 무적 상태면 데미지 무시
    end

    -- 쿨다운 체크
    local cooldownKey = attackerId .. '_' .. defenderId
    local currentTime = os.time()

    if collisionCooldowns[cooldownKey] and
       currentTime - collisionCooldowns[cooldownKey] < Config.Vehicle.CollisionCooldown then
        return -- 쿨다운 중
    end

    -- 최소 속도 체크
    if attackerSpeed < Config.Vehicle.MinSpeedForDamage then
        return -- 속도가 너무 느림
    end

    -- 쿨다운 설정
    collisionCooldowns[cooldownKey] = currentTime

    -- 데미지 계산
    local damage = CalculateCollisionDamage(attackerId, defenderId, attackerSpeed)

    if damage > 0 then
        ApplyDamage(attackerId, defenderId, damage)
    end
end)

-- 충돌 데미지 계산
function CalculateCollisionDamage(attackerId, defenderId, attackerSpeed)
    local attacker = BumberCar.Players[attackerId]
    local defender = BumberCar.Players[defenderId]

    if not attacker or not defender then
        return 0
    end

    -- 기본 데미지 (공격자의 damage 스탯)
    local baseDamage = attacker.vehicleData.damage or Config.Vehicle.DefaultDamage

    -- 데미지 부스트 효과 적용
    if attacker.effects and attacker.effects.damage_boost then
        local multiplier = Config.ItemList.damage_boost.multiplier or 2.0
        baseDamage = baseDamage * multiplier
    end

    -- 속도 배율 계산 (속도가 빠를수록 더 많은 데미지)
    -- 속도 기준: 100 km/h = 1.0x, 200 km/h = 2.0x
    local speedMultiplier = (attackerSpeed / 100.0) * Config.Vehicle.SpeedDamageMultiplier
    speedMultiplier = math.max(0.5, math.min(speedMultiplier, 3.0)) -- 0.5x ~ 3.0x 제한

    -- 방어력 적용 (방어자의 defense 스탯으로 데미지 감소)
    local defense = defender.vehicleData.defense or Config.Vehicle.DefaultDefense

    -- 방어력 부스트 효과 적용
    if defender.effects and defender.effects.defense_boost then
        local multiplier = Config.ItemList.defense_boost.multiplier or 2.0
        defense = defense * multiplier
    end

    local defenseReduction = defense * 0.5 -- 방어력의 50%만큼 데미지 감소

    -- 최종 데미지 계산
    local finalDamage = (baseDamage * speedMultiplier) - defenseReduction

    -- 보스 모드 특별 처리
    if attacker.vehicleData.isBoss then
        -- 보스는 추가 데미지
        finalDamage = finalDamage * Config.Boss.BossDamageMultiplier
        Utils.Debug('Boss collision damage multiplier applied')
    end

    if defender.vehicleData.isBoss then
        -- 보스는 받는 데미지 50% 감소
        finalDamage = finalDamage * 0.5
        Utils.Debug('Boss damage reduction applied')
    end

    -- 팀 프렌들리 파이어 감소
    if IsTeamMode(BumberCar.CurrentGameMode) and
       attacker.team == defender.team and
       attacker.team ~= Constants.Team.NONE then
        finalDamage = finalDamage * 0.5 -- 팀원 데미지 50%
        Utils.Debug('Friendly fire - damage reduced by 50%')
    end

    -- 최소 데미지 보장
    finalDamage = math.max(5, math.floor(finalDamage))

    Utils.Debug('Collision damage calculated:', finalDamage,
                '(Base:', baseDamage, 'Speed:', string.format("%.1f", attackerSpeed), 'km/h, Multiplier:', string.format("%.2f", speedMultiplier), ')')

    return finalDamage
end

-- 데미지 적용 (수동 데미지 적용용 - 무기, 아이템 등)
RegisterServerEvent('bumbercar:server:applyDamage')
AddEventHandler('bumbercar:server:applyDamage', function(targetId, damage, source_override)
    local sourceId = source_override or source

    -- 유효성 검사
    if not BumberCar.Players[targetId] then
        return
    end

    -- 게임 상태 체크
    if BumberCar.GameState ~= Constants.RoundState.PLAYING then
        return
    end

    -- 대상 상태 체크
    if BumberCar.Players[targetId].state ~= Constants.PlayerState.PLAYING then
        return
    end

    -- 무적 상태 체크
    if BumberCar.Players[targetId].invincible then
        return
    end

    ApplyDamage(sourceId, targetId, damage)
end)

-- 데미지 적용 및 체력 관리
function ApplyDamage(attackerId, victimId, damage)
    local victim = BumberCar.Players[victimId]

    if not victim or not victim.vehicleData then
        return
    end

    -- 현재 체력
    local currentHealth = victim.vehicleData.health or 0

    -- 데미지 적용
    local newHealth = math.max(0, currentHealth - damage)
    victim.vehicleData.health = newHealth

    -- 통계 업데이트
    if BumberCar.Players[attackerId] then
        if not BumberCar.Players[attackerId].stats.damageDealt then
            BumberCar.Players[attackerId].stats.damageDealt = 0
        end
        BumberCar.Players[attackerId].stats.damageDealt = BumberCar.Players[attackerId].stats.damageDealt + damage
    end

    if not victim.stats.damageTaken then
        victim.stats.damageTaken = 0
    end
    victim.stats.damageTaken = victim.stats.damageTaken + damage

    Utils.Debug('Damage applied:', damage, 'to', GetPlayerName(victimId),
                '- Health:', newHealth, '/', victim.vehicleData.maxHealth)

    -- 체력 동기화 (클라이언트에 업데이트)
    TriggerClientEvent('bumbercar:client:updateHealth', victimId, {
        health = newHealth,
        maxHealth = victim.vehicleData.maxHealth,
        defense = victim.vehicleData.defense,
        damage = victim.vehicleData.damage
    })

    -- 데미지 숫자 표시
    TriggerClientEvent('bumbercar:client:showDamageNumber', victimId, damage)

    -- 사망 처리
    if newHealth <= 0 then
        Utils.Debug('Player', GetPlayerName(victimId), 'health depleted - triggering death')
        HandlePlayerDeath(victimId, attackerId)
    end
end

-- 플레이어 사망 처리
function HandlePlayerDeath(victimId, killerId)
    local victim = BumberCar.Players[victimId]

    if not victim then
        return
    end

    -- 이미 죽은 상태면 무시
    if victim.state == Constants.PlayerState.DEAD then
        return
    end

    Utils.Success('Player death:', GetPlayerName(victimId),
                  'killed by:', killerId and GetPlayerName(killerId) or 'Unknown')

    -- 차량 폭발 효과
    TriggerClientEvent('bumbercar:client:vehicleExplosion', victimId)

    -- 사망 이벤트 트리거 (round.lua에서 처리)
    TriggerEvent('bumbercar:server:playerDeath', victimId, killerId)
end

-- 체력 회복
RegisterServerEvent('bumbercar:server:healVehicle')
AddEventHandler('bumbercar:server:healVehicle', function(healAmount)
    local source = source

    if not BumberCar.Players[source] then
        return
    end

    local player = BumberCar.Players[source]
    local maxHealth = player.vehicleData.maxHealth or Config.Vehicle.DefaultHealth
    local currentHealth = player.vehicleData.health or 0

    -- 회복량 계산
    local newHealth = math.min(maxHealth, currentHealth + healAmount)
    player.vehicleData.health = newHealth

    Utils.Debug('Vehicle healed:', GetPlayerName(source),
                '- Health:', currentHealth, '->', newHealth)

    -- 클라이언트에 동기화
    TriggerClientEvent('bumbercar:client:updateHealth', source, {
        health = newHealth,
        maxHealth = maxHealth,
        defense = player.vehicleData.defense,
        damage = player.vehicleData.damage
    })

    -- 회복 효과 표시
    TriggerClientEvent('bumbercar:client:showHealEffect', source)
end)

-- 차량 스탯 업데이트 (아이템 효과 등)
RegisterServerEvent('bumbercar:server:updateVehicleStats')
AddEventHandler('bumbercar:server:updateVehicleStats', function(newStats)
    local source = source

    if not BumberCar.Players[source] then
        return
    end

    local player = BumberCar.Players[source]

    -- 스탯 업데이트
    if newStats.damage then
        player.vehicleData.damage = newStats.damage
    end

    if newStats.defense then
        player.vehicleData.defense = newStats.defense
    end

    if newStats.speed then
        player.vehicleData.speed = newStats.speed
    end

    Utils.Debug('Vehicle stats updated for', GetPlayerName(source))

    -- 클라이언트에 동기화
    TriggerClientEvent('bumbercar:client:updateHealth', source, {
        health = player.vehicleData.health,
        maxHealth = player.vehicleData.maxHealth,
        defense = player.vehicleData.defense,
        damage = player.vehicleData.damage,
        speed = player.vehicleData.speed
    })
end)

-- 무적 상태 설정 (스폰 시)
RegisterServerEvent('bumbercar:server:setInvincible')
AddEventHandler('bumbercar:server:setInvincible', function(duration)
    local source = source

    if not BumberCar.Players[source] then
        return
    end

    -- 무적 플래그 설정
    BumberCar.Players[source].invincible = true

    Utils.Debug('Player', GetPlayerName(source), 'is now invincible for', duration, 'seconds')

    -- 클라이언트에 무적 효과 표시
    TriggerClientEvent('bumbercar:client:setInvincible', source, true, duration)

    -- 지정된 시간 후 무적 해제
    Citizen.SetTimeout(duration * 1000, function()
        if BumberCar.Players[source] then
            BumberCar.Players[source].invincible = false
            TriggerClientEvent('bumbercar:client:setInvincible', source, false, 0)
            Utils.Debug('Player', GetPlayerName(source), 'invincibility ended')
        end
    end)
end)

-- 충돌 쿨다운 정리 (주기적으로 오래된 쿨다운 제거)
Citizen.CreateThread(function()
    while true do
        Wait(30000) -- 30초마다 정리

        local currentTime = os.time()
        local cleanupThreshold = 10 -- 10초 이상 지난 쿨다운 제거

        for key, timestamp in pairs(collisionCooldowns) do
            if currentTime - timestamp > cleanupThreshold then
                collisionCooldowns[key] = nil
            end
        end
    end
end)

-- 경계 이탈 데미지 (시간 초과 시 폭발)
RegisterServerEvent('bumbercar:server:boundaryViolation')
AddEventHandler('bumbercar:server:boundaryViolation', function()
    local source = source

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

    Utils.Debug('Player', GetPlayerName(source), 'violated boundary - instant death')

    -- 즉시 사망 (킬러 없음)
    BumberCar.Players[source].vehicleData.health = 0
    HandlePlayerDeath(source, nil)
end)

Utils.Success('Damage system loaded!')
