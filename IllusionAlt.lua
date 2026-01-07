-- False God Illusion Script (Client-Sided)
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
local activeOrdeals = {}
local ordealLoops = {}

-- Current Suit
local currentSuit = "Standard Suit"
local suits = {
    ["Standard Suit"] = {
        Crimson = 1,
        Blue = 1,
        Purple = 1.5,
        White = 2,
        Grey = 2
    }
}

-- Damage Type Colors
local damageColors = {
    Grey = Color3.fromRGB(150, 150, 150),
    White = Color3.new(1, 1, 1),
    Blue = Color3.fromRGB(50, 120, 220),
    Crimson = Color3.fromRGB(220, 50, 50),
    Purple = Color3.fromRGB(200, 100, 255)
}

-- Damage Type Display Names
local damageTypeNames = {
    Grey = "[GREY]",
    White = "[WHITE]",
    Blue = "[BLUE]",
    Crimson = "[RED]",
    Purple = "[PURPLE]"
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

-- Ordeals Button
local ordealsBtn = Instance.new("TextButton")
ordealsBtn.Size = UDim2.new(0, 120, 0, 40)
ordealsBtn.Position = UDim2.new(0.5, 10, 0, 10)
ordealsBtn.Text = "ORDEALS"
ordealsBtn.Font = Enum.Font.GothamBold
ordealsBtn.TextSize = 18
ordealsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ordealsBtn.TextColor3 = Color3.new(1, 1, 1)
ordealsBtn.Parent = screenGui

-- Illusions GUI
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
    ordealsGui.Visible = false
end)

-- Ordeals GUI
local ordealsGui = Instance.new("Frame")
ordealsGui.Size = UDim2.new(0, 400, 0.7, 0)
ordealsGui.Position = UDim2.new(0.5, -200, 0.15, 0)
ordealsGui.BackgroundColor3 = Color3.new(1, 1, 1)
ordealsGui.BackgroundTransparency = 0.1
ordealsGui.Visible = false
ordealsGui.Parent = screenGui

-- Close Button for Ordeals
local closeOrdealsBtn = Instance.new("TextButton")
closeOrdealsBtn.Size = UDim2.new(0, 40, 0, 40)
closeOrdealsBtn.Position = UDim2.new(1, -45, 0, 5)
closeOrdealsBtn.Text = "X"
closeOrdealsBtn.Font = Enum.Font.GothamBold
closeOrdealsBtn.TextSize = 24
closeOrdealsBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeOrdealsBtn.TextColor3 = Color3.new(1, 1, 1)
closeOrdealsBtn.Parent = ordealsGui

closeOrdealsBtn.MouseButton1Click:Connect(function()
    ordealsGui.Visible = false
end)

local ordealsScrollFrame = Instance.new("ScrollingFrame")
ordealsScrollFrame.Size = UDim2.new(1, -20, 1, -60)
ordealsScrollFrame.Position = UDim2.new(0, 10, 0, 50)
ordealsScrollFrame.BackgroundTransparency = 1
ordealsScrollFrame.BorderSizePixel = 0
ordealsScrollFrame.ScrollBarThickness = 8
ordealsScrollFrame.Parent = ordealsGui

local ordealsListLayout = Instance.new("UIListLayout")
ordealsListLayout.Padding = UDim.new(0, 10)
ordealsListLayout.Parent = ordealsScrollFrame

ordealsBtn.MouseButton1Click:Connect(function()
    ordealsGui.Visible = not ordealsGui.Visible
    illusionsGui.Visible = false
end)

