-- Weapon Rarity Simulator GUI Script
-- Place this in StarterGui as a LocalScript

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TweenService = game:GetService("TweenService")

-- Weapon data with rarities
local weapons = {
    {name = "Dessert Eagle", rarity = 2, biome = "Default"},
    {name = "Uzi", rarity = 7, biome = "Default"},
    {name = "SPAS-12", rarity = 16, biome = "Default"},
    {name = "Golden Eagle", rarity = 30, biome = "Default"},
    {name = "M16A4", rarity = 50, biome = "Default"},
    {name = "Sheriff's Revolver", rarity = 89, biome = "Pumpkin Wrath"},
    {name = "AK-47", rarity = 145, biome = "Default"},
    {name = "M60", rarity = 199, biome = "Default"},
    {name = "AA-12", rarity = 230, biome = "Default"},
    {name = "LX1", rarity = 300, biome = "Default"},
    {name = "LX2", rarity = 550, biome = "Default"},
    {name = "Gatling", rarity = 781, biome = "Default"},
    {name = "Sniper", rarity = 998, biome = "Default"},
    {name = "LX3", rarity = 1200, biome = "Default"},
    {name = "Water Gun", rarity = 3750, biome = "Default"},
    {name = "M1 Garand", rarity = 6500, biome = "Default"},
    {name = "Dual Sheriff's Revolver", rarity = 7457, biome = "Pumpkin Wrath"},
    {name = "Rocket Launcher", rarity = 8888, biome = "Default"},
    {name = "Golden M16A4", rarity = 8889, biome = "Default"},
    {name = "Grenade Launcher", rarity = 9999, biome = "Default"},
    {name = "Vulcan", rarity = 10000, biome = "Default"},
    {name = "Dual Uzi", rarity = 11001, biome = "Default"},
    {name = "LX2024", rarity = 12000, biome = "Default"},
    {name = "Dual LX1", rarity = 22222, biome = "Default"},
    {name = "Viewer's Revolver", rarity = 23000, biome = "Default"},
    {name = "Penguin Axe", rarity = 34573, biome = "Default"},
    {name = "LX4", rarity = 40404, biome = "Default"},
    {name = "LXX", rarity = 50000, biome = "Default"},
    {name = "LX5", rarity = 60606, biome = "Default"},
    {name = "Zapper Nova", rarity = 66665, biome = "Default"},
    {name = "Laser_Laser", rarity = 78554, biome = "Default"},
    {name = "LXW", rarity = 80000, biome = "Robot Invasion"},
    {name = "LXD", rarity = 80000, biome = "Default"},
    {name = "Spirit O' Launcher", rarity = 85000, biome = "Graveyard"},
    {name = "Laser Shotgun", rarity = 90000, biome = "Default"},
    {name = "Steampunk M1 Garand", rarity = 100000, biome = "Steampunk"},
    {name = "RGB", rarity = 101010, biome = "Robot Invasion"},
    {name = "Burst-Storm", rarity = 200000, biome = "Default"},
    {name = "Slasher", rarity = 250300, biome = "Night City"},
    {name = "Corrupt Rifle", rarity = 404404, biome = "Night City"},
    {name = "LXY", rarity = 450000, biome = "Default"},
    {name = "Ripper", rarity = 575000, biome = "Night City"},
    {name = "Steampunked Nova", rarity = 578000, biome = "Steampunk"},
    {name = "Overheater", rarity = 589990, biome = "Default"},
    {name = "Gravity Gun", rarity = 750000, biome = "Robot Invasion"},
    {name = "Shieldbearer", rarity = 900500, biome = "Default"},
    {name = "Staff of Steam", rarity = 950750, biome = "Steampunk"},
    {name = "Gun_Gun", rarity = 1000000, biome = "Default"},
    {name = "Stygian Blaster", rarity = 1500000, biome = "Default"},
    {name = "LXF", rarity = 2750000, biome = "Night City"},
    {name = "Staff of Flames", rarity = 2999999, biome = "Default"},
    {name = "Magma Striker", rarity = 3750000, biome = "Default"},
    {name = "Euphoria Ray Blaster", rarity = 5000000, biome = "Default"},
    {name = "Bleeding Scythe", rarity = 7500000, biome = "Night City"},
    {name = "Gamma Ray Generator", rarity = 10000000, biome = "Robot Invasion"},
    {name = "Hyperion Railgun", rarity = 10500000, biome = "Default"},
    {name = "Conjurer's Hand", rarity = 12500000, biome = "Default"},
    {name = "LX6", rarity = 15000000, biome = "Default"},
    {name = "Poison Generator", rarity = 17600009, biome = "Default"},
    {name = "Outburster", rarity = 19000000, biome = "Default"},
    {name = "Plasma Gun", rarity = 19999999, biome = "Alien Invasion"},
    {name = "Warrior's Skull", rarity = 20001000, biome = "Pumpkin Wrath"},
    {name = "Frosting Scythe", rarity = 27500000, biome = "Default"},
    {name = "Math Gatling", rarity = 30000000, biome = "Default"},
    {name = "Ectoplasm Launcher", rarity = 45000000, biome = "Graveyard"},
    {name = "Launcher_Launcher", rarity = 50999999, biome = "Default"},
    {name = "Druid Vine", rarity = 59690100, biome = "Default"},
    {name = "Sun Shooter", rarity = 75000000, biome = "Default"},
    {name = "Dark Dweller's Lantern", rarity = 77777777, biome = "Graveyard"},
    {name = "Tidal Waved Gun", rarity = 88888888, biome = "Default"},
    {name = "Screamer", rarity = 90000000, biome = "Night City"},
    {name = "Mist Generator", rarity = 91000055, biome = "Steampunk"},
    {name = "Eccentric Gun", rarity = 97000000, biome = "Default"},
    {name = "Binary Gun", rarity = 99999999, biome = "Default"},
    {name = "THE NUKER", rarity = 101005750, biome = "Default"}
}

-- Mutations data
local mutations = {
    default = {
        {name = "Bronze", rarity = 75},
        {name = "Silver", rarity = 100},
        {name = "Gold", rarity = 235},
        {name = "Diamond", rarity = 500},
        {name = "Rainbowified", rarity = 1500}
    },
    ["Pumpkin Wrath"] = {
        {name = "Pumpkinized", rarity = 10},
        {name = "SoulFlamed", rarity = 25}
    },
    ["Steampunk"] = {
        {name = "Steamy", rarity = 500},
        {name = "Fogged", rarity = 1000},
        {name = "Mistful", rarity = 50000}
    },
    ["Robot Invasion"] = {
        {name = "Cyber", rarity = 300}
    },
    ["Night City"] = {
        {name = "Corrupted", rarity = 750},
        {name = "Impeached", rarity = 7500},
        {name = "Madness", rarity = 95000},
        {name = "IMPURED", rarity = 100000}
    },
    ["Graveyard"] = {
        {name = "Wilted", rarity = 50},
        {name = "Blighted", rarity = 99},
        {name = "Deformed", rarity = 750},
        {name = "ECTOPLASM", rarity = 75000},
        {name = "UNDERWORLD", rarity = 1000000}
    }
}

local mutationRarities = {}
for _, mutList in pairs(mutations) do
    for _, m in ipairs(mutList) do
        mutationRarities[m.name] = m.rarity
    end
end
mutationRarities["Nightbloom"] = 1.3
mutationRarities["Burning"] = 2
mutationRarities["Natural"] = 4.5

local mutationColors = {
    ["Bronze"] = "184,115,51",
    ["Silver"] = "192,192,192",
    ["Gold"] = "255,215,0",
    ["Diamond"] = "185,242,255",
    ["Rainbowified"] = "255,105,180",
    ["Pumpkinized"] = "255,165,0",
    ["SoulFlamed"] = "255,69,0",
    ["Steamy"] = "169,169,169",
    ["Fogged"] = "105,105,105",
    ["Mistful"] = "220,220,220",
    ["Cyber"] = "0,255,255",
    ["Corrupted"] = "128,0,128",
    ["Impeached"] = "255,0,0",
    ["Madness"] = "255,20,147",
    ["IMPURED"] = "75,0,130",
    ["Wilted"] = "124,252,0",
    ["Blighted"] = "139,69,19",
    ["Deformed"] = "128,0,128",
    ["ECTOPLASM"] = "0,255,0",
    ["UNDERWORLD"] = "178,34,34",
    ["Nightbloom"] = "138,43,226",
    ["Burning"] = "255,69,0",
    ["Natural"] = "0,128,0"
}

