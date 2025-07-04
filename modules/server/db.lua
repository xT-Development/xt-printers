local config = lib.require('configs.server')

local cachedPrinters = {}
local updatingPrinters = false

local strings = {
    GET_ALL_PRINTERS = 'SELECT * FROM `xt_printers`',
    NEW_PRINTER = 'INSERT INTO `xt_printers` (`model`, `coords`, `group`, `storage`, `public`) VALUES (?, ?, ?, ?, ?)',
    DELETE_PRINTER = 'DELETE FROM `xt_printers` WHERE `id` = ?',
    UPDATE_STORAGE = 'UPDATE `xt_printers` SET `storage` = ? WHERE `id` = ?',
    DELETE_PRINTER_STASH = 'DELETE FROM `ox_inventory` WHERE `name` = ?'
}

local function cachePrinters()
    local getPrinters = MySQL.query.await(strings.GET_ALL_PRINTERS)
    if not getPrinters and not getPrinters[1] then
        cachedPrinters = {}
    end

    lib.print.info(getPrinters)

    for x = 1, #getPrinters do
        local printergroup = getPrinters[x].group
        local decodeCoords = json.decode(getPrinters[x].coords)
        local coords = vec4(decodeCoords.x, decodeCoords.y, decodeCoords.z, decodeCoords.w)

        cachedPrinters[getPrinters[x].id] = {
            id = getPrinters[x].id,
            model = getPrinters[x].model,
            coords = coords,
            group = printergroup,
            storage = json.decode(getPrinters[x].storage) or {
                ink = 0,
                paper = 0
            },
            public = (getPrinters[x].public == 1)
        }

        exports.ox_inventory:RegisterStash(('printer_%s'):format(getPrinters[x].id), 'Printer Stash', config.printerStashes.slots, config.printerStashes.weight, nil, false, coords.xyz)
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    cachePrinters()
end)

local db = {}

-- get all printers
function db.getPrinters()
    return cachedPrinters
end

-- add printer
function db.addPrinter(info)
    local coords = {
        x = info.coords.x,
        y = info.coords.y,
        z = info.coords.z,
        w = info.heading
    }

    local id = MySQL.insert.await(strings.NEW_PRINTER, {
        info.model, json.encode(coords), info.group, json.encode({ paper = 10, ink = 100 }), info.public
    })

    if not id then
        return
    end

    local printergroup = info.group
    local coords = vec4(coords.x, coords.y, coords.z, coords.w)
    local data = {
        id = id,
        model = info.model,
        coords = coords,
        group = printergroup,
        storage = { paper = 10, ink = 100 },
        public = info.public
    }

    cachedPrinters[id] = data

    exports.ox_inventory:RegisterStash(('printer_%s'):format(id), 'Printer Stash', config.printerStashes.slots, config.printerStashes.weight, nil, false, coords.xyz)

    TriggerClientEvent('xt-printers:client:newPrinter', -1, data)

    return true, id
end

-- remove printer by id
function db.removePrinter(id)
    id = type(id) ~= "number" and tonumber(id) or id

    if not cachedPrinters[id] then
        return
    end

    local removed = MySQL.query.await(strings.DELETE_PRINTER, { id })
    if not removed then
        return
    end

    MySQL.query.await(strings.DELETE_PRINTER_STASH, { id })

    cachedPrinters[id] = nil

    TriggerClientEvent('xt-printers:client:deletePrinter', -1, id)

    return true
end

-- get printer by id
function db.getPrinterById(id)
    return cachedPrinters[id] or false
end

-- get printer by job
function db.getPrintersByJob(job)
    local printersByJob = {}

    for id, info in pairs(cachedPrinters) do
        if info.group == job then
            printersByJob[#printersByJob + 1] = info
            break
        end
    end

    return printersByJob
end

-- newInk = number, newPaper = number
function db.updateStorage(id, newInk, newPaper)
    if not cachedPrinters[id] then return end

    cachedPrinters[id].storage = {
        ink = newInk,
        paper = newPaper
    }
end

-- storageType = "paper" or "ink"
function db.setStorageByType(id, storageType, amount)
    if not cachedPrinters[id] then return end

    cachedPrinters[id].storage[storageType] = amount
end

-- save all printers storage on resource stop
function db.saveAllPrinters()
    if not cachedPrinters or not next(cachedPrinters) then return end

    for id, info in pairs(cachedPrinters) do
        local storage = json.encode(info.storage)
        MySQL.update(strings.UPDATE_STORAGE, { storage, id })
    end
end

return db