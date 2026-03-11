-- Slap Battles Game Script
-- Gloves: Tornado Glove, Shadow Glove, Chain Glove

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local Debris         = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
    MAX_FAKE_PLAYERS = 5,
    AGGRO_DISTANCE   = 100,
    SLAP_DISTANCE    = 5,
    RESPAWN_TIME     = 3,
    ARENA_SIZE       = 200,
}

-- ============================================================
-- GLOVE DATA  (3 gloves only)
-- ============================================================
--[[
  Tornado Glove
    Push Power      : 5
    Slap Cooldown   : 2s
    Fake-player AI  : When within 35 studs, the fake player spawns a small
                      chasing tornado on the player. The tornado follows the
                      player for 5 seconds; every 0.5s the player is inside
                      it takes a 2-power push in a random direction.
    Player Ability  : Summons a large tornado at the player's feet. All fake
                      players within 25 studs are spun upward with continuous
                      2-power random pushes every 0.3 seconds for 3 seconds.
                      A visual spinning funnel (stacked neon rings) grows from
                      the ground and fades out after the duration.
    Ability Cooldown: 24s

  Shadow Glove
    Push Power      : 6
    Slap Cooldown   : 1.8s
    Fake-player AI  : When within 50 studs, the fake player fades out,
                      sneaks behind the real player in 2 seconds, then
                      reappears and delivers a 2× boosted slap.
    Player Ability  : Player fades to near-invisibility for 3 seconds;
                      WalkSpeed is doubled. The first slap made during or
                      immediately after the shadow state deals 2× push power
                      and ends the effect early.
    Ability Cooldown: 20s

  Chain Glove
    Push Power      : 4
    Slap Cooldown   : 1.2s
    Fake-player AI  : When 2+ fake players are within 25 studs of the real
                      player, they highlight gold, rush together, and slap
                      simultaneously with a chain-beam visual.
    Player Ability  : Arms the next slap with a chain. The primary hit
                      bounces to up to 3 nearby fake players within 20 studs
                      at 50% power, with a golden beam drawn between each
                      chained target.
    Ability Cooldown: 18s
]]
local GLOVE_DATA = {
    ["Tornado Glove"] = {
        PushPower       = 5,
        SlapCooldown    = 2,
        AbilityType     = "Ability",
        Ability         = "Tornado",
        AbilityCooldown = 24,
        Color           = Color3.fromRGB(100, 210, 255),
    },
    ["Shadow Glove"] = {
        PushPower       = 6,
        SlapCooldown    = 1.8,
        AbilityType     = "Ability",
        Ability         = "Shadow",
        AbilityCooldown = 20,
        Color           = Color3.fromRGB(80, 0, 120),
    },
    ["Chain Glove"] = {
        PushPower       = 4,
        SlapCooldown    = 1.2,
        AbilityType     = "Ability",
        Ability         = "Chain",
        AbilityCooldown = 18,
        Color           = Color3.fromRGB(200, 160, 0),
    },
}

-- ============================================================
-- GAME STATE
-- ============================================================
local currentGlove          = "AirBomb Glove"
local equippedGlove         = nil
local lastSlapTime          = 0
local lastAbilityTime       = 0
local fakePlayersList       = {}
local aggroedFakePlayers    = {}
local activeHighlights      = {}
local isTornadoActive       = false
local isShadowActive        = false
local isChainActive         = false

-- ============================================================
-- UI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "SlapBattlesUI"
screenGui.ResetOnSpawn = false
screenGui.Parent       = player:WaitForChild("PlayerGui")

-- Glove toggle button
local gloveButton = Instance.new("TextButton")
gloveButton.Size             = UDim2.new(0, 150, 0, 50)
gloveButton.Position         = UDim2.new(0, 20, 0, 20)
gloveButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
gloveButton.BorderSizePixel  = 2
gloveButton.BorderColor3     = Color3.fromRGB(255, 255, 255)
gloveButton.Text             = "GLOVES"
gloveButton.TextColor3       = Color3.fromRGB(255, 255, 255)
gloveButton.TextScaled       = true
gloveButton.Font             = Enum.Font.GothamBold
gloveButton.Parent           = screenGui

-- Glove selection frame
local gloveSelectionFrame = Instance.new("Frame")
gloveSelectionFrame.Size             = UDim2.new(0, 600, 0, 420)
gloveSelectionFrame.Position         = UDim2.new(0.5, -300, 0.5, -210)
gloveSelectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
gloveSelectionFrame.BorderSizePixel  = 3
gloveSelectionFrame.BorderColor3     = Color3.fromRGB(255, 255, 255)
gloveSelectionFrame.Visible          = false
gloveSelectionFrame.Parent           = screenGui

local selectionTitle = Instance.new("TextLabel")
selectionTitle.Size             = UDim2.new(1, 0, 0, 50)
selectionTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
selectionTitle.BorderSizePixel  = 0
selectionTitle.Text             = "SELECT YOUR GLOVE"
selectionTitle.TextColor3       = Color3.fromRGB(255, 255, 255)
selectionTitle.TextScaled       = true
selectionTitle.Font             = Enum.Font.GothamBold
selectionTitle.Parent           = gloveSelectionFrame

local closeSelectionBtn = Instance.new("TextButton")
closeSelectionBtn.Size             = UDim2.new(0, 40, 0, 40)
closeSelectionBtn.Position         = UDim2.new(1, -45, 0, 5)
closeSelectionBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeSelectionBtn.Text             = "X"
closeSelectionBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeSelectionBtn.TextScaled       = true
closeSelectionBtn.Font             = Enum.Font.GothamBold
closeSelectionBtn.Parent           = gloveSelectionFrame

