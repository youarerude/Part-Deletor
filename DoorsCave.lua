-- ============================================================
-- THE CAVES - LocalScript Executor
-- Devious Goober  |  Starts at Door 230  |  Stage 2
-- Entities : Disease, Her, Void
-- Items    : Coins, Ecstasy, Key, Miner Helmet
-- Hiding   : Minecarts
-- ============================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== CONSTANTS =====
local CAVE_W            = 35
local CAVE_H            = 22
local CAVE_D            = 60
local DOOR_START        = 230
local DOOR_MAX          = 1000
local CHECKPOINT_EVERY  = 50

local DISEASE_SPEED     = 70
local DISEASE_COOLDOWN  = 12
local DISEASE_BEFORE    = 4
local DISEASE_AFTER     = 4

local HER_START         = 235
local HER_COOLDOWN      = 90
local HER_SPEED         = 28

local VOID_START        = 250
local VOID_CHANCE       = 18
local VOID_COOLDOWN     = 35

local CART_DIST         = 5
local GEN_AHEAD         = 6
local CLEAN_BEHIND      = 7
local MAX_ITEMS         = 3

-- ===== STATE =====
local character       = nil
local humanoid        = nil
local rootPart        = nil
local currentDoor     = DOOR_START
local lastDetectedDoor = DOOR_START
local gameStarted     = false
local isHiding        = false
local nearCart        = false
local currentCart     = nil
local checkpointDoor  = DOOR_START
local rooms           = {}
local roomIsDark      = {}
local diseaseActive   = false
local diseaseOnCooldown = false
local herActive       = false
local herOnCooldown   = false
local voidActive      = false
local voidOnCooldown  = false
local isDead          = false
local hiddenParts     = {}
local inventory       = {}
local coins           = 0
local ecstasyActive   = false
local ecstasyEndTime  = 0
local speedPenaltyEnd = 0
local helmetEquipped  = false
local helmetLight     = nil
local lastStepTime    = 0
local floorStepSound  = nil

-- ===== FORWARD DECLARATIONS =====
local setupLighting, createHUD, makePart, makeLight
local handleLoot, makeCrate, makeBarrel, makeRockPile, makeStalactite
local makeMinecart, makeLocker, spawnSpikyRock
local generateRoom, createLobby, startGame, showWarning
local hideInCart, exitCart
local spawnDisease, spawnHer, spawnVoid
local onDoorReached, onDeath, updateCharRef, mainLoop
local giveHelmet

-- ===== GUI REFS =====
local screenGui, doorLabel, coinLabel, warningFrame, warningLabel
local hidePrompt, hideBtnLabel

-- =================================================================
-- LIGHTING
-- =================================================================
setupLighting = function()
    local L = game:GetService("Lighting")
    L.Brightness     = 0.05
    L.ClockTime      = 0
    L.FogColor       = Color3.fromRGB(0, 0, 0)
    L.FogEnd         = 45
    L.FogStart       = 5
    L.GlobalShadows  = true
    L.Ambient        = Color3.fromRGB(6, 5, 8)
    L.OutdoorAmbient = Color3.fromRGB(4, 4, 6)
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

    -- Door Counter Bar
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(0, 200, 0, 48)
    topBar.Position = UDim2.new(0.5, -100, 0, 12)
    topBar.BackgroundColor3 = Color3.fromRGB(10, 8, 14)
    topBar.BackgroundTransparency = 0.35
    topBar.BorderSizePixel = 0
    topBar.Parent = screenGui
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 10)
    tc.Parent = topBar
    local tbStroke = Instance.new("UIStroke")
    tbStroke.Color = Color3.fromRGB(60, 45, 80)
    tbStroke.Thickness = 1.5
    tbStroke.Parent = topBar

    doorLabel = Instance.new("TextLabel")
    doorLabel.Size = UDim2.new(1, 0, 1, 0)
    doorLabel.BackgroundTransparency = 1
    doorLabel.Text = "Cave Door: " .. tostring(DOOR_START)
    doorLabel.TextColor3 = Color3.fromRGB(210, 190, 255)
    doorLabel.TextScaled = true
    doorLabel.Font = Enum.Font.GothamBold
    doorLabel.Parent = topBar

    -- Coin Bar
    local coinBar = Instance.new("Frame")
    coinBar.Size = UDim2.new(0, 140, 0, 42)
    coinBar.Position = UDim2.new(0, 14, 0, 12)
    coinBar.BackgroundColor3 = Color3.fromRGB(10, 8, 14)
    coinBar.BackgroundTransparency = 0.35
    coinBar.BorderSizePixel = 0
    coinBar.Parent = screenGui
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 10)
    cc.Parent = coinBar
    local cbStroke = Instance.new("UIStroke")
    cbStroke.Color = Color3.fromRGB(60, 45, 80)
    cbStroke.Thickness = 1.5
    cbStroke.Parent = coinBar

    local coinDot = Instance.new("Frame")
    coinDot.Size = UDim2.new(0, 20, 0, 20)
    coinDot.Position = UDim2.new(0, 8, 0.5, -10)
    coinDot.BackgroundColor3 = Color3.fromRGB(255, 210, 0)
    coinDot.BorderSizePixel = 0
    coinDot.ZIndex = 2
    coinDot.Parent = coinBar
    local cdC = Instance.new("UICorner")
    cdC.CornerRadius = UDim.new(1, 0)
    cdC.Parent = coinDot

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

    -- Warning Frame
    warningFrame = Instance.new("Frame")
    warningFrame.Name = "WarningFrame"
    warningFrame.Size = UDim2.new(1, 0, 0, 70)
    warningFrame.Position = UDim2.new(0, 0, 0.13, 0)
    warningFrame.BackgroundColor3 = Color3.fromRGB(18, 10, 28)
    warningFrame.BackgroundTransparency = 0.2
    warningFrame.BorderSizePixel = 0
    warningFrame.Visible = false
    warningFrame.Parent = screenGui

    warningLabel = Instance.new("TextLabel")
    warningLabel.Size = UDim2.new(1, -24, 1, 0)
    warningLabel.Position = UDim2.new(0, 12, 0, 0)
    warningLabel.BackgroundTransparency = 1
    warningLabel.Text = ""
    warningLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
    warningLabel.TextScaled = true
    warningLabel.Font = Enum.Font.GothamBold
    warningLabel.TextWrapped = true
    warningLabel.Parent = warningFrame

    -- Hide Prompt
    hidePrompt = Instance.new("Frame")
    hidePrompt.Name = "HidePrompt"
    hidePrompt.Size = UDim2.new(0, 250, 0, 60)
    hidePrompt.Position = UDim2.new(0.5, -125, 0.82, 0)
    hidePrompt.BackgroundColor3 = Color3.fromRGB(10, 8, 14)
    hidePrompt.BackgroundTransparency = 0.28
    hidePrompt.BorderSizePixel = 0
    hidePrompt.Visible = false
    hidePrompt.Parent = screenGui
    local hpC = Instance.new("UICorner")
    hpC.CornerRadius = UDim.new(0, 12)
    hpC.Parent = hidePrompt
    local hpS = Instance.new("UIStroke")
    hpS.Color = Color3.fromRGB(80, 60, 110)
    hpS.Thickness = 1.5
    hpS.Parent = hidePrompt

    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(1, 0, 1, 0)
    hideBtn.BackgroundTransparency = 1
    hideBtn.TextColor3 = Color3.fromRGB(255, 240, 80)
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
-- PART HELPER
-- =================================================================
makePart = function(size, cf, color, transparency, parent, material)
    local p = Instance.new("Part")
    p.Size = size
    p.CFrame = cf
    p.Color = color or Color3.fromRGB(40, 38, 45)
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
    l.Brightness = brightness or 1.5
    l.Range = range or 22
    l.Color = color or Color3.fromRGB(255, 200, 120)
    l.Parent = parent
    return l
