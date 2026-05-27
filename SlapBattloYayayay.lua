-- ============================================================
-- SLAP BATTLES - Full LocalScript
-- Version 2.0 | Updated with Acceleration Glove
-- Features: AI Bots, Glove System, Abilities, Combat, Acceleration
-- ============================================================

-- ============================================================
-- SERVICES
-- ============================================================
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local Debris             = game:GetService("Debris")
local UserInputService   = game:GetService("UserInputService")

-- ============================================================
-- LOCAL PLAYER REFERENCES
-- ============================================================
local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

-- ============================================================
-- GLOBAL CONFIGURATION
-- ============================================================
local CONFIG = {
    MAX_FAKE_PLAYERS   = 5,
    AGGRO_DISTANCE     = 100,
    SLAP_DISTANCE      = 5,
    RESPAWN_TIME       = 3,
    ARENA_SIZE         = 200,

    -- Acceleration Glove Config
    ACCEL_SPEED_GAIN_RATE       = 0.2,   -- seconds between speed ticks
    ACCEL_SPEED_PER_TICK        = 1,     -- speed added per tick
    ACCEL_MAX_SPEED             = 300,   -- hard cap
    ACCEL_BASE_SPEED            = 16,    -- roblox default walkspeed
    ACCEL_CRASH_STUN_DURATION   = 2,     -- seconds player can't move after crash
    ACCEL_DUMMY_CRASH_STUN      = 2,     -- seconds dummy can't move after crash
    ACCEL_CRASH_DISTANCE        = 5,     -- studs to detect crash into dummy
    ACCEL_DUMMY_CRASH_DISTANCE  = 5,     -- studs to detect dummy crash into player
}

-- ============================================================
-- GLOVE DATA TABLE
-- ============================================================
local GLOVE_DATA = {

    -- --------------------------------------------------------
    ["Default Glove"] = {
        PushPower      = 5,
        SlapCooldown   = 2,
        AbilityType    = "None",
        Ability        = nil,
        AbilityCooldown = 0,
        Color          = Color3.fromRGB(200, 200, 200),
        Description    = "A simple glove. No frills, no thrills.",
    },

    -- --------------------------------------------------------
    ["Siphon Glove"] = {
        PushPower      = 8,
        SlapCooldown   = 1.5,
        AbilityType    = "Ability",
        Ability        = "Siphon",
        AbilityCooldown = 15,
        Color          = Color3.fromRGB(0, 255, 255),
        Description    = "Pull everything toward you with a powerful beacon.",
    },

    -- --------------------------------------------------------
    ["Train Glove"] = {
        PushPower      = 7,
        SlapCooldown   = 2,
        AbilityType    = "Ability",
        Ability        = "Train",
        AbilityCooldown = 10,
        Color          = Color3.fromRGB(100, 100, 100),
        Description    = "Summon a train to bulldoze your target.",
    },

    -- --------------------------------------------------------
    ["Counter Glove"] = {
        PushPower      = 6,
        SlapCooldown   = 1.8,
        AbilityType    = "Ability",
        Ability        = "Counter",
        AbilityCooldown = 15,
        Color          = Color3.fromRGB(255, 0, 0),
        Description    = "Block an incoming slap and punish the attacker.",
    },

    -- --------------------------------------------------------
    ["God Glove"] = {
        PushPower      = 100,
        SlapCooldown   = 5,
        AbilityType    = "Fusion",
        Ability        = "TimeStop",
        AbilityCooldown = 60,
        Color          = Color3.fromRGB(255, 215, 0),
        Description    = "The ultimate glove. Stop time itself.",
    },

    -- --------------------------------------------------------
    ["RNG Glove"] = {
        PushPower      = 5,
        SlapCooldown   = 2,
        AbilityType    = "Passive",
        Ability        = "RandomDirection",
        AbilityCooldown = 0,
        Color          = Color3.fromRGB(255, 0, 255),
        Description    = "Slap in a completely random direction every time.",
    },

    -- --------------------------------------------------------
    ["LandMine Glove"] = {
        PushPower      = 5,
        SlapCooldown   = 1,
        AbilityType    = "Ability",
        Ability        = "LandMine",
        AbilityCooldown = 5,
        Color          = Color3.fromRGB(139, 69, 19),
        Description    = "Plant hidden mines across the arena.",
    },

    -- --------------------------------------------------------
    ["Engineer Glove"] = {
        PushPower       = 7,
        SlapCooldown    = 1.8,
        AbilityType     = "Ability",
        Ability         = "Engineer",
        AbilityCooldown  = 180,
        AbilityCooldown2 = 150,
        Color           = Color3.fromRGB(255, 140, 0),
        Description     = "Deploy turrets and roombas to fight for you.",
    },

    -- --------------------------------------------------------
    ["AirBomb Glove"] = {
        PushPower      = 8,
        SlapCooldown   = 2.5,
        AbilityType    = "Ability",
        Ability        = "AirBomb",
        AbilityCooldown = 25,
        Color          = Color3.fromRGB(135, 206, 235),
        Description    = "Call in an airstrike on a targeted enemy.",
    },

    -- --------------------------------------------------------
    ["Admin Glove"] = {
        PushPower      = 8,
        SlapCooldown   = 1.5,
        AbilityType    = "Ability",
        Ability        = "Admin",
        AbilityCooldown = 0,
        Color          = Color3.fromRGB(255, 255, 255),
        Description    = "Access powerful admin commands against opponents.",
    },

    -- --------------------------------------------------------
    ["Song Glove"] = {
        PushPower      = 0,
        SlapCooldown   = 0,
        AbilityType    = "Passive",
        Ability        = "Rhythm",
        AbilityCooldown = 0,
        Color          = Color3.fromRGB(255, 105, 180),
        Description    = "Play a rhythm game to create powerful forcefields.",
    },

    -- --------------------------------------------------------
    -- NEW: ACCELERATION GLOVE
    -- --------------------------------------------------------
    ["Acceleration Glove"] = {
        PushPower      = 6,
        SlapCooldown   = 1.5,
        AbilityType    = "Passive",
        Ability        = "Accelerate",
        AbilityCooldown = 0,
        Color          = Color3.fromRGB(255, 80, 0),
        Description    = "Gain speed the longer you move. Crash into enemies to fling them. Max speed: 300.",
    },

    -- --------------------------------------------------------
    -- NEW: PYROMANIA GLOVE
    -- --------------------------------------------------------
    ["Pyromania Glove"] = {
        PushPower       = 6,
        SlapCooldown    = 1.8,
        AbilityType     = "Ability",
        Ability         = "Gasoline",       -- 1st ability
        AbilityCooldown  = 20,              -- 1st ability cooldown
        Ability2         = "Ignite",        -- 2nd ability
        AbilityCooldown2 = 15,             -- 2nd ability cooldown
        Color           = Color3.fromRGB(255, 120, 0),
        Description     = "Leave a trail of gasoline, then ignite it. Enemies caught in flames take 5 dmg/s for 5s.",
    },
    -- --------------------------------------------------------
}

-- ============================================================
-- GAME STATE VARIABLES
-- ============================================================
local currentGlove        = "Default Glove"
local equippedGlove       = nil
local lastSlapTime        = 0
local lastAbilityTime     = 0
local lastAbility2Time    = 0
local isPlayerSitting     = false
local fakePlayersList     = {}
local aggroedFakePlayers  = {}
local isCounterActive     = false
local counterConnection   = nil
local isTimeStopActive    = false
local playerSlapCount     = 0
local activeLandmines     = {}
local activeTurrets       = {}
local activeRoombas       = {}
local airBombTargetingActive = false
local activeHighlights    = {}

-- ============================================================
-- ACCELERATION GLOVE STATE VARIABLES (PLAYER)
-- ============================================================
local accelCurrentSpeed       = CONFIG.ACCEL_BASE_SPEED  -- current walkspeed while glove equipped
local accelSpeedTickTimer     = 0                         -- timer counting up to SPEED_GAIN_RATE
local accelIsCrashStunned     = false                     -- true when player is stunned after crashing
local accelCrashStunEndTime   = 0                         -- tick() time when stun expires
local accelWasMovingLastFrame = false                     -- used to detect movement
local accelSpeedTickConnection = nil                      -- RunService connection for speed ticking
local accelCrashCheckConnection = nil                     -- RunService connection for crash detection

-- ============================================================
-- ADMIN COMMAND COOLDOWN TRACKING
-- ============================================================
local adminCommandCooldowns = {
    explode    = 0,
    speed      = 0,
    anvil      = 0,
    jumppower  = 0,
    bring      = 0,
    goto       = 0,
    train      = 0,
    freeze     = 0,
    ragdoll    = 0,
}

-- ============================================================
-- SONG GLOVE STATE
-- ============================================================
local songPlaying       = false
local songStartTime     = 0
local rhythmNotes       = {}
local rhythmGameActive  = false

-- ============================================================
-- SCREEN GUI ROOT
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "SlapBattlesUI"
screenGui.ResetOnSpawn  = false
screenGui.Parent        = player:WaitForChild("PlayerGui")

-- ============================================================
-- GLOVE MENU BUTTON
-- ============================================================
local gloveButton = Instance.new("TextButton")
gloveButton.Name             = "GloveButton"
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

-- ============================================================
-- GLOVE SELECTION FRAME
-- ============================================================
local gloveSelectionFrame = Instance.new("Frame")
gloveSelectionFrame.Name             = "GloveSelection"
gloveSelectionFrame.Size             = UDim2.new(0, 600, 0, 400)
gloveSelectionFrame.Position         = UDim2.new(0.5, -300, 0.5, -200)
gloveSelectionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
gloveSelectionFrame.BorderSizePixel  = 3
gloveSelectionFrame.BorderColor3     = Color3.fromRGB(255, 255, 255)
gloveSelectionFrame.Visible          = false
gloveSelectionFrame.Parent           = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size             = UDim2.new(1, 0, 0, 50)
titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleLabel.BorderSizePixel  = 0
titleLabel.Text             = "SELECT YOUR GLOVE"
titleLabel.TextColor3       = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled       = true
titleLabel.Font             = Enum.Font.GothamBold
titleLabel.Parent           = gloveSelectionFrame

local closeGloveSelBtn = Instance.new("TextButton")
closeGloveSelBtn.Size             = UDim2.new(0, 40, 0, 40)
closeGloveSelBtn.Position         = UDim2.new(1, -45, 0, 5)
closeGloveSelBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeGloveSelBtn.Text             = "X"
closeGloveSelBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeGloveSelBtn.TextScaled       = true
closeGloveSelBtn.Font             = Enum.Font.GothamBold
closeGloveSelBtn.Parent           = gloveSelectionFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size               = UDim2.new(1, -20, 1, -70)
scrollFrame.Position           = UDim2.new(0, 10, 0, 60)
scrollFrame.BackgroundColor3   = Color3.fromRGB(40, 40, 40)
scrollFrame.BorderSizePixel    = 2
scrollFrame.ScrollBarThickness = 10
scrollFrame.Parent             = gloveSelectionFrame

-- ============================================================
-- ABILITY BUTTONS
-- ============================================================
local abilityButton = Instance.new("TextButton")
abilityButton.Name             = "AbilityButton"
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

local ability2Button = Instance.new("TextButton")
ability2Button.Name             = "Ability2Button"
ability2Button.Size             = UDim2.new(0, 120, 0, 120)
ability2Button.Position         = UDim2.new(1, -270, 1, -260)
ability2Button.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
ability2Button.BorderSizePixel  = 3
ability2Button.BorderColor3     = Color3.fromRGB(255, 255, 255)
ability2Button.Text             = "ABILITY 2"
ability2Button.TextColor3       = Color3.fromRGB(255, 255, 255)
ability2Button.TextScaled       = true
ability2Button.Font             = Enum.Font.GothamBold
ability2Button.Visible          = false
ability2Button.Parent           = screenGui

-- ============================================================
-- SLAP BUTTON (mobile)
-- ============================================================
local slapButton = Instance.new("TextButton")
slapButton.Name             = "SlapButton"
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

-- ============================================================
-- ACCELERATION HUD (only visible when Acceleration Glove equipped)
-- ============================================================
local accelHudFrame = Instance.new("Frame")
accelHudFrame.Name             = "AccelHud"
accelHudFrame.Size             = UDim2.new(0, 320, 0, 72)
accelHudFrame.Position         = UDim2.new(0.5, -160, 1, -80)
accelHudFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
accelHudFrame.BorderSizePixel  = 2
accelHudFrame.BorderColor3     = Color3.fromRGB(255, 80, 0)
accelHudFrame.BackgroundTransparency = 0.3
accelHudFrame.Visible          = false
accelHudFrame.Parent           = screenGui

local accelHudTitle = Instance.new("TextLabel")
accelHudTitle.Size             = UDim2.new(1, 0, 0, 22)
accelHudTitle.BackgroundTransparency = 1
accelHudTitle.Text             = "ACCELERATION"
accelHudTitle.TextColor3       = Color3.fromRGB(255, 80, 0)
accelHudTitle.TextScaled       = true
accelHudTitle.Font             = Enum.Font.GothamBold
accelHudTitle.Parent           = accelHudFrame

local accelSpeedLabel = Instance.new("TextLabel")
accelSpeedLabel.Name                 = "SpeedLabel"
accelSpeedLabel.Size                 = UDim2.new(0.5, 0, 0, 22)
accelSpeedLabel.Position             = UDim2.new(0, 5, 0, 24)
accelSpeedLabel.BackgroundTransparency = 1
accelSpeedLabel.Text                 = "Speed: 16"
accelSpeedLabel.TextColor3           = Color3.fromRGB(255, 255, 255)
accelSpeedLabel.TextSize             = 14
accelSpeedLabel.Font                 = Enum.Font.Gotham
accelSpeedLabel.TextXAlignment       = Enum.TextXAlignment.Left
accelSpeedLabel.Parent               = accelHudFrame

local accelPowerLabel = Instance.new("TextLabel")
accelPowerLabel.Name                 = "PowerLabel"
accelPowerLabel.Size                 = UDim2.new(0.5, 0, 0, 22)
accelPowerLabel.Position             = UDim2.new(0.5, 0, 0, 24)
accelPowerLabel.BackgroundTransparency = 1
accelPowerLabel.Text                 = "Power: 6"
accelPowerLabel.TextColor3           = Color3.fromRGB(255, 200, 0)
accelPowerLabel.TextSize             = 14
accelPowerLabel.Font                 = Enum.Font.Gotham
accelPowerLabel.TextXAlignment       = Enum.TextXAlignment.Left
accelPowerLabel.Parent               = accelHudFrame

-- Speed bar background
local accelBarBg = Instance.new("Frame")
accelBarBg.Size             = UDim2.new(1, -10, 0, 14)
accelBarBg.Position         = UDim2.new(0, 5, 0, 50)
accelBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
accelBarBg.BorderSizePixel  = 1
accelBarBg.BorderColor3     = Color3.fromRGB(100, 100, 100)
accelBarBg.Parent           = accelHudFrame

-- Speed bar fill
local accelBarFill = Instance.new("Frame")
accelBarFill.Name             = "BarFill"
accelBarFill.Size             = UDim2.new(0, 0, 1, 0)
accelBarFill.BackgroundColor3 = Color3.fromRGB(255, 80, 0)
accelBarFill.BorderSizePixel  = 0
accelBarFill.Parent           = accelBarBg

-- Stun indicator label (shows "STUNNED" when crash stun active)
local accelStunLabel = Instance.new("TextLabel")
accelStunLabel.Name                 = "StunLabel"
accelStunLabel.Size                 = UDim2.new(0, 200, 0, 40)
accelStunLabel.Position             = UDim2.new(0.5, -100, 0.5, -20)
accelStunLabel.BackgroundColor3     = Color3.fromRGB(30, 0, 0)
accelStunLabel.BorderSizePixel      = 3
accelStunLabel.BorderColor3         = Color3.fromRGB(255, 0, 0)
accelStunLabel.Text                 = "CRASH STUNNED!"
accelStunLabel.TextColor3           = Color3.fromRGB(255, 80, 80)
accelStunLabel.TextScaled           = true
accelStunLabel.Font                 = Enum.Font.GothamBold
accelStunLabel.Visible              = false
accelStunLabel.Parent               = screenGui

-- ============================================================
-- UTILITY: GET ACCELERATION PUSH POWER FROM CURRENT SPEED
-- ============================================================
local function getAccelPushPower(speed)
    if speed >= 200 then
        return 12
    elseif speed >= 100 then
        return 8
    elseif speed >= 50 then
        return 5
    else
        return 3  -- below 50, still has some push from normal slap power
    end
end

-- ============================================================
-- UTILITY: UPDATE ACCELERATION HUD
-- ============================================================
local function updateAccelHud()
    if not accelHudFrame.Visible then return end

    local spd = accelCurrentSpeed
    local pwr = getAccelPushPower(spd)

    accelSpeedLabel.Text = string.format("Speed: %d / %d", math.floor(spd), CONFIG.ACCEL_MAX_SPEED)
    accelPowerLabel.Text = string.format("Power: %d", pwr)

    -- Update bar fill (0 to 1 scale from base to max)
    local ratio = math.clamp(
        (spd - CONFIG.ACCEL_BASE_SPEED) / (CONFIG.ACCEL_MAX_SPEED - CONFIG.ACCEL_BASE_SPEED),
        0, 1
    )
    accelBarFill.Size = UDim2.new(ratio, 0, 1, 0)

    -- Color shifts: green → yellow → orange → red as speed increases
    if ratio < 0.33 then
        accelBarFill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
    elseif ratio < 0.66 then
        accelBarFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    else
        accelBarFill.BackgroundColor3 = Color3.fromRGB(255, 50, 0)
    end
end

-- ============================================================
-- UTILITY: APPLY FORCE TO ANY CHARACTER
-- ============================================================
local function applyForce(targetCharacter, direction, power)
    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then
        return
    end

    local targetRoot     = targetCharacter.HumanoidRootPart
    local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")

    if targetHumanoid then
        targetHumanoid.Sit = true
    end

    local bodyVelocity             = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce          = Vector3.new(4e4, 4e4, 4e4)
    bodyVelocity.Velocity          = direction * power * 10 + Vector3.new(0, power * 5, 0)
    bodyVelocity.Parent            = targetRoot

    Debris:AddItem(bodyVelocity, 0.3)

    wait(0.3)
    if targetHumanoid and targetHumanoid.Sit then
        local conn
        conn = targetRoot.Touched:Connect(function(hit)
            if hit:IsA("BasePart") and not hit:IsDescendantOf(targetCharacter) then
                wait(0.1)
                targetHumanoid.Sit = false
                if conn then conn:Disconnect() end
            end
        end)
    end
end

-- ============================================================
-- UTILITY: VISUAL SLAP EFFECT
-- ============================================================
local function createSlapEffect(position, color)
    local part             = Instance.new("Part")
    part.Shape             = Enum.PartType.Ball
    part.Size              = Vector3.new(2, 2, 2)
    part.Position          = position
    part.Anchored          = true
    part.CanCollide        = false
    part.Material          = Enum.Material.Neon
    part.Color             = color
    part.Transparency      = 0.3
    part.Parent            = workspace

    local tween = TweenService:Create(part, TweenInfo.new(0.3), {
        Size         = Vector3.new(5, 5, 5),
        Transparency = 1,
    })
    tween:Play()

    Debris:AddItem(part, 0.5)
end

-- ============================================================
-- UTILITY: CHAT NOTIFICATION (admin / fake player)
-- ============================================================
local function sendAdminChat(message)
    local chatLabel                  = Instance.new("TextLabel")
    chatLabel.Size                   = UDim2.new(0, 400, 0, 30)
    chatLabel.Position               = UDim2.new(0, 20, 0, 100)
    chatLabel.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    chatLabel.BackgroundTransparency = 0.5
    chatLabel.BorderSizePixel        = 2
    chatLabel.BorderColor3           = Color3.fromRGB(255, 255, 255)
    chatLabel.Text                   = message
    chatLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
    chatLabel.TextSize               = 18
    chatLabel.Font                   = Enum.Font.Gotham
    chatLabel.TextXAlignment         = Enum.TextXAlignment.Left
    chatLabel.Parent                 = screenGui

    spawn(function()
        wait(3)
        chatLabel:Destroy()
    end)
end

