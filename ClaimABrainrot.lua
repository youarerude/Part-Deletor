-- Claim a Brainrot Game Script
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Player Data
local playerMoney = 80
local ownedBrainrots = {}
local passiveIncome = 0
local maxBrainrots = 10
local rebirthLevel = 0
local luckMultiplier = 1
local legendaryPity = 0
local mythicalPity = 0
local superPity = 0

-- Brainrot Database
local brainrotData = {
	-- Common
	{name = "Alligarto Alligarto", rarity = "Common", income = 2, cost = 30, chance = 1/2, requiredRebirth = 0},
	{name = "lirili larila", rarity = "Common", income = 4, cost = 52, chance = 1/2.2, requiredRebirth = 0},
	{name = "Fluri Flura", rarity = "Common", income = 6, cost = 75, chance = 1/3, requiredRebirth = 0},
	{name = "Applino Chickinino", rarity = "Common", income = 9, cost = 100, chance = 1/4, requiredRebirth = 0},
	{name = "Cappuccino Assassino", rarity = "Common", income = 12, cost = 125, chance = 1/5, requiredRebirth = 0},
	-- Uncommon
	{name = "Chimpazini Bananini", rarity = "Uncommon", income = 20, cost = 300, chance = 1/12, requiredRebirth = 0},
	{name = "Carloo", rarity = "Uncommon", income = 25, cost = 410, chance = 1/14, requiredRebirth = 0},
	{name = "Boneca Ambalabu", rarity = "Uncommon", income = 30, cost = 530, chance = 1/17, requiredRebirth = 0},
	{name = "Pop Pop Pop Sahur", rarity = "Uncommon", income = 42, cost = 750, chance = 1/18, requiredRebirth = 0},
	-- Rare
	{name = "Brr Brr Patapim", rarity = "Rare", income = 75, cost = 1000, chance = 1/37, requiredRebirth = 0},
	{name = "Brr Es Patipum", rarity = "Rare", income = 100, cost = 1500, chance = 1/38, requiredRebirth = 0},
	{name = "Tung Tung Tung Sahur", rarity = "Rare", income = 150, cost = 2450, chance = 1/39, requiredRebirth = 0},
	{name = "Cocofanto Elefanto", rarity = "Rare", income = 300, cost = 5000, chance = 1/41, requiredRebirth = 0},
	-- Epic
	{name = "Antonio", rarity = "Epic", income = 800, cost = 9500, chance = 1/75, requiredRebirth = 0},
	{name = "Alessio", rarity = "Epic", income = 1000, cost = 12000, chance = 1/77, requiredRebirth = 0},
	{name = "To To To Sahur", rarity = "Epic", income = 2300, cost = 15000, chance = 1/78, requiredRebirth = 0},
	{name = "Tralalero Tralala", rarity = "Epic", income = 5000, cost = 25000, chance = 1/79, requiredRebirth = 0},
	{name = "Ballerina Cappucina", rarity = "Epic", income = 7500, cost = 30000, chance = 1/80, requiredRebirth = 0},
	-- Legendary
	{name = "Apipipipi", rarity = "Legendary", income = 15000, cost = 100000, chance = 1/141, requiredRebirth = 0},
	{name = "Bombardillo Crocodilo", rarity = "Legendary", income = 20000, cost = 175000, chance = 1/142, requiredRebirth = 0},
	{name = "Bombombini Gusini", rarity = "Legendary", income = 34000, cost = 210000, chance = 1/143, requiredRebirth = 0},
	{name = "Rhino Toasterino", rarity = "Legendary", income = 50000, cost = 288000, chance = 1/145, requiredRebirth = 0},
	-- Mythical
	{name = "Ale Zajebiste Tyskie", rarity = "Mythical", income = 100000, cost = 757000, chance = 1/289, requiredRebirth = 0},
	{name = "Aduh 9 April Udah Dekat", rarity = "Mythical", income = 250000, cost = 888001, chance = 1/290, requiredRebirth = 0},
	{name = "Ti Ti Ti Sahur", rarity = "Mythical", income = 300000, cost = 1000000, chance = 1/291, requiredRebirth = 0},
	{name = "Ballerina Lololo", rarity = "Mythical", income = 540000, cost = 1250000, chance = 1/295, requiredRebirth = 0},
	{name = "Tang Tang Kelentang", rarity = "Mythical", income = 720500, cost = 2500750, chance = 1/300, requiredRebirth = 0},
	{name = "Los Tralaleritos", rarity = "Mythical", income = 4500450, cost = 5000100, chance = 1/350, requiredRebirth = 1},
	{name = "Espresso Signora", rarity = "Mythical", income = 7500450, cost = 7000011, chance = 0, requiredRebirth = 0},
	{name = "Dug Dug Dug", rarity = "Mythical", income = 600000, cost = 20000000, chance = 0, requiredRebirth = 0},
	-- Super
	{name = "La Esok Sekolah", rarity = "Super", income = 5450123, cost = 10500000, chance = 1/750, requiredRebirth = 0},
	{name = "Matteo", rarity = "Super", income = 7000000, cost = 12472999, chance = 1/755, requiredRebirth = 0},
	{name = "Pakrahmatmamat", rarity = "Super", income = 9555677, cost = 15500200, chance = 1/755, requiredRebirth = 0},
	{name = "La Vacca Staturno Saturnita", rarity = "Super", income = 11400750, cost = 19760000, chance = 1/760, requiredRebirth = 0},
	{name = "Anpalibabel", rarity = "Super", income = 19500500, cost = 29200475, chance = 1/767, requiredRebirth = 0},
	{name = "Ta Ta Ta Sahur", rarity = "Super", income = 71400200, cost = 23572888, chance = 1/770, requiredRebirth = 0},
	{name = "Te Te Te Sahur", rarity = "Super", income = 89000750, cost = 30555755, chance = 1/799, requiredRebirth = 2},
	{name = "Guerriro Digitale", rarity = "Super", income = 80400571, cost = 27777777, chance = 1/780, requiredRebirth = 0},
	-- MEGA
	{name = "Udin Din Din Din", rarity = "MEGA", income = 100000000, cost = 70200444, chance = 1/1200, requiredRebirth = 0},
	{name = "Cek Cek Satu Dua Tiga Sahur", rarity = "MEGA", income = 145000000, cost = 95300200, chance = 1/1205, requiredRebirth = 0},
	{name = "La Cucaracha", rarity = "MEGA", income = 230759999, cost = 120800000, chance = 1/1210, requiredRebirth = 0},
	{name = "Karkerkar KurKur", rarity = "MEGA", income = 450000000, cost = 214528752, chance = 1/1215, requiredRebirth = 0},
	{name = "Garamararam dan Madudungdung", rarity = "MEGA", income = 785999750, cost = 444200154, chance = 1/1235, requiredRebirth = 0},
	{name = "Los TungTungTungCitos", rarity = "MEGA", income = 1000000000, cost = 889999650, chance = 1/1275, requiredRebirth = 4},
	{name = "Tic Tac Tic Tac Sahur", rarity = "MEGA", income = 660028000, cost = 25000000, chance = 0, requiredRebirth = 0},
	-- CHROMATIC
	{name = "Shampoto Y Finecatonomo", rarity = "CHROMATIC", income = 5400750382, cost = 888888888, chance = 1/3000, requiredRebirth = 0},
	{name = "Chicletera Bicicletera", rarity = "CHROMATIC", income = 8200250750, cost = 1000000000, chance = 1/3010, requiredRebirth = 0},
	{name = "Spaghetti Tuelleti", rarity = "CHROMATIC", income = 10000000000, cost = 3450235100, chance = 1/3020, requiredRebirth = 0},
	{name = "Job Job Job Sahur", rarity = "CHROMATIC", income = 14500000000, cost = 6750000000, chance = 1/3030, requiredRebirth = 0},
	{name = "SIX SEVEN", rarity = "CHROMATIC", income = 19999999999, cost = 9999999999, chance = 1/3075, requiredRebirth = 0},
	{name = "Ketupat Kepat Prekupat", rarity = "CHROMATIC", income = 24000000300, cost = 11000000000, chance = 1/3090, requiredRebirth = 6},
	{name = "Burr Sprite Patipam", rarity = "CHROMATIC", income = 30000000000, cost = 15000000000, chance = 1/3100, requiredRebirth = 6},
	{name = "Los Bros", rarity = "CHROMATIC", income = 28000000550, cost = 9700555272, chance = 0, requiredRebirth = 0},
	{name = "Cha Che Chi", rarity = "CHROMATIC", income = 45000000075, cost = 17500000000, chance = 0, requiredRebirth = 0},
	-- GODLY
	{name = "Banh Mi Ram Ram", rarity = "GODLY", income = 64000000000, cost = 23000000000, chance = 1/7500, requiredRebirth = 0},
	{name = "Pot Hotspot", rarity = "GODLY", income = 99999999999, cost = 47100000000, chance = 1/7520, requiredRebirth = 0},
	{name = "Las Tralaleritas", rarity = "GODLY", income = 154300000075, cost = 81000000777, chance = 1/7540, requiredRebirth = 0},
	{name = "La Vacca Blackhole Goat", rarity = "GODLY", income = 303000101111, cost = 111111111111, chance = 1/7560, requiredRebirth = 0},
	{name = "Il Mastodontico Telepiedone", rarity = "GODLY", income = 720500120778, cost = 420300000001, chance = 1/7580, requiredRebirth = 0},
	{name = "La Grande Combinassion", rarity = "GODLY", income = 1000000000000, cost = 1000000000000, chance = 0, requiredRebirth = 0},
	{name = "Ketchuru and Masturu", rarity = "GODLY", income = 3500000200000, cost = 1000000000000, chance = 1/7620, requiredRebirth = 0},
	{name = "Los La Grande Combinassion", rarity = "GODLY", income = 7500000000000, cost = 3303303303303, chance = 1/7790, requiredRebirth = 5},
	{name = "La Sahur Combinassion", rarity = "GODLY", income = 95050550000000, cost = 75000000000000, chance = 0, requiredRebirth = 0}
}

