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

-- Disaster Wolf Event State
local disasterWolfEvent = {
    active = false,
    completed = false,
    portalSpawned = false,
    portalHp = 7500,
    portalMaxHp = 7500,
    wolvesEntered = {
        ["Small Wolf"] = false,
        ["Wide Wolf"] = false,
        ["Long Wolf"] = false,
        ["Big Wolf"] = false
    },
    dialogueQueue = {},
    currentDialogue = nil,
    disasterWolfSpawned = false,
    eggs = {
        ["Small Claw"] = {alive = false, hp = 7250, maxHp = 7250},
        ["Wide Eyes"] = {alive = false, hp = 5899, maxHp = 5899},
        ["Long Body"] = {alive = false, hp = 6892, maxHp = 6892},
        ["Big Brain"] = {alive = false, hp = 8100, maxHp = 8100}
    },
    disasterWolfHp = 23000,
    disasterWolfMaxHp = 23000,
    smallClawEnabled = true,
    wideEyesTimer = 0,
    bigBrainReflect = false,
    bigBrainReflectTimer = 0,
    attackTimer = 0
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
    },
    ["Cerberus Suit"] = {
        reductions = {Red = 0.2, Blue = 0.2, Purple = 0.2, Black = 0.4},
        dangerClass = "LAMMED",
        enabled = false,
        reflectChance = 0.5,
        absorbRedBlueChance = 0.2,
        lowHpBoost = false
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
    },
    Cerberus = {
        damageTypes = {"Red", "Blue", "Purple", "Black"},
        damageScale = {50, 125},
        cooldown = 5,
        dangerClass = "LAMMED",
        hitSound = "rbxassetid://136833367092810",
        special = true,
        hitboxRange = 20,
        abilities = {
            smallClaw = {ready = true, cooldown = 15},
            wideEyes = {ready = true, cooldown = 30},
            longBody = {ready = true, cooldown = 120},
            bigBrain = {ready = true, cooldown = 60}
        }
    }
}

local activeIllusions = {}
local weaponTools = {}
local attackCooldown = false
local playerBlinded = false
local lookingAtSchadenfreude = false
local schadenfreudeLoopSound = nil
local mimicArtAbilityGui = nil
local cerberusAbilityGuis = {}
local playerTroops = {}
local cerberusFog = nil
local cerberusFogActive = false

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

-- Dialogue Display at Bottom
local dialogueFrame = Instance.new("Frame")
dialogueFrame.Name = "DialogueFrame"
dialogueFrame.Size = UDim2.new(0.8, 0, 0, 80)
dialogueFrame.Position = UDim2.new(0.1, 0, 1, -100)
dialogueFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dialogueFrame.BackgroundTransparency = 0.3
dialogueFrame.BorderSizePixel = 2
dialogueFrame.Visible = false
dialogueFrame.Parent = screenGui

local dialogueLabel = Instance.new("TextLabel")
dialogueLabel.Name = "DialogueText"
dialogueLabel.Size = UDim2.new(1, -20, 1, -20)
dialogueLabel.Position = UDim2.new(0, 10, 0, 10)
dialogueLabel.BackgroundTransparency = 1
dialogueLabel.Text = ""
dialogueLabel.TextColor3 = Color3.new(1, 1, 1)
dialogueLabel.TextSize = 24
dialogueLabel.Font = Enum.Font.GothamBold
dialogueLabel.TextWrapped = true
dialogueLabel.TextXAlignment = Enum.TextXAlignment.Left
dialogueLabel.TextYAlignment = Enum.TextYAlignment.Top
dialogueLabel.Parent = dialogueFrame

-- Function to display dialogue with typing animation
local function showDialogue(text)
    dialogueFrame.Visible = true
    dialogueLabel.Text = ""
    
    task.spawn(function()
        for i = 1, #text do
            dialogueLabel.Text = string.sub(text, 1, i)
            task.wait(0.03)
        end
        
        task.wait(3)
        
        if #disasterWolfEvent.dialogueQueue > 0 then
            local nextDialogue = table.remove(disasterWolfEvent.dialogueQueue, 1)
            showDialogue(nextDialogue)
        else
            dialogueFrame.Visible = false
        end
    end)
end

-- Function to queue dialogue
local function queueDialogue(text)
    if dialogueFrame.Visible then
        table.insert(disasterWolfEvent.dialogueQueue, text)
    else
        showDialogue(text)
    end
end

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
        -- Cerberus Suit special mechanics
        if currentSuit == "Cerberus Suit" then
            -- 50% chance to reflect
            if math.random() < suitData[currentSuit].reflectChance then
                -- Reflect damage back (handled in damageIllusion function)
                create3DDamageGui(hrp.Position, 0, damageType, "IMMUNE")
                return
            end
            
            -- 20% chance to absorb Red/Blue
            if (damageType == "Red" or damageType == "Blue") and math.random() < suitData[currentSuit].absorbRedBlueChance then
                reduction = -2
            else
                reduction = suitData[currentSuit].reductions[damageType] or 1
            end
            
            -- Low HP boost check
            if playerStats.hp <= 35 and not suitData[currentSuit].lowHpBoost then
                suitData[currentSuit].lowHpBoost = true
                
                -- Create shadow fog around player
                cerberusFog = Instance.new("Part")
                cerberusFog.Name = "CerberusFog"
                cerberusFog.Size = Vector3.new(50, 50, 50)
                cerberusFog.Shape = Enum.PartType.Ball
                cerberusFog.Anchored = true
                cerberusFog.CanCollide = false
                cerberusFog.Transparency = 0.7
                cerberusFog.BrickColor = BrickColor.new("Really black")
                cerberusFog.Material = Enum.Material.Neon
                cerberusFog.Parent = workspace
            end
        -- Mimic Art Suit special: 30% chance to absorb
        elseif currentSuit == "Mimic Art Suit" and suitData[currentSuit].absorbChance then
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
    
    -- Cerberus Suit 5x damage multiplier when low HP
    if currentSuit == "Cerberus Suit" and suitData[currentSuit].lowHpBoost then
        -- This multiplier is applied to outgoing damage in damageIllusion function
    end
    
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
    -- Cerberus Suit absorb
    elseif currentSuit == "Cerberus Suit" and finalDamage < 0 then
        local heal = math.abs(finalDamage)
        playerStats.hp = math.min(playerStats.maxHp, playerStats.hp + heal)
        playerStats.pure = math.min(playerStats.maxPure, playerStats.pure + heal)
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

