-- 팀 시스템 (서버)

-- 팀 배정 (모든 플레이어를 레드/블루 팀으로 균등하게 배분)
function AssignTeams()
    local activePlayers = {}

    -- 관전자를 제외한 활성 플레이어 수집
    for playerId, playerData in pairs(BumberCar.Players) do
        if not playerData.spectating and playerData.state ~= Constants.PlayerState.SPECTATING then
            table.insert(activePlayers, playerId)
        end
    end

    -- 플레이어가 없으면 중단
    if #activePlayers == 0 then
        Utils.Error('No active players to assign teams')
        return
    end

    -- 플레이어 목록 섞기 (공정한 배분을 위해)
    local shuffled = Utils.ShuffleTable(activePlayers)

    -- 절반으로 나누기 (홀수인 경우 레드 팀이 한 명 더 많음)
    local halfSize = math.ceil(#shuffled / 2)

    -- 팀 배정
    for i, playerId in ipairs(shuffled) do
        if i <= halfSize then
            BumberCar.Players[playerId].team = Constants.Team.RED
        else
            BumberCar.Players[playerId].team = Constants.Team.BLUE
        end
    end

    local redCount = halfSize
    local blueCount = #shuffled - halfSize

    Utils.Success('Teams assigned - Red:', redCount, 'Blue:', blueCount)

    -- 팀 배정 알림
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == Constants.Team.RED then
            BumberCar.Notify(playerId, '레드 팀에 배정되었습니다', 'info')
        elseif playerData.team == Constants.Team.BLUE then
            BumberCar.Notify(playerId, '블루 팀에 배정되었습니다', 'info')
        end
    end

    return {red = redCount, blue = blueCount}
end

-- 특정 팀의 모든 플레이어 가져오기
function GetTeamPlayers(team)
    local teamPlayers = {}

    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == team then
            table.insert(teamPlayers, playerId)
        end
    end

    return teamPlayers
end

-- 특정 팀의 살아있는 플레이어 수 가져오기
function GetTeamAliveCount(team)
    local count = 0

    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == team and playerData.state == Constants.PlayerState.PLAYING then
            count = count + 1
        end
    end

    return count
end

-- 팀 재조정 (플레이어 수 차이가 2명 이상일 때)
function RebalanceTeams()
    -- 현재 게임 중이 아니면 재조정 불가
    if BumberCar.GameState ~= Constants.RoundState.PLAYING then
        Utils.Debug('Cannot rebalance teams - not in playing state')
        return false
    end

    local redCount = GetTeamAliveCount(Constants.Team.RED)
    local blueCount = GetTeamAliveCount(Constants.Team.BLUE)

    -- 팀 차이가 2명 미만이면 재조정 불필요
    local difference = math.abs(redCount - blueCount)
    if difference < 2 then
        Utils.Debug('Team balance OK - Red:', redCount, 'Blue:', blueCount)
        return false
    end

    Utils.Debug('Teams unbalanced - Red:', redCount, 'Blue:', blueCount, '- Rebalancing...')

    -- 인원이 많은 팀과 적은 팀 결정
    local moreTeam = redCount > blueCount and Constants.Team.RED or Constants.Team.BLUE
    local lessTeam = redCount > blueCount and Constants.Team.BLUE or Constants.Team.RED

    -- 많은 팀에서 한 명을 적은 팀으로 이동
    local moreTeamPlayers = GetTeamPlayers(moreTeam)
    if #moreTeamPlayers > 0 then
        local playerToMove = moreTeamPlayers[math.random(#moreTeamPlayers)]
        BumberCar.Players[playerToMove].team = lessTeam

        -- 팀 색상 재적용
        TriggerClientEvent('bumbercar:client:setTeamColor', playerToMove, lessTeam)

        local teamName = lessTeam == Constants.Team.RED and '레드' or '블루'
        BumberCar.Notify(playerToMove, string.format('팀 균형을 위해 %s 팀으로 이동되었습니다', teamName), 'info')

        Utils.Success('Player', playerToMove, 'moved to', lessTeam, 'for balance')
        return true
    end

    return false
end

-- 게임 모드가 팀전인지 확인
function IsTeamMode(gameMode)
    return gameMode == Constants.GameMode.ITEM_TEAM or
           gameMode == Constants.GameMode.BOMB_TEAM or
           gameMode == Constants.GameMode.CLASSIC_TEAM or
           gameMode == 'weapon_team'
end

-- 팀 점수 계산 (팀원들의 총 킬 수)
function GetTeamScore(team)
    local score = 0

    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == team then
            score = score + (playerData.stats.kills or 0)
        end
    end

    return score
end

-- 팀 통계 가져오기
function GetTeamStats(team)
    local stats = {
        totalKills = 0,
        totalDeaths = 0,
        totalDamageDealt = 0,
        totalDamageTaken = 0,
        aliveCount = 0,
        totalCount = 0
    }

    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == team then
            stats.totalKills = stats.totalKills + (playerData.stats.kills or 0)
            stats.totalDeaths = stats.totalDeaths + (playerData.stats.deaths or 0)
            stats.totalDamageDealt = stats.totalDamageDealt + (playerData.stats.damageDealt or 0)
            stats.totalDamageTaken = stats.totalDamageTaken + (playerData.stats.damageTaken or 0)
            stats.totalCount = stats.totalCount + 1

            if playerData.state == Constants.PlayerState.PLAYING then
                stats.aliveCount = stats.aliveCount + 1
            end
        end
    end

    return stats
end

-- 승리 팀 결정 (마지막 생존 팀 or 높은 점수 팀)
function GetWinningTeam()
    local redAlive = GetTeamAliveCount(Constants.Team.RED)
    local blueAlive = GetTeamAliveCount(Constants.Team.BLUE)

    -- 생존자 수로 먼저 판단
    if redAlive > 0 and blueAlive == 0 then
        return Constants.Team.RED
    elseif blueAlive > 0 and redAlive == 0 then
        return Constants.Team.BLUE
    end

    -- 둘 다 생존 or 둘 다 전멸이면 점수로 판단
    local redScore = GetTeamScore(Constants.Team.RED)
    local blueScore = GetTeamScore(Constants.Team.BLUE)

    if redScore > blueScore then
        return Constants.Team.RED
    elseif blueScore > redScore then
        return Constants.Team.BLUE
    else
        return nil -- 무승부
    end
end

-- 팀 색상 적용
function ApplyTeamColor(playerId, team)
    if not BumberCar.Players[playerId] then
        Utils.Error('Invalid player for team color:', playerId)
        return
    end

    if team ~= Constants.Team.RED and team ~= Constants.Team.BLUE then
        Utils.Debug('No team color for team:', team)
        return
    end

    -- 클라이언트에 팀 색상 적용 요청
    TriggerClientEvent('bumbercar:client:setTeamColor', playerId, team)
    Utils.Debug('Applied team color to player', playerId, '- Team:', team)
end

-- 모든 팀원에게 팀 색상 적용
function ApplyTeamColors()
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == Constants.Team.RED or playerData.team == Constants.Team.BLUE then
            ApplyTeamColor(playerId, playerData.team)
        end
    end

    Utils.Debug('Applied team colors to all players')
end

-- 팀 채팅
RegisterServerEvent('bumbercar:server:teamChat')
AddEventHandler('bumbercar:server:teamChat', function(message)
    local source = source

    -- 플레이어 유효성 체크
    if not BumberCar.Players[source] then
        Utils.Error('Invalid player sending team chat:', source)
        return
    end

    local senderTeam = BumberCar.Players[source].team
    if senderTeam == Constants.Team.NONE then
        BumberCar.Notify(source, '팀에 속해있지 않습니다', 'error')
        return
    end

    -- 메시지 유효성 체크 및 길이 제한
    if not message or type(message) ~= 'string' or message == '' then
        return
    end

    message = string.sub(message, 1, 100)
    message = message:gsub('[<>]', '') -- XSS 방지

    local senderName = GetPlayerName(source)
    local teamName = senderTeam == Constants.Team.RED and 'RED' or 'BLUE'
    local teamColor = senderTeam == Constants.Team.RED and 'rgba(255, 0, 0, 0.6)' or 'rgba(0, 0, 255, 0.6)'

    -- 같은 팀 플레이어에게만 전송
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == senderTeam then
            TriggerClientEvent('chat:addMessage', playerId, {
                template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: ' .. teamColor .. '; border-radius: 3px;"><b>[TEAM ' .. teamName .. '] {0}:</b> {1}</div>',
                args = {senderName, message}
            })
        end
    end

    Utils.Debug('Team chat from', senderName, '(Team:', teamName, '):', message)
end)

-- 팀 정보 요청
RegisterServerEvent('bumbercar:server:getTeamInfo')
AddEventHandler('bumbercar:server:getTeamInfo', function()
    local source = source

    -- 플레이어 유효성 체크
    if not BumberCar.Players[source] then
        Utils.Error('Invalid player requesting team info:', source)
        return
    end

    local teamInfo = {
        [Constants.Team.RED] = {
            players = {},
            stats = GetTeamStats(Constants.Team.RED)
        },
        [Constants.Team.BLUE] = {
            players = {},
            stats = GetTeamStats(Constants.Team.BLUE)
        }
    }

    -- 각 팀의 플레이어 목록 생성
    for playerId, playerData in pairs(BumberCar.Players) do
        if playerData.team == Constants.Team.RED then
            table.insert(teamInfo[Constants.Team.RED].players, {
                id = playerId,
                name = playerData.name,
                state = playerData.state,
                kills = playerData.stats.kills or 0,
                deaths = playerData.stats.deaths or 0
            })
        elseif playerData.team == Constants.Team.BLUE then
            table.insert(teamInfo[Constants.Team.BLUE].players, {
                id = playerId,
                name = playerData.name,
                state = playerData.state,
                kills = playerData.stats.kills or 0,
                deaths = playerData.stats.deaths or 0
            })
        end
    end

    TriggerClientEvent('bumbercar:client:receiveTeamInfo', source, teamInfo)
    Utils.Debug('Sent team info to player:', source)
end)

-- 플레이어가 떠났을 때 팀 재조정 체크
AddEventHandler('playerDropped', function()
    local source = source

    -- 게임 중이고 팀전이면 재조정 체크
    if BumberCar.GameState == Constants.RoundState.PLAYING and IsTeamMode(BumberCar.CurrentGameMode) then
        Citizen.SetTimeout(1000, function()
            RebalanceTeams()
        end)
    end
end)

-- 함수 export (다른 파일에서 사용 가능하도록)
exports('AssignTeams', AssignTeams)
exports('GetTeamPlayers', GetTeamPlayers)
exports('GetTeamAliveCount', GetTeamAliveCount)
exports('RebalanceTeams', RebalanceTeams)
exports('IsTeamMode', IsTeamMode)
exports('GetTeamScore', GetTeamScore)
exports('GetTeamStats', GetTeamStats)
exports('GetWinningTeam', GetWinningTeam)
exports('ApplyTeamColor', ApplyTeamColor)
exports('ApplyTeamColors', ApplyTeamColors)

Utils.Success('Team system loaded!')
