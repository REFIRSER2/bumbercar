-- ============================================
-- 범퍼카 관전 시스템 (클라이언트)
-- 관전 카메라, 플레이어 전환, UI
-- ============================================

local spectating = false
local spectateTarget = nil
local spectateTargets = {}
local lastSwitchTime = 0
local spectateCam = nil

-- ============================================
-- 관전 시작/종료
-- ============================================

-- 관전 시작
RegisterNetEvent('bumbercar:client:startSpectating')
AddEventHandler('bumbercar:client:startSpectating', function()
    Utils.Debug('Starting spectate mode')

    spectating = true
    BumberCar.PlayerState = Constants.PlayerState.SPECTATING

    -- 플레이어 숨기기
    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, false, false)
    SetEntityAlpha(playerPed, 0, false)
    SetEntityCollision(playerPed, false, false)
    FreezeEntityPosition(playerPed, true)

    -- 관전 대상 목록 업데이트
    UpdateSpectateTargets()

    -- 첫 번째 대상으로 전환
    if #spectateTargets > 0 then
        SwitchSpectateTarget(1)
    else
        Utils.Debug('No spectate targets available')
    end

    -- UI 표시
    SendNUIMessage({
        type = Constants.UIEvent.SHOW_SPECTATOR,
        data = {
            enabled = Config.Spectator.ShowUI
        }
    })
end)

-- 관전 종료
RegisterNetEvent('bumbercar:client:stopSpectating')
AddEventHandler('bumbercar:client:stopSpectating', function()
    Utils.Debug('Stopping spectate mode')

    spectating = false
    spectateTarget = nil

    -- 카메라 정리
    if spectateCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(spectateCam, false)
        spectateCam = nil
    end

    -- 플레이어 복구
    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, true, false)
    SetEntityAlpha(playerPed, 255, false)
    SetEntityCollision(playerPed, true, true)
    FreezeEntityPosition(playerPed, false)
    NetworkSetInSpectatorMode(false, playerPed)

    -- UI 숨기기
    SendNUIMessage({
        type = Constants.UIEvent.HIDE_SPECTATOR
    })
end)

-- ============================================
-- 관전 대상 관리
-- ============================================

