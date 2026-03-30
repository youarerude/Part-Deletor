-- ============================================================
--  GRACE : MAZE  –  Fanmade
--  LocalScript → StarterPlayerScripts
--  Credits: Devious Goober
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
    if r<=#ROUND_TABLE then return ROUND_TABLE[r][1],ROUND_TABLE[r][2],ROUND_TABLE[r][3] end
    local ex=r-#ROUND_TABLE; local w=61+ex*8; local h=61+ex*8
    if w%2==0 then w+=1 end; if h%2==0 then h+=1 end
    return w,h,900+ex*200
end

local C={
    wall=Color3.fromRGB(22,22,40), floor=Color3.fromRGB(14,14,28),
    shard=Color3.fromRGB(110,205,255), shardESP=Color3.fromRGB(80,180,255),
    beam=Color3.fromRGB(255,110,35), safe=Color3.fromRGB(30,50,30),
    safeFlr=Color3.fromRGB(40,65,40), door=Color3.fromRGB(45,210,95),
    white=Color3.new(1,1,1), gold=Color3.fromRGB(255,215,60),
    dasher=Color3.fromRGB(255,55,55), dasherPath=Color3.fromRGB(85,165,255),
    pinpoint=Color3.fromRGB(230,60,230), pinLine=Color3.fromRGB(255,100,255),
    parry=Color3.fromRGB(255,215,0),
}

local gameActive=false; local currentRound=1; local mazeFolder=nil
local shardList={}; local collected=0; local totalShards=0
local espActive=false; local exitCellPos=Vector3.new(0,0,0)
local animConns={}; local currentGrid=nil; local gridW,gridH=0,0
local safeSpawnPos=SAFE_ORIGIN+Vector3.new(SAFE_W/2,1.5,SAFE_D/2)
local doorPart=nil
local dasherPart=nil; local dasherActive=false; local dasherLoop=nil; local dasherConn=nil
local pinpointPart=nil; local pinpointLinePart=nil
local pinpointSpawned=false; local pinpointChasing=false
local pinpointLoop=nil; local pinpointHBConn=nil; local pinpointConn=nil
local isParrying=false

-- Modifier system
local appliedMods    = {}  -- set: mod id -> true
local modInexplicable  = false
local modWatchoutKiddo = false
local modFixation      = false
-- Prisoner state (Inexplicable)
local prisonerPart    = nil
local prisonerAngle   = 0
local prisonerDir     = 1
local prisonerBoosted = false
local prisonerBoostT  = 0
local prisonerRage    = 0
local prisonerHeadless = false
local prisonerChasing  = false
local prisonerChaseSpd = 0
local prisonerHBConn   = nil
local prisonerRageGui  = nil
local prisonerHeadFrame = nil

local function getHRP() local c=player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHumanoid() local c=player.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function shuffle(t) for i=#t,2,-1 do local j=math.random(1,i); t[i],t[j]=t[j],t[i] end end
local function cleanAnimConns() for _,c in ipairs(animConns) do pcall(function() c:Disconnect() end) end; animConns={} end
local function makePart(name,sz,pos,color,mat,trans,collide,parent)
    local p=Instance.new("Part"); p.Name=name; p.Size=sz; p.CFrame=CFrame.new(pos)
    p.Anchored=true; p.CanCollide=collide~=false; p.Material=mat or Enum.Material.SmoothPlastic
    p.Color=color; p.Transparency=trans or 0; p.CastShadow=false; p.Parent=parent; return p
end
local function cellToWorld(cx,cy) return MAZE_ORIGIN+Vector3.new((cx-0.5)*CELL_SIZE,0,(cy-0.5)*CELL_SIZE) end
local function setESP(part, outlineColor, fillColor, fillTransparency)
    if not part or not part:IsA("BasePart") then return end
    local hl = part:FindFirstChildOfClass("Highlight")
    if not hl then hl = Instance.new("Highlight"); hl.Name="ESP_Highlight"; hl.Parent=part end
    hl.Adornee             = part
    hl.OutlineColor        = outlineColor
    hl.OutlineTransparency = 0
    hl.FillColor           = fillColor or outlineColor
    hl.FillTransparency    = fillTransparency or 0.55
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
end

-- HUD
local sg=Instance.new("ScreenGui"); sg.Name="GraceMazeHUD"; sg.ResetOnSpawn=false; sg.Parent=player.PlayerGui
local hf=Instance.new("Frame"); hf.Size=UDim2.new(0,275,0,145); hf.Position=UDim2.new(0,14,0,14)
hf.BackgroundColor3=Color3.fromRGB(5,5,14); hf.BackgroundTransparency=0.18; hf.BorderSizePixel=0; hf.Parent=sg
Instance.new("UICorner",hf).CornerRadius=UDim.new(0,12)
local accentBar=Instance.new("Frame"); accentBar.Size=UDim2.new(0,3,1,-16); accentBar.Position=UDim2.new(0,8,0,8)
accentBar.BackgroundColor3=C.shard; accentBar.BorderSizePixel=0; accentBar.Parent=hf
Instance.new("UICorner",accentBar).CornerRadius=UDim.new(1,0)
local function mkL(txt,sz,pos,col,fnt)
    local l=Instance.new("TextLabel"); l.Size=sz; l.Position=pos; l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3=col; l.Font=fnt; l.TextScaled=true
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=hf; return l
end
local lblRound=mkL("Round 1",UDim2.new(1,-24,0,34),UDim2.new(0,20,0,8),C.white,Enum.Font.GothamBold)
local lblShards=mkL("Shards: 0/0",UDim2.new(1,-24,0,28),UDim2.new(0,20,0,48),C.shard,Enum.Font.Gotham)
local lblStatus=mkL("Enter the door",UDim2.new(1,-24,0,26),UDim2.new(0,20,0,84),C.door,Enum.Font.Gotham)
local function refreshHUD(s,c) lblRound.Text="Round "..currentRound; lblShards.Text="Shards: "..collected.."/"..totalShards; if s then lblStatus.Text=s; lblStatus.TextColor3=c or C.white end end

-- Parry button
local pg=Instance.new("ScreenGui"); pg.Name="ParryGui"; pg.ResetOnSpawn=false; pg.Parent=player.PlayerGui
local pb=Instance.new("TextButton"); pb.Size=UDim2.new(0,110,0,110); pb.Position=UDim2.new(1,-130,1,-140)
pb.BackgroundColor3=C.parry; pb.Text="PARRY"; pb.Font=Enum.Font.GothamBold; pb.TextSize=22
pb.TextColor3=Color3.new(0,0,0); pb.BorderSizePixel=0; pb.Parent=pg
Instance.new("UICorner",pb).CornerRadius=UDim.new(1,0)
local pstroke=Instance.new("UIStroke"); pstroke.Color=Color3.new(1,1,1); pstroke.Thickness=3
pstroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; pstroke.Parent=pb
local function holdParry() isParrying=true; TweenService:Create(pb,TweenInfo.new(0.08),{BackgroundColor3=Color3.new(1,1,1),Size=UDim2.new(0,122,0,122)}):Play() end
local function releaseParry() isParrying=false; TweenService:Create(pb,TweenInfo.new(0.12),{BackgroundColor3=C.parry,Size=UDim2.new(0,110,0,110)}):Play() end
pb.MouseButton1Down:Connect(holdParry); pb.MouseButton1Up:Connect(releaseParry); pb.MouseLeave:Connect(releaseParry)
local UIS=game:GetService("UserInputService")
UIS.InputBegan:Connect(function(inp,gpe) if gpe then return end; if inp.KeyCode==Enum.KeyCode.Q or inp.KeyCode==Enum.KeyCode.ButtonR1 then holdParry() end end)
UIS.InputEnded:Connect(function(inp) if inp.KeyCode==Enum.KeyCode.Q or inp.KeyCode==Enum.KeyCode.ButtonR1 then releaseParry() end end)

-- All modifier definitions
local ALL_MODIFIERS = {
    {id="Inexplicable",  name="Inexplicable.",    col=Color3.fromRGB(160,80,255),
     desc="Prisoner Appears.",
     perk="[+20% shard magnetize range]",
     onApply=function() modInexplicable=true end},
    {id="WatchoutKiddo", name="Watchout Kiddo!",  col=Color3.fromRGB(255,130,30),
     desc="Dasher has infinite turns and 3x faster.",
     perk="[15% dmg reduction from entities]",
     onApply=function() modWatchoutKiddo=true end},
    {id="FIXATION",      name="FIXATION.",         col=Color3.fromRGB(255,40,40),
     desc="Pinpoint is 5x faster.",
     perk="[+100% walkspeed]",
     onApply=function()
         modFixation=true
         local hum=getHumanoid(); if hum then hum.WalkSpeed=32 end
     end},
    {id="Wanderlust",    name="Wanderlust.",        col=Color3.fromRGB(80,200,120),
     desc="Maze breathes wider next round.",
     perk="[+5% walk speed]",
     onApply=function() local h=getHumanoid(); if h then h.WalkSpeed=math.min(32,h.WalkSpeed+0.8) end end},
    {id="Ironclad",      name="Ironclad.",          col=Color3.fromRGB(160,160,180),
     desc="Collect a shard, recover a little.",
     perk="[+8 HP per shard]",
     onApply=function() end},  -- handled in onShardTouched check
    {id="BlindEye",      name="Blind Eye.",          col=Color3.fromRGB(200,200,60),
     desc="ESP kicks in at 20% shards instead of 10%.",
     perk="[ESP activates earlier]",
     onApply=function() end},  -- handled via ESP_PCT override
    {id="Phantom",       name="Phantom.",            col=Color3.fromRGB(100,200,220),
     desc="Entities flicker — harder to track.",
     perk="[+10 studs parry window]",
     onApply=function() end},
    {id="Bloodpact",     name="Bloodpact.",          col=Color3.fromRGB(200,20,20),
     desc="Half your HP from the start.",
     perk="[Shards give +5 HP each]",
     onApply=function() local h=getHumanoid(); if h then h.Health=h.MaxHealth/2 end end},
}

-- ── Modifier GUI ──
local modGui = Instance.new("ScreenGui")
modGui.Name="ModifierGui"; modGui.ResetOnSpawn=false; modGui.Parent=player.PlayerGui

local modToggleBtn = Instance.new("TextButton")
modToggleBtn.Size     = UDim2.new(0,140,0,38)
modToggleBtn.Position = UDim2.new(1,-150,0,10)
modToggleBtn.BackgroundColor3 = Color3.fromRGB(18,12,30)
modToggleBtn.Text = "MODIFIERS ▼"
modToggleBtn.Font = Enum.Font.GothamBold; modToggleBtn.TextSize=15
modToggleBtn.TextColor3 = Color3.fromRGB(200,150,255)
modToggleBtn.BorderSizePixel=0; modToggleBtn.Parent=modGui
Instance.new("UICorner",modToggleBtn).CornerRadius=UDim.new(0,8)
local ms=Instance.new("UIStroke"); ms.Color=Color3.fromRGB(120,60,200); ms.Thickness=2; ms.Parent=modToggleBtn

local modPanel = Instance.new("Frame")
modPanel.Size = UDim2.new(0,295,0,460)
modPanel.Position = UDim2.new(0,10,0,60)
modPanel.BackgroundColor3 = Color3.fromRGB(10,8,20)
modPanel.BackgroundTransparency=0.1; modPanel.BorderSizePixel=0
modPanel.Visible=false; modPanel.Parent=modGui
Instance.new("UICorner",modPanel).CornerRadius=UDim.new(0,12)
local mps=Instance.new("UIStroke"); mps.Color=Color3.fromRGB(80,40,140); mps.Thickness=2; mps.Parent=modPanel

local modPanelOpen = false

-- Visibility: hide when in round
local visConn = RunService.Heartbeat:Connect(function()
    local show = not gameActive
    modToggleBtn.Visible = show
    if not show and modPanelOpen then
        modPanel.Visible=false; modPanelOpen=false
        modToggleBtn.Text="MODIFIERS ▼"
    end
end)

