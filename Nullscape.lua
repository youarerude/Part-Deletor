--[[
    ██████╗ ███████╗██╗   ██╗ ██████╗ ██╗██████╗
    ██╔══██╗██╔════╝██║   ██║██╔═══██╗██║██╔══██╗
    ██║  ██║█████╗  ██║   ██║██║   ██║██║██║  ██║
    ██║  ██║██╔══╝  ╚██╗ ██╔╝██║   ██║██║██║  ██║
    ██████╔╝███████╗ ╚████╔╝ ╚██████╔╝██║██████╔╝
    ╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═╝╚═════╝
    DEVOID v4 — Codex Executor
--]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris       = game:GetService("Debris")
local Lighting     = game:GetService("Lighting")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera    = workspace.CurrentCamera

local function getHRP() return character:FindFirstChild("HumanoidRootPart") end
local function getHum() return character:FindFirstChildOfClass("Humanoid") end

-- ============================================================
-- SOUND
-- ============================================================
local function playSound(id, volume, pos)
    local s = Instance.new("Sound")
    s.SoundId  = "rbxassetid://"..tostring(id)
    s.Volume   = volume or 1
    s.RollOffMaxDistance = 9999
    if pos then
        local p = Instance.new("Part",workspace)
        p.Anchored=true; p.CanCollide=false; p.Transparency=1
        p.Position=pos; s.Parent=p
        s:Play(); Debris:AddItem(p,15)
    else
        s.Parent=workspace; s:Play(); Debris:AddItem(s,15)
    end
end

-- Sound IDs
local SFX = {
    HelloworldCharge  = "76488643226841",
    HelloworldTeleport= "95957174060681",
    NukeExplosion     = "102353491611087",
    PlayerDie         = "136836070379847",
    SeedInfect        = "125378217647252",
    CameraFlash       = "133385770201451",
    PurpleLight       = "133385770201451",
    DistortionSpawn   = "135273647100905",
}

-- ============================================================
-- CONSTANTS
-- ============================================================
local MAP_Y        = 20000
local LOBBY_Y      = 30000
local BEACON_COUNT = 3
local MAX_REROLLS  = 3

local SHARD_RANGES = {
    {50,75},{90,120},{150,200},{235,250},{280,300},
}
local function getShardCount(r)
    local t=SHARD_RANGES[math.min(r,#SHARD_RANGES)]; return math.random(t[1],t[2])
end
local function getMapRadius(r) return 200+(r-1)*120 end

-- ============================================================
-- ENTITY REGISTRY
-- ============================================================
local EntityRegistry = {
    {
        Name="Follower", Tips="Follows you around and kills on contact.",
        AppearRound=1, AI="Follower",
        BodyColor=Color3.fromRGB(34,139,34), Speed=7, ShatterSpeed=10,
        Damage=100, ParticleColor=Color3.fromRGB(0,220,0),
    },
    {
        Name="Seed", Tips="Watch for purple platforms — touching one flings you upward.",
        AppearRound=1, AI="Seed",
        BodyColor=Color3.fromRGB(100,0,160),
        TeleportInterval=20, ShatterTeleportInterval=15,
        InfectCount=1, ShatterInfectCount=3, Damage=30,
    },
    {
        Name="Target", Tips="Stay away from its area. Staying in it can kill you.",
        AppearRound=1, AI="Target",
        Interval=50, ShatterInterval=30,
        Radius=50, ShatterRadius=75, Damage=150, ShatterDamage=200,
    },
    {
        Name="Wormhole", Tips="Stay away from wormholes and dont jump if you're near it.",
        AppearRound=1, AI="Wormhole",
        Interval=30, ShatterInterval=25,
        Duration=10, ShatterDuration=15,
        PullForce=28, ShatterPullForce=52, KillRadius=8,
    },
    {
        Name="helloworld", Tips="Teleports in front of you every 5s.",
        AppearRound=1, AI="helloworld",
        Speed=6, ShatterSpeed=8,
        TeleportInterval=5, ShatterTeleportInterval=3, Damage=100,
    },
    {
        Name="Keeper",
        Tips="Stop moving when inside its red zone. Walking for too long triggers a deadly chase.",
        AppearRound=6, AI="Keeper",
        TeleportInterval=20,
        AreaRadius=80, ShatterAreaRadius=100,
        WalkTime=3, ShatterWalkTime=2,
        ChaseSpeed=20, Damage=100,
    },
    {
        Name="Camera",
        Tips="Freeze when you hear 'Say Cheese!' — moving during the flash sends you flying.",
        AppearRound=6, AI="Camera",
        Interval=25, ShatterInterval=20,
        WarnTime=3, Damage=45, ShatterDamage=60,
    },
    {
        Name="Distortion",
        Tips="Mimics your movement. Don't touch it.",
        AppearRound=6, AI="Distortion",
        Delay=2, ShatterDelay=1, Damage=100,
    },
}

-- ============================================================
-- GAME STATE
-- ============================================================
local GS = {
    Phase="LOBBY", Round=1, RoundsBeaten=0, IsShatter=false,
    RerollsLeft=MAX_REROLLS, TotalShards=0, CollectedReality=0, CollectedCosmic=0,
    RealityShards={}, CosmicShards={}, MapPlatforms={},
    Entities={}, EntityConns={}, PickedEntities={}, BeaconChoices={},
    PickedAtLeastOne=false, Distortions={}, CurrentDistortionCount=0,
}

-- ============================================================
-- FOLDERS
-- ============================================================
local function cleanFolder(name)
    local old=workspace:FindFirstChild(name); if old then old:Destroy() end
    local f=Instance.new("Folder"); f.Name=name; f.Parent=workspace; return f
end
local ROOT          = cleanFolder("DevoidGame")
local LOBBY_FOLDER  = Instance.new("Folder",ROOT); LOBBY_FOLDER.Name="Lobby"
local MAP_FOLDER    = Instance.new("Folder",ROOT); MAP_FOLDER.Name="Map"
local ENTITY_FOLDER = Instance.new("Folder",ROOT); ENTITY_FOLDER.Name="Entities"
local SHARD_FOLDER  = Instance.new("Folder",ROOT); SHARD_FOLDER.Name="Shards"

-- ============================================================
-- LIGHTING
-- ============================================================
Lighting.Ambient=Color3.fromRGB(130,125,155); Lighting.OutdoorAmbient=Color3.fromRGB(100,95,120)
Lighting.Brightness=2.5; Lighting.ClockTime=0
Lighting.FogEnd=1000; Lighting.FogColor=Color3.fromRGB(8,4,18); Lighting.FogStart=350
do
    local old=Lighting:FindFirstChildOfClass("Sky"); if old then old:Destroy() end
    local sky=Instance.new("Sky",Lighting); sky.StarCount=5000
    local void="rbxassetid://6444884337"
    sky.SkyboxBk=void;sky.SkyboxDn=void;sky.SkyboxFt=void
    sky.SkyboxLf=void;sky.SkyboxRt=void;sky.SkyboxUp=void
end

-- ============================================================
-- GUI
-- ============================================================
do local old=player.PlayerGui:FindFirstChild("DevoidGUI"); if old then old:Destroy() end end
local GUI=Instance.new("ScreenGui")
GUI.Name="DevoidGUI"; GUI.ResetOnSpawn=false; GUI.IgnoreGuiInset=true; GUI.Parent=player.PlayerGui

local function corner(i,r) local c=Instance.new("UICorner",i); c.CornerRadius=UDim.new(0,r or 8) end
local function mkFrame(p,t) local f=Instance.new("Frame",p); for k,v in pairs(t) do f[k]=v end; return f end
local function mkLabel(p,t) local l=Instance.new("TextLabel",p); for k,v in pairs(t) do l[k]=v end; return l end
local function mkBtn(p,t)   local b=Instance.new("TextButton",p); for k,v in pairs(t) do b[k]=v end; return b end

local HUD=mkFrame(GUI,{Name="HUD",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false})
local lblReality=mkLabel(HUD,{
    Size=UDim2.new(0,310,0,44),Position=UDim2.new(0,16,0,16),
    BackgroundColor3=Color3.fromRGB(8,6,20),BackgroundTransparency=0.3,
    TextColor3=Color3.fromRGB(190,160,255),TextScaled=true,
    Font=Enum.Font.GothamBold,Text="Reality Shards: 0 / 0",ZIndex=2,
}); corner(lblReality)
local lblCosmic=mkLabel(HUD,{
    Size=UDim2.new(0,310,0,44),Position=UDim2.new(0,16,0,68),
    BackgroundColor3=Color3.fromRGB(20,14,4),BackgroundTransparency=0.3,
    TextColor3=Color3.fromRGB(255,210,40),TextScaled=true,
    Font=Enum.Font.GothamBold,Text="Cosmic Shards: 0 / 0",Visible=false,ZIndex=2,
}); corner(lblCosmic)
local lblRound=mkLabel(HUD,{
    Size=UDim2.new(0,210,0,38),Position=UDim2.new(0.5,-105,0,16),
    BackgroundTransparency=1,TextColor3=Color3.fromRGB(220,200,255),
    TextScaled=true,Font=Enum.Font.GothamBold,Text="PM 0:00",ZIndex=2,
})
local lblPhase=mkLabel(HUD,{
    Size=UDim2.new(0,240,0,28),Position=UDim2.new(0.5,-120,0,60),
    BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,80,80),
    TextScaled=true,Font=Enum.Font.Gotham,Text="",Visible=false,ZIndex=2,
})
local lblShatterWarn=mkLabel(HUD,{
    Size=UDim2.new(1,0,0,72),Position=UDim2.new(0,0,0.14,0),
    BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,70,70),
    TextScaled=true,Font=Enum.Font.GothamBold,
    Text="⚠  SHATTER BEGINS  ⚠",Visible=false,ZIndex=5,
})

-- Death Screen
local DEATH=mkFrame(GUI,{
    Name="DeathScreen",Size=UDim2.new(1,0,1,0),
    BackgroundColor3=Color3.fromRGB(4,0,12),BackgroundTransparency=0.08,
    Visible=false,ZIndex=10,
})
mkLabel(DEATH,{
    Size=UDim2.new(1,0,0,90),Position=UDim2.new(0,0,0.08,0),
    BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,45,45),
    TextScaled=true,Font=Enum.Font.GothamBold,Text="YOU DEVOID",ZIndex=11,
})
local lblDeathStats=mkLabel(DEATH,{
    Size=UDim2.new(0.62,0,0.44,0),Position=UDim2.new(0.19,0,0.22,0),
    BackgroundColor3=Color3.fromRGB(14,8,30),BackgroundTransparency=0.28,
    TextColor3=Color3.fromRGB(200,190,255),TextScaled=true,
    Font=Enum.Font.Gotham,Text="",ZIndex=11,TextWrapped=true,
}); corner(lblDeathStats,12)
local btnRetry=mkBtn(DEATH,{
    Size=UDim2.new(0,210,0,52),Position=UDim2.new(0.5,-105,0.74,0),
    BackgroundColor3=Color3.fromRGB(55,0,110),TextColor3=Color3.fromRGB(255,255,255),
    TextScaled=true,Font=Enum.Font.GothamBold,Text="▶   RETRY",ZIndex=11,
}); corner(btnRetry,10)

