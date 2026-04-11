-- ============================================================
-- THE CAVES - LocalScript Executor
-- Devious Goober  |  Starts at Door 230  |  Stage 2
-- Entities : Disease, Her, Void
-- Items    : Coins, Ecstasy, Drill, Hammer, Miner Helmet
-- Hiding   : Empty Minecarts (hollow, 9 parts)
-- Search   : Lockers (3-5x) + Filled Minecarts (1x, no LOS)
-- Doors    : Both entry AND exit walls have arch holes
-- Barricades: 30% nailed (Drill->Hammer), 70% just Hammer
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== CONSTANTS =====
local CAVE_W           = 35
local CAVE_H           = 22
local CAVE_D           = 60
local DOOR_START       = 230
local DOOR_MAX         = 1000
local CHECKPOINT_EVERY = 50
local DOOR_GAP_W       = 7
local DOOR_GAP_H       = 9

local DISEASE_SPEED    = 70
local DISEASE_COOLDOWN = 12
local DISEASE_BEFORE   = 4
local DISEASE_AFTER    = 4

local HER_START        = 235
local HER_COOLDOWN     = 90
local HER_SPEED        = 28

local VOID_START       = 250
local VOID_CHANCE      = 18
local VOID_COOLDOWN    = 35

local CART_DIST        = 5
local GEN_AHEAD        = 6
local CLEAN_BEHIND     = 7
local MAX_ITEMS        = 3

-- ===== STATE =====
local character        = nil
local humanoid         = nil
local rootPart         = nil
local currentDoor      = DOOR_START
local lastDetectedDoor = DOOR_START
local gameStarted      = false
local isHiding         = false
local nearCart         = false
local currentCart      = nil
local checkpointDoor   = DOOR_START
local rooms            = {}
local roomIsDark       = {}
local diseaseActive    = false
local diseaseOnCooldown = false
local herActive        = false
local herOnCooldown    = false
local voidActive       = false
local voidOnCooldown   = false
local isDead           = false
local hiddenParts      = {}
local inventory        = {}
local coins            = 0
local ecstasyActive    = false
local ecstasyEndTime   = 0
local speedPenaltyEnd  = 0
local helmetEquipped   = false
local helmetLight      = nil
local lastStepTime     = 0
local floorStepSound   = nil

-- ===== FORWARD DECLARATIONS =====
local setupLighting, createHUD, makePart, makeLight
local makeCrate, makeBarrel, makeRockPile, makeStalactite
local makeMinecart, makeLocker, spawnSpikyRock, buildArchWall
local generateRoom, createLobby, startGame, showWarning
local hideInCart, exitCart, giveTool, giveHelmet
local spawnDisease, spawnHer, spawnVoid
local onDoorReached, onDeath, updateCharRef, mainLoop

-- ===== GUI REFS =====
local screenGui, doorLabel, coinLabel, warningFrame, warningLabel
local hidePrompt, hideBtnLabel

-- =================================================================
-- LIGHTING
-- =================================================================
setupLighting = function()
    local L = game:GetService("Lighting")
    L.Brightness = 0.05; L.ClockTime = 0
    L.FogColor = Color3.fromRGB(0,0,0); L.FogEnd = 45; L.FogStart = 5
    L.GlobalShadows = true
    L.Ambient = Color3.fromRGB(6,5,8)
    L.OutdoorAmbient = Color3.fromRGB(4,4,6)
end

-- =================================================================
-- HUD
-- =================================================================
createHUD = function()
    if player.PlayerGui:FindFirstChild("CaveHUD") then
        player.PlayerGui.CaveHUD:Destroy()
    end
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CaveHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player.PlayerGui

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(0,210,0,48)
    topBar.Position = UDim2.new(0.5,-105,0,12)
    topBar.BackgroundColor3 = Color3.fromRGB(10,8,14)
    topBar.BackgroundTransparency = 0.35
    topBar.BorderSizePixel = 0
    topBar.Parent = screenGui
    local tbC = Instance.new("UICorner"); tbC.CornerRadius = UDim.new(0,10); tbC.Parent = topBar
    local tbS = Instance.new("UIStroke"); tbS.Color = Color3.fromRGB(60,45,80); tbS.Thickness = 1.5; tbS.Parent = topBar

    doorLabel = Instance.new("TextLabel")
    doorLabel.Size = UDim2.new(1,0,1,0)
    doorLabel.BackgroundTransparency = 1
    doorLabel.Text = "Cave Door: " .. tostring(DOOR_START)
    doorLabel.TextColor3 = Color3.fromRGB(210,190,255)
    doorLabel.TextScaled = true
    doorLabel.Font = Enum.Font.GothamBold
    doorLabel.Parent = topBar

    local coinBar = Instance.new("Frame")
    coinBar.Size = UDim2.new(0,150,0,42)
    coinBar.Position = UDim2.new(0,14,0,12)
    coinBar.BackgroundColor3 = Color3.fromRGB(10,8,14)
    coinBar.BackgroundTransparency = 0.35
    coinBar.BorderSizePixel = 0
    coinBar.Parent = screenGui
    local cbC = Instance.new("UICorner"); cbC.CornerRadius = UDim.new(0,10); cbC.Parent = coinBar
    local cbS = Instance.new("UIStroke"); cbS.Color = Color3.fromRGB(60,45,80); cbS.Thickness = 1.5; cbS.Parent = coinBar

    local coinDot = Instance.new("Frame")
    coinDot.Size = UDim2.new(0,20,0,20)
    coinDot.Position = UDim2.new(0,8,0.5,-10)
    coinDot.BackgroundColor3 = Color3.fromRGB(255,210,0)
    coinDot.BorderSizePixel = 0; coinDot.ZIndex = 2; coinDot.Parent = coinBar
    local cdC = Instance.new("UICorner"); cdC.CornerRadius = UDim.new(1,0); cdC.Parent = coinDot

    coinLabel = Instance.new("TextLabel")
    coinLabel.Size = UDim2.new(1,-36,1,0)
    coinLabel.Position = UDim2.new(0,34,0,0)
    coinLabel.BackgroundTransparency = 1
    coinLabel.Text = "0 Coins"
    coinLabel.TextColor3 = Color3.fromRGB(255,220,60)
    coinLabel.TextScaled = true
    coinLabel.Font = Enum.Font.GothamBold
    coinLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinLabel.Parent = coinBar

    warningFrame = Instance.new("Frame")
    warningFrame.Name = "WarningFrame"
    warningFrame.Size = UDim2.new(1,0,0,70)
    warningFrame.Position = UDim2.new(0,0,0.13,0)
    warningFrame.BackgroundColor3 = Color3.fromRGB(18,10,28)
    warningFrame.BackgroundTransparency = 0.2
    warningFrame.BorderSizePixel = 0
    warningFrame.Visible = false
    warningFrame.Parent = screenGui

    warningLabel = Instance.new("TextLabel")
    warningLabel.Size = UDim2.new(1,-24,1,0)
    warningLabel.Position = UDim2.new(0,12,0,0)
    warningLabel.BackgroundTransparency = 1
    warningLabel.Text = ""
    warningLabel.TextColor3 = Color3.fromRGB(200,160,255)
    warningLabel.TextScaled = true
    warningLabel.Font = Enum.Font.GothamBold
    warningLabel.TextWrapped = true
    warningLabel.Parent = warningFrame

    hidePrompt = Instance.new("Frame")
    hidePrompt.Name = "HidePrompt"
    hidePrompt.Size = UDim2.new(0,260,0,62)
    hidePrompt.Position = UDim2.new(0.5,-130,0.82,0)
    hidePrompt.BackgroundColor3 = Color3.fromRGB(10,8,14)
    hidePrompt.BackgroundTransparency = 0.28
    hidePrompt.BorderSizePixel = 0
    hidePrompt.Visible = false
    hidePrompt.Parent = screenGui
    local hpC = Instance.new("UICorner"); hpC.CornerRadius = UDim.new(0,12); hpC.Parent = hidePrompt
    local hpS = Instance.new("UIStroke"); hpS.Color = Color3.fromRGB(80,60,110); hpS.Thickness = 1.5; hpS.Parent = hidePrompt

    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(1,0,1,0)
    hideBtn.BackgroundTransparency = 1
    hideBtn.TextColor3 = Color3.fromRGB(255,240,80)
    hideBtn.TextScaled = true
    hideBtn.Font = Enum.Font.GothamBold
    hideBtn.Text = "[HIDE IN CART]"
    hideBtn.Parent = hidePrompt
    hideBtnLabel = hideBtn
    hideBtn.MouseButton1Click:Connect(function()
        if not isHiding then hideInCart() else exitCart() end
    end)
