-- ============================================
-- 범퍼카 차량 시스템 (클라이언트)
-- 차량 생성, 업그레이드, 충돌 감지, 효과
-- ============================================

local lastCollisionTime = 0
local collisionCooldown = Config.Vehicle.CollisionCooldown * 1000

-- ============================================
-- 차량 스폰
-- ============================================

-- 차량 스폰 이벤트
RegisterNetEvent('bumbercar:client:spawnVehicle')
AddEventHandler('bumbercar:client:spawnVehicle', function(vehicleModel, spawnPoint, vehicleData)
    Utils.Debug('Spawning vehicle:', vehicleModel, 'at', spawnPoint)

    -- 기존 차량 제거
    if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
        DeleteVehicle(BumberCar.CurrentVehicle)
        BumberCar.CurrentVehicle = nil
    end

    -- 모델 로드
    local modelHash = GetHashKey(vehicleModel)
    RequestModel(modelHash)

    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end

    if not HasModelLoaded(modelHash) then
        Utils.Error('Failed to load vehicle model:', vehicleModel)
        return
    end

    -- 차량 생성
    local vehicle = CreateVehicle(
        modelHash,
        spawnPoint.x, spawnPoint.y, spawnPoint.z,
        spawnPoint.w,
        true,  -- network
        false  -- mission entity
    )

    -- 차량 기본 설정
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleNumberPlateText(vehicle, 'BUMPER')
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleNeedsToBeHotwired(vehicle, false)

    -- 연료 및 오일
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleOilLevel(vehicle, 100.0)

    -- 차량 업그레이드 적용
    ApplyVehicleUpgrades(vehicle)

    -- 무적 시간 (스폰 시)
    if Config.Vehicle.InvincibleOnSpawn then
        SetEntityInvincible(vehicle, true)
        SetVehicleCanBeVisiblyDamaged(vehicle, false)

        Citizen.SetTimeout(Config.Vehicle.InvincibleTime * 1000, function()
            if DoesEntityExist(vehicle) then
                SetEntityInvincible(vehicle, false)
                SetVehicleCanBeVisiblyDamaged(vehicle, true)
            end
        end)

        Utils.Debug('Vehicle invincible for', Config.Vehicle.InvincibleTime, 'seconds')
    end

    -- 플레이어 탑승
    local playerPed = PlayerPedId()
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

    -- 전역 변수에 저장
    BumberCar.CurrentVehicle = vehicle

    -- 차량 데이터 저장
    if vehicleData then
        BumberCar.VehicleData = {
            health = vehicleData.health or Config.Vehicle.DefaultHealth,
            defense = vehicleData.defense or Config.Vehicle.DefaultDefense,
            damage = vehicleData.damage or Config.Vehicle.DefaultDamage,
            maxHealth = vehicleData.maxHealth or Config.Vehicle.DefaultHealth
        }
    end

    -- 모델 언로드
    SetModelAsNoLongerNeeded(modelHash)

    -- 서버에 차량 생성 알림 (네트워크 ID 전송)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('bumbercar:server:vehicleSpawned', netId)

    Utils.Debug('Vehicle spawned successfully, NetID:', netId)
end)

-- ============================================
-- 차량 업그레이드
-- ============================================

