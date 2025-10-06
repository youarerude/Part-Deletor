-- Pet Trading System with Weather - Complete Script for Codex Executor (Mobile Friendly)
-- Paste this entire script into your executor

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")

-- Detect if mobile
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Game Configuration
local Config = {
    StartingMoney = 50,
    RestockInterval = 180,
    WeatherChangeInterval = 600, -- 10 minutes
    MerchantRestockInterval = 120 -- 2 minutes
}

-- Player Data
local PlayerData = {
    Money = Config.StartingMoney,
    Eggs = {},
    Pets = {}
}

-- Egg Data
local EggData = {
    ["Common Egg"] = {
        Cost = 30,
        StockChance = 1,
        Rarity = "Common",
        Pets = {
            {Name = "Cat", Chance = 60, Rarity = "Common", Worth = 50},
            {Name = "Dog", Chance = 30, Rarity = "Common", Worth = 75},
            {Name = "Golden Retriever", Chance = 7, Rarity = "Uncommon", Worth = 500},
            {Name = "Parrot", Chance = 1, Rarity = "Rare", Worth = 1200}
        }
    },
    ["Uncommon Egg"] = {
        Cost = 450,
        StockChance = 5,
        Rarity = "Uncommon",
        Pets = {
            {Name = "German Shepherd", Chance = 65, Rarity = "Uncommon", Worth = 420},
            {Name = "Rooster", Chance = 34, Rarity = "Uncommon", Worth = 550},
            {Name = "Flamingo", Chance = 11, Rarity = "Uncommon", Worth = 710},
            {Name = "Turtle", Chance = 3, Rarity = "Rare", Worth = 1000},
            {Name = "Grizzly Bear", Chance = 0.7, Rarity = "Epic", Worth = 7101}
        }
    },
    ["Rare Egg"] = {
        Cost = 1000,
        StockChance = 12,
        Rarity = "Rare",
        Pets = {
            {Name = "Deer", Chance = 50, Rarity = "Rare", Worth = 1300},
            {Name = "Skunk", Chance = 10, Rarity = "Epic", Worth = 4900},
            {Name = "Night Owl", Chance = 1, Rarity = "Legendary", Worth = 16200},
            {Name = "Woodpecker", Chance = 0.6, Rarity = "Legendary", Worth = 24000}
        }
    },
    ["Epic Egg"] = {
        Cost = 5000,
        StockChance = 30,
        Rarity = "Epic",
        Pets = {
            {Name = "Goose", Chance = 70, Rarity = "Epic", Worth = 10000},
            {Name = "Fly", Chance = 40, Rarity = "Epic", Worth = 11750},
            {Name = "Bubble Squid", Chance = 15, Rarity = "Legendary", Worth = 19500},
            {Name = "Flaming Mosquito", Chance = 3, Rarity = "Mythical", Worth = 41009}
        }
    },
    ["Legendary Egg"] = {
        Cost = 17500,
        StockChance = 75,
        Rarity = "Legendary",
        Pets = {
            {Name = "Pigeon", Chance = 40, Rarity = "Legendary", Worth = 16000},
            {Name = "Blue Jay", Chance = 25, Rarity = "Legendary", Worth = 18790},
            {Name = "Red Bat", Chance = 10, Rarity = "Mythical", Worth = 39090},
            {Name = "Wood Coated Horse", Chance = 5, Rarity = "Mythical", Worth = 50800},
            {Name = "Giant Cobra", Chance = 1, Rarity = "Umbra", Worth = 80910}
        }
    },
    ["Mythical Egg"] = {
        Cost = 30000,
        StockChance = 100,
        Rarity = "Mythical",
        Pets = {
            {Name = "Leopard", Chance = 55, Rarity = "Mythical", Worth = 60000},
            {Name = "Shiny Crab", Chance = 20, Rarity = "Mythical", Worth = 50888},
            {Name = "Starfish", Chance = 5, Rarity = "Umbra", Worth = 90500},
            {Name = "Sky Jellyfish", Chance = 0.5, Rarity = "Imbalance", Worth = 106400}
        }
    },
    ["Umbra Egg"] = {
        Cost = 75000,
        StockChance = 250,
        Rarity = "Umbra",
        Pets = {
            {Name = "Chimera", Chance = 35, Rarity = "Umbra", Worth = 76022},
            {Name = "Cockatrice", Chance = 10, Rarity = "Umbra", Worth = 78009},
            {Name = "Phoenix", Chance = 1, Rarity = "Imbalance", Worth = 109500},
            {Name = "Golden Gorilla", Chance = 0.3, Rarity = "UNSTABLE", Worth = 358219}
        }
    },
    ["Imbalance Egg"] = {
        Cost = 100000,
        StockChance = 500,
        Rarity = "Imbalance",
        Pets = {
            {Name = "Magma Lobster", Chance = 50, Rarity = "Imbalance", Worth = 150700},
            {Name = "Griffin", Chance = 30, Rarity = "Imbalance", Worth = 175000},
            {Name = "Dead Bloomer", Chance = 5, Rarity = "UNSTABLE", Worth = 501450},
            {Name = "Diamond Raptor", Chance = 0.1, Rarity = "BEYOND", Worth = 905819}
        }
    }
}

-- Ordered Egg List for Shop Display
local EggOrder = {
    "Common Egg",
    "Uncommon Egg",
    "Rare Egg",
    "Epic Egg",
    "Legendary Egg",
    "Mythical Egg",
    "Umbra Egg",
    "Imbalance Egg"
}

-- Rarity Colors
local RarityColors = {
    ["Common"] = Color3.fromRGB(150, 150, 150),
    ["Uncommon"] = Color3.fromRGB(0, 170, 0),
    ["Rare"] = Color3.fromRGB(0, 112, 221),
    ["Epic"] = Color3.fromRGB(163, 53, 238),
    ["Legendary"] = Color3.fromRGB(255, 170, 0),
    ["Mythical"] = Color3.fromRGB(255, 85, 255),
    ["Umbra"] = Color3.fromRGB(75, 0, 130),
    ["Imbalance"] = Color3.fromRGB(220, 20, 60),
    ["UNSTABLE"] = Color3.fromRGB(255, 0, 0),
    ["BEYOND"] = Color3.fromRGB(255, 215, 0)
}

-- Shop Stock
local ShopStock = {}
local TimeUntilRestock = Config.RestockInterval

local function GenerateStock()
    ShopStock = {}
    for eggName, eggInfo in pairs(EggData) do
        local stockAmount = 0
        local chance = eggInfo.StockChance
        
        if math.random(1, chance) == 1 then
            local multiplierRoll = math.random(1, 100)
            if multiplierRoll <= 50 then
                stockAmount = 1
            elseif multiplierRoll <= 75 then
                stockAmount = math.random(2, 3)
            elseif multiplierRoll <= 90 then
                stockAmount = math.random(4, 5)
            else
                stockAmount = math.random(6, 10)
            end
        end
        
        ShopStock[eggName] = stockAmount
    end
    TimeUntilRestock = Config.RestockInterval
end

GenerateStock()

