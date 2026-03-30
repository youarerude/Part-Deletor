-- ============================================================
--  GRACE : MAZE  –  Fanmade
--  LocalScript → StarterPlayerScripts
--  Credits: Devious Goober + Vortex & Skip Saferoom by Grok
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local CELL_SIZE  = 8
local WALL_H     = 12
local ESP_PCT    = 0.10
local MAZE_ORIGIN = Vector3.new(200, 0, 0)
local SAFE_ORIGIN = Vector3.new(0,   0, 0)
local SAFE_W, SAFE_D = 40, 44

local ROUND_TABLE = {
	{21,21,100},{31,31,275},{39,39,490},{49,49,750},{61,61,900},
}

local function getRound(r)
	if r <= #ROUND_TABLE then 
		return ROUND_TABLE[r][1], ROUND_TABLE[r][2], ROUND_TABLE[r][3] 
	end
	local ex = r - #ROUND_TABLE
	local w = 61 + ex * 8
	local h = 61 + ex * 8
	if w % 2 == 0 then w += 1 end
	if h % 2 == 0 then h += 1 end
	return w, h, 900 + ex * 200
end

local C = {
	wall = Color3.fromRGB(22,22,40),
	floor = Color3.fromRGB(14,14,28),
	shard = Color3.fromRGB(110,205,255),
	shardESP = Color3.fromRGB(80,180,255),
	beam = Color3.fromRGB(255,110,35),
	safe = Color3.fromRGB(30,50,30),
	safeFlr = Color3.fromRGB(40,65,40),
	door = Color3.fromRGB(45,210,95),
	white = Color3.new(1,1,1),
	gold = Color3.fromRGB(255,215,60),
	dasher = Color3.fromRGB(255,55,55),
	dasherPath = Color3.fromRGB(85,165,255),
	pinpoint = Color3.fromRGB(230,60,230),
	pinLine = Color3.fromRGB(255,100,255),
	parry = Color3.fromRGB(255,215,0),
	vortex = Color3.fromRGB(80, 220, 200),
	vortexCore = Color3.fromRGB(180, 100, 255),
	vortexTrail = Color3.fromRGB(120, 180, 255),
	skip = Color3.fromRGB(0, 255, 200),
}

local gameActive = false
local currentRound = 1
local mazeFolder = nil
local shardList = {}
local collected = 0
local totalShards = 0
local espActive = false
local exitCellPos = Vector3.new(0,0,0)
local animConns = {}
local currentGrid = nil
local gridW, gridH = 0, 0
local safeSpawnPos = SAFE_ORIGIN + Vector3.new(SAFE_W/2, 1.5, SAFE_D/2)
local doorPart = nil

local dasherPart = nil
local dasherActive = false
local dasherLoop = nil
local dasherConn = nil

local pinpointPart = nil
local pinpointSpawned = false
local pinpointChasing = false
local pinpointLoop = nil
local pinpointHBConn = nil

local isParrying = false

-- Vortex Variables
local vortexActive = false
local vortexPart = nil
local vortexLoop = nil

-- Skip Saferoom
local skipPlate = nil

local function getHRP()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

local function cleanAnimConns()
	for _, c in ipairs(animConns) do
		pcall(function() c:Disconnect() end)
	end
	animConns = {}
end