-- 관전 대상 목록 업데이트
function UpdateSpectateTargets()
    spectateTargets = {}

    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)

            -- 살아있는 플레이어만 추가
            if DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                table.insert(spectateTargets, playerId)
            end
        end
    end

    Utils.Debug('Found', #spectateTargets, 'spectate targets')
end

-- 관전 대상 전환
function SwitchSpectateTarget(direction)
    if #spectateTargets == 0 then
        Utils.Debug('No spectate targets available')
        return
    end

    -- 현재 인덱스 찾기
    local currentIndex = 1
    if spectateTarget then
        for i, playerId in ipairs(spectateTargets) do
            if playerId == spectateTarget then
                currentIndex = i
                break
            end
        end
    end

    -- 다음/이전 대상 계산
    local newIndex = currentIndex + direction

    -- 순환 처리
    if newIndex > #spectateTargets then
        newIndex = 1
    elseif newIndex < 1 then
        newIndex = #spectateTargets
    end

    spectateTarget = spectateTargets[newIndex]

    -- 관전 카메라 설정
    AttachToTarget(spectateTarget)

    -- UI 업데이트
    local targetName = GetPlayerName(spectateTarget)
    SendNUIMessage({
        type = Constants.UIEvent.UPDATE_SPECTATOR,
        data = {
            targetName = targetName,
            currentIndex = newIndex,
            totalTargets = #spectateTargets
        }
    })

    Utils.Debug('Switched to target:', targetName, '(', newIndex, '/', #spectateTargets, ')')
end

-- 대상에 카메라 부착
function AttachToTarget(targetPlayerId)
    local targetPed = GetPlayerPed(targetPlayerId)

    if not DoesEntityExist(targetPed) then
        Utils.Debug('Target ped does not exist')
        return
    end

    -- FiveM 내장 관전 모드 사용
    NetworkSetInSpectatorMode(true, targetPed)

    Utils.Debug('Attached to target:', GetPlayerName(targetPlayerId))
end

-- ============================================
-- 관전 컨트롤
-- ============================================

-- 관전 키 입력 처리
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if spectating then
            -- 대상 목록 업데이트 (5초마다)
            local gameTimer = GetGameTimer()
            if gameTimer % 5000 < 50 then
                UpdateSpectateTargets()

                -- 현재 대상이 목록에 없으면 다시 전환
                if spectateTarget then
                    local found = false
                    for _, playerId in ipairs(spectateTargets) do
                        if playerId == spectateTarget then
                            found = true
                            break
                        end
                    end

                    if not found and #spectateTargets > 0 then
                        SwitchSpectateTarget(1)
                    end
                end
            end

            -- 좌클릭: 이전 플레이어
            if IsControlJustPressed(0, Constants.Keys.SPECTATE_PREV) then
                local currentTime = GetGameTimer()
                if (currentTime - lastSwitchTime) > (Config.Spectator.SwitchCooldown * 1000) then
                    SwitchSpectateTarget(-1)
                    lastSwitchTime = currentTime
                end
            end

            -- 우클릭: 다음 플레이어
            if IsControlJustPressed(0, Constants.Keys.SPECTATE_NEXT) then
                local currentTime = GetGameTimer()
                if (currentTime - lastSwitchTime) > (Config.Spectator.SwitchCooldown * 1000) then
                    SwitchSpectateTarget(1)
                    lastSwitchTime = currentTime
                end
            end

            -- 현재 대상이 죽었거나 사라진 경우 체크
            if spectateTarget then
                local targetPed = GetPlayerPed(spectateTarget)
                if not DoesEntityExist(targetPed) or IsEntityDead(targetPed) then
                    Utils.Debug('Spectate target died or disappeared')
                    UpdateSpectateTargets()

                    if #spectateTargets > 0 then
                        SwitchSpectateTarget(1)
                    else
                        spectateTarget = nil
                    end
                end
            end

        else
            Wait(500)
        end
    end
end)

-- ============================================
-- 관전 정보 업데이트
-- ============================================

-- 관전 대상 정보 업데이트 (HUD)
Citizen.CreateThread(function()
    while true do
        Wait(500)

        if spectating and spectateTarget then
            local targetPed = GetPlayerPed(spectateTarget)

            if DoesEntityExist(targetPed) then
                local vehicle = GetVehiclePedIsIn(targetPed, false)
                local health = 0
                local maxHealth = 1000
                local speed = 0

                -- 차량 정보
                if vehicle and vehicle ~= 0 then
                    health = GetVehicleBodyHealth(vehicle)
                    maxHealth = 1000
                    speed = Utils.GetVehicleSpeedKMH(vehicle)
                else
                    -- 플레이어 정보
                    health = GetEntityHealth(targetPed)
                    maxHealth = 200
                end

                -- UI 업데이트
                SendNUIMessage({
                    type = 'updateSpectatorInfo',
                    data = {
                        health = math.floor(health),
                        maxHealth = maxHealth,
                        speed = math.floor(speed),
                        percentage = Utils.GetPercentage(health, maxHealth)
                    }
                })
            end
        else
            Wait(1000)
        end
    end
end)

-- ============================================
-- 자유 카메라 모드 (옵션)
-- ============================================

-- 자유 카메라 (Config.Spectator.FreeCamera가 true일 때)
local freeCameraActive = false
local freeCameraPos = vector3(0, 0, 100)
local freeCameraRot = vector3(0, 0, 0)

-- 자유 카메라 이동
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if spectating and Config.Spectator.FreeCamera and freeCameraActive then
            -- WASD로 이동
            local forward = IsControlPressed(0, 32) -- W
            local backward = IsControlPressed(0, 33) -- S
            local left = IsControlPressed(0, 34) -- A
            local right = IsControlPressed(0, 35) -- D
            local up = IsControlPressed(0, 44) -- Q
            local down = IsControlPressed(0, 38) -- E

            local speed = 1.0
            if IsControlPressed(0, 21) then -- Shift
                speed = 5.0
            end

            -- 이동 처리
            if forward then
                freeCameraPos = freeCameraPos + GetCamForwardVector(spectateCam) * speed
            end
            if backward then
                freeCameraPos = freeCameraPos - GetCamForwardVector(spectateCam) * speed
            end
            if left then
                freeCameraPos = freeCameraPos - GetCamRightVector(spectateCam) * speed
            end
            if right then
                freeCameraPos = freeCameraPos + GetCamRightVector(spectateCam) * speed
            end
            if up then
                freeCameraPos = vector3(freeCameraPos.x, freeCameraPos.y, freeCameraPos.z + speed)
            end
            if down then
                freeCameraPos = vector3(freeCameraPos.x, freeCameraPos.y, freeCameraPos.z - speed)
            end

            -- 카메라 위치 업데이트
            if spectateCam then
                SetCamCoord(spectateCam, freeCameraPos.x, freeCameraPos.y, freeCameraPos.z)
            end

        else
            Wait(100)
        end
    end
end)

