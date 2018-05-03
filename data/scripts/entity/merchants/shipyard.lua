package.path = package.path .. ";data/scripts/lib/?.lua"
require ("utility")
require ("faction")
require ("defaultscripts")
require ("randomext")
require ("stationextensions")
require ("randomext")
require ("stringutility")
require ("merchantutility")
local Dialog = require("dialogutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace Shipyard
Shipyard = {}

-- Menu items
local window

-- ship building menu items
local planDisplayer
local singleBlockCheckBox
local stationFounderCheckBox
local insuranceCheckBox
local captainCheckBox
local styleCombo
local seedTextBox
local nameTextBox
local materialCombo
local volumeSlider
local scaleSlider

-- building ships
local styles = {}
local styleName
local seed = 0;
local volume = 150;
local scale = 1.0;
local material
local preview

local runningJobs = {}


function Shipyard.initialize()
    local station = Entity()

    if station.title == "" then
        station.title = "Shipyard"%_t

        if onServer() then
            local x, y = Sector():getCoordinates()
            local seed = Server().seed

            math.randomseed(Sector().seed + Sector().numEntities)
            addConstructionScaffold(station)
            math.randomseed(appTimeMs())
        end
    end

    if onServer() then
        Sector():registerCallback("onRestoredFromDisk", "onRestoredFromDisk")
    end

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/shipyard2.png"
        InteractionText(station.index).text = Dialog.generateStationInteractionText(station, random())
    end

end

function Shipyard.onRestoredFromDisk(timeSinceLastSimulation)
    Shipyard.update(timeSinceLastSimulation)
end

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function Shipyard.interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, -10000)
end

-- create all required UI elements for the client side
function Shipyard.initUI()

    local res = getResolution()
    local size = vec2(800, 600)

    local menu = ScriptUI()
    window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))

    window.caption = "Shipyard"%_t
    window.showCloseButton = 1
    window.moveable = 1
    menu:registerWindow(window, "Build Ship"%_t);

    local container = window:createContainer(Rect(vec2(0, 0), size));

    local vsplit = UIVerticalSplitter(Rect(vec2(0, 0), size), 10, 10, 0.5)
    vsplit:setRightQuadratic()

    local left = vsplit.left
    local right = vsplit.right

    container:createFrame(left);
    container:createFrame(right);

    local lister = UIVerticalLister(left, 10, 10)
    lister.padding = 20 -- add a higher padding as the slider texts might overlap otherwise

    scaleSlider = container:createSlider(Rect(), 0.2, 3.0, 3.0 / 0.2 * 99, "Scaling"%_t, "updatePlan")
    scaleSlider.value = 1.0;
    lister:placeElementCenter(scaleSlider)

    volumeSlider = container:createSlider(Rect(), 5.0, 1500.0, 1500 / 5 * 100, "Volume"%_t, "updatePlan");
    lister:placeElementCenter(volumeSlider)
    lister.padding = 10 -- set padding back to normal

    -- create check boxes
    singleBlockCheckBox = container:createCheckBox(Rect(), "Single Block"%_t, "onSingleBlockChecked")
    lister:placeElementCenter(singleBlockCheckBox)

    stationFounderCheckBox = container:createCheckBox(Rect(), "Station Founder"%_t, "")
    lister:placeElementCenter(stationFounderCheckBox)
    stationFounderCheckBox.tooltip = "The ship will be able to found stations."%_t

    insuranceCheckBox = container:createCheckBox(Rect(), "Insurance"%_t, "")
    lister:placeElementCenter(insuranceCheckBox)
    insuranceCheckBox.tooltip = "The ship will be insured and you will receive a loss payment if it gets destroyed."%_t

    captainCheckBox = container:createCheckBox(Rect(), "Crew + Captain"%_t, "")
    lister:placeElementCenter(captainCheckBox)
    captainCheckBox.tooltip = "Hire the crew for the ship as well."%_t

    insuranceCheckBox.checked = true
    captainCheckBox.checked = true

    styleCombo = container:createComboBox(Rect(), "onStyleComboSelect");
    lister:placeElementCenter(styleCombo)

    local l = container:createLabel(vec2(), "Seed"%_t, 14);
    l.size = vec2(0, 0)
    lister.padding = 0
    lister:placeElementCenter(l)
    lister.padding = 10

    -- make a seed text box with 2 quadratic buttons next to it
    local rect = lister:placeCenter(vec2(vsplit.left.width - 20, 30))
    local split = UIVerticalSplitter(rect, 5, 0, 0.5)
    split:setRightQuadratic();

    container:createButton(split.right, "-", "seedDecrease");

    local split = UIVerticalSplitter(split.left, 10, 0, 0.5)
    split:setRightQuadratic();

    container:createButton(split.right, "+", "seedIncrease");

    -- make the seed text box
    seedTextBox = container:createTextBox(split.left, "onSeedChanged");
    seedTextBox.text = seed

    materialCombo = container:createComboBox(Rect(), "onMaterialComboSelect");
    for i = 0, NumMaterials() - 1, 1 do
        materialCombo:addEntry(Material(i).name);
    end
    lister:placeElementCenter(materialCombo)

    -- text field for the name
    local l = container:createLabel(vec2(), "Name"%_t, 14);
    l.size = vec2(0, 0)
    lister.padding = 0
    lister:placeElementCenter(l)
    lister.padding = 10

    nameTextBox = container:createTextBox(Rect(), "")
    nameTextBox:forbidInvalidFilenameChars()
    nameTextBox.maxCharacters = 35
    lister:placeElementCenter(nameTextBox)

    -- check box for stats
    statsCheckBox = container:createCheckBox(Rect(), "Show Stats"%_t, "onStatsChecked")
    lister:placeElementCenter(statsCheckBox)
    statsCheckBox.checked = false

    -- button at the bottom
    local button = container:createButton(Rect(), "Build"%_t, "onBuildButtonPress");
    local organizer = UIOrganizer(left)
    organizer.padding = 10
    organizer.margin = 10
    organizer:placeElementBottom(button)

    -- create the viewer
    planDisplayer = container:createPlanDisplayer(vsplit.right);
    planDisplayer.showStats = 0

    -- request the styles
    invokeServerFunction("sendCraftStyles");

