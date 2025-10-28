-- 데미지 시스템 (클라이언트)
local lastCollisionCheck = 0
local vehicleHealth = Config.Vehicle.DefaultHealth
local maxVehicleHealth = Config.Vehicle.DefaultHealth

-- 충돌 감지
Citizen.CreateThread(function()
    while true do
        Wait(100) -- 100ms마다 체크

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING and
           BumberCar.CurrentVehicle then

            local vehicle = BumberCar.CurrentVehicle
            if DoesEntityExist(vehicle) then
                -- 충돌 체크
                if HasEntityCollidedWithAnything(vehicle) then
                    local currentTime = GetGameTimer()

                    -- 쿨다운 체크
                    if (currentTime - lastCollisionCheck) > (Config.Vehicle.CollisionCooldown * 1000) then
                        CheckVehicleCollision(vehicle)
                        lastCollisionCheck = currentTime
                    end
                end
            end
        end
    end
end)

-- 충돌 처리
function CheckVehicleCollision(vehicle)
    local speed = Utils.GetVehicleSpeedKMH(vehicle)

    -- 최소 속도 체크
    if speed < Config.Vehicle.MinSpeedForDamage then
        return
    end

    -- 충돌한 엔티티 찾기
    local pos = GetEntityCoords(vehicle)
    local nearbyVehicles = GetNearbyVehicles(pos, 10.0)

    for _, otherVehicle in ipairs(nearbyVehicles) do
        if otherVehicle ~= vehicle and DoesEntityExist(otherVehicle) then
            local distance = #(GetEntityCoords(vehicle) - GetEntityCoords(otherVehicle))

            -- 가까운 거리에서 충돌 감지
            if distance < 5.0 then
                -- 서버에 충돌 알림
                TriggerServerEvent('bumbercar:server:vehicleCollision',
                    VehToNet(vehicle),
                    VehToNet(otherVehicle),
                    speed,
                    pos
                )

                -- 충돌 효과
                PlayCollisionEffect(vehicle, speed)
                break
            end
        end
    end
end

-- 주변 차량 가져오기
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

-- 충돌 효과
function PlayCollisionEffect(vehicle, speed)
    -- 카메라 흔들림
    local intensity = math.min(speed / 100.0, 1.0)
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)

    -- 소리
    if Config.Sounds.Enabled then
        PlaySoundFromEntity(-1, 'CRASH', vehicle, 'DLC_CHRISTMAS2017_SOUNDS', false, 0)
    end
end

-- 차량 체력 업데이트
RegisterNetEvent('bumbercar:client:updateVehicleHealth')
AddEventHandler('bumbercar:client:updateVehicleHealth', function(health, maxHealth)
    vehicleHealth = health
    maxVehicleHealth = maxHealth

    -- 차량 실제 체력 동기화 (시각적 효과)
    if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
        local percentage = health / maxHealth
        local bodyHealth = 1000.0 * percentage
        SetVehicleBodyHealth(BumberCar.CurrentVehicle, bodyHealth)

        -- 엔진 데미지 (체력 50% 이하)
        if percentage < 0.5 then
            SetVehicleEngineHealth(BumberCar.CurrentVehicle, bodyHealth)
        end
    end

    -- UI 업데이트
    SendNUIMessage({
        type = 'updateHealth',
        health = health,
        maxHealth = maxHealth,
        percentage = Utils.GetPercentage(health, maxHealth)
    })

    Utils.Debug('Vehicle health updated:', health, '/', maxHealth)
end)

-- 데미지 효과
RegisterNetEvent('bumbercar:client:damageEffect')
AddEventHandler('bumbercar:client:damageEffect', function(damage)
    -- 화면 효과
    StartScreenEffect('DefaultFlash', 200, false)

    -- 데미지 텍스트 표시
    SendNUIMessage({
        type = 'showDamage',
        damage = math.floor(damage)
    })
end)

-- 차량 폭발
RegisterNetEvent('bumbercar:client:explodeVehicle')
AddEventHandler('bumbercar:client:explodeVehicle', function()
    if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
        local coords = GetEntityCoords(BumberCar.CurrentVehicle)

        -- 폭발 효과
        AddExplosion(coords.x, coords.y, coords.z, 7, 1.0, true, false, 1.0)

        -- 차량 파괴
        SetVehicleEngineHealth(BumberCar.CurrentVehicle, -4000.0)
        SetVehicleBodyHealth(BumberCar.CurrentVehicle, 0.0)
        SetVehiclePetrolTankHealth(BumberCar.CurrentVehicle, -4000.0)

        -- 플레이어 사망
        SetEntityHealth(PlayerPedId(), 0)

        BumberCar.PlayerState = Constants.PlayerState.DEAD
    end
end)

-- 차량 수리
RegisterNetEvent('bumbercar:client:repairVehicle')
AddEventHandler('bumbercar:client:repairVehicle', function()
    if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
        -- 시각적 수리
        SetVehicleFixed(BumberCar.CurrentVehicle)
        SetVehicleBodyHealth(BumberCar.CurrentVehicle, 1000.0)
        SetVehicleEngineHealth(BumberCar.CurrentVehicle, 1000.0)
        SetVehiclePetrolTankHealth(BumberCar.CurrentVehicle, 1000.0)

        -- 효과
        local coords = GetEntityCoords(BumberCar.CurrentVehicle)
        PlaySoundFromCoord(-1, 'PICK_UP', coords.x, coords.y, coords.z, 'HUD_FRONTEND_DEFAULT_SOUNDSET', false, 0, false)

        -- 파티클 효과 (초록색 반짝임)
        UseParticleFxAsset('core')
        StartParticleFxNonLoopedAtCoord('ent_dst_elec_fire_sp', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
    end
end)

-- 차량 스탯 업데이트
RegisterNetEvent('bumbercar:client:updateVehicleStats')
AddEventHandler('bumbercar:client:updateVehicleStats', function(vehicleData)
    -- UI 업데이트
    SendNUIMessage({
        type = 'updateStats',
        damage = vehicleData.damage,
        defense = vehicleData.defense,
        health = vehicleData.health,
        maxHealth = vehicleData.maxHealth
    })
end)

-- HUD 업데이트 루프
Citizen.CreateThread(function()
    while true do
        Wait(500)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING and
           BumberCar.CurrentVehicle and
           DoesEntityExist(BumberCar.CurrentVehicle) then

            local speed = Utils.GetVehicleSpeedKMH(BumberCar.CurrentVehicle)

            SendNUIMessage({
                type = 'updateSpeed',
                speed = math.floor(speed)
            })
        end
    end
end)
