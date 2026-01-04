-- Illusion System Script (Client-Sided)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Stats
local maxHP = 100
local maxSP = 100
local currentHP = maxHP
local currentSP = maxSP
local hasTrauma = false

-- Active Illusions
local activeIllusions = {}
local illusionLoops = {}

-- Current Suit
local currentSuit = "Standard Suit"
local suits = {
    ["Standard Suit"] = {
        Crimson = 1,
        Blue = 1,
        Purple = 1.5,
        White = 2,
        Grey = 2
    },
    ["Musical Choir Suit"] = {
        Crimson = 0.4,
        Blue = 0.2,
        Purple = 0.6,
        White = 0.5,
        Grey = 0.8
    },
    ["Apostle's Blessing"] = {
        Crimson = 1.2,
        Blue = 0.3,
        Purple = 0.7,
        White = 0.4,
        Grey = 1.5
    },
    ["Shadow Resistant Armor"] = {
        Crimson = 0.6,
        Blue = 0.5,
        Purple = 0.9,
        White = 1.3,
        Grey = 0.7
    }
}

-- Damage Type Colors
local damageColors = {
    Crimson = Color3.fromRGB(220, 50, 50),
    Blue = Color3.fromRGB(50, 120, 220),
    Purple = Color3.fromRGB(200, 100, 255),
    Grey = Color3.fromRGB(150, 150, 150),
    White = Color3.new(1, 1, 1)
}

-- Damage Type Display Names
local damageTypeNames = {
    Crimson = "[RED]",
    Blue = "[BLUE]",
    Purple = "[PURPLE]",
    Grey = "[GREY]",
    White = "[WHITE]"
}

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IllusionSystem"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- HP Bar
local hpFrame = Instance.new("Frame")
hpFrame.Size = UDim2.new(0, 150, 0, 30)
hpFrame.Position = UDim2.new(1, -170, 0, 50)
hpFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
hpFrame.BorderSizePixel = 2
hpFrame.Parent = screenGui

local hpBar = Instance.new("Frame")
hpBar.Size = UDim2.new(1, 0, 1, 0)
hpBar.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
hpBar.BorderSizePixel = 0
hpBar.Parent = hpFrame

local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.BackgroundTransparency = 1
hpText.Text = "HP: 100/100"
hpText.TextColor3 = Color3.new(1, 1, 1)
hpText.Font = Enum.Font.GothamBold
hpText.TextSize = 16
hpText.Parent = hpFrame

-- SP Bar
local spFrame = Instance.new("Frame")
spFrame.Size = UDim2.new(0, 150, 0, 30)
spFrame.Position = UDim2.new(1, -170, 0, 90)
spFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
spFrame.BorderSizePixel = 2
spFrame.Parent = screenGui

local spBar = Instance.new("Frame")
spBar.Size = UDim2.new(1, 0, 1, 0)
spBar.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
spBar.BorderSizePixel = 0
spBar.Parent = spFrame

local spText = Instance.new("TextLabel")
spText.Size = UDim2.new(1, 0, 1, 0)
spText.BackgroundTransparency = 1
spText.Text = "SP: 100/100"
spText.TextColor3 = Color3.new(1, 1, 1)
spText.Font = Enum.Font.GothamBold
spText.TextSize = 16
spText.Parent = spFrame

-- Illusions Button
local illusionsBtn = Instance.new("TextButton")
illusionsBtn.Size = UDim2.new(0, 120, 0, 40)
illusionsBtn.Position = UDim2.new(0.5, -130, 0, 10)
illusionsBtn.Text = "ILLUSIONS"
illusionsBtn.Font = Enum.Font.GothamBold
illusionsBtn.TextSize = 18
illusionsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
illusionsBtn.TextColor3 = Color3.new(1, 1, 1)
illusionsBtn.Parent = screenGui

-- Suits Button
local suitsBtn = Instance.new("TextButton")
suitsBtn.Size = UDim2.new(0, 120, 0, 40)
suitsBtn.Position = UDim2.new(0.5, 10, 0, 10)
suitsBtn.Text = "SUITS"
suitsBtn.Font = Enum.Font.GothamBold
suitsBtn.TextSize = 18
suitsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
suitsBtn.TextColor3 = Color3.new(1, 1, 1)
suitsBtn.Parent = screenGui

-- Illusions GUI (Fixed size - 70% of screen height)
local illusionsGui = Instance.new("Frame")
illusionsGui.Size = UDim2.new(0, 400, 0.7, 0)
illusionsGui.Position = UDim2.new(0.5, -200, 0.15, 0)
illusionsGui.BackgroundColor3 = Color3.new(1, 1, 1)
illusionsGui.BackgroundTransparency = 0.1
illusionsGui.Visible = false
illusionsGui.Parent = screenGui

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 24
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Parent = illusionsGui

closeBtn.MouseButton1Click:Connect(function()
    illusionsGui.Visible = false
end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -60)
scrollFrame.Position = UDim2.new(0, 10, 0, 50)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.Parent = illusionsGui

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scrollFrame

illusionsBtn.MouseButton1Click:Connect(function()
    illusionsGui.Visible = not illusionsGui.Visible
    suitsGui.Visible = false
end)

-- Suits GUI
local suitsGui = Instance.new("Frame")
suitsGui.Size = UDim2.new(0, 400, 0.7, 0)
suitsGui.Position = UDim2.new(0.5, -200, 0.15, 0)
suitsGui.BackgroundColor3 = Color3.new(1, 1, 1)
suitsGui.BackgroundTransparency = 0.1
suitsGui.Visible = false
suitsGui.Parent = screenGui

-- Close Button for Suits GUI
local closeSuitsBtn = Instance.new("TextButton")
closeSuitsBtn.Size = UDim2.new(0, 40, 0, 40)
closeSuitsBtn.Position = UDim2.new(1, -45, 0, 5)
closeSuitsBtn.Text = "X"
closeSuitsBtn.Font = Enum.Font.GothamBold
closeSuitsBtn.TextSize = 24
closeSuitsBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeSuitsBtn.TextColor3 = Color3.new(1, 1, 1)
closeSuitsBtn.Parent = suitsGui

closeSuitsBtn.MouseButton1Click:Connect(function()
    suitsGui.Visible = false
end)

local suitsScrollFrame = Instance.new("ScrollingFrame")
suitsScrollFrame.Size = UDim2.new(1, -20, 1, -60)
suitsScrollFrame.Position = UDim2.new(0, 10, 0, 50)
suitsScrollFrame.BackgroundTransparency = 1
suitsScrollFrame.BorderSizePixel = 0
suitsScrollFrame.ScrollBarThickness = 8
suitsScrollFrame.Parent = suitsGui

local suitsListLayout = Instance.new("UIListLayout")
suitsListLayout.Padding = UDim.new(0, 10)
suitsListLayout.Parent = suitsScrollFrame

suitsBtn.MouseButton1Click:Connect(function()
    suitsGui.Visible = not suitsGui.Visible
    illusionsGui.Visible = false
end)

-- Danger Level Colors
local dangerColors = {
    AYIN = Color3.fromRGB(100, 255, 100),
    SAMECH = Color3.fromRGB(255, 255, 100),
    LAMED = Color3.fromRGB(255, 165, 0),
    SHIN = Color3.fromRGB(255, 50, 50),
    TZADEL = Color3.fromRGB(255, 105, 180)
}

-- Get Damage Label
local function getDamageLabel(amount)
    if amount == 0 then return "IMMUNE"
    elseif amount <= 0.5 then return "RESISTANT"
    elseif amount <= 1 then return "WEAK"
    elseif amount <= 10 then return "NORMAL"
    elseif amount <= 30 then return "VULNERABLE"
    elseif amount <= 75 then return "STRONG"
    else return "POWERFUL"
    end
end