end

-- =================================================================
-- LOOT SYSTEM
-- =================================================================
handleLoot = function(plr, forcedLoot)
    local loot = forcedLoot
    if not loot then
        local r = math.random(1, 100)
        if r <= 15 then
            loot = "MinerHelmet"
        elseif r <= 35 then
            loot = "Ecstasy"
        elseif r <= 55 then
            loot = "Coin"
        elseif r <= 65 then
            loot = "Key"
        else
            loot = "Nothing"
        end
    end

    if loot == "Coin" then
        local amt = math.random(1, 5)
        coins = coins + amt
        if coinLabel then coinLabel.Text = tostring(coins) .. " Coins" end
        showWarning("Found " .. tostring(amt) .. " Cave Coin" .. (amt > 1 and "s" or "") .. "!", 2.5)
        return
    end

    showWarning("Searched: Found " .. loot, 2)

    if loot == "Nothing" then return end
    if loot == "MinerHelmet" then
        if helmetEquipped then
            showWarning("You already have a helmet equipped!", 2)
            return
        end
        giveHelmet(plr)
        return
    end

    if #inventory >= MAX_ITEMS then
        showWarning("Inventory full! Max " .. tostring(MAX_ITEMS) .. " items.", 2)
        return
    end
    table.insert(inventory, loot)
    local tool = Instance.new("Tool")
    tool.Name = loot
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    if loot == "Key" then
        handle.Size = Vector3.new(1, 0.2, 0.2)
        handle.Color = Color3.fromRGB(210, 175, 50)
    elseif loot == "Ecstasy" then
        handle.Size = Vector3.new(0.5, 0.5, 0.5)
        handle.Color = Color3.fromRGB(200, 50, 200)
        handle.Material = Enum.Material.Neon
        tool.Activated:Connect(function()
            tool:Destroy()
            for idx, v in ipairs(inventory) do
                if v == "Ecstasy" then table.remove(inventory, idx) break end
            end
            ecstasyActive = true
            ecstasyEndTime = tick() + 180
            if humanoid then humanoid.WalkSpeed = 22 end
            local ccc = game.Lighting:FindFirstChild("EcstasyCC") or Instance.new("ColorCorrectionEffect", game.Lighting)
            ccc.Name = "EcstasyCC"
            ccc.Saturation = 1.5
            showWarning("Ecstasy active! Speed boost for 3 minutes.", 3)
        end)
    else
        handle.Size = Vector3.new(0.5, 0.5, 0.5)
    end
    handle.Parent = tool
    tool.Parent = plr.Backpack
end

-- =================================================================
-- CAVE DECORATIONS
-- =================================================================
makeCrate = function(folder, pos)
    local body = makePart(Vector3.new(2.5, 2.5, 2.5), CFrame.new(pos + Vector3.new(0, 1.25, 0)), Color3.fromRGB(80, 58, 32), 0, folder, Enum.Material.Wood)
    body.Name = "Crate"
    for i = 1, 2 do
        local plank = makePart(Vector3.new(2.6, 0.18, 2.6), CFrame.new(pos + Vector3.new(0, 0.6 + i * 0.85, 0)), Color3.fromRGB(60, 42, 22), 0, folder, Enum.Material.Wood)
        plank.Name = "CratePlank"
        plank.CanCollide = false
    end
    return body
end

makeBarrel = function(folder, pos)
    local body = makePart(Vector3.new(1.8, 2.8, 1.8), CFrame.new(pos + Vector3.new(0, 1.4, 0)), Color3.fromRGB(90, 62, 30), 0, folder, Enum.Material.Wood)
    body.Name = "Barrel"
    body.Shape = Enum.PartType.Cylinder
    local ring1 = makePart(Vector3.new(2, 0.2, 2), CFrame.new(pos + Vector3.new(0, 0.8, 0)), Color3.fromRGB(50, 45, 40), 0, folder, Enum.Material.Metal)
    ring1.Name = "BarrelRing"
    ring1.CanCollide = false
    local ring2 = makePart(Vector3.new(2, 0.2, 2), CFrame.new(pos + Vector3.new(0, 2.0, 0)), Color3.fromRGB(50, 45, 40), 0, folder, Enum.Material.Metal)
    ring2.Name = "BarrelRing"
    ring2.CanCollide = false
    return body
end

makeRockPile = function(folder, pos)
    local count = math.random(3, 6)
    for i = 1, count do
        local rx, rz, ry = math.random(-5, 5) * 0.2, math.random(-5, 5) * 0.2, math.random(2, 5) * 0.2
        local s  = math.random(6, 14) * 0.1
        local rock = makePart(
            Vector3.new(s, s * 0.65, s),
            CFrame.new(pos + Vector3.new(rx, ry, rz)) * CFrame.Angles(math.rad(math.random(0, 30)), math.rad(math.random(0, 360)), math.rad(math.random(0, 20))),
            Color3.fromRGB(55, 52, 50), 0, folder, Enum.Material.Slate
        )
        rock.Name = "RockPile"
        rock.CanCollide = false
    end
end

makeStalactite = function(folder, ceilingY, x, z)
    local len = math.random(20, 55) * 0.1
    local wid = math.random(4, 10) * 0.1
    local spart = makePart(
        Vector3.new(wid, len, wid),
        CFrame.new(x, ceilingY - len * 0.5, z) * CFrame.Angles(math.rad(math.random(-8, 8)), 0, math.rad(math.random(-8, 8))),
        Color3.fromRGB(50, 48, 46), 0, folder, Enum.Material.Slate
    )
    spart.Name = "Stalactite"
    spart.CanCollide = false
end

makeLocker = function(folder, pos, lockerList)
    local body = makePart(
        Vector3.new(3, 7, 3),
        CFrame.new(pos + Vector3.new(0, 3.5, 0)),
        Color3.fromRGB(35, 40, 45), 0, folder, Enum.Material.Metal
    )
    body.Name = "Locker"
    
    local doorDetail = makePart(
        Vector3.new(2.8, 6.8, 0.2),
        CFrame.new(pos + Vector3.new(0, 3.5, -1.55)),
        Color3.fromRGB(45, 50, 55), 0, folder, Enum.Material.Metal
    )
    doorDetail.Name = "LockerDoor"

    local searches = math.random(3, 5)
    body:SetAttribute("SearchesLeft", searches)

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Search Locker (" .. searches .. ")"
    prompt.RequiresLineOfSight = false
    prompt.Parent = body
    prompt.Triggered:Connect(function(plr)
        local left = body:GetAttribute("SearchesLeft")
        if left > 0 then
            left = left - 1
            body:SetAttribute("SearchesLeft", left)
            prompt.ActionText = "Search Locker (" .. left .. ")"
            
            -- Only dish out guaranteed key if it was assigned on first search
            handleLoot(plr, body:GetAttribute("Loot"))
            body:SetAttribute("Loot", nil) 

            if left <= 0 then
                prompt:Destroy()
            end
        end
    end)

    if lockerList then table.insert(lockerList, body) end
    return body
