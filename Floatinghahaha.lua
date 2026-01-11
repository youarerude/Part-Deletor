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
    ["Statue of Torture"] = {
        description = "A statue that moves when you're not looking...",
        hp = 5400,
        sp = 5522,
        pure = 5000,
        moveSpeed = 20,
        enragedSpeed = 50,
        attackRange = 5,
        damageReductions = {Red = 0.3, Blue = 0.3, Purple = 0.0, Black = 0.4},
        damageType = "Purple",
        damageScale = {90, 189},
        dangerClass = "LAMMED",
        enabled = false,
        attackCount = 0,
        isEnraged = false,
        modelId = "12860242039",
        abilityChance = 0.25
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

-- Spawn Illusion Function
function spawnIllusion(name, data)
    if activeIllusions[name] then return end
    
    local illusionModel = Instance.new("Model")
    illusionModel.Name = name
    
    local torso, head, leftArm, rightArm
    
    -- Special handling for Statue of Torture
    if name == "Statue of Torture" then
        -- Load the statue model
        local InsertService = game:GetService("InsertService")
        local success, statueModel = pcall(function()
            return InsertService:LoadAsset(data.modelId)
        end)
        
        if success and statueModel then
            local actualModel = statueModel:GetChildren()[1]
            if actualModel then
                actualModel.Parent = illusionModel
                actualModel:SetPrimaryPartCFrame(CFrame.new(hrp.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))))
                
                -- Find the primary part or create one
                torso = actualModel.PrimaryPart or actualModel:FindFirstChildWhichIsA("BasePart")
                if not torso then
                    torso = Instance.new("Part")
                    torso.Name = "Torso"
                    torso.Size = Vector3.new(2, 2, 2)
                    torso.Anchored = false
                    torso.CanCollide = true
                    torso.Parent = actualModel
                end
                
                head = torso
            end
            statueModel:Destroy()
        else
            -- Fallback if model doesn't load
            torso = Instance.new("Part")
            torso.Name = "Torso"
            torso.Size = Vector3.new(3, 5, 3)
            torso.Position = hrp.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
            torso.Anchored = false
            torso.CanCollide = true
            torso.BrickColor = BrickColor.new("Dark stone grey")
            torso.Material = Enum.Material.Concrete
            torso.Parent = illusionModel
            head = torso
        end
    else
        -- Normal illusion creation
        torso = Instance.new("Part")
        torso.Name = "Torso"
        torso.Size = Vector3.new(2, 2, 1)
        torso.Position = hrp.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
        torso.Anchored = false
        torso.CanCollide = true
        torso.BrickColor = BrickColor.new("Bright red")
        torso.Parent = illusionModel
        
        head = Instance.new("Part")
        head.Name = "Head"
        head.Size = Vector3.new(2, 1, 1)
        head.Position = torso.Position + Vector3.new(0, 1.5, 0)
        head.Anchored = false
        head.CanCollide = true
        head.BrickColor = BrickColor.new("Bright red")
        head.Parent = illusionModel
        
        leftArm = Instance.new("Part")
        leftArm.Name = "LeftArm"
        leftArm.Size = Vector3.new(1, 2, 1)
        leftArm.Position = torso.Position + Vector3.new(-1.5, 0, 0)
        leftArm.Anchored = false
        leftArm.CanCollide = false
        leftArm.BrickColor = BrickColor.new("Bright red")
        leftArm.Parent = illusionModel
        
        rightArm = Instance.new("Part")
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
    end
    
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
        isEnraged = false,
        lookingAt = false,
        abilityActive = false
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
            
            -- Statue of Torture mechanics
            if name == "Statue of Torture" then
                local camera = workspace.CurrentCamera
                local cameraLook = camera.CFrame.LookVector
                local toStatue = (torso.Position - camera.CFrame.Position).Unit
                local dotProduct = cameraLook:Dot(toStatue)
                
                -- Check if player is looking at statue (dot product > 0.7)
                local playerLookingAtStatue = dotProduct > 0.7 and distance < 60
                illusion.lookingAt = playerLookingAtStatue
                
                -- Movement logic
                if illusion.isEnraged then
                    -- Enraged mode: always move
                    illusionHumanoid.WalkSpeed = data.enragedSpeed
                    illusionHumanoid:MoveTo(hrp.Position)
                elseif playerLookingAtStatue then
                    -- Player looking: freeze
                    illusionHumanoid.WalkSpeed = 0
                else
                    -- Player not looking: move
                    illusionHumanoid.WalkSpeed = data.moveSpeed
                    illusionHumanoid:MoveTo(hrp.Position)
                end
                
                -- Attack on touch
                if distance <= data.attackRange then
                    local currentTime = tick()
                    if currentTime - illusion.lastAttack >= 1 then
                        illusion.lastAttack = currentTime
                        illusion.attackCount = illusion.attackCount + 1
                        
                        -- Check for enraged mode (every 5th attack)
                        if illusion.attackCount >= 5 then
                            illusion.attackCount = 0
                            illusion.isEnraged = true
                            
                            -- Play enraged sound
                            local enragedSound = Instance.new("Sound")
                            enragedSound.SoundId = "rbxassetid://5673404366"
                            enragedSound.Volume = 0.6
                            enragedSound.Parent = torso
                            enragedSound:Play()
                            
                            -- Create red fog
                            local redFog = Instance.new("ColorCorrectionEffect")
                            redFog.Name = "RedFog"
                            redFog.TintColor = Color3.fromRGB(255, 0, 0)
                            redFog.Saturation = 0.5
                            redFog.Parent = game.Lighting
                            
                            -- Deal 3x damage
                            local enragedDamage = math.random(data.damageScale[1], data.damageScale[2]) * 3
                            damagePlayer(enragedDamage, data.damageType)
                            
                            -- Play touch sound
                            local touchSound = Instance.new("Sound")
                            touchSound.SoundId = "rbxassetid://70542612197339"
                            touchSound.Volume = 0.5
                            touchSound.Parent = hrp
                            touchSound:Play()
                            
                            -- Blind and teleport
                            local blindGui = Instance.new("ScreenGui")
                            blindGui.Name = "StatueBlind"
                            blindGui.Parent = player.PlayerGui
                            
                            local blindFrame = Instance.new("Frame")
                            blindFrame.Size = UDim2.new(1, 0, 1, 0)
                            blindFrame.BackgroundColor3 = Color3.new(0, 0, 0)
                            blindFrame.BackgroundTransparency = 0
                            blindFrame.Parent = blindGui
                            
                            -- Fade out blindness
                            task.delay(0.5, function()
                                local fadeTween = TweenService:Create(blindFrame, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {BackgroundTransparency = 1})
                                fadeTween:Play()
                                task.delay(1.5, function()
                                    blindGui:Destroy()
                                end)
                            end)
                            
                            -- Teleport player
                            local teleportDistance = math.random(1, 100)
                            local randomAngle = math.random() * math.pi * 2
                            local teleportOffset = Vector3.new(
                                math.cos(randomAngle) * teleportDistance,
                                0,
                                math.sin(randomAngle) * teleportDistance
                            )
                            hrp.CFrame = hrp.CFrame + teleportOffset
                            
                            -- End enraged mode after 2 seconds
                            task.delay(2, function()
                                illusion.isEnraged = false
                                if redFog then
                                    redFog:Destroy()
                                end
                            end)
                        else
                            -- Normal attack
                            local normalDamage = math.random(data.damageScale[1], data.damageScale[2])
                            damagePlayer(normalDamage, data.damageType)
                            
                            -- Play touch sound
                            local touchSound = Instance.new("Sound")
                            touchSound.SoundId = "rbxassetid://70542612197339"
                            touchSound.Volume = 0.5
                            touchSound.Parent = hrp
                            touchSound:Play()
                            
                            -- Blind and teleport
                            local blindGui = Instance.new("ScreenGui")
                            blindGui.Name = "StatueBlind"
                            blindGui.Parent = player.PlayerGui
                            
                            local blindFrame = Instance.new("Frame")
                            blindFrame.Size = UDim2.new(1, 0, 1, 0)
                            blindFrame.BackgroundColor3 = Color3.new(0, 0, 0)
                            blindFrame.BackgroundTransparency = 0
                            blindFrame.Parent = blindGui
                            
                            -- Fade out blindness
                            task.delay(0.5, function()
                                local fadeTween = TweenService:Create(blindFrame, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {BackgroundTransparency = 1})
                                fadeTween:Play()
                                task.delay(1.5, function()
                                    blindGui:Destroy()
                                end)
                            end)
                            
                            -- Teleport player
                            local teleportDistance = math.random(1, 100)
                            local randomAngle = math.random() * math.pi * 2
                            local teleportOffset = Vector3.new(
                                math.cos(randomAngle) * teleportDistance,
                                0,
                                math.sin(randomAngle) * teleportDistance
                            )
                            hrp.CFrame = hrp.CFrame + teleportOffset
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
                illusionHumanoid:MoveTo(hrp.Position)
                
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
                if currentTime - illusion.lastAttack >= data.attackCooldown then
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
                            damagePlayer(damage, data.damageType)
                            
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

