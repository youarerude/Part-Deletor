-- ╔══════════════════════════════════════════════════════════════════╗
-- ║           SORCHESUS COMPANY  —  3D EDITION                      ║
-- ║   Fanmade Lobotomy Corporation  |  3D Facility Style            ║
-- ║   Inspired by Tuantu Lobotomization Branches                    ║
-- ║   Game Script  |  Run in Codex Executor                         ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ══════════════════════ SERVICES ══════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris           = game:GetService("Debris")
local SoundService     = game:GetService("SoundService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

-- ══════════════════════ 3D WORLD CONSTANTS ══════════════════════
local ROOM_W   = 24
local ROOM_D   = 20
local ROOM_H   = 11
local CORR_W   = 10
local WALL_T   = 1.2
local ROOM_GAP = 4
local FLOOR_Y  = 0
local CORR_LEN = 320
local HQ_OFFSET = -CORR_LEN/2 - 22

-- ══════════════════════ COLORS ══════════════════════
local C = {
    Floor    = Color3.fromRGB(24,  24,  38 ),
    Wall     = Color3.fromRGB(14,  14,  24 ),
    Ceiling  = Color3.fromRGB(18,  18,  30 ),
    Corridor = Color3.fromRGB(30,  30,  50 ),
    HQ       = Color3.fromRGB(40,  40,  72 ),
    NeonBlue = Color3.fromRGB(0,   110, 255),
    NeonWht  = Color3.fromRGB(180, 210, 255),
    NeonGold = Color3.fromRGB(255, 200, 0  ),
    NeonRed  = Color3.fromRGB(255, 30,  30 ),
    Worker   = Color3.fromRGB(60,  140, 255),
    Guard    = Color3.fromRGB(50,  200, 100),
    Agent    = Color3.fromRGB(200, 200, 200),
    Jugg     = Color3.fromRGB(255, 140, 0  ),
    Cmdr     = Color3.fromRGB(255, 50,  50 ),
    Raider   = Color3.fromRGB(255, 200, 0  ),
}
local DangerColors = {
    ["X"]    = Color3.fromRGB(80,  160, 255),
    ["XI"]   = Color3.fromRGB(50,  220, 90 ),
    ["XII"]  = Color3.fromRGB(230, 180, 0  ),
    ["XIII"] = Color3.fromRGB(230, 80,  0  ),
    ["XIV"]  = Color3.fromRGB(190, 0,   230),
}

-- ══════════════════════ GAME DATA ══════════════════════
local Quotas = {750,1000,2500,5000,9000,17500,30000,55555,83000,100000}

local RaidDatabase = {
    Troposphere = {
        {name="Green",  quote="They hunger for what they've lost",  lostQuote="Join Us",
         color=Color3.fromRGB(0,255,0),
         anomalies={{name="Weakling Zombie",count=10,hp=250,dmg=35},{name="Normal Zombie",count=3,hp=750,dmg=75}}},
        {name="Violet", quote="The ritual has only just begun",     lostQuote="The spell is cast",
         color=Color3.fromRGB(148,0,211),
         anomalies={{name="Black Magicians",count=5,hp=175,dmg=100},{name="Shadow Stalker",count=10,hp=245,dmg=50}}},
        {name="Red",    quote="The perfect Food",                   lostQuote="Congratulations",
         color=Color3.fromRGB(255,0,0),
         anomalies={{name="Meat Fluid",count=7,hp=200,dmg=80},{name="Smiling Snails",count=8,hp=125,dmg=75}}},
        {name="Blue",   quote="The tide is rising",                 lostQuote="The surface fades away",
         color=Color3.fromRGB(0,0,255),
         anomalies={{name="Jade Koi Fish",count=5,hp=175,dmg=50},{name="Monster Shark",count=5,hp=210,dmg=80}}},
        {name="Orange", quote="A single spark ignites",             lostQuote="Smoke rises from your defeat",
         color=Color3.fromRGB(255,165,0),
         anomalies={{name="Fire Golem",count=7,hp=150,dmg=40},{name="Blazer",count=5,hp=200,dmg=65}}},
    },
    Stratosphere={}, Mesosphere={}, Thermosphere={}, Exosphere={}
}

local FateEffects = {
    {name="The Curse Of Sloth",       type="debuff",employee="Worker",
     effect=function(e) e.SpeedMultiplier=(e.SpeedMultiplier or 1)*0.5 end,chance=85},
    {name="The Curse Of Weakness",    type="debuff",employee="Guard",
     effect=function(e) e.MaxHP=e.MaxHP-100; e.HP=math.min(e.HP,e.MaxHP) end,chance=85},
    {name="The Bless of Motivation",  type="buff",  employee="Worker",
     effect=function(e) e.SpeedMultiplier=(e.SpeedMultiplier or 1)*2 end,chance=70},
    {name="The Bless of Strength",    type="buff",  employee="Guard",
     effect=function(e) e.Damage=e.Damage*2;e.MaxHP=e.MaxHP*2;e.HP=e.HP*2 end,chance=67},
    {name="The Curse Of Wraith",      type="debuff",employee="Worker",
     effect=function(e) e.SuccessChance=e.SuccessChance-0.1 end,chance=65},
    {name="The Bless of Charisma",    type="buff",  employee="Worker",
     effect=function(e) e.SuccessChance=e.SuccessChance+0.1 end,chance=65},
    {name="The Curse Of Dull",        type="debuff",employee="Guard",
     effect=function(e) e.Damage=e.Damage-100 end,chance=66},
    {name="The bless of Reborn",      type="buff",  employee="Guard",
     effect=function(e) e.Revive=true end,chance=45},
    {name="The Bless of Confidence",  type="buff",  employee="Worker",
     effect=function(e) e.SuccessChance=e.SuccessChance+0.15;e.SpeedMultiplier=(e.SpeedMultiplier or 1)*2.5 end,chance=50},
    {name="The Curse Of Hopeless",    type="debuff",employee="Guard",
     effect=function(e) e.MaxHP=50;e.HP=50;e.Damage=10 end,chance=10},
    {name="The Curse Of Unfortunate", type="debuff",employee="Worker",
     effect=function(e) e.SpeedMultiplier=(e.SpeedMultiplier or 1)*0.2;e.SuccessChance=e.SuccessChance-0.5 end,chance=15},
    {name="The Bless of Empowerment", type="buff",  employee="Guard",
     effect=function(e) e.Damage=e.Damage*7;e.MaxHP=e.MaxHP*5;e.HP=e.HP*5 end,chance=5},
    {name="The Bless of the Umbra",   type="debuff",employee="Worker",
     effect=function(e) e.SpeedMultiplier=(e.SpeedMultiplier or 1)*0.5 end,chance=7},
}

local GameData = {
    Crucible=100,OwnedAnomalies={},WhiteTrainActive=false,TrainTimer=0,
    CurrentDocuments={},CosmicShardCoreHealth=15700,MaxCoreHealth=15700,
    BreachedAnomalies={},
    WorkerNames={"Michael","Christina","Tenna","Ethan","Andy","Joe","Richard","Kaleb","Brian"},
    GuardNames={"Peter","Rick","Kyle","Jayden","Nolan","Steven","Spencer"},
    OwnedWorkers={},OwnedGuards={},OuterGuards={},
    TerminatorAgents={},TerminatorActive=false,
    LastGlobalBreachTime=0,
    OwnedMXWeapons={},OwnedMXArmors={},
    CurrentDay=1,DailyCrucible=0,
    AnomaliesAcceptedToday=0,DocumentsPurchasedToday=false,
    TotalBreaches=0,WorkersDied=0,GuardsDied=0,
    CurrentRaid=nil,RaidEntities={},FateUsedToday=false,
    SelectedDocument=nil,
}

-- ══════════════════════ ANOMALY DATABASE ══════════════════════
local AnomalyDatabase = {
    ["Crying Eyeball"]={
        Description="Sinful Tears, Sinful Deeds.",DangerClass="X",BaseMood=50,
        WorkResults={Knowledge={Success=0.6,Crucible=5,MoodChange=-5},Social={Success=0.95,Crucible=45,MoodChange=15},
            Hunt={Success=0.2,Crucible=1,MoodChange=-20},Passive={Success=0.8,Crucible=30,MoodChange=10}},
        BreachChance=0.005,BreachForm={Name="Blood Cry Out",Health=35,M1Damage=5,Abilities={}},
        Costs={Stat=100,Knowledge=50,Social=75,Hunt=45,Passive=60,BreachForm=250,MXWeapon=350,MXArmor=450},ManagementTips={},
        MXWeapon={Name="Blood Eye Blaster",Damage=25,Chance=0.05,MinLevel=1,MaxLevel=5},
        MXArmor={Name="Armor of Despair",Health=100,Chance=0.02,MinLevel=1,MaxLevel=5},
    },
    ["Whispering Shadow"]={
        Description="It knows your secrets, and it will tell them all.",DangerClass="XI",BaseMood=40,
        WorkResults={Knowledge={Success=0.7,Crucible=15,MoodChange=10},Social={Success=0.4,Crucible=8,MoodChange=-15},
            Hunt={Success=0.3,Crucible=5,MoodChange=-10},Passive={Success=0.5,Crucible=12,MoodChange=5}},
        BreachChance=0.015,BreachForm={Name="Shadow Stalker",Health=80,M1Damage=12,Abilities={"Invisibility","Whisper Madness"}},
        Costs={Stat=300,Knowledge=120,Social=60,Hunt=80,Passive=100,BreachForm=500,MXWeapon=999,MXArmor=1200},ManagementTips={},
        MXWeapon={Name="Secret Whisperer",Damage=120,Chance=0.03,MinLevel=1,MaxLevel=3},
        MXArmor={Name="Mystery Shroud",Health=600,Chance=0.015,MinLevel=1,MaxLevel=3},
    },
    ["Clockwork Heart"]={
        Description="Tick tock, your time is running out.",DangerClass="XI",BaseMood=60,
        WorkResults={Knowledge={Success=0.8,Crucible=20,MoodChange=8},Social={Success=0.6,Crucible=15,MoodChange=-8},
            Hunt={Success=0.5,Crucible=10,MoodChange=-5},Passive={Success=0.7,Crucible=18,MoodChange=12}},
        BreachChance=0.01,BreachForm={Name="Time Ripper",Health=120,M1Damage=15,Abilities={"Time Stop","Rapid Strikes"}},
        Costs={Stat=275,Knowledge=145,Social=120,Hunt=75,Passive=80,BreachForm=510},ManagementTips={},
    },
    ["Smiling Coffin"]={
        Description="Rest eternal, rest with a smile.",DangerClass="XII",BaseMood=30,
        WorkResults={Knowledge={Success=0.5,Crucible=35,MoodChange=-10},Social={Success=0.3,Crucible=20,MoodChange=-25},
            Hunt={Success=0.6,Crucible=40,MoodChange=5},Passive={Success=0.4,Crucible=25,MoodChange=-15}},
        BreachChance=0.025,BreachForm={Name="Grinning Death",Health=200,M1Damage=25,Abilities={"Death Touch","Fear Aura","Coffin Trap"}},
        Costs={Stat=660,Knowledge=150,Social=135,Hunt=166,Passive=121,BreachForm=850},ManagementTips={},
    },
    ["Crimson Orchestra"]={
        Description="A symphony written in blood and screams.",DangerClass="XII",BaseMood=45,
        WorkResults={Knowledge={Success=0.6,Crucible=30,MoodChange=5},Social={Success=0.7,Crucible=42,MoodChange=10},
            Hunt={Success=0.4,Crucible=25,MoodChange=-12},Passive={Success=0.5,Crucible=28,MoodChange=8}},
        BreachChance=0.02,BreachForm={Name="Maestro of Pain",Health=180,M1Damage=20,Abilities={"Sound Wave","Hypnotic Melody","Crescendo Blast"}},
        Costs={Stat=650,Knowledge=175,Social=190,Hunt=145,Passive=160,BreachForm=900},ManagementTips={},
    },
    ["The Void Gazer"]={
        Description="Stare into the abyss, and it stares back with hunger.",DangerClass="XIII",BaseMood=20,
        WorkResults={Knowledge={Success=0.4,Crucible=60,MoodChange=-15},Social={Success=0.2,Crucible=35,MoodChange=-30},
            Hunt={Success=0.5,Crucible=55,MoodChange=10},Passive={Success=0.3,Crucible=40,MoodChange=-20}},
        BreachChance=0.04,BreachForm={Name="Void Avatar",Health=350,M1Damage=35,Abilities={"Void Pull","Reality Tear","Existence Drain","Darkness Burst"}},
        Costs={Stat=980,Knowledge=260,Social=210,Hunt=298,Passive=250,BreachForm=5200},ManagementTips={},
    },
    ["Eternal Flame Child"]={
        Description="Born from ashes, longing for warmth it can never feel.",DangerClass="XIII",BaseMood=35,
        WorkResults={Knowledge={Success=0.5,Crucible=50,MoodChange=-8},Social={Success=0.6,Crucible=65,MoodChange=15},
            Hunt={Success=0.3,Crucible=30,MoodChange=-25},Passive={Success=0.4,Crucible=45,MoodChange=-10}},
        BreachChance=0.035,BreachForm={Name="Inferno Incarnate",Health=280,M1Damage=30,Abilities={"Fire Burst","Immolation","Flame Trail","Phoenix Rebirth"}},
        Costs={Stat=1000,Knowledge=260,Social=285,Hunt=243,Passive=255,BreachForm=5500},ManagementTips={},
    },
    ["Apocalypse Herald"]={
        Description="The end is nigh, and it comes with a twisted smile.",DangerClass="XIV",BaseMood=45,
        WorkResults={Knowledge={Success=0.3,Crucible=100,MoodChange=-20},Social={Success=0.1,Crucible=50,MoodChange=-40},
            Hunt={Success=0.4,Crucible=90,MoodChange=15},Passive={Success=0.2,Crucible=60,MoodChange=-30}},
        BreachChance=0.06,BreachForm={Name="Harbinger of End",Health=600,M1Damage=50,Abilities={"Apocalypse Wave","Reality Collapse","Instant Kill","Summon Minions","World Ender"}},
        Costs={Stat=5700,Knowledge=534,Social=511,Hunt=544,Passive=520,BreachForm=9975},ManagementTips={},
    },
    ["Yin"]={
        Description="The dark side of the equilibrium. The aggressive nature makes it terrifying.",DangerClass="XII",BaseMood=45,
        WorkResults={Knowledge={Success=0.75,Crucible=85,MoodChange=10,MoodRequirement=10},Social={Success=0.2,Crucible=20,MoodChange=-15,MoodRequirement=5},
            Hunt={Success=0.8,Crucible=100,MoodChange=20,MoodRequirement=50},Passive={Success=0.1,Crucible=35,MoodChange=-20,MoodRequirement=5}},
        BreachChance=0.03,BreachForm={Name="The Unbalancer",Health=750,M1Damage=75,Abilities={"Shadow Strike","Dark Vortex"}},
        LinkedAnomaly="Yang",
        Costs={Stat=500,Knowledge=175,Social=120,Hunt=180,Passive=111,BreachForm=900,Management={900,950},MXWeapon=4500,MXArmor=4950},
        ManagementTips={"It hates Yang. Very Much. It Will attack him if he breaches.","If Yin breaches so does Yang."},
        MXWeapon={Name="Chaos Disruptor",Damage=1600,Chance=0.012,MinLevel=4,MaxLevel=5},
        MXArmor={Name="Dark Veil",Health=5800,Chance=0.006,MinLevel=4,MaxLevel=5},
    },
    ["Yang"]={
        Description="The Bright side of the Equilibrium. Its Passive Nature makes it Loved.",DangerClass="X",BaseMood=100,
        NoMoodMeter=true,
        WorkResults={Knowledge={Success=1.0,Crucible=125,MoodChange=0},Social={Success=1.0,Crucible=100,MoodChange=0},
            Hunt={Success=1.0,Crucible=0,MoodChange=0},Passive={Success=1.0,Crucible=200,MoodChange=0}},
        BreachChance=0,BreachOnLinkedBreach=true,
        BreachForm={Name="The Balancer",Health=800,M1Damage=50,Abilities={"Light Heal","Balance Restoration"}},
        LinkedAnomaly="Yin",
        Costs={Stat=750,Knowledge=100,Social=100,Hunt=5,Passive=100,BreachForm=1750,Management={1500,1750,1900},MXWeapon=4500,MXArmor=4950},
        ManagementTips={"It hates Yin very much.","Whenever Yin tries to Breach it will also breach.","It attacks Yin ONLY, not other anomalies."},
        MXWeapon={Name="Peacemaker",Damage=1500,Chance=0.01,MinLevel=4,MaxLevel=5},
        MXArmor={Name="White Divine",Health=5599,Chance=0.005,MinLevel=4,MaxLevel=5},
    },
    ["ERROR"]={
        Description="ERROR 404 FILE NOT FOUND.",DangerClass="XIV",BaseMood=10,HideMoodValue=true,
        WorkResults={Knowledge={Success=0.2,Crucible=3000,MoodChange=-30,MoodRequirement=10,AttackOnFail=true,FailDamage=100},
            Social={Success=0.05,Crucible=5700,MoodChange=-40,MoodRequirement=5,AttackOnFail=true,FailDamage=100},
            Hunt={Success=0.3,Crucible=3500,MoodChange=-25,MoodRequirement=20,AttackOnFail=true,FailDamage=100},
            Passive={Success=0.05,Crucible=4000,MoodChange=-35,MoodRequirement=5,AttackOnFail=true,FailDamage=100}},
        BreachChance=0.08,BreachForm={Name="[ERROR 404 : unexpected error when parsing code]",Health=15000,M1Damage=500,Abilities={"System Corruption","Data Wipe","Reality Glitch","Fatal Exception"}},
        Costs={Stat=7500,Knowledge=500,Social=500,Hunt=500,Passive=500,BreachForm=17500},ManagementTips={},
    },
    ["DISHEVELED MEAT MESS"]={
        Description="LET ME WEAR YOUR SKIN.",DangerClass="XIV",BaseMood=50,
        WorkResults={Knowledge={Success=0.1,Crucible=205,MoodChange=5},Social={Success=0.05,Crucible=150,MoodChange=-10},
            Hunt={Success=0.4,Crucible=350,MoodChange=45},Passive={Success=0.2,Crucible=500,MoodChange=-5}},
        BreachChance=0.06,BreachForm={Name="THE SCRAMBLER",Health=14500,M1Damage=450,Abilities={"Flesh Assimilation","Chaotic Reassembly"}},
        Special="MeatMess",
        Costs={Stat=5300,Knowledge=530,Social=555,Hunt=580,Passive=475,BreachForm=13500,Management={10000},MXWeapon=25000,MXArmor=27500},
        ManagementTips={"Everytime it kills a worker during work, its health increases."},
        MXWeapon={Name="Jealousy",Damage=4500,Chance=0.005,MinLevel=5,MaxLevel=5},
        MXArmor={Name="Wrath",Health=8500,Chance=0.001,MinLevel=5,MaxLevel=5},
    },
    ["Skeleton King"]={
        Description="The one who rules countless Skeletons. Trapped here for decades. Would you join my army?",DangerClass="XIII",BaseMood=30,
        WorkResults={Knowledge={Success=0.6,Crucible=100,MoodChange=5},Social={Success=0.5,Crucible=95,MoodChange=10},
            Hunt={Success=0.6,Crucible=120,MoodChange=30},Passive={Success=0.3,Crucible=70,MoodChange=5}},
        BreachChance=0.035,BreachForm={Name="The Skeleton Monarch",Health=6500,M1Damage=100,Abilities={"Army Summon","Bone Command"}},
        Special="SkeletonKing",
        Costs={Stat=1200,Knowledge=260,Social=250,Hunt=260,Passive=230,BreachForm=5200,Management={7500},MXWeapon=9100,MXArmor=10500},
        ManagementTips={"During Breach, every 30 seconds a guard or worker turns into a skeleton."},
        MXWeapon={Name="Soul Harvester",Damage=4000,Chance=0.005,MinLevel=5,MaxLevel=5},
        MXArmor={Name="Eternal Bones",Health=8000,Chance=0.001,MinLevel=5,MaxLevel=5},
    },
    ["Old Wilted Radio"]={
        Description="This is the recording we must never forget.",DangerClass="XII",BaseMood=50,
        WorkResults={Knowledge={Success=0.5,Crucible=50,MoodChange=-5},Social={Success=0.4,Crucible=65,MoodChange=5},
            Hunt={Success=0.75,Crucible=75,MoodChange=35},Passive={Success=0.2,Crucible=35,MoodChange=-10}},
        BreachChance=0.02,BreachForm={Name="GHz 7500",Health=10,M1Damage=80,Abilities={"Frequency Overload","Signal Distortion"}},
        Special="Radio",
        Costs={Stat=510,Knowledge=140,Social=125,Hunt=163,Passive=105,BreachForm=1100,Enemies=800,Management={1300,1750},MXWeapon=4757,MXArmor=5000},
        ManagementTips={"When breached it will spawn minions attacking the guards.","GHz 7500 is the commander for the Army."},
        EnemyInfo="Enemy Army: kHz 1750, Health: 100, M1 Damage: 10",
        MXWeapon={Name="Ear Ringer",Damage=610,Chance=0.05,MinLevel=3,MaxLevel=5},
        MXArmor={Name="Radio Operator Suit",Health=1200,Chance=0.03,MinLevel=3,MaxLevel=5},
    },
    ["Theres Eyes in the Wall"]={
        Description="STOP STARING AT ME CREEPILY",DangerClass="XII",BaseMood=45,
        WorkResults={Knowledge={Success=0.3,Crucible=50,MoodChange=10},Social={Success=0.4,Crucible=45,MoodChange=5},
            Hunt={Success=0.5,Crucible=75,MoodChange=20},Passive={Success=0.1,Crucible=35,MoodChange=-10}},
        BreachChance=0.02,BreachForm={Name="Spread The Rumors",Health=10,M1Damage=50,Abilities={"Eye Proliferation","Whisper Network"}},
        Special="Eyes",
        Costs={Stat=523,Knowledge=133,Social=144,Hunt=155,Passive=111,BreachForm=1015,Management={1750}},
        ManagementTips={"When breached, every 10 seconds a new eye appears. Each eye has 10 HP."},
    },
    ["Jar of Blood"]={
        Description="This Jar contains all the Grudge in the world.",DangerClass="X",BaseMood=50,
        WorkResults={Knowledge={Success=0.7,Crucible=10,MoodChange=7},Social={Success=0.5,Crucible=27,MoodChange=12},
            Hunt={Success=0.3,Crucible=50,MoodChange=25},Passive={Success=0.5,Crucible=30,MoodChange=5}},
        BreachChance=0,NoBreach=true,Special="JarOfBlood",IsInanimate=true,
        Costs={Stat=125,Knowledge=70,Social=50,Hunt=30,Passive=50,Management={188,200,250}},
        ManagementTips={"Cannot escape. Lower mood = more damage to worker and core."},
    },
    ["Blooming Blood Tree"]={
        Description="Look how beautiful it blooms! The Leaves are Burning through my Skin and i Love it!",DangerClass="XII",BaseMood=75,
        WorkResults={Knowledge={Success=0.5,Crucible=100,MoodChange=5,MoodRequirement=10},Social={Success=0.25,Crucible=235,MoodChange=-5,MoodRequirement=0},
            Hunt={Success=0.67,Crucible=150,MoodChange=10,MoodRequirement=30},Passive={Success=0.1,Crucible=450,MoodChange=-10,MoodRequirement=10}},
        BreachChance=0,NoBreach=true,IsInanimate=true,Special="BloomingBloodTree",
        Costs={Stat=555,Knowledge=189,Social=140,Hunt=140,Passive=135,Management={999,1500}},
        ManagementTips={"After 5 successful works, the worker dies and turns into a flower.","Low mood kills workers."},
    },
    ["Prince of Fame"]={
        Description="In the name of Justice! All evilness will be Punished!",DangerClass="XIII",BaseMood=50,
        WorkResults={Knowledge={Success=0.5,Crucible=300,MoodChange=5,MoodRequirement=5},Social={Success=0.7,Crucible=450,MoodChange=10,MoodRequirement=25},
            Hunt={Success=0.2,Crucible=100,MoodChange=-10,MoodRequirement=5},Passive={Success=0.8,Crucible=400,MoodChange=15,MoodRequirement=15}},
        BreachChance=0.03,BreachForm={Name="The Fame Seeker",Health=1500,M1Damage=275,Abilities={"Justice Strike"}},
        Special="PrinceOfFame",
        Costs={Stat=1205,Knowledge=350,Social=377,Hunt=328,Passive=301,BreachForm=5410,Management={5550,5900,6230},MXWeapon=10500,MXArmor=12300},
        ManagementTips={"Assists in containing other breaches.","No breaches for 10 minutes = mood drains faster.","At 0 mood enters bored mode; at 0 in bored mode, breaches."},
        MXWeapon={Name="The Punisher",Damage=2589,Chance=0.015,MinLevel=4,MaxLevel=5},
        MXArmor={Name="Fame Attraction",Health=5100,Chance=0.01,MinLevel=4,MaxLevel=5},
    },
    ["May the Fate decides"]={
        Description="The scales tip, destiny unfolds. Will fortune smile, or will darkness take hold?",DangerClass="XII",BaseMood=50,
        WorkResults={},BreachChance=0.02,
        BreachForm={Name="Fate Weaver",Health=500,M1Damage=50,Abilities={}},
        Costs={Stat=570,BlessCurse=200,BreachForm=800},
        ManagementTips={"Replaces work buttons with Use button. Use once per day to buff/debuff an employee."},
        Special="FateDecides",
    },
}
-- ══════════════════════ HELPER FUNCTIONS ══════════════════════
local function CI(cls, props)
    local i = Instance.new(cls)
    for k,v in pairs(props) do if k~="Parent" then i[k]=v end end
    i.Parent = props.Parent
    return i
end

local function GetRandomWorkerName() return GameData.WorkerNames[math.random(#GameData.WorkerNames)] end
local function GetRandomGuardName()  return GameData.GuardNames[math.random(#GameData.GuardNames)]   end

local function UpdateCrucible(amount)
    GameData.Crucible = GameData.Crucible + amount
    if amount > 0 then GameData.DailyCrucible = GameData.DailyCrucible + amount end
end

local function getDangerLevel(class)
    return ({["X"]=10,["XI"]=11,["XII"]=12,["XIII"]=13,["XIV"]=14})[class] or 0
end

-- ══════════════════════ 3D WORLD BUILD ══════════════════════
local FacilityFolder = Instance.new("Folder")
FacilityFolder.Name  = "SorchesusCompany3D"
FacilityFolder.Parent = workspace

local NPCFolder = Instance.new("Folder")
NPCFolder.Name   = "SCNPCs"
NPCFolder.Parent = FacilityFolder

-- Basic part factory
local function MP(sz,cf,col,neon,cc,par)
    local p = Instance.new("Part")
    p.Anchored=true; p.CanCollide=(cc~=false)
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p.CastShadow=false
    p.Size=sz; p.CFrame=cf; p.Color=col
    p.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
    p.Parent = par or FacilityFolder
    return p
end

local function NeonStrip(cf,sz,col,par)
    return MP(sz,cf,col,true,false,par or FacilityFolder)
end

-- Build long corridor
local corrCF = CFrame.new(0, FLOOR_Y+ROOM_H/2, 0)
-- Floor
MP(Vector3.new(CORR_LEN,0.6,CORR_W), CFrame.new(0,FLOOR_Y-0.3,0), C.Floor)
-- Ceiling
MP(Vector3.new(CORR_LEN,0.6,CORR_W), CFrame.new(0,FLOOR_Y+ROOM_H+0.3,0), C.Ceiling)
-- Side walls
MP(Vector3.new(CORR_LEN,ROOM_H,WALL_T), CFrame.new(0,FLOOR_Y+ROOM_H/2, CORR_W/2+WALL_T/2), C.Wall)
MP(Vector3.new(CORR_LEN,ROOM_H,WALL_T), CFrame.new(0,FLOOR_Y+ROOM_H/2,-CORR_W/2-WALL_T/2), C.Wall)
-- End caps
MP(Vector3.new(WALL_T,ROOM_H,CORR_W), CFrame.new(-CORR_LEN/2,FLOOR_Y+ROOM_H/2,0), C.Wall)
MP(Vector3.new(WALL_T,ROOM_H,CORR_W), CFrame.new( CORR_LEN/2,FLOOR_Y+ROOM_H/2,0), C.Wall)
-- Neon floor lines
NeonStrip(CFrame.new(0,FLOOR_Y+0.02, CORR_W/2-0.6), Vector3.new(CORR_LEN,0.08,0.35), C.NeonBlue)
NeonStrip(CFrame.new(0,FLOOR_Y+0.02,-CORR_W/2+0.6), Vector3.new(CORR_LEN,0.08,0.35), C.NeonBlue)
-- Neon ceiling strip
NeonStrip(CFrame.new(0,FLOOR_Y+ROOM_H-0.08,0), Vector3.new(CORR_LEN,0.1,0.5), C.NeonWht)
-- Emergency red strips (upper wall edges)
NeonStrip(CFrame.new(0,FLOOR_Y+ROOM_H-0.5, CORR_W/2+WALL_T/2), Vector3.new(CORR_LEN,0.2,0.1), C.NeonRed)
NeonStrip(CFrame.new(0,FLOOR_Y+ROOM_H-0.5,-CORR_W/2-WALL_T/2), Vector3.new(CORR_LEN,0.2,0.1), C.NeonRed)

-- Repeating ceiling lights along corridor
for lx = -CORR_LEN/2+15, CORR_LEN/2-15, 30 do
    NeonStrip(CFrame.new(lx, FLOOR_Y+ROOM_H-0.2, 0), Vector3.new(0.4,0.2,CORR_W-1), C.NeonWht)
end

-- HQ block (left end)
local hqX = HQ_OFFSET
local hqF = Instance.new("Folder"); hqF.Name="HQ"; hqF.Parent=FacilityFolder
MP(Vector3.new(32,0.6,32), CFrame.new(hqX,FLOOR_Y-0.3,0),          C.HQ,    false,true, hqF)
MP(Vector3.new(32,0.6,32), CFrame.new(hqX,FLOOR_Y+ROOM_H+0.3,0),   C.Ceiling,false,true,hqF)
MP(Vector3.new(32,ROOM_H,WALL_T), CFrame.new(hqX,FLOOR_Y+ROOM_H/2, 16), C.Wall,false,true,hqF)
MP(Vector3.new(32,ROOM_H,WALL_T), CFrame.new(hqX,FLOOR_Y+ROOM_H/2,-16), C.Wall,false,true,hqF)
MP(Vector3.new(WALL_T,ROOM_H,32), CFrame.new(hqX-16,FLOOR_Y+ROOM_H/2,0),C.Wall,false,true,hqF)
-- HQ neon decor
NeonStrip(CFrame.new(hqX-15.5,FLOOR_Y+ROOM_H*0.72,0)*CFrame.Angles(0,math.rad(90),0),
    Vector3.new(26,0.25,0.25), Color3.fromRGB(200,40,40), hqF)
NeonStrip(CFrame.new(hqX-15.5,FLOOR_Y+ROOM_H*0.38,0)*CFrame.Angles(0,math.rad(90),0),
    Vector3.new(14,0.18,0.18), C.NeonGold, hqF)
NeonStrip(CFrame.new(hqX,FLOOR_Y+0.02, 15), Vector3.new(30,0.08,0.35), C.NeonBlue, hqF)
NeonStrip(CFrame.new(hqX,FLOOR_Y+0.02,-15), Vector3.new(30,0.08,0.35), C.NeonBlue, hqF)
-- HQ central Cosmic Shard core pillar
local coreBase = MP(Vector3.new(3,0.4,3), CFrame.new(hqX,FLOOR_Y+0.2,0), Color3.fromRGB(30,30,50), false,true,hqF)
local corePillar= MP(Vector3.new(1.5,6,1.5), CFrame.new(hqX,FLOOR_Y+3.2,0), Color3.fromRGB(20,20,40), false,true,hqF)
local coreOrb  = MP(Vector3.new(3,3,3), CFrame.new(hqX,FLOOR_Y+7,0), C.NeonBlue, true,false,hqF)
coreOrb.Name   = "CosmicShard"
local coreGlow = MP(Vector3.new(5,5,5), CFrame.new(hqX,FLOOR_Y+7,0), C.NeonBlue, true,false,hqF)
coreGlow.Transparency = 0.7; coreGlow.Name = "CosmicShardGlow"

-- Animate core orb
spawn(function()
    local t=0
    while coreOrb and coreOrb.Parent do
        t=t+0.03
        local s=1+0.08*math.sin(t)
        coreOrb.Size = Vector3.new(3*s,3*s,3*s)
        coreGlow.Size = Vector3.new(5*s,5*s,5*s)
        local hp = GameData.CosmicShardCoreHealth/GameData.MaxCoreHealth
        local r = math.max(0,1-hp*1.5)
        local g = math.min(1,hp*1.5)
        coreOrb.Color = Color3.new(r*0.5, g*0.3+0.1, 1-r*0.5)
        coreGlow.Color= coreOrb.Color
        wait(0.04)
    end
end)

-- ══════════════════════ ROOM BUILDER ══════════════════════
local roomCount  = 0
local ROOM_START_X = -CORR_LEN/2 + ROOM_W/2 + 8

local function GetNextRoomPos()
    roomCount = roomCount + 1
    local side  = (roomCount % 2 == 1) and 1 or -1
    local slot  = math.ceil(roomCount / 2)
    local x     = ROOM_START_X + (slot-1)*(ROOM_W+ROOM_GAP)
    local z     = side*(CORR_W/2+ROOM_D/2+WALL_T)
    return x, z, side
end

local AllRoom3DData = {}

local function BuildRoom3D(anomalyName)
    local data   = AnomalyDatabase[anomalyName]
    local dCol   = DangerColors[data.DangerClass] or Color3.fromRGB(100,100,160)
    local x, z, side = GetNextRoomPos()
    local fz     = z - side*(ROOM_D/2+WALL_T/2)  -- front wall Z
    local bz     = z + side*(ROOM_D/2+WALL_T/2)  -- back wall Z

    local rFolder = Instance.new("Folder")
    rFolder.Name  = "Room_"..anomalyName:sub(1,12)
    rFolder.Parent= FacilityFolder

    local dimFloor= Color3.new(dCol.R*0.12, dCol.G*0.12, dCol.B*0.12)

    -- Floor / Ceiling
    MP(Vector3.new(ROOM_W,0.6,ROOM_D), CFrame.new(x,FLOOR_Y-0.3,z),        dimFloor,false,true,rFolder)
    MP(Vector3.new(ROOM_W,0.6,ROOM_D), CFrame.new(x,FLOOR_Y+ROOM_H+0.3,z), C.Ceiling,false,true,rFolder)
    -- Back wall
    MP(Vector3.new(ROOM_W,ROOM_H,WALL_T), CFrame.new(x,FLOOR_Y+ROOM_H/2,bz), C.Wall,false,true,rFolder)
    -- Side walls
    MP(Vector3.new(WALL_T,ROOM_H,ROOM_D),CFrame.new(x-ROOM_W/2-WALL_T/2,FLOOR_Y+ROOM_H/2,z),C.Wall,false,true,rFolder)
    MP(Vector3.new(WALL_T,ROOM_H,ROOM_D),CFrame.new(x+ROOM_W/2+WALL_T/2,FLOOR_Y+ROOM_H/2,z),C.Wall,false,true,rFolder)
    -- Front wall (door gap in middle)
    local doorW=6; local doorH=ROOM_H*0.55
    local sideW=(ROOM_W-doorW)/2
    MP(Vector3.new(sideW,ROOM_H,WALL_T),  CFrame.new(x-ROOM_W/2+sideW/2, FLOOR_Y+ROOM_H/2,fz),C.Wall,false,true,rFolder)
    MP(Vector3.new(sideW,ROOM_H,WALL_T),  CFrame.new(x+ROOM_W/2-sideW/2, FLOOR_Y+ROOM_H/2,fz),C.Wall,false,true,rFolder)
    MP(Vector3.new(doorW,ROOM_H-doorH,WALL_T),CFrame.new(x,FLOOR_Y+doorH+(ROOM_H-doorH)/2,fz),C.Wall,false,true,rFolder)

    -- Neon danger strips
    NeonStrip(CFrame.new(x,FLOOR_Y+0.4, bz), Vector3.new(ROOM_W-1,0.1,0.12), dCol, rFolder)
    NeonStrip(CFrame.new(x,FLOOR_Y+ROOM_H-0.5,bz),Vector3.new(ROOM_W-1,0.1,0.12),dCol,rFolder)
    NeonStrip(CFrame.new(x-ROOM_W/2-WALL_T/2,FLOOR_Y+ROOM_H/2,z)*CFrame.Angles(0,math.rad(90),0),Vector3.new(ROOM_D-1,0.1,0.1),dCol,rFolder)
    NeonStrip(CFrame.new(x+ROOM_W/2+WALL_T/2,FLOOR_Y+ROOM_H/2,z)*CFrame.Angles(0,math.rad(90),0),Vector3.new(ROOM_D-1,0.1,0.1),dCol,rFolder)
    -- Door frame glow
    NeonStrip(CFrame.new(x,FLOOR_Y+doorH+0.05,fz),Vector3.new(doorW,0.12,0.12),dCol,rFolder)
    NeonStrip(CFrame.new(x-doorW/2,FLOOR_Y+doorH/2,fz),Vector3.new(0.12,doorH,0.12),dCol,rFolder)
    NeonStrip(CFrame.new(x+doorW/2,FLOOR_Y+doorH/2,fz),Vector3.new(0.12,doorH,0.12),dCol,rFolder)
    -- Floor neon lines inside room
    NeonStrip(CFrame.new(x-ROOM_W/2+1,FLOOR_Y+0.02,z)*CFrame.Angles(0,math.rad(90),0),Vector3.new(ROOM_D-1,0.06,0.18),dCol,rFolder)
    NeonStrip(CFrame.new(x+ROOM_W/2-1,FLOOR_Y+0.02,z)*CFrame.Angles(0,math.rad(90),0),Vector3.new(ROOM_D-1,0.06,0.18),dCol,rFolder)

    -- Mood bar (above door frame on corridor side)
    local moodBarBG = MP(
        Vector3.new(ROOM_W-3,0.45,0.12),
        CFrame.new(x, FLOOR_Y+1.6, fz - side*0.12),
        Color3.fromRGB(35,35,35), false, false, rFolder)
    moodBarBG.Name = "MoodBarBG"
    local moodBarFill = MP(
        Vector3.new(ROOM_W-3,0.45,0.12),
        CFrame.new(x, FLOOR_Y+1.6, fz - side*0.18),
        Color3.fromRGB(50,200,50), true, false, rFolder)
    moodBarFill.Name = "MoodBarFill"

    -- Anomaly containment orb inside room
    local orbCF = CFrame.new(x, FLOOR_Y+3.5, z+side*2.5)
    local orb = MP(Vector3.new(3,3,3), orbCF, dCol, true, false, rFolder)
    orb.Name = "AnomalyOrb"
    local orbGlow = MP(Vector3.new(5,5,5), orbCF, dCol, true, false, rFolder)
    orbGlow.Transparency = 0.72; orbGlow.Name = "OrbGlow"
    -- Containment cage rings
    for ang=0,160,80 do
        local ringCF = orbCF * CFrame.Angles(math.rad(ang),0,0)
        local ring = MP(Vector3.new(4.8,0.18,0.18), ringCF, Color3.fromRGB(60,60,80), false, false, rFolder)
        ring.CanCollide=false
    end

    -- Ceiling light over orb
    NeonStrip(CFrame.new(x,FLOOR_Y+ROOM_H-0.15,z+side*2), Vector3.new(4,0.15,4), dCol, rFolder)

    -- Observation window (side, facing corridor) — just a flat emissive panel
    MP(Vector3.new(8,4,0.3), CFrame.new(x,FLOOR_Y+doorH*0.5+0.5, fz-side*0.5),
        Color3.fromRGB(10,20,40), false, false, rFolder).Transparency = 0.6

    -- Animate orb
    spawn(function()
        local t = math.random()*6
        while orb and orb.Parent do
            t = t + 0.035
            local s = 1 + 0.07*math.sin(t)
            orb.Size     = Vector3.new(3*s,3*s,3*s)
            orbGlow.Size = Vector3.new(5*s,5*s,5*s)
            wait(0.04)
        end
    end)

    local roomData3D = {
        Folder     = rFolder,
        Orb        = orb,
        OrbGlow    = orbGlow,
        MoodFill   = moodBarFill,
        MoodBG     = moodBarBG,
        Position   = Vector3.new(x, FLOOR_Y, z),
        FrontZ     = fz,
        Side       = side,
        DoorX      = x,
        DangerColor= dCol,
    }
    table.insert(AllRoom3DData, roomData3D)
    return roomData3D
end

-- ══════════════════════ NPC FACTORY ══════════════════════
local function MakeNPC(pos, col, label)
    local model = Instance.new("Model"); model.Parent = NPCFolder

    local root = Instance.new("Part")
    root.Size = Vector3.new(1,0.2,1); root.Anchored=true; root.CanCollide=false
    root.Transparency=1; root.CFrame=CFrame.new(pos); root.Parent=model; root.Name="HumanoidRootPart"

    local torso = Instance.new("Part")
    torso.Size = Vector3.new(1.1,1.4,0.6); torso.Color=col
    torso.Anchored=true; torso.CanCollide=false
    torso.Material=Enum.Material.SmoothPlastic
    torso.CFrame = CFrame.new(pos+Vector3.new(0,1.7,0)); torso.Parent=model; torso.Name="Torso"

    local head = Instance.new("Part")
    head.Size=Vector3.new(0.9,0.9,0.9); head.Color=Color3.fromRGB(220,180,140)
    head.Anchored=true; head.CanCollide=false
    head.CFrame=CFrame.new(pos+Vector3.new(0,2.85,0)); head.Parent=model; head.Name="Head"

    local ll = Instance.new("Part"); ll.Size=Vector3.new(0.5,1.2,0.5); ll.Color=Color3.fromRGB(50,50,80)
    ll.Anchored=true; ll.CanCollide=false; ll.CFrame=CFrame.new(pos+Vector3.new(-0.35,0.7,0)); ll.Parent=model
    local rl = Instance.new("Part"); rl.Size=Vector3.new(0.5,1.2,0.5); rl.Color=Color3.fromRGB(50,50,80)
    rl.Anchored=true; rl.CanCollide=false; rl.CFrame=CFrame.new(pos+Vector3.new( 0.35,0.7,0)); rl.Parent=model
    local la = Instance.new("Part"); la.Size=Vector3.new(0.4,1.1,0.4); la.Color=col
    la.Anchored=true; la.CanCollide=false; la.CFrame=CFrame.new(pos+Vector3.new(-0.82,1.65,0)); la.Parent=model
    local ra = Instance.new("Part"); ra.Size=Vector3.new(0.4,1.1,0.4); ra.Color=col
    ra.Anchored=true; ra.CanCollide=false; ra.CFrame=CFrame.new(pos+Vector3.new( 0.82,1.65,0)); ra.Parent=model

    -- Name tag
    local bb = Instance.new("BillboardGui"); bb.Size=UDim2.new(0,120,0,30)
    bb.StudsOffset=Vector3.new(0,2.4,0); bb.AlwaysOnTop=false; bb.Parent=head
    local nl = Instance.new("TextLabel"); nl.Parent=bb; nl.BackgroundTransparency=1
    nl.Size=UDim2.new(1,0,1,0); nl.Text=label
    nl.Font=Enum.Font.GothamBold; nl.TextSize=11
    nl.TextColor3=Color3.new(1,1,1); nl.TextStrokeTransparency=0.3

    -- HP bar billboard
    local hpBB = Instance.new("BillboardGui"); hpBB.Size=UDim2.new(0,90,0,10)
    hpBB.StudsOffset=Vector3.new(0,1.8,0); hpBB.AlwaysOnTop=false; hpBB.Parent=head; hpBB.Name="HPBB"
    local hpBG = Instance.new("Frame"); hpBG.Parent=hpBB
    hpBG.Size=UDim2.new(1,0,1,0); hpBG.BackgroundColor3=Color3.fromRGB(40,40,40); hpBG.BorderSizePixel=0
    local hpFill = Instance.new("Frame"); hpFill.Parent=hpBG; hpFill.Name="Fill"
    hpFill.Size=UDim2.new(1,0,1,0); hpFill.BackgroundColor3=Color3.fromRGB(50,220,80); hpFill.BorderSizePixel=0
    Instance.new("UICorner",hpBG).CornerRadius=UDim.new(1,0)
    Instance.new("UICorner",hpFill).CornerRadius=UDim.new(1,0)

    model.Name = label
    model.PrimaryPart = root

    return {Model=model, Root=root, Torso=torso, Head=head, LL=ll, RL=rl, LA=la, RA=ra, HPFill=hpFill, Label=nl}
end

local function AnimateNPCWalk(npc, startPos, endPos, speed, onDone)
    spawn(function()
        local dist   = (endPos - startPos).Magnitude
        local steps  = math.max(1, math.floor(dist / 0.15))
        local t      = 0
        local legDir = 1
        local armDir = -1
        for s=1,steps do
            if not npc.Root or not npc.Root.Parent then return end
            local alpha  = s/steps
            local newPos = startPos:Lerp(endPos, alpha)
            local lookDir= (endPos-startPos).Unit
            local cf     = CFrame.new(newPos, newPos+lookDir)

            t = t + 0.18
            local legSwing  = math.sin(t)*0.38
            local armSwing  = math.cos(t)*0.28

            npc.Root.CFrame  = cf
            npc.Torso.CFrame = CFrame.new(newPos+Vector3.new(0,1.7,0), newPos+Vector3.new(0,1.7,0)+lookDir)
            npc.Head.CFrame  = CFrame.new(newPos+Vector3.new(0,2.85,0))
            npc.LL.CFrame    = CFrame.new(newPos+Vector3.new(-0.35,0.7,0)) * CFrame.Angles(legSwing,0,0)
            npc.RL.CFrame    = CFrame.new(newPos+Vector3.new( 0.35,0.7,0)) * CFrame.Angles(-legSwing,0,0)
            npc.LA.CFrame    = CFrame.new(newPos+Vector3.new(-0.82,1.65,0)) * CFrame.Angles(armSwing,0,0)
            npc.RA.CFrame    = CFrame.new(newPos+Vector3.new( 0.82,1.65,0)) * CFrame.Angles(-armSwing,0,0)
            wait(speed)
        end
        if onDone then onDone() end
    end)
end

-- NPC patrol along corridor
local function StartNPCPatrol(npcData, col)
    spawn(function()
        local poses = {
            Vector3.new(-CORR_LEN/2+20, FLOOR_Y+1, math.random(-1,1)*1.5),
            Vector3.new(-CORR_LEN/4,    FLOOR_Y+1, math.random(-1,1)*1.5),
            Vector3.new(0,              FLOOR_Y+1, math.random(-1,1)*1.5),
            Vector3.new( CORR_LEN/4,   FLOOR_Y+1, math.random(-1,1)*1.5),
        }
        local idx = 1
        while npcData.Root and npcData.Root.Parent do
            local nxt = poses[idx % #poses + 1]
            local cur = npcData.Root.CFrame.Position
            local done= false
            AnimateNPCWalk(npcData, cur, nxt, 0.035, function() done=true end)
            repeat wait(0.05) until done or not npcData.Root.Parent
            idx = idx + 1
            wait(math.random(1,3))
        end
    end)
end
-- ══════════════════════ NOTIFICATION SYSTEM ══════════════════════
local NotifGui = CI("ScreenGui",{Name="SorchesusNotifs",Parent=playerGui,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local NotifList= CI("Frame",{Parent=NotifGui,BackgroundTransparency=1,
    Size=UDim2.new(0,320,1,0),Position=UDim2.new(1,-330,0,0)})
CI("UIListLayout",{Parent=NotifList,VerticalAlignment=Enum.VerticalAlignment.Bottom,
    HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})

local notifCount=0
local function CreateNotification(msg, bgCol, txCol)
    notifCount=notifCount+1
    bgCol = bgCol or Color3.fromRGB(30,30,45)
    txCol = txCol or Color3.fromRGB(255,255,255)
    local f = CI("Frame",{Parent=NotifList,BackgroundColor3=bgCol,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=0.15,LayoutOrder=-notifCount})
    CI("UICorner",{Parent=f,CornerRadius=UDim.new(0,7)})
    CI("UIStroke",{Parent=f,Color=Color3.new(1,1,1),Thickness=0.6,Transparency=0.8})
    CI("TextLabel",{Parent=f,BackgroundTransparency=1,Size=UDim2.new(1,-12,0,0),
        Position=UDim2.new(0,8,0,6),AutomaticSize=Enum.AutomaticSize.Y,
        Text=msg,Font=Enum.Font.Gotham,TextSize=13,
        TextColor3=txCol,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left})
    f.Size=UDim2.new(1,0,0,38)
    TweenService:Create(f,TweenInfo.new(0.25),{BackgroundTransparency=0.12}):Play()
    Debris:AddItem(f,5)
    spawn(function()
        wait(4.2)
        if f and f.Parent then
            TweenService:Create(f,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
            TweenService:Create(f,TweenInfo.new(0.4),{Size=UDim2.new(1,0,0,0)}):Play()
        end
    end)
end

-- ══════════════════════ MAIN GUI ══════════════════════
local MainGui = CI("ScreenGui",{Name="SorchesusCompany3DGUI",Parent=playerGui,
    ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})

-- Top bar (scrollable)
local TopBar = CI("ScrollingFrame",{Name="TopBar",Parent=MainGui,
    BackgroundColor3=Color3.fromRGB(10,10,18),BorderSizePixel=0,
    Size=UDim2.new(1,0,0,52),CanvasSize=UDim2.new(0,1700,0,52),
    ScrollingDirection=Enum.ScrollingDirection.X,ScrollBarThickness=4,
    ScrollBarImageColor3=Color3.fromRGB(0,80,200)})
CI("UIStroke",{Parent=TopBar,Color=Color3.fromRGB(0,80,200),Thickness=1})
CI("UIListLayout",{Parent=TopBar,FillDirection=Enum.FillDirection.Horizontal,
    VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,18),
    SortOrder=Enum.SortOrder.LayoutOrder})
CI("UIPadding",{Parent=TopBar,PaddingLeft=UDim.new(0,12)})

local function TopBtn(txt, order)
    local b = CI("TextButton",{Parent=TopBar,BackgroundTransparency=1,
        Size=UDim2.new(0,0,1,-6),AutomaticSize=Enum.AutomaticSize.X,
        Text=txt,Font=Enum.Font.GothamBold,TextSize=17,
        TextColor3=Color3.fromRGB(220,220,220),LayoutOrder=order})
    CI("UIPadding",{Parent=b,PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)})
    b.MouseEnter:Connect(function() b.TextColor3=Color3.fromRGB(100,180,255) end)
    b.MouseLeave:Connect(function() b.TextColor3=Color3.fromRGB(220,220,220) end)
    return b
end
local function TopLabel(txt, col, order, w)
    return CI("TextLabel",{Parent=TopBar,BackgroundTransparency=1,
        Size=UDim2.new(0,w or 120,1,0),Text=txt,Font=Enum.Font.GothamBold,TextSize=17,
        TextColor3=col or Color3.fromRGB(255,255,255),
        TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=order})
end

local CompanyName   = TopLabel("❖ SORCHESUS CO.", Color3.fromRGB(210,40,40),  1, 200)
local EmployeeBtn   = TopBtn("Employees",   2)
local OuterGuardBtn = TopBtn("Outer Guard", 3)
local TerminatorBtn = TopBtn("⚡ Terminator", 4)
local InventoryBtn  = TopBtn("Inventory",   5)
local BuyDocBtn     = TopBtn("Buy Docs(100)",6)
local EndDayBtn     = TopBtn("End Day",     7)
EndDayBtn.TextColor3= Color3.fromRGB(80,80,80)

local CrucibleLabel = TopLabel("◈ 100",    C.NeonGold, 8, 130)
local DayLabel      = TopLabel("Day: 1",   Color3.fromRGB(200,200,255), 9, 80)
local QuotaLabel    = TopLabel("Quota: 0/750", Color3.fromRGB(180,180,180), 10, 170)
local CoreLabel     = TopLabel("Core: 15700", Color3.fromRGB(100,220,255), 11, 140)

-- Breach alert label (hidden unless breach)
local BreachAlert = CI("TextLabel",{Parent=MainGui,BackgroundColor3=Color3.fromRGB(150,0,0),
    BorderSizePixel=0,Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,52),
    Text="⚠ BREACH IN PROGRESS",Font=Enum.Font.GothamBold,TextSize=18,
    TextColor3=Color3.fromRGB(255,255,255),Visible=false,ZIndex=5})
CI("UIStroke",{Parent=BreachAlert,Color=Color3.fromRGB(255,80,80),Thickness=1.5})

local function RefreshCrucibleDisplay()
    CrucibleLabel.Text = "◈ "..GameData.Crucible
end
local function UpdateQuotaDisplay()
    local q = Quotas[math.min(GameData.CurrentDay,#Quotas)]
    QuotaLabel.Text = "Quota: "..GameData.DailyCrucible.."/"..q
    local met = GameData.DailyCrucible >= q
    EndDayBtn.TextColor3 = met and Color3.fromRGB(80,255,80) or Color3.fromRGB(80,80,80)
    EndDayBtn.Active = met
end
local function UpdateCoreLabel()
    CoreLabel.Text = "Core: "..GameData.CosmicShardCoreHealth
    local frac = GameData.CosmicShardCoreHealth/GameData.MaxCoreHealth
    CoreLabel.TextColor3 = Color3.new(1-frac*0.5, 0.3+frac*0.6, frac)
end
local function UpdateBreachAlert()
    local any=false
    for _,a in ipairs(GameData.OwnedAnomalies) do if a.IsBreached then any=true break end end
    BreachAlert.Visible=any
end

-- ══════════════════════ PANEL TEMPLATE ══════════════════════
local isMobile = UserInputService.TouchEnabled
local function MakePanel(name, w, h)
    local f = CI("Frame",{Name=name,Parent=MainGui,
        BackgroundColor3=Color3.fromRGB(10,10,22),BorderSizePixel=0,
        Size=isMobile and UDim2.new(0.97,0,0.92,0) or UDim2.new(0,w,0,h),
        Position=isMobile and UDim2.new(0.015,0,0.04,0) or UDim2.new(0.5,-(w//2),0.5,-(h//2)),
        Visible=false,ZIndex=20})
    CI("UICorner",{Parent=f,CornerRadius=UDim.new(0,10)})
    CI("UIStroke",{Parent=f,Color=Color3.fromRGB(0,80,200),Thickness=1.5})

    local title = CI("TextLabel",{Parent=f,BackgroundColor3=Color3.fromRGB(8,8,20),BorderSizePixel=0,
        Size=UDim2.new(1,0,0,38),Text=name:upper(),Font=Enum.Font.GothamBold,TextSize=16,
        TextColor3=Color3.fromRGB(200,200,255)})
    CI("UIStroke",{Parent=title,Color=Color3.fromRGB(0,60,160),Thickness=1})

    local closeBtn = CI("TextButton",{Parent=f,BackgroundColor3=Color3.fromRGB(140,20,20),
        BorderSizePixel=0,Size=UDim2.new(0,32,0,32),Position=UDim2.new(1,-36,0,3),
        Text="✕",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=Color3.fromRGB(255,255,255),ZIndex=21})
    CI("UICorner",{Parent=closeBtn,CornerRadius=UDim.new(0,6)})
    closeBtn.MouseButton1Click:Connect(function() f.Visible=false end)

    local body = CI("ScrollingFrame",{Parent=f,BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.new(1,-10,1,-46),Position=UDim2.new(0,5,0,42),
        CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=5,
        ScrollBarImageColor3=Color3.fromRGB(0,80,200)})
    local layout = CI("UIListLayout",{Parent=body,Padding=UDim.new(0,8),
        SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center})

    return f, body, layout
end

-- ══════════════════════ EMPLOYEE SHOP ══════════════════════
local GuardTypes = {
    {Name="Weak Guard",  Type="Guard",HP=150,MaxHP=150,Damage=20,  Cost=200},
    {Name="Normal Guard",Type="Guard",HP=300,MaxHP=300,Damage=50,  Cost=500},
    {Name="Strong Guard",Type="Guard",HP=600,MaxHP=600,Damage=100, Cost=1000},
    {Name="Tanky Guard", Type="Guard",HP=1200,MaxHP=1200,Damage=75,Cost=2000},
    {Name="Super Guard", Type="Guard",HP=2500,MaxHP=2500,Damage=200,Cost=5000},
}
local WorkerTypes = {
    {Name="Rookie Worker", Type="Worker",HP=80,MaxHP=80,SuccessChance=0.50,Cost=150},
    {Name="Normal Worker", Type="Worker",HP=120,MaxHP=120,SuccessChance=0.65,Cost=350},
    {Name="Expert Worker", Type="Worker",HP=180,MaxHP=180,SuccessChance=0.80,Cost=800},
}

local EmployeeShop, EmpBody, EmpLayout = MakePanel("Employee Shop", 520, 540)

local function RefreshEmployeeShop()
    for _,c in pairs(EmpBody:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end
    local function AddShopRow(label, cost, onClick)
        local row = CI("Frame",{Parent=EmpBody,BackgroundColor3=Color3.fromRGB(18,18,32),
            BorderSizePixel=0,Size=UDim2.new(1,-10,0,52)})
        CI("UICorner",{Parent=row,CornerRadius=UDim.new(0,8)})
        CI("TextLabel",{Parent=row,BackgroundTransparency=1,Size=UDim2.new(0.72,0,1,0),
            Position=UDim2.new(0,10,0,0),Text=label,Font=Enum.Font.Gotham,TextSize=14,
            TextColor3=Color3.fromRGB(220,220,220),TextXAlignment=Enum.TextXAlignment.Left})
        local btn = CI("TextButton",{Parent=row,BackgroundColor3=Color3.fromRGB(30,80,170),
            BorderSizePixel=0,Size=UDim2.new(0.24,0,0.7,0),Position=UDim2.new(0.74,0,0.15,0),
            Text="◈ "..cost,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(255,215,0)})
        CI("UICorner",{Parent=btn,CornerRadius=UDim.new(0,6)})
        btn.MouseButton1Click:Connect(onClick)
        return row
    end
    for _,wt in ipairs(WorkerTypes) do
        local wt2=wt
        AddShopRow("🔵 "..wt2.Name.." (HP:"..wt2.MaxHP.." Suc:"..math.floor(wt2.SuccessChance*100).."%)",wt2.Cost, function()
            if GameData.Crucible < wt2.Cost then CreateNotification("Not enough Crucible!",Color3.fromRGB(200,50,50)) return end
            UpdateCrucible(-wt2.Cost); RefreshCrucibleDisplay()
            local w={Name=GetRandomWorkerName(),Type=wt2.Name,HP=wt2.MaxHP,MaxHP=wt2.MaxHP,
                SuccessChance=wt2.SuccessChance,AssignedTo=nil,SpeedMultiplier=1,BuffDebuff=nil}
            table.insert(GameData.OwnedWorkers,w)
            CreateNotification("Hired: "..w.Name.." ("..wt2.Name..")",Color3.fromRGB(60,180,255))
            local np=Vector3.new(HQ_OFFSET,FLOOR_Y+1,math.random(-8,8))
            local npc=MakeNPC(np,C.Worker,w.Name)
            w.NPC=npc
            StartNPCPatrol(npc, C.Worker)
        end)
    end
    for _,gt in ipairs(GuardTypes) do
        local gt2=gt
        AddShopRow("🟢 "..gt2.Name.." (HP:"..gt2.MaxHP.." Dmg:"..gt2.Damage..")",gt2.Cost, function()
            if GameData.Crucible < gt2.Cost then CreateNotification("Not enough Crucible!",Color3.fromRGB(200,50,50)) return end
            UpdateCrucible(-gt2.Cost); RefreshCrucibleDisplay()
            local g={Name=GetRandomGuardName(),Type=gt2.Name,HP=gt2.MaxHP,MaxHP=gt2.MaxHP,
                Damage=gt2.Damage,AssignedTo=nil,BuffDebuff=nil}
            table.insert(GameData.OwnedGuards,g)
            CreateNotification("Hired: "..g.Name.." ("..gt2.Name..")",Color3.fromRGB(50,200,100))
            local np=Vector3.new(HQ_OFFSET+math.random(-8,8),FLOOR_Y+1,math.random(-8,8))
            local npc=MakeNPC(np,C.Guard,g.Name)
            g.NPC=npc
            StartNPCPatrol(npc, C.Guard)
        end)
    end
    EmpBody.CanvasSize=UDim2.new(0,0,0,EmpLayout.AbsoluteContentSize.Y+20)
end
EmployeeBtn.MouseButton1Click:Connect(function()
    RefreshEmployeeShop(); EmployeeShop.Visible=true
end)

-- ══════════════════════ INVENTORY ══════════════════════
local InvGui, InvBody, InvLayout = MakePanel("Inventory", 560, 560)
InventoryBtn.MouseButton1Click:Connect(function()
    for _,c in pairs(InvBody:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local function InvSection(title)
        CI("TextLabel",{Parent=InvBody,BackgroundTransparency=1,Size=UDim2.new(1,-10,0,28),
            Text=title,Font=Enum.Font.GothamBold,TextSize=15,TextColor3=Color3.fromRGB(180,180,255),
            TextXAlignment=Enum.TextXAlignment.Left})
    end
    InvSection("── Workers ──")
    for _,w in ipairs(GameData.OwnedWorkers) do
        local str="🔵 "..w.Name.." | HP:"..w.HP.."/"..w.MaxHP.." | Suc:"..math.floor(w.SuccessChance*100).."%"
        if w.BuffDebuff then str=str.." | ★ "..w.BuffDebuff end
        CI("TextLabel",{Parent=InvBody,BackgroundColor3=Color3.fromRGB(16,22,36),BorderSizePixel=0,
            Size=UDim2.new(1,-10,0,40),Text=str,Font=Enum.Font.Gotham,TextSize=13,
            TextColor3=w.HP>0 and Color3.fromRGB(200,200,255) or Color3.fromRGB(120,50,50),
            TextXAlignment=Enum.TextXAlignment.Left})
        :FindFirstChildOfClass("Frame") -- just triggers autocreate
    end
    InvSection("── Guards ──")
    for _,g in ipairs(GameData.OwnedGuards) do
        local str="🟢 "..g.Name.." | HP:"..g.HP.."/"..g.MaxHP.." | Dmg:"..g.Damage
        if g.BuffDebuff then str=str.." | ★ "..g.BuffDebuff end
        CI("TextLabel",{Parent=InvBody,BackgroundColor3=Color3.fromRGB(16,22,36),BorderSizePixel=0,
            Size=UDim2.new(1,-10,0,40),Text=str,Font=Enum.Font.Gotham,TextSize=13,
            TextColor3=g.HP>0 and Color3.fromRGB(200,255,200) or Color3.fromRGB(120,50,50),
            TextXAlignment=Enum.TextXAlignment.Left})
    end
    InvSection("── MX Weapons ──")
    for _,w in ipairs(GameData.OwnedMXWeapons) do
        CI("TextLabel",{Parent=InvBody,BackgroundColor3=Color3.fromRGB(16,16,30),BorderSizePixel=0,
            Size=UDim2.new(1,-10,0,36),
            Text="⚔ "..w.Name.." | Dmg:"..w.Damage.." | From: "..w.Anomaly,
            Font=Enum.Font.Gotham,TextSize=13,TextColor3=Color3.fromRGB(255,215,80),
            TextXAlignment=Enum.TextXAlignment.Left})
    end
    InvSection("── MX Armors ──")
    for _,a in ipairs(GameData.OwnedMXArmors) do
        CI("TextLabel",{Parent=InvBody,BackgroundColor3=Color3.fromRGB(16,16,30),BorderSizePixel=0,
            Size=UDim2.new(1,-10,0,36),
            Text="🛡 "..a.Name.." | HP+"..a.Health.." | From: "..a.Anomaly,
            Font=Enum.Font.Gotham,TextSize=13,TextColor3=Color3.fromRGB(150,230,255),
            TextXAlignment=Enum.TextXAlignment.Left})
    end
    InvBody.CanvasSize=UDim2.new(0,0,0,InvLayout.AbsoluteContentSize.Y+20)
    InvGui.Visible=true
end)

-- ══════════════════════ OUTER GUARD ══════════════════════
local OGGui, OGBody, OGLayout = MakePanel("Outer Guard", 480, 500)
OuterGuardBtn.MouseButton1Click:Connect(function()
    for _,c in pairs(OGBody:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    CI("TextLabel",{Parent=OGBody,BackgroundTransparency=1,Size=UDim2.new(1,-10,0,26),
        Text="Available Guards",Font=Enum.Font.GothamBold,TextSize=14,
        TextColor3=Color3.fromRGB(200,220,200)})
    for _,g in ipairs(GameData.OwnedGuards) do
        local g2=g
        if g2.HP>0 and g2.AssignedTo==nil then
            local row=CI("Frame",{Parent=OGBody,BackgroundColor3=Color3.fromRGB(18,28,18),
                BorderSizePixel=0,Size=UDim2.new(1,-10,0,46)})
            CI("UICorner",{Parent=row,CornerRadius=UDim.new(0,7)})
            CI("TextLabel",{Parent=row,BackgroundTransparency=1,Size=UDim2.new(0.74,0,1,0),
                Position=UDim2.new(0,8,0,0),Text="🟢 "..g2.Name.." | HP:"..g2.HP.." Dmg:"..g2.Damage,
                Font=Enum.Font.Gotham,TextSize=13,TextColor3=Color3.fromRGB(200,255,200),
                TextXAlignment=Enum.TextXAlignment.Left})
            local ab=CI("TextButton",{Parent=row,BackgroundColor3=Color3.fromRGB(20,100,40),
                BorderSizePixel=0,Size=UDim2.new(0.22,0,0.7,0),Position=UDim2.new(0.76,0,0.15,0),
                Text="Assign",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(255,255,255)})
            CI("UICorner",{Parent=ab,CornerRadius=UDim.new(0,6)})
            ab.MouseButton1Click:Connect(function()
                table.insert(GameData.OuterGuards,g2); g2.AssignedTo="Outer"
                CreateNotification(g2.Name.." assigned to Outer Guard!",Color3.fromRGB(50,200,100))
                OGGui.Visible=false
            end)
        end
    end
    CI("TextLabel",{Parent=OGBody,BackgroundTransparency=1,Size=UDim2.new(1,-10,0,26),
        Text="Current Outer Guard ("..#GameData.OuterGuards..")",Font=Enum.Font.GothamBold,TextSize=14,
        TextColor3=Color3.fromRGB(220,200,200)})
    for _,g in ipairs(GameData.OuterGuards) do
        local g2=g
        local row=CI("Frame",{Parent=OGBody,BackgroundColor3=Color3.fromRGB(28,18,18),
            BorderSizePixel=0,Size=UDim2.new(1,-10,0,46)})
        CI("UICorner",{Parent=row,CornerRadius=UDim.new(0,7)})
        CI("TextLabel",{Parent=row,BackgroundTransparency=1,Size=UDim2.new(0.74,0,1,0),
            Position=UDim2.new(0,8,0,0),Text="⛔ "..g2.Name.." (Outer) HP:"..g2.HP,
            Font=Enum.Font.Gotham,TextSize=13,TextColor3=Color3.fromRGB(255,180,180),
            TextXAlignment=Enum.TextXAlignment.Left})
        local rb=CI("TextButton",{Parent=row,BackgroundColor3=Color3.fromRGB(120,30,30),
            BorderSizePixel=0,Size=UDim2.new(0.22,0,0.7,0),Position=UDim2.new(0.76,0,0.15,0),
            Text="Remove",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(255,255,255)})
        CI("UICorner",{Parent=rb,CornerRadius=UDim.new(0,6)})
        rb.MouseButton1Click:Connect(function()
            g2.AssignedTo=nil
            for i=#GameData.OuterGuards,1,-1 do if GameData.OuterGuards[i]==g2 then table.remove(GameData.OuterGuards,i) break end end
            OGGui.Visible=false
        end)
    end
    OGBody.CanvasSize=UDim2.new(0,0,0,OGLayout.AbsoluteContentSize.Y+20)
    OGGui.Visible=true
end)
-- ══════════════════════ FATE GUI ══════════════════════
local FateGui, FateBody, FateLayout = MakePanel("May the Fate decides", 480, 440)
local selectedFateEmployee = nil
local currentFateAnomaly   = nil
local FateDecideBtn = CI("TextButton",{Parent=FateGui,BackgroundColor3=Color3.fromRGB(30,120,60),
    BorderSizePixel=0,Size=UDim2.new(0,130,0,38),Position=UDim2.new(0.5,-65,1,-46),
    Text="Decide Fate",Font=Enum.Font.GothamBold,TextSize=15,
    TextColor3=Color3.fromRGB(255,255,255),ZIndex=22,Active=false})
CI("UICorner",{Parent=FateDecideBtn,CornerRadius=UDim.new(0,8)})

local function ShowFateGUI(anomalyInst)
    currentFateAnomaly = anomalyInst
    selectedFateEmployee = nil
    FateDecideBtn.Active = false
    FateDecideBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    for _,c in pairs(FateBody:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local all={}
    for _,w in ipairs(GameData.OwnedWorkers) do if w.HP>0 and not w.BuffDebuff then table.insert(all,{emp=w,role="Worker"}) end end
    for _,g in ipairs(GameData.OwnedGuards)  do if g.HP>0 and not g.BuffDebuff then table.insert(all,{emp=g,role="Guard"})  end end
    for _,e in ipairs(all) do
        local e2=e
        local row=CI("Frame",{Parent=FateBody,BackgroundColor3=Color3.fromRGB(18,18,32),
            BorderSizePixel=0,Size=UDim2.new(1,-10,0,46)})
        CI("UICorner",{Parent=row,CornerRadius=UDim.new(0,7)})
        CI("TextLabel",{Parent=row,BackgroundTransparency=1,Size=UDim2.new(0.74,0,1,0),
            Position=UDim2.new(0,8,0,0),Text=e2.emp.Name.." ("..e2.role..")",
            Font=Enum.Font.Gotham,TextSize=14,TextColor3=Color3.fromRGB(220,220,220),
            TextXAlignment=Enum.TextXAlignment.Left})
        local sb=CI("TextButton",{Parent=row,BackgroundColor3=Color3.fromRGB(40,40,70),
            BorderSizePixel=0,Size=UDim2.new(0.22,0,0.7,0),Position=UDim2.new(0.76,0,0.15,0),
            Text="Select",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(255,255,255)})
        CI("UICorner",{Parent=sb,CornerRadius=UDim.new(0,6)})
        sb.MouseButton1Click:Connect(function()
            selectedFateEmployee = e2.emp
            FateDecideBtn.Active = true
            FateDecideBtn.BackgroundColor3 = Color3.fromRGB(30,120,60)
            for _,ch in pairs(FateBody:GetChildren()) do
                if ch:IsA("Frame") then
                    local btn=ch:FindFirstChildOfClass("TextButton")
                    if btn then btn.BackgroundColor3=Color3.fromRGB(40,40,70) end
                end
            end
            sb.BackgroundColor3 = Color3.fromRGB(20,90,160)
        end)
    end
    FateBody.CanvasSize=UDim2.new(0,0,0,FateLayout.AbsoluteContentSize.Y+20)
    FateGui.Visible=true
end

FateDecideBtn.MouseButton1Click:Connect(function()
    if not selectedFateEmployee or not currentFateAnomaly then return end
    local isWorker = selectedFateEmployee.SuccessChance ~= nil
    local role     = isWorker and "Worker" or "Guard"
    local possible = {}
    for _,eff in ipairs(FateEffects) do
        if eff.employee==role then table.insert(possible,eff) end
    end
    local total=0; for _,e in ipairs(possible) do total=total+e.chance end
    local rand=math.random(total); local cum=0; local chosen=nil
    for _,e in ipairs(possible) do cum=cum+e.chance; if rand<=cum then chosen=e break end end
    if chosen then
        chosen.effect(selectedFateEmployee)
        selectedFateEmployee.BuffDebuff = chosen.name
        local isGood = chosen.type=="buff"
        local bgC = isGood and Color3.fromRGB(0,180,60) or Color3.fromRGB(200,0,0)
        CreateNotification(selectedFateEmployee.Name.." — "..(isGood and "✦ Bless: " or "✸ Curse: ")..chosen.name, bgC)
        currentFateAnomaly.CurrentMood = math.clamp(currentFateAnomaly.CurrentMood+(isGood and 50 or -25),0,100)
        GameData.FateUsedToday = true
    end
    FateGui.Visible=false
end)

-- ══════════════════════ ANOMALY ASSIGN GUI ══════════════════════
local AssignGui, AssignBody, AssignLayout = MakePanel("Assign Workers & Guards", 520, 520)
local currentAssignAnomaly = nil

local function PopulateAssignGui(anomInst)
    currentAssignAnomaly = anomInst
    for _,c in pairs(AssignBody:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    AssignGui:FindFirstChild("Assign Workers & Guards") -- title
    CI("TextLabel",{Parent=AssignBody,BackgroundTransparency=1,Size=UDim2.new(1,-10,0,26),
        Text="── Workers (slot: "..(anomInst.AssignedWorker and "FULL" or "OPEN")..")",
        Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.fromRGB(160,180,255)})
    for _,w in ipairs(GameData.OwnedWorkers) do
        local w2=w
        if w2.HP>0 and w2.AssignedTo==nil then
            local row=CI("Frame",{Parent=AssignBody,BackgroundColor3=Color3.fromRGB(16,16,30),
                BorderSizePixel=0,Size=UDim2.new(1,-10,0,46)})
            CI("UICorner",{Parent=row,CornerRadius=UDim.new(0,7)})
            CI("TextLabel",{Parent=row,BackgroundTransparency=1,Size=UDim2.new(0.72,0,1,0),
                Position=UDim2.new(0,8,0,0),
                Text="🔵 "..w2.Name.." | HP:"..w2.HP.." | Suc:"..math.floor(w2.SuccessChance*100).."%",
                Font=Enum.Font.Gotham,TextSize=13,TextColor3=Color3.fromRGB(200,210,255),
                TextXAlignment=Enum.TextXAlignment.Left})
            local ab=CI("TextButton",{Parent=row,BackgroundColor3=Color3.fromRGB(20,70,170),
                BorderSizePixel=0,Size=UDim2.new(0.24,0,0.7,0),Position=UDim2.new(0.74,0,0.15,0),
                Text="Assign",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(255,255,255)})
            CI("UICorner",{Parent=ab,CornerRadius=UDim.new(0,6)})
            ab.MouseButton1Click:Connect(function()
                if anomInst.AssignedWorker then CreateNotification("Worker slot full!",Color3.fromRGB(200,50,50)) return end
                anomInst.AssignedWorker=w2; w2.AssignedTo=anomInst
                StartWorkerLoop(w2,anomInst)
                AssignGui.Visible=false; UpdateRoomDisplay(anomInst)
                if w2.NPC then
                    -- Walk NPC to the room
                    AnimateNPCWalk(w2.NPC, w2.NPC.Root.CFrame.Position, anomInst.Room3D.Position+Vector3.new(0,1,0), 0.04, nil)
                end
            end)
        end
    end
    CI("TextLabel",{Parent=AssignBody,BackgroundTransparency=1,Size=UDim2.new(1,-10,0,26),
        Text="── Guards (slots: "..#anomInst.AssignedGuards.."/2)",
        Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.fromRGB(160,255,180)})
    for _,g in ipairs(GameData.OwnedGuards) do
        local g2=g
        if g2.HP>0 and g2.AssignedTo==nil then
            local row=CI("Frame",{Parent=AssignBody,BackgroundColor3=Color3.fromRGB(16,16,30),
                BorderSizePixel=0,Size=UDim2.new(1,-10,0,46)})
            CI("UICorner",{Parent=row,CornerRadius=UDim.new(0,7)})
            CI("TextLabel",{Parent=row,BackgroundTransparency=1,Size=UDim2.new(0.72,0,1,0),
                Position=UDim2.new(0,8,0,0),
                Text="🟢 "..g2.Name.." | HP:"..g2.HP.." | Dmg:"..g2.Damage,
                Font=Enum.Font.Gotham,TextSize=13,TextColor3=Color3.fromRGB(200,255,200),
                TextXAlignment=Enum.TextXAlignment.Left})
            local ab=CI("TextButton",{Parent=row,BackgroundColor3=Color3.fromRGB(20,120,50),
                BorderSizePixel=0,Size=UDim2.new(0.24,0,0.7,0),Position=UDim2.new(0.74,0,0.15,0),
                Text="Assign",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(255,255,255)})
            CI("UICorner",{Parent=ab,CornerRadius=UDim.new(0,6)})
            ab.MouseButton1Click:Connect(function()
                if #anomInst.AssignedGuards>=2 then CreateNotification("Guard slots full!",Color3.fromRGB(200,50,50)) return end
                table.insert(anomInst.AssignedGuards,g2); g2.AssignedTo=anomInst
                AssignGui.Visible=false; UpdateRoomDisplay(anomInst)
                if g2.NPC then
                    AnimateNPCWalk(g2.NPC, g2.NPC.Root.CFrame.Position, anomInst.Room3D.Position+Vector3.new(math.random(-3,3),1,0), 0.04, nil)
                end
            end)
        end
    end
    AssignBody.CanvasSize=UDim2.new(0,0,0,AssignLayout.AbsoluteContentSize.Y+20)
    AssignGui.Visible=true
end

-- ══════════════════════ ANOMALY INFO GUI ══════════════════════
local InfoGui, InfoBody, InfoLayout = MakePanel("Anomaly Info", 500, 560)
local InfoPaywallGui = CI("Frame",{Parent=MainGui,BackgroundColor3=Color3.fromRGB(10,10,20),
    BorderSizePixel=0,Visible=false,ZIndex=30,
    Size=isMobile and UDim2.new(0.97,0,0.92,0) or UDim2.new(0,420,0,240),
    Position=isMobile and UDim2.new(0.015,0,0.04,0) or UDim2.new(0.5,-210,0.5,-120)})
CI("UICorner",{Parent=InfoPaywallGui,CornerRadius=UDim.new(0,10)})
CI("UIStroke",{Parent=InfoPaywallGui,Color=C.NeonGold,Thickness=1.5})
local InfoPaywallCostLabel = CI("TextLabel",{Parent=InfoPaywallGui,BackgroundTransparency=1,
    Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.1,0),
    Text="Unlock Info",Font=Enum.Font.GothamBold,TextSize=18,
    TextColor3=Color3.fromRGB(255,215,0)})
local InfoPaywallBtn = CI("TextButton",{Parent=InfoPaywallGui,BackgroundColor3=Color3.fromRGB(60,120,20),
    BorderSizePixel=0,Size=UDim2.new(0,140,0,40),Position=UDim2.new(0.5,-70,0.6,0),
    Text="Purchase",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=Color3.fromRGB(255,255,255)})
CI("UICorner",{Parent=InfoPaywallBtn,CornerRadius=UDim.new(0,8)})
local InfoPWClose = CI("TextButton",{Parent=InfoPaywallGui,BackgroundColor3=Color3.fromRGB(140,20,20),
    BorderSizePixel=0,Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,-34,0,4),
    Text="✕",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.fromRGB(255,255,255),ZIndex=31})
CI("UICorner",{Parent=InfoPWClose,CornerRadius=UDim.new(0,6)})
InfoPWClose.MouseButton1Click:Connect(function() InfoPaywallGui.Visible=false end)

local function ShowAnomalyInfo(anomInst)
    local data    = anomInst.Data
    local unlocked= anomInst.Unlocked
    for _,c in pairs(InfoBody:GetChildren()) do if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end end
    local function Row(txt, col)
        CI("TextLabel",{Parent=InfoBody,BackgroundTransparency=1,Size=UDim2.new(1,-10,0,0),
            AutomaticSize=Enum.AutomaticSize.Y,Text=txt,Font=Enum.Font.Gotham,TextSize=13,
            TextColor3=col or Color3.fromRGB(210,210,210),TextWrapped=true,
            TextXAlignment=Enum.TextXAlignment.Left})
    end
    local dCol = DangerColors[data.DangerClass] or Color3.fromRGB(200,200,200)
    Row((unlocked.Stat and anomInst.Name or "??? [Unclassified]"),Color3.fromRGB(255,200,80))
    Row("Danger Class: "..(unlocked.Stat and data.DangerClass or "???"), dCol)
    Row(data.Description, Color3.fromRGB(180,180,200))
    Row("Mood: "..anomInst.CurrentMood.."/100", Color3.fromRGB(100,200,255))
    Row("Worked by: "..(anomInst.AssignedWorker and anomInst.AssignedWorker.Name or "—"))
    local g1=anomInst.AssignedGuards[1] and anomInst.AssignedGuards[1].Name or "—"
    local g2=anomInst.AssignedGuards[2] and anomInst.AssignedGuards[2].Name or "—"
    Row("Guarded by: "..g1.." & "..g2)
    if anomInst.IsBreached then
        Row("⚠ BREACHED — "..data.BreachForm.Name, Color3.fromRGB(255,50,50))
        Row("Breach HP: "..math.floor(anomInst.BreachHP or 0), Color3.fromRGB(255,100,100))
    end
    if data.ManagementTips and #data.ManagementTips>0 then
        Row("── Management Tips ──", C.NeonGold)
        for i,tip in ipairs(data.ManagementTips) do
            local cost = data.Costs and data.Costs.Management and data.Costs.Management[i]
            if unlocked.Management and unlocked.Management[i] then
                Row("• "..tip, Color3.fromRGB(200,220,160))
            else
                if cost then
                    local tb = CI("TextButton",{Parent=InfoBody,BackgroundColor3=Color3.fromRGB(20,60,20),
                        BorderSizePixel=0,Size=UDim2.new(1,-10,0,36),
                        Text="[Unlock Tip "..(i).."] ◈ "..cost,Font=Enum.Font.GothamBold,TextSize=13,
                        TextColor3=C.NeonGold})
                    CI("UICorner",{Parent=tb,CornerRadius=UDim.new(0,6)})
                    local i2,cost2=i,cost
                    tb.MouseButton1Click:Connect(function()
                        if GameData.Crucible<cost2 then CreateNotification("Not enough Crucible!",Color3.fromRGB(200,50,50)) return end
                        UpdateCrucible(-cost2); RefreshCrucibleDisplay()
                        anomInst.Unlocked.Management[i2]=true
                        ShowAnomalyInfo(anomInst)
                    end)
                end
            end
        end
    end
    -- Unlock info paywall buttons
    local function UnlockRow(key, label, costKey)
        if not unlocked[key] then
            local cost = data.Costs and data.Costs[costKey or key]
            if cost then
                local tb=CI("TextButton",{Parent=InfoBody,BackgroundColor3=Color3.fromRGB(20,40,80),
                    BorderSizePixel=0,Size=UDim2.new(1,-10,0,36),
                    Text="[Unlock "..label.."] ◈ "..cost,Font=Enum.Font.GothamBold,TextSize=13,
                    TextColor3=Color3.fromRGB(180,200,255)})
                CI("UICorner",{Parent=tb,CornerRadius=UDim.new(0,6)})
                local k2,c2=key,cost
                tb.MouseButton1Click:Connect(function()
                    if GameData.Crucible<c2 then CreateNotification("Not enough Crucible!",Color3.fromRGB(200,50,50)) return end
                    UpdateCrucible(-c2); RefreshCrucibleDisplay()
                    anomInst.Unlocked[k2]=true
                    ShowAnomalyInfo(anomInst)
                end)
            end
        end
    end
    UnlockRow("Stat","Name & Danger Class","Stat")
    InfoBody.CanvasSize=UDim2.new(0,0,0,InfoLayout.AbsoluteContentSize.Y+20)
    InfoGui.Visible=true
end

-- ══════════════════════ 3D ROOM DISPLAY UPDATE ══════════════════════
function UpdateRoomDisplay(anomInst)
    local r3d = anomInst.Room3D
    if not r3d then return end
    local mood = anomInst.CurrentMood/100
    local moodCol
    if mood > 0.5 then moodCol = Color3.fromRGB(50,200,50)
    elseif mood > 0.2 then moodCol = Color3.fromRGB(220,160,30)
    else moodCol = Color3.fromRGB(220,40,40) end

    if r3d.MoodFill and r3d.MoodFill.Parent then
        local barW = (ROOM_W-3)*mood
        local bgW  = ROOM_W-3
        local bgX  = r3d.FrontZ - r3d.Side*0.12
        local fillX= r3d.FrontZ - r3d.Side*0.18
        TweenService:Create(r3d.MoodFill, TweenInfo.new(0.3),{
            Size=Vector3.new(math.max(0.1,barW), 0.45, 0.12),
            Color=moodCol,
            CFrame=CFrame.new(r3d.DoorX - (bgW-barW)/2, FLOOR_Y+1.6, fillX)
        }):Play()
        r3d.MoodFill.Material = Enum.Material.Neon
    end

    if r3d.Orb and r3d.Orb.Parent then
        if anomInst.IsBreached then
            TweenService:Create(r3d.Orb,TweenInfo.new(0.2),{Color=C.NeonRed}):Play()
            TweenService:Create(r3d.OrbGlow,TweenInfo.new(0.2),{Color=C.NeonRed}):Play()
        else
            local dc = r3d.DangerColor
            local blended = Color3.new(
                dc.R*(0.5+mood*0.5),
                dc.G*(0.3+mood*0.7),
                dc.B*(0.6+mood*0.4))
            TweenService:Create(r3d.Orb,TweenInfo.new(0.4),{Color=blended}):Play()
            TweenService:Create(r3d.OrbGlow,TweenInfo.new(0.4),{Color=blended}):Play()
        end
    end

    -- Update billboard if it exists
    if anomInst.Billboard then
        local bb = anomInst.Billboard
        if bb.NameLabel then
            bb.NameLabel.Text = (anomInst.Unlocked.Stat and anomInst.Name or "[???]")
                ..(anomInst.IsBreached and " ⚠BREACH" or "")
        end
        if bb.MoodFill then
            TweenService:Create(bb.MoodFill,TweenInfo.new(0.3),{
                Size=UDim2.new(mood,0,1,0),
                BackgroundColor3=moodCol
            }):Play()
        end
    end
end
-- ══════════════════════ GAME LOGIC FUNCTIONS ══════════════════════
local function RollForMXGift(anomInst)
    local d = anomInst.Data
    if d.MXWeapon and math.random()<d.MXWeapon.Chance then
        local item={Name=d.MXWeapon.Name,Damage=d.MXWeapon.Damage,
            MinLevel=d.MXWeapon.MinLevel,MaxLevel=d.MXWeapon.MaxLevel,
            Type="Weapon",Anomaly=anomInst.Name,EquippedTo=nil}
        table.insert(GameData.OwnedMXWeapons,item)
        CreateNotification("⚔ MX Weapon: "..item.Name.."!",Color3.fromRGB(255,200,50))
    end
    if d.MXArmor and math.random()<d.MXArmor.Chance then
        local item={Name=d.MXArmor.Name,Health=d.MXArmor.Health,
            MinLevel=d.MXArmor.MinLevel,MaxLevel=d.MXArmor.MaxLevel,
            Type="Armor",Anomaly=anomInst.Name,EquippedTo=nil}
        table.insert(GameData.OwnedMXArmors,item)
        CreateNotification("🛡 MX Armor: "..item.Name.."!",Color3.fromRGB(150,230,255))
    end
end

-- Flash breach effect in 3D
local function BreachFlash(room3D)
    spawn(function()
        for _=1,6 do
            if room3D.Orb and room3D.Orb.Parent then
                room3D.Orb.Color = C.NeonRed; room3D.OrbGlow.Color=C.NeonRed
                wait(0.15)
                room3D.Orb.Color = Color3.fromRGB(80,80,80); room3D.OrbGlow.Color=Color3.fromRGB(60,60,60)
                wait(0.15)
            end
        end
    end)
end

function TriggerBreach(anomInst, _roomFrame)
    if anomInst.IsBreached or anomInst.Data.NoBreach then return end
    if anomInst.Data.NoMoodMeter and not anomInst.Data.BreachOnLinkedBreach then return end

    GameData.LastGlobalBreachTime = os.time()
    GameData.TotalBreaches = GameData.TotalBreaches + 1

    local breachData = anomInst.Data.BreachForm
    anomInst.IsBreached = true
    anomInst.BreachHP   = breachData.Health + (anomInst.BonusBreachHealth or 0)
    anomInst.BreachTime = os.time()

    table.insert(GameData.BreachedAnomalies,{Instance=anomInst,BreachData=breachData})

    CreateNotification("⚠ BREACH! "..breachData.Name.." has escaped!", C.NeonRed)
    UpdateBreachAlert()
    UpdateRoomDisplay(anomInst)

    if anomInst.Room3D then BreachFlash(anomInst.Room3D) end

    local snd = Instance.new("Sound")
    snd.SoundId = "rbxassetid://91141788235501"
    snd.Volume  = 1; snd.Parent = workspace
    snd:Play(); Debris:AddItem(snd,5)

    -- Linked anomaly
    if anomInst.Data.LinkedAnomaly then
        for _,other in ipairs(GameData.OwnedAnomalies) do
            if other.Name==anomInst.Data.LinkedAnomaly and other.Data.BreachOnLinkedBreach then
                TriggerBreach(other,nil)
            end
        end
    end
    -- Prince of Fame response
    for _,a in ipairs(GameData.OwnedAnomalies) do
        if a.Name=="Prince of Fame" and not a.IsBreached then
            a.IsHelping=true; TriggerBreach(a,nil); break
        end
    end

    StartBreachLoop(anomInst)
end

function StartBreachLoop(anomInst)
    spawn(function()
        local bd      = anomInst.Data.BreachForm
        local elapsed = 0
        local minions = {}; local eyes = {}
        local minionDmg=0

        if anomInst.Data.Special=="Radio"  then for i=1,5 do table.insert(minions,{HP=100}) end; minionDmg=10 end
        if anomInst.Data.Special=="Eyes"   then table.insert(eyes,{HP=10}) end

        while anomInst.IsBreached do
            wait(2); elapsed=elapsed+2

            -- SkeletonKing every 30s
            if anomInst.Data.Special=="SkeletonKing" and elapsed%30==0 then
                local all={}
                for _,w in ipairs(GameData.OwnedWorkers) do if w.HP>0 then table.insert(all,w) end end
                for _,g in ipairs(GameData.OwnedGuards)  do if g.HP>0 then table.insert(all,g) end end
                if #all>0 then
                    local tgt=all[math.random(#all)]
                    if tgt.Revive then tgt.HP=tgt.MaxHP; tgt.Revive=false
                        CreateNotification(tgt.Name.." revived!",Color3.fromRGB(100,255,100))
                    else
                        tgt.HP=0
                        if tgt.SuccessChance then GameData.WorkersDied=GameData.WorkersDied+1
                        else GameData.GuardsDied=GameData.GuardsDied+1 end
                        CreateNotification(tgt.Name.." joined the skeleton army!",C.NeonRed)
                        if tgt.AssignedTo and tgt.AssignedTo~="Outer" then
                            if tgt.AssignedTo.AssignedWorker==tgt then tgt.AssignedTo.AssignedWorker=nil end
                            for i=#tgt.AssignedTo.AssignedGuards,1,-1 do
                                if tgt.AssignedTo.AssignedGuards[i]==tgt then table.remove(tgt.AssignedTo.AssignedGuards,i) end
                            end
                            UpdateRoomDisplay(tgt.AssignedTo)
                        elseif tgt.AssignedTo=="Outer" then
                            for i=#GameData.OuterGuards,1,-1 do if GameData.OuterGuards[i]==tgt then table.remove(GameData.OuterGuards,i) break end end
                        end
                        tgt.AssignedTo=nil
                        if tgt.SuccessChance then for i=#GameData.OwnedWorkers,1,-1 do if GameData.OwnedWorkers[i]==tgt then table.remove(GameData.OwnedWorkers,i) end end
                        else for i=#GameData.OwnedGuards,1,-1 do if GameData.OwnedGuards[i]==tgt then table.remove(GameData.OwnedGuards,i) end end end
                        if tgt.NPC and tgt.NPC.Model then tgt.NPC.Torso.Color=Color3.fromRGB(200,200,200) end
                    end
                end
            end

            -- Eyes spawn
            if anomInst.Data.Special=="Eyes" and elapsed%10==0 then
                table.insert(eyes,{HP=10}); CreateNotification("👁 New eye appeared!",C.NeonRed)
            end

            -- Gather combatants
            local employees={}
            if anomInst.AssignedWorker and anomInst.AssignedWorker.HP>0 then table.insert(employees,anomInst.AssignedWorker) end
            for _,g in ipairs(anomInst.AssignedGuards) do if g.HP>0 then table.insert(employees,g) end end

            -- Terminator agents
            if GameData.TerminatorActive and #GameData.TerminatorAgents>0 then
                local agent=GameData.TerminatorAgents[1]
                local dmg = bd.M1Damage*0.5
                agent.HP = agent.HP - dmg
                CreateNotification(agent.Name.." taking fire! HP:"..math.floor(agent.HP),Color3.fromRGB(200,140,0))
                anomInst.BreachHP = anomInst.BreachHP - agent.Damage
                if anomInst.BreachHP<=0 then
                    anomInst.IsBreached=false
                    for i=#GameData.BreachedAnomalies,1,-1 do
                        if GameData.BreachedAnomalies[i].Instance==anomInst then table.remove(GameData.BreachedAnomalies,i) break end
                    end
                    CreateNotification(agent.Name.." contained "..anomInst.Name.."!",Color3.fromRGB(50,200,100))
                    anomInst.CurrentMood=math.clamp(anomInst.Data.BaseMood*0.5,0,100)
                    UpdateRoomDisplay(anomInst); UpdateBreachAlert(); return
                end
                if agent.HP<=0 then
                    CreateNotification(agent.Name.." is down!",C.NeonRed)
                    table.remove(GameData.TerminatorAgents,1)
                    if #GameData.TerminatorAgents==0 then GameData.TerminatorActive=false end
                end
            end

            -- Extra minion/eye damage to employees
            local extraDmg=0
            if anomInst.Data.Special=="Radio" then extraDmg=minionDmg*#minions
            elseif anomInst.Data.Special=="Eyes" then extraDmg=50*#eyes end
            if extraDmg>0 and #employees>0 then
                local tgt=employees[math.random(#employees)]
                tgt.HP=math.max(0,tgt.HP-extraDmg)
                if tgt.NPC and tgt.NPC.HPFill then tgt.NPC.HPFill.Size=UDim2.new(tgt.HP/tgt.MaxHP,0,1,0) end
            end

            -- Main anomaly attack
            if #employees>0 then
                local tgt=employees[math.random(#employees)]
                -- Yang only attacks Yin
                local isYang = anomInst.Name=="Yang"
                if isYang then
                    local yinFound=false
                    for _,a in ipairs(GameData.OwnedAnomalies) do
                        if a.Name=="Yin" and a.IsBreached then
                            a.BreachHP = a.BreachHP - bd.M1Damage
                            CreateNotification("Yang attacks Yin! Yin HP:"..math.floor(a.BreachHP),Color3.fromRGB(100,200,255))
                            if a.BreachHP<=0 then
                                a.IsBreached=false
                                for i=#GameData.BreachedAnomalies,1,-1 do if GameData.BreachedAnomalies[i].Instance==a then table.remove(GameData.BreachedAnomalies,i) break end end
                                CreateNotification("Yang contained Yin!",Color3.fromRGB(100,200,255))
                                anomInst.IsBreached=false
                                for i=#GameData.BreachedAnomalies,1,-1 do if GameData.BreachedAnomalies[i].Instance==anomInst then table.remove(GameData.BreachedAnomalies,i) break end end
                                UpdateRoomDisplay(a); UpdateRoomDisplay(anomInst); UpdateBreachAlert(); return
                            end
                            yinFound=true; break
                        end
                    end
                    if not yinFound then
                        -- Yang contained itself if Yin already gone
                        anomInst.IsBreached=false
                        for i=#GameData.BreachedAnomalies,1,-1 do if GameData.BreachedAnomalies[i].Instance==anomInst then table.remove(GameData.BreachedAnomalies,i) break end end
                        UpdateRoomDisplay(anomInst); UpdateBreachAlert(); return
                    end
                else
                    -- Normal attack
                    local totalDmg = bd.M1Damage
                    if tgt.MXArmor then totalDmg=math.max(1,totalDmg-20) end
                    tgt.HP = math.max(0, tgt.HP - totalDmg)
                    CreateNotification(bd.Name.." attacked "..tgt.Name.." for "..totalDmg,C.NeonRed)
                    if tgt.NPC and tgt.NPC.HPFill then tgt.NPC.HPFill.Size=UDim2.new(tgt.HP/tgt.MaxHP,0,1,0) end
                    if tgt.HP<=0 then
                        local isWorker = tgt.SuccessChance~=nil
                        if isWorker then GameData.WorkersDied=GameData.WorkersDied+1
                        else
                            if tgt.Revive then tgt.HP=tgt.MaxHP; tgt.Revive=false
                                CreateNotification(tgt.Name.." revived!",Color3.fromRGB(100,255,100))
                            else
                                GameData.GuardsDied=GameData.GuardsDied+1
                            end
                        end
                        CreateNotification(tgt.Name.." was killed!",C.NeonRed)
                        if tgt.AssignedTo and tgt.AssignedTo~="Outer" then
                            if tgt.AssignedTo.AssignedWorker==tgt then tgt.AssignedTo.AssignedWorker=nil end
                            for i=#tgt.AssignedTo.AssignedGuards,1,-1 do if tgt.AssignedTo.AssignedGuards[i]==tgt then table.remove(tgt.AssignedTo.AssignedGuards,i) end end
                            UpdateRoomDisplay(tgt.AssignedTo)
                        end
                        tgt.AssignedTo=nil
                        if tgt.NPC and tgt.NPC.Torso then tgt.NPC.Torso.Color=Color3.fromRGB(120,50,50) end
                    end
                end
            else
                -- Attack core
                GameData.CosmicShardCoreHealth = GameData.CosmicShardCoreHealth - bd.M1Damage
                CreateNotification("Core damaged! HP:"..GameData.CosmicShardCoreHealth,C.NeonRed)
                UpdateCoreLabel()
                if GameData.CosmicShardCoreHealth<=0 then
                    CreateNotification("💀 FACILITY DESTROYED — GAME OVER",C.NeonRed)
                end
            end

            -- Guards fight back
            for _,g in ipairs(anomInst.AssignedGuards) do
                if g.HP>0 then
                    local dmg = g.Damage * (g.MXWeapon and 1.5 or 1)
                    anomInst.BreachHP = anomInst.BreachHP - dmg
                    if anomInst.BreachHP<=0 then
                        anomInst.IsBreached=false
                        for i=#GameData.BreachedAnomalies,1,-1 do
                            if GameData.BreachedAnomalies[i].Instance==anomInst then table.remove(GameData.BreachedAnomalies,i) break end
                        end
                        CreateNotification(g.Name.." contained "..anomInst.Name.."!",Color3.fromRGB(50,200,100))
                        anomInst.CurrentMood=math.clamp(anomInst.Data.BaseMood*0.5,0,100)
                        UpdateRoomDisplay(anomInst); UpdateBreachAlert(); return
                    end
                end
            end
        end
    end)
end

-- ══════════════════════ PERFORM WORK ══════════════════════
local function PerformWork(anomInst, workType)
    if anomInst.IsBreached then CreateNotification("Can't work during breach!",C.NeonRed) return end
    local data = anomInst.Data
    local wr   = data.WorkResults[workType]
    if not wr then CreateNotification("Work type unavailable.",Color3.fromRGB(150,150,150)) return end
    if wr.MoodRequirement and anomInst.CurrentMood < wr.MoodRequirement then
        CreateNotification("Mood too low for "..workType.."!",Color3.fromRGB(200,100,50)) return end

    local success = math.random() < wr.Success
    local moodChange = wr.MoodChange or 0
    if success then
        UpdateCrucible(wr.Crucible); RefreshCrucibleDisplay(); UpdateQuotaDisplay()
        RollForMXGift(anomInst)
        CreateNotification("✓ "..workType.." success! +"..wr.Crucible.." ◈",Color3.fromRGB(50,200,80))
        -- Blooming Blood Tree
        if data.Special=="BloomingBloodTree" and anomInst.AssignedWorker then
            anomInst.SuccessfulWorkerWorks=(anomInst.SuccessfulWorkerWorks or 0)+1
            if anomInst.SuccessfulWorkerWorks>=5 then
                local w=anomInst.AssignedWorker
                w.HP=0; GameData.WorkersDied=GameData.WorkersDied+1
                CreateNotification(w.Name.." bloomed into a flower and died!",C.NeonRed)
                anomInst.AssignedWorker=nil; w.AssignedTo=nil
                anomInst.SuccessfulWorkerWorks=0
                if w.NPC and w.NPC.Torso then w.NPC.Torso.Color=Color3.fromRGB(200,50,100) end
                UpdateRoomDisplay(anomInst); return
            end
        end
    else
        CreateNotification("✗ "..workType.." failed! Mood "..moodChange,Color3.fromRGB(200,80,50))
        if wr.AttackOnFail and anomInst.AssignedWorker then
            anomInst.AssignedWorker.HP=math.max(0,anomInst.AssignedWorker.HP-(wr.FailDamage or 0))
            CreateNotification("ERROR attacked worker for "..(wr.FailDamage or 0),C.NeonRed)
        end
    end

    anomInst.CurrentMood = math.clamp(anomInst.CurrentMood + moodChange, 0, 100)

    -- JarOfBlood damage
    if data.Special=="JarOfBlood" and moodChange<0 and anomInst.AssignedWorker then
        local dmg=0; local m=anomInst.CurrentMood
        if m<=10 then dmg=69 elseif m<=30 then dmg=30 elseif m<=75 then dmg=10 end
        if dmg>0 then
            anomInst.AssignedWorker.HP=math.max(0,anomInst.AssignedWorker.HP-dmg)
            CreateNotification("Jar of Blood damaged "..anomInst.AssignedWorker.Name.." for "..dmg,C.NeonRed)
            if anomInst.AssignedWorker.HP<=0 then
                GameData.WorkersDied=GameData.WorkersDied+1
                CreateNotification(anomInst.AssignedWorker.Name.." died!",C.NeonRed)
                anomInst.AssignedWorker.AssignedTo=nil; anomInst.AssignedWorker=nil
            end
        end
    end
    -- MeatMess low mood attack
    if data.Special=="MeatMess" and anomInst.CurrentMood<30 and math.random()<0.3 and anomInst.AssignedWorker then
        anomInst.AssignedWorker.HP=0; GameData.WorkersDied=GameData.WorkersDied+1
        CreateNotification(anomInst.Name.." killed and ate "..anomInst.AssignedWorker.Name,C.NeonRed)
        anomInst.BonusBreachHealth=(anomInst.BonusBreachHealth or 0)+10
        anomInst.AssignedWorker.AssignedTo=nil; anomInst.AssignedWorker=nil
    end

    if anomInst.CurrentMood<=0 then
        if data.IsInanimate and anomInst.AssignedWorker then
            anomInst.AssignedWorker.HP=0; GameData.WorkersDied=GameData.WorkersDied+1
            CreateNotification(anomInst.Name.." killed the worker!",C.NeonRed)
            anomInst.AssignedWorker.AssignedTo=nil; anomInst.AssignedWorker=nil
            anomInst.CurrentMood=data.BaseMood/2
        else
            TriggerBreach(anomInst,nil)
        end
    elseif not success and math.random()<(data.BreachChance*3) then
        TriggerBreach(anomInst,nil)
    elseif success and math.random()<data.BreachChance then
        TriggerBreach(anomInst,nil)
    end

    UpdateRoomDisplay(anomInst)
end

-- Worker auto-loop
function StartWorkerLoop(worker, anomInst)
    spawn(function()
        while worker.AssignedTo==anomInst and worker.HP>0 and not anomInst.IsBreached do
            wait(5/(worker.SpeedMultiplier or 1))
            if not (worker.AssignedTo==anomInst and worker.HP>0 and not anomInst.IsBreached) then break end
            local workTypes = {}
            for k,_ in pairs(anomInst.Data.WorkResults) do table.insert(workTypes,k) end
            if #workTypes>0 then
                local wt = workTypes[math.random(#workTypes)]
                PerformWork(anomInst, wt)
            end
        end
    end)
end
-- ══════════════════════ CREATE ANOMALY ROOM ══════════════════════
function CreateAnomalyRoom(anomalyName)
    local data = AnomalyDatabase[anomalyName]
    if not data then return end

    local unlocked = {
        Stat=false, Knowledge=false, Social=false, Hunt=false, Passive=false,
        BreachForm=data.BreachForm==nil,
        Enemies=data.Costs==nil or data.Costs.Enemies==nil,
        BlessCurse=false, Management={}
    }
    if data.MXWeapon then unlocked.MXWeapon=false end
    if data.MXArmor  then unlocked.MXArmor=false  end
    for i=1,data.ManagementTips and #data.ManagementTips or 0 do unlocked.Management[i]=false end

    local anomInst = {
        Name=anomalyName, CurrentMood=data.BaseMood, Data=data,
        AssignedWorker=nil, AssignedGuards={}, IsBreached=false,
        BonusBreachHealth=0, ToBeExecuted=false,
        SuccessfulWorkerWorks=0, IsBored=false, IsHelping=false,
        Unlocked=unlocked, Room3D=nil, Billboard=nil,
    }

    -- Build 3D room
    local r3d = BuildRoom3D(anomalyName)
    anomInst.Room3D = r3d

    -- Billboard above the orb for HUD info
    local bb = {}
    local bbGui = Instance.new("BillboardGui")
    bbGui.Size = UDim2.new(0,180,0,60)
    bbGui.StudsOffset = Vector3.new(0, 4.5, 0)
    bbGui.AlwaysOnTop = false
    bbGui.Parent = r3d.Orb
    -- Name row
    local nameL = CI("TextLabel",{Parent=bbGui,BackgroundTransparency=1,
        Size=UDim2.new(1,0,0.5,0),Text=unlocked.Stat and anomalyName or "???",
        Font=Enum.Font.GothamBold,TextSize=13,
        TextColor3=r3d.DangerColor,TextStrokeTransparency=0.3})
    -- Mood bar container
    local moodBBbg=CI("Frame",{Parent=bbGui,BackgroundColor3=Color3.fromRGB(35,35,35),
        BorderSizePixel=0,Size=UDim2.new(1,-4,0,10),Position=UDim2.new(0,2,0.52,0)})
    CI("UICorner",{Parent=moodBBbg,CornerRadius=UDim.new(1,0)})
    local moodFill=CI("Frame",{Parent=moodBBbg,Name="Fill",
        BackgroundColor3=Color3.fromRGB(50,200,50),BorderSizePixel=0,
        Size=UDim2.new(data.BaseMood/100,0,1,0)})
    CI("UICorner",{Parent=moodFill,CornerRadius=UDim.new(1,0)})
    bb.NameLabel = nameL; bb.MoodFill = moodFill
    anomInst.Billboard = bb

    -- In-room 2D panel (attached to workspace, shown as ScreenGui overlay room card)
    -- We create a small ScreenGui card per anomaly room
    local roomGui = CI("Frame",{Parent=MainGui,BackgroundColor3=Color3.fromRGB(10,10,22),
        BorderSizePixel=0,ZIndex=15,Visible=false,
        Size=isMobile and UDim2.new(0.96,0,0.94,0) or UDim2.new(0,440,0,500),
        Position=isMobile and UDim2.new(0.02,0,0.03,0) or UDim2.new(0.5,-220,0.5,-250)})
    CI("UICorner",{Parent=roomGui,CornerRadius=UDim.new(0,10)})
    CI("UIStroke",{Parent=roomGui,Color=r3d.DangerColor,Thickness=1.5})

    local rTitle = CI("TextLabel",{Parent=roomGui,BackgroundColor3=Color3.fromRGB(8,8,20),BorderSizePixel=0,
        Size=UDim2.new(1,0,0,38),
        Text=(unlocked.Stat and anomalyName:upper() or "[UNCLASSIFIED]").." — Class "..data.DangerClass,
        Font=Enum.Font.GothamBold,TextSize=15,TextColor3=r3d.DangerColor})
    CI("UIStroke",{Parent=rTitle,Color=r3d.DangerColor,Thickness=0.8})

    local closeR=CI("TextButton",{Parent=roomGui,BackgroundColor3=Color3.fromRGB(140,20,20),
        BorderSizePixel=0,Size=UDim2.new(0,32,0,32),Position=UDim2.new(1,-36,0,3),
        Text="✕",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=Color3.fromRGB(255,255,255),ZIndex=16})
    CI("UICorner",{Parent=closeR,CornerRadius=UDim.new(0,6)})
    closeR.MouseButton1Click:Connect(function() roomGui.Visible=false end)

    -- Mood bar in card
    local mBG=CI("Frame",{Parent=roomGui,BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0,
        Size=UDim2.new(1,-30,0,16),Position=UDim2.new(0,15,0,44)})
    CI("UICorner",{Parent=mBG,CornerRadius=UDim.new(0,8)})
    local mFill=CI("Frame",{Parent=mBG,Name="MoodFill",BackgroundColor3=Color3.fromRGB(50,200,50),
        BorderSizePixel=0,Size=UDim2.new(data.BaseMood/100,0,1,0)})
    CI("UICorner",{Parent=mFill,CornerRadius=UDim.new(0,8)})
    local mLbl=CI("TextLabel",{Parent=roomGui,BackgroundTransparency=1,
        Size=UDim2.new(1,-30,0,18),Position=UDim2.new(0,15,0,62),
        Text="Mood: "..data.BaseMood.."/100",Font=Enum.Font.Gotham,TextSize=13,
        TextColor3=Color3.fromRGB(200,200,200),TextXAlignment=Enum.TextXAlignment.Left})
    local staffLbl=CI("TextLabel",{Parent=roomGui,BackgroundTransparency=1,
        Size=UDim2.new(1,-30,0,18),Position=UDim2.new(0,15,0,82),
        Text="Worker: — | Guards: — & —",Font=Enum.Font.Gotham,TextSize=13,
        TextColor3=Color3.fromRGB(180,180,180),TextXAlignment=Enum.TextXAlignment.Left})

    -- Work buttons / Fate Use button
    local btnY = 106
    if data.Special ~= "FateDecides" then
        local workTypes = {"Knowledge","Social","Hunt","Passive"}
        local wColors   = {Color3.fromRGB(20,60,160),Color3.fromRGB(20,120,60),Color3.fromRGB(160,60,20),Color3.fromRGB(80,20,140)}
        for i,wt in ipairs(workTypes) do
            local wr = data.WorkResults[wt]
            if wr then
                local col = (i-1)%2; local row2 = math.floor((i-1)/2)
                local wb=CI("TextButton",{Parent=roomGui,BackgroundColor3=wColors[i],BorderSizePixel=0,
                    Size=UDim2.new(0.46,0,0,46),
                    Position=UDim2.new(col*0.5+0.02,0,0,btnY+row2*54),
                    Text=wt.."\n✓ "..math.floor(wr.Success*100).."% | ◈ "..wr.Crucible,
                    Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(255,255,255)})
                CI("UICorner",{Parent=wb,CornerRadius=UDim.new(0,8)})
                CI("UIStroke",{Parent=wb,Color=wColors[i],Thickness=0.8})
                local wt2=wt
                wb.MouseButton1Click:Connect(function() PerformWork(anomInst,wt2) end)
                anomInst["WBtn_"..wt] = wb
            end
        end
        btnY = btnY + 116
    else
        local ub=CI("TextButton",{Parent=roomGui,BackgroundColor3=Color3.fromRGB(80,40,120),BorderSizePixel=0,
            Size=UDim2.new(0.94,0,0,46),Position=UDim2.new(0.03,0,0,btnY),
            Text="☯ Use Fate (once/day)",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.fromRGB(255,255,255)})
        CI("UICorner",{Parent=ub,CornerRadius=UDim.new(0,8)})
        ub.MouseButton1Click:Connect(function()
            if GameData.FateUsedToday then CreateNotification("Already used today!",C.NeonRed) return end
            ShowFateGUI(anomInst)
        end)
        btnY = btnY + 54
    end

    -- Info, Assign, Execute buttons
    local function ActionBtn(txt, col, yOff, action)
        local b=CI("TextButton",{Parent=roomGui,BackgroundColor3=col,BorderSizePixel=0,
            Size=UDim2.new(0.94,0,0,40),Position=UDim2.new(0.03,0,0,yOff),
            Text=txt,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.fromRGB(255,255,255)})
        CI("UICorner",{Parent=b,CornerRadius=UDim.new(0,8)})
        b.MouseButton1Click:Connect(action); return b
    end
    ActionBtn("ℹ Info & Unlock",         Color3.fromRGB(40,40,90),  btnY,    function() ShowAnomalyInfo(anomInst) end)
    ActionBtn("👥 Workers & Guards",      Color3.fromRGB(30,60,100), btnY+48, function() PopulateAssignGui(anomInst) end)
    ActionBtn("⚡ Execute",               Color3.fromRGB(130,20,20), btnY+96, function()
        if not anomInst.IsBreached then
            anomInst.ToBeExecuted=true
            TriggerBreach(anomInst,nil)
        end
    end)

    -- Update function for this room card
    anomInst.UpdateCard = function()
        local m = anomInst.CurrentMood/100
        local mc = m>0.5 and Color3.fromRGB(50,200,50) or (m>0.2 and Color3.fromRGB(220,160,30) or Color3.fromRGB(220,40,40))
        TweenService:Create(mFill,TweenInfo.new(0.3),{Size=UDim2.new(m,0,1,0),BackgroundColor3=mc}):Play()
        mLbl.Text = "Mood: "..anomInst.CurrentMood.."/100"
        local w1 = anomInst.AssignedWorker and anomInst.AssignedWorker.Name or "—"
        local g1 = anomInst.AssignedGuards[1] and anomInst.AssignedGuards[1].Name or "—"
        local g2 = anomInst.AssignedGuards[2] and anomInst.AssignedGuards[2].Name or "—"
        staffLbl.Text = "Worker: "..w1.." | Guards: "..g1.." & "..g2
        if anomInst.IsBreached then
            rTitle.Text = "⚠ BREACH — "..(anomInst.Data.BreachForm and anomInst.Data.BreachForm.Name or anomalyName)
            rTitle.TextColor3 = C.NeonRed
        else
            rTitle.Text = (unlocked.Stat and anomalyName:upper() or "[UNCLASSIFIED]").." — Class "..data.DangerClass
            rTitle.TextColor3 = r3d.DangerColor
        end
    end

    -- Patch UpdateRoomDisplay to also call UpdateCard
    local origUpdate = UpdateRoomDisplay
    anomInst.RoomGui = roomGui

    table.insert(GameData.OwnedAnomalies, anomInst)

    -- Orb click-to-open panel
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 60
    clickDetector.Parent = r3d.Orb
    clickDetector.MouseClick:Connect(function()
        -- Close all other room guis
        for _,a in ipairs(GameData.OwnedAnomalies) do
            if a.RoomGui and a~=anomInst then a.RoomGui.Visible=false end
        end
        anomInst.UpdateCard()
        roomGui.Visible = not roomGui.Visible
    end)

    -- Passive mood decay loop
    spawn(function()
        while not anomInst.IsBreached do
            wait(8)
            if anomInst.IsBreached then break end
            if not (data.NoMoodMeter) then
                local decay = 3
                if anomInst.IsBored then decay=6 end
                anomInst.CurrentMood = math.clamp(anomInst.CurrentMood - decay, 0, 100)
                UpdateRoomDisplay(anomInst)
                if anomInst.UpdateCard then anomInst.UpdateCard() end
                if anomInst.CurrentMood<=0 and not data.NoBreach then
                    TriggerBreach(anomInst,nil)
                end
            end
        end
    end)

    -- FateDecides timed mood decay
    if data.Special=="FateDecides" then
        spawn(function()
            while not anomInst.IsBreached do
                wait(60)
                anomInst.CurrentMood=math.clamp(anomInst.CurrentMood-5,0,100)
                UpdateRoomDisplay(anomInst)
                if anomInst.CurrentMood<=0 then TriggerBreach(anomInst,nil) end
            end
        end)
    end

    -- PrinceOfFame bored mode
    if data.Special=="PrinceOfFame" then
        spawn(function()
            while not anomInst.IsBreached do
                wait(10)
                local noBreachFor = os.time()-GameData.LastGlobalBreachTime
                if noBreachFor>600 and not anomInst.IsBored then
                    anomInst.IsBored=true
                    CreateNotification("Prince of Fame is bored! Work fails doubled.",Color3.fromRGB(200,140,0))
                end
                if anomInst.IsBored and anomInst.CurrentMood<=0 then
                    TriggerBreach(anomInst,nil)
                end
            end
        end)
    end

    UpdateRoomDisplay(anomInst)
    CreateNotification("Anomaly accepted: "..anomalyName, Color3.fromRGB(50,180,80))
end

-- Wrap UpdateRoomDisplay to also trigger card update
local _origUpdateRoomDisplay = UpdateRoomDisplay
function UpdateRoomDisplay(anomInst)
    _origUpdateRoomDisplay(anomInst)
    if anomInst.UpdateCard then anomInst.UpdateCard() end
end
-- ══════════════════════ DOCUMENT / ANOMALY SELECTION ══════════════════════
local DocGui, DocBody, DocLayout = MakePanel("Anomaly Documents", 480, 420)

local function GenerateRandomDocuments()
    local keys={}; for k in pairs(AnomalyDatabase) do table.insert(keys,k) end
    local chosen={}; local used={}
    while #chosen<3 and #keys>0 do
        local idx=math.random(#keys)
        local k=keys[idx]
        if not used[k] then
            -- check not already owned
            local owned=false
            for _,a in ipairs(GameData.OwnedAnomalies) do if a.Name==k then owned=true break end end
            if not owned then table.insert(chosen,k); used[k]=true end
        end
        table.remove(keys,idx)
        if #keys==0 then break end
    end
    while #chosen<3 do table.insert(chosen,"Crying Eyeball") end
    return chosen
end

local selectedDoc = nil

local function PopulateDocGui()
    for _,c in pairs(DocBody:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    selectedDoc = nil
    for i,docName in ipairs(GameData.CurrentDocuments) do
        local data   = AnomalyDatabase[docName]
        local dCol   = DangerColors[data.DangerClass] or Color3.fromRGB(150,150,200)
        local docCard = CI("Frame",{Parent=DocBody,BackgroundColor3=Color3.fromRGB(14,14,28),
            BorderSizePixel=0,Size=UDim2.new(1,-10,0,100)})
        CI("UICorner",{Parent=docCard,CornerRadius=UDim.new(0,9)})
        CI("UIStroke",{Parent=docCard,Color=dCol,Thickness=1.2})
        CI("TextLabel",{Parent=docCard,BackgroundTransparency=1,
            Size=UDim2.new(1,-10,0,28),Position=UDim2.new(0,8,0,4),
            Text="Document "..i.." — [REDACTED]",Font=Enum.Font.GothamBold,TextSize=15,
            TextColor3=dCol,TextXAlignment=Enum.TextXAlignment.Left})
        CI("TextLabel",{Parent=docCard,BackgroundTransparency=1,
            Size=UDim2.new(1,-10,0,52),Position=UDim2.new(0,8,0,32),
            Text=data.Description,Font=Enum.Font.Gotham,TextSize=13,
            TextColor3=Color3.fromRGB(180,180,200),TextXAlignment=Enum.TextXAlignment.Left,
            TextWrapped=true})
        local selBtn=CI("TextButton",{Parent=docCard,BackgroundColor3=Color3.fromRGB(30,80,160),
            BorderSizePixel=0,Size=UDim2.new(0,90,0,28),Position=UDim2.new(1,-98,0,68),
            Text="Select",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.fromRGB(255,255,255)})
        CI("UICorner",{Parent=selBtn,CornerRadius=UDim.new(0,6)})
        local docName2=docName; local docCard2=docCard
        selBtn.MouseButton1Click:Connect(function()
            selectedDoc=docName2
            for _,c2 in pairs(DocBody:GetChildren()) do
                if c2:IsA("Frame") then
                    local s=c2:FindFirstChildOfClass("UIStroke")
                    if s then s.Color=dCol; s.Thickness=1.2 end
                end
            end
            local st=docCard2:FindFirstChildOfClass("UIStroke")
            if st then st.Color=C.NeonGold; st.Thickness=2.5 end
            selBtn.BackgroundColor3=Color3.fromRGB(10,120,40); selBtn.Text="✓ Selected"
        end)
    end
    -- Accept / Decline / Reroll
    local row=CI("Frame",{Parent=DocBody,BackgroundTransparency=1,Size=UDim2.new(1,-10,0,46)})
    local accBtn=CI("TextButton",{Parent=row,BackgroundColor3=Color3.fromRGB(20,120,40),BorderSizePixel=0,
        Size=UDim2.new(0.3,0,1,0),Position=UDim2.new(0,0,0,0),
        Text="Accept",Font=Enum.Font.GothamBold,TextSize=15,TextColor3=Color3.fromRGB(255,255,255)})
    CI("UICorner",{Parent=accBtn,CornerRadius=UDim.new(0,8)})
    local decBtn=CI("TextButton",{Parent=row,BackgroundColor3=Color3.fromRGB(140,20,20),BorderSizePixel=0,
        Size=UDim2.new(0.3,0,1,0),Position=UDim2.new(0.35,0,0,0),
        Text="Decline",Font=Enum.Font.GothamBold,TextSize=15,TextColor3=Color3.fromRGB(255,255,255)})
    CI("UICorner",{Parent=decBtn,CornerRadius=UDim.new(0,8)})
    local reBtn=CI("TextButton",{Parent=row,BackgroundColor3=Color3.fromRGB(60,60,100),BorderSizePixel=0,
        Size=UDim2.new(0.3,0,1,0),Position=UDim2.new(0.7,0,0,0),
        Text="Reroll ◈100",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.fromRGB(255,255,255)})
    CI("UICorner",{Parent=reBtn,CornerRadius=UDim.new(0,8)})
    accBtn.MouseButton1Click:Connect(function()
        if not selectedDoc then CreateNotification("Select a document first!",C.NeonRed) return end
        if GameData.AnomaliesAcceptedToday>=1 then CreateNotification("Only 1 anomaly per day!",C.NeonRed) return end
        CreateAnomalyRoom(selectedDoc)
        GameData.AnomaliesAcceptedToday=GameData.AnomaliesAcceptedToday+1
        DocGui.Visible=false; selectedDoc=nil
    end)
    decBtn.MouseButton1Click:Connect(function()
        selectedDoc=nil; DocGui.Visible=false
    end)
    reBtn.MouseButton1Click:Connect(function()
        if GameData.Crucible<100 then CreateNotification("Not enough Crucible!",C.NeonRed) return end
        UpdateCrucible(-100); RefreshCrucibleDisplay()
        GameData.CurrentDocuments=GenerateRandomDocuments()
        PopulateDocGui()
        CreateNotification("Documents rerolled!",Color3.fromRGB(100,180,255))
    end)
    DocBody.CanvasSize=UDim2.new(0,0,0,DocLayout.AbsoluteContentSize.Y+20)
end

BuyDocBtn.MouseButton1Click:Connect(function()
    if GameData.DocumentsPurchasedToday then CreateNotification("Already purchased today!",C.NeonRed) return end
    if GameData.Crucible<100 then CreateNotification("Not enough Crucible!",C.NeonRed) return end
    UpdateCrucible(-100); RefreshCrucibleDisplay()
    GameData.CurrentDocuments=GenerateRandomDocuments()
    GameData.DocumentsPurchasedToday=true
    PopulateDocGui(); DocGui.Visible=true
    CreateNotification("Documents purchased!",Color3.fromRGB(50,200,80))
end)

-- ══════════════════════ TERMINATOR PROTOCOL ══════════════════════
TerminatorBtn.MouseButton1Click:Connect(function()
    local anyBreach=false
    for _,a in ipairs(GameData.OwnedAnomalies) do if a.IsBreached then anyBreach=true break end end
    if not anyBreach then CreateNotification("No active breach to respond to!",C.NeonRed) return end
    if GameData.TerminatorActive then CreateNotification("Terminator already active!",C.NeonRed) return end
    if GameData.Crucible<35000 then CreateNotification("Need ◈35000 for Terminator!",C.NeonRed) return end
    UpdateCrucible(-35000); RefreshCrucibleDisplay()
    GameData.TerminatorAgents = {
        {Name="Agent Aisyah",     HP=3500, MaxHP=3500, Damage=500},
        {Name="Agent Blake",      HP=4000, MaxHP=4000, Damage=350},
        {Name="Agent Tyler",      HP=3750, MaxHP=3750, Damage=450},
        {Name="Agent Toby",       HP=3000, MaxHP=3000, Damage=750},
        {Name="Agent Anastasia",  HP=4300, MaxHP=4300, Damage=530},
        {Name="Agent Elmer",      HP=6000, MaxHP=6000, Damage=600},
        {Name="Juggernaut Paul",  HP=9000, MaxHP=9000, Damage=1000},
        {Name="Juggernaut Dexter",HP=10000,MaxHP=10000,Damage=1500},
        {Name="Commander Britney",HP=17500,MaxHP=17500,Damage=3000},
    }
    GameData.TerminatorActive=true
    CreateNotification("⚡ TERMINATOR PROTOCOL ACTIVATED!",C.NeonRed,Color3.fromRGB(255,255,255))
    -- Spawn agent NPCs in corridor
    for i,agent in ipairs(GameData.TerminatorAgents) do
        local col = i<=6 and C.Agent or (i<=8 and C.Jugg or C.Cmdr)
        local pos = Vector3.new(-CORR_LEN/2+10+(i-1)*8, FLOOR_Y+1, 0)
        local npc = MakeNPC(pos, col, agent.Name)
        agent.NPC = npc
        -- March toward the nearest breach
        spawn(function()
            wait(i*0.3)
            local target = Vector3.new(CORR_LEN/4, FLOOR_Y+1, 0)
            AnimateNPCWalk(npc, pos, target, 0.028, nil)
        end)
    end
end)

-- ══════════════════════ END DAY / DAY CYCLE ══════════════════════
local EndDayGui = CI("Frame",{Parent=MainGui,BackgroundColor3=Color3.fromRGB(5,5,15),BorderSizePixel=0,
    Visible=false,ZIndex=50,
    Size=isMobile and UDim2.new(0.97,0,0.94,0) or UDim2.new(0,440,0,420),
    Position=isMobile and UDim2.new(0.015,0,0.03,0) or UDim2.new(0.5,-220,0.5,-210)})
CI("UICorner",{Parent=EndDayGui,CornerRadius=UDim.new(0,12)})
CI("UIStroke",{Parent=EndDayGui,Color=C.NeonGold,Thickness=2})
local edTitle=CI("TextLabel",{Parent=EndDayGui,BackgroundColor3=Color3.fromRGB(8,8,18),BorderSizePixel=0,
    Size=UDim2.new(1,0,0,42),Text="END OF DAY "..GameData.CurrentDay,
    Font=Enum.Font.GothamBold,TextSize=20,TextColor3=C.NeonGold})
local edBody=CI("Frame",{Parent=EndDayGui,BackgroundTransparency=1,
    Size=UDim2.new(1,-30,0,260),Position=UDim2.new(0,15,0,50)})
local edLayout=CI("UIListLayout",{Parent=edBody,Padding=UDim.new(0,8)})
local edCont=CI("TextButton",{Parent=EndDayGui,BackgroundColor3=Color3.fromRGB(20,120,40),BorderSizePixel=0,
    Size=UDim2.new(0.7,0,0,46),Position=UDim2.new(0.15,0,1,-56),
    Text="→ Continue to Day "..(GameData.CurrentDay+1),Font=Enum.Font.GothamBold,TextSize=16,
    TextColor3=Color3.fromRGB(255,255,255)})
CI("UICorner",{Parent=edCont,CornerRadius=UDim.new(0,8)})

local function ShowEndDayScreen()
    edTitle.Text="END OF DAY "..GameData.CurrentDay
    edCont.Text="→ Continue to Day "..(GameData.CurrentDay+1)
    for _,c in pairs(edBody:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
    local function Stat(txt, col)
        CI("TextLabel",{Parent=edBody,BackgroundTransparency=1,Size=UDim2.new(1,0,0,34),
            Text=txt,Font=Enum.Font.Gotham,TextSize=15,
            TextColor3=col or Color3.fromRGB(200,200,200)})
    end
    Stat("Day "..GameData.CurrentDay.." Summary",C.NeonGold)
    Stat("◈ Crucible earned: "..GameData.DailyCrucible, Color3.fromRGB(255,200,50))
    local q=Quotas[math.min(GameData.CurrentDay,#Quotas)]
    Stat("Quota: "..GameData.DailyCrucible.."/"..q, GameData.DailyCrucible>=q and Color3.fromRGB(50,220,80) or C.NeonRed)
    Stat("⚠ Total Breaches: "..GameData.TotalBreaches, Color3.fromRGB(255,120,50))
    Stat("💀 Workers died: "..GameData.WorkersDied, Color3.fromRGB(220,100,100))
    Stat("🛡 Guards died: "..GameData.GuardsDied, Color3.fromRGB(200,150,100))
    Stat("Core HP: "..GameData.CosmicShardCoreHealth.."/"..GameData.MaxCoreHealth, Color3.fromRGB(100,200,255))
    EndDayGui.Visible=true
end

edCont.MouseButton1Click:Connect(function()
    GameData.CurrentDay=GameData.CurrentDay+1
    GameData.DailyCrucible=0; GameData.AnomaliesAcceptedToday=0
    GameData.DocumentsPurchasedToday=false; GameData.FateUsedToday=false
    DayLabel.Text="Day: "..GameData.CurrentDay
    UpdateQuotaDisplay(); EndDayGui.Visible=false
    -- Raid check
    local raidDays={[5]="Troposphere",[10]="Stratosphere",[25]="Mesosphere",[50]="Thermosphere",[75]="Exosphere"}
    local sphere=raidDays[GameData.CurrentDay]
    if sphere and RaidDatabase[sphere] and #RaidDatabase[sphere]>0 then
        StartRaid(sphere)
    end
end)

EndDayBtn.MouseButton1Click:Connect(function()
    local q=Quotas[math.min(GameData.CurrentDay,#Quotas)]
    if GameData.DailyCrucible<q then CreateNotification("Quota not reached!",C.NeonRed) return end
    ShowEndDayScreen()
end)

-- ══════════════════════ RAID SYSTEM ══════════════════════
function StartRaid(sphere)
    local raidList = RaidDatabase[sphere]
    if not raidList or #raidList==0 then return end
    local raid = raidList[math.random(#raidList)]
    GameData.CurrentRaid=raid
    CreateNotification("⚔ RAID! ["..raid.name.."] "..raid.quote, raid.color, Color3.fromRGB(255,255,255))

    -- Summon raid NPCs from right end of corridor
    local entities={}
    for _,anom in ipairs(raid.anomalies) do
        for i=1,anom.count do
            local pos=Vector3.new(CORR_LEN/2-5, FLOOR_Y+1, math.random(-3,3))
            local npc=MakeNPC(pos, raid.color, anom.name.." "..i)
            local ent={NPC=npc,HP=anom.hp,MaxHP=anom.hp,Damage=anom.dmg,Name=anom.name.." "..i}
            table.insert(entities,ent); table.insert(GameData.RaidEntities,ent)
            -- march inward
            spawn(function()
                wait(i*0.2)
                AnimateNPCWalk(npc, pos, Vector3.new(0,FLOOR_Y+1,math.random(-3,3)), 0.03, nil)
            end)
        end
    end

    -- Raid combat loop
    spawn(function()
        while #GameData.RaidEntities>0 do
            wait(2)
            -- Outer guards fight
            for _,g in ipairs(GameData.OuterGuards) do
                if g.HP>0 and #GameData.RaidEntities>0 then
                    local tgt=GameData.RaidEntities[math.random(#GameData.RaidEntities)]
                    tgt.HP=tgt.HP-g.Damage
                    if tgt.HP<=0 then
                        CreateNotification(g.Name.." eliminated "..tgt.Name.."!",Color3.fromRGB(50,200,80))
                        if tgt.NPC and tgt.NPC.Torso then tgt.NPC.Torso.Color=Color3.fromRGB(80,80,80) end
                        for i=#GameData.RaidEntities,1,-1 do if GameData.RaidEntities[i]==tgt then table.remove(GameData.RaidEntities,i) break end end
                    end
                end
            end
            -- Raid attacks outer guards / core
            if #GameData.RaidEntities>0 then
                local raider=GameData.RaidEntities[math.random(#GameData.RaidEntities)]
                if #GameData.OuterGuards>0 then
                    local og=GameData.OuterGuards[math.random(#GameData.OuterGuards)]
                    og.HP=og.HP-raider.Damage
                    if og.NPC and og.NPC.HPFill then og.NPC.HPFill.Size=UDim2.new(og.HP/og.MaxHP,0,1,0) end
                    if og.HP<=0 then
                        CreateNotification(raider.Name.." killed outer guard "..og.Name.."!",C.NeonRed)
                        for i=#GameData.OuterGuards,1,-1 do if GameData.OuterGuards[i]==og then table.remove(GameData.OuterGuards,i) break end end
                        GameData.GuardsDied=GameData.GuardsDied+1
                    end
                else
                    GameData.CosmicShardCoreHealth=GameData.CosmicShardCoreHealth-raider.Damage
                    UpdateCoreLabel()
                    CreateNotification("Raider "..raider.Name.." damaged core! HP:"..GameData.CosmicShardCoreHealth, C.NeonRed)
                end
            end
        end
        GameData.CurrentRaid=nil; GameData.RaidEntities={}
        CreateNotification("✓ Raid repelled!",Color3.fromRGB(50,220,80))
    end)
end

-- ══════════════════════ WHITE TRAIN ══════════════════════
local function StartWhiteTrain()
    GameData.WhiteTrainActive=true
    CreateNotification("🚂 The White Train approaches...",Color3.fromRGB(220,220,220))
    -- Animate a white train part across the corridor
    local train=MP(Vector3.new(24,5,6), CFrame.new(-CORR_LEN/2-15,FLOOR_Y+3,0),
        Color3.fromRGB(230,230,240),false,false,FacilityFolder)
    NeonStrip(CFrame.new(-CORR_LEN/2-15,FLOOR_Y+3,0),Vector3.new(24,0.2,0.2),C.NeonWht,FacilityFolder)
    local trainLight=MakePart and train -- reuse part ref

    spawn(function()
        local t=0
        while t<CORR_LEN+50 do
            wait(0.04)
            t=t+3.5
            train.CFrame=CFrame.new(-CORR_LEN/2-15+t, FLOOR_Y+3, 0)
        end
        train:Destroy()
        GameData.WhiteTrainActive=false
        -- Reward
        local bonus=math.random(100,400)
        UpdateCrucible(bonus); RefreshCrucibleDisplay(); UpdateQuotaDisplay()
        CreateNotification("White Train passed! +"..bonus.." ◈",Color3.fromRGB(220,220,220))
    end)

    -- Schedule next
    spawn(function()
        wait(math.random(120,240))
        StartWhiteTrain()
    end)
end
-- ══════════════════════ CAMERA SYSTEM ══════════════════════
-- Isometric / strategic camera (like Tuantu) orbiting the facility
local camAngleY   = 35   -- horizontal rotation
local camAngleX   = -48  -- vertical tilt (degrees)
local camDist     = 90
local camTarget   = Vector3.new(0, FLOOR_Y+4, 0)
local camDragging = false
local camLastMouse= nil

camera.CameraType = Enum.CameraType.Scriptable

local function ApplyCamera()
    local rad_x = math.rad(camAngleX)
    local rad_y = math.rad(camAngleY)
    local offset = Vector3.new(
        camDist * math.cos(rad_x) * math.sin(rad_y),
        camDist * math.sin(-rad_x),
        camDist * math.cos(rad_x) * math.cos(rad_y)
    )
    local camPos = camTarget + offset
    camera.CFrame = CFrame.new(camPos, camTarget)
end

-- Mouse/Touch drag to orbit
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2 then
        camDragging=true; camLastMouse=input.Position
    elseif input.UserInputType==Enum.UserInputType.Touch then
        camDragging=true; camLastMouse=input.Position
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton2
    or input.UserInputType==Enum.UserInputType.Touch then
        camDragging=false; camLastMouse=nil
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if camDragging and camLastMouse then
        if input.UserInputType==Enum.UserInputType.MouseMovement
        or input.UserInputType==Enum.UserInputType.Touch then
            local delta = input.Position - camLastMouse
            camAngleY   = camAngleY + delta.X * 0.4
            camAngleX   = math.clamp(camAngleX + delta.Y * 0.3, -80, -10)
            camLastMouse= input.Position
            ApplyCamera()
        end
    end
    -- Scroll to zoom
    if input.UserInputType==Enum.UserInputType.MouseWheel then
        camDist = math.clamp(camDist - input.Position.Z * 6, 30, 200)
        ApplyCamera()
    end
end)

-- WASD / arrow keys pan
local camPanKeys = {
    [Enum.KeyCode.W]=Vector3.new(0,0,-1),
    [Enum.KeyCode.S]=Vector3.new(0,0, 1),
    [Enum.KeyCode.A]=Vector3.new(-1,0,0),
    [Enum.KeyCode.D]=Vector3.new( 1,0,0),
    [Enum.KeyCode.Up]   =Vector3.new(0,0,-1),
    [Enum.KeyCode.Down] =Vector3.new(0,0, 1),
    [Enum.KeyCode.Left] =Vector3.new(-1,0,0),
    [Enum.KeyCode.Right]=Vector3.new( 1,0,0),
}
local heldKeys={}
UserInputService.InputBegan:Connect(function(input,gpe)
    if not gpe then heldKeys[input.KeyCode]=true end
end)
UserInputService.InputEnded:Connect(function(input)
    heldKeys[input.KeyCode]=nil
end)

-- Mobile pan buttons
if UserInputService.TouchEnabled then
    local panPad = CI("Frame",{Parent=MainGui,BackgroundTransparency=1,
        Size=UDim2.new(0,130,0,130),Position=UDim2.new(0,10,1,-150),ZIndex=30})
    local dirs = {
        {txt="▲",pos=UDim2.new(0.35,0,0,0),   move=Vector3.new(0,0,-1)},
        {txt="▼",pos=UDim2.new(0.35,0,0.65,0), move=Vector3.new(0,0,1)},
        {txt="◄",pos=UDim2.new(0,0,0.35,0),    move=Vector3.new(-1,0,0)},
        {txt="►",pos=UDim2.new(0.65,0,0.35,0), move=Vector3.new(1,0,0)},
    }
    for _,d in ipairs(dirs) do
        local btn=CI("TextButton",{Parent=panPad,BackgroundColor3=Color3.fromRGB(30,30,50),
            BackgroundTransparency=0.3,BorderSizePixel=0,
            Size=UDim2.new(0,40,0,40),Position=d.pos,Text=d.txt,
            Font=Enum.Font.GothamBold,TextSize=18,TextColor3=Color3.fromRGB(180,200,255),ZIndex=31})
        CI("UICorner",{Parent=btn,CornerRadius=UDim.new(0,8)})
        local mv=d.move
        btn.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch then heldKeys[mv]=true end
        end)
        btn.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch then heldKeys[mv]=nil end
        end)
    end
    -- Zoom in/out
    local zin=CI("TextButton",{Parent=MainGui,BackgroundColor3=Color3.fromRGB(30,30,50),
        BackgroundTransparency=0.3,BorderSizePixel=0,
        Size=UDim2.new(0,44,0,44),Position=UDim2.new(0,150,1,-80),
        Text="+",Font=Enum.Font.GothamBold,TextSize=22,TextColor3=Color3.fromRGB(180,200,255),ZIndex=31})
    CI("UICorner",{Parent=zin,CornerRadius=UDim.new(0,10)})
    zin.MouseButton1Click:Connect(function() camDist=math.max(30,camDist-8); ApplyCamera() end)
    local zout=CI("TextButton",{Parent=MainGui,BackgroundColor3=Color3.fromRGB(30,30,50),
        BackgroundTransparency=0.3,BorderSizePixel=0,
        Size=UDim2.new(0,44,0,44),Position=UDim2.new(0,200,1,-80),
        Text="−",Font=Enum.Font.GothamBold,TextSize=22,TextColor3=Color3.fromRGB(180,200,255),ZIndex=31})
    CI("UICorner",{Parent=zout,CornerRadius=UDim.new(0,10)})
    zout.MouseButton1Click:Connect(function() camDist=math.min(200,camDist+8); ApplyCamera() end)
end

-- RunService camera + key pan loop
RunService.Heartbeat:Connect(function(dt)
    local moved=false
    for key,dir in pairs(camPanKeys) do
        if heldKeys[key] then
            camTarget=camTarget + dir*dt*22; moved=true
        end
    end
    -- Mobile touch pan
    for key,dir in pairs(heldKeys) do
        if type(key)=="userdata" then -- Vector3 key from mobile buttons
            camTarget=camTarget + key*dt*22; moved=true
        end
    end
    if moved then ApplyCamera() end
end)

-- Initial camera position
ApplyCamera()

-- ══════════════════════ AMBIENT MOOD LIGHTING ══════════════════════
-- Subtly shift workspace lighting based on breach state
local Lighting = game:GetService("Lighting")
Lighting.Ambient = Color3.fromRGB(5,5,15)
Lighting.OutdoorAmbient = Color3.fromRGB(5,5,15)
Lighting.Brightness = 0.8

local function UpdateGlobalMoodLighting()
    local anyBreach = false
    for _,a in ipairs(GameData.OwnedAnomalies) do if a.IsBreached then anyBreach=true break end end
    local targetAmb = anyBreach and Color3.fromRGB(30,5,5) or Color3.fromRGB(5,5,15)
    TweenService:Create(Lighting, TweenInfo.new(1), {Ambient=targetAmb}):Play()
end

-- ══════════════════════ MAIN UPDATE LOOP ══════════════════════
RunService.Heartbeat:Connect(function()
    -- Keep facility locked in world (clean up floating parts if needed)
end)

-- Update breach alert + lighting every second
spawn(function()
    while true do
        wait(1)
        UpdateBreachAlert()
        UpdateGlobalMoodLighting()
        -- Pulse breach alert label
        if BreachAlert.Visible then
            TweenService:Create(BreachAlert,TweenInfo.new(0.4),{
                BackgroundColor3=Color3.fromRGB(math.random(130,180),0,0)
            }):Play()
        end
    end
end)

-- ══════════════════════ INITIALIZE ══════════════════════
wait(0.5)
CreateNotification("❖ Welcome to SORCHESUS COMPANY 3D", Color3.fromRGB(200,40,40))
wait(1.2)
CreateNotification("Click anomaly orbs to open room panels", Color3.fromRGB(80,130,220))
wait(1.2)
CreateNotification("Right-click drag to orbit. Scroll to zoom. WASD to pan.", Color3.fromRGB(100,100,180))

-- Start white train
wait(3)
StartWhiteTrain()
UpdateQuotaDisplay()
UpdateCoreLabel()

-- Spawn a few starter patrol workers and guards in HQ visually
for i=1,2 do
    wait(0.15)
    local pos=Vector3.new(HQ_OFFSET+math.random(-10,10),FLOOR_Y+1,math.random(-8,8))
    local npc=MakeNPC(pos, C.Worker, "Worker")
    StartNPCPatrol(npc, C.Worker)
end
for i=1,3 do
    wait(0.1)
    local pos=Vector3.new(HQ_OFFSET+math.random(-8,8),FLOOR_Y+1,math.random(-8,8))
    local npc=MakeNPC(pos, C.Guard, "Guard")
    StartNPCPatrol(npc, C.Guard)
end

print("✔ Sorchesus Company 3D loaded successfully!")
