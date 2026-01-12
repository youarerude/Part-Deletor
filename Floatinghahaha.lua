local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Player Stats
local playerStats = {
    hp = 100,
    maxHp = 100,
    sp = 100,
    maxSp = 100,
    pure = 100,
    maxPure = 100,
    currentSuit = "Standard Uniform",
    currentWeapon = "Baton",
    burning = false,
    burnTick = 0
}

-- Damage Type Colors
local damageColors = {
    Red = Color3.fromRGB(255, 0, 0),
    Blue = Color3.fromRGB(0, 100, 255),
    Purple = Color3.fromRGB(150, 0, 255),
    Black = Color3.fromRGB(100, 100, 100)
}

-- Illusion Data
local illusionData = {
    GroundCrawler = {
        description = "It crawls under ground like it owns this place...",
        hp = 145,
        sp = 150,
        pure = 100,
        crawlSpeed = 17,
        attackRange = 10,
        attackCooldown = 5,
        damageReductions = {Red = 0.8, Blue = 1, Purple = 2, Black = 2},
        damageType = "Red",
        damageScale = {2, 5},
        dangerClass = "TETH",
        enabled = false
    },
    Scorcher = {
        description = "a familiar burnt house as the man saw, and suddenly memories of the good times came pouring out... Ah yes the agony...",
        hp = 300,
        sp = 250,
        pure = 100,
        walkSpeed = 12,
        attackRange = 10,
        attackCooldown = 3,
        damageReductions = {Red = 0.9, Blue = 0.9, Purple = 0.6, Black = 1.6},
        damageType = "Black",
        damageScale = {5, 9},
        dangerClass = "HE",
        enabled = false
    },
    Schadenfreude = {
        description = "No matter what you've done DO NOT LOOK AT IT. Its highly dangerous and might blind you.",
        hp = 555,
        sp = 675,
        pure = 499,
        walkSpeed = 14,
        attackRange = 10,
        attackCooldown = 4,
        damageReductions = {Red = 0.6, Blue = 0.4, Purple = 0.9, Black = 1.5},
        damageType = "Blue",
        damageScale = {15, 23},
        dangerClass = "WAW",
        enabled = false
    },
    Mimicry = {
        description = "Suddenly, a cry for help echoes in the hallway. \"Manager help me!\"",
        hp = 950,
        sp = 900,
        pure = 1055,
        walkSpeed = 18,
        attackRange = 10,
        attackCooldown = 5,
        damageReductions = {Red = 0.3, Blue = 0.5, Purple = 0.6, Black = 0.6},
        damageType = "Black",
        damageScale = {14, 27},
        dangerClass = "ALEPH",
        enabled = false,
        phase = 1,
        attackCount = 0
    },
    ["Small Wolf"] = {
        description = "A small wolf that follows the player relentlessly.",
        hp = 444,
        sp = 250,
        pure = 300,
        walkSpeed = 16,
        attackRange = 10,
        attackCooldown = 2,
        damageReductions = {Red = 0.5, Blue = 0.7, Purple = 1, Black = 1.1},
        damageType = "Red",
        damageScale = {6, 13},
        dangerClass = "HE",
        enabled = false,
        speedBoostTimer = 0,
        isSpeedBoosted = false
    },
    ["Wide Wolf"] = {
        description = "A wide wolf carrying a radio signal on its back.",
        hp = 760,
        sp = 899,
        pure = 722,
        walkSpeed = 14,
        attackRange = 10,
        attackCooldown = 3,
        damageReductions = {Red = 0.7, Blue = 0.3, Purple = 0.7, Black = 0.9},
        damageType = "Blue",
        damageScale = {8, 15},
        dangerClass = "WAW",
        enabled = false,
        pulseTimer = 0,
        beamTimer = 0
    },
    ["Long Wolf"] = {
        description = "A long wolf wearing a coat, surrounded by dark fog.",
        hp = 800,
        sp = 810,
        pure = 780,
        walkSpeed = 15,
        attackRange = 10,
        attackCooldown = 3,
        damageReductions = {Red = 0.7, Blue = 0.7, Purple = 0.1, Black = 0.8},
        damageType = "Purple",
        damageScale = {10, 18},
        dangerClass = "WAW",
        enabled = false,
        coatTimer = 0,
        fogSize = 50,
        fogDamageMultiplier = 1,
        maxFogSize = 100,
        maxFogMultiplier = 10
    },
    ["Big Wolf"] = {
        description = "A big wolf with a mirror on its back that reflects attacks.",
        hp = 1050,
        sp = 1000,
        pure = 1750,
        walkSpeed = 13,
        attackRange = 10,
        attackCooldown = 3,
        damageReductions = {Red = 0.5, Blue = 0.5, Purple = 0.5, Black = 0.05},
        damageType = "Black",
        damageScale = {45, 75},
        dangerClass = "ALEPH",
        enabled = false,
        reflectChance = 0.25,
        mirrorMode = false,
        mirrorTimer = 0
    },
    ["Disaster Wolf"] = {
        description = "The legendary disaster wolf born from all four wolves.",
        hp = 15000,
        sp = 0,
        pure = 0,
        walkSpeed = 0,
        attackRange = 0,
        attackCooldown = 999,
        damageReductions = {Red = 0.0, Blue = 0.0, Purple = 0.0, Black = 0.0},
        damageType = "Black",
        damageScale = {0, 0},
        dangerClass = "ALEPH",
        enabled = false,
        canAttack = false
    }
}

-- Suit Data
local suitData = {
    ["Standard Uniform"] = {
        reductions = {Red = 1, Blue = 1, Purple = 1.5, Black = 2},
        dangerClass = "TETH",
        enabled = true
    },
    ["Ground Suit"] = {
        reductions = {Red = 0.8, Blue = 1.3, Purple = 1.5, Black = 1.9},
        dangerClass = "TETH",
        enabled = false
    },
    ["3rd Match Suit"] = {
        reductions = {Red = 0.9, Blue = 0.9, Purple = 1, Black = 2},
        dangerClass = "HE",
        enabled = false
    },
    ["Sublock Suit"] = {
        reductions = {Red = 0.6, Blue = 0.2, Purple = 0.8, Black = 1},
        dangerClass = "WAW",
        enabled = false
    },
    ["Mimic Art Suit"] = {
        reductions = {Red = 0.2, Blue = 0.5, Purple = 0.6, Black = 0.3},
        dangerClass = "ALEPH",
        enabled = false,
        absorbChance = 0.3
    }
}

-- Weapon Data
local weaponData = {
    Baton = {
        damageType = "Red",
        damageScale = {1, 3},
        cooldown = 3,
        dangerClass = "TETH",
        hitSound = "rbxassetid://128679366092068"
    },
    Ground = {
        damageType = "Red",
        damageScale = {3, 7},
        cooldown = 4,
        dangerClass = "TETH",
        hitSound = "rbxassetid://8595980577"
    },
    ["3rd Match"] = {
        damageType = "Purple",
        damageScale = {20, 35},
        cooldown = 25,
        dangerClass = "HE",
        hitSound = "rbxassetid://95567505981991"
    },
    Sublock = {
        damageType = "Blue",
        damageScale = {5, 10},
        cooldown = 3,
        dangerClass = "WAW",
        hitSound = "rbxassetid://117297744119258",
        attackActiveSound = "rbxassetid://137396441027315",
        special = true,
        attackCount = 0
    },
    ["Mimic Art"] = {
        damageType = "Black",
        damageScale = {25, 53},
        cooldown = 4,
        dangerClass = "ALEPH",
        hitSound = "rbxassetid://136833367092810",
        abilityHitSound = "rbxassetid://102362803607982",
        abilityActivateSound = "rbxassetid://72209573879445",
        special = true,
        abilityCooldown = 30,
        abilityReady = true,
        dashSpeed = 15,
        dashDuration = 1
    }
}

local activeIllusions = {}
local weaponTools = {}
local attackCooldown = false
local playerBlinded = false
local lookingAtSchadenfreude = false
local schadenfreudeLoopSound = nil
local mimicArtAbilityGui = nil
local elkCityPortal = nil
local disasterWolfEvent = {
    active = false,
    completed = false,
    wolvesEntered = {},
    dialogueGui = nil,
    currentDialogue = "",
    typingIndex = 0
}
local eggIllusions = {}

-- GUI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IllusionSystemGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Create Bars (Top Right)
local function createBar(name, color, position)
    local frame = Instance.new("Frame")
    frame.Name = name .. "Frame"
    frame.Size = UDim2.new(0, 200, 0, 25)
    frame.Position = position
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 2
    frame.Parent = screenGui
    
    local bar = Instance.new("Frame")
    bar.Name = name .. "Bar"
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel = 0
    bar.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name .. ": 100/100"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    return frame, bar, label
end

local hpFrame, hpBar, hpLabel = createBar("HP", Color3.fromRGB(255, 50, 50), UDim2.new(1, -220, 0, 20))
local spFrame, spBar, spLabel = createBar("SP", Color3.fromRGB(50, 150, 255), UDim2.new(1, -220, 0, 55))
local pureFrame, pureBar, pureLabel = createBar("PURE", Color3.fromRGB(255, 255, 100), UDim2.new(1, -220, 0, 90))

-- Update Bars Function
local function updateBars()
    local hpPercent = playerStats.hp / playerStats.maxHp
    local spPercent = playerStats.sp / playerStats.maxSp
    local purePercent = playerStats.pure / playerStats.maxPure
    
    hpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
    spBar.Size = UDim2.new(spPercent, 0, 1, 0)
    pureBar.Size = UDim2.new(purePercent, 0, 1, 0)
    
    hpLabel.Text = string.format("HP: %.0f/%.0f", playerStats.hp, playerStats.maxHp)
    spLabel.Text = string.format("SP: %.0f/%.0f", playerStats.sp, playerStats.maxSp)
    pureLabel.Text = string.format("PURE: %.0f/%.0f", playerStats.pure, playerStats.maxPure)
end

-- Get Damage Multiplier from Pure
local function getPureMultiplier()
    local purePercent = playerStats.pure / playerStats.maxPure
    if purePercent <= 0 then
        return 11
    else
        return 1 + (1 - purePercent) * 10
    end
end

-- Get Damage Category
local function getDamageCategory(damage)
    if damage <= -6 then return "SPAGHETTIFIED"
    elseif damage <= -0.1 then return "ABSORB"
    elseif damage <= 0.1 then return "IMMUNE"
    elseif damage <= 0.5 then return "RESISTANT"
    elseif damage <= 1.5 then return "WEAK"
    elseif damage <= 10 then return "NORMAL"
    elseif damage <= 45 then return "VULNERABLE"
    elseif damage <= 70 then return "STRONG"
    else return "POWERFUL"
    end
end

-- Get Sound ID for Damage Category
local function getDamageSound(category)
    if category == "SPAGHETTIFIED" or category == "ABSORB" then
        return "rbxassetid://138177235392363"
    elseif category == "IMMUNE" then
        return "rbxassetid://9116521883"
    elseif category == "RESISTANT" or category == "WEAK" then
        return "rbxassetid://76525344270919"
    elseif category == "NORMAL" then
        return "rbxassetid://7837536770"
    elseif category == "VULNERABLE" or category == "STRONG" then
        return "rbxassetid://82176913611683"
    elseif category == "POWERFUL" then
        return "rbxassetid://8164951181"
    end
end

-- Create 3D Damage GUI
local function create3DDamageGui(position, damage, damageType, category)
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.Position = position + Vector3.new(0, 3, 0)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Parent = workspace
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 300, 0, 100)
    billboardGui.Adornee = part
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = part
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = string.format("%s! %.1f %s Damage", category, math.abs(damage), damageType)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0.5
    textLabel.Parent = billboardGui
    
    -- Set text color based on damage type
    if damageType == "Red" then
        textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    elseif damageType == "Blue" then
        textLabel.TextColor3 = Color3.fromRGB(0, 100, 255)
    elseif damageType == "Purple" then
        textLabel.TextColor3 = Color3.fromRGB(150, 0, 255)
    elseif damageType == "Black" then
        textLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    
    -- Play sound
    local sound = Instance.new("Sound")
    sound.SoundId = getDamageSound(category)
    sound.Volume = 0.5
    sound.Parent = part
    sound:Play()
    
    -- Animate up and fade
    local tween = TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Linear), {Position = part.Position + Vector3.new(0, 5, 0)})
    tween:Play()
    
    local fadeTween = TweenService:Create(textLabel, TweenInfo.new(2, Enum.EasingStyle.Linear), {TextTransparency = 1})
    fadeTween:Play()
    
    task.delay(2.5, function()
        part:Destroy()
    end)