local gloveScrollFrame = Instance.new("ScrollingFrame")
gloveScrollFrame.Size               = UDim2.new(1, -20, 1, -70)
gloveScrollFrame.Position           = UDim2.new(0, 10, 0, 60)
gloveScrollFrame.BackgroundColor3   = Color3.fromRGB(40, 40, 40)
gloveScrollFrame.BorderSizePixel    = 2
gloveScrollFrame.ScrollBarThickness = 10
gloveScrollFrame.Parent             = gloveSelectionFrame

-- Ability button (mobile / on-screen)
local abilityButton = Instance.new("TextButton")
abilityButton.Size             = UDim2.new(0, 120, 0, 120)
abilityButton.Position         = UDim2.new(1, -140, 1, -260)
abilityButton.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
abilityButton.BorderSizePixel  = 3
abilityButton.BorderColor3     = Color3.fromRGB(255, 255, 255)
abilityButton.Text             = "ABILITY"
abilityButton.TextColor3       = Color3.fromRGB(255, 255, 255)
abilityButton.TextScaled       = true
abilityButton.Font             = Enum.Font.GothamBold
abilityButton.Visible          = false
abilityButton.Parent           = screenGui

-- Slap button (mobile)
local slapButton = Instance.new("TextButton")
slapButton.Size             = UDim2.new(0, 120, 0, 120)
slapButton.Position         = UDim2.new(1, -140, 1, -140)
slapButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
slapButton.BorderSizePixel  = 3
slapButton.BorderColor3     = Color3.fromRGB(255, 255, 255)
slapButton.Text             = "SLAP"
slapButton.TextColor3       = Color3.fromRGB(255, 255, 255)
slapButton.TextScaled       = true
slapButton.Font             = Enum.Font.GothamBold
slapButton.Parent           = screenGui

-- Stats panel
local statsFrame = Instance.new("Frame")
statsFrame.Size                 = UDim2.new(0, 250, 0, 130)
statsFrame.Position             = UDim2.new(1, -270, 0, 20)
statsFrame.BackgroundColor3     = Color3.fromRGB(30, 30, 30)
statsFrame.BackgroundTransparency = 0.3
statsFrame.BorderSizePixel      = 2
statsFrame.BorderColor3         = Color3.fromRGB(255, 255, 255)
statsFrame.Parent               = screenGui

local statsHeader = Instance.new("TextLabel")
statsHeader.Size               = UDim2.new(1, 0, 0, 28)
statsHeader.BackgroundTransparency = 1
statsHeader.Text               = "CURRENT GLOVE"
statsHeader.TextColor3         = Color3.fromRGB(255, 255, 255)
statsHeader.TextScaled         = true
statsHeader.Font               = Enum.Font.GothamBold
statsHeader.Parent             = statsFrame

local gloveNameLabel = Instance.new("TextLabel")
gloveNameLabel.Name               = "GloveName"
gloveNameLabel.Size               = UDim2.new(1, -10, 0, 24)
gloveNameLabel.Position           = UDim2.new(0, 5, 0, 32)
gloveNameLabel.BackgroundTransparency = 1
gloveNameLabel.TextColor3         = Color3.fromRGB(255, 255, 0)
gloveNameLabel.TextSize           = 16
gloveNameLabel.Font               = Enum.Font.GothamBold
gloveNameLabel.TextXAlignment     = Enum.TextXAlignment.Left
gloveNameLabel.Parent             = statsFrame

local statsInfoLabel = Instance.new("TextLabel")
statsInfoLabel.Name               = "StatsInfo"
statsInfoLabel.Size               = UDim2.new(1, -10, 1, -65)
statsInfoLabel.Position           = UDim2.new(0, 5, 0, 60)
statsInfoLabel.BackgroundTransparency = 1
statsInfoLabel.TextColor3         = Color3.fromRGB(200, 200, 200)
statsInfoLabel.TextSize           = 13
statsInfoLabel.Font               = Enum.Font.Gotham
statsInfoLabel.TextXAlignment     = Enum.TextXAlignment.Left
statsInfoLabel.TextYAlignment     = Enum.TextYAlignment.Top
statsInfoLabel.Parent             = statsFrame

-- Slap cooldown bar
local cooldownBar = Instance.new("Frame")
cooldownBar.Size             = UDim2.new(0, 200, 0, 20)
cooldownBar.Position         = UDim2.new(0.5, -100, 1, -100)
cooldownBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
cooldownBar.BorderSizePixel  = 2
cooldownBar.BorderColor3     = Color3.fromRGB(255, 255, 255)
cooldownBar.Parent           = screenGui

local cooldownFill = Instance.new("Frame")
cooldownFill.Size             = UDim2.new(1, 0, 1, 0)
cooldownFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
cooldownFill.BorderSizePixel  = 0
cooldownFill.Parent           = cooldownBar

local cooldownText = Instance.new("TextLabel")
cooldownText.Size                  = UDim2.new(1, 0, 1, 0)
cooldownText.BackgroundTransparency = 1
cooldownText.Text                  = "READY"
cooldownText.TextColor3            = Color3.fromRGB(255, 255, 255)
cooldownText.TextScaled            = true
cooldownText.Font                  = Enum.Font.GothamBold
cooldownText.TextStrokeTransparency = 0.5
cooldownText.ZIndex                = 2
cooldownText.Parent                = cooldownBar

