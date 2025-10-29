-- ============================================
-- 범퍼카 무기 시스템 (클라이언트)
-- 무기전 모드: 조준, 발사, 락온, 탄약
-- ============================================

local currentWeapon = nil
local weaponProp = nil
local isAiming = false
local isFiring = false
local lastFireTime = 0
local currentAmmo = 0

-- 락온 시스템
local lockOnTarget = nil
local lockOnProgress = 0
local lockOnStartTime = 0

-- 필드의 무기 아이템 (픽업용)
local activeWeapons = {}

-- 탄약 상자
local ammoBoxes = {}

-- ============================================
-- 무기 할당
-- ============================================

-- 무기 할당 (게임 시작 시 또는 픽업 시)
RegisterNetEvent('bumbercar:client:weaponAssigned')
AddEventHandler('bumbercar:client:weaponAssigned', function(weaponId, ammo)
    currentWeapon = weaponId
    currentAmmo = ammo or 0

    local weaponData = Config.Weapons[weaponId]

    if weaponData then
        BumberCar.Weapon.id = weaponId
        BumberCar.Weapon.ammo = currentAmmo

        Utils.Debug('Weapon assigned:', weaponData.name, 'Ammo:', currentAmmo)

        -- 무기 프롭 생성
        CreateWeaponProp(weaponId, weaponData)

        -- UI 업데이트
        SendNUIMessage({
            type = 'updateWeapon',
            data = {
                weaponId = weaponId,
                weaponData = weaponData,
                ammo = currentAmmo
            }
        })

        -- 알림
        TriggerEvent('bumbercar:client:notify',
            string.format('%s 장착', weaponData.name),
            'success')
    end
end)

-- 무기 변경
RegisterNetEvent('bumbercar:client:weaponChanged')
AddEventHandler('bumbercar:client:weaponChanged', function(weaponId, ammo)
    -- 기존 무기 프롭 제거
    if weaponProp and DoesEntityExist(weaponProp) then
        DeleteEntity(weaponProp)
        weaponProp = nil
    end

    -- 새 무기 할당
    TriggerEvent('bumbercar:client:weaponAssigned', weaponId, ammo)
end)

-- ============================================
-- 무기 프롭 생성
-- ============================================

-- 무기 프롭 생성 및 차량에 부착
function CreateWeaponProp(weaponId, weaponData)
    if not BumberCar.CurrentVehicle or not DoesEntityExist(BumberCar.CurrentVehicle) then
        Utils.Debug('Cannot create weapon prop - no vehicle')
        return
    end

    -- 기존 프롭 제거
    if weaponProp and DoesEntityExist(weaponProp) then
        DeleteEntity(weaponProp)
        weaponProp = nil
    end

    local vehicle = BumberCar.CurrentVehicle
    local modelHash = GetHashKey(weaponData.model)

    -- 모델 로드
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end

    -- 프롭 생성
    local vehCoords = GetEntityCoords(vehicle)
    weaponProp = CreateObject(modelHash, vehCoords.x, vehCoords.y, vehCoords.z, false, false, false)

    -- 차량에 부착
    local mountPos = weaponData.mountPosition or vector3(0.0, 1.5, 0.3)
    local mountRot = weaponData.mountRotation or vector3(0.0, 0.0, 0.0)

    AttachEntityToEntity(
        weaponProp, vehicle,
        GetEntityBoneIndexByName(vehicle, 'bonnet'),
        mountPos.x, mountPos.y, mountPos.z,
        mountRot.x, mountRot.y, mountRot.z,
        false, false, false, false, 2, true
    )

    SetModelAsNoLongerNeeded(modelHash)

    Utils.Debug('Weapon prop created and attached')
end

-- ============================================
-- 조준 시스템
-- ============================================