end

-- Apply Damage to Player
local function damagePlayer(damageAmount, damageType)
    local currentSuit = playerStats.currentSuit
    local reduction = 1
    
    if currentSuit and suitData[currentSuit] then
        -- Mimic Art Suit special: 30% chance to absorb
        if currentSuit == "Mimic Art Suit" and suitData[currentSuit].absorbChance then
            if math.random() < suitData[currentSuit].absorbChance then
                reduction = -0.5
            else
                reduction = suitData[currentSuit].reductions[damageType] or 1
            end
        else
            reduction = suitData[currentSuit].reductions[damageType] or 1
        end
    end
    
    local finalDamage = damageAmount * reduction
    
    -- Apply SP penalty if SP is 0
    if playerStats.sp <= 0 then
        finalDamage = finalDamage * 0.5
    end
    
    local category = getDamageCategory(finalDamage)
    
    -- Mimic Art Suit lifesteal
    if currentSuit == "Mimic Art Suit" and finalDamage < 0 then
        local heal = math.abs(finalDamage)
        if damageType == "Red" then
            playerStats.hp = math.min(playerStats.maxHp, playerStats.hp + heal)
            playerStats.pure = math.min(playerStats.maxPure, playerStats.pure + heal)
        elseif damageType == "Blue" then
            playerStats.sp = math.min(playerStats.maxSp, playerStats.sp + heal)
        elseif damageType == "Purple" then
            playerStats.hp = math.min(playerStats.maxHp, playerStats.hp + heal)
            playerStats.sp = math.min(playerStats.maxSp, playerStats.sp + heal)
            playerStats.pure = math.min(playerStats.maxPure, playerStats.pure + heal)
        elseif damageType == "Black" then
            playerStats.hp = math.min(playerStats.maxHp, playerStats.hp + heal)
            playerStats.pure = math.min(playerStats.maxPure, playerStats.pure + heal)
        end
    else
        if damageType == "Red" then
            playerStats.hp = math.max(0, playerStats.hp - finalDamage)
        elseif damageType == "Blue" then
            playerStats.sp = math.max(0, playerStats.sp - finalDamage)
        elseif damageType == "Purple" then
            playerStats.hp = math.max(0, playerStats.hp - finalDamage)
            playerStats.sp = math.max(0, playerStats.sp - finalDamage)
        elseif damageType == "Black" then
            playerStats.hp = math.max(0, playerStats.hp - finalDamage)
            playerStats.pure = math.max(0, playerStats.pure - finalDamage * 0.5)
        end
    end
    
    updateBars()
    create3DDamageGui(hrp.Position, finalDamage, damageType, category)
    
    -- Check if player died
    if playerStats.hp <= 0 then
        humanoid.Health = 0
        print("You died!")
    end
    
    -- Apply speed penalty if SP is 0
    if playerStats.sp <= 0 then
        humanoid.WalkSpeed = 8
    else
        humanoid.WalkSpeed = 16
    end
end

-- Create Illusion Menu Button
local illusionButton = Instance.new("TextButton")
illusionButton.Size = UDim2.new(0, 100, 0, 40)
illusionButton.Position = UDim2.new(0, 20, 0, 20)
illusionButton.Text = "Illusion"
illusionButton.Font = Enum.Font.GothamBold
illusionButton.TextScaled = true
illusionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
illusionButton.TextColor3 = Color3.new(1, 1, 1)
illusionButton.Parent = screenGui

-- Create Suit Menu Button
local suitButton = Instance.new("TextButton")
suitButton.Size = UDim2.new(0, 100, 0, 40)
suitButton.Position = UDim2.new(0, 130, 0, 20)
suitButton.Text = "Suit"
suitButton.Font = Enum.Font.GothamBold
suitButton.TextScaled = true
suitButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
suitButton.TextColor3 = Color3.new(1, 1, 1)
suitButton.Parent = screenGui

-- Create Weapon Menu Button
local weaponButton = Instance.new("TextButton")
weaponButton.Size = UDim2.new(0, 100, 0, 40)
weaponButton.Position = UDim2.new(0, 240, 0, 20)
weaponButton.Text = "Weapon"
weaponButton.Font = Enum.Font.GothamBold
weaponButton.TextScaled = true
weaponButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
weaponButton.TextColor3 = Color3.new(1, 1, 1)
weaponButton.Parent = screenGui

-- Illusion Menu
local illusionMenu = Instance.new("Frame")
illusionMenu.Size = UDim2.new(0, 500, 0, 400)
illusionMenu.Position = UDim2.new(0.5, -250, 0.5, -200)
illusionMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
illusionMenu.BorderSizePixel = 2
illusionMenu.Visible = false
illusionMenu.Parent = screenGui

local illusionTitle = Instance.new("TextLabel")
illusionTitle.Size = UDim2.new(1, 0, 0, 40)
illusionTitle.Text = "Illusions"
illusionTitle.Font = Enum.Font.GothamBold
illusionTitle.TextScaled = true
illusionTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
illusionTitle.TextColor3 = Color3.new(1, 1, 1)
illusionTitle.Parent = illusionMenu

local illusionScroll = Instance.new("ScrollingFrame")
illusionScroll.Size = UDim2.new(1, 0, 1, -40)
illusionScroll.Position = UDim2.new(0, 0, 0, 40)
illusionScroll.BackgroundTransparency = 1
illusionScroll.ScrollBarThickness = 10
illusionScroll.Parent = illusionMenu

-- Populate Illusion Menu
local yPos = 0
for name, data in pairs(illusionData) do
    local illusionFrame = Instance.new("Frame")
    illusionFrame.Size = UDim2.new(1, -20, 0, 100)
    illusionFrame.Position = UDim2.new(0, 10, 0, yPos)
    illusionFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    illusionFrame.Parent = illusionScroll
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.6, 0, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.Text = name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = illusionFrame
    
    local hpLabel = Instance.new("TextLabel")
    hpLabel.Size = UDim2.new(0.3, 0, 0, 20)
    hpLabel.Position = UDim2.new(0, 5, 0, 30)
    hpLabel.Text = "HP: " .. data.hp
    hpLabel.Font = Enum.Font.Gotham
    hpLabel.TextScaled = true
    hpLabel.BackgroundTransparency = 1
    hpLabel.TextColor3 = Color3.new(1, 1, 1)
    hpLabel.TextXAlignment = Enum.TextXAlignment.Left
    hpLabel.Parent = illusionFrame
    
    local spLabel = Instance.new("TextLabel")
    spLabel.Size = UDim2.new(0.3, 0, 0, 20)
    spLabel.Position = UDim2.new(0, 5, 0, 50)
    spLabel.Text = "SP: " .. data.sp
    spLabel.Font = Enum.Font.Gotham
    spLabel.TextScaled = true
    spLabel.BackgroundTransparency = 1
    spLabel.TextColor3 = Color3.new(1, 1, 1)
    spLabel.TextXAlignment = Enum.TextXAlignment.Left
    spLabel.Parent = illusionFrame
    
    local pureLabel = Instance.new("TextLabel")
    pureLabel.Size = UDim2.new(0.3, 0, 0, 20)
    pureLabel.Position = UDim2.new(0, 5, 0, 70)
    pureLabel.Text = "PURE: " .. data.pure
    pureLabel.Font = Enum.Font.Gotham
    pureLabel.TextScaled = true
    pureLabel.BackgroundTransparency = 1
    pureLabel.TextColor3 = Color3.new(1, 1, 1)
    pureLabel.TextXAlignment = Enum.TextXAlignment.Left
    pureLabel.Parent = illusionFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 80, 0, 30)
    toggleButton.Position = UDim2.new(1, -90, 0, 5)
    toggleButton.Text = data.enabled and "ON" or "OFF"
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextScaled = true
    toggleButton.BackgroundColor3 = data.enabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.Parent = illusionFrame
    
    toggleButton.MouseButton1Click:Connect(function()
        data.enabled = not data.enabled
        toggleButton.Text = data.enabled and "ON" or "OFF"
        toggleButton.BackgroundColor3 = data.enabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        
        if data.enabled then
            spawnIllusion(name, data)
        else
            removeIllusion(name)
        end
    end)
    
    yPos = yPos + 120
end

illusionScroll.CanvasSize = UDim2.new(0, 0, 0, yPos)

-- Suit Menu
local suitMenu = Instance.new("Frame")
suitMenu.Size = UDim2.new(0, 400, 0, 350)
suitMenu.Position = UDim2.new(0.5, -200, 0.5, -175)
suitMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
suitMenu.BorderSizePixel = 2
suitMenu.Visible = false
suitMenu.Parent = screenGui

local suitTitle = Instance.new("TextLabel")
suitTitle.Size = UDim2.new(1, 0, 0, 40)
suitTitle.Text = "Suits"
suitTitle.Font = Enum.Font.GothamBold
suitTitle.TextScaled = true
suitTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
suitTitle.TextColor3 = Color3.new(1, 1, 1)
suitTitle.Parent = suitMenu

local suitScroll = Instance.new("ScrollingFrame")
suitScroll.Size = UDim2.new(1, 0, 1, -40)
suitScroll.Position = UDim2.new(0, 0, 0, 40)
suitScroll.BackgroundTransparency = 1
suitScroll.ScrollBarThickness = 10
suitScroll.Parent = suitMenu

-- Populate Suit Menu
yPos = 0
for name, data in pairs(suitData) do
    local suitFrame = Instance.new("Frame")
    suitFrame.Size = UDim2.new(1, -20, 0, 80)
    suitFrame.Position = UDim2.new(0, 10, 0, yPos)
    suitFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    suitFrame.Parent = suitScroll
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.6, 0, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.Text = name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = suitFrame
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 80, 0, 30)
    toggleButton.Position = UDim2.new(1, -90, 0, 5)
    toggleButton.Text = data.enabled and "ON" or "OFF"
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextScaled = true
    toggleButton.BackgroundColor3 = data.enabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.Parent = suitFrame
    
    toggleButton.MouseButton1Click:Connect(function()
        -- Turn off all suits
        for suitName, suitInfo in pairs(suitData) do
            suitInfo.enabled = false
        end
        
        -- Turn on selected suit
        data.enabled = true
        playerStats.currentSuit = name
        
        -- Update all buttons
        for _, child in pairs(suitScroll:GetChildren()) do
            if child:IsA("Frame") then
                local btn = child:FindFirstChildOfClass("TextButton")
                if btn then
                    local frameName = child:FindFirstChildOfClass("TextLabel").Text
                    btn.Text = (frameName == name) and "ON" or "OFF"
                    btn.BackgroundColor3 = (frameName == name) and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
                end
            end
        end
    end)
    
    yPos = yPos + 90
end

suitScroll.CanvasSize = UDim2.new(0, 0, 0, yPos)

-- Weapon Menu
local weaponMenu = Instance.new("Frame")
weaponMenu.Size = UDim2.new(0, 400, 0, 350)
weaponMenu.Position = UDim2.new(0.5, -200, 0.5, -175)
weaponMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
weaponMenu.BorderSizePixel = 2
weaponMenu.Visible = false
weaponMenu.Parent = screenGui

local weaponTitle = Instance.new("TextLabel")
weaponTitle.Size = UDim2.new(1, 0, 0, 40)
weaponTitle.Text = "Weapons"
weaponTitle.Font = Enum.Font.GothamBold
weaponTitle.TextScaled = true
weaponTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
weaponTitle.TextColor3 = Color3.new(1, 1, 1)
weaponTitle.Parent = weaponMenu

