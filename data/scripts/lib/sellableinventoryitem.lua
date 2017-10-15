package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("tooltipmaker")
require ("inventoryitemprice")

local SellableInventoryItem = {}
SellableInventoryItem.__index = SellableInventoryItem

function SortSellableInventoryItems(a, b)
    if a.item.itemType == b.item.itemType then
        if a.rarity.value == b.rarity.value then
            if a.item.itemType == InventoryItemType.Turret or a.item.itemType == InventoryItemType.TurretTemplate then
                if a.item.weaponPrefix == b.item.weaponPrefix then
                    return a.price > b.price
                else
                    return a.item.weaponPrefix < b.item.weaponPrefix
                end
            elseif a.item.itemType == InventoryItemType.SystemUpgrade then
                if a.item.script == b.item.script then
                    return a.price > b.price
                else
                    return a.item.script < b.item.script
                end
            end
        else
            return a.rarity.value > b.rarity.value
        end
    else
        return a.item.itemType < b.item.itemType
    end
end

local function new(item, index, owner)
    local obj = setmetatable({item = item, index = index}, SellableInventoryItem)

    -- initialize the item
    obj.price = obj:getPrice()
    obj.name = obj:getName()
    obj.rarity = obj.item.rarity
    obj.material = obj:getMaterial()
    obj.icon = obj:getIcon()

    if owner and index then
        obj.amount = owner:getInventory():amount(index)
    elseif index and type(index) == "number" then
        obj.amount = index
    else
        obj.amount = 1
    end

    return obj
end

function SellableInventoryItem:getMaterial()
    if self.item.itemType == InventoryItemType.Turret or self.item.itemType == InventoryItemType.TurretTemplate then
        return self.item.material
    end
end

function SellableInventoryItem:getIcon()
    if self.item.itemType == InventoryItemType.Turret or self.item.itemType == InventoryItemType.TurretTemplate then
        return self.item.weaponIcon
    elseif self.item.itemType == InventoryItemType.SystemUpgrade then
        return self.item.icon
    elseif self.item.itemType == InventoryItemType.VanillaItem then
        return self.item.icon
    end
end

function SellableInventoryItem:getTooltip()

    if self.tooltip == nil then
        if self.item.itemType == InventoryItemType.Turret or self.item.itemType == InventoryItemType.TurretTemplate then
            self.tooltip = makeTurretTooltip(self.item)
        elseif self.item.itemType == InventoryItemType.SystemUpgrade then
            self.tooltip = self.item.tooltip
        elseif self.item.itemType == InventoryItemType.VanillaItem then
            self.tooltip = self.item:getTooltip()
        end
    end

    return self.tooltip
end

function SellableInventoryItem:getPrice()
    local value = 0

    if self.item.itemType == InventoryItemType.Turret or self.item.itemType == InventoryItemType.TurretTemplate then

        local turret = self.item

        local value = round(ArmedObjectPrice(turret))

        return value

    elseif self.item.itemType == InventoryItemType.SystemUpgrade then
        value = self.item.price

    elseif self.item.itemType == InventoryItemType.VanillaItem then
        value = self.item.price
    end

    return value
end

function SellableInventoryItem:getName()
    local name = ""

    if self.item.itemType == InventoryItemType.Turret or self.item.itemType == InventoryItemType.TurretTemplate then
        if onClient() then
            local tooltip = self:getTooltip()
            return tooltip:getLine(0).ctext
        else
            return "Turret";
        end

    elseif self.item.itemType == InventoryItemType.SystemUpgrade then
        return self.item.name
    elseif self.item.itemType == InventoryItemType.VanillaItem then
        return self.item.name
    end

    return name
end

function SellableInventoryItem:boughtByPlayer(ship)
    local faction = Faction(ship.factionIndex)
    faction:getInventory():add(self.item)
end

function SellableInventoryItem:soldByPlayer(ship)

    local faction = Faction(ship.factionIndex)

    local item = faction:getInventory():take(self.index)
    if item == nil then
        return "Item to sell not found", {}
    end

end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})


