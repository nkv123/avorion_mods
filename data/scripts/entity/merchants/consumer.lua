package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("randomext")
require ("utility")
require ("faction")
require ("stringutility")
local TradingAPI = require ("tradingmanager")
local Dialog = require("dialogutility")

local window

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Consumer
Consumer = {}
Consumer = TradingAPI:CreateNamespace()

Consumer.consumerName = ""
Consumer.consumerIcon = ""
Consumer.consumedGoods = {}

function Consumer.interactionPossible(playerIndex, option)

    if Player(playerIndex).craftIndex == Entity().index then return false end

    return CheckFactionInteraction(playerIndex, -20000)
end

function Consumer.restore(values)
    Consumer.restoreTradingGoods(values)
    Consumer.consumerName = values.consumerName
end

function Consumer.secure()
    local values = Consumer.secureTradingGoods()
    values.consumerName = Consumer.consumerName

    return values
end

function Consumer.initialize(name_in, ...)

    local entity = Entity()

    if onServer() then
        Consumer.consumerName = name_in or Consumer.consumerName

        -- only use parameter goods if there are any, otherwise we prefer the goods we might already have in consumedGoods
        local consumedGoods_in = {...}
        if #consumedGoods_in > 0 then
            Consumer.consumedGoods = consumedGoods_in
        end

        local station = Entity()

        -- add the name as a category
        if Consumer.consumerName ~= "" and entity.title == "" then
            entity.title = Consumer.consumerName
        end


        local seed = Sector().seed + Sector().numEntities
        math.randomseed(seed);

        -- consumers only buy
        Consumer.trader.buyPriceFactor = math.random() * 0.2 + 0.9 -- 0.9 to 1.1

        local bought = {}

        for i, name in pairs(Consumer.consumedGoods) do
            local g = goods[name]
            table.insert(bought, g:good())
        end

        Consumer.initializeTrading(bought, {})
    else
        Consumer.requestGoods()

        if Consumer.consumerIcon ~= "" and EntityIcon().icon == "" then
            EntityIcon().icon = Consumer.consumerIcon
            InteractionText().text = Dialog.generateStationInteractionText(entity, random())
        end
    end

end

-- create all required UI elements for the client side
function Consumer.initUI()

    local res = getResolution()
    local size = vec2(950, 650)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(window, "Sell Goods"%_t);

    window.caption = ""
    window.showCloseButton = 1
    window.moveable = 1

    -- create a tabbed window inside the main window
    local tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create buy tab
    local buyTab = tabbedWindow:createTab("Buy"%_t, "data/textures/icons/purse.png", "Buy from station"%_t)
    Consumer.buildBuyGui(buyTab)

    -- create sell tab
    local sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/coins.png", "Sell to station"%_t)
    Consumer.buildSellGui(sellTab)

    tabbedWindow:deactivateTab(buyTab)

    Consumer.trader.guiInitialized = 1

    invokeServerFunction("sendName")
    Consumer.requestGoods()

end

function Consumer.sendName()
    invokeClientFunction(Player(callingPlayer), "receiveName", Consumer.consumerName)
end

function Consumer.receiveName(name)
    window.caption = name%_t
end

function Consumer.onShowWindow()
    Consumer.requestGoods()
end

function Consumer.getUpdateInterval()
    return 5
end

function Consumer.updateServer(timeStep)
    Consumer.useUpBoughtGoods(timeStep)
    Consumer.updateOrganizeGoodsBulletins(timeStep)
end

return Consumer