-- ============================================================
-- HELPER: build glove selection buttons
-- ============================================================
local function createGloveButtons()
    local yOffset = 0
    for gloveName, gd in pairs(GLOVE_DATA) do
        local frame = Instance.new("Frame")
        frame.Size             = UDim2.new(1, -20, 0, 105)
        frame.Position         = UDim2.new(0, 10, 0, yOffset)
        frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        frame.BorderSizePixel  = 2
        frame.BorderColor3     = gd.Color
        frame.Parent           = gloveScrollFrame

        local nLabel = Instance.new("TextLabel")
        nLabel.Size               = UDim2.new(1, -10, 0, 26)
        nLabel.Position           = UDim2.new(0, 5, 0, 5)
        nLabel.BackgroundTransparency = 1
        nLabel.Text               = gloveName
        nLabel.TextColor3         = gd.Color
        nLabel.TextScaled         = true
        nLabel.Font               = Enum.Font.GothamBold
        nLabel.TextXAlignment     = Enum.TextXAlignment.Left
        nLabel.Parent             = frame

        local sLabel = Instance.new("TextLabel")
        sLabel.Size               = UDim2.new(1, -10, 0, 36)
        sLabel.Position           = UDim2.new(0, 5, 0, 35)
        sLabel.BackgroundTransparency = 1
        sLabel.Text               = string.format(
            "Push: %d  |  Slap CD: %.1fs  |  Ability CD: %ds",
            gd.PushPower, gd.SlapCooldown, gd.AbilityCooldown
        )
        sLabel.TextColor3         = Color3.fromRGB(200, 200, 200)
        sLabel.TextSize           = 13
        sLabel.Font               = Enum.Font.Gotham
        sLabel.TextXAlignment     = Enum.TextXAlignment.Left
        sLabel.TextWrapped        = true
        sLabel.Parent             = frame

        local selBtn = Instance.new("TextButton")
        selBtn.Size             = UDim2.new(0, 120, 0, 28)
        selBtn.Position         = UDim2.new(1, -130, 1, -33)
        selBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        selBtn.Text             = "SELECT"
        selBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
        selBtn.TextScaled       = true
        selBtn.Font             = Enum.Font.GothamBold
        selBtn.Parent           = frame

        selBtn.MouseButton1Click:Connect(function()
            currentGlove = gloveName
            gloveSelectionFrame.Visible = false
            updateGloveAppearance()
        end)

        yOffset += 115
    end
    gloveScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function applyForce(targetCharacter, direction, power)
    if not targetCharacter then return end
    local tRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    local tHum  = targetCharacter:FindFirstChild("Humanoid")
    if not tRoot then return end
    if tHum then tHum.Sit = true end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(4e4, 4e4, 4e4)
    bv.Velocity = direction * power * 10 + Vector3.new(0, power * 5, 0)
    bv.Parent   = tRoot
    Debris:AddItem(bv, 0.3)

    spawn(function()
        wait(0.3)
        if tHum and tHum.Sit then
            local conn
            conn = tRoot.Touched:Connect(function(hit)
                if hit:IsA("BasePart") and not hit:IsDescendantOf(targetCharacter) then
                    wait(0.1)
                    tHum.Sit = false
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)
end

local function createSlapEffect(pos, color)
    local p = Instance.new("Part")
    p.Shape       = Enum.PartType.Ball
    p.Size        = Vector3.new(2, 2, 2)
    p.Position    = pos
    p.Anchored    = true
    p.CanCollide  = false
    p.Material    = Enum.Material.Neon
    p.Color       = color
    p.Transparency = 0.3
    p.Parent      = workspace
    TweenService:Create(p, TweenInfo.new(0.3), {Size = Vector3.new(5,5,5), Transparency = 1}):Play()
    Debris:AddItem(p, 0.5)
end

local function randomDirection()
    local angle = math.random() * math.pi * 2
    local elev  = (math.random() - 0.5) * math.pi * 0.5
    return Vector3.new(
        math.cos(angle) * math.cos(elev),
        math.sin(elev),
        math.sin(angle) * math.cos(elev)
    ).Unit
end

-- Golden beam visual for Chain ability
local function createChainBeam(from, to, color)
    local mid  = (from + to) / 2
    local dist = (to - from).Magnitude
    local beam = Instance.new("Part")
    beam.Size        = Vector3.new(0.35, 0.35, dist)
    beam.CFrame      = CFrame.new(mid, to)
    beam.Anchored    = true
    beam.CanCollide  = false
    beam.Material    = Enum.Material.Neon
    beam.Color       = color
    beam.Transparency = 0.15
    beam.Parent      = workspace
    TweenService:Create(beam, TweenInfo.new(0.5), {Transparency = 1}):Play()
    Debris:AddItem(beam, 0.5)
end

-- Update stats panel and glove appearance
local function updateStatsDisplay()
    local gd = GLOVE_DATA[currentGlove]
    gloveNameLabel.Text  = currentGlove
    statsInfoLabel.Text  = string.format(
        "Push Power: %d\nSlap Cooldown: %.1fs\nAbility CD: %ds",
        gd.PushPower, gd.SlapCooldown, gd.AbilityCooldown
    )
end

function updateGloveAppearance()
    updateStatsDisplay()
    if equippedGlove and equippedGlove:FindFirstChild("Handle") then
        equippedGlove.Handle.Color = GLOVE_DATA[currentGlove].Color
    end
end

-- ============================================================
-- ABILITY: TORNADO
-- ============================================================
-- Player   → Summons a large spinning funnel (stacked neon rings) at
--            the player's feet. All fake players within 25 studs receive
--            a random-direction 2-power push every 0.3 seconds for 3 s.
--            Rings grow upward and fade out at the end.
-- Fake player → When ≤35 studs from the real player, spawns a small
--               chasing tornado on the player. The tornado follows the
--               player for 5 seconds; every 0.5s while inside, the
--               player is pushed 2 power in a random direction.
-- ============================================================
local function spawnTornadoVisual(basePos, scale, color, duration)
    -- Build stacked rings that rotate and fade
    local rings = {}
    local numRings = 6
    for i = 1, numRings do
        local ring = Instance.new("Part")
        ring.Shape       = Enum.PartType.Ball
        ring.Size        = Vector3.new(scale * (1 + i * 0.18), 0.5, scale * (1 + i * 0.18))
        ring.Position    = basePos + Vector3.new(0, i * (scale * 0.35), 0)
        ring.Anchored    = true
        ring.CanCollide  = false
        ring.Material    = Enum.Material.Neon
        ring.Color       = color
        ring.Transparency = 0.35 + i * 0.07
        ring.CFrame      = CFrame.new(ring.Position)
        ring.Parent      = workspace
        table.insert(rings, ring)
    end

    -- Spin and drift upward, then fade
    local t0 = tick()
    local spinConn
    spinConn = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - t0
        if elapsed >= duration then
            spinConn:Disconnect()
            for _, r in ipairs(rings) do
                if r.Parent then
                    TweenService:Create(r, TweenInfo.new(0.4), {Transparency = 1}):Play()
                    Debris:AddItem(r, 0.4)
                end
            end
            return
        end
        local angle = elapsed * 4  -- radians per second
        for i, ring in ipairs(rings) do
            if ring.Parent then
                local r   = scale * (1 + i * 0.18) * 0.5
                local cx  = basePos.X + math.cos(angle + i) * r * 0.2
                local cz  = basePos.Z + math.sin(angle + i) * r * 0.2
                ring.CFrame = CFrame.new(cx, basePos.Y + i * (scale * 0.35) + elapsed * 0.5, cz)
                            * CFrame.Angles(0, angle + i, 0)
            end
        end
    end)
    return spinConn