end

-- =================================================================
-- PART HELPERS
-- =================================================================
makePart = function(size, cf, color, transparency, parent, material)
    local p = Instance.new("Part")
    p.Size = size; p.CFrame = cf
    p.Color = color or Color3.fromRGB(40,38,45)
    p.Transparency = transparency or 0
    p.Anchored = true; p.CanCollide = true; p.CastShadow = false
    p.Material = material or Enum.Material.SmoothPlastic
    p.Parent = parent or workspace
    return p
end

makeLight = function(parent, brightness, range, color)
    local l = Instance.new("PointLight")
    l.Brightness = brightness or 1.5
    l.Range = range or 22
    l.Color = color or Color3.fromRGB(255,200,120)
    l.Parent = parent
    return l
end

-- =================================================================
-- TOOL HELPER
-- =================================================================
giveTool = function(plr, toolName, color, size)
    local tool = Instance.new("Tool"); tool.Name = toolName
    local handle = Instance.new("Part"); handle.Name = "Handle"
    handle.Size = size or Vector3.new(0.8,0.5,0.5)
    handle.Color = color or Color3.fromRGB(180,180,180)
    handle.Material = Enum.Material.Metal; handle.Parent = tool
    tool.Parent = plr.Backpack
    return tool
end

-- =================================================================
-- MINER HELMET ITEM
-- =================================================================
giveHelmet = function(plr)
    if #inventory >= MAX_ITEMS then
        showWarning("Inventory full! Max " .. MAX_ITEMS .. " items.", 2); return
    end
    if helmetEquipped then
        showWarning("Helmet already equipped!", 2); return
    end
    table.insert(inventory, "MinerHelmet")
    local tool = Instance.new("Tool"); tool.Name = "MinerHelmet"
    tool.ToolTip = "Activate to wear - produces light!"
    local handle = Instance.new("Part"); handle.Name = "Handle"
    handle.Size = Vector3.new(1.4,1,1.4)
    handle.Color = Color3.fromRGB(38,80,120)
    handle.Material = Enum.Material.Metal; handle.Parent = tool

    local visor = Instance.new("Part"); visor.Name = "Visor"
    visor.Size = Vector3.new(1.3,0.35,0.2)
    visor.Color = Color3.fromRGB(200,220,255); visor.Material = Enum.Material.Neon
    visor.Transparency = 0.3; visor.CanCollide = false; visor.Anchored = false
    local vw = Instance.new("Weld"); vw.Part0 = handle; vw.Part1 = visor
    vw.C1 = CFrame.new(0,-0.2,-0.65); vw.Parent = handle; visor.Parent = tool

    local lamp = Instance.new("Part"); lamp.Name = "HelmLamp"
    lamp.Size = Vector3.new(0.4,0.35,0.4)
    lamp.Color = Color3.fromRGB(255,245,180); lamp.Material = Enum.Material.Neon
    lamp.CanCollide = false; lamp.Anchored = false
    local lw = Instance.new("Weld"); lw.Part0 = handle; lw.Part1 = lamp
    lw.C1 = CFrame.new(0,-0.42,-0.55); lw.Parent = handle; lamp.Parent = tool
    tool.Parent = plr.Backpack

    tool.Activated:Connect(function()
        if helmetEquipped then showWarning("Helmet already equipped!", 1.5); return end
        for idx, v in ipairs(inventory) do
            if v == "MinerHelmet" then table.remove(inventory, idx); break end
        end
        tool:Destroy(); helmetEquipped = true
        local char = player.Character; if not char then return end
        local head = char:FindFirstChild("Head"); if not head then return end

        local hatPart = Instance.new("Part"); hatPart.Name = "MinerHat"
        hatPart.Size = Vector3.new(1.6,1.1,1.6)
        hatPart.Color = Color3.fromRGB(38,80,120); hatPart.Material = Enum.Material.Metal
        hatPart.CanCollide = false; hatPart.Anchored = false; hatPart.Parent = char
        local hw = Instance.new("Weld"); hw.Part0 = head; hw.Part1 = hatPart
        hw.C0 = CFrame.new(0,0.7,0); hw.Parent = hatPart

        local brim = Instance.new("Part"); brim.Name = "HatBrim"
        brim.Size = Vector3.new(2,0.15,2); brim.Color = Color3.fromRGB(28,62,96)
        brim.Material = Enum.Material.Metal; brim.CanCollide = false; brim.Anchored = false; brim.Parent = char
        local bw = Instance.new("Weld"); bw.Part0 = hatPart; bw.Part1 = brim
        bw.C0 = CFrame.new(0,-0.45,0); bw.Parent = brim

        local hatLamp = Instance.new("Part"); hatLamp.Name = "HatLamp"
        hatLamp.Size = Vector3.new(0.45,0.4,0.45)
        hatLamp.Color = Color3.fromRGB(255,245,180); hatLamp.Material = Enum.Material.Neon
        hatLamp.CanCollide = false; hatLamp.Anchored = false; hatLamp.Parent = char
        local lw2 = Instance.new("Weld"); lw2.Part0 = hatPart; lw2.Part1 = hatLamp
        lw2.C0 = CFrame.new(0,0.2,-0.65); lw2.Parent = hatLamp

        helmetLight = Instance.new("PointLight")
        helmetLight.Brightness = 2.5; helmetLight.Range = 38
        helmetLight.Color = Color3.fromRGB(255,240,160); helmetLight.Parent = hatLamp
        showWarning("Miner Helmet equipped! You glow in the dark.", 3)
    end)
end

-- =================================================================
-- DECORATIONS
-- =================================================================
makeCrate = function(folder, pos)
    local body = makePart(Vector3.new(2.5,2.5,2.5),CFrame.new(pos+Vector3.new(0,1.25,0)),Color3.fromRGB(80,58,32),0,folder,Enum.Material.Wood)
    body.Name = "Crate"
    for i = 1,2 do
        local pl = makePart(Vector3.new(2.6,0.18,2.6),CFrame.new(pos+Vector3.new(0,0.6+i*0.9,0)),Color3.fromRGB(60,42,22),0,folder,Enum.Material.Wood)
        pl.Name = "CratePlank"; pl.CanCollide = false
    end
end

makeBarrel = function(folder, pos)
    local body = makePart(Vector3.new(1.8,2.8,1.8),CFrame.new(pos+Vector3.new(0,1.4,0)),Color3.fromRGB(90,62,30),0,folder,Enum.Material.Wood)
    body.Name = "Barrel"; body.Shape = Enum.PartType.Cylinder
    for yi = 1,2 do
        local ring = makePart(Vector3.new(2,0.2,2),CFrame.new(pos+Vector3.new(0,0.8+yi*0.8,0)),Color3.fromRGB(50,45,40),0,folder,Enum.Material.Metal)
        ring.Name = "BarrelRing"; ring.CanCollide = false
    end
end

