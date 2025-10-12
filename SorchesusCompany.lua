-- Sorchesus Company - Complete Client-Side GUI Script
-- Fixed Crucible updates and added Yin, Yang, and ERROR anomalies
-- Modified for mobile friendliness
-- Updated with new anomalies, outer guard, mood decreases, and adjusted worker intervals
-- Fixed errors: nil.HP and sub on nil
-- Added Execute button and Terminator Protocol button
-- Changed Apocalypse Herald starter mood to 45
-- Updated Terminator Protocol to spawn temporary agents that attack with priority and wipe anomalies
-- Modifications: Prevent terminator button and crucible text from merging with horizontal scroll, change terminator to contain instead of kill, added base system

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local isMobile = UserInputService.TouchEnabled

-- Employee Database from the list
local EmployeeDatabase = {
    ["Unlucky Worker"] = {cost = 500, hp = 60, success = 0.1, type = "Worker"},
    ["Normal Worker"] = {cost = 850, hp = 90, success = 0.23, type = "Worker"},
    ["Smart Worker"] = {cost = 1750, hp = 110, success = 0.35, type = "Worker"},
    ["Lucky Worker"] = {cost = 2355, hp = 150, success = 0.40, type = "Worker"},
    ["Smarter Worker"] = {cost = 3400, hp = 230, success = 0.50, type = "Worker"},
    ["Weak Guard"] = {cost = 900, hp = 120, damage = 25, type = "Guard"},
    ["Normal Guard"] = {cost = 1500, hp = 175, damage = 40, type = "Guard"},
    ["Strong Guard"] = {cost = 2500, hp = 299, damage = 75, type = "Guard"},
    ["Tanky Guard"] = {cost = 5000, hp = 500, damage = 100, type = "Guard"}
}

-- Bases Database
local BasesDatabase = {
    {
        Name = "Ginkha",
        Cost = 0,
        StarterCrucible = 100,
        StarterEquipment = {},
        Requirement = nil,
        MaxAnomalyContainment = 5,
        Perks = {CrucMult = 1, DmgMult = 1},
        CosmicShardCoreHealth = 15700,
    },
    {
        Name = "Alessia",
        Cost = 50000,
        StarterCrucible = 500,
        StarterEquipment = {
            Guards = {{Type = "Weak Guard", Count = 1}},
            Workers = {{Type = "Unlucky Worker", Count = 1}},
        },
        Requirement = {Base = "Ginkha", Containment = 5},
        MaxAnomalyContainment = 7,
        Perks = {CrucMult = 1.5, DmgMult = 1},
        CosmicShardCoreHealth = 35000,
    },
    {
        Name = "Carract",
        Cost = 150000,
        StarterCrucible = 1750,
        StarterEquipment = {
            Guards = {{Type = "Weak Guard", Count = 3}, {Type = "Normal Guard", Count = 1}},
            Workers = {{Type = "Unlucky Worker", Count = 3}, {Type = "Normal Worker", Count = 1}},
        },
        Requirement = {Base = "Alessia", Containment = 7},
        MaxAnomalyContainment = 10,
        Perks = {CrucMult = 2, DmgMult = 1.5},
        CosmicShardCoreHealth = 70000,
    },
    {
        Name = "Carract Sector 2",
        Cost = 350000,
        StarterCrucible = 5000,
        StarterEquipment = {
            Guards = {{Type = "Normal Guard", Count = 4}},
            Workers = {{Type = "Normal Worker", Count = 2}},
        },
        Requirement = {Base = "Carract", Containment = 10},
        MaxAnomalyContainment = 15,
        Perks = {CrucMult = 2.5, DmgMult = 1.5},
        CosmicShardCoreHealth = 95000,
    },
    {
        Name = "Genesis",
        Cost = 500000,
        StarterCrucible = 17500,
        StarterEquipment = {
            Guards = {{Type = "Normal Guard", Count = 10}},
            Workers = {{Type = "Lucky Worker", Count = 2}, {Type = "Normal Worker", Count = 4}},
        },
        Requirement = {Base = "Carract Sector 2", Containment = 15},
        MaxAnomalyContainment = 25,
        Perks = {CrucMult = 3, DmgMult = 2},
        CosmicShardCoreHealth = 125000,
    },
}

-- Game Data
local GameData = {
    Crucible = 0,
    WhiteTrainActive = false,
    TrainTimer = 0,
    CurrentDocuments = {},
    TerminatorAgents = {},
    TerminatorActive = false,
    Bases = {},
    CurrentBase = "Ginkha",
    WorkerNames = {"Michael", "Christina", "Tenna", "Ethan", "Andy", "Joe", "Richard", "Kaleb", "Brian"},
    GuardNames = {"Peter", "Rick", "Kyle", "Jayden", "Nolan", "Steven", "Spencer"},
}

-- Initialize Bases
for _, baseData in ipairs(BasesDatabase) do
    GameData.Bases[baseData.Name] = {
        owned = (baseData.Cost == 0),
        anomalies = {},
        workers = {},
        guards = {},
        outerGuards = {},
        breachedAnomalies = {},
        coreHealth = baseData.CosmicShardCoreHealth,
        maxCoreHealth = baseData.CosmicShardCoreHealth,
        maxContainment = baseData.MaxAnomalyContainment,
        perks = baseData.Perks,
    }
    if baseData.Cost == 0 then
        GameData.Crucible = baseData.StarterCrucible
    end
end

-- Anomaly Database (unchanged from original)
local AnomalyDatabase = {
    ["Crying Eyeball"] = {
        Description = "Sinful Tears, Sinful Deeds.",
        DangerClass = "X",
        BaseMood = 50,
        WorkResults = {
            Knowledge = {Success = 0.6, Crucible = 5, MoodChange = -5},
            Social = {Success = 0.95, Crucible = 45, MoodChange = 15},
            Hunt = {Success = 0.2, Crucible = 1, MoodChange = -20},
            Passive = {Success = 0.8, Crucible = 30, MoodChange = 10}
        },
        BreachChance = 0.005,
        BreachForm = {
            Name = "Blood Cry Out",
            Health = 35,
            M1Damage = 5,
            Abilities = {}
        }
    },
    ["Whispering Shadow"] = {
        Description = "It knows your secrets, and it will tell them all.",
        DangerClass = "XI",
        BaseMood = 40,
        WorkResults = {
            Knowledge = {Success = 0.7, Crucible = 15, MoodChange = 10},
            Social = {Success = 0.4, Crucible = 8, MoodChange = -15},
            Hunt = {Success = 0.3, Crucible = 5, MoodChange = -10},
            Passive = {Success = 0.5, Crucible = 12, MoodChange = 5}
        },
        BreachChance = 0.015,
        BreachForm = {
            Name = "Shadow Stalker",
            Health = 80,
            M1Damage = 12,
            Abilities = {"Invisibility", "Whisper Madness"}
        }
    },
    ["Clockwork Heart"] = {
        Description = "Tick tock, your time is running out.",
        DangerClass = "XI",
        BaseMood = 60,
        WorkResults = {
            Knowledge = {Success = 0.8, Crucible = 20, MoodChange = 8},
            Social = {Success = 0.6, Crucible = 15, MoodChange = -8},
            Hunt = {Success = 0.5, Crucible = 10, MoodChange = -5},
            Passive = {Success = 0.7, Crucible = 18, MoodChange = 12}
        },
        BreachChance = 0.01,
        BreachForm = {
            Name = "Time Ripper",
            Health = 120,
            M1Damage = 15,
            Abilities = {"Time Stop", "Rapid Strikes"}
        }
    },
    ["Smiling Coffin"] = {
        Description = "Rest eternal, rest with a smile.",
        DangerClass = "XII",
        BaseMood = 30,
        WorkResults = {
            Knowledge = {Success = 0.5, Crucible = 35, MoodChange = -10},
            Social = {Success = 0.3, Crucible = 20, MoodChange = -25},
            Hunt = {Success = 0.6, Crucible = 40, MoodChange = 5},
            Passive = {Success = 0.4, Crucible = 25, MoodChange = -15}
        },
        BreachChance = 0.025,
        BreachForm = {
            Name = "Grinning Death",
            Health = 200,
            M1Damage = 25,
            Abilities = {"Death Touch", "Fear Aura", "Coffin Trap"}
        }
    },
    ["Crimson Orchestra"] = {
        Description = "A symphony written in blood and screams.",
        DangerClass = "XII",
        BaseMood = 45,
        WorkResults = {
            Knowledge = {Success = 0.6, Crucible = 30, MoodChange = 5},
            Social = {Success = 0.7, Crucible = 42, MoodChange = 10},
            Hunt = {Success = 0.4, Crucible = 25, MoodChange = -12},
            Passive = {Success = 0.5, Crucible = 28, MoodChange = 8}
        },
        BreachChance = 0.02,
        BreachForm = {
            Name = "Maestro of Pain",
            Health = 180,
            M1Damage = 20,
            Abilities = {"Sound Wave", "Hypnotic Melody", "Crescendo Blast"}
        }
    },
    ["The Void Gazer"] = {
        Description = "Stare into the abyss, and it stares back with hunger.",
        DangerClass = "XIII",
        BaseMood = 20,
        WorkResults = {
            Knowledge = {Success = 0.4, Crucible = 60, MoodChange = -15},
            Social = {Success = 0.2, Crucible = 35, MoodChange = -30},
            Hunt = {Success = 0.5, Crucible = 55, MoodChange = 10},
            Passive = {Success = 0.3, Crucible = 40, MoodChange = -20}
        },
        BreachChance = 0.04,
        BreachForm = {
            Name = "Void Avatar",
            Health = 350,
            M1Damage = 35,
            Abilities = {"Void Pull", "Reality Tear", "Existence Drain", "Darkness Burst"}
        }
    },
    ["Eternal Flame Child"] = {
        Description = "Born from ashes, longing for warmth it can never feel.",
        DangerClass = "XIII",
        BaseMood = 35,
        WorkResults = {
            Knowledge = {Success = 0.5, Crucible = 50, MoodChange = -8},
            Social = {Success = 0.6, Crucible = 65, MoodChange = 15},
            Hunt = {Success = 0.3, Crucible = 30, MoodChange = -25},
            Passive = {Success = 0.4, Crucible = 45, MoodChange = -10}
        },
        BreachChance = 0.035,
        BreachForm = {
            Name = "Inferno Incarnate",
            Health = 280,
            M1Damage = 30,
            Abilities = {"Fire Burst", "Immolation", "Flame Trail", "Phoenix Rebirth"}
        }
    },
    ["Apocalypse Herald"] = {
        Description = "The end is nigh, and it comes with a twisted smile.",
        DangerClass = "XIV",
        BaseMood = 45,
        WorkResults = {
            Knowledge = {Success = 0.3, Crucible = 100, MoodChange = -20},
            Social = {Success = 0.1, Crucible = 50, MoodChange = -40},
            Hunt = {Success = 0.4, Crucible = 90, MoodChange = 15},
            Passive = {Success = 0.2, Crucible = 60, MoodChange = -30}
        },
        BreachChance = 0.06,
        BreachForm = {
            Name = "Harbinger of End",
            Health = 600,
            M1Damage = 50,
            Abilities = {"Apocalypse Wave", "Reality Collapse", "Instant Kill", "Summon Minions", "World Ender"}
        }
    },
    ["Yin"] = {
        Description = "The dark side of the equilibrium. The aggressive nature makes it terrifying.",
        DangerClass = "XII",
        BaseMood = 45,
        WorkResults = {
            Knowledge = {Success = 0.75, Crucible = 85, MoodChange = 10, MoodRequirement = 10},
            Social = {Success = 0.2, Crucible = 20, MoodChange = -15, MoodRequirement = 5},
            Hunt = {Success = 0.8, Crucible = 100, MoodChange = 20, MoodRequirement = 50},
            Passive = {Success = 0.1, Crucible = 35, MoodChange = -20, MoodRequirement = 5}
        },
        BreachChance = 0.03,
        BreachForm = {
            Name = "The Unbalancer",
            Health = 750,
            M1Damage = 75,
            Abilities = {"Shadow Strike", "Dark Vortex"}
        },
        LinkedAnomaly = "Yang"
    },
    ["Yang"] = {
        Description = "The Bright side of the Equilibrium. Its Passive Nature what makes it Loved.",
        DangerClass = "X",
        BaseMood = 100,
        NoMoodMeter = true,
        WorkResults = {
            Knowledge = {Success = 1.0, Crucible = 125, MoodChange = 0},
            Social = {Success = 1.0, Crucible = 100, MoodChange = 0},
            Hunt = {Success = 1.0, Crucible = 0, MoodChange = 0},
            Passive = {Success = 1.0, Crucible = 200, MoodChange = 0}
        },
        BreachChance = 0,
        BreachForm = {
            Name = "The Balancer",
            Health = 800,
            M1Damage = 50,
            Abilities = {"Light Heal", "Balance Restoration"}
        },
        LinkedAnomaly = "Yin",
        BreachOnLinkedBreach = true
    },
    ["ERROR"] = {
        Description = "ERROR 404 FILE NOT FOUND.",
        DangerClass = "XIV",
        BaseMood = 10,
        HideMoodValue = true,
        WorkResults = {
            Knowledge = {Success = 0.2, Crucible = 3000, MoodChange = -30, MoodRequirement = 10, AttackOnFail = true, FailDamage = 100},
            Social = {Success = 0.05, Crucible = 5700, MoodChange = -40, MoodRequirement = 5, AttackOnFail = true, FailDamage = 100},
            Hunt = {Success = 0.3, Crucible = 3500, MoodChange = -25, MoodRequirement = 20, AttackOnFail = true, FailDamage = 100},
            Passive = {Success = 0.05, Crucible = 4000, MoodChange = -35, MoodRequirement = 5, AttackOnFail = true, FailDamage = 100}
        },
        BreachChance = 0.08,
        BreachForm = {
            Name = "[ERROR 404 : unexpected error when parsing code]",
            Health = 15000,
            M1Damage = 500,
            Abilities = {"System Corruption", "Data Wipe", "Reality Glitch", "Fatal Exception"}
        }
    },
    ["DISHEVELED MEAT MESS"] = {
        Description = "LET ME WEAR YOUR SKIN.",
        DangerClass = "XIV",
        BaseMood = 50,
        WorkResults = {
            Knowledge = {Success = 0.1, Crucible = 205, MoodChange = 5},
            Social = {Success = 0.05, Crucible = 150, MoodChange = -10},
            Hunt = {Success = 0.4, Crucible = 350, MoodChange = 45},
            Passive = {Success = 0.2, Crucible = 500, MoodChange = -5}
        },
        BreachChance = 0.06,
        BreachForm = {
            Name = "THE SCRAMBLER",
            Health = 14500,
            M1Damage = 450,
            Abilities = {"Flesh Assimilation", "Chaotic Reassembly"}
        },
        Special = "MeatMess"
    },
    ["Skeleton King"] = {
        Description = "The one who rules countless Skeleton, The one who's trapped here for decades after accidentally trusting the illusions. Would you join the force mortal and become my army?",
        DangerClass = "XIII",
        BaseMood = 30,
        WorkResults = {
            Knowledge = {Success = 0.6, Crucible = 100, MoodChange = 5},
            Social = {Success = 0.5, Crucible = 95, MoodChange = 10},
            Hunt = {Success = 0.6, Crucible = 120, MoodChange = 30},
            Passive = {Success = 0.3, Crucible = 70, MoodChange = 5}
        },
        BreachChance = 0.035,
        BreachForm = {
            Name = "The Skeleton Monarch",
            Health = 6500,
            M1Damage = 100,
            Abilities = {"Army Summon", "Bone Command"}
        },
        Special = "SkeletonKing"
    },
    ["Old Wilted Radio"] = {
        Description = "This is the recording we must never forget and ever.",
        DangerClass = "XII",
        BaseMood = 50,
        WorkResults = {
            Knowledge = {Success = 0.5, Crucible = 50, MoodChange = -5},
            Social = {Success = 0.4, Crucible = 65, MoodChange = 5},
            Hunt = {Success = 0.75, Crucible = 75, MoodChange = 35},
            Passive = {Success = 0.2, Crucible = 35, MoodChange = -10}
        },
        BreachChance = 0.02,
        BreachForm = {
            Name = "GHz 7500",
            Health = 10,
            M1Damage = 80,
            Abilities = {"Frequency Overload", "Signal Distortion"}
        },
        Special = "Radio"
    },
    ["Theres Eyes in the Wall"] = {
        Description = "STOP STARING AT ME CREEPILY",
        DangerClass = "XII",
        BaseMood = 45,
        WorkResults = {
            Knowledge = {Success = 0.3, Crucible = 50, MoodChange = 10},
            Social = {Success = 0.4, Crucible = 45, MoodChange = 5},
            Hunt = {Success = 0.5, Crucible = 75, MoodChange = 20},
            Passive = {Success = 0.1, Crucible = 35, MoodChange = -10}
        },
        BreachChance = 0.02,
        BreachForm = {
            Name = "Spread The Rumors",
            Health = 10,
            M1Damage = 50,
            Abilities = {"Eye Proliferation", "Whisper Network"}
        },
        Special = "Eyes"
    },
    ["Jar of Blood"] = {
        Description = "This Jar contains all the Grudge in the world.",
        DangerClass = "X",
        BaseMood = 50,
        WorkResults = {
            Knowledge = {Success = 0.7, Crucible = 10, MoodChange = 7},
            Social = {Success = 0.5, Crucible = 27, MoodChange = 12},
            Hunt = {Success = 0.3, Crucible = 50, MoodChange = 25},
            Passive = {Success = 0.5, Crucible = 30, MoodChange = 5}
        },
        BreachChance = 0,
        BreachForm = nil,
        NoBreach = true,
        Special = "JarOfBlood"
    }
}

