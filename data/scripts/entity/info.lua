package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";mods/LogLevels/scripts/lib/?.lua"
require ("stringutility")
require ("PrintLog")
local logLevels = require("LogLevels")
-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AIInfo
AIInfo = {}

local player = Player()
local craft = Entity(player.craftIndex)
local ship = Entity()

function AIInfo.getUpdateInterval()
  return 1
end

-- this function will be executed every frame on the server only
function AIInfo.updateServer(timeStep)


  AIInfo.updateFlying(timeStep)

end

function AIInfo.updateFlying(timeStep)
  if not craft then craft = Entity(player.craftIndex) end

  if not ship then ship = Entity() end
  printPos(ship)
--  printSphere(ship)
  frontOfSphere(ship)
--  directionSphere(ship)
--  printBox(ship)
--  frontOfBox(ship)
--  directionBox(ship)
  printMatrixPosition(ship)
  printMatrixOrientation(ship)

--  heading(ship)
end
function heading(s)
  local sPos = s.translationf
  local heading = s.translationf - craft.translationf
  local distance = length(heading);
  local direction = heading / distance; 
  print(s.name .. " heading" ,logLevels.trace)  
  printTarget(direction)
end
function printPos(s)
  local sPos = s.translationf
  print(s.name .. " pos : "..tostring(sPos) ,logLevels.trace)  


end
function printMatrixPosition(s)
  sMatrix =s.position
  print(s.name .."printMatrixPosition",logLevels.trace)
  print(s.name .. " matix right | up | look: " ..tostring(sMatrix.right	)  .. " | " .. tostring(sMatrix.up).. " | " ..tostring(sMatrix.look),logLevels.trace)
  print(s.name .. " matix translation | pos | position: " ..tostring(sMatrix.translation	)  .. " | " .. tostring(sMatrix.pos).. " | " ..tostring(sMatrix.position),logLevels.trace)

end
function printMatrixOrientation(s)
  sMatrix =s.orientation
  print(s.name .."printMatrixOrientation",logLevels.trace)
  print(s.name .. " matix right | up | look: " ..tostring(sMatrix.right	)  .. " | " .. tostring(sMatrix.up).. " | " ..tostring(sMatrix.look),logLevels.trace)
  print(s.name .. " matix translation | pos | position: " ..tostring(sMatrix.translation	)  .. " | " .. tostring(sMatrix.pos).. " | " ..tostring(sMatrix.position),logLevels.trace)

end
function printSphere(s)
  local sSphere=s:getBoundingSphere()
  print(s.name.. " sphere center | radius: " ..tostring(sSphere.center) .. " | " .. tostring(sSphere.radius),logLevels.trace)


end
function printBox(s)
  local sBox = s:getBoundingBox()
  print(s.name .. " box upper | lower | size: " ..tostring(sBox.upper	)  .. " | " .. tostring(sBox.lower).. " | " ..tostring(sBox.size),logLevels.trace)
  print(s.name.." box position | center: " ..tostring(sBox.position).. " | "..tostring(sBox.center) ,logLevels.trace)
end
function frontOfSphere(s,dist)

  local sSphere=s:getBoundingSphere()
  sMatrix =s.position
  local v = sSphere.center +sMatrix.look
  print(s.name .." frontOfSphere",logLevels.trace)
  printTarget(v)  
  printTargetMagnitude(v)
  return v
end
function directionSphere(s)
  front=frontOfSphere(s,200)
  local v =front-s.translationf

  print(s.name .." directionSphere",logLevels.trace)
  printTarget(v)
  printTargetMagnitude(v)
  return v 
end

function frontOfBox(s)

  local sSphere=s:getBoundingSphere()
  local sBox=s:getBoundingBox()
  local v = vec3(sSphere.center.x,sSphere.center.y, sSphere.center.z+sBox.size.z*0.5) 
--  print(s.name .." frontOfBox",logLevels.trace)
--  printTarget(v)
--  printTargetMagnitude(v)
  return v
end
function directionBox(s)
  front=frontOfBox(s)
  local v =front-s.translationf

  print(s.name .." directionBox",logLevels.trace)
  printTarget(v)
  printTargetMagnitude(v)
  return v 
end
function printTarget(t)
  print("vec3: " .. tostring(t),logLevels.trace)
end

function printTargetMagnitude(t)
  print("magnitude vec3: " .. tostring(length(t)),logLevels.trace)
end