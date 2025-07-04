local createdInteractions = {}

local utils = {}

function utils.progressColor(ink)
    if ink <= 100 and ink >= 75 then
        return 'green'
    elseif ink < 75 and ink >= 50 then
        return 'yellow'
    elseif ink < 50 and ink >= 25 then
        return 'orange'
    elseif ink < 25 and ink >= 0 then
        return 'red'
    end
end

return utils