-- ============================================================
-- FORWARD DECLARATIONS
-- ============================================================
local buildLobby,startRound,refreshBeacons,selectEntity,doReroll,onDeath,activateStartPP

-- ============================================================
-- CAMERA SHAKE
-- ============================================================
local function shakeCamera(intensity,duration)
    local elapsed=0; local conn
    conn=RunService.RenderStepped:Connect(function(dt)
        elapsed+=dt
        if elapsed>=duration then conn:Disconnect(); return end
        local fade=1-elapsed/duration; local s=intensity*fade
        camera.CFrame=camera.CFrame
            *CFrame.new((math.random()-0.5)*s*2,(math.random()-0.5)*s*2,0)
            *CFrame.Angles(
                math.rad((math.random()-0.5)*s*5),
                math.rad((math.random()-0.5)*s*5),
                math.rad((math.random()-0.5)*s*2)
            )
    end)
end

-- ============================================================
-- MAP GENERATION
-- ============================================================
local PLAT_COLORS={
    Color3.fromRGB(28,22,48),Color3.fromRGB(38,28,58),
    Color3.fromRGB(22,18,42),Color3.fromRGB(32,26,52),
}
local PLAT_DEFS={
    {8,8},{12,12},{20,8},{8,20},{28,8},{8,28},
    {16,16},{24,8},{8,24},{18,18},{14,6},{6,14},
    {32,8},{8,32},{10,10},{22,22},
}

local function clearMap()
    for _,p in ipairs(GS.MapPlatforms) do if p and p.Parent then p:Destroy() end end
    for _,s in ipairs(GS.RealityShards) do if s and s.Parent then s:Destroy() end end
    for _,s in ipairs(GS.CosmicShards)  do if s and s.Parent then s:Destroy() end end
    for _,e in ipairs(GS.Entities)      do if e and e.Parent then e:Destroy() end end
    for _,c in ipairs(GS.EntityConns)   do c:Disconnect() end
    GS.MapPlatforms={};GS.RealityShards={};GS.CosmicShards={}
    GS.Entities={};GS.EntityConns={};GS.Distortions={};GS.CurrentDistortionCount=0
    for _,o in ipairs(MAP_FOLDER:GetChildren())    do o:Destroy() end
    for _,o in ipairs(SHARD_FOLDER:GetChildren())  do o:Destroy() end
    for _,o in ipairs(ENTITY_FOLDER:GetChildren()) do o:Destroy() end
end