-- Rarity Colors (for borders)
local rarityColors = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(85, 255, 85),
	Rare = Color3.fromRGB(85, 170, 255),
	Epic = Color3.fromRGB(170, 85, 255),
	Legendary = Color3.fromRGB(255, 215, 0),
	Mythical = Color3.fromRGB(255, 0, 0),
	Super = Color3.fromRGB(0, 255, 255),
	MEGA = Color3.fromRGB(128, 0, 0),
	CHROMATIC = Color3.fromRGB(255, 255, 255),
	GODLY = Color3.fromRGB(255, 215, 0)
}

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotGame"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Money Display
local moneyFrame = Instance.new("Frame")
moneyFrame.Size = UDim2.new(0, 200, 0, 60)
moneyFrame.Position = UDim2.new(0, 10, 0, 10)
moneyFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
moneyFrame.BorderSizePixel = 0
moneyFrame.ZIndex = 2
moneyFrame.Parent = screenGui

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(1, 0, 0.5, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "$" .. playerMoney
moneyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
moneyLabel.TextScaled = true
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.ZIndex = 2
moneyLabel.Parent = moneyFrame

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Size = UDim2.new(1, 0, 0.5, 0)
incomeLabel.Position = UDim2.new(0, 0, 0.5, 0)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "+" .. passiveIncome .. "$/s"
incomeLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
incomeLabel.TextSize = 14
incomeLabel.Font = Enum.Font.Gotham
incomeLabel.ZIndex = 2
incomeLabel.Parent = moneyFrame

-- Inventory Button
local inventoryButton = Instance.new("TextButton")
inventoryButton.Size = UDim2.new(0, 120, 0, 40)
inventoryButton.Position = UDim2.new(0, 10, 0, 80)
inventoryButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
inventoryButton.BorderSizePixel = 0
inventoryButton.Text = "📦 INVENTORY"
inventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
inventoryButton.TextSize = 14
inventoryButton.Font = Enum.Font.GothamBold
inventoryButton.ZIndex = 2
inventoryButton.Parent = screenGui

-- Rebirth Button
local rebirthButton = Instance.new("TextButton")
rebirthButton.Size = UDim2.new(0, 120, 0, 40)
rebirthButton.Position = UDim2.new(0, 140, 0, 80)
rebirthButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
rebirthButton.BorderSizePixel = 0
rebirthButton.Text = "🔄 REBIRTH"
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextSize = 14
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.ZIndex = 2
rebirthButton.Parent = screenGui

-- Fuse Button
local fuseButton = Instance.new("TextButton")
fuseButton.Size = UDim2.new(0, 120, 0, 40)
fuseButton.Position = UDim2.new(0, 270, 0, 80)
fuseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
fuseButton.BorderSizePixel = 0
fuseButton.Text = "🔥 FUSE"
fuseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
fuseButton.TextSize = 14
fuseButton.Font = Enum.Font.GothamBold
fuseButton.ZIndex = 2
fuseButton.Parent = screenGui

-- Admin Button
local adminButton = Instance.new("TextButton")
adminButton.Size = UDim2.new(0, 120, 0, 40)
adminButton.Position = UDim2.new(0, 400, 0, 80)
adminButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
adminButton.BorderSizePixel = 0
adminButton.Text = "🛠 ADMIN"
adminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
adminButton.TextSize = 14
adminButton.Font = Enum.Font.GothamBold
adminButton.ZIndex = 2
adminButton.Parent = screenGui

-- Inventory Frame
local inventoryFrame = Instance.new("Frame")
inventoryFrame.Size = UDim2.new(0, 400, 0, 500)
inventoryFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
inventoryFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
inventoryFrame.BorderSizePixel = 2
inventoryFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
inventoryFrame.Visible = false
inventoryFrame.ZIndex = 5
inventoryFrame.Parent = screenGui

local inventoryTitle = Instance.new("TextLabel")
inventoryTitle.Size = UDim2.new(1, 0, 0, 40)
inventoryTitle.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
inventoryTitle.BorderSizePixel = 0
inventoryTitle.Text = "📦 MY BRAINROTS"
inventoryTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
inventoryTitle.TextSize = 18
inventoryTitle.Font = Enum.Font.GothamBold
inventoryTitle.ZIndex = 6
inventoryTitle.Parent = inventoryFrame

local inventoryCount = Instance.new("TextLabel")
inventoryCount.Size = UDim2.new(0, 80, 0, 25)
inventoryCount.Position = UDim2.new(1, -90, 0, 45)
inventoryCount.BackgroundTransparency = 1
inventoryCount.Text = "0/" .. maxBrainrots
inventoryCount.TextColor3 = Color3.fromRGB(255, 215, 0)
inventoryCount.TextSize = 14
inventoryCount.Font = Enum.Font.GothamBold
inventoryCount.ZIndex = 6
inventoryCount.Parent = inventoryFrame

local closeInventoryButton = Instance.new("TextButton")
closeInventoryButton.Size = UDim2.new(0, 30, 0, 30)
closeInventoryButton.Position = UDim2.new(1, -35, 0, 5)
closeInventoryButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
closeInventoryButton.BorderSizePixel = 0
closeInventoryButton.Text = "X"
closeInventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeInventoryButton.TextSize = 18
closeInventoryButton.Font = Enum.Font.GothamBold
closeInventoryButton.ZIndex = 6
closeInventoryButton.Parent = inventoryFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -80)
scrollFrame.Position = UDim2.new(0, 10, 0, 70)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ZIndex = 6
scrollFrame.Parent = inventoryFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollFrame

-- Rebirth Frame
local rebirthFrame = Instance.new("Frame")
rebirthFrame.Size = UDim2.new(0, 400, 0, 500)
rebirthFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
rebirthFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
rebirthFrame.BorderSizePixel = 2
rebirthFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
rebirthFrame.Visible = false
rebirthFrame.ZIndex = 5
rebirthFrame.Parent = screenGui

local rebirthTitle = Instance.new("TextLabel")
rebirthTitle.Size = UDim2.new(1, 0, 0, 40)
rebirthTitle.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
rebirthTitle.BorderSizePixel = 0
rebirthTitle.Text = "🔄 REBIRTH SYSTEM"
rebirthTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthTitle.TextSize = 18
rebirthTitle.Font = Enum.Font.GothamBold
rebirthTitle.ZIndex = 6
rebirthTitle.Parent = rebirthFrame

