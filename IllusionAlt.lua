-- King Chess Family & Bonehive Disease Illusion Script (Client-Sided)
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
illusionsBtn.Position = UDim2.new(0.5, -60, 0, 10)
illusionsBtn.Text = "ILLUSIONS"
illusionsBtn.Font = Enum.Font.GothamBold
illusionsBtn.TextSize = 18
illusionsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
illusionsBtn.TextColor3 = Color3.new(1, 1, 1)
illusionsBtn.Parent = screenGui

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
end)

-- Danger Level Colors
local dangerColors = {
    TZADEL = Color3.fromRGB(255, 105, 180),
    SAMECH = Color3.fromRGB(255, 255, 100),
    ALEPH = Color3.fromRGB(255, 0, 0)
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

-- Helper function to create humanoid body
local function createHumanoid(name, size, color1, color2, position)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = workspace
    
    local torso = Instance.new("Part")
    torso.Size = Vector3.new(2, 2, 1) * size
    torso.Color = color1
    torso.Material = Enum.Material.Neon
    torso.Anchored = true
    torso.CanCollide = false
    torso.Position = position
    torso.Parent = model
    
    local head = Instance.new("Part")
    head.Size = Vector3.new(1.5, 1.5, 1.5) * size
    head.Shape = Enum.PartType.Ball
    head.Color = color1
    head.Material = Enum.Material.Neon
    head.Anchored = true
    head.CanCollide = false
    head.Position = torso.Position + Vector3.new(0, 2 * size, 0)
    head.Parent = model
    
    local leftArm = Instance.new("Part")
    leftArm.Size = Vector3.new(1, 2, 1) * size
    leftArm.Color = color2
    leftArm.Material = Enum.Material.Neon
    leftArm.Anchored = true
    leftArm.CanCollide = false
    leftArm.Position = torso.Position + Vector3.new(-1.5 * size, 0, 0)
    leftArm.Parent = model
    
    local rightArm = Instance.new("Part")
    rightArm.Size = Vector3.new(1, 2, 1) * size
    rightArm.Color = color2
    rightArm.Material = Enum.Material.Neon
    rightArm.Anchored = true
    rightArm.CanCollide = false
    rightArm.Position = torso.Position + Vector3.new(1.5 * size, 0, 0)
    rightArm.Parent = model
    
    local leftLeg = Instance.new("Part")
    leftLeg.Size = Vector3.new(1, 2, 1) * size
    leftLeg.Color = color2
    leftLeg.Material = Enum.Material.Neon
    leftLeg.Anchored = true
    leftLeg.CanCollide = false
    leftLeg.Position = torso.Position + Vector3.new(-0.5 * size, -2 * size, 0)
    leftLeg.Parent = model
    
    local rightLeg = Instance.new("Part")
    rightLeg.Size = Vector3.new(1, 2, 1) * size
    rightLeg.Color = color2
    rightLeg.Material = Enum.Material.Neon
    rightLeg.Anchored = true
    rightLeg.CanCollide = false
    rightLeg.Position = torso.Position + Vector3.new(0.5 * size, -2 * size, 0)
    rightLeg.Parent = model
    
    return model, torso, head, leftArm, rightArm, leftLeg, rightLeg
end

-- Illusion: King Chess Family
local function startKingChessFamily()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    -- Create King
    local king, kingTorso, kingHead, kingLeftArm, kingRightArm, kingLeftLeg, kingRightLeg = 
        createHumanoid("King", 2, Color3.new(1, 1, 1), Color3.new(0, 0, 0), hrp.Position + Vector3.new(20, 0, 0))
    
    -- Crown for King
    local crown = Instance.new("Part")
    crown.Size = Vector3.new(3.5, 1, 3.5)
    crown.Color = Color3.fromRGB(255, 215, 0)
    crown.Material = Enum.Material.Neon
    crown.Anchored = true
    crown.CanCollide = false
    crown.Parent = king
    
    -- Staff for King
    local staff = Instance.new("Part")
    staff.Size = Vector3.new(0.5, 8, 0.5)
    staff.Color = Color3.fromRGB(139, 69, 19)
    staff.Material = Enum.Material.Wood
    staff.Anchored = true
    staff.CanCollide = false
    staff.Parent = king
    
    local staffTop = Instance.new("Part")
    staffTop.Size = Vector3.new(1.5, 1.5, 1.5)
    staffTop.Shape = Enum.PartType.Ball
    staffTop.Color = Color3.fromRGB(255, 215, 0)
    staffTop.Material = Enum.Material.Neon
    staffTop.Anchored = true
    staffTop.CanCollide = false
    staffTop.Parent = king
    
    -- Create Queen
    local queen, queenTorso, queenHead, queenLeftArm, queenRightArm, queenLeftLeg, queenRightLeg = 
        createHumanoid("Queen", 2, Color3.new(1, 1, 1), Color3.new(0, 0, 0), hrp.Position + Vector3.new(25, 0, 0))
    
    -- Crown for Queen
    local queenCrown = Instance.new("Part")
    queenCrown.Size = Vector3.new(3, 1.5, 3)
    queenCrown.Color = Color3.fromRGB(255, 215, 0)
    queenCrown.Material = Enum.Material.Neon
    queenCrown.Anchored = true
    queenCrown.CanCollide = false
    queenCrown.Parent = queen
    
    -- Sword for Queen
    local queenSword = Instance.new("Part")
    queenSword.Size = Vector3.new(0.3, 5, 0.5)
    queenSword.Color = Color3.fromRGB(192, 192, 192)
    queenSword.Material = Enum.Material.Metal
    queenSword.Anchored = true
    queenSword.CanCollide = false
    queenSword.Parent = queen
    
    -- Create 4 Rooks (circling King)
    local rooks = {}
    for i = 1, 4 do
        local angle = (i / 4) * math.pi * 2
        local offset = Vector3.new(math.cos(angle) * 15, 0, math.sin(angle) * 15)
        local rook, rTorso, rHead, rLA, rRA, rLL, rRL = 
            createHumanoid("Rook" .. i, 1, Color3.new(1, 1, 1), Color3.new(0, 0, 0), hrp.Position + offset)
        
        -- Sword for Rook
        local rookSword = Instance.new("Part")
        rookSword.Size = Vector3.new(0.2, 3, 0.3)
        rookSword.Color = Color3.fromRGB(192, 192, 192)
        rookSword.Material = Enum.Material.Metal
        rookSword.Anchored = true
        rookSword.CanCollide = false
        rookSword.Parent = rook
        
        table.insert(rooks, {
            model = rook,
            torso = rTorso,
            head = rHead,
            leftArm = rLA,
            rightArm = rRA,
            leftLeg = rLL,
            rightLeg = rRL,
            sword = rookSword,
            angle = angle,
            followingPlayer = false
        })
    end
    
    -- Create 1 Bishop
    local bishop, bishopTorso, bishopHead, bishopLeftArm, bishopRightArm, bishopLeftLeg, bishopRightLeg = 
        createHumanoid("Bishop", 1, Color3.new(1, 1, 1), Color3.new(0, 0, 0), hrp.Position + Vector3.new(30, 0, 0))
    
    -- Staff for Bishop
    local bishopStaff = Instance.new("Part")
    bishopStaff.Size = Vector3.new(0.3, 4, 0.3)
    bishopStaff.Color = Color3.fromRGB(139, 69, 19)
    bishopStaff.Material = Enum.Material.Wood
    bishopStaff.Anchored = true
    bishopStaff.CanCollide = false
    bishopStaff.Parent = bishop
    
    -- Create 2 Knights (riding horses)
    local knights = {}
    for i = 1, 2 do
        local knight, kTorso, kHead, kLA, kRA, kLL, kRL = 
            createHumanoid("Knight" .. i, 1, Color3.new(1, 1, 1), Color3.new(0, 0, 0), hrp.Position + Vector3.new(35 + i * 5, 0, 0))
        
        -- Simple horse body
        local horseBody = Instance.new("Part")
        horseBody.Size = Vector3.new(3, 2, 5)
        horseBody.Color = Color3.fromRGB(139, 69, 19)
        horseBody.Material = Enum.Material.Wood
        horseBody.Anchored = true
        horseBody.CanCollide = false
        horseBody.Parent = knight
        
        local horseHead = Instance.new("Part")
        horseHead.Size = Vector3.new(1.5, 2, 1.5)
        horseHead.Color = Color3.fromRGB(139, 69, 19)
        horseHead.Material = Enum.Material.Wood
        horseHead.Anchored = true
        horseHead.CanCollide = false
        horseHead.Parent = knight
        
        table.insert(knights, {
            model = knight,
            torso = kTorso,
            head = kHead,
            leftArm = kLA,
            rightArm = kRA,
            leftLeg = kLL,
            rightLeg = kRL,
            horseBody = horseBody,
            horseHead = horseHead
        })
    end
    
    -- Create 5 Pawns
    local pawns = {}
    for i = 1, 5 do
        local pawn, pTorso, pHead, pLA, pRA, pLL, pRL = 
            createHumanoid("Pawn" .. i, 0.5, Color3.new(1, 1, 1), Color3.new(0, 0, 0), hrp.Position + Vector3.new(40 + i * 3, 0, 0))
        
        -- Axe for Pawn
        local axe = Instance.new("Part")
        axe.Size = Vector3.new(0.3, 2, 0.5)
        axe.Color = Color3.fromRGB(139, 69, 19)
        axe.Material = Enum.Material.Wood
        axe.Anchored = true
        axe.CanCollide = false
        axe.Parent = pawn
        
        local axeHead = Instance.new("Part")
        axeHead.Size = Vector3.new(1, 0.3, 0.5)
        axeHead.Color = Color3.fromRGB(192, 192, 192)
        axeHead.Material = Enum.Material.Metal
        axeHead.Anchored = true
        axeHead.CanCollide = false
        axeHead.Parent = pawn
        
        table.insert(pawns, {
            model = pawn,
            torso = pTorso,
            head = pHead,
            leftArm = pLA,
            rightArm = pRA,
            leftLeg = pLL,
            rightLeg = pRL,
            axe = axe,
            axeHead = axeHead
        })
    end
    
    -- Timers
    local kingAttackTimer = 0
    local queenAttackTimer = 0
    local bishopAttackTimer = 0
    local rookAttackTimers = {0, 0, 0, 0}
    local knightTimers = {0, 0}
    local pawnAttackTimers = {0, 0, 0, 0, 0}
    
    -- Movement functions
    local function updateBodyParts(torso, head, leftArm, rightArm, leftLeg, rightLeg, size)
        head.Position = torso.Position + Vector3.new(0, 2 * size, 0)
        leftArm.Position = torso.Position + torso.CFrame.RightVector * (-1.5 * size)
        rightArm.Position = torso.Position + torso.CFrame.RightVector * (1.5 * size)
        leftLeg.Position = torso.Position + Vector3.new(-0.5 * size, -2 * size, 0)
        rightLeg.Position = torso.Position + Vector3.new(0.5 * size, -2 * size, 0)
    end
    
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
        if not activeIllusions["King Chess Family"] then
            if king and king.Parent then king:Destroy() end
            if queen and queen.Parent then queen:Destroy() end
            if bishop and bishop.Parent then bishop:Destroy() end
            for _, rook in ipairs(rooks) do
                if rook.model and rook.model.Parent then rook.model:Destroy() end
            end
            for _, knight in ipairs(knights) do
                if knight.model and knight.model.Parent then knight.model:Destroy() end
            end
            for _, pawn in ipairs(pawns) do
                if pawn.model and pawn.model.Parent then pawn.model:Destroy() end
            end
            loop:Disconnect()
            return
        end
        
        local currentChar = player.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        local playerPos = currentChar.HumanoidRootPart.Position
        
        -- King behavior
        kingAttackTimer = kingAttackTimer + dt
        moveTowardsPlayer(kingTorso, 10, dt)
        updateBodyParts(kingTorso, kingHead, kingLeftArm, kingRightArm, kingLeftLeg, kingRightLeg, 2)
        crown.Position = kingHead.Position + Vector3.new(0, 2, 0)
        staff.Position = kingRightArm.Position + Vector3.new(0, -2, 0)
        staff.CFrame = CFrame.new(staff.Position, staff.Position + Vector3.new(0, -1, 0))
        staffTop.Position = staff.Position + Vector3.new(0, 4.75, 0)
        
        if kingAttackTimer >= 3 then
            kingAttackTimer = 0
            task.spawn(function()
                local forcefield = Instance.new("Part")
                forcefield.Shape = Enum.PartType.Ball
                forcefield.Size = Vector3.new(40, 40, 40)
                forcefield.Color = Color3.fromRGB(150, 150, 150)
                forcefield.Material = Enum.Material.ForceField
                forcefield.Transparency = 0.3
                forcefield.CanCollide = false
                forcefield.Anchored = true
                forcefield.Position = kingTorso.Position
                forcefield.Parent = workspace
                
                local dist = (playerPos - kingTorso.Position).Magnitude
                if dist <= 20 then
                    applyDamage("Grey", 30, 50)
                end
                
                TweenService:Create(forcefield, TweenInfo.new(2), {Transparency = 1}):Play()
                task.delay(2, function()
                    if forcefield and forcefield.Parent then forcefield:Destroy() end
                end)
            end)
        end
        
        -- Queen behavior
        queenAttackTimer = queenAttackTimer + dt
        moveTowardsPlayer(queenTorso, 16, dt)
        updateBodyParts(queenTorso, queenHead, queenLeftArm, queenRightArm, queenLeftLeg, queenRightLeg, 2)
        queenCrown.Position = queenHead.Position + Vector3.new(0, 2.25, 0)
        queenSword.CFrame = CFrame.new(queenRightArm.Position + Vector3.new(0, -1.5, 0), queenRightArm.Position + Vector3.new(0, -3, 0))
        
        if queenAttackTimer >= 1 then
            queenAttackTimer = 0
            local dist = (playerPos - queenTorso.Position).Magnitude
            if dist <= 5 then
                applyDamage("White", 10, 30)
            end
        end
        
        -- Rooks behavior
        for i, rook in ipairs(rooks) do
            local distToKing = (kingTorso.Position - rook.torso.Position).Magnitude
            local distToPlayer = (playerPos - rook.torso.Position).Magnitude
            
            if distToPlayer <= 20 and not rook.followingPlayer then
                rook.followingPlayer = true
            elseif distToPlayer > 20 and rook.followingPlayer then
                rook.followingPlayer = false
            end
            
            if rook.followingPlayer then
                moveTowardsPlayer(rook.torso, 20, dt)
                rookAttackTimers[i] = rookAttackTimers[i] + dt
                
                if rookAttackTimers[i] >= 2 then
                    rookAttackTimers[i] = 0
                    if distToPlayer <= 5 then
                        applyDamage("Crimson", 10, 18)
                    end
                end
            else
                -- Circle around king
                rook.angle = rook.angle + dt * 0.5
                local offset = Vector3.new(math.cos(rook.angle) * 15, 0, math.sin(rook.angle) * 15)
                rook.torso.Position = kingTorso.Position + offset
                local lookAt = Vector3.new(kingTorso.Position.X, rook.torso.Position.Y, kingTorso.Position.Z)
                rook.torso.CFrame = CFrame.new(rook.torso.Position, lookAt)
            end
            
            updateBodyParts(rook.torso, rook.head, rook.leftArm, rook.rightArm, rook.leftLeg, rook.rightLeg, 1)
            rook.sword.CFrame = CFrame.new(rook.rightArm.Position + Vector3.new(0, -1, 0), rook.rightArm.Position + Vector3.new(0, -2, 0))
        end
        
        -- Bishop behavior
        bishopAttackTimer = bishopAttackTimer + dt
        moveTowardsPlayer(bishopTorso, 18, dt)
        updateBodyParts(bishopTorso, bishopHead, bishopLeftArm, bishopRightArm, bishopLeftLeg, bishopRightLeg, 1)
        bishopStaff.Position = bishopRightArm.Position + Vector3.new(0, -1.5, 0)
        bishopStaff.CFrame = CFrame.new(bishopStaff.Position, bishopStaff.Position + Vector3.new(0, -1, 0))
        
        local distToBishop = (playerPos - bishopTorso.Position).Magnitude
        if bishopAttackTimer >= 5 and distToBishop <= 30 then
            bishopAttackTimer = 0
            task.spawn(function()
                -- Create giant beam
                local beam = Instance.new("Part")
                beam.Size = Vector3.new(8, 100, 8)
                beam.Color = Color3.fromRGB(50, 120, 220)
                beam.Material = Enum.Material.Neon
                beam.Transparency = 0.3
                beam.CanCollide = false
                beam.Anchored = true
                beam.Position = playerPos + Vector3.new(0, 50, 0)
                beam.Parent = workspace
                
                applyDamage("Blue", 20, 30)
                
                TweenService:Create(beam, TweenInfo.new(2), {Transparency = 1}):Play()
                task.delay(2, function()
                    if beam and beam.Parent then beam:Destroy() end
                end)
            end)
        end
        
        -- Knights behavior
        for i, knight in ipairs(knights) do
            knightTimers[i] = knightTimers[i] + dt
            moveTowardsPlayer(knight.torso, 30, dt)
            updateBodyParts(knight.torso, knight.head, knight.leftArm, knight.rightArm, knight.leftLeg, knight.rightLeg, 1)
            
            -- Update horse position
            knight.horseBody.Position = knight.torso.Position + Vector3.new(0, -2, 0)
            knight.horseBody.CFrame = knight.torso.CFrame * CFrame.new(0, -2, 0)
            knight.horseHead.Position = knight.horseBody.Position + knight.horseBody.CFrame.LookVector * 3
            knight.horseHead.CFrame = knight.horseBody.CFrame * CFrame.new(0, 0.5, 3)
            
            -- Check for collision (touch damage)
            local distToKnight = (playerPos - knight.torso.Position).Magnitude
            if distToKnight <= 5 and knightTimers[i] >= 1 then
                knightTimers[i] = 0
                applyDamage("Grey", 9, 30)
                
                -- Fling effect
                if currentChar:FindFirstChild("HumanoidRootPart") then
                    local flingDir = (playerPos - knight.torso.Position).Unit
                    local bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                    bodyVelocity.Velocity = flingDir * 50 + Vector3.new(0, 30, 0)
                    bodyVelocity.Parent = currentChar.HumanoidRootPart
                    
                    task.delay(0.1, function()
                        if bodyVelocity and bodyVelocity.Parent then
                            bodyVelocity:Destroy()
                        end
                    end)
                end
            end
        end
        
        -- Pawns behavior
        for i, pawn in ipairs(pawns) do
            pawnAttackTimers[i] = pawnAttackTimers[i] + dt
            moveTowardsPlayer(pawn.torso, 12, dt)
            updateBodyParts(pawn.torso, pawn.head, pawn.leftArm, pawn.rightArm, pawn.leftLeg, pawn.rightLeg, 0.5)
            
            pawn.axe.Position = pawn.rightArm.Position + Vector3.new(0, -0.75, 0)
            pawn.axe.CFrame = CFrame.new(pawn.axe.Position, pawn.axe.Position + Vector3.new(0, -1, 0))
            pawn.axeHead.Position = pawn.axe.Position + Vector3.new(0, 1.15, 0)
            pawn.axeHead.CFrame = pawn.axe.CFrame * CFrame.new(0, 1.15, 0)
            
            if pawnAttackTimers[i] >= 3 then
                pawnAttackTimers[i] = 0
                local distToPawn = (playerPos - pawn.torso.Position).Magnitude
                if distToPawn <= 5 then
                    applyDamage("Grey", 6, 10)
                end
            end
        end
    end)
    
    illusionLoops["King Chess Family"] = {loop}
