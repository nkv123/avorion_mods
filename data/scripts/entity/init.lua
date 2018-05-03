if not onServer() then return end

local entity = Entity()

if entity:hasComponent(ComponentType.DockingPositions) then
    entity:addScriptOnce("entity/regrowdocks.lua")
end

if entity.allianceOwned then
    entity:addScriptOnce("entity/claimalliance.lua")
end
