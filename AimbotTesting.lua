-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Cam = game.Workspace.CurrentCamera

-- ─────────────────────────────────────────
--  STATE
-- ─────────────────────────────────────────

local aimbotEnabled  = false
local currentMode    = "lock"   -- "lock" | "assist"
local fov            = 100
local assistSmooth   = 0.15     -- 0 = instant, 1 = never moves
local espHighlights  = {}       -- [Player] = Highlight

-- ─────────────────────────────────────────
--  FOV CIRCLE
-- ─────────────────────────────────────────

local FOVring = Drawing.new("Circle")
FOVring.Visible    = false
FOVring.Thickness  = 2
FOVring.Color      = Color3.fromRGB(160, 80, 255)
FOVring.Filled     = false
FOVring.Radius     = fov
FOVring.Position   = Cam.ViewportSize / 2

-- ─────────────────────────────────────────
--  GUI ROOT
-- ─────────────────────────────────────────

local AimbotGUI = Instance.new("ScreenGui")
AimbotGUI.Name          = "AimbotGUI"
AimbotGUI.ResetOnSpawn  = false
AimbotGUI.DisplayOrder  = 999
AimbotGUI.Parent        = Players.LocalPlayer:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────
--  MINIMIZED BALL
-- ─────────────────────────────────────────

local Ball = Instance.new("TextButton")
Ball.Name              = "Ball"
Ball.Parent            = AimbotGUI
Ball.BackgroundColor3  = Color3.fromRGB(90, 30, 180)
Ball.BorderSizePixel   = 0
Ball.Position          = UDim2.new(0.5, -28, 0.5, -28)
Ball.Size              = UDim2.new(0, 56, 0, 56)
Ball.ZIndex            = 10
Ball.Text              = "⊕"
Ball.Font              = Enum.Font.GothamBold
Ball.TextColor3        = Color3.fromRGB(230, 200, 255)
Ball.TextSize          = 24
Ball.AutoButtonColor   = false
Ball.Visible           = false
Ball.Active            = true
Ball.Draggable         = true

local BallCorner = Instance.new("UICorner")
BallCorner.CornerRadius = UDim.new(1, 0)
BallCorner.Parent = Ball

local BallStroke = Instance.new("UIStroke")
BallStroke.Color        = Color3.fromRGB(180, 100, 255)
BallStroke.Thickness    = 2
BallStroke.Transparency = 0.2
BallStroke.Parent       = Ball

-- ─────────────────────────────────────────
--  MAIN PANEL
-- ─────────────────────────────────────────

local Background = Instance.new("Frame")
Background.Name             = "Background"
Background.Parent           = AimbotGUI
Background.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
Background.BorderSizePixel  = 0
Background.Position         = UDim2.new(0.5, -125, 0.5, -130)
Background.Size             = UDim2.new(0, 250, 0, 260)
Background.Active           = true
Background.Draggable        = true
Background.ZIndex           = 2
Background.ClipsDescendants = true

local BgCorner = Instance.new("UICorner")
BgCorner.CornerRadius = UDim.new(0, 18)
BgCorner.Parent = Background

local BgStroke = Instance.new("UIStroke")
BgStroke.Color        = Color3.fromRGB(100, 70, 200)
BgStroke.Thickness    = 1.5
BgStroke.Transparency = 0.3
BgStroke.Parent       = Background

-- ── Top Bar ──────────────────────────────

local TopBar = Instance.new("Frame")
TopBar.Name             = "TopBar"
TopBar.Parent           = Background
TopBar.BackgroundColor3 = Color3.fromRGB(30, 18, 60)
TopBar.BorderSizePixel  = 0
TopBar.Size             = UDim2.new(1, 0, 0, 54)
TopBar.ZIndex           = 3

local TopGradient = Instance.new("UIGradient")
TopGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 30, 160)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 18, 60)),
})
TopGradient.Rotation = 90
TopGradient.Parent   = TopBar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Parent              = TopBar
TitleIcon.BackgroundTransparency = 1
TitleIcon.Position            = UDim2.new(0, 14, 0, 0)
TitleIcon.Size                = UDim2.new(0, 30, 1, 0)
TitleIcon.Font                = Enum.Font.GothamBold
TitleIcon.Text                = "⊕"
TitleIcon.TextColor3          = Color3.fromRGB(180, 120, 255)
TitleIcon.TextSize            = 22
TitleIcon.ZIndex              = 4