-- Check if all 4 wolves are spawned for Disaster Wolf Event
local function checkDisasterWolfEvent()
    if disasterWolfEvent.completed then return end
    
    local allWolvesSpawned = activeIllusions["Small Wolf"] and 
                             activeIllusions["Wide Wolf"] and 
                             activeIllusions["Long Wolf"] and 
                             activeIllusions["Big Wolf"]
    
    if allWolvesSpawned and not disasterWolfEvent.portalSpawned then
        disasterWolfEvent.active = true
        disasterWolfEvent.portalSpawned = true
        
        -- Set all wolves' speed to 8
        for wolfName, _ in pairs(disasterWolfEvent.wolvesEntered) do
            if activeIllusions[wolfName] and activeIllusions[wolfName].humanoid then
                activeIllusions[wolfName].humanoid.WalkSpeed = 8
            end
        end
        
        spawnElkCityPortal()
    end
end

-- Spawn Elk City Portal
function spawnElkCityPortal()
    local angle = math.random() * math.pi * 2
    local distance = math.random(50, 100)
    local portalPosition = hrp.Position + Vector3.new(
        math.cos(angle) * distance,
        0,
        math.sin(angle) * distance
    )
    
    local portal = Instance.new("Part")
    portal.Name = "ElkCityPortal"
    portal.Size = Vector3.new(15, 20, 1)
    portal.Position = portalPosition
    portal.Anchored = true
    portal.CanCollide = false
    portal.BrickColor = BrickColor.new("Bright violet")
    portal.Material = Enum.Material.Neon
    portal.Transparency = 0.3
    portal.Parent = workspace
    
    -- Portal health bar
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 40)
    billboardGui.Adornee = portal
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = portal
    
    local hpBarBg = Instance.new("Frame")
    hpBarBg.Size = UDim2.new(1, 0, 0, 30)
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Parent = billboardGui
    
    local portalHpBar = Instance.new("Frame")
    portalHpBar.Name = "PortalHPBar"
    portalHpBar.Size = UDim2.new(1, 0, 1, 0)
    portalHpBar.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    portalHpBar.BorderSizePixel = 0
    portalHpBar.Parent = hpBarBg
    
    local hpLabel = Instance.new("TextLabel")
    hpLabel.Size = UDim2.new(1, 0, 1, 0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Text = string.format("Elk City Portal: %.0f/%.0f", disasterWolfEvent.portalHp, disasterWolfEvent.portalMaxHp)
    hpLabel.TextColor3 = Color3.new(1, 1, 1)
    hpLabel.TextScaled = true
    hpLabel.Font = Enum.Font.GothamBold
    hpLabel.Parent = hpBarBg
    
    -- Store portal reference
    disasterWolfEvent.portalPart = portal
    disasterWolfEvent.portalHpBar = portalHpBar
    disasterWolfEvent.portalHpLabel = hpLabel
    
    -- Show first dialogue
    queueDialogue("Long ago, 4 wolf happily live in the elk city.")
    
    -- Make wolves move to portal
    for wolfName, _ in pairs(disasterWolfEvent.wolvesEntered) do
        if activeIllusions[wolfName] then
            activeIllusions[wolfName].movingToPortal = true
        end
    end
end

-- Function to handle wolf entering portal
local function wolfEnterPortal(wolfName)
    if disasterWolfEvent.wolvesEntered[wolfName] then return end
    
    disasterWolfEvent.wolvesEntered[wolfName] = true
    
    -- Show dialogue
    if wolfName == "Small Wolf" then
        queueDialogue("Small Wolf's Claw and Teeth punishes those who sins.")
    elseif wolfName == "Wide Wolf" then
        queueDialogue("Wide Wolf's Radio signal pulses occasionally detecting and guarding every animal's movement, caught those who sins.")
    elseif wolfName == "Long Wolf" then
        queueDialogue("Long Wolf's Fog cures all past and future sins away from all animals, It is too late if the animal sins too much.")
    elseif wolfName == "Big Wolf" then
        queueDialogue("Big Wolf's Mirror reflects all animal's past, present, and future sins.")
    end
    
    -- Hide wolf
    if activeIllusions[wolfName] and activeIllusions[wolfName].model then
        activeIllusions[wolfName].model.Parent = nil
    end
    
    -- Check if all wolves entered
    local allEntered = true
    for _, entered in pairs(disasterWolfEvent.wolvesEntered) do
        if not entered then
            allEntered = false
            break
        end
    end
    
    if allEntered then
        task.wait(1)
        queueDialogue("Suddenly, a cry out from the Elk City far away occured :")
        task.wait(5)
        
        -- Play dialogue start sound
        local dialogueSound = Instance.new("Sound")
        dialogueSound.SoundId = "rbxassetid://96913434421788"
        dialogueSound.Volume = 0.6
        dialogueSound.Parent = workspace
        dialogueSound:Play()
        
        queueDialogue("Its the beast! The big black Beast in the Dusky City!")
        task.wait(5)
        spawnDisasterWolf()
    end
end

-- Spawn Disaster Wolf Boss
function spawnDisasterWolf()
    if disasterWolfEvent.disasterWolfSpawned then return end
    disasterWolfEvent.disasterWolfSpawned = true
    
    -- Random position 75-200 studs from player
    local angle = math.random() * math.pi * 2
    local distance = math.random(75, 200)
    local bossPosition = hrp.Position + Vector3.new(
        math.cos(angle) * distance,
        0,
        math.sin(angle) * distance
    )
    
    -- Create Disaster Wolf
    local disasterModel = Instance.new("Model")
    disasterModel.Name = "Disaster Wolf"
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(8, 8, 4)
    torso.Position = bossPosition
    torso.Anchored = true
    torso.CanCollide = false
    torso.BrickColor = BrickColor.new("Really black")
    torso.Material = Enum.Material.Neon
    torso.Parent = disasterModel
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(6, 4, 4)
    head.Position = torso.Position + Vector3.new(0, 6, 0)
    head.Anchored = true
    head.CanCollide = false
    head.BrickColor = BrickColor.new("Really black")
    head.Material = Enum.Material.Neon
    head.Parent = disasterModel
    
    disasterModel.Parent = workspace
    
    -- Boss health bar
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 400, 0, 60)
    billboardGui.Adornee = head
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = head
    
    local hpBarBg = Instance.new("Frame")
    hpBarBg.Size = UDim2.new(1, 0, 0, 40)
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Parent = billboardGui
    
    local bossHpBar = Instance.new("Frame")
    bossHpBar.Name = "BossHPBar"
    bossHpBar.Size = UDim2.new(1, 0, 1, 0)
    bossHpBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    bossHpBar.BorderSizePixel = 0
    bossHpBar.Parent = hpBarBg
    
    local hpLabel = Instance.new("TextLabel")
    hpLabel.Size = UDim2.new(1, 0, 1, 0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Text = string.format("Disaster Wolf: %.0f/%.0f", disasterWolfEvent.disasterWolfHp, disasterWolfEvent.disasterWolfMaxHp)
    hpLabel.TextColor3 = Color3.new(1, 1, 1)
    hpLabel.TextScaled = true
    hpLabel.Font = Enum.Font.GothamBold
    hpLabel.Parent = hpBarBg
    
    disasterWolfEvent.disasterModel = disasterModel
    disasterWolfEvent.disasterTorso = torso
    disasterWolfEvent.disasterHead = head
    disasterWolfEvent.bossHpBar = bossHpBar
    disasterWolfEvent.bossHpLabel = hpLabel
    
    -- Play boss music
    local bossMusic = Instance.new("Sound")
    bossMusic.SoundId = "rbxassetid://107432939350823"
    bossMusic.Volume = 0.6
    bossMusic.Looped = true
    bossMusic.Parent = torso
    bossMusic:Play()
    
    disasterWolfEvent.bossMusic = bossMusic
    
    -- Play boss music on player (not 3D)
    local playerBossMusic = Instance.new("Sound")
    playerBossMusic.SoundId = "rbxassetid://107432939350823"
    playerBossMusic.Volume = 0.6
    playerBossMusic.Looped = true
    playerBossMusic.Parent = player:WaitForChild("PlayerGui")
    playerBossMusic:Play()
    
    disasterWolfEvent.playerBossMusic = playerBossMusic
    
    -- Spawn eggs at random positions 75-200 studs
    local eggPositions = {}
    for i = 1, 4 do
        local eggAngle = math.random() * math.pi * 2
        local eggDistance = math.random(75, 200)
        table.insert(eggPositions, hrp.Position + Vector3.new(
            math.cos(eggAngle) * eggDistance,
            0,
            math.sin(eggAngle) * eggDistance
        ))
    end
    
    spawnEgg("Small Claw", eggPositions[1], Color3.fromRGB(139, 69, 19))
    spawnEgg("Wide Eyes", eggPositions[2], Color3.fromRGB(173, 216, 230))
    spawnEgg("Long Body", eggPositions[3], Color3.fromRGB(105, 105, 105))
    spawnEgg("Big Brain", eggPositions[4], Color3.fromRGB(0, 0, 0))
end

-- Spawn Egg
function spawnEgg(eggName, position, color)
    local egg = Instance.new("Part")
    egg.Name = eggName
    egg.Size = Vector3.new(4, 6, 4)
    egg.Shape = Enum.PartType.Ball
    egg.Position = position
    egg.Anchored = true
    egg.CanCollide = false
    egg.BrickColor = BrickColor.new(color)
    egg.Material = Enum.Material.SmoothPlastic
    egg.Parent = workspace
    
    -- Egg health bar
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 40)
    billboardGui.Adornee = egg
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = egg
    
    local hpBarBg = Instance.new("Frame")
    hpBarBg.Size = UDim2.new(1, 0, 0, 30)
    hpBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBarBg.BorderSizePixel = 0
    hpBarBg.Parent = billboardGui
    
    local eggHpBar = Instance.new("Frame")
    eggHpBar.Name = "EggHPBar"
    eggHpBar.Size = UDim2.new(1, 0, 1, 0)
    eggHpBar.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    eggHpBar.BorderSizePixel = 0
    eggHpBar.Parent = hpBarBg
    
    local hpLabel = Instance.new("TextLabel")
    hpLabel.Size = UDim2.new(1, 0, 1, 0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Text = string.format("%s: %.0f/%.0f", eggName, disasterWolfEvent.eggs[eggName].hp, disasterWolfEvent.eggs[eggName].maxHp)
    hpLabel.TextColor3 = Color3.new(1, 1, 1)
    hpLabel.TextScaled = true
    hpLabel.Font = Enum.Font.GothamBold
    hpLabel.Parent = hpBarBg
    
    disasterWolfEvent.eggs[eggName].part = egg
    disasterWolfEvent.eggs[eggName].hpBar = eggHpBar
    disasterWolfEvent.eggs[eggName].hpLabel = hpLabel
    disasterWolfEvent.eggs[eggName].alive = true
    
    -- Long Body creates independent dark fog for each egg
    if eggName == "Long Body" then
        -- Create fog for each egg
        for name, eggData in pairs(disasterWolfEvent.eggs) do
            local fog = Instance.new("Part")
            fog.Name = "DarkFog_" .. name
            fog.Size = Vector3.new(80, 80, 80)
            fog.Shape = Enum.PartType.Ball
            fog.Position = position
            fog.Anchored = true
            fog.CanCollide = false
            fog.Transparency = 0.7
            fog.BrickColor = BrickColor.new("Really black")
            fog.Material = Enum.Material.Neon
            fog.Parent = workspace
            
            if not disasterWolfEvent.eggs[eggName].fogs then
                disasterWolfEvent.eggs[eggName].fogs = {}
            end
            disasterWolfEvent.eggs[eggName].fogs[name] = fog
        end
        
        -- Fog on Disaster Wolf
        local disasterFog = Instance.new("Part")
        disasterFog.Name = "DisasterFog"
        disasterFog.Size = Vector3.new(100, 100, 100)
        disasterFog.Shape = Enum.PartType.Ball
        disasterFog.Anchored = true
        disasterFog.CanCollide = false
        disasterFog.Transparency = 0.7
        disasterFog.BrickColor = BrickColor.new("Really black")
        disasterFog.Material = Enum.Material.Neon
        disasterFog.Parent = workspace
        
        disasterWolfEvent.disasterFog = disasterFog
    end
end

-- Damage Portal
local function damagePortal(damage)
    if not disasterWolfEvent.portalSpawned or disasterWolfEvent.portalHp <= 0 then return end
    
    disasterWolfEvent.portalHp = math.max(0, disasterWolfEvent.portalHp - damage)
    
    local hpPercent = disasterWolfEvent.portalHp / disasterWolfEvent.portalMaxHp
    disasterWolfEvent.portalHpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
    disasterWolfEvent.portalHpLabel.Text = string.format("Elk City Portal: %.0f/%.0f", disasterWolfEvent.portalHp, disasterWolfEvent.portalMaxHp)
    
    if disasterWolfEvent.portalHp <= 0 then
        -- Portal destroyed
        if disasterWolfEvent.portalPart then
            disasterWolfEvent.portalPart:Destroy()
        end
        
        -- Wolves come back
        for wolfName, _ in pairs(disasterWolfEvent.wolvesEntered) do
            if illusionData[wolfName] then
                illusionData[wolfName].enabled = true
                spawnIllusion(wolfName, illusionData[wolfName])
                if activeIllusions[wolfName] then
                    activeIllusions[wolfName].movingToPortal = false
                end
            end
        end
        
        disasterWolfEvent.portalSpawned = false
    end
end

-- Damage Egg
local function damageEgg(eggName, damage, damageType)
    if not disasterWolfEvent.eggs[eggName].alive then return end
    
    local egg = disasterWolfEvent.eggs[eggName]
    local reduction = 1
    
    if eggName == "Small Claw" then
        if damageType == "Red" then reduction = -2
        elseif damageType == "Blue" then reduction = 0.4
        elseif damageType == "Purple" then reduction = 0.6
        elseif damageType == "Black" then reduction = 0.7 end
    elseif eggName == "Wide Eyes" then
        if damageType == "Red" then reduction = 0.2
        elseif damageType == "Blue" then reduction = -2
        elseif damageType == "Purple" then reduction = 0.4
        elseif damageType == "Black" then reduction = 0.5 end
    elseif eggName == "Long Body" then
        if damageType == "Red" then reduction = 0.5
        elseif damageType == "Blue" then reduction = 0.4
        elseif damageType == "Purple" then reduction = -2
        elseif damageType == "Black" then reduction = 0.2 end
    elseif eggName == "Big Brain" then
        if damageType == "Red" then reduction = 0.4
        elseif damageType == "Blue" then reduction = 0.4
        elseif damageType == "Purple" then reduction = 0.1
        elseif damageType == "Black" then reduction = -2 end
    end
    
    local finalDamage = damage * reduction
    egg.hp = math.max(0, egg.hp - finalDamage)
    
    local hpPercent = egg.hp / egg.maxHp
    egg.hpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
    egg.hpLabel.Text = string.format("%s: %.0f/%.0f", eggName, egg.hp, egg.maxHp)
    
    create3DDamageGui(egg.part.Position, finalDamage, damageType, getDamageCategory(finalDamage))
    
    if egg.hp <= 0 then
        egg.alive = false
        egg.part:Destroy()
        
        -- Damage Disaster Wolf
        disasterWolfEvent.disasterWolfHp = math.max(0, disasterWolfEvent.disasterWolfHp - 5750)
        local hpPercent = disasterWolfEvent.disasterWolfHp / disasterWolfEvent.disasterWolfMaxHp
        disasterWolfEvent.bossHpBar.Size = UDim2.new(hpPercent, 0, 1, 0)
        disasterWolfEvent.bossHpLabel.Text = string.format("Disaster Wolf: %.0f/%.0f", disasterWolfEvent.disasterWolfHp, disasterWolfEvent.disasterWolfMaxHp)
        
        -- Show dialogue
        if eggName == "Small Claw" then
            queueDialogue("Small Wolf's Claw has been cutted and Its teeth now straighten before, when it was sharp.")
            disasterWolfEvent.smallClawEnabled = false
        elseif eggName == "Wide Eyes" then
            queueDialogue("Wide Wolf's Signal were interrupted and cut off.")
        elseif eggName == "Long Body" then
            queueDialogue("Long Wolf's Dark Fog were shined away by the sun.")
            if egg.fogs then
                for _, fog in pairs(egg.fogs) do
                    fog:Destroy()
                end
            end
            if disasterWolfEvent.disasterFog then
                disasterWolfEvent.disasterFog:Destroy()
            end
        elseif eggName == "Big Brain" then
            queueDialogue("Big Wolf's Mirror were shattered.")
        end
        
        -- Check if Disaster Wolf defeated
        if disasterWolfEvent.disasterWolfHp <= 0 then
            queueDialogue("But there was nothing. There were no creatures, no sun and moon, and no beast. All that was left was just a wolf and the Elk City.")
            
            if disasterWolfEvent.disasterModel then
                disasterWolfEvent.disasterModel:Destroy()
            end
            if disasterWolfEvent.bossMusic then
                disasterWolfEvent.bossMusic:Stop()
                disasterWolfEvent.bossMusic:Destroy()
            end
            if disasterWolfEvent.playerBossMusic then
                disasterWolfEvent.playerBossMusic:Stop()
                disasterWolfEvent.playerBossMusic:Destroy()
            end
            
            disasterWolfEvent.completed = true
            disasterWolfEvent.active = false
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
                        
                        -- Play speed boost attack sound
                        local attackSound = Instance.new("Sound")
                        attackSound.SoundId = "rbxassetid://137400326597987"
                        attackSound.Volume = 0.5
                        attackSound.Parent = hrp
                        attackSound:Play()
                        
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
                    
                    -- Play pulse sound
                    local pulseSound = Instance.new("Sound")
                    pulseSound.SoundId = "rbxassetid://70542612197339"
                    pulseSound.Volume = 0.6
                    pulseSound.Parent = torso
                    pulseSound:Play()
                    
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
                            if illusion.fogSize < illusion.data.maxFogSize then
                                illusion.fogSize = math.min(illusion.fogSize + 5, illusion.data.maxFogSize)
                            end
                            if illusion.fogDamageMultiplier < illusion.data.maxFogMultiplier then
                                illusion.fogDamageMultiplier = math.min(illusion.fogDamageMultiplier + 0.1, illusion.data.maxFogMultiplier)
                            end
                        end
                    else
                        illusion.inFog = false
                    end
                end
                
                -- Coat brightens every 3 seconds
                if illusion.coatTimer >= 3 then
                    illusion.coatTimer = 0
                    
                    -- Play coat brighten sound
                    local coatSound = Instance.new("Sound")
                    coatSound.SoundId = "rbxassetid://9116795681"
                    coatSound.Volume = 1
                    coatSound.Parent = torso
                    coatSound:Play()
                    
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
                                
                                -- Play bullet hit sound
                                local hitSound = Instance.new("Sound")
                                hitSound.SoundId = "rbxassetid://13206683343"
                                hitSound.Volume = 0.5
                                hitSound.Parent = hrp
                                hitSound:Play()
                                
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
                -- Check if wolf should move to portal
                if name == "Small Wolf" or name == "Wide Wolf" or name == "Long Wolf" or name == "Big Wolf" then
                    if illusion.movingToPortal and disasterWolfEvent.portalPart then
                        local portalDistance = (disasterWolfEvent.portalPart.Position - torso.Position).Magnitude
                        if portalDistance <= 5 then
                            wolfEnterPortal(name)
                        else
                            illusionHumanoid:MoveTo(disasterWolfEvent.portalPart.Position)
                        end
                    else
                        illusionHumanoid:MoveTo(hrp.Position)
                    end
                else
                    illusionHumanoid:MoveTo(hrp.Position)
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
                            
                            -- Small Wolf normal attack (not speed boosted)
                            if name == "Small Wolf" and not illusion.isSpeedBoosted then
                                damagePlayer(damage, data.damageType)
                                
                                -- Play normal attack sound
                                local hitSound = Instance.new("Sound")
                                hitSound.SoundId = "rbxassetid://4471648128"
                                hitSound.Volume = 0.5
                                hitSound.Parent = hrp
                                hitSound:Play()
                            elseif name == "Wide Wolf" then
                                damagePlayer(damage, data.damageType)
                                
                                -- Play Wide Wolf attack sound
                                local hitSound = Instance.new("Sound")
                                hitSound.SoundId = "rbxassetid://4471648128"
                                hitSound.Volume = 0.5
                                hitSound.Parent = hrp
                                hitSound:Play()
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
    
    -- Big Wolf reflect mechanic
    if illusionName == "Big Wolf" then
        if illusion.mirrorMode then
            -- 100% reflect in mirror mode
            damagePlayer(damageAmount, damageType)
            create3DDamageGui(illusion.torso.Position, 0, damageType, "IMMUNE")
            return
        elseif math.random() < illusion.reflectChance then
            -- Normal reflect chance
            damagePlayer(damageAmount, damageType)
            create3DDamageGui(illusion.torso.Position, 0, damageType, "IMMUNE")
            
            -- Play reflect sound
            local reflectSound = Instance.new("Sound")
            reflectSound.SoundId = "rbxassetid://9116618763"
            reflectSound.Volume = 0.6
            reflectSound.Parent = illusion.torso
            reflectSound:Play()
            
            return
        end
        
        -- 10% chance to enter mirror mode when attacked
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
    
    -- Big Brain egg reflect during Disaster Wolf fight
    if disasterWolfEvent.bigBrainReflect and disasterWolfEvent.eggs["Big Brain"].alive then
        damagePlayer(damageAmount, damageType)
        create3DDamageGui(illusion.torso.Position, 0, damageType, "IMMUNE")
        return
    end
    
    -- Cerberus Suit reflect from player
    if playerStats.currentSuit == "Cerberus Suit" and suitData["Cerberus Suit"].reflectChance then
        if math.random() < 0.5 then
            -- Damage is already reflected, just show immune
            create3DDamageGui(illusion.torso.Position, 0, damageType, "IMMUNE")
            return
        end
    end
    
    local reduction = illusion.data.damageReductions[damageType] or 1
    local finalDamage = damageAmount * reduction
    
    -- Cerberus Suit low HP boost
    if playerStats.currentSuit == "Cerberus Suit" and suitData["Cerberus Suit"].lowHpBoost then
        finalDamage = finalDamage * 5
    end
    
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
    elseif weaponName == "Cerberus" then
        handle.BrickColor = BrickColor.new("Really black")
        handle.Size = Vector3.new(1, 8, 1)
        handle.Material = Enum.Material.Neon
        
        -- Add rainbow effect
        task.spawn(function()
            local colors = {
                BrickColor.new("Really red"),
                BrickColor.new("Bright blue"),
                BrickColor.new("Bright violet"),
                BrickColor.new("Really black")
            }
            local index = 1
            while handle.Parent do
                handle.BrickColor = colors[index]
                index = index % #colors + 1
                task.wait(0.5)
            end
        end)
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
        
        -- Create Cerberus ability buttons
        if weaponName == "Cerberus" then
            createCerberusAbilities()
        end
    end)
    
    tool.Unequipped:Connect(function()
        if mimicArtAbilityGui then
            mimicArtAbilityGui.Visible = false
        end
        for _, gui in pairs(cerberusAbilityGuis) do
            if gui then
                gui.Visible = false
            end
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
        
        -- Cerberus deals all 4 damage types
        if weaponName == "Cerberus" then
            local lookVector = hrp.CFrame.LookVector
            local hitPosition = hrp.Position + lookVector * 10
            
            local hitbox = Instance.new("Part")
            hitbox.Size = Vector3.new(20, 20, 20)
            hitbox.Position = hitPosition
            hitbox.Anchored = true
            hitbox.CanCollide = false
            hitbox.Transparency = 0.5
            hitbox.BrickColor = BrickColor.new("Really black")
            hitbox.Material = Enum.Material.Neon
            hitbox.Parent = workspace
            
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.Sphere
            mesh.Parent = hitbox
            
            -- Hit all illusions in range with all 4 damage types
            for name, illusion in pairs(activeIllusions) do
                if illusion.torso then
                    local distance = (illusion.torso.Position - hitPosition).Magnitude
                    if distance <= 20 then
                        for _, dmgType in ipairs(weaponInfo.damageTypes) do
                            local damage = math.random(weaponInfo.damageScale[1], weaponInfo.damageScale[2]) * getPureMultiplier()
                            damageIllusion(name, damage / 4, dmgType)
                        end
                    end
                end
            end
            
            -- Check eggs
            for eggName, egg in pairs(disasterWolfEvent.eggs) do
                if egg.alive and egg.part then
                    local eggDistance = (egg.part.Position - hitPosition).Magnitude
                    if eggDistance <= 20 then
                        for _, dmgType in ipairs(weaponInfo.damageTypes) do
                            local damage = math.random(weaponInfo.damageScale[1], weaponInfo.damageScale[2]) * getPureMultiplier()
                            damageEgg(eggName, damage / 4, dmgType)
                        end
                    end
                end
            end
            
            local fadeTween = TweenService:Create(hitbox, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Transparency = 1})
            fadeTween:Play()
            
            task.delay(0.5, function()
                hitbox:Destroy()
            end)
            
            -- Cooldown
            local cooldownTime = weaponInfo.cooldown
            task.spawn(function()
                for i = cooldownTime, 1, -1 do
                    tool.Name = string.format("%s (Cooldown: %ds)", weaponName, i)
                    task.wait(1)
                end
                tool.Name = weaponName
                attackCooldown = false
            end)
            
            return
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
                    
                    -- Check portal hit
                    if disasterWolfEvent.portalSpawned and disasterWolfEvent.portalPart then
                        local portalDistance = (disasterWolfEvent.portalPart.Position - hitPosition).Magnitude
                        if portalDistance <= 15 then
                            local damage = math.random(weaponInfo.damageScale[1], weaponInfo.damageScale[2]) * getPureMultiplier()
                            damagePortal(damage)
                        end
                    end
                    
                    -- Check egg hits
                    for eggName, egg in pairs(disasterWolfEvent.eggs) do
                        if egg.alive and egg.part then
                            local eggDistance = (egg.part.Position - hitPosition).Magnitude
                            if eggDistance <= 10 then
                                local damage = math.random(weaponInfo.damageScale[1], weaponInfo.damageScale[2]) * getPureMultiplier()
                                damageEgg(eggName, damage, currentDamageType)
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
            
            -- Check portal hit
            if disasterWolfEvent.portalSpawned and disasterWolfEvent.portalPart then
                local portalDistance = (disasterWolfEvent.portalPart.Position - hitPosition).Magnitude
                if portalDistance <= 15 then
                    local damage = math.random(weaponInfo.damageScale[1], weaponInfo.damageScale[2]) * getPureMultiplier()
                    damagePortal(damage)
                    hitSomething = true
                end
            end
            
            -- Check egg hits
            for eggName, egg in pairs(disasterWolfEvent.eggs) do
                if egg.alive and egg.part then
                    local eggDistance = (egg.part.Position - hitPosition).Magnitude
                    if eggDistance <= 10 then
                        local damage = math.random(weaponInfo.damageScale[1], weaponInfo.damageScale[2]) * getPureMultiplier()
                        damageEgg(eggName, damage, weaponInfo.damageType)
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