-- Danger Level Colors
local dangerColors = {
    ALEPH = Color3.fromRGB(255, 0, 0),
    DAWN = Color3.fromRGB(200, 100, 255),
    NOON = Color3.fromRGB(180, 80, 235),
    DUSK = Color3.fromRGB(160, 60, 215),
    MIDNIGHT = Color3.fromRGB(140, 40, 195)
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

-- Create 3D Damage Popup
local function createDamagePopup(damageType, amount)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
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
    damageLabel.Text = string.format("%s %.1f %s", damageTypeNames[damageType] or "[DMG]", amount, getDamageLabel(amount))
    damageLabel.TextColor3 = damageColors[damageType] or Color3.new(1, 1, 1)
    damageLabel.Font = Enum.Font.GothamBold
    damageLabel.TextSize = 24
    damageLabel.TextStrokeTransparency = 0.5
    damageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    damageLabel.Parent = billboard
    
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
    local amount = math.random(minAmount * 10, maxAmount * 10) / 10
    
    local resistance = suits[currentSuit][damageType] or 1
    amount = amount * resistance
    
    local finalDamage = amount
    
    if damageType == "Grey" then
        finalDamage = calculateGreyDamage(amount)
        currentHP = math.max(0, currentHP - finalDamage)
    elseif damageType == "White" then
        finalDamage = calculateGreyDamage(amount)
        currentSP = math.max(0, currentSP - finalDamage)
    elseif damageType == "Purple" then
        currentHP = math.max(0, currentHP - finalDamage)
        currentSP = math.max(0, currentSP - finalDamage)
    elseif damageType == "Blue" then
        currentSP = math.max(0, currentSP - finalDamage)
    elseif damageType == "Crimson" then
        currentHP = math.max(0, currentHP - finalDamage)
    else
        currentHP = math.max(0, currentHP - finalDamage)
    end
    
    createDamagePopup(damageType, finalDamage)
    
    if currentSP <= 0 and not hasTrauma then
        hasTrauma = true
        warn("TRAUMA ACQUIRED!")
    end
    
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

-- Helper function to create humanoid apostle
local function createApostle(name, size, color, position)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = workspace
    
    local torso = Instance.new("Part")
    torso.Size = Vector3.new(2, 2, 1) * size
    torso.Color = color
    torso.Material = Enum.Material.Neon
    torso.Anchored = true
    torso.CanCollide = false
    torso.Position = position
    torso.Parent = model
    
    local head = Instance.new("Part")
    head.Size = Vector3.new(1.5, 1.5, 1.5) * size
    head.Shape = Enum.PartType.Ball
    head.Color = color
    head.Material = Enum.Material.Neon
    head.Anchored = true
    head.CanCollide = false
    head.Position = torso.Position + Vector3.new(0, 2 * size, 0)
    head.Parent = model
    
    local leftArm = Instance.new("Part")
    leftArm.Size = Vector3.new(1, 2, 1) * size
    leftArm.Color = color
    leftArm.Material = Enum.Material.Neon
    leftArm.Anchored = true
    leftArm.CanCollide = false
    leftArm.Position = torso.Position + Vector3.new(-1.5 * size, 0, 0)
    leftArm.Parent = model
    
    local rightArm = Instance.new("Part")
    rightArm.Size = Vector3.new(1, 2, 1) * size
    rightArm.Color = color
    rightArm.Material = Enum.Material.Neon
    rightArm.Anchored = true
    rightArm.CanCollide = false
    rightArm.Position = torso.Position + Vector3.new(1.5 * size, 0, 0)
    rightArm.Parent = model
    
    local leftLeg = Instance.new("Part")
    leftLeg.Size = Vector3.new(1, 2, 1) * size
    leftLeg.Color = color
    leftLeg.Material = Enum.Material.Neon
    leftLeg.Anchored = true
    leftLeg.CanCollide = false
    leftLeg.Position = torso.Position + Vector3.new(-0.5 * size, -2 * size, 0)
    leftLeg.Parent = model
    
    local rightLeg = Instance.new("Part")
    rightLeg.Size = Vector3.new(1, 2, 1) * size
    rightLeg.Color = color
    rightLeg.Material = Enum.Material.Neon
    rightLeg.Anchored = true
    rightLeg.CanCollide = false
    rightLeg.Position = torso.Position + Vector3.new(0.5 * size, -2 * size, 0)
    rightLeg.Parent = model
    
    return model, torso, head, leftArm, rightArm, leftLeg, rightLeg
end

-- Illusion: False God
local function startFalseGod()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    -- Create giant eye
    local eyeCenter = hrp.Position + Vector3.new(0, 200, 0)
    
    local eyeball = Instance.new("Part")
    eyeball.Shape = Enum.PartType.Ball
    eyeball.Size = Vector3.new(50, 50, 50)
    eyeball.Color = Color3.new(1, 1, 1)
    eyeball.Material = Enum.Material.SmoothPlastic
    eyeball.Anchored = true
    eyeball.CanCollide = false
    eyeball.Position = eyeCenter
    eyeball.Parent = workspace
    
    local pupil = Instance.new("Part")
    pupil.Shape = Enum.PartType.Ball
    pupil.Size = Vector3.new(25, 25, 25)
    pupil.Color = Color3.fromRGB(0, 150, 255)
    pupil.Material = Enum.Material.Neon
    pupil.Anchored = true
    pupil.CanCollide = false
    pupil.Position = eyeCenter
    pupil.Parent = eyeball
    
    -- 200 stud forcefield
    local forcefield = Instance.new("Part")
    forcefield.Shape = Enum.PartType.Ball
    forcefield.Size = Vector3.new(400, 400, 400)
    forcefield.Color = Color3.fromRGB(100, 200, 255)
    forcefield.Material = Enum.Material.ForceField
    forcefield.Transparency = 0.7
    forcefield.CanCollide = false
    forcefield.Anchored = true
    forcefield.Position = eyeCenter
    forcefield.Parent = workspace
    
    -- Create 3 Sword Apostles
    local swordApostles = {}
    for i = 1, 3 do
        local angle = (i / 3) * math.pi * 2
        local offset = Vector3.new(math.cos(angle) * 15, 0, math.sin(angle) * 15)
        local apostle, torso, head, la, ra, ll, rl = 
            createApostle("SwordApostle" .. i, 1.5, Color3.fromRGB(255, 215, 0), eyeCenter + offset)
        
        local sword = Instance.new("Part")
        sword.Size = Vector3.new(0.5, 6, 0.5)
        sword.Color = Color3.fromRGB(192, 192, 192)
        sword.Material = Enum.Material.Metal
        sword.Anchored = true
        sword.CanCollide = false
        sword.Parent = apostle
        
        table.insert(swordApostles, {
            model = apostle,
            torso = torso,
            head = head,
            leftArm = la,
            rightArm = ra,
            leftLeg = ll,
            rightLeg = rl,
            sword = sword,
            angle = angle,
            followingPlayer = false,
            attackCount = 0,
            attackTimer = 0
        })
    end
    
    -- Create 2 Spear Apostles
    local spearApostles = {}
    for i = 1, 2 do
        local apostle, torso, head, la, ra, ll, rl = 
            createApostle("SpearApostle" .. i, 1.5, Color3.fromRGB(255, 100, 100), eyeCenter + Vector3.new(i * 20, 0, 0))
        
        local spear = Instance.new("Part")
        spear.Size = Vector3.new(0.3, 8, 0.3)
        spear.Color = Color3.fromRGB(139, 69, 19)
        spear.Material = Enum.Material.Wood
        spear.Anchored = true
        spear.CanCollide = false
        spear.Parent = apostle
        
        local spearTip = Instance.new("Part")
        spearTip.Size = Vector3.new(0.5, 1, 0.5)
        spearTip.Color = Color3.fromRGB(192, 192, 192)
        spearTip.Material = Enum.Material.Metal
        spearTip.Anchored = true
        spearTip.CanCollide = false
        spearTip.Parent = apostle
        
        table.insert(spearApostles, {
            model = apostle,
            torso = torso,
            head = head,
            leftArm = la,
            rightArm = ra,
            leftLeg = ll,
            rightLeg = rl,
            spear = spear,
            spearTip = spearTip,
            dashTimer = 0,
            isDashing = false,
            dashDirection = Vector3.new(),
            dashTime = 0
        })
    end
    
    -- Create 1 Staff Apostle
    local staffApostle, staffTorso, staffHead, staffLA, staffRA, staffLL, staffRL = 
        createApostle("StaffApostle", 1.5, Color3.fromRGB(150, 100, 255), eyeCenter + Vector3.new(-30, 0, 0))
    
    local staff = Instance.new("Part")
    staff.Size = Vector3.new(0.5, 7, 0.5)
    staff.Color = Color3.fromRGB(139, 69, 19)
    staff.Material = Enum.Material.Wood
    staff.Anchored = true
    staff.CanCollide = false
    staff.Parent = staffApostle
    
    local staffOrb = Instance.new("Part")
    staffOrb.Shape = Enum.PartType.Ball
    staffOrb.Size = Vector3.new(1.5, 1.5, 1.5)
    staffOrb.Color = Color3.fromRGB(150, 100, 255)
    staffOrb.Material = Enum.Material.Neon
    staffOrb.Anchored = true
    staffOrb.CanCollide = false
    staffOrb.Parent = staffApostle
    
    local staffTimer = 0
    local staffBeamWarning = nil
    
    -- Create 3 Grapple Apostles
    local grappleApostles = {}
    for i = 1, 3 do
        local apostle, torso, head, la, ra, ll, rl = 
            createApostle("GrappleApostle" .. i, 1.5, Color3.fromRGB(100, 255, 100), eyeCenter + Vector3.new(0, 0, i * 20))
        
        table.insert(grappleApostles, {
            model = apostle,
            torso = torso,
            head = head,
            leftArm = la,
            rightArm = ra,
            leftLeg = ll,
            rightLeg = rl,
            hookTimer = 0,
            activeHook = nil
        })
    end
    
    -- Create 3 Gun Apostles
    local gunApostles = {}
    for i = 1, 3 do
        local apostle, torso, head, la, ra, ll, rl = 
            createApostle("GunApostle" .. i, 1.5, Color3.fromRGB(150, 150, 150), eyeCenter + Vector3.new(0, 0, -i * 20))
        
        local greyGun = Instance.new("Part")
        greyGun.Size = Vector3.new(0.5, 0.5, 1.5)
        greyGun.Color = Color3.fromRGB(100, 100, 100)
        greyGun.Material = Enum.Material.Metal
        greyGun.Anchored = true
        greyGun.CanCollide = false
        greyGun.Parent = apostle
        
        local whiteGun = Instance.new("Part")
        whiteGun.Size = Vector3.new(0.5, 0.5, 1.5)
        whiteGun.Color = Color3.new(1, 1, 1)
        whiteGun.Material = Enum.Material.Metal
        whiteGun.Anchored = true
        whiteGun.CanCollide = false
        whiteGun.Parent = apostle
        
        table.insert(gunApostles, {
            model = apostle,
            torso = torso,
            head = head,
            leftArm = la,
            rightArm = ra,
            leftLeg = ll,
            rightLeg = rl,
            greyGun = greyGun,
            whiteGun = whiteGun,
            shootTimer = 0,
            shootCount = 0,
            isBarraging = false,
            barrageTimer = 0,
            barrageBulletCount = 0,
            barrageType = ""
        })
    end
    
    -- Timers
    local ffDamageTimer = 0
    local ability1Timer = 0
    local ability2Timer = 0
    local ability3Angle = 0
    local ability4Timer = 0
    
    -- Update body parts helper
    local function updateBodyParts(torso, head, leftArm, rightArm, leftLeg, rightLeg, size)
        head.Position = torso.Position + Vector3.new(0, 2 * size, 0)
        leftArm.Position = torso.Position + torso.CFrame.RightVector * (-1.5 * size)
        rightArm.Position = torso.Position + torso.CFrame.RightVector * (1.5 * size)
        leftLeg.Position = torso.Position + Vector3.new(-0.5 * size, -2 * size, 0)
        rightLeg.Position = torso.Position + Vector3.new(0.5 * size, -2 * size, 0)
    end
    
    -- Move towards player helper
    local function moveTowardsPlayer(torso, speed, dt)
        local currentChar = player.Character
        if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
            local playerPos = currentChar.HumanoidRootPart.Position
            local direction = (playerPos - torso.Position).Unit
            torso.Position = torso.Position + direction * speed * dt
            
            local lookAt = Vector3.new(playerPos.X, torso.Position.Y, playerPos.Z)
            torso.CFrame = CFrame.new(torso.Position, lookAt)
            
            return playerPos
        end
        return nil
    end
    
    -- Main loop
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeIllusions["False God"] then
            if eyeball and eyeball.Parent then eyeball:Destroy() end
            if forcefield and forcefield.Parent then forcefield:Destroy() end
            for _, sa in ipairs(swordApostles) do
                if sa.model and sa.model.Parent then sa.model:Destroy() end
            end
            for _, spa in ipairs(spearApostles) do
                if spa.model and spa.model.Parent then spa.model:Destroy() end
            end
            if staffApostle and staffApostle.Parent then staffApostle:Destroy() end
            for _, ga in ipairs(grappleApostles) do
                if ga.model and ga.model.Parent then ga.model:Destroy() end
            end
            for _, guna in ipairs(gunApostles) do
                if guna.model and guna.model.Parent then guna.model:Destroy() end
            end
            loop:Disconnect()
            return
        end
        
        local currentChar = player.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        local playerPos = currentChar.HumanoidRootPart.Position
        
        -- Pupil tracks player
        local dirToPlayer = (playerPos - eyeCenter).Unit
        pupil.Position = eyeCenter + dirToPlayer * 10
        
        -- Forcefield damage
        local distToEye = (playerPos - eyeCenter).Magnitude
        if distToEye <= 200 then
            ffDamageTimer = ffDamageTimer + dt
            if ffDamageTimer >= 1 then
                ffDamageTimer = 0
                applyDamage("Grey", 30, 45)
                applyDamage("White", 30, 45)
            end
        else
            ffDamageTimer = 0
        end
        
        -- Ability 1: Single beam every 5 seconds
        ability1Timer = ability1Timer + dt
        if ability1Timer >= 5 then
            ability1Timer = 0
            task.spawn(function()
                local beam = Instance.new("Part")
                beam.Size = Vector3.new(10, 400, 10)
                beam.Color = Color3.fromRGB(255, 255, 255)
                beam.Material = Enum.Material.Neon
                beam.Transparency = 0.3
                beam.CanCollide = false
                beam.Anchored = true
                beam.Position = playerPos + Vector3.new(0, 200, 0)
                beam.Parent = workspace
                
                local dist = (playerPos - beam.Position).Magnitude
                if dist <= 5 then
                    applyDamage("White", 50, 60)
                    applyDamage("Grey", 50, 60)
                end
                
                TweenService:Create(beam, TweenInfo.new(2), {Transparency = 1}):Play()
                task.delay(2, function()
                    if beam and beam.Parent then beam:Destroy() end
                end)
            end)
        end
        
        -- Ability 2: Circle beams every 3 seconds
        ability2Timer = ability2Timer + dt
        if ability2Timer >= 3 then
            ability2Timer = 0
            task.spawn(function()
                local beamCount = math.random(10, 10)
                local spawnDist = math.random(15, 20)
                
                for i = 1, beamCount do
                    local angle = (i / beamCount) * math.pi * 2
                    local offset = Vector3.new(math.cos(angle) * spawnDist, 0, math.sin(angle) * spawnDist)
                    local beamPos = eyeCenter + offset
                    
                    local beam = Instance.new("Part")
                    beam.Size = Vector3.new(8, 400, 8)
                    beam.Color = Color3.fromRGB(200, 200, 255)
                    beam.Material = Enum.Material.Neon
                    beam.Transparency = 0.3
                    beam.CanCollide = false
                    beam.Anchored = true
                    beam.Position = beamPos
                    beam.Parent = workspace
                    
                    local distToBeam = (playerPos - beamPos).Magnitude
                    if distToBeam <= 4 then
                        applyDamage("White", 25, 40)
                        applyDamage("Grey", 25, 40)
                    end
                    
                    TweenService:Create(beam, TweenInfo.new(2), {Transparency = 1}):Play()
                    task.delay(2, function()
                        if beam and beam.Parent then beam:Destroy() end
                    end)
                    
                    task.wait(0.1)
                end
            end)
        end
        
        -- Ability 3: 2 Spinning beams
        ability3Angle = ability3Angle + dt * 2
        local spinDist1 = math.random(100, 250)
        local spinDist2 = math.random(100, 250)
        
        local spin1Pos = eyeCenter + Vector3.new(math.cos(ability3Angle) * spinDist1, 0, math.sin(ability3Angle) * spinDist1)
        local spin2Pos = eyeCenter + Vector3.new(math.cos(ability3Angle + math.pi) * spinDist2, 0, math.sin(ability3Angle + math.pi) * spinDist2)
        
        -- Check collision with spinning beams (invisible damage zones)
        local distToSpin1 = (playerPos - spin1Pos).Magnitude
        local distToSpin2 = (playerPos - spin2Pos).Magnitude
        
        if distToSpin1 <= 5 or distToSpin2 <= 5 then
            applyDamage("White", 30, 50)
            applyDamage("Grey", 30, 50)
        end
        
        -- Ability 4: Dot warning beams every 1.5 seconds
        ability4Timer = ability4Timer + dt
        if ability4Timer >= 1.5 then
            ability4Timer = 0
            task.spawn(function()
                local dots = {}
                for i = 1, 15 do
                    local randomDist = math.random(0, 30)
                    local randomAngle = math.random() * math.pi * 2
                    local dotPos = eyeCenter + Vector3.new(math.cos(randomAngle) * randomDist, 0, math.sin(randomAngle) * randomDist)
                    
                    local dot = Instance.new("Part")
                    dot.Size = Vector3.new(2, 2, 2)
                    dot.Shape = Enum.PartType.Ball
                    dot.Color = Color3.fromRGB(255, 0, 0)
                    dot.Material = Enum.Material.Neon
                    dot.Transparency = 0.5
                    dot.CanCollide = false
                    dot.Anchored = true
                    dot.Position = dotPos
                    dot.Parent = workspace
                    
                    table.insert(dots, dot)
                end
                
                task.wait(2)
                
                for _, dot in ipairs(dots) do
                    if dot and dot.Parent then
                        local beam = Instance.new("Part")
                        beam.Size = Vector3.new(6, 400, 6)
                        beam.Color = Color3.fromRGB(255, 100, 100)
                        beam.Material = Enum.Material.Neon
                        beam.Transparency = 0.3
                        beam.CanCollide = false
                        beam.Anchored = true
                        beam.Position = dot.Position + Vector3.new(0, 200, 0)
                        beam.Parent = workspace
                        
                        local distToBeam = (playerPos - dot.Position).Magnitude
                        if distToBeam <= 3 then
                            applyDamage("White", 30, 50)
                            applyDamage("Grey", 30, 50)
                        end
                        
                        dot:Destroy()
                        
                        TweenService:Create(beam, TweenInfo.new(2), {Transparency = 1}):Play()
                        task.delay(2, function()
                            if beam and beam.Parent then beam:Destroy() end
                        end)
                    end
                end
            end)
        end
        
        -- Sword Apostles behavior
        for i, sa in ipairs(swordApostles) do
            local distToPlayer = (playerPos - sa.torso.Position).Magnitude
            local distToEyeCenter = (sa.torso.Position - eyeCenter).Magnitude
            
            if distToPlayer <= 30 and not sa.followingPlayer then
                sa.followingPlayer = true
            elseif distToPlayer > 30 and sa.followingPlayer then
                sa.followingPlayer = false
            end
            
            if sa.followingPlayer then
                moveTowardsPlayer(sa.torso, 20, dt)
                sa.attackTimer = sa.attackTimer + dt
                
                if sa.attackTimer >= 1 and distToPlayer <= 5 then
                    sa.attackTimer = 0
                    sa.attackCount = sa.attackCount + 1
                    applyDamage("White", 45, 80)
                    applyDamage("Grey", 45, 80)
                    
                    if sa.attackCount >= 3 then
                        sa.attackCount = 0
                        -- Spawn 3 flying slashes
                        for j = 1, 3 do
                            task.spawn(function()
                                local slash = Instance.new("Part")
                                slash.Size = Vector3.new(3, 0.5, 5)
                                slash.Color = Color3.fromRGB(255, 0, 0)
                                slash.Material = Enum.Material.Neon
                                slash.Transparency = 0.3
                                slash.CanCollide = false
                                slash.Anchored = false
                                slash.Position = sa.torso.Position + Vector3.new(0, j * 2, 0)
                                slash.CFrame = sa.torso.CFrame
                                slash.Parent = workspace
                                
                                local bodyVel = Instance.new("BodyVelocity")
                                bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
                                bodyVel.Velocity = sa.torso.CFrame.LookVector * 60
                                bodyVel.Parent = slash
                                
                                local touchConnection
                                touchConnection = slash.Touched:Connect(function(hit)
                                    if hit.Parent == currentChar then
                                        applyDamage("Grey", 10, 30)
                                        applyDamage("White", 10, 30)
                                        touchConnection:Disconnect()
                                        slash:Destroy()
                                    end
                                end)
                                
                                task.delay(3, function()
                                    if slash and slash.Parent then slash:Destroy() end
                                end)
                            end)
                        end
                    end
                end
            else
                -- Wander around eye
                sa.angle = sa.angle + dt * 0.3
                local wanderDist = math.random(0, 20)
                local offset = Vector3.new(math.cos(sa.angle) * wanderDist, 0, math.sin(sa.angle) * wanderDist)
                sa.torso.Position = eyeCenter + offset
                local lookAt = Vector3.new(eyeCenter.X, sa.torso.Position.Y, eyeCenter.Z)
                sa.torso.CFrame = CFrame.new(sa.torso.Position, lookAt)
            end
            
            updateBodyParts(sa.torso, sa.head, sa.leftArm, sa.rightArm, sa.leftLeg, sa.rightLeg, 1.5)
            sa.sword.CFrame = CFrame.new(sa.rightArm.Position + Vector3.new(0, -2, 0), sa.rightArm.Position + Vector3.new(0, -4, 0))
        end
        
        -- Spear Apostles behavior
        for i, spa in ipairs(spearApostles) do
            if spa.isDashing then
                spa.dashTime = spa.dashTime + dt
                spa.torso.Position = spa.torso.Position + spa.dashDirection * 30 * dt
                
                local distToPlayer = (playerPos - spa.torso.Position).Magnitude
                if distToPlayer <= 5 then
                    applyDamage("Grey", 45, 50)
                    applyDamage("White", 45, 50)
                end
                
                if spa.dashTime >= 1.5 then
                    spa.isDashing = false
                    spa.dashTime = 0
                end
            else
                moveTowardsPlayer(spa.torso, 20, dt)
                spa.dashTimer = spa.dashTimer + dt
                
                if spa.dashTimer >= 3 then
                    spa.dashTimer = 0
                    spa.isDashing = true
                    spa.dashDirection = (playerPos - spa.torso.Position).Unit
                end
            end
            
            updateBodyParts(spa.torso, spa.head, spa.leftArm, spa.rightArm, spa.leftLeg, spa.rightLeg, 1.5)
            spa.spear.CFrame = CFrame.new(spa.rightArm.Position + Vector3.new(0, -3, 0), spa.rightArm.Position + Vector3.new(0, -5, 0))
            spa.spearTip.Position = spa.spear.Position + spa.spear.CFrame.UpVector * -4.5
        end
        
        -- Staff Apostle behavior
        moveTowardsPlayer(staffTorso, 15, dt)
        updateBodyParts(staffTorso, staffHead, staffLA, staffRA, staffLL, staffRL, 1.5)
        staff.CFrame = CFrame.new(staffRA.Position + Vector3.new(0, -2.5, 0), staffRA.Position + Vector3.new(0, -4, 0))
        staffOrb.Position = staff.Position + staff.CFrame.UpVector * -4
        
        staffTimer = staffTimer + dt
        if staffTimer >= 10 then
            staffTimer = 0
            task.spawn(function()
                -- Create warning beam
                local warningBeam = Instance.new("Part")
                warningBeam.Size = Vector3.new(30, 400, 30)
                warningBeam.Color = Color3.fromRGB(150, 100, 255)
                warningBeam.Material = Enum.Material.Neon
                warningBeam.Transparency = 0.8
                warningBeam.CanCollide = false
                warningBeam.Anchored = true
                warningBeam.Position = playerPos + Vector3.new(0, 200, 0)
                warningBeam.Parent = workspace
                
                task.wait(2)
                
                warningBeam.Transparency = 0
                
                local distToBeam = (playerPos - warningBeam.Position).Magnitude
                local originalSpeed = currentChar.Humanoid.WalkSpeed
                
                if distToBeam <= 15 then
                    currentChar.Humanoid.WalkSpeed = math.max(0, originalSpeed - 10)
                    
                    local damageLoop = RunService.Heartbeat:Connect(function()
                        if not warningBeam or not warningBeam.Parent then return end
                        local currentDist = (currentChar.HumanoidRootPart.Position - warningBeam.Position).Magnitude
                        if currentDist <= 15 then
                            applyDamage("Grey", 10, 20)
                            applyDamage("White", 10, 20)
                            applyDamage("Crimson", 10, 20)
                            applyDamage("Purple", 10, 20)
                            applyDamage("Blue", 10, 20)
                        end
                    end)
                    
                    task.wait(3)
                    damageLoop:Disconnect()
                    currentChar.Humanoid.WalkSpeed = originalSpeed
                end
                
                TweenService:Create(warningBeam, TweenInfo.new(2), {Transparency = 1}):Play()
                task.delay(2, function()
                    if warningBeam and warningBeam.Parent then warningBeam:Destroy() end
                end)
            end)
        end
        
        -- Grapple Apostles behavior
        for i, ga in ipairs(grappleApostles) do
            moveTowardsPlayer(ga.torso, 18, dt)
            updateBodyParts(ga.torso, ga.head, ga.leftArm, ga.rightArm, ga.leftLeg, ga.rightLeg, 1.5)
            
            ga.hookTimer = ga.hookTimer + dt
            if ga.hookTimer >= 5 then
                ga.hookTimer = 0
                task.spawn(function()
                    local hookDir = (playerPos - ga.torso.Position).Unit
                    local hook = Instance.new("Part")
                    hook.Size = Vector3.new(0.5, 0.5, 2)
                    hook.Color = Color3.fromRGB(100, 100, 100)
                    hook.Material = Enum.Material.Metal
                    hook.CanCollide = false
                    hook.Anchored = false
                    hook.Position = ga.torso.Position
                    hook.CFrame = CFrame.new(ga.torso.Position, playerPos)
                    hook.Parent = workspace
                    
                    local bodyVel = Instance.new("BodyVelocity")
                    bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
                    bodyVel.Velocity = hookDir * 80
                    bodyVel.Parent = hook
                    
                    local rope = Instance.new("Part")
                    rope.Size = Vector3.new(0.2, 0.2, 1)
                    rope.Color = Color3.fromRGB(80, 80, 80)
                    rope.Material = Enum.Material.Metal
                    rope.CanCollide = false
                    rope.Anchored = true
                    rope.Parent = workspace
                    
                    local distTraveled = 0
                    local caught = false
                    
                    local hookLoop = RunService.Heartbeat:Connect(function(dt2)
                        if not hook or not hook.Parent then return end
                        
                        distTraveled = (hook.Position - ga.torso.Position).Magnitude
                        
                        -- Update rope
                        rope.Size = Vector3.new(0.2, 0.2, distTraveled)
                        rope.CFrame = CFrame.new(ga.torso.Position, hook.Position) * CFrame.new(0, 0, -distTraveled / 2)
                        
                        -- Check if caught player
                        local distToPlayer = (hook.Position - currentChar.HumanoidRootPart.Position).Magnitude
                        if distToPlayer <= 3 and not caught then
                            caught = true
                            bodyVel.Velocity = (ga.torso.Position - hook.Position).Unit * 60
                            
                            -- Drag player
                            local dragVel = Instance.new("BodyVelocity")
                            dragVel.MaxForce = Vector3.new(4000, 4000, 4000)
                            dragVel.Velocity = (ga.torso.Position - currentChar.HumanoidRootPart.Position).Unit * 50
                            dragVel.Parent = currentChar.HumanoidRootPart
                            
                            task.wait(1)
                            
                            if dragVel and dragVel.Parent then dragVel:Destroy() end
                            applyDamage("Grey", 20, 50)
                            applyDamage("White", 20, 50)
                            applyDamage("Purple", 20, 50)
                            applyDamage("Crimson", 20, 50)
                            applyDamage("Blue", 20, 50)
                            
                            hook:Destroy()
                            rope:Destroy()
                        end
                        
                        if distTraveled >= 50 then
                            hook:Destroy()
                            rope:Destroy()
                        end
                    end)
                    
                    task.delay(2, function()
                        hookLoop:Disconnect()
                        if hook and hook.Parent then hook:Destroy() end
                        if rope and rope.Parent then rope:Destroy() end
                    end)
                end)
            end
        end
        
        -- Gun Apostles behavior
        for i, guna in ipairs(gunApostles) do
            moveTowardsPlayer(guna.torso, 15, dt)
            updateBodyParts(guna.torso, guna.head, guna.leftArm, guna.rightArm, guna.leftLeg, guna.rightLeg, 1.5)
            
            guna.greyGun.CFrame = CFrame.new(guna.leftArm.Position + Vector3.new(0, -1, 0), playerPos)
            guna.whiteGun.CFrame = CFrame.new(guna.rightArm.Position + Vector3.new(0, -1, 0), playerPos)
            
            if guna.isBarraging then
                guna.barrageTimer = guna.barrageTimer + dt
                if guna.barrageTimer >= 0.05 then
                    guna.barrageTimer = 0
                    guna.barrageBulletCount = guna.barrageBulletCount + 1
                    
                    local gun = nil
                    local damageType = ""
                    
                    if guna.barrageType == "grey" then
                        gun = guna.greyGun
                        damageType = "Grey"
                    elseif guna.barrageType == "white" then
                        gun = guna.whiteGun
                        damageType = "White"
                    elseif guna.barrageType == "both" then
                        gun = math.random() > 0.5 and guna.greyGun or guna.whiteGun
                        damageType = gun == guna.greyGun and "Grey" or "White"
                    end
                    
                    task.spawn(function()
                        local bullet = Instance.new("Part")
                        bullet.Size = Vector3.new(0.3, 0.3, 0.8)
                        bullet.Color = damageType == "Grey" and Color3.fromRGB(150, 150, 150) or Color3.new(1, 1, 1)
                        bullet.Material = Enum.Material.Neon
                        bullet.CanCollide = false
                        bullet.Anchored = false
                        bullet.Position = gun.Position
                        bullet.CFrame = gun.CFrame
                        bullet.Parent = workspace
                        
                        local bodyVel = Instance.new("BodyVelocity")
                        bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
                        bodyVel.Velocity = (playerPos - gun.Position).Unit * 100
                        bodyVel.Parent = bullet
                        
                        local touchConnection
                        touchConnection = bullet.Touched:Connect(function(hit)
                            if hit.Parent == currentChar then
                                applyDamage(damageType, 15, 25)
                                touchConnection:Disconnect()
                                bullet:Destroy()
                            end
                        end)
                        
                        task.delay(2, function()
                            if bullet and bullet.Parent then bullet:Destroy() end
                        end)
                    end)
                    
                    if guna.barrageBulletCount >= 30 then
                        guna.isBarraging = false
                        guna.barrageBulletCount = 0
                        guna.shootCount = 0
                    end
                end
            else
                guna.shootTimer = guna.shootTimer + dt
                if guna.shootTimer >= 1 then
                    guna.shootTimer = 0
                    guna.shootCount = guna.shootCount + 1
                    
                    local gun = guna.shootCount % 2 == 1 and guna.greyGun or guna.whiteGun
                    local damageType = gun == guna.greyGun and "Grey" or "White"
                    
                    task.spawn(function()
                        local bullet = Instance.new("Part")
                        bullet.Size = Vector3.new(0.3, 0.3, 0.8)
                        bullet.Color = damageType == "Grey" and Color3.fromRGB(150, 150, 150) or Color3.new(1, 1, 1)
                        bullet.Material = Enum.Material.Neon
                        bullet.CanCollide = false
                        bullet.Anchored = false
                        bullet.Position = gun.Position
                        bullet.CFrame = gun.CFrame
                        bullet.Parent = workspace
                        
                        local bodyVel = Instance.new("BodyVelocity")
                        bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
                        bodyVel.Velocity = (playerPos - gun.Position).Unit * 100
                        bodyVel.Parent = bullet
                        
                        local touchConnection
                        touchConnection = bullet.Touched:Connect(function(hit)
                            if hit.Parent == currentChar then
                                applyDamage(damageType, 15, 25)
                                touchConnection:Disconnect()
                                bullet:Destroy()
                            end
                        end)
                        
                        task.delay(2, function()
                            if bullet and bullet.Parent then bullet:Destroy() end
                        end)
                    end)
                    
                    if guna.shootCount >= 10 then
                        guna.isBarraging = true
                        if guna.shootCount == 10 then
                            guna.barrageType = "grey"
                        elseif guna.shootCount == 20 then
                            guna.barrageType = "white"
                        elseif guna.shootCount == 30 then
                            guna.barrageType = "both"
                        end
                    end
                end
            end
        end
    end)
    
    illusionLoops["False God"] = {loop}
