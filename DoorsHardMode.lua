-- ============================================================
-- DOORS INSPIRED GAME - LocalScript Executor
-- Devious Goober - Modded (Snow White Boss, Malware Fix & VOID)
-- + GARDEN ROOMS & DOOR 100 SPAWN OVERRIDES
-- + HARD MODE (Speed 25, Music, 5min Timer, Door 100 Win, All Entities From 0)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== HARD MODE TOGGLE =====
local HARD_MODE = true  -- Set to false for normal mode

-- ===== CONSTANTS =====
local ROOM_W            = 30
local ROOM_H            = 12
local ROOM_D            = 50
local DOOR_MAX          = 1000
local CHECKPOINT_EVERY  = 100
local PLANTERA_SPEED    = 50
local PLANTERA_COOLDOWN = 10
local DISEASE_SPEED     = 75
local DISEASE_COOLDOWN  = 10
local STEM_START        = 50
local STEM_COOLDOWN     = 60
local PLANTERA_BEFORE   = 5
local PLANTERA_AFTER    = 5
local MALWARE_SPEED     = 100
local MALWARE_COOLDOWN  = 3
local MALWARE_START     = 75
local MALWARE_BEFORE    = 10
local MALWARE_AFTER     = 10
local HER_START         = 100
local HER_COOLDOWN      = 120
local HER_SPEED         = 30
local LOCKER_DIST       = 5
local GEN_AHEAD         = 7
local CLEAN_BEHIND      = 8
local MAX_ITEMS         = 3

local SNOW_WHITE_DOOR   = 135
local SNOW_WHITE_END    = 170

local GARDEN_START      = 175
local GARDEN_CHANCE     = 30

-- VOID CONSTANTS
local VOID_START        = 180
local VOID_CHANCE       = 20
local VOID_COOLDOWN     = 30

-- ===== HARD MODE CONSTANTS =====
local HARD_MODE_DOOR_MAX  = 100       -- Win at door 100 in hard mode
local HARD_MODE_TIME      = 300       -- 5 minutes (seconds)
local HARD_MODE_SPEED     = 25        -- Player speed
local HARD_MODE_CHANCE    = 45        -- 45% spawn chance for all entities
local HARD_MODE_COOLDOWN  = 7         -- 7s cooldown for all entities
local HARD_MODE_MUSIC_ID  = "rbxassetid://106551572422078"
local HARD_MODE_STEM_OPEN = 3         -- Stem eye open duration (seconds)
local HARD_GARDEN_CHANCE  = 30        -- Garden chance from door 0 in hard mode

-- Decoration part names that Malware targets
local DECOR_NAMES = {
    TableTop=true, TableLeg=true, PlantPot=true, PlantBush=true,
    DrawerBody=true, Drawer=true, DrawerHandle=true,
    BedFrame=true, Mattress=true, Pillow=true, Headboard=true,
    Shelf=true, ShelfBoard=true, Crate=true,
    WallSconce=true, Vine=true, Rug=true, Battery=true,
}

-- ===== STATE =====
local character      = nil
local humanoid       = nil
local rootPart       = nil
local currentDoor    = 0
local lastDetectedDoor = 0
local gameStarted    = false
local isHiding       = false
local nearLocker     = false
local currentLocker  = nil
local checkpointDoor = 0
local rooms          = {}
local roomIsDark     = {}
local planteraActive = false
local planteraOnCooldown = false
local diseaseActive  = false
local diseaseOnCooldown = false
local stemActive     = false
local stemOnCooldown = false
local malwareActive  = false
local malwareOnCooldown = false
local herActive      = false
local herOnCooldown  = false
local voidActive     = false
local voidOnCooldown = false
local planteraSpawnedThisCheckpoint = false
local isDead         = false
local hiddenParts    = {}
local inventory      = {}
local coins          = 0

-- ITEM & BOSS STATES
local flashlightBattery = 420
local ecstasyActive     = false
local ecstasyEndTime    = 0
local snowWhiteActive   = false
local snowWhitePart     = nil
local lockerTime        = 0
local speedPenaltyEnd   = 0

-- FOOTSTEP STATES
local floorStepSound    = nil
local grassStepSound    = nil
local lastStepTime      = 0

-- ===== HARD MODE STATE =====
local hardModeStarted     = false
local hardModeTimerActive = false
local hardModeTimeLeft    = HARD_MODE_TIME
local hardModeMusic       = nil

-- ===== FORWARD DECLARATIONS =====
local setupLighting, createHUD, makePart, makeLight, makeTableDecor
local makePlant, makeDrawerTable, makeBed, makeLocker, makeVineDecor
local generateRoom, createLobby, startGame, showWarning, hideInLocker
local exitLocker, spawnPlantera, spawnDisease, spawnStem, spawnMalware
local spawnHer, spawnSnowWhite, spawnVoid, onDoorReached, onDeath, updateCharRef, mainLoop

-- ===== GUI REFS =====
local screenGui, doorLabel, coinLabel, warningFrame, warningLabel
local hidePrompt, hideBtnLabel, stemEyeContainer, stemEyeOuter, stemEyeStroke
local stemIris, stemPupil, stemTopLid, stemBottomLid, stemSound
local batteryGui, batteryFill, freezeOverlay
local timerLabel, hardModeBadge  -- HARD MODE HUD elements

-- =================================================================
-- LIGHTING
-- =================================================================
setupLighting = function()
    local L = game:GetService("Lighting")
    L.Brightness     = 0.15
    L.ClockTime      = 0
    L.FogColor       = Color3.fromRGB(0, 0, 0)
    L.FogEnd         = 55
    L.FogStart       = 5
    L.GlobalShadows  = true
    L.Ambient        = Color3.fromRGB(8, 8, 15)
    L.OutdoorAmbient = Color3.fromRGB(5, 5, 10)
end

-- =================================================================
-- HUD
-- =================================================================
createHUD = function()
    if player.PlayerGui:FindFirstChild("GameHUD") then
        player.PlayerGui.GameHUD:Destroy()
    end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player.PlayerGui

    freezeOverlay = Instance.new("Frame")
    freezeOverlay.Name = "FreezeOverlay"
    freezeOverlay.Size = UDim2.new(1, 0, 1, 0)
    freezeOverlay.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    freezeOverlay.BackgroundTransparency = 1
    freezeOverlay.BorderSizePixel = 0
    freezeOverlay.ZIndex = 100
    freezeOverlay.Parent = screenGui

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(0, 190, 0, 46)
    topBar.Position = UDim2.new(0.5, -95, 0, 12)
    topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    topBar.BackgroundTransparency = 0.42
    topBar.BorderSizePixel = 0
    topBar.Parent = screenGui
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 10)
    tc.Parent = topBar

    doorLabel = Instance.new("TextLabel")
    doorLabel.Size = UDim2.new(1, 0, 1, 0)
    doorLabel.BackgroundTransparency = 1
    doorLabel.Text = "Door: 0"
    doorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    doorLabel.TextScaled = true
    doorLabel.Font = Enum.Font.GothamBold
    doorLabel.Parent = topBar

    local coinBar = Instance.new("Frame")
    coinBar.Size = UDim2.new(0, 130, 0, 40)
    coinBar.Position = UDim2.new(0, 14, 0, 12)
    coinBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    coinBar.BackgroundTransparency = 0.42
    coinBar.BorderSizePixel = 0
    coinBar.Parent = screenGui
    local coinCorner = Instance.new("UICorner")
    coinCorner.CornerRadius = UDim.new(0, 10)
    coinCorner.Parent = coinBar

    local coinIcon = Instance.new("Frame")
    coinIcon.Size = UDim2.new(0, 22, 0, 22)
    coinIcon.Position = UDim2.new(0, 8, 0.5, -11)
    coinIcon.BackgroundColor3 = Color3.fromRGB(255, 210, 0)
    coinIcon.BorderSizePixel = 0
    coinIcon.ZIndex = 2
    coinIcon.Parent = coinBar
    local ciCorner = Instance.new("UICorner")
    ciCorner.CornerRadius = UDim.new(1, 0)
    ciCorner.Parent = coinIcon

    coinLabel = Instance.new("TextLabel")
    coinLabel.Size = UDim2.new(1, -38, 1, 0)
    coinLabel.Position = UDim2.new(0, 36, 0, 0)
    coinLabel.BackgroundTransparency = 1
    coinLabel.Text = "0 Coins"
    coinLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
    coinLabel.TextScaled = true
    coinLabel.Font = Enum.Font.GothamBold
    coinLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinLabel.Parent = coinBar

    warningFrame = Instance.new("Frame")
    warningFrame.Name = "WarningFrame"
    warningFrame.Size = UDim2.new(1, 0, 0, 72)
    warningFrame.Position = UDim2.new(0, 0, 0.13, 0)
    warningFrame.BackgroundColor3 = Color3.fromRGB(8, 55, 8)
    warningFrame.BackgroundTransparency = 0.2
    warningFrame.BorderSizePixel = 0
    warningFrame.Visible = false
    warningFrame.Parent = screenGui

    warningLabel = Instance.new("TextLabel")
    warningLabel.Size = UDim2.new(1, -24, 1, 0)
    warningLabel.Position = UDim2.new(0, 12, 0, 0)
    warningLabel.BackgroundTransparency = 1
    warningLabel.Text = ""
    warningLabel.TextColor3 = Color3.fromRGB(70, 255, 70)
    warningLabel.TextScaled = true
    warningLabel.Font = Enum.Font.GothamBold
    warningLabel.TextWrapped = true
    warningLabel.Parent = warningFrame

    hidePrompt = Instance.new("Frame")
    hidePrompt.Name = "HidePrompt"
    hidePrompt.Size = UDim2.new(0, 240, 0, 58)
    hidePrompt.Position = UDim2.new(0.5, -120, 0.82, 0)
    hidePrompt.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    hidePrompt.BackgroundTransparency = 0.3
    hidePrompt.BorderSizePixel = 0
    hidePrompt.Visible = false
    hidePrompt.Parent = screenGui
    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 12)
    hc.Parent = hidePrompt

    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(1, 0, 1, 0)
    hideBtn.BackgroundTransparency = 1
    hideBtn.TextColor3 = Color3.fromRGB(255, 255, 80)
    hideBtn.TextScaled = true
    hideBtn.Font = Enum.Font.GothamBold
    hideBtn.Text = "[HIDE]"
    hideBtn.Parent = hidePrompt
    hideBtnLabel = hideBtn

    hideBtn.MouseButton1Click:Connect(function()
        if not isHiding then hideInLocker() else exitLocker() end
    end)

    batteryGui = Instance.new("Frame")
    batteryGui.Name = "BatteryBar"
    batteryGui.Size = UDim2.new(0, 180, 0, 12)
    batteryGui.Position = UDim2.new(0.5, -90, 1, -140)
    batteryGui.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    batteryGui.BorderSizePixel = 2
    batteryGui.Visible = false
    batteryGui.Parent = screenGui

    batteryFill = Instance.new("Frame")
    batteryFill.Size = UDim2.new(1, 0, 1, 0)
    batteryFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
    batteryFill.BorderSizePixel = 0
    batteryFill.Parent = batteryGui

    -- ===== HARD MODE HUD ELEMENTS =====
    if HARD_MODE then
        -- HARD MODE Badge (top right)
        hardModeBadge = Instance.new("Frame")
        hardModeBadge.Size = UDim2.new(0, 160, 0, 40)
        hardModeBadge.Position = UDim2.new(1, -174, 0, 12)
        hardModeBadge.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        hardModeBadge.BackgroundTransparency = 0.2
        hardModeBadge.BorderSizePixel = 0
        hardModeBadge.Parent = screenGui
        local hmCorner = Instance.new("UICorner")
        hmCorner.CornerRadius = UDim.new(0, 10)
        hmCorner.Parent = hardModeBadge
        local hmStroke = Instance.new("UIStroke")
        hmStroke.Color = Color3.fromRGB(255, 60, 60)
        hmStroke.Thickness = 2
        hmStroke.Parent = hardModeBadge
        local hmLabel = Instance.new("TextLabel")
        hmLabel.Size = UDim2.new(1, 0, 1, 0)
        hmLabel.BackgroundTransparency = 1
        hmLabel.Text = "HARD MODE"
        hmLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
        hmLabel.TextScaled = true
        hmLabel.Font = Enum.Font.GothamBold
        hmLabel.Parent = hardModeBadge

        -- Timer Bar
        local timerBar = Instance.new("Frame")
        timerBar.Size = UDim2.new(0, 160, 0, 46)
        timerBar.Position = UDim2.new(1, -174, 0, 60)
        timerBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        timerBar.BackgroundTransparency = 0.42
        timerBar.BorderSizePixel = 0
        timerBar.Parent = screenGui
        local tbCorner = Instance.new("UICorner")
        tbCorner.CornerRadius = UDim.new(0, 10)
        tbCorner.Parent = timerBar

        timerLabel = Instance.new("TextLabel")
        timerLabel.Size = UDim2.new(1, 0, 1, 0)
        timerLabel.BackgroundTransparency = 1
        timerLabel.Text = "5:00"
        timerLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
        timerLabel.TextScaled = true
        timerLabel.Font = Enum.Font.GothamBold
        timerLabel.Parent = timerBar

        -- Goal label (reach door 100)
        local goalBar = Instance.new("Frame")
        goalBar.Size = UDim2.new(0, 160, 0, 32)
        goalBar.Position = UDim2.new(1, -174, 0, 114)
        goalBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        goalBar.BackgroundTransparency = 0.55
        goalBar.BorderSizePixel = 0
        goalBar.Parent = screenGui
        local gbCorner = Instance.new("UICorner")
        gbCorner.CornerRadius = UDim.new(0, 8)
        gbCorner.Parent = goalBar
        local goalLabel = Instance.new("TextLabel")
        goalLabel.Size = UDim2.new(1, 0, 1, 0)
        goalLabel.BackgroundTransparency = 1
        goalLabel.Text = "Goal: Door 100"
        goalLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        goalLabel.TextScaled = true
        goalLabel.Font = Enum.Font.Gotham
        goalLabel.Parent = goalBar
    end
    -- ===== END HARD MODE HUD =====

    stemEyeContainer = Instance.new("Frame")
    stemEyeContainer.Name = "StemEyeContainer"
    stemEyeContainer.Size = UDim2.new(0, 240, 0, 120)
    stemEyeContainer.Position = UDim2.new(0.5, -120, 0.16, 0)
    stemEyeContainer.BackgroundTransparency = 1
    stemEyeContainer.Visible = false
    stemEyeContainer.ZIndex = 10
    stemEyeContainer.Parent = screenGui

    stemEyeOuter = Instance.new("Frame")
    stemEyeOuter.Name = "EyeOuter"
    stemEyeOuter.Size = UDim2.new(1, 0, 1, 0)
    stemEyeOuter.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    stemEyeOuter.BorderSizePixel = 0
    stemEyeOuter.ClipsDescendants = true
    stemEyeOuter.ZIndex = 10
    stemEyeOuter.Parent = stemEyeContainer
    local outerCorner = Instance.new("UICorner")
    outerCorner.CornerRadius = UDim.new(1, 0)
    outerCorner.Parent = stemEyeOuter

    stemEyeStroke = Instance.new("UIStroke")
    stemEyeStroke.Color = Color3.fromRGB(0, 255, 60)
    stemEyeStroke.Thickness = 5
    stemEyeStroke.Transparency = 0
    stemEyeStroke.Parent = stemEyeOuter

    stemIris = Instance.new("Frame")
    stemIris.Name = "Iris"
    stemIris.Size = UDim2.new(0, 90, 0, 90)
    stemIris.Position = UDim2.new(0.5, -45, 0.5, -45)
    stemIris.BackgroundColor3 = Color3.fromRGB(0, 185, 0)
    stemIris.BorderSizePixel = 0
    stemIris.ZIndex = 11
    stemIris.Parent = stemEyeOuter
    local irisCorner = Instance.new("UICorner")
    irisCorner.CornerRadius = UDim.new(1, 0)
    irisCorner.Parent = stemIris

    local irisRing = Instance.new("Frame")
    irisRing.Name = "IrisRing"
    irisRing.Size = UDim2.new(0, 72, 0, 72)
    irisRing.Position = UDim2.new(0.5, -36, 0.5, -36)
    irisRing.BackgroundColor3 = Color3.fromRGB(0, 225, 0)
    irisRing.BorderSizePixel = 0
    irisRing.ZIndex = 12
    irisRing.Parent = stemIris
    local irisRingCorner = Instance.new("UICorner")
    irisRingCorner.CornerRadius = UDim.new(1, 0)
    irisRingCorner.Parent = irisRing

    stemPupil = Instance.new("Frame")
    stemPupil.Name = "Pupil"
    stemPupil.Size = UDim2.new(0, 38, 0, 38)
    stemPupil.Position = UDim2.new(0.5, -19, 0.5, -19)
    stemPupil.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    stemPupil.BorderSizePixel = 0
    stemPupil.ZIndex = 13
    stemPupil.Parent = irisRing
    local pupilCorner = Instance.new("UICorner")
    pupilCorner.CornerRadius = UDim.new(1, 0)
    pupilCorner.Parent = stemPupil

    local highlight = Instance.new("Frame")
    highlight.Name = "Highlight"
    highlight.Size = UDim2.new(0, 10, 0, 10)
    highlight.Position = UDim2.new(0.58, 0, 0.08, 0)
    highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    highlight.BorderSizePixel = 0
    highlight.ZIndex = 14
    highlight.Parent = stemPupil
    local hlCorner = Instance.new("UICorner")
    hlCorner.CornerRadius = UDim.new(1, 0)
    hlCorner.Parent = highlight

    stemTopLid = Instance.new("Frame")
    stemTopLid.Name = "TopLid"
    stemTopLid.Size = UDim2.new(1, 0, 0.5, 2)
    stemTopLid.Position = UDim2.new(0, 0, 0, 0)
    stemTopLid.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    stemTopLid.BorderSizePixel = 0
    stemTopLid.ZIndex = 15
    stemTopLid.Parent = stemEyeOuter

    local topLash = Instance.new("Frame")
    topLash.Size = UDim2.new(1, 0, 0, 6)
    topLash.Position = UDim2.new(0, 0, 1, -6)
    topLash.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
    topLash.BorderSizePixel = 0
    topLash.ZIndex = 16
    topLash.Parent = stemTopLid
    local tlCorner = Instance.new("UICorner")
    tlCorner.CornerRadius = UDim.new(0, 4)
    tlCorner.Parent = topLash

    stemBottomLid = Instance.new("Frame")
    stemBottomLid.Name = "BottomLid"
    stemBottomLid.Size = UDim2.new(1, 0, 0.5, 2)
    stemBottomLid.Position = UDim2.new(0, 0, 0.5, -2)
    stemBottomLid.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    stemBottomLid.BorderSizePixel = 0
    stemBottomLid.ZIndex = 15
    stemBottomLid.Parent = stemEyeOuter

    local botLash = Instance.new("Frame")
    botLash.Size = UDim2.new(1, 0, 0, 6)
    botLash.Position = UDim2.new(0, 0, 0, 0)
    botLash.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
    botLash.BorderSizePixel = 0
    botLash.ZIndex = 16
    botLash.Parent = stemBottomLid
    local blCorner = Instance.new("UICorner")
    blCorner.CornerRadius = UDim.new(0, 4)
    blCorner.Parent = botLash

    stemSound = Instance.new("Sound")
    stemSound.Name = "StemSound"
    stemSound.Parent = screenGui
