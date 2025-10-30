-- ============================================
-- 범퍼카 경계 시스템 (클라이언트)
-- 경계 체크, 경고 타이머, 시각화
-- ============================================

local boundaryData = nil
local boundaryWarning = false
local boundaryTimer = 0
local boundaryTimerActive = false
local lastBoundaryCheck = 0

-- ============================================
-- 맵 경계 설정
-- ============================================

-- 맵 설정 (경계 포함)
RegisterNetEvent('bumbercar:client:setMap')
AddEventHandler('bumbercar:client:setMap', function(mapId, mapData)
    BumberCar.CurrentMap = mapId

    if mapData and mapData.boundary then
        boundaryData = mapData.boundary
        Utils.Debug('Map boundary set:', mapId, 'Type:', boundaryData.type)
    else
        boundaryData = nil
        Utils.Debug('Map has no boundary data')
    end

    -- UI 업데이트
    SendNUIMessage({
        type = 'setMap',
        data = {
            mapId = mapId,
            mapData = mapData
        }
    })
end)

-- ============================================
-- 경계 체크 함수
-- ============================================

-- 경계 체크 함수 (위치가 경계 안에 있는지)
function CheckBoundary(coords, boundary)
    if not boundary then
        return true
    end

    if boundary.type == Constants.BoundaryType.CIRCLE then
        -- 원형 경계
        local distance = Utils.GetDistance2D(coords, boundary.center)
        return distance <= boundary.radius

    elseif boundary.type == Constants.BoundaryType.RECTANGLE then
        -- 사각형 경계
        return Utils.IsPointInRectangle(coords, boundary.min, boundary.max)
    end

    return true
end

-- ============================================
-- 경계 체크 루프
-- ============================================

-- 경계 체크 메인 루프
Citizen.CreateThread(function()
    while true do
        Wait(Config.Boundary.TickRate * 1000)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING and
           boundaryData then

            local playerPed = PlayerPedId()
            local vehicle = BumberCar.CurrentVehicle

            -- 차량이 있으면 차량 위치, 없으면 플레이어 위치
            local coords
            if vehicle and DoesEntityExist(vehicle) then
                coords = GetEntityCoords(vehicle)
            else
                coords = GetEntityCoords(playerPed)
            end

            -- 경계 체크
            local inBoundary = CheckBoundary(coords, boundaryData)
            BumberCar.InBoundary = inBoundary

            -- 경계 이탈 시
            if not inBoundary and not boundaryWarning then
                boundaryWarning = true
                boundaryTimer = Config.Boundary.WarningTime
                boundaryTimerActive = true

                Utils.Debug('Player left boundary, starting warning timer')

                -- 경고 메시지
                TriggerEvent('bumbercar:client:notify',
                    string.format(Config.Notifications.BoundaryWarning, boundaryTimer),
                    'warning')

                -- UI 타이머 표시
                SendNUIMessage({
                    type = Constants.UIEvent.SHOW_TIMER,
                    data = {
                        timer = boundaryTimer,
                        message = '경계를 벗어났습니다!',
                        color = 'red'
                    }
                })

            -- 경계 복귀 시
            elseif inBoundary and boundaryWarning then
                boundaryWarning = false
                boundaryTimerActive = false
                boundaryTimer = 0

                Utils.Debug('Player returned to boundary')

                -- 경고 해제 메시지
                TriggerEvent('bumbercar:client:notify', '경계로 복귀했습니다', 'success')

                -- UI 타이머 숨기기
                SendNUIMessage({
                    type = Constants.UIEvent.HIDE_TIMER
                })
            end

        else
            -- 게임 중이 아니면 타이머 초기화
            if boundaryTimerActive then
                boundaryWarning = false
                boundaryTimerActive = false
                boundaryTimer = 0

                SendNUIMessage({
                    type = Constants.UIEvent.HIDE_TIMER
                })
            end
        end
    end
end)

-- ============================================
-- 경계 타이머
-- ============================================

-- 경계 타이머 카운트다운
Citizen.CreateThread(function()
    while true do
        Wait(1000)

        if boundaryTimerActive and boundaryTimer > 0 then
            boundaryTimer = boundaryTimer - 1

            Utils.Debug('Boundary timer:', boundaryTimer)

            -- UI 업데이트
            SendNUIMessage({
                type = 'updateTimer',
                data = {
                    timer = boundaryTimer
                }
            })

            -- 경고 사운드 (마지막 5초)
            if boundaryTimer <= 5 and Config.Sounds.Enabled then
                PlaySound(-1, 'COUNTDOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false, 0, true)
            end

            -- 타이머 종료 - 서버에 경계 위반 알림
            if boundaryTimer <= 0 then
                boundaryTimerActive = false
                boundaryWarning = false

                Utils.Debug('Boundary timer expired - notifying server')
                TriggerServerEvent('bumbercar:server:boundaryViolation')

                -- UI 타이머 숨기기
                SendNUIMessage({
                    type = Constants.UIEvent.HIDE_TIMER
                })
            end
        end
    end
end)

-- ============================================
-- 경계 시각화
-- ============================================

-- 경계 시각화 메인 루프
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if Config.Boundary.ShowVisual and
           BumberCar.GameState == Constants.RoundState.PLAYING and
           boundaryData then

            DrawBoundary(boundaryData)
        else
            Wait(500)
        end
    end
end)

-- 경계 그리기 함수
function DrawBoundary(boundary)
    local color = Config.Boundary.VisualColor

    if boundary.type == Constants.BoundaryType.CIRCLE then
        DrawCircleBoundary(boundary, color)
    elseif boundary.type == Constants.BoundaryType.RECTANGLE then
        DrawRectangleBoundary(boundary, color)
    end
end