end

-- Function to show ordeal intro
local function showOrdealIntro(ordealName, descName, introDesc)
    -- Wait a frame to ensure GUI is loaded
    task.wait()
    
    local introFrame = Instance.new("Frame")
    introFrame.Size = UDim2.new(0, 600, 0, 200)
    introFrame.Position = UDim2.new(0.5, -300, 0.5, -100)
    introFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    introFrame.BackgroundTransparency = 0.2
    introFrame.BorderSizePixel = 3
    introFrame.BorderColor3 = Color3.fromRGB(200, 100, 255)
    introFrame.Parent = screenGui
    
    local ordealLabel = Instance.new("TextLabel")
    ordealLabel.Size = UDim2.new(1, -20, 0, 40)
    ordealLabel.Position = UDim2.new(0, 10, 0, 10)
    ordealLabel.Text = ordealName
    ordealLabel.Font = Enum.Font.GothamBold
    ordealLabel.TextSize = 28
    ordealLabel.TextColor3 = Color3.fromRGB(200, 100, 255)
    ordealLabel.BackgroundTransparency = 1
    ordealLabel.Parent = introFrame
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0, 30)
    descLabel.Position = UDim2.new(0, 10, 0, 55)
    descLabel.Text = descName
    descLabel.Font = Enum.Font.GothamBold
    descLabel.TextSize = 20
    descLabel.TextColor3 = Color3.new(1, 1, 1)
    descLabel.BackgroundTransparency = 1
    descLabel.Parent = introFrame
    
    local introLabel = Instance.new("TextLabel")
    introLabel.Size = UDim2.new(1, -20, 0, 100)
    introLabel.Position = UDim2.new(0, 10, 0, 90)
    introLabel.Text = '"' .. introDesc .. '"'
    introLabel.Font = Enum.Font.Gotham
    introLabel.TextSize = 16
    introLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    introLabel.BackgroundTransparency = 1
    introLabel.TextWrapped = true
    introLabel.Parent = introFrame
    
    task.wait(3)
    
    -- Check if frame still exists before tweening
    if introFrame and introFrame.Parent then
        TweenService:Create(introFrame, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
        TweenService:Create(ordealLabel, TweenInfo.new(1), {TextTransparency = 1}):Play()
        TweenService:Create(descLabel, TweenInfo.new(1), {TextTransparency = 1}):Play()
        TweenService:Create(introLabel, TweenInfo.new(1), {TextTransparency = 1}):Play()
        
        task.delay(1, function()
            if introFrame and introFrame.Parent then
                introFrame:Destroy()
            end
        end)
    end
end

-- Ordeal: Dawn of Purple
local function startDawnOfPurple()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    showOrdealIntro("Dawn of Purple", "Desire", "We crave love, we will do anything to get it.")
    
    local hrp = char.HumanoidRootPart
    local desiringSouls = {}
    
    -- Spawn 10 Desiring Souls
    for i = 1, 10 do
        local angle = (i / 10) * math.pi * 2
        local dist = math.random(30, 60)
        local spawnPos = hrp.Position + Vector3.new(math.cos(angle) * dist, 10, math.sin(angle) * dist)
        
        -- Create floating humanoid with big brain
        local soul = Instance.new("Model")
        soul.Name = "DesiringSoul"
        soul.Parent = workspace
        
        local torso = Instance.new("Part")
        torso.Size = Vector3.new(2, 2, 1)
        torso.Color = Color3.fromRGB(200, 100, 255)
        torso.Material = Enum.Material.Neon
        torso.Anchored = true
        torso.CanCollide = false
        torso.Position = spawnPos
        torso.Parent = soul
        
        local brain = Instance.new("Part")
        brain.Size = Vector3.new(3, 3, 3)
        brain.Shape = Enum.PartType.Ball
        brain.Color = Color3.fromRGB(150, 50, 200)
        brain.Material = Enum.Material.Neon
        brain.Anchored = true
        brain.CanCollide = false
        brain.Position = torso.Position + Vector3.new(0, 3, 0)
        brain.Parent = soul
        
        table.insert(desiringSouls, {
            model = soul,
            torso = torso,
            brain = brain,
            pulseTimer = 0
        })
    end
    
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeOrdeals["Dawn of Purple"] then
            for _, soul in ipairs(desiringSouls) do
                if soul.model and soul.model.Parent then soul.model:Destroy() end
            end
            loop:Disconnect()
            return
        end
        
        local currentChar = player.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        local playerPos = currentChar.HumanoidRootPart.Position
        
        for _, soul in ipairs(desiringSouls) do
            soul.pulseTimer = soul.pulseTimer + dt
            
            -- Float up and down
            soul.torso.Position = soul.torso.Position + Vector3.new(0, math.sin(tick() * 2) * 0.01, 0)
            soul.brain.Position = soul.torso.Position + Vector3.new(0, 3, 0)
            
            if soul.pulseTimer >= 3 then
                soul.pulseTimer = 0
                
                task.spawn(function()
                    local forcefield = Instance.new("Part")
                    forcefield.Shape = Enum.PartType.Ball
                    forcefield.Size = Vector3.new(60, 60, 60)
                    forcefield.Color = Color3.fromRGB(200, 100, 255)
                    forcefield.Material = Enum.Material.ForceField
                    forcefield.Transparency = 0.5
                    forcefield.CanCollide = false
                    forcefield.Anchored = true
                    forcefield.Position = soul.torso.Position
                    forcefield.Parent = workspace
                    
                    local distToSoul = (playerPos - soul.torso.Position).Magnitude
                    if distToSoul <= 30 then
                        applyDamage("Purple", 5, 10)
                        
                        -- Force walk to soul
                        if currentChar:FindFirstChild("Humanoid") then
                            local humanoidRef = currentChar.Humanoid
                            local startTime = tick()
                            local forceWalkLoop = RunService.Heartbeat:Connect(function()
                                if tick() - startTime >= 2 or not forcefield or not forcefield.Parent then return end
                                if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
                                    local dir = (soul.torso.Position - currentChar.HumanoidRootPart.Position).Unit
                                    humanoidRef:Move(dir)
                                end
                            end)
                            
                            task.delay(2, function()
                                forceWalkLoop:Disconnect()
                            end)
                        end
                    end
                    
                    TweenService:Create(forcefield, TweenInfo.new(2), {Transparency = 1}):Play()
                    task.delay(2, function()
                        if forcefield and forcefield.Parent then forcefield:Destroy() end
                    end)
                end)
            end
        end
    end)
    
    ordealLoops["Dawn of Purple"] = {loop}
