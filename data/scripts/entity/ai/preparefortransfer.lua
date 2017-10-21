package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/LogLevels/scripts/lib/?.lua"
require ("stringutility")
require ("PrintLog")
local logLevels = require("LogLevels")
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AITransfer
AITransfer = {}
local waypoints
local player = Player()
local craft = Entity(player.craftIndex)
local ship = Entity()
local current
function AITransfer.getUpdateInterval()
  return 1
end
-- this function will be executed every frame on the server only1
function AITransfer.updateServer(timeStep)


  AITransfer.updateFlying(timeStep)

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
function AITransfer.updateFlying(timeStep)
  if not craft then craft = Entity(player.craftIndex) end
  if not ship then ship = Entity() end
  AITransfer.flytoShip(ship,craft)


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

function AITransfer.flytoShip(ship, craft)
  --commanded ship
  local shipCenter = ship:getBoundingSphere().center
  local shipRadius = ship:getBoundingSphere().radius
  --
  local shipPos , shipDir =  getDockingPositionFront(ship)
  --getBoundingBox().size.z *0.5 exact mesurement coases collision
  local shipHalfSizeZ = craft:getBoundingBox().size.z * 0.5
  local shipPosFront = shipPos + shipDir *  shipHalfSizeZ
  --
  local shipPosDown, shipDirDown = getDockingPositionDown(ship)
  local shipSizeY = craft:getBoundingBox().size.y
  local shipPosBelow = shipPosDown+shipDirDown *shipSizeY
--player ship
  local craftCenter = craft:getBoundingSphere().center
  local craftRadius = craft:getBoundingSphere().radius
  --
  local craftPos, craftDir = getDockingPositionFront(craft)
  --getBoundingBox().size.z *0.5 exact mesurement coases collision
  local craftHalfSizeZ = craft:getBoundingBox().size.z *0.5

  local craftPosFront = craftPos+craftDir  *craftHalfSizeZ
  --
  local craftPosUp, craftDirUp =getDockingPositionUp(craft) 
  local craftSizeY = craft:getBoundingBox().size.y
  local craftPosAbove = craftCenter+craftDirUp * craftSizeY


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
--    table.insert(waypoints, v4)

--    printTarget(v1)
--    printTarget(v2)
--    printTarget(v3)
--    printTarget(v4)
    current=1
    sendPlayerInformation("have set course.")  
  end

  local d = craftHalfSizeZ
  local dist= distance(shipPosFront, waypoints[current])
--  printDistanceShip(dist)
--  printDistance(d)

  if dist < d then

    --do not pass #waypoints
    if current <= #waypoints then 
      sendPlayerInformation("have reached waypoint "..current.." / ".. #waypoints )
      current = current + 1
      if current < #waypoints then
        sendPlayerInformation("are going to waypoint "..current.." / ".. #waypoints )
      end
    end
  end

--    print( ship.name .." remaining waypoints ".. tostring(#waypoints - current) ,logLevels.trace)



  if current <= #waypoints then 

    -- go slow
    if current > 1 then
      local engine = Engine(ship.index)
      ship.desiredVelocity = (engine.brakeThrust / engine.maxVelocity) * 0.15
    end
    -- fly linear if passed 2 else fly normal
    if current > 2 then
      ai:setFlyLinear(waypoints[current], 0)
    else
      ai:setFly(waypoints[current], 0)
    end

  else  
    sendPlayerInformation("have reached our destination.")
    ai:setPassive()
    terminate()
  end

end


--  if dockStage == 0 then
--     -- go  to front  craft position + far+craft radius + ship radius
--    target =
----    print( ship.name .." location wanted: ",logLevels.trace)
--    printTarget(target)
--    if ai.state ~= AIState.Fly then
--      ai:setFly(target , 0)
--    end

--    local dist = distance(target,shipPos) 
--    local dist2 = far+craftRadius+shipRadius
--    -- once the ships have touched radiuses go to stage 1
--    printDistanceShip(dist)
--    printDistance(dist2)
--    if dist < dist2 then
--      changeDockingStage(1)
--    end
--  end



----   stage 1 is flying towards the player ship
--  if dockStage == 1 then
--    -- go  to front  craft position + near+craft radius + ship radius
--    target = craftPos+craftDir * (near+craftRadius+shipRadius)
--     local dist = distance(target,shipPos) 
--    printDistanceShip(dist)

--    if ai.state ~= AIState.Fly then
--      ai:setFlyLinear(target , 0)
--    end
--    local v = Velocity(ship.index)
--    if v.linear2 <= 0.01 then
--      changeDockingStage(2)
--    end
--  end
--  if dockStage == 2 then
---- go  to front   craft position + craft radius + ship:getBoundingBox().size.z * 0.5
--    target =craftPos+craftDir * (ship:getBoundingBox().size.z * 0.5)
--    local dist =distance(target,shipPos) 
--     printDistanceShip(dist)

--    ai:setFlyLinear(target, 0)

--    local engine = Engine(ship.index)
--    ship.desiredVelocity = (engine.brakeThrust / engine.maxVelocity) * 0.15
--    local v = Velocity(ship.index)
--    if v.linear2 <= 0.01 then
--      changeDockingStage(3)
--    end
--  end
--  if dockStage == 3 then
--    -- go to front craft position
--    target =craftPos+craftDir
--    local dist =distance(craftPos,shipPos) 

--    ai:setFlyLinear(target, 0)
--    if dist==0 then
--      ai:setPassive()
--     ship:invokeFunction("craftorders.lua", "setAIAction")
--        terminate()
--      return true
--    end
--    return false
--  end

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

--end
