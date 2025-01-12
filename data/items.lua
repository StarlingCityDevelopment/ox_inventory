local items = {}
local files = {
    'ambulance',
    'carkeys',
    'clothes',
    'drugs',
    'inventory',
    'mechanics',
    'police',
    'radio',
    'restaurants',
    'robberies',
    'racing',
    'tuners',
}

for _, file in ipairs(files) do
    local item = require("data.items." .. file)
    for k, v in pairs(item) do
        if not items[k] then items[k] = v end
    end
end

return items