-- Weather Data
local WeatherData = {
    ["Clear"] = {
        duration = 600,
        mutations = {},
        merchant = nil,
        visual = function()
            Lighting.TimeOfDay = "12:00:00"
            Lighting.Brightness = 2
            Lighting.FogEnd = 100000
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            -- Remove particles if any
            if workspace:FindFirstChild("WeatherParticles") then
                workspace.WeatherParticles:Destroy()
            end
        end
    },
    ["Night"] = {
        chance = 100,
        duration = 600,
        mutations = {
            {name = "Lunar", multiplier = 2, chance = 5}
        },
        merchant = {
            name = "Moon Merchant",
            items = {
                {type = "egg", name = "Moonlight Egg", cost = 40500, stockChance = 3, rarity = "Mythical", pets = {
                    {Name = "Darker Night Owl", Chance = 66, Rarity = "Legendary", Worth = 55300},
                    {Name = "Floating Living Lantern", Chance = 40, Rarity = "Mythical", Worth = 50035},
                    {Name = "Traveling Moon Goblin", Chance = 25, Rarity = "Mythical", Worth = 59000},
                    {Name = "Lunar Golem", Chance = 5, Rarity = "Umbra", Worth = 83100},
                    {Name = "Darkened Humanoid", Chance = 0.8, Rarity = "Imbalance", Worth = 177777}
                }},
                {type = "pet", name = "Werewolf Pet", cost = 88482, stockChance = 7, rarity = "Umbra", worth = 88482}
            }
        },
        visual = function()
            Lighting.TimeOfDay = "00:00:00"
            Lighting.Brightness = 0.5
            Lighting.FogEnd = 100000
            Lighting.Ambient = Color3.fromRGB(50, 50, 100)
        end
    },
    ["Frosted Zone"] = {
        chance = 97,
        duration = 480,
        mutations = {
            {name = "Chilled", multiplier = 2.5, chance = 4},
            {name = "Frozen", multiplier = 4, chance = 10}
        },
        merchant = {
            name = "Ice Merchant",
            items = {
                {type = "egg", name = "Frosted Egg", cost = 17999, stockChance = 2, rarity = "Legendary", pets = {
                    {Name = "Ice Wolf", Chance = 45, Rarity = "Legendary", Worth = 10302},
                    {Name = "Living Ice Cube", Chance = 25, Rarity = "Legendary", Worth = 13192},
                    {Name = "Frozen Flamingo", Chance = 5, Rarity = "Mythical", Worth = 37771},
                    {Name = "Three Headed Ice Cub", Chance = 1, Rarity = "Umbra", Worth = 78900},
                    {Name = "Yeti", Chance = 0.4, Rarity = "Imbalance", Worth = 150320}
                }},
                {type = "egg", name = "Subzero Egg", cost = 89750, stockChance = 7, rarity = "Umbra", pets = {
                    {Name = "SnowFlake", Chance = 30, Rarity = "Umbra", Worth = 76280},
                    {Name = "Frostbite Bull", Chance = 10, Rarity = "Imbalance", Worth = 102000},
                    {Name = "Subzero Bloomer", Chance = 1, Rarity = "BEYOND", Worth = 909482}
                }},
                {type = "pet", name = "Ice Queen Pet", cost = 250000, stockChance = 10, rarity = "Imbalance", worth = 220362}
            }
        },
        visual = function()
            Lighting.TimeOfDay = "12:00:00"
            Lighting.Brightness = 1
            Lighting.FogStart = 0
            Lighting.FogEnd = 200
            Lighting.FogColor = Color3.fromRGB(200, 255, 255)
            Lighting.Ambient = Color3.fromRGB(150, 200, 255)
        end
    },
    ["Quirky"] = {
        chance = 35,
        duration = 600,
        mutations = {
            {name = "BrainMelt", multiplier = 10, chance = 15}
        },
        merchant = {
            name = "Funny Fella",
            items = {
                {type = "egg", name = "Brainrot Egg", cost = 100001, stockChance = 5, rarity = "Imbalance", pets = {
                    {Name = "Tralalero Tralala", Chance = 50, Rarity = "Mythical", Worth = 50000},
                    {Name = "Tung Tung Tung Sahur", Chance = 30, Rarity = "Mythical", Worth = 55555},
                    {Name = "Brr Brr Patapim", Chance = 10, Rarity = "Imbalance", Worth = 160303},
                    {Name = "Pot Hotspot", Chance = 1, Rarity = "UNSTABLE", Worth = 601482},
                    {Name = "Garama dan Madudung", Chance = 0.5, Rarity = "BEYOND", Worth = 899300}
                }},
                {type = "egg", name = "Mega Brainrot Egg", cost = 375375, stockChance = 10, rarity = "UNSTABLE", pets = {
                    {Name = "Nooooo my hotspot", Chance = 30, Rarity = "Imbalance", Worth = 101101},
                    {Name = "La Esok Sekolah", Chance = 10, Rarity = "Imbalance", Worth = 109400},
                    {Name = "Spaghetti Tuelleti", Chance = 2, Rarity = "UNSTABLE", Worth = 650472},
                    {Name = "La Vacca Saturnus", Chance = 0.5, Rarity = "BEYOND", Worth = 999997},
                    {Name = "La Grande Combinassion", Chance = 0.08, Rarity = "S E C R E T", Worth = 7382943}
                }},
                {type = "pet", name = "Cek Cek Satu Dua Tiga Pet", cost = 899999, stockChance = 20, rarity = "BEYOND", worth = 999999}
            }
        },
        visual = function()
            Lighting.TimeOfDay = "12:00:00"
            Lighting.Brightness = 3
            Lighting.FogEnd = 100000
            Lighting.Ambient = Color3.fromRGB(255, 200, 100)
        end
    }
}

-- Current Weather
local CurrentWeather = "Clear"
local TimeUntilWeatherChange = Config.WeatherChangeInterval
local WeatherDuration = 0

-- Merchant Stock
local MerchantStock = {}
local TimeUntilMerchantRestock = Config.MerchantRestockInterval

local function SelectWeather()
    local weathers = {"Night", "Frosted Zone", "Quirky"}
    local totalChance = 0
    for _, w in ipairs(weathers) do
        totalChance = totalChance + WeatherData[w].chance
    end
    local roll = math.random(1, totalChance)
    local current = 0
    for _, w in ipairs(weathers) do
        current = current + WeatherData[w].chance
        if roll <= current then
            return w
        end
    end
    return "Clear"
end

local function ApplyWeather(weather)
    CurrentWeather = weather
    WeatherData[weather].visual()
    WeatherDuration = WeatherData[weather].duration
    if weather ~= "Clear" then
        GenerateMerchantStock()
        merchantButton.Visible = true
        ShowNotification("🌌 New Weather: " .. weather .. "!")
    else
        merchantButton.Visible = false
    end
end

local function GenerateMerchantStock()
    MerchantStock = {}
    local merchant = WeatherData[CurrentWeather].merchant
    if merchant then
        for _, item in ipairs(merchant.items) do
            local stockAmount = 0
            if math.random(1, item.stockChance) == 1 then
                stockAmount = math.random(1, 5) -- Random stock
            end
            MerchantStock[item.name] = {amount = stockAmount, data = item}
        end
    end
    TimeUntilMerchantRestock = Config.MerchantRestockInterval
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetTradingSystem"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Mobile scaling
local scale = isMobile and 1.2 or 1

-- Money Display
local moneyFrame = Instance.new("Frame")
moneyFrame.Size = UDim2.new(0, 150 * scale, 0, 50 * scale)
moneyFrame.Position = UDim2.new(1, -160 * scale, 0, 10)
moneyFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = screenGui

local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 8)
moneyCorner.Parent = moneyFrame

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(1, 0, 1, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "💰 $" .. PlayerData.Money
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.TextSize = 20 * scale
moneyLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
moneyLabel.TextScaled = true
moneyLabel.Parent = moneyFrame

-- Weather Display
local weatherFrame = Instance.new("Frame")
weatherFrame.Size = UDim2.new(0, 150 * scale, 0, 50 * scale)
weatherFrame.Position = UDim2.new(1, -160 * scale, 0, 70 * scale)
weatherFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
weatherFrame.BorderSizePixel = 0
weatherFrame.Parent = screenGui

local weatherCorner = Instance.new("UICorner")
weatherCorner.CornerRadius = UDim.new(0, 8)
weatherCorner.Parent = weatherFrame

local weatherLabel = Instance.new("TextLabel")
weatherLabel.Size = UDim2.new(1, 0, 1, 0)
weatherLabel.BackgroundTransparency = 1
weatherLabel.Text = "☀️ Clear"
weatherLabel.Font = Enum.Font.GothamBold
weatherLabel.TextSize = 20 * scale
weatherLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
weatherLabel.TextScaled = true
weatherLabel.Parent = weatherFrame

-- Merchant Button (hidden by default)
local merchantButton = Instance.new("TextButton")
merchantButton.Size = UDim2.new(0, 150 * scale, 0, 50 * scale)
merchantButton.Position = UDim2.new(1, -160 * scale, 0, 130 * scale)
merchantButton.Text = "🛍️ Merchant"
merchantButton.Font = Enum.Font.GothamBold
merchantButton.TextSize = 18 * scale
merchantButton.TextColor3 = Color3.fromRGB(255, 255, 255)
merchantButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
merchantButton.BorderSizePixel = 0
merchantButton.TextScaled = isMobile
merchantButton.Visible = false
merchantButton.Parent = screenGui

local merchantCorner = Instance.new("UICorner")
merchantCorner.CornerRadius = UDim.new(0, 8)
merchantCorner.Parent = merchantButton

-- Shop Button
local shopButton = Instance.new("TextButton")
shopButton.Size = UDim2.new(0, 120 * scale, 0, 50 * scale)
shopButton.Position = UDim2.new(0, 10, 0, 10)
shopButton.Text = "🛒 SHOP"
shopButton.Font = Enum.Font.GothamBold
shopButton.TextSize = 18 * scale
shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
shopButton.BorderSizePixel = 0
shopButton.TextScaled = isMobile
shopButton.Parent = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 8)
shopCorner.Parent = shopButton

