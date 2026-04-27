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

-- Use this for INSTANT burst damage (not drain-rate).
-- ModifyFate alone gets overwritten by SyncFateToHealth next frame
-- because SyncFateToHealth reads from Humanoid.Health.
-- This writes BOTH so they stay in sync.
local function InstantFateDamage(pct)
    ModifyFate(-pct)
    if Humanoid and Humanoid.MaxHealth > 0 then
        local newHP = math.clamp(Humanoid.Health - (pct / 100) * Humanoid.MaxHealth, 0, Humanoid.MaxHealth)
        Humanoid.Health = newHP
    end
end

-- ═══════════════════════════════════════════════════════════
--               ENTITY DEATH EFFECTS
-- ═══════════════════════════════════════════════════════════
-- Tracks which entity caused the most recent kill so the right
-- death effect fires on Humanoid.Died.
local lastDeathCause   = nil   -- "Gaze"|"Elude"|"Numb"|"Mouthfeed"|"Piece"|"Delictum"|nil
local pendingCorpse    = nil   -- pre-cloned corpse captured the moment damage is dealt

-- Tag a death cause AND immediately snapshot the character.
-- Must be called BEFORE setting Humanoid.Health = 0.
local function TagDeathCause(cause)
    lastDeathCause = cause
    -- Clone right now while the character is 100% intact
    local char = Character
    if char then
        local ok, clone = pcall(function()
            local c = char:Clone()
            -- Strip scripts so it stays static
            for _, obj in ipairs(c:GetDescendants()) do
                pcall(function()
                    if obj:IsA("Script") or obj:IsA("LocalScript")
                    or obj:IsA("Animator") or obj:IsA("Animation") then
                        obj:Destroy()
                    end
                end)
            end
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
                hum.PlatformStand = true
            end
            -- Anchor everything initially; effects will unanchor what they need
            for _, p in ipairs(c:GetDescendants()) do
                pcall(function()
                    if p:IsA("BasePart") then
                        p.Anchored   = true
                        p.CanCollide = false
                        p.CastShadow = false
                    end
                end)
            end
            c.Parent = Workspace
            return c
        end)
        if ok and clone then
            -- Destroy any previous unclaimed corpse
            if pendingCorpse then pcall(function() pendingCorpse:Destroy() end) end
            pendingCorpse = clone
        end
    end
end

-- ── Helpers ────────────────────────────────────────────────

-- Deep-clone the player's current avatar (shirts, pants, accessories, face)
-- into Workspace as a static corpse model.
-- charSnapshot must be passed in (captured BEFORE Roblox cleans up the char).
local function CloneAvatarAsCorpse(charSnapshot)
    if not charSnapshot then return nil end
    local ok, clone = pcall(function() return charSnapshot:Clone() end)
    if not ok or not clone then return nil end
    clone.Name = "GraceCorpse_"..tostring(tick())
    -- Strip live scripts / animator
    for _, obj in ipairs(clone:GetDescendants()) do
        if obj and obj.Parent then
            local isOk, isScript = pcall(function()
                return obj:IsA("Script") or obj:IsA("LocalScript")
                    or obj:IsA("Animator") or obj:IsA("Animation")
            end)
            if isOk and isScript then
                pcall(function() obj:Destroy() end)
            end
        end
    end
    -- Disable humanoid
    local hum = clone:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
        hum.PlatformStand = true
    end
    -- Unanchor every BasePart
    for _, p in ipairs(clone:GetDescendants()) do
        if p and p.Parent then
            pcall(function()
                if p:IsA("BasePart") then
                    p.Anchored   = false
                    p.CanCollide = true
                    p.CastShadow = false
                end
            end)
        end
    end
    clone.Parent = Workspace
    return clone
end

-- Spawn a flat blood puddle (Cylinder) at pos, growing over time
local function SpawnBloodPuddle(pos, startR, endR, growTime)
    startR   = startR  or 0.5
    endR     = endR    or 3
    growTime = growTime or 3
    local p  = Instance.new("Part")
    p.Name        = "BloodPuddle"
    p.Shape       = Enum.PartType.Cylinder
    p.Size        = Vector3.new(0.18, startR*2, startR*2)
    p.CFrame      = CFrame.new(pos + Vector3.new(0,0.06,0)) * CFrame.Angles(0,0,math.pi/2)
    p.Anchored    = true
    p.CanCollide  = false
    p.CastShadow  = false
    p.Color       = Color3.fromRGB(110,0,0)
    p.Material    = Enum.Material.SmoothPlastic
    p.Transparency = 0.15
    p.Parent      = Workspace
    TweenService:Create(p, TweenInfo.new(growTime),
        {Size = Vector3.new(0.18, endR*2, endR*2)}):Play()
    return p
end

-- Spray small blood droplets from pos with random velocities
local function SprayBlood(pos, count, speed)
    speed = speed or 18
    for _ = 1, count do
        local d = Instance.new("Part")
        d.Size        = Vector3.new(0.12,0.12,0.12)
        d.Color       = Color3.fromRGB(100 + math.random(0, 40), 0, 0)
        d.Material    = Enum.Material.SmoothPlastic
        d.Transparency = 0.1
        d.CanCollide  = false
        d.CastShadow  = false
        d.CFrame      = CFrame.new(pos + Vector3.new((math.random()-0.5)*0.5, 0, (math.random()-0.5)*0.5))
        d.Parent      = Workspace
        local bv = Instance.new("BodyVelocity")
        local dir = Vector3.new(math.random()-0.5, math.random()*1.2-0.2, math.random()-0.5).Unit
        bv.Velocity = dir * (speed * (0.5 + math.random()*0.8))
        bv.MaxForce = Vector3.new(1,1,1) * 9e8
        bv.P        = 9e8
        bv.Parent   = d
        game:GetService("Debris"):AddItem(bv, 0.35)
        game:GetService("Debris"):AddItem(d,  3)
    end
end

-- Continuous drip from pos for duration seconds
local function StartBloodDrip(posFunc, duration)
    local running = true
    task.spawn(function()
        while running do
            local pos = posFunc()
            if pos then SprayBlood(pos, 3, 4) end
            task.wait(0.14)
        end
    end)
    task.delay(duration, function() running = false end)
end

-- Schedule any instance for destruction after 5 minutes
local function AutoCleanup(inst)
    game:GetService("Debris"):AddItem(inst, 300)
end