local function getAvailableMods()
    local pool={}
    for _,m in ipairs(ALL_MODIFIERS) do
        if not appliedMods[m.id] then table.insert(pool,m) end
    end
    -- shuffle
    for i=#pool,2,-1 do local j=math.random(1,i); pool[i],pool[j]=pool[j],pool[i] end
    local out={}; for i=1,math.min(5,#pool) do out[i]=pool[i] end
    return out
end

local function rebuildModPanel()
    -- Clear existing cards
    for _,c in ipairs(modPanel:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end

    local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-20,0,28)
    title.Position=UDim2.new(0,10,0,8); title.BackgroundTransparency=1
    title.Text="— MODIFIERS —"; title.TextColor3=Color3.fromRGB(200,150,255)
    title.Font=Enum.Font.GothamBold; title.TextScaled=true; title.Parent=modPanel

    local choices = getAvailableMods()
    if #choices==0 then
        local el=Instance.new("TextLabel"); el.Size=UDim2.new(1,-20,0,40)
        el.Position=UDim2.new(0,10,0,44); el.BackgroundTransparency=1
        el.Text="No modifiers left."; el.TextColor3=Color3.fromRGB(150,150,150)
        el.Font=Enum.Font.Gotham; el.TextScaled=true; el.Parent=modPanel
        return
    end

    for i,mod in ipairs(choices) do
        local card=Instance.new("TextButton")
        card.Size=UDim2.new(1,-20,0,78)
        card.Position=UDim2.new(0,10,0,40+(i-1)*84)
        card.BackgroundColor3=Color3.fromRGB(22,16,36)
        card.BorderSizePixel=0; card.Text=""; card.AutoButtonColor=false
        card.Parent=modPanel
        Instance.new("UICorner",card).CornerRadius=UDim.new(0,9)
        local cs=Instance.new("UIStroke"); cs.Color=mod.col; cs.Thickness=1.5; cs.Parent=card

        local cname=Instance.new("TextLabel"); cname.Size=UDim2.new(1,-10,0,24)
        cname.Position=UDim2.new(0,8,0,6); cname.BackgroundTransparency=1
        cname.Text=mod.name; cname.TextColor3=mod.col
        cname.Font=Enum.Font.GothamBold; cname.TextScaled=true
        cname.TextXAlignment=Enum.TextXAlignment.Left; cname.Parent=card

        local cdesc=Instance.new("TextLabel"); cdesc.Size=UDim2.new(1,-10,0,20)
        cdesc.Position=UDim2.new(0,8,0,30); cdesc.BackgroundTransparency=1
        cdesc.Text=mod.desc; cdesc.TextColor3=Color3.fromRGB(190,180,200)
        cdesc.Font=Enum.Font.Gotham; cdesc.TextScaled=true
        cdesc.TextXAlignment=Enum.TextXAlignment.Left; cdesc.Parent=card

        local cperk=Instance.new("TextLabel"); cperk.Size=UDim2.new(1,-10,0,18)
        cperk.Position=UDim2.new(0,8,0,52); cperk.BackgroundTransparency=1
        cperk.Text=mod.perk; cperk.TextColor3=Color3.fromRGB(80,220,120)
        cperk.Font=Enum.Font.Gotham; cperk.TextScaled=true
        cperk.TextXAlignment=Enum.TextXAlignment.Left; cperk.Parent=card

        card.MouseButton1Click:Connect(function()
            if gameActive then return end
            if appliedMods[mod.id] then return end
            appliedMods[mod.id]=true
            mod.onApply()
            -- Flash card
            TweenService:Create(card,TweenInfo.new(0.15),{BackgroundColor3=mod.col}):Play()
            task.delay(0.2,function()
                rebuildModPanel()
                -- Start prisoner immediately if inexplicable applied
                if mod.id=="Inexplicable" then
                    startPrisonerLoop()
                end
            end)
        end)
    end
end

modToggleBtn.MouseButton1Click:Connect(function()
    if gameActive then return end
    modPanelOpen = not modPanelOpen
    modPanel.Visible = modPanelOpen
    modToggleBtn.Text = modPanelOpen and "MODIFIERS ▲" or "MODIFIERS ▼"
    if modPanelOpen then rebuildModPanel() end
end)

-- entityDamage helper (respects WatchoutKiddo 15% reduction)
local function entityDamage(hum, amount)
    if not hum or hum.Health<=0 then return end
    local mult = modWatchoutKiddo and 0.85 or 1
    hum.Health = math.max(0.1, hum.Health - amount * mult)
end

-- ESP threshold
local function checkESP()
    if espActive then return end
    local rem=0; for _,sd in ipairs(shardList) do if sd.part and sd.part.Parent then rem+=1 end end
    if rem==0 then return end
    if rem<=math.max(1,math.ceil(totalShards*ESP_PCT)) then
        espActive=true; accentBar.BackgroundColor3=C.gold
        refreshHUD("⚠ LAST "..rem.." SHARDS – ESP!",C.gold)
        for _,sd in ipairs(shardList) do
            if sd.part and sd.part.Parent then
                sd.part.Color=C.gold; setESP(sd.part,C.gold,C.gold,0.3)
                local l=sd.part:FindFirstChildOfClass("PointLight"); if l then l.Color=C.gold; l.Brightness=5 end
            end
        end
    end
end

-- Shard (no ESP on spawn)
local function spawnShard(wp,folder)
    local p=Instance.new("Part"); p.Name="Shard"; p.Size=Vector3.new(1.4,1.4,1.4)
    p.Shape=Enum.PartType.Ball; p.Position=wp+Vector3.new(0,2.6,0)
    p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.Neon
    p.Color=C.shard; p.CastShadow=false; p.Parent=folder
    local light=Instance.new("PointLight"); light.Brightness=2; light.Range=8; light.Color=C.shard; light.Parent=p
    local baseY=p.Position.Y; local ang=math.random()*math.pi*2
    local ac=RunService.Heartbeat:Connect(function(dt)
        if p and p.Parent then ang+=dt*1.6; p.CFrame=CFrame.new(p.Position.X,baseY+math.sin(ang*1.2)*0.3,p.Position.Z)*CFrame.Angles(0,ang,0) end
    end); table.insert(animConns,ac)
    -- R3+: magnet — pull toward player within 10 studs
    if currentRound>=3 then
        local mc=RunService.Heartbeat:Connect(function(dt)
            if not p or not p.Parent then return end
            local hrp=getHRP(); if not hrp then return end
            local diff=hrp.Position-p.Position
            if diff.Magnitude<=(modInexplicable and 12 or 10) and diff.Magnitude>0.5 then
                p.CFrame=CFrame.new(p.Position+diff.Unit*math.min(18*dt,diff.Magnitude))
            end
        end)
        table.insert(animConns,mc)
    end
    return p
end

-- Exit beam (see-through ESP only, no billboard)
local function spawnExitBeam(wp,folder)
    local b=Instance.new("Part"); b.Name="ExitBeam"; b.Size=Vector3.new(CELL_SIZE-1,32,CELL_SIZE-1)
    b.Position=wp+Vector3.new(0,16,0); b.Anchored=true; b.CanCollide=false
    b.Material=Enum.Material.Neon; b.Color=C.beam; b.Transparency=0.4; b.CastShadow=false; b.Parent=folder
    setESP(b,C.beam,C.beam,0.2)
    local pl=Instance.new("PointLight"); pl.Brightness=10; pl.Range=22; pl.Color=C.beam; pl.Parent=b
    local bc=RunService.Heartbeat:Connect(function() if b and b.Parent then b.Transparency=0.22+0.22*math.sin(tick()*4.5) end end)
    table.insert(animConns,bc); return b
end

-- Shard collect
local function onShardTouched(sd)
    if not sd.part or not sd.part.Parent then return end
    if sd.conn then sd.conn:Disconnect(); sd.conn=nil end
    local p=sd.part; sd.part=nil
    TweenService:Create(p,TweenInfo.new(0.12),{Size=Vector3.new(2.8,2.8,2.8),Transparency=1}):Play()
    task.delay(0.14,function() if p then p:Destroy() end end)
    collected+=1; refreshHUD(); checkESP()
    local rem=0; for _,s in ipairs(shardList) do if s.part and s.part.Parent then rem+=1 end end
    if rem==0 then
        accentBar.BackgroundColor3=C.beam; refreshHUD("All shards! Reach the EXIT!",C.beam)
        local eb=spawnExitBeam(exitCellPos,mazeFolder); local bc
        bc=eb.Touched:Connect(function(hit)
            if hit.Parent~=player.Character then return end; bc:Disconnect(); gameActive=false
            local h=getHRP(); if h then h.CFrame=CFrame.new(safeSpawnPos) end
            currentRound+=1; cleanAnimConns()
            if mazeFolder then mazeFolder:Destroy(); mazeFolder=nil end
            if dasherPart then dasherPart:Destroy(); dasherPart=nil end
            if dasherLoop then dasherLoop:Disconnect(); dasherLoop=nil end
            if dasherConn then dasherConn:Disconnect(); dasherConn=nil end
            if pinpointHBConn then pinpointHBConn:Disconnect(); pinpointHBConn=nil end
            if pinpointLoop then pinpointLoop:Disconnect(); pinpointLoop=nil end
            if pinpointConn then pinpointConn:Disconnect(); pinpointConn=nil end
            if pinpointPart then pinpointPart:Destroy(); pinpointPart=nil end
            if pinpointLinePart then pinpointLinePart:Destroy(); pinpointLinePart=nil end
            shardList={}; collected=0; totalShards=0; espActive=false
            dasherActive=false; pinpointSpawned=false; pinpointChasing=false; currentGrid=nil
            accentBar.BackgroundColor3=C.shard
            refreshHUD("Round "..(currentRound-1).." clear! Enter door for Round "..currentRound,C.door)
        end)
    end
end

-- Maze generation
local function generateMaze(W,H)
    local grid={}; for y=1,H do grid[y]=table.create(W,1) end
    grid[2][2]=0; local stack={{2,2}}
    while #stack>0 do
        local cur=stack[#stack]; local cx,cy=cur[1],cur[2]
        local dirs={{0,-2},{0,2},{-2,0},{2,0}}; shuffle(dirs); local moved=false
        for _,d in ipairs(dirs) do
            local nx,ny=cx+d[1],cy+d[2]
            if nx>=1 and nx<=W and ny>=1 and ny<=H and grid[ny][nx]==1 then
                grid[cy+d[2]/2][cx+d[1]/2]=0; grid[ny][nx]=0; table.insert(stack,{nx,ny}); moved=true; break
            end
        end
        if not moved then table.remove(stack) end
    end; return grid
end
local function getOpenCells(grid,W,H)
    local cells={}; for y=2,H-1 do for x=2,W-1 do if grid[y][x]==0 then table.insert(cells,{x,y}) end end end; return cells
end
local function buildMazeWorld(grid,W,H)
    local f=Instance.new("Folder"); f.Name="Maze_Round"..currentRound; f.Parent=workspace
    makePart("Floor",Vector3.new(W*CELL_SIZE,1,H*CELL_SIZE),MAZE_ORIGIN+Vector3.new(W*CELL_SIZE/2,-0.5,H*CELL_SIZE/2),C.floor,Enum.Material.SmoothPlastic,0,true,f)
    for y=1,H do for x=1,W do if grid[y][x]==1 then
        makePart("Wall",Vector3.new(CELL_SIZE,WALL_H,CELL_SIZE),MAZE_ORIGIN+Vector3.new((x-0.5)*CELL_SIZE,WALL_H/2,(y-0.5)*CELL_SIZE),C.wall,Enum.Material.SmoothPlastic,0,true,f)
    end end end; return f
end

-- Dasher
local ALL_DIRS={{1,0},{-1,0},{0,1},{0,-1}}

-- Snap world pos to nearest open grid cell
local function worldToCell(wp)
    local rel=wp-MAZE_ORIGIN
    local cx=math.clamp(math.floor(rel.X/CELL_SIZE)+1,1,gridW)
    local cy=math.clamp(math.floor(rel.Z/CELL_SIZE)+1,1,gridH)
    if currentGrid and currentGrid[cy] and currentGrid[cy][cx]==0 then return cx,cy end
    for r=1,5 do for dy=-r,r do for dx=-r,r do
        local nx,ny=cx+dx,cy+dy
        if nx>=1 and nx<=gridW and ny>=1 and ny<=gridH and currentGrid[ny][nx]==0 then return nx,ny end
    end end end
    return cx,cy
end

-- Random-turn path starting from (sx,sy), doing numTurns turns
local function genDasherPath(sx,sy,numTurns)
    local cur={sx,sy}
    -- pick any valid start direction
    local sds={}
    for _,d in ipairs(ALL_DIRS) do
        local nx,ny=cur[1]+d[1],cur[2]+d[2]
        if nx>=1 and nx<=gridW and ny>=1 and ny<=gridH and currentGrid[ny][nx]==0 then table.insert(sds,d) end
    end
    if #sds==0 then return {cur} end
    shuffle(sds)
    local wps={{cur[1],cur[2]}}; local cd=sds[1]
    for _=1,numTurns do
        -- walk straight until wall
        local moved=false
        for _=1,200 do
            local nx,ny=cur[1]+cd[1],cur[2]+cd[2]
            if nx<1 or nx>gridW or ny<1 or ny>gridH or currentGrid[ny][nx]==1 then break end
            cur={nx,ny}; moved=true
        end
        if moved then table.insert(wps,{cur[1],cur[2]}) end
        -- pick a valid turn (not reverse, not same)
        local tds={}
        for _,d in ipairs(ALL_DIRS) do
            local ir=d[1]==-cd[1] and d[2]==-cd[2]
            local is=d[1]==cd[1]  and d[2]==cd[2]
            if not ir and not is then
                local nx2,ny2=cur[1]+d[1],cur[2]+d[2]
                if nx2>=1 and nx2<=gridW and ny2>=1 and ny2<=gridH and currentGrid[ny2][nx2]==0 then table.insert(tds,d) end
            end
        end
        if #tds==0 then break end
        shuffle(tds); cd=tds[1]
    end
    return wps
end

local function drawDasherPath(wps,folder)
    local pf=Instance.new("Folder"); pf.Name="DasherPath"; pf.Parent=folder; local PY=5
    for i=1,#wps-1 do
        local pA=cellToWorld(wps[i][1],wps[i][2])+Vector3.new(0,PY,0)
        local pB=cellToWorld(wps[i+1][1],wps[i+1][2])+Vector3.new(0,PY,0)
        local len=(pA-pB).Magnitude; if len>0.1 then
            local s=Instance.new("Part"); s.Size=Vector3.new(0.85,0.85,len)
            s.CFrame=CFrame.new((pA+pB)/2,pB); s.Anchored=true; s.CanCollide=false
            s.Material=Enum.Material.Neon; s.Color=C.dasherPath; s.Transparency=0.05
            s.CastShadow=false; s.Parent=pf
        end
    end
    for i,wp in ipairs(wps) do
        local dot=Instance.new("Part"); dot.Size=Vector3.new(1.8,1.8,1.8); dot.Shape=Enum.PartType.Ball
        dot.Position=cellToWorld(wp[1],wp[2])+Vector3.new(0,PY,0)
        dot.Anchored=true; dot.CanCollide=false; dot.Material=Enum.Material.Neon
        dot.Color=i==1 and C.gold or (i==#wps and C.dasher or C.dasherPath)
        dot.CastShadow=false; dot.Parent=pf
    end
    return pf
end

local function moveDasherAlong(wps,onDone)
    if not dasherPart then if onDone then onDone() end; return end
    local SPEED=modWatchoutKiddo and 165 or 55; local idx=1
    local function nxt()
        if not dasherPart or not dasherPart.Parent then if onDone then onDone() end; return end
        idx+=1; if idx>#wps then if onDone then onDone() end; return end
        local tgt=cellToWorld(wps[idx][1],wps[idx][2])+Vector3.new(0,3,0)
        local tw=TweenService:Create(dasherPart,TweenInfo.new((tgt-dasherPart.Position).Magnitude/SPEED,Enum.EasingStyle.Linear),{Position=tgt})
        tw:Play(); tw.Completed:Connect(nxt)
    end
    dasherPart.Position=cellToWorld(wps[1][1],wps[1][2])+Vector3.new(0,3,0); dasherPart.Transparency=0; nxt()
end

local function createDasherPart(folder)
    if dasherPart then dasherPart:Destroy() end
    local p=Instance.new("Part"); p.Name="Dasher"; p.Size=Vector3.new(3.5,7,2.5)
    p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.Neon; p.Color=C.dasher
    p.Transparency=1; p.CastShadow=false; p.Position=MAZE_ORIGIN+Vector3.new(-30,3,-30)
    setESP(p,C.dasher,C.dasher,0.3)
    local l=Instance.new("PointLight"); l.Brightness=8; l.Range=18; l.Color=C.dasher; l.Parent=p
    p.Parent=folder; dasherPart=p
    if dasherConn then dasherConn:Disconnect() end
    dasherConn=p.Touched:Connect(function(hit)
        if p.Transparency>0.5 then return end
        if hit.Parent==player.Character then local h=hit.Parent:FindFirstChildOfClass("Humanoid"); if h then h.Health=0 end end
    end)
end

local function startDasherLoop(chance,numTurns)
    if dasherLoop then dasherLoop:Disconnect(); dasherLoop=nil end; local el=0
    dasherLoop=RunService.Heartbeat:Connect(function(dt)
        if not gameActive or not currentGrid then return end; el+=dt; if el<10 then return end; el=0
        if dasherActive then return end; if math.random()>chance then return end; dasherActive=true

        local hrp=getHRP(); if not hrp then dasherActive=false; return end
        -- Line spawns at player, walks random turns outward
        local pcx,pcy=worldToCell(hrp.Position)
        local wps=genDasherPath(pcx,pcy,modWatchoutKiddo and 9999 or numTurns)
        if #wps<2 then dasherActive=false; return end

        local pf=drawDasherPath(wps,mazeFolder)
        local fT=0
        local fC=RunService.Heartbeat:Connect(function(fd)
            fT+=fd
            for _,s in ipairs(pf:GetDescendants()) do if s:IsA("BasePart") then s.Transparency=0.05+0.5*math.abs(math.sin(fT*8)) end end
        end)

        task.delay(3,function()
            pcall(function() fC:Disconnect() end)
            if pf and pf.Parent then
                for _,s in ipairs(pf:GetDescendants()) do if s:IsA("BasePart") then TweenService:Create(s,TweenInfo.new(0.3),{Transparency=1}):Play() end end
                task.delay(0.35,function() if pf and pf.Parent then pf:Destroy() end end)
            end
            if not gameActive or not dasherPart then dasherActive=false; return end
            -- Dasher runs the path in REVERSE (end of line → player)
            local revWps={}; for i=#wps,1,-1 do table.insert(revWps,wps[i]) end
            moveDasherAlong(revWps,function()
                if dasherPart and dasherPart.Parent then
                    TweenService:Create(dasherPart,TweenInfo.new(0.3),{Transparency=1}):Play()
                    task.delay(0.35,function()
                        if dasherPart and dasherPart.Parent then dasherPart.Position=MAZE_ORIGIN+Vector3.new(-30,3,-30) end
                        dasherActive=false
                    end)
                else dasherActive=false end
            end)
        end)
    end)
end

-- Pinpoint

-- BFS through maze from (sx,sy) to (ex,ey), returns list of {x,y} cells
local function bfsPath(sx,sy,ex,ey)
    if sx==ex and sy==ey then return {{sx,sy}} end
    local W,H=gridW,gridH; local grid=currentGrid
    local function K(x,y) return y*(W+1)+x end
    local visited={}; local prev={}; local queue={{sx,sy}}
    visited[K(sx,sy)]=true
    while #queue>0 do
        local cur=table.remove(queue,1); local cx,cy=cur[1],cur[2]
        if cx==ex and cy==ey then
            local path={}; local node={ex,ey}
            while node do table.insert(path,1,node); node=prev[K(node[1],node[2])] end
            return path
        end
        for _,d in ipairs(ALL_DIRS) do
            local nx,ny=cx+d[1],cy+d[2]
            if nx>=1 and nx<=W and ny>=1 and ny<=H and grid[ny][nx]==0 then
                local nk=K(nx,ny)
                if not visited[nk] then visited[nk]=true; prev[nk]=cur; table.insert(queue,{nx,ny}) end
            end
        end
    end
    return {}
end

-- Reduce full cell list to just the turn waypoints
local function simplifyPath(path)
    if #path<=2 then return path end
    local wps={path[1]}
    local pd={path[2][1]-path[1][1], path[2][2]-path[1][2]}
    for i=3,#path do
        local d={path[i][1]-path[i-1][1], path[i][2]-path[i-1][2]}
        if d[1]~=pd[1] or d[2]~=pd[2] then table.insert(wps,path[i-1]); pd=d end
    end
    table.insert(wps,path[#path]); return wps
end


-- Draw a Pinpoint path (corridor turns) in the world, returns folder
local function drawPinpointPath(wps,folder)
    local pf=Instance.new("Folder"); pf.Name="PinpointPath"; pf.Parent=folder
    local PY=5
    for i=1,#wps-1 do
        local pA=cellToWorld(wps[i][1],wps[i][2])+Vector3.new(0,PY,0)
        local pB=cellToWorld(wps[i+1][1],wps[i+1][2])+Vector3.new(0,PY,0)
        local len=(pA-pB).Magnitude; if len>0.1 then
            local s=Instance.new("Part"); s.Size=Vector3.new(0.75,0.75,len)
            s.CFrame=CFrame.new((pA+pB)/2,pB); s.Anchored=true; s.CanCollide=false
            s.Material=Enum.Material.Neon; s.Color=C.pinLine
            s.Transparency=0.05; s.CastShadow=false; s.Parent=pf
        end
    end
    for i,wp in ipairs(wps) do
        local dot=Instance.new("Part"); dot.Size=Vector3.new(1.5,1.5,1.5); dot.Shape=Enum.PartType.Ball
        dot.Position=cellToWorld(wp[1],wp[2])+Vector3.new(0,PY,0)
        dot.Anchored=true; dot.CanCollide=false; dot.Material=Enum.Material.Neon
        -- pinpoint spawn = first wp (pink), player end = last wp (gold), corners = lighter pink
        dot.Color=i==1 and C.pinpoint or (i==#wps and C.gold or C.pinLine)
        dot.CastShadow=false; dot.Parent=pf
    end
    return pf
end

local function clearPinpointPath(pf)
    if not pf or not pf.Parent then return end
    for _,s in ipairs(pf:GetDescendants()) do
        if s:IsA("BasePart") then TweenService:Create(s,TweenInfo.new(0.25),{Transparency=1}):Play() end
    end
    task.delay(0.3,function() if pf and pf.Parent then pf:Destroy() end end)
end

local function createPinpointPart(folder)
    if pinpointPart then pinpointPart:Destroy() end
    local p=Instance.new("Part"); p.Name="Pinpoint"; p.Size=Vector3.new(2.2,5.5,2.2)
    p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.Neon; p.Color=C.pinpoint
    p.Transparency=1; p.CastShadow=false; p.Position=MAZE_ORIGIN+Vector3.new(-30,3,-30)
    setESP(p,C.pinpoint,C.pinpoint,0.25)
    local l=Instance.new("PointLight"); l.Brightness=9; l.Range=20; l.Color=C.pinpoint; l.Parent=p
    p.Parent=folder; pinpointPart=p
end
-- Pinpoint contact handlers (parry / kill)
local function onPinpointContact(rechaseFunc)
    if isParrying then
        pinpointChasing=false; pinpointSpawned=false
        if pinpointHBConn then pinpointHBConn:Disconnect(); pinpointHBConn=nil end
        TweenService:Create(pinpointPart,TweenInfo.new(0.2),{Transparency=1}):Play()
        task.delay(0.25,function() if pinpointPart and pinpointPart.Parent then pinpointPart.Position=MAZE_ORIGIN+Vector3.new(-30,3,-30) end end)
        local flash=Instance.new("Frame"); flash.Size=UDim2.new(1,0,1,0); flash.BackgroundColor3=C.pinpoint
        flash.BackgroundTransparency=0; flash.BorderSizePixel=0; flash.Parent=sg
        TweenService:Create(flash,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play()
        task.delay(0.55,function() flash:Destroy() end)
        refreshHUD("Parry! Pinpoint destroyed!",C.pinpoint)
    else
        pinpointChasing=false
        if pinpointHBConn then pinpointHBConn:Disconnect(); pinpointHBConn=nil end
        local h=getHumanoid(); if h then h.Health=0 end
        -- stays alive, re-chases after respawn
        task.delay(4,function()
            if pinpointSpawned and gameActive and pinpointPart and pinpointPart.Parent then
                rechaseFunc()
            end
        end)
    end
end

-- Chase along BFS waypoints, recalculating whenever player moves cell
local function startPinpointChase(scx, scy)
    if pinpointHBConn then pinpointHBConn:Disconnect(); pinpointHBConn=nil end
    pinpointChasing=true

    local SPEED = 90 + math.max(0, currentRound - 2) * 30
    if currentRound >= 5 then SPEED = 180 end
    if modFixation then SPEED = SPEED * 5 end
    local hrp=getHRP(); if not hrp then pinpointChasing=false; return end

    -- Build full cell path from current pinpoint pos to player
    local function rebuildPath()
        local h=getHRP(); if not h then return {} end
        local pcx,pcy=worldToCell(h.Position)
        local ppx,ppy=worldToCell(pinpointPart.Position)
        local fullPath=bfsPath(ppx,ppy,pcx,pcy)
        -- Convert to world positions (corridor centre, Y=3)
        local pts={}
        for _,cell in ipairs(fullPath) do
            table.insert(pts, cellToWorld(cell[1],cell[2])+Vector3.new(0,3,0))
        end
        return pts
    end

    local pts=rebuildPath()
    local ptIdx=1  -- current target point index

    local lastCX,lastCY=worldToCell(hrp.Position)

    pinpointHBConn=RunService.Heartbeat:Connect(function(dt)
        if not pinpointChasing then return end
        if not pinpointPart or not pinpointPart.Parent then return end
        local h=getHRP(); if not h then return end

        -- If player moved to a new cell, recalculate path from current position
        local ncx,ncy=worldToCell(h.Position)
        if ncx~=lastCX or ncy~=lastCY then
            lastCX,lastCY=ncx,ncy
            pts=rebuildPath()
            ptIdx=1
        end

        if #pts==0 then return end

        -- Check contact with player directly
        local playerDist=(pinpointPart.Position-h.Position).Magnitude
        if playerDist<3.5 then
            onPinpointContact(function() startPinpointChase(scx,scy) end)
            return
        end

        -- Advance along waypoints
        local cur=pinpointPart.Position
        while ptIdx<=#pts do
            local wp=pts[ptIdx]
            local d=(wp-cur).Magnitude
            if d<1.5 then
                ptIdx+=1  -- reached this waypoint, move to next
            else
                -- Move toward current waypoint
                local dir=(wp-cur).Unit
                pinpointPart.CFrame=CFrame.new(cur+dir*math.min(SPEED*dt,d))
                break
            end
        end

        -- If we exhausted all waypoints rebuild (player may have moved slightly)
        if ptIdx>#pts then
            pts=rebuildPath(); ptIdx=1
        end
    end)
end
local function startPinpointLoop()
    if pinpointLoop then pinpointLoop:Disconnect(); pinpointLoop=nil end; local el=0
    pinpointLoop=RunService.Heartbeat:Connect(function(dt)
        if not gameActive or not currentGrid then return end
        if pinpointSpawned then return end; el+=dt; if el<8 then return end; el=0
        if math.random()>0.50 then return end; pinpointSpawned=true

        -- Pick random spawn cell
        local cells=getOpenCells(currentGrid,gridW,gridH); shuffle(cells)
        if #cells==0 then pinpointSpawned=false; return end
        local scx,scy=cells[1][1],cells[1][2]
        local spawnWorld=cellToWorld(scx,scy)+Vector3.new(0,3,0)

        local hrp=getHRP(); if not hrp then pinpointSpawned=false; return end

        -- BFS path from spawn to player
        local pcx,pcy=worldToCell(hrp.Position)
        local path=bfsPath(scx,scy,pcx,pcy)
        local wps=simplifyPath(path)

        -- Draw the corridor path
        local pathFolder=drawPinpointPath(wps,mazeFolder)

        -- Flash pulse while player reads it
        local fT=0
        local fC=RunService.Heartbeat:Connect(function(fd)
            fT+=fd
            for _,s in ipairs(pathFolder:GetDescendants()) do
                if s:IsA("BasePart") then s.Transparency=0.05+0.5*math.abs(math.sin(fT*9)) end
            end
        end)

        -- If player moves to a new cell during warning → recalculate BFS (new turns added)
        local lastCX,lastCY=pcx,pcy
        local moveConn; moveConn=RunService.Heartbeat:Connect(function()
            if not gameActive then pcall(function() moveConn:Disconnect() end); return end
            local h2=getHRP(); if not h2 then return end
            local ncx,ncy=worldToCell(h2.Position)
            if ncx~=lastCX or ncy~=lastCY then
                lastCX,lastCY=ncx,ncy
                local newPath=bfsPath(scx,scy,ncx,ncy)
                if #newPath>=2 then
                    wps=simplifyPath(newPath)
                    clearPinpointPath(pathFolder)
                    pathFolder=drawPinpointPath(wps,mazeFolder)
                end
            end
        end)

        task.delay(3,function()
            pcall(function() fC:Disconnect() end)
            pcall(function() moveConn:Disconnect() end)
            clearPinpointPath(pathFolder)
            if not gameActive or not pinpointPart then return end
            -- Pinpoint appears at spawn and follows BFS path to player
            pinpointPart.Position=spawnWorld; pinpointPart.Transparency=0
            startPinpointChase(scx,scy)
        end)
    end)
end


-- ── Saint ──────────────────────────────────────────────────
local saintPart      = nil
local saintActive    = false
local saintLoop      = nil
local saintEventConn = nil

-- Vignette overlay (4 edge panels, hidden until saint event)
local vigGui = Instance.new("ScreenGui")
vigGui.Name = "SaintVig"; vigGui.ResetOnSpawn = false
vigGui.IgnoreGuiInset = true; vigGui.Parent = player.PlayerGui

local function makeVigEdge(anchorX, anchorY, posX, posY, sizeX, sizeY, gradRot)
    local f = Instance.new("Frame")
    f.AnchorPoint = Vector2.new(anchorX, anchorY)
    f.Position    = UDim2.new(posX, 0, posY, 0)
    f.Size        = UDim2.new(sizeX, 0, sizeY, 0)
    f.BackgroundColor3 = Color3.new(0,0,0)
    f.BackgroundTransparency = 1   -- hidden by default
    f.BorderSizePixel = 0; f.Parent = vigGui
    local g = Instance.new("UIGradient"); g.Rotation = gradRot
    g.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.65, 0.8),
        NumberSequenceKeypoint.new(1, 1)
    }; g.Parent = f; return f
end
local vigEdges = {
    makeVigEdge(0,0, 0,0, 1,0.45, 180), -- top
    makeVigEdge(0,1, 0,1, 1,0.45, 0),   -- bottom
    makeVigEdge(0,0, 0,0, 0.38,1, 270), -- left
    makeVigEdge(1,0, 1,0, 0.38,1, 90),  -- right
}
local function setVigAlpha(a) -- 0=off, 1=full vignette
    for _, e in ipairs(vigEdges) do e.BackgroundTransparency = 1 - a end
end

-- Build saint part + billboard eye
local function buildSaintEntity()
    local mazeCX = MAZE_ORIGIN.X + (gridW * CELL_SIZE) / 2
    local mazeCZ = MAZE_ORIGIN.Z + (gridH * CELL_SIZE) / 2
    local skyPos  = Vector3.new(mazeCX, 90, mazeCZ)

    -- Invisible anchor part
    local part = Instance.new("Part")
    part.Name = "Saint"; part.Size = Vector3.new(4,4,4)
    part.Position = skyPos; part.Anchored = true
    part.CanCollide = false; part.Transparency = 1
    part.CastShadow = false; part.Parent = workspace

    -- BillboardGui containing the drawn eye
    local bb = Instance.new("BillboardGui")
    bb.Name = "SaintEye"; bb.Size = UDim2.new(0, 400, 0, 400)
    bb.StudsOffsetWorldSpace = Vector3.new(0,0,0)
    bb.AlwaysOnTop = true; bb.Parent = part

    local root = Instance.new("Frame")
    root.Size = UDim2.new(1,0,1,0); root.BackgroundTransparency = 1
    root.BorderSizePixel = 0; root.Parent = bb

    -- Angel halo ring (top center)
    local halo = Instance.new("Frame")
    halo.Name = "Halo"
    halo.Size = UDim2.new(0,130,0,130)
    halo.Position = UDim2.new(0.5,-65,0.0,0)
    halo.BackgroundTransparency = 1; halo.BorderSizePixel = 0
    halo.Parent = root
    Instance.new("UICorner", halo).CornerRadius = UDim.new(1,0)
    local haloStroke = Instance.new("UIStroke")
    haloStroke.Color = Color3.fromRGB(255,225,80)
    haloStroke.Thickness = 9; haloStroke.Parent = halo

    -- Left wing
    local function makeWing(side)
        local w = Instance.new("Frame")
        w.Size = UDim2.new(0,160,0,70)
        w.BackgroundColor3 = Color3.fromRGB(235,235,255)
        w.BackgroundTransparency = 0.15; w.BorderSizePixel = 0
        w.Position = side=="L" and UDim2.new(0.5,-230,0.48,-20) or UDim2.new(0.5,70,0.48,-20)
        w.Rotation  = side=="L" and -18 or 18; w.Parent = root
        Instance.new("UICorner", w).CornerRadius = UDim.new(0.5,0)
        -- feather lines
        for i=1,3 do
            local line = Instance.new("Frame")
            line.Size = UDim2.new(0,2,0.75,0)
            line.Position = UDim2.new(0.22*i,0,0.12,0)
            line.BackgroundColor3 = Color3.fromRGB(180,180,220)
            line.BackgroundTransparency = 0.3; line.BorderSizePixel=0; line.Parent=w
        end
        -- second smaller feather row
        local w2 = Instance.new("Frame")
        w2.Size = UDim2.new(0,110,0,45)
        w2.BackgroundColor3 = Color3.fromRGB(225,225,250)
        w2.BackgroundTransparency = 0.2; w2.BorderSizePixel=0
        w2.Position = side=="L" and UDim2.new(0.5,-185,0.54,-10) or UDim2.new(0.5,75,0.54,-10)
        w2.Rotation = side=="L" and -30 or 30; w2.Parent = root
        Instance.new("UICorner", w2).CornerRadius = UDim.new(0.5,0)
    end
    makeWing("L"); makeWing("R")

    -- Eye container (clips eyelids)
    local eyeCon = Instance.new("Frame")
    eyeCon.Name = "EyeCon"
    eyeCon.Size = UDim2.new(0,220,0,100)
    eyeCon.Position = UDim2.new(0.5,-110,0.5,-50)
    eyeCon.BackgroundTransparency = 1; eyeCon.ClipsDescendants = true
    eyeCon.BorderSizePixel = 0; eyeCon.Parent = root

    -- Eye white
    local eyeW = Instance.new("Frame")
    eyeW.Size = UDim2.new(1,0,1,0); eyeW.BackgroundColor3 = Color3.fromRGB(255,255,255)
    eyeW.BorderSizePixel = 0; eyeW.Parent = eyeCon
    Instance.new("UICorner", eyeW).CornerRadius = UDim.new(0.5,0)

    -- Iris
    local iris = Instance.new("Frame")
    iris.Size = UDim2.new(0,62,0,62)
    iris.Position = UDim2.new(0.5,-31,0.5,-31)
    iris.BackgroundColor3 = Color3.fromRGB(180,130,255)
    iris.BorderSizePixel=0; iris.Parent = eyeW
    Instance.new("UICorner", iris).CornerRadius = UDim.new(1,0)

    -- Pupil
    local pupil = Instance.new("Frame")
    pupil.Size = UDim2.new(0,38,0,38)
    pupil.Position = UDim2.new(0.5,-19,0.5,-19)
    pupil.BackgroundColor3 = Color3.fromRGB(10,5,20)
    pupil.BorderSizePixel=0; pupil.Parent = iris
    Instance.new("UICorner", pupil).CornerRadius = UDim.new(1,0)

    -- Glint
    local glint = Instance.new("Frame")
    glint.Size = UDim2.new(0,10,0,10)
    glint.Position = UDim2.new(0.6,0,0.1,0)
    glint.BackgroundColor3 = Color3.new(1,1,1)
    glint.BorderSizePixel=0; glint.Parent = pupil
    Instance.new("UICorner", glint).CornerRadius = UDim.new(1,0)

    -- Eyelids (start CLOSED: both covering the eye)
    local upperLid = Instance.new("Frame")
    upperLid.Name = "UpperLid"
    upperLid.Size = UDim2.new(1,0,0.6,0)
    upperLid.Position = UDim2.new(0,0,-0.05,0) -- closed: sits on top half
    upperLid.BackgroundColor3 = Color3.fromRGB(25,20,45)
    upperLid.BorderSizePixel=0; upperLid.ZIndex=4; upperLid.Parent=eyeCon
    Instance.new("UICorner", upperLid).CornerRadius = UDim.new(0.35,0)

    local lowerLid = Instance.new("Frame")
    lowerLid.Name = "LowerLid"
    lowerLid.Size = UDim2.new(1,0,0.6,0)
    lowerLid.Position = UDim2.new(0,0,0.45,0) -- closed: sits on bottom half
    lowerLid.BackgroundColor3 = Color3.fromRGB(25,20,45)
    lowerLid.BorderSizePixel=0; lowerLid.ZIndex=4; lowerLid.Parent=eyeCon
    Instance.new("UICorner", lowerLid).CornerRadius = UDim.new(0.35,0)

    return part, { upperLid=upperLid, lowerLid=lowerLid, pupil=pupil, iris=iris, eyeW=eyeW }
end

-- Animate eyelid open/close
local function animateLids(eyeParts, opening)
    if opening then
        -- Open: lids slide away from center
        TweenService:Create(eyeParts.upperLid, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Position=UDim2.new(0,0,-0.7,0)}):Play()
        TweenService:Create(eyeParts.lowerLid, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Position=UDim2.new(0,0,1.1,0)}):Play()
    else
        -- Close: lids meet at center
        TweenService:Create(eyeParts.upperLid, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Position=UDim2.new(0,0,-0.05,0)}):Play()
        TweenService:Create(eyeParts.lowerLid, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Position=UDim2.new(0,0,0.45,0)}):Play()
    end
end

-- Full saint event: appear (3s) → open (5s) → close → vanish
local function runSaintEvent()
    if saintActive or not gameActive then return end
    saintActive = true

    local part, eyeParts = buildSaintEntity()
    saintPart = part

    -- Make player invisible
    local function setCharVis(vis)
        local c = player.Character
        if not c then return end
        for _, obj in ipairs(c:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Decal") then
                obj.LocalTransparencyModifier = vis and 0 or 1
            end
        end
    end
    setCharVis(false) -- hide

    -- Pupil breathing animation (runs while open)
    local breathConn = nil

    -- ── Phase 1: appear with closed eye (3s) ──────────────
    task.wait(3)
    if not gameActive then
        if part and part.Parent then part:Destroy() end
        setCharVis(true)
        saintPart=nil; saintActive=false; return
    end

    -- ── Phase 2: open eye → force gaze (5s) ───────────────
    animateLids(eyeParts, true)
    setVigAlpha(0)
    task.wait(0.6) -- wait for open animation

    -- Camera gaze force setup
    local cam = workspace.CurrentCamera
    local origCamType = cam.CameraType
    cam.CameraType = Enum.CameraType.Scriptable

    -- Init yaw/pitch from current camera
    local cf0 = cam.CFrame
    local camYaw   = math.atan2(-cf0.LookVector.X, -cf0.LookVector.Z)
    local camPitch = math.asin(math.clamp(cf0.LookVector.Y, -1, 1))

    local PULL        = 0.028  -- lerp strength per frame
    local SENSITIVITY = 0.0028 -- mouse resistance sensitivity
    local gazeTime    = 0      -- accumulated time fully looking (for death)
    local vigAlpha    = 0

    -- Pupil animate while open
    local pAng = 0
    breathConn = RunService.Heartbeat:Connect(function(dt)
        pAng += dt * 2
        if eyeParts.iris and eyeParts.iris.Parent then
            local s = 62 + math.sin(pAng)*6
            eyeParts.iris.Size = UDim2.new(0,s,0,s)
            eyeParts.iris.Position = UDim2.new(0.5,-s/2,0.5,-s/2)
        end
    end)

    local eventStart = tick()
    local EVENT_DURATION = 5

    if saintEventConn then saintEventConn:Disconnect(); saintEventConn=nil end
    saintEventConn = RunService.Heartbeat:Connect(function(dt)
        if not gameActive then
            saintEventConn:Disconnect(); saintEventConn=nil; return
        end

        local elapsed = tick() - eventStart
        if elapsed >= EVENT_DURATION then
            -- Time's up, close eye
            saintEventConn:Disconnect(); saintEventConn=nil

            pcall(function() breathConn:Disconnect() end)
            animateLids(eyeParts, false)

            -- Restore camera
            cam.CameraType = origCamType
            setCharVis(true)

            -- Fade vignette out
            local fadeT = 0
            local fadeConn = RunService.Heartbeat:Connect(function(fd)
                fadeT += fd
                local a = math.max(0, vigAlpha * (1 - fadeT/0.5))
                setVigAlpha(a)
                if fadeT >= 0.5 then
                    setVigAlpha(0)
                    -- disconnect handled externally
                end
            end)
            task.delay(0.5, function()
                pcall(function() fadeConn:Disconnect() end)
                setVigAlpha(0)
            end)

            task.delay(0.6, function()
                if part and part.Parent then
                    -- Fade out billboard
                    task.delay(0.1, function()
                        if part and part.Parent then part:Destroy() end
                        saintPart=nil; saintActive=false
                    end)
                else
                    saintPart=nil; saintActive=false
                end
            end)
            return
        end

        local hrp = getHRP()
        if not hrp then return end
        local headPos = hrp.Position + Vector3.new(0, 2, 0)
        local saintPos = part.Position

        -- Player mouse resistance
        local delta = UIS:GetMouseDelta()
        camYaw   = camYaw   - delta.X * SENSITIVITY
        camPitch = math.clamp(camPitch - delta.Y * SENSITIVITY, -1.4, 1.4)

        -- Direction to saint
        local toSaint = (saintPos - headPos)
        if toSaint.Magnitude < 0.1 then return end
        toSaint = toSaint.Unit
        local targetYaw   = math.atan2(-toSaint.X, -toSaint.Z)
        local targetPitch = math.asin(math.clamp(toSaint.Y, -1, 1))

        -- Shortest yaw delta (angle wrap)
        local dy = ((targetYaw - camYaw + math.pi) % (2*math.pi)) - math.pi
        local dp = targetPitch - camPitch

        -- Apply pull
        camYaw   = camYaw   + dy * PULL
        camPitch = camPitch + dp * PULL

        -- Update camera
        cam.CFrame = CFrame.new(headPos)
            * CFrame.Angles(0, camYaw, 0)
            * CFrame.Angles(camPitch, 0, 0)

        -- Gaze detection: dot product of look vector vs direction to saint
        local lookVec  = cam.CFrame.LookVector
        local dot      = lookVec:Dot(toSaint)  -- 1 = fully looking, -1 = fully away

        -- Vignette intensity: higher when more forced
        local progress = elapsed / EVENT_DURATION
        vigAlpha = math.clamp(0.3 + progress * 0.5, 0, 0.85)
        setVigAlpha(vigAlpha)

        -- Health effects
        local hum = getHumanoid()
        if hum and hum.Health > 0 then
            if dot > 0.82 then
                -- Looking at saint → drain health
                entityDamage(hum, 8 * dt)
                gazeTime += dt
                if gazeTime >= 2.2 then
                    -- Fully captured → die
                    hum.Health = 0
                end
            elseif dot < 0.3 then
                -- Looking away → heal
                gazeTime = math.max(0, gazeTime - dt * 0.5)
                hum.Health = math.min(hum.MaxHealth, hum.Health + 5 * dt)
            else
                -- Neutral zone
                gazeTime = math.max(0, gazeTime - dt * 0.2)
            end
        end
    end)
end


-- ── Unlively ───────────────────────────────────────────────
local unlivelActive = false
local unlivelLoop   = nil

local function runUnlivelEvent()
    if unlivelActive or not gameActive then return end
    unlivelActive = true

    -- ScreenGui holding the tree
    local tGui = Instance.new("ScreenGui")
    tGui.Name="UnlivelGui"; tGui.ResetOnSpawn=false
    tGui.IgnoreGuiInset=true; tGui.Parent=player.PlayerGui

    -- Root frame: bottom-center
    local root=Instance.new("Frame")
    root.Size=UDim2.new(0,280,0,380)
    root.Position=UDim2.new(0.5,-140,1,-420)
    root.BackgroundTransparency=1; root.BorderSizePixel=0; root.Parent=tGui

    -- Trunk
    local trunk=Instance.new("Frame")
    trunk.Size=UDim2.new(0,28,0,180)
    trunk.Position=UDim2.new(0.5,-14,0.5,40)
    trunk.BackgroundColor3=Color3.fromRGB(80,50,30)
    trunk.BorderSizePixel=0; trunk.Parent=root
    Instance.new("UICorner",trunk).CornerRadius=UDim.new(0.1,0)

    -- Branch helper
    local function makeBranch(px,py,w,h,rot,color)
        local b=Instance.new("Frame"); b.Size=UDim2.new(0,w,0,h)
        b.Position=UDim2.new(0,px,0,py); b.Rotation=rot
        b.BackgroundColor3=color or Color3.fromRGB(80,50,30)
        b.BorderSizePixel=0; b.Parent=root
        Instance.new("UICorner",b).CornerRadius=UDim.new(0.1,0)
        return b
    end

    -- Branches
    local branches={
        makeBranch(60,170,90,16,-30),
        makeBranch(120,130,80,14,25),
        makeBranch(50,140,70,12,45),
        makeBranch(140,160,60,12,-45),
        makeBranch(70,195,100,14,-15),
        makeBranch(105,115,60,12,55),
    }

    -- Foliage blobs (will wither progressively)
    local foliageColor=Color3.fromRGB(60,130,50)
    local foliage={}
    local foliagePositions={
        {30,60,80,70},{110,40,90,80},{160,70,70,65},
        {45,100,75,60},{130,90,80,70},{80,30,70,65},
    }
    for _,fp in ipairs(foliagePositions) do
        local blob=Instance.new("Frame"); blob.Size=UDim2.new(0,fp[3],0,fp[4])
        blob.Position=UDim2.new(0,fp[1],0,fp[2])
        blob.BackgroundColor3=foliageColor
        blob.BorderSizePixel=0; blob.Parent=root
        Instance.new("UICorner",blob).CornerRadius=UDim.new(1,0)
        table.insert(foliage,blob)
    end

    -- Progress bar (time left)




    local TIMER=5; local elapsed=0; local parryCount=0
    local parryDebounce=false; local finished=false

    -- Wither stages: affects foliage color + size per parry
    local witherColors={
        Color3.fromRGB(50,110,40),  -- parry 1
        Color3.fromRGB(90,85,30),   -- parry 2
        Color3.fromRGB(110,70,20),  -- parry 3
        Color3.fromRGB(130,40,10),  -- parry 4
    }
    local witherScales={0.85, 0.70, 0.55, 0.35}

    local function applyWither(n)
        local col = n<=4 and witherColors[n] or Color3.fromRGB(80,50,30)
        local scale = n<=4 and witherScales[n] or 0.2
        for _, blob in ipairs(foliage) do
            TweenService:Create(blob, TweenInfo.new(0.3), {
                BackgroundColor3 = col,
                Size = UDim2.new(0, blob.Size.X.Offset*scale, 0, blob.Size.Y.Offset*scale)
            }):Play()
        end
        -- Darken branches on high withers
        if n>=3 then
            for _, br in ipairs(branches) do
                TweenService:Create(br, TweenInfo.new(0.3), {
                    BackgroundColor3 = Color3.fromRGB(50,30,15)
                }):Play()
            end
        end
        TweenService:Create(trunk, TweenInfo.new(0.25), {
            BackgroundColor3 = Color3.fromRGB(math.max(30,80-n*10), math.max(15,50-n*8), math.max(5,30-n*5))
        }):Play()
    end

    local function killTree()
        -- Ash woosh: shrink + fade + scatter upward
        for _, blob in ipairs(foliage) do
            if blob.Parent then
                TweenService:Create(blob,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                    {BackgroundTransparency=1, Size=UDim2.new(0,4,0,4)}):Play()
            end
        end
        TweenService:Create(trunk,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play()
        for _,br in ipairs(branches) do
            TweenService:Create(br,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
        end
        -- Slide root upward
        TweenService:Create(root,TweenInfo.new(0.6,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
            {Position=UDim2.new(0.5,-140,0,-400)}):Play()
        task.delay(0.7,function()
            if tGui and tGui.Parent then tGui:Destroy() end
            unlivelActive=false
        end)
    end

    local function explodeKill()
        -- Red flash screen + death
        local flash=Instance.new("Frame"); flash.Size=UDim2.new(1,0,1,0)
        flash.BackgroundColor3=Color3.fromRGB(220,30,10); flash.BackgroundTransparency=0
        flash.BorderSizePixel=0; flash.Parent=tGui
        TweenService:Create(flash,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
        local hum=getHumanoid(); if hum then hum.Health=0 end
        task.delay(0.5,function()
            if tGui and tGui.Parent then tGui:Destroy() end
            unlivelActive=false
        end)
    end

    -- Parry listener: player must press parry button 5 times
    local parryHeld=false
    -- Watch isParrying transitions (edge detection)
    local prevParry=false
    local parryWatchConn=RunService.Heartbeat:Connect(function(dt)
        if finished then return end

        -- edge detect parry press
        if isParrying and not prevParry then
            if not parryDebounce then
                parryDebounce=true
                parryCount+=1
                if parryCount<5 then
                    applyWither(parryCount)
                else
                    -- Final wither then ash
                    applyWither(4)
                    task.wait(0.25)
                    finished=true
                    killTree()
                end
                task.delay(0.25,function() parryDebounce=false end)
            end
        end
        prevParry=isParrying

        -- Timer
        if not finished then
            elapsed+=dt
            -- Slowly turn red
            local t=math.min(elapsed/TIMER,1)
            local rc=math.floor(60+t*160); local gc=math.floor(200-t*170); local bc=math.floor(80-t*70)
            for _,blob in ipairs(foliage) do
                blob.BackgroundColor3=Color3.fromRGB(rc,math.max(0,gc),math.max(0,bc))
            end

            if elapsed>=TIMER then
                finished=true
                explodeKill()
            end
        end
    end)

    -- Cleanup if game ends
    task.spawn(function()
        while not finished and unlivelActive do task.wait(0.5) end
        pcall(function() parryWatchConn:Disconnect() end)
    end)
end

local function startUnlivelLoop()
    if unlivelLoop then unlivelLoop:Disconnect(); unlivelLoop=nil end
    local el=0
    unlivelLoop=RunService.Heartbeat:Connect(function(dt)
        if not gameActive then return end
        if unlivelActive then return end
        el+=dt; if el<20 then return end; el=0
        if math.random()>0.25 then return end
        runUnlivelEvent()
    end)
end

local function startSaintLoop()
    if saintLoop then saintLoop:Disconnect(); saintLoop=nil end
    local el=0
    saintLoop=RunService.Heartbeat:Connect(function(dt)
        if not gameActive then return end
        if saintActive then return end
        el+=dt; if el<20 then return end; el=0
        if math.random()>0.30 then return end
        runSaintEvent()
    end)
end


-- ── Despair ────────────────────────────────────────────────
local despairLoop    = nil
local despairActive  = false
local despairPuddles = {}   -- permanent puddle parts + conns

-- Puddles persist across events; track who's inside for slow
local puddleSlowConn = nil

local function startPuddleSlowLoop()
    if puddleSlowConn then return end
    puddleSlowConn = RunService.Heartbeat:Connect(function()
        if not gameActive then return end
        local hrp = getHRP(); if not hrp then return end
        local hum = getHumanoid(); if not hum then return end
        local inPuddle = false
        for _, pd in ipairs(despairPuddles) do
            if pd and pd.Parent then
                local diff = (hrp.Position - pd.Position)
                diff = Vector3.new(diff.X, 0, diff.Z)
                if diff.Magnitude < pd.Size.X * 0.5 then
                    inPuddle = true; break
                end
            end
        end
        if inPuddle then
            hum.WalkSpeed = math.max(4, hum.WalkSpeed - 0.5)
        else
            hum.WalkSpeed = math.min(16, hum.WalkSpeed + 2)
        end
    end)
end

local function spawnPuddle(pos)
    local pd = Instance.new("Part")
    pd.Name = "DespairPuddle"
    pd.Size = Vector3.new(12, 0.3, 12)
    pd.Position = Vector3.new(pos.X, pos.Y - 2.5, pos.Z)
    pd.Anchored = true; pd.CanCollide = false
    pd.Material = Enum.Material.Neon
    pd.Color = Color3.fromRGB(80, 80, 90)
    pd.Transparency = 0.35; pd.CastShadow = false
    pd.Parent = workspace
    -- Ripple pulse
    local ra = RunService.Heartbeat:Connect(function()
        if pd and pd.Parent then
            pd.Transparency = 0.3 + 0.15 * math.abs(math.sin(tick() * 1.8))
        end
    end)
    table.insert(animConns, ra)
    table.insert(despairPuddles, pd)
    -- Damage tick every 1 second
    task.spawn(function()
        while pd and pd.Parent and gameActive do
            task.wait(1)
            local hrp = getHRP(); if not hrp then continue end
            local diff = (hrp.Position - pd.Position)
            diff = Vector3.new(diff.X, 0, diff.Z)
            if diff.Magnitude < pd.Size.X * 0.5 then
                local hum = getHumanoid()
                if hum and hum.Health > 0 then
                    hum.Health = math.max(0.1, hum.Health - 10)
                end
            end
        end
    end)
end

local function runDespairEvent()
    if despairActive or not gameActive then return end
    despairActive = true

    -- ── Rain GUI ──
    local rainGui = Instance.new("ScreenGui")
    rainGui.Name = "DespairRain"; rainGui.ResetOnSpawn = false
    rainGui.IgnoreGuiInset = true; rainGui.Parent = player.PlayerGui

    -- Gray fog overlay
    local fog = Instance.new("Frame")
    fog.Size = UDim2.new(1,0,1,0); fog.BackgroundColor3 = Color3.fromRGB(130,130,140)
    fog.BackgroundTransparency = 1; fog.BorderSizePixel = 0; fog.Parent = rainGui

    -- Lighting fog
    local atmosphere = Instance.new("ColorCorrectionEffect")
    atmosphere.Saturation = 0; atmosphere.Contrast = -0.3; atmosphere.Brightness = -0.15
    atmosphere.Parent = game:GetService("Lighting")

    -- Fade fog in over 2s
    TweenService:Create(fog, TweenInfo.new(2), {BackgroundTransparency = 0.62}):Play()

    -- Spawn rain drops
    local rainDrops = {}
    local RAINDROP_COUNT = 55
    for i = 1, RAINDROP_COUNT do
        local drop = Instance.new("Frame")
        drop.Size = UDim2.new(0, math.random(1,2), 0, math.random(18,38))
        drop.Position = UDim2.new(math.random()/1, 0, math.random()/1 - 0.1, 0)
        drop.BackgroundColor3 = Color3.fromRGB(140,150,180)
        drop.BackgroundTransparency = math.random()*0.4 + 0.3
        drop.BorderSizePixel = 0; drop.Rotation = 12; drop.Parent = rainGui
        table.insert(rainDrops, {frame=drop, speed=math.random(60,120)/100})
    end

    -- Animate rain drops
    local rainConn = RunService.Heartbeat:Connect(function(dt)
        for _, rd in ipairs(rainDrops) do
            if rd.frame and rd.frame.Parent then
                local py = rd.frame.Position.Y.Scale + rd.speed * dt * 0.7
                if py > 1.05 then py = -0.05 end
                rd.frame.Position = UDim2.new(rd.frame.Position.X.Scale, 0, py, 0)
            end
        end
    end)

    -- ── Phase 1: rain appears for 3s ──
    task.wait(3)
    if not gameActive then
        pcall(function() rainConn:Disconnect() end)
        if atmosphere and atmosphere.Parent then atmosphere:Destroy() end
        if rainGui and rainGui.Parent then rainGui:Destroy() end
        despairActive = false; return
    end

    -- ── Phase 2: screen shake + must hold parry for 5s ──
    local cam = workspace.CurrentCamera
    local shakeConn = nil
    local shakeMag = 0

    shakeConn = RunService.Heartbeat:Connect(function(dt)
        shakeMag = math.min(shakeMag + dt * 3, 1)
        local ox = (math.random() - 0.5) * 0.55 * shakeMag
        local oy = (math.random() - 0.5) * 0.35 * shakeMag
        cam.CFrame = cam.CFrame * CFrame.new(ox, oy, 0)
    end)

    local holdTime = 0
    local survived = false
    local HOLD_NEEDED = 5

    local holdConn = RunService.Heartbeat:Connect(function(dt)
        if not gameActive then return end
        if isParrying then
            holdTime += dt
            if holdTime >= HOLD_NEEDED then
                survived = true
            end
        else
            holdTime = math.max(0, holdTime - dt * 0.4)
        end
    end)

    -- Wait up to 5 + buffer seconds
    local elapsed = 0
    local waitConn
    waitConn = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if survived or elapsed >= HOLD_NEEDED + 2 then
            waitConn:Disconnect()
        end
    end)
    while not survived and elapsed < HOLD_NEEDED + 2 and gameActive do
        task.wait(0.1)
    end
    pcall(function() holdConn:Disconnect() end)
    pcall(function() waitConn:Disconnect() end)
    pcall(function() shakeConn:Disconnect() end)

    if not gameActive then
        if atmosphere and atmosphere.Parent then atmosphere:Destroy() end
        if rainGui and rainGui.Parent then rainGui:Destroy() end
        pcall(function() rainConn:Disconnect() end)
        despairActive = false; return
    end

    -- ── Phase 3a: survived → fade out rain, leave puddle ──
    if survived then
        TweenService:Create(fog, TweenInfo.new(1.5), {BackgroundTransparency = 1}):Play()
        task.delay(1.5, function()
            if atmosphere and atmosphere.Parent then atmosphere:Destroy() end
            if rainGui and rainGui.Parent then rainGui:Destroy() end
        end)
        pcall(function() rainConn:Disconnect() end)

        -- Spawn grey puddle at player feet
        local hrp = getHRP()
        if hrp then
            spawnPuddle(hrp.Position)
            startPuddleSlowLoop()
        end
        despairActive = false
        return
    end

    -- ── Phase 3b: not survived → grey ghost + float + die ──
    pcall(function() rainConn:Disconnect() end)
    TweenService:Create(fog, TweenInfo.new(0.5), {BackgroundTransparency = 0.4}):Play()

    -- Turn character grey neon
    local char = player.Character
    if char then
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.Neon
                obj.Color    = Color3.fromRGB(120, 120, 130)
                obj.Transparency = 0.3
            end
        end
        -- Disable humanoid physics so they float
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = true
            -- Float upward slowly
            TweenService:Create(hrp, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                CFrame = hrp.CFrame + Vector3.new(0, 80, 0)
            }):Play()
        end
    end

    task.wait(3)

    -- Kill
    local hum = getHumanoid()
    if hum then hum.Health = 0 end

    -- Cleanup (CharacterAdded will handle the rest)
    task.delay(0.5, function()
        if atmosphere and atmosphere.Parent then atmosphere:Destroy() end
        if rainGui and rainGui.Parent then rainGui:Destroy() end
        despairActive = false
    end)
end

local function startDespairLoop()
    if despairLoop then despairLoop:Disconnect(); despairLoop=nil end
    -- Random interval between 25 and 60 seconds
    local function scheduleNext()
        local interval = math.random(25, 60)
        local el = 0
        despairLoop = RunService.Heartbeat:Connect(function(dt)
            if not gameActive then return end
            el += dt
            if el < interval then return end
            despairLoop:Disconnect(); despairLoop = nil
            if math.random() <= 0.25 then
                runDespairEvent()
            end
            if gameActive then scheduleNext() end
        end)
    end
    scheduleNext()
end


-- ── Ecneulfni ──────────────────────────────────────────────
local ecneulfniLoop   = nil
local ecneulfniActive = false

local function runEcneulfniEvent()
    if ecneulfniActive or not gameActive then return end
    ecneulfniActive = true

    -- Decide eye count (0-5) and whether the single-eye blood variant triggers
    local eyeCount   = math.random(0, 5)
    local bloodEye   = (eyeCount == 1) and (math.random() < 0.45)  -- ~45% chance if 1 eye
    local jumpTarget = bloodEye and 0 or eyeCount   -- 0-jump if blood eye

    -- ── Face GUI ──
    local fGui = Instance.new("ScreenGui")
    fGui.Name = "EcneulfniGui"; fGui.ResetOnSpawn = false
    fGui.IgnoreGuiInset = true; fGui.Parent = player.PlayerGui

    -- Face container: center screen
    local face = Instance.new("Frame")
    face.Size = UDim2.new(0, 280, 0, 280)
    face.Position = UDim2.new(0.5, -140, 0.5, -160)
    face.BackgroundColor3 = Color3.fromRGB(30, 22, 22)
    face.BorderSizePixel = 0; face.Parent = fGui
    Instance.new("UICorner", face).CornerRadius = UDim.new(0.15, 0)

    -- Dark outer glow
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 0, 0); stroke.Thickness = 5; stroke.Parent = face



    -- Timer bar
    local timerBG = Instance.new("Frame")
    timerBG.Size = UDim2.new(0, 280, 0, 8)
    timerBG.Position = UDim2.new(0.5, -140, 0.5, 135)
    timerBG.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
    timerBG.BorderSizePixel = 0; timerBG.Parent = fGui
    Instance.new("UICorner", timerBG).CornerRadius = UDim.new(0.5, 0)

    local timerFill = Instance.new("Frame")
    timerFill.Size = UDim2.new(1, 0, 1, 0)
    timerFill.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    timerFill.BorderSizePixel = 0; timerFill.Parent = timerBG
    Instance.new("UICorner", timerFill).CornerRadius = UDim.new(0.5, 0)

    -- Eye builder
    local function makeEye(px, py, sz, isBlood)
        local eyeFrame = Instance.new("Frame")
        eyeFrame.Size = UDim2.new(0, sz, 0, sz * 0.55)
        eyeFrame.Position = UDim2.new(0, px - sz/2, 0, py - sz*0.27)
        eyeFrame.BackgroundColor3 = Color3.fromRGB(230, 220, 215)
        eyeFrame.BorderSizePixel = 0; eyeFrame.ClipsDescendants = true
        eyeFrame.Parent = face
        Instance.new("UICorner", eyeFrame).CornerRadius = UDim.new(0.5, 0)

        -- Closed lid (starts covering entire eye)
        local lid = Instance.new("Frame")
        lid.Size = UDim2.new(1, 0, 1.2, 0)
        lid.Position = UDim2.new(0, 0, -0.1, 0)
        lid.BackgroundColor3 = Color3.fromRGB(30, 22, 22)
        lid.BorderSizePixel = 0; lid.ZIndex = 4; lid.Parent = eyeFrame
        Instance.new("UICorner", lid).CornerRadius = UDim.new(0.3, 0)

        if isBlood then
            -- Blood iris (red, no pupil)
            local iris = Instance.new("Frame")
            iris.Size = UDim2.new(0, sz*0.55, 0, sz*0.55)
            iris.Position = UDim2.new(0.5, -sz*0.275, 0.5, -sz*0.275)
            iris.BackgroundColor3 = Color3.fromRGB(160, 5, 5)
            iris.BorderSizePixel = 0; iris.ZIndex = 2; iris.Parent = eyeFrame
            Instance.new("UICorner", iris).CornerRadius = UDim.new(1, 0)
            -- Blood drip
            local drip = Instance.new("Frame")
            drip.Size = UDim2.new(0, 6, 0, sz * 0.7)
            drip.Position = UDim2.new(0.5, -3, 0.6, 0)
            drip.BackgroundColor3 = Color3.fromRGB(180, 5, 5)
            drip.BorderSizePixel = 0; drip.ZIndex = 3; drip.Parent = eyeFrame
            Instance.new("UICorner", drip).CornerRadius = UDim.new(0.5, 0)
        else
            -- Normal iris
            local irisColor = BrickColor.Random().Color
            local iris = Instance.new("Frame")
            iris.Size = UDim2.new(0, sz*0.52, 0, sz*0.52)
            iris.Position = UDim2.new(0.5, -sz*0.26, 0.5, -sz*0.26)
            iris.BackgroundColor3 = irisColor
            iris.BorderSizePixel = 0; iris.ZIndex = 2; iris.Parent = eyeFrame
            Instance.new("UICorner", iris).CornerRadius = UDim.new(1, 0)
            -- Pupil
            local pupil = Instance.new("Frame")
            pupil.Size = UDim2.new(0, sz*0.28, 0, sz*0.28)
            pupil.Position = UDim2.new(0.5, -sz*0.14, 0.5, -sz*0.14)
            pupil.BackgroundColor3 = Color3.fromRGB(8, 5, 5)
            pupil.BorderSizePixel = 0; pupil.ZIndex = 3; pupil.Parent = eyeFrame
            Instance.new("UICorner", pupil).CornerRadius = UDim.new(1, 0)
            -- Glint
            local glint = Instance.new("Frame")
            glint.Size = UDim2.new(0, sz*0.1, 0, sz*0.1)
            glint.Position = UDim2.new(0.62, 0, 0.12, 0)
            glint.BackgroundColor3 = Color3.new(1, 1, 1)
            glint.BorderSizePixel = 0; glint.ZIndex = 4; glint.Parent = eyeFrame
            Instance.new("UICorner", glint).CornerRadius = UDim.new(1, 0)
        end
        return lid
    end

    -- Place eyes on the face (distribute evenly)
    local lids = {}
    if eyeCount == 0 then
        -- No eyes: blank face, just show the face with a "…" or empty
        local emptyLbl = Instance.new("TextLabel")
        emptyLbl.Size = UDim2.new(1, 0, 0.5, 0); emptyLbl.Position = UDim2.new(0, 0, 0.25, 0)
        emptyLbl.BackgroundTransparency = 1; emptyLbl.Text = "—"
        emptyLbl.TextColor3 = Color3.fromRGB(180, 160, 160)
        emptyLbl.Font = Enum.Font.GothamBold; emptyLbl.TextScaled = true; emptyLbl.Parent = face
    else
        -- Grid layout: up to 3 per row
        local cols = math.min(eyeCount, 3)
        local rows = math.ceil(eyeCount / cols)
        local eyeSz = math.min(70, math.floor(220 / cols))
        local padX = math.floor(280 / (cols + 1))
        local padY = math.floor(280 / (rows + 1))
        local placed = 0
        for row = 1, rows do
            local rowCount = math.min(cols, eyeCount - placed)
            for col = 1, rowCount do
                local px = math.floor(280 / (rowCount + 1)) * col
                local py = padY * row
                local isBlood = bloodEye and (placed == 0)
                table.insert(lids, makeEye(px, py, eyeSz, isBlood))
                placed += 1
            end
        end
    end

    -- ── Phase 1: face appears, eyes closed (3s) ──
    task.wait(3)
    if not gameActive then
        if fGui and fGui.Parent then fGui:Destroy() end
        ecneulfniActive = false; return
    end

    -- Red flash
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1,0,1,0); flash.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    flash.BackgroundTransparency = 0.3; flash.BorderSizePixel = 0; flash.Parent = fGui
    TweenService:Create(flash, TweenInfo.new(0.08), {BackgroundTransparency = 1}):Play()
    task.delay(0.12, function() if flash and flash.Parent then flash:Destroy() end end)

    task.wait(1) -- 1s after flash, eyes open

    -- Open all lids
    for _, lid in ipairs(lids) do
        TweenService:Create(lid, TweenInfo.new(0.35, Enum.EasingStyle.Back), {
            Position = UDim2.new(0, 0, -1.3, 0)
        }):Play()
    end

    -- Show jump requirement
    if jumpTarget == 0 then
    else
    end

    -- ── Phase 2: player must jump N times in 5s ──
    local jumpsDone = 0
    local success   = false
    local WINDOW    = 5

    local hrp = getHRP()
    local lastGrounded = true
    local jumpConn = nil
    local elapsed = 0

    if jumpTarget > 0 then
        jumpConn = RunService.Heartbeat:Connect(function(dt)
            elapsed += dt
            local h2 = getHRP(); if not h2 then return end
            local hum = getHumanoid(); if not hum then return end
            -- Detect jump (left ground)
            local grounded = (hum.FloorMaterial ~= Enum.Material.Air)
            if lastGrounded and not grounded then
                jumpsDone += 1
                if jumpsDone >= jumpTarget then success = true end
            end
            lastGrounded = grounded
            timerFill.Size = UDim2.new(math.max(0, 1 - elapsed/WINDOW), 0, 1, 0)
        end)
    else
        -- 0 jumps: player must NOT jump
        jumpConn = RunService.Heartbeat:Connect(function(dt)
            elapsed += dt
            local hum = getHumanoid(); if not hum then return end
            local grounded = (hum.FloorMaterial ~= Enum.Material.Air)
            if lastGrounded and not grounded then
                -- jumped when they shouldn't have
                success = false
                elapsed = WINDOW + 1
            end
            lastGrounded = grounded
            timerFill.Size = UDim2.new(math.max(0, 1 - elapsed/WINDOW), 0, 1, 0)
        end)
        success = true  -- will be set false if they jump
    end

    -- Wait for window
    while elapsed < WINDOW and not success and gameActive do
        task.wait(0.05)
    end
    -- For 0-jump: need to also wait the full window without jumping
    if jumpTarget == 0 then
        while elapsed < WINDOW and gameActive do
            task.wait(0.05)
        end
    end
    pcall(function() if jumpConn then jumpConn:Disconnect() end end)

    if not gameActive then
        if fGui and fGui.Parent then fGui:Destroy() end
        ecneulfniActive = false; return
    end

    -- Close lids
    for _, lid in ipairs(lids) do
        TweenService:Create(lid, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0, 0, -0.1, 0)
        }):Play()
    end

    if (jumpTarget == 0 and success) or (jumpTarget > 0 and jumpsDone >= jumpTarget) then
        -- ✓ Correct: dismiss face
        TweenService:Create(face, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -140, -0.5, 0)
        }):Play()
        task.delay(0.6, function()
            if fGui and fGui.Parent then fGui:Destroy() end
            ecneulfniActive = false
        end)
    else
        -- ✗ Wrong: head chop

        local chop = Instance.new("Frame")
        chop.Size = UDim2.new(1,0,1,0); chop.BackgroundColor3 = Color3.new(0,0,0)
        chop.BackgroundTransparency = 0; chop.BorderSizePixel = 0; chop.Parent = fGui
        -- Red slash
        local slash = Instance.new("Frame")
        slash.Size = UDim2.new(1.5, 0, 0, 8); slash.Position = UDim2.new(-0.25, 0, 0.48, 0)
        slash.Rotation = -12; slash.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
        slash.BorderSizePixel = 0; slash.Parent = chop

        task.wait(0.25)
        local char = player.Character
        if char then
            -- Detach head visually
            local head = char:FindFirstChild("Head")
            if head then
                head.Anchored = false
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(math.random(-15,15), 25, math.random(-15,15))
                bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Parent = head
                game:GetService("Debris"):AddItem(bv, 0.3)
            end
            local hum = getHumanoid(); if hum then hum.Health = 0 end
        end
        task.delay(0.5, function()
            if fGui and fGui.Parent then fGui:Destroy() end
            ecneulfniActive = false
        end)
    end
