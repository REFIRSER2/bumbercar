-- UI 시스템 (클라이언트)

-- 3D 텍스트 표시
local text3DList = {}

-- 3D 텍스트 추가/업데이트
RegisterNetEvent('bumbercar:client:add3DText')
AddEventHandler('bumbercar:client:add3DText', function(id, text, position, options)
    text3DList[id] = {
        text = text,
        position = position,
        options = options or {}
    }
end)

-- 3D 텍스트 제거
RegisterNetEvent('bumbercar:client:remove3DText')
AddEventHandler('bumbercar:client:remove3DText', function(id)
    text3DList[id] = nil
end)

-- 플레이어 이름 표시
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if Config.UI.ShowPlayerNames and BumberCar.GameState == Constants.RoundState.PLAYING then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            local players = GetActivePlayers()
            for _, playerId in ipairs(players) do
                if playerId ~= PlayerId() then
                    local targetPed = GetPlayerPed(playerId)
                    if DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                        local targetCoords = GetEntityCoords(targetPed)
                        local distance = #(playerCoords - targetCoords)

                        if distance <= Config.UI.NameDistance then
                            local targetName = GetPlayerName(playerId)
                            local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(
                                targetCoords.x,
                                targetCoords.y,
                                targetCoords.z + 1.0
                            )

                            if onScreen then
                                -- NUI로 3D 텍스트 표시
                                SendNUIMessage({
                                    type = 'update3DText',
                                    id = 'player_' .. playerId,
                                    text = targetName,
                                    x = screenX,
                                    y = screenY,
                                    distance = distance
                                })
                            end
                        end
                    end
                end
            end
        else
            Wait(500)
        end
    end
end)

-- HUD 표시/숨기기
RegisterNetEvent('bumbercar:client:toggleHUD')
AddEventHandler('bumbercar:client:toggleHUD', function(show)
    SendNUIMessage({
        type = show and Constants.UIEvent.SHOW_HUD or Constants.UIEvent.HIDE_HUD
    })
end)

-- 미니맵 설정
Citizen.CreateThread(function()
    while true do
        Wait(500)

        if BumberCar.GameState == Constants.RoundState.PLAYING then
            if Config.UI.ShowMinimap then
                DisplayRadar(true)
            else
                DisplayRadar(false)
            end
        else
            DisplayRadar(true)
        end
    end
end)

-- HUD 컴포넌트 숨기기 (게임 진행 중)
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if BumberCar.GameState == Constants.RoundState.PLAYING then
            -- 기본 HUD 숨기기
            HideHudComponentThisFrame(1)  -- Wanted Stars
            HideHudComponentThisFrame(2)  -- Weapon Icon
            HideHudComponentThisFrame(3)  -- Cash
            HideHudComponentThisFrame(4)  -- MP Cash
            HideHudComponentThisFrame(6)  -- Vehicle Name
            HideHudComponentThisFrame(7)  -- Area Name
            HideHudComponentThisFrame(8)  -- Vehicle Class
            HideHudComponentThisFrame(9)  -- Street Name
            HideHudComponentThisFrame(13) -- Cash Change
            HideHudComponentThisFrame(17) -- Save Game
            HideHudComponentThisFrame(20) -- Weapon Stats
        else
            Wait(500)
        end
    end
end)

-- 키 안내 표시
Citizen.CreateThread(function()
    while true do
        Wait(0)

        if BumberCar.GameState == Constants.RoundState.PLAYING and
           BumberCar.PlayerState == Constants.PlayerState.PLAYING then

            -- 아이템 사용 키 안내
            if BumberCar.Items[1] or BumberCar.Items[2] then
                SetTextFont(4)
                SetTextScale(0.35, 0.35)
                SetTextColour(255, 255, 255, 200)
                SetTextOutline()
                SetTextEntry('STRING')

                local helpText = ''
                if BumberCar.Items[1] then
                    helpText = helpText .. '[G] 아이템 1  '
                end
                if BumberCar.Items[2] then
                    helpText = helpText .. '[H] 아이템 2'
                end

                AddTextComponentString(helpText)
                DrawText(0.5, 0.92)
            end

        elseif BumberCar.PlayerState == Constants.PlayerState.SPECTATING then
            -- 관전 키 안내
            SetTextFont(4)
            SetTextScale(0.35, 0.35)
            SetTextColour(255, 255, 255, 200)
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry('STRING')
            AddTextComponentString('[좌클릭] 이전 플레이어  [우클릭] 다음 플레이어')
            DrawText(0.5, 0.92)

        else
            Wait(500)
        end
    end
end)