local function generateMap(round)
    clearMap()
    local radius   = getMapRadius(round)
    local maxPlats = 85+round*45
    local placed={}

    local function overlaps(cx,cz,hw,hd)
        for _,p in ipairs(placed) do
            local gx=math.abs(cx-p.cx)-(hw+p.hw)
            local gz=math.abs(cz-p.cz)-(hd+p.hd)
            if gx<3 and gz<3 then return true end
        end
        return false
    end

    local function makePlat(cx,cz,def,name)
        local sz=Vector3.new(def[1],2,def[2])
        local pt=Instance.new("Part",MAP_FOLDER)
        pt.Name=name or "Plat"; pt.Size=sz
        pt.Position=Vector3.new(cx,MAP_Y,cz)
        pt.Anchored=true; pt.Material=Enum.Material.SmoothPlastic
        pt.Color=PLAT_COLORS[math.random(1,#PLAT_COLORS)]
        pt:SetAttribute("OrigColor",pt.Color)
        table.insert(GS.MapPlatforms,pt)
        table.insert(placed,{cx=cx,cz=cz,hw=def[1]/2,hd=def[2]/2})
        return pt
    end

    makePlat(0,0,{36,36},"SpawnPlatform")
    local frontier={{cx=0,cz=0,hw=18,hd=18}}
    local DIRS={{1,0},{-1,0},{0,1},{0,-1}}
    local iter=0

    while #GS.MapPlatforms<maxPlats and iter<18000 do
        iter+=1
        if #frontier==0 then break end
        local base=frontier[math.random(1,math.min(#frontier,30))]
        local dir=DIRS[math.random(1,4)]
        local def=PLAT_DEFS[math.random(1,#PLAT_DEFS)]
        local nhw=def[1]/2; local nhd=def[2]/2
        local gap=math.random()<0.65 and math.random(0,1) or math.random(9,14)
        local cx,cz
        if dir[1]~=0 then
            cx=base.cx+dir[1]*(base.hw+gap+nhw); cz=base.cz+math.random(-2,2)
        else
            cx=base.cx+math.random(-2,2); cz=base.cz+dir[2]*(base.hd+gap+nhd)
        end
        if math.abs(cx)+nhw>radius then continue end
        if math.abs(cz)+nhd>radius then continue end
        if overlaps(cx,cz,nhw,nhd) then continue end
        makePlat(cx,cz,def)
        table.insert(frontier,{cx=cx,cz=cz,hw=nhw,hd=nhd})
        if #frontier>70 then table.remove(frontier,1) end
    end

    return GS.MapPlatforms
end

-- ============================================================
-- SHARD HELPERS
-- ============================================================
local function spinPart(p)
    local c; c=RunService.Heartbeat:Connect(function(dt)
        if p and p.Parent then p.CFrame=p.CFrame*CFrame.Angles(0,dt*2.2,0) else c:Disconnect() end
    end)
end
local function addParticles(part,color)
    local a=Instance.new("Attachment",part)
    local pe=Instance.new("ParticleEmitter",a)
    pe.Color=ColorSequence.new(color); pe.LightEmission=1; pe.Rate=14
    pe.Speed=NumberRange.new(1,3); pe.Lifetime=NumberRange.new(0.5,1.5)
    pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(1,0)})
end

local function spawnRealityShards(count,platforms)
    GS.RealityShards={};GS.CollectedReality=0;GS.TotalShards=count
    local pool={}
    for _,p in ipairs(platforms) do if p.Name~="SpawnPlatform" then table.insert(pool,p) end end
    for i=#pool,2,-1 do local j=math.random(1,i);pool[i],pool[j]=pool[j],pool[i] end
    for i=1,math.min(count,#pool) do
        local plat=pool[i]
        local s=Instance.new("Part",SHARD_FOLDER)
        s.Name="RealityShard";s.Shape=Enum.PartType.Ball;s.Size=Vector3.new(1.8,1.8,1.8)
        s.Position=plat.Position+Vector3.new(0,3.5,0);s.Anchored=true;s.CanCollide=false
        s.Material=Enum.Material.Neon;s.Color=Color3.fromRGB(130,90,255)
        addParticles(s,Color3.fromRGB(160,110,255));spinPart(s)
        local bb=Instance.new("BillboardGui",s);bb.Size=UDim2.new(0,40,0,24);bb.StudsOffset=Vector3.new(0,2,0)
        local l=Instance.new("TextLabel",bb);l.Size=UDim2.new(1,0,1,0);l.BackgroundTransparency=1
        l.TextColor3=Color3.fromRGB(200,160,255);l.TextScaled=true;l.Font=Enum.Font.GothamBold;l.Text="◆"
        table.insert(GS.RealityShards,s)
    end
    lblReality.Text="Reality Shards: 0 / "..count
end

local function spawnCosmicShards(count,platforms)
    GS.CosmicShards={};GS.CollectedCosmic=0
    local pool={}
    for _,p in ipairs(platforms) do if p and p.Parent and p.Name~="SpawnPlatform" then table.insert(pool,p) end end
    for i=#pool,2,-1 do local j=math.random(1,i);pool[i],pool[j]=pool[j],pool[i] end
    for i=1,math.min(count,#pool) do
        local plat=pool[i]; if not plat or not plat.Parent then continue end
        local s=Instance.new("Part",SHARD_FOLDER)
        s.Name="CosmicShard";s.Shape=Enum.PartType.Ball;s.Size=Vector3.new(2.2,2.2,2.2)
        s.Position=plat.Position+Vector3.new(0,4,0);s.Anchored=true;s.CanCollide=false
        s.Material=Enum.Material.Neon;s.Color=Color3.fromRGB(255,205,40)
        addParticles(s,Color3.fromRGB(255,215,0));spinPart(s)
        local bb=Instance.new("BillboardGui",s);bb.Size=UDim2.new(0,40,0,24);bb.StudsOffset=Vector3.new(0,2,0)
        local l=Instance.new("TextLabel",bb);l.Size=UDim2.new(1,0,1,0);l.BackgroundTransparency=1
        l.TextColor3=Color3.fromRGB(255,215,0);l.TextScaled=true;l.Font=Enum.Font.GothamBold;l.Text="✦"
        table.insert(GS.CosmicShards,s)
    end
    lblCosmic.Text="Cosmic Shards: 0 / "..count;lblCosmic.Visible=true
end

-- ============================================================
-- SPAWN BEACON
-- ============================================================
local function createSpawnBeacon()
    local old=MAP_FOLDER:FindFirstChild("SpawnBeacon"); if old then old:Destroy() end
    local beam=Instance.new("Part",MAP_FOLDER)
    beam.Name="SpawnBeacon";beam.Size=Vector3.new(6,800,6)
    beam.CFrame=CFrame.new(0,MAP_Y+400,0);beam.Anchored=true;beam.CanCollide=false
    beam.Material=Enum.Material.Neon;beam.Color=Color3.fromRGB(0,255,80);beam.Transparency=0.45
    local a=Instance.new("Attachment",beam)
    local pe=Instance.new("ParticleEmitter",a)
    pe.Color=ColorSequence.new(Color3.fromRGB(0,255,80));pe.LightEmission=1;pe.Rate=40
    pe.Speed=NumberRange.new(3,10);pe.Lifetime=NumberRange.new(0.8,2)
    pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
    task.spawn(function()
        while beam.Parent do
            TweenService:Create(beam,TweenInfo.new(0.8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=0.72}):Play()
            task.wait(1)
        end
    end)
end

-- ============================================================
-- MUSHROOM CLOUD
-- ============================================================
local function createMushroomCloud(pos,shatter)
    local sc=shatter and 1.7 or 1.0
    playSound(SFX.NukeExplosion, 2, pos)

    local ring=Instance.new("Part",workspace)
    ring.Shape=Enum.PartType.Cylinder;ring.Size=Vector3.new(2,6,6)
    ring.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2)
    ring.Anchored=true;ring.CanCollide=false;ring.Material=Enum.Material.Neon
    ring.Color=Color3.fromRGB(255,160,30);ring.Transparency=0.1
    TweenService:Create(ring,TweenInfo.new(1.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(2,240*sc,240*sc),Transparency=1}):Play()
    Debris:AddItem(ring,1.5)

    local fb=Instance.new("Part",workspace)
    fb.Shape=Enum.PartType.Ball;fb.Size=Vector3.new(5,5,5);fb.Position=pos
    fb.Anchored=true;fb.CanCollide=false;fb.Material=Enum.Material.Neon;fb.Color=Color3.fromRGB(255,70,0)
    TweenService:Create(fb,TweenInfo.new(0.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(90*sc,90*sc,90*sc),Transparency=0.15}):Play()
    task.delay(0.6,function() TweenService:Create(fb,TweenInfo.new(2),{Transparency=1}):Play();Debris:AddItem(fb,2.1) end)

    local og=Instance.new("Part",workspace)
    og.Shape=Enum.PartType.Ball;og.Size=Vector3.new(10,10,10);og.Position=pos
    og.Anchored=true;og.CanCollide=false;og.Material=Enum.Material.Neon
    og.Color=Color3.fromRGB(255,200,50);og.Transparency=0.5
    TweenService:Create(og,TweenInfo.new(0.9,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(130*sc,130*sc,130*sc),Transparency=0.75}):Play()
    task.delay(0.9,function() TweenService:Create(og,TweenInfo.new(2.5),{Transparency=1}):Play();Debris:AddItem(og,2.6) end)

    local stemH=170*sc
    local stem=Instance.new("Part",workspace)
    stem.Size=Vector3.new(18*sc,2,18*sc);stem.Position=pos;stem.Anchored=true;stem.CanCollide=false
    stem.Material=Enum.Material.SmoothPlastic;stem.Color=Color3.fromRGB(72,52,42)
    TweenService:Create(stem,TweenInfo.new(2.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(13*sc,stemH,13*sc),Position=pos+Vector3.new(0,stemH/2,0)}):Play()
    task.delay(3.8,function() TweenService:Create(stem,TweenInfo.new(2.5),{Transparency=1}):Play();Debris:AddItem(stem,2.6) end)

    local stemG=Instance.new("Part",workspace)
    stemG.Size=Vector3.new(23*sc,2,23*sc);stemG.Position=pos;stemG.Anchored=true;stemG.CanCollide=false
    stemG.Material=Enum.Material.Neon;stemG.Color=Color3.fromRGB(255,110,15);stemG.Transparency=0.58
    TweenService:Create(stemG,TweenInfo.new(2.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(16*sc,stemH*0.9,16*sc),Position=pos+Vector3.new(0,stemH*0.45,0),Transparency=0.8}):Play()
    task.delay(3.4,function() TweenService:Create(stemG,TweenInfo.new(2),{Transparency=1}):Play();Debris:AddItem(stemG,2.1) end)

    task.spawn(function()
        task.wait(1.55)
        local capPos=pos+Vector3.new(0,stemH,0)
        local cap=Instance.new("Part",workspace)
        cap.Shape=Enum.PartType.Ball;cap.Size=Vector3.new(12,12,12);cap.Position=capPos
        cap.Anchored=true;cap.CanCollide=false;cap.Material=Enum.Material.SmoothPlastic;cap.Color=Color3.fromRGB(82,60,50)
        TweenService:Create(cap,TweenInfo.new(2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(185*sc,100*sc,185*sc)}):Play()
        task.delay(4,function() TweenService:Create(cap,TweenInfo.new(2.5),{Transparency=1}):Play();Debris:AddItem(cap,2.6) end)
        local capG=Instance.new("Part",workspace)
        capG.Shape=Enum.PartType.Ball;capG.Size=Vector3.new(14,14,14);capG.Position=capPos
        capG.Anchored=true;capG.CanCollide=false;capG.Material=Enum.Material.Neon
        capG.Color=Color3.fromRGB(255,150,20);capG.Transparency=0.38
        TweenService:Create(capG,TweenInfo.new(2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(200*sc,78*sc,200*sc),Transparency=0.72}):Play()
        task.delay(3.5,function() TweenService:Create(capG,TweenInfo.new(2),{Transparency=1}):Play();Debris:AddItem(capG,2.1) end)
        local cr=Instance.new("Part",workspace)
        cr.Shape=Enum.PartType.Cylinder;cr.Size=Vector3.new(2,8,8)
        cr.CFrame=CFrame.new(capPos)*CFrame.Angles(0,0,math.pi/2)
        cr.Anchored=true;cr.CanCollide=false;cr.Material=Enum.Material.Neon
        cr.Color=Color3.fromRGB(255,200,60);cr.Transparency=0.28
        TweenService:Create(cr,TweenInfo.new(1.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(2,210*sc,210*sc),Transparency=1}):Play()
        Debris:AddItem(cr,1.9)
    end)

    for _=1,24 do
        local d=Instance.new("Part",workspace)
        d.Size=Vector3.new(math.random(2,7),math.random(2,7),math.random(2,7))
        d.Position=pos+Vector3.new(0,math.random(4,16),0)
        d.Material=Enum.Material.SmoothPlastic;d.Color=Color3.fromRGB(90+math.random(0,40),68+math.random(0,20),50)
        d.CanCollide=true
        local bv=Instance.new("BodyVelocity",d); local ang=math.random()*math.pi*2
        bv.Velocity=Vector3.new(math.cos(ang)*math.random(45,115)*sc,math.random(60,150)*sc,math.sin(ang)*math.random(45,115)*sc)
        bv.MaxForce=Vector3.new(1e5,1e5,1e5); Debris:AddItem(d,math.random(4,9))
    end
    for _=1,12 do
        local d=Instance.new("Part",workspace)
        d.Shape=Enum.PartType.Ball;d.Size=Vector3.new(1.5,1.5,1.5)*sc
        d.Position=pos+Vector3.new(0,8,0);d.CanCollide=false
        d.Material=Enum.Material.Neon;d.Color=Color3.fromRGB(255,math.random(100,200),0)
        local bv=Instance.new("BodyVelocity",d); local ang=math.random()*math.pi*2
        bv.Velocity=Vector3.new(math.cos(ang)*math.random(38,85)*sc,math.random(90,180)*sc,math.sin(ang)*math.random(38,85)*sc)
        bv.MaxForce=Vector3.new(1e5,1e5,1e5)
        TweenService:Create(d,TweenInfo.new(4),{Transparency=1}):Play(); Debris:AddItem(d,4)
    end
    shakeCamera(shatter and 4.8 or 2.9,shatter and 4.2 or 3.0)

    local hrp=getHRP()
    if hrp then
        local dist=(hrp.Position-pos).Magnitude
        local r=(shatter and 75 or 50)*sc
        if dist<r then
            local hum=getHum()
            if hum and hum.Health>0 then hum.Health=math.max(0,hum.Health-(shatter and 200 or 150)) end
            local dir3=(hrp.Position-pos); if dir3.Magnitude>0 then dir3=dir3.Unit end
            local bv=Instance.new("BodyVelocity",hrp)
            bv.Velocity=dir3*95+Vector3.new(0,70,0);bv.MaxForce=Vector3.new(1e5,1e5,1e5)
            Debris:AddItem(bv,0.28)
        end
    end
end

-- ============================================================
-- ENTITY HELPERS
-- ============================================================
local function anyMapPlat()
    local valid={}
    for _,p in ipairs(GS.MapPlatforms) do
        if p and p.Parent then table.insert(valid,p) end
    end
    if #valid==0 then return nil end
    return valid[math.random(1,#valid)]
end

-- ============================================================
-- ENTITY AIs
-- ============================================================

-- FOLLOWER (Anchored=true body — moved via CFrame each frame)
local function spawnFollower(def,platforms)
    if #platforms==0 then return end
    local sp=anyMapPlat() or platforms[math.random(1,#platforms)]

    local model=Instance.new("Model",ENTITY_FOLDER); model.Name="Follower"
    local body=Instance.new("Part",model)
    body.Name="HumanoidRootPart";body.Shape=Enum.PartType.Ball;body.Size=Vector3.new(4.5,4.5,4.5)
    body.Position=sp.Position+Vector3.new(0,7,0)
    body.Material=Enum.Material.SmoothPlastic;body.Color=def.BodyColor
    body.CanCollide=false;body.Anchored=true  -- Anchored! No gravity drift

    local pot=Instance.new("Part",model)
    pot.Size=Vector3.new(3.2,2.8,3.2);pot.Material=Enum.Material.SmoothPlastic
    pot.Color=Color3.fromRGB(101,72,42);pot.CanCollide=false;pot.Anchored=true
    pot.Position=body.Position-Vector3.new(0,3.3,0)

    for _,sx in ipairs({-0.9,0.9}) do
        local eye=Instance.new("Part",model)
        eye.Shape=Enum.PartType.Ball;eye.Size=Vector3.new(0.7,0.7,0.7)
        eye.Material=Enum.Material.Neon;eye.Color=Color3.fromRGB(255,255,255)
        eye.CanCollide=false;eye.Anchored=true
        eye.Position=body.Position+Vector3.new(sx,0.4,-2.1)
    end

    local att=Instance.new("Attachment",body)
    local pe=Instance.new("ParticleEmitter",att)
    pe.Color=ColorSequence.new(def.ParticleColor);pe.LightEmission=0.7;pe.Rate=24
    pe.Speed=NumberRange.new(0.5,2.5);pe.Lifetime=NumberRange.new(0.4,1.4)
    pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,0)})

    local bb=Instance.new("BillboardGui",body)
    bb.Size=UDim2.new(0,100,0,28);bb.StudsOffset=Vector3.new(0,4,0);bb.AlwaysOnTop=true
    local bl=Instance.new("TextLabel",bb);bl.Size=UDim2.new(1,0,1,0)
    bl.BackgroundTransparency=1;bl.TextColor3=Color3.fromRGB(0,255,80)
    bl.TextScaled=true;bl.Font=Enum.Font.GothamBold;bl.Text="Follower"

    model.PrimaryPart=body;table.insert(GS.Entities,model)

    local conn=RunService.Heartbeat:Connect(function(dt)
        if not model.Parent then return end
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        local hrp=getHRP(); if not hrp then return end
        local speed=GS.IsShatter and def.ShatterSpeed or def.Speed
        local diff=hrp.Position-body.Position; local dist=diff.Magnitude
        if dist>0.8 then
            local newCF=CFrame.new(body.Position+diff.Unit*speed*dt,hrp.Position)
            body.CFrame=newCF
            pot.CFrame=newCF*CFrame.new(0,-3.3,0)
        end
        if dist<5 then
            local hum=getHum()
            if hum and hum.Health>0 then hum.Health=math.max(0,hum.Health-def.Damage*dt*4) end
        end
    end)
    table.insert(GS.EntityConns,conn)
end

-- SEED
local function spawnSeed(def,platforms)
    if #platforms==0 then return end
    local model=Instance.new("Model",ENTITY_FOLDER);model.Name="Seed"
    local body=Instance.new("Part",model)
    body.Name="Root";body.Shape=Enum.PartType.Ball;body.Size=Vector3.new(3.5,3.5,3.5)
    body.Position=platforms[math.random(1,#platforms)].Position+Vector3.new(0,5,0)
    body.Anchored=true;body.CanCollide=false
    body.Material=Enum.Material.Neon;body.Color=def.BodyColor
    model.PrimaryPart=body;table.insert(GS.Entities,model)

    local infected={}
    local function cleanInfected()
        for _,p in ipairs(infected) do
            if p and p.Parent then
                p.Material=Enum.Material.SmoothPlastic
                local oc=p:GetAttribute("OrigColor"); if oc then p.Color=oc end
                p:SetAttribute("SeedInfected",false)
            end
        end; infected={}
    end
    local function infectAround(centre)
        cleanInfected()
        playSound(SFX.SeedInfect, 1, centre.Position)
        local count=GS.IsShatter and def.ShatterInfectCount or def.InfectCount
        local function infect(p)
            p.Material=Enum.Material.Neon;p.Color=Color3.fromRGB(128,0,210)
            p:SetAttribute("SeedInfected",true);table.insert(infected,p)
        end
        infect(centre)
        if count>1 then
            local near={}
            for _,p in ipairs(GS.MapPlatforms) do
                if p and p.Parent and p~=centre then table.insert(near,{p=p,d=(p.Position-centre.Position).Magnitude}) end
            end
            table.sort(near,function(a,b) return a.d<b.d end)
            for i=1,math.min(count-1,#near) do infect(near[i].p) end
        end
    end

    local vp={}
    for _,p in ipairs(GS.MapPlatforms) do if p and p.Parent then table.insert(vp,p) end end
    if #vp>0 then local f=vp[math.random(1,#vp)]; body.Position=f.Position+Vector3.new(0,4,0); infectAround(f) end

    local timer=0;local dmgCd={}
    local conn=RunService.Heartbeat:Connect(function(dt)
        if not model.Parent then return end
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        timer+=dt
        if timer>=(GS.IsShatter and def.ShatterTeleportInterval or def.TeleportInterval) then
            timer=0
            local vp2={}
            for _,p in ipairs(GS.MapPlatforms) do if p and p.Parent then table.insert(vp2,p) end end
            if #vp2>0 then
                local np=vp2[math.random(1,#vp2)];body.Position=np.Position+Vector3.new(0,4,0);infectAround(np)
            end
        end
        local hrp=getHRP(); if not hrp then return end
        for _,p in ipairs(infected) do
            if p and p.Parent and p:GetAttribute("SeedInfected") then
                local pp=p.Position;local rp=hrp.Position
                if math.abs(rp.X-pp.X)<11 and math.abs(rp.Z-pp.Z)<11 and rp.Y-pp.Y>0 and rp.Y-pp.Y<5 then
                    local now=tick()
                    if not dmgCd[p] or now-dmgCd[p]>1.5 then
                        dmgCd[p]=now
                        local hum=getHum()
                        if hum and hum.Health>0 then
                            hum.Health=math.max(0,hum.Health-def.Damage)
                            local bv=Instance.new("BodyVelocity",hrp)
                            bv.Velocity=Vector3.new(math.random(-15,15),65,math.random(-15,15));bv.MaxForce=Vector3.new(1e4,1e5,1e4)
                            Debris:AddItem(bv,0.18)
                        end
                    end
                end
            end
        end
    end)
    table.insert(GS.EntityConns,conn)
end

-- TARGET
local function spawnTarget(def,platforms)
    local timer=0;local nukeActive=false
    local conn=RunService.Heartbeat:Connect(function(dt)
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        timer+=dt
        if timer>=(GS.IsShatter and def.ShatterInterval or def.Interval) and not nukeActive then
            timer=0;nukeActive=true
            task.spawn(function()
                local hrp=getHRP(); if not hrp then nukeActive=false;return end
                local tPos=hrp.Position
                local radius=GS.IsShatter and def.ShatterRadius or def.Radius
                local circ=Instance.new("Part",MAP_FOLDER)
                circ.Name="NukeCircle";circ.Shape=Enum.PartType.Cylinder
                circ.Size=Vector3.new(1.5,radius*2,radius*2)
                circ.CFrame=CFrame.new(tPos.X,tPos.Y-2,tPos.Z)*CFrame.Angles(0,0,math.pi/2)
                circ.Anchored=true;circ.CanCollide=false
                circ.Material=Enum.Material.Neon;circ.Color=Color3.fromRGB(180,0,255);circ.Transparency=0.35
                task.spawn(function()
                    for _=1,10 do
                        if not circ.Parent then break end
                        TweenService:Create(circ,TweenInfo.new(0.25),{Transparency=0.7}):Play();task.wait(0.25)
                        if not circ.Parent then break end
                        TweenService:Create(circ,TweenInfo.new(0.25),{Transparency=0.18}):Play();task.wait(0.25)
                    end
                end)
                local warn=Instance.new("TextLabel",GUI)
                warn.Size=UDim2.new(0.6,0,0,54);warn.Position=UDim2.new(0.2,0,0.28,0)
                warn.BackgroundTransparency=1;warn.TextColor3=Color3.fromRGB(255,40,255)
                warn.TextScaled=true;warn.Font=Enum.Font.GothamBold
                warn.Text="⚠  INCOMING STRIKE  ⚠";warn.ZIndex=15
                TweenService:Create(warn,TweenInfo.new(4.8),{TextTransparency=1}):Play();Debris:AddItem(warn,5)
                task.wait(5); if circ.Parent then circ:Destroy() end
                local mis=Instance.new("Part",MAP_FOLDER)
                mis.Name="NukeMissile";mis.Size=Vector3.new(2.5,22,2.5)
                mis.Position=Vector3.new(tPos.X,tPos.Y+700,tPos.Z)
                mis.Anchored=true;mis.CanCollide=false
                mis.Material=Enum.Material.Neon;mis.Color=Color3.fromRGB(255,80,0)
                local ma=Instance.new("Attachment",mis)
                local mpe=Instance.new("ParticleEmitter",ma)
                mpe.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,80,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,220,0))})
                mpe.LightEmission=1;mpe.Rate=120;mpe.Speed=NumberRange.new(10,24)
                mpe.Lifetime=NumberRange.new(0.2,0.8)
                mpe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,3),NumberSequenceKeypoint.new(1,0)})
                TweenService:Create(mis,TweenInfo.new(1.8,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=Vector3.new(tPos.X,tPos.Y,tPos.Z)}):Play()
                task.wait(1.85); if mis.Parent then mis:Destroy() end
                createMushroomCloud(tPos,GS.IsShatter)
                nukeActive=false
            end)
        end
    end)
    table.insert(GS.EntityConns,conn)
end

-- WORMHOLE
local function spawnWormhole(def,platforms)
    local timer=0;local whActive=false
    local conn=RunService.Heartbeat:Connect(function(dt)
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        timer+=dt
        if timer>=(GS.IsShatter and def.ShatterInterval or def.Interval) and not whActive then
            timer=0;whActive=true
            task.spawn(function()
                local sp=anyMapPlat(); if not sp then whActive=false;return end
                local whPos=sp.Position+Vector3.new(0,30,0)
                local wModel=Instance.new("Model",ENTITY_FOLDER); wModel.Name="WormholeModel"
                local core=Instance.new("Part",wModel)
                core.Shape=Enum.PartType.Ball;core.Size=Vector3.new(8,8,8)
                core.Position=whPos;core.Anchored=true;core.CanCollide=false
                core.Material=Enum.Material.Neon;core.Color=Color3.fromRGB(15,0,30);core.Transparency=0.1
                local ring1=Instance.new("Part",wModel)
                ring1.Shape=Enum.PartType.Cylinder;ring1.Size=Vector3.new(1.5,22,22)
                ring1.CFrame=CFrame.new(whPos);ring1.Anchored=true;ring1.CanCollide=false
                ring1.Material=Enum.Material.Neon;ring1.Color=Color3.fromRGB(80,0,200);ring1.Transparency=0.25
                local ring2=Instance.new("Part",wModel)
                ring2.Shape=Enum.PartType.Cylinder;ring2.Size=Vector3.new(1.5,20,20)
                ring2.CFrame=CFrame.new(whPos)*CFrame.Angles(math.rad(45),0,0)
                ring2.Anchored=true;ring2.CanCollide=false
                ring2.Material=Enum.Material.Neon;ring2.Color=Color3.fromRGB(150,0,255);ring2.Transparency=0.35
                local att=Instance.new("Attachment",core)
                local pe=Instance.new("ParticleEmitter",att)
                pe.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(150,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(40,0,100))})
                pe.LightEmission=1;pe.Rate=35;pe.Speed=NumberRange.new(3,9)
                pe.Lifetime=NumberRange.new(0.3,1.2)
                pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(1,0)})
                local bb=Instance.new("BillboardGui",core)
                bb.Size=UDim2.new(0,130,0,32);bb.StudsOffset=Vector3.new(0,13,0);bb.AlwaysOnTop=true
                local wbl=Instance.new("TextLabel",bb);wbl.Size=UDim2.new(1,0,1,0)
                wbl.BackgroundTransparency=1;wbl.TextColor3=Color3.fromRGB(200,80,255)
                wbl.TextScaled=true;wbl.Font=Enum.Font.GothamBold;wbl.Text="⚠ WORMHOLE"
                local screenW=Instance.new("TextLabel",GUI)
                screenW.Size=UDim2.new(0.6,0,0,44);screenW.Position=UDim2.new(0.2,0,0.35,0)
                screenW.BackgroundTransparency=1;screenW.TextColor3=Color3.fromRGB(180,0,255)
                screenW.TextScaled=true;screenW.Font=Enum.Font.GothamBold
                screenW.Text="⚠  WORMHOLE APPEARED  ⚠";screenW.ZIndex=12
                TweenService:Create(screenW,TweenInfo.new(3),{TextTransparency=1}):Play();Debris:AddItem(screenW,3.5)

                local duration=GS.IsShatter and def.ShatterDuration or def.Duration
                local pullForce=GS.IsShatter and def.ShatterPullForce or def.PullForce
                local elapsed=0
                local spinConn=RunService.Heartbeat:Connect(function(sDt)
                    if not ring1.Parent then return end
                    ring1.CFrame=ring1.CFrame*CFrame.Angles(0,sDt*2.5,0)
                    ring2.CFrame=ring2.CFrame*CFrame.Angles(sDt*1.8,sDt*1.2,0)
                    elapsed+=sDt
                    local hrp=getHRP()
                    if hrp then
                        local toWH=whPos-hrp.Position; local dist=toWH.Magnitude
                        if dist<90 then
                            local strength=pullForce*(1-(dist/90))^0.7
                            local bf=Instance.new("BodyForce",hrp)
                            bf.Force=toWH.Unit*strength*50; Debris:AddItem(bf,0.05)
                            local hum=getHum()
                            if hum then
                                local st=hum:GetState()
                                local airborne=(st==Enum.HumanoidStateType.Freefall or st==Enum.HumanoidStateType.Jumping)
                                if airborne and dist<def.KillRadius*2.5 then
                                    if hum.Health>0 then hum.Health=0 end
                                end
                                if dist<def.KillRadius then
                                    if hum.Health>0 then hum.Health=0 end
                                end
                            end
                        end
                    end
                    if elapsed>=duration then
                        spinConn:Disconnect()
                        if core.Parent then
                            TweenService:Create(core,TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=Vector3.new(0.1,0.1,0.1),Transparency=1}):Play()
                            TweenService:Create(ring1,TweenInfo.new(0.5),{Size=Vector3.new(0.1,0.1,0.1),Transparency=1}):Play()
                            TweenService:Create(ring2,TweenInfo.new(0.5),{Size=Vector3.new(0.1,0.1,0.1),Transparency=1}):Play()
                            Debris:AddItem(wModel,0.7)
                        end
                        task.wait(0.7); whActive=false
                    end
                end)
                table.insert(GS.EntityConns,spinConn)
            end)
        end
    end)
    table.insert(GS.EntityConns,conn)
