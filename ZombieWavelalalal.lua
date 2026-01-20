-- Zombie Apocalypse Game Script
-- Client-sided for Codex Executor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Game Variables
local currentWave = 1
local zombiesRemaining = 0
local isIntermission = false
local intermissionTime = 20
local gameStarted = false
local bossesSpawned = {}

-- Player Stats
local playerHealth = 100
local maxPlayerHealth = 100
local playerSpeed = 16

-- Gun Stats
local gunEquipped = false
local currentBullet = 10
local maxBullet = 10
local currentAmmo = 50
local maxAmmo = 50
local ammoPerReload = 10
local bulletDamage = 10
local shootCooldown = 1
local reloadTime = 5
local isReloading = false
local canShoot = true
local isShooting = false

-- Upgrade Stats
local damageBonus = 0
local speedBonus = 0
local slownessStacks = 0
local ricochetStacks = 0

-- Ability Stats
local hasBulletHell = false
local bulletHellStacks = 0
local hasExplosiveBullet = false
local explosiveBulletChance = 0.03

-- Zombie spawning variables
local activeZombies = {}
local zombieModels = {}
local minZombieIncrease = 5
local maxZombieIncrease = 10
local currentMinZombies = 10
local currentMaxZombies = 10

-- Zone tracking
local currentZone = "The City"
local waveHpIncrease = 0

-- Zombie Types
local zombieTypes = {
    Zombie = {
        introducedWave = 1,
        hp = 30,
        speed = 15,
        attackCooldown = 2,
        damage = 5,
        baseSpawnChance = 2,
        maxDecrease = 1,
        minCount = 1,
        maxCount = math.huge,
        color = Color3.fromRGB(100, 100, 100),
        zones = {"The City"}
    },
    Speedster = {
        introducedWave = 3,
        hp = 25,
        speed = 20,
        attackCooldown = 1,
        damage = 3,
        baseSpawnChance = 4,
        maxDecrease = 1,
        minCount = 1,
        maxCount = 100,
        color = Color3.fromRGB(50, 150, 255),
        zones = {"The City"}
    },
    Explosive = {
        introducedWave = 5,
        hp = 75,
        speed = 12,
        attackCooldown = 3,
        damage = 7,
        baseSpawnChance = 7,
        maxDecrease = 2,
        minCount = 2,
        maxCount = 30,
        color = Color3.fromRGB(255, 50, 50),
        explosive = true,
        zones = {"The City", "The Sewers"}
    },
    Speedster = {
        introducedWave = 3,
        hp = 25,
        speed = 20,
        attackCooldown = 1,
        damage = 3,
        baseSpawnChance = 4,
        maxDecrease = 1,
        minCount = 1,
        maxCount = 100,
        color = Color3.fromRGB(50, 150, 255),
        zones = {"The City", "The Lab"}
    },
    Tanky = {
        introducedWave = 9,
        hp = 100,
        speed = 8,
        attackCooldown = 2.5,
        damage = 15,
        baseSpawnChance = 10,
        maxDecrease = 1,
        minCount = 1,
        maxCount = 10,
        color = Color3.fromRGB(150, 50, 150),
        zones = {"The City", "The Sewers", "The Lab"}
    },
    Splitters = {
        introducedWave = 11,
        hp = 75,
        speed = 16,
        attackCooldown = 2.2,
        damage = 12,
        baseSpawnChance = 2,
        maxDecrease = 1,
        minCount = 1,
        maxCount = math.huge,
        color = Color3.fromRGB(200, 100, 50),
        splitter = true,
        zones = {"The Sewers"}
    },
    Vomiters = {
        introducedWave = 15,
        hp = 90,
        speed = 13,
        attackCooldown = 5,
        damage = 10,
        baseSpawnChance = 7,
        maxDecrease = 2,
        minCount = 1,
        maxCount = 90,
        color = Color3.fromRGB(100, 255, 50),
        vomiter = true,
        zones = {"The Sewers", "The Lab"}
    },
    Charger = {
        introducedWave = 17,
        hp = 500,
        speed = 30,
        attackCooldown = 4,
        damage = 75,
        baseSpawnChance = 10,
        maxDecrease = 5,
        minCount = 1,
        maxCount = 10,
        color = Color3.fromRGB(150, 150, 200),
        charger = true,
        zones = {"The Sewers"}
    },
    Zomshroom = {
        introducedWave = 19,
        hp = 750,
        speed = 0,
        attackCooldown = 10,
        damage = 30,
        baseSpawnChance = 20,
        maxDecrease = 7,
        minCount = 1,
        maxCount = 5,
        color = Color3.fromRGB(50, 200, 100),
        zomshroom = true,
        zones = {"The Lab"}
    },
    FireZombie = {
        introducedWave = 21,
        hp = 100,
        speed = 18,
        attackCooldown = 3,
        damage = 45,
        baseSpawnChance = 2,
        maxDecrease = 1,
        minCount = 1,
        maxCount = 250,
        color = Color3.fromRGB(255, 100, 0),
        fireZombie = true,
        zones = {"The Lab"}
    },
    TheHowler = {
        introducedWave = 10,
        hp = 920,
        speed = 17,
        attackCooldown = 2.5,
        damage = 30,
        baseSpawnChance = 1,
        maxDecrease = 1,
        minCount = 1,
        maxCount = 1,
        color = Color3.fromRGB(150, 0, 0),
        boss = true,
        onlyWave = 10,
        zones = {"The City"}
    },
    Toxicle = {
        introducedWave = 20,
        hp = 12000,
        speed = 25,
        attackCooldown = 5,
        damage = 90,
        baseSpawnChance = 1,
        maxDecrease = 1,
        minCount = 1,
        maxCount = 1,
        color = Color3.fromRGB(50, 255, 100),
        boss = true,
        onlyWave = 20,
        toxicle = true,
        zones = {"The Sewers"}
    }
}

-- Available upgrades
local availableUpgrades = {
    "Gun Damage",
    "Movement Speed",
    "Max Bullet Increase",
    "Max Ammo Increase",
    "Bullet Rate",
    "Max Health",
    "Slowness",
    "Ricochet"
}

local availableAbilities = {
    "Bullet Hell",
    "Explosive Bullet",
    "Heatseeking",
    "Lifesteal",
    "Fire Bullets",
    "Homing Bounce",
    "Magic Bullet"
}

local selectedAbilities = {}
local hasHeatseeking = false
local hasLifesteal = false
local hasFireBullets = false
local hasHomingBounce = false
local hasMagicBullet = false

-- GUI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZombieApocalypseGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- Wave Label
local waveLabel = Instance.new("TextLabel")
waveLabel.Size = UDim2.new(0, 200, 0, 50)
waveLabel.Position = UDim2.new(0.5, -100, 0, 10)
waveLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
waveLabel.BackgroundTransparency = 0.5
waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
waveLabel.TextScaled = true
waveLabel.Font = Enum.Font.SourceSansBold
waveLabel.Text = "Wave 1"
waveLabel.Parent = screenGui

-- Zone Label
local zoneLabel = Instance.new("TextLabel")
zoneLabel.Size = UDim2.new(0, 250, 0, 40)
zoneLabel.Position = UDim2.new(0.5, -125, 0, 65)
zoneLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
zoneLabel.BackgroundTransparency = 0.5
zoneLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
zoneLabel.TextScaled = true
zoneLabel.Font = Enum.Font.SourceSansBold
zoneLabel.Text = "The City"
zoneLabel.Parent = screenGui

-- HP Bar
local hpFrame = Instance.new("Frame")
hpFrame.Size = UDim2.new(0, 250, 0, 30)
hpFrame.Position = UDim2.new(0, 10, 1, -40)
hpFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hpFrame.BorderSizePixel = 2
hpFrame.Parent = screenGui

local hpBar = Instance.new("Frame")
hpBar.Size = UDim2.new(1, 0, 1, 0)
hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
hpBar.BorderSizePixel = 0
hpBar.Parent = hpFrame