end

-- this function gets called every time the window is shown on the client, ie. when a player presses F
function Shipyard.onShowWindow()
    Shipyard.updatePlan()
end

---- this function gets called every time the window is closed on the client
--function onCloseWindow()
--
--end

--function updateClient(timeStep)
--
--end

--function updateServer(timeStep)
--
--end

function Shipyard.renderUIIndicator(px, py, size)

    local x = px - size / 2;
    local y = py + size / 2;

    for i, job in pairs(runningJobs) do

        -- outer rect
        local dx = x
        local dy = y + i * 5

        local sx = size + 2
        local sy = 4

        drawRect(Rect(dx, dy, sx + dx, sy + dy), ColorRGB(0, 0, 0));

        -- inner rect
        sx = sx - 2
        sy = sy - 2

        sx = sx * job.executed / job.duration

        drawRect(Rect(dx + 1, dy + 1, sx + dx + 1, sy + dy + 1), ColorRGB(0.66, 0.66, 1.0));
    end

end

function Shipyard.renderUI()

    local fee = GetFee(Faction(), Player()) * 2

    local planMoney = preview:getMoneyValue()

    local planResources = {preview:getResourceValue()}
    local planResourcesFee = {}
    local planResourcesTotal = {}

    -- insurance
    local insuranceMoney = 0
    if insuranceCheckBox.checked then
        insuranceMoney = Shipyard.getInsuranceMoney(preview)
    end

    -- crew
    local crewMoney = 0
    if captainCheckBox.checked then
        crewMoney = Shipyard.getCrewMoney(preview)
    end

    -- plan resources
    for i, v in pairs(planResources) do
        table.insert(planResourcesTotal, v)
    end

    local offset = 10
    offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Ship Costs"%_t, planMoney, planResources)
    offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Insurance"%_t, insuranceMoney)
    offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Crew"%_t, crewMoney)
    offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Fee"%_t, planMoney * fee, planResourcesFee)
    offset = offset + renderPrices(planDisplayer.lower + vec2(10, offset), "Total"%_t, planMoney + planMoney * fee + crewMoney + insuranceMoney, planResourcesTotal)
end

