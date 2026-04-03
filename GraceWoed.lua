-- ============================================================
--  GRACE : WOED  -  Fanmade
--  Domain: Frenzy (Dasher's Domain)
--  Run via executor loadstring
--  Credits: Devious Goober
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local UIS          = game:GetService("UserInputService")
local Debris       = game:GetService("Debris")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Sound helper (global)
local function playSound(id, parent, vol)
    local s=Instance.new("Sound"); s.SoundId="rbxassetid://"..id
    s.Volume=vol or 1; s.Parent=parent or workspace; s:Play()
    game:GetService("Debris"):AddItem(s, 8)
    return s
end

local function getHRP()   local c=player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c=player.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function makePart(n,sz,pos,col,mat,trans,collide,parent)
    local p=Instance.new("Part"); p.Name=n; p.Size=sz; p.CFrame=CFrame.new(pos)
    p.Anchored=true; p.CanCollide=collide~=false; p.Material=mat or Enum.Material.SmoothPlastic
    p.Color=col; p.Transparency=trans or 0; p.CastShadow=false; p.Parent=parent; return p
end

-- ── Constants ───────────────────────────────────────────────
local SAFE_ORIGIN    = Vector3.new(0,0,0)
local SAFE_W, SAFE_D = 40, 44
local safeSpawnPos   = SAFE_ORIGIN + Vector3.new(SAFE_W/2, 1.5, SAFE_D/2)

local DOM_ORIGIN   = Vector3.new(600, 0, 200)  -- domain road starts here
local ROAD_W       = 75
local ROAD_H       = 20
local SEG_LEN      = 200
local MAX_SEGS     = 50
local PLAYER_SPEED = 50

local C = {
    wall   = Color3.fromRGB(28, 10, 10),
    floor  = Color3.fromRGB(18, 6, 6),
    roof   = Color3.fromRGB(22, 8, 8),
    door   = Color3.fromRGB(45, 210, 95),
    reck   = Color3.fromRGB(255, 30, 0),
    reckD  = Color3.fromRGB(160, 10, 0),
    tar    = Color3.fromRGB(18, 20, 12),
    gate   = Color3.fromRGB(0, 200, 255),
    portal = Color3.fromRGB(120, 0, 255),
    hide   = Color3.fromRGB(255, 100, 0),
    gold   = Color3.fromRGB(255, 200, 30),
    white  = Color3.new(1,1,1),
}

-- ── Domain state ────────────────────────────────────────────
local domainActive    = false
local selectedDomain  = nil
local builtSegs       = {}    -- [idx] -> {folder, startZ}
local segCount        = 0
local finalDoorBuilt  = false
local finalDoorOpen   = false
local finalBtnCount   = 0
local endingTriggered = false

-- Reckless
local reckFolder    = nil
local reckParts     = {}      -- {part, lx, ly, lz}  (local offsets from crowd center Z)
local reckZ         = 0       -- world Z of crowd center
local reckDir       = 1       -- 1=forward  -1=backward
local reckRunning   = false
local reckCooldown  = 10      -- seconds until first run
local reckCooldownT = 0
local reckSound     = nil

-- Shake

-- Parry
local isParrying    = false

-- Fog saved values
local savedFogColor  = Lighting.FogColor
local savedFogStart  = Lighting.FogStart
local savedFogEnd    = Lighting.FogEnd
local savedBright    = Lighting.Brightness
local savedOutAmb    = Lighting.OutdoorAmbient
local savedAmb       = Lighting.Ambient

-- ── Screen shake (RenderStepped-based, mobile friendly) ──────
local shakeIntensityVal = 0
local shakeDurationVal  = 0
local shakeStartTime    = 0

local function doShake(intensity, duration)
    -- intensity: studs of offset, duration: seconds
    shakeIntensityVal = intensity or 5
    shakeDurationVal  = duration  or 0.65
    shakeStartTime    = tick()
end

RunService:BindToRenderStep("DomainShake", Enum.RenderPriority.Camera.Value+1, function()
    if shakeDurationVal <= 0 then return end
    local elapsed = tick() - shakeStartTime
    if elapsed < shakeDurationVal then
        local progress = elapsed / shakeDurationVal
        local cur = shakeIntensityVal * (1 - progress)
        local cam = workspace.CurrentCamera
        local ox = (math.random()-0.5)*2*cur
        local oy = (math.random()-0.5)*2*cur
        cam.CFrame = cam.CFrame * CFrame.new(ox, oy, 0)
    else
        shakeDurationVal = 0
    end
end)

-- ── Fog setup ────────────────────────────────────────────────
local function applyDomainFog()
    Lighting.FogColor       = Color3.fromRGB(160, 8, 8)
    Lighting.FogStart       = 8
    Lighting.FogEnd         = 65
    Lighting.Brightness     = 0.25
    Lighting.OutdoorAmbient = Color3.fromRGB(60, 4, 4)
    Lighting.Ambient        = Color3.fromRGB(30, 2, 2)
end

local function restoreFog()
    Lighting.FogColor       = savedFogColor
    Lighting.FogStart       = savedFogStart
    Lighting.FogEnd         = savedFogEnd
    Lighting.Brightness     = savedBright
    Lighting.OutdoorAmbient = savedOutAmb
    Lighting.Ambient        = savedAmb
end

-- ── HUD + Parry + Domain Selector ───────────────────────────
local sg = Instance.new("ScreenGui"); sg.Name="WOEDMain"; sg.ResetOnSpawn=false; sg.Parent=player.PlayerGui

-- Domain selector bar (top center)
local dsBar = Instance.new("Frame"); dsBar.Size=UDim2.new(0,360,0,46)
dsBar.Position=UDim2.new(0.5,-180,0,8); dsBar.BackgroundColor3=Color3.fromRGB(8,3,3)
dsBar.BackgroundTransparency=0.08; dsBar.BorderSizePixel=0; dsBar.Parent=sg
Instance.new("UICorner",dsBar).CornerRadius=UDim.new(0,10)
local dsStroke=Instance.new("UIStroke"); dsStroke.Color=Color3.fromRGB(180,25,0); dsStroke.Thickness=2; dsStroke.Parent=dsBar

local dsTitle=Instance.new("TextLabel"); dsTitle.Size=UDim2.new(0,90,1,0); dsTitle.Position=UDim2.new(0,8,0,0)
dsTitle.BackgroundTransparency=1; dsTitle.Text="DOMAIN:"; dsTitle.TextColor3=Color3.fromRGB(180,70,70)
dsTitle.Font=Enum.Font.GothamBold; dsTitle.TextScaled=true; dsTitle.TextXAlignment=Enum.TextXAlignment.Left; dsTitle.Parent=dsBar

local frenzyBtn=Instance.new("TextButton"); frenzyBtn.Size=UDim2.new(0,210,0,32)
frenzyBtn.Position=UDim2.new(0,102,0.5,-16); frenzyBtn.BackgroundColor3=Color3.fromRGB(35,8,8)
frenzyBtn.Text="Frenzy  |  Dasher's Domain"; frenzyBtn.Font=Enum.Font.GothamBold; frenzyBtn.TextSize=13
frenzyBtn.TextColor3=Color3.fromRGB(255,70,40); frenzyBtn.BorderSizePixel=0; frenzyBtn.Parent=dsBar
Instance.new("UICorner",frenzyBtn).CornerRadius=UDim.new(0,6)
local fbs=Instance.new("UIStroke"); fbs.Color=Color3.fromRGB(200,40,15); fbs.Thickness=1.5; fbs.Parent=frenzyBtn

local dsNotice=Instance.new("TextLabel"); dsNotice.Size=UDim2.new(0,50,1,0); dsNotice.Position=UDim2.new(1,-58,0,0)
dsNotice.BackgroundTransparency=1; dsNotice.Text="PICK"; dsNotice.TextColor3=Color3.fromRGB(200,100,80)
dsNotice.Font=Enum.Font.GothamBold; dsNotice.TextScaled=true; dsNotice.Parent=dsBar

-- HUD
local hf=Instance.new("Frame"); hf.Size=UDim2.new(0,210,0,44); hf.Position=UDim2.new(0,14,0,62)
hf.BackgroundColor3=Color3.fromRGB(5,2,2); hf.BackgroundTransparency=0.2; hf.BorderSizePixel=0; hf.Parent=sg
Instance.new("UICorner",hf).CornerRadius=UDim.new(0,8)
local hudLbl=Instance.new("TextLabel"); hudLbl.Size=UDim2.new(1,-10,1,0); hudLbl.Position=UDim2.new(0,8,0,0)
hudLbl.BackgroundTransparency=1; hudLbl.Text="Pick a domain to begin"
hudLbl.TextColor3=Color3.fromRGB(200,130,130); hudLbl.Font=Enum.Font.GothamBold
hudLbl.TextScaled=true; hudLbl.TextXAlignment=Enum.TextXAlignment.Left; hudLbl.Parent=hf

-- Parry button
local pg=Instance.new("ScreenGui"); pg.Name="ParryGui"; pg.ResetOnSpawn=false; pg.Parent=player.PlayerGui
local pb=Instance.new("TextButton"); pb.Size=UDim2.new(0,110,0,110); pb.Position=UDim2.new(1,-130,1,-185)
pb.BackgroundColor3=Color3.fromRGB(255,215,0); pb.Text="PARRY"; pb.Font=Enum.Font.GothamBold; pb.TextSize=22
pb.TextColor3=Color3.new(0,0,0); pb.BorderSizePixel=0; pb.Parent=pg
Instance.new("UICorner",pb).CornerRadius=UDim.new(1,0)
local ps=Instance.new("UIStroke"); ps.Color=Color3.new(1,1,1); ps.Thickness=3; ps.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; ps.Parent=pb
local function holdParry() isParrying=true; TweenService:Create(pb,TweenInfo.new(0.08),{BackgroundColor3=Color3.new(1,1,1),Size=UDim2.new(0,122,0,122)}):Play() end
local function relParry()  isParrying=false; TweenService:Create(pb,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(255,215,0),Size=UDim2.new(0,110,0,110)}):Play() end
pb.MouseButton1Down:Connect(holdParry); pb.MouseButton1Up:Connect(relParry); pb.MouseLeave:Connect(relParry)
UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.Q or inp.KeyCode==Enum.KeyCode.ButtonR1 then holdParry() end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.KeyCode==Enum.KeyCode.Q or inp.KeyCode==Enum.KeyCode.ButtonR1 then relParry() end
end)

