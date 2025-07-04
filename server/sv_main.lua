local shared    = lib.require('configs.shared')
local UTILS     = lib.require('modules.server.utils')
local DB        = lib.require('modules.server.db')
local STORAGE   = lib.require('modules.server.storage')

local completedPrints = {}

-- get ink and paper
lib.callback.register('xt-printers:server:getPrinterStorage', function(source, id)
    local hasAllowedJob, job = UTILS.hasAllowedJob(source)
    if not hasAllowedJob then return end

    local printer = DB.getPrinterById(id)
    if not printer then return end

    return printer.storage
end)

-- refill printer paper or ink
lib.callback.register('xt-printers:server:refillPrinter', function(source, id, storageType)
    local hasAllowedJob, job = UTILS.hasAllowedJob(source)
    if not hasAllowedJob then return end

    local printer = DB.getPrinterById(id)
    if not printer then return end

    local item = 'printerink'
    local setAmount = 100
    local removeAmount = 1

    if storageType == 'paper' then
        if printer.storage.paper >= shared.maxPaper then
            lib.notify(source, {
                title = 'Paper is Full',
                description = 'The printer paper is already full!',
                type = 'error'
            })
            return false
        end

        item = 'printerpaper'
        local paperCount = exports.ox_inventory:GetItemCount(source, item)
        setAmount = (printer.storage.paper + paperCount)

        if setAmount > shared.maxPaper then
            setAmount = shared.maxPaper
        end

        removeAmount = (setAmount - printer.storage.paper)
    else
        if printer.storage.ink > 0 then
            lib.notify(source, {
                title = 'Ink is not empty!',
                description = 'The ink cartridge needs to be compeltely empty before replacing!',
                type = 'error'
            })
            return false
        end
    end

    -- remove item and set stroage values
    if exports.ox_inventory:RemoveItem(source, item, removeAmount) then
        DB.setStorageByType(id, storageType, setAmount)

        return true, removeAmount
    else
        lib.notify(source, {
            title = 'Missing Items!',
            type = 'error'
        })
    end

    return false
end)

-- check if printer has enough ink/paper
lib.callback.register('xt-printers:server:canPrint', function(source, id, copies)
    local printer = DB.getPrinterById(id)
    if not printer then return end

    if not printer.public then
        local hasAllowedJob, job = UTILS.hasAllowedJob(source)
        if not hasAllowedJob then return end
    end

    local canPrint = STORAGE.hasRequired(printer, copies)
    if not canPrint then return end

    STORAGE.updateStorage(printer, copies) -- Remove ink/paper now

    return true
end)

-- all printers
lib.callback.register('xt-printers:server:getAllPrinters', function(_)
    return DB.getPrinters()
end)

-- get printers by job
lib.callback.register('xt-printers:server:getPrintersByJob', function(source)
    local hasAllowedJob, job = UTILS.hasAllowedJob(source)
    if not hasAllowedJob then return end

    return DB.getPrintersByJob(job)
end)

-- new printer
lib.callback.register('xt-printers:server:createPrinter', function(source, info)
    local hasAllowedJob = UTILS.hasAllowedJob(source, info.group)
    if not hasAllowedJob then return end

    return DB.addPrinter(info)
end)

-- delete printer
lib.callback.register('xt-printers:server:deletePrinter', function(source, id)
    local printer = DB.getPrinterById(id)
    if not printer then return end

    local hasAllowedJob = UTILS.hasAllowedJob(source, printer.group)
    if not hasAllowedJob then return end

    return DB.removePrinter(id)
end)

-- get completed prints
lib.callback.register('xt-printers:server:getCompletedPrints', function(source, id)
    if not completedPrints[id] then
        lib.notify(source, {
            title = 'Empty Tray!',
            description = 'There are no completed prints here!',
            type = 'error',
        })
        return
    end

    if completedPrints[id][source] then
        local info = completedPrints[id][source]
        if exports.ox_inventory:AddItem(source, 'printerdocument', info[4] or 1, { label = info[1], description = info[2], imagelink = info[3] }) then

            completedPrints[id][source] = nil

            return true
        end
    else
        lib.notify(source, {
            title = 'You do not have any completed prints here!',
            type = 'error',
        })
    end

    return false
end)

-- print complete
lib.callback.register('xt-printers:server:completePrint', function(source, info, id)
    local printer = DB.getPrinterById(id)
    if not printer then return end

    local callback = false
    local dist = UTILS.distanceCheck(source, printer.coords)
    if dist then
        if exports.ox_inventory:AddItem(source, 'printerdocument', info[4] or 1, { label = info[1], description = info[2], imagelink = info[3] }) then
            callback = true
        end
    else
        if not completedPrints[id] then
            completedPrints[id] = {}
        end

        completedPrints[id][source] = info

        callback = true
    end

    return callback
end)

-- ensure only printer docs go into printer stashes
local printerStashHook = exports.ox_inventory:registerHook('swapItems', function(payload)
    if not payload.fromSlot then return end

    local item = payload.fromSlot.name
    if item == 'printerdocument' or item == 'printerpaper' then
        return true
    end

    return false
end, {
    print = false,
    inventoryFilter = {
        '^printer_[%w]+',
    }
})

lib.addCommand('printers', {
    help = 'Add/Remove Printers',
}, function(source, args, raw)
    if not UTILS.hasAllowedJob(source) then return end

    TriggerClientEvent('xt-printers:client:openMenu', source)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    DB.saveAllPrinters()
    exports.ox_inventory:removeHooks(printerStashHook)
end)