local weaponScroll = Instance.new("ScrollingFrame")
weaponScroll.Size = UDim2.new(1, 0, 1, -40)
weaponScroll.Position = UDim2.new(0, 0, 0, 40)
weaponScroll.BackgroundTransparency = 1
weaponScroll.ScrollBarThickness = 10
weaponScroll.Parent = weaponMenu

-- Button Connections
illusionButton.MouseButton1Click:Connect(function()
    illusionMenu.Visible = not illusionMenu.Visible
    suitMenu.Visible = false
    weaponMenu.Visible = false
end)

suitButton.MouseButton1Click:Connect(function()
    suitMenu.Visible = not suitMenu.Visible
    illusionMenu.Visible = false
    weaponMenu.Visible = false
end)

weaponButton.MouseButton1Click:Connect(function()
    weaponMenu.Visible = not weaponMenu.Visible
    illusionMenu.Visible = false
    suitMenu.Visible = false
end)

-- Create Dialogue GUI for Disaster Wolf Event
local function createDialogueGui()
    if disasterWolfEvent.dialogueGui then return end
    
    local dialogueFrame = Instance.new("Frame")
    dialogueFrame.Size = UDim2.new(0.8, 0, 0, 100)
    dialogueFrame.Position = UDim2.new(0.1, 0, 1, -120)
    dialogueFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    dialogueFrame.BorderSizePixel = 2
    dialogueFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    dialogueFrame.Parent = screenGui
    
    local dialogueLabel = Instance.new("TextLabel")
    dialogueLabel.Name = "DialogueText"
    dialogueLabel.Size = UDim2.new(1, -20, 1, -20)
    dialogueLabel.Position = UDim2.new(0, 10, 0, 10)
    dialogueLabel.BackgroundTransparency = 1
    dialogueLabel.Text = ""
    dialogueLabel.TextColor3 = Color3.new(1, 1, 1)
    dialogueLabel.TextScaled = false
    dialogueLabel.TextSize = 20
    dialogueLabel.Font = Enum.Font.Gotham
    dialogueLabel.TextWrapped = true
    dialogueLabel.TextXAlignment = Enum.TextXAlignment.Left
    dialogueLabel.TextYAlignment = Enum.TextYAlignment.Top
    dialogueLabel.Parent = dialogueFrame
    
    disasterWolfEvent.dialogueGui = dialogueFrame
end

-- Show Dialogue with Typing Animation
local function showDialogue(text)
    if not disasterWolfEvent.dialogueGui then
        createDialogueGui()
    end
    
    local dialogueLabel = disasterWolfEvent.dialogueGui:FindFirstChild("DialogueText")
    if not dialogueLabel then return end
    
    disasterWolfEvent.currentDialogue = text
    disasterWolfEvent.typingIndex = 0
    dialogueLabel.Text = ""
    
    task.spawn(function()
        for i = 1, #text do
            if disasterWolfEvent.currentDialogue ~= text then break end
            dialogueLabel.Text = string.sub(text, 1, i)
            task.wait(0.1)
        end
        task.wait(3)
        if disasterWolfEvent.currentDialogue == text then
            dialogueLabel.Text = ""
        end
    end)
end

-- Check if all 4 wolves are spawned
local function checkForDisasterWolfEvent()
    if disasterWolfEvent.completed then return end
    
    local wolvesActive = {
        ["Small Wolf"] = activeIllusions["Small Wolf"] ~= nil,
        ["Wide Wolf"] = activeIllusions["Wide Wolf"] ~= nil,
        ["Long Wolf"] = activeIllusions["Long Wolf"] ~= nil,
        ["Big Wolf"] = activeIllusions["Big Wolf"] ~= nil
    }
    
    local allActive = wolvesActive["Small Wolf"] and wolvesActive["Wide Wolf"] and 
                     wolvesActive["Long Wolf"] and wolvesActive["Big Wolf"]
    
    if allActive and not disasterWolfEvent.active then
        disasterWolfEvent.active = true
        spawnElkCityPortal()
    end
end

-- Spawn Elk City Portal
function spawnElkCityPortal()
    if elkCityPortal then return end
    
    local angle = math.random() * math.pi * 2
    local distance = math.random(50, 100)
    local portalPos = hrp.Position + Vector3.new(
        math.cos(angle) * distance,
        0,
        math.sin(angle) * distance
    )
    
    local portal = Instance.new("Part")
    portal.Name = "ElkCityPortal"
    portal.Size = Vector3.new(10, 15, 1)
    portal.Position = portalPos
    portal.Anchored = true
    portal.CanCollide = false
    portal.BrickColor = BrickColor.new("Bright violet")
    portal.Material = Enum.Material.Neon
    portal.Parent = workspace
    
    elkCityPortal = {
        part = portal,
        hp = 7500,
        maxHp = 7500
    }
    
    -- Create HP bar for portal
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 30)
    billboardGui.Adornee = portal
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = portal
    
    local hpBarBg = Instance.new("Frame")
    hpBarBg.Size = UDim2.new(1, 0, 1, 0)
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Parent = billboardGui
    
    local hpBar = Instance.new("Frame")
    hpBar.Name = "HPBar"
    hpBar.Size = UDim2.new(1, 0, 1, 0)
    hpBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = hpBarBg
    
    elkCityPortal.hpBar = hpBar
    
    showDialogue("Long ago, 4 wolf happily live in the elk city.")
    
    -- Make all wolves move to portal
    for wolfName, illusion in pairs(activeIllusions) do
        if wolfName == "Small Wolf" or wolfName == "Wide Wolf" or 
           wolfName == "Long Wolf" or wolfName == "Big Wolf" then
            illusion.movingToPortal = true
            illusion.stoppedAttacking = true
        end
    end
end