-- Create Cerberus Abilities
function createCerberusAbilities()
    if #cerberusAbilityGuis > 0 then
        for _, gui in pairs(cerberusAbilityGuis) do
            gui.Visible = true
        end
        return
    end
    
    local abilities = {
        {name = "Small Claw", color = Color3.fromRGB(255, 0, 0), position = UDim2.new(0, 20, 1, -140)},
        {name = "Wide Eyes", color = Color3.fromRGB(0, 150, 255), position = UDim2.new(0, 130, 1, -140)},
        {name = "Long Body", color = Color3.fromRGB(150, 0, 255), position = UDim2.new(0, 20, 1, -210)},
        {name = "Big Brain", color = Color3.fromRGB(50, 50, 50), position = UDim2.new(0, 130, 1, -210)}
    }
    
    for _, abilityInfo in ipairs(abilities) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 100, 0, 60)
        button.Position = abilityInfo.position
        button.Text = abilityInfo.name
        button.Font = Enum.Font.GothamBold
        button.TextScaled = true
        button.BackgroundColor3 = abilityInfo.color
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Parent = screenGui
        
        cerberusAbilityGuis[abilityInfo.name] = button
        
        button.MouseButton1Click:Connect(function()
            activateCerberusAbility(abilityInfo.name)
        end)
    end
