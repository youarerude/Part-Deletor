-- ============================================================
-- JUJUTSU KAISEN  |  LocalScript → StarterPlayerScripts
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Debris           = game:GetService("Debris")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp       = character:WaitForChild("HumanoidRootPart")
local playerHum = character:WaitForChild("Humanoid")
local camera    = workspace.CurrentCamera

-- ============================================================
-- GRADE CONFIG
-- ============================================================
local GRADES = {
	{name="Grade 4", spawnInterval=5,  maxCount=20, color=Color3.fromRGB(180,180,180), size=2,   dmg=3,  attackRate=2,   aggroRange=35, speed=10},
	{name="Grade 3", spawnInterval=10, maxCount=15, color=Color3.fromRGB(100,200,100), size=2.5, dmg=6,  attackRate=2.5, aggroRange=40, speed=13},
	{name="Grade 2", spawnInterval=25, maxCount=8,  color=Color3.fromRGB(200,150,50),  size=3,   dmg=12, attackRate=3,   aggroRange=45, speed=15},
	{name="Grade 1", spawnInterval=50, maxCount=5,  color=Color3.fromRGB(200,50,50),   size=3.5, dmg=20, attackRate=3.5, aggroRange=50, speed=17},
}
local DUMMY_HP = {["Grade 4"]=50, ["Grade 3"]=100, ["Grade 2"]=200, ["Grade 1"]=350}
local SPAWN_RADIUS = 40

-- ============================================================
-- STATE
-- ============================================================
local spawnedDummies = {}
local gradeTimers    = {}
for _, g in ipairs(GRADES) do gradeTimers[g.name] = 0 end

local currentSorcerer = "Gojo"

-- All cooldowns for all sorcerers keyed by unique string
local allCooldowns = {
	-- Gojo
	Red=0, Blue=0, Purple=0, UnlimitedVoid=0,
	-- Sukuna
	Fuga=0, Cleave=0, Dismantle=0, MalevolentShrine=0,
	-- Nobara
	Nail=0, Doll=0, Torture=0, ExplosiveNails=0,
	-- Megumi
	RabbitEscape=0, Toad=0, MaxElephant=0, Summon=0, ChimeraShadowGarden=0,
	-- Mahoraga
	SwordOfExtermination=0, Adaptation=0, DivineCrash=0, CrushingGrab=0,
}

local blueOrb      = nil
local domainActive = false
local isChanneling = false

-- Burn status: {entry -> timer}
local burnTimers   = {}

-- ============================================================
-- SORCERER ABILITY DEFINITIONS
-- ============================================================
local SORCERER_ABILITIES = {
	Gojo = {
		{key="Red",           label="Red",      color=Color3.fromRGB(210,40,40),  cd=10},
		{key="Blue",          label="Blue",     color=Color3.fromRGB(40,90,210),  cd=13},
		{key="Purple",        label="Purple",   color=Color3.fromRGB(150,40,210), cd=30},
		{key="UnlimitedVoid", label="∞ Void",   color=Color3.fromRGB(15,0,35),    cd=120},
	},
	Sukuna = {
		{key="Fuga",            label="Fuga",       color=Color3.fromRGB(210,80,20),  cd=15},
		{key="Cleave",          label="Cleave",     color=Color3.fromRGB(180,20,20),  cd=13},
		{key="Dismantle",       label="Dismantle",  color=Color3.fromRGB(140,30,30),  cd=12},
		{key="MalevolentShrine",label="M.Shrine",   color=Color3.fromRGB(40,0,0),     cd=120},
	},
	Nobara = {
		{key="Nail",          label="Nail",        color=Color3.fromRGB(160,120,60),  cd=12},
		{key="Doll",          label="Doll",        color=Color3.fromRGB(90,60,160),   cd=3},
		{key="Torture",       label="Torture",     color=Color3.fromRGB(160,30,30),   cd=13},
		{key="ExplosiveNails",label="Exp. Nails",  color=Color3.fromRGB(200,80,20),   cd=15},
	},
	Megumi = {
		{key="RabbitEscape",          label="Rabbits",     color=Color3.fromRGB(240,240,240), cd=10},
		{key="Toad",                  label="Toad",        color=Color3.fromRGB(50,140,60),   cd=9},
		{key="MaxElephant",           label="Elephant",    color=Color3.fromRGB(200,120,160), cd=15},
		{key="Summon",                label="Summon...",   color=Color3.fromRGB(20,20,40),    cd=180},
		{key="ChimeraShadowGarden",   label="CSGarden",    color=Color3.fromRGB(5,5,15),      cd=120},
	},
	Mahoraga = {
		{key="SwordOfExtermination",  label="⚔ Sword",     color=Color3.fromRGB(200,200,100), cd=0.6},
		{key="Adaptation",            label="Adaptation",  color=Color3.fromRGB(80,160,80),   cd=50},
		{key="DivineCrash",           label="D.Crash",     color=Color3.fromRGB(220,180,30),  cd=15},
		{key="CrushingGrab",          label="C.Grab",      color=Color3.fromRGB(80,40,20),    cd=999},
	},
}

-- ============================================================
-- UTILITY
-- ============================================================
local function getMouseWorldPos()
	local ray = camera:ScreenPointToRay(
		UserInputService:GetMouseLocation().X,
		UserInputService:GetMouseLocation().Y)
	local result = workspace:Raycast(ray.Origin, ray.Direction * 600)
	if result then return result.Position end
	return ray.Origin + ray.Direction * 60
end

-- Flat horizontal aim: takes the look direction but zeroes Y, returns Unit on XZ plane
local function getFlatAimDir()
	local raw = getMouseWorldPos() - hrp.Position
	local flat = Vector3.new(raw.X, 0, raw.Z)
	if flat.Magnitude < 0.1 then
		flat = hrp.CFrame.LookVector
		flat = Vector3.new(flat.X, 0, flat.Z)
	end
	return flat.Unit
end

local function countGrade(n)
	local c = 0
	for _, e in ipairs(spawnedDummies) do
		if e.grade == n and e.humanoid.Health > 0 then c = c + 1 end
	end
	return c
end

local function cleanDeadDummies()
	local alive = {}
	for _, e in ipairs(spawnedDummies) do
		if e.humanoid.Health > 0 then
			table.insert(alive, e)
		else
			pcall(function() e.model:Destroy() end)
		end
	end
	spawnedDummies = alive
end

local function makePart(props)
	local p = Instance.new("Part")
	for k,v in pairs(props) do p[k] = v end
	return p
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function hpColor(pct)
	if pct > 0.6 then return Color3.fromRGB(80,220,80)
	elseif pct > 0.3 then return Color3.fromRGB(230,180,0)
	else return Color3.fromRGB(220,50,50) end
end

local function flashScreen(sgui, color, fadeIn, hold, fadeOut)
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1,0,1,0)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 50
	flash.Parent = sgui
	TweenService:Create(flash, TweenInfo.new(fadeIn), {BackgroundTransparency=0}):Play()
	task.delay(fadeIn + hold, function()
		TweenService:Create(flash, TweenInfo.new(fadeOut), {BackgroundTransparency=1}):Play()
		Debris:AddItem(flash, fadeOut + 0.1)
	end)
end

-- Apply burn to a dummy entry (5 dmg/s for 10s)
local function applyBurn(entry)
	if not entry or entry.humanoid.Health <= 0 then return end
	burnTimers[entry] = 10  -- reset or start 10s burn
end

-- ============================================================
-- SCREEN GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JJKGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- ============================================================
-- PLAYER HEALTH BAR
-- ============================================================
local playerHpFrame = Instance.new("Frame")
playerHpFrame.Size = UDim2.new(0, 220, 0, 34)
playerHpFrame.Position = UDim2.new(0, 12, 1, -50)
playerHpFrame.BackgroundColor3 = Color3.fromRGB(15,15,30)
playerHpFrame.BackgroundTransparency = 0.25
playerHpFrame.BorderSizePixel = 0
playerHpFrame.Parent = screenGui
addCorner(playerHpFrame, 8)

local playerHpLabel = Instance.new("TextLabel")
playerHpLabel.Size = UDim2.new(1,0,0,14)
playerHpLabel.Position = UDim2.new(0,0,0,2)
playerHpLabel.BackgroundTransparency = 1
playerHpLabel.Text = "YOU  100/100"
playerHpLabel.TextColor3 = Color3.fromRGB(220,180,255)
playerHpLabel.Font = Enum.Font.GothamBold
playerHpLabel.TextSize = 11
playerHpLabel.Parent = playerHpFrame

local playerHpBg = Instance.new("Frame")
playerHpBg.Size = UDim2.new(1,-10,0,10)
playerHpBg.Position = UDim2.new(0,5,0,19)
playerHpBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
playerHpBg.BorderSizePixel = 0
playerHpBg.Parent = playerHpFrame
addCorner(playerHpBg, 4)

local playerHpFill = Instance.new("Frame")
playerHpFill.Size = UDim2.new(1,0,1,0)
playerHpFill.BackgroundColor3 = Color3.fromRGB(80,220,80)
playerHpFill.BorderSizePixel = 0
playerHpFill.Parent = playerHpBg
addCorner(playerHpFill, 4)

-- ============================================================
-- TOP BAR
-- ============================================================
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 260, 0, 36)
titleLabel.Position = UDim2.new(0.5, -130, 0, 10)
titleLabel.BackgroundColor3 = Color3.fromRGB(15,15,30)
titleLabel.BackgroundTransparency = 0.3
titleLabel.BorderSizePixel = 0
titleLabel.Text = "⚔ JUJUTSU KAISEN"
titleLabel.TextColor3 = Color3.fromRGB(220,180,255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.Parent = screenGui
addCorner(titleLabel, 8)

local sorcererBtn = Instance.new("TextButton")
sorcererBtn.Size = UDim2.new(0, 170, 0, 34)
sorcererBtn.Position = UDim2.new(0.5, -85, 0, 54)
sorcererBtn.BackgroundColor3 = Color3.fromRGB(80,30,140)
sorcererBtn.BorderSizePixel = 0
sorcererBtn.Text = "👤 Sorcerer: Gojo"
sorcererBtn.TextColor3 = Color3.fromRGB(255,255,255)
sorcererBtn.Font = Enum.Font.GothamSemibold
sorcererBtn.TextSize = 13
sorcererBtn.Parent = screenGui
addCorner(sorcererBtn, 8)

local sorcererPanel = Instance.new("Frame")
sorcererPanel.Size = UDim2.new(0, 210, 0, 130)
sorcererPanel.Position = UDim2.new(0.5, -105, 0, 94)
sorcererPanel.BackgroundColor3 = Color3.fromRGB(20,10,40)
sorcererPanel.BackgroundTransparency = 0.1
sorcererPanel.BorderSizePixel = 0
sorcererPanel.Visible = false
sorcererPanel.ZIndex = 10
sorcererPanel.Parent = screenGui
addCorner(sorcererPanel, 8)

do
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0,4)
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	l.Parent = sorcererPanel
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0,6)
	pad.Parent = sorcererPanel
end

-- ============================================================
-- ABILITY BAR  (dynamic, rebuilt on sorcerer change)
-- ============================================================
local abilityFrame = Instance.new("Frame")
abilityFrame.Size = UDim2.new(0, 450, 0, 80)
abilityFrame.Position = UDim2.new(0.5, -225, 1, -100)
abilityFrame.BackgroundTransparency = 1
abilityFrame.Parent = screenGui

local abilityButtons   = {}  -- rebuilt per sorcerer
local currentAbilDefs  = {}  -- the active list

-- Megumi elephant state (hoisted so rebuildAbilityBar can cancel it)
local elephantActive   = false
local elephantZone     = nil
local elephantStillTimer = 0
local elephantLastPos  = nil
local elephantZoneConn = nil

-- Mahoraga adaptation state (hoisted)
local adaptationPct     = 0    -- 0..100
local adaptationReady   = false
local mahoragaRef       = nil  -- reference to active Mahoraga torso/hum for player-controlled mode

-- Adaptation HUD bar (bottom-right, only shown for Mahoraga)
local adaptFrame = Instance.new("Frame")
adaptFrame.Size = UDim2.new(0, 200, 0, 42)
adaptFrame.Position = UDim2.new(1, -212, 1, -100)
adaptFrame.BackgroundColor3 = Color3.fromRGB(10,25,10)
adaptFrame.BackgroundTransparency = 0.25
adaptFrame.BorderSizePixel = 0
adaptFrame.Visible = false
adaptFrame.Parent = screenGui
addCorner(adaptFrame, 8)

local adaptLabel = Instance.new("TextLabel")
adaptLabel.Size = UDim2.new(1,0,0,16)
adaptLabel.Position = UDim2.new(0,0,0,2)
adaptLabel.BackgroundTransparency = 1
adaptLabel.Text = "Adaptation: 0%"
adaptLabel.TextColor3 = Color3.fromRGB(100,240,80)
adaptLabel.Font = Enum.Font.GothamBold
adaptLabel.TextSize = 11
adaptLabel.Parent = adaptFrame

local adaptBg = Instance.new("Frame")
adaptBg.Size = UDim2.new(1,-10,0,10)
adaptBg.Position = UDim2.new(0,5,0,20)
adaptBg.BackgroundColor3 = Color3.fromRGB(30,30,30)
adaptBg.BorderSizePixel = 0
adaptBg.Parent = adaptFrame
addCorner(adaptBg, 4)

local adaptFill = Instance.new("Frame")
adaptFill.Size = UDim2.new(0,0,1,0)
adaptFill.BackgroundColor3 = Color3.fromRGB(80,220,80)
adaptFill.BorderSizePixel = 0
adaptFill.Parent = adaptBg
addCorner(adaptFill, 4)

local function rebuildAbilityBar(sorcererName)
	-- Cancel active elephant zone if switching away
	if elephantActive then
		elephantActive = false
		if elephantZoneConn then elephantZoneConn:Disconnect() elephantZoneConn=nil end
		if elephantZone and elephantZone.Parent then elephantZone:Destroy() elephantZone=nil end
	end
	-- Clear existing buttons
	for _, info in pairs(abilityButtons) do
		if info.btn and info.btn.Parent then
			info.btn:Destroy()
		end
	end
	abilityButtons = {}

	-- Remove old layout if any
	for _, ch in ipairs(abilityFrame:GetChildren()) do
		if ch:IsA("UIListLayout") then ch:Destroy() end
	end

	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0,8)
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	l.Parent = abilityFrame

	currentAbilDefs = SORCERER_ABILITIES[sorcererName] or SORCERER_ABILITIES["Gojo"]

	for _, ad in ipairs(currentAbilDefs) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 96, 0, 72)
		btn.BackgroundColor3 = ad.color
		btn.BorderSizePixel = 0
		btn.Text = ad.label.."\n["..ad.cd.."s]"
		btn.TextColor3 = Color3.fromRGB(255,255,255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.Parent = abilityFrame
		addCorner(btn, 10)

		local overlay = Instance.new("Frame")
		overlay.Size = UDim2.new(1,0,1,0)
		overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.ZIndex = 5
		overlay.Parent = btn
		addCorner(overlay, 10)

		-- Special border for domain abilities
		if ad.key == "UnlimitedVoid" then
			local s = Instance.new("UIStroke") s.Color=Color3.fromRGB(130,60,220) s.Thickness=2 s.Parent=btn
		elseif ad.key == "MalevolentShrine" then
			local s = Instance.new("UIStroke") s.Color=Color3.fromRGB(220,60,0) s.Thickness=2 s.Parent=btn
		elseif ad.key == "ExplosiveNails" then
			local s = Instance.new("UIStroke") s.Color=Color3.fromRGB(255,180,30) s.Thickness=2 s.Parent=btn
		elseif ad.key == "Summon" then
			local s = Instance.new("UIStroke") s.Color=Color3.fromRGB(100,100,200) s.Thickness=2 s.Parent=btn
		elseif ad.key == "ChimeraShadowGarden" then
			local s = Instance.new("UIStroke") s.Color=Color3.fromRGB(60,180,80) s.Thickness=2 s.Parent=btn
		elseif ad.key == "Adaptation" then
			local s = Instance.new("UIStroke") s.Color=Color3.fromRGB(80,220,80) s.Thickness=2 s.Parent=btn
		end

		abilityButtons[ad.key] = {btn=btn, overlay=overlay, baseColor=ad.color, cd=ad.cd, label=ad.label}

		-- Wire click/touch
		local function onFire()
			if currentSorcerer == "Gojo" then
				if     ad.key=="Red"           then fireGojo_Red()
				elseif ad.key=="Blue"          then fireGojo_Blue()
				elseif ad.key=="Purple"        then fireGojo_Purple()
				elseif ad.key=="UnlimitedVoid" then fireGojo_UnlimitedVoid()
				end
			elseif currentSorcerer == "Sukuna" then
				if     ad.key=="Fuga"             then fireSukuna_Fuga()
				elseif ad.key=="Cleave"           then fireSukuna_Cleave()
				elseif ad.key=="Dismantle"        then fireSukuna_Dismantle()
				elseif ad.key=="MalevolentShrine" then fireSukuna_MalevolentShrine()
				end
			elseif currentSorcerer == "Nobara" then
				if     ad.key=="Nail"          then fireNobara_Nail()
				elseif ad.key=="Doll"          then fireNobara_Doll()
				elseif ad.key=="Torture"       then fireNobara_Torture()
				elseif ad.key=="ExplosiveNails" then fireNobara_ExplosiveNails()
				end
			elseif currentSorcerer == "Megumi" then
				if     ad.key=="RabbitEscape"        then fireMegumi_RabbitEscape()
				elseif ad.key=="Toad"                then fireMegumi_Toad()
				elseif ad.key=="MaxElephant"         then fireMegumi_MaxElephant()
				elseif ad.key=="Summon"              then fireMegumi_Summon()
				elseif ad.key=="ChimeraShadowGarden" then fireMegumi_ChimeraShadowGarden()
				end
			elseif currentSorcerer == "Mahoraga" then
				if     ad.key=="SwordOfExtermination" then fireMahoraga_Sword()
				elseif ad.key=="Adaptation"           then fireMahoraga_Adaptation()
				elseif ad.key=="DivineCrash"          then fireMahoraga_DivineCrash()
				elseif ad.key=="CrushingGrab"         then fireMahoraga_CrushingGrab()
				end
			end
		end
		btn.MouseButton1Click:Connect(onFire)
		btn.TouchTap:Connect(onFire)
	end
end

-- ============================================================
-- COUNTER PANEL
-- ============================================================
local counterFrame = Instance.new("Frame")
counterFrame.Size = UDim2.new(0, 165, 0, 110)
counterFrame.Position = UDim2.new(0, 10, 0.5, -55)
counterFrame.BackgroundColor3 = Color3.fromRGB(10,10,25)
counterFrame.BackgroundTransparency = 0.3
counterFrame.BorderSizePixel = 0
counterFrame.Parent = screenGui
addCorner(counterFrame, 8)

do
	local ct = Instance.new("TextLabel")
	ct.Size = UDim2.new(1,0,0,22)
	ct.BackgroundTransparency = 1
	ct.Text = "Curses Active"
	ct.TextColor3 = Color3.fromRGB(200,150,255)
	ct.Font = Enum.Font.GothamBold
	ct.TextSize = 13
	ct.Parent = counterFrame
end

local gradeColors = {
	["Grade 4"]=Color3.fromRGB(180,180,180),
	["Grade 3"]=Color3.fromRGB(100,200,100),
	["Grade 2"]=Color3.fromRGB(200,150,50),
	["Grade 1"]=Color3.fromRGB(220,50,50),
}
local counterLabels = {}
for i, g in ipairs(GRADES) do
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,-10,0,18)
	lbl.Position = UDim2.new(0,5,0,20+(i-1)*21)
	lbl.BackgroundTransparency = 1
	lbl.Text = g.name..": 0/"..g.maxCount
	lbl.TextColor3 = gradeColors[g.name]
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = counterFrame
	counterLabels[g.name] = lbl