local Title = Instance.new("TextLabel")
Title.Name               = "Title"
Title.Parent             = TopBar
Title.BackgroundTransparency = 1
Title.Position           = UDim2.new(0, 50, 0, 0)
Title.Size               = UDim2.new(1, -90, 1, 0)
Title.Font               = Enum.Font.GothamBold
Title.Text               = "AIMBOT"
Title.TextColor3         = Color3.fromRGB(240, 220, 255)
Title.TextSize           = 17
Title.TextXAlignment     = Enum.TextXAlignment.Left
Title.ZIndex             = 4

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name             = "MinimizeBtn"
MinimizeBtn.Parent           = TopBar
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 100)
MinimizeBtn.BorderSizePixel  = 0
MinimizeBtn.Position         = UDim2.new(1, -44, 0.5, -15)
MinimizeBtn.Size             = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Font             = Enum.Font.GothamBold
MinimizeBtn.Text             = "—"
MinimizeBtn.TextColor3       = Color3.fromRGB(200, 160, 255)
MinimizeBtn.TextSize         = 14
MinimizeBtn.ZIndex           = 5
MinimizeBtn.AutoButtonColor  = false

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinimizeBtn

-- ── Divider ──────────────────────────────

local Divider = Instance.new("Frame")
Divider.Parent           = Background
Divider.BackgroundColor3 = Color3.fromRGB(90, 50, 160)
Divider.BorderSizePixel  = 0
Divider.Position         = UDim2.new(0, 14, 0, 54)
Divider.Size             = UDim2.new(1, -28, 0, 1)
Divider.ZIndex           = 3

-- ── Scrolling Content ────────────────────

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name                    = "ScrollFrame"
ScrollFrame.Parent                  = Background
ScrollFrame.BackgroundTransparency  = 1
ScrollFrame.BorderSizePixel         = 0
ScrollFrame.Position                = UDim2.new(0, 0, 0, 56)
ScrollFrame.Size                    = UDim2.new(1, 0, 1, -56)
ScrollFrame.CanvasSize              = UDim2.new(0, 0, 0, 340)
ScrollFrame.ScrollBarThickness      = 3
ScrollFrame.ScrollBarImageColor3    = Color3.fromRGB(120, 70, 200)
ScrollFrame.ScrollBarImageTransparency = 0.3
ScrollFrame.ZIndex                  = 3
ScrollFrame.ElasticBehavior         = Enum.ElasticBehavior.Always

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent             = ScrollFrame
ListLayout.SortOrder          = Enum.SortOrder.LayoutOrder
ListLayout.Padding            = UDim.new(0, 8)
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop    = UDim.new(0, 10)
ListPadding.PaddingBottom = UDim.new(0, 10)
ListPadding.Parent        = ScrollFrame

-- Helper: card container
local function makeCard(layoutOrder, height, transparent)
    local card = Instance.new("Frame")
    card.BackgroundColor3     = Color3.fromRGB(22, 14, 40)
    card.BackgroundTransparency = transparent and 1 or 0
    card.BorderSizePixel      = 0
    card.Size                 = UDim2.new(1, -28, 0, height)
    card.LayoutOrder          = layoutOrder
    card.ZIndex               = 4
    card.Parent               = ScrollFrame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = card
    return card
end

-- ── Status Card ──────────────────────────

local StatusCard = makeCard(1, 34)

local StatusDot = Instance.new("Frame")
StatusDot.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
StatusDot.BorderSizePixel  = 0
StatusDot.Position         = UDim2.new(0, 12, 0.5, -6)
StatusDot.Size             = UDim2.new(0, 12, 0, 12)
StatusDot.ZIndex           = 5
StatusDot.Parent           = StatusCard
local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = StatusDot

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent              = StatusCard
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position            = UDim2.new(0, 32, 0, 0)
StatusLabel.Size                = UDim2.new(1, -36, 1, 0)
StatusLabel.Font                = Enum.Font.GothamSemibold
StatusLabel.Text                = "AIMBOT  ·  INACTIVE"
StatusLabel.TextColor3          = Color3.fromRGB(180, 140, 220)
StatusLabel.TextSize            = 13
StatusLabel.TextXAlignment      = Enum.TextXAlignment.Left
StatusLabel.ZIndex              = 5