end

-- Illusion: Bonehive Disease
local function startBonehiveDisease()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    
    -- Create initial green fog
    local fog = Instance.new("Part")
    fog.Shape = Enum.PartType.Ball
    fog.Size = Vector3.new(20, 20, 20)
    fog.Color = Color3.fromRGB(50, 150, 50)
    fog.Material = Enum.Material.Neon
    fog.Transparency = 0.7
    fog.CanCollide = false
    fog.Anchored = true
    fog.Position = hrp.Position + Vector3.new(30, 0, 0)
    fog.Parent = workspace
    
    -- Fog particle effect
    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
    particles.Color = ColorSequence.new(Color3.fromRGB(50, 150, 50))
    particles.Size = NumberSequence.new(3)
    particles.Lifetime = NumberRange.new(2, 4)
    particles.Rate = 50
    particles.Speed = NumberRange.new(1, 3)
    particles.Transparency = NumberSequence.new(0.5)
    particles.Parent = fog
    
    local fogSize = 20
    local minDmg = 3
    local maxDmg = 8
    local growthTimer = 0
    local damageTimer = 0
    local termiteSpawnTimer = 0
    local bonehives = {}
    local termites = {}
    local playerBonehiveStates = {}
    
    local function createBonehive(position)
        local bonehive = Instance.new("Part")
        bonehive.Size = Vector3.new(4, 4, 4)
        bonehive.Color = Color3.fromRGB(230, 230, 200)
        bonehive.Material = Enum.Material.Cobblestone
        bonehive.Anchored = true
        bonehive.CanCollide = false
        bonehive.Position = position
        bonehive.Parent = workspace
        
        -- Add bone texture details
        for i = 1, 5 do
            local bone = Instance.new("Part")
            bone.Size = Vector3.new(0.5, math.random(10, 20) / 10, 0.5)
            bone.Color = Color3.fromRGB(255, 255, 240)
            bone.Material = Enum.Material.Marble
            bone.Anchored = true
            bone.CanCollide = false
            local angle = math.random() * math.pi * 2
            local dist = math.random(5, 15) / 10
            bone.Position = bonehive.Position + Vector3.new(math.cos(angle) * dist, math.random(-10, 10) / 10, math.sin(angle) * dist)
            bone.Orientation = Vector3.new(math.random(-45, 45), math.random(0, 360), math.random(-45, 45))
            bone.Parent = bonehive
        end
        
        table.insert(bonehives, bonehive)
        
        -- Increase fog size by 5 studs
        fogSize = fogSize + 5
        fog.Size = Vector3.new(fogSize, fogSize, fogSize)
    end
    
    local function spawnTermite(bonehive)
        if not bonehive or not bonehive.Parent then return end
        
        local termite = Instance.new("Part")
        termite.Size = Vector3.new(0.5, 0.3, 1)
        termite.Color = Color3.fromRGB(139, 69, 19)
        termite.Material = Enum.Material.Neon
        termite.Anchored = false
        termite.CanCollide = true
        termite.Position = bonehive.Position + Vector3.new(math.random(-2, 2), 3, math.random(-2, 2))
        termite.Parent = workspace
        
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVel.Parent = termite
        
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
        bodyGyro.P = 3000
        bodyGyro.Parent = termite
        
        table.insert(termites, {
            part = termite,
            vel = bodyVel,
            gyro = bodyGyro,
            attackTimer = 0
        })
    end
    
    local loop = RunService.Heartbeat:Connect(function(dt)
        if not activeIllusions["Bonehive Disease"] then
            if fog and fog.Parent then fog:Destroy() end
            for _, bonehive in ipairs(bonehives) do
                if bonehive and bonehive.Parent then bonehive:Destroy() end
            end
            for _, termite in ipairs(termites) do
                if termite.part and termite.part.Parent then termite.part:Destroy() end
            end
            loop:Disconnect()
            return
        end
        
        local currentChar = player.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        local playerPos = currentChar.HumanoidRootPart.Position
        
        -- Growth timer
        growthTimer = growthTimer + dt
        if growthTimer >= 1 then
            growthTimer = 0
            fogSize = fogSize + 1
            fog.Size = Vector3.new(fogSize, fogSize, fogSize)
            
            -- Increase damage (cap at 100-200)
            if minDmg < 100 then
                minDmg = minDmg + 1
            end
            if maxDmg < 200 then
                maxDmg = maxDmg + 1
            end
        end
        
        -- Check if player is in fog
        local distToFog = (playerPos - fog.Position).Magnitude
        local isInFog = distToFog <= (fogSize / 2)
        
        if isInFog then
            damageTimer = damageTimer + dt
            if damageTimer >= 1 then
                damageTimer = 0
                applyDamage("White", minDmg, maxDmg)
                
                -- Check if SP reached 0 and not already transformed
                if currentSP <= 0 and not playerBonehiveStates[player.UserId] then
                    playerBonehiveStates[player.UserId] = true
                    createBonehive(playerPos)
                    
                    -- Kill the player
                    if currentChar:FindFirstChild("Humanoid") then
                        currentChar.Humanoid.Health = 0
                    end
                    
                    -- Reset the state after respawn
                    task.delay(5, function()
                        playerBonehiveStates[player.UserId] = nil
                    end)
                end
            end
        else
            damageTimer = 0
        end
        
        -- Spawn termites every 10 seconds
        termiteSpawnTimer = termiteSpawnTimer + dt
        if termiteSpawnTimer >= 10 then
            termiteSpawnTimer = 0
            for _, bonehive in ipairs(bonehives) do
                if bonehive and bonehive.Parent then
                    spawnTermite(bonehive)
                end
            end
        end
        
        -- Update termites
        for i = #termites, 1, -1 do
            local termite = termites[i]
            if not termite.part or not termite.part.Parent then
                table.remove(termites, i)
            else
                termite.attackTimer = termite.attackTimer + dt
                
                -- Move towards player
                local dir = (playerPos - termite.part.Position).Unit
                termite.vel.Velocity = Vector3.new(dir.X * 15, -5, dir.Z * 15)
                termite.gyro.CFrame = CFrame.new(termite.part.Position, termite.part.Position + dir)
                
                -- Attack if close
                local distToTermite = (playerPos - termite.part.Position).Magnitude
                if distToTermite <= 3 and termite.attackTimer >= 1 then
                    termite.attackTimer = 0
                    applyDamage("Crimson", 2, 3)
                end
                
                -- Remove if too far from fog
                local distTermiteToFog = (termite.part.Position - fog.Position).Magnitude
                if distTermiteToFog > (fogSize / 2) + 50 then
                    termite.part:Destroy()
                    table.remove(termites, i)
                end
            end
        end
    end)
    
    illusionLoops["Bonehive Disease"] = {loop}
