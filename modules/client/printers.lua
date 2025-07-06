local config        = lib.require('configs.client')
local SHARED        = lib.require('configs.shared')
local UTILS         = lib.require('modules.client.utils')
local USE_INTERACT  = GetConvar('renewed_useinteract', 'false') == 'true'

local createdPrinters = {}

-- open paper and ink menu
local function paperAndInkMenu(id)
    local storage = lib.callback.await('xt-printers:server:getPrinterStorage', false, id)
    local menuOptions = {
        {
            title = ('Paper: %s pages'):format(storage.paper),
            icon = 'fas fa-file',
            description = 'Click to Refill',
            readOnly = (storage.paper > SHARED.maxPaper),
            onSelect = function()
                local refilled, amountRefilled = lib.callback.await('xt-printers:server:refillPrinter', false, id, 'paper')
                if refilled then
                    lib.notify({
                        title = 'Paper Refilled',
                        description = ('Added %s pages to the printer tray'):format(amountRefilled)
                    })
                end
            end
        },
        {
            title = ('Ink: %s%s'):format(storage.ink, '%'),
            icon = 'fas fa-pen-nib',
            colorScheme = UTILS.progressColor(storage.ink),
            progress = storage.ink,
            description = 'Click to Refill',
            readOnly = (storage.ink > 0),
            onSelect = function()
                local refilled, amountRefilled = lib.callback.await('xt-printers:server:refillPrinter', false, id, 'ink')
                if refilled then
                    lib.notify({
                        title = 'Ink Refilled',
                        description = 'Ink refilled to 100'
                    })
                end
            end
        }
    }

    lib.registerContext({
        id = 'printer_ink_paper',
        title = 'Paper & Ink',
        options = menuOptions
    })
    lib.showContext('printer_ink_paper')
end

local PRINTER_UTILS = {}

-- start placement
function PRINTER_UTILS.placePrinter(model)
    local newCoords, newHeading = Renewed.placeObject(model, 10, true)
    if not newCoords then return end

    return newCoords, newHeading
end

-- create printer
function PRINTER_UTILS.createPrinter(id, model, coords, heading, group, public)
    coords = vec3(coords.x, coords.y, coords.z)

    local objectData = {
        id = ('printer_%s'):format(id),
        model = model,
        coords = coords,
        heading = heading,
        freeze = true,
        snapGround  = true,
    }

    local interactions = {
        -- public and group interactions
        {
            label = 'Print',
            icon = 'fas fa-print',
            groups = public == 0 and group or false,
            onSelect = function()
                local input = lib.inputDialog('Printer', {
                    { type = 'input', label = 'Title', description = 'Title of printed document', required = true },
                    { type = 'input', label = 'Description', description = 'Description of printed document', required = false },
                    { type = 'input', label = 'Link', description = 'Provide link to image being printed', required = true },
                    { type = 'number', label = 'Copies', description = 'Number of copies to print', min = 1, max = config.maxCopies, required = true }
                }) if not input then return end

                local canPrint = lib.callback.await('xt-printers:server:canPrint', false, id, input[4])
                if not canPrint then
                    lib.notify({
                        title = 'Printer Lacks Enough Paper or Ink!',
                        type = 'error'
                    })
                    return
                end

                if lib.progressCircle({
                    label = 'Printing...',
                    duration = ((config.waitPerPage * input[4]) * 1000),
                    position = 'bottom',
                    useWhileDead = true,
                    canCancel = false,
                    disable = {
                        car = true,
                    },
                }) then
                    local printed = lib.callback.await('xt-printers:server:completePrint', false, input, id)
                    if not printed then return end

                    lib.notify({
                        title = 'Printing Complete',
                        type = 'success'
                    })
                end
            end
        },
        {
            label = 'Get Completed Prints',
            icon = 'fas fa-check',
            groups = public == 0 and group or false,
            onSelect = function()
                local received = lib.callback.await('xt-printers:server:getCompletedPrints', false, id)
                if not received then return end

                lib.notify({
                    title = 'Received Completed Prints',
                    type = 'success'
                })
            end
        },

        -- group specific interactions
        {
            label = 'Open Printer Stash',
            icon = 'fas fa-box-open',
            groups = group,
            onSelect = function()
                exports.ox_inventory:openInventory('stash', { id = ('printer_%s'):format(id) })
            end
        },
        {
            label = 'Paper & Ink',
            icon = 'fas fa-gear',
            groups = group,
            onSelect = function()
                paperAndInkMenu(id)
            end
        },
    }

    if USE_INTERACT then
        for x = 1, #interactions do
            interactions[x].interactDst = 2.5
            interactions[x].distance = 3.5
            interactions[x].action = function()
                return interactions[x].onSelect()
            end
        end

        objectData.interact = {
            options = interactions
        }
    else
        objectData.target = interactions
    end

    local newPackage = Renewed.addObject(objectData)

    local _, object = Renewed.getObject(('printer_%s'):format(id))

    createdPrinters[#createdPrinters+1] = object
end

-- remove single printer
function PRINTER_UTILS.removePrinter(id)
    local _, object = Renewed.getObject(('printer_%s'):format(id))
    if not object then return end

    Renewed.removeObject(('printer_%s'):format(id))
end

-- remove all printers on unload
function PRINTER_UTILS.removeAllPrinters()
    if not createdPrinters or not next(createdPrinters) then return end -- no printers exist

    for id, info in pairs(createdPrinters) do
        Renewed.removeObject(('printer_%s'):format(id))
    end

    createdPrinters = {}
end

-- create all printers on load
function PRINTER_UTILS.createAllPrinters()
    if createdPrinters and next(createdPrinters) then return end -- printers already created

    local getPrinters = lib.callback.await('xt-printers:server:getAllPrinters', false)
    if not getPrinters or not next(getPrinters) then return end

    for id, info in pairs(getPrinters) do
        PRINTER_UTILS.createPrinter(id, info.model, info.coords.xyz, info.coords.w, info.group, info.public)
    end
end

return PRINTER_UTILS