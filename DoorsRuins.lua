-- ============================================================
-- THE RUINS - LocalScript Executor
-- Devious Goober  |  Stage 3  |  Doors 375 to 1000
-- Room Types : Normal Bridge (75%) | Stairs (50%) | Gem (20%)
-- Entities   : Disease | Her | Agony | Drain | Plantera | Stem
-- Day/Night  : Tween-based realistic outdoor lighting cycle
-- Hiding     : Ruins Gaps (crumbled wall sections)
-- Sea        : 1000x1000 Terrain Water  -  touch = instant death
-- Items      : Coins | Ecstasy | Gem | Lantern | Pure Gem
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInput    = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== CONSTANTS =====
local RUINS_START       = 375
local RUINS_D           = 60    -- room depth (studs)
local RUINS_W           = 50    -- bridge width
local RUINS_FLOOR_Y     = 5     -- ruins bridge Y
local SEA_Y             = 0     -- sea surface Y
local CAVE_EXIT_Y       = -20   -- lobby cave hole bottom
local DOOR_MAX          = 1000
local CHECKPOINT_EVERY  = 50

local DISEASE_SPEED     = 70
local DISEASE_COOLDOWN  = 12
local DISEASE_BEFORE    = 7     -- UPDATED: 7 rooms back
local DISEASE_AFTER     = 5     -- UPDATED: 5 rooms forward

local AGONY_SPEED       = 90
local AGONY_COOLDOWN    = 18

local HER_COOLDOWN      = 90
local HER_SPEED         = 28

local DRAIN_COOLDOWN    = 40
local DRAIN_RISE_TIME   = 8
local DRAIN_STAY_TIME   = 4
local DRAIN_FALL_TIME   = 6

local PLANTERA_SPEED    = 45
local PLANTERA_COOLDOWN = 12
local PLANTERA_BEFORE   = 7     -- UPDATED: 7 rooms back
local PLANTERA_AFTER    = 5     -- UPDATED: 5 rooms forward

local STEM_COOLDOWN     = 55

local HIDE_DIST         = 5
local GEN_AHEAD         = 6
local CLEAN_BEHIND      = 7
local MAX_ITEMS         = 3

-- Boat constants
local BOAT_SPEED        = 28
local BOAT_KILL_DIST    = 110   -- studs from room center before walls push back
local GEM_MIN_DIST      = 20
local GEM_MAX_DIST      = 60

-- ===== STATE =====
local character         = nil
local humanoid          = nil
local rootPart          = nil
local currentDoor       = RUINS_START
local lastDetectedDoor  = RUINS_START
local gameStarted       = false
local isHiding          = false
local nearGap           = false
local currentGap        = nil
local checkpointDoor    = RUINS_START
local rooms             = {}
local roomIsDark        = {}
local roomType          = {}    -- "normal"|"stairs"|"gem"
local gemRoomStates     = {}    -- [doorNum] = {bridgeRaised=bool, gemTaken=bool}

local diseaseActive     = false
local diseaseOnCooldown = false
local agonyActive       = false
local agonyOnCooldown   = false
local herActive         = false
local herOnCooldown     = false
local drainActive       = false
local drainOnCooldown   = false
local planteraActive    = false
local planteraOnCooldown = false
local planteraSpawned   = false
local stemActive        = false
local stemOnCooldown    = false

local isDead            = false
local hiddenParts       = {}
local inventory         = {}
local coins             = 0
local ecstasyActive     = false
local ecstasyEndTime    = 0
local lastStepTime      = 0
local grassStepSound    = nil
local stoneStepSound    = nil

local onBoat            = false
local playerBoat        = nil
local boatVel           = nil
local boatGyro          = nil

-- Day / night tracking
local currentPeriod     = nil
local clockTime         = 8     -- start at morning

-- ===== FORWARD DECLARATIONS =====
local setupLighting, applyLightingPreset, advanceDayNight
local createHUD, makePart, makeLight, giveTool
local makeRuinsPillar, makeDestroyedPillar, makeRuinsArch
local makeCrumbledWall, makeAncientAltar, makeRuinsDecor
local makeRuinsChest, makeRuinsGap, makeTreeBarrier
local makeBoat, makeGem
local generateNormalRoom, generateStairsRoom, generateGemRoom
local generateRoom, createLobby, startGame, showWarning
local hideInGap, exitGap
local spawnDisease, spawnAgony, spawnHer, spawnDrain, spawnPlantera, spawnStem
local onDoorReached, onDeath, updateCharRef, mainLoop
local getRuinsZ, isNight, isDaytime

-- NEW HELPERS FOR NEW ITEMS
local getEquippedLantern, hasPureGemEquipped

-- ===== GUI REFS =====
local screenGui, doorLabel, coinLabel, warningFrame, warningLabel
local hidePrompt, hideBtnLabel, timeLabel
local stemEyeContainer, stemEyeOuter, stemEyeStroke
local stemIris, stemPupil, stemTopLid, stemBottomLid, stemSnd

-- =================================================================
-- HELPERS
-- =================================================================
getRuinsZ = function(doorNum)
    return -((doorNum - RUINS_START) * RUINS_D)
end

isNight = function()
    local c = clockTime
    return c > 20 or c < 6
end

isDaytime = function()
    local c = clockTime
    return c >= 8 and c <= 18
end

-- NEW: Lantern & Pure Gem equipped checks
getEquippedLantern = function()
    if not character then return nil end
    return character:FindFirstChild("Lantern")
end

hasPureGemEquipped = function()
    if not character then return false end
    return character:FindFirstChild("PureGem") \~= nil
end

-- =================================================================
-- DAY / NIGHT CYCLE  (inline presets - no module require)
-- =================================================================
local LIGHT_PRESETS = {
    Sunrise = {
        Brightness = 1.2, ClockTime = 7,
        FogEnd = 500, FogStart = 80,
        FogColor = Color3.fromRGB(255, 200, 150),
        Ambient = Color3.fromRGB(180, 140, 110),
        OutdoorAmbient = Color3.fromRGB(160, 120, 90),
    },
    Day = {
        Brightness = 2.5, ClockTime = 13,
        FogEnd = 900, FogStart = 200,
        FogColor = Color3.fromRGB(180, 210, 240),
        Ambient = Color3.fromRGB(130, 145, 165),
        OutdoorAmbient = Color3.fromRGB(140, 160, 185),
    },
    GoldenHour = {
        Brightness = 1.4, ClockTime = 17,
        FogEnd = 600, FogStart = 100,
        FogColor = Color3.fromRGB(255, 170, 80),
        Ambient = Color3.fromRGB(200, 140, 80),
        OutdoorAmbient = Color3.fromRGB(210, 150, 70),
    },
    Sunset = {
        Brightness = 0.8, ClockTime = 19,
        FogEnd = 350, FogStart = 60,
        FogColor = Color3.fromRGB(200, 90, 40),
        Ambient = Color3.fromRGB(160, 80, 50),
        OutdoorAmbient = Color3.fromRGB(150, 70, 40),
    },
    Twilight = {
        Brightness = 0.3, ClockTime = 21,
        FogEnd = 200, FogStart = 30,
        FogColor = Color3.fromRGB(20, 20, 55),
        Ambient = Color3.fromRGB(40, 40, 80),
        OutdoorAmbient = Color3.fromRGB(30, 30, 65),
    },
    Night = {
        Brightness = 0.05, ClockTime = 2,
        FogEnd = 120, FogStart = 10,
        FogColor = Color3.fromRGB(5, 5, 18),
        Ambient = Color3.fromRGB(8, 8, 22),
        OutdoorAmbient = Color3.fromRGB(6, 6, 18),
    },
}

applyLightingPreset = function(name)
    if currentPeriod == name then return end
    currentPeriod = name
    local preset = LIGHT_PRESETS[name]
    if not preset then return end
    local L = game:GetService("Lighting")
    local ti = TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for prop, val in pairs(preset) do
        if prop \~= "ClockTime" then
            local ok, _ = pcall(function()
                TweenService:Create(L, ti, { [prop] = val }):Play()
            end)
        end
    end
    L.ClockTime = preset.ClockTime
end

setupLighting = function()
    local L = game:GetService("Lighting")
    L.Brightness     = 2.5
    L.ClockTime      = 8
    L.FogColor       = Color3.fromRGB(180, 210, 240)
    L.FogEnd         = 900
    L.FogStart       = 200
    L.GlobalShadows  = true
    L.Ambient        = Color3.fromRGB(130, 145, 165)
    L.OutdoorAmbient = Color3.fromRGB(140, 160, 185)
    -- Add sky effects
    local sky = Instance.new("Sky")
    currentPeriod = "Day"
end

advanceDayNight = function()
    -- Advances game clock over real time; 1 full day = 12 real minutes
    task.spawn(function()
        while gameStarted do
            task.wait(4) -- 4 real seconds per in-game hour
            clockTime = clockTime + 1
            if clockTime >= 24 then clockTime = 0 end
            local c = clockTime
            if c >= 6 and c <= 8 then
                applyLightingPreset("Sunrise")
            elseif c > 8 and c <= 17 then
                applyLightingPreset("Day")
            elseif c > 17 and c <= 18.5 then
                applyLightingPreset("GoldenHour")
            elseif c > 18.5 and c <= 20 then
                applyLightingPreset("Sunset")
            elseif c > 20 and c <= 23 then
                applyLightingPreset("Twilight")
            else
                applyLightingPreset("Night")
            end
            if timeLabel then
                local h = math.floor(clockTime)
                local m = math.floor((clockTime - h) * 60)
                local period = (h >= 6 and h < 18) and "Day" or "Night"
                timeLabel.Text = string.format("%02d:%02d  %s", h, m, period)
            end
        end
    end)
end

