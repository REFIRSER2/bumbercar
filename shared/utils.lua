-- 유틸리티 함수들
Utils = {}

-- 두 점 사이의 거리 계산
function Utils.GetDistance(pos1, pos2)
    if type(pos1) == "table" then
        pos1 = vector3(pos1.x or 0, pos1.y or 0, pos1.z or 0)
    end
    if type(pos2) == "table" then
        pos2 = vector3(pos2.x or 0, pos2.y or 0, pos2.z or 0)
    end
    return #(pos1 - pos2)
end

-- 2D 거리 계산 (높이 무시)
function Utils.GetDistance2D(pos1, pos2)
    local p1 = type(pos1) == "table" and vector2(pos1.x or 0, pos1.y or 0) or vector2(pos1.x, pos1.y)
    local p2 = type(pos2) == "table" and vector2(pos2.x or 0, pos2.y or 0) or vector2(pos2.x, pos2.y)
    return #(p1 - p2)
end

-- 테이블 복사
function Utils.DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for k, v in next, original, nil do
            copy[Utils.DeepCopy(k)] = Utils.DeepCopy(v)
        end
        setmetatable(copy, Utils.DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- 테이블에서 랜덤 요소 선택
function Utils.GetRandomElement(tbl)
    if #tbl == 0 then return nil end
    return tbl[math.random(1, #tbl)]
end

-- 테이블 섞기
function Utils.ShuffleTable(tbl)
    local shuffled = Utils.DeepCopy(tbl)
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

-- 테이블에 값이 존재하는지 확인
function Utils.TableContains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- 테이블에서 값 제거
function Utils.RemoveFromTable(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            table.remove(tbl, i)
            return true
        end
    end
    return false
end

-- 점이 원 안에 있는지 확인
function Utils.IsPointInCircle(point, center, radius)
    local distance = Utils.GetDistance2D(point, center)
    return distance <= radius
end

-- 점이 사각형 안에 있는지 확인
function Utils.IsPointInRectangle(point, rectMin, rectMax)
    return point.x >= rectMin.x and point.x <= rectMax.x and
           point.y >= rectMin.y and point.y <= rectMax.y
end

-- 시간 포맷팅 (초 -> MM:SS)
function Utils.FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", mins, secs)
end

-- 숫자를 천 단위로 구분
function Utils.FormatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- 퍼센트 계산
function Utils.GetPercentage(current, max)
    if max == 0 then return 0 end
    return math.floor((current / max) * 100)
end

-- 벡터를 테이블로 변환
function Utils.VectorToTable(vec)
    return {
        x = vec.x,
        y = vec.y,
        z = vec.z
    }
end

-- 테이블을 벡터로 변환
function Utils.TableToVector(tbl)
    return vector3(tbl.x or 0, tbl.y or 0, tbl.z or 0)
end

-- 디버그 출력
function Utils.Debug(...)
    if Config and Config.Debug then
        print('[BumberCar]', ...)
    end
end

-- 에러 출력
function Utils.Error(...)
    print('[BumberCar ERROR]', ...)
end

-- 성공 메시지
function Utils.Success(...)
    print('[BumberCar SUCCESS]', ...)
end

-- 랜덤 스폰 포인트 선택
function Utils.GetRandomSpawnPoint(spawnPoints)
    if not spawnPoints or #spawnPoints == 0 then
        Utils.Error('No spawn points available')
        return nil
    end
    return Utils.GetRandomElement(spawnPoints)
end

-- 차량 속도 계산 (MPH)
function Utils.GetVehicleSpeedMPH(vehicle)
    return GetEntitySpeed(vehicle) * 2.236936
end

-- 차량 속도 계산 (KM/H)
function Utils.GetVehicleSpeedKMH(vehicle)
    return GetEntitySpeed(vehicle) * 3.6
end

-- 충돌 데미지 계산
function Utils.CalculateCollisionDamage(speed, baseDamage, multiplier)
    multiplier = multiplier or 1.0
    -- 속도가 빠를수록 더 많은 데미지
    local speedFactor = (speed / 50.0) -- 50 km/h 기준
    local damage = baseDamage * speedFactor * multiplier
    return math.max(0, math.floor(damage))
end

-- 팀 색상 가져오기
function Utils.GetTeamColor(team)
    if team == Constants.Team.RED then
        return {r = 255, g = 0, b = 0, a = 255}
    elseif team == Constants.Team.BLUE then
        return {r = 0, g = 0, b = 255, a = 255}
    else
        return {r = 255, g = 255, b = 255, a = 255}
    end
end

-- HEX 색상을 RGB로 변환
function Utils.HexToRGB(hex)
    hex = hex:gsub("#", "")
    return {
        r = tonumber("0x"..hex:sub(1,2)),
        g = tonumber("0x"..hex:sub(3,4)),
        b = tonumber("0x"..hex:sub(5,6)),
        a = 255
    }
end