makeRockPile = function(folder, pos)
    for i = 1, math.random(3,6) do
        local s = math.random(6,14)*0.1
        local rock = makePart(
            Vector3.new(s,s*0.65,s),
            CFrame.new(pos+Vector3.new(math.random(-4,4)*0.2,math.random(2,5)*0.2,math.random(-4,4)*0.2))*
            CFrame.Angles(math.rad(math.random(0,30)),math.rad(math.random(0,360)),math.rad(math.random(0,20))),
            Color3.fromRGB(55,52,50),0,folder,Enum.Material.Slate
        )
        rock.Name = "RockPile"; rock.CanCollide = false
    end
end

makeStalactite = function(folder, ceilY, x, z)
    local len = math.random(20,55)*0.1; local wid = math.random(4,10)*0.1
    local sp = makePart(
        Vector3.new(wid,len,wid),
        CFrame.new(x,ceilY-len*0.5,z)*CFrame.Angles(math.rad(math.random(-8,8)),0,math.rad(math.random(-8,8))),
        Color3.fromRGB(50,48,46),0,folder,Enum.Material.Slate
    )
    sp.Name = "Stalactite"; sp.CanCollide = false
end

spawnSpikyRock = function(folder, pos)
    local h = math.random(4,9)
    local spike = makePart(
        Vector3.new(math.random(15,30)*0.1,h,math.random(15,30)*0.1),
        CFrame.new(pos+Vector3.new(0,h*0.5,0))*CFrame.Angles(math.rad(math.random(-12,12)),math.rad(math.random(0,360)),math.rad(math.random(-12,12))),
        Color3.fromRGB(30,28,28),0,folder,Enum.Material.Slate
    )
    spike.Name = "SpikyRock"
    local db = false
    spike.Touched:Connect(function(hit)
        if hit.Parent == character and not db and not isHiding then
            db = true
            if humanoid and humanoid.Health > 0 then
                humanoid:TakeDamage(5); showWarning("Ouch! Spiky rock!", 1.2)
            end
            task.wait(1.5); db = false
        end
    end)
end

-- =================================================================
-- MINECART  (hollow with 4 walls + floor + 4 wheels)
--   "hide"   = empty hollow (9 parts) -> IsLocker for hiding
--   "filled" = cart + dirt (10 parts) -> 1x search, no LOS req
--   "deco"   = decoration only
-- =================================================================
makeMinecart = function(folder, pos, cartType)
    local metalC = Color3.fromRGB(55,52,52)
    local darkC  = Color3.fromRGB(38,36,36)
    local wheelC = Color3.fromRGB(32,30,30)

    -- 1. Floor
    local floor = makePart(Vector3.new(4,0.3,7),CFrame.new(pos+Vector3.new(0,0.45,0)),darkC,0,folder,Enum.Material.Metal)
    floor.Name = "CartFloor"

    -- 2. Wall Left
    local wL = makePart(Vector3.new(0.3,2.2,7),CFrame.new(pos+Vector3.new(-2.15,1.55,0)),metalC,0,folder,Enum.Material.Metal)
    wL.Name = "CartWallL"

    -- 3. Wall Right
    local wR = makePart(Vector3.new(0.3,2.2,7),CFrame.new(pos+Vector3.new(2.15,1.55,0)),metalC,0,folder,Enum.Material.Metal)
    wR.Name = "CartWallR"

    -- 4. Wall Front
    local wF = makePart(Vector3.new(4,2.2,0.3),CFrame.new(pos+Vector3.new(0,1.55,-3.5)),metalC,0,folder,Enum.Material.Metal)
    wF.Name = "CartWallF"

    -- 5. Wall Back
    local wB = makePart(Vector3.new(4,2.2,0.3),CFrame.new(pos+Vector3.new(0,1.55,3.5)),metalC,0,folder,Enum.Material.Metal)
    wB.Name = "CartWallB"

    -- Wheels 6-9
    local wheelPos = {
        Vector3.new(-2.25,0.55,-2.2), Vector3.new(-2.25,0.55,2.2),
        Vector3.new(2.25,0.55,-2.2),  Vector3.new(2.25,0.55,2.2),
    }
    for _, wp in ipairs(wheelPos) do
        local whl = makePart(Vector3.new(0.45,1.1,1.1),CFrame.new(pos+wp),wheelC,0,folder,Enum.Material.Metal)
        whl.Name = "CartWheel"; whl.Shape = Enum.PartType.Cylinder
    end

    -- Rails below
    for xi = -1,1,2 do
        local rail = makePart(Vector3.new(0.3,0.25,CAVE_D*0.85),CFrame.new(pos+Vector3.new(xi*1.5,0.12,0)),Color3.fromRGB(70,68,65),0,folder,Enum.Material.Metal)
        rail.Name = "Rail"; rail.CanCollide = false
    end

    -- ---- FILLED CART: part 10 = dirt, searchable 1x through walls ----
    if cartType == "filled" then
        local dirt = makePart(Vector3.new(3.6,1.4,6.6),CFrame.new(pos+Vector3.new(0,1.3,0)),Color3.fromRGB(92,64,30),0,folder,Enum.Material.Mud)
        dirt.Name = "CartDirt"

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Search Cart"
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = CART_DIST + 2
        prompt.Parent = floor

        prompt.Triggered:Connect(function(plr)
            prompt:Destroy()
            if dirt and dirt.Parent then dirt.Transparency = 0.6 end

            local r = math.random(1,100); local loot
            if r <= 20 then loot = "Drill"
            elseif r <= 40 then loot = "Hammer"
            elseif r <= 55 then loot = "Ecstasy"
            elseif r <= 75 then loot = "Coin"
            else loot = "Nothing" end

            if loot == "Coin" then
                local amt = math.random(1,5); coins = coins + amt
                if coinLabel then coinLabel.Text = tostring(coins) .. " Coins" end
                showWarning("Cart: Found " .. tostring(amt) .. " Cave Coin(s)!", 2.5); return
            end
            if loot == "Nothing" then showWarning("Cart: Nothing but dirt inside.", 2); return end

            showWarning("Cart: Found " .. loot .. "!", 2)

            if loot == "Drill" then
                if #inventory >= MAX_ITEMS then showWarning("Inventory full!", 2); return end
                table.insert(inventory, "Drill")
                giveTool(plr, "Drill", Color3.fromRGB(50,50,160), Vector3.new(1.2,0.4,0.4))

            elseif loot == "Hammer" then
                if #inventory >= MAX_ITEMS then showWarning("Inventory full!", 2); return end
                table.insert(inventory, "Hammer")
                giveTool(plr, "Hammer", Color3.fromRGB(80,80,80), Vector3.new(0.5,1.4,0.5))

            elseif loot == "Ecstasy" then
                if #inventory >= MAX_ITEMS then showWarning("Inventory full!", 2); return end
                table.insert(inventory, "Ecstasy")
                local t = giveTool(plr, "Ecstasy", Color3.fromRGB(200,50,200), Vector3.new(0.5,0.5,0.5))
                t.Handle.Material = Enum.Material.Neon
                t.Activated:Connect(function()
                    t:Destroy()
                    for idx, v in ipairs(inventory) do if v=="Ecstasy" then table.remove(inventory,idx); break end end
                    ecstasyActive = true; ecstasyEndTime = tick()+180
                    if humanoid then humanoid.WalkSpeed = 22 end
                    local ccc = game.Lighting:FindFirstChild("EcstasyCC") or Instance.new("ColorCorrectionEffect",game.Lighting)
                    ccc.Name = "EcstasyCC"; ccc.Saturation = 1.5
                    showWarning("Ecstasy! Speed boost 3 minutes.", 3)
                end)
            end
        end)

    -- ---- EMPTY HIDE CART: IsLocker flag on floor so player can hide ----
    elseif cartType == "hide" then
        floor:SetAttribute("IsLocker", true)
        floor.Name = "CartHideFloor"
        -- Subtle glow rim so player knows this one is hideable
        local glow = makePart(Vector3.new(4,0.08,7),CFrame.new(pos+Vector3.new(0,2.66,0)),Color3.fromRGB(80,200,255),0.7,folder,Enum.Material.Neon)
        glow.Name = "CartRim"; glow.CanCollide = false
        makeLight(glow,0.5,8,Color3.fromRGB(80,200,255))
    end

    return floor
