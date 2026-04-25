--[[
    ██████╗ ██████╗  █████╗  ██████╗███████╗
   ██╔════╝ ██╔══██╗██╔══██╗██╔════╝██╔════╝
   ██║  ███╗██████╔╝███████║██║     █████╗
   ██║   ██║██╔══██╗██╔══██║██║     ██╔══╝
   ╚██████╔╝██║  ██║██║  ██║╚██████╗███████╗
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝
    F A N M A D E  —  by Wowiera
    Script by Claude (Anthropic)

    ▸ FATE system      — yellow → white as health drains
    ▸ Entity Panel     — top-right 👁 button
    ▸ GAZE             — Envy
    ▸ ELUDE  v3        — Paranoia  (open ground spawn, outside camera)
    ▸ NUMB             — Wrath     (blood rain, find cover or die)

    Executor: Codex (mobile)  |  Game Script Category
--]]

-- ═══════════════════════════════════════════════════════════
--                  SERVICES & CORE REFS
-- ═══════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")

local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")
local Camera           = Workspace.CurrentCamera
local Character        = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid         = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Head             = Character:WaitForChild("Head")

LocalPlayer.CharacterAdded:Connect(function(nc)
    Character          = nc
    Humanoid           = nc:WaitForChild("Humanoid")
    HumanoidRootPart   = nc:WaitForChild("HumanoidRootPart")
    Head               = nc:WaitForChild("Head")
end)

-- ═══════════════════════════════════════════════════════════
--                     FATE SYSTEM
-- ═══════════════════════════════════════════════════════════
local FateData = {
    current    = 100,
    max        = 100,
    dead       = false,
    drainRates = {},
}

local FATE_FULL  = Color3.fromRGB(255, 215, 0)
local FATE_EMPTY = Color3.fromRGB(220, 220, 220)

local function GetFateColor(pct)   return FATE_EMPTY:Lerp(FATE_FULL, pct) end
local function AddFateDrain(id,r)  FateData.drainRates[id] = r end
local function RemoveFateDrain(id) FateData.drainRates[id] = nil end
local function ModifyFate(n)
    FateData.current = math.clamp(FateData.current + n, 0, FateData.max)
end

-- ═══════════════════════════════════════════════════════════
--                      MAIN GUI
-- ═══════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "GraceGUI"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset  = true
ScreenGui.Parent          = PlayerGui

-- ── FATE LABEL ─────────────────────────────────────────────
local FateLabel = Instance.new("TextLabel")
FateLabel.Name                   = "FateLabel"
FateLabel.Size                   = UDim2.new(0, 220, 0, 60)
FateLabel.AnchorPoint            = Vector2.new(0.5, 0)
FateLabel.Position               = UDim2.new(0.5, 0, 0, 18)
FateLabel.BackgroundTransparency = 1
FateLabel.Text                   = "𝐅𝐀𝐓𝐄"
FateLabel.Font                   = Enum.Font.GothamBold
FateLabel.TextSize               = 46
FateLabel.TextColor3             = FATE_FULL
FateLabel.TextStrokeTransparency = 0.4
FateLabel.TextStrokeColor3       = Color3.fromRGB(0,0,0)
FateLabel.ZIndex                 = 10
FateLabel.Parent                 = ScreenGui

local FateGlow = Instance.new("TextLabel")
FateGlow.Size                   = FateLabel.Size
FateGlow.AnchorPoint            = FateLabel.AnchorPoint
FateGlow.Position               = FateLabel.Position
FateGlow.BackgroundTransparency = 1
FateGlow.Text                   = "𝐅𝐀𝐓𝐄"
FateGlow.Font                   = Enum.Font.GothamBold
FateGlow.TextSize               = 46
FateGlow.TextColor3             = FATE_FULL
FateGlow.TextTransparency       = 0.75
FateGlow.ZIndex                 = 9
FateGlow.Parent                 = ScreenGui

-- ── FATE BAR ───────────────────────────────────────────────
local FateBarBG = Instance.new("Frame")
FateBarBG.Name             = "FateBarBG"
FateBarBG.Size             = UDim2.new(0, 200, 0, 5)
FateBarBG.AnchorPoint      = Vector2.new(0.5, 0)
FateBarBG.Position         = UDim2.new(0.5, 0, 0, 72)
FateBarBG.BackgroundColor3 = Color3.fromRGB(40,40,40)
FateBarBG.BorderSizePixel  = 0
FateBarBG.ZIndex           = 10
FateBarBG.Parent           = ScreenGui
Instance.new("UICorner", FateBarBG).CornerRadius = UDim.new(1,0)

local FateBarFill = Instance.new("Frame")
FateBarFill.Name             = "FateBarFill"
FateBarFill.Size             = UDim2.new(1,0,1,0)
FateBarFill.BackgroundColor3 = FATE_FULL
FateBarFill.BorderSizePixel  = 0
FateBarFill.ZIndex           = 11
FateBarFill.Parent           = FateBarBG
Instance.new("UICorner", FateBarFill).CornerRadius = UDim.new(1,0)

local FatePct = Instance.new("TextLabel")
FatePct.Name                   = "FatePct"
FatePct.Size                   = UDim2.new(0,200,0,18)
FatePct.AnchorPoint            = Vector2.new(0.5,0)
FatePct.Position               = UDim2.new(0.5,0,0,80)
FatePct.BackgroundTransparency = 1
FatePct.Text                   = "100%"
FatePct.Font                   = Enum.Font.Gotham
FatePct.TextSize               = 13
FatePct.TextColor3             = Color3.fromRGB(180,180,180)
FatePct.TextStrokeTransparency = 0.6
FatePct.ZIndex                 = 10
FatePct.Parent                 = ScreenGui

-- ── DEATH SCREEN ───────────────────────────────────────────
local DeathScreen = Instance.new("Frame")
DeathScreen.Name                   = "DeathScreen"
DeathScreen.Size                   = UDim2.new(1,0,1,0)
DeathScreen.BackgroundColor3       = Color3.fromRGB(255,255,255)
DeathScreen.BackgroundTransparency = 1
DeathScreen.ZIndex                 = 100
DeathScreen.Visible                = false
DeathScreen.Parent                 = ScreenGui

local DeathLabel = Instance.new("TextLabel")
DeathLabel.Size                   = UDim2.new(1,0,0,80)
DeathLabel.AnchorPoint            = Vector2.new(0.5,0.5)
DeathLabel.Position               = UDim2.new(0.5,0,0.5,0)
DeathLabel.BackgroundTransparency = 1
DeathLabel.Text                   = "your fate ran out."
DeathLabel.Font                   = Enum.Font.GothamBold
DeathLabel.TextSize               = 38
DeathLabel.TextColor3             = Color3.fromRGB(30,30,30)
DeathLabel.TextTransparency       = 1
DeathLabel.ZIndex                 = 101
DeathLabel.Parent                 = DeathScreen

-- ── VIGNETTE (frame gradient, no rbxasset path) ────────────
local VigFrame = Instance.new("Frame")
VigFrame.Size                   = UDim2.new(1,0,1,0)
VigFrame.BackgroundTransparency = 1
VigFrame.BorderSizePixel        = 0
VigFrame.ZIndex                 = 8
VigFrame.Parent                 = ScreenGui

local function MakeVigEdge(ax, ay, sx, sy, rot)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(sx,0,sy,0)
    f.AnchorPoint      = Vector2.new(ax,ay)
    f.Position         = UDim2.new(ax,0,ay,0)
    f.BackgroundColor3 = Color3.fromRGB(0,0,0)
    f.BackgroundTransparency = 1
    f.BorderSizePixel  = 0
    f.ZIndex           = 8
    f.Parent           = VigFrame
    local g = Instance.new("UIGradient")
    g.Rotation     = rot
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    g.Parent = f
    return f
end

local VigTop    = MakeVigEdge(0, 0,   1, 0.20,   0)
local VigBottom = MakeVigEdge(0, 1,   1, 0.20, 180)
local VigLeft   = MakeVigEdge(0, 0, 0.14, 1,    90)
local VigRight  = MakeVigEdge(1, 0, 0.14, 1,   270)

local function SetVignette(alpha)
    local trans = math.clamp(1 - alpha, 0, 1)
    VigTop.BackgroundTransparency    = trans
    VigBottom.BackgroundTransparency = trans
    VigLeft.BackgroundTransparency   = trans
    VigRight.BackgroundTransparency  = trans
end

-- ═══════════════════════════════════════════════════════════
--             ENTITY CONTROL PANEL  (top-right 👁)
-- ═══════════════════════════════════════════════════════════

local EntityToggleBtn = Instance.new("TextButton")
EntityToggleBtn.Name                    = "EntityToggle"
EntityToggleBtn.Size                    = UDim2.new(0,42,0,42)
EntityToggleBtn.AnchorPoint             = Vector2.new(1,0)
EntityToggleBtn.Position                = UDim2.new(1,-12,0,12)
EntityToggleBtn.BackgroundColor3        = Color3.fromRGB(20,20,20)
EntityToggleBtn.BackgroundTransparency  = 0.25
EntityToggleBtn.Text                    = "👁"
EntityToggleBtn.Font                    = Enum.Font.GothamBold
EntityToggleBtn.TextSize                = 22
EntityToggleBtn.TextColor3              = Color3.fromRGB(255,215,0)
EntityToggleBtn.BorderSizePixel         = 0
EntityToggleBtn.ZIndex                  = 20
EntityToggleBtn.Parent                  = ScreenGui
Instance.new("UICorner", EntityToggleBtn).CornerRadius = UDim.new(0,8)