-- Rainbow colors for Rainbowified
local rainbowColors = {
    "255,0,0",    -- Red
    "255,165,0",  -- Orange
    "255,255,0",  -- Yellow
    "0,255,0",    -- Green
    "0,0,255",    -- Blue
    "75,0,130",   -- Indigo
    "238,130,238" -- Violet
}

-- Collect gun names
local gunNames = {}
for _, w in ipairs(weapons) do
    table.insert(gunNames, w.name)
end
table.sort(gunNames)

-- Collect mutation names
local mutationNames = {"None"}
local seenMuts = {}
for _, mutList in pairs(mutations) do
    for _, m in ipairs(mutList) do
        if not seenMuts[m.name] then
            table.insert(mutationNames, m.name)
            seenMuts[m.name] = true
        end
    end
end
seenMuts["Nightbloom"] = true
seenMuts["Burning"] = true
seenMuts["Natural"] = true
table.insert(mutationNames, "Nightbloom")
table.insert(mutationNames, "Burning")
table.insert(mutationNames, "Natural")
table.sort(mutationNames, function(a, b)
    if a == "None" then return true end
    if b == "None" then return false end
    return a < b
end)

-- Player stats
local playerData = {
    rolls = 0,
    inventory = {}, -- list of {baseName = string, mutations = table}
    items = {},
    pets = {}, -- list of {name = string, lastAction = number}
    currentBiome = "Default",
    money = 0,
    usedCarved = false,
    usedUFO = false
}

local luckMultiplier = 0  -- Default boost 0
local gunLuckBoost = 0
local mutationLuckBoost = 0
local biomeLuckBoost = 0
local biomeEndTime = 0
local biomeDuration = 0

local potionTimers = {
    luckyPotion1 = 0,
    mutationPotion1 = 0,
    biomePotion1 = 0,
    luckyPotion2 = 0,
    mutationPotion2 = 0,
    biomePotion2 = 0,
    luckyPotion3 = 0,
    mutationPotion3 = 0,
    biomePotion3 = 0,
    luckyPotion4 = 0,
    mutationPotion4 = 0,
    biomePotion4 = 0,
    dicePotion = 0,
    luckyPotion5 = 0,
    mutationPotion5 = 0,
    biomePotion5 = 0
}

-- Shop items
local shopItems = {
    {name = "Lucky Potion I", cost = 50, description = "Increases gun luck by 5% for 60 seconds.", func = function() gunLuckBoost = 0.05; potionTimers.luckyPotion1 = 60 end},
    {name = "Mutation Potion I", cost = 65, description = "Increases mutation luck by 5% for 55 seconds.", func = function() mutationLuckBoost = 0.05; potionTimers.mutationPotion1 = 55 end},
    {name = "Biome Potion I", cost = 100, description = "Increases biome luck by 10% for 1 use.", func = function() biomeLuckBoost = 0.10; potionTimers.biomePotion1 = 1 end},
    {name = "Lucky Potion II", cost = 125, description = "Increases gun luck by 15% for 90 seconds.", func = function() gunLuckBoost = 0.15; potionTimers.luckyPotion2 = 90 end},
    {name = "Mutation Potion II", cost = 175, description = "Increases mutation luck by 12% for 72 seconds.", func = function() mutationLuckBoost = 0.12; potionTimers.mutationPotion2 = 72 end},
    {name = "Biome Potion II", cost = 235, description = "Increases biome luck by 25% for 1 use.", func = function() biomeLuckBoost = 0.25; potionTimers.biomePotion2 = 1 end},
    {name = "Lucky Potion III", cost = 300, description = "Increases gun luck by 30% for 180 seconds.", func = function() gunLuckBoost = 0.30; potionTimers.luckyPotion3 = 180 end},
    {name = "Mutation Potion III", cost = 375, description = "Increases mutation luck by 34% for 162 seconds.", func = function() mutationLuckBoost = 0.34; potionTimers.mutationPotion3 = 162 end},
    {name = "Biome Potion III", cost = 499, description = "Increases biome luck by 45% for 1 use.", func = function() biomeLuckBoost = 0.45; potionTimers.biomePotion3 = 1 end},
    {name = "Carved Pumpkin", cost = 900, description = "Activates Pumpkin Wrath biome for 5 minutes.", func = function() playerData.currentBiome = "Pumpkin Wrath"; biomeEndTime = os.time() + 300; biomeDuration = 300 end, once = true},
    {name = "Lucky Potion IV", cost = 1750, description = "Increases gun luck by 50% for 300 seconds.", func = function() gunLuckBoost = 0.50; potionTimers.luckyPotion4 = 300 end},
    {name = "Mutation Potion IV", cost = 2300, description = "Increases mutation luck by 55% for 240 seconds.", func = function() mutationLuckBoost = 0.55; potionTimers.mutationPotion4 = 240 end},
    {name = "Biome Potion IV", cost = 4500, description = "Increases biome luck by 60% for 1 use.", func = function() biomeLuckBoost = 0.60; potionTimers.biomePotion4 = 1 end},
    {name = "UFO Necklace", cost = 9000, description = "Activates Robot Invasion biome for 6 minutes.", func = function() playerData.currentBiome = "Robot Invasion"; biomeEndTime = os.time() + 360; biomeDuration = 360 end, once = true},
    {name = "Dice Potion", cost = 14500, description = "Gives a random luck boost for 60 seconds.", func = function() 
        local rand = math.random(1, 95 + 25 + 2)
        if rand <= 2 then
            gunLuckBoost = 0.01
        elseif rand <= 2 + 25 then
            gunLuckBoost = 5
        else
            gunLuckBoost = 10
        end
        potionTimers.dicePotion = 60
    end},
    {name = "Lucky Potion V", cost = 19500, description = "Increases gun luck by 69% for 300 seconds.", func = function() gunLuckBoost = 0.69; potionTimers.luckyPotion5 = 300 end},
    {name = "Mutation Potion V", cost = 25750, description = "Increases mutation luck by 72% for 264 seconds.", func = function() mutationLuckBoost = 0.72; potionTimers.mutationPotion5 = 264 end},
    {name = "Elemental Controller", cost = 29500, description = "Activates a random biome for 5 minutes.", func = function() 
        local rand = math.random(1, 245 + 111 + 75 + 40 + 10 + 2)
        local selectedBiome
        if rand <= 2 then
            selectedBiome = nil
        elseif rand <= 2 + 10 then
            selectedBiome = "Pumpkin Wrath"
        elseif rand <= 2 + 10 + 40 then
            selectedBiome = "Robot Invasion"
        elseif rand <= 2 + 10 + 40 + 75 then
            selectedBiome = "Steampunk"
        elseif rand <= 2 + 10 + 40 + 75 + 111 then
            selectedBiome = "Graveyard"
        else
            selectedBiome = "Night City"
        end
        if selectedBiome then
            playerData.currentBiome = selectedBiome
            biomeEndTime = os.time() + 300
            biomeDuration = 300
        end
    end},
    {name = "Biome Potion V", cost = 31000, description = "Increases biome luck by 85% for 1 use.", func = function() biomeLuckBoost = 0.85; potionTimers.biomePotion5 = 1 end},
    {name = "Fox", cost = 25700, description = "Every 10 minutes it has 50% chance to give a random 1/1 to 1/1,000 chance Gun!", rarity = "Common", func = function() table.insert(playerData.pets, {name = "Fox", lastAction = 0}) end},
    {name = "Owl", cost = 28500, description = "Every 1 minute and 30 seconds it gives Nightbloom to a random Gun! (Doesn't need chance)", rarity = "Common", func = function() table.insert(playerData.pets, {name = "Owl", lastAction = 0}) end},
    {name = "Dog", cost = 37777, description = "Every 1 minute it has 5% chance to give Lucky Potion I or Mutation Potion I or Biome Potion I!", rarity = "Uncommon", func = function() table.insert(playerData.pets, {name = "Dog", lastAction = 0}) end},
    {name = "Giant Fire Ant", cost = 39000, description = "Every 1 minute it has 50% chance to apply Burning mutation to a random Gun!", rarity = "Uncommon", func = function() table.insert(playerData.pets, {name = "Giant Fire Ant", lastAction = 0}) end},
    {name = "Pumpkin Head Deer", cost = 42573, description = "If it's during Pumpkin Wrath Biome, it will increase the chance of Pumpkinized into 1/5 Chance and Soulflamed into 1/7!", rarity = "Uncommon", func = function() table.insert(playerData.pets, {name = "Pumpkin Head Deer", lastAction = 0}) end},
    {name = "Druid", cost = 50000, description = "Increases the chance of Druid Vine gun from 1/59,690,100 to 1/5,966,001. Second ability: every 2 minutes it applies Natural Mutation to a random Gun!", rarity = "Rare", func = function() table.insert(playerData.pets, {name = "Druid", lastAction = 0}) end}
}

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WeaponSimGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 600, 0, 450)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "⚔️ WEAPON RARITY SIMULATOR ⚔️"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 24
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleLabel

-- Stats Display
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -20, 0, 30)
statsLabel.Position = UDim2.new(0, 10, 0, 60)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "Rolls: 0 | Current Biome: Default | Money: 0"
statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statsLabel.TextSize = 16
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.Parent = mainFrame

-- Biome Timer Label
local biomeTimerLabel = Instance.new("TextLabel")
biomeTimerLabel.Size = UDim2.new(1, -20, 0, 30)
biomeTimerLabel.Position = UDim2.new(0, 10, 0, 90)
biomeTimerLabel.BackgroundTransparency = 1
biomeTimerLabel.Text = ""
biomeTimerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
biomeTimerLabel.TextSize = 16
biomeTimerLabel.Font = Enum.Font.Gotham
biomeTimerLabel.TextXAlignment = Enum.TextXAlignment.Left
biomeTimerLabel.Parent = mainFrame

-- Notification Label
local notificationLabel = Instance.new("TextLabel")
notificationLabel.Size = UDim2.new(1, -20, 0, 30)
notificationLabel.Position = UDim2.new(0, 10, 0, 120)
notificationLabel.BackgroundTransparency = 1
notificationLabel.Text = ""
notificationLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
notificationLabel.TextSize = 16
notificationLabel.Font = Enum.Font.Gotham
notificationLabel.TextXAlignment = Enum.TextXAlignment.Left
notificationLabel.Parent = mainFrame

-- Result Display
local resultFrame = Instance.new("Frame")
resultFrame.Size = UDim2.new(1, -40, 0, 150)
resultFrame.Position = UDim2.new(0, 20, 0, 150)
resultFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
resultFrame.BorderSizePixel = 0
resultFrame.Parent = mainFrame

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 8)
resultCorner.Parent = resultFrame

local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(1, -20, 1, -20)
resultLabel.Position = UDim2.new(0, 10, 0, 10)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = "Click 'ROLL WEAPON' to start!"
resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
resultLabel.TextSize = 20
resultLabel.Font = Enum.Font.GothamBold
resultLabel.TextWrapped = true
resultLabel.RichText = true
resultLabel.Parent = resultFrame

-- Roll Button
local rollButton = Instance.new("TextButton")
rollButton.Size = UDim2.new(0, 250, 0, 50)
rollButton.Position = UDim2.new(0.5, -125, 0, 310)
rollButton.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
rollButton.BorderSizePixel = 0
rollButton.Text = "🎲 ROLL WEAPON"
rollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rollButton.TextSize = 20
rollButton.Font = Enum.Font.GothamBold
rollButton.Parent = mainFrame

local rollCorner = Instance.new("UICorner")
rollCorner.CornerRadius = UDim.new(0, 8)
rollCorner.Parent = rollButton

-- Inventory Button
local invButton = Instance.new("TextButton")
invButton.Size = UDim2.new(0, 120, 0, 40)
invButton.Position = UDim2.new(0, 20, 0, 370)
invButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
invButton.BorderSizePixel = 0
invButton.Text = "📦 Inventory"
invButton.TextColor3 = Color3.fromRGB(255, 255, 255)
invButton.TextSize = 16
invButton.Font = Enum.Font.GothamBold
invButton.Parent = mainFrame

local invCorner = Instance.new("UICorner")
invCorner.CornerRadius = UDim.new(0, 8)
invCorner.Parent = invButton

-- Admin Button
local adminButton = Instance.new("TextButton")
adminButton.Size = UDim2.new(0, 120, 0, 40)
adminButton.Position = UDim2.new(0, 150, 0, 370)
adminButton.BackgroundColor3 = Color3.fromRGB(150, 50, 200)
adminButton.BorderSizePixel = 0
adminButton.Text = "🔧 Admin"
adminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
adminButton.TextSize = 16
adminButton.Font = Enum.Font.GothamBold
adminButton.Parent = mainFrame

local adminCorner = Instance.new("UICorner")
adminCorner.CornerRadius = UDim.new(0, 8)
adminCorner.Parent = adminButton

-- Auto Roll Button
local autoRollButton = Instance.new("TextButton")
autoRollButton.Size = UDim2.new(0, 120, 0, 40)
autoRollButton.Position = UDim2.new(0, 280, 0, 370)
autoRollButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
autoRollButton.BorderSizePixel = 0
autoRollButton.Text = "⚡ Auto Roll"
autoRollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoRollButton.TextSize = 16
autoRollButton.Font = Enum.Font.GothamBold
autoRollButton.Parent = mainFrame

local autoCorner = Instance.new("UICorner")
autoCorner.CornerRadius = UDim.new(0, 8)
autoCorner.Parent = autoRollButton

-- Shop Button
local shopButton = Instance.new("TextButton")
shopButton.Size = UDim2.new(0, 120, 0, 40)
shopButton.Position = UDim2.new(0, 410, 0, 370)
shopButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
shopButton.BorderSizePixel = 0
shopButton.Text = "🏬 Shop"
shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopButton.TextSize = 16
shopButton.Font = Enum.Font.GothamBold
shopButton.Parent = mainFrame

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 8)
shopCorner.Parent = shopButton

-- Inventory Frame (with scrolling)
local invFrame = Instance.new("Frame")
invFrame.Size = UDim2.new(0, 500, 0, 400)
invFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
invFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
invFrame.BorderSizePixel = 0
invFrame.Visible = false
invFrame.Parent = screenGui

local invFrameCorner = Instance.new("UICorner")
invFrameCorner.CornerRadius = UDim.new(0, 12)
invFrameCorner.Parent = invFrame

-- Inventory Title
local invTitle = Instance.new("TextLabel")
invTitle.Size = UDim2.new(1, 0, 0, 50)
invTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
invTitle.BorderSizePixel = 0
invTitle.Text = "📦 INVENTORY"
invTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
invTitle.TextSize = 22
invTitle.Font = Enum.Font.GothamBold
invTitle.Parent = invFrame

local invTitleCorner = Instance.new("UICorner")
invTitleCorner.CornerRadius = UDim.new(0, 12)
invTitleCorner.Parent = invTitle

-- Close Inventory Button
local closeInvButton = Instance.new("TextButton")
closeInvButton.Size = UDim2.new(0, 40, 0, 40)
closeInvButton.Position = UDim2.new(1, -45, 0, 5)
closeInvButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeInvButton.BorderSizePixel = 0
closeInvButton.Text = "X"
closeInvButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeInvButton.TextSize = 20
closeInvButton.Font = Enum.Font.GothamBold
closeInvButton.Parent = invFrame

local closeInvCorner = Instance.new("UICorner")
closeInvCorner.CornerRadius = UDim.new(0, 8)
closeInvCorner.Parent = closeInvButton

