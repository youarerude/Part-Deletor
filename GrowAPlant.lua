--[[
    Roblox Plant Shop System - Mobile Friendly
    Place this LocalScript in StarterGui or StarterPlayer > StarterPlayerScripts
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Setup Player Money
local function setupMoney()
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    
    local money = leaderstats:FindFirstChild("Money")
    if not money then
        money = Instance.new("IntValue")
        money.Name = "Money"
        money.Value = 50
        money.Parent = leaderstats
    end
    return money
end

local playerMoney = setupMoney()

-- Player Inventory
local playerInventory = {}
local playerGarden = {}

-- Shop Items Configuration (Main Shop)
local shopItems = {
    {name = "Carrot Seed", cost = 15, stockChance = 1, rarity = "Common", color = Color3.fromRGB(150, 150, 150), plantName = "Carrot Plant", produceName = "Carrot", growTime = 30, produceWorth = 25, produceKG = 0.5},
    {name = "Strawberry Seed", cost = 30, stockChance = 2, rarity = "Common", color = Color3.fromRGB(150, 150, 150), plantName = "Strawberry Plant", produceName = "Strawberry", growTime = 45, produceWorth = 50, produceKG = 0.3},
    {name = "Lemon Seed", cost = 75, stockChance = 3, rarity = "Common", color = Color3.fromRGB(150, 150, 150), plantName = "Lemon Plant", produceName = "Lemon", growTime = 60, produceWorth = 120, produceKG = 0.4},
    {name = "Kiwi Seed", cost = 100, stockChance = 5, rarity = "Common", color = Color3.fromRGB(150, 150, 150), plantName = "Kiwi Plant", produceName = "Kiwi", growTime = 75, produceWorth = 160, produceKG = 0.5},
    {name = "Coconut Seed", cost = 500, stockChance = 15, rarity = "Uncommon", color = Color3.fromRGB(85, 255, 127), plantName = "Coconut Plant", produceName = "Coconut", growTime = 120, produceWorth = 800, produceKG = 1.2},
    {name = "Mushroom Seed", cost = 750, stockChance = 17, rarity = "Uncommon", color = Color3.fromRGB(85, 255, 127), plantName = "Mushroom Plant", produceName = "Mushroom", growTime = 90, produceWorth = 1200, produceKG = 0.3},
    {name = "Mango Seed", cost = 900, stockChance = 18, rarity = "Uncommon", color = Color3.fromRGB(85, 255, 127), plantName = "Mango Plant", produceName = "Mango", growTime = 150, produceWorth = 1500, produceKG = 0.8},
    {name = "Banana Seed", cost = 1200, stockChance = 19, rarity = "Uncommon", color = Color3.fromRGB(85, 255, 127), plantName = "Banana Plant", produceName = "Banana", growTime = 180, produceWorth = 2000, produceKG = 1.0},
    {name = "Olive Seed", cost = 9000, stockChance = 30, rarity = "Rare", color = Color3.fromRGB(85, 170, 255), plantName = "Olive Plant", produceName = "Olive", growTime = 240, produceWorth = 15000, produceKG = 0.6},
    {name = "Persimmon Seed", cost = 10000, stockChance = 33, rarity = "Rare", color = Color3.fromRGB(85, 170, 255), plantName = "Persimmon Plant", produceName = "Persimmon", growTime = 260, produceWorth = 17000, produceKG = 0.7},
    {name = "Pineapple Seed", cost = 15000, stockChance = 35, rarity = "Rare", color = Color3.fromRGB(85, 170, 255), plantName = "Pineapple Plant", produceName = "Pineapple", growTime = 300, produceWorth = 25000, produceKG = 1.5},
    {name = "Jackfruit Seed", cost = 25000, stockChance = 36, rarity = "Rare", color = Color3.fromRGB(85, 170, 255), plantName = "Jackfruit Plant", produceName = "Jackfruit", growTime = 350, produceWorth = 40000, produceKG = 3.0},
    {name = "Pear Seed", cost = 30000, stockChance = 40, rarity = "Rare", color = Color3.fromRGB(85, 170, 255), plantName = "Pear Plant", produceName = "Pear", growTime = 320, produceWorth = 50000, produceKG = 0.8},
    {name = "Blueberry Seed", cost = 100000, stockChance = 75, rarity = "Epic", color = Color3.fromRGB(170, 0, 255), plantName = "Blueberry Plant", produceName = "Blueberry", growTime = 400, produceWorth = 170000, produceKG = 0.4},
    {name = "Pumpkin Seed", cost = 125000, stockChance = 76, rarity = "Epic", color = Color3.fromRGB(170, 0, 255), plantName = "Pumpkin Plant", produceName = "Pumpkin", growTime = 450, produceWorth = 210000, produceKG = 5.0},
    {name = "Citrus Seed", cost = 175000, stockChance = 78, rarity = "Epic", color = Color3.fromRGB(170, 0, 255), plantName = "Citrus Plant", produceName = "Citrus", growTime = 480, produceWorth = 300000, produceKG = 0.6},
    {name = "Sugarcane Seed", cost = 230000, stockChance = 80, rarity = "Epic", color = Color3.fromRGB(170, 0, 255), plantName = "Sugarcane Plant", produceName = "Sugarcane", growTime = 500, produceWorth = 400000, produceKG = 2.0},
    {name = "Grape Seed", cost = 300000, stockChance = 85, rarity = "Epic", color = Color3.fromRGB(170, 0, 255), plantName = "Grape Plant", produceName = "Grape", growTime = 550, produceWorth = 520000, produceKG = 1.0},
    {name = "Custard Apple Seed", cost = 800000, stockChance = 100, rarity = "Legendary", color = Color3.fromRGB(255, 170, 0), plantName = "Custard Apple Plant", produceName = "Custard Apple", growTime = 600, produceWorth = 1400000, produceKG = 1.2},
    {name = "Elderberry Seed", cost = 950000, stockChance = 105, rarity = "Legendary", color = Color3.fromRGB(255, 170, 0), plantName = "Elderberry Plant", produceName = "Elderberry", growTime = 650, produceWorth = 1700000, produceKG = 0.5},
    {name = "Shaddock Seed", cost = 1000000, stockChance = 110, rarity = "Legendary", color = Color3.fromRGB(255, 170, 0), plantName = "Shaddock Plant", produceName = "Shaddock", growTime = 700, produceWorth = 1800000, produceKG = 1.5},
    {name = "Grapefruit Seed", cost = 1200000, stockChance = 112, rarity = "Legendary", color = Color3.fromRGB(255, 170, 0), plantName = "Grapefruit Plant", produceName = "Grapefruit", growTime = 720, produceWorth = 2200000, produceKG = 0.9},
    {name = "Lychee Seed", cost = 1570300, stockChance = 115, rarity = "Legendary", color = Color3.fromRGB(255, 170, 0), plantName = "Lychee Plant", produceName = "Lychee", growTime = 750, produceWorth = 2900000, produceKG = 0.3},
    {name = "Fig Seed", cost = 2000000, stockChance = 120, rarity = "Legendary", color = Color3.fromRGB(255, 170, 0), plantName = "Fig Plant", produceName = "Fig", growTime = 800, produceWorth = 3700000, produceKG = 0.4},
    {name = "Cocovine Seed", cost = 10000000, stockChance = 300, rarity = "Mythical", color = Color3.fromRGB(170, 0, 170), plantName = "Cocovine Plant", produceName = "Cocovine", growTime = 1000, produceWorth = 18000000, produceKG = 2.5},
    {name = "Maple Seed", cost = 15000000, stockChance = 310, rarity = "Mythical", color = Color3.fromRGB(170, 0, 170), plantName = "Maple Plant", produceName = "Maple", growTime = 1100, produceWorth = 28000000, produceKG = 1.0},
    {name = "Lotus Seed", cost = 23750000, stockChance = 320, rarity = "Mythical", color = Color3.fromRGB(170, 0, 170), plantName = "Lotus Plant", produceName = "Lotus", growTime = 1200, produceWorth = 44000000, produceKG = 0.8},
    {name = "Amaryllis Seed", cost = 30000000, stockChance = 325, rarity = "Mythical", color = Color3.fromRGB(170, 0, 170), plantName = "Amaryllis Plant", produceName = "Amaryllis", growTime = 1300, produceWorth = 56000000, produceKG = 0.6},
    {name = "Garlic Seed", cost = 45200000, stockChance = 345, rarity = "Mythical", color = Color3.fromRGB(170, 0, 170), plantName = "Garlic Plant", produceName = "Garlic", growTime = 1400, produceWorth = 85000000, produceKG = 0.5},
    {name = "Pokeweed Seed", cost = 81000000, stockChance = 750, rarity = "Ancient", color = Color3.fromRGB(0, 100, 0), plantName = "Pokeweed Plant", produceName = "Pokeweed", growTime = 1800, produceWorth = 150000000, produceKG = 1.5},
    {name = "Leopard Lily Seed", cost = 90000000, stockChance = 760, rarity = "Ancient", color = Color3.fromRGB(0, 100, 0), plantName = "Leopard Lily Plant", produceName = "Leopard Lily", growTime = 1900, produceWorth = 170000000, produceKG = 0.4},
    {name = "Bittercress Seed", cost = 100000000, stockChance = 777, rarity = "Ancient", color = Color3.fromRGB(0, 100, 0), plantName = "Bittercress Plant", produceName = "Bittercress", growTime = 2000, produceWorth = 190000000, produceKG = 0.3},
    {name = "Honesty Seed", cost = 125000000, stockChance = 780, rarity = "Ancient", color = Color3.fromRGB(0, 100, 0), plantName = "Honesty Plant", produceName = "Honesty", growTime = 2100, produceWorth = 240000000, produceKG = 0.5},
    {name = "Passion Fruit Seed", cost = 150000000, stockChance = 785, rarity = "Ancient", color = Color3.fromRGB(0, 100, 0), plantName = "Passion Fruit Plant", produceName = "Passion Fruit", growTime = 2200, produceWorth = 290000000, produceKG = 0.7},
    {name = "River Maple Seed", cost = 175000000, stockChance = 790, rarity = "Ancient", color = Color3.fromRGB(0, 100, 0), plantName = "River Maple Plant", produceName = "River Maple", growTime = 2300, produceWorth = 340000000, produceKG = 1.0},
    {name = "Golden Garlic Seed", cost = 200000000, stockChance = 800, rarity = "Ancient", color = Color3.fromRGB(0, 100, 0), plantName = "Golden Garlic Plant", produceName = "Golden Garlic", growTime = 2500, produceWorth = 390000000, produceKG = 0.4},
}

-- Weather Configuration
local weathers = {
    {
        name = "Night",
        encounterChance = 2,
        duration = 5 * 60,
        mutations = {
            {name = "Lunaric", applyChance = 10, multiplier = 3},
        },
        merchantItems = {
            {name = "MoonBloom Seed", cost = 23000, stockChance = 2, rarity = "Rare", color = Color3.fromRGB(85, 170, 255), plantName = "MoonBloom Plant", produceName = "MoonBloom", growTime = 300, produceWorth = 40000, produceKG = 0.5},
            {name = "StarFruit Seed", cost = 310000, stockChance = 4, rarity = "Epic", color = Color3.fromRGB(170, 0, 255), plantName = "StarFruit Plant", produceName = "StarFruit", growTime = 450, produceWorth = 550000, produceKG = 0.6},
            {name = "Ghost Orchid Seed", cost = 450000, stockChance = 9, rarity = "Epic", color = Color3.fromRGB(170, 0, 255), plantName = "Ghost Orchid Plant", produceName = "Ghost Orchid", growTime = 500, produceWorth = 800000, produceKG = 0.4},
            {name = "Crescent Berry Seed", cost = 222222222, stockChance = 50, rarity = "Ancient", color = Color3.fromRGB(0, 100, 0), plantName = "Crescent Berry Plant", produceName = "Crescent Berry", growTime = 2000, produceWorth = 400000000, produceKG = 0.3},
        }
    },
    {
        name = "Arctic Zone",
        encounterChance = 4,
        duration = 7 * 60,
        mutations = {
            {name = "Cold", applyChance = 15, multiplier = 2},
            {name = "Frozen", applyChance = 30, multiplier = 7},
            {name = "Subzero", applyChance = 100, multiplier = 75},
        },
        merchantItems = {
            {name = "Snow Orchid Seed", cost = 500000, stockChance = 2, rarity = "Legendary", color = Color3.fromRGB(255, 170, 0), plantName = "Snow Orchid Plant", produceName = "Snow Orchid", growTime = 600, produceWorth = 900000, produceKG = 0.4},
            {name = "FrostSpike Seed", cost = 750000, stockChance = 3, rarity = "Legendary", color = Color3.fromRGB(255, 170, 0), plantName = "FrostSpike Plant", produceName = "FrostSpike", growTime = 650, produceWorth = 1300000, produceKG = 0.5},
            {name = "Queen of Blizzard Seed", cost = 40000000, stockChance = 8, rarity = "Mythical", color = Color3.fromRGB(170, 0, 170), plantName = "Queen of Blizzard Plant", produceName = "Queen of Blizzard", growTime = 1000, produceWorth = 70000000, produceKG = 1.0},
            {name = "Frosted Spike Sundew Seed", cost = 50000000, stockChance = 16, rarity = "Mythical", color = Color3.fromRGB(170, 0, 170), plantName = "Frosted Spike Sundew Plant", produceName = "Frosted Spike Sundew", growTime = 1100, produceWorth = 90000000, produceKG = 0.8},
            {name = "Subzero Onion Seed", cost = 190000000, stockChance = 35, rarity = "Ancient", color = Color3.fromRGB(0, 100, 0), plantName = "Subzero Onion Plant", produceName = "Subzero Onion", growTime = 2000, produceWorth = 350000000, produceKG = 0.6},
        }
    },
    {
        name = "Chernobyl",
        encounterChance = 9,
        duration = 6 * 60,
        mutations = {
            {name = "Withered", applyChance = 19, multiplier = 5},
            {name = "Radioactive", applyChance = 25, multiplier = 15},
        },
        merchantItems = {
            {name = "Radioactive Daisy Seed", cost = 305000, stockChance = 2, rarity = "Epic", color = Color3.fromRGB(170, 0, 255), plantName = "Radioactive Daisy Plant", produceName = "Radioactive Daisy", growTime = 450, produceWorth = 550000, produceKG = 0.3},
            {name = "Withered Nuclearic Tree Seed", cost = 12000000, stockChance = 7, rarity = "Mythical", color = Color3.fromRGB(170, 0, 170), plantName = "Withered Nuclearic Tree Plant", produceName = "Withered Nuclearic Fruit", growTime = 1200, produceWorth = 22000000, produceKG = 1.2},
            {name = "Chernobyl Traveler Seed", cost = 320500000, stockChance = 66, rarity = "Ancient", color = Color3.fromRGB(0, 100, 0), plantName = "Chernobyl Traveler Plant", produceName = "Chernobyl Traveler", growTime = 2200, produceWorth = 600000000, produceKG = 0.7},
        }
    },
}

-- All Seed Configurations
local seedConfigs = {}
for _, item in ipairs(shopItems) do
    table.insert(seedConfigs, item)
end
for _, weather in ipairs(weathers) do
    for _, item in ipairs(weather.merchantItems) do
        table.insert(seedConfigs, item)
    end
end

-- Stock System (Main Shop)
local itemStocks = {}

local function generateStock()
    for _, item in ipairs(shopItems) do
        local roll = math.random(1, item.stockChance)
        if roll == 1 then
            itemStocks[item.name] = math.random(1, 10)
        else
            itemStocks[item.name] = 0
        end
    end
end

-- Merchant Stocks
local merchantStocks = {}

local function formatMoney(amount)
    return "$" .. tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%d:%02d", minutes, secs)
end

local function createGradientLabel(parent, text, color1, color2)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(color1, color2)
    gradient.Rotation = 90
    gradient.Parent = label
    
    return label
end

local function findSeedConfig(name)
    for _, item in ipairs(seedConfigs) do
        if item.name == name then
            return item
        end
    end
    return nil
end

local function calculateMultiplier(produce)
    local mult = 1
    if produce.mutations then
        for _, mut in ipairs(produce.mutations) do
            mult = mult * mut.multiplier
        end
    end
    return mult
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlantShopGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Money Display
local moneyDisplay = Instance.new("TextLabel")
moneyDisplay.Name = "MoneyDisplay"
moneyDisplay.Size = UDim2.new(0, 150, 0, 50)
moneyDisplay.Position = UDim2.new(0.5, -75, 0, 10)
moneyDisplay.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
moneyDisplay.BorderSizePixel = 0
moneyDisplay.Font = Enum.Font.GothamBold
moneyDisplay.Text = formatMoney(playerMoney.Value)
moneyDisplay.TextColor3 = Color3.fromRGB(85, 255, 85)
moneyDisplay.TextSize = 24
moneyDisplay.Parent = screenGui

local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0.2, 0)
moneyCorner.Parent = moneyDisplay

playerMoney.Changed:Connect(function()
    moneyDisplay.Text = formatMoney(playerMoney.Value)
end)

-- Weather Display
local weatherDisplay = Instance.new("TextLabel")
weatherDisplay.Name = "WeatherDisplay"
weatherDisplay.Size = UDim2.new(0, 200, 0, 30)
weatherDisplay.Position = UDim2.new(0.5, -100, 0, 60)
weatherDisplay.BackgroundTransparency = 1
weatherDisplay.Font = Enum.Font.Gotham
weatherDisplay.Text = "Weather: Clear"
weatherDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
weatherDisplay.TextSize = 18
weatherDisplay.Parent = screenGui

-- Shop Button
local shopButton = Instance.new("TextButton")
shopButton.Name = "ShopButton"
shopButton.Size = UDim2.new(0, 80, 0, 80)
shopButton.Position = UDim2.new(0.05, 0, 0.3, 0)
shopButton.BackgroundColor3 = Color3.fromRGB(0, 170, 127)
shopButton.BorderSizePixel = 0
shopButton.Font = Enum.Font.GothamBold
shopButton.Text = "SHOP"
shopButton.TextColor3 = Color3.new(1, 1, 1)
shopButton.TextSize = 20
shopButton.TextScaled = true
shopButton.Parent = screenGui

local shopButtonCorner = Instance.new("UICorner")
shopButtonCorner.CornerRadius = UDim.new(0.2, 0)
shopButtonCorner.Parent = shopButton

-- Inventory Button
local inventoryButton = Instance.new("TextButton")
inventoryButton.Name = "InventoryButton"
inventoryButton.Size = UDim2.new(0, 80, 0, 80)
inventoryButton.Position = UDim2.new(0.05, 0, 0.45, 0)
inventoryButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
inventoryButton.BorderSizePixel = 0
inventoryButton.Font = Enum.Font.GothamBold
inventoryButton.Text = "INV"
inventoryButton.TextColor3 = Color3.new(1, 1, 1)
inventoryButton.TextSize = 20
inventoryButton.TextScaled = true
inventoryButton.Parent = screenGui

local invButtonCorner = Instance.new("UICorner")
invButtonCorner.CornerRadius = UDim.new(0.2, 0)
invButtonCorner.Parent = inventoryButton

-- Garden Button
local gardenButton = Instance.new("TextButton")
gardenButton.Name = "GardenButton"
gardenButton.Size = UDim2.new(0, 80, 0, 80)
gardenButton.Position = UDim2.new(0.05, 0, 0.6, 0)
gardenButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
gardenButton.BorderSizePixel = 0
gardenButton.Font = Enum.Font.GothamBold
gardenButton.Text = "GARDEN"
gardenButton.TextColor3 = Color3.new(1, 1, 1)
gardenButton.TextSize = 18
gardenButton.TextScaled = true
gardenButton.Parent = screenGui

local gardenButtonCorner = Instance.new("UICorner")
gardenButtonCorner.CornerRadius = UDim.new(0.2, 0)
gardenButtonCorner.Parent = gardenButton

-- Merchant Button
local merchantButton = Instance.new("TextButton")
merchantButton.Name = "MerchantButton"
merchantButton.Size = UDim2.new(0, 80, 0, 80)
merchantButton.Position = UDim2.new(0.05, 0, 0.75, 0)
merchantButton.BackgroundColor3 = Color3.fromRGB(170, 0, 170)
merchantButton.BorderSizePixel = 0
merchantButton.Font = Enum.Font.GothamBold
merchantButton.Text = "MERCHANT"
merchantButton.TextColor3 = Color3.new(1, 1, 1)
merchantButton.TextSize = 18
merchantButton.TextScaled = true
merchantButton.Visible = false
merchantButton.Parent = screenGui

local merchantButtonCorner = Instance.new("UICorner")
merchantButtonCorner.CornerRadius = UDim.new(0.2, 0)
merchantButtonCorner.Parent = merchantButton

-- Admin Button
local adminButton = Instance.new("TextButton")
adminButton.Name = "AdminButton"
adminButton.Size = UDim2.new(0, 80, 0, 80)
adminButton.Position = UDim2.new(0.05, 0, 0.9, 0)
adminButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
adminButton.BorderSizePixel = 0
adminButton.Font = Enum.Font.GothamBold
adminButton.Text = "ADMIN"
adminButton.TextColor3 = Color3.new(1, 1, 1)
adminButton.TextSize = 18
adminButton.TextScaled = true
adminButton.Parent = screenGui

local adminButtonCorner = Instance.new("UICorner")
adminButtonCorner.CornerRadius = UDim.new(0.2, 0)
adminButtonCorner.Parent = adminButton

-- Shop Frame
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = screenGui

local shopFrameCorner = Instance.new("UICorner")
shopFrameCorner.CornerRadius = UDim.new(0.02, 0)
shopFrameCorner.Parent = shopFrame

local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "ShopTitle"
shopTitle.Size = UDim2.new(1, 0, 0, 50)
shopTitle.Position = UDim2.new(0, 0, 0, 10)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Text = "PLANT SEED SHOP"
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.TextSize = 28
shopTitle.Parent = shopFrame

local shopCloseButton = Instance.new("TextButton")
shopCloseButton.Name = "CloseButton"
shopCloseButton.Size = UDim2.new(0, 40, 0, 40)
shopCloseButton.Position = UDim2.new(1, -50, 0, 10)
shopCloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
shopCloseButton.BorderSizePixel = 0
shopCloseButton.Font = Enum.Font.GothamBold
shopCloseButton.Text = "X"
shopCloseButton.TextColor3 = Color3.new(1, 1, 1)
shopCloseButton.TextSize = 24
shopCloseButton.Parent = shopFrame

local shopCloseCorner = Instance.new("UICorner")
shopCloseCorner.CornerRadius = UDim.new(0.2, 0)
shopCloseCorner.Parent = shopCloseButton

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(0.5, 0, 0, 30)
timerLabel.Position = UDim2.new(0.25, 0, 0, 60)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.Gotham
timerLabel.Text = "Next Restock: 3:00"
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
timerLabel.TextSize = 18
timerLabel.Parent = shopFrame

local shopScrollFrame = Instance.new("ScrollingFrame")
shopScrollFrame.Name = "ScrollFrame"
shopScrollFrame.Size = UDim2.new(1, -20, 1, -110)
shopScrollFrame.Position = UDim2.new(0, 10, 0, 100)
shopScrollFrame.BackgroundTransparency = 1
shopScrollFrame.BorderSizePixel = 0
shopScrollFrame.ScrollBarThickness = 8
shopScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
shopScrollFrame.Parent = shopFrame

local shopScrollLayout = Instance.new("UIListLayout")
shopScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopScrollLayout.Padding = UDim.new(0, 8)
shopScrollLayout.Parent = shopScrollFrame

-- Merchant Frame
local merchantFrame = Instance.new("Frame")
merchantFrame.Name = "MerchantFrame"
merchantFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
merchantFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
merchantFrame.AnchorPoint = Vector2.new(0.5, 0.5)
merchantFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
merchantFrame.BorderSizePixel = 0
merchantFrame.Visible = false
merchantFrame.Parent = screenGui

local merchantFrameCorner = Instance.new("UICorner")
merchantFrameCorner.CornerRadius = UDim.new(0.02, 0)
merchantFrameCorner.Parent = merchantFrame

local merchantTitle = Instance.new("TextLabel")
merchantTitle.Name = "MerchantTitle"
merchantTitle.Size = UDim2.new(1, 0, 0, 50)
merchantTitle.Position = UDim2.new(0, 0, 0, 10)
merchantTitle.BackgroundTransparency = 1
merchantTitle.Font = Enum.Font.GothamBold
merchantTitle.Text = "TRAVELING MERCHANT"
merchantTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
merchantTitle.TextSize = 28
merchantTitle.Parent = merchantFrame

local merchantCloseButton = Instance.new("TextButton")
merchantCloseButton.Name = "CloseButton"
merchantCloseButton.Size = UDim2.new(0, 40, 0, 40)
merchantCloseButton.Position = UDim2.new(1, -50, 0, 10)
merchantCloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
merchantCloseButton.BorderSizePixel = 0
merchantCloseButton.Font = Enum.Font.GothamBold
merchantCloseButton.Text = "X"
merchantCloseButton.TextColor3 = Color3.new(1, 1, 1)
merchantCloseButton.TextSize = 24
merchantCloseButton.Parent = merchantFrame

local merchantCloseCorner = Instance.new("UICorner")
merchantCloseCorner.CornerRadius = UDim.new(0.2, 0)
merchantCloseCorner.Parent = merchantCloseButton

local merchantScrollFrame = Instance.new("ScrollingFrame")
merchantScrollFrame.Name = "ScrollFrame"
merchantScrollFrame.Size = UDim2.new(1, -20, 1, -70)
merchantScrollFrame.Position = UDim2.new(0, 10, 0, 70)
merchantScrollFrame.BackgroundTransparency = 1
merchantScrollFrame.BorderSizePixel = 0
merchantScrollFrame.ScrollBarThickness = 8
merchantScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
merchantScrollFrame.Parent = merchantFrame

local merchantScrollLayout = Instance.new("UIListLayout")
merchantScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
merchantScrollLayout.Padding = UDim.new(0, 8)
merchantScrollLayout.Parent = merchantScrollFrame

-- Inventory Frame
local inventoryFrame = Instance.new("Frame")
inventoryFrame.Name = "InventoryFrame"
inventoryFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
inventoryFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
inventoryFrame.AnchorPoint = Vector2.new(0.5, 0.5)
inventoryFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
inventoryFrame.BorderSizePixel = 0
inventoryFrame.Visible = false
inventoryFrame.Parent = screenGui

local invFrameCorner = Instance.new("UICorner")
invFrameCorner.CornerRadius = UDim.new(0.02, 0)
invFrameCorner.Parent = inventoryFrame

local invTitle = Instance.new("TextLabel")
invTitle.Size = UDim2.new(1, 0, 0, 50)
invTitle.Position = UDim2.new(0, 0, 0, 10)
invTitle.BackgroundTransparency = 1
invTitle.Font = Enum.Font.GothamBold
invTitle.Text = "INVENTORY"
invTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
invTitle.TextSize = 28
invTitle.Parent = inventoryFrame

local invCloseButton = Instance.new("TextButton")
invCloseButton.Size = UDim2.new(0, 40, 0, 40)
invCloseButton.Position = UDim2.new(1, -50, 0, 10)
invCloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
invCloseButton.BorderSizePixel = 0
invCloseButton.Font = Enum.Font.GothamBold
invCloseButton.Text = "X"
invCloseButton.TextColor3 = Color3.new(1, 1, 1)
invCloseButton.TextSize = 24
invCloseButton.Parent = inventoryFrame

local invCloseCorner = Instance.new("UICorner")
invCloseCorner.CornerRadius = UDim.new(0.2, 0)
invCloseCorner.Parent = invCloseButton

local invScrollFrame = Instance.new("ScrollingFrame")
invScrollFrame.Size = UDim2.new(1, -20, 1, -80)
invScrollFrame.Position = UDim2.new(0, 10, 0, 70)
invScrollFrame.BackgroundTransparency = 1
invScrollFrame.BorderSizePixel = 0
invScrollFrame.ScrollBarThickness = 8
invScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
invScrollFrame.Parent = inventoryFrame

local invScrollLayout = Instance.new("UIListLayout")
invScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
invScrollLayout.Padding = UDim.new(0, 8)
invScrollLayout.Parent = invScrollFrame

-- Garden Frame
local gardenFrame = Instance.new("Frame")
gardenFrame.Name = "GardenFrame"
gardenFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
gardenFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
gardenFrame.AnchorPoint = Vector2.new(0.5, 0.5)
gardenFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
gardenFrame.BorderSizePixel = 0
gardenFrame.Visible = false
gardenFrame.Parent = screenGui

local gardenFrameCorner = Instance.new("UICorner")
gardenFrameCorner.CornerRadius = UDim.new(0.02, 0)
gardenFrameCorner.Parent = gardenFrame

local gardenTitle = Instance.new("TextLabel")
gardenTitle.Size = UDim2.new(1, 0, 0, 50)
gardenTitle.Position = UDim2.new(0, 0, 0, 10)
gardenTitle.BackgroundTransparency = 1
gardenTitle.Font = Enum.Font.GothamBold
gardenTitle.Text = "GARDEN"
gardenTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
gardenTitle.TextSize = 28
gardenTitle.Parent = gardenFrame

local gardenCloseButton = Instance.new("TextButton")
gardenCloseButton.Size = UDim2.new(0, 40, 0, 40)
gardenCloseButton.Position = UDim2.new(1, -50, 0, 10)
gardenCloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
gardenCloseButton.BorderSizePixel = 0
gardenCloseButton.Font = Enum.Font.GothamBold
gardenCloseButton.Text = "X"
gardenCloseButton.TextColor3 = Color3.new(1, 1, 1)
gardenCloseButton.TextSize = 24
gardenCloseButton.Parent = gardenFrame

local gardenCloseCorner = Instance.new("UICorner")
gardenCloseCorner.CornerRadius = UDim.new(0.2, 0)
gardenCloseCorner.Parent = gardenCloseButton

local gardenScrollFrame = Instance.new("ScrollingFrame")
gardenScrollFrame.Size = UDim2.new(1, -20, 1, -80)
gardenScrollFrame.Position = UDim2.new(0, 10, 0, 70)
gardenScrollFrame.BackgroundTransparency = 1
gardenScrollFrame.BorderSizePixel = 0
gardenScrollFrame.ScrollBarThickness = 8
gardenScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
gardenScrollFrame.Parent = gardenFrame

local gardenScrollLayout = Instance.new("UIListLayout")
gardenScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
gardenScrollLayout.Padding = UDim.new(0, 8)
gardenScrollLayout.Parent = gardenScrollFrame

-- Admin Frame
local adminFrame = Instance.new("Frame")
adminFrame.Name = "AdminFrame"
adminFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
adminFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
adminFrame.AnchorPoint = Vector2.new(0.5, 0.5)
adminFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
adminFrame.BorderSizePixel = 0
adminFrame.Visible = false
adminFrame.Parent = screenGui

local adminFrameCorner = Instance.new("UICorner")
adminFrameCorner.CornerRadius = UDim.new(0.02, 0)
adminFrameCorner.Parent = adminFrame

local adminTitle = Instance.new("TextLabel")
adminTitle.Size = UDim2.new(1, 0, 0, 50)
adminTitle.Position = UDim2.new(0, 0, 0, 10)
adminTitle.BackgroundTransparency = 1
adminTitle.Font = Enum.Font.GothamBold
adminTitle.Text = "ADMIN PANEL"
adminTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
adminTitle.TextSize = 28
adminTitle.Parent = adminFrame

local adminCloseButton = Instance.new("TextButton")
adminCloseButton.Size = UDim2.new(0, 40, 0, 40)
adminCloseButton.Position = UDim2.new(1, -50, 0, 10)
adminCloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
adminCloseButton.BorderSizePixel = 0
adminCloseButton.Font = Enum.Font.GothamBold
adminCloseButton.Text = "X"
adminCloseButton.TextColor3 = Color3.new(1, 1, 1)
adminCloseButton.TextSize = 24
adminCloseButton.Parent = adminFrame

local adminCloseCorner = Instance.new("UICorner")
adminCloseCorner.CornerRadius = UDim.new(0.2, 0)
adminCloseCorner.Parent = adminCloseButton

local adminScrollFrame = Instance.new("ScrollingFrame")
adminScrollFrame.Size = UDim2.new(1, -20, 1, -80)
adminScrollFrame.Position = UDim2.new(0, 10, 0, 70)
adminScrollFrame.BackgroundTransparency = 1
adminScrollFrame.BorderSizePixel = 0
adminScrollFrame.ScrollBarThickness = 8
adminScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
adminScrollFrame.Parent = adminFrame

local adminScrollLayout = Instance.new("UIListLayout")
adminScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
adminScrollLayout.Padding = UDim.new(0, 8)
adminScrollLayout.Parent = adminScrollFrame

-- Admin Controls
local giveMoneyLabel = Instance.new("TextLabel")
giveMoneyLabel.Size = UDim2.new(1, 0, 0, 30)
giveMoneyLabel.BackgroundTransparency = 1
giveMoneyLabel.Font = Enum.Font.Gotham
giveMoneyLabel.Text = "Give Money"
giveMoneyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
giveMoneyLabel.TextSize = 18
giveMoneyLabel.Parent = adminScrollFrame

local giveMoneyInput = Instance.new("TextBox")
giveMoneyInput.Size = UDim2.new(1, 0, 0, 40)
giveMoneyInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
giveMoneyInput.BorderSizePixel = 0
giveMoneyInput.Font = Enum.Font.Gotham
giveMoneyInput.Text = ""
giveMoneyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
giveMoneyInput.TextSize = 18
giveMoneyInput.Parent = adminScrollFrame

local giveMoneyButton = Instance.new("TextButton")
giveMoneyButton.Size = UDim2.new(1, 0, 0, 40)
giveMoneyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
giveMoneyButton.BorderSizePixel = 0
giveMoneyButton.Font = Enum.Font.GothamBold
giveMoneyButton.Text = "Give Money"
giveMoneyButton.TextColor3 = Color3.new(1, 1, 1)
giveMoneyButton.TextSize = 18
giveMoneyButton.Parent = adminScrollFrame

giveMoneyButton.MouseButton1Click:Connect(function()
    local amount = tonumber(giveMoneyInput.Text)
    if amount then
        playerMoney.Value = playerMoney.Value + amount
        print("Gave " .. amount .. " money")
    end
end)

local restockShopNowButton = Instance.new("TextButton")
restockShopNowButton.Size = UDim2.new(1, 0, 0, 40)
restockShopNowButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
restockShopNowButton.BorderSizePixel = 0
restockShopNowButton.Font = Enum.Font.GothamBold
restockShopNowButton.Text = "Restock Shop Now"
restockShopNowButton.TextColor3 = Color3.new(1, 1, 1)
restockShopNowButton.TextSize = 18
restockShopNowButton.Parent = adminScrollFrame

restockShopNowButton.MouseButton1Click:Connect(function()
    generateStock()
    updateShopDisplay()
    print("Shop restocked!")
end)

local restockSeedLabel = Instance.new("TextLabel")
restockSeedLabel.Size = UDim2.new(1, 0, 0, 30)
restockSeedLabel.BackgroundTransparency = 1
restockSeedLabel.Font = Enum.Font.Gotham
restockSeedLabel.Text = "Restock Seed"
restockSeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
restockSeedLabel.TextSize = 18
restockSeedLabel.Parent = adminScrollFrame

local restockSeedDropdown = Instance.new("TextButton")
restockSeedDropdown.Size = UDim2.new(1, 0, 0, 40)
restockSeedDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
restockSeedDropdown.BorderSizePixel = 0
restockSeedDropdown.Font = Enum.Font.Gotham
restockSeedDropdown.Text = "Select Seed"
restockSeedDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
restockSeedDropdown.TextSize = 18
restockSeedDropdown.Parent = adminScrollFrame

local restockSeedList = Instance.new("ScrollingFrame")
restockSeedList.Size = UDim2.new(1, 0, 0, 200)
restockSeedList.Position = UDim2.new(0, 0, 0, 0)
restockSeedList.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
restockSeedList.BorderSizePixel = 0
restockSeedList.ScrollBarThickness = 8
restockSeedList.Visible = false
restockSeedList.Parent = restockSeedDropdown

local restockSeedListLayout = Instance.new("UIListLayout")
restockSeedListLayout.SortOrder = Enum.SortOrder.LayoutOrder
restockSeedListLayout.Padding = UDim.new(0, 4)
restockSeedListLayout.Parent = restockSeedList

local function updateRestockSeedList()
    for _, child in ipairs(restockSeedList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local availableSeeds = {}
    for _, item in ipairs(shopItems) do
        table.insert(availableSeeds, item.name)
    end
    for _, aw in ipairs(activeWeathers) do
        for _, item in ipairs(aw.weather.merchantItems) do
            table.insert(availableSeeds, item.name)
        end
    end

    for _, seedName in ipairs(availableSeeds) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.Gotham
        btn.Text = seedName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 14
        btn.Parent = restockSeedList

        btn.MouseButton1Click:Connect(function()
            restockSeedDropdown.Text = seedName
            restockSeedList.Visible = false
        end)
    end

    restockSeedList.CanvasSize = UDim2.new(0, 0, 0, restockSeedListLayout.AbsoluteContentSize.Y)
end

restockSeedDropdown.MouseButton1Click:Connect(function()
    updateRestockSeedList()
    restockSeedList.Visible = not restockSeedList.Visible
end)

local restockAmountInput = Instance.new("TextBox")
restockAmountInput.Size = UDim2.new(1, 0, 0, 40)
restockAmountInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
restockAmountInput.BorderSizePixel = 0
restockAmountInput.Font = Enum.Font.Gotham
restockAmountInput.Text = "Restock Amount"
restockAmountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
restockAmountInput.TextSize = 18
restockAmountInput.Parent = adminScrollFrame

local restockSeedButton = Instance.new("TextButton")
restockSeedButton.Size = UDim2.new(1, 0, 0, 40)
restockSeedButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
restockSeedButton.BorderSizePixel = 0
restockSeedButton.Font = Enum.Font.GothamBold
restockSeedButton.Text = "Restock Seed"
restockSeedButton.TextColor3 = Color3.new(1, 1, 1)
restockSeedButton.TextSize = 18
restockSeedButton.Parent = adminScrollFrame

restockSeedButton.MouseButton1Click:Connect(function()
    local seedName = restockSeedDropdown.Text
    local amount = tonumber(restockAmountInput.Text)
    if seedName ~= "Select Seed" and amount then
        local isMainSeed = false
        for _, item in ipairs(shopItems) do
            if item.name == seedName then
                isMainSeed = true
                break
            end
        end
        if isMainSeed then
            itemStocks[seedName] = amount
            updateShopDisplay()
        else
            merchantStocks[seedName] = amount
            updateMerchantDisplay()
        end
        print("Restocked " .. seedName .. " with " .. amount)
    end
end)

local giveSeedLabel = Instance.new("TextLabel")
giveSeedLabel.Size = UDim2.new(1, 0, 0, 30)
giveSeedLabel.BackgroundTransparency = 1
giveSeedLabel.Font = Enum.Font.Gotham
giveSeedLabel.Text = "Give Seed"
giveSeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
giveSeedLabel.TextSize = 18
giveSeedLabel.Parent = adminScrollFrame

local giveSeedDropdown = Instance.new("TextButton")
giveSeedDropdown.Size = UDim2.new(1, 0, 0, 40)
giveSeedDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
giveSeedDropdown.BorderSizePixel = 0
giveSeedDropdown.Font = Enum.Font.Gotham
giveSeedDropdown.Text = "Select Seed"
giveSeedDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
giveSeedDropdown.TextSize = 18
giveSeedDropdown.Parent = adminScrollFrame

local giveSeedList = Instance.new("ScrollingFrame")
giveSeedList.Size = UDim2.new(1, 0, 0, 200)
giveSeedList.Position = UDim2.new(0, 0, 0, 0)
giveSeedList.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
giveSeedList.BorderSizePixel = 0
giveSeedList.ScrollBarThickness = 8
giveSeedList.Visible = false
giveSeedList.Parent = giveSeedDropdown

local giveSeedListLayout = Instance.new("UIListLayout")
giveSeedListLayout.SortOrder = Enum.SortOrder.LayoutOrder
giveSeedListLayout.Padding = UDim.new(0, 4)
giveSeedListLayout.Parent = giveSeedList

local function updateGiveSeedList()
    for _, child in ipairs(giveSeedList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for _, item in ipairs(seedConfigs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.Gotham
        btn.Text = item.name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 14
        btn.Parent = giveSeedList

        btn.MouseButton1Click:Connect(function()
            giveSeedDropdown.Text = item.name
            giveSeedList.Visible = false
        end)
    end

    giveSeedList.CanvasSize = UDim2.new(0, 0, 0, giveSeedListLayout.AbsoluteContentSize.Y)
end

giveSeedDropdown.MouseButton1Click:Connect(function()
    updateGiveSeedList()
    giveSeedList.Visible = not giveSeedList.Visible
end)

local giveAmountInput = Instance.new("TextBox")
giveAmountInput.Size = UDim2.new(1, 0, 0, 40)
giveAmountInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
giveAmountInput.BorderSizePixel = 0
giveAmountInput.Font = Enum.Font.Gotham
giveAmountInput.Text = "Give Amount"
giveAmountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
giveAmountInput.TextSize = 18
giveAmountInput.Parent = adminScrollFrame

local giveSeedButton = Instance.new("TextButton")
giveSeedButton.Size = UDim2.new(1, 0, 0, 40)
giveSeedButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
giveSeedButton.BorderSizePixel = 0
giveSeedButton.Font = Enum.Font.GothamBold
giveSeedButton.Text = "Give Seed"
giveSeedButton.TextColor3 = Color3.new(1, 1, 1)
giveSeedButton.TextSize = 18
giveSeedButton.Parent = adminScrollFrame

giveSeedButton.MouseButton1Click:Connect(function()
    local seedName = giveSeedDropdown.Text
    local amount = tonumber(giveAmountInput.Text)
    if seedName ~= "Select Seed" and amount then
        if not playerInventory[seedName] then
            playerInventory[seedName] = 0
        end
        playerInventory[seedName] = playerInventory[seedName] + amount
        updateInventoryDisplay()
        print("Gave " .. amount .. " of " .. seedName .. " to inventory")
    end
end)

local triggerWeatherNowButton = Instance.new("TextButton")
triggerWeatherNowButton.Size = UDim2.new(1, 0, 0, 40)
triggerWeatherNowButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
triggerWeatherNowButton.BorderSizePixel = 0
triggerWeatherNowButton.Font = Enum.Font.GothamBold
triggerWeatherNowButton.Text = "Trigger Weather Now"
triggerWeatherNowButton.TextColor3 = Color3.new(1, 1, 1)
triggerWeatherNowButton.TextSize = 18
triggerWeatherNowButton.Parent = adminScrollFrame

triggerWeatherNowButton.MouseButton1Click:Connect(function()
    nextWeatherRoll = os.time()
    print("Triggered weather roll")
end)

local endWeatherNowButton = Instance.new("TextButton")
endWeatherNowButton.Size = UDim2.new(1, 0, 0, 40)
endWeatherNowButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
endWeatherNowButton.BorderSizePixel = 0
endWeatherNowButton.Font = Enum.Font.GothamBold
endWeatherNowButton.Text = "End Weather Now"
endWeatherNowButton.TextColor3 = Color3.new(1, 1, 1)
endWeatherNowButton.TextSize = 18
endWeatherNowButton.Parent = adminScrollFrame

endWeatherNowButton.MouseButton1Click:Connect(function()
    for _, aw in ipairs(activeWeathers) do
        aw.endTime = os.time()
    end
    print("Ended all weathers")
end)

local triggerSelectedWeatherLabel = Instance.new("TextLabel")
triggerSelectedWeatherLabel.Size = UDim2.new(1, 0, 0, 30)
triggerSelectedWeatherLabel.BackgroundTransparency = 1
triggerSelectedWeatherLabel.Font = Enum.Font.Gotham
triggerSelectedWeatherLabel.Text = "Trigger Selected Weather"
triggerSelectedWeatherLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
triggerSelectedWeatherLabel.TextSize = 18
triggerSelectedWeatherLabel.Parent = adminScrollFrame

local triggerWeatherDropdown = Instance.new("TextButton")
triggerWeatherDropdown.Size = UDim2.new(1, 0, 0, 40)
triggerWeatherDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
triggerWeatherDropdown.BorderSizePixel = 0
triggerWeatherDropdown.Font = Enum.Font.Gotham
triggerWeatherDropdown.Text = "Select Weather"
triggerWeatherDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
triggerWeatherDropdown.TextSize = 18
triggerWeatherDropdown.Parent = adminScrollFrame

local triggerWeatherList = Instance.new("ScrollingFrame")
triggerWeatherList.Size = UDim2.new(1, 0, 0, 200)
triggerWeatherList.Position = UDim2.new(0, 0, 0, 0)
triggerWeatherList.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
triggerWeatherList.BorderSizePixel = 0
triggerWeatherList.ScrollBarThickness = 8
triggerWeatherList.Visible = false
triggerWeatherList.Parent = triggerWeatherDropdown

local triggerWeatherListLayout = Instance.new("UIListLayout")
triggerWeatherListLayout.SortOrder = Enum.SortOrder.LayoutOrder
triggerWeatherListLayout.Padding = UDim.new(0, 4)
triggerWeatherListLayout.Parent = triggerWeatherList

for _, w in ipairs(weathers) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.Gotham
    btn.Text = w.name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Parent = triggerWeatherList

    btn.MouseButton1Click:Connect(function()
        triggerWeatherDropdown.Text = w.name
        triggerWeatherList.Visible = false
    end)
end

triggerWeatherDropdown.MouseButton1Click:Connect(function()
    triggerWeatherList.Visible = not triggerWeatherList.Visible
end)

local triggerSelectedWeatherButton = Instance.new("TextButton")
triggerSelectedWeatherButton.Size = UDim2.new(1, 0, 0, 40)
triggerSelectedWeatherButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
triggerSelectedWeatherButton.BorderSizePixel = 0
triggerSelectedWeatherButton.Font = Enum.Font.GothamBold
triggerSelectedWeatherButton.Text = "Trigger Selected Weather"
triggerSelectedWeatherButton.TextColor3 = Color3.new(1, 1, 1)
triggerSelectedWeatherButton.TextSize = 18
triggerSelectedWeatherButton.Parent = adminScrollFrame

triggerSelectedWeatherButton.MouseButton1Click:Connect(function()
    local weatherName = triggerWeatherDropdown.Text
    if weatherName ~= "Select Weather" then
        for _, w in ipairs(weathers) do
            if w.name == weatherName then
                table.insert(activeWeathers, {weather = w, endTime = os.time() + w.duration})
                for _, item in ipairs(w.merchantItems) do
                    local roll = math.random(1, item.stockChance)
                    if roll == 1 then
                        merchantStocks[item.name] = math.random(1, 10)
                    else
                        merchantStocks[item.name] = 0
                    end
                end
                print("Triggered " .. weatherName)
                break
            end
        end
    end
end)

local growAllButton = Instance.new("TextButton")
growAllButton.Size = UDim2.new(1, 0, 0, 40)
growAllButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
growAllButton.BorderSizePixel = 0
growAllButton.Font = Enum.Font.GothamBold
growAllButton.Text = "Grow All"
growAllButton.TextColor3 = Color3.new(1, 1, 1)
growAllButton.TextSize = 18
growAllButton.Parent = adminScrollFrame

growAllButton.MouseButton1Click:Connect(function()
    for _, plantData in ipairs(playerGarden) do
        plantData.isFullyGrown = true
        plantData.timeGrown = plantData.growTime
        plantData.produces = {}
        for i = 1, 5 do
            table.insert(plantData.produces, {
                name = plantData.produceName,
                worth = plantData.produceWorth,
                kg = plantData.produceKG,
                growTime = plantData.growTime,
                timeGrown = plantData.growTime,
                isReady = true,
                growthPercent = 100,
                mutations = {}
            })
        end
    end
    updateGardenDisplay()
    print("Grew all plants")
end)

adminScrollFrame.CanvasSize = UDim2.new(0, 0, 0, adminScrollLayout.AbsoluteContentSize.Y + 10)

-- Plant Info Frame
local plantInfoFrame = Instance.new("Frame")
plantInfoFrame.Name = "PlantInfoFrame"
plantInfoFrame.Size = UDim2.new(0.85, 0, 0.75, 0)
plantInfoFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
plantInfoFrame.AnchorPoint = Vector2.new(0.5, 0.5)
plantInfoFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
plantInfoFrame.BorderSizePixel = 0
plantInfoFrame.Visible = false
plantInfoFrame.ZIndex = 10
plantInfoFrame.Parent = screenGui

local plantInfoCorner = Instance.new("UICorner")
plantInfoCorner.CornerRadius = UDim.new(0.02, 0)
plantInfoCorner.Parent = plantInfoFrame

local plantInfoTitle = Instance.new("TextLabel")
plantInfoTitle.Name = "Title"
plantInfoTitle.Size = UDim2.new(1, 0, 0, 50)
plantInfoTitle.Position = UDim2.new(0, 0, 0, 10)
plantInfoTitle.BackgroundTransparency = 1
plantInfoTitle.Font = Enum.Font.GothamBold
plantInfoTitle.Text = "PLANT INFO"
plantInfoTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
plantInfoTitle.TextSize = 24
plantInfoTitle.Parent = plantInfoFrame

local plantInfoClose = Instance.new("TextButton")
plantInfoClose.Size = UDim2.new(0, 40, 0, 40)
plantInfoClose.Position = UDim2.new(1, -50, 0, 10)
plantInfoClose.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
plantInfoClose.BorderSizePixel = 0
plantInfoClose.Font = Enum.Font.GothamBold
plantInfoClose.Text = "X"
plantInfoClose.TextColor3 = Color3.new(1, 1, 1)
plantInfoClose.TextSize = 24
plantInfoClose.Parent = plantInfoFrame

local plantInfoCloseCorner = Instance.new("UICorner")
plantInfoCloseCorner.CornerRadius = UDim.new(0.2, 0)
plantInfoCloseCorner.Parent = plantInfoClose

local plantInfoScroll = Instance.new("ScrollingFrame")
plantInfoScroll.Size = UDim2.new(1, -20, 1, -80)
plantInfoScroll.Position = UDim2.new(0, 10, 0, 70)
plantInfoScroll.BackgroundTransparency = 1
plantInfoScroll.BorderSizePixel = 0
plantInfoScroll.ScrollBarThickness = 8
plantInfoScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
plantInfoScroll.Parent = plantInfoFrame

local plantInfoLayout = Instance.new("UIListLayout")
plantInfoLayout.SortOrder = Enum.SortOrder.LayoutOrder
plantInfoLayout.Padding = UDim.new(0, 8)
plantInfoLayout.Parent = plantInfoScroll

-- Functions
local function updateShopDisplay()
    for _, child in ipairs(shopScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            local item = findSeedConfig(child.Name)
            
            if item then
                local stock = itemStocks[item.name] or 0
                local costLabel = child:FindFirstChild("CostLabel")
                local stockLabel = child:FindFirstChild("StockLabel")
                local buyButton = child:FindFirstChild("BuyButton")
                
                if stock == 0 then
                    costLabel.Text = "NO STOCK"
                    costLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                    stockLabel.Text = "0x"
                    buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                    buyButton.Text = "OUT"
                else
                    costLabel.Text = formatMoney(item.cost)
                    costLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
                    stockLabel.Text = stock .. "x"
                    buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                    buyButton.Text = "BUY"
                end
            end
        end
    end
end

local function updateMerchantDisplay()
    for _, child in ipairs(merchantScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local displayedItems = {}
    for _, aw in ipairs(activeWeathers) do
        if aw.weather and aw.weather.merchantItems then
            for _, item in ipairs(aw.weather.merchantItems) do
                if not displayedItems[item.name] then
                    local itemFrame = createShopItemFrame(item)
                    itemFrame.Parent = merchantScrollFrame
                    displayedItems[item.name] = true

                    local buyButton = itemFrame:FindFirstChild("BuyButton")
                    buyButton.MouseButton1Click:Connect(function()
                        local stock = merchantStocks[item.name] or 0
                        if stock > 0 and playerMoney.Value >= item.cost then
                            playerMoney.Value = playerMoney.Value - item.cost
                            merchantStocks[item.name] = stock - 1
                            
                            if not playerInventory[item.name] then
                                playerInventory[item.name] = 0
                            end
                            playerInventory[item.name] = playerInventory[item.name] + 1
                            
                            updateMerchantDisplay()
                            updateInventoryDisplay()
                            print(player.Name .. " purchased " .. item.name .. " from merchant")
                        elseif stock == 0 then
                            print("Out of stock!")
                        else
                            print("Not enough money!")
                        end
                    end)
                end
            end
        end
    end

    for _, child in ipairs(merchantScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            local itemName = child.Name
            local item = findSeedConfig(itemName)
            if item then
                local stock = merchantStocks[itemName] or 0
                local costLabel = child:FindFirstChild("CostLabel")
                local stockLabel = child:FindFirstChild("StockLabel")
                local buyButton = child:FindFirstChild("BuyButton")
                
                if stock == 0 then
                    costLabel.Text = "NO STOCK"
                    costLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                    stockLabel.Text = "0x"
                    buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                    buyButton.Text = "OUT"
                else
                    costLabel.Text = formatMoney(item.cost)
                    costLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
                    stockLabel.Text = stock .. "x"
                    buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                    buyButton.Text = "BUY"
                end
            end
        end
    end

    merchantScrollFrame.CanvasSize = UDim2.new(0, 0, 0, merchantScrollLayout.AbsoluteContentSize.Y + 10)
end

local function updateInventoryDisplay()
    for _, child in ipairs(invScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for seedName, quantity in pairs(playerInventory) do
        if quantity > 0 then
            local itemFrame = createInventoryItemFrame(seedName, quantity)
            if itemFrame then
                itemFrame.Parent = invScrollFrame
                
                local plantButton = itemFrame:FindFirstChild("PlantButton")
                plantButton.MouseButton1Click:Connect(function()
                    if playerInventory[seedName] and playerInventory[seedName] > 0 then
                        playerInventory[seedName] = playerInventory[seedName] - 1
                        
                        local item = findSeedConfig(seedName)
                        
                        if item then
                            table.insert(playerGarden, {
                                name = seedName,
                                plantName = item.plantName,
                                produceName = item.produceName,
                                growTime = item.growTime,
                                produceWorth = item.produceWorth,
                                produceKG = item.produceKG,
                                timeGrown = 0,
                                isFullyGrown = false,
                                produces = {}
                            })
                            
                            updateInventoryDisplay()
                            updateGardenDisplay()
                            print("Planted " .. seedName .. "!")
                        end
                    end
                end)
            end
        end
    end
    
    invScrollFrame.CanvasSize = UDim2.new(0, 0, 0, invScrollLayout.AbsoluteContentSize.Y + 10)
end

local function updateGardenDisplay()
    for _, child in ipairs(gardenScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for i, plantData in ipairs(playerGarden) do
        local itemFrame = createGardenPlantFrame(plantData)
        itemFrame.Parent = gardenScrollFrame
        
        local statusLabel = itemFrame:FindFirstChild("StatusLabel")
        local produceLabel = itemFrame:FindFirstChild("ProduceLabel")
        
        if plantData.isFullyGrown then
            statusLabel.Text = "Fully Grown"
            statusLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
            produceLabel.Text = #plantData.produces .. "x Produced"
        else
            local growthPercent = math.floor((plantData.timeGrown / plantData.growTime) * 100)
            statusLabel.Text = growthPercent .. "% Grown"
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
        end
        
        local infoButton = itemFrame:FindFirstChild("InfoButton")
        infoButton.MouseButton1Click:Connect(function()
            plantInfoFrame.Visible = true
            plantInfoTitle.Text = plantData.plantName .. " - INFO"
            
            for _, child in ipairs(plantInfoScroll:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextLabel") then
                    child:Destroy()
                end
            end
            
            if plantData.isFullyGrown then
                for _, produce in ipairs(plantData.produces) do
                    local produceFrame = Instance.new("Frame")
                    produceFrame.Size = UDim2.new(1, -10, 0, 120)
                    produceFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    produceFrame.BorderSizePixel = 0
                    produceFrame.Parent = plantInfoScroll
                    
                    local pCorner = Instance.new("UICorner")
                    pCorner.CornerRadius = UDim.new(0.08, 0)
                    pCorner.Parent = produceFrame
                    
                    local pName = Instance.new("TextLabel")
                    pName.Size = UDim2.new(1, -100, 0, 25)
                    pName.Position = UDim2.new(0, 5, 0, 5)
                    pName.BackgroundTransparency = 1
                    pName.Font = Enum.Font.GothamBold
                    pName.Text = produce.name
                    pName.TextColor3 = Color3.new(1, 1, 1)
                    pName.TextSize = 16
                    pName.TextXAlignment = Enum.TextXAlignment.Left
                    pName.Parent = produceFrame
                    
                    if produce.isReady then
                        local mult = calculateMultiplier(produce)
                        local pWorth = Instance.new("TextLabel")
                        pWorth.Size = UDim2.new(1, -100, 0, 20)
                        pWorth.Position = UDim2.new(0, 5, 0, 32)
                        pWorth.BackgroundTransparency = 1
                        pWorth.Font = Enum.Font.Gotham
                        pWorth.Text = "Worth: " .. formatMoney(produce.worth * mult)
                        pWorth.TextColor3 = Color3.fromRGB(85, 255, 85)
                        pWorth.TextSize = 14
                        pWorth.TextXAlignment = Enum.TextXAlignment.Left
                        pWorth.Parent = produceFrame
                        
                        local pKG = Instance.new("TextLabel")
                        pKG.Size = UDim2.new(1, -100, 0, 20)
                        pKG.Position = UDim2.new(0, 5, 0, 54)
                        pKG.BackgroundTransparency = 1
                        pKG.Font = Enum.Font.Gotham
                        pKG.Text = produce.kg .. " KG"
                        pKG.TextColor3 = Color3.fromRGB(200, 200, 200)
                        pKG.TextSize = 14
                        pKG.TextXAlignment = Enum.TextXAlignment.Left
                        pKG.Parent = produceFrame
                        
                        local mutationsLabel = Instance.new("TextLabel")
                        mutationsLabel.Size = UDim2.new(1, -100, 0, 20)
                        mutationsLabel.Position = UDim2.new(0, 5, 0, 76)
                        mutationsLabel.BackgroundTransparency = 1
                        mutationsLabel.Font = Enum.Font.Gotham
                        mutationsLabel.TextColor3 = Color3.fromRGB(170, 85, 255)
                        mutationsLabel.TextSize = 14
                        mutationsLabel.TextXAlignment = Enum.TextXAlignment.Left
                        if #produce.mutations > 0 then
                            local txt = "Mutations: "
                            for _, mut in ipairs(produce.mutations) do
                                txt = txt .. mut.name .. " (" .. mut.multiplier .. "x), "
                            end
                            mutationsLabel.Text = txt:sub(1, -3)
                        else
                            mutationsLabel.Text = "Mutations: none"
                        end
                        mutationsLabel.Parent = produceFrame
                        
                        local harvestBtn = Instance.new("TextButton")
                        harvestBtn.Size = UDim2.new(0, 80, 0, 35)
                        harvestBtn.Position = UDim2.new(1, -90, 0.5, -17.5)
                        harvestBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                        harvestBtn.BorderSizePixel = 0
                        harvestBtn.Font = Enum.Font.GothamBold
                        harvestBtn.Text = "HARVEST"
                        harvestBtn.TextColor3 = Color3.new(1, 1, 1)
                        harvestBtn.TextSize = 14
                        harvestBtn.Parent = produceFrame
                        
                        local hCorner = Instance.new("UICorner")
                        hCorner.CornerRadius = UDim.new(0.15, 0)
                        hCorner.Parent = harvestBtn
                        
                        harvestBtn.MouseButton1Click:Connect(function()
                            local mult = calculateMultiplier(produce)
                            playerMoney.Value = playerMoney.Value + produce.worth * mult
                            for j, p in ipairs(plantData.produces) do
                                if p == produce then
                                    table.remove(plantData.produces, j)
                                    break
                                end
                            end
                            plantInfoFrame.Visible = false
                            updateGardenDisplay()
                            print("Harvested " .. produce.name .. "!")
                        end)
                    else
                        local pGrowth = Instance.new("TextLabel")
                        pGrowth.Size = UDim2.new(1, -100, 0, 25)
                        pGrowth.Position = UDim2.new(0, 5, 0, 35)
                        pGrowth.BackgroundTransparency = 1
                        pGrowth.Font = Enum.Font.Gotham
                        pGrowth.Text = produce.growthPercent .. "% Grown"
                        pGrowth.TextColor3 = Color3.fromRGB(255, 255, 100)
                        pGrowth.TextSize = 14
                        pGrowth.TextXAlignment = Enum.TextXAlignment.Left
                        pGrowth.Parent = produceFrame
                    end
                end
            else
                local growthLabel = Instance.new("TextLabel")
                growthLabel.Size = UDim2.new(1, 0, 0, 100)
                growthLabel.BackgroundTransparency = 1
                growthLabel.Font = Enum.Font.GothamBold
                growthLabel.Text = "Plant is still growing...\n" .. math.floor((plantData.timeGrown / plantData.growTime) * 100) .. "% Complete"
                growthLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
                growthLabel.TextSize = 18
                growthLabel.Parent = plantInfoScroll
            end
            
            plantInfoScroll.CanvasSize = UDim2.new(0, 0, 0, plantInfoLayout.AbsoluteContentSize.Y + 10)
        end)
    end
    
    gardenScrollFrame.CanvasSize = UDim2.new(0, 0, 0, gardenScrollLayout.AbsoluteContentSize.Y + 10)
end

local function setupShop()
    for _, item in ipairs(shopItems) do
        local itemFrame = createShopItemFrame(item)
        itemFrame.Parent = shopScrollFrame
        
        local buyButton = itemFrame:FindFirstChild("BuyButton")
        buyButton.MouseButton1Click:Connect(function()
            local stock = itemStocks[item.name] or 0
            if stock > 0 and playerMoney.Value >= item.cost then
                playerMoney.Value = playerMoney.Value - item.cost
                itemStocks[item.name] = stock - 1
                
                if not playerInventory[item.name] then
                    playerInventory[item.name] = 0
                end
                playerInventory[item.name] = playerInventory[item.name] + 1
                
                updateShopDisplay()
                updateInventoryDisplay()
                print(player.Name .. " purchased " .. item.name)
            elseif stock == 0 then
                print("Out of stock!")
            else
                print("Not enough money!")
            end
        end)
    end
    
    shopScrollFrame.CanvasSize = UDim2.new(0, 0, 0, shopScrollLayout.AbsoluteContentSize.Y + 10)
end

-- Button Connections
shopButton.MouseButton1Click:Connect(function()
    shopFrame.Visible = not shopFrame.Visible
    inventoryFrame.Visible = false
    gardenFrame.Visible = false
    merchantFrame.Visible = false
    adminFrame.Visible = false
end)

shopCloseButton.MouseButton1Click:Connect(function()
    shopFrame.Visible = false
end)

inventoryButton.MouseButton1Click:Connect(function()
    inventoryFrame.Visible = not inventoryFrame.Visible
    shopFrame.Visible = false
    gardenFrame.Visible = false
    merchantFrame.Visible = false
    adminFrame.Visible = false
    updateInventoryDisplay()
end)

invCloseButton.MouseButton1Click:Connect(function()
    inventoryFrame.Visible = false
end)

gardenButton.MouseButton1Click:Connect(function()
    gardenFrame.Visible = not gardenFrame.Visible
    shopFrame.Visible = false
    inventoryFrame.Visible = false
    merchantFrame.Visible = false
    adminFrame.Visible = false
    updateGardenDisplay()
end)

gardenCloseButton.MouseButton1Click:Connect(function()
    gardenFrame.Visible = false
end)

merchantButton.MouseButton1Click:Connect(function()
    merchantFrame.Visible = not merchantFrame.Visible
    shopFrame.Visible = false
    inventoryFrame.Visible = false
    gardenFrame.Visible = false
    adminFrame.Visible = false
    if merchantFrame.Visible then
        updateMerchantDisplay()
    end
end)

merchantCloseButton.MouseButton1Click:Connect(function()
    merchantFrame.Visible = false
end)

adminButton.MouseButton1Click:Connect(function()
    adminFrame.Visible = not adminFrame.Visible
    shopFrame.Visible = false
    inventoryFrame.Visible = false
    gardenFrame.Visible = false
    merchantFrame.Visible = false
end)

adminCloseButton.MouseButton1Click:Connect(function()
    adminFrame.Visible = false
end)

plantInfoClose.MouseButton1Click:Connect(function()
    plantInfoFrame.Visible = false
end)

-- Restock System
local restockTime = 180
local currentTime = restockTime

local function updateTimer()
    local minutes = math.floor(currentTime / 60)
    local seconds = currentTime % 60
    timerLabel.Text = string.format("Next Restock: %d:%02d", minutes, seconds)
end

-- Garden Growth System
spawn(function()
    while true do
        task.wait(1)
        
        for _, plantData in ipairs(playerGarden) do
            if not plantData.isFullyGrown then
                plantData.timeGrown = plantData.timeGrown + 1
                
                if plantData.timeGrown >= plantData.growTime then
                    plantData.isFullyGrown = true
                    
                    table.insert(plantData.produces, {
                        name = plantData.produceName,
                        worth = plantData.produceWorth,
                        kg = plantData.produceKG,
                        growTime = plantData.growTime,
                        timeGrown = 0,
                        isReady = false,
                        growthPercent = 0,
                        mutations = {}
                    })
                end
            else
                for _, produce in ipairs(plantData.produces) do
                    if not produce.isReady then
                        produce.timeGrown = produce.timeGrown + 1
                        produce.growthPercent = math.floor((produce.timeGrown / produce.growTime) * 100)
                        
                        if produce.timeGrown >= produce.growTime then
                            produce.isReady = true
                        end
                    end
                end
                
                -- Auto-generate new produce when plant is fully grown
                local allReady = true
                for _, produce in ipairs(plantData.produces) do
                    if not produce.isReady then
                        allReady = false
                        break
                    end
                end
                
                if allReady and #plantData.produces < 5 then
                    table.insert(plantData.produces, {
                        name = plantData.produceName,
                        worth = plantData.produceWorth,
                        kg = plantData.produceKG,
                        growTime = plantData.growTime,
                        timeGrown = 0,
                        isReady = false,
                        growthPercent = 0,
                        mutations = {}
                    })
                end
            end
        end
        
        if gardenFrame.Visible then
            updateGardenDisplay()
        end
    end
end)

-- Restock Timer System
spawn(function()
    while true do
        task.wait(1)
        currentTime = currentTime - 1
        
        if currentTime <= 0 then
            generateStock()
            updateShopDisplay()
            currentTime = restockTime
            print("Shop restocked!")
        end
        
        updateTimer()
    end
end)

-- Weather System
local activeWeathers = {}
local nextWeatherRoll = os.time() + 7 * 60

spawn(function()
    while true do
        task.wait(1)
        
        local now = os.time()
        
        -- Check ended weathers
        for i = #activeWeathers, 1, -1 do
            if now >= activeWeathers[i].endTime then
                local w = activeWeathers[i].weather
                for _, item in ipairs(w.merchantItems) do
                    merchantStocks[item.name] = nil
                end
                table.remove(activeWeathers, i)
                print("Weather " .. w.name .. " ended!")
            end
        end
        
        -- Roll for new weathers
        if now >= nextWeatherRoll then
            nextWeatherRoll = now + 7 * 60
            for _, w in ipairs(weathers) do
                if math.random(1, w.encounterChance) == 1 then
                    table.insert(activeWeathers, {weather = w, endTime = now + w.duration})
                    -- Generate merchant stock
                    for _, item in ipairs(w.merchantItems) do
                        local roll = math.random(1, item.stockChance)
                        if roll == 1 then
                            merchantStocks[item.name] = math.random(1, 10)
                        else
                            merchantStocks[item.name] = 0
                        end
                    end
                    print("Weather " .. w.name .. " started!")
                end
            end
        end
        
        -- Apply mutations
        for _, aw in ipairs(activeWeathers) do
            for _, mut in ipairs(aw.weather.mutations) do
                for _, plant in ipairs(playerGarden) do
                    if plant.isFullyGrown then
                        for _, produce in ipairs(plant.produces) do
                            if not produce.isReady then
                                local hasMut = false
                                for _, pm in ipairs(produce.mutations) do
                                    if pm.name == mut.name then
                                        hasMut = true
                                        break
                                    end
                                end
                                if not hasMut then
                                    if math.random(1, mut.applyChance) == 1 then
                                        table.insert(produce.mutations, {name = mut.name, multiplier = mut.multiplier})
                                        print("Applied " .. mut.name .. " to " .. produce.name)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Update merchant button visibility
        merchantButton.Visible = #activeWeathers > 0
        
        -- Update weather display
        local txt = "Weather: "
        if #activeWeathers == 0 then
            local timeToNext = math.max(nextWeatherRoll - now, 0)
            txt = txt .. "Clear (Next in " .. formatTime(timeToNext) .. ")"
        else
            for i, aw in ipairs(activeWeathers) do
                if i > 1 then txt = txt .. ", " end
                txt = txt .. aw.weather.name .. " (" .. formatTime(aw.endTime - now) .. ")"
            end
        end
        weatherDisplay.Text = txt
        
        if merchantFrame.Visible then
            updateMerchantDisplay()
        end
    end
end)

-- Initialize
generateStock()
setupShop()
updateShopDisplay()
updateTimer()

print("Plant Shop System Loaded!")
print("- Press SHOP to buy seeds")
print("- Press INV to view inventory and plant seeds")
print("- Press GARDEN to view growing plants and harvest produce")
print("- Press MERCHANT during weather events for special seeds")