-- Inventory Button
local invButton = Instance.new("TextButton")
invButton.Size = UDim2.new(0, 140 * scale, 0, 50 * scale)
invButton.Position = UDim2.new(0, (130 * scale) + 10, 0, 10)
invButton.Text = "📦 INVENTORY"
invButton.Font = Enum.Font.GothamBold
invButton.TextSize = 18 * scale
invButton.TextColor3 = Color3.fromRGB(255, 255, 255)
invButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
invButton.BorderSizePixel = 0
invButton.TextScaled = isMobile
invButton.Parent = screenGui

local invCorner = Instance.new("UICorner")
invCorner.CornerRadius = UDim.new(0, 8)
invCorner.Parent = invButton

-- Admin Button
local adminButton = Instance.new("TextButton")
adminButton.Size = UDim2.new(0, 120 * scale, 0, 50 * scale)
adminButton.Position = UDim2.new(0, 10, 0, 70 * scale)
adminButton.Text = "🔧 ADMIN"
adminButton.Font = Enum.Font.GothamBold
adminButton.TextSize = 18 * scale
adminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
adminButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
adminButton.BorderSizePixel = 0
adminButton.TextScaled = isMobile
adminButton.Parent = screenGui

local adminCorner = Instance.new("UICorner")
adminCorner.CornerRadius = UDim.new(0, 8)
adminCorner.Parent = adminButton

-- Shop Frame
local shopFrame = Instance.new("Frame")
if isMobile then
    shopFrame.Size = UDim2.new(0.95, 0, 0.85, 0)
    shopFrame.Position = UDim2.new(0.025, 0, 0.075, 0)
else
    shopFrame.Size = UDim2.new(0, 700, 0, 500)
    shopFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
end
shopFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
shopFrame.Visible = false
shopFrame.Parent = screenGui

local shopFrameCorner = Instance.new("UICorner")
shopFrameCorner.CornerRadius = UDim.new(0, 12)
shopFrameCorner.Parent = shopFrame

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 50 * scale)
shopTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
shopTitle.Text = "🛒 EGG SHOP"
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 24 * scale
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.BorderSizePixel = 0
shopTitle.TextScaled = isMobile
shopTitle.Parent = shopFrame

local shopTitleCorner = Instance.new("UICorner")
shopTitleCorner.CornerRadius = UDim.new(0, 12)
shopTitleCorner.Parent = shopTitle

-- Restock Timer Label
local restockLabel = Instance.new("TextLabel")
restockLabel.Size = UDim2.new(0, 200 * scale, 0, 35 * scale)
restockLabel.Position = UDim2.new(0.5, -100 * scale, 0, 55 * scale)
restockLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
restockLabel.Text = "🔄 Restock: 3:00"
restockLabel.Font = Enum.Font.GothamBold
restockLabel.TextSize = 16 * scale
restockLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
restockLabel.BorderSizePixel = 0
restockLabel.TextScaled = isMobile
restockLabel.Parent = shopFrame

local restockCorner = Instance.new("UICorner")
restockCorner.CornerRadius = UDim.new(0, 8)
restockCorner.Parent = restockLabel

local shopCloseButton = Instance.new("TextButton")
shopCloseButton.Size = UDim2.new(0, 40 * scale, 0, 40 * scale)
shopCloseButton.Position = UDim2.new(1, -45 * scale, 0, 5)
shopCloseButton.Text = "✕"
shopCloseButton.Font = Enum.Font.GothamBold
shopCloseButton.TextSize = 20 * scale
shopCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopCloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
shopCloseButton.BorderSizePixel = 0
shopCloseButton.TextScaled = isMobile
shopCloseButton.Parent = shopFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = shopCloseButton

local shopScroll = Instance.new("ScrollingFrame")
shopScroll.Size = UDim2.new(1, -20, 1, -110 * scale)
shopScroll.Position = UDim2.new(0, 10, 0, 100 * scale)
shopScroll.BackgroundTransparency = 1
shopScroll.BorderSizePixel = 0
shopScroll.ScrollBarThickness = isMobile and 12 or 8
shopScroll.Parent = shopFrame

local shopLayout = Instance.new("UIGridLayout")
shopLayout.CellSize = isMobile and UDim2.new(0, 180, 0, 160) or UDim2.new(0, 200, 0, 150)
shopLayout.CellPadding = UDim2.new(0, 10, 0, 10)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shopScroll

-- Inventory Frame
local invFrame = Instance.new("Frame")
if isMobile then
    invFrame.Size = UDim2.new(0.95, 0, 0.85, 0)
    invFrame.Position = UDim2.new(0.025, 0, 0.075, 0)
else
    invFrame.Size = UDim2.new(0, 700, 0, 500)
    invFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
end
invFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
invFrame.Visible = false
invFrame.Parent = screenGui

local invFrameCorner = Instance.new("UICorner")
invFrameCorner.CornerRadius = UDim.new(0, 12)
invFrameCorner.Parent = invFrame

local invTitle = Instance.new("TextLabel")
invTitle.Size = UDim2.new(1, 0, 0, 50 * scale)
invTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
invTitle.Text = "📦 INVENTORY"
invTitle.Font = Enum.Font.GothamBold
invTitle.TextSize = 24 * scale
invTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
invTitle.BorderSizePixel = 0
invTitle.TextScaled = isMobile
invTitle.Parent = invFrame

local invTitleCorner = Instance.new("UICorner")
invTitleCorner.CornerRadius = UDim.new(0, 12)
invTitleCorner.Parent = invTitle

local invCloseButton = Instance.new("TextButton")
invCloseButton.Size = UDim2.new(0, 40 * scale, 0, 40 * scale)
invCloseButton.Position = UDim2.new(1, -45 * scale, 0, 5)
invCloseButton.Text = "✕"
invCloseButton.Font = Enum.Font.GothamBold
invCloseButton.TextSize = 20 * scale
invCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
invCloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
invCloseButton.BorderSizePixel = 0
invCloseButton.TextScaled = isMobile
invCloseButton.Parent = invFrame

local invCloseCorner = Instance.new("UICorner")
invCloseCorner.CornerRadius = UDim.new(0, 8)
invCloseCorner.Parent = invCloseButton

-- Tab Buttons
local eggsTabButton = Instance.new("TextButton")
eggsTabButton.Size = UDim2.new(0, 150 * scale, 0, 35 * scale)
eggsTabButton.Position = UDim2.new(0, 10, 0, 60 * scale)
eggsTabButton.Text = "EGGS"
eggsTabButton.Font = Enum.Font.GothamBold
eggsTabButton.TextSize = 16 * scale
eggsTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
eggsTabButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
eggsTabButton.BorderSizePixel = 0
eggsTabButton.TextScaled = isMobile
eggsTabButton.Parent = invFrame

local eggsTabCorner = Instance.new("UICorner")
eggsTabCorner.CornerRadius = UDim.new(0, 8)
eggsTabCorner.Parent = eggsTabButton

local petsTabButton = Instance.new("TextButton")
petsTabButton.Size = UDim2.new(0, 150 * scale, 0, 35 * scale)
petsTabButton.Position = UDim2.new(0, (160 * scale) + 10, 0, 60 * scale)
petsTabButton.Text = "PETS"
petsTabButton.Font = Enum.Font.GothamBold
petsTabButton.TextSize = 16 * scale
petsTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
petsTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
petsTabButton.BorderSizePixel = 0
petsTabButton.TextScaled = isMobile
petsTabButton.Parent = invFrame

local petsTabCorner = Instance.new("UICorner")
petsTabCorner.CornerRadius = UDim.new(0, 8)
petsTabCorner.Parent = petsTabButton

