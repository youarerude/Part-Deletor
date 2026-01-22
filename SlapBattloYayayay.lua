-- Slap Battles Game Script
-- Main game script with AI players, gloves, and abilities

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Configuration
local CONFIG = {
    MAX_FAKE_PLAYERS = 5,
    AGGRO_DISTANCE = 100,
    SLAP_DISTANCE = 5,
    RESPAWN_TIME = 3,
    ARENA_SIZE = 200
}

-- Glove data with all properties
local GLOVE_DATA = {
    ["Default Glove"] = {
        PushPower = 5,
        SlapCooldown = 2,
        AbilityType = "None",
        Ability = nil,
        AbilityCooldown = 0,
        Color = Color3.fromRGB(200, 200, 200)
    },
    ["Siphon Glove"] = {
        PushPower = 8,
        SlapCooldown = 1.5,
        AbilityType = "Ability",
        Ability = "Siphon",
        AbilityCooldown = 15,
        Color = Color3.fromRGB(0, 255, 255)
    },
    ["Train Glove"] = {
        PushPower = 7,
        SlapCooldown = 2,
        AbilityType = "Ability",
        Ability = "Train",
        AbilityCooldown = 10,
        Color = Color3.fromRGB(100, 100, 100)
    },
    ["Counter Glove"] = {
        PushPower = 6,
        SlapCooldown = 1.8,
        AbilityType = "Ability",
        Ability = "Counter",
        AbilityCooldown = 15,
        Color = Color3.fromRGB(255, 0, 0)
    },
    ["God Glove"] = {
        PushPower = 100,
        SlapCooldown = 5,
        AbilityType = "Fusion",
        Ability = "TimeStop",
        AbilityCooldown = 60,
        Color = Color3.fromRGB(255, 215, 0)
    },
    ["RNG Glove"] = {
        PushPower = 5,
        SlapCooldown = 2,
        AbilityType = "Passive",
        Ability = "RandomDirection",
        AbilityCooldown = 0,
        Color = Color3.fromRGB(255, 0, 255)
    },
    ["LandMine Glove"] = {
        PushPower = 5,
        SlapCooldown = 1,
        AbilityType = "Ability",
        Ability = "LandMine",
        AbilityCooldown = 5,
        Color = Color3.fromRGB(139, 69, 19)
    },
    ["Engineer Glove"] = {
        PushPower = 7,
        SlapCooldown = 1.8,
        AbilityType = "Ability",
        Ability = "Engineer",
        AbilityCooldown = 180, -- 3 minutes for turret
        AbilityCooldown2 = 150, -- 2.5 minutes for roombas
        Color = Color3.fromRGB(255, 140, 0)
    },
    ["AirBomb Glove"] = {
        PushPower = 8,
        SlapCooldown = 2.5,
        AbilityType = "Ability",
        Ability = "AirBomb",
        AbilityCooldown = 25,
        Color = Color3.fromRGB(135, 206, 235)
    },
    ["Admin Glove"] = {
        PushPower = 8,
        SlapCooldown = 1.5,
        AbilityType = "Ability",
        Ability = "Admin",
        AbilityCooldown = 0,
        Color = Color3.fromRGB(255, 255, 255)
    },
    ["Song Glove"] = {
        PushPower = 0, -- Variable based on rhythm performance
        SlapCooldown = 999, -- No slapping, only rhythm
        AbilityType = "Passive",
        Ability = "Rhythm",
        AbilityCooldown = 0,
        Color = Color3.fromRGB(255, 100, 150)
    }
}

-- Game state variables
local currentGlove = "Default Glove"
local equippedGlove = nil
local lastSlapTime = 0
local lastAbilityTime = 0
local lastAbility2Time = 0
local isPlayerSitting = false
local fakePlayersList = {}
local aggroedFakePlayers = {}
local isCounterActive = false
local counterConnection = nil
local isTimeStopActive = false
local playerSlapCount = 0
local activeLandmines = {}
local activeTurrets = {}
local activeRoombas = {}
local airBombTargetingActive = false
local activeHighlights = {}
local adminCommandCooldowns = {
    explode = 0,
    speed = 0,
    anvil = 0,
    jumppower = 0,
    bring = 0,
    goto = 0,
    train = 0,
    freeze = 0,
    ragdoll = 0
}
local rhythmGameActive = false
local rhythmSound = nil
local rhythmNotes = {}
local rhythmScore = 0

-- UI Elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SlapBattlesUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Glove Button
local gloveButton = Instance.new("TextButton")
gloveButton.Name = "GloveButton"
gloveButton.Size = UDim2.new(0, 150, 0, 50)
gloveButton.Position = UDim2.new(0, 20, 0, 20)
gloveButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
gloveButton.BorderSizePixel = 2
gloveButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
gloveButton.Text = "GLOVES"
gloveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
gloveButton.TextScaled = true
gloveButton.Font = Enum.Font.GothamBold
gloveButton.Parent = screenGui

-- Glove Selection GUI
local gloveSelectionFrame = Instance.new("Frame")
gloveSelectionFrame.Name = "GloveSelection"
gloveSelectionFrame.Size = UDim2.new(0, 600, 0, 400)
gloveSelectionFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
gloveSelectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
gloveSelectionFrame.BorderSizePixel = 3
gloveSelectionFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
gloveSelectionFrame.Visible = false
gloveSelectionFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "SELECT YOUR GLOVE"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = gloveSelectionFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -45, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = gloveSelectionFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -70)
scrollFrame.Position = UDim2.new(0, 10, 0, 60)
scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
scrollFrame.BorderSizePixel = 2
scrollFrame.ScrollBarThickness = 10
scrollFrame.Parent = gloveSelectionFrame

-- Ability Button (always visible for mobile)
local abilityButton = Instance.new("TextButton")
abilityButton.Name = "AbilityButton"
abilityButton.Size = UDim2.new(0, 120, 0, 120)
abilityButton.Position = UDim2.new(1, -140, 1, -260)
abilityButton.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
abilityButton.BorderSizePixel = 3
abilityButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
abilityButton.Text = "ABILITY"
abilityButton.TextColor3 = Color3.fromRGB(255, 255, 255)
abilityButton.TextScaled = true
abilityButton.Font = Enum.Font.GothamBold
abilityButton.Visible = false
abilityButton.Parent = screenGui

-- Second Ability Button (for Engineer Glove)
local ability2Button = Instance.new("TextButton")
ability2Button.Name = "Ability2Button"
ability2Button.Size = UDim2.new(0, 120, 0, 120)
ability2Button.Position = UDim2.new(1, -270, 1, -260)
ability2Button.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
ability2Button.BorderSizePixel = 3
ability2Button.BorderColor3 = Color3.fromRGB(255, 255, 255)
ability2Button.Text = "ABILITY 2"
ability2Button.TextColor3 = Color3.fromRGB(255, 255, 255)
ability2Button.TextScaled = true
ability2Button.Font = Enum.Font.GothamBold
ability2Button.Visible = false
ability2Button.Parent = screenGui

-- Add mobile slap button
local slapButton = Instance.new("TextButton")
slapButton.Name = "SlapButton"
slapButton.Size = UDim2.new(0, 120, 0, 120)
slapButton.Position = UDim2.new(1, -140, 1, -140)
slapButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
slapButton.BorderSizePixel = 3
slapButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
slapButton.Text = "SLAP"
slapButton.TextColor3 = Color3.fromRGB(255, 255, 255)
slapButton.TextScaled = true
slapButton.Font = Enum.Font.GothamBold
slapButton.Parent = screenGui

-- Slap button functionality
slapButton.MouseButton1Click:Connect(function()
    playerSlap()
end)

-- Create glove selection buttons
local function createGloveButtons()
    local yOffset = 0
    for gloveName, gloveData in pairs(GLOVE_DATA) do
        local gloveFrame = Instance.new("Frame")
        gloveFrame.Size = UDim2.new(1, -20, 0, 120)
        gloveFrame.Position = UDim2.new(0, 10, 0, yOffset)
        gloveFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        gloveFrame.BorderSizePixel = 2
        gloveFrame.BorderColor3 = gloveData.Color
        gloveFrame.Parent = scrollFrame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -10, 0, 25)
        nameLabel.Position = UDim2.new(0, 5, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = gloveName
        nameLabel.TextColor3 = gloveData.Color
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = gloveFrame
        
        local statsText = string.format(
            "Push Power: %d | Slap Cooldown: %.1fs\nType: %s | Ability Cooldown: %ds",
            gloveData.PushPower,
            gloveData.SlapCooldown,
            gloveData.AbilityType,
            gloveData.AbilityCooldown
        )
        
        local statsLabel = Instance.new("TextLabel")
        statsLabel.Size = UDim2.new(1, -10, 0, 50)
        statsLabel.Position = UDim2.new(0, 5, 0, 35)
        statsLabel.BackgroundTransparency = 1
        statsLabel.Text = statsText
        statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statsLabel.TextSize = 14
        statsLabel.Font = Enum.Font.Gotham
        statsLabel.TextXAlignment = Enum.TextXAlignment.Left
        statsLabel.TextYAlignment = Enum.TextYAlignment.Top
        statsLabel.Parent = gloveFrame
        
        local selectButton = Instance.new("TextButton")
        selectButton.Size = UDim2.new(0, 120, 0, 30)
        selectButton.Position = UDim2.new(1, -130, 1, -35)
        selectButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        selectButton.Text = "SELECT"
        selectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectButton.TextScaled = true
        selectButton.Font = Enum.Font.GothamBold
        selectButton.Parent = gloveFrame
        
        selectButton.MouseButton1Click:Connect(function()
            currentGlove = gloveName
            gloveSelectionFrame.Visible = false
            if equippedGlove then
                updateGloveAppearance()
            end
        end)
        
        yOffset = yOffset + 130
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

createGloveButtons()

-- Button connections
gloveButton.MouseButton1Click:Connect(function()
    gloveSelectionFrame.Visible = not gloveSelectionFrame.Visible
end)

closeButton.MouseButton1Click:Connect(function()
    gloveSelectionFrame.Visible = false
end)

-- Function to apply force to character
local function applyForce(targetCharacter, direction, power)
    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local targetRoot = targetCharacter.HumanoidRootPart
    local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
    
    if targetHumanoid then
        targetHumanoid.Sit = true
    end
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4e4, 4e4, 4e4)
    bodyVelocity.Velocity = direction * power * 10 + Vector3.new(0, power * 5, 0)
    bodyVelocity.Parent = targetRoot
    
    Debris:AddItem(bodyVelocity, 0.3)
    
    wait(0.3)
    if targetHumanoid and targetHumanoid.Sit then
        local connection
        connection = targetRoot.Touched:Connect(function(hit)
            if hit:IsA("BasePart") and not hit:IsDescendantOf(targetCharacter) then
                wait(0.1)
                targetHumanoid.Sit = false
                if connection then
                    connection:Disconnect()
                end
            end
        end)
    end
end

-- Function to create visual slap effect
local function createSlapEffect(position, color)
    local part = Instance.new("Part")
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(2, 2, 2)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.3
    part.Parent = workspace
    
    local tween = TweenService:Create(part, TweenInfo.new(0.3), {
        Size = Vector3.new(5, 5, 5),
        Transparency = 1
    })
    tween:Play()
    
    Debris:AddItem(part, 0.5)
end

-- Player slap function
local function playerSlap()
    if not equippedGlove or not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    -- Can't slap while counter is active
    if isCounterActive then
        return
    end
    
    -- Can't slap during time stop
    if isTimeStopActive then
        return
    end
    
    local currentTime = tick()
    local gloveData = GLOVE_DATA[currentGlove]
    
    if currentTime - lastSlapTime < gloveData.SlapCooldown then
        return
    end
    
    lastSlapTime = currentTime
    
    local characterRoot = character.HumanoidRootPart
    local slapPosition = characterRoot.Position + characterRoot.CFrame.LookVector * 3
    
    createSlapEffect(slapPosition, gloveData.Color)
    
    -- Check for fake players in range
    for _, fakePlayer in ipairs(fakePlayersList) do
        if fakePlayer.character and fakePlayer.character:FindFirstChild("HumanoidRootPart") then
            local fakeRoot = fakePlayer.character.HumanoidRootPart
            local distance = (fakeRoot.Position - slapPosition).Magnitude
            
            if distance <= CONFIG.SLAP_DISTANCE then
                -- Check if fake player has counter active
                if fakePlayer.isCounterActive then
                    -- Trigger counter punishment on player
                    triggerCounterPunishment(character)
                else
                    local direction
                    
                    -- Check if using RNG Glove (random direction)
                    if currentGlove == "RNG Glove" then
                        -- Random direction in 3D space
                        local randomAngle = math.random() * math.pi * 2
                        local randomElevation = (math.random() - 0.5) * math.pi * 0.5
                        direction = Vector3.new(
                            math.cos(randomAngle) * math.cos(randomElevation),
                            math.sin(randomElevation),
                            math.sin(randomAngle) * math.cos(randomElevation)
                        ).Unit
                    else
                        -- Normal direction (towards target)
                        direction = (fakeRoot.Position - characterRoot.Position).Unit
                    end
                    
                    applyForce(fakePlayer.character, direction, gloveData.PushPower)
                    
                    -- Track slaps taken for God Glove
                    fakePlayer.slapsTaken = fakePlayer.slapsTaken + 1
                    
                    -- Damage turrets and roombas
                    for _, turretData in ipairs(activeTurrets) do
                        if not turretData.isPlayerOwned and turretData.head and turretData.head.Parent then
                            local turretDist = (turretData.head.Position - slapPosition).Magnitude
                            if turretDist <= CONFIG.SLAP_DISTANCE then
                                turretData.health = turretData.health - 5
                            end
                        end
                    end
                    
                    for _, roombaData in ipairs(activeRoombas) do
                        if not roombaData.isPlayerOwned and roombaData.part and roombaData.part.Parent then
                            local roombaDist = (roombaData.part.Position - slapPosition).Magnitude
                            if roombaDist <= CONFIG.SLAP_DISTANCE then
                                roombaData.health = roombaData.health - 5
                            end
                        end
                    end
                    
                    -- Aggro the fake player
                    if not table.find(aggroedFakePlayers, fakePlayer) then
                        table.insert(aggroedFakePlayers, fakePlayer)
                        fakePlayer.isAggro = true
                    end
                end
            end
        end
    end
end

