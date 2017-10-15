package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require("randomext")
require("stringutility")
require("utility")
local SectorSpecifics = require("sectorspecifics")

local OperationExodus = {}

local points = nil
local targets = nil

function OperationExodus.getFaction()
    local name = "The Haatii"%_T

    local galaxy = Galaxy()
    local faction = galaxy:findFaction(name)
    if faction == nil then
        faction = galaxy:createFaction(name, 180, 0)
    end
    return faction
end

function OperationExodus.tryGenerateBeacon(generator)
    local x, y = generator.coordX, generator.coordY

    if math.random() < 0.33 and length(vec2(x, y)) > 200 then
        OperationExodus.generateBeacon(generator)
    end
end

function OperationExodus.generateBeacon(generator)
    local text, args = OperationExodus.getBeaconText(generator.coordX, generator.coordY)
    local mat = generator:createSmallAsteroidField()
    local beacon = generator:createBeacon(mat, nil, text, args)
    beacon:addScriptOnce("story/exodusbeacon")
end

function OperationExodus.getBeaconText(x, y)
    -- get the nearest point
    local coord, index, useX = OperationExodus.getBeaconData(x, y)

    local text = "This is a message for all participants of Operation Exodus.${remaining}"%_t

    local remaining = ""
    if useX then
        remaining = string.format("\n\n#%i X = %i", index, coord)
    else
        remaining = string.format("\n\n#%i Y = %i", index, coord)
    end

    return text, {remaining = remaining}
end

function OperationExodus.getBeaconData(x, y)
    -- get the nearest point
    local nearest
    local index
    local minDist = math.huge
    for i, point in pairs(OperationExodus.getRendezVousPoints()) do
        local d = length(vec2(point.x - x, point.y - y))
        if d < minDist then
            minDist = d
            nearest = point
            index = i
        end
    end

    local useX = (makeFastHash(x, y, Server().seed.value) % 2 == 0)

    local coord
    if useX then
        coord = nearest.x
    else
        coord = nearest.y
    end

    return coord, index, useX
end


function OperationExodus.getFollowingPoint(x, y)
    local corners = OperationExodus.getCornerPoints()

    -- which corner is nearest?
    local eval = function (e)
        local a = e.x - x
        local b = e.y - y
        return a * a + b * b
    end

    local corner = findMinimum(corners, eval)
    local stepSize = 50

    -- if we can reach the next point within 50 sectors, do so
    local d = length(vec2(corner.x - x, corner.y - y))
    if d < stepSize then
        return {x = corner.x, y = corner.y}
    end

    -- find direction
    local dir = normalize(vec2(corner.x - x, corner.y - y)) * stepSize

    -- do a deterministic random number generation
    local serverSeed = Server().seed
    local hash = makeHash(x, y, corner.x, corner.y, serverSeed.value)
    local specs = SectorSpecifics()

    return specs:findFreeSector(Random(Seed(hash)), math.floor(x + dir.x), math.floor(y + dir.y), 15, 20, serverSeed)
end


-- returns 100 sector coordinates distributed more or less evenly in the galaxy
function OperationExodus.getRendezVousPoints()

    if not points then
        points = {}

        local seed = Server().seed
        local random = Random(seed + 179424673)
        local specs = SectorSpecifics()

        for x = -475, 475, 100 do
            for y = -475, 475, 100 do
                local p = specs:findFreeSector(random, x, y, 0, 50, seed)
                table.insert(points, {x = p.x, y = p.y})
            end
        end

        shuffle(random, points)
    end

    return points
end

-- returns 4 sector coordinates, each in another corner of the galaxy
function OperationExodus.getCornerPoints()

    if not targets then
        targets = {}

        local seed = Server().seed
        local random = Random(Server().seed - 179424673)
        local specs = SectorSpecifics()

        local cornerCenters = {
            {x = -450, y = -450},
            {x = 450, y = -450},
            {x = 450, y = 450},
            {x = -450, y = 450},
        }

        for _, center in pairs(cornerCenters) do

            local p = specs:findFreeSector(random, center.x, center.y, 0, 50, seed)

            local x = math.floor(math.min(500, math.max(-499, p.x)))
            local y = math.floor(math.min(500, math.max(-499, p.y)))

            table.insert(targets, {x = x, y = y})
        end
    end

    return targets
end

return OperationExodus