-- Spawn Illusion Function
function spawnIllusion(name, data)
    if activeIllusions[name] then return end
    
    local illusionModel = Instance.new("Model")
    illusionModel.Name = name
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Position = hrp.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
    torso.Anchored = false
    torso.CanCollide = true
    torso.BrickColor = BrickColor.new("Bright red")
    torso.Parent = illusionModel
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 1, 1)
    head.Position = torso.Position + Vector3.new(0, 1.5, 0)
    head.Anchored = false
    head.CanCollide = true
    head.BrickColor = BrickColor.new("Bright red")
    head.Parent = illusionModel
    
    local leftArm = Instance.new("Part")
    leftArm.Name = "LeftArm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.Position = torso.Position + Vector3.new(-1.5, 0, 0)
    leftArm.Anchored = false
    leftArm.CanCollide = false
    leftArm.BrickColor = BrickColor.new("Bright red")
    leftArm.Parent = illusionModel
    
    local rightArm = Instance.new("Part")
    rightArm.Name = "RightArm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Position = torso.Position + Vector3.new(1.5, 0, 0)
    rightArm.Anchored = false
    rightArm.CanCollide = false
    rightArm.BrickColor = BrickColor.new("Bright red")
    rightArm.Parent = illusionModel
    
    -- Weld parts together
    local function weld(part0, part1)
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = part0
        weld.Part1 = part1
        weld.Parent = part0
    end
    
    weld(torso, head)
    weld(torso, leftArm)
    weld(torso, rightArm)
    
    local illusionHumanoid = Instance.new("Humanoid")
    illusionHumanoid.MaxHealth = data.hp
    illusionHumanoid.Health = data.hp
    illusionHumanoid.WalkSpeed = data.crawlSpeed or data.walkSpeed or 16
    illusionHumanoid.Parent = illusionModel
    
    -- Special effects for Scorcher
    if name == "Scorcher" then
        torso.BrickColor = BrickColor.new("Really black")
        head.BrickColor = BrickColor.new("Really black")
        leftArm.BrickColor = BrickColor.new("Really black")
        rightArm.BrickColor = BrickColor.new("Really black")
        
        local fire = Instance.new("Fire")
        fire.Size = 5
        fire.Heat = 10
        fire.Parent = torso
        
        local fire2 = Instance.new("Fire")
        fire2.Size = 3
        fire2.Heat = 8
        fire2.Parent = head
    end
    
    -- Special effects for Schadenfreude
    if name == "Schadenfreude" then
        torso.BrickColor = BrickColor.new("Really black")
        head.BrickColor = BrickColor.new("Really black")
        leftArm.BrickColor = BrickColor.new("Really black")
        rightArm.BrickColor = BrickColor.new("Really black")
        
        -- Add "DONT LOOK" text above head
        local dontLookGui = Instance.new("BillboardGui")
        dontLookGui.Size = UDim2.new(0, 200, 0, 50)
        dontLookGui.StudsOffset = Vector3.new(0, 4, 0)
        dontLookGui.Adornee = head
        dontLookGui.AlwaysOnTop = true
        dontLookGui.Parent = head
        
        local dontLookLabel = Instance.new("TextLabel")
        dontLookLabel.Size = UDim2.new(1, 0, 1, 0)
        dontLookLabel.BackgroundTransparency = 1
        dontLookLabel.Text = "DONT LOOK"
        dontLookLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        dontLookLabel.TextScaled = true
        dontLookLabel.Font = Enum.Font.GothamBold
        dontLookLabel.TextStrokeTransparency = 0
        dontLookLabel.Parent = dontLookGui
    end
    
    -- Special effects for Mimicry
    if name == "Mimicry" then
        torso.BrickColor = BrickColor.new("Really red")
        head.BrickColor = BrickColor.new("Really red")
        leftArm.BrickColor = BrickColor.new("Really red")
        rightArm.BrickColor = BrickColor.new("Really red")
        
        -- Phase 1 sound loop
        local phase1Sound = Instance.new("Sound")
        phase1Sound.SoundId = "rbxassetid://2796806401"
        phase1Sound.Volume = 0.4
        phase1Sound.Looped = true
        phase1Sound.Parent = torso
        phase1Sound:Play()
    end
    
    -- Special effects for Small Wolf
    if name == "Small Wolf" then
        torso.BrickColor = BrickColor.new("Brown")
        head.BrickColor = BrickColor.new("Brown")
        leftArm.BrickColor = BrickColor.new("Brown")
        rightArm.BrickColor = BrickColor.new("Brown")
        torso.Size = Vector3.new(1.5, 1.5, 1)
        head.Size = Vector3.new(1.5, 0.8, 1)
    end
    
    -- Special effects for Wide Wolf
    if name == "Wide Wolf" then
        torso.BrickColor = BrickColor.new("Light blue")
        head.BrickColor = BrickColor.new("Light blue")
        leftArm.BrickColor = BrickColor.new("Light blue")
        rightArm.BrickColor = BrickColor.new("Light blue")
        torso.Size = Vector3.new(3, 2, 1)
        
        -- Add radio on back
        local radio = Instance.new("Part")
        radio.Size = Vector3.new(0.5, 1, 0.5)
        radio.BrickColor = BrickColor.new("Really black")
        radio.Material = Enum.Material.Metal
        radio.Parent = illusionModel
        
        local radioWeld = Instance.new("WeldConstraint")
        radioWeld.Part0 = torso
        radioWeld.Part1 = radio
        radioWeld.Parent = torso
        
        local attachment0 = Instance.new("Attachment")
        attachment0.Position = Vector3.new(0, 0, -0.7)
        attachment0.Parent = torso
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = radio
        
        local weld = Instance.new("Weld")
        weld.Part0 = torso
        weld.Part1 = radio
        weld.C0 = CFrame.new(0, 0, -0.7)
        weld.Parent = torso
    end
    
    -- Special effects for Long Wolf
    if name == "Long Wolf" then
        torso.BrickColor = BrickColor.new("Dark stone grey")
        head.BrickColor = BrickColor.new("Dark stone grey")
        leftArm.BrickColor = BrickColor.new("Dark stone grey")
        rightArm.BrickColor = BrickColor.new("Dark stone grey")
        torso.Size = Vector3.new(2, 3, 1)
        
        -- Create dark fog
        local fog = Instance.new("Part")
        fog.Name = "DarkFog"
        fog.Size = Vector3.new(50, 50, 50)
        fog.Shape = Enum.PartType.Ball
        fog.Anchored = true
        fog.CanCollide = false
        fog.Transparency = 0.7
        fog.BrickColor = BrickColor.new("Really black")
        fog.Material = Enum.Material.Neon
        fog.Parent = illusionModel
    end
    
    -- Special effects for Big Wolf
    if name == "Big Wolf" then
        torso.BrickColor = BrickColor.new("Black")
        head.BrickColor = BrickColor.new("Black")
        leftArm.BrickColor = BrickColor.new("Black")
        rightArm.BrickColor = BrickColor.new("Black")
        torso.Size = Vector3.new(3, 3, 1.5)
        head.Size = Vector3.new(3, 1.5, 1.5)
        
        -- Add mirror on back
        local mirror = Instance.new("Part")
        mirror.Name = "Mirror"
        mirror.Size = Vector3.new(2, 3, 0.2)
        mirror.BrickColor = BrickColor.new("White")
        mirror.Material = Enum.Material.Glass
        mirror.Reflectance = 0.8
        mirror.Parent = illusionModel
        
        local weld = Instance.new("Weld")
        weld.Part0 = torso
        weld.Part1 = mirror
        weld.C0 = CFrame.new(0, 0, -1)
        weld.Parent = torso
    end
    
    illusionModel.Parent = workspace
    
    -- Create 3D Health Bars for Illusion
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 60)
    billboardGui.Adornee = head
    billboardGui.AlwaysOnTop = false
    billboardGui.Parent = head
    
    local barFrame = Instance.new("Frame")
    barFrame.Size = UDim2.new(1, 0, 1, 0)
    barFrame.BackgroundTransparency = 1
    barFrame.Parent = billboardGui
    
    -- HP Bar
    local hpBarBg = Instance.new("Frame")
    hpBarBg.Size = UDim2.new(1, 0, 0, 15)
    hpBarBg.Position = UDim2.new(0, 0, 0, 0)
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Parent = barFrame
    
    local illusionHpBar = Instance.new("Frame")
    illusionHpBar.Name = "HPBar"
    illusionHpBar.Size = UDim2.new(1, 0, 1, 0)
    illusionHpBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    illusionHpBar.BorderSizePixel = 0
    illusionHpBar.Parent = hpBarBg
    
    -- SP Bar
    local spBarBg = Instance.new("Frame")
    spBarBg.Size = UDim2.new(1, 0, 0, 15)
    spBarBg.Position = UDim2.new(0, 0, 0, 20)
    spBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    spBarBg.BorderSizePixel = 0
    spBarBg.Parent = barFrame
    
    local illusionSpBar = Instance.new("Frame")
    illusionSpBar.Name = "SPBar"
    illusionSpBar.Size = UDim2.new(1, 0, 1, 0)
    illusionSpBar.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    illusionSpBar.BorderSizePixel = 0
    illusionSpBar.Parent = spBarBg
    
    -- Pure Bar
    local pureBarBg = Instance.new("Frame")
    pureBarBg.Size = UDim2.new(1, 0, 0, 15)
    pureBarBg.Position = UDim2.new(0, 0, 0, 40)
    pureBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    pureBarBg.BorderSizePixel = 0
    pureBarBg.Parent = barFrame
    
    local illusionPureBar = Instance.new("Frame")
    illusionPureBar.Name = "PureBar"
    illusionPureBar.Size = UDim2.new(1, 0, 1, 0)
    illusionPureBar.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
    illusionPureBar.BorderSizePixel = 0
    illusionPureBar.Parent = pureBarBg
    
    billboardGui.Enabled = false
    
    -- Store illusion data
    activeIllusions[name] = {
        model = illusionModel,
        humanoid = illusionHumanoid,
        torso = torso,
        head = head,
        leftArm = leftArm,
        rightArm = rightArm,
        data = data,
        hp = data.hp,
        sp = data.sp,
        pure = data.pure or 100,
        maxHp = data.hp,
        maxSp = data.sp,
        maxPure = data.pure or 100,
        lastAttack = 0,
        hpBar = illusionHpBar,
        spBar = illusionSpBar,
        pureBar = illusionPureBar,
        billboardGui = billboardGui,
        fireTrail = {},
        phase = data.phase or 1,
        attackCount = 0,
        eggTimer = 0,
        iLoveYouTimer = 0,
        currentDialogue = nil,
        speedBoostTimer = data.speedBoostTimer or 0,
        isSpeedBoosted = data.isSpeedBoosted or false,
        pulseTimer = data.pulseTimer or 0,
        beamTimer = data.beamTimer or 0,
        coatTimer = data.coatTimer or 0,
        fogSize = data.fogSize or 50,
        fogDamageMultiplier = data.fogDamageMultiplier or 1,
        reflectChance = data.reflectChance or 0,
        mirrorMode = data.mirrorMode or false,
        mirrorTimer = data.mirrorTimer or 0,
        afterimageTrail = {}
    }
    
    -- Helper function to show Mimicry dialogue
    local function showMimicryDialogue(text, sound)
        local illusion = activeIllusions[name]
        if not illusion then return end
        
        -- Remove current dialogue if exists
        if illusion.currentDialogue then
            illusion.currentDialogue:Destroy()
        end
        
        -- Create new dialogue
        local dialogueGui = Instance.new("BillboardGui")
        dialogueGui.Size = UDim2.new(0, 200, 0, 50)
        dialogueGui.StudsOffset = Vector3.new(0, 5, 0)
        dialogueGui.Adornee = illusion.head
        dialogueGui.AlwaysOnTop = true
        dialogueGui.Parent = illusion.head
        
        local dialogueLabel = Instance.new("TextLabel")
        dialogueLabel.Size = UDim2.new(1, 0, 1, 0)
        dialogueLabel.BackgroundTransparency = 1
        dialogueLabel.Text = text
        dialogueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        dialogueLabel.TextScaled = true
        dialogueLabel.Font = Enum.Font.GothamBold
        dialogueLabel.TextStrokeTransparency = 0
        dialogueLabel.Parent = dialogueGui
        
        illusion.currentDialogue = dialogueGui
        
        -- Play sound if provided
        if sound then
            local dialogueSound = Instance.new("Sound")
            dialogueSound.SoundId = sound
            dialogueSound.Volume = 0.5
            dialogueSound.Parent = illusion.torso
            dialogueSound:Play()
        end
        
        -- Fade out after 1 second
        task.delay(1, function()
            if dialogueGui and dialogueGui.Parent then
                local fadeTween = TweenService:Create(dialogueLabel, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {TextTransparency = 1})
                fadeTween:Play()
                task.delay(0.3, function()
                    dialogueGui:Destroy()
                    if illusion.currentDialogue == dialogueGui then
                        illusion.currentDialogue = nil
                    end
                end)
            end
        end)
    end
    
    -- AI Behavior
    task.spawn(function()
        while activeIllusions[name] and illusionModel.Parent do
            local illusion = activeIllusions[name]
            
            if illusion.hp <= 0 then
                removeIllusion(name)
                break
            end
            
            -- Apply SP penalty
            local speedMultiplier = 1
            local damageMultiplier = 1
            if illusion.sp <= 0 then
                speedMultiplier = 0.5
                damageMultiplier = 0.5
            end
            
            illusionHumanoid.WalkSpeed = (data.crawlSpeed or data.walkSpeed or 16) * speedMultiplier
            
            local distance = (hrp.Position - torso.Position).Magnitude
            
            -- Small Wolf special mechanics
            if name == "Small Wolf" then
                illusion.speedBoostTimer = illusion.speedBoostTimer + 0.1
                
                if illusion.speedBoostTimer >= 30 and not illusion.isSpeedBoosted then
                    illusion.isSpeedBoosted = true
                    illusionHumanoid.WalkSpeed = illusionHumanoid.WalkSpeed + 100
                    
                    -- Create afterimage trail
                    task.spawn(function()
                        while illusion.isSpeedBoosted and activeIllusions[name] do
                            local afterimage = torso:Clone()
                            afterimage.Anchored = true
                            afterimage.CanCollide = false
                            afterimage.Transparency = 0.7
                            afterimage.Parent = workspace
                            
                            table.insert(illusion.afterimageTrail, afterimage)
                            
                            task.delay(0.5, function()
                                local fadeTween = TweenService:Create(afterimage, TweenInfo.new(0.5), {Transparency = 1})
                                fadeTween:Play()
                                task.delay(0.5, function()
                                    afterimage:Destroy()
                                end)
                            end)
                            
                            task.wait(0.1)
                        end
                    end)
                end
                
                -- Reset speed after attack
                if illusion.isSpeedBoosted and distance <= data.attackRange then
                    local currentTime = tick()
                    if currentTime - illusion.lastAttack >= data.attackCooldown then
                        local damage = math.random(15, 35)
                        damagePlayer(damage, "Red")
                        
                        illusion.isSpeedBoosted = false
                        illusion.speedBoostTimer = 0
                        illusionHumanoid.WalkSpeed = data.walkSpeed
                        illusion.lastAttack = currentTime
                    end
                end
            end
            
            -- Wide Wolf special mechanics
            if name == "Wide Wolf" then
                illusion.pulseTimer = illusion.pulseTimer + 0.1
                illusion.beamTimer = illusion.beamTimer + 0.1
                
                -- Pulse every 25 seconds
                if illusion.pulseTimer >= 25 then
                    illusion.pulseTimer = 0
                    
                    local forcefield = Instance.new("Part")
                    forcefield.Size = Vector3.new(50, 50, 50)
                    forcefield.Shape = Enum.PartType.Ball
                    forcefield.Position = torso.Position
                    forcefield.Anchored = true
                    forcefield.CanCollide = false
                    forcefield.Transparency = 0.5
                    forcefield.BrickColor = BrickColor.new("Bright blue")
                    forcefield.Material = Enum.Material.Neon
                    forcefield.Parent = workspace
                    
                    -- Check if player in forcefield
                    if (hrp.Position - forcefield.Position).Magnitude <= 25 then
                        local damage = math.random(25, 30)
                        damagePlayer(damage, "Blue")
                    end
                    
                    -- Fade out
                    local fadeTween = TweenService:Create(forcefield, TweenInfo.new(1), {Transparency = 1})
                    fadeTween:Play()
                    task.delay(1, function()
                        forcefield:Destroy()
                    end)
                end
                
                -- Beam every 10 seconds
                if illusion.beamTimer >= 10 then
                    illusion.beamTimer = 0
                    
                    local beam = Instance.new("Part")
                    beam.Size = Vector3.new(5, 50, 5)
                    beam.Position = hrp.Position + Vector3.new(0, 25, 0)
                    beam.Anchored = true
                    beam.CanCollide = false
                    beam.BrickColor = BrickColor.new("Bright blue")
                    beam.Material = Enum.Material.Neon
                    beam.Transparency = 0.3
                    beam.Parent = workspace
                    
                    if (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(beam.Position.X, 0, beam.Position.Z)).Magnitude <= 5 then
                        local damage = math.random(10, 25)
                        damagePlayer(damage, "Blue")
                    end
                    
                    task.delay(1, function()
                        beam:Destroy()
                    end)
                end
            end
            
            -- Long Wolf special mechanics
            if name == "Long Wolf" then
                illusion.coatTimer = illusion.coatTimer + 0.1
                
                -- Update fog position
                local fog = illusionModel:FindFirstChild("DarkFog")
                if fog then
                    fog.Position = torso.Position
                    fog.Size = Vector3.new(illusion.fogSize, illusion.fogSize, illusion.fogSize)
                    
                    -- Check if player in fog
                    if (hrp.Position - fog.Position).Magnitude <= illusion.fogSize / 2 then
                        if not illusion.inFog then
                            illusion.inFog = true
                            task.spawn(function()
                                while illusion.inFog and activeIllusions[name] do
                                    local baseDamage = math.random(7, 10)
                                    local damage = baseDamage * illusion.fogDamageMultiplier
                                    damagePlayer(damage, "Purple")
                                    task.wait(0.5)
                                    
                                    -- Check if still in fog
                                    if (hrp.Position - fog.Position).Magnitude > illusion.fogSize / 2 then
                                        illusion.inFog = false
                                    end
                                end
                            end)
                        end
                        
                        -- Check if player died in fog
                        if playerStats.hp <= 0 then
                            illusion.fogSize = math.min(illusion.fogSize + 5, data.maxFogSize or 100)
                            illusion.fogDamageMultiplier = math.min(illusion.fogDamageMultiplier + 0.1, data.maxFogMultiplier or 10)
                        end
                    else
                        illusion.inFog = false
                    end
                end
                
                -- Coat brightens every 3 seconds
                if illusion.coatTimer >= 3 then
                    illusion.coatTimer = 0
                    
                    -- Brighten effect
                    torso.Material = Enum.Material.Neon
                    local originalColor = torso.BrickColor
                    torso.BrickColor = BrickColor.new("White")
                    
                    if distance <= 15 then
                        local damage = math.random(25, 32)
                        damagePlayer(damage, "Purple")
                    end
                    
                    task.delay(0.5, function()
                        torso.Material = Enum.Material.SmoothPlastic
                        torso.BrickColor = originalColor
                    end)
                end
            end
            
            -- Big Wolf special mechanics
            if name == "Big Wolf" then
                if illusion.mirrorMode then
                    illusion.mirrorTimer = illusion.mirrorTimer + 0.1
                    illusionHumanoid.WalkSpeed = 0
                    
                    -- Barrage of bullets
                    if illusion.mirrorTimer % 0.5 < 0.1 then
                        local bullet = Instance.new("Part")
                        bullet.Size = Vector3.new(1, 1, 1)
                        bullet.Shape = Enum.PartType.Ball
                        bullet.Position = torso.Position + Vector3.new(0, 2, 0)
                        bullet.BrickColor = BrickColor.new("Really black")
                        bullet.Material = Enum.Material.Neon
                        bullet.CanCollide = false
                        bullet.Parent = workspace
                        
                        local bodyVelocity = Instance.new("BodyVelocity")
                        bodyVelocity.Velocity = (hrp.Position - bullet.Position).Unit * 50
                        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bodyVelocity.Parent = bullet
                        
                        bullet.Touched:Connect(function(hit)
                            if hit.Parent == character then
                                local damage = math.random(20, 45)
                                damagePlayer(damage, "Black")
                                bullet:Destroy()
                            end
                        end)
                        
                        task.delay(3, function()
                            if bullet.Parent then
                                bullet:Destroy()
                            end
                        end)
                    end
                    
                    -- End mirror mode after 5 seconds
                    if illusion.mirrorTimer >= 5 then
                        illusion.mirrorMode = false
                        illusion.mirrorTimer = 0
                        illusion.reflectChance = data.reflectChance
                        illusionHumanoid.WalkSpeed = data.walkSpeed
                        
                        local mirror = illusionModel:FindFirstChild("Mirror")
                        if mirror then
                            mirror.Transparency = 0
                        end
                    end
                end
            end
            
            -- Mimicry special mechanics
            if name == "Mimicry" then
                -- Check if player died near Mimicry (Phase 1 -> Egg)
                if illusion.phase == 1 and playerStats.hp <= 0 and distance <= 20 then
                    -- Transform into egg
                    illusion.phase = "egg"
                    illusion.hp = 15000
                    illusion.sp = 14500
                    illusion.pure = 15300
                    illusion.maxHp = 15000
                    illusion.maxSp = 14500
                    illusion.maxPure = 15300
                    illusion.data.damageReductions = {Red = 0.0, Blue = 0.05, Purple = 0.1, Black = 0.15}
                    illusion.eggTimer = 0
                    
                    -- Stop phase 1 sound
                    for _, child in pairs(torso:GetChildren()) do
                        if child:IsA("Sound") and child.Looped then
                            child:Stop()
                            child:Destroy()
                        end
                    end
                    
                    -- Change appearance to egg
                    torso.Size = Vector3.new(4, 4, 4)
                    torso.Shape = Enum.PartType.Ball
                    torso.BrickColor = BrickColor.new("White")
                    head.Transparency = 1
                    leftArm.Transparency = 1
                    rightArm.Transparency = 1
                    
                    illusionHumanoid.WalkSpeed = 0
                end
                
                -- Egg hatching
                if illusion.phase == "egg" then
                    illusion.eggTimer = illusion.eggTimer + 0.1
                    
                    if illusion.eggTimer >= 60 then
                        -- Hatch into Phase 2
                        illusion.phase = 2
                        illusion.hp = 5300
                        illusion.sp = 6535
                        illusion.pure = 6000
                        illusion.maxHp = 5300
                        illusion.maxSp = 6535
                        illusion.maxPure = 6000
                        illusion.data.damageReductions = {Red = 0.1, Blue = 0.5, Purple = 0.4, Black = 0.1}
                        illusion.data.walkSpeed = 25
                        illusion.data.attackRange = 15
                        illusion.data.attackCooldown = 2
                        illusion.data.damageScale = {30, 70}
                        illusion.attackCount = 0
                        
                        -- Play hatch sound
                        local hatchSound = Instance.new("Sound")
                        hatchSound.SoundId = "rbxassetid://83494547160190"
                        hatchSound.Volume = 0.6
                        hatchSound.Parent = torso
                        hatchSound:Play()
                        
                        -- Change to tall humanoid
                        torso.Size = Vector3.new(2, 4, 1)
                        torso.Shape = Enum.PartType.Block
                        torso.BrickColor = BrickColor.new("Really red")
                        head.Transparency = 0
                        head.Size = Vector3.new(2, 2, 1)
                        leftArm.Transparency = 0
                        leftArm.Size = Vector3.new(1, 4, 1)
                        rightArm.Transparency = 0
                        rightArm.Size = Vector3.new(1, 4, 1)
                        
                        illusionHumanoid.WalkSpeed = 25
                        
                        -- Start "I love you..." loop sound
                        local loveSound = Instance.new("Sound")
                        loveSound.SoundId = "rbxassetid://131461792070501"
                        loveSound.Volume = 0.4
                        loveSound.Looped = true
                        loveSound.Parent = torso
                        loveSound:Play()
                    end
                end
                
                -- Phase 2 mechanics
                if illusion.phase == 2 then
                    -- "I love you..." dialogue every 2 seconds
                    illusion.iLoveYouTimer = illusion.iLoveYouTimer + 0.1
                    if illusion.iLoveYouTimer >= 2 then
                        showMimicryDialogue("I love you...", nil)
                        illusion.iLoveYouTimer = 0
                    end
                    
                    -- "Hello?" when close to player
                    if distance <= 20 and distance > 15 then
                        if not illusion.shownHello then
                            showMimicryDialogue("Hello?", "rbxassetid://119594199902437")
                            illusion.shownHello = true
                        end
                    else
                        illusion.shownHello = false
                    end
                end
            end
            
            -- Schadenfreude looking mechanic
            if name == "Schadenfreude" then
                local camera = workspace.CurrentCamera
                local cameraLook = camera.CFrame.LookVector
                local toIllusion = (head.Position - camera.CFrame.Position).Unit
                local dotProduct = cameraLook:Dot(toIllusion)
                
                -- Player is looking at Schadenfreude if dot product > 0.9
                if dotProduct > 0.9 and distance < 50 then
                    if not lookingAtSchadenfreude then
                        lookingAtSchadenfreude = true
                        playerBlinded = true
                        
                        -- Play looking sound (loop)
                        schadenfreudeLoopSound = Instance.new("Sound")
                        schadenfreudeLoopSound.SoundId = "rbxassetid://3106518815"
                        schadenfreudeLoopSound.Volume = 0.5
                        schadenfreudeLoopSound.Looped = true
                        schadenfreudeLoopSound.Parent = hrp
                        schadenfreudeLoopSound:Play()
                        
                        -- Create blind effect
                        local blindGui = Instance.new("ScreenGui")
                        blindGui.Name = "BlindEffect"
                        blindGui.Parent = player.PlayerGui
                        
                        local blindFrame = Instance.new("Frame")
                        blindFrame.Size = UDim2.new(1, 0, 1, 0)
                        blindFrame.BackgroundColor3 = Color3.new(0, 0, 0)
                        blindFrame.BackgroundTransparency = 0
                        blindFrame.Parent = blindGui
                        
                        -- Damage loop
                        task.spawn(function()
                            while lookingAtSchadenfreude and playerBlinded do
                                damagePlayer(math.random(10, 15), "Blue")
                                task.wait(0.5)
                            end
                        end)
                    end
                else
                    if lookingAtSchadenfreude then
                        lookingAtSchadenfreude = false
                        playerBlinded = false
                        
                        -- Stop sound
                        if schadenfreudeLoopSound then
                            schadenfreudeLoopSound:Stop()
                            schadenfreudeLoopSound:Destroy()
                            schadenfreudeLoopSound = nil
                        end
                        
                        -- Remove blind effect
                        if player.PlayerGui:FindFirstChild("BlindEffect") then
                            player.PlayerGui.BlindEffect:Destroy()
                        end
                    end
                end
            end
            
            -- Move towards player
            if distance > data.attackRange then
                -- Check if moving to portal
                if illusion.movingToPortal and elkCityPortal then
                    illusionHumanoid:MoveTo(elkCityPortal.part.Position)
                    
                    -- Check if reached portal
                    if (torso.Position - elkCityPortal.part.Position).Magnitude <= 5 then
                        -- Wolf enters portal
                        if not disasterWolfEvent.wolvesEntered[name] then
                            disasterWolfEvent.wolvesEntered[name] = true
                            
                            if name == "Small Wolf" then
                                showDialogue("Small Wolf's Claw and Teeth punishes those who sins.")
                            elseif name == "Wide Wolf" then
                                showDialogue("Wide Wolf's Radio signal pulses occasionally detecting and guarding every animal's movement, caught those who sins.")
                            elseif name == "Long Wolf" then
                                showDialogue("Long Wolf's Fog cures all past and future sins away from all animals, It is too late if the animal sins too much.")
                            elseif name == "Big Wolf" then
                                showDialogue("Big Wolf's Mirror reflects all animal's past, present, and future sins.")
                            end
                            
                            -- Hide wolf
                            illusionModel.Parent = nil
                            
                            -- Check if all wolves entered
                            local allEntered = disasterWolfEvent.wolvesEntered["Small Wolf"] and
                                             disasterWolfEvent.wolvesEntered["Wide Wolf"] and
                                             disasterWolfEvent.wolvesEntered["Long Wolf"] and
                                             disasterWolfEvent.wolvesEntered["Big Wolf"]
                            
                            if allEntered then
                                task.wait(3)
                                showDialogue("Suddenly, a cry out from the Elk City far away occured :")
                                task.wait(6)
                                showDialogue("Its the beast! The big black Beast in the Dusky City!")
                                task.wait(6)
                                spawnDisasterWolf()
                            end
                        end
                    end
                else
                    -- Normal movement
                    if not illusion.stoppedAttacking then
                        illusionHumanoid:MoveTo(hrp.Position)
                    end
                end
                
                -- Scorcher leaves fire trail
                if name == "Scorcher" then
                    local firePart = Instance.new("Part")
                    firePart.Size = Vector3.new(3, 0.5, 3)
                    firePart.Position = torso.Position
                    firePart.Anchored = true
                    firePart.CanCollide = false
                    firePart.Transparency = 0.5
                    firePart.BrickColor = BrickColor.new("Really red")
                    firePart.Material = Enum.Material.Neon
                    firePart.Parent = workspace
                    
                    local fireEffect = Instance.new("Fire")
                    fireEffect.Size = 8
                    fireEffect.Heat = 15
                    fireEffect.Parent = firePart
                    
                    table.insert(illusion.fireTrail, firePart)
                    
                    -- Damage player if touching fire
                    firePart.Touched:Connect(function(hit)
                        if hit.Parent == character and not playerStats.burning then
                            playerStats.burning = true
                            
                            -- Play fire lit sound
                            local litSound = Instance.new("Sound")
                            litSound.SoundId = "rbxassetid://4403634269"
                            litSound.Volume = 0.5
                            litSound.Parent = hrp
                            litSound:Play()
                            
                            -- Play fire crackle loop
                            local crackleSound = Instance.new("Sound")
                            crackleSound.SoundId = "rbxassetid://9079463756"
                            crackleSound.Volume = 0.3
                            crackleSound.Looped = true
                            crackleSound.Parent = hrp
                            crackleSound:Play()
                            
                            task.spawn(function()
                                while playerStats.burning and hit.Parent == character do
                                    damagePlayer(math.random(2, 5), "Purple")
                                    task.wait(1)
                                    
                                    -- Check if still touching fire
                                    local stillBurning = false
                                    for _, trail in pairs(activeIllusions[name].fireTrail) do
                                        if (trail.Position - hrp.Position).Magnitude < 5 then
                                            stillBurning = true
                                            break
                                        end
                                    end
                                    
                                    if not stillBurning then
                                        playerStats.burning = false
                                        crackleSound:Stop()
                                        task.wait(0.5)
                                        crackleSound:Destroy()
                                    end
                                end
                            end)
                        end
                    end)
                    
                    task.delay(10, function()
                        firePart:Destroy()
                    end)
                end
            else
                -- Attack player
                local currentTime = tick()
                if currentTime - illusion.lastAttack >= data.attackCooldown and not illusion.stoppedAttacking then
                    illusion.lastAttack = currentTime
                    
                    -- Mimicry Phase 2 special attacks
                    if name == "Mimicry" and illusion.phase == 2 then
                        illusion.attackCount = illusion.attackCount + 1
                        
                        -- 17th attack: Dash ability
                        if illusion.attackCount >= 17 then
                            showMimicryDialogue("Goodbye.", "rbxassetid://72209573879445")
                            illusion.attackCount = 0
                            
                            -- Dash forward
                            local dashDirection = (hrp.Position - torso.Position).Unit
                            illusionHumanoid.WalkSpeed = 35
                            
                            local dashTime = 0
                            local dashing = true
                            task.spawn(function()
                                while dashing and dashTime < 2 do
                                    illusionHumanoid:MoveTo(torso.Position + dashDirection * 50)
                                    
                                    -- Check if player is caught in dash
                                    local dashDistance = (hrp.Position - torso.Position).Magnitude
                                    if dashDistance <= 5 then
                                        local dashDamage = math.random(80, 175)
                                        damagePlayer(dashDamage, "Black")
                                        
                                        -- Play dash hit sound
                                        local dashHitSound = Instance.new("Sound")
                                        dashHitSound.SoundId = "rbxassetid://124734278847105"
                                        dashHitSound.Volume = 0.6
                                        dashHitSound.Parent = hrp
                                        dashHitSound:Play()
                                    end
                                    
                                    dashTime = dashTime + 0.1
                                    task.wait(0.1)
                                end
                                dashing = false
                                illusionHumanoid.WalkSpeed = 25
                            end)
                            
                        -- 5th attack: Beam ability
                        elseif illusion.attackCount % 5 == 0 then
                            showMimicryDialogue("Help! Help!", "rbxassetid://74146743627850")
                            
                            task.wait(1) -- 1 second delay
                            
                            -- Create beam
                            local beam = Instance.new("Part")
                            beam.Size = Vector3.new(5, 50, 5)
                            beam.Position = hrp.Position + Vector3.new(0, 25, 0)
                            beam.Anchored = true
                            beam.CanCollide = false
                            beam.BrickColor = BrickColor.new("Really red")
                            beam.Material = Enum.Material.Neon
                            beam.Transparency = 0.3
                            beam.Parent = workspace
                            
                            -- Check if player is in beam
                            local beamDistance = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(beam.Position.X, 0, beam.Position.Z)).Magnitude
                            if beamDistance <= 5 then
                                local beamDamage = math.random(65, 90)
                                damagePlayer(beamDamage, "Black")
                            end
                            
                            task.delay(1, function()
                                beam:Destroy()
                            end)
                            
                        else
                            -- Normal attack
                            local armTween = TweenService:Create(leftArm, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = leftArm.CFrame * CFrame.Angles(math.rad(-90), 0, 0)})
                            armTween:Play()
                            local armTween2 = TweenService:Create(rightArm, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = rightArm.CFrame * CFrame.Angles(math.rad(-90), 0, 0)})
                            armTween2:Play()
                            
                            task.wait(0.3)
                            
                            if (hrp.Position - torso.Position).Magnitude <= data.attackRange then
                                local damage = math.random(data.damageScale[1], data.damageScale[2]) * damageMultiplier
                                damagePlayer(damage, data.damageType)
                                
                                -- Play phase 2 hit sound
                                local hitSound = Instance.new("Sound")
                                hitSound.SoundId = "rbxassetid://74494429622344"
                                hitSound.Volume = 0.5
                                hitSound.Parent = hrp
                                hitSound:Play()
                            end
                            
                            task.wait(0.2)
                            armTween:Cancel()
                            armTween2:Cancel()
                        end
                        
                    elseif name == "Mimicry" and illusion.phase == 1 then
                        -- Phase 1 attack
                        local armTween = TweenService:Create(leftArm, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = leftArm.CFrame * CFrame.Angles(math.rad(-90), 0, 0)})
                        armTween:Play()
                        local armTween2 = TweenService:Create(rightArm, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = rightArm.CFrame * CFrame.Angles(math.rad(-90), 0, 0)})
                        armTween2:Play()
                        
                        task.wait(0.3)
                        
                        if (hrp.Position - torso.Position).Magnitude <= data.attackRange then
                            local damage = math.random(data.damageScale[1], data.damageScale[2]) * damageMultiplier
                            damagePlayer(damage, data.damageType)
                            
                            -- Play phase 1 hit sound
                            local hitSound = Instance.new("Sound")
                            hitSound.SoundId = "rbxassetid://6594869919"
                            hitSound.Volume = 0.5
                            hitSound.Parent = hrp
                            hitSound:Play()
                        end
                        
                        task.wait(0.2)
                        armTween:Cancel()
                        armTween2:Cancel()
                        
                    else
                        -- Normal illusion attack
                        local armTween = TweenService:Create(leftArm, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = leftArm.CFrame * CFrame.Angles(math.rad(-90), 0, 0)})
                        armTween:Play()
                        local armTween2 = TweenService:Create(rightArm, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = rightArm.CFrame * CFrame.Angles(math.rad(-90), 0, 0)})
                        armTween2:Play()
                        
                        task.wait(0.3)
                        
                        if (hrp.Position - torso.Position).Magnitude <= data.attackRange then
                            local attackSound = Instance.new("Sound")
                            if name == "Schadenfreude" then
                                attackSound.SoundId = "rbxassetid://117297744119258"
                            else
                                attackSound.SoundId = "rbxassetid://77452678009271"
                            end
                            attackSound.Volume = 0.5
                            attackSound.Parent = torso
                            attackSound:Play()
                            
                            local damage = math.random(data.damageScale[1], data.damageScale[2]) * damageMultiplier
                            
                            -- Small Wolf normal attack (not speed boosted)
                            if name == "Small Wolf" and not illusion.isSpeedBoosted then
                                damagePlayer(damage, data.damageType)
                            elseif name ~= "Small Wolf" or not illusion.isSpeedBoosted then
                                damagePlayer(damage, data.damageType)
                            end
                            
                            if name == "Schadenfreude" then
                                local hitSound = Instance.new("Sound")
                                hitSound.SoundId = "rbxassetid://935843979"
                                hitSound.Volume = 0.5
                                hitSound.Parent = hrp
                                hitSound:Play()
                            end
                            
                            if name == "Scorcher" then
                                playerStats.burning = true
                                
                                local litSound = Instance.new("Sound")
                                litSound.SoundId = "rbxassetid://4403634269"
                                litSound.Volume = 0.5
                                litSound.Parent = hrp
                                litSound:Play()
                                
                                local crackleSound = Instance.new("Sound")
                                crackleSound.SoundId = "rbxassetid://9079463756"
                                crackleSound.Volume = 0.3
                                crackleSound.Looped = true
                                crackleSound.Parent = hrp
                                crackleSound:Play()
                                
                                task.spawn(function()
                                    for i = 1, 5 do
                                        if not playerStats.burning then break end
                                        damagePlayer(math.random(2, 5), "Purple")
                                        task.wait(1)
                                    end
                                    playerStats.burning = false
                                    crackleSound:Stop()
                                    task.wait(0.5)
                                    crackleSound:Destroy()
                                end)
                            end
                        else
                            local missSound = Instance.new("Sound")
                            missSound.SoundId = "rbxassetid://96785397624223"
                            missSound.Volume = 0.5
                            missSound.Parent = torso
                            missSound:Play()
                        end
                        
                        task.wait(0.2)
                        armTween:Cancel()
                        armTween2:Cancel()
                    end
                end
            end
            
            task.wait(0.1)
        end
    end)