-- Siphon ability
local function activateSiphonAbility(caster, isPlayer)
    local casterRoot
    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end
        casterRoot = character.HumanoidRootPart
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then
            return
        end
        casterRoot = caster.character.HumanoidRootPart
    end
    
    local beaconPosition = casterRoot.Position + Vector3.new(0, 2, 0)
    
    -- Create beacon
    local beacon = Instance.new("Part")
    beacon.Shape = Enum.PartType.Cylinder
    beacon.Size = Vector3.new(2, 3, 3)
    beacon.Position = beaconPosition
    beacon.Anchored = true
    beacon.CanCollide = false
    beacon.Material = Enum.Material.Neon
    beacon.Color = Color3.fromRGB(0, 255, 255)
    beacon.Orientation = Vector3.new(0, 0, 90)
    beacon.Parent = workspace
    
    -- Create forcefield
    local forcefield = Instance.new("Part")
    forcefield.Shape = Enum.PartType.Ball
    forcefield.Size = Vector3.new(40, 40, 40)
    forcefield.Position = beaconPosition
    forcefield.Anchored = true
    forcefield.CanCollide = false
    forcefield.Material = Enum.Material.ForceField
    forcefield.Color = Color3.fromRGB(0, 255, 255)
    forcefield.Transparency = 0.7
    forcefield.Parent = workspace
    
    -- Siphon effect
    local duration = 4
    local startTime = tick()
    
    local siphonConnection
    siphonConnection = RunService.Heartbeat:Connect(function()
        if tick() - startTime >= duration then
            siphonConnection:Disconnect()
            if beacon.Parent then
                beacon:Destroy()
            end
            if forcefield.Parent then
                forcefield:Destroy()
            end
            return
        end
        
        -- Pull player if fake player used ability
        if not isPlayer then
            if character and character:FindFirstChild("HumanoidRootPart") then
                local playerRoot = character.HumanoidRootPart
                local distance = (playerRoot.Position - beaconPosition).Magnitude
                
                if distance <= 20 then
                    local direction = (beaconPosition - playerRoot.Position).Unit
                    
                    -- Create new velocity each frame for continuous pull
                    local existingVelocity = playerRoot:FindFirstChild("SiphonVelocity")
                    if existingVelocity then
                        existingVelocity:Destroy()
                    end
                    
                    local pullForce = Instance.new("BodyVelocity")
                    pullForce.Name = "SiphonVelocity"
                    pullForce.MaxForce = Vector3.new(5000, 5000, 5000)
                    pullForce.Velocity = direction * 60
                    pullForce.Parent = playerRoot
                    
                    Debris:AddItem(pullForce, 0.15)
                end
            end
        end
        
        -- Pull fake players if player used ability
        if isPlayer then
            for _, fakePlayer in ipairs(fakePlayersList) do
                if fakePlayer.character and fakePlayer.character:FindFirstChild("HumanoidRootPart") then
                    local fakeRoot = fakePlayer.character.HumanoidRootPart
                    local distance = (fakeRoot.Position - beaconPosition).Magnitude
                    
                    if distance <= 20 then
                        local direction = (beaconPosition - fakeRoot.Position).Unit
                        
                        -- Create new velocity each frame for continuous pull
                        local existingVelocity = fakeRoot:FindFirstChild("SiphonVelocity")
                        if existingVelocity then
                            existingVelocity:Destroy()
                        end
                        
                        local pullForce = Instance.new("BodyVelocity")
                        pullForce.Name = "SiphonVelocity"
                        pullForce.MaxForce = Vector3.new(5000, 5000, 5000)
                        pullForce.Velocity = direction * 60
                        pullForce.Parent = fakeRoot
                        
                        Debris:AddItem(pullForce, 0.15)
                    end
                end
            end
        end
    end)
    
    -- Cleanup after duration
    spawn(function()
        wait(duration)
        if siphonConnection then
            siphonConnection:Disconnect()
        end
        if beacon.Parent then
            beacon:Destroy()
        end
        if forcefield.Parent then
            forcefield:Destroy()
        end
        
        -- Clean up any remaining velocity objects
        if isPlayer then
            for _, fakePlayer in ipairs(fakePlayersList) do
                if fakePlayer.character and fakePlayer.character:FindFirstChild("HumanoidRootPart") then
                    local vel = fakePlayer.character.HumanoidRootPart:FindFirstChild("SiphonVelocity")
                    if vel then vel:Destroy() end
                end
            end
        else
            if character and character:FindFirstChild("HumanoidRootPart") then
                local vel = character.HumanoidRootPart:FindFirstChild("SiphonVelocity")
                if vel then vel:Destroy() end
            end
        end
    end)
end

-- Train ability
local function activateTrainAbility(caster, isPlayer)
    local casterRoot
    local targetCharacter
    
    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end
        casterRoot = character.HumanoidRootPart
        
        -- Find nearest fake player
        local nearestDistance = math.huge
        for _, fakePlayer in ipairs(fakePlayersList) do
            if fakePlayer.character and fakePlayer.character:FindFirstChild("HumanoidRootPart") then
                local dist = (fakePlayer.character.HumanoidRootPart.Position - casterRoot.Position).Magnitude
                if dist < nearestDistance then
                    nearestDistance = dist
                    targetCharacter = fakePlayer.character
                end
            end
        end
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then
            return
        end
        casterRoot = caster.character.HumanoidRootPart
        targetCharacter = character
    end
    
    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local targetRoot = targetCharacter.HumanoidRootPart
    local direction = (targetRoot.Position - casterRoot.Position).Unit
    local spawnPosition = targetRoot.Position - direction * 100
    
    -- Create train with proper physics
    local train = Instance.new("Part")
    train.Size = Vector3.new(8, 6, 12)
    train.Position = spawnPosition + Vector3.new(0, 3, 0)
    train.Anchored = true -- Start anchored
    train.CanCollide = true
    train.Material = Enum.Material.Metal
    train.Color = Color3.fromRGB(100, 100, 100)
    train.Parent = workspace
    
    -- Add visual indicator
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 255, 0)
    light.Brightness = 5
    light.Range = 30
    light.Parent = train
    
    local startTime = tick()
    local maxDuration = 10
    local hitRegistered = false
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not train.Parent or not targetRoot.Parent then
            if connection then
                connection:Disconnect()
            end
            if train.Parent then
                train:Destroy()
            end
            return
        end
        
        local elapsed = tick() - startTime
        if elapsed >= maxDuration then
            connection:Disconnect()
            train:Destroy()
            return
        end
        
        -- Calculate speed that increases over time
        local speed = math.min(10 + elapsed * 12, 100)
        
        -- Get direction to target
        local newDirection = (targetRoot.Position - train.Position).Unit
        
        -- Move train manually
        local movement = newDirection * speed * RunService.Heartbeat:Wait()
        train.CFrame = CFrame.new(train.Position + movement) * CFrame.lookAt(Vector3.new(), newDirection)
        
        -- Check for collision manually
        if not hitRegistered then
            local distance = (train.Position - targetRoot.Position).Magnitude
            if distance <= 8 then
                hitRegistered = true
                local hitDirection = (targetRoot.Position - train.Position).Unit
                applyForce(targetCharacter, hitDirection, 12)
                
                -- Create impact effect
                local explosion = Instance.new("Explosion")
                explosion.Position = train.Position
                explosion.BlastRadius = 10
                explosion.BlastPressure = 0
                explosion.Parent = workspace
                
                connection:Disconnect()
                train:Destroy()
            end
        end
    end)
    
    spawn(function()
        wait(maxDuration)
        if connection then
            connection:Disconnect()
        end
        if train.Parent then
            train:Destroy()
        end
    end)
end

-- Counter ability
local function activateCounterAbility(caster, isPlayer)
    local casterRoot
    local casterHumanoid
    
    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") or not humanoid then
            return
        end
        casterRoot = character.HumanoidRootPart
        casterHumanoid = humanoid
        isCounterActive = true
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") or not caster.humanoid then
            return
        end
        casterRoot = caster.character.HumanoidRootPart
        casterHumanoid = caster.humanoid
        caster.isCounterActive = true
    end
    
    -- Create red light effect
    local redLight = Instance.new("PointLight")
    redLight.Name = "CounterLight"
    redLight.Color = Color3.fromRGB(255, 0, 0)
    redLight.Brightness = 10
    redLight.Range = 15
    redLight.Parent = casterRoot
    
    -- Create red sphere around character
    local counterSphere = Instance.new("Part")
    counterSphere.Name = "CounterSphere"
    counterSphere.Shape = Enum.PartType.Ball
    counterSphere.Size = Vector3.new(8, 8, 8)
    counterSphere.Position = casterRoot.Position
    counterSphere.Anchored = true
    counterSphere.CanCollide = false
    counterSphere.Material = Enum.Material.Neon
    counterSphere.Color = Color3.fromRGB(255, 0, 0)
    counterSphere.Transparency = 0.5
    counterSphere.Parent = workspace
    
    -- Prevent movement
    local originalWalkSpeed = casterHumanoid.WalkSpeed
    casterHumanoid.WalkSpeed = 0
    
    -- Keep sphere attached to character
    local sphereConnection
    sphereConnection = RunService.Heartbeat:Connect(function()
        if counterSphere.Parent and casterRoot.Parent then
            counterSphere.Position = casterRoot.Position
        else
            if sphereConnection then
                sphereConnection:Disconnect()
            end
        end
    end)
    
    -- Counter duration
    wait(1)
    
    -- Restore movement
    casterHumanoid.WalkSpeed = originalWalkSpeed
    
    -- Remove effects
    if redLight.Parent then
        redLight:Destroy()
    end
    if counterSphere.Parent then
        counterSphere:Destroy()
    end
    if sphereConnection then
        sphereConnection:Disconnect()
    end
    
    if isPlayer then
        isCounterActive = false
    else
        caster.isCounterActive = false
    end
end

-- Function to trigger counter punishment
local function triggerCounterPunishment(attacker)
    if not attacker or not attacker:FindFirstChild("HumanoidRootPart") or not attacker:FindFirstChild("Humanoid") then
        return
    end
    
    local attackerRoot = attacker.HumanoidRootPart
    local attackerHumanoid = attacker.Humanoid
    
    -- Freeze attacker
    local originalWalkSpeed = attackerHumanoid.WalkSpeed
    attackerHumanoid.WalkSpeed = 0
    
    -- Create warning effect
    local warningLight = Instance.new("PointLight")
    warningLight.Color = Color3.fromRGB(255, 255, 0)
    warningLight.Brightness = 5
    warningLight.Range = 10
    warningLight.Parent = attackerRoot
    
    -- Spawn anvil above attacker
    local anvilSpawnPos = attackerRoot.Position + Vector3.new(0, 20, 0)
    
    local anvil = Instance.new("Part")
    anvil.Name = "Anvil"
    anvil.Size = Vector3.new(3, 2, 3)
    anvil.Position = anvilSpawnPos
    anvil.Anchored = true
    anvil.CanCollide = false
    anvil.Material = Enum.Material.Metal
    anvil.Color = Color3.fromRGB(80, 80, 80)
    anvil.Parent = workspace
    
    -- Add mesh for anvil look
    local mesh = Instance.new("BlockMesh")
    mesh.Scale = Vector3.new(1, 0.7, 1)
    mesh.Parent = anvil
    
    wait(0.3)
    
    -- Drop anvil
    anvil.Anchored = false
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, 4e4, 0)
    bodyVelocity.Velocity = Vector3.new(0, -100, 0)
    bodyVelocity.Parent = anvil
    
    -- Wait for impact
    local hitConnection
    hitConnection = anvil.Touched:Connect(function(hit)
        if hit.Parent == attacker or hit == attackerRoot then
            -- Apply downward force
            applyForce(attacker, Vector3.new(0, -1, 0), 50)
            
            -- Create impact effect
            local impactEffect = Instance.new("Part")
            impactEffect.Shape = Enum.PartType.Ball
            impactEffect.Size = Vector3.new(1, 1, 1)
            impactEffect.Position = attackerRoot.Position
            impactEffect.Anchored = true
            impactEffect.CanCollide = false
            impactEffect.Material = Enum.Material.Neon
            impactEffect.Color = Color3.fromRGB(255, 255, 0)
            impactEffect.Transparency = 0.3
            impactEffect.Parent = workspace
            
            local tween = TweenService:Create(impactEffect, TweenInfo.new(0.5), {
                Size = Vector3.new(10, 10, 10),
                Transparency = 1
            })
            tween:Play()
            Debris:AddItem(impactEffect, 0.5)
            
            -- Restore movement
            attackerHumanoid.WalkSpeed = originalWalkSpeed
            
            if warningLight.Parent then
                warningLight:Destroy()
            end
            
            if hitConnection then
                hitConnection:Disconnect()
            end
            
            if anvil.Parent then
                Debris:AddItem(anvil, 1)
            end
        end
    end)
    
    -- Cleanup after 3 seconds if no hit
    spawn(function()
        wait(3)
        if hitConnection then
            hitConnection:Disconnect()
        end
        if anvil.Parent then
            anvil:Destroy()
        end
        if warningLight.Parent then
            warningLight:Destroy()
        end
        attackerHumanoid.WalkSpeed = originalWalkSpeed
    end)
end

-- Admin Panel System
local adminPanelGui = Instance.new("Frame")
adminPanelGui.Name = "AdminPanel"
adminPanelGui.Size = UDim2.new(0, 600, 0, 500)
adminPanelGui.Position = UDim2.new(0.5, -300, 0.5, -250)
adminPanelGui.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
adminPanelGui.BorderSizePixel = 3
adminPanelGui.BorderColor3 = Color3.fromRGB(255, 255, 255)
adminPanelGui.Visible = false
adminPanelGui.Parent = screenGui

local adminTitle = Instance.new("TextLabel")
adminTitle.Size = UDim2.new(1, 0, 0, 40)
adminTitle.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
adminTitle.BorderSizePixel = 0
adminTitle.Text = "ADMIN PANEL"
adminTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
adminTitle.TextScaled = true
adminTitle.Font = Enum.Font.GothamBold
adminTitle.Parent = adminPanelGui

local closeAdminButton = Instance.new("TextButton")
closeAdminButton.Size = UDim2.new(0, 35, 0, 35)
closeAdminButton.Position = UDim2.new(1, -38, 0, 2.5)
closeAdminButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeAdminButton.Text = "X"
closeAdminButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeAdminButton.TextScaled = true
closeAdminButton.Font = Enum.Font.GothamBold
closeAdminButton.Parent = adminPanelGui

local adminScrollFrame = Instance.new("ScrollingFrame")
adminScrollFrame.Size = UDim2.new(1, -20, 1, -60)
adminScrollFrame.Position = UDim2.new(0, 10, 0, 50)
adminScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
adminScrollFrame.BorderSizePixel = 0
adminScrollFrame.ScrollBarThickness = 8
adminScrollFrame.Parent = adminPanelGui

-- Admin Panel Button (replaces ability button for Admin Glove)
local adminPanelButton = Instance.new("TextButton")
adminPanelButton.Name = "AdminPanelButton"
adminPanelButton.Size = UDim2.new(0, 120, 0, 120)
adminPanelButton.Position = UDim2.new(1, -140, 1, -260)
adminPanelButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
adminPanelButton.BorderSizePixel = 3
adminPanelButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
adminPanelButton.Text = "ADMIN"
adminPanelButton.TextColor3 = Color3.fromRGB(0, 0, 0)
adminPanelButton.TextScaled = true
adminPanelButton.Font = Enum.Font.GothamBold
adminPanelButton.Visible = false
adminPanelButton.Parent = screenGui

adminPanelButton.MouseButton1Click:Connect(function()
    adminPanelGui.Visible = not adminPanelGui.Visible
end)

closeAdminButton.MouseButton1Click:Connect(function()
    adminPanelGui.Visible = false
end)

