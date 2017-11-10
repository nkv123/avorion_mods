package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")
require ("goods")
require ("randomext")
require ("merchantutility")
require ("stringutility")
local TradingAPI = require ("tradingmanager")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace SmugglersMarket
SmugglersMarket = {}
SmugglersMarket = TradingAPI:CreateNamespace()
SmugglersMarket.trader.tax = 0.2

local brandLines = {}
local playerCargos = {}

function SmugglersMarket.interactionPossible(playerIndex, option)
    return true
end

if onClient() then

local function generateInteractionText()
    local a = {
        "This is a free station, where everybody can mind his own business."%_t,
        "Best wares in the galaxy."%_t,
        "Welcome to the true, free market."%_t,
        "You'll find members for nearly everything on this station, if the coin is right."%_t,
    }
    local b = {
        "What do you want?"%_t,
        "If you get in trouble, it's your own fault."%_t,
        "Don't make any trouble."%_t,
        "I'm sure you'll find what you're looking for."%_t,
        "What's up?"%_t,
    }

    return randomEntry(random(), a) .. " " .. randomEntry(random(), b)
end

function SmugglersMarket.initialize()
    EntityIcon().icon = "data/textures/icons/pixel/crate.png"
    InteractionText().text = generateInteractionText()
end

end

function SmugglersMarket.initUI()

    local res = getResolution()
    local size = vec2(950, 600)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Smuggler's Market"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Sell Stolen Goods"%_t);

    -- create a tabbed window inside the main window
    local tabbedWindow = window:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create unbrand tab
    local brandTab = tabbedWindow:createTab("Unbrand"%_t, "data/textures/icons/domino-mask.png", "Unbrand Stolen Goods"%_t)

    local lister = UIVerticalLister(Rect(tabbedWindow.size), 5, 0)
    local rect = lister:placeCenter(vec2(lister.inner.width, 21))

    local split1, split2 = 640, 720
    local vasplit1 = UIArbitraryVerticalSplitter(rect, 10, 0, split1, split2)
    local vasplit2 = UIArbitraryVerticalSplitter(vasplit1:partition(0), 10, 0, 350, 390, 530)

    brandTab:createLabel(vasplit2:partition(0).lower + vec2(10, 0), "Name"%_t, 15)
    brandTab:createLabel(vasplit2:partition(2).lower + vec2(10, 0), "Price/u"%_t, 15)
    brandTab:createLabel(vasplit2:partition(3).lower + vec2(10, 0), "You"%_t, 15)


    brandLines = {}
    for i = 1, 14 do
        local line = {}
        local rect = lister:placeCenter(vec2(lister.inner.width, 30))

        local vasplit1 = UIArbitraryVerticalSplitter(rect, 10, 0, split1, split2)
        line.frame = brandTab:createFrame(vasplit1:partition(0))

        line.numbers = brandTab:createTextBox(vasplit1:partition(1), "", "")
        line.button = brandTab:createButton(vasplit1:partition(2), "Unbrand"%_t, "onUnbrandClicked")
        line.button.maxTextSize = 16

        local vasplit2 = UIArbitraryVerticalSplitter(vasplit1:partition(0), 10, 0, 350, 390, 530)

        line.name = brandTab:createLabel(vasplit2:partition(0).lower + vec2(10, 6), "Name"%_t, 15)
        line.icon = brandTab:createPicture(vasplit2:partition(1), "")
        line.price = brandTab:createLabel(vasplit2:partition(2).lower + vec2(10, 6), "560.501", 15)
        line.you = brandTab:createLabel(vasplit2:partition(3).lower + vec2(10, 6), "750", 15)

        line.icon.isIcon = 1
        line.numbers.clearOnClick = 1

        line.hide = function(self)
            self.frame:hide()
            self.numbers:hide()
            self.button:hide()
            self.name:hide()
            self.icon:hide()
            self.price:hide()
            self.you:hide()
        end

        line.show = function(show)
            show.frame:show()
            show.numbers:show()
            show.button:show()
            show.name:show()
            show.icon:show()
            show.price:show()
            show.you:show()
        end

        table.insert(brandLines, line)
    end

    -- create sell tab
    local sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/coins.png", "Sell Stolen Goods"%_t)
    SmugglersMarket.buildSellGui(sellTab)
    SmugglersMarket.trader.guiInitialized = true

    SmugglersMarket.setCrewInteractionThresholds()
end

function SmugglersMarket.setCrewInteractionThresholds()
    if onClient() then
        invokeServerFunction("setCrewInteractionThresholds")
    end

    Entity():invokeFunction("data/scripts/entity/crewboard.lua", "overrideRelationThreshold", -200000)