local closeRebirthButton = Instance.new("TextButton")
closeRebirthButton.Size = UDim2.new(0, 30, 0, 30)
closeRebirthButton.Position = UDim2.new(1, -35, 0, 5)
closeRebirthButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
closeRebirthButton.BorderSizePixel = 0
closeRebirthButton.Text = "X"
closeRebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeRebirthButton.TextSize = 18
closeRebirthButton.Font = Enum.Font.GothamBold
closeRebirthButton.ZIndex = 6
closeRebirthButton.Parent = rebirthFrame

local currentRebirthLabel = Instance.new("TextLabel")
currentRebirthLabel.Size = UDim2.new(0.9, 0, 0, 30)
currentRebirthLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
currentRebirthLabel.BackgroundTransparency = 1
currentRebirthLabel.Text = "Current Rebirth: 0"
currentRebirthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
currentRebirthLabel.TextSize = 16
currentRebirthLabel.Font = Enum.Font.GothamBold
currentRebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
currentRebirthLabel.ZIndex = 6
currentRebirthLabel.Parent = rebirthFrame

local nextRebirthTitle = Instance.new("TextLabel")
nextRebirthTitle.Size = UDim2.new(0.9, 0, 0, 30)
nextRebirthTitle.Position = UDim2.new(0.05, 0, 0.2, 0)
nextRebirthTitle.BackgroundTransparency = 1
nextRebirthTitle.Text = "Next Rebirth: 1"
nextRebirthTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
nextRebirthTitle.TextSize = 16
nextRebirthTitle.Font = Enum.Font.GothamBold
nextRebirthTitle.TextXAlignment = Enum.TextXAlignment.Left
nextRebirthTitle.ZIndex = 6
nextRebirthTitle.Parent = rebirthFrame

local perksLabel = Instance.new("TextLabel")
perksLabel.Size = UDim2.new(0.9, 0, 0, 100)
perksLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
perksLabel.BackgroundTransparency = 1
perksLabel.Text = "Perks:"
perksLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
perksLabel.TextSize = 14
perksLabel.Font = Enum.Font.Gotham
perksLabel.TextXAlignment = Enum.TextXAlignment.Left
perksLabel.TextWrapped = true
perksLabel.ZIndex = 6
perksLabel.Parent = rebirthFrame

local reqLabel = Instance.new("TextLabel")
reqLabel.Size = UDim2.new(0.9, 0, 0, 100)
reqLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
reqLabel.BackgroundTransparency = 1
reqLabel.Text = "Requirements:"
reqLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
reqLabel.TextSize = 14
reqLabel.Font = Enum.Font.Gotham
reqLabel.TextXAlignment = Enum.TextXAlignment.Left
reqLabel.TextWrapped = true
reqLabel.ZIndex = 6
reqLabel.Parent = rebirthFrame

local doRebirthButton = Instance.new("TextButton")
doRebirthButton.Size = UDim2.new(0.4, 0, 0, 40)
doRebirthButton.Position = UDim2.new(0.3, 0, 0.8, 0)
doRebirthButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
doRebirthButton.BorderSizePixel = 0
doRebirthButton.Text = "NOT READY"
doRebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
doRebirthButton.TextSize = 16
doRebirthButton.Font = Enum.Font.GothamBold
doRebirthButton.ZIndex = 6
doRebirthButton.Parent = rebirthFrame

-- Fuse Frame
local fuseFrame = Instance.new("Frame")
fuseFrame.Size = UDim2.new(0, 400, 0, 500)
fuseFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
fuseFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
fuseFrame.BorderSizePixel = 2
fuseFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
fuseFrame.Visible = false
fuseFrame.ZIndex = 5
fuseFrame.Parent = screenGui

local fuseTitle = Instance.new("TextLabel")
fuseTitle.Size = UDim2.new(1, 0, 0, 40)
fuseTitle.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
fuseTitle.BorderSizePixel = 0
fuseTitle.Text = "🔥 FUSE BRAINROTS"
fuseTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
fuseTitle.TextSize = 18
fuseTitle.Font = Enum.Font.GothamBold
fuseTitle.ZIndex = 6
fuseTitle.Parent = fuseFrame

local closeFuseButton = Instance.new("TextButton")
closeFuseButton.Size = UDim2.new(0, 30, 0, 30)
closeFuseButton.Position = UDim2.new(1, -35, 0, 5)
closeFuseButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
closeFuseButton.BorderSizePixel = 0
closeFuseButton.Text = "X"
closeFuseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeFuseButton.TextSize = 18
closeFuseButton.Font = Enum.Font.GothamBold
closeFuseButton.ZIndex = 6
closeFuseButton.Parent = fuseFrame

local fuseScrollFrame = Instance.new("ScrollingFrame")
fuseScrollFrame.Size = UDim2.new(1, -20, 1, -40)
fuseScrollFrame.Position = UDim2.new(0, 10, 0, 40)
fuseScrollFrame.BackgroundTransparency = 1
fuseScrollFrame.BorderSizePixel = 0
fuseScrollFrame.ScrollBarThickness = 6
fuseScrollFrame.ZIndex = 6
fuseScrollFrame.Parent = fuseFrame

local fuseListLayout = Instance.new("UIListLayout")
fuseListLayout.Padding = UDim.new(0, 5)
fuseListLayout.Parent = fuseScrollFrame