-- =================================================================
-- HUD
-- =================================================================
createHUD = function()
    if player.PlayerGui:FindFirstChild("RuinsHUD") then
        player.PlayerGui.RuinsHUD:Destroy()
    end
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RuinsHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player.PlayerGui

    -- Door bar
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(0, 220, 0, 48)
    topBar.Position = UDim2.new(0.5, -110, 0, 12)
    topBar.BackgroundColor3 = Color3.fromRGB(28, 22, 14)
    topBar.BackgroundTransparency = 0.3
    topBar.BorderSizePixel = 0
    topBar.Parent = screenGui
    local tbC = Instance.new("UICorner"); tbC.CornerRadius = UDim.new(0, 10); tbC.Parent = topBar
    local tbS = Instance.new("UIStroke"); tbS.Color = Color3.fromRGB(120, 100, 60); tbS.Thickness = 1.5; tbS.Parent = topBar

    doorLabel = Instance.new("TextLabel")
    doorLabel.Size = UDim2.new(1, 0, 1, 0)
    doorLabel.BackgroundTransparency = 1
    doorLabel.Text = "Ruins Door: " .. tostring(RUINS_START)
    doorLabel.TextColor3 = Color3.fromRGB(240, 220, 160)
    doorLabel.TextScaled = true
    doorLabel.Font = Enum.Font.GothamBold
    doorLabel.Parent = topBar

    -- Coin bar
    local coinBar = Instance.new("Frame")
    coinBar.Size = UDim2.new(0, 150, 0, 42)
    coinBar.Position = UDim2.new(0, 14, 0, 12)
    coinBar.BackgroundColor3 = Color3.fromRGB(28, 22, 14)
    coinBar.BackgroundTransparency = 0.3
    coinBar.BorderSizePixel = 0
    coinBar.Parent = screenGui
    local cbC = Instance.new("UICorner"); cbC.CornerRadius = UDim.new(0, 10); cbC.Parent = coinBar
    local cbS = Instance.new("UIStroke"); cbS.Color = Color3.fromRGB(120, 100, 60); cbS.Thickness = 1.5; cbS.Parent = coinBar

    local coinDot = Instance.new("Frame")
    coinDot.Size = UDim2.new(0, 20, 0, 20)
    coinDot.Position = UDim2.new(0, 8, 0.5, -10)
    coinDot.BackgroundColor3 = Color3.fromRGB(255, 210, 0)
    coinDot.BorderSizePixel = 0; coinDot.ZIndex = 2; coinDot.Parent = coinBar
    local cdC = Instance.new("UICorner"); cdC.CornerRadius = UDim.new(1, 0); cdC.Parent = coinDot

    coinLabel = Instance.new("TextLabel")
    coinLabel.Size = UDim2.new(1, -36, 1, 0)
    coinLabel.Position = UDim2.new(0, 34, 0, 0)
    coinLabel.BackgroundTransparency = 1
    coinLabel.Text = "0 Coins"
    coinLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
    coinLabel.TextScaled = true
    coinLabel.Font = Enum.Font.GothamBold
    coinLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinLabel.Parent = coinBar

    -- Time label (top right)
    local timeBar = Instance.new("Frame")
    timeBar.Size = UDim2.new(0, 150, 0, 38)
    timeBar.Position = UDim2.new(1, -164, 0, 12)
    timeBar.BackgroundColor3 = Color3.fromRGB(28, 22, 14)
    timeBar.BackgroundTransparency = 0.3
    timeBar.BorderSizePixel = 0
    timeBar.Parent = screenGui
    local tmC = Instance.new("UICorner"); tmC.CornerRadius = UDim.new(0, 10); tmC.Parent = timeBar

    timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, 0, 1, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "08:00  Day"
    timeLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
    timeLabel.TextScaled = true
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.Parent = timeBar

    -- Warning
    warningFrame = Instance.new("Frame")
    warningFrame.Name = "WarningFrame"
    warningFrame.Size = UDim2.new(1, 0, 0, 70)
    warningFrame.Position = UDim2.new(0, 0, 0.13, 0)
    warningFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 5)
    warningFrame.BackgroundTransparency = 0.2
    warningFrame.BorderSizePixel = 0
    warningFrame.Visible = false
    warningFrame.Parent = screenGui

    warningLabel = Instance.new("TextLabel")
    warningLabel.Size = UDim2.new(1, -24, 1, 0)
    warningLabel.Position = UDim2.new(0, 12, 0, 0)
    warningLabel.BackgroundTransparency = 1
    warningLabel.Text = ""
    warningLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
    warningLabel.TextScaled = true
    warningLabel.Font = Enum.Font.GothamBold
    warningLabel.TextWrapped = true
    warningLabel.Parent = warningFrame

    -- Hide prompt
    hidePrompt = Instance.new("Frame")
    hidePrompt.Name = "HidePrompt"
    hidePrompt.Size = UDim2.new(0, 260, 0, 62)
    hidePrompt.Position = UDim2.new(0.5, -130, 0.82, 0)
    hidePrompt.BackgroundColor3 = Color3.fromRGB(28, 22, 14)
    hidePrompt.BackgroundTransparency = 0.28
    hidePrompt.BorderSizePixel = 0
    hidePrompt.Visible = false
    hidePrompt.Parent = screenGui
    local hpC = Instance.new("UICorner"); hpC.CornerRadius = UDim.new(0, 12); hpC.Parent = hidePrompt
    local hpS = Instance.new("UIStroke"); hpS.Color = Color3.fromRGB(120, 100, 60); hpS.Thickness = 1.5; hpS.Parent = hidePrompt

    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(1, 0, 1, 0)
    hideBtn.BackgroundTransparency = 1
    hideBtn.TextColor3 = Color3.fromRGB(255, 240, 80)
    hideBtn.TextScaled = true
    hideBtn.Font = Enum.Font.GothamBold
    hideBtn.Text = "[HIDE IN RUINS GAP]"
    hideBtn.Parent = hidePrompt
    hideBtnLabel = hideBtn
    hideBtn.MouseButton1Click:Connect(function()
        if not isHiding then hideInGap() else exitGap() end
    end)

    -- Stem Eye UI
    stemEyeContainer = Instance.new("Frame")
    stemEyeContainer.Name = "StemEyeContainer"
    stemEyeContainer.Size = UDim2.new(0, 240, 0, 120)
    stemEyeContainer.Position = UDim2.new(0.5, -120, 0.16, 0)
    stemEyeContainer.BackgroundTransparency = 1
    stemEyeContainer.Visible = false
    stemEyeContainer.ZIndex = 10
    stemEyeContainer.Parent = screenGui

    stemEyeOuter = Instance.new("Frame")
    stemEyeOuter.Size = UDim2.new(1, 0, 1, 0)
    stemEyeOuter.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    stemEyeOuter.BorderSizePixel = 0
    stemEyeOuter.ClipsDescendants = true
    stemEyeOuter.ZIndex = 10
    stemEyeOuter.Parent = stemEyeContainer
    local outerC = Instance.new("UICorner"); outerC.CornerRadius = UDim.new(1, 0); outerC.Parent = stemEyeOuter

    stemEyeStroke = Instance.new("UIStroke")
    stemEyeStroke.Color = Color3.fromRGB(0, 255, 60)
    stemEyeStroke.Thickness = 5
    stemEyeStroke.Parent = stemEyeOuter

    local iris = Instance.new("Frame"); iris.Name = "Iris"
    iris.Size = UDim2.new(0, 90, 0, 90); iris.Position = UDim2.new(0.5, -45, 0.5, -45)
    iris.BackgroundColor3 = Color3.fromRGB(0, 185, 0); iris.BorderSizePixel = 0; iris.ZIndex = 11; iris.Parent = stemEyeOuter
    local iC = Instance.new("UICorner"); iC.CornerRadius = UDim.new(1, 0); iC.Parent = iris
    stemIris = iris

    local irisRing = Instance.new("Frame"); irisRing.Name = "IrisRing"
    irisRing.Size = UDim2.new(0, 72, 0, 72); irisRing.Position = UDim2.new(0.5, -36, 0.5, -36)
    irisRing.BackgroundColor3 = Color3.fromRGB(0, 225, 0); irisRing.BorderSizePixel = 0; irisRing.ZIndex = 12; irisRing.Parent = iris
    local irC = Instance.new("UICorner"); irC.CornerRadius = UDim.new(1, 0); irC.Parent = irisRing

    stemPupil = Instance.new("Frame"); stemPupil.Name = "Pupil"
    stemPupil.Size = UDim2.new(0, 38, 0, 38); stemPupil.Position = UDim2.new(0.5, -19, 0.5, -19)
    stemPupil.BackgroundColor3 = Color3.fromRGB(0, 0, 0); stemPupil.BorderSizePixel = 0; stemPupil.ZIndex = 13; stemPupil.Parent = irisRing
    local pC = Instance.new("UICorner"); pC.CornerRadius = UDim.new(1, 0); pC.Parent = stemPupil

    local hl = Instance.new("Frame"); hl.Size = UDim2.new(0, 10, 0, 10); hl.Position = UDim2.new(0.58, 0, 0.08, 0)
    hl.BackgroundColor3 = Color3.fromRGB(255, 255, 255); hl.BorderSizePixel = 0; hl.ZIndex = 14; hl.Parent = stemPupil
    local hlC = Instance.new("UICorner"); hlC.CornerRadius = UDim.new(1, 0); hlC.Parent = hl

    stemTopLid = Instance.new("Frame"); stemTopLid.Name = "TopLid"
    stemTopLid.Size = UDim2.new(1, 0, 0.5, 2); stemTopLid.Position = UDim2.new(0, 0, 0, 0)
    stemTopLid.BackgroundColor3 = Color3.fromRGB(10, 10, 20); stemTopLid.BorderSizePixel = 0; stemTopLid.ZIndex = 15; stemTopLid.Parent = stemEyeOuter

    stemBottomLid = Instance.new("Frame"); stemBottomLid.Name = "BottomLid"
    stemBottomLid.Size = UDim2.new(1, 0, 0.5, 2); stemBottomLid.Position = UDim2.new(0, 0, 0.5, -2)
    stemBottomLid.BackgroundColor3 = Color3.fromRGB(10, 10, 20); stemBottomLid.BorderSizePixel = 0; stemBottomLid.ZIndex = 15; stemBottomLid.Parent = stemEyeOuter

    stemSnd = Instance.new("Sound"); stemSnd.Name = "StemSound"; stemSnd.Parent = screenGui
end

-- =================================================================
-- PART HELPERS
-- =================================================================
makePart = function(size, cf, color, transparency, parent, material)
    local p = Instance.new("Part")
    p.Size = size; p.CFrame = cf
    p.Color = color or Color3.fromRGB(150, 140, 120)
    p.Transparency = transparency or 0
    p.Anchored = true; p.CanCollide = true; p.CastShadow = false
    p.Material = material or Enum.Material.SmoothPlastic
    p.Parent = parent or workspace
    return p
end

makeLight = function(parent, brightness, range, color)
    local l = Instance.new("PointLight")
    l.Brightness = brightness or 1.5; l.Range = range or 22
    l.Color = color or Color3.fromRGB(255, 220, 150)
    l.Parent = parent; return l
end

giveTool = function(plr, toolName, color, size)
    local tool = Instance.new("Tool"); tool.Name = toolName
    local handle = Instance.new("Part"); handle.Name = "Handle"
    handle.Size = size or Vector3.new(0.8, 0.5, 0.5)
    handle.Color = color or Color3.fromRGB(180, 180, 180)
    handle.Material = Enum.Material.Metal; handle.Parent = tool
    tool.Parent = plr.Backpack; return tool
end

-- =================================================================
-- RUINS DECORATIONS  (5 types, mossy stone aesthetic)
-- =================================================================
local STONE   = Color3.fromRGB(130, 125, 115)
local MOSS_C  = Color3.fromRGB(55, 100, 45)
local VINE_C  = Color3.fromRGB(38, 80, 30)

makeRuinsPillar = function(folder, pos)
    -- Intact mossy pillar: cylinder with moss overlay
    local pillar = makePart(Vector3.new(2.5, 12, 2.5), CFrame.new(pos + Vector3.new(0, 6, 0)), STONE, 0, folder, Enum.Material.Cobblestone)
    pillar.Name = "RuinsPillar"; pillar.Shape = Enum.PartType.Cylinder
    -- Moss patches (small flat parts clinging to surface)
    for i = 1, 3 do
        local mossPatch = makePart(
            Vector3.new(2.6, 0.3, 1.2),
            CFrame.new(pos + Vector3.new(0, 2 + i * 3, 0)) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0),
            MOSS_C, 0, folder, Enum.Material.Grass
        )
        mossPatch.Name = "MossPatch"; mossPatch.CanCollide = false
    end
    -- Capital stone on top
    makePart(Vector3.new(3.5, 1, 3.5), CFrame.new(pos + Vector3.new(0, 12.5, 0)), STONE, 0, folder, Enum.Material.Cobblestone).Name = "PillarCapital"
end

makeDestroyedPillar = function(folder, pos)
    -- Broken half-pillar with rubble
    local h = math.random(4, 7)
    local pillar = makePart(Vector3.new(2.5, h, 2.5), CFrame.new(pos + Vector3.new(0, h * 0.5, 0)), STONE, 0, folder, Enum.Material.Cobblestone)
    pillar.Name = "BrokenPillar"; pillar.Shape = Enum.PartType.Cylinder
    -- Jagged broken top
    for i = 1, 3 do
        local shard = makePart(
            Vector3.new(math.random(8, 14) * 0.1, math.random(8, 18) * 0.1, math.random(8, 14) * 0.1),
            CFrame.new(pos + Vector3.new(math.random(-12, 12) * 0.1, h + 0.3, math.random(-12, 12) * 0.1)) * CFrame.Angles(math.rad(math.random(-30, 30)), math.rad(math.random(0, 360)), math.rad(math.random(-30, 30))),
            STONE, 0, folder, Enum.Material.Cobblestone
        )
        shard.Name = "PillarShard"; shard.CanCollide = false
    end
    -- Rubble at base
    for i = 1, 5 do
        local chunk = makePart(
            Vector3.new(math.random(5, 15) * 0.1, math.random(3, 8) * 0.1, math.random(5, 12) * 0.1),
            CFrame.new(pos + Vector3.new(math.random(-20, 20) * 0.1, 0.3, math.random(-20, 20) * 0.1)) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0),
            STONE, 0, folder, Enum.Material.Cobblestone
        )
        chunk.Name = "Rubble"; chunk.CanCollide = false
    end
    -- Moss
    local moss = makePart(Vector3.new(2.6, 0.25, 2.6), CFrame.new(pos + Vector3.new(0, h + 0.1, 0)), MOSS_C, 0, folder, Enum.Material.Grass)
    moss.Name = "TopMoss"; moss.CanCollide = false
end

makeRuinsArch = function(folder, pos, rotY)
    local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY or 0), 0)
    local archColor = Color3.fromRGB(120, 115, 105)
    -- Left post
    makePart(Vector3.new(2, 10, 2), cf * CFrame.new(-4, 5, 0), archColor, 0, folder, Enum.Material.Cobblestone).Name = "ArchPostL"
    -- Right post
    makePart(Vector3.new(2, 10, 2), cf * CFrame.new(4, 5, 0), archColor, 0, folder, Enum.Material.Cobblestone).Name = "ArchPostR"
    -- Keystone / lintel
    makePart(Vector3.new(10, 2, 2), cf * CFrame.new(0, 10.5, 0), archColor, 0, folder, Enum.Material.Cobblestone).Name = "ArchLintel"
    -- Vines hanging down
    for vi = 1, 4 do
        local vLen = math.random(20, 50) * 0.1
        local vine = makePart(
            Vector3.new(0.25, vLen, 0.25),
            cf * CFrame.new(math.random(-40, 40) * 0.1, 10.5 - vLen * 0.5, math.random(-5, 5) * 0.1),
            VINE_C, 0.15, folder, Enum.Material.Grass
        )
        vine.Name = "Vine"; vine.CanCollide = false
    end
    -- Moss on lintel
    local mossTop = makePart(Vector3.new(10, 0.3, 2.2), cf * CFrame.new(0, 11.6, 0), MOSS_C, 0, folder, Enum.Material.Grass)
    mossTop.Name = "ArchMoss"; mossTop.CanCollide = false
end

makeCrumbledWall = function(folder, pos, rotY)
    local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY or 0), 0)
    local wallLen = math.random(6, 10)
    -- Main wall section (low, crumbled)
    local wall = makePart(Vector3.new(wallLen, math.random(3, 6), 1), cf * CFrame.new(0, 2, 0), STONE, 0, folder, Enum.Material.Cobblestone)
    wall.Name = "CrumbledWall"
    -- Uneven top rubble
    for i = 1, math.random(3, 5) do
        local block = makePart(
            Vector3.new(math.random(8, 18) * 0.1, math.random(4, 10) * 0.1, math.random(8, 16) * 0.1),
            cf * CFrame.new(math.random(-wallLen*4, wallLen*4) * 0.1, math.random(2, 4), math.random(-5, 5) * 0.1) * CFrame.Angles(0, math.rad(math.random(0, 360)), math.rad(math.random(-15, 15))),
            STONE, 0, folder, Enum.Material.Cobblestone
        )
        block.Name = "WallRubble"; block.CanCollide = false
    end
    -- Moss covering
    local mossC = makePart(Vector3.new(wallLen, 0.2, 1.2), cf * CFrame.new(0, 3.6, 0), MOSS_C, 0, folder, Enum.Material.Grass)
    mossC.Name = "WallMoss"; mossC.CanCollide = false
end

makeAncientAltar = function(folder, pos)
    -- Central pedestal
    local base = makePart(Vector3.new(4, 0.8, 4), CFrame.new(pos + Vector3.new(0, 0.4, 0)), STONE, 0, folder, Enum.Material.Cobblestone)
    base.Name = "AltarBase"
    local middle = makePart(Vector3.new(3, 2.5, 3), CFrame.new(pos + Vector3.new(0, 2.05, 0)), STONE, 0, folder, Enum.Material.Cobblestone)
    middle.Name = "AltarMiddle"
    local top = makePart(Vector3.new(3.5, 0.6, 3.5), CFrame.new(pos + Vector3.new(0, 3.6, 0)), Color3.fromRGB(110, 105, 95), 0, folder, Enum.Material.Cobblestone)
    top.Name = "AltarTop"
    -- Carved rune details (small notched parts)
    for i = 0, 3 do
        local rune = makePart(Vector3.new(0.2, 0.25, 1.5), CFrame.new(pos + Vector3.new(0, 2 + i * 0.5, 0)) * CFrame.Angles(0, math.rad(i * 90), 0), Color3.fromRGB(90, 85, 80), 0, folder)
        rune.Name = "AltarRune"; rune.CanCollide = false
    end
    -- Moss on top
    local moss = makePart(Vector3.new(3.2, 0.15, 3.2), CFrame.new(pos + Vector3.new(0, 3.95, 0)), MOSS_C, 0.2, folder, Enum.Material.Grass)
    moss.Name = "AltarMoss"; moss.CanCollide = false
