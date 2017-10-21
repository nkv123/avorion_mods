package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/LogLevels/scripts/lib/?.lua"
require ("stringutility")
require ("PrintLog")
local logLevels = require("LogLevels")
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AITransferPrepare
AITransferPrepare = {}
local waypoints
local player = Player()
local craft = Entity(player.craftIndex)
local ship = Entity()
local current
function AITransferPrepare.getUpdateInterval()
  return 1
end
-- this function will be executed every frame on the server only1
function AITransferPrepare.updateServer(timeStep)


  AITransferPrepare.updateFlying(timeStep)

end
function sendPlayerNormal(note)
  local player = Player(Entity().factionIndex)
  if player then
    player:sendChatMessage(ship.name or "", ChatMessageType.Normal, "Sir, we ".. note%_T)
  end
end

function sendPlayerInformation(note)
  local player = Player(Entity().factionIndex)
  if player then
    player:sendChatMessage(ship.name or "", ChatMessageType.Information, "Sir, we ".. note%_T)
  end
end

function printTarget(t)
  print("vec3: " .. tostring(t),logLevels.trace)
end

function printTargetMagnitude(t)
  print("magnitude vec3: " .. tostring(length(t)),logLevels.trace)
end
function getDockingPositionFront(s)
  sMatrix = s.position
  pos = sMatrix.translation
  dir = sMatrix.look
  return pos, dir
end
function getDockingPositionUp(s)
  sMatrix = s.position
  pos = sMatrix.translation
  dir = sMatrix.up
  return pos, dir
end
function getDockingPositionDown(s)
  sMatrix = s.position
  pos = sMatrix.translation
  dir = -sMatrix.up
  return pos, dir
end
function AITransferPrepare.updateFlying(timeStep)
  if not craft then craft = Entity(player.craftIndex) end
  if not ship then ship = Entity() end
  AITransferPrepare.flytoShip(ship,craft)


end

function printDockStage()
  print(ship.name .. " going to " .. craft.name .. " dockStage : ".. tostring(dockStage),logLevels.trace)

end
function printDistanceShip(d)
  sendPlayerNormal("are at distance: " ..ship.name .. " - target: " ..tostring (d))
  print("distance: " ..ship.name .. " - target: " ..tostring (d),logLevels.trace)
end
function printDistance(d)
  sendPlayerNormal("are at distance: " ..tostring (d))
  print("distance: " ..tostring (d),logLevels.trace)
end

function AITransferPrepare.flytoShip(ship, craft)
  --commanded ship
  local shipCenter = ship:getBoundingSphere().center
  local shipRadius = ship:getBoundingSphere().radius
  local shipPos , shipDir =  getDockingPositionFront(ship)
  local shipPosFront = shipPos + shipDir *  shipRadius 
  --
  local shipPosDown, shipDirDown = getDockingPositionDown(ship)
  local shipPosBelow = shipPosDown+shipDirDown *shipRadius
--player ship
  local craftCenter = craft:getBoundingSphere().center
  local craftRadius = craft:getBoundingSphere().radius
  --
  local craftPos, craftDir = getDockingPositionFront(craft)
  local craftPosFront = craftPos+craftDir  * craftRadius
  --
  local craftPosUp, craftDirUp =getDockingPositionUp(craft) 
  local craftPosAbove = craftCenter+craftDirUp * craftRadius
  --
  local ai = ShipAI(ship.index)
  local far = 500 --5.0 km away
  local near = 150 --1.5 km away


  if not waypoints or #waypoints == 0 then
    waypoints = {}
    -- define vec3
    v1 = vec3(0,0,0)
    v2 = vec3(0,0,0)
    v3 = vec3(0,0,0)    
    v4 = vec3(0,0,0)
    -- instanciate vec3
    v1 = craftPos + craftDir * far
    v2 = craftPos + craftDir * near
    v3 = craftPosFront
    v4 = craftPosAbove 
    --add to table waypoints
    table.insert(waypoints, v1)
    table.insert(waypoints, v2)
    table.insert(waypoints, v3)
    table.insert(waypoints, v4)

--    printTarget(v1)
--    printTarget(v2)
--    printTarget(v3)
--    printTarget(v4)
    current=1
    sendPlayerNormal("have set course.") 
    sendPlayerInformation("have set course.")  

  end

  local d = shipRadius*shipRadius
  local dist= distance2(shipPosFront, waypoints[current])
--  printDistanceShip(dist)
--  printDistance(d)

  if dist < d then

    --do not pass #waypoints
    if current <= #waypoints then 
      sendPlayerNormal("have reached waypoint "..current.." / ".. #waypoints )
      current = current + 1
      if current < #waypoints then
        sendPlayerNormal("are going to waypoint "..current.." / ".. #waypoints )
      end
    end
  end

  if current <= #waypoints then 

    -- go slow
    if current > 1 then
      local engine = Engine(ship.index)
      ship.desiredVelocity = (engine.brakeThrust / engine.maxVelocity) * 0.15
    end
    -- fly linear if passed 2 else fly normal
    if current > 2 then
      if ai.state ~= AIState.Fly then
        ai:setFlyLinear(waypoints[current], 0)
      end
    else
      if ai.state ~= AIState.Fly then
        ai:setFly(waypoints[current], 0)
      end
    end

  else  
    sendPlayerNormal("have reached our destination.")
    sendPlayerInformation("have reached our destination.")    
    ai:setPassive()
    terminate()
  end

end