end

-- =================================================================
-- LOCKER  (cave metal locker, searchable 3-5 times)
--   Loot: Coin, Ecstasy, Drill, MinerHelmet, Nothing
-- =================================================================
makeLocker = function(folder, pos)
    local body = makePart(Vector3.new(2.5,6.5,2),CFrame.new(pos+Vector3.new(0,3.25,0)),Color3.fromRGB(50,72,100),0,folder,Enum.Material.Metal)
    body.Name = "LockerBody"
    makePart(Vector3.new(0.08,6.1,1.7),CFrame.new(pos+Vector3.new(-1.21,3.25,0)),Color3.fromRGB(40,60,88),0,folder,Enum.Material.Metal).Name="LockerDoorLine"
    makePart(Vector3.new(0.2,0.9,0.32),CFrame.new(pos+Vector3.new(-1.32,3.4,0.5)),Color3.fromRGB(200,175,95),0,folder).Name="LockerHandle"
    for vi = 1,3 do
        makePart(Vector3.new(1.8,0.14,0.08),CFrame.new(pos+Vector3.new(-0.3,5.5-vi*0.4,-1.01)),Color3.fromRGB(38,55,78),0,folder).Name="LockerVent"
    end

    local usesLeft = math.random(3,5)

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Search Locker"
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 6
    prompt.Parent = body

    prompt.Triggered:Connect(function(plr)
        if usesLeft <= 0 then showWarning("Locker is empty.", 1.5); return end
        usesLeft = usesLeft - 1

        local r = math.random(1,100); local loot
        if r <= 10 then loot = "MinerHelmet"
        elseif r <= 22 then loot = "Drill"
        elseif r <= 38 then loot = "Ecstasy"
        elseif r <= 62 then loot = "Coin"
        else loot = "Nothing" end

        if usesLeft == 0 then
            prompt:Destroy(); body.Color = Color3.fromRGB(30,40,55)
        end

        local leftStr = " (" .. usesLeft .. " left)"

        if loot == "Coin" then
            local amt = math.random(1,4); coins = coins + amt
            if coinLabel then coinLabel.Text = tostring(coins) .. " Coins" end
            showWarning("Locker: " .. tostring(amt) .. " coin(s)" .. leftStr, 2); return
        end
        if loot == "Nothing" then showWarning("Locker: Nothing here." .. leftStr, 2); return end
        if loot == "MinerHelmet" then
            showWarning("Locker: Miner Helmet!" .. leftStr, 2.5); giveHelmet(plr); return
        end
        if loot == "Drill" then
            if #inventory >= MAX_ITEMS then showWarning("Inventory full!", 2); return end
            table.insert(inventory,"Drill")
            giveTool(plr,"Drill",Color3.fromRGB(50,50,160),Vector3.new(1.2,0.4,0.4))
            showWarning("Locker: Drill found - removes nails!" .. leftStr, 2.5); return
        end
        if loot == "Ecstasy" then
            if #inventory >= MAX_ITEMS then showWarning("Inventory full!", 2); return end
            table.insert(inventory,"Ecstasy")
            local t = giveTool(plr,"Ecstasy",Color3.fromRGB(200,50,200),Vector3.new(0.5,0.5,0.5))
            t.Handle.Material = Enum.Material.Neon
            t.Activated:Connect(function()
                t:Destroy()
                for idx, v in ipairs(inventory) do if v=="Ecstasy" then table.remove(inventory,idx); break end end
                ecstasyActive = true; ecstasyEndTime = tick()+180
                if humanoid then humanoid.WalkSpeed = 22 end
                local ccc = game.Lighting:FindFirstChild("EcstasyCC") or Instance.new("ColorCorrectionEffect",game.Lighting)
                ccc.Name = "EcstasyCC"; ccc.Saturation = 1.5
                showWarning("Ecstasy! Speed boost 3 minutes.", 3)
            end)
            showWarning("Locker: Ecstasy!" .. leftStr, 2)
        end
    end)
    return body
end

-- =================================================================
-- BUILD ARCH WALL  (both entry and exit walls use this)
--   Creates side panels + top panel leaving a DOOR_GAP_W x DOOR_GAP_H
--   hole at ground level.  isSignWall=true adds the door number sign.
-- =================================================================
buildArchWall = function(folder, O, zOffset, roomW, roomH, wallColor, isSignWall, doorNum)
    local halfGap = DOOR_GAP_W * 0.5
    local sideW   = (roomW - DOOR_GAP_W) * 0.5
    local topH    = roomH - DOOR_GAP_H
    local suffix  = (zOffset < 0) and "Front" or "Back"

    -- Left panel
    makePart(
        Vector3.new(sideW,roomH,1),
        CFrame.new(O + Vector3.new(-(halfGap + sideW*0.5), roomH*0.5, zOffset)),
        wallColor, 0, folder, Enum.Material.Cobblestone
    ).Name = suffix .. "WallL"

    -- Right panel
    makePart(
        Vector3.new(sideW,roomH,1),
        CFrame.new(O + Vector3.new(halfGap + sideW*0.5, roomH*0.5, zOffset)),
        wallColor, 0, folder, Enum.Material.Cobblestone
    ).Name = suffix .. "WallR"

    -- Top panel (above the gap)
    makePart(
        Vector3.new(DOOR_GAP_W, topH, 1),
        CFrame.new(O + Vector3.new(0, roomH - topH*0.5, zOffset)),
        wallColor, 0, folder, Enum.Material.Cobblestone
    ).Name = suffix .. "WallTop"

    -- Left arch post (decorative stone trim)
    makePart(
        Vector3.new(0.9,DOOR_GAP_H,1.3),
        CFrame.new(O + Vector3.new(-halfGap - 0.45, DOOR_GAP_H*0.5, zOffset)),
        Color3.fromRGB(62,58,54), 0, folder, Enum.Material.Cobblestone
    ).Name = "ArchPost"

    -- Right arch post
    makePart(
        Vector3.new(0.9,DOOR_GAP_H,1.3),
        CFrame.new(O + Vector3.new(halfGap + 0.45, DOOR_GAP_H*0.5, zOffset)),
        Color3.fromRGB(62,58,54), 0, folder, Enum.Material.Cobblestone
    ).Name = "ArchPost"

    -- Lintel (horizontal stone across top of arch)
    makePart(
        Vector3.new(DOOR_GAP_W + 1.8, 0.9, 1.3),
        CFrame.new(O + Vector3.new(0, DOOR_GAP_H + 0.45, zOffset)),
        Color3.fromRGB(62,58,54), 0, folder, Enum.Material.Cobblestone
    ).Name = "ArchLintel"

    -- Door number sign above the arch (exit wall only)
    if isSignWall and doorNum then
        local faceDir = (zOffset < 0) and Enum.NormalId.Front or Enum.NormalId.Back
        local signZ   = zOffset + ((zOffset < 0) and 0.3 or -0.3)
        local signPart = makePart(
            Vector3.new(DOOR_GAP_W + 2, 1.6, 0.4),
            CFrame.new(O + Vector3.new(0, DOOR_GAP_H + 1.8, signZ)),
            Color3.fromRGB(28,26,24), 0, folder, Enum.Material.Slate
        )
        signPart.Name = "DoorSign"
        local sg = Instance.new("SurfaceGui"); sg.Face = faceDir; sg.Parent = signPart
        local sl = Instance.new("TextLabel"); sl.Size = UDim2.new(1,0,1,0)
        sl.BackgroundTransparency = 1; sl.Text = tostring(doorNum + 1)
        sl.TextColor3 = Color3.fromRGB(200,180,140); sl.TextScaled = true
        sl.Font = Enum.Font.GothamBold; sl.Parent = sg
    end
end