end

local function startEcneulfniLoop()
    if ecneulfniLoop then ecneulfniLoop:Disconnect(); ecneulfniLoop=nil end
    local el = 0
    ecneulfniLoop = RunService.Heartbeat:Connect(function(dt)
        if not gameActive then return end
        if ecneulfniActive then return end
        el += dt; if el < 15 then return end; el = 0
        if math.random() > 0.23 then return end
        runEcneulfniEvent()
    end)
end


-- ── Vortex ─────────────────────────────────────────────────
local vortexActive = false
local vortexLoop   = nil

local function runVortexEvent()
    if vortexActive or not gameActive then return end
    vortexActive = true

    -- Pause all entity spawning
    local wasDasher   = dasherActive;    dasherActive   = true   -- prevent new dashes
    local wasSaint    = saintActive;     saintActive    = true
    local wasUnlivel  = unlivelActive;   unlivelActive  = true
    local wasDespair  = despairActive;   despairActive  = true
    local wasEcn      = ecneulfniActive; ecneulfniActive= true
    local wasPin      = pinpointChasing; pinpointChasing= false
    if pinpointHBConn then pinpointHBConn:Disconnect(); pinpointHBConn=nil end

    -- ── Build vortex visual at sky-centre ──
    local mazeCX = MAZE_ORIGIN.X + (gridW * CELL_SIZE) / 2
    local mazeCZ = MAZE_ORIGIN.Z + (gridH * CELL_SIZE) / 2
    local vortexCentre = Vector3.new(mazeCX, 85, mazeCZ)

    local vGui = Instance.new("ScreenGui")
    vGui.Name = "VortexGui"; vGui.ResetOnSpawn = false
    vGui.IgnoreGuiInset = true; vGui.Parent = player.PlayerGui

    -- Spinning ring overlay (pure 2D vortex spiral)
    local spinRoot = Instance.new("Frame")
    spinRoot.Size = UDim2.new(0,320,0,320)
    spinRoot.Position = UDim2.new(0.5,-160,0.5,-160)
    spinRoot.BackgroundTransparency = 1; spinRoot.BorderSizePixel = 0
    spinRoot.Parent = vGui

    -- Ring layers
    local rings = {}
    local ringColors = {
        Color3.fromRGB(80,40,180), Color3.fromRGB(120,60,220),
        Color3.fromRGB(60,20,140), Color3.fromRGB(160,80,255),
    }
    for i=1,8 do
        local r = Instance.new("Frame")
        local sz = 320 - (i-1)*30
        r.Size = UDim2.new(0,sz,0,sz)
        r.Position = UDim2.new(0.5,-sz/2,0.5,-sz/2)
        r.BackgroundTransparency = 1; r.BorderSizePixel = 0; r.Parent = spinRoot
        local stroke = Instance.new("UIStroke")
        stroke.Color = ringColors[(i-1)%4+1]
        stroke.Thickness = 4 - (i*0.3); stroke.Parent = r
        Instance.new("UICorner", r).CornerRadius = UDim.new(1,0)
        table.insert(rings, {frame=r, speed=(i%2==0 and 1 or -1) * (0.6+i*0.12)})
    end

    -- Vortex centre dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,18,0,18)
    dot.Position = UDim2.new(0.5,-9,0.5,-9)
    dot.BackgroundColor3 = Color3.fromRGB(200,120,255)
    dot.BorderSizePixel=0; dot.Parent=spinRoot
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)

    -- Dark vignette
    local vig = Instance.new("Frame")
    vig.Size = UDim2.new(1,0,1,0); vig.BackgroundColor3 = Color3.new(0,0,0)
    vig.BackgroundTransparency = 0.5; vig.BorderSizePixel=0; vig.Parent=vGui

    -- Spin the rings
    local spinConn = RunService.Heartbeat:Connect(function(dt)
        for _, rd in ipairs(rings) do
            if rd.frame and rd.frame.Parent then
                rd.frame.Rotation = rd.frame.Rotation + rd.speed * dt * 120
            end
        end
        if dot and dot.Parent then
            dot.Rotation = dot.Rotation + dt * 200
        end
    end)

    -- ── Phase 1: form for ~2s ──
    task.wait(2)
    if not gameActive then
        pcall(function() spinConn:Disconnect() end)
        if vGui and vGui.Parent then vGui:Destroy() end
        vortexActive=false; return
    end

    -- ── Phase 2: suck walls + shards (3s) ──
    -- Collect all wall/floor parts + live shard parts
    local suckParts = {}
    if mazeFolder then
        for _, obj in ipairs(mazeFolder:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name ~= "ExitBeam" then
                table.insert(suckParts, obj)
            end
        end
    end
    -- Also collect live shards
    local liveShards = {}
    for _, sd in ipairs(shardList) do
        if sd.part and sd.part.Parent then
            table.insert(suckParts, sd.part)
            table.insert(liveShards, sd)  -- remember which are still alive
        end
    end

    -- Count remaining before suck
    local remainingCount = #liveShards

    -- Animate parts flying toward vortex centre
    for _, p in ipairs(suckParts) do
        if p and p.Parent then
            p.Anchored = false; p.CanCollide = false
            local dist = (p.Position - vortexCentre).Magnitude
            local dur  = math.clamp(dist / 120, 0.5, 3.0)
            TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position  = vortexCentre,
                Size      = Vector3.new(0.1, 0.1, 0.1),
                Transparency = 1,
            }):Play()
        end
    end

    -- Disconnect shard touch connections during suck
    for _, sd in ipairs(liveShards) do
        if sd.conn then sd.conn:Disconnect(); sd.conn=nil end
    end

    task.wait(3)
    if not gameActive then
        pcall(function() spinConn:Disconnect() end)
        if vGui and vGui.Parent then vGui:Destroy() end
        if mazeFolder and mazeFolder.Parent then mazeFolder:Destroy(); mazeFolder=nil end
        vortexActive=false; return
    end

    -- Destroy old maze
    if mazeFolder and mazeFolder.Parent then mazeFolder:Destroy(); mazeFolder=nil end

    -- ── Phase 3: flash + rebuild ──
    pcall(function() spinConn:Disconnect() end)

    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1,0,1,0); flash.BackgroundColor3 = Color3.new(1,1,1)
    flash.BackgroundTransparency = 0; flash.BorderSizePixel = 0; flash.Parent = vGui
    TweenService:Create(flash, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()

    -- Rebuild maze (same W/H/seed free)
    local gW, gH, _ = getRound(currentRound)
    math.randomseed(os.clock() * 99991 + currentRound * 1337)
    local newGrid = generateMaze(gW, gH)
    currentGrid = newGrid; gridW = gW; gridH = gH
    mazeFolder  = buildMazeWorld(newGrid, gW, gH)

    -- Re-place exit cell (same relative position: far corner)
    local newCells = getOpenCells(newGrid, gW, gH)
    shuffle(newCells)
    exitCellPos = cellToWorld(newCells[#newCells][1], newCells[#newCells][2])

    -- Respawn only the shards that were still uncollected
    -- Clear old shard entries and rebuild just the live ones
    for _, sd in ipairs(shardList) do
        if sd.part and sd.part.Parent then sd.part:Destroy() end
    end
    shardList = {}

    shuffle(newCells)
    local respawnCount = math.min(remainingCount, #newCells - 1)
    for i = 1, respawnCount do
        local cell = newCells[i]; if not cell then break end
        local sp2  = spawnShard(cellToWorld(cell[1], cell[2]), mazeFolder)
        local idx  = i
        local sd2  = {part=sp2, conn=nil}
        shardList[idx] = sd2
        sd2.conn = sp2.Touched:Connect(function(hit)
            if hit.Parent == player.Character then onShardTouched(sd2) end
        end)
    end

    -- Rebuild entity parts in new maze
    if currentRound >= 1 and dasherPart then
        dasherPart:Destroy(); dasherPart=nil
        createDasherPart(mazeFolder)
    end
    if currentRound >= 2 and pinpointPart then
        pinpointPart:Destroy(); pinpointPart=nil
        createPinpointPart(mazeFolder)
    end

    task.wait(0.4)
    if vGui and vGui.Parent then vGui:Destroy() end

    -- Restore entity flags
    dasherActive    = false
    saintActive     = false
    unlivelActive   = false
    despairActive   = false
    ecneulfniActive = false
    pinpointSpawned = false
    vortexActive    = false

    refreshHUD("Map rebuilt! " .. #shardList .. " shards remain.", C.gold)
end

local function startVortexLoop()
    if vortexLoop then vortexLoop:Disconnect(); vortexLoop=nil end
    local function schedule()
        local el = 0
        vortexLoop = RunService.Heartbeat:Connect(function(dt)
            if not gameActive then return end
            el += dt; if el < 60 then return end
            vortexLoop:Disconnect(); vortexLoop=nil
            if math.random() <= 0.10 then
                runVortexEvent()
            end
            if gameActive then schedule() end
        end)
    end
    schedule()
end


-- ── Prisoner (Inexplicable modifier) ──────────────────────
local PRISONER_RADIUS = 7

local function buildPrisonerFace(part)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0,90,0,100)
    bb.StudsOffsetWorldSpace = Vector3.new(0,0,0)
    bb.AlwaysOnTop = true; bb.Parent = part

    local face = Instance.new("Frame")
    face.Size=UDim2.new(1,0,1,0); face.BackgroundTransparency=1
    face.BorderSizePixel=0; face.Parent=bb

    -- Head
    local head=Instance.new("Frame"); head.Name="Head"
    head.Size=UDim2.new(0,72,0,80); head.Position=UDim2.new(0.5,-36,0.05,0)
    head.BackgroundColor3=Color3.fromRGB(190,165,140); head.BorderSizePixel=0
    head.Parent=face
    Instance.new("UICorner",head).CornerRadius=UDim.new(0.35,0)
    prisonerHeadFrame=head

    -- Prison stripe (forehead band)
    local band=Instance.new("Frame"); band.Size=UDim2.new(1,0,0,10)
    band.Position=UDim2.new(0,0,0.08,0); band.BackgroundColor3=Color3.fromRGB(40,40,40)
    band.BorderSizePixel=0; band.Parent=head

    -- Eyes
    for _,xoff in ipairs({-14,14}) do
        local eye=Instance.new("Frame"); eye.Size=UDim2.new(0,12,0,14)
        eye.Position=UDim2.new(0.5,xoff-6,0.38,0)
        eye.BackgroundColor3=Color3.fromRGB(20,15,15); eye.BorderSizePixel=0
        eye.Parent=head; Instance.new("UICorner",eye).CornerRadius=UDim.new(1,0)
    end

    -- Mouth (flat nervous)
    local mouth=Instance.new("Frame"); mouth.Size=UDim2.new(0,26,0,4)
    mouth.Position=UDim2.new(0.5,-13,0.7,0)
    mouth.BackgroundColor3=Color3.fromRGB(70,35,35); mouth.BorderSizePixel=0
    mouth.Parent=head; Instance.new("UICorner",mouth).CornerRadius=UDim.new(0.5,0)

    -- Number badge (prisoner number)
    local badge=Instance.new("TextLabel"); badge.Size=UDim2.new(0.85,0,0,18)
    badge.Position=UDim2.new(0.075,0,0.82,0); badge.BackgroundTransparency=1
    badge.Text="847"; badge.TextColor3=Color3.fromRGB(70,70,70)
    badge.Font=Enum.Font.GothamBold; badge.TextScaled=true; badge.Parent=head
end

local function startPrisonerLoop()
    if prisonerHBConn then prisonerHBConn:Disconnect(); prisonerHBConn=nil end
    if prisonerPart then prisonerPart:Destroy(); prisonerPart=nil end
    if prisonerRageGui then prisonerRageGui:Destroy(); prisonerRageGui=nil end

    -- Create part
    local p=Instance.new("Part"); p.Name="Prisoner"; p.Size=Vector3.new(1,1,1)
    p.Anchored=true; p.CanCollide=false; p.Transparency=1; p.CastShadow=false
    p.Parent=workspace; prisonerPart=p
    buildPrisonerFace(p)

    -- Rage bar GUI
    local rGui=Instance.new("ScreenGui"); rGui.Name="RageGui"
    rGui.ResetOnSpawn=false; rGui.Parent=player.PlayerGui
    prisonerRageGui=rGui

    local rBG=Instance.new("Frame"); rBG.Size=UDim2.new(0,200,0,8)
    rBG.Position=UDim2.new(0.5,-100,1,-162); rBG.BackgroundColor3=Color3.fromRGB(25,8,8)
    rBG.BorderSizePixel=0; rBG.Parent=rGui
    Instance.new("UICorner",rBG).CornerRadius=UDim.new(0.5,0)

    local rFill=Instance.new("Frame"); rFill.Name="Fill"; rFill.Size=UDim2.new(0,0,1,0)
    rFill.BackgroundColor3=Color3.fromRGB(200,30,30); rFill.BorderSizePixel=0
    rFill.Parent=rBG; Instance.new("UICorner",rFill).CornerRadius=UDim.new(0.5,0)

    local rLbl=Instance.new("TextLabel"); rLbl.Size=UDim2.new(1,0,0,14)
    rLbl.Position=UDim2.new(0,0,-2.2,0); rLbl.BackgroundTransparency=1
    rLbl.Text="RAGE"; rLbl.TextColor3=Color3.fromRGB(200,50,50)
    rLbl.Font=Enum.Font.GothamBold; rLbl.TextScaled=true; rLbl.Parent=rBG

    -- Reset state
    prisonerAngle=0; prisonerDir=1; prisonerBoosted=false; prisonerBoostT=0
    prisonerRage=0; prisonerHeadless=false; prisonerChasing=false; prisonerChaseSpd=0

    local cam=workspace.CurrentCamera
    local rageTickT=0
    local prevParry=false

    prisonerHBConn=RunService.Heartbeat:Connect(function(dt)
        local hrp=getHRP(); if not hrp then return end

        if not prisonerChasing then
            -- Orbit
            local spd=1.0*(prisonerBoosted and 1.5 or 1.0)
            prisonerAngle+=dt*spd*prisonerDir

            if prisonerBoosted then
                prisonerBoostT-=dt
                if prisonerBoostT<=0 then prisonerBoosted=false end
            end

            local px=hrp.Position.X+math.cos(prisonerAngle)*PRISONER_RADIUS
            local pz=hrp.Position.Z+math.sin(prisonerAngle)*PRISONER_RADIUS
            p.CFrame=CFrame.new(px,hrp.Position.Y+2,pz)*CFrame.Angles(0,-prisonerAngle,0)

            -- Vision check
            local toP=(p.Position-cam.CFrame.Position)
            local inVision=toP.Magnitude>0.1 and cam.CFrame.LookVector:Dot(toP.Unit)>0.5

            if inVision then
                -- Rage tick every 0.1s
                rageTickT+=dt
                if rageTickT>=0.1 then
                    rageTickT=0
                    prisonerRage=math.min(100,prisonerRage+1)
                    rFill.Size=UDim2.new(prisonerRage/100,0,1,0)
                    local rc=math.floor(100+prisonerRage)
                    local gc=math.max(0,math.floor(30-prisonerRage*0.28))
                    rFill.BackgroundColor3=Color3.fromRGB(rc,gc,gc)
                end

                -- Screen shake (only if camera not taken by Saint)
                if prisonerRage>0 and cam.CameraType~=Enum.CameraType.Scriptable then
                    local shk=(prisonerRage/100)*0.22
                    cam.CFrame=cam.CFrame*CFrame.new(
                        (math.random()-0.5)*shk,(math.random()-0.5)*shk*0.6,0)
                end

                -- Parry edge: boost + maybe flip direction
                if isParrying and not prevParry then
                    prisonerBoosted=true; prisonerBoostT=1.0
                    if math.random()<0.5 then prisonerDir=-prisonerDir end
                end
            else
                rageTickT=0
            end
            prevParry=isParrying

            -- Rage hits 100: go headless then chase
            if prisonerRage>=100 and not prisonerHeadless then
                prisonerHeadless=true
                if prisonerHeadFrame and prisonerHeadFrame.Parent then
                    TweenService:Create(prisonerHeadFrame,TweenInfo.new(0.12),{
                        Size=UDim2.new(0,110,0,110),
                        BackgroundTransparency=1
                    }):Play()
                    task.delay(0.15,function()
                        if prisonerHeadFrame then prisonerHeadFrame.Visible=false end
                    end)
                end
                -- Flash red
                local expG=Instance.new("ScreenGui"); expG.Name="RageFlash"
                expG.ResetOnSpawn=false; expG.Parent=player.PlayerGui
                local ef=Instance.new("Frame"); ef.Size=UDim2.new(1,0,1,0)
                ef.BackgroundColor3=Color3.fromRGB(200,20,20); ef.BackgroundTransparency=0.2
                ef.BorderSizePixel=0; ef.Parent=expG
                TweenService:Create(ef,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
                task.delay(0.45,function() if expG and expG.Parent then expG:Destroy() end end)
                -- 3s then chase
                task.delay(3,function()
                    if p and p.Parent and gameActive then
                        prisonerChasing=true; prisonerChaseSpd=6
                    end
                end)
            end

        else
            -- Chase: accelerate toward player
            prisonerChaseSpd=prisonerChaseSpd+dt*0.9
            local tgt=hrp.Position+Vector3.new(0,2,0)
            local diff=tgt-p.Position
            if diff.Magnitude>0.5 then
                p.CFrame=CFrame.new(p.Position+diff.Unit*math.min(prisonerChaseSpd*dt,diff.Magnitude))
            end
            -- Caught player
            if diff.Magnitude<3 then
                prisonerChasing=false
                if prisonerHBConn then prisonerHBConn:Disconnect(); prisonerHBConn=nil end
                -- Raise then explode
                local hrp2=getHRP()
                if hrp2 then
                    hrp2.Anchored=true
                    TweenService:Create(hrp2,TweenInfo.new(1.6,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
                        {CFrame=hrp2.CFrame+Vector3.new(0,40,0)}):Play()
                end
                local eGui=Instance.new("ScreenGui"); eGui.Name="PrisonerKill"
                eGui.ResetOnSpawn=false; eGui.Parent=player.PlayerGui
                local ef2=Instance.new("Frame"); ef2.Size=UDim2.new(1,0,1,0)
                ef2.BackgroundColor3=Color3.fromRGB(255,100,20); ef2.BackgroundTransparency=0
                ef2.BorderSizePixel=0; ef2.Parent=eGui
                TweenService:Create(ef2,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play()
                task.delay(1.8,function()
                    local h=getHumanoid(); if h then h.Health=0 end
                    if eGui and eGui.Parent then eGui:Destroy() end
                    if p and p.Parent then p:Destroy(); prisonerPart=nil end
                    if prisonerRageGui and prisonerRageGui.Parent then
                        prisonerRageGui:Destroy(); prisonerRageGui=nil
                    end
                end)
            end
        end
    end)
end

-- Saferoom
local function buildSaferoom()
    local f=Instance.new("Folder"); f.Name="Saferoom"; f.Parent=workspace
    local o=SAFE_ORIGIN; local cX=SAFE_W/2; local cZ=SAFE_D/2
    makePart("Floor",Vector3.new(SAFE_W,1,SAFE_D),o+Vector3.new(cX,-0.5,cZ),C.safeFlr,Enum.Material.SmoothPlastic,0,true,f)
    makePart("Ceiling",Vector3.new(SAFE_W,1,SAFE_D),o+Vector3.new(cX,15.5,cZ),C.safe,Enum.Material.SmoothPlastic,0,true,f)
    makePart("BackWall",Vector3.new(SAFE_W,16,1),o+Vector3.new(cX,7.5,SAFE_D),C.safe,Enum.Material.SmoothPlastic,0,true,f)
    makePart("LeftWall",Vector3.new(1,16,SAFE_D),o+Vector3.new(0,7.5,cZ),C.safe,Enum.Material.SmoothPlastic,0,true,f)
    makePart("RightWall",Vector3.new(1,16,SAFE_D),o+Vector3.new(SAFE_W,7.5,cZ),C.safe,Enum.Material.SmoothPlastic,0,true,f)
    local dW=CELL_SIZE+4; local pW=(SAFE_W-dW)/2
    makePart("FrontL",Vector3.new(pW,16,1),o+Vector3.new(pW/2,7.5,0),C.safe,Enum.Material.SmoothPlastic,0,true,f)
    makePart("FrontR",Vector3.new(pW,16,1),o+Vector3.new(SAFE_W-pW/2,7.5,0),C.safe,Enum.Material.SmoothPlastic,0,true,f)
    makePart("DoorHdr",Vector3.new(dW,4,1),o+Vector3.new(cX,14,0),C.safe,Enum.Material.SmoothPlastic,0,true,f)
    local door=makePart("DoorTrigger",Vector3.new(dW,10,1.2),o+Vector3.new(cX,5.5,1.5),C.door,Enum.Material.Neon,0.45,false,f)
    setESP(door,C.door,C.door,0.3)
    local dp=RunService.Heartbeat:Connect(function() if door and door.Parent then door.Transparency=0.32+0.2*math.sin(tick()*2.5) end end)
    table.insert(animConns,dp)
    local fl=f:FindFirstChild("Floor"); if fl then local pl=Instance.new("PointLight"); pl.Brightness=3; pl.Range=55; pl.Color=Color3.fromRGB(155,235,155); pl.Parent=fl end

    -- Skip pads: one per future round, placed along the back wall
    local skipColors={
        Color3.fromRGB(90,200,255), Color3.fromRGB(255,200,50),
        Color3.fromRGB(200,80,255), Color3.fromRGB(80,255,140), Color3.fromRGB(255,80,80),
    }
    for i=1,5 do
        local targetRound=i+1 -- skip to round 2,3,4,5,6
        local padX=o.X + 4 + (i-1)*(SAFE_W-8)/4
        local padZ=o.Z + SAFE_D - 4
        local col=skipColors[i]
        local skip=makePart("SkipPad_R"..targetRound,
            Vector3.new(6,0.4,6), Vector3.new(padX,0.2,padZ),
            col, Enum.Material.Neon, 0.2, true, f)
        -- pulse
        local pa=RunService.Heartbeat:Connect(function()
            if skip and skip.Parent then skip.Transparency=0.1+0.25*math.abs(math.sin(tick()*2+i)) end
        end)
        table.insert(animConns,pa)
        -- label via BillboardGui (just a TextLabel, no billboard tricks)
        local bb2=Instance.new("BillboardGui"); bb2.Size=UDim2.new(0,120,0,36)
        bb2.StudsOffset=Vector3.new(0,3,0); bb2.AlwaysOnTop=false; bb2.Parent=skip
        local lbl2=Instance.new("TextLabel"); lbl2.Size=UDim2.new(1,0,1,0)
        lbl2.BackgroundTransparency=1; lbl2.Text="Skip→R"..targetRound
        lbl2.TextColor3=Color3.new(1,1,1); lbl2.Font=Enum.Font.GothamBold
        lbl2.TextScaled=true; lbl2.Parent=bb2
        -- touch
        local debounce=false
        skip.Touched:Connect(function(hit)
            if debounce then return end
            if hit.Parent~=player.Character then return end
            if gameActive then return end
            debounce=true
            currentRound=targetRound
            startRound()
            task.delay(1, function() debounce=false end)
        end)
    end

    doorPart=door; return f,door
end

-- Start round
local function startRound()
    if gameActive then return end
    gameActive=true; espActive=false; dasherActive=false; pinpointSpawned=false; pinpointChasing=false; shardList={}; collected=0
    cleanAnimConns()
    if mazeFolder then mazeFolder:Destroy(); mazeFolder=nil end
    if dasherPart then dasherPart:Destroy(); dasherPart=nil end
    if dasherLoop then dasherLoop:Disconnect(); dasherLoop=nil end
    if dasherConn then dasherConn:Disconnect(); dasherConn=nil end
    if pinpointHBConn then pinpointHBConn:Disconnect(); pinpointHBConn=nil end
    if pinpointLoop then pinpointLoop:Disconnect(); pinpointLoop=nil end
    if pinpointConn then pinpointConn:Disconnect(); pinpointConn=nil end
    if pinpointPart then pinpointPart:Destroy(); pinpointPart=nil end
    if pinpointLinePart then pinpointLinePart:Destroy(); pinpointLinePart=nil end
    if saintLoop then saintLoop:Disconnect(); saintLoop=nil end
    if saintEventConn then saintEventConn:Disconnect(); saintEventConn=nil end
    if saintPart then saintPart:Destroy(); saintPart=nil end
    saintActive=false; setVigAlpha(0)
    if unlivelLoop then unlivelLoop:Disconnect(); unlivelLoop=nil end
    unlivelActive=false
    if despairLoop then despairLoop:Disconnect(); despairLoop=nil end
    despairActive=false
    if puddleSlowConn then puddleSlowConn:Disconnect(); puddleSlowConn=nil end
    for _,pd in ipairs(despairPuddles) do if pd and pd.Parent then pd:Destroy() end end
    despairPuddles={}
    if ecneulfniLoop then ecneulfniLoop:Disconnect(); ecneulfniLoop=nil end
    ecneulfniActive=false
    if vortexLoop then vortexLoop:Disconnect(); vortexLoop=nil end
    vortexActive=false
    accentBar.BackgroundColor3=C.shard
    local gW,gH,st=getRound(currentRound); refreshHUD("Generating Round "..currentRound.."…",C.white)
    math.randomseed(os.clock()*100000+currentRound*997)
    local grid=generateMaze(gW,gH); currentGrid=grid; gridW=gW; gridH=gH
    mazeFolder=buildMazeWorld(grid,gW,gH)
    local cells=getOpenCells(grid,gW,gH); shuffle(cells)
    local sc=cells[1]; local ec=cells[#cells]
    local sp=cellToWorld(sc[1],sc[2])+Vector3.new(0,1,0); exitCellPos=cellToWorld(ec[1],ec[2])
    totalShards=math.min(st,#cells-2)
    for i=2,totalShards+1 do
        local cell=cells[i]; if not cell then break end
        local s=spawnShard(cellToWorld(cell[1],cell[2]),mazeFolder); local idx=i-1
        local sd={part=s,conn=nil}; shardList[idx]=sd
        sd.conn=s.Touched:Connect(function(hit) if hit.Parent==player.Character then onShardTouched(sd) end end)
    end
    refreshHUD("Collect all "..totalShards.." shards!",C.shard)
    if currentRound==1 then createDasherPart(mazeFolder); startDasherLoop(0.30,5) end
    if currentRound>=2 then createDasherPart(mazeFolder); startDasherLoop(0.50,10); createPinpointPart(mazeFolder); startPinpointLoop(); startSaintLoop() end
    if currentRound>=3 then startUnlivelLoop() end
    if currentRound>=4 then startDespairLoop(); startEcneulfniLoop() end
    if currentRound>=5 then startVortexLoop() end
    if modInexplicable then
        prisonerRage=0; prisonerHeadless=false; prisonerChasing=false
        task.delay(0.5,function() startPrisonerLoop() end)
    end
    if modFixation then
        local hum2=getHumanoid(); if hum2 then hum2.WalkSpeed=32 end
    end
    task.wait(0.15); local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(sp) end
end

-- Init
local _sf,initDoor=buildSaferoom()
task.wait(1.2); local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(safeSpawnPos) end
refreshHUD("Enter the door to start",C.door)
initDoor.Touched:Connect(function(hit) if hit.Parent==player.Character and not gameActive then startRound() end end)
player.CharacterAdded:Connect(function(c)
    character=c; task.wait(0.5); local h=c:WaitForChild("HumanoidRootPart",5)
    if h then
        if not gameActive then
            h.CFrame=CFrame.new(safeSpawnPos)
            if modFixation then task.delay(0.5,function() local hm=getHumanoid(); if hm then hm.WalkSpeed=32 end end) end
            if modInexplicable and not prisonerHBConn then task.delay(1,function() startPrisonerLoop() end) end
        else
            gameActive=false; pinpointChasing=false; cleanAnimConns()
            if mazeFolder then mazeFolder:Destroy(); mazeFolder=nil end
            if dasherPart then dasherPart:Destroy(); dasherPart=nil end
            if dasherLoop then dasherLoop:Disconnect(); dasherLoop=nil end
            if pinpointHBConn then pinpointHBConn:Disconnect(); pinpointHBConn=nil end
            if pinpointLoop then pinpointLoop:Disconnect(); pinpointLoop=nil end
            if pinpointPart then pinpointPart:Destroy(); pinpointPart=nil end
            if pinpointLinePart then pinpointLinePart:Destroy(); pinpointLinePart=nil end
            shardList={}; collected=0; totalShards=0; espActive=false; dasherActive=false
            pinpointSpawned=false; currentGrid=nil
            if saintLoop then saintLoop:Disconnect(); saintLoop=nil end
            if saintEventConn then saintEventConn:Disconnect(); saintEventConn=nil end
            if saintPart then saintPart:Destroy(); saintPart=nil end
            saintActive=false; setVigAlpha(0)
            if despairLoop then despairLoop:Disconnect(); despairLoop=nil end
            despairActive=false
            if puddleSlowConn then puddleSlowConn:Disconnect(); puddleSlowConn=nil end
            accentBar.BackgroundColor3=C.shard
            h.CFrame=CFrame.new(safeSpawnPos)
            if modFixation then h.WalkSpeed=32 end
            if modInexplicable then task.delay(1,function() startPrisonerLoop() end) end
            refreshHUD("You died. Enter door to retry Round "..currentRound,C.dasher)
        end
    end
end)