end

-- =================================================================
-- PART HELPERS
-- =================================================================
makePart = function(size, cf, color, transparency, parent, material)
    local p = Instance.new("Part")
    p.Size = size
    p.CFrame = cf
    p.Color = color or Color3.fromRGB(50, 50, 60)
    p.Transparency = transparency or 0
    p.Anchored = true
    p.CanCollide = true
    p.CastShadow = false
    p.Material = material or Enum.Material.SmoothPlastic
    p.Parent = parent or workspace
    return p
end

makeLight = function(parent, brightness, range, color)
    local l = Instance.new("PointLight")
    l.Brightness = brightness or 2
    l.Range = range or 28
    l.Color = color or Color3.fromRGB(255, 240, 200)
    l.Parent = parent
    return l
end

-- =================================================================
-- DECORATIONS
-- =================================================================
makeTableDecor = function(folder, pos)
    local top = makePart(Vector3.new(5, 0.8, 3), CFrame.new(pos + Vector3.new(0, 3.2, 0)), Color3.fromRGB(110, 75, 40), 0, folder)
    top.Name = "TableTop"
    local legOff = {Vector3.new(2, 1.6, 1), Vector3.new(-2, 1.6, 1), Vector3.new(2, 1.6, -1), Vector3.new(-2, 1.6, -1)}
    for _, o in ipairs(legOff) do
        makePart(Vector3.new(0.3, 3.2, 0.3), CFrame.new(pos + o), Color3.fromRGB(85, 58, 28), 0, folder).Name = "TableLeg"
    end
end

makePlant = function(folder, pos)
    makePart(Vector3.new(1.5, 1.8, 1.5), CFrame.new(pos + Vector3.new(0, 0.9, 0)), Color3.fromRGB(130, 85, 55), 0, folder).Name = "PlantPot"
    local bush = Instance.new("Part")
    bush.Shape = Enum.PartType.Ball
    bush.Size = Vector3.new(2.8, 2.8, 2.8)
    bush.CFrame = CFrame.new(pos + Vector3.new(0, 2.9, 0))
    bush.Color = Color3.fromRGB(28, 108, 28)
    bush.Anchored = true
    bush.CanCollide = false
    bush.Material = Enum.Material.Grass
    bush.Parent = folder
    bush.Name = "PlantBush"
end

makeDrawerTable = function(folder, pos, roomDrawersList)
    local numDrawers = math.random(1, 5)
    makePart(Vector3.new(4, 5, 2.5), CFrame.new(pos + Vector3.new(0, 2.5, 0)), Color3.fromRGB(95, 68, 38), 0, folder).Name = "DrawerBody"
    local slotH = 4 / numDrawers
    for i = 1, numDrawers do
        local dY = (i - 1) * slotH - 1.8 + slotH * 0.5
        local drawer = makePart(Vector3.new(3.5, slotH - 0.15, 0.15), CFrame.new(pos + Vector3.new(0, 2.5 + dY, -1.33)), Color3.fromRGB(80, 55, 28), 0, folder)
        drawer.Name = "Drawer"
        makePart(Vector3.new(0.7, 0.25, 0.35), CFrame.new(pos + Vector3.new(0, 2.5 + dY, -1.52)), Color3.fromRGB(210, 185, 100), 0, folder).Name = "DrawerHandle"
        if roomDrawersList then table.insert(roomDrawersList, drawer) end
    end
end

makeBed = function(folder, pos, rotY)
    local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY or 0), 0)
    makePart(Vector3.new(4.5, 1, 7.5), cf * CFrame.new(0, 0.5, 0), Color3.fromRGB(75, 55, 35), 0, folder).Name = "BedFrame"
    makePart(Vector3.new(4, 0.9, 7), cf * CFrame.new(0, 1.45, 0), Color3.fromRGB(210, 210, 225), 0, folder).Name = "Mattress"
    makePart(Vector3.new(3.2, 0.5, 1.8), cf * CFrame.new(0, 2, -2.6), Color3.fromRGB(245, 245, 255), 0, folder).Name = "Pillow"
    makePart(Vector3.new(4.5, 3.5, 0.4), cf * CFrame.new(0, 2.2, -3.8), Color3.fromRGB(65, 45, 28), 0, folder).Name = "Headboard"
end

makeLocker = function(folder, pos)
    local body = makePart(Vector3.new(2.5, 6.5, 2), CFrame.new(pos + Vector3.new(0, 3.25, 0)), Color3.fromRGB(50, 72, 100), 0, folder, Enum.Material.Metal)
    body.Name = "LockerBody"
    body:SetAttribute("IsLocker", true)
    makePart(Vector3.new(0.08, 6.1, 1.7), CFrame.new(pos + Vector3.new(-1.21, 3.25, 0)), Color3.fromRGB(40, 60, 88), 0, folder, Enum.Material.Metal).Name = "LockerDoorLine"
    makePart(Vector3.new(0.2, 0.9, 0.32), CFrame.new(pos + Vector3.new(-1.32, 3.4, 0.5)), Color3.fromRGB(200, 175, 95), 0, folder).Name = "LockerHandle"
    for i = 1, 3 do
        makePart(Vector3.new(1.8, 0.14, 0.08), CFrame.new(pos + Vector3.new(-0.3, 5.5 - i * 0.4, -1.01)), Color3.fromRGB(38, 55, 78), 0, folder).Name = "LockerVent"
    end
    return body
end

makeVineDecor = function(folder, roomOrigin, heavy)
    local count = heavy and math.random(25, 40) or math.random(6, 11)
    for i = 1, count do
        local isFloorVine = (math.random(1, 3) == 1)
        local vineLen = math.random(4, 10)
        local vineCF

        if isFloorVine then
            vineCF = CFrame.new(roomOrigin + Vector3.new(math.random(-ROOM_W*0.4, ROOM_W*0.4), -0.4, math.random(-ROOM_D*0.4, ROOM_D*0.4))) * CFrame.Angles(0, math.rad(math.random(0,360)), math.rad(90))
        else
            local side = math.random(1, 4)
            local offset = math.random(-12, 12)
            local yOff = math.random(1, ROOM_H - 2)
            if side == 1 then
                vineCF = CFrame.new(roomOrigin + Vector3.new(offset, yOff, ROOM_D * 0.5 - 0.3))
            elseif side == 2 then
                vineCF = CFrame.new(roomOrigin + Vector3.new(offset, yOff, -ROOM_D * 0.5 + 0.3))
            elseif side == 3 then
                vineCF = CFrame.new(roomOrigin + Vector3.new(ROOM_W * 0.5 - 0.3, yOff, offset))
            else
                vineCF = CFrame.new(roomOrigin + Vector3.new(-ROOM_W * 0.5 + 0.3, yOff, offset))
            end
        end

        local vine = makePart(Vector3.new(0.35, vineLen, 0.35), vineCF, Color3.fromRGB(22, 115, 22), 0.1, folder, Enum.Material.Grass)
        vine.Name = "Vine"
        vine.CanCollide = false
    end
