local config        = lib.require('configs.client')
local UTILS         = lib.require('modules.client.utils')
local PRINTER_UTILS = lib.require('modules.client.printers')

local menus = {}

-- view all printers for job
function menus.viewPrinters()
    local printers = lib.callback.await('xt-printers:server:getPrintersByJob', false)
    if not printers or not printers[1] then return end

    local menuOptions = {}
    for x = 1, #printers do
        local printerInfo = printers[x]
        local printerStorage = printerInfo.storage

        local image

        for t = 1, #config.printerModels do
            if config.printerModels[t] == printers[x].model then
                image = ('https://gta-objects.xyz/gallery/objects/%s.jpg'):format(config.printerModels[t])
                break
            end
        end

        menuOptions[#menuOptions + 1] = {
            title = printerInfo.model,
            image = image,
            description = ('📄 Paper: %s  \n✒️ Ink: %s%%'):format(printerStorage.paper, printerStorage.ink),
            onSelect = function()
                local delete = lib.alertDialog({
                    header = 'Delete Printer?',
                    content = 'Are you sure you want to delete this printer?',
                    centered = true,
                    cancel = true,
                    labels = {
                        cancel = 'Go Back',
                        confirm = 'Delete Printer'
                    }
                }) if delete == 'cancel' then return end

                local deleted = lib.callback.await('xt-printers:server:deletePrinter', false, printerInfo.id)
                if not deleted then return end

                PRINTER_UTILS.removePrinter(printerInfo.id)

                lib.notify({
                    title = 'Printed Removed',
                    type = 'success'
                })
            end
        }
    end

    lib.registerContext({
        id = 'printer_model_select',
        title = 'Choose Printer Model',
        options = menuOptions
    })
    lib.showContext('printer_model_select')
end

-- choose printer model
function menus.choosePrinterModelMenu()
    local menuOptions = {}

    for x = 1, #config.printerModels do
        menuOptions[#menuOptions + 1] = {
            title = config.printerModels[x],
            image = ('https://gta-objects.xyz/gallery/objects/%s.jpg'):format(config.printerModels[x]),
            onSelect = function()
                local newCoords, newHeading = PRINTER_UTILS.placePrinter(config.printerModels[x])
                if not newCoords then return end

                local isPublic = lib.alertDialog({
                    header = 'Make Public?',
                    content = 'Do you want to allow public access to this printer?',
                    centered = true,
                    cancel = true,
                    labels = {
                        cancel = 'Job Only',
                        confirm = 'Make Public'
                    }
                })

                local job = Renewed.getPlayer().job
                local created, newID = lib.callback.await('xt-printers:server:createPrinter', false, {
                    model = config.printerModels[x],
                    coords = newCoords,
                    heading = newHeading,
                    group = job,
                    public = (isPublic == 'confirm') and 1 or 0
                })
                if not created then return end
            end
        }
    end

    lib.registerContext({
        id = 'printer_model_select',
        title = 'Choose Printer Model',
        options = menuOptions
    })
    lib.showContext('printer_model_select')
end

-- main menu
function menus.printersMenu()
    local menuOptions = {
        {
            title = 'New Printer',
            icon = 'fas fa-plus',
            onSelect = function()
                menus.choosePrinterModelMenu()
            end
        },
        {
            title = 'View Printers',
            icon = 'fas fa-print',
            onSelect = function()
                menus.viewPrinters()
            end
        },
    }

    lib.registerContext({
        id = 'printer_model_select',
        title = 'Choose Printer Model',
        options = menuOptions
    })
    lib.showContext('printer_model_select')
end

return menus