end

-- HELLOWORLD (Anchored=true — no gravity drift)
local function spawnHelloworld(def,platforms)
    if #platforms==0 then return end
    local sp=anyMapPlat() or platforms[math.random(1,#platforms)]

    local model=Instance.new("Model",ENTITY_FOLDER);model.Name="helloworld"
    local body=Instance.new("Part",model)
    body.Name="HumanoidRootPart";body.Size=Vector3.new(4,4,4)
    body.Position=sp.Position+Vector3.new(0,6,0)
    body.Material=Enum.Material.Neon;body.Color=Color3.fromRGB(0,200,255)
    body.CanCollide=false;body.Anchored=true  -- Anchored! No gravity drift

    for _,sx in ipairs({-1,1}) do
        local eye=Instance.new("Part",model)
        eye.Shape=Enum.PartType.Ball;eye.Size=Vector3.new(0.9,0.9,0.9)
        eye.Material=Enum.Material.Neon;eye.Color=Color3.fromRGB(255,0,80)
        eye.CanCollide=false;eye.Anchored=true
        eye.Position=body.Position+Vector3.new(sx,0.3,-2.1)
    end

    local att=Instance.new("Attachment",body)
    local pe=Instance.new("ParticleEmitter",att)
    pe.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,80,180))})
    pe.LightEmission=1;pe.Rate=30;pe.Speed=NumberRange.new(1,4)
    pe.Lifetime=NumberRange.new(0.3,1)
    pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.5),NumberSequenceKeypoint.new(1,0)})

    local bb=Instance.new("BillboardGui",body)
    bb.Size=UDim2.new(0,110,0,28);bb.StudsOffset=Vector3.new(0,4,0);bb.AlwaysOnTop=true
    local bl=Instance.new("TextLabel",bb);bl.Size=UDim2.new(1,0,1,0)
    bl.BackgroundTransparency=1;bl.TextColor3=Color3.fromRGB(0,220,255)
    bl.TextScaled=true;bl.Font=Enum.Font.GothamBold;bl.Text="helloworld"

    model.PrimaryPart=body;table.insert(GS.Entities,model)

    local tpTimer=0;local dmgCd=0;local charging=false

    local conn=RunService.Heartbeat:Connect(function(dt)
        if not model.Parent then return end
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        local hrp=getHRP(); if not hrp then return end

        local speed=GS.IsShatter and def.ShatterSpeed or def.Speed
        local diff=hrp.Position-body.Position; local dist=diff.Magnitude

        if dist>0.8 then
            body.CFrame=CFrame.new(body.Position+diff.Unit*speed*dt,hrp.Position)
        end

        tpTimer+=dt
        local tpInterval=GS.IsShatter and def.ShatterTeleportInterval or def.TeleportInterval
        local chargeStart=tpInterval-1.2  -- charge sound fires 1.2s before teleport

        if tpTimer>=chargeStart and not charging then
            charging=true
            playSound(SFX.HelloworldCharge, 1.2)
        end

        if tpTimer>=tpInterval then
            tpTimer=0;charging=false
            playSound(SFX.HelloworldTeleport, 1.5)
            local lookVec=hrp.CFrame.LookVector
            local targetPos=hrp.Position+lookVec*15

            local flash=Instance.new("Part",workspace)
            flash.Shape=Enum.PartType.Ball;flash.Size=Vector3.new(5,5,5)
            flash.Position=targetPos;flash.Anchored=true;flash.CanCollide=false
            flash.Material=Enum.Material.Neon;flash.Color=Color3.fromRGB(0,220,255);flash.Transparency=0.2
            TweenService:Create(flash,TweenInfo.new(0.4),{Size=Vector3.new(0.1,0.1,0.1),Transparency=1}):Play()
            Debris:AddItem(flash,0.5)

            body.CFrame=CFrame.new(targetPos,hrp.Position)
        end

        if dist<4.5 then
            local now=tick()
            if now-dmgCd>0.3 then
                dmgCd=now
                local hum=getHum()
                if hum and hum.Health>0 then hum.Health=math.max(0,hum.Health-def.Damage*dt*5) end
            end
        end
    end)
    table.insert(GS.EntityConns,conn)