-- 조준 모드 진입/해제
function ToggleAimMode()
    isAiming = not isAiming

    if isAiming then
        Utils.Debug('Entering aim mode')

        -- FOV 감소 (줌 효과)
        SetCamFov(GetRenderingCam(), Config.WeaponMode.AimFOV or 40.0)

        -- 크로스헤어 표시
        SendNUIMessage({
            type = 'showCrosshair',
            data = {
                color = Config.WeaponMode.CrosshairColor
            }
        })

    else
        Utils.Debug('Exiting aim mode')

        -- FOV 원래대로
        SetCamFov(GetRenderingCam(), 75.0)

        -- 크로스헤어 숨기기
        SendNUIMessage({
            type = 'hideCrosshair'
        })

        -- 락온 취소
        lockOnTarget = nil
        lockOnProgress = 0
    end
end

-- 조준 컨트롤
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING and
           currentWeapon and
           Config.WeaponMode.Enabled then

            -- 우클릭: 조준 모드
            if Config.WeaponMode.RightClickAim then
                if IsControlPressed(0, 25) then -- 우클릭
                    if not isAiming then
                        ToggleAimMode()
                    end
                else
                    if isAiming then
                        ToggleAimMode()
                    end
                end
            end

        else
            Wait(100)
        end
    end
end)

-- ============================================
-- 발사 시스템
-- ============================================

-- 발사
function FireWeapon()
    if not currentWeapon or not BumberCar.CurrentVehicle then
        return
    end

    local weaponData = Config.Weapons[currentWeapon]
    if not weaponData then
        return
    end

    -- 탄약 체크
    if weaponData.ammo ~= -1 and currentAmmo <= 0 then
        TriggerEvent('bumbercar:client:notify', '탄약이 부족합니다!', 'warning')
        return
    end

    -- 발사 속도 쿨다운
    local currentTime = GetGameTimer()
    if (currentTime - lastFireTime) < (weaponData.fireRate * 1000) then
        return
    end

    lastFireTime = currentTime

    -- 조준 위치 계산
    local vehicle = BumberCar.CurrentVehicle
    local vehCoords = GetEntityCoords(vehicle)
    local vehForward = GetEntityForwardVector(vehicle)

    -- 카메라 방향으로 발사 (조준 모드)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local aimDirection = RotationToDirection(camRot)
    local targetPos = camCoords + aimDirection * weaponData.range

    Utils.Debug('Firing weapon:', weaponData.name)

    -- 서버에 발사 알림
    TriggerServerEvent('bumbercar:server:weaponFire',
        vehCoords,
        targetPos,
        aimDirection,
        lockOnTarget
    )

    -- 클라이언트 발사 효과
    PlayFireEffects(vehCoords, targetPos, weaponData)

    -- 탄약 감소 (무한 탄약이 아니면)
    if weaponData.ammo ~= -1 then
        currentAmmo = currentAmmo - 1
        BumberCar.Weapon.ammo = currentAmmo

        -- UI 업데이트
        SendNUIMessage({
            type = 'updateAmmo',
            data = {
                ammo = currentAmmo
            }
        })
    end
end

-- 발사 컨트롤
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if isAiming and currentWeapon then
            local weaponData = Config.Weapons[currentWeapon]

            -- 좌클릭: 발사
            if Config.WeaponMode.LeftClickFire then
                if Config.WeaponMode.AutoFire then
                    -- 자동 발사 (누르고 있으면 계속 발사)
                    if IsControlPressed(0, 24) then -- 좌클릭
                        FireWeapon()
                    end
                else
                    -- 단발 (클릭마다 한 발)
                    if IsControlJustPressed(0, 24) then
                        FireWeapon()
                    end
                end
            end

        else
            Wait(100)
        end
    end
end)