end

-- =================================================================
-- ROOM GENERATION
-- =================================================================
generateRoom = function(doorNum)
    if rooms[doorNum] then return end

    local folder = Instance.new("Folder")
    folder.Name = "Room_" .. doorNum
    folder.Parent = workspace

    local originZ = -(doorNum * ROOM_D)
    local O = Vector3.new(0, 0, originZ)
    local roomDrawers = {}

    -- HARD MODE: garden from door 0, normal: garden after GARDEN_START
    local isGarden
    if HARD_MODE then
        isGarden = (math.random(1, 100) <= HARD_GARDEN_CHANCE)
    else
        isGarden = (doorNum >= GARDEN_START) and (math.random(1, 100) <= GARDEN_CHANCE)
    end

    -- HARD MODE: no locked rooms
    local isLocked = (not HARD_MODE) and (math.random(1, 100) <= 40)

    local isDark   = math.random(1, 100) <= 38
    roomIsDark[doorNum] = isDark

    local isLeft   = not isGarden and (math.random(1, 100) <= 55)
    local isRight  = not isGarden and (math.random(1, 100) <= 55)

    local isIceRoom = (doorNum >= SNOW_WHITE_DOOR and doorNum < SNOW_WHITE_END)
    local floorMat  = isIceRoom and Enum.Material.Ice or Enum.Material.SmoothPlastic
    local wallMat   = isIceRoom and Enum.Material.Ice or Enum.Material.SmoothPlastic

    local floorColor   = isIceRoom and Color3.fromRGB(150, 240, 255) or Color3.fromRGB(36, 36, 46)
    local ceilingColor = isIceRoom and Color3.fromRGB(120, 220, 255) or Color3.fromRGB(30, 30, 40)
    local wallColor    = isIceRoom and Color3.fromRGB(130, 230, 255) or Color3.fromRGB(40, 40, 52)

    local bwSideW = (ROOM_W - 5) * 0.5

    if isGarden then
        makePart(Vector3.new(ROOM_W * 3, 1, ROOM_D), CFrame.new(O + Vector3.new(0, -0.5, 0)), Color3.fromRGB(34, 139, 34), 0, folder, Enum.Material.Grass).Name = "GardenGrass"
        makePart(Vector3.new(10, 1.05, ROOM_D), CFrame.new(O + Vector3.new(0, -0.45, 0)), Color3.fromRGB(100, 100, 100), 0, folder, Enum.Material.Cobblestone).Name = "HallwayPath"
        makePart(Vector3.new(10, 1, ROOM_D), CFrame.new(O + Vector3.new(0, ROOM_H + 0.5, 0)), ceilingColor, 0, folder, wallMat).Name = "HallwayCeiling"

        for z = -ROOM_D*0.45, ROOM_D*0.45, 12 do
            makePart(Vector3.new(1, ROOM_H, 1), CFrame.new(O + Vector3.new(-4.5, ROOM_H * 0.5, z)), wallColor, 0, folder, wallMat).Name = "PillarL"
            makePart(Vector3.new(1, ROOM_H, 1), CFrame.new(O + Vector3.new(4.5, ROOM_H * 0.5, z)), wallColor, 0, folder, wallMat).Name = "PillarR"
        end

        makePart(Vector3.new(ROOM_W * 3, ROOM_H, 1), CFrame.new(O + Vector3.new(0, ROOM_H * 0.5, ROOM_D * 0.5)), wallColor, 0, folder, wallMat).Name = "BackWall"
        makePart(Vector3.new(ROOM_W * 3, ROOM_H, 1), CFrame.new(O + Vector3.new(0, ROOM_H * 0.5, -ROOM_D * 0.5)), wallColor, 0, folder, wallMat).Name = "FrontWall"
        makePart(Vector3.new(1, ROOM_H, ROOM_D), CFrame.new(O + Vector3.new(-ROOM_W * 1.5, ROOM_H * 0.5, 0)), wallColor, 0, folder, wallMat).Name = "BoundaryL"
        makePart(Vector3.new(1, ROOM_H, ROOM_D), CFrame.new(O + Vector3.new(ROOM_W * 1.5, ROOM_H * 0.5, 0)), wallColor, 0, folder, wallMat).Name = "BoundaryR"

        makePart(Vector3.new(5.5, 0.4, 0.5), CFrame.new(O + Vector3.new(0, 7.2, -ROOM_D * 0.5)), Color3.fromRGB(60, 40, 20), 0, folder).Name = "DoorFrameTop"
        makePart(Vector3.new(0.4, 7.2, 0.5), CFrame.new(O + Vector3.new(-2.75, 3.6, -ROOM_D * 0.5)), Color3.fromRGB(60, 40, 20), 0, folder).Name = "DoorFrameL"
        makePart(Vector3.new(0.4, 7.2, 0.5), CFrame.new(O + Vector3.new(2.75, 3.6, -ROOM_D * 0.5)), Color3.fromRGB(60, 40, 20), 0, folder).Name = "DoorFrameR"
    else
        local floor = makePart(Vector3.new(ROOM_W, 1, ROOM_D), CFrame.new(O + Vector3.new(0, -0.5, 0)), floorColor, 0, folder, floorMat)
        floor.Name = "Floor"
        if isIceRoom then
            floor.CustomPhysicalProperties = PhysicalProperties.new(0.05, 0.05, 0.5, 1, 1)
        end
        makePart(Vector3.new(ROOM_W, 1, ROOM_D), CFrame.new(O + Vector3.new(0, ROOM_H + 0.5, 0)), ceilingColor, 0, folder, wallMat).Name = "Ceiling"
        makePart(Vector3.new(1, ROOM_H, ROOM_D), CFrame.new(O + Vector3.new(-ROOM_W * 0.5 - 0.5, ROOM_H * 0.5, 0)), wallColor, 0, folder, wallMat).Name = "WallLeft"
        makePart(Vector3.new(1, ROOM_H, ROOM_D), CFrame.new(O + Vector3.new(ROOM_W * 0.5 + 0.5, ROOM_H * 0.5, 0)), wallColor, 0, folder, wallMat).Name = "WallRight"

        makePart(Vector3.new(bwSideW, ROOM_H, 1), CFrame.new(O + Vector3.new(-(ROOM_W + 5) * 0.25, ROOM_H * 0.5, ROOM_D * 0.5)), wallColor, 0, folder, wallMat).Name = "BackWallL"
        makePart(Vector3.new(bwSideW, ROOM_H, 1), CFrame.new(O + Vector3.new((ROOM_W + 5) * 0.25, ROOM_H * 0.5, ROOM_D * 0.5)), wallColor, 0, folder, wallMat).Name = "BackWallR"
        makePart(Vector3.new(5, ROOM_H - 7, 1), CFrame.new(O + Vector3.new(0, ROOM_H - (ROOM_H - 7) * 0.5, ROOM_D * 0.5)), wallColor, 0, folder, wallMat).Name = "BackWallTop"

        if isLeft and not isRight then
            makePart(Vector3.new(ROOM_W * 0.65, ROOM_H, 2), CFrame.new(O + Vector3.new(ROOM_W * 0.175, ROOM_H * 0.5, -ROOM_D * 0.3)), wallColor, 0, folder, wallMat)
            makePart(Vector3.new(ROOM_W * 0.65, ROOM_H, 2), CFrame.new(O + Vector3.new(-ROOM_W * 0.175, ROOM_H * 0.5, -ROOM_D * 0.7)), wallColor, 0, folder, wallMat)
        elseif isRight and not isLeft then
            makePart(Vector3.new(ROOM_W * 0.65, ROOM_H, 2), CFrame.new(O + Vector3.new(-ROOM_W * 0.175, ROOM_H * 0.5, -ROOM_D * 0.3)), wallColor, 0, folder, wallMat)
            makePart(Vector3.new(ROOM_W * 0.65, ROOM_H, 2), CFrame.new(O + Vector3.new(ROOM_W * 0.175, ROOM_H * 0.5, -ROOM_D * 0.7)), wallColor, 0, folder, wallMat)
        elseif isLeft and isRight then
            makePart(Vector3.new(ROOM_W * 0.3, ROOM_H, ROOM_D * 0.6), CFrame.new(O + Vector3.new(0, ROOM_H * 0.5, -ROOM_D * 0.5)), wallColor, 0, folder, wallMat)
        else
            makePart(Vector3.new(bwSideW, ROOM_H, 1), CFrame.new(O + Vector3.new(-(ROOM_W + 5) * 0.25, ROOM_H * 0.5, -ROOM_D * 0.5)), wallColor, 0, folder, wallMat).Name = "FrontWallL"
            makePart(Vector3.new(bwSideW, ROOM_H, 1), CFrame.new(O + Vector3.new((ROOM_W + 5) * 0.25, ROOM_H * 0.5, -ROOM_D * 0.5)), wallColor, 0, folder, wallMat).Name = "FrontWallR"
            makePart(Vector3.new(5, ROOM_H - 7, 1), CFrame.new(O + Vector3.new(0, ROOM_H - (ROOM_H - 7) * 0.5, -ROOM_D * 0.5)), wallColor, 0, folder, wallMat).Name = "FrontWallTop"
            makePart(Vector3.new(5.5, 0.4, 0.5), CFrame.new(O + Vector3.new(0, 7.2, -ROOM_D * 0.5)), Color3.fromRGB(60, 40, 20), 0, folder).Name = "DoorFrameTop"
            makePart(Vector3.new(0.4, 7.2, 0.5), CFrame.new(O + Vector3.new(-2.75, 3.6, -ROOM_D * 0.5)), Color3.fromRGB(60, 40, 20), 0, folder).Name = "DoorFrameL"
            makePart(Vector3.new(0.4, 7.2, 0.5), CFrame.new(O + Vector3.new(2.75, 3.6, -ROOM_D * 0.5)), Color3.fromRGB(60, 40, 20), 0, folder).Name = "DoorFrameR"
        end
    end

    -- isLocked is always false in HARD_MODE, so this block is skipped in hard mode
    local doorsToUnlock = {}
    if isLocked then
        if isGarden then
            local vineDoor = makePart(Vector3.new(6.5, 8.2, 1), CFrame.new(O + Vector3.new(0, 4.1, -ROOM_D * 0.5)), Color3.fromRGB(22, 115, 22), 0, folder, Enum.Material.Grass)
            vineDoor.Name = "LockedVines"
            table.insert(doorsToUnlock, vineDoor)
        else
            if isLeft and isRight then
                local doorL = makePart(Vector3.new(ROOM_W * 0.35, ROOM_H, 1), CFrame.new(O + Vector3.new(-ROOM_W * 0.325, ROOM_H * 0.5, -ROOM_D * 0.5)), Color3.fromRGB(70, 30, 30), 0, folder)
                local doorR = makePart(Vector3.new(ROOM_W * 0.35, ROOM_H, 1), CFrame.new(O + Vector3.new(ROOM_W * 0.325, ROOM_H * 0.5, -ROOM_D * 0.5)), Color3.fromRGB(70, 30, 30), 0, folder)
                table.insert(doorsToUnlock, doorL)
                table.insert(doorsToUnlock, doorR)
            else
                local lockedDoor = makePart(Vector3.new(6.5, 8.2, 1), CFrame.new(O + Vector3.new(0, 4.1, -ROOM_D * 0.5)), Color3.fromRGB(70, 30, 30), 0, folder)
                lockedDoor.Name = "LockedDoor"
                table.insert(doorsToUnlock, lockedDoor)
            end
        end

        for _, d in ipairs(doorsToUnlock) do
            local prompt = Instance.new("ProximityPrompt")
            prompt.ActionText = isGarden and "Cut Vines" or "Unlock"
            prompt.RequiresLineOfSight = false
            prompt.Parent = d
            prompt.Triggered:Connect(function()
                local char = player.Character
                if isGarden then
                    if char and char:FindFirstChild("Lopper") then
                        char.Lopper:Destroy()
                        d:Destroy()
                        for i, v in ipairs(inventory) do
                            if v == "Lopper" then table.remove(inventory, i) break end
                        end
                    else
                        showWarning("You need to hold a Lopper to cut this!", 2)
                    end
                else
                    if char and char:FindFirstChild("Key") then
                        char.Key:Destroy()
                        d:Destroy()
                        for i, v in ipairs(inventory) do
                            if v == "Key" then table.remove(inventory, i) break end
                        end
                    else
                        showWarning("You need to hold a Key to unlock this!", 2)
                    end
                end
            end)
        end
    end

    local signPart = makePart(Vector3.new(4, 1.5, 0.3), CFrame.new(O + Vector3.new(0, 8.6, -ROOM_D * 0.5 + 0.2)), Color3.fromRGB(18, 18, 22), 0, folder)
    signPart.Name = "DoorSign"
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = signPart
    local signLabel = Instance.new("TextLabel")
    signLabel.Size = UDim2.new(1, 0, 1, 0)
    signLabel.BackgroundTransparency = 1
    signLabel.Text = tostring(doorNum + 1)
    signLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    signLabel.TextScaled = true
    signLabel.Font = Enum.Font.GothamBold
    signLabel.Parent = signGui

    if not isDark then
        local lightY = ROOM_H - 0.6
        local hlx = isGarden and 3 or 8
        local lightPos = {Vector3.new(-hlx, lightY, -12), Vector3.new(hlx, lightY, -12), Vector3.new(-hlx, lightY, 12), Vector3.new(hlx, lightY, 12)}
        for _, lp in ipairs(lightPos) do
            local bulb = makePart(Vector3.new(1.2, 0.4, 1.2), CFrame.new(O + lp), Color3.fromRGB(255, 255, 220), 0, folder)
            bulb.Name = "LightBulb"
            makeLight(bulb, 1.8, 26, isIceRoom and Color3.fromRGB(200, 255, 255) or Color3.fromRGB(255, 238, 180))
            makePart(Vector3.new(0.1, 0.6, 0.1), CFrame.new(O + lp + Vector3.new(0, 0.5, 0)), Color3.fromRGB(30, 30, 30), 0, folder).Name = "LightWire"
        end
    end

    if doorNum > 0 and doorNum % CHECKPOINT_EVERY == 0 then
        local cpPart = makePart(Vector3.new(8, 2.2, 0.4), CFrame.new(O + Vector3.new(0, 6, 0)), Color3.fromRGB(10, 85, 10), 0, folder, Enum.Material.Neon)
        cpPart.Name = "CheckpointSign"
        local cpGui = Instance.new("SurfaceGui")
        cpGui.Face = Enum.NormalId.Front
        cpGui.Parent = cpPart
        local cpLabel2 = Instance.new("TextLabel")
        cpLabel2.Size = UDim2.new(1, 0, 1, 0)
        cpLabel2.BackgroundTransparency = 1
        cpLabel2.Text = "CHECKPOINT  -  Door " .. doorNum
        cpLabel2.TextColor3 = Color3.fromRGB(100, 255, 100)
        cpLabel2.TextScaled = true
        cpLabel2.Font = Enum.Font.GothamBold
        cpLabel2.Parent = cpGui
    end

    if isGarden then
        local bushes = {}
        for i = 1, 12 do
            local bx = (math.random(1, 2) == 1 and 1 or -1) * math.random(10, 35)
            local bz = math.random(-ROOM_D*0.45, ROOM_D*0.45)
            local bush = makePart(Vector3.new(4, 4, 4), CFrame.new(O + Vector3.new(bx, 1.5, bz)), Color3.fromRGB(34, 139, 34), 0, folder, Enum.Material.Grass)
            bush.Shape = Enum.PartType.Ball
            bush.Name = "SunflowerBush"
            table.insert(bushes, bush)
        end
        for i = 1, 3 do
            if bushes[i] then bushes[i]:SetAttribute("IsLocker", true) end
        end

        if not isDark then
            for i = 1, 4 do
                local lx = (i % 2 == 0 and 1 or -1) * math.random(10, 20)
                local lz = math.random(-ROOM_D*0.4, ROOM_D*0.4)
                local post = makePart(Vector3.new(0.5, 9, 0.5), CFrame.new(O + Vector3.new(lx, 4.5, lz)), Color3.fromRGB(20, 20, 20), 0, folder)
                local bulb = makePart(Vector3.new(1.5, 1.5, 1.5), CFrame.new(O + Vector3.new(lx, 9, lz)), Color3.fromRGB(255, 255, 200), 0, folder, Enum.Material.Neon)
                makeLight(bulb, 2, 45, Color3.fromRGB(255, 255, 200))
            end
        end

        -- Garden lopper only in non-hard mode (no locked rooms in hard mode)
        if isLocked then
            local lopper = makePart(Vector3.new(2, 0.2, 0.6), CFrame.new(O + Vector3.new(math.random(-25, 25), 0.6, math.random(-15, 15))), Color3.fromRGB(150, 150, 150), 0, folder, Enum.Material.Metal)
            lopper.Name = "Lopper"
            local lp = Instance.new("ProximityPrompt", lopper)
            lp.ActionText = "Take Lopper"
            lp.Triggered:Connect(function(plr)
                if #inventory >= MAX_ITEMS then showWarning("Inventory full! Max 3 items.", 2) return end
                lp:Destroy()
                table.insert(inventory, "Lopper")
                local tool = Instance.new("Tool")
                tool.Name = "Lopper"
                local handle = Instance.new("Part")
                handle.Name = "Handle"
                handle.Size = Vector3.new(2, 0.2, 0.6)
                handle.Color = Color3.fromRGB(150, 150, 150)
                handle.Parent = tool
                tool.Parent = plr.Backpack
                lopper:Destroy()
            end)
        end

        if math.random(1, 100) <= 20 then
            local batPart = makePart(Vector3.new(0.4, 0.8, 0.4), CFrame.new(O + Vector3.new(math.random(-10, 10), 1, math.random(-10, 10))), Color3.fromRGB(30, 30, 30), 1, folder)
            batPart.Name = "Battery"
            local batPrompt = Instance.new("ProximityPrompt", batPart)
            batPrompt.ActionText = "Take Battery (+2 min)"
            batPrompt.Triggered:Connect(function()
                flashlightBattery = math.min(420, flashlightBattery + 120)
                showWarning("Refilled Flashlight Battery!", 2)
                batPart:Destroy()
            end)
        end

    else
        local lSide = math.random(1, 2) == 1 and 1 or -1
        local lZ = math.random(-18, 18)
        makeLocker(folder, O + Vector3.new(lSide * (ROOM_W * 0.42), 0, lZ))

        local roll = math.random(1, 10)
        if roll <= 7 then makeTableDecor(folder, O + Vector3.new(math.random(-8, 8), 0, math.random(-18, 18))) end
        if roll <= 7 then makePlant(folder, O + Vector3.new(math.random(-10, 10), 0, math.random(-18, 18))) end
        if roll <= 5 then makeDrawerTable(folder, O + Vector3.new(math.random(-8, 8), 0, math.random(-18, 18)), roomDrawers) end
        if roll <= 4 then makeBed(folder, O + Vector3.new(math.random(-8, 8), 0, math.random(-14, 14)), math.random(0, 1) * 90) end
        if roll <= 3 then makeLocker(folder, O + Vector3.new(-lSide * (ROOM_W * 0.42), 0, lZ - 6)) end
        if roll <= 2 then
            makePlant(folder, O + Vector3.new(math.random(-10, 10), 0, math.random(-18, 18)))
            makeTableDecor(folder, O + Vector3.new(math.random(-8, 8), 0, math.random(-18, 18)))
        end
        if roll <= 5 then
            local shelf = makePart(Vector3.new(0.3, 5, 3.5), CFrame.new(O + Vector3.new(math.random(-12, 12), 2.5, math.random(-18, 18))), Color3.fromRGB(90, 62, 32), 0, folder)
            shelf.Name = "Shelf"
            for s = 1, 3 do
                makePart(Vector3.new(0.32, 0.2, 3.5), CFrame.new(shelf.CFrame.Position + Vector3.new(0, s * 1.4 - 2, 0)), Color3.fromRGB(80, 55, 28), 0, folder).Name = "ShelfBoard"
            end
        end
        if roll >= 5 then
            makePart(Vector3.new(2, 2, 2), CFrame.new(O + Vector3.new(math.random(-10, 10), 1, math.random(-18, 18))), Color3.fromRGB(100, 80, 50), 0, folder, Enum.Material.Wood).Name = "Crate"
        end
        if roll >= 4 and not isDark then
            local sconce = makePart(Vector3.new(0.5, 1, 0.4), CFrame.new(O + Vector3.new(lSide * (ROOM_W * 0.48), ROOM_H - 3, math.random(-15, 15))), Color3.fromRGB(80, 70, 50), 0, folder)
            sconce.Name = "WallSconce"
            makeLight(sconce, 1, 14, Color3.fromRGB(255, 200, 120))
        end

        if math.random(1, 100) <= 20 then
            local batPart = makePart(Vector3.new(0.4, 0.8, 0.4), CFrame.new(O + Vector3.new(math.random(-5, 5), 3, math.random(-10, 10))), Color3.fromRGB(30, 30, 30), 1, folder)
            batPart.Name = "Battery"
            local batPrompt = Instance.new("ProximityPrompt", batPart)
            batPrompt.ActionText = "Take Battery (+2 min)"
            batPrompt.Enabled = false
            batPrompt.Triggered:Connect(function()
                flashlightBattery = math.min(420, flashlightBattery + 120)
                showWarning("Refilled Flashlight Battery!", 2)
                batPart:Destroy()
            end)
        end

        local keysNeeded = isLocked and 1 or 0
        if isLeft and isRight and isLocked then keysNeeded = 2 end

        for i = 1, keysNeeded do
            if #roomDrawers == 0 then makeDrawerTable(folder, O + Vector3.new(0, 0, 0), roomDrawers) end
            local available = {}
            for _, d in ipairs(roomDrawers) do
                if not d:GetAttribute("Loot") then table.insert(available, d) end
            end
            if #available > 0 then available[math.random(1, #available)]:SetAttribute("Loot", "Key") end
        end

        for _, drawer in ipairs(roomDrawers) do
            local prompt = Instance.new("ProximityPrompt")
            prompt.ActionText = "Search"
            prompt.RequiresLineOfSight = false
            prompt.Parent = drawer
            prompt.Triggered:Connect(function(plr)
                prompt:Destroy()

                local loot = drawer:GetAttribute("Loot")
                if not loot then
                    local r = math.random(1, 100)
                    if r <= 10 then loot = "Flashlight"
                    elseif r <= 35 then loot = "Ecstasy"
                    elseif r <= 60 then loot = "Coin"
                    else loot = "Nothing" end
                end

                if loot == "Coin" then
                    local amt = math.random(1, 5)
                    coins = coins + amt
                    if coinLabel then coinLabel.Text = tostring(coins) .. " Coins" end
                    showWarning("Found " .. amt .. " Coin" .. (amt > 1 and "s" or "") .. "!  Total: " .. coins, 2.5)
                    return
                end

                showWarning("You searched Drawer and found: " .. loot, 2)

                if loot ~= "Nothing" then
                    if #inventory >= MAX_ITEMS then
                        showWarning("Inventory full! Max 3 items.", 2)
                        return
                    end
                    table.insert(inventory, loot)
                    local tool = Instance.new("Tool")
                    tool.Name = loot
                    local handle = Instance.new("Part")
                    handle.Name = "Handle"
                    if loot == "Key" then
                        handle.Size = Vector3.new(1, 0.2, 0.2)
                        handle.Color = Color3.fromRGB(255, 215, 0)
                    elseif loot == "Flashlight" then
                        handle.Size = Vector3.new(0.4, 1.2, 0.4)
                        handle.Color = Color3.fromRGB(20, 20, 20)
                        local light = Instance.new("SpotLight", handle)
                        light.Range = 45
                        light.Brightness = 3
                        light.Angle = 70
                    elseif loot == "Ecstasy" then
                        handle.Size = Vector3.new(0.5, 0.5, 0.5)
                        handle.Color = Color3.fromRGB(200, 50, 200)
                        handle.Material = Enum.Material.Neon
                        tool.Activated:Connect(function()
                            tool:Destroy()
                            for i, v in ipairs(inventory) do
                                if v == "Ecstasy" then table.remove(inventory, i) break end
                            end
                            ecstasyActive = true
                            ecstasyEndTime = tick() + 180
                            if humanoid then humanoid.WalkSpeed = snowWhiteActive and 16 or 23 end
                            local cc = game.Lighting:FindFirstChild("EcstasyCC") or Instance.new("ColorCorrectionEffect", game.Lighting)
                            cc.Name = "EcstasyCC"
                            cc.Saturation = 1.5
                        end)
                    else
                        handle.Size = Vector3.new(0.5, 0.5, 0.5)
                    end
                    handle.Parent = tool
                    tool.Parent = plr.Backpack
                end
            end)
        end
    end

    rooms[doorNum] = folder