end

-- Resonance status badge (bottom-right, only visible for Nobara)
local resonanceBadge = Instance.new("TextLabel")
resonanceBadge.Size = UDim2.new(0, 190, 0, 32)
resonanceBadge.Position = UDim2.new(1, -202, 1, -50)
resonanceBadge.BackgroundColor3 = Color3.fromRGB(20,20,30)
resonanceBadge.BackgroundTransparency = 0.25
resonanceBadge.BorderSizePixel = 0
resonanceBadge.Text = "○ No Resonance"
resonanceBadge.TextColor3 = Color3.fromRGB(120,120,140)
resonanceBadge.Font = Enum.Font.GothamBold
resonanceBadge.TextSize = 13
resonanceBadge.Visible = false
resonanceBadge.Parent = screenGui
addCorner(resonanceBadge, 8)

-- ============================================================
-- DOMAIN / CAMERA HELPERS
-- ============================================================
local domainRing    = nil
local domainOverlay = nil
local shakeConn     = nil
local DEFAULT_FOV   = 70

local function buildDomainVisuals(ringColor)
	domainOverlay = Instance.new("Frame")
	domainOverlay.Size = UDim2.new(1,0,1,0)
	domainOverlay.BackgroundColor3 = ringColor or Color3.fromRGB(5,0,20)
	domainOverlay.BackgroundTransparency = 0.65
	domainOverlay.BorderSizePixel = 0
	domainOverlay.ZIndex = 20
	domainOverlay.Parent = screenGui

	domainRing = makePart({
		Shape=Enum.PartType.Ball, Size=Vector3.new(1,1,1),
		Position=hrp.Position, Anchored=true, CanCollide=false,
		CastShadow=false, Material=Enum.Material.Neon,
		Color=ringColor or Color3.fromRGB(40,0,80), Transparency=0.55, Parent=workspace
	})
	TweenService:Create(domainRing, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size=Vector3.new(90,90,90), Transparency=0.78}):Play()
end

local function destroyDomainVisuals()
	if domainRing then
		TweenService:Create(domainRing, TweenInfo.new(1.5), {Size=Vector3.new(1,1,1), Transparency=1}):Play()
		Debris:AddItem(domainRing, 1.6) domainRing = nil
	end
	if domainOverlay then
		TweenService:Create(domainOverlay, TweenInfo.new(1), {BackgroundTransparency=1}):Play()
		Debris:AddItem(domainOverlay, 1.1) domainOverlay = nil
	end
end

local function startShake(intensity)
	if shakeConn then shakeConn:Disconnect() end
	shakeConn = RunService.RenderStepped:Connect(function()
		camera.CFrame = camera.CFrame * CFrame.Angles(
			math.rad((math.random()-0.5)*intensity*0.2),
			math.rad((math.random()-0.5)*intensity*0.2), 0)
	end)
end
local function stopShake()
	if shakeConn then shakeConn:Disconnect() shakeConn = nil end
end
local function expandFOV(target, t)
	TweenService:Create(camera, TweenInfo.new(t), {FieldOfView=target}):Play()
end

-- ============================================================
-- DUMMY SPAWNING
-- ============================================================
local function spawnDummy(gradeData)
	local angle    = math.random() * math.pi * 2
	local dist     = math.random(10, SPAWN_RADIUS)
	local spawnPos = hrp.Position + Vector3.new(math.cos(angle)*dist, 0, math.sin(angle)*dist)

	local model = Instance.new("Model")
	model.Name  = gradeData.name.." Dummy"

	local torso = makePart({
		Name="HumanoidRootPart",
		Size=Vector3.new(gradeData.size, gradeData.size*1.2, gradeData.size),
		Position=spawnPos + Vector3.new(0, gradeData.size*1.5, 0),
		Color=gradeData.color, Material=Enum.Material.SmoothPlastic,
		Anchored=false, CanCollide=true, Parent=model
	})
	local head = makePart({
		Name="Head",
		Size=Vector3.new(gradeData.size*.8, gradeData.size*.8, gradeData.size*.8),
		Position=torso.Position + Vector3.new(0, gradeData.size, 0),
		Color=gradeData.color, Material=Enum.Material.SmoothPlastic,
		CanCollide=true, Parent=model
	})
	local hw = Instance.new("WeldConstraint") hw.Part0=torso hw.Part1=head hw.Parent=torso

	-- Billboard: name + HP bar
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 115, 0, 46)
	bb.StudsOffset = Vector3.new(0, gradeData.size + 2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = torso

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1,0,0,20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = gradeData.name
	nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = bb

	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(1,-8,0,11)
	hpBg.Position = UDim2.new(0,4,0,22)
	hpBg.BackgroundColor3 = Color3.fromRGB(35,35,35)
	hpBg.BorderSizePixel = 0
	hpBg.Parent = bb
	addCorner(hpBg, 4)

	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.new(1,0,1,0)
	hpFill.BackgroundColor3 = Color3.fromRGB(80,220,80)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg
	addCorner(hpFill, 4)

	local hpNum = Instance.new("TextLabel")
	hpNum.Size = UDim2.new(1,0,1,0)
	hpNum.BackgroundTransparency = 1
	hpNum.Text = DUMMY_HP[gradeData.name].."/"..DUMMY_HP[gradeData.name]
	hpNum.TextColor3 = Color3.fromRGB(255,255,255)
	hpNum.TextStrokeTransparency = 0.4
	hpNum.Font = Enum.Font.Gotham
	hpNum.TextSize = 8
	hpNum.ZIndex = 2
	hpNum.Parent = hpBg

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = DUMMY_HP[gradeData.name]
	hum.Health    = DUMMY_HP[gradeData.name]
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	model.PrimaryPart = torso
	model.Parent = workspace

	table.insert(spawnedDummies, {
		grade=gradeData.name, model=model, humanoid=hum, torso=torso,
		hpFill=hpFill, hpNum=hpNum, attackTimer=0, frozen=false, gradeData=gradeData,
	})
end

-- ============================================================
-- SHARED COOLDOWN HELPERS
-- ============================================================
local function isCooldown(k) return allCooldowns[k] and allCooldowns[k] > 0 end
local function startCD(k,d)  allCooldowns[k] = d end

-- ============================================================
-- ========= GOJO ABILITIES ===================================
-- ============================================================

-- ---- RED ----
function fireGojo_Red()
	if isCooldown("Red") or isChanneling then return end
	startCD("Red", 10)

	local origin = hrp.Position + Vector3.new(0, 0.5, 0)
	local target = getMouseWorldPos()
	local dir    = (target - origin).Unit
	local len    = (target - origin).Magnitude

	local beam = makePart({
		Size=Vector3.new(0.45,0.45,len),
		CFrame=CFrame.new(origin, target)*CFrame.new(0,0,-len/2),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(220,30,30), Material=Enum.Material.Neon, Parent=workspace
	})
	local bl=Instance.new("PointLight") bl.Brightness=4 bl.Range=12 bl.Color=Color3.fromRGB(220,30,30) bl.Parent=beam
	Debris:AddItem(beam, 0.2)

	local ring = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1,1,1),
		Position=target, Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(220,30,30), Material=Enum.Material.Neon, Transparency=0.4, Parent=workspace})
	TweenService:Create(ring, TweenInfo.new(0.3), {Size=Vector3.new(9,9,9), Transparency=1}):Play()
	Debris:AddItem(ring, 0.31)

	for _, e in ipairs(spawnedDummies) do
		if e.humanoid.Health > 0 then
			local toE  = e.torso.Position - origin
			local proj = toE:Dot(dir)
			local perp = (toE - dir*proj).Magnitude
			if proj > 0 and perp < 3.5 then
				e.humanoid:TakeDamage(15)
				local bv=Instance.new("BodyVelocity") bv.Velocity=dir*45+Vector3.new(0,12,0) bv.MaxForce=Vector3.new(1e5,1e5,1e5) bv.P=1e4 bv.Parent=e.torso
				Debris:AddItem(bv, 0.22)
			end
		end
	end
end

-- ---- BLUE ----
function fireGojo_Blue()
	if isCooldown("Blue") or isChanneling then return end
	if blueOrb then blueOrb:Destroy() blueOrb=nil end
	startCD("Blue", 13)

	local orb = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(2.2,2.2,2.2),
		Position=getMouseWorldPos(), Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(30,80,255), Material=Enum.Material.Neon, Parent=workspace})
	local bl=Instance.new("PointLight") bl.Brightness=6 bl.Range=22 bl.Color=Color3.fromRGB(30,80,255) bl.Parent=orb
	blueOrb = orb

	local moveConn = RunService.Heartbeat:Connect(function()
		if not orb.Parent then return end
		orb.Position = getMouseWorldPos()
	end)
	local magnetized = {}
	local magConn = RunService.Heartbeat:Connect(function()
		if not orb.Parent then return end
		for _, e in ipairs(spawnedDummies) do
			if e.humanoid.Health>0 and not magnetized[e] then
				if (e.torso.Position-orb.Position).Magnitude<=15 then magnetized[e]=true end
			end
		end
		for e in pairs(magnetized) do
			if e.humanoid.Health>0 then
				local d=(orb.Position-e.torso.Position).Unit
				local bv=Instance.new("BodyVelocity") bv.Velocity=d*28 bv.MaxForce=Vector3.new(1e5,1e5,1e5) bv.P=5000 bv.Parent=e.torso
				Debris:AddItem(bv, 0.06)
			end
		end
	end)

	task.delay(5, function()
		moveConn:Disconnect() magConn:Disconnect()
		if not orb.Parent then return end
		local exPos=orb.Position
		local exp=makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(2,2,2),
			Position=exPos, Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(30,80,255), Material=Enum.Material.Neon, Parent=workspace})
		TweenService:Create(exp, TweenInfo.new(0.45), {Size=Vector3.new(24,24,24), Transparency=1}):Play()
		Debris:AddItem(exp, 0.46)
		for e in pairs(magnetized) do
			if e.humanoid.Health>0 then
				e.humanoid:TakeDamage(15)
				local fDir=(e.torso.Position-exPos).Unit
				local bv=Instance.new("BodyVelocity") bv.Velocity=fDir*65+Vector3.new(0,32,0) bv.MaxForce=Vector3.new(1e5,1e5,1e5) bv.P=1e5 bv.Parent=e.torso
				Debris:AddItem(bv, 0.3)
			end
		end
		orb:Destroy() blueOrb=nil
	end)
end

-- ---- PURPLE (flat aim — no up/down) ----
function fireGojo_Purple()
	if isCooldown("Purple") or isChanneling then return end
	startCD("Purple", 30)
	isChanneling = true

	local centerPos = hrp.Position + Vector3.new(0, 1.5, 0)
	-- FLAT horizontal direction only
	local dir = getFlatAimDir()

	-- Red & Blue orbs spawn to the sides relative to flat direction
	local right  = Vector3.new(-dir.Z, 0, dir.X)  -- perpendicular on XZ
	local redOrb = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1.5,1.5,1.5),
		Position=centerPos - right*2.5, Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(220,30,30), Material=Enum.Material.Neon, Parent=workspace})
	local rl=Instance.new("PointLight") rl.Color=Color3.fromRGB(220,30,30) rl.Brightness=5 rl.Range=14 rl.Parent=redOrb

	local blueO = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1.5,1.5,1.5),
		Position=centerPos + right*2.5, Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(30,80,255), Material=Enum.Material.Neon, Parent=workspace})
	local bll=Instance.new("PointLight") bll.Color=Color3.fromRGB(30,80,255) bll.Brightness=5 bll.Range=14 bll.Parent=blueO

	TweenService:Create(redOrb, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position=centerPos, Size=Vector3.new(3.5,3.5,3.5)}):Play()
	TweenService:Create(blueO, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position=centerPos, Size=Vector3.new(3.5,3.5,3.5)}):Play()

	task.wait(1.3)
	pcall(function() redOrb:Destroy() end)
	pcall(function() blueO:Destroy() end)

	local purpOrb = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(5,5,5),
		Position=centerPos, Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(180,30,255), Material=Enum.Material.Neon, Parent=workspace})
	local pl=Instance.new("PointLight") pl.Color=Color3.fromRGB(180,30,255) pl.Brightness=10 pl.Range=28 pl.Parent=purpOrb

	task.wait(0.35)

	local travelDist=350; local speed=130; local traveled=0
	local lastPos=centerPos; local alreadyHit={}

	local fireConn
	fireConn = RunService.Heartbeat:Connect(function(dt)
		if not purpOrb.Parent then fireConn:Disconnect() isChanneling=false return end
		local move=speed*dt; traveled=traveled+move
		-- Keep Y constant (flat travel at orb's Y)
		local newPos = Vector3.new(lastPos.X+dir.X*move, lastPos.Y, lastPos.Z+dir.Z*move)
		purpOrb.Position = newPos; lastPos=newPos

		-- Debris trail
		if math.random()<0.4 then
			local s=makePart({Shape=Enum.PartType.Ball,
				Size=Vector3.new(math.random()*1+0.3, math.random()*1+0.3, math.random()*1+0.3),
				Position=newPos+Vector3.new((math.random()-0.5)*2, (math.random()-0.5)*1, (math.random()-0.5)*2),
				Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(180,30,255), Material=Enum.Material.Neon, Transparency=0.3, Parent=workspace})
			TweenService:Create(s, TweenInfo.new(0.5), {Transparency=1, Size=Vector3.new(0.1,0.1,0.1)}):Play()
			Debris:AddItem(s, 0.51)
		end

		-- Pierce hit (flat-level check)
		for _, e in ipairs(spawnedDummies) do
			if e.humanoid.Health>0 and not alreadyHit[e] then
				if (e.torso.Position-newPos).Magnitude<4.5 then
					alreadyHit[e]=true
					e.humanoid:TakeDamage(50)
					local bv=Instance.new("BodyVelocity") bv.Velocity=dir*30+Vector3.new(0,8,0) bv.MaxForce=Vector3.new(1e5,1e5,1e5) bv.P=1e4 bv.Parent=e.torso
					Debris:AddItem(bv, 0.2)
				end
			end
		end

		if traveled>=travelDist then fireConn:Disconnect() purpOrb:Destroy() isChanneling=false end
	end)
end

-- ---- UNLIMITED VOID ----
function fireGojo_UnlimitedVoid()
	if isCooldown("UnlimitedVoid") or isChanneling or domainActive then return end
	startCD("UnlimitedVoid", 120)
	isChanneling = true; domainActive = true

	buildDomainVisuals(Color3.fromRGB(40,0,80))
	task.delay(3, function() flashScreen(screenGui, Color3.fromRGB(255,255,255), 0.6, 0.15, 0.9) end)

	task.delay(3.8, function()
		startShake(2); expandFOV(95, 1.5); isChanneling=false
		local domainCenter=hrp.Position; local frozenEntries={}
		for _, e in ipairs(spawnedDummies) do
			if e.humanoid.Health>0 and (e.torso.Position-domainCenter).Magnitude<=45 then
				e.frozen=true; e.torso.Anchored=true
				table.insert(frozenEntries, e)
				local vt=makePart({Size=e.torso.Size*Vector3.new(1.08,1.08,1.08), CFrame=e.torso.CFrame,
					Anchored=true, CanCollide=false, Color=Color3.fromRGB(60,0,120), Material=Enum.Material.Neon, Transparency=0.55, Parent=workspace})
				local vtw=Instance.new("WeldConstraint") vtw.Part0=e.torso vtw.Part1=vt vtw.Parent=e.torso
				e.voidTint=vt
			end
		end
		local tick=0
		local function doDmgTick()
			tick=tick+1
			for _, e in ipairs(frozenEntries) do if e.humanoid.Health>0 then e.humanoid:TakeDamage(10) end end
			if tick<15 then task.delay(1, doDmgTick) end
		end
		task.delay(1, doDmgTick)

		task.delay(15, function()
			local sp=hrp.Position
			for i=1,22 do
				local sh=makePart({Size=Vector3.new(math.random(1,4),math.random(1,5),math.random(1,2)),
					Position=sp+Vector3.new(math.random(-22,22),math.random(1,12),math.random(-22,22)),
					Color=Color3.fromRGB(100,0,160), Material=Enum.Material.Neon, Transparency=0.25, Anchored=false, CanCollide=false, Parent=workspace})
				TweenService:Create(sh, TweenInfo.new(1.4), {Transparency=1,
					Position=sh.Position+Vector3.new(math.random(-18,18),math.random(8,22),math.random(-18,18))}):Play()
				Debris:AddItem(sh, 1.5)
			end
			flashScreen(screenGui, Color3.fromRGB(0,0,0), 0.5, 0.25, 0.9)
			task.delay(0.5, function()
				for _, e in ipairs(frozenEntries) do
					e.frozen=false; pcall(function() e.torso.Anchored=false end)
					if e.voidTint then pcall(function() e.voidTint:Destroy() end) e.voidTint=nil end
				end
				stopShake(); expandFOV(DEFAULT_FOV, 1.5); destroyDomainVisuals(); domainActive=false
			end)
		end)
	end)
end

-- ============================================================
-- ========= SUKUNA ABILITIES =================================
-- ============================================================

-- ---- FUGA (Fire Bow & Arrow, flat aim) ----
function fireSukuna_Fuga()
	if isCooldown("Fuga") or isChanneling then return end
	startCD("Fuga", 15)
	isChanneling = true

	local origin = hrp.Position + Vector3.new(0, 1.5, 0)
	local dir    = getFlatAimDir()  -- flat horizontal only

	-- BOW ANIMATION: build a fire bow shape (arc of fire parts)
	local bowParts = {}
	for i = 1, 8 do
		local t   = (i / 8) * math.pi       -- 0..pi arc
		local arc = Vector3.new(math.cos(t)*0, math.sin(t)*2.5, 0)  -- vertical bow curve
		-- offset bow to left side of player
		local right = Vector3.new(-dir.Z, 0, dir.X)
		local bowPos = origin + right*(-1.2) + Vector3.new(0, arc.Y - 1.25, 0)
		local bp = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.35,0.35,0.35),
			Position=bowPos, Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(255,140,20), Material=Enum.Material.Neon, Transparency=0.1, Parent=workspace})
		local fl=Instance.new("PointLight") fl.Brightness=2 fl.Range=5 fl.Color=Color3.fromRGB(255,140,20) fl.Parent=bp
		table.insert(bowParts, bp)
	end

	-- Arrow nock part (held at center)
	local arrowNock = makePart({
		Size=Vector3.new(0.2,0.2,2.5),
		CFrame=CFrame.new(origin, origin+dir)*CFrame.new(0,0,-1.25),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(255,200,80), Material=Enum.Material.Neon, Parent=workspace})

	task.wait(3)  -- 3 second draw time

	-- Destroy bow & arrow visuals
	for _, bp in ipairs(bowParts) do pcall(function() bp:Destroy() end) end
	pcall(function() arrowNock:Destroy() end)

	-- Fire the arrow (flat aim direction captured at draw time — already flat)
	local arrowPos  = origin
	local arrowHead = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.4,0.4,1.5),
		CFrame=CFrame.new(arrowPos, arrowPos+dir)*CFrame.new(0,0,-0.75),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(255,160,30), Material=Enum.Material.Neon, Parent=workspace})
	local afl=Instance.new("PointLight") afl.Brightness=5 afl.Range=10 afl.Color=Color3.fromRGB(255,120,0) afl.Parent=arrowHead

	local arrowTravel=0; local arrowMax=200; local arrowSpeed=100
	local arrowLast=arrowPos; local arrowHit=false

	local arrowConn
	arrowConn = RunService.Heartbeat:Connect(function(dt)
		if not arrowHead.Parent or arrowHit then arrowConn:Disconnect() isChanneling=false return end
		local move = arrowSpeed*dt
		arrowTravel = arrowTravel+move
		-- Flat travel only
		local newPos = Vector3.new(arrowLast.X+dir.X*move, arrowLast.Y, arrowLast.Z+dir.Z*move)
		arrowHead.CFrame = CFrame.new(newPos, newPos+dir)*CFrame.new(0,0,-0.75)
		arrowLast=newPos

		-- Fire trail
		if math.random()<0.5 then
			local trail=makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.3,0.3,0.3),
				Position=newPos, Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(255,100,0), Material=Enum.Material.Neon, Transparency=0.2, Parent=workspace})
			TweenService:Create(trail, TweenInfo.new(0.4), {Transparency=1, Size=Vector3.new(0.05,0.05,0.05)}):Play()
			Debris:AddItem(trail, 0.41)
		end

		-- Hit check
		for _, e in ipairs(spawnedDummies) do
			if e.humanoid.Health>0 and (e.torso.Position-newPos).Magnitude<3 then
				arrowHit=true
				arrowHead:Destroy()
				arrowConn:Disconnect()
				isChanneling=false

				-- Spawn flaming AOE area
				local aoeCenter = newPos
				local aoe = makePart({Size=Vector3.new(12,0.5,12),
					Position=aoeCenter+Vector3.new(0,-1,0), Anchored=true, CanCollide=false,
					Color=Color3.fromRGB(255,80,0), Material=Enum.Material.Neon, Transparency=0.4, Parent=workspace})
				addCorner(aoe, 0)  -- AOE floor
				local aoeLight=Instance.new("PointLight") aoeLight.Brightness=6 aoeLight.Range=18 aoeLight.Color=Color3.fromRGB(255,80,0) aoeLight.Parent=aoe

				-- Flicker effect
				local flickerConn = RunService.Heartbeat:Connect(function()
					if not aoe.Parent then return end
					aoe.Transparency = 0.3 + math.sin(tick()*12)*0.15
				end)

				-- Spawn fire particle columns
				local firePillars = {}
				for fi=1,10 do
					local angle2=math.random()*math.pi*2
					local r=math.random()*5
					local fp=makePart({Shape=Enum.PartType.Ball,
						Size=Vector3.new(0.8,math.random(2,5),0.8),
						Position=aoeCenter+Vector3.new(math.cos(angle2)*r, math.random(1,4), math.sin(angle2)*r),
						Anchored=true, CanCollide=false,
						Color=Color3.fromRGB(255,math.random(60,140),0), Material=Enum.Material.Neon, Transparency=0.3, Parent=workspace})
					table.insert(firePillars, fp)
				end

				-- AOE damage every 0.5s for 5s
				local aoeTick=0
				local function doAoeTick()
					if aoeTick>=10 then return end
					aoeTick=aoeTick+1
					for _, ae in ipairs(spawnedDummies) do
						if ae.humanoid.Health>0 and (ae.torso.Position-aoeCenter).Magnitude<=7 then
							ae.humanoid:TakeDamage(15)
							applyBurn(ae)  -- burn effect
						end
					end
					task.delay(0.5, doAoeTick)
				end
				task.delay(0.5, doAoeTick)

				-- Clean up after 5s
				task.delay(5, function()
					flickerConn:Disconnect()
					pcall(function() aoe:Destroy() end)
					for _, fp in ipairs(firePillars) do pcall(function() fp:Destroy() end) end
				end)
				return
			end
		end

		if arrowTravel>=arrowMax then
			arrowConn:Disconnect()
			pcall(function() arrowHead:Destroy() end)
			isChanneling=false
		end
	end)