-- 차량 업그레이드 적용 함수
function ApplyVehicleUpgrades(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end

    -- 최대 업그레이드 적용
    if Config.VehicleCustomization.MaxUpgrades then
        SetVehicleModKit(vehicle, 0)

        -- 모든 모드 최대 업그레이드
        for i = 0, 49 do
            local maxMod = GetNumVehicleMods(vehicle, i) - 1
            if maxMod > 0 then
                SetVehicleMod(vehicle, i, maxMod, false)
            end
        end

        Utils.Debug('Applied max upgrades to vehicle')
    end

    -- 터보
    if Config.VehicleCustomization.Turbo then
        ToggleVehicleMod(vehicle, 18, true)
        Utils.Debug('Turbo enabled')
    end

    -- 제논 라이트
    if Config.VehicleCustomization.XenonLights then
        ToggleVehicleMod(vehicle, 22, true)
    end

    -- 네온 라이트
    if Config.VehicleCustomization.Neons then
        SetVehicleNeonLightEnabled(vehicle, 0, true)
        SetVehicleNeonLightEnabled(vehicle, 1, true)
        SetVehicleNeonLightEnabled(vehicle, 2, true)
        SetVehicleNeonLightEnabled(vehicle, 3, true)
        SetVehicleNeonLightsColour(vehicle, 255, 0, 255)
    end

    -- 랜덤 색상
    if Config.VehicleCustomization.RandomColors then
        local r = math.random(0, 255)
        local g = math.random(0, 255)
        local b = math.random(0, 255)
        SetVehicleCustomPrimaryColour(vehicle, r, g, b)
        SetVehicleCustomSecondaryColour(vehicle, r, g, b)
    end
end

-- ============================================
-- 팀 색상 설정
-- ============================================

-- 팀 색상 적용
RegisterNetEvent('bumbercar:client:setTeamColor')
AddEventHandler('bumbercar:client:setTeamColor', function(team)
    if not BumberCar.CurrentVehicle or not DoesEntityExist(BumberCar.CurrentVehicle) then
        return
    end

    local vehicle = BumberCar.CurrentVehicle
    local colors = Config.TeamColors[team]

    if colors then
        SetVehicleCustomPrimaryColour(vehicle, colors.primary.r, colors.primary.g, colors.primary.b)
        SetVehicleCustomSecondaryColour(vehicle, colors.secondary.r, colors.secondary.g, colors.secondary.b)

        Utils.Debug('Applied team color:', team)
    end
end)

-- ============================================
-- 보스 차량 설정
-- ============================================

-- 보스 차량 설정
RegisterNetEvent('bumbercar:client:setBossVehicle')
AddEventHandler('bumbercar:client:setBossVehicle', function(isBoss)
    if not BumberCar.CurrentVehicle or not DoesEntityExist(BumberCar.CurrentVehicle) then
        return
    end

    local vehicle = BumberCar.CurrentVehicle

    if isBoss then
        Utils.Debug('Setting as boss vehicle')

        -- 보스 차량 무적 (밀림 방지)
        if Config.Boss.BossImmovable then
            SetEntityInvincible(vehicle, true)
            SetVehicleCanBeVisiblyDamaged(vehicle, false)
        end

        -- 보스 차량 시각 효과 (빨간색 네온)
        SetVehicleNeonLightEnabled(vehicle, 0, true)
        SetVehicleNeonLightEnabled(vehicle, 1, true)
        SetVehicleNeonLightEnabled(vehicle, 2, true)
        SetVehicleNeonLightEnabled(vehicle, 3, true)
        SetVehicleNeonLightsColour(vehicle, 255, 0, 0)

        -- 보스 차량 헤드라이트 색상
        SetVehicleHeadlightsColour(vehicle, 1) -- 빨간색
    end
end)

-- ============================================
-- 차량 폭발
-- ============================================

-- 차량 폭발
RegisterNetEvent('bumbercar:client:vehicleExplosion')
AddEventHandler('bumbercar:client:vehicleExplosion', function()
    if not BumberCar.CurrentVehicle or not DoesEntityExist(BumberCar.CurrentVehicle) then
        return
    end

    local vehicle = BumberCar.CurrentVehicle
    local coords = GetEntityCoords(vehicle)

    Utils.Debug('Vehicle explosion triggered')

    -- 폭발 효과
    AddExplosion(coords.x, coords.y, coords.z, 7, 1.0, true, false, 1.0)

    -- 차량 파괴
    SetVehicleEngineHealth(vehicle, -4000.0)
    SetVehicleBodyHealth(vehicle, 0.0)
    SetVehiclePetrolTankHealth(vehicle, -4000.0)

    -- 플레이어 상태 업데이트
    BumberCar.PlayerState = Constants.PlayerState.DEAD
end)

-- ============================================
-- 차량 변경 (랜덤)
-- ============================================

-- 랜덤 차량으로 변경
RegisterNetEvent('bumbercar:client:changeVehicle')
AddEventHandler('bumbercar:client:changeVehicle', function(newModel)
    if not BumberCar.CurrentVehicle or not DoesEntityExist(BumberCar.CurrentVehicle) then
        return
    end

    local oldVehicle = BumberCar.CurrentVehicle
    local pos = GetEntityCoords(oldVehicle)
    local heading = GetEntityHeading(oldVehicle)
    local velocity = GetEntityVelocity(oldVehicle)

    Utils.Debug('Changing to vehicle:', newModel)

    -- 모델 로드
    local modelHash = GetHashKey(newModel)
    RequestModel(modelHash)

    while not HasModelLoaded(modelHash) do
        Wait(10)
    end

    -- 새 차량 생성
    local newVehicle = CreateVehicle(modelHash, pos.x, pos.y, pos.z, heading, true, false)

    -- 차량 설정
    SetVehicleOnGroundProperly(newVehicle)
    SetVehicleEngineOn(newVehicle, true, true, false)
    ApplyVehicleUpgrades(newVehicle)

    -- 속도 유지
    SetEntityVelocity(newVehicle, velocity.x, velocity.y, velocity.z)

    -- 플레이어 탑승
    TaskWarpPedIntoVehicle(PlayerPedId(), newVehicle, -1)

    -- 기존 차량 제거
    DeleteVehicle(oldVehicle)

    -- 전역 변수 업데이트
    BumberCar.CurrentVehicle = newVehicle

    -- 모델 언로드
    SetModelAsNoLongerNeeded(modelHash)

    -- 서버에 알림
    local netId = NetworkGetNetworkIdFromEntity(newVehicle)
    TriggerServerEvent('bumbercar:server:vehicleChanged', netId, newModel)

    Utils.Debug('Vehicle changed successfully')
end)

-- ============================================
-- 힘 적용 (부스트/점프)
-- ============================================

-- 힘 적용 (방향, 힘)
RegisterNetEvent('bumbercar:client:applyForce')
AddEventHandler('bumbercar:client:applyForce', function(direction, force)
    if not BumberCar.CurrentVehicle or not DoesEntityExist(BumberCar.CurrentVehicle) then
        return
    end

    local vehicle = BumberCar.CurrentVehicle

    if direction == 'forward' then
        -- 앞으로 부스트
        local forwardVector = GetEntityForwardVector(vehicle)
        ApplyForceToEntity(
            vehicle, 1,
            forwardVector.x * force, forwardVector.y * force, 0.0,
            0.0, 0.0, 0.0,
            0, true, true, true, false, true
        )
        Utils.Debug('Applied forward boost, force:', force)

    elseif direction == 'up' then
        -- 위로 점프
        ApplyForceToEntity(
            vehicle, 1,
            0.0, 0.0, force,
            0.0, 0.0, 0.0,
            0, true, true, true, false, true
        )
        Utils.Debug('Applied jump, force:', force)
    end

    -- 부스트 효과
    if Config.Sounds.Enabled then
        PlaySoundFromEntity(-1, 'BOOST', vehicle, 'DLC_CHRISTMAS2017_SOUNDS', false, 0)
    end
end)

-- ============================================
-- 충돌 감지
-- ============================================

-- 충돌 감지 루프
Citizen.CreateThread(function()
    while true do
        Wait(100)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING and
           BumberCar.CurrentVehicle then

            local vehicle = BumberCar.CurrentVehicle

            if DoesEntityExist(vehicle) then
                -- 충돌 체크
                if HasEntityCollidedWithAnything(vehicle) then
                    local currentTime = GetGameTimer()

                    -- 쿨다운 체크
                    if (currentTime - lastCollisionTime) > collisionCooldown then
                        CheckVehicleCollision(vehicle)
                        lastCollisionTime = currentTime
                    end
                end
            end
        else
            Wait(500)
        end
    end
end)

-- 충돌 처리 함수
function CheckVehicleCollision(vehicle)
    local speed = Utils.GetVehicleSpeedKMH(vehicle)

    -- 최소 속도 체크
    if speed < Config.Vehicle.MinSpeedForDamage then
        return
    end

    local myPos = GetEntityCoords(vehicle)
    local myVelocity = GetEntityVelocity(vehicle)

    -- 주변 차량 찾기
    local nearbyVehicles = GetNearbyVehicles(myPos, 10.0)

    for _, otherVehicle in ipairs(nearbyVehicles) do
        if otherVehicle ~= vehicle and DoesEntityExist(otherVehicle) then
            local otherPos = GetEntityCoords(otherVehicle)
            local distance = #(myPos - otherPos)

            -- 충돌 거리 체크 (5m 이내)
            if distance < 5.0 then
                -- 다른 플레이어 차량인지 확인
                local targetPlayer = GetPlayerFromVehicle(otherVehicle)

                if targetPlayer and targetPlayer ~= -1 then
                    Utils.Debug('Collision detected with player vehicle, speed:', speed)

                    -- 서버에 충돌 알림
                    local netId = NetworkGetNetworkIdFromEntity(otherVehicle)
                    TriggerServerEvent('bumbercar:server:vehicleCollision',
                        netId,
                        speed,
                        myPos
                    )

                    -- 충돌 효과
                    PlayCollisionEffect(vehicle, speed)

                    break
                end
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
        local distance = #(coords - vehCoords)

        if distance <= radius then
            table.insert(vehicles, vehicle)
        end

        success, vehicle = FindNextVehicle(handle)
    until not success

    EndFindVehicle(handle)
    return vehicles
end

-- 차량에서 플레이어 찾기
function GetPlayerFromVehicle(vehicle)
    local players = GetActivePlayers()

    for _, playerId in ipairs(players) do
        local ped = GetPlayerPed(playerId)
        local veh = GetVehiclePedIsIn(ped, false)

        if veh == vehicle then
            return playerId
        end
    end

    return -1
end

-- 충돌 효과
function PlayCollisionEffect(vehicle, speed)
    -- 카메라 흔들림
    local intensity = math.min(speed / 100.0, 1.0)
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)

    -- 사운드
    if Config.Sounds.Enabled then
        PlaySoundFromEntity(-1, 'CRASH', vehicle, 'DLC_CHRISTMAS2017_SOUNDS', false, 0)
    end

    -- 화면 효과
    StartScreenEffect('DefaultFlash', 100, false)
end

-- ============================================
-- 물 체크
-- ============================================

-- 물 체크는 main.lua에서 처리됨

-- ============================================
-- 속도 효과
-- ============================================

-- 속도 효과 (고속 주행 시)
Citizen.CreateThread(function()
    while true do
        Wait(100)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING and
           BumberCar.CurrentVehicle then

            local vehicle = BumberCar.CurrentVehicle

            if DoesEntityExist(vehicle) then
                local speed = Utils.GetVehicleSpeedKMH(vehicle)

                -- 고속 주행 효과 (150 km/h 이상)
                if speed > 150 then
                    -- 속도감 효과 (FOV 증가)
                    SetTimecycleModifier('raceturbo')
                else
                    -- 기본 효과
                    ClearTimecycleModifier()
                end
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================
-- 리소스 종료 시 정리
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- 차량 제거
        if BumberCar.CurrentVehicle and DoesEntityExist(BumberCar.CurrentVehicle) then
            DeleteVehicle(BumberCar.CurrentVehicle)
        end

        -- 효과 제거
        ClearTimecycleModifier()
    end
end)

Utils.Debug('Vehicle system loaded')