local function sendFakePlayerChat(fakePlayerName, message)
    local chatLabel                  = Instance.new("TextLabel")
    chatLabel.Size                   = UDim2.new(0, 450, 0, 35)
    chatLabel.Position               = UDim2.new(0, 20, 0, 140)
    chatLabel.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
    chatLabel.BackgroundTransparency = 0.3
    chatLabel.BorderSizePixel        = 2
    chatLabel.BorderColor3           = Color3.fromRGB(100, 150, 255)
    chatLabel.Text                   = "[" .. fakePlayerName .. "]: " .. message
    chatLabel.TextColor3             = Color3.fromRGB(200, 220, 255)
    chatLabel.TextSize               = 16
    chatLabel.Font                   = Enum.Font.Gotham
    chatLabel.TextXAlignment         = Enum.TextXAlignment.Left
    chatLabel.Parent                 = screenGui

    spawn(function()
        wait(4)
        chatLabel:Destroy()
    end)
end

-- ============================================================
-- UTILITY: ABILITY NOTIFICATION POPUP
-- ============================================================
local function createAbilityNotification(abilityName, color)
    local notifColor = color or Color3.fromRGB(255, 255, 0)

    local notification             = Instance.new("Frame")
    notification.Size              = UDim2.new(0, 320, 0, 60)
    notification.Position          = UDim2.new(0.5, -160, 0, -80)
    notification.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
    notification.BorderSizePixel   = 3
    notification.BorderColor3      = notifColor
    notification.Parent            = screenGui

    local textLabel                = Instance.new("TextLabel")
    textLabel.Size                 = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text                 = abilityName .. " ACTIVATED!"
    textLabel.TextColor3           = notifColor
    textLabel.TextScaled           = true
    textLabel.Font                 = Enum.Font.GothamBold
    textLabel.Parent               = notification

    local tweenIn = TweenService:Create(notification, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Position = UDim2.new(0.5, -160, 0, 20),
    })
    tweenIn:Play()

    wait(2)

    local tweenOut = TweenService:Create(notification, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Position          = UDim2.new(0.5, -160, 0, -80),
        BackgroundTransparency = 1,
    })
    tweenOut:Play()

    wait(0.25)
    notification:Destroy()
end

-- ============================================================
-- COUNTER PUNISHMENT
-- ============================================================
local function triggerCounterPunishment(attacker)
    if not attacker
    or not attacker:FindFirstChild("HumanoidRootPart")
    or not attacker:FindFirstChild("Humanoid") then
        return
    end

    local attackerRoot     = attacker.HumanoidRootPart
    local attackerHumanoid = attacker.Humanoid
    local originalSpeed    = attackerHumanoid.WalkSpeed

    attackerHumanoid.WalkSpeed = 0

    local warningLight         = Instance.new("PointLight")
    warningLight.Color         = Color3.fromRGB(255, 255, 0)
    warningLight.Brightness    = 5
    warningLight.Range         = 10
    warningLight.Parent        = attackerRoot

    local anvilSpawnPos = attackerRoot.Position + Vector3.new(0, 20, 0)

    local anvil          = Instance.new("Part")
    anvil.Name           = "Anvil"
    anvil.Size           = Vector3.new(3, 2, 3)
    anvil.Position       = anvilSpawnPos
    anvil.Anchored       = true
    anvil.CanCollide     = false
    anvil.Material       = Enum.Material.Metal
    anvil.Color          = Color3.fromRGB(80, 80, 80)
    anvil.Parent         = workspace

    local mesh       = Instance.new("BlockMesh")
    mesh.Scale       = Vector3.new(1, 0.7, 1)
    mesh.Parent      = anvil

    wait(0.3)

    anvil.Anchored   = false
    local bv         = Instance.new("BodyVelocity")
    bv.MaxForce      = Vector3.new(0, 4e4, 0)
    bv.Velocity      = Vector3.new(0, -100, 0)
    bv.Parent        = anvil

    local hitConn
    hitConn = anvil.Touched:Connect(function(hit)
        if hit.Parent == attacker or hit == attackerRoot then
            applyForce(attacker, Vector3.new(0, -1, 0), 50)

            local impactFx          = Instance.new("Part")
            impactFx.Shape          = Enum.PartType.Ball
            impactFx.Size           = Vector3.new(1, 1, 1)
            impactFx.Position       = attackerRoot.Position
            impactFx.Anchored       = true
            impactFx.CanCollide     = false
            impactFx.Material       = Enum.Material.Neon
            impactFx.Color          = Color3.fromRGB(255, 255, 0)
            impactFx.Transparency   = 0.3
            impactFx.Parent         = workspace

            TweenService:Create(impactFx, TweenInfo.new(0.5), {
                Size         = Vector3.new(10, 10, 10),
                Transparency = 1,
            }):Play()
            Debris:AddItem(impactFx, 0.5)

            attackerHumanoid.WalkSpeed = originalSpeed
            if warningLight.Parent then warningLight:Destroy() end
            if hitConn then hitConn:Disconnect() end
            Debris:AddItem(anvil, 1)
        end
    end)

    spawn(function()
        wait(3)
        if hitConn then hitConn:Disconnect() end
        if anvil.Parent then anvil:Destroy() end
        if warningLight.Parent then warningLight:Destroy() end
        attackerHumanoid.WalkSpeed = originalSpeed
    end)
end

-- ============================================================
-- PLAYER SLAP FUNCTION (forward declaration so we can wrap it)
-- ============================================================
local playerSlap  -- defined below

-- ============================================================
-- SIPHON ABILITY
-- ============================================================
local function activateSiphonAbility(caster, isPlayer)
    local casterRoot
    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        casterRoot = character.HumanoidRootPart
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then return end
        casterRoot = caster.character.HumanoidRootPart
    end

    local beaconPos = casterRoot.Position + Vector3.new(0, 2, 0)

    local beacon            = Instance.new("Part")
    beacon.Shape            = Enum.PartType.Cylinder
    beacon.Size             = Vector3.new(2, 3, 3)
    beacon.Position         = beaconPos
    beacon.Anchored         = true
    beacon.CanCollide       = false
    beacon.Material         = Enum.Material.Neon
    beacon.Color            = Color3.fromRGB(0, 255, 255)
    beacon.Orientation      = Vector3.new(0, 0, 90)
    beacon.Parent           = workspace

    local ff                = Instance.new("Part")
    ff.Shape                = Enum.PartType.Ball
    ff.Size                 = Vector3.new(40, 40, 40)
    ff.Position             = beaconPos
    ff.Anchored             = true
    ff.CanCollide           = false
    ff.Material             = Enum.Material.ForceField
    ff.Color                = Color3.fromRGB(0, 255, 255)
    ff.Transparency         = 0.7
    ff.Parent               = workspace

    local duration  = 4
    local startTime = tick()

    local siphonConn
    siphonConn = RunService.Heartbeat:Connect(function()
        if tick() - startTime >= duration then
            siphonConn:Disconnect()
            if beacon.Parent then beacon:Destroy() end
            if ff.Parent then ff:Destroy() end
            return
        end

        local function pullTarget(targetRoot)
            local dist = (targetRoot.Position - beaconPos).Magnitude
            if dist <= 20 then
                local dir = (beaconPos - targetRoot.Position).Unit
                local existing = targetRoot:FindFirstChild("SiphonVelocity")
                if existing then existing:Destroy() end
                local pf           = Instance.new("BodyVelocity")
                pf.Name            = "SiphonVelocity"
                pf.MaxForce        = Vector3.new(5000, 5000, 5000)
                pf.Velocity        = dir * 60
                pf.Parent          = targetRoot
                Debris:AddItem(pf, 0.15)
            end
        end

        if not isPlayer then
            if character and character:FindFirstChild("HumanoidRootPart") then
                pullTarget(character.HumanoidRootPart)
            end
        else
            for _, fp in ipairs(fakePlayersList) do
                if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                    pullTarget(fp.character.HumanoidRootPart)
                end
            end
        end
    end)

    spawn(function()
        wait(duration)
        if siphonConn then siphonConn:Disconnect() end
        if beacon.Parent then beacon:Destroy() end
        if ff.Parent then ff:Destroy() end

        local function cleanup(root)
            if root then
                local v = root:FindFirstChild("SiphonVelocity")
                if v then v:Destroy() end
            end
        end

        if isPlayer then
            for _, fp in ipairs(fakePlayersList) do
                if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                    cleanup(fp.character.HumanoidRootPart)
                end
            end
        else
            if character and character:FindFirstChild("HumanoidRootPart") then
                cleanup(character.HumanoidRootPart)
            end
        end
    end)
end

-- ============================================================
-- TRAIN ABILITY
-- ============================================================
local function activateTrainAbility(caster, isPlayer)
    local casterRoot
    local targetCharacter

    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        casterRoot = character.HumanoidRootPart
        local nearestDist = math.huge
        for _, fp in ipairs(fakePlayersList) do
            if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                local d = (fp.character.HumanoidRootPart.Position - casterRoot.Position).Magnitude
                if d < nearestDist then
                    nearestDist     = d
                    targetCharacter = fp.character
                end
            end
        end
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then return end
        casterRoot      = caster.character.HumanoidRootPart
        targetCharacter = character
    end

    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then return end

    local targetRoot  = targetCharacter.HumanoidRootPart
    local direction   = (targetRoot.Position - casterRoot.Position).Unit
    local spawnPos    = targetRoot.Position - direction * 100

    local train           = Instance.new("Part")
    train.Size            = Vector3.new(8, 6, 12)
    train.Position        = spawnPos + Vector3.new(0, 3, 0)
    train.Anchored        = true
    train.CanCollide      = true
    train.Material        = Enum.Material.Metal
    train.Color           = Color3.fromRGB(100, 100, 100)
    train.Parent          = workspace

    local light           = Instance.new("PointLight")
    light.Color           = Color3.fromRGB(255, 255, 0)
    light.Brightness      = 5
    light.Range           = 30
    light.Parent          = train

    local startTime   = tick()
    local maxDuration = 10
    local hitDone     = false

    local trainConn
    trainConn = RunService.Heartbeat:Connect(function()
        if not train.Parent or not targetRoot.Parent then
            if trainConn then trainConn:Disconnect() end
            if train.Parent then train:Destroy() end
            return
        end

        local elapsed = tick() - startTime
        if elapsed >= maxDuration then
            trainConn:Disconnect()
            train:Destroy()
            return
        end

        local speed  = math.min(10 + elapsed * 12, 100)
        local newDir = (targetRoot.Position - train.Position).Unit
        local dt     = RunService.Heartbeat:Wait()
        train.CFrame = CFrame.new(train.Position + newDir * speed * dt) * CFrame.lookAt(Vector3.new(), newDir)

        if not hitDone then
            local dist = (train.Position - targetRoot.Position).Magnitude
            if dist <= 8 then
                hitDone  = true
                local hDir = (targetRoot.Position - train.Position).Unit
                applyForce(targetCharacter, hDir, 12)

                local explosion            = Instance.new("Explosion")
                explosion.Position         = train.Position
                explosion.BlastRadius      = 10
                explosion.BlastPressure    = 0
                explosion.Parent           = workspace

                trainConn:Disconnect()
                train:Destroy()
            end
        end
    end)

    spawn(function()
        wait(maxDuration)
        if trainConn then trainConn:Disconnect() end
        if train.Parent then train:Destroy() end
    end)
end

-- ============================================================
-- COUNTER ABILITY
-- ============================================================
local function activateCounterAbility(caster, isPlayer)
    local casterRoot
    local casterHumanoid

    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") or not humanoid then return end
        casterRoot     = character.HumanoidRootPart
        casterHumanoid = humanoid
        isCounterActive = true
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then return end
        casterRoot          = caster.character.HumanoidRootPart
        casterHumanoid      = caster.humanoid
        caster.isCounterActive = true
    end

    local redLight           = Instance.new("PointLight")
    redLight.Name            = "CounterLight"
    redLight.Color           = Color3.fromRGB(255, 0, 0)
    redLight.Brightness      = 10
    redLight.Range           = 15
    redLight.Parent          = casterRoot

    local sphere             = Instance.new("Part")
    sphere.Name              = "CounterSphere"
    sphere.Shape             = Enum.PartType.Ball
    sphere.Size              = Vector3.new(8, 8, 8)
    sphere.Position          = casterRoot.Position
    sphere.Anchored          = true
    sphere.CanCollide        = false
    sphere.Material          = Enum.Material.Neon
    sphere.Color             = Color3.fromRGB(255, 0, 0)
    sphere.Transparency      = 0.5
    sphere.Parent            = workspace

    local origSpeed          = casterHumanoid.WalkSpeed
    casterHumanoid.WalkSpeed = 0

    local sphConn
    sphConn = RunService.Heartbeat:Connect(function()
        if sphere.Parent and casterRoot.Parent then
            sphere.Position = casterRoot.Position
        else
            if sphConn then sphConn:Disconnect() end
        end
    end)

    wait(1)

    casterHumanoid.WalkSpeed = origSpeed
    if redLight.Parent  then redLight:Destroy() end
    if sphere.Parent    then sphere:Destroy() end
    if sphConn          then sphConn:Disconnect() end

    if isPlayer then
        isCounterActive = false
    else
        caster.isCounterActive = false
    end
end

-- ============================================================
-- TIME STOP ABILITY (God Glove)
-- ============================================================
local function activateTimeStopAbility()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    isTimeStopActive = true

    local colorFx             = Instance.new("ColorCorrectionEffect")
    colorFx.Name              = "TimeStopEffect"
    colorFx.Saturation        = -1
    colorFx.TintColor         = Color3.fromRGB(150, 150, 150)
    colorFx.Parent            = game.Lighting

    local tsSound             = Instance.new("Sound")
    tsSound.SoundId           = "rbxassetid://5153845714"
    tsSound.Volume            = 0.7
    tsSound.Parent            = workspace
    tsSound:Play()
    Debris:AddItem(tsSound, 3)

    local tsLabel             = Instance.new("TextLabel")
    tsLabel.Size              = UDim2.new(0, 400, 0, 80)
    tsLabel.Position          = UDim2.new(0.5, -200, 0.1, 0)
    tsLabel.BackgroundTransparency = 1
    tsLabel.Text              = "TIME STOPPED"
    tsLabel.TextColor3        = Color3.fromRGB(255, 215, 0)
    tsLabel.TextScaled        = true
    tsLabel.Font              = Enum.Font.GothamBold
    tsLabel.TextStrokeTransparency = 0
    tsLabel.TextStrokeColor3  = Color3.fromRGB(0, 0, 0)
    tsLabel.Parent            = screenGui

    local frozenData = {}

    for _, fp in ipairs(fakePlayersList) do
        if fp.character and fp.humanoid and fp.rootPart then
            local origSpeed = fp.humanoid.WalkSpeed
            table.insert(frozenData, { fakePlayer = fp, originalSpeed = origSpeed })

            fp.humanoid.WalkSpeed = 0
            fp.humanoid.JumpPower = 0

            local fxIce             = Instance.new("Part")
            fxIce.Name              = "FreezeEffect"
            fxIce.Size              = Vector3.new(4, 6, 4)
            fxIce.Position          = fp.rootPart.Position
            fxIce.Anchored          = true
            fxIce.CanCollide        = false
            fxIce.Material          = Enum.Material.Ice
            fxIce.Color             = Color3.fromRGB(150, 200, 255)
            fxIce.Transparency      = 0.5
            fxIce.Parent            = fp.character

            local iceConn
            iceConn = RunService.Heartbeat:Connect(function()
                if fxIce.Parent and fp.rootPart.Parent then
                    fxIce.Position = fp.rootPart.Position
                else
                    if iceConn then iceConn:Disconnect() end
                end
            end)

            fp.freezeConnection = iceConn
            fp.freezeEffect     = fxIce
        end
    end

    for i = 10, 1, -1 do
        wait(1)
        tsLabel.Text = "TIME STOPPED - " .. i
    end

    wait(1)
    isTimeStopActive = false

    if colorFx.Parent then colorFx:Destroy() end

    for _, data in ipairs(frozenData) do
        local fp = data.fakePlayer
        if fp.humanoid then
            fp.humanoid.WalkSpeed = data.originalSpeed
            fp.humanoid.JumpPower = 50
        end
        if fp.freezeEffect and fp.freezeEffect.Parent then fp.freezeEffect:Destroy() end
        if fp.freezeConnection then fp.freezeConnection:Disconnect() end
    end

    tsLabel.Text = "TIME RESUMED"
    wait(1)
    tsLabel:Destroy()
end

-- ============================================================
-- LANDMINE ABILITY
-- ============================================================
local function activateLandMineAbility(caster, isPlayer)
    local casterRoot
    local minePosition

    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        casterRoot   = character.HumanoidRootPart
        minePosition = casterRoot.Position
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then return end
        casterRoot = caster.character.HumanoidRootPart
        if character and character:FindFirstChild("HumanoidRootPart") then
            local playerRoot     = character.HumanoidRootPart
            local dirToPlayer    = (playerRoot.Position - casterRoot.Position).Unit
            local randomDist     = math.random(30, 50)
            minePosition         = playerRoot.Position - dirToPlayer * randomDist
            minePosition         = Vector3.new(minePosition.X, 0.5, minePosition.Z)
        else
            return
        end
    end

    local mine             = Instance.new("Part")
    mine.Name              = "Landmine"
    mine.Size              = Vector3.new(4, 0.5, 4)
    mine.Position          = minePosition
    mine.Anchored          = true
    mine.CanCollide        = false
    mine.Material          = Enum.Material.Metal
    mine.Color             = Color3.fromRGB(139, 69, 19)
    mine.Transparency      = 0
    mine.Parent            = workspace

    local decal        = Instance.new("Decal")
    decal.Texture      = "rbxasset://textures/face.png"
    decal.Face         = Enum.NormalId.Top
    decal.Parent       = mine

    local mineLight        = Instance.new("PointLight")
    mineLight.Color        = Color3.fromRGB(255, 0, 0)
    mineLight.Brightness   = 2
    mineLight.Range        = 10
    mineLight.Parent       = mine

    local mineData = { mine = mine, owner = isPlayer and "player" or caster, isPlayerOwned = isPlayer }
    table.insert(activeLandmines, mineData)

    wait(2)
    if mine.Parent then
        TweenService:Create(mine, TweenInfo.new(0.5), { Transparency = 0.8 }):Play()
        mineLight.Brightness = 0.5
    end

    local triggerConn
    triggerConn = RunService.Heartbeat:Connect(function()
        if not mine.Parent then
            triggerConn:Disconnect()
            return
        end

        local function explodeMine(targetChar)
            local explosion            = Instance.new("Explosion")
            explosion.Position         = mine.Position
            explosion.BlastRadius      = 8
            explosion.BlastPressure    = 0
            explosion.Parent           = workspace

            applyForce(targetChar, Vector3.new(0, 1, 0), 9)

            triggerConn:Disconnect()
            mine:Destroy()

            for idx, data in ipairs(activeLandmines) do
                if data.mine == mine then
                    table.remove(activeLandmines, idx)
                    break
                end
            end
        end

        if not isPlayer then
            if character and character:FindFirstChild("HumanoidRootPart") then
                if (character.HumanoidRootPart.Position - mine.Position).Magnitude <= 3 then
                    explodeMine(character)
                end
            end
        else
            for _, fp in ipairs(fakePlayersList) do
                if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                    if (fp.character.HumanoidRootPart.Position - mine.Position).Magnitude <= 3 then
                        explodeMine(fp.character)
                        break
                    end
                end
            end
        end
    end)

    spawn(function()
        wait(30)
        if triggerConn then triggerConn:Disconnect() end
        if mine.Parent then mine:Destroy() end
        for idx, data in ipairs(activeLandmines) do
            if data.mine == mine then
                table.remove(activeLandmines, idx)
                break
            end
        end
    end)
end