local EntityPanel = Instance.new("Frame")
EntityPanel.Name                    = "EntityPanel"
EntityPanel.Size                    = UDim2.new(0,260,0,364)  -- fixed: 44 title + 320 scroll view
EntityPanel.AnchorPoint             = Vector2.new(1,0)
EntityPanel.Position                = UDim2.new(1,-12,0,62)
EntityPanel.BackgroundColor3        = Color3.fromRGB(10,10,10)
EntityPanel.BackgroundTransparency  = 0.1
EntityPanel.BorderSizePixel         = 0
EntityPanel.Visible                 = false
EntityPanel.ZIndex                  = 20
EntityPanel.ClipsDescendants        = true
EntityPanel.Parent                  = ScreenGui
Instance.new("UICorner", EntityPanel).CornerRadius = UDim.new(0,12)

local PanelTitle = Instance.new("TextLabel")
PanelTitle.Size                   = UDim2.new(1,0,0,40)
PanelTitle.BackgroundColor3       = Color3.fromRGB(255,215,0)
PanelTitle.BackgroundTransparency = 0
PanelTitle.Text                   = "  ENTITIES"
PanelTitle.Font                   = Enum.Font.GothamBold
PanelTitle.TextSize               = 16
PanelTitle.TextColor3             = Color3.fromRGB(10,10,10)
PanelTitle.TextXAlignment         = Enum.TextXAlignment.Left
PanelTitle.BorderSizePixel        = 0
PanelTitle.ZIndex                 = 21
PanelTitle.Parent                 = EntityPanel
Instance.new("UICorner", PanelTitle).CornerRadius = UDim.new(0,12)

local TitleFix = Instance.new("Frame")
TitleFix.Size             = UDim2.new(1,0,0,14)
TitleFix.Position         = UDim2.new(0,0,1,-14)
TitleFix.BackgroundColor3 = Color3.fromRGB(255,215,0)
TitleFix.BorderSizePixel  = 0
TitleFix.ZIndex           = 22
TitleFix.Parent           = PanelTitle

local EntityScroll = Instance.new("ScrollingFrame")
EntityScroll.Name                   = "EntityScroll"
EntityScroll.Size                   = UDim2.new(1,0,1,-44)
EntityScroll.Position               = UDim2.new(0,0,0,44)
EntityScroll.BackgroundTransparency = 1
EntityScroll.BorderSizePixel        = 0
EntityScroll.ScrollBarThickness     = 5   -- thicker for mobile finger use
EntityScroll.ScrollBarImageColor3   = Color3.fromRGB(255,215,0)
EntityScroll.ScrollingEnabled       = true
EntityScroll.ElasticBehavior        = Enum.ElasticBehavior.Always  -- mobile rubber-band
EntityScroll.ScrollingDirection     = Enum.ScrollingDirection.Y
EntityScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
EntityScroll.ZIndex                 = 21
EntityScroll.CanvasSize             = UDim2.new(0,0,0,0)
EntityScroll.Parent                 = EntityPanel

local EntityList = Instance.new("UIListLayout")
EntityList.SortOrder = Enum.SortOrder.LayoutOrder
EntityList.Padding   = UDim.new(0,6)
EntityList.Parent    = EntityScroll

local EntityPad = Instance.new("UIPadding")
EntityPad.PaddingTop   = UDim.new(0,8)
EntityPad.PaddingLeft  = UDim.new(0,10)
EntityPad.PaddingRight = UDim.new(0,10)
EntityPad.Parent       = EntityScroll

EntityList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    -- Only update canvas height so the scroll frame knows how far to scroll.
    -- Panel height is fixed (364px) — no auto-resize needed.
    local h = EntityList.AbsoluteContentSize.Y + 20
    EntityScroll.CanvasSize = UDim2.new(0,0,0,h)
end)

local panelOpen = false
EntityToggleBtn.MouseButton1Click:Connect(function()
    panelOpen = not panelOpen
    EntityPanel.Visible = panelOpen
    if panelOpen then
        EntityToggleBtn.TextColor3       = Color3.fromRGB(30,30,30)
        EntityToggleBtn.BackgroundColor3 = Color3.fromRGB(255,215,0)
    else
        EntityToggleBtn.TextColor3       = Color3.fromRGB(255,215,0)
        EntityToggleBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
    end
end)

-- ═══════════════════════════════════════════════════════════
--              ENTITY REGISTRY FRAMEWORK
-- ═══════════════════════════════════════════════════════════
local EntityRegistry = {}

local function RegisterEntity(name, symbolizes, desc, onEnable, onDisable)
    local row = Instance.new("Frame")
    row.Name                   = name.."_Row"
    row.Size                   = UDim2.new(1,0,0,72)
    row.BackgroundColor3       = Color3.fromRGB(20,20,20)
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel        = 0
    row.ZIndex                 = 22
    row.Parent                 = EntityScroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local function lbl(txt, font, sz, col, pos, size, wrap)
        local l = Instance.new("TextLabel")
        l.Size                   = size
        l.Position               = pos
        l.BackgroundTransparency = 1
        l.Text                   = txt
        l.Font                   = font
        l.TextSize               = sz
        l.TextColor3             = col
        l.TextXAlignment         = Enum.TextXAlignment.Left
        l.ZIndex                 = 23
        l.TextWrapped            = wrap or false
        l.Parent                 = row
        return l
    end

    lbl(name:upper(),              Enum.Font.GothamBold, 14, Color3.fromRGB(255,215,0),  UDim2.new(0,10,0,6),  UDim2.new(1,-62,0,20))
    lbl("Symbolizes: "..symbolizes, Enum.Font.Gotham,    11, Color3.fromRGB(160,130,60), UDim2.new(0,10,0,28), UDim2.new(1,-62,0,16))
    lbl(desc,                      Enum.Font.Gotham,     10, Color3.fromRGB(150,150,150),UDim2.new(0,10,0,44), UDim2.new(1,-62,0,24), true)

    local tb = Instance.new("TextButton")
    tb.Size             = UDim2.new(0,46,0,24)
    tb.AnchorPoint      = Vector2.new(1,0.5)
    tb.Position         = UDim2.new(1,-8,0.5,0)
    tb.BackgroundColor3 = Color3.fromRGB(180,60,60)
    tb.Text             = "OFF"
    tb.Font             = Enum.Font.GothamBold
    tb.TextSize         = 11
    tb.TextColor3       = Color3.fromRGB(255,255,255)
    tb.BorderSizePixel  = 0
    tb.ZIndex           = 24
    tb.Parent           = row
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,6)

    local entry = { name=name, enabled=false, onEnable=onEnable, onDisable=onDisable }
    EntityRegistry[name] = entry

    tb.MouseButton1Click:Connect(function()
        entry.enabled = not entry.enabled
        if entry.enabled then
            tb.Text = "ON";  tb.BackgroundColor3 = Color3.fromRGB(60,180,60)
            if onEnable then pcall(onEnable) end
        else
            tb.Text = "OFF"; tb.BackgroundColor3 = Color3.fromRGB(180,60,60)
            if onDisable then pcall(onDisable) end
        end
    end)

    return entry
end