-- ── Mode Selector ────────────────────────

local ModeCard = makeCard(2, 74)

local ModeTitleLbl = Instance.new("TextLabel")
ModeTitleLbl.Parent              = ModeCard
ModeTitleLbl.BackgroundTransparency = 1
ModeTitleLbl.Position            = UDim2.new(0, 10, 0, 6)
ModeTitleLbl.Size                = UDim2.new(1, -20, 0, 18)
ModeTitleLbl.Font                = Enum.Font.Gotham
ModeTitleLbl.Text                = "MODE"
ModeTitleLbl.TextColor3          = Color3.fromRGB(120, 90, 170)
ModeTitleLbl.TextSize            = 11
ModeTitleLbl.TextXAlignment      = Enum.TextXAlignment.Left
ModeTitleLbl.ZIndex              = 5

local LockBtn = Instance.new("TextButton")
LockBtn.Parent           = ModeCard
LockBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 180)
LockBtn.BorderSizePixel  = 0
LockBtn.Position         = UDim2.new(0, 10, 0, 28)
LockBtn.Size             = UDim2.new(0.47, -5, 0, 34)
LockBtn.Font             = Enum.Font.GothamBold
LockBtn.Text             = "AIM-LOCK"
LockBtn.TextColor3       = Color3.fromRGB(230, 200, 255)
LockBtn.TextSize         = 13
LockBtn.ZIndex           = 5
LockBtn.AutoButtonColor  = false
local LockCorner = Instance.new("UICorner")
LockCorner.CornerRadius = UDim.new(0, 9)
LockCorner.Parent = LockBtn
local LockStroke = Instance.new("UIStroke")
LockStroke.Color        = Color3.fromRGB(160, 90, 255)
LockStroke.Thickness    = 1.5
LockStroke.Transparency = 0.2
LockStroke.Parent       = LockBtn

local AssistBtn = Instance.new("TextButton")
AssistBtn.Parent           = ModeCard
AssistBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 55)
AssistBtn.BorderSizePixel  = 0
AssistBtn.Position         = UDim2.new(0.5, 5, 0, 28)
AssistBtn.Size             = UDim2.new(0.47, -5, 0, 34)
AssistBtn.Font             = Enum.Font.GothamBold
AssistBtn.Text             = "AIM-ASSIST"
AssistBtn.TextColor3       = Color3.fromRGB(130, 100, 180)
AssistBtn.TextSize         = 13
AssistBtn.ZIndex           = 5
AssistBtn.AutoButtonColor  = false
local AssistCorner = Instance.new("UICorner")
AssistCorner.CornerRadius = UDim.new(0, 9)
AssistCorner.Parent = AssistBtn
local AssistStroke = Instance.new("UIStroke")
AssistStroke.Color        = Color3.fromRGB(80, 55, 130)
AssistStroke.Thickness    = 1.5
AssistStroke.Transparency = 0.5
AssistStroke.Parent       = AssistBtn

-- ── Enable Toggle ────────────────────────

local ToggleCard = makeCard(3, 68, true)

local EnableToggle = Instance.new("TextButton")
EnableToggle.Parent           = ToggleCard
EnableToggle.BackgroundColor3 = Color3.fromRGB(70, 30, 140)
EnableToggle.BorderSizePixel  = 0
EnableToggle.Position         = UDim2.new(0, 0, 0, 0)
EnableToggle.Size             = UDim2.new(1, 0, 1, 0)
EnableToggle.Font             = Enum.Font.GothamBold
EnableToggle.Text             = "ENABLE"
EnableToggle.TextColor3       = Color3.fromRGB(230, 200, 255)
EnableToggle.TextSize         = 20
EnableToggle.ZIndex           = 5
EnableToggle.AutoButtonColor  = false
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 10)
ToggleCorner.Parent = EnableToggle
local ToggleGradient = Instance.new("UIGradient")
ToggleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 40, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 20, 120)),
})
ToggleGradient.Rotation = 135
ToggleGradient.Parent   = EnableToggle
local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color        = Color3.fromRGB(160, 90, 255)
ToggleStroke.Thickness    = 1.5
ToggleStroke.Transparency = 0.2
ToggleStroke.Parent       = EnableToggle