end

-- KEEPER
local function spawnKeeper(def,platforms)
    if #platforms==0 then return end
    local sp=anyMapPlat() or platforms[math.random(1,#platforms)]

    local model=Instance.new("Model",ENTITY_FOLDER);model.Name="Keeper"
    local body=Instance.new("Part",model)
    body.Name="HumanoidRootPart";body.Size=Vector3.new(5,5,5)
    body.Position=sp.Position+Vector3.new(0,8,0)
    body.Material=Enum.Material.Neon;body.Color=Color3.fromRGB(220,0,0)
    body.CanCollide=false;body.Anchored=true

    -- Transparent red zone disc
    local zone=Instance.new("Part",model)
    zone.Name="KeeperZone";zone.Shape=Enum.PartType.Cylinder
    local zoneR=(GS.IsShatter and def.ShatterAreaRadius or def.AreaRadius)
    zone.Size=Vector3.new(1,zoneR*2,zoneR*2)
    zone.CFrame=body.CFrame*CFrame.Angles(0,0,math.pi/2)
    zone.Anchored=true;zone.CanCollide=false
    zone.Material=Enum.Material.Neon;zone.Color=Color3.fromRGB(255,0,0);zone.Transparency=0.82

    local bb=Instance.new("BillboardGui",body)
    bb.Size=UDim2.new(0,100,0,28);bb.StudsOffset=Vector3.new(0,5,0);bb.AlwaysOnTop=true
    local bl=Instance.new("TextLabel",bb);bl.Size=UDim2.new(1,0,1,0)
    bl.BackgroundTransparency=1;bl.TextColor3=Color3.fromRGB(255,60,60)
    bl.TextScaled=true;bl.Font=Enum.Font.GothamBold;bl.Text="Keeper"

    model.PrimaryPart=body;table.insert(GS.Entities,model)

    -- Timer label on HUD
    local timerLbl=mkLabel(GUI,{
        Size=UDim2.new(0,200,0,38),Position=UDim2.new(0.5,-100,0,100),
        BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,80,80),
        TextScaled=true,Font=Enum.Font.GothamBold,Text="",Visible=false,ZIndex=8,
    })

    local tpTimer=0
    local chasing=false
    local walkTimer=0
    local prevPos=nil

    local tpConn=RunService.Heartbeat:Connect(function(dt)
        if not model.Parent then return end
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end

        tpTimer+=dt
        if tpTimer>=def.TeleportInterval then
            tpTimer=0
            local np=anyMapPlat()
            if np then
                body.CFrame=CFrame.new(np.Position+Vector3.new(0,8,0))
                local zR=GS.IsShatter and def.ShatterAreaRadius or def.AreaRadius
                zone.Size=Vector3.new(1,zR*2,zR*2)
                zone.CFrame=body.CFrame*CFrame.Angles(0,0,math.pi/2)
            end
        end

        local hrp=getHRP(); if not hrp then return end
        local hum=getHum(); if not hum then return end
        local rp=hrp.Position
        local bp=body.Position

        local zoneRadius=GS.IsShatter and def.ShatterAreaRadius or def.AreaRadius
        local inZone=(Vector3.new(rp.X,bp.Y,rp.Z)-bp).Magnitude < zoneRadius

        -- Sync zone disc pos
        zone.CFrame=CFrame.new(bp.X,bp.Y,bp.Z)*CFrame.Angles(0,0,math.pi/2)

        if chasing then
            -- Chase at 20 speed
            local diff=rp-body.Position; local dist=diff.Magnitude
            if dist>1 then body.CFrame=CFrame.new(bp+diff.Unit*def.ChaseSpeed*dt,rp) end
            if dist<5 and hum.Health>0 then hum.Health=math.max(0,hum.Health-def.Damage*dt*4) end
        else
            if inZone then
                -- Check if walking (position changed since last frame)
                local isWalking=false
                if prevPos then
                    local moved=(Vector3.new(rp.X,0,rp.Z)-Vector3.new(prevPos.X,0,prevPos.Z)).Magnitude
                    isWalking=moved>0.05
                end
                if isWalking then
                    walkTimer+=dt
                    local needed=GS.IsShatter and def.ShatterWalkTime or def.WalkTime
                    local remaining=math.max(0,math.ceil(needed-walkTimer))
                    timerLbl.Text="⚠ Stop! "..remaining.."s"
                    timerLbl.Visible=true
                    if walkTimer>=needed then
                        chasing=true
                        timerLbl.Visible=false
                    end
                else
                    walkTimer=0
                    timerLbl.Text="⚠ Stop! "..(GS.IsShatter and def.ShatterWalkTime or def.WalkTime).."s"
                    timerLbl.Visible=true
                end
            else
                walkTimer=0
                timerLbl.Visible=false
            end
        end
        prevPos=rp
    end)
    table.insert(GS.EntityConns,tpConn)

    -- Cleanup label on phase change
    local cleanConn=RunService.Heartbeat:Connect(function()
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then
            timerLbl:Destroy()
            cleanConn:Disconnect()
        end
    end)
    table.insert(GS.EntityConns,cleanConn)
end

-- CAMERA ENTITY
local function spawnCameraEntity(def,platforms)
    local timer=0;local flashActive=false

    local conn=RunService.Heartbeat:Connect(function(dt)
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        timer+=dt
        local interval=GS.IsShatter and def.ShatterInterval or def.Interval
        if timer>=interval and not flashActive then
            timer=0;flashActive=true
            task.spawn(function()
                local flashes=GS.IsShatter and 3 or 1
                for fi=1,flashes do
                    if GS.Phase=="DEAD" then break end

                    -- "Say Cheese!" warning
                    local cheese=Instance.new("TextLabel",GUI)
                    cheese.Size=UDim2.new(0.7,0,0,60);cheese.Position=UDim2.new(0.15,0,0.18,0)
                    cheese.BackgroundTransparency=1;cheese.TextColor3=Color3.fromRGB(255,255,200)
                    cheese.TextScaled=true;cheese.Font=Enum.Font.GothamBold
                    cheese.Text="📷  Say Cheese!";cheese.ZIndex=16
                    TweenService:Create(cheese,TweenInfo.new(2.8),{TextTransparency=1}):Play()
                    Debris:AddItem(cheese,3)

                    task.wait(def.WarnTime)
                    if GS.Phase=="DEAD" then break end

                    -- Snapshot player position at flash moment
                    local hrp=getHRP(); if not hrp then break end
                    local snapPos=hrp.Position

                    -- White flash overlay + Sound
                    playSound(SFX.CameraFlash, 1.5)
                    local flash=Instance.new("Frame",GUI)
                    flash.Size=UDim2.new(1,0,1,0);flash.BackgroundColor3=Color3.fromRGB(255,255,255)
                    flash.BackgroundTransparency=0;flash.ZIndex=20
                    shakeCamera(1.2,0.5)

                    task.wait(0.08)

                    -- Check if player moved during flash window
                    local hrp2=getHRP()
                    local moved=false
                    if hrp2 then
                        local d=(Vector3.new(hrp2.Position.X,0,hrp2.Position.Z)-Vector3.new(snapPos.X,0,snapPos.Z)).Magnitude
                        moved=d>1.5
                    end

                    if moved then
                        -- Red flash + fling
                        flash.BackgroundColor3=Color3.fromRGB(255,40,40)
                        local dmg=GS.IsShatter and def.ShatterDamage or def.Damage
                        local hum=getHum()
                        if hum and hum.Health>0 then hum.Health=math.max(0,hum.Health-dmg) end
                        if hrp2 then
                            local dirs={
                                Vector3.new(1,0,0),Vector3.new(-1,0,0),
                                Vector3.new(0,0,1),Vector3.new(0,0,-1),
                                Vector3.new(0.7,0.3,0.7),Vector3.new(-0.7,0.3,-0.7),
                            }
                            local d=dirs[math.random(1,#dirs)]
                            local bv=Instance.new("BodyVelocity",hrp2)
                            bv.Velocity=(d.Unit*85)+Vector3.new(0,55,0)
                            bv.MaxForce=Vector3.new(1e5,1e5,1e5); Debris:AddItem(bv,0.22)
                        end
                        shakeCamera(3.5,1.2)
                    end

                    -- Fade out flash
                    TweenService:Create(flash,TweenInfo.new(1.8),{BackgroundTransparency=1}):Play()
                    Debris:AddItem(flash,2)

                    if fi<flashes then task.wait(3) end
                end
                flashActive=false
            end)
        end
    end)
    table.insert(GS.EntityConns,conn)
end

-- DISTORTION ENTITY
local function spawnDistortion(def, platforms, isShatterExtra, rank)
    task.spawn(function()
        if not isShatterExtra then task.wait(5) end
        if GS.Phase == "DEAD" or GS.Phase == "LOBBY" then return end
        
        local function getTarget()
            if rank == 1 then return getHRP() end
            local prevDist = GS.Distortions[rank - 1]
            return prevDist and prevDist.PrimaryPart or getHRP()
        end

        local target = getTarget()
        local spawnPos = target and target.Position or Vector3.new(0, MAP_Y+5, 0)

        -- Purple Light Sequence
        playSound(SFX.PurpleLight, 1.5, spawnPos)
        local light = Instance.new("Part", MAP_FOLDER)
        light.Shape = Enum.PartType.Ball; light.Size = Vector3.new(2, 2, 2)
        light.Position = spawnPos; light.Anchored = true; light.CanCollide = false
        light.Material = Enum.Material.Neon; light.Color = Color3.fromRGB(150, 0, 255)
        TweenService:Create(light, TweenInfo.new(2), {Size = Vector3.new(6, 6, 6), Transparency = 1}):Play()
        Debris:AddItem(light, 2)

        task.wait(2)
        if GS.Phase == "DEAD" or GS.Phase == "LOBBY" then return end

        -- Distortion Creature Spawn
        playSound(SFX.DistortionSpawn, 1.5, spawnPos)
        local model = Instance.new("Model", ENTITY_FOLDER)
        model.Name = "Distortion_" .. rank
        local body = Instance.new("Part", model)
        body.Name = "HumanoidRootPart"
        body.Size = Vector3.new(4, 5, 4)
        body.Position = spawnPos
        body.Material = Enum.Material.Neon; body.Color = Color3.fromRGB(80, 0, 150)
        body.Anchored = true; body.CanCollide = false
        model.PrimaryPart = body
        table.insert(GS.Entities, model)
        GS.Distortions[rank] = model

        local history = {}
        local conn = RunService.Heartbeat:Connect(function(dt)
            if not model.Parent or GS.Phase == "DEAD" or GS.Phase == "LOBBY" then return end

            local currentTarget = getTarget()
            if currentTarget then
                table.insert(history, {t = tick(), p = currentTarget.Position})
            end

            local delayTime = GS.IsShatter and def.ShatterDelay or def.Delay
            local targetTime = tick() - delayTime

            while #history > 2 and history[2].t < targetTime do
                table.remove(history, 1)
            end

            if #history >= 2 then
                local p1, p2 = history[1], history[2]
                local alpha = math.clamp((targetTime - p1.t) / (p2.t - p1.t), 0, 1)
                body.CFrame = CFrame.new(p1.p:Lerp(p2.p, alpha))
            elseif #history == 1 then
                body.CFrame = CFrame.new(history[1].p)
            end

            local hrp = getHRP()
            if hrp and (hrp.Position - body.Position).Magnitude < 4.5 then
                local hum = getHum()
                if hum and hum.Health > 0 then
                    hum.Health = math.max(0, hum.Health - def.Damage * dt * 5)
                end
            end
        end)
        table.insert(GS.EntityConns, conn)
    end)
end

-- Spawn dispatcher
local function spawnEntities(platforms)
    for _,c in ipairs(GS.EntityConns) do c:Disconnect() end;GS.EntityConns={}
    for _,e in ipairs(GS.Entities)    do if e and e.Parent then e:Destroy() end end;GS.Entities={}
    
    local distCount = 0
    for _,def in ipairs(GS.PickedEntities) do
        if def.AppearRound<=GS.Round then
            if     def.AI=="Follower"  then spawnFollower(def,platforms)
            elseif def.AI=="Seed"      then spawnSeed(def,platforms)
            elseif def.AI=="Target"    then spawnTarget(def,platforms)
            elseif def.AI=="Wormhole"  then spawnWormhole(def,platforms)
            elseif def.AI=="helloworld"then spawnHelloworld(def,platforms)
            elseif def.AI=="Keeper"    then spawnKeeper(def,platforms)
            elseif def.AI=="Camera"    then spawnCameraEntity(def,platforms)
            elseif def.AI=="Distortion"then 
                distCount += 1
                spawnDistortion(def, platforms, false, distCount)
            end
        end
    end
    GS.CurrentDistortionCount = distCount
end

-- ============================================================
-- SHATTER
-- ============================================================
local function startShatter(platforms)
    GS.IsShatter=true;GS.Phase="SHATTER"
    lblPhase.Text="⚠  SHATTER";lblPhase.Visible=true
    lblShatterWarn.Visible=true;lblShatterWarn.TextTransparency=0
    TweenService:Create(lblShatterWarn,TweenInfo.new(2.5),{TextTransparency=1}):Play()
    task.delay(3,function() lblShatterWarn.Visible=false end)
    createSpawnBeacon()
    spawnCosmicShards(GS.TotalShards,platforms)
    
    -- Shatter Extra Distortion Logic
    if GS.CurrentDistortionCount > 0 then
        local distDef
        for _, e in ipairs(GS.PickedEntities) do
            if e.AI == "Distortion" then distDef = e; break end
        end
        if distDef then
            GS.CurrentDistortionCount += 1
            spawnDistortion(distDef, platforms, true, GS.CurrentDistortionCount)
        end
    end

    local toShatter={}
    for _,p in ipairs(GS.MapPlatforms) do
        if p and p.Parent and p.Name~="SpawnPlatform" then table.insert(toShatter,p) end
    end
    for i=#toShatter,2,-1 do local j=math.random(1,i);toShatter[i],toShatter[j]=toShatter[j],toShatter[i] end
    task.spawn(function()
        for _,p in ipairs(toShatter) do
            if GS.Phase~="SHATTER" then break end
            task.wait(5)
            if p and p.Parent then
                p.Material=Enum.Material.Neon;p.Color=Color3.fromRGB(200,40,40)
                task.wait(0.4)
                if p.Parent then
                    TweenService:Create(p,TweenInfo.new(0.5),{Transparency=1}):Play();Debris:AddItem(p,0.5)
                end
            end
        end
    end)
end

-- ============================================================
-- DEATH
-- ============================================================
local deathLock=false
onDeath=function()
    if deathLock or GS.Phase=="DEAD" then return end
    deathLock=true;GS.Phase="DEAD"
    playSound(SFX.PlayerDie, 1.2)
    for _,c in ipairs(GS.EntityConns) do c:Disconnect() end
    task.wait(0.8);HUD.Visible=false
    local names={}
    for _,e in ipairs(GS.PickedEntities) do table.insert(names,e.Name) end
    lblDeathStats.Text=
        "Reality Shards:  "..GS.CollectedReality.." / "..GS.TotalShards.."\n"..
        "Cosmic Shards:   "..GS.CollectedCosmic.." / "..GS.TotalShards.."\n"..
        "Rounds Beaten:   "..GS.RoundsBeaten.."\n"..
        "Entities Faced:  "..(#names>0 and table.concat(names,", ") or "None").."\n\n"..
        "Buffs: Coming Soon™"
    DEATH.Visible=true;deathLock=false
end

-- ============================================================
-- ROUND COMPLETE
-- ============================================================
local function completeRound()
    if GS.Phase~="SHATTER" then return end
    GS.Phase="COMPLETE";GS.RoundsBeaten+=1
    local sb=MAP_FOLDER:FindFirstChild("SpawnBeacon"); if sb then sb:Destroy() end
    for _,c in ipairs(GS.EntityConns) do c:Disconnect() end
    local flash=Instance.new("Frame",GUI)
    flash.Size=UDim2.new(1,0,1,0);flash.BackgroundColor3=Color3.fromRGB(220,220,255);flash.ZIndex=25
    TweenService:Create(flash,TweenInfo.new(1.2),{BackgroundTransparency=1}):Play();Debris:AddItem(flash,1.5)
    task.wait(1.8)
    GS.Round+=1;GS.IsShatter=false
    lblRound.Text="PM "..(GS.Round-1)..":00"
    lblPhase.Visible=false;lblCosmic.Visible=false;HUD.Visible=false
    GS.PickedEntities={};GS.PickedAtLeastOne=false
    clearMap();refreshBeacons()
    GS.Phase="LOBBY"
    local hrp=getHRP(); if hrp then character:PivotTo(CFrame.new(0,LOBBY_Y+6,-42)) end
    local hum=getHum(); if hum then hum.Health=hum.MaxHealth end
end

-- ============================================================
-- START ROUND
-- ============================================================
startRound=function()
    HUD.Visible=true;DEATH.Visible=false
    lblCosmic.Visible=false;lblPhase.Visible=false
    GS.Phase="PLAYING";GS.IsShatter=false
    GS.CollectedReality=0;GS.CollectedCosmic=0
    lblRound.Text="PM "..(GS.Round-1)..":00"
    lblReality.Text="Reality Shards: 0 / ..."
    local platforms=generateMap(GS.Round)
    local count=getShardCount(GS.Round)
    spawnRealityShards(count,platforms)
    spawnEntities(platforms)
    local hrp=getHRP(); if hrp then character:PivotTo(CFrame.new(0,MAP_Y+5,0)) end
end

-- ============================================================
-- COLLECTION LOOP
-- ============================================================
local function startCollectionLoop()
    RunService.Heartbeat:Connect(function()
        if GS.Phase~="PLAYING" and GS.Phase~="SHATTER" then return end
        local hrp=getHRP(); if not hrp then return end
        local pos=hrp.Position
        local hum=getHum()
        if hum and hum.Health<=0 then onDeath();return end
        if pos.Y<MAP_Y-150 then onDeath();return end
        if GS.Phase=="PLAYING" then
            for i=#GS.RealityShards,1,-1 do
                local s=GS.RealityShards[i]
                if s and s.Parent and (pos-s.Position).Magnitude<5.5 then
                    s:Destroy();table.remove(GS.RealityShards,i)
                    GS.CollectedReality+=1
                    lblReality.Text="Reality Shards: "..GS.CollectedReality.." / "..GS.TotalShards
                    if GS.CollectedReality>=GS.TotalShards then
                        lblReality.Text="Reality Shards: ALL COLLECTED ✓"
                        startShatter(GS.MapPlatforms)
                    end
                end
            end
        end
        if GS.Phase=="SHATTER" then
            for i=#GS.CosmicShards,1,-1 do
                local s=GS.CosmicShards[i]
                if s and s.Parent and (pos-s.Position).Magnitude<5.5 then
                    s:Destroy();table.remove(GS.CosmicShards,i)
                    GS.CollectedCosmic+=1
                    lblCosmic.Text="Cosmic Shards: "..GS.CollectedCosmic.." / "..GS.TotalShards
                end
            end
            if (pos-Vector3.new(0,MAP_Y+4,0)).Magnitude<18 then completeRound() end
        end
    end)
end

-- ============================================================
-- BEACON / REROLL
-- ============================================================
local function pickBeaconChoices()
    -- Calculate counts to prevent more than 3 of the same entity
    local counts = {}
    for _, pe in ipairs(GS.PickedEntities) do
        counts[pe.Name] = (counts[pe.Name] or 0) + 1
    end

    local pool={}
    for _,e in ipairs(EntityRegistry) do 
        if e.AppearRound<=GS.Round and (counts[e.Name] or 0) < 3 then 
            table.insert(pool,e) 
        end 
    end
    
    if #pool==0 then pool={table.unpack(EntityRegistry)} end
    
    local used={}
    GS.BeaconChoices={}
    for i=1,BEACON_COUNT do
        local allowDupe= GS.PickedAtLeastOne or (#pool<=BEACON_COUNT-i+1)
        local idx;local t=0
        repeat idx=math.random(1,#pool);t+=1 until allowDupe or not used[idx] or t>30
        used[idx]=true; table.insert(GS.BeaconChoices,pool[idx])
    end
end

local function updateBeaconBillboards()
    local i=0
    for _,obj in ipairs(LOBBY_FOLDER:GetChildren()) do
        if obj.Name:sub(1,9)=="BeaconOrb" then
            i+=1; local e=GS.BeaconChoices[i]; if not e then continue end
            local bb=obj:FindFirstChildOfClass("BillboardGui"); if not bb then continue end
            local bg=bb:FindFirstChildOfClass("Frame"); if not bg then continue end
            for _,l in ipairs(bg:GetChildren()) do
                if l:IsA("TextLabel") then
                    if l.Name=="EntityName" then l.Text=e.Name
                    elseif l.Name=="EntityTip" then l.Text="💡 "..e.Tips end
                end
            end
        end
    end
    local j=0
    for _,obj in ipairs(LOBBY_FOLDER:GetChildren()) do
        if obj.Name:sub(1,11)=="BeaconBase_" then
            j+=1
            local pp=obj:FindFirstChildOfClass("ProximityPrompt")
            if pp and GS.BeaconChoices[j] then pp.ObjectText=GS.BeaconChoices[j].Name end
        end
    end
    local startBase=LOBBY_FOLDER:FindFirstChild("StartBase")
    if startBase then
        local spp=startBase:FindFirstChildOfClass("ProximityPrompt")
        if spp then spp.Enabled=GS.PickedAtLeastOne end
        startBase.Color=GS.PickedAtLeastOne and Color3.fromRGB(20,80,20) or Color3.fromRGB(12,12,12)
    end
end

refreshBeacons=function()
    GS.RerollsLeft=MAX_REROLLS
    pickBeaconChoices()
    updateBeaconBillboards()
    for _,obj in ipairs(LOBBY_FOLDER:GetChildren()) do
        if obj.Name=="RerollSign" then
            local sg=obj:FindFirstChildOfClass("SurfaceGui")
            if sg then local rc=sg:FindFirstChild("RerollCount"); if rc then rc.Text="Rolls left: "..GS.RerollsLeft end end
        end
    end
end

-- ============================================================
-- SELECT ENTITY 
-- ============================================================
selectEntity=function(idx)
    if GS.Phase~="LOBBY" then return end
    local entity=GS.BeaconChoices[idx]; if not entity then return end
    table.insert(GS.PickedEntities,entity)
    GS.PickedAtLeastOne=true

    local flash=Instance.new("Frame",GUI)
    flash.Size=UDim2.new(1,0,1,0);flash.BackgroundColor3=Color3.fromRGB(70,0,140)
    flash.BackgroundTransparency=0.28;flash.ZIndex=20
    TweenService:Create(flash,TweenInfo.new(0.9),{BackgroundTransparency=1}):Play();Debris:AddItem(flash,1)

    local popup=Instance.new("TextLabel",GUI)
    popup.Size=UDim2.new(1,0,0,58);popup.Position=UDim2.new(0,0,0.42,0)
    popup.BackgroundTransparency=1;popup.TextColor3=Color3.fromRGB(230,190,255)
    popup.TextScaled=true;popup.Font=Enum.Font.GothamBold
    popup.Text="Entity Added: "..entity.Name.."  ("..#GS.PickedEntities.." total)";popup.ZIndex=21
    TweenService:Create(popup,TweenInfo.new(1.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0.5),{TextTransparency=1}):Play()
    Debris:AddItem(popup,2.5)

    pickBeaconChoices()
    updateBeaconBillboards()
end

activateStartPP=function()
    if not GS.PickedAtLeastOne or GS.Phase~="LOBBY" then return end
    startRound()
end

doReroll=function()
    if GS.RerollsLeft<=0 or GS.Phase~="LOBBY" then return end
    GS.RerollsLeft-=1; pickBeaconChoices(); updateBeaconBillboards()
    for _,obj in ipairs(LOBBY_FOLDER:GetChildren()) do
        if obj.Name=="RerollSign" then
            local sg=obj:FindFirstChildOfClass("SurfaceGui")
            if sg then local rc=sg:FindFirstChild("RerollCount"); if rc then rc.Text="Rolls left: "..GS.RerollsLeft end end
        end
    end
end

-- ============================================================
-- ROUND 6 GATE MESSAGE
-- ============================================================
local function showGateMessage()
    local lbl=Instance.new("TextLabel",GUI)
    lbl.Size=UDim2.new(0.85,0,0,62);lbl.Position=UDim2.new(0.075,0,0.4,0)
    lbl.BackgroundColor3=Color3.fromRGB(8,0,20);lbl.BackgroundTransparency=0.3
    lbl.TextColor3=Color3.fromRGB(255,100,255)
    lbl.TextScaled=true;lbl.Font=Enum.Font.GothamBold;lbl.TextWrapped=true
    lbl.Text="1st gate of the void opens, growing more humidity exponentially."
    lbl.ZIndex=18;lbl.TextTransparency=1
    corner(lbl,10)
    TweenService:Create(lbl,TweenInfo.new(1.2),{TextTransparency=0,BackgroundTransparency=0.28}):Play()
    task.delay(5,function()
        TweenService:Create(lbl,TweenInfo.new(2),{TextTransparency=1,BackgroundTransparency=1}):Play()
        Debris:AddItem(lbl,2.2)
    end)
end

-- ============================================================
-- LOBBY BUILDER
-- ============================================================
buildLobby=function()
    for _,o in ipairs(LOBBY_FOLDER:GetChildren()) do o:Destroy() end

    local base=Instance.new("Part",LOBBY_FOLDER)
    base.Name="LobbyBase";base.Size=Vector3.new(140,3,140)
    base.Position=Vector3.new(0,LOBBY_Y,0);base.Anchored=true
    base.Material=Enum.Material.SmoothPlastic;base.Color=Color3.fromRGB(18,12,38)

    for _,bd in ipairs({
        {Vector3.new(140,0.4,2),Vector3.new(0,LOBBY_Y+1.7,70)},
        {Vector3.new(140,0.4,2),Vector3.new(0,LOBBY_Y+1.7,-70)},
        {Vector3.new(2,0.4,140),Vector3.new(70,LOBBY_Y+1.7,0)},
        {Vector3.new(2,0.4,140),Vector3.new(-70,LOBBY_Y+1.7,0)},
    }) do
        local b=Instance.new("Part",LOBBY_FOLDER)
        b.Size=bd[1];b.Position=bd[2];b.Anchored=true;b.CanCollide=false
        b.Material=Enum.Material.Neon;b.Color=Color3.fromRGB(80,0,160)
    end

    local tsP=Instance.new("Part",LOBBY_FOLDER)
    tsP.Size=Vector3.new(52,12,1);tsP.Position=Vector3.new(0,LOBBY_Y+20,-62)
    tsP.Anchored=true;tsP.Material=Enum.Material.SmoothPlastic;tsP.Color=Color3.fromRGB(10,5,25)
    local tsG=Instance.new("SurfaceGui",tsP)
    tsG.Face=Enum.NormalId.Back;tsG.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;tsG.PixelsPerStud=42
    local tsL=Instance.new("TextLabel",tsG)
    tsL.Size=UDim2.new(1,0,0.62,0);tsL.BackgroundTransparency=1
    tsL.TextColor3=Color3.fromRGB(200,150,255);tsL.TextScaled=true;tsL.Font=Enum.Font.GothamBold;tsL.Text="DEVOID"
    local subL=Instance.new("TextLabel",tsG)
    subL.Size=UDim2.new(1,0,0.36,0);subL.Position=UDim2.new(0,0,0.64,0)
    subL.BackgroundTransparency=1;subL.TextColor3=Color3.fromRGB(160,130,200)
    subL.TextScaled=true;subL.Font=Enum.Font.Gotham;subL.Text="Choose your entities below"

    pickBeaconChoices()
    local bxs={-40,0,40}
    for i=1,BEACON_COUNT do
        local bx=bxs[i];local bz=22;local by=LOBBY_Y+1.5
        local bBase=Instance.new("Part",LOBBY_FOLDER)
        bBase.Name="BeaconBase_"..i;bBase.Size=Vector3.new(10,1,10)
        bBase.Position=Vector3.new(bx,by,bz);bBase.Anchored=true
        bBase.Material=Enum.Material.SmoothPlastic;bBase.Color=Color3.fromRGB(28,16,55)
        local pil=Instance.new("Part",LOBBY_FOLDER)
        pil.Size=Vector3.new(2,12,2);pil.Position=Vector3.new(bx,by+6,bz)
        pil.Anchored=true;pil.Material=Enum.Material.Neon;pil.Color=Color3.fromRGB(90,0,180)
        local orb=Instance.new("Part",LOBBY_FOLDER)
        orb.Name="BeaconOrb_"..i;orb.Shape=Enum.PartType.Ball;orb.Size=Vector3.new(3.5,3.5,3.5)
        orb.Position=Vector3.new(bx,by+14,bz);orb.Anchored=true;orb.CanCollide=false
        orb.Material=Enum.Material.Neon;orb.Color=Color3.fromRGB(170,70,255)
        local bb=Instance.new("BillboardGui",orb)
        bb.Size=UDim2.new(0,235,0,140);bb.StudsOffset=Vector3.new(0,4,0);bb.AlwaysOnTop=true;bb.LightInfluence=0
        local bg=Instance.new("Frame",bb);bg.Size=UDim2.new(1,0,1,0)
        bg.BackgroundColor3=Color3.fromRGB(10,5,25);bg.BackgroundTransparency=0.28;corner(bg,10)
        local nmL=Instance.new("TextLabel",bg)
        nmL.Name="EntityName";nmL.Size=UDim2.new(1,-8,0.42,0);nmL.Position=UDim2.new(0,4,0.03,0)
        nmL.BackgroundTransparency=1;nmL.TextColor3=Color3.fromRGB(220,180,255)
        nmL.TextScaled=true;nmL.Font=Enum.Font.GothamBold
        nmL.Text=GS.BeaconChoices[i] and GS.BeaconChoices[i].Name or "???"
        local tpL=Instance.new("TextLabel",bg)
        tpL.Name="EntityTip";tpL.Size=UDim2.new(1,-8,0.52,0);tpL.Position=UDim2.new(0,4,0.46,0)
        tpL.BackgroundTransparency=1;tpL.TextColor3=Color3.fromRGB(180,175,210)
        tpL.TextScaled=true;tpL.Font=Enum.Font.Gotham;tpL.TextWrapped=true
        tpL.Text=GS.BeaconChoices[i] and ("💡 "..GS.BeaconChoices[i].Tips) or ""
        local pp=Instance.new("ProximityPrompt",bBase)
        pp.ActionText="Pick Entity";pp.ObjectText=GS.BeaconChoices[i] and GS.BeaconChoices[i].Name or "???"
        pp.MaxActivationDistance=35;pp.RequiresLineOfSight=false;pp.KeyboardKeyCode=Enum.KeyCode.E
        local ci=i
        pp.Triggered:Connect(function(p) if p==player then selectEntity(ci) end end)
    end

    local rrBase=Instance.new("Part",LOBBY_FOLDER)
    rrBase.Name="RerollBase";rrBase.Size=Vector3.new(12,1,12)
    rrBase.Position=Vector3.new(0,LOBBY_Y+1.5,-28);rrBase.Anchored=true
    rrBase.Material=Enum.Material.SmoothPlastic;rrBase.Color=Color3.fromRGB(18,38,18)
    local rrSP=Instance.new("Part",LOBBY_FOLDER)
    rrSP.Name="RerollSign";rrSP.Size=Vector3.new(12,6,1)
    rrSP.Position=Vector3.new(0,LOBBY_Y+8,-32);rrSP.Anchored=true
    rrSP.Material=Enum.Material.SmoothPlastic;rrSP.Color=Color3.fromRGB(12,28,12)
    local rrG=Instance.new("SurfaceGui",rrSP)
    rrG.Face=Enum.NormalId.Front;rrG.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;rrG.PixelsPerStud=40
    local rrT=Instance.new("TextLabel",rrG)
    rrT.Size=UDim2.new(1,0,0.55,0);rrT.BackgroundTransparency=1
    rrT.TextColor3=Color3.fromRGB(100,255,100);rrT.TextScaled=true;rrT.Font=Enum.Font.GothamBold;rrT.Text="REROLL"
    local rrC=Instance.new("TextLabel",rrG)
    rrC.Name="RerollCount";rrC.Size=UDim2.new(1,0,0.42,0);rrC.Position=UDim2.new(0,0,0.56,0)
    rrC.BackgroundTransparency=1;rrC.TextColor3=Color3.fromRGB(170,255,170)
    rrC.TextScaled=true;rrC.Font=Enum.Font.Gotham;rrC.Text="Rolls left: "..GS.RerollsLeft
    local rrPP=Instance.new("ProximityPrompt",rrBase)
    rrPP.ActionText="Reroll Beacons";rrPP.ObjectText="Reroll Station"
    rrPP.MaxActivationDistance=35;rrPP.RequiresLineOfSight=false
    rrPP.Triggered:Connect(function(p) if p==player then doReroll() end end)

    local startBase=Instance.new("Part",LOBBY_FOLDER)
    startBase.Name="StartBase";startBase.Size=Vector3.new(14,1,14)
    startBase.Position=Vector3.new(0,LOBBY_Y+1.5,50);startBase.Anchored=true
    startBase.Material=Enum.Material.Neon
    startBase.Color=GS.PickedAtLeastOne and Color3.fromRGB(20,80,20) or Color3.fromRGB(12,12,12)
    local startSP=Instance.new("Part",LOBBY_FOLDER)
    startSP.Size=Vector3.new(14,6,1);startSP.Position=Vector3.new(0,LOBBY_Y+8,53)
    startSP.Anchored=true;startSP.Material=Enum.Material.SmoothPlastic;startSP.Color=Color3.fromRGB(8,22,8)
    local startG=Instance.new("SurfaceGui",startSP)
    startG.Face=Enum.NormalId.Front;startG.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;startG.PixelsPerStud=40
    local stL=Instance.new("TextLabel",startG)
    stL.Size=UDim2.new(1,0,0.6,0);stL.BackgroundTransparency=1
    stL.TextColor3=Color3.fromRGB(80,255,80);stL.TextScaled=true;stL.Font=Enum.Font.GothamBold;stL.Text="START ROUND"
    local stSub=Instance.new("TextLabel",startG)
    stSub.Size=UDim2.new(1,0,0.38,0);stSub.Position=UDim2.new(0,0,0.62,0)
    stSub.BackgroundTransparency=1;stSub.TextColor3=Color3.fromRGB(120,200,120)
    stSub.TextScaled=true;stSub.Font=Enum.Font.Gotham;stSub.Text="Pick at least 1 entity first"
    local startPP=Instance.new("ProximityPrompt",startBase)
    startPP.ActionText="Begin";startPP.ObjectText="Start Round"
    startPP.MaxActivationDistance=35;startPP.RequiresLineOfSight=false
    startPP.Enabled=GS.PickedAtLeastOne
    startPP.Triggered:Connect(function(p)
        if p==player then activateStartPP() end
    end)

    if GS.Round==6 then
        task.delay(1,showGateMessage)
    end

    task.wait(0.2)
    character:PivotTo(CFrame.new(0,LOBBY_Y+6,-42))
end

-- ============================================================
-- RETRY
-- ============================================================
btnRetry.MouseButton1Click:Connect(function()
    DEATH.Visible=false;GS.Phase="LOBBY";GS.Round=1;GS.RoundsBeaten=0
    GS.PickedEntities={};GS.PickedAtLeastOne=false;GS.RerollsLeft=MAX_REROLLS;GS.IsShatter=false
    HUD.Visible=false;lblCosmic.Visible=false;lblPhase.Visible=false
    lblRound.Text="PM 0:00";lblReality.Text="Reality Shards: 0 / 0"
    clearMap();buildLobby()
end)

-- ============================================================
-- /SKIP
-- ============================================================
local function skipRound()
    if GS.Phase=="DEAD" then return end
    for _,c in ipairs(GS.EntityConns) do c:Disconnect() end;GS.EntityConns={}
    clearMap()
    GS.Round+=1;GS.RoundsBeaten+=1;GS.IsShatter=false;GS.Phase="LOBBY"
    GS.PickedEntities={};GS.PickedAtLeastOne=false;GS.RerollsLeft=MAX_REROLLS
    HUD.Visible=false;lblCosmic.Visible=false;lblPhase.Visible=false
    lblRound.Text="PM "..(GS.Round-1)..":00";lblReality.Text="Reality Shards: 0 / 0"
    buildLobby()
    task.wait(0.1); character:PivotTo(CFrame.new(0,LOBBY_Y+6,-42))
    local hum=getHum(); if hum then hum.Health=hum.MaxHealth end
end

player.Chatted:Connect(function(msg)
    if msg:lower():sub(1,5)=="/skip" then skipRound() end
end)
pcall(function()
    local TCS=game:GetService("TextChatService")
    if TCS and TCS.TextChannels then
        local ch=TCS.TextChannels:FindFirstChild("RBXGeneral")
        if ch then
            ch.SaidMessageChanged:Connect(function(m)
                if m and m.Text and m.Text:lower():sub(1,5)=="/skip" then skipRound() end
            end)
        end
    end
end)

-- ============================================================
-- CHAR RESPAWN
-- ============================================================
player.CharacterAdded:Connect(function(newChar)
    character=newChar
    if GS.Phase=="PLAYING" or GS.Phase=="SHATTER" then
        task.wait(1); onDeath()
    end
end)

-- ============================================================
-- INIT
-- ============================================================
buildLobby()
startCollectionLoop()

print("╔════════════════════════════════════╗")
print("║  DEVOID v4.1 — loaded              ║")
print("║  Entities : "..#EntityRegistry.."                   ║")
print("║  Map Y   = "..MAP_Y.."               ║")
print("║  Lobby Y  = "..LOBBY_Y.."              ║")
print("║  /skip — skip to next round        ║")
print("╚════════════════════════════════════╝")
