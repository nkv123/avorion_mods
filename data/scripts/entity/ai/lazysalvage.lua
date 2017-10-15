
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/LogLevels/scripts/lib/?.lua"

require ("stringutility")
require("PrintLog")
local logLevels = require("LogLevels")
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AILasySalvage
AILasySalvage = {}

local minedWreckage = nil
local minedLoot = nil
local collectCounter = 0

function AILasySalvage.getUpdateInterval()
  return 1
end

-- this function will be executed every frame on the server only
function AILasySalvage.updateServer(timeStep)
  local ship = Entity()
--  print(ship.name .. " is lazy salvaging!!",logLevels.trace)
  if ship.hasPilot or ship:getCrewMembers(CrewProfessionType.Captain) == 0 then
    terminate()
    return
  end

  -- find a wreckage that can be harvested
  AILasySalvage.updateSalvaging(timeStep)
end

-- check the immediate region around the ship for loot that can be collected
-- and if there is some, assign minedLoot
function AILasySalvage.findMinedLoot()
  local loots = {Sector():getEntitiesByType(EntityType.Loot)}
  local ship = Entity()

  minedLoot = nil
  for _, loot in pairs(loots) do
    if loot:isCollectable(ship) and distance2(loot.translationf, ship.translationf) < 150 * 150 then
      minedLoot = loot
      print(ship.name .. " has found loot!!",logLevels.trace)
      break
    end
  end

end

-- check the sector for a wreckage that can be mined
-- if there is one, assign minedwreckage
function AILasySalvage.findMinedWreckage()

--  local radius = 20
  local ship = Entity()
  local sector = Sector()

  minedWreckage = nil

  local mineables = {sector:getEntitiesByComponent(ComponentType.MineableMaterial)}
  local nearest = math.huge

  for _, a in pairs(mineables) do
    if a.type == EntityType.Wreckage then
      local resources = a:getMineableResources()
      if resources ~= nil and resources > 0 then

        local dist = distance2(a.translationf, ship.translationf)
        if dist < nearest then
          nearest = dist
          minedWreckage = a
        end

      end
    end
  end

  if minedWreckage then
    broadcastInvokeClientFunction("setMinedWreckage", minedWreckage.index)
    print(ship.name .. " has found a wreckage!!", logLevels.trace)
  else
    local player = Player(Entity().factionIndex)
    if player then
      local x, y = Sector():getCoordinates()
      local coords = tostring(x) .. ":" .. tostring(y)

      player:sendChatMessage(ship.name or "", ChatMessageType.Error, "Your ship in sector %s can't find any more wreckages."%_T, coords)
      player:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't find any more wreckages in \\s(%s)!"%_T, coords)
    end

    ShipAI(ship.index):setPassive()
    ship:invokeFunction("craftorders.lua", "setAIAction")
    terminate()
  end

end

function AILasySalvage.updateSalvaging(timeStep)

  -- highest priority is wrecking the wreckages
  if not valid(minedWreckage) and not valid(minedLoot) then

    -- first, check if there is a wreckage to mine
    AILasySalvage.findMinedWreckage()

    -- then, if there's no wreckage, check if there is loot to collect
    if not valid(minedWreckage) then
      AILasySalvage.findMinedLoot() 
    end

  end

  local ship = Entity()
  local ai = ShipAI()

  if valid(minedWreckage) then

--    if there is a wreckage to collect, attack it
    if ship.selectedObject == nil
    or ship.selectedObject.index ~= minedWreckage.index
    or ai.state ~= AIState.Attack then

      if ship.numTurrets == 0 then
        local player = Player(Entity().factionIndex)
        if player then
          player:sendChatMessage("Server", ChatMessageType.Error, "Your ship can't salvage without turrets."%_T)
        end
        terminate()
        return
      end

--           ai:setFly(minedWreckage.translationf, 0)
      ai:setAttack(minedWreckage)

    end



  elseif valid(minedLoot) then
-- there is loot to collect, fly there
    collectCounter = collectCounter + timeStep
    if collectCounter > 3 then
      collectCounter = collectCounter - 3
      ai:setFly(minedLoot.translationf, 0)
    end

  end
end

function AILasySalvage.setMinedWreckage(index)
  minedWreckage = Entity(index)
end

---- this function will be executed every frame on the client only
--function updateClient(timeStep)
--
--    if valid(minedWreckage) then
--        drawDebugSphere(minedWreckage:getBoundingSphere(), ColorRGB(1, 0, 0))
--    end
--end