end

-- ---- CLEAVE ----
function fireSukuna_Cleave()
	if isCooldown("Cleave") or isChanneling then return end
	startCD("Cleave", 13)

	local center = hrp.Position
	local RADIUS = 25

	-- Cleave zone floor indicator
	local zonePart = makePart({Size=Vector3.new(RADIUS*2, 0.4, RADIUS*2),
		Position=center+Vector3.new(0,-2.5,0), Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(180,0,0), Material=Enum.Material.Neon, Transparency=0.55, Parent=workspace})

	-- Slash particles (many thin diagonal cutting lines radiating from center)
	local slashParts = {}
	local function spawnSlashParticle()
		if not zonePart.Parent then return end
		local angle2 = math.random()*math.pi*2
		local r      = math.random()*RADIUS*0.9
		local slashDir = Vector3.new(math.cos(angle2), 0, math.sin(angle2))
		local slashPos = center + slashDir*r + Vector3.new(0, math.random(0,4), 0)
		local slashLen = math.random(2,6)
		-- Slash: thin elongated neon part rotated along its travel angle
		local perp = Vector3.new(-slashDir.Z, 0, slashDir.X)
		local cf   = CFrame.fromMatrix(slashPos, perp, Vector3.new(0,1,0), -slashDir)
		local sp = makePart({Size=Vector3.new(slashLen, 0.07, 0.07),
			CFrame=cf, Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(255,230,220), Material=Enum.Material.Neon, Transparency=0.0, Parent=workspace})
		TweenService:Create(sp, TweenInfo.new(0.12), {Transparency=1, Size=Vector3.new(slashLen*1.5, 0.04, 0.04)}):Play()
		Debris:AddItem(sp, 0.13)
	end

	-- Continuously spawn slashes for 3 seconds
	local slashTimer=0
	local slashConn = RunService.Heartbeat:Connect(function(dt)
		if not zonePart.Parent then return end
		slashTimer=slashTimer+dt
		-- Spawn ~15 slashes per second
		if slashTimer>=0.067 then
			slashTimer=0
			spawnSlashParticle()
			spawnSlashParticle()
		end
	end)

	-- Damage every 0.2s for 3s = 15 damage ticks
	local damageTimer=0
	local damageConn = RunService.Heartbeat:Connect(function(dt)
		if not zonePart.Parent then return end
		damageTimer=damageTimer+dt
		if damageTimer>=0.2 then
			damageTimer=0
			for _, e in ipairs(spawnedDummies) do
				if e.humanoid.Health>0 and (e.torso.Position-center).Magnitude<=RADIUS then
					e.humanoid:TakeDamage(5)
				end
			end
		end
	end)

	task.delay(3, function()
		slashConn:Disconnect()
		damageConn:Disconnect()
		TweenService:Create(zonePart, TweenInfo.new(0.3), {Transparency=1}):Play()
		Debris:AddItem(zonePart, 0.31)
	end)
end

-- ---- DISMANTLE (5 slash projectiles, flat aim) ----
function fireSukuna_Dismantle()
	if isCooldown("Dismantle") or isChanneling then return end
	startCD("Dismantle", 12)

	local baseDir = getFlatAimDir()
	local right   = Vector3.new(-baseDir.Z, 0, baseDir.X)

	-- Spread 5 slashes in a slight fan
	local spreads = {-0.15, -0.07, 0, 0.07, 0.15}

	for si, offset in ipairs(spreads) do
		task.delay(si*0.06, function()
			local spreadDir = (baseDir + right*offset).Unit
			local origin    = hrp.Position + Vector3.new(0, 1.5, 0)

			-- Slash projectile: thin elongated part
			local slash = makePart({
				Size=Vector3.new(3,0.1,0.12),
				CFrame=CFrame.new(origin, origin+spreadDir)*CFrame.new(0,0,-1.5),
				Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(255,230,200), Material=Enum.Material.Neon, Transparency=0.05, Parent=workspace})
			local sl=Instance.new("PointLight") sl.Brightness=3 sl.Range=8 sl.Color=Color3.fromRGB(255,200,150) sl.Parent=slash

			local trav=0; local maxDist=120; local spd=140
			local lastP=origin; local hitSet={}

			local conn
			conn = RunService.Heartbeat:Connect(function(dt)
				if not slash.Parent then conn:Disconnect() return end
				local move=spd*dt; trav=trav+move
				local newPos=Vector3.new(lastP.X+spreadDir.X*move, lastP.Y, lastP.Z+spreadDir.Z*move)
				slash.CFrame=CFrame.new(newPos, newPos+spreadDir)*CFrame.new(0,0,-1.5)
				lastP=newPos

				-- Slash trail flicker
				if math.random()<0.4 then
					local tr=makePart({Size=Vector3.new(2,0.06,0.06),
						CFrame=slash.CFrame, Anchored=true, CanCollide=false,
						Color=Color3.fromRGB(255,240,220), Material=Enum.Material.Neon, Transparency=0.3, Parent=workspace})
					TweenService:Create(tr, TweenInfo.new(0.1), {Transparency=1}):Play()
					Debris:AddItem(tr, 0.11)
				end

				-- Hit
				for _, e in ipairs(spawnedDummies) do
					if e.humanoid.Health>0 and not hitSet[e] and (e.torso.Position-newPos).Magnitude<3 then
						hitSet[e]=true
						e.humanoid:TakeDamage(12)
						-- Small slash impact flash
						local imp=makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1,1,1),
							Position=e.torso.Position, Anchored=true, CanCollide=false,
							Color=Color3.fromRGB(255,230,200), Material=Enum.Material.Neon, Transparency=0.3, Parent=workspace})
						TweenService:Create(imp, TweenInfo.new(0.2), {Size=Vector3.new(4,4,4), Transparency=1}):Play()
						Debris:AddItem(imp, 0.21)
					end
				end

				if trav>=maxDist then conn:Disconnect() pcall(function() slash:Destroy() end) end
			end)
		end)
	end
end

-- ---- MALEVOLENT SHRINE (Coming Soon) ----
function fireSukuna_MalevolentShrine()
	if isCooldown("MalevolentShrine") or isChanneling or domainActive then return end
	startCD("MalevolentShrine", 120)
	isChanneling = true
	domainActive = true

	local domainCenter = hrp.Position

	-- ── Phase 1: Domain sphere expands (same as Unlimited Void but blood-red) ──
	buildDomainVisuals(Color3.fromRGB(80, 0, 0))

	-- Red flash on activation after sphere builds
	task.delay(3, function()
		flashScreen(screenGui, Color3.fromRGB(200, 30, 0), 0.5, 0.15, 0.7)
	end)

	task.delay(3.6, function()
		startShake(2)
		expandFOV(92, 1.5)
		isChanneling = false

		-- ── Phase 2: Build the Shrine ──
		-- Shrine is made of dark stone-like pillars and a torii gate shape
		local shrineParts = {}

		local function addShrinePart(props)
			local p = makePart(props)
			table.insert(shrineParts, p)
			return p
		end

		-- Base platform (flat slab)
		addShrinePart({
			Size = Vector3.new(10, 0.6, 10),
			Position = domainCenter + Vector3.new(0, -2, 0),
			Anchored = true, CanCollide = false,
			Color = Color3.fromRGB(25, 5, 5),
			Material = Enum.Material.SmoothPlastic,
			Parent = workspace,
		})

		-- 4 corner pillars rising up
		local pillarOffsets = {
			Vector3.new(-4, 0, -4), Vector3.new(4, 0, -4),
			Vector3.new(-4, 0, 4),  Vector3.new(4, 0, 4),
		}
		for _, offset in ipairs(pillarOffsets) do
			local pillarBase = domainCenter + offset + Vector3.new(0, -2, 0)
			local pillar = addShrinePart({
				Size = Vector3.new(1, 0.1, 1),
				Position = pillarBase,
				Anchored = true, CanCollide = false,
				Color = Color3.fromRGB(30, 5, 5),
				Material = Enum.Material.SmoothPlastic,
				Parent = workspace,
			})
			-- Animate pillar growing upward
			TweenService:Create(pillar, TweenInfo.new(1.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{Size = Vector3.new(1, 9, 1), Position = pillarBase + Vector3.new(0, 4.45, 0)}):Play()
		end

		task.wait(0.6)

		-- Torii gate crossbeam (horizontal beam across top front)
		local crossBeam = addShrinePart({
			Size = Vector3.new(0.1, 1.2, 1.2),
			Position = domainCenter + Vector3.new(0, 5.5, -4),
			Anchored = true, CanCollide = false,
			Color = Color3.fromRGB(120, 10, 10),
			Material = Enum.Material.Neon,
			Transparency = 0.2,
			Parent = workspace,
		})
		TweenService:Create(crossBeam, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = Vector3.new(10, 1.2, 1.2)}):Play()

		-- Crossbeam glow
		local cbl = Instance.new("PointLight") cbl.Color=Color3.fromRGB(180,20,0) cbl.Brightness=4 cbl.Range=12 cbl.Parent=crossBeam

		task.wait(0.4)

		-- Second crossbeam slightly lower (torii style double beam)
		local crossBeam2 = addShrinePart({
			Size = Vector3.new(0.1, 0.7, 0.7),
			Position = domainCenter + Vector3.new(0, 4.5, -4),
			Anchored = true, CanCollide = false,
			Color = Color3.fromRGB(100, 8, 8),
			Material = Enum.Material.Neon,
			Transparency = 0.3,
			Parent = workspace,
		})
		TweenService:Create(crossBeam2, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = Vector3.new(9, 0.7, 0.7)}):Play()

		task.wait(0.3)

		-- Shrine lanterns (2 glowing orbs hanging from crossbeam)
		for _, side in ipairs({-3, 3}) do
			local lantern = addShrinePart({
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1, 1, 1),
				Position = domainCenter + Vector3.new(side, 4.2, -4),
				Anchored = true, CanCollide = false,
				Color = Color3.fromRGB(220, 30, 0),
				Material = Enum.Material.Neon,
				Transparency = 0.1,
				Parent = workspace,
			})
			local ll = Instance.new("PointLight") ll.Color=Color3.fromRGB(255,40,0) ll.Brightness=6 ll.Range=14 ll.Parent=lantern
		end

		-- Altar block in center
		local altar = addShrinePart({
			Size = Vector3.new(0.5, 0.5, 0.5),
			Position = domainCenter + Vector3.new(0, -1.5, 0),
			Anchored = true, CanCollide = false,
			Color = Color3.fromRGB(15, 3, 3),
			Material = Enum.Material.SmoothPlastic,
			Parent = workspace,
		})
		TweenService:Create(altar, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = Vector3.new(3.5, 2.5, 3.5), Position = domainCenter + Vector3.new(0, -0.75, 0)}):Play()

		task.wait(0.5)

		-- Altar glowing runes (small neon parts around base)
		for ri = 1, 8 do
			local runeAngle = (ri / 8) * math.pi * 2
			local runePos = domainCenter + Vector3.new(math.cos(runeAngle)*5, -1.8, math.sin(runeAngle)*5)
			local rune = addShrinePart({
				Size = Vector3.new(0.5, 0.1, 0.8),
				CFrame = CFrame.new(runePos) * CFrame.Angles(0, runeAngle, 0),
				Anchored = true, CanCollide = false,
				Color = Color3.fromRGB(200, 20, 0),
				Material = Enum.Material.Neon,
				Transparency = 0.1,
				Parent = workspace,
			})
			TweenService:Create(rune, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = Vector3.new(0.8, 0.1, 1.4)}):Play()
		end

		task.wait(0.8)

		-- ── Phase 3: Slashes fill the domain + damage ──
		-- Collect dummies in range at activation time
		local targetedDummies = {}
		for _, e in ipairs(spawnedDummies) do
			if e.humanoid.Health > 0 and (e.torso.Position - domainCenter).Magnitude <= 45 then
				table.insert(targetedDummies, e)
				-- Red void tint on frozen targets
				local vt = makePart({
					Size = e.torso.Size * Vector3.new(1.08,1.08,1.08),
					CFrame = e.torso.CFrame,
					Anchored = true, CanCollide = false,
					Color = Color3.fromRGB(120, 0, 0),
					Material = Enum.Material.Neon,
					Transparency = 0.5,
					Parent = workspace,
				})
				local vtw = Instance.new("WeldConstraint") vtw.Part0=e.torso vtw.Part1=vt vtw.Parent=e.torso
				e.shrineTint = vt
			end
		end

		-- Slash particle system — runs for 15 seconds
		local slashAccum   = 0
		local damageAccum  = 0
		local elapsedTime  = 0
		local DOMAIN_DUR   = 15

		local shrineConn = RunService.Heartbeat:Connect(function(dt)
			if not domainActive then return end
			elapsedTime  = elapsedTime + dt
			slashAccum   = slashAccum + dt
			damageAccum  = damageAccum + dt

			-- Spawn slashes every ~0.05s (heavy slash storm)
			if slashAccum >= 0.05 then
				slashAccum = 0
				-- Pick a random point inside the domain
				local sAngle = math.random() * math.pi * 2
				local sR     = math.random() * 40
				local sH     = math.random(-2, 6)
				local sPos   = domainCenter + Vector3.new(math.cos(sAngle)*sR, sH, math.sin(sAngle)*sR)
				-- Random slash orientation
				local slashRot = math.random() * math.pi * 2
				local slashLen = math.random(3, 9)
				local sDir     = Vector3.new(math.cos(slashRot), 0, math.sin(slashRot))
				local sPerp    = Vector3.new(-sDir.Z, 0, sDir.X)
				local sCF      = CFrame.fromMatrix(sPos, sPerp, Vector3.new(0,1,0), -sDir)
				local slash    = makePart({
					Size      = Vector3.new(slashLen, 0.08, 0.08),
					CFrame    = sCF,
					Anchored  = true, CanCollide = false,
					Color     = Color3.fromRGB(255, math.random(200,240), math.random(180,220)),
					Material  = Enum.Material.Neon,
					Transparency = 0.0,
					Parent    = workspace,
				})
				TweenService:Create(slash, TweenInfo.new(0.1),
					{Transparency = 1, Size = Vector3.new(slashLen * 1.4, 0.04, 0.04)}):Play()
				Debris:AddItem(slash, 0.11)
			end

			-- Damage every 0.1s
			if damageAccum >= 0.1 then
				damageAccum = 0
				for _, e in ipairs(targetedDummies) do
					if e.humanoid.Health > 0 then
						e.humanoid:TakeDamage(5)
					end
				end
			end

			-- Also damage any new dummies that wandered in
			if math.floor(elapsedTime * 10) % 5 == 0 then
				for _, e in ipairs(spawnedDummies) do
					if e.humanoid.Health > 0 and not e.shrineTint then
						if (e.torso.Position - domainCenter).Magnitude <= 45 then
							table.insert(targetedDummies, e)
							local vt2 = makePart({
								Size = e.torso.Size * Vector3.new(1.08,1.08,1.08),
								CFrame = e.torso.CFrame,
								Anchored = true, CanCollide = false,
								Color = Color3.fromRGB(120,0,0),
								Material = Enum.Material.Neon,
								Transparency = 0.5,
								Parent = workspace,
							})
							local vtw2 = Instance.new("WeldConstraint") vtw2.Part0=e.torso vtw2.Part1=vt2 vtw2.Parent=e.torso
							e.shrineTint = vt2
						end
					end
				end
			end
		end)

		-- ── Phase 4: Shatter + shrine collapses after 15s ──
		task.delay(DOMAIN_DUR, function()
			shrineConn:Disconnect()

			-- Shattering glass-like shards burst outward
			for i = 1, 28 do
				local shardPos = domainCenter + Vector3.new(
					math.random(-30,30), math.random(0,15), math.random(-30,30))
				local shard = makePart({
					Size = Vector3.new(math.random(1,5), math.random(1,6), math.random(1,3)),
					Position = shardPos,
					Color = Color3.fromRGB(80+math.random(0,60), 0, 0),
					Material = Enum.Material.Neon,
					Transparency = 0.2,
					Anchored = false, CanCollide = false,
					Parent = workspace,
				})
				TweenService:Create(shard, TweenInfo.new(1.6), {
					Transparency = 1,
					Position = shardPos + Vector3.new(
						math.random(-20,20), math.random(10,25), math.random(-20,20)),
				}):Play()
				Debris:AddItem(shard, 1.7)
			end

			-- Shrine pillars collapse (tween size to 0 and fall)
			for _, sp in ipairs(shrineParts) do
				if sp and sp.Parent then
					TweenService:Create(sp, TweenInfo.new(1.0, Enum.EasingStyle.Back, Enum.EasingDirection.In),
						{Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1}):Play()
					Debris:AddItem(sp, 1.1)
				end
			end

			-- Black flash out
			flashScreen(screenGui, Color3.fromRGB(0, 0, 0), 0.4, 0.2, 0.8)

			-- Remove tints + restore state
			task.delay(0.4, function()
				for _, e in ipairs(targetedDummies) do
					if e.shrineTint then
						pcall(function() e.shrineTint:Destroy() end)
						e.shrineTint = nil
					end
				end
				stopShake()
				expandFOV(DEFAULT_FOV, 1.5)
				destroyDomainVisuals()
				domainActive = false
			end)
		end)
	end)