end

-- =================================================================
-- LOBBY
-- =================================================================
createLobby = function()
    local folder = Instance.new("Folder")
    folder.Name = "Lobby"
    folder.Parent = workspace

    makePart(Vector3.new(50, 1, 65), CFrame.new(0, -0.5, 32), Color3.fromRGB(36, 36, 48), 0, folder).Name = "LobbyFloor"
    makePart(Vector3.new(50, 1, 65), CFrame.new(0, 13.5, 32), Color3.fromRGB(28, 28, 38), 0, folder).Name = "LobbyCeiling"
    makePart(Vector3.new(50, 14, 1), CFrame.new(0, 7, 64.5), Color3.fromRGB(40, 40, 52), 0, folder).Name = "LobbyWallBack"
    makePart(Vector3.new(1, 14, 65), CFrame.new(-25, 7, 32), Color3.fromRGB(40, 40, 52), 0, folder).Name = "LobbyWallL"
    makePart(Vector3.new(1, 14, 65), CFrame.new(25, 7, 32), Color3.fromRGB(40, 40, 52), 0, folder).Name = "LobbyWallR"

    local lbLights = {Vector3.new(-12, 13, 20), Vector3.new(12, 13, 20), Vector3.new(-12, 13, 48), Vector3.new(12, 13, 48)}
    for _, lp in ipairs(lbLights) do
        local lb = makePart(Vector3.new(1.2, 0.4, 1.2), CFrame.new(lp), Color3.fromRGB(255, 255, 220), 0, folder)
        lb.Name = "LobbyLight"
        makeLight(lb, 2.2, 38, Color3.fromRGB(255, 240, 190))
    end

    local welcomeSign = makePart(Vector3.new(16, 3.5, 0.4), CFrame.new(0, 10, 64.2), Color3.fromRGB(15, 15, 20), 0, folder)
    welcomeSign.Name = "WelcomeSign"
    local wsGui = Instance.new("SurfaceGui")
    wsGui.Face = Enum.NormalId.Front
    wsGui.Parent = welcomeSign
    local wsLabel = Instance.new("TextLabel")
    wsLabel.Size = UDim2.new(1, 0, 0.6, 0)
    wsLabel.BackgroundTransparency = 1
    wsLabel.Text = HARD_MODE and "HARD MODE - Reach Door 100!" or "Survive to Door 1000"
    wsLabel.TextColor3 = HARD_MODE and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(220, 60, 60)
    wsLabel.TextScaled = true
    wsLabel.Font = Enum.Font.GothamBold
    wsLabel.Parent = wsGui
    local wsSubLabel = Instance.new("TextLabel")
    wsSubLabel.Size = UDim2.new(1, 0, 0.38, 0)
    wsSubLabel.Position = UDim2.new(0, 0, 0.62, 0)
    wsSubLabel.BackgroundTransparency = 1
    wsSubLabel.Text = HARD_MODE and "5 min timer  |  All entities from Door 0  |  No locked rooms!" or "Checkpoints every 100 doors  |  Hide in lockers!"
    wsSubLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    wsSubLabel.TextScaled = true
    wsSubLabel.Font = Enum.Font.Gotham
    wsSubLabel.Parent = wsGui

    makeTableDecor(folder, Vector3.new(-10, 0, 42))
    makePlant(folder, Vector3.new(10, 0, 42))
    makePlant(folder, Vector3.new(-16, 0, 30))
    makePlant(folder, Vector3.new(16, 0, 30))
    makeDrawerTable(folder, Vector3.new(13, 0, 55), {})
    makeBed(folder, Vector3.new(-13, 0, 55), 0)
    makeLocker(folder, Vector3.new(-22, 0, 42))
    makeLocker(folder, Vector3.new(22, 0, 42))

    local rug = makePart(Vector3.new(12, 0.05, 20), CFrame.new(0, 0, 28), Color3.fromRGB(90, 30, 30), 0, folder)
    rug.Name = "Rug"
    rug.CanCollide = false

    local startBtn = makePart(Vector3.new(7, 2.5, 3), CFrame.new(0, 1.25, 15), HARD_MODE and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(0, 155, 0), 0, folder, Enum.Material.Neon)
    startBtn.Name = "StartButton"
    local sbGui = Instance.new("SurfaceGui")
    sbGui.Face = Enum.NormalId.Front
    sbGui.Parent = startBtn
    local sbLabel = Instance.new("TextLabel")
    sbLabel.Size = UDim2.new(1, 0, 1, 0)
    sbLabel.BackgroundTransparency = 1
    sbLabel.Text = HARD_MODE and "HARD MODE START" or "PRESS  START"
    sbLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sbLabel.TextScaled = true
    sbLabel.Font = Enum.Font.GothamBold
    sbLabel.Parent = sbGui

    local startGui = Instance.new("ScreenGui")
    startGui.Name = "StartGui"
    startGui.ResetOnSpawn = false
    startGui.Parent = player.PlayerGui

    local startFrame = Instance.new("Frame")
    startFrame.Size = UDim2.new(0, 270, 0, 62)
    startFrame.Position = UDim2.new(0.5, -135, 0.82, 0)
    startFrame.BackgroundColor3 = HARD_MODE and Color3.fromRGB(160, 0, 0) or Color3.fromRGB(0, 130, 0)
    startFrame.BackgroundTransparency = 0.18
    startFrame.BorderSizePixel = 0
    startFrame.Visible = false
    startFrame.Name = "StartFrame"
    startFrame.Parent = startGui
    local sfc = Instance.new("UICorner")
    sfc.CornerRadius = UDim.new(0, 14)
    sfc.Parent = startFrame

    local startBtnUI = Instance.new("TextButton")
    startBtnUI.Size = UDim2.new(1, 0, 1, 0)
    startBtnUI.BackgroundTransparency = 1
    startBtnUI.Text = HARD_MODE and "[HARD MODE - TAP TO START]" or "[TAP TO START]"
    startBtnUI.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtnUI.TextScaled = true
    startBtnUI.Font = Enum.Font.GothamBold
    startBtnUI.Parent = startFrame

    startBtnUI.MouseButton1Click:Connect(function()
        if not gameStarted then startGui:Destroy(); startGame() end
    end)

    RunService.Heartbeat:Connect(function()
        if gameStarted or not rootPart then return end
        if not startGui.Parent then return end
        local dist = (rootPart.Position - startBtn.Position).Magnitude
        startFrame.Visible = dist < 10
    end)

    rooms[-1] = folder
    if character then character:PivotTo(CFrame.new(0, 3, 45)) end
end

-- =================================================================
-- LOCKER INTERACTION
-- =================================================================
hideInLocker = function()
    if not currentLocker or isHiding or not humanoid then return end
    isHiding = true
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            hiddenParts[part] = part.Transparency
            part.Transparency = 1
        end
    end
    if hideBtnLabel then hideBtnLabel.Text = "[EXIT]" end
end

exitLocker = function()
    if not isHiding or not humanoid then return end
    isHiding = false
    humanoid.JumpPower = 50
    for part, trans in pairs(hiddenParts) do
        if part and part.Parent then part.Transparency = trans end
    end
    table.clear(hiddenParts)
    if hideBtnLabel then hideBtnLabel.Text = "[HIDE]" end
end

-- =================================================================
-- WARNING
-- =================================================================
showWarning = function(msg, duration)
    if not warningFrame then return end
    warningFrame.Visible = true
    if warningLabel then warningLabel.Text = msg end
    task.delay(duration or 4, function()
        if warningFrame then warningFrame.Visible = false end
    end)
end

-- =================================================================
-- DEATH
-- =================================================================
onDeath = function()
    if isDead then return end
    isDead = true
    gameStarted = false
    isHiding = false
    snowWhiteActive = false
    lockerTime = 0
    if freezeOverlay then freezeOverlay.BackgroundTransparency = 1 end

    if snowWhitePart and snowWhitePart.Parent then
        snowWhitePart.Parent:Destroy()
        snowWhitePart = nil
    end

    if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
    if stemEyeContainer then stemEyeContainer.Visible = false end
    inventory = {}
    flashlightBattery = 420
    ecstasyActive = false
    local cc = game.Lighting:FindFirstChild("EcstasyCC")
    if cc then cc:Destroy() end

    -- HARD MODE: stop music and reset timer
    if HARD_MODE then
        hardModeStarted = false
        hardModeTimerActive = false
        hardModeTimeLeft = HARD_MODE_TIME
        if hardModeMusic then
            hardModeMusic:Stop()
            hardModeMusic:Destroy()
            hardModeMusic = nil
        end
        if timerLabel then
            timerLabel.Text = "5:00"
            timerLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
        end
    end

    local deathGui = Instance.new("ScreenGui")
    deathGui.Name = "DeathGui"
    deathGui.ResetOnSpawn = false
    deathGui.Parent = player.PlayerGui

    local deathBG = Instance.new("Frame")
    deathBG.Size = UDim2.new(1, 0, 1, 0)
    deathBG.BackgroundColor3 = Color3.fromRGB(160, 0, 0)
    deathBG.BackgroundTransparency = 0.45
    deathBG.BorderSizePixel = 0
    deathBG.Parent = deathGui

    local diedLabel = Instance.new("TextLabel")
    diedLabel.Size = UDim2.new(1, 0, 0.28, 0)
    diedLabel.Position = UDim2.new(0, 0, 0.34, 0)
    diedLabel.BackgroundTransparency = 1
    diedLabel.Text = "YOU DIED"
    diedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    diedLabel.TextScaled = true
    diedLabel.Font = Enum.Font.GothamBold
    diedLabel.Parent = deathBG

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(1, 0, 0.1, 0)
    subLabel.Position = UDim2.new(0, 0, 0.62, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = HARD_MODE and "Restarting Hard Mode from Door 0..." or ("Respawning at Checkpoint: Door " .. checkpointDoor)
    subLabel.TextColor3 = Color3.fromRGB(255, 190, 190)
    subLabel.TextScaled = true
    subLabel.Font = Enum.Font.Gotham
    subLabel.Parent = deathBG

    player.CharacterAdded:Wait()
    task.wait(0.3)

    deathGui:Destroy()
    isDead = false

    -- HARD MODE: always respawn at door 0
    local respawnDoor = HARD_MODE and 0 or checkpointDoor

    if character and rootPart then
        local cpZ = -(respawnDoor * ROOM_D) + ROOM_D * 0.35
        character:PivotTo(CFrame.new(0, 3, cpZ))
    end

    currentDoor = respawnDoor
    lastDetectedDoor = respawnDoor
    if doorLabel then doorLabel.Text = "Door: " .. respawnDoor end
    gameStarted = true

    for i = respawnDoor, respawnDoor + GEN_AHEAD do
        if i <= DOOR_MAX then generateRoom(i) end
    end

    if currentDoor >= SNOW_WHITE_DOOR and currentDoor < SNOW_WHITE_END then
        game.Lighting.FogColor = Color3.fromRGB(0, 200, 255)
        spawnSnowWhite(currentDoor)
    else
        game.Lighting.FogColor = Color3.fromRGB(0, 0, 0)
    end
end

-- =================================================================
-- ENTITY FUNCTIONS
-- =================================================================

spawnStem = function(bypassCooldown)
    -- HARD MODE: allow duplicates by skipping the stemActive guard
    if not HARD_MODE then
        if stemActive then return end
    end
    if stemOnCooldown and not bypassCooldown then return end
    stemActive = true
    if not bypassCooldown then stemOnCooldown = true end

    stemEyeOuter.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    stemEyeStroke.Color = Color3.fromRGB(0, 255, 60)
    stemIris.BackgroundColor3 = Color3.fromRGB(0, 185, 0)
    stemPupil.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    stemPupil.Size = UDim2.new(0, 38, 0, 38)
    stemPupil.Position = UDim2.new(0.5, -19, 0.5, -19)
    stemTopLid.Size = UDim2.new(1, 0, 0.5, 2)
    stemTopLid.Position = UDim2.new(0, 0, 0, 0)
    stemTopLid.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    stemBottomLid.Size = UDim2.new(1, 0, 0.5, 2)
    stemBottomLid.Position = UDim2.new(0, 0, 0.5, -2)
    stemBottomLid.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    stemEyeContainer.Visible = true

    task.wait(2)

    stemEyeStroke.Color = Color3.fromRGB(255, 0, 0)
    stemIris.BackgroundColor3 = Color3.fromRGB(210, 0, 0)

    local C_SCLERA_DARK = Color3.fromRGB(35, 0, 0)
    local C_SCLERA_LITE = Color3.fromRGB(230, 210, 210)
    local C_LID_DARK    = Color3.fromRGB(10, 10, 20)
    local C_LID_RED     = Color3.fromRGB(80, 0, 0)

    for _ = 1, 3 do
        stemEyeOuter.BackgroundColor3 = C_SCLERA_DARK
        stemTopLid.BackgroundColor3   = C_LID_RED
        stemBottomLid.BackgroundColor3 = C_LID_RED
        task.wait(0.11)
        stemEyeOuter.BackgroundColor3 = C_SCLERA_LITE
        stemTopLid.BackgroundColor3   = C_LID_DARK
        stemBottomLid.BackgroundColor3 = C_LID_DARK
        task.wait(0.11)
    end

    stemEyeOuter.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    task.wait(0.18)

    local openInfo = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(stemTopLid, openInfo, {Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 0)}):Play()
    TweenService:Create(stemBottomLid, openInfo, {Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 0)}):Play()
    TweenService:Create(stemPupil, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 54, 0, 54), Position = UDim2.new(0.5, -27, 0.5, -27)}):Play()

    if stemSound then stemSound.SoundId = "rbxassetid://132516383045655"; stemSound:Play() end

    task.wait(0.6)

    local isEyeOpen = true
    local stemConn
    stemConn = RunService.Heartbeat:Connect(function()
        if not isEyeOpen or isDead then stemConn:Disconnect(); return end
        if humanoid and rootPart and not isHiding then
            local moving  = humanoid.MoveDirection.Magnitude > 0.05
            local jumping = humanoid:GetState() == Enum.HumanoidStateType.Jumping
            if moving or jumping then
                stemPupil.Size = UDim2.new(0, 10, 0, 10)
                stemPupil.Position = UDim2.new(0.5, -5, 0.5, -5)
                task.wait(0.06)
                isEyeOpen = false
                humanoid.Health = 0
                onDeath()
                stemConn:Disconnect()
            end
        end
    end)

    -- HARD MODE: eye open lasts 3 seconds, normal: 5 seconds
    local openDuration = HARD_MODE and HARD_MODE_STEM_OPEN or 5
    task.delay(openDuration, function()
        isEyeOpen = false
        local closeInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(stemTopLid, closeInfo, {Size = UDim2.new(1, 0, 0.5, 2), Position = UDim2.new(0, 0, 0, 0)}):Play()
        TweenService:Create(stemBottomLid, closeInfo, {Size = UDim2.new(1, 0, 0.5, 2), Position = UDim2.new(0, 0, 0.5, -2)}):Play()
        TweenService:Create(stemPupil, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0.5, -19, 0.5, -19)}):Play()
        task.wait(0.45)
        stemEyeContainer.Visible = false
        stemActive = false
        if not bypassCooldown then
            local cd = HARD_MODE and HARD_MODE_COOLDOWN or STEM_COOLDOWN
            task.delay(cd, function() stemOnCooldown = false end)
        end
    end)
end

spawnPlantera = function(doorNum)
    -- HARD MODE: allow duplicates, only block on cooldown
    if not HARD_MODE then
        if planteraActive or diseaseActive or malwareActive then return end
        if planteraOnCooldown then return end
    else
        if planteraOnCooldown then return end
    end
    planteraActive = true
    planteraOnCooldown = true
    planteraSpawnedThisCheckpoint = true

    if doorNum >= STEM_START and math.random(1, 100) <= 55 then
        task.spawn(function() spawnStem(true) end)
    end

    for d = doorNum - 3, doorNum + 2 do
        if rooms[d] then makeVineDecor(rooms[d], Vector3.new(0, 0, -(d * ROOM_D)), true) end
    end

    local entityFolder = Instance.new("Folder")
    entityFolder.Name = "PlanteraEntity"
    entityFolder.Parent = workspace

    local startDoor = doorNum - PLANTERA_BEFORE
    local stopDoor  = doorNum + PLANTERA_AFTER
    local startZ    = -(startDoor * ROOM_D)
    local stopZ     = -(stopDoor  * ROOM_D)

    local entityPart = makePart(Vector3.new(ROOM_W - 1, ROOM_H, ROOM_D), CFrame.new(0, ROOM_H * 0.5, startZ), Color3.fromRGB(18, 75, 18), 0.5, entityFolder, Enum.Material.Neon)
    entityPart.Name = "PlanteraBody"
    entityPart.CanCollide = false

    local trail = Instance.new("Trail")
    trail.Color = ColorSequence.new(Color3.fromRGB(30, 200, 30))
    trail.Lifetime = 2
    trail.Parent = entityPart
    local a0 = Instance.new("Attachment", entityPart); a0.Position = Vector3.new(0, 5, 0)
    local a1 = Instance.new("Attachment", entityPart); a1.Position = Vector3.new(0, -5, 0)
    trail.Attachment0 = a0; trail.Attachment1 = a1

    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(Color3.fromRGB(10, 220, 10))
    particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5)})
    particles.Rate = 50; particles.Speed = NumberRange.new(5, 15)
    particles.Parent = entityPart

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, ROOM_W * 16, 0, ROOM_H * 16)
    billboard.AlwaysOnTop = false
    billboard.Parent = entityPart
    local imgLabel = Instance.new("ImageLabel")
    imgLabel.Size = UDim2.new(1, 0, 1, 0)
    imgLabel.BackgroundTransparency = 1
    imgLabel.Image = "rbxassetid://129873844893798"
    imgLabel.ScaleType = Enum.ScaleType.Fit
    imgLabel.Parent = billboard

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://112243770921992"
    sound.Volume = 1.3; sound.Looped = true; sound.RollOffMaxDistance = 150
    sound.Parent = entityPart; sound:Play()

    local planteraMoveConn
    planteraMoveConn = RunService.Heartbeat:Connect(function(dt)
        if not entityPart or not entityPart.Parent then planteraMoveConn:Disconnect(); return end
        local cf = entityPart.CFrame
        local newZ = cf.Position.Z - PLANTERA_SPEED * dt
        entityPart.CFrame = CFrame.new(cf.Position.X, cf.Position.Y, newZ)

        if rootPart and humanoid and not isDead then
            local dist = math.abs(rootPart.Position.Z - entityPart.Position.Z)
            if dist < 120 then
                local intensity = (120 - dist) / 120
                humanoid.CameraOffset = Vector3.new(math.random(-10,10)*0.03*intensity, math.random(-10,10)*0.03*intensity, 0)
            else
                humanoid.CameraOffset = Vector3.new(0, 0, 0)
            end
            if not isHiding and dist < ROOM_D * 0.5 then
                if humanoid.Health > 0 then humanoid.Health = 0; onDeath() end
            end
        end

        if newZ <= stopZ then
            planteraMoveConn:Disconnect()
            sound:Stop()
            if humanoid then humanoid.CameraOffset = Vector3.new(0,0,0) end
            planteraActive = false
            local step = 0
            local fadeConn
            fadeConn = RunService.Heartbeat:Connect(function()
                step = step + 1
                if entityPart and entityPart.Parent then entityPart.Transparency = 0.5 + step * 0.04 end
                if step >= 12 then
                    fadeConn:Disconnect()
                    for d = startDoor, stopDoor do
                        if rooms[d] then
                            for _, v in ipairs(rooms[d]:GetDescendants()) do
                                if v.Name == "Vine" then v:Destroy() end
                            end
                        end
                    end
                    entityFolder:Destroy()
                end
            end)
            local cd = HARD_MODE and HARD_MODE_COOLDOWN or PLANTERA_COOLDOWN
            task.delay(cd, function() planteraOnCooldown = false end)
        end
    end)
end

spawnDisease = function(doorNum)
    -- HARD MODE: allow duplicates, only block on cooldown
    if not HARD_MODE then
        if planteraActive or diseaseActive or malwareActive then return end
        if diseaseOnCooldown then return end
    else
        if diseaseOnCooldown then return end
    end
    diseaseActive = true
    diseaseOnCooldown = true

    local entityFolder = Instance.new("Folder")
    entityFolder.Name = "DiseaseEntity"
    entityFolder.Parent = workspace

    local startDoor = doorNum - PLANTERA_BEFORE
    local stopDoor  = doorNum + PLANTERA_AFTER
    local startZ    = -(startDoor * ROOM_D)
    local stopZ     = -(stopDoor  * ROOM_D)

    for d = startDoor, stopDoor do
        if rooms[d] then
            local smoke = Instance.new("ParticleEmitter")
            smoke.Name = "DiseaseSmoke"
            smoke.Color = ColorSequence.new(Color3.fromRGB(200, 0, 0))
            smoke.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 20)})
            smoke.Rate = 100; smoke.Speed = NumberRange.new(2, 5); smoke.Lifetime = NumberRange.new(3, 6)
            smoke.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 1)})
            local emitPart = makePart(Vector3.new(ROOM_W, 1, ROOM_D), CFrame.new(0, ROOM_H * 0.5, -(d * ROOM_D)), Color3.new(), 1, entityFolder)
            smoke.Parent = emitPart
        end
    end

    local entityPart = makePart(Vector3.new(ROOM_W - 1, ROOM_H, ROOM_D), CFrame.new(0, ROOM_H * 0.5, startZ), Color3.fromRGB(150, 0, 0), 0.5, entityFolder, Enum.Material.Neon)
    entityPart.Name = "DiseaseBody"
    entityPart.CanCollide = false

    local trail = Instance.new("Trail")
    trail.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
    trail.Lifetime = 2; trail.Parent = entityPart
    local da0 = Instance.new("Attachment", entityPart); da0.Position = Vector3.new(0, 5, 0)
    local da1 = Instance.new("Attachment", entityPart); da1.Position = Vector3.new(0, -5, 0)
    trail.Attachment0 = da0; trail.Attachment1 = da1

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://125795970503985"
    sound.Volume = 1.5; sound.Looped = true; sound.RollOffMaxDistance = 200
    sound.Parent = entityPart; sound:Play()

    local moveConn
    moveConn = RunService.Heartbeat:Connect(function(dt)
        if not entityPart or not entityPart.Parent then moveConn:Disconnect(); return end
        local cf = entityPart.CFrame
        local newZ = cf.Position.Z - DISEASE_SPEED * dt
        entityPart.CFrame = CFrame.new(cf.Position.X, cf.Position.Y, newZ)

        if rootPart and humanoid and not isDead then
            local distZ = math.abs(rootPart.Position.Z - entityPart.Position.Z)
            if distZ < 150 then
                local intensity = (150 - distZ) / 150
                humanoid.CameraOffset = Vector3.new(math.random(-10,10)*0.06*intensity, math.random(-10,10)*0.06*intensity, 0)
            else
                humanoid.CameraOffset = Vector3.new(0,0,0)
            end
            if not isHiding and distZ < ROOM_D * 0.5 then
                if humanoid.Health > 0 then humanoid.Health = 0; onDeath() end
            end
        end

        if newZ <= stopZ then
            moveConn:Disconnect(); sound:Stop()
            diseaseActive = false
            if humanoid then humanoid.CameraOffset = Vector3.new(0,0,0) end
            entityFolder:Destroy()
            local cd = HARD_MODE and HARD_MODE_COOLDOWN or DISEASE_COOLDOWN
            task.delay(cd, function() diseaseOnCooldown = false end)
        end
    end)
end

spawnMalware = function(doorNum)
    -- HARD MODE: allow duplicates, only block on cooldown
    if not HARD_MODE then
        if planteraActive or diseaseActive or malwareActive then return end
        if malwareOnCooldown then return end
    else
        if malwareOnCooldown then return end
    end
    malwareActive = true
    malwareOnCooldown = true

    local entityFolder = Instance.new("Folder")
    entityFolder.Name = "MalwareEntity"
    entityFolder.Parent = workspace

    local startDoor = doorNum - MALWARE_BEFORE
    local stopDoor  = doorNum + MALWARE_AFTER
    local startZ    = -(startDoor * ROOM_D)
    local stopZ     = -(stopDoor  * ROOM_D)

    local entityPart = makePart(
        Vector3.new(ROOM_W - 1, ROOM_H, ROOM_D * 0.4),
        CFrame.new(0, ROOM_H * 0.5, startZ),
        Color3.fromRGB(0, 255, 255), 0.35,
        entityFolder, Enum.Material.Neon
    )
    entityPart.Name = "MalwareBody"
    entityPart.CanCollide = false

    local slice2 = makePart(
        Vector3.new(ROOM_W - 1, ROOM_H * 0.4, ROOM_D * 0.25),
        CFrame.new(0, ROOM_H * 0.3, startZ + 4),
        Color3.fromRGB(255, 0, 255), 0.5,
        entityFolder, Enum.Material.Neon
    )
    slice2.Name = "MalwareSlice"
    slice2.CanCollide = false

    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0))
    })
    particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 8)})
    particles.Rate = 200
    particles.Speed = NumberRange.new(10, 30)
    particles.Lifetime = NumberRange.new(0.2, 0.5)
    particles.RotSpeed = NumberRange.new(-360, 360)
    particles.Rotation = NumberRange.new(0, 360)
    particles.Parent = entityPart

    local trail = Instance.new("Trail")
    trail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
    })
    trail.Lifetime = 0.4
    trail.WidthScale = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
    trail.Parent = entityPart
    local ta0 = Instance.new("Attachment", entityPart); ta0.Position = Vector3.new(0, ROOM_H * 0.45, 0)
    local ta1 = Instance.new("Attachment", entityPart); ta1.Position = Vector3.new(0, -ROOM_H * 0.45, 0)
    trail.Attachment0 = ta0; trail.Attachment1 = ta1

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://121601166627717"
    sound.Volume = 5
    sound.Looped = true
    sound.RollOffMaxDistance = 300
    sound.Parent = entityPart
    sound:Play()

    local destroyedRooms = {}

    local malwareMoveConn
    malwareMoveConn = RunService.Heartbeat:Connect(function(dt)
        if not entityPart or not entityPart.Parent then
            malwareMoveConn:Disconnect()
            return
        end

        local cf = entityPart.CFrame
        local newZ = cf.Position.Z - MALWARE_SPEED * dt
        entityPart.CFrame = CFrame.new(0, ROOM_H * 0.5, newZ)
        slice2.CFrame = CFrame.new(0, ROOM_H * 0.3, newZ + 4 + math.random(-2, 2) * 0.5)

        local passingDoor = math.max(0, math.floor(-newZ / ROOM_D + 0.5))

        if not destroyedRooms[passingDoor] then
            destroyedRooms[passingDoor] = true
            if rooms[passingDoor] then
                local decorList = {}
                for _, part in ipairs(rooms[passingDoor]:GetDescendants()) do
                    if part:IsA("BasePart") and DECOR_NAMES[part.Name] then
                        table.insert(decorList, part)
                    end
                end

                local toDestroy = math.random(3, 5)
                for i = 1, math.min(toDestroy, #decorList) do
                    local idx = math.random(1, #decorList)
                    local part = decorList[idx]
                    table.remove(decorList, idx)
                    part.Color = Color3.fromRGB(0, 255, 255)
                    part.Material = Enum.Material.Neon
                    task.delay(0.06, function()
                        if part and part.Parent then part:Destroy() end
                    end)
                end
            end
        end

        if rootPart and humanoid and not isDead then
            local distZ = math.abs(rootPart.Position.Z - newZ)

            if distZ < 180 then
                local intensity = (180 - distZ) / 180
                humanoid.CameraOffset = Vector3.new(
                    math.random(-100, 100) * 0.012 * intensity,
                    math.random(-100, 100) * 0.012 * intensity,
                    0
                )
            else
                humanoid.CameraOffset = Vector3.new(0, 0, 0)
            end

            if distZ < ROOM_D * 0.55 then
                local playerX  = rootPart.Position.X
                local playerZ  = rootPart.Position.Z
                local roomCtrZ = -(passingDoor * ROOM_D)
                local relZ     = math.abs(playerZ - roomCtrZ)

                local nearSideWall = math.abs(playerX) > (ROOM_W * 0.5 - 5)
                local nearEndWall  = relZ > (ROOM_D * 0.5 - 6)
                local inCorner = nearSideWall and nearEndWall

                if not inCorner then
                    if humanoid.Health > 0 then
                        humanoid.Health = 0
                        onDeath()
                    end
                end
            end
        end

        if newZ <= stopZ then
            malwareMoveConn:Disconnect()
            sound:Stop()
            if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
            malwareActive = false

            local step = 0
            local fadeConn
            fadeConn = RunService.Heartbeat:Connect(function()
                step = step + 1
                if entityPart and entityPart.Parent then entityPart.Transparency = 0.35 + step * 0.065 end
                if slice2 and slice2.Parent then slice2.Transparency = 0.5 + step * 0.065 end
                if step >= 10 then
                    fadeConn:Disconnect()
                    entityFolder:Destroy()
                end
            end)

            local cd = HARD_MODE and HARD_MODE_COOLDOWN or MALWARE_COOLDOWN
            task.delay(cd, function() malwareOnCooldown = false end)
        end
    end)
end

spawnHer = function(doorNum)
    -- HARD MODE: allow duplicates, only block on cooldown
    if not HARD_MODE then
        if herActive or herOnCooldown then return end
    else
        if herOnCooldown then return end
    end
    herActive = true
    herOnCooldown = true

    local roomZ = -(doorNum * ROOM_D)

    local entityFolder = Instance.new("Folder")
    entityFolder.Name = "HerEntity"
    entityFolder.Parent = workspace

    local entityPart = makePart(Vector3.new(1.8, 7.5, 1.8), CFrame.new(0, 3.75, roomZ), Color3.fromRGB(0, 0, 0), 0, entityFolder)
    entityPart.Name = "HerBody"
    entityPart.CanCollide = false

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://129136912774651"
    sound.Volume = 2
    sound.Looped = true
    sound.RollOffMaxDistance = 100
    sound.Parent = entityPart
    sound:Play()

    local lookTimer = 0
    local isChasing = false
    local herConn

    herConn = RunService.Heartbeat:Connect(function(dt)
        if not entityPart or not entityPart.Parent or isDead then
            if herConn then herConn:Disconnect() end
            return
        end

        if not isChasing then
            if rootPart and camera then
                local toHer = (entityPart.Position - camera.CFrame.Position).Unit
                local lookDir = camera.CFrame.LookVector
                local dot = lookDir:Dot(toHer)

                if dot > 0.75 then
                    lookTimer = lookTimer + dt
                else
                    lookTimer = math.max(0, lookTimer - dt)
                end

                if lookTimer >= 3 then
                    isChasing = true
                    sound:Stop()
                    sound.SoundId = "rbxassetid://108968287863512"
                    sound.Volume = 3
                    sound:Play()
                    entityPart.Color = Color3.fromRGB(20, 0, 0)
                end
            end

            if currentDoor > doorNum + 2 then
                herConn:Disconnect()
                entityFolder:Destroy()
                herActive = false
                local cd = HARD_MODE and HARD_MODE_COOLDOWN or HER_COOLDOWN
                task.delay(cd, function() herOnCooldown = false end)
            end
        else
            if rootPart then
                local cframeLook = CFrame.lookAt(entityPart.Position, rootPart.Position)
                entityPart.CFrame = cframeLook + cframeLook.LookVector * HER_SPEED * dt
                entityPart.CFrame = CFrame.new(entityPart.Position.X, 3.75, entityPart.Position.Z)

                local dist = (rootPart.Position - entityPart.Position).Magnitude
                if dist < 100 and humanoid then
                    local intensity = (100 - dist) / 100
                    humanoid.CameraOffset = Vector3.new(
                        math.random(-10, 10) * 0.08 * intensity,
                        math.random(-10, 10) * 0.08 * intensity,
                        0
                    )
                end

                if dist < 4 and humanoid.Health > 0 then
                    local deathSound = Instance.new("Sound")
                    deathSound.SoundId = "rbxassetid://132080416777849"
                    deathSound.Parent = workspace
                    deathSound:Play()
                    humanoid.Health = 0
                    onDeath()
                end

                if not roomIsDark[currentDoor] then
                    herConn:Disconnect()
                    sound:Stop()
                    if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
                    entityFolder:Destroy()
                    herActive = false
                    local cd = HARD_MODE and HARD_MODE_COOLDOWN or HER_COOLDOWN
                    task.delay(cd, function() herOnCooldown = false end)
                end
            end
        end
    end)
end

spawnSnowWhite = function(doorNum)
    if snowWhiteActive then return end
    snowWhiteActive = true

    local entityFolder = Instance.new("Folder")
    entityFolder.Name = "SnowWhiteEntity"
    entityFolder.Parent = workspace

    snowWhitePart = makePart(Vector3.new(2, 7.5, 2), CFrame.new(0, 3.75, -(doorNum * ROOM_D)), Color3.fromRGB(0, 255, 255), 0, entityFolder, Enum.Material.Neon)
    snowWhitePart.Name = "SnowWhiteBody"
    snowWhitePart.CanCollide = false

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://127541805467143"
    sound.PlaybackSpeed = 1.3
    sound.Volume = 2
    sound.Looped = true
    sound.RollOffMaxDistance = 150
    sound.Parent = snowWhitePart
    sound:Play()

    task.spawn(function()
        while snowWhiteActive and not isDead and snowWhitePart.Parent do
            task.wait(5)
            if not isHiding and snowWhitePart.Parent then
                local throwSound = Instance.new("Sound", snowWhitePart)
                throwSound.SoundId = "rbxassetid://139748755504027"
                throwSound.Volume = 1.5
                throwSound:Play()

                local iceBall = makePart(Vector3.new(1.5, 1.5, 1.5), snowWhitePart.CFrame, Color3.fromRGB(150, 255, 255), 0.2, entityFolder, Enum.Material.Neon)
                iceBall.Shape = Enum.PartType.Ball
                iceBall.CanCollide = false

                local toPlayer = (rootPart.Position - iceBall.Position).Unit
                local speed = 40
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = toPlayer * speed
                bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                bv.Parent = iceBall

                local hitConn
                hitConn = iceBall.Touched:Connect(function(hit)
                    if hit.Parent == character then
                        hitConn:Disconnect()
                        iceBall:Destroy()
                        if humanoid then
                            humanoid:TakeDamage(30)
                            speedPenaltyEnd = tick() + 10
                            local hitSound = Instance.new("Sound", workspace)
                            hitSound.SoundId = "rbxassetid://138083803229439"
                            hitSound:Play()
                        end
                    elseif hit.Name ~= "SnowWhiteBody" and not hit.Parent:IsDescendantOf(character) then
                        hitConn:Disconnect()
                        task.delay(0.1, function() iceBall:Destroy() end)
                    end
                end)
                task.delay(4, function() if iceBall and iceBall.Parent then iceBall:Destroy() end end)
            end
        end
    end)

    local snowConn
    snowConn = RunService.Heartbeat:Connect(function(dt)
        if not snowWhitePart or not snowWhitePart.Parent or isDead then
            snowConn:Disconnect()
            return
        end

        if not isHiding and rootPart then
            local cframeLook = CFrame.lookAt(snowWhitePart.Position, rootPart.Position)
            snowWhitePart.CFrame = cframeLook + cframeLook.LookVector * 13 * dt
            snowWhitePart.CFrame = CFrame.new(snowWhitePart.Position.X, 3.75, snowWhitePart.Position.Z)

            local dist = (rootPart.Position - snowWhitePart.Position).Magnitude
            if dist < 4 and humanoid.Health > 0 then
                local deathSound = Instance.new("Sound", workspace)
                deathSound.SoundId = "rbxassetid://137069306202776"
                deathSound:Play()
                humanoid.Health = 0
                onDeath()
            end
        end
    end)
end

spawnVoid = function(doorNum)
    -- HARD MODE: allow duplicates, only block on cooldown
    if not HARD_MODE then
        if voidActive or voidOnCooldown then return end
    else
        if voidOnCooldown then return end
    end
    voidActive = true
    voidOnCooldown = true

    local roomZ = -(doorNum * ROOM_D)

    local voidPart = makePart(Vector3.new(5, 0.1, 5), CFrame.new(0, -0.4, roomZ), Color3.fromRGB(5, 5, 5), 0, workspace, Enum.Material.Neon)
    voidPart.Name = "VoidSubstance"
    voidPart.CanCollide = false

    local particles = Instance.new("ParticleEmitter", voidPart)
    particles.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
    particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6)})
    particles.Rate = 60
    particles.Speed = NumberRange.new(5, 12)

    local expSound = Instance.new("Sound", voidPart)
    expSound.SoundId = "rbxassetid://140328974468167"
    expSound.Looped = true
    expSound.PlaybackSpeed = 0.01
    expSound.Volume = 2
    expSound.RollOffMaxDistance = 200
    expSound:Play()

    local expansionTime = 13
    local maxExpansion = 100
    local startTime = tick()

    local voidConn
    voidConn = RunService.Heartbeat:Connect(function()
        if not voidPart or not voidPart.Parent then
            voidConn:Disconnect()
            return
        end

        local elapsed = tick() - startTime
        local progress = math.min(1, elapsed / expansionTime)

        local currentSize = 5 + (maxExpansion - 5) * progress
        voidPart.Size = Vector3.new(currentSize, 0.1, currentSize)

        expSound.PlaybackSpeed = 0.01 + (1.99 * progress)

        if rootPart and humanoid and humanoid.Health > 0 and not isDead and not isHiding then
            local pPos = rootPart.Position
            local vPos = voidPart.Position
            local dist = math.sqrt((pPos.X - vPos.X)^2 + (pPos.Z - vPos.Z)^2)

            if dist <= (currentSize / 2) and math.abs(pPos.Y - vPos.Y) < 10 then
                humanoid.Health = 0
                for _, pt in ipairs(character:GetDescendants()) do
                    if pt:IsA("BasePart") then pt.CanCollide = false end
                end
                humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                rootPart.Velocity = Vector3.new(0, -50, 0)
                onDeath()
            end
        end
    end)

    task.delay(25, function()
        voidActive = false
        if voidConn then voidConn:Disconnect() end
        if voidPart then voidPart:Destroy() end
    end)

    local cd = HARD_MODE and HARD_MODE_COOLDOWN or VOID_COOLDOWN
    task.delay(cd, function()
        voidOnCooldown = false
    end)
end

