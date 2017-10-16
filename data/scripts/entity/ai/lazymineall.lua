package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/LogLevels/scripts/lib/?.lua"
require ("stringutility")
require ("PrintLog")
local logLevels = require("LogLevels")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AILazyMineAll
AILazyMineAll = {}

local minedAsteroid = nil
local minedLoot = nil
local collectCounter = 0

function AILazyMineAll.getUpdateInterval()
  return 0.25
end

-- this function will be executed every frame on the server only
function AILazyMineAll.updateServer(timeStep)
  local ship = Entity()
--  print(ship.name .. " is lazy mining!!",logLevels.trace)

  if ship.hasPilot or ship:getCrewMembers(CrewProfessionType.Captain) == 0 then
    terminate()
    return
  end

  -- find an asteroid that can be harvested
  AILazyMineAll.updateMining(timeStep)
end

-- check the immediate region around the ship for loot that can be collected
-- and if there is some, assign minedLoot
function AILazyMineAll.findMinedLoot()

  local loots = {Sector():getEntitiesByType(EntityType.Loot)}

  local ship = Entity()

  minedLoot = nil
  for _, loot in pairs(loots) do
    if loot:isCollectable(ship) and distance2(loot.translationf, ship.translationf) < 150 * 150 then
      minedLoot = loot
     -- print(ship.name .. " has found loot!!",logLevels.trace)
      break
    end
  end

end

-- check the sector for an asteroid
-- if there is one, assign minedAsteroid
function AILazyMineAll.findMinedAsteroid()
--    local radius = 20
  local ship = Entity()
  local sector = Sector()

  minedAsteroid = nil

  local mineables =   {sector:getEntitiesByType(EntityType.Asteroid)}

  local nearest = math.huge

  for _, a in pairs(mineables) do
    dist = distance2(a.translationf, ship.translationf)

    if dist < nearest then
      nearest = dist
      minedAsteroid = a
    end
  end
  




  if minedAsteroid then
    broadcastInvokeClientFunction("setMinedAsteroid", minedAsteroid.index)
  --  print(ship.name .. " has found a asteroid!!", logLevels.trace)
  else
    local player = Player(Entity().factionIndex)
    if player then
      local x, y = Sector():getCoordinates()
      local coords = tostring(x) .. ":" .. tostring(y)

      player:sendChatMessage(ship.name or "", ChatMessageType.Error, "Your mining ship in sector %s can't find any more asteroids."%_T, coords)
      player:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we can't find any more asteroids in \\s(%s)!"%_T, coords)
    end

    ShipAI(ship.index):setPassive()
    ship:invokeFunction("craftorders.lua", "setAIAction")
    terminate()
  end

end

function AILazyMineAll.updateMining(timeStep)

  -- highest priority is mining
  if not valid(minedAsteroid) and not valid(minedLoot) then

    -- first, check if there is an asteroid to mine
    AILazyMineAll.findMinedAsteroid()

    -- then, if there's no asteroid, check  if there is loot to collect
    if not valid(minedLoot) then
      AILazyMineAll.findMinedLoot()
    end

  end

  local ship = Entity()
  local ai = ShipAI()

  if valid(minedAsteroid) then

-- if there is an asteroid to collect, attack it
    if ship.selectedObject == nil
    or ship.selectedObject.index ~= minedAsteroid.index
    or ai.state ~= AIState.Attack then

      ai:setAttack(minedAsteroid)
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

function AILazyMineAll.setMinedAsteroid(index)
  minedAsteroid = Entity(index)
end

---- this function will be executed every frame on the client only
--function updateClient(timeStep)
--
--    if valid(minedAsteroid) then
--        drawDebugSphere(minedAsteroid:getBoundingSphere(), ColorRGB(1, 0, 0))
--    end
--end