-- ============================================================
-- AIRBOMB ABILITY
-- ============================================================
local function activateAirBombAbility(caster, isPlayer, targetOverride)
    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        for _, h in ipairs(activeHighlights) do
            if h.Parent then h:Destroy() end
        end
        activeHighlights = {}

        airBombTargetingActive = true

        for _, fp in ipairs(fakePlayersList) do
            if fp.character then
                local hl                 = Instance.new("Highlight")
                hl.FillColor             = Color3.fromRGB(135, 206, 235)
                hl.OutlineColor          = Color3.fromRGB(255, 255, 0)
                hl.FillTransparency      = 0.5
                hl.OutlineTransparency   = 0
                hl.Parent                = fp.character
                table.insert(activeHighlights, hl)

                local cd                 = Instance.new("ClickDetector")
                cd.MaxActivationDistance = 100
                cd.Parent                = fp.character.HumanoidRootPart

                cd.MouseClick:Connect(function()
                    if not airBombTargetingActive then return end
                    airBombTargetingActive = false

                    for _, h2 in ipairs(activeHighlights) do
                        if h2.Parent ~= fp.character and h2.Parent then h2:Destroy() end
                    end

                    for _, fp2 in ipairs(fakePlayersList) do
                        if fp2.character and fp2.character:FindFirstChild("HumanoidRootPart") then
                            local cd2 = fp2.character.HumanoidRootPart:FindFirstChild("ClickDetector")
                            if cd2 then cd2:Destroy() end
                        end
                    end

                    spawn(function()
                        wait(3)
                        if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                            local tRoot      = fp.character.HumanoidRootPart
                            local bSpawn     = tRoot.Position + Vector3.new(0, 50, 0)

                            local bomb           = Instance.new("Part")
                            bomb.Name            = "AirBomb"
                            bomb.Shape           = Enum.PartType.Ball
                            bomb.Size            = Vector3.new(3, 3, 3)
                            bomb.Position        = bSpawn
                            bomb.Anchored        = true
                            bomb.CanCollide      = false
                            bomb.Material        = Enum.Material.Neon
                            bomb.Color           = Color3.fromRGB(255, 0, 0)
                            bomb.Parent          = workspace

                            local trail          = Instance.new("Trail")
                            local a0             = Instance.new("Attachment")
                            local a1             = Instance.new("Attachment")
                            a0.Position          = Vector3.new(0, 1, 0)
                            a1.Position          = Vector3.new(0, -1, 0)
                            a0.Parent            = bomb
                            a1.Parent            = bomb
                            trail.Attachment0    = a0
                            trail.Attachment1    = a1
                            trail.Color          = ColorSequence.new(Color3.fromRGB(255, 100, 0))
                            trail.Lifetime       = 0.5
                            trail.Parent         = bomb

                            local st  = tick()
                            local dur = 1.5
                            while tick() - st < dur do
                                local prog   = (tick() - st) / dur
                                bomb.Position = bSpawn:Lerp(tRoot.Position, prog)
                                RunService.Heartbeat:Wait()
                            end

                            local exp              = Instance.new("Explosion")
                            exp.Position           = tRoot.Position
                            exp.BlastRadius        = 10
                            exp.BlastPressure      = 0
                            exp.Parent             = workspace

                            local rA = math.random() * math.pi * 2
                            local rE = (math.random() - 0.5) * math.pi * 0.5
                            local dir = Vector3.new(
                                math.cos(rA) * math.cos(rE),
                                math.sin(rE),
                                math.sin(rA) * math.cos(rE)
                            ).Unit
                            applyForce(fp.character, dir, 15)
                            bomb:Destroy()
                        end

                        for _, h2 in ipairs(activeHighlights) do
                            if h2.Parent then h2:Destroy() end
                        end
                        activeHighlights = {}
                    end)
                end)
            end
        end

        spawn(function()
            wait(10)
            if airBombTargetingActive then
                airBombTargetingActive = false
                for _, h in ipairs(activeHighlights) do
                    if h.Parent then h:Destroy() end
                end
                activeHighlights = {}
                for _, fp in ipairs(fakePlayersList) do
                    if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                        local cd2 = fp.character.HumanoidRootPart:FindFirstChild("ClickDetector")
                        if cd2 then cd2:Destroy() end
                    end
                end
            end
        end)
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then return end
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        local playerRoot = character.HumanoidRootPart
        local dist       = (playerRoot.Position - caster.character.HumanoidRootPart.Position).Magnitude

        if dist < 75 or dist > 100 then return end

        local hl                 = Instance.new("Highlight")
        hl.FillColor             = Color3.fromRGB(135, 206, 235)
        hl.OutlineColor          = Color3.fromRGB(255, 255, 0)
        hl.FillTransparency      = 0.5
        hl.OutlineTransparency   = 0
        hl.Parent                = character

        spawn(function()
            wait(3)
            if character and playerRoot.Parent then
                local bSpawn = playerRoot.Position + Vector3.new(0, 50, 0)

                local bomb           = Instance.new("Part")
                bomb.Name            = "AirBomb"
                bomb.Shape           = Enum.PartType.Ball
                bomb.Size            = Vector3.new(3, 3, 3)
                bomb.Position        = bSpawn
                bomb.Anchored        = true
                bomb.CanCollide      = false
                bomb.Material        = Enum.Material.Neon
                bomb.Color           = Color3.fromRGB(255, 0, 0)
                bomb.Parent          = workspace

                local st  = tick()
                local dur = 1.5
                while tick() - st < dur do
                    local prog    = (tick() - st) / dur
                    bomb.Position = bSpawn:Lerp(playerRoot.Position, prog)
                    RunService.Heartbeat:Wait()
                end

                local exp              = Instance.new("Explosion")
                exp.Position           = playerRoot.Position
                exp.BlastRadius        = 10
                exp.BlastPressure      = 0
                exp.Parent             = workspace

                local rA  = math.random() * math.pi * 2
                local rE  = (math.random() - 0.5) * math.pi * 0.5
                local dir = Vector3.new(
                    math.cos(rA) * math.cos(rE),
                    math.sin(rE),
                    math.sin(rA) * math.cos(rE)
                ).Unit
                applyForce(character, dir, 15)
                bomb:Destroy()
            end
            if hl.Parent then hl:Destroy() end
        end)
    end
end

-- ============================================================
-- ENGINEER TURRET ABILITY
-- ============================================================
local function activateEngineerTurret(caster, isPlayer)
    local casterRoot

    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        casterRoot = character.HumanoidRootPart
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then return end
        casterRoot = caster.character.HumanoidRootPart
    end

    local turretPos = casterRoot.Position + Vector3.new(0, 0, 5)

    local tBase          = Instance.new("Part")
    tBase.Name           = "TurretBase"
    tBase.Size           = Vector3.new(3, 1, 3)
    tBase.Position       = turretPos
    tBase.Anchored       = true
    tBase.CanCollide     = true
    tBase.Material       = Enum.Material.Metal
    tBase.Color          = Color3.fromRGB(100, 100, 100)
    tBase.Parent         = workspace

    local tHead          = Instance.new("Part")
    tHead.Name           = "TurretHead"
    tHead.Size           = Vector3.new(2, 2, 2)
    tHead.Position       = turretPos + Vector3.new(0, 1.5, 0)
    tHead.Anchored       = true
    tHead.CanCollide     = false
    tHead.Material       = Enum.Material.Metal
    tHead.Color          = Color3.fromRGB(255, 140, 0)
    tHead.Parent         = workspace

    local barrel         = Instance.new("Part")
    barrel.Name          = "Barrel"
    barrel.Size          = Vector3.new(0.5, 0.5, 2)
    barrel.Position      = tHead.Position + Vector3.new(0, 0, 1)
    barrel.Anchored      = true
    barrel.CanCollide    = false
    barrel.Material      = Enum.Material.Metal
    barrel.Color         = Color3.fromRGB(50, 50, 50)
    barrel.Parent        = tHead

    local turretData = {
        base          = tBase,
        head          = tHead,
        barrel        = barrel,
        health        = 30,
        owner         = isPlayer and "player" or caster,
        isPlayerOwned = isPlayer,
        lastShootTime = 0,
    }
    table.insert(activeTurrets, turretData)

    local shootConn
    shootConn = RunService.Heartbeat:Connect(function()
        if not tHead.Parent or turretData.health <= 0 then
            shootConn:Disconnect()
            if tBase.Parent then tBase:Destroy() end
            if tHead.Parent then tHead:Destroy() end
            for i, t in ipairs(activeTurrets) do
                if t == turretData then table.remove(activeTurrets, i) break end
            end
            return
        end

        local currentTime = tick()
        if currentTime - turretData.lastShootTime < 5 then return end

        local nearestTarget, nearestDist = nil, math.huge

        if isPlayer then
            for _, fp in ipairs(fakePlayersList) do
                if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                    local d = (fp.character.HumanoidRootPart.Position - tHead.Position).Magnitude
                    if d < nearestDist then nearestDist = d; nearestTarget = fp.character end
                end
            end
        else
            if character and character:FindFirstChild("HumanoidRootPart") then
                nearestTarget = character
            end
        end

        if nearestTarget and nearestTarget:FindFirstChild("HumanoidRootPart") then
            local tRoot    = nearestTarget.HumanoidRootPart
            local lookDir  = (tRoot.Position - tHead.Position).Unit
            tHead.CFrame   = CFrame.lookAt(tHead.Position, tRoot.Position)
            barrel.CFrame  = CFrame.lookAt(barrel.Position, tRoot.Position) * CFrame.new(0, 0, -1)

            turretData.lastShootTime = currentTime

            local bullet         = Instance.new("Part")
            bullet.Name          = "TurretBullet"
            bullet.Size          = Vector3.new(0.5, 0.5, 1)
            bullet.Position      = barrel.Position + lookDir * 2
            bullet.Anchored      = false
            bullet.CanCollide    = false
            bullet.Material      = Enum.Material.Neon
            bullet.Color         = Color3.fromRGB(255, 255, 0)
            bullet.Parent        = workspace

            local bv             = Instance.new("BodyVelocity")
            bv.MaxForce          = Vector3.new(4e4, 4e4, 4e4)
            bv.Velocity          = lookDir * 80
            bv.Parent            = bullet

            local hitConn
            hitConn = RunService.Heartbeat:Connect(function()
                if not bullet.Parent then hitConn:Disconnect() return end
                if nearestTarget and nearestTarget:FindFirstChild("HumanoidRootPart") then
                    if (nearestTarget.HumanoidRootPart.Position - bullet.Position).Magnitude <= 3 then
                        applyForce(nearestTarget, (nearestTarget.HumanoidRootPart.Position - bullet.Position).Unit, 5)
                        if not isPlayer then
                            if not table.find(aggroedFakePlayers, caster) then
                                table.insert(aggroedFakePlayers, caster)
                                caster.isAggro      = true
                                caster.aggroTarget  = "turret"
                                caster.aggroTurret  = turretData
                            end
                        end
                        hitConn:Disconnect()
                        bullet:Destroy()
                    end
                end
            end)

            Debris:AddItem(bullet, 3)
        end
    end)

    spawn(function()
        wait(120)
        if shootConn then shootConn:Disconnect() end
        if tBase.Parent then tBase:Destroy() end
        if tHead.Parent then tHead:Destroy() end
        for i, t in ipairs(activeTurrets) do
            if t == turretData then table.remove(activeTurrets, i) break end
        end
    end)
end

-- ============================================================
-- ENGINEER ROOMBAS ABILITY
-- ============================================================
local function activateEngineerRoombas(caster, isPlayer)
    local casterRoot

    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        casterRoot = character.HumanoidRootPart
    else
        if not caster.character or not caster.character:FindFirstChild("HumanoidRootPart") then return end
        casterRoot = caster.character.HumanoidRootPart
    end

    for i = 1, 3 do
        local angle      = (i - 1) * (math.pi * 2 / 3)
        local offset     = Vector3.new(math.cos(angle) * 5, 0, math.sin(angle) * 5)
        local rPos       = casterRoot.Position + offset

        local roomba         = Instance.new("Part")
        roomba.Name          = "Roomba"
        roomba.Shape         = Enum.PartType.Cylinder
        roomba.Size          = Vector3.new(1, 2, 2)
        roomba.Position      = rPos
        roomba.Anchored      = false
        roomba.CanCollide    = true
        roomba.Material      = Enum.Material.Plastic
        roomba.Color         = Color3.fromRGB(100, 200, 255)
        roomba.Orientation   = Vector3.new(0, 0, 90)
        roomba.Parent        = workspace

        local bg             = Instance.new("BodyGyro")
        bg.MaxTorque         = Vector3.new(4e4, 4e4, 4e4)
        bg.P                 = 3000
        bg.Parent            = roomba

        local roombaData = {
            part          = roomba,
            health        = 15,
            owner         = isPlayer and "player" or caster,
            isPlayerOwned = isPlayer,
            lastShootTime = 0,
            bodyGyro      = bg,
        }
        table.insert(activeRoombas, roombaData)

        local rConn
        rConn = RunService.Heartbeat:Connect(function()
            if not roomba.Parent or roombaData.health <= 0 then
                rConn:Disconnect()
                if roomba.Parent then roomba:Destroy() end
                for j, r in ipairs(activeRoombas) do
                    if r == roombaData then table.remove(activeRoombas, j) break end
                end
                return
            end

            local nearestTarget, nearestDist = nil, math.huge

            if isPlayer then
                for _, fp in ipairs(fakePlayersList) do
                    if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                        local d = (fp.character.HumanoidRootPart.Position - roomba.Position).Magnitude
                        if d < nearestDist then nearestDist = d; nearestTarget = fp.character end
                    end
                end
            else
                if character and character:FindFirstChild("HumanoidRootPart") then
                    nearestTarget = character
                    nearestDist   = (character.HumanoidRootPart.Position - roomba.Position).Magnitude
                end
            end

            if nearestTarget and nearestTarget:FindFirstChild("HumanoidRootPart") then
                local tRoot = nearestTarget.HumanoidRootPart
                local dir   = (tRoot.Position - roomba.Position).Unit

                local mv = roomba:FindFirstChild("MoveForce")
                if not mv then
                    mv          = Instance.new("BodyVelocity")
                    mv.Name     = "MoveForce"
                    mv.MaxForce = Vector3.new(3000, 0, 3000)
                    mv.Parent   = roomba
                end
                mv.Velocity = Vector3.new(dir.X * 10, 0, dir.Z * 10)

                local ct = tick()
                if ct - roombaData.lastShootTime >= 3 then
                    roombaData.lastShootTime = ct

                    local bullet         = Instance.new("Part")
                    bullet.Name          = "RoombaBullet"
                    bullet.Size          = Vector3.new(0.3, 0.3, 0.6)
                    bullet.Position      = roomba.Position + dir * 2
                    bullet.Anchored      = false
                    bullet.CanCollide    = false
                    bullet.Material      = Enum.Material.Neon
                    bullet.Color         = Color3.fromRGB(100, 200, 255)
                    bullet.Parent        = workspace

                    local bv             = Instance.new("BodyVelocity")
                    bv.MaxForce          = Vector3.new(4e4, 4e4, 4e4)
                    bv.Velocity          = dir * 60
                    bv.Parent            = bullet

                    local hConn
                    hConn = RunService.Heartbeat:Connect(function()
                        if not bullet.Parent then hConn:Disconnect() return end
                        if nearestTarget and nearestTarget:FindFirstChild("HumanoidRootPart") then
                            if (nearestTarget.HumanoidRootPart.Position - bullet.Position).Magnitude <= 2.5 then
                                applyForce(nearestTarget, (nearestTarget.HumanoidRootPart.Position - bullet.Position).Unit, 2)
                                if not isPlayer then
                                    if not table.find(aggroedFakePlayers, caster) then
                                        table.insert(aggroedFakePlayers, caster)
                                        caster.isAggro      = true
                                        caster.aggroTarget  = "roomba"
                                        caster.aggroRoomba  = roombaData
                                    end
                                end
                                hConn:Disconnect()
                                bullet:Destroy()
                            end
                        end
                    end)

                    Debris:AddItem(bullet, 2)
                end
            end
        end)

        spawn(function()
            wait(120)
            if rConn then rConn:Disconnect() end
            if roomba.Parent then roomba:Destroy() end
            for j, r in ipairs(activeRoombas) do
                if r == roombaData then table.remove(activeRoombas, j) break end
            end
        end)
    end
end

-- ============================================================
-- SONG GLOVE RHYTHM SYSTEM
-- ============================================================
local rhythmGui = Instance.new("Frame")
rhythmGui.Name                 = "RhythmGame"
rhythmGui.Size                 = UDim2.new(0, 400, 0, 600)
rhythmGui.Position             = UDim2.new(0.5, -200, 0.5, -300)
rhythmGui.BackgroundTransparency = 1
rhythmGui.Visible              = false
rhythmGui.Parent               = screenGui

local lanes      = {}
local laneColors = {
    Color3.fromRGB(255, 0, 0),
    Color3.fromRGB(0, 255, 0),
    Color3.fromRGB(0, 0, 255),
    Color3.fromRGB(255, 255, 0),
}
local laneKeys = { Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.J, Enum.KeyCode.K }

for i = 1, 4 do
    local targetZone                 = Instance.new("Frame")
    targetZone.Name                  = "TargetZone" .. i
    targetZone.Size                  = UDim2.new(0, 80, 0, 80)
    targetZone.Position              = UDim2.new(0, (i - 1) * 100, 1, -100)
    targetZone.BackgroundColor3      = Color3.fromRGB(100, 100, 100)
    targetZone.BorderSizePixel       = 3
    targetZone.BorderColor3          = Color3.fromRGB(255, 255, 255)
    targetZone.BackgroundTransparency = 0.5
    targetZone.Parent                = rhythmGui

    local keyLabel                   = Instance.new("TextLabel")
    keyLabel.Size                    = UDim2.new(1, 0, 1, 0)
    keyLabel.BackgroundTransparency  = 1
    keyLabel.Text                    = string.sub(laneKeys[i].Name, 8)
    keyLabel.TextColor3              = Color3.fromRGB(255, 255, 255)
    keyLabel.TextScaled              = true
    keyLabel.Font                    = Enum.Font.GothamBold
    keyLabel.Parent                  = targetZone

    local mobileBtn                  = Instance.new("TextButton")
    mobileBtn.Name                   = "LaneButton" .. i
    mobileBtn.Size                   = UDim2.new(0, 80, 0, 80)
    mobileBtn.Position               = UDim2.new(0, (i - 1) * 100, 1, -200)
    mobileBtn.BackgroundColor3       = laneColors[i]
    mobileBtn.BorderSizePixel        = 3
    mobileBtn.BorderColor3           = Color3.fromRGB(255, 255, 255)
    mobileBtn.Text                   = string.sub(laneKeys[i].Name, 8)
    mobileBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
    mobileBtn.TextScaled             = true
    mobileBtn.Font                   = Enum.Font.GothamBold
    mobileBtn.Parent                 = rhythmGui

    lanes[i] = { targetZone = targetZone, button = mobileBtn, notes = {} }
end

local songSound          = Instance.new("Sound")
songSound.Name           = "SongSound"
songSound.SoundId        = "rbxassetid://112166141751710"
songSound.Volume         = 1
songSound.Parent         = workspace

local function createRhythmForcefield(size, pushPower, color)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local cRoot = character.HumanoidRootPart

    local ff             = Instance.new("Part")
    ff.Name              = "RhythmForcefield"
    ff.Shape             = Enum.PartType.Ball
    ff.Size              = Vector3.new(size, size, size)
    ff.Position          = cRoot.Position
    ff.Anchored          = true
    ff.CanCollide        = false
    ff.Material          = Enum.Material.ForceField
    ff.Color             = color
    ff.Transparency      = 0.5
    ff.Parent            = workspace

    for _, fp in ipairs(fakePlayersList) do
        if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
            local fRoot = fp.character.HumanoidRootPart
            if (fRoot.Position - cRoot.Position).Magnitude <= size / 2 then
                applyForce(fp.character, (fRoot.Position - cRoot.Position).Unit, pushPower)
                if not table.find(aggroedFakePlayers, fp) then
                    table.insert(aggroedFakePlayers, fp)
                    fp.isAggro = true
                end
            end
        end
    end

    TweenService:Create(ff, TweenInfo.new(0.5), {
        Transparency = 1,
        Size         = Vector3.new(size * 1.2, size * 1.2, size * 1.2),
    }):Play()

    Debris:AddItem(ff, 0.5)
end

local function spawnNote(laneIndex, isBlackNote)
    if not lanes[laneIndex] then return end
    local note             = Instance.new("Frame")
    note.Name              = isBlackNote and "BlackNote" or "Note"
    note.Size              = UDim2.new(0, 70, 0, 70)
    note.Position          = UDim2.new(0, (laneIndex - 1) * 100 + 5, 0, -70)
    note.BackgroundColor3  = isBlackNote and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    note.BorderSizePixel   = 3
    note.BorderColor3      = isBlackNote and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
    note.Parent            = rhythmGui

    local noteData = { frame = note, lane = laneIndex, isBlack = isBlackNote, startTime = tick() }
    table.insert(lanes[laneIndex].notes, noteData)
    table.insert(rhythmNotes, noteData)
    return noteData
end

