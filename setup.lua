print("Which side are you doing:")
print("1) Generate Address")
print("2) Install Client")
print("3) Install Server")

local choice = read()
if choice == "3" then
    shell.run("wget run https://github.com/migeyel/ecnet/releases/download/v2.1.0/install.lua")
    shell.run("wget run https://github.com/migeyel/ccryptolib/releases/download/v1.2.2/install.lua")
    shell.run("clear")

    local ecnet2 = require("ecnet2")
    local random = require("ccryptolib.random")
    
    random.initWithTiming()
    local address = ecnet2.Identity("/.ecnet2").address
    print("The address of this device is:")
    print(address)

elseif choice == "2" then
    shell.run("wget https://raw.githubusercontent.com/CrazyDev05/CC-Scripts/refs/heads/main/client.lua")
    shell.run("wget run https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua -f")
    shell.run("clear")

    print("Server address?")
    local server = read()

    print("Encryption key? (32 cahr alphanumeric)")
    local key = read()

    local file = fs.open("startup.lua", "a")
    file.writeLine("shell.run('client " .. server .. " " .. key .."')")
elseif choise == "3" then
    shell.run("wget https://raw.githubusercontent.com/CrazyDev05/CC-Scripts/refs/heads/main/server.lua")
    shell.run("clear")

    local address = generateAddress()

    print("Client address?")
    local client = read()
    
    print("Encryption key? (32 cahr alphanumeric)")
    local key = read()

    print("Modem side?")
    local modem_side = read()
    
    print("Armor side? (from the Inventory Manager)")
    local armor_side = read()
    
    print("Time Fluid Tank side? (from the Inventory Manager)")
    local refill_side = read()
    
    print("Slot to put empty Time Wand")
    local refill_slot = read()

    local file = fs.open("startup.lua", "a")
    file.writeLine("shell.run('server ".. client .. " " .. key .. " " .. modem_side .. " " .. armor_side .. " " refill_side .. " " .. refill_slot .."')")
    file.close()
end