-- 원형 경계 그리기
function DrawCircleBoundary(boundary, color)
    local center = boundary.center
    local radius = boundary.radius
    local height = Config.Boundary.VisualHeight

    -- 원을 64개의 선분으로 나누어 그리기
    local segments = 64

    for i = 0, segments do
        local angle1 = (i / segments) * math.pi * 2
        local angle2 = ((i + 1) / segments) * math.pi * 2

        local x1 = center.x + math.cos(angle1) * radius
        local y1 = center.y + math.sin(angle1) * radius
        local x2 = center.x + math.cos(angle2) * radius
        local y2 = center.y + math.sin(angle2) * radius

        -- 바닥 라인
        DrawLine(
            x1, y1, center.z,
            x2, y2, center.z,
            color.r, color.g, color.b, color.a
        )

        -- 상단 라인
        DrawLine(
            x1, y1, center.z + height,
            x2, y2, center.z + height,
            color.r, color.g, color.b, color.a
        )

        -- 수직 라인 (8개 간격)
        if i % 8 == 0 then
            DrawLine(
                x1, y1, center.z,
                x1, y1, center.z + height,
                color.r, color.g, color.b, color.a
            )
        end
    end
end

-- 사각형 경계 그리기
function DrawRectangleBoundary(boundary, color)
    local min = boundary.min
    local max = boundary.max
    local height = Config.Boundary.VisualHeight

    -- 모서리 좌표
    local corners = {
        vector3(min.x, min.y, min.z),
        vector3(max.x, min.y, min.z),
        vector3(max.x, max.y, min.z),
        vector3(min.x, max.y, min.z)
    }

    -- 바닥 및 상단 라인
    for i = 1, 4 do
        local c1 = corners[i]
        local c2 = corners[i % 4 + 1]

        -- 바닥 라인
        DrawLine(
            c1.x, c1.y, c1.z,
            c2.x, c2.y, c2.z,
            color.r, color.g, color.b, color.a
        )

        -- 상단 라인
        DrawLine(
            c1.x, c1.y, c1.z + height,
            c2.x, c2.y, c2.z + height,
            color.r, color.g, color.b, color.a
        )
    end

    -- 수직 라인 (모서리)
    for i = 1, 4 do
        local c = corners[i]
        DrawLine(
            c.x, c.y, c.z,
            c.x, c.y, c.z + height,
            color.r, color.g, color.b, color.a
        )
    end
end

-- ============================================
-- 경계 경고 텍스트
-- ============================================

-- 경계 경고 화면 텍스트
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if boundaryWarning and boundaryTimer > 0 then
            -- 화면 상단에 경고 표시
            SetTextFont(4)
            SetTextScale(0.8, 0.8)
            SetTextColour(255, 0, 0, 255)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString(string.format('경계 이탈! %d초 후 폭발!', boundaryTimer))
            DrawText(0.5, 0.1)

            -- 화면 깜빡임 효과 (마지막 3초)
            if boundaryTimer <= 3 then
                local alpha = math.floor(math.abs(math.sin(GetGameTimer() / 200.0)) * 100)
                DrawRect(0.5, 0.5, 1.0, 1.0, 255, 0, 0, alpha)
            elseif boundaryTimer <= 5 then
                -- 마지막 5초 약한 경고
                DrawRect(0.5, 0.5, 1.0, 1.0, 255, 0, 0, 20)
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================
-- 경계 거리 표시 (옵션)
-- ============================================

-- 경계까지의 거리 표시
Citizen.CreateThread(function()
    while true do
        Wait(500)

        if Config.Debug and
           BumberCar.GameState == Constants.RoundState.PLAYING and
           boundaryData then

            local playerPed = PlayerPedId()
            local vehicle = BumberCar.CurrentVehicle

            local coords
            if vehicle and DoesEntityExist(vehicle) then
                coords = GetEntityCoords(vehicle)
            else
                coords = GetEntityCoords(playerPed)
            end

            local distanceToBoundary = 0

            if boundaryData.type == Constants.BoundaryType.CIRCLE then
                local distanceFromCenter = Utils.GetDistance2D(coords, boundaryData.center)
                distanceToBoundary = boundaryData.radius - distanceFromCenter

            elseif boundaryData.type == Constants.BoundaryType.RECTANGLE then
                -- 사각형의 경우 가장 가까운 변까지의 거리 계산
                local min = boundaryData.min
                local max = boundaryData.max

                local dx = math.max(min.x - coords.x, coords.x - max.x, 0)
                local dy = math.max(min.y - coords.y, coords.y - max.y, 0)
                distanceToBoundary = -math.sqrt(dx * dx + dy * dy)

                -- 안에 있으면 양수로 표시
                if CheckBoundary(coords, boundaryData) then
                    distanceToBoundary = math.min(
                        coords.x - min.x,
                        max.x - coords.x,
                        coords.y - min.y,
                        max.y - coords.y
                    )
                end
            end

            -- 디버그 정보
            if distanceToBoundary > 0 then
                Utils.Debug(string.format('Distance to boundary: %.1fm', distanceToBoundary))
            else
                Utils.Debug(string.format('Outside boundary by %.1fm', -distanceToBoundary))
            end
        else
            Wait(2000)
        end
    end
end)

-- ============================================
-- 라운드 종료 시 정리
-- ============================================

-- 라운드 종료 시 경계 데이터 정리
RegisterNetEvent('bumbercar:client:returnToLobby')
AddEventHandler('bumbercar:client:returnToLobby', function()
    -- 경계 데이터 초기화
    boundaryData = nil
    boundaryWarning = false
    boundaryTimer = 0
    boundaryTimerActive = false

    Utils.Debug('Boundary system reset')
end)

Utils.Debug('Boundary system loaded')
