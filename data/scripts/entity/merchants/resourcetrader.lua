package.path = package.path .. ";data/scripts/lib/?.lua"
require ("randomext")
require ("galaxy")
require ("utility")
require ("stringutility")
require ("faction")
require ("player")
local Dialog = require("dialogutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace ResourceDepot
ResourceDepot = {}

-- Menu items
local window = 0
local buyAmountTextBox = 0
local sellAmountTextBox = 0

local stock = {}
local buyPrice = {}
local sellPrice = {}

local soldGoodStockLabels = {}
local soldGoodPriceLabels = {}
local soldGoodTextBoxes = {}
local soldGoodButtons = {}

local boughtGoodStockLabels = {}
local boughtGoodPriceLabels = {}
local boughtGoodTextBoxes = {}
local boughtGoodButtons = {}

local guiInitialized = false

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function ResourceDepot.interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, -25000)
end

function ResourceDepot.restore(data)
    stock = data
end

function ResourceDepot.secure()
    return stock
end

function ResourceDepot.initialize()
    local station = Entity()

    if station.title == "" then
        station.title = "Resource Depot"%_t
    end

    if onServer() then
        math.randomseed(Sector().seed + Sector().numEntities)

        -- best buy price: 1 iron for 10 credits
        -- best sell price: 1 iron for 10 credits
        local x, y = Sector():getCoordinates();

        local probabilities = Balancing_GetMaterialProbability(x, y);

        for i = 1, NumMaterials() do
            stock[i] = math.max(0, probabilities[i - 1] - 0.1) * (getInt(5000, 10000) * Balancing_GetSectorRichnessFactor(x, y))
            buyPrice[i] = 10 * Material(i - 1).costFactor
            sellPrice[i] = 10 * Material(i - 1).costFactor
        end

        local num = 0
        for i = NumMaterials(), 1, -1 do
            stock[i] = stock[i] + num
            num = num + stock[i] / 4;
        end

        for i = 1, NumMaterials() do
            stock[i] = round(stock[i])
        end

    end

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/resources.png"
        InteractionText(station.index).text = Dialog.generateStationInteractionText(station, random())
    end
end

-- create all required UI elements for the client side
function ResourceDepot.initUI()

    local res = getResolution()
    local size = vec2(700, 650)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(window, "Trade Materials"%_t);

    window.caption = ""
    window.showCloseButton = 1
    window.moveable = 1

    -- create a tabbed window inside the main window
    local tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create buy tab
    local buyTab = tabbedWindow:createTab("Buy"%_t, "data/textures/icons/purse.png", "Buy from station"%_t)
    ResourceDepot.buildBuyGui(buyTab)

    -- create sell tab
    local sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/coins.png", "Sell to station"%_t)
    ResourceDepot.buildSellGui(sellTab)

    ResourceDepot.retrieveData();

    guiInitialized = true

end


function ResourceDepot.buildBuyGui(window)
    ResourceDepot.buildGui(window, 1)
end

function ResourceDepot.buildSellGui(window)
    ResourceDepot.buildGui(window, 0)
end

function ResourceDepot.buildGui(window, guiType)

    local buttonCaption = ""
    local buttonCallback = ""
    local textCallback = ""

    if guiType == 1 then
        buttonCaption = "Buy"%_t
        buttonCallback = "onBuyButtonPressed"
        textCallback = "onBuyTextEntered"
    else
        buttonCaption = "Sell"%_t
        buttonCallback = "onSellButtonPressed"
        textCallback = "onSellTextEntered"
    end

    local nameX = 10
    local stockX = 250
    local volX = 340
    local priceX = 390
    local textBoxX = 480
    local buttonX = 550

    -- header
    -- createLabel(window, vec2(nameX, 10), "Name", 15)
    window:createLabel(vec2(stockX, 0), "Stock"%_t, 15)
    window:createLabel(vec2(priceX, 0), "Cr"%_t, 15)

    local y = 25
    for i = 1, NumMaterials() do

        local yText = y + 6

        local frame = window:createFrame(Rect(0, y, textBoxX - 10, 30 + y))

        local nameLabel = window:createLabel(vec2(nameX, yText), "", 15)
        local stockLabel = window:createLabel(vec2(stockX, yText), "", 15)
        local priceLabel = window:createLabel(vec2(priceX, yText), "", 15)
        local numberTextBox = window:createTextBox(Rect(textBoxX, yText - 6, 60 + textBoxX, 30 + yText - 6), textCallback)
        local button = window:createButton(Rect(buttonX, yText - 6, window.size.x, 30 + yText - 6), buttonCaption, buttonCallback)

        button.maxTextSize = 16

        numberTextBox.text = "0"
        numberTextBox.allowedCharacters = "0123456789"
        numberTextBox.clearOnClick = 1

        if guiType == 1 then
            table.insert(soldGoodStockLabels, stockLabel)
            table.insert(soldGoodPriceLabels, priceLabel)
            table.insert(soldGoodTextBoxes, numberTextBox)
            table.insert(soldGoodButtons, button)
        else
            table.insert(boughtGoodStockLabels, stockLabel)
            table.insert(boughtGoodPriceLabels, priceLabel)
            table.insert(boughtGoodTextBoxes, numberTextBox)
            table.insert(boughtGoodButtons, button)
        end

        nameLabel.caption = Material(i - 1).name
        nameLabel.color = Material(i - 1).color

        y = y + 35
    end

end

--function renderUIIndicator(px, py, size)
--
--end
--
---- this function gets called every time the window is shown on the client, ie. when a player presses F
--function onShowWindow()
--
--end
--
---- this function gets called every time the window is closed on the client
--function onCloseWindow()
--
--end
--
--function update(timeStep)
--
--end

--function updateClient(timeStep)
--
--end