function Shipyard.updatePlan()

    -- just to make sure that the interface is completely created, this function is called during initialization of the GUI, and not everything may be constructed yet
    if materialCombo == nil then return end
    if singleBlockCheckBox == nil then return end
    if planDisplayer == nil then return end
    if volumeSlider == nil then return end
    if scaleSlider == nil then return end

    -- retrieve all settings
    material = materialCombo.selectedIndex;
    volume = volumeSlider.value;
    scale = scaleSlider.value;
    if scale <= 0.1 then scale = 0.1 end

    local seed = seedTextBox.text

    if singleBlockCheckBox.checked then
        preview = BlockPlan()

        -- create a white plating block with size 1, 1, 1 and the selected material at the center of the new plan
        preview:addBlock(vec3(0, 0, 0), vec3(1, 1, 1), -1, -1, ColorRGB(1, 1, 1), Material(material), Matrix(), BlockType.Hull)
    else
        styleName = styleCombo.selectedEntry;

        local style = styles[styleName]
        if style == nil then
            preview = BlockPlan()
        else
            -- generate the preview plan
            preview = GeneratePlanFromStyle(style, Seed(seed), volume, 2000, 1, Material(material))
        end
    end

    preview:scale(vec3(scale, scale, scale))

    -- set to display
    planDisplayer.plan = preview

end

function Shipyard.getInsuranceMoney(plan)
    local insuranceMoney = plan:getMoneyValue()
    for i, v in pairs({plan:getResourceValue()}) do
        insuranceMoney = insuranceMoney + Material(i - 1).costFactor * v * 10;
    end

    return math.floor(insuranceMoney * 0.3);
end

function Shipyard.getCrewMoney(plan)
    local crewMoney = 0

    local crew = Crew():buildMinimumCrew(plan)
    crew.maxSize = crew.maxSize + 1
    crew:add(1, CrewMan(CrewProfessionType.Captain, true, 1))

    for p, amount in pairs(crew:getMembers()) do
        local profession = CrewProfession(p)
        crewMoney = crewMoney + profession.price * amount
    end

    return crewMoney
end

function Shipyard.getRequiredMoney(plan, orderingFaction)
    local requiredMoney = plan:getMoneyValue();
    requiredMoney = requiredMoney

    local fee = GetFee(Faction(), orderingFaction) * 2
    fee = requiredMoney * fee
    requiredMoney = requiredMoney + fee

    return requiredMoney, fee
end

function Shipyard.getRequiredResources(plan, orderingFaction)
    return {plan:getResourceValue()}
end

function Shipyard.getRequiredMoneyTest(styleName, seed, volume, material, scale)
    local style = Faction():getShipStyle(styleName)
    plan = GeneratePlanFromStyle(style, Seed(seed), volume, 2000, 1, Material(material))

    plan:scale(vec3(scale, scale, scale))

    -- get the money required for the plan
    local buyer = Faction(Player(callingPlayer).craft.factionIndex)
    return Shipyard.getRequiredMoney(plan, buyer)
end

function Shipyard.getRequiredResourcesTest(styleName, seed, volume, material, scale)
    local style = Faction():getShipStyle(styleName)
    plan = GeneratePlanFromStyle(style, Seed(seed), volume, 2000, 1, Material(material))

    plan:scale(vec3(scale, scale, scale))

    -- get the money required for the plan
    local buyer = Faction(Player(callingPlayer).craft.factionIndex)
    local requiredResources = Shipyard.getRequiredResources(plan, buyer)

    for i = 1, NumMaterials() do
        requiredResources[i] = requiredResources[i] or 0
    end

    return unpack(requiredResources)
end

function Shipyard.transactionComplete()
    ScriptUI():stopInteraction()
end

-- this function gets called by the server to indicate that all data was sent
function Shipyard.receiveStyles(styles_received)

    styles = styles_received

    for name, style in pairsByKeys(styles) do
        styleCombo:addEntry(name)
    end

    styleCombo.selectedIndex = 0

    -- create a plan
    Shipyard.updatePlan();

end

function Shipyard.startClientJob(executed, duration)
    local job = {}
    job.executed = executed
    job.duration = duration

    table.insert(runningJobs, job)
end

function Shipyard.seedDecrease()
    local number = tonumber(seed) or 0
    Shipyard.setSeed(number - 1)
end

function Shipyard.seedIncrease()
    local number = tonumber(seed) or 0
    Shipyard.setSeed(number + 1)