local hpLabel = Instance.new("TextLabel")
hpLabel.Size = UDim2.new(1, 0, 1, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hpLabel.Font = Enum.Font.SourceSansBold
hpLabel.TextScaled = true
hpLabel.Text = "100/100"
hpLabel.Parent = hpFrame

-- Ammo Label
local ammoLabel = Instance.new("TextLabel")
ammoLabel.Size = UDim2.new(0, 150, 0, 40)
ammoLabel.Position = UDim2.new(1, -160, 1, -50)
ammoLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ammoLabel.BackgroundTransparency = 0.5
ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ammoLabel.TextScaled = true
ammoLabel.Font = Enum.Font.SourceSansBold
ammoLabel.Visible = false
ammoLabel.Parent = screenGui

-- Shoot Button
local shootButton = Instance.new("TextButton")
shootButton.Size = UDim2.new(0, 100, 0, 100)
shootButton.Position = UDim2.new(1, -120, 1, -120)
shootButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
shootButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shootButton.Font = Enum.Font.SourceSansBold
shootButton.TextScaled = true
shootButton.Text = "SHOOT"
shootButton.Visible = false
shootButton.Parent = screenGui

-- Debug/Cheat Buttons
local skipWaveButton = Instance.new("TextButton")
skipWaveButton.Size = UDim2.new(0, 120, 0, 40)
skipWaveButton.Position = UDim2.new(0, 10, 0, 120)
skipWaveButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
skipWaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
skipWaveButton.Font = Enum.Font.SourceSansBold
skipWaveButton.TextScaled = true
skipWaveButton.Text = "Skip Wave"
skipWaveButton.Parent = screenGui

local abilityChooseButton = Instance.new("TextButton")
abilityChooseButton.Size = UDim2.new(0, 120, 0, 40)
abilityChooseButton.Position = UDim2.new(0, 10, 0, 170)
abilityChooseButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
abilityChooseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
abilityChooseButton.Font = Enum.Font.SourceSansBold
abilityChooseButton.TextScaled = true
abilityChooseButton.Text = "Ability Choose"
abilityChooseButton.Parent = screenGui

local upgradeChooseButton = Instance.new("TextButton")
upgradeChooseButton.Size = UDim2.new(0, 120, 0, 40)
upgradeChooseButton.Position = UDim2.new(0, 10, 0, 220)
upgradeChooseButton.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
upgradeChooseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
upgradeChooseButton.Font = Enum.Font.SourceSansBold
upgradeChooseButton.TextScaled = true
upgradeChooseButton.Text = "Upgrade Choose"
upgradeChooseButton.Parent = screenGui

local zombieSpawnerButton = Instance.new("TextButton")
zombieSpawnerButton.Size = UDim2.new(0, 120, 0, 40)
zombieSpawnerButton.Position = UDim2.new(0, 10, 0, 270)
zombieSpawnerButton.BackgroundColor3 = Color3.fromRGB(200, 100, 200)
zombieSpawnerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
zombieSpawnerButton.Font = Enum.Font.SourceSansBold
zombieSpawnerButton.TextScaled = true
zombieSpawnerButton.Text = "Zombie Spawner"
zombieSpawnerButton.Parent = screenGui

local skipToWaveButton = Instance.new("TextButton")
skipToWaveButton.Size = UDim2.new(0, 120, 0, 40)
skipToWaveButton.Position = UDim2.new(0, 10, 0, 320)
skipToWaveButton.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
skipToWaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
skipToWaveButton.Font = Enum.Font.SourceSansBold
skipToWaveButton.TextScaled = true
skipToWaveButton.Text = "Skip to Wave"
skipToWaveButton.Parent = screenGui

-- Skip to Wave Frame
local skipWaveFrame = Instance.new("Frame")
skipWaveFrame.Size = UDim2.new(0, 200, 0, 120)
skipWaveFrame.Position = UDim2.new(0.5, -100, 0.5, -60)
skipWaveFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
skipWaveFrame.BorderSizePixel = 2
skipWaveFrame.BorderColor3 = Color3.fromRGB(255, 200, 100)
skipWaveFrame.Visible = false
skipWaveFrame.Parent = screenGui

local skipWaveTitle = Instance.new("TextLabel")
skipWaveTitle.Size = UDim2.new(1, 0, 0, 30)
skipWaveTitle.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
skipWaveTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
skipWaveTitle.Font = Enum.Font.SourceSansBold
skipWaveTitle.TextScaled = true
skipWaveTitle.Text = "Skip to Wave"
skipWaveTitle.Parent = skipWaveFrame

local closeSkipButton = Instance.new("TextButton")
closeSkipButton.Size = UDim2.new(0, 25, 0, 25)
closeSkipButton.Position = UDim2.new(1, -27, 0, 2)
closeSkipButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeSkipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeSkipButton.Font = Enum.Font.SourceSansBold
closeSkipButton.TextScaled = true
closeSkipButton.Text = "X"
closeSkipButton.Parent = skipWaveFrame

local waveInputLabel = Instance.new("TextLabel")
waveInputLabel.Size = UDim2.new(1, -10, 0, 20)
waveInputLabel.Position = UDim2.new(0, 5, 0, 35)
waveInputLabel.BackgroundTransparency = 1
waveInputLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
waveInputLabel.Font = Enum.Font.SourceSans
waveInputLabel.TextSize = 14
waveInputLabel.Text = "Enter Wave Number:"
waveInputLabel.TextXAlignment = Enum.TextXAlignment.Left
waveInputLabel.Parent = skipWaveFrame

local waveInput = Instance.new("TextBox")
waveInput.Size = UDim2.new(1, -10, 0, 25)
waveInput.Position = UDim2.new(0, 5, 0, 55)
waveInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
waveInput.TextColor3 = Color3.fromRGB(255, 255, 255)
waveInput.Font = Enum.Font.SourceSans
waveInput.TextSize = 14
waveInput.PlaceholderText = "Enter wave (e.g., 15)"
waveInput.Text = ""
waveInput.Parent = skipWaveFrame

local confirmSkipButton = Instance.new("TextButton")
confirmSkipButton.Size = UDim2.new(1, -10, 0, 30)
confirmSkipButton.Position = UDim2.new(0, 5, 1, -35)
confirmSkipButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
confirmSkipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmSkipButton.Font = Enum.Font.SourceSansBold
confirmSkipButton.TextScaled = true
confirmSkipButton.Text = "Skip"
confirmSkipButton.Parent = skipWaveFrame

-- Zombie Spawner Frame
local zombieSpawnerFrame = Instance.new("Frame")
zombieSpawnerFrame.Size = UDim2.new(0, 200, 0, 399)
zombieSpawnerFrame.Position = UDim2.new(0.5, -100, 0.5, -199)
zombieSpawnerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
zombieSpawnerFrame.BorderSizePixel = 2
zombieSpawnerFrame.BorderColor3 = Color3.fromRGB(200, 100, 200)
zombieSpawnerFrame.Visible = false
zombieSpawnerFrame.Parent = screenGui

local spawnerTitle = Instance.new("TextLabel")
spawnerTitle.Size = UDim2.new(1, 0, 0, 30)
spawnerTitle.Position = UDim2.new(0, 0, 0, 0)
spawnerTitle.BackgroundColor3 = Color3.fromRGB(200, 100, 200)
spawnerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnerTitle.Font = Enum.Font.SourceSansBold
spawnerTitle.TextScaled = true
spawnerTitle.Text = "Zombie Spawner"
spawnerTitle.Parent = zombieSpawnerFrame

local closeSpawnerButton = Instance.new("TextButton")
closeSpawnerButton.Size = UDim2.new(0, 25, 0, 25)
closeSpawnerButton.Position = UDim2.new(1, -27, 0, 2)
closeSpawnerButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeSpawnerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeSpawnerButton.Font = Enum.Font.SourceSansBold
closeSpawnerButton.TextScaled = true
closeSpawnerButton.Text = "X"
closeSpawnerButton.Parent = zombieSpawnerFrame

local amountLabel = Instance.new("TextLabel")
amountLabel.Size = UDim2.new(1, -10, 0, 20)
amountLabel.Position = UDim2.new(0, 5, 0, 35)
amountLabel.BackgroundTransparency = 1
amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
amountLabel.Font = Enum.Font.SourceSans
amountLabel.TextSize = 14
amountLabel.Text = "Amount to Spawn:"
amountLabel.TextXAlignment = Enum.TextXAlignment.Left
amountLabel.Parent = zombieSpawnerFrame

local amountInput = Instance.new("TextBox")
amountInput.Size = UDim2.new(1, -10, 0, 25)
amountInput.Position = UDim2.new(0, 5, 0, 55)
amountInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
amountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
amountInput.Font = Enum.Font.SourceSans
amountInput.TextSize = 14
amountInput.PlaceholderText = "Enter amount (e.g., 5)"
amountInput.Text = "1"
amountInput.Parent = zombieSpawnerFrame

local zombieListLabel = Instance.new("TextLabel")
zombieListLabel.Size = UDim2.new(1, -10, 0, 20)
zombieListLabel.Position = UDim2.new(0, 5, 0, 85)
zombieListLabel.BackgroundTransparency = 1
zombieListLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
zombieListLabel.Font = Enum.Font.SourceSans
zombieListLabel.TextSize = 14
zombieListLabel.Text = "Select Zombie:"
zombieListLabel.TextXAlignment = Enum.TextXAlignment.Left
zombieListLabel.Parent = zombieSpawnerFrame

local zombieListFrame = Instance.new("ScrollingFrame")
zombieListFrame.Size = UDim2.new(1, -10, 0, 220)
zombieListFrame.Position = UDim2.new(0, 5, 0, 105)
zombieListFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
zombieListFrame.BorderSizePixel = 1
zombieListFrame.ScrollBarThickness = 6
zombieListFrame.Parent = zombieSpawnerFrame

local spawnConfirmButton = Instance.new("TextButton")
spawnConfirmButton.Size = UDim2.new(1, -10, 0, 35)
spawnConfirmButton.Position = UDim2.new(0, 5, 1, -40)
spawnConfirmButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
spawnConfirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnConfirmButton.Font = Enum.Font.SourceSansBold
spawnConfirmButton.TextScaled = true
spawnConfirmButton.Text = "Spawn Zombies"
spawnConfirmButton.Parent = zombieSpawnerFrame

local selectedZombieType = nil

-- Populate zombie list
local yOffset = 0
for zombieName, zombieData in pairs(zombieTypes) do
    local zombieButton = Instance.new("TextButton")
    zombieButton.Size = UDim2.new(1, -10, 0, 35)
    zombieButton.Position = UDim2.new(0, 5, 0, yOffset)
    zombieButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    zombieButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    zombieButton.Font = Enum.Font.SourceSans
    zombieButton.TextSize = 12
    zombieButton.Text = zombieName .. "\nHP: " .. zombieData.hp .. " | DMG: " .. zombieData.damage
    zombieButton.Parent = zombieListFrame
    
    zombieButton.MouseButton1Click:Connect(function()
        selectedZombieType = zombieName
        
        -- Reset all buttons
        for _, child in pairs(zombieListFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            end
        end
        
        -- Highlight selected
        zombieButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    end)
    
    yOffset = yOffset + 40
end

zombieListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)

-- Upgrade Selection Frame
local upgradeFrame = Instance.new("Frame")
upgradeFrame.Size = UDim2.new(1, 0, 1, 0)
upgradeFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
upgradeFrame.BackgroundTransparency = 0.3
upgradeFrame.Visible = false
upgradeFrame.Parent = screenGui

local upgradeTitle = Instance.new("TextLabel")
upgradeTitle.Size = UDim2.new(0, 400, 0, 60)
upgradeTitle.Position = UDim2.new(0.5, -200, 0.1, 0)
upgradeTitle.BackgroundTransparency = 1
upgradeTitle.TextColor3 = Color3.fromRGB(255, 255, 0)
upgradeTitle.Font = Enum.Font.SourceSansBold
upgradeTitle.TextScaled = true
upgradeTitle.Text = "Choose Your Upgrade!"
upgradeTitle.Parent = upgradeFrame

-- Create Gun Tool
local gun = Instance.new("Tool")
gun.Name = "Gun"
gun.RequiresHandle = true
gun.CanBeDropped = false

local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.5, 0.3, 2)
handle.BrickColor = BrickColor.new("Really black")
handle.Parent = gun

-- Functions
local function updateHPBar()
    local healthPercent = playerHealth / maxPlayerHealth
    hpBar.Size = UDim2.new(healthPercent, 0, 1, 0)
    hpLabel.Text = math.floor(playerHealth) .. "/" .. maxPlayerHealth
    
    if healthPercent > 0.6 then
        hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    elseif healthPercent > 0.3 then
        hpBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    else
        hpBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    end
end

local function updateAmmoLabel()
    ammoLabel.Text = currentBullet .. "/" .. currentAmmo
end