end

-- Ordeal: Noon of Purple
local function startNoonOfPurple()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    showOrdealIntro("Noon of Purple", "Grant us Love", "We've found a new meaning of love, We began to study and study about love endlessly.")
    
    local hrp = char.HumanoidRootPart
    local statues = {}
    local lovedOnes = {}
    
    -- Spawn 5 statues
    for i = 1, 5 do
        local angle = (i / 5) * math.pi * 2
        local dist = math.random(50, 100)
        local statuePos = hrp.Position + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
        
        local statue = Instance.new("Part")
        statue.Size = Vector3.new(5, 10, 5)
        statue.Color = Color3.fromRGB(150, 100, 200)
        statue.Material = Enum.Material.Marble
        statue.Anchored = true
        statue.CanCollide = false
        statue.Position = statuePos
        statue.Parent = workspace
        
        table.insert(statues, {
            part = statue,
            spawnTimer = 0,
            shootTimer = 0
        })
    end
    
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeOrdeals["Noon of Purple"] then
            for _, statue in ipairs(statues) do
                if statue.part and statue.part.Parent then statue.part:Destroy() end
            end
            for _, loved in ipairs(lovedOnes) do
                if loved.model and loved.model.Parent then loved.model:Destroy() end
            end
            loop:Disconnect()
            return
        end
        
        local currentChar = player.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        local playerPos = currentChar.HumanoidRootPart.Position
        
        for _, statue in ipairs(statues) do
            statue.spawnTimer = statue.spawnTimer + dt
            statue.shootTimer = statue.shootTimer + dt
            
            local distToStatue = (playerPos - statue.part.Position).Magnitude
            
            -- Spawn Desiring Soul every 5 seconds
            if statue.spawnTimer >= 5 then
                statue.spawnTimer = 0
                
                local soul = Instance.new("Model")
                soul.Name = "DesiringSoul"
                soul.Parent = workspace
                
                local torso = Instance.new("Part")
                torso.Size = Vector3.new(2, 2, 1)
                torso.Color = Color3.fromRGB(200, 100, 255)
                torso.Material = Enum.Material.Neon
                torso.Anchored = true
                torso.CanCollide = false
                torso.Position = statue.part.Position + Vector3.new(0, 6, 0)
                torso.Parent = soul
                
                local brain = Instance.new("Part")
                brain.Size = Vector3.new(3, 3, 3)
                brain.Shape = Enum.PartType.Ball
                brain.Color = Color3.fromRGB(150, 50, 200)
                brain.Material = Enum.Material.Neon
                brain.Anchored = true
                brain.CanCollide = false
                brain.Position = torso.Position + Vector3.new(0, 3, 0)
                brain.Parent = soul
            end
            
            -- Shoot 20 bullets in circle if player within 50 studs
            if distToStatue <= 50 and statue.shootTimer >= 2 then
                statue.shootTimer = 0
                
                for i = 1, 20 do
                    local angle = (i / 20) * math.pi * 2
                    local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
                    
                    task.spawn(function()
                        local bullet = Instance.new("Part")
                        bullet.Size = Vector3.new(0.5, 0.5, 0.5)
                        bullet.Shape = Enum.PartType.Ball
                        bullet.Color = Color3.fromRGB(200, 100, 255)
                        bullet.Material = Enum.Material.Neon
                        bullet.CanCollide = false
                        bullet.Anchored = false
                        bullet.Position = statue.part.Position + Vector3.new(0, 5, 0)
                        bullet.Parent = workspace
                        
                        local bodyVel = Instance.new("BodyVelocity")
                        bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
                        bodyVel.Velocity = dir * 50
                        bodyVel.Parent = bullet
                        
                        local touchConnection
                        touchConnection = bullet.Touched:Connect(function(hit)
                            if hit.Parent == currentChar then
                                applyDamage("Purple", 8, 16)
                                touchConnection:Disconnect()
                                bullet:Destroy()
                            end
                        end)
                        
                        task.delay(3, function()
                            if bullet and bullet.Parent then bullet:Destroy() end
                        end)
                    end)
                    
                    task.wait(0.05)
                end
            end
        end
        
        -- Check if player died to spawn Loved One
        if currentHP <= 0 and not activeOrdeals["Noon of Purple_spawned"] then
            activeOrdeals["Noon of Purple_spawned"] = true
            
            local loved = Instance.new("Model")
            loved.Name = "TheLovedOne"
            loved.Parent = workspace
            
            local torso = Instance.new("Part")
            torso.Size = Vector3.new(2, 2, 1)
            torso.Color = Color3.fromRGB(255, 150, 200)
            torso.Material = Enum.Material.Neon
            torso.Anchored = true
            torso.CanCollide = false
            torso.Position = playerPos
            torso.Parent = loved
            
            table.insert(lovedOnes, {
                model = loved,
                torso = torso,
                attackTimer = 0
            })
            
            task.delay(5, function()
                activeOrdeals["Noon of Purple_spawned"] = nil
            end)
        end
        
        -- Update Loved Ones
        for _, loved in ipairs(lovedOnes) do
            if loved.model and loved.model.Parent then
                if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
                    local dir = (playerPos - loved.torso.Position).Unit
                    loved.torso.Position = loved.torso.Position + dir * 10 * dt
                    
                    -- Make it face player
                    local lookAt = Vector3.new(playerPos.X, loved.torso.Position.Y, playerPos.Z)
                    loved.torso.CFrame = CFrame.new(loved.torso.Position, lookAt)
                    
                    loved.attackTimer = loved.attackTimer + dt
                    local distToPlayer = (playerPos - loved.torso.Position).Magnitude
                    
                    if distToPlayer <= 5 and loved.attackTimer >= 1 then
                        loved.attackTimer = 0
                        applyDamage("Purple", 3, 5)
                    end
                end
            end
        end
    end)
    
    ordealLoops["Noon of Purple"] = {loop}