-- 발사 효과
function PlayFireEffects(startPos, endPos, weaponData)
    -- 총구 화염
    if weaponData.muzzleFlash then
        local coords = GetEntityCoords(weaponProp or BumberCar.CurrentVehicle)
        UseParticleFxAsset('core')
        StartParticleFxNonLoopedAtCoord(
            'muz_railgun',
            coords.x, coords.y, coords.z,
            0.0, 0.0, 0.0,
            1.0, false, false, false
        )
    end

    -- 탄도 표시
    if weaponData.bulletTracer then
        local color = weaponData.tracerColor or {r = 255, g = 255, b = 0}
        DrawLine(
            startPos.x, startPos.y, startPos.z,
            endPos.x, endPos.y, endPos.z,
            color.r, color.g, color.b, 255
        )
    end

    -- 발사 사운드
    if Config.Sounds.Enabled and weaponData.soundEffect then
        PlaySoundFromCoord(-1, weaponData.soundEffect, startPos.x, startPos.y, startPos.z,
            'DLC_CHRISTMAS2017_SOUNDS', false, 0, false)
    end

    -- 카메라 흔들림
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.3)
end

-- 회전을 방향 벡터로 변환
function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )

    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )

    return direction
end

-- ============================================
-- 피격 효과
-- ============================================

-- 무기 발사 효과 (다른 플레이어가 발사한 것)
RegisterNetEvent('bumbercar:client:weaponFired')
AddEventHandler('bumbercar:client:weaponFired', function(shooterPos, targetPos, weaponId)
    local weaponData = Config.Weapons[weaponId]

    if weaponData and weaponData.bulletTracer then
        -- 탄도 표시
        local color = weaponData.tracerColor or {r = 255, g = 255, b = 0}

        Citizen.CreateThread(function()
            local endTime = GetGameTimer() + 100 -- 100ms 동안 표시

            while GetGameTimer() < endTime do
                DrawLine(
                    shooterPos.x, shooterPos.y, shooterPos.z,
                    targetPos.x, targetPos.y, targetPos.z,
                    color.r, color.g, color.b, 255
                )
                Wait(0)
            end
        end)
    end

    -- 사운드
    if Config.Sounds.Enabled and weaponData.soundEffect then
        PlaySoundFromCoord(-1, weaponData.soundEffect,
            shooterPos.x, shooterPos.y, shooterPos.z,
            'DLC_CHRISTMAS2017_SOUNDS', false, 0, false)
    end
end)

-- 피격 마커
RegisterNetEvent('bumbercar:client:weaponHit')
AddEventHandler('bumbercar:client:weaponHit', function(damage)
    Utils.Debug('Weapon hit! Damage:', damage)

    -- 히트 마커 표시
    if Config.WeaponMode.HitMarker then
        SendNUIMessage({
            type = 'showHitMarker',
            data = {
                damage = damage
            }
        })
    end

    -- 히트 사운드
    if Config.WeaponMode.HitMarkerSound and Config.Sounds.Enabled then
        PlaySound(-1, 'HIT_CONFIRM', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false, 0, true)
    end

    -- 화면 효과
    StartScreenEffect('DefaultFlash', 200, false)
end)

-- ============================================
-- 락온 시스템
-- ============================================

-- 락온 업데이트 루프
Citizen.CreateThread(function()
    while true do
        Wait(100)

        if isAiming and currentWeapon then
            local weaponData = Config.Weapons[currentWeapon]

            -- 락온 가능한 무기인지 체크
            if weaponData and weaponData.lockOnEnabled then
                UpdateLockOn(weaponData)
            end
        else
            lockOnTarget = nil
            lockOnProgress = 0
        end
    end
end)