-- =================================================================
-- ROOM GENERATION
-- =================================================================
generateRoom = function(doorNum)
    if rooms[doorNum] then return end

    local folder = Instance.new("Folder")
    folder.Name  = "Room_" .. doorNum
    folder.Parent = workspace

    local originZ    = -(doorNum * CAVE_D)
    local O          = Vector3.new(0,0,originZ)
    local isDark     = math.random(1,100) <= 50
    local isBarricaded = math.random(1,100) <= 40
    local isNailed   = isBarricaded and (math.random(1,100) <= 30)

    roomIsDark[doorNum] = isDark

    local roomW  = CAVE_W; local roomH = CAVE_H; local roomD = CAVE_D
    local wallC  = Color3.fromRGB(45,43,40)
    local floorC = Color3.fromRGB(38,36,34)
    local ceilC  = Color3.fromRGB(33,31,30)

    -- Floor
    makePart(Vector3.new(roomW,1,roomD),CFrame.new(O+Vector3.new(0,-0.5,0)),floorC,0,folder,Enum.Material.Slate).Name="CaveFloor"
    -- Ceiling
    makePart(Vector3.new(roomW,1,roomD),CFrame.new(O+Vector3.new(0,roomH+0.5,0)),ceilC,0,folder,Enum.Material.Slate).Name="CaveCeiling"
    -- Side walls
    makePart(Vector3.new(1,roomH,roomD),CFrame.new(O+Vector3.new(-roomW*0.5-0.5,roomH*0.5,0)),wallC,0,folder,Enum.Material.Cobblestone).Name="CaveWallL"
    makePart(Vector3.new(1,roomH,roomD),CFrame.new(O+Vector3.new(roomW*0.5+0.5,roomH*0.5,0)),wallC,0,folder,Enum.Material.Cobblestone).Name="CaveWallR"

    -- ENTRY wall (back, positive Z) - has arch hole so you can see back
    buildArchWall(folder, O, roomD*0.5+0.5, roomW, roomH, wallC, false, nil)

    -- EXIT wall (front, negative Z) - has arch hole + door number sign
    buildArchWall(folder, O, -(roomD*0.5+0.5), roomW, roomH, wallC, true, doorNum)

    -- ---- BARRICADE ----
    if isBarricaded then
        local plankC   = Color3.fromRGB(80,55,25)
        local barF     = Instance.new("Folder"); barF.Name="Barricade"; barF.Parent=folder
        local halfGap  = DOOR_GAP_W*0.5
        local planks   = {}
        local plankH   = DOOR_GAP_H / 4

        for pi = 0,3 do
            local pk = makePart(
                Vector3.new(DOOR_GAP_W-0.2, plankH-0.15, 0.5),
                CFrame.new(O+Vector3.new(0, plankH*0.5+pi*plankH, -(roomD*0.5+0.5))),
                plankC, 0, barF, Enum.Material.Wood
            )
            pk.Name = "BarricadePlank"; table.insert(planks, pk)
        end

        -- Nail visuals if nailed
        local nailFolder = Instance.new("Folder"); nailFolder.Name="NailsFolder"; nailFolder.Parent=barF
        if isNailed then
            for ni = 1,6 do
                local nx = math.random(-28,28)*0.1; local ny = math.random(5,75)*0.1
                local nail = makePart(Vector3.new(0.15,0.15,0.6),CFrame.new(O+Vector3.new(nx,ny,-(roomD*0.5+0.5))),Color3.fromRGB(140,130,120),0,nailFolder,Enum.Material.Metal)
                nail.Name = "Nail"; nail.CanCollide = false
            end
        end

        local nailsRemoved = not isNailed
        local prompt = Instance.new("ProximityPrompt")
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 6
        prompt.ActionText = isNailed and "Use Drill (remove nails)" or "Use Hammer (break barricade)"
        prompt.Parent = planks[1]

        prompt.Triggered:Connect(function(plr)
            local char = plr.Character; if not char then return end

            -- STEP 1: If nailed, must drill first
            if not nailsRemoved then
                if char:FindFirstChild("Drill") then
                    nailsRemoved = true
                    nailFolder:Destroy()
                    prompt.ActionText = "Use Hammer (break barricade)"
                    char.Drill:Destroy()
                    for idx, v in ipairs(inventory) do if v=="Drill" then table.remove(inventory,idx); break end end
                    showWarning("Nails drilled out! Now use a Hammer to break it.", 2.5)
                else
                    showWarning("Barricade is NAILED. You need a Drill first!", 2)
                end
                return
            end

            -- STEP 2: Hammer breaks the planks
            if char:FindFirstChild("Hammer") then
                for _, pk in ipairs(planks) do if pk and pk.Parent then pk:Destroy() end end
                barF:Destroy(); prompt:Destroy()
                char.Hammer:Destroy()
                for idx, v in ipairs(inventory) do if v=="Hammer" then table.remove(inventory,idx); break end end
                showWarning("Barricade smashed! Path is clear.", 2)
            else
                showWarning("You need a Hammer to break this barricade!", 2)
            end
        end)
    end

    -- ---- CHECKPOINT SIGN ----
    if doorNum > DOOR_START and (doorNum-DOOR_START) % CHECKPOINT_EVERY == 0 then
        local cpPart = makePart(Vector3.new(10,2.5,0.4),CFrame.new(O+Vector3.new(0,6,0)),Color3.fromRGB(12,80,12),0,folder,Enum.Material.Neon)
        cpPart.Name="CheckpointSign"
        local cpG=Instance.new("SurfaceGui"); cpG.Face=Enum.NormalId.Front; cpG.Parent=cpPart
        local cpL=Instance.new("TextLabel"); cpL.Size=UDim2.new(1,0,1,0); cpL.BackgroundTransparency=1
        cpL.Text="CHECKPOINT  -  Cave Door "..doorNum; cpL.TextColor3=Color3.fromRGB(100,255,100)
        cpL.TextScaled=true; cpL.Font=Enum.Font.GothamBold; cpL.Parent=cpG
    end

    -- ---- LANTERNS ----
    if not isDark then
        for li = 1, math.random(2,4) do
            local lx = math.random(-math.floor(roomW*0.35),math.floor(roomW*0.35))
            local lz = math.random(-math.floor(roomD*0.35),math.floor(roomD*0.35))
            makePart(Vector3.new(0.15,2,0.15),CFrame.new(O+Vector3.new(lx,roomH-0.5,lz)),Color3.fromRGB(60,55,50),0,folder,Enum.Material.Metal).Name="LanternChain"
            local lan=makePart(Vector3.new(1.2,1.4,1.2),CFrame.new(O+Vector3.new(lx,roomH-2.4,lz)),Color3.fromRGB(255,210,100),0,folder,Enum.Material.Neon)
            lan.Name="Lantern"; makeLight(lan,1.8,30,Color3.fromRGB(255,210,110))
        end
    end

    -- ---- STALACTITES ----
    for si = 1, math.random(4,9) do
        makeStalactite(folder, roomH,
            O.X + math.random(-math.floor(roomW*0.42),math.floor(roomW*0.42)),
            O.Z + math.random(-math.floor(roomD*0.42),math.floor(roomD*0.42))
        )
    end

    -- ---- SPIKY ROCKS ----
    for si = 1, math.random(2,5) do
        spawnSpikyRock(folder, O+Vector3.new(
            math.random(-math.floor(roomW*0.38),math.floor(roomW*0.38)), 0,
            math.random(-math.floor(roomD*0.38),math.floor(roomD*0.38))
        ))
    end

    -- ---- ROCK PILES & PROPS ----
    for pi = 1, math.random(1,3) do
        makeRockPile(folder, O+Vector3.new(math.random(-math.floor(roomW*0.4),math.floor(roomW*0.4)),0,math.random(-math.floor(roomD*0.4),math.floor(roomD*0.4))))
    end
    local roll = math.random(1,10)
    if roll<=7 then makeCrate(folder, O+Vector3.new(math.random(-12,12),0,math.random(-20,20))) end
    if roll<=6 then makeBarrel(folder, O+Vector3.new(math.random(-12,12),0,math.random(-20,20))) end
    if roll<=5 then makeBarrel(folder, O+Vector3.new(math.random(-12,12),0,math.random(-20,20))) end

    -- ---- LOCKERS: 1-3 normal, 3-6 in barricaded rooms ----
    local numLockers = isBarricaded and math.random(3,6) or math.random(1,3)
    for li = 1, numLockers do
        local lx = (math.random(1,2)==1 and 1 or -1) * math.random(8,math.floor(roomW*0.42))
        local lz = math.random(-math.floor(roomD*0.4),math.floor(roomD*0.4))
        makeLocker(folder, O+Vector3.new(lx,0,lz))
    end

    -- ---- MINECARTS: 1 hide, 1-2 filled, rest deco ----
    local numCarts    = math.random(3,5)
    local hideSpawned = false
    local filledCount = 0
    local maxFilled   = math.random(1,2)

    for ci = 1, numCarts do
        local cx = math.random(-math.floor(roomW*0.35),math.floor(roomW*0.35))
        local cz = math.random(-math.floor(roomD*0.35),math.floor(roomD*0.35))
        local ctype
        if not hideSpawned then
            ctype="hide"; hideSpawned=true
        elseif filledCount < maxFilled then
            ctype="filled"; filledCount=filledCount+1
        else
            ctype="deco"
        end
        makeMinecart(folder, O+Vector3.new(cx,0,cz), ctype)
    end

    rooms[doorNum] = folder