-- ── GAZE DEATH ──────────────────────────────────────────────
-- Headless body at death position + censored black bar on neck stump
-- + decapitated head tossed nearby with looping blood drip
local function GazeDeathEffect(corpse)
    if not corpse then return end
    local hrp = corpse:FindFirstChild("HumanoidRootPart")
    local deathPos = hrp and hrp.Position or Vector3.new(0,0,0)

    -- Detach head from corpse
    local corpseHead = corpse:FindFirstChild("Head")
    local neckPos    = deathPos + Vector3.new(0,1.5,0)
    if corpseHead then
        neckPos = corpseHead.Position
        -- Detach: remove motor/weld so it's free
        for _, w in ipairs(corpseHead:GetChildren()) do
            if w:IsA("Motor6D") or w:IsA("Weld") or w:IsA("WeldConstraint") then
                w:Destroy()
            end
        end
    end

    -- Anchor body (headless static pose)
    for _, p in ipairs(corpse:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored   = true
            p.CanCollide = false
        end
    end

    -- Censored black bar over neck stump
    local torso = corpse:FindFirstChild("Torso") or corpse:FindFirstChild("UpperTorso")
    if torso then
        local bb = Instance.new("BillboardGui")
        bb.Size        = UDim2.new(0,100,0,24)
        bb.StudsOffset = Vector3.new(0,1.45,0)
        bb.AlwaysOnTop = false
        bb.Adornee     = torso
        bb.Parent      = torso

        local bar = Instance.new("Frame")
        bar.Size             = UDim2.new(1,0,1,0)
        bar.BackgroundColor3 = Color3.fromRGB(0,0,0)
        bar.BorderSizePixel  = 0
        bar.Parent           = bb

        local ct = Instance.new("TextLabel")
        ct.Size                   = UDim2.new(1,0,1,0)
        ct.BackgroundTransparency = 1
        ct.Text                   = "████████████"
        ct.Font                   = Enum.Font.GothamBold
        ct.TextSize               = 13
        ct.TextColor3             = Color3.fromRGB(25,25,25)
        ct.Parent                 = bb
    end

    -- Blood spray from neck
    SprayBlood(neckPos, 30, 12)
    local puddle = SpawnBloodPuddle(deathPos, 0.4, 3.5, 4)
    AutoCleanup(puddle)

    -- Toss decapitated head
    if corpseHead and corpseHead.Parent then
        corpseHead.Anchored   = false
        corpseHead.CanCollide = true
        local bv = Instance.new("BodyVelocity")
        local dir = Vector3.new(math.random()-0.5, 0.8+math.random()*0.5, math.random()-0.5).Unit
        bv.Velocity = dir * (10 + math.random()*8)
        bv.MaxForce = Vector3.new(1,1,1)*1e5
        bv.P        = 5000
        bv.Parent   = corpseHead
        game:GetService("Debris"):AddItem(bv, 0.5)

        -- Settle then drip
        task.delay(1.5, function()
            if corpseHead and corpseHead.Parent then
                corpseHead.Anchored = true
                local headPuddle = SpawnBloodPuddle(corpseHead.Position + Vector3.new(0,-0.5,0), 0.2, 1.8, 5)
                AutoCleanup(headPuddle)
                StartBloodDrip(function()
                    return corpseHead and corpseHead.Parent and (corpseHead.Position + Vector3.new(0,-0.5,0)) or nil
                end, 60)
            end
        end)
        AutoCleanup(corpseHead)
    end

    -- Ongoing neck drip from body
    StartBloodDrip(function()
        if torso and torso.Parent then
            return torso.Position + Vector3.new(0,1.4,0)
        end
        return nil
    end, 30)

    AutoCleanup(corpse)
end

-- ── ELUDE / MOUTHFEED DEATH ─────────────────────────────────
-- Limbs explode outward with BodyVelocity + blood spray + puddle
local function ExplodingLimbsDeathEffect(corpse)
    if not corpse then return end
    local hrp = corpse:FindFirstChild("HumanoidRootPart")
    local deathPos = hrp and hrp.Position or Vector3.new(0,0,0)

    -- Unanchor all parts for the explosion
    for _, p in ipairs(corpse:GetDescendants()) do
        if p and p.Parent then
            pcall(function()
                if p:IsA("BasePart") then
                    p.Anchored   = false
                    p.CanCollide = true
                end
            end)
        end
    end
        if p:IsA("BasePart") then
                    local dir = Vector3.new(math.random()-0.5, 0.4+math.random()*0.8, math.random()-0.5).Unit
                    local bv  = Instance.new("BodyVelocity")
                    bv.Velocity = dir * (18 + math.random()*28)
                    bv.MaxForce = Vector3.new(1,1,1) * 9e8
                    bv.P        = 9e8
                    bv.Parent   = p
                    game:GetService("Debris"):AddItem(bv, 0.4)
                end
            end)
        end
    end

    -- Blood burst at center
    SprayBlood(deathPos + Vector3.new(0,1,0), 35, 22)

    -- Puddle after parts land
    task.delay(0.6, function()
        local puddle = SpawnBloodPuddle(deathPos, 0.4, 5, 3.5)
        AutoCleanup(puddle)
    end)

    AutoCleanup(corpse)
end

-- ── NUMB DEATH ──────────────────────────────────────────────
-- Body squishes flat and turns red, then dissolves into blood puddle
local function NumbDeathEffect(corpse)
    if not corpse then return end
    local hrp = corpse:FindFirstChild("HumanoidRootPart")
    local deathPos = hrp and hrp.Position or Vector3.new(0,0,0)

    -- Parts are already anchored by the dispatcher

    -- Phase 1 (0–1.5s): turn red
    for _, p in ipairs(corpse:GetDescendants()) do
        if p:IsA("BasePart") then
            TweenService:Create(p, TweenInfo.new(1.5), {Color = Color3.fromRGB(150,0,0)}):Play()
        end
    end

    -- Phase 2 (1.5–4s): squish flat downward
    task.delay(1.5, function()
        if not corpse or not corpse.Parent then return end
        for _, p in ipairs(corpse:GetDescendants()) do
            if p:IsA("BasePart") then
                TweenService:Create(p,
                    TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size  = Vector3.new(p.Size.X*1.8, math.max(p.Size.Y*0.04, 0.04), p.Size.Z*1.8),
                    CFrame = CFrame.new(
                        deathPos.X + (p.Position.X-deathPos.X)*1.15,
                        deathPos.Y + 0.05,
                        deathPos.Z + (p.Position.Z-deathPos.Z)*1.15),
                    Transparency = 0.65,
                }):Play()
            end
        end

        local puddle = SpawnBloodPuddle(deathPos, 0.3, 7, 2.8)
        AutoCleanup(puddle)

        -- Phase 3 (3.5s): fade out completely
        task.delay(2.8, function()
            if not corpse or not corpse.Parent then return end
            for _, p in ipairs(corpse:GetDescendants()) do
                if p:IsA("BasePart") then
                    TweenService:Create(p, TweenInfo.new(0.6), {Transparency=1}):Play()
                end
            end
            task.delay(0.7, function()
                if corpse and corpse.Parent then corpse:Destroy() end
            end)
        end)
    end)

    AutoCleanup(corpse)
end

-- ── PIECE DEATH ─────────────────────────────────────────────
-- Ragdoll briefly, then both wrists yanked upward by infinite white chains
local function PieceDeathEffect(corpse)
    if not corpse then return end
    local hrp = corpse:FindFirstChild("HumanoidRootPart")
    local deathPos = hrp and hrp.Position or Vector3.new(0,0,0)

    -- Unanchor briefly for ragdoll settle
    for _, p in ipairs(corpse:GetDescendants()) do
        if p and p.Parent then
            pcall(function()
                if p:IsA("BasePart") then
                    p.Anchored   = false
                    p.CanCollide = true
                end
            end)
        end
    end

    task.delay(0.7, function()
        if not corpse or not corpse.Parent then return end

        -- Anchor everything
        for _, p in ipairs(corpse:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Anchored   = true
                p.CanCollide = false
            end
        end

        -- Find arm parts (R6 naming)
        local lArm = corpse:FindFirstChild("Left Arm")  or corpse:FindFirstChild("LeftHand")
        local rArm = corpse:FindFirstChild("Right Arm") or corpse:FindFirstChild("RightHand")
        local torso = corpse:FindFirstChild("Torso") or corpse:FindFirstChild("UpperTorso")

        -- Tween whole corpse upward 12 studs over 2s
        for _, p in ipairs(corpse:GetDescendants()) do
            if p:IsA("BasePart") then
                TweenService:Create(p,
                    TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    CFrame = p.CFrame + Vector3.new(0,12,0)
                }):Play()
            end
        end

        -- After lift, spawn tall white chain segments from each hand going to sky
        task.delay(2.1, function()
            local function MakeChain(armPart)
                if not armPart or not armPart.Parent then return end
                local chainPart = Instance.new("Part")
                chainPart.Name        = "PieceChain"
                chainPart.Size        = Vector3.new(0.18, 800, 0.18)
                chainPart.Color       = Color3.fromRGB(245,245,255)
                chainPart.Material    = Enum.Material.SmoothPlastic
                chainPart.Transparency = 0.08
                chainPart.Anchored    = true
                chainPart.CanCollide  = false
                chainPart.CastShadow  = false
                -- Centre the tall cylinder so bottom is at hand position
                chainPart.CFrame      = CFrame.new(armPart.Position + Vector3.new(0,400,0))
                chainPart.Parent      = Workspace
                AutoCleanup(chainPart)

                -- Subtle chain link texture via UIGradient BillboardGui won't work on Part,
                -- so add thin dark rings along the chain for visual rhythm
                for i = 1, 12 do
                    local ring = Instance.new("Part")
                    ring.Size        = Vector3.new(0.35, 0.12, 0.35)
                    ring.Color       = Color3.fromRGB(200,200,220)
                    ring.Material    = Enum.Material.SmoothPlastic
                    ring.Transparency = 0.2
                    ring.Anchored    = true
                    ring.CanCollide  = false
                    ring.CastShadow  = false
                    ring.CFrame      = CFrame.new(armPart.Position + Vector3.new(0, i*4, 0))
                    ring.Parent      = Workspace
                    AutoCleanup(ring)
                end
            end

            MakeChain(lArm)
            MakeChain(rArm)
        end)
    end)

    AutoCleanup(corpse)
end