-- Remove Illusion
function removeIllusion(name)
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
    local spPercent = illusion.sp / illusion.maxSp
    local purePercent = illusion.pure / illusion.maxPure
    
    illusion.hpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
    illusion.spBar.Size = UDim2.new(spPercent, 0, 1, 0)
    illusion.pureBar.Size = UDim2.new(purePercent, 0, 1, 0)
    
    if hpPercent < 1 then
        illusion.billboardGui.Enabled = true
    end
    
    create3DDamageGui(illusion.torso.Position, finalDamage, damageType, category)
    
    -- Statue of Torture ability trigger
    if illusionName == "Statue of Torture" and not illusion.abilityActive then
        if math.random() < illusion.data.abilityChance then
            illusion.abilityActive = true
            
            -- Play ability sound
            local abilitySound = Instance.new("Sound")
            abilitySound.SoundId = "rbxassetid://129247666293361"
            abilitySound.Volume = 0.6
            abilitySound.Parent = illusion.torso
            abilitySound:Play()
            
            -- Spawn beams
            task.spawn(function()
                for i = 1, 10 do
                    -- Random position within 50 studs of player
                    local randomOffset = Vector3.new(
                        math.random(-50, 50),
                        0,
                        math.random(-50, 50)
                    )
                    local beamPosition = hrp.Position + randomOffset
                    
                    -- Create beam
                    local beam = Instance.new("Part")
                    beam.Size = Vector3.new(5, 100, 5)
                    beam.Position = beamPosition + Vector3.new(0, 50, 0)
                    beam.Anchored = true
                    beam.CanCollide = false
                    beam.BrickColor = BrickColor.new("Bright violet")
                    beam.Material = Enum.Material.Neon
                    beam.Transparency = 0.3
                    beam.Parent = workspace
                    
                    -- Check if player is in beam
                    local beamDistance = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(beamPosition.X, 0, beamPosition.Z)).Magnitude
                    if beamDistance <= 5 then
                        local beamDamage = math.random(30, 50)
                        damagePlayer(beamDamage, "Purple")
                    end
                    
                    -- Beam lasts 4 seconds then disappears for 1 second
                    task.delay(4, function()
                        beam.Transparency = 1
                        task.delay(1, function()
                            beam:Destroy()
                        end)
                    end)
                    
                    task.wait(0.1)
                end
                
                illusion.abilityActive = false
            end)
        end
    end
    
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
end)

print("Illusion Combat System Loaded!")
print("Current Weapon: " .. playerStats.currentWeapon)
print("Current Suit: " .. playerStats.currentSuit)
