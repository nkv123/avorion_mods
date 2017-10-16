
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("upgradegenerator")
seed = Seed(2)

function execute(sender, commandName, ...)
  makeHypers(sender)
  makeMiners(sender)
  makeTradingoverview(sender)
  makeCiviltcs(sender)
  makeMilitarytcs(sender)
  makeScannerbooster(sender)
  makeRadarbooster(sender)

end

function getDescription()
  return "adds 5 hyperspace, minining systems, tradeoverview, civiltcs, militarycts, scanboosters, radarboosters"
end

function getHelp()
  return "just type command /upgrades"
end

function makeHypers(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/hyperspacebooster.lua", Rarity(RarityType.Legendary),seed)
  for _=0,4 do
     Player(sender):getInventory():add(system)
  end
end
function makeMiners(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/miningsystem.lua", Rarity(RarityType.Legendary),seed)
  
  for _=0,4 do
     Player(sender):getInventory():add(system)
  end
end

function makeTradingoverview(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/tradingoverview.lua", Rarity(RarityType.Legendary), seed)
  for i=0,4 do
     Player(sender):getInventory():add(system)
  end
end

function makeCiviltcs(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/civiltcs.lua", Rarity(RarityType.Legendary),seed)
  for i=0,4 do
     Player(sender):getInventory():add(system)
  end
end

function makeMilitarytcs(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(RarityType.Legendary), seed)
  for i=0,4 do
     Player(sender):getInventory():add(system)
  end
end
function makeScannerbooster(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/scannerbooster.lua", Rarity(RarityType.Legendary), seed)
  for i=0,4 do
     Player(sender):getInventory():add(system)
  end
end

function makeRadarbooster(sender)
  local system = SystemUpgradeTemplate("data/scripts/systems/radarbooster.lua", Rarity(RarityType.Legendary), seed)
  for i=0,4 do
     Player(sender):getInventory():add(system)
  end
end