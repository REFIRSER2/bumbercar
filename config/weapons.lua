-- 무기 설정
Config.Weapons = {
    -- 기본 무기 (게임 시작 시 장착)
    default_gun = {
        name = '기본 기관총',
        model = 'w_mg_mg',
        icon = '🔫',
        color = '#888888',
        description = '기본 무기',

        -- 무기 스탯
        damage = 20,              -- 데미지
        fireRate = 0.1,           -- 발사 속도 (초당)
        range = 50.0,             -- 사거리
        accuracy = 0.9,           -- 정확도 (0.0 ~ 1.0)
        ammo = -1,                -- 탄약 (-1 = 무한)
        reloadTime = 0,           -- 재장전 시간

        -- 차량 장착 위치 (본넷 기준)
        mountPosition = vector3(0.0, 1.5, 0.3),
        mountRotation = vector3(0.0, 0.0, 0.0),

        -- 발사 설정
        muzzleFlash = true,       -- 총구 화염 효과
        bulletTracer = true,      -- 탄도 표시
        soundEffect = 'WEAPON_MINIGUN_FIRE',

        -- 타겟팅
        autoAim = false,          -- 자동 조준
        aimAssist = true,         -- 조준 보조
        lockOnEnabled = false     -- 락온 가능 여부
    },

    -- 일반 무기들
    machine_gun = {
        name = '기관총',
        model = 'w_mg_mg',
        icon = '🔫',
        color = '#FF6600',
        description = '빠른 연사력의 기관총',

        damage = 25,
        fireRate = 0.08,
        range = 60.0,
        accuracy = 0.85,
        ammo = 200,
        reloadTime = 3.0,

        mountPosition = vector3(0.0, 1.5, 0.3),
        mountRotation = vector3(0.0, 0.0, 0.0),

        muzzleFlash = true,
        bulletTracer = true,
        soundEffect = 'WEAPON_MINIGUN_FIRE',

        autoAim = false,
        aimAssist = true,
        lockOnEnabled = false
    },

    heavy_cannon = {
        name = '중화기',
        model = 'w_lr_firework',
        icon = '💥',
        color = '#FF0000',
        description = '강력한 포탄을 발사하는 중화기',

        damage = 100,
        fireRate = 1.5,
        range = 80.0,
        accuracy = 0.7,
        ammo = 30,
        reloadTime = 4.0,

        mountPosition = vector3(0.0, 1.5, 0.4),
        mountRotation = vector3(0.0, 0.0, 0.0),

        muzzleFlash = true,
        bulletTracer = true,
        soundEffect = 'WEAPON_TANK_FIRE',

        explosionOnHit = true,
        explosionType = 'EXPLOSION_GRENADE',

        autoAim = false,
        aimAssist = true,
        lockOnEnabled = false
    },

    sniper = {
        name = '저격총',
        model = 'w_sr_sniperrifle',
        icon = '🎯',
        color = '#00FF00',
        description = '정확한 원거리 저격',

        damage = 150,
        fireRate = 2.0,
        range = 150.0,
        accuracy = 0.98,
        ammo = 20,
        reloadTime = 3.5,

        mountPosition = vector3(0.0, 1.5, 0.35),
        mountRotation = vector3(0.0, 0.0, 0.0),

        muzzleFlash = true,
        bulletTracer = true,
        soundEffect = 'WEAPON_SNIPER_FIRE',

        scopeZoom = 2.0,          -- 조준경 줌 배율
        autoAim = false,
        aimAssist = false,
        lockOnEnabled = false
    },

    laser_gun = {
        name = '레이저건',
        model = 'w_pi_raygun',
        icon = '⚡',
        color = '#00FFFF',
        description = '빠른 레이저 빔 발사',

        damage = 35,
        fireRate = 0.05,
        range = 70.0,
        accuracy = 0.95,
        ammo = -1,
        reloadTime = 0,

        mountPosition = vector3(0.0, 1.5, 0.3),
        mountRotation = vector3(0.0, 0.0, 0.0),

        muzzleFlash = true,
        bulletTracer = true,
        tracerColor = {r = 0, g = 255, b = 255},
        soundEffect = 'WEAPON_RAYGUN_FIRE',

        autoAim = false,
        aimAssist = true,
        lockOnEnabled = false
    },

    missile_launcher = {
        name = '미사일 발사기',
        model = 'w_lr_rpg',
        icon = '🚀',
        color = '#FF00FF',
        description = '유도 미사일 발사',

        damage = 200,
        fireRate = 3.0,
        range = 100.0,
        accuracy = 0.8,
        ammo = 10,
        reloadTime = 5.0,

        mountPosition = vector3(0.0, 1.5, 0.5),
        mountRotation = vector3(0.0, 0.0, 0.0),

        muzzleFlash = true,
        bulletTracer = false,
        soundEffect = 'WEAPON_RPG_FIRE',

        projectileSpeed = 50.0,
        explosionOnHit = true,
        explosionType = 'EXPLOSION_ROCKET',

        autoAim = false,
        aimAssist = true,
        lockOnEnabled = true,     -- 락온 가능
        lockOnTime = 2.0,         -- 락온 시간 (초)
        lockOnRange = 80.0        -- 락온 거리
    },

    shotgun = {
        name = '산탄총',
        model = 'w_sg_pumpshotgun',
        icon = '💢',
        color = '#FF8800',
        description = '근거리 산탄 공격',

        damage = 30,              -- 펠렛당 데미지
        fireRate = 0.8,
        range = 25.0,
        accuracy = 0.6,
        ammo = 40,
        reloadTime = 4.0,

        mountPosition = vector3(0.0, 1.5, 0.3),
        mountRotation = vector3(0.0, 0.0, 0.0),

        pelletCount = 8,          -- 산탄 개수
        pelletSpread = 5.0,       -- 산탄 분산도

        muzzleFlash = true,
        bulletTracer = false,
        soundEffect = 'WEAPON_SHOTGUN_FIRE',

        autoAim = false,
        aimAssist = true,
        lockOnEnabled = false
    },

    plasma_cannon = {
        name = '플라즈마 캐논',
        model = 'w_lr_firework',
        icon = '⚛️',
        color = '#8800FF',
        description = '고에너지 플라즈마 발사',

        damage = 80,
        fireRate = 1.0,
        range = 65.0,
        accuracy = 0.88,
        ammo = 50,
        reloadTime = 3.0,

        mountPosition = vector3(0.0, 1.5, 0.4),
        mountRotation = vector3(0.0, 0.0, 0.0),

        muzzleFlash = true,
        bulletTracer = true,
        tracerColor = {r = 128, g = 0, b = 255},
        soundEffect = 'WEAPON_SPACE_PISTOL_FIRE',

        explosionOnHit = true,
        explosionType = 'EXPLOSION_STICKYBOMB',
        areaOfEffect = 5.0,       -- 범위 피해

        autoAim = false,
        aimAssist = true,
        lockOnEnabled = false
    }
}