-- ============================================
-- 관전 UI 텍스트
-- ============================================

-- 관전 안내 텍스트
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if spectating and Config.Spectator.ShowUI then
            -- 화면 하단에 안내 표시
            SetTextFont(4)
            SetTextScale(0.35, 0.35)
            SetTextColour(255, 255, 255, 200)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString('[좌클릭] 이전 플레이어  [우클릭] 다음 플레이어')
            DrawText(0.5, 0.92)

            -- 관전 중 표시
            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 200, 0, 255)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString('관전 모드')
            DrawText(0.5, 0.05)

            -- 대상 이름
            if spectateTarget then
                local targetName = GetPlayerName(spectateTarget)
                SetTextFont(4)
                SetTextScale(0.4, 0.4)
                SetTextColour(255, 255, 255, 255)
                SetTextOutline()
                SetTextCentre(true)
                SetTextEntry('STRING')
                AddTextComponentString(targetName)
                DrawText(0.5, 0.1)
            end

        else
            Wait(500)
        end
    end
end)

-- ============================================
-- 플레이어 이름 3D 표시
-- ============================================

-- 관전 대상 위에 이름 표시
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if spectating and spectateTarget and Config.Spectator.ShowUI then
            local targetPed = GetPlayerPed(spectateTarget)

            if DoesEntityExist(targetPed) then
                local coords = GetEntityCoords(targetPed)
                local targetName = GetPlayerName(spectateTarget)

                -- 3D 텍스트 표시
                local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(
                    coords.x, coords.y, coords.z + 1.5
                )

                if onScreen then
                    SetTextScale(0.5, 0.5)
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextColour(255, 255, 255, 255)
                    SetTextOutline()
                    SetTextCentre(true)
                    SetTextEntry('STRING')
                    AddTextComponentString(targetName)
                    DrawText(screenX, screenY)
                end
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================
-- 정리
-- ============================================

-- 리소스 종료 시 정리
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if spectating then
            -- 관전 종료
            spectating = false

            if spectateCam then
                RenderScriptCams(false, false, 0, true, true)
                DestroyCam(spectateCam, false)
            end

            -- 플레이어 복구
            local playerPed = PlayerPedId()
            SetEntityVisible(playerPed, true, false)
            SetEntityAlpha(playerPed, 255, false)
            SetEntityCollision(playerPed, true, true)
            FreezeEntityPosition(playerPed, false)
            NetworkSetInSpectatorMode(false, playerPed)
        end
    end
end)

Utils.Debug('Spectator system loaded')