-- Eggs Scroll
local eggsScroll = Instance.new("ScrollingFrame")
eggsScroll.Size = UDim2.new(1, -20, 1, -115 * scale)
eggsScroll.Position = UDim2.new(0, 10, 0, 105 * scale)
eggsScroll.BackgroundTransparency = 1
eggsScroll.BorderSizePixel = 0
eggsScroll.ScrollBarThickness = isMobile and 12 or 8
eggsScroll.Visible = true
eggsScroll.Parent = invFrame

local eggsLayout = Instance.new("UIGridLayout")
eggsLayout.CellSize = isMobile and UDim2.new(0, 180, 0, 140) or UDim2.new(0, 200, 0, 130)
eggsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
eggsLayout.Parent = eggsScroll

-- Pets Scroll
local petsScroll = Instance.new("ScrollingFrame")
petsScroll.Size = UDim2.new(1, -20, 1, -115 * scale)
petsScroll.Position = UDim2.new(0, 10, 0, 105 * scale)
petsScroll.BackgroundTransparency = 1
petsScroll.BorderSizePixel = 0
petsScroll.ScrollBarThickness = isMobile and 12 or 8
petsScroll.Visible = false
petsScroll.Parent = invFrame

local petsLayout = Instance.new("UIGridLayout")
petsLayout.CellSize = isMobile and UDim2.new(0, 180, 0, 170) or UDim2.new(0, 200, 0, 160)
petsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
petsLayout.Parent = petsScroll

-- Admin Frame
local adminFrame = Instance.new("Frame")
if isMobile then
    adminFrame.Size = UDim2.new(0.95, 0, 0.85, 0)
    adminFrame.Position = UDim2.new(0.025, 0, 0.075, 0)
else
    adminFrame.Size = UDim2.new(0, 700, 0, 500)
    adminFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
end
adminFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
adminFrame.Visible = false
adminFrame.Parent = screenGui

local adminFrameCorner = Instance.new("UICorner")
adminFrameCorner.CornerRadius = UDim.new(0, 12)
adminFrameCorner.Parent = adminFrame

local adminTitle = Instance.new("TextLabel")
adminTitle.Size = UDim2.new(1, 0, 0, 50 * scale)
adminTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
adminTitle.Text = "🔧 ADMIN PANEL"
adminTitle.Font = Enum.Font.GothamBold
adminTitle.TextSize = 24 * scale
adminTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
adminTitle.BorderSizePixel = 0
adminTitle.TextScaled = isMobile
adminTitle.Parent = adminFrame

local adminTitleCorner = Instance.new("UICorner")
adminTitleCorner.CornerRadius = UDim.new(0, 12)
adminTitleCorner.Parent = adminTitle

local adminCloseButton = Instance.new("TextButton")
adminCloseButton.Size = UDim2.new(0, 40 * scale, 0, 40 * scale)
adminCloseButton.Position = UDim2.new(1, -45 * scale, 0, 5)
adminCloseButton.Text = "✕"
adminCloseButton.Font = Enum.Font.GothamBold
adminCloseButton.TextSize = 20 * scale
adminCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
adminCloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
adminCloseButton.BorderSizePixel = 0
adminCloseButton.TextScaled = isMobile
adminCloseButton.Parent = adminFrame

local adminCloseCorner = Instance.new("UICorner")
adminCloseCorner.CornerRadius = UDim.new(0, 8)
adminCloseCorner.Parent = adminCloseButton

-- Admin Content
local adminContent = Instance.new("ScrollingFrame")
adminContent.Size = UDim2.new(1, -20, 1, -60 * scale)
adminContent.Position = UDim2.new(0, 10, 0, 60 * scale)
adminContent.BackgroundTransparency = 1
adminContent.BorderSizePixel = 0
adminContent.ScrollBarThickness = isMobile and 12 or 8
adminContent.Parent = adminFrame

local adminLayout = Instance.new("UIListLayout")
adminLayout.Padding = UDim.new(0, 10 * scale)
adminLayout.SortOrder = Enum.SortOrder.LayoutOrder
adminLayout.Parent = adminContent

-- Function to create dropdown
local function CreateDropdown(parent, labelText, options, default)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(1, 0, 0, 40 * scale)
    dropdownFrame.BackgroundTransparency = 1
    dropdownFrame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16 * scale
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = dropdownFrame

    local selectedButton = Instance.new("TextButton")
    selectedButton.Size = UDim2.new(0.6, 0, 1, 0)
    selectedButton.Position = UDim2.new(0.4, 0, 0, 0)
    selectedButton.Text = default or options[1]
    selectedButton.Font = Enum.Font.Gotham
    selectedButton.TextSize = 14 * scale
    selectedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectedButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    selectedButton.BorderSizePixel = 0
    selectedButton.Parent = dropdownFrame

    local selectedCorner = Instance.new("UICorner")
    selectedCorner.CornerRadius = UDim.new(0, 6)
    selectedCorner.Parent = selectedButton

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(0.6, 0, 0, 150 * scale)
    listFrame.Position = UDim2.new(0.4, 0, 1, 0)
    listFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 6
    listFrame.Visible = false
    listFrame.ZIndex = 10
    listFrame.Parent = dropdownFrame

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = listFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listFrame

    for _, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, 0, 0, 30 * scale)
        optionButton.Text = option
        optionButton.Font = Enum.Font.Gotham
        optionButton.TextSize = 14 * scale
        optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        optionButton.BackgroundTransparency = 1
        optionButton.ZIndex = 10
        optionButton.Parent = listFrame

        optionButton.MouseButton1Click:Connect(function()
            selectedButton.Text = option
            listFrame.Visible = false
        end)
    end

    listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)

    selectedButton.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
    end)

    return selectedButton, dropdownFrame
end

-- Collect egg names
local EggNames = {}
for _, name in ipairs(EggOrder) do
    table.insert(EggNames, name)
end

-- Collect all pets
local AllPets = {}
for eggName, eggInfo in pairs(EggData) do
    for _, pet in ipairs(eggInfo.Pets) do
        table.insert(AllPets, {Name = pet.Name, Rarity = pet.Rarity, Worth = pet.Worth, Origin = eggName})
    end
end

local PetNames = {}
for _, pet in ipairs(AllPets) do
    table.insert(PetNames, pet.Name .. " (" .. pet.Rarity .. ")")
end
table.sort(PetNames)

-- Restock Shop Now Button
local restockShopButton = Instance.new("TextButton")
restockShopButton.Size = UDim2.new(1, 0, 0, 40 * scale)
restockShopButton.Text = "Restock Shop Now"
restockShopButton.Font = Enum.Font.GothamBold
restockShopButton.TextSize = 16 * scale
restockShopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
restockShopButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
restockShopButton.BorderSizePixel = 0
restockShopButton.Parent = adminContent

local restockShopCorner = Instance.new("UICorner")
restockShopCorner.CornerRadius = UDim.new(0, 8)
restockShopCorner.Parent = restockShopButton

-- Restock Egg Dropdown and Button
local restockEggSelected, restockEggDropdown = CreateDropdown(adminContent, "Restock Egg:", EggNames, EggNames[1])

local restockEggButton = Instance.new("TextButton")
restockEggButton.Size = UDim2.new(1, 0, 0, 40 * scale)
restockEggButton.Text = "Restock Egg Now"
restockEggButton.Font = Enum.Font.GothamBold
restockEggButton.TextSize = 16 * scale
restockEggButton.TextColor3 = Color3.fromRGB(255, 255, 255)
restockEggButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
restockEggButton.BorderSizePixel = 0
restockEggButton.Parent = adminContent

local restockEggCorner = Instance.new("UICorner")
restockEggCorner.CornerRadius = UDim.new(0, 8)
restockEggCorner.Parent = restockEggButton

-- Give Egg Dropdown and Button
local giveEggSelected, giveEggDropdown = CreateDropdown(adminContent, "Give Egg:", EggNames, EggNames[1])

local giveEggButton = Instance.new("TextButton")
giveEggButton.Size = UDim2.new(1, 0, 0, 40 * scale)
giveEggButton.Text = "Give Egg"
giveEggButton.Font = Enum.Font.GothamBold
giveEggButton.TextSize = 16 * scale
giveEggButton.TextColor3 = Color3.fromRGB(255, 255, 255)
giveEggButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
giveEggButton.BorderSizePixel = 0
giveEggButton.Parent = adminContent

