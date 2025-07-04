local shared = lib.require('configs.shared')

local utils = {}

function utils.distanceCheck(src, printerCoords)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local dist = #(coords - vec3(printerCoords.x, printerCoords.y, printerCoords.z))

    return dist <= 3
end

function utils.hasAllowedJob(src, checkJob)
    if checkJob then
        if shared.allowedJobs[checkJob] then
            if Renewed.hasGroup(src, checkJob, shared.allowedJobs[checkJob]) then
                return true, checkJob
            end
        end
    end

    for job, rank in pairs(shared.allowedJobs) do
        if Renewed.hasGroup(src, job, rank or nil) then
            return true, job
        end
    end

    return false
end

return utils