end

local function activateTornadoAbility(caster, isPlayer)
    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        if isTornadoActive then return end
        isTornadoActive = true

        local origin = character.HumanoidRootPart.Position
        local duration = 3
        local spinConn = spawnTornadoVisual(origin, 5, Color3.fromRGB(100, 210, 255), duration)

        -- Pulse fake players every 0.3 s for the duration
        local t0 = tick()
        local pulseConn
        pulseConn = RunService.Heartbeat:Connect(function()
            if tick() - t0 >= duration then
                pulseConn:Disconnect()
                if spinConn then spinConn:Disconnect() end
                isTornadoActive = false
                return
            end
        end)

        spawn(function()
            local intervals = math.floor(duration / 0.3)
            for _ = 1, intervals do
                wait(0.3)
                if not isTornadoActive then break end
                local cRoot = character and character:FindFirstChild("HumanoidRootPart")
                if not cRoot then break end
                for _, fp in ipairs(fakePlayersList) do
                    if fp.rootPart and (fp.rootPart.Position - cRoot.Position).Magnitude <= 25 then
                        applyForce(fp.character, randomDirection(), 2)
                        if not table.find(aggroedFakePlayers, fp) then
                            table.insert(aggroedFakePlayers, fp)
                            fp.isAggro = true
                        end
                    end
                end
            end
            isTornadoActive = false
            if pulseConn then pulseConn:Disconnect() end
            if spinConn   then spinConn:Disconnect()  end
        end)

    else
        -- Fake-player spawns a small chasing tornado on the real player
        if not caster.character or not caster.rootPart then return end
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        local dist = (character.HumanoidRootPart.Position - caster.rootPart.Position).Magnitude
        if dist > 35 then return end

        local pRoot    = character.HumanoidRootPart
        local duration = 5
        -- Small visual tornado that follows the player
        local tornado = Instance.new("Part")
        tornado.Shape      = Enum.PartType.Ball
        tornado.Size       = Vector3.new(5, 7, 5)
        tornado.Anchored   = true
        tornado.CanCollide = false
        tornado.Material   = Enum.Material.Neon
        tornado.Color      = Color3.fromRGB(100, 210, 255)
        tornado.Transparency = 0.5
        tornado.Parent     = workspace

        local t0 = tick()
        local trackConn
        trackConn = RunService.Heartbeat:Connect(function()
            if tick() - t0 >= duration then
                trackConn:Disconnect()
                if tornado.Parent then
                    TweenService:Create(tornado, TweenInfo.new(0.4), {Transparency = 1}):Play()
                    Debris:AddItem(tornado, 0.4)
                end
                return
            end
            if pRoot.Parent then
                tornado.Position = pRoot.Position + Vector3.new(0, 2, 0)
                tornado.CFrame   = CFrame.new(tornado.Position) * CFrame.Angles(0, tick() * 4, 0)
            end
        end)

        spawn(function()
            local intervals = math.floor(duration / 0.5)
            for _ = 1, intervals do
                wait(0.5)
                if not (tornado.Parent) then break end
                if character and character:FindFirstChild("HumanoidRootPart") then
                    applyForce(character, randomDirection(), 2)
                end
            end
            if trackConn then trackConn:Disconnect() end
            if tornado.Parent then tornado:Destroy() end
        end)
    end
end