end

makeRuinsDecor = function(folder, pos)
    local t = math.random(1, 5)
    if t == 1 then makeRuinsPillar(folder, pos)
    elseif t == 2 then makeDestroyedPillar(folder, pos)
    elseif t == 3 then makeRuinsArch(folder, pos, math.random(0, 3) * 90)
    elseif t == 4 then makeCrumbledWall(folder, pos, math.random(0, 1) * 90)
    else makeAncientAltar(folder, pos) end
end

-- =================================================================
-- RUINS CHEST  (stone chest, 1-3 searches, varies by probability)
-- =================================================================
makeRuinsChest = function(folder, pos, isLocked)
    local chestColor = Color3.fromRGB(115, 108, 95)
    -- Chest body
    local body = makePart(Vector3.new(3, 2, 2.5), CFrame.new(pos + Vector3.new(0, 1, 0)), chestColor, 0, folder, Enum.Material.Cobblestone)
    body.Name = "RuinsChest"
    -- Lid
    local lid = makePart(Vector3.new(3, 0.6, 2.5), CFrame.new(pos + Vector3.new(0, 2.3, 0)), Color3.fromRGB(100, 94, 82), 0, folder, Enum.Material.Cobblestone)
    lid.Name = "ChestLid"
    -- Metal bands
    for bi = 0, 1 do
        local band = makePart(Vector3.new(3.1, 0.2, 2.6), CFrame.new(pos + Vector3.new(0, 0.8 + bi * 1.2, 0)), Color3.fromRGB(70, 65, 55), 0, folder, Enum.Material.Metal)
        band.Name = "ChestBand"; band.CanCollide = false
    end
    -- Lock clasp
    local clasp = makePart(Vector3.new(0.5, 0.5, 0.3), CFrame.new(pos + Vector3.new(0, 2.0, -1.3)), Color3.fromRGB(160, 140, 80), 0, folder, Enum.Material.Metal)
    clasp.Name = "ChestClasp"; clasp.CanCollide = false
    -- Moss on chest
    local moss = makePart(Vector3.new(3.1, 0.15, 2.6), CFrame.new(pos + Vector3.new(0, 2.65, 0)), MOSS_C, 0, folder, Enum.Material.Grass)
    moss.Name = "ChestMoss"; moss.CanCollide = false

    -- Determine max uses: 75% get 1, 30% get 2, 10% get 3
    local maxUses = 1
    if math.random(1, 100) <= 30 then maxUses = 2 end
    if math.random(1, 100) <= 10 then maxUses = 3 end
    local usesLeft = maxUses

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Search Chest"
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 6
    prompt.Parent = body

    prompt.Triggered:Connect(function(plr)
        if usesLeft <= 0 then showWarning("Chest is empty.", 1.5); return end
        usesLeft = usesLeft - 1

        local r = math.random(1, 100); local loot
        -- UPDATED LOOT TABLE WITH NEW ITEMS
        if r <= 5 then loot = "PureGem"      -- 5%
        elseif r <= 20 then loot = "Lantern" -- 15%
        elseif r <= 32 then loot = "Gem"     -- \~12%
        elseif r <= 48 then loot = "Ecstasy" -- \~16%
        elseif r <= 78 then loot = "Coin"    -- \~30%
        else loot = "Nothing" end

        if usesLeft == 0 then
            prompt:Destroy()
            body.Color = Color3.fromRGB(70, 66, 58)
        end

        local leftStr = " (" .. tostring(usesLeft) .. " left)"

        if loot == "Coin" then
            local amt = math.random(2, 8); coins = coins + amt
            if coinLabel then coinLabel.Text = tostring(coins) .. " Coins" end
            showWarning("Chest: Found " .. tostring(amt) .. " Ancient Coins!" .. leftStr, 2.5); return
        end
        if loot == "Nothing" then showWarning("Chest: Dust and cobwebs." .. leftStr, 2); return end

        if loot == "Gem" then
            if #inventory >= MAX_ITEMS then showWarning("Inventory full!", 2); return end
            showWarning("Chest: Found a Gem!" .. leftStr, 2.5)
            table.insert(inventory, "Gem")
            local t = giveTool(plr, "Gem", Color3.fromRGB(60, 200, 200), Vector3.new(0.7, 0.7, 0.7))
            t.Handle.Material = Enum.Material.Neon
            return
        end

        if loot == "Ecstasy" then
            if #inventory >= MAX_ITEMS then showWarning("Inventory full!", 2); return end
            table.insert(inventory, "Ecstasy")
            local t = giveTool(plr, "Ecstasy", Color3.fromRGB(200, 50, 200), Vector3.new(0.5, 0.5, 0.5))
            t.Handle.Material = Enum.Material.Neon
            t.Activated:Connect(function()
                t:Destroy()
                for idx, v in ipairs(inventory) do if v == "Ecstasy" then table.remove(inventory, idx); break end end
                ecstasyActive = true; ecstasyEndTime = tick() + 180
                if humanoid then humanoid.WalkSpeed = 22 end
                local ccc = game.Lighting:FindFirstChild("EcstasyCC") or Instance.new("ColorCorrectionEffect", game.Lighting)
                ccc.Name = "EcstasyCC"; ccc.Saturation = 1.5
                showWarning("Ecstasy active! Speed boost 3 minutes.", 3)
            end)
            showWarning("Chest: Ecstasy!" .. leftStr, 2)
            return
        end

        -- NEW: Lantern
        if loot == "Lantern" then
            if #inventory >= MAX_ITEMS then showWarning("Inventory full!", 2); return end
            table.insert(inventory, "Lantern")
            local t = giveTool(plr, "Lantern", Color3.fromRGB(220, 180, 80), Vector3.new(0.7, 1.1, 0.7))
            local handle = t.Handle
            handle.Material = Enum.Material.Metal
            -- Lantern light (yellow warm)
            local light = Instance.new("PointLight")
            light.Name = "LanternLight"
            light.Brightness = 2.5
            light.Range = 35
            light.Color = Color3.fromRGB(255, 220, 150)
            light.Enabled = true
            light.Parent = handle
            -- Flame particles for lantern look
            local flame = Instance.new("ParticleEmitter", handle)
            flame.Texture = "rbxassetid://241650899"
            flame.Color = ColorSequence.new(Color3.fromRGB(255, 180, 60))
            flame.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)})
            flame.Rate = 8
            flame.Speed = NumberRange.new(1, 2)
            flame.Lifetime = NumberRange.new(0.6, 1.2)
            flame.Transparency = NumberSequence.new(0.4, 1)
            flame.Parent = handle
            showWarning("Chest: Lantern!" .. leftStr, 2)
            return
        end

        -- NEW: Pure Gem
        if loot == "PureGem" then
            if #inventory >= MAX_ITEMS then showWarning("Inventory full!", 2); return end
            table.insert(inventory, "PureGem")
            local t = giveTool(plr, "PureGem", Color3.fromRGB(180, 255, 120), Vector3.new(0.6, 0.6, 0.6))
            local handle = t.Handle
            handle.Material = Enum.Material.Neon
            -- Gentle glow
            local glight = Instance.new("PointLight")
            glight.Brightness = 1.2
            glight.Range = 14
            glight.Color = Color3.fromRGB(180, 255, 120)
            glight.Parent = handle
            showWarning("Chest: Pure Gem!" .. leftStr, 2.5)
            return
        end
    end)
    return body
end

-- =================================================================
-- RUINS GAP  (hiding spot - crumbled wall crevice)
-- =================================================================
makeRuinsGap = function(folder, pos, rotY)
    local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY or 0), 0)
    local gapColor = Color3.fromRGB(80, 76, 70)

    -- Back slab
    local backWall = makePart(Vector3.new(6, 5, 0.8), cf * CFrame.new(0, 2.5, 1.5), gapColor, 0, folder, Enum.Material.Cobblestone)
    backWall.Name = "GapBack"
    -- Left slab
    local leftW = makePart(Vector3.new(0.8, 5, 3), cf * CFrame.new(-3, 2.5, 0), gapColor, 0, folder, Enum.Material.Cobblestone)
    leftW.Name = "GapLeft"
    -- Right slab
    local rightW = makePart(Vector3.new(0.8, 5, 3), cf * CFrame.new(3, 2.5, 0), gapColor, 0, folder, Enum.Material.Cobblestone)
    rightW.Name = "GapRight"
    -- Rubble scattered at entrance
    for i = 1, 4 do
        local r = makePart(
            Vector3.new(math.random(4,10)*0.1, math.random(3,7)*0.1, math.random(4,10)*0.1),
            cf * CFrame.new(math.random(-22,22)*0.1, 0.15, math.random(-8,8)*0.1) * CFrame.Angles(0, math.rad(math.random(0,360)), 0),
            STONE, 0, folder, Enum.Material.Cobblestone
        )
        r.Name = "GapRubble"; r.CanCollide = false
    end
    -- Moss inside the gap
    local innerMoss = makePart(Vector3.new(5.2, 0.2, 2.8), cf * CFrame.new(0, 0.15, 0.5), MOSS_C, 0, folder, Enum.Material.Grass)
    innerMoss.Name = "GapMoss"; innerMoss.CanCollide = false

    -- IsLocker on back wall for hide detection
    backWall:SetAttribute("IsLocker", true)
    return backWall
end

-- =================================================================
-- TREE BARRIER  (spawned when Plantera is coming)
-- =================================================================
makeTreeBarrier = function(folder, O, zPos)
    local treeColor = Color3.fromRGB(60, 80, 40)
    local leafColor = Color3.fromRGB(40, 100, 30)
    local tf = Instance.new("Folder"); tf.Name = "TreeBarrier"; tf.Parent = folder
    for i = -1, 1 do
        local tx = i * 12
        -- Trunk
        local trunk = makePart(Vector3.new(2, 14, 2), CFrame.new(O.X + tx, RUINS_FLOOR_Y + 7, zPos), treeColor, 0, tf, Enum.Material.Wood)
        trunk.Name = "TreeTrunk"
        -- Foliage
        local leaf = makePart(Vector3.new(9, 7, 9), CFrame.new(O.X + tx, RUINS_FLOOR_Y + 16, zPos), leafColor, 0.1, tf, Enum.Material.Grass)
        leaf.Name = "TreeLeaf"; leaf.Shape = Enum.PartType.Ball
        -- Vine cascade
        for vi = 1, 5 do
            local vLen = math.random(30, 70) * 0.1
            local vine = makePart(
                Vector3.new(0.3, vLen, 0.3),
                CFrame.new(O.X + tx + math.random(-30, 30)*0.1, RUINS_FLOOR_Y + 14 - vLen * 0.5, zPos),
                VINE_C, 0.1, tf, Enum.Material.Grass
            )
            vine.Name = "Vine"; vine.CanCollide = false
        end
    end
    -- Blocking fog (dense mossy wall center)
    local block = makePart(Vector3.new(50, 14, 2), CFrame.new(O.X, RUINS_FLOOR_Y + 7, zPos), Color3.fromRGB(40, 60, 25), 0.55, tf, Enum.Material.Grass)
    block.Name = "PlantBarrier"; block.CanCollide = true
    return tf
end

-- =================================================================
-- BOAT  (used in Gem room)
-- =================================================================
makeBoat = function(pos)
    local ef = Instance.new("Folder"); ef.Name = "Boat"; ef.Parent = workspace
    local hull = makePart(Vector3.new(8, 2, 14), CFrame.new(pos + Vector3.new(0, SEA_Y + 1, 0)), Color3.fromRGB(100, 72, 38), 0, ef, Enum.Material.Wood)
    hull.Name = "BoatHull"; hull.Anchored = false
    -- Hull planks
    for pi = -1, 1 do
        local pl = makePart(Vector3.new(8.2, 0.25, 14.2), CFrame.new(pos + Vector3.new(0, SEA_Y + 1.2 + pi * 0.3, 0)), Color3.fromRGB(80, 55, 25), 0, ef, Enum.Material.Wood)
        pl.Name = "BoatPlank"; pl.Anchored = false
        local w = Instance.new("Weld"); w.Part0 = hull; w.Part1 = pl; w.C0 = CFrame.new(0, pi * 0.3, 0); w.Parent = hull
    end
    -- Mast suggestion (short post)
    local mast = makePart(Vector3.new(0.5, 6, 0.5), CFrame.new(pos + Vector3.new(0, SEA_Y + 4.5, 0)), Color3.fromRGB(80, 55, 25), 0, ef, Enum.Material.Wood)
    mast.Name = "BoatMast"; mast.Anchored = false
    local mw = Instance.new("Weld"); mw.Part0 = hull; mw.Part1 = mast; mw.C0 = CFrame.new(0, 3, 0); mw.Parent = hull

    -- Physics for floating
    local bv = Instance.new("BodyVelocity"); bv.Velocity = Vector3.new(0, 0, 0); bv.MaxForce = Vector3.new(1e4, 1e4, 1e4); bv.Parent = hull
    local bg = Instance.new("BodyGyro"); bg.MaxTorque = Vector3.new(1e5, 0, 1e5); bg.CFrame = CFrame.new(hull.Position); bg.Parent = hull

    -- Board prompt
    local bp = Instance.new("ProximityPrompt"); bp.ActionText = "Board Boat"; bp.RequiresLineOfSight = false; bp.MaxActivationDistance = 8; bp.Parent = hull
    bp.Triggered:Connect(function()
        if not character or onBoat then return end
        onBoat = true; playerBoat = hull; boatVel = bv; boatGyro = bg
        if rootPart then rootPart.CFrame = CFrame.new(hull.Position + Vector3.new(0, 2.5, 0)) end
        local bpLeave = Instance.new("ProximityPrompt"); bpLeave.ActionText = "Disembark"; bpLeave.RequiresLineOfSight = false; bpLeave.MaxActivationDistance = 4; bpLeave.Parent = hull
        bpLeave.Triggered:Connect(function()
            onBoat = false; playerBoat = nil; boatVel = nil; boatGyro = nil; bpLeave:Destroy()
            bv.Velocity = Vector3.new(0, 0, 0)
        end)
    end)
    return hull, bv, bg, ef
end

-- =================================================================
-- GEM  (spawns in sea near gem room)
-- =================================================================
makeGem = function(folder, roomCenterX, roomCenterZ, gemDoorNum)
    local angle = math.random(0, 360)
    local dist  = GEM_MIN_DIST + math.random() * (GEM_MAX_DIST - GEM_MIN_DIST)
    local gx    = roomCenterX + math.cos(math.rad(angle)) * dist
    local gz    = roomCenterZ + math.sin(math.rad(angle)) * dist
    local gemPart = makePart(
        Vector3.new(1.5, 1.5, 1.5),
        CFrame.new(gx, SEA_Y + 1.5, gz),
        Color3.fromRGB(50, 220, 220), 0, folder, Enum.Material.Neon
    )
    gemPart.Name = "GemInSea"
    gemPart.Shape = Enum.PartType.Ball
    makeLight(gemPart, 3, 18, Color3.fromRGB(80, 255, 255))
    -- Glow particles
    local pe = Instance.new("ParticleEmitter", gemPart)
    pe.Color = ColorSequence.new(Color3.fromRGB(50, 220, 220))
    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0)})
    pe.Rate = 15; pe.Speed = NumberRange.new(1, 3)

    local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Take Gem"; prompt.RequiresLineOfSight = false; prompt.MaxActivationDistance = 8; prompt.Parent = gemPart
    prompt.Triggered:Connect(function(plr)
        if #inventory >= MAX_ITEMS then showWarning("Inventory full!", 2); return end
        if gemRoomStates[gemDoorNum] then gemRoomStates[gemDoorNum].gemTaken = true end
        table.insert(inventory, "Gem")
        local t = giveTool(plr, "Gem", Color3.fromRGB(60, 200, 200), Vector3.new(0.7, 0.7, 0.7))
        t.Handle.Material = Enum.Material.Neon
        gemPart:Destroy()
        showWarning("Got the Gem! Now insert it into the panel.", 3)
    end)
    return gemPart
end

-- =================================================================
-- ROOM GENERATION  (3 types dispatched based on chance)
-- =================================================================
generateNormalRoom = function(folder, O, doorNum)
    local floorColor = Color3.fromRGB(145, 138, 118)
    local edgeColor  = Color3.fromRGB(120, 114, 96)

    -- 50x50 bridge floor (no side walls)
    local floor = makePart(Vector3.new(RUINS_W, 1, RUINS_D), CFrame.new(O + Vector3.new(0, RUINS_FLOOR_Y - 0.5, 0)), floorColor, 0, folder, Enum.Material.Cobblestone)
    floor.Name = "BridgeFloor"
    -- Textured stone edge lines
    for ei = -1, 1, 2 do
        local edge = makePart(Vector3.new(1, 1.5, RUINS_D), CFrame.new(O + Vector3.new(ei * RUINS_W * 0.5, RUINS_FLOOR_Y, 0)), edgeColor, 0, folder, Enum.Material.Cobblestone)
        edge.Name = "BridgeEdge"
    end

    -- 2-5 Ruins decorations scattered on bridge
    local numDecor = math.random(2, 5)
    for di = 1, numDecor do
        local dx = math.random(-18, 18); local dz = math.random(-22, 22)
        makeRuinsDecor(folder, O + Vector3.new(dx, RUINS_FLOOR_Y, dz))
    end

    -- 1 Ruins Gap (random direction) - the hiding spot
    local gapRotY = math.random(0, 3) * 90
    local gapX = (math.random(1, 2) == 1 and 1 or -1) * math.random(8, 18)
    local gapZ = math.random(-18, 18)
    makeRuinsGap(folder, O + Vector3.new(gapX, RUINS_FLOOR_Y, gapZ), gapRotY)

    -- 1-3 Ruins Chests
    local numChests = math.random(1, 3)
    for ci = 1, numChests do
        local cx = math.random(-18, 18); local cz = math.random(-22, 22)
        makeRuinsChest(folder, O + Vector3.new(cx, RUINS_FLOOR_Y, cz), false)
    end
end

generateStairsRoom = function(folder, O, doorNum)
    local floorColor = Color3.fromRGB(145, 138, 118)
    local stepColor  = Color3.fromRGB(130, 124, 106)

    -- Main floor
    makePart(Vector3.new(RUINS_W, 1, RUINS_D), CFrame.new(O + Vector3.new(0, RUINS_FLOOR_Y - 0.5, 0)), floorColor, 0, folder, Enum.Material.Cobblestone).Name = "StairsFloor"

    -- Entrance stairs (rising up from -Z entry side)
    local numSteps = 6
    for si = 0, numSteps - 1 do
        local stepY  = RUINS_FLOOR_Y + si * 1.2
        local stepZ  = (RUINS_D * 0.5) - 2 - si * 2.2
        local step = makePart(Vector3.new(RUINS_W, 1.2, 2.2), CFrame.new(O + Vector3.new(0, stepY, stepZ)), stepColor, 0, folder, Enum.Material.Cobblestone)
        step.Name = "StepEntrance"
    end
    -- Elevated platform in middle
    local platH = RUINS_FLOOR_Y + numSteps * 1.2
    makePart(Vector3.new(RUINS_W, 1, RUINS_D * 0.35), CFrame.new(O + Vector3.new(0, platH - 0.5, 0)), floorColor, 0, folder, Enum.Material.Cobblestone).Name = "PlatformTop"

    -- Exit stairs (descending to exit side)
    for si = 0, numSteps - 1 do
        local stepY  = platH - si * 1.2
        local stepZ  = -(RUINS_D * 0.5 - 2 - si * 2.2)
        local step = makePart(Vector3.new(RUINS_W, 1.2, 2.2), CFrame.new(O + Vector3.new(0, stepY, stepZ)), stepColor, 0, folder, Enum.Material.Cobblestone)
        step.Name = "StepExit"
    end

    -- Edge lines
    for ei = -1, 1, 2 do
        makePart(Vector3.new(1, 1.5, RUINS_D), CFrame.new(O + Vector3.new(ei * RUINS_W * 0.5, RUINS_FLOOR_Y, 0)), Color3.fromRGB(120, 114, 96), 0, folder, Enum.Material.Cobblestone).Name = "BridgeEdge"
    end

    -- Ruins gap at entrance and exit landing
    makeRuinsGap(folder, O + Vector3.new(math.random(-15, 15), RUINS_FLOOR_Y, RUINS_D * 0.4), math.random(0, 3) * 90)
    makeRuinsGap(folder, O + Vector3.new(math.random(-15, 15), RUINS_FLOOR_Y, -RUINS_D * 0.4), math.random(0, 3) * 90)

    -- Chest at entrance and exit landings
    makeRuinsChest(folder, O + Vector3.new(math.random(-14, 14), RUINS_FLOOR_Y, RUINS_D * 0.38), false)
    makeRuinsChest(folder, O + Vector3.new(math.random(-14, 14), RUINS_FLOOR_Y, -RUINS_D * 0.38), false)

    -- Some decor on platform
    for di = 1, 2 do
        makeRuinsDecor(folder, O + Vector3.new(math.random(-14, 14), platH, math.random(-8, 8)))
    end
end

generateGemRoom = function(folder, O, doorNum)
    gemRoomStates[doorNum] = { bridgeRaised = false, gemTaken = false }

    local platformW = RUINS_W
    local platformD = 20
    local gapD = 55  -- gap the bridge spans
    local floorC = Color3.fromRGB(145, 138, 118)

    -- Entrance platform
    makePart(Vector3.new(platformW, 1, platformD), CFrame.new(O + Vector3.new(0, RUINS_FLOOR_Y - 0.5, RUINS_D * 0.5 - platformD * 0.5)), floorC, 0, folder, Enum.Material.Cobblestone).Name = "EntrancePlatform"
    -- Exit platform
    makePart(Vector3.new(platformW, 1, platformD), CFrame.new(O + Vector3.new(0, RUINS_FLOOR_Y - 0.5, -(RUINS_D * 0.5 - platformD * 0.5))), floorC, 0, folder, Enum.Material.Cobblestone).Name = "ExitPlatform"

    -- Edge railing suggestions (low stone walls on sides of platforms)
    for side = -1, 1, 2 do
        makePart(Vector3.new(1, 2.5, platformD), CFrame.new(O + Vector3.new(side * platformW * 0.5, RUINS_FLOOR_Y + 0.75, RUINS_D * 0.5 - platformD * 0.5)), STONE, 0, folder, Enum.Material.Cobblestone).Name = "PlatformEdge"
        makePart(Vector3.new(1, 2.5, platformD), CFrame.new(O + Vector3.new(side * platformW * 0.5, RUINS_FLOOR_Y + 0.75, -(RUINS_D * 0.5 - platformD * 0.5))), STONE, 0, folder, Enum.Material.Cobblestone).Name = "PlatformEdge"
    end

    -- Gem panel on entrance platform side wall
    local panelPart = makePart(Vector3.new(3, 3, 0.5), CFrame.new(O + Vector3.new(RUINS_W * 0.45, RUINS_FLOOR_Y + 1.5, RUINS_D * 0.5 - platformD + 2)), Color3.fromRGB(60, 55, 45), 0, folder, Enum.Material.Cobblestone)
    panelPart.Name = "GemPanel"
    -- Panel gem slot indicator (glowing recess)
    local slot = makePart(Vector3.new(1.2, 1.2, 0.3), CFrame.new(O + Vector3.new(RUINS_W * 0.45, RUINS_FLOOR_Y + 1.5, RUINS_D * 0.5 - platformD + 1.9)), Color3.fromRGB(20, 20, 20), 0, folder, Enum.Material.Neon)
    slot.Name = "PanelSlot"; slot.CanCollide = false
    makeLight(slot, 1, 8, Color3.fromRGB(50, 200, 200))

    -- Bridge planks (submerged - start at sea level, rise to bridge level)
    local bridgeF = Instance.new("Folder"); bridgeF.Name = "GemBridge"; bridgeF.Parent = folder
    local bridgePlanks = {}
    local gapCenter = O.Z -- center Z of the gap
    local numPlanks = 10
    for pi = 1, numPlanks do
        local pct = pi / (numPlanks + 1)
        local pz = (RUINS_D * 0.5 - platformD) - pct * gapD
        local plank = makePart(
            Vector3.new(platformW, 1, gapD / numPlanks - 0.3),
            CFrame.new(O.X, SEA_Y - 2, O.Z + pz),
            Color3.fromRGB(100, 78, 45), 0, bridgeF, Enum.Material.Wood
        )
        plank.Name = "GemBridgePlank"
        plank:SetAttribute("TargetY", RUINS_FLOOR_Y - 0.5)
        table.insert(bridgePlanks, plank)
    end

    -- Gem panel prompt
    local panelPrompt = Instance.new("ProximityPrompt"); panelPrompt.ActionText = "Insert Gem"; panelPrompt.RequiresLineOfSight = false; panelPrompt.MaxActivationDistance = 7; panelPrompt.Parent = panelPart
    panelPrompt.Triggered:Connect(function(plr)
        local char = plr.Character; if not char then return end
        local hasGem = false
        for _, v in ipairs(inventory) do if v == "Gem" then hasGem = true; break end end
        if not hasGem and not char:FindFirstChild("Gem") then
            showWarning("You need a Gem! Find it in the sea below.", 3); return
        end
        if gemRoomStates[doorNum] and gemRoomStates[doorNum].bridgeRaised then
            showWarning("Bridge already raised!", 2); return
        end
        -- Remove gem from inventory and backpack
        for i, v in ipairs(inventory) do if v == "Gem" then table.remove(inventory, i); break end end
        if char:FindFirstChild("Gem") then char.Gem:Destroy() end
        if gemRoomStates[doorNum] then gemRoomStates[doorNum].bridgeRaised = true end
        panelPrompt:Destroy()
        slot.Color = Color3.fromRGB(50, 220, 220)
        makeLight(slot, 3, 14, Color3.fromRGB(50, 220, 220))
        showWarning("Gem inserted! The bridge rises...", 3)
        -- Animate bridge rising
        for idx, plank in ipairs(bridgePlanks) do
            task.delay(idx * 0.08, function()
                if plank and plank.Parent then
                    TweenService:Create(plank, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(plank.Position.X, RUINS_FLOOR_Y - 0.5, plank.Position.Z) }):Play()
                end
            end)
        end
    end)

    -- Ruins gap on both platforms
    makeRuinsGap(folder, O + Vector3.new(math.random(-14, 14), RUINS_FLOOR_Y, RUINS_D * 0.38), 0)
    makeRuinsGap(folder, O + Vector3.new(math.random(-14, 14), RUINS_FLOOR_Y, -RUINS_D * 0.38), 0)

    -- Chest on entrance platform
    makeRuinsChest(folder, O + Vector3.new(math.random(-12, 12), RUINS_FLOOR_Y, RUINS_D * 0.3), false)

    -- Spawn boat to the side of the room
    local boatX = O.X + RUINS_W * 0.6
    local boatZ = O.Z
    makeBoat(Vector3.new(boatX, SEA_Y, boatZ))

    -- Spawn gem in sea
    local ladderPart = makePart(Vector3.new(1.5, math.abs(RUINS_FLOOR_Y - SEA_Y) + 2, 1.5), CFrame.new(O.X + RUINS_W * 0.6, (RUINS_FLOOR_Y + SEA_Y) * 0.5, O.Z + platformD * 0.5), Color3.fromRGB(80, 60, 30), 0, folder, Enum.Material.Wood)
    ladderPart.Name = "SeaLadder"
    -- Rungs on ladder
    for ri = 0, 3 do
        local rung = makePart(Vector3.new(2.5, 0.2, 0.2), CFrame.new(O.X + RUINS_W * 0.6, SEA_Y + 1.5 + ri * 1.2, O.Z + platformD * 0.5), Color3.fromRGB(70, 50, 20), 0, folder, Enum.Material.Wood)
        rung.Name = "LadderRung"
    end
    -- Climb prompt at base of ladder
    local climbPrompt = Instance.new("ProximityPrompt"); climbPrompt.ActionText = "Climb Up"; climbPrompt.RequiresLineOfSight = false; climbPrompt.MaxActivationDistance = 5; climbPrompt.Parent = ladderPart
    climbPrompt.Triggered:Connect(function()
        if character then character:PivotTo(CFrame.new(O.X + RUINS_W * 0.6, RUINS_FLOOR_Y + 3, O.Z + platformD * 0.5)) end
    end)

    makeGem(folder, O.X, O.Z, doorNum)
end

-- =================================================================
-- ROOM DISPATCH
-- =================================================================
generateRoom = function(doorNum)
    if rooms[doorNum] then return end
    local folder = Instance.new("Folder"); folder.Name = "RuinsRoom_" .. doorNum; folder.Parent = workspace

    local roomZ = getRuinsZ(doorNum)
    local O     = Vector3.new(0, 0, roomZ)

    -- Determine room type
    local rType = "normal"
    local gemRoll = math.random(1, 100)
    if gemRoll <= 20 then rType = "gem"
    elseif math.random(1, 100) <= 50 then rType = "stairs" end
    roomType[doorNum] = rType

    if rType == "gem" then
        generateGemRoom(folder, O, doorNum)
    elseif rType == "stairs" then
        generateStairsRoom(folder, O, doorNum)
    else
        generateNormalRoom(folder, O, doorNum)
    end

    -- Checkpoint sign
    if doorNum > RUINS_START and (doorNum - RUINS_START) % CHECKPOINT_EVERY == 0 then
        local cpPart = makePart(Vector3.new(10, 2.5, 0.4), CFrame.new(O + Vector3.new(0, RUINS_FLOOR_Y + 4, 0)), Color3.fromRGB(10, 80, 10), 0, folder, Enum.Material.Neon)
        cpPart.Name = "CheckpointSign"
        local cpG = Instance.new("SurfaceGui"); cpG.Face = Enum.NormalId.Front; cpG.Parent = cpPart
        local cpL = Instance.new("TextLabel"); cpL.Size = UDim2.new(1, 0, 1, 0); cpL.BackgroundTransparency = 1
        cpL.Text = "CHECKPOINT  -  Ruins Door " .. doorNum; cpL.TextColor3 = Color3.fromRGB(100, 255, 100)
        cpL.TextScaled = true; cpL.Font = Enum.Font.GothamBold; cpL.Parent = cpG
    end

    -- Door number stone marker at exit edge
    local markerPart = makePart(Vector3.new(4, 2, 0.4), CFrame.new(O + Vector3.new(0, RUINS_FLOOR_Y + 2, -RUINS_D * 0.5)), Color3.fromRGB(100, 95, 80), 0, folder, Enum.Material.Cobblestone)
    markerPart.Name = "DoorMarker"
    local mG = Instance.new("SurfaceGui"); mG.Face = Enum.NormalId.Front; mG.Parent = markerPart
    local mL = Instance.new("TextLabel"); mL.Size = UDim2.new(1, 0, 1, 0); mL.BackgroundTransparency = 1
    mL.Text = tostring(doorNum + 1); mL.TextColor3 = Color3.fromRGB(220, 200, 140); mL.TextScaled = true; mL.Font = Enum.Font.GothamBold; mL.Parent = mG

    rooms[doorNum] = folder
end

-- =================================================================
-- LOBBY  (cave exit transition area - surface ruins entry)
-- =================================================================
createLobby = function()
    local folder = Instance.new("Folder"); folder.Name = "RuinsLobby"; folder.Parent = workspace
    local stoneC = Color3.fromRGB(110, 104, 92)

    -- Underground cave exit cave box (below surface)
    makePart(Vector3.new(18, 1, 18), CFrame.new(0, CAVE_EXIT_Y - 0.5, 60), Color3.fromRGB(42, 40, 38), 0, folder, Enum.Material.Slate).Name = "CaveExitFloor"
    makePart(Vector3.new(18, 1, 18), CFrame.new(0, RUINS_FLOOR_Y + 1, 60), Color3.fromRGB(35, 33, 31), 0, folder, Enum.Material.Slate).Name = "CaveExitCeiling"
    makePart(Vector3.new(18, math.abs(CAVE_EXIT_Y) + RUINS_FLOOR_Y + 2, 1), CFrame.new(0, (CAVE_EXIT_Y + RUINS_FLOOR_Y) * 0.5, 69), Color3.fromRGB(44, 42, 40), 0, folder, Enum.Material.Cobblestone).Name = "CaveExitBack"
    for side = -1, 1, 2 do
        makePart(Vector3.new(1, math.abs(CAVE_EXIT_Y) + RUINS_FLOOR_Y + 2, 18), CFrame.new(side * 9, (CAVE_EXIT_Y + RUINS_FLOOR_Y) * 0.5, 60), Color3.fromRGB(44, 42, 40), 0, folder, Enum.Material.Cobblestone).Name = "CaveExitWall"
    end
    -- Ceiling gap (hole through which ladder goes)
    -- The ceiling has a 4x4 hole in center; we simulate with 4 side panels leaving center open
    for xi = -1, 1, 2 do
        makePart(Vector3.new(6, 1, 18), CFrame.new(xi * 6, RUINS_FLOOR_Y + 1, 60), Color3.fromRGB(35, 33, 31), 0, folder, Enum.Material.Slate).Name = "CaveCeilingSide"
    end
    for zi = -1, 1, 2 do
        makePart(Vector3.new(6, 1, 6), CFrame.new(0, RUINS_FLOOR_Y + 1, 60 + zi * 6), Color3.fromRGB(35, 33, 31), 0, folder, Enum.Material.Slate).Name = "CaveCeilingSide"
    end

    -- Ladder (tall Parts with rungs, goes from cave floor to surface)
    local ladderTotalH = math.abs(CAVE_EXIT_Y) + RUINS_FLOOR_Y
    local ladderPost = makePart(Vector3.new(0.6, ladderTotalH, 0.6), CFrame.new(0, CAVE_EXIT_Y + ladderTotalH * 0.5, 60), Color3.fromRGB(65, 48, 28), 0, folder, Enum.Material.Wood)
    ladderPost.Name = "LadderPost"
    local numRungs = math.floor(ladderTotalH / 1.4)
    for ri = 0, numRungs do
        local ry = CAVE_EXIT_Y + ri * 1.4 + 1
        local rung = makePart(Vector3.new(2.8, 0.25, 0.25), CFrame.new(0, ry, 60), Color3.fromRGB(55, 40, 20), 0, folder, Enum.Material.Wood)
        rung.Name = "Rung"
    end
    -- Climb prompt at base of ladder
    local climbBase = makePart(Vector3.new(3, 1, 3), CFrame.new(0, CAVE_EXIT_Y + 0.5, 60), Color3.fromRGB(0, 150, 60), 0.8, folder, Enum.Material.Neon)
    climbBase.Name = "LadderBase"
    local cp = Instance.new("ProximityPrompt"); cp.ActionText = "Climb to Surface"; cp.RequiresLineOfSight = false; cp.MaxActivationDistance = 6; cp.Parent = climbBase
    cp.Triggered:Connect(function()
        if character then character:PivotTo(CFrame.new(0, RUINS_FLOOR_Y + 3, 55)) end
        showWarning("You emerge into The Ruins!", 3)
        if not gameStarted then
            task.wait(0.5)
            startGame()
        end
    end)

    -- Surface ruins lobby (open air stone courtyard)
    -- Large stone courtyard floor
    makePart(Vector3.new(60, 1, 80), CFrame.new(0, RUINS_FLOOR_Y - 0.5, 30), stoneC, 0, folder, Enum.Material.Cobblestone).Name = "LobbyCourtyard"
    -- Broken walls around courtyard (partial)
    for zi = -1, 1, 2 do
        makePart(Vector3.new(60, 5, 2), CFrame.new(0, RUINS_FLOOR_Y + 2, 30 + zi * 40), Color3.fromRGB(115, 108, 95), 0, folder, Enum.Material.Cobblestone).Name = "CourtyardWall"
    end
    for xi = -1, 1, 2 do
        makePart(Vector3.new(2, 8, 80), CFrame.new(xi * 30, RUINS_FLOOR_Y + 3.5, 30), Color3.fromRGB(115, 108, 95), 0, folder, Enum.Material.Cobblestone).Name = "CourtyardWallSide"
    end
    -- Moss on floor
    makePart(Vector3.new(55, 0.2, 70), CFrame.new(0, RUINS_FLOOR_Y + 0.05, 30), MOSS_C, 0.4, folder, Enum.Material.Grass).Name = "CourtyardMoss"

    -- Decorative ruins scattered in courtyard
    for di = 1, 6 do
        local dx = math.random(-22, 22); local dz = math.random(-25, 55)
        makeRuinsDecor(folder, Vector3.new(dx, RUINS_FLOOR_Y, dz))
    end

    -- Welcome sign (stone tablet)
    local tablet = makePart(Vector3.new(20, 5, 0.6), CFrame.new(0, RUINS_FLOOR_Y + 5.5, -8), Color3.fromRGB(90, 85, 75), 0, folder, Enum.Material.Cobblestone)
    tablet.Name = "WelcomeTablet"
    local wg = Instance.new("SurfaceGui"); wg.Face = Enum.NormalId.Front; wg.Parent = tablet
    local wl1 = Instance.new("TextLabel"); wl1.Size = UDim2.new(1, 0, 0.5, 0); wl1.BackgroundTransparency = 1
    wl1.Text = "THE RUINS"; wl1.TextColor3 = Color3.fromRGB(240, 215, 150); wl1.TextScaled = true; wl1.Font = Enum.Font.GothamBold; wl1.Parent = wg
    local wl2 = Instance.new("TextLabel"); wl2.Size = UDim2.new(1, 0, 0.4, 0); wl2.Position = UDim2.new(0, 0, 0.56, 0); wl2.BackgroundTransparency = 1
    wl2.Text = "Stage 3  -  Ruins Doors 375 to 1000  |  Hide in crumbled walls!"; wl2.TextColor3 = Color3.fromRGB(200, 185, 140); wl2.TextScaled = true; wl2.Font = Enum.Font.Gotham; wl2.Parent = wg

    rooms[-1] = folder
    -- Terrain water (large sea around all ruins)
    pcall(function()
        workspace.Terrain:FillBlock(
            CFrame.new(0, SEA_Y - 2, -30000),
            Vector3.new(1200, 6, 60000),
            Enum.Material.Water
        )
    end)
    if character then character:PivotTo(CFrame.new(0, CAVE_EXIT_Y + 3, 65)) end
end

-- =================================================================
-- HIDING  (ruins gap)
-- =================================================================
hideInGap = function()
    if not currentGap or isHiding or not humanoid then return end
    isHiding = true; humanoid.WalkSpeed = 0; humanoid.JumpPower = 0
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then hiddenParts[part] = part.Transparency; part.Transparency = 1 end
    end
    if hideBtnLabel then hideBtnLabel.Text = "[EXIT GAP]" end
end

exitGap = function()
    if not isHiding or not humanoid then return end
    isHiding = false; humanoid.JumpPower = 50
    for part, trans in pairs(hiddenParts) do if part and part.Parent then part.Transparency = trans end end
    table.clear(hiddenParts)
    if hideBtnLabel then hideBtnLabel.Text = "[HIDE IN RUINS GAP]" end
end

-- =================================================================
-- WARNING
-- =================================================================
showWarning = function(msg, duration)
    if not warningFrame then return end
    warningFrame.Visible = true
    if warningLabel then warningLabel.Text = msg end
    task.delay(duration or 4, function() if warningFrame then warningFrame.Visible = false end end)
end

-- =================================================================
-- DEATH
-- =================================================================
onDeath = function()
    if isDead then return end
    isDead = true; gameStarted = false; isHiding = false; onBoat = false; playerBoat = nil; boatVel = nil; boatGyro = nil
    if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
    inventory = {}; ecstasyActive = false
    local ccc = game.Lighting:FindFirstChild("EcstasyCC"); if ccc then ccc:Destroy() end
    if stemEyeContainer then stemEyeContainer.Visible = false end

    -- NEW: If died to Plantera, remove all tree barriers
    if planteraActive then
        for _, folder in pairs(rooms) do
            local treeBarrier = folder:FindFirstChild("TreeBarrier")
            if treeBarrier then
                treeBarrier:Destroy()
            end
        end
    end

    local dg = Instance.new("ScreenGui"); dg.Name = "RuinsDeathGui"; dg.ResetOnSpawn = false; dg.Parent = player.PlayerGui
    local bg = Instance.new("Frame"); bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = Color3.fromRGB(60, 45, 20); bg.BackgroundTransparency = 0.45; bg.BorderSizePixel = 0; bg.Parent = dg
    local dl = Instance.new("TextLabel"); dl.Size = UDim2.new(1, 0, 0.28, 0); dl.Position = UDim2.new(0, 0, 0.32, 0); dl.BackgroundTransparency = 1
    dl.Text = "YOU FELL IN THE RUINS"; dl.TextColor3 = Color3.fromRGB(255, 230, 140); dl.TextScaled = true; dl.Font = Enum.Font.GothamBold; dl.Parent = bg
    local sl = Instance.new("TextLabel"); sl.Size = UDim2.new(1, 0, 0.1, 0); sl.Position = UDim2.new(0, 0, 0.60, 0); sl.BackgroundTransparency = 1
    sl.Text = "Respawning at checkpoint: Ruins Door " .. tostring(checkpointDoor); sl.TextColor3 = Color3.fromRGB(220, 200, 130); sl.TextScaled = true; sl.Font = Enum.Font.Gotham; sl.Parent = bg

    player.CharacterAdded:Wait(); task.wait(0.3); dg:Destroy(); isDead = false

    local cpZ = getRuinsZ(checkpointDoor) + RUINS_D * 0.35
    if character and rootPart then character:PivotTo(CFrame.new(0, RUINS_FLOOR_Y + 3, cpZ)) end

    currentDoor = checkpointDoor; lastDetectedDoor = checkpointDoor
    if doorLabel then doorLabel.Text = "Ruins Door: " .. tostring(checkpointDoor) end
    gameStarted = true
    for i = checkpointDoor, checkpointDoor + GEN_AHEAD do if i <= DOOR_MAX then generateRoom(i) end end
    advanceDayNight()
end

-- =================================================================
-- ENTITIES
-- =================================================================
spawnDisease = function(doorNum)
    if diseaseActive or diseaseOnCooldown then return end
    diseaseActive = true; diseaseOnCooldown = true
    local ef = Instance.new("Folder"); ef.Name = "DiseaseEntity"; ef.Parent = workspace
    local startZ = getRuinsZ(doorNum - DISEASE_BEFORE) + RUINS_D * 0.5
    local stopZ  = getRuinsZ(doorNum + DISEASE_AFTER) - RUINS_D * 0.5

    local body = makePart(Vector3.new(RUINS_W, 14, RUINS_D), CFrame.new(0, RUINS_FLOOR_Y + 7, startZ), Color3.fromRGB(140, 0, 0), 0.45, ef, Enum.Material.Neon)
    body.Name = "DiseaseBody"; body.CanCollide = false
    -- Smoke particles
    local pe = Instance.new("ParticleEmitter", body); pe.Color = ColorSequence.new(Color3.fromRGB(180, 0, 0))
    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 16)}); pe.Rate = 80; pe.Speed = NumberRange.new(2, 5); pe.Lifetime = NumberRange.new(3, 6)
    pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1)})
    local tr = Instance.new("Trail"); tr.Color = ColorSequence.new(Color3.fromRGB(220, 0, 0)); tr.Lifetime = 1.8; tr.Parent = body
    local a0 = Instance.new("Attachment", body); a0.Position = Vector3.new(0, 5, 0)
    local a1 = Instance.new("Attachment", body); a1.Position = Vector3.new(0, -5, 0)
    tr.Attachment0 = a0; tr.Attachment1 = a1
    local snd = Instance.new("Sound"); snd.SoundId = "rbxassetid://125795970503985"; snd.Volume = 1.5; snd.Looped = true; snd.RollOffMaxDistance = 200; snd.Parent = body; snd:Play()

    -- NEW: Lantern reacts to Disease spawn (red smoke + red light)
    local lantern = getEquippedLantern()
    local redSmoke = nil
    if lantern then
        local handle = lantern:FindFirstChild("Handle")
        if handle then
            local light = handle:FindFirstChild("LanternLight")
            if light then light.Color = Color3.fromRGB(255, 0, 0) end
            redSmoke = Instance.new("ParticleEmitter")
            redSmoke.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
            redSmoke.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.5)})
            redSmoke.Transparency = NumberSequence.new(0.3, 1)
            redSmoke.Rate = 35
            redSmoke.Speed = NumberRange.new(2, 6)
            redSmoke.Lifetime = NumberRange.new(1.5, 3.5)
            redSmoke.Parent = handle
        end
    end

    local mc; mc = RunService.Heartbeat:Connect(function(dt)
        if not body or not body.Parent then mc:Disconnect(); return end
        local newZ = body.CFrame.Position.Z - DISEASE_SPEED * dt
        body.CFrame = CFrame.new(body.CFrame.Position.X, body.CFrame.Position.Y, newZ)
        if rootPart and humanoid and not isDead then
            local dZ = math.abs(rootPart.Position.Z - newZ)
            if dZ < 140 then local i2 = (140 - dZ) / 140; humanoid.CameraOffset = Vector3.new(math.random(-10, 10) * 0.05 * i2, math.random(-10, 10) * 0.05 * i2, 0)
            else humanoid.CameraOffset = Vector3.new(0, 0, 0) end

            -- NEW: Pure Gem counter for Disease
            if not isHiding and dZ < RUINS_D * 0.45 then
                if hasPureGemEquipped() then
                    local gemTool = character:FindFirstChild("PureGem")
                    if gemTool then
                        gemTool:Destroy()
                        for idx, v in ipairs(inventory) do
                            if v == "PureGem" then table.remove(inventory, idx); break end
                        end
                    end
                    -- Disease dies with blood trail + sound (echo + loud)
                    local deathSnd = Instance.new("Sound")
                    deathSnd.SoundId = "rbxassetid://139916424589528"
                    deathSnd.Volume = 3
                    deathSnd.Parent = body
                    deathSnd:Play()
                    local echo = Instance.new("EchoSoundEffect")
                    echo.Delay = 0.25
                    echo.WetLevel = 0.55
                    echo.Parent = deathSnd
                    -- Blood trail particles
                    local blood = Instance.new("ParticleEmitter", body)
                    blood.Color = ColorSequence.new(Color3.fromRGB(120, 0, 0))
                    blood.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0)})
                    blood.Transparency = NumberSequence.new(0.2, 1)
                    blood.Rate = 70
                    blood.Speed = NumberRange.new(1, 5)
                    blood.Lifetime = NumberRange.new(2, 4)
                    mc:Disconnect()
                    diseaseActive = false
                    task.delay(DISEASE_COOLDOWN, function() diseaseOnCooldown = false end)
                    -- Immediate fade
                    local step = 0
                    local fc; fc = RunService.Heartbeat:Connect(function()
                        step = step + 1
                        if body and body.Parent then body.Transparency = 0.45 + step * 0.06 end
                        if step >= 10 then fc:Disconnect(); ef:Destroy() end
                    end)
                    -- Cleanup lantern red smoke
                    if redSmoke then redSmoke:Destroy() end
                    local lanternBack = getEquippedLantern()
                    if lanternBack then
                        local h = lanternBack:FindFirstChild("Handle")
                        if h then
                            local l = h:FindFirstChild("LanternLight")
                            if l then l.Color = Color3.fromRGB(255, 220, 150) end
                        end
                    end
                    return
                else
                    if humanoid.Health > 0 then humanoid.Health = 0; onDeath() end
                end
            end
        end

        if newZ <= stopZ then
            mc:Disconnect(); snd:Stop(); diseaseActive = false
            if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
            -- Cleanup lantern
            if redSmoke then redSmoke:Destroy() end
            local lanternBack = getEquippedLantern()
            if lanternBack then
                local h = lanternBack:FindFirstChild("Handle")
                if h then
                    local l = h:FindFirstChild("LanternLight")
                    if l then l.Color = Color3.fromRGB(255, 220, 150) end
                end
            end
            local step = 0; local fc; fc = RunService.Heartbeat:Connect(function() step = step + 1; if body and body.Parent then body.Transparency = 0.45 + step * 0.06 end; if step >= 10 then fc:Disconnect(); ef:Destroy() end end)
            task.delay(DISEASE_COOLDOWN, function() diseaseOnCooldown = false end)
        end
    end)
end

spawnAgony = function(doorNum)
    if agonyActive or agonyOnCooldown then return end
    agonyActive = true; agonyOnCooldown = true
    -- No warning - just the sound
    local ef = Instance.new("Folder"); ef.Name = "AgonyEntity"; ef.Parent = workspace
    local startZ = getRuinsZ(doorNum - 4) + RUINS_D * 0.5
    local stopZ  = getRuinsZ(doorNum + 5) - RUINS_D * 0.5

    local body = makePart(Vector3.new(5, 12, 5), CFrame.new(0, RUINS_FLOOR_Y + 6, startZ), Color3.fromRGB(5, 5, 5), 0.1, ef, Enum.Material.Neon)
    body.Name = "AgonyBody"; body.CanCollide = false
    local pe = Instance.new("ParticleEmitter", body); pe.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 18)}); pe.Rate = 140; pe.Speed = NumberRange.new(6, 14); pe.Lifetime = NumberRange.new(1, 2.5)
    local tr = Instance.new("Trail"); tr.Color = ColorSequence.new(Color3.fromRGB(10, 10, 10)); tr.Lifetime = 2; tr.Parent = body
    local at0 = Instance.new("Attachment", body); at0.Position = Vector3.new(0, 5, 0)
    local at1 = Instance.new("Attachment", body); at1.Position = Vector3.new(0, -5, 0)
    tr.Attachment0 = at0; tr.Attachment1 = at1
    -- Ominous ambient sound (no warning text)
    local snd = Instance.new("Sound"); snd.SoundId = "rbxassetid://89060529910257"; snd.Volume = 2.5; snd.Looped = true; snd.RollOffMaxDistance = 400; snd.Parent = body; snd:Play()

    -- NEW: Lantern reacts to Agony (breaks)
    local lantern = getEquippedLantern()
    if lantern then
        local handle = lantern:FindFirstChild("Handle")
        if handle then
            local light = handle:FindFirstChild("LanternLight")
            if light then light.Enabled = false end
            local brokeSnd = Instance.new("Sound")
            brokeSnd.SoundId = "rbxassetid://140414748697760"
            brokeSnd.Volume = 1.8
            brokeSnd.Parent = handle
            brokeSnd:Play()
            brokeSnd.Ended:Connect(function() brokeSnd:Destroy() end)
        end
    end

    local ac; ac = RunService.Heartbeat:Connect(function(dt)
        if not body or not body.Parent then ac:Disconnect(); return end
        local newZ = body.CFrame.Position.Z - AGONY_SPEED * dt
        body.CFrame = CFrame.new(body.CFrame.Position.X, body.CFrame.Position.Y, newZ)
        if rootPart and humanoid and not isDead then
            local dZ = math.abs(rootPart.Position.Z - newZ)
            if dZ < 160 then local i2 = (160 - dZ) / 160; humanoid.CameraOffset = Vector3.new(math.random(-10, 10) * 0.09 * i2, math.random(-10, 10) * 0.09 * i2, 0)
            else humanoid.CameraOffset = Vector3.new(0, 0, 0) end
            local distToPlayer = (rootPart.Position - body.Position).Magnitude
            -- NEW: Pure Gem counter for Agony (look or distance)
            local isKilledByAgony = false
            if distToPlayer < 10 then
                isKilledByAgony = true
            else
                -- look kill
                local camDir = camera.CFrame.LookVector
                local dirToAgony = (body.Position - camera.CFrame.Position).Unit
                if camDir:Dot(dirToAgony) > 0.5 then
                    local rp = RaycastParams.new(); rp.FilterDescendantsInstances = {ef, character, rooms[-1]}; rp.FilterType = Enum.RaycastFilterType.Exclude
                    local hit = workspace:Raycast(camera.CFrame.Position, dirToAgony * distToPlayer, rp)
                    if not hit then isKilledByAgony = true end
                end
            end

            if isKilledByAgony then
                if hasPureGemEquipped() then
                    local gemTool = character:FindFirstChild("PureGem")
                    if gemTool then
                        gemTool:Destroy()
                        for idx, v in ipairs(inventory) do if v == "PureGem" then table.remove(inventory, idx); break end end
                    end
                    -- Agony dies with blood trail + sound (echo + loud)
                    local deathSnd = Instance.new("Sound")
                    deathSnd.SoundId = "rbxassetid://139916424589528"
                    deathSnd.Volume = 3
                    deathSnd.Parent = body
                    deathSnd:Play()
                    local echo = Instance.new("EchoSoundEffect")
                    echo.Delay = 0.25
                    echo.WetLevel = 0.55
                    echo.Parent = deathSnd
                    -- Blood trail
                    local blood = Instance.new("ParticleEmitter", body)
                    blood.Color = ColorSequence.new(Color3.fromRGB(120, 0, 0))
                    blood.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0)})
                    blood.Transparency = NumberSequence.new(0.2, 1)
                    blood.Rate = 70
                    blood.Speed = NumberRange.new(1, 5)
                    blood.Lifetime = NumberRange.new(2, 4)
                    ac:Disconnect(); snd:Stop(); agonyActive = false
                    if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
                    -- Immediate fade
                    local step = 0; local fc; fc = RunService.Heartbeat:Connect(function() step = step + 1; if body and body.Parent then body.Transparency = 0.1 + step * 0.09 end; if step >= 10 then fc:Disconnect(); ef:Destroy() end end)
                    task.delay(AGONY_COOLDOWN, function() agonyOnCooldown = false end)
                    -- Lantern lights back up
                    local lanternLit = getEquippedLantern()
                    if lanternLit then
                        local h = lanternLit:FindFirstChild("Handle")
                        if h then
                            local l = h:FindFirstChild("LanternLight")
                            if l then
                                l.Enabled = true
                                l.Color = Color3.fromRGB(255, 220, 150)
                                local litSnd = Instance.new("Sound")
                                litSnd.SoundId = "rbxassetid://139419162875767"
                                litSnd.Volume = 1.6
                                litSnd.Parent = h
                                litSnd:Play()
                                litSnd.Ended:Connect(function() litSnd:Destroy() end)
                            end
                        end
                    end
                    return
                else
                    if humanoid.Health > 0 then humanoid.Health = 0; onDeath() end
                end
            end
        end
        if newZ <= stopZ then
            ac:Disconnect(); snd:Stop(); agonyActive = false
            if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
            -- Lantern lights back up
            local lanternLit = getEquippedLantern()
            if lanternLit then
                local h = lanternLit:FindFirstChild("Handle")
                if h then
                    local l = h:FindFirstChild("LanternLight")
                    if l then
                        l.Enabled = true
                        l.Color = Color3.fromRGB(255, 220, 150)
                        local litSnd = Instance.new("Sound")
                        litSnd.SoundId = "rbxassetid://139419162875767"
                        litSnd.Volume = 1.6
                        litSnd.Parent = h
                        litSnd:Play()
                        litSnd.Ended:Connect(function() litSnd:Destroy() end)
                    end
                end
            end
            local step = 0; local fc; fc = RunService.Heartbeat:Connect(function() step = step + 1; if body and body.Parent then body.Transparency = 0.1 + step * 0.09 end; if step >= 10 then fc:Disconnect(); ef:Destroy() end end)
            task.delay(AGONY_COOLDOWN, function() agonyOnCooldown = false end)
        end
    end)
end

spawnHer = function(doorNum)
    if herActive or herOnCooldown then return end
    herActive = true; herOnCooldown = true
    local ef = Instance.new("Folder"); ef.Name = "HerEntity"; ef.Parent = workspace
    local spawnZ = getRuinsZ(doorNum)
    local body = makePart(Vector3.new(1.8, 7.5, 1.8), CFrame.new(math.random(-15, 15), RUINS_FLOOR_Y + 3.75, spawnZ), Color3.fromRGB(0, 0, 0), 0, ef)
    body.Name = "HerBody"; body.CanCollide = false
    local snd = Instance.new("Sound"); snd.SoundId = "rbxassetid://129136912774651"; snd.Volume = 2; snd.Looped = true; snd.RollOffMaxDistance = 100; snd.Parent = body; snd:Play()
    local lookTimer = 0; local isChasing = false; local hc
    hc = RunService.Heartbeat:Connect(function(dt)
        if not body or not body.Parent or isDead then if hc then hc:Disconnect() end; return end
        if not isChasing then
            if rootPart and camera then
                local dot = camera.CFrame.LookVector:Dot((body.Position - camera.CFrame.Position).Unit)
                if dot > 0.75 then lookTimer = lookTimer + dt else lookTimer = math.max(0, lookTimer - dt) end
                if lookTimer >= 3 then isChasing = true; snd:Stop(); snd.SoundId = "rbxassetid://108968287863512"; snd.Volume = 3; snd:Play(); body.Color = Color3.fromRGB(22, 0, 0) end
            end
            if currentDoor > doorNum + 2 then hc:Disconnect(); ef:Destroy(); herActive = false; task.delay(HER_COOLDOWN, function() herOnCooldown = false end) end
        else
            if rootPart then
                local lCF = CFrame.lookAt(body.Position, rootPart.Position)
                local newPos = lCF.Position + lCF.LookVector * HER_SPEED * dt
                body.CFrame = CFrame.new(newPos.X, RUINS_FLOOR_Y + 3.75, newPos.Z)
                local dist = (rootPart.Position - body.Position).Magnitude
                if dist < 90 and humanoid then local i2 = (90 - dist) / 90; humanoid.CameraOffset = Vector3.new(math.random(-10, 10) * 0.07 * i2, math.random(-10, 10) * 0.07 * i2, 0) end

                -- NEW: Pure Gem counter for Her (chase kill)
                if dist < 4 and humanoid and humanoid.Health > 0 then
                    if hasPureGemEquipped() then
                        local gemTool = character:FindFirstChild("PureGem")
                        if gemTool then
                            gemTool:Destroy()
                            for idx, v in ipairs(inventory) do if v == "PureGem" then table.remove(inventory, idx); break end end
                        end
                        -- Her dies with blood trail + special sound (echo + loud)
                        local deathSnd = Instance.new("Sound")
                        deathSnd.SoundId = "rbxassetid://139936933116829"
                        deathSnd.Volume = 3.5
                        deathSnd.Parent = body
                        deathSnd:Play()
                        local echo = Instance.new("EchoSoundEffect")
                        echo.Delay = 0.3
                        echo.WetLevel = 0.6
                        echo.Parent = deathSnd
                        -- Blood trail
                        local bloodTrail = Instance.new("Trail")
                        bloodTrail.Color = ColorSequence.new(Color3.fromRGB(120, 0, 0))
                        bloodTrail.Lifetime = 3.5
                        bloodTrail.Parent = body
                        local att0 = Instance.new("Attachment", body); att0.Position = Vector3.new(0, 3, 0)
                        local att1 = Instance.new("Attachment", body); att1.Position = Vector3.new(0, -3, 0)
                        bloodTrail.Attachment0 = att0
                        bloodTrail.Attachment1 = att1
                        hc:Disconnect(); snd:Stop(); herActive = false
                        if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
                        ef:Destroy()
                        task.delay(HER_COOLDOWN, function() herOnCooldown = false end)
                        return
                    else
                        humanoid.Health = 0; onDeath()
                    end
                end

                -- Her retreats at dawn (as requested: long chase until day, disappears after day even if still "crying")
                if isDaytime() then
                    hc:Disconnect(); snd:Stop(); if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end; ef:Destroy(); herActive = false; task.delay(HER_COOLDOWN, function() herOnCooldown = false end)
                end
            end
        end
    end)
end

spawnDrain = function(doorNum)
    if drainActive or drainOnCooldown then return end
    drainActive = true; drainOnCooldown = true
    -- Sea turns black and rises toward bridge level
    local ef = Instance.new("Folder"); ef.Name = "DrainEntity"; ef.Parent = workspace
    local centerZ = getRuinsZ(currentDoor)

    -- Black water overlay (large plane that rises) - can turn white with Pure Gem
    local blackSea = makePart(Vector3.new(1000, 0.5, 1500), CFrame.new(0, SEA_Y + 0.3, -30000), Color3.fromRGB(5, 5, 5), 0.1, ef, Enum.Material.Neon)
    blackSea.Name = "BlackSea"; blackSea.CanCollide = false

    local snd = Instance.new("Sound"); snd.SoundId = "rbxassetid://93281700241946"; snd.Volume = 2.2; snd.Looped = true; snd.Parent = blackSea; snd:Play()

    local elapsed = 0; local maxRise = RUINS_FLOOR_Y - SEA_Y - 0.2
    local healTimer = 0  -- for Pure Gem heal

    local dc; dc = RunService.Heartbeat:Connect(function(dt)
        if isDead then if dc then dc:Disconnect() end; ef:Destroy(); drainActive = false; drainOnCooldown = false; return end
        elapsed = elapsed + dt
        local currentH = 0

        if elapsed <= DRAIN_RISE_TIME then currentH = (elapsed / DRAIN_RISE_TIME) * maxRise
        elseif elapsed <= DRAIN_RISE_TIME + DRAIN_STAY_TIME then currentH = maxRise
        elseif elapsed <= DRAIN_RISE_TIME + DRAIN_STAY_TIME + DRAIN_FALL_TIME then
            local f = elapsed - (DRAIN_RISE_TIME + DRAIN_STAY_TIME); currentH = maxRise - (f / DRAIN_FALL_TIME) * maxRise
        else
            dc:Disconnect(); snd:Stop(); ef:Destroy(); drainActive = false
            task.delay(DRAIN_COOLDOWN, function() drainOnCooldown = false end); return
        end

        local newY = SEA_Y + 0.3 + currentH
        blackSea.CFrame = CFrame.new(0, newY, -30000)

        -- NEW: Pure Gem changes drain to white sea + healing touch
        local gemHeld = hasPureGemEquipped()
        if gemHeld then
            blackSea.Color = Color3.fromRGB(220, 240, 255) -- white sea
        else
            blackSea.Color = Color3.fromRGB(5, 5, 5)
        end

        -- Kill / heal player if water reaches their feet
        if rootPart and humanoid and humanoid.Health > 0 and not isHiding then
            if rootPart.Position.Y < newY + 1.5 then
                if gemHeld then
                    healTimer = healTimer + dt
                    if healTimer >= 1 then
                        humanoid.Health = math.min(100, humanoid.Health + 12)
                        healTimer = 0
                    end
                else
                    local dSnd = Instance.new("Sound"); dSnd.SoundId = "rbxassetid://128701355933535"; dSnd.Volume = 2; dSnd.Parent = workspace; dSnd:Play()
                    humanoid.Health = 0; onDeath()
                end
            else
                healTimer = 0
            end
        end
    end)
end

spawnPlantera = function(doorNum)
    if planteraActive or planteraOnCooldown then return end
    planteraActive = true; planteraOnCooldown = true; planteraSpawned = true
    -- Create tree barriers at exit of several rooms ahead
    local treeBarrierFolders = {}
    for d = doorNum, doorNum + PLANTERA_AFTER + 1 do
        if rooms[d] then
            local rZ = getRuinsZ(d) - RUINS_D * 0.5
            local tf = makeTreeBarrier(rooms[d], Vector3.new(0, 0, rZ), rZ)
            table.insert(treeBarrierFolders, {folder = tf, z = rZ})
        end
    end
    showWarning("PLANTERA approaches! The exit is blocked - HIDE NOW!", 4)

    local ef = Instance.new("Folder"); ef.Name = "PlanteraEntity"; ef.Parent = workspace
    local startZ = getRuinsZ(doorNum - PLANTERA_BEFORE) + RUINS_D * 0.5
    local stopZ  = getRuinsZ(doorNum + PLANTERA_AFTER) - RUINS_D * 0.5

    local body = makePart(Vector3.new(RUINS_W - 2, 12, RUINS_D), CFrame.new(0, RUINS_FLOOR_Y + 6, startZ), Color3.fromRGB(18, 75, 18), 0.45, ef, Enum.Material.Neon)
    body.Name = "PlanteraBody"; body.CanCollide = false

    local pe = Instance.new("ParticleEmitter", body); pe.Color = ColorSequence.new(Color3.fromRGB(10, 220, 10))
    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 8)}); pe.Rate = 60; pe.Speed = NumberRange.new(5, 15)
    local tr = Instance.new("Trail"); tr.Color = ColorSequence.new(Color3.fromRGB(30, 200, 30)); tr.Lifetime = 2; tr.Parent = body
    local pa0 = Instance.new("Attachment", body); pa0.Position = Vector3.new(0, 5, 0)
    local pa1 = Instance.new("Attachment", body); pa1.Position = Vector3.new(0, -5, 0)
    tr.Attachment0 = pa0; tr.Attachment1 = pa1

    local snd = Instance.new("Sound"); snd.SoundId = "rbxassetid://112243770921992"; snd.Volume = 1.5; snd.Looped = true; snd.RollOffMaxDistance = 200; snd.Parent = body; snd:Play()

    local pc; pc = RunService.Heartbeat:Connect(function(dt)
        if not body or not body.Parent then pc:Disconnect(); return end
        local newZ = body.CFrame.Position.Z - PLANTERA_SPEED * dt
        body.CFrame = CFrame.new(body.CFrame.Position.X, body.CFrame.Position.Y, newZ)

        -- Destroy tree barriers as Plantera passes through them
        for idx, tbData in ipairs(treeBarrierFolders) do
            if tbData.folder and tbData.folder.Parent and newZ <= tbData.z + 5 then
                tbData.folder:Destroy(); treeBarrierFolders[idx] = {folder = nil, z = tbData.z}
            end
        end

        if rootPart and humanoid and not isDead then
            local dZ = math.abs(rootPart.Position.Z - newZ)
            if dZ < 120 then local i2 = (120 - dZ) / 120; humanoid.CameraOffset = Vector3.new(math.random(-10, 10) * 0.04 * i2, math.random(-10, 10) * 0.04 * i2, 0)
            else humanoid.CameraOffset = Vector3.new(0, 0, 0) end

            -- NEW: Pure Gem counter for Plantera
            if not isHiding and dZ < RUINS_D * 0.45 then
                if hasPureGemEquipped() then
                    local gemTool = character:FindFirstChild("PureGem")
                    if gemTool then
                        gemTool:Destroy()
                        for idx, v in ipairs(inventory) do if v == "PureGem" then table.remove(inventory, idx); break end end
                    end
                    -- Plantera dies with blood trail + sound (echo + loud)
                    local deathSnd = Instance.new("Sound")
                    deathSnd.SoundId = "rbxassetid://139916424589528"
                    deathSnd.Volume = 3
                    deathSnd.Parent = body
                    deathSnd:Play()
                    local echo = Instance.new("EchoSoundEffect")
                    echo.Delay = 0.25
                    echo.WetLevel = 0.55
                    echo.Parent = deathSnd
                    -- Blood trail particles
                    local blood = Instance.new("ParticleEmitter", body)
                    blood.Color = ColorSequence.new(Color3.fromRGB(120, 0, 0))
                    blood.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0)})
                    blood.Transparency = NumberSequence.new(0.2, 1)
                    blood.Rate = 70
                    blood.Speed = NumberRange.new(1, 5)
                    blood.Lifetime = NumberRange.new(2, 4)
                    pc:Disconnect(); snd:Stop(); planteraActive = false
                    if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
                    -- Immediate fade
                    local step = 0
                    local fc; fc = RunService.Heartbeat:Connect(function()
                        step = step + 1
                        if body and body.Parent then body.Transparency = 0.45 + step * 0.06 end
                        if step >= 10 then fc:Disconnect(); ef:Destroy() end
                    end)
                    task.delay(PLANTERA_COOLDOWN, function() planteraOnCooldown = false; planteraSpawned = false end)
                    return
                else
                    if humanoid.Health > 0 then humanoid.Health = 0; onDeath() end
                end
            end
        end

        if newZ <= stopZ then
            pc:Disconnect(); snd:Stop(); planteraActive = false
            if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
            local step = 0; local fc; fc = RunService.Heartbeat:Connect(function() step = step + 1; if body and body.Parent then body.Transparency = 0.45 + step * 0.06 end; if step >= 10 then fc:Disconnect(); ef:Destroy() end end)
            task.delay(PLANTERA_COOLDOWN, function() planteraOnCooldown = false; planteraSpawned = false end)
        end
    end)
end