end

function Shipyard.setSeed(newSeed)
    seed = newSeed
    seedTextBox.text = seed
    Shipyard.updatePlan();
end

function Shipyard.onSeedChanged()
    Shipyard.setSeed(seedTextBox.text);
end

function Shipyard.onSingleBlockChecked()
    Shipyard.updatePlan();
end

function Shipyard.onStyleComboSelect()
    Shipyard.updatePlan();
end

function Shipyard.onMaterialComboSelect()
    Shipyard.updatePlan();
end

function Shipyard.onStatsChecked(index, checked)
    if planDisplayer then
        planDisplayer.showStats = checked
    end
end

function Shipyard.onBuildButtonPress()

    -- check whether a ship with that name already exists
    local name = nameTextBox.text

    if name == "" then
        displayChatMessage("You have to give your ship a name!"%_t, "Shipyard"%_t, 1)
        return
    end

    if Player():ownsShip(name) then
        displayChatMessage("You already have a ship called '${x}'"%_t % {x = name}, "Shipyard"%_t, 1)
        return
    end

    local singleBlock = singleBlockCheckBox.checked
    local founder = stationFounderCheckBox.checked
    local insurance = insuranceCheckBox.checked
    local captain = captainCheckBox.checked
    local seed = seedTextBox.text

    invokeServerFunction("startServerJob", singleBlock, founder, insurance, captain, styleName, seed, volume, scale, material, name)

end


-- ######################################################################################################### --
-- ######################################        Common        ############################################# --
-- ######################################################################################################### --
function Shipyard.getUpdateInterval()
    return 1.0
end

function Shipyard.update(timeStep)
    for i, job in pairs(runningJobs) do
        job.executed = job.executed + timeStep

        if job.executed >= job.duration then

            if onServer() then
                local owner = Faction(job.shipOwner)

                if owner then
                    Shipyard.createShip(owner, job.singleBlock, job.founder, job.insurance, job.captain, job.styleName, job.seed, job.volume, job.scale, job.material, job.shipName)
                end
            end

            runningJobs[i] = nil
        end
    end
end


-- ######################################################################################################### --
-- ######################################     Server Sided     ############################################# --
-- ######################################################################################################### --
function Shipyard.startServerJob(singleBlock, founder, insurance, captain, styleName, seed, volume, scale, material, name)

    local buyer, ship, player = getInteractingFaction(callingPlayer, AlliancePrivilege.SpendResources, AlliancePrivilege.FoundShips)
    if not buyer then return end

    local stationFaction = Faction()
    local station = Entity()

    -- shipyard may only have x jobs
    if tablelength(runningJobs) >= 2 then
        player:sendChatMessage(station.title, 1, "The shipyard is already at maximum capacity."%_t)
        return 1
    end

    local settings = GameSettings()
    if settings.maximumPlayerShips > 0 and buyer.numShips >= settings.maximumPlayerShips then
        player:sendChatMessage("Server"%_t, 1, "Maximum ship limit per faction (%s) of this server reached!"%_t, settings.maximumPlayerShips)
        return
    end

    -- check if the player can afford the ship
    -- first create the plan
    local plan

    if singleBlock then
        plan = BlockPlan()
        plan:addBlock(vec3(0, 0, 0), vec3(2, 2, 2), -1, -1, ColorRGB(1, 1, 1), Material(material), Matrix(), BlockType.Hull)
    else
        local style = stationFaction:getShipStyle(styleName)
        plan = GeneratePlanFromStyle(style, Seed(seed), volume, 2000, 1, Material(material))
    end

    plan:scale(vec3(scale, scale, scale))

    -- get the money required for the plan
    local requiredMoney, fee = Shipyard.getRequiredMoney(plan, buyer)
    local requiredResources = Shipyard.getRequiredResources(plan, buyer)

    if insurance then
        requiredMoney = requiredMoney + Shipyard.getInsuranceMoney(plan)
    end

    if captain then
        requiredMoney = requiredMoney + Shipyard.getCrewMoney(plan)
    end

    -- check if the player has enough money & resources
    local canPay, msg, args = buyer:canPay(requiredMoney, unpack(requiredResources))
    if not canPay then -- if there was an error, print it
        player:sendChatMessage(station.title, 1, msg, unpack(args))
        return;
    end

    receiveTransactionTax(station, fee)

    -- let the player pay
    buyer:pay(requiredMoney, unpack(requiredResources))

    -- relations of the player to the faction owning the shipyard get better
    local relationsChange = GetRelationChangeFromMoney(requiredMoney)
    for i, v in pairs(requiredResources) do
        relationsChange = relationsChange + v / 4
    end

    Galaxy():changeFactionRelations(buyer, stationFaction, relationsChange)

    -- register the ship in the player's database
    -- The ship might get renamed in order to keep consistency in the database
    local cx, cy = Sector():getCoordinates()

    -- start the job
    local requiredTime = math.floor(20.0 + plan.durability / 100.0)

    if buyer.infiniteResources then
        requiredTime = 1.0
    end

    local job = {}
    job.executed = 0
    job.duration = requiredTime
    job.shipOwner = buyer.index
    job.styleName = styleName
    job.seed = seed
    job.scale = scale
    job.volume = volume
    job.material = material
    job.shipName = name
    job.singleBlock = singleBlock
    job.founder = founder
    job.insurance = insurance
    job.captain = captain

    table.insert(runningJobs, job)

    -- TODO: translation of time string
    player:sendChatMessage(station.title, 0, "Thank you for your purchase. Your ship will be ready in about %s."%_t, createReadableTimeString(requiredTime))

    -- tell all clients in the sector that production begins
    broadcastInvokeClientFunction("startClientJob", 0, requiredTime)

    -- this sends an ack to the client and makes it close the window
    invokeClientFunction(player, "transactionComplete")