-- Get Resistance Label
local function getResistanceLabel(resistance)
    if resistance == 0 then return "IMMUNE"
    elseif resistance <= 0.5 then return "RESISTANT"
    elseif resistance <= 1 then return "WEAK"
    elseif resistance <= 1.5 then return "NORMAL"
    elseif resistance <= 2 then return "VULNERABLE"
    else return "WEAK"
    end
end

-- Create 3D Damage Popup
local function createDamagePopup(damageType, amount)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    -- Create a part for the BillboardGui
    local part = Instance.new("Part")
    part.Size = Vector3.new(1, 1, 1)
    part.Transparency = 1
    part.CanCollide = false
    part.Anchored = true
    part.Position = hrp.Position + Vector3.new(math.random(-2, 2), 3, math.random(-2, 2))
    part.Parent = workspace
    
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(6, 0, 2, 0)
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    
    local damageLabel = Instance.new("TextLabel")
    damageLabel.Size = UDim2.new(1, 0, 1, 0)
    damageLabel.BackgroundTransparency = 1
    damageLabel.Text = string.format("%s %.1f %s", damageTypeNames[damageType], amount, getDamageLabel(amount))
    damageLabel.TextColor3 = damageColors[damageType]
    damageLabel.Font = Enum.Font.GothamBold
    damageLabel.TextSize = 24
    damageLabel.TextStrokeTransparency = 0.5
    damageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    damageLabel.Parent = billboard
    
    -- Animate upward and fade
    local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local goal = {Position = part.Position + Vector3.new(0, 5, 0)}
    local tween = TweenService:Create(part, tweenInfo, goal)
    tween:Play()
    
    local fadeTween = TweenService:Create(damageLabel, tweenInfo, {TextTransparency = 1, TextStrokeTransparency = 1})
    fadeTween:Play()
    
    task.delay(2, function()
        part:Destroy()
    end)
end

-- Damage Functions
local function calculateGreyDamage(dmg)
    local chance = 0
    if dmg <= 5 then chance = 0.05
    elseif dmg <= 20 then chance = 0.13
    elseif dmg <= 50 then chance = 0.30
    elseif dmg <= 100 then chance = 0.50
    elseif dmg <= 375 then chance = 0.75
    elseif dmg <= 900 then chance = 0.90
    else chance = 1.0 end
    
    if math.random() < chance then
        return dmg * 3
    end
    return dmg
end

local function resetStats()
    currentHP = maxHP
    currentSP = maxSP
    hasTrauma = false
    updateBars()
end

local function applyDamage(damageType, minAmount, maxAmount)
    -- Generate random damage with decimal
    local amount = math.random(minAmount * 10, maxAmount * 10) / 10
    
    -- Apply suit resistance
    local resistance = suits[currentSuit][damageType] or 1
    amount = amount * resistance
    
    local finalDamage = amount
    
    if damageType == "Crimson" then
        currentHP = math.max(0, currentHP - finalDamage)
    elseif damageType == "Blue" then
        currentSP = math.max(0, currentSP - finalDamage)
    elseif damageType == "Purple" then
        currentHP = math.max(0, currentHP - finalDamage)
        currentSP = math.max(0, currentSP - finalDamage)
    elseif damageType == "Grey" then
        finalDamage = calculateGreyDamage(amount)
        currentHP = math.max(0, currentHP - finalDamage)
    elseif damageType == "White" then
        finalDamage = calculateGreyDamage(amount)
        currentSP = math.max(0, currentSP - finalDamage)
    end
    
    -- Create damage popup
    createDamagePopup(damageType, finalDamage)
    
    if currentSP <= 0 and not hasTrauma then
        hasTrauma = true
        warn("TRAUMA ACQUIRED!")
    end
    
    -- Check if player died
    if currentHP <= 0 then
        humanoid.Health = 0
        task.wait(5)
        resetStats()
    end
    
    updateBars()
end

function updateBars()
    hpBar.Size = UDim2.new(currentHP / maxHP, 0, 1, 0)
    hpText.Text = string.format("HP: %.1f/%d", currentHP, maxHP)
    
    spBar.Size = UDim2.new(currentSP / maxSP, 0, 1, 0)
    spText.Text = string.format("SP: %.1f/%d", currentSP, maxSP)
end

-- Illusion: Apostle
local function startApostle()
    local apostles = {}
    
    local function spawnApostle()
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = char.HumanoidRootPart
        local spawnDist = 50
        local angle = math.random() * math.pi * 2
        local offset = Vector3.new(math.cos(angle) * spawnDist, 5, math.sin(angle) * spawnDist)
        
        local apostle = Instance.new("Part")
        apostle.Shape = Enum.PartType.Ball
        apostle.Size = Vector3.new(3, 3, 3)
        apostle.Color = Color3.new(1, 1, 1)
        apostle.Material = Enum.Material.Neon
        apostle.CanCollide = false
        apostle.Anchored = false
        apostle.Position = hrp.Position + offset
        apostle.Parent = workspace
        
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVel.Parent = apostle
        
        table.insert(apostles, {part = apostle, vel = bodyVel})
        
        local touchConnection
        touchConnection = apostle.Touched:Connect(function(hit)
            if hit.Parent == char then
                local whiteScreen = Instance.new("Frame")
                whiteScreen.Size = UDim2.new(1, 0, 1, 0)
                whiteScreen.BackgroundColor3 = Color3.new(1, 1, 1)
                whiteScreen.BackgroundTransparency = 0
                whiteScreen.Parent = screenGui
                
                TweenService:Create(whiteScreen, TweenInfo.new(2), {BackgroundTransparency = 1}):Play()
                task.delay(2, function() whiteScreen:Destroy() end)
                
                applyDamage("Blue", 1, 7)
                touchConnection:Disconnect()
                apostle:Destroy()
                
                for i, a in ipairs(apostles) do
                    if a.part == apostle then
                        table.remove(apostles, i)
                        break
                    end
                end
            end
        end)
    end
    
    spawnApostle()
    
    local spawnLoop = RunService.Heartbeat:Connect(function()
        if not activeIllusions["Apostle"] then
            for _, a in ipairs(apostles) do
                if a.part and a.part.Parent then 
                    a.part:Destroy() 
                end
            end
            spawnLoop:Disconnect()
            return
        end
        
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            for _, a in ipairs(apostles) do
                if a.part and a.part.Parent and a.vel and a.vel.Parent then
                    local dir = (hrp.Position - a.part.Position).Unit
                    a.vel.Velocity = dir * 15
                end
            end
        end
    end)
    
    local spawnTimer = 0
    local timerLoop = RunService.Heartbeat:Connect(function(dt)
        if not activeIllusions["Apostle"] then
            timerLoop:Disconnect()
            return
        end
        
        spawnTimer = spawnTimer + dt
        if spawnTimer >= 10 then
            spawnTimer = 0
            spawnApostle()
        end
    end)
    
    illusionLoops["Apostle"] = {spawnLoop, timerLoop}
end