-- ============================================================
-- ABILITY: SHADOW
-- ============================================================
-- Player   → Goes near-invisible (0.75 transparency) for 3 seconds.
--            WalkSpeed ×2.  First slap during/after = 2× push power
--            and ends the effect early.
-- Fake player → When ≤50 studs, fades out, sneaks behind the real
--               player in ~2 seconds, reappears, then delivers a
--               2× boosted slap.
-- ============================================================
local function activateShadowAbility(caster, isPlayer)
    if isPlayer then
        if not character or not humanoid then return end
        if isShadowActive then return end
        isShadowActive = true

        local originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed  = originalSpeed * 2

        -- Fade character
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = 0.75
            end
        end

        -- Dark purple aura
        local aura = Instance.new("Part")
        aura.Name       = "ShadowAura"
        aura.Shape      = Enum.PartType.Ball
        aura.Size       = Vector3.new(6, 6, 6)
        aura.Anchored   = true
        aura.CanCollide = false
        aura.Material   = Enum.Material.Neon
        aura.Color      = Color3.fromRGB(80, 0, 120)
        aura.Transparency = 0.55
        aura.Parent     = workspace

        local auraConn = RunService.Heartbeat:Connect(function()
            if aura.Parent and character and character:FindFirstChild("HumanoidRootPart") then
                aura.Position = character.HumanoidRootPart.Position
            end
        end)

        -- Auto-end after 3 seconds
        spawn(function()
            wait(3)
            if isShadowActive then
                isShadowActive = false
                if humanoid then humanoid.WalkSpeed = originalSpeed end
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.Transparency = 0
                    end
                end
                auraConn:Disconnect()
                if aura.Parent then aura:Destroy() end
            end
        end)

    else
        -- Fake-player shadow AI
        if not caster.character or not caster.rootPart or not caster.humanoid then return end
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        if caster.isShadowActive then return end

        local dist = (character.HumanoidRootPart.Position - caster.rootPart.Position).Magnitude
        if dist > 50 then return end

        caster.isShadowActive = true

        -- Fade out
        for _, part in ipairs(caster.character:GetDescendants()) do
            if part:IsA("BasePart") then part.Transparency = 0.88 end
        end
        local origSpeed = caster.humanoid.WalkSpeed
        caster.humanoid.WalkSpeed = origSpeed * 2

        spawn(function()
            wait(0.5)
            -- Sneak behind player
            local pRoot = character:FindFirstChild("HumanoidRootPart")
            if pRoot and caster.humanoid then
                local behindPos = pRoot.Position - pRoot.CFrame.LookVector * 5 + Vector3.new(0, 0.5, 0)
                caster.humanoid:MoveTo(behindPos)
            end

            wait(1.8)

            -- Reappear
            if caster.character then
                for _, part in ipairs(caster.character:GetDescendants()) do
                    if part:IsA("BasePart") then part.Transparency = 0 end
                end
                if caster.humanoid then caster.humanoid.WalkSpeed = origSpeed end
            end

            -- 2× boosted slap
            local pRootNow = character and character:FindFirstChild("HumanoidRootPart")
            if pRootNow and caster.rootPart then
                local dir = (pRootNow.Position - caster.rootPart.Position).Unit
                createSlapEffect(caster.rootPart.Position + dir * 3, GLOVE_DATA["Shadow Glove"].Color)
                applyForce(character, dir, GLOVE_DATA["Shadow Glove"].PushPower * 2)
            end

            caster.isShadowActive = false
        end)
    end
end

-- ============================================================
-- ABILITY: CHAIN
-- ============================================================
-- Player   → Arms next slap. On hit, the push bounces to up to 3
--            nearby fake players within 20 studs at 50% power.
--            Golden beams are drawn between chained targets.
-- Fake player → If 2+ fake players are within 25 studs of the real
--               player, they highlight gold, rush together, and slap
--               simultaneously.
-- ============================================================
local function activateChainAbility(caster, isPlayer)
    if isPlayer then
        if isChainActive then return end
        isChainActive = true

        abilityButton.BackgroundColor3 = Color3.fromRGB(200, 160, 0)
        abilityButton.Text             = "CHAIN\nREADY"

        -- Auto-cancel after 8 s if never consumed
        spawn(function()
            wait(8)
            if isChainActive then
                isChainActive                  = false
                abilityButton.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
                abilityButton.Text             = "ABILITY"
            end
        end)

    else
        -- Fake-player coordinated chain slap
        if not caster.character or not caster.rootPart then return end
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        local pRoot = character.HumanoidRootPart

        -- Gather allies within 25 studs of the real player
        local allies = {caster}
        for _, fp in ipairs(fakePlayersList) do
            if fp ~= caster and fp.isAggro and fp.rootPart then
                if (fp.rootPart.Position - pRoot.Position).Magnitude <= 25 then
                    table.insert(allies, fp)
                    if #allies >= 3 then break end
                end
            end
        end
        if #allies < 2 then return end  -- need at least 2 for a real chain

        -- Gold highlight on all participants
        for _, fp in ipairs(allies) do
            if fp.character then
                local hl = Instance.new("Highlight")
                hl.FillColor        = Color3.fromRGB(200, 160, 0)
                hl.OutlineColor     = Color3.fromRGB(255, 220, 0)
                hl.FillTransparency = 0.35
                hl.OutlineTransparency = 0
                hl.Parent           = fp.character
                Debris:AddItem(hl, 2)
            end
        end

        -- All rush in, then slap simultaneously after 1 second
        spawn(function()
            for _, fp in ipairs(allies) do
                if fp.humanoid and fp.rootPart then
                    fp.humanoid:MoveTo(pRoot.Position)
                end
            end
            wait(1)
            for _, fp in ipairs(allies) do
                if fp.rootPart and character and character:FindFirstChild("HumanoidRootPart") then
                    local pRootNow = character.HumanoidRootPart
                    local dir = (pRootNow.Position - fp.rootPart.Position).Unit
                    createSlapEffect(fp.rootPart.Position + dir * 3, GLOVE_DATA["Chain Glove"].Color)
                    applyForce(character, dir, GLOVE_DATA["Chain Glove"].PushPower)
                    createChainBeam(fp.rootPart.Position, pRootNow.Position, GLOVE_DATA["Chain Glove"].Color)
                end
            end
        end)
    end
end