end

-- ============================================================
-- ========= NOBARA ABILITIES =================================
-- ============================================================

-- Nobara shared state
local nobaraDolls      = {}  -- list of { entry=dummyEntry, state="attached"|"dropped", dollPart=Part, resonance=bool }
local MAX_DOLLS        = 3
local resonanceDoll    = nil  -- the dropped resonance doll part in the world (if any)
local resonanceActive  = false  -- player is holding the resonance doll
local resonanceDummies = {}  -- entries that have resonance doll linked to them

-- Nearest alive dummy to player (optionally filtered by a predicate)
local function getNearestDummy(pred)
	local best, bestDist = nil, math.huge
	for _, e in ipairs(spawnedDummies) do
		if e.humanoid.Health > 0 then
			if pred == nil or pred(e) then
				local d = (e.torso.Position - hrp.Position).Magnitude
				if d < bestDist then bestDist = d; best = e end
			end
		end
	end
	return best, bestDist
end

-- Check how many dolls are currently attached (not yet dropped / died)
local function activeDollCount()
	local c = 0
	for _, d in ipairs(nobaraDolls) do
		if d.state == "attached" and d.entry.humanoid.Health > 0 then
			c = c + 1
		end
	end
	return c
end

-- Clean up doll records for dead dummies
local function cleanDolls()
	local alive = {}
	for _, d in ipairs(nobaraDolls) do
		if d.entry.humanoid.Health > 0 then
			table.insert(alive, d)
		else
			-- Dummy died — destroy its doll visuals and free resonance slot
			pcall(function() d.dollPart:Destroy() end)
			-- Remove from resonanceDummies
			for i, re in ipairs(resonanceDummies) do
				if re == d.entry then table.remove(resonanceDummies, i) break end
			end
		end
	end
	nobaraDolls = alive
end

-- ---- NAIL (homing) ----
function fireNobara_Nail()
	if isCooldown("Nail") or isChanneling then return end
	startCD("Nail", 12)

	local target, dist = getNearestDummy()
	if not target then return end

	-- Nail projectile visual
	local nailPos = hrp.Position + Vector3.new(0, 1.2, 0)
	local nail = makePart({
		Size = Vector3.new(0.15, 0.15, 1.2),
		CFrame = CFrame.new(nailPos, target.torso.Position),
		Anchored = true, CanCollide = false,
		Color = Color3.fromRGB(180, 150, 80),
		Material = Enum.Material.SmoothPlastic,
		Parent = workspace,
	})
	-- Nail head (slightly thicker tip)
	local nailHead = makePart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.28, 0.28, 0.28),
		Position = nailPos,
		Anchored = true, CanCollide = false,
		Color = Color3.fromRGB(200, 170, 90),
		Material = Enum.Material.SmoothPlastic,
		Parent = workspace,
	})
	local nhw = Instance.new("WeldConstraint") nhw.Part0=nail nhw.Part1=nailHead nhw.Parent=nail

	local traveled = 0
	local speed    = 90
	local lastPos  = nailPos
	local hit      = false

	local nailConn
	nailConn = RunService.Heartbeat:Connect(function(dt)
		if not nail.Parent or hit then nailConn:Disconnect() return end
		if not target or target.humanoid.Health <= 0 then
			-- Target died; continue straight
			traveled = traveled + speed * dt
			if traveled > 120 then nailConn:Disconnect() pcall(function() nail:Destroy() end) end
			return
		end

		-- Home toward target
		local toTarget = (target.torso.Position - lastPos)
		local move     = math.min(speed * dt, toTarget.Magnitude)
		local dir      = toTarget.Unit
		local newPos   = lastPos + dir * move
		nail.CFrame    = CFrame.new(newPos, target.torso.Position)
		nailHead.Position = newPos + dir * 0.6
		lastPos = newPos
		traveled = traveled + move

		-- Hit
		if toTarget.Magnitude < 2 then
			hit = true
			nailConn:Disconnect()
			target.humanoid:TakeDamage(10)

			-- Impact spark
			local spark = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.8,0.8,0.8),
				Position=newPos, Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(255,220,80), Material=Enum.Material.Neon, Transparency=0.2, Parent=workspace})
			TweenService:Create(spark, TweenInfo.new(0.2), {Size=Vector3.new(3,3,3), Transparency=1}):Play()
			Debris:AddItem(spark, 0.21)

			-- Nail sticks into dummy briefly
			nail.Anchored = false
			local nailWeld = Instance.new("WeldConstraint") nailWeld.Part0=target.torso nailWeld.Part1=nail nailWeld.Parent=target.torso
			Debris:AddItem(nail, 1.5)
		end

		if traveled > 200 then
			nailConn:Disconnect()
			pcall(function() nail:Destroy() end)
		end
	end)
end

-- ---- DOLL ----
function fireNobara_Doll()
	if isCooldown("Doll") or isChanneling then return end

	cleanDolls()

	-- Find nearest dummy that doesn't already have a doll
	local hasDollSet = {}
	for _, d in ipairs(nobaraDolls) do hasDollSet[d.entry] = true end

	local target = getNearestDummy(function(e) return not hasDollSet[e] end)
	if not target then return end
	if activeDollCount() >= MAX_DOLLS then return end

	startCD("Doll", 3)

	-- Doll visual: small humanoid-shaped figure thrown at target
	local dollModel = Instance.new("Model") dollModel.Name="Doll" dollModel.Parent=workspace

	local dollBody = makePart({
		Size=Vector3.new(0.5,0.7,0.3),
		Position=hrp.Position+Vector3.new(0,1.5,0),
		Anchored=false, CanCollide=false,
		Color=Color3.fromRGB(240,220,180), Material=Enum.Material.SmoothPlastic,
		Parent=dollModel
	})
	local dollHead = makePart({
		Shape=Enum.PartType.Ball, Size=Vector3.new(0.4,0.4,0.4),
		Position=dollBody.Position+Vector3.new(0,0.55,0),
		Anchored=false, CanCollide=false,
		Color=Color3.fromRGB(240,220,180), Material=Enum.Material.SmoothPlastic,
		Parent=dollModel
	})
	local dhw = Instance.new("WeldConstraint") dhw.Part0=dollBody dhw.Part1=dollHead dhw.Parent=dollBody
	dollModel.PrimaryPart = dollBody

	-- Blue highlight aura on dummy
	local aura = makePart({
		Size=target.torso.Size*Vector3.new(1.15,1.15,1.15),
		CFrame=target.torso.CFrame,
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(60,120,255), Material=Enum.Material.Neon,
		Transparency=0.5, Parent=workspace
	})
	local auraw = Instance.new("WeldConstraint") auraw.Part0=target.torso auraw.Part1=aura auraw.Parent=target.torso

	-- Fly doll toward target
	local throwOrigin = hrp.Position + Vector3.new(0,1.5,0)
	local throwTarget = target.torso.Position + Vector3.new(0,1,0)
	local throwTime   = 0.6
	local throwElap   = 0
	local flyConn
	flyConn = RunService.Heartbeat:Connect(function(dt)
		throwElap = throwElap + dt
		local t = math.min(throwElap / throwTime, 1)
		-- Arc trajectory
		local lerpPos = throwOrigin:Lerp(throwTarget, t)
		lerpPos = lerpPos + Vector3.new(0, math.sin(t*math.pi)*3, 0)
		dollBody.CFrame = CFrame.new(lerpPos)
		if t >= 1 then
			flyConn:Disconnect()
			-- Attach doll to dummy via weld
			dollBody.Anchored = false
			local dw = Instance.new("WeldConstraint") dw.Part0=target.torso dw.Part1=dollBody dw.Parent=target.torso

			local dollRecord = {entry=target, state="attached", dollPart=dollBody, aura=aura, resonance=false}
			table.insert(nobaraDolls, dollRecord)

			-- After 5 seconds doll drops (becomes resonance doll)
			task.delay(5, function()
				if target.humanoid.Health <= 0 then return end
				dollRecord.state = "dropped"
				-- Detach from dummy
				for _, ch in ipairs(target.torso:GetChildren()) do
					if ch:IsA("WeldConstraint") and (ch.Part0==dollBody or ch.Part1==dollBody) then ch:Destroy() end
				end
				-- Remove aura
				pcall(function() aura:Destroy() end)

				-- Drop doll to ground
				dollBody.Anchored = false
				dollBody.CanCollide = true
				local bv = Instance.new("BodyVelocity") bv.Velocity=Vector3.new(0,-10,0) bv.MaxForce=Vector3.new(0,1e5,0) bv.P=5000 bv.Parent=dollBody
				Debris:AddItem(bv, 0.5)

				-- Resonance glow
				local resGlow = Instance.new("PointLight") resGlow.Color=Color3.fromRGB(80,160,255) resGlow.Brightness=4 resGlow.Range=10 resGlow.Parent=dollBody
				dollBody.Color = Color3.fromRGB(80,160,255)

				-- Billboard "Pick up" prompt
				local resGui = Instance.new("BillboardGui")
				resGui.Size = UDim2.new(0,100,0,24)
				resGui.StudsOffset = Vector3.new(0,2,0)
				resGui.AlwaysOnTop = true
				resGui.Parent = dollBody
				local resLabel = Instance.new("TextLabel")
				resLabel.Size = UDim2.new(1,0,1,0)
				resLabel.BackgroundTransparency = 1
				resLabel.Text = "🔵 Pick Up"
				resLabel.TextColor3 = Color3.fromRGB(100,200,255)
				resLabel.Font = Enum.Font.GothamBold
				resLabel.TextScaled = true
				resLabel.Parent = resGui

				-- Store as world resonance doll
				if resonanceDoll and resonanceDoll.Parent then resonanceDoll:Destroy() end
				resonanceDoll = dollBody
				resonanceActive = false
				-- Link this dummy to resonance
				dollRecord.resonance = true
				if not table.find(resonanceDummies, target) then
					table.insert(resonanceDummies, target)
				end
			end)
		end
	end)
end

-- ---- TORTURE ----
function fireNobara_Torture()
	if isCooldown("Torture") or isChanneling then return end

	-- Need at least one doll attached somewhere
	cleanDolls()
	local hasDoll = false
	for _, d in ipairs(nobaraDolls) do
		if d.state == "attached" and d.entry.humanoid.Health > 0 then hasDoll = true break end
	end
	if not hasDoll and not resonanceActive then return end

	startCD("Torture", 13)
	isChanneling = true

	-- Animation: hammer appears above player, slams down onto a tiny doll model
	local hammerOrigin = hrp.Position + Vector3.new(0, 4, 0)
	local hammerHandle = makePart({
		Size=Vector3.new(0.2,1.8,0.2),
		Position=hammerOrigin,
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(80,50,20), Material=Enum.Material.SmoothPlastic, Parent=workspace
	})
	local hammerHead = makePart({
		Size=Vector3.new(0.8,0.5,0.5),
		Position=hammerOrigin+Vector3.new(0,1,0),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(60,60,60), Material=Enum.Material.SmoothPlastic, Parent=workspace
	})
	local hhw = Instance.new("WeldConstraint") hhw.Part0=hammerHandle hhw.Part1=hammerHead hhw.Parent=hammerHandle

	-- Raise hammer
	TweenService:Create(hammerHandle, TweenInfo.new(0.3), {Position=hammerOrigin+Vector3.new(0,2,0)}):Play()
	task.wait(0.5)

	-- Slam down
	TweenService:Create(hammerHandle, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position=hrp.Position+Vector3.new(0,0.5,0)}):Play()
	task.wait(0.15)

	-- Impact shockwave
	local impactRing = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1,1,1),
		Position=hrp.Position+Vector3.new(0,0.5,0),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(255,80,80), Material=Enum.Material.Neon, Transparency=0.3, Parent=workspace})
	TweenService:Create(impactRing, TweenInfo.new(0.3), {Size=Vector3.new(8,8,8), Transparency=1}):Play()
	Debris:AddItem(impactRing, 0.31)
	startShake(1)
	task.delay(0.4, stopShake)

	-- Deal 15 damage to all dummies with attached dolls
	for _, d in ipairs(nobaraDolls) do
		if d.state == "attached" and d.entry.humanoid.Health > 0 then
			d.entry.humanoid:TakeDamage(15)
			-- Nail impact flash on the dummy
			local flash = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1,1,1),
				Position=d.entry.torso.Position, Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(255,100,100), Material=Enum.Material.Neon, Transparency=0.2, Parent=workspace})
			TweenService:Create(flash, TweenInfo.new(0.25), {Size=Vector3.new(5,5,5), Transparency=1}):Play()
			Debris:AddItem(flash, 0.26)
		end
	end

	-- If resonance is active, also damage resonance-linked dummies
	if resonanceActive then
		for _, re in ipairs(resonanceDummies) do
			if re.humanoid.Health > 0 then
				re.humanoid:TakeDamage(15)
				local flash2 = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1,1,1),
					Position=re.torso.Position, Anchored=true, CanCollide=false,
					Color=Color3.fromRGB(100,180,255), Material=Enum.Material.Neon, Transparency=0.2, Parent=workspace})
				TweenService:Create(flash2, TweenInfo.new(0.25), {Size=Vector3.new(5,5,5), Transparency=1}):Play()
				Debris:AddItem(flash2, 0.26)
			end
		end
	end

	Debris:AddItem(hammerHandle, 0.5)
	task.wait(0.3)
	isChanneling = false
end