--function updateServer(timeStep)
--
--end

--function renderUI()
--
--end

-- client sided
function ResourceDepot.onBuyButtonPressed(button)
    local material = 0

    for i = 1, NumMaterials() do
        if soldGoodButtons[i].index == button.index then
            material = i
        end
    end

    local amount = soldGoodTextBoxes[material].text
    if amount == "" then
        amount = 0
    else
        amount = tonumber(amount)
    end

    invokeServerFunction("buy", material, amount);

end

function ResourceDepot.onSellButtonPressed(button)

    local material = 0

    for i = 1, NumMaterials() do
        if boughtGoodButtons[i].index == button.index then
            material = i
        end
    end

    local amount = boughtGoodTextBoxes[material].text
    if amount == "" then
        amount = 0
    else
        amount = tonumber(amount)
    end

    invokeServerFunction("sell", material, amount);

end

function ResourceDepot.onBuyTextEntered()

end

function ResourceDepot.onSellTextEntered()

end

function ResourceDepot.retrieveData()
    invokeServerFunction("getData");
end

function ResourceDepot.setData(material, amount, remoteBuyPrice, remoteSellPrice)

    if guiInitialized then
        stock[material] = amount
        buyPrice[material] = remoteBuyPrice
        sellPrice[material] = remoteSellPrice

        soldGoodStockLabels[material].caption = createMonetaryString(amount)
        soldGoodPriceLabels[material].caption = tostring(remoteBuyPrice)
        boughtGoodStockLabels[material].caption = createMonetaryString(amount)
        boughtGoodPriceLabels[material].caption = tostring(remoteSellPrice)
    end

end


-- server sided
function ResourceDepot.buy(material, amount)

    if amount <= 0 then return end

    local seller, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not seller then return end

    local station = Entity()

    local numTraded = math.min(stock[material], amount)
    local price = ResourceDepot.getBuyPrice(material, seller) * numTraded;

    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to trade."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to trade."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    local ok, msg, args = seller:canPay(price)
    if not ok then
        player:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    seller:pay(price)
    seller:receiveResource(Material(material - 1), numTraded)

    stock[material] = stock[material] - numTraded

    ResourceDepot.improveRelations(numTraded, ship, seller)

    -- update
    broadcastInvokeClientFunction("setData", material, stock[material], ResourceDepot.getBuyPrice(material, seller), ResourceDepot.getSellPrice(material, seller))

end

function ResourceDepot.sell(material, amount)

    if amount <= 0 then return end

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end

    local station = Entity()

    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to trade."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to trade."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    local playerResources = {buyer:getResources()}
    local numTraded = math.min(playerResources[material], amount)
    local price = ResourceDepot.getSellPrice(material, buyer) * numTraded;

    buyer:receive(price);
    buyer:payResource(Material(material - 1), numTraded);

    stock[material] = stock[material] + numTraded

    ResourceDepot.improveRelations(numTraded, ship, buyer)

    -- update
    broadcastInvokeClientFunction("setData", material, stock[material], ResourceDepot.getBuyPrice(material, buyer), ResourceDepot.getSellPrice(material, buyer));
end

-- relations improve when trading
function ResourceDepot.improveRelations(numTraded, ship, buyer)
    relationsGained = relationsGained or {}

    local gained = relationsGained[buyer.index] or 0
    local maxGainable = 10000
    local gainable = math.max(0, maxGainable - gained)

    local gain = numTraded / 20
    gain = math.min(gain, gainable)

    -- mining ships get higher relation gain
    if ship:getNumUnarmedTurrets() > ship:getNumArmedTurrets() then
        gain = gain * 1.5
    end

    Galaxy():changeFactionRelations(buyer, Faction(), gain)

    -- remember that the player gained that many relation points
    gained = gained + gain
    relationsGained[buyer.index] = gained
end

function ResourceDepot.getBuyingFactor(orderingFaction)

    local stationFaction = Faction()

    if orderingFaction.index == Faction().index then return 1 end

    local percentage = 1;
    local relation = stationFaction:getRelations(orderingFaction.index)

    -- 2.0 at relation = 0
    -- 1.2 at relation = 100000
    if relation >= 0 then
        percentage = lerp(relation, 0, 100000, 2, 1.2)
    end

    -- 2.0 at relation = 0
    -- 3.0 at relation = -10000
    -- 3.0+ at relation < -10000
    if relation < 0 then
        percentage = lerp(relation, -10000, 0, 3, 2)
    end

    return percentage

end

function ResourceDepot.getSellingFactor(orderingFaction)

    local stationFaction = Faction()

    if orderingFaction.index == Faction().index then return 1 end

    local percentage = 1;
    local relation = stationFaction:getRelations(orderingFaction.index)

    -- 0.5 at relation = 0
    -- 0.8 at relation = 100000
    if relation >= 0 then
        percentage = lerp(relation, 0, 100000, 0.4, 0.6)
    end

    -- 0.5 at relation = 0
    -- 0.1 at relation <= -10000
    if relation < 0 then
        percentage = lerp(relation, -10000, 0, 0.1, 0.4);

        percentage = math.max(percentage, 0.1);
    end

    return percentage

end

function ResourceDepot.getSellPrice(material, faction)
    return round(sellPrice[material] * ResourceDepot.getSellingFactor(faction), 1)
end

function ResourceDepot.getBuyPrice(material, faction)
    return round(buyPrice[material] * ResourceDepot.getBuyingFactor(faction), 1)
end

function ResourceDepot.getData()

    local player = Player(callingPlayer)

    for i = 1, NumMaterials() do
        invokeClientFunction(player, "setData", i, stock[i], ResourceDepot.getBuyPrice(i, player), ResourceDepot.getSellPrice(i, player));
    end

end