-- Illusion: Brooding Darkness
local function startBroodingDarkness()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    -- Create humanoid-like enemy
    local enemy = Instance.new("Model")
    enemy.Name = "BroodingDarkness"
    enemy.Parent = workspace
    
    local torso = Instance.new("Part")
    torso.Size = Vector3.new(2, 2, 1)
    torso.Color = Color3.new(0, 0, 0)
    torso.Material = Enum.Material.Neon
    torso.Anchored = true
    torso.CanCollide = false
    torso.Position = hrp.Position + Vector3.new(10, 0, 0)
    torso.Parent = enemy
    
    local head = Instance.new("Part")
    head.Size = Vector3.new(1.5, 1.5, 1.5)
    head.Shape = Enum.PartType.Ball
    head.Color = Color3.new(0, 0, 0)
    head.Material = Enum.Material.Neon
    head.Anchored = true
    head.CanCollide = false
    head.Position = torso.Position + Vector3.new(0, 2, 0)
    head.Parent = enemy
    
    local leftArm = Instance.new("Part")
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.Color = Color3.new(0.1, 0.1, 0.1)
    leftArm.Material = Enum.Material.Neon
    leftArm.Anchored = true
    leftArm.CanCollide = false
    leftArm.Position = torso.Position + Vector3.new(-1.5, 0, 0)
    leftArm.Parent = enemy
    
    local rightArm = Instance.new("Part")
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Color = Color3.new(0.1, 0.1, 0.1)
    rightArm.Material = Enum.Material.Neon
    rightArm.Anchored = true
    rightArm.CanCollide = false
    rightArm.Position = torso.Position + Vector3.new(1.5, 0, 0)
    rightArm.Parent = enemy
    
    local leftLeg = Instance.new("Part")
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.Color = Color3.new(0.2, 0.2, 0.2)
    leftLeg.Material = Enum.Material.Neon
    leftLeg.Anchored = true
    leftLeg.CanCollide = false
    leftLeg.Position = torso.Position + Vector3.new(-0.5, -2, 0)
    leftLeg.Parent = enemy
    
    local rightLeg = Instance.new("Part")
    rightLeg.Size = Vector3.new(1, 2, 1)
    rightLeg.Color = Color3.new(0.2, 0.2, 0.2)
    rightLeg.Material = Enum.Material.Neon
    rightLeg.Anchored = true
    rightLeg.CanCollide = false
    rightLeg.Position = torso.Position + Vector3.new(0.5, -2, 0)
    rightLeg.Parent = enemy
    
    local attackTimer = 0
    local abilityTimer = 0
    local isForceWalking = false
    local forceWalkConnection = nil
    local moveSpeed = 8 -- Studs per second
    
    local function punchAttack()
        local currentChar = player.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        
        local playerPos = currentChar.HumanoidRootPart.Position
        local enemyPos = torso.Position
        local dist = (playerPos - enemyPos).Magnitude
        
        -- Animate arms forward
        local leftGoal = {Position = leftArm.Position + (playerPos - enemyPos).Unit * 3}
        local rightGoal = {Position = rightArm.Position + (playerPos - enemyPos).Unit * 3}
        
        local punchTween1 = TweenService:Create(leftArm, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), leftGoal)
        local punchTween2 = TweenService:Create(rightArm, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), rightGoal)
        
        punchTween1:Play()
        punchTween2:Play()
        
        task.wait(0.3)
        
        -- Check if player is in range
        if dist <= 10 then
            applyDamage("Blue", 4, 7)
        end
        
        -- Reset arms
        task.wait(0.2)
        TweenService:Create(leftArm, TweenInfo.new(0.3), {Position = torso.Position + Vector3.new(-1.5, 0, 0)}):Play()
        TweenService:Create(rightArm, TweenInfo.new(0.3), {Position = torso.Position + Vector3.new(1.5, 0, 0)}):Play()
    end
    
    local function useAbility()
        -- Create blue forcefield
        local forcefield = Instance.new("Part")
        forcefield.Shape = Enum.PartType.Ball
        forcefield.Size = Vector3.new(100, 100, 100)
        forcefield.Color = Color3.fromRGB(50, 120, 220)
        forcefield.Material = Enum.Material.ForceField
        forcefield.Transparency = 0.3
        forcefield.CanCollide = false
        forcefield.Anchored = true
        forcefield.Position = torso.Position
        forcefield.Parent = workspace
        
        -- Fade forcefield over 3 seconds
        TweenService:Create(forcefield, TweenInfo.new(3), {Transparency = 1}):Play()
        
        -- Check if player is in range
        local currentChar = player.Character
        if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
            local playerPos = currentChar.HumanoidRootPart.Position
            local dist = (playerPos - torso.Position).Magnitude
            
            if dist <= 50 then
                applyDamage("Blue", 22, 28)
                
                -- Check if SP is 0 for force walk
                if currentSP <= 0 and not isForceWalking then
                    isForceWalking = true
                    local humanoid = currentChar:FindFirstChild("Humanoid")
                    
                    if humanoid then
                        forceWalkConnection = RunService.Heartbeat:Connect(function()
                            if not activeIllusions["Brooding Darkness"] or not torso.Parent then
                                if forceWalkConnection then
                                    forceWalkConnection:Disconnect()
                                end
                                isForceWalking = false
                                return
                            end
                            
                            local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
                            if currentHrp then
                                local direction = (torso.Position - currentHrp.Position).Unit
                                humanoid:MoveTo(currentHrp.Position + direction * 5)
                                
                                -- Check if touched illusion
                                local touchDist = (currentHrp.Position - torso.Position).Magnitude
                                if touchDist <= 5 then
                                    applyDamage("Crimson", 80, 120)
                                    if forceWalkConnection then
                                        forceWalkConnection:Disconnect()
                                    end
                                    isForceWalking = false
                                end
                            end
                        end)
                    end
                end
            end
        end
        
        task.delay(3, function()
            if forcefield and forcefield.Parent then
                forcefield:Destroy()
            end
        end)
    end
    
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeIllusions["Brooding Darkness"] then
            if enemy and enemy.Parent then enemy:Destroy() end
            if forceWalkConnection then forceWalkConnection:Disconnect() end
            loop:Disconnect()
            return
        end
        
        attackTimer = attackTimer + dt
        abilityTimer = abilityTimer + dt
        
        -- Attack every 3 seconds
        if attackTimer >= 3 then
            attackTimer = 0
            punchAttack()
        end
        
        -- Use ability every 30 seconds
        if abilityTimer >= 30 then
            abilityTimer = 0
            useAbility()
        end
        
        -- Follow and face player
        local currentChar = player.Character
        if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
            local playerPos = currentChar.HumanoidRootPart.Position
            local enemyPos = torso.Position
            local dist = (playerPos - enemyPos).Magnitude
            
            -- Move towards player if too far
            if dist > 7 then
                local direction = (playerPos - enemyPos).Unit
                local newPos = enemyPos + direction * moveSpeed * dt
                torso.Position = newPos
            end
            
            -- Make enemy face player
            local lookAt = Vector3.new(playerPos.X, torso.Position.Y, playerPos.Z)
            torso.CFrame = CFrame.new(torso.Position, lookAt)
            
            -- Update body parts positions relative to torso
            head.Position = torso.Position + Vector3.new(0, 2, 0)
            leftArm.Position = torso.Position + torso.CFrame.RightVector * -1.5
            rightArm.Position = torso.Position + torso.CFrame.RightVector * 1.5
            leftLeg.Position = torso.Position + Vector3.new(-0.5, -2, 0)
            rightLeg.Position = torso.Position + Vector3.new(0.5, -2, 0)
        end
    end)
    
    illusionLoops["Brooding Darkness"] = {loop}
end