-- Tabs for Inventory
local gunsTabButton = Instance.new("TextButton")
gunsTabButton.Size = UDim2.new(1/3, 0, 0, 40)
gunsTabButton.Position = UDim2.new(0, 0, 0, 50)
gunsTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
gunsTabButton.BorderSizePixel = 0
gunsTabButton.Text = "Guns"
gunsTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
gunsTabButton.TextSize = 18
gunsTabButton.Font = Enum.Font.GothamBold
gunsTabButton.Parent = invFrame

local gunsTabCorner = Instance.new("UICorner")
gunsTabCorner.CornerRadius = UDim.new(0, 8)
gunsTabCorner.Parent = gunsTabButton

local itemsTabButton = Instance.new("TextButton")
itemsTabButton.Size = UDim2.new(1/3, 0, 0, 40)
itemsTabButton.Position = UDim2.new(1/3, 0, 0, 50)
itemsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
itemsTabButton.BorderSizePixel = 0
itemsTabButton.Text = "Items"
itemsTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
itemsTabButton.TextSize = 18
itemsTabButton.Font = Enum.Font.GothamBold
itemsTabButton.Parent = invFrame

local itemsTabCorner = Instance.new("UICorner")
itemsTabCorner.CornerRadius = UDim.new(0, 8)
itemsTabCorner.Parent = itemsTabButton

local petsTabButton = Instance.new("TextButton")
petsTabButton.Size = UDim2.new(1/3, 0, 0, 40)
petsTabButton.Position = UDim2.new(2/3, 0, 0, 50)
petsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
petsTabButton.BorderSizePixel = 0
petsTabButton.Text = "Pets"
petsTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
petsTabButton.TextSize = 18
petsTabButton.Font = Enum.Font.GothamBold
petsTabButton.Parent = invFrame

local petsTabCorner = Instance.new("UICorner")
petsTabCorner.CornerRadius = UDim.new(0, 8)
petsTabCorner.Parent = petsTabButton

-- Scrolling Frame for Inventory Guns
local gunsScrollFrame = Instance.new("ScrollingFrame")
gunsScrollFrame.Size = UDim2.new(1, -20, 1, -110)
gunsScrollFrame.Position = UDim2.new(0, 10, 0, 100)
gunsScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
gunsScrollFrame.BorderSizePixel = 0
gunsScrollFrame.ScrollBarThickness = 8
gunsScrollFrame.Parent = invFrame
gunsScrollFrame.Visible = true

local gunsScrollCorner = Instance.new("UICorner")
gunsScrollCorner.CornerRadius = UDim.new(0, 8)
gunsScrollCorner.Parent = gunsScrollFrame

local gunsListLayout = Instance.new("UIListLayout")
gunsListLayout.Padding = UDim.new(0, 5)
gunsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
gunsListLayout.Parent = gunsScrollFrame

-- Scrolling Frame for Inventory Items
local itemsScrollFrame = Instance.new("ScrollingFrame")
itemsScrollFrame.Size = UDim2.new(1, -20, 1, -110)
itemsScrollFrame.Position = UDim2.new(0, 10, 0, 100)
itemsScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
itemsScrollFrame.BorderSizePixel = 0
itemsScrollFrame.ScrollBarThickness = 8
itemsScrollFrame.Parent = invFrame
itemsScrollFrame.Visible = false

local itemsScrollCorner = Instance.new("UICorner")
itemsScrollCorner.CornerRadius = UDim.new(0, 8)
itemsScrollCorner.Parent = itemsScrollFrame

local itemsListLayout = Instance.new("UIListLayout")
itemsListLayout.Padding = UDim.new(0, 5)
itemsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
itemsListLayout.Parent = itemsScrollFrame

-- Scrolling Frame for Inventory Pets
local petsScrollFrame = Instance.new("ScrollingFrame")
petsScrollFrame.Size = UDim2.new(1, -20, 1, -110)
petsScrollFrame.Position = UDim2.new(0, 10, 0, 100)
petsScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
petsScrollFrame.BorderSizePixel = 0
petsScrollFrame.ScrollBarThickness = 8
petsScrollFrame.Parent = invFrame
petsScrollFrame.Visible = false

local petsScrollCorner = Instance.new("UICorner")
petsScrollCorner.CornerRadius = UDim.new(0, 8)
petsScrollCorner.Parent = petsScrollFrame

local petsListLayout = Instance.new("UIListLayout")
petsListLayout.Padding = UDim.new(0, 5)
petsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
petsListLayout.Parent = petsScrollFrame

-- Shop Frame
local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0, 500, 0, 500)
shopFrame.Position = UDim2.new(0.5, -250, 0.5, -250)
shopFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = screenGui

local shopFrameCorner = Instance.new("UICorner")
shopFrameCorner.CornerRadius = UDim.new(0, 12)
shopFrameCorner.Parent = shopFrame

-- Shop Title
local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 50)
shopTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
shopTitle.BorderSizePixel = 0
shopTitle.Text = "🏬 SHOP"
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.TextSize = 22
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Parent = shopFrame

local shopTitleCorner = Instance.new("UICorner")
shopTitleCorner.CornerRadius = UDim.new(0, 12)
shopTitleCorner.Parent = shopTitle

-- Close Shop Button
local closeShopButton = Instance.new("TextButton")
closeShopButton.Size = UDim2.new(0, 40, 0, 40)
closeShopButton.Position = UDim2.new(1, -45, 0, 5)
closeShopButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeShopButton.BorderSizePixel = 0
closeShopButton.Text = "X"
closeShopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeShopButton.TextSize = 20
closeShopButton.Font = Enum.Font.GothamBold
closeShopButton.Parent = shopFrame

local closeShopCorner = Instance.new("UICorner")
closeShopCorner.CornerRadius = UDim.new(0, 8)
closeShopCorner.Parent = closeShopButton

-- Scrolling Frame for Shop
local shopScrollFrame = Instance.new("ScrollingFrame")
shopScrollFrame.Size = UDim2.new(1, -20, 1, -70)
shopScrollFrame.Position = UDim2.new(0, 10, 0, 60)
shopScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
shopScrollFrame.BorderSizePixel = 0
shopScrollFrame.ScrollBarThickness = 8
shopScrollFrame.Parent = shopFrame

local shopScrollCorner = Instance.new("UICorner")
shopScrollCorner.CornerRadius = UDim.new(0, 8)
shopScrollCorner.Parent = shopScrollFrame

local shopListLayout = Instance.new("UIListLayout")
shopListLayout.Padding = UDim.new(0, 5)
shopListLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopListLayout.Parent = shopScrollFrame

-- Admin Frame
local adminFrame = Instance.new("Frame")
adminFrame.Size = UDim2.new(0, 500, 0, 400)
adminFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
adminFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
adminFrame.BorderSizePixel = 0
adminFrame.Visible = false
adminFrame.Parent = screenGui

local adminFrameCorner = Instance.new("UICorner")
adminFrameCorner.CornerRadius = UDim.new(0, 12)
adminFrameCorner.Parent = adminFrame

-- Admin Title
local adminTitle = Instance.new("TextLabel")
adminTitle.Size = UDim2.new(1, 0, 0, 50)
adminTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
adminTitle.BorderSizePixel = 0
adminTitle.Text = "🔧 ADMIN MENU"
adminTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
adminTitle.TextSize = 22
adminTitle.Font = Enum.Font.GothamBold
adminTitle.Parent = adminFrame

local adminTitleCorner = Instance.new("UICorner")
adminTitleCorner.CornerRadius = UDim.new(0, 12)
adminTitleCorner.Parent = adminTitle

-- Close Admin Button
local closeAdminButton = Instance.new("TextButton")
closeAdminButton.Size = UDim2.new(0, 40, 0, 40)
closeAdminButton.Position = UDim2.new(1, -45, 0, 5)
closeAdminButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeAdminButton.BorderSizePixel = 0
closeAdminButton.Text = "X"
closeAdminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeAdminButton.TextSize = 20
closeAdminButton.Font = Enum.Font.GothamBold
closeAdminButton.Parent = adminFrame