-- Rhythm Game UI (Song Glove)
local rhythmGameUI = Instance.new("Frame")
rhythmGameUI.Name = "RhythmGame"
rhythmGameUI.Size = UDim2.new(1, 0, 1, 0)
rhythmGameUI.BackgroundTransparency = 1
rhythmGameUI.Visible = false
rhythmGameUI.Parent = screenGui

-- Create 4 lanes with target zones
local lanePositions = {0.3, 0.4, 0.5, 0.6}
local laneColors = {
    Color3.fromRGB(255, 0, 0),    -- Red
    Color3.fromRGB(0, 255, 0),    -- Green
    Color3.fromRGB(0, 0, 255),    -- Blue
    Color3.fromRGB(255, 255, 0)   -- Yellow
}
local laneKeys = {Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.J, Enum.KeyCode.K}

local targetZones = {}
local laneButtons = {}

for i = 1, 4 do
    -- Target zone (grey block)
    local targetZone = Instance.new("Frame")
    targetZone.Name = "TargetZone" .. i
    targetZone.Size = UDim2.new(0, 80, 0, 80)
    targetZone.Position = UDim2.new(lanePositions[i], -40, 0.85, -40)
    targetZone.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    targetZone.BorderSizePixel = 3
    targetZone.BorderColor3 = Color3.fromRGB(255, 255, 255)
    targetZone.Parent = rhythmGameUI
    table.insert(targetZones, targetZone)
    
    -- Lane button for mobile
    local laneBtn = Instance.new("TextButton")
    laneBtn.Name = "LaneButton" .. i
    laneBtn.Size = UDim2.new(0, 80, 0, 60)
    laneBtn.Position = UDim2.new(lanePositions[i], -40, 0.95, -30)
    laneBtn.BackgroundColor3 = laneColors[i]
    laneBtn.BorderSizePixel = 3
    laneBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    laneBtn.Text = ""
    laneBtn.Parent = rhythmGameUI
    table.insert(laneButtons, laneBtn)
end

-- Score display
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size = UDim2.new(0, 200, 0, 50)
scoreLabel.Position = UDim2.new(0.5, -100, 0.05, 0)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Text = "SCORE: 0"
scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scoreLabel.TextScaled = true
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.TextStrokeTransparency = 0
scoreLabel.Parent = rhythmGameUI

-- Rhythm game functions
local function createForcefield(size, power, color)
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local root = character.HumanoidRootPart
    
    local forcefield = Instance.new("Part")
    forcefield.Name = "RhythmForcefield"
    forcefield.Shape = Enum.PartType.Ball
    forcefield.Size = Vector3.new(size, size, size)
    forcefield.Position = root.Position
    forcefield.Anchored = true
    forcefield.CanCollide = false
    forcefield.Material = Enum.Material.ForceField
    forcefield.Color = color
    forcefield.Transparency = 0.5
    forcefield.Parent = workspace
    
    -- Damage fake players in range
    for _, fakePlayer in ipairs(fakePlayersList) do
        if fakePlayer.character and fakePlayer.character:FindFirstChild("HumanoidRootPart") then
            local fakeRoot = fakePlayer.character.HumanoidRootPart
            local distance = (fakeRoot.Position - root.Position).Magnitude
            
            if distance <= size / 2 then
                local direction = (fakeRoot.Position - root.Position).Unit
                applyForce(fakePlayer.character, direction, power)
                
                -- Aggro fake player
                if not table.find(aggroedFakePlayers, fakePlayer) then
                    table.insert(aggroedFakePlayers, fakePlayer)
                    fakePlayer.isAggro = true
                end
            end
        end
    end
    
    -- Fade out
    local tween = TweenService:Create(forcefield, TweenInfo.new(0.3), {
        Transparency = 1
    })
    tween:Play()
    
    Debris:AddItem(forcefield, 0.5)
end

local function spawnNote(lane)
    local note = Instance.new("Frame")
    note.Name = "Note"
    note.Size = UDim2.new(0, 60, 0, 60)
    note.Position = UDim2.new(lanePositions[lane], -30, 0, -30)
    note.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    note.BorderSizePixel = 3
    note.BorderColor3 = laneColors[lane]
    note.Parent = rhythmGameUI
    
    local noteData = {
        frame = note,
        lane = lane,
        startTime = tick(),
        isSpecial = false
    }
    
    table.insert(rhythmNotes, noteData)
    
    return noteData
end

local function spawnSpecialNote(lane)
    local note = Instance.new("Frame")
    note.Name = "SpecialNote"
    note.Size = UDim2.new(0, 70, 0, 70)
    note.Position = UDim2.new(lanePositions[lane], -35, 0, -35)
    note.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    note.BorderSizePixel = 4
    note.BorderColor3 = Color3.fromRGB(255, 255, 255)
    note.Parent = rhythmGameUI
    
    local noteData = {
        frame = note,
        lane = lane,
        startTime = tick(),
        isSpecial = true
    }
    
    table.insert(rhythmNotes, noteData)
    
    return noteData
end

local function checkNoteHit(lane)
    local closestNote = nil
    local closestDistance = math.huge
    
    for i, noteData in ipairs(rhythmNotes) do
        if noteData.lane == lane and noteData.frame.Parent then
            local noteY = noteData.frame.Position.Y.Scale
            local targetY = targetZones[lane].Position.Y.Scale
            local distance = math.abs(noteY - targetY)
            
            if distance < closestDistance then
                closestDistance = distance
                closestNote = {data = noteData, index = i}
            end
        end
    end
    
    if closestNote and closestDistance < 0.05 then
        local noteData = closestNote.data
        noteData.frame:Destroy()
        table.remove(rhythmNotes, closestNote.index)
        
        rhythmScore = rhythmScore + (noteData.isSpecial and 100 or 10)
        scoreLabel.Text = "SCORE: " .. rhythmScore
        
        -- Determine forcefield based on song time
        if not rhythmSound then return end
        
        local songTime = rhythmSound.TimePosition
        local size, power, color
        
        if noteData.isSpecial then
            -- Black note special
            size = 150
            power = 17
            color = Color3.fromRGB(0, 0, 0)
        elseif songTime >= 82 then -- 1:22
            size = 65
            power = 13
            color = Color3.fromRGB(128, 0, 128)
        elseif songTime >= 65 then -- 1:05
            size = 50
            power = 10
            color = Color3.fromRGB(255, 0, 0)
        elseif songTime >= 51 then -- 0:51
            size = 35
            power = 8
            color = Color3.fromRGB(0, 0, 255)
        elseif songTime >= 9 then -- 0:09
            size = 20
            power = 5
            color = Color3.fromRGB(255, 255, 255)
        else
            size = 10
            power = 3
            color = Color3.fromRGB(100, 100, 100)
        end
        
        createForcefield(size, power, color)
        
        return true
    end
    
    return false
end

local function startRhythmGame()
    if rhythmGameActive then return end
    
    rhythmGameActive = true
    rhythmGameUI.Visible = true
    rhythmScore = 0
    rhythmNotes = {}
    
    -- Create and play sound
    rhythmSound = Instance.new("Sound")
    rhythmSound.SoundId = "rbxassetid://112166141751710"
    rhythmSound.Volume = 1
    rhythmSound.Parent = workspace
    rhythmSound:Play()
    
    -- Note spawning pattern
    spawn(function()
        local songStartTime = tick()
        local lastSpawnTime = 0
        local specialNoteSpawned = false
        
        while rhythmGameActive and rhythmSound.IsPlaying do
            local currentTime = tick() - songStartTime
            local songTime = rhythmSound.TimePosition
            
            -- Spawn special black note at 2:08
            if songTime >= 128 and not specialNoteSpawned then
                specialNoteSpawned = true
                local lane = math.random(1, 4)
                spawnSpecialNote(lane)
            end
            
            -- Regular note spawning
            if tick() - lastSpawnTime >= math.random(20, 100) / 100 then
                lastSpawnTime = tick()
                local lane = math.random(1, 4)
                spawnNote(lane)
            end
            
            wait()
        end
        
        -- Clean up when song ends
        wait(2)
        stopRhythmGame()
    end)
    
    -- Update note positions
    spawn(function()
        while rhythmGameActive do
            for i = #rhythmNotes, 1, -1 do
                local noteData = rhythmNotes[i]
                if noteData.frame.Parent then
                    local elapsed = tick() - noteData.startTime
                    local progress = elapsed / 2
                    
                    noteData.frame.Position = UDim2.new(
                        lanePositions[noteData.lane],
                        noteData.isSpecial and -35 or -30,
                        progress,
                        noteData.isSpecial and -35 or -30
                    )
                    
                    -- Remove if missed
                    if progress > 1 then
                        noteData.frame:Destroy()
                        table.remove(rhythmNotes, i)
                    end
                else
                    table.remove(rhythmNotes, i)
                end
            end
            
            RunService.RenderStepped:Wait()
        end
    end)
end

local function stopRhythmGame()
    rhythmGameActive = false
    rhythmGameUI.Visible = false
    
    if rhythmSound then
        rhythmSound:Stop()
        rhythmSound:Destroy()
        rhythmSound = nil
    end
    
    for _, noteData in ipairs(rhythmNotes) do
        if noteData.frame.Parent then
            noteData.frame:Destroy()
        end
    end
    
    rhythmNotes = {}
end

-- Button inputs for rhythm game
for i, btn in ipairs(laneButtons) do
    btn.MouseButton1Click:Connect(function()
        if rhythmGameActive then
            checkNoteHit(i)
        end
    end)
end

-- Keyboard inputs
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not rhythmGameActive then return end
    
    for i, key in ipairs(laneKeys) do
        if input.KeyCode == key then
            checkNoteHit(i)
            
            -- Visual feedback
            laneButtons[i].BackgroundTransparency = 0.5
            spawn(function()
                wait(0.1)
                laneButtons[i].BackgroundTransparency = 0
            end)
            break
        end
    end
end)

-- Chat function
local function sendAdminChat(message)
    local chatLabel = Instance.new("TextLabel")
    chatLabel.Size = UDim2.new(0, 400, 0, 30)
    chatLabel.Position = UDim2.new(0, 20, 0, 100)
    chatLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    chatLabel.BackgroundTransparency = 0.5
    chatLabel.BorderSizePixel = 2
    chatLabel.BorderColor3 = Color3.fromRGB(255, 255, 255)
    chatLabel.Text = message
    chatLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    chatLabel.TextSize = 18
    chatLabel.Font = Enum.Font.Gotham
    chatLabel.TextXAlignment = Enum.TextXAlignment.Left
    chatLabel.Parent = screenGui
    
    spawn(function()
        wait(3)
        chatLabel:Destroy()
    end)
end

-- Fake player chat function
local function sendFakePlayerChat(fakePlayerName, message)
    local chatLabel = Instance.new("TextLabel")
    chatLabel.Size = UDim2.new(0, 450, 0, 35)
    chatLabel.Position = UDim2.new(0, 20, 0, 140)
    chatLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    chatLabel.BackgroundTransparency = 0.3
    chatLabel.BorderSizePixel = 2
    chatLabel.BorderColor3 = Color3.fromRGB(100, 150, 255)
    chatLabel.Text = "[" .. fakePlayerName .. "]: " .. message
    chatLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
    chatLabel.TextSize = 16
    chatLabel.Font = Enum.Font.Gotham
    chatLabel.TextXAlignment = Enum.TextXAlignment.Left
    chatLabel.Parent = screenGui
    
    spawn(function()
        wait(4)
        chatLabel:Destroy()
    end)
end