-- Illusion: Brooding Darkness
local function startBroodingDarkness()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    -- Create humanoid-like enemy
    local enemy = Instance.new("Model")
    enemy.Name = "BroodingDarkness"
    enemy.Parent = workspace
    
    local torso = Instance.new("Part")
    torso.Size = Vector3.new(2, 2, 1)
    torso.Color = Color3.new(0, 0, 0)
    torso.Material = Enum.Material.Neon
    torso.Anchored = true
    torso.CanCollide = false
    torso.Position = hrp.Position + Vector3.new(10, 0, 0)
    torso.Parent = enemy
    
    local head = Instance.new("Part")
    head.Size = Vector3.new(1.5, 1.5, 1.5)
    head.Shape = Enum.PartType.Ball
    head.Color = Color3.new(0, 0, 0)
    head.Material = Enum.Material.Neon
    head.Anchored = true
    head.CanCollide = false
    head.Position = torso.Position + Vector3.new(0, 2, 0)
    head.Parent = enemy
    
    local leftArm = Instance.new("Part")
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.Color = Color3.new(0.1, 0.1, 0.1)
    leftArm.Material = Enum.Material.Neon
    leftArm.Anchored = true
    leftArm.CanCollide = false
    leftArm.Position = torso.Position + Vector3.new(-1.5, 0, 0)
    leftArm.Parent = enemy
    
    local rightArm = Instance.new("Part")
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Color = Color3.new(0.1, 0.1, 0.1)
    rightArm.Material = Enum.Material.Neon
    rightArm.Anchored = true
    rightArm.CanCollide = false
    rightArm.Position = torso.Position + Vector3.new(1.5, 0, 0)
    rightArm.Parent = enemy
    
    local leftLeg = Instance.new("Part")
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.Color = Color3.new(0.2, 0.2, 0.2)
    leftLeg.Material = Enum.Material.Neon
    leftLeg.Anchored = true
    leftLeg.CanCollide = false
    leftLeg.Position = torso.Position + Vector3.new(-0.5, -2, 0)
    leftLeg.Parent = enemy
    
    local rightLeg = Instance.new("Part")
    rightLeg.Size = Vector3.new(1, 2, 1)
    rightLeg.Color = Color3.new(0.2, 0.2, 0.2)
    rightLeg.Material = Enum.Material.Neon
    rightLeg.Anchored = true
    rightLeg.CanCollide = false
    rightLeg.Position = torso.Position + Vector3.new(0.5, -2, 0)
    rightLeg.Parent = enemy
    
    local attackTimer = 0
    local abilityTimer = 0
    local isForceWalking = false
    local forceWalkConnection = nil
    local moveSpeed = 8 -- Studs per second
    
    local function punchAttack()
        local currentChar = player.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        
        local playerPos = currentChar.HumanoidRootPart.Position
        local enemyPos = torso.Position
        local dist = (playerPos - enemyPos).Magnitude
        
        -- Animate arms forward
        local leftGoal = {Position = leftArm.Position + (playerPos - enemyPos).Unit * 3}
        local rightGoal = {Position = rightArm.Position + (playerPos - enemyPos).Unit * 3}
        
        local punchTween1 = TweenService:Create(leftArm, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), leftGoal)
        local punchTween2 = TweenService:Create(rightArm, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), rightGoal)
        
        punchTween1:Play()
        punchTween2:Play()
        
        task.wait(0.3)
        
        -- Check if player is in range
        if dist <= 10 then
            applyDamage("Blue", 4, 7)
        end
        
        -- Reset arms
        task.wait(0.2)
        TweenService:Create(leftArm, TweenInfo.new(0.3), {Position = torso.Position + Vector3.new(-1.5, 0, 0)}):Play()
        TweenService:Create(rightArm, TweenInfo.new(0.3), {Position = torso.Position + Vector3.new(1.5, 0, 0)}):Play()
    end
    
    local function useAbility()
        -- Create blue forcefield
        local forcefield = Instance.new("Part")
        forcefield.Shape = Enum.PartType.Ball
        forcefield.Size = Vector3.new(100, 100, 100)
        forcefield.Color = Color3.fromRGB(50, 120, 220)
        forcefield.Material = Enum.Material.ForceField
        forcefield.Transparency = 0.3
        forcefield.CanCollide = false
        forcefield.Anchored = true
        forcefield.Position = torso.Position
        forcefield.Parent = workspace
        
        -- Fade forcefield over 3 seconds
        TweenService:Create(forcefield, TweenInfo.new(3), {Transparency = 1}):Play()
        
        -- Check if player is in range
        local currentChar = player.Character
        if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
            local playerPos = currentChar.HumanoidRootPart.Position
            local dist = (playerPos - torso.Position).Magnitude
            
            if dist <= 50 then
                applyDamage("Blue", 22, 28)
                
                -- Check if SP is 0 for force walk
                if currentSP <= 0 and not isForceWalking then
                    isForceWalking = true
                    local humanoid = currentChar:FindFirstChild("Humanoid")
                    
                    if humanoid then
                        forceWalkConnection = RunService.Heartbeat:Connect(function()
                            if not activeIllusions["Brooding Darkness"] or not torso.Parent then
                                if forceWalkConnection then
                                    forceWalkConnection:Disconnect()
                                end
                                isForceWalking = false
                                return
                            end
                            
                            local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
                            if currentHrp then
                                local direction = (torso.Position - currentHrp.Position).Unit
                                humanoid:MoveTo(currentHrp.Position + direction * 5)
                                
                                -- Check if touched illusion
                                local touchDist = (currentHrp.Position - torso.Position).Magnitude
                                if touchDist <= 5 then
                                    applyDamage("Crimson", 80, 120)
                                    if forceWalkConnection then
                                        forceWalkConnection:Disconnect()
                                    end
                                    isForceWalking = false
                                end
                            end
                        end)
                    end
                end
            end
        end
        
        task.delay(3, function()
            if forcefield and forcefield.Parent then
                forcefield:Destroy()
            end
        end)
    end
    
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeIllusions["Brooding Darkness"] then
            if enemy and enemy.Parent then enemy:Destroy() end
            if forceWalkConnection then forceWalkConnection:Disconnect() end
            loop:Disconnect()
            return
        end
        
        attackTimer = attackTimer + dt
        abilityTimer = abilityTimer + dt
        
        -- Attack every 3 seconds
        if attackTimer >= 3 then
            attackTimer = 0
            punchAttack()
        end
        
        -- Use ability every 30 seconds
        if abilityTimer >= 30 then
            abilityTimer = 0
            useAbility()
        end
        
        -- Follow and face player
        local currentChar = player.Character
        if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
            local playerPos = currentChar.HumanoidRootPart.Position
            local enemyPos = torso.Position
            local dist = (playerPos - enemyPos).Magnitude
            
            -- Move towards player if too far
            if dist > 7 then
                local direction = (playerPos - enemyPos).Unit
                local newPos = enemyPos + direction * moveSpeed * dt
                torso.Position = newPos
            end
            
            -- Make enemy face player
            local lookAt = Vector3.new(playerPos.X, torso.Position.Y, playerPos.Z)
            torso.CFrame = CFrame.new(torso.Position, lookAt)
            
            -- Update body parts positions relative to torso
            head.Position = torso.Position + Vector3.new(0, 2, 0)
            leftArm.Position = torso.Position + torso.CFrame.RightVector * -1.5
            rightArm.Position = torso.Position + torso.CFrame.RightVector * 1.5
            leftLeg.Position = torso.Position + Vector3.new(-0.5, -2, 0)
            rightLeg.Position = torso.Position + Vector3.new(0.5, -2, 0)
        end
    end)
    
    illusionLoops["Brooding Darkness"] = {loop}
end