end

-- =================================================================
-- CAVE LOBBY
-- =================================================================
createLobby = function()
    local folder = Instance.new("Folder"); folder.Name="CaveLobby"; folder.Parent=workspace
    makePart(Vector3.new(55,1,70),CFrame.new(0,-0.5,35),Color3.fromRGB(38,36,34),0,folder,Enum.Material.Slate).Name="LobbyFloor"
    makePart(Vector3.new(55,1,70),CFrame.new(0,CAVE_H+0.5,35),Color3.fromRGB(30,28,27),0,folder,Enum.Material.Slate).Name="LobbyCeiling"
    makePart(Vector3.new(55,CAVE_H,1),CFrame.new(0,CAVE_H*0.5,70.5),Color3.fromRGB(45,43,40),0,folder,Enum.Material.Cobblestone).Name="LobbyBack"
    makePart(Vector3.new(1,CAVE_H,70),CFrame.new(-27.5,CAVE_H*0.5,35),Color3.fromRGB(45,43,40),0,folder,Enum.Material.Cobblestone).Name="LobbyWallL"
    makePart(Vector3.new(1,CAVE_H,70),CFrame.new(27.5,CAVE_H*0.5,35),Color3.fromRGB(45,43,40),0,folder,Enum.Material.Cobblestone).Name="LobbyWallR"
    for _, lp in ipairs({Vector3.new(-14,CAVE_H-2,20),Vector3.new(14,CAVE_H-2,20),Vector3.new(-14,CAVE_H-2,50),Vector3.new(14,CAVE_H-2,50),Vector3.new(0,CAVE_H-2,35)}) do
        makePart(Vector3.new(0.15,2,0.15),CFrame.new(lp+Vector3.new(0,1.2,0)),Color3.fromRGB(60,55,50),0,folder,Enum.Material.Metal)
        local lan=makePart(Vector3.new(1.2,1.4,1.2),CFrame.new(lp),Color3.fromRGB(255,210,100),0,folder,Enum.Material.Neon)
        makeLight(lan,2.2,40,Color3.fromRGB(255,210,110))
    end
    local sb=makePart(Vector3.new(22,4.5,0.5),CFrame.new(0,14,69),Color3.fromRGB(22,20,18),0,folder,Enum.Material.Slate); sb.Name="WelcomeSign"
    local wg=Instance.new("SurfaceGui"); wg.Face=Enum.NormalId.Front; wg.Parent=sb
    local wl1=Instance.new("TextLabel"); wl1.Size=UDim2.new(1,0,0.55,0); wl1.BackgroundTransparency=1; wl1.Text="THE CAVES"
    wl1.TextColor3=Color3.fromRGB(200,170,100); wl1.TextScaled=true; wl1.Font=Enum.Font.GothamBold; wl1.Parent=wg
    local wl2=Instance.new("TextLabel"); wl2.Size=UDim2.new(1,0,0.4,0); wl2.Position=UDim2.new(0,0,0.58,0); wl2.BackgroundTransparency=1
    wl2.Text="Cave Doors 230-1000  |  Hide in EMPTY carts (blue glow)!"; wl2.TextColor3=Color3.fromRGB(160,145,120); wl2.TextScaled=true; wl2.Font=Enum.Font.Gotham; wl2.Parent=wg
    makeCrate(folder,Vector3.new(-14,0,44)); makeCrate(folder,Vector3.new(14,0,44))
    makeBarrel(folder,Vector3.new(-18,0,32)); makeBarrel(folder,Vector3.new(18,0,32))
    makeRockPile(folder,Vector3.new(-10,0,58)); makeRockPile(folder,Vector3.new(10,0,58))
    makeMinecart(folder,Vector3.new(-14,0,54),"deco"); makeMinecart(folder,Vector3.new(14,0,54),"deco")
    for si=1,12 do makeStalactite(folder,CAVE_H,math.random(-24,24),math.random(10,68)) end
    local btn=makePart(Vector3.new(8,3,3.5),CFrame.new(0,1.5,16),Color3.fromRGB(0,140,60),0,folder,Enum.Material.Neon); btn.Name="StartButton"
    local bg2=Instance.new("SurfaceGui"); bg2.Face=Enum.NormalId.Front; bg2.Parent=btn
    local bl=Instance.new("TextLabel"); bl.Size=UDim2.new(1,0,1,0); bl.BackgroundTransparency=1
    bl.Text="ENTER THE CAVES"; bl.TextColor3=Color3.fromRGB(255,255,255); bl.TextScaled=true; bl.Font=Enum.Font.GothamBold; bl.Parent=bg2
    makeLight(btn,3,20,Color3.fromRGB(0,200,80))
    local startGui=Instance.new("ScreenGui"); startGui.Name="CaveStartGui"; startGui.ResetOnSpawn=false; startGui.Parent=player.PlayerGui
    local sf=Instance.new("Frame"); sf.Size=UDim2.new(0,280,0,65); sf.Position=UDim2.new(0.5,-140,0.83,0)
    sf.BackgroundColor3=Color3.fromRGB(0,100,40); sf.BackgroundTransparency=0.2; sf.BorderSizePixel=0; sf.Visible=false; sf.Name="StartFrame"; sf.Parent=startGui
    local sfc=Instance.new("UICorner"); sfc.CornerRadius=UDim.new(0,14); sfc.Parent=sf
    local sbUI=Instance.new("TextButton"); sbUI.Size=UDim2.new(1,0,1,0); sbUI.BackgroundTransparency=1
    sbUI.Text="[TAP TO ENTER CAVES]"; sbUI.TextColor3=Color3.fromRGB(255,255,255); sbUI.TextScaled=true; sbUI.Font=Enum.Font.GothamBold; sbUI.Parent=sf
    sbUI.MouseButton1Click:Connect(function() if not gameStarted then startGui:Destroy(); startGame() end end)
    RunService.Heartbeat:Connect(function() if gameStarted or not rootPart or not startGui.Parent then return end; sf.Visible=(rootPart.Position-btn.Position).Magnitude<12 end)
    rooms[-1]=folder; if character then character:PivotTo(CFrame.new(0,3,48)) end
end

-- =================================================================
-- HIDING
-- =================================================================
hideInCart = function()
    if not currentCart or isHiding or not humanoid then return end
    isHiding=true; humanoid.WalkSpeed=0; humanoid.JumpPower=0
    for _,part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then hiddenParts[part]=part.Transparency; part.Transparency=1 end
    end
    if hideBtnLabel then hideBtnLabel.Text="[EXIT CART]" end