local closeAdminCorner = Instance.new("UICorner")
closeAdminCorner.CornerRadius = UDim.new(0, 8)
closeAdminCorner.Parent = closeAdminButton

-- Reroll Biome Button
local rerollBiomeButton = Instance.new("TextButton")
rerollBiomeButton.Size = UDim2.new(0, 200, 0, 30)
rerollBiomeButton.Position = UDim2.new(0, 170, 0, 220)
rerollBiomeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
rerollBiomeButton.BorderSizePixel = 0
rerollBiomeButton.Text = "🌍 Reroll Biome"
rerollBiomeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rerollBiomeButton.TextSize = 16
rerollBiomeButton.Font = Enum.Font.GothamBold
rerollBiomeButton.Parent = adminFrame

local rerollBiomeCorner = Instance.new("UICorner")
rerollBiomeCorner.CornerRadius = UDim.new(0, 8)
rerollBiomeCorner.Parent = rerollBiomeButton

-- Function to create dropdown
local function createDropdown(parent, pos, size, options, default)
    local ddFrame = Instance.new("Frame")
    ddFrame.Parent = parent
    ddFrame.Position = pos
    ddFrame.Size = size
    ddFrame.BackgroundTransparency = 1

    local selectButton = Instance.new("TextButton")
    selectButton.Parent = ddFrame
    selectButton.Size = UDim2.new(1, 0, 0, 30)
    selectButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    selectButton.BorderSizePixel = 0
    selectButton.Text = default
    selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectButton.TextSize = 14
    selectButton.Font = Enum.Font.Gotham
    local selCorner = Instance.new("UICorner")
    selCorner.CornerRadius = UDim.new(0, 4)
    selCorner.Parent = selectButton

    local scrollDd = Instance.new("ScrollingFrame")
    scrollDd.Parent = ddFrame
    scrollDd.Position = UDim2.new(0, 0, 0, 30)
    scrollDd.Size = UDim2.new(1, 0, 0, 100)
    scrollDd.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    scrollDd.BorderSizePixel = 0
    scrollDd.ScrollBarThickness = 6
    scrollDd.Visible = false
    local scDdCorner = Instance.new("UICorner")
    scDdCorner.CornerRadius = UDim.new(0, 4)
    scDdCorner.Parent = scrollDd

    local listDd = Instance.new("UIListLayout")
    listDd.Parent = scrollDd
    listDd.Padding = UDim.new(0, 2)
    listDd.SortOrder = Enum.SortOrder.LayoutOrder

    local currentSel = default

    selectButton.MouseButton1Click:Connect(function()
        scrollDd.Visible = not scrollDd.Visible
    end)

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Parent = scrollDd
        optBtn.Size = UDim2.new(1, -10, 0, 25)
        optBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        optBtn.BorderSizePixel = 0
        optBtn.Text = opt
        optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        optBtn.TextSize = 14
        optBtn.Font = Enum.Font.Gotham
        local optCorner = Instance.new("UICorner")
        optCorner.CornerRadius = UDim.new(0, 4)
        optCorner.Parent = optBtn

        optBtn.MouseButton1Click:Connect(function()
            currentSel = opt
            selectButton.Text = opt
            scrollDd.Visible = false
        end)
    end

    scrollDd.CanvasSize = UDim2.new(0, 0, 0, #options * 27)

    return function()
        return currentSel
    end
end

-- Admin UI elements
local luckLabel = Instance.new("TextLabel")
luckLabel.Parent = adminFrame
luckLabel.Position = UDim2.new(0, 10, 0, 60)
luckLabel.Size = UDim2.new(0, 150, 0, 30)
luckLabel.BackgroundTransparency = 1
luckLabel.Text = "Luck Multiplier:"
luckLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
luckLabel.TextSize = 16
luckLabel.Font = Enum.Font.Gotham
luckLabel.TextXAlignment = Enum.TextXAlignment.Left

local luckBox = Instance.new("TextBox")
luckBox.Parent = adminFrame
luckBox.Position = UDim2.new(0, 170, 0, 60)
luckBox.Size = UDim2.new(0, 100, 0, 30)
luckBox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
luckBox.BorderSizePixel = 0
luckBox.Text = "0"
luckBox.TextColor3 = Color3.fromRGB(255, 255, 255)
luckBox.TextSize = 16
luckBox.Font = Enum.Font.Gotham
local luckBoxCorner = Instance.new("UICorner")
luckBoxCorner.CornerRadius = UDim.new(0, 4)
luckBoxCorner.Parent = luckBox

local setLuckButton = Instance.new("TextButton")
setLuckButton.Parent = adminFrame
setLuckButton.Position = UDim2.new(0, 280, 0, 60)
setLuckButton.Size = UDim2.new(0, 150, 0, 30)
setLuckButton.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
setLuckButton.BorderSizePixel = 0
setLuckButton.Text = "Set Multiplier"
setLuckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
setLuckButton.TextSize = 16
setLuckButton.Font = Enum.Font.GothamBold
local setLuckCorner = Instance.new("UICorner")
setLuckCorner.CornerRadius = UDim.new(0, 8)
setLuckCorner.Parent = setLuckButton

local gunLabel = Instance.new("TextLabel")
gunLabel.Parent = adminFrame
gunLabel.Position = UDim2.new(0, 10, 0, 100)
gunLabel.Size = UDim2.new(0, 150, 0, 30)
gunLabel.BackgroundTransparency = 1
gunLabel.Text = "Give Gun:"
gunLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
gunLabel.TextSize = 16
gunLabel.Font = Enum.Font.Gotham
gunLabel.TextXAlignment = Enum.TextXAlignment.Left

local getGun = createDropdown(adminFrame, UDim2.new(0, 170, 0, 100), UDim2.new(0, 200, 0, 30), gunNames, gunNames[1])

local mutLabel = Instance.new("TextLabel")
mutLabel.Parent = adminFrame
mutLabel.Position = UDim2.new(0, 10, 0, 140)
mutLabel.Size = UDim2.new(0, 150, 0, 30)
mutLabel.BackgroundTransparency = 1
mutLabel.Text = "Gun Mutation:"
mutLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
mutLabel.TextSize = 16
mutLabel.Font = Enum.Font.Gotham
mutLabel.TextXAlignment = Enum.TextXAlignment.Left

local getMut = createDropdown(adminFrame, UDim2.new(0, 170, 0, 140), UDim2.new(0, 200, 0, 30), mutationNames, "None")

local sendGunButton = Instance.new("TextButton")
sendGunButton.Parent = adminFrame
sendGunButton.Position = UDim2.new(0, 170, 0, 180)
sendGunButton.Size = UDim2.new(0, 200, 0, 30)
sendGunButton.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
sendGunButton.BorderSizePixel = 0
sendGunButton.Text = "Send Gun"
sendGunButton.TextColor3 = Color3.fromRGB(255, 255, 255)
sendGunButton.TextSize = 16
sendGunButton.Font = Enum.Font.GothamBold
local sendGunCorner = Instance.new("UICorner")
sendGunCorner.CornerRadius = UDim.new(0, 8)
sendGunCorner.Parent = sendGunButton

-- Functions
local function formatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    return formatted
end

local function getRarityColor(rarity)
    if rarity <= 100 then
        return Color3.fromRGB(180, 180, 180) -- Grey
    elseif rarity <= 1000 then
        return Color3.fromRGB(0, 100, 0) -- Dark Green
    elseif rarity <= 10000 then
        return Color3.fromRGB(0, 0, 255) -- Blue
    elseif rarity <= 100000 then
        return Color3.fromRGB(255, 255, 0) -- Yellow
    elseif rarity <= 1000000 then
        return Color3.fromRGB(128, 0, 128) -- Dark Purple
    elseif rarity <= 10000000 then
        return Color3.fromRGB(255, 0, 0) -- Red
    elseif rarity <= 100000000 then
        return "cyan_darkblue" -- Animated Cyan and Dark blue gradient
    elseif rarity <= 1000000000 then
        return "rainbow" -- Rainbow animated
    elseif rarity <= 10000000000 then
        return "bw_gradient" -- Black and white gradient animated
    else
        return "red_orange_gold" -- Animated red, orange, and gold gradient
    end
end

local function applyAnimatedGradient(frame, type)
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("UIGradient") then
            child:Destroy()
        end
    end
    local gradient = Instance.new("UIGradient")
    gradient.Parent = frame
    if type == "cyan_darkblue" then
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 139))
        }
    elseif type == "rainbow" then
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 165, 0)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.666, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(75, 0, 130)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 130, 238))
        }
    elseif type == "bw_gradient" then
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
        }
    elseif type == "red_orange_gold" then
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 165, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
        }
    end
    gradient.Rotation = 0
    task.spawn(function()
        while frame and frame.Parent do
            local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(gradient, tweenInfo, {Rotation = 360})
            tween:Play()
            tween.Completed:Wait()
            gradient.Rotation = 0
        end
    end)