-- Illusion: The Gun Devil
local function startGunDevil()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    -- Create grey humanoid
    local enemy = Instance.new("Model")
    enemy.Name = "GunDevil"
    enemy.Parent = workspace
    
    local torso = Instance.new("Part")
    torso.Size = Vector3.new(2, 2, 1)
    torso.Color = Color3.fromRGB(150, 150, 150)
    torso.Material = Enum.Material.Metal
    torso.Anchored = true
    torso.CanCollide = false
    torso.Position = hrp.Position + Vector3.new(15, 0, 0)
    torso.Parent = enemy
    
    local head = Instance.new("Part")
    head.Size = Vector3.new(1.5, 1.5, 1.5)
    head.Shape = Enum.PartType.Ball
    head.Color = Color3.fromRGB(120, 120, 120)
    head.Material = Enum.Material.Metal
    head.Anchored = true
    head.CanCollide = false
    head.Position = torso.Position + Vector3.new(0, 2, 0)
    head.Parent = enemy
    
    local leftArm = Instance.new("Part")
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.Color = Color3.fromRGB(140, 140, 140)
    leftArm.Material = Enum.Material.Metal
    leftArm.Anchored = true
    leftArm.CanCollide = false
    leftArm.Position = torso.Position + Vector3.new(-1.5, 0, 0)
    leftArm.Parent = enemy
    
    local rightArm = Instance.new("Part")
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Color = Color3.fromRGB(140, 140, 140)
    rightArm.Material = Enum.Material.Metal
    rightArm.Anchored = true
    rightArm.CanCollide = false
    rightArm.Position = torso.Position + Vector3.new(1.5, 0, 0)
    rightArm.Parent = enemy
    
    -- Gun parts on arms
    local leftGun = Instance.new("Part")
    leftGun.Size = Vector3.new(0.5, 0.5, 2)
    leftGun.Color = Color3.new(0.1, 0.1, 0.1)
    leftGun.Material = Enum.Material.Metal
    leftGun.Anchored = true
    leftGun.CanCollide = false
    leftGun.Parent = enemy
    
    local rightGun = Instance.new("Part")
    rightGun.Size = Vector3.new(0.5, 0.5, 2)
    rightGun.Color = Color3.new(0.1, 0.1, 0.1)
    rightGun.Material = Enum.Material.Metal
    rightGun.Anchored = true
    rightGun.CanCollide = false
    rightGun.Parent = enemy
    
    local leftLeg = Instance.new("Part")
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.Color = Color3.fromRGB(130, 130, 130)
    leftLeg.Material = Enum.Material.Metal
    leftLeg.Anchored = true
    leftLeg.CanCollide = false
    leftLeg.Position = torso.Position + Vector3.new(-0.5, -2, 0)
    leftLeg.Parent = enemy
    
    local rightLeg = Instance.new("Part")
    rightLeg.Size = Vector3.new(1, 2, 1)
    rightLeg.Color = Color3.fromRGB(130, 130, 130)
    rightLeg.Material = Enum.Material.Metal
    rightLeg.Anchored = true
    rightLeg.CanCollide = false
    rightLeg.Position = torso.Position + Vector3.new(0.5, -2, 0)
    rightLeg.Parent = enemy
    
    local shootTimer = 0
    local bulletCount = 0
    local isBarraging = false
    local barrageCount = 0
    local barrageTimer = 0
    local abilityTimer = 0
    local moveSpeed = 6
    
    local function shootBullet(gunPart, direction)
        local currentChar = player.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        
        local playerPos = currentChar.HumanoidRootPart.Position
        local targetPos = direction or playerPos
        
        -- Create bullet
        local bullet = Instance.new("Part")
        bullet.Size = Vector3.new(0.3, 0.3, 1)
        bullet.Color = Color3.fromRGB(255, 200, 0)
        bullet.Material = Enum.Material.Neon
        bullet.CanCollide = false
        bullet.Anchored = false
        bullet.Position = gunPart.Position
        bullet.CFrame = CFrame.new(gunPart.Position, targetPos)
        bullet.Parent = workspace
        
        -- Muzzle flash
        local flash = Instance.new("Part")
        flash.Size = Vector3.new(1, 1, 1)
        flash.Color = Color3.fromRGB(255, 150, 0)
        flash.Material = Enum.Material.Neon
        flash.Transparency = 0.3
        flash.Shape = Enum.PartType.Ball
        flash.CanCollide = false
        flash.Anchored = true
        flash.Position = gunPart.Position
        flash.Parent = workspace
        
        TweenService:Create(flash, TweenInfo.new(0.1), {Transparency = 1}):Play()
        task.delay(0.1, function() if flash.Parent then flash:Destroy() end end)
        
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVel.Velocity = (targetPos - gunPart.Position).Unit * 120
        bodyVel.Parent = bullet
        
        local touchConnection
        touchConnection = bullet.Touched:Connect(function(hit)
            if hit.Parent == currentChar then
                applyDamage("Crimson", 8, 17)
                touchConnection:Disconnect()
                bullet:Destroy()
            end
        end)
        
        task.delay(3, function()
            if bullet.Parent then bullet:Destroy() end
        end)
    end
    
    local function circleBarrage()
        -- Shoot 20 bullets in a circle pattern
        for i = 1, 20 do
            local angle = (i / 20) * math.pi * 2
            local offset = Vector3.new(math.cos(angle) * 50, 0, math.sin(angle) * 50)
            local targetPos = torso.Position + offset
            
            -- Alternate between guns for visual effect
            if i % 2 == 0 then
                shootBullet(leftGun, targetPos)
            else
                shootBullet(rightGun, targetPos)
            end
            
            task.wait(0.05) -- Small delay between each shot for visual effect
        end
    end
    
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeIllusions["The Gun Devil"] then
            if enemy and enemy.Parent then enemy:Destroy() end
            loop:Disconnect()
            return
        end
        
        local currentChar = player.Character
        if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
            local playerPos = currentChar.HumanoidRootPart.Position
            local enemyPos = torso.Position
            local dist = (playerPos - enemyPos).Magnitude
            
            -- Move towards player if too far
            if dist > 20 then
                local direction = (playerPos - enemyPos).Unit
                local newPos = enemyPos + direction * moveSpeed * dt
                torso.Position = newPos
            end
            
            -- Make enemy face player
            local lookAt = Vector3.new(playerPos.X, torso.Position.Y, playerPos.Z)
            torso.CFrame = CFrame.new(torso.Position, lookAt)
            
            -- Update body parts
            head.Position = torso.Position + Vector3.new(0, 2, 0)
            leftArm.Position = torso.Position + torso.CFrame.RightVector * -1.5
            rightArm.Position = torso.Position + torso.CFrame.RightVector * 1.5
            leftGun.CFrame = CFrame.new(leftArm.Position + torso.CFrame.LookVector * 1.5, playerPos)
            rightGun.CFrame = CFrame.new(rightArm.Position + torso.CFrame.LookVector * 1.5, playerPos)
            leftLeg.Position = torso.Position + Vector3.new(-0.5, -2, 0)
            rightLeg.Position = torso.Position + Vector3.new(0.5, -2, 0)
        end
        
        -- Shooting logic
        if isBarraging then
            barrageTimer = barrageTimer + dt
            if barrageTimer >= 0.1 then
                barrageTimer = 0
                barrageCount = barrageCount + 1
                
                -- Alternate between guns
                if barrageCount % 2 == 0 then
                    shootBullet(leftGun)
                else
                    shootBullet(rightGun)
                end
                
                if barrageCount >= 20 then
                    isBarraging = false
                    barrageCount = 0
                    bulletCount = 0
                end
            end
        else
            shootTimer = shootTimer + dt
            if shootTimer >= 2 then
                shootTimer = 0
                bulletCount = bulletCount + 1
                
                -- Alternate between guns
                if bulletCount % 2 == 0 then
                    shootBullet(leftGun)
                else
                    shootBullet(rightGun)
                end
                
                if bulletCount >= 5 then
                    isBarraging = true
                end
            end
        end
        
        -- Circle barrage ability every 30 seconds
        abilityTimer = abilityTimer + dt
        if abilityTimer >= 30 then
            abilityTimer = 0
            task.spawn(function()
                circleBarrage()
            end)
        end
    end)
    
    illusionLoops["The Gun Devil"] = {loop}
end

