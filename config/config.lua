-- 기본 설정
Config = {}

-- 디버그 모드
Config.Debug = true

-- 로비 설정
Config.Lobby = {
    MinPlayers = 2,              -- 게임 시작 최소 플레이어 수
    AutoStartTime = 30,          -- 최소 인원 충족 시 자동 시작까지 시간 (초)
    ReadyPercentage = 0.5,       -- 준비 완료 필요 비율 (50%)
    SpawnPoint = vector4(-1044.41, -2749.68, 21.36, 240.0) -- 로비 스폰 위치
}

-- 라운드 설정
Config.Round = {
    PrepareTime = 5,             -- 게임 시작 전 준비 시간 (초)
    RoundTime = 300,             -- 기본 라운드 시간 (초)
    EndingTime = 10,             -- 게임 종료 후 결과 표시 시간 (초)
    RespawnDelay = 3             -- 사망 후 리스폰 대기 시간 (초) - 관전 모드 전환용
}

-- 차량 설정
Config.Vehicle = {
    DefaultHealth = 1000,        -- 기본 차량 체력
    DefaultDefense = 100,        -- 기본 방어력
    DefaultDamage = 50,          -- 기본 공격력
    SpeedDamageMultiplier = 1.5, -- 속도에 따른 데미지 배율
    MinSpeedForDamage = 10,      -- 데미지를 입히는 최소 속도 (km/h)
    CollisionCooldown = 0.5,     -- 충돌 데미지 쿨다운 (초)
    InvincibleOnSpawn = true,    -- 스폰 시 무적
    InvincibleTime = 3           -- 무적 시간 (초)
}

-- 경계 설정
Config.Boundary = {
    WarningTime = 5,             -- 경계 이탈 시 경고 시간 (초)
    TickRate = 0.5,              -- 경계 체크 주기 (초)
    ShowVisual = true,           -- 경계선 시각화 표시
    VisualColor = {r = 255, g = 0, b = 0, a = 100}, -- 경계선 색상
    VisualHeight = 50.0          -- 경계선 높이
}

-- 아이템 설정
Config.Items = {
    Enabled = true,              -- 아이템 시스템 활성화
    RespawnTime = 30,            -- 아이템 리스폰 시간 (초)
    MaxSlots = 2,                -- 최대 아이템 슬롯 수
    PickupDistance = 3.0,        -- 아이템 획득 거리
    ShowNames = true,            -- 아이템 이름 표시
    EffectDuration = 15          -- 기본 버프 효과 지속 시간 (초)
}

-- 폭탄 모드 설정
Config.Bomb = {
    ExplosionTime = 60,          -- 폭탄 폭발 시간 (초)
    TransferCooldown = 1.0,      -- 폭탄 전달 쿨다운 (초)
    WarningTime = 10,            -- 폭발 임박 경고 시간 (초)
    ExplosionRadius = 10.0,      -- 폭발 반경
    ExplosionDamage = 9999       -- 폭발 데미지
}

-- 보스 모드 설정
Config.Boss = {
    BossVehicle = 'rhino',       -- 보스 차량 모델
    BossHealthMultiplier = 5.0,  -- 보스 차량 체력 배율
    BossDamageMultiplier = 2.0,  -- 보스 공격력 배율
    BossImmovable = true,        -- 보스 차량 밀림 방지
    MinPlayers = 3               -- 보스 모드 최소 플레이어 수
}

-- 관전 설정
Config.Spectator = {
    Enabled = true,              -- 관전 모드 활성화
    FreeCamera = false,          -- 자유 시점 활성화 (false = 플레이어 시점만)
    SwitchCooldown = 0.5,        -- 관전 대상 전환 쿨다운 (초)
    ShowUI = true                -- 관전 UI 표시
}

-- UI 설정
Config.UI = {
    ShowPlayerNames = true,      -- 플레이어 이름 표시
    NameDistance = 30.0,         -- 이름 표시 거리
    ShowVehicleStats = true,     -- 차량 스탯 HUD 표시
    ShowMinimap = true,          -- 미니맵 표시
    Language = 'ko'              -- 언어 (ko = 한국어)
}

-- 알림 메시지
Config.Notifications = {
    GameStarting = '게임이 %d초 후 시작됩니다!',
    GameStarted = '게임이 시작되었습니다!',
    PlayerReady = '%s님이 준비 완료했습니다',
    PlayerNotReady = '%s님이 준비를 해제했습니다',
    PlayerDied = '%s님이 탈락했습니다',
    RoundEnded = '라운드가 종료되었습니다',
    Winner = '%s님이 승리했습니다!',
    TeamWinner = '%s 팀이 승리했습니다!',
    BoundaryWarning = '경계를 벗어났습니다! %d초 후 폭발합니다',
    ItemPickup = '%s 아이템을 획득했습니다',
    BombReceived = '폭탄을 받았습니다! 다른 플레이어에게 넘기세요!',
    BombTransferred = '폭탄을 넘겼습니다!'
}

-- 사운드 설정
Config.Sounds = {
    Enabled = true,
    Volume = 0.3,
    Sounds = {
        Collision = 'COLLISION',
        ItemPickup = 'PICK_UP',
        BombTick = 'BOMB_TICK',
        Explosion = 'EXPLOSION',
        Victory = 'VICTORY',
        Countdown = 'COUNTDOWN'
    }
}

-- 관리자 권한
Config.AdminPermissions = {
    'group.admin',
    'bumbercar.admin'
}

-- 커맨드
Config.Commands = {
    OpenLobby = 'bumpercar',     -- 로비 열기
    ForceStart = 'bcstart',      -- 강제 시작 (관리자)
    ForceEnd = 'bcend',          -- 강제 종료 (관리자)
    EditMap = 'bcedit',          -- 맵 편집 (관리자)
    SetGameMode = 'bcmode'       -- 게임 모드 설정 (관리자)
}