end

-- Ordeal: Dusk of Purple
local function startDuskOfPurple()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    showOrdealIntro("Dusk of Purple", "Unconditional Obsession", "You make us complete. We cannot live without you.")
    
    local hrp = char.HumanoidRootPart
    local buildingPos = hrp.Position + Vector3.new(math.random(-100, 100), 0, math.random(-100, 100))
    
    -- Create building with mouth
    local building = Instance.new("Model")
    building.Name = "ObsessionBuilding"
    building.Parent = workspace
    
    local buildingBody = Instance.new("Part")
    buildingBody.Size = Vector3.new(20, 30, 20)
    buildingBody.Color = Color3.fromRGB(100, 50, 150)
    buildingBody.Material = Enum.Material.Brick
    buildingBody.Anchored = true
    buildingBody.CanCollide = false
    buildingBody.Position = buildingPos
    buildingBody.Parent = building
    
    local mouth = Instance.new("Part")
    mouth.Size = Vector3.new(10, 5, 2)
    mouth.Color = Color3.fromRGB(50, 0, 0)
    mouth.Material = Enum.Material.Neon
    mouth.Anchored = true
    mouth.CanCollide = false
    mouth.Position = buildingBody.Position + Vector3.new(0, -5, 10)
    mouth.Parent = building
    
    local pulseTimer = 0
    local soulSpawnTimer = 0
    local desiringSouls = {}
    
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeOrdeals["Dusk of Purple"] then
            if building and building.Parent then building:Destroy() end
            for _, soul in ipairs(desiringSouls) do
                if soul.model and soul.model.Parent then soul.model:Destroy() end
            end
            loop:Disconnect()
            return
        end
        
        local currentChar = player.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        local playerPos = currentChar.HumanoidRootPart.Position
        
        -- Check if player is looking at building
        local camera = workspace.CurrentCamera
        local camCFrame = camera.CFrame
        local dirToBuilding = (buildingBody.Position - camCFrame.Position).Unit
        local camLook = camCFrame.LookVector
        local dot = dirToBuilding:Dot(camLook)
        
        local isLooking = dot > 0.7
        
        -- Move towards player if not looking
        if not isLooking then
            local dir = (playerPos - buildingBody.Position).Unit
            buildingBody.Position = buildingBody.Position + dir * 10 * dt
            mouth.Position = buildingBody.Position + buildingBody.CFrame.LookVector * 10 + Vector3.new(0, -5, 0)
        end
        
        -- Pulse forcefield every 5 seconds
        pulseTimer = pulseTimer + dt
        if pulseTimer >= 5 then
            pulseTimer = 0
            
            task.spawn(function()
                local forcefield = Instance.new("Part")
                forcefield.Shape = Enum.PartType.Ball
                forcefield.Size = Vector3.new(300, 300, 300)
                forcefield.Color = Color3.fromRGB(200, 100, 255)
                forcefield.Material = Enum.Material.ForceField
                forcefield.Transparency = 0.5
                forcefield.CanCollide = false
                forcefield.Anchored = true
                forcefield.Position = buildingBody.Position
                forcefield.Parent = workspace
                
                local distToBuilding = (playerPos - buildingBody.Position).Magnitude
                if distToBuilding <= 150 then
                    applyDamage("Purple", 15, 30)
                    
                    -- Force walk to building
                    if currentChar:FindFirstChild("Humanoid") then
                        local humanoidRef = currentChar.Humanoid
                        local startTime = tick()
                        local forceWalkLoop = RunService.Heartbeat:Connect(function()
                            if tick() - startTime >= 3 or not forcefield or not forcefield.Parent then return end
                            if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
                                local dir = (buildingBody.Position - currentChar.HumanoidRootPart.Position).Unit
                                humanoidRef:Move(dir)
                            end
                        end)
                        
                        task.delay(3, function()
                            forceWalkLoop:Disconnect()
                        end)
                    end
                    
                    -- Check if player died
                    if currentHP <= 0 then
                        -- Spawn Desiring Soul
                        local soul = Instance.new("Model")
                        soul.Name = "DesiringSoul"
                        soul.Parent = workspace
                        
                        local torso = Instance.new("Part")
                        torso.Size = Vector3.new(2, 2, 1)
                        torso.Color = Color3.fromRGB(200, 100, 255)
                        torso.Material = Enum.Material.Neon
                        torso.Anchored = true
                        torso.CanCollide = false
                        torso.Position = playerPos + Vector3.new(0, 5, 0)
                        torso.Parent = soul
                        
                        local brain = Instance.new("Part")
                        brain.Size = Vector3.new(3, 3, 3)
                        brain.Shape = Enum.PartType.Ball
                        brain.Color = Color3.fromRGB(150, 50, 200)
                        brain.Material = Enum.Material.Neon
                        brain.Anchored = true
                        brain.CanCollide = false
                        brain.Position = torso.Position + Vector3.new(0, 3, 0)
                        brain.Parent = soul
                        
                        table.insert(desiringSouls, soul)
                    end
                end
                
                TweenService:Create(forcefield, TweenInfo.new(3), {Transparency = 1}):Play()
                task.delay(3, function()
                    if forcefield and forcefield.Parent then forcefield:Destroy() end
                end)
            end)
        end
        
        -- Spawn 5 Desiring Souls every 10 seconds
        soulSpawnTimer = soulSpawnTimer + dt
        if soulSpawnTimer >= 10 then
            soulSpawnTimer = 0
            
            for i = 1, 5 do
                local angle = (i / 5) * math.pi * 2
                local dist = 20
                local spawnPos = buildingBody.Position + Vector3.new(math.cos(angle) * dist, 10, math.sin(angle) * dist)
                
                local soul = Instance.new("Model")
                soul.Name = "DesiringSoul"
                soul.Parent = workspace
                
                local torso = Instance.new("Part")
                torso.Size = Vector3.new(2, 2, 1)
                torso.Color = Color3.fromRGB(200, 100, 255)
                torso.Material = Enum.Material.Neon
                torso.Anchored = true
                torso.CanCollide = false
                torso.Position = spawnPos
                torso.Parent = soul
                
                local brain = Instance.new("Part")
                brain.Size = Vector3.new(3, 3, 3)
                brain.Shape = Enum.PartType.Ball
                brain.Color = Color3.fromRGB(150, 50, 200)
                brain.Material = Enum.Material.Neon
                brain.Anchored = true
                brain.CanCollide = false
                brain.Position = torso.Position + Vector3.new(0, 3, 0)
                brain.Parent = soul
                
                table.insert(desiringSouls, soul)
            end
        end
    end)
    
    ordealLoops["Dusk of Purple"] = {loop}
