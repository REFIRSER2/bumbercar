-- 팀 시스템 (서버)

-- 팀 채팅
RegisterServerEvent('bumbercar:server:teamChat')
AddEventHandler('bumbercar:server:teamChat', function(message)
    local source = source
    if not BumberCar.Players[source] then return end

    local senderTeam = BumberCar.Players[source].team
    if senderTeam == Constants.Team.NONE then return end

    local senderName = GetPlayerName(source)

    -- 같은 팀 플레이어에게만 전송
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == senderTeam then
            TriggerClientEvent('chat:addMessage', playerId, {
                template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 100, 200, 0.6); border-radius: 3px;"><b>[TEAM] {0}:</b> {1}</div>',
                args = {senderName, message}
            })
        end
    end
end)

-- 팀 정보 가져오기
RegisterServerEvent('bumbercar:server:getTeamInfo')
AddEventHandler('bumbercar:server:getTeamInfo', function()
    local source = source

    local teamInfo = {
        [Constants.Team.RED] = {},
        [Constants.Team.BLUE] = {}
    }

    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == Constants.Team.RED then
            table.insert(teamInfo[Constants.Team.RED], {
                id = playerId,
                name = playerData.name,
                state = playerData.state
            })
        elseif playerData.team == Constants.Team.BLUE then
            table.insert(teamInfo[Constants.Team.BLUE], {
                id = playerId,
                name = playerData.name,
                state = playerData.state
            })
        end
    end

    TriggerClientEvent('bumbercar:client:receiveTeamInfo', source, teamInfo)
end)

-- 팀 점수 계산
function GetTeamScore(team)
    local score = 0
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == team then
            score = score + playerData.stats.kills
        end
    end
    return score
end

-- 팀 생존자 수
function GetTeamAliveCount(team)
    local count = 0
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == team and playerData.state == Constants.PlayerState.PLAYING then
            count = count + 1
        end
    end
    return count
end
