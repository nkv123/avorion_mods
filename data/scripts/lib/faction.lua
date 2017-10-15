package.path = package.path .. ";data/scripts/lib/?.lua"
require("stringutility")

-- this is so the script won't crash when executed in a context where there's no onServer() or onClient() function available -
-- naturally those functions should return false then
if not onServer then onServer = function() return false end end
if not onClient then onClient = function() return false end end

-- number between 0 and 1 as percentage of the actual price
-- usually the price is calculated like this:
-- local price = 1000
-- local priceWithFee = price + price * fee
function GetFee(providingFaction, orderingFaction)

    if orderingFaction.index == providingFaction.index then return 0 end

    local percentage = 0;
    local relation = 0

    if onServer() then
        relation = providingFaction:getRelations(orderingFaction.index)
    else
        local player = Player()
        if providingFaction.index == player.index then
            relation = player:getRelations(orderingFaction.index)
        else
            relation = player:getRelations(providingFaction.index)
        end
    end

    percentage = 0.5 - relation / 200000;

    -- pay extra if relations are not good
    if relation < 0 then
        percentage = percentage * 1.5
    end

    return percentage
end

local overriddenRelationThreshold

function overrideRelationThreshold(threshold)
    overriddenRelationThreshold = threshold
end

function CheckFactionInteraction(playerIndex, relationThreshold, msg)
    local player = Player(playerIndex)

    local craft = player.craft
    local interactor = player
    if craft.factionIndex == player.allianceIndex then
        interactor = player.alliance
    end

    local faction = Faction()

    if overriddenRelationThreshold then relationThreshold = overriddenRelationThreshold end

    local relationLevel = interactor:getRelations(faction.index)

    if relationLevel < relationThreshold then
        return false, msg or "Our records say that we're not allowed to do business with you.\n\nCome back when your relations to our faction are better."%_t
    end

    return true
end

if onServer() then

-- return the interacting faction based on the ship the player is flying, and check if the player has certain permissions
function getInteractingFaction(callingPlayer, ...)
    local player = Player(callingPlayer)
    if not player then return end

    local ship = Entity(player.craftIndex)
    if not ship then return end

    local alliance
    if ship.factionIndex == player.allianceIndex then
        alliance = player.alliance

        local requiredPrivileges = {...}
        for _, privilege in pairs(requiredPrivileges) do
            if not alliance:hasPrivilege(callingPlayer, privilege) then
                player:sendChatMessage("Server"%_t, 1, "You don't have permission to do that in the name of your alliance."%_t)
                return
            end
        end
    end

    local buyer
    if not alliance then
        buyer = player
    else
        buyer = alliance
    end

    return buyer, ship, player, alliance
end

-- return the interacting faction based on a given ship, and if there's a calling player, check for permissions
-- this is used when ai factions should be able to interact as well and when there's not necessarily a calling player
function getInteractingFactionByShip(shipIndex, callingPlayer, ...)

    local ship = Entity(shipIndex)
    if not ship then return end

    local buyer = Faction(ship.factionIndex)
    local alliance
    if buyer.isAlliance then
        alliance = Alliance(buyer.index)
    end

    local player
    if callingPlayer then
        player = Player(callingPlayer)
        if not player then return end

        if player.craftIndex ~= shipIndex then return end

        if ship.factionIndex == player.allianceIndex then
            local requiredPrivileges = {...}
            for _, privilege in pairs(requiredPrivileges) do
                if not alliance:hasPrivilege(callingPlayer, privilege) then
                    player:sendChatMessage("Server"%_t, 1, "You don't have permission to do that in the name of your alliance."%_t)
                    return
                end
            end
        end
    end

    if alliance then
        buyer = alliance
    end

    return buyer, ship, player, alliance
end


-- check if the calling player has permissions to do things with the given entity
function checkEntityInteractionPermissions(craft, ...)

    if not callingPlayer then return end
    if not craft then return end

    local player = Player(callingPlayer)
    if not player then return end

    local alliance
    local owner
    if craft.factionIndex == player.allianceIndex then
        -- if the entity belongs to the player's alliance, then check for any given privileges
        alliance = player.alliance

        local requiredPrivileges = {...}
        for _, privilege in pairs(requiredPrivileges) do
            if not alliance:hasPrivilege(callingPlayer, privilege) then
                player:sendChatMessage("Server"%_t, 1, "You don't have permission to do that in the name of your alliance."%_t)
                return
            end
        end

        owner = alliance

    elseif craft.factionIndex == callingPlayer then
        -- players can do whatever they want with their own entities
        owner = player
    else
        player:sendChatMessage("Server"%_t, 1, "You don't have permission to do that."%_t)
        return
    end

    return owner, craft, player, alliance

end

end


if onClient() then

-- check if the calling player has permissions to do things with the given entity
function checkEntityInteractionPermissions(craft, ...)

    if not craft then return end

    local player = Player()
    if not player then return end

    local alliance
    local owner
    if craft.factionIndex == player.allianceIndex then
        -- if the entity belongs to the player's alliance, then check for any given privileges
        alliance = player.alliance

        local requiredPrivileges = {...}
        for _, privilege in pairs(requiredPrivileges) do
            if not alliance:hasPrivilege(player.index, privilege) then
                return
            end
        end

        owner = alliance

    elseif craft.factionIndex == player.index then
        -- players can do whatever they want with their own entities
        owner = player
    else
        return
    end

    return owner, craft, player, alliance

end

end


