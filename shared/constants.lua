-- 게임 상수 정의
Constants = {}

-- 라운드 상태
Constants.RoundState = {
    LOBBY = 'lobby',        -- 대기 중
    STARTING = 'starting',  -- 시작 준비
    PREPARE = 'prepare',    -- 게임 시작 전 준비 시간
    PLAYING = 'playing',    -- 게임 진행 중
    ENDING = 'ending'       -- 게임 종료
}

-- 게임 모드
Constants.GameMode = {
    ITEM_FFA = 'item_ffa',           -- 아이템전 개인전
    ITEM_TEAM = 'item_team',         -- 아이템전 팀전
    BOMB_FFA = 'bomb_ffa',           -- 폭탄 건내기 개인전
    BOMB_TEAM = 'bomb_team',         -- 폭탄 건내기 팀전
    CLASSIC_FFA = 'classic_ffa',     -- 노아이템전 개인전
    CLASSIC_TEAM = 'classic_team',   -- 노아이템전 팀전
    BOSS = 'boss'                    -- 보스 모드
}

-- 팀
Constants.Team = {
    NONE = 0,
    RED = 1,
    BLUE = 2
}

-- 아이템 타입
Constants.ItemType = {
    INSTANT = 'instant',    -- 즉발형 (바로 사용)
    USABLE = 'usable'       -- 사용형 (슬롯에 저장)
}

-- 아이템 효과
Constants.ItemEffect = {
    DAMAGE_BOOST = 'damage_boost',       -- 공격력 증가
    DEFENSE_BOOST = 'defense_boost',     -- 방어력 증가
    SPEED_BOOST = 'speed_boost',         -- 속도 증가
    REPAIR = 'repair',                   -- 수리
    RANDOM_VEHICLE = 'random_vehicle',   -- 차량 무작위 변경
    BOOST = 'boost',                     -- 부스트
    JUMP = 'jump',                       -- 점프
    FREEZE = 'freeze',                   -- 상대 정지
    EXPLOSION = 'explosion'              -- 폭발
}

-- 플레이어 상태
Constants.PlayerState = {
    LOBBY = 'lobby',           -- 로비 대기
    READY = 'ready',           -- 준비 완료
    SPECTATING = 'spectating', -- 관전 중
    PLAYING = 'playing',       -- 게임 중
    DEAD = 'dead'              -- 사망
}

-- 경계 타입
Constants.BoundaryType = {
    CIRCLE = 'circle',      -- 원형
    RECTANGLE = 'rectangle' -- 사각형
}

-- UI 이벤트
Constants.UIEvent = {
    SHOW_LOBBY = 'bumbercar:ui:showLobby',
    HIDE_LOBBY = 'bumbercar:ui:hideLobby',
    UPDATE_LOBBY = 'bumbercar:ui:updateLobby',
    SHOW_HUD = 'bumbercar:ui:showHud',
    HIDE_HUD = 'bumbercar:ui:hideHud',
    UPDATE_HUD = 'bumbercar:ui:updateHud',
    SHOW_SPECTATOR = 'bumbercar:ui:showSpectator',
    HIDE_SPECTATOR = 'bumbercar:ui:hideSpectator',
    UPDATE_SPECTATOR = 'bumbercar:ui:updateSpectator',
    SHOW_TIMER = 'bumbercar:ui:showTimer',
    HIDE_TIMER = 'bumbercar:ui:hideTimer',
    SHOW_3D_TEXT = 'bumbercar:ui:show3DText',
    UPDATE_3D_TEXT = 'bumbercar:ui:update3DText',
    REMOVE_3D_TEXT = 'bumbercar:ui:remove3DText'
}

-- 키 바인딩
Constants.Keys = {
    ITEM_SLOT_1 = 47,  -- G
    ITEM_SLOT_2 = 74,  -- H
    SPECTATE_PREV = 24, -- 좌클릭
    SPECTATE_NEXT = 25  -- 우클릭
}

-- 기본 값
Constants.Defaults = {
    LOBBY_MIN_PLAYERS = 2,          -- 최소 플레이어 수
    LOBBY_AUTO_START_TIME = 30,     -- 자동 시작 시간 (초)
    PREPARE_TIME = 5,               -- 준비 시간 (초)
    ROUND_TIME = 300,               -- 라운드 시간 (초)
    ENDING_TIME = 10,               -- 종료 화면 시간 (초)
    BOUNDARY_WARNING_TIME = 5,      -- 경계 이탈 경고 시간 (초)
    ITEM_RESPAWN_TIME = 30,         -- 아이템 리스폰 시간 (초)
    BOMB_EXPLOSION_TIME = 60        -- 폭탄 폭발 시간 (초)
}