end

-- Spawn Disaster Wolf and Eggs
function spawnDisasterWolf()
    -- Spawn Disaster Wolf at portal location
    local disasterPos = elkCityPortal.part.Position
    
    local disasterModel = Instance.new("Model")
    disasterModel.Name = "Disaster Wolf"
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(10, 10, 5)
    torso.Position = disasterPos
    torso.Anchored = true
    torso.CanCollide = true
    torso.BrickColor = BrickColor.new("Really black")
    torso.Material = Enum.Material.Neon
    torso.Parent = disasterModel
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(10, 5, 5)
    head.Position = torso.Position + Vector3.new(0, 7.5, 0)
    head.Anchored = true
    head.CanCollide = true
    head.BrickColor = BrickColor.new("Really black")
    head.Material = Enum.Material.Neon
    head.Parent = disasterModel
    
    disasterModel.Parent = workspace
    
    local disasterHumanoid = Instance.new("Humanoid")
    disasterHumanoid.MaxHealth = 15000
    disasterHumanoid.Health = 15000
    disasterHumanoid.WalkSpeed = 0
    disasterHumanoid.Parent = disasterModel
    
    -- Create HP bar
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 400, 0, 40)
    billboardGui.Adornee = head
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = head
    
    local hpBarBg = Instance.new("Frame")
    hpBarBg.Size = UDim2.new(1, 0, 1, 0)
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Parent = billboardGui
    
    local hpBar = Instance.new("Frame")
    hpBar.Name = "HPBar"
    hpBar.Size = UDim2.new(1, 0, 1, 0)
    hpBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = hpBarBg
    
    activeIllusions["Disaster Wolf"] = {
        model = disasterModel,
        humanoid = disasterHumanoid,
        torso = torso,
        head = head,
        data = illusionData["Disaster Wolf"],
        hp = 15000,
        maxHp = 15000,
        hpBar = hpBar,
        canAttack = false
    }
    
    -- Spawn 4 eggs around Disaster Wolf
    local eggNames = {"Small Claw", "Wide Eyes", "Long Body", "Big Brain"}
    local eggPositions = {
        Vector3.new(15, 0, 0),
        Vector3.new(-15, 0, 0),
        Vector3.new(0, 0, 15),
        Vector3.new(0, 0, -15)
    }
    
    for i, eggName in ipairs(eggNames) do
        spawnEgg(eggName, disasterPos + eggPositions[i])
    end
