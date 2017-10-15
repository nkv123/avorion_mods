package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

SectorGenerator = require ("SectorGenerator")
NamePool = require ("namepool")
Placer = require("placer")
Smuggler = require("story/smuggler")
require("stringutility")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return 350
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

    local language = Language(Seed(makeFastHash(seed.value, x, y)))
    local factionName = language:getFactionName()

    local faction = Galaxy():findFaction(factionName)
    if not faction then
        faction = Galaxy():createFaction(factionName, x, y)
    end

    local station = generator:createStation(faction, "merchants/smugglersmarket")
    station.title = "Smuggler Hideout"%_t
    station:addScript("merchants/tradingpost")
    NamePool.setStationName(station)

    -- create ships
    local defenders = math.random(0, 2)
    for i = 1, defenders do
        local ship = ShipGenerator.createDefender(faction, generator:getPositionInSector())
        ship:removeScript("antismuggle.lua")
    end

    -- create some asteroids
    local numFields = math.random(3, 4)
    for i = 1, numFields do
        local mat = generator:createAsteroidField();
        if math.random() < 0.15 then generator:createStash(mat) end
    end

    local numAsteroids = math.random(0, 2)
    for i = 1, numAsteroids do
        generator:createBigAsteroid();
    end

    local numSmallFields = math.random(2, 5)
    for i = 1, numSmallFields do
        generator:createSmallAsteroidField()
    end

    if SectorTemplate.gates(x, y) then generator:createGates() end

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()

    -- create a shady representative
    local ship = Smuggler.spawnRepresentative(station)

    Sector():addScript("data/scripts/sector/respawnresourceasteroids.lua")

    Placer.resolveIntersections()
end


return SectorTemplate
