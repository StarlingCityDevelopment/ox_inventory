if not lib then return end

local VPed = {}
local clonedPed = nil
local screenOffset = { distance = 3.0, z = 0.0, x = 0.0 }

-- Cache commonly used math functions
local sin, cos, atan, rad, deg, sqrt = math.sin, math.cos, math.atan, math.rad, math.deg, math.sqrt

local function createPed(model)
    local hash = lib.requestModel(model, 2500)
    local ped = CreatePed(4, hash, 0.0, 0.0, 0.0, 0.0, false, false)
    SetModelAsNoLongerNeeded(hash)
    return ped
end

local function loadAnimDict(dict)
    lib.requestAnimDict(dict, 2500)
end

local function setupPedProperties(ped)
    SetEntityCollision(ped, false, true)
    SetEntityInvincible(ped, true)
    NetworkSetEntityInvisibleToNetwork(ped, true)
    SetEntityCanBeDamaged(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityAlpha(ped, 255, false)
    SetEntityVisible(ped, true, false)
    SetEntityLodDist(ped, 0)
end

local function updatePedPosition()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local camRotZ, camRotX = rad(camRot.z), rad(camRot.x)

    local sinZ, cosZ = sin(camRotZ), cos(camRotZ)
    local sinX, cosX = sin(camRotX), cos(camRotX)

    local forward = vector3(
        -sinZ * cosX,
        cosZ * cosX,
        sinX
    )

    local right = vector3(cosZ, sinZ, 0.0)

    local target = camCoords + forward * screenOffset.distance + right * screenOffset.x +
    vector3(0.0, 0.0, screenOffset.z)

    SetEntityCoordsNoOffset(clonedPed, target.x, target.y, target.z, false, false, false)

    local dir = camCoords - target
    local dirX, dirY, dirZ = dir.x, dir.y, dir.z
    local pitch = deg(atan(dirZ / sqrt(dirX * dirX + dirY * dirY)))
    local yaw = deg(atan(dirY / dirX)) - 90.0
    if dirX < 0 then yaw = yaw + 180.0 end

    SetEntityRotation(clonedPed, pitch, 0.0, yaw, 2, true)
end

function VPed.startClonedPedPreview(targetPed, emote, offset)
    targetPed = targetPed or PlayerPedId()
    screenOffset = offset or screenOffset

    if clonedPed then
        VPed.stopClonedPedPreview()
    end

    clonedPed = createPed(GetEntityModel(targetPed))
    ClonePedToTarget(targetPed, clonedPed)
    setupPedProperties(clonedPed)
    DisableIdleCamera(true)

    if emote then
        loadAnimDict(emote.dict)
        TaskPlayAnim(clonedPed, emote.dict, emote.name, 8.0, 1.0, -1, 1, 0, false, false, false)
        RemoveAnimDict(emote.dict)
    end

    CreateThread(function()
        while clonedPed do
            updatePedPosition()
            Wait(0)
        end
    end)
end

function VPed.stopClonedPedPreview()
    if clonedPed then
        DisableIdleCamera(false)
        DeleteEntity(clonedPed)
        clonedPed = nil
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        VPed.stopClonedPedPreview()
    end
end)

function VPed.getClonedPed()
    return clonedPed
end

return VPed