local function damagePlayer(damage)
    playerHealth = math.max(0, playerHealth - damage)
    updateHPBar()
    
    if playerHealth <= 0 then
        humanoid.Health = 0
    end
end

local function healPlayer(amount)
    playerHealth = math.min(maxPlayerHealth, playerHealth + amount)
    updateHPBar()
end

local function createExplosion(position, radius, damage, isRed)
    local explosion = Instance.new("Part")
    explosion.Shape = Enum.PartType.Ball
    explosion.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
    explosion.Position = position
    explosion.Anchored = true
    explosion.CanCollide = false
    explosion.Transparency = 0.5
    explosion.Material = Enum.Material.Neon
    explosion.Color = isRed and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 0)
    explosion.Parent = workspace
    
    -- Damage entities in range
    for _, zombie in pairs(activeZombies) do
        if zombie and zombie.PrimaryPart then
            local distance = (zombie.PrimaryPart.Position - position).Magnitude
            if distance <= radius then
                local zombieHumanoid = zombie:FindFirstChildOfClass("Humanoid")
                if zombieHumanoid then
                    zombieHumanoid.Health = zombieHumanoid.Health - damage
                end
                
                -- Push zombies away
                local pushDirection = (zombie.PrimaryPart.Position - position).Unit
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Velocity = pushDirection * 50
                bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                bodyVelocity.Parent = zombie.PrimaryPart
                game:GetService("Debris"):AddItem(bodyVelocity, 0.1)
            end
        end
    end
    
    -- Check player distance
    local playerDistance = (rootPart.Position - position).Magnitude
    if playerDistance <= radius then
        damagePlayer(damage)
    end
    
    -- Fade out explosion
    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(explosion, tweenInfo, {Transparency = 1})
    tween:Play()
    
    game:GetService("Debris"):AddItem(explosion, 1)
end

local function spawnOrb(position, orbType)
    local orb = Instance.new("Part")
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(2, 2, 2)
    orb.Position = position + Vector3.new(0, 2, 0)
    orb.Anchored = true
    orb.CanCollide = false
    orb.Material = Enum.Material.Neon
    
    if orbType == "ammo" then
        orb.Color = Color3.fromRGB(0, 255, 0)
    elseif orbType == "health" then
        orb.Color = Color3.fromRGB(255, 0, 0)
    else
        orb.Color = Color3.fromRGB(255, 255, 0)
    end
    
    orb.Parent = workspace
    
    -- Floating animation
    local startPos = orb.Position
    spawn(function()
        while orb.Parent do
            orb.Position = startPos + Vector3.new(0, math.sin(tick() * 2) * 0.5, 0)
            orb.CFrame = orb.CFrame * CFrame.Angles(0, math.rad(2), 0)
            wait()
        end
    end)
    
    -- Touch detection
    local touchConnection
    touchConnection = orb.Touched:Connect(function(hit)
        if hit.Parent == character then
            touchConnection:Disconnect()
            
            if orbType == "ammo" then
                currentAmmo = maxAmmo
                updateAmmoLabel()
            elseif orbType == "health" then
                healPlayer(maxPlayerHealth)
            elseif orbType == "ability" then
                showUpgradeSelection(true)
            end
            
            orb:Destroy()
        end
    end)
    
    game:GetService("Debris"):AddItem(orb, 30)
end