end

makeMinecart = function(folder, pos, isHideCart)
    local cartModel = Instance.new("Model")
    cartModel.Name = isHideCart and "HidingCart" or "LootCart"
    cartModel.Parent = folder

    -- 1 Floor
    local floor = makePart(
        Vector3.new(4, 0.3, 6.5),
        CFrame.new(pos + Vector3.new(0, 0.65, 0)),
        Color3.fromRGB(40, 38, 38), 0, cartModel, Enum.Material.Metal
    )
    floor.Name = "CartFloor"

    -- 4 Walls
    makePart(Vector3.new(4.5, 2.8, 0.25), CFrame.new(pos + Vector3.new(0, 1.8, 3.5)), Color3.fromRGB(55, 52, 52), 0, cartModel, Enum.Material.Metal).Name = "CartWallFront"
    makePart(Vector3.new(4.5, 2.8, 0.25), CFrame.new(pos + Vector3.new(0, 1.8, -3.5)), Color3.fromRGB(55, 52, 52), 0, cartModel, Enum.Material.Metal).Name = "CartWallBack"
    makePart(Vector3.new(0.25, 2.8, 6.75), CFrame.new(pos + Vector3.new(2.125, 1.8, 0)), Color3.fromRGB(55, 52, 52), 0, cartModel, Enum.Material.Metal).Name = "CartWallRight"
    makePart(Vector3.new(0.25, 2.8, 6.75), CFrame.new(pos + Vector3.new(-2.125, 1.8, 0)), Color3.fromRGB(55, 52, 52), 0, cartModel, Enum.Material.Metal).Name = "CartWallLeft"

    -- 4 Wheels
    for xi = -1, 1, 2 do
        for zi = -1, 1, 2 do
            local wheel = makePart(Vector3.new(0.5, 1.4, 1.4), CFrame.new(pos + Vector3.new(xi * 2.2, 0.7, zi * 2.6)), Color3.fromRGB(35, 33, 33), 0, cartModel, Enum.Material.Metal)
            wheel.Name = "CartWheel"
            wheel.Shape = Enum.PartType.Cylinder
        end
    end

    if isHideCart then
        floor:SetAttribute("IsLocker", true)
    else
        -- 1 Dirt Payload
        local dirt = makePart(
            Vector3.new(4, 2.2, 6.5),
            CFrame.new(pos + Vector3.new(0, 1.7, 0)),
            Color3.fromRGB(50, 40, 30), 0, cartModel, Enum.Material.Slate
        )
        dirt.Name = "CartDirt"

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Search Dirt"
        prompt.RequiresLineOfSight = false
        prompt.Parent = dirt
        prompt.Triggered:Connect(function(plr)
            prompt:Destroy()
            handleLoot(plr)
        end)
    end

    -- Rails
    for xi = -1, 1, 2 do
        local rail = makePart(Vector3.new(0.3, 0.3, CAVE_D * 0.9), CFrame.new(pos + Vector3.new(xi * 1.6, 0.15, 0)), Color3.fromRGB(70, 68, 65), 0, cartModel, Enum.Material.Metal)
        rail.Name = "Rail"
        rail.CanCollide = false
    end
    return floor
end

spawnSpikyRock = function(folder, pos)
    local h = math.random(4, 9)
    local spike = makePart(
        Vector3.new(math.random(15, 30) * 0.1, h, math.random(15, 30) * 0.1),
        CFrame.new(pos + Vector3.new(0, h * 0.5, 0)) * CFrame.Angles(math.rad(math.random(-12, 12)), math.rad(math.random(0, 360)), math.rad(math.random(-12, 12))),
        Color3.fromRGB(30, 28, 28), 0, folder, Enum.Material.Slate
    )
    spike.Name = "SpikyRock"
    local db = false
    spike.Touched:Connect(function(hit)
        if hit.Parent == character and not db and not isHiding then
            db = true
            if humanoid and humanoid.Health > 0 then
                humanoid:TakeDamage(5)
                showWarning("Ouch! Spiky rock!", 1.2)
            end
            task.wait(1.5)
            db = false
        end
    end)
end

-- =================================================================
-- GIVE HELMET ITEM
-- =================================================================
giveHelmet = function(plr)
    if #inventory >= MAX_ITEMS then
        showWarning("Inventory full! Max " .. MAX_ITEMS .. " items.", 2)
        return
    end
    table.insert(inventory, "MinerHelmet")
    local tool = Instance.new("Tool")
    tool.Name = "MinerHelmet"
    tool.ToolTip = "Equip to wear a light-up helmet"
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1.4, 1, 1.4)
    handle.Color = Color3.fromRGB(38, 80, 120)
    handle.Material = Enum.Material.Metal
    handle.Parent = tool
    local visor = Instance.new("Part")
    visor.Name = "Visor"
    visor.Size = Vector3.new(1.3, 0.35, 0.2)
    visor.Color = Color3.fromRGB(200, 220, 255)
    visor.Material = Enum.Material.Neon
    visor.Transparency = 0.3
    visor.CanCollide = false
    visor.Anchored = false
    local weld = Instance.new("Weld")
    weld.Part0 = handle
    weld.Part1 = visor
    weld.C1 = CFrame.new(0, -0.2, -0.65)
    weld.Parent = handle
    visor.Parent = tool
    local lamp = Instance.new("Part")
    lamp.Name = "HelmLamp"
    lamp.Size = Vector3.new(0.4, 0.35, 0.4)
    lamp.Color = Color3.fromRGB(255, 240, 160)
    lamp.Material = Enum.Material.Neon
    lamp.CanCollide = false
    lamp.Anchored = false
    local lampWeld = Instance.new("Weld")
    lampWeld.Part0 = handle
    lampWeld.Part1 = lamp
    lampWeld.C1 = CFrame.new(0, -0.42, -0.55)
    lampWeld.Parent = handle
    lamp.Parent = tool
    tool.Parent = plr.Backpack

    tool.Activated:Connect(function()
        if helmetEquipped then
            showWarning("Helmet already equipped!", 1.5)
            return
        end
        for idx, v in ipairs(inventory) do
            if v == "MinerHelmet" then table.remove(inventory, idx) break end
        end
        tool:Destroy()
        helmetEquipped = true

        local char = player.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end

        local hatPart = Instance.new("Part")
        hatPart.Name = "MinerHat"
        hatPart.Size = Vector3.new(1.6, 1.1, 1.6)
        hatPart.Color = Color3.fromRGB(38, 80, 120)
        hatPart.Material = Enum.Material.Metal
        hatPart.CanCollide = false
        hatPart.Anchored = false
        hatPart.Parent = char
        local hatWeld = Instance.new("Weld")
        hatWeld.Part0 = head
        hatWeld.Part1 = hatPart
        hatWeld.C0 = CFrame.new(0, 0.7, 0)
        hatWeld.Parent = hatPart

        local brim = Instance.new("Part")
        brim.Name = "HatBrim"
        brim.Size = Vector3.new(2, 0.15, 2)
        brim.Color = Color3.fromRGB(28, 62, 96)
        brim.Material = Enum.Material.Metal
        brim.CanCollide = false
        brim.Anchored = false
        brim.Parent = char
        local brimWeld = Instance.new("Weld")
        brimWeld.Part0 = hatPart
        brimWeld.Part1 = brim
        brimWeld.C0 = CFrame.new(0, -0.45, 0)
        brimWeld.Parent = brim

        local hatLamp = Instance.new("Part")
        hatLamp.Name = "HatLamp"
        hatLamp.Size = Vector3.new(0.45, 0.4, 0.45)
        hatLamp.Color = Color3.fromRGB(255, 245, 180)
        hatLamp.Material = Enum.Material.Neon
        hatLamp.CanCollide = false
        hatLamp.Anchored = false
        hatLamp.Parent = char
        local lampWeld2 = Instance.new("Weld")
        lampWeld2.Part0 = hatPart
        lampWeld2.Part1 = hatLamp
        lampWeld2.C0 = CFrame.new(0, 0.2, -0.65)
        lampWeld2.Parent = hatLamp

        helmetLight = Instance.new("PointLight")
        helmetLight.Brightness = 2.5
        helmetLight.Range = 38
        helmetLight.Color = Color3.fromRGB(255, 240, 160)
        helmetLight.Parent = hatLamp

        showWarning("Miner Helmet equipped! Light source active.", 3)
    end)