end

local function getRainbowText(text)
    local coloredText = ""
    local upperText = string.upper(text)
    for i = 1, #upperText do
        local char = string.sub(upperText, i, i)
        local colorIndex = (i - 1) % #rainbowColors + 1
        coloredText = coloredText .. '<font color="rgb(' .. rainbowColors[colorIndex] .. ')">' .. char .. '</font>'
    end
    return coloredText
end

local function getMutationText(mutations)
    local texts = {}
    for _, mutation in ipairs(mutations) do
        local mutText
        if mutation == "Rainbowified" then
            mutText = getRainbowText("Rainbowified")
        else
            local colorStr = mutationColors[mutation] or "255,255,255"
            mutText = '<font color="rgb(' .. colorStr .. ')">' .. string.upper(mutation) .. '</font>'
        end
        table.insert(texts, "[" .. mutText .. "]")
    end
    return table.concat(texts, " + ")
end

local function calculateEffectiveRarity(gunRarity, mutations)
    local effective = gunRarity
    for _, mut in ipairs(mutations) do
        effective = effective * (mutationRarities[mut] or 1)
    end
    return math.floor(effective)
end

local function getMoneyFromRarity(rarity)
    if rarity <= 100 then
        return math.random(5, 10)
    elseif rarity <= 1000 then
        return math.random(12, 24)
    elseif rarity <= 10000 then
        return math.random(30, 60)
    elseif rarity <= 100000 then
        return math.random(75, 150)
    elseif rarity <= 1000000 then
        return math.random(150, 300)
    elseif rarity <= 10000000 then
        return math.random(375, 750)
    elseif rarity <= 100000000 then
        return math.random(750, 1500)
    elseif rarity <= 1000000000 then
        return math.random(1000, 2000)
    elseif rarity <= 10000000000 then
        return math.random(5000, 10000)
    elseif rarity <= 100000000000 then
        return math.random(15750, 31500)
    elseif rarity <= 1000000000000000 then
        return math.random(30000, 60000)
    else
        return math.random(75000, 150000)
    end
end

local function hasPet(petName)
    for _, pet in ipairs(playerData.pets) do
        if pet.name == petName then
            return true
        end
    end
    return false
end