local giveEggCorner = Instance.new("UICorner")
giveEggCorner.CornerRadius = UDim.new(0, 8)
giveEggCorner.Parent = giveEggButton

-- Give Pet Dropdown and Button
local givePetSelected, givePetDropdown = CreateDropdown(adminContent, "Give Pet:", PetNames, PetNames[1])

local givePetButton = Instance.new("TextButton")
givePetButton.Size = UDim2.new(1, 0, 0, 40 * scale)
givePetButton.Text = "Give Pet"
givePetButton.Font = Enum.Font.GothamBold
givePetButton.TextSize = 16 * scale
givePetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
givePetButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
givePetButton.BorderSizePixel = 0
givePetButton.Parent = adminContent

local givePetCorner = Instance.new("UICorner")
givePetCorner.CornerRadius = UDim.new(0, 8)
givePetCorner.Parent = givePetButton

-- Give Money Input and Button
local giveMoneyFrame = Instance.new("Frame")
giveMoneyFrame.Size = UDim2.new(1, 0, 0, 40 * scale)
giveMoneyFrame.BackgroundTransparency = 1
giveMoneyFrame.Parent = adminContent

local giveMoneyLabel = Instance.new("TextLabel")
giveMoneyLabel.Size = UDim2.new(0.4, 0, 1, 0)
giveMoneyLabel.BackgroundTransparency = 1
giveMoneyLabel.Text = "Give Money:"
giveMoneyLabel.Font = Enum.Font.GothamBold
giveMoneyLabel.TextSize = 16 * scale
giveMoneyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
giveMoneyLabel.TextXAlignment = Enum.TextXAlignment.Left
giveMoneyLabel.Parent = giveMoneyFrame

local giveMoneyInput = Instance.new("TextBox")
giveMoneyInput.Size = UDim2.new(0.4, 0, 1, 0)
giveMoneyInput.Position = UDim2.new(0.4, 0, 0, 0)
giveMoneyInput.Text = "1000"
giveMoneyInput.Font = Enum.Font.Gotham
giveMoneyInput.TextSize = 14 * scale
giveMoneyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
giveMoneyInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
giveMoneyInput.BorderSizePixel = 0
giveMoneyInput.Parent = giveMoneyFrame

local giveMoneyInputCorner = Instance.new("UICorner")
giveMoneyInputCorner.CornerRadius = UDim.new(0, 6)
giveMoneyInputCorner.Parent = giveMoneyInput

local giveMoneyButton = Instance.new("TextButton")
giveMoneyButton.Size = UDim2.new(0.2, 0, 1, 0)
giveMoneyButton.Position = UDim2.new(0.8, 0, 0, 0)
giveMoneyButton.Text = "Add"
giveMoneyButton.Font = Enum.Font.GothamBold
giveMoneyButton.TextSize = 16 * scale
giveMoneyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
giveMoneyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
giveMoneyButton.BorderSizePixel = 0
giveMoneyButton.Parent = giveMoneyFrame

local giveMoneyButtonCorner = Instance.new("UICorner")
giveMoneyButtonCorner.CornerRadius = UDim.new(0, 8)
giveMoneyButtonCorner.Parent = giveMoneyButton

-- Update canvas size for admin
adminContent.CanvasSize = UDim2.new(0, 0, 0, adminLayout.AbsoluteContentSize.Y + 20)

-- Merchant Frame
local merchantFrame = Instance.new("Frame")
if isMobile then
    merchantFrame.Size = UDim2.new(0.95, 0, 0.85, 0)
    merchantFrame.Position = UDim2.new(0.025, 0, 0.075, 0)
else
    merchantFrame.Size = UDim2.new(0, 700, 0, 500)
    merchantFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
end
merchantFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
merchantFrame.Visible = false
merchantFrame.Parent = screenGui

local merchantFrameCorner = Instance.new("UICorner")
merchantFrameCorner.CornerRadius = UDim.new(0, 12)
merchantFrameCorner.Parent = merchantFrame

local merchantTitle = Instance.new("TextLabel")
merchantTitle.Size = UDim2.new(1, 0, 0, 50 * scale)
merchantTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
merchantTitle.Text = "🛍️ TRAVELING MERCHANT"
merchantTitle.Font = Enum.Font.GothamBold
merchantTitle.TextSize = 24 * scale
merchantTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
merchantTitle.BorderSizePixel = 0
merchantTitle.TextScaled = isMobile
merchantTitle.Parent = merchantFrame

local merchantTitleCorner = Instance.new("UICorner")
merchantTitleCorner.CornerRadius = UDim.new(0, 12)
merchantTitleCorner.Parent = merchantTitle

local merchantRestockLabel = Instance.new("TextLabel")
merchantRestockLabel.Size = UDim2.new(0, 200 * scale, 0, 35 * scale)
merchantRestockLabel.Position = UDim2.new(0.5, -100 * scale, 0, 55 * scale)
merchantRestockLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
merchantRestockLabel.Text = "🔄 Restock: 2:00"
merchantRestockLabel.Font = Enum.Font.GothamBold
merchantRestockLabel.TextSize = 16 * scale
merchantRestockLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
merchantRestockLabel.BorderSizePixel = 0
merchantRestockLabel.TextScaled = isMobile
merchantRestockLabel.Parent = merchantFrame

local merchantRestockCorner = Instance.new("UICorner")
merchantRestockCorner.CornerRadius = UDim.new(0, 8)
merchantRestockCorner.Parent = merchantRestockLabel

local merchantCloseButton = Instance.new("TextButton")
merchantCloseButton.Size = UDim2.new(0, 40 * scale, 0, 40 * scale)
merchantCloseButton.Position = UDim2.new(1, -45 * scale, 0, 5)
merchantCloseButton.Text = "✕"
merchantCloseButton.Font = Enum.Font.GothamBold
merchantCloseButton.TextSize = 20 * scale
merchantCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
merchantCloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
merchantCloseButton.BorderSizePixel = 0
merchantCloseButton.TextScaled = isMobile
merchantCloseButton.Parent = merchantFrame

local merchantCloseCorner = Instance.new("UICorner")
merchantCloseCorner.CornerRadius = UDim.new(0, 8)
merchantCloseCorner.Parent = merchantCloseButton

local merchantScroll = Instance.new("ScrollingFrame")
merchantScroll.Size = UDim2.new(1, -20, 1, -110 * scale)
merchantScroll.Position = UDim2.new(0, 10, 0, 100 * scale)
merchantScroll.BackgroundTransparency = 1
merchantScroll.BorderSizePixel = 0
merchantScroll.ScrollBarThickness = isMobile and 12 or 8
merchantScroll.Parent = merchantFrame

local merchantLayout = Instance.new("UIGridLayout")
merchantLayout.CellSize = isMobile and UDim2.new(0, 180, 0, 160) or UDim2.new(0, 200, 0, 150)
merchantLayout.CellPadding = UDim2.new(0, 10, 0, 10)
merchantLayout.SortOrder = Enum.SortOrder.LayoutOrder
merchantLayout.Parent = merchantScroll

-- Notification
local notificationLabel = Instance.new("TextLabel")
if isMobile then
    notificationLabel.Size = UDim2.new(0.8, 0, 0, 70)
    notificationLabel.Position = UDim2.new(0.1, 0, 0, -90)
else
    notificationLabel.Size = UDim2.new(0, 400, 0, 60)
    notificationLabel.Position = UDim2.new(0.5, -200, 0, -80)
end
notificationLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
notificationLabel.Text = ""
notificationLabel.Font = Enum.Font.GothamBold
notificationLabel.TextSize = 20 * scale
notificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notificationLabel.BorderSizePixel = 0
notificationLabel.Visible = false
notificationLabel.TextScaled = isMobile
notificationLabel.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 10)
notifCorner.Parent = notificationLabel