end

-- =================================================================
-- ROOM GENERATION
-- =================================================================
generateRoom = function(doorNum)
    if rooms[doorNum] then return end

    local folder = Instance.new("Folder")
    folder.Name = "Room_" .. doorNum
    folder.Parent = workspace

    local originZ = -(doorNum * CAVE_D)
    local O       = Vector3.new(0, 0, originZ)
    local lockerList = {}

    local isDark    = math.random(1, 100) <= 50
    local isLocked  = math.random(1, 100) <= 35
    local numCarts  = math.random(2, 4)
    local numHide   = math.random(1, 2)

    roomIsDark[doorNum] = isDark

    local roomW = CAVE_W + math.random(0, 2) * 5
    local roomH = CAVE_H
    local roomD = CAVE_D

    local floorColor  = Color3.fromRGB(38, 36, 34)
    local wallColor   = Color3.fromRGB(45, 43, 40)
    local ceilColor   = Color3.fromRGB(33, 31, 30)

    makePart(Vector3.new(roomW, 1, roomD), CFrame.new(O + Vector3.new(0, -0.5, 0)), floorColor, 0, folder, Enum.Material.Slate).Name = "CaveFloor"
    makePart(Vector3.new(roomW, 1, roomD), CFrame.new(O + Vector3.new(0, roomH + 0.5, 0)), ceilColor, 0, folder, Enum.Material.Slate).Name = "CaveCeiling"
    makePart(Vector3.new(1, roomH, roomD), CFrame.new(O + Vector3.new(-roomW * 0.5 - 0.5, roomH * 0.5, 0)), wallColor, 0, folder, Enum.Material.Cobblestone).Name = "CaveWallL"
    makePart(Vector3.new(1, roomH, roomD), CFrame.new(O + Vector3.new(roomW * 0.5 + 0.5, roomH * 0.5, 0)), wallColor, 0, folder, Enum.Material.Cobblestone).Name = "CaveWallR"

    local halfGap = 3.5
    local sideW   = (roomW - halfGap * 2) * 0.5

    -- Back wall with doorway opening hole
    makePart(Vector3.new(sideW, roomH, 1), CFrame.new(O + Vector3.new(-(halfGap + sideW * 0.5), roomH * 0.5, roomD * 0.5 + 0.5)), wallColor, 0, folder, Enum.Material.Cobblestone).Name = "BackWallL"
    makePart(Vector3.new(sideW, roomH, 1), CFrame.new(O + Vector3.new(halfGap + sideW * 0.5, roomH * 0.5, roomD * 0.5 + 0.5)), wallColor, 0, folder, Enum.Material.Cobblestone).Name = "BackWallR"
    makePart(Vector3.new(halfGap * 2, roomH - 8, 1), CFrame.new(O + Vector3.new(0, roomH - (roomH - 8) * 0.5, roomD * 0.5 + 0.5)), wallColor, 0, folder, Enum.Material.Cobblestone).Name = "BackWallTop"

    -- Front wall with doorway opening hole
    makePart(Vector3.new(sideW, roomH, 1), CFrame.new(O + Vector3.new(-(halfGap + sideW * 0.5), roomH * 0.5, -roomD * 0.5 - 0.5)), wallColor, 0, folder, Enum.Material.Cobblestone).Name = "FrontWallL"
    makePart(Vector3.new(sideW, roomH, 1), CFrame.new(O + Vector3.new(halfGap + sideW * 0.5, roomH * 0.5, -roomD * 0.5 - 0.5)), wallColor, 0, folder, Enum.Material.Cobblestone).Name = "FrontWallR"
    makePart(Vector3.new(halfGap * 2, roomH - 8, 1), CFrame.new(O + Vector3.new(0, roomH - (roomH - 8) * 0.5, -roomD * 0.5 - 0.5)), wallColor, 0, folder, Enum.Material.Cobblestone).Name = "FrontWallTop"

    -- Door frame stone arch
    makePart(Vector3.new(0.8, 9, 1.2), CFrame.new(O + Vector3.new(-halfGap - 0.4, 4.5, -roomD * 0.5 - 0.5)), Color3.fromRGB(62, 58, 54), 0, folder, Enum.Material.Cobblestone).Name = "DoorFrameL"
    makePart(Vector3.new(0.8, 9, 1.2), CFrame.new(O + Vector3.new(halfGap + 0.4, 4.5, -roomD * 0.5 - 0.5)), Color3.fromRGB(62, 58, 54), 0, folder, Enum.Material.Cobblestone).Name = "DoorFrameR"
    makePart(Vector3.new(halfGap * 2 + 1.6, 0.8, 1.2), CFrame.new(O + Vector3.new(0, 9, -roomD * 0.5 - 0.5)), Color3.fromRGB(62, 58, 54), 0, folder, Enum.Material.Cobblestone).Name = "DoorFrameTop"

    if isLocked then
        local lockedDoor = makePart(Vector3.new(halfGap * 2, 8.8, 0.6), CFrame.new(O + Vector3.new(0, 4.4, -roomD * 0.5 - 0.5)), Color3.fromRGB(70, 50, 25), 0, folder, Enum.Material.Wood)
        lockedDoor.Name = "LockedDoor"
        for pi = 0, 3 do
            makePart(Vector3.new(halfGap * 2 + 0.1, 0.3, 0.7), CFrame.new(O + Vector3.new(0, 1.2 + pi * 2.1, -roomD * 0.5 - 0.5)), Color3.fromRGB(55, 38, 18), 0, folder, Enum.Material.Wood).Name = "DoorPlank"
        end

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Use Key"
        prompt.RequiresLineOfSight = false
        prompt.Parent = lockedDoor
        prompt.Triggered:Connect(function()
            local char = player.Character
            if char and char:FindFirstChild("Key") then
                char.Key:Destroy()
                lockedDoor:Destroy()
                for i, v in ipairs(inventory) do
                    if v == "Key" then table.remove(inventory, i) break end
                end
                showWarning("Door unlocked!", 2)
            else
                showWarning("You need a Key to open this!", 2)
            end
        end)
    end

    local signPart = makePart(Vector3.new(halfGap * 2 + 2, 1.6, 0.4), CFrame.new(O + Vector3.new(0, 10.2, -roomD * 0.5 - 0.2)), Color3.fromRGB(28, 26, 24), 0, folder, Enum.Material.Slate)
    signPart.Name = "DoorSign"
    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = signPart
    local signLabel = Instance.new("TextLabel")
    signLabel.Size = UDim2.new(1, 0, 1, 0)
    signLabel.BackgroundTransparency = 1
    signLabel.Text = tostring(doorNum + 1)
    signLabel.TextColor3 = Color3.fromRGB(200, 180, 140)
    signLabel.TextScaled = true
    signLabel.Font = Enum.Font.GothamBold
    signLabel.Parent = signGui

    if doorNum > DOOR_START and (doorNum - DOOR_START) % CHECKPOINT_EVERY == 0 then
        local cpPart = makePart(Vector3.new(10, 2.5, 0.4), CFrame.new(O + Vector3.new(0, 6, 0)), Color3.fromRGB(12, 80, 12), 0, folder, Enum.Material.Neon)
        cpPart.Name = "CheckpointSign"
        local cpGui = Instance.new("SurfaceGui")
        cpGui.Face = Enum.NormalId.Front
        cpGui.Parent = cpPart
        local cpLabel = Instance.new("TextLabel")
        cpLabel.Size = UDim2.new(1, 0, 1, 0)
        cpLabel.BackgroundTransparency = 1
        cpLabel.Text = "CHECKPOINT  -  Cave Door " .. doorNum
        cpLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        cpLabel.TextScaled = true
        cpLabel.Font = Enum.Font.GothamBold
        cpLabel.Parent = cpGui
    end

    if not isDark then
        local numLights = math.random(2, 4)
        for li = 1, numLights do
            local lx = math.random(-math.floor(roomW * 0.35), math.floor(roomW * 0.35))
            local lz = math.random(-math.floor(roomD * 0.35), math.floor(roomD * 0.35))
            makePart(Vector3.new(0.15, 2, 0.15), CFrame.new(O + Vector3.new(lx, roomH - 0.5, lz)), Color3.fromRGB(60, 55, 50), 0, folder, Enum.Material.Metal).Name = "LanternChain"
            local lantern = makePart(Vector3.new(1.2, 1.4, 1.2), CFrame.new(O + Vector3.new(lx, roomH - 2.4, lz)), Color3.fromRGB(255, 210, 100), 0, folder, Enum.Material.Neon)
            lantern.Name = "Lantern"
            makeLight(lantern, 1.8, 30, Color3.fromRGB(255, 210, 110))
        end
    end

    for si = 1, math.random(4, 9) do
        makeStalactite(folder, roomH, O.X + math.random(-math.floor(roomW * 0.42), math.floor(roomW * 0.42)), O.Z + math.random(-math.floor(roomD * 0.42), math.floor(roomD * 0.42)))
    end

    for si = 1, math.random(2, 5) do
        spawnSpikyRock(folder, O + Vector3.new(math.random(-math.floor(roomW * 0.38), math.floor(roomW * 0.38)), 0, math.random(-math.floor(roomD * 0.38), math.floor(roomD * 0.38))))
    end

    for pi = 1, math.random(1, 3) do
        makeRockPile(folder, O + Vector3.new(math.random(-math.floor(roomW * 0.4), math.floor(roomW * 0.4)), 0, math.random(-math.floor(roomD * 0.4), math.floor(roomD * 0.4))))
    end

    local roll = math.random(1, 10)
    if roll <= 7 then makeCrate(folder, O + Vector3.new(math.random(-12, 12), 0, math.random(-20, 20))) end
    if roll <= 6 then 
        makeBarrel(folder, O + Vector3.new(math.random(-12, 12), 0, math.random(-20, 20))) 
        makeBarrel(folder, O + Vector3.new(math.random(-12, 12), 0, math.random(-20, 20))) 
    end

    local numLockers = isLocked and math.random(4, 9) or math.random(1, 3)
    for _ = 1, numLockers do
        local lpos = O + Vector3.new(math.random(-10, 10), 0, math.random(-20, 20))
        makeLocker(folder, lpos, lockerList)
    end

    local hideCartCount = 0
    for ci = 1, numCarts do
        local cx = math.random(-math.floor(roomW * 0.35), math.floor(roomW * 0.35))
        local cz = math.random(-math.floor(roomD * 0.35), math.floor(roomD * 0.35))
        local isThisHide = (hideCartCount < numHide)
        if isThisHide then hideCartCount = hideCartCount + 1 end
        makeMinecart(folder, O + Vector3.new(cx, 0, cz), isThisHide)
    end

    local keysNeeded = isLocked and 1 or 0
    for ki = 1, keysNeeded do
        if #lockerList > 0 then
            lockerList[math.random(1, #lockerList)]:SetAttribute("Loot", "Key")
        else
            local fallbackLocker = makeLocker(folder, O + Vector3.new(0, 0, 0), lockerList)
            fallbackLocker:SetAttribute("Loot", "Key")
        end
    end

    rooms[doorNum] = folder
end

-- =================================================================
-- CAVE LOBBY (entrance zone)
-- =================================================================
createLobby = function()
    local folder = Instance.new("Folder")
    folder.Name = "CaveLobby"
    folder.Parent = workspace

    makePart(Vector3.new(55, 1, 70), CFrame.new(0, -0.5, 35), Color3.fromRGB(38, 36, 34), 0, folder, Enum.Material.Slate).Name = "LobbyFloor"
    makePart(Vector3.new(55, 1, 70), CFrame.new(0, CAVE_H + 0.5, 35), Color3.fromRGB(30, 28, 27), 0, folder, Enum.Material.Slate).Name = "LobbyCeiling"
    makePart(Vector3.new(55, CAVE_H, 1), CFrame.new(0, CAVE_H * 0.5, 70.5), Color3.fromRGB(45, 43, 40), 0, folder, Enum.Material.Cobblestone).Name = "LobbyWallBack"
    makePart(Vector3.new(1, CAVE_H, 70), CFrame.new(-27.5, CAVE_H * 0.5, 35), Color3.fromRGB(45, 43, 40), 0, folder, Enum.Material.Cobblestone).Name = "LobbyWallL"
    makePart(Vector3.new(1, CAVE_H, 70), CFrame.new(27.5, CAVE_H * 0.5, 35), Color3.fromRGB(45, 43, 40), 0, folder, Enum.Material.Cobblestone).Name = "LobbyWallR"

    local lobbyLights = {Vector3.new(-14, CAVE_H - 2, 20), Vector3.new(14, CAVE_H - 2, 20), Vector3.new(-14, CAVE_H - 2, 50), Vector3.new(14, CAVE_H - 2, 50), Vector3.new(0, CAVE_H - 2, 35)}
    for _, lp in ipairs(lobbyLights) do
        makePart(Vector3.new(0.15, 2, 0.15), CFrame.new(lp + Vector3.new(0, 1.2, 0)), Color3.fromRGB(60, 55, 50), 0, folder, Enum.Material.Metal)
        local lan = makePart(Vector3.new(1.2, 1.4, 1.2), CFrame.new(lp), Color3.fromRGB(255, 210, 100), 0, folder, Enum.Material.Neon)
        lan.Name = "Lantern"
        makeLight(lan, 2.2, 40, Color3.fromRGB(255, 210, 110))
    end

    local signBoard = makePart(Vector3.new(22, 4.5, 0.5), CFrame.new(0, 14, 69), Color3.fromRGB(22, 20, 18), 0, folder, Enum.Material.Slate)
    signBoard.Name = "WelcomeSign"
    local wsGui = Instance.new("SurfaceGui")
    wsGui.Face = Enum.NormalId.Front
    wsGui.Parent = signBoard
    local wsLine1 = Instance.new("TextLabel")
    wsLine1.Size = UDim2.new(1, 0, 0.55, 0)
    wsLine1.BackgroundTransparency = 1
    wsLine1.Text = "THE CAVES"
    wsLine1.TextColor3 = Color3.fromRGB(200, 170, 100)
    wsLine1.TextScaled = true
    wsLine1.Font = Enum.Font.GothamBold
    wsLine1.Parent = wsGui
    local wsLine2 = Instance.new("TextLabel")
    wsLine2.Size = UDim2.new(1, 0, 0.4, 0)
    wsLine2.Position = UDim2.new(0, 0, 0.58, 0)
    wsLine2.BackgroundTransparency = 1
    wsLine2.Text = "Survive from Cave Door 230 to 1000  |  Hide in minecarts!"
    wsLine2.TextColor3 = Color3.fromRGB(160, 145, 120)
    wsLine2.TextScaled = true
    wsLine2.Font = Enum.Font.Gotham
    wsLine2.Parent = wsGui

    makeCrate(folder, Vector3.new(-14, 0, 44))
    makeCrate(folder, Vector3.new(14, 0, 44))
    makeBarrel(folder, Vector3.new(-18, 0, 32))
    makeBarrel(folder, Vector3.new(18, 0, 32))
    makeBarrel(folder, Vector3.new(-20, 0, 28))
    makeRockPile(folder, Vector3.new(-10, 0, 58))
    makeRockPile(folder, Vector3.new(10, 0, 58))
    makeMinecart(folder, Vector3.new(-14, 0, 54), false)
    makeMinecart(folder, Vector3.new(14, 0, 54), false)

    for i = 1, 12 do
        makeStalactite(folder, CAVE_H, math.random(-24, 24), math.random(10, 68))
    end

    local startBtn = makePart(Vector3.new(8, 3, 3.5), CFrame.new(0, 1.5, 16), Color3.fromRGB(0, 140, 60), 0, folder, Enum.Material.Neon)
    startBtn.Name = "StartButton"
    local sbGui = Instance.new("SurfaceGui")
    sbGui.Face = Enum.NormalId.Front
    sbGui.Parent = startBtn
    local sbLabel = Instance.new("TextLabel")
    sbLabel.Size = UDim2.new(1, 0, 1, 0)
    sbLabel.BackgroundTransparency = 1
    sbLabel.Text = "ENTER THE CAVES"
    sbLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    sbLabel.TextScaled = true
    sbLabel.Font = Enum.Font.GothamBold
    sbLabel.Parent = sbGui
    makeLight(startBtn, 3, 20, Color3.fromRGB(0, 200, 80))

    local startGui = Instance.new("ScreenGui")
    startGui.Name = "CaveStartGui"
    startGui.ResetOnSpawn = false
    startGui.Parent = player.PlayerGui

    local startFrame = Instance.new("Frame")
    startFrame.Size = UDim2.new(0, 280, 0, 65)
    startFrame.Position = UDim2.new(0.5, -140, 0.83, 0)
    startFrame.BackgroundColor3 = Color3.fromRGB(0, 100, 40)
    startFrame.BackgroundTransparency = 0.2
    startFrame.BorderSizePixel = 0
    startFrame.Visible = false
    startFrame.Name = "StartFrame"
    startFrame.Parent = startGui
    local sfC = Instance.new("UICorner")
    sfC.CornerRadius = UDim.new(0, 14)
    sfC.Parent = startFrame

    local startBtnUI = Instance.new("TextButton")
    startBtnUI.Size = UDim2.new(1, 0, 1, 0)
    startBtnUI.BackgroundTransparency = 1
    startBtnUI.Text = "[TAP TO ENTER CAVES]"
    startBtnUI.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtnUI.TextScaled = true
    startBtnUI.Font = Enum.Font.GothamBold
    startBtnUI.Parent = startFrame

    startBtnUI.MouseButton1Click:Connect(function()
        if not gameStarted then
            startGui:Destroy()
            startGame()
        end
    end)

    RunService.Heartbeat:Connect(function()
        if gameStarted or not rootPart then return end
        if not startGui.Parent then return end
        local dist = (rootPart.Position - startBtn.Position).Magnitude
        startFrame.Visible = dist < 12
    end)

    rooms[-1] = folder
    if character then character:PivotTo(CFrame.new(0, 3, 48)) end
end

-- =================================================================
-- MINECART HIDING
-- =================================================================
hideInCart = function()
    if not currentCart or isHiding or not humanoid then return end
    isHiding = true
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            hiddenParts[part] = part.Transparency
            part.Transparency = 1
        end
    end
    if hideBtnLabel then hideBtnLabel.Text = "[EXIT CART]" end
end

exitCart = function()
    if not isHiding or not humanoid then return end
    isHiding = false
    humanoid.JumpPower = 50
    for part, trans in pairs(hiddenParts) do
        if part and part.Parent then part.Transparency = trans end
    end
    table.clear(hiddenParts)
    if hideBtnLabel then hideBtnLabel.Text = "[HIDE IN CART]" end
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
    isDead      = true
    gameStarted = false
    isHiding    = false

    if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end

    inventory     = {}
    ecstasyActive = false
    helmetEquipped = false
    helmetLight    = nil
    local ccc = game.Lighting:FindFirstChild("EcstasyCC")
    if ccc then ccc:Destroy() end

    local deathGui = Instance.new("ScreenGui")
    deathGui.Name = "CaveDeathGui"
    deathGui.ResetOnSpawn = false
    deathGui.Parent = player.PlayerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    bg.BackgroundTransparency = 0.45
    bg.BorderSizePixel = 0
    bg.Parent = deathGui

    local dl = Instance.new("TextLabel")
    dl.Size = UDim2.new(1, 0, 0.28, 0)
    dl.Position = UDim2.new(0, 0, 0.32, 0)
    dl.BackgroundTransparency = 1
    dl.Text = "YOU DIED IN THE CAVES"
    dl.TextColor3 = Color3.fromRGB(255, 255, 255)
    dl.TextScaled = true
    dl.Font = Enum.Font.GothamBold
    dl.Parent = bg

    local sl = Instance.new("TextLabel")
    sl.Size = UDim2.new(1, 0, 0.1, 0)
    sl.Position = UDim2.new(0, 0, 0.60, 0)
    sl.BackgroundTransparency = 1
    sl.Text = "Returning to checkpoint: Cave Door " .. tostring(checkpointDoor)
    sl.TextColor3 = Color3.fromRGB(255, 180, 180)
    sl.TextScaled = true
    sl.Font = Enum.Font.Gotham
    sl.Parent = bg

    player.CharacterAdded:Wait()
    task.wait(0.3)

    deathGui:Destroy()
    isDead = false

    if character and rootPart then
        local cpZ = -(checkpointDoor * CAVE_D) + CAVE_D * 0.35
        character:PivotTo(CFrame.new(0, 3, cpZ))
    end

    currentDoor       = checkpointDoor
    lastDetectedDoor  = checkpointDoor
    if doorLabel then doorLabel.Text = "Cave Door: " .. tostring(checkpointDoor) end
    gameStarted = true

    for i = checkpointDoor, checkpointDoor + GEN_AHEAD do
        if i <= DOOR_MAX then generateRoom(i) end
    end
end

-- =================================================================
-- ENTITIES
-- =================================================================
spawnDisease = function(doorNum)
    if diseaseActive or diseaseOnCooldown then return end
    diseaseActive   = true
    diseaseOnCooldown = true

    local ef = Instance.new("Folder")
    ef.Name = "DiseaseEntity"
    ef.Parent = workspace

    local startDoor = doorNum - DISEASE_BEFORE
    local stopDoor  = doorNum + DISEASE_AFTER
    local startZ    = -(startDoor * CAVE_D)
    local stopZ     = -(stopDoor * CAVE_D)

    for d = startDoor, stopDoor do
        if rooms[d] then
            local smoke = Instance.new("ParticleEmitter")
            smoke.Name = "DiseaseSmoke"
            smoke.Color = ColorSequence.new(Color3.fromRGB(180, 0, 0))
            smoke.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 8), NumberSequenceKeypoint.new(1, 18)})
            smoke.Rate = 80
            smoke.Speed = NumberRange.new(2, 4)
            smoke.Lifetime = NumberRange.new(3, 5)
            smoke.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1)})
            local ep = makePart(Vector3.new(CAVE_W, 1, CAVE_D), CFrame.new(0, CAVE_H * 0.5, -(d * CAVE_D)), Color3.new(), 1, ef)
            smoke.Parent = ep
        end
    end

    local body = makePart(Vector3.new(CAVE_W - 1, CAVE_H, CAVE_D), CFrame.new(0, CAVE_H * 0.5, startZ), Color3.fromRGB(140, 0, 0), 0.45, ef, Enum.Material.Neon)
    body.Name = "DiseaseBody"
    body.CanCollide = false

    local trail = Instance.new("Trail")
    trail.Color = ColorSequence.new(Color3.fromRGB(220, 0, 0))
    trail.Lifetime = 1.8
    trail.Parent = body
    local da0 = Instance.new("Attachment", body); da0.Position = Vector3.new(0, 5, 0)
    local da1 = Instance.new("Attachment", body); da1.Position = Vector3.new(0, -5, 0)
    trail.Attachment0 = da0
    trail.Attachment1 = da1

    local snd = Instance.new("Sound")
    snd.SoundId = "rbxassetid://125795970503985"
    snd.Volume = 1.5
    snd.Looped = true
    snd.RollOffMaxDistance = 200
    snd.Parent = body
    snd:Play()

    local moveConn
    moveConn = RunService.Heartbeat:Connect(function(dt)
        if not body or not body.Parent then moveConn:Disconnect() return end
        local newZ = body.CFrame.Position.Z - DISEASE_SPEED * dt
        body.CFrame = CFrame.new(body.CFrame.Position.X, body.CFrame.Position.Y, newZ)

        if rootPart and humanoid and not isDead then
            local distZ = math.abs(rootPart.Position.Z - newZ)
            if distZ < 140 then
                local intensity = (140 - distZ) / 140
                humanoid.CameraOffset = Vector3.new(math.random(-10, 10) * 0.05 * intensity, math.random(-10, 10) * 0.05 * intensity, 0)
            else
                humanoid.CameraOffset = Vector3.new(0, 0, 0)
            end
            if not isHiding and distZ < CAVE_D * 0.45 then
                if humanoid.Health > 0 then humanoid.Health = 0; onDeath() end
            end
        end

        if newZ <= stopZ then
            moveConn:Disconnect()
            snd:Stop()
            diseaseActive = false
            if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
            local step = 0
            local fc
            fc = RunService.Heartbeat:Connect(function()
                step = step + 1
                if body and body.Parent then body.Transparency = 0.45 + step * 0.06 end
                if step >= 10 then fc:Disconnect(); ef:Destroy() end
            end)
            task.delay(DISEASE_COOLDOWN, function() diseaseOnCooldown = false end)
        end
    end)
