package.path = package.path .. ";data/scripts/lib/?.lua"
require ("turretgenerator")
seed = Seed(0)


function makeRepairbeams1(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local RepairTemplate = GenerateTurretTemplate(seed, WeaponType.RepairBeam, 0, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {RepairTemplate:getWeapons()}

----clear old weapons from turret
  RepairTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
    weapon.shieldRepair =1000
    weapon.fireRate = 1
    --    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 650
    weapon.accuracy = 1
----add mofidied weapons to turret
    RepairTemplate:addWeapon(weapon)
  end



--change properties of turret
  RepairTemplate.automatic = true
  RepairTemplate.simultaneousShooting = true
  RepairTemplate.size = 1
  for i=0,  12 do
    Player(sender):getInventory():add(InventoryTurret(RepairTemplate))
  end
end


function makeRepairbeams2(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local RepairTemplate = GenerateTurretTemplate(seed, WeaponType.RepairBeam, 0, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {RepairTemplate:getWeapons()}

----clear old weapons from turret
  RepairTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
    weapon.hullRepair =1000
    weapon.fireRate = 1
    --    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 650
    weapon.accuracy = 1
----add mofidied weapons to turret
    RepairTemplate:addWeapon(weapon)
  end



--change properties of turret
  RepairTemplate.automatic = true
  RepairTemplate.simultaneousShooting = true
  RepairTemplate.size = 1
  for i=0,  12 do
    Player(sender):getInventory():add(InventoryTurret(RepairTemplate))
  end
end


function makeMiningLasers(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local LaserTemplate  = GenerateTurretTemplate(seed, WeaponType.MiningLaser, 150, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {LaserTemplate:getWeapons()}

----clear old weapons from turret
  LaserTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
    weapon.damage = 150
    weapon.fireRate = 1
    weapon.stoneEfficiency = .75
--    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 300
    weapon.accuracy = 1
----add mofidied weapons to turret
    LaserTemplate:addWeapon(weapon)
  end


--change properties of turret
  LaserTemplate
  .automatic = true
  LaserTemplate.simultaneousShooting = true
  LaserTemplate.size = 1
  for i=0, 12 do
    Player(sender):getInventory():add(InventoryTurret(LaserTemplate))
  end
end
function makeSalvagingLasers(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local LaserTemplate  = GenerateTurretTemplate(seed, WeaponType.SalvagingLaser, 150, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {LaserTemplate:getWeapons()}

----clear old weapons from turret
  LaserTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
    weapon.damage = 150
    weapon.fireRate = 1
    weapon.metalEfficiency=0.75
--    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 300
    weapon.accuracy = 1
----add mofidied weapons to turret
    LaserTemplate:addWeapon(weapon)
  end


--change properties of turret
  LaserTemplate
  .automatic = true
  LaserTemplate.simultaneousShooting = true
  LaserTemplate.size = 1
  for i=0, 12 do
    Player(sender):getInventory():add(InventoryTurret(LaserTemplate))
  end
end


function execute(sender, commandName, ...)
  makeRepairbeams1(sender)
  makeMiningLasers(sender)
  makeSalvagingLasers(sender)
  makeRepairbeams2(sender)

end

function getDescription()
  return "adds 12 mining, salvage, 12 hull repair, 12 shield repair turrets"
end

function getHelp()
  return "just type command /uturrets"
end