-- ── Reckless crowd builder ───────────────────────────────────
local function buildReckless()
    if reckFolder and reckFolder.Parent then reckFolder:Destroy() end
    reckFolder = Instance.new("Folder"); reckFolder.Name="Reckless"; reckFolder.Parent=workspace
    reckParts = {}

    local colOffsets = {-20,-12,-4,4,12,20}
    local rowOffsets = {-10,-5,0,5,10}
    local cx = DOM_ORIGIN.X

    -- Invisible anchor for sound + center reference
    local anchor = Instance.new("Part"); anchor.Size=Vector3.new(0.1,0.1,0.1)
    anchor.Anchored=true; anchor.CanCollide=false; anchor.Transparency=1
    anchor.Position=Vector3.new(cx,3,DOM_ORIGIN.Z-80); anchor.Parent=reckFolder
    table.insert(reckParts,{part=anchor, lx=0, ly=3, lz=0})

    reckSound = Instance.new("Sound"); reckSound.SoundId="rbxassetid://140055944802247"
    reckSound.Volume=1.5; reckSound.Looped=true; reckSound.RollOffMaxDistance=500
    reckSound.Parent=anchor; reckSound:Play()

    for _,col in ipairs(colOffsets) do
        for _,row in ipairs(rowOffsets) do
            local function rp(name,sz,lx,ly,lz,col3)
                local p=Instance.new("Part"); p.Name=name; p.Size=sz
                p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.Neon
                p.Color=col3; p.CastShadow=false; p.Parent=reckFolder
                p.Position=Vector3.new(cx+lx, ly, DOM_ORIGIN.Z-80+lz)
                table.insert(reckParts,{part=p, lx=lx, ly=ly, lz=lz})
                return p
            end
            rp("Torso",    Vector3.new(2,2.2,1.2), col,    3,   row, C.reck)
            rp("LeftArm",  Vector3.new(1,2,1),     col-1.5,3,   row, C.reckD)
            rp("RightArm", Vector3.new(1,2,1),     col+1.5,3,   row, C.reckD)
            rp("LeftLeg",  Vector3.new(1,2,1),     col-0.5,1,   row, C.reckD)
            rp("RightLeg", Vector3.new(1,2,1),     col+0.5,1,   row, C.reckD)
            -- Red glow per member
            local gl=Instance.new("PointLight"); gl.Brightness=3; gl.Range=12
            gl.Color=Color3.fromRGB(255,30,0); gl.Parent=reckParts[#reckParts].part
        end
    end
    reckZ = DOM_ORIGIN.Z - 80
end

local function setReckZ(newZ)
    reckZ = newZ
    local cx = DOM_ORIGIN.X
    for _,e in ipairs(reckParts) do
        if e.part and e.part.Parent then
            e.part.Position = Vector3.new(cx + e.lx, e.ly, newZ + e.lz)
        end
    end
end

-- ── Player safety check (is in hiding spot) ──────────────────
local function playerInHide()
    local hrp=getHRP(); if not hrp then return false end
    local rx = math.abs(hrp.Position.X - DOM_ORIGIN.X)
    if rx > ROAD_W/2 + 2 then return true end   -- inside wall alcove
    if hrp.Position.Y > 8 then return true end   -- on roof platform
    return false
end

-- ── Hiding spot builder ──────────────────────────────────────
-- Returns hideType string
local function buildHideSpot(parent, segIdx)
    local startZ = DOM_ORIGIN.Z + segIdx * SEG_LEN
    local hideZ  = startZ + 100   -- midpoint of segment
    local cx     = DOM_ORIGIN.X
    local hw     = ROAD_W/2
    local TYPES  = {"wall_left","wall_right","roof"}
    local htype  = TYPES[math.random(1,3)]

    -- Glow at entrance
    local function addIndicator(px, py, pz, sz)
        local ind=makePart("HideInd",sz,Vector3.new(px,py,pz),C.hide,Enum.Material.Neon,0.55,false,parent)
        local gl=Instance.new("PointLight"); gl.Brightness=4; gl.Range=18; gl.Color=C.hide; gl.Parent=ind
        return ind
    end

    if htype == "wall_left" or htype == "wall_right" then
        local side = (htype=="wall_left") and -1 or 1
        local wallX = cx + side*(hw+0.5)
        local AOPEN = 22   -- opening width along Z
        local ADEPTH= 16   -- depth extending from wall

        -- Split the wall: before alcove and after alcove
        local beforeLen = 100 - AOPEN/2     -- ~89
        local afterStart= 100 + AOPEN/2     -- ~111
        local afterLen  = SEG_LEN - afterStart
        makePart("WallA",Vector3.new(1,ROAD_H,beforeLen),Vector3.new(wallX,ROAD_H/2,startZ+beforeLen/2),C.wall,nil,0,true,parent)
        makePart("WallB",Vector3.new(1,ROAD_H,afterLen), Vector3.new(wallX,ROAD_H/2,startZ+afterStart+afterLen/2),C.wall,nil,0,true,parent)

        -- Alcove room
        local alc_cx = cx + side*(hw + ADEPTH/2 + 0.5)
        makePart("AlcFloor",  Vector3.new(ADEPTH,1,AOPEN),     Vector3.new(alc_cx,-0.5,hideZ),            C.floor, nil,0,true, parent)
        makePart("AlcRoof",   Vector3.new(ADEPTH,1,AOPEN),     Vector3.new(alc_cx,ROAD_H+0.5,hideZ),      C.roof,  nil,0,true, parent)
        makePart("AlcEnd",    Vector3.new(1,ROAD_H,AOPEN),     Vector3.new(cx+side*(hw+ADEPTH+1),ROAD_H/2,hideZ), C.wall,nil,0,true, parent)
        makePart("AlcSide1",  Vector3.new(ADEPTH,ROAD_H,1),    Vector3.new(alc_cx,ROAD_H/2,hideZ-AOPEN/2-0.5),C.wall,nil,0,true,parent)
        makePart("AlcSide2",  Vector3.new(ADEPTH,ROAD_H,1),    Vector3.new(alc_cx,ROAD_H/2,hideZ+AOPEN/2+0.5),C.wall,nil,0,true,parent)

        -- Indicator (open entrance flash strip)
        addIndicator(wallX, ROAD_H/2, hideZ, Vector3.new(1.2, ROAD_H-2, AOPEN-2))

        -- Opposite wall is full
        local opp = cx - side*(hw+0.5)
        makePart("WallOpp",Vector3.new(1,ROAD_H,SEG_LEN),Vector3.new(opp,ROAD_H/2,startZ+SEG_LEN/2),C.wall,nil,0,true,parent)
    else
        -- Roof platform type
        -- Both side walls are full
        makePart("WallL",Vector3.new(1,ROAD_H,SEG_LEN),Vector3.new(cx-hw-0.5,ROAD_H/2,startZ+SEG_LEN/2),C.wall,nil,0,true,parent)
        makePart("WallR",Vector3.new(1,ROAD_H,SEG_LEN),Vector3.new(cx+hw+0.5,ROAD_H/2,startZ+SEG_LEN/2),C.wall,nil,0,true,parent)

        -- Step platform (Y=6.5, 30 wide, 22 long)
        makePart("Step",     Vector3.new(30,1,22),Vector3.new(cx,6.5,hideZ),               C.wall,Enum.Material.SmoothPlastic,0,true,parent)
        -- Main roof platform (Y=12.5, 40 wide, 22 long)
        local roofPlatform=makePart("RoofPlat",Vector3.new(40,1,22),Vector3.new(cx,12.5,hideZ),C.floor,Enum.Material.SmoothPlastic,0,true,parent)
        -- Railings on roof platform
        makePart("RailL",Vector3.new(1,3,22),Vector3.new(cx-20,14,hideZ),C.wall,nil,0,true,parent)
        makePart("RailR",Vector3.new(1,3,22),Vector3.new(cx+20,14,hideZ),C.wall,nil,0,true,parent)

        -- Glowing indicator strip on step
        addIndicator(cx,7.1,hideZ,Vector3.new(28,0.4,20))
    end

    return htype
end

-- ── Segment builder ──────────────────────────────────────────
local function buildSegment(segIdx)
    if builtSegs[segIdx] then return end
    local f = Instance.new("Folder"); f.Name="Seg_"..segIdx; f.Parent=workspace
    local startZ = DOM_ORIGIN.Z + segIdx * SEG_LEN
    local midZ   = startZ + SEG_LEN/2
    local cx     = DOM_ORIGIN.X
    local hw     = ROAD_W/2

    -- Floor + roof
    makePart("Floor",Vector3.new(ROAD_W,1,SEG_LEN),Vector3.new(cx,-0.5,midZ),   C.floor,nil,0,true,f)
    makePart("Roof", Vector3.new(ROAD_W,1,SEG_LEN),Vector3.new(cx,ROAD_H+0.5,midZ),C.roof,nil,0,true,f)

    -- Back wall only on segment 0
    if segIdx==0 then
        makePart("BackWall",Vector3.new(ROAD_W+2,ROAD_H,1),Vector3.new(cx,ROAD_H/2,startZ-0.5),C.wall,nil,0,true,f)
    end

    -- Ambient light in each segment
    local afl=f:FindFirstChild("Floor")
    if afl then
        local pl=Instance.new("PointLight"); pl.Brightness=1.5; pl.Range=120
        pl.Color=Color3.fromRGB(160,10,10); pl.Parent=afl
    end

    local isGate = (segIdx>=2) and ((segIdx+1) % 3 == 0) and segIdx < MAX_SEGS-1
    local hasTar = segIdx >= 6

    -- Build walls (hide spot splits them, gate segments leave walls full)
    if not isGate and segIdx > 0 then
        local htype = buildHideSpot(f, segIdx)
        builtSegs[segIdx] = {folder=f, startZ=startZ, htype=htype}
    else
        -- Full side walls
        makePart("WallL",Vector3.new(1,ROAD_H,SEG_LEN),Vector3.new(cx-hw-0.5,ROAD_H/2,midZ),C.wall,nil,0,true,f)
        makePart("WallR",Vector3.new(1,ROAD_H,SEG_LEN),Vector3.new(cx+hw+0.5,ROAD_H/2,midZ),C.wall,nil,0,true,f)
        builtSegs[segIdx] = {folder=f, startZ=startZ, htype="none"}
    end

    -- Gate door (every 3rd segment, segments 2,5,8...)
    if isGate then
        local gateZ = startZ + SEG_LEN - 8
        local cyan   = C.gate
        local frame  = Color3.fromRGB(15,50,70)

        makePart("GPillarL",Vector3.new(4,ROAD_H,4),  Vector3.new(cx-hw+2,ROAD_H/2,gateZ),frame,nil,0,true,f)
        makePart("GPillarR",Vector3.new(4,ROAD_H,4),  Vector3.new(cx+hw-2,ROAD_H/2,gateZ),frame,nil,0,true,f)
        makePart("GTop",    Vector3.new(ROAD_W,4,4),  Vector3.new(cx,ROAD_H-2,gateZ),      frame,nil,0,true,f)

        local panel=makePart("GDoor",Vector3.new(ROAD_W-8,ROAD_H-4,1.5),Vector3.new(cx,(ROAD_H-4)/2+0.5,gateZ),cyan,Enum.Material.Neon,0.2,true,f)
        local glow=Instance.new("PointLight"); glow.Brightness=6; glow.Range=30; glow.Color=cyan; glow.Parent=panel

        -- 3 buttons at staggered positions in the segment
        local btnData = {}
        local btnPositions = {
            Vector3.new(cx-22, 0.5, startZ+55),
            Vector3.new(cx+22, 0.5, startZ+125),
            Vector3.new(cx,    0.5, startZ+175),
        }
        local activated = 0
        for bi, bpos in ipairs(btnPositions) do
            local btn=makePart("GBtn_"..bi,Vector3.new(5,1,5),bpos,Color3.fromRGB(255,80,0),Enum.Material.Neon,0,false,f)
            local bl=Instance.new("PointLight"); bl.Brightness=3; bl.Range=14; bl.Color=Color3.fromRGB(255,80,0); bl.Parent=btn
            local pp=Instance.new("ProximityPrompt"); pp.ActionText="Activate"; pp.MaxActivationDistance=8
            pp.ObjectText="Gate Button"; pp.RequiresLineOfSight=false; pp.HoldDuration=0.5; pp.Parent=btn
            local used=false
            pp.Triggered:Connect(function()
                if used then return end; used=true
                btn.Color=Color3.fromRGB(0,255,80)
                local bl2=btn:FindFirstChildOfClass("PointLight"); if bl2 then bl2.Color=Color3.fromRGB(0,255,80) end
                activated = activated + 1
                if activated >= 3 then
                    -- Slide door down
                    local gh=getHRP(); if gh then playSound("115937318685871",gh,1) end
                    TweenService:Create(panel,TweenInfo.new(2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
                        {CFrame=panel.CFrame+Vector3.new(0,-(ROAD_H+8),0)}):Play()
                    task.delay(2.2,function() if panel and panel.Parent then panel:Destroy() end end)
                end
            end)
        end
    end

    -- Tar patches (segment 7+, 10 per segment)
    if hasTar then
        for i=1,10 do
            local tx = cx + math.random(math.floor(-ROAD_W/2+8), math.floor(ROAD_W/2-8))
            local tz = startZ + math.random(30, SEG_LEN-30)
            local ts = math.random(15,22)
            local tar=makePart("Tar_"..i,Vector3.new(ts,0.6,ts),Vector3.new(tx,0.25,tz),C.tar,Enum.Material.Neon,0.25,false,f)
            tar.Color=Color3.fromRGB(0,0,0); tar.Material=Enum.Material.Neon; tar.Transparency=0.15
            local tarConn = tar.Touched:Connect(function(hit)
                if hit.Parent~=player.Character then return end
                local hum=getHum(); if not hum then return end
                hum.WalkSpeed=math.max(8,hum.WalkSpeed-20)
            end)
            -- Damage per second while inside
            task.spawn(function()
                while tar and tar.Parent and domainActive do
                    task.wait(1)
                    local hrp=getHRP()
                    if hrp then
                        local diff=hrp.Position-tar.Position
                        if Vector3.new(diff.X,0,diff.Z).Magnitude < ts/2+1 then
                            local hum=getHum()
                            if hum and hum.Health>0 then hum.Health=math.max(0.1,hum.Health-5) end
                        end
                    end
                end
                tarConn:Disconnect()
            end)
        end
    end

    -- Segment end trigger (generate next at 100-stud mark, then again at segment end)
    -- Done from main loop instead
end

-- ── Final door + 10 buttons ──────────────────────────────────
local finalDoor = nil

-- Forward declarations
local doRecklessExplosion
local startEndCutscene
local showVictoryText
local spawnPortal

local function buildFinalDoor()
    local segIdx = MAX_SEGS - 1
    local startZ = DOM_ORIGIN.Z + segIdx * SEG_LEN
    local doorZ  = startZ + SEG_LEN - 8
    local cx     = DOM_ORIGIN.X
    local f      = builtSegs[segIdx] and builtSegs[segIdx].folder or workspace

    -- Frame + door
    local dframe=makePart("FinalFrame",Vector3.new(14,16,1.5),Vector3.new(cx,8,doorZ),Color3.fromRGB(55,35,15),nil,0,true,f)
    finalDoor=makePart("FinalDoor",Vector3.new(10,13,1.2),Vector3.new(cx,6.5,doorZ),Color3.fromRGB(80,55,25),nil,0,true,f)
    local dl=Instance.new("PointLight"); dl.Brightness=4; dl.Range=20; dl.Color=Color3.fromRGB(255,180,50); dl.Parent=finalDoor

    -- 10 buttons spread across last 3 segments
    local finalBtns = {}
    for i=1,10 do
        local bseg = MAX_SEGS - 1 - math.floor((i-1)/4)  -- spread across last 3 segs
        local bsZ  = DOM_ORIGIN.Z + bseg * SEG_LEN
        local bx   = cx + math.random(math.floor(-ROAD_W/2+6), math.floor(ROAD_W/2-6))
        local bz   = bsZ + math.random(20, SEG_LEN-20)
        local btn  = makePart("FinalBtn_"..i,Vector3.new(4,1,4),Vector3.new(bx,0.5,bz),C.gold,Enum.Material.Neon,0,false,f)
        local bl2  = Instance.new("PointLight"); bl2.Brightness=3; bl2.Range=12; bl2.Color=C.gold; bl2.Parent=btn
        local pp2  = Instance.new("ProximityPrompt"); pp2.ActionText="Press"; pp2.MaxActivationDistance=8
        pp2.ObjectText="Final Button ("..i.."/10)"; pp2.RequiresLineOfSight=false; pp2.HoldDuration=0.8; pp2.Parent=btn
        local used = false
        table.insert(finalBtns, {btn=btn, pp=pp2, used=false})
        pp2.Triggered:Connect(function()
            if used then return end; used=true
            btn.Color=Color3.fromRGB(0,255,80); local bl3=btn:FindFirstChildOfClass("PointLight"); if bl3 then bl3.Color=Color3.fromRGB(0,255,80) end
            finalBtnCount = finalBtnCount + 1
            hudLbl.Text = "Final Buttons: "..finalBtnCount.."/10"
            if finalBtnCount >= 10 and not finalDoorOpen then
                finalDoorOpen = true
                -- Slide door up
                TweenService:Create(finalDoor,TweenInfo.new(2.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                    {CFrame=finalDoor.CFrame+Vector3.new(0,18,0)}):Play()
                task.delay(2.6,function()
                    if finalDoor and finalDoor.Parent then finalDoor:Destroy() end
                    -- Approach trigger just past the door
                    local trig=Instance.new("Part"); trig.Size=Vector3.new(ROAD_W,ROAD_H,8)
                    trig.Position=Vector3.new(cx,ROAD_H/2,doorZ+6); trig.Anchored=true
                    trig.CanCollide=false; trig.Transparency=1; trig.Parent=workspace
                    local tc; tc=trig.Touched:Connect(function(hit)
                        if hit.Parent~=player.Character then return end
                        if endingTriggered then return end
                        endingTriggered=true; tc:Disconnect(); trig:Destroy()
                        startEndCutscene(doorZ)
                    end)
                end)
            end
        end)
    end
end

-- ── Ending cutscene ──────────────────────────────────────────
local cutsceneConn = nil

startEndCutscene = function(doorZ)
    local hrp=getHRP(); if not hrp then return end
    local hum=getHum(); if hum then hum.WalkSpeed=0; hum.JumpPower=0 end

    local cam=workspace.CurrentCamera
    cam.CameraType=Enum.CameraType.Scriptable

    -- Camera locked just behind player, looking forward (+Z toward door)
    local ppos=hrp.Position+Vector3.new(0,2,0)
    local camPos=ppos+Vector3.new(0,2,-18)
    cam.CFrame=CFrame.new(camPos, ppos+Vector3.new(0,0,10))

    -- Place Reckless far behind (at road start)
    setReckZ(DOM_ORIGIN.Z - 10)
    reckRunning=true

    local CINE_SPEED=40

    cutsceneConn=RunService.Heartbeat:Connect(function(dt)
        reckZ=reckZ+CINE_SPEED*dt
        setReckZ(reckZ)

        -- Keep camera locked
        local hrp2=getHRP()
        if hrp2 then
            local pp=hrp2.Position+Vector3.new(0,2,0)
            cam.CFrame=CFrame.new(pp+Vector3.new(0,2,-18), pp+Vector3.new(0,0,10))
        end

        -- Distance from Reckless to player
        local hrp3=getHRP(); if not hrp3 then return end
        local dist=math.abs(hrp3.Position.Z - reckZ)

        -- Intensifying shake
        if dist < 120 then
            local I=math.clamp(1-dist/120,0,1)
                        doShake(I*8, 0.3)
        end

        -- At 30 studs: EXPLODE
        if dist < 30 then
            if cutsceneConn then cutsceneConn:Disconnect(); cutsceneConn=nil end
            reckRunning=false
            doRecklessExplosion()
        end
    end)
end

doRecklessExplosion = function()
    -- Destroy crowd
    local dhrp=getHRP(); if dhrp then playSound("93486052675418",dhrp,1.2) end
    if reckFolder and reckFolder.Parent then reckFolder:Destroy(); reckFolder=nil; reckParts={} end

    -- Massive shake for 10 seconds
    task.spawn(function()
        local cam=workspace.CurrentCamera
        local endT=tick()+10
        while tick()<endT do
            local prog=1-(endT-tick())/10
            local mag=1.5*(1-prog*0.7)
            cam.CFrame=cam.CFrame*CFrame.new((math.random()-0.5)*mag,(math.random()-0.5)*mag*0.7,0)
                *CFrame.Angles((math.random()-0.5)*0.08*mag,(math.random()-0.5)*0.12*mag,0)
            task.wait(0.04)
        end
    end)

    -- White flash
    local fg=Instance.new("ScreenGui"); fg.Name="ExpFlash"; fg.ResetOnSpawn=false; fg.Parent=player.PlayerGui
    local ff=Instance.new("Frame"); ff.Size=UDim2.new(1,0,1,0); ff.BackgroundColor3=Color3.new(1,1,1)
    ff.BackgroundTransparency=0; ff.BorderSizePixel=0; ff.Parent=fg
    TweenService:Create(ff,TweenInfo.new(4),{BackgroundTransparency=1}):Play()
    task.delay(4.1,function() if fg and fg.Parent then fg:Destroy() end end)

    -- Victory text after 1.5s
    task.delay(1.5, showVictoryText)

    -- Restore camera + player after 3s
    task.delay(3,function()
        local cam2=workspace.CurrentCamera
        cam2.CameraType=Enum.CameraType.Custom
        local hum=getHum()
        if hum then hum.WalkSpeed=PLAYER_SPEED; hum.JumpPower=50 end
    end)

    -- Portal after 4s
    task.delay(4, spawnPortal)
end

showVictoryText = function()
    local gui=Instance.new("ScreenGui"); gui.Name="Victory"; gui.ResetOnSpawn=false; gui.Parent=player.PlayerGui

    local line1=Instance.new("TextLabel"); line1.Size=UDim2.new(0.8,0,0,48)
    line1.Position=UDim2.new(0.1,0,0.28,0); line1.BackgroundTransparency=1
    line1.Text="SIN AT LOSS AT THE"; line1.TextColor3=Color3.new(1,1,1)
    line1.Font=Enum.Font.GothamBold; line1.TextScaled=true; line1.Parent=gui

    local bigWord=Instance.new("TextLabel"); bigWord.Size=UDim2.new(0.9,0,0,130)
    bigWord.Position=UDim2.new(0.05,0,0.36,0); bigWord.BackgroundTransparency=1
    bigWord.Text="AGAPE"; bigWord.TextColor3=Color3.fromRGB(255,215,60)
    bigWord.Font=Enum.Font.GothamBold; bigWord.TextScaled=true; bigWord.Parent=gui

    local line3=Instance.new("TextLabel"); line3.Size=UDim2.new(0.8,0,0,48)
    line3.Position=UDim2.new(0.1,0,0.62,0); line3.BackgroundTransparency=1
    line3.Text="VICTORY OF LOVE"; line3.TextColor3=Color3.new(1,1,1)
    line3.Font=Enum.Font.GothamBold; line3.TextScaled=true; line3.Parent=gui

    -- Each label shakes its letters (approximate: shake whole labels independently)
    local t=0; local labels={line1,bigWord,line3}
    local basePos={UDim2.new(0.1,0,0.28,0), UDim2.new(0.05,0,0.36,0), UDim2.new(0.1,0,0.62,0)}
    local vc=RunService.Heartbeat:Connect(function(dt)
        t=t+dt
        local alpha=math.min(t/5,1)
        for i,lbl in ipairs(labels) do
            lbl.TextTransparency=alpha
            local shk=(1-alpha)*7
            local bx=basePos[i].X.Scale; local by=basePos[i].Y.Scale
            lbl.Position=UDim2.new(bx,(math.random()-0.5)*shk*10,by,(math.random()-0.5)*shk*6)
        end
        if t>=5.2 then
            pcall(function()
                vc:Disconnect()
                if gui and gui.Parent then gui:Destroy() end
            end)
        end
    end)
end

spawnPortal = function()
    local cx = DOM_ORIGIN.X
    local pz = DOM_ORIGIN.Z + MAX_SEGS * SEG_LEN + 15

    local portal=Instance.new("Part"); portal.Name="ExitPortal"
    portal.Size=Vector3.new(9,14,2)
    portal.Position=Vector3.new(cx,7,pz)
    portal.Anchored=true; portal.CanCollide=false
    portal.Material=Enum.Material.Neon; portal.Color=C.portal
    portal.CastShadow=false; portal.Parent=workspace

    local hl=Instance.new("Highlight"); hl.Adornee=portal
    hl.OutlineColor=Color3.fromRGB(160,60,255); hl.FillColor=Color3.fromRGB(90,0,200)
    hl.FillTransparency=0.25; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=portal

    local pl=Instance.new("PointLight"); pl.Brightness=10; pl.Range=35; pl.Color=C.portal; pl.Parent=portal

    local pc; pc=portal.Touched:Connect(function(hit)
        if hit.Parent~=player.Character then return end
        pc:Disconnect(); portal:Destroy()
        -- Domain complete: return to saferoom
        domainActive=false; restoreFog()
        local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(safeSpawnPos) end
        hudLbl.Text="Domain Clear!"; hudLbl.TextColor3=Color3.fromRGB(100,255,100)
        selectedDomain=nil
        frenzyBtn.BackgroundColor3=Color3.fromRGB(35,8,8)
        frenzyBtn.TextColor3=Color3.fromRGB(255,70,40)
        dsNotice.Text="PICK"
    end)
end

-- ── Domain main loop ─────────────────────────────────────────
local domainConn = nil

local function startFrenzyDomain()
    domainActive    = true
    segCount        = 0
    finalDoorBuilt  = false
    finalDoorOpen   = false
    finalBtnCount   = 0
    endingTriggered = false
    reckRunning     = false
    reckCooldownT   = 0
    reckDir         = 1

    -- Clean up any old domain parts
    for _,v in pairs(builtSegs) do if v.folder and v.folder.Parent then v.folder:Destroy() end end
    builtSegs = {}

    applyDomainFog()

    -- Teleport player to domain start
    local hrp=getHRP()
    if hrp then hrp.CFrame=CFrame.new(DOM_ORIGIN.X, 1.5, DOM_ORIGIN.Z + 12) end
    local hum=getHum()
    if hum then hum.WalkSpeed=50; hum.JumpPower=50 end

    -- Build first 3 segments immediately
    for i=0,2 do buildSegment(i); segCount=i+1 end

    -- Build Reckless crowd
    buildReckless()
    setReckZ(DOM_ORIGIN.Z - 80)

    hudLbl.Text="Frenzy - RUN!"
    hudLbl.TextColor3=Color3.fromRGB(255,80,50)

    domainConn = RunService.Heartbeat:Connect(function(dt)
        if not domainActive then domainConn:Disconnect(); domainConn=nil; return end

        local hrp2=getHRP(); if not hrp2 then return end
        local pz = hrp2.Position.Z - DOM_ORIGIN.Z
        local pSeg = math.max(0, math.floor(pz / SEG_LEN))

        -- Generate road ahead (up to 3 segments ahead, max MAX_SEGS)
        local needed = math.min(pSeg + 3, MAX_SEGS - 1)
        while segCount <= needed do
            buildSegment(segCount); segCount=segCount+1
        end

        -- Final door
        if segCount >= MAX_SEGS and not finalDoorBuilt then
            finalDoorBuilt=true; buildFinalDoor()
        end

        -- Clean segments far behind (more than 3 behind player)
        for idx,data in pairs(builtSegs) do
            if idx < pSeg - 3 and data.folder and data.folder.Parent then
                data.folder:Destroy(); builtSegs[idx]=nil
            end
        end

        -- ── Reckless logic ─────────────────────────────────
        if not reckRunning then
            reckCooldownT = reckCooldownT + dt
            if reckCooldownT >= 10 then
                reckCooldownT = 0; reckRunning = true; reckDir = 1
                -- Spawn just behind the player
                setReckZ(hrp2.Position.Z - 80)
            end
        else
            local RSPEED = 100
            local newZ = reckZ + reckDir * RSPEED * dt
            local roadEnd = DOM_ORIGIN.Z + segCount * SEG_LEN

            -- Turn around at end of generated road
            if newZ >= roadEnd then
                reckDir = -1; newZ = roadEnd - 1
            end
            -- Reached back behind start: stop, start cooldown
            if newZ <= DOM_ORIGIN.Z - 60 then
                reckRunning = false; reckCooldownT = 0
                newZ = DOM_ORIGIN.Z - 80
                setReckZ(newZ)
            else
                setReckZ(newZ)
            end

            -- Kill check: not in hiding spot AND Reckless passes through
            if not playerInHide() and not endingTriggered then
                local dx = math.abs(hrp2.Position.X - DOM_ORIGIN.X)
                local dz = math.abs(hrp2.Position.Z - reckZ)
                if dx < 26 and dz < 18 then
                    local hum2=getHum(); if hum2 and hum2.Health>0 then hum2.Health=0 end
                end
            end

            -- Shake screen based on proximity
            if not endingTriggered then
                local dist=math.abs(hrp2.Position.Z - reckZ)
                local intensity=math.clamp(1-dist/180, 0, 1)
                if intensity > 0.05 then
                                        doShake(intensity*6, 0.28)
                end
            end
        end

        -- Restore walkspeed if off tar
        local hum3=getHum()
        if hum3 and hum3.WalkSpeed < PLAYER_SPEED and not endingTriggered then
            hum3.WalkSpeed=math.min(PLAYER_SPEED, hum3.WalkSpeed+dt*8)
        end
    end)
end

-- ── Saferoom ─────────────────────────────────────────────────
local function buildSaferoom()
    local f=Instance.new("Folder"); f.Name="Saferoom"; f.Parent=workspace
    local o=SAFE_ORIGIN; local cX=SAFE_W/2; local cZ=SAFE_D/2
    makePart("Floor",   Vector3.new(SAFE_W,1,SAFE_D),          o+Vector3.new(cX,-0.5,cZ),   Color3.fromRGB(40,65,40),nil,0,true,f)
    makePart("Ceiling", Vector3.new(SAFE_W,1,SAFE_D),          o+Vector3.new(cX,15.5,cZ),   Color3.fromRGB(30,50,30),nil,0,true,f)
    makePart("BackWall",Vector3.new(SAFE_W,16,1),               o+Vector3.new(cX,7.5,SAFE_D),Color3.fromRGB(30,50,30),nil,0,true,f)
    makePart("LeftWall",Vector3.new(1,16,SAFE_D),               o+Vector3.new(0,7.5,cZ),     Color3.fromRGB(30,50,30),nil,0,true,f)
    makePart("RightWall",Vector3.new(1,16,SAFE_D),              o+Vector3.new(SAFE_W,7.5,cZ),Color3.fromRGB(30,50,30),nil,0,true,f)

    local dW=12; local pW=(SAFE_W-dW)/2
    makePart("FrontL",  Vector3.new(pW,16,1),   o+Vector3.new(pW/2,7.5,0),       Color3.fromRGB(30,50,30),nil,0,true,f)
    makePart("FrontR",  Vector3.new(pW,16,1),   o+Vector3.new(SAFE_W-pW/2,7.5,0),Color3.fromRGB(30,50,30),nil,0,true,f)
    makePart("DoorHdr", Vector3.new(dW,4,1),    o+Vector3.new(cX,14,0),           Color3.fromRGB(30,50,30),nil,0,true,f)

    -- Door (gated until domain selected)
    local door=makePart("Door",Vector3.new(dW,10,1.2),o+Vector3.new(cX,5.5,1.5),Color3.fromRGB(45,210,95),Enum.Material.Neon,0.4,false,f)
    local doorGlow=Instance.new("PointLight"); doorGlow.Brightness=3; doorGlow.Range=40; doorGlow.Color=Color3.fromRGB(45,210,95); doorGlow.Parent=door
    RunService.Heartbeat:Connect(function() if door and door.Parent then door.Transparency=0.3+0.2*math.sin(tick()*2.5) end end)

    local fl=f:FindFirstChild("Floor")
    if fl then local pl=Instance.new("PointLight"); pl.Brightness=3; pl.Range=55; pl.Color=Color3.fromRGB(155,235,155); pl.Parent=fl end

    door.Touched:Connect(function(hit)
        if hit.Parent~=player.Character then return end
        if selectedDomain == nil then
            hudLbl.Text="Pick a domain first!"
            hudLbl.TextColor3=Color3.fromRGB(255,100,80)
            return
        end
        if domainActive then return end
        if selectedDomain == "Frenzy" then startFrenzyDomain() end
    end)

    return f
end

-- ── Domain selector wiring ────────────────────────────────────
frenzyBtn.MouseButton1Click:Connect(function()
    if domainActive then return end
    selectedDomain = "Frenzy"
    frenzyBtn.BackgroundColor3 = Color3.fromRGB(80, 15, 8)
    frenzyBtn.TextColor3 = Color3.fromRGB(255, 140, 100)
    dsNotice.Text = "READY"
    dsNotice.TextColor3 = Color3.fromRGB(100, 255, 120)
    hudLbl.Text = "Frenzy selected - enter the door!"
    hudLbl.TextColor3 = Color3.fromRGB(255, 130, 80)
end)

-- ── Init ──────────────────────────────────────────────────────
buildSaferoom()
task.wait(1.2)
local initHRP=getHRP()
if initHRP then initHRP.CFrame=CFrame.new(safeSpawnPos) end

player.CharacterAdded:Connect(function(c)
    character=c; task.wait(0.5)
    local h=c:WaitForChild("HumanoidRootPart",5)
    if h then
        h.CFrame=CFrame.new(safeSpawnPos)
        task.delay(0.3,function()
            local hum=getHum()
            if hum then hum.WalkSpeed=16 end
        end)
        if domainActive then
            domainActive=false
            if domainConn then domainConn:Disconnect(); domainConn=nil end
            restoreFog()
            for _,v in pairs(builtSegs) do if v.folder and v.folder.Parent then v.folder:Destroy() end end
            builtSegs={}; segCount=0
            if reckFolder and reckFolder.Parent then reckFolder:Destroy(); reckFolder=nil; reckParts={} end
            finalDoorBuilt=false; finalDoorOpen=false; finalBtnCount=0; endingTriggered=false
            selectedDomain=nil
            frenzyBtn.BackgroundColor3=Color3.fromRGB(35,8,8)
            frenzyBtn.TextColor3=Color3.fromRGB(255,70,40)
            dsNotice.Text="PICK"; dsNotice.TextColor3=Color3.fromRGB(200,100,80)
            hudLbl.Text="Pick a domain to begin"; hudLbl.TextColor3=Color3.fromRGB(200,130,130)
        end
    end
end)


-- Parry cooldown (shared across all domains)
local parryCooldown = false
local function triggerParryCooldown(dur)
    parryCooldown = true
    task.delay(dur or 2, function() parryCooldown = false end)
end
-- Wrap holdParry to respect cooldown
local _origHoldParry = holdParry
holdParry = function()
    if parryCooldown then return end
    _origHoldParry()
end

-- ================================================================
--  GRIEF DOMAIN  (Despair's Domain)
-- ================================================================
-- Rain ambience (looping, persistent)
local griefRainSound = nil
local function startGriefRainSound()
    if griefRainSound then return end
    local s=Instance.new("Sound"); s.SoundId="rbxassetid://140237752767800"
    s.Volume=0.4; s.Looped=true; s.RollOffMaxDistance=9999
    s.Parent=workspace; s:Play()
    griefRainSound=s
end
local function stopGriefRainSound()
    if griefRainSound then griefRainSound:Stop(); griefRainSound:Destroy(); griefRainSound=nil end
end

-- Grief forward declarations
local onFloorEntered
local buildRegret
local buildFallen
local buildGriefBeacon
local runBeaconCutscene
local materializeExitPath
local runFogEvent


local GTOW_ORIGIN  = Vector3.new(-200, 0, 0)  -- tower world origin
local FLOOR_H      = 14   -- height per floor
local TOW_W        = 50
local TOW_D        = 60
local WIN_W        = 12   -- window width
local WIN_H        = 6    -- window height (Y: 4 to 10 in floor-local space)
local GRIEF_SPEED  = 30

-- Grief state
local griefActive    = false
local griefConn      = nil
local griefFloors    = {}  -- [floorIdx] -> {folder, parts}
local griefFloorCount= 0
local currentFloor   = 1
local floodY         = GTOW_ORIGIN.Y + FLOOR_H - 2.5  -- starts just below floor 1
local floodPart      = nil
local floodRising    = false
local floodRate      = FLOOR_H / 7  -- studs per second
local fallens        = {}  -- array of fallen entity tables
local maxFallens     = 5
local rainPart       = nil
local rainEmitter    = nil
local griefFogConn   = nil

-- Fog thickening event
local fogEventActive  = false
-- Regret event
local regretActive    = false
local regretParts     = {}
local regretConn      = nil

-- Beacon
local beaconTriggered  = false
local beaconComplete   = false

-- Floor entry tracking (to prevent multi-trigger)
local lastFloorTrigger = 0

-- ── Tower floor builder ─────────────────────────────────────
local function gFloorOrigin(floorIdx)
    return GTOW_ORIGIN + Vector3.new(0, (floorIdx-1)*FLOOR_H, 0)
end

local function buildWindow(parent, wallPart1, wallPart2, wallPart3, wallPart4)
    -- wallParts: used structurally, not really needed here
end

-- Build a single floor, returns folder + table of key parts
local function buildGriefFloor(floorIdx)
    if griefFloors[floorIdx] then return end
    local f   = Instance.new("Folder"); f.Name="GFloor_"..floorIdx; f.Parent=workspace
    local o   = gFloorOrigin(floorIdx)
    local cx  = GTOW_ORIGIN.X
    local cz  = GTOW_ORIGIN.Z
    local hw  = TOW_W/2
    local hd  = TOW_D/2
    local parts = {}

    local function gp(name,sz,pos,col,mat,trans,collide)
        local p=makePart(name,sz,pos,col,mat or Enum.Material.SmoothPlastic,trans or 0,collide,f)
        table.insert(parts,p); return p
    end

    local WC = Color3.fromRGB(55,55,65)
    local FC = Color3.fromRGB(45,45,55)

    -- Floor slab
    gp("FloorSlab",Vector3.new(TOW_W,1,TOW_D),Vector3.new(cx,o.Y-0.5,cz),FC)

    -- 4 walls with windows: N/S/E/W
    -- Each wall: bottom strip + top strip + left panel + right panel
    -- N wall (Z = -hd)
    local wz_n = cz - hd - 0.5
    gp("NWallBot",Vector3.new(TOW_W,WIN_H-2,1),Vector3.new(cx,o.Y+2,wz_n),WC)
    gp("NWallTop",Vector3.new(TOW_W,FLOOR_H-WIN_H-2,1),Vector3.new(cx,o.Y+WIN_H+2,wz_n),WC)
    gp("NWallWL", Vector3.new((TOW_W-WIN_W)/2,WIN_H,1),Vector3.new(cx-(WIN_W/2+(TOW_W-WIN_W)/4),o.Y+WIN_H/2+2,wz_n),WC)
    gp("NWallWR", Vector3.new((TOW_W-WIN_W)/2,WIN_H,1),Vector3.new(cx+(WIN_W/2+(TOW_W-WIN_W)/4),o.Y+WIN_H/2+2,wz_n),WC)
    -- S wall
    local wz_s = cz + hd + 0.5
    gp("SWallBot",Vector3.new(TOW_W,WIN_H-2,1),Vector3.new(cx,o.Y+2,wz_s),WC)
    gp("SWallTop",Vector3.new(TOW_W,FLOOR_H-WIN_H-2,1),Vector3.new(cx,o.Y+WIN_H+2,wz_s),WC)
    gp("SWallWL", Vector3.new((TOW_W-WIN_W)/2,WIN_H,1),Vector3.new(cx-(WIN_W/2+(TOW_W-WIN_W)/4),o.Y+WIN_H/2+2,wz_s),WC)
    gp("SWallWR", Vector3.new((TOW_W-WIN_W)/2,WIN_H,1),Vector3.new(cx+(WIN_W/2+(TOW_W-WIN_W)/4),o.Y+WIN_H/2+2,wz_s),WC)
    -- E wall (X = +hw)
    local wx_e = cx + hw + 0.5
    gp("EWallBot",Vector3.new(1,WIN_H-2,TOW_D),Vector3.new(wx_e,o.Y+2,cz),WC)
    gp("EWallTop",Vector3.new(1,FLOOR_H-WIN_H-2,TOW_D),Vector3.new(wx_e,o.Y+WIN_H+2,cz),WC)
    gp("EWallWL", Vector3.new(1,WIN_H,(TOW_D-WIN_W)/2),Vector3.new(wx_e,o.Y+WIN_H/2+2,cz-(WIN_W/2+(TOW_D-WIN_W)/4)),WC)
    gp("EWallWR", Vector3.new(1,WIN_H,(TOW_D-WIN_W)/2),Vector3.new(wx_e,o.Y+WIN_H/2+2,cz+(WIN_W/2+(TOW_D-WIN_W)/4)),WC)
    -- W wall
    local wx_w = cx - hw - 0.5
    gp("WWallBot",Vector3.new(1,WIN_H-2,TOW_D),Vector3.new(wx_w,o.Y+2,cz),WC)
    gp("WWallTop",Vector3.new(1,FLOOR_H-WIN_H-2,TOW_D),Vector3.new(wx_w,o.Y+WIN_H+2,cz),WC)
    gp("WWallWL", Vector3.new(1,WIN_H,(TOW_D-WIN_W)/2),Vector3.new(wx_w,o.Y+WIN_H/2+2,cz-(WIN_W/2+(TOW_D-WIN_W)/4)),WC)
    gp("WWallWR", Vector3.new(1,WIN_H,(TOW_D-WIN_W)/2),Vector3.new(wx_w,o.Y+WIN_H/2+2,cz+(WIN_W/2+(TOW_D-WIN_W)/4)),WC)

    -- Ceiling
    gp("Ceiling",Vector3.new(TOW_W,1,TOW_D),Vector3.new(cx,o.Y+FLOOR_H-0.5,cz),FC)

    -- Stair: series of step Parts from floor level to ceiling
    if floorIdx < 50 then
        local rampX = cx - hw + 7
        local stepCount = 8
        local stepW = 10
        local stepD = (TOW_D * 0.7) / stepCount
        for si = 0, stepCount-1 do
            local stepY = o.Y + (si/stepCount)*FLOOR_H + 0.5
            local stepZ = cz - TOW_D*0.35 + si*stepD + stepD/2
            local step = gp("Step_"..floorIdx.."_"..si, Vector3.new(stepW, 1, stepD+0.2),
                Vector3.new(rampX, stepY, stepZ), Color3.fromRGB(65,55,45))
        end
        -- Hole in ceiling: we make ceiling transparent in stair area (leave opening)
        -- The ceiling slab covers everything; we remove it and add 3 smaller slabs leaving a gap
        -- Delete the full ceiling and replace with 3 panels
        if f:FindFirstChild("Ceiling") then f:FindFirstChild("Ceiling"):Destroy() end
        -- Ceiling with stair hole: 4 panels around the opening
        local openZ1 = cz - TOW_D*0.35
        local openZ2 = openZ1 + stepCount*stepD
        local openXL = rampX - stepW/2
        local openXR = rampX + stepW/2
        -- Left of hole
        if openXL > cx-hw then
            gp("CeilHL",Vector3.new(openXL-(cx-hw),1,TOW_D),Vector3.new((cx-hw+openXL)/2,o.Y+FLOOR_H-0.5,cz),FC)
        end
        -- Right of hole
        if openXR < cx+hw then
            gp("CeilHR",Vector3.new((cx+hw)-openXR,1,TOW_D),Vector3.new((openXR+cx+hw)/2,o.Y+FLOOR_H-0.5,cz),FC)
        end
        -- Front of hole
        if openZ1 > cz-TOW_D/2 then
            gp("CeilHF",Vector3.new(stepW,1,openZ1-(cz-TOW_D/2)),Vector3.new(rampX,o.Y+FLOOR_H-0.5,(cz-TOW_D/2+openZ1)/2),FC)
        end
        -- Back of hole
        if openZ2 < cz+TOW_D/2 then
            gp("CeilHB",Vector3.new(stepW,1,(cz+TOW_D/2)-openZ2),Vector3.new(rampX,o.Y+FLOOR_H-0.5,(openZ2+cz+TOW_D/2)/2),FC)
        end
        -- Hole blocker (invisible, toggled closed during events)
        local blocker=Instance.new("Part"); blocker.Name="StairBlocker_"..floorIdx
        blocker.Size=Vector3.new(stepW,1,openZ2-openZ1)
        blocker.Position=Vector3.new(rampX,o.Y+FLOOR_H-0.5,(openZ1+openZ2)/2)
        blocker.Anchored=true; blocker.CanCollide=false; blocker.Transparency=1
        blocker.Material=Enum.Material.SmoothPlastic; blocker.Color=FC
        blocker.CastShadow=false; blocker.Parent=f
        table.insert(parts, blocker)
    end

    -- Ambient light
    local fl = f:FindFirstChild("FloorSlab")
    if fl then
        local pl=Instance.new("PointLight"); pl.Brightness=1.2; pl.Range=55
        pl.Color=Color3.fromRGB(140,140,160); pl.Parent=fl
    end

    -- Decoration (3 random variations)
    local decType = math.random(1,3)
    if decType == 1 then
        -- Candles on E wall ledge
        for i=-1,1 do
            local cp=gp("Candle",Vector3.new(0.5,2,0.5),Vector3.new(wx_e-1.5,o.Y+3,cz+i*8),Color3.fromRGB(255,200,80),Enum.Material.Neon)
            local cl=Instance.new("PointLight"); cl.Brightness=2; cl.Range=10; cl.Color=Color3.fromRGB(255,180,60); cl.Parent=cp
        end
    elseif decType == 2 then
        -- Bookshelf-style blocks on S wall
        for i=0,3 do
            gp("Shelf",Vector3.new(8,0.5,2),Vector3.new(cx-12+i*8,o.Y+2+i*2.2,wz_s-2),Color3.fromRGB(70,50,30))
        end
    else
        -- Rug on floor center
        gp("Rug",Vector3.new(18,0.2,24),Vector3.new(cx,o.Y+0.1,cz),Color3.fromRGB(80,40,40))
    end

    -- Floor entry trigger zone (top of stair area)
    local triggerY = o.Y + 1
    local entryPart = Instance.new("Part"); entryPart.Name="FloorEntry_"..floorIdx
    entryPart.Size=Vector3.new(TOW_W,2,TOW_D); entryPart.Position=Vector3.new(cx,triggerY+1,cz)
    entryPart.Anchored=true; entryPart.CanCollide=false; entryPart.Transparency=1; entryPart.Parent=f

    local triggered = false
    entryPart.Touched:Connect(function(hit)
        if hit.Parent~=player.Character then return end
        if triggered then return end
        if tick()-lastFloorTrigger < 1 then return end
        triggered = true; lastFloorTrigger = tick()
        task.delay(2, function() triggered = false end)
        onFloorEntered(floorIdx)
    end)

    griefFloors[floorIdx] = {folder=f, parts=parts, stairDestroyed=false}
    griefFloorCount = math.max(griefFloorCount, floorIdx)
end

-- ── Flood ───────────────────────────────────────────────────
local function buildFlood()
    if floodPart then return end
    local cx = GTOW_ORIGIN.X; local cz = GTOW_ORIGIN.Z
    floodPart = Instance.new("Part"); floodPart.Name="GriefFlood"
    floodPart.Size=Vector3.new(400, 4, 400)
    floodPart.Position=Vector3.new(cx, floodY, cz)
    floodPart.Anchored=true; floodPart.CanCollide=false
    floodPart.Material=Enum.Material.Neon
    floodPart.Color=Color3.fromRGB(70,75,85); floodPart.Transparency=0.35
    floodPart.CastShadow=false; floodPart.Parent=workspace
end

-- ── Rain ────────────────────────────────────────────────────
local function buildRain()
    rainPart = Instance.new("Part"); rainPart.Name="GriefRain"
    rainPart.Size=Vector3.new(1,1,1); rainPart.Anchored=true
    rainPart.CanCollide=false; rainPart.Transparency=1; rainPart.Parent=workspace
    local pe = Instance.new("ParticleEmitter")
    pe.Name="RainEmit"
    pe.Texture="rbxasset://textures/particles/smoke_main.dds"
    pe.Rate=300; pe.Lifetime=NumberRange.new(0.6,1.0)
    pe.Speed=NumberRange.new(55,70)
    pe.SpreadAngle=Vector2.new(3,3)
    pe.Rotation=NumberRange.new(0,0); pe.RotSpeed=NumberRange.new(0,0)
    pe.Size=NumberSequence.new{NumberSequenceKeypoint.new(0,0.08,0),NumberSequenceKeypoint.new(1,0.06,0)}
    pe.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(140,155,175)),ColorSequenceKeypoint.new(1,Color3.fromRGB(100,115,130))}
    pe.LightEmission=0.15; pe.LightInfluence=0.8
    pe.VelocityInheritance=0
    -- Direction: straight down
    local att=Instance.new("Attachment"); att.WorldCFrame=CFrame.new(0,0,0)
    att.Parent=rainPart; pe.Parent=rainPart
    rainEmitter = pe
end

-- ── Regret (giant worm) ──────────────────────────────────────
buildRegret = function(floorIdx)
    if regretActive then return end
    regretActive = true
    regretParts  = {}
    playSound("139902269912848", workspace, 1.2)
    local o      = gFloorOrigin(floorIdx)
    local cx     = GTOW_ORIGIN.X; local cz = GTOW_ORIGIN.Z
    local hw     = TOW_W/2

    -- Worm segments (outside tower, orbiting)
    for i=1,8 do
        local seg = Instance.new("Part"); seg.Name="RegretSeg_"..i
        seg.Size=Vector3.new(6,6,6); seg.Shape=Enum.PartType.Ball
        seg.Anchored=true; seg.CanCollide=false
        seg.Material=Enum.Material.Neon; seg.Color=Color3.fromRGB(120,20,20)
        seg.CastShadow=false; seg.Parent=workspace
        local hl=Instance.new("Highlight"); hl.Adornee=seg
        hl.OutlineColor=Color3.fromRGB(255,30,0); hl.FillColor=Color3.fromRGB(180,0,0)
        hl.FillTransparency=0.3; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=seg
        table.insert(regretParts,seg)
    end

    -- Red ESP on current floor and adjacent
    for _,fi in ipairs({floorIdx-1, floorIdx, floorIdx+1}) do
        if griefFloors[fi] then
            for _,p in ipairs(griefFloors[fi].parts) do
                local hl2=Instance.new("Highlight"); hl2.Name="RegretHL"; hl2.Adornee=p
                hl2.OutlineColor=Color3.fromRGB(255,20,0); hl2.FillColor=Color3.fromRGB(200,0,0)
                hl2.FillTransparency=0.65; hl2.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl2.Parent=p
            end
        end
    end

    -- Close stair hole blocker during regret
    local stairBlocker = nil
    if griefFloors[floorIdx] then
        for _,p in ipairs(griefFloors[floorIdx].parts) do
            if p.Name == "StairBlocker_"..floorIdx then
                p.Transparency = 0.25; p.CanCollide = true; stairBlocker = p; break
            end
        end
    end

    local angle = 0
    regretConn = RunService.Heartbeat:Connect(function(dt)
        if not regretActive then regretConn:Disconnect(); return end
        angle = angle + dt * 1.2
        local radius = TOW_W * 0.7
        for i,seg in ipairs(regretParts) do
            if seg and seg.Parent then
                local a = angle + (i-1)*0.5
                local segY = o.Y + FLOOR_H*0.5 + math.sin(angle*0.8 + i*0.4)*FLOOR_H*0.3
                seg.Position=Vector3.new(cx+math.cos(a)*radius, segY, cz+math.sin(a)*radius)
            end
        end
    end)

    -- After 4s: eat floor (remove walls, keep stair)
    task.delay(4, function()
        -- Reopen stair hole
        if stairBlocker then stairBlocker.Transparency=1; stairBlocker.CanCollide=false end

        -- Remove wall parts on current floor (leave stair)
        if griefFloors[floorIdx] then
            for _,p in ipairs(griefFloors[floorIdx].parts) do
                if p and p.Parent then
                    local n=p.Name
                    if n:match("Wall") then p:Destroy() end
                end
            end
        end

        -- Remove ESP highlights
        for _,fi in ipairs({floorIdx-1,floorIdx,floorIdx+1}) do
            if griefFloors[fi] then
                for _,p in ipairs(griefFloors[fi].parts) do
                    if p and p.Parent then
                        local h=p:FindFirstChild("RegretHL"); if h then h:Destroy() end
                    end
                end
            end
        end

        -- Check if player still in danger zone
        local hrp=getHRP()
        if hrp then
            local py = hrp.Position.Y
            local myFloor = math.floor((py - GTOW_ORIGIN.Y) / FLOOR_H) + 1
            if myFloor == floorIdx then
                if isParrying then
                    -- Knock off tower
                    hrp.Anchored=false
                    hrp.AssemblyLinearVelocity=Vector3.new(math.random(-20,20),5,math.random(-20,20))
                    playSound("133245268132726", hrp, 1)
                else
                    -- Annihilate: scatter all body parts
                    local char=player.Character
                    if char then
                        for _,p in ipairs(char:GetDescendants()) do
                            if p:IsA("BasePart") then
                                p.Anchored=false
                                p.AssemblyLinearVelocity=Vector3.new(math.random(-40,40),math.random(20,50),math.random(-40,40))
                                TweenService:Create(p,TweenInfo.new(0.5),{Transparency=1}):Play()
                            end
                        end
                        local sndD=Instance.new("Sound"); sndD.SoundId="rbxassetid://139937016099100"; sndD.Volume=1; sndD.Parent=hrp; sndD:Play()
                        task.delay(0.3,function() local hum=getHum(); if hum then hum.Health=0 end end)
                    end
                end
            end
        end

        -- Despawn worm
        pcall(function() if regretConn then regretConn:Disconnect(); regretConn=nil end end)
        for _,seg in ipairs(regretParts) do if seg and seg.Parent then seg:Destroy() end end
        regretParts={}
        regretActive=false
    end)
end

-- ── Fog thickening event ─────────────────────────────────────
runFogEvent = function()
    if fogEventActive or beaconComplete then return end
    fogEventActive = true
    if griefRainSound then TweenService:Create(griefRainSound,TweenInfo.new(1.5),{Volume=1.2}):Play() end

    local origEnd   = Lighting.FogEnd
    local origColor = Lighting.FogColor

    -- Gradually thicken fog + shake
    TweenService:Create(Lighting:FindFirstChildOfClass("Atmosphere") or Lighting,
        TweenInfo.new(0),{}):Play()  -- placeholder
    Lighting.FogEnd = 20
    -- Close stair blockers during fog event
    local hrpFE=getHRP()
    if hrpFE then
        local curF=math.max(1,math.floor((hrpFE.Position.Y-GTOW_ORIGIN.Y)/FLOOR_H)+1)
        for fi=curF-1,curF+1 do
            if griefFloors[fi] then
                for _,p in ipairs(griefFloors[fi].parts) do
                    if p.Name:match("StairBlocker_") then p.Transparency=0.25; p.CanCollide=true end
                end
            end
        end
    end

    -- Shake during thick fog
    local shakeConn; shakeConn = RunService.Heartbeat:Connect(function(dt)
        if not fogEventActive then shakeConn:Disconnect(); return end
        doShake(2,0.3)
    end)

    -- After 4s fog turns red
    task.delay(4, function()
        Lighting.FogColor = Color3.fromRGB(160,10,10)

        -- Kill if player is in window opening
        local hrp=getHRP()
        if hrp then
            local px=hrp.Position.X; local pz=hrp.Position.Z
            local cx=GTOW_ORIGIN.X; local cz_t=GTOW_ORIGIN.Z
            local hw=TOW_W/2; local hd=TOW_D/2
            local py_rel = (hrp.Position.Y - GTOW_ORIGIN.Y) % FLOOR_H
            local inWindowHeight = (py_rel >= 4 and py_rel <= 10)
            local nearEdge = (math.abs(px-cx) > hw-3) or (math.abs(pz-cz_t) > hd-3)
            if inWindowHeight and nearEdge then
                local hum=getHum(); if hum then
                    local dhrp2=getHRP(); if dhrp2 then playSound("137673547776909",dhrp2,1) end
                    hum.Health=0
                end
            end
        end

        -- 2s later: fog back to grey
        task.delay(2, function()
            pcall(function() shakeConn:Disconnect() end)
            TweenService:Create(Lighting,TweenInfo.new(1.5),{FogColor=origColor, FogEnd=origEnd}):Play()
            if griefRainSound then TweenService:Create(griefRainSound,TweenInfo.new(1.5),{Volume=0.4}):Play() end
            -- Reopen stair blockers
            for _,fd in pairs(griefFloors) do
                for _,p in ipairs(fd.parts) do
                    if p and p.Parent and p.Name:match("StairBlocker_") then
                        p.Transparency=1; p.CanCollide=false
                    end
                end
            end
            fogEventActive = false
        end)
    end)
end

-- ── Fallen entity ─────────────────────────────────────────────
buildFallen = function(pos)
    local f=Instance.new("Folder"); f.Name="Fallen"; f.Parent=workspace
    local skin=Color3.fromRGB(90,110,130)
    local dark=Color3.fromRGB(50,60,75)

    local function fp(name,sz,cf,col,trans)
        local p=Instance.new("Part"); p.Name=name; p.Size=sz; p.CFrame=cf
        p.Anchored=true; p.CanCollide=false
        p.Color=col; p.Transparency=trans or 0
        p.Material=Enum.Material.SmoothPlastic; p.CastShadow=false; p.Parent=f
        return p
    end

    local root=fp("Root",Vector3.new(0.1,0.1,0.1),CFrame.new(pos),Color3.new(0,0,0),0.999)
    fp("Torso",   Vector3.new(2,2,1),  CFrame.new(pos),              skin)
    fp("Head",    Vector3.new(2,1,1),  CFrame.new(pos+Vector3.new(0,1.5,0)), Color3.fromRGB(70,90,100))
    fp("LAr",     Vector3.new(1,2,1),  CFrame.new(pos+Vector3.new(-1.5,0,0)),dark)
    fp("RAr",     Vector3.new(1,2,1),  CFrame.new(pos+Vector3.new( 1.5,0,0)),dark)
    fp("LLg",     Vector3.new(1,2,1),  CFrame.new(pos+Vector3.new(-0.5,-2,0)),dark)
    fp("RLg",     Vector3.new(1,2,1),  CFrame.new(pos+Vector3.new( 0.5,-2,0)),dark)

    -- Watery ESP
    local hl=Instance.new("Highlight"); hl.Adornee=root
    hl.OutlineColor=Color3.fromRGB(80,120,180); hl.FillColor=Color3.fromRGB(40,80,140)
    hl.FillTransparency=0.4; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=root

    local health=90
    local speed=20
    local knockbackConn=nil

    local ent = {
        folder=f, root=root, health=health, speed=speed,
        hbConn=nil, dead=false, knockedBack=false
    }

    -- Setpos helper
    local function setPos(newPos)
        if not f.Parent then return end
        local off=newPos-root.CFrame.Position
        for _,p in ipairs(f:GetDescendants()) do
            if p:IsA("BasePart") then p.CFrame=p.CFrame+off end
        end
    end

    ent.hbConn=RunService.Heartbeat:Connect(function(dt)
        if ent.dead then return end
        if not f.Parent then return end
        local hrp=getHRP(); if not hrp then return end
        if ent.knockedBack then return end

        -- Move toward player
        local cur=root.CFrame.Position
        local tgt=hrp.Position
        local diff=tgt-cur; local dist=diff.Magnitude
        if dist>0.5 then
            setPos(cur+diff.Unit*math.min(speed*dt,dist))
        end

        -- Face player (yaw only)
        if dist>0.5 then
            local faceCF=CFrame.new(cur,Vector3.new(tgt.X,cur.Y,tgt.Z))
            local dy=math.atan2(-faceCF.LookVector.X,-faceCF.LookVector.Z)
                   - math.atan2(-root.CFrame.LookVector.X,-root.CFrame.LookVector.Z)
            dy=((dy+math.pi)%(math.pi*2))-math.pi
            if math.abs(dy)>0.01 then
                local c2,s2=math.cos(dy),math.sin(dy)
                local orig=root.CFrame.Position
                for _,p in ipairs(f:GetDescendants()) do
                    if p:IsA("BasePart") then
                        local lp=p.CFrame.Position-orig
                        local rx=lp.X*c2-lp.Z*s2; local rz=lp.X*s2+lp.Z*c2
                        p.CFrame=CFrame.new(orig+Vector3.new(rx,lp.Y,rz))*CFrame.Angles(0,dy,0)
                    end
                end
            end
        end

        -- Hit player
        if dist<3.2 then
            local hum=getHum(); if hum and hum.Health>0 then
                hum.Health=math.max(0.1,hum.Health-20*dt)
                if math.random()<0.04 then playSound("76525344270919", root, 0.8) end
            end
        end

        -- Parry
        if isParrying and dist<5 then
            ent.health=ent.health-30
            if ent.health<=0 then
                ent.dead=true; ent.hbConn:Disconnect()
                TweenService:Create(root,TweenInfo.new(0.4),{Transparency=1}):Play()
                task.delay(0.45,function() if f.Parent then f:Destroy() end end)
                for i,e in ipairs(fallens) do if e==ent then table.remove(fallens,i); break end end
                return
            end
            ent.knockedBack=true
            local away=(cur-tgt).Unit
            task.spawn(function()
                for _=1,15 do
                    if not ent.knockedBack then break end
                    setPos(root.CFrame.Position+away*2)
                    task.wait(0.04)
                end
                ent.knockedBack=false
            end)
        end
    end)

    table.insert(fallens, ent)
    return ent
end

-- ── Floor enter callback ─────────────────────────────────────
onFloorEntered = function(floorIdx)
    if not griefActive then return end
    currentFloor = floorIdx

    -- Generate next 2 floors
    for i=floorIdx,floorIdx+2 do
        if not griefFloors[i] and i<=50 then buildGriefFloor(i) end
    end

    -- Start flood rising on floor 2+
    if floorIdx >= 2 then floodRising = true end

    -- Update flood rate (faster after floor 10)
    if floorIdx >= 10 then floodRate = FLOOR_H / 5 end

    -- 45% fog event
    if math.random() <= 0.45 and floorIdx > 1 then
        task.delay(1, runFogEvent)
    end

    -- 50% Regret (worm) on floors 2+
    if math.random() <= 0.50 and floorIdx >= 2 and not regretActive then
        task.delay(2, function()
            if griefActive and not beaconComplete then buildRegret(floorIdx) end
        end)
    end

    -- Spawn Fallen on floor 13+
    if floorIdx >= 13 then
        local cap = floorIdx >= 20 and 10 or 5
        if math.random() <= 0.50 and #fallens < cap then
            local spawnPos = Vector3.new(
                GTOW_ORIGIN.X + math.random(-18,18),
                floodY + 2,
                GTOW_ORIGIN.Z + math.random(-20,20)
            )
            buildFallen(spawnPos)
        end
    end

    -- Floor 30: Beacon
    if floorIdx == 30 and not beaconTriggered then
        buildGriefBeacon()
    end
end

-- ── Beacon ───────────────────────────────────────────────────
buildGriefBeacon = function()
    beaconTriggered=true
    local cx=GTOW_ORIGIN.X; local cz=GTOW_ORIGIN.Z
    local o=gFloorOrigin(30)

    -- Beacon pillar in center of floor 30 (exposed, no roof above it)
    local beacon=Instance.new("Part"); beacon.Name="GriefBeacon"
    beacon.Size=Vector3.new(3,8,3); beacon.Position=Vector3.new(cx,o.Y+4,cz)
    beacon.Anchored=true; beacon.CanCollide=false
    beacon.Material=Enum.Material.Neon; beacon.Color=Color3.fromRGB(255,240,180)
    beacon.CastShadow=false; beacon.Parent=workspace
    local bl=Instance.new("PointLight"); bl.Brightness=8; bl.Range=40
    bl.Color=Color3.fromRGB(255,240,180); bl.Parent=beacon

    local pp=Instance.new("ProximityPrompt"); pp.ActionText="Activate Beacon"
    pp.MaxActivationDistance=10; pp.HoldDuration=20; pp.RequiresLineOfSight=false
    pp.ObjectText="Beacon of Light"; pp.Parent=beacon

    pp.Triggered:Connect(function()
        if beaconComplete then return end
        beaconComplete=true
        runBeaconCutscene(beacon, o)
    end)

    -- Pulse
    task.spawn(function()
        while beacon and beacon.Parent and not beaconComplete do
            TweenService:Create(beacon,TweenInfo.new(0.8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
                {Size=Vector3.new(3.8,8.8,3.8)}):Play()
            task.wait(0.85)
            if not (beacon and beacon.Parent) then break end
            TweenService:Create(beacon,TweenInfo.new(0.8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
                {Size=Vector3.new(3,8,3)}):Play()
            task.wait(0.85)
        end
    end)
end

runBeaconCutscene = function(beacon, floorOrigin)
    local cam=workspace.CurrentCamera
    local hum=getHum(); if hum then hum.WalkSpeed=0; hum.JumpPower=0 end

    -- Frog perspective: camera at floor level looking up at beacon
    local beaconPos=beacon.Position
    cam.CameraType=Enum.CameraType.Scriptable
    local lookPos=beaconPos+Vector3.new(0,20,0)
    cam.CFrame=CFrame.new(beaconPos+Vector3.new(0,-4,8), lookPos)

    -- Slowly pan upward over 5s
    TweenService:Create(cam,TweenInfo.new(5,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut),
        {CFrame=CFrame.new(beaconPos+Vector3.new(0,2,6), lookPos)}):Play()

    -- Beacon grows massively
    task.delay(4,function()
        TweenService:Create(beacon,TweenInfo.new(1.5),{Size=Vector3.new(40,120,40)}):Play()
        local bl=beacon:FindFirstChildOfClass("PointLight")
        if bl then TweenService:Create(bl,TweenInfo.new(1.5),{Brightness=50,Range=300}):Play() end
    end)

    -- White blind flash at 5s
    task.delay(5,function()
        local flashGui=Instance.new("ScreenGui"); flashGui.Name="BeaconFlash"
        flashGui.ResetOnSpawn=false; flashGui.Parent=player.PlayerGui
        local ff=Instance.new("Frame"); ff.Size=UDim2.new(1,0,1,0)
        ff.BackgroundColor3=Color3.new(1,1,1); ff.BackgroundTransparency=0; ff.BorderSizePixel=0; ff.Parent=flashGui

        -- Fog → yellow, stop rain & flood
        Lighting.FogColor=Color3.fromRGB(255,240,100); Lighting.FogEnd=200
        floodRising=false
        if rainEmitter then rainEmitter.Enabled=false end

        -- Victory text
        task.delay(0.3,function()
            showVictoryText()
        end)

        -- Fade flash
        TweenService:Create(ff,TweenInfo.new(2.5),{BackgroundTransparency=1}):Play()
        task.delay(2.6,function() if flashGui and flashGui.Parent then flashGui:Destroy() end end)

        -- Return camera to player at 8s
        task.delay(3,function()
            cam.CameraType=Enum.CameraType.Custom
            local hum2=getHum(); if hum2 then hum2.WalkSpeed=GRIEF_SPEED; hum2.JumpPower=50 end

            -- Materialize path from floor 30
            task.delay(0.5,function() materializeExitPath(floorOrigin) end)
        end)
    end)
end

materializeExitPath = function(floorOrigin)
    local cx=GTOW_ORIGIN.X; local cz_t=GTOW_ORIGIN.Z
    local pY=floorOrigin.Y+0.5
    local pathFolder=Instance.new("Folder"); pathFolder.Name="ExitPath"; pathFolder.Parent=workspace

    -- Path: series of floating platforms extending south from tower
    for i=1,12 do
        local pz=cz_t+TOW_D/2 + i*8
        local seg=Instance.new("Part"); seg.Name="PathSeg_"..i
        seg.Size=Vector3.new(8,1,7); seg.Position=Vector3.new(cx,pY,pz)
        seg.Anchored=true; seg.CanCollide=true
        seg.Material=Enum.Material.Neon; seg.Color=Color3.fromRGB(255,235,80)
        seg.Transparency=1; seg.CastShadow=false; seg.Parent=pathFolder

        local hl=Instance.new("Highlight"); hl.Adornee=seg
        hl.OutlineColor=Color3.fromRGB(255,200,50); hl.FillColor=Color3.fromRGB(200,160,0)
        hl.FillTransparency=0.3; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=seg

        task.delay(i*0.15,function()
            TweenService:Create(seg,TweenInfo.new(0.6),{Transparency=0.05}):Play()
        end)
    end

    -- Portal at end of path
    task.delay(12*0.15+1,function()
        local portalZ=cz_t+TOW_D/2+12*8+5
        local port=Instance.new("Part"); port.Name="GriefPortal"
        port.Size=Vector3.new(9,14,2); port.Position=Vector3.new(cx,pY+7,portalZ)
        port.Anchored=true; port.CanCollide=false
        port.Material=Enum.Material.Neon; port.Color=Color3.fromRGB(120,0,255)
        port.CastShadow=false; port.Parent=workspace
        local phl=Instance.new("Highlight"); phl.Adornee=port
        phl.OutlineColor=Color3.fromRGB(160,60,255); phl.FillColor=Color3.fromRGB(90,0,200)
        phl.FillTransparency=0.25; phl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; phl.Parent=port
        local ppl=Instance.new("PointLight"); ppl.Brightness=10; ppl.Range=35; ppl.Color=Color3.fromRGB(120,0,255); ppl.Parent=port

        local ptc; ptc=port.Touched:Connect(function(hit)
            if hit.Parent~=player.Character then return end
            ptc:Disconnect(); port:Destroy(); pathFolder:Destroy()
            griefActive=false
            restoreFog(); floodRising=false
            if rainEmitter then rainEmitter.Enabled=false end
            stopGriefRainSound()
            local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(safeSpawnPos) end
            hudLbl.Text="Grief Domain Clear!"
            hudLbl.TextColor3=Color3.fromRGB(100,255,100)
            selectedDomain=nil
        end)
    end)
end

-- ── Grief domain main ─────────────────────────────────────────
local function startGriefDomain()
    griefActive=true; griefFloors={}; griefFloorCount=0
    currentFloor=1; floodRising=false; fallens={}; regretActive=false
    fogEventActive=false; beaconTriggered=false; beaconComplete=false
    lastFloorTrigger=0; floodY=GTOW_ORIGIN.Y+FLOOR_H-2.5

    -- Fog: grey, moderately thick
    Lighting.FogColor=Color3.fromRGB(130,135,145); Lighting.FogStart=12; Lighting.FogEnd=90
    Lighting.Brightness=0.3; Lighting.OutdoorAmbient=Color3.fromRGB(60,62,68)
    Lighting.Ambient=Color3.fromRGB(40,42,48)

    -- Spawn player at floor 1 center
    local cx=GTOW_ORIGIN.X; local cz_t=GTOW_ORIGIN.Z
    local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(cx,GTOW_ORIGIN.Y+2,cz_t) end
    local hum=getHum(); if hum then hum.WalkSpeed=GRIEF_SPEED; hum.JumpPower=50 end

    -- Build first 2 floors
    buildGriefFloor(1); buildGriefFloor(2)

    -- Build flood
    buildFlood()

    -- Build rain
    buildRain()

    hudLbl.Text="Grief  -  Floor 1"; hudLbl.TextColor3=Color3.fromRGB(150,165,185)

    -- Start rain ambience
    startGriefRainSound()

    -- Main loop
    griefConn=RunService.Heartbeat:Connect(function(dt)
        if not griefActive then griefConn:Disconnect(); griefConn=nil; return end

        local hrp2=getHRP(); if not hrp2 then return end

        -- Update rain position
        if rainPart then
            rainPart.Position=Vector3.new(hrp2.Position.X, hrp2.Position.Y+70, hrp2.Position.Z)
        end

        -- Flood rising
        if floodRising and not beaconComplete then
            floodY=floodY+floodRate*dt
            if floodPart then
                floodPart.Position=Vector3.new(floodPart.Position.X, floodY, floodPart.Position.Z)
            end
            -- Flood damage
            if hrp2.Position.Y <= floodY+2 then
                local hum2=getHum()
                if hum2 and hum2.Health>0 then hum2.Health=math.max(0.1,hum2.Health-10*dt) end
            end
        end

        -- Update floor HUD
        local py=hrp2.Position.Y
        local floor_now=math.max(1,math.floor((py-GTOW_ORIGIN.Y)/FLOOR_H)+1)
        if floor_now~=currentFloor then
            hudLbl.Text="Grief  -  Floor "..floor_now
        end

        -- Cleanup floors more than 4 below
        for idx,data in pairs(griefFloors) do
            if idx < floor_now-4 and data.folder and data.folder.Parent then
                data.folder:Destroy(); griefFloors[idx]=nil
            end
        end
    end)
end

-- Wire Grief button
local griefBtn=Instance.new("TextButton"); griefBtn.Size=UDim2.new(0,200,0,32)
griefBtn.Position=UDim2.new(0,315,0.5,-16); griefBtn.BackgroundColor3=Color3.fromRGB(12,12,28)
griefBtn.Text="Grief  |  Despair's Domain"; griefBtn.Font=Enum.Font.GothamBold; griefBtn.TextSize=13
griefBtn.TextColor3=Color3.fromRGB(120,140,200); griefBtn.BorderSizePixel=0; griefBtn.Parent=dsBar
Instance.new("UICorner",griefBtn).CornerRadius=UDim.new(0,6)
local gbs=Instance.new("UIStroke"); gbs.Color=Color3.fromRGB(80,100,200); gbs.Thickness=1.5; gbs.Parent=griefBtn

-- Widen domain bar for 2 buttons
dsBar.Size=UDim2.new(0,560,0,46)
dsBar.Position=UDim2.new(0.5,-280,0,8)

griefBtn.MouseButton1Click:Connect(function()
    if domainActive then return end
    selectedDomain="Grief"
    griefBtn.BackgroundColor3=Color3.fromRGB(25,25,55)
    griefBtn.TextColor3=Color3.fromRGB(180,200,255)
    frenzyBtn.BackgroundColor3=Color3.fromRGB(35,8,8)
    frenzyBtn.TextColor3=Color3.fromRGB(255,70,40)
    dsNotice.Text="READY"; dsNotice.TextColor3=Color3.fromRGB(100,255,120)
    hudLbl.Text="Grief selected - enter the door!"
    hudLbl.TextColor3=Color3.fromRGB(130,150,200)
end)

-- Update door handler to support Grief
-- (We need to patch the door touch - the saferoom door is already built above)
-- Re-patch by connecting a new signal that checks selectedDomain=="Grief"
-- The original door.Touched already handles "Frenzy" -- we modify the original startRound fallback logic
-- Instead: override via a separate variable checked in the door touch
-- This is handled by the selectedDomain variable already in the buildSaferoom door.Touched:
-- We need to update that function. Since it's already connected, add another branch:
local _griefDoorConn = nil
task.delay(1, function()
    -- Find the DoorTrigger
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj.Name=="Door" and obj.Parent and obj.Parent.Name=="Saferoom" then
            _griefDoorConn = obj.Touched:Connect(function(hit)
                if hit.Parent~=player.Character then return end
                if selectedDomain~="Grief" then return end
                if domainActive or griefActive then return end
                startGriefDomain()
            end)
            break
        end
    end
end)

-- ================================================================
--  nevaeH DOMAIN  (Saint's Domain)
-- ================================================================

-- Forward declarations
local nPhase
local nBelieverList
local nDeity
local nDeityActive
local nDeityEventConn
local runDeityEvent
local spawnBeliever
local startNPhase
local nShowVictory
local nExitCutscene

-- Constants
local NHV_ORIGIN   = Vector3.new(-600, 0, 0)
local NHV_SIZE     = 280      -- map radius (square half-side)
local NHV_TREE_H   = 120
local NHV_TREE_R   = 12
local NEVAEH_SPEED = 45

-- State
local nevaeHActive  = false
local nevaeHConn    = nil
local nPhase        = 1
local nStatuePrayed = 0
local nStatueGoal   = {3,5,7,10,20}  -- per phase
local nStatues      = {}  -- {part, fake, prayed, conn}
local nBelieverList = {}
local nDeityActive  = false
local nDeityConn    = nil
local nFallObjects  = {}
local nTreePart     = nil
local nDeityPart    = nil
local nAfterimages  = {}
local nGrassConn    = nil
local nFallConn     = nil
local nDeityFogConn = nil
local nPhaseFolder  = nil
local nMapFolder    = nil

-- Fog tween shortcut
local function setNFog(color, fstart, fend_val, dur)
    if dur and dur > 0 then
        TweenService:Create(Lighting, TweenInfo.new(dur), {
            FogColor=color, FogStart=fstart, FogEnd=fend_val
        }):Play()
    else
        Lighting.FogColor=color; Lighting.FogStart=fstart; Lighting.FogEnd=fend_val
    end
end

-- ── Map builder ──────────────────────────────────────────────
local function buildNevaeHMap()
    nMapFolder = Instance.new("Folder"); nMapFolder.Name="nevaeHMap"; nMapFolder.Parent=workspace
    local cx=NHV_ORIGIN.X; local cz=NHV_ORIGIN.Z; local hs=NHV_SIZE

    -- Ground base (grass)
    local grass=makePart("NBase",Vector3.new(hs*2,1,hs*2),Vector3.new(cx,-0.5,cz),
        Color3.fromRGB(45,110,45),Enum.Material.Grass,0,true,nMapFolder)

    -- Soil path: ring around tree (radius 35, width 10)
    local RING_R=35; local RING_SEGS=28
    for i=1,RING_SEGS do
        local a=(i/RING_SEGS)*math.pi*2
        local na=((i+1)/RING_SEGS)*math.pi*2
        local px=cx+math.cos(a)*RING_R; local pz=cz+math.sin(a)*RING_R
        local nx=cx+math.cos(na)*RING_R; local nz=cz+math.sin(na)*RING_R
        local mid=Vector3.new((px+nx)/2, 0.1, (pz+nz)/2)
        local len=(Vector3.new(px,0,pz)-Vector3.new(nx,0,nz)).Magnitude
        local seg=Instance.new("Part"); seg.Name="SoilRing"; seg.Size=Vector3.new(10,0.5,len+1)
        seg.CFrame=CFrame.new(mid)*CFrame.Angles(0,a+math.pi/2,0)
        seg.Anchored=true; seg.CanCollide=true; seg.Material=Enum.Material.SmoothPlastic
        seg.Color=Color3.fromRGB(100,70,40); seg.Parent=nMapFolder
    end

    -- 4 soil paths leading outward from ring
    local pathDirs={{1,0},{-1,0},{0,1},{0,-1}}
    for _,d in ipairs(pathDirs) do
        for step=0,10 do
            local dist=RING_R+10+step*22
            local px=cx+d[1]*dist; local pz=cz+d[2]*dist
            local seg=makePart("SoilPath",Vector3.new(10,0.5,22),
                Vector3.new(px,0.1,pz),Color3.fromRGB(100,70,40),Enum.Material.SmoothPlastic,0,true,nMapFolder)
            if d[1]~=0 then seg.Size=Vector3.new(22,0.5,10) end
        end
    end

    -- Soil patches scattered
    for i=1,35 do
        local a=math.random()*math.pi*2; local r=math.random(50,hs-20)
        local sp=makePart("SoilPatch",Vector3.new(math.random(8,18),0.5,math.random(8,18)),
            Vector3.new(cx+math.cos(a)*r,0.1,cz+math.sin(a)*r),
            Color3.fromRGB(110,75,45),Enum.Material.SmoothPlastic,0,true,nMapFolder)
    end

    -- Giant tree trunk
    nTreePart=makePart("NTree",Vector3.new(NHV_TREE_R*2,NHV_TREE_H,NHV_TREE_R*2),
        Vector3.new(cx,NHV_TREE_H/2,cz),Color3.fromRGB(60,35,18),Enum.Material.Wood,0,true,nMapFolder)
    nTreePart.Shape = Enum.PartType.Cylinder
    -- Rotate cylinder to be vertical
    nTreePart.CFrame = CFrame.new(cx,NHV_TREE_H/2,cz)*CFrame.Angles(0,0,math.pi/2)
    nTreePart.Size = Vector3.new(NHV_TREE_H,NHV_TREE_R*2,NHV_TREE_R*2)

    -- Tree canopy (big ball cluster)
    for i=1,5 do
        local a=math.random()*math.pi*2; local r=math.random(15,30)
        local bh=NHV_TREE_H+math.random(-10,20)
        local ball=makePart("Canopy_"..i,Vector3.new(math.random(30,55),math.random(25,40),math.random(30,55)),
            Vector3.new(cx+math.cos(a)*r,bh,cz+math.sin(a)*r),
            Color3.fromRGB(30,90,30),Enum.Material.Grass,0,false,nMapFolder)
        ball.Shape=Enum.PartType.Ball
    end
    -- Center canopy
    makePart("CanopyC",Vector3.new(60,45,60),Vector3.new(cx,NHV_TREE_H+18,cz),
        Color3.fromRGB(25,80,25),Enum.Material.Grass,0,false,nMapFolder)

    return nMapFolder
end

-- ── Statue builder ────────────────────────────────────────────
local function spawnStatue(isFake)
    local cx=NHV_ORIGIN.X; local cz_t=NHV_ORIGIN.Z; local hs=NHV_SIZE
    local pos
    if isFake then
        -- On grass (not soil - random position)
        local a=math.random()*math.pi*2; local r=math.random(55,hs-25)
        pos=Vector3.new(cx+math.cos(a)*r, 0.5, cz_t+math.sin(a)*r)
    else
        -- On soil paths/ring area
        local paths={{cx-120,cz_t},{cx+120,cz_t},{cx,cz_t-120},{cx,cz_t+120},
                     {cx-80,cz_t-80},{cx+80,cz_t+80},{cx-80,cz_t+80},{cx+80,cz_t-80}}
        local pick=paths[math.random(1,#paths)]
        pos=Vector3.new(pick[1]+math.random(-8,8),0.5,pick[2]+math.random(-8,8))
    end

    local f=Instance.new("Folder"); f.Name=isFake and "FakeStatue" or "Statue"; f.Parent=workspace
    local base=makePart("Base",Vector3.new(3,0.5,3),pos,Color3.fromRGB(160,150,140),nil,0,true,f)
    local pillar=makePart("Pillar",Vector3.new(1.5,4,1.5),pos+Vector3.new(0,2.25,0),Color3.fromRGB(160,150,140),nil,0,true,f)
    local head=makePart("Head",Vector3.new(2,2,2),pos+Vector3.new(0,5.5,0),Color3.fromRGB(180,170,160),nil,0,true,f)
    head.Shape=Enum.PartType.Ball

    local pp=Instance.new("ProximityPrompt"); pp.ActionText="Pray"
    pp.MaxActivationDistance=8; pp.HoldDuration=5; pp.RequiresLineOfSight=false
    pp.ObjectText=isFake and "???" or "Statue"; pp.Parent=base

    local sd={folder=f, base=base, fake=isFake, prayed=false, pp=pp}

    pp.Triggered:Connect(function()
        if sd.prayed then return end
        sd.prayed=true; pp:Destroy()
        if isFake then
            -- Red ESP for 3s then fade, 30 damage
            local hl=Instance.new("Highlight"); hl.Adornee=base
            hl.OutlineColor=Color3.fromRGB(255,20,0); hl.FillColor=Color3.fromRGB(200,0,0)
            hl.FillTransparency=0.4; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=base
            playSound("133245268132726",base,1)
            local hum=getHum(); if hum then hum.Health=math.max(0.1,hum.Health-30) end
            task.delay(3,function()
                TweenService:Create(hl,TweenInfo.new(0.5),{OutlineTransparency=1,FillTransparency=1}):Play()
                task.delay(0.6,function() if hl.Parent then hl:Destroy() end end)
            end)
        else
            -- Green ESP for 3s
            local hl=Instance.new("Highlight"); hl.Adornee=base
            hl.OutlineColor=Color3.fromRGB(0,255,60); hl.FillColor=Color3.fromRGB(0,200,40)
            hl.FillTransparency=0.4; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=base
            playSound("115937318685871",base,0.8)
            nStatuePrayed=nStatuePrayed+1
            local goal=nStatueGoal[nPhase] or 3
            hudLbl.Text="nevaeH - Statues: "..nStatuePrayed.."/"..goal
            task.delay(3,function()
                TweenService:Create(hl,TweenInfo.new(0.5),{OutlineTransparency=1,FillTransparency=1}):Play()
                task.delay(0.6,function() if hl.Parent then hl:Destroy() end end)
            end)
            -- Check phase complete
            if nStatuePrayed >= goal and nevaeHActive then
                task.delay(0.5,function() startNPhase(nPhase+1) end)
            end
        end
    end)

    table.insert(nStatues,sd)
    return sd
end

local function spawnNStatues(count, fakeCount)
    for i=1,count do spawnStatue(false) end
    for i=1,fakeCount do spawnStatue(true) end
end

local function clearNStatues()
    for _,sd in ipairs(nStatues) do
        if sd.folder and sd.folder.Parent then sd.folder:Destroy() end
    end
    nStatues={}
end

-- ── Deity ─────────────────────────────────────────────────────
local function buildDeity()
    if nDeityPart then return end
    local cx=NHV_ORIGIN.X; local cz_t=NHV_ORIGIN.Z
    local topY=NHV_TREE_H+55

    nDeityPart=Instance.new("Part"); nDeityPart.Name="Deity"
    nDeityPart.Size=Vector3.new(4,4,4); nDeityPart.Position=Vector3.new(cx,topY,cz_t)
    nDeityPart.Anchored=true; nDeityPart.CanCollide=false; nDeityPart.Transparency=1
    nDeityPart.CastShadow=false; nDeityPart.Parent=workspace

    local bb=Instance.new("BillboardGui"); bb.Name="DeityEye"
    bb.Size=UDim2.new(0,450,0,450); bb.StudsOffsetWorldSpace=Vector3.new(0,0,0)
    bb.AlwaysOnTop=true; bb.Parent=nDeityPart

    local root=Instance.new("Frame"); root.Size=UDim2.new(1,0,1,0)
    root.BackgroundTransparency=1; root.BorderSizePixel=0; root.Parent=bb

    -- Golden ring (halo)
    local halo=Instance.new("Frame"); halo.Size=UDim2.new(0,160,0,160)
    halo.Position=UDim2.new(0.5,-80,0.02,0); halo.BackgroundTransparency=1
    halo.BorderSizePixel=0; halo.Parent=root
    Instance.new("UICorner",halo).CornerRadius=UDim.new(1,0)
    local hs=Instance.new("UIStroke"); hs.Color=Color3.fromRGB(255,210,50); hs.Thickness=12; hs.Parent=halo

    -- Multiple wings (6 pairs, semi-transparent)
    local wingAngles={-80,-50,-20,20,50,80}
    for _,ang in ipairs(wingAngles) do
        for side=-1,1,2 do
            local w=Instance.new("Frame"); w.Size=UDim2.new(0,90,0,30)
            w.BackgroundColor3=Color3.fromRGB(240,230,180)
            w.BackgroundTransparency=0.45; w.BorderSizePixel=0
            local wx = 0.5 + side*0.22
            w.Position=UDim2.new(wx,-45,0.45,-15)
            w.Rotation=ang*side; w.Parent=root
            Instance.new("UICorner",w).CornerRadius=UDim.new(0.5,0)
        end
    end

    -- Eye container
    local eyeCon=Instance.new("Frame"); eyeCon.Name="DeityEyeCon"
    eyeCon.Size=UDim2.new(0,200,0,100); eyeCon.Position=UDim2.new(0.5,-100,0.5,-50)
    eyeCon.BackgroundTransparency=1; eyeCon.ClipsDescendants=true; eyeCon.Parent=root

    local eyeW=Instance.new("Frame"); eyeW.Size=UDim2.new(1,0,1,0)
    eyeW.BackgroundColor3=Color3.fromRGB(10,8,15); eyeW.Parent=eyeCon  -- black eye
    Instance.new("UICorner",eyeW).CornerRadius=UDim.new(0.5,0)

    local pupil=Instance.new("Frame"); pupil.Name="DeityPupil"
    pupil.Size=UDim2.new(0,50,0,50); pupil.Position=UDim2.new(0.5,-25,0.5,-25)
    pupil.BackgroundColor3=Color3.new(1,1,1); pupil.Parent=eyeW  -- white pupil
    Instance.new("UICorner",pupil).CornerRadius=UDim.new(1,0)

    -- Eyelids (start closed)
    local upperLid=Instance.new("Frame"); upperLid.Name="DUpperLid"
    upperLid.Size=UDim2.new(1,0,0.65,0); upperLid.Position=UDim2.new(0,0,-0.05,0)
    upperLid.BackgroundColor3=Color3.fromRGB(10,8,15); upperLid.ZIndex=5; upperLid.Parent=eyeCon
    Instance.new("UICorner",upperLid).CornerRadius=UDim.new(0.35,0)

    local lowerLid=Instance.new("Frame"); lowerLid.Name="DLowerLid"
    lowerLid.Size=UDim2.new(1,0,0.65,0); lowerLid.Position=UDim2.new(0,0,0.40,0)
    lowerLid.BackgroundColor3=Color3.fromRGB(10,8,15); lowerLid.ZIndex=5; lowerLid.Parent=eyeCon
    Instance.new("UICorner",lowerLid).CornerRadius=UDim.new(0.35,0)

    -- Wing flutter animation
    local wingT=0
    local wingConn=RunService.Heartbeat:Connect(function(dt)
        if not nDeityPart or not nDeityPart.Parent then return end
        wingT=wingT+dt*2.5
        for i,w in ipairs(root:GetChildren()) do
            if w:IsA("Frame") and w.Name=="" then
                local flut=math.sin(wingT*1.8+i*0.6)*12
                w.Rotation=w.Rotation+flut*dt*0.5
            end
        end
    end)
    nDeityPart.Destroying:Connect(function() pcall(function() wingConn:Disconnect() end) end)

    return nDeityPart, {upperLid=upperLid,lowerLid=lowerLid,pupil=pupil}
end

-- ── Deity event ───────────────────────────────────────────────
runDeityEvent = function(eyeParts)
    if not nDeityPart or not nevaeHActive then return end
    local open = math.random()<0.30
    if not open then return end  -- 30% chance

    -- Open lids
    TweenService:Create(eyeParts.upperLid,TweenInfo.new(0.5,Enum.EasingStyle.Back),
        {Position=UDim2.new(0,0,-0.9,0)}):Play()
    TweenService:Create(eyeParts.lowerLid,TweenInfo.new(0.5,Enum.EasingStyle.Back),
        {Position=UDim2.new(0,0,1.2,0)}):Play()

    nDeityActive=true
    local cam=workspace.CurrentCamera
    local cf0=cam.CFrame
    local camYaw=math.atan2(-cf0.LookVector.X,-cf0.LookVector.Z)
    local camPitch=math.asin(math.clamp(cf0.LookVector.Y,-1,1))
    local origType=cam.CameraType
    cam.CameraType=Enum.CameraType.Scriptable

    -- Make player invisible
    local function setCharVis(vis)
        local c=player.Character; if not c then return end
        for _,obj in ipairs(c:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Decal") then obj.LocalTransparencyModifier=vis and 0 or 1 end
        end
    end
    setCharVis(false)

    local PULL=0.06
    local gazeTime=0
    local evStart=tick()
    local EVT_DUR=6
    local origFogColor=Lighting.FogColor
    local origFogEnd=Lighting.FogEnd

    if nDeityConn then nDeityConn:Disconnect() end
    nDeityConn=RunService.Heartbeat:Connect(function(dt)
        if not nevaeHActive then nDeityConn:Disconnect(); return end
        local elapsed=tick()-evStart
        if elapsed>=EVT_DUR then
            nDeityConn:Disconnect(); nDeityConn=nil
            TweenService:Create(eyeParts.upperLid,TweenInfo.new(0.4),{Position=UDim2.new(0,0,-0.05,0)}):Play()
            TweenService:Create(eyeParts.lowerLid,TweenInfo.new(0.4),{Position=UDim2.new(0,0,0.40,0)}):Play()
            cam.CameraType=origType; setCharVis(true)
            setNFog(origFogColor, 15, origFogEnd, 2)
            nDeityActive=false
            return
        end

        local hrp=getHRP(); if not hrp then return end
        local headPos=hrp.Position+Vector3.new(0,2,0)
        local deityPos=nDeityPart.Position
        local toD=(deityPos-headPos)
        if toD.Magnitude<0.1 then return end; toD=toD.Unit

        local delta=UIS:GetMouseDelta()
        camYaw=camYaw-delta.X*0.0025
        camPitch=math.clamp(camPitch-delta.Y*0.0025,-1.4,1.4)

        local tYaw=math.atan2(-toD.X,-toD.Z)
        local tPitch=math.asin(math.clamp(toD.Y,-1,1))
        local dy=((tYaw-camYaw+math.pi)%(math.pi*2))-math.pi
        camYaw=camYaw+dy*PULL
        camPitch=camPitch+(tPitch-camPitch)*PULL

        cam.CFrame=CFrame.new(headPos)*CFrame.Angles(0,camYaw,0)*CFrame.Angles(camPitch,0,0)

        local dot=cam.CFrame.LookVector:Dot(toD)
        local progress=math.clamp(dot,0,1)

        -- Fog reddening + shake proportional to gaze
        local fogR=math.floor(130+progress*125)
        local fogG=math.floor(130-progress*120)
        Lighting.FogColor=Color3.fromRGB(fogR,fogG,fogG)
        Lighting.FogEnd=math.max(20, origFogEnd-progress*60)
        if progress>0.1 then doShake(progress*4,0.2) end

        local hum=getHum(); if not hum then return end
        if dot>0.92 then
            gazeTime=gazeTime+dt
            if gazeTime>=0.4 then
                -- Instant death + afterimage
                nDeityConn:Disconnect(); nDeityConn=nil
                cam.CameraType=origType; setCharVis(true)
                setNFog(origFogColor,15,origFogEnd,2)
                nDeityActive=false
                -- Afterimage (white wings + yellow ring, permanent)
                local aimf=Instance.new("Part"); aimf.Name="Afterimage"
                aimf.Size=Vector3.new(4,8,1); aimf.Position=hrp.Position
                aimf.Anchored=true; aimf.CanCollide=false
                aimf.Material=Enum.Material.Neon; aimf.Color=Color3.new(1,1,1)
                aimf.Transparency=0.35; aimf.CastShadow=false; aimf.Parent=workspace
                local ahl=Instance.new("Highlight"); ahl.Adornee=aimf
                ahl.OutlineColor=Color3.fromRGB(255,210,50); ahl.FillColor=Color3.new(1,1,1)
                ahl.FillTransparency=0.3; ahl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; ahl.Parent=aimf
                -- Wings on billboard
                local aiBB=Instance.new("BillboardGui"); aiBB.Size=UDim2.new(0,120,0,120)
                aiBB.AlwaysOnTop=false; aiBB.Parent=aimf
                local aiR=Instance.new("Frame"); aiR.Size=UDim2.new(1,0,1,0)
                aiR.BackgroundTransparency=1; aiR.Parent=aiBB
                for _,side in ipairs({-1,1}) do
                    local w=Instance.new("Frame"); w.Size=UDim2.new(0,55,0,22)
                    w.BackgroundColor3=Color3.new(1,1,1); w.BackgroundTransparency=0.3
                    w.Position=UDim2.new(0.5,side==(-1) and -70 or 15,0.3,0)
                    w.Rotation=side*20; w.Parent=aiR
                    Instance.new("UICorner",w).CornerRadius=UDim.new(0.5,0)
                end
                -- Ring above
                local aiHalo=Instance.new("Frame"); aiHalo.Size=UDim2.new(0,40,0,40)
                aiHalo.Position=UDim2.new(0.5,-20,0,0); aiHalo.BackgroundTransparency=1; aiHalo.Parent=aiBB
                Instance.new("UICorner",aiHalo).CornerRadius=UDim.new(1,0)
                local aiS=Instance.new("UIStroke"); aiS.Color=Color3.fromRGB(255,210,50); aiS.Thickness=5; aiS.Parent=aiHalo
                table.insert(nAfterimages,aimf)

                TweenService:Create(eyeParts.upperLid,TweenInfo.new(0.4),{Position=UDim2.new(0,0,-0.05,0)}):Play()
                TweenService:Create(eyeParts.lowerLid,TweenInfo.new(0.4),{Position=UDim2.new(0,0,0.40,0)}):Play()
                hum.Health=0
            end
        else
            gazeTime=math.max(0,gazeTime-dt*0.8)
        end
    end)
end

-- ── Believer entity ───────────────────────────────────────────
spawnBeliever = function()
    local cx=NHV_ORIGIN.X; local cz_t=NHV_ORIGIN.Z
    local ang=math.random()*math.pi*2; local r=math.random(30,80)
    local pos=Vector3.new(cx+math.cos(ang)*r,1,cz_t+math.sin(ang)*r)

    local f=Instance.new("Folder"); f.Name="Believer"; f.Parent=workspace
    local glow=Color3.fromRGB(200,190,140)
    local function bp(name,sz,cf,col,trans)
        local p=Instance.new("Part"); p.Name=name; p.Size=sz; p.CFrame=cf
        p.Anchored=true; p.CanCollide=false; p.Color=col; p.Transparency=trans or 0
        p.Material=Enum.Material.SmoothPlastic; p.CastShadow=false; p.Parent=f; return p
    end
    local root=bp("Root",Vector3.new(0.1,0.1,0.1),CFrame.new(pos),Color3.new(0,0,0),0.999)
    bp("Torso",   Vector3.new(2,2,1),   CFrame.new(pos),glow)
    bp("Head",    Vector3.new(2,1,1),   CFrame.new(pos+Vector3.new(0,1.5,0)),glow)
    bp("LAr",     Vector3.new(1,2,1),   CFrame.new(pos+Vector3.new(-1.5,0,0)),glow)
    bp("RAr",     Vector3.new(1,2,1),   CFrame.new(pos+Vector3.new( 1.5,0,0)),glow)
    bp("LLg",     Vector3.new(1,2,1),   CFrame.new(pos+Vector3.new(-0.5,-2,0)),glow)
    bp("RLg",     Vector3.new(1,2,1),   CFrame.new(pos+Vector3.new( 0.5,-2,0)),glow)
    -- Wings (phases 3+)
    for _,side in ipairs({-1,1}) do
        bp("Wing"..side,Vector3.new(0.3,4,8),
            CFrame.new(pos+Vector3.new(side*4,1,0))*CFrame.Angles(0,0,side*0.4),
            Color3.fromRGB(230,220,180),0.35)
    end
    local hl=Instance.new("Highlight"); hl.Adornee=root
    hl.OutlineColor=Color3.fromRGB(220,200,80); hl.FillColor=Color3.fromRGB(200,180,60)
    hl.FillTransparency=0.5; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=root

    local health=90; local speed=20
    local ent={folder=f,root=root,health=health,speed=speed,hbConn=nil,dead=false,stopped=false}

    local function setPos(np)
        if not f.Parent then return end
        local off=np-root.CFrame.Position
        for _,p in ipairs(f:GetDescendants()) do if p:IsA("BasePart") then p.CFrame=p.CFrame+off end end
    end

    ent.hbConn=RunService.Heartbeat:Connect(function(dt)
        if ent.dead or ent.stopped then return end
        if not f.Parent then return end
        local hrp=getHRP(); if not hrp then return end
        local cur=root.CFrame.Position
        local tgt=hrp.Position; local diff=tgt-cur; local dist=diff.Magnitude
        if dist>0.5 then setPos(cur+diff.Unit*math.min(speed*dt,dist)) end

        -- Face
        if dist>0.5 then
            local fCF=CFrame.new(cur,Vector3.new(tgt.X,cur.Y,tgt.Z))
            local dy=math.atan2(-fCF.LookVector.X,-fCF.LookVector.Z)-math.atan2(-root.CFrame.LookVector.X,-root.CFrame.LookVector.Z)
            dy=((dy+math.pi)%(math.pi*2))-math.pi
            if math.abs(dy)>0.01 then
                local c2,s2=math.cos(dy),math.sin(dy); local orig=root.CFrame.Position
                for _,p in ipairs(f:GetDescendants()) do
                    if p:IsA("BasePart") then
                        local lp=p.CFrame.Position-orig
                        p.CFrame=CFrame.new(orig+Vector3.new(lp.X*c2-lp.Z*s2,lp.Y,lp.X*s2+lp.Z*c2))*CFrame.Angles(0,dy,0)
                    end
                end
            end
        end

        -- Hit
        if dist<3.2 then
            local hum=getHum(); if hum and hum.Health>0 then
                hum.Health=math.max(0.1,hum.Health-35*dt)
                if math.random()<0.04 then playSound("76525344270919",root,0.8) end
            end
        end

        -- Parry
        if isParrying and not parryCooldown and dist<5 then
            triggerParryCooldown(2)
            playSound("133245268132726",root,1)
            ent.health=ent.health-30
            if ent.health<=0 then
                playSound("81916503066203",root,1)
                ent.dead=true; ent.hbConn:Disconnect()
                TweenService:Create(root,TweenInfo.new(0.5),{Transparency=1}):Play()
                task.delay(0.55,function() if f.Parent then f:Destroy() end end)
                for i,e in ipairs(nBelieverList) do if e==ent then table.remove(nBelieverList,i); break end end
                return
            end
            -- Knockback
            local away=(cur-tgt).Unit
            task.spawn(function()
                for _=1,15 do task.wait(0.04); if ent.dead then break end; setPos(root.CFrame.Position+away*2.5) end
            end)
        end
    end)

    table.insert(nBelieverList,ent)
    return ent
end

-- ── Falling objects (phase 5) ─────────────────────────────────
local function startFalling()
    if nFallConn then return end
    task.spawn(function()
        while nevaeHActive and nPhase>=5 do
            task.wait(1)
            for i=1,5 do
                task.spawn(function()
                    local hrp=getHRP(); if not hrp then return end
                    local ang=math.random()*math.pi*2; local r=math.random(5,45)
                    local fx=hrp.Position.X+math.cos(ang)*r
                    local fz=hrp.Position.Z+math.sin(ang)*r
                    local obj=Instance.new("Part"); obj.Name="FallObj"
                    obj.Size=Vector3.new(math.random(2,5),math.random(2,5),math.random(2,5))
                    obj.Position=Vector3.new(fx,hrp.Position.Y+60,fz)
                    obj.Anchored=false; obj.CanCollide=true
                    obj.Material=Enum.Material.SmoothPlastic
                    obj.Color=Color3.fromRGB(80,80,90); obj.CastShadow=false; obj.Parent=workspace
                    game:GetService("Debris"):AddItem(obj,5)
                    local oc; oc=obj.Touched:Connect(function(hit)
                        if hit.Parent~=player.Character then return end
                        local hum=getHum(); if hum then hum.Health=math.max(0.1,hum.Health-30) end
                        oc:Disconnect()
                    end)
                    table.insert(nFallObjects,obj)
                end)
            end
        end
    end)
end

-- ── Phase transitions ─────────────────────────────────────────
local deityEyeParts = nil

startNPhase = function(p)
    if not nevaeHActive then return end
    nPhase=p; nStatuePrayed=0
    clearNStatues()

    if p==1 then
        -- Setup already done in startNevaeH
    elseif p==2 then
        -- Black fog, night
        setNFog(Color3.fromRGB(15,15,25), 15, 200, 3)
        Lighting.Brightness=0.15
        hudLbl.Text="nevaeH - Phase 2  Statues: 0/5"
        hudLbl.TextColor3=Color3.fromRGB(180,180,220)
        spawnNStatues(5,0)
        -- Build and activate Deity
        local dp,ep=buildDeity(); deityEyeParts=ep
        -- Schedule deity events every 20s
        task.spawn(function()
            while nevaeHActive and nPhase>=2 do
                task.wait(20)
                if nevaeHActive and nPhase>=2 and deityEyeParts then
                    runDeityEvent(deityEyeParts)
                end
            end
        end)
    elseif p==3 then
        hudLbl.Text="nevaeH - Phase 3  Statues: 0/7"
        setNFog(Color3.fromRGB(10,10,20),15,180,2)
        spawnNStatues(7,0)
        -- Spawn first believers from tree
        for i=1,3 do
            task.delay(i*1.5,function() if nevaeHActive then spawnBeliever() end end)
        end
        -- Ongoing believer spawning every 25s
        task.spawn(function()
            while nevaeHActive and nPhase>=3 do
                task.wait(25)
                if nevaeHActive and nPhase>=3 and #nBelieverList<8 then spawnBeliever() end
            end
        end)
    elseif p==4 then
        hudLbl.Text="nevaeH - Phase 4  Statues: 0/10"
        setNFog(Color3.fromRGB(8,8,18),15,160,2)
        spawnNStatues(10,5)  -- 10 real + 5 fake
    elseif p==5 then
        -- Flash screen
        local fg=Instance.new("ScreenGui"); fg.Name="P5Flash"; fg.ResetOnSpawn=false; fg.Parent=player.PlayerGui
        local ff=Instance.new("Frame"); ff.Size=UDim2.new(1,0,1,0)
        ff.BackgroundColor3=Color3.new(1,1,1); ff.BackgroundTransparency=0; ff.BorderSizePixel=0; ff.Parent=fg
        TweenService:Create(ff,TweenInfo.new(1.2),{BackgroundTransparency=1}):Play()
        task.delay(1.3,function() if fg and fg.Parent then fg:Destroy() end end)

        -- White less thick fog
        setNFog(Color3.fromRGB(220,220,230),8,120,2)
        hudLbl.Text="nevaeH - Phase 5  Statues: 0/20"
        hudLbl.TextColor3=Color3.fromRGB(255,255,200)
        spawnNStatues(20,10)
        startFalling()
        -- Constant weak shake
        task.spawn(function()
            while nevaeHActive and nPhase>=5 do
                doShake(1.2, 0.8)
                task.wait(0.9)
            end
        end)
    elseif p==6 then
        -- Finale
        nExitCutscene()
    end
end

-- ── Exit cutscene ─────────────────────────────────────────────
nExitCutscene = function()
    local cam=workspace.CurrentCamera
    local hum=getHum(); if hum then hum.WalkSpeed=0; hum.JumpPower=0 end
    local cx=NHV_ORIGIN.X; local cz_t=NHV_ORIGIN.Z
    local treeTop=Vector3.new(cx,NHV_TREE_H+80,cz_t)

    -- Camera from high above looking down at tree
    cam.CameraType=Enum.CameraType.Scriptable
    cam.CFrame=CFrame.new(cx,NHV_TREE_H+200,cz_t+20)*CFrame.Angles(-math.pi/2.2,0,0)

    task.delay(5,function()
        -- Tree burst of light
        if nTreePart then
            TweenService:Create(nTreePart,TweenInfo.new(0.8),{Color=Color3.new(1,1,0.8)}):Play()
            local tl=Instance.new("PointLight"); tl.Brightness=50; tl.Range=600
            tl.Color=Color3.fromRGB(255,245,150); tl.Parent=nTreePart
        end

        -- Yellow blind flash
        local fgY=Instance.new("ScreenGui"); fgY.Name="TreeBurst"; fgY.ResetOnSpawn=false; fgY.Parent=player.PlayerGui
        local ffy=Instance.new("Frame"); ffy.Size=UDim2.new(1,0,1,0)
        ffy.BackgroundColor3=Color3.fromRGB(255,240,80); ffy.BackgroundTransparency=0; ffy.BorderSizePixel=0; ffy.Parent=fgY
        doShake(20,1.5)
        TweenService:Create(ffy,TweenInfo.new(3),{BackgroundTransparency=1}):Play()
        task.delay(3.1,function() if fgY and fgY.Parent then fgY:Destroy() end end)

        -- Fog → yellow
        setNFog(Color3.fromRGB(255,240,100),15,300,2)

        -- Stop falling objects
        nPhase=99  -- stops all loops
        for _,obj in ipairs(nFallObjects) do if obj and obj.Parent then obj:Destroy() end end

        -- Deity disappears
        if nDeityPart and nDeityPart.Parent then
            TweenService:Create(nDeityPart,TweenInfo.new(1),{Transparency=1}):Play()
            task.delay(1.1,function() if nDeityPart and nDeityPart.Parent then nDeityPart:Destroy(); nDeityPart=nil end end)
        end

        -- Believers stop, become angels (gold ESP, stopped)
        for _,e in ipairs(nBelieverList) do
            e.stopped=true
            local hl=e.root and e.root:FindFirstChildOfClass("Highlight")
            if hl then hl.OutlineColor=Color3.fromRGB(255,215,50); hl.FillColor=Color3.fromRGB(255,200,30) end
        end

        -- Fake statues get yellow ESP
        for _,sd in ipairs(nStatues) do
            if sd.fake and sd.folder and sd.folder.Parent then
                local hl=Instance.new("Highlight"); hl.Adornee=sd.base
                hl.OutlineColor=Color3.fromRGB(255,215,50); hl.FillColor=Color3.fromRGB(255,180,0)
                hl.FillTransparency=0.4; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=sd.base
            end
        end
    end)

    -- Victory text + return camera at 8s
    task.delay(8,function()
        showVictoryText()
        cam.CameraType=Enum.CameraType.Custom
        local hum2=getHum(); if hum2 then hum2.WalkSpeed=NEVAEH_SPEED; hum2.JumpPower=50 end
    end)

    -- Exit path at 11s
    task.delay(11,function()
        local cx2=NHV_ORIGIN.X; local cz2=NHV_ORIGIN.Z
        local pf=Instance.new("Folder"); pf.Name="NevPath"; pf.Parent=workspace
        for i=1,15 do
            task.delay(i*0.2,function()
                local seg=makePart("NPath_"..i,Vector3.new(8,1,8),
                    Vector3.new(cx2+i*10, 1, cz2+80),
                    Color3.fromRGB(255,230,80),Enum.Material.Neon,1,true,pf)
                TweenService:Create(seg,TweenInfo.new(0.5),{Transparency=0.1}):Play()
            end)
        end
        -- Portal
        task.delay(15*0.2+1,function()
            local port=makePart("NevPortal",Vector3.new(9,14,2),
                Vector3.new(cx2+15*10+5,7,cz2+80),
                Color3.fromRGB(255,200,30),Enum.Material.Neon,0.2,false,pf)
            local phl=Instance.new("Highlight"); phl.Adornee=port
            phl.OutlineColor=Color3.fromRGB(255,230,60); phl.FillColor=Color3.fromRGB(255,200,0)
            phl.FillTransparency=0.2; phl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; phl.Parent=port
            local pc; pc=port.Touched:Connect(function(hit)
                if hit.Parent~=player.Character then return end
                pc:Disconnect(); pf:Destroy()
                nevaeHActive=false; restoreFog()
                if nMapFolder and nMapFolder.Parent then nMapFolder:Destroy(); nMapFolder=nil end
                for _,ai in ipairs(nAfterimages) do if ai.Parent then ai:Destroy() end end
                local hrp3=getHRP(); if hrp3 then hrp3.CFrame=CFrame.new(safeSpawnPos) end
                hudLbl.Text="nevaeH Domain Clear!"
                hudLbl.TextColor3=Color3.fromRGB(255,240,100)
                selectedDomain=nil
            end)
        end)
    end)
end

-- ── Start nevaeH ──────────────────────────────────────────────
local function startNevaeH()
    nevaeHActive=true; nPhase=1; nStatuePrayed=0
    nStatues={}; nBelieverList={}; nAfterimages={}; nFallObjects={}
    nDeityPart=nil; nDeityActive=false

    -- Phase 1 fog: blue, airy
    setNFog(Color3.fromRGB(100,150,220),15,250,0)
    Lighting.Brightness=1.2; Lighting.OutdoorAmbient=Color3.fromRGB(100,140,200)

    -- Teleport + speed
    local hrp=getHRP()
    if hrp then hrp.CFrame=CFrame.new(NHV_ORIGIN.X,1.5,NHV_ORIGIN.Z+50) end
    local hum=getHum(); if hum then hum.WalkSpeed=NEVAEH_SPEED; hum.JumpPower=50 end

    buildNevaeHMap()
    spawnNStatues(3,0)

    hudLbl.Text="nevaeH - Statues: 0/3"
    hudLbl.TextColor3=Color3.fromRGB(140,200,255)

    -- Grass damage loop
    nGrassConn=RunService.Heartbeat:Connect(function(dt)
        if not nevaeHActive then nGrassConn:Disconnect(); return end
        local hrp2=getHRP(); if not hrp2 then return end
        local hum2=getHum(); if not hum2 then return end
        -- Raycast downward to check surface
        local result=workspace:Raycast(hrp2.Position,Vector3.new(0,-3.5,0))
        if result and result.Instance then
            local n=result.Instance.Name
            if n~="SoilRing" and n~="SoilPath" and n~="SoilPatch" and n~="NPath" and not n:match("Step") and not n:match("Stair") then
                if result.Instance.Material==Enum.Material.Grass then
                    hum2.Health=math.max(0.1,hum2.Health-5*dt)
                end
            end
        end
    end)

    -- Main loop
    nevaeHConn=RunService.Heartbeat:Connect(function(dt)
        if not nevaeHActive then nevaeHConn:Disconnect(); nevaeHConn=nil; return end
    end)
end

-- Wire nevaeH button
local nevBtn=Instance.new("TextButton"); nevBtn.Size=UDim2.new(0,200,0,32)
nevBtn.Position=UDim2.new(0,525,0.5,-16); nevBtn.BackgroundColor3=Color3.fromRGB(12,20,35)
nevBtn.Text="nevaeH  |  Saint's Domain"; nevBtn.Font=Enum.Font.GothamBold; nevBtn.TextSize=12
nevBtn.TextColor3=Color3.fromRGB(140,190,255); nevBtn.BorderSizePixel=0; nevBtn.Parent=dsBar
Instance.new("UICorner",nevBtn).CornerRadius=UDim.new(0,6)
local nvs=Instance.new("UIStroke"); nvs.Color=Color3.fromRGB(80,140,255); nvs.Thickness=1.5; nvs.Parent=nevBtn

-- Widen bar for 3 buttons
dsBar.Size=UDim2.new(0,780,0,46)
dsBar.Position=UDim2.new(0.5,-390,0,8)

nevBtn.MouseButton1Click:Connect(function()
    if domainActive or griefActive or nevaeHActive then return end
    selectedDomain="nevaeH"
    nevBtn.BackgroundColor3=Color3.fromRGB(20,35,65)
    nevBtn.TextColor3=Color3.fromRGB(200,230,255)
    frenzyBtn.BackgroundColor3=Color3.fromRGB(35,8,8); frenzyBtn.TextColor3=Color3.fromRGB(255,70,40)
    griefBtn.BackgroundColor3=Color3.fromRGB(12,12,28); griefBtn.TextColor3=Color3.fromRGB(120,140,200)
    dsNotice.Text="READY"; dsNotice.TextColor3=Color3.fromRGB(100,255,120)
    hudLbl.Text="nevaeH selected - enter the door!"
    hudLbl.TextColor3=Color3.fromRGB(140,190,255)
end)

-- Door handler
task.delay(1.5,function()
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj.Name=="Door" and obj.Parent and obj.Parent.Name=="Saferoom" then
            obj.Touched:Connect(function(hit)
                if hit.Parent~=player.Character then return end
                if selectedDomain~="nevaeH" then return end
                if nevaeHActive or domainActive or griefActive then return end
                startNevaeH()
            end)
            break
        end
    end
end)
