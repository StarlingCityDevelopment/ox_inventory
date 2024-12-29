local items = {}
local files = {
    'ambulance',
    'carkeys',
    'clothes',
    'drugs',
    'inventory',
    'motorworks',
    'police',
    'radio',
    'restaurants',
    'robberies',
}

for _, file in ipairs(files) do
    local item = require("data.items." .. file)
    for k, v in pairs(item) do
        items[k] = v
    end
end

return items