-- Illusion: The Gun Devil
local function startGunDevil()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    -- Create grey humanoid
    local enemy = Instance.new("Model")
    enemy.Name = "GunDevil"
    enemy.Parent = workspace
    
    local torso = Instance.new("Part")
    torso.Size = Vector3.new(2, 2, 1)
    torso.Color = Color3.fromRGB(150, 150, 150)
    torso.Material = Enum.Material.Metal
    torso.Anchored = true
    torso.CanCollide = false
    torso.Position = hrp.Position + Vector3.new(15, 0, 0)
    torso.Parent = enemy
    
    local head = Instance.new("Part")
    head.Size = Vector3.new(1.5, 1.5, 1.5)
    head.Shape = Enum.PartType.Ball
    head.Color = Color3.fromRGB(120, 120, 120)
    head.Material = Enum.Material.Metal
    head.Anchored = true
    head.CanCollide = false
    head.Position = torso.Position + Vector3.new(0, 2, 0)
    head.Parent = enemy
    
    local leftArm = Instance.new("Part")
    leftArm.Size = Vector3.new(1, 2, 1)
    leftArm.Color = Color3.fromRGB(140, 140, 140)
    leftArm.Material = Enum.Material.Metal
    leftArm.Anchored = true
    leftArm.CanCollide = false
    leftArm.Position = torso.Position + Vector3.new(-1.5, 0, 0)
    leftArm.Parent = enemy
    
    local rightArm = Instance.new("Part")
    rightArm.Size = Vector3.new(1, 2, 1)
    rightArm.Color = Color3.fromRGB(140, 140, 140)
    rightArm.Material = Enum.Material.Metal
    rightArm.Anchored = true
    rightArm.CanCollide = false
    rightArm.Position = torso.Position + Vector3.new(1.5, 0, 0)
    rightArm.Parent = enemy
    
    -- Gun parts on arms
    local leftGun = Instance.new("Part")
    leftGun.Size = Vector3.new(0.5, 0.5, 2)
    leftGun.Color = Color3.new(0.1, 0.1, 0.1)
    leftGun.Material = Enum.Material.Metal
    leftGun.Anchored = true
    leftGun.CanCollide = false
    leftGun.Parent = enemy
    
    local rightGun = Instance.new("Part")
    rightGun.Size = Vector3.new(0.5, 0.5, 2)
    rightGun.Color = Color3.new(0.1, 0.1, 0.1)
    rightGun.Material = Enum.Material.Metal
    rightGun.Anchored = true
    rightGun.CanCollide = false
    rightGun.Parent = enemy
    
    local leftLeg = Instance.new("Part")
    leftLeg.Size = Vector3.new(1, 2, 1)
    leftLeg.Color = Color3.fromRGB(130, 130, 130)
    leftLeg.Material = Enum.Material.Metal
    leftLeg.Anchored = true
    leftLeg.CanCollide = false
    leftLeg.Position = torso.Position + Vector3.new(-0.5, -2, 0)
    leftLeg.Parent = enemy
    
    local rightLeg = Instance.new("Part")
    rightLeg.Size = Vector3.new(1, 2, 1)
    rightLeg.Color = Color3.fromRGB(130, 130, 130)
    rightLeg.Material = Enum.Material.Metal
    rightLeg.Anchored = true
    rightLeg.CanCollide = false
    rightLeg.Position = torso.Position + Vector3.new(0.5, -2, 0)
    rightLeg.Parent = enemy
    
    local shootTimer = 0
    local bulletCount = 0
    local isBarraging = false
    local barrageCount = 0
    local barrageTimer = 0
    local abilityTimer = 0
    local moveSpeed = 6
    
    local function shootBullet(gunPart, direction)
        local currentChar = player.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        
        local playerPos = currentChar.HumanoidRootPart.Position
        local targetPos = direction or playerPos
        
        -- Create bullet
        local bullet = Instance.new("Part")
        bullet.Size = Vector3.new(0.3, 0.3, 1)
        bullet.Color = Color3.fromRGB(255, 200, 0)
        bullet.Material = Enum.Material.Neon
        bullet.CanCollide = false
        bullet.Anchored = false
        bullet.Position = gunPart.Position
        bullet.CFrame = CFrame.new(gunPart.Position, targetPos)
        bullet.Parent = workspace
        
        -- Muzzle flash
        local flash = Instance.new("Part")
        flash.Size = Vector3.new(1, 1, 1)
        flash.Color = Color3.fromRGB(255, 150, 0)
        flash.Material = Enum.Material.Neon
        flash.Transparency = 0.3
        flash.Shape = Enum.PartType.Ball
        flash.CanCollide = false
        flash.Anchored = true
        flash.Position = gunPart.Position
        flash.Parent = workspace
        
        TweenService:Create(flash, TweenInfo.new(0.1), {Transparency = 1}):Play()
        task.delay(0.1, function() if flash.Parent then flash:Destroy() end end)
        
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVel.Velocity = (targetPos - gunPart.Position).Unit * 120
        bodyVel.Parent = bullet
        
        local touchConnection
        touchConnection = bullet.Touched:Connect(function(hit)
            if hit.Parent == currentChar then
                applyDamage("Crimson", 8, 17)
                touchConnection:Disconnect()
                bullet:Destroy()
            end
        end)
        
        task.delay(3, function()
            if bullet.Parent then bullet:Destroy() end
        end)
    end
    
    local function circleBarrage()
        -- Shoot 20 bullets in a circle pattern
        for i = 1, 20 do
            local angle = (i / 20) * math.pi * 2
            local offset = Vector3.new(math.cos(angle) * 50, 0, math.sin(angle) * 50)
            local targetPos = torso.Position + offset
            
            -- Alternate between guns for visual effect
            if i % 2 == 0 then
                shootBullet(leftGun, targetPos)
            else
                shootBullet(rightGun, targetPos)
            end
            
            task.wait(0.05) -- Small delay between each shot for visual effect
        end
    end
    
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeIllusions["The Gun Devil"] then
            if enemy and enemy.Parent then enemy:Destroy() end
            loop:Disconnect()
            return
        end
        
        local currentChar = player.Character
        if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
            local playerPos = currentChar.HumanoidRootPart.Position
            local enemyPos = torso.Position
            local dist = (playerPos - enemyPos).Magnitude
            
            -- Move towards player if too far
            if dist > 20 then
                local direction = (playerPos - enemyPos).Unit
                local newPos = enemyPos + direction * moveSpeed * dt
                torso.Position = newPos
            end
            
            -- Make enemy face player
            local lookAt = Vector3.new(playerPos.X, torso.Position.Y, playerPos.Z)
            torso.CFrame = CFrame.new(torso.Position, lookAt)
            
            -- Update body parts
            head.Position = torso.Position + Vector3.new(0, 2, 0)
            leftArm.Position = torso.Position + torso.CFrame.RightVector * -1.5
            rightArm.Position = torso.Position + torso.CFrame.RightVector * 1.5
            leftGun.CFrame = CFrame.new(leftArm.Position + torso.CFrame.LookVector * 1.5, playerPos)
            rightGun.CFrame = CFrame.new(rightArm.Position + torso.CFrame.LookVector * 1.5, playerPos)
            leftLeg.Position = torso.Position + Vector3.new(-0.5, -2, 0)
            rightLeg.Position = torso.Position + Vector3.new(0.5, -2, 0)
        end
        
        -- Shooting logic
        if isBarraging then
            barrageTimer = barrageTimer + dt
            if barrageTimer >= 0.1 then
                barrageTimer = 0
                barrageCount = barrageCount + 1
                
                -- Alternate between guns
                if barrageCount % 2 == 0 then
                    shootBullet(leftGun)
                else
                    shootBullet(rightGun)
                end
                
                if barrageCount >= 20 then
                    isBarraging = false
                    barrageCount = 0
                    bulletCount = 0
                end
            end
        else
            shootTimer = shootTimer + dt
            if shootTimer >= 2 then
                shootTimer = 0
                bulletCount = bulletCount + 1
                
                -- Alternate between guns
                if bulletCount % 2 == 0 then
                    shootBullet(leftGun)
                else
                    shootBullet(rightGun)
                end
                
                if bulletCount >= 5 then
                    isBarraging = true
                end
            end
        end
        
        -- Circle barrage ability every 30 seconds
        abilityTimer = abilityTimer + dt
        if abilityTimer >= 30 then
            abilityTimer = 0
            task.spawn(function()
                circleBarrage()
            end)
        end
    end)
    
    illusionLoops["The Gun Devil"] = {loop}
end