local function checkNoteHit(laneIndex)
    if not lanes[laneIndex] then return end
    local songTime      = tick() - songStartTime
    local closestNote   = nil
    local closestDist   = math.huge

    for _, nd in ipairs(lanes[laneIndex].notes) do
        local noteY   = nd.frame.Position.Y.Offset
        local targetY = lanes[laneIndex].targetZone.Position.Y.Offset
        local d       = math.abs(noteY - targetY)
        if d < closestDist then closestDist = d; closestNote = nd end
    end

    if closestNote and closestDist < 50 then
        local size, power, color

        if closestNote.isBlack then
            size = 150; power = 17; color = Color3.fromRGB(0, 0, 0)
        elseif songTime >= 82 then
            size = 65; power = 13; color = Color3.fromRGB(128, 0, 128)
        elseif songTime >= 65 then
            size = 50; power = 10; color = Color3.fromRGB(255, 0, 0)
        elseif songTime >= 51 then
            size = 35; power = 8; color = Color3.fromRGB(0, 0, 255)
        elseif songTime >= 9 then
            size = 20; power = 5; color = Color3.fromRGB(255, 255, 255)
        else
            size = 10; power = 3; color = Color3.fromRGB(100, 100, 100)
        end

        createRhythmForcefield(size, power, color)
        closestNote.frame:Destroy()

        for i, n in ipairs(lanes[laneIndex].notes) do
            if n == closestNote then table.remove(lanes[laneIndex].notes, i) break end
        end
        for i, n in ipairs(rhythmNotes) do
            if n == closestNote then table.remove(rhythmNotes, i) break end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not rhythmGameActive then return end
    for i, key in ipairs(laneKeys) do
        if input.KeyCode == key then
            checkNoteHit(i)
            lanes[i].targetZone.BackgroundColor3 = laneColors[i]
            spawn(function()
                wait(0.1)
                lanes[i].targetZone.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            end)
            break
        end
    end
end)

for i, lane in ipairs(lanes) do
    lane.button.MouseButton1Click:Connect(function()
        if not rhythmGameActive then return end
        checkNoteHit(i)
        lane.targetZone.BackgroundColor3 = laneColors[i]
        spawn(function()
            wait(0.1)
            lane.targetZone.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        end)
    end)
end

local function startSongGlovePerformance()
    if songPlaying then return end
    songPlaying       = true
    rhythmGameActive  = true
    songStartTime     = tick()
    rhythmGui.Visible = true
    songSound:Play()

    spawn(function()
        local noteSchedule = {}
        for t = 0, 128, 0.1 do
            if math.random() < 0.3 then
                local ln       = math.random(1, 4)
                local isBlack  = (t >= 128 and t <= 130)
                table.insert(noteSchedule, { time = t, lane = ln, isBlack = isBlack })
            end
        end
        for _, ni in ipairs(noteSchedule) do
            local wt = ni.time - (tick() - songStartTime)
            if wt > 0 then
                wait(wt - 2)
                if rhythmGameActive then spawnNote(ni.lane, ni.isBlack) end
            end
        end
    end)

    spawn(function()
        while rhythmGameActive do
            for _, nd in ipairs(rhythmNotes) do
                if nd.frame.Parent then
                    local curY    = nd.frame.Position.Y.Offset
                    local targetY = lanes[nd.lane].targetZone.Position.Y.Offset
                    nd.frame.Position = UDim2.new(nd.frame.Position.X.Scale, nd.frame.Position.X.Offset, 0, curY + 3)
                    if curY + 3 > targetY + 150 then nd.frame:Destroy() end
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)

    spawn(function()
        wait(130)
        if songPlaying then
            songPlaying       = false
            rhythmGameActive  = false
            rhythmGui.Visible = false
            songSound:Stop()
            for _, nd in ipairs(rhythmNotes) do
                if nd.frame.Parent then nd.frame:Destroy() end
            end
            rhythmNotes = {}
            for _, lane in ipairs(lanes) do lane.notes = {} end
        end
    end)
end

local function stopSongGlovePerformance()
    songPlaying       = false
    rhythmGameActive  = false
    rhythmGui.Visible = false
    songSound:Stop()
    for _, nd in ipairs(rhythmNotes) do
        if nd.frame.Parent then nd.frame:Destroy() end
    end
    rhythmNotes = {}
    for _, lane in ipairs(lanes) do lane.notes = {} end
end

-- ============================================================
-- ADMIN PANEL GUI
-- ============================================================
local adminPanelGui = Instance.new("Frame")
adminPanelGui.Name             = "AdminPanel"
adminPanelGui.Size             = UDim2.new(0, 600, 0, 500)
adminPanelGui.Position         = UDim2.new(0.5, -300, 0.5, -250)
adminPanelGui.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
adminPanelGui.BorderSizePixel  = 3
adminPanelGui.BorderColor3     = Color3.fromRGB(255, 255, 255)
adminPanelGui.Visible          = false
adminPanelGui.Parent           = screenGui

local adminTitle = Instance.new("TextLabel")
adminTitle.Size             = UDim2.new(1, 0, 0, 40)
adminTitle.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
adminTitle.BorderSizePixel  = 0
adminTitle.Text             = "ADMIN PANEL"
adminTitle.TextColor3       = Color3.fromRGB(255, 255, 255)
adminTitle.TextScaled       = true
adminTitle.Font             = Enum.Font.GothamBold
adminTitle.Parent           = adminPanelGui

local closeAdminBtn = Instance.new("TextButton")
closeAdminBtn.Size             = UDim2.new(0, 35, 0, 35)
closeAdminBtn.Position         = UDim2.new(1, -38, 0, 2.5)
closeAdminBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeAdminBtn.Text             = "X"
closeAdminBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
closeAdminBtn.TextScaled       = true
closeAdminBtn.Font             = Enum.Font.GothamBold
closeAdminBtn.Parent           = adminPanelGui

local adminScrollFrame = Instance.new("ScrollingFrame")
adminScrollFrame.Size               = UDim2.new(1, -20, 1, -60)
adminScrollFrame.Position           = UDim2.new(0, 10, 0, 50)
adminScrollFrame.BackgroundColor3   = Color3.fromRGB(30, 30, 30)
adminScrollFrame.BorderSizePixel    = 0
adminScrollFrame.ScrollBarThickness = 8
adminScrollFrame.Parent             = adminPanelGui

local adminPanelButton = Instance.new("TextButton")
adminPanelButton.Name             = "AdminPanelButton"
adminPanelButton.Size             = UDim2.new(0, 120, 0, 120)
adminPanelButton.Position         = UDim2.new(1, -140, 1, -260)
adminPanelButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
adminPanelButton.BorderSizePixel  = 3
adminPanelButton.BorderColor3     = Color3.fromRGB(0, 0, 0)
adminPanelButton.Text             = "ADMIN"
adminPanelButton.TextColor3       = Color3.fromRGB(0, 0, 0)
adminPanelButton.TextScaled       = true
adminPanelButton.Font             = Enum.Font.GothamBold
adminPanelButton.Visible          = false
adminPanelButton.Parent           = screenGui

adminPanelButton.MouseButton1Click:Connect(function()
    adminPanelGui.Visible = not adminPanelGui.Visible
end)
closeAdminBtn.MouseButton1Click:Connect(function()
    adminPanelGui.Visible = false
end)

-- ============================================================
-- ADMIN COMMANDS
-- ============================================================
local adminCommands = {
    {
        name     = "Explode",
        cooldown = 30,
        func     = function()
            local ct = tick()
            if ct - adminCommandCooldowns.explode < 30 then return end
            adminCommandCooldowns.explode = ct

            for _, h in ipairs(activeHighlights) do if h.Parent then h:Destroy() end end
            activeHighlights = {}

            local selectedNames = {}
            for _, fp in ipairs(fakePlayersList) do
                if fp.character then
                    local hl               = Instance.new("Highlight")
                    hl.FillColor           = Color3.fromRGB(255, 100, 0)
                    hl.OutlineColor        = Color3.fromRGB(255, 0, 0)
                    hl.FillTransparency    = 0.5
                    hl.OutlineTransparency = 0
                    hl.Parent              = fp.character
                    table.insert(activeHighlights, hl)

                    local cd               = Instance.new("ClickDetector")
                    cd.MaxActivationDistance = 100
                    cd.Parent              = fp.character.HumanoidRootPart

                    cd.MouseClick:Connect(function()
                        table.insert(selectedNames, fp.name)
                        if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                            local exp = Instance.new("Explosion")
                            exp.Position = fp.character.HumanoidRootPart.Position
                            exp.BlastRadius = 10; exp.BlastPressure = 0; exp.Parent = workspace
                            local rA = math.random() * math.pi * 2
                            local rE = (math.random() - 0.5) * math.pi * 0.5
                            local dir = Vector3.new(math.cos(rA)*math.cos(rE), math.sin(rE), math.sin(rA)*math.cos(rE)).Unit
                            applyForce(fp.character, dir, 12)
                        end
                        cd:Destroy()
                        if hl.Parent then hl:Destroy() end
                    end)
                end
            end

            spawn(function()
                wait(10)
                for _, h in ipairs(activeHighlights) do if h.Parent then h:Destroy() end end
                activeHighlights = {}
                if #selectedNames > 0 then sendAdminChat("/Explode " .. table.concat(selectedNames, ", ")) end
            end)
        end,
    },

    {
        name     = "Speed",
        cooldown = 50,
        func     = function()
            local ct = tick()
            if ct - adminCommandCooldowns.speed < 50 then return end
            adminCommandCooldowns.speed = ct

            local inputFrame                  = Instance.new("Frame")
            inputFrame.Size                   = UDim2.new(0, 300, 0, 150)
            inputFrame.Position               = UDim2.new(0.5, -150, 0.5, -75)
            inputFrame.BackgroundColor3       = Color3.fromRGB(40, 40, 40)
            inputFrame.BorderSizePixel        = 3
            inputFrame.BorderColor3           = Color3.fromRGB(255, 255, 255)
            inputFrame.Parent                 = screenGui

            local inputBox                    = Instance.new("TextBox")
            inputBox.Size                     = UDim2.new(1, -20, 0, 40)
            inputBox.Position                 = UDim2.new(0, 10, 0, 30)
            inputBox.BackgroundColor3         = Color3.fromRGB(60, 60, 60)
            inputBox.Text                     = "16"
            inputBox.TextColor3               = Color3.fromRGB(255, 255, 255)
            inputBox.TextScaled               = true
            inputBox.Font                     = Enum.Font.Gotham
            inputBox.Parent                   = inputFrame

            local confirmBtn                  = Instance.new("TextButton")
            confirmBtn.Size                   = UDim2.new(0, 100, 0, 40)
            confirmBtn.Position               = UDim2.new(0.5, -50, 1, -50)
            confirmBtn.BackgroundColor3       = Color3.fromRGB(50, 150, 50)
            confirmBtn.Text                   = "SET"
            confirmBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
            confirmBtn.TextScaled             = true
            confirmBtn.Font                   = Enum.Font.GothamBold
            confirmBtn.Parent                 = inputFrame

            confirmBtn.MouseButton1Click:Connect(function()
                local v = tonumber(inputBox.Text) or 16
                if humanoid then humanoid.WalkSpeed = v end
                sendAdminChat("/Speed " .. v)
                inputFrame:Destroy()
            end)
        end,
    },

    {
        name     = "Anvil",
        cooldown = 35,
        func     = function()
            local ct = tick()
            if ct - adminCommandCooldowns.anvil < 35 then return end
            adminCommandCooldowns.anvil = ct

            for _, h in ipairs(activeHighlights) do if h.Parent then h:Destroy() end end
            activeHighlights = {}

            local selectedNames = {}
            for _, fp in ipairs(fakePlayersList) do
                if fp.character then
                    local hl               = Instance.new("Highlight")
                    hl.FillColor           = Color3.fromRGB(100, 100, 100)
                    hl.OutlineColor        = Color3.fromRGB(255, 255, 0)
                    hl.FillTransparency    = 0.5
                    hl.OutlineTransparency = 0
                    hl.Parent              = fp.character
                    table.insert(activeHighlights, hl)

                    local cd               = Instance.new("ClickDetector")
                    cd.MaxActivationDistance = 100
                    cd.Parent              = fp.character.HumanoidRootPart

                    cd.MouseClick:Connect(function()
                        table.insert(selectedNames, fp.name)
                        if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                            local tRoot = fp.character.HumanoidRootPart
                            local spawnPos = tRoot.Position + Vector3.new(0, 20, 0)
                            local anvil = Instance.new("Part")
                            anvil.Name = "Anvil"; anvil.Size = Vector3.new(3, 2, 3)
                            anvil.Position = spawnPos; anvil.Anchored = false
                            anvil.Material = Enum.Material.Metal; anvil.Color = Color3.fromRGB(80, 80, 80)
                            anvil.Parent = workspace
                            local bv = Instance.new("BodyVelocity")
                            bv.MaxForce = Vector3.new(0, 4e4, 0); bv.Velocity = Vector3.new(0, -100, 0)
                            bv.Parent = anvil
                            local hc; hc = anvil.Touched:Connect(function(hit)
                                if hit.Parent == fp.character then
                                    applyForce(fp.character, Vector3.new(0, -1, 0), 13)
                                    hc:Disconnect(); Debris:AddItem(anvil, 1)
                                end
                            end)
                            Debris:AddItem(anvil, 3)
                        end
                        cd:Destroy(); if hl.Parent then hl:Destroy() end
                    end)
                end
            end

            spawn(function()
                wait(10)
                for _, h in ipairs(activeHighlights) do if h.Parent then h:Destroy() end end
                if #selectedNames > 0 then sendAdminChat("/Anvil " .. table.concat(selectedNames, ", ")) end
            end)
        end,
    },

    {
        name     = "JumpPower",
        cooldown = 50,
        func     = function()
            local ct = tick()
            if ct - adminCommandCooldowns.jumppower < 50 then return end
            adminCommandCooldowns.jumppower = ct

            local inputFrame                  = Instance.new("Frame")
            inputFrame.Size                   = UDim2.new(0, 300, 0, 150)
            inputFrame.Position               = UDim2.new(0.5, -150, 0.5, -75)
            inputFrame.BackgroundColor3       = Color3.fromRGB(40, 40, 40)
            inputFrame.BorderSizePixel        = 3
            inputFrame.BorderColor3           = Color3.fromRGB(255, 255, 255)
            inputFrame.Parent                 = screenGui

            local inputBox                    = Instance.new("TextBox")
            inputBox.Size                     = UDim2.new(1, -20, 0, 40)
            inputBox.Position                 = UDim2.new(0, 10, 0, 30)
            inputBox.BackgroundColor3         = Color3.fromRGB(60, 60, 60)
            inputBox.Text                     = "50"
            inputBox.TextColor3               = Color3.fromRGB(255, 255, 255)
            inputBox.TextScaled               = true
            inputBox.Font                     = Enum.Font.Gotham
            inputBox.Parent                   = inputFrame

            local confirmBtn                  = Instance.new("TextButton")
            confirmBtn.Size                   = UDim2.new(0, 100, 0, 40)
            confirmBtn.Position               = UDim2.new(0.5, -50, 1, -50)
            confirmBtn.BackgroundColor3       = Color3.fromRGB(50, 150, 50)
            confirmBtn.Text                   = "SET"
            confirmBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
            confirmBtn.TextScaled             = true
            confirmBtn.Font                   = Enum.Font.GothamBold
            confirmBtn.Parent                 = inputFrame

            confirmBtn.MouseButton1Click:Connect(function()
                local v = tonumber(inputBox.Text) or 50
                if humanoid then humanoid.JumpPower = v end
                sendAdminChat("/JumpPower " .. v)
                inputFrame:Destroy()
            end)
        end,
    },

    {
        name     = "Bring",
        cooldown = 55,
        func     = function()
            local ct = tick()
            if ct - adminCommandCooldowns.bring < 55 then return end
            adminCommandCooldowns.bring = ct

            local df              = Instance.new("Frame")
            df.Size               = UDim2.new(0, 300, 0, 300)
            df.Position           = UDim2.new(0.5, -150, 0.5, -150)
            df.BackgroundColor3   = Color3.fromRGB(40, 40, 40)
            df.BorderSizePixel    = 3
            df.BorderColor3       = Color3.fromRGB(255, 255, 255)
            df.Parent             = screenGui

            local sf              = Instance.new("ScrollingFrame")
            sf.Size               = UDim2.new(1, -20, 1, -20)
            sf.Position           = UDim2.new(0, 10, 0, 10)
            sf.BackgroundColor3   = Color3.fromRGB(60, 60, 60)
            sf.BorderSizePixel    = 0
            sf.ScrollBarThickness = 6
            sf.Parent             = df

            local yo = 0
            for _, fp in ipairs(fakePlayersList) do
                local btn             = Instance.new("TextButton")
                btn.Size              = UDim2.new(1, -10, 0, 40)
                btn.Position          = UDim2.new(0, 5, 0, yo)
                btn.BackgroundColor3  = Color3.fromRGB(80, 80, 80)
                btn.Text              = fp.name
                btn.TextColor3        = Color3.fromRGB(255, 255, 255)
                btn.TextScaled        = true
                btn.Font              = Enum.Font.Gotham
                btn.Parent            = sf

                btn.MouseButton1Click:Connect(function()
                    if fp.character and fp.rootPart and character and rootPart then
                        fp.rootPart.CFrame = rootPart.CFrame + Vector3.new(5, 0, 0)
                        sendAdminChat("/Bring " .. fp.name)
                    end
                    df:Destroy()
                end)
                yo = yo + 45
            end
            sf.CanvasSize = UDim2.new(0, 0, 0, yo)
        end,
    },

    {
        name     = "Goto",
        cooldown = 53,
        func     = function()
            local ct = tick()
            if ct - adminCommandCooldowns.goto < 53 then return end
            adminCommandCooldowns.goto = ct

            local df              = Instance.new("Frame")
            df.Size               = UDim2.new(0, 300, 0, 300)
            df.Position           = UDim2.new(0.5, -150, 0.5, -150)
            df.BackgroundColor3   = Color3.fromRGB(40, 40, 40)
            df.BorderSizePixel    = 3
            df.BorderColor3       = Color3.fromRGB(255, 255, 255)
            df.Parent             = screenGui

            local sf              = Instance.new("ScrollingFrame")
            sf.Size               = UDim2.new(1, -20, 1, -20)
            sf.Position           = UDim2.new(0, 10, 0, 10)
            sf.BackgroundColor3   = Color3.fromRGB(60, 60, 60)
            sf.BorderSizePixel    = 0
            sf.ScrollBarThickness = 6
            sf.Parent             = df

            local yo = 0
            for _, fp in ipairs(fakePlayersList) do
                local btn             = Instance.new("TextButton")
                btn.Size              = UDim2.new(1, -10, 0, 40)
                btn.Position          = UDim2.new(0, 5, 0, yo)
                btn.BackgroundColor3  = Color3.fromRGB(80, 80, 80)
                btn.Text              = fp.name
                btn.TextColor3        = Color3.fromRGB(255, 255, 255)
                btn.TextScaled        = true
                btn.Font              = Enum.Font.Gotham
                btn.Parent            = sf

                btn.MouseButton1Click:Connect(function()
                    if fp.character and fp.rootPart and character and rootPart then
                        rootPart.CFrame = fp.rootPart.CFrame + Vector3.new(5, 0, 0)
                        sendAdminChat("/Goto " .. fp.name)
                    end
                    df:Destroy()
                end)
                yo = yo + 45
            end
            sf.CanvasSize = UDim2.new(0, 0, 0, yo)
        end,
    },

    {
        name     = "Train",
        cooldown = 60,
        func     = function()
            local ct = tick()
            if ct - adminCommandCooldowns.train < 60 then return end
            adminCommandCooldowns.train = ct
            activateTrainAbility(nil, true)
            sendAdminChat("/Train")
        end,
    },

    {
        name     = "Freeze",
        cooldown = 40,
        func     = function()
            local ct = tick()
            if ct - adminCommandCooldowns.freeze < 40 then return end
            adminCommandCooldowns.freeze = ct

            for _, h in ipairs(activeHighlights) do if h.Parent then h:Destroy() end end
            activeHighlights = {}

            local selectedNames = {}
            for _, fp in ipairs(fakePlayersList) do
                if fp.character then
                    local hl               = Instance.new("Highlight")
                    hl.FillColor           = Color3.fromRGB(100, 200, 255)
                    hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency    = 0.5
                    hl.OutlineTransparency = 0
                    hl.Parent              = fp.character
                    table.insert(activeHighlights, hl)

                    local cd               = Instance.new("ClickDetector")
                    cd.MaxActivationDistance = 100
                    cd.Parent              = fp.character.HumanoidRootPart

                    cd.MouseClick:Connect(function()
                        table.insert(selectedNames, fp.name)
                        if fp.humanoid then
                            local os = fp.humanoid.WalkSpeed
                            fp.humanoid.WalkSpeed = 0
                            spawn(function()
                                wait(5)
                                if fp.humanoid then fp.humanoid.WalkSpeed = os end
                            end)
                        end
                        cd:Destroy(); if hl.Parent then hl:Destroy() end
                    end)
                end
            end

            spawn(function()
                wait(10)
                for _, h in ipairs(activeHighlights) do if h.Parent then h:Destroy() end end
                if #selectedNames > 0 then sendAdminChat("/Freeze " .. table.concat(selectedNames, ", ")) end
            end)
        end,
    },

    {
        name     = "Ragdoll",
        cooldown = 45,
        func     = function()
            local ct = tick()
            if ct - adminCommandCooldowns.ragdoll < 45 then return end
            adminCommandCooldowns.ragdoll = ct

            for _, h in ipairs(activeHighlights) do if h.Parent then h:Destroy() end end
            activeHighlights = {}

            local selectedNames = {}
            for _, fp in ipairs(fakePlayersList) do
                if fp.character then
                    local hl               = Instance.new("Highlight")
                    hl.FillColor           = Color3.fromRGB(200, 100, 255)
                    hl.OutlineColor        = Color3.fromRGB(255, 100, 255)
                    hl.FillTransparency    = 0.5
                    hl.OutlineTransparency = 0
                    hl.Parent              = fp.character
                    table.insert(activeHighlights, hl)

                    local cd               = Instance.new("ClickDetector")
                    cd.MaxActivationDistance = 100
                    cd.Parent              = fp.character.HumanoidRootPart

                    cd.MouseButton1Click:Connect(function()
                        table.insert(selectedNames, fp.name)
                        if fp.humanoid and fp.rootPart then
                            fp.humanoid.PlatformStand = true
                            local rDir = Vector3.new(math.random(-1,1), math.random(0,1), math.random(-1,1)).Unit
                            applyForce(fp.character, rDir, 15)
                            spawn(function()
                                wait(3)
                                if fp.humanoid then fp.humanoid.PlatformStand = false end
                            end)
                        end
                        cd:Destroy(); if hl.Parent then hl:Destroy() end
                    end)
                end
            end

            spawn(function()
                wait(10)
                for _, h in ipairs(activeHighlights) do if h.Parent then h:Destroy() end end
                if #selectedNames > 0 then sendAdminChat("/Ragdoll " .. table.concat(selectedNames, ", ")) end
            end)
        end,
    },
}