end

-- Ordeal: Midnight of Purple
local function startMidnightOfPurple()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    showOrdealIntro("Midnight of Purple", "God's Lust", "We are the divine incarnations of desire. Witness our power.")
    
    local hrp = char.HumanoidRootPart
    
    -- Create 5 Deity Pillars
    local pillars = {}
    local pillarData = {
        {name = "Crimson Deity", color = Color3.fromRGB(220, 50, 50), type = "Crimson"},
        {name = "Blue Deity", color = Color3.fromRGB(50, 120, 220), type = "Blue"},
        {name = "Purple Deity", color = Color3.fromRGB(200, 100, 255), type = "Purple"},
        {name = "Grey Deity", color = Color3.fromRGB(150, 150, 150), type = "Grey"},
        {name = "White Deity", color = Color3.new(1, 1, 1), type = "White"}
    }
    
    for i, data in ipairs(pillarData) do
        local angle = (i / 5) * math.pi * 2
        local dist = math.random(80, 150)
        local pillarPos = hrp.Position + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
        
        local pillar = Instance.new("Part")
        pillar.Size = Vector3.new(15, 100, 15)
        pillar.Color = data.color
        pillar.Material = Enum.Material.Neon
        pillar.Anchored = true
        pillar.CanCollide = false
        pillar.Position = pillarPos + Vector3.new(0, 50, 0)
        pillar.Parent = workspace
        
        local nameLabel = Instance.new("BillboardGui")
        nameLabel.Size = UDim2.new(0, 200, 0, 50)
        nameLabel.Adornee = pillar
        nameLabel.AlwaysOnTop = true
        nameLabel.Parent = pillar
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = data.name
        textLabel.TextColor3 = data.color
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 24
        textLabel.TextStrokeTransparency = 0.5
        textLabel.Parent = nameLabel
        
        -- Add image for Purple Deity
        local imageGui = nil
        if data.type == "Purple" then
            imageGui = Instance.new("BillboardGui")
            imageGui.Size = UDim2.new(0, 300, 0, 300)
            imageGui.Adornee = pillar
            imageGui.AlwaysOnTop = false
            imageGui.Parent = pillar
            
            local image = Instance.new("ImageLabel")
            image.Size = UDim2.new(1, 0, 1, 0)
            image.BackgroundTransparency = 1
            image.Image = "rbxassetid://10154713819"
            image.Parent = imageGui
        end
        
        table.insert(pillars, {
            part = pillar,
            type = data.type,
            timer = 0,
            imageGui = imageGui,
            tentacles = {}
        })
    end
    
    local blinding = false
    local blindFrame = nil
    
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeOrdeals["Midnight of Purple"] then
            for _, pillar in ipairs(pillars) do
                if pillar.part and pillar.part.Parent then pillar.part:Destroy() end
                for _, tent in ipairs(pillar.tentacles) do
                    if tent and tent.Parent then tent:Destroy() end
                end
            end
            if blindFrame and blindFrame.Parent then blindFrame:Destroy() end
            loop:Disconnect()
            return
        end
        
        local currentChar = player.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        local playerPos = currentChar.HumanoidRootPart.Position
        
        for _, pillar in ipairs(pillars) do
            pillar.timer = pillar.timer + dt
            
            -- Crimson Deity: Tentacle stab every 10 seconds
            if pillar.type == "Crimson" and pillar.timer >= 10 then
                pillar.timer = 0
                task.spawn(function()
                    local spawnPos = playerPos + Vector3.new(math.random(-50, 50), 50, math.random(-50, 50))
                    
                    local portal = Instance.new("Part")
                    portal.Shape = Enum.PartType.Cylinder
                    portal.Size = Vector3.new(0.5, 10, 10)
                    portal.Color = Color3.fromRGB(220, 50, 50)
                    portal.Material = Enum.Material.Neon
                    portal.Transparency = 0.5
                    portal.CanCollide = false
                    portal.Anchored = true
                    portal.Position = spawnPos
                    portal.Orientation = Vector3.new(0, 0, 90)
                    portal.Parent = workspace
                    
                    task.wait(0.5)
                    
                    local tentacle = Instance.new("Part")
                    tentacle.Size = Vector3.new(5, 60, 5)
                    tentacle.Color = Color3.fromRGB(200, 30, 30)
                    tentacle.Material = Enum.Material.Neon
                    tentacle.CanCollide = false
                    tentacle.Anchored = true
                    tentacle.Position = spawnPos + Vector3.new(0, -30, 0)
                    tentacle.Parent = workspace
                    
                    local distToTent = (playerPos - tentacle.Position).Magnitude
                    if distToTent <= 5 then
                        applyDamage("Crimson", 50, 75)
                    end
                    
                    portal:Destroy()
                    
                    TweenService:Create(tentacle, TweenInfo.new(2), {Transparency = 1}):Play()
                    task.delay(2, function()
                        if tentacle and tentacle.Parent then tentacle:Destroy() end
                    end)
                end)
            end
            
            -- Blue Deity: Spike every 25 seconds
            if pillar.type == "Blue" and pillar.timer >= 25 then
                pillar.timer = 0
                task.spawn(function()
                    local spike = Instance.new("Part")
                    spike.Size = Vector3.new(15, 40, 15)
                    spike.Color = Color3.fromRGB(50, 120, 220)
                    spike.Material = Enum.Material.Neon
                    spike.CanCollide = false
                    spike.Anchored = true
                    spike.Position = playerPos + Vector3.new(0, 100, 0)
                    spike.Parent = workspace
                    
                    TweenService:Create(spike, TweenInfo.new(0.5), {Position = playerPos + Vector3.new(0, 7.5, 0)}):Play()
                    task.wait(0.5)
                    
                    local distToSpike = (playerPos - spike.Position).Magnitude
                    if distToSpike <= 10 then
                        local damageStart = tick()
                        local damageLoop = RunService.Heartbeat:Connect(function()
                            if tick() - damageStart >= 3 then return end
                            if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
                                applyDamage("Blue", 10, 30)
                                
                                if currentSP <= 0 then
                                    -- Force walk to Blue Deity
                                    if currentChar:FindFirstChild("Humanoid") then
                                        local humanoidRef = currentChar.Humanoid
                                        local forceStartTime = tick()
                                        local forceLoop = RunService.Heartbeat:Connect(function()
                                            if tick() - forceStartTime >= 1 then return end
                                            if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
                                                local dir = (pillar.part.Position - currentChar.HumanoidRootPart.Position).Unit
                                                humanoidRef:Move(dir)
                                                
                                                applyDamage("Crimson", 25, 50)
                                            end
                                        end)
                                        
                                        task.delay(1, function()
                                            forceLoop:Disconnect()
                                        end)
                                    end
                                end
                            end
                        end)
                        
                        task.delay(3, function()
                            damageLoop:Disconnect()
                        end)
                    end
                    
                    TweenService:Create(spike, TweenInfo.new(2), {Transparency = 1}):Play()
                    task.delay(2, function()
                        if spike and spike.Parent then spike:Destroy() end
                    end)
                end)
            end
            
            -- Purple Deity: Blinding effect
            if pillar.type == "Purple" then
                local camera = workspace.CurrentCamera
                local camCFrame = camera.CFrame
                local dirToPillar = (pillar.part.Position - camCFrame.Position).Unit
                local camLook = camCFrame.LookVector
                local dot = dirToPillar:Dot(camLook)
                
                local isLooking = dot > 0.5
                
                if isLooking and not blinding then
                    blinding = true
                    blindFrame = Instance.new("Frame")
                    blindFrame.Size = UDim2.new(1, 0, 1, 0)
                    blindFrame.BackgroundColor3 = Color3.new(0, 0, 0)
                    blindFrame.BackgroundTransparency = 0
                    blindFrame.Parent = screenGui
                    
                    local blindLoop = RunService.Heartbeat:Connect(function()
                        if not blinding then return end
                        applyDamage("Purple", 43, 76)
                        task.wait(1)
                    end)
                    
                    task.spawn(function()
                        while blinding and activeOrdeals["Midnight of Purple"] do
                            local cam2 = workspace.CurrentCamera
                            local camCFrame2 = cam2.CFrame
                            local dirToPillar2 = (pillar.part.Position - camCFrame2.Position).Unit
                            local camLook2 = camCFrame2.LookVector
                            local dot2 = dirToPillar2:Dot(camLook2)
                            
                            if dot2 <= 0.5 then
                                blinding = false
                                blindLoop:Disconnect()
                                if blindFrame and blindFrame.Parent then
                                    blindFrame:Destroy()
                                end
                                break
                            end
                            task.wait(0.1)
                        end
                    end)
                elseif not isLooking and blinding then
                    blinding = false
                    if blindFrame and blindFrame.Parent then
                        blindFrame:Destroy()
                    end
                end
            end
            
            -- Grey Deity: 3 Tentacles every 53 seconds
            if pillar.type == "Grey" and pillar.timer >= 53 then
                pillar.timer = 0
                task.spawn(function()
                    for i = 1, 3 do
                        local spawnPos = playerPos + Vector3.new(math.random(-70, 70), 50, math.random(-70, 70))
                        
                        local portal = Instance.new("Part")
                        portal.Shape = Enum.PartType.Cylinder
                        portal.Size = Vector3.new(0.5, 15, 15)
                        portal.Color = Color3.fromRGB(150, 150, 150)
                        portal.Material = Enum.Material.Neon
                        portal.Transparency = 0.5
                        portal.CanCollide = false
                        portal.Anchored = true
                        portal.Position = spawnPos
                        portal.Orientation = Vector3.new(0, 0, 90)
                        portal.Parent = workspace
                        
                        task.wait(1)
                        
                        local tentacle = Instance.new("Part")
                        tentacle.Size = Vector3.new(8, 80, 8)
                        tentacle.Color = Color3.fromRGB(120, 120, 120)
                        tentacle.Material = Enum.Material.Neon
                        tentacle.CanCollide = false
                        tentacle.Anchored = true
                        tentacle.Position = spawnPos + Vector3.new(0, -40, 0)
                        tentacle.Parent = workspace
                        
                        table.insert(pillar.tentacles, tentacle)
                        portal:Destroy()
                    end
                    
                    task.wait(0.5)
                    
                    for _, tent in ipairs(pillar.tentacles) do
                        if tent and tent.Parent then
                            local distToTent = (playerPos - tent.Position).Magnitude
                            if distToTent <= 8 then
                                applyDamage("Grey", 60, 80)
                            end
                            
                            TweenService:Create(tent, TweenInfo.new(2), {Transparency = 1}):Play()
                            task.delay(2, function()
                                if tent and tent.Parent then tent:Destroy() end
                            end)
                        end
                    end
                    
                    pillar.tentacles = {}
                end)
            end
            
            -- White Deity: All player damage every 1 minute
            if pillar.type == "White" and pillar.timer >= 60 then
                pillar.timer = 0
                task.spawn(function()
                    -- Play sound
                    local sound = Instance.new("Sound")
                    sound.SoundId = "rbxassetid://70542612197339"
                    sound.Volume = 1
                    sound.Parent = pillar.part
                    sound:Play()
                    
                    applyDamage("White", 75, 120)
                    
                    task.delay(5, function()
                        if sound and sound.Parent then sound:Destroy() end
                    end)
                end)
            end
        end
    end)
    
    ordealLoops["Midnight of Purple"] = {loop}