-- ============================================================
-- PLAYER SLAP
-- ============================================================
local function playerSlap()
    if not equippedGlove or not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local now  = tick()
    local gd   = GLOVE_DATA[currentGlove]
    if now - lastSlapTime < gd.SlapCooldown then return end
    lastSlapTime = now

    local cRoot   = character.HumanoidRootPart
    local slapPos = cRoot.Position + cRoot.CFrame.LookVector * 3
    createSlapEffect(slapPos, gd.Color)

    -- Shadow state: end early, apply 2× boost to this slap
    local shadowBoost = 1
    if currentGlove == "Shadow Glove" and isShadowActive then
        shadowBoost    = 2
        isShadowActive = false
        if humanoid then humanoid.WalkSpeed = humanoid.WalkSpeed / 2 end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Transparency = 0
            end
        end
        local aura = workspace:FindFirstChild("ShadowAura")
        if aura then aura:Destroy() end
    end

    -- Find and hit fake players in range
    local primaryTarget = nil
    for _, fp in ipairs(fakePlayersList) do
        if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
            local fRoot = fp.character.HumanoidRootPart
            if (fRoot.Position - slapPos).Magnitude <= CONFIG.SLAP_DISTANCE then
                local dir = (fRoot.Position - cRoot.Position).Unit
                applyForce(fp.character, dir, gd.PushPower * shadowBoost)
                fp.slapsTaken = (fp.slapsTaken or 0) + 1
                if not table.find(aggroedFakePlayers, fp) then
                    table.insert(aggroedFakePlayers, fp)
                    fp.isAggro = true
                end
                if not primaryTarget then primaryTarget = fp end

                -- Chain: bounce to nearby fake players
                if currentGlove == "Chain Glove" and isChainActive then
                    isChainActive                  = false
                    abilityButton.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
                    abilityButton.Text             = "ABILITY"

                    createChainBeam(slapPos, fRoot.Position, GLOVE_DATA["Chain Glove"].Color)

                    local bounced = 0
                    for _, other in ipairs(fakePlayersList) do
                        if other ~= fp and other.character and other.character:FindFirstChild("HumanoidRootPart") then
                            local oRoot = other.character.HumanoidRootPart
                            if (oRoot.Position - fRoot.Position).Magnitude <= 20 then
                                local chainDir = (oRoot.Position - fRoot.Position).Unit
                                applyForce(other.character, chainDir, gd.PushPower * 0.5)
                                createChainBeam(fRoot.Position, oRoot.Position, GLOVE_DATA["Chain Glove"].Color)
                                if not table.find(aggroedFakePlayers, other) then
                                    table.insert(aggroedFakePlayers, other)
                                    other.isAggro = true
                                end
                                bounced += 1
                                if bounced >= 3 then break end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================
-- UI CONNECTIONS
-- ============================================================
gloveButton.MouseButton1Click:Connect(function()
    gloveSelectionFrame.Visible = not gloveSelectionFrame.Visible
end)
closeSelectionBtn.MouseButton1Click:Connect(function()
    gloveSelectionFrame.Visible = false
end)
slapButton.MouseButton1Click:Connect(function()
    playerSlap()
end)

abilityButton.MouseButton1Click:Connect(function()
    local now = tick()
    local gd  = GLOVE_DATA[currentGlove]

    -- Don't let Chain fire again while already armed
    if currentGlove == "Chain Glove" and isChainActive then return end
    if now - lastAbilityTime < gd.AbilityCooldown then return end
    lastAbilityTime = now

    if     gd.Ability == "Tornado" then activateTornadoAbility(nil, true)
    elseif gd.Ability == "Shadow"  then activateShadowAbility(nil, true)
    elseif gd.Ability == "Chain"   then activateChainAbility(nil, true)
    end

    -- Countdown display
    local cdLeft = gd.AbilityCooldown
    spawn(function()
        for i = cdLeft, 0, -1 do
            if currentGlove == "Chain Glove" and isChainActive then
                abilityButton.Text = "CHAIN\nREADY"
            else
                abilityButton.Text = i > 0 and tostring(i) or "ABILITY"
            end
            wait(1)
        end
        if not (currentGlove == "Chain Glove" and isChainActive) then
            abilityButton.Text             = "ABILITY"
            abilityButton.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
        end
    end)
end)

-- Keyboard shortcuts
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E then
        playerSlap()
    elseif input.KeyCode == Enum.KeyCode.Q then
        abilityButton.MouseButton1Click:Fire()
    end
end)

-- Cooldown bar + stats live update
RunService.Heartbeat:Connect(function()
    local gd      = GLOVE_DATA[currentGlove]
    local elapsed = tick() - lastSlapTime
    if elapsed >= gd.SlapCooldown then
        cooldownFill.Size             = UDim2.new(1, 0, 1, 0)
        cooldownFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        cooldownText.Text             = "READY"
    else
        local progress = elapsed / gd.SlapCooldown
        cooldownFill.Size             = UDim2.new(progress, 0, 1, 0)
        cooldownFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        cooldownText.Text             = string.format("%.1f", gd.SlapCooldown - elapsed)
    end
    if gloveNameLabel.Text ~= currentGlove then
        updateStatsDisplay()
    end
end)

