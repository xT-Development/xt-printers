local db = lib.require('modules.server.db')

local printers_storage = {}

-- check if printer has enough paper and ink
function printers_storage.hasRequired(printer, copies)
    if not printer then return end

    local hasInk = printer.storage.ink >= copies
    local hasPaper = printer.storage.paper >= copies

    return (hasInk and hasPaper)
end

-- update printer storage
function printers_storage.updateStorage(printer, copies)
    if not printer then return end

    local newInk = printer.storage.ink - copies
    local newPaper = printer.storage.paper - copies

    if newInk < 0 then
        newInk = 0
    end

    if newPaper < 0 then
        newPaper = 0
    end

    db.updateStorage(printer.id, newInk, newPaper)
end

return printers_storage