-- ---- EXPLOSIVE NAILS ----
function fireNobara_ExplosiveNails()
	if isCooldown("ExplosiveNails") or isChanneling then return end
	startCD("ExplosiveNails", 15)

	-- If player has resonance doll, put explosive nail INTO the doll and hammer → explode all resonance dummies
	if resonanceActive then
		isChanneling = true

		-- Show nail going into held doll (above player)
		local dollGlowPos = hrp.Position + Vector3.new(0, 2.5, 0)
		local expNailVis = makePart({
			Size=Vector3.new(0.18,0.18,1.4),
			CFrame=CFrame.new(dollGlowPos+Vector3.new(0,2,0), dollGlowPos),
			Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(220,180,60), Material=Enum.Material.Neon, Parent=workspace
		})
		TweenService:Create(expNailVis, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{CFrame=CFrame.new(dollGlowPos+Vector3.new(0,0.1,0), dollGlowPos-Vector3.new(0,1,0))}):Play()
		task.wait(0.3)
		Debris:AddItem(expNailVis, 0.1)

		-- Mini hammer slam (instant) 
		startShake(1.5)
		task.delay(0.3, stopShake)

		-- EXPLOSION on every resonance dummy
		for _, re in ipairs(resonanceDummies) do
			if re.humanoid.Health > 0 then
				re.humanoid:TakeDamage(35)

				-- Big explosion visual on each
				local expl = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(2,2,2),
					Position=re.torso.Position, Anchored=true, CanCollide=false,
					Color=Color3.fromRGB(255,160,30), Material=Enum.Material.Neon, Transparency=0.1, Parent=workspace})
				local epl = Instance.new("PointLight") epl.Brightness=8 epl.Range=20 epl.Color=Color3.fromRGB(255,140,20) epl.Parent=expl
				TweenService:Create(expl, TweenInfo.new(0.5), {Size=Vector3.new(14,14,14), Transparency=1}):Play()
				Debris:AddItem(expl, 0.51)

				-- Knockback
				local blastDir = (re.torso.Position - hrp.Position).Unit
				local bv = Instance.new("BodyVelocity") bv.Velocity=blastDir*55+Vector3.new(0,28,0) bv.MaxForce=Vector3.new(1e5,1e5,1e5) bv.P=1e5 bv.Parent=re.torso
				Debris:AddItem(bv, 0.3)

				-- Debris shards
				for i=1,6 do
					local shard=makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.4,0.4,0.4),
						Position=re.torso.Position+Vector3.new(math.random(-2,2),math.random(0,3),math.random(-2,2)),
						Anchored=false, CanCollide=false,
						Color=Color3.fromRGB(255,200,60), Material=Enum.Material.Neon, Transparency=0.3, Parent=workspace})
					TweenService:Create(shard, TweenInfo.new(0.6), {Transparency=1, Position=shard.Position+Vector3.new(math.random(-5,5),math.random(3,8),math.random(-5,5))}):Play()
					Debris:AddItem(shard, 0.61)
				end
			end
		end

		-- Consume resonance doll
		resonanceActive = false
		resonanceDummies = {}
		-- Clean up doll records that were resonance
		local newDolls = {}
		for _, d in ipairs(nobaraDolls) do
			if not d.resonance then table.insert(newDolls, d) end
		end
		nobaraDolls = newDolls

		task.wait(0.2)
		isChanneling = false

	else
		-- No resonance: fire a homing explosive nail at nearest dummy (20 dmg + knockback)
		local target = getNearestDummy()
		if not target then return end

		local nailPos = hrp.Position + Vector3.new(0, 1.2, 0)
		local nail = makePart({
			Size=Vector3.new(0.2,0.2,1.4),
			CFrame=CFrame.new(nailPos, target.torso.Position),
			Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(255,200,50), Material=Enum.Material.Neon, Parent=workspace
		})
		local nl=Instance.new("PointLight") nl.Brightness=3 nl.Range=8 nl.Color=Color3.fromRGB(255,180,30) nl.Parent=nail

		local traveled=0; local speed=95; local lastPos=nailPos; local hit=false

		local nailConn
		nailConn = RunService.Heartbeat:Connect(function(dt)
			if not nail.Parent or hit then nailConn:Disconnect() return end
			if not target or target.humanoid.Health<=0 then
				traveled=traveled+speed*dt
				if traveled>130 then nailConn:Disconnect() pcall(function() nail:Destroy() end) end
				return
			end
			local toTarget=(target.torso.Position-lastPos)
			local move=math.min(speed*dt, toTarget.Magnitude)
			local dir=toTarget.Unit
			local newPos=lastPos+dir*move
			nail.CFrame=CFrame.new(newPos, target.torso.Position)
			lastPos=newPos; traveled=traveled+move

			if toTarget.Magnitude<2.5 then
				hit=true; nailConn:Disconnect()
				nail:Destroy()

				target.humanoid:TakeDamage(20)

				-- Explosion
				local expl=makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1.5,1.5,1.5),
					Position=target.torso.Position, Anchored=true, CanCollide=false,
					Color=Color3.fromRGB(255,160,30), Material=Enum.Material.Neon, Transparency=0.1, Parent=workspace})
				TweenService:Create(expl, TweenInfo.new(0.4), {Size=Vector3.new(10,10,10), Transparency=1}):Play()
				Debris:AddItem(expl, 0.41)

				-- Knockback
				local blastDir=(target.torso.Position-hrp.Position).Unit
				local bv=Instance.new("BodyVelocity") bv.Velocity=blastDir*50+Vector3.new(0,22,0) bv.MaxForce=Vector3.new(1e5,1e5,1e5) bv.P=1e5 bv.Parent=target.torso
				Debris:AddItem(bv, 0.25)
			end
			if traveled>200 then nailConn:Disconnect() pcall(function() nail:Destroy() end) end
		end)
	end
end

-- ============================================================
-- RESONANCE DOLL PICKUP DETECTION (runs in heartbeat)
-- ============================================================
local function checkDollPickup(dt)
	if resonanceDoll and resonanceDoll.Parent and not resonanceActive then
		local dist = (resonanceDoll.Position - hrp.Position).Magnitude
		if dist < 4 then
			-- Pick up
			resonanceActive = true
			resonanceDoll:Destroy()
			resonanceDoll = nil

			-- Show HUD indicator
			local pickupNotice = Instance.new("TextLabel")
			pickupNotice.Size = UDim2.new(0, 200, 0, 36)
			pickupNotice.Position = UDim2.new(0.5, -100, 0.35, 0)
			pickupNotice.BackgroundColor3 = Color3.fromRGB(20,60,140)
			pickupNotice.BackgroundTransparency = 0.2
			pickupNotice.BorderSizePixel = 0
			pickupNotice.Text = "🔵 Resonance Active!"
			pickupNotice.TextColor3 = Color3.fromRGB(150,210,255)
			pickupNotice.Font = Enum.Font.GothamBold
			pickupNotice.TextSize = 14
			pickupNotice.Parent = screenGui
			addCorner(pickupNotice, 8)
			TweenService:Create(pickupNotice, TweenInfo.new(2.5), {TextTransparency=1, BackgroundTransparency=1}):Play()
			Debris:AddItem(pickupNotice, 2.6)
		end
	end
end


-- ============================================================
-- ========= MEGUMI ABILITIES =================================
-- ============================================================

-- ---- RABBIT ESCAPE ----
function fireMegumi_RabbitEscape()
	if isCooldown("RabbitEscape") or isChanneling then return end
	startCD("RabbitEscape", 10)

	local spawnCenter = hrp.Position

	-- Spawn 50 small rabbits that rise upward from the ground around the player
	local rabbitParts = {}
	for i = 1, 50 do
		local angle = (i / 50) * math.pi * 2 + math.random() * 0.4
		local r     = math.random() * 5
		local startPos = spawnCenter + Vector3.new(math.cos(angle)*r, -1, math.sin(angle)*r)
		local rSize = math.random() * 0.4 + 0.5

		-- Rabbit body
		local rb = makePart({
			Shape=Enum.PartType.Ball, Size=Vector3.new(rSize, rSize*1.2, rSize),
			Position=startPos,
			Anchored=false, CanCollide=false,
			Color=Color3.fromRGB(240,240,235), Material=Enum.Material.SmoothPlastic,
			Parent=workspace
		})
		-- Rabbit head
		local rh = makePart({
			Shape=Enum.PartType.Ball, Size=Vector3.new(rSize*0.7, rSize*0.7, rSize*0.7),
			Position=startPos+Vector3.new(0, rSize*0.9, 0),
			Anchored=false, CanCollide=false,
			Color=Color3.fromRGB(240,240,235), Material=Enum.Material.SmoothPlastic,
			Parent=workspace
		})
		-- Ear 1
		local re1 = makePart({
			Size=Vector3.new(rSize*0.15, rSize*0.6, rSize*0.1),
			Position=rh.Position+Vector3.new(-rSize*0.2, rSize*0.55, 0),
			Anchored=false, CanCollide=false,
			Color=Color3.fromRGB(255,200,200), Material=Enum.Material.SmoothPlastic,
			Parent=workspace
		})
		-- Ear 2
		local re2 = makePart({
			Size=Vector3.new(rSize*0.15, rSize*0.6, rSize*0.1),
			Position=rh.Position+Vector3.new(rSize*0.2, rSize*0.55, 0),
			Anchored=false, CanCollide=false,
			Color=Color3.fromRGB(255,200,200), Material=Enum.Material.SmoothPlastic,
			Parent=workspace
		})
		local rhw  = Instance.new("WeldConstraint") rhw.Part0=rb  rhw.Part1=rh  rhw.Parent=rb
		local re1w = Instance.new("WeldConstraint") re1w.Part0=rh re1w.Part1=re1 re1w.Parent=rh
		local re2w = Instance.new("WeldConstraint") re2w.Part0=rh re2w.Part1=re2 re2w.Parent=rh

		-- Give each rabbit upward velocity
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = Vector3.new(
			(math.random()-0.5)*12,
			math.random(20, 32),
			(math.random()-0.5)*12
		)
		bv.MaxForce = Vector3.new(1e4, 1e5, 1e4)
		bv.P = 5000
		bv.Parent = rb
		Debris:AddItem(bv, 0.5)

		table.insert(rabbitParts, {rb, rh, re1, re2})
	end

	-- Lift player up slightly
	local playerBv = Instance.new("BodyVelocity")
	playerBv.Velocity = Vector3.new(0, 18, 0)
	playerBv.MaxForce = Vector3.new(0, 1e5, 0)
	playerBv.P = 8000
	playerBv.Parent = hrp
	Debris:AddItem(playerBv, 0.4)

	-- Damage any dummies in the rising rabbit cloud (up to 8 studs radius)
	for _, e in ipairs(spawnedDummies) do
		if e.humanoid.Health > 0 and (e.torso.Position - spawnCenter).Magnitude <= 8 then
			e.humanoid:TakeDamage(15)
			-- Fling upward + outward
			local fDir = (e.torso.Position - spawnCenter)
			fDir = Vector3.new(fDir.X, 0, fDir.Z)
			if fDir.Magnitude < 0.1 then fDir = Vector3.new(1,0,0) end
			fDir = fDir.Unit
			local bv2 = Instance.new("BodyVelocity")
			bv2.Velocity = fDir*30 + Vector3.new(0,35,0)
			bv2.MaxForce = Vector3.new(1e5,1e5,1e5)
			bv2.P = 1e5
			bv2.Parent = e.torso
			Debris:AddItem(bv2, 0.35)
		end
	end

	-- Rabbits collapse after 4 seconds
	task.delay(4, function()
		for _, group in ipairs(rabbitParts) do
			for _, p in ipairs(group) do
				if p and p.Parent then
					TweenService:Create(p, TweenInfo.new(0.5), {Transparency=1, Size=Vector3.new(0.1,0.1,0.1)}):Play()
					Debris:AddItem(p, 0.55)
				end
			end
		end
	end)
end

-- ---- TOAD ----
function fireMegumi_Toad()
	if isCooldown("Toad") or isChanneling then return end

	local target = getNearestDummy()
	if not target then return end
	startCD("Toad", 9)

	local toadSpawnPos = hrp.Position + Vector3.new(0, -1.5, 0)
	local toadTarget   = target.torso.Position

	-- Toad body (large green blob)
	local toadBody = makePart({
		Shape=Enum.PartType.Ball,
		Size=Vector3.new(4, 3, 4),
		Position=toadSpawnPos,
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(50, 130, 50), Material=Enum.Material.SmoothPlastic,
		Parent=workspace
	})
	-- Toad eyes (two bumps on top)
	local eyeL = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.8,0.8,0.8),
		Position=toadBody.Position+Vector3.new(-0.8,1.7,0.5), Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(255,200,50), Material=Enum.Material.SmoothPlastic, Parent=workspace})
	local eyeR = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.8,0.8,0.8),
		Position=toadBody.Position+Vector3.new(0.8,1.7,0.5), Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(255,200,50), Material=Enum.Material.SmoothPlastic, Parent=workspace})
	local elw = Instance.new("WeldConstraint") elw.Part0=toadBody elw.Part1=eyeL elw.Parent=toadBody
	local erw = Instance.new("WeldConstraint") erw.Part0=toadBody erw.Part1=eyeR erw.Parent=toadBody

	-- Toad appears with a quick scale-in
	toadBody.Size = Vector3.new(0.5,0.5,0.5)
	TweenService:Create(toadBody, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size=Vector3.new(4,3,4)}):Play()

	task.wait(0.4)

	-- Fire tongue (thin green line extending to target)
	local tongueDir = (toadTarget - toadSpawnPos)
	local tongueLen = tongueDir.Magnitude
	tongueDir = tongueDir.Unit

	local tongue = makePart({
		Size=Vector3.new(0.3, 0.3, 0.2),
		CFrame=CFrame.new(toadSpawnPos, toadTarget) * CFrame.new(0,0,-0.1),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(220,60,60), Material=Enum.Material.Neon,
		Parent=workspace
	})

	-- Tongue extends out
	TweenService:Create(tongue, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size=Vector3.new(0.35, 0.35, tongueLen),
		 CFrame=CFrame.new(toadSpawnPos+tongueDir*(tongueLen/2), toadTarget)}):Play()

	task.wait(0.22)

	-- Hit!
	target.humanoid:TakeDamage(13)

	-- Impact flash
	local imp = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1,1,1),
		Position=toadTarget, Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(100,220,80), Material=Enum.Material.Neon, Transparency=0.3, Parent=workspace})
	TweenService:Create(imp, TweenInfo.new(0.25), {Size=Vector3.new(5,5,5), Transparency=1}):Play()
	Debris:AddItem(imp, 0.26)

	-- Pull dummy slightly toward toad
	local pullDir = (toadSpawnPos - toadTarget).Unit
	local pbv = Instance.new("BodyVelocity")
	pbv.Velocity = pullDir * 20 + Vector3.new(0,5,0)
	pbv.MaxForce = Vector3.new(1e5,1e5,1e5) pbv.P=1e4 pbv.Parent=target.torso
	Debris:AddItem(pbv, 0.3)

	-- Tongue retracts
	TweenService:Create(tongue, TweenInfo.new(0.15), {Size=Vector3.new(0.3,0.3,0.1)}):Play()
	Debris:AddItem(tongue, 0.16)

	-- Toad disappears after hit
	task.delay(0.6, function()
		TweenService:Create(toadBody, TweenInfo.new(0.3),
			{Size=Vector3.new(0.1,0.1,0.1), Transparency=1}):Play()
		Debris:AddItem(toadBody, 0.31)
	end)
end

-- ---- MAX ELEPHANT ----
function fireMegumi_MaxElephant()
	if isCooldown("MaxElephant") or isChanneling then return end
	-- Toggle: if already active cancel
	if elephantActive then
		elephantActive = false
		if elephantZoneConn then elephantZoneConn:Disconnect() elephantZoneConn=nil end
		if elephantZone and elephantZone.Parent then elephantZone:Destroy() elephantZone=nil end
		return
	end
	startCD("MaxElephant", 15)
	elephantActive    = true
	elephantStillTimer = 0
	elephantLastPos   = nil

	-- Red targeting zone (flat cylinder on ground)
	elephantZone = makePart({
		Shape=Enum.PartType.Cylinder,
		Size=Vector3.new(0.5, 40, 40),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(220,40,40),
		Material=Enum.Material.Neon,
		Transparency=0.55,
		Parent=workspace,
	})
	elephantZone.CFrame = CFrame.new(getMouseWorldPos()) * CFrame.Angles(0,0,math.pi/2)

	-- Zone follows cursor
	local STILL_THRESHOLD = 2    -- studs of movement to reset timer
	local CHARGE_TIME     = 3    -- seconds standing still to trigger

	elephantZoneConn = RunService.Heartbeat:Connect(function(dt)
		if not elephantActive or not elephantZone or not elephantZone.Parent then
			if elephantZoneConn then elephantZoneConn:Disconnect() elephantZoneConn=nil end
			return
		end

		local mousePos = getMouseWorldPos()
		local flatMousePos = Vector3.new(mousePos.X, hrp.Position.Y - 2, mousePos.Z)
		elephantZone.CFrame = CFrame.new(flatMousePos) * CFrame.Angles(0,0,math.pi/2)

		-- Check if player is standing still within the zone
		local playerFlat = Vector3.new(hrp.Position.X, flatMousePos.Y, hrp.Position.Z)
		local distToZoneCenter = (playerFlat - flatMousePos).Magnitude

		if distToZoneCenter <= 20 then
			-- Player is inside the zone
			if elephantLastPos == nil then
				elephantLastPos = hrp.Position
			end
			local moved = (hrp.Position - elephantLastPos).Magnitude
			if moved < STILL_THRESHOLD * dt * 5 then
				elephantStillTimer = elephantStillTimer + dt
				-- Flash zone faster as it charges
				local pulse = 0.4 + math.sin(elephantStillTimer * 8) * 0.15
				elephantZone.Transparency = pulse
			else
				elephantStillTimer = 0
				elephantLastPos = hrp.Position
				elephantZone.Transparency = 0.55
			end
			elephantLastPos = hrp.Position
		else
			elephantStillTimer = 0
			elephantZone.Transparency = 0.55
		end

		-- Trigger elephant after 3 seconds still
		if elephantStillTimer >= CHARGE_TIME then
			elephantZoneConn:Disconnect() elephantZoneConn=nil
			elephantActive = false

			local dropPos = flatMousePos + Vector3.new(0, 2, 0)

			-- ── Elephant drop animation ──
			-- Pink elephant body (large) descends from high above
			local eBody = makePart({
				Shape=Enum.PartType.Ball,
				Size=Vector3.new(6,5,8),
				Position=dropPos + Vector3.new(0, 40, 0),  -- high above
				Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(230,160,200), Material=Enum.Material.SmoothPlastic,
				Parent=workspace
			})
			-- Head
			local eHead = makePart({
				Shape=Enum.PartType.Ball, Size=Vector3.new(4,4,4),
				Position=eBody.Position+Vector3.new(0,0,5),
				Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(230,160,200), Material=Enum.Material.SmoothPlastic, Parent=workspace})
			-- Trunk
			local eTrunk = makePart({
				Size=Vector3.new(0.8,0.8,4),
				Position=eHead.Position+Vector3.new(0,-1,3),
				Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(220,150,190), Material=Enum.Material.SmoothPlastic, Parent=workspace})
			-- 4 Legs
			local legPositions = {Vector3.new(-2,-3,2), Vector3.new(2,-3,2), Vector3.new(-2,-3,-2), Vector3.new(2,-3,-2)}
			local legs = {}
			for _, lOff in ipairs(legPositions) do
				local leg = makePart({Size=Vector3.new(1.2,3,1.2),
					Position=eBody.Position+lOff,
					Anchored=true, CanCollide=false,
					Color=Color3.fromRGB(225,155,195), Material=Enum.Material.SmoothPlastic, Parent=workspace})
				table.insert(legs, leg)
			end
			-- Ears
			local earL = makePart({Size=Vector3.new(0.4,3,4),
				Position=eHead.Position+Vector3.new(-2.5,0,0),
				Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(240,170,210), Material=Enum.Material.SmoothPlastic, Parent=workspace})
			local earR = makePart({Size=Vector3.new(0.4,3,4),
				Position=eHead.Position+Vector3.new(2.5,0,0),
				Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(240,170,210), Material=Enum.Material.SmoothPlastic, Parent=workspace})

			local elephantParts = {eBody, eHead, eTrunk, earL, earR}
			for _, l in ipairs(legs) do table.insert(elephantParts, l) end

			-- Drop shadow zone
			elephantZone.Color = Color3.fromRGB(180,100,140)
			elephantZone.Parent = workspace  -- keep it for shadow

			-- Descend tween (everything drops from 40 studs above to ground level)
			local dropOffset = Vector3.new(0, -40, 0)
			for _, p in ipairs(elephantParts) do
				TweenService:Create(p, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{Position=p.Position+dropOffset}):Play()
			end

			task.wait(0.52)

			-- SMASH impact
			startShake(3)
			task.delay(0.5, stopShake)

			-- Ground crack shockwave
			local crack = makePart({
				Shape=Enum.PartType.Cylinder,
				Size=Vector3.new(0.5, 3, 3),
				CFrame=CFrame.new(dropPos)*CFrame.Angles(0,0,math.pi/2),
				Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(60,40,30), Material=Enum.Material.SmoothPlastic,
				Parent=workspace
			})
			TweenService:Create(crack, TweenInfo.new(0.6), {Size=Vector3.new(0.5,50,50), Transparency=1}):Play()
			Debris:AddItem(crack, 0.61)

			-- Dust puff ring
			for i=1,10 do
				local dustAngle = (i/10)*math.pi*2
				local dustPuff = makePart({Shape=Enum.PartType.Ball,
					Size=Vector3.new(1,1,1),
					Position=dropPos+Vector3.new(math.cos(dustAngle)*3, 0.5, math.sin(dustAngle)*3),
					Anchored=true, CanCollide=false,
					Color=Color3.fromRGB(180,160,140), Material=Enum.Material.SmoothPlastic, Transparency=0.2,
					Parent=workspace})
				TweenService:Create(dustPuff, TweenInfo.new(0.7), {
					Size=Vector3.new(4,3,4),
					Position=dustPuff.Position+Vector3.new(math.cos(dustAngle)*6, 2, math.sin(dustAngle)*6),
					Transparency=1
				}):Play()
				Debris:AddItem(dustPuff, 0.71)
			end

			-- Land debris: broken rock/rubble chunks scattered around
			for i=1,16 do
				local debrisAngle = math.random()*math.pi*2
				local debrisDist  = math.random(3,14)
				local debrisPos   = dropPos+Vector3.new(math.cos(debrisAngle)*debrisDist, 0.5, math.sin(debrisAngle)*debrisDist)
				local debris = makePart({
					Size=Vector3.new(math.random(1,3), math.random(1,3), math.random(1,2)),
					Position=debrisPos+Vector3.new(0,6,0),
					Anchored=false, CanCollide=true,
					Color=Color3.fromRGB(math.random(60,100), math.random(50,80), math.random(40,60)),
					Material=Enum.Material.SmoothPlastic,
					Parent=workspace
				})
				local dbv = Instance.new("BodyVelocity")
				dbv.Velocity=Vector3.new(math.cos(debrisAngle)*12, math.random(10,20), math.sin(debrisAngle)*12)
				dbv.MaxForce=Vector3.new(1e4,1e4,1e4) dbv.P=3000 dbv.Parent=debris
				Debris:AddItem(dbv, 0.4)
				Debris:AddItem(debris, 4)
			end

			-- Damage dummies in zone
			for _, e in ipairs(spawnedDummies) do
				if e.humanoid.Health > 0 then
					local edist = (e.torso.Position - dropPos).Magnitude
					if edist <= 22 then
						e.humanoid:TakeDamage(20)
						local blastDir = (e.torso.Position-dropPos)
						blastDir = Vector3.new(blastDir.X,0,blastDir.Z)
						if blastDir.Magnitude < 0.1 then blastDir=Vector3.new(1,0,0) end
						blastDir = blastDir.Unit
						local bv3 = Instance.new("BodyVelocity")
						bv3.Velocity=blastDir*40+Vector3.new(0,25,0)
						bv3.MaxForce=Vector3.new(1e5,1e5,1e5) bv3.P=1e5 bv3.Parent=e.torso
						Debris:AddItem(bv3, 0.3)
					end
				end
			end

			-- Elephant fades out
			for _, p in ipairs(elephantParts) do
				TweenService:Create(p, TweenInfo.new(0.8),
					{Transparency=1, Size=p.Size*Vector3.new(1.1,0.1,1.1)}):Play()
				Debris:AddItem(p, 0.85)
			end

			TweenService:Create(elephantZone, TweenInfo.new(0.5), {Transparency=1}):Play()
			Debris:AddItem(elephantZone, 0.6)
			elephantZone = nil
		end
	end)
end

-- ---- WITH THIS TREASURE I SUMMON (Coming Soon) ----
function fireMegumi_Summon()
	if isCooldown("Summon") or isChanneling or domainActive then return end
	startCD("Summon", 180)
	isChanneling = true
	domainActive = true

	-- ── Helper: show a dialogue bubble above the player ──
	local function showDialogue(text, duration)
		local db = Instance.new("BillboardGui")
		db.Size = UDim2.new(0, 300, 0, 60)
		db.StudsOffset = Vector3.new(0, 7, 0)
		db.AlwaysOnTop = true
		db.Parent = hrp
		local dl = Instance.new("TextLabel")
		dl.Size = UDim2.new(1,0,1,0)
		dl.BackgroundColor3 = Color3.fromRGB(5,5,15)
		dl.BackgroundTransparency = 0.25
		dl.BorderSizePixel = 0
		dl.Text = text
		dl.TextColor3 = Color3.fromRGB(220,220,255)
		dl.Font = Enum.Font.GothamBold
		dl.TextSize = 14
		dl.TextWrapped = true
		dl.Parent = db
		addCorner(dl, 8)
		Debris:AddItem(db, duration + 0.1)
		return db
	end

	-- ── Helper: a simple neon sphere with a PointLight ──
	local function glowSphere(pos, color, size, bright, range)
		local p = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(size,size,size),
			Position=pos, Anchored=true, CanCollide=false,
			Color=color, Material=Enum.Material.Neon, Transparency=0.1, Parent=workspace})
		local l = Instance.new("PointLight") l.Color=color l.Brightness=bright l.Range=range l.Parent=p
		return p
	end

	-- ========== PHASE 1: Freeze + dialogue "With this treasure I summon..." ==========
	-- Freeze all dummies
	local frozenForSummon = {}
	for _, e in ipairs(spawnedDummies) do
		if e.humanoid.Health > 0 then
			e.frozen = true
			e.torso.Anchored = true
			table.insert(frozenForSummon, e)
		end
	end

	-- Freeze player movement
	local playerAnchor = Instance.new("BodyVelocity")
	playerAnchor.Velocity = Vector3.new(0,0,0)
	playerAnchor.MaxForce = Vector3.new(1e5,0,1e5)
	playerAnchor.P = 1e5
	playerAnchor.Parent = hrp

	-- Dialogue 0
	showDialogue("\"With this treasure I summon...\"", 3)
	task.wait(2)

	-- ========== PHASE 2: Night fog / darkness overlay ==========
	local nightOverlay = Instance.new("Frame")
	nightOverlay.Size = UDim2.new(1,0,1,0)
	nightOverlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
	nightOverlay.BackgroundTransparency = 1
	nightOverlay.BorderSizePixel = 0
	nightOverlay.ZIndex = 18
	nightOverlay.Parent = screenGui

	TweenService:Create(nightOverlay, TweenInfo.new(2), {BackgroundTransparency=0.35}):Play()
	task.wait(2)

	-- ========== PHASE 3: Player glow ==========
	local playerGlow = glowSphere(hrp.Position, Color3.fromRGB(200,220,255), 3, 6, 18)
	local playerGlowWeld = Instance.new("WeldConstraint")
	playerGlowWeld.Part0 = hrp
	playerGlowWeld.Part1 = playerGlow
	playerGlowWeld.Parent = hrp

	-- Pulsing glow tween loop
	local glowPulse = true
	local function pulseGlow()
		if not glowPulse or not playerGlow.Parent then return end
		TweenService:Create(playerGlow, TweenInfo.new(0.6), {Size=Vector3.new(4.5,4.5,4.5), Transparency=0.3}):Play()
		task.delay(0.62, function()
			if not glowPulse or not playerGlow.Parent then return end
			TweenService:Create(playerGlow, TweenInfo.new(0.6), {Size=Vector3.new(2.5,2.5,2.5), Transparency=0.05}):Play()
			task.delay(0.62, pulseGlow)
		end)
	end
	pulseGlow()
	task.wait(1)

	-- ========== PHASE 4: 5 White Toads surround player ==========
	local toadParts = {}
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		local r     = 10
		local tp    = hrp.Position + Vector3.new(math.cos(angle)*r, -1, math.sin(angle)*r)

		-- Toad body (white)
		local tb = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.1,0.1,0.1),
			Position=tp, Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(240,240,240), Material=Enum.Material.SmoothPlastic, Parent=workspace})
		local th = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.1,0.1,0.1),
			Position=tp+Vector3.new(0,2,0), Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(240,240,240), Material=Enum.Material.SmoothPlastic, Parent=workspace})
		local te1 = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.1,0.1,0.1),
			Position=th.Position+Vector3.new(-0.7,1.3,0), Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(220,240,255), Material=Enum.Material.Neon, Parent=workspace})
		local te2 = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.1,0.1,0.1),
			Position=th.Position+Vector3.new(0.7,1.3,0), Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(220,240,255), Material=Enum.Material.Neon, Parent=workspace})
		local tw1 = Instance.new("WeldConstraint") tw1.Part0=tb tw1.Part1=th tw1.Parent=tb
		local tw2 = Instance.new("WeldConstraint") tw2.Part0=tb tw2.Part1=te1 tw2.Parent=tb
		local tw3 = Instance.new("WeldConstraint") tw3.Part0=tb tw3.Part1=te2 tw3.Parent=tb

		-- Toad light
		local tl = Instance.new("PointLight") tl.Color=Color3.fromRGB(200,220,255) tl.Brightness=3 tl.Range=12 tl.Parent=tb

		-- Scale-in appear animation
		TweenService:Create(tb,  TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=Vector3.new(3,2.5,3)}):Play()
		TweenService:Create(th,  TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=Vector3.new(2,2,2)}):Play()
		TweenService:Create(te1, TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=Vector3.new(0.7,0.7,0.7)}):Play()
		TweenService:Create(te2, TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=Vector3.new(0.7,0.7,0.7)}):Play()

		table.insert(toadParts, {tb, th, te1, te2})
		task.wait(0.18)
	end

	-- 5 wolves appear behind the toads (further out)
	local wolfParts = {}
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		local r     = 16
		local wp    = hrp.Position + Vector3.new(math.cos(angle)*r, -1, math.sin(angle)*r)

		local wb = makePart({Size=Vector3.new(0.1,0.1,0.1), Position=wp,
			Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(50,50,60), Material=Enum.Material.SmoothPlastic, Parent=workspace})
		local wh = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.1,0.1,0.1),
			Position=wp+Vector3.new(0,1.6,0.8), Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(50,50,60), Material=Enum.Material.SmoothPlastic, Parent=workspace})
		-- Snout
		local wsn = makePart({Size=Vector3.new(0.1,0.1,0.1),
			Position=wh.Position+Vector3.new(0,-0.2,0.6), Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(60,55,65), Material=Enum.Material.SmoothPlastic, Parent=workspace})
		-- Eyes glow
		local we1 = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.1,0.1,0.1),
			Position=wh.Position+Vector3.new(-0.35,0.2,0.5), Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(255,200,50), Material=Enum.Material.Neon, Parent=workspace})
		local we2 = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.1,0.1,0.1),
			Position=wh.Position+Vector3.new(0.35,0.2,0.5), Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(255,200,50), Material=Enum.Material.Neon, Parent=workspace})
		local wwh = Instance.new("WeldConstraint") wwh.Part0=wb wwh.Part1=wh wwh.Parent=wb
		local wwsn = Instance.new("WeldConstraint") wwsn.Part0=wb wwsn.Part1=wsn wwsn.Parent=wb
		local wwe1 = Instance.new("WeldConstraint") wwe1.Part0=wb wwe1.Part1=we1 wwe1.Parent=wb
		local wwe2 = Instance.new("WeldConstraint") wwe2.Part0=wb wwe2.Part1=we2 wwe2.Parent=wb

		local wl = Instance.new("PointLight") wl.Color=Color3.fromRGB(255,200,50) wl.Brightness=2 wl.Range=10 wl.Parent=wb

		TweenService:Create(wb,  TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=Vector3.new(2.5,1.8,3.5)}):Play()
		TweenService:Create(wh,  TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=Vector3.new(1.5,1.5,1.8)}):Play()
		TweenService:Create(wsn, TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=Vector3.new(0.8,0.6,1.2)}):Play()
		TweenService:Create(we1, TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=Vector3.new(0.35,0.35,0.35)}):Play()
		TweenService:Create(we2, TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=Vector3.new(0.35,0.35,0.35)}):Play()

		table.insert(wolfParts, {wb, wh, wsn, we1, we2})
		task.wait(0.15)
	end

	task.wait(0.5)

	-- ========== PHASE 5: Mahoraga building animation (behind player) ==========
	local mahoPos = hrp.Position + hrp.CFrame.LookVector * (-6)
	local mahoParts = {}

	local function addMahoPart(props)
		local p = makePart(props)
		table.insert(mahoParts, p)
		return p
	end

	-- Wrapped mummified appearance: start with small parts and grow
	-- Core body (wrapped in white silk — white material)
	local mahoBody = addMahoPart({
		Size=Vector3.new(0.1,0.1,0.1),
		Position=mahoPos+Vector3.new(0,3,0),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(220,215,200), Material=Enum.Material.SmoothPlastic,
		Parent=workspace
	})
	TweenService:Create(mahoBody, TweenInfo.new(0.8,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Size=Vector3.new(2.5,4,2)}):Play()
	task.wait(0.3)

	local mahoHead = addMahoPart({
		Shape=Enum.PartType.Ball, Size=Vector3.new(0.1,0.1,0.1),
		Position=mahoPos+Vector3.new(0,6,0),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(215,210,195), Material=Enum.Material.SmoothPlastic,
		Parent=workspace
	})
	TweenService:Create(mahoHead, TweenInfo.new(0.7,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Size=Vector3.new(2.2,2.2,2.2)}):Play()
	task.wait(0.25)

	-- The eight-handled wheel on mahoraga's back (iconic wheel shape)
	local wheelCenter = addMahoPart({
		Shape=Enum.PartType.Ball, Size=Vector3.new(0.1,0.1,0.1),
		Position=mahoPos+Vector3.new(0,4,-1.5),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(200,190,170), Material=Enum.Material.SmoothPlastic,
		Parent=workspace
	})
	TweenService:Create(wheelCenter, TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Size=Vector3.new(0.8,0.8,0.8)}):Play()

	-- 8 spoke handles
	local wheelSpokes = {}
	for si=1,8 do
		local spoke = addMahoPart({
			Size=Vector3.new(0.2,0.2,0.1),
			Position=mahoPos+Vector3.new(0,4,-1.5),
			Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(180,170,150), Material=Enum.Material.SmoothPlastic,
			Parent=workspace
		})
		local spokeTargetPos = mahoPos + Vector3.new(
			math.cos((si/8)*math.pi*2)*2.5,
			4 + math.sin((si/8)*math.pi*2)*2.5,
			-1.5
		)
		TweenService:Create(spoke, TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
			{Size=Vector3.new(0.25,2.2,0.2), Position=spokeTargetPos}):Play()
		table.insert(wheelSpokes, spoke)
		task.wait(0.06)
	end

	-- Arms (wrapped)
	local armL = addMahoPart({
		Size=Vector3.new(0.1,0.1,0.1),
		Position=mahoPos+Vector3.new(-2,3.5,0),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(220,215,200), Material=Enum.Material.SmoothPlastic,
		Parent=workspace
	})
	TweenService:Create(armL, TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Size=Vector3.new(0.9,3,0.9)}):Play()

	local armR = addMahoPart({
		Size=Vector3.new(0.1,0.1,0.1),
		Position=mahoPos+Vector3.new(2,3.5,0),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(220,215,200), Material=Enum.Material.SmoothPlastic,
		Parent=workspace
	})
	TweenService:Create(armR, TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Size=Vector3.new(0.9,3,0.9)}):Play()

	-- Glow on mahoraga
	local mahoGlow = Instance.new("PointLight")
	mahoGlow.Color = Color3.fromRGB(200,210,180)
	mahoGlow.Brightness = 4
	mahoGlow.Range = 20
	mahoGlow.Parent = mahoBody

	task.wait(1.2)

	-- ========== PHASE 6: Dialogues ==========
	-- "Hey Damn bastard"
	showDialogue("\"Hey... damn bastard.\"", 5)
	task.wait(4)

	-- "I'll Be Dying First"
	showDialogue("\"I'll be dying first.\"", 3.5)
	task.wait(2)

	-- ========== PHASE 7: Mahoraga breaks free from mummified wrapping ==========
	-- White silk particle burst
	for i=1,20 do
		local silkAngle  = math.random()*math.pi*2
		local silkRadius = math.random()*3
		local silk = makePart({
			Size=Vector3.new(math.random()*0.8+0.2, math.random()*0.8+0.2, math.random()*0.2+0.05),
			Position=mahoPos+Vector3.new(
				math.cos(silkAngle)*silkRadius, math.random(2,6), math.sin(silkAngle)*silkRadius),
			Anchored=false, CanCollide=false,
			Color=Color3.fromRGB(245,245,240), Material=Enum.Material.SmoothPlastic, Transparency=0.1,
			Parent=workspace
		})
		TweenService:Create(silk, TweenInfo.new(1.2), {
			Transparency=1,
			Position=silk.Position+Vector3.new(
				math.cos(silkAngle)*math.random(4,8), math.random(3,10), math.sin(silkAngle)*math.random(4,8))
		}):Play()
		Debris:AddItem(silk, 1.3)
	end

	-- Mahoraga changes color (darker, skin revealed)
	TweenService:Create(mahoBody, TweenInfo.new(0.5), {Color=Color3.fromRGB(60,55,50)}):Play()
	TweenService:Create(mahoHead, TweenInfo.new(0.5), {Color=Color3.fromRGB(55,50,45)}):Play()
	TweenService:Create(armL,     TweenInfo.new(0.5), {Color=Color3.fromRGB(60,55,50)}):Play()
	TweenService:Create(armR,     TweenInfo.new(0.5), {Color=Color3.fromRGB(60,55,50)}):Play()
	mahoGlow.Color = Color3.fromRGB(100,180,80)  -- green aura after breaking free
	mahoGlow.Brightness = 7
	mahoGlow.Range = 25

	-- Flash screen briefly
	flashScreen(screenGui, Color3.fromRGB(255,255,255), 0.2, 0.05, 0.3)
	startShake(1.5)
	task.delay(0.5, stopShake)

	-- "Let me see your best shot."
	task.wait(0.3)
	showDialogue("\"Let me see your best shot.\"", 5)
	task.wait(1.5)

	-- ========== PHASE 8: Mahoraga slaps/kills player ==========
	-- Arm swings (armR moves to player position)
	local slap = TweenService:Create(armR, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position=hrp.Position+Vector3.new(0,2,0)})
	slap:Play()
	task.wait(0.22)

	-- Impact flash + shake
	flashScreen(screenGui, Color3.fromRGB(255,100,100), 0.05, 0.05, 0.2)
	startShake(4)
	task.delay(0.6, stopShake)

	-- Kill player (set health to 0)
	playerHum.Health = 0

	-- Remove player movement lock
	pcall(function() playerAnchor:Destroy() end)
	glowPulse = false
	pcall(function() playerGlow:Destroy() end)

	task.wait(0.5)

	-- ========== PHASE 9: Remove cinematic elements ==========
	-- Fade out night overlay
	TweenService:Create(nightOverlay, TweenInfo.new(2), {BackgroundTransparency=1}):Play()
	Debris:AddItem(nightOverlay, 2.1)

	-- Remove toads and wolves
	for _, group in ipairs(toadParts) do
		for _, p in ipairs(group) do
			TweenService:Create(p, TweenInfo.new(0.5), {Transparency=1, Size=Vector3.new(0.1,0.1,0.1)}):Play()
			Debris:AddItem(p, 0.6)
		end
	end
	for _, group in ipairs(wolfParts) do
		for _, p in ipairs(group) do
			TweenService:Create(p, TweenInfo.new(0.5), {Transparency=1, Size=Vector3.new(0.1,0.1,0.1)}):Play()
			Debris:AddItem(p, 0.6)
		end
	end

	task.wait(1)

	-- ========== PHASE 10: Unfreeze dummies, spawn Mahoraga dummy as AI =========
	for _, e in ipairs(frozenForSummon) do
		e.frozen = false
		pcall(function() e.torso.Anchored = false end)
	end
	isChanneling = false
	domainActive = false

	-- Remove mahoraga cinematic parts
	for _, mp in ipairs(mahoParts) do
		TweenService:Create(mp, TweenInfo.new(0.8), {Transparency=1}):Play()
		Debris:AddItem(mp, 0.9)
	end

	-- Spawn Mahoraga as an autonomous dummy that attacks other dummies
	local mahoModel   = Instance.new("Model") mahoModel.Name="Mahoraga" mahoModel.Parent=workspace

	local mahoTorso = makePart({
		Name="HumanoidRootPart",
		Size=Vector3.new(3.5,4.5,3),
		Position=mahoPos+Vector3.new(0,3,0),
		Anchored=false, CanCollide=true,
		Color=Color3.fromRGB(50,45,40), Material=Enum.Material.SmoothPlastic,
		Parent=mahoModel
	})
	local mahoHeadPart = makePart({
		Name="Head",
		Shape=Enum.PartType.Ball,
		Size=Vector3.new(2.8,2.8,2.8),
		Position=mahoPos+Vector3.new(0,7,0),
		Anchored=false, CanCollide=false,
		Color=Color3.fromRGB(45,40,35), Material=Enum.Material.SmoothPlastic,
		Parent=mahoModel
	})
	local mhw = Instance.new("WeldConstraint") mhw.Part0=mahoTorso mhw.Part1=mahoHeadPart mhw.Parent=mahoTorso

	-- Mahoraga's iconic wheel (decorative, on back)
	local mwCenter = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.9,0.9,0.9),
		Position=mahoPos+Vector3.new(0,4.5,-2),
		Anchored=false, CanCollide=false,
		Color=Color3.fromRGB(140,130,110), Material=Enum.Material.SmoothPlastic, Parent=mahoModel})
	local mwcw = Instance.new("WeldConstraint") mwcw.Part0=mahoTorso mwcw.Part1=mwCenter mwcw.Parent=mahoTorso
	for si=1,8 do
		local spoke = makePart({
			Size=Vector3.new(0.25,2.5,0.2),
			CFrame=CFrame.new(mahoPos+Vector3.new(
				math.cos((si/8)*math.pi*2)*2.8, 4.5+math.sin((si/8)*math.pi*2)*2.8, -2)),
			Anchored=false, CanCollide=false,
			Color=Color3.fromRGB(120,110,90), Material=Enum.Material.SmoothPlastic, Parent=mahoModel})
		local sw = Instance.new("WeldConstraint") sw.Part0=mahoTorso sw.Part1=spoke sw.Parent=mahoTorso
	end

	-- Mahoraga glows green
	local mahoGlow2 = Instance.new("PointLight") mahoGlow2.Color=Color3.fromRGB(80,200,60) mahoGlow2.Brightness=5 mahoGlow2.Range=22 mahoGlow2.Parent=mahoTorso

	-- Billboard name
	local mahoBB = Instance.new("BillboardGui")
	mahoBB.Size = UDim2.new(0,120,0,32) mahoBB.StudsOffset=Vector3.new(0,6,0) mahoBB.AlwaysOnTop=true mahoBB.Parent=mahoTorso
	local mahoLabel = Instance.new("TextLabel")
	mahoLabel.Size=UDim2.new(1,0,1,0) mahoLabel.BackgroundTransparency=1
	mahoLabel.Text="⚙ Mahoraga" mahoLabel.TextColor3=Color3.fromRGB(100,240,80)
	mahoLabel.Font=Enum.Font.GothamBold mahoLabel.TextStrokeTransparency=0 mahoLabel.TextScaled=true mahoLabel.Parent=mahoBB

	-- Humanoid (very high HP — it's Mahoraga)
	local mahoHum = Instance.new("Humanoid")
	mahoHum.MaxHealth = 9999
	mahoHum.Health    = 9999
	mahoHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	mahoHum.Parent = mahoModel

	mahoModel.PrimaryPart = mahoTorso

	-- HP bar for Mahoraga
	local mahoBgHp = Instance.new("Frame")
	mahoBgHp.Size=UDim2.new(0,130,0,12) mahoBgHp.Position=UDim2.new(0,0,0,18)
	mahoBgHp.BackgroundColor3=Color3.fromRGB(30,30,30) mahoBgHp.BorderSizePixel=0 mahoBgHp.Parent=mahoBB
	addCorner(mahoBgHp,4)
	local mahoFillHp = Instance.new("Frame")
	mahoFillHp.Size=UDim2.new(1,0,1,0)
	mahoFillHp.BackgroundColor3=Color3.fromRGB(80,220,80) mahoFillHp.BorderSizePixel=0 mahoFillHp.Parent=mahoBgHp
	addCorner(mahoFillHp,4)

	-- Register Mahoraga as a special AI entry (attacks dummies, not player)
	local mahoEntry = {
		grade      = "Mahoraga",
		model      = mahoModel,
		humanoid   = mahoHum,
		torso      = mahoTorso,
		hpFill     = mahoFillHp,
		hpNum      = mahoLabel,
		attackTimer= 0,
		frozen     = false,
		isMahoraga = true,
		gradeData  = {dmg=40, attackRate=1.5, aggroRange=60, speed=22, name="Mahoraga"},
	}
	-- Mahoraga AI runs in a separate loop (attacks dummies, not player)
	local mahoConn
	mahoConn = RunService.Heartbeat:Connect(function(dt)
		if not mahoTorso.Parent or mahoHum.Health <= 0 then
			mahoConn:Disconnect() return
		end
		-- Find nearest enemy dummy
		local nearestEnemy, nearestDist = nil, math.huge
		for _, e in ipairs(spawnedDummies) do
			if e.humanoid.Health > 0 then
				local d = (mahoTorso.Position - e.torso.Position).Magnitude
				if d < nearestDist then nearestDist=d nearestEnemy=e end
			end
		end
		if nearestEnemy then
			-- Move toward enemy
			local moveDir = (nearestEnemy.torso.Position - mahoTorso.Position)
			if moveDir.Magnitude > 4 then
				moveDir = moveDir.Unit
				local bv=Instance.new("BodyVelocity") bv.Velocity=moveDir*22 bv.MaxForce=Vector3.new(1e5,0,1e5) bv.P=3000 bv.Parent=mahoTorso
				Debris:AddItem(bv, dt+0.03)
			end
			-- Attack
			mahoEntry.attackTimer = mahoEntry.attackTimer + dt
			if mahoEntry.attackTimer >= 1.5 and nearestDist <= 6 then
				mahoEntry.attackTimer = 0
				nearestEnemy.humanoid:TakeDamage(40)
				-- Slam impact
				local imp=makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1,1,1),
					Position=nearestEnemy.torso.Position, Anchored=true, CanCollide=false,
					Color=Color3.fromRGB(80,220,60), Material=Enum.Material.Neon, Transparency=0.2, Parent=workspace})
				TweenService:Create(imp, TweenInfo.new(0.3), {Size=Vector3.new(7,7,7), Transparency=1}):Play()
				Debris:AddItem(imp, 0.31)
				-- Knockback
				local kDir=(nearestEnemy.torso.Position-mahoTorso.Position).Unit
				local bv2=Instance.new("BodyVelocity") bv2.Velocity=kDir*50+Vector3.new(0,20,0) bv2.MaxForce=Vector3.new(1e5,1e5,1e5) bv2.P=1e5 bv2.Parent=nearestEnemy.torso
				Debris:AddItem(bv2, 0.25)
			end
		end
		-- Update HP bar
		local pct2 = mahoHum.Health / mahoHum.MaxHealth
		mahoFillHp.Size = UDim2.new(math.max(0,pct2),0,1,0)
		mahoFillHp.BackgroundColor3 = hpColor(pct2)
	end)
end

-- ============================================================
-- MEGUMI: CHIMERA SHADOW GARDEN
-- ============================================================
function fireMegumi_ChimeraShadowGarden()
	if isCooldown("ChimeraShadowGarden") or isChanneling or domainActive then return end
	startCD("ChimeraShadowGarden", 120)
	isChanneling = true
	domainActive = true

	local domainCenter = hrp.Position

	-- Same domain sphere build as other domains (dark green tint)
	buildDomainVisuals(Color3.fromRGB(5,30,10))

	task.delay(3, function()
		flashScreen(screenGui, Color3.fromRGB(10,200,50), 0.5, 0.1, 0.7)
	end)

	task.delay(3.6, function()
		startShake(1.5)
		expandFOV(90, 1.5)
		isChanneling = false

		-- ── Black liquid flood: rising dark floor ──
		local liquidFloor = makePart({
			Size=Vector3.new(90,0.5,90),
			Position=domainCenter+Vector3.new(0,-3,0),
			Anchored=true, CanCollide=true,
			Color=Color3.fromRGB(5,5,10), Material=Enum.Material.Neon,
			Transparency=0.3, Parent=workspace
		})
		-- Rise from below
		TweenService:Create(liquidFloor, TweenInfo.new(2), {Position=domainCenter+Vector3.new(0,-1.5,0)}):Play()

		-- Liquid ripple shimmer
		local shimmerConn = RunService.Heartbeat:Connect(function()
			if not liquidFloor.Parent then return end
			liquidFloor.Transparency = 0.25 + math.sin(tick()*3)*0.08
		end)

		-- Slow all dummies in domain
		local frozenInDomain = {}
		for _, e in ipairs(spawnedDummies) do
			if e.humanoid.Health>0 and (e.torso.Position-domainCenter).Magnitude<=45 then
				e.frozen = true
				e.torso.Anchored = true
				table.insert(frozenInDomain, e)
			end
		end

		-- ── 300 black liquid bunnies ──
		local bunnyParts = {}
		for i=1,300 do
			local bAngle = math.random()*math.pi*2
			local bR     = math.random()*42
			local bPos   = domainCenter+Vector3.new(math.cos(bAngle)*bR, -1.2, math.sin(bAngle)*bR)
			local bSize  = math.random()*0.4+0.35

			local bb = makePart({Shape=Enum.PartType.Ball,
				Size=Vector3.new(bSize, bSize*1.1, bSize),
				Position=bPos, Anchored=false, CanCollide=false,
				Color=Color3.fromRGB(8,8,12), Material=Enum.Material.Neon,
				Transparency=0.1, Parent=workspace})
			local bh = makePart({Shape=Enum.PartType.Ball,
				Size=Vector3.new(bSize*0.7, bSize*0.7, bSize*0.7),
				Position=bPos+Vector3.new(0,bSize*0.9,0), Anchored=false, CanCollide=false,
				Color=Color3.fromRGB(8,8,12), Material=Enum.Material.Neon,
				Transparency=0.1, Parent=workspace})
			local be1 = makePart({Size=Vector3.new(bSize*0.12,bSize*0.5,bSize*0.08),
				Position=bh.Position+Vector3.new(-bSize*0.18,bSize*0.45,0),
				Anchored=false, CanCollide=false,
				Color=Color3.fromRGB(8,8,12), Material=Enum.Material.Neon,
				Transparency=0.1, Parent=workspace})
			local be2 = makePart({Size=Vector3.new(bSize*0.12,bSize*0.5,bSize*0.08),
				Position=bh.Position+Vector3.new(bSize*0.18,bSize*0.45,0),
				Anchored=false, CanCollide=false,
				Color=Color3.fromRGB(8,8,12), Material=Enum.Material.Neon,
				Transparency=0.1, Parent=workspace})
			local bw1=Instance.new("WeldConstraint") bw1.Part0=bb bw1.Part1=bh bw1.Parent=bb
			local bw2=Instance.new("WeldConstraint") bw2.Part0=bb bw2.Part1=be1 bw2.Parent=bb
			local bw3=Instance.new("WeldConstraint") bw3.Part0=bb bw3.Part1=be2 bw3.Parent=bb

			-- Give each bunny a random patrol velocity
			local bvDir = Vector3.new((math.random()-0.5)*2, 0, (math.random()-0.5)*2).Unit
			local bBV = Instance.new("BodyVelocity")
			bBV.Velocity = bvDir * (math.random()*4+3)
			bBV.MaxForce = Vector3.new(1e4,0,1e4) bBV.P=800 bBV.Parent=bb

			table.insert(bunnyParts, bb)
		end

		-- Bunny damage loop — every 0.1s check proximity to dummies
		local bunnyDmgAccum = 0
		local toadSpawnAccum = 0
		local elapsedDomain  = 0
		local DOMAIN_DUR     = 15
		local spawnedLiquidToads = {}

		local csgConn = RunService.Heartbeat:Connect(function(dt)
			if not domainActive then return end
			elapsedDomain = elapsedDomain + dt
			bunnyDmgAccum = bunnyDmgAccum + dt
			toadSpawnAccum = toadSpawnAccum + dt

			-- Bunny contact damage every 0.1s
			if bunnyDmgAccum >= 0.1 then
				bunnyDmgAccum = 0
				for _, bn in ipairs(bunnyParts) do
					if not bn.Parent then continue end
					for _, e in ipairs(spawnedDummies) do
						if e.humanoid.Health>0 and (bn.Position-e.torso.Position).Magnitude<2.5 then
							e.humanoid:TakeDamage(5)
							-- Push dummy away from bunny
							local pushDir=(e.torso.Position-bn.Position)
							pushDir=Vector3.new(pushDir.X,0,pushDir.Z)
							if pushDir.Magnitude>0.01 then
								local pbv=Instance.new("BodyVelocity") pbv.Velocity=pushDir.Unit*18 pbv.MaxForce=Vector3.new(1e4,0,1e4) pbv.P=3000 pbv.Parent=e.torso
								Debris:AddItem(pbv, 0.1)
							end
						end
					end
				end

				-- Also trap any new dummies that walked in
				for _, e in ipairs(spawnedDummies) do
					if e.humanoid.Health>0 and not e.frozen and (e.torso.Position-domainCenter).Magnitude<=45 then
						e.frozen=true e.torso.Anchored=true
						table.insert(frozenInDomain, e)
					end
				end
			end

			-- Spawn liquid toad every 0.5s
			if toadSpawnAccum >= 0.5 then
				toadSpawnAccum = 0
				local tAngle = math.random()*math.pi*2
				local tR     = math.random()*35
				local tPos   = domainCenter+Vector3.new(math.cos(tAngle)*tR, -1, math.sin(tAngle)*tR)

				local ltBody = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.1,0.1,0.1),
					Position=tPos, Anchored=true, CanCollide=false,
					Color=Color3.fromRGB(10,10,15), Material=Enum.Material.Neon, Transparency=0.1, Parent=workspace})
				TweenService:Create(ltBody, TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
					{Size=Vector3.new(2,1.5,2)}):Play()
				local ltLight=Instance.new("PointLight") ltLight.Color=Color3.fromRGB(30,200,60) ltLight.Brightness=2 ltLight.Range=8 ltLight.Parent=ltBody
				table.insert(spawnedLiquidToads, ltBody)

				-- Toad grabs nearest dummy with tongue
				task.delay(0.4, function()
					if not ltBody.Parent then return end
					local nearestE, nearestD = nil, math.huge
					for _, e in ipairs(spawnedDummies) do
						if e.humanoid.Health>0 then
							local d=(ltBody.Position-e.torso.Position).Magnitude
							if d<nearestD then nearestD=d nearestE=e end
						end
					end
					if nearestE and nearestD<20 then
						nearestE.humanoid:TakeDamage(10)
						local tDir=(ltBody.Position-nearestE.torso.Position).Unit
						local tbv=Instance.new("BodyVelocity") tbv.Velocity=tDir*15 tbv.MaxForce=Vector3.new(1e5,0,1e5) tbv.P=5000 tbv.Parent=nearestE.torso
						Debris:AddItem(tbv, 0.4)
						-- Tongue visual
						local tongLen=(nearestE.torso.Position-ltBody.Position).Magnitude
						local tong=makePart({Size=Vector3.new(0.18,0.18,tongLen),
							CFrame=CFrame.new(ltBody.Position, nearestE.torso.Position)*CFrame.new(0,0,-tongLen/2),
							Anchored=true, CanCollide=false,
							Color=Color3.fromRGB(30,180,30), Material=Enum.Material.Neon, Transparency=0.2, Parent=workspace})
						TweenService:Create(tong, TweenInfo.new(0.3), {Transparency=1, Size=Vector3.new(0.05,0.05,tongLen)}):Play()
						Debris:AddItem(tong, 0.31)
					end
					-- Toad vanishes after grabbing
					TweenService:Create(ltBody, TweenInfo.new(0.4), {Transparency=1, Size=Vector3.new(0.1,0.1,0.1)}):Play()
					Debris:AddItem(ltBody, 0.41)
				end)
			end
		end)

		-- ── After 15s: domain melts away ──
		task.delay(DOMAIN_DUR, function()
			csgConn:Disconnect()
			shimmerConn:Disconnect()

			-- Melt animation: liquid floor sinks back down
			TweenService:Create(liquidFloor, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position=domainCenter+Vector3.new(0,-8,0), Transparency=1}):Play()
			Debris:AddItem(liquidFloor, 2.1)

			-- Bunnies dissolve into black wisps
			for _, bn in ipairs(bunnyParts) do
				if bn and bn.Parent then
					TweenService:Create(bn, TweenInfo.new(math.random()*0.8+0.4), {Transparency=1, Size=Vector3.new(0.05,0.05,0.05)}):Play()
					Debris:AddItem(bn, 1.3)
				end
			end

			-- Clean up remaining liquid toads
			for _, lt in ipairs(spawnedLiquidToads) do
				pcall(function()
					if lt.Parent then
						TweenService:Create(lt, TweenInfo.new(0.3), {Transparency=1}):Play()
						Debris:AddItem(lt, 0.4)
					end
				end)
			end

			-- Dark green mist drip-away particles
			for i=1,18 do
				local mPos=domainCenter+Vector3.new(math.random(-20,20),math.random(0,8),math.random(-20,20))
				local mist=makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(2,2,2),
					Position=mPos, Anchored=true, CanCollide=false,
					Color=Color3.fromRGB(10,40,15), Material=Enum.Material.Neon, Transparency=0.4, Parent=workspace})
				TweenService:Create(mist, TweenInfo.new(1.5),
					{Position=mPos+Vector3.new(0,-6,0), Transparency=1, Size=Vector3.new(0.2,0.2,0.2)}):Play()
				Debris:AddItem(mist, 1.6)
			end

			flashScreen(screenGui, Color3.fromRGB(0,0,0), 0.3, 0.15, 0.7)

			task.delay(0.5, function()
				for _, e in ipairs(frozenInDomain) do
					e.frozen=false; pcall(function() e.torso.Anchored=false end)
				end
				stopShake()
				expandFOV(DEFAULT_FOV, 1.5)
				destroyDomainVisuals()
				domainActive=false
			end)
		end)
	end)
