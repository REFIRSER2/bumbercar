-- 로비 시스템 (클라이언트)

-- 로비 업데이트
RegisterNetEvent('bumbercar:client:lobbyUpdate')
AddEventHandler('bumbercar:client:lobbyUpdate', function(lobbyData)
    Utils.Debug('Received lobby update with', #lobbyData.players, 'players')
    Utils.Debug('Sending NUI message:', Constants.UIEvent.UPDATE_LOBBY)

    SendNUIMessage({
        type = Constants.UIEvent.UPDATE_LOBBY,
        data = lobbyData
    })

    Utils.Debug('NUI message sent')
end)