-- ============================================================
-- FAKE PLAYER CREATION
-- ============================================================
local function createFakePlayer(name, glove)
    local fp = {
        name          = name,
        currentGlove  = glove,
        lastSlapTime  = 0,
        lastAbilityTime = 0,
        isAggro       = false,
        isShadowActive = false,
        slapsTaken    = 0,
        slapsGiven    = 0,
        character     = nil,
        humanoid      = nil,
        rootPart      = nil,
        wanderTarget  = nil,
    }

    local model = Instance.new("Model")
    model.Name  = name
    model.Parent = workspace

    local sp = Vector3.new(
        math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2),
        5,
        math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2)
    )

    local function mkPart(n, sz, col, pos)
        local p = Instance.new("Part")
        p.Name = n; p.Size = sz; p.Color = col
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Position = pos; p.Parent = model
        return p
    end

    local hrp  = mkPart("HumanoidRootPart", Vector3.new(2,2,1), Color3.fromRGB(200,200,200), sp)
    hrp.Transparency = 1
    local torso = mkPart("Torso",    Vector3.new(2,2,1), Color3.fromRGB(0,100,200),     sp)
    local head  = mkPart("Head",     Vector3.new(2,1,1), Color3.fromRGB(255,204,153),   sp + Vector3.new(0,1.5,0))
    local lArm  = mkPart("Left Arm", Vector3.new(1,2,1), Color3.fromRGB(255,204,153),   sp + Vector3.new(-1.5,0,0))
    local rArm  = mkPart("Right Arm",Vector3.new(1,2,1), Color3.fromRGB(255,204,153),   sp + Vector3.new(1.5,0,0))
    local lLeg  = mkPart("Left Leg", Vector3.new(1,2,1), Color3.fromRGB(0,180,0),       sp + Vector3.new(-0.5,-2,0))
    local rLeg  = mkPart("Right Leg",Vector3.new(1,2,1), Color3.fromRGB(0,180,0),       sp + Vector3.new(0.5,-2,0))

    local face = Instance.new("Decal")
    face.Texture = "rbxasset://textures/face.png"
    face.Parent  = head

    local function weld(p0, p1, c0)
        local w = Instance.new("Weld"); w.Part0 = p0; w.Part1 = p1; w.C0 = c0; w.Parent = p0
    end
    weld(torso, hrp,  CFrame.new())
    weld(torso, head, CFrame.new(0,1.5,0))
    weld(torso, lArm, CFrame.new(-1.5,0,0))
    weld(torso, rArm, CFrame.new(1.5,0,0))
    weld(torso, lLeg, CFrame.new(-0.5,-2,0))
    weld(torso, rLeg, CFrame.new(0.5,-2,0))

    local hum = Instance.new("Humanoid"); hum.Parent = model

    -- Glove visual
    local gv = Instance.new("Part")
    gv.Size = Vector3.new(1,1,1); gv.Color = GLOVE_DATA[glove].Color
    gv.Material = Enum.Material.Neon; gv.Parent = model
    weld(rArm, gv, CFrame.new(0,-1,0))

    -- Name tag
    local bbg = Instance.new("BillboardGui")
    bbg.Size        = UDim2.new(0,130,0,50)
    bbg.StudsOffset = Vector3.new(0,2.5,0)
    bbg.AlwaysOnTop = true
    bbg.Parent      = head

    local nTag = Instance.new("TextLabel")
    nTag.Size               = UDim2.new(1,0,0.55,0)
    nTag.BackgroundTransparency = 1
    nTag.Text               = name
    nTag.TextColor3         = Color3.fromRGB(255,255,255)
    nTag.TextScaled         = true
    nTag.Font               = Enum.Font.GothamBold
    nTag.TextStrokeTransparency = 0.4
    nTag.Parent             = bbg

    local gTag = Instance.new("TextLabel")
    gTag.Size               = UDim2.new(1,0,0.45,0)
    gTag.Position           = UDim2.new(0,0,0.55,0)
    gTag.BackgroundTransparency = 1
    gTag.Text               = glove
    gTag.TextColor3         = GLOVE_DATA[glove].Color
    gTag.TextScaled         = true
    gTag.Font               = Enum.Font.Gotham
    gTag.TextStrokeTransparency = 0.4
    gTag.Parent             = bbg

    fp.character    = model
    fp.humanoid     = hum
    fp.rootPart     = hrp
    fp.wanderTarget = sp
    return fp
end

-- ============================================================
-- FAKE PLAYER AI
-- ============================================================
local function updateFakePlayerAI(fp)
    if not fp.character or not fp.rootPart or not fp.humanoid then return end
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    if humanoid.Health <= 0 then return end

    local fRoot  = fp.rootPart
    local pRoot  = character.HumanoidRootPart
    local dist   = (pRoot.Position - fRoot.Position).Magnitude

    -- Auto-aggro
    if dist <= CONFIG.AGGRO_DISTANCE and not fp.isAggro then
        fp.isAggro = true
        if not table.find(aggroedFakePlayers, fp) then
            table.insert(aggroedFakePlayers, fp)
        end
    end

    if fp.isAggro then
        fp.humanoid:MoveTo(pRoot.Position)

        -- Slap when in range
        if dist <= CONFIG.SLAP_DISTANCE then
            local now = tick()
            local gd  = GLOVE_DATA[fp.currentGlove]
            if now - fp.lastSlapTime >= gd.SlapCooldown then
                fp.lastSlapTime = now
                local dir = (pRoot.Position - fRoot.Position).Unit
                createSlapEffect(fRoot.Position + dir * 3, gd.Color)
                applyForce(character, dir, gd.PushPower)
                fp.slapsGiven = (fp.slapsGiven or 0) + 1
            end
        end

        -- Ability logic
        local now = tick()
        local gd  = GLOVE_DATA[fp.currentGlove]
        if now - fp.lastAbilityTime >= gd.AbilityCooldown then

            if fp.currentGlove == "Tornado Glove" then
                -- Activate when within 35 studs
                if dist <= 35 then
                    fp.lastAbilityTime = now
                    activateTornadoAbility(fp, false)
                end

            elseif fp.currentGlove == "Shadow Glove" then
                -- Sneak when within 50 studs
                if dist <= 50 then
                    fp.lastAbilityTime = now
                    activateShadowAbility(fp, false)
                end

            elseif fp.currentGlove == "Chain Glove" then
                -- Coordinate when another aggro fake player is also near the player
                local nearbyAllies = 0
                for _, other in ipairs(fakePlayersList) do
                    if other ~= fp and other.isAggro and other.rootPart then
                        if (other.rootPart.Position - pRoot.Position).Magnitude <= 25 then
                            nearbyAllies += 1
                        end
                    end
                end
                if nearbyAllies >= 1 then
                    fp.lastAbilityTime = now
                    activateChainAbility(fp, false)
                end
            end
        end

    else
        -- Wander until aggro
        if not fp.wanderTarget or (fRoot.Position - fp.wanderTarget).Magnitude < 5 then
            fp.wanderTarget = Vector3.new(
                math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2),
                fRoot.Position.Y,
                math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2)
            )
        end
        fp.humanoid:MoveTo(fp.wanderTarget)
    end
