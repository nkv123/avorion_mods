package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("stringutility")
require ("faction")
require ("player")
require ("merchantutility")

local availableCrewMembers = 0;
local slider = 0;
local membersLabel = 0;
local placesLabel = 0;
local priceLabel = 0;
local costPerMember = 0;
local uiGroups = {}

local availableCrew = {}

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace CrewBoard
CrewBoard = {}

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function CrewBoard.interactionPossible(playerIndex, option)
    local player = Player(playerIndex)
    local ship = player.craft
    if not ship then return false end
    if not ship:hasComponent(ComponentType.Crew) then return false end
    if Player(playerIndex).craftIndex == Entity().index then return false end

    return CheckFactionInteraction(playerIndex, -25000)
end

-- this function gets called on creation of the entity the script is attached to, on client and server
function CrewBoard.initialize()
    if onServer() then

        local scaling = 1
        if Server().infiniteResources then
            scaling = 50
        else
            local x, y = Sector():getCoordinates()

            local d = length(vec2(x, y))
            scaling = 1 + ((1 - (d / 450)) * 5)
        end

        scaling = math.max(1, scaling)

        local probabilities = {}
        table.insert(probabilities, {profession = CrewProfessionType.None, probability = 1.0, number = math.floor(math.random(30, 40) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.Engine, probability = 0.5, number = math.floor(math.random(5, 15) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.Repair, probability = 0.5, number = math.floor(math.random(5, 15) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.Gunner, probability = 0.5, number = math.floor(math.random(5, 10) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.Miner, probability = 0.5, number = math.floor(math.random(5, 10) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.Pilot, probability = 0.5, number = math.floor(math.random(3, 10) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.Security, probability = 0.4, number = math.floor(math.random(3, 10) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.Attacker, probability = 0.25, number = math.floor(math.random(3, 10) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.Sergeant, probability = 0.4, number = math.floor(math.random(4, 10) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.Lieutenant, probability = 0.3, number = math.floor(math.random(4, 7) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.Commander, probability = 0.25, number = math.floor(math.random(3, 5) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.General, probability = 0.15, number = math.floor(math.random(1, 2) * scaling)})
        table.insert(probabilities, {profession = CrewProfessionType.Captain, probability = 0.75, number = math.random(1, 2)})

        local station = Entity()
        -- crew for specific stations
        if station:hasScript("shipyard.lua") or
                station:hasScript("repairdock.lua") then
            CrewBoard.setProbability(probabilities, CrewProfessionType.Repair)
            CrewBoard.setProbability(probabilities, CrewProfessionType.Engine)
        elseif station:hasScript("militaryoutpost.lua") then
            CrewBoard.setProbability(probabilities, CrewProfessionType.Gunner)
            CrewBoard.setProbability(probabilities, CrewProfessionType.Lieutenant)
            CrewBoard.setProbability(probabilities, CrewProfessionType.Commander)
            CrewBoard.setProbability(probabilities, CrewProfessionType.General)
            CrewBoard.setProbability(probabilities, CrewProfessionType.Pilot)
        elseif station:hasScript("researchstation.lua") or
                station:hasScript("turretfactory.lua") or
                station:hasScript("fighterfactory.lua") then
            CrewBoard.setProbability(probabilities, CrewProfessionType.Engine)
            CrewBoard.setProbability(probabilities, CrewProfessionType.Gunner)

            if station:hasScript("fighterfactory.lua") then
                CrewBoard.setProbability(probabilities, CrewProfessionType.Pilot)
            end
        elseif station:hasScript("headquarters.lua") then
            CrewBoard.setProbability(probabilities, CrewProfessionType.Captain)
            CrewBoard.setProbability(probabilities, CrewProfessionType.General)
            CrewBoard.setProbability(probabilities, CrewProfessionType.Commander)
        elseif station:hasScript("planetarytradingpost.lua") then
            CrewBoard.setProbability(probabilities, CrewProfessionType.Pilot)
        elseif station:hasScript("tradingpost.lua") then
            CrewBoard.setProbability(probabilities, CrewProfessionType.None)
            CrewBoard.setProbability(probabilities, CrewProfessionType.Security)
        elseif station:hasScript("equipmentdock.lua") then
            CrewBoard.setProbability(probabilities, CrewProfessionType.Gunner)
            CrewBoard.setProbability(probabilities, CrewProfessionType.Miner)
            CrewBoard.setProbability(probabilities, CrewProfessionType.Pilot)
        elseif station:hasScript("smugglersmarket.lua") then
            CrewBoard.setProbability(probabilities, CrewProfessionType.Security)
        elseif string.match(station.title, " Mine") then
            CrewBoard.setProbability(probabilities, CrewProfessionType.Miner)
        end

        -- first insert all with probability >= 1
        for _, crew in pairs(probabilities) do
            if crew.probability >= 1.0 and #availableCrew < 6 then
                table.insert(availableCrew, crew)
            end
        end

        for _, crew in pairs(probabilities) do
            if crew.probability < 1.0 and math.random() < crew.probability and #availableCrew < 6 then
                table.insert(availableCrew, crew)
            end
        end
    end
end

function CrewBoard.setProbability(probabilities, profession, p)
    if not p then p = 1 end

    for _, crew in pairs(probabilities) do
        if crew.profession == profession then
            crew.probability = p
            return
        end
    end
end

-- this function gets called on creation of the entity the script is attached to, on client only
-- AFTER initialize above
-- create all required UI elements for the client side
function CrewBoard.initUI()

    local res = getResolution()

    local size = vec2(870, 300)


    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(window, "Hire Crew"%_t);

    window.caption = "Hire Crew"%_t
    window.showCloseButton = 1
    window.moveable = 1

    local frame = Rect(vec2(0, 10), size)

    local hsplit = UIHorizontalMultiSplitter(frame, 10, 10, 6)

    local padding = 15
    local iconSize = 30
    local barSize = 185
    local sliderSize = 350
    local priceSize = 70
    local buttonSize = 150

    local iconX = 15
    local barX = iconX + iconSize + padding
    local sliderX = barX + barSize + padding
    local priceX = sliderX + sliderSize + padding
    local buttonX = priceX + priceSize + padding

    for i = 0, 6 do
        local rect = hsplit:partition(i)

        local pic = window:createPicture(Rect(iconX, rect.lower.y, iconX + iconSize, rect.upper.y), "")
        local bar = window:createNumbersBar(Rect(barX, rect.lower.y, barX + barSize, rect.upper.y))
        local slider = window:createSlider(Rect(sliderX, rect.lower.y, sliderX + sliderSize, rect.upper.y), 0, 15, 15, "", "updatePrice");
        local label = window:createLabel(vec2(priceX, rect.lower.y + 4), "", 16)
        local button = window:createButton(Rect(buttonX, rect.lower.y, buttonX + buttonSize, rect.upper.y), "Hire"%_t, "onHireButtonPressed");

        local hide = function (self)
            self.bar:hide()
            self.pic:hide()
            self.slider:hide()
            self.label:hide()
            self.button:hide()
        end

        local show = function (self)
            self.bar:show()
            self.pic:show()
            self.slider:show()
            self.label:show()
            self.button:show()
        end

        table.insert(uiGroups, {pic=pic, bar=bar, slider=slider, label=label, button=button, show=show, hide=hide})

    end

    CrewBoard.retrieveData()
end

function CrewBoard.updatePrice(slider)
    local num = slider.value

    local costs = costPerMember * num * GetFee(Faction(), Player())

    for i, group in pairs(uiGroups) do
        if group.slider.index == slider.index then

            group.label.caption = round(CrewProfession(availableCrew[i].profession).price * group.slider.value) .. "$"
        end
    end

    -- if costs > 0 then
        -- priceLabel.caption = "$".. createMonetaryString(round(costs, 0))
    -- else
        -- priceLabel.caption = ""
    -- end
end

function CrewBoard.retrieveData()
    invokeServerFunction("sendDataToClient", Player().index);
end

-- called on client
function CrewBoard.setData(available)
    availableCrew = available
    CrewBoard.refreshUI()
end

function CrewBoard.refreshUI()
    local ship = Player().craft

    if ship.maxCrewSize == nil or ship.crewSize == nil then
        return
    end

    local placesOnShip = ship.maxCrewSize - ship.crewSize

    for _, group in pairs(uiGroups) do
        group:hide()
    end

    for i, pair in pairs(availableCrew) do
        local profession = CrewProfession(pair.profession)
        local number = pair.number

        local group = uiGroups[i]
        group:show()

        group.pic.isIcon = 1
        group.pic.picture = profession.icon
        group.pic.tooltip = profession.name .. "\n" .. profession.description

        group.bar:clear()
        group.bar:setRange(0, 40)
        group.bar:addEntry(number, tostring(number) .. " " .. profession.plural, profession.color)
        group.bar.tooltip = profession.name .. "\n" .. profession.description

        group.slider:setValueNoCallback(0)
        group.slider.min = 0
        group.slider.max = number
        group.slider.segments = number

        if pair.profession == CrewProfessionType.Captain then
            group.slider.max = 1
            group.slider.segments = 1
        end
    end

end

function CrewBoard.onHireButtonPressed(button)
    for i, group in pairs(uiGroups) do
        if group.button.index == button.index then
            local num = group.slider.value
            invokeServerFunction("hireCrew", i, num)
        end
    end
end

-- this function gets called every time the window is shown on the client, ie. when a player presses F and if interactionPossible() returned 1
function CrewBoard.onShowWindow()
    CrewBoard.retrieveData()
end


function CrewBoard.sendDataToClient(playerIndex)
    invokeClientFunction(Player(playerIndex), "setData", availableCrew)
end

function CrewBoard.hireCrew(i, num)

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources)
    if not buyer then return end

    local pair = availableCrew[i]
    local profession = CrewProfession(pair.profession)

    local station = Entity()
    local stationFaction = Faction()

    local costs = profession.price * num

    -- reduce the price right away if the buyer owns the station
    local tax = round(costs * 0.2)
    if stationFaction.index == buyer.index then
        costs = costs - tax
        -- don't pay out for the second time
        tax = 0
    end

    local canPay, msg, args = buyer:canPay(costs)
    if not canPay then
        player:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    local canHire, msg, args = ship:canAddCrew(num, pair.profession, 0)
    if not canHire then
        player:sendChatMessage(station.title, 1, msg, unpack(args))
        return
    end

    local errors = {}
    errors[EntityType.Station] = "You must be docked to the station to hire crewmembers."%_T
    errors[EntityType.Ship] = "You must be closer to the ship to hire crewmembers."%_T
    if not CheckPlayerDocked(player, station, errors) then
        return
    end

    receiveTransactionTax(station, tax)

    buyer:pay("Paid %1% credits to hire crew."%_T, costs);

    ship:addCrew(num, CrewMan(profession, profession ~= CrewProfessionType.None, 1));

    pair.number = pair.number - num

    invokeClientFunction(player, "setData", availableCrew)
end

---- this function gets called every time the window is closed on the client
--function onCloseWindow()
--
--end
--
---- this function gets called once each frame, on client and server
--function update(timeStep)
--
--end
--
---- this function gets called once each frame, on client only
--function updateClient(timeStep)
--
--end
--
---- this function gets called once each frame, on server only
--function updateServer(timeStep)
--
--end
--
---- this function gets called whenever the ui window gets rendered, AFTER the window was rendered (client only)
--function renderUI()
--
--end




