local config            = lib.require('configs.client')
local MENUS             = lib.require('modules.client.menus')
local PRINTER_UTILS     = lib.require('modules.client.printers')

-- item export for documents
exports('printerdocument', function(data, slot)
    if slot.metadata and not slot.metadata.imagelink then return end

    config.viewDocument(slot.metadata.imagelink)
end)

-- open printer menu
RegisterNetEvent('xt-printers:client:openMenu', function(data)
    if GetInvokingResource() then return end

    MENUS.printersMenu()
end)

-- create/remove printer
RegisterNetEvent('xt-printers:client:newPrinter', function(data)
    if GetInvokingResource() then return end

    PRINTER_UTILS.createPrinter(data.id, data.model, data.coords.xyz, data.coords.w, data.group, data.public)
end)

-- remove printer
RegisterNetEvent('xt-printers:client:deletePrinter', function(id)
    if GetInvokingResource() then return end

    PRINTER_UTILS.removePrinter(id)
end)

-- handlers
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() or not NetworkIsPlayerConnected(cache.playerId)then return end

    Wait(500)
    PRINTER_UTILS.createAllPrinters()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    PRINTER_UTILS.removeAllPrinters()
end)

AddEventHandler('Renewed-Lib:client:PlayerLoaded', function(player)
    Wait(500)
    PRINTER_UTILS.createAllPrinters()
end)

AddEventHandler('Renewed-Lib:client:PlayerUnloaded', function(resource)
    PRINTER_UTILS.removeAllPrinters()
end)