end

-- ============================================================
-- GLOVE TOOL
-- ============================================================
local function createGloveTool()
    local tool           = Instance.new("Tool")
    tool.Name            = "Glove"
    tool.RequiresHandle  = true
    tool.CanBeDropped    = false

    local handle         = Instance.new("Part")
    handle.Name          = "Handle"
    handle.Size          = Vector3.new(1.5, 1.5, 1.5)
    handle.CanCollide    = false
    handle.Color         = GLOVE_DATA[currentGlove].Color
    handle.Parent        = tool

    tool.Equipped:Connect(function()
        equippedGlove = tool
        abilityButton.Visible = true
        slapButton.Visible    = true
        updateGloveAppearance()
    end)
    tool.Unequipped:Connect(function()
        equippedGlove         = nil
        abilityButton.Visible = false
        slapButton.Visible    = false
    end)
    tool.Activated:Connect(function()
        playerSlap()
    end)

    tool.Parent = player.Backpack
    return tool
end

-- ============================================================
-- ARENA & WORLD
-- ============================================================
local function createArena()
    local arena = Instance.new("Part")
    arena.Name     = "Arena"
    arena.Size     = Vector3.new(CONFIG.ARENA_SIZE, 1, CONFIG.ARENA_SIZE)
    arena.Position = Vector3.new(0, 0, 0)
    arena.Anchored = true
    arena.Material = Enum.Material.Concrete
    arena.Color    = Color3.fromRGB(150, 150, 150)
    arena.Parent   = workspace

    local sp = Instance.new("SpawnLocation")
    sp.Size        = Vector3.new(10, 1, 10)
    sp.Position    = Vector3.new(0, 1, 0)
    sp.Anchored    = true
    sp.Transparency = 0.5
    sp.BrickColor  = BrickColor.new("Bright green")
    sp.Parent      = workspace

    -- Kill zone below the arena
    local dz = Instance.new("Part")
    dz.Size        = Vector3.new(CONFIG.ARENA_SIZE * 2, 5, CONFIG.ARENA_SIZE * 2)
    dz.Position    = Vector3.new(0, -50, 0)
    dz.Anchored    = true
    dz.CanCollide  = false
    dz.Transparency = 1
    dz.Parent      = workspace
    dz.Touched:Connect(function(hit)
        if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
            hit.Parent.Humanoid.Health = 0
        end
    end)
end

-- ============================================================
-- CHARACTER SETUP & RESPAWN
-- ============================================================
local function setupCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid  = character:WaitForChild("Humanoid")
    rootPart  = character:WaitForChild("HumanoidRootPart")
    createGloveTool()

    humanoid.Died:Connect(function()
        wait(CONFIG.RESPAWN_TIME)
        player:LoadCharacter()
    end)
end

player.CharacterAdded:Connect(function()
    wait(0.5)
    setupCharacter()
end)

-- Fake player health watch + respawn
RunService.Heartbeat:Connect(function()
    local gloveNames = {}
    for n in pairs(GLOVE_DATA) do table.insert(gloveNames, n) end

    for i, fp in ipairs(fakePlayersList) do
        if fp.humanoid and fp.humanoid.Health <= 0 then
            if fp.character then fp.character:Destroy() end
            for j, a in ipairs(aggroedFakePlayers) do
                if a == fp then table.remove(aggroedFakePlayers, j); break end
            end
            local savedName  = fp.name
            local randGlove  = gloveNames[math.random(1, #gloveNames)]
            spawn(function()
                wait(CONFIG.RESPAWN_TIME)
                fakePlayersList[i] = createFakePlayer(savedName, randGlove)
            end)
        end
    end
end)

-- AI loop
RunService.Heartbeat:Connect(function()
    for _, fp in ipairs(fakePlayersList) do
        updateFakePlayerAI(fp)
    end
end)

-- ============================================================
-- INITIALIZE
-- ============================================================
local function initialize()
    print("=== Slap Battles: 3-Glove Edition ===")
    createArena()
    setupCharacter()
    createGloveButtons()
    updateStatsDisplay()

    local gloveNames = {}
    for n in pairs(GLOVE_DATA) do table.insert(gloveNames, n) end

    local botNames = {"Bot_Alpha", "Bot_Beta", "Bot_Gamma", "Bot_Delta", "Bot_Epsilon"}
    for i = 1, CONFIG.MAX_FAKE_PLAYERS do
        local g  = gloveNames[math.random(1, #gloveNames)]
        local fp = createFakePlayer(botNames[i], g)
        table.insert(fakePlayersList, fp)
    end

    print("Ready! Gloves: Tornado | Shadow | Chain")
    print("Controls: E = Slap  |  Q = Ability  |  GLOVES button = select glove")
    print("======================================")
end

wait(1)
initialize()