-- Function to update fuse display
local function updateFuseFrame()
	for _, child in ipairs(fuseScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, fusion in ipairs(fusionData) do
		local rowFrame = Instance.new("Frame")
		rowFrame.Size = UDim2.new(1, 0, 0, 100)
		rowFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		rowFrame.BorderSizePixel = 1
		rowFrame.BorderColor3 = rarityColors[fusion.rarity]
		rowFrame.ZIndex = 7
		rowFrame.Parent = fuseScrollFrame
		
		addRarityGradient(rowFrame, fusion.rarity)
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -10, 0, 20)
		nameLabel.Position = UDim2.new(0, 5, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = fusion.result
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 8
		nameLabel.Parent = rowFrame
		
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(1, -10, 0, 18)
		rarityLabel.Position = UDim2.new(0, 5, 0, 25)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Text = fusion.rarity
		rarityLabel.TextColor3 = rarityColors[fusion.rarity]
		rarityLabel.TextSize = 12
		rarityLabel.Font = Enum.Font.GothamBold
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
		rarityLabel.ZIndex = 8
		rarityLabel.Parent = rowFrame
		
		local costText = Instance.new("TextLabel")
		costText.Size = UDim2.new(1, -10, 0, 18)
		costText.Position = UDim2.new(0, 5, 0, 43)
		costText.BackgroundTransparency = 1
		costText.Text = "Cost: $" .. fusion.cost
		costText.TextColor3 = Color3.fromRGB(255, 215, 0)
		costText.TextSize = 12
		costText.Font = Enum.Font.Gotham
		costText.TextXAlignment = Enum.TextXAlignment.Left
		costText.ZIndex = 8
		costText.Parent = rowFrame
		
		local reqStr = {}
		for _, r in ipairs(fusion.requirements) do
			table.insert(reqStr, r[2] .. " " .. r[1])
		end
		local reqText = Instance.new("TextLabel")
		reqText.Size = UDim2.new(1, -10, 0, 18)
		reqText.Position = UDim2.new(0, 5, 0, 61)
		reqText.BackgroundTransparency = 1
		reqText.Text = "Requirements: " .. table.concat(reqStr, ", ")
		reqText.TextColor3 = Color3.fromRGB(255, 255, 255)
		reqText.TextSize = 12
		reqText.Font = Enum.Font.Gotham
		reqText.TextXAlignment = Enum.TextXAlignment.Left
		reqText.TextWrapped = true
		reqText.ZIndex = 8
		reqText.Parent = rowFrame
		
		local fuseBtn = Instance.new("TextButton")
		fuseBtn.Size = UDim2.new(0, 80, 0, 30)
		fuseBtn.Position = UDim2.new(1, -90, 0, 65)
		fuseBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
		fuseBtn.BorderSizePixel = 0
		fuseBtn.Text = "FUSE"
		fuseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		fuseBtn.TextSize = 14
		fuseBtn.Font = Enum.Font.GothamBold
		fuseBtn.ZIndex = 8
		fuseBtn.Parent = rowFrame
		
		local canFuse = playerMoney >= fusion.cost
		for _, req in ipairs(fusion.requirements) do
			if countBrainrot(req[1]) < req[2] then
				canFuse = false
				break
			end
		end
		if canFuse then
			fuseBtn.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
		end
		
		fuseBtn.MouseButton1Click:Connect(function()
			local canFuse = playerMoney >= fusion.cost
			for _, req in ipairs(fusion.requirements) do
				if countBrainrot(req[1]) < req[2] then
					canFuse = false
					break
				end
			end
			if canFuse then
				playerMoney = playerMoney - fusion.cost
				moneyLabel.Text = "$" .. playerMoney
				for _, req in ipairs(fusion.requirements) do
					local toRemove = req[2]
					for j = #ownedBrainrots, 1, -1 do
						if ownedBrainrots[j].name == req[1] and toRemove > 0 then
							passiveIncome = passiveIncome - ownedBrainrots[j].income
							table.remove(ownedBrainrots, j)
							toRemove = toRemove - 1
						end
					end
				end
				table.insert(ownedBrainrots, {
					name = fusion.result,
					rarity = fusion.rarity,
					income = fusion.income,
					cost = fusion.cost
				})
				passiveIncome = passiveIncome + fusion.income
				incomeLabel.Text = "+" .. passiveIncome .. "$/s"
				updateInventory()
				updateFuseFrame()
			end
		end)
	end
	
	fuseScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #fusionData * 105)
end

-- Toggle Fuse
fuseButton.MouseButton1Click:Connect(function()
	updateFuseFrame()
	fuseFrame.Visible = not fuseFrame.Visible
end)

closeFuseButton.MouseButton1Click:Connect(function()
	fuseFrame.Visible = false
end)

-- Admin Frame
local adminFrame = Instance.new("Frame")
adminFrame.Size = UDim2.new(0, 400, 0, 500)
adminFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
adminFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
adminFrame.BorderSizePixel = 2
adminFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
adminFrame.Visible = false
adminFrame.ZIndex = 5
adminFrame.Parent = screenGui

local adminTitle = Instance.new("TextLabel")
adminTitle.Size = UDim2.new(1, 0, 0, 40)
adminTitle.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
adminTitle.BorderSizePixel = 0
adminTitle.Text = "🛠 ADMIN PANEL"
adminTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
adminTitle.TextSize = 18
adminTitle.Font = Enum.Font.GothamBold
adminTitle.ZIndex = 6
adminTitle.Parent = adminFrame

local closeAdminButton = Instance.new("TextButton")
closeAdminButton.Size = UDim2.new(0, 30, 0, 30)
closeAdminButton.Position = UDim2.new(1, -35, 0, 5)
closeAdminButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
closeAdminButton.BorderSizePixel = 0
closeAdminButton.Text = "X"
closeAdminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeAdminButton.TextSize = 18
closeAdminButton.Font = Enum.Font.GothamBold
closeAdminButton.ZIndex = 6
closeAdminButton.Parent = adminFrame

local adminScrollFrame = Instance.new("ScrollingFrame")
adminScrollFrame.Size = UDim2.new(1, -20, 1, -40)
adminScrollFrame.Position = UDim2.new(0, 10, 0, 40)
adminScrollFrame.BackgroundTransparency = 1
adminScrollFrame.BorderSizePixel = 0
adminScrollFrame.ScrollBarThickness = 6
adminScrollFrame.ZIndex = 6
adminScrollFrame.Parent = adminFrame

local adminListLayout = Instance.new("UIListLayout")
adminListLayout.Padding = UDim.new(0, 10)
adminListLayout.Parent = adminScrollFrame

-- Collect unique rarities and brainrot names
local rarities = {}
local seen_rarity = {}
local brainrotNames = {}
for _, br in ipairs(brainrotData) do
	if not seen_rarity[br.rarity] then
		table.insert(rarities, br.rarity)
		seen_rarity[br.rarity] = true
	end
	table.insert(brainrotNames, br.name)
end

-- Set Coin
local setCoinRow = Instance.new("Frame")
setCoinRow.Size = UDim2.new(1, 0, 0, 40)
setCoinRow.BackgroundTransparency = 1
setCoinRow.ZIndex = 6
setCoinRow.Parent = adminScrollFrame

local setCoinLabel = Instance.new("TextLabel")
setCoinLabel.Size = UDim2.new(0.3, 0, 1, 0)
setCoinLabel.BackgroundTransparency = 1
setCoinLabel.Text = "Set Coin:"
setCoinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
setCoinLabel.TextSize = 14
setCoinLabel.Font = Enum.Font.Gotham
setCoinLabel.TextXAlignment = Enum.TextXAlignment.Left
setCoinLabel.ZIndex = 6
setCoinLabel.Parent = setCoinRow

local setCoinTextBox = Instance.new("TextBox")
setCoinTextBox.Size = UDim2.new(0.4, 0, 1, 0)
setCoinTextBox.Position = UDim2.new(0.3, 0, 0, 0)
setCoinTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
setCoinTextBox.BorderSizePixel = 0
setCoinTextBox.Text = ""
setCoinTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
setCoinTextBox.TextSize = 14
setCoinTextBox.Font = Enum.Font.Gotham
setCoinTextBox.ZIndex = 6
setCoinTextBox.Parent = setCoinRow

local setCoinButton = Instance.new("TextButton")
setCoinButton.Size = UDim2.new(0.3, 0, 1, 0)
setCoinButton.Position = UDim2.new(0.7, 0, 0, 0)
setCoinButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
setCoinButton.BorderSizePixel = 0
setCoinButton.Text = "Apply"
setCoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
setCoinButton.TextSize = 14
setCoinButton.Font = Enum.Font.GothamBold
setCoinButton.ZIndex = 6
setCoinButton.Parent = setCoinRow

setCoinButton.MouseButton1Click:Connect(function()
    local num = tonumber(setCoinTextBox.Text)
    if num then
        playerMoney = num
        moneyLabel.Text = "$" .. playerMoney
    end
end)

-- Spawn Random Rarity Dropdown and Button
local spawnRandomRarityRow = Instance.new("Frame")
spawnRandomRarityRow.Size = UDim2.new(1, 0, 0, 40)
spawnRandomRarityRow.BackgroundTransparency = 1
spawnRandomRarityRow.ZIndex = 6
spawnRandomRarityRow.Parent = adminScrollFrame

local selectedRarity = rarities[1]

local rarityDropdownButton = Instance.new("TextButton")
rarityDropdownButton.Size = UDim2.new(0.5, 0, 1, 0)
rarityDropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
rarityDropdownButton.BorderSizePixel = 0
rarityDropdownButton.Text = "Rarity: " .. selectedRarity
rarityDropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rarityDropdownButton.TextSize = 14
rarityDropdownButton.Font = Enum.Font.Gotham
rarityDropdownButton.ZIndex = 6
rarityDropdownButton.Parent = spawnRandomRarityRow

local spawnRandomRarityButton = Instance.new("TextButton")
spawnRandomRarityButton.Size = UDim2.new(0.5, 0, 1, 0)
spawnRandomRarityButton.Position = UDim2.new(0.5, 0, 0, 0)
spawnRandomRarityButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
spawnRandomRarityButton.BorderSizePixel = 0
spawnRandomRarityButton.Text = "Spawn Random Rarity"
spawnRandomRarityButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnRandomRarityButton.TextSize = 14
spawnRandomRarityButton.Font = Enum.Font.GothamBold
spawnRandomRarityButton.ZIndex = 6
spawnRandomRarityButton.Parent = spawnRandomRarityRow

local rarityListFrame = Instance.new("ScrollingFrame")
rarityListFrame.Size = UDim2.new(0.5, 0, 0, 200)
rarityListFrame.Position = UDim2.new(0, 0, 1, 0)
rarityListFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
rarityListFrame.BorderSizePixel = 0
rarityListFrame.ScrollBarThickness = 6
rarityListFrame.Visible = false
rarityListFrame.ZIndex = 10
rarityListFrame.Parent = spawnRandomRarityRow

local rarityListLayout = Instance.new("UIListLayout")
rarityListLayout.Padding = UDim.new(0, 5)
rarityListLayout.Parent = rarityListFrame

for _, rarity in ipairs(rarities) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.Text = rarity
    btn.TextColor3 = rarityColors[rarity] or Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.Gotham
    btn.ZIndex = 11
    btn.Parent = rarityListFrame

    btn.MouseButton1Click:Connect(function()
        selectedRarity = rarity
        rarityDropdownButton.Text = "Rarity: " .. rarity
        rarityListFrame.Visible = false
    end)
end

rarityListFrame.CanvasSize = UDim2.new(0, 0, 0, #rarities * 35)

rarityDropdownButton.MouseButton1Click:Connect(function()
    rarityListFrame.Visible = not rarityListFrame.Visible
end)

spawnRandomRarityButton.MouseButton1Click:Connect(function()
    local pool = {}
    for _, br in ipairs(brainrotData) do
        if br.rarity == selectedRarity and (br.requiredRebirth or 0) <= rebirthLevel then
            table.insert(pool, br)
        end
    end
    if #pool > 0 then
        local randomBr = pool[math.random(1, #pool)]
        createBrainrotCard(randomBr)
    end
end)

-- Spawn Any Random Rarity Button
local spawnAnyRandomRow = Instance.new("Frame")
spawnAnyRandomRow.Size = UDim2.new(1, 0, 0, 40)
spawnAnyRandomRow.BackgroundTransparency = 1
spawnAnyRandomRow.ZIndex = 6
spawnAnyRandomRow.Parent = adminScrollFrame

local spawnAnyRandomButton = Instance.new("TextButton")
spawnAnyRandomButton.Size = UDim2.new(1, 0, 1, 0)
spawnAnyRandomButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
spawnAnyRandomButton.BorderSizePixel = 0
spawnAnyRandomButton.Text = "Spawn Random Any Rarity"
spawnAnyRandomButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnAnyRandomButton.TextSize = 14
spawnAnyRandomButton.Font = Enum.Font.GothamBold
spawnAnyRandomButton.ZIndex = 6
spawnAnyRandomButton.Parent = spawnAnyRandomRow

spawnAnyRandomButton.MouseButton1Click:Connect(function()
    local brainrot = selectRandomBrainrot()
    createBrainrotCard(brainrot)
    updatePityLabels()
end)

-- Spawn Specific Brainrot
local spawnBrainrotRow = Instance.new("Frame")
spawnBrainrotRow.Size = UDim2.new(1, 0, 0, 40)
spawnBrainrotRow.BackgroundTransparency = 1
spawnBrainrotRow.ZIndex = 6
spawnBrainrotRow.Parent = adminScrollFrame

local selectedSpawnBrainrot = brainrotNames[1]

local brainrotDropdownButton = Instance.new("TextButton")
brainrotDropdownButton.Size = UDim2.new(0.5, 0, 1, 0)
brainrotDropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
brainrotDropdownButton.BorderSizePixel = 0
brainrotDropdownButton.Text = "Brainrot: " .. selectedSpawnBrainrot
brainrotDropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
brainrotDropdownButton.TextSize = 14
brainrotDropdownButton.Font = Enum.Font.Gotham
brainrotDropdownButton.TextTruncate = Enum.TextTruncate.SplitWord
brainrotDropdownButton.ZIndex = 6
brainrotDropdownButton.Parent = spawnBrainrotRow

local spawnBrainrotButton = Instance.new("TextButton")
spawnBrainrotButton.Size = UDim2.new(0.5, 0, 1, 0)
spawnBrainrotButton.Position = UDim2.new(0.5, 0, 0, 0)
spawnBrainrotButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
spawnBrainrotButton.BorderSizePixel = 0
spawnBrainrotButton.Text = "Spawn Brainrot"
spawnBrainrotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnBrainrotButton.TextSize = 14
spawnBrainrotButton.Font = Enum.Font.GothamBold
spawnBrainrotButton.ZIndex = 6
spawnBrainrotButton.Parent = spawnBrainrotRow

local brainrotListFrame = Instance.new("ScrollingFrame")
brainrotListFrame.Size = UDim2.new(0.5, 0, 0, 200)
brainrotListFrame.Position = UDim2.new(0, 0, 1, 0)
brainrotListFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
brainrotListFrame.BorderSizePixel = 0
brainrotListFrame.ScrollBarThickness = 6
brainrotListFrame.Visible = false
brainrotListFrame.ZIndex = 10
brainrotListFrame.Parent = spawnBrainrotRow

local brainrotListLayout = Instance.new("UIListLayout")
brainrotListLayout.Padding = UDim.new(0, 5)
brainrotListLayout.Parent = brainrotListFrame

for _, name in ipairs(brainrotNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.Gotham
    btn.TextTruncate = Enum.TextTruncate.SplitWord
    btn.ZIndex = 11
    btn.Parent = brainrotListFrame

    btn.MouseButton1Click:Connect(function()
        selectedSpawnBrainrot = name
        brainrotDropdownButton.Text = "Brainrot: " .. name
        brainrotListFrame.Visible = false
    end)
end

brainrotListFrame.CanvasSize = UDim2.new(0, 0, 0, #brainrotNames * 35)

brainrotDropdownButton.MouseButton1Click:Connect(function()
    brainrotListFrame.Visible = not brainrotListFrame.Visible
end)

spawnBrainrotButton.MouseButton1Click:Connect(function()
    for _, br in ipairs(brainrotData) do
        if br.name == selectedSpawnBrainrot and (br.requiredRebirth or 0) <= rebirthLevel then
            createBrainrotCard(br)
            break
        end
    end
end)

-- Set Rebirth
local setRebirthRow = Instance.new("Frame")
setRebirthRow.Size = UDim2.new(1, 0, 0, 40)
setRebirthRow.BackgroundTransparency = 1
setRebirthRow.ZIndex = 6
setRebirthRow.Parent = adminScrollFrame

local setRebirthLabel = Instance.new("TextLabel")
setRebirthLabel.Size = UDim2.new(0.3, 0, 1, 0)
setRebirthLabel.BackgroundTransparency = 1
setRebirthLabel.Text = "Set Rebirth (1-6):"
setRebirthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
setRebirthLabel.TextSize = 14
setRebirthLabel.Font = Enum.Font.Gotham
setRebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
setRebirthLabel.ZIndex = 6
setRebirthLabel.Parent = setRebirthRow

local setRebirthTextBox = Instance.new("TextBox")
setRebirthTextBox.Size = UDim2.new(0.4, 0, 1, 0)
setRebirthTextBox.Position = UDim2.new(0.3, 0, 0, 0)
setRebirthTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
setRebirthTextBox.BorderSizePixel = 0
setRebirthTextBox.Text = ""
setRebirthTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
setRebirthTextBox.TextSize = 14
setRebirthTextBox.Font = Enum.Font.Gotham
setRebirthTextBox.ZIndex = 6
setRebirthTextBox.Parent = setRebirthRow

local setRebirthButton = Instance.new("TextButton")
setRebirthButton.Size = UDim2.new(0.3, 0, 1, 0)
setRebirthButton.Position = UDim2.new(0.7, 0, 0, 0)
setRebirthButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
setRebirthButton.BorderSizePixel = 0
setRebirthButton.Text = "Apply"
setRebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
setRebirthButton.TextSize = 14
setRebirthButton.Font = Enum.Font.GothamBold
setRebirthButton.ZIndex = 6
setRebirthButton.Parent = setRebirthRow

setRebirthButton.MouseButton1Click:Connect(function()
    local lvl = tonumber(setRebirthTextBox.Text)
    if lvl and lvl >= 1 and lvl <= 6 then
        rebirthLevel = lvl
        luckMultiplier = 1 + 0.1 * rebirthLevel
        maxBrainrots = (lvl >= 3) and 20 or 10
        updateRebirthFrame()
        inventoryCount.Text = #ownedBrainrots .. "/" .. maxBrainrots
    end
end)

-- Give Brainrot
local giveBrainrotRow = Instance.new("Frame")
giveBrainrotRow.Size = UDim2.new(1, 0, 0, 40)
giveBrainrotRow.BackgroundTransparency = 1
giveBrainrotRow.ZIndex = 6
giveBrainrotRow.Parent = adminScrollFrame

local selectedGiveBrainrot = brainrotNames[1]

local giveDropdownButton = Instance.new("TextButton")
giveDropdownButton.Size = UDim2.new(0.5, 0, 1, 0)
giveDropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
giveDropdownButton.BorderSizePixel = 0
giveDropdownButton.Text = "Give: " .. selectedGiveBrainrot
giveDropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
giveDropdownButton.TextSize = 14
giveDropdownButton.Font = Enum.Font.Gotham
giveDropdownButton.TextTruncate = Enum.TextTruncate.SplitWord
giveDropdownButton.ZIndex = 6
giveDropdownButton.Parent = giveBrainrotRow

local giveBrainrotButton = Instance.new("TextButton")
giveBrainrotButton.Size = UDim2.new(0.5, 0, 1, 0)
giveBrainrotButton.Position = UDim2.new(0.5, 0, 0, 0)
giveBrainrotButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
giveBrainrotButton.BorderSizePixel = 0
giveBrainrotButton.Text = "Give Brainrot"
giveBrainrotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
giveBrainrotButton.TextSize = 14
giveBrainrotButton.Font = Enum.Font.GothamBold
giveBrainrotButton.ZIndex = 6
giveBrainrotButton.Parent = giveBrainrotRow

local giveListFrame = Instance.new("ScrollingFrame")
giveListFrame.Size = UDim2.new(0.5, 0, 0, 200)
giveListFrame.Position = UDim2.new(0, 0, 1, 0)
giveListFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
giveListFrame.BorderSizePixel = 0
giveListFrame.ScrollBarThickness = 6
giveListFrame.Visible = false
giveListFrame.ZIndex = 10
giveListFrame.Parent = giveBrainrotRow

local giveListLayout = Instance.new("UIListLayout")
giveListLayout.Padding = UDim.new(0, 5)
giveListLayout.Parent = giveListFrame

for _, name in ipairs(brainrotNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.Gotham
    btn.TextTruncate = Enum.TextTruncate.SplitWord
    btn.ZIndex = 11
    btn.Parent = giveListFrame

    btn.MouseButton1Click:Connect(function()
        selectedGiveBrainrot = name
        giveDropdownButton.Text = "Give: " .. name
        giveListFrame.Visible = false
    end)
end

giveListFrame.CanvasSize = UDim2.new(0, 0, 0, #brainrotNames * 35)

giveDropdownButton.MouseButton1Click:Connect(function()
    giveListFrame.Visible = not giveListFrame.Visible
end)

giveBrainrotButton.MouseButton1Click:Connect(function()
    if #ownedBrainrots >= maxBrainrots then return end
    for _, br in ipairs(brainrotData) do
        if br.name == selectedGiveBrainrot then
            table.insert(ownedBrainrots, {
                name = br.name,
                rarity = br.rarity,
                income = br.income,
                cost = br.cost
            })
            passiveIncome = passiveIncome + br.income
            updateInventory()
            incomeLabel.Text = "+" .. passiveIncome .. "$/s"
            break
        end
    end
end)

adminScrollFrame.CanvasSize = UDim2.new(0, 0, 0, adminListLayout.AbsoluteContentSize.Y + 20)

-- Pity Display
local pityFrame = Instance.new("Frame")
pityFrame.Size = UDim2.new(0, 200, 0, 75)
pityFrame.Position = UDim2.new(0.5, -100, 0.5, -175)
pityFrame.BackgroundTransparency = 1
pityFrame.ZIndex = 2
pityFrame.Parent = screenGui

local legendaryPityLabel = Instance.new("TextLabel")
legendaryPityLabel.Size = UDim2.new(1, 0, 0.333, 0)
legendaryPityLabel.BackgroundTransparency = 1
legendaryPityLabel.Text = "Legendary Pity: 0/50"
legendaryPityLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
legendaryPityLabel.TextSize = 14
legendaryPityLabel.Font = Enum.Font.Gotham
legendaryPityLabel.ZIndex = 2
legendaryPityLabel.Parent = pityFrame

local mythicalPityLabel = Instance.new("TextLabel")
mythicalPityLabel.Size = UDim2.new(1, 0, 0.333, 0)
mythicalPityLabel.Position = UDim2.new(0, 0, 0.333, 0)
mythicalPityLabel.BackgroundTransparency = 1
mythicalPityLabel.Text = "Mythical Pity: 0/175"
mythicalPityLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
mythicalPityLabel.TextSize = 14
mythicalPityLabel.Font = Enum.Font.Gotham
mythicalPityLabel.ZIndex = 2
mythicalPityLabel.Parent = pityFrame

local superPityLabel = Instance.new("TextLabel")
superPityLabel.Size = UDim2.new(1, 0, 0.333, 0)
superPityLabel.Position = UDim2.new(0, 0, 0.666, 0)
superPityLabel.BackgroundTransparency = 1
superPityLabel.Text = "Super Pity: 0/342"
superPityLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
superPityLabel.TextSize = 14
superPityLabel.Font = Enum.Font.Gotham
superPityLabel.ZIndex = 2
superPityLabel.Parent = pityFrame

local function updatePityLabels()
    legendaryPityLabel.Text = "Legendary Pity: " .. legendaryPity .. "/50"
    mythicalPityLabel.Text = "Mythical Pity: " .. mythicalPity .. "/175"
    superPityLabel.Text = "Super Pity: " .. superPity .. "/342"
end

updatePityLabels()

-- Helper Functions
local function countBrainrot(name)
    local count = 0
    for _, item in ipairs(ownedBrainrots) do
        if item.name == name then
            count = count + 1
        end
    end
    return count
end

-- Update Rebirth Frame
local function updateRebirthFrame()
	currentRebirthLabel.Text = "Current Rebirth: " .. rebirthLevel
	local canRebirth = false
	if rebirthLevel >= 6 then
		nextRebirthTitle.Text = "Max Rebirth Reached"
		perksLabel.Visible = false
		reqLabel.Visible = false
		doRebirthButton.Visible = false
	else
		perksLabel.Visible = true
		reqLabel.Visible = true
		doRebirthButton.Visible = true
		if rebirthLevel == 0 then
			nextRebirthTitle.Text = "Next Rebirth: 1"
			perksLabel.Text = "Perks:\n- 1.1x Luck\n- 300 Starter Money\n- Unlocks Los Tralaleritos"
			reqLabel.Text = "Requirements:\n- Rhino Toasterino\n- Tang Tang Kelentang\n- 10,000,000 Money"
			canRebirth = playerMoney >= 10000000 and countBrainrot("Rhino Toasterino") >= 1 and countBrainrot("Tang Tang Kelentang") >= 1
		elseif rebirthLevel == 1 then
			nextRebirthTitle.Text = "Next Rebirth: 2"
			perksLabel.Text = "Perks:\n- 1.2x Luck\n- 1500 Starter Money\n- Unlocks Te Te Te Sahur"
			reqLabel.Text = "Requirements:\n- 15,000,000,000 Money\n- Anpalibabel\n- Ta Ta Ta Sahur\n- La Vacca Staturno Saturnita"
			canRebirth = playerMoney >= 15000000000 and countBrainrot("Anpalibabel") >= 1 and countBrainrot("Ta Ta Ta Sahur") >= 1 and countBrainrot("La Vacca Staturno Saturnita") >= 1
		elseif rebirthLevel == 2 then
			nextRebirthTitle.Text = "Next Rebirth: 3"
			perksLabel.Text = "Perks:\n- 1.3x Luck\n- Floor 2 (10+ Max Brainrot: 20 Total)\n- 15000 Starter Money"
			reqLabel.Text = "Requirements:\n- 50,000,000,000,000 Money\n- Karkerkar KurKur\n- Garamararam dan Madudungdung"
			canRebirth = playerMoney >= 50000000000000 and countBrainrot("Karkerkar KurKur") >= 1 and countBrainrot("Garamararam dan Madudungdung") >= 1
		elseif rebirthLevel == 3 then
			nextRebirthTitle.Text = "Next Rebirth: 4"
			perksLabel.Text = "Perks:\n- 1.4x Luck\n- 50000 Starter Money\n- Unlocks Los TungTungTungCitos"
			reqLabel.Text = "Requirements:\n- 75,000,000,000,000,000 Money\n- La Cucaracha\n- Chicletera Bicicletera\n- SIX SEVEN"
			canRebirth = playerMoney >= 75000000000000000 and countBrainrot("La Cucaracha") >= 1 and countBrainrot("Chicletera Bicicletera") >= 1 and countBrainrot("SIX SEVEN") >= 1
		elseif rebirthLevel == 4 then
			nextRebirthTitle.Text = "Next Rebirth: 5"
			perksLabel.Text = "Perks:\n- 1.5x Luck\n- 120500 Starter Money\n- Unlocks Los La Grande Combinassion"
			reqLabel.Text = "Requirements:\n- 2 Los TungTungTungCitos\n- 2 Los Tralaleritos\n- 1 Las Tralaleritas\n- 1 Te Te Te Sahur"
			canRebirth = countBrainrot("Los TungTungTungCitos") >= 2 and countBrainrot("Los Tralaleritos") >= 2 and countBrainrot("Las Tralaleritas") >= 1 and countBrainrot("Te Te Te Sahur") >= 1
		elseif rebirthLevel == 5 then
			nextRebirthTitle.Text = "Next Rebirth: 6"
			perksLabel.Text = "Perks:\n- 1.6x Luck\n- Ketupat Kepat Prekupat\n- Burr Sprite Patipam\n- 350200 Starter Money"
			reqLabel.Text = "Requirements:\n- Los La Grande Combinassion\n- 10,000,000,000,000,000,000 Money\n- Ketchuru and Masturu"
			canRebirth = countBrainrot("Los La Grande Combinassion") >= 1 and playerMoney >= 10000000000000000000 and countBrainrot("Ketchuru and Masturu") >= 1
		end
		if canRebirth then
			doRebirthButton.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
			doRebirthButton.Text = "REBIRTH NOW!"
		else
			doRebirthButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
			doRebirthButton.Text = "NOT READY"
		end
	end
end

-- Toggle Inventory
inventoryButton.MouseButton1Click:Connect(function()
	inventoryFrame.Visible = not inventoryFrame.Visible
end)

closeInventoryButton.MouseButton1Click:Connect(function()
	inventoryFrame.Visible = false
end)

-- Toggle Rebirth
rebirthButton.MouseButton1Click:Connect(function()
	updateRebirthFrame()
	rebirthFrame.Visible = not rebirthFrame.Visible
end)

closeRebirthButton.MouseButton1Click:Connect(function()
	rebirthFrame.Visible = false
end)

-- Toggle Fuse
fuseButton.MouseButton1Click:Connect(function()
	updateFuseFrame()
	fuseFrame.Visible = not fuseFrame.Visible
end)

closeFuseButton.MouseButton1Click:Connect(function()
	fuseFrame.Visible = false
end)

-- Toggle Admin
adminButton.MouseButton1Click:Connect(function()
	adminFrame.Visible = not adminFrame.Visible
end)

closeAdminButton.MouseButton1Click:Connect(function()
	adminFrame.Visible = false
end)

-- Perform Rebirth
doRebirthButton.MouseButton1Click:Connect(function()
	local canRebirth = false
	local starterMoneyAmount = 0
	if rebirthLevel == 0 then
		canRebirth = playerMoney >= 10000000 and countBrainrot("Rhino Toasterino") >= 1 and countBrainrot("Tang Tang Kelentang") >= 1
		starterMoneyAmount = 300
	elseif rebirthLevel == 1 then
		canRebirth = playerMoney >= 15000000000 and countBrainrot("Anpalibabel") >= 1 and countBrainrot("Ta Ta Ta Sahur") >= 1 and countBrainrot("La Vacca Staturno Saturnita") >= 1
		starterMoneyAmount = 1500
	elseif rebirthLevel == 2 then
		canRebirth = playerMoney >= 50000000000000 and countBrainrot("Karkerkar KurKur") >= 1 and countBrainrot("Garamararam dan Madudungdung") >= 1
		starterMoneyAmount = 15000
	elseif rebirthLevel == 3 then
		canRebirth = playerMoney >= 75000000000000000 and countBrainrot("La Cucaracha") >= 1 and countBrainrot("Chicletera Bicicletera") >= 1 and countBrainrot("SIX SEVEN") >= 1
		starterMoneyAmount = 50000
	elseif rebirthLevel == 4 then
		canRebirth = countBrainrot("Los TungTungTungCitos") >= 2 and countBrainrot("Los Tralaleritos") >= 2 and countBrainrot("Las Tralaleritas") >= 1 and countBrainrot("Te Te Te Sahur") >= 1
		starterMoneyAmount = 120500
	elseif rebirthLevel == 5 then
		canRebirth = countBrainrot("Los La Grande Combinassion") >= 1 and playerMoney >= 10000000000000000000 and countBrainrot("Ketchuru and Masturu") >= 1
		starterMoneyAmount = 350200
	end
	if canRebirth then
		rebirthLevel = rebirthLevel + 1
		luckMultiplier = 1 + 0.1 * rebirthLevel
		ownedBrainrots = {}
		passiveIncome = 0
		legendaryPity = 0
		mythicalPity = 0
		superPity = 0
		playerMoney = starterMoneyAmount
		if rebirthLevel == 3 then
			maxBrainrots = 20
		end
		moneyLabel.Text = "$" .. playerMoney
		incomeLabel.Text = "+" .. passiveIncome .. "$/s"
		updateInventory()
		updateRebirthFrame()
		rebirthFrame.Visible = false
		updatePityLabels()
	end
end)

-- Function to add gradient based on rarity
local function addRarityGradient(frame, rarity)
	local gradient = Instance.new("UIGradient")
	gradient.Parent = frame
	if rarity == "Mythical" then
		gradient.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 0, 0))
	elseif rarity == "Super" then
		gradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 255), Color3.fromRGB(0, 255, 255))
	elseif rarity == "MEGA" then
		local seq1 = ColorSequence.new(Color3.fromRGB(250, 128, 114), Color3.fromRGB(0, 0, 0))
		local seq2 = ColorSequence.new(Color3.fromRGB(250, 128, 114), Color3.fromRGB(0, 0, 0))
		gradient.Color = seq1
		local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)
		spawn(function()
			while frame.Parent do
				local tween = TweenService:Create(gradient, tweenInfo, {Color = seq2})
				tween:Play()
				tween.Completed:Wait()
				tween = TweenService:Create(gradient, tweenInfo, {Color = seq1})
				tween:Play()
				tween.Completed:Wait()
			end
		end)
	elseif rarity == "CHROMATIC" then
		gradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
		}
		spawn(function()
			while frame.Parent do
				local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Linear)
				local tween = TweenService:Create(gradient, tweenInfo, {Offset = Vector2.new(-1, 0)})
				tween:Play()
				tween.Completed:Wait()
				gradient.Offset = Vector2.new(0, 0)
			end
		end)
	elseif rarity == "GODLY" then
		gradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 165, 0)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(204, 172, 0))
		}
	end