local function makePart(name, sz, pos, color, mat, trans, collide, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = sz
	p.CFrame = CFrame.new(pos)
	p.Anchored = true
	p.CanCollide = collide \~= false
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Color = color
	p.Transparency = trans or 0
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function cellToWorld(cx, cy)
	return MAZE_ORIGIN + Vector3.new((cx - 0.5) * CELL_SIZE, 0, (cy - 0.5) * CELL_SIZE)
end

local function setESP(part, lc, fc, ft)
	local s = part:FindFirstChildOfClass("SelectionBox")
	if not s then 
		s = Instance.new("SelectionBox")
		s.Parent = part 
	end
	s.Adornee = part
	s.Color3 = lc
	s.LineThickness = 0.08
	s.SurfaceColor3 = fc or lc
	s.SurfaceTransparency = ft or 0.55
end

-- HUD
local sg = Instance.new("ScreenGui")
sg.Name = "GraceMazeHUD"
sg.ResetOnSpawn = false
sg.Parent = player.PlayerGui

local hf = Instance.new("Frame")
hf.Size = UDim2.new(0, 275, 0, 145)
hf.Position = UDim2.new(0, 14, 0, 14)
hf.BackgroundColor3 = Color3.fromRGB(5,5,14)
hf.BackgroundTransparency = 0.18
hf.BorderSizePixel = 0
hf.Parent = sg
Instance.new("UICorner", hf).CornerRadius = UDim.new(0,12)

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 3, 1, -16)
accentBar.Position = UDim2.new(0, 8, 0, 8)
accentBar.BackgroundColor3 = C.shard
accentBar.BorderSizePixel = 0
accentBar.Parent = hf
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1,0)

local function mkL(txt, sz, pos, col, fnt)
	local l = Instance.new("TextLabel")
	l.Size = sz
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = col
	l.Font = fnt
	l.TextScaled = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = hf
	return l
end

local lblRound = mkL("Round 1", UDim2.new(1,-24,0,34), UDim2.new(0,20,0,8), C.white, Enum.Font.GothamBold)
local lblShards = mkL("Shards: 0/0", UDim2.new(1,-24,0,28), UDim2.new(0,20,0,48), C.shard, Enum.Font.Gotham)
local lblStatus = mkL("Enter the door", UDim2.new(1,-24,0,26), UDim2.new(0,20,0,84), C.door, Enum.Font.Gotham)

local function refreshHUD(s, c)
	lblRound.Text = "Round " .. currentRound
	lblShards.Text = "Shards: " .. collected .. "/" .. totalShards
	if s then 
		lblStatus.Text = s
		lblStatus.TextColor3 = c or C.white 
	end
end

-- Parry Button
local pg = Instance.new("ScreenGui")
pg.Name = "ParryGui"
pg.ResetOnSpawn = false
pg.Parent = player.PlayerGui

local pb = Instance.new("TextButton")
pb.Size = UDim2.new(0,110,0,110)
pb.Position = UDim2.new(1,-130,1,-140)
pb.BackgroundColor3 = C.parry
pb.Text = "PARRY"
pb.Font = Enum.Font.GothamBold
pb.TextSize = 22
pb.TextColor3 = Color3.new(0,0,0)
pb.BorderSizePixel = 0
pb.Parent = pg
Instance.new("UICorner", pb).CornerRadius = UDim.new(1,0)

local pstroke = Instance.new("UIStroke")
pstroke.Color = Color3.new(1,1,1)
pstroke.Thickness = 3
pstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
pstroke.Parent = pb

local function holdParry()
	isParrying = true
	TweenService:Create(pb, TweenInfo.new(0.08), {BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(0,122,0,122)}):Play()
end

local function releaseParry()
	isParrying = false
	TweenService:Create(pb, TweenInfo.new(0.12), {BackgroundColor3 = C.parry, Size = UDim2.new(0,110,0,110)}):Play()
end

pb.MouseButton1Down:Connect(holdParry)
pb.MouseButton1Up:Connect(releaseParry)
pb.MouseLeave:Connect(releaseParry)

local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	if inp.KeyCode == Enum.KeyCode.Q or inp.KeyCode == Enum.KeyCode.ButtonR1 then holdParry() end
end)
UIS.InputEnded:Connect(function(inp)
	if inp.KeyCode == Enum.KeyCode.Q or inp.KeyCode == Enum.KeyCode.ButtonR1 then releaseParry() end
end)

-- ESP & Shard
local function checkESP()
	if espActive then return end
	local rem = 0
	for _, sd in ipairs(shardList) do if sd.part and sd.part.Parent then rem += 1 end end
	if rem <= math.max(1, math.ceil(totalShards * ESP_PCT)) then
		espActive = true
		accentBar.BackgroundColor3 = C.gold
		refreshHUD("⚠ LAST " .. rem .. " SHARDS – ESP!", C.gold)
		for _, sd in ipairs(shardList) do
			if sd.part and sd.part.Parent then
				sd.part.Color = C.gold
				setESP(sd.part, C.gold, C.gold, 0.3)
			end
		end
	end
end

local function spawnShard(wp, folder)
	local p = Instance.new("Part")
	p.Name = "Shard"
	p.Size = Vector3.new(1.4,1.4,1.4)
	p.Shape = Enum.PartType.Ball
	p.Position = wp + Vector3.new(0,2.6,0)
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = C.shard
	p.CastShadow = false
	p.Parent = folder
	
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 8
	light.Color = C.shard
	light.Parent = p
	
	local baseY = p.Position.Y
	local ang = math.random() * math.pi * 2
	local ac = RunService.Heartbeat:Connect(function(dt)
		if p and p.Parent then
			ang += dt * 1.6
			p.CFrame = CFrame.new(p.Position.X, baseY + math.sin(ang*1.2)*0.3, p.Position.Z) * CFrame.Angles(0, ang, 0)
		end
	end)
	table.insert(animConns, ac)
	return p
end

local function spawnExitBeam(wp, folder)
	local b = Instance.new("Part")
	b.Name = "ExitBeam"
	b.Size = Vector3.new(CELL_SIZE-1,32,CELL_SIZE-1)
	b.Position = wp + Vector3.new(0,16,0)
	b.Anchored = true
	b.CanCollide = false
	b.Material = Enum.Material.Neon
	b.Color = C.beam
	b.Transparency = 0.4
	b.CastShadow = false
	b.Parent = folder
	setESP(b, C.beam, C.beam, 0.2)
	
	local pl = Instance.new("PointLight")
	pl.Brightness = 10
	pl.Range = 22
	pl.Color = C.beam
	pl.Parent = b
	
	local bc = RunService.Heartbeat:Connect(function()
		if b and b.Parent then b.Transparency = 0.22 + 0.22*math.sin(tick()*4.5) end
	end)
	table.insert(animConns, bc)
	return b
end

local function onShardTouched(sd)
	if not sd.part or not sd.part.Parent then return end
	if sd.conn then sd.conn:Disconnect() end
	local p = sd.part
	sd.part = nil
	TweenService:Create(p, TweenInfo.new(0.12), {Size = Vector3.new(2.8,2.8,2.8), Transparency = 1}):Play()
	task.delay(0.14, function() if p then p:Destroy() end end)
	
	collected += 1
	refreshHUD()
	checkESP()
	
	local rem = 0
	for _, s in ipairs(shardList) do if s.part and s.part.Parent then rem += 1 end end
	
	if rem == 0 then
		accentBar.BackgroundColor3 = C.beam
		refreshHUD("All shards! Reach the EXIT!", C.beam)
		local eb = spawnExitBeam(exitCellPos, mazeFolder)
		local bc = eb.Touched:Connect(function(hit)
			if hit.Parent \~= player.Character then return end
			bc:Disconnect()
			gameActive = false
			local h = getHRP()
			if h then h.CFrame = CFrame.new(safeSpawnPos) end
			currentRound += 1
			cleanAnimConns()
			if mazeFolder then mazeFolder:Destroy() end
			if dasherPart then dasherPart:Destroy() end
			if vortexLoop then vortexLoop:Disconnect() end
			if vortexPart then vortexPart:Destroy() end
			vortexActive = false
			shardList = {}
			collected = 0
			totalShards = 0
			espActive = false
			dasherActive = false
			pinpointSpawned = false
			pinpointChasing = false
			currentGrid = nil
			accentBar.BackgroundColor3 = C.shard
			refreshHUD("Round " .. (currentRound-1) .. " clear! Enter door for Round " .. currentRound, C.door)
		end)
	end
end

-- Maze Generation
local function generateMaze(W, H)
	local grid = {}
	for y = 1, H do grid[y] = table.create(W, 1) end
	grid[2][2] = 0
	local stack = {{2,2}}
	while #stack > 0 do
		local cur = stack[#stack]
		local cx, cy = cur[1], cur[2]
		local dirs = {{0,-2},{0,2},{-2,0},{2,0}}
		shuffle(dirs)
		local moved = false
		for _, d in ipairs(dirs) do
			local nx, ny = cx + d[1], cy + d[2]
			if nx >= 1 and nx <= W and ny >= 1 and ny <= H and grid[ny][nx] == 1 then
				grid[cy + d[2]/2][cx + d[1]/2] = 0
				grid[ny][nx] = 0
				table.insert(stack, {nx, ny})
				moved = true
				break
			end
		end
		if not moved then table.remove(stack) end
	end
	return grid
end

local function getOpenCells(grid, W, H)
	local cells = {}
	for y = 2, H-1 do
		for x = 2, W-1 do
			if grid[y][x] == 0 then table.insert(cells, {x,y}) end
		end
	end
	return cells
end

local function buildMazeWorld(grid, W, H)
	local f = Instance.new("Folder")
	f.Name = "Maze_Round" .. currentRound
	f.Parent = workspace
	makePart("Floor", Vector3.new(W*CELL_SIZE,1,H*CELL_SIZE), MAZE_ORIGIN + Vector3.new(W*CELL_SIZE/2, -0.5, H*CELL_SIZE/2), C.floor, Enum.Material.SmoothPlastic, 0, true, f)
	for y = 1, H do
		for x = 1, W do
			if grid[y][x] == 1 then
				makePart("Wall", Vector3.new(CELL_SIZE, WALL_H, CELL_SIZE), MAZE_ORIGIN + Vector3.new((x-0.5)*CELL_SIZE, WALL_H/2, (y-0.5)*CELL_SIZE), C.wall, Enum.Material.SmoothPlastic, 0, true, f)
			end
		end
	end
	return f
end

-- DASHER
local ALL_DIRS = {{1,0},{-1,0},{0,1},{0,-1}}

local function worldToCell(wp)
	local rel = wp - MAZE_ORIGIN
	local cx = math.clamp(math.floor(rel.X / CELL_SIZE) + 1, 1, gridW)
	local cy = math.clamp(math.floor(rel.Z / CELL_SIZE) + 1, 1, gridH)
	if currentGrid and currentGrid[cy] and currentGrid[cy][cx] == 0 then return cx, cy end
	for r = 1, 5 do
		for dy = -r, r do
			for dx = -r, r do
				local nx, ny = cx + dx, cy + dy
				if nx >= 1 and nx <= gridW and ny >= 1 and ny <= gridH and currentGrid[ny][nx] == 0 then
					return nx, ny
				end
			end
		end
	end
	return cx, cy
end

local function createDasherPart(folder)
	if dasherPart then dasherPart:Destroy() end
	local p = Instance.new("Part")
	p.Name = "Dasher"
	p.Size = Vector3.new(3.5,7,2.5)
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = C.dasher
	p.Transparency = 1
	p.CastShadow = false
	p.Position = MAZE_ORIGIN + Vector3.new(-30,3,-30)
	p.Parent = folder
	dasherPart = p
	
	if dasherConn then dasherConn:Disconnect() end
	dasherConn = p.Touched:Connect(function(hit)
		if p.Transparency > 0.5 then return end
		if hit.Parent == player.Character then
			local h = hit.Parent:FindFirstChildOfClass("Humanoid")
			if h then h.Health = 0 end
		end
	end)
end

local function startDasherLoop(chance, numTurns)
	if dasherLoop then dasherLoop:Disconnect() end
	local el = 0
	dasherLoop = RunService.Heartbeat:Connect(function(dt)
		if not gameActive or not currentGrid or dasherActive then return end
		el += dt
		if el < 10 then return end
		el = 0
		if math.random() > chance then return end
		
		dasherActive = true
		local hrp = getHRP()
		if not hrp then dasherActive = false; return end
		
		local pcx, pcy = worldToCell(hrp.Position)
		-- Simplified path for Dasher (you can expand later)
		local wps = {{pcx, pcy}}
		for i = 1, numTurns do
			table.insert(wps, {pcx + math.random(-5,5), pcy + math.random(-5,5)})
		end
		
		task.delay(3, function()
			if not gameActive then dasherActive = false; return end
			-- Dash toward player (simplified)
			local h = getHRP()
			if h and dasherPart then
				dasherPart.Position = cellToWorld(pcx, pcy) + Vector3.new(0,3,0)
				dasherPart.Transparency = 0
				TweenService:Create(dasherPart, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {Position = h.Position + Vector3.new(0,3,0)}):Play()
			end
			task.delay(2, function() dasherActive = false end)
		end)
	end)
end

-- VORTEX
local function createVortex()
	if vortexPart then vortexPart:Destroy() end
	local p = Instance.new("Part")
	p.Name = "Vortex"
	p.Size = Vector3.new(18, 45, 18)
	p.Shape = Enum.PartType.Cylinder
	p.CFrame = CFrame.new(MAZE_ORIGIN.X + gridW*CELL_SIZE/2, 80, MAZE_ORIGIN.Z + gridH*CELL_SIZE/2) * CFrame.Angles(math.rad(90), 0, 0)
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = C.vortex
	p.Transparency = 0.3
	p.CastShadow = false
	p.Parent = mazeFolder
	vortexPart = p
	return p
end

local function triggerVortex()
	if vortexActive or not gameActive or not mazeFolder then return end
	vortexActive = true
	
	local vortex = createVortex()
	refreshHUD("VORTEX INCOMING...", C.vortex)
	
	task.wait(3)
	if not gameActive then vortexActive = false; return end
	
	-- Suck animation
	for _, obj in ipairs(mazeFolder:GetChildren()) do
		if obj:IsA("BasePart") and (obj.Name == "Wall" or obj.Name == "Shard") then
			local tweenInfo = TweenInfo.new(2.8, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			TweenService:Create(obj, tweenInfo, {
				Position = obj.Position + Vector3.new(math.random(-20,20), 140, math.random(-20,20)),
				Transparency = 1
			}):Play()
		end
	end
	
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1,0,1,0)
	flash.BackgroundColor3 = Color3.new(1,1,1)
	flash.BackgroundTransparency = 1
	flash.Parent = sg
	TweenService:Create(flash, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
	
	task.wait(1.6)
	
	-- Regenerate maze
	cleanAnimConns()
	if mazeFolder then mazeFolder:Destroy() end
	if dasherPart then dasherPart:Destroy() end
	
	local oldCollected = collected
	local remaining = totalShards - collected
	
	local gW, gH = getRound(currentRound)
	local newGrid = generateMaze(gW, gH)
	currentGrid = newGrid
	gridW, gridH = gW, gH
	
	mazeFolder = buildMazeWorld(newGrid, gW, gH)
	
	local cells = getOpenCells(newGrid, gW, gH)
	shuffle(cells)
	
	shardList = {}
	collected = oldCollected
	totalShards = oldCollected + remaining
	
	for i = 1, math.min(remaining, #cells-1) do
		local cell = cells[i]
		local s = spawnShard(cellToWorld(cell[1], cell[2]), mazeFolder)
		local sd = {part = s, conn = nil}
		table.insert(shardList, sd)
		sd.conn = s.Touched:Connect(function(hit)
			if hit.Parent == player.Character then onShardTouched(sd) end
		end)
	end
	
	local sc = cells[1]
	local sp = cellToWorld(sc[1], sc[2]) + Vector3.new(0,1,0)
	exitCellPos = cellToWorld(cells[#cells][1], cells[#cells][2])
	
	if currentRound >= 1 then
		createDasherPart(mazeFolder)
		startDasherLoop(0.4, 8)
	end
	if currentRound >= 3 then
		startVortexLoop()
	end
	
	local hrp = getHRP()
	if hrp then hrp.CFrame = CFrame.new(sp) end
	
	TweenService:Create(flash, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
	task.delay(0.7, function() flash:Destroy() end)
	
	refreshHUD("Vortex passed... New maze! " .. remaining .. " shards left", C.vortex)
	vortexActive = false
	if vortexPart then vortexPart:Destroy() end
end

local function startVortexLoop()
	if vortexLoop then vortexLoop:Disconnect() end
	local timer = 0
	vortexLoop = RunService.Heartbeat:Connect(function(dt)
		if not gameActive or currentRound < 3 or vortexActive then return end
		timer += dt
		if timer < 30 then return end
		timer = 0
		if math.random() <= 0.35 then
			triggerVortex()
		end
	end)
end

-- Skip Saferoom Plate
local function createSkipPlate(folder)
	if skipPlate then skipPlate:Destroy() end
	local plate = makePart("SkipPlate", Vector3.new(6, 0.6, 6), SAFE_ORIGIN + Vector3.new(SAFE_W/2, 1.2, SAFE_D - 8), C.skip, Enum.Material.Neon, 0.2, true, folder)
	setESP(plate, C.skip, C.skip, 0.4)
	
	local label = Instance.new("BillboardGui")
	label.Size = UDim2.new(0, 140, 0, 50)
	label.StudsOffset = Vector3.new(0, 4, 0)
	label.AlwaysOnTop = true
	label.Parent = plate
	
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1,0,1,0)
	text.BackgroundTransparency = 1
	text.Text = "SKIP SAFEROOM"
	text.TextColor3 = C.white
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Parent = label
	
	local pulse = RunService.Heartbeat:Connect(function()
		if plate and plate.Parent then
			plate.Transparency = 0.15 + 0.25 * math.sin(tick() * 6)
		end
	end)
	table.insert(animConns, pulse)
	
	skipPlate = plate
	
	plate.Touched:Connect(function(hit)
		if hit.Parent \~= player.Character or gameActive then return end
		refreshHUD("Skipping to next saferoom...", C.skip)
		gameActive = false
		cleanAnimConns()
		if mazeFolder then mazeFolder:Destroy() end
		if vortexLoop then vortexLoop:Disconnect() end
		if vortexPart then vortexPart:Destroy() end
		vortexActive = false
		
		currentRound += 1
		local h = getHRP()
		if h then h.CFrame = CFrame.new(safeSpawnPos) end
		
		refreshHUD("Skipped to Round " .. currentRound, C.skip)
		task.wait(1.5)
		refreshHUD("Enter the door to start Round " .. currentRound, C.door)
	end)
end

local function buildSaferoom()
	local f = Instance.new("Folder")
	f.Name = "Saferoom"
	f.Parent = workspace
	
	local o = SAFE_ORIGIN
	local cX = SAFE_W/2
	local cZ = SAFE_D/2
	
	makePart("Floor", Vector3.new(SAFE_W,1,SAFE_D), o + Vector3.new(cX,-0.5,cZ), C.safeFlr, Enum.Material.SmoothPlastic, 0, true, f)
	makePart("Ceiling", Vector3.new(SAFE_W,1,SAFE_D), o + Vector3.new(cX,15.5,cZ), C.safe, Enum.Material.SmoothPlastic, 0, true, f)
	makePart("BackWall", Vector3.new(SAFE_W,16,1), o + Vector3.new(cX,7.5,SAFE_D), C.safe, Enum.Material.SmoothPlastic, 0, true, f)
	makePart("LeftWall", Vector3.new(1,16,SAFE_D), o + Vector3.new(0,7.5,cZ), C.safe, Enum.Material.SmoothPlastic, 0, true, f)
	makePart("RightWall", Vector3.new(1,16,SAFE_D), o + Vector3.new(SAFE_W,7.5,cZ), C.safe, Enum.Material.SmoothPlastic, 0, true, f)
	
	local dW = CELL_SIZE + 4
	local pW = (SAFE_W - dW) / 2
	makePart("FrontL", Vector3.new(pW,16,1), o + Vector3.new(pW/2,7.5,0), C.safe, Enum.Material.SmoothPlastic, 0, true, f)
	makePart("FrontR", Vector3.new(pW,16,1), o + Vector3.new(SAFE_W-pW/2,7.5,0), C.safe, Enum.Material.SmoothPlastic, 0, true, f)
	makePart("DoorHdr", Vector3.new(dW,4,1), o + Vector3.new(cX,14,0), C.safe, Enum.Material.SmoothPlastic, 0, true, f)
	
	local door = makePart("DoorTrigger", Vector3.new(dW,10,1.2), o + Vector3.new(cX,5.5,1.5), C.door, Enum.Material.Neon, 0.45, false, f)
	setESP(door, C.door, C.door, 0.3)
	
	local dp = RunService.Heartbeat:Connect(function()
		if door and door.Parent then door.Transparency = 0.32 + 0.2*math.sin(tick()*2.5) end
	end)
	table.insert(animConns, dp)
	
	createSkipPlate(f)
	
	doorPart = door
	return f, door
end

-- Start Round
local function startRound()
	if gameActive then return end
	gameActive = true
	espActive = false
	dasherActive = false
	vortexActive = false
	
	shardList = {}
	collected = 0
	cleanAnimConns()
	
	if mazeFolder then mazeFolder:Destroy() end
	if dasherPart then dasherPart:Destroy() end
	if vortexLoop then vortexLoop:Disconnect() end
	if vortexPart then vortexPart:Destroy() end
	
	accentBar.BackgroundColor3 = C.shard
	local gW, gH, st = getRound(currentRound)
	refreshHUD("Generating Round " .. currentRound .. "…", C.white)
	
	math.randomseed(os.clock() * 100000 + currentRound * 997)
	local grid = generateMaze(gW, gH)
	currentGrid = grid
	gridW, gridH = gW, gH
	
	mazeFolder = buildMazeWorld(grid, gW, gH)
	
	local cells = getOpenCells(grid, gW, gH)
	shuffle(cells)
	local sc = cells[1]
	local ec = cells[#cells]
	local sp = cellToWorld(sc[1], sc[2]) + Vector3.new(0,1,0)
	exitCellPos = cellToWorld(ec[1], ec[2])
	
	totalShards = math.min(st, #cells - 2)
	
	for i = 2, totalShards + 1 do
		local cell = cells[i]
		if not cell then break end
		local s = spawnShard(cellToWorld(cell[1], cell[2]), mazeFolder)
		local sd = {part = s, conn = nil}
		table.insert(shardList, sd)
		sd.conn = s.Touched:Connect(function(hit)
			if hit.Parent == player.Character then onShardTouched(sd) end
		end)
	end
	
	refreshHUD("Collect all " .. totalShards .. " shards!", C.shard)
	
	-- Spawn entities
	if currentRound >= 1 then
		createDasherPart(mazeFolder)
		startDasherLoop(currentRound >= 2 and 0.5 or 0.3, currentRound >= 2 and 10 or 5)
	end
	if currentRound >= 3 then
		startVortexLoop()
	end
	
	task.wait(0.15)
	local hrp = getHRP()
	if hrp then hrp.CFrame = CFrame.new(sp) end
end

-- Init
local _, initDoor = buildSaferoom()
task.wait(1.2)
local hrp = getHRP()
if hrp then hrp.CFrame = CFrame.new(safeSpawnPos) end
refreshHUD("Enter the door to start (or touch SKIP plate)", C.door)

initDoor.Touched:Connect(function(hit)
	if hit.Parent == player.Character and not gameActive then
		startRound()
	end
end)

player.CharacterAdded:Connect(function(c)
	character = c
	task.wait(0.5)
	local h = c:WaitForChild("HumanoidRootPart", 5)
	if h then
		if not gameActive then
			h.CFrame = CFrame.new(safeSpawnPos)
		else
			gameActive = false
			vortexActive = false
			cleanAnimConns()
			if mazeFolder then mazeFolder:Destroy() end
			if dasherPart then dasherPart:Destroy() end
			if vortexLoop then vortexLoop:Disconnect() end
			if vortexPart then vortexPart:Destroy() end
			shardList = {}
			collected = 0
			totalShards = 0
			espActive = false
			dasherActive = false
			currentGrid = nil
			accentBar.BackgroundColor3 = C.shard
			h.CFrame = CFrame.new(safeSpawnPos)
			refreshHUD("You died. Enter door to retry Round " .. currentRound, C.dasher)
		end
	end
end)

print("Grace: Maze Fanmade - Fully Loaded & Fixed")
