
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/sector/factionwar/?.lua"

require ("stringutility")
require ("randomext")
require("factionwarutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace TemporaryDefender
TemporaryDefender = {}

if onServer() then

local hitsReceived = {}
local enemiesHaveBeenPresent = false

function TemporaryDefender.initialize()
    Entity():registerCallback("onShieldHit", "onShieldHit")
    Entity():registerCallback("onHullHit", "onHullHit")
end

function TemporaryDefender.getUpdateInterval()
    return random():getFloat(5, 10)
end

function TemporaryDefender.updateServer()
    -- check if there are still any enemies around
    -- if not, jump away
    local ships = {Sector():getEntitiesByComponents(ComponentType.Owner, ComponentType.Plan)}
    local self = Entity()

    local enemiesPresent = false
    for _, ship in pairs(ships) do
        if self.factionIndex ~= ship.factionIndex then
            local faction = Faction(ship.factionIndex)
            if faction and faction:getRelations(self.factionIndex) < -75000 then
                enemiesPresent = true
                enemiesHaveBeenPresent = true
                break
            end
        end
    end

    if not enemiesPresent and enemiesHaveBeenPresent then
        deferredCallback(random():getFloat(1, 5), "jumpAway")
    end
end

function TemporaryDefender.jumpAway()
    Sector():deleteEntityJumped(Entity())
end


function TemporaryDefender.onShieldHit(obj, shooterIndex, damage, location)
    if damage > 0 then
        TemporaryDefender.onShotHit(obj, shooterIndex, location)
    end
end

function TemporaryDefender.onHullHit(obj, block, shooterIndex, damage, location)
    if damage > 0 then
        TemporaryDefender.onShotHit(obj, shooterIndex, location)
    end
end

function TemporaryDefender.onShotHit(obj, shooterIndex, location)

    local shooter = Entity(shooterIndex)
    if not shooter then return end

    local hits = hitsReceived[shooter.factionIndex] or 0
    hits = hits + 1
    hitsReceived[shooter.factionIndex] = hits

    if hits == 10 then
        TemporaryDefender.declareWar(shooter.factionIndex)
    end
end

function TemporaryDefender.declareWar(playerIndex)

    local others = Faction(playerIndex)
    if not others.isPlayer then return end -- TODO: Adjust to alliance

    local player = Player(playerIndex)

    local key, enemy = getFactionWarSideVariableName()
    local side = player:getValue(key)

    if side and side ~= 0 then return end

    -- if the player hasn't yet sided with someone, declare war
    local faction = Faction()
    local relations = faction:getRelations(playerIndex)

    Galaxy():setFactionRelations(faction, player, -100000)
    invokeClientFunction(player, "notifyPlayerOfWarDeclaration")

    -- save that the player sided with the other faction
    player:setValue(key, enemy)

    -- notify ships of the other faction so they can declare peace
    -- we notify them all, just in case that the one we notify might get destroyed
    local others = {Sector():getEntitiesByScript("factionwar/temporarydefender")}
    local self = Entity()
    for _, other in pairs(others) do
        if other.factionIndex ~= self.factionIndex then
            other:invokeFunction("factionwar/temporarydefender", "deferredDeclarePeace", playerIndex)
            otherFactionIndex = other.factionIndex
        end
    end

end

function TemporaryDefender.deferredDeclarePeace(playerIndex)
    deferredCallback(8.0, "declarePeace", playerIndex)
end

function TemporaryDefender.declarePeace(playerIndex)
    local faction = Faction()
    local player = Player(playerIndex)
    local relations = faction:getRelations(playerIndex)

    Galaxy():setFactionRelations(faction, player, 85000)
    invokeClientFunction(player, "notifyPlayerOfPeaceDeclaration")
end

end -- if onServer()

if onClient() then

function TemporaryDefender.notifyPlayerOfPeaceDeclaration()
    local dialog = {
        text = "We thank you for your help! Such heroism will not be forgotten. You can consider us your allies from now on."%_t
    }

    ScriptUI():interactShowDialog(dialog, true)
end

function TemporaryDefender.notifyPlayerOfWarDeclaration()
    local dialog = {
        text = "To the entire fleet: ${name} is attacking us!\n\nClassify these ships as hostile and destroy them along with the others!"%_t % Player()
    }

    ScriptUI():interactShowDialog(dialog, true)
end

end -- if onClient()