-- Illusion: Eye Eater
local function startEyeEater()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    -- Create floating eye
    local eye = Instance.new("Part")
    eye.Shape = Enum.PartType.Ball
    eye.Size = Vector3.new(3, 3, 3)
    eye.Color = Color3.new(1, 1, 1)
    eye.Material = Enum.Material.SmoothPlastic
    eye.Anchored = true
    eye.CanCollide = false
    eye.Position = hrp.Position + Vector3.new(10, 5, 0)
    eye.Parent = workspace
    
    -- Green pupil (normal state)
    local pupil = Instance.new("Part")
    pupil.Shape = Enum.PartType.Ball
    pupil.Size = Vector3.new(1.5, 1.5, 1.5)
    pupil.Color = Color3.fromRGB(0, 255, 0)
    pupil.Material = Enum.Material.Neon
    pupil.Anchored = true
    pupil.CanCollide = false
    pupil.Parent = eye
    
    -- Particle emitter for purple state
    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
    particles.Color = ColorSequence.new(Color3.fromRGB(200, 0, 255))
    particles.Size = NumberSequence.new(0.5)
    particles.Lifetime = NumberRange.new(1, 2)
    particles.Rate = 50
    particles.Speed = NumberRange.new(2, 5)
    particles.Enabled = false
    particles.Parent = pupil
    
    local attackTimer = 0
    local abilityTimer = 0
    local moveSpeed = 10
    local isMouth = false
    local isForceWalking = false
    local forceWalkConnection = nil
    local originalSpeed = 16
    
    local function transformToMouth()
        isMouth = true
        eye.Color = Color3.fromRGB(255, 100, 100)
        pupil.Visible = false
        
        -- Check if player is close enough
        local currentChar = player.Character
        if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
            local dist = (currentChar.HumanoidRootPart.Position - eye.Position).Magnitude
            if dist <= 15 then
                applyDamage("Grey", 8, 10)
            end
        end
        
        task.wait(0.5)
        
        -- Transform back
        isMouth = false
        eye.Color = Color3.new(1, 1, 1)
        pupil.Visible = true
    end
    
    local function purpleAbility()
        -- Turn purple with particles
        pupil.Color = Color3.fromRGB(200, 0, 255)
        particles.Enabled = true
        
        local currentChar = player.Character
        if currentChar and currentChar:FindFirstChild("HumanoidRootPart") and currentChar:FindFirstChild("Humanoid") then
            local dist = (currentChar.HumanoidRootPart.Position - eye.Position).Magnitude
            
            if dist <= 200 then
                isForceWalking = true
                local humanoid = currentChar.Humanoid
                originalSpeed = humanoid.WalkSpeed
                humanoid.WalkSpeed = originalSpeed + 4
                
                forceWalkConnection = RunService.Heartbeat:Connect(function()
                    if not activeIllusions["Eye Eater"] or not eye.Parent then
                        if forceWalkConnection then
                            forceWalkConnection:Disconnect()
                        end
                        isForceWalking = false
                        if humanoid then
                            humanoid.WalkSpeed = originalSpeed
                        end
                        return
                    end
                    
                    local currentHrp = currentChar:FindFirstChild("HumanoidRootPart")
                    if currentHrp and humanoid then
                        -- Force walk toward eye
                        local direction = (eye.Position - currentHrp.Position).Unit
                        humanoid:Move(direction)
                        
                        -- Check if touched eye
                        local touchDist = (currentHrp.Position - eye.Position).Magnitude
                        if touchDist <= 5 then
                            -- Transform to mouth and damage
                            pupil.Color = Color3.fromRGB(0, 255, 0)
                            particles.Enabled = false
                            eye.Color = Color3.fromRGB(255, 100, 100)
                            pupil.Visible = false
                            
                            applyDamage("Grey", 10, 20)
                            
                            task.wait(0.5)
                            eye.Color = Color3.new(1, 1, 1)
                            pupil.Visible = true
                            
                            -- Reset speed and stop force walk
                            humanoid.WalkSpeed = originalSpeed
                            if forceWalkConnection then
                                forceWalkConnection:Disconnect()
                            end
                            isForceWalking = false
                        end
                    end
                end)
            end
        end
        
        -- Reset after 10 seconds if player hasn't reached
        task.wait(10)
        if isForceWalking then
            pupil.Color = Color3.fromRGB(0, 255, 0)
            particles.Enabled = false
            
            local currentChar = player.Character
            if currentChar and currentChar:FindFirstChild("Humanoid") then
                currentChar.Humanoid.WalkSpeed = originalSpeed
            end
            
            if forceWalkConnection then
                forceWalkConnection:Disconnect()
            end
            isForceWalking = false
        end
    end
    
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeIllusions["Eye Eater"] then
            if eye and eye.Parent then eye:Destroy() end
            if forceWalkConnection then forceWalkConnection:Disconnect() end
            loop:Disconnect()
            return
        end
        
        attackTimer = attackTimer + dt
        abilityTimer = abilityTimer + dt
        
        -- Attack every 3 seconds
        if attackTimer >= 3 and not isMouth and not isForceWalking then
            attackTimer = 0
            task.spawn(function()
                transformToMouth()
            end)
        end
        
        -- Purple ability every 25 seconds
        if abilityTimer >= 25 and not isForceWalking then
            abilityTimer = 0
            task.spawn(function()
                purpleAbility()
            end)
        end
        
        -- Follow and look at player
        local currentChar = player.Character
        if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
            local playerPos = currentChar.HumanoidRootPart.Position
            local eyePos = eye.Position
            local dist = (playerPos - eyePos).Magnitude
            
            -- Move towards player if too far
            if dist > 10 and not isForceWalking then
                local direction = (playerPos - eyePos).Unit
                local newPos = eyePos + direction * moveSpeed * dt
                eye.Position = newPos
            end
            
            -- Make pupil face player
            pupil.Position = eye.Position + (playerPos - eye.Position).Unit * 0.75
        end
    end)
    
    illusionLoops["Eye Eater"] = {loop}
end

-- Illusion: Liquid Orchestra
local function startLiquidOrchestra()
    local liquid = Instance.new("Part")
    liquid.Size = Vector3.new(10, 1, 10)
    liquid.Color = Color3.new(0, 0, 0)
    liquid.Material = Enum.Material.Glass
    liquid.Anchored = true
    liquid.CanCollide = false
    
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        liquid.Position = char.HumanoidRootPart.Position + Vector3.new(0, -3, 0)
    end
    liquid.Parent = workspace
    
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.Parent = liquid
    
    local movementText = Instance.new("TextLabel")
    movementText.Size = UDim2.new(1, 0, 1, 0)
    movementText.BackgroundTransparency = 1
    movementText.Text = "Movement 1"
    movementText.TextColor3 = Color3.new(1, 1, 1)
    movementText.Font = Enum.Font.GothamBold
    movementText.TextSize = 48
    movementText.Parent = surfaceGui
    
    local movements = {
        {time = 0, color = Color3.fromRGB(150, 150, 150), size = 20, damage = "Grey", scale = {10, 30}, name = "Movement 1"},
        {time = 25, color = Color3.new(1, 1, 1), size = 45, damage = "White", scale = {10, 30}, name = "Movement 2"},
        {time = 60, color = Color3.fromRGB(200, 100, 255), size = 90, damage = "Purple", scale = {10, 30}, name = "Movement 3"},
        {time = 150, color = Color3.fromRGB(220, 50, 50), size = 150, damage = "Crimson", scale = {10, 30}, name = "Movement 4"},
        {time = 300, color = Color3.fromRGB(50, 120, 220), size = 300, damage = "Blue", scale = {10, 30}, name = "Movement 5"}
    }
    
    local currentMovement = 1
    local forcefield = nil
    local timer = 0
    local lastDamageTime = 0
    
    local function createForcefield(movement)
        if forcefield and forcefield.Parent then 
            forcefield:Destroy() 
        end
        
        forcefield = Instance.new("Part")
        forcefield.Shape = Enum.PartType.Ball
        forcefield.Size = Vector3.new(movement.size, movement.size, movement.size)
        forcefield.Color = movement.color
        forcefield.Material = Enum.Material.ForceField
        forcefield.Transparency = 0.5
        forcefield.CanCollide = false
        forcefield.Anchored = true
        forcefield.Position = liquid.Position
        forcefield.Parent = workspace
        
        movementText.Text = movement.name
    end
    
    createForcefield(movements[1])
    
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeIllusions["Liquid Orchestra"] then
            if liquid and liquid.Parent then liquid:Destroy() end
            if forcefield and forcefield.Parent then forcefield:Destroy() end
            loop:Disconnect()
            return
        end
        
        timer = timer + dt
        
        for i = currentMovement + 1, #movements do
            if timer >= movements[i].time then
                currentMovement = i
                createForcefield(movements[i])
            end
        end
        
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and forcefield and forcefield.Parent then
            local dist = (char.HumanoidRootPart.Position - forcefield.Position).Magnitude
            local movement = movements[currentMovement]
            
            if dist <= movement.size / 2 and (timer - lastDamageTime) >= 1 then
                applyDamage(movement.damage, movement.scale[1], movement.scale[2])
                lastDamageTime = timer
            end
        end
    end)
    
    illusionLoops["Liquid Orchestra"] = {loop}