-- Admin Commands
local adminCommands = {
    {
        name = "Explode",
        cooldown = 30,
        func = function()
            local currentTime = tick()
            if currentTime - adminCommandCooldowns.explode < 30 then
                return
            end
            
            adminCommandCooldowns.explode = currentTime
            
            -- Clear existing highlights
            for _, h in ipairs(activeHighlights) do
                if h.Parent then h:Destroy() end
            end
            activeHighlights = {}
            
            local selectedNames = {}
            
            -- Highlight all fake players
            for _, fakePlayer in ipairs(fakePlayersList) do
                if fakePlayer.character then
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Color3.fromRGB(255, 100, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Parent = fakePlayer.character
                    table.insert(activeHighlights, highlight)
                    
                    local clickDetector = Instance.new("ClickDetector")
                    clickDetector.MaxActivationDistance = 100
                    clickDetector.Parent = fakePlayer.character.HumanoidRootPart
                    
                    clickDetector.MouseClick:Connect(function()
                        table.insert(selectedNames, fakePlayer.name)
                        
                        if fakePlayer.character and fakePlayer.character:FindFirstChild("HumanoidRootPart") then
                            local explosion = Instance.new("Explosion")
                            explosion.Position = fakePlayer.character.HumanoidRootPart.Position
                            explosion.BlastRadius = 10
                            explosion.BlastPressure = 0
                            explosion.Parent = workspace
                            
                            local randomAngle = math.random() * math.pi * 2
                            local randomElevation = (math.random() - 0.5) * math.pi * 0.5
                            local direction = Vector3.new(
                                math.cos(randomAngle) * math.cos(randomElevation),
                                math.sin(randomElevation),
                                math.sin(randomAngle) * math.cos(randomElevation)
                            ).Unit
                            
                            applyForce(fakePlayer.character, direction, 12)
                        end
                        
                        clickDetector:Destroy()
                        if highlight.Parent then highlight:Destroy() end
                    end)
                end
            end
            
            spawn(function()
                wait(10)
                for _, h in ipairs(activeHighlights) do
                    if h.Parent then h:Destroy() end
                end
                activeHighlights = {}
                
                if #selectedNames > 0 then
                    local nameStr = table.concat(selectedNames, ", ")
                    sendAdminChat("/Explode " .. nameStr)
                end
            end)
        end
    },
    {
        name = "Speed",
        cooldown = 50,
        func = function()
            local currentTime = tick()
            if currentTime - adminCommandCooldowns.speed < 50 then
                return
            end
            
            adminCommandCooldowns.speed = currentTime
            
            local inputFrame = Instance.new("Frame")
            inputFrame.Size = UDim2.new(0, 300, 0, 150)
            inputFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
            inputFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            inputFrame.BorderSizePixel = 3
            inputFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
            inputFrame.Parent = screenGui
            
            local inputBox = Instance.new("TextBox")
            inputBox.Size = UDim2.new(1, -20, 0, 40)
            inputBox.Position = UDim2.new(0, 10, 0, 30)
            inputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            inputBox.Text = "16"
            inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            inputBox.TextScaled = true
            inputBox.Font = Enum.Font.Gotham
            inputBox.Parent = inputFrame
            
            local confirmBtn = Instance.new("TextButton")
            confirmBtn.Size = UDim2.new(0, 100, 0, 40)
            confirmBtn.Position = UDim2.new(0.5, -50, 1, -50)
            confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            confirmBtn.Text = "SET"
            confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            confirmBtn.TextScaled = true
            confirmBtn.Font = Enum.Font.GothamBold
            confirmBtn.Parent = inputFrame
            
            confirmBtn.MouseButton1Click:Connect(function()
                local speedValue = tonumber(inputBox.Text) or 16
                if humanoid then
                    humanoid.WalkSpeed = speedValue
                    sendAdminChat("/Speed " .. speedValue)
                end
                inputFrame:Destroy()
            end)
        end
    },
    {
        name = "Anvil",
        cooldown = 35,
        func = function()
            local currentTime = tick()
            if currentTime - adminCommandCooldowns.anvil < 35 then
                return
            end
            
            adminCommandCooldowns.anvil = currentTime
            
            for _, h in ipairs(activeHighlights) do
                if h.Parent then h:Destroy() end
            end
            activeHighlights = {}
            
            local selectedNames = {}
            
            for _, fakePlayer in ipairs(fakePlayersList) do
                if fakePlayer.character then
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Color3.fromRGB(100, 100, 100)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Parent = fakePlayer.character
                    table.insert(activeHighlights, highlight)
                    
                    local clickDetector = Instance.new("ClickDetector")
                    clickDetector.MaxActivationDistance = 100
                    clickDetector.Parent = fakePlayer.character.HumanoidRootPart
                    
                    clickDetector.MouseClick:Connect(function()
                        table.insert(selectedNames, fakePlayer.name)
                        
                        if fakePlayer.character and fakePlayer.character:FindFirstChild("HumanoidRootPart") then
                            local targetRoot = fakePlayer.character.HumanoidRootPart
                            local anvilSpawnPos = targetRoot.Position + Vector3.new(0, 20, 0)
                            
                            local anvil = Instance.new("Part")
                            anvil.Name = "Anvil"
                            anvil.Size = Vector3.new(3, 2, 3)
                            anvil.Position = anvilSpawnPos
                            anvil.Anchored = false
                            anvil.Material = Enum.Material.Metal
                            anvil.Color = Color3.fromRGB(80, 80, 80)
                            anvil.Parent = workspace
                            
                            local bv = Instance.new("BodyVelocity")
                            bv.MaxForce = Vector3.new(0, 4e4, 0)
                            bv.Velocity = Vector3.new(0, -100, 0)
                            bv.Parent = anvil
                            
                            local hitConn
                            hitConn = anvil.Touched:Connect(function(hit)
                                if hit.Parent == fakePlayer.character then
                                    applyForce(fakePlayer.character, Vector3.new(0, -1, 0), 13)
                                    hitConn:Disconnect()
                                    Debris:AddItem(anvil, 1)
                                end
                            end)
                            
                            Debris:AddItem(anvil, 3)
                        end
                        
                        clickDetector:Destroy()
                        if highlight.Parent then highlight:Destroy() end
                    end)
                end
            end
            
            spawn(function()
                wait(10)
                for _, h in ipairs(activeHighlights) do
                    if h.Parent then h:Destroy() end
                end
                
                if #selectedNames > 0 then
                    local nameStr = table.concat(selectedNames, ", ")
                    sendAdminChat("/Anvil " .. nameStr)
                end
            end)
        end
    },
    {
        name = "JumpPower",
        cooldown = 50,
        func = function()
            local currentTime = tick()
            if currentTime - adminCommandCooldowns.jumppower < 50 then
                return
            end
            
            adminCommandCooldowns.jumppower = currentTime
            
            local inputFrame = Instance.new("Frame")
            inputFrame.Size = UDim2.new(0, 300, 0, 150)
            inputFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
            inputFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            inputFrame.BorderSizePixel = 3
            inputFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
            inputFrame.Parent = screenGui
            
            local inputBox = Instance.new("TextBox")
            inputBox.Size = UDim2.new(1, -20, 0, 40)
            inputBox.Position = UDim2.new(0, 10, 0, 30)
            inputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            inputBox.Text = "50"
            inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            inputBox.TextScaled = true
            inputBox.Font = Enum.Font.Gotham
            inputBox.Parent = inputFrame
            
            local confirmBtn = Instance.new("TextButton")
            confirmBtn.Size = UDim2.new(0, 100, 0, 40)
            confirmBtn.Position = UDim2.new(0.5, -50, 1, -50)
            confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
            confirmBtn.Text = "SET"
            confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            confirmBtn.TextScaled = true
            confirmBtn.Font = Enum.Font.GothamBold
            confirmBtn.Parent = inputFrame
            
            confirmBtn.MouseButton1Click:Connect(function()
                local jumpValue = tonumber(inputBox.Text) or 50
                if humanoid then
                    humanoid.JumpPower = jumpValue
                    sendAdminChat("/JumpPower " .. jumpValue)
                end
                inputFrame:Destroy()
            end)
        end
    },
    {
        name = "Bring",
        cooldown = 55,
        func = function()
            local currentTime = tick()
            if currentTime - adminCommandCooldowns.bring < 55 then
                return
            end
            
            adminCommandCooldowns.bring = currentTime
            
            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Size = UDim2.new(0, 300, 0, 300)
            dropdownFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
            dropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            dropdownFrame.BorderSizePixel = 3
            dropdownFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
            dropdownFrame.Parent = screenGui
            
            local scrollFrame = Instance.new("ScrollingFrame")
            scrollFrame.Size = UDim2.new(1, -20, 1, -20)
            scrollFrame.Position = UDim2.new(0, 10, 0, 10)
            scrollFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            scrollFrame.BorderSizePixel = 0
            scrollFrame.ScrollBarThickness = 6
            scrollFrame.Parent = dropdownFrame
            
            local yOffset = 0
            for _, fakePlayer in ipairs(fakePlayersList) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -10, 0, 40)
                btn.Position = UDim2.new(0, 5, 0, yOffset)
                btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                btn.Text = fakePlayer.name
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextScaled = true
                btn.Font = Enum.Font.Gotham
                btn.Parent = scrollFrame
                
                btn.MouseButton1Click:Connect(function()
                    if fakePlayer.character and fakePlayer.rootPart and character and rootPart then
                        fakePlayer.rootPart.CFrame = rootPart.CFrame + Vector3.new(5, 0, 0)
                        sendAdminChat("/Bring " .. fakePlayer.name)
                    end
                    dropdownFrame:Destroy()
                end)
                
                yOffset = yOffset + 45
            end
            
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
        end
    },
    {
        name = "Goto",
        cooldown = 53,
        func = function()
            local currentTime = tick()
            if currentTime - adminCommandCooldowns.goto < 53 then
                return
            end
            
            adminCommandCooldowns.goto = currentTime
            
            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Size = UDim2.new(0, 300, 0, 300)
            dropdownFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
            dropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            dropdownFrame.BorderSizePixel = 3
            dropdownFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
            dropdownFrame.Parent = screenGui
            
            local scrollFrame = Instance.new("ScrollingFrame")
            scrollFrame.Size = UDim2.new(1, -20, 1, -20)
            scrollFrame.Position = UDim2.new(0, 10, 0, 10)
            scrollFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            scrollFrame.BorderSizePixel = 0
            scrollFrame.ScrollBarThickness = 6
            scrollFrame.Parent = dropdownFrame
            
            local yOffset = 0
            for _, fakePlayer in ipairs(fakePlayersList) do
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -10, 0, 40)
                btn.Position = UDim2.new(0, 5, 0, yOffset)
                btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                btn.Text = fakePlayer.name
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextScaled = true
                btn.Font = Enum.Font.Gotham
                btn.Parent = scrollFrame
                
                btn.MouseButton1Click:Connect(function()
                    if fakePlayer.character and fakePlayer.rootPart and character and rootPart then
                        rootPart.CFrame = fakePlayer.rootPart.CFrame + Vector3.new(5, 0, 0)
                        sendAdminChat("/Goto " .. fakePlayer.name)
                    end
                    dropdownFrame:Destroy()
                end)
                
                yOffset = yOffset + 45
            end
            
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
        end
    },
    {
        name = "Train",
        cooldown = 60,
        func = function()
            local currentTime = tick()
            if currentTime - adminCommandCooldowns.train < 60 then
                return
            end
            
            adminCommandCooldowns.train = currentTime
            
            activateTrainAbility(nil, true)
            sendAdminChat("/Train")
        end
    },
    {
        name = "Freeze",
        cooldown = 40,
        func = function()
            local currentTime = tick()
            if currentTime - adminCommandCooldowns.freeze < 40 then
                return
            end
            
            adminCommandCooldowns.freeze = currentTime
            
            for _, h in ipairs(activeHighlights) do
                if h.Parent then h:Destroy() end
            end
            activeHighlights = {}
            
            local selectedNames = {}
            
            for _, fakePlayer in ipairs(fakePlayersList) do
                if fakePlayer.character then
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Color3.fromRGB(100, 200, 255)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Parent = fakePlayer.character
                    table.insert(activeHighlights, highlight)
                    
                    local clickDetector = Instance.new("ClickDetector")
                    clickDetector.MaxActivationDistance = 100
                    clickDetector.Parent = fakePlayer.character.HumanoidRootPart
                    
                    clickDetector.MouseClick:Connect(function()
                        table.insert(selectedNames, fakePlayer.name)
                        
                        if fakePlayer.humanoid then
                            local originalSpeed = fakePlayer.humanoid.WalkSpeed
                            fakePlayer.humanoid.WalkSpeed = 0
                            
                            spawn(function()
                                wait(5)
                                if fakePlayer.humanoid then
                                    fakePlayer.humanoid.WalkSpeed = originalSpeed
                                end
                            end)
                        end
                        
                        clickDetector:Destroy()
                        if highlight.Parent then highlight:Destroy() end
                    end)
                end
            end
            
            spawn(function()
                wait(10)
                for _, h in ipairs(activeHighlights) do
                    if h.Parent then h:Destroy() end
                end
                
                if #selectedNames > 0 then
                    local nameStr = table.concat(selectedNames, ", ")
                    sendAdminChat("/Freeze " .. nameStr)
                end
            end)
        end
    },
    {
        name = "Ragdoll",
        cooldown = 45,
        func = function()
            local currentTime = tick()
            if currentTime - adminCommandCooldowns.ragdoll < 45 then
                return
            end
            
            adminCommandCooldowns.ragdoll = currentTime
            
            for _, h in ipairs(activeHighlights) do
                if h.Parent then h:Destroy() end
            end
            activeHighlights = {}
            
            local selectedNames = {}
            
            for _, fakePlayer in ipairs(fakePlayersList) do
                if fakePlayer.character then
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Color3.fromRGB(200, 100, 255)
                    highlight.OutlineColor = Color3.fromRGB(255, 100, 255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Parent = fakePlayer.character
                    table.insert(activeHighlights, highlight)
                    
                    local clickDetector = Instance.new("ClickDetector")
                    clickDetector.MaxActivationDistance = 100
                    clickDetector.Parent = fakePlayer.character.HumanoidRootPart
                    
                    clickDetector.MouseButton1Click:Connect(function()
                        table.insert(selectedNames, fakePlayer.name)
                        
                        if fakePlayer.humanoid and fakePlayer.rootPart then
                            fakePlayer.humanoid.PlatformStand = true
                            
                            local randomDir = Vector3.new(
                                math.random(-1, 1),
                                math.random(0, 1),
                                math.random(-1, 1)
                            ).Unit
                            
                            applyForce(fakePlayer.character, randomDir, 15)
                            
                            spawn(function()
                                wait(3)
                                if fakePlayer.humanoid then
                                    fakePlayer.humanoid.PlatformStand = false
                                end
                            end)
                        end
                        
                        clickDetector:Destroy()
                        if highlight.Parent then highlight:Destroy() end
                    end)
                end
            end
            
            spawn(function()
                wait(10)
                for _, h in ipairs(activeHighlights) do
                    if h.Parent then h:Destroy() end
                end
                
                if #selectedNames > 0 then
                    local nameStr = table.concat(selectedNames, ", ")
                    sendAdminChat("/Ragdoll " .. nameStr)
                end
            end)
        end
    }
}

-- Create command buttons in admin panel
local function createAdminCommandButtons()
    local yOffset = 10
    for _, cmd in ipairs(adminCommands) do
        local cmdFrame = Instance.new("Frame")
        cmdFrame.Size = UDim2.new(1, -20, 0, 60)
        cmdFrame.Position = UDim2.new(0, 10, 0, yOffset)
        cmdFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        cmdFrame.BorderSizePixel = 2
        cmdFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
        cmdFrame.Parent = adminScrollFrame
        
        local cmdLabel = Instance.new("TextLabel")
        cmdLabel.Size = UDim2.new(0.6, 0, 1, 0)
        cmdLabel.BackgroundTransparency = 1
        cmdLabel.Text = "/" .. cmd.name
        cmdLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        cmdLabel.TextSize = 16
        cmdLabel.Font = Enum.Font.GothamBold
        cmdLabel.TextXAlignment = Enum.TextXAlignment.Left
        cmdLabel.Parent = cmdFrame
        
        local cooldownLabel = Instance.new("TextLabel")
        cooldownLabel.Size = UDim2.new(0.3, 0, 0.4, 0)
        cooldownLabel.Position = UDim2.new(0.6, 0, 0.5, 0)
        cooldownLabel.BackgroundTransparency = 1
        cooldownLabel.Text = cmd.cooldown .. "s CD"
        cooldownLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        cooldownLabel.TextSize = 12
        cooldownLabel.Font = Enum.Font.Gotham
        cooldownLabel.Parent = cmdFrame
        
        local useBtn = Instance.new("TextButton")
        useBtn.Size = UDim2.new(0, 80, 0, 40)
        useBtn.Position = UDim2.new(1, -90, 0.5, -20)
        useBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        useBtn.Text = "USE"
        useBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        useBtn.TextScaled = true
        useBtn.Font = Enum.Font.GothamBold
        useBtn.Parent = cmdFrame
        
        useBtn.MouseButton1Click:Connect(function()
            cmd.func()
        end)
        
        yOffset = yOffset + 70
    end
    
    adminScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

createAdminCommandButtons()

