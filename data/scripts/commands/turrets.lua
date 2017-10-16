package.path = package.path .. ";data/scripts/lib/?.lua"
require ("turretgenerator")
seed = Seed(0)
--weapon types ChainGun Laser MiningLaser PlasmaGun  RocketLauncher Cannon RailGun RepairBeam Bolter LightningGun TeslaGun ForceGun SalvagingLaser PulseCannon
function makeCannons(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local CannonTemplate = GenerateTurretTemplate(seed, WeaponType.Cannon, 1200, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {CannonTemplate:getWeapons()}

----clear old weapons from turret
  CannonTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
--    weapon.fireRate = 5
    --    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 1500
    weapon.accuracy = 0.99
    weapon.psize = 2
----add mofidied weapons to turret
    CannonTemplate:addWeapon(weapon)
  end



--change properties of turret
  CannonTemplate.automatic = true
  CannonTemplate.simultaneousShooting = true
  CannonTemplate.size = 2
  for i=0,  12 do
    Player(sender):getInventory():add(InventoryTurret(CannonTemplate))
  end
end


function makeLasers(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local LaserTemplate  = GenerateTurretTemplate(seed, WeaponType.Laser, 200, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {LaserTemplate:getWeapons()}

----clear old weapons from turret
  LaserTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
--    weapon.fireRate = 2
--    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 450
    weapon.accuracy = 1
----add mofidied weapons to turret
    LaserTemplate:addWeapon(weapon)
  end


--change properties of turret
  LaserTemplate
  .automatic = true
  LaserTemplate.simultaneousShooting = true
  LaserTemplate.size = 2
  for i=0, 12 do
    Player(sender):getInventory():add(InventoryTurret(LaserTemplate))
  end
end

function makeRailGuns(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local LaserTemplate  = GenerateTurretTemplate(seed, WeaponType.RailGun, 400, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {LaserTemplate:getWeapons()}

----clear old weapons from turret
  LaserTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
--    weapon.fireRate = 3
--    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 600
    weapon.accuracy = 1
----add mofidied weapons to turret
    LaserTemplate:addWeapon(weapon)
  end



--change properties of turret
  LaserTemplate.automatic = true
  LaserTemplate.simultaneousShooting = true
  LaserTemplate.size = 2
  for i=0, 12 do
    Player(sender):getInventory():add(InventoryTurret(LaserTemplate))
  end
end

function makePlasmaGuns(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local PlasmaTemplate  = GenerateTurretTemplate(seed, WeaponType.PlasmaGun, 50, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {PlasmaTemplate:getWeapons()}

----clear old weapons from turret
  PlasmaTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
--    weapon.fireRate = 2
--    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 650.
    weapon.accuracy = 0.971
    weapon.psize = 2
----add mofidied weapons to turret
    PlasmaTemplate:addWeapon(weapon)
  end



--change properties of turret
  PlasmaTemplate.automatic = true
  PlasmaTemplate.simultaneousShooting = true
  PlasmaTemplate.size = 2
  for i=0, 12 do
    Player(sender):getInventory():add(InventoryTurret(PlasmaTemplate))
  end
end


function makeLightningGuns(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local LightningTemplate  = GenerateTurretTemplate(seed, WeaponType.LightningGun, 3000, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {LightningTemplate:getWeapons()}

----clear old weapons from turret
  LightningTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
--    weapon.fireRate = 0.95
--    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 450.
    weapon.accuracy = 0.75
    weapon.psize = 1
----add mofidied weapons to turret
    LightningTemplate:addWeapon(weapon)
  end



--change properties of turret
  LightningTemplate.automatic = true
  LightningTemplate.simultaneousShooting = true
  LightningTemplate.size = 1
  for i=0, 12 do
    Player(sender):getInventory():add(InventoryTurret(LightningTemplate))
  end
end

function makeTeslaGuns(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local LightningTemplate  = GenerateTurretTemplate(seed, WeaponType.TeslaGun, 500, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {LightningTemplate:getWeapons()}

----clear old weapons from turret
  LightningTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
--    weapon.damage = 500
--    weapon.fireRate = 0.99
--    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 450.
    weapon.accuracy = 1
    weapon.psize = 1
----add mofidied weapons to turret
    LightningTemplate:addWeapon(weapon)
  end



--change properties of turret
  LightningTemplate.automatic = true
  LightningTemplate.simultaneousShooting = true
  LightningTemplate.size = 1
  for i=0, 12 do
    Player(sender):getInventory():add(InventoryTurret(LightningTemplate))
  end
end

function makeChainGuns(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local LightningTemplate  = GenerateTurretTemplate(seed, WeaponType.ChainGun, 50, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {LightningTemplate:getWeapons()}

----clear old weapons from turret
  LightningTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
--    weapon.fireRate = 0.5
--    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 750
    weapon.accuracy = 0.96
    weapon.psize = 1
----add mofidied weapons to turret
    LightningTemplate:addWeapon(weapon)
  end



--change properties of turret
  LightningTemplate.automatic = true
  LightningTemplate.simultaneousShooting = true
  LightningTemplate.size = 1
  for i=0, 12 do
    Player(sender):getInventory():add(InventoryTurret(LightningTemplate))
  end
end

function makePulseCannons(sender)


--(seed,weaponType,dps,techLevel,rarity,material)
  local PlasmaTemplate  = GenerateTurretTemplate(seed, WeaponType.PulseCannon, 1000, 20,  Rarity(5), Material(MaterialType.Avorion))
--table containing the weapons that make up the turret
  local weapons = {PlasmaTemplate:getWeapons()}

----clear old weapons from turret
  PlasmaTemplate:clearWeapons()

----modify weapons
  for _,weapon in pairs(weapons) do
--    weapon.fireRate = 2
--    weapon.recoil = weapon.recoil*0.01
--    weapon.pmaximumTime = 20
--    weapon.pvelocity = 5000
--    weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator*20.0
    weapon.reach = 1500.
    weapon.accuracy = 0.98
    weapon.psize = 2
----add mofidied weapons to turret
    PlasmaTemplate:addWeapon(weapon)
  end



--change properties of turret
  PlasmaTemplate.automatic = true
  PlasmaTemplate.simultaneousShooting = true
  PlasmaTemplate.size = 2
  for i=0, 12 do
    Player(sender):getInventory():add(InventoryTurret(PlasmaTemplate))
  end
end



function execute(sender, commandName, ...)
  makeCannons(sender)
  makeLasers(sender)
  makeRailGuns(sender)
  makePlasmaGuns(sender)
  makeLightningGuns(sender)
  makeChainGuns(sender)
  makeTeslaGuns(sender)
  makePulseCannons(sender)
end

function getDescription()
  return "adds 12 cannons, lasers, railguns plasmagun, lightningguns, teslaguns, pulseguns turrets"
end

function getHelp()
  return "just type command /turrets"
end
