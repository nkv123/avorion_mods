
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
Xsotan = require("story/xsotan")
Placer = require("placer")
Balancing = require("galaxy")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    local d2 = length2(vec2(x, y))

    if d2 < Balancing.BlockRingMin2 then
        return 750
    else
        return 0
    end
end

function SectorTemplate.offgrid(x, y)
    return true
end

-- this function returns whether or not a sector should have space gates
function SectorTemplate.gates(x, y)
    return false
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    math.randomseed(seed);

    local generator = SectorGenerator(x, y)

    local numFields = math.random(2, 5)
    for i = 1, numFields do
        generator:createAsteroidField(0.075);
    end

    for i = 1, 5 - numFields do
        generator:createEmptyAsteroidField();
    end

    local numSmallFields = math.random(8, 15)
    for i = 1, numSmallFields do
        local mat = generator:createSmallAsteroidField()

        if math.random() < 0.2 then generator:createStash(mat) end
    end

    Xsotan.infectAsteroids()

    for i = 1, numFields do
        if math.random() < 0.35 then generator:createBigAsteroid() end
    end

    for i = 1, 5 - numFields do
        if math.random() < 0.5 then generator:createEmptyBigAsteroid(position) end
    end

    local numAsteroids = math.random(0, 2)
    for i = 1, numAsteroids do
        local mat = generator:createAsteroidField()
        local asteroid = generator:createClaimableAsteroid()
        asteroid.position = mat
    end

    for i = 1, math.random(5, 10) do
        Xsotan.createShip(generator:getPositionInSector(), random():getFloat(0.5, 2.0))
    end

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate
