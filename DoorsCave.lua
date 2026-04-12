-- ============================================================
-- THE CAVES - LocalScript Executor
-- Devious Goober  |  Starts at Door 230  |  Stage 2
-- Entities : Disease, Her, Void, Drain, Ghoul, Agony
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

local BRIDGE_START     = 290
local BRIDGE_CHANCE    = 20
local BRIDGE_W         = 100
local BRIDGE_H         = 60
local BRIDGE_D         = 140
local PIT_DEPTH        = 80

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

local DRAIN_START      = 250
local DRAIN_CHANCE     = 40
local DRAIN_COOLDOWN   = 35

local GHOUL_START      = 275
local GHOUL_CHANCE     = 27
local GHOUL_COOLDOWN   = 60

local AGONY_START      = 315
local AGONY_CHANCE     = 25
local AGONY_SPEED      = 95
local AGONY_COOLDOWN   = 20

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
local roomIsBridge     = {}
local roomZData        = {}
local bridgeStates     = {}
local bridgeSounds     = {}

local diseaseActive    = false
local diseaseOnCooldown = false
local herActive        = false
local herOnCooldown    = false
local voidActive       = false
local voidOnCooldown   = false
local drainActive      = false
local drainOnCooldown  = false
local ghoulActive      = false
local ghoulOnCooldown  = false
local ghoulSpawnDoor   = 0
local agonyActive      = false
local agonyOnCooldown  = false

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
local hideInCart, exitCart, giveTool, giveHelmet, breakBridge
local spawnDisease, spawnHer, spawnVoid, spawnDrain, spawnGhoul, spawnAgony
local onDoorReached, onDeath, updateCharRef, mainLoop
local getIsBridge, getRoomZ

-- =================================================================
-- SPATIAL HELPERS
-- =================================================================
getIsBridge = function(doorNum)
    if roomIsBridge[doorNum] ~= nil then return roomIsBridge[doorNum] end
    roomIsBridge[doorNum] = (doorNum >= BRIDGE_START and math.random(1, 100) <= BRIDGE_CHANCE)
    return roomIsBridge[doorNum]
end

getRoomZ = function(doorNum)
    if roomZData[doorNum] then return roomZData[doorNum] end
    local z = DOOR_START * CAVE_D
    for i = DOOR_START + 1, doorNum do
        local prevLen = getIsBridge(i-1) and BRIDGE_D or CAVE_D
        local thisLen = getIsBridge(i) and BRIDGE_D or CAVE_D
        z = z + (prevLen * 0.5) + (thisLen * 0.5)
    end
    roomZData[doorNum] = z
    return z
end

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

giveTool = function(plr, toolName, color, size)
    local tool = Instance.new("Tool"); tool.Name = toolName
    local handle = Instance.new("Part"); handle.Name = "Handle"
    handle.Size = size or Vector3.new(0.8,0.5,0.5)
    handle.Color = color or Color3.fromRGB(180,180,180)
    handle.Material = Enum.Material.Metal; handle.Parent = tool
    tool.Parent = plr.Backpack
    return tool
end

giveHelmet = function(plr)
    if #inventory >= MAX_ITEMS then showWarning("Inventory full! Max " .. MAX_ITEMS .. " items.", 2); return end
    if helmetEquipped then showWarning("Helmet already equipped!", 2); return end
    table.insert(inventory, "MinerHelmet")
    local tool = Instance.new("Tool"); tool.Name = "MinerHelmet"
    local handle = Instance.new("Part"); handle.Name = "Handle"
    handle.Size = Vector3.new(1.4,1,1.4); handle.Color = Color3.fromRGB(38,80,120)
    handle.Material = Enum.Material.Metal; handle.Parent = tool
    tool.Parent = plr.Backpack

    tool.Activated:Connect(function()
        if helmetEquipped then return end
        for idx, v in ipairs(inventory) do if v == "MinerHelmet" then table.remove(inventory, idx); break end end
        tool:Destroy(); helmetEquipped = true
        local char = player.Character; if not char then return end
        local head = char:FindFirstChild("Head"); if not head then return end

        local hatPart = Instance.new("Part"); hatPart.Name = "MinerHat"
        hatPart.Size = Vector3.new(1.6,1.1,1.6); hatPart.Color = Color3.fromRGB(38,80,120); hatPart.Material = Enum.Material.Metal
        hatPart.CanCollide = false; hatPart.Anchored = false; hatPart.Parent = char
        local hw = Instance.new("Weld"); hw.Part0 = head; hw.Part1 = hatPart; hw.C0 = CFrame.new(0,0.7,0); hw.Parent = hatPart

        local hatLamp = Instance.new("Part"); hatLamp.Name = "HatLamp"
        hatLamp.Size = Vector3.new(0.45,0.4,0.45); hatLamp.Color = Color3.fromRGB(255,245,180); hatLamp.Material = Enum.Material.Neon
        hatLamp.CanCollide = false; hatLamp.Anchored = false; hatLamp.Parent = char
        local lw2 = Instance.new("Weld"); lw2.Part0 = hatPart; lw2.Part1 = hatLamp; lw2.C0 = CFrame.new(0,0.2,-0.65); lw2.Parent = hatLamp

        helmetLight = Instance.new("PointLight")
        helmetLight.Brightness = 2.5; helmetLight.Range = 38
        helmetLight.Color = Color3.fromRGB(255,240,160); helmetLight.Parent = hatLamp
    end)
end

-- =================================================================
-- DECORATIONS
-- =================================================================
makeCrate = function(folder, pos)
    local body = makePart(Vector3.new(2.5,2.5,2.5),CFrame.new(pos+Vector3.new(0,1.25,0)),Color3.fromRGB(80,58,32),0,folder,Enum.Material.Wood)
    body.Name = "Crate"
end

makeBarrel = function(folder, pos)
    local body = makePart(Vector3.new(1.8,2.8,1.8),CFrame.new(pos+Vector3.new(0,1.4,0)),Color3.fromRGB(90,62,30),0,folder,Enum.Material.Wood)
    body.Name = "Barrel"; body.Shape = Enum.PartType.Cylinder
end

makeRockPile = function(folder, pos)
    for i = 1, math.random(3,6) do
        local s = math.random(6,14)*0.1
        local rock = makePart(Vector3.new(s,s*0.65,s),CFrame.new(pos+Vector3.new(math.random(-4,4)*0.2,math.random(2,5)*0.2,math.random(-4,4)*0.2))*CFrame.Angles(math.rad(math.random(0,30)),math.rad(math.random(0,360)),math.rad(math.random(0,20))),Color3.fromRGB(55,52,50),0,folder,Enum.Material.Slate)
        rock.Name = "RockPile"; rock.CanCollide = false
    end
end

makeStalactite = function(folder, ceilY, x, z)
    local len = math.random(20,55)*0.1; local wid = math.random(4,10)*0.1
    local sp = makePart(Vector3.new(wid,len,wid),CFrame.new(x,ceilY-len*0.5,z)*CFrame.Angles(math.rad(math.random(-8,8)),0,math.rad(math.random(-8,8))),Color3.fromRGB(50,48,46),0,folder,Enum.Material.Slate)
    sp.Name = "Stalactite"; sp.CanCollide = false
end

spawnSpikyRock = function(folder, pos)
    local h = math.random(4,9)
    local spike = makePart(Vector3.new(math.random(15,30)*0.1,h,math.random(15,30)*0.1),CFrame.new(pos+Vector3.new(0,h*0.5,0))*CFrame.Angles(math.rad(math.random(-12,12)),math.rad(math.random(0,360)),math.rad(math.random(-12,12))),Color3.fromRGB(30,28,28),0,folder,Enum.Material.Slate)
    spike.Name = "SpikyRock"
    local db = false
    spike.Touched:Connect(function(hit)
        if hit.Parent == character and not db and not isHiding then
            db = true; if humanoid and humanoid.Health > 0 then humanoid:TakeDamage(5); showWarning("Ouch! Spiky rock!", 1.2) end
            task.wait(1.5); db = false
        end
    end)
end

-- =================================================================
-- MINECART & LOCKER
-- =================================================================
makeMinecart = function(folder, pos, cartType)
    local floor = makePart(Vector3.new(4,0.3,7),CFrame.new(pos+Vector3.new(0,0.45,0)),Color3.fromRGB(38,36,36),0,folder,Enum.Material.Metal)
    floor.Name = "CartFloor"
    makePart(Vector3.new(0.3,2.2,7),CFrame.new(pos+Vector3.new(-2.15,1.55,0)),Color3.fromRGB(55,52,52),0,folder,Enum.Material.Metal).Name = "CartWallL"
    makePart(Vector3.new(0.3,2.2,7),CFrame.new(pos+Vector3.new(2.15,1.55,0)),Color3.fromRGB(55,52,52),0,folder,Enum.Material.Metal).Name = "CartWallR"
    makePart(Vector3.new(4,2.2,0.3),CFrame.new(pos+Vector3.new(0,1.55,-3.5)),Color3.fromRGB(55,52,52),0,folder,Enum.Material.Metal).Name = "CartWallF"
    makePart(Vector3.new(4,2.2,0.3),CFrame.new(pos+Vector3.new(0,1.55,3.5)),Color3.fromRGB(55,52,52),0,folder,Enum.Material.Metal).Name = "CartWallB"

    if cartType == "filled" then
        makePart(Vector3.new(3.6,1.4,6.6),CFrame.new(pos+Vector3.new(0,1.3,0)),Color3.fromRGB(92,64,30),0,folder,Enum.Material.Mud).Name = "CartDirt"
    elseif cartType == "hide" then
        floor:SetAttribute("IsLocker", true); floor.Name = "CartHideFloor"
    end
    return floor
end

makeLocker = function(folder, pos)
    local body = makePart(Vector3.new(2.5,6.5,2),CFrame.new(pos+Vector3.new(0,3.25,0)),Color3.fromRGB(50,72,100),0,folder,Enum.Material.Metal)
    body.Name = "LockerBody"
    return body
end

-- =================================================================
-- BUILD ARCH WALL
-- =================================================================
buildArchWall = function(folder, O, zOffset, roomW, roomH, wallColor, isSignWall, doorNum)
    local halfGap = DOOR_GAP_W * 0.5; local sideW = (roomW - DOOR_GAP_W) * 0.5; local topH = roomH - DOOR_GAP_H
    makePart(Vector3.new(sideW,roomH,1), CFrame.new(O + Vector3.new(-(halfGap + sideW*0.5), roomH*0.5, zOffset)), wallColor, 0, folder, Enum.Material.Cobblestone)
    makePart(Vector3.new(sideW,roomH,1), CFrame.new(O + Vector3.new(halfGap + sideW*0.5, roomH*0.5, zOffset)), wallColor, 0, folder, Enum.Material.Cobblestone)
    makePart(Vector3.new(DOOR_GAP_W, topH, 1), CFrame.new(O + Vector3.new(0, roomH - topH*0.5, zOffset)), wallColor, 0, folder, Enum.Material.Cobblestone)
end

-- =================================================================
-- ROOM GENERATION
-- =================================================================
generateRoom = function(doorNum)
    if rooms[doorNum] then return end
    local folder = Instance.new("Folder"); folder.Name  = "Room_" .. doorNum; folder.Parent = workspace

    local isBridge = getIsBridge(doorNum)
    local isDark   = (not isBridge) and (math.random(1,100) <= 50)
    roomIsDark[doorNum] = isDark

    local roomW = isBridge and BRIDGE_W or CAVE_W
    local roomH = isBridge and BRIDGE_H or CAVE_H
    local roomD = isBridge and BRIDGE_D or CAVE_D
    local originZ = getRoomZ(doorNum)
    local O = Vector3.new(0, 0, -originZ)

    local wallC  = Color3.fromRGB(45,43,40)
    local floorC = Color3.fromRGB(38,36,34)

    if isBridge then
        wallC = Color3.fromRGB(35,33,30)
        makePart(Vector3.new(roomW,1,roomD), CFrame.new(O+Vector3.new(0,roomH+0.5,0)), Color3.fromRGB(33,31,30), 0, folder, Enum.Material.Slate).Name="CaveCeiling"
        makePart(Vector3.new(1,roomH+PIT_DEPTH,roomD), CFrame.new(O+Vector3.new(-roomW*0.5-0.5,(roomH-PIT_DEPTH)*0.5,0)), wallC, 0, folder, Enum.Material.Cobblestone).Name="CaveWallL"
        makePart(Vector3.new(1,roomH+PIT_DEPTH,roomD), CFrame.new(O+Vector3.new(roomW*0.5+0.5,(roomH-PIT_DEPTH)*0.5,0)), wallC, 0, folder, Enum.Material.Cobblestone).Name="CaveWallR"

        local platD = 25
        makePart(Vector3.new(roomW,1,platD), CFrame.new(O+Vector3.new(0,-0.5,roomD*0.5-platD*0.5)), floorC, 0, folder, Enum.Material.Slate).Name="CaveFloor"
        makePart(Vector3.new(roomW,1,platD), CFrame.new(O+Vector3.new(0,-0.5,-roomD*0.5+platD*0.5)), floorC, 0, folder, Enum.Material.Slate).Name="CaveFloor"

        local bridgeF = Instance.new("Folder"); bridgeF.Name = "Bridge"; bridgeF.Parent = folder
        local gapZStart = O.Z + roomD*0.5 - platD
        local gapDist = (O.Z + roomD*0.5 - platD) - (O.Z - roomD*0.5 + platD)
        
        local bSnd = Instance.new("Sound"); bSnd.SoundId = "rbxassetid://140355241446143"
        bSnd.Volume = 0; bSnd.Looped = true; bSnd.Parent = bridgeF; bSnd:Play()
        bridgeSounds[doorNum] = bSnd

        for i = 1, 20 do
            local pZ = gapZStart - (i * (gapDist / 21))
            local dipY = -0.5 - math.sin((i / 21) * math.pi) * 5
            local plank = makePart(Vector3.new(6,0.4,3), CFrame.new(O.X,dipY,pZ), Color3.fromRGB(80,55,30), 0, bridgeF, Enum.Material.Wood)
            plank.Name = "BridgePlank"; plank:SetAttribute("BridgeId", doorNum); plank:SetAttribute("DefaultY", dipY); plank:SetAttribute("DefaultZ", pZ); plank:SetAttribute("Progress", i/21)
        end
    else
        makePart(Vector3.new(roomW,1,roomD),CFrame.new(O+Vector3.new(0,-0.5,0)),floorC,0,folder,Enum.Material.Slate).Name="CaveFloor"
        makePart(Vector3.new(roomW,1,roomD),CFrame.new(O+Vector3.new(0,roomH+0.5,0)),Color3.fromRGB(33,31,30),0,folder,Enum.Material.Slate).Name="CaveCeiling"
        makePart(Vector3.new(1,roomH,roomD),CFrame.new(O+Vector3.new(-roomW*0.5-0.5,roomH*0.5,0)),wallC,0,folder,Enum.Material.Cobblestone).Name="CaveWallL"
        makePart(Vector3.new(1,roomH,roomD),CFrame.new(O+Vector3.new(roomW*0.5+0.5,roomH*0.5,0)),wallC,0,folder,Enum.Material.Cobblestone).Name="CaveWallR"
        
        if not isDark then
            for li = 1, math.random(2,4) do
                local lx = math.random(-math.floor(roomW*0.35),math.floor(roomW*0.35)); local lz = math.random(-math.floor(roomD*0.35),math.floor(roomD*0.35))
                local lan=makePart(Vector3.new(1.2,1.4,1.2),CFrame.new(O+Vector3.new(lx,roomH-2.4,lz)),Color3.fromRGB(255,210,100),0,folder,Enum.Material.Neon)
                lan.Name="Lantern"; makeLight(lan,1.8,30,Color3.fromRGB(255,210,110))
            end
        end
        for si = 1, math.random(2,5) do spawnSpikyRock(folder, O+Vector3.new(math.random(-10,10), 0, math.random(-20,20))) end
        makeLocker(folder, O+Vector3.new(math.random(8,12),0,0))
    end

    buildArchWall(folder, O, roomD*0.5+0.5, roomW, roomH, wallC, false, nil)
    buildArchWall(folder, O, -(roomD*0.5+0.5), roomW, roomH, wallC, true, doorNum)
    rooms[doorNum] = folder
end

createLobby = function()
    local folder = Instance.new("Folder"); folder.Name="CaveLobby"; folder.Parent=workspace
    makePart(Vector3.new(55,1,70),CFrame.new(0,-0.5,35),Color3.fromRGB(38,36,34),0,folder,Enum.Material.Slate).Name="LobbyFloor"
    local btn=makePart(Vector3.new(8,3,3.5),CFrame.new(0,1.5,16),Color3.fromRGB(0,140,60),0,folder,Enum.Material.Neon); btn.Name="StartButton"
    
    local startGui=Instance.new("ScreenGui"); startGui.Name="CaveStartGui"; startGui.ResetOnSpawn=false; startGui.Parent=player.PlayerGui
    local sf=Instance.new("Frame"); sf.Size=UDim2.new(0,280,0,65); sf.Position=UDim2.new(0.5,-140,0.83,0); sf.BackgroundColor3=Color3.fromRGB(0,100,40); sf.Parent=startGui
    local sbUI=Instance.new("TextButton"); sbUI.Size=UDim2.new(1,0,1,0); sbUI.BackgroundTransparency=1; sbUI.Text="[TAP TO ENTER CAVES]"; sbUI.Font=Enum.Font.GothamBold; sbUI.Parent=sf
    sbUI.MouseButton1Click:Connect(function() if not gameStarted then startGui:Destroy(); startGame() end end)
    rooms[-1]=folder; if character then character:PivotTo(CFrame.new(0,3,48)) end
end

-- =================================================================
-- HIDING & BRIDGE BREAKING
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
    table.clear(hiddenParts); if hideBtnLabel then hideBtnLabel.Text="[HIDE IN CART]" end
end

breakBridge = function(doorNum)
    if not bridgeStates[doorNum] then return end
    bridgeStates[doorNum].broken = true
    if bridgeSounds[doorNum] then bridgeSounds[doorNum]:Stop() end
    local folder = rooms[doorNum]
    if folder then
        local bridgeF = folder:FindFirstChild("Bridge")
        if bridgeF then
            for _, p in ipairs(bridgeF:GetChildren()) do if p.Name == "BridgePlank" then p.Anchored = false; p.CanCollide = false end end
        end
    end
end

showWarning = function(msg, duration)
    if not warningFrame then return end
    warningFrame.Visible=true; if warningLabel then warningLabel.Text=msg end
    task.delay(duration or 4, function() if warningFrame then warningFrame.Visible=false end end)
end

onDeath = function()
    if isDead then return end
    isDead=true; gameStarted=false; isHiding=false
    if humanoid then humanoid.CameraOffset=Vector3.new(0,0,0) end
    inventory={}; ecstasyActive=false; helmetEquipped=false; helmetLight=nil
    local dg=Instance.new("ScreenGui"); dg.Name="CaveDeathGui"; dg.ResetOnSpawn=false; dg.Parent=player.PlayerGui
    local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(100,0,0); bg.BackgroundTransparency=0.45; bg.BorderSizePixel=0; bg.Parent=dg
    local dl=Instance.new("TextLabel"); dl.Size=UDim2.new(1,0,0.28,0); dl.Position=UDim2.new(0,0,0.32,0); dl.BackgroundTransparency=1
    dl.Text="YOU DIED IN THE CAVES"; dl.TextColor3=Color3.fromRGB(255,255,255); dl.TextScaled=true; dl.Font=Enum.Font.GothamBold; dl.Parent=bg
    player.CharacterAdded:Wait(); task.wait(0.3); dg:Destroy(); isDead=false
    
    local cpLength = getIsBridge(checkpointDoor) and BRIDGE_D or CAVE_D
    if character and rootPart then character:PivotTo(CFrame.new(0,3,-getRoomZ(checkpointDoor) + cpLength*0.35)) end
    currentDoor=checkpointDoor; lastDetectedDoor=checkpointDoor
    if doorLabel then doorLabel.Text="Cave Door: "..tostring(checkpointDoor) end
    gameStarted=true
    for i=checkpointDoor, checkpointDoor+GEN_AHEAD do if i<=DOOR_MAX then generateRoom(i) end end
end

-- =================================================================
-- ENTITIES
-- =================================================================
spawnAgony = function(doorNum)
    if agonyActive or agonyOnCooldown then return end
    agonyActive = true; agonyOnCooldown = true

    local ef = Instance.new("Folder"); ef.Name = "AgonyEntity"; ef.Parent = workspace
    local startDoor = doorNum - 3
    local stopDoor = doorNum + 5
    local startZ = -getRoomZ(startDoor) + (getIsBridge(startDoor) and BRIDGE_D*0.5 or CAVE_D*0.5)
    local stopZ  = -getRoomZ(stopDoor) - (getIsBridge(stopDoor) and BRIDGE_D*0.5 or CAVE_D*0.5)

    local body = makePart(Vector3.new(4, 8, 4), CFrame.new(0, CAVE_H*0.5, startZ), Color3.fromRGB(0,0,0), 0.2, ef, Enum.Material.Neon)
    body.Name = "AgonyBody"; body.CanCollide = false

    local tr = Instance.new("Trail"); tr.Color = ColorSequence.new(Color3.fromRGB(0,0,0)); tr.Lifetime = 2.5; tr.Parent = body
    local a0 = Instance.new("Attachment", body); a0.Position = Vector3.new(0,4,0)
    local a1 = Instance.new("Attachment", body); a1.Position = Vector3.new(0,-4,0)
    tr.Attachment0 = a0; tr.Attachment1 = a1

    local pe = Instance.new("ParticleEmitter", body)
    pe.Color = ColorSequence.new(Color3.fromRGB(0,0,0))
    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,3), NumberSequenceKeypoint.new(1,0)})
    pe.Rate = 100; pe.Speed = NumberRange.new(5,15); pe.Lifetime = NumberRange.new(1,2)

    local moveSnd = Instance.new("Sound"); moveSnd.SoundId = "rbxassetid://89060529910257"
    moveSnd.Volume = 2; moveSnd.Looped = true; moveSnd.RollOffMaxDistance = 250; moveSnd.Parent = body; moveSnd:Play()

    local lightSnd = Instance.new("Sound"); lightSnd.SoundId = "rbxassetid://140414748697760"
    lightSnd.Volume = 1.5; lightSnd.Parent = body

    local currentDarkRoom = startDoor

    local ac; ac = RunService.Heartbeat:Connect(function(dt)
        if not body or not body.Parent then ac:Disconnect(); return end
        local newZ = body.CFrame.Position.Z - AGONY_SPEED * dt
        body.CFrame = CFrame.new(body.CFrame.Position.X, body.CFrame.Position.Y, newZ)

        -- Destroy Lights & Trigger Darkness
        if -getRoomZ(currentDarkRoom) > newZ and currentDarkRoom <= stopDoor then
            roomIsDark[currentDarkRoom] = true
            local roomFolder = rooms[currentDarkRoom]
            if roomFolder then
                local brokeLight = false
                for _, v in ipairs(roomFolder:GetDescendants()) do
                    if v:IsA("PointLight") then v:Destroy(); brokeLight = true end
                    if v.Name == "Lantern" then v.Material = Enum.Material.Glass; v.Color = Color3.fromRGB(30,30,30); brokeLight = true end
                end
                if brokeLight then lightSnd:Play() end
            end
            currentDarkRoom = currentDarkRoom + 1
        end

        -- Line of Sight & Camera Shake
        if rootPart and humanoid and not isDead then
            local dist = math.abs(rootPart.Position.Z - newZ)
            
            if dist < 150 then
                local i2 = (150 - dist) / 150
                humanoid.CameraOffset = Vector3.new(math.random(-10,10)*0.08*i2, math.random(-10,10)*0.08*i2, 0)
            else
                humanoid.CameraOffset = Vector3.new(0,0,0)
            end

            if dist < 60 then
                if isHiding then
                    -- Carts don't save you from Agony.
                    if humanoid.Health > 0 then humanoid.Health = 0; onDeath() end
                else
                    -- Raycast to check for Line of Sight blocks (Lockers, spikes, etc.)
                    local rayOrigin = body.Position
                    local rayDir = (rootPart.Position - rayOrigin)
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {ef, character}
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    
                    local hit = workspace:Raycast(rayOrigin, rayDir, rayParams)
                    
                    if not hit then
                        if humanoid.Health > 0 then humanoid.Health = 0; onDeath() end
                    end
                end
            end
        end

        if newZ <= stopZ then
            ac:Disconnect(); moveSnd:Stop(); agonyActive = false
            if humanoid then humanoid.CameraOffset = Vector3.new(0,0,0) end
            ef:Destroy()
            task.delay(AGONY_COOLDOWN, function() agonyOnCooldown = false end)
        end
    end)
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
    for i=DOOR_START,doorNum-CLEAN_BEHIND do
        if rooms[i] then rooms[i]:Destroy(); rooms[i]=nil end
        roomIsDark[i]=nil
        if bridgeSounds[i] then bridgeSounds[i]:Destroy(); bridgeSounds[i]=nil end
        bridgeStates[i]=nil
    end

    if doorNum >= AGONY_START and not agonyActive and not agonyOnCooldown then
        if math.random(1, 100) <= AGONY_CHANCE then task.spawn(function() spawnAgony(doorNum) end) end
    end