end

-- Create Illusion Entries
local illusions = {
    {
        name = "Apostle",
        desc = "Messenger from the [FALSE GOD] ordered to kill humanity.",
        damageType = "Blue",
        damageScale = "1 - 7",
        danger = "AYIN",
        func = startApostle
    },
    {
        name = "Brooding Darkness",
        desc = "A dark humanoid entity that feeds on despair. It strikes with its shadowy fists and unleashes waves of mental anguish. Those with broken minds are drawn to it like moths to a flame, meeting their doom in its embrace.",
        damageType = "Blue",
        damageScale = "4 - 7 (Punch) / 22 - 28 (Ability) / 80 - 120 (Touch)",
        danger = "LAMED",
        func = startBroodingDarkness
    },
    {
        name = "The Gun Devil",
        desc = "A manifestation of humanity's fear of firearms. This metallic grey entity is armed with dual guns that never run out of ammunition. It stalks its prey relentlessly, firing with cold precision. After warming up with a few shots, it unleashes a devastating barrage that tears through flesh and bone. The sound of gunfire echoes as a grim reminder: nowhere is safe.",
        damageType = "Crimson",
        damageScale = "8 - 17",
        danger = "SHIN",
        func = startGunDevil
    },
    {
        name = "Eye Eater",
        desc = "Eye of RAHHHH. A floating eyeball with an emerald green pupil that watches your every move. Every few seconds, it transforms into a grotesque mouth to feast on your soul. But its true terror lies in its hypnotic purple gaze - when the pupil turns violet, you cannot resist its pull. Your legs move on their own, faster and faster, drawn like a moth to flame. And when you reach it... the eye opens wide.",
        damageType = "Grey",
        damageScale = "8 - 10 (Bite) / 10 - 20 (Purple Touch)",
        danger = "SAMECH",
        func = startEyeEater
    },
    {
        name = "Liquid Orchestra",
        desc = "Somewhere in the Flament Village, a deadly disease is around the village but nobody noticed. Then, a villager shouted: 'Hey! This liquid is producing music!' Everybody come to the liquid. And slowly, the music grew louder, and louder, and louder. The villagers are devoted to the music and then they start to melt and rot.",
        damageType = "Variable",
        damageScale = "10 - 30",
        danger = "TZADEL",
        func = startLiquidOrchestra
    }
}

for _, illusion in ipairs(illusions) do
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 150)
    frame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    frame.BorderSizePixel = 1
    frame.Parent = scrollFrame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.Text = illusion.name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 18
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = Color3.new(0, 0, 0)
    nameLabel.Parent = frame
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -10, 0, 40)
    descLabel.Position = UDim2.new(0, 5, 0, 30)
    descLabel.Text = illusion.desc
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 10
    descLabel.TextWrapped = true
    descLabel.BackgroundTransparency = 1
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.TextColor3 = Color3.new(0, 0, 0)
    descLabel.Parent = frame
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -10, 0, 50)
    infoLabel.Position = UDim2.new(0, 5, 0, 75)
    infoLabel.Text = string.format("Damage Type: %s\nDamage Scale: %s\nDanger Level: %s", 
        illusion.damageType, illusion.damageScale, illusion.danger)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 12
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.TextColor3 = dangerColors[illusion.danger]
    infoLabel.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 80, 0, 30)
    toggleBtn.Position = UDim2.new(1, -90, 1, -35)
    toggleBtn.Text = "OFF"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 16
    toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Parent = frame
    
    toggleBtn.MouseButton1Click:Connect(function()
        if activeIllusions[illusion.name] then
            activeIllusions[illusion.name] = false
            toggleBtn.Text = "OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            
            -- Clean up loops
            if illusionLoops[illusion.name] then
                for _, loop in ipairs(illusionLoops[illusion.name]) do
                    if loop and loop.Connected then
                        loop:Disconnect()
                    end
                end
                illusionLoops[illusion.name] = nil
            end
        else
            activeIllusions[illusion.name] = true
            toggleBtn.Text = "ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
            illusion.func()
        end
    end)
end

scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)

-- Create Suit Entries
local function refreshSuitButtons()
    for _, child in ipairs(suitsScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    for suitName, resistances in pairs(suits) do
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 180)
        frame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        frame.BorderSizePixel = 1
        frame.Parent = suitsScrollFrame
        
        -- Suit Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -10, 0, 25)
        nameLabel.Position = UDim2.new(0, 5, 0, 5)
        nameLabel.Text = suitName .. (currentSuit == suitName and " (EQUIPPED)" or "")
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 18
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextColor3 = currentSuit == suitName and Color3.fromRGB(0, 200, 0) or Color3.new(0, 0, 0)
        nameLabel.Parent = frame
        
        -- Resistances
        local resistanceText = string.format(
            "Crimson: %.1f [%s]\nBlue: %.1f [%s]\nPurple: %.1f [%s]\nWhite: %.1f [%s]\nGrey: %.1f [%s]",
            resistances.Crimson, getResistanceLabel(resistances.Crimson),
            resistances.Blue, getResistanceLabel(resistances.Blue),
            resistances.Purple, getResistanceLabel(resistances.Purple),
            resistances.White, getResistanceLabel(resistances.White),
            resistances.Grey, getResistanceLabel(resistances.Grey)
        )
        
        local resistanceLabel = Instance.new("TextLabel")
        resistanceLabel.Size = UDim2.new(1, -10, 0, 100)
        resistanceLabel.Position = UDim2.new(0, 5, 0, 35)
        resistanceLabel.Text = resistanceText
        resistanceLabel.Font = Enum.Font.Gotham
        resistanceLabel.TextSize = 12
        resistanceLabel.BackgroundTransparency = 1
        resistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
        resistanceLabel.TextYAlignment = Enum.TextYAlignment.Top
        resistanceLabel.TextColor3 = Color3.new(0, 0, 0)
        resistanceLabel.Parent = frame
        
        -- Equip Button
        local equipBtn = Instance.new("TextButton")
        equipBtn.Size = UDim2.new(0, 100, 0, 35)
        equipBtn.Position = UDim2.new(0.5, -50, 1, -40)
        equipBtn.Text = currentSuit == suitName and "EQUIPPED" or "EQUIP"
        equipBtn.Font = Enum.Font.GothamBold
        equipBtn.TextSize = 16
        equipBtn.BackgroundColor3 = currentSuit == suitName and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(80, 160, 255)
        equipBtn.TextColor3 = Color3.new(1, 1, 1)
        equipBtn.Parent = frame
        
        equipBtn.MouseButton1Click:Connect(function()
            currentSuit = suitName
            refreshSuitButtons()
        end)
    end
    
    suitsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, suitsListLayout.AbsoluteContentSize.Y + 20)
end

refreshSuitButtons()

-- Reset stats on respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    resetStats()
end)
