package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/entity/?.lua"

require ("randomext")
local DockAI = require ("ai/dock")

local stationIndex
local script
local stage
local waitCount
local tractorWaitCount

function getStationIndex()
    return stationIndex
end

function getUpdateInterval()
    return 2
end

function restore(values)
    stationIndex = Uuid(values.stationIndex)
    script = values.script
    stage = values.stage
    waitCount = values.waitCount

    DockAI.restore(values)
end

function secure()
    local values =
    {
        stationIndex = stationIndex.string,
        script = script,
        stage = stage,
        waitCount = waitCount,
    }

    DockAI.secure(values)

    return values
end

function initialize(stationIndex_in, script_in)
    stationIndex = stationIndex_in
    script = script_in
end

function onTradingFinished(ship)
end

function updateServer(timeStep)

    local ship = Entity()

    local station = Entity(stationIndex)

    -- in case the station doesn't exist any more, leave the sector
    if not station then
        ship:addScript("ai/passsector.lua", random():getDirection() * 2000)
        terminate()
        return
    end

    local pos, dir = station:getDockingPositions()

    -- stages
    if not pos or not dir or not valid(station) then
        -- something is not right, abort
        onTradingFinished(ship)
    else
        stage = stage or 0

        -- stage 0 is flying towards the light-line
        if stage == 0 then
            local flyToDock, tractorActive = DockAI.flyToDock(ship, station)

            if flyToDock then
                stage = 2
            end

            if tractorActive then
                tractorWaitCount = tractorWaitCount or 0
                tractorWaitCount = tractorWaitCount + timeStep

                if tractorWaitCount > 2 * 60 then -- seconds
                    local docks = DockingPositions(station)

                    docks:stopDocking(ship)
                    onTradingFinished(ship)
                end
            end
        end

        -- stage 2 is waiting
        if stage == 2 then
            waitCount = waitCount or 0
            waitCount = waitCount + timeStep

            if waitCount > 40 then -- seconds waiting
                doTransaction(ship, station, script)
                -- fly away
                stage = 3
            end
        end

        -- fly back to the end of the lights
        if stage == 3 then
            if DockAI.flyAwayFromDock(ship, station) then
                onTradingFinished(ship)
            end
        end
    end
end