-- Helper Functions (adjusted)
local function GetCurrentBase()
    return GameData.Bases[GameData.CurrentBase]
end

local function GetBase(anomaly)
    return GameData.Bases[anomaly.Base]
end

local function GetAllBreachedAnomalies()
    local all = {}
    for _, base in pairs(GameData.Bases) do
        if base.owned then
            for _, br in ipairs(base.breachedAnomalies) do
                table.insert(all, br)
            end
        end
    end
    return all
end

local function GetAllAnomalies()
    local all = {}
    for _, base in pairs(GameData.Bases) do
        if base.owned then
            for _, an in ipairs(base.anomalies) do
                table.insert(all, an)
            end
        end
    end
    return all
end

local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do
        if k ~= "Parent" then
            instance[k] = v
        end
    end
    instance.Parent = properties.Parent
    return instance
end

local function GetRandomWorkerName()
    return GameData.WorkerNames[math.random(#GameData.WorkerNames)]
end

local function GetRandomGuardName()
    return GameData.GuardNames[math.random(#GameData.GuardNames)]
end

local function UpdateCrucible(amount)
    GameData.Crucible = GameData.Crucible + amount
end

local function RefreshCrucibleDisplay()
    if CrucibleLabel then
        CrucibleLabel.Text = "Crucible: " .. GameData.Crucible
    end
end

local function getDangerLevel(class)
    local map = {
        ["X"] = 10,
        ["XI"] = 11,
        ["XII"] = 12,
        ["XIII"] = 13,
        ["XIV"] = 14
    }
    return map[class] or 0
end

local function UpdateRoomDisplay(anomalyInstance)
    local roomFrame = anomalyInstance.RoomFrame
    if not roomFrame then return end

    local moodLabel = roomFrame:FindFirstChild("MoodLabel")
    local moodBar = roomFrame:FindFirstChild("MoodBar")
    if moodLabel then
        if anomalyInstance.Data.HideMoodValue then
            moodLabel.Text = "Mood: [ERROR]"
        elseif anomalyInstance.Data.NoMoodMeter then
            moodLabel.Text = "Mood: ∞ (Always Peaceful)"
        else
            moodLabel.Text = "Mood: " .. anomalyInstance.CurrentMood .. "/100"
        end
    }
    if moodBar then
        if anomalyInstance.Data.NoMoodMeter then
            moodBar.Size = UDim2.new(1, -10, 0, 8)
            moodBar.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        else
            local moodColor = anomalyInstance.CurrentMood > 50 and Color3.fromRGB(50, 150, 50) or 
                             anomalyInstance.CurrentMood > 20 and Color3.fromRGB(200, 150, 50) or 
                             Color3.fromRGB(200, 50, 50)
            TweenService:Create(moodBar, TweenInfo.new(0.3), {
                Size = UDim2.new(anomalyInstance.CurrentMood / 100, -10, 0, 8),
                BackgroundColor3 = moodColor
            }):Play()
        end
    end

    local workedByLabel = roomFrame:FindFirstChild("WorkedByLabel")
    if workedByLabel then
        workedByLabel.Text = "Worked by: " .. (anomalyInstance.AssignedWorker and anomalyInstance.AssignedWorker.Name or "___")
    end

    local guardedByLabel = roomFrame:FindFirstChild("GuardedByLabel")
    if guardedByLabel then
        local g1 = anomalyInstance.AssignedGuards[1] and anomalyInstance.AssignedGuards[1].Name or "___"
        local g2 = anomalyInstance.AssignedGuards[2] and anomalyInstance.AssignedGuards[2].Name or "___"
        guardedByLabel.Text = "Guarded by: " .. g1 .. " and " .. g2
    end

    local nameLabel = roomFrame:FindFirstChild("TextLabel")
    if nameLabel then
        if anomalyInstance.IsBreached then
            nameLabel.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
            nameLabel.Text = anomalyInstance.Name .. " [BREACHED]"
        else
            nameLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            nameLabel.Text = anomalyInstance.Name
        end
    end

    for _, child in pairs(roomFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name ~= "InfoButton" and child.Name ~= "ExecuteButton" then
            if anomalyInstance.IsBreached then
                child.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                child.TextColor3 = Color3.fromRGB(100, 100, 100)
                child.Active = false
            else
                child.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
                child.TextColor3 = Color3.fromRGB(255, 255, 255)
                child.Active = true
            end
        end
        if child.Name == "AssignButton" or child.Name == "ExecuteButton" then
            child.Active = not anomalyInstance.IsBreached
        end
    end
end

local function CreateRoomFrame(anomalyInstance)
    local roomFrame = CreateInstance("Frame", {
        Name = "AnomalyRoom_" .. #GetCurrentBase().anomalies,
        Parent = AnomalyContainer,
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BorderSizePixel = 2,
        BorderColor3 = Color3.fromRGB(80, 80, 90)
    })
    
    CreateInstance("UICorner", {Parent = roomFrame, CornerRadius = UDim.new(0, 10)})
    
    local nameLabel = CreateInstance("TextLabel", {
        Parent = roomFrame,
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 35),
        Text = anomalyInstance.Name,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 200, 100),
        TextWrapped = true
    })
    
    local dangerLabel = CreateInstance("TextLabel", {
        Parent = roomFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 25),
        Position = UDim2.new(0, 5, 0, 40),
        Text = "Danger Class: " .. anomalyInstance.Data.DangerClass,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(255, 100, 100),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local moodLabel = CreateInstance("TextLabel", {
        Name = "MoodLabel",
        Parent = roomFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 70),
        Text = "Mood: " .. anomalyInstance.CurrentMood .. "/100",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local moodBar = CreateInstance("Frame", {
        Name = "MoodBar",
        Parent = roomFrame,
        BackgroundColor3 = Color3.fromRGB(50, 150, 50),
        BorderSizePixel = 0,
        Size = UDim2.new(anomalyInstance.CurrentMood / 100, -10, 0, 8),
        Position = UDim2.new(0, 5, 0, 95)
    })
    CreateInstance("UICorner", {Parent = moodBar, CornerRadius = UDim.new(0, 4)})
    
    local workedByLabel = CreateInstance("TextLabel", {
        Name = "WorkedByLabel",
        Parent = roomFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 105),
        Text = "Worked by: ___",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local guardedByLabel = CreateInstance("TextLabel", {
        Name = "GuardedByLabel",
        Parent = roomFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 125),
        Text = "Guarded by: ___ and ___",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local workTypes = {"Knowledge", "Social", "Hunt", "Passive"}
    for i, workType in ipairs(workTypes) do
        local workBtn = CreateInstance("TextButton", {
            Name = workType .. "Button",
            Parent = roomFrame,
            BackgroundColor3 = Color3.fromRGB(60, 60, 80),
            BorderSizePixel = 0,
            Size = UDim2.new(0.45, -5, 0, 35),
            Position = UDim2.new((i-1) % 2 * 0.5 + 0.025, 0, 0, 150 + math.floor((i-1) / 2) * 45),
            Text = workType,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        })
        CreateInstance("UICorner", {Parent = workBtn, CornerRadius = UDim.new(0, 6)})
        
        workBtn.MouseButton1Click:Connect(function()
            PerformWork(anomalyInstance, workType, roomFrame)
        end)
    end
    
    local infoBtn = CreateInstance("TextButton", {
        Name = "InfoButton",
        Parent = roomFrame,
        BackgroundColor3 = Color3.fromRGB(80, 80, 100),
        BorderSizePixel = 0,
        Size = UDim2.new(0.95, 0, 0, 35),
        Position = UDim2.new(0.025, 0, 0, 240),
        Text = "Info",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    CreateInstance("UICorner", {Parent = infoBtn, CornerRadius = UDim.new(0, 6)})
    
    infoBtn.MouseButton1Click:Connect(function()
        ShowAnomalyInfo(anomalyInstance)
    end)
    
    local assignBtn = CreateInstance("TextButton", {
        Name = "AssignButton",
        Parent = roomFrame,
        BackgroundColor3 = Color3.fromRGB(80, 80, 100),
        BorderSizePixel = 0,
        Size = UDim2.new(0.95, 0, 0, 35),
        Position = UDim2.new(0.025, 0, 0, 280),
        Text = "Workers & Guards",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    CreateInstance("UICorner", {Parent = assignBtn, CornerRadius = UDim.new(0, 6)})
    
    assignBtn.MouseButton1Click:Connect(function()
        PopulateAssignGui(anomalyInstance)
        AssignGui.Visible = true
    end)
    
    local executeBtn = CreateInstance("TextButton", {
        Name = "ExecuteButton",
        Parent = roomFrame,
        BackgroundColor3 = Color3.fromRGB(150, 50, 50),
        BorderSizePixel = 0,
        Size = UDim2.new(0.95, 0, 0, 35),
        Position = UDim2.new(0.025, 0, 0, 320),
        Text = "Execute",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    CreateInstance("UICorner", {Parent = executeBtn, CornerRadius = UDim.new(0, 6)})
    
    executeBtn.MouseButton1Click:Connect(function()
        if not anomalyInstance.IsBreached then
            anomalyInstance.ToBeExecuted = true
            TriggerBreach(anomalyInstance, roomFrame)
        end
    end)
    
    return roomFrame
end

local function RefreshAnomalyContainer()
    for _, child in pairs(AnomalyContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local currentBase = GetCurrentBase()
    for _, anomalyInstance in ipairs(currentBase.anomalies) do
        local roomFrame = CreateRoomFrame(anomalyInstance)
        anomalyInstance.RoomFrame = roomFrame
        UpdateRoomDisplay(anomalyInstance)
    end
    
    local layout = AnomalyContainer:FindFirstChildOfClass("UIGridLayout")
    if layout then
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            AnomalyContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
        AnomalyContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end
end

-- Create Main GUI
local MainGui = CreateInstance("ScreenGui", {
    Name = "SorchesusCompanyGUI",
    Parent = playerGui,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

-- Top Bar with horizontal scroll
local TopBar = CreateInstance("ScrollingFrame", {
    Name = "TopBar",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0, 0),
    CanvasSize = UDim2.new(0, 1000, 0, 50),
    HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
    ScrollBarThickness = 5,
    VerticalScrollBarVisibility = Enum.ScrollerScrollBarVisibility.Never
})

local CompanyName = CreateInstance("TextLabel", {
    Name = "CompanyName",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 300, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    Text = "SORCHESUS COMPANY - Ginkha",
    Font = Enum.Font.GothamBold,
    TextSize = 24,
    TextColor3 = Color3.fromRGB(200, 50, 50),
    TextXAlignment = Enum.TextXAlignment.Left
})

local EmployeeButton = CreateInstance("TextButton", {
    Name = "EmployeeButton",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 120, 1, 0),
    Position = UDim2.new(0, 320, 0, 0),
    Text = "Employees",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Left
})

local OuterGuardButton = CreateInstance("TextButton", {
    Name = "OuterGuardButton",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 120, 1, 0),
    Position = UDim2.new(0, 450, 0, 0),
    Text = "Outer Guard",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Left
})

local TerminatorButton = CreateInstance("TextButton", {
    Name = "TerminatorButton",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 150, 1, 0),
    Position = UDim2.new(0, 580, 0, 0),
    Text = "Terminator Protocol",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Left
})

local BasesButton = CreateInstance("TextButton", {
    Name = "BasesButton",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 120, 1, 0),
    Position = UDim2.new(0, 740, 0, 0),
    Text = "Base",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Left
})

local CrucibleLabel = CreateInstance("TextLabel", {
    Name = "CrucibleLabel",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 870, 0, 0),
    Text = "Crucible: " .. GameData.Crucible,
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 215, 0),
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Employee Shop GUI (adjusted)
local EmployeeShop = CreateInstance("Frame", {
    Name = "EmployeeShop",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 3,
    BorderColor3 = Color3.fromRGB(100, 100, 100),
    Size = isMobile and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(0, 700, 0, 550),
    Position = isMobile and UDim2.new(0.025, 0, 0.025, 0) or UDim2.new(0.5, -350, 0.5, -275),
    Visible = false,
    ZIndex = 10
})

local ShopTitle = CreateInstance("TextLabel", {
    Name = "ShopTitle",
    Parent = EmployeeShop,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "EMPLOYEE SHOP",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local ShopScroll = CreateInstance("ScrollingFrame", {
    Name = "ShopScroll",
    Parent = EmployeeShop,
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    Size = UDim2.new(1, -20, 1, -90),
    Position = UDim2.new(0, 10, 0, 50),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 8
})

local shopGrid = CreateInstance("UIGridLayout", {
    Parent = ShopScroll,
    CellSize = UDim2.new(isMobile and 1 or 0.5, -10, 0, 180),
    CellPadding = UDim2.new(0, 10, 0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center
})

-- employees list from original
local employees = {
    {name = "Unlucky Worker", cost = 500, hp = 60, success = 0.1, type = "Worker"},
    {name = "Normal Worker", cost = 850, hp = 90, success = 0.23, type = "Worker"},
    {name = "Smart Worker", cost = 1750, hp = 110, success = 0.35, type = "Worker"},
    {name = "Lucky Worker", cost = 2355, hp = 150, success = 0.40, type = "Worker"},
    {name = "Smarter Worker", cost = 3400, hp = 230, success = 0.50, type = "Worker"},
    {name = "Weak Guard", cost = 900, hp = 120, damage = 25, type = "Guard"},
    {name = "Normal Guard", cost = 1500, hp = 175, damage = 40, type = "Guard"},
    {name = "Strong Guard", cost = 2500, hp = 299, damage = 75, type = "Guard"},
    {name = "Tanky Guard", cost = 5000, hp = 500, damage = 100, type = "Guard"}
}

for _, emp in ipairs(employees) do
    local frame = CreateInstance("Frame", {
        Parent = ShopScroll,
        BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    })
    CreateInstance("UICorner", {Parent = frame})
    
    CreateInstance("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        Text = emp.name,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    
    local stats = "Cost: " .. emp.cost .. " Crucible\nHealth: " .. emp.hp
    if emp.type == "Worker" then
        stats = stats .. "\nSuccess: " .. (emp.success * 100) .. "%"
    else
        stats = stats .. "\nDamage: " .. emp.damage
    end
    
    CreateInstance("TextLabel", {
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 90),
        Position = UDim2.new(0, 5, 0, 30),
        Text = stats,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })
    
    local buyBtn = CreateInstance("TextButton", {
        Parent = frame,
        BackgroundColor3 = Color3.fromRGB(50, 150, 50),
        Size = UDim2.new(1, -10, 0, 35),
        Position = UDim2.new(0, 5, 1, -40),
        Text = "Buy",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    CreateInstance("UICorner", {Parent = buyBtn})
    
    buyBtn.MouseButton1Click:Connect(function()
        if GameData.Crucible >= emp.cost then
            UpdateCrucible(-emp.cost)
            RefreshCrucibleDisplay()
            local currentBase = GetCurrentBase()
            local nameFunc = emp.type == "Worker" and GetRandomWorkerName or GetRandomGuardName
            local name = nameFunc()
            local employee = {
                Name = name,
                Type = emp.name,
                MaxHP = emp.hp,
                HP = emp.hp,
                AssignedTo = nil
            }
            if emp.type == "Worker" then
                employee.SuccessChance = emp.success
                table.insert(currentBase.workers, employee)
            else
                employee.Damage = emp.damage
                table.insert(currentBase.guards, employee)
            end
            CreateNotification("Hired " .. name .. " (" .. emp.name .. ")", Color3.fromRGB(50, 200, 50))
        else
            CreateNotification("Not enough Crucible!", Color3.fromRGB(200, 50, 50))
        end
    end)
end

shopGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ShopScroll.CanvasSize = UDim2.new(0, 0, 0, shopGrid.AbsoluteContentSize.Y + 20)
end)

local CloseShopButton = CreateInstance("TextButton", {
    Name = "CloseButton",
    Parent = EmployeeShop,
    BackgroundColor3 = Color3.fromRGB(150, 50, 50),
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -35, 0, 5),
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = CloseShopButton, CornerRadius = UDim.new(0, 6)})

-- Assign GUI (adjusted)
local AssignGui = CreateInstance("Frame", {
    Name = "AssignGui",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 3,
    BorderColor3 = Color3.fromRGB(100, 100, 100),
    Size = isMobile and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(0, 600, 0, 450),
    Position = isMobile and UDim2.new(0.025, 0, 0.025, 0) or UDim2.new(0.5, -300, 0.5, -225),
    Visible = false,
    ZIndex = 10
})

-- ... (rest of AssignGui creation unchanged)

local function PopulateAssignGui(anomalyInstance)
    AssignTitle.Text = "ASSIGN TO " .. anomalyInstance.Name:upper()
    
    for _, child in pairs(WorkerSection:GetChildren()) do
        if child.Name ~= "UIListLayout" and child.Name ~= "TextLabel" then
            child:Destroy()
        end
    end
    for _, child in pairs(GuardSection:GetChildren()) do
        if child.Name ~= "UIListLayout" and child.Name ~= "TextLabel" then
            child:Destroy()
        end
    end

    local currentBase = GetCurrentBase()
    for _, worker in ipairs(currentBase.workers) do
        if worker.HP > 0 and worker.AssignedTo == nil then
            local btn = CreateInstance("TextButton", {
                Parent = WorkerSection,
                BackgroundColor3 = Color3.fromRGB(60, 60, 80),
                Size = UDim2.new(1, -10, 0, 40),
                Text = worker.Name .. " (" .. worker.Type .. ") HP: " .. worker.HP,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
            CreateInstance("UICorner", {Parent = btn})
            btn.MouseButton1Click:Connect(function()
                if anomalyInstance.AssignedWorker == nil then
                    anomalyInstance.AssignedWorker = worker
                    worker.AssignedTo = anomalyInstance
                    StartWorkerLoop(worker, anomalyInstance)
                    AssignGui.Visible = false
                    UpdateRoomDisplay(anomalyInstance)
                else
                    CreateNotification("Worker slot full!", Color3.fromRGB(200, 50, 50))
                end
            end)
        end
    end
    WorkerSection.CanvasSize = UDim2.new(0, 0, 0, workerList.AbsoluteContentSize.Y + 50)

    for _, guard in ipairs(currentBase.guards) do
        if guard.HP > 0 and guard.AssignedTo == nil then
            local btn = CreateInstance("TextButton", {
                Parent = GuardSection,
                BackgroundColor3 = Color3.fromRGB(60, 60, 80),
                Size = UDim2.new(1, -10, 0, 40),
                Text = guard.Name .. " (" .. guard.Type .. ") HP: " .. guard.HP,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
            CreateInstance("UICorner", {Parent = btn})
            btn.MouseButton1Click:Connect(function()
                if #anomalyInstance.AssignedGuards < 2 then
                    table.insert(anomalyInstance.AssignedGuards, guard)
                    guard.AssignedTo = anomalyInstance
                    AssignGui.Visible = false
                    UpdateRoomDisplay(anomalyInstance)
                else
                    CreateNotification("Guard slots full!", Color3.fromRGB(200, 50, 50))
                end
            end)
        end
    end
    GuardSection.CanvasSize = UDim2.new(0, 0, 0, guardList.AbsoluteContentSize.Y + 50)
end

-- Outer Guard GUI (adjusted)
local OuterGuardGui = CreateInstance("Frame", {
    Name = "OuterGuardGui",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 3,
    BorderColor3 = Color3.fromRGB(100, 100, 100),
    Size = isMobile and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(0, 600, 0, 450),
    Position = isMobile and UDim2.new(0.025, 0, 0.025, 0) or UDim2.new(0.5, -300, 0.5, -225),
    Visible = false,
    ZIndex = 10
})

-- ... (rest unchanged)

local function PopulateOuterGui()
    local currentBase = GetCurrentBase()
    for _, child in pairs(AvailableOuterGuardSection:GetChildren()) do
        if child.Name ~= "UIListLayout" and child.Name ~= "TextLabel" then
            child:Destroy()
        end
    end
    for _, child in pairs(CurrentOuterGuardSection:GetChildren()) do
        if child.Name ~= "UIListLayout" and child.Name ~= "TextLabel" then
            child:Destroy()
        end
    end

    for _, guard in ipairs(currentBase.guards) do
        if guard.HP > 0 and guard.AssignedTo == nil then
            local btn = CreateInstance("TextButton", {
                Parent = AvailableOuterGuardSection,
                BackgroundColor3 = Color3.fromRGB(60, 60, 80),
                Size = UDim2.new(1, -10, 0, 40),
                Text = guard.Name .. " (" .. guard.Type .. ") HP: " .. guard.HP,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
            CreateInstance("UICorner", {Parent = btn})
            btn.MouseButton1Click:Connect(function()
                table.insert(currentBase.outerGuards, guard)
                guard.AssignedTo = "Outer"
                PopulateOuterGui()
            end)
        end
    end
    AvailableOuterGuardSection.CanvasSize = UDim2.new(0, 0, 0, availableOuterList.AbsoluteContentSize.Y + 50)

    for _, guard in ipairs(currentBase.outerGuards) do
        local btn = CreateInstance("TextButton", {
            Parent = CurrentOuterGuardSection,
            BackgroundColor3 = Color3.fromRGB(60, 60, 80),
            Size = UDim2.new(1, -10, 0, 40),
            Text = guard.Name .. " (" .. guard.Type .. ") HP: " .. guard.HP .. " (Assigned)",
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        })
        CreateInstance("UICorner", {Parent = btn})
        btn.MouseButton1Click:Connect(function()
            guard.AssignedTo = nil
            for i = #currentBase.outerGuards, 1, -1 do
                if currentBase.outerGuards[i] == guard then
                    table.remove(currentBase.outerGuards, i)
                    break
                end
            end
            PopulateOuterGui()
        end)
    end
    CurrentOuterGuardSection.CanvasSize = UDim2.new(0, 0, 0, currentOuterList.AbsoluteContentSize.Y + 50)
end

-- Cosmic Shard Core Display (adjusted for current base)
local CoreFrame = CreateInstance("Frame", {
    Name = "CoreFrame",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 30),
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(100, 200, 255),
    Size = UDim2.new(0.28, -20, 0.25, 0),
    Position = UDim2.new(0.72, 0, 0.5, 10)
})

-- ... (rest unchanged)

local function UpdateCoreDisplay()
    local currentBase = GetCurrentBase()
    local healthPercent = currentBase.coreHealth / currentBase.maxCoreHealth
    
    CoreHealthLabel.Text = string.format("Health: %d / %d", currentBase.coreHealth, currentBase.maxCoreHealth)
    
    TweenService:Create(CoreHealthBar, TweenInfo.new(0.5), {
        Size = UDim2.new(healthPercent, 0, 1, 0),
        BackgroundColor3 = healthPercent > 0.6 and Color3.fromRGB(100, 200, 255) or healthPercent > 0.3 and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(255, 100, 100)
    }):Play()
    
    CoreStatusLabel.Text = currentBase.coreHealth <= 0 and "STATUS: DESTROYED" or healthPercent < 0.3 and "STATUS: CRITICAL" or healthPercent < 0.6 and "STATUS: DAMAGED" or "STATUS: PROTECTED"
    CoreStatusLabel.TextColor3 = currentBase.coreHealth <= 0 and Color3.fromRGB(255, 50, 50) or healthPercent < 0.3 and Color3.fromRGB(255, 100, 50) or healthPercent < 0.6 and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(100, 255, 100)
    
    UpdateBreachAlert()
end

-- Breach Alert Container (global)
local BreachAlertContainer = CreateInstance("Frame", {
    Name = "BreachAlertContainer",
    Parent = MainGui,
    BackgroundTransparency = 1,
    Size = UDim2.new(0.28, -20, 0.15, 0),
    Position = UDim2.new(0.72, 0, 0.77, 0)
})

local function UpdateBreachAlert()
    for _, child in pairs(BreachAlertContainer:GetChildren()) do
        child:Destroy()
    end
    
    local totalBreached = #GetAllBreachedAnomalies()
    if totalBreached > 0 then
        local alertLabel = CreateInstance("TextLabel", {
            Name = "BreachAlert",
            Parent = BreachAlertContainer,
            BackgroundColor3 = Color3.fromRGB(150, 20, 20),
            BorderSizePixel = 2,
            BorderColor3 = Color3.fromRGB(255, 50, 50),
            Size = UDim2.new(1, 0, 0, 50),
            Text = string.format("⚠ ACTIVE BREACHES: %d ⚠", totalBreached),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        })
        
        CreateInstance("UICorner", {Parent = alertLabel, CornerRadius = UDim.new(0, 8)})
        
        spawn(function()
            while alertLabel.Parent do
                alertLabel.BackgroundColor3 = Color3.fromRGB(150, 20, 20)
                wait(0.5)
                if alertLabel.Parent then
                    alertLabel.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                    wait(0.5)
                end
            end
        end)
    end
end

-- Anomaly Container
local AnomalyContainer = CreateInstance("ScrollingFrame", {
    Name = "AnomalyContainer",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(50, 50, 50),
    Size = UDim2.new(0.7, -20, 0.85, -20),
    Position = UDim2.new(0, 10, 0, 60),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 10
})

CreateInstance("UIGridLayout", {
    Parent = AnomalyContainer,
    CellSize = UDim2.new(isMobile and 1 or 0.5, -10, 0, 360),
    CellPadding = UDim2.new(0, 10, 0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

-- Train Panel (unchanged)
local TrainPanel = CreateInstance("Frame", {
    Name = "TrainPanel",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(25, 25, 35),
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(100, 100, 150),
    Size = UDim2.new(0.28, -20, 0.4, 0),
    Position = UDim2.new(0.72, 0, 0, 60)
})

-- ... (rest of TrainPanel unchanged)

-- Document Selection GUI (unchanged, but accept checks max containment)

-- Functions (adjusted)
local function StartWorkerLoop(worker, anomalyInstance)
    spawn(function()
        while worker.AssignedTo == anomalyInstance and worker.HP > 0 and not anomalyInstance.IsBreached do
            wait(5)
            local oldMood = anomalyInstance.CurrentMood
            local success = math.random() < worker.SuccessChance
            local moodChange = success and 15 or -10
            anomalyInstance.CurrentMood = math.clamp(anomalyInstance.CurrentMood + moodChange, 0, 100)
            if success then
                local mult = GetBase(anomalyInstance).perks.CrucMult
                UpdateCrucible(20 * mult)
                RefreshCrucibleDisplay()
            end
            UpdateRoomDisplay(anomalyInstance)
            if moodChange < 0 then
                if anomalyInstance.Data.Special == "JarOfBlood" then
                    local damage = 0
                    local newMood = anomalyInstance.CurrentMood
                    if newMood <= 10 then damage = 69
                    elseif newMood <= 30 then damage = 30
                    elseif newMood <= 75 then damage = 10
                    end
                    worker.HP = math.max(0, worker.HP - damage)
                    CreateNotification(anomalyInstance.Name .. " damaged " .. worker.Name .. " for " .. damage, Color3.fromRGB(200, 50, 50))
                    if worker.HP <= 0 then
                        CreateNotification(worker.Name .. " was killed!", Color3.fromRGB(200, 50, 50))
                        anomalyInstance.AssignedWorker = nil
                        worker.AssignedTo = nil
                        UpdateRoomDisplay(anomalyInstance)
                        break
                    end
                end
            end
            if anomalyInstance.Data.Special == "MeatMess" and anomalyInstance.CurrentMood < 30 and math.random() < 0.3 then
                if anomalyInstance.AssignedWorker then
                    anomalyInstance.AssignedWorker.HP = 0
                    CreateNotification(anomalyInstance.Name .. " killed and ate " .. anomalyInstance.AssignedWorker.Name, Color3.fromRGB(200, 50, 50))
                    anomalyInstance.BonusBreachHealth = (anomalyInstance.BonusBreachHealth or 0) + 10
                    anomalyInstance.AssignedWorker = nil
                    UpdateRoomDisplay(anomalyInstance)
                end
            end
            if anomalyInstance.CurrentMood <= 0 then
                TriggerBreach(anomalyInstance, anomalyInstance.RoomFrame)
                break
            end
            if anomalyInstance.CurrentMood < 30 and math.random() < 0.4 then
                local damage = anomalyInstance.Data.BreachForm.M1Damage * 0.5
                worker.HP = math.max(0, worker.HP - damage)
                CreateNotification(anomalyInstance.Name .. " attacked " .. worker.Name .. " for " .. damage, Color3.fromRGB(200, 50, 50))
                if worker.HP <= 0 then
                    CreateNotification(worker.Name .. " was killed!", Color3.fromRGB(200, 50, 50))
                    anomalyInstance.AssignedWorker = nil
                    worker.AssignedTo = nil
                    UpdateRoomDisplay(anomalyInstance)
                    break
                end
            end
        end
    end)
end

local function PerformWork(anomalyInstance, workType, roomFrame)
    local workResult = anomalyInstance.Data.WorkResults[workType]
    if not workResult then return end
    
    if workResult.MoodRequirement and anomalyInstance.CurrentMood < workResult.MoodRequirement then
        CreateNotification("Mood too low! Minimum required: " .. workResult.MoodRequirement, Color3.fromRGB(200, 50, 50))
        return
    end
    
    if anomalyInstance.Data.NoMoodMeter then
        local mult = GetBase(anomalyInstance).perks.CrucMult
        UpdateCrucible(workResult.Crucible * mult)
        RefreshCrucibleDisplay()
        CreateNotification("Work Success! +" .. workResult.Crucible * mult .. " Crucible", Color3.fromRGB(50, 200, 50))
        return
    end
    
    local oldMood = anomalyInstance.CurrentMood
    local success = math.random() < workResult.Success
    local moodChange = 0
    
    if success then
        local mult = GetBase(anomalyInstance).perks.CrucMult
        UpdateCrucible(workResult.Crucible * mult)
        RefreshCrucibleDisplay()
        moodChange = workResult.MoodChange
    else
        if workResult.AttackOnFail and anomalyInstance.AssignedWorker then
            local damage = workResult.FailDamage
            anomalyInstance.AssignedWorker.HP = math.max(0, anomalyInstance.AssignedWorker.HP - damage)
            CreateNotification(anomalyInstance.Name .. " attacked " .. anomalyInstance.AssignedWorker.Name .. " for " .. damage, Color3.fromRGB(200, 50, 50))
            
            if anomalyInstance.AssignedWorker.HP <= 0 then
                CreateNotification(anomalyInstance.AssignedWorker.Name .. " was killed!", Color3.fromRGB(200, 50, 50))
                anomalyInstance.AssignedWorker = nil
                UpdateRoomDisplay(anomalyInstance)
            end
        end
        moodChange = math.abs(workResult.MoodChange) * 2 * -1
    end
    
    anomalyInstance.CurrentMood = math.clamp(anomalyInstance.CurrentMood + moodChange, 0, 100)
    
    if moodChange < 0 then
        if anomalyInstance.Data.Special == "JarOfBlood" then
            local damage = 0
            local newMood = anomalyInstance.CurrentMood
            if newMood <= 10 then damage = 3500
            elseif newMood <= 30 then damage = 750
            elseif newMood <= 75 then damage = 100
            end
            local base = GetBase(anomalyInstance)
            base.coreHealth = math.max(0, base.coreHealth - damage)
            CreateNotification(anomalyInstance.Name .. " damaged the Cosmic Shard Core for " .. damage, Color3.fromRGB(200, 50, 50))
            UpdateCoreDisplay()
        end
    end
    
    if anomalyInstance.Data.Special == "MeatMess" and anomalyInstance.CurrentMood < 30 and math.random() < 0.3 then
        if anomalyInstance.AssignedWorker then
            anomalyInstance.AssignedWorker.HP = 0
            CreateNotification(anomalyInstance.Name .. " killed and ate " .. anomalyInstance.AssignedWorker.Name, Color3.fromRGB(200, 50, 50))
            anomalyInstance.BonusBreachHealth = (anomalyInstance.BonusBreachHealth or 0) + 10
            anomalyInstance.AssignedWorker = nil
            UpdateRoomDisplay(anomalyInstance)
        end
    end
    
    if anomalyInstance.CurrentMood <= 0 then
        TriggerBreach(anomalyInstance, roomFrame)
    else
        if success then
            if math.random() < anomalyInstance.Data.BreachChance then
                TriggerBreach(anomalyInstance, roomFrame)
            end
        else
            if math.random() < (anomalyInstance.Data.BreachChance * 3) then
                TriggerBreach(anomalyInstance, roomFrame)
            end
        end
    end
    
    local moodText = moodChange >= 0 and ("+" .. moodChange) or tostring(moodChange)
    local notifText = success and ("Work Success! +" .. workResult.Crucible .. " Crucible (Mood: " .. moodText .. ")") or ("Work Failed! Mood decreased by " .. math.abs(moodChange))
    CreateNotification(notifText, success and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50))
    
    UpdateRoomDisplay(anomalyInstance)
end

local function TriggerBreach(anomalyInstance, roomFrame)
    if anomalyInstance.IsBreached or anomalyInstance.Data.NoBreach then return end
    
    if anomalyInstance.Data.NoMoodMeter and not anomalyInstance.Data.BreachOnLinkedBreach then
        return
    end
    
    local breachData = anomalyInstance.Data.BreachForm
    anomalyInstance.IsBreached = true
    anomalyInstance.BreachHP = breachData.Health + (anomalyInstance.BonusBreachHealth or 0)
    anomalyInstance.BreachTime = os.time()
    
    local base = GetBase(anomalyInstance)
    table.insert(base.breachedAnomalies, {
        Instance = anomalyInstance,
        BreachData = breachData,
        RoomFrame = roomFrame
    })
    
    local message = "BREACH! " .. breachData.Name .. " has escaped!"
    if anomalyInstance.Base ~= GameData.CurrentBase then
        message = "Anomaly Breach in " .. anomalyInstance.Base .. "!"
    end
    CreateNotification(message, Color3.fromRGB(255, 0, 0))
    
    UpdateRoomDisplay(anomalyInstance)
    UpdateBreachAlert()
    
    if anomalyInstance.Data.LinkedAnomaly then
        local allAnomalies = GetAllAnomalies()
        for _, otherAnomaly in ipairs(allAnomalies) do
            if otherAnomaly.Name == anomalyInstance.Data.LinkedAnomaly and otherAnomaly.Data.BreachOnLinkedBreach then
                CreateNotification(otherAnomaly.Name .. " is responding to the breach!", Color3.fromRGB(100, 200, 255))
                TriggerBreach(otherAnomaly, otherAnomaly.RoomFrame)
            end
        end
    end
    
    StartBreachLoop(anomalyInstance)
end

local function StartBreachLoop(anomalyInstance)
    spawn(function()
        local breachData = anomalyInstance.Data.BreachForm
        local isYang = anomalyInstance.Name == "Yang"
        local yinInstance = nil
        local elapsed = 0
        
        local minions = {}
        local minionDamage = 0
        local eyes = {}
        
        if anomalyInstance.Data.Special == "Radio" then
            for i = 1, 5 do
                table.insert(minions, {HP = 100})
            end
            minionDamage = 10
        end
        
        if anomalyInstance.Data.Special == "Eyes" then
            table.insert(eyes, {HP = 10})
        end
        
        if isYang then
            local allAnomalies = GetAllAnomalies()
            for _, anomaly in ipairs(allAnomalies) do
                if anomaly.Name == "Yin" and anomaly.IsBreached then
                    yinInstance = anomaly
                    break
                end
            end
        end
        
        while anomalyInstance.IsBreached do
            wait(2)
            elapsed = elapsed + 2
            
            if anomalyInstance.Data.Special == "SkeletonKing" and elapsed % 30 == 0 then
                local base = GetBase(anomalyInstance)
                local allEmployees = {}
                for _, w in ipairs(base.workers) do
                    if w.HP > 0 then table.insert(allEmployees, w) end
                end
                for _, g in ipairs(base.guards) do
                    if g.HP > 0 then table.insert(allEmployees, g) end
                end
                if #allEmployees > 0 then
                    local target = allEmployees[math.random(#allEmployees)]
                    target.HP = 0
                    CreateNotification(target.Name .. " joined the skeleton army!", Color3.fromRGB(200, 50, 50))
                    if target.AssignedTo then
                        if target.AssignedTo == "Outer" then
                            for i = #base.outerGuards, 1, -1 do
                                if base.outerGuards[i] == target then
                                    table.remove(base.outerGuards, i)
                                    break
                                end
                            end
                        else
                            if target.AssignedTo.AssignedWorker == target then
                                target.AssignedTo.AssignedWorker = nil
                            end
                            for i = #target.AssignedTo.AssignedGuards, 1, -1 do
                                if target.AssignedTo.AssignedGuards[i] == target then
                                    table.remove(target.AssignedTo.AssignedGuards, i)
                                end
                            end
                            UpdateRoomDisplay(target.AssignedTo)
                        end
                    end
                    target.AssignedTo = nil
                    if target.SuccessChance then
                        for i = #base.workers, 1, -1 do
                            if base.workers[i] == target then
                                table.remove(base.workers, i)
                            end
                        end
                    else
                        for i = #base.guards, 1, -1 do
                            if base.guards[i] == target then
                                table.remove(base.guards, i)
                            end
                        end
                    end
                end
            end
            
            if anomalyInstance.Data.Special == "Eyes" and elapsed % 5 == 0 then
                table.insert(eyes, {HP = 10})
                CreateNotification("New eye appeared!", Color3.fromRGB(200, 50, 50))
            end
            
            local employees = {}
            if anomalyInstance.AssignedWorker and anomalyInstance.AssignedWorker.HP > 0 then
                table.insert(employees, anomalyInstance.AssignedWorker)
            end
            for _, guard in ipairs(anomalyInstance.AssignedGuards) do
                if guard.HP > 0 then
                    table.insert(employees, guard)
                end
            end
            
            -- Special minion/eye damage
            local extraDamage = 0
            if anomalyInstance.Data.Special == "Radio" then
                extraDamage = minionDamage * #minions
            elseif anomalyInstance.Data.Special == "Eyes" then
                extraDamage = 50 * #eyes
            end
            if extraDamage > 0 then
                if #employees > 0 then
                    local target = employees[math.random(#employees)]
                    target.HP = math.max(0, target.HP - extraDamage)
                    CreateNotification(anomalyInstance.Name .. " minions attacked " .. target.Name .. " for " .. extraDamage, Color3.fromRGB(200, 50, 50))
                    if target.HP <= 0 then
                        CreateNotification(target.Name .. " was killed!", Color3.fromRGB(200, 50, 50))
                        if target == anomalyInstance.AssignedWorker then
                            anomalyInstance.AssignedWorker = nil
                        else
                            for i = #anomalyInstance.AssignedGuards, 1, -1 do
                                if anomalyInstance.AssignedGuards[i] == target then
                                    table.remove(anomalyInstance.AssignedGuards, i)
                                    break
                                end
                            end
                        end
                        target.AssignedTo = nil
                        UpdateRoomDisplay(anomalyInstance)
                    end
                else
                    local damageTarget = GetBase(anomalyInstance).coreHealth
                    if GameData.TerminatorActive and #GameData.TerminatorAgents > 0 then
                        local agent = GameData.TerminatorAgents[math.random(#GameData.TerminatorAgents)]
                        agent.HP = math.max(0, agent.HP - extraDamage)
                        CreateNotification(anomalyInstance.Name .. " minions attacked " .. agent.Name .. " for " .. extraDamage, Color3.fromRGB(200, 50, 50))
                        if agent.HP <= 0 then
                            CreateNotification(agent.Name .. " is down!", Color3.fromRGB(200, 50, 50))
                            for i = #GameData.TerminatorAgents, 1, -1 do
                                if GameData.TerminatorAgents[i] == agent then
                                    table.remove(GameData.TerminatorAgents, i)
                                    break
                                end
                            end
                        end
                    else
                        local base = GetBase(anomalyInstance)
                        base.coreHealth = math.max(0, base.coreHealth - extraDamage)
                        UpdateCoreDisplay()
                        if base.coreHealth <= 0 then
                            CompanyDestroyed(anomalyInstance.Base)
                            break
                        end
                    end
                end
            end
            
            if isYang and yinInstance then
                if yinInstance.IsBreached and yinInstance.BreachHP > 0 then
                    local damage = breachData.M1Damage
                    yinInstance.BreachHP = math.max(0, yinInstance.BreachHP - damage)
                    CreateNotification("The Balancer attacked The Unbalancer for " .. damage, Color3.fromRGB(100, 200, 255))
                    
                    if yinInstance.BreachHP <= 0 then
                        CreateNotification("The Unbalancer has been contained by The Balancer!", Color3.fromRGB(50, 200, 50))
                        yinInstance.IsBreached = false
                        yinInstance.CurrentMood = yinInstance.Data.BaseMood / 2
                        yinInstance.BreachHP = nil
                        local yinBase = GetBase(yinInstance)
                        for i, b in ipairs(yinBase.breachedAnomalies) do
                            if b.Instance == yinInstance then
                                table.remove(yinBase.breachedAnomalies, i)
                                break
                            end
                        end
                        UpdateRoomDisplay(yinInstance)
                        
                        anomalyInstance.IsBreached = false
                        local thisBase = GetBase(anomalyInstance)
                        for i, b in ipairs(thisBase.breachedAnomalies) do
                            if b.Instance == anomalyInstance then
                                table.remove(thisBase.breachedAnomalies, i)
                                break
                            end
                        end
                        UpdateRoomDisplay(anomalyInstance)
                        UpdateBreachAlert()
                        UpdateCoreDisplay()
                        break
                    end
                else
                    anomalyInstance.IsBreached = false
                    local thisBase = GetBase(anomalyInstance)
                    for i, b in ipairs(thisBase.breachedAnomalies) do
                        if b.Instance == anomalyInstance then
                            table.remove(thisBase.breachedAnomalies, i)
                            break
                        end
                    end
                    UpdateRoomDisplay(anomalyInstance)
                    UpdateBreachAlert()
                    UpdateCoreDisplay()
                    break
                end
            else
                if #employees > 0 then
                    local target = employees[math.random(#employees)]
                    local damage = breachData.M1Damage
                    target.HP = math.max(0, target.HP - damage)
                    CreateNotification(breachData.Name .. " attacked " .. target.Name .. " for " .. damage, Color3.fromRGB(200, 50, 50))
                    
                    if target.HP <= 0 then
                        CreateNotification(target.Name .. " was killed!", Color3.fromRGB(200, 50, 50))
                        if target == anomalyInstance.AssignedWorker then
                            anomalyInstance.AssignedWorker = nil
                        else
                            for i = #anomalyInstance.AssignedGuards, 1, -1 do
                                if anomalyInstance.AssignedGuards[i] == target then
                                    table.remove(anomalyInstance.AssignedGuards, i)
                                    break
                                end
                            end
                        end
                        target.AssignedTo = nil
                        UpdateRoomDisplay(anomalyInstance)
                    end
                else
                    local damage = breachData.M1Damage
                    if GameData.TerminatorActive and #GameData.TerminatorAgents > 0 then
                        local agent = GameData.TerminatorAgents[math.random(#GameData.TerminatorAgents)]
                        agent.HP = math.max(0, agent.HP - damage)
                        CreateNotification(breachData.Name .. " attacked " .. agent.Name .. " for " .. damage, Color3.fromRGB(200, 50, 50))
                        if agent.HP <= 0 then
                            CreateNotification(agent.Name .. " is down!", Color3.fromRGB(200, 50, 50))
                            for i = #GameData.TerminatorAgents, 1, -1 do
                                if GameData.TerminatorAgents[i] == agent then
                                    table.remove(GameData.TerminatorAgents, i)
                                    break
                                end
                            end
                        end
                    else
                        local base = GetBase(anomalyInstance)
                        base.coreHealth = math.max(0, base.coreHealth - damage)
                        UpdateCoreDisplay()
                        if base.coreHealth <= 0 then
                            CompanyDestroyed(anomalyInstance.Base)
                            break
                        end
                    end
                end
                
                local base = GetBase(anomalyInstance)
                local dmgMult = base.perks.DmgMult
                for _, guard in ipairs(anomalyInstance.AssignedGuards) do
                    if guard.HP > 0 then
                        local gdamage = guard.Damage * dmgMult
                        local attacked = false
                        if anomalyInstance.Data.Special == "Radio" and #minions > 0 then
                            minions[1].HP = math.max(0, minions[1].HP - gdamage)
                            if minions[1].HP <= 0 then
                                table.remove(minions, 1)
                                CreateNotification("kHz 1750 Enemy defeated!", Color3.fromRGB(50, 200, 50))
                            end
                            attacked = true
                        elseif anomalyInstance.Data.Special == "Eyes" and #eyes > 0 then
                            eyes[1].HP = math.max(0, eyes[1].HP - gdamage)
                            if eyes[1].HP <= 0 then
                                table.remove(eyes, 1)
                                CreateNotification("Eye destroyed!", Color3.fromRGB(50, 200, 50))
                            end
                            attacked = true
                        end
                        if not attacked then
                            anomalyInstance.BreachHP = math.max(0, anomalyInstance.BreachHP - gdamage)
                        end
                        CreateNotification(guard.Name .. " attacked " .. breachData.Name .. " for " .. gdamage, Color3.fromRGB(50, 200, 50))
                    end
                end
                
                if anomalyInstance.Data.Special == "Eyes" and #eyes == 0 then
                    anomalyInstance.BreachHP = 0
                elseif anomalyInstance.Data.Special == "Radio" and #minions == 0 then
                    anomalyInstance.BreachHP = 0
                end
                
                if anomalyInstance.BreachHP <= 0 then
                    local wipe = anomalyInstance.ToBeExecuted
                    if wipe then
                        CreateNotification(anomalyInstance.Name .. " has been wiped forever!", Color3.fromRGB(255, 0, 0))
                        local base = GetBase(anomalyInstance)
                        for i = #base.anomalies, 1, -1 do
                            if base.anomalies[i] == anomalyInstance then
                                table.remove(base.anomalies, i)
                                break
                            end
                        end
                        if anomalyInstance.RoomFrame then
                            anomalyInstance.RoomFrame:Destroy()
                        end
                    else
                        CreateNotification(breachData.Name .. " has been contained!", Color3.fromRGB(50, 200, 50))
                        anomalyInstance.IsBreached = false
                        anomalyInstance.CurrentMood = anomalyInstance.Data.BaseMood / 2
                        anomalyInstance.BreachHP = nil
                    end
                    local base = GetBase(anomalyInstance)
                    for i, b in ipairs(base.breachedAnomalies) do
                        if b.Instance == anomalyInstance then
                            table.remove(base.breachedAnomalies, i)
                            break
                        end
                    end
                    UpdateRoomDisplay(anomalyInstance)
                    UpdateBreachAlert()
                    UpdateCoreDisplay()
                    break
                end
            end
        end
    end)
end

-- Initialize
RefreshAnomalyContainer()
StartWhiteTrain()