end

-- Spawn Individual Egg
function spawnEgg(eggName, position)
    local eggModel = Instance.new("Model")
    eggModel.Name = eggName
    
    local eggPart = Instance.new("Part")
    eggPart.Name = "Egg"
    eggPart.Size = Vector3.new(4, 6, 4)
    eggPart.Shape = Enum.PartType.Ball
    eggPart.Position = position
    eggPart.Anchored = true
    eggPart.CanCollide = true
    eggPart.Parent = eggModel
    
    if eggName == "Small Claw" then
        eggPart.BrickColor = BrickColor.new("Brown")
    elseif eggName == "Wide Eyes" then
        eggPart.BrickColor = BrickColor.new("Light blue")
    elseif eggName == "Long Body" then
        eggPart.BrickColor = BrickColor.new("Dark stone grey")
    elseif eggName == "Big Brain" then
        eggPart.BrickColor = BrickColor.new("Black")
    end
    
    eggModel.Parent = workspace
    
    local eggHumanoid = Instance.new("Humanoid")
    eggHumanoid.MaxHealth = 2000
    eggHumanoid.Health = 2000
    eggHumanoid.Parent = eggModel
    
    -- Create HP bar
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 30)
    billboardGui.Adornee = eggPart
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = eggPart
    
    local hpBarBg = Instance.new("Frame")
    hpBarBg.Size = UDim2.new(1, 0, 1, 0)
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Parent = billboardGui
    
    local hpBar = Instance.new("Frame")
    hpBar.Name = "HPBar"
    hpBar.Size = UDim2.new(1, 0, 1, 0)
    hpBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = hpBarBg
    
    -- Create dark fog for Long Body
    local fog = nil
    if eggName == "Long Body" then
        fog = Instance.new("Part")
        fog.Name = "Fog"
        fog.Size = Vector3.new(50, 50, 50)
        fog.Shape = Enum.PartType.Ball
        fog.Position = position
        fog.Anchored = true
        fog.CanCollide = false
        fog.Transparency = 0.7
        fog.BrickColor = BrickColor.new("Really black")
        fog.Material = Enum.Material.Neon
        fog.Parent = eggModel
    end
    
    eggIllusions[eggName] = {
        model = eggModel,
        humanoid = eggHumanoid,
        part = eggPart,
        hp = 2000,
        maxHp = 2000,
        hpBar = hpBar,
        fog = fog,
        lastAbility = 0
    }
    
    -- Egg abilities
    task.spawn(function()
        while eggIllusions[eggName] and eggIllusions[eggName].hp > 0 do
            local currentTime = tick()
            
            if eggName == "Small Claw" then
                -- Enable Disaster Wolf attack
                if activeIllusions["Disaster Wolf"] then
                    activeIllusions["Disaster Wolf"].canAttack = true
                end
                
            elseif eggName == "Wide Eyes" then
                -- Damage and teleport every 10 seconds
                if currentTime - eggIllusions[eggName].lastAbility >= 10 then
                    eggIllusions[eggName].lastAbility = currentTime
                    
                    local damage = math.random(45, 80)
                    damagePlayer(damage, "Blue")
                    
                    -- Teleport near Disaster Wolf
                    if activeIllusions["Disaster Wolf"] then
                        local disasterPos = activeIllusions["Disaster Wolf"].torso.Position
                        local angle = math.random() * math.pi * 2
                        local newPos = disasterPos + Vector3.new(math.cos(angle) * 20, 0, math.sin(angle) * 20)
                        eggPart.Position = newPos
                        if fog then fog.Position = newPos end
                    end
                end
                
            elseif eggName == "Long Body" then
                -- Protect with fog
                if fog then
                    -- Check if player or eggs in fog
                    for name, egg in pairs(eggIllusions) do
                        if egg.part and (egg.part.Position - fog.Position).Magnitude <= 25 then
                            -- Eggs are protected
                        end
                    end
                    
                    if (hrp.Position - fog.Position).Magnitude <= 25 then
                        if not eggIllusions[eggName].playerInFog then
                            eggIllusions[eggName].playerInFog = true
                            task.spawn(function()
                                while eggIllusions[eggName] and eggIllusions[eggName].playerInFog do
                                    damagePlayer(math.random(7, 10), "Purple")
                                    task.wait(0.5)
                                    
                                    if (hrp.Position - fog.Position).Magnitude > 25 then
                                        eggIllusions[eggName].playerInFog = false
                                    end
                                end
                            end)
                        end
                    else
                        eggIllusions[eggName].playerInFog = false
                    end
                end
                
            elseif eggName == "Big Brain" then
                -- 13% chance to damage and reflect
                if math.random() < 0.13 and currentTime - eggIllusions[eggName].lastAbility >= 1 then
                    eggIllusions[eggName].lastAbility = currentTime
                    
                    local damage = math.random(50, 75)
                    damagePlayer(damage, "Black")
                    
                    -- Activate reflect for 10 seconds
                    eggIllusions[eggName].reflecting = true
                    task.delay(10, function()
                        if eggIllusions[eggName] then
                            eggIllusions[eggName].reflecting = false
                        end
                    end)
                end
            end
            
            task.wait(0.1)
        end
    end)