-- ── FOV Info ─────────────────────────────

local FovCard = makeCard(4, 30)

local FovLabel = Instance.new("TextLabel")
FovLabel.Parent              = FovCard
FovLabel.BackgroundTransparency = 1
FovLabel.Size                = UDim2.new(1, 0, 1, 0)
FovLabel.Font                = Enum.Font.Gotham
FovLabel.Text                = "FOV RADIUS  ·  " .. fov .. " px"
FovLabel.TextColor3          = Color3.fromRGB(130, 100, 180)
FovLabel.TextSize            = 12
FovLabel.ZIndex              = 5

-- ── Credits ──────────────────────────────

local CreditsCard = makeCard(5, 24, true)

local Credits = Instance.new("TextLabel")
Credits.Parent              = CreditsCard
Credits.BackgroundTransparency = 1
Credits.Size                = UDim2.new(1, 0, 1, 0)
Credits.Font                = Enum.Font.Gotham
Credits.Text                = "by Bloodscript"
Credits.TextColor3          = Color3.fromRGB(80, 60, 110)
Credits.TextSize            = 11
Credits.ZIndex              = 5

-- ─────────────────────────────────────────
--  ESP HIGHLIGHTS
-- ─────────────────────────────────────────

local function applyHighlight(player)
    local char = player.Character
    if not char then return end
    if char:FindFirstChildOfClass("Highlight") then return end
    local hl = Instance.new("Highlight")
    hl.Parent              = char
    hl.FillColor           = Color3.fromRGB(180, 80, 255)
    hl.OutlineColor        = Color3.fromRGB(255, 200, 255)
    hl.FillTransparency    = 0.55
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    espHighlights[player]  = hl
    -- Hide nametag
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
end

local function addESP(player)
    applyHighlight(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        if aimbotEnabled then
            applyHighlight(player)
        end
    end)
end

local function removeESP(player)
    local hl = espHighlights[player]
    if hl and hl.Parent then hl:Destroy() end
    espHighlights[player] = nil
end

local function enableAllESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then addESP(p) end
    end
end

local function disableAllESP()
    for player, _ in pairs(espHighlights) do
        removeESP(player)
    end
end

-- ─────────────────────────────────────────
--  MODE VISUALS
-- ─────────────────────────────────────────

local function setModeVisuals(mode)
    if mode == "lock" then
        LockBtn.BackgroundColor3  = Color3.fromRGB(90, 40, 180)
        LockBtn.TextColor3        = Color3.fromRGB(230, 200, 255)
        LockStroke.Color          = Color3.fromRGB(160, 90, 255)
        LockStroke.Transparency   = 0.2
        AssistBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 55)
        AssistBtn.TextColor3       = Color3.fromRGB(130, 100, 180)
        AssistStroke.Color         = Color3.fromRGB(80, 55, 130)
        AssistStroke.Transparency  = 0.5
    else
        AssistBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 180)
        AssistBtn.TextColor3       = Color3.fromRGB(230, 200, 255)
        AssistStroke.Color         = Color3.fromRGB(160, 90, 255)
        AssistStroke.Transparency  = 0.2
        LockBtn.BackgroundColor3  = Color3.fromRGB(30, 20, 55)
        LockBtn.TextColor3        = Color3.fromRGB(130, 100, 180)
        LockStroke.Color          = Color3.fromRGB(80, 55, 130)
        LockStroke.Transparency   = 0.5
    end
end

LockBtn.MouseButton1Click:Connect(function()
    currentMode = "lock"
    setModeVisuals("lock")
end)

AssistBtn.MouseButton1Click:Connect(function()
    currentMode = "assist"
    setModeVisuals("assist")
end)

-- ─────────────────────────────────────────
--  AIMBOT TOGGLE
-- ─────────────────────────────────────────