-- Build admin command buttons
local function createAdminCommandButtons()
    local yOffset = 10
    for _, cmd in ipairs(adminCommands) do
        local cmdFrame             = Instance.new("Frame")
        cmdFrame.Size              = UDim2.new(1, -20, 0, 60)
        cmdFrame.Position          = UDim2.new(0, 10, 0, yOffset)
        cmdFrame.BackgroundColor3  = Color3.fromRGB(50, 50, 50)
        cmdFrame.BorderSizePixel   = 2
        cmdFrame.BorderColor3      = Color3.fromRGB(100, 100, 100)
        cmdFrame.Parent            = adminScrollFrame

        local cmdLabel             = Instance.new("TextLabel")
        cmdLabel.Size              = UDim2.new(0.6, 0, 1, 0)
        cmdLabel.BackgroundTransparency = 1
        cmdLabel.Text              = "/" .. cmd.name
        cmdLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
        cmdLabel.TextSize          = 16
        cmdLabel.Font              = Enum.Font.GothamBold
        cmdLabel.TextXAlignment    = Enum.TextXAlignment.Left
        cmdLabel.Parent            = cmdFrame

        local cdLabel              = Instance.new("TextLabel")
        cdLabel.Size               = UDim2.new(0.3, 0, 0.4, 0)
        cdLabel.Position           = UDim2.new(0.6, 0, 0.5, 0)
        cdLabel.BackgroundTransparency = 1
        cdLabel.Text               = cmd.cooldown .. "s CD"
        cdLabel.TextColor3         = Color3.fromRGB(200, 200, 200)
        cdLabel.TextSize           = 12
        cdLabel.Font               = Enum.Font.Gotham
        cdLabel.Parent             = cmdFrame

        local useBtn               = Instance.new("TextButton")
        useBtn.Size                = UDim2.new(0, 80, 0, 40)
        useBtn.Position            = UDim2.new(1, -90, 0.5, -20)
        useBtn.BackgroundColor3    = Color3.fromRGB(50, 150, 50)
        useBtn.Text                = "USE"
        useBtn.TextColor3          = Color3.fromRGB(255, 255, 255)
        useBtn.TextScaled          = true
        useBtn.Font                = Enum.Font.GothamBold
        useBtn.Parent              = cmdFrame

        useBtn.MouseButton1Click:Connect(function() cmd.func() end)

        yOffset = yOffset + 70
    end
    adminScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

createAdminCommandButtons()

-- ============================================================
-- ============================================================
--    ACCELERATION GLOVE — PLAYER FUNCTIONS
-- ============================================================
-- ============================================================

-- ------------------------------------------------------------
-- Start the acceleration speed-gain ticker for the player
-- Called when Acceleration Glove is equipped
-- ------------------------------------------------------------
local function startAccelerationForPlayer()
    -- reset speed to base
    accelCurrentSpeed   = CONFIG.ACCEL_BASE_SPEED
    accelSpeedTickTimer = 0
    accelIsCrashStunned = false

    -- Show the HUD
    accelHudFrame.Visible = true
    updateAccelHud()

    -- Disconnect any old connection
    if accelSpeedTickConnection then
        accelSpeedTickConnection:Disconnect()
        accelSpeedTickConnection = nil
    end

    -- Start speed tick loop
    accelSpeedTickConnection = RunService.Heartbeat:Connect(function(dt)
        -- Don't tick if stunned
        if accelIsCrashStunned then
            -- check if stun expired
            if tick() >= accelCrashStunEndTime then
                accelIsCrashStunned = false
                accelStunLabel.Visible = false
                -- reset speed on stun end
                accelCurrentSpeed = CONFIG.ACCEL_BASE_SPEED
                if humanoid then
                    humanoid.WalkSpeed = accelCurrentSpeed
                end
                updateAccelHud()
            end
            return
        end

        if not humanoid then return end
        if not character then return end

        -- Detect if the player is moving
        local isMoving = humanoid.MoveDirection.Magnitude > 0.01

        if isMoving then
            accelSpeedTickTimer = accelSpeedTickTimer + dt

            if accelSpeedTickTimer >= CONFIG.ACCEL_SPEED_GAIN_RATE then
                accelSpeedTickTimer = accelSpeedTickTimer - CONFIG.ACCEL_SPEED_GAIN_RATE

                -- Add speed, cap at max
                accelCurrentSpeed = math.min(
                    accelCurrentSpeed + CONFIG.ACCEL_SPEED_PER_TICK,
                    CONFIG.ACCEL_MAX_SPEED
                )

                humanoid.WalkSpeed = accelCurrentSpeed
                updateAccelHud()
            end
        else
            -- Not moving: decay speed back toward base gradually
            accelSpeedTickTimer = 0
            if accelCurrentSpeed > CONFIG.ACCEL_BASE_SPEED then
                accelCurrentSpeed = math.max(
                    accelCurrentSpeed - (2 * dt * 16),   -- gentle decay ~2 walkspeed/s
                    CONFIG.ACCEL_BASE_SPEED
                )
                humanoid.WalkSpeed = accelCurrentSpeed
                updateAccelHud()
            end
        end
    end)

    -- Start crash detection loop
    if accelCrashCheckConnection then
        accelCrashCheckConnection:Disconnect()
        accelCrashCheckConnection = nil
    end

    accelCrashCheckConnection = RunService.Heartbeat:Connect(function()
        if accelIsCrashStunned then return end
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        local cRoot = character.HumanoidRootPart

        -- Only check crash if player is actually moving fast enough to matter
        if accelCurrentSpeed < 30 then return end

        for _, fp in ipairs(fakePlayersList) do
            if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                local fRoot = fp.character.HumanoidRootPart
                local dist  = (fRoot.Position - cRoot.Position).Magnitude

                if dist <= CONFIG.ACCEL_CRASH_DISTANCE then
                    -- === CRASH! ===
                    local pushPower = getAccelPushPower(accelCurrentSpeed)
                    local crashDir  = (fRoot.Position - cRoot.Position).Unit

                    -- Fling the dummy away
                    applyForce(fp.character, crashDir, pushPower)

                    -- Visual crash effect
                    createSlapEffect(fRoot.Position, Color3.fromRGB(255, 80, 0))

                    -- Crash notification
                    spawn(function()
                        createAbilityNotification(
                            "CRASH! Power " .. pushPower,
                            Color3.fromRGB(255, 80, 0)
                        )
                    end)

                    -- Aggro the fake player
                    if not table.find(aggroedFakePlayers, fp) then
                        table.insert(aggroedFakePlayers, fp)
                        fp.isAggro = true
                    end

                    -- Stun the player (can't move for 2s)
                    accelIsCrashStunned    = true
                    accelCrashStunEndTime  = tick() + CONFIG.ACCEL_CRASH_STUN_DURATION

                    if humanoid then
                        humanoid.WalkSpeed = 0
                    end

                    accelStunLabel.Visible = true
                    updateAccelHud()

                    -- Only count crash once per tick cycle; break inner loop
                    break
                end
            end
        end
    end)
end

-- ------------------------------------------------------------
-- Stop acceleration system when glove is unequipped
-- ------------------------------------------------------------
local function stopAccelerationForPlayer()
    if accelSpeedTickConnection then
        accelSpeedTickConnection:Disconnect()
        accelSpeedTickConnection = nil
    end

    if accelCrashCheckConnection then
        accelCrashCheckConnection:Disconnect()
        accelCrashCheckConnection = nil
    end

    -- Restore default speed
    accelCurrentSpeed = CONFIG.ACCEL_BASE_SPEED
    if humanoid then
        humanoid.WalkSpeed = CONFIG.ACCEL_BASE_SPEED
    end

    accelHudFrame.Visible  = false
    accelStunLabel.Visible = false
    accelIsCrashStunned    = false
end

-- ============================================================
-- ============================================================
--    ACCELERATION GLOVE — FAKE PLAYER (DUMMY) FUNCTIONS
-- ============================================================
-- ============================================================

-- Called inside the fake player AI update loop to handle
-- Acceleration Glove-specific behaviour for a single dummy.
--
-- The dummy:
--   • Gains +1 speed every 0.5s it is actively moving
--   • Speed caps at 300
--   • If the dummy crashes into the real player → player gets pushed, dummy is stunned 2s
--   • Dummy does NOT manually slap while using this glove; it relies purely on crashes
-- ============================================================

local function initAccelDummyState(fp)
    -- Called once when a dummy with Acceleration Glove is created
    fp.accelSpeed         = CONFIG.ACCEL_BASE_SPEED
    fp.accelTickTimer     = 0
    fp.accelCrashStunned  = false
    fp.accelStunEndTime   = 0
end

-- Per-frame update for an Acceleration Glove dummy
-- dt is the delta time from Heartbeat
local function updateAccelDummy(fp, dt)
    if not fp.character or not fp.rootPart or not fp.humanoid then return end
    if isTimeStopActive then return end

    -- Check if crash stun has expired
    if fp.accelCrashStunned then
        if tick() >= fp.accelStunEndTime then
            fp.accelCrashStunned   = false
            fp.accelSpeed          = CONFIG.ACCEL_BASE_SPEED
            fp.humanoid.WalkSpeed  = fp.accelSpeed
        end
        -- While stunned, don't move
        return
    end

    local fRoot = fp.rootPart

    -- Determine if the dummy is actually moving (velocity-based check)
    local vel     = fRoot.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
    local hSpeed  = Vector3.new(vel.X, 0, vel.Z).Magnitude
    local isMoving = hSpeed > 2

    if isMoving then
        fp.accelTickTimer = fp.accelTickTimer + dt
        if fp.accelTickTimer >= CONFIG.ACCEL_SPEED_GAIN_RATE then
            fp.accelTickTimer = fp.accelTickTimer - CONFIG.ACCEL_SPEED_GAIN_RATE

            fp.accelSpeed = math.min(
                fp.accelSpeed + CONFIG.ACCEL_SPEED_PER_TICK,
                CONFIG.ACCEL_MAX_SPEED
            )
            fp.humanoid.WalkSpeed = fp.accelSpeed
        end
    else
        fp.accelTickTimer = 0
        -- Gradual speed decay when not moving
        if fp.accelSpeed > CONFIG.ACCEL_BASE_SPEED then
            fp.accelSpeed = math.max(fp.accelSpeed - (2 * dt * 16), CONFIG.ACCEL_BASE_SPEED)
            fp.humanoid.WalkSpeed = fp.accelSpeed
        end
    end

    -- Crash detection against the real player
    if fp.accelSpeed >= 30 then
        if character and character:FindFirstChild("HumanoidRootPart") then
            local playerRoot = character.HumanoidRootPart
            local dist       = (playerRoot.Position - fRoot.Position).Magnitude

            if dist <= CONFIG.ACCEL_DUMMY_CRASH_DISTANCE then
                -- === DUMMY CRASH INTO PLAYER ===
                local pushPower = getAccelPushPower(fp.accelSpeed)
                local crashDir  = (playerRoot.Position - fRoot.Position).Unit

                -- Push the real player
                applyForce(character, crashDir, pushPower)

                -- Visual crash effect on player's position
                createSlapEffect(playerRoot.Position, Color3.fromRGB(255, 80, 0))

                -- Stun the dummy
                fp.accelCrashStunned  = true
                fp.accelStunEndTime   = tick() + CONFIG.ACCEL_DUMMY_CRASH_STUN
                fp.humanoid.WalkSpeed = 0

                -- Optional: show fake player chat
                spawn(function()
                    sendFakePlayerChat(fp.name, "SPEED CRASH! *stunned*")
                end)
            end
        end
    end
end

-- ============================================================
-- PLAYER SLAP FUNCTION (actual definition)
-- ============================================================
local function playerSlapImpl()
    if not equippedGlove or not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    if isCounterActive  then return end
    if isTimeStopActive then return end

    -- Acceleration Glove stun check
    if currentGlove == "Acceleration Glove" and accelIsCrashStunned then
        return
    end

    local currentTime = tick()
    local gloveData   = GLOVE_DATA[currentGlove]

    if currentTime - lastSlapTime < gloveData.SlapCooldown then return end
    lastSlapTime = currentTime

    local characterRoot = character.HumanoidRootPart
    local slapPosition  = characterRoot.Position + characterRoot.CFrame.LookVector * 3

    createSlapEffect(slapPosition, gloveData.Color)

    for _, fp in ipairs(fakePlayersList) do
        if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
            local fakeRoot = fp.character.HumanoidRootPart
            local distance = (fakeRoot.Position - slapPosition).Magnitude

            if distance <= CONFIG.SLAP_DISTANCE then
                if fp.isCounterActive then
                    triggerCounterPunishment(character)
                else
                    local direction
                    local pushPower = gloveData.PushPower

                    -- Acceleration Glove: push power scales with current speed
                    if currentGlove == "Acceleration Glove" then
                        pushPower = getAccelPushPower(accelCurrentSpeed)
                    end

                    if currentGlove == "RNG Glove" then
                        local rA = math.random() * math.pi * 2
                        local rE = (math.random() - 0.5) * math.pi * 0.5
                        direction = Vector3.new(
                            math.cos(rA) * math.cos(rE),
                            math.sin(rE),
                            math.sin(rA) * math.cos(rE)
                        ).Unit
                    else
                        direction = (fakeRoot.Position - characterRoot.Position).Unit
                    end

                    applyForce(fp.character, direction, pushPower)

                    fp.slapsTaken = fp.slapsTaken + 1

                    -- Turret / roomba damage
                    for _, td in ipairs(activeTurrets) do
                        if not td.isPlayerOwned and td.head and td.head.Parent then
                            if (td.head.Position - slapPosition).Magnitude <= CONFIG.SLAP_DISTANCE then
                                td.health = td.health - 5
                            end
                        end
                    end
                    for _, rd in ipairs(activeRoombas) do
                        if not rd.isPlayerOwned and rd.part and rd.part.Parent then
                            if (rd.part.Position - slapPosition).Magnitude <= CONFIG.SLAP_DISTANCE then
                                rd.health = rd.health - 5
                            end
                        end
                    end

                    if not table.find(aggroedFakePlayers, fp) then
                        table.insert(aggroedFakePlayers, fp)
                        fp.isAggro = true
                    end
                end
            end
        end
    end
end

-- Wrap with sound
playerSlap = function()
    playerSlapImpl()
    local s         = Instance.new("Sound")
    s.SoundId       = "rbxassetid://537371462"
    s.Volume        = 0.5
    s.Parent        = workspace
    s:Play()
    Debris:AddItem(s, 2)
end

slapButton.MouseButton1Click:Connect(function()
    playerSlap()
end)

-- ============================================================
-- GLOVE SELECTION BUTTONS
-- ============================================================
local function createGloveButtons()
    local yOffset = 0
    for gloveName, gloveData in pairs(GLOVE_DATA) do
        local gFrame             = Instance.new("Frame")
        gFrame.Size              = UDim2.new(1, -20, 0, 130)
        gFrame.Position          = UDim2.new(0, 10, 0, yOffset)
        gFrame.BackgroundColor3  = Color3.fromRGB(50, 50, 50)
        gFrame.BorderSizePixel   = 2
        gFrame.BorderColor3      = gloveData.Color
        gFrame.Parent            = scrollFrame

        local nameLabel          = Instance.new("TextLabel")
        nameLabel.Size           = UDim2.new(1, -10, 0, 25)
        nameLabel.Position       = UDim2.new(0, 5, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text           = gloveName
        nameLabel.TextColor3     = gloveData.Color
        nameLabel.TextScaled     = true
        nameLabel.Font           = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent         = gFrame

        local descLabel          = Instance.new("TextLabel")
        descLabel.Size           = UDim2.new(1, -10, 0, 30)
        descLabel.Position       = UDim2.new(0, 5, 0, 32)
        descLabel.BackgroundTransparency = 1
        descLabel.Text           = gloveData.Description or ""
        descLabel.TextColor3     = Color3.fromRGB(180, 180, 180)
        descLabel.TextSize       = 12
        descLabel.Font           = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.TextWrapped    = true
        descLabel.Parent         = gFrame

        local statsText = string.format(
            "Push: %d | Slap CD: %.1fs | Type: %s | Ability CD: %ds",
            gloveData.PushPower,
            gloveData.SlapCooldown,
            gloveData.AbilityType,
            gloveData.AbilityCooldown
        )

        local statsLabel         = Instance.new("TextLabel")
        statsLabel.Size          = UDim2.new(1, -10, 0, 30)
        statsLabel.Position      = UDim2.new(0, 5, 0, 65)
        statsLabel.BackgroundTransparency = 1
        statsLabel.Text          = statsText
        statsLabel.TextColor3    = Color3.fromRGB(200, 200, 200)
        statsLabel.TextSize      = 12
        statsLabel.Font          = Enum.Font.Gotham
        statsLabel.TextXAlignment = Enum.TextXAlignment.Left
        statsLabel.TextYAlignment = Enum.TextYAlignment.Top
        statsLabel.Parent        = gFrame

        local selectBtn          = Instance.new("TextButton")
        selectBtn.Size           = UDim2.new(0, 120, 0, 30)
        selectBtn.Position       = UDim2.new(1, -130, 1, -35)
        selectBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        selectBtn.Text           = "SELECT"
        selectBtn.TextColor3     = Color3.fromRGB(255, 255, 255)
        selectBtn.TextScaled     = true
        selectBtn.Font           = Enum.Font.GothamBold
        selectBtn.Parent         = gFrame

        selectBtn.MouseButton1Click:Connect(function()
            currentGlove = gloveName
            gloveSelectionFrame.Visible = false
            if equippedGlove then
                updateGloveAppearance()
            end
        end)

        yOffset = yOffset + 140
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

createGloveButtons()

gloveButton.MouseButton1Click:Connect(function()
    gloveSelectionFrame.Visible = not gloveSelectionFrame.Visible
end)
closeGloveSelBtn.MouseButton1Click:Connect(function()
    gloveSelectionFrame.Visible = false
end)

-- ============================================================
-- ABILITY BUTTON — ACTIVATION
-- ============================================================
abilityButton.MouseButton1Click:Connect(function()
    local currentTime = tick()
    local gloveData   = GLOVE_DATA[currentGlove]

    -- Pyromania 1st ability is handled here (Gasoline trail)
    if currentGlove == "Pyromania Glove" then
        if currentTime - lastAbilityTime < gloveData.AbilityCooldown then return end
        lastAbilityTime = currentTime
        activatePyroGasoline(nil, true)
        local cd = gloveData.AbilityCooldown
        abilityButton.Text = "GAS " .. cd
        for i = cd - 1, 0, -1 do wait(1); abilityButton.Text = tostring(i) end
        abilityButton.Text = "GASOLINE"
        return
    end

    if gloveData.AbilityType == "None" then return end
    if currentTime - lastAbilityTime < gloveData.AbilityCooldown then return end
    lastAbilityTime = currentTime

    if     gloveData.Ability == "Siphon"   then activateSiphonAbility(nil, true)
    elseif gloveData.Ability == "Train"    then activateTrainAbility(nil, true)
    elseif gloveData.Ability == "Counter"  then activateCounterAbility(nil, true)
    elseif gloveData.Ability == "TimeStop" then activateTimeStopAbility()
    elseif gloveData.Ability == "LandMine" then activateLandMineAbility(nil, true)
    elseif gloveData.Ability == "Engineer" then activateEngineerTurret(nil, true)
    elseif gloveData.Ability == "AirBomb"  then activateAirBombAbility(nil, true)
    end

    local cd = gloveData.AbilityCooldown
    abilityButton.Text = tostring(cd)
    for i = cd - 1, 0, -1 do
        wait(1)
        abilityButton.Text = tostring(i)
    end
    abilityButton.Text = "ABILITY"
end)

ability2Button.MouseButton1Click:Connect(function()
    local currentTime = tick()

    if currentGlove == "Engineer Glove" then
        local gloveData = GLOVE_DATA["Engineer Glove"]
        if currentTime - lastAbility2Time < gloveData.AbilityCooldown2 then return end
        lastAbility2Time = currentTime
        activateEngineerRoombas(nil, true)
        local cd = gloveData.AbilityCooldown2
        ability2Button.Text = tostring(cd)
        for i = cd - 1, 0, -1 do wait(1); ability2Button.Text = tostring(i) end
        ability2Button.Text = "ABILITY 2"

    elseif currentGlove == "Pyromania Glove" then
        local gloveData = GLOVE_DATA["Pyromania Glove"]
        if currentTime - lastAbility2Time < gloveData.AbilityCooldown2 then return end
        lastAbility2Time = currentTime
        activatePyroIgnite(nil, true)   -- defined later
        local cd = gloveData.AbilityCooldown2
        ability2Button.Text = tostring(cd)
        ability2Button.Text = "🔥 IGNITE"
        for i = cd - 1, 0, -1 do wait(1); ability2Button.Text = tostring(i) end
        ability2Button.Text = "IGNITE"
    end
end)

-- ============================================================
-- GLOVE TOOL CREATION
-- ============================================================
local function updateGloveAppearance()
    if equippedGlove and equippedGlove:FindFirstChild("Handle") then
        equippedGlove.Handle.Color = GLOVE_DATA[currentGlove].Color
    end
end

local function createGloveTool()
    local tool          = Instance.new("Tool")
    tool.Name           = "Glove"
    tool.RequiresHandle = true
    tool.CanBeDropped   = false

    local handle        = Instance.new("Part")
    handle.Name         = "Handle"
    handle.Size         = Vector3.new(1.5, 1.5, 1.5)
    handle.CanCollide   = false
    handle.Parent       = tool

    local mesh          = Instance.new("SpecialMesh")
    mesh.MeshType       = Enum.MeshType.Brick
    mesh.Scale          = Vector3.new(1.2, 1.2, 1.2)
    mesh.Parent         = handle

    tool.Equipped:Connect(function()
        equippedGlove = tool
        updateGloveAppearance()

        local gloveData = GLOVE_DATA[currentGlove]

        -- Song Glove
        if currentGlove == "Song Glove" then
            startSongGlovePerformance()
        end

        -- Acceleration Glove
        if currentGlove == "Acceleration Glove" then
            startAccelerationForPlayer()
        end

        -- Ability buttons
        if gloveData.AbilityType == "Ability" or gloveData.AbilityType == "Fusion" then
            if currentGlove == "Admin Glove" then
                adminPanelButton.Visible = true
                abilityButton.Visible    = false
            else
                abilityButton.Visible    = true
                adminPanelButton.Visible = false
            end
        else
            abilityButton.Visible    = false
            adminPanelButton.Visible = false
        end

        ability2Button.Visible = (currentGlove == "Engineer Glove" or currentGlove == "Pyromania Glove")

        if currentGlove ~= "Song Glove" then
            slapButton.Visible = true
        else
            slapButton.Visible = false
        end

        -- Passive notification
        if gloveData.AbilityType == "Passive" and currentGlove ~= "Song Glove" then
            local notifLabel             = Instance.new("TextLabel")
            notifLabel.Size              = UDim2.new(0, 300, 0, 60)
            notifLabel.Position          = UDim2.new(0.5, -150, 0.15, 0)
            notifLabel.BackgroundColor3  = Color3.fromRGB(50, 50, 50)
            notifLabel.BorderSizePixel   = 3
            notifLabel.BorderColor3      = gloveData.Color
            notifLabel.Text              = "PASSIVE: " .. (gloveData.Ability or "")
            notifLabel.TextColor3        = gloveData.Color
            notifLabel.TextScaled        = true
            notifLabel.Font              = Enum.Font.GothamBold
            notifLabel.Parent            = screenGui

            spawn(function()
                wait(3)
                notifLabel:Destroy()
            end)
        end
    end)

    tool.Unequipped:Connect(function()
        equippedGlove            = nil
        abilityButton.Visible    = false
        ability2Button.Visible   = false
        adminPanelButton.Visible = false
        slapButton.Visible       = false

        if currentGlove == "Song Glove" then
            stopSongGlovePerformance()
        end

        if currentGlove == "Acceleration Glove" then
            stopAccelerationForPlayer()
        end

        -- Pyromania: stop active trail if still running
        if currentGlove == "Pyromania Glove" then
            pyroGasolineActive = false
            if pyroTrailConnection then
                pyroTrailConnection:Disconnect()
                pyroTrailConnection = nil
            end
            -- Fade out any un-ignited player gasoline puddles
            for _, pd in ipairs(activePyroGasoline) do
                if pd.part.Parent and not pd.ignited then
                    TweenService:Create(pd.part, TweenInfo.new(0.5), {
                        Transparency = 1
                    }):Play()
                    Debris:AddItem(pd.part, 0.6)
                end
            end
            activePyroGasoline = {}
        end
    end)

    tool.Activated:Connect(function()
        playerSlap()
    end)

    tool.Parent = player.Backpack
    return tool
end

-- ============================================================
-- FAKE PLAYER: CREATE CHARACTER
-- ============================================================
local function createFakePlayer(name, glove)
    local fp = {
        name                = name,
        currentGlove        = glove,
        lastSlapTime        = 0,
        lastAbilityTime     = 0,
        lastAbility2Time    = 0,
        lastAdminCommandTime = 0,
        adminCommandsUsed   = {},
        isAggro             = false,
        isDead              = false,
        isCounterActive     = false,
        slapsTaken          = 0,
        slapsGiven          = 0,
        character           = nil,
        humanoid            = nil,
        rootPart            = nil,
        freezeConnection    = nil,
        freezeEffect        = nil,
        aggroTarget         = nil,
        aggroTurret         = nil,
        aggroRoomba         = nil,
        wanderTarget        = nil,
        -- Acceleration Glove state
        accelSpeed          = CONFIG.ACCEL_BASE_SPEED,
        accelTickTimer      = 0,
        accelCrashStunned   = false,
        accelStunEndTime    = 0,
        -- Pyromania Glove state
        pyroDummyGasoline   = {},
        pyroGasolineActive  = false,
        pyroGasolineEndTime = 0,
        pyroGasolineTimer   = 0,
        pyroIgnitedOwn      = false,
    }

    local model     = Instance.new("Model")
    model.Name      = name
    model.Parent    = workspace

    local head = Instance.new("Part")
    head.Name      = "Head"
    head.Size      = Vector3.new(2, 1, 1)
    head.Color     = Color3.fromRGB(255, 204, 153)
    head.TopSurface    = Enum.SurfaceType.Smooth
    head.BottomSurface = Enum.SurfaceType.Smooth
    head.Parent    = model

    local face     = Instance.new("Decal")
    face.Texture   = "rbxasset://textures/face.png"
    face.Parent    = head

    local torso = Instance.new("Part")
    torso.Name     = "Torso"
    torso.Size     = Vector3.new(2, 2, 1)
    torso.Color    = Color3.fromRGB(0, 0, 255)
    torso.TopSurface    = Enum.SurfaceType.Smooth
    torso.BottomSurface = Enum.SurfaceType.Smooth
    torso.Parent   = model

    local leftArm = Instance.new("Part")
    leftArm.Name  = "Left Arm"
    leftArm.Size  = Vector3.new(1, 2, 1)
    leftArm.Color = Color3.fromRGB(255, 204, 153)
    leftArm.TopSurface    = Enum.SurfaceType.Smooth
    leftArm.BottomSurface = Enum.SurfaceType.Smooth
    leftArm.Parent = model

    local rightArm = Instance.new("Part")
    rightArm.Name  = "Right Arm"
    rightArm.Size  = Vector3.new(1, 2, 1)
    rightArm.Color = Color3.fromRGB(255, 204, 153)
    rightArm.TopSurface    = Enum.SurfaceType.Smooth
    rightArm.BottomSurface = Enum.SurfaceType.Smooth
    rightArm.Parent = model

    local leftLeg = Instance.new("Part")
    leftLeg.Name  = "Left Leg"
    leftLeg.Size  = Vector3.new(1, 2, 1)
    leftLeg.Color = Color3.fromRGB(0, 255, 0)
    leftLeg.TopSurface    = Enum.SurfaceType.Smooth
    leftLeg.BottomSurface = Enum.SurfaceType.Smooth
    leftLeg.Parent = model

    local rightLeg = Instance.new("Part")
    rightLeg.Name  = "Right Leg"
    rightLeg.Size  = Vector3.new(1, 2, 1)
    rightLeg.Color = Color3.fromRGB(0, 255, 0)
    rightLeg.TopSurface    = Enum.SurfaceType.Smooth
    rightLeg.BottomSurface = Enum.SurfaceType.Smooth
    rightLeg.Parent = model

    local hrp = Instance.new("Part")
    hrp.Name         = "HumanoidRootPart"
    hrp.Size         = Vector3.new(2, 2, 1)
    hrp.Transparency = 1
    hrp.Parent       = model

    local spawnPos = Vector3.new(
        math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2),
        10,
        math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2)
    )

    hrp.Position      = spawnPos
    torso.Position    = spawnPos
    head.Position     = spawnPos + Vector3.new(0, 1.5, 0)
    leftArm.Position  = spawnPos + Vector3.new(-1.5, 0, 0)
    rightArm.Position = spawnPos + Vector3.new(1.5, 0, 0)
    leftLeg.Position  = spawnPos + Vector3.new(-0.5, -2, 0)
    rightLeg.Position = spawnPos + Vector3.new(0.5, -2, 0)

    local function weld(p0, p1, c0)
        local w    = Instance.new("Weld")
        w.Part0    = p0
        w.Part1    = p1
        w.C0       = c0
        w.Parent   = p0
        return w
    end

    weld(torso, hrp,      CFrame.new())
    weld(torso, head,     CFrame.new(0, 1.5, 0))
    weld(torso, leftArm,  CFrame.new(-1.5, 0, 0))
    weld(torso, rightArm, CFrame.new(1.5, 0, 0))
    weld(torso, leftLeg,  CFrame.new(-0.5, -2, 0))
    weld(torso, rightLeg, CFrame.new(0.5, -2, 0))

    local hum          = Instance.new("Humanoid")
    hum.MaxHealth      = 100
    hum.Health         = 100
    hum.Parent         = model

    local gloveVis           = Instance.new("Part")
    gloveVis.Name            = "GloveVisual"
    gloveVis.Size            = Vector3.new(1, 1, 1)
    gloveVis.Color           = GLOVE_DATA[glove].Color
    gloveVis.Material        = Enum.Material.Neon
    gloveVis.Parent          = model
    weld(rightArm, gloveVis, CFrame.new(0, -1, 0))

    -- Speed trail for Acceleration Glove dummies
    if glove == "Acceleration Glove" then
        local trail          = Instance.new("Trail")
        local ta0            = Instance.new("Attachment")
        local ta1            = Instance.new("Attachment")
        ta0.Position         = Vector3.new(0, 1, 0)
        ta1.Position         = Vector3.new(0, -1, 0)
        ta0.Parent           = hrp
        ta1.Parent           = hrp
        trail.Attachment0    = ta0
        trail.Attachment1    = ta1
        trail.Color          = ColorSequence.new(Color3.fromRGB(255, 80, 0))
        trail.Lifetime       = 0.3
        trail.MinLength      = 0
        trail.Parent         = model
    end

    fp.character = model
    fp.humanoid  = hum
    fp.rootPart  = hrp

    return fp