end

-- Function to update inventory display
local function updateInventory()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	inventoryCount.Text = #ownedBrainrots .. "/" .. maxBrainrots
	
	for i, brainrotItem in ipairs(ownedBrainrots) do
		local itemFrame = Instance.new("Frame")
		itemFrame.Size = UDim2.new(1, 0, 0, 70)
		itemFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		itemFrame.BorderSizePixel = 1
		itemFrame.BorderColor3 = rarityColors[brainrotItem.rarity]
		itemFrame.ZIndex = 7
		itemFrame.Parent = scrollFrame
		
		addRarityGradient(itemFrame, brainrotItem.rarity)
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.6, -10, 0, 20)
		nameLabel.Position = UDim2.new(0, 10, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = brainrotItem.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextWrapped = true
		nameLabel.ZIndex = 8
		nameLabel.Parent = itemFrame
		
		local incomeText = Instance.new("TextLabel")
		incomeText.Size = UDim2.new(0.6, -10, 0, 18)
		incomeText.Position = UDim2.new(0, 10, 0, 27)
		incomeText.BackgroundTransparency = 1
		incomeText.Text = "+" .. brainrotItem.income .. "$/s"
		incomeText.TextColor3 = Color3.fromRGB(85, 255, 85)
		incomeText.TextSize = 12
		incomeText.Font = Enum.Font.Gotham
		incomeText.TextXAlignment = Enum.TextXAlignment.Left
		incomeText.ZIndex = 8
		incomeText.Parent = itemFrame
		
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(0.6, -10, 0, 18)
		rarityLabel.Position = UDim2.new(0, 10, 0, 47)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Text = brainrotItem.rarity
		rarityLabel.TextColor3 = rarityColors[brainrotItem.rarity]
		rarityLabel.TextSize = 12
		rarityLabel.Font = Enum.Font.GothamBold
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
		rarityLabel.ZIndex = 8
		rarityLabel.Parent = itemFrame
		
		local sellButton = Instance.new("TextButton")
		sellButton.Size = UDim2.new(0, 80, 0, 50)
		sellButton.Position = UDim2.new(1, -90, 0, 10)
		sellButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
		sellButton.BorderSizePixel = 0
		sellButton.Text = "SELL\n$" .. math.floor(brainrotItem.cost * 0.7)
		sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		sellButton.TextSize = 12
		sellButton.Font = Enum.Font.GothamBold
		sellButton.ZIndex = 8
		sellButton.Parent = itemFrame
		
		sellButton.MouseButton1Click:Connect(function()
			local sellPrice = math.floor(brainrotItem.cost * 0.7)
			playerMoney = playerMoney + sellPrice
			passiveIncome = passiveIncome - brainrotItem.income
			table.remove(ownedBrainrots, i)
			
			moneyLabel.Text = "$" .. playerMoney
			incomeLabel.Text = "+" .. passiveIncome .. "$/s"
			
			updateInventory()
		end)
	end
	
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #ownedBrainrots * 75)
end

-- Track Frame (Scrolling Area)
local trackFrame = Instance.new("Frame")
trackFrame.Size = UDim2.new(0, 700, 0, 150)
trackFrame.Position = UDim2.new(0.5, -350, 0.5, -75)
trackFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
trackFrame.BorderSizePixel = 2
trackFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
trackFrame.ClipsDescendants = true
trackFrame.ZIndex = 1
trackFrame.Parent = screenGui

local trackTitle = Instance.new("TextLabel")
trackTitle.Size = UDim2.new(1, 0, 0, 25)
trackTitle.Position = UDim2.new(0, 0, 0, -30)
trackTitle.BackgroundTransparency = 1
trackTitle.Text = "🎯 BRAINROT TRACK 🎯"
trackTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
trackTitle.TextScaled = true
trackTitle.Font = Enum.Font.GothamBold
trackTitle.ZIndex = 1
trackTitle.Parent = trackFrame

-- Function to select random brainrot based on chances
local function selectRandomBrainrot()
	local availableBrainrots = {}
	for _, br in ipairs(brainrotData) do
		if (br.requiredRebirth or 0) <= rebirthLevel and br.chance > 0 then
			table.insert(availableBrainrots, br)
		end
	end
	
	local forceRarity = nil
	if superPity >= 342 then
		forceRarity = "Super"
	elseif mythicalPity >= 175 then
		forceRarity = "Mythical"
	elseif legendaryPity >= 50 then
		forceRarity = "Legendary"
	end
	
	local selectPool = availableBrainrots
	if forceRarity then
		selectPool = {}
		for _, br in ipairs(availableBrainrots) do
			if br.rarity == forceRarity then
				table.insert(selectPool, br)
			end
		end
	end
	if #selectPool == 0 then
		selectPool = availableBrainrots
	end
	
	local totalWeight = 0
	for _, brainrot in ipairs(selectPool) do
		local effectiveChance = brainrot.chance
		if brainrot.rarity == "Legendary" or brainrot.rarity == "Mythical" or brainrot.rarity == "Super" or brainrot.rarity == "MEGA" or brainrot.rarity == "CHROMATIC" or brainrot.rarity == "GODLY" then
			effectiveChance = effectiveChance * luckMultiplier
		end
		totalWeight = totalWeight + effectiveChance
	end
	
	local random = math.random() * totalWeight
	local cumulative = 0
	
	for _, brainrot in ipairs(selectPool) do
		local effectiveChance = brainrot.chance
		if brainrot.rarity == "Legendary" or brainrot.rarity == "Mythical" or brainrot.rarity == "Super" or brainrot.rarity == "MEGA" or brainrot.rarity == "CHROMATIC" or brainrot.rarity == "GODLY" then
			effectiveChance = effectiveChance * luckMultiplier
		end
		cumulative = cumulative + effectiveChance
		if random <= cumulative then
			-- Update pities
			if brainrot.rarity == "Legendary" then
				legendaryPity = 0
			else
				legendaryPity = legendaryPity + 1
			end
			if brainrot.rarity == "Mythical" then
				mythicalPity = 0
			else
				mythicalPity = mythicalPity + 1
			end
			if brainrot.rarity == "Super" then
				superPity = 0
			else
				superPity = superPity + 1
			end
			return brainrot
		end
	end
	
	return selectPool[1]
end

-- Function to create brainrot card
local function createBrainrotCard(brainrot)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 180, 0, 130)
	card.Position = UDim2.new(0, 700, 0, 10)
	card.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	card.BorderSizePixel = 2
	card.BorderColor3 = rarityColors[brainrot.rarity]
	card.ZIndex = 1
	card.Parent = trackFrame
	
	addRarityGradient(card, brainrot.rarity)
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 30)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = brainrot.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.ZIndex = 2
	nameLabel.Parent = card
	
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -10, 0, 18)
	rarityLabel.Position = UDim2.new(0, 5, 0, 35)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = brainrot.rarity
	rarityLabel.TextColor3 = rarityColors[brainrot.rarity]
	rarityLabel.TextSize = 12
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.ZIndex = 2
	rarityLabel.Parent = card
	
	local incomeText = Instance.new("TextLabel")
	incomeText.Size = UDim2.new(1, -10, 0, 18)
	incomeText.Position = UDim2.new(0, 5, 0, 55)
	incomeText.BackgroundTransparency = 1
	incomeText.Text = "+" .. brainrot.income .. "$/s"
	incomeText.TextColor3 = Color3.fromRGB(85, 255, 85)
	incomeText.TextSize = 12
	incomeText.Font = Enum.Font.Gotham
	incomeText.ZIndex = 2
	incomeText.Parent = card
	
	local costText = Instance.new("TextLabel")
	costText.Size = UDim2.new(1, -10, 0, 18)
	costText.Position = UDim2.new(0, 5, 0, 75)
	costText.BackgroundTransparency = 1
	costText.Text = "Cost: $" .. brainrot.cost
	costText.TextColor3 = Color3.fromRGB(255, 215, 0)
	costText.TextSize = 12
	costText.Font = Enum.Font.Gotham
	costText.ZIndex = 2
	costText.Parent = card
	
	local claimButton = Instance.new("TextButton")
	claimButton.Size = UDim2.new(0.9, 0, 0, 25)
	claimButton.Position = UDim2.new(0.05, 0, 0, 100)
	claimButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	claimButton.BorderSizePixel = 0
	claimButton.Text = "CLAIM"
	claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimButton.TextSize = 14
	claimButton.Font = Enum.Font.GothamBold
	claimButton.ZIndex = 2
	claimButton.Parent = card
	
	claimButton.MouseButton1Click:Connect(function()
		if #ownedBrainrots >= maxBrainrots then
			claimButton.Text = "INVENTORY FULL!"
			claimButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
			wait(1)
			claimButton.Text = "CLAIM"
			claimButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		elseif playerMoney >= brainrot.cost then
			playerMoney = playerMoney - brainrot.cost
			passiveIncome = passiveIncome + brainrot.income
			table.insert(ownedBrainrots, {
				name = brainrot.name,
				rarity = brainrot.rarity,
				income = brainrot.income,
				cost = brainrot.cost
			})
			
			moneyLabel.Text = "$" .. playerMoney
			incomeLabel.Text = "+" .. passiveIncome .. "$/s"
			updateInventory()
			
			claimButton.Text = "CLAIMED!"
			claimButton.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
			wait(0.5)
			card:Destroy()
		else
			claimButton.Text = "NOT ENOUGH $"
			claimButton.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
			wait(1)
			claimButton.Text = "CLAIM"
			claimButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		end
	end)
	
	-- Animate card moving left
	local tweenInfo = TweenInfo.new(8, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(card, tweenInfo, {Position = UDim2.new(0, -200, 0, 10)})
	tween:Play()
	
	tween.Completed:Connect(function()
		card:Destroy()
	end)
end

-- Spawn brainrots periodically
spawn(function()
	while wait(3) do
		local brainrot = selectRandomBrainrot()
		createBrainrotCard(brainrot)
		updatePityLabels()
	end
end)

-- Passive income generator
spawn(function()
	while wait(1) do
		if passiveIncome > 0 then
			playerMoney = playerMoney + passiveIncome
			moneyLabel.Text = "$" .. playerMoney
		end
	end
end)