-- Functions
function ShowNotification(text)
    notificationLabel.Text = text
    notificationLabel.Visible = true
    if isMobile then
        notificationLabel:TweenPosition(UDim2.new(0.1, 0, 0, 20), "Out", "Quad", 0.5, true)
    else
        notificationLabel:TweenPosition(UDim2.new(0.5, -200, 0, 20), "Out", "Quad", 0.5, true)
    end
    
    wait(3)
    
    if isMobile then
        notificationLabel:TweenPosition(UDim2.new(0.1, 0, 0, -90), "In", "Quad", 0.5, true, function()
            notificationLabel.Visible = false
        end)
    else
        notificationLabel:TweenPosition(UDim2.new(0.5, -200, 0, -80), "In", "Quad", 0.5, true, function()
            notificationLabel.Visible = false
        end)
    end
end

function UpdateMoney()
    moneyLabel.Text = "💰 $" .. PlayerData.Money
end

function UpdateRestockTimer()
    local minutes = math.floor(TimeUntilRestock / 60)
    local seconds = TimeUntilRestock % 60
    restockLabel.Text = string.format("🔄 Restock: %d:%02d", minutes, seconds)
end

function UpdateMerchantRestockTimer()
    local minutes = math.floor(TimeUntilMerchantRestock / 60)
    local seconds = TimeUntilMerchantRestock % 60
    merchantRestockLabel.Text = string.format("🔄 Restock: %d:%02d", minutes, seconds)
end

function UpdateWeatherLabel()
    local icon = ""
    if CurrentWeather == "Night" then
        icon = "🌙"
    elseif CurrentWeather == "Frosted Zone" then
        icon = "❄️"
    elseif CurrentWeather == "Quirky" then
        icon = "🤪"
    else
        icon = "☀️"
    end
    weatherLabel.Text = icon .. " " .. CurrentWeather
end

function UpdateShop()
    for _, child in ipairs(shopScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for _, eggName in ipairs(EggOrder) do
        local stockAmount = ShopStock[eggName] or 0
        local eggInfo = EggData[eggName]
        
        local eggCard = Instance.new("Frame")
        eggCard.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        eggCard.BorderSizePixel = 0
        eggCard.LayoutOrder = _
        eggCard.Parent = shopScroll
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = eggCard
        
        local eggNameLabel = Instance.new("TextLabel")
        eggNameLabel.Size = UDim2.new(1, -10, 0, 25)
        eggNameLabel.Position = UDim2.new(0, 5, 0, 5)
        eggNameLabel.BackgroundTransparency = 1
        eggNameLabel.Text = eggName
        eggNameLabel.Font = Enum.Font.GothamBold
        eggNameLabel.TextSize = 14
        eggNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        eggNameLabel.TextScaled = true
        eggNameLabel.Parent = eggCard
        
        if stockAmount > 0 then
            local priceLabel = Instance.new("TextLabel")
            priceLabel.Size = UDim2.new(1, -10, 0, 22)
            priceLabel.Position = UDim2.new(0, 5, 0, 32)
            priceLabel.BackgroundTransparency = 1
            priceLabel.Text = "$" .. eggInfo.Cost
            priceLabel.Font = Enum.Font.GothamBold
            priceLabel.TextSize = 18
            priceLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
            priceLabel.TextScaled = isMobile
            priceLabel.Parent = eggCard
            
            local rarityLabel = Instance.new("TextLabel")
            rarityLabel.Size = UDim2.new(1, -10, 0, 18)
            rarityLabel.Position = UDim2.new(0, 5, 0, 56)
            rarityLabel.BackgroundTransparency = 1
            rarityLabel.Text = eggInfo.Rarity
            rarityLabel.Font = Enum.Font.Gotham
            rarityLabel.TextSize = 14
            rarityLabel.TextColor3 = RarityColors[eggInfo.Rarity]
            rarityLabel.TextScaled = isMobile
            rarityLabel.Parent = eggCard
            
            local stockLabel = Instance.new("TextLabel")
            stockLabel.Size = UDim2.new(1, -10, 0, 18)
            stockLabel.Position = UDim2.new(0, 5, 0, 76)
            stockLabel.BackgroundTransparency = 1
            stockLabel.Text = stockAmount .. "x"
            stockLabel.Font = Enum.Font.GothamBold
            stockLabel.TextSize = 16
            stockLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            stockLabel.TextScaled = isMobile
            stockLabel.Parent = eggCard
            
            local buyButton = Instance.new("TextButton")
            buyButton.Size = UDim2.new(1, -10, 0, 35)
            buyButton.Position = UDim2.new(0, 5, 1, -40)
            buyButton.Text = "BUY"
            buyButton.Font = Enum.Font.GothamBold
            buyButton.TextSize = 16
            buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            buyButton.BorderSizePixel = 0
            buyButton.TextScaled = isMobile
            buyButton.Parent = eggCard
            
            local buyCorner = Instance.new("UICorner")
            buyCorner.CornerRadius = UDim.new(0, 6)
            buyCorner.Parent = buyButton
            
            buyButton.MouseButton1Click:Connect(function()
                if PlayerData.Money >= eggInfo.Cost and ShopStock[eggName] > 0 then
                    PlayerData.Money = PlayerData.Money - eggInfo.Cost
                    ShopStock[eggName] = ShopStock[eggName] - 1
                    table.insert(PlayerData.Eggs, {Name = eggName, Rarity = eggInfo.Rarity})
                    UpdateMoney()
                    UpdateShop()
                    ShowNotification("✅ Purchased " .. eggName .. "!")
                else
                    ShowNotification("❌ Not enough money or out of stock!")
                end
            end)
        else
            local noStockLabel = Instance.new("TextLabel")
            noStockLabel.Size = UDim2.new(1, -10, 0, 30)
            noStockLabel.Position = UDim2.new(0, 5, 0, 40)
            noStockLabel.BackgroundTransparency = 1
            noStockLabel.Text = "NO STOCK"
            noStockLabel.Font = Enum.Font.GothamBold
            noStockLabel.TextSize = 20
            noStockLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            noStockLabel.TextScaled = isMobile
            noStockLabel.Parent = eggCard
            
            local rarityLabel = Instance.new("TextLabel")
            rarityLabel.Size = UDim2.new(1, -10, 0, 18)
            rarityLabel.Position = UDim2.new(0, 5, 0, 75)
            rarityLabel.BackgroundTransparency = 1
            rarityLabel.Text = eggInfo.Rarity
            rarityLabel.Font = Enum.Font.Gotham
            rarityLabel.TextSize = 14
            rarityLabel.TextColor3 = RarityColors[eggInfo.Rarity]
            rarityLabel.TextScaled = isMobile
            rarityLabel.Parent = eggCard
            
            local stockLabel = Instance.new("TextLabel")
            stockLabel.Size = UDim2.new(1, -10, 0, 18)
            stockLabel.Position = UDim2.new(0, 5, 0, 95)
            stockLabel.BackgroundTransparency = 1
            stockLabel.Text = "0x"
            stockLabel.Font = Enum.Font.GothamBold
            stockLabel.TextSize = 16
            stockLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            stockLabel.TextScaled = isMobile
            stockLabel.Parent = eggCard
        end
    end
    
    shopScroll.CanvasSize = UDim2.new(0, 0, 0, shopLayout.AbsoluteContentSize.Y + 10)
end

function UpdateMerchant()
    for _, child in ipairs(merchantScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local merchant = WeatherData[CurrentWeather].merchant
    if merchant then
        merchantTitle.Text = "🛍️ " .. merchant.name
        for name, stock in pairs(MerchantStock) do
            local item = stock.data
            local stockAmount = stock.amount
            local card = Instance.new("Frame")
            card.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            card.BorderSizePixel = 0
            card.Parent = merchantScroll
            
            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 8)
            cardCorner.Parent = card
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -10, 0, 25)
            nameLabel.Position = UDim2.new(0, 5, 0, 5)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = name
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 14
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.TextScaled = true
            nameLabel.Parent = card
            
            if stockAmount > 0 then
                local priceLabel = Instance.new("TextLabel")
                priceLabel.Size = UDim2.new(1, -10, 0, 22)
                priceLabel.Position = UDim2.new(0, 5, 0, 32)
                priceLabel.BackgroundTransparency = 1
                priceLabel.Text = "$" .. item.cost
                priceLabel.Font = Enum.Font.GothamBold
                priceLabel.TextSize = 18
                priceLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
                priceLabel.TextScaled = isMobile
                priceLabel.Parent = card
                
                local rarityLabel = Instance.new("TextLabel")
                rarityLabel.Size = UDim2.new(1, -10, 0, 18)
                rarityLabel.Position = UDim2.new(0, 5, 0, 56)
                rarityLabel.BackgroundTransparency = 1
                rarityLabel.Text = item.rarity
                rarityLabel.Font = Enum.Font.Gotham
                rarityLabel.TextSize = 14
                rarityLabel.TextColor3 = RarityColors[item.rarity] or Color3.fromRGB(255, 255, 255)
                rarityLabel.TextScaled = isMobile
                rarityLabel.Parent = card
                
                local stockLabel = Instance.new("TextLabel")
                stockLabel.Size = UDim2.new(1, -10, 0, 18)
                stockLabel.Position = UDim2.new(0, 5, 0, 76)
                stockLabel.BackgroundTransparency = 1
                stockLabel.Text = stockAmount .. "x"
                stockLabel.Font = Enum.Font.GothamBold
                stockLabel.TextSize = 16
                stockLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                stockLabel.TextScaled = isMobile
                stockLabel.Parent = card
                
                local buyButton = Instance.new("TextButton")
                buyButton.Size = UDim2.new(1, -10, 0, 35)
                buyButton.Position = UDim2.new(0, 5, 1, -40)
                buyButton.Text = "BUY"
                buyButton.Font = Enum.Font.GothamBold
                buyButton.TextSize = 16
                buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                buyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                buyButton.BorderSizePixel = 0
                buyButton.TextScaled = isMobile
                buyButton.Parent = card
                
                local buyCorner = Instance.new("UICorner")
                buyCorner.CornerRadius = UDim.new(0, 6)
                buyCorner.Parent = buyButton
                
                buyButton.MouseButton1Click:Connect(function()
                    if PlayerData.Money >= item.cost and stockAmount > 0 then
                        PlayerData.Money = PlayerData.Money - item.cost
                        MerchantStock[name].amount = MerchantStock[name].amount - 1
                        if item.type == "egg" then
                            table.insert(PlayerData.Eggs, {Name = name, Rarity = item.rarity, Pets = item.pets})
                        else
                            table.insert(PlayerData.Pets, {
                                Name = name,
                                Rarity = item.rarity,
                                Origin = "Merchant",
                                Worth = item.worth
                            })
                        end
                        UpdateMoney()
                        UpdateMerchant()
                        ShowNotification("✅ Purchased " .. name .. "!")
                    else
                        ShowNotification("❌ Not enough money or out of stock!")
                    end
                end)
            else
                local noStockLabel = Instance.new("TextLabel")
                noStockLabel.Size = UDim2.new(1, -10, 0, 30)
                noStockLabel.Position = UDim2.new(0, 5, 0, 40)
                noStockLabel.BackgroundTransparency = 1
                noStockLabel.Text = "NO STOCK"
                noStockLabel.Font = Enum.Font.GothamBold
                noStockLabel.TextSize = 20
                noStockLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                noStockLabel.TextScaled = isMobile
                noStockLabel.Parent = card
                
                local rarityLabel = Instance.new("TextLabel")
                rarityLabel.Size = UDim2.new(1, -10, 0, 18)
                rarityLabel.Position = UDim2.new(0, 5, 0, 75)
                rarityLabel.BackgroundTransparency = 1
                rarityLabel.Text = item.rarity
                rarityLabel.Font = Enum.Font.Gotham
                rarityLabel.TextSize = 14
                rarityLabel.TextColor3 = RarityColors[item.rarity] or Color3.fromRGB(255, 255, 255)
                rarityLabel.TextScaled = isMobile
                rarityLabel.Parent = card
                
                local stockLabel = Instance.new("TextLabel")
                stockLabel.Size = UDim2.new(1, -10, 0, 18)
                stockLabel.Position = UDim2.new(0, 5, 0, 95)
                stockLabel.BackgroundTransparency = 1
                stockLabel.Text = "0x"
                stockLabel.Font = Enum.Font.GothamBold
                stockLabel.TextSize = 16
                stockLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                stockLabel.TextScaled = isMobile
                stockLabel.Parent = card
            end
        end
    end
    
    merchantScroll.CanvasSize = UDim2.new(0, 0, 0, merchantLayout.AbsoluteContentSize.Y + 10)