end

-- ============================================================
-- FAKE PLAYER NAME TAG
-- ============================================================
local function createNameTag(fp)
    if not fp.character or not fp.character:FindFirstChild("Head") then return end

    local bbGui            = Instance.new("BillboardGui")
    bbGui.Name             = "NameTag"
    bbGui.Size             = UDim2.new(0, 120, 0, 50)
    bbGui.StudsOffset      = Vector3.new(0, 2.5, 0)
    bbGui.AlwaysOnTop      = true
    bbGui.Parent           = fp.character.Head

    local nameLabel        = Instance.new("TextLabel")
    nameLabel.Size         = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text         = fp.name
    nameLabel.TextColor3   = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled   = true
    nameLabel.Font         = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Parent       = bbGui

    local gloveLabel       = Instance.new("TextLabel")
    gloveLabel.Size        = UDim2.new(1, 0, 0.5, 0)
    gloveLabel.Position    = UDim2.new(0, 0, 0.5, 0)
    gloveLabel.BackgroundTransparency = 1
    gloveLabel.Text        = fp.currentGlove
    gloveLabel.TextColor3  = GLOVE_DATA[fp.currentGlove].Color
    gloveLabel.TextScaled  = true
    gloveLabel.Font        = Enum.Font.Gotham
    gloveLabel.TextStrokeTransparency = 0.5
    gloveLabel.Parent      = bbGui
end