end

function SmugglersMarket.onShowWindow()
    local ship = Player().craft

    -- read cargos and sort
    local cargos = {}
    for good, amount in pairs(ship:getCargos()) do
        table.insert(cargos, {good = good, amount = amount})
    end

    function comp(a, b) return a.good.name < b.good.name end
    table.sort (cargos, comp)

    for _, line in pairs(SmugglersMarket.trader.boughtLines) do
        line:hide();
        line.number.text = "0"
    end
    for _, line in pairs(brandLines) do
        line:hide();
        line.numbers.text = "0"
    end

    SmugglersMarket.trader.boughtGoods = {}
    local boughtGoods = SmugglersMarket.trader.boughtGoods
    local i = 1
    for _, p in pairs(cargos) do
        local good, amount = p.good, p.amount
        if i > #SmugglersMarket.trader.boughtLines then break end
        if i > #brandLines then break end

        if good.stolen then
            -- do sell lines
            local line = SmugglersMarket.trader.boughtLines[i]
            line:show()
            line.icon.picture = good.icon
            line.name.caption = good.displayName
            line.price.caption = createMonetaryString(round(good.price * 0.25))
            line.size.caption = round(good.size, 2)
            line.you.caption = amount
            line.stock.caption = "   -"

            boughtGoods[i] = good

            -- do unbranding lines
            local line = brandLines[i]

            line:show()
            line.icon.picture = good.icon
            line.name.caption = good.displayName
            line.price.caption = createMonetaryString(round(good.price * 0.5))
            line.you.caption = amount

            i = i + 1
        end
    end
end

function SmugglersMarket.onSellTextEntered(textBox)
    local self = SmugglersMarket.trader

    local enteredNumber = tonumber(textBox.text)
    if enteredNumber == nil then
        enteredNumber = 0
    end

    local newNumber = enteredNumber

    local goodIndex = nil
    for i, line in pairs(self.boughtLines) do
        if line.number.index == textBox.index then
            goodIndex = i
            break
        end
    end
    if goodIndex == nil then return end

    local good = self.boughtGoods[goodIndex]
    if not good then
        print ("good with index " .. goodIndex .. " isn't bought")
        printEntityDebugInfo();
        return
    end

    local ship = Player().craft
    local msg

    -- make sure the player does not sell more than he has in his cargo bay
    local amountOnPlayerShip = ship:getCargoAmount(good)
    if amountOnPlayerShip == nil then return end --> no cargo bay

    if amountOnPlayerShip < newNumber then
        newNumber = amountOnPlayerShip
        if newNumber == 0 then
            msg = "You don't have any of this!"%_t
        end
    end

    if msg then
        self:sendError(nil, msg)
    end

    -- maximum number of sellable things is the amount the player has on his ship
    if newNumber ~= enteredNumber then
        textBox.text = newNumber
    end
end

function SmugglersMarket.onSellButtonPressed(button)
    local self = SmugglersMarket.trader

    local shipIndex = Player().craftIndex
    local goodIndex = nil

    for i, line in ipairs(self.boughtLines) do
        if line.button.index == button.index then
            goodIndex = i
        end
    end

    if goodIndex == nil then
        return
    end

    local amount = self.boughtLines[goodIndex].number.text
    if amount == "" then
        amount = 0
    else
        amount = tonumber(amount)
    end

    local good = self.boughtGoods[goodIndex]
    if not good then
        print ("internal error, good with index " .. goodIndex .. " of sell button not found.")
        printEntityDebugInfo()
        return
    end

    invokeServerFunction("buyIllegalGood", good.name, amount, true, false, false)
end