end

function UpdateInventory()
    -- Clear eggs
    for _, child in ipairs(eggsScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Clear pets
    for _, child in ipairs(petsScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add eggs
    for i, egg in ipairs(PlayerData.Eggs) do
        local eggCard = Instance.new("Frame")
        eggCard.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        eggCard.BorderSizePixel = 0
        eggCard.Parent = eggsScroll
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = eggCard
        
        local eggNameLabel = Instance.new("TextLabel")
        eggNameLabel.Size = UDim2.new(1, -10, 0, 30)
        eggNameLabel.Position = UDim2.new(0, 5, 0, 5)
        eggNameLabel.BackgroundTransparency = 1
        eggNameLabel.Text = egg.Name
        eggNameLabel.Font = Enum.Font.GothamBold
        eggNameLabel.TextSize = 14
        eggNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        eggNameLabel.TextScaled = true
        eggNameLabel.Parent = eggCard
        
        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(1, -10, 0, 20)
        rarityLabel.Position = UDim2.new(0, 5, 0, 38)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Text = egg.Rarity
        rarityLabel.Font = Enum.Font.Gotham
        rarityLabel.TextSize = 14
        rarityLabel.TextColor3 = RarityColors[egg.Rarity]
        rarityLabel.TextScaled = isMobile
        rarityLabel.Parent = eggCard
        
        local hatchButton = Instance.new("TextButton")
        hatchButton.Size = UDim2.new(1, -10, 0, 40)
        hatchButton.Position = UDim2.new(0, 5, 1, -45)
        hatchButton.Text = "🥚 HATCH"
        hatchButton.Font = Enum.Font.GothamBold
        hatchButton.TextSize = 16
        hatchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        hatchButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
        hatchButton.BorderSizePixel = 0
        hatchButton.TextScaled = isMobile
        hatchButton.Parent = eggCard
        
        local hatchCorner = Instance.new("UICorner")
        hatchCorner.CornerRadius = UDim.new(0, 6)
        hatchCorner.Parent = hatchButton
        
        hatchButton.MouseButton1Click:Connect(function()
            local eggInfo = EggData[egg.Name] or egg -- For merchant eggs, egg has Pets
            local pets = eggInfo.Pets or egg.pets
            
            -- Roll for pet
            local totalChance = 0
            for _, pet in ipairs(pets) do
                totalChance = totalChance + pet.Chance
            end
            
            local roll = math.random() * totalChance
            local currentChance = 0
            local selectedPet = nil
            
            for _, pet in ipairs(pets) do
                currentChance = currentChance + pet.Chance
                if roll <= currentChance then
                    selectedPet = pet
                    break
                end
            end
            
            if selectedPet then
                local worth = selectedPet.Worth
                local mutationText = ""
                if CurrentWeather ~= "Clear" then
                    local mutations = WeatherData[CurrentWeather].mutations
                    for _, mut in ipairs(mutations) do
                        if math.random(1, mut.chance) == 1 then
                            worth = math.floor(worth * mut.multiplier)
                            mutationText = " with " .. mut.name .. " mutation!"
                            break
                        end
                    end
                end
                
                table.insert(PlayerData.Pets, {
                    Name = selectedPet.Name,
                    Rarity = selectedPet.Rarity,
                    Origin = egg.Name or egg.Origin or "Hatched",
                    Worth = worth
                })
                
                table.remove(PlayerData.Eggs, i)
                UpdateInventory()
                ShowNotification("🎉 You got " .. selectedPet.Name .. mutationText)
            end
        end)
    end
    
    -- Add pets
    for i, pet in ipairs(PlayerData.Pets) do
        local petCard = Instance.new("Frame")
        petCard.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        petCard.BorderSizePixel = 0
        petCard.Parent = petsScroll
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = petCard
        
        local petNameLabel = Instance.new("TextLabel")
        petNameLabel.Size = UDim2.new(1, -10, 0, 25)
        petNameLabel.Position = UDim2.new(0, 5, 0, 5)
        petNameLabel.BackgroundTransparency = 1
        petNameLabel.Text = pet.Name
        petNameLabel.Font = Enum.Font.GothamBold
        petNameLabel.TextSize = 14
        petNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        petNameLabel.TextScaled = true
        petNameLabel.Parent = petCard
        
        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(1, -10, 0, 18)
        rarityLabel.Position = UDim2.new(0, 5, 0, 32)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Text = pet.Rarity
        rarityLabel.Font = Enum.Font.Gotham
        rarityLabel.TextSize = 13
        rarityLabel.TextColor3 = RarityColors[pet.Rarity]
        rarityLabel.TextScaled = isMobile
        rarityLabel.Parent = petCard
        
        local originLabel = Instance.new("TextLabel")
        originLabel.Size = UDim2.new(1, -10, 0, 35)
        originLabel.Position = UDim2.new(0, 5, 0, 52)
        originLabel.BackgroundTransparency = 1
        originLabel.Text = "From: " .. pet.Origin
        originLabel.Font = Enum.Font.Gotham
        originLabel.TextSize = 11
        originLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        originLabel.TextWrapped = true
        originLabel.TextScaled = isMobile
        originLabel.Parent = petCard
        
        local worthLabel = Instance.new("TextLabel")
        worthLabel.Size = UDim2.new(1, -10, 0, 20)
        worthLabel.Position = UDim2.new(0, 5, 0, 90)
        worthLabel.BackgroundTransparency = 1
        worthLabel.Text = "Worth: $" .. pet.Worth
        worthLabel.Font = Enum.Font.GothamBold
        worthLabel.TextSize = 12
        worthLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
        worthLabel.TextScaled = isMobile
        worthLabel.Parent = petCard
        
        local sellButton = Instance.new("TextButton")
        sellButton.Size = UDim2.new(1, -10, 0, 35)
        sellButton.Position = UDim2.new(0, 5, 1, -40)
        sellButton.Text = "💰 SELL"
        sellButton.Font = Enum.Font.GothamBold
        sellButton.TextSize = 14
        sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        sellButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        sellButton.BorderSizePixel = 0
        sellButton.TextScaled = isMobile
        sellButton.Parent = petCard
        
        local sellCorner = Instance.new("UICorner")
        sellCorner.CornerRadius = UDim.new(0, 6)
        sellCorner.Parent = sellButton
        
        sellButton.MouseButton1Click:Connect(function()
            PlayerData.Money = PlayerData.Money + pet.Worth
            table.remove(PlayerData.Pets, i)
            UpdateMoney()
            UpdateInventory()
            ShowNotification("💰 Sold " .. pet.Name .. " for $" .. pet.Worth .. "!")
        end)
    end
    
    eggsScroll.CanvasSize = UDim2.new(0, 0, 0, eggsLayout.AbsoluteContentSize.Y + 10)
    petsScroll.CanvasSize = UDim2.new(0, 0, 0, petsLayout.AbsoluteContentSize.Y + 10)
end

-- Admin Button Connections
restockShopButton.MouseButton1Click:Connect(function()
    GenerateStock()
    UpdateShop()
    ShowNotification("🔄 Shop Restocked!")
end)

restockEggButton.MouseButton1Click:Connect(function()
    local selectedEgg = restockEggSelected.Text
    if EggData[selectedEgg] then
        ShopStock[selectedEgg] = (ShopStock[selectedEgg] or 0) + 10  -- Add 10 stock
        UpdateShop()
        ShowNotification("🔄 Restocked " .. selectedEgg .. "!")
    end
end)

giveEggButton.MouseButton1Click:Connect(function()
    local selectedEgg = giveEggSelected.Text
    if EggData[selectedEgg] then
        table.insert(PlayerData.Eggs, {Name = selectedEgg, Rarity = EggData[selectedEgg].Rarity, Pets = EggData[selectedEgg].Pets})
        UpdateInventory()
        ShowNotification("✅ Gave " .. selectedEgg .. " to inventory!")
    end
end)

givePetButton.MouseButton1Click:Connect(function()
    local selectedPetStr = givePetSelected.Text
    local petName = selectedPetStr:match("^(.-) %(")
    for _, pet in ipairs(AllPets) do
        if pet.Name == petName then
            table.insert(PlayerData.Pets, {
                Name = pet.Name,
                Rarity = pet.Rarity,
                Origin = pet.Origin,
                Worth = pet.Worth
            })
            UpdateInventory()
            ShowNotification("✅ Gave " .. pet.Name .. "!")
            break
        end
    end
end)

giveMoneyButton.MouseButton1Click:Connect(function()
    local amount = tonumber(giveMoneyInput.Text)
    if amount then
        PlayerData.Money = PlayerData.Money + amount
        UpdateMoney()
        ShowNotification("💰 Added $" .. amount .. "!")
    else
        ShowNotification("❌ Invalid amount!")
    end
end)

-- Button Connections
shopButton.MouseButton1Click:Connect(function()
    shopFrame.Visible = not shopFrame.Visible
    invFrame.Visible = false
    adminFrame.Visible = false
    merchantFrame.Visible = false
    if shopFrame.Visible then
        UpdateShop()
    end
end)

invButton.MouseButton1Click:Connect(function()
    invFrame.Visible = not invFrame.Visible
    shopFrame.Visible = false
    adminFrame.Visible = false
    merchantFrame.Visible = false
    if invFrame.Visible then
        UpdateInventory()
    end
end)

adminButton.MouseButton1Click:Connect(function()
    adminFrame.Visible = not adminFrame.Visible
    shopFrame.Visible = false
    invFrame.Visible = false
    merchantFrame.Visible = false
end)

merchantButton.MouseButton1Click:Connect(function()
    merchantFrame.Visible = not merchantFrame.Visible
    shopFrame.Visible = false
    invFrame.Visible = false
    adminFrame.Visible = false
    if merchantFrame.Visible then
        UpdateMerchant()
    end
end)

shopCloseButton.MouseButton1Click:Connect(function()
    shopFrame.Visible = false
end)

invCloseButton.MouseButton1Click:Connect(function()
    invFrame.Visible = false
end)

adminCloseButton.MouseButton1Click:Connect(function()
    adminFrame.Visible = false
end)

merchantCloseButton.MouseButton1Click:Connect(function()
    merchantFrame.Visible = false
end)

eggsTabButton.MouseButton1Click:Connect(function()
    eggsScroll.Visible = true
    petsScroll.Visible = false
    eggsTabButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    petsTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

petsTabButton.MouseButton1Click:Connect(function()
    eggsScroll.Visible = false
    petsScroll.Visible = true
    eggsTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    petsTabButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
end)

-- Restock timer loop
spawn(function()
    while true do
        wait(1)
        TimeUntilRestock = TimeUntilRestock - 1
        
        if TimeUntilRestock <= 0 then
            GenerateStock()
            if shopFrame.Visible then
                UpdateShop()
            end
            ShowNotification("🔄 Shop Restocked!")
        end
        
        UpdateRestockTimer()
    end
end)

-- Merchant restock loop
spawn(function()
    while true do
        wait(1)
        if CurrentWeather ~= "Clear" then
            TimeUntilMerchantRestock = TimeUntilMerchantRestock - 1
            if TimeUntilMerchantRestock <= 0 then
                GenerateMerchantStock()
                if merchantFrame.Visible then
                    UpdateMerchant()
                end
                ShowNotification("🔄 Merchant Restocked!")
            end
            UpdateMerchantRestockTimer()
        end
    end
end)

-- Weather loop
spawn(function()
    while true do
        wait(1)
        TimeUntilWeatherChange = TimeUntilWeatherChange - 1
        
        if TimeUntilWeatherChange <= 0 then
            local newWeather = SelectWeather()
            ApplyWeather(newWeather)
            UpdateWeatherLabel()
            TimeUntilWeatherChange = Config.WeatherChangeInterval
        end
        
        if WeatherDuration > 0 then
            WeatherDuration = WeatherDuration - 1
            if WeatherDuration <= 0 then
                ApplyWeather("Clear")
                UpdateWeatherLabel()
            end
        end
    end
end)

-- Initialize
ApplyWeather("Clear")
UpdateWeatherLabel()
UpdateShop()
ShowNotification("🎮 Pet System with Weather Loaded!")
print("Pet System with Weather loaded successfully! Mobile Optimized: " .. tostring(isMobile))