end

-- Create Illusion Entry
local falseGodIllusion = {
    name = "False God",
    desc = "A GIANT eye protected by 200 stud forcefield (30-45 Grey & White dmg/sec). 4 abilities: Beam (50-60), Circle beams (25-40), Spinning beams (30-50), Dot warning beams (30-50). Guarded by 12 upgraded apostles: 3 Sword (45-80 + flying slashes 10-30), 2 Spear (dash 45-50), 1 Staff (beam 10-20 all types + slowdown), 3 Grapple (hook drag 20-50 all types), 3 Gun (15-25 with barrage).",
    damageType = "Multiple",
    damageScale = "10 - 80",
    danger = "ALEPH",
    func = startFalseGod
}

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, -10, 0, 150)
frame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
frame.BorderSizePixel = 1
frame.Parent = scrollFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -10, 0, 25)
nameLabel.Position = UDim2.new(0, 5, 0, 5)
nameLabel.Text = falseGodIllusion.name
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 18
nameLabel.BackgroundTransparency = 1
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.TextColor3 = Color3.new(0, 0, 0)
nameLabel.Parent = frame

local descLabel = Instance.new("TextLabel")
descLabel.Size = UDim2.new(1, -10, 0, 60)
descLabel.Position = UDim2.new(0, 5, 0, 30)
descLabel.Text = falseGodIllusion.desc
descLabel.Font = Enum.Font.Gotham
descLabel.TextSize = 8
descLabel.TextWrapped = true
descLabel.BackgroundTransparency = 1
descLabel.TextXAlignment = Enum.TextXAlignment.Left
descLabel.TextYAlignment = Enum.TextYAlignment.Top
descLabel.TextColor3 = Color3.new(0, 0, 0)
descLabel.Parent = frame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -10, 0, 50)
infoLabel.Position = UDim2.new(0, 5, 0, 95)
infoLabel.Text = string.format("Damage Type: %s\nDamage Scale: %s\nDanger Level: %s", 
    falseGodIllusion.damageType, falseGodIllusion.damageScale, falseGodIllusion.danger)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 12
