DO NOT USE
I'm not finished fixing this to be plug in play. Will do a PR when it's ready.

# hsn-inventory
Advanced Inventory System for Fivem

-- Stash Trigger

TriggerServerEvent("hsn-inventory:server:openStash", {name = 'Motel',slots = 15, type = 'stash'})

Showcase --> https://streamable.com/kpvdj3

Setup -- > https://streamable.com/esytcq

You can contact with me for inventory bugs or dupes...
https://discord.gg/6FQhKDXBJ6

Add this code ghmattimysql server.lua

exports("ready", function (callback)
  Citizen.CreateThread(function ()
      -- add some more error handling
      while GetResourceState('ghmattimysql') ~= 'started' do
          Citizen.Wait(0)
      end
      callback()
  end)
end)

es_extended server / main.lua
https://imgur.com/a/L6zmAIf

##Use (/addItem playerId item count) command for give item.

Server Side Remove Item

TriggerEvent("hsn-inventory:server:removeItem",playerId,itemname,count)

Server Side Add Item

TriggerEvent("hsn-inventory:server:addItem",playerId,itemname,count)

Client Side Add Item

TriggerServerEvent("hsn-inventory:client:addItem",itemname,count)

Client Side Remove Item

TriggerServerEvent("hsn-inventory:client:removeItem",itemname,count)


