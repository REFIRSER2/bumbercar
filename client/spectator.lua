-- 관전 시스템 (클라이언트)
local spectating = false
local spectateTarget = nil
local spectateTargets = {}
local lastSwitchTime = 0

-- 관전 시작
RegisterNetEvent('bumbercar:client:startSpectating')
AddEventHandler('bumbercar:client:startSpectating', function()
    spectating = true
    BumberCar.PlayerState = Constants.PlayerState.SPECTATING

    -- 관전 대상 목록 업데이트
    UpdateSpectateTargets()

    -- 첫 번째 대상으로 전환
    if #spectateTargets > 0 then
        SwitchSpectateTarget(1)
    end

    -- UI 표시
    SendNUIMessage({
        type = Constants.UIEvent.SHOW_SPECTATOR
    })

    Utils.Debug('Spectating started')
end)

-- 관전 종료
RegisterNetEvent('bumbercar:client:stopSpectating')
AddEventHandler('bumbercar:client:stopSpectating', function()
    spectating = false
    spectateTarget = nil

    -- 카메라 리셋
    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, true, false)
    SetEntityCollision(playerPed, true, true)
    FreezeEntityPosition(playerPed, false)
    NetworkSetInSpectatorMode(false, playerPed)

    -- UI 숨기기
    SendNUIMessage({
        type = Constants.UIEvent.HIDE_SPECTATOR
    })

    Utils.Debug('Spectating stopped')
end)

-- 관전 대상 목록 업데이트
function UpdateSpectateTargets()
    spectateTargets = {}

    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                table.insert(spectateTargets, playerId)
            end
        end
    end
end

-- 관전 대상 전환
function SwitchSpectateTarget(direction)
    if #spectateTargets == 0 then
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

    -- 다음/이전 대상
    local newIndex = currentIndex + direction
    if newIndex > #spectateTargets then
        newIndex = 1
    elseif newIndex < 1 then
        newIndex = #spectateTargets
    end

    spectateTarget = spectateTargets[newIndex]

    -- 관전 모드 활성화
    local targetPed = GetPlayerPed(spectateTarget)
    if DoesEntityExist(targetPed) then
        -- 플레이어 투명하게
        local playerPed = PlayerPedId()
        SetEntityVisible(playerPed, false, false)
        SetEntityCollision(playerPed, false, false)
        FreezeEntityPosition(playerPed, true)

        -- 관전 모드
        NetworkSetInSpectatorMode(true, targetPed)

        -- UI 업데이트
        local targetName = GetPlayerName(spectateTarget)
        SendNUIMessage({
            type = Constants.UIEvent.UPDATE_SPECTATOR,
            targetName = targetName,
            currentIndex = newIndex,
            totalTargets = #spectateTargets
        })

        Utils.Debug('Spectating:', targetName)
    end
end

-- 관전 컨트롤
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if spectating then
            -- 대상 목록 업데이트 (5초마다)
            if GetGameTimer() % 5000 < 50 then
                UpdateSpectateTargets()
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

            -- 현재 대상이 죽었거나 사라진 경우
            if spectateTarget then
                local targetPed = GetPlayerPed(spectateTarget)
                if not DoesEntityExist(targetPed) or IsEntityDead(targetPed) then
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

-- 관전 UI 정보 업데이트
Citizen.CreateThread(function()
    while true do
        Wait(500)

        if spectating and spectateTarget then
            local targetPed = GetPlayerPed(spectateTarget)
            if DoesEntityExist(targetPed) then
                local vehicle = GetVehiclePedIsIn(targetPed, false)
                local health = 0
                local maxHealth = 1000

                if vehicle and vehicle ~= 0 then
                    health = GetVehicleBodyHealth(vehicle)
                    maxHealth = 1000
                end

                -- UI 업데이트
                SendNUIMessage({
                    type = 'updateSpectatorInfo',
                    health = health,
                    maxHealth = maxHealth,
                    speed = vehicle and Utils.GetVehicleSpeedKMH(vehicle) or 0
                })
            end
        end
    end
end)