end

spawnHer = function(doorNum)
    if herActive or herOnCooldown then return end
    herActive   = true
    herOnCooldown = true

    local roomZ = -(doorNum * CAVE_D)

    local ef = Instance.new("Folder")
    ef.Name = "HerEntity"
    ef.Parent = workspace

    local body = makePart(Vector3.new(1.8, 7.5, 1.8), CFrame.new(0, 3.75, roomZ), Color3.fromRGB(0, 0, 0), 0, ef)
    body.Name = "HerBody"
    body.CanCollide = false

    local snd = Instance.new("Sound")
    snd.SoundId = "rbxassetid://129136912774651"
    snd.Volume = 2
    snd.Looped = true
    snd.RollOffMaxDistance = 100
    snd.Parent = body
    snd:Play()

    local lookTimer = 0
    local isChasing = false
    local herConn

    herConn = RunService.Heartbeat:Connect(function(dt)
        if not body or not body.Parent or isDead then
            if herConn then herConn:Disconnect() end
            return
        end

        if not isChasing then
            if rootPart and camera then
                local toHer   = (body.Position - camera.CFrame.Position).Unit
                local lookDir = camera.CFrame.LookVector
                local dot     = lookDir:Dot(toHer)

                if dot > 0.75 then
                    lookTimer = lookTimer + dt
                else
                    lookTimer = math.max(0, lookTimer - dt)
                end

                if lookTimer >= 3 then
                    isChasing = true
                    snd:Stop()
                    snd.SoundId = "rbxassetid://108968287863512"
                    snd.Volume = 3
                    snd:Play()
                    body.Color = Color3.fromRGB(22, 0, 0)
                end
            end

            if currentDoor > doorNum + 2 then
                herConn:Disconnect()
                ef:Destroy()
                herActive = false
                task.delay(HER_COOLDOWN, function() herOnCooldown = false end)
            end
        else
            if rootPart then
                local lookCF = CFrame.lookAt(body.Position, rootPart.Position)
                body.CFrame = lookCF + lookCF.LookVector * HER_SPEED * dt
                body.CFrame = CFrame.new(body.Position.X, 3.75, body.Position.Z)

                local dist = (rootPart.Position - body.Position).Magnitude
                if dist < 90 and humanoid then
                    local intensity = (90 - dist) / 90
                    humanoid.CameraOffset = Vector3.new(math.random(-10, 10) * 0.07 * intensity, math.random(-10, 10) * 0.07 * intensity, 0)
                end

                if dist < 4 and humanoid and humanoid.Health > 0 then
                    humanoid.Health = 0
                    onDeath()
                end

                if not roomIsDark[currentDoor] then
                    herConn:Disconnect()
                    snd:Stop()
                    if humanoid then humanoid.CameraOffset = Vector3.new(0, 0, 0) end
                    ef:Destroy()
                    herActive = false
                    task.delay(HER_COOLDOWN, function() herOnCooldown = false end)
                end
            end
        end
    end)