-- ============================================================
-- FAKE PLAYER AI — MAIN UPDATE
-- ============================================================
local function updateFakePlayerAI(fp, dt)
    if fp.isDead then return end
    if not fp.character or not fp.rootPart or not fp.humanoid then return end
    if isTimeStopActive then return end
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    if humanoid.Health <= 0 then return end

    local fakeRoot   = fp.rootPart
    local playerRoot = character.HumanoidRootPart
    local distance   = (playerRoot.Position - fakeRoot.Position).Magnitude

    -- --------------------------------------------------------
    -- ACCELERATION GLOVE: special per-frame update
    -- (handles speed gain, crash detection for dummy)
    -- --------------------------------------------------------
    if fp.currentGlove == "Acceleration Glove" then
        updateAccelDummy(fp, dt)

        if fp.accelCrashStunned then
            -- stunned; do nothing this frame
            return
        end
    end

    if fp.isAggro then
        -- Determine movement target
        local targetPos   = playerRoot.Position
        local targetValid = false

        if fp.aggroTarget == "turret" and fp.aggroTurret then
            if fp.aggroTurret.head and fp.aggroTurret.head.Parent and fp.aggroTurret.health > 0 then
                targetPos   = fp.aggroTurret.head.Position
                targetValid = true
            else
                fp.aggroTarget = "roomba"
            end
        end

        if fp.aggroTarget == "roomba" and fp.aggroRoomba then
            if fp.aggroRoomba.part and fp.aggroRoomba.part.Parent and fp.aggroRoomba.health > 0 then
                targetPos   = fp.aggroRoomba.part.Position
                targetValid = true
            else
                fp.aggroTarget = nil
            end
        end

        fp.humanoid:MoveTo(targetPos)

        local distToTarget = (targetPos - fakeRoot.Position).Magnitude

        -- Acceleration Glove dummy never manually slaps; it only crashes
        if fp.currentGlove ~= "Acceleration Glove" then
            if distToTarget <= CONFIG.SLAP_DISTANCE then
                local ct        = tick()
                local gData     = GLOVE_DATA[fp.currentGlove]

                if ct - fp.lastSlapTime >= gData.SlapCooldown then
                    fp.lastSlapTime = ct

                    if not targetValid and isCounterActive then
                        triggerCounterPunishment(fp.character)
                    else
                        local slapPos = fakeRoot.Position + (targetPos - fakeRoot.Position).Unit * 3
                        createSlapEffect(slapPos, gData.Color)

                        if fp.aggroTarget == "turret" and fp.aggroTurret then
                            fp.aggroTurret.health = fp.aggroTurret.health - 5
                        elseif fp.aggroTarget == "roomba" and fp.aggroRoomba then
                            fp.aggroRoomba.health = fp.aggroRoomba.health - 5
                        else
                            local slapDir
                            if fp.currentGlove == "RNG Glove" then
                                local rA = math.random() * math.pi * 2
                                local rE = (math.random() - 0.5) * math.pi * 0.5
                                slapDir  = Vector3.new(
                                    math.cos(rA) * math.cos(rE),
                                    math.sin(rE),
                                    math.sin(rA) * math.cos(rE)
                                ).Unit
                            else
                                slapDir = (playerRoot.Position - fakeRoot.Position).Unit
                            end

                            applyForce(character, slapDir, gData.PushPower)
                            playerSlapCount  = playerSlapCount + 1
                            fp.slapsGiven    = fp.slapsGiven + 1
                        end
                    end
                end
            end
        end

        -- ----------------------------------------------------
        -- ABILITY USAGE (non-Acceleration, non-Admin gloves)
        -- ----------------------------------------------------
        if fp.currentGlove ~= "Acceleration Glove" then
            local ct    = tick()
            local gData = GLOVE_DATA[fp.currentGlove]

            if ct - fp.lastAbilityTime >= gData.AbilityCooldown then
                if fp.currentGlove == "Siphon Glove" then
                    if distance <= 20 then
                        fp.lastAbilityTime = ct
                        activateSiphonAbility(fp, false)
                    end
                elseif fp.currentGlove == "Train Glove" then
                    if humanoid.MoveDirection.Magnitude < 0.1 then
                        fp.lastAbilityTime = ct
                        activateTrainAbility(fp, false)
                    end
                elseif fp.currentGlove == "Counter Glove" then
                    if distance <= 5 then
                        fp.lastAbilityTime = ct
                        activateCounterAbility(fp, false)
                    end
                elseif fp.currentGlove == "God Glove" then
                    if fp.slapsTaken >= 10 then
                        fp.lastAbilityTime = ct
                        fp.slapsTaken      = 0
                        activateTimeStopAbility()
                    end
                elseif fp.currentGlove == "LandMine Glove" then
                    if math.random(1, 100) <= 30 then
                        fp.lastAbilityTime = ct
                        activateLandMineAbility(fp, false)
                    end
                elseif fp.currentGlove == "Engineer Glove" then
                    if fp.slapsTaken == 1 or (fp.slapsTaken > 1 and fp.slapsTaken % 5 == 0) then
                        fp.lastAbilityTime = ct
                        activateEngineerTurret(fp, false)
                    end
                    if fp.slapsGiven >= 3 then
                        fp.slapsGiven = 0
                        activateEngineerRoombas(fp, false)
                    end
                elseif fp.currentGlove == "AirBomb Glove" then
                    if distance >= 75 and distance <= 100 then
                        fp.lastAbilityTime = ct
                        activateAirBombAbility(fp, false)
                    end
                elseif fp.currentGlove == "Admin Glove" then
                    -- Admin AI commands
                    if ct - fp.lastAdminCommandTime >= 20 then
                        fp.lastAdminCommandTime = ct

                        local availCmds = {}
                        if distance > 30 then
                            table.insert(availCmds, "speed")
                            table.insert(availCmds, "jumppower")
                        end
                        if distance < 50 then
                            table.insert(availCmds, "explode")
                            table.insert(availCmds, "anvil")
                            table.insert(availCmds, "ragdoll")
                        end
                        table.insert(availCmds, "goto")
                        table.insert(availCmds, "train")

                        if #availCmds > 0 then
                            local chosen = availCmds[math.random(1, #availCmds)]

                            if chosen == "speed" then
                                local sv = math.random(20, 40)
                                if fp.humanoid then fp.humanoid.WalkSpeed = sv end
                                sendFakePlayerChat(fp.name, "/Speed " .. sv)
                            elseif chosen == "jumppower" then
                                local jv = math.random(60, 100)
                                if fp.humanoid then fp.humanoid.JumpPower = jv end
                                sendFakePlayerChat(fp.name, "/JumpPower " .. jv)
                            elseif chosen == "explode" then
                                if character and character:FindFirstChild("HumanoidRootPart") then
                                    sendFakePlayerChat(fp.name, "/Explode " .. player.Name)
                                    spawn(function()
                                        wait(1)
                                        local exp            = Instance.new("Explosion")
                                        exp.Position         = character.HumanoidRootPart.Position
                                        exp.BlastRadius      = 10
                                        exp.BlastPressure    = 0
                                        exp.Parent           = workspace
                                        local rA = math.random() * math.pi * 2
                                        local rE = (math.random() - 0.5) * math.pi * 0.5
                                        local dir = Vector3.new(math.cos(rA)*math.cos(rE), math.sin(rE), math.sin(rA)*math.cos(rE)).Unit
                                        applyForce(character, dir, 12)
                                    end)
                                end
                            elseif chosen == "anvil" then
                                if character and character:FindFirstChild("HumanoidRootPart") then
                                    sendFakePlayerChat(fp.name, "/Anvil " .. player.Name)
                                    spawn(function()
                                        wait(1)
                                        local pr = character.HumanoidRootPart
                                        local anvilPos = pr.Position + Vector3.new(0, 20, 0)
                                        local anv = Instance.new("Part")
                                        anv.Name = "Anvil"; anv.Size = Vector3.new(3, 2, 3)
                                        anv.Position = anvilPos; anv.Anchored = false
                                        anv.Material = Enum.Material.Metal; anv.Color = Color3.fromRGB(80, 80, 80)
                                        anv.Parent = workspace
                                        local bv = Instance.new("BodyVelocity")
                                        bv.MaxForce = Vector3.new(0, 4e4, 0); bv.Velocity = Vector3.new(0, -100, 0)
                                        bv.Parent = anv
                                        local hc; hc = anv.Touched:Connect(function(hit)
                                            if hit.Parent == character then
                                                applyForce(character, Vector3.new(0, -1, 0), 13)
                                                hc:Disconnect(); Debris:AddItem(anv, 1)
                                            end
                                        end)
                                        Debris:AddItem(anv, 3)
                                    end)
                                end
                            elseif chosen == "ragdoll" then
                                if character and humanoid and character:FindFirstChild("HumanoidRootPart") then
                                    sendFakePlayerChat(fp.name, "/Ragdoll " .. player.Name)
                                    spawn(function()
                                        wait(0.5)
                                        humanoid.PlatformStand = true
                                        local rd = Vector3.new(math.random(-1,1), math.random(0,1), math.random(-1,1)).Unit
                                        applyForce(character, rd, 15)
                                        spawn(function()
                                            wait(3)
                                            if humanoid then humanoid.PlatformStand = false end
                                        end)
                                    end)
                                end
                            elseif chosen == "goto" then
                                if character and rootPart and fp.rootPart then
                                    sendFakePlayerChat(fp.name, "/Goto " .. player.Name)
                                    spawn(function()
                                        wait(0.3)
                                        fp.rootPart.CFrame = rootPart.CFrame + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
                                    end)
                                end
                            elseif chosen == "train" then
                                sendFakePlayerChat(fp.name, "/Train")
                                activateTrainAbility(fp, false)
                            end
                        end
                    end
                end
            end
        end -- end non-accel ability check

    else
        -- NOT aggro: wander
        if not fp.wanderTarget
        or (fp.rootPart.Position - fp.wanderTarget).Magnitude < 5 then
            fp.wanderTarget = Vector3.new(
                math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2),
                fp.rootPart.Position.Y,
                math.random(-CONFIG.ARENA_SIZE/2, CONFIG.ARENA_SIZE/2)
            )
        end
        fp.humanoid:MoveTo(fp.wanderTarget)
    end
end

-- ============================================================
-- INITIALIZE FAKE PLAYERS
-- ============================================================
local function initializeFakePlayers()
    local gloveNames = {}
    for name, _ in pairs(GLOVE_DATA) do
        table.insert(gloveNames, name)
    end

    local fpNames = {
        "Bot_Alpha", "Bot_Beta", "Bot_Gamma", "Bot_Delta", "Bot_Epsilon",
    }

    for i = 1, CONFIG.MAX_FAKE_PLAYERS do
        local rg = gloveNames[math.random(1, #gloveNames)]
        local fp = createFakePlayer(fpNames[i], rg)
        fp.wanderTarget = fp.rootPart.Position
        table.insert(fakePlayersList, fp)
    end
end

-- ============================================================
-- FAKE PLAYER HEALTH MONITORING + RESPAWN
-- ============================================================
-- Tracks which indices are already queued for respawn so we don't double-spawn
local respawningIndices = {}

local function respawnFakePlayer(i, fp)
    if respawningIndices[i] then return end
    respawningIndices[i] = true

    -- Remove from aggro list immediately
    for j, aggro in ipairs(aggroedFakePlayers) do
        if aggro == fp then
            table.remove(aggroedFakePlayers, j)
            break
        end
    end

    -- Destroy character model if it still exists
    if fp.character and fp.character.Parent then
        fp.character:Destroy()
    end

    -- Mark fp as dead so AI loop skips it
    fp.isDead = true

    spawn(function()
        wait(CONFIG.RESPAWN_TIME)

        local gloveNames = {}
        for name, _ in pairs(GLOVE_DATA) do
            table.insert(gloveNames, name)
        end
        -- Pick a DIFFERENT glove from the one the old dummy had
        local newGlove
        repeat
            newGlove = gloveNames[math.random(1, #gloveNames)]
        until newGlove ~= fp.currentGlove or #gloveNames == 1

        local newFp = createFakePlayer(fp.name, newGlove)
        newFp.wanderTarget = newFp.rootPart.Position
        fakePlayersList[i] = newFp
        respawningIndices[i] = nil
        createNameTag(newFp)

        -- Chat notification about respawn with new glove
        spawn(function()
            sendFakePlayerChat(newFp.name, "Respawned with " .. newGlove .. "!")
        end)
    end)
end

local function checkFakePlayerHealth()
    RunService.Heartbeat:Connect(function()
        for i, fp in ipairs(fakePlayersList) do
            if fp.isDead then continue end

            -- Condition 1: humanoid died normally
            local healthDead = fp.humanoid and fp.humanoid.Health <= 0

            -- Condition 2: model was destroyed (void kill, workspace cleanup, etc.)
            local modelGone = fp.character == nil
                or fp.character.Parent == nil

            -- Condition 3: rootPart gone
            local rootGone = fp.rootPart == nil
                or fp.rootPart.Parent == nil

            if healthDead or modelGone or rootGone then
                respawnFakePlayer(i, fp)
            end
        end
    end)
end

-- ============================================================
-- MAIN GAME LOOP (Heartbeat)
-- ============================================================
local function gameLoop()
    RunService.Heartbeat:Connect(function(dt)
        for _, fp in ipairs(fakePlayersList) do
            updateFakePlayerAI(fp, dt)
        end
    end)
end

-- ============================================================
-- PLAYER DEATH HANDLING
-- ============================================================
local function onPlayerDeath()
    humanoid.Died:Connect(function()
        wait(CONFIG.RESPAWN_TIME)
        if character and character.Parent then
            character:BreakJoints()
        end
        player:LoadCharacter()
    end)
end

-- ============================================================
-- CHARACTER SETUP
-- ============================================================
local function setupCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid  = character:WaitForChild("Humanoid")
    rootPart  = character:WaitForChild("HumanoidRootPart")
    createGloveTool()
    onPlayerDeath()
end

player.CharacterAdded:Connect(function(char)
    wait(0.5)
    setupCharacter()
end)

-- ============================================================
-- KEYBOARD INPUT (non-rhythm)
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.E then
        if equippedGlove and currentGlove ~= "Song Glove" then
            playerSlap()
        end
    elseif input.KeyCode == Enum.KeyCode.Q then
        local gData = GLOVE_DATA[currentGlove]
        if gData and gData.AbilityType ~= "None" and currentGlove ~= "Song Glove" then
            abilityButton.MouseButton1Click:Fire()
        end
    end
end)

-- ============================================================
-- STATS GUI (top right)
-- ============================================================
local function createStatsGUI()
    local statsFrame             = Instance.new("Frame")
    statsFrame.Name              = "StatsFrame"
    statsFrame.Size              = UDim2.new(0, 260, 0, 170)
    statsFrame.Position          = UDim2.new(1, -280, 0, 20)
    statsFrame.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
    statsFrame.BorderSizePixel   = 2
    statsFrame.BorderColor3      = Color3.fromRGB(255, 255, 255)
    statsFrame.BackgroundTransparency = 0.3
    statsFrame.Parent            = screenGui

    local statsTitle             = Instance.new("TextLabel")
    statsTitle.Size              = UDim2.new(1, 0, 0, 30)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text              = "CURRENT GLOVE"
    statsTitle.TextColor3        = Color3.fromRGB(255, 255, 255)
    statsTitle.TextScaled        = true
    statsTitle.Font              = Enum.Font.GothamBold
    statsTitle.Parent            = statsFrame

    local gloveNameLabel         = Instance.new("TextLabel")
    gloveNameLabel.Name          = "GloveName"
    gloveNameLabel.Size          = UDim2.new(1, -10, 0, 25)
    gloveNameLabel.Position      = UDim2.new(0, 5, 0, 32)
    gloveNameLabel.BackgroundTransparency = 1
    gloveNameLabel.Text          = currentGlove
    gloveNameLabel.TextColor3    = Color3.fromRGB(255, 255, 0)
    gloveNameLabel.TextSize      = 18
    gloveNameLabel.Font          = Enum.Font.GothamBold
    gloveNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    gloveNameLabel.Parent        = statsFrame

    local statsInfoLabel         = Instance.new("TextLabel")
    statsInfoLabel.Name          = "StatsInfo"
    statsInfoLabel.Size          = UDim2.new(1, -10, 1, -70)
    statsInfoLabel.Position      = UDim2.new(0, 5, 0, 65)
    statsInfoLabel.BackgroundTransparency = 1
    statsInfoLabel.TextColor3    = Color3.fromRGB(200, 200, 200)
    statsInfoLabel.TextSize      = 13
    statsInfoLabel.Font          = Enum.Font.Gotham
    statsInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
    statsInfoLabel.Parent        = statsFrame

    local function updateStats()
        gloveNameLabel.Text = currentGlove
        local gd = GLOVE_DATA[currentGlove]
        local extra = ""
        if currentGlove == "Acceleration Glove" then
            extra = string.format("\nCurrent Speed: %d\nPush Power: %d",
                math.floor(accelCurrentSpeed),
                getAccelPushPower(accelCurrentSpeed)
            )
        end
        statsInfoLabel.Text = string.format(
            "Base Push: %d\nSlap CD: %.1fs\nType: %s\nAbility CD: %ds%s",
            gd.PushPower, gd.SlapCooldown, gd.AbilityType, gd.AbilityCooldown, extra
        )
    end

    updateStats()

    RunService.Heartbeat:Connect(function()
        if gloveNameLabel.Text ~= currentGlove then
            updateStats()
        elseif currentGlove == "Acceleration Glove" then
            updateStats()
        end
    end)
end

-- ============================================================
-- COOLDOWN BAR (bottom center)
-- ============================================================
local function createCooldownIndicator()
    local barFrame             = Instance.new("Frame")
    barFrame.Name              = "CooldownBar"
    barFrame.Size              = UDim2.new(0, 200, 0, 20)
    barFrame.Position          = UDim2.new(0.5, -100, 1, -100)
    barFrame.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
    barFrame.BorderSizePixel   = 2
    barFrame.BorderColor3      = Color3.fromRGB(255, 255, 255)
    barFrame.Parent            = screenGui

    local barFill              = Instance.new("Frame")
    barFill.Name               = "Fill"
    barFill.Size               = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3   = Color3.fromRGB(0, 255, 0)
    barFill.BorderSizePixel    = 0
    barFill.Parent             = barFrame

    local barText              = Instance.new("TextLabel")
    barText.Size               = UDim2.new(1, 0, 1, 0)
    barText.BackgroundTransparency = 1
    barText.Text               = "READY"
    barText.TextColor3         = Color3.fromRGB(255, 255, 255)
    barText.TextScaled         = true
    barText.Font               = Enum.Font.GothamBold
    barText.TextStrokeTransparency = 0.5
    barText.ZIndex             = 2
    barText.Parent             = barFrame

    RunService.Heartbeat:Connect(function()
        local gd       = GLOVE_DATA[currentGlove]
        local elapsed  = tick() - lastSlapTime

        if elapsed >= gd.SlapCooldown then
            barFill.Size             = UDim2.new(1, 0, 1, 0)
            barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            barText.Text             = "READY"
        else
            local progress           = elapsed / gd.SlapCooldown
            barFill.Size             = UDim2.new(progress, 0, 1, 0)
            barFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            barText.Text             = string.format("%.1f", gd.SlapCooldown - elapsed)
        end
    end)
end

-- ============================================================
-- ARENA CREATION
-- ============================================================
local function createArena()
    local arena            = Instance.new("Part")
    arena.Name             = "Arena"
    arena.Size             = Vector3.new(CONFIG.ARENA_SIZE, 1, CONFIG.ARENA_SIZE)
    arena.Position         = Vector3.new(0, 0, 0)
    arena.Anchored         = true
    arena.Material         = Enum.Material.Concrete
    arena.Color            = Color3.fromRGB(150, 150, 150)
    arena.Parent           = workspace

    local spawn            = Instance.new("SpawnLocation")
    spawn.Size             = Vector3.new(10, 1, 10)
    spawn.Position         = Vector3.new(0, 1, 0)
    spawn.Anchored         = true
    spawn.CanCollide       = true
    spawn.Transparency     = 0.5
    spawn.BrickColor       = BrickColor.new("Bright green")
    spawn.Parent           = workspace
end

-- ============================================================
-- DEATH ZONE
-- ============================================================
local function createDeathZone()
    local dz               = Instance.new("Part")
    dz.Name                = "DeathZone"
    dz.Size                = Vector3.new(CONFIG.ARENA_SIZE * 2, 5, CONFIG.ARENA_SIZE * 2)
    dz.Position            = Vector3.new(0, -50, 0)
    dz.Anchored            = true
    dz.CanCollide          = false
    dz.Transparency        = 1
    dz.Parent              = workspace

    dz.Touched:Connect(function(hit)
        if hit.Parent:FindFirstChild("Humanoid") then
            hit.Parent.Humanoid.Health = 0
        end
    end)
end

-- ============================================================
-- DEBUG MODE (optional — uncomment enableDebugMode() to use)
-- ============================================================
local function getClosestFakePlayer()
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return nil, 0
    end
    local pr       = character.HumanoidRootPart
    local closest  = nil
    local closestD = math.huge
    for _, fp in ipairs(fakePlayersList) do
        if fp.character and fp.rootPart then
            local d = (fp.rootPart.Position - pr.Position).Magnitude
            if d < closestD then closestD = d; closest = fp end
        end
    end
    return closest, closestD
end

local function enableDebugMode()
    local debugLabel               = Instance.new("TextLabel")
    debugLabel.Name                = "DebugInfo"
    debugLabel.Size                = UDim2.new(0, 350, 0, 250)
    debugLabel.Position            = UDim2.new(0, 20, 1, -270)
    debugLabel.BackgroundColor3    = Color3.fromRGB(0, 0, 0)
    debugLabel.BackgroundTransparency = 0.5
    debugLabel.TextColor3          = Color3.fromRGB(0, 255, 0)
    debugLabel.TextSize            = 11
    debugLabel.Font                = Enum.Font.Code
    debugLabel.TextXAlignment      = Enum.TextXAlignment.Left
    debugLabel.TextYAlignment      = Enum.TextYAlignment.Top
    debugLabel.Parent              = screenGui

    RunService.Heartbeat:Connect(function()
        local cf, cd     = getClosestFakePlayer()
        local aggroCount = #aggroedFakePlayers
        local accelExtra = ""
        if currentGlove == "Acceleration Glove" then
            accelExtra = string.format(
                "\nAccel Speed: %d\nAccel Power: %d\nCrash Stunned: %s",
                math.floor(accelCurrentSpeed),
                getAccelPushPower(accelCurrentSpeed),
                tostring(accelIsCrashStunned)
            )
        end

        debugLabel.Text = string.format(
            "=== DEBUG INFO ===\nCurrent Glove: %s\nAggro Count: %d\nAlive Bots: %d\nClosest Bot: %s\nDistance: %.1f\nEquipped: %s%s",
            currentGlove,
            aggroCount,
            #fakePlayersList,
            cf and cf.name or "None",
            cd or 0,
            equippedGlove and "Yes" or "No",
            accelExtra
        )
    end)
end

-- ============================================================
-- INITIALIZE EVERYTHING
-- ============================================================
local function initialize()
    print("=== Slap Battles v2.0 Initializing ===")

    createArena()
    createDeathZone()
    createStatsGUI()
    createCooldownIndicator()
    setupCharacter()
    initializeFakePlayers()

    for _, fp in ipairs(fakePlayersList) do
        createNameTag(fp)
    end

    checkFakePlayerHealth()
    gameLoop()

    print("Controls: E = Slap | Q = Ability | GLOVES button = select glove")
    print("NEW: Acceleration Glove - gain speed over time, crash into enemies!")
    print("=== Initialized! ===")
end

-- ============================================================
-- START
-- ============================================================
wait(1)
initialize()

-- Uncomment to enable debug overlay:
-- enableDebugMode()

-- ============================================================
print("=== SLAP BATTLES LOADED (v2.0 - Acceleration Glove) ===")
-- ============================================================

-- ============================================================
-- SESSION STATS TRACKER
-- Tracks slaps given, received, crashes, and ability uses
-- across the current session.
-- ============================================================
local sessionStats = {
    slapsGiven       = 0,
    slapsReceived    = 0,
    crashesPerformed = 0,
    abilitiesUsed    = 0,
    sessionStart     = tick(),
}

local function incrementStat(statName)
    if sessionStats[statName] ~= nil then
        sessionStats[statName] = sessionStats[statName] + 1
    end
end

-- ============================================================
-- SESSION STATS GUI (bottom left corner)
-- ============================================================
local function createSessionStatsGUI()
    local statsFrame             = Instance.new("Frame")
    statsFrame.Name              = "SessionStats"
    statsFrame.Size              = UDim2.new(0, 200, 0, 130)
    statsFrame.Position          = UDim2.new(0, 20, 1, -160)
    statsFrame.BackgroundColor3  = Color3.fromRGB(20, 20, 20)
    statsFrame.BorderSizePixel   = 2
    statsFrame.BorderColor3      = Color3.fromRGB(100, 100, 100)
    statsFrame.BackgroundTransparency = 0.4
    statsFrame.Parent            = screenGui

    local titleLabel             = Instance.new("TextLabel")
    titleLabel.Size              = UDim2.new(1, 0, 0, 24)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text              = "SESSION STATS"
    titleLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled        = true
    titleLabel.Font              = Enum.Font.GothamBold
    titleLabel.Parent            = statsFrame

    local statsText              = Instance.new("TextLabel")
    statsText.Name               = "StatsText"
    statsText.Size               = UDim2.new(1, -8, 1, -28)
    statsText.Position           = UDim2.new(0, 4, 0, 26)
    statsText.BackgroundTransparency = 1
    statsText.TextColor3         = Color3.fromRGB(200, 200, 200)
    statsText.TextSize           = 12
    statsText.Font               = Enum.Font.Gotham
    statsText.TextXAlignment     = Enum.TextXAlignment.Left
    statsText.TextYAlignment     = Enum.TextYAlignment.Top
    statsText.Parent             = statsFrame

    -- Update every second
    spawn(function()
        while true do
            wait(1)
            local elapsed    = tick() - sessionStats.sessionStart
            local mins       = math.floor(elapsed / 60)
            local secs       = math.floor(elapsed % 60)

            statsText.Text = string.format(
                "Slaps Given: %d\nSlaps Received: %d\nCrashes: %d\nAbilities: %d\nTime: %02d:%02d",
                sessionStats.slapsGiven,
                sessionStats.slapsReceived,
                sessionStats.crashesPerformed,
                sessionStats.abilitiesUsed,
                mins,
                secs
            )
        end
    end)
end

createSessionStatsGUI()

-- ============================================================
-- ACCELERATION GLOVE — SPEED TIER CHANGE NOTIFICATION
-- Pops up on screen when the player crosses a speed threshold
-- ============================================================
local accelLastNotifiedTier = 0  -- 0 = below 50, 1 = 50-100, 2 = 100-200, 3 = 200-300

local function getAccelSpeedTier(speed)
    if speed >= 200 then return 3
    elseif speed >= 100 then return 2
    elseif speed >= 50  then return 1
    else return 0 end
end

local function showSpeedTierNotification(tier)
    local labels = {
        [1] = { text = "SPEED TIER 1",  color = Color3.fromRGB(80, 220, 80),   sub = "Power: 5" },
        [2] = { text = "SPEED TIER 2",  color = Color3.fromRGB(255, 180, 0),   sub = "Power: 8" },
        [3] = { text = "MAX SPEED!",    color = Color3.fromRGB(255, 50, 0),    sub = "Power: 12 — CRITICAL" },
    }

    local info = labels[tier]
    if not info then return end

    local notifFrame             = Instance.new("Frame")
    notifFrame.Size              = UDim2.new(0, 260, 0, 56)
    notifFrame.Position          = UDim2.new(0.5, -130, 0.25, 0)
    notifFrame.BackgroundColor3  = Color3.fromRGB(20, 20, 20)
    notifFrame.BorderSizePixel   = 3
    notifFrame.BorderColor3      = info.color
    notifFrame.BackgroundTransparency = 0.2
    notifFrame.Parent            = screenGui

    local mainLabel              = Instance.new("TextLabel")
    mainLabel.Size               = UDim2.new(1, 0, 0.55, 0)
    mainLabel.BackgroundTransparency = 1
    mainLabel.Text               = info.text
    mainLabel.TextColor3         = info.color
    mainLabel.TextScaled         = true
    mainLabel.Font               = Enum.Font.GothamBold
    mainLabel.Parent             = notifFrame

    local subLabel               = Instance.new("TextLabel")
    subLabel.Size                = UDim2.new(1, 0, 0.45, 0)
    subLabel.Position            = UDim2.new(0, 0, 0.55, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.Text                = info.sub
    subLabel.TextColor3          = Color3.fromRGB(220, 220, 220)
    subLabel.TextScaled          = true
    subLabel.Font                = Enum.Font.Gotham
    subLabel.Parent              = notifFrame

    -- Slide in from left
    notifFrame.Position = UDim2.new(-0.3, 0, 0.25, 0)
    TweenService:Create(notifFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -130, 0.25, 0)
    }):Play()

    wait(1.8)

    TweenService:Create(notifFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position          = UDim2.new(1.1, 0, 0.25, 0),
        BackgroundTransparency = 1,
    }):Play()

    wait(0.25)
    notifFrame:Destroy()
end

-- Hook into the acceleration HUD update to fire tier notifications
local _origUpdateAccelHud = updateAccelHud
updateAccelHud = function()
    _origUpdateAccelHud()

    if currentGlove ~= "Acceleration Glove" then return end

    local tier = getAccelSpeedTier(accelCurrentSpeed)
    if tier ~= accelLastNotifiedTier and tier > accelLastNotifiedTier then
        accelLastNotifiedTier = tier
        spawn(function()
            showSpeedTierNotification(tier)
        end)
    elseif tier < accelLastNotifiedTier then
        -- Speed dropped back a tier; reset so it can notify again on next climb
        accelLastNotifiedTier = tier
    end
end

-- ============================================================
-- ACCELERATION GLOVE — CHARACTER COLOR TINT ON SPEED TIERS
-- Tints the player's torso/arms to reflect current speed tier
-- ============================================================
local accelLastColorTier = -1

local function applyAccelColorTint(tier)
    if not character then return end

    local colors = {
        [0] = Color3.fromRGB(0, 0, 255),        -- default blue torso
        [1] = Color3.fromRGB(80, 180, 80),       -- green tint
        [2] = Color3.fromRGB(255, 160, 0),       -- orange tint
        [3] = Color3.fromRGB(220, 40, 0),        -- red tint (max speed)
    }

    local col = colors[tier] or colors[0]

    for _, partName in ipairs({ "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            TweenService:Create(part, TweenInfo.new(0.3), { Color = col }):Play()
        end
    end
end

-- Poll tier changes and apply tint
RunService.Heartbeat:Connect(function()
    if currentGlove ~= "Acceleration Glove" or not equippedGlove then
        -- Restore original colors if glove was unequipped
        if accelLastColorTier ~= -1 then
            accelLastColorTier = -1
            if character then
                local origColors = {
                    Torso        = Color3.fromRGB(0, 0, 255),
                    ["Left Arm"]  = Color3.fromRGB(255, 204, 153),
                    ["Right Arm"] = Color3.fromRGB(255, 204, 153),
                    ["Left Leg"]  = Color3.fromRGB(0, 255, 0),
                    ["Right Leg"] = Color3.fromRGB(0, 255, 0),
                }
                for partName, col in pairs(origColors) do
                    local part = character:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        TweenService:Create(part, TweenInfo.new(0.3), { Color = col }):Play()
                    end
                end
            end
        end
        return
    end

    local tier = getAccelSpeedTier(accelCurrentSpeed)
    if tier ~= accelLastColorTier then
        accelLastColorTier = tier
        applyAccelColorTint(tier)
    end
end)

-- ============================================================
print("=== EXTRA SYSTEMS LOADED: SessionStats | TierNotify | ColorTint ===")
-- ============================================================

-- ============================================================
-- ============================================================
--    PYROMANIA GLOVE — FULL SYSTEM
--    Ability 1 : Gasoline Trail (20s CD)
--    Ability 2 : Ignite          (15s CD)
--    Passive   : Burn on contact with flame (5 dmg/s, 5s)
-- ============================================================
-- ============================================================

-- ============================================================
-- PYROMANIA STATE — PLAYER
-- ============================================================
local pyroGasolineActive       = false   -- is the trail currently being laid?
local pyroGasolineEndTime      = 0       -- when the trail stops (5s after activation)
local activePyroGasoline       = {}      -- list of gasoline puddle parts (player-owned)
local pyroTrailConnection      = nil     -- Heartbeat connection for trail laying

-- ============================================================
-- PYROMANIA STATE — SHARED
-- ============================================================
local activeFlames             = {}      -- list of { flame, owner, gasolinePuddles }
local burningCharacters        = {}      -- { character, endTime, connection }

-- ============================================================
-- PYROMANIA: UTILITY — IS PART GASOLINE?
-- ============================================================
local function isPyroGasolinePart(part)
    return part and part.Name == "PyroGasoline"
end

-- ============================================================
-- PYROMANIA: BURN EFFECT
-- Applies 5 damage/s for 5s to a humanoid character.
-- Stacks are prevented — if already burning, refresh timer.
-- ============================================================
local function applyBurnEffect(targetCharacter)
    if not targetCharacter then return end
    local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
    if not targetHumanoid then return end

    -- Check if already burning; if so, refresh end time only
    for _, entry in ipairs(burningCharacters) do
        if entry.character == targetCharacter then
            entry.endTime = tick() + 5
            return
        end
    end

    -- Not yet burning — create entry
    local entry = {
        character = targetCharacter,
        endTime   = tick() + 5,
        conn      = nil,
    }

    -- Fire visual on target
    local fireEffect      = Instance.new("Fire")
    fireEffect.Name       = "BurnFire"
    fireEffect.Size       = 3
    fireEffect.Heat       = 8
    fireEffect.Color      = Color3.fromRGB(255, 80, 0)
    fireEffect.SecondaryColor = Color3.fromRGB(200, 160, 0)

    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        or targetCharacter:FindFirstChild("Torso")
    if targetRoot then
        fireEffect.Parent = targetRoot
    end

    -- Damage tick every 1 second
    entry.conn = RunService.Heartbeat:Connect(function()
        if not targetCharacter.Parent then
            -- target was destroyed
            if fireEffect.Parent then fireEffect:Destroy() end
            entry.conn:Disconnect()
            for i, e in ipairs(burningCharacters) do
                if e == entry then table.remove(burningCharacters, i) break end
            end
            return
        end

        if tick() >= entry.endTime then
            -- Burn expired
            if fireEffect.Parent then fireEffect:Destroy() end
            entry.conn:Disconnect()
            for i, e in ipairs(burningCharacters) do
                if e == entry then table.remove(burningCharacters, i) break end
            end
            return
        end

        -- Deal 5 damage every ~1s via a small per-tick check
        -- We use a lastDamageTime inside the entry
        if not entry.lastDamageTime then entry.lastDamageTime = tick() end
        if tick() - entry.lastDamageTime >= 1 then
            entry.lastDamageTime = tick()
            if targetHumanoid and targetHumanoid.Health > 0 then
                targetHumanoid.Health = math.max(0, targetHumanoid.Health - 5)
            end
        end
    end)

    table.insert(burningCharacters, entry)
end

-- ============================================================
-- PYROMANIA: CREATE A SINGLE GASOLINE PUDDLE
-- Returns the part so it can be tracked.
-- ============================================================
local function createGasolinePuddle(position, owner)
    local puddle           = Instance.new("Part")
    puddle.Name            = "PyroGasoline"
    puddle.Size            = Vector3.new(3.5, 0.1, 3.5)
    puddle.Position        = Vector3.new(position.X, position.Y - 2.8, position.Z)
    puddle.Anchored        = true
    puddle.CanCollide      = false
    puddle.Material        = Enum.Material.Neon
    puddle.Color           = Color3.fromRGB(80, 255, 80)      -- greenish slick
    puddle.Transparency    = 0.35
    puddle.CastShadow      = false
    puddle.Parent          = workspace

    -- Slight shimmer tween
    local shimmerTween = TweenService:Create(puddle, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Transparency = 0.55,
    })
    shimmerTween:Play()

    local puddleData = {
        part      = puddle,
        owner     = owner,    -- "player" or a fp reference
        ignited   = false,
        shimmer   = shimmerTween,
    }

    return puddleData
end

-- ============================================================
-- PYROMANIA: FLOOD-FILL — find all connected gasoline puddles
-- Two puddles are "connected" if they are within 5 studs of each other.
-- ============================================================
local function getConnectedGasoline(startPuddle, puddleList)
    local connected = {}
    local visited   = {}
    local queue     = { startPuddle }
    visited[startPuddle] = true

    while #queue > 0 do
        local current = table.remove(queue, 1)
        table.insert(connected, current)

        for _, other in ipairs(puddleList) do
            if not visited[other] and not other.ignited then
                local dist = (other.part.Position - current.part.Position).Magnitude
                if dist <= 5 then
                    visited[other]   = true
                    table.insert(queue, other)
                end
            end
        end
    end

    return connected
end

-- ============================================================
-- PYROMANIA: IGNITE A SET OF PUDDLES
-- Turns them into flames, checks for burn contact with dummies.
-- ============================================================
local function ignitePuddles(puddleSet, isPlayer)
    for _, puddleData in ipairs(puddleSet) do
        if puddleData.ignited or not puddleData.part.Parent then continue end
        puddleData.ignited = true
        if puddleData.shimmer then puddleData.shimmer:Cancel() end

        local puddle = puddleData.part

        -- Visual: turn orange/red for flames
        puddle.Color        = Color3.fromRGB(255, 100, 0)
        puddle.Transparency = 0.2

        -- Add fire particle
        local fire           = Instance.new("Fire")
        fire.Name            = "PyroFire"
        fire.Size            = 4
        fire.Heat            = 9
        fire.Color           = Color3.fromRGB(255, 80, 0)
        fire.SecondaryColor  = Color3.fromRGB(200, 40, 0)
        fire.Parent          = puddle

        local flameEntry = {
            puddle    = puddleData,
            fire      = fire,
            isPlayer  = isPlayer,
            startTime = tick(),
        }
        table.insert(activeFlames, flameEntry)

        -- Burn checker for this flame puddle
        local burnConn
        burnConn = RunService.Heartbeat:Connect(function()
            if not puddle.Parent then
                burnConn:Disconnect()
                return
            end

            -- After 20s, extinguish this puddle
            if tick() - flameEntry.startTime >= 20 then
                burnConn:Disconnect()
                if fire.Parent then fire:Destroy() end
                puddle.Transparency = 1
                Debris:AddItem(puddle, 0.5)
                for i, fe in ipairs(activeFlames) do
                    if fe == flameEntry then table.remove(activeFlames, i) break end
                end
                return
            end

            if isPlayer then
                -- Check if any fake player dummy is standing on flame
                for _, fp in ipairs(fakePlayersList) do
                    if fp.character and fp.character:FindFirstChild("HumanoidRootPart") then
                        local fRoot = fp.character.HumanoidRootPart
                        local dist  = (fRoot.Position - puddle.Position).Magnitude
                        if dist <= 3 then
                            applyBurnEffect(fp.character)
                        end
                    end
                end
            else
                -- Dummy-owned flame: check if real player steps on it
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local pRoot = character.HumanoidRootPart
                    local dist  = (pRoot.Position - puddle.Position).Magnitude
                    if dist <= 3 then
                        applyBurnEffect(character)
                    end
                end
            end
        end)
    end
end

-- ============================================================
-- PYROMANIA ABILITY 1: GASOLINE TRAIL (player)
-- Lays gasoline puddles at player's feet every 0.25s for 5s.
-- ============================================================
local function activatePyroGasoline(_, isPlayer)
    if isPlayer then
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        if pyroGasolineActive then return end

        pyroGasolineActive  = true
        pyroGasolineEndTime = tick() + 5

        -- Notification
        spawn(function()
            createAbilityNotification("GASOLINE TRAIL", Color3.fromRGB(80, 255, 80))
        end)

        -- Disconnect any old connection
        if pyroTrailConnection then
            pyroTrailConnection:Disconnect()
            pyroTrailConnection = nil
        end

        -- Trail ticker
        local lastPuddlePos   = Vector3.new(math.huge, 0, 0)
        local MIN_PUDDLE_DIST = 2.5   -- only place new puddle if moved this far

        pyroTrailConnection = RunService.Heartbeat:Connect(function()
            if tick() >= pyroGasolineEndTime then
                pyroGasolineActive = false
                pyroTrailConnection:Disconnect()
                pyroTrailConnection = nil
                return
            end

            if not character or not character:FindFirstChild("HumanoidRootPart") then return end

            local pos  = character.HumanoidRootPart.Position
            local dist = (pos - lastPuddlePos).Magnitude

            if dist >= MIN_PUDDLE_DIST then
                lastPuddlePos = pos
                local pd = createGasolinePuddle(pos, "player")
                table.insert(activePyroGasoline, pd)

                -- Auto-remove puddle after 10s (if not ignited)
                spawn(function()
                    wait(10)
                    if pd.part.Parent and not pd.ignited then
                        pd.part.Transparency = 1
                        Debris:AddItem(pd.part, 0.2)
                        for i, p in ipairs(activePyroGasoline) do
                            if p == pd then table.remove(activePyroGasoline, i) break end
                        end
                    end
                end)
            end
        end)
    end
end

-- ============================================================
-- PYROMANIA ABILITY 2: IGNITE (player)
-- If standing on gasoline → flood-fill ignite connected puddles.
-- If NOT on gasoline → summon fire at player's feet.
-- ============================================================
function activatePyroIgnite(_, isPlayer)
    if not isPlayer then return end  -- only called for player here; dummy has own logic
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local cRoot      = character.HumanoidRootPart
    local playerPos  = cRoot.Position

    -- Find any gasoline puddle under/near the player
    local standingOn = nil
    for _, pd in ipairs(activePyroGasoline) do
        if not pd.ignited and pd.part.Parent then
            local dist = (pd.part.Position - playerPos).Magnitude
            if dist <= 4 then
                standingOn = pd
                break
            end
        end
    end

    if standingOn then
        -- Standing on gasoline — flood-fill ignite all connected
        local connected = getConnectedGasoline(standingOn, activePyroGasoline)
        ignitePuddles(connected, true)

        spawn(function()
            createAbilityNotification(
                "IGNITE! " .. #connected .. " puddles!",
                Color3.fromRGB(255, 80, 0)
            )
        end)
    else
        -- NOT on gasoline — summon standalone fire at feet
        local fakeGas = createGasolinePuddle(playerPos, "player")
        fakeGas.ignited = true   -- skip flood-fill logic
        fakeGas.part.Parent = workspace
        ignitePuddles({ fakeGas }, true)

        spawn(function()
            createAbilityNotification("IGNITE! (standalone fire)", Color3.fromRGB(255, 140, 0))
        end)
    end
end

-- ============================================================
-- PYROMANIA: DUMMY (FAKE PLAYER) FUNCTIONS
-- ============================================================

-- State init for a Pyromania dummy
local function initPyroDummyState(fp)
    fp.pyroDummyGasoline   = {}    -- list of gasoline puddle data this dummy placed
    fp.pyroGasolineActive  = false
    fp.pyroGasolineEndTime = 0
    fp.pyroGasolineTimer   = 0     -- time since last puddle drop
    fp.pyroIgnitedOwn      = false -- has it ignited its gasoline this "round"?
end

-- Gasoline trail for dummy: drops puddles as it walks
local function updatePyroDummyTrail(fp, dt)
    if not fp.character or not fp.rootPart then return end
    if not fp.pyroGasolineActive then return end
    if tick() >= fp.pyroGasolineEndTime then
        fp.pyroGasolineActive = false
        return
    end

    fp.pyroGasolineTimer = fp.pyroGasolineTimer + dt
    if fp.pyroGasolineTimer >= 0.3 then
        fp.pyroGasolineTimer = 0
        local pos = fp.rootPart.Position
        local pd  = createGasolinePuddle(pos, fp)
        table.insert(fp.pyroDummyGasoline, pd)

        spawn(function()
            wait(10)
            if pd.part.Parent and not pd.ignited then
                pd.part.Transparency = 1
                Debris:AddItem(pd.part, 0.2)
                for i, p in ipairs(fp.pyroDummyGasoline) do
                    if p == pd then table.remove(fp.pyroDummyGasoline, i) break end
                end
            end
        end)
    end
end

-- Full per-frame Pyromania dummy AI update
local function updatePyroDummy(fp, dt)
    if not fp.character or not fp.rootPart or not fp.humanoid then return end

    local fRoot      = fp.rootPart
    local ct         = tick()

    -- Drop gasoline trail while active
    updatePyroDummyTrail(fp, dt)

    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local playerRoot = character.HumanoidRootPart
    local dist       = (playerRoot.Position - fRoot.Position).Magnitude

    -- 1ST ABILITY: activate gasoline trail when within 20 studs
    if not fp.pyroGasolineActive and ct - fp.lastAbilityTime >= 20 then
        if dist <= 20 then
            fp.lastAbilityTime    = ct
            fp.pyroGasolineActive = true
            fp.pyroGasolineEndTime = ct + 5
            fp.pyroGasolineTimer  = 0
            fp.pyroIgnitedOwn     = false  -- allow igniting again next time
        end
    end

    -- 2ND ABILITY: ignite own gasoline if dummy has walked over it
    if not fp.pyroIgnitedOwn and ct - fp.lastAbility2Time >= 15 then
        -- Check if dummy is standing on any of its own (un-ignited) gasoline
        for _, pd in ipairs(fp.pyroDummyGasoline) do
            if not pd.ignited and pd.part.Parent then
                local puddleDist = (fRoot.Position - pd.part.Position).Magnitude
                if puddleDist <= 4 then
                    fp.pyroIgnitedOwn    = true
                    fp.lastAbility2Time  = ct

                    -- Flood-fill ignite all connected dummy gasoline
                    local connected = getConnectedGasoline(pd, fp.pyroDummyGasoline)
                    ignitePuddles(connected, false)

                    sendFakePlayerChat(fp.name, "IGNITE!")
                    break
                end
            end
        end
    end
end

-- ============================================================
-- PYROMANIA DUMMY: HOOK INTO MAIN updateFakePlayerAI
-- We patch updateFakePlayerAI to call updatePyroDummy when needed
-- by appending a check in the main loop via a wrapper connection.
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    for _, fp in ipairs(fakePlayersList) do
        if fp.isDead then continue end
        if fp.currentGlove ~= "Pyromania Glove" then continue end
        updatePyroDummy(fp, dt)
    end
end)

-- ============================================================
-- PYROMANIA: BUTTON LABEL RESET ON GLOVE EQUIP / UNEQUIP
-- Keeps the button labels readable for mobile players.
-- ============================================================
RunService.Heartbeat:Connect(function()
    if currentGlove == "Pyromania Glove" and equippedGlove then
        -- Only reset to label text when not mid-cooldown
        -- (cooldown loop handles the numbers itself)
        if abilityButton.Visible  and abilityButton.Text  == "ABILITY" then
            abilityButton.Text  = "GASOLINE"
        end
        if ability2Button.Visible and ability2Button.Text == "ABILITY 2" then
            ability2Button.Text = "IGNITE"
        end
    elseif currentGlove ~= "Pyromania Glove" then
        -- Restore generic labels when switching away
        if abilityButton.Text  == "GASOLINE" then abilityButton.Text  = "ABILITY"   end
        if ability2Button.Text == "IGNITE"   then ability2Button.Text = "ABILITY 2" end
    end
end)

-- ============================================================
print("=== PYROMANIA GLOVE LOADED ===")
print("Ability 1 (GASOLINE button): Leave trail for 5s | 20s CD")
print("Ability 2 (IGNITE button):   Ignite gasoline / standalone fire | 15s CD")
print("Burn damage: 5 dmg/s for 5s on contact with flames")
print("Dummy health: 100")
-- ============================================================