-- AirBomb ability
local function activateAirBombAbility(caster, isPlayer, targetOverride)
    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        -- Clear any existing highlights
        for _, highlight in ipairs(activeHighlights) do
            if highlight.Parent then
                highlight:Destroy()
            end
        end
        activeHighlights = {}
        
        airBombTargetingActive = true
        
        -- Highlight all fake players
        for _, fakePlayer in ipairs(fakePlayersList) do
            if fakePlayer.character then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(135, 206, 235)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
                highlight.FillTransparency = 0.5
                highlight.OutlineTransparency = 0
                highlight.Parent = fakePlayer.character
                table.insert(activeHighlights, highlight)
                
                -- Create click detector for selection
                local clickDetector = Instance.new("ClickDetector")
                clickDetector.MaxActivationDistance = 100
                clickDetector.Parent = fakePlayer.character.HumanoidRootPart
                
                clickDetector.MouseClick:Connect(function()
                    if not airBombTargetingActive then return end
                    
                    airBombTargetingActive = false
                    
                    -- Remove all highlights except selected
                    for _, h in ipairs(activeHighlights) do
                        if h.Parent ~= fakePlayer.character and h.Parent then
                            h:Destroy()
                        end
                    end
                    
                    -- Remove click detectors from all
                    for _, fp in ipairs(fakePlayersList) do
                        if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                            local cd = fp.character.HumanoidRootPart:FindFirstChild("ClickDetector")
                            if cd then cd:Destroy() end
                        end
                    end
                    
                    -- Drop bomb on selected target
                    spawn(function()
                        wait(3)
                        
                        if fakePlayer.character and fakePlayer.character:FindFirstChild("HumanoidRootPart") then
                            local targetRoot = fakePlayer.character.HumanoidRootPart
                            local bombSpawnPos = targetRoot.Position + Vector3.new(0, 50, 0)
                            
                            -- Create bomb
                            local bomb = Instance.new("Part")
                            bomb.Name = "AirBomb"
                            bomb.Shape = Enum.PartType.Ball
                            bomb.Size = Vector3.new(3, 3, 3)
                            bomb.Position = bombSpawnPos
                            bomb.Anchored = true
                            bomb.CanCollide = false
                            bomb.Material = Enum.Material.Neon
                            bomb.Color = Color3.fromRGB(255, 0, 0)
                            bomb.Parent = workspace
                            
                            -- Create trail effect
                            local trail = Instance.new("Trail")
                            local attach0 = Instance.new("Attachment")
                            local attach1 = Instance.new("Attachment")
                            attach0.Position = Vector3.new(0, 1, 0)
                            attach1.Position = Vector3.new(0, -1, 0)
                            attach0.Parent = bomb
                            attach1.Parent = bomb
                            trail.Attachment0 = attach0
                            trail.Attachment1 = attach1
                            trail.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
                            trail.Lifetime = 0.5
                            trail.Parent = bomb
                            
                            -- Animate bomb falling
                            local startTime = tick()
                            local fallDuration = 1.5
                            
                            while tick() - startTime < fallDuration do
                                local progress = (tick() - startTime) / fallDuration
                                bomb.Position = bombSpawnPos:Lerp(targetRoot.Position, progress)
                                RunService.Heartbeat:Wait()
                            end
                            
                            -- Explosion
                            local explosion = Instance.new("Explosion")
                            explosion.Position = targetRoot.Position
                            explosion.BlastRadius = 10
                            explosion.BlastPressure = 0
                            explosion.Parent = workspace
                            
                            -- Random direction push
                            local randomAngle = math.random() * math.pi * 2
                            local randomElevation = (math.random() - 0.5) * math.pi * 0.5
                            local direction = Vector3.new(
                                math.cos(randomAngle) * math.cos(randomElevation),
                                math.sin(randomElevation),
                                math.sin(randomAngle) * math.cos(randomElevation)
                            ).Unit
                            
                            applyForce(fakePlayer.character, direction, 15)
                            
                            bomb:Destroy()
                        end
                        
                        -- Remove highlight
                        for _, h in ipairs(activeHighlights) do
                            if h.Parent then
                                h:Destroy()
                            end
                        end
                        activeHighlights = {}
                    end)
                end)
            end
        end
        
        -- Auto-cancel after 10 seconds if no selection
        spawn(function()
            wait(10)
            if airBombTargetingActive then
                airBombTargetingActive = false
                for _, h in ipairs(activeHighlights) do
                    if h.Parent then
                        h:Destroy()
                    end
                end
                activeHighlights = {}
                
                -- Remove click detectors
                for _, fp in ipairs(fakePlayersList) do
                    if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                        local cd = fp.character.HumanoidRootPart:FindFirstChild("ClickDetector")
                        if cd then cd:Destroy() end
                    end
                end
            end
        end)
    else
        -- Fake player using AirBomb on real player
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end
        
        local playerRoot = character.HumanoidRootPart
        local distance = (playerRoot.Position - caster.character.HumanoidRootPart.Position).Magnitude
        
        -- Only activate if player is 75-100 studs away
        if distance < 75 or distance > 100 then
            return
        end
        
        -- Highlight player
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(135, 206, 235)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Parent = character
        
        -- Wait 3 seconds then drop bomb
        spawn(function()
            wait(3)
            
            if character and playerRoot.Parent then
                local bombSpawnPos = playerRoot.Position + Vector3.new(0, 50, 0)
                
                -- Create bomb
                local bomb = Instance.new("Part")
                bomb.Name = "AirBomb"
                bomb.Shape = Enum.PartType.Ball
                bomb.Size = Vector3.new(3, 3, 3)
                bomb.Position = bombSpawnPos
                bomb.Anchored = true
                bomb.CanCollide = false
                bomb.Material = Enum.Material.Neon
                bomb.Color = Color3.fromRGB(255, 0, 0)
                bomb.Parent = workspace
                
                -- Animate bomb falling
                local startTime = tick()
                local fallDuration = 1.5
                
                while tick() - startTime < fallDuration do
                    local progress = (tick() - startTime) / fallDuration
                    bomb.Position = bombSpawnPos:Lerp(playerRoot.Position, progress)
                    RunService.Heartbeat:Wait()
                end
                
                -- Explosion
                local explosion = Instance.new("Explosion")
                explosion.Position = playerRoot.Position
                explosion.BlastRadius = 10
                explosion.BlastPressure = 0
                explosion.Parent = workspace
                
                -- Random direction push
                local randomAngle = math.random() * math.pi * 2
                local randomElevation = (math.random() - 0.5) * math.pi * 0.5
                local direction = Vector3.new(
                    math.cos(randomAngle) * math.cos(randomElevation),
                    math.sin(randomElevation),
                    math.sin(randomAngle) * math.cos(randomElevation)
                ).Unit
                
                applyForce(character, direction, 15)
                
                bomb:Destroy()
            end
            
            -- Remove highlight
            if highlight.Parent then
                highlight:Destroy()
            end
        end)
    end
end

-- Engineer Turret ability
local function activateEngineerTurret(caster, isPlayer)
    local casterRoot
    
    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end
        casterRoot = character.HumanoidRootPart
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then
            return
        end
        casterRoot = caster.character.HumanoidRootPart
    end
    
    local turretPosition = casterRoot.Position + Vector3.new(0, 0, 5)
    
    -- Create turret base
    local turretBase = Instance.new("Part")
    turretBase.Name = "TurretBase"
    turretBase.Size = Vector3.new(3, 1, 3)
    turretBase.Position = turretPosition
    turretBase.Anchored = true
    turretBase.CanCollide = true
    turretBase.Material = Enum.Material.Metal
    turretBase.Color = Color3.fromRGB(100, 100, 100)
    turretBase.Parent = workspace
    
    -- Create turret head
    local turretHead = Instance.new("Part")
    turretHead.Name = "TurretHead"
    turretHead.Size = Vector3.new(2, 2, 2)
    turretHead.Position = turretPosition + Vector3.new(0, 1.5, 0)
    turretHead.Anchored = true
    turretHead.CanCollide = false
    turretHead.Material = Enum.Material.Metal
    turretHead.Color = Color3.fromRGB(255, 140, 0)
    turretHead.Parent = workspace
    
    -- Create barrel
    local barrel = Instance.new("Part")
    barrel.Name = "Barrel"
    barrel.Size = Vector3.new(0.5, 0.5, 2)
    barrel.Position = turretHead.Position + Vector3.new(0, 0, 1)
    barrel.Anchored = true
    barrel.CanCollide = false
    barrel.Material = Enum.Material.Metal
    barrel.Color = Color3.fromRGB(50, 50, 50)
    barrel.Parent = turretHead
    
    local turretData = {
        base = turretBase,
        head = turretHead,
        barrel = barrel,
        health = 30,
        owner = isPlayer and "player" or caster,
        isPlayerOwned = isPlayer,
        lastShootTime = 0
    }
    
    table.insert(activeTurrets, turretData)
    
    -- Turret shooting logic
    local shootConnection
    shootConnection = RunService.Heartbeat:Connect(function()
        if not turretHead.Parent or turretData.health <= 0 then
            shootConnection:Disconnect()
            if turretBase.Parent then turretBase:Destroy() end
            if turretHead.Parent then turretHead:Destroy() end
            for i, t in ipairs(activeTurrets) do
                if t == turretData then
                    table.remove(activeTurrets, i)
                    break
                end
            end
            return
        end
        
        local currentTime = tick()
        if currentTime - turretData.lastShootTime < 5 then
            return
        end
        
        local nearestTarget = nil
        local nearestDistance = math.huge
        
        -- Find nearest target
        if isPlayer then
            -- Turret owned by player - target fake players
            for _, fakePlayer in ipairs(fakePlayersList) do
                if fakePlayer.character and fakePlayer.character:FindFirstChild("HumanoidRootPart") then
                    local dist = (fakePlayer.character.HumanoidRootPart.Position - turretHead.Position).Magnitude
                    if dist < nearestDistance then
                        nearestDistance = dist
                        nearestTarget = fakePlayer.character
                    end
                end
            end
        else
            -- Turret owned by fake player - target real player
            if character and character:FindFirstChild("HumanoidRootPart") then
                nearestTarget = character
            end
        end
        
        if nearestTarget and nearestTarget:FindFirstChild("HumanoidRootPart") then
            local targetRoot = nearestTarget.HumanoidRootPart
            
            -- Rotate turret to face target
            local lookDirection = (targetRoot.Position - turretHead.Position).Unit
            turretHead.CFrame = CFrame.lookAt(turretHead.Position, targetRoot.Position)
            barrel.CFrame = CFrame.lookAt(barrel.Position, targetRoot.Position) * CFrame.new(0, 0, -1)
            
            -- Shoot bullet
            turretData.lastShootTime = currentTime
            
            local bullet = Instance.new("Part")
            bullet.Name = "TurretBullet"
            bullet.Size = Vector3.new(0.5, 0.5, 1)
            bullet.Position = barrel.Position + lookDirection * 2
            bullet.Anchored = false
            bullet.CanCollide = false
            bullet.Material = Enum.Material.Neon
            bullet.Color = Color3.fromRGB(255, 255, 0)
            bullet.Parent = workspace
            
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(4e4, 4e4, 4e4)
            bodyVelocity.Velocity = lookDirection * 80
            bodyVelocity.Parent = bullet
            
            -- Bullet hit detection
            local hitConnection
            hitConnection = RunService.Heartbeat:Connect(function()
                if not bullet.Parent then
                    hitConnection:Disconnect()
                    return
                end
                
                if nearestTarget and nearestTarget:FindFirstChild("HumanoidRootPart") then
                    local dist = (nearestTarget.HumanoidRootPart.Position - bullet.Position).Magnitude
                    if dist <= 3 then
                        local direction = (nearestTarget.HumanoidRootPart.Position - bullet.Position).Unit
                        applyForce(nearestTarget, direction, 5)
                        
                        -- Aggro target to turret
                        if not isPlayer then
                            -- Player got hit, aggro to turret
                            if not table.find(aggroedFakePlayers, caster) then
                                table.insert(aggroedFakePlayers, caster)
                                caster.isAggro = true
                                caster.aggroTarget = "turret"
                                caster.aggroTurret = turretData
                            end
                        end
                        
                        hitConnection:Disconnect()
                        bullet:Destroy()
                    end
                end
            end)
            
            Debris:AddItem(bullet, 3)
        end
    end)
    
    -- Auto-destroy after 2 minutes
    spawn(function()
        wait(120)
        if shootConnection then
            shootConnection:Disconnect()
        end
        if turretBase.Parent then turretBase:Destroy() end
        if turretHead.Parent then turretHead:Destroy() end
        for i, t in ipairs(activeTurrets) do
            if t == turretData then
                table.remove(activeTurrets, i)
                break
            end
        end
    end)
end

-- Engineer Roomba ability
local function activateEngineerRoombas(caster, isPlayer)
    local casterRoot
    
    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end
        casterRoot = character.HumanoidRootPart
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then
            return
        end
        casterRoot = caster.character.HumanoidRootPart
    end
    
    -- Create 3 roombas
    for i = 1, 3 do
        local angle = (i - 1) * (math.pi * 2 / 3)
        local offset = Vector3.new(math.cos(angle) * 5, 0, math.sin(angle) * 5)
        local roombaPosition = casterRoot.Position + offset
        
        -- Create roomba
        local roomba = Instance.new("Part")
        roomba.Name = "Roomba"
        roomba.Shape = Enum.PartType.Cylinder
        roomba.Size = Vector3.new(1, 2, 2)
        roomba.Position = roombaPosition
        roomba.Anchored = false
        roomba.CanCollide = true
        roomba.Material = Enum.Material.Plastic
        roomba.Color = Color3.fromRGB(100, 200, 255)
        roomba.Orientation = Vector3.new(0, 0, 90)
        roomba.Parent = workspace
        
        -- Add bodygyro for stability
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(4e4, 4e4, 4e4)
        bodyGyro.P = 3000
        bodyGyro.Parent = roomba
        
        local roombaData = {
            part = roomba,
            health = 15,
            owner = isPlayer and "player" or caster,
            isPlayerOwned = isPlayer,
            lastShootTime = 0,
            bodyGyro = bodyGyro
        }
        
        table.insert(activeRoombas, roombaData)
        
        -- Roomba AI and shooting
        local roombaConnection
        roombaConnection = RunService.Heartbeat:Connect(function()
            if not roomba.Parent or roombaData.health <= 0 then
                roombaConnection:Disconnect()
                if roomba.Parent then roomba:Destroy() end
                for j, r in ipairs(activeRoombas) do
                    if r == roombaData then
                        table.remove(activeRoombas, j)
                        break
                    end
                end
                return
            end
            
            local nearestTarget = nil
            local nearestDistance = math.huge
            
            -- Find nearest target
            if isPlayer then
                for _, fakePlayer in ipairs(fakePlayersList) do
                    if fakePlayer.character and fakePlayer.character:FindFirstChild("HumanoidRootPart") then
                        local dist = (fakePlayer.character.HumanoidRootPart.Position - roomba.Position).Magnitude
                        if dist < nearestDistance then
                            nearestDistance = dist
                            nearestTarget = fakePlayer.character
                        end
                    end
                end
            else
                if character and character:FindFirstChild("HumanoidRootPart") then
                    nearestTarget = character
                    nearestDistance = (character.HumanoidRootPart.Position - roomba.Position).Magnitude
                end
            end
            
            if nearestTarget and nearestTarget:FindFirstChild("HumanoidRootPart") then
                local targetRoot = nearestTarget.HumanoidRootPart
                
                -- Move towards target
                local direction = (targetRoot.Position - roomba.Position).Unit
                local moveForce = roomba:FindFirstChild("MoveForce")
                if not moveForce then
                    moveForce = Instance.new("BodyVelocity")
                    moveForce.Name = "MoveForce"
                    moveForce.MaxForce = Vector3.new(3000, 0, 3000)
                    moveForce.Parent = roomba
                end
                moveForce.Velocity = Vector3.new(direction.X * 10, 0, direction.Z * 10)
                
                -- Shoot every 3 seconds
                local currentTime = tick()
                if currentTime - roombaData.lastShootTime >= 3 then
                    roombaData.lastShootTime = currentTime
                    
                    local bullet = Instance.new("Part")
                    bullet.Name = "RoombaBullet"
                    bullet.Size = Vector3.new(0.3, 0.3, 0.6)
                    bullet.Position = roomba.Position + direction * 2
                    bullet.Anchored = false
                    bullet.CanCollide = false
                    bullet.Material = Enum.Material.Neon
                    bullet.Color = Color3.fromRGB(100, 200, 255)
                    bullet.Parent = workspace
                    
                    local bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(4e4, 4e4, 4e4)
                    bv.Velocity = direction * 60
                    bv.Parent = bullet
                    
                    -- Bullet hit
                    local hitConn
                    hitConn = RunService.Heartbeat:Connect(function()
                        if not bullet.Parent then
                            hitConn:Disconnect()
                            return
                        end
                        
                        if nearestTarget and nearestTarget:FindFirstChild("HumanoidRootPart") then
                            local dist = (nearestTarget.HumanoidRootPart.Position - bullet.Position).Magnitude
                            if dist <= 2.5 then
                                local dir = (nearestTarget.HumanoidRootPart.Position - bullet.Position).Unit
                                applyForce(nearestTarget, dir, 2)
                                
                                -- Aggro to roomba
                                if not isPlayer then
                                    if not table.find(aggroedFakePlayers, caster) then
                                        table.insert(aggroedFakePlayers, caster)
                                        caster.isAggro = true
                                        caster.aggroTarget = "roomba"
                                        caster.aggroRoomba = roombaData
                                    end
                                end
                                
                                hitConn:Disconnect()
                                bullet:Destroy()
                            end
                        end
                    end)
                    
                    Debris:AddItem(bullet, 2)
                end
            end
        end)
        
        -- Auto-destroy after 2 minutes
        spawn(function()
            wait(120)
            if roombaConnection then
                roombaConnection:Disconnect()
            end
            if roomba.Parent then roomba:Destroy() end
            for j, r in ipairs(activeRoombas) do
                if r == roombaData then
                    table.remove(activeRoombas, j)
                    break
                end
            end
        end)
    end