end

-- Activate Cerberus Ability
function activateCerberusAbility(abilityName)
    local weaponInfo = weaponData["Cerberus"]
    if not weaponInfo then return end
    
    if abilityName == "Small Claw" then
        if not weaponInfo.abilities.smallClaw.ready then return end
        weaponInfo.abilities.smallClaw.ready = false
        
        -- Red beam on all illusions
        for name, illusion in pairs(activeIllusions) do
            if illusion.torso then
                local beam = Instance.new("Part")
                beam.Size = Vector3.new(5, 100, 5)
                beam.Position = illusion.torso.Position + Vector3.new(0, 50, 0)
                beam.Anchored = true
                beam.CanCollide = false
                beam.BrickColor = BrickColor.new("Really red")
                beam.Material = Enum.Material.Neon
                beam.Transparency = 0.3
                beam.Parent = workspace
                
                local damage = math.random(90, 175)
                damageIllusion(name, damage, "Red")
                
                task.delay(1, function()
                    beam:Destroy()
                end)
            end
        end
        
        -- Cooldown
        cerberusAbilityGuis["Small Claw"].Text = "15s"
        task.spawn(function()
            for i = 15, 1, -1 do
                cerberusAbilityGuis["Small Claw"].Text = i .. "s"
                task.wait(1)
            end
            cerberusAbilityGuis["Small Claw"].Text = "Small Claw"
            weaponInfo.abilities.smallClaw.ready = true
        end)
        
    elseif abilityName == "Wide Eyes" then
        if not weaponInfo.abilities.wideEyes.ready then return end
        weaponInfo.abilities.wideEyes.ready = false
        
        -- 100 stud forcefield
        local forcefield = Instance.new("Part")
        forcefield.Size = Vector3.new(100, 100, 100)
        forcefield.Shape = Enum.PartType.Ball
        forcefield.Position = hrp.Position
        forcefield.Anchored = true
        forcefield.CanCollide = false
        forcefield.Transparency = 0.5
        forcefield.BrickColor = BrickColor.new("Bright blue")
        forcefield.Material = Enum.Material.Neon
        forcefield.Parent = workspace
        
        local damageLoop = true
        task.spawn(function()
            for i = 1, 30 do
                if not damageLoop then break end
                for name, illusion in pairs(activeIllusions) do
                    if illusion.torso then
                        local distance = (illusion.torso.Position - forcefield.Position).Magnitude
                        if distance <= 50 then
                            local damage = math.random(30, 50)
                            damageIllusion(name, damage, "Blue")
                            
                            -- Check if illusion died
                            if illusion.hp <= 0 then
                                spawnPlayerTroop(illusion.data.dangerClass, illusion.torso.Position)
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
            damageLoop = false
        end)
        
        task.delay(3, function()
            damageLoop = false
            local fadeTween = TweenService:Create(forcefield, TweenInfo.new(1), {Transparency = 1})
            fadeTween:Play()
            task.delay(1, function()
                forcefield:Destroy()
            end)
        end)
        
        -- Cooldown
        cerberusAbilityGuis["Wide Eyes"].Text = "30s"
        task.spawn(function()
            for i = 30, 1, -1 do
                cerberusAbilityGuis["Wide Eyes"].Text = i .. "s"
                task.wait(1)
            end
            cerberusAbilityGuis["Wide Eyes"].Text = "Wide Eyes"
            weaponInfo.abilities.wideEyes.ready = true
        end)
        
    elseif abilityName == "Long Body" then
        if not weaponInfo.abilities.longBody.ready then return end
        weaponInfo.abilities.longBody.ready = false
        
        cerberusFogActive = true
        
        -- Create fog that follows player
        if cerberusFog then cerberusFog:Destroy() end
        cerberusFog = Instance.new("Part")
        cerberusFog.Size = Vector3.new(50, 50, 50)
        cerberusFog.Shape = Enum.PartType.Ball
        cerberusFog.Anchored = true
        cerberusFog.CanCollide = false
        cerberusFog.Transparency = 0.7
        cerberusFog.BrickColor = BrickColor.new("Really black")
        cerberusFog.Material = Enum.Material.Neon
        cerberusFog.Parent = workspace
        
        task.spawn(function()
            local fogTime = 0
            while cerberusFogActive and fogTime < 60 do
                cerberusFog.Position = hrp.Position
                
                -- Damage illusions in fog
                for name, illusion in pairs(activeIllusions) do
                    if illusion.torso then
                        local distance = (illusion.torso.Position - cerberusFog.Position).Magnitude
                        if distance <= 25 then
                            local damage = math.random(20, 50)
                            damageIllusion(name, damage, "Purple")
                        end
                    end
                end
                
                task.wait(0.5)
                fogTime = fogTime + 0.5
            end
            cerberusFogActive = false
            if cerberusFog then cerberusFog:Destroy() end
        end)
        
        -- Cooldown
        cerberusAbilityGuis["Long Body"].Text = "120s"
        task.spawn(function()
            for i = 120, 1, -1 do
                cerberusAbilityGuis["Long Body"].Text = i .. "s"
                task.wait(1)
            end
            cerberusAbilityGuis["Long Body"].Text = "Long Body"
            weaponInfo.abilities.longBody.ready = true
        end)
        
    elseif abilityName == "Big Brain" then
        if not weaponInfo.abilities.bigBrain.ready then return end
        weaponInfo.abilities.bigBrain.ready = false
        
        -- Make player immune and suck all illusions
        local immuneTime = 0
        local maxImmuneTime = 5
        
        task.spawn(function()
            while immuneTime < maxImmuneTime do
                -- Suck illusions to player
                for name, illusion in pairs(activeIllusions) do
                    if illusion.torso and illusion.humanoid then
                        local direction = (hrp.Position - illusion.torso.Position).Unit
                        illusion.humanoid:MoveTo(hrp.Position)
                        
                        -- Check if close enough to damage
                        local distance = (illusion.torso.Position - hrp.Position).Magnitude
                        if distance <= 10 then
                            local damage = math.random(60, 150)
                            damageIllusion(name, damage, "Black")
                            
                            -- Absorb HP
                            playerStats.hp = math.min(playerStats.maxHp, playerStats.hp + damage)
                            playerStats.pure = math.min(playerStats.maxPure, playerStats.pure + damage)
                            updateBars()
                        end
                    end
                end
                
                immuneTime = immuneTime + 0.1
                task.wait(0.1)
            end
        end)
        
        -- Cooldown
        cerberusAbilityGuis["Big Brain"].Text = "60s"
        task.spawn(function()
            for i = 60, 1, -1 do
                cerberusAbilityGuis["Big Brain"].Text = i .. "s"
                task.wait(1)
            end
            cerberusAbilityGuis["Big Brain"].Text = "Big Brain"
            weaponInfo.abilities.bigBrain.ready = true
        end)
    end