local function setAimbotState(enabled)
    aimbotEnabled = enabled
    if enabled then
        ToggleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 180, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 100, 60)),
        })
        ToggleStroke.Color      = Color3.fromRGB(60, 220, 120)
        EnableToggle.Text       = "DISABLE"
        EnableToggle.TextColor3 = Color3.fromRGB(200, 255, 220)
        StatusDot.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
        StatusLabel.Text           = "AIMBOT  ·  ACTIVE"
        StatusLabel.TextColor3     = Color3.fromRGB(140, 220, 160)
        FOVring.Color   = Color3.fromRGB(60, 220, 120)
        FOVring.Visible = true
        enableAllESP()
    else
        ToggleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 40, 200)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 20, 120)),
        })
        ToggleStroke.Color      = Color3.fromRGB(160, 90, 255)
        EnableToggle.Text       = "ENABLE"
        EnableToggle.TextColor3 = Color3.fromRGB(230, 200, 255)
        StatusDot.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
        StatusLabel.Text           = "AIMBOT  ·  INACTIVE"
        StatusLabel.TextColor3     = Color3.fromRGB(180, 140, 220)
        FOVring.Color   = Color3.fromRGB(160, 80, 255)
        FOVring.Visible = false
        disableAllESP()
    end
end

EnableToggle.MouseButton1Click:Connect(function()
    setAimbotState(not aimbotEnabled)
end)

EnableToggle.MouseEnter:Connect(function()
    TweenService:Create(EnableToggle, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(90, 45, 170)
    }):Play()
end)
EnableToggle.MouseLeave:Connect(function()
    TweenService:Create(EnableToggle, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(70, 30, 140)
    }):Play()
end)

-- ─────────────────────────────────────────
--  MINIMIZE → BALL
-- ─────────────────────────────────────────

local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

MinimizeBtn.MouseButton1Click:Connect(function()
    Ball.Position = UDim2.new(
        Background.Position.X.Scale,
        Background.Position.X.Offset + 97,
        Background.Position.Y.Scale,
        Background.Position.Y.Offset + 102
    )
    Background.Visible = false
    Ball.Visible       = true
    TweenService:Create(Ball, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 64, 0, 64)
    }):Play()
    task.delay(0.15, function()
        TweenService:Create(Ball, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 56, 0, 56)
        }):Play()
    end)
end)

Ball.MouseButton1Click:Connect(function()
    Ball.Visible       = false
    Background.Visible = true
end)

-- Ball color reflects aimbot state
RunService.Heartbeat:Connect(function()
    if not Ball.Visible then return end
    Ball.BackgroundColor3 = aimbotEnabled
        and Color3.fromRGB(40, 160, 80)
        or  Color3.fromRGB(90, 30, 180)
    BallStroke.Color = aimbotEnabled
        and Color3.fromRGB(60, 220, 120)
        or  Color3.fromRGB(180, 100, 255)
end)

-- ─────────────────────────────────────────
--  AIMBOT TARGETING
-- ─────────────────────────────────────────

local function getClosestPlayerInFOV(trg_part)
    local nearest, last = nil, math.huge
    local center      = Cam.ViewportSize / 2
    local localPlayer = Players.LocalPlayer
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and (not player.Team or player.Team ~= localPlayer.Team) then
            local part = player.Character and player.Character:FindFirstChild(trg_part)
            if part then
                local ePos, isVisible = Cam:WorldToViewportPoint(part.Position)
                local dist = (Vector2.new(ePos.X, ePos.Y) - center).Magnitude
                if dist < last and isVisible and dist < fov then
                    last    = dist
                    nearest = player
                end
            end
        end
    end
    return nearest
end

-- ─────────────────────────────────────────
--  RENDER LOOP
-- ─────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Delete then
        FOVring:Remove()
    end
end)

RunService.RenderStepped:Connect(function()
    FOVring.Position = Cam.ViewportSize / 2
    if not aimbotEnabled then return end

    local closest = getClosestPlayerInFOV("Head")
    if not (closest and closest.Character and closest.Character:FindFirstChild("Head")) then return end
    local targetPos = closest.Character.Head.Position

    if currentMode == "lock" then
        local lookVec = (targetPos - Cam.CFrame.Position).Unit
        Cam.CFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lookVec)
    elseif currentMode == "assist" then
        local lerpedLook = Cam.CFrame.LookVector:Lerp(
            (targetPos - Cam.CFrame.Position).Unit,
            assistSmooth
        )
        Cam.CFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lerpedLook)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)
