--[[
    ██████╗ ███████╗██╗   ██╗ ██████╗ ██╗██████╗
    ██╔══██╗██╔════╝██║   ██║██╔═══██╗██║██╔══██╗
    ██║  ██║█████╗  ██║   ██║██║   ██║██║██║  ██║
    ██║  ██║██╔══╝  ╚██╗ ██╔╝██║   ██║██║██║  ██║
    ██████╔╝███████╗ ╚████╔╝ ╚██████╔╝██║██████╔╝
    ╚═════╝ ╚══════╝  ╚═══╝   ╚═════╝ ╚═╝╚═════╝
    DEVOID v5 — Codex Executor
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
    HelloworldCharge   = "76488643226841",
    HelloworldTeleport = "95957174060681",
    NukeExplosion      = "102353491611087",
    NukeCharging       = "138764534704077",
    PlayerDie          = "136836070379847",
    SeedInfect         = "125378217647252",
    CameraFlash        = "133385770201451",
    PurpleLight        = "133385770201451",
    DistortionSpawn    = "135273647100905",
    HookedDollAmbient  = "1296600882",
    HookedDollTeleport = "77995265370404",
    HookedDollInfect   = "125531588934587",
    MalwarePopup       = "130988530651697",
    OrbCharge          = "140049602451857",
    OrbExplode         = "127421570919272",
    MementoAirborne    = "139810065060748",
    MementoAmbience    = "140707174776546",
    FleshTrain         = "133008658452162",
    FleshCrash         = "138307089384990",
    StarlightCharge    = "138453151679878",
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
        Tips="Mimics your movement with a delay. Don't touch it.",
        AppearRound=6, AI="Distortion",
        Delay=2, ShatterDelay=1,
        BaseCount=1, ShatterExtraCount=1,
    },
    {
        Name="Malware",
        Tips="Close the pop-ups before they block your entire screen.",
        AppearRound=6, AI="Malware",
        MinInterval=30, MaxInterval=50,
        ShatterMinInterval=25, ShatterMaxInterval=30,
        PopupCount=5, ShatterPopupCount=8,
    },
    {
        Name="Hooked Doll",
        Tips="Avoid black platforms and don't collect leaking shards unless you can handle the fling.",
        AppearRound=13, AI="HookedDoll",
        Speed=10,
        InfectDuration=5,
        ShardLeakDuration=5,
        ShardDamage=30,
    },
    {
        Name="Greed",
        Tips="Collect exactly what it demands before time runs out, or you die.",
        AppearRound=13, AI="Greed",
        MinInterval=34, MaxInterval=45,
        Demand=0,  -- set dynamically
        WarnTime=3, TimerDuration=10,
        ShatterMinDemand=10, ShatterMaxDemand=20, ShatterTimerDuration=7,
    },
    {
        Name="Crescendo",
        Tips="Three beams lock onto you — dodge before the swords fly through.",
        AppearRound=13, AI="Crescendo",
        MinInterval=25, MaxInterval=30,
        BeamCount=3, ShatterBeamCount=5,
        ShatterMinInterval=10, ShatterMaxInterval=15,
        WarnTime=3,
    },
    {
        Name="Starlight",
        Tips="When it stops and aims, move — you have 2 seconds before the beam fires.",
        AppearRound=25, AI="Starlight",
        Speed=20, ShatterSpeed=25,
        AimDelay=2, ShatterAimDelay=1,
        BeamLength=5000, Damage=100,
    },
}

-- ============================================================
-- FATAL ENTITY REGISTRY
-- ============================================================
local FatalEntityRegistry = {
    {
        Name="Guardian",
        Tips="When 'Death on Sight' appears, run — orbs explode into lethal vertical beams.",
        AppearRound=25, AI="Guardian",
        MinInterval=50, MaxInterval=90,
        OrbCount=3, ShatterOrbCount=5,
        OrbSpeed=20, BeamDamage=100,
    },
    {
        Name="Memento Mori",
        Tips="Don't leave the ground when the fog turns red. Artificial platform will be stripped.",
        AppearRound=25, AI="MementoMori",
        MinInterval=45, MaxInterval=85,
        Duration=10, ShatterDuration=13,
        AirTime=1, ShatterAirTime=1,
        BaseTextCount=5, ExtraTextPerRound=7,
    },
    {
        Name="Flesh",
        Tips="When the beam appears, get out of the way — the train will follow but can't turn fast.",
        AppearRound=25, AI="Flesh",
        -- Normal: beam every 3s, train appears after 2s
        BeamInterval=3, WarnTime=2,
        TrainSpeed=180, TurnSpeed=0.4,
        CartCount=5, TrainLength=28,
        -- Shatter: beam every 1s, train appears after 1s, unholy speed, better turn
        ShatterBeamInterval=1, ShatterWarnTime=1,
        ShatterTrainSpeed=420, ShatterTurnSpeed=1.8,
    },
}
local MAX_FATAL_PICKS = 3