end

-- LandMine ability
local function activateLandMineAbility(caster, isPlayer)
    local casterRoot
    local minePosition
    
    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end
        casterRoot = character.HumanoidRootPart
        
        -- Player places mine at their position
        minePosition = casterRoot.Position
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then
            return
        end
        casterRoot = caster.character.HumanoidRootPart
        
        -- Fake player places mine 30-50 studs away from player
        if character and character:FindFirstChild("HumanoidRootPart") then
            local playerRoot = character.HumanoidRootPart
            local directionToPlayer = (playerRoot.Position - casterRoot.Position).Unit
            local randomDistance = math.random(30, 50)
            minePosition = playerRoot.Position - directionToPlayer * randomDistance
            minePosition = Vector3.new(minePosition.X, 0.5, minePosition.Z)
        else
            return
        end
    end
    
    -- Create landmine
    local landmine = Instance.new("Part")
    landmine.Name = "Landmine"
    landmine.Size = Vector3.new(4, 0.5, 4)
    landmine.Position = minePosition
    landmine.Anchored = true
    landmine.CanCollide = false
    landmine.Material = Enum.Material.Metal
    landmine.Color = Color3.fromRGB(139, 69, 19)
    landmine.Transparency = 0
    landmine.Parent = workspace
    
    -- Add warning decal
    local decal = Instance.new("Decal")
    decal.Texture = "rbxasset://textures/face.png"
    decal.Face = Enum.NormalId.Top
    decal.Parent = landmine
    
    -- Add red light
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 0, 0)
    light.Brightness = 2
    light.Range = 10
    light.Parent = landmine
    
    -- Store mine data
    local mineData = {
        mine = landmine,
        owner = isPlayer and "player" or caster,
        isPlayerOwned = isPlayer
    }
    table.insert(activeLandmines, mineData)
    
    -- Make mine nearly invisible after 2 seconds
    wait(2)
    if landmine.Parent then
        local tween = TweenService:Create(landmine, TweenInfo.new(0.5), {
            Transparency = 0.8
        })
        tween:Play()
        
        if light then
            light.Brightness = 0.5
        end
    end
    
    -- Check for triggers
    local triggerConnection
    triggerConnection = RunService.Heartbeat:Connect(function()
        if not landmine.Parent then
            triggerConnection:Disconnect()
            return
        end
        
        -- Check if player steps on it (if fake player owns it)
        if not isPlayer then
            if character and character:FindFirstChild("HumanoidRootPart") then
                local playerRoot = character.HumanoidRootPart
                local distance = (playerRoot.Position - landmine.Position).Magnitude
                
                if distance <= 3 then
                    -- Explode!
                    local explosion = Instance.new("Explosion")
                    explosion.Position = landmine.Position
                    explosion.BlastRadius = 8
                    explosion.BlastPressure = 0
                    explosion.Parent = workspace
                    
                    -- Apply force upward
                    local explosionDirection = Vector3.new(0, 1, 0)
                    applyForce(character, explosionDirection, 9)
                    
                    -- Remove mine
                    triggerConnection:Disconnect()
                    landmine:Destroy()
                    
                    -- Remove from active mines
                    for i, data in ipairs(activeLandmines) do
                        if data.mine == landmine then
                            table.remove(activeLandmines, i)
                            break
                        end
                    end
                end
            end
        end
        
        -- Check if fake players step on it (if player owns it)
        if isPlayer then
            for _, fakePlayer in ipairs(fakePlayersList) do
                if fakePlayer.character and fakePlayer.character:FindFirstChild("HumanoidRootPart") then
                    local fakeRoot = fakePlayer.character.HumanoidRootPart
                    local distance = (fakeRoot.Position - landmine.Position).Magnitude
                    
                    if distance <= 3 then
                        -- Explode!
                        local explosion = Instance.new("Explosion")
                        explosion.Position = landmine.Position
                        explosion.BlastRadius = 8
                        explosion.BlastPressure = 0
                        explosion.Parent = workspace
                        
                        -- Apply force upward
                        local explosionDirection = Vector3.new(0, 1, 0)
                        applyForce(fakePlayer.character, explosionDirection, 9)
                        
                        -- Remove mine
                        triggerConnection:Disconnect()
                        landmine:Destroy()
                        
                        -- Remove from active mines
                        for i, data in ipairs(activeLandmines) do
                            if data.mine == landmine then
                                table.remove(activeLandmines, i)
                                break
                            end
                        end
                        
                        break
                    end
                end
            end
        end
    end)
    
    -- Auto-destroy after 30 seconds
    spawn(function()
        wait(30)
        if triggerConnection then
            triggerConnection:Disconnect()
        end
        if landmine.Parent then
            landmine:Destroy()
        end
        -- Remove from active mines
        for i, data in ipairs(activeLandmines) do
            if data.mine == landmine then
                table.remove(activeLandmines, i)
                break
            end
        end
    end)
end

-- TimeStop ability (God Glove)
local function activateTimeStopAbility()
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    isTimeStopActive = true
    
    -- Create grey screen effect
    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "TimeStopEffect"
    colorCorrection.Saturation = -1
    colorCorrection.TintColor = Color3.fromRGB(150, 150, 150)
    colorCorrection.Parent = game.Lighting
    
    -- Create time stop visual effect
    local timeStopSound = Instance.new("Sound")
    timeStopSound.SoundId = "rbxassetid://5153845714"
    timeStopSound.Volume = 0.7
    timeStopSound.Parent = workspace
    timeStopSound:Play()
    Debris:AddItem(timeStopSound, 3)
    
    -- Create visual indicator
    local timeStopLabel = Instance.new("TextLabel")
    timeStopLabel.Size = UDim2.new(0, 400, 0, 80)
    timeStopLabel.Position = UDim2.new(0.5, -200, 0.1, 0)
    timeStopLabel.BackgroundTransparency = 1
    timeStopLabel.Text = "TIME STOPPED"
    timeStopLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    timeStopLabel.TextScaled = true
    timeStopLabel.Font = Enum.Font.GothamBold
    timeStopLabel.TextStrokeTransparency = 0
    timeStopLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    timeStopLabel.Parent = screenGui
    
    -- Freeze all fake players
    local frozenData = {}
    for _, fakePlayer in ipairs(fakePlayersList) do
        if fakePlayer.character and fakePlayer.humanoid and fakePlayer.rootPart then
            -- Store original walkspeed
            local originalSpeed = fakePlayer.humanoid.WalkSpeed
            table.insert(frozenData, {
                fakePlayer = fakePlayer,
                originalSpeed = originalSpeed
            })
            
            -- Freeze
            fakePlayer.humanoid.WalkSpeed = 0
            fakePlayer.humanoid.JumpPower = 0
            
            -- Visual freeze effect
            local freezeEffect = Instance.new("Part")
            freezeEffect.Name = "FreezeEffect"
            freezeEffect.Size = Vector3.new(4, 6, 4)
            freezeEffect.Position = fakePlayer.rootPart.Position
            freezeEffect.Anchored = true
            freezeEffect.CanCollide = false
            freezeEffect.Material = Enum.Material.Ice
            freezeEffect.Color = Color3.fromRGB(150, 200, 255)
            freezeEffect.Transparency = 0.5
            freezeEffect.Parent = fakePlayer.character
            
            -- Keep freeze effect attached
            local freezeConnection
            freezeConnection = RunService.Heartbeat:Connect(function()
                if freezeEffect.Parent and fakePlayer.rootPart.Parent then
                    freezeEffect.Position = fakePlayer.rootPart.Position
                else
                    if freezeConnection then
                        freezeConnection:Disconnect()
                    end
                end
            end)
            
            -- Store connection for cleanup
            fakePlayer.freezeConnection = freezeConnection
            fakePlayer.freezeEffect = freezeEffect
        end
    end
    
    -- Countdown timer
    for i = 10, 1, -1 do
        wait(1)
        timeStopLabel.Text = "TIME STOPPED - " .. i
    end
    
    -- Restore everything
    wait(1)
    isTimeStopActive = false
    
    -- Remove grey screen
    if colorCorrection.Parent then
        colorCorrection:Destroy()
    end
    
    -- Unfreeze all fake players
    for _, data in ipairs(frozenData) do
        local fakePlayer = data.fakePlayer
        if fakePlayer.humanoid then
            fakePlayer.humanoid.WalkSpeed = data.originalSpeed
            fakePlayer.humanoid.JumpPower = 50
        end
        
        if fakePlayer.freezeEffect and fakePlayer.freezeEffect.Parent then
            fakePlayer.freezeEffect:Destroy()
        end
        
        if fakePlayer.freezeConnection then
            fakePlayer.freezeConnection:Disconnect()
        end
    end
    
    timeStopLabel.Text = "TIME RESUMED"
    wait(1)
    timeStopLabel:Destroy()
end

-- Ability activation
abilityButton.MouseButton1Click:Connect(function()
    local currentTime = tick()
    local gloveData = GLOVE_DATA[currentGlove]
    
    if gloveData.AbilityType == "None" then
        return
    end
    
    if currentTime - lastAbilityTime < gloveData.AbilityCooldown then
        return
    end
    
    lastAbilityTime = currentTime
    
    if gloveData.Ability == "Siphon" then
        activateSiphonAbility(nil, true)
    elseif gloveData.Ability == "Train" then
        activateTrainAbility(nil, true)
    elseif gloveData.Ability == "Counter" then
        activateCounterAbility(nil, true)
    elseif gloveData.Ability == "TimeStop" then
        activateTimeStopAbility()
    elseif gloveData.Ability == "LandMine" then
        activateLandMineAbility(nil, true)
    elseif gloveData.Ability == "Engineer" then
        activateEngineerTurret(nil, true)
    elseif gloveData.Ability == "AirBomb" then
        activateAirBombAbility(nil, true)
    end
    
    -- Update button text with cooldown
    local cooldownLeft = gloveData.AbilityCooldown
    abilityButton.Text = tostring(cooldownLeft)
    
    for i = cooldownLeft - 1, 0, -1 do
        wait(1)
        abilityButton.Text = tostring(i)
    end
    
    abilityButton.Text = "ABILITY"
end)

-- Second ability button activation
ability2Button.MouseButton1Click:Connect(function()
    local currentTime = tick()
    local gloveData = GLOVE_DATA[currentGlove]
    
    if currentGlove ~= "Engineer Glove" then
        return
    end
    
    if currentTime - lastAbility2Time < gloveData.AbilityCooldown2 then
        return
    end
    
    lastAbility2Time = currentTime
    activateEngineerRoombas(nil, true)
    
    -- Update button text with cooldown
    local cooldownLeft = gloveData.AbilityCooldown2
    ability2Button.Text = tostring(cooldownLeft)
    
    for i = cooldownLeft - 1, 0, -1 do
        wait(1)
        ability2Button.Text = tostring(i)
    end
    
    ability2Button.Text = "ABILITY 2"
end)

-- Create glove tool
local function createGloveTool()
    local tool = Instance.new("Tool")
    tool.Name = "Glove"
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1.5, 1.5, 1.5)
    handle.CanCollide = false
    handle.Parent = tool
    
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Brick
    mesh.Scale = Vector3.new(1.2, 1.2, 1.2)
    mesh.Parent = handle
    
    tool.Equipped:Connect(function()
        equippedGlove = tool
        updateGloveAppearance()
        
        local gloveData = GLOVE_DATA[currentGlove]
        
        -- Special handling for Song Glove
        if currentGlove == "Song Glove" then
            startRhythmGame()
            slapButton.Visible = false
            abilityButton.Visible = false
            adminPanelButton.Visible = false
            ability2Button.Visible = false
            return
        end
        
        if gloveData.AbilityType == "Ability" or gloveData.AbilityType == "Fusion" then
            if currentGlove == "Admin Glove" then
                adminPanelButton.Visible = true
                abilityButton.Visible = false
            else
                abilityButton.Visible = true
                adminPanelButton.Visible = false
            end
        else
            abilityButton.Visible = false
            adminPanelButton.Visible = false
        end
        
        -- Show second ability button for Engineer Glove
        if currentGlove == "Engineer Glove" then
            ability2Button.Visible = true
        else
            ability2Button.Visible = false
        end
        
        -- Always show slap button on mobile
        slapButton.Visible = true
        
        -- Show notification for passive gloves
        if gloveData.AbilityType == "Passive" and currentGlove ~= "Song Glove" then
            local passiveNotif = Instance.new("TextLabel")
            passiveNotif.Size = UDim2.new(0, 300, 0, 60)
            passiveNotif.Position = UDim2.new(0.5, -150, 0.15, 0)
            passiveNotif.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            passiveNotif.BorderSizePixel = 3
            passiveNotif.BorderColor3 = gloveData.Color
            passiveNotif.Text = "PASSIVE: " .. gloveData.Ability
            passiveNotif.TextColor3 = gloveData.Color
            passiveNotif.TextScaled = true
            passiveNotif.Font = Enum.Font.GothamBold
            passiveNotif.Parent = screenGui
            
            spawn(function()
                wait(3)
                passiveNotif:Destroy()
            end)
        end
    end)
    
    tool.Unequipped:Connect(function()
        equippedGlove = nil
        abilityButton.Visible = false
        ability2Button.Visible = false
        adminPanelButton.Visible = false
        slapButton.Visible = false
        
        -- Stop rhythm game if Song Glove is unequipped
        if currentGlove == "Song Glove" then
            stopRhythmGame()
        end
    end)
    
    tool.Activated:Connect(function()
        playerSlap()
    end)
    
    tool.Parent = player.Backpack
    return tool
end

function updateGloveAppearance()
    if equippedGlove and equippedGlove:FindFirstChild("Handle") then
        local gloveData = GLOVE_DATA[currentGlove]
        equippedGlove.Handle.Color = gloveData.Color
    end
end

