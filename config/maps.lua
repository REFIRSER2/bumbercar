-- 맵 설정
Config.Maps = {
    -- 맵 1: 비치 아레나
    beach_arena = {
        name = '비치 아레나',
        description = '해변가에 위치한 넓은 아레나',
        icon = '🏖️',
        thumbnail = 'beach_arena.jpg',

        -- 경계 설정 (원형)
        boundary = {
            type = Constants.BoundaryType.CIRCLE,
            center = vector3(-1500.0, -1000.0, 5.0),
            radius = 150.0
        },

        -- 스폰 포인트
        spawnPoints = {
            vector4(-1550.0, -1050.0, 5.0, 0.0),
            vector4(-1450.0, -1050.0, 5.0, 90.0),
            vector4(-1550.0, -950.0, 5.0, 180.0),
            vector4(-1450.0, -950.0, 5.0, 270.0),
            vector4(-1500.0, -1000.0, 5.0, 45.0),
            vector4(-1520.0, -1020.0, 5.0, 135.0),
            vector4(-1480.0, -1020.0, 5.0, 225.0),
            vector4(-1520.0, -980.0, 5.0, 315.0)
        },

        -- 아이템 스폰 위치
        itemSpawns = {
            vector3(-1530.0, -1030.0, 5.0),
            vector3(-1470.0, -1030.0, 5.0),
            vector3(-1530.0, -970.0, 5.0),
            vector3(-1470.0, -970.0, 5.0),
            vector3(-1500.0, -1000.0, 5.0),
            vector3(-1515.0, -1015.0, 5.0),
            vector3(-1485.0, -1015.0, 5.0),
            vector3(-1515.0, -985.0, 5.0),
            vector3(-1485.0, -985.0, 5.0)
        },

        -- 관전 카메라 위치
        spectatorCam = vector3(-1500.0, -1000.0, 80.0)
    },

    -- 맵 2: 도심 주차장
    city_parking = {
        name = '도심 주차장',
        description = '빌딩 숲 사이의 옥상 주차장',
        icon = '🏙️',
        thumbnail = 'city_parking.jpg',

        -- 경계 설정 (사각형)
        boundary = {
            type = Constants.BoundaryType.RECTANGLE,
            min = vector3(-300.0, -800.0, 30.0),
            max = vector3(-100.0, -600.0, 35.0)
        },

        spawnPoints = {
            vector4(-280.0, -780.0, 31.0, 0.0),
            vector4(-220.0, -780.0, 31.0, 0.0),
            vector4(-160.0, -780.0, 31.0, 0.0),
            vector4(-280.0, -720.0, 31.0, 180.0),
            vector4(-220.0, -720.0, 31.0, 180.0),
            vector4(-160.0, -720.0, 31.0, 180.0),
            vector4(-280.0, -660.0, 31.0, 180.0),
            vector4(-220.0, -660.0, 31.0, 180.0),
            vector4(-160.0, -660.0, 31.0, 180.0)
        },

        itemSpawns = {
            vector3(-270.0, -760.0, 31.0),
            vector3(-230.0, -760.0, 31.0),
            vector3(-190.0, -760.0, 31.0),
            vector3(-270.0, -700.0, 31.0),
            vector3(-230.0, -700.0, 31.0),
            vector3(-190.0, -700.0, 31.0),
            vector3(-200.0, -720.0, 31.0),
            vector3(-260.0, -720.0, 31.0)
        },

        spectatorCam = vector3(-200.0, -700.0, 80.0)
    },

    -- 맵 3: 경기장
    stadium = {
        name = '경기장',
        description = '거대한 원형 경기장',
        icon = '🏟️',
        thumbnail = 'stadium.jpg',

        boundary = {
            type = Constants.BoundaryType.CIRCLE,
            center = vector3(-250.0, -2000.0, 30.0),
            radius = 100.0
        },

        spawnPoints = {
            vector4(-250.0, -2080.0, 30.0, 0.0),
            vector4(-320.0, -2040.0, 30.0, 45.0),
            vector4(-320.0, -1960.0, 30.0, 90.0),
            vector4(-250.0, -1920.0, 30.0, 135.0),
            vector4(-180.0, -1960.0, 30.0, 180.0),
            vector4(-180.0, -2040.0, 30.0, 225.0),
            vector4(-280.0, -2000.0, 30.0, 270.0),
            vector4(-220.0, -2000.0, 30.0, 315.0)
        },

        itemSpawns = {
            vector3(-250.0, -2000.0, 30.0),
            vector3(-290.0, -2060.0, 30.0),
            vector3(-310.0, -2000.0, 30.0),
            vector3(-290.0, -1940.0, 30.0),
            vector3(-210.0, -2060.0, 30.0),
            vector3(-190.0, -2000.0, 30.0),
            vector3(-210.0, -1940.0, 30.0),
            vector3(-250.0, -2050.0, 30.0),
            vector3(-250.0, -1950.0, 30.0)
        },

        spectatorCam = vector3(-250.0, -2000.0, 90.0)
    },

    -- 맵 4: 공항 활주로
    airport = {
        name = '공항 활주로',
        description = '넓고 긴 공항 활주로',
        icon = '✈️',
        thumbnail = 'airport.jpg',

        boundary = {
            type = Constants.BoundaryType.RECTANGLE,
            min = vector3(-1300.0, -3000.0, 12.0),
            max = vector3(-900.0, -2600.0, 15.0)
        },

        spawnPoints = {
            vector4(-1250.0, -2950.0, 13.0, 0.0),
            vector4(-1150.0, -2950.0, 13.0, 0.0),
            vector4(-1050.0, -2950.0, 13.0, 0.0),
            vector4(-1250.0, -2850.0, 13.0, 90.0),
            vector4(-1150.0, -2850.0, 13.0, 90.0),
            vector4(-1050.0, -2850.0, 13.0, 90.0),
            vector4(-1250.0, -2750.0, 13.0, 180.0),
            vector4(-1150.0, -2750.0, 13.0, 180.0),
            vector4(-1050.0, -2750.0, 13.0, 180.0),
            vector4(-1250.0, -2650.0, 13.0, 270.0),
            vector4(-1150.0, -2650.0, 13.0, 270.0),
            vector4(-1050.0, -2650.0, 13.0, 270.0)
        },

        itemSpawns = {
            vector3(-1200.0, -2900.0, 13.0),
            vector3(-1100.0, -2900.0, 13.0),
            vector3(-1200.0, -2800.0, 13.0),
            vector3(-1100.0, -2800.0, 13.0),
            vector3(-1200.0, -2700.0, 13.0),
            vector3(-1100.0, -2700.0, 13.0),
            vector3(-1250.0, -2800.0, 13.0),
            vector3(-1050.0, -2800.0, 13.0),
            vector3(-1150.0, -2950.0, 13.0),
            vector3(-1150.0, -2650.0, 13.0)
        },

        spectatorCam = vector3(-1100.0, -2800.0, 100.0)
    },

    -- 맵 5: 산악 도로
    mountain_road = {
        name = '산악 도로',
        description = '구불구불한 산악 도로',
        icon = '⛰️',
        thumbnail = 'mountain.jpg',

        boundary = {
            type = Constants.BoundaryType.CIRCLE,
            center = vector3(2500.0, 3000.0, 50.0),
            radius = 120.0
        },

        spawnPoints = {
            vector4(2550.0, 3050.0, 50.0, 0.0),
            vector4(2450.0, 3050.0, 50.0, 45.0),
            vector4(2450.0, 2950.0, 50.0, 90.0),
            vector4(2550.0, 2950.0, 50.0, 135.0),
            vector4(2500.0, 3000.0, 50.0, 180.0),
            vector4(2520.0, 3020.0, 50.0, 225.0),
            vector4(2480.0, 3020.0, 50.0, 270.0),
            vector4(2520.0, 2980.0, 50.0, 315.0)
        },

        itemSpawns = {
            vector3(2530.0, 3030.0, 50.0),
            vector3(2470.0, 3030.0, 50.0),
            vector3(2530.0, 2970.0, 50.0),
            vector3(2470.0, 2970.0, 50.0),
            vector3(2500.0, 3000.0, 50.0),
            vector3(2550.0, 3000.0, 50.0),
            vector3(2450.0, 3000.0, 50.0),
            vector3(2500.0, 3040.0, 50.0),
            vector3(2500.0, 2960.0, 50.0)
        },

        spectatorCam = vector3(2500.0, 3000.0, 120.0)
    }
}

-- 기본 맵
Config.DefaultMap = 'beach_arena'

-- 맵 투표 설정
Config.MapVoting = {
    Enabled = true,           -- 맵 투표 활성화
    VoteTime = 15,            -- 투표 시간 (초)
    RandomIfTie = true        -- 동점 시 랜덤 선택
}
