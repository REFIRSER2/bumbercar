-- 아이템 설정
Config.ItemList = {
    -- 즉발형 아이템 (획득 즉시 효과 발동)
    repair = {
        name = '수리',
        type = Constants.ItemType.INSTANT,
        effect = Constants.ItemEffect.REPAIR,
        icon = '🔧',
        color = '#00FF00',
        description = '차량을 즉시 수리합니다',
        healAmount = 500, -- 회복량
        maxHealth = true  -- 최대 체력까지 회복
    },

    random_vehicle = {
        name = '차량 변경',
        type = Constants.ItemType.INSTANT,
        effect = Constants.ItemEffect.RANDOM_VEHICLE,
        icon = '🎲',
        color = '#FF00FF',
        description = '랜덤한 차량으로 변경됩니다',
        keepStats = false -- 기존 스탯 유지 여부
    },

    -- 사용형 아이템 (슬롯에 저장 후 키로 사용)
    damage_boost = {
        name = '공격력 증가',
        type = Constants.ItemType.USABLE,
        effect = Constants.ItemEffect.DAMAGE_BOOST,
        icon = '⚔️',
        color = '#FF0000',
        description = '일정 시간 동안 공격력이 증가합니다',
        duration = 15,     -- 지속 시간 (초)
        multiplier = 2.0,  -- 배율
        stackable = false  -- 중첩 가능 여부
    },

    defense_boost = {
        name = '방어력 증가',
        type = Constants.ItemType.USABLE,
        effect = Constants.ItemEffect.DEFENSE_BOOST,
        icon = '🛡️',
        color = '#0000FF',
        description = '일정 시간 동안 방어력이 증가합니다',
        duration = 15,
        multiplier = 2.0,
        stackable = false
    },

    speed_boost = {
        name = '속도 증가',
        type = Constants.ItemType.USABLE,
        effect = Constants.ItemEffect.SPEED_BOOST,
        icon = '⚡',
        color = '#FFFF00',
        description = '일정 시간 동안 속도가 증가합니다',
        duration = 10,
        multiplier = 1.5,
        stackable = false
    },

    boost = {
        name = '부스트',
        type = Constants.ItemType.USABLE,
        effect = Constants.ItemEffect.BOOST,
        icon = '🚀',
        color = '#FF8800',
        description = '순간적으로 강력한 가속을 합니다',
        force = 50.0,      -- 부스트 힘
        duration = 2,      -- 지속 시간 (초)
        cooldown = 5       -- 쿨다운 (초)
    },

    jump = {
        name = '점프',
        type = Constants.ItemType.USABLE,
        effect = Constants.ItemEffect.JUMP,
        icon = '⬆️',
        color = '#00FFFF',
        description = '차량을 높이 점프시킵니다',
        force = 30.0,      -- 점프 힘
        charges = 3,       -- 사용 횟수
        cooldown = 3       -- 쿨다운 (초)
    },

    freeze = {
        name = '정지',
        type = Constants.ItemType.USABLE,
        effect = Constants.ItemEffect.FREEZE,
        icon = '❄️',
        color = '#88FFFF',
        description = '가장 가까운 적을 일시적으로 정지시킵니다',
        duration = 3,      -- 지속 시간 (초)
        range = 15.0,      -- 범위
        cooldown = 10      -- 쿨다운 (초)
    },

    explosion = {
        name = '폭발',
        type = Constants.ItemType.USABLE,
        effect = Constants.ItemEffect.EXPLOSION,
        icon = '💣',
        color = '#FF0000',
        description = '주변에 폭발을 일으킵니다',
        damage = 300,      -- 데미지
        radius = 8.0,      -- 범위
        knockback = 20.0,  -- 넉백
        cooldown = 15      -- 쿨다운 (초)
    }
}

-- 아이템 드랍 확률 (가중치)
Config.ItemDropWeights = {
    -- 즉발형
    repair = 100,
    random_vehicle = 30,

    -- 사용형
    damage_boost = 80,
    defense_boost = 80,
    speed_boost = 80,
    boost = 90,
    jump = 70,
    freeze = 40,
    explosion = 30
}

-- 게임 모드별 아이템 설정
Config.ItemsByGameMode = {
    -- 아이템전 - 모든 아이템 사용
    [Constants.GameMode.ITEM_FFA] = {
        'repair', 'random_vehicle', 'damage_boost', 'defense_boost',
        'speed_boost', 'boost', 'jump', 'freeze', 'explosion'
    },
    [Constants.GameMode.ITEM_TEAM] = {
        'repair', 'random_vehicle', 'damage_boost', 'defense_boost',
        'speed_boost', 'boost', 'jump', 'freeze', 'explosion'
    },

    -- 노아이템전 - 아이템 없음
    [Constants.GameMode.CLASSIC_FFA] = {},
    [Constants.GameMode.CLASSIC_TEAM] = {},

    -- 폭탄 모드 - 기본 아이템만
    [Constants.GameMode.BOMB_FFA] = {
        'repair', 'speed_boost', 'boost', 'jump'
    },
    [Constants.GameMode.BOMB_TEAM] = {
        'repair', 'speed_boost', 'boost', 'jump'
    },

    -- 보스 모드 - 일반 플레이어용 아이템
    [Constants.GameMode.BOSS] = {
        'repair', 'damage_boost', 'speed_boost', 'boost', 'jump'
    }
}

-- 아이템 스폰 설정
Config.ItemSpawn = {
    MinDistance = 10.0,      -- 아이템 간 최소 거리
    MaxActive = 10,          -- 최대 활성 아이템 수
    RespawnTime = 30,        -- 리스폰 시간 (초)
    PickupRadius = 2.5,      -- 획득 범위
    ShowRadius = 50.0,       -- 표시 범위 (3D 텍스트)
    MarkerType = 1,          -- 마커 타입
    MarkerSize = {x = 2.0, y = 2.0, z = 1.0},
    MarkerColor = {r = 255, g = 255, b = 0, a = 150},
    ShowMarker = true,       -- 마커 표시
    ShowText = true,         -- 텍스트 표시
    RotateMarker = true,     -- 마커 회전 효과
    BobMarker = true         -- 마커 상하 움직임
}
