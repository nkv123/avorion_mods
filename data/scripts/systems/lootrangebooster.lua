package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require("utility")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getLootCollectionRange(seed, rarity)
    return round((rarity.value + 2) * 5 * (1.3 ^ rarity.value)) -- one unit is 10 meters
end

function onInstalled(seed, rarity)
    addAbsoluteBias(StatsBonuses.LootCollectionRange, getLootCollectionRange(seed, rarity))
end

function onUninstalled(seed, rarity)
end

function getName(seed, rarity)
    return "RCN-00 Tractor Beam Upgrade MK ${mark}"%_t % {mark = toRomanLiterals(rarity.value + 2)}
end

function getIcon(seed, rarity)
    return "data/textures/icons/coins.png"
end

function getEnergy(seed, rarity)
    local range = getLootCollectionRange(seed, rarity)
    return range * 20 * 1000 * 1000 / (1.1 ^ rarity.value)
end

function getPrice(seed, rarity)
    return 500 * getLootCollectionRange(seed, rarity)
end

function getTooltipLines(seed, rarity)
    return
    {
        {ltext = "Loot Collection Range"%_t, rtext = "+${distance} km"%_t % {distance = getLootCollectionRange(seed, rarity) / 100}, icon = "data/textures/icons/coins.png"}
    }
end

function getDescriptionLines(seed, rarity)
    return
    {
        {ltext = "Gotta catch 'em all!"%_t, lcolor = ColorRGB(1, 0.5, 0.5)}
    }
end