-- ── DELICTUM DEATH ──────────────────────────────────────────
-- Only the head remains on the ground; rest of body gone; blood floods out
local function DelictumDeathEffect(corpse)
    if not corpse then return end
    local hrp = corpse:FindFirstChild("HumanoidRootPart")
    local deathPos = hrp and hrp.Position or Vector3.new(0,0,0)

    -- Immediately destroy everything except Head and accessories
    for _, p in ipairs(corpse:GetChildren()) do
        local keep = false
        if p:IsA("BasePart") and p.Name == "Head" then keep = true end
        if p:IsA("Accessory") then keep = true end  -- hats, hair stay
        if p:IsA("SpecialMesh") then keep = true end
        if not keep and p:IsA("BasePart") then p:Destroy()
        elseif not keep and p:IsA("Motor6D") then p:Destroy()
        end
    end
    -- Also destroy any non-head BaseParts that snuck in
    for _, p in ipairs(corpse:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "Head" then p:Destroy() end
    end

    local head = corpse:FindFirstChild("Head")
    if head then
        head.Anchored   = true
        head.CanCollide = false
        -- Drop it to the ground slightly
        local groundRay = Workspace:Raycast(
            deathPos + Vector3.new(0,5,0), Vector3.new(0,-15,0),
            RaycastParams.new()
        )
        local groundY = groundRay and groundRay.Position.Y or (deathPos.Y)
        head.CFrame = CFrame.new(deathPos.X, groundY + 0.55, deathPos.Z)
            * CFrame.Angles(0, math.random()*math.pi*2, math.random()*0.3-0.15)

        -- Snap accessories to head position
        for _, acc in ipairs(corpse:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle then
                    handle.Anchored   = true
                    handle.CanCollide = false
                    handle.CFrame = head.CFrame * CFrame.new(0, 0.5 + math.random()*0.3, 0)
                end
            end
        end

        -- Growing blood pool from head
        local puddle = SpawnBloodPuddle(head.Position + Vector3.new(0,-0.5,0), 0.2, 5.5, 6)
        AutoCleanup(puddle)

        -- Long blood drip animation
        StartBloodDrip(function()
            return head and head.Parent and (head.Position + Vector3.new(0,-0.45,0)) or nil
        end, 90)
    end

    AutoCleanup(corpse)
end

-- ── DISPATCH ────────────────────────────────────────────────
local function ConnectDeathEffect(targetChar)
    targetChar = targetChar or Character
    if not targetChar then return end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if not hum then
        hum = targetChar:WaitForChild("Humanoid", 5)
        if not hum then return end
    end

    hum.Died:Connect(function()
        local cause  = lastDeathCause
        local corpse = pendingCorpse   -- grabbed BEFORE health hit 0, fully intact
        lastDeathCause = nil
        pendingCorpse  = nil

        if not corpse then return end  -- no snapshot = no effect (non-entity death)

        task.delay(0.08, function()
            if not corpse.Parent then return end
            if      cause == "Gaze"      then GazeDeathEffect(corpse)
            elseif  cause == "Elude"     then ExplodingLimbsDeathEffect(corpse)
            elseif  cause == "Numb"      then NumbDeathEffect(corpse)
            elseif  cause == "Mouthfeed" then ExplodingLimbsDeathEffect(corpse)
            elseif  cause == "Piece"     then PieceDeathEffect(corpse)
            elseif  cause == "Delictum"  then DelictumDeathEffect(corpse)
            elseif  cause == "Norm"      then ExplodingLimbsDeathEffect(corpse)
            else    pcall(function() corpse:Destroy() end)
            end
        end)
    end)
end
task.defer(function()
    ConnectDeathEffect(Character)
end)

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
FateLabel.Text                   = "FATE"
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
FateGlow.Text                   = "FATE"
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
    ▸ "Accept it." text flashes when caught
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
                TagDeathCause("Elude")
                InstantFateDamage(25)
                EludeFlash(nil, Color3.fromRGB(180,190,255))
                task.delay(0.12, function()
                    EludeFlicker.BackgroundColor3 = Color3.fromRGB(0,80,80)
                end)
                EludeHint.Text = "Accept it."
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
        - "Nomercy." flashes on screen
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

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(
        math.random()*2 - 1,
        heavy and -(55 + math.random()*15) or -(35 + math.random()*10),
        math.random()*2 - 1
    )
    bv.MaxForce = Vector3.new(0, 9e8, 0)
    bv.P        = 9e8
    bv.Parent   = drop

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
        NumbText.Text = "No mercy."
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
                TagDeathCause("Numb")
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
            TagDeathCause("Mouthfeed")
            InstantFateDamage(30)

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
--           ENTITY: PIECE  (Symbolizes: Injustice)
-- ═══════════════════════════════════════════════════════════
--[[
    ▸ 6 monochrome see-through spinning Limbs float and follow you
      in the 3D world at walkspeed 7.
    ▸ If a limb is >30 studs away it rushes at speed 100,
      then slows back to 7 once inside 30 studs.
    ▸ Touch a limb (within 2.5 studs) → it is "stolen":
        - Disappears from the world.
        - That slot on the TOP-SCREEN R6 body HUD becomes visible.
        - That slot on the back-following ghost body becomes opaque.
    ▸ Back-follower: a full semi-transparent R6 ghost body sits 3 studs
      behind you at all times. Limb slots start invisible, fill in
      as you steal each piece.
    ▸ When ALL 6 limbs are stolen → CHASE MODE:
        - The complete back-follower detaches and chases you.
        - Speed starts at 0 and increases by +1 every 0.1 seconds.
        - Touching the chasing body → -100% fate (instant death).
    ▸ HUD: a small R6 silhouette panel at the top-left of the screen.
      Each body-part frame is monochrome and starts transparent,
      fills with a grey tone when stolen.
--]]

local Piece = {
    active        = false,
    conn          = nil,
    limbs         = {},
    follower      = nil,
    followerParts = {},
    hudParts      = {},
    chasing       = false,
    chaseSpeed    = 0,
    chaseAccTimer = 0,
    CHASE_ACC_INT = 0.1,
    dmgCooldown   = false,
    dmgCDTimer    = 0,
    DMG_CD        = 1.5,
    pendingReset  = false,   -- set true when Piece kills the player
}

local PIECE_LIMB_NAMES = {"Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg"}

-- Limb floating offsets (relative to player, spread around them)
local LIMB_ORBIT_OFFSETS = {
    Head     = Vector3.new( 0,   6,  -8),
    Torso    = Vector3.new(-8,   3,   4),
    LeftArm  = Vector3.new( 9,   4,   3),
    RightArm = Vector3.new(-6,   1,  -9),
    LeftLeg  = Vector3.new( 7,  -1,   8),
    RightLeg = Vector3.new(-3,   5,   9),
}

-- Limb sizes matching R6 roughly
local LIMB_SIZES = {
    Head     = Vector3.new(2,2,2),
    Torso    = Vector3.new(2,2,1),
    LeftArm  = Vector3.new(1,2,1),
    RightArm = Vector3.new(1,2,1),
    LeftLeg  = Vector3.new(1,2,1),
    RightLeg = Vector3.new(1,2,1),
}

-- ── HUD: R6 silhouette (top-left corner) ───────────────────
local PieceHUDFrame = Instance.new("Frame")
PieceHUDFrame.Name                   = "PieceHUD"
PieceHUDFrame.Size                   = UDim2.new(0,80,0,120)
PieceHUDFrame.AnchorPoint            = Vector2.new(0,0)
PieceHUDFrame.Position               = UDim2.new(0,12,0,12)
PieceHUDFrame.BackgroundColor3       = Color3.fromRGB(10,10,10)
PieceHUDFrame.BackgroundTransparency = 0.4
PieceHUDFrame.BorderSizePixel        = 0
PieceHUDFrame.Visible                = false
PieceHUDFrame.ZIndex                 = 15
PieceHUDFrame.Parent                 = ScreenGui
Instance.new("UICorner",PieceHUDFrame).CornerRadius = UDim.new(0,8)

local PieceHUDTitle = Instance.new("TextLabel")
PieceHUDTitle.Size                   = UDim2.new(1,0,0,14)
PieceHUDTitle.BackgroundTransparency = 1
PieceHUDTitle.Text                   = "P I E C E"
PieceHUDTitle.Font                   = Enum.Font.GothamBold
PieceHUDTitle.TextSize               = 9
PieceHUDTitle.TextColor3             = Color3.fromRGB(180,180,180)
PieceHUDTitle.ZIndex                 = 16
PieceHUDTitle.Parent                 = PieceHUDFrame

-- Body part positions on the HUD (pixel positions inside the 80x120 frame)
local HUD_PART_LAYOUT = {
    Head     = {x=30, y=15,  w=20, h=20},
    Torso    = {x=22, y=36,  w=36, h=28},
    LeftArm  = {x= 5, y=36,  w=16, h=28},
    RightArm = {x=59, y=36,  w=16, h=28},
    LeftLeg  = {x=22, y=65,  w=16, h=30},
    RightLeg = {x=42, y=65,  w=16, h=30},
}

for _, nm in ipairs(PIECE_LIMB_NAMES) do
    local layout = HUD_PART_LAYOUT[nm]
    local f = Instance.new("Frame")
    f.Name             = "HUD_"..nm
    f.Size             = UDim2.new(0, layout.w, 0, layout.h)
    f.Position         = UDim2.new(0, layout.x, 0, layout.y)
    f.BackgroundColor3 = Color3.fromRGB(160,160,160)
    f.BackgroundTransparency = 1   -- invisible until stolen
    f.BorderSizePixel  = 1
    f.BorderColor3     = Color3.fromRGB(80,80,80)
    f.ZIndex           = 16
    f.Parent           = PieceHUDFrame
    if nm == "Head" then
        Instance.new("UICorner", f).CornerRadius = UDim.new(0.2,0)
    end
    Piece.hudParts[nm] = f
end

-- Touch warning
local PieceWarn = Instance.new("TextLabel")
PieceWarn.Name                   = "PieceWarn"
PieceWarn.Size                   = UDim2.new(0,300,0,24)
PieceWarn.AnchorPoint            = Vector2.new(0.5,1)
PieceWarn.Position               = UDim2.new(0.5,0,1,-140)
PieceWarn.BackgroundTransparency = 1
PieceWarn.Text                   = ""
PieceWarn.Font                   = Enum.Font.GothamBold
PieceWarn.TextSize               = 14
PieceWarn.TextColor3             = Color3.fromRGB(180,180,180)
PieceWarn.TextTransparency       = 1
PieceWarn.ZIndex                 = 12
PieceWarn.Parent                 = ScreenGui

local function PieceShowWarn(txt)
    PieceWarn.Text = txt
    TweenService:Create(PieceWarn, TweenInfo.new(0.2), {TextTransparency=0}):Play()
    task.delay(2.5, function()
        TweenService:Create(PieceWarn, TweenInfo.new(0.8), {TextTransparency=1}):Play()
    end)
end

-- Build back-follower model (transparent R6 body behind player)
local function BuildFollowerModel()
    local model = Instance.new("Model")
    model.Name = "PieceFollower"
    local parts = {}
    for _, nm in ipairs(PIECE_LIMB_NAMES) do
        local p = Instance.new("Part")
        p.Name         = nm
        p.Size         = LIMB_SIZES[nm]
        p.Anchored     = true
        p.CanCollide   = false
        p.CastShadow   = false
        p.Material     = Enum.Material.SmoothPlastic
        p.Color        = Color3.fromRGB(160,160,160)
        p.Transparency = 1   -- invisible until stolen
        p.Parent       = model
        parts[nm]      = p
    end
    model.PrimaryPart = parts["Torso"]
    model.Parent      = Workspace
    return model, parts
end

-- Position follower behind the player
local function UpdateFollowerPose(followerParts, baseCF)
    -- CFrames relative to the Torso
    local offsets = {
        Torso    = CFrame.new(0,  0,   0),
        Head     = CFrame.new(0,  1.5, 0),
        LeftArm  = CFrame.new(-1.5, 0, 0),
        RightArm = CFrame.new( 1.5, 0, 0),
        LeftLeg  = CFrame.new(-0.5,-2, 0),
        RightLeg = CFrame.new( 0.5,-2, 0),
    }
    for nm, off in pairs(offsets) do
        if followerParts[nm] then
            followerParts[nm].CFrame = baseCF * off
        end
    end
end

-- Build the 3D floating limb parts
local function BuildFloatingLimbs()
    local hrp = HumanoidRootPart
    local limbs = {}
    for _, nm in ipairs(PIECE_LIMB_NAMES) do
        local offset = LIMB_ORBIT_OFFSETS[nm]
        local startPos = hrp and (hrp.Position + offset) or Vector3.new(0,5,0)
        local p = Instance.new("Part")
        p.Name         = "PieceLimb_"..nm
        p.Size         = LIMB_SIZES[nm]
        p.Anchored     = true
        p.CanCollide   = false
        p.CastShadow   = false
        p.Material     = Enum.Material.SmoothPlastic
        p.Color        = Color3.fromRGB(180,180,180)
        p.Transparency = 0.45
        p.CFrame       = CFrame.new(startPos)
        p.Parent       = Workspace
        table.insert(limbs, {
            name   = nm,
            part   = p,
            stolen = false,
            vel    = Vector3.new(0,0,0),
            spinT  = math.random() * math.pi * 2,  -- random spin start
        })
    end
    return limbs
end

-- Mark a limb as stolen
local function StealLimb(limbEntry)
    if limbEntry.stolen then return end
    limbEntry.stolen = true

    -- Remove from world
    if limbEntry.part then
        limbEntry.part:Destroy()
        limbEntry.part = nil
    end

    local nm = limbEntry.name

    -- Make HUD slot visible
    local hudF = Piece.hudParts[nm]
    if hudF then
        TweenService:Create(hudF, TweenInfo.new(0.3), {BackgroundTransparency=0.2}):Play()
    end

    -- Make follower part visible
    local fPart = Piece.followerParts[nm]
    if fPart then
        TweenService:Create(fPart, TweenInfo.new(0.4), {Transparency=0.35}):Play()
    end

    PieceShowWarn("you took the "..nm:lower()..".")

    -- Check if all stolen
    local allStolen = true
    for _, le in ipairs(Piece.limbs) do
        if not le.stolen then allStolen = false; break end
    end

    if allStolen then
        task.delay(0.8, function()
            if not Piece.active then return end
            Piece.chasing      = true
            Piece.chaseSpeed   = 0
            Piece.chaseAccTimer = 0
            PieceShowWarn("Its complete.")
            -- Make follower more opaque/ominous
            for _, fp in pairs(Piece.followerParts) do
                TweenService:Create(fp, TweenInfo.new(0.6), {Transparency=0.1, Color=Color3.fromRGB(30,30,30)}):Play()
            end
        end)
    end
end

-- Clears all 3D objects and GUI, then restarts the entity from scratch.
-- Called on respawn when Piece was the cause of death.
local function PieceHardReset()
    -- Stop heartbeat loop
    if Piece.conn then Piece.conn:Disconnect(); Piece.conn = nil end
    -- Destroy floating limbs
    for _, le in ipairs(Piece.limbs) do
        if le.part then le.part:Destroy(); le.part = nil end
    end
    Piece.limbs = {}
    -- Destroy follower
    if Piece.follower then Piece.follower:Destroy(); Piece.follower = nil end
    Piece.followerParts = {}
    -- Reset chase state
    Piece.chasing       = false
    Piece.chaseSpeed    = 0
    Piece.chaseAccTimer = 0
    Piece.dmgCooldown   = false
    Piece.dmgCDTimer    = 0
    Piece.pendingReset  = false
    -- Reset HUD slots to invisible
    for _, nm in ipairs(PIECE_LIMB_NAMES) do
        local hf = Piece.hudParts[nm]
        if hf then hf.BackgroundTransparency = 1 end
    end
    -- Rebuild everything after a short delay (let respawn finish)
    task.delay(1.5, function()
        if not Piece.active then return end
        local followerModel, fParts = BuildFollowerModel()
        Piece.follower      = followerModel
        Piece.followerParts = fParts
        Piece.limbs         = BuildFloatingLimbs()
        PieceHUDFrame.Visible = true
        PieceShowWarn("Steal it.")
        -- Restart heartbeat
        OnPieceEnable()
    end)
end

local function OnPieceEnable()
    Piece.active      = true
    Piece.chasing     = false
    Piece.chaseSpeed  = 0
    Piece.dmgCooldown = false
    Piece.dmgCDTimer  = 0

    -- Reset stolen state
    Piece.limbs = {}

    -- Build follower
    local followerModel, fParts = BuildFollowerModel()
    Piece.follower      = followerModel
    Piece.followerParts = fParts

    -- Build floating limbs
    Piece.limbs = BuildFloatingLimbs()

    -- Show HUD
    PieceHUDFrame.Visible = true
    for _, nm in ipairs(PIECE_LIMB_NAMES) do
        local hf = Piece.hudParts[nm]
        if hf then hf.BackgroundTransparency = 1 end
    end

    PieceShowWarn("Steal it.")

    Piece.conn = RunService.Heartbeat:Connect(function(dt)
        if not Piece.active then return end
        local hrp = HumanoidRootPart; if not hrp then return end

        -- ── DAMAGE COOLDOWN ──
        if Piece.dmgCooldown then
            Piece.dmgCDTimer = Piece.dmgCDTimer - dt
            if Piece.dmgCDTimer <= 0 then Piece.dmgCooldown = false end
        end

        -- ── MOVE & SPIN FLOATING LIMBS ───────────────────────
        for _, le in ipairs(Piece.limbs) do
            if le.stolen or not le.part then continue end

            local p         = le.part
            local curPos    = p.Position
            local targetPos = hrp.Position + LIMB_ORBIT_OFFSETS[le.name]
            local distToTarget = (targetPos - curPos).Magnitude

            -- Speed: 100 if far from target (>30), else 4
            local speed = distToTarget > 30 and 100 or 4

            local dir = (targetPos - curPos)
            local dist = dir.Magnitude
            if dist > 0.1 then
                local moveAmt = math.min(speed * dt, dist)
                curPos = curPos + dir.Unit * moveAmt
            end

            -- Spin
            le.spinT = le.spinT + dt * 2.2
            p.CFrame = CFrame.new(curPos) * CFrame.Angles(le.spinT, le.spinT * 0.7, 0)

            -- Touch check (2.5 studs)
            if (curPos - hrp.Position).Magnitude < 2.5 then
                StealLimb(le)
            end
        end

        -- ── FOLLOWER POSITIONING ─────────────────────────────
        if not Piece.chasing then
            -- Sit 3 studs behind player, mirroring their CFrame
            local behindCF = hrp.CFrame * CFrame.new(0, 0, 3)
            UpdateFollowerPose(Piece.followerParts, behindCF)
        else
            -- ── CHASE MODE ──────────────────────────────────
            Piece.chaseAccTimer = Piece.chaseAccTimer + dt
            if Piece.chaseAccTimer >= Piece.CHASE_ACC_INT then
                Piece.chaseAccTimer = 0
                Piece.chaseSpeed    = Piece.chaseSpeed + 1
            end

            -- Move follower torso toward player
            local torso = Piece.followerParts["Torso"]
            if torso then
                local curTorsoPos = torso.Position
                local toPlayer    = hrp.Position - curTorsoPos
                local dist2       = toPlayer.Magnitude
                if dist2 > 0.3 then
                    local moveAmt = math.min(Piece.chaseSpeed * dt, dist2)
                    local newTorsoPos = curTorsoPos + toPlayer.Unit * moveAmt
                    local faceCF = CFrame.new(newTorsoPos,
                        Vector3.new(hrp.Position.X, newTorsoPos.Y, hrp.Position.Z))
                    UpdateFollowerPose(Piece.followerParts, faceCF)
                end

                -- Chase touch check (3 studs)
                if not Piece.dmgCooldown and (torso.Position - hrp.Position).Magnitude < 3 then
                    Piece.dmgCooldown = true
                    Piece.dmgCDTimer  = Piece.DMG_CD
                    TagDeathCause("Piece")
                    InstantFateDamage(100)
                    PieceShowWarn("Its just a piece of useless object.")
                    -- Flag that Piece killed the player — reset will trigger on respawn
                    Piece.pendingReset = true
                end
            end
        end
    end)
end

local function OnPieceDisable()
    Piece.active  = false
    Piece.chasing = false
    if Piece.conn then Piece.conn:Disconnect(); Piece.conn = nil end
    -- Destroy floating limbs
    for _, le in ipairs(Piece.limbs) do
        if le.part then le.part:Destroy(); le.part = nil end
    end
    Piece.limbs = {}
    -- Destroy follower
    if Piece.follower then Piece.follower:Destroy(); Piece.follower = nil end
    Piece.followerParts = {}
    -- Hide HUD
    PieceHUDFrame.Visible = false
    TweenService:Create(PieceWarn, TweenInfo.new(0.3), {TextTransparency=1}):Play()
end

RegisterEntity("Piece","Injustice",
    "Why waste money on a useless object? Steal it. Get it. Hide it. It's just a piece anyway.",
    OnPieceEnable, OnPieceDisable)

-- ═══════════════════════════════════════════════════════════
--        ENTITY: DELICTUM  (Symbolizes: Past Mistakes)
-- ═══════════════════════════════════════════════════════════
--[[
    RECORDING PHASE:
    ▸ From the moment Delictum is enabled, it silently records the
      local player's CFrame (position + rotation) every 0.05s into
      a rolling history buffer per "life".

    SHADOW SPAWN:
    ▸ Each time the player dies (CharacterAdded fires), after 2 seconds
      a new shadow clone spawns and plays back that life's recorded path.
    ▸ It loops infinitely once it reaches the end of the recording.
    ▸ Multiple deaths = multiple shadows running simultaneously, each
      replaying a different life's path.
    ▸ Shadow appearance: dark semi-transparent R6 body with a faint
      purple/grey tint, always at the recorded CFrame (no physics).

    DAMAGE:
    ▸ If the local player gets within 3 studs of ANY shadow's torso:
      -45% fate instantly, 2s immunity.

    LIMIT: max 8 simultaneous shadows to avoid performance issues.
--]]

local Delictum = {
    active         = false,
    recordConn     = nil,
    shadowConn     = nil,
    -- Recording
    currentRecord  = {},       -- {cf, t} per frame this life
    recordTimer    = 0,
    RECORD_INTERVAL = 0.05,
    -- Shadows
    shadows        = {},       -- array of { frames={cf}, index, model, parts, looping }
    MAX_SHADOWS    = 8,
    -- Damage
    dmgCooldown    = false,
    dmgCDTimer     = 0,
    DMG_CD         = 2,
}

local DelictumWarn = Instance.new("TextLabel")
DelictumWarn.Name                   = "DelictumWarn"
DelictumWarn.Size                   = UDim2.new(0,300,0,24)
DelictumWarn.AnchorPoint            = Vector2.new(0.5,1)
DelictumWarn.Position               = UDim2.new(0.5,0,1,-158)
DelictumWarn.BackgroundTransparency = 1
DelictumWarn.Text                   = ""
DelictumWarn.Font                   = Enum.Font.GothamBold
DelictumWarn.TextSize               = 14
DelictumWarn.TextColor3             = Color3.fromRGB(160,120,200)
DelictumWarn.TextTransparency       = 1
DelictumWarn.ZIndex                 = 12
DelictumWarn.Parent                 = ScreenGui

-- Shadow screen tint (purple flash on touch)
local DelictumTint = Instance.new("Frame")
DelictumTint.Size                   = UDim2.new(1,0,1,0)
DelictumTint.BackgroundColor3       = Color3.fromRGB(80,0,120)
DelictumTint.BackgroundTransparency = 1
DelictumTint.ZIndex                 = 7
DelictumTint.Parent                 = ScreenGui

local function DelictumShowWarn(txt)
    DelictumWarn.Text = txt
    TweenService:Create(DelictumWarn, TweenInfo.new(0.2), {TextTransparency=0}):Play()
    task.delay(2.5, function()
        TweenService:Create(DelictumWarn, TweenInfo.new(0.8), {TextTransparency=1}):Play()
    end)
end

-- Build a shadow R6 model
local function BuildShadowModel()
    local m = Instance.new("Model")
    m.Name = "Delictum_Shadow_"..tostring(tick())
    local shadowCol = Color3.fromRGB(30, 10, 50)
    local function mkP(nm, sz)
        local p = Instance.new("Part")
        p.Name = nm; p.Size = sz; p.Anchored = true
        p.CanCollide = false; p.CastShadow = false
        p.Material = Enum.Material.SmoothPlastic
        p.Color = shadowCol; p.Transparency = 0.45
        p.Parent = m; return p
    end
    local torso = mkP("Torso",    Vector3.new(2,2,1))
    mkP("Head",     Vector3.new(1,1,1))
    mkP("LeftArm",  Vector3.new(1,2,1))
    mkP("RightArm", Vector3.new(1,2,1))
    mkP("LeftLeg",  Vector3.new(1,2,1))
    mkP("RightLeg", Vector3.new(1,2,1))
    m.PrimaryPart = torso

    -- Faint purple glow eyes via BillboardGui
    local hd = m:FindFirstChild("Head")
    if hd then
        local eyeBB = Instance.new("BillboardGui")
        eyeBB.Size = UDim2.new(0,30,0,10); eyeBB.StudsOffset = Vector3.new(0,0,0.52)
        eyeBB.AlwaysOnTop = false; eyeBB.Adornee = hd; eyeBB.Parent = hd
        local function mkEye(ax)
            local e = Instance.new("Frame")
            e.Size = UDim2.new(0.35,0,0.7,0); e.AnchorPoint = Vector2.new(ax,0.5)
            e.Position = UDim2.new(ax==0 and 0.08 or 0.92, 0, 0.5, 0)
            e.BackgroundColor3 = Color3.fromRGB(160,80,255)
            e.BorderSizePixel = 0; e.Parent = eyeBB
            Instance.new("UICorner",e).CornerRadius = UDim.new(1,0)
            TweenService:Create(e, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,-1,true),
                {BackgroundColor3=Color3.fromRGB(80,20,140)}):Play()
        end
        mkEye(0); mkEye(1)
    end

    m.Parent = Workspace

    -- Collect parts into a table for fast CFrame setting
    local parts = {}
    for _, p in ipairs(m:GetChildren()) do
        if p:IsA("BasePart") then parts[p.Name] = p end
    end
    return m, parts
end

-- Position a shadow model at a recorded CFrame (torso = base)
local function PlaceShadowAt(shadowParts, cf)
    local offsets = {
        Torso    = CFrame.new(0, 0,    0),
        Head     = CFrame.new(0, 1.5,  0),
        LeftArm  = CFrame.new(-1.5, 0, 0),
        RightArm = CFrame.new( 1.5, 0, 0),
        LeftLeg  = CFrame.new(-0.5,-2, 0),
        RightLeg = CFrame.new( 0.5,-2, 0),
    }
    for nm, off in pairs(offsets) do
        if shadowParts[nm] then shadowParts[nm].CFrame = cf * off end
    end
end

-- Finalise the current recording and spawn a shadow that plays it back
local function SpawnShadowFromRecording(frames)
    if #frames < 2 then return end
    if #Delictum.shadows >= Delictum.MAX_SHADOWS then
        -- Remove the oldest shadow to stay under limit
        local oldest = table.remove(Delictum.shadows, 1)
        if oldest.model then oldest.model:Destroy() end
    end

    local model, parts = BuildShadowModel()
    local shadow = {
        frames = frames,
        index  = 1,
        model  = model,
        parts  = parts,
        timer  = 0,
        STEP   = 0.05,   -- matches recording interval
    }
    table.insert(Delictum.shadows, shadow)
    -- Place immediately at first recorded position
    PlaceShadowAt(parts, frames[1])
end

-- Called on each death while Delictum is active
local function DelictumOnDeath()
    if not Delictum.active then return end
    local frames = Delictum.currentRecord
    Delictum.currentRecord = {}   -- start fresh recording for next life

    if #frames < 2 then return end

    task.delay(2, function()
        if not Delictum.active then return end
        SpawnShadowFromRecording(frames)
        DelictumShowWarn("mistakes don't disappear.")
    end)
end

local function OnDelictumEnable()
    Delictum.active        = true
    Delictum.currentRecord = {}
    Delictum.recordTimer   = 0
    Delictum.dmgCooldown   = false
    Delictum.dmgCDTimer    = 0

    -- Recording loop
    Delictum.recordConn = RunService.Heartbeat:Connect(function(dt)
        if not Delictum.active then return end
        local hrp = HumanoidRootPart; if not hrp then return end

        Delictum.recordTimer = Delictum.recordTimer + dt
        if Delictum.recordTimer >= Delictum.RECORD_INTERVAL then
            Delictum.recordTimer = 0
            -- Record torso CFrame (position + facing)
            table.insert(Delictum.currentRecord, hrp.CFrame)
            -- Cap recording length to 20 minutes worth of frames to save memory
            if #Delictum.currentRecord > 24000 then
                table.remove(Delictum.currentRecord, 1)
            end
        end

        -- ── ADVANCE SHADOW PLAYBACK ──────────────────────────
        for _, shadow in ipairs(Delictum.shadows) do
            if not shadow.model or not shadow.model.Parent then continue end

            shadow.timer = shadow.timer + dt
            if shadow.timer >= shadow.STEP then
                shadow.timer = 0
                shadow.index = shadow.index + 1
                -- Loop back to start
                if shadow.index > #shadow.frames then
                    shadow.index = 1
                end
                PlaceShadowAt(shadow.parts, shadow.frames[shadow.index])
            end
        end

        -- ── DAMAGE CHECK ─────────────────────────────────────
        if Delictum.dmgCooldown then
            Delictum.dmgCDTimer = Delictum.dmgCDTimer - dt
            if Delictum.dmgCDTimer <= 0 then Delictum.dmgCooldown = false end
        end

        if not Delictum.dmgCooldown and HumanoidRootPart then
            local playerPos = HumanoidRootPart.Position
            for _, shadow in ipairs(Delictum.shadows) do
                if shadow.parts and shadow.parts["Torso"] then
                    local d = (shadow.parts["Torso"].Position - playerPos).Magnitude
                    if d < 3 then
                        Delictum.dmgCooldown = true
                        Delictum.dmgCDTimer  = Delictum.DMG_CD
                        TagDeathCause("Delictum")
                        InstantFateDamage(45)
                        TweenService:Create(DelictumTint, TweenInfo.new(0.15), {BackgroundTransparency=0.75}):Play()
                        task.delay(0.3, function()
                            TweenService:Create(DelictumTint, TweenInfo.new(0.7), {BackgroundTransparency=1}):Play()
                        end)
                        DelictumShowWarn("that was you.")
                        break
                    end
                end
            end
        end
    end)
end

local function OnDelictumDisable()
    Delictum.active = false
    if Delictum.recordConn then Delictum.recordConn:Disconnect(); Delictum.recordConn = nil end
    -- Destroy all shadows
    for _, shadow in ipairs(Delictum.shadows) do
        if shadow.model then shadow.model:Destroy() end
    end
    Delictum.shadows       = {}
    Delictum.currentRecord = {}
    TweenService:Create(DelictumWarn, TweenInfo.new(0.3), {TextTransparency=1}):Play()
    TweenService:Create(DelictumTint, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
end

RegisterEntity("Delictum","Past Mistakes",
    "Every mistake, every scar I left in the past... it affects the future. What else can I do?",
    OnDelictumEnable, OnDelictumDisable)

-- ═══════════════════════════════════════════════════════════
--         ENTITY: NORM  (Symbolizes: Lust / Self-pleasure)
-- ═══════════════════════════════════════════════════════════
--[[
    PHASE 1 — SHAKING EYE COUNTDOWN:
    ▸ Every 10–25s a large shaking eye appears on the screen (ScreenGui).
    ▸ It shakes with random offsets every frame.
    ▸ The pupil displays a countdown: 5, 4, 3, 2, 1.
    ▸ Each number lasts 1 second. The eye shakes faster as the count drops.

    PHASE 2 — BLOCKING EYE IN 3D:
    ▸ When countdown hits 0, the screen eye disappears.
    ▸ A large 2D-in-3D "happy eye" (eyelid lifted, curved) spawns in front
      of the player, floating at eye-level in the 3D world.
    ▸ It follows the player's facing direction with smooth spring delay
      so it always tries to stay directly in front of you.
    ▸ After 5 seconds it fades and disappears.
    ▸ Touch (within 3.5 studs of the billboard part): -50% fate, 2s immunity.

    DETAILS:
    ▸ "Feels great isn't it?" subtitle fades in under the countdown eye.
    ▸ Blocking eye has pulsing glow, slow iris rotation via tween.
--]]

local Norm = {
    active        = false,
    conn          = nil,
    cycleTimer    = 0,
    cycleInterval = 0,   -- set randomly between 10–25 each cycle
    inCountdown   = false,
    countdownNum  = 5,
    countdownTimer = 0,
    blockingActive = false,
    blockPart      = nil,
    blockTimer     = 0,
    BLOCK_DUR      = 5,
    blockVelX      = 0,
    blockVelZ      = 0,
    dmgCooldown    = false,
    dmgCDTimer     = 0,
    DMG_CD         = 2,
}

-- ── SCREEN SHAKING EYE (ScreenGui) ─────────────────────────
local NormEyeFrame = Instance.new("Frame")
NormEyeFrame.Name                   = "NormEyeFrame"
NormEyeFrame.Size                   = UDim2.new(0, 140, 0, 140)
NormEyeFrame.AnchorPoint            = Vector2.new(0.5, 0.5)
NormEyeFrame.Position               = UDim2.new(0.5, 0, 0.5, 0)
NormEyeFrame.BackgroundTransparency = 1
NormEyeFrame.Visible                = false
NormEyeFrame.ZIndex                 = 30
NormEyeFrame.Parent                 = ScreenGui  -- assigned later

-- Outer eye white
local NormEyeWhite = Instance.new("Frame")
NormEyeWhite.Name             = "EyeWhite"
NormEyeWhite.Size             = UDim2.new(1, 0, 0.6, 0)
NormEyeWhite.AnchorPoint      = Vector2.new(0.5, 0.5)
NormEyeWhite.Position         = UDim2.new(0.5, 0, 0.5, 0)
NormEyeWhite.BackgroundColor3 = Color3.fromRGB(245, 240, 235)
NormEyeWhite.BorderSizePixel  = 0
NormEyeWhite.ZIndex           = 31
NormEyeWhite.Parent           = NormEyeFrame
Instance.new("UICorner", NormEyeWhite).CornerRadius = UDim.new(1, 0)

-- Iris
local NormIris = Instance.new("Frame")
NormIris.Name             = "Iris"
NormIris.Size             = UDim2.new(0.48, 0, 0.48, 0)
NormIris.AnchorPoint      = Vector2.new(0.5, 0.5)
NormIris.Position         = UDim2.new(0.5, 0, 0.5, 0)
NormIris.BackgroundColor3 = Color3.fromRGB(140, 80, 20)
NormIris.BorderSizePixel  = 0
NormIris.ZIndex           = 32
NormIris.Parent           = NormEyeFrame
Instance.new("UICorner", NormIris).CornerRadius = UDim.new(1, 0)

-- Pupil (countdown number inside)
local NormPupil = Instance.new("Frame")
NormPupil.Name             = "Pupil"
NormPupil.Size             = UDim2.new(0.55, 0, 0.55, 0)
NormPupil.AnchorPoint      = Vector2.new(0.5, 0.5)
NormPupil.Position         = UDim2.new(0.5, 0, 0.5, 0)
NormPupil.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
NormPupil.BorderSizePixel  = 0
NormPupil.ZIndex           = 33
NormPupil.Parent           = NormIris
Instance.new("UICorner", NormPupil).CornerRadius = UDim.new(1, 0)

local NormCountLabel = Instance.new("TextLabel")
NormCountLabel.Size                   = UDim2.new(1, 0, 1, 0)
NormCountLabel.BackgroundTransparency = 1
NormCountLabel.Text                   = "5"
NormCountLabel.Font                   = Enum.Font.GothamBold
NormCountLabel.TextSize               = 36
NormCountLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
NormCountLabel.ZIndex                 = 34
NormCountLabel.Parent                 = NormPupil

-- Subtitle
local NormSubLabel = Instance.new("TextLabel")
NormSubLabel.Name                   = "NormSub"
NormSubLabel.Size                   = UDim2.new(0, 220, 0, 22)
NormSubLabel.AnchorPoint            = Vector2.new(0.5, 0)
NormSubLabel.Position               = UDim2.new(0.5, 0, 1, 10)
NormSubLabel.BackgroundTransparency = 1
NormSubLabel.Text                   = "Feels great isn't it?"
NormSubLabel.Font                   = Enum.Font.Gotham
NormSubLabel.TextSize               = 14
NormSubLabel.TextColor3             = Color3.fromRGB(200, 180, 140)
NormSubLabel.TextTransparency       = 1
NormSubLabel.ZIndex                 = 34
NormSubLabel.Parent                 = NormEyeFrame

-- ── BUILD 3D BLOCKING HAPPY EYE ────────────────────────────
local function BuildBlockingEye()
    local part = Instance.new("Part")
    part.Name        = "NormBlockingEye"
    part.Size        = Vector3.new(1, 1, 1)
    part.Anchored    = true
    part.CanCollide  = false
    part.CastShadow  = false
    part.Transparency = 1
    part.Parent      = Workspace

    local bb = Instance.new("BillboardGui")
    bb.Name         = "NormBlockBB"
    bb.Size         = UDim2.new(0, 260, 0, 180)
    bb.AlwaysOnTop  = false
    bb.Adornee      = part
    bb.Parent       = part

    -- Eye white (oval, wider than tall)
    local eWhite = Instance.new("Frame")
    eWhite.Size             = UDim2.new(1, 0, 0.55, 0)
    eWhite.AnchorPoint      = Vector2.new(0.5, 0.5)
    eWhite.Position         = UDim2.new(0.5, 0, 0.58, 0)
    eWhite.BackgroundColor3 = Color3.fromRGB(248, 244, 240)
    eWhite.BorderSizePixel  = 0
    eWhite.Parent           = bb
    Instance.new("UICorner", eWhite).CornerRadius = UDim.new(1, 0)

    -- Happy eyelid (top lid lifted = flat or slightly curved line above)
    -- We simulate by clipping the top with a darker curved frame
    local topLid = Instance.new("Frame")
    topLid.Size             = UDim2.new(1.08, 0, 0.38, 0)
    topLid.AnchorPoint      = Vector2.new(0.5, 1)
    topLid.Position         = UDim2.new(0.5, 0, 0.32, 0)
    topLid.BackgroundColor3 = Color3.fromRGB(18, 10, 18)
    topLid.BorderSizePixel  = 0
    topLid.ZIndex           = 2
    topLid.Parent           = bb
    Instance.new("UICorner", topLid).CornerRadius = UDim.new(0.5, 0)

    -- Bottom lid (slightly curved, happy squint)
    local botLid = Instance.new("Frame")
    botLid.Size             = UDim2.new(1.08, 0, 0.38, 0)
    botLid.AnchorPoint      = Vector2.new(0.5, 0)
    botLid.Position         = UDim2.new(0.5, 0, 0.75, 0)
    botLid.BackgroundColor3 = Color3.fromRGB(18, 10, 18)
    botLid.BorderSizePixel  = 0
    botLid.ZIndex           = 2
    botLid.Parent           = bb
    Instance.new("UICorner", botLid).CornerRadius = UDim.new(0.5, 0)

    -- Iris
    local iris = Instance.new("Frame")
    iris.Size             = UDim2.new(0.34, 0, 0.50, 0)
    iris.AnchorPoint      = Vector2.new(0.5, 0.5)
    iris.Position         = UDim2.new(0.5, 0, 0.58, 0)
    iris.BackgroundColor3 = Color3.fromRGB(160, 100, 30)
    iris.BorderSizePixel  = 0
    iris.ZIndex           = 3
    iris.Parent           = bb
    Instance.new("UICorner", iris).CornerRadius = UDim.new(1, 0)

    -- Pupil
    local pupil = Instance.new("Frame")
    pupil.Size             = UDim2.new(0.55, 0, 0.55, 0)
    pupil.AnchorPoint      = Vector2.new(0.5, 0.5)
    pupil.Position         = UDim2.new(0.5, 0, 0.5, 0)
    pupil.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
    pupil.BorderSizePixel  = 0
    pupil.ZIndex           = 4
    pupil.Parent           = iris
    Instance.new("UICorner", pupil).CornerRadius = UDim.new(1, 0)

    -- Highlight glint
    local glint = Instance.new("Frame")
    glint.Size             = UDim2.new(0.28, 0, 0.28, 0)
    glint.AnchorPoint      = Vector2.new(0, 0)
    glint.Position         = UDim2.new(0.15, 0, 0.1, 0)
    glint.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glint.BackgroundTransparency = 0.2
    glint.BorderSizePixel  = 0
    glint.ZIndex           = 5
    glint.Parent           = pupil
    Instance.new("UICorner", glint).CornerRadius = UDim.new(1, 0)

    -- Iris slow pulse
    TweenService:Create(iris,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundColor3 = Color3.fromRGB(200, 140, 50)}
    ):Play()

    return part, bb
end

local NORM_APPEAR_DIALOGUES = {
    "Jork it crazy style",
    "You know you want it right?",
    "Come here~",
    "Repent to god but you have to jork it",
}
local NORM_TOUCH_DIALOGUES = {
    "Good boy",
    "Do you feel that?",
    "Like the pleasure?",
    "Do it harder",
}

local NormDialogLabel = Instance.new("TextLabel")
NormDialogLabel.Name                   = "NormDialog"
NormDialogLabel.Size                   = UDim2.new(0, 300, 0, 26)
NormDialogLabel.AnchorPoint            = Vector2.new(0.5, 1)
NormDialogLabel.Position               = UDim2.new(0.5, 0, 1, -50)
NormDialogLabel.BackgroundTransparency = 1
NormDialogLabel.Text                   = ""
NormDialogLabel.Font                   = Enum.Font.GothamBold
NormDialogLabel.TextSize               = 15
NormDialogLabel.TextColor3             = Color3.fromRGB(220, 180, 120)
NormDialogLabel.TextTransparency       = 1
NormDialogLabel.ZIndex                 = 35
NormDialogLabel.Parent                 = ScreenGui

local function NormSayDialog(lines)
    local line = lines[math.random(1, #lines)]
    NormDialogLabel.Text = '"' .. line .. '"'
    TweenService:Create(NormDialogLabel, TweenInfo.new(0.25), {TextTransparency=0}):Play()
    task.delay(3, function()
        TweenService:Create(NormDialogLabel, TweenInfo.new(0.8), {TextTransparency=1}):Play()
    end)
end

local function OnNormEnable()
    Norm.active        = true
    Norm.cycleTimer    = 0
    Norm.cycleInterval = 10 + math.random() * 15
    Norm.inCountdown   = false
    Norm.blockingActive = false
    Norm.dmgCooldown   = false
    Norm.dmgCDTimer    = 0

    local shakeX, shakeY = 0, 0
    local shakeIntensity = 0

    Norm.conn = RunService.Heartbeat:Connect(function(dt)
        if not Norm.active then return end
        local hrp = HumanoidRootPart; if not hrp then return end

        -- ── DAMAGE COOLDOWN ──
        if Norm.dmgCooldown then
            Norm.dmgCDTimer = Norm.dmgCDTimer - dt
            if Norm.dmgCDTimer <= 0 then Norm.dmgCooldown = false end
        end

        -- ── CYCLE TIMER ──────────────────────────────────────
        if not Norm.inCountdown and not Norm.blockingActive then
            Norm.cycleTimer = Norm.cycleTimer + dt
            if Norm.cycleTimer >= Norm.cycleInterval then
                Norm.cycleTimer    = 0
                Norm.cycleInterval = 10 + math.random() * 15
                -- Start countdown
                Norm.inCountdown   = true
                Norm.countdownNum  = 5
                Norm.countdownTimer = 0
                NormEyeFrame.Visible = true
                NormCountLabel.Text  = "5"
                TweenService:Create(NormSubLabel, TweenInfo.new(0.5), {TextTransparency=0}):Play()
                NormSayDialog(NORM_APPEAR_DIALOGUES)
            end
        end

        -- ── COUNTDOWN PHASE ──────────────────────────────────
        if Norm.inCountdown then
            Norm.countdownTimer = Norm.countdownTimer + dt

            -- Shake intensity increases as count drops
            shakeIntensity = (6 - Norm.countdownNum) * 3.5 + 2

            -- Apply shake to frame position
            shakeX = shakeX * 0.7 + (math.random()-0.5) * shakeIntensity * 2
            shakeY = shakeY * 0.7 + (math.random()-0.5) * shakeIntensity * 2
            NormEyeFrame.Position = UDim2.new(0.5, math.floor(shakeX), 0.5, math.floor(shakeY))

            -- Advance countdown every 1s
            if Norm.countdownTimer >= 1 then
                Norm.countdownTimer = 0
                Norm.countdownNum   = Norm.countdownNum - 1

                if Norm.countdownNum <= 0 then
                    -- Countdown done — hide screen eye, spawn blocking eye
                    Norm.inCountdown   = false
                    NormEyeFrame.Visible = false
                    NormEyeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                    TweenService:Create(NormSubLabel, TweenInfo.new(0.3), {TextTransparency=1}):Play()

                    -- Spawn blocking eye 8 studs in front of player
                    local spawnPos = hrp.Position + hrp.CFrame.LookVector * 8 + Vector3.new(0, 1.5, 0)
                    local bPart, _ = BuildBlockingEye()
                    bPart.CFrame   = CFrame.new(spawnPos)
                    Norm.blockPart  = bPart
                    Norm.blockTimer = 0
                    Norm.blockingActive = true
                    Norm.blockVelX  = 0
                    Norm.blockVelZ  = 0
                else
                    NormCountLabel.Text = tostring(Norm.countdownNum)
                    -- Flash the pupil on each tick
                    TweenService:Create(NormPupil,
                        TweenInfo.new(0.08),
                        {BackgroundColor3 = Color3.fromRGB(60, 0, 0)}
                    ):Play()
                    task.delay(0.12, function()
                        TweenService:Create(NormPupil,
                            TweenInfo.new(0.1),
                            {BackgroundColor3 = Color3.fromRGB(5, 5, 5)}
                        ):Play()
                    end)
                end
            end
        end

        -- ── BLOCKING EYE PHASE ───────────────────────────────
        if Norm.blockingActive and Norm.blockPart and Norm.blockPart.Parent then
            Norm.blockTimer = Norm.blockTimer + dt

            if Norm.blockTimer >= Norm.BLOCK_DUR then
                -- Expire
                Norm.blockPart:Destroy(); Norm.blockPart = nil
                Norm.blockingActive = false
            else
                -- Smooth spring follow — always tries to stay 6 studs in front of player
                local targetPos = hrp.Position + hrp.CFrame.LookVector * 6 + Vector3.new(0, 1.5, 0)
                local curPos    = Norm.blockPart.Position
                local diff      = targetPos - curPos

                -- Spring toward target (slow, smooth delay feel)
                local SPRING = 3.5
                local DAMP   = 0.55
                Norm.blockVelX = Norm.blockVelX * (1 - DAMP) + diff.X * SPRING * dt
                Norm.blockVelZ = Norm.blockVelZ * (1 - DAMP) + diff.Z * SPRING * dt

                local newPos = Vector3.new(
                    curPos.X + Norm.blockVelX * dt,
                    targetPos.Y,  -- snap Y directly so it stays at eye level
                    curPos.Z + Norm.blockVelZ * dt
                )
                Norm.blockPart.CFrame = CFrame.new(newPos)

                -- Touch check
                if not Norm.dmgCooldown then
                    local dist = (newPos - hrp.Position).Magnitude
                    if dist < 3.5 then
                        Norm.dmgCooldown = true
                        Norm.dmgCDTimer  = Norm.DMG_CD
                        TagDeathCause("Norm")
                        InstantFateDamage(50)
                        NormSayDialog(NORM_TOUCH_DIALOGUES)

                        -- Flash
                        TweenService:Create(NormEyeWhite,
                            TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}
                        ):Play()
                        task.delay(0.2, function()
                            pcall(function()
                                TweenService:Create(NormEyeWhite,
                                    TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(245,240,235)}
                                ):Play()
                            end)
                        end)
                    end
                end
            end
        end
    end)
end

local function OnNormDisable()
    Norm.active = false
    if Norm.conn then Norm.conn:Disconnect(); Norm.conn = nil end
    NormEyeFrame.Visible = false
    if Norm.blockPart then Norm.blockPart:Destroy(); Norm.blockPart = nil end
    Norm.inCountdown    = false
    Norm.blockingActive = false
    TweenService:Create(NormSubLabel,   TweenInfo.new(0.3), {TextTransparency=1}):Play()
    TweenService:Create(NormDialogLabel, TweenInfo.new(0.3), {TextTransparency=1}):Play()
end

-- Assign NormEyeFrame to the ScreenGui (created before ScreenGui in code order)
NormEyeFrame.Parent = ScreenGui

RegisterEntity("Norm","Lust",
    "Feels great isn't it? The warmth. The silence. No one else. Just you and what you want.",
    OnNormEnable, OnNormDisable)

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
        if not lastDeathCause then
            if FateData.drainRates["Gaze"] and FateData.drainRates["Gaze"] > 0 then
                TagDeathCause("Gaze")
            end
        end
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
LocalPlayer.CharacterAdded:Connect(function(newChar)
    FateData.dead    = false
    FateData.current = 100
    TweenService:Create(DeathScreen, TweenInfo.new(0.8), {BackgroundTransparency=1}):Play()
    TweenService:Create(DeathLabel,  TweenInfo.new(0.4), {TextTransparency=1}):Play()
    task.delay(1, function() DeathScreen.Visible = false end)
    -- Clear stale snapshot from previous life
    if pendingCorpse then
        pcall(function() pendingCorpse:Destroy() end)
        pendingCorpse = nil
    end
    lastDeathCause = nil
    -- Pass newChar directly so we never depend on global Character order
    task.delay(0.3, function()
        ConnectDeathEffect(newChar)
    end)
    -- Piece: reset and restart if it killed the player
    if Piece.pendingReset then PieceHardReset() end
    -- Delictum: save last life's recording, spawn a shadow after 2s
    if Delictum.active then DelictumOnDeath() end
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
IntroLabel.Text = "FATE"; IntroLabel.Font = Enum.Font.GothamBold; IntroLabel.TextSize = 52
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
print("╔══════════════════════════════════════════════════════╗")
print("║         GRACE Fanmade v10 — Loaded                  ║")
print("║  GAZE / ELUDE / NUMB / MOUTHFEED  active            ║")
print("║  PIECE / DELICTUM / NORM          active            ║")
print("║  DEATH EFFECTS  — avatar corpse per entity          ║")
print("║  FIX: TagDeathCause snapshots avatar BEFORE kill    ║")
print("║  FIX: pendingCorpse cleared on CharacterAdded       ║")
print("╚══════════════════════════════════════════════════════╝")