end

function Shipyard.createShip(buyer, singleBlock, founder, insurance, captain, styleName, seed, volume, scale, material, name)

    local ownedShips = 0
    local player
    if buyer.isAlliance then
        ownedShips = Alliance(buyer.index).numShips
    elseif buyer.isPlayer then
        player = Player(buyer.index)
        ownedShips = player.numShips
    end

    local settings = GameSettings()
    if settings.maximumPlayerShips > 0 and ownedShips >= settings.maximumPlayerShips then
        if player then
            player:sendChatMessage("Server"%_t, 1, "Maximum ship limit per faction (%s) of this server reached!"%_t, settings.maximumPlayerShips)
        end
        return
    end

    local station = Entity()
    local stationFaction = Faction()

    local plan

    if singleBlock then
        plan = BlockPlan()
        plan:addBlock(vec3(0, 0, 0), vec3(2, 2, 2), -1, -1, ColorRGB(1, 1, 1), Material(material), Matrix(), BlockType.Hull)
    else
        local style = stationFaction:getShipStyle(styleName);
        plan = GeneratePlanFromStyle(style, Seed(seed), volume, 2000, 1, Material(material));
    end

    plan:scale(vec3(scale, scale, scale))

    -- use the same orientation as the station
    local position = station.orientation

    -- get a position to put the craft
    local sphere = station:getBoundingSphere()

    position.translation = sphere.center + random():getDirection() * (sphere.radius + plan.radius + 50);

    local ship = Sector():createShip(buyer, name, plan, position);

    -- add base scripts
    AddDefaultShipScripts(ship)

    if founder then
        ship:addScript("data/scripts/entity/stationfounder.lua")
    end

    if insurance then
        ship:addScript("data/scripts/entity/insurance.lua")
        ship:invokeFunction("data/scripts/entity/insurance.lua", "internalInsure")
    end

    if captain then
        -- add base crew
        local crew = ship.minCrew
        crew:add(1, CrewMan(CrewProfessionType.Captain, true, 1))

        ship.crew = crew
    end

end

-- sends all craft styles to a client
function Shipyard.sendCraftStyles()

    local player = Player(callingPlayer)
    local faction = Faction()
    local styleNames = {faction:getShipStyleNames()}
    local styles = {}

    for i, name in pairs(styleNames) do
        styles[name] = faction:getShipStyle(name)
    end

    invokeClientFunction(player, "receiveStyles", styles)

    for _, job in pairs(runningJobs) do
        invokeClientFunction(player, "startClientJob", job.executed, job.duration)
    end

end

function Shipyard.restore(data)
    runningJobs = data
end

function Shipyard.secure()
    return runningJobs
end