-- Fake player AI
local function createFakePlayer(name, glove)
    local fakePlayer = {
        name = name,
        currentGlove = glove,
        lastSlapTime = 0,
        lastAbilityTime = 0,
        lastAdminCommandTime = 0,
        adminCommandsUsed = {},
        isAggro = false,
        isCounterActive = false,
        slapsTaken = 0,
        slapsGiven = 0,
        character = nil,
        humanoid = nil,
        rootPart = nil,
        freezeConnection = nil,
        freezeEffect = nil,
        aggroTarget = nil,
        aggroTurret = nil,
        aggroRoomba = nil
    }
    
    -- Create character
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = workspace
    
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 1, 1)
    head.Color = Color3.fromRGB(255, 204, 153)
    head.TopSurface = Enum.SurfaceType.Smooth
    head.BottomSurface = Enum.SurfaceType.Smooth
    head.Parent = model
    
    local face = Instance.new("Decal")
    face.Texture = "rbxasset://textures/face.png"
    face.Parent = head
    
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Color = Color3.fromRGB(0, 0, 255)
    torso.TopSurface = Enum.SurfaceType.Smooth
    torso.BottomSurface = Enum.SurfaceType.Smooth
    torso.Parent = model
    
    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.Color = Color3.fromRGB(255, 204, 153)
    leftArm.TopSurface = Enum.SurfaceType.Smooth
    leftArm.BottomSurface = Enum.SurfaceType.Smooth
    leftArm.Parent = model
    
    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Color = Color3.fromRGB(255, 204, 153)
    rightArm.TopSurface = Enum.SurfaceType.Smooth
    rightArm.BottomSurface = Enum.SurfaceType.Smooth
    rightArm.Parent = model
    
    local leftLeg = Instance.new("Part")
    leftLeg.Name = "Left Leg"
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.Color = Color3.fromRGB(0, 255, 0)
    leftLeg.TopSurface = Enum.SurfaceType.Smooth
    leftLeg.BottomSurface = Enum.SurfaceType.Smooth
    leftLeg.Parent = model
    
    local rightLeg = Instance.new("Part")
    rightLeg.Name = "Right Leg"
    rightLeg.Size = Vector3.new(1, 2, 1)
    rightLeg.Color = Color3.fromRGB(0, 255, 0)
    rightLeg.TopSurface = Enum.SurfaceType.Smooth
    rightLeg.BottomSurface = Enum.SurfaceType.Smooth
    rightLeg.Parent = model
    
    local humanoidRootPart = Instance.new("Part")
    humanoidRootPart.Name = "HumanoidRootPart"
    humanoidRootPart.Size = Vector3.new(2, 2, 1)
    humanoidRootPart.Transparency = 1
    humanoidRootPart.Parent = model
    
    -- Position parts
    local spawnPos = Vector3.new(
        math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2),
        10,
        math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2)
    )
    
    humanoidRootPart.Position = spawnPos
    torso.Position = spawnPos
    head.Position = spawnPos + Vector3.new(0, 1.5, 0)
    leftArm.Position = spawnPos + Vector3.new(-1.5, 0, 0)
    rightArm.Position = spawnPos + Vector3.new(1.5, 0, 0)
    leftLeg.Position = spawnPos + Vector3.new(-0.5, -2, 0)
    rightLeg.Position = spawnPos + Vector3.new(0.5, -2, 0)
    
    -- Create welds
    local function weld(part0, part1, c0)
        local weld = Instance.new("Weld")
        weld.Part0 = part0
        weld.Part1 = part1
        weld.C0 = c0
        weld.Parent = part0
        return weld
    end
    
    weld(torso, humanoidRootPart, CFrame.new())
    weld(torso, head, CFrame.new(0, 1.5, 0))
    weld(torso, leftArm, CFrame.new(-1.5, 0, 0))
    weld(torso, rightArm, CFrame.new(1.5, 0, 0))
    weld(torso, leftLeg, CFrame.new(-0.5, -2, 0))
    weld(torso, rightLeg, CFrame.new(0.5, -2, 0))
    
    -- Create humanoid
    local hum = Instance.new("Humanoid")
    hum.Parent = model
    
    -- Create glove visual
    local gloveModel = Instance.new("Part")
    gloveModel.Name = "GloveVisual"
    gloveModel.Size = Vector3.new(1, 1, 1)
    gloveModel.Color = GLOVE_DATA[glove].Color
    gloveModel.Material = Enum.Material.Neon
    gloveModel.Parent = model
    
    weld(rightArm, gloveModel, CFrame.new(0, -1, 0))
    
    fakePlayer.character = model
    fakePlayer.humanoid = hum
    fakePlayer.rootPart = humanoidRootPart
    
    return fakePlayer
end

-- Fake player AI behavior
local function updateFakePlayerAI(fakePlayer)
    if not fakePlayer.character or not fakePlayer.rootPart or not fakePlayer.humanoid then
        return
    end
    
    -- Don't move if time is stopped
    if isTimeStopActive then
        return
    end
    
    if not character or not character:FindFirstChild("HumanoidRootPart") or not humanoid or humanoid.Health <= 0 then
        return
    end
    
    local fakeRoot = fakePlayer.rootPart
    local playerRoot = character.HumanoidRootPart
    local distance = (playerRoot.Position - fakeRoot.Position).Magnitude
    
    -- Movement logic
    if fakePlayer.isAggro then
        -- Determine target based on aggro priority: turret > roomba > player
        local targetPosition
        local targetValid = false
        
        if fakePlayer.aggroTarget == "turret" and fakePlayer.aggroTurret then
            if fakePlayer.aggroTurret.head and fakePlayer.aggroTurret.head.Parent and fakePlayer.aggroTurret.health > 0 then
                targetPosition = fakePlayer.aggroTurret.head.Position
                targetValid = true
            else
                fakePlayer.aggroTarget = "roomba"
            end
        end
        
        if fakePlayer.aggroTarget == "roomba" and fakePlayer.aggroRoomba then
            if fakePlayer.aggroRoomba.part and fakePlayer.aggroRoomba.part.Parent and fakePlayer.aggroRoomba.health > 0 then
                targetPosition = fakePlayer.aggroRoomba.part.Position
                targetValid = true
            else
                fakePlayer.aggroTarget = nil
            end
        end
        
        if not targetValid then
            targetPosition = playerRoot.Position
        end
        
        -- Chase target
        fakePlayer.humanoid:MoveTo(targetPosition)
        
        -- Calculate distance to current target
        local distanceToTarget = (targetPosition - fakeRoot.Position).Magnitude
        
        -- Slap if in range
        if distanceToTarget <= CONFIG.SLAP_DISTANCE then
            local currentTime = tick()
            local gloveData = GLOVE_DATA[fakePlayer.currentGlove]
            
            if currentTime - fakePlayer.lastSlapTime >= gloveData.SlapCooldown then
                fakePlayer.lastSlapTime = currentTime
                
                -- Check if slapping player with counter active
                if not targetValid and isCounterActive then
                    -- Trigger counter punishment on fake player
                    triggerCounterPunishment(fakePlayer.character)
                else
                    -- Perform slap
                    local slapPosition = fakeRoot.Position + (targetPosition - fakeRoot.Position).Unit * 3
                    createSlapEffect(slapPosition, gloveData.Color)
                    
                    -- Check if slapping turret or roomba
                    if fakePlayer.aggroTarget == "turret" and fakePlayer.aggroTurret then
                        fakePlayer.aggroTurret.health = fakePlayer.aggroTurret.health - 5
                        if fakePlayer.aggroTurret.health <= 0 then
                            fakePlayer.aggroTarget = "roomba"
                        end
                    elseif fakePlayer.aggroTarget == "roomba" and fakePlayer.aggroRoomba then
                        fakePlayer.aggroRoomba.health = fakePlayer.aggroRoomba.health - 5
                        if fakePlayer.aggroRoomba.health <= 0 then
                            fakePlayer.aggroTarget = nil
                        end
                    else
                        -- Slapping player
                        local slapDirection
                        
                        -- Check if using RNG Glove (random direction)
                        if fakePlayer.currentGlove == "RNG Glove" then
                            local randomAngle = math.random() * math.pi * 2
                            local randomElevation = (math.random() - 0.5) * math.pi * 0.5
                            slapDirection = Vector3.new(
                                math.cos(randomAngle) * math.cos(randomElevation),
                                math.sin(randomElevation),
                                math.sin(randomAngle) * math.cos(randomElevation)
                            ).Unit
                        else
                            slapDirection = (playerRoot.Position - fakeRoot.Position).Unit
                        end
                        
                        applyForce(character, slapDirection, gloveData.PushPower)
                        
                        -- Track slaps for God Glove auto-ability
                        playerSlapCount = playerSlapCount + 1
                        fakePlayer.slapsGiven = fakePlayer.slapsGiven + 1
                    end
                end
            end
        end
        
        -- Use abilities based on glove type
        local currentTime = tick()
        local gloveData = GLOVE_DATA[fakePlayer.currentGlove]
        
        if currentTime - fakePlayer.lastAbilityTime >= gloveData.AbilityCooldown then
            if fakePlayer.currentGlove == "Siphon Glove" then
                -- Activate siphon when player is within 20 studs
                if distance <= 20 then
                    fakePlayer.lastAbilityTime = currentTime
                    activateSiphonAbility(fakePlayer, false)
                end
            elseif fakePlayer.currentGlove == "Train Glove" then
                -- Activate train when player is relatively still
                if humanoid.MoveDirection.Magnitude < 0.1 then
                    fakePlayer.lastAbilityTime = currentTime
                    activateTrainAbility(fakePlayer, false)
                end
            elseif fakePlayer.currentGlove == "Counter Glove" then
                -- Activate counter when player is within 5 studs
                if distance <= 5 then
                    fakePlayer.lastAbilityTime = currentTime
                    activateCounterAbility(fakePlayer, false)
                end
            elseif fakePlayer.currentGlove == "God Glove" then
                -- Activate time stop after being slapped 10 times
                if fakePlayer.slapsTaken >= 10 then
                    fakePlayer.lastAbilityTime = currentTime
                    fakePlayer.slapsTaken = 0
                    activateTimeStopAbility()
                end
            elseif fakePlayer.currentGlove == "LandMine Glove" then
                -- Randomly place landmines 30-50 studs away from player
                if math.random(1, 100) <= 30 then -- 30% chance to place mine
                    fakePlayer.lastAbilityTime = currentTime
                    activateLandMineAbility(fakePlayer, false)
                end
            elseif fakePlayer.currentGlove == "Engineer Glove" then
                -- Place turret after being slapped (1st time, then every 5 slaps)
                if fakePlayer.slapsTaken == 1 or (fakePlayer.slapsTaken > 1 and fakePlayer.slapsTaken % 5 == 0) then
                    fakePlayer.lastAbilityTime = currentTime
                    activateEngineerTurret(fakePlayer, false)
                end
                
                -- Place roombas after being slapped 3 times
                if fakePlayer.slapsGiven >= 3 then
                    fakePlayer.slapsGiven = 0
                    activateEngineerRoombas(fakePlayer, false)
                end
            elseif fakePlayer.currentGlove == "AirBomb Glove" then
                -- Activate when player is 75-100 studs away
                if distance >= 75 and distance <= 100 then
                    fakePlayer.lastAbilityTime = currentTime
                    activateAirBombAbility(fakePlayer, false)
                end
            elseif fakePlayer.currentGlove == "Admin Glove" then
                -- Admin Glove AI: Use random commands strategically
                if currentTime - fakePlayer.lastAdminCommandTime >= 20 then
                    fakePlayer.lastAdminCommandTime = currentTime
                    
                    -- Choose random command based on situation
                    local availableCommands = {}
                    
                    -- Speed/JumpPower when far from player
                    if distance > 30 then
                        table.insert(availableCommands, "speed")
                        table.insert(availableCommands, "jumppower")
                    end
                    
                    -- Offensive commands when close
                    if distance < 50 then
                        table.insert(availableCommands, "explode")
                        table.insert(availableCommands, "anvil")
                        table.insert(availableCommands, "ragdoll")
                    end
                    
                    -- Teleport commands
                    table.insert(availableCommands, "goto")
                    
                    -- Train command
                    table.insert(availableCommands, "train")
                    
                    if #availableCommands > 0 then
                        local chosenCommand = availableCommands[math.random(1, #availableCommands)]
                        
                        if chosenCommand == "speed" then
                            if fakePlayer.humanoid then
                                local speedValue = math.random(20, 40)
                                fakePlayer.humanoid.WalkSpeed = speedValue
                                sendFakePlayerChat(fakePlayer.name, "/Speed " .. speedValue)
                            end
                        elseif chosenCommand == "jumppower" then
                            if fakePlayer.humanoid then
                                local jumpValue = math.random(60, 100)
                                fakePlayer.humanoid.JumpPower = jumpValue
                                sendFakePlayerChat(fakePlayer.name, "/JumpPower " .. jumpValue)
                            end
                        elseif chosenCommand == "explode" then
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                sendFakePlayerChat(fakePlayer.name, "/Explode " .. player.Name)
                                
                                spawn(function()
                                    wait(1)
                                    local explosion = Instance.new("Explosion")
                                    explosion.Position = character.HumanoidRootPart.Position
                                    explosion.BlastRadius = 10
                                    explosion.BlastPressure = 0
                                    explosion.Parent = workspace
                                    
                                    local randomAngle = math.random() * math.pi * 2
                                    local randomElevation = (math.random() - 0.5) * math.pi * 0.5
                                    local direction = Vector3.new(
                                        math.cos(randomAngle) * math.cos(randomElevation),
                                        math.sin(randomElevation),
                                        math.sin(randomAngle) * math.cos(randomElevation)
                                    ).Unit
                                    
                                    applyForce(character, direction, 12)
                                end)
                            end
                        elseif chosenCommand == "anvil" then
                            if character and character:FindFirstChild("HumanoidRootPart") then
                                sendFakePlayerChat(fakePlayer.name, "/Anvil " .. player.Name)
                                
                                spawn(function()
                                    wait(1)
                                    local playerRoot = character.HumanoidRootPart
                                    local anvilSpawnPos = playerRoot.Position + Vector3.new(0, 20, 0)
                                    
                                    local anvil = Instance.new("Part")
                                    anvil.Name = "Anvil"
                                    anvil.Size = Vector3.new(3, 2, 3)
                                    anvil.Position = anvilSpawnPos
                                    anvil.Anchored = false
                                    anvil.Material = Enum.Material.Metal
                                    anvil.Color = Color3.fromRGB(80, 80, 80)
                                    anvil.Parent = workspace
                                    
                                    local bv = Instance.new("BodyVelocity")
                                    bv.MaxForce = Vector3.new(0, 4e4, 0)
                                    bv.Velocity = Vector3.new(0, -100, 0)
                                    bv.Parent = anvil
                                    
                                    local hitConn
                                    hitConn = anvil.Touched:Connect(function(hit)
                                        if hit.Parent == character then
                                            applyForce(character, Vector3.new(0, -1, 0), 13)
                                            hitConn:Disconnect()
                                            Debris:AddItem(anvil, 1)
                                        end
                                    end)
                                    
                                    Debris:AddItem(anvil, 3)
                                end)
                            end
                        elseif chosenCommand == "ragdoll" then
                            if character and humanoid and character:FindFirstChild("HumanoidRootPart") then
                                sendFakePlayerChat(fakePlayer.name, "/Ragdoll " .. player.Name)
                                
                                spawn(function()
                                    wait(0.5)
                                    humanoid.PlatformStand = true
                                    
                                    local randomDir = Vector3.new(
                                        math.random(-1, 1),
                                        math.random(0, 1),
                                        math.random(-1, 1)
                                    ).Unit
                                    
                                    applyForce(character, randomDir, 15)
                                    
                                    spawn(function()
                                        wait(3)
                                        if humanoid then
                                            humanoid.PlatformStand = false
                                        end
                                    end)
                                end)
                            end
                        elseif chosenCommand == "goto" then
                            if character and rootPart and fakePlayer.rootPart then
                                sendFakePlayerChat(fakePlayer.name, "/Goto " .. player.Name)
                                
                                spawn(function()
                                    wait(0.3)
                                    fakePlayer.rootPart.CFrame = rootPart.CFrame + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
                                end)
                            end
                        elseif chosenCommand == "train" then
                            sendFakePlayerChat(fakePlayer.name, "/Train")
                            activateTrainAbility(fakePlayer, false)
                        end
                    end
                end
            end
        end
    else
        -- Wander around when not aggro
        if (fakeRoot.Position - fakePlayer.wanderTarget).Magnitude < 5 or not fakePlayer.wanderTarget then
            fakePlayer.wanderTarget = Vector3.new(
                math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2),
                fakeRoot.Position.Y,
                math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2)
            )
        end
        
        fakePlayer.humanoid:MoveTo(fakePlayer.wanderTarget)
    end
