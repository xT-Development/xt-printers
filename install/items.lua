--[[

    ADD THESE TO OX_INVENTORY ITEMS

]]--


["printerdocument"] = {
    label = "Document",
    weight = 10,
    stack = false,
    close = true,
    description = "A printed document",
    client = {
        image = "printerdocument.png",
        export = "xt-printers.printerdocument"
    }
},

["printerink"] = {
    label = "Ink Cartridge",
    weight = 200,
    stack = true,
    close = false,
    description = "Ink for printing",
},

["printerpaper"] = {
    label = "Blank Printer Paper",
    weight = 10,
    stack = true,
    close = false,
    description = "Blank paper for printing",
},