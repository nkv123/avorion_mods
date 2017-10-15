package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/LogLevels/scripts/lib/?.lua"
require ("stringutility")
require ("PrintLog")
local logLevels = require("LogLevels")
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AITransfer
AITransfer = {}

local player = Player()
local craft = Entity(player.craftIndex)
local ship = Entity()
local dockStage = 0

function AITransfer.getUpdateInterval()
  return 1
end

-- this function will be executed every frame on the server only
function AITransfer.updateServer(timeStep)


  AITransfer.updateFlying(timeStep)

end

function AITransfer.updateFlying(timeStep)
  if not craft then craft = Entity(player.craftIndex) end
  if not ship then ship = Entity() end
  AITransfer.flytoShip(ship,craft)

end

function printInfo()
  print(ship.name .. " going to " .. craft.name .. " dockStage : ".. tostring(dockStage),logLevels.trace)
  printPos(craft) 
  printPos(ship) 
end
function printPos(s)
  local sPos = s.translationf
  print(s.name .. " craft pos : "..tostring(sPos) ,logLevels.trace)  
--  printSphere(s)
--  printBox(s)
end

function printSphere(s)
  local sSphere=s:getBoundingSphere()
  print(s.name.. " craft sphere center | radius: " ..tostring(sSphere.center) .. " | " .. tostring(sSphere.radius),logLevels.trace)
end
function printBox(s)
  local sBox = s:getBoundingBox()
  print(s.name .. " craft box upper | lower | size: " ..tostring(sBox.upper	)  .. " | " .. tostring(sBox.lower).. " | " ..tostring(sBox.size),logLevels.trace)
  print(s.name.." craft box position | center: " ..tostring(sBox.position).. " | "..tostring(sBox.center) ,logLevels.trace)
end
function frontOfSphere(s)
  print(s.name .." frontOfSphere",logLevels.trace)
  local sSphere=s:getBoundingSphere()
  local v = vec3(sSphere.center.x,sSphere.center.y, sSphere.center.z+sSphere.radius+500)
  printTarget(v)
  return v
end
function frontOfBox(s)
  print(s.name .." frontOfBox",logLevels.trace)
  local sSphere=s:getBoundingSphere()
  local sBox=s:getBoundingBox()
  local v = vec3(sSphere.center.x,sSphere.center.y, sSphere.center.z+sBox.size.z*0.5)
  printTarget(v)
  return v
end
function shipNose(s)
  print(s.name .." shipNose",logLevels.trace)
  local sv=s.translationf
  local v= sv+frontOfBox(s)
  printTarget(v)
  return v
end
function printTarget(t)
  print("target vec3:" .. tostring(t),logLevels.trace)
end
function printDist (s1, s2)
  d=distance(s1,s2)
  print("distance  from " .. tostring(s1).." to ".. tostring(s2).." is ".. tostring(d) ,logLevels.trace)
end
function AITransfer.flytoShip(ship, craft)


  dockStage = dockStage or 0
--player ship
  local craftCenter = craft:getBoundingSphere().center
  local craftRadius = craft:getBoundingSphere().radius
  local craftPos = craft.translationf
  local craftFront =   frontOfSphere(craft)
--commanded ship
  local shipCenter = ship:getBoundingSphere().center
  local shipRadius = ship:getBoundingSphere().radius
  local shipPos = ship.translationf
  local shipFront =  frontOfSphere(ship)
  local ai = ShipAI(ship.index)

  if dockStage == 0 then
    printInfo()
    target =frontOfSphere(craft)
    if ai.state ~= AIState.Fly then
      ai:setFly(target , 0)
    end

    local dist = distance(craftCenter,shipCenter)
    printDist (craftCenter,shipCenter)
    -- once the ships have touched radiuses go to stage 1
    if dist> craftRadius + shipRadius then
      dockStage = 1
    end
  end



--    -- stage 1 is flying towards the dock inside the light-line
  if dockStage == 1 then
    printInfo()
--      local dock = craft.position:transformCoord(pos + radius * ship:getBoundingBox().size.z * 0.5)
    target = shipNose(craft)
    if ai.state ~= AIState.Fly then
      ai:setFlyLinear(target , 0)
    end


    local v = Velocity(ship.index)
    if v.linear2 <= 0.01 then
      dockStage = 2
      printInfo()
      stop(ship)

    end
  end
--    if dockStage == 2 then
--      local dock = craft.position:transformCoord(pos )
--      ai:setFlyLinear(dock, 0)

--      local engine = Engine(ship.index)
--      ship.desiredVelocity = (engine.brakeThrust / engine.maxVelocity) * 0.15
--    end
--    local dist = distance(dock, craft)
--    -- once the ship is at the dock, wait
--    if dist==0 then
--      ai:setPassive()
--      return true
--    end

--    return false

end

function stop(ship)
  local ai = ShipAI(ship.index)
  ai:setPassive()
  ship:invokeFunction("craftorders.lua", "setAIAction")

  print("terminating",logLevels.trace)
  terminate()
end