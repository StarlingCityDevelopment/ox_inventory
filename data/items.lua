local items = {}
local files = {
    'alcool',
    'ambulance',
    'cards',
    'carkeys',
    'clothes',
    'distributor',
    'drugs',
    'fishing',
    'hotel',
    'inventory',
    'mechanics',
    'police',
    'racing',
    'radio',
    'restaurants',
    'robberies',
    'school_cafeteria',
    'tuners',
}

for _, file in ipairs(files) do
    local item = require("data.items." .. file)
    for k, v in pairs(item) do
        if not items[k] then items[k] = v end
    end
end

return items
