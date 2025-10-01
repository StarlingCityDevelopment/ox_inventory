local items = {}
local files = {
    'alcool',
    'ambulance',
    'cards',
    'clothes',
    'distributor',
    'drugs',
    'fishing',
    'hotel',
    'inventory',
    'materials',
    'mechanics',
    'police',
    'radio',
    'restaurants',
    'robberies',
    'tuners',
    'vehiclekeys',
}

for _, file in ipairs(files) do
    local item = require("data.items." .. file)
    for k, v in pairs(item) do
        if not items[k] then items[k] = v end
    end
end

return items