end

spawnVoid = function(doorNum)
    if voidActive or voidOnCooldown then return end
    voidActive   = true
    voidOnCooldown = true

    local roomZ = -(doorNum * CAVE_D)

    local voidPart = makePart(Vector3.new(5, 0.1, 5), CFrame.new(0, -0.4, roomZ), Color3.fromRGB(5, 5, 5), 0, workspace, Enum.Material.Neon)
    voidPart.Name = "VoidSubstance"
    voidPart.CanCollide = false

    local particles = Instance.new("ParticleEmitter", voidPart)
    particles.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
    particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 5)})
    particles.Rate  = 55
    particles.Speed = NumberRange.new(4, 10)

    local expSnd = Instance.new("Sound", voidPart)
    expSnd.SoundId = "rbxassetid://140328974468167"
    expSnd.Looped  = true
    expSnd.PlaybackSpeed = 0.01
    expSnd.Volume  = 2
    expSnd.RollOffMaxDistance = 200
    expSnd:Play()

    local expansionTime = 14
    local maxSize       = 90
    local startTime     = tick()

    local vc
    vc = RunService.Heartbeat:Connect(function()
        if not voidPart or not voidPart.Parent then vc:Disconnect() return end

        local elapsed  = tick() - startTime
        local progress = math.min(1, elapsed / expansionTime)
        local curSize  = 5 + (maxSize - 5) * progress
        voidPart.Size = Vector3.new(curSize, 0.1, curSize)
        expSnd.PlaybackSpeed = 0.01 + (1.99 * progress)

        if rootPart and humanoid and humanoid.Health > 0 and not isDead and not isHiding then
            local pPos = rootPart.Position
            local vPos = voidPart.Position
            local dist = math.sqrt((pPos.X - vPos.X)^2 + (pPos.Z - vPos.Z)^2)
            if dist <= (curSize / 2) and math.abs(pPos.Y - vPos.Y) < 10 then
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

    task.delay(28, function()
        voidActive = false
        if vc then vc:Disconnect() end
        if voidPart and voidPart.Parent then voidPart:Destroy() end
    end)

    task.delay(VOID_COOLDOWN, function() voidOnCooldown = false end)
end

-- =================================================================
-- DOOR REACHED
-- =================================================================
onDoorReached = function(doorNum)
    currentDoor = doorNum
    if doorLabel then doorLabel.Text = "Cave Door: " .. tostring(doorNum) end

    if doorNum > DOOR_START and (doorNum - DOOR_START) % CHECKPOINT_EVERY == 0 then
        checkpointDoor = doorNum
        showWarning("CHECKPOINT SAVED  -  Cave Door " .. tostring(doorNum), 3)
    end

    for i = doorNum + 1, doorNum + GEN_AHEAD do
        if i <= DOOR_MAX then generateRoom(i) end
    end

    for i = DOOR_START, doorNum - CLEAN_BEHIND do
        if rooms[i] then rooms[i]:Destroy(); rooms[i] = nil end
        roomIsDark[i] = nil
    end

    if doorNum >= HER_START and not herActive and not herOnCooldown then
        if roomIsDark[doorNum] and math.random(1, 100) <= 28 then task.spawn(function() spawnHer(doorNum) end) end
    end

    if not diseaseActive and not diseaseOnCooldown and doorNum >= DOOR_START + 5 then
        if math.random(1, 100) <= 40 then spawnDisease(doorNum) end
    end

    if doorNum >= VOID_START and not voidActive and not voidOnCooldown then
        if math.random(1, 100) <= VOID_CHANCE then task.spawn(function() spawnVoid(doorNum) end) end
    end

    if doorNum >= DOOR_MAX then
        showWarning("YOU ESCAPED THE CAVES! Congratulations, brave miner!", 20)
        gameStarted = false
    end
end

-- =================================================================
-- START GAME
-- =================================================================
startGame = function()
    gameStarted      = true
    currentDoor      = DOOR_START
    lastDetectedDoor = DOOR_START
    checkpointDoor   = DOOR_START
    if character then
        character:PivotTo(CFrame.new(0, 3, -(DOOR_START * CAVE_D) + CAVE_D * 0.45))
    end
    for i = DOOR_START, DOOR_START + GEN_AHEAD do
        generateRoom(i)
    end
end

-- =================================================================
-- CHARACTER REF
-- =================================================================
updateCharRef = function(newChar)
    character = newChar
    humanoid  = newChar:WaitForChild("Humanoid")
    rootPart  = newChar:WaitForChild("HumanoidRootPart")

    task.spawn(function()
        local runSnd = rootPart:WaitForChild("Running", 3)
        if runSnd then runSnd.Volume = 0 end
    end)

    floorStepSound = Instance.new("Sound")
    floorStepSound.SoundId = "rbxassetid://138898236956764"
    floorStepSound.Volume  = 1
    floorStepSound.Parent  = rootPart

    humanoid.Died:Connect(function() onDeath() end)
end

-- =================================================================
-- MAIN LOOP
-- =================================================================
mainLoop = function()
    RunService.Heartbeat:Connect(function(dt)
        if not gameStarted or not rootPart then return end

        local targetSpeed = 16
        if ecstasyActive then
            if tick() > ecstasyEndTime then
                ecstasyActive = false
                local ccc = game.Lighting:FindFirstChild("EcstasyCC")
                if ccc then ccc:Destroy() end
            else
                targetSpeed = 22
            end
        end
        if tick() < speedPenaltyEnd then
            targetSpeed = targetSpeed - 3
        end
        if not isHiding and humanoid and not diseaseActive then
            humanoid.WalkSpeed = targetSpeed
        end

        if humanoid and humanoid.Health > 0 and not isHiding then
            local isMoving = humanoid.MoveDirection.Magnitude > 0
            if isMoving and humanoid.FloorMaterial ~= Enum.Material.Air then
                local speedRatio  = humanoid.WalkSpeed / 16
                local stepInterval = 0.38 / math.max(0.1, speedRatio)
                if tick() - lastStepTime >= stepInterval then
                    lastStepTime = tick()
                    if floorStepSound then
                        floorStepSound.PlaybackSpeed = speedRatio
                        floorStepSound:Play()
                    end
                end
            else
                lastStepTime = 0
            end
        end

        local playerZ   = rootPart.Position.Z
        local approxDoor = math.max(DOOR_START, math.floor(-playerZ / CAVE_D + 0.5))
        if approxDoor > lastDetectedDoor and approxDoor <= DOOR_MAX then
            lastDetectedDoor = approxDoor
            onDoorReached(approxDoor)
        end

        nearCart    = false
        currentCart = nil
        for d = currentDoor - 1, currentDoor + 1 do
            if rooms[d] then
                for _, part in ipairs(rooms[d]:GetDescendants()) do
                    if part:IsA("BasePart") and part:GetAttribute("IsLocker") then
                        if (rootPart.Position - part.Position).Magnitude < CART_DIST then
                            nearCart    = true
                            currentCart = part
                        end
                    end
                end
            end
        end

        if hidePrompt then
            hidePrompt.Visible = (nearCart and not isHiding) or isHiding
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
