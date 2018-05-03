package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local Balancing = require ("galaxy")

function qualifiesForPersecution(craft)

    local x, y = Sector():getCoordinates()

    local otherHP = Balancing_GetSectorShipHP(x, y)
    local otherDps = Balancing_GetSectorWeaponDPS(x, y)
    otherDps = otherDps * Balancing_GetEnemySectorTurrets(x, y)
    otherDps = otherDps * Balancing_GetDamageFactor(Server().difficulty)

    local selfDps = craft.firePower
    local selfHP = craft.maxDurability + (craft.shieldMaxDurability or 0)

    local timeAlive = selfHP / otherDps
    local timeToKill = otherHP / selfDps
    if otherDps == 0.0 or selfDps == 0.0 then
        timeAlive = selfHP
        timeToKill = otherHP
    end

    return timeAlive < timeToKill * 0.5
end

function sectorPersecutable(x, y)
    local d2 = x * x + y * y

    local threshold = 400
    local difficulty = GameSettings().difficulty

    if difficulty <= Difficulty.Beginner then
        return false
    elseif difficulty == Difficulty.Easy then
        threshold = 320
    elseif difficulty == Difficulty.Normal then
        threshold = 370
    end

    if d2 > threshold * threshold then
--        print ("too far out")
        return false
    end

    if d2 < Balancing.BlockRingMax * Balancing.BlockRingMax then
--        print ("inside barrier")
        return false
    end

    return true
end

function sectorGetPersecutedCraft()
    local sector = Sector()

    if not sectorPersecutable(sector:getCoordinates()) then
        return
    end

    if (sector:getValue("neutral_zone") or 0) == 1 then
        return
    end

    if sector:getEntitiesByScript("entity/energysuppressor.lua") then
        return
    end

    local persecutors = {Sector():getEntitiesByScript("entity/ai/persecutor.lua")}
    if #persecutors > 0 then
        return
    end

    local craftsByFaction = {}
    for _, craft in pairs({sector:getEntitiesByComponent(ComponentType.Turrets)}) do
        craftsByFaction[craft.factionIndex] = craftsByFaction[craft.factionIndex] or {}
        table.insert(craftsByFaction[craft.factionIndex], craft)
    end

    local atLeastOneStrongEnough = false
    local notStrongEnough = nil
    local server = Server()

    for factionIndex, crafts in pairs(craftsByFaction) do
        local faction = Faction(factionIndex)

        -- only consider players that are online
        local online = false
        local playerOwned = faction.isPlayer or faction.isAlliance

        if faction.isPlayer and server:isOnline(factionIndex) then
            online = true
        else
            if faction.isAlliance then
                local alliance = Alliance(factionIndex)
                local members = {alliance:getMembers()}

                for _, member in pairs(members) do
                    if server:isOnline(member) then
                        online = true
                        break
                    end
                end
            end
        end

        -- if there's at least one craft of a faction that's strong enough, don't attack
        if online or not playerOwned then
            for _, craft in pairs(crafts) do
                if qualifiesForPersecution(craft) then
                    if online and playerOwned then
                        -- only attack ships of online players
                        notStrongEnough = craft
                    end
                else
--                    print ("found at least one craft that's strong enough: " .. craft.typename .. " " .. craft.translatedTitle .. " " .. craft.name)
                    atLeastOneStrongEnough = true
                    break
                end
            end
        end

        if atLeastOneStrongEnough then
            break
        end
    end

    if not atLeastOneStrongEnough then
        return notStrongEnough
    end
end