local function createZombie(zombieType, spawnPosition)
    local zombieData = zombieTypes[zombieType]
    
    -- Create zombie model
    local zombie = Instance.new("Model")
    zombie.Name = zombieType
    
    local isBoss = zombieData.boss or false
    local isCharger = zombieData.charger or false
    local sizeMultiplier = isBoss and 3 or (isCharger and 2.5 or 1)
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2 * sizeMultiplier, 2 * sizeMultiplier, 1 * sizeMultiplier)
    torso.Position = spawnPosition
    torso.BrickColor = BrickColor.new(zombieData.color)
    torso.Parent = zombie
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.5 * sizeMultiplier, 1.5 * sizeMultiplier, 1.5 * sizeMultiplier)
    head.Position = spawnPosition + Vector3.new(0, 2 * sizeMultiplier, 0)
    head.BrickColor = BrickColor.new(zombieData.color)
    head.Parent = zombie
    
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(1 * sizeMultiplier, 2 * sizeMultiplier, 1 * sizeMultiplier)
    leftArm.Position = spawnPosition + Vector3.new(-1.5 * sizeMultiplier, 0, 0)
    leftArm.BrickColor = BrickColor.new(zombieData.color)
    leftArm.Parent = zombie
    
    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(1 * sizeMultiplier, 2 * sizeMultiplier, 1 * sizeMultiplier)
    rightArm.Position = spawnPosition + Vector3.new(1.5 * sizeMultiplier, 0, 0)
    rightArm.BrickColor = BrickColor.new(zombieData.color)
    rightArm.Parent = zombie
    
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(1 * sizeMultiplier, 2 * sizeMultiplier, 1 * sizeMultiplier)
    leftLeg.Position = spawnPosition + Vector3.new(-0.5 * sizeMultiplier, -2 * sizeMultiplier, 0)
    leftLeg.BrickColor = BrickColor.new(zombieData.color)
    leftLeg.Parent = zombie
    
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(1 * sizeMultiplier, 2 * sizeMultiplier, 1 * sizeMultiplier)
    rightLeg.Position = spawnPosition + Vector3.new(0.5 * sizeMultiplier, -2 * sizeMultiplier, 0)
    rightLeg.BrickColor = BrickColor.new(zombieData.color)
    rightLeg.Parent = zombie
    
    local zombieHumanoid = Instance.new("Humanoid")
    zombieHumanoid.MaxHealth = zombieData.hp + waveHpIncrease
    zombieHumanoid.Health = zombieData.hp + waveHpIncrease
    -- Fixed: Use base speed from data, not affected by slownessStacks during creation
    local baseSpeed = zombieData.speed
    if not zombieData.charger and not zombieData.zomshroom then
        baseSpeed = math.max(1, zombieData.speed - slownessStacks)
    end
    zombieHumanoid.WalkSpeed = baseSpeed
    zombieHumanoid.Parent = zombie
    
    zombie.PrimaryPart = torso
    zombie.Parent = workspace
    
    -- HP Bar above zombie
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(4 * sizeMultiplier, 0, 0.5 * sizeMultiplier, 0)
    billboardGui.StudsOffset = Vector3.new(0, 3 * sizeMultiplier, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = head
    
    local hpBarFrame = Instance.new("Frame")
    hpBarFrame.Size = UDim2.new(1, 0, 1, 0)
    hpBarFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    hpBarFrame.Parent = billboardGui
    
    local zombieHpBar = Instance.new("Frame")
    zombieHpBar.Size = UDim2.new(1, 0, 1, 0)
    zombieHpBar.BackgroundColor3 = isBoss and Color3.fromRGB(255, 100, 0) or Color3.fromRGB(255, 0, 0)
    zombieHpBar.BorderSizePixel = 0
    zombieHpBar.Parent = hpBarFrame
    
    if isBoss then
        local bossNameLabel = Instance.new("TextLabel")
        bossNameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        bossNameLabel.Position = UDim2.new(0, 0, -0.6, 0)
        bossNameLabel.BackgroundTransparency = 1
        bossNameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        bossNameLabel.Font = Enum.Font.SourceSansBold
        bossNameLabel.TextScaled = true
        bossNameLabel.Text = "BOSS: " .. zombieType
        bossNameLabel.Parent = billboardGui
    end
    
    table.insert(activeZombies, zombie)
    
    -- Zombie AI
    local lastAttackTime = 0
    local attackCount = 0
    local poisonedPlayers = {}
    local isCharging = false
    
    -- Zomshroom spawning logic
    if zombieData.zomshroom then
        spawn(function()
            while zombie.Parent and zombieHumanoid.Health > 0 do
                wait(10)
                
                if character and rootPart then
                    -- Create green forcefield
                    local forcefield = Instance.new("Part")
                    forcefield.Shape = Enum.PartType.Ball
                    forcefield.Size = Vector3.new(30, 30, 30)
                    forcefield.Position = torso.Position
                    forcefield.Anchored = true
                    forcefield.CanCollide = false
                    forcefield.Transparency = 0.5
                    forcefield.Material = Enum.Material.Neon
                    forcefield.Color = Color3.fromRGB(100, 255, 50)
                    forcefield.Parent = workspace
                    
                    -- Damage entities in range
                    local distance = (rootPart.Position - torso.Position).Magnitude
                    if distance <= 15 then
                        damagePlayer(zombieData.damage)
                    end
                    
                    for _, z in pairs(activeZombies) do
                        if z and z.PrimaryPart and z ~= zombie then
                            local zDist = (z.PrimaryPart.Position - torso.Position).Magnitude
                            if zDist <= 15 then
                                local zHum = z:FindFirstChildOfClass("Humanoid")
                                if zHum then
                                    zHum.Health = zHum.Health - zombieData.damage
                                end
                            end
                        end
                    end
                    
                    -- Fade out
                    local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(forcefield, tweenInfo, {Transparency = 1})
                    tween:Play()
                    game:GetService("Debris"):AddItem(forcefield, 1)
                    
                    -- Spawn a zombie
                    local spawnRand = math.random(1, 10)
                    local spawnType = nil
                    
                    if spawnRand <= 5 then
                        spawnType = "Splitters"
                    elseif spawnRand <= 8 then
                        spawnType = "Vomiters"
                    else
                        spawnType = "Charger"
                    end
                    
                    local angle = math.random() * math.pi * 2
                    local dist = math.random(5, 15)
                    local spawnPos = torso.Position + Vector3.new(
                        math.cos(angle) * dist,
                        0,
                        math.sin(angle) * dist
                    )
                    
                    createZombie(spawnType, spawnPos)
                    zombiesRemaining = zombiesRemaining + 1
                end
            end
        end)
    end
    
    -- Toxicle radiation aura
    if zombieData.toxicle then
        spawn(function()
            while zombie.Parent and zombieHumanoid.Health > 0 do
                wait(1)
                
                if character and rootPart then
                    -- Damage player in radiation range
                    local distance = (rootPart.Position - torso.Position).Magnitude
                    if distance <= 30 then
                        local radiationDamage = math.random(10, 20)
                        damagePlayer(radiationDamage)
                    end
                    
                    -- Damage zombies (except Sewers zombies)
                    for _, z in pairs(activeZombies) do
                        if z and z.PrimaryPart and z ~= zombie then
                            local zDist = (z.PrimaryPart.Position - torso.Position).Magnitude
                            if zDist <= 30 then
                                -- Check if it's a Sewers zombie
                                local isSewerZombie = false
                                local zData = zombieTypes[z.Name]
                                if zData and zData.zones then
                                    for _, zone in pairs(zData.zones) do
                                        if zone == "The Sewers" then
                                            isSewerZombie = true
                                            break
                                        end
                                    end
                                end
                                
                                if not isSewerZombie then
                                    local zHum = z:FindFirstChildOfClass("Humanoid")
                                    if zHum then
                                        local radiationDamage = math.random(10, 20)
                                        zHum.Health = zHum.Health - radiationDamage
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        
        -- Visual radiation effect
        spawn(function()
            local radiationEffect = Instance.new("Part")
            radiationEffect.Shape = Enum.PartType.Ball
            radiationEffect.Size = Vector3.new(60, 60, 60)
            radiationEffect.Anchored = true
            radiationEffect.CanCollide = false
            radiationEffect.Transparency = 0.8
            radiationEffect.Material = Enum.Material.Neon
            radiationEffect.Color = Color3.fromRGB(50, 255, 100)
            radiationEffect.Parent = zombie
            
            while zombie.Parent and zombieHumanoid.Health > 0 do
                radiationEffect.Position = torso.Position
                radiationEffect.Transparency = 0.7 + math.sin(tick() * 2) * 0.2
                wait()
            end
            
            radiationEffect:Destroy()
        end)
    end
    
    spawn(function()
        while zombie.Parent and zombieHumanoid.Health > 0 do
            if character and rootPart then
                local distance = (torso.Position - rootPart.Position).Magnitude
                
                -- Zomshroom doesn't move
                if zombieData.zomshroom then
                    zombieHumanoid.WalkSpeed = 0
                -- Toxicle projectile attack
                elseif zombieData.toxicle and distance <= 40 then
                    zombieHumanoid.WalkSpeed = 0
                    
                    if tick() - lastAttackTime >= zombieData.attackCooldown then
                        -- Shoot toxic slime projectile
                        local slime = Instance.new("Part")
                        slime.Shape = Enum.PartType.Ball
                        slime.Size = Vector3.new(3, 3, 3)
                        slime.Position = torso.Position + Vector3.new(0, 2, 0)
                        slime.BrickColor = BrickColor.new("Lime green")
                        slime.Material = Enum.Material.Neon
                        slime.CanCollide = false
                        slime.Anchored = false
                        slime.Transparency = 0.2
                        slime.Parent = workspace
                        
                        -- Trail effect
                        local trail = Instance.new("Trail")
                        local att0 = Instance.new("Attachment", slime)
                        local att1 = Instance.new("Attachment", slime)
                        att1.Position = Vector3.new(0, 1, 0)
                        trail.Attachment0 = att0
                        trail.Attachment1 = att1
                        trail.Color = ColorSequence.new(Color3.fromRGB(50, 255, 100))
                        trail.Lifetime = 0.8
                        trail.Parent = slime
                        
                        local direction = (rootPart.Position - slime.Position).Unit
                        local bodyVelocity = Instance.new("BodyVelocity")
                        bodyVelocity.Velocity = direction * 60
                        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                        bodyVelocity.Parent = slime
                        
                        local hitConnection
                        hitConnection = slime.Touched:Connect(function(hit)
                            if hit.Parent == character then
                                hitConnection:Disconnect()
                                damagePlayer(zombieData.damage)
                                slime:Destroy()
                            end
                        end)
                        
                        game:GetService("Debris"):AddItem(slime, 5)
                        lastAttackTime = tick()
                    end
                -- Charger special behavior
                elseif isCharger then
                    zombieHumanoid.WalkSpeed = 0
                    
                    if tick() - lastAttackTime >= zombieData.attackCooldown and not isCharging then
                        isCharging = true
                        lastAttackTime = tick()
                        
                        -- Start charge
                        torso.BrickColor = BrickColor.new("Bright red")
                        local chargeDirection = (rootPart.Position - torso.Position).Unit
                        local chargeVelocity = Instance.new("BodyVelocity")
                        chargeVelocity.Velocity = chargeDirection * zombieData.speed
                        chargeVelocity.MaxForce = Vector3.new(100000, 0, 100000)
                        chargeVelocity.Parent = torso
                        
                        -- Charge hit detection
                        local chargeConnection
                        chargeConnection = torso.Touched:Connect(function(hit)
                            if hit.Parent == character then
                                damagePlayer(zombieData.damage)
                                
                                -- Fling player
                                local flingDirection = (rootPart.Position - torso.Position).Unit
                                local bodyVelocity = Instance.new("BodyVelocity")
                                bodyVelocity.Velocity = flingDirection * 80 + Vector3.new(0, 30, 0)
                                bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                                bodyVelocity.Parent = rootPart
                                game:GetService("Debris"):AddItem(bodyVelocity, 0.3)
                            end
                        end)
                        
                        wait(1)
                        
                        chargeConnection:Disconnect()
                        chargeVelocity:Destroy()
                        torso.BrickColor = BrickColor.new(zombieData.color)
                        isCharging = false
                    end
                -- Vomiter projectile attack
                elseif zombieData.vomiter and distance <= 30 then
                    zombieHumanoid.WalkSpeed = 0
                    
                    if tick() - lastAttackTime >= zombieData.attackCooldown then
                        -- Shoot vomit projectile
                        local vomit = Instance.new("Part")
                        vomit.Shape = Enum.PartType.Ball
                        vomit.Size = Vector3.new(1.5, 1.5, 1.5)
                        vomit.Position = torso.Position + Vector3.new(0, 1, 0)
                        vomit.BrickColor = BrickColor.new("Lime green")
                        vomit.Material = Enum.Material.Neon
                        vomit.CanCollide = false
                        vomit.Anchored = false
                        vomit.Transparency = 0.3
                        vomit.Parent = workspace
                        
                        -- Trail effect
                        local trail = Instance.new("Trail")
                        local att0 = Instance.new("Attachment", vomit)
                        local att1 = Instance.new("Attachment", vomit)
                        att1.Position = Vector3.new(0, 1, 0)
                        trail.Attachment0 = att0
                        trail.Attachment1 = att1
                        trail.Color = ColorSequence.new(Color3.fromRGB(100, 255, 50))
                        trail.Lifetime = 0.5
                        trail.Parent = vomit
                        
                        local direction = (rootPart.Position - vomit.Position).Unit
                        local bodyVelocity = Instance.new("BodyVelocity")
                        bodyVelocity.Velocity = direction * 50
                        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                        bodyVelocity.Parent = vomit
                        
                        local hitConnection
                        hitConnection = vomit.Touched:Connect(function(hit)
                            if hit.Parent == character then
                                hitConnection:Disconnect()
                                damagePlayer(zombieData.damage)
                                
                                -- Apply poison
                                if not poisonedPlayers[player.UserId] then
                                    poisonedPlayers[player.UserId] = true
                                    spawn(function()
                                        for i = 1, 600 do
                                            wait(1)
                                            damagePlayer(1)
                                        end
                                        poisonedPlayers[player.UserId] = nil
                                    end)
                                end
                                
                                vomit:Destroy()
                            end
                        end)
                        
                        game:GetService("Debris"):AddItem(vomit, 5)
                        lastAttackTime = tick()
                    end
                elseif distance <= 10 then
                    -- Melee attack
                    zombieHumanoid.WalkSpeed = 0
                    
                    if tick() - lastAttackTime >= zombieData.attackCooldown then
                        damagePlayer(zombieData.damage)
                        lastAttackTime = tick()
                        attackCount = attackCount + 1
                        
                        -- Fire Zombie burning effect
                        if zombieData.fireZombie then
                            spawn(function()
                                for i = 1, 6 do
                                    wait(0.5)
                                    damagePlayer(5)
                                end
                            end)
                        end
                        
                        -- Howler special ability
                        if zombieType == "TheHowler" and attackCount % 5 == 0 then
                            -- Howl animation
                            torso.BrickColor = BrickColor.new("Bright red")
                            wait(0.5)
                            torso.BrickColor = BrickColor.new(zombieData.color)
                            
                            createExplosion(torso.Position, 40, 75, true)
                            
                            -- Stun player
                            local originalSpeed = humanoid.WalkSpeed
                            humanoid.WalkSpeed = 0
                            wait(3)
                            humanoid.WalkSpeed = originalSpeed
                            
                            -- Stun all zombies
                            for _, z in pairs(activeZombies) do
                                if z ~= zombie and z:FindFirstChildOfClass("Humanoid") then
                                    local zHum = z:FindFirstChildOfClass("Humanoid")
                                    local zSpeed = zHum.WalkSpeed
                                    zHum.WalkSpeed = 0
                                    spawn(function()
                                        wait(3)
                                        if zHum and zHum.Parent then
                                            zHum.WalkSpeed = zSpeed
                                        end
                                    end)
                                end
                            end
                        end
                    end
                else
                    -- Follow player
                    local followSpeed = zombieData.speed
                    if not zombieData.boss and not zombieData.charger and not zombieData.zomshroom then
                        followSpeed = math.max(1, zombieData.speed - slownessStacks)
                    end
                    zombieHumanoid.WalkSpeed = followSpeed
                    zombieHumanoid:MoveTo(rootPart.Position)
                end
            end
            
            -- Update HP bar
            local healthPercent = zombieHumanoid.Health / zombieHumanoid.MaxHealth
            zombieHpBar.Size = UDim2.new(healthPercent, 0, 1, 0)
            
            wait(0.1)
        end
    end)
    
    -- Death handling
    zombieHumanoid.Died:Connect(function()
        zombiesRemaining = zombiesRemaining - 1
        
        -- Remove from active zombies
        for i, z in pairs(activeZombies) do
            if z == zombie then
                table.remove(activeZombies, i)
                break
            end
        end
        
        -- Splitter special
        if zombieData.splitter then
            for i = 1, 2 do
                local splitZombie = Instance.new("Model")
                splitZombie.Name = "SplittedZombie"
                
                local splitTorso = Instance.new("Part")
                splitTorso.Name = "Torso"
                splitTorso.Size = Vector3.new(1, 1, 0.5)
                splitTorso.Position = torso.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
                splitTorso.BrickColor = BrickColor.new(zombieData.color)
                splitTorso.Parent = splitZombie
                
                local splitHead = Instance.new("Part")
                splitHead.Name = "Head"
                splitHead.Size = Vector3.new(0.75, 0.75, 0.75)
                splitHead.Position = splitTorso.Position + Vector3.new(0, 1, 0)
                splitHead.BrickColor = BrickColor.new(zombieData.color)
                splitHead.Parent = splitZombie
                
                local splitHumanoid = Instance.new("Humanoid")
                splitHumanoid.MaxHealth = 40
                splitHumanoid.Health = 40
                splitHumanoid.WalkSpeed = 19
                splitHumanoid.Parent = splitZombie
                
                splitZombie.PrimaryPart = splitTorso
                splitZombie.Parent = workspace
                table.insert(activeZombies, splitZombie)
                zombiesRemaining = zombiesRemaining + 1
                
                -- Split zombie AI
                spawn(function()
                    local splitLastAttack = 0
                    while splitZombie.Parent and splitHumanoid.Health > 0 do
                        if character and rootPart then
                            local dist = (splitTorso.Position - rootPart.Position).Magnitude
                            if dist <= 10 then
                                splitHumanoid.WalkSpeed = 0
                                if tick() - splitLastAttack >= 1 then
                                    damagePlayer(3)
                                    splitLastAttack = tick()
                                end
                            else
                                splitHumanoid.WalkSpeed = 19
                                splitHumanoid:MoveTo(rootPart.Position)
                            end
                        end
                        wait(0.1)
                    end
                end)
                
                splitHumanoid.Died:Connect(function()
                    zombiesRemaining = zombiesRemaining - 1
                    for j, z in pairs(activeZombies) do
                        if z == splitZombie then
                            table.remove(activeZombies, j)
                            break
                        end
                    end
                    splitZombie:Destroy()
                end)
            end
        end
        
        -- Explosive zombie special
        if zombieData.explosive then
            createExplosion(torso.Position, 20, 20, true)
        end
        
        -- Bullet Hell ability
        if hasBulletHell then
            bulletHellStacks = bulletHellStacks + 1
        end
        
        -- Orb drops
        local rand = math.random(1, 100)
        if rand <= 5 then
            spawnOrb(torso.Position, "ability")
        elseif rand <= 25 then
            spawnOrb(torso.Position, "ammo")
        elseif rand <= 45 then
            spawnOrb(torso.Position, "health")
        end
        
        zombie:Destroy()
        
        if zombiesRemaining <= 0 and not isIntermission then
            startIntermission()
        end
    end)
    
    return zombie
end

local function getSpawnChance(zombieType)
    local data = zombieTypes[zombieType]
    local wavesElapsed = currentWave - data.introducedWave
    local decreaseAmount = math.floor(wavesElapsed / (12 - data.maxDecrease))
    local currentChance = math.max(data.maxDecrease, data.baseSpawnChance - (decreaseAmount * (12 - data.maxDecrease) / 10))
    return math.max(1, math.floor(currentChance))
end

local function spawnWaveZombies()
    local zombieCount = math.random(currentMinZombies, currentMaxZombies)
    zombiesRemaining = zombieCount
    
    -- Reset zombie spawn count after wave 15
    if currentWave == 16 then
        currentMinZombies = 20
        currentMaxZombies = 20
    end
    
    -- Update zone
    if currentWave >= 21 then
        currentZone = "The Lab"
        zoneLabel.Text = "The Lab"
        zoneLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    elseif currentWave >= 11 then
        currentZone = "The Sewers"
        zoneLabel.Text = "The Sewers"
        zoneLabel.TextColor3 = Color3.fromRGB(100, 200, 50)
    else
        currentZone = "The City"
        zoneLabel.Text = "The City"
        zoneLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    end
    
    -- Spawn boss on specific wave (only once)
    if currentWave == 10 and not bossesSpawned["TheHowler"] then
        local angle = math.random() * math.pi * 2
        local distance = 50
        local spawnPos = rootPart.Position + Vector3.new(
            math.cos(angle) * distance,
            5,
            math.sin(angle) * distance
        )
        createZombie("TheHowler", spawnPos)
        bossesSpawned["TheHowler"] = true
    elseif currentWave == 20 and not bossesSpawned["Toxicle"] then
        local angle = math.random() * math.pi * 2
        local distance = 50
        local spawnPos = rootPart.Position + Vector3.new(
            math.cos(angle) * distance,
            5,
            math.sin(angle) * distance
        )
        createZombie("Toxicle", spawnPos)
        bossesSpawned["Toxicle"] = true
    end
    
    for i = 1, zombieCount do
        -- Determine zombie type
        local availableTypes = {}
        for typeName, data in pairs(zombieTypes) do
            -- Skip if it's a boss-only wave zombie and already spawned
            if data.onlyWave and bossesSpawned[typeName] then
                -- Skip this type
            elseif currentWave >= data.introducedWave and not data.onlyWave then
                -- Check zone restrictions
                local validZone = false
                if data.zones then
                    for _, zone in pairs(data.zones) do
                        if zone == currentZone then
                            validZone = true
                            break
                        end
                    end
                else
                    validZone = true
                end
                
                if validZone then
                    local spawnedCount = 0
                    for _, z in pairs(activeZombies) do
                        if z.Name == typeName then
                            spawnedCount = spawnedCount + 1
                        end
                    end
                    
                    if spawnedCount < data.maxCount then
                        table.insert(availableTypes, typeName)
                    end
                end
            end
        end
        
        if #availableTypes > 0 then
            local selectedType = nil
            
            for _, typeName in pairs(availableTypes) do
                local chance = getSpawnChance(typeName)
                if math.random(1, chance) == 1 then
                    selectedType = typeName
                    break
                end
            end
            
            if not selectedType and #availableTypes > 0 then
                selectedType = availableTypes[math.random(1, #availableTypes)]
            end
            
            if selectedType then
                -- Random spawn position
                local angle = math.random() * math.pi * 2
                local distance = math.random(30, 100)
                local spawnPos = rootPart.Position + Vector3.new(
                    math.cos(angle) * distance,
                    5,
                    math.sin(angle) * distance
                )
                
                createZombie(selectedType, spawnPos)
            end
        end
        
        wait(0.3)
    end
end

function startIntermission()
    isIntermission = true
    local timeLeft = intermissionTime
    
    -- Check if boss wave was cleared
    if currentWave % 10 == 0 then
        maxPlayerHealth = maxPlayerHealth + 200
        playerHealth = maxPlayerHealth
        updateHPBar()
        showAchievement("Boss Defeated! +200 Max HP!")
    end
    
    while timeLeft > 0 do
        waveLabel.Text = "Intermission: " .. timeLeft
        wait(1)
        timeLeft = timeLeft - 1
    end
    
    isIntermission = false
    showUpgradeSelection(false)
end

function showUpgradeSelection(abilityForced)
    upgradeFrame.Visible = true
    
    -- Clear previous buttons
    for _, child in pairs(upgradeFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local options = {}
    
    if abilityForced then
        upgradeTitle.Text = "Choose Your Ability!"
        -- Filter out already selected abilities
        for _, ability in pairs(availableAbilities) do
            local alreadySelected = false
            for _, selected in pairs(selectedAbilities) do
                if selected == ability then
                    alreadySelected = true
                    break
                end
            end
            
            -- Check special requirements
            local meetsRequirements = true
            if ability == "Homing Bounce" and ricochetStacks < 5 then
                meetsRequirements = false
            end
            
            if not alreadySelected and meetsRequirements then
                table.insert(options, ability)
            end
        end
        
        -- Fill remaining slots with upgrades if needed
        while #options < 3 do
            local upgrade = availableUpgrades[math.random(1, #availableUpgrades)]
            table.insert(options, upgrade)
        end
    else
        -- Random upgrades
        local tempUpgrades = {}
        for _, upgrade in pairs(availableUpgrades) do
            table.insert(tempUpgrades, upgrade)
        end
        
        for i = 1, 3 do
            if #tempUpgrades > 0 then
                local index = math.random(1, #tempUpgrades)
                table.insert(options, tempUpgrades[index])
                table.remove(tempUpgrades, index)
            end
        end
    end
    
    -- Shuffle options
    for i = #options, 2, -1 do
        local j = math.random(i)
        options[i], options[j] = options[j], options[i]
    end
    
    -- Take only 3
    while #options > 3 do
        table.remove(options)
    end
    
    -- Create buttons
    for i, option in pairs(options) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 250, 0, 100)
        button.Position = UDim2.new(0.5, -375 + (i - 1) * 275, 0.5, -50)
        button.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.SourceSansBold
        button.TextScaled = true
        button.Text = option
        button.Parent = upgradeFrame
        
        button.MouseButton1Click:Connect(function()
            applyUpgrade(option)
            upgradeFrame.Visible = false
            
            if not abilityForced then
                currentWave = currentWave + 1
                waveLabel.Text = "Wave " .. currentWave
                
                -- Increase zombie HP every wave (changed to 0-0, no increase)
                local hpIncrease = math.random(0, 0)
                waveHpIncrease = waveHpIncrease + hpIncrease
                
                -- Update zombie counts
                local increase = math.random(minZombieIncrease, maxZombieIncrease)
                currentMinZombies = currentMinZombies + minZombieIncrease
                currentMaxZombies = currentMaxZombies + maxZombieIncrease
                minZombieIncrease = minZombieIncrease + 5
                maxZombieIncrease = maxZombieIncrease + 5
                
                spawnWaveZombies()
            end
        end)
    end
end

function applyUpgrade(upgrade)
    if upgrade == "Gun Damage" then
        damageBonus = damageBonus + 5
    elseif upgrade == "Movement Speed" then
        speedBonus = speedBonus + 5
        humanoid.WalkSpeed = playerSpeed + speedBonus
    elseif upgrade == "Max Bullet Increase" then
        maxBullet = maxBullet + 5
        currentBullet = currentBullet + 5
        updateAmmoLabel()
    elseif upgrade == "Max Ammo Increase" then
        maxAmmo = maxAmmo + 7
        currentAmmo = currentAmmo + 7
        updateAmmoLabel()
    elseif upgrade == "Bullet Rate" then
        shootCooldown = math.max(0.1, shootCooldown - 0.2)
    elseif upgrade == "Max Health" then
        maxPlayerHealth = maxPlayerHealth + 20
        playerHealth = playerHealth + 20
        updateHPBar()
    elseif upgrade == "Slowness" then
        slownessStacks = slownessStacks + 1
    elseif upgrade == "Ricochet" then
        ricochetStacks = ricochetStacks + 1
    elseif upgrade == "Bullet Hell" then
        hasBulletHell = true
        table.insert(selectedAbilities, upgrade)
    elseif upgrade == "Explosive Bullet" then
        hasExplosiveBullet = true
        table.insert(selectedAbilities, upgrade)
    elseif upgrade == "Heatseeking" then
        hasHeatseeking = true
        table.insert(selectedAbilities, upgrade)
    elseif upgrade == "Lifesteal" then
        hasLifesteal = true
        table.insert(selectedAbilities, upgrade)
    elseif upgrade == "Fire Bullets" then
        hasFireBullets = true
        table.insert(selectedAbilities, upgrade)
    elseif upgrade == "Homing Bounce" then
        hasHomingBounce = true
        table.insert(selectedAbilities, upgrade)
    elseif upgrade == "Magic Bullet" then
        hasMagicBullet = true
        table.insert(selectedAbilities, upgrade)
    end
end

local function shootBullet()
    if not canShoot or currentBullet <= 0 or isReloading then
        return
    end
    
    canShoot = false
    currentBullet = currentBullet - 1
    updateAmmoLabel()
    
    -- Create bullet
    local isExplosive = hasExplosiveBullet and math.random() <= explosiveBulletChance
    local isFire = hasFireBullets
    local isMolotov = isExplosive and isFire
    
    local bullet = Instance.new("Part")
    bullet.Size = Vector3.new(0.2, 0.2, 1)
    bullet.Position = rootPart.Position + rootPart.CFrame.LookVector * 3
    
    -- Bullet color based on type
    if isMolotov then
        bullet.BrickColor = BrickColor.new("Deep orange")
    elseif isExplosive then
        bullet.BrickColor = BrickColor.new("Really red")
    elseif isFire then
        bullet.BrickColor = BrickColor.new("Deep orange")
    else
        bullet.BrickColor = BrickColor.new("New Yeller")
    end
    
    bullet.Material = Enum.Material.Neon
    bullet.CanCollide = false
    bullet.Anchored = false
    bullet.Parent = workspace
    
    -- Fire trail effect
    if isFire or isMolotov then
        local trail = Instance.new("Trail")
        local att0 = Instance.new("Attachment", bullet)
        local att1 = Instance.new("Attachment", bullet)
        att1.Position = Vector3.new(0, 0, 0.5)
        trail.Attachment0 = att0
        trail.Attachment1 = att1
        trail.Color = ColorSequence.new(Color3.fromRGB(255, 150, 0))
        trail.Lifetime = 0.3
        trail.Parent = bullet
    end
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = rootPart.CFrame.LookVector * 100
    bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
    bodyVelocity.Parent = bullet
    
    local bouncesRemaining = ricochetStacks
    local hitZombies = {}
    
    -- Heatseeking logic
    if hasHeatseeking then
        spawn(function()
            while bullet.Parent do
                local closestZombie = nil
                local closestDistance = 10
                
                for _, zombie in pairs(activeZombies) do
                    if zombie and zombie.PrimaryPart then
                        local alreadyHit = false
                        for _, hz in pairs(hitZombies) do
                            if hz == zombie then
                                alreadyHit = true
                                break
                            end
                        end
                        
                        if not alreadyHit then
                            local distance = (zombie.PrimaryPart.Position - bullet.Position).Magnitude
                            if distance < closestDistance then
                                closestZombie = zombie
                                closestDistance = distance
                            end
                        end
                    end
                end
                
                if closestZombie and closestZombie.PrimaryPart then
                    local targetDirection = (closestZombie.PrimaryPart.Position - bullet.Position).Unit
                    local currentDirection = bodyVelocity.Velocity.Unit
                    local newDirection = (currentDirection + targetDirection * 0.3).Unit
                    bodyVelocity.Velocity = newDirection * 100
                end
                
                wait(0.05)
            end
        end)
    end
    
    -- Bullet hit detection
    local hitConnection
    hitConnection = bullet.Touched:Connect(function(hit)
        if hit.Parent ~= character and hit.Parent:FindFirstChildOfClass("Humanoid") then
            local alreadyHit = false
            for _, hz in pairs(hitZombies) do
                if hz == hit.Parent then
                    alreadyHit = true
                    break
                end
            end
            
            if alreadyHit then
                return
            end
            
            table.insert(hitZombies, hit.Parent)
            
            local totalDamage = bulletDamage + damageBonus
            if hasBulletHell then
                totalDamage = totalDamage + bulletHellStacks
            end
            
            local targetHumanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
            local isFireImmune = zombieTypes[hit.Parent.Name] and zombieTypes[hit.Parent.Name].fireZombie
            
            -- Molotov explosion
            if isMolotov then
                hitConnection:Disconnect()
                createExplosion(bullet.Position, 20, 75, true)
                
                -- Create orange liquid puddle
                local puddle = Instance.new("Part")
                puddle.Size = Vector3.new(60, 0.5, 60)
                puddle.Position = bullet.Position - Vector3.new(0, 2, 0)
                puddle.Anchored = true
                puddle.CanCollide = false
                puddle.Transparency = 0.3
                puddle.Material = Enum.Material.Neon
                puddle.Color = Color3.fromRGB(255, 150, 0)
                puddle.Parent = workspace
                
                -- Puddle burn damage loop
                spawn(function()
                    local puddleStart = tick()
                    while tick() - puddleStart < 10 do
                        -- Check zombies in puddle
                        for _, zombie in pairs(activeZombies) do
                            if zombie and zombie.PrimaryPart then
                                local zDist = (zombie.PrimaryPart.Position - puddle.Position).Magnitude
                                if zDist <= 30 then
                                    local zHum = zombie:FindFirstChildOfClass("Humanoid")
                                    local zIsFireImmune = zombieTypes[zombie.Name] and zombieTypes[zombie.Name].fireZombie
                                    
                                    if zHum and not zIsFireImmune then
                                        -- Apply burning if not already burning
                                        if not zombie:FindFirstChild("Burning") then
                                            local burningTag = Instance.new("BoolValue")
                                            burningTag.Name = "Burning"
                                            burningTag.Parent = zombie
                                            
                                            spawn(function()
                                                for i = 1, 10 do
                                                    wait(0.5)
                                                    if zHum and zHum.Parent and zHum.Health > 0 then
                                                        zHum.Health = zHum.Health - 5
                                                        if hasLifesteal then
                                                            healPlayer(5)
                                                        end
                                                    else
                                                        break
                                                    end
                                                end
                                                if burningTag and burningTag.Parent then
                                                    burningTag:Destroy()
                                                end
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Check player in puddle
                        if rootPart then
                            local playerDist = (rootPart.Position - puddle.Position).Magnitude
                            if playerDist <= 30 then
                                -- Player can get burned too
                                spawn(function()
                                    for i = 1, 6 do
                                        wait(0.5)
                                        damagePlayer(5)
                                    end
                                end)
                            end
                        end
                        
                        wait(0.5)
                    end
                    
                    -- Fade out puddle
                    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(puddle, tweenInfo, {Transparency = 1})
                    tween:Play()
                    wait(2)
                    puddle:Destroy()
                end)
                
                -- Apply fire to all zombies in explosion radius
                for _, zombie in pairs(activeZombies) do
                    if zombie and zombie.PrimaryPart then
                        local distance = (zombie.PrimaryPart.Position - bullet.Position).Magnitude
                        if distance <= 20 then
                            local zHum = zombie:FindFirstChildOfClass("Humanoid")
                            local zIsFireImmune = zombieTypes[zombie.Name] and zombieTypes[zombie.Name].fireZombie
                            
                            if zHum and not zIsFireImmune then
                                -- Apply burning effect
                                spawn(function()
                                    for i = 1, 10 do
                                        wait(0.5)
                                        if zHum and zHum.Parent and zHum.Health > 0 then
                                            zHum.Health = zHum.Health - 5
                                            if hasLifesteal then
                                                healPlayer(5)
                                            end
                                        else
                                            break
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end
                
                if hasLifesteal then
                    healPlayer(75)
                end
                bullet:Destroy()
            -- Regular explosive
            elseif isExplosive then
                hitConnection:Disconnect()
                createExplosion(bullet.Position, 20, 75, true)
                if hasLifesteal then
                    healPlayer(75)
                end
                bullet:Destroy()
            else
                local actualDamage = math.min(totalDamage, targetHumanoid.Health)
                targetHumanoid.Health = targetHumanoid.Health - totalDamage
                
                -- Lifesteal
                if hasLifesteal then
                    healPlayer(actualDamage)
                end
                
                -- Fire effect
                if isFire then
                    if not isFireImmune then
                        spawn(function()
                            for i = 1, 10 do
                                wait(0.5)
                                if targetHumanoid and targetHumanoid.Parent and targetHumanoid.Health > 0 then
                                    targetHumanoid.Health = targetHumanoid.Health - 5
                                    if hasLifesteal then
                                        healPlayer(5)
                                    end
                                else
                                    break
                                end
                            end
                        end)
                    end
                end
                
                -- Ricochet logic
                if bouncesRemaining > 0 then
                    bouncesRemaining = bouncesRemaining - 1
                    
                    -- Find next target
                    local nextTarget = nil
                    local closestDist = math.huge
                    
                    -- Homing Bounce guarantees a target
                    if hasHomingBounce then
                        for _, zombie in pairs(activeZombies) do
                            if zombie and zombie.PrimaryPart and zombie ~= hit.Parent then
                                local hitThis = false
                                for _, hz in pairs(hitZombies) do
                                    if hz == zombie then
                                        hitThis = true
                                        break
                                    end
                                end
                                
                                if not hitThis then
                                    local dist = (zombie.PrimaryPart.Position - bullet.Position).Magnitude
                                    if dist < closestDist then
                                        closestDist = dist
                                        nextTarget = zombie
                                    end
                                end
                            end
                        end
                    else
                        -- Regular ricochet with distance limit
                        for _, zombie in pairs(activeZombies) do
                            if zombie and zombie.PrimaryPart and zombie ~= hit.Parent then
                                local hitThis = false
                                for _, hz in pairs(hitZombies) do
                                    if hz == zombie then
                                        hitThis = true
                                        break
                                    end
                                end
                                
                                if not hitThis then
                                    local dist = (zombie.PrimaryPart.Position - bullet.Position).Magnitude
                                    if dist < closestDist and dist < 30 then
                                        closestDist = dist
                                        nextTarget = zombie
                                    end
                                end
                            end
                        end
                    end
                    
                    if nextTarget and nextTarget.PrimaryPart then
                        -- Bounce to next target (horizontal only)
                        local direction = (nextTarget.PrimaryPart.Position - bullet.Position)
                        direction = Vector3.new(direction.X, 0, direction.Z).Unit
                        bodyVelocity.Velocity = direction * 100
                        bullet.BrickColor = BrickColor.new("Cyan")
                    else
                        hitConnection:Disconnect()
                        bullet:Destroy()
                    end
                else
                    hitConnection:Disconnect()
                    bullet:Destroy()
                end
            end
        end
    end)
    
    game:GetService("Debris"):AddItem(bullet, 3)
    
    wait(shootCooldown)
    canShoot = true
end

local function reloadGun()
    if isReloading or currentAmmo <= 0 or currentBullet >= maxBullet then
        return
    end
    
    isReloading = true
    wait(reloadTime)
    
    local ammoNeeded = maxBullet - currentBullet
    local ammoToUse = math.min(ammoNeeded, ammoPerReload, currentAmmo)
    
    currentBullet = currentBullet + ammoToUse
    currentAmmo = currentAmmo - ammoToUse
    
    updateAmmoLabel()
    isReloading = false
end

-- Gun equipped handling
gun.Equipped:Connect(function()
    gunEquipped = true
    ammoLabel.Visible = true
    shootButton.Visible = true
    updateAmmoLabel()
end)

gun.Unequipped:Connect(function()
    gunEquipped = false
    ammoLabel.Visible = false
    shootButton.Visible = false
    isShooting = false
end)

-- Shoot button handling
local shootButtonConnection
shootButton.MouseButton1Down:Connect(function()
    isShooting = true
    while isShooting and gunEquipped do
        if currentBullet > 0 then
            shootBullet()
        else
            reloadGun()
            break
        end
        wait(0.1)
    end
end)

shootButton.MouseButton1Up:Connect(function()
    isShooting = false
end)

-- Skip Wave Button
skipWaveButton.MouseButton1Click:Connect(function()
    if not isIntermission then
        -- Kill all zombies
        for _, zombie in pairs(activeZombies) do
            if zombie and zombie:FindFirstChildOfClass("Humanoid") then
                zombie:FindFirstChildOfClass("Humanoid").Health = 0
            end
        end
        zombiesRemaining = 0
        activeZombies = {}
    end
end)

-- Ability Choose Button
abilityChooseButton.MouseButton1Click:Connect(function()
    if not upgradeFrame.Visible then
        showUpgradeSelection(true)
    end
end)

-- Upgrade Choose Button
upgradeChooseButton.MouseButton1Click:Connect(function()
    if not upgradeFrame.Visible then
        showUpgradeSelection(false)
    end
end)

-- Zombie Spawner Button
zombieSpawnerButton.MouseButton1Click:Connect(function()
    zombieSpawnerFrame.Visible = not zombieSpawnerFrame.Visible
end)

-- Close Spawner Button
closeSpawnerButton.MouseButton1Click:Connect(function()
    zombieSpawnerFrame.Visible = false
end)

-- Spawn Confirm Button
spawnConfirmButton.MouseButton1Click:Connect(function()
    if not selectedZombieType then
        return
    end
    
    local amount = tonumber(amountInput.Text)
    if not amount or amount < 1 then
        amount = 1
    end
    
    amount = math.floor(amount)
    
    -- Spawn the zombies
    for i = 1, amount do
        local angle = math.random() * math.pi * 2
        local distance = math.random(30, 100)
        local spawnPos = rootPart.Position + Vector3.new(
            math.cos(angle) * distance,
            5,
            math.sin(angle) * distance
        )
        
        createZombie(selectedZombieType, spawnPos)
        zombiesRemaining = zombiesRemaining + 1
        
        wait(0.1)
    end
end)

-- Skip to Wave Button
skipToWaveButton.MouseButton1Click:Connect(function()
    skipWaveFrame.Visible = not skipWaveFrame.Visible
end)

-- Close Skip Wave Button
closeSkipButton.MouseButton1Click:Connect(function()
    skipWaveFrame.Visible = false
end)

-- Confirm Skip Button
confirmSkipButton.MouseButton1Click:Connect(function()
    local targetWave = tonumber(waveInput.Text)
    if not targetWave or targetWave < 1 then
        return
    end
    
    targetWave = math.floor(targetWave)
    
    -- Kill all zombies
    for _, zombie in pairs(activeZombies) do
        if zombie and zombie:FindFirstChildOfClass("Humanoid") then
            zombie:Destroy()
        end
    end
    activeZombies = {}
    zombiesRemaining = 0
    
    -- Update wave
    currentWave = targetWave
    waveLabel.Text = "Wave " .. currentWave
    
    -- Close the frame
    skipWaveFrame.Visible = false
    
    -- Start new wave
    wait(1)
    spawnWaveZombies()
end)

-- Auto reload when out of bullets
spawn(function()
    while wait(0.5) do
        if gunEquipped and currentBullet <= 0 and currentAmmo > 0 and not isReloading then
            reloadGun()
        end
    end
end)

-- Give gun to player
gun.Parent = player.Backpack

-- Character respawn handling
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    
    playerHealth = maxPlayerHealth
    updateHPBar()
    
    humanoid.WalkSpeed = playerSpeed + speedBonus
    
    -- Give gun again
    if gun.Parent ~= player.Backpack and gun.Parent ~= character then
        gun.Parent = player.Backpack
    end
end)

-- Health monitoring
humanoid.HealthChanged:Connect(function(health)
    if health <= 0 then
        -- Game over logic
        wait(3)
        
        -- Reset game
        currentWave = 1
        zombiesRemaining = 0
        playerHealth = 100
        maxPlayerHealth = 100
        playerSpeed = 16
        
        currentBullet = 10
        maxBullet = 10
        currentAmmo = 50
        maxAmmo = 50
        bulletDamage = 10
        shootCooldown = 1
        
        damageBonus = 0
        speedBonus = 0
        hasBulletHell = false
        bulletHellStacks = 0
        hasExplosiveBullet = false
        
        currentMinZombies = 10
        currentMaxZombies = 10
        minZombieIncrease = 5
        maxZombieIncrease = 10
        
        selectedAbilities = {}
        
        for _, zombie in pairs(activeZombies) do
            if zombie and zombie.Parent then
                zombie:Destroy()
            end
        end
        activeZombies = {}
        
        waveLabel.Text = "Wave 1"
        updateHPBar()
        updateAmmoLabel()
        
        if character and character.Parent then
            humanoid.Health = humanoid.MaxHealth
            playerHealth = maxPlayerHealth
            updateHPBar()
        end
    end
end)

-- Continuous HP sync
spawn(function()
    while wait(0.1) do
        if humanoid and humanoid.Health > 0 then
            humanoid.Health = (playerHealth / maxPlayerHealth) * humanoid.MaxHealth
        end
    end
end)

-- Input handling for reload
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.R and gunEquipped then
        reloadGun()
    end
end)

-- Start game
wait(2)
waveLabel.Text = "Wave 1"
spawnWaveZombies()

-- Game loop
spawn(function()
    while wait(1) do
        -- Check if all zombies are dead
        if zombiesRemaining <= 0 and not isIntermission and #activeZombies == 0 then
            startIntermission()
        end
    end
end)

-- Zombie cleanup loop
spawn(function()
    while wait(5) do
        for i = #activeZombies, 1, -1 do
            local zombie = activeZombies[i]
            if not zombie or not zombie.Parent or not zombie:FindFirstChildOfClass("Humanoid") or 
               zombie:FindFirstChildOfClass("Humanoid").Health <= 0 then
                table.remove(activeZombies, i)
                if zombie and zombie.Parent then
                    zombie:Destroy()
                end
            end
        end
    end
end)

-- Performance optimization: Limit active zombies render distance
spawn(function()
    while wait(0.5) do
        for _, zombie in pairs(activeZombies) do
            if zombie and zombie.PrimaryPart and rootPart then
                local distance = (zombie.PrimaryPart.Position - rootPart.Position).Magnitude
                
                -- Hide zombies too far away
                for _, part in pairs(zombie:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if distance > 200 then
                            part.Transparency = 1
                        else
                            local originalTransparency = 0
                            if zombie.Name == "Explosive" and part.Name ~= "Head" then
                                originalTransparency = 0
                            end
                            part.Transparency = originalTransparency
                        end
                    end
                end
            end
        end
    end
end)

-- Wave difficulty scaling
local function calculateWaveDifficulty()
    if currentWave >= 20 then
        -- Extreme difficulty
        for typeName, data in pairs(zombieTypes) do
            data.hp = data.hp * 1.1
            data.damage = data.damage * 1.05
        end
    elseif currentWave >= 15 then
        -- Very hard
        for typeName, data in pairs(zombieTypes) do
            data.hp = data.hp * 1.05
            data.damage = data.damage * 1.03
        end
    elseif currentWave >= 10 then
        -- Hard
        for typeName, data in pairs(zombieTypes) do
            data.speed = data.speed * 1.02
        end
    end
end

-- Apply difficulty every wave
spawn(function()
    while wait(1) do
        if not isIntermission then
            calculateWaveDifficulty()
        end
    end
end)

-- Achievement system (visual notifications)
local achievementFrame = Instance.new("Frame")
achievementFrame.Size = UDim2.new(0, 300, 0, 80)
achievementFrame.Position = UDim2.new(0.5, -150, 0, -100)
achievementFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
achievementFrame.BorderSizePixel = 2
achievementFrame.Parent = screenGui

local achievementLabel = Instance.new("TextLabel")
achievementLabel.Size = UDim2.new(1, -10, 1, -10)
achievementLabel.Position = UDim2.new(0, 5, 0, 5)
achievementLabel.BackgroundTransparency = 1
achievementLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
achievementLabel.Font = Enum.Font.SourceSansBold
achievementLabel.TextScaled = true
achievementLabel.TextWrapped = true
achievementLabel.Parent = achievementFrame

local function showAchievement(text)
    achievementLabel.Text = text
    achievementFrame:TweenPosition(
        UDim2.new(0.5, -150, 0, 20),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Bounce,
        0.5,
        true
    )
    
    wait(3)
    
    achievementFrame:TweenPosition(
        UDim2.new(0.5, -150, 0, -100),
        Enum.EasingDirection.In,
        Enum.EasingStyle.Quad,
        0.3,
        true
    )
end

-- Track achievements
local achievementsUnlocked = {}

spawn(function()
    while wait(1) do
        -- Wave milestones
        if currentWave == 5 and not achievementsUnlocked["wave5"] then
            showAchievement("Wave 5 Survived!")
            achievementsUnlocked["wave5"] = true
        elseif currentWave == 10 and not achievementsUnlocked["wave10"] then
            showAchievement("Wave 10 Conquered!")
            achievementsUnlocked["wave10"] = true
        elseif currentWave == 20 and not achievementsUnlocked["wave20"] then
            showAchievement("Wave 20 Mastered!")
            achievementsUnlocked["wave20"] = true
        end
        
        -- Kill streaks
        if bulletHellStacks >= 50 and not achievementsUnlocked["kills50"] then
            showAchievement("50 Kills Streak!")
            achievementsUnlocked["kills50"] = true
        elseif bulletHellStacks >= 100 and not achievementsUnlocked["kills100"] then
            showAchievement("100 Kills Streak!")
            achievementsUnlocked["kills100"] = true
        end
    end
end)

-- Visual effects for player damage
local damageOverlay = Instance.new("Frame")
damageOverlay.Size = UDim2.new(1, 0, 1, 0)
damageOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
damageOverlay.BackgroundTransparency = 1
damageOverlay.BorderSizePixel = 0
damageOverlay.ZIndex = 10
damageOverlay.Parent = screenGui

local originalDamagePlayer = damagePlayer
damagePlayer = function(damage)
    originalDamagePlayer(damage)
    
    -- Flash red
    damageOverlay.BackgroundTransparency = 0.5
    local tween = TweenService:Create(
        damageOverlay,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )
    tween:Play()
    
    -- Magic Bullet trigger
    if hasMagicBullet and playerHealth < 50 and math.random() <= 0.5 then
        spawn(function()
            for _, zombie in pairs(activeZombies) do
                if zombie and zombie.PrimaryPart then
                    local zHum = zombie:FindFirstChildOfClass("Humanoid")
                    if zHum and zHum.Health > 0 then
                        -- Create blue portal
                        local portal = Instance.new("Part")
                        portal.Size = Vector3.new(3, 3, 0.5)
                        portal.Position = zombie.PrimaryPart.Position + (zombie.PrimaryPart.CFrame.LookVector * 15)
                        portal.Anchored = true
                        portal.CanCollide = false
                        portal.Material = Enum.Material.Neon
                        portal.Color = Color3.fromRGB(0, 100, 255)
                        portal.Transparency = 0.3
                        portal.Parent = workspace
                        
                        -- Make it face the zombie
                        portal.CFrame = CFrame.new(portal.Position, zombie.PrimaryPart.Position)
                        
                        wait(3)
                        
                        -- Fire black bullet
                        if zombie.Parent and zHum.Health > 0 then
                            local magicBullet = Instance.new("Part")
                            magicBullet.Size = Vector3.new(0.5, 0.5, 2)
                            magicBullet.Position = portal.Position
                            magicBullet.BrickColor = BrickColor.new("Really black")
                            magicBullet.Material = Enum.Material.Neon
                            magicBullet.CanCollide = false
                            magicBullet.Anchored = false
                            magicBullet.Parent = workspace
                            
                            -- Trail effect
                            local trail = Instance.new("Trail")
                            local att0 = Instance.new("Attachment", magicBullet)
                            local att1 = Instance.new("Attachment", magicBullet)
                            att1.Position = Vector3.new(0, 0, 1)
                            trail.Attachment0 = att0
                            trail.Attachment1 = att1
                            trail.Color = ColorSequence.new(Color3.fromRGB(100, 0, 255))
                            trail.Lifetime = 0.5
                            trail.Parent = magicBullet
                            
                            local direction = (zombie.PrimaryPart.Position - magicBullet.Position).Unit
                            local bodyVelocity = Instance.new("BodyVelocity")
                            bodyVelocity.Velocity = direction * 150
                            bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                            bodyVelocity.Parent = magicBullet
                            
                            local hitConnection
                            hitConnection = magicBullet.Touched:Connect(function(hit)
                                if hit.Parent == zombie then
                                    hitConnection:Disconnect()
                                    local magicDamage = math.random(120, 250)
                                    zHum.Health = zHum.Health - magicDamage
                                    
                                    if hasLifesteal then
                                        healPlayer(magicDamage)
                                    end
                                    
                                    magicBullet:Destroy()
                                end
                            end)
                            
                            game:GetService("Debris"):AddItem(magicBullet, 3)
                        end
                        
                        portal:Destroy()
                    end
                end
                
                wait(0.05)
            end
        end)
    end
end

-- Mobile controls optimization
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    shootButton.Size = UDim2.new(0, 120, 0, 120)
    shootButton.Position = UDim2.new(1, -140, 1, -140)
    
    -- Add reload button for mobile
    local reloadButton = Instance.new("TextButton")
    reloadButton.Size = UDim2.new(0, 80, 0, 80)
    reloadButton.Position = UDim2.new(1, -140, 1, -240)
    reloadButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    reloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    reloadButton.Font = Enum.Font.SourceSansBold
    reloadButton.TextScaled = true
    reloadButton.Text = "RELOAD"
    reloadButton.Visible = false
    reloadButton.Parent = screenGui
    
    gun.Equipped:Connect(function()
        reloadButton.Visible = true
    end)
    
    gun.Unequipped:Connect(function()
        reloadButton.Visible = false
    end)
    
    reloadButton.MouseButton1Click:Connect(function()
        reloadGun()
    end)
end

-- Stats display (toggle with Tab key)
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(0, 300, 0, 400)
statsFrame.Position = UDim2.new(0, 10, 0, 70)
statsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statsFrame.BackgroundTransparency = 0.5
statsFrame.Visible = false
statsFrame.Parent = screenGui

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -10, 1, -10)
statsLabel.Position = UDim2.new(0, 5, 0, 5)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.Font = Enum.Font.SourceSans
statsLabel.TextSize = 18
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.TextWrapped = true
statsLabel.Parent = statsFrame

local function updateStats()
    local statsText = string.format([[
=== PLAYER STATS ===
Wave: %d
HP: %d/%d
Speed: %d

=== GUN STATS ===
Damage: %d
Fire Rate: %.2fs
Max Bullets: %d
Max Ammo: %d

=== ABILITIES ===
%s
Bullet Hell Stacks: %d

=== ZOMBIES ===
Active: %d
Remaining: %d
    ]],
        currentWave,
        math.floor(playerHealth), maxPlayerHealth,
        playerSpeed + speedBonus,
        bulletDamage + damageBonus + (hasBulletHell and bulletHellStacks or 0),
        shootCooldown,
        maxBullet,
        maxAmmo,
        table.concat(selectedAbilities, ", "),
        bulletHellStacks,
        #activeZombies,
        zombiesRemaining
    )
    
    statsLabel.Text = statsText
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Tab then
        statsFrame.Visible = not statsFrame.Visible
        if statsFrame.Visible then
            updateStats()
        end
    end
end)

spawn(function()
    while wait(0.5) do
        if statsFrame.Visible then
            updateStats()
        end
    end
end)

-- Zombie spawn position validation
local function isValidSpawnPosition(position)
    local region = Region3.new(position - Vector3.new(5, 5, 5), position + Vector3.new(5, 5, 5))
    region = region:ExpandToGrid(4)
    
    local parts = workspace:FindPartsInRegion3(region, nil, 100)
    
    for _, part in pairs(parts) do
        if part:IsA("Terrain") or (part:IsA("BasePart") and part.CanCollide) then
            return false
        end
    end
    
    return true
end

-- Enhanced zombie spawning with validation
local originalSpawnWaveZombies = spawnWaveZombies
spawnWaveZombies = function()
    local zombieCount = math.random(currentMinZombies, currentMaxZombies)
    zombiesRemaining = zombieCount
    
    for i = 1, zombieCount do
        local availableTypes = {}
        for typeName, data in pairs(zombieTypes) do
            if currentWave >= data.introducedWave then
                local spawnedCount = 0
                for _, z in pairs(activeZombies) do
                    if z.Name == typeName then
                        spawnedCount = spawnedCount + 1
                    end
                end
                
                if spawnedCount < data.maxCount then
                    table.insert(availableTypes, typeName)
                end
            end
        end
        
        if #availableTypes > 0 then
            local selectedType = nil
            
            for _, typeName in pairs(availableTypes) do
                local chance = getSpawnChance(typeName)
                if math.random(1, chance) == 1 then
                    selectedType = typeName
                    break
                end
            end
            
            if not selectedType then
                selectedType = "Zombie"
            end
            
            local spawnPos
            local attempts = 0
            repeat
                local angle = math.random() * math.pi * 2
                local distance = math.random(30, 100)
                spawnPos = rootPart.Position + Vector3.new(
                    math.cos(angle) * distance,
                    5,
                    math.sin(angle) * distance
                )
                attempts = attempts + 1
            until attempts >= 10
            
            createZombie(selectedType, spawnPos)
        end
        
        wait(0.3)
    end
end

-- Warning system for low health/ammo
local warningLabel = Instance.new("TextLabel")
warningLabel.Size = UDim2.new(0, 400, 0, 60)
warningLabel.Position = UDim2.new(0.5, -200, 0.3, 0)
warningLabel.BackgroundTransparency = 1
warningLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
warningLabel.Font = Enum.Font.SourceSansBold
warningLabel.TextScaled = true
warningLabel.Text = ""
warningLabel.Visible = false
warningLabel.Parent = screenGui

spawn(function()
    while wait(1) do
        if playerHealth < maxPlayerHealth * 0.3 then
            warningLabel.Text = "LOW HEALTH!"
            warningLabel.Visible = true
        elseif currentAmmo == 0 and currentBullet == 0 then
            warningLabel.Text = "OUT OF AMMO!"
            warningLabel.Visible = true
        else
            warningLabel.Visible = false
        end
    end
end)

-- Sound effects (optional, if you want to add sounds)
local function playSound(soundId, volume)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Volume = volume or 0.5
    sound.Parent = rootPart
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 5)
end

-- Final initialization
print("Zombie Apocalypse Script Loaded!")
print("Press Tab to view stats")
print("Press R to reload")
print("Good luck, survivor!")

-- Anti-AFK
spawn(function()
    while wait(300) do
        if humanoid then
            humanoid:Move(Vector3.new(0, 0, 0))
        end
    end
end)