-- =================================================================
-- DOOR REACHED
-- =================================================================
onDoorReached = function(doorNum)
    currentDoor = doorNum
    if doorLabel then doorLabel.Text = "Door: " .. doorNum end

    -- ===== HARD MODE DOOR 1: START MUSIC + TIMER =====
    if HARD_MODE and doorNum == 1 then
        hardModeStarted = true
        hardModeTimeLeft = HARD_MODE_TIME
        hardModeTimerActive = true

        -- Destroy old music if any
        if hardModeMusic then
            hardModeMusic:Stop()
            hardModeMusic:Destroy()
            hardModeMusic = nil
        end

        hardModeMusic = Instance.new("Sound")
        hardModeMusic.SoundId = HARD_MODE_MUSIC_ID
        hardModeMusic.Volume = 0.85
        hardModeMusic.Looped = true
        hardModeMusic.Parent = workspace
        hardModeMusic:Play()

        if timerLabel then
            timerLabel.Text = "5:00"
            timerLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
        end
        showWarning("HARD MODE ACTIVE! Reach Door 100 in 5 minutes!", 4)
    end

    -- ===== HARD MODE WIN CONDITION: DOOR 100 =====
    if HARD_MODE and doorNum >= HARD_MODE_DOOR_MAX then
        hardModeTimerActive = false
        if hardModeMusic then
            hardModeMusic:Stop()
            hardModeMusic:Destroy()
            hardModeMusic = nil
        end
        if timerLabel then
            timerLabel.Text = "WIN!"
            timerLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
        showWarning("🏆 HARD MODE COMPLETE! You reached Door 100 in time!", 20)
        gameStarted = false
        return
    end

    if not HARD_MODE then
        if doorNum > 0 and doorNum % CHECKPOINT_EVERY == 0 then
            checkpointDoor = doorNum
            planteraSpawnedThisCheckpoint = false
            showWarning("CHECKPOINT SAVED  -  Door " .. doorNum, 3)
        end
    end

    -- Boss Logic (only in normal mode or if not past hard mode door max)
    if doorNum >= SNOW_WHITE_DOOR and doorNum < SNOW_WHITE_END then
        game.Lighting.FogColor = Color3.fromRGB(0, 200, 255)
    else
        game.Lighting.FogColor = Color3.fromRGB(0, 0, 0)
    end

    if doorNum == SNOW_WHITE_DOOR and not snowWhiteActive then
        spawnSnowWhite(doorNum)
    end

    if doorNum == SNOW_WHITE_END and snowWhiteActive then
        snowWhiteActive = false
        if snowWhitePart and snowWhitePart.Parent then
            snowWhitePart.Parent:Destroy()
        end
    end

    for i = doorNum + 1, doorNum + GEN_AHEAD do
        if i <= DOOR_MAX then generateRoom(i) end
    end

    for i = 0, doorNum - CLEAN_BEHIND do
        if rooms[i] then rooms[i]:Destroy(); rooms[i] = nil end
        roomIsDark[i] = nil
    end

    local entityMultiplier = snowWhiteActive and 0.1 or 1

    -- ===== HARD MODE ENTITY SPAWNING =====
    -- All entities from door 0, 45% chance each, 7s cooldown, duplicates allowed
    if HARD_MODE then
        if not stemOnCooldown and math.random(1, 100) <= HARD_MODE_CHANCE then
            task.spawn(function() spawnStem(false) end)
        end
        if not herOnCooldown and math.random(1, 100) <= HARD_MODE_CHANCE then
            task.spawn(function() spawnHer(doorNum) end)
        end
        if not planteraOnCooldown and math.random(1, 100) <= HARD_MODE_CHANCE then
            spawnPlantera(doorNum)
        end
        if not diseaseOnCooldown and math.random(1, 100) <= HARD_MODE_CHANCE then
            spawnDisease(doorNum)
        end
        if not malwareOnCooldown and math.random(1, 100) <= HARD_MODE_CHANCE then
            task.spawn(function() spawnMalware(doorNum) end)
        end
        if not voidOnCooldown and math.random(1, 100) <= HARD_MODE_CHANCE then
            task.spawn(function() spawnVoid(doorNum) end)
        end

    -- ===== NORMAL MODE ENTITY SPAWNING (original logic) =====
    else
        if doorNum == 100 then
            if not herActive and not herOnCooldown and roomIsDark[doorNum] and math.random(1, 100) <= (25 * entityMultiplier) then
                task.spawn(function() spawnHer(doorNum) end)
            end

            if not stemActive and not stemOnCooldown and math.random(1, 100) <= (20 * entityMultiplier) then
                task.spawn(function() spawnStem(false) end)
            end

            if not planteraActive and not diseaseActive and not malwareActive then
                local roll = math.random(1, 100)
                if roll <= (30 * entityMultiplier) then
                    spawnPlantera(doorNum)
                elseif roll <= (55 * entityMultiplier) and not diseaseOnCooldown then
                    spawnDisease(doorNum)
                elseif roll <= (80 * entityMultiplier) and not malwareOnCooldown then
                    task.spawn(function() spawnMalware(doorNum) end)
                end
            end
        elseif doorNum >= 5 and doorNum < 100 then
            if doorNum >= HER_START and not herActive and not herOnCooldown then
                if roomIsDark[doorNum] and math.random(1, 100) <= (25 * entityMultiplier) then
                    task.spawn(function() spawnHer(doorNum) end)
                end
            end

            if doorNum >= STEM_START and not stemActive and not stemOnCooldown then
                if math.random(1, 100) <= (85 * entityMultiplier) then
                    task.spawn(function() spawnStem(false) end)
                end
            end

            if doorNum >= 5 and not planteraActive and not diseaseActive and not malwareActive and not planteraOnCooldown and not planteraSpawnedThisCheckpoint then
                if math.random(1, 100) <= (50 * entityMultiplier) then spawnPlantera(doorNum) end
            end

            if doorNum >= 35 and not planteraActive and not diseaseActive and not malwareActive and not diseaseOnCooldown then
                if math.random(1, 100) <= (30 * entityMultiplier) then spawnDisease(doorNum) end
            end

            if doorNum >= MALWARE_START and not planteraActive and not diseaseActive and not malwareActive and not malwareOnCooldown then
                if math.random(1, 100) <= (30 * entityMultiplier) then
                    task.spawn(function() spawnMalware(doorNum) end)
                end
            end
        else
            if doorNum >= HER_START and not herActive and not herOnCooldown then
                if roomIsDark[doorNum] and math.random(1, 100) <= (25 * entityMultiplier) then
                    task.spawn(function() spawnHer(doorNum) end)
                end
            end

            if doorNum >= STEM_START and not stemActive and not stemOnCooldown then
                if math.random(1, 100) <= (85 * entityMultiplier) then
                    task.spawn(function() spawnStem(false) end)
                end
            end

            if doorNum >= 5 and not planteraActive and not diseaseActive and not malwareActive and not planteraOnCooldown and not planteraSpawnedThisCheckpoint then
                if math.random(1, 100) <= (50 * entityMultiplier) then spawnPlantera(doorNum) end
            end

            if doorNum >= 35 and not planteraActive and not diseaseActive and not malwareActive and not diseaseOnCooldown then
                if math.random(1, 100) <= (30 * entityMultiplier) then spawnDisease(doorNum) end
            end

            if doorNum >= MALWARE_START and not planteraActive and not diseaseActive and not malwareActive and not malwareOnCooldown then
                if math.random(1, 100) <= (30 * entityMultiplier) then
                    task.spawn(function() spawnMalware(doorNum) end)
                end
            end
        end

        -- Void (normal mode)
        if doorNum >= VOID_START and not voidActive and not voidOnCooldown then
            if math.random(1, 100) <= VOID_CHANCE then
                task.spawn(function() spawnVoid(doorNum) end)
            end
        end

        if doorNum >= DOOR_MAX then
            showWarning("YOU ESCAPED! Congratulations on surviving all 1000 doors!", 20)
            gameStarted = false
        end
    end
end

-- =================================================================
-- START GAME
-- =================================================================
startGame = function()
    gameStarted = true
    currentDoor = 0
    lastDetectedDoor = 0
    checkpointDoor = 0
    planteraSpawnedThisCheckpoint = false

    -- HARD MODE: reset timer state
    if HARD_MODE then
        hardModeStarted = false
        hardModeTimerActive = false
        hardModeTimeLeft = HARD_MODE_TIME
        if hardModeMusic then
            hardModeMusic:Stop()
            hardModeMusic:Destroy()
            hardModeMusic = nil
        end
        if timerLabel then
            timerLabel.Text = "5:00"
            timerLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
        end
    end

    if character then character:PivotTo(CFrame.new(0, 3, ROOM_D * 0.45)) end
    for i = 0, GEN_AHEAD do generateRoom(i) end
end

-- =================================================================
-- CHARACTER REF
-- =================================================================
updateCharRef = function(newChar)
    character = newChar
    humanoid  = newChar:WaitForChild("Humanoid")
    rootPart  = newChar:WaitForChild("HumanoidRootPart")

    -- Mute default run sound
    task.spawn(function()
        local runSound = rootPart:WaitForChild("Running", 3)
        if runSound then runSound.Volume = 0 end
    end)

    -- Setup Custom Footsteps
    floorStepSound = Instance.new("Sound")
    floorStepSound.SoundId = "rbxassetid://138898236956764"
    floorStepSound.Volume = 1
    floorStepSound.Parent = rootPart

    grassStepSound = Instance.new("Sound")
    grassStepSound.SoundId = "rbxassetid://140563218459039"
    grassStepSound.Volume = 1
    grassStepSound.Parent = rootPart

    humanoid.Died:Connect(function() onDeath() end)
end

-- =================================================================
-- MAIN LOOP
-- =================================================================
mainLoop = function()
    RunService.Heartbeat:Connect(function(dt)
        if not gameStarted or not rootPart then return end

        -- WalkSpeed Logic
        -- HARD MODE: base speed is 25 once past door 1, normal: 16
        local baseSpeed = (HARD_MODE and hardModeStarted) and HARD_MODE_SPEED or 16

        local targetSpeed = baseSpeed
        if snowWhiteActive then targetSpeed = 14 end
        if ecstasyActive then
            if tick() > ecstasyEndTime then
                ecstasyActive = false
                local cc = game.Lighting:FindFirstChild("EcstasyCC")
                if cc then cc:Destroy() end
            else
                targetSpeed = snowWhiteActive and 16 or (HARD_MODE and hardModeStarted and 28 or 23)
            end
        end

        if tick() < speedPenaltyEnd then
            targetSpeed = targetSpeed - 3
        end

        if not isHiding and humanoid and not diseaseActive then
            humanoid.WalkSpeed = targetSpeed
        end

        -- CUSTOM FOOTSTEP LOGIC
        if humanoid.Health > 0 and not isHiding then
            local isMoving = humanoid.MoveDirection.Magnitude > 0
            if isMoving and humanoid.FloorMaterial ~= Enum.Material.Air then
                local speedRatio = humanoid.WalkSpeed / 16
                local stepInterval = 0.35 / math.max(0.1, speedRatio)
                if tick() - lastStepTime >= stepInterval then
                    lastStepTime = tick()
                    if humanoid.FloorMaterial == Enum.Material.Grass then
                        grassStepSound.PlaybackSpeed = speedRatio
                        grassStepSound:Play()
                    else
                        floorStepSound.PlaybackSpeed = speedRatio
                        floorStepSound:Play()
                    end
                end
            else
                lastStepTime = 0
            end
        end

        -- HARD MODE TIMER COUNTDOWN
        if HARD_MODE and hardModeTimerActive then
            hardModeTimeLeft = hardModeTimeLeft - dt
            if hardModeTimeLeft <= 0 then
                hardModeTimeLeft = 0
                hardModeTimerActive = false
                if timerLabel then
                    timerLabel.Text = "0:00"
                    timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                end
                showWarning("TIME'S UP! You failed Hard Mode!", 5)
                if humanoid and humanoid.Health > 0 then
                    humanoid.Health = 0
                    onDeath()
                end
            else
                if timerLabel then
                    local mins = math.floor(hardModeTimeLeft / 60)
                    local secs = math.floor(hardModeTimeLeft % 60)
                    timerLabel.Text = string.format("%d:%02d", mins, secs)
                    -- Flash red when under 60 seconds
                    if hardModeTimeLeft <= 30 then
                        local flash = math.floor(tick() * 4) % 2 == 0
                        timerLabel.TextColor3 = flash and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 150, 150)
                    elseif hardModeTimeLeft <= 60 then
                        timerLabel.TextColor3 = Color3.fromRGB(255, 100, 60)
                    else
                        timerLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
                    end
                end
            end
        end

        -- Locker Freeze Logic (Snow White)
        if isHiding and snowWhiteActive then
            lockerTime = lockerTime + dt
            if lockerTime >= 5 then
                local freezeRatio = math.min(1, (lockerTime - 5) / 3)
                if freezeOverlay then
                    freezeOverlay.BackgroundTransparency = 1 - (freezeRatio * 0.8)
                end

                if lockerTime >= 5 and lockerTime - dt < 5 then
                    local fzSound = Instance.new("Sound", workspace)
                    fzSound.SoundId = "rbxassetid://124506007378500"
                    fzSound:Play()
                end

                if lockerTime >= 8 and not isDead then
                    humanoid.Health = 0
                    onDeath()
                end
            end
        else
            lockerTime = 0
            if freezeOverlay then freezeOverlay.BackgroundTransparency = 1 end
        end

        local hasFlashlight = character and character:FindFirstChild("Flashlight")
        if batteryGui then batteryGui.Visible = hasFlashlight ~= nil end
        if hasFlashlight then
            flashlightBattery = math.max(0, flashlightBattery - dt)
            batteryFill.Size = UDim2.new(flashlightBattery / 420, 0, 1, 0)
            local light = hasFlashlight.Handle:FindFirstChildOfClass("SpotLight")
            if light then light.Enabled = (flashlightBattery > 0) end
        end

        for _, bat in ipairs(workspace:GetDescendants()) do
            if bat.Name == "Battery" and bat:IsA("BasePart") then
                bat.Transparency = hasFlashlight and 0 or 1
                local p = bat:FindFirstChildOfClass("ProximityPrompt")
                if p then p.Enabled = hasFlashlight ~= nil end
            end
        end

        local playerPos = rootPart.Position
        local playerZ   = playerPos.Z
        local approxDoor = math.max(0, math.floor(-playerZ / ROOM_D + 0.5))
        if approxDoor > lastDetectedDoor and approxDoor <= DOOR_MAX then
            lastDetectedDoor = approxDoor
            onDoorReached(approxDoor)
        end

        nearLocker = false
        currentLocker = nil
        for d = currentDoor - 1, currentDoor + 1 do
            if rooms[d] then
                for _, part in ipairs(rooms[d]:GetDescendants()) do
                    if part:IsA("BasePart") and part:GetAttribute("IsLocker") then
                        if (playerPos - part.Position).Magnitude < LOCKER_DIST then
                            nearLocker = true
                            currentLocker = part
                        end
                    end
                end
            end
        end

        if hidePrompt then
            hidePrompt.Visible = (nearLocker and not isHiding) or isHiding
        end
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