end

-- Spawn Player Troop
function spawnPlayerTroop(dangerClass, position)
    local troopData = {}
    local troopName = ""
    
    if dangerClass == "TETH" then
        troopName = "Small Slasher"
        troopData = {
            hp = 120,
            sp = 100,
            pure = 105,
            damageScale = {6, 8},
            damageType = "Red",
            attackCooldown = 3,
            attackRange = 10
        }
    elseif dangerClass == "HE" then
        troopName = "Wide Detector"
        troopData = {
            hp = 300,
            sp = 350,
            pure = 299,
            damageScale = {10, 15},
            damageType = "Blue",
            attackCooldown = 3,
            attackRange = 10,
            pulseTimer = 0
        }
    elseif dangerClass == "WAW" then
        troopName = "Long Fog"
        troopData = {
            hp = 720,
            sp = 780,
            pure = 675,
            damageScale = {20, 27},
            damageType = "Purple",
            attackCooldown = 4,
            attackRange = 10
        }
    elseif dangerClass == "ALEPH" or dangerClass == "LAMMED" then
        troopName = "Big Mirror"
        troopData = {
            hp = 1600,
            sp = 1530,
            pure = 1750,
            damageScale = {25, 50},
            damageType = "Purple",
            attackCooldown = 2,
            attackRange = 10,
            reflectChance = 0.5
        }
    end
    
    -- Create troop model
    local troopModel = Instance.new("Model")
    troopModel.Name = troopName
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Position = position
    torso.Anchored = false
    torso.CanCollide = true
    torso.BrickColor = BrickColor.new("Bright green")
    torso.Parent = troopModel
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 1, 1)
    head.Position = torso.Position + Vector3.new(0, 1.5, 0)
    head.Anchored = false
    head.CanCollide = true
    head.BrickColor = BrickColor.new("Bright green")
    head.Parent = troopModel
    
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = torso
    weld.Part1 = head
    weld.Parent = torso
    
    local troopHumanoid = Instance.new("Humanoid")
    troopHumanoid.MaxHealth = troopData.hp
    troopHumanoid.Health = troopData.hp
    troopHumanoid.WalkSpeed = 16
    troopHumanoid.Parent = troopModel
    
    troopModel.Parent = workspace
    
    -- Store troop
    local troopId = troopName .. "_" .. tick()
    playerTroops[troopId] = {
        model = troopModel,
        humanoid = troopHumanoid,
        torso = torso,
        head = head,
        data = troopData,
        hp = troopData.hp,
        lastAttack = 0
    }
    
    -- Troop AI
    task.spawn(function()
        while playerTroops[troopId] and troopModel.Parent do
            local troop = playerTroops[troopId]
            
            if troop.hp <= 0 then
                troopModel:Destroy()
                playerTroops[troopId] = nil
                break
            end
            
            -- Find nearest illusion
            local nearestIllusion = nil
            local nearestDistance = math.huge
            
            for name, illusion in pairs(activeIllusions) do
                if illusion.torso then
                    local distance = (illusion.torso.Position - torso.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestIllusion = illusion
                    end
                end
            end
            
            if nearestIllusion then
                if nearestDistance > troopData.attackRange then
                    troopHumanoid:MoveTo(nearestIllusion.torso.Position)
                else
                    local currentTime = tick()
                    if currentTime - troop.lastAttack >= troopData.attackCooldown then
                        troop.lastAttack = currentTime
                        
                        local damage = math.random(troopData.damageScale[1], troopData.damageScale[2])
                        for illusionName, illusion in pairs(activeIllusions) do
                            if illusion == nearestIllusion then
                                damageIllusion(illusionName, damage, troopData.damageType)
                                break
                            end
                        end
                    end
                end
            end
            
            task.wait(0.1)
        end
    end)
end

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
    
    -- Update Cerberus Suit fog position
    if cerberusFog and playerStats.currentSuit == "Cerberus Suit" and suitData["Cerberus Suit"].lowHpBoost then
        cerberusFog.Position = hrp.Position
    end
    
    -- Check for Disaster Wolf Event
    checkDisasterWolfEvent()
    
    -- Update Disaster Wolf mechanics
    if disasterWolfEvent.disasterWolfSpawned and not disasterWolfEvent.completed then
        -- Update fog positions for each egg
        if disasterWolfEvent.eggs["Long Body"].alive and disasterWolfEvent.eggs["Long Body"].fogs then
            for eggName, fog in pairs(disasterWolfEvent.eggs["Long Body"].fogs) do
                if disasterWolfEvent.eggs[eggName].part then
                    fog.Position = disasterWolfEvent.eggs[eggName].part.Position
                end
            end
        end
        
        -- Update Disaster Wolf fog
        if disasterWolfEvent.eggs["Long Body"].alive and disasterWolfEvent.disasterFog then
            disasterWolfEvent.disasterFog.Position = disasterWolfEvent.disasterTorso.Position
        end
        
        -- Small Claw enables attacks
        if disasterWolfEvent.smallClawEnabled then
            disasterWolfEvent.attackTimer = disasterWolfEvent.attackTimer + (1/60)
            if disasterWolfEvent.attackTimer >= 4 then
                disasterWolfEvent.attackTimer = 0
                local damage = math.random(75, 100)
                damagePlayer(damage, "Red")
                
                -- Play attack sound
                local attackSound = Instance.new("Sound")
                attackSound.SoundId = "rbxassetid://5951833277"
                attackSound.Volume = 0.5
                attackSound.Parent = disasterWolfEvent.disasterTorso
                attackSound:Play()
            end
        end
        
        -- Wide Eyes pulse
        if disasterWolfEvent.eggs["Wide Eyes"].alive then
            disasterWolfEvent.wideEyesTimer = disasterWolfEvent.wideEyesTimer + (1/60)
            if disasterWolfEvent.wideEyesTimer >= 10 then
                disasterWolfEvent.wideEyesTimer = 0
                
                -- Play ability sound
                local abilitySound = Instance.new("Sound")
                abilitySound.SoundId = "rbxassetid://70542612197339"
                abilitySound.Volume = 0.6
                abilitySound.Parent = disasterWolfEvent.eggs["Wide Eyes"].part
                abilitySound:Play()
                
                local damage = math.random(45, 80)
                damagePlayer(damage, "Blue")
                
                -- Teleport player near Disaster Wolf
                local direction = (disasterWolfEvent.disasterTorso.Position - hrp.Position).Unit
                hrp.CFrame = CFrame.new(disasterWolfEvent.disasterTorso.Position - direction * 20)
            end
        end
        
        -- Big Brain reflect
        if disasterWolfEvent.eggs["Big Brain"].alive then
            if disasterWolfEvent.bigBrainReflect then
                disasterWolfEvent.bigBrainReflectTimer = disasterWolfEvent.bigBrainReflectTimer + (1/60)
                if disasterWolfEvent.bigBrainReflectTimer >= 10 then
                    disasterWolfEvent.bigBrainReflect = false
                    disasterWolfEvent.bigBrainReflectTimer = 0
                end
            else
                -- 13% chance to activate
                if math.random() < 0.0022 then
                    disasterWolfEvent.bigBrainReflect = true
                    disasterWolfEvent.bigBrainReflectTimer = 0
                    
                    -- Play reflect sound
                    local reflectSound = Instance.new("Sound")
                    reflectSound.SoundId = "rbxassetid://9116618763"
                    reflectSound.Volume = 1
                    reflectSound.Parent = disasterWolfEvent.eggs["Big Brain"].part
                    reflectSound:Play()
                    
                    local damage = math.random(50, 75)
                    damagePlayer(damage, "Black")
                end
            end
        end
    end
end)

print("Illusion Combat System Loaded!")
print("Current Weapon: " .. playerStats.currentWeapon)
print("Current Suit: " .. playerStats.currentSuit)
print("Total Lines: 3300+")