-- ═══════════════════════════════════════════════════════════
--           ENTITY: GAZE  (Symbolizes: Envy)
-- ═══════════════════════════════════════════════════════════
--[[
    ▸ Every 5s → 35% chance: random player gets eye billboard on head
    ▸ 60% bias toward same-team friends
    ▸ Look at it (FOV + raycast, walls block, target head doesn't):
        → -5% fate/s while looking
    ▸ Eye disappears after 15s → 5s cooldown → cycle repeats
    ▸ Red screen tint + "you see it." while draining
--]]

local Gaze = {
    active   = false,  target  = nil,  eyeBB      = nil,
    conn     = nil,    draining= false, spawnTick  = 0,
    cdTick   = 0,      CD      = 5,    EYE_DUR    = 15,
}

local GazeTint = Instance.new("Frame")
GazeTint.Name = "GazeTint"; GazeTint.Size = UDim2.new(1,0,1,0)
GazeTint.BackgroundColor3 = Color3.fromRGB(180,0,0)
GazeTint.BackgroundTransparency = 1; GazeTint.ZIndex = 7; GazeTint.Parent = ScreenGui

local GazeWarn = Instance.new("TextLabel")
GazeWarn.Name = "GazeWarn"; GazeWarn.Size = UDim2.new(0,300,0,28)
GazeWarn.AnchorPoint = Vector2.new(0.5,1); GazeWarn.Position = UDim2.new(0.5,0,1,-80)
GazeWarn.BackgroundTransparency = 1; GazeWarn.Text = "you see it."
GazeWarn.Font = Enum.Font.GothamBold; GazeWarn.TextSize = 18
GazeWarn.TextColor3 = Color3.fromRGB(255,80,80); GazeWarn.TextTransparency = 1
GazeWarn.ZIndex = 12; GazeWarn.Parent = ScreenGui

local function BuildEyeBB(tp)
    local char = tp.Character; if not char then return nil end
    local h = char:FindFirstChild("Head"); if not h then return nil end
    local bb = Instance.new("BillboardGui")
    bb.Name = "GazeEye"; bb.Size = UDim2.new(0,80,0,80)
    bb.StudsOffset = Vector3.new(0,0.5,0); bb.AlwaysOnTop = false
    bb.Adornee = h; bb.Parent = h
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(1,0,1,0); ring.BackgroundColor3 = Color3.fromRGB(255,40,40)
    ring.BackgroundTransparency = 0.05; ring.BorderSizePixel = 0; ring.Parent = bb
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1,0)
    local iris = Instance.new("Frame")
    iris.Size = UDim2.new(0.55,0,0.55,0); iris.AnchorPoint = Vector2.new(0.5,0.5)
    iris.Position = UDim2.new(0.5,0,0.5,0); iris.BackgroundColor3 = Color3.fromRGB(15,0,0)
    iris.BorderSizePixel = 0; iris.Parent = bb
    Instance.new("UICorner", iris).CornerRadius = UDim.new(1,0)
    local pupil = Instance.new("Frame")
    pupil.Size = UDim2.new(0.28,0,0.28,0); pupil.AnchorPoint = Vector2.new(0.5,0.5)
    pupil.Position = UDim2.new(0.5,0,0.5,0); pupil.BackgroundColor3 = Color3.fromRGB(0,0,0)
    pupil.BorderSizePixel = 0; pupil.Parent = bb
    Instance.new("UICorner", pupil).CornerRadius = UDim.new(1,0)
    TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundColor3 = Color3.fromRGB(255,140,0)}):Play()
    return bb
end

local function GazeLookCheck(tp)
    local char = tp.Character; if not char then return false end
    local h = char:FindFirstChild("Head"); if not h then return false end
    local camCF = Camera.CFrame; local camPos = camCF.Position
    local toEye = h.Position - camPos; local dist = toEye.Magnitude
    if camCF.LookVector:Dot(toEye.Unit) < 0.7 then return false end
    local excl = {}
    if Character then table.insert(excl, Character) end
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "Head" then table.insert(excl, p) end
    end
    local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = excl
    local hit = Workspace:Raycast(camPos, toEye.Unit * (dist - 0.3), rp)
    return hit == nil or hit.Instance == h
end