end

-- Create Illusion Entries
local illusions = {
    {
        name = "King Chess Family",
        desc = "The entire chess family: King with staff (Grey 30-50, speed 10), Queen with sword (White 10-30, speed 16), 4 Rooks circling King (Crimson 10-18, speed 20), Bishop with prayer beam (Blue 20-30, speed 18), 2 Knights on horses with fling (Grey 9-30, speed 30), and 5 Pawns with axes (Grey 6-10, speed 12).",
        damageType = "Multiple",
        damageScale = "6 - 50",
        danger = "TZADEL",
        func = startKingChessFamily
    },
    {
        name = "Bonehive Disease",
        desc = "A moving green fog that grows 1 stud every second. Players inside take 3-8 White damage per second (scales up to 100-200). If SP reaches 0 in the fog, player transforms into a bonehive (increases fog size by 5 studs). Every 10 seconds, bone termites spawn dealing 2-3 Crimson damage.",
        damageType = "White",
        damageScale = "3 - 8 → 100 - 200",
        danger = "SAMECH",
        func = startBonehiveDisease
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
    descLabel.Size = UDim2.new(1, -10, 0, 60)
    descLabel.Position = UDim2.new(0, 5, 0, 30)
    descLabel.Text = illusion.desc
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 9
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

-- Reset stats on respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    resetStats()
end)