-- 락온 업데이트
function UpdateLockOn(weaponData)
    local vehicle = BumberCar.CurrentVehicle
    if not vehicle or not DoesEntityExist(vehicle) then
        return
    end

    local vehCoords = GetEntityCoords(vehicle)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local aimDirection = RotationToDirection(camRot)

    -- 조준선 상의 대상 찾기
    local nearestTarget = nil
    local nearestDistance = weaponData.lockOnRange or 80.0

    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetVeh = GetVehiclePedIsIn(targetPed, false)

            if targetVeh and targetVeh ~= 0 and DoesEntityExist(targetVeh) then
                local targetCoords = GetEntityCoords(targetVeh)
                local distance = #(vehCoords - targetCoords)

                if distance <= nearestDistance then
                    -- 조준선과 대상의 각도 체크
                    local dirToTarget = targetCoords - camCoords
                    local angle = math.acos(
                        (aimDirection.x * dirToTarget.x + aimDirection.y * dirToTarget.y + aimDirection.z * dirToTarget.z) /
                        (#aimDirection * #dirToTarget)
                    )

                    -- 조준선 근처에 있으면 (5도 이내)
                    if angle < math.rad(5) then
                        nearestDistance = distance
                        nearestTarget = playerId
                    end
                end
            end
        end
    end

    -- 락온 진행
    if nearestTarget then
        if lockOnTarget == nearestTarget then
            -- 같은 대상 - 진행도 증가
            local currentTime = GetGameTimer()
            local elapsed = (currentTime - lockOnStartTime) / 1000.0
            lockOnProgress = math.min(elapsed / (weaponData.lockOnTime or 2.0), 1.0)

            -- 락온 완료
            if lockOnProgress >= 1.0 then
                -- 서버에 락온 확인
                TriggerServerEvent('bumbercar:server:weaponLockOn', GetPlayerServerId(nearestTarget))

                Utils.Debug('Lock-on complete on player', nearestTarget)
            end

        else
            -- 새로운 대상
            lockOnTarget = nearestTarget
            lockOnStartTime = GetGameTimer()
            lockOnProgress = 0
        end

        -- UI 업데이트
        SendNUIMessage({
            type = 'updateLockOn',
            data = {
                progress = lockOnProgress,
                locked = lockOnProgress >= 1.0
            }
        })

    else
        -- 대상 없음
        lockOnTarget = nil
        lockOnProgress = 0

        SendNUIMessage({
            type = 'updateLockOn',
            data = {
                progress = 0,
                locked = false
            }
        })
    end
end

-- 락온 확인
RegisterNetEvent('bumbercar:client:lockOnConfirmed')
AddEventHandler('bumbercar:client:lockOnConfirmed', function()
    Utils.Debug('Lock-on confirmed by server')

    -- UI 업데이트
    SendNUIMessage({
        type = 'lockOnConfirmed'
    })

    -- 사운드
    if Config.Sounds.Enabled then
        PlaySound(-1, 'LOCK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false, 0, true)
    end
end)

-- ============================================
-- 재장전
-- ============================================

-- 재장전 (R 키)
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING and
           currentWeapon then

            -- R 키: 재장전
            if IsControlJustPressed(0, 45) then -- R
                local weaponData = Config.Weapons[currentWeapon]

                if weaponData and weaponData.ammo ~= -1 and weaponData.reloadTime > 0 then
                    Utils.Debug('Reloading weapon')

                    -- 서버에 재장전 요청
                    TriggerServerEvent('bumbercar:server:weaponReload')

                    -- UI 업데이트
                    SendNUIMessage({
                        type = 'reloadingWeapon',
                        data = {
                            reloadTime = weaponData.reloadTime
                        }
                    })
                end
            end

        else
            Wait(100)
        end
    end
end)

-- 탄약 업데이트
RegisterNetEvent('bumbercar:client:ammoUpdate')
AddEventHandler('bumbercar:client:ammoUpdate', function(newAmmo)
    currentAmmo = newAmmo
    BumberCar.Weapon.ammo = newAmmo

    Utils.Debug('Ammo updated:', newAmmo)

    -- UI 업데이트
    SendNUIMessage({
        type = 'updateAmmo',
        data = {
            ammo = newAmmo
        }
    })
end)

-- ============================================
-- 무기 및 탄약 픽업
-- ============================================

-- 무기 스폰
RegisterNetEvent('bumbercar:client:weaponSpawned')
AddEventHandler('bumbercar:client:weaponSpawned', function(weaponIndex, weaponId, position)
    activeWeapons[weaponIndex] = {
        id = weaponIndex,
        weaponId = weaponId,
        position = vector3(position.x, position.y, position.z),
        active = true
    }

    Utils.Debug('Weapon spawned:', weaponId, 'at index', weaponIndex)
end)

-- 탄약 상자 스폰
RegisterNetEvent('bumbercar:client:ammoBoxSpawned')
AddEventHandler('bumbercar:client:ammoBoxSpawned', function(boxIndex, position, amount)
    ammoBoxes[boxIndex] = {
        id = boxIndex,
        position = vector3(position.x, position.y, position.z),
        amount = amount,
        active = true
    }

    Utils.Debug('Ammo box spawned at index', boxIndex)
end)

-- 무기/탄약 픽업 감지
Citizen.CreateThread(function()
    while true do
        Wait(200)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING and
           Config.WeaponMode.Enabled then

            local playerCoords = GetEntityCoords(PlayerPedId())

            -- 무기 픽업
            for weaponIndex, weapon in pairs(activeWeapons) do
                if weapon.active then
                    local distance = #(playerCoords - weapon.position)

                    if distance <= Config.WeaponMode.WeaponPickupDistance then
                        -- E 키로 획득
                        if IsControlJustPressed(0, 38) then
                            TriggerServerEvent('bumbercar:server:weaponPickup', weaponIndex)
                            activeWeapons[weaponIndex] = nil
                        end
                    end
                end
            end

            -- 탄약 상자 픽업
            for boxIndex, box in pairs(ammoBoxes) do
                if box.active then
                    local distance = #(playerCoords - box.position)

                    if distance <= Config.WeaponMode.WeaponPickupDistance then
                        -- E 키로 획득
                        if IsControlJustPressed(0, 38) then
                            TriggerServerEvent('bumbercar:server:ammoBoxPickup', boxIndex)
                            ammoBoxes[boxIndex] = nil
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
-- 크로스헤어 및 HUD
-- ============================================

-- 크로스헤어 그리기
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if isAiming and Config.WeaponMode.ShowCrosshair then
            -- 화면 중앙에 크로스헤어
            local screenW, screenH = GetActiveScreenResolution()
            local centerX = screenW / 2.0
            local centerY = screenH / 2.0

            -- 십자가 모양
            DrawRect(0.5, 0.5, 0.002, 0.02, 255, 255, 255, 200)
            DrawRect(0.5, 0.5, 0.02, 0.002, 255, 255, 255, 200)

        else
            Wait(100)
        end
    end
end)

-- 탄약 HUD
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING and
           currentWeapon then

            local weaponData = Config.Weapons[currentWeapon]

            if weaponData and weaponData.ammo ~= -1 then
                -- 화면 우하단에 탄약 표시
                SetTextFont(4)
                SetTextScale(0.5, 0.5)
                SetTextColour(255, 255, 255, 255)
                SetTextOutline()
                SetTextEntry('STRING')
                AddTextComponentString(string.format('탄약: %d', currentAmmo))
                DrawText(0.92, 0.92)
            end

        else
            Wait(100)
        end
    end
end)

-- ============================================
-- 정리
-- ============================================

-- 라운드 종료 시 정리
RegisterNetEvent('bumbercar:client:returnToLobby')
AddEventHandler('bumbercar:client:returnToLobby', function()
    -- 무기 프롭 제거
    if weaponProp and DoesEntityExist(weaponProp) then
        DeleteEntity(weaponProp)
        weaponProp = nil
    end

    -- 상태 리셋
    currentWeapon = nil
    currentAmmo = 0
    isAiming = false
    isFiring = false
    lockOnTarget = nil
    lockOnProgress = 0
    activeWeapons = {}
    ammoBoxes = {}

    -- UI 리셋
    SendNUIMessage({
        type = 'resetWeapon'
    })

    Utils.Debug('Weapon system reset')
end)

-- 리소스 종료 시 정리
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if weaponProp and DoesEntityExist(weaponProp) then
            DeleteEntity(weaponProp)
        end
    end
end)

Utils.Debug('Weapon system loaded')