local function updateInventoryDisplay(tab)
    local scroll = (tab == "Guns" and gunsScrollFrame) or (tab == "Items" and itemsScrollFrame) or (tab == "Pets" and petsScrollFrame)
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    if tab == "Guns" then
        local count = {}
        for _, gun in ipairs(playerData.inventory) do
            local muts = table.concat(table.sort(table.clone(gun.mutations)), ":")
            local key = gun.baseName .. ":" .. muts
            count[key] = (count[key] or 0) + 1
            gun.key = key -- for reference
        end
        
        if next(count) == nil then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, -10, 0, 50)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "No weapons yet! Start rolling!"
            emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            emptyLabel.TextSize = 18
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.Parent = scroll
            scroll.CanvasSize = UDim2.new(0, 0, 0, 50)
            return
        end
        
        local yOffset = 0
        for key, amount in pairs(count) do
            local baseName, mutsStr = string.match(key, "([^:]+):(.+)")
            local mutations = {}
            if mutsStr ~= "" then
                mutations = string.split(mutsStr, ":")
            end
            
            local weaponData = nil
            for _, w in ipairs(weapons) do
                if w.name == baseName then
                    weaponData = w
                    break
                end
            end
            
            if weaponData then
                local effectiveRarity = calculateEffectiveRarity(weaponData.rarity, mutations)
                
                local itemFrame = Instance.new("Frame")
                itemFrame.Size = UDim2.new(1, -10, 0, 60)
                itemFrame.BorderSizePixel = 0
                itemFrame.Parent = scroll
                
                local color = getRarityColor(effectiveRarity)
                if typeof(color) == "Color3" then
                    itemFrame.BackgroundColor3 = color
                else
                    applyAnimatedGradient(itemFrame, color)
                end
                
                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = UDim.new(0, 8)
                itemCorner.Parent = itemFrame
                
                local displayName = baseName
                if #mutations > 0 then
                    displayName = displayName .. "\n" .. getMutationText(mutations)
                end
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(0.7, -10, 1, 0)
                nameLabel.Position = UDim2.new(0, 10, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = displayName
                nameLabel.RichText = true
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextSize = 16
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextWrapped = true
                nameLabel.Parent = itemFrame
                
                local rarityLabel = Instance.new("TextLabel")
                rarityLabel.Size = UDim2.new(0.3, -10, 0.5, 0)
                rarityLabel.Position = UDim2.new(0.7, 0, 0, 5)
                rarityLabel.BackgroundTransparency = 1
                rarityLabel.Text = "1/" .. formatNumber(effectiveRarity)
                rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                rarityLabel.TextSize = 14
                rarityLabel.Font = Enum.Font.Gotham
                rarityLabel.TextXAlignment = Enum.TextXAlignment.Right
                rarityLabel.Parent = itemFrame
                
                local countLabel = Instance.new("TextLabel")
                countLabel.Size = UDim2.new(0.3, -10, 0.5, 0)
                countLabel.Position = UDim2.new(0.7, 0, 0.5, -5)
                countLabel.BackgroundTransparency = 1
                countLabel.Text = "x" .. amount
                countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                countLabel.TextSize = 14
                countLabel.Font = Enum.Font.GothamBold
                countLabel.TextXAlignment = Enum.TextXAlignment.Right
                countLabel.Parent = itemFrame
                
                yOffset = yOffset + 65
            end
        end
        
        scroll.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    elseif tab == "Items" then
        local yOffset = 0
        for _, itemName in ipairs(playerData.items) do
            local itemData
            for _, shopItem in ipairs(shopItems) do
                if shopItem.name == itemName then
                    itemData = shopItem
                    break
                end
            end
            if itemData then
                local itemFrame = Instance.new("Frame")
                itemFrame.Size = UDim2.new(1, -10, 0, 80)
                itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                itemFrame.BorderSizePixel = 0
                itemFrame.Parent = scroll
                
                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = UDim.new(0, 8)
                itemCorner.Parent = itemFrame
                
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(0.7, -10, 0.375, 0)
                nameLabel.Position = UDim2.new(0, 10, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = itemName
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextSize = 16
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextWrapped = true
                nameLabel.Parent = itemFrame
                
                local descLabel = Instance.new("TextLabel")
                descLabel.Size = UDim2.new(0.7, -10, 0.625, 0)
                descLabel.Position = UDim2.new(0, 10, 0.375, 0)
                descLabel.BackgroundTransparency = 1
                descLabel.Text = itemData.description or ""
                descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                descLabel.TextSize = 14
                descLabel.Font = Enum.Font.Gotham
                descLabel.TextXAlignment = Enum.TextXAlignment.Left
                descLabel.TextWrapped = true
                descLabel.Parent = itemFrame
                
                local useButton = Instance.new("TextButton")
                useButton.Size = UDim2.new(0, 80, 0, 30)
                useButton.Position = UDim2.new(0.8, -90, 0.5, -15)
                useButton.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
                useButton.BorderSizePixel = 0
                useButton.Text = "Use"
                useButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                useButton.TextSize = 14
                useButton.Font = Enum.Font.GothamBold
                useButton.Parent = itemFrame

                local useCorner = Instance.new("UICorner")
                useCorner.CornerRadius = UDim.new(0, 8)
                useCorner.Parent = useButton

                useButton.MouseButton1Click:Connect(function()
                    if itemData.once and ((itemData.name == "Carved Pumpkin" and playerData.usedCarved) or (itemData.name == "UFO Necklace" and playerData.usedUFO)) then return end
                    itemData.func()
                    if itemData.once then
                        if itemData.name == "Carved Pumpkin" then playerData.usedCarved = true end
                        if itemData.name == "UFO Necklace" then playerData.usedUFO = true end
                    end
                    -- Remove from inventory
                    for i, v in ipairs(playerData.items) do
                        if v == itemName then
                            table.remove(playerData.items, i)
                            break
                        end
                    end
                    updateInventoryDisplay("Items")
                end)
                
                yOffset = yOffset + 85
            end
        end
        
        scroll.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    elseif tab == "Pets" then
        local count = {}
        for _, pet in ipairs(playerData.pets) do
            count[pet.name] = (count[pet.name] or 0) + 1
        end
        
        local yOffset = 0
        for name, amount in pairs(count) do
            local petData
            for _, shopItem in ipairs(shopItems) do
                if shopItem.name == name and shopItem.rarity then
                    petData = shopItem
                    break
                end
            end
            if petData then
                local itemFrame = Instance.new("Frame")
                itemFrame.Size = UDim2.new(1, -10, 0, 80)
                itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                itemFrame.BorderSizePixel = 0
                itemFrame.Parent = scroll
                
                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = UDim.new(0, 8)
                itemCorner.Parent = itemFrame
                
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(0.7, -10, 0.375, 0)
                nameLabel.Position = UDim2.new(0, 10, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = name .. " x" .. amount .. " (" .. petData.rarity .. ")"
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextSize = 16
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextWrapped = true
                nameLabel.Parent = itemFrame
                
                local descLabel = Instance.new("TextLabel")
                descLabel.Size = UDim2.new(0.7, -10, 0.625, 0)
                descLabel.Position = UDim2.new(0, 10, 0.375, 0)
                descLabel.BackgroundTransparency = 1
                descLabel.Text = petData.description or ""
                descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                descLabel.TextSize = 14
                descLabel.Font = Enum.Font.Gotham
                descLabel.TextXAlignment = Enum.TextXAlignment.Left
                descLabel.TextWrapped = true
                descLabel.Parent = itemFrame
                
                yOffset = yOffset + 85
            end
        end
        
        scroll.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    end
end

local function updateShopDisplay()
    for _, child in ipairs(shopScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local yOffset = 0
    for _, item in ipairs(shopItems) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -10, 0, 80)
        itemFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        itemFrame.BorderSizePixel = 0
        itemFrame.Parent = shopScrollFrame
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 8)
        itemCorner.Parent = itemFrame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, -10, 0.375, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = item.name .. (item.rarity and " (" .. item.rarity .. ")" or "")
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextWrapped = true
        nameLabel.Parent = itemFrame
        
        local costLabel = Instance.new("TextLabel")
        costLabel.Size = UDim2.new(0.7, -10, 0.25, 0)
        costLabel.Position = UDim2.new(0, 10, 0.375, 0)
        costLabel.BackgroundTransparency = 1
        costLabel.Text = "Cost: " .. item.cost .. " Money"
        costLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        costLabel.TextSize = 14
        costLabel.Font = Enum.Font.Gotham
        costLabel.TextXAlignment = Enum.TextXAlignment.Left
        costLabel.Parent = itemFrame
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.7, -10, 0.375, 0)
        descLabel.Position = UDim2.new(0, 10, 0.625, 0)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = item.description or ""
        descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        descLabel.TextSize = 14
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextWrapped = true
        descLabel.Parent = itemFrame
        
        local buyButton = Instance.new("TextButton")
        buyButton.Size = UDim2.new(0, 80, 0, 30)
        buyButton.Position = UDim2.new(0.8, -90, 0.5, -15)
        buyButton.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
        buyButton.BorderSizePixel = 0
        buyButton.Text = "Buy"
        buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        buyButton.TextSize = 14
        buyButton.Font = Enum.Font.GothamBold
        buyButton.Parent = itemFrame

        local buyCorner = Instance.new("UICorner")
        buyCorner.CornerRadius = UDim.new(0, 8)
        buyCorner.Parent = buyButton

        buyButton.MouseButton1Click:Connect(function()
            if playerData.money >= item.cost then
                playerData.money = playerData.money - item.cost
                if item.rarity then
                    item.func()
                else
                    table.insert(playerData.items, item.name)
                end
                updateStats()
            end
        end)
        
        yOffset = yOffset + 85
    end
    
    shopScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

local function updateStats()
    statsLabel.Text = string.format("Rolls: %d | Current Biome: %s | Money: %d", playerData.rolls, playerData.currentBiome, playerData.money)
end

local function updateBiomeTimer()
    if biomeEndTime > os.time() then
        local remaining = biomeEndTime - os.time()
        biomeTimerLabel.Text = "Biome Time Left: " .. math.floor(remaining / 60) .. " min " .. (remaining % 60) .. " sec"
    else
        biomeTimerLabel.Text = ""
    end
end

task.spawn(function()
    while true do
        updateBiomeTimer()
        task.wait(1)
    end
end)

local function rollWeapon()
    local gunLuck = math.max(1, 1 + luckMultiplier + gunLuckBoost)
    local mutationLuck = math.max(1, 1 + luckMultiplier + mutationLuckBoost)
    local biomeLuck = math.max(1, 1 + luckMultiplier + biomeLuckBoost)
    local gunExp = 1 / gunLuck
    local mutationExp = 1 / mutationLuck

    local totalWeight = 0
    local availableWeapons = {}
    
    for _, weapon in ipairs(weapons) do
        if weapon.biome == "Default" or weapon.biome == playerData.currentBiome then
            local adjustedRarity = weapon.rarity
            if weapon.name == "Druid Vine" and hasPet("Druid") then
                adjustedRarity = 5966001
            end
            local baseWeight = 1 / adjustedRarity
            local weight = math.pow(baseWeight, gunExp)
            totalWeight = totalWeight + weight
            table.insert(availableWeapons, {weapon = weapon, weight = weight, adjustedRarity = adjustedRarity})
        end
    end
    
    local roll = math.random() * totalWeight
    local current = 0
    
    local selectedEntry = nil
    for _, entry in ipairs(availableWeapons) do
        current = current + entry.weight
        if roll <= current then
            selectedEntry = entry
            break
        end
    end
    
    if selectedEntry then
        local selectedWeapon = selectedEntry.weapon
        -- Apply mutation
        local possibleMutations = {}
        for _, m in ipairs(mutations.default) do
            table.insert(possibleMutations, {name = m.name, rarity = m.rarity})
        end
        local biomeMuts = mutations[playerData.currentBiome]
        if biomeMuts then
            for _, m in ipairs(biomeMuts) do
                table.insert(possibleMutations, {name = m.name, rarity = m.rarity})
            end
        end
        
        if playerData.currentBiome == "Pumpkin Wrath" and hasPet("Pumpkin Head Deer") then
            for _, m in ipairs(possibleMutations) do
                if m.name == "Pumpkinized" then m.rarity = 5 end
                if m.name == "SoulFlamed" then m.rarity = 7 end
            end
        end
        
        table.sort(possibleMutations, function(a, b) return a.rarity > b.rarity end)  -- Rarest first
        
        local mutationName = nil
        for _, m in ipairs(possibleMutations) do
            local baseProb = 1 / m.rarity
            local adjustedProb = math.pow(baseProb, mutationExp)
            if math.random() < adjustedProb then
                mutationName = m.name
                break
            end
        end
        
        local mutationsList = mutationName and {mutationName} or {}
        local newGun = {baseName = selectedWeapon.name, mutations = mutationsList}
        
        local effectiveRarity = calculateEffectiveRarity(selectedWeapon.rarity, mutationsList)
        
        local displayName = selectedWeapon.name
        if #mutationsList > 0 then
            displayName = displayName .. '\n' .. getMutationText(mutationsList)
        end
        
        playerData.rolls = playerData.rolls + 1
        table.insert(playerData.inventory, newGun)
        playerData.money = playerData.money + getMoneyFromRarity(effectiveRarity)
        
        updateStats()
        
        local color = getRarityColor(effectiveRarity)
        if typeof(color) == "Color3" then
            resultFrame.BackgroundColor3 = color
            for _, child in ipairs(resultFrame:GetChildren()) do
                if child:IsA("UIGradient") then
                    child:Destroy()
                end
            end
        else
            applyAnimatedGradient(resultFrame, color)
        end
        resultLabel.Text = string.format("✨ %s ✨\n1/%s", displayName, formatNumber(effectiveRarity))
        
        return selectedWeapon
    end
end

local function applyMutationToRandomGun(mutation)
    if #playerData.inventory == 0 then return end
    local index = math.random(1, #playerData.inventory)
    table.insert(playerData.inventory[index].mutations, mutation)
end

local function giveRandomLowRarityGun()
    local lowWeapons = {}
    for _, w in ipairs(weapons) do
        if w.rarity <= 1000 then
            table.insert(lowWeapons, w)
        end
    end
    if #lowWeapons > 0 then
        local selected = lowWeapons[math.random(1, #lowWeapons)]
        table.insert(playerData.inventory, {baseName = selected.name, mutations = {}})
    end
end

local function giveRandomPotionI()
    local potions = {"Lucky Potion I", "Mutation Potion I", "Biome Potion I"}
    table.insert(playerData.items, potions[math.random(1, #potions)])
end

task.spawn(function()
    while true do
        local now = os.time()
        for _, pet in ipairs(playerData.pets) do
            local interval = 0
            local prob = 0
            local action = nil
            if pet.name == "Fox" then
                interval = 600
                prob = 0.5
                action = giveRandomLowRarityGun
            elseif pet.name == "Owl" then
                interval = 90
                prob = 1
                action = function() applyMutationToRandomGun("Nightbloom") end
            elseif pet.name == "Dog" then
                interval = 60
                prob = 0.05
                action = giveRandomPotionI
            elseif pet.name == "Giant Fire Ant" then
                interval = 60
                prob = 0.5
                action = function() applyMutationToRandomGun("Burning") end
            elseif pet.name == "Druid" then
                interval = 120
                prob = 1
                action = function() applyMutationToRandomGun("Natural") end
            end
            -- Pumpkin Head Deer is passive, no action here
            if interval > 0 and now - pet.lastAction >= interval then
                pet.lastAction = now
                if math.random() < prob then
                    action()
                end
            end
        end
        task.wait(1)
    end
end)

local autoRolling = false
rollButton.MouseButton1Click:Connect(function()
    if not autoRolling then
        rollWeapon()
    end
end)

autoRollButton.MouseButton1Click:Connect(function()
    autoRolling = not autoRolling
    autoRollButton.Text = autoRolling and "⏸️ Stop" or "⚡ Auto Roll"
    autoRollButton.BackgroundColor3 = autoRolling and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(200, 150, 50)
    
    if autoRolling then
        task.spawn(function()
            while autoRolling do
                rollWeapon()
                task.wait(0.1)
            end
        end)
    end
end)

invButton.MouseButton1Click:Connect(function()
    invFrame.Visible = true
    updateInventoryDisplay("Guns")
end)

closeInvButton.MouseButton1Click:Connect(function()
    invFrame.Visible = false
end)

gunsTabButton.MouseButton1Click:Connect(function()
    gunsTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    itemsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    petsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    gunsScrollFrame.Visible = true
    itemsScrollFrame.Visible = false
    petsScrollFrame.Visible = false
    updateInventoryDisplay("Guns")
end)

itemsTabButton.MouseButton1Click:Connect(function()
    gunsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    itemsTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    petsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    gunsScrollFrame.Visible = false
    itemsScrollFrame.Visible = true
    petsScrollFrame.Visible = false
    updateInventoryDisplay("Items")
end)

petsTabButton.MouseButton1Click:Connect(function()
    gunsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    itemsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    petsTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    gunsScrollFrame.Visible = false
    itemsScrollFrame.Visible = false
    petsScrollFrame.Visible = true
    updateInventoryDisplay("Pets")
end)

shopButton.MouseButton1Click:Connect(function()
    shopFrame.Visible = true
    updateShopDisplay()
end)

closeShopButton.MouseButton1Click:Connect(function()
    shopFrame.Visible = false
end)

local biomes = {"Default", "Pumpkin Wrath", "Robot Invasion", "Steampunk", "Night City", "Graveyard", "Alien Invasion"}
local currentBiomeIndex = 1

rerollBiomeButton.MouseButton1Click:Connect(function()
    currentBiomeIndex = math.random(1, #biomes)
    playerData.currentBiome = biomes[currentBiomeIndex]
    updateStats()
end)

-- Auto biome changer
task.spawn(function()
    while true do
        if playerData.currentBiome == "Default" then
            task.wait(7 * 60)  -- Wait 7 minutes
            -- Check for new biome
            local specialBiomes = {
                {name = "Night City", rarity = 80, duration = 5 * 60},
                {name = "Robot Invasion", rarity = 35, duration = 6 * 60},
                {name = "Steampunk", rarity = 10, duration = 7 * 60},
                {name = "Pumpkin Wrath", rarity = 2, duration = 5 * 60},
                {name = "Graveyard", rarity = 69, duration = 5 * 60},
                {name = "Alien Invasion", rarity = 100, duration = 6 * 60}
            }
            local candidates = {}
            for _, b in ipairs(specialBiomes) do
                local effectiveRar = b.rarity / biomeLuckBoost -- Use biomeLuckBoost here
                if math.random(1, math.floor(effectiveRar)) == 1 then
                    table.insert(candidates, b)
                end
            end
            local selected = nil
            if #candidates > 0 then
                table.sort(candidates, function(a, b) return a.rarity > b.rarity end)
                selected = candidates[1]
            end
            if selected then
                playerData.currentBiome = selected.name
                biomeEndTime = os.time() + selected.duration
                biomeDuration = selected.duration
                updateStats()
                task.wait(selected.duration)
                playerData.currentBiome = "Default"
                biomeEndTime = 0
                updateStats()
            end
            -- If not selected, loop will wait another 7 minutes next time
        else
            task.wait(1)  -- Check again soon if not in default
        end
    end
end)

-- Potion timers
task.spawn(function()
    while true do
        for key, time in pairs(potionTimers) do
            if time > 0 then
                potionTimers[key] = time - 1
                if potionTimers[key] == 0 then
                    notificationLabel.Text = key .. " ran out!"
                    task.delay(5, function() notificationLabel.Text = "" end)
                    if string.find(key, "luckyPotion") then
                        gunLuckBoost = 0
                    elseif string.find(key, "mutationPotion") then
                        mutationLuckBoost = 0
                    elseif string.find(key, "biomePotion") then
                        biomeLuckBoost = 0
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- Admin connections
adminButton.MouseButton1Click:Connect(function()
    adminFrame.Visible = true
end)

closeAdminButton.MouseButton1Click:Connect(function()
    adminFrame.Visible = false
end)

setLuckButton.MouseButton1Click:Connect(function()
    luckMultiplier = tonumber(luckBox.Text) or 0
    luckMultiplier = math.max(0, luckMultiplier)  -- Clamp to >=0
end)

sendGunButton.MouseButton1Click:Connect(function()
    local selectedGun = getGun()
    local selectedMut = getMut()
    local mutations = selectedMut ~= "None" and {selectedMut} or {}
    table.insert(playerData.inventory, {baseName = selectedGun, mutations = mutations})
    -- Optionally update result, but skip for now
end)

print("Weapon Rarity Simulator loaded!")