end

-- Damage Egg
local function damageEgg(eggName, damageAmount)
    local egg = eggIllusions[eggName]
    if not egg then return end
    
    -- Big Brain reflect
    if eggName == "Big Brain" and egg.reflecting then
        damagePlayer(damageAmount, "Black")
        return
    end
    
    -- Long Body fog protection
    if egg.fog then
        local inFog = false
        for name, otherEgg in pairs(eggIllusions) do
            if otherEgg.part and (otherEgg.part.Position - egg.fog.Position).Magnitude <= 25 then
                -- Reduce damage for eggs in fog
                if name == eggName then
                    damageAmount = damageAmount * 0.5
                end
            end
        end
    end
    
    egg.hp = math.max(0, egg.hp - damageAmount)
    
    local hpPercent = egg.hp / egg.maxHp
    egg.hpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
    
    create3DDamageGui(egg.part.Position, damageAmount, "Red", getDamageCategory(damageAmount))
    
    if egg.hp <= 0 then
        removeEgg(eggName)
    end
end

-- Remove Egg
function removeEgg(eggName)
    if eggIllusions[eggName] then
        if eggIllusions[eggName].model then
            eggIllusions[eggName].model:Destroy()
        end
        eggIllusions[eggName] = nil
        
        -- Show death dialogue
        if eggName == "Small Claw" then
            showDialogue("Small Wolf's Claw has been cutted and Its teeth now straighten before, when it was sharp.")
            if activeIllusions["Disaster Wolf"] then
                activeIllusions["Disaster Wolf"].canAttack = false
            end
        elseif eggName == "Wide Eyes" then
            showDialogue("Wide Wolf's Signal were interrupted and cut off.")
        elseif eggName == "Long Body" then
            showDialogue("Long Wolf's Dark Fog were shined away by the sun.")
        elseif eggName == "Big Brain" then
            showDialogue("Big Wolf's Mirror were shattered.")
        end
        
        -- Check if all eggs destroyed
        local allDestroyed = true
        for name, egg in pairs(eggIllusions) do
            if egg then
                allDestroyed = false
                break
            end
        end
        
        if allDestroyed and activeIllusions["Disaster Wolf"] then
            -- Disaster Wolf can now be damaged
            activeIllusions["Disaster Wolf"].data.damageReductions = {Red = 0.3, Blue = 0.3, Purple = 0.3, Black = 0.3}
        end
    end
end
    if activeIllusions[name] then
        local illusion = activeIllusions[name]
        if illusion.model then
            illusion.model:Destroy()
        end
        for _, firePart in pairs(illusion.fireTrail) do
            firePart:Destroy()
        end
        activeIllusions[name] = nil
        illusionData[name].enabled = false
    end
end

-- Damage Illusion
local function damageIllusion(illusionName, damageAmount, damageType)
    local illusion = activeIllusions[illusionName]
    if not illusion then return end
    
    -- Disaster Wolf is immune until all eggs destroyed
    if illusionName == "Disaster Wolf" then
        local anyEggsAlive = false
        for name, egg in pairs(eggIllusions) do
            if egg then
                anyEggsAlive = true
                break
            end
        end
        
        if anyEggsAlive then
            create3DDamageGui(illusion.torso.Position, 0, damageType, "IMMUNE")
            return
        end
    end
    
    -- Big Wolf reflect mechanic
    if illusionName == "Big Wolf" then
        if illusion.mirrorMode then
            damagePlayer(damageAmount, damageType)
            create3DDamageGui(illusion.torso.Position, 0, damageType, "IMMUNE")
            return
        elseif math.random() < illusion.reflectChance then
            damagePlayer(damageAmount, damageType)
            create3DDamageGui(illusion.torso.Position, 0, damageType, "IMMUNE")
            return
        end
        
        if math.random() < 0.1 and not illusion.mirrorMode then
            illusion.mirrorMode = true
            illusion.mirrorTimer = 0
            illusion.reflectChance = 1.0
            
            local mirror = illusion.model:FindFirstChild("Mirror")
            if mirror then
                mirror.Transparency = 0.3
                mirror.BrickColor = BrickColor.new("Cyan")
            end
        end
    end
    
    local reduction = illusion.data.damageReductions[damageType] or 1
    local finalDamage = damageAmount * reduction
    
    if illusion.sp <= 0 then
        finalDamage = finalDamage * 0.5
    end
    
    local category = getDamageCategory(finalDamage)
    
    if damageType == "Red" then
        illusion.hp = math.max(0, illusion.hp - finalDamage)
    elseif damageType == "Blue" then
        illusion.sp = math.max(0, illusion.sp - finalDamage)
    elseif damageType == "Purple" then
        illusion.hp = math.max(0, illusion.hp - finalDamage)
        illusion.sp = math.max(0, illusion.sp - finalDamage)
    elseif damageType == "Black" then
        illusion.hp = math.max(0, illusion.hp - finalDamage)
        illusion.pure = math.max(0, illusion.pure - finalDamage * 0.5)
    end
    
    local hpPercent = illusion.hp / illusion.maxHp
    local spPercent = illusion.sp and illusion.sp / illusion.maxSp or 1
    local purePercent = illusion.pure and illusion.pure / illusion.maxPure or 1
    
    illusion.hpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
    if illusion.spBar then
        illusion.spBar.Size = UDim2.new(spPercent, 0, 1, 0)
    end
    if illusion.pureBar then
        illusion.pureBar.Size = UDim2.new(purePercent, 0, 1, 0)
    end
    
    if hpPercent < 1 and illusion.billboardGui then
        illusion.billboardGui.Enabled = true
    end
    
    create3DDamageGui(illusion.torso.Position, finalDamage, damageType, category)
    
    if illusion.hp <= 0 then
        removeIllusion(illusionName)
    end
end

