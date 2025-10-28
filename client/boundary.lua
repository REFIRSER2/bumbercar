-- 경계 시스템 (클라이언트)
local boundaryWarning = false
local boundaryTimer = 0
local boundaryTimerActive = false

-- 경계 체크 루프
Citizen.CreateThread(function()
    while true do
        Wait(Config.Boundary.TickRate * 1000)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING and
           BumberCar.CurrentMap then

            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local map = Config.Maps[BumberCar.CurrentMap]

            if map and map.boundary then
                local inBoundary = CheckBoundary(coords, map.boundary)

                -- 경계 이탈
                if not inBoundary and not boundaryWarning then
                    boundaryWarning = true
                    boundaryTimer = Config.Boundary.WarningTime
                    boundaryTimerActive = true

                    -- 경고 메시지
                    TriggerEvent('bumbercar:client:notify',
                        string.format(Config.Notifications.BoundaryWarning, boundaryTimer),
                        'warning')

                    -- UI 타이머 표시
                    SendNUIMessage({
                        type = Constants.UIEvent.SHOW_TIMER,
                        timer = boundaryTimer,
                        message = '경계를 벗어났습니다!'
                    })

                -- 경계 복귀
                elseif inBoundary and boundaryWarning then
                    boundaryWarning = false
                    boundaryTimerActive = false
                    boundaryTimer = 0

                    -- UI 타이머 숨기기
                    SendNUIMessage({
                        type = Constants.UIEvent.HIDE_TIMER
                    })
                end

                BumberCar.InBoundary = inBoundary
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

-- 경계 타이머
Citizen.CreateThread(function()
    while true do
        Wait(1000)

        if boundaryTimerActive and boundaryTimer > 0 then
            boundaryTimer = boundaryTimer - 1

            -- UI 업데이트
            SendNUIMessage({
                type = 'updateTimer',
                timer = boundaryTimer
            })

            -- 타이머 종료
            if boundaryTimer <= 0 then
                boundaryTimerActive = false
                TriggerServerEvent('bumbercar:server:boundaryDeath')
            end
        end
    end
end)

-- 경계 체크 함수
function CheckBoundary(coords, boundary)
    if boundary.type == Constants.BoundaryType.CIRCLE then
        return Utils.IsPointInCircle(coords, boundary.center, boundary.radius)
    elseif boundary.type == Constants.BoundaryType.RECTANGLE then
        return Utils.IsPointInRectangle(coords, boundary.min, boundary.max)
    end
    return true
end

-- 경계 시각화
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if Config.Boundary.ShowVisual and
           BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.CurrentMap then

            local map = Config.Maps[BumberCar.CurrentMap]
            if map and map.boundary then
                DrawBoundary(map.boundary)
            end
        else
            Wait(500)
        end
    end
end)

-- 경계 그리기
function DrawBoundary(boundary)
    local color = Config.Boundary.VisualColor

    if boundary.type == Constants.BoundaryType.CIRCLE then
        -- 원형 경계
        local center = boundary.center
        local radius = boundary.radius
        local height = Config.Boundary.VisualHeight

        -- 원을 여러 선분으로 나누어 그리기
        local segments = 64
        for i = 0, segments do
            local angle1 = (i / segments) * math.pi * 2
            local angle2 = ((i + 1) / segments) * math.pi * 2

            local x1 = center.x + math.cos(angle1) * radius
            local y1 = center.y + math.sin(angle1) * radius
            local x2 = center.x + math.cos(angle2) * radius
            local y2 = center.y + math.sin(angle2) * radius

            -- 바닥에서 위로 선 그리기
            DrawLine(x1, y1, center.z, x2, y2, center.z, color.r, color.g, color.b, color.a)
            DrawLine(x1, y1, center.z + height, x2, y2, center.z + height, color.r, color.g, color.b, color.a)

            -- 수직선 (간격 두고)
            if i % 4 == 0 then
                DrawLine(x1, y1, center.z, x1, y1, center.z + height, color.r, color.g, color.b, color.a)
            end
        end

    elseif boundary.type == Constants.BoundaryType.RECTANGLE then
        -- 사각형 경계
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

        -- 바닥 라인
        for i = 1, 4 do
            local c1 = corners[i]
            local c2 = corners[i % 4 + 1]
            DrawLine(c1.x, c1.y, c1.z, c2.x, c2.y, c2.z, color.r, color.g, color.b, color.a)
            DrawLine(c1.x, c1.y, c1.z + height, c2.x, c2.y, c2.z + height, color.r, color.g, color.b, color.a)
        end

        -- 수직선
        for i = 1, 4 do
            local c = corners[i]
            DrawLine(c.x, c.y, c.z, c.x, c.y, c.z + height, color.r, color.g, color.b, color.a)
        end
    end
end

-- 경계 외부 경고 텍스트
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
            DrawText(0.5, 0.05)

            -- 화면 깜빡임 효과
            if boundaryTimer <= 3 then
                DrawRect(0.5, 0.5, 1.0, 1.0, 255, 0, 0, 30)
            end
        else
            Wait(500)
        end
    end
end)