end

exitCart = function()
    if not isHiding or not humanoid then return end
    isHiding=false; humanoid.JumpPower=50
    for part,trans in pairs(hiddenParts) do if part and part.Parent then part.Transparency=trans end end
    table.clear(hiddenParts)
    if hideBtnLabel then hideBtnLabel.Text="[HIDE IN CART]" end
end

-- =================================================================
-- WARNING
-- =================================================================
showWarning = function(msg, duration)
    if not warningFrame then return end
    warningFrame.Visible=true
    if warningLabel then warningLabel.Text=msg end
    task.delay(duration or 4, function() if warningFrame then warningFrame.Visible=false end end)
end

-- =================================================================
-- DEATH
-- =================================================================
onDeath = function()
    if isDead then return end
    isDead=true; gameStarted=false; isHiding=false
    if humanoid then humanoid.CameraOffset=Vector3.new(0,0,0) end
    inventory={}; ecstasyActive=false; helmetEquipped=false; helmetLight=nil
    local ccc=game.Lighting:FindFirstChild("EcstasyCC"); if ccc then ccc:Destroy() end
    local dg=Instance.new("ScreenGui"); dg.Name="CaveDeathGui"; dg.ResetOnSpawn=false; dg.Parent=player.PlayerGui
    local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(100,0,0); bg.BackgroundTransparency=0.45; bg.BorderSizePixel=0; bg.Parent=dg
    local dl=Instance.new("TextLabel"); dl.Size=UDim2.new(1,0,0.28,0); dl.Position=UDim2.new(0,0,0.32,0); dl.BackgroundTransparency=1
    dl.Text="YOU DIED IN THE CAVES"; dl.TextColor3=Color3.fromRGB(255,255,255); dl.TextScaled=true; dl.Font=Enum.Font.GothamBold; dl.Parent=bg
    local sl=Instance.new("TextLabel"); sl.Size=UDim2.new(1,0,0.1,0); sl.Position=UDim2.new(0,0,0.60,0); sl.BackgroundTransparency=1
    sl.Text="Returning to checkpoint: Cave Door "..tostring(checkpointDoor); sl.TextColor3=Color3.fromRGB(255,180,180); sl.TextScaled=true; sl.Font=Enum.Font.Gotham; sl.Parent=bg
    player.CharacterAdded:Wait(); task.wait(0.3); dg:Destroy(); isDead=false
    if character and rootPart then character:PivotTo(CFrame.new(0,3,-(checkpointDoor*CAVE_D)+CAVE_D*0.35)) end
    currentDoor=checkpointDoor; lastDetectedDoor=checkpointDoor
    if doorLabel then doorLabel.Text="Cave Door: "..tostring(checkpointDoor) end
    gameStarted=true
    for i=checkpointDoor, checkpointDoor+GEN_AHEAD do if i<=DOOR_MAX then generateRoom(i) end end
end

-- =================================================================
-- ENTITIES
-- =================================================================
spawnDisease = function(doorNum)
    if diseaseActive or diseaseOnCooldown then return end
    diseaseActive=true; diseaseOnCooldown=true
    local ef=Instance.new("Folder"); ef.Name="DiseaseEntity"; ef.Parent=workspace
    local startDoor=doorNum-DISEASE_BEFORE; local stopDoor=doorNum+DISEASE_AFTER
    local startZ=-(startDoor*CAVE_D); local stopZ=-(stopDoor*CAVE_D)
    for d=startDoor,stopDoor do
        if rooms[d] then
            local smoke=Instance.new("ParticleEmitter"); smoke.Color=ColorSequence.new(Color3.fromRGB(180,0,0))
            smoke.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,8),NumberSequenceKeypoint.new(1,18)})
            smoke.Rate=80; smoke.Speed=NumberRange.new(2,4); smoke.Lifetime=NumberRange.new(3,5)
            smoke.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.75),NumberSequenceKeypoint.new(1,1)})
            local ep=makePart(Vector3.new(CAVE_W,1,CAVE_D),CFrame.new(0,CAVE_H*0.5,-(d*CAVE_D)),Color3.new(),1,ef); smoke.Parent=ep
        end
    end
    local body=makePart(Vector3.new(CAVE_W-1,CAVE_H,CAVE_D),CFrame.new(0,CAVE_H*0.5,startZ),Color3.fromRGB(140,0,0),0.45,ef,Enum.Material.Neon)
    body.Name="DiseaseBody"; body.CanCollide=false
    local tr=Instance.new("Trail"); tr.Color=ColorSequence.new(Color3.fromRGB(220,0,0)); tr.Lifetime=1.8; tr.Parent=body
    local a0=Instance.new("Attachment",body); a0.Position=Vector3.new(0,5,0)
    local a1=Instance.new("Attachment",body); a1.Position=Vector3.new(0,-5,0)
    tr.Attachment0=a0; tr.Attachment1=a1
    local snd=Instance.new("Sound"); snd.SoundId="rbxassetid://125795970503985"; snd.Volume=1.5; snd.Looped=true; snd.RollOffMaxDistance=200; snd.Parent=body; snd:Play()
    local mc
    mc=RunService.Heartbeat:Connect(function(dt)
        if not body or not body.Parent then mc:Disconnect(); return end
        local newZ=body.CFrame.Position.Z-DISEASE_SPEED*dt
        body.CFrame=CFrame.new(body.CFrame.Position.X,body.CFrame.Position.Y,newZ)
        if rootPart and humanoid and not isDead then
            local dZ=math.abs(rootPart.Position.Z-newZ)
            if dZ<140 then local i2=(140-dZ)/140; humanoid.CameraOffset=Vector3.new(math.random(-10,10)*0.05*i2,math.random(-10,10)*0.05*i2,0) else humanoid.CameraOffset=Vector3.new(0,0,0) end
            if not isHiding and dZ<CAVE_D*0.45 then if humanoid.Health>0 then humanoid.Health=0; onDeath() end end
        end
        if newZ<=stopZ then
            mc:Disconnect(); snd:Stop(); diseaseActive=false
            if humanoid then humanoid.CameraOffset=Vector3.new(0,0,0) end
            local step=0; local fc; fc=RunService.Heartbeat:Connect(function() step=step+1; if body and body.Parent then body.Transparency=0.45+step*0.06 end; if step>=10 then fc:Disconnect(); ef:Destroy() end end)
            task.delay(DISEASE_COOLDOWN,function() diseaseOnCooldown=false end)
        end
    end)
end

spawnHer = function(doorNum)
    if herActive or herOnCooldown then return end
    herActive=true; herOnCooldown=true
    local ef=Instance.new("Folder"); ef.Name="HerEntity"; ef.Parent=workspace
    local body=makePart(Vector3.new(1.8,7.5,1.8),CFrame.new(0,3.75,-(doorNum*CAVE_D)),Color3.fromRGB(0,0,0),0,ef)
    body.Name="HerBody"; body.CanCollide=false
    local snd=Instance.new("Sound"); snd.SoundId="rbxassetid://129136912774651"; snd.Volume=2; snd.Looped=true; snd.RollOffMaxDistance=100; snd.Parent=body; snd:Play()
    local lookTimer=0; local isChasing=false; local hc
    hc=RunService.Heartbeat:Connect(function(dt)
        if not body or not body.Parent or isDead then if hc then hc:Disconnect() end; return end
        if not isChasing then
            if rootPart and camera then
                local dot=camera.CFrame.LookVector:Dot((body.Position-camera.CFrame.Position).Unit)
                if dot>0.75 then lookTimer=lookTimer+dt else lookTimer=math.max(0,lookTimer-dt) end
                if lookTimer>=3 then
                    isChasing=true; snd:Stop(); snd.SoundId="rbxassetid://108968287863512"; snd.Volume=3; snd:Play(); body.Color=Color3.fromRGB(22,0,0)
                end
            end
            if currentDoor>doorNum+2 then hc:Disconnect(); ef:Destroy(); herActive=false; task.delay(HER_COOLDOWN,function() herOnCooldown=false end) end
        else
            if rootPart then
                local lCF=CFrame.lookAt(body.Position,rootPart.Position)
                local newPos=lCF.Position+lCF.LookVector*HER_SPEED*dt
                body.CFrame=CFrame.new(newPos.X,3.75,newPos.Z)
                local dist=(rootPart.Position-body.Position).Magnitude
                if dist<90 and humanoid then local i2=(90-dist)/90; humanoid.CameraOffset=Vector3.new(math.random(-10,10)*0.07*i2,math.random(-10,10)*0.07*i2,0) end
                if dist<4 and humanoid and humanoid.Health>0 then humanoid.Health=0; onDeath() end
                if not roomIsDark[currentDoor] then hc:Disconnect(); snd:Stop(); if humanoid then humanoid.CameraOffset=Vector3.new(0,0,0) end; ef:Destroy(); herActive=false; task.delay(HER_COOLDOWN,function() herOnCooldown=false end) end
            end
        end
    end)