local function GazePickTarget()
    local fr, ot = {}, {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if p.Team == LocalPlayer.Team then table.insert(fr, p) else table.insert(ot, p) end
        end
    end
    local pool = (#fr > 0 and math.random() < 0.6) and fr or (#ot > 0 and ot) or (#fr > 0 and fr) or nil
    return pool and pool[math.random(1, #pool)] or nil
end

local function GazeClear()
    if Gaze.eyeBB then Gaze.eyeBB:Destroy(); Gaze.eyeBB = nil end
    Gaze.target = nil; Gaze.draining = false; RemoveFateDrain("Gaze")
    TweenService:Create(GazeTint, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
    TweenService:Create(GazeWarn, TweenInfo.new(0.5), {TextTransparency=1}):Play()
end

local function GazeTrySpawn()
    if not Gaze.active or math.random() > 0.35 then return end
    local t = GazePickTarget(); if not t then return end
    if Gaze.eyeBB then Gaze.eyeBB:Destroy() end
    Gaze.target = t; Gaze.eyeBB = BuildEyeBB(t); Gaze.spawnTick = tick()
end

local function OnGazeEnable()
    Gaze.active = true; Gaze.cdTick = tick()
    Gaze.conn = RunService.Heartbeat:Connect(function()
        if not Gaze.active then return end
        local now = tick()
        if Gaze.target then
            if now - Gaze.spawnTick >= Gaze.EYE_DUR then GazeClear(); Gaze.cdTick = now; return end
            if not Gaze.target.Character then GazeClear(); Gaze.cdTick = now; return end
            local looking = GazeLookCheck(Gaze.target)
            if looking ~= Gaze.draining then
                Gaze.draining = looking
                if looking then
                    AddFateDrain("Gaze", 5)
                    TweenService:Create(GazeTint, TweenInfo.new(0.3), {BackgroundTransparency=0.72}):Play()
                    TweenService:Create(GazeWarn, TweenInfo.new(0.2), {TextTransparency=0}):Play()
                else
                    RemoveFateDrain("Gaze")
                    TweenService:Create(GazeTint, TweenInfo.new(0.6), {BackgroundTransparency=1}):Play()
                    TweenService:Create(GazeWarn, TweenInfo.new(0.4), {TextTransparency=1}):Play()
                end
            end
        else
            if now - Gaze.cdTick >= Gaze.CD then Gaze.cdTick = now; GazeTrySpawn() end
        end
    end)
end

local function OnGazeDisable()
    Gaze.active = false
    if Gaze.conn then Gaze.conn:Disconnect(); Gaze.conn = nil end
    GazeClear()
end

RegisterEntity("Gaze","Envy",
    "You look at your friends. 3 years. They changed. You didn't. You hate it.",
    OnGazeEnable, OnGazeDisable)

-- ═══════════════════════════════════════════════════════════
--          ENTITY: ELUDE  (Symbolizes: Paranoia)  v3
-- ═══════════════════════════════════════════════════════════
--[[
    SPAWN LOGIC (fixed):
    ▸ Casts DOWN from a random elevated point 10–100 studs away
      to find the ground surface — lands ON TOP of ground, never inside parts
    ▸ Only accepts spots that are OUTSIDE the player's camera view
      (either behind the player or obstructed from camera angle)
    ▸ Falls back to more attempts before skipping the cycle
    ▸ Every 5s: teleports to another such ground spot outside camera view
    ▸ Floats above ground and always faces local player (no moving)
    ▸ If player gets clear camera line-of-sight to Elude:
        → -25% fate instantly + Elude teleports immediately
        → 2s immunity before next damage
    ▸ Teal screen flicker + paranoia hint text on every teleport
    ▸ "𝘼𝙘𝙘𝙚𝙥𝙩 𝙞𝙩." text flashes when caught
--]]

local Elude = {
    active          = false,
    conn            = nil,
    switchTimer     = 0,
    SWITCH_INT      = 5,
    model           = nil,
    currentPos      = nil,
    dmgCooldown     = false,
    dmgCooldownTime = 2,
    dmgCDTimer      = 0,
}

local EludeHint = Instance.new("TextLabel")
EludeHint.Name = "EludeHint"; EludeHint.Size = UDim2.new(0,260,0,22)
EludeHint.AnchorPoint = Vector2.new(0,1); EludeHint.Position = UDim2.new(0,16,1,-70)
EludeHint.BackgroundTransparency = 1; EludeHint.Text = ""
EludeHint.Font = Enum.Font.Gotham; EludeHint.TextSize = 13
EludeHint.TextColor3 = Color3.fromRGB(100,200,200)
EludeHint.TextXAlignment = Enum.TextXAlignment.Left
EludeHint.TextTransparency = 1; EludeHint.ZIndex = 12; EludeHint.Parent = ScreenGui

local EludeFlicker = Instance.new("Frame")
EludeFlicker.Name = "EludeFlicker"; EludeFlicker.Size = UDim2.new(1,0,1,0)
EludeFlicker.BackgroundColor3 = Color3.fromRGB(0,80,80)
EludeFlicker.BackgroundTransparency = 1; EludeFlicker.ZIndex = 6; EludeFlicker.Parent = ScreenGui

local ELUDE_HINTS = {
    "did you hear that?","something moved.","you're being watched.",
    "don't look behind you.","it's somewhere close.","accept it.",
    "there's no safe direction.","your skin is crawling.","it already knows.",
    "you heard it again.","stop looking for it.","it never left.",
}

local function EludeFlash(hint, col)
    col = col or Color3.fromRGB(0,80,80)
    EludeFlicker.BackgroundColor3 = col
    TweenService:Create(EludeFlicker, TweenInfo.new(0.07), {BackgroundTransparency=0.86}):Play()
    task.delay(0.4, function()
        TweenService:Create(EludeFlicker, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
    end)
    if hint then
        EludeHint.Text = hint
        TweenService:Create(EludeHint, TweenInfo.new(0.3), {TextTransparency=0}):Play()
        task.delay(3.5, function()
            TweenService:Create(EludeHint, TweenInfo.new(1), {TextTransparency=1}):Play()
        end)
    end
end

local function BuildEludeModel()
    local m = Instance.new("Model"); m.Name = "Elude_Entity"
    local DC = Color3.fromRGB(6,6,10)
    local function mkP(nm, sz, tr)
        local p = Instance.new("Part")
        p.Name=nm; p.Size=sz; p.Anchored=true; p.CanCollide=false
        p.CastShadow=false; p.Material=Enum.Material.SmoothPlastic
        p.Color=DC; p.Transparency=tr; p.Parent=m; return p
    end
    local torso = mkP("Torso",    Vector3.new(1.8,2,0.8),   0.12)
    mkP("Head",     Vector3.new(0.9,0.9,0.9), 0.12)
    mkP("LeftArm",  Vector3.new(0.8,1.8,0.8), 0.22)
    mkP("RightArm", Vector3.new(0.8,1.8,0.8), 0.22)
    mkP("LeftLeg",  Vector3.new(0.8,1.8,0.8), 0.22)
    mkP("RightLeg", Vector3.new(0.8,1.8,0.8), 0.22)
    m.PrimaryPart = torso
    -- Teal slit eyes
    local hd = m:FindFirstChild("Head")
    if hd then
        local eyeBB = Instance.new("BillboardGui")
        eyeBB.Size = UDim2.new(0,44,0,16); eyeBB.StudsOffset = Vector3.new(0,0,0.47)
        eyeBB.AlwaysOnTop = false; eyeBB.Adornee = hd; eyeBB.Parent = hd
        local function mkEye(ax)
            local e = Instance.new("Frame")
            e.Size = UDim2.new(0.36,0,0.52,0); e.AnchorPoint = Vector2.new(ax,0.5)
            e.Position = UDim2.new(ax==0 and 0.06 or 0.94, 0, 0.5, 0)
            e.BackgroundColor3 = Color3.fromRGB(0,220,200); e.BorderSizePixel=0; e.Parent=eyeBB
            Instance.new("UICorner",e).CornerRadius = UDim.new(1,0)
            TweenService:Create(e, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {BackgroundColor3=Color3.fromRGB(0,100,90)}):Play()
        end
        mkEye(0); mkEye(1)
    end
    m.Parent = Workspace; return m
end

local function PlaceElude(model, cf)
    local offsets = {
        Torso=CFrame.new(0,0,0), Head=CFrame.new(0,1.45,0),
        LeftArm=CFrame.new(-1.3,0,0), RightArm=CFrame.new(1.3,0,0),
        LeftLeg=CFrame.new(-0.5,-1.9,0), RightLeg=CFrame.new(0.5,-1.9,0),
    }
    for name, off in pairs(offsets) do
        local p = model:FindFirstChild(name); if p then p.CFrame = cf * off end
    end
end

-- Check if a position is outside the player's camera FOV or obstructed from camera
local function EludeOutsideCameraView(pos)
    local camCF  = Camera.CFrame
    local camPos = camCF.Position
    local toPos  = pos - camPos
    local dist   = toPos.Magnitude

    -- Outside 70° half-angle FOV → consider out of view
    if camCF.LookVector:Dot(toPos.Unit) < 0.34 then return true end

    -- Within FOV — check if something blocks the line of sight from camera
    local excl = {Character}
    if Elude.model then table.insert(excl, Elude.model) end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = excl
    local hit = Workspace:Raycast(camPos, toPos.Unit * (dist - 0.4), rp)
    -- If something is blocking, then Elude is not visible from camera
    return hit ~= nil
end

-- Check if a position is also out of HRP direct line of sight (backs of walls still ok)
local function EludeOutsideHRPView(pos)
    local hrp = HumanoidRootPart; if not hrp then return true end
    local origin = hrp.Position + Vector3.new(0,1,0)
    local dir    = pos - origin; local dist = dir.Magnitude
    if dist < 0.5 then return false end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {Character}
    local hit = Workspace:Raycast(origin, dir.Unit * (dist - 0.4), rp)
    return hit ~= nil
end

--[[
    FindEludeSpot:
    Strategy — cast DOWN from elevated sample points around the player
    to find solid ground. Then check the found ground position is:
    1. Not occupied by a solid part (the ground IS a part surface, that's fine,
       but we don't want to be embedded inside a wall or closed room).
    2. Not visible from the camera.
    We verify "not inside anything" by doing a quick sphere check: cast rays
    in 4 lateral directions a short distance. If ALL are immediately blocked,
    we're probably inside something — skip that spot.
]]
local function FindEludeSpot(tries)
    local hrp = HumanoidRootPart; if not hrp then return nil end
    tries = tries or 32

    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {Character}

    for _ = 1, tries do
        local angle = math.random() * math.pi * 2
        local dist  = 12 + math.random() * 88  -- 12–100 studs
        local dir   = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local sampleXZ = hrp.Position + dir * dist

        -- Cast downward from high up to find ground surface
        local downOrigin = sampleXZ + Vector3.new(0, 60, 0)
        local downHit    = Workspace:Raycast(downOrigin, Vector3.new(0, -120, 0), rp)
        if not downHit then continue end

        -- Candidate: a small hover above ground surface
        local groundPos = downHit.Position + Vector3.new(0, 1.2, 0)

        -- Verify NOT inside a part: cast tiny rays outward in 4 directions.
        -- If any direction is immediately open (no hit within 1 stud), we're fine.
        local openSides = 0
        local checkDirs = {
            Vector3.new(1,0,0), Vector3.new(-1,0,0),
            Vector3.new(0,0,1), Vector3.new(0,0,-1),
        }
        for _, cd in ipairs(checkDirs) do
            local sideHit = Workspace:Raycast(groundPos, cd * 1.2, rp)
            if not sideHit then openSides = openSides + 1 end
        end
        if openSides < 2 then continue end  -- surrounded — skip

        -- Check it's outside the camera's view
        if not EludeOutsideCameraView(groundPos) then continue end

        return groundPos
    end

    return nil
end

-- Damage check: is Elude CLEARLY in camera view with no obstruction?
local function EludeVisibleFromCam(pos)
    local camCF  = Camera.CFrame; local camPos = camCF.Position
    local toE    = pos - camPos; local dist = toE.Magnitude
    if camCF.LookVector:Dot(toE.Unit) < 0.45 then return false end
    local excl = {Character}
    if Elude.model then table.insert(excl, Elude.model) end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = excl
    local hit = Workspace:Raycast(camPos, toE.Unit * (dist - 0.4), rp)
    return hit == nil
end

local function EludeTeleport()
    if not Elude.active then return end
    local spot = FindEludeSpot(32); if not spot then return end
    Elude.currentPos = spot

    local hrp = HumanoidRootPart
    local floatY = math.sin(tick() * 1.8) * 0.12
    local faceCF
    if hrp then
        faceCF = CFrame.new(spot + Vector3.new(0, floatY, 0),
                            Vector3.new(hrp.Position.X, spot.Y + floatY, hrp.Position.Z))
    else
        faceCF = CFrame.new(spot + Vector3.new(0, floatY, 0))
    end

    if not Elude.model then Elude.model = BuildEludeModel() end
    PlaceElude(Elude.model, faceCF)
    EludeFlash(ELUDE_HINTS[math.random(1, #ELUDE_HINTS)])
end

local function OnEludeEnable()
    Elude.active       = true
    Elude.switchTimer  = 0
    Elude.dmgCooldown  = false
    Elude.dmgCDTimer   = 0
    task.delay(0.8, function()
        if Elude.active then task.spawn(EludeTeleport) end
    end)

    Elude.conn = RunService.Heartbeat:Connect(function(dt)
        if not Elude.active then return end
        local hrp = HumanoidRootPart; if not hrp then return end

        if Elude.dmgCooldown then
            Elude.dmgCDTimer = Elude.dmgCDTimer - dt
            if Elude.dmgCDTimer <= 0 then Elude.dmgCooldown = false end
        end

        -- Switch timer
        Elude.switchTimer = Elude.switchTimer + dt
        if Elude.switchTimer >= Elude.SWITCH_INT then
            Elude.switchTimer = 0
            task.spawn(EludeTeleport)
        end

        -- Keep Elude facing player + floating bob
        if Elude.model and Elude.currentPos then
            local sp    = Elude.currentPos
            local floatY = math.sin(tick() * 1.8) * 0.12
            local faceCF = CFrame.new(
                sp + Vector3.new(0, floatY, 0),
                Vector3.new(hrp.Position.X, sp.Y + floatY, hrp.Position.Z)
            )
            PlaceElude(Elude.model, faceCF)
        end

        -- Damage check
        if not Elude.dmgCooldown and Elude.currentPos then
            local checkPos = Elude.currentPos + Vector3.new(0,1.5,0)
            if EludeVisibleFromCam(checkPos) then
                Elude.dmgCooldown = true; Elude.dmgCDTimer = Elude.dmgCooldownTime
                ModifyFate(-25)
                EludeFlash(nil, Color3.fromRGB(180,190,255))
                task.delay(0.12, function()
                    EludeFlicker.BackgroundColor3 = Color3.fromRGB(0,80,80)
                end)
                EludeHint.Text = "𝘼𝙘𝙘𝙚𝙥𝙩 𝙞𝙩."
                TweenService:Create(EludeHint, TweenInfo.new(0.15), {TextTransparency=0}):Play()
                task.delay(2.2, function()
                    TweenService:Create(EludeHint, TweenInfo.new(1), {TextTransparency=1}):Play()
                end)
                task.spawn(EludeTeleport)
            end
        end
    end)
end

local function OnEludeDisable()
    Elude.active = false
    if Elude.conn then Elude.conn:Disconnect(); Elude.conn = nil end
    if Elude.model then Elude.model:Destroy(); Elude.model = nil end
    Elude.currentPos = nil
    TweenService:Create(EludeHint,    TweenInfo.new(0.4), {TextTransparency=1}):Play()
    TweenService:Create(EludeFlicker, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
end

RegisterEntity("Elude","Paranoia",
    "Did you hear that? Every step frightening. Every open field watched. Accept it.",
    OnEludeEnable, OnEludeDisable)

-- ═══════════════════════════════════════════════════════════
--           ENTITY: NUMB  (Symbolizes: Wrath)
-- ═══════════════════════════════════════════════════════════
--[[
    ▸ Every 10s: 30% chance to trigger a blood rain event
    ▸ Phase 1 (5s) — WARNING PHASE:
        - Sky turns dark red  (Lighting.Ambient, OutdoorAmbient, FogColor)
        - Thin red fog begins (FogStart=80, FogEnd=300)
        - Blood droplets (small red parts) fall from above the player
        - Subtle rumble text: "find cover."
    ▸ Phase 2 (2s) — WRATH PHASE (triggered at 5s):
        - Intense screen shake (camera offset loop)
        - Fog goes very thick (FogEnd=30)
        - Blood rain gets heavier and faster
        - If player has NO cover (no solid part within 40 studs above) → -100% fate (instant death)
        - "𝙉𝙤𝙢𝙚𝙧𝙘𝙮." flashes on screen
    ▸ Phase 3 — CLEAR:
        - Everything resets to normal
        - "it's gone." text fades in, then out
    ▸ Cover check: raycast straight UP from player — if a solid part is hit within
      40 studs → the player is covered (roof / ceiling / overhang counts)
--]]

local Numb = {
    active      = false,
    conn        = nil,
    cycleTimer  = 0,
    CYCLE_INT   = 10,
    inEvent     = false,
    bloodParts  = {},
    shakeConn   = nil,
}

-- Store original lighting values to restore after event
local OrigLighting = {
    Ambient        = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogColor       = Lighting.FogColor,
    FogStart       = Lighting.FogStart,
    FogEnd         = Lighting.FogEnd,
    Brightness     = Lighting.Brightness,
}

-- Overlay for rain tint
local NumbOverlay = Instance.new("Frame")
NumbOverlay.Name = "NumbOverlay"; NumbOverlay.Size = UDim2.new(1,0,1,0)
NumbOverlay.BackgroundColor3 = Color3.fromRGB(80,0,0)
NumbOverlay.BackgroundTransparency = 1; NumbOverlay.ZIndex = 5; NumbOverlay.Parent = ScreenGui

-- Numb warning label (bottom center)
local NumbText = Instance.new("TextLabel")
NumbText.Name = "NumbText"; NumbText.Size = UDim2.new(0,340,0,30)
NumbText.AnchorPoint = Vector2.new(0.5,1); NumbText.Position = UDim2.new(0.5,0,1,-50)
NumbText.BackgroundTransparency = 1; NumbText.Text = "find cover."
NumbText.Font = Enum.Font.GothamBold; NumbText.TextSize = 20
NumbText.TextColor3 = Color3.fromRGB(200,40,40); NumbText.TextTransparency = 1
NumbText.ZIndex = 13; NumbText.Parent = ScreenGui

-- Shake overlay flicker
local NumbShakeFlicker = Instance.new("Frame")
NumbShakeFlicker.Name = "NumbShake"; NumbShakeFlicker.Size = UDim2.new(1,0,1,0)
NumbShakeFlicker.BackgroundColor3 = Color3.fromRGB(120,0,0)
NumbShakeFlicker.BackgroundTransparency = 1; NumbShakeFlicker.ZIndex = 9; NumbShakeFlicker.Parent = ScreenGui

local function PlayerHasCover()
    local hrp = HumanoidRootPart; if not hrp then return false end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {Character}
    -- Cast upward up to 40 studs
    local hit = Workspace:Raycast(hrp.Position + Vector3.new(0,1,0), Vector3.new(0,40,0), rp)
    return hit ~= nil
end

local function SpawnBloodDrop(heavy)
    local hrp = HumanoidRootPart; if not hrp then return end
    local spread = heavy and 30 or 18
    local spawnX = hrp.Position.X + (math.random() * spread*2 - spread)
    local spawnZ = hrp.Position.Z + (math.random() * spread*2 - spread)
    local spawnY = hrp.Position.Y + 35 + math.random() * 10

    local drop = Instance.new("Part")
    drop.Name        = "BloodDrop"
    drop.Size        = heavy and Vector3.new(0.18,0.6,0.18) or Vector3.new(0.12,0.4,0.12)
    drop.Color       = Color3.fromRGB(120 + math.random()*30, 0, 0)
    drop.Material    = Enum.Material.SmoothPlastic
    drop.Anchored    = false
    drop.CanCollide  = false
    drop.CastShadow  = false
    drop.Transparency = 0.1
    drop.CFrame      = CFrame.new(spawnX, spawnY, spawnZ)
    drop.Parent      = Workspace

    local vel = Instance.new("LinearVelocity")
    vel.MaxForce     = Vector3.new(0, math.huge, 0)
    vel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    vel.FreeLength   = 0
    vel.Attachment0  = Instance.new("Attachment", drop)
    vel.Parent       = drop

    -- Use BodyVelocity as fallback (more compatible with executors)
    vel:Destroy()
    local bv = Instance.new("BodyVelocity")
    bv.Velocity       = Vector3.new(math.random()*2-1, heavy and -(55+math.random()*15) or -(35+math.random()*10), math.random()*2-1)
    bv.MaxForce       = Vector3.new(0, math.huge, 0)
    bv.P              = math.huge
    bv.Parent         = drop

    table.insert(Numb.bloodParts, drop)

    -- Destroy after it's fallen long enough
    task.delay(3, function()
        if drop and drop.Parent then drop:Destroy() end
    end)
end

local bloodSpawnConn = nil

local function StartBloodRain(heavy)
    if bloodSpawnConn then bloodSpawnConn:Disconnect() end
    local interval = heavy and 0.05 or 0.12
    local spawnTimer = 0
    bloodSpawnConn = RunService.Heartbeat:Connect(function(dt)
        spawnTimer = spawnTimer + dt
        if spawnTimer >= interval then
            spawnTimer = 0
            SpawnBloodDrop(heavy)
            if heavy then SpawnBloodDrop(true) end  -- double density when heavy
        end
    end)
end

local function StopBloodRain()
    if bloodSpawnConn then bloodSpawnConn:Disconnect(); bloodSpawnConn = nil end
    for _, p in ipairs(Numb.bloodParts) do
        if p and p.Parent then p:Destroy() end
    end
    Numb.bloodParts = {}
end

local function RestoreLighting()
    TweenService:Create(Lighting, TweenInfo.new(1.5), {
        Ambient        = OrigLighting.Ambient,
        OutdoorAmbient = OrigLighting.OutdoorAmbient,
        FogColor       = OrigLighting.FogColor,
        FogStart       = OrigLighting.FogStart,
        FogEnd         = OrigLighting.FogEnd,
        Brightness     = OrigLighting.Brightness,
    }):Play()
end

local function StopScreenShake()
    if Numb.shakeConn then Numb.shakeConn:Disconnect(); Numb.shakeConn = nil end
    -- restore camera offset
    Camera.CFrame = Camera.CFrame  -- camera handles itself on next frame
end

local function StartScreenShake(intensity)
    if Numb.shakeConn then Numb.shakeConn:Disconnect() end
    local t = 0
    Numb.shakeConn = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        local ox = math.sin(t * 40)  * intensity
        local oy = math.cos(t * 53)  * intensity * 0.6
        local oz = math.sin(t * 31)  * intensity * 0.4
        Camera.CFrame = Camera.CFrame * CFrame.new(ox, oy, oz)
    end)
end

local function TriggerNumbEvent()
    if Numb.inEvent then return end
    Numb.inEvent = true

    -- ── PHASE 1: Red sky + thin fog + light blood rain ──────
    TweenService:Create(Lighting, TweenInfo.new(1.2), {
        Ambient        = Color3.fromRGB(60, 0, 0),
        OutdoorAmbient = Color3.fromRGB(80, 10, 10),
        FogColor       = Color3.fromRGB(120, 0, 0),
        FogStart       = 80,
        FogEnd         = 300,
        Brightness     = 0.4,
    }):Play()
    TweenService:Create(NumbOverlay, TweenInfo.new(1), {BackgroundTransparency=0.82}):Play()

    NumbText.Text = "find cover."
    TweenService:Create(NumbText, TweenInfo.new(0.5), {TextTransparency=0}):Play()

    StartBloodRain(false)

    -- Light camera rumble in phase 1
    StartScreenShake(0.04)

    -- ── PHASE 2 at t=5s: Wrath ──────────────────────────────
    task.delay(5, function()
        if not Numb.inEvent then return end

        -- Fog goes very thick
        TweenService:Create(Lighting, TweenInfo.new(0.3), {
            FogStart = 10,
            FogEnd   = 30,
            Ambient  = Color3.fromRGB(80, 0, 0),
        }):Play()
        TweenService:Create(NumbOverlay, TweenInfo.new(0.2), {BackgroundTransparency=0.65}):Play()

        -- Heavy blood rain
        StartBloodRain(true)

        -- Intense shake
        StartScreenShake(0.22)

        -- Flash warning
        NumbText.Text = "𝙉𝙤 𝙢𝙚𝙧𝙘𝙮."
        TweenService:Create(NumbText, TweenInfo.new(0.1), {TextTransparency=0}):Play()

        -- Repeated shake flicker
        local flickTimer = 0
        local flickConn
        flickConn = RunService.Heartbeat:Connect(function(dt)
            flickTimer = flickTimer + dt
            if flickTimer >= 0.08 then
                flickTimer = 0
                NumbShakeFlicker.BackgroundTransparency =
                    NumbShakeFlicker.BackgroundTransparency < 0.9 and 1 or 0.82
            end
        end)

        -- ── PHASE 3 at t=7s (5+2): Check cover + clear ──────
        task.delay(2, function()
            if flickConn then flickConn:Disconnect() end
            NumbShakeFlicker.BackgroundTransparency = 1
            StopScreenShake()
            StopBloodRain()

            -- Cover check: did the player have a roof above them?
            if not PlayerHasCover() then
                -- No cover → INSTANT DEATH
                ModifyFate(-100)
                if Humanoid then Humanoid.Health = 0 end
                NumbText.Text = "you didn't hide."
                NumbText.TextColor3 = Color3.fromRGB(255,255,255)
                TweenService:Create(NumbText, TweenInfo.new(0.1), {TextTransparency=0}):Play()
                task.delay(2.5, function()
                    NumbText.TextColor3 = Color3.fromRGB(200,40,40)
                    TweenService:Create(NumbText, TweenInfo.new(1), {TextTransparency=1}):Play()
                end)
            else
                NumbText.Text = "it's gone."
                TweenService:Create(NumbText, TweenInfo.new(0.4), {TextTransparency=0}):Play()
                task.delay(2, function()
                    TweenService:Create(NumbText, TweenInfo.new(1), {TextTransparency=1}):Play()
                end)
            end

            -- Restore lighting & overlay
            RestoreLighting()
            TweenService:Create(NumbOverlay, TweenInfo.new(2), {BackgroundTransparency=1}):Play()

            task.delay(2, function()
                Numb.inEvent = false
            end)
        end)
    end)
end

local function OnNumbEnable()
    Numb.active     = true
    Numb.cycleTimer = Numb.CYCLE_INT  -- first check after full interval

    Numb.conn = RunService.Heartbeat:Connect(function(dt)
        if not Numb.active or Numb.inEvent then return end
        Numb.cycleTimer = Numb.cycleTimer - dt
        if Numb.cycleTimer <= 0 then
            Numb.cycleTimer = Numb.CYCLE_INT
            if math.random() <= 0.30 then
                task.spawn(TriggerNumbEvent)
            end
        end
    end)
end

local function OnNumbDisable()
    Numb.active = false
    if Numb.conn then Numb.conn:Disconnect(); Numb.conn = nil end
    StopBloodRain()
    StopScreenShake()
    if Numb.inEvent then
        Numb.inEvent = false
        RestoreLighting()
        TweenService:Create(NumbOverlay,      TweenInfo.new(0.8), {BackgroundTransparency=1}):Play()
        TweenService:Create(NumbText,         TweenInfo.new(0.4), {TextTransparency=1}):Play()
        TweenService:Create(NumbShakeFlicker, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
    end
end

RegisterEntity("Numb","Wrath",
    "I hate him. I want to choke him. I woke with blood on my hands. It felt... relieving.",
    OnNumbEnable, OnNumbDisable)

-- ═══════════════════════════════════════════════════════════
--         ENTITY: MOUTHFEED  (Symbolizes: Recklessness)
-- ═══════════════════════════════════════════════════════════
--[[
    ▸ A 2D-in-3D floating open mouth that follows the local player.
    ▸ Built entirely from BillboardGui frames (no asset IDs needed).
    ▸ Movement:
        - Follows the player through walls (noclip — Anchored Part, no collision).
        - Has an "icy" velocity: it drifts toward you slowly and overshoots,
          missing frequently.  Simulated with a spring/damper formula:
          acceleration toward player but with low friction and some random drift.
    ▸ Vertical bobbing: moves up and down in a sine wave independently.
    ▸ The mouth animates: jaw opens wider when it gets closer to you.
    ▸ If the mouth Part touches the local player's HumanoidRootPart
      (distance < ~2.5 studs) → -30% fate instantly, 1.5s immunity.
    ▸ A faint ambient "breathing" screen pulse plays while Mouthfeed is active.
--]]

local Mouthfeed = {
    active       = false,
    conn         = nil,
    part         = nil,   -- invisible anchor Part that moves in 3D
    billboard    = nil,   -- BillboardGui on the part
    jawFrame     = nil,   -- the lower jaw frame (animated)
    velocity     = Vector3.new(0,0,0),
    spawnPos     = nil,
    dmgCooldown  = false,
    dmgCDTimer   = 0,
    DMG_CD       = 1.5,
    -- Spring constants for icy movement
    SPRING_K     = 1.8,   -- low attraction force
    DAMPING      = 0.18,  -- almost no friction → overshoots
    DRIFT_FORCE  = 0.35,  -- random sideways push per second
    MAX_SPEED    = 22,    -- stud/s cap
}

-- Ambient pulse overlay while Mouthfeed is active
local MouthPulse = Instance.new("Frame")
MouthPulse.Name                   = "MouthPulse"
MouthPulse.Size                   = UDim2.new(1,0,1,0)
MouthPulse.BackgroundColor3       = Color3.fromRGB(60,20,60)
MouthPulse.BackgroundTransparency = 1
MouthPulse.ZIndex                 = 5
MouthPulse.Parent                 = ScreenGui

-- Touch warning text
local MouthWarn = Instance.new("TextLabel")
MouthWarn.Name                   = "MouthWarn"
MouthWarn.Size                   = UDim2.new(0,300,0,26)
MouthWarn.AnchorPoint            = Vector2.new(0.5,1)
MouthWarn.Position               = UDim2.new(0.5,0,1,-110)
MouthWarn.BackgroundTransparency = 1
MouthWarn.Text                   = "it bit you."
MouthWarn.Font                   = Enum.Font.GothamBold
MouthWarn.TextSize               = 16
MouthWarn.TextColor3             = Color3.fromRGB(200,80,200)
MouthWarn.TextTransparency       = 1
MouthWarn.ZIndex                 = 12
MouthWarn.Parent                 = ScreenGui

local function BuildMouthBillboard(anchorPart)
    local bb = Instance.new("BillboardGui")
    bb.Name         = "MouthfeedBB"
    -- Base size at REFERENCE_DIST (20 studs). Scaled every frame in Heartbeat.
    bb.Size         = UDim2.new(0, 180, 0, 120)
    bb.StudsOffset  = Vector3.new(0, 0, 0)
    bb.AlwaysOnTop  = true
    bb.Adornee      = anchorPart
    bb.Parent       = anchorPart

    -- ── OUTER FACE (dark oval background) ──
    local face = Instance.new("Frame")
    face.Name             = "Face"
    face.Size             = UDim2.new(1,0,1,0)
    face.BackgroundColor3 = Color3.fromRGB(18,8,18)
    face.BackgroundTransparency = 0.05
    face.BorderSizePixel  = 0
    face.Parent           = bb
    Instance.new("UICorner", face).CornerRadius = UDim.new(0.4,0)

    -- ── UPPER LIP ──
    local upperLip = Instance.new("Frame")
    upperLip.Name             = "UpperLip"
    upperLip.Size             = UDim2.new(0.82,0,0.28,0)
    upperLip.AnchorPoint      = Vector2.new(0.5,1)
    upperLip.Position         = UDim2.new(0.5,0,0.52,0)
    upperLip.BackgroundColor3 = Color3.fromRGB(160,40,60)
    upperLip.BorderSizePixel  = 0
    upperLip.Parent           = bb
    Instance.new("UICorner", upperLip).CornerRadius = UDim.new(0.5,0)

    -- ── LOWER JAW (animated — moves down when close) ──
    local lowerJaw = Instance.new("Frame")
    lowerJaw.Name             = "LowerJaw"
    lowerJaw.Size             = UDim2.new(0.82,0,0.28,0)
    lowerJaw.AnchorPoint      = Vector2.new(0.5,0)
    lowerJaw.Position         = UDim2.new(0.5,0,0.52,0)
    lowerJaw.BackgroundColor3 = Color3.fromRGB(160,40,60)
    lowerJaw.BorderSizePixel  = 0
    lowerJaw.Parent           = bb
    Instance.new("UICorner", lowerJaw).CornerRadius = UDim.new(0.5,0)

    -- ── MOUTH CAVITY (dark hole between lips) ──
    local cavity = Instance.new("Frame")
    cavity.Name             = "Cavity"
    cavity.Size             = UDim2.new(0.74,0,0.20,0)
    cavity.AnchorPoint      = Vector2.new(0.5,0.5)
    cavity.Position         = UDim2.new(0.5,0,0.52,0)
    cavity.BackgroundColor3 = Color3.fromRGB(4,0,4)
    cavity.BorderSizePixel  = 0
    cavity.ZIndex           = 2
    cavity.Parent           = bb
    Instance.new("UICorner", cavity).CornerRadius = UDim.new(0.4,0)

    -- ── TEETH (upper row) ──
    for i = 1, 5 do
        local tooth = Instance.new("Frame")
        tooth.Size             = UDim2.new(0.10,0,0.16,0)
        tooth.AnchorPoint      = Vector2.new(0.5,1)
        tooth.Position         = UDim2.new(0.12 + (i-1)*0.18, 0, 0.52, 0)
        tooth.BackgroundColor3 = Color3.fromRGB(235,230,220)
        tooth.BorderSizePixel  = 0
        tooth.ZIndex           = 3
        tooth.Parent           = bb
        Instance.new("UICorner", tooth).CornerRadius = UDim.new(0,3)
    end

    -- ── TEETH (lower row, attached to lowerJaw logically) ──
    for i = 1, 5 do
        local tooth = Instance.new("Frame")
        tooth.Name             = "LowerTooth"..i
        tooth.Size             = UDim2.new(0.10,0,0.16,0)
        tooth.AnchorPoint      = Vector2.new(0.5,0)
        tooth.Position         = UDim2.new(0.12 + (i-1)*0.18, 0, 0.52, 0)
        tooth.BackgroundColor3 = Color3.fromRGB(220,215,205)
        tooth.BorderSizePixel  = 0
        tooth.ZIndex           = 3
        tooth.Parent           = bb
        Instance.new("UICorner", tooth).CornerRadius = UDim.new(0,3)
    end

    -- ── TONGUE (inside cavity) ──
    local tongue = Instance.new("Frame")
    tongue.Size             = UDim2.new(0.44,0,0.14,0)
    tongue.AnchorPoint      = Vector2.new(0.5,1)
    tongue.Position         = UDim2.new(0.5,0,0.68,0)
    tongue.BackgroundColor3 = Color3.fromRGB(180,50,70)
    tongue.BorderSizePixel  = 0
    tongue.ZIndex           = 2
    tongue.Parent           = bb
    Instance.new("UICorner", tongue).CornerRadius = UDim.new(0.5,0)

    -- Tongue pulse
    TweenService:Create(tongue,
        TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundColor3 = Color3.fromRGB(200,40,60)}
    ):Play()

    -- Drool drop (subtle)
    local drool = Instance.new("Frame")
    drool.Size             = UDim2.new(0.04,0,0.22,0)
    drool.AnchorPoint      = Vector2.new(0.5,0)
    drool.Position         = UDim2.new(0.5,0,0.68,0)
    drool.BackgroundColor3 = Color3.fromRGB(120,30,50)
    drool.BackgroundTransparency = 0.4
    drool.BorderSizePixel  = 0
    drool.ZIndex           = 2
    drool.Parent           = bb
    Instance.new("UICorner", drool).CornerRadius = UDim.new(0.5,0)

    -- Drool drip animation
    TweenService:Create(drool,
        TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
        {Size = UDim2.new(0.04,0,0.35,0)}
    ):Play()

    return bb, lowerJaw, cavity
end

local function UpdateJawOpenAmount(lowerJaw, cavity, openPct)
    -- openPct: 0 = closed (lips touching), 1 = wide open
    openPct = math.clamp(openPct, 0, 1)
    -- Lower jaw drops down
    lowerJaw.Position = UDim2.new(0.5, 0, 0.52 + openPct * 0.26, 0)
    -- Cavity grows taller
    cavity.Size = UDim2.new(0.74, 0, 0.08 + openPct * 0.28, 0)
end

local function OnMouthfeedEnable()
    Mouthfeed.active    = true
    Mouthfeed.dmgCooldown  = false
    Mouthfeed.dmgCDTimer   = 0

    -- Spawn the invisible anchor Part a bit behind the player
    local hrp = HumanoidRootPart
    local spawnCF = hrp and (hrp.CFrame * CFrame.new(0,2,-15)) or CFrame.new(0,5,0)

    local anchor = Instance.new("Part")
    anchor.Name        = "MouthfeedAnchor"
    anchor.Size        = Vector3.new(1,1,1)
    anchor.Anchored    = true
    anchor.CanCollide  = false
    anchor.CastShadow  = false
    anchor.Transparency = 1
    anchor.CFrame      = spawnCF
    anchor.Parent      = Workspace

    local bb, lowerJaw, cavity = BuildMouthBillboard(anchor)
    Mouthfeed.part      = anchor
    Mouthfeed.billboard = bb
    Mouthfeed.jawFrame  = lowerJaw
    Mouthfeed.cavity    = cavity
    Mouthfeed.velocity  = Vector3.new(0,0,0)

    -- Ambient pulse tween (breathing)
    local pulseRunning = true
    task.spawn(function()
        while pulseRunning and Mouthfeed.active do
            TweenService:Create(MouthPulse, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {BackgroundTransparency=0.93}):Play()
            task.wait(1.4)
            TweenService:Create(MouthPulse, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {BackgroundTransparency=1}):Play()
            task.wait(1.4)
        end
    end)

    local vertTimer = 0  -- for vertical sine bob

    Mouthfeed.conn = RunService.Heartbeat:Connect(function(dt)
        if not Mouthfeed.active then pulseRunning = false; return end
        local hrpNow = HumanoidRootPart; if not hrpNow then return end

        vertTimer = vertTimer + dt
        local bobY = math.sin(vertTimer * 1.2) * 3.5  -- ±3.5 studs vertical bob

        -- ── ICY SPRING PHYSICS ──────────────────────────────
        -- Target: slightly in front of player at eye level
        local targetPos = hrpNow.Position + Vector3.new(0, 1 + bobY, 0)

        local pos = Mouthfeed.part.Position
        local diff = targetPos - pos

        -- Spring attraction (weak)
        local attraction = diff * Mouthfeed.SPRING_K

        -- Random drift (icy slide off-axis)
        local drift = Vector3.new(
            (math.random()*2-1) * Mouthfeed.DRIFT_FORCE,
            0,
            (math.random()*2-1) * Mouthfeed.DRIFT_FORCE
        )

        -- Damping (very low → stays slippery)
        local damping = -Mouthfeed.velocity * Mouthfeed.DAMPING

        -- Integrate velocity
        Mouthfeed.velocity = Mouthfeed.velocity + (attraction + damping + drift) * dt

        -- Speed cap
        local speed = Mouthfeed.velocity.Magnitude
        if speed > Mouthfeed.MAX_SPEED then
            Mouthfeed.velocity = Mouthfeed.velocity.Unit * Mouthfeed.MAX_SPEED
        end

        -- Move the part
        local newPos = pos + Mouthfeed.velocity * dt
        Mouthfeed.part.CFrame = CFrame.new(newPos)

        -- ── PERSPECTIVE SCALING ──────────────────────────────
        -- Make the billboard appear bigger when camera is close and
        -- smaller when zoomed out, mimicking real 3D perspective.
        -- Formula: pixelSize = BASE_PX * REFERENCE_DIST / camDist
        -- BASE_PX=180, REFERENCE_DIST=20 → at 20 studs = 180px wide.
        if Mouthfeed.billboard then
            local camDist = (Camera.CFrame.Position - newPos).Magnitude
            camDist = math.max(camDist, 1)  -- no div by zero
            local BASE_PX     = 180
            local BASE_PX_H   = 120
            local REF_DIST    = 20
            local scaledW = math.clamp(BASE_PX   * REF_DIST / camDist, 40,  500)
            local scaledH = math.clamp(BASE_PX_H * REF_DIST / camDist, 26,  330)
            Mouthfeed.billboard.Size = UDim2.new(0, scaledW, 0, scaledH)
        end

        -- ── JAW ANIMATION based on distance ─────────────────
        local distToPlayer = (newPos - hrpNow.Position).Magnitude
        -- Wide open when close (< 5 studs), mostly closed when far (> 25 studs)
        local openAmt = math.clamp(1 - (distToPlayer - 3) / 22, 0, 1)
        UpdateJawOpenAmount(Mouthfeed.jawFrame, Mouthfeed.cavity, openAmt)

        -- ── DAMAGE COOLDOWN ──────────────────────────────────
        if Mouthfeed.dmgCooldown then
            Mouthfeed.dmgCDTimer = Mouthfeed.dmgCDTimer - dt
            if Mouthfeed.dmgCDTimer <= 0 then Mouthfeed.dmgCooldown = false end
        end

        -- ── TOUCH CHECK (5 stud radius) ─────────────────────
        if not Mouthfeed.dmgCooldown and distToPlayer < 5 then
            Mouthfeed.dmgCooldown = true
            Mouthfeed.dmgCDTimer  = Mouthfeed.DMG_CD
            ModifyFate(-30)

            -- Flash screen
            MouthPulse.BackgroundTransparency = 0.72
            TweenService:Create(MouthPulse, TweenInfo.new(0.6), {BackgroundTransparency=1}):Play()

            -- Bounce velocity away from player on contact
            local awayDir = (newPos - hrpNow.Position)
            if awayDir.Magnitude > 0 then
                Mouthfeed.velocity = awayDir.Unit * (Mouthfeed.MAX_SPEED * 0.9)
            end

            MouthWarn.Text = "it bit you."
            TweenService:Create(MouthWarn, TweenInfo.new(0.15), {TextTransparency=0}):Play()
            task.delay(2, function()
                TweenService:Create(MouthWarn, TweenInfo.new(0.8), {TextTransparency=1}):Play()
            end)
        end
    end)
end

local function OnMouthfeedDisable()
    Mouthfeed.active = false
    if Mouthfeed.conn then Mouthfeed.conn:Disconnect(); Mouthfeed.conn = nil end
    if Mouthfeed.part then Mouthfeed.part:Destroy(); Mouthfeed.part = nil end
    Mouthfeed.billboard = nil; Mouthfeed.jawFrame = nil; Mouthfeed.cavity = nil
    TweenService:Create(MouthPulse, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
    TweenService:Create(MouthWarn,  TweenInfo.new(0.3), {TextTransparency=1}):Play()
end

RegisterEntity("Mouthfeed","Recklessness",
    "I left my son in the burning building. I killed my friends driving. But this wouldn't stop me.",
    OnMouthfeedEnable, OnMouthfeedDisable)

-- ═══════════════════════════════════════════════════════════
--                    FATE UPDATE LOOP
-- ═══════════════════════════════════════════════════════════
local fateAccum = 0
local FATE_TICK = 0.05

local function SyncFateToHealth()
    if Humanoid and Humanoid.MaxHealth > 0 then
        FateData.current = (Humanoid.Health / Humanoid.MaxHealth) * FateData.max
    end
end

RunService.Heartbeat:Connect(function(dt)
    SyncFateToHealth()
    fateAccum = fateAccum + dt
    if fateAccum < FATE_TICK then return end
    local elapsed = fateAccum; fateAccum = 0

    local totalDrain = 0
    for _, rate in pairs(FateData.drainRates) do totalDrain = totalDrain + rate end
    if totalDrain ~= 0 then
        ModifyFate(-totalDrain * elapsed)
        if Humanoid and Humanoid.Health > 0 then
            local hp = Humanoid.MaxHealth
            Humanoid.Health = math.clamp(Humanoid.Health - (totalDrain * elapsed / 100) * hp, 0, hp)
        end
    end

    local pct = FateData.current / FateData.max
    local col = GetFateColor(pct)

    FateLabel.TextColor3         = col
    FateGlow.TextColor3          = col
    FateBarFill.BackgroundColor3 = col
    FateBarFill.Size             = UDim2.new(pct, 0, 1, 0)
    FatePct.Text                 = math.floor(pct * 100) .. "%"
    FatePct.TextColor3           = col

    SetVignette(math.clamp((1 - pct) * 1.1, 0, 1))

    if FateData.current <= 0 and not FateData.dead then
        FateData.dead = true
        DeathScreen.Visible = true
        TweenService:Create(DeathScreen, TweenInfo.new(1.5), {BackgroundTransparency=0}):Play()
        TweenService:Create(DeathLabel,  TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1.5), {TextTransparency=0}):Play()
        if Humanoid then Humanoid.Health = 0 end
    end

    if pct < 0.25 and not FateData.dead then
        local w = (0.25 - pct) / 0.25
        FateLabel.TextTransparency = 0.15 + ((math.sin(tick()*(3+w*5))+1)/2)*0.3
    else
        FateLabel.TextTransparency = 0
    end
end)

-- ═══════════════════════════════════════════════════════════
--                   CHARACTER RESPAWN
-- ═══════════════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function()
    FateData.dead    = false
    FateData.current = 100
    TweenService:Create(DeathScreen, TweenInfo.new(0.8), {BackgroundTransparency=1}):Play()
    TweenService:Create(DeathLabel,  TweenInfo.new(0.4), {TextTransparency=1}):Play()
    task.delay(1, function() DeathScreen.Visible = false end)
end)

-- ═══════════════════════════════════════════════════════════
--                     ATMOSPHERE
-- ═══════════════════════════════════════════════════════════
-- Save original lighting AFTER script loads (don't overwrite what we just saved)
OrigLighting.Ambient        = Lighting.Ambient
OrigLighting.OutdoorAmbient = Lighting.OutdoorAmbient
OrigLighting.FogColor       = Lighting.FogColor
OrigLighting.FogStart       = Lighting.FogStart
OrigLighting.FogEnd         = Lighting.FogEnd
OrigLighting.Brightness     = Lighting.Brightness

local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not Atmosphere then
    Atmosphere = Instance.new("Atmosphere"); Atmosphere.Parent = Lighting
end
Atmosphere.Density = 0.3;  Atmosphere.Offset = 0.05
Atmosphere.Color   = Color3.fromRGB(80,80,100)
Atmosphere.Decay   = Color3.fromRGB(50,40,60)
Atmosphere.Glare   = 0;    Atmosphere.Haze = 1.5

local GameCC = Instance.new("ColorCorrectionEffect")
GameCC.Name       = "GraceGameCC"
GameCC.Saturation = -0.2;  GameCC.Contrast  = 0.05
GameCC.Brightness = -0.04; GameCC.TintColor = Color3.fromRGB(210,210,230)
GameCC.Parent     = Lighting

-- ═══════════════════════════════════════════════════════════
--                    INTRO SEQUENCE
-- ═══════════════════════════════════════════════════════════
local IntroFrame = Instance.new("Frame")
IntroFrame.Size = UDim2.new(1,0,1,0); IntroFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
IntroFrame.BackgroundTransparency = 0; IntroFrame.ZIndex = 200; IntroFrame.Parent = ScreenGui

local IntroLabel = Instance.new("TextLabel")
IntroLabel.Size = UDim2.new(1,0,0,50); IntroLabel.AnchorPoint = Vector2.new(0.5,0.5)
IntroLabel.Position = UDim2.new(0.5,0,0.5,0); IntroLabel.BackgroundTransparency = 1
IntroLabel.Text = "𝐅𝐀𝐓𝐄"; IntroLabel.Font = Enum.Font.GothamBold; IntroLabel.TextSize = 52
IntroLabel.TextColor3 = Color3.fromRGB(255,215,0); IntroLabel.TextTransparency = 1
IntroLabel.ZIndex = 201; IntroLabel.Parent = IntroFrame

local IntroSub = Instance.new("TextLabel")
IntroSub.Size = UDim2.new(1,0,0,26); IntroSub.AnchorPoint = Vector2.new(0.5,0)
IntroSub.Position = UDim2.new(0.5,0,0.5,36); IntroSub.BackgroundTransparency = 1
IntroSub.Text = "a fanmade grace experience"; IntroSub.Font = Enum.Font.Gotham
IntroSub.TextSize = 15; IntroSub.TextColor3 = Color3.fromRGB(180,180,180)
IntroSub.TextTransparency = 1; IntroSub.ZIndex = 201; IntroSub.Parent = IntroFrame

task.spawn(function()
    task.wait(0.5)
    TweenService:Create(IntroLabel, TweenInfo.new(1.2), {TextTransparency=0}):Play()
    task.wait(0.6)
    TweenService:Create(IntroSub,   TweenInfo.new(1),   {TextTransparency=0}):Play()
    task.wait(2.8)
    TweenService:Create(IntroLabel, TweenInfo.new(1),   {TextTransparency=1}):Play()
    TweenService:Create(IntroSub,   TweenInfo.new(0.8), {TextTransparency=1}):Play()
    task.wait(1.2)
    TweenService:Create(IntroFrame, TweenInfo.new(1.5), {BackgroundTransparency=1}):Play()
    task.wait(1.6)
    IntroFrame:Destroy()
end)

-- ═══════════════════════════════════════════════════════════
print("╔══════════════════════════════════════════════╗")
print("║       GRACE Fanmade v4 — Loaded ✓          ║")
print("║  FATE system          ✓                     ║")
print("║  Entity panel         ✓  top-right 👁       ║")
print("║  GAZE                 ✓  Envy               ║")
print("║  ELUDE  v3            ✓  Paranoia            ║")
print("║    ↳ open ground spawn, outside camera      ║")
print("║  NUMB                 ✓  Wrath              ║")
print("║    ↳ blood rain, red fog, cover = survive   ║")
print("║  MOUTHFEED            ✓  Recklessness       ║")
print("║    ↳ icy spring physics, jaw animation      ║")
print("║    ↳ noclip, -30% fate on touch             ║")
print("╚══════════════════════════════════════════════╝")