-- ============================================================
-- GAME STATE
-- ============================================================
local GS = {
    Phase="LOBBY", Round=1, RoundsBeaten=0, IsShatter=false,
    RerollsLeft=MAX_REROLLS, TotalShards=0, CollectedReality=0, CollectedCosmic=0,
    RealityShards={}, CosmicShards={}, MapPlatforms={},
    Entities={}, EntityConns={}, PickedEntities={}, BeaconChoices={},
    PickedAtLeastOne=false,
    ShatterStartTick=0,   -- for grace period before beacon can complete round
    RandomMode=false,     -- random mode flag
    RandomModeMultiplier=false, -- 3x shard gain
    RandomModeEntityTimer=0,
    -- entity pick-count cap (max 3 times per entity per lobby)
    PickCounts={},
    -- entities that persist across all future rounds (accumulated)
    PersistentEntities={},
    -- persistent cosmic shard bank (carries across rounds)
    CosmicBank=0,
    -- active upgrades  {MoreIncome=bool, Speedy=bool, Infusion=bool, ArtificialPlatform=bool}
    Upgrades={},
    -- upgrade beacon state
    ShowingUpgrades=false,
    UpgradeChoices={},
    -- fatal entity state (initialized here so never nil)
    FatalPickedEntities={},
    FatalPickCounts={},
    FatalBeaconsDone=false,
    ShowingFatalBeacons=false,
    FatalBeaconChoices={},
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
-- upgrade labels — defined later in upgrade system, forward-declared so earlier functions can reference them
local lblLobbyBank, lblCosmicBank
-- fatal entity spawner — defined later but called from startRound
local spawnFatalEntities

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
    for _,c in ipairs(GS.EntityConns)   do if c then pcall(function() c:Disconnect() end) end end
    GS.MapPlatforms={};GS.RealityShards={};GS.CosmicShards={}
    GS.Entities={};GS.EntityConns={}
    for _,o in ipairs(MAP_FOLDER:GetChildren())    do o:Destroy() end
    for _,o in ipairs(SHARD_FOLDER:GetChildren())  do o:Destroy() end
    for _,o in ipairs(ENTITY_FOLDER:GetChildren()) do o:Destroy() end
end

local function generateMap(round)
    clearMap()
    -- Shard count for this round
    local shardRange = SHARD_RANGES[math.min(round,#SHARD_RANGES)]
    local maxShards  = shardRange[2]
    -- Platform count = at least shardCount + 25 buffer (so every shard has a platform)
    local maxPlats   = math.max(85+round*45, maxShards + 25)
    -- Radius must be large enough to physically fit maxPlats platforms
    -- avg platform ~15 studs wide, ~5 stud gap → ~20 studs per platform in a grid
    -- area needed ≈ maxPlats * 400 studs²  → radius ≈ sqrt(maxPlats*400/pi)
    local baseRadius = getMapRadius(round)
    local neededRadius = math.ceil(math.sqrt(maxPlats * 500 / math.pi))
    local radius = math.max(baseRadius, neededRadius)
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

    while #GS.MapPlatforms<maxPlats and iter<60000 do
        iter+=1
        if #frontier==0 then break end
        local base=frontier[math.random(1,math.min(#frontier,60))]
        local dir=DIRS[math.random(1,4)]
        local def=PLAT_DEFS[math.random(1,#PLAT_DEFS)]
        local nhw=def[1]/2; local nhd=def[2]/2
        -- 65% touching/nearly-touching, 35% jump gap
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
        if #frontier>120 then table.remove(frontier,1) end
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
        local isRealimic = GS.Upgrades.Infusion and math.random()<0.30
        local s=Instance.new("Part",SHARD_FOLDER)
        s.Name= isRealimic and "RealimicShard" or "RealityShard"
        s.Shape=Enum.PartType.Ball;s.Size=Vector3.new(1.8,1.8,1.8)
        s.Position=plat.Position+Vector3.new(0,3.5,0);s.Anchored=true;s.CanCollide=false
        s.Material=Enum.Material.Neon
        s.Color= isRealimic and Color3.fromRGB(200,130,255) or Color3.fromRGB(130,90,255)
        addParticles(s, isRealimic and Color3.fromRGB(255,200,80) or Color3.fromRGB(160,110,255));spinPart(s)
        local bb=Instance.new("BillboardGui",s);bb.Size=UDim2.new(0,44,0,26);bb.StudsOffset=Vector3.new(0,2,0)
        local l=Instance.new("TextLabel",bb);l.Size=UDim2.new(1,0,1,0);l.BackgroundTransparency=1
        l.TextColor3= isRealimic and Color3.fromRGB(255,210,100) or Color3.fromRGB(200,160,255)
        l.TextScaled=true;l.Font=Enum.Font.GothamBold;l.Text= isRealimic and "◈" or "◆"
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
            for _,part in ipairs(model:GetChildren()) do
                if part:IsA("Part") and part~=body and part~=pot then
                    -- eyes follow body
                end
            end
        end
        if dist<5 then
            local hum=getHum()
            if hum and hum.Health>0 then hum.Health=math.max(0,hum.Health-def.Damage*dt*4) end
        end
    end)
    table.insert(GS.EntityConns,conn)
    print("[Devoid] Follower spawned on",sp.Name,"at",tostring(sp.Position))
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
                -- Charging sound that speeds up over 5s
                task.spawn(function()
                    local snd=Instance.new("Sound",workspace)
                    snd.SoundId="rbxassetid://"..SFX.NukeCharging
                    snd.Volume=1.4; snd.PlaybackSpeed=0.5; snd.Looped=true; snd:Play()
                    local elapsed=0
                    local sc; sc=RunService.Heartbeat:Connect(function(dt)
                        elapsed+=dt
                        snd.PlaybackSpeed=0.5+elapsed*0.28  -- ramps from 0.5 to ~1.9 over 5s
                        snd.Pitch=0.6+elapsed*0.26
                        if elapsed>=5 then sc:Disconnect(); snd:Stop(); snd:Destroy() end
                    end)
                end)
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
                local spinConn  -- pre-declared so callback can safely reference it
                spinConn=RunService.Heartbeat:Connect(function(sDt)
                    if not ring1.Parent then
                        if spinConn then pcall(function() spinConn:Disconnect() end) end
                        whActive=false; return
                    end
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
                        if spinConn then pcall(function() spinConn:Disconnect() end) end
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

    local tpTimer=0;local dmgCd=0;local chargePlayed=false

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
        local chargeStart=tpInterval-1.2

        -- Play charge sound once, only in the 1.2s window before teleport
        if tpTimer>=chargeStart and not chargePlayed then
            chargePlayed=true
            playSound(SFX.HelloworldCharge, 1.2)
        end

        if tpTimer>=tpInterval then
            tpTimer=0;chargePlayed=false
            -- Teleport sound plays at the moment of teleport
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
    print("[Devoid] helloworld spawned on",sp.Name)
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

        local zoneRadius=(GS.IsShatter and def.ShatterAreaRadius or def.AreaRadius)
                        - (GS.Upgrades.SensoryDeprivation and 20 or 0)
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
    print("[Devoid] Keeper spawned")
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

                    -- White flash overlay
                    local flash=Instance.new("Frame",GUI)
                    flash.Size=UDim2.new(1,0,1,0);flash.BackgroundColor3=Color3.fromRGB(255,255,255)
                    flash.BackgroundTransparency=0;flash.ZIndex=20
                    playSound(SFX.CameraFlash, 1.5)
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
    print("[Devoid] Camera entity spawned")
end

-- DISTORTION
local function spawnDistortion(def,platforms)
    if #platforms==0 then return end
    local delay = GS.IsShatter and def.ShatterDelay or def.Delay
    local count = def.BaseCount + (GS.IsShatter and def.ShatterExtraCount or 0)

    local histBuffers={}
    for i=1,count do histBuffers[i]={} end
    local models={}

    for i=1,count do
        local model=Instance.new("Model",ENTITY_FOLDER); model.Name="Distortion_"..i
        local body=Instance.new("Part",model)
        body.Name="Root"; body.Shape=Enum.PartType.Ball; body.Size=Vector3.new(3.5,3.5,3.5)
        local sp=anyMapPlat() or platforms[math.random(1,#platforms)]
        body.Position=sp.Position+Vector3.new(0,6,0)
        body.Anchored=true; body.CanCollide=false; body.Material=Enum.Material.Neon
        body.Color=Color3.fromHSV((0.75+(i-1)*0.04)%1, 0.85, 1); body.Transparency=0.2
        local att=Instance.new("Attachment",body)
        local pe=Instance.new("ParticleEmitter",att)
        pe.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(180,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(80,0,140))})
                    local closest=beamStart+aimDir*proj
                    local distXZ = Vector3.new(hrpPos.X - closest.X, 0, hrpPos.Z - closest.Z).Magnitude
                    if distXZ < 7 then
        pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(1,0)})
        local bb=Instance.new("BillboardGui",body)
        bb.Size=UDim2.new(0,110,0,28); bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true
        local bl=Instance.new("TextLabel",bb); bl.Size=UDim2.new(1,0,1,0)
        bl.BackgroundTransparency=1; bl.TextColor3=Color3.fromRGB(200,80,255)
        bl.TextScaled=true; bl.Font=Enum.Font.GothamBold; bl.Text="Distortion"
        model.PrimaryPart=body; table.insert(GS.Entities,model); table.insert(models,{model=model,body=body})
    end

    -- Staggered purple light → spawn sequence
    task.spawn(function()
        task.wait(5)
        for i=1,count do
            if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then break end
            local srcPos
            if i==1 then
                local hrp=getHRP(); if not hrp then break end; srcPos=hrp.Position
            else
                local pb=models[i-1].body; if not pb or not pb.Parent then break end; srcPos=pb.Position
            end
            playSound(SFX.PurpleLight, 1.2, srcPos)
            local pLight=Instance.new("Part",workspace)
            pLight.Shape=Enum.PartType.Ball; pLight.Size=Vector3.new(4,4,4)
            pLight.Position=srcPos; pLight.Anchored=true; pLight.CanCollide=false
            pLight.Material=Enum.Material.Neon; pLight.Color=Color3.fromRGB(160,0,255); pLight.Transparency=0.2
            TweenService:Create(pLight,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(14,14,14),Transparency=0.6}):Play()
            task.wait(2)
            if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then pLight:Destroy(); break end
            models[i].body.Position=srcPos+Vector3.new(0,1,0)
            playSound(SFX.DistortionSpawn, 1.3, srcPos)
            TweenService:Create(pLight,TweenInfo.new(0.4),{Transparency=1}):Play(); Debris:AddItem(pLight,0.5)
        end
    end)

    local conn=RunService.Heartbeat:Connect(function(dt)
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        local now=tick()
        local hrp=getHRP()
        if hrp then
            table.insert(histBuffers[1],{t=now,pos=hrp.Position})
            while #histBuffers[1]>0 and now-histBuffers[1][1].t>delay+0.5 do table.remove(histBuffers[1],1) end
        end
        for i=1,count do
            local mb=models[i]; if not mb.body.Parent then continue end
            local buf=histBuffers[i]; local targetPos=nil
            for bi=1,#buf do if now-buf[bi].t>=delay then targetPos=buf[bi].pos end end
            if targetPos then
                mb.body.Position=targetPos
                if i<count then
                    table.insert(histBuffers[i+1],{t=now,pos=mb.body.Position})
                    while #histBuffers[i+1]>0 and now-histBuffers[i+1][1].t>delay+0.5 do table.remove(histBuffers[i+1],1) end
                end
            end
            if hrp and (hrp.Position-mb.body.Position).Magnitude<4 then
                local hum=getHum(); if hum and hum.Health>0 then hum.Health=0 end
            end
        end
    end)
    table.insert(GS.EntityConns,conn)
    print("[Devoid] Distortion spawned count="..count.." delay="..delay.."s")
end

-- MALWARE
local function spawnMalware(def, platforms)
    local timer = 0
    local nextInterval = math.random(def.MinInterval, def.MaxInterval)
    local activePopups = {}

    -- Popup titles and body text for flavour
    local adTexts = {
        {"YOU WON A FREE IPHONE!!!", "Click OK to claim your prize!\nLimited time offer!"},
        {"⚠ VIRUS DETECTED ⚠", "Your device has 47 viruses.\nDownload our free cleaner NOW!"},
        {"HOT SINGLES IN YOUR AREA", "They are waiting for you.\nDon't keep them waiting..."},
        {"CONGRATULATIONS!", "You are the 1,000,000th visitor!\nClaim your reward immediately!"},
        {"SYSTEM WARNING", "Your RAM is critically low.\nCall 1-800-FIX-PC now."},
        {"SPECIAL OFFER!!!", "Buy 1 get 99 FREE!\nToday only. Act fast!!!"},
        {"UPDATE REQUIRED", "Please update your Adobe Flash\nPlayer to continue browsing."},
        {"YOUR ACCOUNT IS SUSPENDED", "Verify your identity immediately\nor lose access forever."},
        {"DOWNLOAD SPEED BOOST", "Increase your speed by 3000%!\nClick here to install."},
        {"SECURITY ALERT", "Unauthorised access detected.\nChange your password NOW!"},
    }

    local function makePopup(index)
        local adData = adTexts[math.random(1, #adTexts)]

        -- Random screen position (keep inside screen roughly)
        local rx = math.random(2, 68) / 100
        local ry = math.random(10, 65) / 100

        local popup = mkFrame(GUI, {
            Size = UDim2.new(0, 320, 0, 200),
            Position = UDim2.new(rx, 0, ry, 0),
            BackgroundColor3 = Color3.fromRGB(195, 195, 195),
            BorderSizePixel = 2,
            ZIndex = 30,
            Active = true,
            Draggable = true,
        })
        corner(popup, 0)

        -- Title bar
        local titleBar = mkFrame(popup, {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Color3.fromRGB(0, 0, 128),
            ZIndex = 31,
        })
        local titleLbl = mkLabel(titleBar, {
            Size = UDim2.new(1, -32, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            Font = Enum.Font.GothamBold,
            Text = adData[1],
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 32,
        })

        -- Close button (X)
        local closeBtn = mkBtn(titleBar, {
            Size = UDim2.new(0, 26, 0, 24),
            Position = UDim2.new(1, -28, 0, 2),
            BackgroundColor3 = Color3.fromRGB(220, 50, 50),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextScaled = true,
            Font = Enum.Font.GothamBold,
            Text = "✕",
            ZIndex = 33,
        })
        corner(closeBtn, 2)

        -- Body text
        local bodyLbl = mkLabel(popup, {
            Size = UDim2.new(1, -8, 0, 90),
            Position = UDim2.new(0, 4, 0, 34),
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(0, 0, 0),
            TextScaled = true,
            Font = Enum.Font.Gotham,
            Text = adData[2],
            TextWrapped = true,
            ZIndex = 31,
        })

        -- OK button at bottom
        local okBtn = mkBtn(popup, {
            Size = UDim2.new(0, 80, 0, 28),
            Position = UDim2.new(0.5, -40, 1, -36),
            BackgroundColor3 = Color3.fromRGB(195, 195, 195),
            TextColor3 = Color3.fromRGB(0, 0, 0),
            TextScaled = true,
            Font = Enum.Font.Gotham,
            Text = "OK",
            ZIndex = 32,
            BorderSizePixel = 2,
        })

        -- A "scan bar" that runs across the popup for extra annoyance
        local scanBar = mkFrame(popup, {
            Size = UDim2.new(0, 6, 0.6, 0),
            Position = UDim2.new(0, 0, 0.22, 0),
            BackgroundColor3 = Color3.fromRGB(0, 255, 0),
            BackgroundTransparency = 0.5,
            ZIndex = 34,
        })
        -- Animate scan bar
        task.spawn(function()
            while popup.Parent do
                TweenService:Create(scanBar, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(1, -6, 0.22, 0)
                }):Play()
                task.wait(1.2)
                if not popup.Parent then break end
                scanBar.Position = UDim2.new(0, 0, 0.22, 0)
            end
        end)

        -- Close on X or OK
        local function closePopup()
            if popup and popup.Parent then
                TweenService:Create(popup, TweenInfo.new(0.15), {Size=UDim2.new(0,0,0,0)}):Play()
                Debris:AddItem(popup, 0.2)
                -- Remove from active list
                for i, p in ipairs(activePopups) do
                    if p == popup then table.remove(activePopups, i); break end
                end
            end
        end
        closeBtn.MouseButton1Click:Connect(closePopup)
        okBtn.MouseButton1Click:Connect(closePopup)

        table.insert(activePopups, popup)
        playSound(SFX.MalwarePopup, 0.8)
    end

    local conn = RunService.Heartbeat:Connect(function(dt)
        if GS.Phase == "DEAD" or GS.Phase == "LOBBY" then return end
        timer += dt
        if timer >= nextInterval then
            timer = 0
            local minI = GS.IsShatter and def.ShatterMinInterval or def.MinInterval
            local maxI = GS.IsShatter and def.ShatterMaxInterval or def.MaxInterval
            nextInterval = math.random(minI, maxI)

            local count = GS.IsShatter and def.ShatterPopupCount or def.PopupCount
            for i = 1, count do
                task.wait(0.08 * (i-1))  -- stagger slightly so they don't all stack
                if GS.Phase ~= "DEAD" and GS.Phase ~= "LOBBY" then
                    makePopup(i)
                end
            end
        end
    end)
    table.insert(GS.EntityConns, conn)

    -- Cleanup all popups on phase change
    local cleanConn = RunService.Heartbeat:Connect(function()
        if GS.Phase == "DEAD" or GS.Phase == "LOBBY" then
            for _, p in ipairs(activePopups) do if p and p.Parent then p:Destroy() end end
            activePopups = {}
            cleanConn:Disconnect()
        end
    end)
    table.insert(GS.EntityConns, cleanConn)
    print("[Devoid] Malware spawned")
end

-- HOOKED DOLL
local function spawnHookedDoll(def, platforms)
    if #platforms==0 then return end
    local sp = anyMapPlat() or platforms[math.random(1,#platforms)]

    local model = Instance.new("Model", ENTITY_FOLDER); model.Name="HookedDoll"

    -- Body: pale doll shape
    local body = Instance.new("Part", model)
    body.Name="HumanoidRootPart"; body.Size=Vector3.new(3,4,2)
    body.Position=sp.Position+Vector3.new(0,200,0)  -- starts in sky
    body.Anchored=true; body.CanCollide=false
    body.Material=Enum.Material.SmoothPlastic; body.Color=Color3.fromRGB(230,200,180)

    -- Head
    local head=Instance.new("Part",model)
    head.Shape=Enum.PartType.Ball; head.Size=Vector3.new(2.2,2.2,2.2)
    head.Anchored=true; head.CanCollide=false
    head.Material=Enum.Material.SmoothPlastic; head.Color=Color3.fromRGB(230,200,180)
    head.Position=body.Position+Vector3.new(0,3,0)

    -- String visuals (thin vertical parts)
    local strings={}
    for i=1,3 do
        local str=Instance.new("Part",model)
        str.Size=Vector3.new(0.1,6,0.1); str.Anchored=true; str.CanCollide=false
        str.Material=Enum.Material.SmoothPlastic; str.Color=Color3.fromRGB(200,200,200)
        str.Position=body.Position+Vector3.new((i-2)*0.8,5,0)
        table.insert(strings,str)
    end

    -- Eyes (black X)
    for _,sx in ipairs({-0.5,0.5}) do
        local eye=Instance.new("Part",model)
        eye.Shape=Enum.PartType.Ball; eye.Size=Vector3.new(0.4,0.4,0.4)
        eye.Material=Enum.Material.Neon; eye.Color=Color3.fromRGB(0,0,0)
        eye.Anchored=true; eye.CanCollide=false
        eye.Position=head.Position+Vector3.new(sx,0,-1.05)
    end

    -- Ambient glow
    local att=Instance.new("Attachment",body)
    local pe=Instance.new("ParticleEmitter",att)
    pe.Color=ColorSequence.new(Color3.fromRGB(180,180,255)); pe.LightEmission=0.5; pe.Rate=10
    pe.Speed=NumberRange.new(0.5,2); pe.Lifetime=NumberRange.new(0.5,1.5)
    pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.3),NumberSequenceKeypoint.new(1,0)})

    local bb=Instance.new("BillboardGui",body)
    bb.Size=UDim2.new(0,115,0,28); bb.StudsOffset=Vector3.new(0,6,0); bb.AlwaysOnTop=true
    local bl=Instance.new("TextLabel",bb); bl.Size=UDim2.new(1,0,1,0)
    bl.BackgroundTransparency=1; bl.TextColor3=Color3.fromRGB(200,180,255)
    bl.TextScaled=true; bl.Font=Enum.Font.GothamBold; bl.Text="Hooked Doll"

    model.PrimaryPart=body; table.insert(GS.Entities,model)

    local infectedPlats={}  -- {part, timer, origColor, origMat}
    local leakingShards={}  -- {shard, timer}
    local hasDropped=false
    local dropTimer=0
    local speedDebuff={}    -- tracks if player is on infected plat

    -- Drop animation: fall from sky to nearest platform
    local function dropToPlatform()
        local target=anyMapPlat() or platforms[math.random(1,#platforms)]
        local destY=target.Position.Y+6
        playSound(SFX.HookedDollAmbient, 1.2, body.Position)
        -- Drop tween
        TweenService:Create(body,TweenInfo.new(1.8,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
            Position=Vector3.new(target.Position.X,destY,target.Position.Z)
        }):Play()
        for _,str in ipairs(strings) do
            TweenService:Create(str,TweenInfo.new(1.8,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
                Position=Vector3.new(target.Position.X+(str.Position-body.Position).X,destY+5,target.Position.Z)
            }):Play()
        end
        head.Position=body.Position+Vector3.new(0,3,0)
        task.wait(1.9)
        if body.Parent then
            body.Position=Vector3.new(target.Position.X,destY,target.Position.Z)
            head.Position=body.Position+Vector3.new(0,3,0)
        end
        hasDropped=true
    end

    task.spawn(dropToPlatform)

    local function infectPlatform(p)
        if p:GetAttribute("HookInfected") then return end
        p:SetAttribute("HookInfected",true)
        p:SetAttribute("HookOrigColor",tostring(p.Color.R)..","..tostring(p.Color.G)..","..tostring(p.Color.B))
        p:SetAttribute("HookOrigMat",p.Material.Name)
        p.Color=Color3.fromRGB(15,15,15); p.Material=Enum.Material.SmoothPlastic
        playSound(SFX.HookedDollInfect, 0.9, p.Position)
        table.insert(infectedPlats,{part=p, timer=def.InfectDuration})
    end

    local function leakShard(s)
        if s:GetAttribute("LeakActive") then return end
        s:SetAttribute("LeakActive",true)
        local wasName=s.Name
        s.Color=Color3.fromRGB(255,255,255); s.Material=Enum.Material.Neon
        -- White pulsing
        local pulse=true
        task.spawn(function()
            while s.Parent and s:GetAttribute("LeakActive") do
                TweenService:Create(s,TweenInfo.new(0.3),{Transparency=0.6}):Play(); task.wait(0.3)
                TweenService:Create(s,TweenInfo.new(0.3),{Transparency=0}):Play(); task.wait(0.3)
            end
        end)
        table.insert(leakingShards,{shard=s, timer=def.ShardLeakDuration, wasName=wasName})
    end

    local playerSpeedReduced=false
    local conn=RunService.Heartbeat:Connect(function(dt)
        if not model.Parent then return end
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        if not hasDropped then return end

        local hrp=getHRP(); if not hrp then return end
        local hum=getHum(); if not hum then return end

        -- Chase player
        local diff=hrp.Position-body.Position; local dist=diff.Magnitude
        if dist>1 then
            local move=diff.Unit*def.Speed*dt
            body.Position=body.Position+move
            head.Position=body.Position+Vector3.new(0,3,0)
            for _,str in ipairs(strings) do
                str.Position=body.Position+Vector3.new((str.Position-body.Position).X,5,0)
            end
        end

        -- Kill on direct contact with body
        if (hrp.Position-body.Position).Magnitude < 4.5 then
            local hum2=getHum()
            if hum2 and hum2.Health>0 then hum2.Health=0 end
        end

        -- Infect nearby platforms
        for _,p in ipairs(GS.MapPlatforms) do
            if p and p.Parent and not p:GetAttribute("HookInfected") then
                if (p.Position-body.Position).Magnitude < p.Size.X/2+4 then
                    infectPlatform(p)
                end
            end
        end

        -- Leak nearby shards
        local allShards={}
        for _,s in ipairs(GS.RealityShards) do table.insert(allShards,s) end
        for _,s in ipairs(GS.CosmicShards)  do table.insert(allShards,s) end
        for _,s in ipairs(allShards) do
            if s and s.Parent and not s:GetAttribute("LeakActive") then
                if (s.Position-body.Position).Magnitude < 12 then leakShard(s) end
            end
        end

        -- Check if player stands on infected platform
        local onInfected=false
        local hrpPos=hrp.Position
        for _,entry in ipairs(infectedPlats) do
            local p=entry.part
            if p and p.Parent then
                local dx=math.abs(hrpPos.X-p.Position.X); local dz=math.abs(hrpPos.Z-p.Position.Z)
                local dy=hrpPos.Y-p.Position.Y
                if dx<p.Size.X/2+1 and dz<p.Size.Z/2+1 and dy>0 and dy<4 then
                    onInfected=true; break
                end
            end
        end
        if onInfected then
            hum.Health=math.max(0,hum.Health-1/0.1*dt)  -- 1 dmg per 0.1s
            if not playerSpeedReduced then
                playerSpeedReduced=true
                local base=hum.WalkSpeed
                hum.WalkSpeed=math.max(2,base*0.5)
            end
        else
            if playerSpeedReduced then
                playerSpeedReduced=false
                local stacks=GS.Upgrades._SpeedyStacks or 0
                hum.WalkSpeed=16+stacks*5
            end
        end

        -- Tick down infected platform timers
        for i=#infectedPlats,1,-1 do
            local e=infectedPlats[i]; e.timer-=dt
            if e.timer<=0 then
                if e.part and e.part.Parent then
                    e.part:SetAttribute("HookInfected",false)
                    e.part.Material=Enum.Material.SmoothPlastic
                    local oc=e.part:GetAttribute("OrigColor"); if oc then e.part.Color=oc end
                end
                table.remove(infectedPlats,i)
            end
        end

        -- Tick down leaking shard timers & handle collection
        for i=#leakingShards,1,-1 do
            local e=leakingShards[i]; e.timer-=dt
            -- Check if player collected leaking shard
            if e.shard and e.shard.Parent and (hrpPos-e.shard.Position).Magnitude<5.5 then
                -- Give value
                if e.wasName=="CosmicShard" or e.wasName=="RealimicShard" then
                    local gain=GS.Upgrades.MoreIncome and 2 or 1
                    GS.CosmicBank=GS.CosmicBank+gain; if updateBankLabels then updateBankLabels() end
                end
                if e.wasName=="RealityShard" or e.wasName=="RealimicShard" then
                    GS.CollectedReality+=1
                    lblReality.Text="Reality Shards: "..GS.CollectedReality.." / "..GS.TotalShards
                    if GS.CollectedReality>=GS.TotalShards then
                        lblReality.Text="Reality Shards: ALL COLLECTED ✓"
                        startShatter(GS.MapPlatforms)
                    end
                end
                -- Remove from original shard lists
                for li,s in ipairs(GS.RealityShards) do if s==e.shard then table.remove(GS.RealityShards,li); break end end
                for li,s in ipairs(GS.CosmicShards)  do if s==e.shard then table.remove(GS.CosmicShards, li); break end end
                e.shard:Destroy()
                table.remove(leakingShards,i)
                -- Damage + fling
                hum.Health=math.max(0,hum.Health-def.ShardDamage)
                local dirs={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1),Vector3.new(0.7,0,0.7),Vector3.new(-0.7,0,-0.7)}
                local fdir=dirs[math.random(1,#dirs)]
                local bv=Instance.new("BodyVelocity",hrp)
                bv.Velocity=fdir.Unit*90+Vector3.new(0,55,0); bv.MaxForce=Vector3.new(1e5,1e5,1e5)
                Debris:AddItem(bv,0.22)
            elseif e.timer<=0 then
                -- Revert shard appearance
                if e.shard and e.shard.Parent then
                    e.shard:SetAttribute("LeakActive",false)
                    if e.wasName=="RealityShard" or e.wasName=="RealimicShard" then
                        e.shard.Color=Color3.fromRGB(130,90,255)
                    else
                        e.shard.Color=Color3.fromRGB(255,205,40)
                    end
                end
                table.remove(leakingShards,i)
            end
        end

        -- Teleport every 30s
        dropTimer+=dt
        if dropTimer>=30 then
            dropTimer=0; hasDropped=false
            local tp=anyMapPlat() or platforms[math.random(1,#platforms)]
            body.Position=tp.Position+Vector3.new(0,200,0)
            playSound(SFX.HookedDollTeleport,1.2,body.Position)
            task.spawn(dropToPlatform)
        end
    end)
    table.insert(GS.EntityConns,conn)
    print("[Devoid] Hooked Doll spawned")
end

-- GREED
local function spawnGreed(def, platforms)
    local timer = 0
    local nextInterval = math.random(def.MinInterval, def.MaxInterval)
    local greedActive = false

    local conn = RunService.Heartbeat:Connect(function(dt)
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        timer += dt
        if timer < nextInterval or greedActive then return end
        timer = 0
        nextInterval = math.random(def.MinInterval, def.MaxInterval)
        greedActive = true

        task.spawn(function()
            -- Pick shard demand
            local demand
            if GS.IsShatter then
                demand = math.random(def.ShatterMinDemand, def.ShatterMaxDemand)
            else
                demand = math.random(5, 15)
            end
            local collected = 0
            local timerDur = GS.IsShatter and def.ShatterTimerDuration or def.TimerDuration

            -- Build smiley face GUI
            local face = mkFrame(GUI, {
                Size = UDim2.new(0,180,0,220),
                Position = UDim2.new(0.5,-90,0.08,0),
                BackgroundColor3 = Color3.fromRGB(60,200,60),
                BackgroundTransparency = 0.05,
                ZIndex = 35,
            }); corner(face, 90)

            -- Eyes showing $ for first 3s
            local eye1 = mkLabel(face, {
                Size=UDim2.new(0,50,0,50), Position=UDim2.new(0.12,0,0.12,0),
                BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0,
                TextColor3=Color3.fromRGB(255,215,0), TextScaled=true,
                Font=Enum.Font.GothamBold, Text="$", ZIndex=36,
            }); corner(eye1,25)
            local eye2 = mkLabel(face, {
                Size=UDim2.new(0,50,0,50), Position=UDim2.new(0.6,0,0.12,0),
                BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0,
                TextColor3=Color3.fromRGB(255,215,0), TextScaled=true,
                Font=Enum.Font.GothamBold, Text="$", ZIndex=36,
            }); corner(eye2,25)

            -- Smile
            local smile = mkLabel(face, {
                Size=UDim2.new(0.75,0,0,36), Position=UDim2.new(0.125,0,0.58,0),
                BackgroundTransparency=1, TextColor3=Color3.fromRGB(0,0,0),
                TextScaled=true, Font=Enum.Font.GothamBold, Text="^___^", ZIndex=36,
            })

            -- Top label
            local topLbl = mkLabel(face, {
                Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,-0.18,0),
                BackgroundTransparency=1, TextColor3=Color3.fromRGB(255,230,0),
                TextScaled=true, Font=Enum.Font.GothamBold, Text="REMEMBER!!!", ZIndex=36,
            })

            -- Progress label
            local progLbl = mkLabel(face, {
                Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,0.82,0),
                BackgroundTransparency=1, TextColor3=Color3.fromRGB(255,255,255),
                TextScaled=true, Font=Enum.Font.Gotham, Text="0/"..demand, ZIndex=36,
            })

            -- Timer bar background
            local timerBg = mkFrame(face, {
                Size=UDim2.new(1,0,0,10), Position=UDim2.new(0,0,0.94,0),
                BackgroundColor3=Color3.fromRGB(40,40,40), ZIndex=36,
            })
            local timerBar = mkFrame(timerBg, {
                Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(80,255,80), ZIndex=37,
            })

            task.wait(def.WarnTime)
            if GS.Phase=="DEAD" then face:Destroy(); greedActive=false; return end

            -- Reveal number eyes: tens digit / ones digit
            local tens = math.floor(demand/10)
            local ones = demand % 10
            eye1.Text = tostring(tens); eye1.TextColor3 = Color3.fromRGB(255,255,255)
            eye2.Text = tostring(ones); eye2.TextColor3 = Color3.fromRGB(255,255,255)
            smile.Text = "·_·"

            -- Countdown + collection check
            local elapsed = 0
            local done = false
            local countConn
            countConn = RunService.Heartbeat:Connect(function(cdt)
                if not face.Parent then countConn:Disconnect(); return end
                if GS.Phase=="DEAD" then face:Destroy(); countConn:Disconnect(); greedActive=false; return end
                elapsed += cdt
                local frac = math.max(0, 1 - elapsed/timerDur)
                timerBar.Size = UDim2.new(frac,0,1,0)
                timerBar.BackgroundColor3 = Color3.fromHSV(frac*0.33, 1, 1)  -- green→red

                -- Count collected shards near player
                local hrp = getHRP()
                if hrp then
                    -- Check reality shards
                    for i=#GS.RealityShards,1,-1 do
                        local s=GS.RealityShards[i]
                        if s and s.Parent and (hrp.Position-s.Position).Magnitude<5.5 then
                            collected+=1; progLbl.Text=collected.."/"..demand
                        end
                    end
                    -- Check cosmic shards during shatter
                    if GS.IsShatter then
                        for i=#GS.CosmicShards,1,-1 do
                            local s=GS.CosmicShards[i]
                            if s and s.Parent and (hrp.Position-s.Position).Magnitude<5.5 then
                                collected+=1; progLbl.Text=collected.."/"..demand
                            end
                        end
                    end
                end

                if collected >= demand and not done then
                    done = true; countConn:Disconnect()
                    smile.Text = ":)"; topLbl.Text = "Thank You."
                    eye1.Text = "^"; eye2.Text = "^"
                    face.BackgroundColor3 = Color3.fromRGB(80,255,80)
                    task.wait(1.5)
                    if face.Parent then
                        TweenService:Create(face,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play()
                        Debris:AddItem(face, 0.6)
                    end
                    greedActive = false
                elseif elapsed >= timerDur and not done then
                    done = true; countConn:Disconnect()
                    -- Kill player
                    local hum = getHum()
                    if hum and hum.Health > 0 then hum.Health = 0 end
                    if face.Parent then face:Destroy() end
                    greedActive = false
                end
            end)
        end)
    end)
    table.insert(GS.EntityConns, conn)
    print("[Devoid] Greed spawned")
end

-- CRESCENDO
local function spawnCrescendo(def, platforms)
    local timer = 0
    local nextInterval = math.random(def.MinInterval, def.MaxInterval)
    local active = false

    local conn = RunService.Heartbeat:Connect(function(dt)
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        timer += dt
        if timer < nextInterval or active then return end
        timer = 0
        local minI = GS.IsShatter and def.ShatterMinInterval or def.MinInterval
        local maxI = GS.IsShatter and def.ShatterMaxInterval or def.MaxInterval
        nextInterval = math.random(minI, maxI)
        active = true

        task.spawn(function()
            local hrp = getHRP(); if not hrp then active=false; return end

            local beamCount = GS.IsShatter and def.ShatterBeamCount or def.BeamCount
            local BEAM_LENGTH = 8000
            local beams = {}
            local swordModels = {}

            -- Generate fixed directions for this attack (random per-fire)
            local dirs = {}
            for i = 1, beamCount do
                local vertical = GS.IsShatter and math.random() < 0.4
                if vertical then
                    table.insert(dirs, {vec=Vector3.new(0,1,0), vertical=true})
                else
                    local randAngle = math.random() * math.pi * 2
                    table.insert(dirs, {
                        vec=Vector3.new(math.cos(randAngle), 0, math.sin(randAngle)),
                        vertical=false
                    })
                end
            end

            -- Spawn beams
            for _, dirData in ipairs(dirs) do
                local d = dirData.vec
                local beam = Instance.new("Part", MAP_FOLDER)
                beam.Name = "CrescendoBeam"
                beam.Size = Vector3.new(2.5, 2.5, BEAM_LENGTH)
                beam.Anchored = true; beam.CanCollide = false
                beam.Material = Enum.Material.Neon
                beam.Color = Color3.fromRGB(220, 0, 0)
                beam.Transparency = 0.72
                table.insert(beams, {part=beam, dir=dirData})
            end

            -- Track beams following player during WarnTime
            local warnElapsed = 0
            local followConn
            followConn = RunService.Heartbeat:Connect(function(dt)
                warnElapsed += dt
                local hrp2 = getHRP()
                if not hrp2 then followConn:Disconnect(); return end
                local pos = hrp2.Position
                for _, beamData in ipairs(beams) do
                    local b = beamData.part
                    if not b.Parent then continue end
                    local d = beamData.dir.vec
                    if beamData.dir.vertical then
                        b.CFrame = CFrame.new(pos) * CFrame.Angles(math.pi/2, 0, 0)
                    else
                        -- Keep beam centered on player, oriented along d
                        b.CFrame = CFrame.new(pos, pos + d)
                        b.CFrame = CFrame.new(pos) * (b.CFrame - b.CFrame.Position)
                        -- Simpler: just LookAt + position
                        local lookCF = CFrame.lookAt(pos, pos + d)
                        b.CFrame = lookCF
                    end
                end
                if warnElapsed >= def.WarnTime then followConn:Disconnect() end
            end)

            -- Warning label
            local warnLbl = Instance.new("TextLabel", GUI)
            warnLbl.Size = UDim2.new(0.6,0,0,44); warnLbl.Position = UDim2.new(0.2,0,0.3,0)
            warnLbl.BackgroundTransparency = 1; warnLbl.TextColor3 = Color3.fromRGB(255,40,40)
            warnLbl.TextScaled = true; warnLbl.Font = Enum.Font.GothamBold
            warnLbl.Text = "⚠  DODGE THE BEAMS  ⚠"; warnLbl.ZIndex = 15
            TweenService:Create(warnLbl, TweenInfo.new(2.8), {TextTransparency=1}):Play()
            Debris:AddItem(warnLbl, 3)

            -- Wait for dodge window
            task.wait(def.WarnTime)
            followConn:Disconnect()

            if GS.Phase == "DEAD" then
                for _, b in ipairs(beams) do if b.part.Parent then b.part:Destroy() end end
                active = false; return
            end

            -- Snapshot player position when swords fire (beams lock here)
            local fireOrigin = getHRP() and getHRP().Position or hrp.Position

            -- Destroy beams NOW — before swords fire
            for _, b in ipairs(beams) do
                if b.part.Parent then b.part:Destroy() end
            end

            -- Fire swords along each beam direction
            for _, beamData in ipairs(beams) do
                local d = beamData.dir.vec
                local isVert = beamData.dir.vertical

                -- Sword model
                local sModel = Instance.new("Model", MAP_FOLDER); sModel.Name = "CrescendoSword"
                local blade = Instance.new("Part", sModel)
                blade.Size = Vector3.new(1, 1, 22)
                blade.Material = Enum.Material.Neon
                blade.Color = Color3.fromRGB(200, 80, 255)
                blade.CanCollide = false; blade.Anchored = true

                local tip = Instance.new("Part", sModel)
                tip.Size = Vector3.new(0.5, 0.5, 5)
                tip.Material = Enum.Material.Neon
                tip.Color = Color3.fromRGB(255, 200, 255)
                tip.CanCollide = false; tip.Anchored = true

                -- Wings
                for _, side in ipairs({-1, 1}) do
                    local wing = Instance.new("Part", sModel)
                    wing.Size = Vector3.new(5, 0.4, 3)
                    wing.Material = Enum.Material.Neon
                    wing.Color = Color3.fromRGB(180, 50, 220)
                    wing.CanCollide = false; wing.Anchored = true
                    if isVert then
                        wing.CFrame = CFrame.new(fireOrigin + Vector3.new(side*3.5, 50, 0))
                    else
                        wing.CFrame = CFrame.new(fireOrigin - d*50 + Vector3.new(side*3,0,0), fireOrigin - d*50 + d)
                    end
                end

                -- Start sword 50 studs behind player
                local startPos = isVert and (fireOrigin + Vector3.new(0, 50, 0)) or (fireOrigin - d*50)
                if isVert then
                    blade.CFrame = CFrame.new(startPos) * CFrame.Angles(math.pi/2, 0, 0)
                    tip.CFrame   = CFrame.new(startPos + Vector3.new(0, 13, 0)) * CFrame.Angles(math.pi/2, 0, 0)
                else
                    blade.CFrame = CFrame.new(startPos, startPos + d)
                    tip.CFrame   = CFrame.new(startPos + d*13, startPos + d*14)
                end

                table.insert(swordModels, {model=sModel, blade=blade, tip=tip, dir=d, isVert=isVert, startPos=startPos})
            end

            -- Animate swords flying through beams
            local elapsed = 0
            local speed = 90  -- studs per second (slowed down)
            local dmgCd = {}
            local flyConn
            flyConn = RunService.Heartbeat:Connect(function(fdt)
                elapsed += fdt
                local moved = speed * elapsed

                for _, sw in ipairs(swordModels) do
                    if not sw.blade.Parent then continue end
                    if not sw.tip or not sw.tip.Parent then continue end
                    local newPos
                    if sw.isVert then
                        newPos = sw.startPos - Vector3.new(0, moved, 0)
                        sw.blade.CFrame = CFrame.new(newPos) * CFrame.Angles(math.pi/2, 0, 0)
                        sw.tip.CFrame   = CFrame.new(newPos - Vector3.new(0, 13, 0)) * CFrame.Angles(math.pi/2, 0, 0)
                    else
                        newPos = sw.startPos + sw.dir * moved
                        sw.blade.CFrame = CFrame.new(newPos, newPos + sw.dir)
                        sw.tip.CFrame   = CFrame.new(newPos + sw.dir*13, newPos + sw.dir*14)
                    end

                    -- Damage player if close to blade
                    local hrp2 = getHRP()
                    if hrp2 then
                        local dist = (hrp2.Position - newPos).Magnitude
                        if dist < 6 then
                            local now = tick()
                            if not dmgCd[sw] or now - dmgCd[sw] > 0.2 then
                                dmgCd[sw] = now
                                local hum = getHum()
                                if hum and hum.Health > 0 then hum.Health = 0 end
                            end
                        end
                    end
                end

                -- Remove everything after sword fully travels
                if elapsed > BEAM_LENGTH / speed + 0.5 then
                    flyConn:Disconnect()
                    for _, b in ipairs(beams) do if b.part.Parent then b.part:Destroy() end end
                    for _, sw in ipairs(swordModels) do if sw.model.Parent then sw.model:Destroy() end end
                    active = false
                end
            end)
            table.insert(GS.EntityConns, flyConn)
        end)
    end)
    table.insert(GS.EntityConns, conn)
    print("[Devoid] Crescendo spawned")
end

-- STARLIGHT
local function spawnStarlight(def, platforms)
    if #platforms==0 then return end
    local hrpInit=getHRP(); if not hrpInit then return end
    local ang=math.random()*math.pi*2
    local dist=math.random(100,150)
    local spawnPos=hrpInit.Position+Vector3.new(math.cos(ang)*dist,0,math.sin(ang)*dist)
    spawnPos=Vector3.new(spawnPos.X,MAP_Y+8,spawnPos.Z)

    local model=Instance.new("Model",ENTITY_FOLDER); model.Name="Starlight"

    -- 2D star body (flat disc + points)
    local body=Instance.new("Part",model)
    body.Name="Root"; body.Shape=Enum.PartType.Ball; body.Size=Vector3.new(10,10,2)
    body.Position=spawnPos; body.Anchored=true; body.CanCollide=false
    body.Material=Enum.Material.Neon; body.Color=Color3.fromRGB(255,220,40)

    -- Star points (5)
    for i=1,5 do
        local pAng=(i/5)*math.pi*2
        local pPt=Instance.new("Part",model)
        pPt.Size=Vector3.new(3,3,1.5)
        pPt.Position=body.Position+Vector3.new(math.cos(pAng)*7,math.sin(pAng)*7,0)
        pPt.Anchored=true; pPt.CanCollide=false
        pPt.Material=Enum.Material.Neon; pPt.Color=Color3.fromRGB(255,235,60)
    end

    -- Single eye
    local eye=Instance.new("Part",model)
    eye.Shape=Enum.PartType.Ball; eye.Size=Vector3.new(3,3,1.5)
    eye.Position=body.Position+Vector3.new(0,0,-1.5)
    eye.Anchored=true; eye.CanCollide=false
    eye.Material=Enum.Material.Neon; eye.Color=Color3.fromRGB(0,0,0)
    local pupil=Instance.new("Part",model)
    pupil.Shape=Enum.PartType.Ball; pupil.Size=Vector3.new(1.4,1.4,1.6)
    pupil.Position=body.Position+Vector3.new(0,0,-2)
    pupil.Anchored=true; pupil.CanCollide=false
    pupil.Material=Enum.Material.Neon; pupil.Color=Color3.fromRGB(0,200,255)

    local bb=Instance.new("BillboardGui",body)
    bb.Size=UDim2.new(0,100,0,28); bb.StudsOffset=Vector3.new(0,8,0); bb.AlwaysOnTop=true
    local bl=Instance.new("TextLabel",bb); bl.Size=UDim2.new(1,0,1,0)
    bl.BackgroundTransparency=1; bl.TextColor3=Color3.fromRGB(255,240,80)
    bl.TextScaled=true; bl.Font=Enum.Font.GothamBold; bl.Text="Starlight"

    model.PrimaryPart=body; table.insert(GS.Entities,model)

    local phase="chase"  -- chase | aim | fire | cooldown
    local phaseTimer=0
    local aimDir=Vector3.new(1,0,0)
    local warnBeam=nil; local fireBeam=nil

    local conn=RunService.Heartbeat:Connect(function(dt)
        if not model.Parent then return end
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        local hrp=getHRP(); if not hrp then return end

        phaseTimer+=dt

        -- Rotate star visually
        for _,p in ipairs(model:GetChildren()) do
            if p:IsA("BasePart") then
                p.CFrame=p.CFrame*CFrame.Angles(0,0,dt*1.5)
            end
        end

        if phase=="chase" then
            local speed=GS.IsShatter and def.ShatterSpeed or def.Speed
            local diff=hrp.Position-body.Position; diff=Vector3.new(diff.X,0,diff.Z)
            local dist2=diff.Magnitude
            if dist2>2 then
                local mv=diff.Unit*speed*dt
                for _,p in ipairs(model:GetChildren()) do
                    if p:IsA("BasePart") then p.Position+=mv end
                end
            end
            -- Switch to aim after random 4-8s
            if phaseTimer>=math.random(4,8) then
                phase="aim"; phaseTimer=0
            end

        elseif phase=="aim" then
            -- Transparent warning beam tracking player with 2s delay
            local aimDelay=GS.IsShatter and def.ShatterAimDelay or def.AimDelay
            local hrpPos=hrp.Position
            local newDir=(hrpPos-body.Position); newDir=Vector3.new(newDir.X,0,newDir.Z)
            if newDir.Magnitude>0 then
                -- Lerp aim direction slowly (the 2s delay effect)
                aimDir=(aimDir+(newDir.Unit-aimDir)*dt*(1/aimDelay)*0.5)
                if aimDir.Magnitude>0 then aimDir=aimDir.Unit end
            end
            -- Update/create warning beam
            if warnBeam==nil then
                warnBeam=Instance.new("Part",MAP_FOLDER)
                warnBeam.Name="StarlightWarnBeam"; warnBeam.CanCollide=false; warnBeam.Anchored=true
                warnBeam.Material=Enum.Material.Neon; warnBeam.Color=Color3.fromRGB(255,240,80)
                warnBeam.Transparency=0.78
            end
            warnBeam.Size=Vector3.new(4,4,def.BeamLength)
            warnBeam.CFrame=CFrame.new(body.Position+aimDir*(def.BeamLength/2),body.Position+aimDir*(def.BeamLength+1))

            if phaseTimer>=aimDelay then
                phase="fire"; phaseTimer=0
                -- Fire sound
                playSound(SFX.StarlightCharge,2,body.Position)
                if warnBeam and warnBeam.Parent then warnBeam:Destroy(); warnBeam=nil end
                -- Spawn real beam
                fireBeam=Instance.new("Part",MAP_FOLDER)
                fireBeam.Name="StarlightBeam"; fireBeam.CanCollide=false; fireBeam.Anchored=true
                fireBeam.Material=Enum.Material.Neon; fireBeam.Color=Color3.fromRGB(255,255,100)
                fireBeam.Transparency=0.08
                fireBeam.Size=Vector3.new(7,7,def.BeamLength)
                fireBeam.CFrame=CFrame.new(body.Position+aimDir*(def.BeamLength/2),body.Position+aimDir*(def.BeamLength+1))
            end

        elseif phase=="fire" then
            -- Keep beam in place for 3s, deal damage if player in beam
            if fireBeam and fireBeam.Parent then
                local hrpPos=hrp.Position
                -- Simple beam collision: project player onto beam axis
                local beamStart=body.Position
                local beamEnd=beamStart+aimDir*def.BeamLength
                local toPlayer=hrpPos-beamStart
                local proj=toPlayer:Dot(aimDir)
                if proj>=0 and proj<=def.BeamLength then
                    local closest=beamStart+aimDir*proj
                    if (hrpPos-closest).Magnitude<5 then
                        local hum=getHum()
                        if hum and hum.Health>0 then hum.Health=math.max(0,hum.Health-def.Damage*dt*3) end
                    end
                end
            end
            if phaseTimer>=3 then
                phase="cooldown"; phaseTimer=0
                if fireBeam and fireBeam.Parent then
                    TweenService:Create(fireBeam,TweenInfo.new(0.4),{Transparency=1}):Play()
                    Debris:AddItem(fireBeam,0.5); fireBeam=nil
                end
            end

        elseif phase=="cooldown" then
            if phaseTimer>=5 then phase="chase"; phaseTimer=0 end
        end
    end)
    table.insert(GS.EntityConns,conn)
    print("[Devoid] Starlight spawned")
end

-- Spawn dispatcher
local function spawnEntities(platforms)
    for _,c in ipairs(GS.EntityConns) do c:Disconnect() end;GS.EntityConns={}
    for _,e in ipairs(GS.Entities)    do if e and e.Parent then e:Destroy() end end;GS.Entities={}

    -- Build full spawn list: persistent pool (never cleared) + current lobby picks
    local toSpawn={}
    for _,def in ipairs(GS.PersistentEntities) do table.insert(toSpawn,def) end
    for _,def in ipairs(GS.PickedEntities)     do table.insert(toSpawn,def) end

    print("[Devoid] Spawning "..#toSpawn.." entities ("..#GS.PersistentEntities.." persistent + "..#GS.PickedEntities.." new)")
    for _,def in ipairs(toSpawn) do
        if def.AppearRound<=GS.Round then
            if     def.AI=="Follower"   then spawnFollower(def,platforms)
            elseif def.AI=="Seed"       then spawnSeed(def,platforms)
            elseif def.AI=="Target"     then spawnTarget(def,platforms)
            elseif def.AI=="Wormhole"   then spawnWormhole(def,platforms)
            elseif def.AI=="helloworld" then spawnHelloworld(def,platforms)
            elseif def.AI=="Keeper"     then spawnKeeper(def,platforms)
            elseif def.AI=="Camera"     then spawnCameraEntity(def,platforms)
            elseif def.AI=="Distortion" then spawnDistortion(def,platforms)
            elseif def.AI=="Malware"    then spawnMalware(def,platforms)
            elseif def.AI=="HookedDoll" then spawnHookedDoll(def,platforms)
            elseif def.AI=="Greed"      then spawnGreed(def,platforms)
            elseif def.AI=="Crescendo"  then spawnCrescendo(def,platforms)
            elseif def.AI=="Starlight"  then spawnStarlight(def,platforms)
            end
        end
    end
end

-- ============================================================
-- SHATTER
-- ============================================================
local function startShatter(platforms)
    GS.IsShatter=true;GS.Phase="SHATTER"
    GS.ShatterStartTick=tick()   -- grace period starts here
    lblPhase.Text="⚠  SHATTER";lblPhase.Visible=true
    lblShatterWarn.Visible=true;lblShatterWarn.TextTransparency=0
    TweenService:Create(lblShatterWarn,TweenInfo.new(2.5),{TextTransparency=1}):Play()
    task.delay(3,function() lblShatterWarn.Visible=false end)
    createSpawnBeacon()
    spawnCosmicShards(GS.TotalShards,platforms)

    -- Pathway upgrade: draw a line from player to beacon
    if GS.Upgrades.Pathway then
        task.spawn(function()
            while GS.Phase=="SHATTER" do
                local hrp=getHRP(); if not hrp then task.wait(0.1); continue end
                local beaconPos=Vector3.new(0,MAP_Y+1,0)
                local diff=beaconPos-hrp.Position
                local midPos=hrp.Position+diff*0.5
                local line=Instance.new("Part",MAP_FOLDER)
                line.Name="PathwayLine"; line.Size=Vector3.new(0.4,0.4,diff.Magnitude)
                line.CFrame=CFrame.new(midPos,beaconPos); line.Anchored=true; line.CanCollide=false
                line.Material=Enum.Material.Neon; line.Color=Color3.fromRGB(0,255,80); line.Transparency=0.25
                Debris:AddItem(line,0.12)
                task.wait(0.1)
            end
        end)
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
    for _,c in ipairs(GS.EntityConns) do if c then pcall(function() c:Disconnect() end) end end
    task.wait(0.8);HUD.Visible=false
    local names={}
    for _,e in ipairs(GS.PersistentEntities) do table.insert(names,e.Name) end
    for _,e in ipairs(GS.PickedEntities)     do table.insert(names,e.Name) end
    for _,e in ipairs(GS.FatalPickedEntities) do table.insert(names,"[FATAL] "..e.Name) end
    -- Build buffs string
    local buffLines={}
    if GS.Upgrades.MoreIncome then table.insert(buffLines,"More Income (x2 ✦)") end
    if GS.Upgrades.Speedy     then table.insert(buffLines,"Speedy (+"..(((GS.Upgrades._SpeedyStacks or 1))*5).." speed)") end
    if GS.Upgrades.Infusion   then table.insert(buffLines,"Infusion (30% Realimic)") end
    if GS.Upgrades.ArtificialPlatform then table.insert(buffLines,"Artificial Platform") end
    local buffStr = #buffLines>0 and table.concat(buffLines,"\n") or "None"
    lblDeathStats.Text=
        "Reality Shards:  "..GS.CollectedReality.." / "..GS.TotalShards.."\n"..
        "Cosmic Shards:   "..GS.CollectedCosmic.." / "..GS.TotalShards.."\n"..
        "Cosmic Bank:     "..GS.CosmicBank.." ✦\n"..
        "Rounds Beaten:   "..GS.RoundsBeaten.."\n"..
        "Entities:        "..(#names>0 and table.concat(names,", ") or "None").."\n"..
        "Buffs:\n"..buffStr
    DEATH.Visible=true;deathLock=false
end

-- ============================================================
-- ROUND COMPLETE  (called when player touches spawn beacon during shatter)
-- ============================================================
local function completeRound()
    if GS.Phase~="SHATTER" then return end
    GS.Phase="COMPLETE";GS.RoundsBeaten+=1
    local sb=MAP_FOLDER:FindFirstChild("SpawnBeacon"); if sb then sb:Destroy() end
    for _,c in ipairs(GS.EntityConns) do if c then pcall(function() c:Disconnect() end) end end
    -- Destroy any leftover cosmic shards (uncollected ones)
    for _,s in ipairs(GS.CosmicShards) do if s and s.Parent then s:Destroy() end end
    GS.CosmicShards={}
    local flash=Instance.new("Frame",GUI)
    flash.Size=UDim2.new(1,0,1,0);flash.BackgroundColor3=Color3.fromRGB(220,220,255);flash.ZIndex=25
    TweenService:Create(flash,TweenInfo.new(1.2),{BackgroundTransparency=1}):Play();Debris:AddItem(flash,1.5)
    task.wait(1.8)
    GS.Round+=1;GS.IsShatter=false
    lblRound.Text="PM "..(GS.Round-1)..":00"
    lblPhase.Visible=false;lblCosmic.Visible=false;HUD.Visible=false
    -- Carry all this round's picks into the persistent pool
    for _,def in ipairs(GS.PickedEntities) do
        table.insert(GS.PersistentEntities,def)
    end
    GS.PickedEntities={};GS.PickedAtLeastOne=false;GS.PickCounts={};GS.ShowingUpgrades=false
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
    if lblLobbyBank then lblLobbyBank.Visible=false end
    GS.Phase="PLAYING";GS.IsShatter=false
    GS.CollectedReality=0;GS.CollectedCosmic=0
    lblRound.Text="PM "..(GS.Round-1)..":00"
    lblReality.Text="Reality Shards: 0 / ..."

    -- Purple fog starts permanently from round 10
    if GS.Round>=10 then
        Lighting.FogColor=Color3.fromRGB(80,0,140)
        Lighting.FogEnd=600
        Lighting.FogStart=80
    end

    local platforms=generateMap(GS.Round)
    local count=getShardCount(GS.Round)
    spawnRealityShards(count,platforms)

    if GS.RandomMode then
        -- Random Mode: spawn 1 random entity immediately, then every 20s another
        -- Eligible = ALL entities up to current round (includes round 13+ when in that range)
        local function spawnRandomEntity()
            local eligible={}
            for _,e in ipairs(EntityRegistry) do
                if e.AppearRound<=GS.Round then table.insert(eligible,e) end
            end
            -- Include fatal entities in random mode at round 30+
            if GS.Round>=30 then
                for _,e in ipairs(FatalEntityRegistry) do
                    if e.AppearRound<=GS.Round then table.insert(eligible,e) end
                end
            end
            if #eligible==0 then return end
            local def=eligible[math.random(1,#eligible)]
            if     def.AI=="Follower"   then spawnFollower(def,platforms)
            elseif def.AI=="Seed"       then spawnSeed(def,platforms)
            elseif def.AI=="Target"     then spawnTarget(def,platforms)
            elseif def.AI=="Wormhole"   then spawnWormhole(def,platforms)
            elseif def.AI=="helloworld" then spawnHelloworld(def,platforms)
            elseif def.AI=="Keeper"     then spawnKeeper(def,platforms)
            elseif def.AI=="Camera"     then spawnCameraEntity(def,platforms)
            elseif def.AI=="Distortion" then spawnDistortion(def,platforms)
            elseif def.AI=="Malware"    then spawnMalware(def,platforms)
            elseif def.AI=="HookedDoll" then spawnHookedDoll(def,platforms)
            elseif def.AI=="Greed"      then spawnGreed(def,platforms)
            elseif def.AI=="Crescendo"  then spawnCrescendo(def,platforms)
            elseif def.AI=="Starlight"  then spawnStarlight(def,platforms)
            -- Fatal entities
            elseif def.AI=="Guardian"    then spawnGuardian(def,platforms)
            elseif def.AI=="MementoMori" then spawnMementoMori(def,platforms)
            elseif def.AI=="Flesh"       then spawnFlesh(def,platforms)
            end
        end
        spawnRandomEntity()
        task.spawn(function()
            while GS.Phase=="PLAYING" or GS.Phase=="SHATTER" do
                task.wait(20)
                if GS.Phase~="PLAYING" and GS.Phase~="SHATTER" then break end
                spawnRandomEntity()
            end
        end)
    else
        spawnEntities(platforms)
    end

    -- Apply Speedy + Jumpy stacks
    local hum2=getHum()
    if hum2 then
        if GS.Upgrades._SpeedyStacks then hum2.WalkSpeed=16+(GS.Upgrades._SpeedyStacks*5) end
        if GS.Upgrades._JumpyStacks  then hum2.JumpPower=50+(GS.Upgrades._JumpyStacks*10) end
    end
    -- Spawn fatal entities (persists like normal entities)
    spawnFatalEntities(platforms)
    GS.FatalBeaconsDone=false  -- reset for next fatal round
    local hrp=getHRP(); if hrp then character:PivotTo(CFrame.new(0,MAP_Y+5,0)) end
    print("[Devoid] Round "..GS.Round.." | Platforms: "..#platforms.." | Shards: "..count)
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

        -- Magnetic Force: pull nearby shards toward player
        if GS.Upgrades.MagneticForce then
            local allS={}
            for _,s in ipairs(GS.RealityShards) do table.insert(allS,s) end
            for _,s in ipairs(GS.CosmicShards)  do table.insert(allS,s) end
            for _,s in ipairs(allS) do
                if s and s.Parent then
                    local diff=pos-s.Position
                    if diff.Magnitude<10 and diff.Magnitude>0.5 then
                        s.Position=s.Position+diff.Unit*12*(1/60)  -- pull toward player
                    end
                end
            end
        end
        if GS.Phase=="PLAYING" then
            for i=#GS.RealityShards,1,-1 do
                local s=GS.RealityShards[i]
                if s and s.Parent and (pos-s.Position).Magnitude<5.5 then
                    local isRealimic=(s.Name=="RealimicShard")
                    s:Destroy();table.remove(GS.RealityShards,i)
                    -- RandomMode: 3x reality count (not realimic)
                    local realAdd = (GS.RandomModeMultiplier and not isRealimic) and 3 or 1
                    GS.CollectedReality += realAdd
                    if isRealimic then
                        local gain=(GS.Upgrades.MoreIncome and 2 or 1)
                        GS.CosmicBank+=gain; if updateBankLabels then updateBankLabels() end
                    end
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
                    -- RandomMode: 3x cosmic bank gain
                    local gain=(GS.Upgrades.MoreIncome and 2 or 1)*(GS.RandomModeMultiplier and 3 or 1)
                    GS.CosmicBank=GS.CosmicBank+gain
                    if updateBankLabels then updateBankLabels() end
                    lblCosmic.Text="Cosmic Shards: "..GS.CollectedCosmic.." / "..GS.TotalShards
                end
            end
            -- Beacon touch = voluntarily end round — 6s grace period prevents instant trigger
            local beaconPos=Vector3.new(0,MAP_Y+4,0)
            local gracePassed = tick()-GS.ShatterStartTick > 6
            if gracePassed and (pos-beaconPos).Magnitude<10 then completeRound() end
        end
    end)
end

-- ============================================================
-- BEACON / REROLL  (beacons allow dupes after first pick)
-- ============================================================
local function pickBeaconChoices()
    local pool={}
    for _,e in ipairs(EntityRegistry) do
        if e.AppearRound<=GS.Round then
            -- exclude if picked 3+ times already this lobby
            local cnt=GS.PickCounts[e.Name] or 0
            if cnt<3 then table.insert(pool,e) end
        end
    end
    if #pool==0 then
        -- fallback: allow any available entity ignoring cap
        for _,e in ipairs(EntityRegistry) do
            if e.AppearRound<=GS.Round then table.insert(pool,e) end
        end
    end
    local used={}; GS.BeaconChoices={}
    for i=1,BEACON_COUNT do
        if #pool==0 then break end
        local allowDupe=(#pool<=BEACON_COUNT-i+1)
        local idx;local t=0
        repeat idx=math.random(1,#pool);t+=1 until allowDupe or not used[idx] or t>30
        used[idx]=true; table.insert(GS.BeaconChoices,pool[idx])
    end
end

local function updateBeaconBillboards()
    local choices = GS.ShowingUpgrades and GS.UpgradeChoices or GS.BeaconChoices
    local isUpgrade = GS.ShowingUpgrades
    local i=0
    for _,obj in ipairs(LOBBY_FOLDER:GetChildren()) do
        if obj.Name:sub(1,9)=="BeaconOrb" then
            i+=1; local e=choices[i]
            -- Change orb color: blue for upgrades, purple for entities
            if obj:IsA("BasePart") then
                obj.Color = isUpgrade and Color3.fromRGB(0,100,255) or Color3.fromRGB(170,70,255)
            end
            if not e then
                -- Hide billboard if no choice at this slot
                local bb=obj:FindFirstChildOfClass("BillboardGui"); if bb then bb.Enabled=false end
                continue
            end
            local bb=obj:FindFirstChildOfClass("BillboardGui"); if not bb then continue end
            bb.Enabled=true
            local bg=bb:FindFirstChildOfClass("Frame"); if not bg then continue end
            for _,l in ipairs(bg:GetChildren()) do
                if l:IsA("TextLabel") then
                    if l.Name=="EntityName" then
                        l.Text = isUpgrade and (e.Name.." ["..e.Cost.."✦]") or e.Name
                        l.TextColor3 = isUpgrade and Color3.fromRGB(80,200,255) or Color3.fromRGB(220,180,255)
                    elseif l.Name=="EntityTip" then
                        l.Text="💡 "..e.Tips
                    end
                end
            end
        end
    end
    local j=0
    for _,obj in ipairs(LOBBY_FOLDER:GetChildren()) do
        if obj.Name:sub(1,11)=="BeaconBase_" then
            j+=1
            local pp=obj:FindFirstChildOfClass("ProximityPrompt")
            if pp then
                local ch=choices[j]
                pp.ObjectText = ch and ch.Name or "???"
                pp.ActionText = isUpgrade and "Buy Upgrade" or "Pick Entity"
            end
        end
    end
    -- Update start prompt
    local startBase=LOBBY_FOLDER:FindFirstChild("StartBase")
    if startBase then
        local spp=startBase:FindFirstChildOfClass("ProximityPrompt")
        if spp then spp.Enabled=GS.PickedAtLeastOne end
        startBase.Color=GS.PickedAtLeastOne and Color3.fromRGB(20,80,20) or Color3.fromRGB(12,12,12)
    end
    -- Update skip-upgrade prompt
    local skipBase=LOBBY_FOLDER:FindFirstChild("SkipUpgradeBase")
    if skipBase then
        skipBase.Transparency = isUpgrade and 0.5 or 0.9
        local spp=skipBase:FindFirstChildOfClass("ProximityPrompt")
        if spp then spp.Enabled=isUpgrade end
    end
    -- Show/hide lobby bank label
    if lblLobbyBank then lblLobbyBank.Visible=(GS.Phase=="LOBBY") end
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
-- SELECT ENTITY  — picks entity, refreshes beacons (multi-pick)
-- ============================================================
-- Forward-declare upgrade functions (defined further below)
local pickUpgradeChoices, selectUpgrade, skipUpgrades, updateBankLabels
selectEntity=function(idx)
    if GS.Phase~="LOBBY" then return end
    if GS.ShowingUpgrades then selectUpgrade(idx); return end
    local entity=GS.BeaconChoices[idx]; if not entity then return end
    table.insert(GS.PickedEntities,entity)
    GS.PickedAtLeastOne=true
    GS.PickCounts[entity.Name]=(GS.PickCounts[entity.Name] or 0)+1

    -- Flash
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

    -- After entity pick → switch beacons to upgrade mode ONLY on rounds divisible by 3
    if GS.Round % 3 == 0 then
        GS.ShowingUpgrades=true
        pickUpgradeChoices()
    else
        pickBeaconChoices()
    end
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
-- UPGRADE SYSTEM
-- ============================================================
local UpgradeRegistry = {
    {
        Name="More Income", Tips="1 cosmic shard counts as 2 from now on.",
        Cost=3, Key="MoreIncome", OneTime=false, Chain=nil,
    },
    {
        Name="Speedy", Tips="+5 walk speed permanently.",
        Cost=5, Key="Speedy", OneTime=false, Chain=nil,
    },
    {
        Name="Infusion", Tips="30% of reality shards become Realimic shards.",
        Cost=8, Key="Infusion", OneTime=true, Chain=nil,
    },
    {
        Name="Artificial Platform", Tips="While airborne, a platform spawns under your feet for 1 second.",
        Cost=10, Key="ArtificialPlatform", OneTime=true, Chain=nil,
    },
    {
        Name="Magnetic Force", Tips="Reality/Cosmic/Realimic shards within 10 studs are pulled to you.",
        Cost=6, Key="MagneticForce", OneTime=true, Chain=nil,
    },
    {
        Name="Jumpy", Tips="+10 jump power.",
        Cost=4, Key="Jumpy", OneTime=false, Chain=nil,
    },
    {
        Name="Radar", Tips="ESP all entities on the map with their names.",
        Cost=12, Key="Radar", OneTime=true, Chain=nil,
    },
    {
        Name="Pathway", Tips="During Shatter, a line guides you to the beacon.",
        Cost=7, Key="Pathway", OneTime=true, Chain=nil,
    },
    -- Chain upgrades (only appear after specific entity/upgrade)
    {
        Name="Sensory Deprivation", Tips="Keeper's detection range is reduced by 20 studs.",
        Cost=9, Key="SensoryDeprivation", OneTime=true, Chain="Keeper",
    },
    {
        Name="Where'd Go?", Tips="Guardian's orbs spawn at random spots 30-50 studs away instead of bursting from it.",
        Cost=11, Key="WheredGo", OneTime=true, Chain="Guardian",
    },
    {
        Name="Railway", Tips="Flesh train is locked to the beam rail — turn speed becomes 0.",
        Cost=8, Key="Railway", OneTime=true, Chain="Flesh",
    },
}

-- Upgrade bank label (top-right of HUD)
lblCosmicBank=mkLabel(HUD,{
    Size=UDim2.new(0,220,0,38), Position=UDim2.new(1,-236,0,16),
    BackgroundColor3=Color3.fromRGB(20,14,4), BackgroundTransparency=0.3,
    TextColor3=Color3.fromRGB(255,210,40), TextScaled=true,
    Font=Enum.Font.GothamBold, Text="Bank: 0 ✦", ZIndex=2,
}); corner(lblCosmicBank)

-- Bank label shown in lobby too
lblLobbyBank=mkLabel(GUI,{
    Size=UDim2.new(0,220,0,38), Position=UDim2.new(0.5,-110,0,16),
    BackgroundColor3=Color3.fromRGB(20,14,4), BackgroundTransparency=0.3,
    TextColor3=Color3.fromRGB(255,210,40), TextScaled=true,
    Font=Enum.Font.GothamBold, Text="Bank: 0 ✦", ZIndex=2, Visible=false,
}); corner(lblLobbyBank)

updateBankLabels = function()
    local txt="Bank: "..GS.CosmicBank.." ✦"
    lblCosmicBank.Text=txt; lblLobbyBank.Text=txt
end

-- Upgrade effect: Artificial Platform
local artPlatActive=false
local function startArtificialPlatformLoop()
    local platPart=nil
    local wasAirborne=false
    local platTimer=0
    RunService.Heartbeat:Connect(function(dt)
        if not GS.Upgrades.ArtificialPlatform then return end
        if GS.Phase~="PLAYING" and GS.Phase~="SHATTER" then return end
        local hrp=getHRP(); if not hrp then return end
        local hum=getHum(); if not hum then return end
        local st=hum:GetState()
        local airborne=(st==Enum.HumanoidStateType.Freefall or st==Enum.HumanoidStateType.Jumping)
        if airborne then
            platTimer+=dt
            if not platPart or not platPart.Parent then
                platPart=Instance.new("Part",workspace)
                platPart.Size=Vector3.new(10,1,10)
                platPart.Anchored=true; platPart.CanCollide=true
                platPart.Material=Enum.Material.Neon; platPart.Color=Color3.fromRGB(0,180,255)
                platPart.Transparency=0.4
            end
            -- Follow horizontally only
            platPart.Position=Vector3.new(hrp.Position.X, hrp.Position.Y-3.5, hrp.Position.Z)
            if platTimer>=1 then
                if platPart and platPart.Parent then
                    TweenService:Create(platPart,TweenInfo.new(0.3),{Transparency=1}):Play()
                    Debris:AddItem(platPart,0.35); platPart=nil
                end
                platTimer=0
            end
        else
            platTimer=0
            if platPart and platPart.Parent then
                TweenService:Create(platPart,TweenInfo.new(0.2),{Transparency=1}):Play()
                Debris:AddItem(platPart,0.25); platPart=nil
            end
        end
    end)
end
startArtificialPlatformLoop()

local function applyUpgradeEffect(upg)
    GS.Upgrades[upg.Key]=true
    if upg.Key=="Speedy" then
        local hum=getHum()
        GS.Upgrades._SpeedyStacks=(GS.Upgrades._SpeedyStacks or 0)+1
        if hum then hum.WalkSpeed=16+(GS.Upgrades._SpeedyStacks*5) end
    elseif upg.Key=="Jumpy" then
        local hum=getHum()
        GS.Upgrades._JumpyStacks=(GS.Upgrades._JumpyStacks or 0)+1
        if hum then hum.JumpPower=(hum.JumpPower or 50)+10 end
    elseif upg.Key=="Radar" then
        -- ESP: attach BillboardGui to all existing entity models
        task.spawn(function()
            while GS.Upgrades.Radar do
                for _,e in ipairs(GS.Entities) do
                    if e and e.Parent then
                        local root=e:FindFirstChild("HumanoidRootPart") or e:FindFirstChild("Root") or e:FindFirstChild("Torso")
                        if root and not root:FindFirstChild("RadarBB") then
                            local bb=Instance.new("BillboardGui",root); bb.Name="RadarBB"
                            bb.Size=UDim2.new(0,110,0,28); bb.StudsOffset=Vector3.new(0,6,0); bb.AlwaysOnTop=true
                            local lbl=Instance.new("TextLabel",bb); lbl.Size=UDim2.new(1,0,1,0)
                            lbl.BackgroundColor3=Color3.fromRGB(0,0,0); lbl.BackgroundTransparency=0.35
                            lbl.TextColor3=Color3.fromRGB(0,255,200); lbl.TextScaled=true
                            lbl.Font=Enum.Font.GothamBold; lbl.Text="[ESP] "..e.Name
                        end
                    end
                end
                task.wait(1)
            end
        end)
    elseif upg.Key=="SensoryDeprivation" then
        -- Applied live in Keeper AI via GS.Upgrades.SensoryDeprivation check
    elseif upg.Key=="WheredGo" then
        -- Applied live in Guardian AI
    elseif upg.Key=="Railway" then
        -- Applied live in Flesh AI via GS.Upgrades.Railway
    end
end

pickUpgradeChoices = function()
    local pool={}
    for _,u in ipairs(UpgradeRegistry) do
        if u.OneTime and GS.Upgrades[u.Key] then continue end  -- already owned
        -- Chain check: only show if the required entity/upgrade was picked
        if u.Chain then
            local found = false
            for _,e in ipairs(GS.PersistentEntities) do if e.Name==u.Chain then found=true end end
            for _,e in ipairs(GS.PickedEntities)     do if e.Name==u.Chain then found=true end end
            for _,e in ipairs(GS.FatalPickedEntities) do if e.Name==u.Chain then found=true end end
            if not found then continue end
        end
        table.insert(pool, u)
    end
    if #pool==0 then GS.UpgradeChoices={}; return end
    local used={}; GS.UpgradeChoices={}
    local n=math.min(BEACON_COUNT, #pool)
    for i=1,n do
        local idx;local t=0
        repeat idx=math.random(1,#pool);t+=1 until not used[idx] or t>30
        used[idx]=true; table.insert(GS.UpgradeChoices, pool[idx])
    end
end

selectUpgrade = function(idx)
    if GS.Phase~="LOBBY" then return end
    local upg=GS.UpgradeChoices[idx]; if not upg then return end
    if GS.CosmicBank < upg.Cost then
        -- Not enough shards: show flash red
        local poor=Instance.new("TextLabel",GUI)
        poor.Size=UDim2.new(0.6,0,0,48);poor.Position=UDim2.new(0.2,0,0.44,0)
        poor.BackgroundTransparency=1;poor.TextColor3=Color3.fromRGB(255,60,60)
        poor.TextScaled=true;poor.Font=Enum.Font.GothamBold
        poor.Text="Not enough ✦ (need "..upg.Cost..")";poor.ZIndex=22
        TweenService:Create(poor,TweenInfo.new(1.5),{TextTransparency=1}):Play()
        Debris:AddItem(poor,1.8)
        return
    end
    GS.CosmicBank-=upg.Cost
    updateBankLabels()
    applyUpgradeEffect(upg)

    local flash=Instance.new("Frame",GUI)
    flash.Size=UDim2.new(1,0,1,0);flash.BackgroundColor3=Color3.fromRGB(0,60,120)
    flash.BackgroundTransparency=0.3;flash.ZIndex=20
    TweenService:Create(flash,TweenInfo.new(0.9),{BackgroundTransparency=1}):Play();Debris:AddItem(flash,1)

    local popup=Instance.new("TextLabel",GUI)
    popup.Size=UDim2.new(1,0,0,58);popup.Position=UDim2.new(0,0,0.42,0)
    popup.BackgroundTransparency=1;popup.TextColor3=Color3.fromRGB(100,200,255)
    popup.TextScaled=true;popup.Font=Enum.Font.GothamBold
    popup.Text="Upgrade: "..upg.Name;popup.ZIndex=21
    TweenService:Create(popup,TweenInfo.new(1.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0.5),{TextTransparency=1}):Play()
    Debris:AddItem(popup,2.5)

    -- Return to entity beacons
    GS.ShowingUpgrades=false
    pickBeaconChoices()
    updateBeaconBillboards()
end

skipUpgrades = function()
    if GS.Phase~="LOBBY" or not GS.ShowingUpgrades then return end
    GS.ShowingUpgrades=false
    pickBeaconChoices()
    updateBeaconBillboards()
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
    -- Fade in
    TweenService:Create(lbl,TweenInfo.new(1.2),{TextTransparency=0,BackgroundTransparency=0.28}):Play()
    -- Hold, then fade out
    task.delay(5,function()
        TweenService:Create(lbl,TweenInfo.new(2),{TextTransparency=1,BackgroundTransparency=1}):Play()
        Debris:AddItem(lbl,2.2)
    end)
end

-- ============================================================
-- LOBBY BUILDER
-- ============================================================
buildLobby=function()
    -- Clear old lobby objects
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

    -- Title sign
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

    -- Beacons
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

    -- Reroll station
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

    -- START ROUND platform (glows green when at least 1 entity picked)
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

    -- Skip upgrade pad (lit when upgrade beacons are showing)
    local skipBase=Instance.new("Part",LOBBY_FOLDER)
    skipBase.Name="SkipUpgradeBase";skipBase.Size=Vector3.new(12,1,12)
    skipBase.Position=Vector3.new(42,LOBBY_Y+1.5,50);skipBase.Anchored=true
    skipBase.Material=Enum.Material.Neon
    skipBase.Color=Color3.fromRGB(80,40,0); skipBase.Transparency=0.9
    local skipSP=Instance.new("Part",LOBBY_FOLDER)
    skipSP.Size=Vector3.new(12,4,1);skipSP.Position=Vector3.new(42,LOBBY_Y+7,53)
    skipSP.Anchored=true;skipSP.Material=Enum.Material.SmoothPlastic;skipSP.Color=Color3.fromRGB(30,14,4)
    local skipG=Instance.new("SurfaceGui",skipSP)
    skipG.Face=Enum.NormalId.Front;skipG.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;skipG.PixelsPerStud=40
    local skL=Instance.new("TextLabel",skipG)
    skL.Size=UDim2.new(1,0,1,0);skL.BackgroundTransparency=1
    skL.TextColor3=Color3.fromRGB(255,160,60);skL.TextScaled=true;skL.Font=Enum.Font.GothamBold;skL.Text="SKIP UPGRADE"
    local skipPP=Instance.new("ProximityPrompt",skipBase)
    skipPP.ActionText="Skip";skipPP.ObjectText="Skip Upgrade"
    skipPP.MaxActivationDistance=35;skipPP.RequiresLineOfSight=false
    skipPP.Enabled=GS.ShowingUpgrades
    skipPP.Triggered:Connect(function(p) if p==player then skipUpgrades() end end)

    -- Lobby bank label
    lblLobbyBank.Visible=true
    if lblCosmicBank then lblCosmicBank.Parent=HUD end -- stays inside HUD, only shows when HUD is visible
    updateBankLabels()

    -- Round gate messages
    if GS.Round==6  then task.delay(1,showGateMessage) end
    if GS.Round==13 then
        task.delay(1, function()
            local lbl=Instance.new("TextLabel",GUI)
            lbl.Size=UDim2.new(0.85,0,0,62);lbl.Position=UDim2.new(0.075,0,0.4,0)
            lbl.BackgroundColor3=Color3.fromRGB(20,0,8);lbl.BackgroundTransparency=0.3
            lbl.TextColor3=Color3.fromRGB(255,60,100)
            lbl.TextScaled=true;lbl.Font=Enum.Font.GothamBold;lbl.TextWrapped=true
            lbl.Text="2nd gate of the void opens, Freeing the deep entities."
            lbl.ZIndex=18;lbl.TextTransparency=1
            corner(lbl,10)
            TweenService:Create(lbl,TweenInfo.new(1.2),{TextTransparency=0,BackgroundTransparency=0.28}):Play()
            task.delay(5,function()
                TweenService:Create(lbl,TweenInfo.new(2),{TextTransparency=1,BackgroundTransparency=1}):Play()
                Debris:AddItem(lbl,2.2)
            end)
        end)
    end

    if GS.Round==25 then
        task.delay(1, function()
            local lbl=Instance.new("TextLabel",GUI)
            lbl.Size=UDim2.new(0.85,0,0,62);lbl.Position=UDim2.new(0.075,0,0.4,0)
            lbl.BackgroundColor3=Color3.fromRGB(25,0,4);lbl.BackgroundTransparency=0.3
            lbl.TextColor3=Color3.fromRGB(255,20,20)
            lbl.TextScaled=true;lbl.Font=Enum.Font.GothamBold;lbl.TextWrapped=true
            lbl.Text="The 3rd gates of void opens, freeing the cosmic disasters."
            lbl.ZIndex=18;lbl.TextTransparency=1; corner(lbl,10)
            TweenService:Create(lbl,TweenInfo.new(1.2),{TextTransparency=0,BackgroundTransparency=0.28}):Play()
            task.delay(5,function()
                TweenService:Create(lbl,TweenInfo.new(2),{TextTransparency=1,BackgroundTransparency=1}):Play()
                Debris:AddItem(lbl,2.2)
            end)
        end)
    end

    -- Fatal entity beacons: round 25 and every 2+ rounds after (25,27,29,31…)
    local isFatalRound = GS.Round>=25 and (GS.Round==25 or (GS.Round-25)%2==0)
    if isFatalRound and not GS.FatalBeaconsDone then
        GS.ShowingFatalBeacons = true
        -- Hide normal beacons until fatal is picked
        for _,obj in ipairs(LOBBY_FOLDER:GetChildren()) do
            if obj.Name:sub(1,11)=="BeaconBase_" then
                local pp=obj:FindFirstChildOfClass("ProximityPrompt")
                if pp then pp.Enabled=false end
                obj.Transparency=0.8
            end
            if obj.Name:sub(1,9)=="BeaconOrb" then obj.Transparency=0.85 end
        end

        local fatalPool={}
        for _,e in ipairs(FatalEntityRegistry) do
            if e.AppearRound<=GS.Round then
                local cnt=GS.FatalPickCounts[e.Name] or 0
                if cnt<MAX_FATAL_PICKS then table.insert(fatalPool,e) end
            end
        end
        GS.FatalBeaconChoices = {}
        for i=1,math.min(BEACON_COUNT,#fatalPool) do
            table.insert(GS.FatalBeaconChoices, fatalPool[i])
        end

        -- Fatal sign
        local fSign=Instance.new("Part",LOBBY_FOLDER)
        fSign.Size=Vector3.new(60,9,1); fSign.Position=Vector3.new(0,LOBBY_Y+18,-5)
        fSign.Anchored=true; fSign.Material=Enum.Material.SmoothPlastic; fSign.Color=Color3.fromRGB(25,0,0)
        local fsG=Instance.new("SurfaceGui",fSign)
        fsG.Face=Enum.NormalId.Front; fsG.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; fsG.PixelsPerStud=42
        local fsL=Instance.new("TextLabel",fsG)
        fsL.Size=UDim2.new(1,0,1,0); fsL.BackgroundTransparency=1
        fsL.TextColor3=Color3.fromRGB(255,60,60); fsL.TextScaled=true; fsL.Font=Enum.Font.GothamBold
        fsL.Text="⚠  FATAL ENTITIES — Pick one before choosing your entity  ⚠"

        -- Fatal beacons at ground level, Z=-5 (between spawn at Z=-42 and normal beacons at Z=22)
        local fbxs={-40,0,40}
        for i=1,math.min(BEACON_COUNT,#GS.FatalBeaconChoices) do
            local bx=fbxs[i]; local bz=-5; local by=LOBBY_Y+1.5

            local fBase=Instance.new("Part",LOBBY_FOLDER)
            fBase.Name="FatalBeaconBase_"..i; fBase.Size=Vector3.new(10,1,10)
            fBase.Position=Vector3.new(bx,by,bz); fBase.Anchored=true
            fBase.Material=Enum.Material.Neon; fBase.Color=Color3.fromRGB(180,0,0)

            local fPillar=Instance.new("Part",LOBBY_FOLDER)
            fPillar.Size=Vector3.new(2,12,2); fPillar.Position=Vector3.new(bx,by+6,bz)
            fPillar.Anchored=true; fPillar.Material=Enum.Material.Neon; fPillar.Color=Color3.fromRGB(220,0,0)

            local fOrb=Instance.new("Part",LOBBY_FOLDER)
            fOrb.Name="FatalBeaconOrb_"..i; fOrb.Shape=Enum.PartType.Ball; fOrb.Size=Vector3.new(3.5,3.5,3.5)
            fOrb.Position=Vector3.new(bx,by+14,bz); fOrb.Anchored=true; fOrb.CanCollide=false
            fOrb.Material=Enum.Material.Neon; fOrb.Color=Color3.fromRGB(255,0,0)

            local fbb=Instance.new("BillboardGui",fOrb)
            fbb.Size=UDim2.new(0,235,0,140); fbb.StudsOffset=Vector3.new(0,4,0); fbb.AlwaysOnTop=true; fbb.LightInfluence=0
            local fbg=Instance.new("Frame",fbb); fbg.Size=UDim2.new(1,0,1,0)
            fbg.BackgroundColor3=Color3.fromRGB(25,0,0); fbg.BackgroundTransparency=0.28; corner(fbg,10)

            local fTitle=Instance.new("TextLabel",fbg)
            fTitle.Size=UDim2.new(1,0,0,22); fTitle.BackgroundTransparency=1
            fTitle.TextColor3=Color3.fromRGB(255,50,50); fTitle.TextScaled=true
            fTitle.Font=Enum.Font.GothamBold; fTitle.Text="⚠ FATAL ENTITY"

            local fnmL=Instance.new("TextLabel",fbg)
            fnmL.Name="FatalName"; fnmL.Size=UDim2.new(1,-8,0.38,0); fnmL.Position=UDim2.new(0,4,0.2,0)
            fnmL.BackgroundTransparency=1; fnmL.TextColor3=Color3.fromRGB(255,120,120)
            fnmL.TextScaled=true; fnmL.Font=Enum.Font.GothamBold; fnmL.Text=GS.FatalBeaconChoices[i].Name

            local ftpL=Instance.new("TextLabel",fbg)
            ftpL.Size=UDim2.new(1,-8,0.38,0); ftpL.Position=UDim2.new(0,4,0.58,0)
            ftpL.BackgroundTransparency=1; ftpL.TextColor3=Color3.fromRGB(220,160,160)
            ftpL.TextScaled=true; ftpL.Font=Enum.Font.Gotham; ftpL.TextWrapped=true
            ftpL.Text="💡 "..GS.FatalBeaconChoices[i].Tips

            local fpp=Instance.new("ProximityPrompt",fBase)
            fpp.ActionText="Pick Fatal Entity"; fpp.ObjectText=GS.FatalBeaconChoices[i].Name
            fpp.MaxActivationDistance=60; fpp.RequiresLineOfSight=false

            local fi=i
            fpp.Triggered:Connect(function(p)
                if p~=player then return end
                local chosen=GS.FatalBeaconChoices[fi]; if not chosen then return end
                table.insert(GS.FatalPickedEntities, chosen)
                GS.FatalPickCounts[chosen.Name]=(GS.FatalPickCounts[chosen.Name] or 0)+1
                GS.FatalBeaconsDone=true; GS.ShowingFatalBeacons=false

                -- Destroy fatal beacons
                for _,obj in ipairs(LOBBY_FOLDER:GetChildren()) do
                    if obj.Name:sub(1,12)=="FatalBeacon" then obj:Destroy() end
                end
                if fSign.Parent then fSign:Destroy() end

                -- Re-enable normal beacons
                for _,obj in ipairs(LOBBY_FOLDER:GetChildren()) do
                    if obj.Name:sub(1,11)=="BeaconBase_" then
                        local pp2=obj:FindFirstChildOfClass("ProximityPrompt")
                        if pp2 then pp2.Enabled=true end
                        obj.Transparency=0
                    end
                    if obj.Name:sub(1,9)=="BeaconOrb" then obj.Transparency=0 end
                end

                local flash=Instance.new("Frame",GUI)
                flash.Size=UDim2.new(1,0,1,0); flash.BackgroundColor3=Color3.fromRGB(140,0,0)
                flash.BackgroundTransparency=0.3; flash.ZIndex=20
                TweenService:Create(flash,TweenInfo.new(0.9),{BackgroundTransparency=1}):Play(); Debris:AddItem(flash,1)

                local popup=Instance.new("TextLabel",GUI)
                popup.Size=UDim2.new(1,0,0,58); popup.Position=UDim2.new(0,0,0.42,0)
                popup.BackgroundTransparency=1; popup.TextColor3=Color3.fromRGB(255,100,100)
                popup.TextScaled=true; popup.Font=Enum.Font.GothamBold
                popup.Text="Fatal Entity: "..chosen.Name; popup.ZIndex=21
                TweenService:Create(popup,TweenInfo.new(1.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,0.5),{TextTransparency=1}):Play()
                Debris:AddItem(popup,2.5)

                pickBeaconChoices(); updateBeaconBillboards()
            end)
        end
    end

    -- Random Mode offer: every multiple of 10 (10,20,30...)
    if GS.Round>=10 and GS.Round%10==0 and not GS.RandomMode then
        task.delay(1.5, function()
            -- Dark overlay
            local overlay=mkFrame(GUI,{
                Size=UDim2.new(1,0,1,0),
                BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.45,
                ZIndex=40,
            })
            local offerBox=mkFrame(GUI,{
                Size=UDim2.new(0,480,0,320),
                Position=UDim2.new(0.5,-240,0.5,-160),
                BackgroundColor3=Color3.fromRGB(12,6,28),BackgroundTransparency=0.08,
                ZIndex=41,
            }); corner(offerBox,14)

            mkLabel(offerBox,{
                Size=UDim2.new(1,0,0,52),Position=UDim2.new(0,0,0,0),
                BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,200,40),
                TextScaled=true,Font=Enum.Font.GothamBold,Text="Random Mode",ZIndex=42,
            })
            mkLabel(offerBox,{
                Size=UDim2.new(0.9,0,0,60),Position=UDim2.new(0.05,0,0.18,0),
                BackgroundTransparency=1,TextColor3=Color3.fromRGB(200,190,255),
                TextScaled=true,Font=Enum.Font.Gotham,TextWrapped=true,ZIndex=42,
                Text="\"You get filthy rich — we freed the entities to make some space.\"",
            })
            mkLabel(offerBox,{
                Size=UDim2.new(0.9,0,0,44),Position=UDim2.new(0.05,0,0.42,0),
                BackgroundTransparency=1,TextColor3=Color3.fromRGB(100,255,120),
                TextScaled=true,Font=Enum.Font.Gotham,TextWrapped=true,ZIndex=42,
                Text="3x Reality + Cosmic gain permanently (except Realimic)\nEntities spawn randomly every 20s",
            })

            local yesBtn=mkBtn(offerBox,{
                Size=UDim2.new(0,140,0,48),Position=UDim2.new(0.08,0,0.74,0),
                BackgroundColor3=Color3.fromRGB(30,160,30),TextColor3=Color3.fromRGB(255,255,255),
                TextScaled=true,Font=Enum.Font.GothamBold,Text="Yes",ZIndex=42,
            }); corner(yesBtn,10)
            local noBtn=mkBtn(offerBox,{
                Size=UDim2.new(0,140,0,48),Position=UDim2.new(0.62,0,0.74,0),
                BackgroundColor3=Color3.fromRGB(160,30,30),TextColor3=Color3.fromRGB(255,255,255),
                TextScaled=true,Font=Enum.Font.GothamBold,Text="No",ZIndex=42,
            }); corner(noBtn,10)

            local function closeOffer()
                overlay:Destroy(); offerBox:Destroy()
            end
            yesBtn.MouseButton1Click:Connect(function()
                GS.RandomMode=true; GS.RandomModeMultiplier=true
                closeOffer()
                -- Show brief confirmation
                local conf=mkLabel(GUI,{
                    Size=UDim2.new(0.7,0,0,52),Position=UDim2.new(0.15,0,0.45,0),
                    BackgroundTransparency=1,TextColor3=Color3.fromRGB(100,255,120),
                    TextScaled=true,Font=Enum.Font.GothamBold,
                    Text="Random Mode Activated!",ZIndex=43,
                })
                TweenService:Create(conf,TweenInfo.new(2.5),{TextTransparency=1}):Play()
                Debris:AddItem(conf,2.6)
            end)
            noBtn.MouseButton1Click:Connect(closeOffer)
        end)
    end

    task.wait(0.2)
    character:PivotTo(CFrame.new(0,LOBBY_Y+6,-42))
end

-- ============================================================
-- RETRY
-- ============================================================
btnRetry.MouseButton1Click:Connect(function()
    DEATH.Visible=false;GS.Phase="LOBBY";GS.Round=1;GS.RoundsBeaten=0
    GS.PickedEntities={};GS.PickedAtLeastOne=false;GS.PickCounts={};GS.ShowingUpgrades=false
    GS.PersistentEntities={}
    GS.RerollsLeft=MAX_REROLLS;GS.IsShatter=false
    GS.Upgrades={};GS.CosmicBank=0;updateBankLabels()
    GS.RandomMode=false;GS.RandomModeMultiplier=false
    GS.FatalPickedEntities={};GS.FatalPickCounts={};GS.FatalBeaconsDone=false
    -- Reset fog
    Lighting.FogColor=Color3.fromRGB(8,4,18);Lighting.FogEnd=1000;Lighting.FogStart=350
    HUD.Visible=false;lblCosmic.Visible=false;lblPhase.Visible=false
    lblRound.Text="PM 0:00";lblReality.Text="Reality Shards: 0 / 0"
    clearMap();buildLobby()
end)

-- ============================================================
-- /SKIP  /SHATTER  /GIVE
-- ============================================================
local function skipRound(count)
    count = math.max(1, math.floor(tonumber(count) or 1))
    if GS.Phase=="DEAD" then return end
    for _,c in ipairs(GS.EntityConns) do if c then pcall(function() c:Disconnect() end) end end;GS.EntityConns={}
    clearMap()
    GS.Round += count
    GS.RoundsBeaten += count
    GS.IsShatter=false;GS.Phase="LOBBY"
    GS.PickedEntities={};GS.PickedAtLeastOne=false;GS.PickCounts={};GS.ShowingUpgrades=false;GS.RerollsLeft=MAX_REROLLS
    GS.PersistentEntities={}
    HUD.Visible=false;lblCosmic.Visible=false;lblPhase.Visible=false
    lblRound.Text="PM "..(GS.Round-1)..":00";lblReality.Text="Reality Shards: 0 / 0"
    buildLobby()
    task.wait(0.1); character:PivotTo(CFrame.new(0,LOBBY_Y+6,-42))
    local hum=getHum(); if hum then hum.Health=hum.MaxHealth end
    print("[Devoid] /skip "..count.." → Round "..GS.Round)
end

local function shatterNow()
    if GS.Phase~="PLAYING" then return end
    for _,s in ipairs(GS.RealityShards) do if s and s.Parent then s:Destroy() end end
    GS.RealityShards={}
    GS.CollectedReality=GS.TotalShards
    lblReality.Text="Reality Shards: ALL COLLECTED ✓"
    startShatter(GS.MapPlatforms)
    print("[Devoid] /shatter activated")
end

local function giveCosmicCommand(amount)
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    GS.CosmicBank = GS.CosmicBank + amount
    if updateBankLabels then updateBankLabels() end
    print("[Devoid] /give "..amount.." → Bank: "..GS.CosmicBank)
end

-- ============================================================
-- ENTITY COMMANDS  (one-shot per invocation)
-- ============================================================
local function cmdSpawnNear(spawnFn, dist)
    -- Spawns an entity near the player. spawnFn receives a fake one-platform list.
    local hrp = getHRP(); if not hrp then return end
    local angle = math.random() * math.pi * 2
    local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * (dist or 25)
    local fakePlat = {Position = hrp.Position + offset}
    -- We need a real Part for some entity functions, create a temp anchor
    local anchor = Instance.new("Part", MAP_FOLDER)
    anchor.Size = Vector3.new(10,2,10); anchor.Anchored = true; anchor.CanCollide = false
    anchor.Transparency = 1; anchor.Position = hrp.Position + offset
    spawnFn({anchor})
end

local function cmdSpawnFollower()
    local def = nil
    for _,e in ipairs(EntityRegistry) do if e.AI=="Follower" then def=e; break end end
    if not def then return end
    cmdSpawnNear(function(plats) spawnFollower(def,plats) end, 25)
end

local function cmdSpawnSeed()
    local def = nil
    for _,e in ipairs(EntityRegistry) do if e.AI=="Seed" then def=e; break end end
    if not def or #GS.MapPlatforms==0 then return end
    spawnSeed(def, GS.MapPlatforms)
end

local function cmdSpawnTarget()
    local def = nil
    for _,e in ipairs(EntityRegistry) do if e.AI=="Target" then def=e; break end end
    if not def then return end
    -- One-shot: fire immediately then stop
    local hrp=getHRP(); if not hrp then return end
    local tPos=hrp.Position
    local radius=def.Radius
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
    mis.Size=Vector3.new(2.5,22,2.5);mis.Position=Vector3.new(tPos.X,tPos.Y+700,tPos.Z)
    mis.Anchored=true;mis.CanCollide=false;mis.Material=Enum.Material.Neon;mis.Color=Color3.fromRGB(255,80,0)
    local ma=Instance.new("Attachment",mis)
    local mpe=Instance.new("ParticleEmitter",ma)
    mpe.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,80,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,220,0))})
    mpe.LightEmission=1;mpe.Rate=120;mpe.Speed=NumberRange.new(10,24)
    mpe.Lifetime=NumberRange.new(0.2,0.8)
    mpe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,3),NumberSequenceKeypoint.new(1,0)})
    TweenService:Create(mis,TweenInfo.new(1.8,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=Vector3.new(tPos.X,tPos.Y,tPos.Z)}):Play()
    task.wait(1.85); if mis.Parent then mis:Destroy() end
    createMushroomCloud(tPos, false)
end

local function cmdSpawnHelloworld()
    local def = nil
    for _,e in ipairs(EntityRegistry) do if e.AI=="helloworld" then def=e; break end end
    if not def then return end
    cmdSpawnNear(function(plats) spawnHelloworld(def,plats) end, 25)
end

local function cmdSpawnCamera()
    local def = nil
    for _,e in ipairs(EntityRegistry) do if e.AI=="Camera" then def=e; break end end
    if not def then return end
    -- One-shot camera flash
    task.spawn(function()
        local cheese=Instance.new("TextLabel",GUI)
        cheese.Size=UDim2.new(0.7,0,0,60);cheese.Position=UDim2.new(0.15,0,0.18,0)
        cheese.BackgroundTransparency=1;cheese.TextColor3=Color3.fromRGB(255,255,200)
        cheese.TextScaled=true;cheese.Font=Enum.Font.GothamBold
        cheese.Text="📷  Say Cheese!";cheese.ZIndex=16
        TweenService:Create(cheese,TweenInfo.new(2.8),{TextTransparency=1}):Play()
        Debris:AddItem(cheese,3)
        task.wait(def.WarnTime)
        local hrp=getHRP(); if not hrp then return end
        local snapPos=hrp.Position
        playSound(SFX.CameraFlash, 1.5)
        local flash=Instance.new("Frame",GUI)
        flash.Size=UDim2.new(1,0,1,0);flash.BackgroundColor3=Color3.fromRGB(255,255,255)
        flash.BackgroundTransparency=0;flash.ZIndex=20
        shakeCamera(1.2,0.5)
        task.wait(0.08)
        local hrp2=getHRP()
        if hrp2 then
            local d=(Vector3.new(hrp2.Position.X,0,hrp2.Position.Z)-Vector3.new(snapPos.X,0,snapPos.Z)).Magnitude
            if d>1.5 then
                flash.BackgroundColor3=Color3.fromRGB(255,40,40)
                local hum=getHum()
                if hum and hum.Health>0 then hum.Health=math.max(0,hum.Health-def.Damage) end
                local dirs={Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}
                local fdir=dirs[math.random(1,#dirs)]
                local bv=Instance.new("BodyVelocity",hrp2)
                bv.Velocity=(fdir.Unit*85)+Vector3.new(0,55,0);bv.MaxForce=Vector3.new(1e5,1e5,1e5)
                Debris:AddItem(bv,0.22); shakeCamera(3.5,1.2)
            end
        end
        TweenService:Create(flash,TweenInfo.new(1.8),{BackgroundTransparency=1}):Play()
        Debris:AddItem(flash,2)
    end)
end

local function cmdSpawnKeeper()
    local def = nil
    for _,e in ipairs(EntityRegistry) do if e.AI=="Keeper" then def=e; break end end
    if not def then return end
    cmdSpawnNear(function(plats) spawnKeeper(def,plats) end, 55)
end

local function cmdSpawnDistortion()
    local def = nil
    for _,e in ipairs(EntityRegistry) do if e.AI=="Distortion" then def=e; break end end
    if not def or #GS.MapPlatforms==0 then return end
    spawnDistortion(def, GS.MapPlatforms)
end

local function cmdSpawnMalware()
    local def = nil
    for _,e in ipairs(EntityRegistry) do if e.AI=="Malware" then def=e; break end end
    if not def then return end
    local adTexts = {
        {"YOU WON A FREE IPHONE!!!", "Click OK to claim your prize!\nLimited time offer!"},
        {"⚠ VIRUS DETECTED ⚠", "Your device has 47 viruses.\nDownload our free cleaner NOW!"},
        {"HOT SINGLES IN YOUR AREA", "They are waiting for you.\nDon't keep them waiting..."},
        {"CONGRATULATIONS!", "You are the 1,000,000th visitor!\nClaim your reward immediately!"},
        {"SYSTEM WARNING", "Your RAM is critically low.\nCall 1-800-FIX-PC now."},
    }
    for i=1,5 do
        task.wait(0.08*(i-1))
        local adData=adTexts[math.random(1,#adTexts)]
        local rx=math.random(2,68)/100; local ry=math.random(10,65)/100
        local popup=mkFrame(GUI,{Size=UDim2.new(0,320,0,200),Position=UDim2.new(rx,0,ry,0),BackgroundColor3=Color3.fromRGB(195,195,195),BorderSizePixel=2,ZIndex=30,Active=true,Draggable=true})
        corner(popup,0)
        local titleBar=mkFrame(popup,{Size=UDim2.new(1,0,0,28),BackgroundColor3=Color3.fromRGB(0,0,128),ZIndex=31})
        mkLabel(titleBar,{Size=UDim2.new(1,-32,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,255,255),TextScaled=true,Font=Enum.Font.GothamBold,Text=adData[1],TextXAlignment=Enum.TextXAlignment.Left,ZIndex=32})
        local closeBtn=mkBtn(titleBar,{Size=UDim2.new(0,26,0,24),Position=UDim2.new(1,-28,0,2),BackgroundColor3=Color3.fromRGB(220,50,50),TextColor3=Color3.fromRGB(255,255,255),TextScaled=true,Font=Enum.Font.GothamBold,Text="✕",ZIndex=33}); corner(closeBtn,2)
        mkLabel(popup,{Size=UDim2.new(1,-8,0,90),Position=UDim2.new(0,4,0,34),BackgroundTransparency=1,TextColor3=Color3.fromRGB(0,0,0),TextScaled=true,Font=Enum.Font.Gotham,Text=adData[2],TextWrapped=true,ZIndex=31})
        local okBtn=mkBtn(popup,{Size=UDim2.new(0,80,0,28),Position=UDim2.new(0.5,-40,1,-36),BackgroundColor3=Color3.fromRGB(195,195,195),TextColor3=Color3.fromRGB(0,0,0),TextScaled=true,Font=Enum.Font.Gotham,Text="OK",ZIndex=32,BorderSizePixel=2})
        local function close() if popup and popup.Parent then TweenService:Create(popup,TweenInfo.new(0.15),{Size=UDim2.new(0,0,0,0)}):Play(); Debris:AddItem(popup,0.2) end end
        closeBtn.MouseButton1Click:Connect(close); okBtn.MouseButton1Click:Connect(close)
        playSound(SFX.MalwarePopup, 0.8)
    end
end

local function cmdSpawnHookedDoll()
    local def = nil
    for _,e in ipairs(EntityRegistry) do if e.AI=="HookedDoll" then def=e; break end end
    if not def then return end
    cmdSpawnNear(function(plats) spawnHookedDoll(def,plats) end, 25)
end

local function cmdSpawnGreed()
    local def = nil
    for _,e in ipairs(EntityRegistry) do if e.AI=="Greed" then def=e; break end end
    if not def then return end
    -- Force one immediate greed event
    local demand = math.random(5,15)
    if GS.IsShatter then demand = math.random(def.ShatterMinDemand, def.ShatterMaxDemand) end
    local timerDur = GS.IsShatter and def.ShatterTimerDuration or def.TimerDuration
    local collected = 0

    local face=mkFrame(GUI,{Size=UDim2.new(0,180,0,220),Position=UDim2.new(0.5,-90,0.08,0),BackgroundColor3=Color3.fromRGB(60,200,60),BackgroundTransparency=0.05,ZIndex=35}); corner(face,90)
    local eye1=mkLabel(face,{Size=UDim2.new(0,50,0,50),Position=UDim2.new(0.12,0,0.12,0),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0,TextColor3=Color3.fromRGB(255,215,0),TextScaled=true,Font=Enum.Font.GothamBold,Text="$",ZIndex=36}); corner(eye1,25)
    local eye2=mkLabel(face,{Size=UDim2.new(0,50,0,50),Position=UDim2.new(0.6,0,0.12,0),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0,TextColor3=Color3.fromRGB(255,215,0),TextScaled=true,Font=Enum.Font.GothamBold,Text="$",ZIndex=36}); corner(eye2,25)
    mkLabel(face,{Size=UDim2.new(0.75,0,0,36),Position=UDim2.new(0.125,0,0.58,0),BackgroundTransparency=1,TextColor3=Color3.fromRGB(0,0,0),TextScaled=true,Font=Enum.Font.GothamBold,Text="^___^",ZIndex=36})
    mkLabel(face,{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,-0.18,0),BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,230,0),TextScaled=true,Font=Enum.Font.GothamBold,Text="REMEMBER!!!",ZIndex=36})
    local progLbl=mkLabel(face,{Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,0.82,0),BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,255,255),TextScaled=true,Font=Enum.Font.Gotham,Text="0/"..demand,ZIndex=36})
    local timerBg=mkFrame(face,{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,0.94,0),BackgroundColor3=Color3.fromRGB(40,40,40),ZIndex=36})
    local timerBar=mkFrame(timerBg,{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(80,255,80),ZIndex=37})

    task.spawn(function()
        task.wait(def.WarnTime)
        if not face.Parent then return end
        eye1.Text=tostring(math.floor(demand/10)); eye1.TextColor3=Color3.fromRGB(255,255,255)
        eye2.Text=tostring(demand%10); eye2.TextColor3=Color3.fromRGB(255,255,255)
        local elapsed=0; local done=false
        local gc; gc=RunService.Heartbeat:Connect(function(dt)
            if not face.Parent then gc:Disconnect(); return end
            elapsed+=dt
            local frac=math.max(0,1-elapsed/timerDur)
            timerBar.Size=UDim2.new(frac,0,1,0); timerBar.BackgroundColor3=Color3.fromHSV(frac*0.33,1,1)
            local hrp=getHRP()
            if hrp then
                for i=#GS.RealityShards,1,-1 do
                    local s=GS.RealityShards[i]
                    if s and s.Parent and (hrp.Position-s.Position).Magnitude<5.5 then collected+=1; progLbl.Text=collected.."/"..demand end
                end
            end
            if collected>=demand and not done then
                done=true; gc:Disconnect()
                face.BackgroundColor3=Color3.fromRGB(80,255,80)
                task.wait(1.5); if face.Parent then TweenService:Create(face,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play(); Debris:AddItem(face,0.6) end
            elseif elapsed>=timerDur and not done then
                done=true; gc:Disconnect()
                local hum=getHum(); if hum and hum.Health>0 then hum.Health=0 end
                if face.Parent then face:Destroy() end
            end
        end)
    end)
end

local function cmdSpawnCrescendo()
    local def = nil
    for _,e in ipairs(EntityRegistry) do if e.AI=="Crescendo" then def=e; break end end
    if not def then return end
    local hrp=getHRP(); if not hrp then return end
    local beamCount=3
    local BEAM_LENGTH=8000
    local beams={}; local swordModels={}
    local dirs={}
    for i=1,beamCount do
        local ang=math.random()*math.pi*2
        table.insert(dirs,{vec=Vector3.new(math.cos(ang),0,math.sin(ang)),vertical=false})
    end
    local origin=hrp.Position
    for _,dirData in ipairs(dirs) do
        local d=dirData.vec
        local beam=Instance.new("Part",MAP_FOLDER)
        beam.Name="CrescendoBeam";beam.Size=Vector3.new(2.5,2.5,BEAM_LENGTH)
        beam.Anchored=true;beam.CanCollide=false;beam.Material=Enum.Material.Neon
        beam.Color=Color3.fromRGB(220,0,0);beam.Transparency=0.72
        beam.CFrame=CFrame.lookAt(origin,origin+d)
        table.insert(beams,{part=beam,dir=dirData})
    end
    task.spawn(function()
        task.wait(def.WarnTime)
        local fireOrigin=getHRP() and getHRP().Position or origin
        for _,b in ipairs(beams) do if b.part.Parent then b.part:Destroy() end end
        for _,beamData in ipairs(beams) do
            local d=beamData.dir.vec
            local sModel=Instance.new("Model",MAP_FOLDER); sModel.Name="CrescendoSword"
            local blade=Instance.new("Part",sModel)
            blade.Size=Vector3.new(1,1,22);blade.Material=Enum.Material.Neon;blade.Color=Color3.fromRGB(200,80,255);blade.CanCollide=false;blade.Anchored=true
            local tip=Instance.new("Part",sModel)
            tip.Size=Vector3.new(0.5,0.5,5);tip.Material=Enum.Material.Neon;tip.Color=Color3.fromRGB(255,200,255);tip.CanCollide=false;tip.Anchored=true
            local startPos=fireOrigin-d*50
            blade.CFrame=CFrame.new(startPos,startPos+d); tip.CFrame=CFrame.new(startPos+d*13,startPos+d*14)
            table.insert(swordModels,{model=sModel,blade=blade,tip=tip,dir=d,isVert=false,startPos=startPos})
        end
        local elapsed=0; local speed=90; local flyConn
        flyConn=RunService.Heartbeat:Connect(function(fdt)
            elapsed+=fdt; local moved=speed*elapsed
            for _,sw in ipairs(swordModels) do
                if not sw.blade.Parent then continue end
                if not sw.tip or not sw.tip.Parent then continue end
                local newPos=sw.startPos+sw.dir*moved
                sw.blade.CFrame=CFrame.new(newPos,newPos+sw.dir)
                sw.tip.CFrame=CFrame.new(newPos+sw.dir*13,newPos+sw.dir*14)
                local hrp2=getHRP()
                if hrp2 and (hrp2.Position-newPos).Magnitude<6 then
                    local hum=getHum(); if hum and hum.Health>0 then hum.Health=0 end
                end
            end
            if elapsed>BEAM_LENGTH/speed+0.5 then
                flyConn:Disconnect()
                for _,sw in ipairs(swordModels) do if sw.model.Parent then sw.model:Destroy() end end
            end
        end)
        table.insert(GS.EntityConns,flyConn)
    end)
end

-- ============================================================
-- GUARDIAN AI
-- ============================================================
local function spawnGuardian(def, platforms)
    local timer = 0
    local nextInterval = math.random(def.MinInterval, def.MaxInterval)
    local conn = RunService.Heartbeat:Connect(function(dt)
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        timer += dt
        if timer < nextInterval then return end
        timer = 0; nextInterval = math.random(def.MinInterval, def.MaxInterval)
        task.spawn(function()
            local hrp = getHRP(); if not hrp then return end
            local spawnPos = hrp.Position + hrp.CFrame.LookVector * 8
            local gModel = Instance.new("Model", ENTITY_FOLDER); gModel.Name = "Guardian"
            local function mkGPart(sz, pos, col, mat, trans)
                local p = Instance.new("Part", gModel)
                p.Size=sz; p.Position=pos; p.Anchored=true; p.CanCollide=false
                p.Material=mat or Enum.Material.SmoothPlastic
                p.Color=col; p.Transparency=trans or 0; return p
            end
            local torso  = mkGPart(Vector3.new(2,2,1), spawnPos+Vector3.new(0,1,0),   Color3.fromRGB(20,0,40),  Enum.Material.Neon)
            local _      = mkGPart(Vector3.new(2.2,2.2,1.1), torso.Position,          Color3.fromRGB(100,0,200),Enum.Material.Neon, 0.6)
            local head   = mkGPart(Vector3.new(2,2,1), spawnPos+Vector3.new(0,3.2,0), Color3.fromRGB(10,0,20))
            local _      = mkGPart(Vector3.new(1.6,0.3,0.2), head.Position+Vector3.new(0,0.15,-0.55), Color3.fromRGB(160,0,255), Enum.Material.Neon)
            for _,sx in ipairs({-1.5,1.5}) do
                mkGPart(Vector3.new(0.8,1.2,1.2), torso.Position+Vector3.new(sx,0.4,0), Color3.fromRGB(80,0,160), Enum.Material.Neon)
                mkGPart(Vector3.new(1,2,1), torso.Position+Vector3.new(sx*1.5,-0.5,0), Color3.fromRGB(15,0,30))
            end
            for _,lx in ipairs({-0.5,0.5}) do mkGPart(Vector3.new(0.9,2,1), torso.Position+Vector3.new(lx,-2,0), Color3.fromRGB(15,0,30)) end
            -- Cape particles
            local att=Instance.new("Attachment",torso); att.Position=Vector3.new(0,-1,0.6)
            local cpe=Instance.new("ParticleEmitter",att)
            cpe.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(80,0,160)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0))})
            cpe.LightEmission=0.8;cpe.Rate=20;cpe.Speed=NumberRange.new(2,5);cpe.Lifetime=NumberRange.new(0.4,1.2)
            cpe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(1,0)});cpe.EmissionDirection=Enum.NormalId.Back
            table.insert(GS.Entities, gModel)
            -- Follow for 3s at player's current walk speed
            local fEl=0; local fConn
            fConn=RunService.Heartbeat:Connect(function(fdt)
                fEl+=fdt; if fEl>=3 then fConn:Disconnect(); return end
                local h2=getHRP(); if not h2 then fConn:Disconnect(); return end
                local hum2=getHum()
                local followSpeed = hum2 and hum2.WalkSpeed or 16
                local move=(h2.Position+h2.CFrame.LookVector*8-torso.Position)*Vector3.new(1,0,1)
                if move.Magnitude>0.5 then
                    local mv=move.Unit*followSpeed*fdt
                    for _,p in ipairs(gModel:GetChildren()) do if p:IsA("BasePart") then p.Position+=mv end end
                end
            end)
            task.wait(3)
            local sub=Instance.new("TextLabel",GUI)
            sub.Size=UDim2.new(0.6,0,0,44);sub.Position=UDim2.new(0.2,0,0.82,0)
            sub.BackgroundTransparency=1;sub.TextColor3=Color3.fromRGB(160,0,255)
            sub.TextScaled=true;sub.Font=Enum.Font.GothamBold;sub.Text="Death on Sight.";sub.ZIndex=15
            TweenService:Create(sub,TweenInfo.new(3),{TextTransparency=1}):Play(); Debris:AddItem(sub,3.5)
            local orbCount=GS.IsShatter and def.ShatterOrbCount or def.OrbCount
            for wave=1,3 do
                if GS.Phase=="DEAD" then break end
                for o=1,orbCount do
                    if GS.Phase=="DEAD" then break end
                    local theta=math.random()*math.pi*2; local phi=(math.random()-0.5)*math.pi
                    local dir=Vector3.new(math.cos(phi)*math.cos(theta),math.sin(phi)*0.5,math.cos(phi)*math.sin(theta)).Unit
                    local orbSpawnPos
                    if GS.Upgrades.WheredGo then
                        -- Spawn at random position 30-50 studs from player instead of from Guardian
                        local hrpNow=getHRP()
                        if hrpNow then
                            local rAng=math.random()*math.pi*2
                            local rDist=math.random(30,50)
                            orbSpawnPos=hrpNow.Position+Vector3.new(math.cos(rAng)*rDist,math.random(-5,10),math.sin(rAng)*rDist)
                        else
                            orbSpawnPos=torso.Position
                        end
                    else
                        orbSpawnPos=torso.Position
                    end
                    local orb=Instance.new("Part",MAP_FOLDER)
                    orb.Shape=Enum.PartType.Ball;orb.Size=Vector3.new(14,14,14)
                    orb.Position=orbSpawnPos;orb.Anchored=true;orb.CanCollide=false
                    orb.Material=Enum.Material.Neon;orb.Color=Color3.fromRGB(5,0,15)
                    local sel=Instance.new("SelectionBox",orb);sel.Adornee=orb
                    sel.Color3=Color3.fromRGB(130,0,255);sel.LineThickness=0.12;sel.SurfaceTransparency=0.82
                    -- Charge sound on the orb (5s long)
                    playSound(SFX.OrbCharge, 1.2, orb.Position)
                    local oEl=0; local oConn
                    oConn=RunService.Heartbeat:Connect(function(odt)
                        oEl+=odt
                        local spd=math.max(0, def.OrbSpeed - oEl*6)  -- slower decel = travels much further
                        if orb.Parent then orb.Position=orb.Position+dir*spd*odt end
                        if spd<=0 then
                            oConn:Disconnect()
                            -- Wait 3s before exploding
                            task.wait(3)
                            if not orb.Parent then return end
                            playSound(SFX.OrbExplode, 1.4, orb.Position)
                            local bPos=orb.Position
                            local beamH=GS.IsShatter and 500 or 320
                            local bW=GS.IsShatter and 14 or 9
                            -- Beam goes BOTH up and down from explosion point
                            local beamUp=Instance.new("Part",MAP_FOLDER)
                            beamUp.Size=Vector3.new(bW,beamH,bW)
                            beamUp.Position=bPos+Vector3.new(0,beamH/2,0)
                            beamUp.Anchored=true;beamUp.CanCollide=false
                            beamUp.Material=Enum.Material.Neon;beamUp.Color=Color3.fromRGB(10,0,25);beamUp.Transparency=0.08
                            local bSelU=Instance.new("SelectionBox",beamUp);bSelU.Adornee=beamUp
                            bSelU.Color3=Color3.fromRGB(120,0,240);bSelU.LineThickness=0.12;bSelU.SurfaceTransparency=0.82
                            local beamDn=Instance.new("Part",MAP_FOLDER)
                            beamDn.Size=Vector3.new(bW,beamH,bW)
                            beamDn.Position=bPos-Vector3.new(0,beamH/2,0)
                            beamDn.Anchored=true;beamDn.CanCollide=false
                            beamDn.Material=Enum.Material.Neon;beamDn.Color=Color3.fromRGB(10,0,25);beamDn.Transparency=0.08
                            local bSelD=Instance.new("SelectionBox",beamDn);bSelD.Adornee=beamDn
                            bSelD.Color3=Color3.fromRGB(120,0,240);bSelD.LineThickness=0.12;bSelD.SurfaceTransparency=0.82
                            shakeCamera(3,1.5)
                            local h3=getHRP()
                            if h3 then
                                local bd=h3.Position-bPos
                                if math.abs(bd.X)<bW+1 and math.abs(bd.Z)<bW+1 then
                                    local hum=getHum(); if hum and hum.Health>0 then hum.Health=math.max(0,hum.Health-def.BeamDamage) end
                                end
                            end
                            task.wait(1)
                            if orb.Parent    then TweenService:Create(orb,    TweenInfo.new(0.4),{Transparency=1}):Play();Debris:AddItem(orb,0.5) end
                            if beamUp.Parent then TweenService:Create(beamUp, TweenInfo.new(0.6),{Transparency=1}):Play();Debris:AddItem(beamUp,0.7) end
                            if beamDn.Parent then TweenService:Create(beamDn, TweenInfo.new(0.6),{Transparency=1}):Play();Debris:AddItem(beamDn,0.7) end
                        end
                    end)
                    table.insert(GS.EntityConns,oConn)
                    task.wait(0.18)
                end
                task.wait(3)
            end
            task.wait(3)
            if gModel.Parent then
                for _,p in ipairs(gModel:GetChildren()) do if p:IsA("BasePart") then TweenService:Create(p,TweenInfo.new(1.2),{Transparency=1}):Play() end end
                Debris:AddItem(gModel,1.3)
            end
        end)
    end)
    table.insert(GS.EntityConns,conn)
    print("[Devoid] Guardian spawned")
end

-- MEMENTO MORI
local function spawnMementoMori(def, platforms)
    local timer = 0
    local nextInterval = math.random(def.MinInterval, def.MaxInterval)
    local eventActive = false

    local japaneseTexts = {
        "覚えて。","死。","失敗。","卑怯者。","走る。",
        "逃げろ。","無駄だ。","終わり。","見えない。","闇。",
        "消えろ。","絶望。","孤独。","恐怖。","静けさ。",
    }

    local conn = RunService.Heartbeat:Connect(function(dt)
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        timer += dt
        if timer < nextInterval or eventActive then return end
        timer = 0; nextInterval = math.random(def.MinInterval, def.MaxInterval)
        eventActive = true

        task.spawn(function()
            local duration     = GS.IsShatter and def.ShatterDuration     or def.Duration
            local airTimeLimit = GS.IsShatter and def.ShatterAirTime      or def.AirTime
            local textMult     = GS.IsShatter and 2 or 1
            local totalTexts   = (def.BaseTextCount + math.floor(GS.Round * def.ExtraTextPerRound / 5)) * textMult

            -- Red fog
            local oldFogColor = Lighting.FogColor
            local oldFogEnd   = Lighting.FogEnd
            local oldFogStart = Lighting.FogStart
            Lighting.FogColor = Color3.fromRGB(180, 0, 0)
            Lighting.FogEnd   = 500
            Lighting.FogStart = 60

            -- Ambience sound
            local ambSnd=Instance.new("Sound",workspace)
            ambSnd.SoundId="rbxassetid://"..SFX.MementoAmbience
            ambSnd.Volume=1.2; ambSnd.Looped=true; ambSnd:Play()
            Debris:AddItem(ambSnd, duration+0.5)

            -- Spawn 3D world text labels (BillboardGui on anchored parts across the map)
            local spawnedParts = {}
            local spawnTextConn; local textTimer = 0; local textSpawned = 0

            spawnTextConn = RunService.Heartbeat:Connect(function(sdt)
                textTimer += sdt
                if textTimer >= 1 and textSpawned < totalTexts then
                    textTimer = 0
                    local batch = math.min(5 * textMult, totalTexts - textSpawned)
                    for _ = 1, batch do
                        textSpawned += 1
                        -- Place text across the whole map area
                        local radius = getMapRadius(GS.Round)
                        local rx = math.random(-radius, radius)
                        local rz = math.random(-radius, radius)
                        local ry = MAP_Y + math.random(-8, 30)

                        local anchor = Instance.new("Part", MAP_FOLDER)
                        anchor.Size = Vector3.new(0.1, 0.1, 0.1)
                        anchor.Position = Vector3.new(rx, ry, rz)
                        anchor.Anchored = true; anchor.CanCollide = false; anchor.Transparency = 1
                        table.insert(spawnedParts, anchor)

                        local bb = Instance.new("BillboardGui", anchor)
                        bb.Size = UDim2.new(0, 160, 0, 50)
                        bb.AlwaysOnTop = false
                        bb.LightInfluence = 0

                        local tl = Instance.new("TextLabel", bb)
                        tl.Size = UDim2.new(1, 0, 1, 0)
                        tl.BackgroundTransparency = 1
                        tl.TextColor3 = Color3.fromRGB(255, 30, 30)
                        tl.TextScaled = true
                        tl.Font = Enum.Font.GothamBold
                        tl.Text = japaneseTexts[math.random(1, #japaneseTexts)]
                        tl.TextTransparency = 0
                        -- Fade out after a couple seconds
                        TweenService:Create(tl, TweenInfo.new(duration * 0.6), {TextTransparency = 1}):Play()
                    end
                end
            end)

            -- Airborne kill beam
            local airborneTimer = 0
            local artPlatStripped = false
            local secondChanceActive = false
            local warnLabel = nil
            local airborneSnd = nil

            local airConn; airConn = RunService.Heartbeat:Connect(function(adt)
                local hrp = getHRP(); local hum = getHum()
                if not hrp or not hum then return end
                local st = hum:GetState()
                local isAirborne = (st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping)

                -- Strip artificial platform
                if isAirborne and GS.Upgrades.ArtificialPlatform and not artPlatStripped then
                    artPlatStripped = true
                    GS.Upgrades.ArtificialPlatform = false
                    local noCheat = Instance.new("TextLabel", GUI)
                    noCheat.Size = UDim2.new(0.8,0,0,44); noCheat.Position = UDim2.new(0.1,0,0.8,0)
                    noCheat.BackgroundTransparency = 1; noCheat.TextColor3 = Color3.fromRGB(255,50,50)
                    noCheat.TextScaled = true; noCheat.Font = Enum.Font.GothamBold
                    noCheat.Text = "不正行為はありません。"; noCheat.ZIndex = 20
                    TweenService:Create(noCheat, TweenInfo.new(3), {TextTransparency=1}):Play()
                    Debris:AddItem(noCheat, 3.5)
                    secondChanceActive = true
                end

                if isAirborne then
                    airborneTimer += adt
                    -- Start airborne sound on first frame airborne
                    if airborneSnd == nil then
                        airborneSnd = Instance.new("Sound", workspace)
                        airborneSnd.SoundId = "rbxassetid://"..SFX.MementoAirborne
                        airborneSnd.Volume = 1.2; airborneSnd.Looped = true
                        airborneSnd.PlaybackSpeed = 0.5; airborneSnd:Play()
                    end
                    -- Pitch and speed ramp from 0.5 to 2.0 over the airTimeLimit window
                    local limit = secondChanceActive and (airTimeLimit + 3) or airTimeLimit
                    local frac = math.min(airborneTimer / limit, 1)
                    airborneSnd.PlaybackSpeed = 0.5 + frac * 1.5
                    if warnLabel == nil then
                        warnLabel = Instance.new("TextLabel", GUI)
                        warnLabel.Size = UDim2.new(0.5,0,0,38); warnLabel.Position = UDim2.new(0.25,0,0.88,0)
                        warnLabel.BackgroundTransparency = 1; warnLabel.TextColor3 = Color3.fromRGB(255,80,0)
                        warnLabel.TextScaled = true; warnLabel.Font = Enum.Font.GothamBold
                        warnLabel.Text = "LAND NOW!"; warnLabel.ZIndex = 18
                    end
                    if airborneTimer >= limit then
                        if airborneSnd then airborneSnd:Stop(); airborneSnd:Destroy(); airborneSnd=nil end
                        if warnLabel then warnLabel:Destroy(); warnLabel = nil end
                        airConn:Disconnect()
                        -- Giant beam: up AND down
                        local bp = hrp.Position
                        local theta = math.random() * math.pi * 2
                        local beamH = 600
                        local bW = 24
                        -- Up beam
                        local bUp = Instance.new("Part", MAP_FOLDER)
                        bUp.Size = Vector3.new(bW, beamH, bW)
                        bUp.Position = bp + Vector3.new(0, beamH/2, 0)
                        bUp.Anchored=true; bUp.CanCollide=false
                        bUp.Material=Enum.Material.Neon; bUp.Color=Color3.fromRGB(0,0,0)
                        local bSelU=Instance.new("SelectionBox",bUp); bSelU.Adornee=bUp
                        bSelU.Color3=Color3.fromRGB(255,0,0); bSelU.LineThickness=0.12; bSelU.SurfaceTransparency=0.82
                        -- Down beam
                        local bDn = Instance.new("Part", MAP_FOLDER)
                        bDn.Size = Vector3.new(bW, beamH, bW)
                        bDn.Position = bp - Vector3.new(0, beamH/2, 0)
                        bDn.Anchored=true; bDn.CanCollide=false
                        bDn.Material=Enum.Material.Neon; bDn.Color=Color3.fromRGB(0,0,0)
                        local bSelD=Instance.new("SelectionBox",bDn); bSelD.Adornee=bDn
                        bSelD.Color3=Color3.fromRGB(255,0,0); bSelD.LineThickness=0.12; bSelD.SurfaceTransparency=0.82
                        shakeCamera(5, 0.6)
                        if hum.Health > 0 then hum.Health = 0 end
                        TweenService:Create(bUp,TweenInfo.new(0.8),{Transparency=1}):Play(); Debris:AddItem(bUp,0.9)
                        TweenService:Create(bDn,TweenInfo.new(0.8),{Transparency=1}):Play(); Debris:AddItem(bDn,0.9)
                    end
                else
                    airborneTimer = 0
                    if airborneSnd then airborneSnd:Stop(); airborneSnd:Destroy(); airborneSnd=nil end
                    if warnLabel then warnLabel:Destroy(); warnLabel = nil end
                end
            end)

            -- Event duration
            task.wait(duration)
            spawnTextConn:Disconnect(); airConn:Disconnect()
            if warnLabel then warnLabel:Destroy() end
            if airborneSnd then airborneSnd:Stop(); airborneSnd:Destroy(); airborneSnd=nil end
            if ambSnd and ambSnd.Parent then ambSnd:Stop(); ambSnd:Destroy() end

            -- Clean up text parts
            for _, p in ipairs(spawnedParts) do if p and p.Parent then p:Destroy() end end

            -- Restore fog
            Lighting.FogColor = oldFogColor; Lighting.FogEnd = oldFogEnd; Lighting.FogStart = oldFogStart

            -- Re-enable artificial platform if it was stripped
            if artPlatStripped then GS.Upgrades.ArtificialPlatform = true end

            eventActive = false
        end)
    end)
    table.insert(GS.EntityConns, conn)
    print("[Devoid] Memento Mori spawned")
end

-- FLESH
local function spawnFlesh(def, platforms)
    local active = false

    local conn = RunService.Heartbeat:Connect(function(dt)
        if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then return end
        if active then return end
        active = true

        task.spawn(function()
            while GS.Phase~="DEAD" and GS.Phase~="LOBBY" do
                local beamInterval = GS.IsShatter and def.ShatterBeamInterval or def.BeamInterval
                local warnTime     = GS.IsShatter and def.ShatterWarnTime     or def.WarnTime
                local trainSpeed   = GS.IsShatter and def.ShatterTrainSpeed   or def.TrainSpeed
                local turnSpeed    = GS.IsShatter and def.ShatterTurnSpeed    or def.TurnSpeed
                local cartCount    = def.CartCount
                local cartLen      = def.TrainLength

                local hrp = getHRP(); if not hrp then task.wait(1); continue end

                -- Random direction for beam (always horizontal for normal, can be any angle)
                local ang = math.random() * math.pi * 2
                local dir = Vector3.new(math.cos(ang), 0, math.sin(ang)).Unit

                -- Transparent warning beam centered on player
                local BEAM_LENGTH = 600
                local warnBeam = Instance.new("Part", MAP_FOLDER)
                warnBeam.Name = "FleshBeam"
                warnBeam.Size = Vector3.new(cartLen * 1.2, cartLen * 1.2, BEAM_LENGTH)
                warnBeam.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dir)
                warnBeam.Anchored = true; warnBeam.CanCollide = false
                warnBeam.Material = Enum.Material.Neon
                warnBeam.Color = Color3.fromRGB(200, 0, 0)
                warnBeam.Transparency = 0.78

                -- Pulse the warning beam
                task.spawn(function()
                    for _ = 1, math.floor(warnTime/0.3) do
                        if not warnBeam.Parent then return end
                        TweenService:Create(warnBeam,TweenInfo.new(0.15),{Transparency=0.55}):Play(); task.wait(0.15)
                        TweenService:Create(warnBeam,TweenInfo.new(0.15),{Transparency=0.82}):Play(); task.wait(0.15)
                    end
                end)

                task.wait(warnTime)
                if warnBeam.Parent then warnBeam:Destroy() end
                if GS.Phase=="DEAD" or GS.Phase=="LOBBY" then break end

                -- Snapshot player position for spawn origin
                local hrp2 = getHRP(); if not hrp2 then task.wait(1); continue end
                local origin = hrp2.Position
                -- Spawn 100 studs behind player along the beam direction
                local spawnOffset = -dir * 100

                -- Build Flesh train model
                local trainModel = Instance.new("Model", ENTITY_FOLDER); trainModel.Name = "FleshTrain"

                local CART_GAP = cartLen + 2
                local carts = {}

                -- Flesh color
                local fleshColors = {
                    Color3.fromRGB(200,100,80),
                    Color3.fromRGB(210,90,70),
                    Color3.fromRGB(190,110,90),
                }

                for c = 1, cartCount do
                    local cartPos = origin + spawnOffset - dir * (c-1) * CART_GAP

                    local cart = Instance.new("Part", trainModel)
                    cart.Name = "Cart"..c
                    cart.Size = Vector3.new(cartLen, cartLen*0.9, cartLen)
                    cart.Position = cartPos + Vector3.new(0, 2, 0)
                    cart.Anchored = true; cart.CanCollide = false
                    cart.Material = Enum.Material.SmoothPlastic
                    cart.Color = fleshColors[math.random(1,#fleshColors)]

                    -- Vein-like neon streaks
                    local vein = Instance.new("Part", trainModel)
                    vein.Size = Vector3.new(cartLen*0.12, cartLen*0.8, cartLen)
                    vein.Position = cartPos + Vector3.new(math.random(-4,4), 2, 0)
                    vein.Anchored = true; vein.CanCollide = false
                    vein.Material = Enum.Material.Neon; vein.Color = Color3.fromRGB(255,40,60)
                    vein.Transparency = 0.3

                    -- Lead cart gets a mouth (front face)
                    if c == 1 then
                        local mouth = Instance.new("Part", trainModel)
                        mouth.Size = Vector3.new(cartLen*0.65, cartLen*0.3, 1)
                        mouth.CFrame = CFrame.new(cartPos + Vector3.new(0,1.5,-(cartLen/2+0.6)),
                                                   cartPos + Vector3.new(0,1.5,-(cartLen/2+1.6)))
                        mouth.Anchored = true; mouth.CanCollide = false
                        mouth.Material = Enum.Material.Neon; mouth.Color = Color3.fromRGB(0,0,0)

                        -- Teeth (white nubs)
                        for t=1,5 do
                            local tooth = Instance.new("Part", trainModel)
                            tooth.Size = Vector3.new(1.2, 1.8, 1)
                            tooth.Position = cartPos + Vector3.new(-cartLen*0.25 + (t-1)*cartLen*0.13, 1.2, -(cartLen/2+0.6))
                            tooth.Anchored=true; tooth.CanCollide=false
                            tooth.Material=Enum.Material.SmoothPlastic; tooth.Color=Color3.fromRGB(240,235,220)
                        end
                    end

                    -- Shatter: all carts get eyes
                    if GS.IsShatter or c==1 then
                        for _,ex in ipairs({-cartLen*0.18, cartLen*0.18}) do
                            local eye=Instance.new("Part",trainModel)
                            eye.Shape=Enum.PartType.Ball; eye.Size=Vector3.new(2.2,2.2,2.2)
                            eye.Position=cartPos+Vector3.new(ex,cartLen*0.3,-(cartLen/2+0.8))
                            eye.Anchored=true; eye.CanCollide=false
                            eye.Material=Enum.Material.Neon; eye.Color=Color3.fromRGB(255,255,0)
                        end
                    end

                    table.insert(carts, {part=cart, offset=-(c-1)*CART_GAP})
                end

                -- Sound on a moving anchor part
                local sndAnchor = Instance.new("Part", MAP_FOLDER)
                sndAnchor.Size = Vector3.new(0.1,0.1,0.1); sndAnchor.Transparency=1
                sndAnchor.Anchored=true; sndAnchor.CanCollide=false
                sndAnchor.Position = origin + spawnOffset
                local snd = Instance.new("Sound", sndAnchor)
                snd.SoundId = "rbxassetid://"..SFX.FleshTrain
                snd.Volume = 2.5; snd.Looped = true; snd.RollOffMaxDistance = 50
                snd:Play()

                table.insert(GS.Entities, trainModel)

                -- Train runs along `dir` from spawn, slowly steering toward player
                -- `trainDir` is the current heading (unit Vector3, Y=0)
                local trainPos = origin + spawnOffset
                local trainDir = dir  -- initial heading = beam direction
                local elapsed = 0
                local destroyed = false

                local moveConn; moveConn = RunService.Heartbeat:Connect(function(mdt)
                    if not trainModel.Parent or destroyed then
                        if moveConn then pcall(function() moveConn:Disconnect() end) end
                        if snd and snd.Parent then snd:Stop(); snd:Destroy() end
                        if sndAnchor and sndAnchor.Parent then sndAnchor:Destroy() end
                        return
                    end
                    elapsed += mdt

                    -- Steer toward player (slow turn)
                    local effectiveTurn = (GS.Upgrades.Railway and 0) or turnSpeed
                    if effectiveTurn > 0 then
                        local hrp3 = getHRP()
                        if hrp3 and GS.Phase ~= "DEAD" then
                            local toPlayer = hrp3.Position - trainPos
                            local toPlayerFlat = Vector3.new(toPlayer.X, 0, toPlayer.Z)
                            if toPlayerFlat.Magnitude > 1 then
                                local target = toPlayerFlat.Unit
                                -- Lerp current direction toward target
                                local lerpFrac = math.min(effectiveTurn * mdt, 1)
                                local newDir = (trainDir + target * lerpFrac)
                                if newDir.Magnitude > 0.001 then
                                    trainDir = newDir.Unit
                                end
                            end
                        end
                    end

                    -- Move forward — keep Y locked at MAP_Y level so it doesn't follow player vertically
                    trainPos = Vector3.new(
                        trainPos.X + trainDir.X * trainSpeed * mdt,
                        MAP_Y + 3,  -- fixed height, never follows player Y
                        trainPos.Z + trainDir.Z * trainSpeed * mdt
                    )

                    -- Update sound anchor position
                    if sndAnchor and sndAnchor.Parent then sndAnchor.Position = trainPos end

                    -- Position each cart along the train axis
                    for ci, cartData in ipairs(carts) do
                        if cartData.part.Parent then
                            local cartPos = trainPos + trainDir * cartData.offset
                            cartPos = Vector3.new(cartPos.X, MAP_Y+3, cartPos.Z)
                            cartData.part.CFrame = CFrame.new(cartPos, cartPos + Vector3.new(trainDir.X,0,trainDir.Z))
                        end
                    end

                    -- Sync decorative parts (veins, eyes, teeth, mouth) to their cart
                    -- We stored a "relCF" on first frame per part; just update each frame
                    for _, p in ipairs(trainModel:GetChildren()) do
                        if p:IsA("BasePart") and p.Name:sub(1,4)~="Cart" then
                            local nearCart = carts[1]; local minD = 9e9
                            for _,cd in ipairs(carts) do
                                local d=(cd.part.Position-p.Position).Magnitude
                                if d<minD then minD=d; nearCart=cd end
                            end
                            if nearCart and nearCart.part.Parent then
                                local rel = p:GetAttribute("RelCF")
                                if not rel then
                                    -- First frame: store relative CFrame as numbers
                                    local relCF = nearCart.part.CFrame:ToObjectSpace(p.CFrame)
                                    p:SetAttribute("RelCF_PX", relCF.Position.X)
                                    p:SetAttribute("RelCF_PY", relCF.Position.Y)
                                    p:SetAttribute("RelCF_PZ", relCF.Position.Z)
                                    p:SetAttribute("RelCF", true)
                                end
                                local rx = p:GetAttribute("RelCF_PX") or 0
                                local ry = p:GetAttribute("RelCF_PY") or 0
                                local rz = p:GetAttribute("RelCF_PZ") or 0
                                p.CFrame = nearCart.part.CFrame * CFrame.new(rx, ry, rz)
                            end
                        end
                    end

                    -- Update sound position
                    if snd and snd.Parent then snd.Parent.Position = trainPos end

                    -- Collision check
                    local hrp4 = getHRP()
                    if hrp4 then
                        for _,cd in ipairs(carts) do
                            if cd.part.Parent and (hrp4.Position-cd.part.Position).Magnitude < cartLen*0.55 then
                                playSound(SFX.FleshCrash, 2, cd.part.Position)
                                local hum=getHum(); if hum and hum.Health>0 then hum.Health=0 end
                            end
                        end
                    end

                    -- Destroy after traveling 200 studs from spawn origin
                    if (trainPos - origin).Magnitude > 200 then
                        destroyed = true
                        if moveConn then pcall(function() moveConn:Disconnect() end) end
                        if snd and snd.Parent then snd:Stop(); snd:Destroy() end
                        if sndAnchor and sndAnchor.Parent then sndAnchor:Destroy() end
                        for _,p in ipairs(trainModel:GetChildren()) do
                            if p:IsA("BasePart") then
                                TweenService:Create(p,TweenInfo.new(0.5),{Transparency=1}):Play()
                            end
                        end
                        Debris:AddItem(trainModel, 0.6)
                        for i,e in ipairs(GS.Entities) do if e==trainModel then table.remove(GS.Entities,i);break end end
                    end
                end)
                table.insert(GS.EntityConns, moveConn)

                -- Wait for train to clear then restart cycle
                task.wait(beamInterval + warnTime + 3)
            end
            active=false
        end)
    end)
    table.insert(GS.EntityConns, conn)
    print("[Devoid] Flesh spawned")
end

-- Dispatch fatal entities (assigns to forward-declared upvalue)
spawnFatalEntities = function(platforms)
    for _,def in ipairs(GS.FatalPickedEntities) do
        if     def.AI=="Guardian"    then spawnGuardian(def, platforms)
        elseif def.AI=="MementoMori" then spawnMementoMori(def, platforms)
        elseif def.AI=="Flesh"       then spawnFlesh(def, platforms)
        end
    end
end

-- ============================================================
-- CMD: /wormhole and /guardian (one-shot)
-- ============================================================
local function cmdSpawnWormhole()
    local def=nil; for _,e in ipairs(EntityRegistry) do if e.AI=="Wormhole" then def=e;break end end
    if not def or #GS.MapPlatforms==0 then return end
    spawnWormhole(def, GS.MapPlatforms)
end

local function cmdSpawnFlesh()
    local def=nil; for _,e in ipairs(FatalEntityRegistry) do if e.AI=="Flesh" then def=e;break end end
    if not def then return end
    local immDef={}; for k,v in pairs(def) do immDef[k]=v end
    immDef.BeamInterval=0; immDef.ShatterBeamInterval=0
    task.spawn(function() spawnFlesh(immDef, GS.MapPlatforms) end)
end

local function cmdSpawnGuardian()
    local def=nil; for _,e in ipairs(FatalEntityRegistry) do if e.AI=="Guardian" then def=e;break end end
    if not def then return end
    -- Override with zero interval so it fires on the very first tick
    local immDef = {}; for k,v in pairs(def) do immDef[k]=v end
    immDef.MinInterval=0; immDef.MaxInterval=0
    task.spawn(function() spawnGuardian(immDef, GS.MapPlatforms) end)
end

local function cmdSpawnMementoMori()
    local def=nil; for _,e in ipairs(FatalEntityRegistry) do if e.AI=="MementoMori" then def=e;break end end
    if not def then return end
    local immDef = {}; for k,v in pairs(def) do immDef[k]=v end
    immDef.MinInterval=0; immDef.MaxInterval=0
    task.spawn(function() spawnMementoMori(immDef, GS.MapPlatforms) end)
end

local function parseCmd(msg)
    local parts={}
    for w in msg:gmatch("%S+") do table.insert(parts,w) end
    local cmd=(parts[1] or ""):lower()
    if     cmd=="/skip"          then skipRound(parts[2])
    elseif cmd=="/shatter"       then shatterNow()
    elseif cmd=="/give"          then giveCosmicCommand(parts[2])
    elseif cmd=="/follower"      then cmdSpawnFollower()
    elseif cmd=="/seed"          then cmdSpawnSeed()
    elseif cmd=="/target"        then task.spawn(cmdSpawnTarget)
    elseif cmd=="/helloworld"    then cmdSpawnHelloworld()
    elseif cmd=="/camera"        then cmdSpawnCamera()
    elseif cmd=="/keeper"        then cmdSpawnKeeper()
    elseif cmd=="/distortion"    then cmdSpawnDistortion()
    elseif cmd=="/malware"       then cmdSpawnMalware()
    elseif cmd=="/hookeddoll"    then cmdSpawnHookedDoll()
    elseif cmd=="/greed"         then task.spawn(cmdSpawnGreed)
    elseif cmd=="/crescendo"     then task.spawn(cmdSpawnCrescendo)
    elseif cmd=="/wormhole"      then cmdSpawnWormhole()
    elseif cmd=="/guardian"      then task.spawn(cmdSpawnGuardian)
    elseif cmd=="/mementomori"   then task.spawn(cmdSpawnMementoMori)
    elseif cmd=="/flesh"         then task.spawn(cmdSpawnFlesh)
    elseif cmd=="/starlight"     then
        local def=nil; for _,e in ipairs(EntityRegistry) do if e.AI=="Starlight" then def=e;break end end
        if def then task.spawn(function() spawnStarlight(def,GS.MapPlatforms) end) end
    end
end

player.Chatted:Connect(function(msg) parseCmd(msg) end)
pcall(function()
    local TCS=game:GetService("TextChatService")
    if TCS and TCS.TextChannels then
        local ch=TCS.TextChannels:FindFirstChild("RBXGeneral")
        if ch then
            ch.SaidMessageChanged:Connect(function(m)
                if m and m.Text then parseCmd(m.Text) end
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
print("║  DEVOID v12 — loaded                ║")
print("║  Entities : "..#EntityRegistry.."                   ║")
print("║  Fatal    : "..#FatalEntityRegistry.."                    ║")
print("║  Upgrades : "..#UpgradeRegistry.."                    ║")
print("║  /skip /shatter /give /guardian     ║")
print("║  /mementomori /wormhole /crescendo  ║")
print("╚════════════════════════════════════╝")