-- WEAPON TOOL SYSTEM
local function createWeaponTool(weaponName)
    local tool = Instance.new("Tool")
    tool.Name = weaponName
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.5, 4, 0.5)
    handle.BrickColor = BrickColor.new("Really black")
    handle.Material = Enum.Material.SmoothPlastic
    handle.Parent = tool
    
    local mesh = Instance.new("CylinderMesh")
    mesh.Scale = Vector3.new(1, 1, 1)
    mesh.Parent = handle
    
    if weaponName == "Baton" then
        handle.BrickColor = BrickColor.new("Dark stone grey")
    elseif weaponName == "Ground" then
        handle.BrickColor = BrickColor.new("Brown")
        handle.Size = Vector3.new(0.7, 5, 0.7)
    elseif weaponName == "3rd Match" then
        handle.BrickColor = BrickColor.new("Really red")
        handle.Size = Vector3.new(0.6, 4.5, 0.6)
        handle.Material = Enum.Material.Neon
        
        local fire = Instance.new("Fire")
        fire.Size = 3
        fire.Heat = 5
        fire.Parent = handle
    elseif weaponName == "Sublock" then
        handle.BrickColor = BrickColor.new("Bright blue")
        handle.Size = Vector3.new(0.8, 4, 0.8)
        handle.Material = Enum.Material.Neon
    elseif weaponName == "Mimic Art" then
        handle.BrickColor = BrickColor.new("Really red")
        handle.Size = Vector3.new(0.7, 5, 0.7)
        handle.Material = Enum.Material.Neon
    end
    
    tool.Equipped:Connect(function()
        playerStats.currentWeapon = weaponName
        print("Equipped: " .. weaponName)
        
        -- Create Mimic Art ability button
        if weaponName == "Mimic Art" then
            if not mimicArtAbilityGui then
                mimicArtAbilityGui = Instance.new("TextButton")
                mimicArtAbilityGui.Size = UDim2.new(0, 100, 0, 50)
                mimicArtAbilityGui.Position = UDim2.new(0, 20, 1, -70)
                mimicArtAbilityGui.Text = "Goodbye"
                mimicArtAbilityGui.Font = Enum.Font.GothamBold
                mimicArtAbilityGui.TextScaled = true
                mimicArtAbilityGui.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                mimicArtAbilityGui.TextColor3 = Color3.new(1, 1, 1)
                mimicArtAbilityGui.Parent = screenGui
                
                mimicArtAbilityGui.MouseButton1Click:Connect(function()
                    local weaponInfo = weaponData["Mimic Art"]
                    if not weaponInfo.abilityReady then return end
                    
                    weaponInfo.abilityReady = false
                    
                    -- Play activate sound
                    local activateSound = Instance.new("Sound")
                    activateSound.SoundId = weaponInfo.abilityActivateSound
                    activateSound.Volume = 0.6
                    activateSound.Parent = hrp
                    activateSound:Play()
                    
                    -- Create red box
                    local redBox = Instance.new("Part")
                    redBox.Size = Vector3.new(45, 45, 45)
                    redBox.Position = hrp.Position + hrp.CFrame.LookVector * 22.5
                    redBox.Anchored = true
                    redBox.CanCollide = false
                    redBox.Transparency = 0.5
                    redBox.BrickColor = BrickColor.new("Really red")
                    redBox.Material = Enum.Material.Neon
                    redBox.Parent = workspace
                    
                    -- Damage illusions in box
                    local damageLoop = true
                    task.spawn(function()
                        while damageLoop do
                            for name, illusion in pairs(activeIllusions) do
                                if illusion.torso then
                                    local pos = illusion.torso.Position
                                    local boxPos = redBox.Position
                                    local halfSize = 22.5
                                    
                                    if math.abs(pos.X - boxPos.X) <= halfSize and
                                       math.abs(pos.Y - boxPos.Y) <= halfSize and
                                       math.abs(pos.Z - boxPos.Z) <= halfSize then
                                        local damage = math.random(12, 30)
                                        damageIllusion(name, damage, "Red")
                                        
                                        -- Play hit sound
                                        local hitSound = Instance.new("Sound")
                                        hitSound.SoundId = weaponInfo.abilityHitSound
                                        hitSound.Volume = 0.4
                                        hitSound.Parent = illusion.torso
                                        hitSound:Play()
                                    end
                                end
                            end
                            task.wait(0.5)
                        end
                    end)
                    
                    -- Destroy after 1 second
                    task.delay(1, function()
                        damageLoop = false
                        redBox:Destroy()
                    end)
                    
                    -- Cooldown
                    mimicArtAbilityGui.Text = "30s"
                    task.spawn(function()
                        for i = 30, 1, -1 do
                            mimicArtAbilityGui.Text = i .. "s"
                            task.wait(1)
                        end
                        mimicArtAbilityGui.Text = "Goodbye"
                        weaponInfo.abilityReady = true
                    end)
                end)
            end
            mimicArtAbilityGui.Visible = true
        end
    end)
    
    tool.Unequipped:Connect(function()
        if mimicArtAbilityGui then
            mimicArtAbilityGui.Visible = false
        end
    end)
    
    tool.Activated:Connect(function()
        if attackCooldown then return end
        
        local weaponInfo = weaponData[weaponName]
        if not weaponInfo then return end
        
        attackCooldown = true
        
        -- Mimic Art dash
        if weaponName == "Mimic Art" then
            local dashDirection = hrp.CFrame.LookVector
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = dashDirection * weaponInfo.dashSpeed
            bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
            bodyVelocity.Parent = hrp
            
            task.delay(weaponInfo.dashDuration, function()
                bodyVelocity:Destroy()
            end)
        end
        
        local lookVector = hrp.CFrame.LookVector
        local hitPosition = hrp.Position + lookVector * 8 + Vector3.new(0, 2, 0)
        
        local hitbox = Instance.new("Part")
        hitbox.Size = Vector3.new(10, 10, 10)
        hitbox.Position = hitPosition
        hitbox.Anchored = true
        hitbox.CanCollide = false
        hitbox.Transparency = 0.5
        hitbox.BrickColor = BrickColor.new("Really red")
        hitbox.Material = Enum.Material.Neon
        hitbox.Parent = workspace
        
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Sphere
        mesh.Parent = hitbox
        
        if weaponName == "Sublock" then
            weaponInfo.attackCount = weaponInfo.attackCount + 1
            
            local activeSound = Instance.new("Sound")
            activeSound.SoundId = weaponInfo.attackActiveSound
            activeSound.Volume = 0.5
            activeSound.Parent = hitbox
            activeSound:Play()
            
            local currentDamageType = weaponInfo.damageType
            if weaponInfo.attackCount >= 5 then
                currentDamageType = "Red"
                weaponInfo.attackCount = 0
                hitbox.BrickColor = BrickColor.new("Really red")
            else
                hitbox.BrickColor = BrickColor.new("Bright blue")
            end
            
            local hitboxActive = true
            task.spawn(function()
                local damageLoop = Instance.new("Sound")
                damageLoop.SoundId = weaponInfo.hitSound
                damageLoop.Volume = 0.3
                damageLoop.Looped = true
                damageLoop.Parent = hitbox
                damageLoop:Play()
                
                local startTime = tick()
                while hitboxActive and tick() - startTime < 2 do
                    for name, illusion in pairs(activeIllusions) do
                        if illusion.torso then
                            local distance = (illusion.torso.Position - hitPosition).Magnitude
                            if distance <= 10 then
                                local damage = math.random(weaponInfo.damageScale[1], weaponInfo.damageScale[2]) * getPureMultiplier()
                                damageIllusion(name, damage, currentDamageType)
                            end
                        end
                    end
                    task.wait(0.1)
                end
                
                damageLoop:Stop()
                damageLoop:Destroy()
                hitboxActive = false
            end)
            
            task.delay(2, function()
                hitboxActive = false
                local fadeTween = TweenService:Create(hitbox, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Transparency = 1})
                fadeTween:Play()
                task.delay(0.5, function()
                    hitbox:Destroy()
                end)
            end)
        else
            local hitSomething = false
            for name, illusion in pairs(activeIllusions) do
                if illusion.torso then
                    local distance = (illusion.torso.Position - hitPosition).Magnitude
                    if distance <= 10 then
                        local damage = math.random(weaponInfo.damageScale[1], weaponInfo.damageScale[2]) * getPureMultiplier()
                        damageIllusion(name, damage, weaponInfo.damageType)
                        hitSomething = true
                    end
                end
            end
            
            -- Check for egg hits
            for eggName, egg in pairs(eggIllusions) do
                if egg.part then
                    local distance = (egg.part.Position - hitPosition).Magnitude
                    if distance <= 10 then
                        local damage = math.random(weaponInfo.damageScale[1], weaponInfo.damageScale[2]) * getPureMultiplier()
                        damageEgg(eggName, damage)
                        hitSomething = true
                    end
                end
            end
            
            -- Check for portal hit
            if elkCityPortal and elkCityPortal.part then
                local distance = (elkCityPortal.part.Position - hitPosition).Magnitude
                if distance <= 10 then
                    local damage = math.random(weaponInfo.damageScale[1], weaponInfo.damageScale[2]) * getPureMultiplier()
                    elkCityPortal.hp = math.max(0, elkCityPortal.hp - damage)
                    
                    local hpPercent = elkCityPortal.hp / elkCityPortal.maxHp
                    elkCityPortal.hpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
                    
                    create3DDamageGui(elkCityPortal.part.Position, damage, weaponInfo.damageType, getDamageCategory(damage))
                    hitSomething = true
                    
                    -- Portal destroyed
                    if elkCityPortal.hp <= 0 then
                        elkCityPortal.part:Destroy()
                        elkCityPortal = nil
                        
                        -- All wolves return to attacking
                        for wolfName, illusion in pairs(activeIllusions) do
                            if wolfName == "Small Wolf" or wolfName == "Wide Wolf" or 
                               wolfName == "Long Wolf" or wolfName == "Big Wolf" then
                                illusion.movingToPortal = false
                                illusion.stoppedAttacking = false
                                illusion.model.Parent = workspace
                            end
                        end
                    end
                end
            end
            
            if hitSomething and weaponInfo.hitSound then
                local hitSound = Instance.new("Sound")
                hitSound.SoundId = weaponInfo.hitSound
                hitSound.Volume = 0.5
                hitSound.Parent = hitbox
                hitSound:Play()
            end
            
            local fadeTween = TweenService:Create(hitbox, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Transparency = 1})
            fadeTween:Play()
            
            task.delay(0.5, function()
                hitbox:Destroy()
            end)
        end
        
        local cooldownTime = weaponInfo.cooldown
        task.spawn(function()
            for i = cooldownTime, 1, -1 do
                tool.Name = string.format("%s (Cooldown: %ds)", weaponName, i)
                task.wait(1)
            end
            tool.Name = weaponName
            attackCooldown = false
        end)
    end)
    
    return tool
end

-- Create all weapon tools
for weaponName, _ in pairs(weaponData) do
    weaponTools[weaponName] = createWeaponTool(weaponName)
end

-- Give starter weapon
if weaponTools["Baton"] then
    weaponTools["Baton"].Parent = player.Backpack
    task.wait(0.1)
    humanoid:EquipTool(weaponTools["Baton"])
end

-- Populate Weapon Menu
yPos = 0
for name, data in pairs(weaponData) do
    local weaponFrame = Instance.new("Frame")
    weaponFrame.Size = UDim2.new(1, -20, 0, 80)
    weaponFrame.Position = UDim2.new(0, 10, 0, yPos)
    weaponFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    weaponFrame.Parent = weaponScroll
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.6, 0, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.Text = name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = weaponFrame
    
    local damageLabel = Instance.new("TextLabel")
    damageLabel.Size = UDim2.new(0.5, 0, 0, 20)
    damageLabel.Position = UDim2.new(0, 5, 0, 30)
    damageLabel.Text = string.format("DMG: %d-%d %s", data.damageScale[1], data.damageScale[2], data.damageType)
    damageLabel.Font = Enum.Font.Gotham
    damageLabel.TextScaled = true
    damageLabel.BackgroundTransparency = 1
    damageLabel.TextColor3 = Color3.new(1, 1, 1)
    damageLabel.TextXAlignment = Enum.TextXAlignment.Left
    damageLabel.Parent = weaponFrame
    
    local equipButton = Instance.new("TextButton")
    equipButton.Size = UDim2.new(0, 80, 0, 30)
    equipButton.Position = UDim2.new(1, -90, 0, 5)
    equipButton.Text = "EQUIP"
    equipButton.Font = Enum.Font.GothamBold
    equipButton.TextScaled = true
    equipButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
    equipButton.TextColor3 = Color3.new(1, 1, 1)
    equipButton.Parent = weaponFrame
    
    equipButton.MouseButton1Click:Connect(function()
        playerStats.currentWeapon = name
        
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = player.Backpack
            end
        end
        
        if weaponTools[name] then
            weaponTools[name].Parent = player.Backpack
            task.wait(0.1)
            humanoid:EquipTool(weaponTools[name])
        end
        
        print("Equipped: " .. name)
    end)
    
    yPos = yPos + 90
end

weaponScroll.CanvasSize = UDim2.new(0, 0, 0, yPos)

-- Handle character respawn
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    hrp = newCharacter:WaitForChild("HumanoidRootPart")
    
    playerStats.hp = playerStats.maxHp
    playerStats.sp = playerStats.maxSp
    playerStats.pure = playerStats.maxPure
    playerStats.burning = false
    updateBars()
    
    local currentWeaponTool = player.Backpack:FindFirstChild(playerStats.currentWeapon)
    if currentWeaponTool then
        humanoid:EquipTool(currentWeaponTool)
    end
    
    humanoid.WalkSpeed = 16
    
    humanoid.Died:Connect(function()
        print("You died!")
        if player.PlayerGui:FindFirstChild("BlindEffect") then
            player.PlayerGui.BlindEffect:Destroy()
        end
        if schadenfreudeLoopSound then
            schadenfreudeLoopSound:Destroy()
            schadenfreudeLoopSound = nil
        end
        lookingAtSchadenfreude = false
        playerBlinded = false
    end)
end

onCharacterAdded(character)
player.CharacterAdded:Connect(onCharacterAdded)

-- Update loop
RunService.Heartbeat:Connect(function()
    updateBars()
    
    local healthLossPercent = 1 - (playerStats.hp / playerStats.maxHp)
    local targetPure = playerStats.maxPure * (1 - healthLossPercent)
    playerStats.pure = math.max(0, math.min(playerStats.maxPure, targetPure))
    
    -- Check for disaster wolf event
    checkForDisasterWolfEvent()
end)

print("Illusion Combat System Loaded!")
print("Current Weapon: " .. playerStats.currentWeapon)
print("Current Suit: " .. playerStats.currentSuit)
