return {
    maxCopies = 10,                 -- max copies of a document can be printed at once
    waitPerPage = 1,                -- how many seconds to wait per page while printing

    printerModels = {               -- printer models that can be selected
        'v_res_printer',
        'prop_printer_02',
        'prop_printer_01'
    },

    viewDocument = function(link)   -- function used to view the document, passes the image link as args
        exports['randol_imageui']:showImage(link)
    end
}