end

-- Initialize fake players
local function initializeFakePlayers()
    local gloveNames = {}
    for name, _ in pairs(GLOVE_DATA) do
        table.insert(gloveNames, name)
    end
    
    local fakePlayerNames = {"Bot_Alpha", "Bot_Beta", "Bot_Gamma", "Bot_Delta", "Bot_Epsilon"}
    
    for i = 1, CONFIG.MAX_FAKE_PLAYERS do
        local randomGlove = gloveNames[math.random(1, #gloveNames)]
        local fakePlayer = createFakePlayer(fakePlayerNames[i], randomGlove)
        fakePlayer.wanderTarget = fakePlayer.rootPart.Position
        table.insert(fakePlayersList, fakePlayer)
    end
end

-- Main game loop
local function gameLoop()
    RunService.Heartbeat:Connect(function()
        for _, fakePlayer in ipairs(fakePlayersList) do
            updateFakePlayerAI(fakePlayer)
        end
    end)
end

-- Player death handling
local function onPlayerDeath()
    humanoid.Died:Connect(function()
        wait(CONFIG.RESPAWN_TIME)
        
        if character and character.Parent then
            character:BreakJoints()
        end
        
        player:LoadCharacter()
    end)
end

-- Character setup
local function setupCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    
    createGloveTool()
    onPlayerDeath()
end

-- Handle respawns
player.CharacterAdded:Connect(function(char)
    wait(0.5)
    setupCharacter()
end)

-- Input handling for mobile/keyboard
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        if equippedGlove then
            playerSlap()
        end
    elseif input.KeyCode == Enum.KeyCode.Q then
        local gloveData = GLOVE_DATA[currentGlove]
        if gloveData.AbilityType ~= "None" then
            abilityButton.MouseButton1Click:Fire()
        end
    end
end)

-- Create arena
local function createArena()
    local arena = Instance.new("Part")
    arena.Name = "Arena"
    arena.Size = Vector3.new(CONFIG.ARENA_SIZE, 1, CONFIG.ARENA_SIZE)
    arena.Position = Vector3.new(0, 0, 0)
    arena.Anchored = true
    arena.Material = Enum.Material.Concrete
    arena.Color = Color3.fromRGB(150, 150, 150)
    arena.Parent = workspace
    
    -- Create spawn platform
    local spawn = Instance.new("SpawnLocation")
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.Position = Vector3.new(0, 1, 0)
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Transparency = 0.5
    spawn.BrickColor = BrickColor.new("Bright green")
    spawn.Parent = workspace
    
    -- Walls removed for void slapping gameplay!
end

-- Health check for fake players
local function checkFakePlayerHealth()
    RunService.Heartbeat:Connect(function()
        for i, fakePlayer in ipairs(fakePlayersList) do
            if fakePlayer.humanoid and fakePlayer.humanoid.Health <= 0 then
                if fakePlayer.character then
                    fakePlayer.character:Destroy()
                end
                
                -- Remove from aggro list if present
                for j, aggroPlayer in ipairs(aggroedFakePlayers) do
                    if aggroPlayer == fakePlayer then
                        table.remove(aggroedFakePlayers, j)
                        break
                    end
                end
                
                -- Respawn fake player with random glove
                spawn(function()
                    wait(CONFIG.RESPAWN_TIME)
                    
                    -- Get random glove
                    local gloveNames = {}
                    for name, _ in pairs(GLOVE_DATA) do
                        table.insert(gloveNames, name)
                    end
                    local randomGlove = gloveNames[math.random(1, #gloveNames)]
                    
                    local newFakePlayer = createFakePlayer(fakePlayer.name, randomGlove)
                    newFakePlayer.wanderTarget = newFakePlayer.rootPart.Position
                    fakePlayersList[i] = newFakePlayer
                    
                    -- Add name tag to new fake player
                    createNameTag(newFakePlayer)
                end)
            end
        end
    end)
end

-- Death zone (kills players who fall too far)
local function createDeathZone()
    local deathZone = Instance.new("Part")
    deathZone.Name = "DeathZone"
    deathZone.Size = Vector3.new(CONFIG.ARENA_SIZE * 2, 5, CONFIG.ARENA_SIZE * 2)
    deathZone.Position = Vector3.new(0, -50, 0)
    deathZone.Anchored = true
    deathZone.CanCollide = false
    deathZone.Transparency = 1
    deathZone.Parent = workspace
    
    deathZone.Touched:Connect(function(hit)
        if hit.Parent:FindFirstChild("Humanoid") then
            hit.Parent.Humanoid.Health = 0
        end
    end)
end

-- Player statistics GUI
local function createStatsGUI()
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(0, 250, 0, 150)
    statsFrame.Position = UDim2.new(1, -270, 0, 20)
    statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    statsFrame.BorderSizePixel = 2
    statsFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    statsFrame.BackgroundTransparency = 0.3
    statsFrame.Parent = screenGui
    
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Size = UDim2.new(1, 0, 0, 30)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "CURRENT GLOVE"
    statsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsTitle.TextScaled = true
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.Parent = statsFrame
    
    local gloveNameLabel = Instance.new("TextLabel")
    gloveNameLabel.Name = "GloveName"
    gloveNameLabel.Size = UDim2.new(1, -10, 0, 25)
    gloveNameLabel.Position = UDim2.new(0, 5, 0, 35)
    gloveNameLabel.BackgroundTransparency = 1
    gloveNameLabel.Text = currentGlove
    gloveNameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    gloveNameLabel.TextSize = 18
    gloveNameLabel.Font = Enum.Font.GothamBold
    gloveNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    gloveNameLabel.Parent = statsFrame
    
    local statsInfoLabel = Instance.new("TextLabel")
    statsInfoLabel.Name = "StatsInfo"
    statsInfoLabel.Size = UDim2.new(1, -10, 1, -70)
    statsInfoLabel.Position = UDim2.new(0, 5, 0, 65)
    statsInfoLabel.BackgroundTransparency = 1
    statsInfoLabel.Text = ""
    statsInfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statsInfoLabel.TextSize = 14
    statsInfoLabel.Font = Enum.Font.Gotham
    statsInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
    statsInfoLabel.Parent = statsFrame
    
    -- Update stats display
    local function updateStatsDisplay()
        gloveNameLabel.Text = currentGlove
        local gloveData = GLOVE_DATA[currentGlove]
        local statsText = string.format(
            "Push Power: %d\nSlap Cooldown: %.1fs\nType: %s\nAbility CD: %ds",
            gloveData.PushPower,
            gloveData.SlapCooldown,
            gloveData.AbilityType,
            gloveData.AbilityCooldown
        )
        statsInfoLabel.Text = statsText
    end
    
    updateStatsDisplay()
    
    -- Watch for glove changes
    RunService.Heartbeat:Connect(function()
        if gloveNameLabel.Text ~= currentGlove then
            updateStatsDisplay()
        end
    end)
end

-- Fake player name tags
local function createNameTag(fakePlayer)
    if not fakePlayer.character or not fakePlayer.character:FindFirstChild("Head") then
        return
    end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "NameTag"
    billboardGui.Size = UDim2.new(0, 100, 0, 40)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = fakePlayer.character.Head
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = fakePlayer.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Parent = billboardGui
    
    local gloveLabel = Instance.new("TextLabel")
    gloveLabel.Size = UDim2.new(1, 0, 0.5, 0)
    gloveLabel.Position = UDim2.new(0, 0, 0.5, 0)
    gloveLabel.BackgroundTransparency = 1
    gloveLabel.Text = fakePlayer.currentGlove
    gloveLabel.TextColor3 = GLOVE_DATA[fakePlayer.currentGlove].Color
    gloveLabel.TextScaled = true
    gloveLabel.Font = Enum.Font.Gotham
    gloveLabel.TextStrokeTransparency = 0.5
    gloveLabel.Parent = billboardGui
end

-- Enhanced visual effects for abilities
local function createAbilityNotification(abilityName)
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(0.5, -150, 0, -80)
    notification.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    notification.BorderSizePixel = 3
    notification.BorderColor3 = Color3.fromRGB(255, 255, 0)
    notification.Parent = screenGui
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = abilityName .. " ACTIVATED!"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = notification
    
    local tween = TweenService:Create(notification, TweenInfo.new(0.3), {
        Position = UDim2.new(0.5, -150, 0, 20)
    })
    tween:Play()
    
    wait(2)
    
    local tween2 = TweenService:Create(notification, TweenInfo.new(0.3), {
        Position = UDim2.new(0.5, -150, 0, -80),
        BackgroundTransparency = 1
    })
    tween2:Play()
    
    wait(0.3)
    notification:Destroy()
end

-- Add sound effects
local function createSlapSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://537371462"
    sound.Volume = 0.5
    sound.Parent = workspace
    return sound
end

local slapSound = createSlapSound()

-- Modify playerSlap to include sound
local originalPlayerSlap = playerSlap
playerSlap = function()
    originalPlayerSlap()
    if slapSound then
        slapSound:Play()
    end
end

-- Cooldown indicator for slap
local function createCooldownIndicator()
    local cooldownBar = Instance.new("Frame")
    cooldownBar.Name = "CooldownBar"
    cooldownBar.Size = UDim2.new(0, 200, 0, 20)
    cooldownBar.Position = UDim2.new(0.5, -100, 1, -100)
    cooldownBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    cooldownBar.BorderSizePixel = 2
    cooldownBar.BorderColor3 = Color3.fromRGB(255, 255, 255)
    cooldownBar.Parent = screenGui
    
    local cooldownFill = Instance.new("Frame")
    cooldownFill.Name = "Fill"
    cooldownFill.Size = UDim2.new(1, 0, 1, 0)
    cooldownFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    cooldownFill.BorderSizePixel = 0
    cooldownFill.Parent = cooldownBar
    
    local cooldownText = Instance.new("TextLabel")
    cooldownText.Size = UDim2.new(1, 0, 1, 0)
    cooldownText.BackgroundTransparency = 1
    cooldownText.Text = "READY"
    cooldownText.TextColor3 = Color3.fromRGB(255, 255, 255)
    cooldownText.TextScaled = true
    cooldownText.Font = Enum.Font.GothamBold
    cooldownText.TextStrokeTransparency = 0.5
    cooldownText.ZIndex = 2
    cooldownText.Parent = cooldownBar
    
    RunService.Heartbeat:Connect(function()
        local gloveData = GLOVE_DATA[currentGlove]
        local currentTime = tick()
        local timeSinceSlap = currentTime - lastSlapTime
        
        if timeSinceSlap >= gloveData.SlapCooldown then
            cooldownFill.Size = UDim2.new(1, 0, 1, 0)
            cooldownFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            cooldownText.Text = "READY"
        else
            local progress = timeSinceSlap / gloveData.SlapCooldown
            cooldownFill.Size = UDim2.new(progress, 0, 1, 0)
            cooldownFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            local remaining = gloveData.SlapCooldown - timeSinceSlap
            cooldownText.Text = string.format("%.1f", remaining)
        end
    end)
end

-- Initialize everything
local function initialize()
    print("Initializing Slap Battles...")
    
    createArena()
    createDeathZone()
    createStatsGUI()
    createCooldownIndicator()
    setupCharacter()
    initializeFakePlayers()
    
    -- Add name tags to fake players
    for _, fakePlayer in ipairs(fakePlayersList) do
        createNameTag(fakePlayer)
    end
    
    checkFakePlayerHealth()
    gameLoop()
    
    print("Slap Battles initialized! Press E to slap, Q for ability.")
    print("Click the GLOVES button to select your glove!")
end

-- Start the game
wait(1)
initialize()

-- Additional utility functions
local function getClosestFakePlayer()
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local playerRoot = character.HumanoidRootPart
    local closestPlayer = nil
    local closestDistance = math.huge
    
    for _, fakePlayer in ipairs(fakePlayersList) do
        if fakePlayer.character and fakePlayer.rootPart then
            local distance = (fakePlayer.rootPart.Position - playerRoot.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = fakePlayer
            end
        end
    end
    
    return closestPlayer, closestDistance
end

-- Debug commands (optional)
local function enableDebugMode()
    local debugLabel = Instance.new("TextLabel")
    debugLabel.Name = "DebugInfo"
    debugLabel.Size = UDim2.new(0, 300, 0, 200)
    debugLabel.Position = UDim2.new(0, 20, 1, -220)
    debugLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    debugLabel.BackgroundTransparency = 0.5
    debugLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    debugLabel.TextSize = 12
    debugLabel.Font = Enum.Font.Code
    debugLabel.TextXAlignment = Enum.TextXAlignment.Left
    debugLabel.TextYAlignment = Enum.TextYAlignment.Top
    debugLabel.Parent = screenGui
    
    RunService.Heartbeat:Connect(function()
        local closestFake, distance = getClosestFakePlayer()
        local aggroCount = #aggroedFakePlayers
        
        local debugText = string.format(
            "=== DEBUG INFO ===\nCurrent Glove: %s\nAggro Count: %d\nAlive Bots: %d\nClosest Bot: %s\nDistance: %.1f\nEquipped: %s",
            currentGlove,
            aggroCount,
            #fakePlayersList,
            closestFake and closestFake.name or "None",
            distance or 0,
            equippedGlove and "Yes" or "No"
        )
        
        debugLabel.Text = debugText
    end)
end

-- Uncomment to enable debug mode
-- enableDebugMode()

print("=== SLAP BATTLES LOADED ===")
print("Total lines: 1300+")
print("Features: AI Bots, Glove System, Abilities, Combat")
print("==============================")
