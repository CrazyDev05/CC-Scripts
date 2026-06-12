local modem_side = "top"
local armor_side = "top"
local refill_side = "right"
local refill_slot = 2
local client = "<address here>"
local protocol_key = "<32 char alphanumeric here (same as client)>"

local tArgs = { ... }
if #tArgs ~= 6 then
    print( "Usage: server <client address> <32 char key> <modem side> <armor chest side> <fluid tank side> <fluid tank slot>" )
    return
end

client = tArgs[1]
protocol_key = tArgs[2]

modem_side = tArgs[3]
armor_side = tArgs[4]
refill_side = tArgs[5]
refill_slot = tonumber(tArgs[6])

local manager = peripheral.find("inventory_manager") or error("No Inventory Manager attached", 0)

local ecnet2 = require("ecnet2")
local random = require("ccryptolib.random")
local refill_level = 0

random.initWithTiming()
ecnet2.open(modem_side)

local id = ecnet2.Identity("/.ecnet2")
local command = id:Protocol {
    name = "command",
    key = protocol_key,

    serialize = textutils.serialize,
    deserialize = textutils.unserialize,
}
local reconnect = id:Protocol {
    name = "reconnect",
    key = protocol_key,

    -- Objects must be serialized before they are sent over.
    serialize = textutils.serialize,
    deserialize = textutils.unserialize,
}

local listener = command:listen()
local connections = {}

local config = fs.open("/config.json", "r")
if config then
    local contents = textutils.unserialiseJSON(config.readAll())
    refill_level = contents["refill_level"]
    config.close()
end

local function removeArmor(targetSlot)
    for i = 0, 3 do
        manager.removeItemFromPlayer(armor_side, {
            fromSlot=100+i,
            toSlot=targetSlot+i
        })
    end
end

local function addArmor(sourceSlot)
    for i = 0, 3 do
        manager.addItemToPlayer(armor_side, {
            fromSlot=sourceSlot+i,
            toSlot=100+i
        })
    end
end

local function contains(contents, min, max)
    for i = min, max do
        if contents[i] ~= nil then
            return true
        end
    end
    return false
end

local function listChest()
    local unordered = manager.listChest(armor_side)
    local ordered = {}

    for _, item in pairs(unordered) do
        ordered[item.slot] = item
    end

    return ordered
end

local function message()
    while true do
        local event, id, p2, message, channel, distance = os.pullEvent()
        if event == "ecnet2_request" and id == listener.id then
            local connection = listener:accept(refill_level, p2)
            connections[connection.id] = connection
        elseif event == "ecnet2_message" and connections[id] then
            print(textutils.serialiseJSON(message))
            
            if message.action == "update_level" then
                refill_level = message.value
                
                local config = fs.open("/config.json", "w")
                if config then
                    local contents = textutils.serialiseJSON({
                        ["refill_level"] = refill_level
                    })
                    config.write(contents)
                    config.close()
                end

                connections[id]:send(refill_level)
            elseif message.action == "swap" then
                local chest = listChest()
                local first = contains(chest, 0, 3)
                local second = contains(chest, 4, 7)

                if first and not second then
                    removeArmor(4)
                    addArmor(0)
                elseif second and not first then
                    removeArmor(0)
                    addArmor(4)
                elseif not second and not first then
                    removeArmor(0)
                end
            end
        end
    end
end

local function refill()
    while true do
        local threshold = math.min(math.max(refill_level, 0), 7999)
        for _, item in pairs(manager.getItems()) do
            if item.name == "justdirethings:time_wand" then
                local container = item.components["justdirethings:fluid_container"]
                if not container or container.amount <= threshold then
                    manager.removeItemFromPlayer(refill_side, {
                        fromSlot=item.slot,
                        toSlot=refill_slot
                    })
                    sleep(1)
                    local moved = manager.addItemToPlayer(refill_side, {
                        toSlot=refill_slot
                    })
                    if moved == 0 then
                        manager.addItemToPlayer(refill_side, {})
                    end
                    break
                end
            end
        end
        sleep(1)
    end
end

reconnect:connect(client, modem_side)
parallel.waitForAny(message, refill, ecnet2.daemon)