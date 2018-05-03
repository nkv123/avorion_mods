
package.path = package.path .. ";data/scripts/lib/?.lua;"
package.path = package.path .. ";data/scripts/?.lua;"

local SectorSpecifics = require ("sectorspecifics")
local Balancing = require ("galaxy")
local Dialog = require("dialogutility")
require ("stringutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace MilitaryOutpost
MilitaryOutpost = {}

function MilitaryOutpost.initialize()
    if onServer() and Entity().title == "" then
        Entity().title = "Military Outpost"%_t
    end

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/military.png"
        InteractionText().text = Dialog.generateStationInteractionText(Entity(), random())
    end
end

function MilitaryOutpost.getUpdateInterval()
    return 1
end

function MilitaryOutpost.updateServer(timeStep)
    MilitaryOutpost.updateBulletins(timeStep)
end


local r = Random(Seed(os.time()))

local updateFrequency
local updateTime

function MilitaryOutpost.updateBulletins(timeStep)
    if not updateFrequency then
        -- more frequent updates when there are more ingredients
        updateFrequency = 60 * 60
    end

    if not updateTime then
        -- by adding half the time here, we have a chance that a factory immediately has a bulletin
        updateTime = 0

        local minutesSimulated = r:getInt(10, 80)
        minutesSimulated = 70
        for i = 1, minutesSimulated do -- simulate bulletin posting / removing
            MilitaryOutpost.updateBulletins(60)
        end
    end

    updateTime = updateTime + timeStep

    -- don't execute the following code if the time hasn't exceeded the posting frequency
    if updateTime < updateFrequency then return end
    updateTime = updateTime - updateFrequency

    local clear = MilitaryOutpost.getClear()
    if not clear then return end

    local explore = MilitaryOutpost.getExplore()
    if not explore then return end

    -- since in this case "add" can override "remove", adding a bulletin is slightly more probable
    local add = r:getFloat() < 0.5
    local remove = r:getFloat() < 0.5

    if not add and not remove then
        if r:getFloat() < 0.5 then
            add = true
        else
            remove = true
        end
    end

    if add then
        -- randomly add bulletins
        local choice = math.random(1,2)
        if choice == 1 then
            Entity():invokeFunction("bulletinboard", "postBulletin", clear)
        elseif choice == 2 then
            Entity():invokeFunction("bulletinboard", "postBulletin", explore)
        end

    elseif remove then
        -- randomly remove bulletins
        local choice = math.random(1,2)
        if choice == 1 then
            Entity():invokeFunction("bulletinboard", "removeBulletin", clear.brief)
        elseif choice == 2 then
            Entity():invokeFunction("bulletinboard", "removeBulletin", explore.brief)
        end
    end




end

function MilitaryOutpost.getExplore()
    return MilitaryOutpost.getExploreSectorBulletin()
end

function MilitaryOutpost.getClear()
    return MilitaryOutpost.getClearSectorBulletin()
end

function MilitaryOutpost.getExploreSectorBulletin()
    local specs = SectorSpecifics()
    local x, y = Sector():getCoordinates()
    local coords = specs.getShuffledCoordinates(random(), x, y, 10, 20)
    local serverSeed = Server().seed
    local target = nil

    for _, coord in pairs(coords) do
        local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, serverSeed)

        if not regular and offgrid and not blocked and not home then
            specs:initialize(coord.x, coord.y, serverSeed)

            --only sectors with containerfield, cultists, wreckage, pirates, resitance or smugglers should be used
            if specs.generationTemplate.path == "sectors/containerfield"
                or specs.generationTemplate.path == "sectors/cultists"
                or specs.generationTemplate.path == "sectors/functionalwreckage"
                or specs.generationTemplate.path == "sectors/pirateastroidfield"
                or specs.generationTemplate.path == "sectors/piratefight"
                or specs.generationTemplate.path == "sectors/piratestation"
                or specs.generationTemplate.path == "sectors/resitancecell"
                or specs.generationTemplate.path == "sectors/smugglerhideout"
                or specs.generationTemplate.path == "sectors/stationwreckage"
                or specs.generationTemplate.path == "sectors/wreckageastroidfield"
                or specs.generationTemplate.path == "sectors/wreckagefiled" then
                target = coord
            end
        end
    end

    if not target then return end

    local description = "We are interested in a nearby sector. We need someone to explore it in our name.\n\nSector: (${x} : ${y})"%_t

    reward = 20000 * Balancing.GetSectorRichnessFactor(Sector():getCoordinates())

    local bulletin =
    {
        brief = "Explore Sector"%_t,
        description = description,
        difficulty = "Easy /*difficulty*/"%_t,
        reward = "$${reward}",
        script = "missions/exploresector/exploresector.lua",
        arguments = {Entity().index, target.x, target.y, reward},
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "The sector is \\s(%i:%i)."%_T,
        entityTitle = Entity().title,
        entityTitleArgs = Entity():getTitleArguments(),
        onAccept = [[
            local self, player = ...
            local title = self.entityTitle % self.entityTitleArgs
            player:sendChatMessage(title, 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]]
    }

    return bulletin

end

function MilitaryOutpost.getClearSectorBulletin()

    -- find a sector that has pirates
    local specs = SectorSpecifics()
    local x, y = Sector():getCoordinates()
    local coords = specs.getShuffledCoordinates(random(), x, y, 2, 15)
    local serverSeed = Server().seed
    local target = nil

    for _, coord in pairs(coords) do
        local regular, offgrid, blocked, home = specs:determineContent(coord.x, coord.y, serverSeed)

        if offgrid and not blocked then
            specs:initialize(coord.x, coord.y, serverSeed)

            if specs.generationTemplate.path == "sectors/pirateasteroidfield" then
                if not Galaxy():sectorExists(coord.x, coord.y) then
                    target = coord
                    break
                end
            end
        end
    end

    if not target then return end

    local description = "A nearby sector has been occupied by pirates and they have been attacking our convoys and traders.\nWe cannot let that scum do whatever they like. We need someone to take care of them.\n\nSector: (${x} : ${y})"%_t

    reward = 50000 * Balancing.GetSectorRichnessFactor(Sector():getCoordinates())

    local bulletin =
    {
        brief = "Wipe out Pirates"%_t,
        description = description,
        difficulty = "Medium /*difficulty*/"%_t,
        reward = "$${reward}",
        script = "missions/clearsector.lua",
        arguments = {Entity().index, target.x, target.y, reward},
        formatArguments = {x = target.x, y = target.y, reward = createMonetaryString(reward)},
        msg = "Their location is \\s(%i:%i)."%_T,
        entityTitle = Entity().title,
        entityTitleArgs = Entity():getTitleArguments(),
        onAccept = [[
            local self, player = ...
            local title = self.entityTitle % self.entityTitleArgs
            player:sendChatMessage(title, 0, self.msg, self.formatArguments.x, self.formatArguments.y)
        ]]
    }

    return bulletin
end