-- 무기 아이템 드랍 확률 (가중치)
Config.WeaponDropWeights = {
    machine_gun = 100,
    heavy_cannon = 60,
    sniper = 50,
    laser_gun = 70,
    missile_launcher = 40,
    shotgun = 80,
    plasma_cannon = 50
}

-- 무기전 설정
Config.WeaponMode = {
    Enabled = true,                -- 무기전 활성화
    DefaultWeapon = 'default_gun', -- 기본 무기
    MaxWeapons = 1,                -- 최대 장착 가능 무기 수

    -- 조준 설정
    AimSensitivity = 1.0,          -- 조준 감도
    AimFOV = 40.0,                 -- 조준 시 FOV
    ShowCrosshair = true,          -- 조준점 표시
    CrosshairColor = {r = 255, g = 255, b = 255, a = 200},

    -- 발사 설정
    LeftClickFire = true,          -- 좌클릭으로 발사
    RightClickAim = true,          -- 우클릭으로 조준
    AutoFire = false,              -- 자동 발사 (버튼 누르고 있으면 계속 발사)

    -- 피격 효과
    HitMarker = true,              -- 히트마커 표시
    HitMarkerSound = true,         -- 히트 사운드
    DamageNumbers = true,          -- 데미지 숫자 표시

    -- 무기 교체
    WeaponPickupDistance = 3.0,    -- 무기 획득 거리
    WeaponDropOnDeath = false,     -- 사망 시 무기 드랍
    ShowWeaponNames = true,        -- 무기 이름 표시

    -- 탄약
    SharedAmmo = false,            -- 무기 간 탄약 공유
    AmmoBoxSpawn = true,           -- 탄약 상자 스폰
    AmmoBoxAmount = 50,            -- 탄약 상자당 탄약량
    AmmoBoxRespawn = 20            -- 탄약 상자 리스폰 시간 (초)
}

-- 게임 모드에 무기전 추가
Constants.GameMode.WEAPON_FFA = 'weapon_ffa'   -- 무기전 개인전
Constants.GameMode.WEAPON_TEAM = 'weapon_team' -- 무기전 팀전