infoLabel.BackgroundTransparency = 1
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.TextColor3 = dangerColors[falseGodIllusion.danger]
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
    if activeIllusions[falseGodIllusion.name] then
        activeIllusions[falseGodIllusion.name] = false
        toggleBtn.Text = "OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        
        if illusionLoops[falseGodIllusion.name] then
            for _, loop in ipairs(illusionLoops[falseGodIllusion.name]) do
                if loop and loop.Connected then
                    loop:Disconnect()
                end
            end
            illusionLoops[falseGodIllusion.name] = nil
        end
    else
        activeIllusions[falseGodIllusion.name] = true
        toggleBtn.Text = "ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
        falseGodIllusion.func()
    end
end)

scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)

-- Create Ordeal Entries
local ordeals = {
    {
        name = "Dawn of Purple",
        desc = "10 floating humanoids with big brains spawn. Every 3 seconds they pulse a 30 stud purple forcefield that force walks players and deals 5-10 Purple damage.",
        descName = "Desire",
        introDesc = "We crave love, we will do anything to get it.",
        ordealLevel = "DAWN",
        func = startDawnOfPurple
    },
    {
        name = "Noon of Purple",
        desc = "5 statues spawn that create Desiring Souls every 5 seconds. If player is within 50 studs, shoots 20 purple bullets in a circle dealing 8-16 Purple damage every 2 seconds. Dead players become 'The Loved One' (3-5 Purple damage).",
        descName = "Grant us Love",
        introDesc = "We've found a new meaning of love, We began to study and study about love endlessly.",
        ordealLevel = "NOON",
        func = startNoonOfPurple
    },
    {
        name = "Dusk of Purple",
        desc = "A building with a mouth appears. Every 5 seconds creates 150 stud forcefield that force walks players dealing 15-30 Purple damage. Dead players become Desiring Souls. Every 10 seconds spawns 5 new Desiring Souls. Building follows player at speed 10 when not looking at it.",
        descName = "Unconditional Obsession",
        introDesc = "You make us complete. We cannot live without you.",
        ordealLevel = "DUSK",
        func = startDuskOfPurple
    },
    {
        name = "Midnight of Purple",
        desc = "5 GIANT deity pillars appear: Crimson (tentacle stab 50-75), Blue (spike crash 10-30/tick + force walk on SP=0), Purple (blinds + 43-76/sec when looking), Grey (3 tentacles 60-80), White (all players 75-120 every minute with sound).",
        descName = "God's Lust",
        introDesc = "We are the divine incarnations of desire. Witness our power.",
        ordealLevel = "MIDNIGHT",
        func = startMidnightOfPurple
    }
}

for _, ordeal in ipairs(ordeals) do
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 150)
    frame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    frame.BorderSizePixel = 1
    frame.Parent = ordealsScrollFrame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -10, 0, 25)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.Text = ordeal.name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 18
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = Color3.new(0, 0, 0)
    nameLabel.Parent = frame
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -10, 0, 60)
    descLabel.Position = UDim2.new(0, 5, 0, 30)
    descLabel.Text = ordeal.desc
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 8
    descLabel.TextWrapped = true
    descLabel.BackgroundTransparency = 1
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.TextColor3 = Color3.new(0, 0, 0)
    descLabel.Parent = frame
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -10, 0, 50)
    infoLabel.Position = UDim2.new(0, 5, 0, 95)
    infoLabel.Text = string.format("Description: %s\nOrdeal Level: %s", 
        ordeal.descName, ordeal.ordealLevel)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 12
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.TextColor3 = dangerColors[ordeal.ordealLevel]
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
        if activeOrdeals[ordeal.name] then
            activeOrdeals[ordeal.name] = false
            toggleBtn.Text = "OFF"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
            
            if ordealLoops[ordeal.name] then
                for _, loop in ipairs(ordealLoops[ordeal.name]) do
                    if loop and loop.Connected then
                        loop:Disconnect()
                    end
                end
                ordealLoops[ordeal.name] = nil
            end
        else
            activeOrdeals[ordeal.name] = true
            toggleBtn.Text = "ON"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
            ordeal.func()
        end
    end)
end

ordealsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ordealsListLayout.AbsoluteContentSize.Y + 20)

-- Reset stats on respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    resetStats()
end)
