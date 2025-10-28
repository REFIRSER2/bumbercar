-- 로비 시스템 (클라이언트)

-- 로비 업데이트
RegisterNetEvent('bumbercar:client:lobbyUpdate')
AddEventHandler('bumbercar:client:lobbyUpdate', function(lobbyData)
    SendNUIMessage({
        type = Constants.UIEvent.UPDATE_LOBBY,
        data = lobbyData
    })
end)
