local Geom = {}

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function distanceSquared(x1, y1, x2, y2)
    local deltaX = x1 - x2
    local deltaY = y1 - y2
    return deltaX * deltaX + deltaY * deltaY
end

local function distancePointToSegmentSquared(pointX, pointY, segmentStartX, segmentStartY, segmentEndX, segmentEndY)
    local segmentX = segmentEndX - segmentStartX
    local segmentY = segmentEndY - segmentStartY
    local segmentLengthSquared = segmentX * segmentX + segmentY * segmentY
    if segmentLengthSquared <= 0 then
        return distanceSquared(pointX, pointY, segmentStartX, segmentStartY)
    end

    local t = ((pointX - segmentStartX) * segmentX + (pointY - segmentStartY) * segmentY) / segmentLengthSquared
    local clampedT = clamp(t, 0, 1)
    local closestX = segmentStartX + segmentX * clampedT
    local closestY = segmentStartY + segmentY * clampedT
    return distanceSquared(pointX, pointY, closestX, closestY)
end

local function isPointInsidePolygon(pointX, pointY, polygonPoints)
    local count = #polygonPoints
    if count < 6 then return false end

    local inside = false
    local previousIndex = count - 1
    for currentIndex = 1, count, 2 do
        local currentX = polygonPoints[currentIndex]
        local currentY = polygonPoints[currentIndex + 1]
        local previousX = polygonPoints[previousIndex]
        local previousY = polygonPoints[previousIndex + 1]

        local isCrossing = ((currentY > pointY) ~= (previousY > pointY))
        if isCrossing then
            local denominator = previousY - currentY
            if denominator ~= 0 then
                local intersectX = (previousX - currentX) * (pointY - currentY) / denominator + currentX
                if pointX < intersectX then
                    inside = not inside
                end
            end
        end
        previousIndex = currentIndex
    end
    return inside
end

function Geom.circleVsCircle(centerAX, centerAY, radiusA, centerBX, centerBY, radiusB)
    local radiusSum = radiusA + radiusB
    return distanceSquared(centerAX, centerAY, centerBX, centerBY) <= radiusSum * radiusSum
end

function Geom.circleVsAabb(circleX, circleY, circleRadius, minX, minY, maxX, maxY)
    local nearestX = clamp(circleX, minX, maxX)
    local nearestY = clamp(circleY, minY, maxY)
    return distanceSquared(circleX, circleY, nearestX, nearestY) <= circleRadius * circleRadius
end

function Geom.circleVsPolygon(circleX, circleY, circleRadius, polygonPoints)
    if not polygonPoints or #polygonPoints < 6 then
        return false
    end

    if isPointInsidePolygon(circleX, circleY, polygonPoints) then
        return true
    end

    local radiusSquared = circleRadius * circleRadius
    local count = #polygonPoints
    for currentIndex = 1, count, 2 do
        local nextIndex = currentIndex + 2
        if nextIndex > count then
            nextIndex = 1
        end

        local edgeStartX = polygonPoints[currentIndex]
        local edgeStartY = polygonPoints[currentIndex + 1]
        local edgeEndX = polygonPoints[nextIndex]
        local edgeEndY = polygonPoints[nextIndex + 1]

        if distancePointToSegmentSquared(circleX, circleY, edgeStartX, edgeStartY, edgeEndX, edgeEndY) <= radiusSquared then
            return true
        end
    end

    return false
end

return {
    Geom = Geom
}