end

spawnVoid = function(doorNum)
    if voidActive or voidOnCooldown then return end
    voidActive=true; voidOnCooldown=true
    local vp=makePart(Vector3.new(5,0.1,5),CFrame.new(0,-0.4,-(doorNum*CAVE_D)),Color3.fromRGB(5,5,5),0,workspace,Enum.Material.Neon)
    vp.Name="VoidSubstance"; vp.CanCollide=false
    local pe=Instance.new("ParticleEmitter",vp); pe.Color=ColorSequence.new(Color3.fromRGB(0,0,0))
    pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,5)}); pe.Rate=55; pe.Speed=NumberRange.new(4,10)
    local es=Instance.new("Sound",vp); es.SoundId="rbxassetid://140328974468167"; es.Looped=true; es.PlaybackSpeed=0.01; es.Volume=2; es.RollOffMaxDistance=200; es:Play()
    local startT=tick(); local vc
    vc=RunService.Heartbeat:Connect(function()
        if not vp or not vp.Parent then vc:Disconnect(); return end
        local prog=math.min(1,(tick()-startT)/14); local cs=5+(90-5)*prog
        vp.Size=Vector3.new(cs,0.1,cs); es.PlaybackSpeed=0.01+1.99*prog
        if rootPart and humanoid and humanoid.Health>0 and not isDead and not isHiding then
            local pP=rootPart.Position; local vP=vp.Position
            local d=math.sqrt((pP.X-vP.X)^2+(pP.Z-vP.Z)^2)
            if d<=(cs/2) and math.abs(pP.Y-vP.Y)<10 then
                humanoid.Health=0
                for _,pt in ipairs(character:GetDescendants()) do if pt:IsA("BasePart") then pt.CanCollide=false end end
                humanoid:ChangeState(Enum.HumanoidStateType.Physics); rootPart.Velocity=Vector3.new(0,-50,0); onDeath()
            end
        end
    end)
    task.delay(28,function() voidActive=false; if vc then vc:Disconnect() end; if vp and vp.Parent then vp:Destroy() end end)
    task.delay(VOID_COOLDOWN,function() voidOnCooldown=false end)
end

-- =================================================================
-- DOOR REACHED
-- =================================================================
onDoorReached = function(doorNum)
    currentDoor=doorNum
    if doorLabel then doorLabel.Text="Cave Door: "..tostring(doorNum) end
    if doorNum>DOOR_START and (doorNum-DOOR_START)%CHECKPOINT_EVERY==0 then
        checkpointDoor=doorNum; showWarning("CHECKPOINT SAVED  -  Cave Door "..tostring(doorNum),3)
    end
    for i=doorNum+1,doorNum+GEN_AHEAD do if i<=DOOR_MAX then generateRoom(i) end end
    for i=DOOR_START,doorNum-CLEAN_BEHIND do if rooms[i] then rooms[i]:Destroy(); rooms[i]=nil end; roomIsDark[i]=nil end
    if doorNum>=HER_START and not herActive and not herOnCooldown then
        if roomIsDark[doorNum] and math.random(1,100)<=28 then task.spawn(function() spawnHer(doorNum) end) end
    end
    if not diseaseActive and not diseaseOnCooldown and doorNum>=DOOR_START+5 then
        if math.random(1,100)<=40 then spawnDisease(doorNum) end
    end
    if doorNum>=VOID_START and not voidActive and not voidOnCooldown then
        if math.random(1,100)<=VOID_CHANCE then task.spawn(function() spawnVoid(doorNum) end) end
    end
    if doorNum>=DOOR_MAX then showWarning("YOU ESCAPED THE CAVES! You are a legend, miner.",20); gameStarted=false end
end

-- =================================================================
-- START GAME
-- =================================================================
startGame = function()
    gameStarted=true; currentDoor=DOOR_START; lastDetectedDoor=DOOR_START; checkpointDoor=DOOR_START
    if character then character:PivotTo(CFrame.new(0,3,-(DOOR_START*CAVE_D)+CAVE_D*0.45)) end
    for i=DOOR_START,DOOR_START+GEN_AHEAD do generateRoom(i) end
end

-- =================================================================
-- CHARACTER REF
-- =================================================================
updateCharRef = function(newChar)
    character=newChar; humanoid=newChar:WaitForChild("Humanoid"); rootPart=newChar:WaitForChild("HumanoidRootPart")
    task.spawn(function() local rs=rootPart:WaitForChild("Running",3); if rs then rs.Volume=0 end end)
    floorStepSound=Instance.new("Sound"); floorStepSound.SoundId="rbxassetid://138898236956764"; floorStepSound.Volume=1; floorStepSound.Parent=rootPart
    humanoid.Died:Connect(function() onDeath() end)
end

-- =================================================================
-- MAIN LOOP
-- =================================================================
mainLoop = function()
    RunService.Heartbeat:Connect(function(dt)
        if not gameStarted or not rootPart then return end
        local targetSpeed=16
        if ecstasyActive then
            if tick()>ecstasyEndTime then ecstasyActive=false; local ccc=game.Lighting:FindFirstChild("EcstasyCC"); if ccc then ccc:Destroy() end
            else targetSpeed=22 end
        end
        if tick()<speedPenaltyEnd then targetSpeed=targetSpeed-3 end
        if not isHiding and humanoid and not diseaseActive then humanoid.WalkSpeed=targetSpeed end
        if humanoid and humanoid.Health>0 and not isHiding then
            local moving=humanoid.MoveDirection.Magnitude>0
            if moving and humanoid.FloorMaterial~=Enum.Material.Air then
                local sr=humanoid.WalkSpeed/16; local siv=0.38/math.max(0.1,sr)
                if tick()-lastStepTime>=siv then lastStepTime=tick(); if floorStepSound then floorStepSound.PlaybackSpeed=sr; floorStepSound:Play() end end
            else lastStepTime=0 end
        end
        local approxDoor=math.max(DOOR_START,math.floor(-rootPart.Position.Z/CAVE_D+0.5))
        if approxDoor>lastDetectedDoor and approxDoor<=DOOR_MAX then lastDetectedDoor=approxDoor; onDoorReached(approxDoor) end
        nearCart=false; currentCart=nil
        for d=currentDoor-1,currentDoor+1 do
            if rooms[d] then
                for _,part in ipairs(rooms[d]:GetDescendants()) do
                    if part:IsA("BasePart") and part:GetAttribute("IsLocker") then
                        if (rootPart.Position-part.Position).Magnitude<CART_DIST then nearCart=true; currentCart=part end
                    end
                end
            end
        end
        if hidePrompt then hidePrompt.Visible=(nearCart and not isHiding) or isHiding end
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
