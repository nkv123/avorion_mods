package.path = package.path .. ";data/scripts/lib/?.lua"
require ("stringutility")

if onServer() then

package.path = package.path .. ";data/scripts/?.lua"

require ("galaxy")
local AsyncPirateGenerator = require ("asyncpirategenerator")
local AsyncShipGenerator = require ("asyncshipgenerator")
local Rewards = require ("rewards")
local SectorSpecifics = require ("sectorspecifics")

local target = nil
local generated = 0
local rewardsGiven = false
local pirates = {}
local traders = {}
local timeSinceCall = 0
local piratesGenerated = false
local tradersGenerated = false
local allGenerated = false

function getUpdateInterval()
    return 5
end

function secure()
    return {dummy = 1}
end

function restore(data)
    terminate()
end

function initialize(firstInitialization)

    local specs = SectorSpecifics()
    local x, y = Sector():getCoordinates()
    local coords = specs.getShuffledCoordinates(random(), x, y, 7, 12)

    target = nil

    for _, coord in pairs(coords) do

        local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, Server().seed)

        if not regular and not offgrid and not blocked and not home then
            target = {x=coord.x, y=coord.y}
            break
        end
    end

    -- if no empty sector could be found, exit silently
    if not target then
        terminate()
        return
    end


    local player = Player()
    player:registerCallback("onSectorEntered", "onSectorEntered")
    player:registerCallback("onSectorLeft", "onSectorLeft")

    if firstInitialization then
        local messages =
        {
            "Mayday! Mayday! We are under attack by pirates! Our position is \\s(%i:%i), someone help, please!"%_t,
            "Mayday! CHRRK ... under attack CHRRK ... pirates ... CHRRK ... position \\s(%i:%i) ... help!"%_t,
            "Can anybody hear us? We have been ambushed by pirates! Our position is \\s(%i:%i) Help!"%_t,
            "This is a distress call! Our position is \\s(%i:%i) We are under attack by pirates, please help!"%_t,
        }

        player:sendChatMessage("Unknown"%_t, 0, messages[random():getInt(1, #messages)], target.x, target.y)
        player:sendChatMessage("", 3, "You have received a distress signal by an unknown source."%_t)
    end

end

function piratePosition()
    local pos = random():getVector(-1000, 1000)
    return MatrixLookUpPosition(-pos, vec3(0, 1, 0), pos)
end

function updateServer(timeStep)

    local x, y = Sector():getCoordinates()
    if x == target.x and y == target.y then
        if allGenerated then
            updatePresentShips()

            local piratesLeft = tablelength(pirates)
            local tradersLeft = tablelength(traders)

            if not rewardsGiven and piratesLeft == 0 and tradersLeft > 0 then
                rewardsGiven = true

                local traderFaction = Faction(table.first(traders).factionIndex)
                local money = tradersLeft * 2000 * Balancing_GetSectorRichnessFactor(Sector():getCoordinates())

                for _, player in pairs({Sector():getPlayers()}) do
                    Rewards.standard(player, traderFaction, nil, money, 5000, true, true)
                end
            end
        end
    elseif generated == 0 then
        timeSinceCall = timeSinceCall + timeStep

        if timeSinceCall > 10 * 60 then
            terminate()
        end
    end



end

function updatePresentShips()
    for i, pirate in pairs(pirates) do
        if not valid(pirate) then
            pirates[i] = nil
        end
    end

    for i, trader in pairs(traders) do
        if not valid(trader) then
            traders[i] = nil
        end
    end
end

function onSectorLeft(player, x, y)
    -- only react when the player left the correct Sector
    if x ~= target.x or y ~= target.y then return end

    updatePresentShips()

    if tablelength(pirates) == 0 then
        -- all pirates were beaten, delete all traders on leave
        for _, trader in pairs(traders) do
            Sector():deleteEntity(trader)
        end
    end

    if tablelength(pirates) == 0 or tablelength(traders) == 0 then
        terminate()
    end
end

function onSectorEntered(player, x, y)

    if x ~= target.x or y ~= target.y then return end

    generated = 1

    -- spawn 3 ships and 10 pirates
    local faction = Galaxy():getNearestFaction(x, y)
    local volume = Balancing_GetSectorShipVolume(x, y) * 2

    local look = vec3(1, 0, 0)
    local up = vec3(0, 1, 0)

    local onShipsFinished = function (ships)
        for _, ship in pairs(ships) do
            table.insert(traders, ship)
            ShipAI(ship.index):setPassiveShooting(1)
        end

        tradersGenerated = true
        allGenerated = piratesGenerated and tradersGenerated
    end

    local shipGenerator = AsyncShipGenerator(nil, onShipsFinished)

    shipGenerator:startBatch()
    shipGenerator:createFreighterShip(faction, MatrixLookUpPosition(look, up, vec3(100, 50, 50)), volume)
    shipGenerator:createFreighterShip(faction, MatrixLookUpPosition(look, up, vec3(0, -50, 0)), volume)
    shipGenerator:createTradingShip(faction, MatrixLookUpPosition(look, up, vec3(-100, -50, -50)), volume)
    shipGenerator:createFreighterShip(faction, MatrixLookUpPosition(look, up, vec3(-200, 50, -50)), volume)
    shipGenerator:createFreighterShip(faction, MatrixLookUpPosition(look, up, vec3(-300, -50, 50)), volume)
    shipGenerator:endBatch()

    local onPiratesFinished = function (ships)
        for _, ship in pairs(ships) do
            table.insert(pirates, ship)
        end

        piratesGenerated = true
        allGenerated = piratesGenerated and tradersGenerated
    end

    local pirateGenerator = AsyncPirateGenerator(nil, onPiratesFinished)

    pirateGenerator:startBatch()
    pirateGenerator:createMarauder(piratePosition())
    pirateGenerator:createPirate(piratePosition())
    pirateGenerator:createPirate(piratePosition())
    pirateGenerator:createPirate(piratePosition())
    pirateGenerator:createBandit(piratePosition())
    pirateGenerator:createBandit(piratePosition())
    pirateGenerator:createBandit(piratePosition())
    pirateGenerator:createBandit(piratePosition())
    pirateGenerator:createBandit(piratePosition())
    pirateGenerator:endBatch()

end

function sendCoordinates()
    invokeClientFunction(Player(callingPlayer), "receiveCoordinates", target)
end

end

function abandon()
    if onClient() then
        invokeServerFunction("abandon")
        return
    end
    terminate()
end

if onClient() then

function initialize()
    invokeServerFunction("sendCoordinates")
    target = {x=0, y=0}
end

function receiveCoordinates(target_in)
    target = target_in
end

function getMissionBrief()
    return "Distress Signal"%_t
end

function getMissionDescription()
    if not target then return "" end

    return string.format("You received a distress call from an unknown source. Their last reported position was (%i:%i)."%_t, target.x, target.y)
end

function getMissionLocation()
    if not target then return 0, 0 end

    return target.x, target.y
end

end




