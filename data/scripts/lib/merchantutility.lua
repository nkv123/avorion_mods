package.path = package.path .. ";data/scripts/lib/?.lua"
require("stringutility")
require("utility")

function receiveTransactionTax(station, amount)
    if not amount then return end
    amount = round(amount)
    if amount == 0 then return end

    local stationOwner = Faction(station.factionIndex)
    local x, y = Sector():getCoordinates()

    if stationOwner then
        local msg = Format("\\s(%1%:%2%) %3%: Gained %4% credits transaction tax."%_T,
            x,
            y,
            station.title)

        stationOwner:receive(msg, amount)
    end

end
