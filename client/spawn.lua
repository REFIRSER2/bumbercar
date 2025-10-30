-- 스폰 관리 시스템 (basic-gamemode 없이 작동)
local hasSpawned = false

-- 플레이어 첫 스폰
AddEventHandler('playerSpawned', function()
    if not hasSpawned then
        hasSpawned = true
        Utils.Debug('Player spawned for the first time')

        -- 초기 스폰 처리
        Citizen.CreateThread(function()
            Citizen.Wait(1000)

            -- 기본 플레이어 모델 로드
            local playerPed = PlayerPedId()
            local model = GetHashKey('mp_m_freemode_01')

            RequestModel(model)
            while not HasModelLoaded(model) do
                Citizen.Wait(10)
            end

            -- 모델 설정
            SetPlayerModel(PlayerId(), model)
            SetModelAsNoLongerNeeded(model)

            -- 기본 설정
            local newPed = PlayerPedId()
            SetPedDefaultComponentVariation(newPed)
            SetEntityHealth(newPed, 200)

            -- 로비 위치로 텔레포트
            local lobbySpawn = Config.Lobby.SpawnPoint
            SetEntityCoords(newPed, lobbySpawn.x, lobbySpawn.y, lobbySpawn.z, false, false, false, true)
            SetEntityHeading(newPed, lobbySpawn.w)

            -- 무기 제거
            RemoveAllPedWeapons(newPed, true)

            Utils.Debug('Initial spawn completed')
        end)
    end
end)

-- 네트워크 시작 시 강제 스폰
Citizen.CreateThread(function()
    -- 네트워크 준비 대기
    while not NetworkIsSessionStarted() do
        Citizen.Wait(100)
    end

    -- 약간 대기 후 스폰 트리거
    Citizen.Wait(2000)

    if not hasSpawned then
        Utils.Debug('Forcing player spawn')

        -- 스폰 강제 트리거
        local playerPed = PlayerPedId()

        if not DoesEntityExist(playerPed) or IsEntityDead(playerPed) then
            -- 플레이어 생성
            local model = GetHashKey('mp_m_freemode_01')
            RequestModel(model)
            while not HasModelLoaded(model) do
                Citizen.Wait(10)
            end

            SetPlayerModel(PlayerId(), model)
            SetModelAsNoLongerNeeded(model)
        end

        -- 위치 설정
        local newPed = PlayerPedId()
        local lobbySpawn = Config.Lobby.SpawnPoint

        SetEntityCoords(newPed, lobbySpawn.x, lobbySpawn.y, lobbySpawn.z, false, false, false, true)
        SetEntityHeading(newPed, lobbySpawn.w)
        SetEntityHealth(newPed, 200)
        SetPedDefaultComponentVariation(newPed)
        RemoveAllPedWeapons(newPed, true)

        -- 무적 해제
        SetEntityInvincible(newPed, false)

        -- 스폰 완료 플래그
        hasSpawned = true

        -- 네트워크에 스폰 알림
        NetworkResurrectLocalPlayer(lobbySpawn.x, lobbySpawn.y, lobbySpawn.z, lobbySpawn.w, true, false)

        Utils.Debug('Manual spawn completed')

        -- playerSpawned 이벤트 트리거
        TriggerEvent('playerSpawned')
    end
end)

-- 사망 시 리스폰
AddEventHandler('baseevents:onPlayerDied', function()
    Utils.Debug('Player died, preparing respawn')
end)

AddEventHandler('baseevents:onPlayerKilled', function(killerId, deathData)
    Utils.Debug('Player killed, preparing respawn')
end)

-- 리소스 재시작 시 리셋
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        hasSpawned = false
    end
end)