end

-- =================================================================
-- START GAME & CHAR REF
-- =================================================================
startGame = function()
    gameStarted=true; currentDoor=DOOR_START; lastDetectedDoor=DOOR_START; checkpointDoor=DOOR_START
    local startLen = getIsBridge(DOOR_START) and BRIDGE_D or CAVE_D
    if character then character:PivotTo(CFrame.new(0,3,-getRoomZ(DOOR_START)+startLen*0.45)) end
    for i=DOOR_START,DOOR_START+GEN_AHEAD do generateRoom(i) end
end

updateCharRef = function(newChar)
    character=newChar; humanoid=newChar:WaitForChild("Humanoid"); rootPart=newChar:WaitForChild("HumanoidRootPart")
    task.spawn(function() local rs=rootPart:WaitForChild("Running",3); if rs then rs.Volume=0 end end)
    
    floorStepSound=Instance.new("Sound")
    floorStepSound.SoundId="rbxassetid://138662719868461" 
    floorStepSound.Volume=1
    floorStepSound.Parent=rootPart
    
    humanoid.Died:Connect(function() onDeath() end)
end

-- =================================================================
-- MAIN LOOP
-- =================================================================
mainLoop = function()
    RunService.Heartbeat:Connect(function(dt)
        if not gameStarted or not rootPart then return end
        local targetSpeed=16
        if not isHiding and humanoid and not diseaseActive then humanoid.WalkSpeed=targetSpeed end
        
        local onBridgeId = nil
        if humanoid and humanoid.Health > 0 and not isDead then
            local hit = workspace:Raycast(rootPart.Position, Vector3.new(0,-6,0))
            if hit and hit.Instance.Name == "BridgePlank" then onBridgeId = hit.Instance:GetAttribute("BridgeId") end
        end

        local moving = false
        if humanoid and humanoid.Health>0 and not isHiding then
            moving = humanoid.MoveDirection.Magnitude>0
            if moving and humanoid.FloorMaterial~=Enum.Material.Air then
                local sr=humanoid.WalkSpeed/16; local siv=0.38/math.max(0.1,sr)
                if tick()-lastStepTime>=siv then 
                    lastStepTime=tick()
                    -- Swap footstep sound based on terrain
                    if onBridgeId then
                        floorStepSound.SoundId = "rbxassetid://139561410113584"
                    else
                        floorStepSound.SoundId = "rbxassetid://138662719868461"
                    end
                    if floorStepSound then floorStepSound.PlaybackSpeed=sr; floorStepSound:Play() end 
                end
            else lastStepTime=0 end
        end

        local pZ = rootPart.Position.Z
        local approxDoor = currentDoor
        local nextZ = -getRoomZ(approxDoor) - (getIsBridge(approxDoor) and BRIDGE_D or CAVE_D)*0.5
        while pZ < nextZ and approxDoor < DOOR_MAX do
            approxDoor = approxDoor + 1
            nextZ = -getRoomZ(approxDoor) - (getIsBridge(approxDoor) and BRIDGE_D or CAVE_D)*0.5
        end
        local prevZ = -getRoomZ(approxDoor - 1) - (getIsBridge(approxDoor - 1) and BRIDGE_D or CAVE_D)*0.5
        while pZ > prevZ and approxDoor > DOOR_START do
            approxDoor = approxDoor - 1
            prevZ = -getRoomZ(approxDoor - 1) - (getIsBridge(approxDoor - 1) and BRIDGE_D or CAVE_D)*0.5
        end

        if approxDoor>lastDetectedDoor and approxDoor<=DOOR_MAX then lastDetectedDoor=approxDoor; onDoorReached(approxDoor) end

        -- Cart Detection
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
