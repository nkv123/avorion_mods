
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("upgradegenerator")
seed = Seed(2)

function getDescription()
  return "adds 5 hyperspace, minining systems, tradeoverview, civiltcs, militarycts, scanboosters, radarboosters"
end

function getHelp()
  return "just type command /upgrades"
end

function makeHypers(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/hyperspacebooster.lua", Rarity(RarityType.Legendary),seed)
  
     Player(sender):getInventory():add(system)
  end
function makeMiners(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/miningsystem.lua", Rarity(RarityType.Legendary),seed)
  
 
     Player(sender):getInventory():add(system)
  
end

function makeTradingoverview(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/tradingoverview.lua", Rarity(RarityType.Legendary), seed)
  
     Player(sender):getInventory():add(system)
  
end

function makeCiviltcs(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/civiltcs.lua", Rarity(RarityType.Legendary),seed)
  
     Player(sender):getInventory():add(system)
  
end

function makeMilitarytcs(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(RarityType.Legendary), seed)
  
     Player(sender):getInventory():add(system)
  
end
function makeScannerbooster(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/scannerbooster.lua", Rarity(RarityType.Legendary), seed)
  
     Player(sender):getInventory():add(system)
  
end

function makeRadarbooster(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/radarbooster.lua", Rarity(RarityType.Legendary), seed)
 
     Player(sender):getInventory():add(system)
  
end

function makeCargoextension(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/cargoextension.lua", Rarity(RarityType.Legendary), seed)
 
     Player(sender):getInventory():add(system)
  
end


function makeValuablesdetector(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/valuablesdetector.lua", Rarity(RarityType.Legendary), seed)
 
     Player(sender):getInventory():add(system)
  
end
function makeVelocitybypass(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/velocitybypass.lua", Rarity(RarityType.Legendary), seed)
 
     Player(sender):getInventory():add(system)
  
end



function execute(sender, commandName, ...)
  makeHypers(sender)
  makeMiners(sender)
  makeTradingoverview(sender)
  makeCiviltcs(sender)
  makeMilitarytcs(sender)
  makeScannerbooster(sender)
  makeRadarbooster(sender)
  makeValuablesdetector(sender)
  makeVelocitybypass(sender)
end