function SmugglersMarket.buyIllegalGood(goodName, amount)
    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end

    local self = SmugglersMarket.trader

    -- check if the specific good from the player can be bought (ie. it's not illegal or something like that)
    local cargos = ship:findCargos(goodName)
    local good = nil
    local msg = "You don't have any %s that the station buys!"%_t
    local args = {goodName}

    for g, amount in pairs(cargos) do
        local ok
        ok, msg = self:isBoughtBySelf(g)
        args = {}
        if ok and g.stolen then
            good = g
            break
        end
    end

    msg = msg or "You don't have any %s that the station buys!"%_t
    if not good then
        self:sendError(buyer, msg, unpack(args))
        return
    end

    local station = Entity()
    local stationFaction = Faction()

    -- make sure the player does not sell more than he has in his cargo bay
    local amountOnShip = ship:getCargoAmount(good)

    if amountOnShip < amount then
        amount = amountOnShip

        if amountOnShip == 0 then
            self:sendError(buyer, "You don't have any %s on your ship"%_t, good.plural)
        end
    end

    if amount == 0 then
        return
    end

    -- begin transaction
    -- calculate price. if the seller is the owner of the station, the price is 0
    local price = self:getBuyPrice(good.name, buyer.index) * amount

    local canPay, msg, args = stationFaction:canPay(price);
    if not canPay then
        self:sendError(buyer, "This station's faction doesn't have enough money."%_t)
        return
    end

    if not noDockCheck then
        -- test the docking last so the player can know what he can buy from afar already
        local errors = {}
        errors[EntityType.Station] = "You must be docked to the station to trade."%_T
        errors[EntityType.Ship] = "You must be closer to the ship to trade."%_T
        if not CheckShipDocked(buyer, ship, station, errors) then
            return
        end
    end

    local x, y = Sector():getCoordinates()
    local fromDescription = "\\s(${x}:${y}) ${title} bought ${amount} ${plural} for ${credits} credits."%_T %
    {
        x = x,
        y = y,
        amount = amount,
        plural = good.plural,
        credits = createMonetaryString(price),
        title = station.title
    }

    local toDescription = "\\s(${x}:${y}): ${name} sold ${amount} ${plural} for ${credits} credits."%_T %
    {
        x = x,
        y = y,
        amount = amount,
        plural = good.plural,
        credits = createMonetaryString(price),
        name = ship.name,
    }

    -- give money to ship faction
    self:transferMoney(stationFaction, stationFaction, buyer, price, fromDescription, toDescription)

    -- remove goods from ship
    ship:removeCargo(good, amount)

    -- add goods to station
    self:increaseGoods(good.name, amount)

    -- trading (non-military) ships get higher relation gain
    local relationsChange = GetRelationChangeFromMoney(price)
    if ship:getNumArmedTurrets() <= 1 then
        relationsChange = relationsChange * 1.5
    end

    Galaxy():changeFactionRelations(buyer, stationFaction, relationsChange)

    invokeClientFunction(Player(callingPlayer), "onShowWindow")
end

function SmugglersMarket.onUnbrandClicked(button)
    local boughtGoods = SmugglersMarket.trader.boughtGoods

    for i, line in pairs(brandLines) do
        if line.button.index == button.index then
            invokeServerFunction("unbrand", boughtGoods[i].name, tonumber(line.numbers.text))
        end
    end
end

function SmugglersMarket.unbrand(goodName, amount)

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end

    local station = Entity()

    local cargos = ship:findCargos(goodName)
    local good = nil
    for g, cargoAmount in pairs(cargos) do
        if g.stolen then
            good = g
            amount = math.min(cargoAmount, amount)
            break
        end
    end

    if not good then
        SmugglersMarket.sendError(player, "You don't have any stolen %s!"%_t, goodName)
        return
    end

    local price = amount * round(good.price * 0.5)

    local canPay, msg, args = buyer:canPay(price)
    if not canPay then
        SmugglersMarket.sendError(player, msg, unpack(args))
        return
    end

    if not station:isDocked(ship) then
        SmugglersMarket.sendError(player, "You have to be docked to the station to unbrand goods!"%_t)
        return
    end

    -- pay and exchange
    receiveTransactionTax(station, price * SmugglersMarket.trader.tax)

    buyer:pay("Paid %1% credits to unbrand stolen goods."%_T, price)

    local purified = copy(good)
    purified.stolen = false

    ship:removeCargo(good, amount)
    ship:addCargo(purified, amount)

    invokeClientFunction(player, "onShowWindow")
end

function SmugglersMarket.receiveGoods()
    SmugglersMarket.onShowWindow()
end

function SmugglersMarket.trader:isBoughtBySelf(good)
    local original = goods[good.name]
    if not original then
        return false, "You can't sell ${displayPlural} here."%_t % good
    end

    return true
end

SmugglersMarket.oldBuyFromShip = SmugglersMarket.buyFromShip
function SmugglersMarket.buyFromShip(...)
    SmugglersMarket.oldBuyFromShip(...)
    invokeClientFunction(Player(callingPlayer), "onShowWindow")
end

-- price for which goods are bought from players
function SmugglersMarket.trader:getBuyPrice(goodName)
    local good = goods[goodName]
    if not good then return 0 end

    return round(good.price * 0.15)
end

--function onSellTextEntered()
--
--end