spawnStem = function()
    if stemActive or stemOnCooldown then return end
    stemActive = true; stemOnCooldown = true

    stemEyeOuter.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    stemEyeStroke.Color = Color3.fromRGB(0, 255, 60)
    stemIris.BackgroundColor3 = Color3.fromRGB(0, 185, 0)
    stemPupil.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    stemPupil.Size = UDim2.new(0, 38, 0, 38); stemPupil.Position = UDim2.new(0.5, -19, 0.5, -19)
    stemTopLid.Size = UDim2.new(1, 0, 0.5, 2); stemTopLid.Position = UDim2.new(0, 0, 0, 0)
    stemTopLid.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    stemBottomLid.Size = UDim2.new(1, 0, 0.5, 2); stemBottomLid.Position = UDim2.new(0, 0, 0.5, -2)
    stemBottomLid.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    stemEyeContainer.Visible = true

    task.wait(2)

    stemEyeStroke.Color = Color3.fromRGB(255, 0, 0)
    stemIris.BackgroundColor3 = Color3.fromRGB(210, 0, 0)

    for _ = 1, 3 do
        stemEyeOuter.BackgroundColor3 = Color3.fromRGB(35, 0, 0)
        stemTopLid.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        stemBottomLid.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
        task.wait(0.11)
        stemEyeOuter.BackgroundColor3 = Color3.fromRGB(230, 210, 210)
        stemTopLid.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
        stemBottomLid.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
        task.wait(0.11)
    end

    stemEyeOuter.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    task.wait(0.18)

    local openInfo = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(stemTopLid, openInfo, {Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 0)}):Play()
    TweenService:Create(stemBottomLid, openInfo, {Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 0)}):Play()
    TweenService:Create(stemPupil, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 54, 0, 54), Position = UDim2.new(0.5, -27, 0.5, -27)}):Play()

    if stemSnd then stemSnd.SoundId = "rbxassetid://132516383045655"; stemSnd:Play() end
    task.wait(0.6)

    local isEyeOpen = true; local stemConn
    stemConn = RunService.Heartbeat:Connect(function()
        if not isEyeOpen or isDead then stemConn:Disconnect(); return end
        if humanoid and rootPart and not isHiding then
            local moving = humanoid.MoveDirection.Magnitude > 0.05
            local jumping = humanoid:GetState() == Enum.HumanoidStateType.Jumping
            if moving or jumping then
                -- NEW: Pure Gem counter for Stem
                if hasPureGemEquipped() then
                    local gemTool = character:FindFirstChild("PureGem")
                    if gemTool then
                        gemTool:Destroy()
                        for idx, v in ipairs(inventory) do if v == "PureGem" then table.remove(inventory, idx); break end end
                    end
                    isEyeOpen = false
                    -- Stem death sound (echo + loud)
                    local stemDeathSnd = Instance.new("Sound")
                    stemDeathSnd.SoundId = "rbxassetid://140325083438865"
                    stemDeathSnd.Volume = 3.2
                    stemDeathSnd.Parent = workspace
                    stemDeathSnd:Play()
                    local echo = Instance.new("EchoSoundEffect")
                    echo.Delay = 0.22
                    echo.WetLevel = 0.5
                    echo.Parent = stemDeathSnd
                    -- Blood splatter on screen that slowly disappears
                    local bloodOverlay = Instance.new("Frame")
                    bloodOverlay.Size = UDim2.new(1, 0, 1, 0)
                    bloodOverlay.BackgroundColor3 = Color3.fromRGB(110, 0, 0)
                    bloodOverlay.BackgroundTransparency = 0.25
                    bloodOverlay.BorderSizePixel = 0
                    bloodOverlay.ZIndex = 200
                    bloodOverlay.Parent = screenGui
                    TweenService:Create(bloodOverlay, TweenInfo.new(8, Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
                    task.delay(9, function() if bloodOverlay and bloodOverlay.Parent then bloodOverlay:Destroy() end end)
                    -- Close eye and end
                    local closeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    TweenService:Create(stemTopLid, closeInfo, {Size = UDim2.new(1, 0, 0.5, 2), Position = UDim2.new(0, 0, 0, 0)}):Play()
                    TweenService:Create(stemBottomLid, closeInfo, {Size = UDim2.new(1, 0, 0.5, 2), Position = UDim2.new(0, 0, 0.5, -2)}):Play()
                    TweenService:Create(stemPupil, closeInfo, {Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0.5, -19, 0.5, -19)}):Play()
                    task.wait(0.45)
                    stemEyeContainer.Visible = false; stemActive = false
                    task.delay(STEM_COOLDOWN, function() stemOnCooldown = false end)
                    stemConn:Disconnect()
                    return
                else
                    stemPupil.Size = UDim2.new(0, 10, 0, 10); stemPupil.Position = UDim2.new(0.5, -5, 0.5, -5)
                    task.wait(0.06); isEyeOpen = false; humanoid.Health = 0; onDeath(); stemConn:Disconnect()
                end
            end
        end
    end)

    task.delay(5, function()
        isEyeOpen = false
        local closeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(stemTopLid, closeInfo, {Size = UDim2.new(1, 0, 0.5, 2), Position = UDim2.new(0, 0, 0, 0)}):Play()
        TweenService:Create(stemBottomLid, closeInfo, {Size = UDim2.new(1, 0, 0.5, 2), Position = UDim2.new(0, 0, 0.5, -2)}):Play()
        TweenService:Create(stemPupil, closeInfo, {Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0.5, -19, 0.5, -19)}):Play()
        task.wait(0.45)
        stemEyeContainer.Visible = false; stemActive = false
        task.delay(STEM_COOLDOWN, function() stemOnCooldown = false end)
    end)
end

-- =================================================================
-- DOOR REACHED
-- =================================================================
onDoorReached = function(doorNum)
    currentDoor = doorNum
    if doorLabel then doorLabel.Text = "Ruins Door: " .. tostring(doorNum) end

    if doorNum > RUINS_START and (doorNum - RUINS_START) % CHECKPOINT_EVERY == 0 then
        checkpointDoor = doorNum; showWarning("CHECKPOINT SAVED  -  Ruins Door " .. tostring(doorNum), 3)
    end

    -- Generate ahead
    for i = doorNum + 1, doorNum + GEN_AHEAD do if i <= DOOR_MAX then generateRoom(i) end end
    -- Clean behind
    for i = RUINS_START, doorNum - CLEAN_BEHIND do
        if rooms[i] then rooms[i]:Destroy(); rooms[i] = nil end
        roomType[i] = nil; gemRoomStates[i] = nil
    end

    -- Disease: any time, 35% chance
    if not diseaseActive and not diseaseOnCooldown then
        if math.random(1, 100) <= 35 then spawnDisease(doorNum) end
    end

    -- Night-only entities
    if isNight() then
        if not herActive and not herOnCooldown and math.random(1, 100) <= 30 then
            task.spawn(function() spawnHer(doorNum) end)
        end
        if not agonyActive and not agonyOnCooldown and not diseaseActive and math.random(1, 100) <= 22 then
            task.spawn(function() spawnAgony(doorNum) end)
        end
    end

    -- Day-only entities
    if isDaytime() then
        if not planteraActive and not planteraSpawned and not planteraOnCooldown and doorNum >= RUINS_START + 5 then
            if math.random(1, 100) <= 40 then task.spawn(function() spawnPlantera(doorNum) end) end
        end
        if not stemActive and not stemOnCooldown and math.random(1, 100) <= 50 then
            task.spawn(function() spawnStem() end)
        end
    end

    -- Drain: any time
    if not drainActive and not drainOnCooldown and doorNum >= RUINS_START + 3 then
        if math.random(1, 100) <= 28 then task.spawn(function() spawnDrain(doorNum) end) end
    end

    if doorNum >= DOOR_MAX then
        showWarning("YOU ESCAPED! Stage 3 complete. The Ruins are behind you.", 20)
        gameStarted = false
    end
end

-- =================================================================
-- START GAME
-- =================================================================
startGame = function()
    gameStarted = true; currentDoor = RUINS_START; lastDetectedDoor = RUINS_START; checkpointDoor = RUINS_START
    if character then character:PivotTo(CFrame.new(0, RUINS_FLOOR_Y + 3, getRuinsZ(RUINS_START) + RUINS_D * 0.4)) end
    for i = RUINS_START, RUINS_START + GEN_AHEAD do generateRoom(i) end
    advanceDayNight()
end

-- =================================================================
-- CHARACTER REF
-- =================================================================
updateCharRef = function(newChar)
    character = newChar; humanoid = newChar:WaitForChild("Humanoid"); rootPart = newChar:WaitForChild("HumanoidRootPart")
    task.spawn(function() local rs = rootPart:WaitForChild("Running", 3); if rs then rs.Volume = 0 end end)

    grassStepSound = Instance.new("Sound"); grassStepSound.SoundId = "rbxassetid://140563218459039"; grassStepSound.Volume = 0.9; grassStepSound.Parent = rootPart
    stoneStepSound = Instance.new("Sound"); stoneStepSound.SoundId = "rbxassetid://138662719868461"; stoneStepSound.Volume = 0.8; stoneStepSound.Parent = rootPart

    humanoid.Died:Connect(function() onDeath() end)
end

-- =================================================================
-- MAIN LOOP
-- =================================================================
mainLoop = function()
    RunService.Heartbeat:Connect(function(dt)
        if not gameStarted or not rootPart then return end

        -- Walk speed
        local targetSpeed = 16
        if ecstasyActive then
            if tick() > ecstasyEndTime then
                ecstasyActive = false; local ccc = game.Lighting:FindFirstChild("EcstasyCC"); if ccc then ccc:Destroy() end
            else targetSpeed = 22 end
        end
        if not isHiding and humanoid and not diseaseActive and not planteraActive then
            humanoid.WalkSpeed = targetSpeed
        end

        -- Sea death trigger
        if rootPart.Position.Y < SEA_Y + 1 and not isDead and humanoid and humanoid.Health > 0 then
            humanoid.Health = 0; onDeath()
        end

        -- Footsteps
        if humanoid and humanoid.Health > 0 and not isHiding then
            local moving = humanoid.MoveDirection.Magnitude > 0
            if moving and humanoid.FloorMaterial \~= Enum.Material.Air then
                local sr = humanoid.WalkSpeed / 16; local siv = 0.36 / math.max(0.1, sr)
                if tick() - lastStepTime >= siv then
                    lastStepTime = tick()
                    local snd = (humanoid.FloorMaterial == Enum.Material.Grass or humanoid.FloorMaterial == Enum.Material.Water) and grassStepSound or stoneStepSound
                    if snd then snd.PlaybackSpeed = sr; snd:Play() end
                end
            else lastStepTime = 0 end
        end

        -- Boat control
        if onBoat and playerBoat and boatVel and rootPart then
            local fwd = 0; local strafe = 0
            if UserInput:IsKeyDown(Enum.KeyCode.W) or UserInput:IsKeyDown(Enum.KeyCode.Up) then fwd = 1 end
            if UserInput:IsKeyDown(Enum.KeyCode.S) or UserInput:IsKeyDown(Enum.KeyCode.Down) then fwd = -1 end
            if UserInput:IsKeyDown(Enum.KeyCode.A) or UserInput:IsKeyDown(Enum.KeyCode.Left) then strafe = 1 end
            if UserInput:IsKeyDown(Enum.KeyCode.D) or UserInput:IsKeyDown(Enum.KeyCode.Right) then strafe = -1 end

            -- Mobile touch support (steer towards camera look direction)
            if UserInput.TouchEnabled and humanoid and humanoid.MoveDirection.Magnitude > 0 then
                local md = humanoid.MoveDirection; fwd = md.Z; strafe = md.X
            end

            local camLook = camera.CFrame.LookVector
            local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
            local flatRight = Vector3.new(camLook.Z, 0, -camLook.X).Unit
            local vel = (flatLook * fwd + flatRight * strafe) * BOAT_SPEED
            boatVel.Velocity = vel
            if boatGyro then boatGyro.CFrame = CFrame.new(playerBoat.Position, playerBoat.Position + flatLook) end

            -- Keep player on boat
            if rootPart then rootPart.CFrame = CFrame.new(playerBoat.Position + Vector3.new(0, 2.5, 0)) end

            -- Keep boat at sea level
            local bPos = playerBoat.Position
            if math.abs(bPos.Y - (SEA_Y + 1)) > 0.5 then
                playerBoat.CFrame = CFrame.new(bPos.X, SEA_Y + 1, bPos.Z)
            end

            -- Kill wall - prevent going too far
            local roomZ = getRuinsZ(currentDoor)
            local distFromRoom = math.sqrt((bPos.X) ^ 2 + (bPos.Z - roomZ) ^ 2)
            if distFromRoom > BOAT_KILL_DIST then
                -- Push back
                local pushDir = Vector3.new(bPos.X, 0, bPos.Z - roomZ).Unit
                playerBoat.CFrame = CFrame.new(playerBoat.Position - pushDir * 2)
                boatVel.Velocity = -pushDir * 10
                showWarning("Invisible barrier! Don't stray too far.", 1.5)
            end

            -- If boat somehow passes the next room's entrance, sink it
            if bPos.Z < getRuinsZ(currentDoor + 1) - RUINS_D * 0.3 then
                if humanoid and humanoid.Health > 0 then
                    showWarning("You tried to skip - the boat sinks!", 2)
                    humanoid.Health = 0; onDeath()
                end
            end
        end

        -- Door detection
        local pZ = rootPart.Position.Z
        local approxDoor = currentDoor
        local nextZ = getRuinsZ(approxDoor) - RUINS_D * 0.5
        while pZ < nextZ and approxDoor < DOOR_MAX do
            approxDoor = approxDoor + 1; nextZ = getRuinsZ(approxDoor) - RUINS_D * 0.5
        end

        if approxDoor > lastDetectedDoor and approxDoor <= DOOR_MAX then
            lastDetectedDoor = approxDoor; onDoorReached(approxDoor)
        end

        -- Ruins gap detection
        nearGap = false; currentGap = nil
        for d = currentDoor - 1, currentDoor + 1 do
            if rooms[d] then
                for _, part in ipairs(rooms[d]:GetDescendants()) do
                    if part:IsA("BasePart") and part:GetAttribute("IsLocker") then
                        if (rootPart.Position - part.Position).Magnitude < HIDE_DIST then nearGap = true; currentGap = part end
                    end
                end
            end
        end
        if hidePrompt then hidePrompt.Visible = (nearGap and not isHiding) or isHiding end
    end)
end

-- =================================================================
-- INITIALIZE
-- =================================================================
updateCharRef(player.Character or player.CharacterAdded:Wait())
player.CharacterAdded:Connect(updateCharRef)
setupLighting()
createHUD()
createLobby()
mainLoop()
