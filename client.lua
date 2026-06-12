local server = "<server address here>"
local protocol_key = "<32 char alphanumeric here (same as client)>"

local tArgs = { ... }
if #tArgs ~= 2 then
    print( "Usage: client <server address> <32 char key>" )
    return
end
server = tArgs[1]
protocol_key = tArgs[2]

local ecnet2 = require("ecnet2")
local random = require("ccryptolib.random")
local basalt = require("basalt")
local connection = nil

local main = basalt.createFrame()
    :setSize(26, 20)

main:addLabel()
    :setPosition(2, 2)
    :setSize(15, 1)
    :setText("Min Time Fluid:")

local fluidDisplay = main:addLabel()
    :setPosition(18, 2)
    :setText("")

local fluidSlider = main:addSlider()
    :setPosition(2, 3)
    :setSize(24, 1)
    :setStep(0)
    :setMax(8000)
    :onChange("step", function(self, _)
        local value = self:getValue()

        fluidDisplay:setText(""..value)
        connection:send({
            ["action"]="update_level",
            ["value"]=value
        })
    end)


local swapArmor = main:addButton()
    :setPosition(2, 6)
    :setSize(24, 3)
    :setText("Swap Armor")
    :onClick(function(self)
        connection:send({
            ["action"]="swap"
        })
    end)

random.initWithTiming()

-- Open the top modem for comms.
ecnet2.open("back")

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
    serialize = textutils.serialize,
    deserialize = textutils.unserialize,
}


local function updateLevel(value)
    local max = fluidSlider.getResolved("max")
    local maxSteps = fluidSlider.getResolved("width")
    fluidSlider:setStep((value * (maxSteps - 1) / max) + 1)
end

local function main()
    connection = command:connect(server, "back")
    updateLevel(select(2, connection:receive()))

    while true do
        coroutine.yield()
    end
end

local listener = reconnect:listen()
local function message()
    while true do
        local event, id, p2, message, channel, distance = os.pullEvent()
        if event == "ecnet2_request" and id == listener.id then
            break
        end
    end
end

parallel.waitForAny(main, message, basalt.run, ecnet2.daemon)