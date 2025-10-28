-- 차량 설정
Config.Vehicles = {
    -- 일반 차량 (랜덤 스폰용)
    Regular = {
        {
            model = 'blista',
            name = '블리스타',
            health = 800,
            defense = 80,
            damage = 40,
            speed = 1.0
        },
        {
            model = 'brioso',
            name = '브리오소',
            health = 700,
            defense = 70,
            damage = 35,
            speed = 1.1
        },
        {
            model = 'dilettante',
            name = '딜레탄테',
            health = 750,
            defense = 75,
            damage = 38,
            speed = 1.05
        },
        {
            model = 'issi2',
            name = '이시',
            health = 650,
            defense = 65,
            damage = 32,
            speed = 1.15
        },
        {
            model = 'panto',
            name = '판토',
            health = 600,
            defense = 60,
            damage = 30,
            speed = 1.2
        },
        {
            model = 'prairie',
            name = '프레리',
            health = 850,
            defense = 85,
            damage = 42,
            speed = 0.95
        },
        {
            model = 'rhapsody',
            name = '랩소디',
            health = 720,
            defense = 72,
            damage = 36,
            speed = 1.08
        },
        {
            model = 'sultan',
            name = '술탄',
            health = 900,
            defense = 90,
            damage = 45,
            speed = 1.1
        },
        {
            model = 'futo',
            name = '후토',
            health = 820,
            defense = 82,
            damage = 41,
            speed = 1.05
        },
        {
            model = 'penumbra',
            name = '페넘브라',
            health = 880,
            defense = 88,
            damage = 44,
            speed = 1.0
        },
        {
            model = 'kuruma',
            name = '쿠루마',
            health = 950,
            defense = 95,
            damage = 48,
            speed = 0.98
        },
        {
            model = 'elegy',
            name = '엘레지',
            health = 920,
            defense = 92,
            damage = 46,
            speed = 1.05
        },
        {
            model = 'banshee',
            name = '밴시',
            health = 850,
            defense = 85,
            damage = 50,
            speed = 1.15
        },
        {
            model = 'infernus',
            name = '인페르누스',
            health = 900,
            defense = 90,
            damage = 52,
            speed = 1.2
        },
        {
            model = 'zentorno',
            name = '젠토르노',
            health = 950,
            defense = 95,
            damage = 55,
            speed = 1.18
        },
        {
            model = 'sandking',
            name = '샌드킹',
            health = 1200,
            defense = 120,
            damage = 60,
            speed = 0.85
        },
        {
            model = 'bison',
            name = '바이슨',
            health = 1100,
            defense = 110,
            damage = 55,
            speed = 0.9
        },
        {
            model = 'bobcatxl',
            name = '밥캣',
            health = 1150,
            defense = 115,
            damage = 58,
            speed = 0.88
        }
    },

    -- 보스 전용 차량
    Boss = {
        {
            model = 'rhino',
            name = '라이노 탱크',
            health = 5000,
            defense = 500,
            damage = 200,
            speed = 0.7,
            immovable = true
        },
        {
            model = 'insurgent',
            name = '인서전트',
            health = 4000,
            defense = 400,
            damage = 150,
            speed = 0.85,
            immovable = true
        },
        {
            model = 'nightshark',
            name = '나이트샤크',
            health = 3500,
            defense = 350,
            damage = 130,
            speed = 0.9,
            immovable = true
        },
        {
            model = 'menacer',
            name = '메네이서',
            health = 3800,
            defense = 380,
            damage = 140,
            speed = 0.88,
            immovable = true
        }
    }
}

-- 차량 커스터마이징 설정
Config.VehicleCustomization = {
    RandomColors = true,         -- 랜덤 색상 적용
    MaxUpgrades = true,          -- 최대 업그레이드 적용
    CustomLivery = false,        -- 커스텀 리버리 적용
    Neons = false,               -- 네온 라이트
    Turbo = true,                -- 터보
    XenonLights = false          -- 제논 라이트
}

-- 팀 색상
Config.TeamColors = {
    [Constants.Team.RED] = {
        primary = {r = 27, g = 0, b = 0},    -- 빨강 (인덱스)
        secondary = {r = 27, g = 0, b = 0}
    },
    [Constants.Team.BLUE] = {
        primary = {r = 64, g = 0, b = 0},    -- 파랑 (인덱스)
        secondary = {r = 64, g = 0, b = 0}
    }
}
