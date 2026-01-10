local items = {}
local files = {
    'alcool',
    'ambulance',
    'ammos',
    'cards',
    'clothes',
    'distributor',
    'drugs',
    'fishing',
    'halloween',
    'hotel',
    'inventory',
    'lean',
    'materials',
    'mechanics',
    'police',
    'radio',
    'restaurants',
    'robberies',
    'store',
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
