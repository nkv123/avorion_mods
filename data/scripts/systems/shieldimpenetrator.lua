package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getBonuses(seed, rarity)
    math.randomseed(seed)

    local durability = 0.38
    durability = durability + (rarity.value * 0.03) + (0.03 * math.random())

    local rechargeTimeFactor = 4.0
    rechargeTimeFactor = rechargeTimeFactor - (rarity.value * 0.2) - (0.2 * math.random())

    return durability, rechargeTimeFactor
end

function onInstalled(seed, rarity)
    local durability, rechargeTimeFactor = getBonuses(seed, rarity)

    addAbsoluteBias(StatsBonuses.ShieldImpenetrable, 1)
    addMultiplier(StatsBonuses.ShieldDurability, durability)
    addBaseMultiplier(StatsBonuses.ShieldTimeUntilRechargeAfterHit, rechargeTimeFactor)
end

function onUninstalled(seed, rarity)

end

function getName(seed, rarity)
    return "Shield Reinforcer"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/bordered-shield.png"
end

function getEnergy(seed, rarity)
    local durability, rechargeTimeFactor = getBonuses(seed, rarity)
    return durability * 1.75 * 1000 * 1000 * 1000
end

function getPrice(seed, rarity)
    local durability, rechargeTimeFactor = getBonuses(seed, rarity)
    local price = durability * 1000 * 500
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity)

    local texts = {}
    local durability, rechargeTimeFactor = getBonuses(seed, rarity)

    table.insert(texts, {ltext = "Impenetrable Shields"%_t, rtext = "Yes"%_t, icon = "data/textures/icons/shield.png"})

    if durability ~= 0 then
        table.insert(texts, {ltext = "Shield Durability"%_t, rtext = string.format("%+i%%", -(1.0 - durability) * 100), icon = "data/textures/icons/health-normal.png"})
    end
    if rechargeTimeFactor ~= 0 then
        table.insert(texts, {ltext = "Time Until Recharge"%_t, rtext = string.format("%+i%%", rechargeTimeFactor * 100), icon = "data/textures/icons/sands-of-time.png"})
    end

    return texts
end

function getDescriptionLines(seed, rarity)
    local texts = {}
    table.insert(texts, {ltext = "Shields can't be penetrated by shots or torpedoes."%_t})
    table.insert(texts, {ltext = "Durability is diverted to reinforce shield membrane."%_t})
    table.insert(texts, {ltext = "Time until recharge after a hit is increased."%_t})

    return texts
end
