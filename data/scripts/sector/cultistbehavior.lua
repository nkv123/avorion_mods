if onServer() then

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"
package.path = package.path .. ";?"

require ("galaxy")
require ("randomext")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace CultistBehavior
CultistBehavior = {}


function CultistBehavior.getUpdateInterval()
    return 15
end

function CultistBehavior.secure()
    return
    {
        center = CultistBehavior.center,
        asteroidID = CultistBehavior.asteroidID,
        cultists = CultistBehavior.cultists,
        isAggressive = CultistBehavior.isAggressive
    }
end

function CultistBehavior.restore(data)
    CultistBehavior.center = data.center
    CultistBehavior.asteroidID = data.asteroidID
    CultistBehavior.cultists = data.cultists
    CultistBehavior.isAggressive = data.isAggressive

    CultistBehavior.setInitialCallbacks()
end

function CultistBehavior.initialize(matrix, asteroidID, ...)
    if asteroidID then
        CultistBehavior.center = {x = matrix.pos.x, y = matrix.pos.y, z = matrix.pos.z}
        CultistBehavior.asteroidID = asteroidID
        CultistBehavior.isAggressive = false

        CultistBehavior.cultists = {}
        for _, id in pairs({...}) do
            CultistBehavior.cultists[id] = true
        end

        CultistBehavior.setInitialCallbacks()
    end
end

function CultistBehavior.setInitialCallbacks()
    if not CultistBehavior.isAggressive then
        local sector = Sector()

        local asteroid = sector:getEntity(Uuid(CultistBehavior.asteroidID))
        if asteroid then
            asteroid:registerCallback("onShotHit", "onAsteroidHit")
        end

        for id, _ in pairs(CultistBehavior.cultists) do
            local ship = sector:getEntity(Uuid(id))
            if ship then
                ship:registerCallback("onShotHit", "onCultistHit")
            end

            local ai = ShipAI(Uuid(id))
            if ai then
                ai:setPassiveShooting(false)
            end
        end
    end
end

function CultistBehavior.update(timeStep)
    local cultistFaction
    for id, _ in pairs(CultistBehavior.cultists) do
        local cultist = Entity(Uuid(id))
        if cultist then
            cultistFaction = cultist.factionIndex
        else
            CultistBehavior.cultists[id] = nil
        end
    end

    if tablelength(CultistBehavior.cultists) == 0 then
        terminate()
        return
    end

    if CultistBehavior.isAggressive then
        local sector = Sector()
        local ships = {sector:getEntitiesByType(EntityType.Ship)}

        local enemiesPresent = false
        for _, ship in pairs(ships) do
            if Faction(ship.factionIndex):getRelations(cultistFaction) < -40000 then -- TODO
                enemiesPresent = true
                break
            end
        end

        if not enemiesPresent then
            CultistBehavior.setNormal()
        end
    end
end

function CultistBehavior.onAsteroidHit(objectIndex, shooterIndex)
    CultistBehavior.setAggressive(Entity(Uuid(shooterIndex)))
end

function CultistBehavior.onCultistHit(objectIndex, shooterIndex)
    CultistBehavior.setAggressive(Entity(Uuid(shooterIndex)))
end

function CultistBehavior.setAggressive(shooterEntity)
    CultistBehavior.isAggressive = true

    local sector = Sector()
    local asteroid = sector:getEntity(Uuid(CultistBehavior.asteroidID))
    if asteroid then
        asteroid:unregisterCallback("onShotHit", "onAsteroidHit")
    end

    local shooterFaction, cultistFaction
    if shooterEntity then
        shooterFaction = shooterEntity.factionIndex
    end

    for id, _ in pairs(CultistBehavior.cultists) do
        local cultist = sector:getEntity(Uuid(id))
        if cultist then
            cultistFaction = cultist.factionIndex
            cultist:unregisterCallback("onShotHit", "onCultistHit")
        end

        local ai = ShipAI(Uuid(id))
        if ai then
            ai:setAggressive()
            --if shooterFaction and shooterFaction ~= cultistFaction then
                --print("register enemy")
                --ai:registerEnemyFaction(shooterFaction)
            --end
        end
    end

    if shooterFaction and shooterFaction ~= cultistFaction then
        local currentRelations = Faction(cultistFaction):getRelations(shooterFaction)
        if currentRelations >= -40000 then -- TODO
            Galaxy():setFactionRelations(Faction(cultistFaction), Faction(shooterFaction), -75000)
        end
    end
end

function CultistBehavior.setNormal()
    CultistBehavior.isAggressive = false

    local sector = Sector()

    local asteroid = sector:getEntity(Uuid(CultistBehavior.asteroidID))
    if asteroid then
        asteroid:registerCallback("onShotHit", "onAsteroidHit")
    end

    local cultistCount = tablelength(CultistBehavior.cultists)
    local cultistRadius = getFloat(200, 600)
    local i = 1

    for id, _ in pairs(CultistBehavior.cultists) do
        local cultist = sector:getEntity(Uuid(id))
        if cultist then
            cultist:registerCallback("onShotHit", "onCultistHit")
        end

        -- return back into circle formation
        local ai = ShipAI(Uuid(id))
        if ai then
            local angle = 2 * math.pi * i / cultistCount
            local cultistLook = vec3(math.cos(angle), math.sin(angle), 0)
            local pos = vec3(CultistBehavior.center.x, CultistBehavior.center.y, CultistBehavior.center.z)
            ai:setFly(pos + cultistLook * cultistRadius, 0)
        end

        i = i + 1
    end
end

end