end

-- ============================================================
-- MAHORAGA ABILITIES
-- ============================================================

-- Track adaptation damage taken
local function onMahoragaDamaged()
	adaptationPct = math.min(100, adaptationPct + 5)
	if adaptationPct >= 100 then
		adaptationReady = true
		adaptFill.BackgroundColor3 = Color3.fromRGB(50,255,80)
	end
	adaptLabel.Text = "Adaptation: "..math.floor(adaptationPct).."%"..(adaptationReady and " ✓ READY" or "")
	adaptFill.Size = UDim2.new(adaptationPct/100, 0, 1, 0)
end

-- ---- SWORD OF EXTERMINATION (M1) ----
function fireMahoraga_Sword()
	if isChanneling then return end
	-- No cooldown for basic attack but no spam guard needed beyond animation
	if allCooldowns["SwordOfExtermination"] > 0 then return end
	allCooldowns["SwordOfExtermination"] = 0.6  -- short animation lock

	local target = getNearestDummy()
	if not target then return end

	-- Sword slash visual: a bright golden arc
	local swingOrigin = hrp.Position + Vector3.new(0,1.5,0)
	local dir = (target.torso.Position - swingOrigin).Unit

	-- Sword blade (long thin neon part)
	local blade = makePart({
		Size=Vector3.new(0.15, 0.15, 5),
		CFrame=CFrame.new(swingOrigin, swingOrigin+dir)*CFrame.new(0,0,-2.5),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(255,240,120), Material=Enum.Material.Neon,
		Transparency=0.0, Parent=workspace
	})
	local sbl=Instance.new("PointLight") sbl.Color=Color3.fromRGB(255,230,80) sbl.Brightness=5 sbl.Range=12 sbl.Parent=blade

	-- Slash arc particles
	for ai=1,5 do
		local arcAngle = (ai/5-0.5)*0.8
		local arcDir = CFrame.Angles(0,arcAngle,0) * dir
		local arc=makePart({Size=Vector3.new(0.08,0.08,4),
			CFrame=CFrame.new(swingOrigin, swingOrigin+arcDir.Position)*CFrame.new(0,0,-2),
			Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(255,255,180), Material=Enum.Material.Neon, Transparency=0.3, Parent=workspace})
		TweenService:Create(arc, TweenInfo.new(0.15), {Transparency=1, Size=Vector3.new(0.04,0.04,5)}):Play()
		Debris:AddItem(arc, 0.16)
	end

	-- Hit detection (within 7 studs along blade)
	for _, e in ipairs(spawnedDummies) do
		if e.humanoid.Health>0 then
			local toE = e.torso.Position - swingOrigin
			local proj = toE:Dot(dir)
			local perp = (toE - dir*proj).Magnitude
			if proj>0 and proj<6 and perp<2.5 then
				e.humanoid:TakeDamage(15)
				local imp=makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.8,0.8,0.8),
					Position=e.torso.Position, Anchored=true, CanCollide=false,
					Color=Color3.fromRGB(255,240,80), Material=Enum.Material.Neon, Transparency=0.2, Parent=workspace})
				TweenService:Create(imp, TweenInfo.new(0.2), {Size=Vector3.new(4,4,4), Transparency=1}):Play()
				Debris:AddItem(imp, 0.21)
			end
		end
	end

	TweenService:Create(blade, TweenInfo.new(0.15), {Transparency=1}):Play()
	Debris:AddItem(blade, 0.2)
end

-- ---- ADAPTATION ----
function fireMahoraga_Adaptation()
	if isCooldown("Adaptation") then return end
	if not adaptationReady then return end  -- need 100% bar
	startCD("Adaptation", 50)
	adaptationReady = false
	adaptationPct   = 0
	adaptFill.BackgroundColor3 = Color3.fromRGB(80,220,80)
	adaptLabel.Text = "Adaptation: 0%"
	adaptFill.Size = UDim2.new(0,0,1,0)

	-- Heal Mahoraga (find mahoragaRef or find the model by name)
	local mahoModel = workspace:FindFirstChild("Mahoraga")
	if mahoModel then
		local mHum = mahoModel:FindFirstChildOfClass("Humanoid")
		if mHum then mHum.Health = mHum.MaxHealth end
	end
	-- Also heal the player character if in Mahoraga mode
	playerHum.Health = playerHum.MaxHealth

	-- Wheel spin visual around player
	local wheelCenter2 = hrp.Position + Vector3.new(0,3,0)
	for si=1,8 do
		local sAngle = (si/8)*math.pi*2
		local sPos = wheelCenter2 + Vector3.new(math.cos(sAngle)*3, math.sin(sAngle)*3, 0)
		local spoke2=makePart({Size=Vector3.new(0.3,2,0.2),
			Position=sPos, Anchored=true, CanCollide=false,
			Color=Color3.fromRGB(150,220,100), Material=Enum.Material.Neon, Transparency=0.2, Parent=workspace})
		local tStart=sAngle
		TweenService:Create(spoke2, TweenInfo.new(1.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
			{Size=Vector3.new(0.1,0.1,0.1), Transparency=1,
			 Position=wheelCenter2+Vector3.new(math.cos(tStart+math.pi)*5, math.sin(tStart+math.pi)*5, 0)}):Play()
		Debris:AddItem(spoke2, 1.6)
	end

	-- Green heal flash
	flashScreen(screenGui, Color3.fromRGB(60,255,100), 0.2, 0.1, 0.5)
	local healGlow=makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1,1,1),
		Position=hrp.Position, Anchored=false, CanCollide=false,
		Color=Color3.fromRGB(60,255,100), Material=Enum.Material.Neon, Transparency=0.2, Parent=workspace})
	local hgw=Instance.new("WeldConstraint") hgw.Part0=hrp hgw.Part1=healGlow hgw.Parent=hrp
	TweenService:Create(healGlow, TweenInfo.new(1), {Size=Vector3.new(8,8,8), Transparency=1}):Play()
	Debris:AddItem(healGlow, 1.1)
end

-- ---- DIVINE CRASH ----
function fireMahoraga_DivineCrash()
	if isCooldown("DivineCrash") or isChanneling then return end
	startCD("DivineCrash", 15)
	isChanneling = true

	local crashPos = getMouseWorldPos()
	crashPos = Vector3.new(crashPos.X, hrp.Position.Y - 1.5, crashPos.Z)

	-- Yellow shining palm glow on hand (on player)
	local palmGlow = makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(1.5,1.5,1.5),
		Position=hrp.Position+Vector3.new(1.5,0,0),
		Anchored=false, CanCollide=false,
		Color=Color3.fromRGB(255,230,50), Material=Enum.Material.Neon, Transparency=0.1, Parent=workspace})
	local palmWeld=Instance.new("BodyPosition") palmWeld.Position=hrp.Position+Vector3.new(1.5,0,0) palmWeld.MaxForce=Vector3.new(0,0,0) palmWeld.Parent=palmGlow
	local palmLight=Instance.new("PointLight") palmLight.Color=Color3.fromRGB(255,220,30) palmLight.Brightness=8 palmLight.Range=18 palmLight.Parent=palmGlow

	-- Charge particles swirl around palm
	task.spawn(function()
		for pi=1,12 do
			if not palmGlow.Parent then break end
			local pAngle=(pi/12)*math.pi*2
			local charge=makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(0.3,0.3,0.3),
				Position=palmGlow.Position+Vector3.new(math.cos(pAngle)*2, math.sin(pAngle)*2, 0),
				Anchored=true, CanCollide=false,
				Color=Color3.fromRGB(255,220,50), Material=Enum.Material.Neon, Transparency=0.2, Parent=workspace})
			TweenService:Create(charge, TweenInfo.new(0.5), {Position=palmGlow.Position, Transparency=1, Size=Vector3.new(0.05,0.05,0.05)}):Play()
			Debris:AddItem(charge, 0.55)
			task.wait(0.04)
		end
	end)

	task.wait(0.7)  -- charge time

	-- Slam down: palm glow shoots to crashPos
	TweenService:Create(palmGlow, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position=crashPos+Vector3.new(0,1,0)}):Play()
	task.wait(0.17)
	palmGlow:Destroy()

	-- IMPACT
	startShake(3)
	task.delay(0.6, stopShake)

	-- Shockwave ring on ground
	local shockRing=makePart({Shape=Enum.PartType.Cylinder,
		Size=Vector3.new(0.6,2,2),
		CFrame=CFrame.new(crashPos)*CFrame.Angles(0,0,math.pi/2),
		Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(255,220,50), Material=Enum.Material.Neon, Transparency=0.2, Parent=workspace})
	TweenService:Create(shockRing, TweenInfo.new(0.5), {Size=Vector3.new(0.6,30,30), Transparency=1}):Play()
	Debris:AddItem(shockRing, 0.51)

	-- Impact glow burst
	local burst=makePart({Shape=Enum.PartType.Ball, Size=Vector3.new(2,2,2),
		Position=crashPos, Anchored=true, CanCollide=false,
		Color=Color3.fromRGB(255,230,60), Material=Enum.Material.Neon, Transparency=0.1, Parent=workspace})
	TweenService:Create(burst, TweenInfo.new(0.4), {Size=Vector3.new(16,16,16), Transparency=1}):Play()
	Debris:AddItem(burst, 0.41)

	-- Debris: broken ground chunks fly out
	for i=1,18 do
		local dAngle=math.random()*math.pi*2
		local dDist=math.random(2,12)
		local debris=makePart({
			Size=Vector3.new(math.random(1,3),math.random(1,3),math.random(1,2)),
			Position=crashPos+Vector3.new(math.cos(dAngle)*dDist, 1, math.sin(dAngle)*dDist),
			Anchored=false, CanCollide=true,
			Color=Color3.fromRGB(math.random(60,100),math.random(50,80),math.random(40,60)),
			Material=Enum.Material.SmoothPlastic, Parent=workspace
		})
		local dbv=Instance.new("BodyVelocity")
		dbv.Velocity=Vector3.new(math.cos(dAngle)*16, math.random(12,22), math.sin(dAngle)*16)
		dbv.MaxForce=Vector3.new(1e4,1e4,1e4) dbv.P=3000 dbv.Parent=debris
		Debris:AddItem(dbv, 0.4)
		Debris:AddItem(debris, 5)
	end

	-- AOE damage + fling (25 dmg, 20 stud radius)
	for _, e in ipairs(spawnedDummies) do
		if e.humanoid.Health>0 and (e.torso.Position-crashPos).Magnitude<=20 then
			e.humanoid:TakeDamage(25)
			local fDir=(e.torso.Position-crashPos)
			fDir=Vector3.new(fDir.X,0,fDir.Z)
			if fDir.Magnitude<0.1 then fDir=Vector3.new(1,0,0) end
			fDir=fDir.Unit
			local fBV=Instance.new("BodyVelocity") fBV.Velocity=fDir*55+Vector3.new(0,30,0) fBV.MaxForce=Vector3.new(1e5,1e5,1e5) fBV.P=1e5 fBV.Parent=e.torso
			Debris:AddItem(fBV, 0.3)
		end
	end

	isChanneling = false
end

-- ---- CRUSHING GRAB (Coming Soon) ----
function fireMahoraga_CrushingGrab()
	local notice=Instance.new("TextLabel")
	notice.Size=UDim2.new(0,220,0,40) notice.Position=UDim2.new(0.5,-110,0.4,0)
	notice.BackgroundColor3=Color3.fromRGB(30,20,10) notice.BackgroundTransparency=0.15
	notice.BorderSizePixel=0 notice.Text="Crushing Grab — Coming Soon"
	notice.TextColor3=Color3.fromRGB(220,180,100) notice.Font=Enum.Font.GothamBold notice.TextSize=13
	notice.Parent=screenGui addCorner(notice,8)
	TweenService:Create(notice, TweenInfo.new(2.2), {TextTransparency=1, BackgroundTransparency=1}):Play()
	Debris:AddItem(notice, 2.3)
end

-- ============================================================
-- SORCERER PANEL + SWITCHING
-- ============================================================
local SORCERERS = {"Gojo","Sukuna","Nobara","Megumi","Mahoraga","Itadori (Soon)","Nanami (Soon)"}
for _, sName in ipairs(SORCERERS) do
	local isSoon = sName:find("Soon")
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.9,0,0,26)
	b.BackgroundColor3 = (not isSoon) and Color3.fromRGB(90,40,160) or Color3.fromRGB(50,50,50)
	b.BorderSizePixel = 0
	b.Text = sName
	b.TextColor3 = Color3.fromRGB(255,255,255)
	b.Font = Enum.Font.Gotham
	b.TextSize = 12
	b.ZIndex = 11
	b.Parent = sorcererPanel
	addCorner(b, 6)
	b.MouseButton1Click:Connect(function()
		if isSoon then return end
		currentSorcerer = sName
		sorcererBtn.Text = "👤 Sorcerer: "..sName
		sorcererPanel.Visible = false
		rebuildAbilityBar(sName)
	end)
end
sorcererBtn.MouseButton1Click:Connect(function()
	sorcererPanel.Visible = not sorcererPanel.Visible
end)

-- ============================================================
-- AGGRO AI
-- ============================================================
local function runAggroAI(entry, dt)
	if entry.frozen or entry.humanoid.Health<=0 then return end
	local gd   = entry.gradeData
	local dist = (entry.torso.Position-hrp.Position).Magnitude

	if dist<=gd.aggroRange then
		local moveDir=(hrp.Position-entry.torso.Position)
		if moveDir.Magnitude>3.5 then
			moveDir=moveDir.Unit
			local bv=Instance.new("BodyVelocity")
			bv.Velocity=moveDir*gd.speed
			bv.MaxForce=Vector3.new(1e5,0,1e5) bv.P=2000 bv.Parent=entry.torso
			Debris:AddItem(bv, dt+0.03)
		end
		entry.attackTimer=(entry.attackTimer or 0)+dt
		if entry.attackTimer>=gd.attackRate and dist<=5.5 then
			entry.attackTimer=0
			playerHum:TakeDamage(gd.dmg)
			playerHpFill.BackgroundColor3=Color3.fromRGB(255,70,70)
			task.delay(0.25, function()
				playerHpFill.BackgroundColor3=hpColor(playerHum.Health/playerHum.MaxHealth)
			end)
		elseif dist>5.5 then
			entry.attackTimer=0
		end
	end
end

-- ============================================================
-- BURN TICK (runs in main loop)
-- ============================================================
local burnTickAccum = 0
local function processBurns(dt)
	burnTickAccum = burnTickAccum + dt
	if burnTickAccum >= 1 then
		burnTickAccum = 0
		local stillBurning = {}
		for entry, remaining in pairs(burnTimers) do
			if entry.humanoid and entry.humanoid.Health > 0 then
				entry.humanoid:TakeDamage(5)
				-- Orange tint flash to show burn
				if entry.torso and entry.torso.Parent then
					local oldColor = entry.torso.Color
					entry.torso.Color = Color3.fromRGB(255,120,0)
					task.delay(0.15, function()
						if entry.torso and entry.torso.Parent then
							entry.torso.Color = oldColor
						end
					end)
				end
				local newRemaining = remaining - 1
				if newRemaining > 0 then
					stillBurning[entry] = newRemaining
				end
			end
		end
		burnTimers = stillBurning
	end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
	cleanDeadDummies()

	-- Spawn
	for _, g in ipairs(GRADES) do
		gradeTimers[g.name]=gradeTimers[g.name]+dt
		if gradeTimers[g.name]>=g.spawnInterval then
			gradeTimers[g.name]=0
			if countGrade(g.name)<g.maxCount then spawnDummy(g) end
		end
	end

	-- AI + HP bars
	for _, e in ipairs(spawnedDummies) do
		runAggroAI(e, dt)
		local pct=e.humanoid.Health/e.humanoid.MaxHealth
		e.hpFill.Size=UDim2.new(math.max(0,pct),0,1,0)
		e.hpFill.BackgroundColor3=hpColor(pct)
		e.hpNum.Text=math.floor(e.humanoid.Health).."/"..e.humanoid.MaxHealth
	end

	processBurns(dt)
	checkDollPickup(dt)
	cleanDolls()

	-- Player HP
	do
		local pct=playerHum.Health/playerHum.MaxHealth
		playerHpFill.Size=UDim2.new(math.max(0,pct),0,1,0)
		playerHpFill.BackgroundColor3=hpColor(pct)
		playerHpLabel.Text="YOU  "..math.floor(playerHum.Health).."/"..playerHum.MaxHealth
	end

	-- Cooldown UI
	for _, ad in ipairs(currentAbilDefs) do
		local k    = ad.key
		local info = abilityButtons[k]
		if not info then continue end
		local cdVal = allCooldowns[k] or 0
		if cdVal > 0 then
			allCooldowns[k] = math.max(0, cdVal-dt)
			local pct = allCooldowns[k] / ad.cd
			info.overlay.BackgroundTransparency = 0.35+(1-pct)*0.55
			info.btn.Text = info.label.."\n["..math.ceil(allCooldowns[k]).."s]"
		else
			info.overlay.BackgroundTransparency = 1
			info.btn.Text = info.label.."\n["..ad.cd.."s]"
		end
	end

	-- Counter
	for _, g in ipairs(GRADES) do
		counterLabels[g.name].Text=g.name..": "..countGrade(g.name).."/"..g.maxCount
	end

	-- Resonance status badge (only shown when Nobara is active)
	if currentSorcerer == "Nobara" then
		resonanceBadge.Visible = true
		if resonanceActive then
			resonanceBadge.Text = "🔵 Resonance READY"
			resonanceBadge.TextColor3 = Color3.fromRGB(100,220,255)
			resonanceBadge.BackgroundColor3 = Color3.fromRGB(10,40,120)
		elseif resonanceDoll and resonanceDoll.Parent then
			resonanceBadge.Text = "🔵 Pick Up Doll!"
			resonanceBadge.TextColor3 = Color3.fromRGB(180,220,255)
			resonanceBadge.BackgroundColor3 = Color3.fromRGB(10,30,80)
		else
			resonanceBadge.Text = "○ No Resonance"
			resonanceBadge.TextColor3 = Color3.fromRGB(120,120,140)
			resonanceBadge.BackgroundColor3 = Color3.fromRGB(20,20,30)
		end
	else
		resonanceBadge.Visible = false
	end

	-- Adaptation HUD (only shown when Mahoraga is active sorcerer)
	adaptFrame.Visible = (currentSorcerer == "Mahoraga")
end)

-- ============================================================
-- MAHORAGA DAMAGE TRACKING
-- Hook into player damage events for Adaptation bar.
-- Since we can't intercept enemy hits directly in LocalScript,
-- we watch the player's Health each frame and attribute drops.
-- ============================================================
local lastPlayerHealth = playerHum.Health
playerHum.HealthChanged:Connect(function(newHealth)
	if currentSorcerer == "Mahoraga" and newHealth < lastPlayerHealth then
		onMahoragaDamaged()
	end
	lastPlayerHealth = newHealth
end)

-- Build initial ability bar for Gojo
rebuildAbilityBar("Gojo")

print("[JJK] Loaded | Sorcerer: Gojo")
