-- Sorchesus Company - Complete Client-Side GUI Script
-- Fixed Crucible updates and added new employees
-- Modified for mobile friendliness
-- Updated with Outer Guards, mood decay, auto-worker every 5s, and new anomalies

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local isMobile = UserInputService.TouchEnabled

-- Game Data
local GameData = {
    Crucible = 100,
    OwnedAnomalies = {},
    WhiteTrainActive = false,
    TrainTimer = 0,
    CurrentDocuments = {},
    CosmicShardCoreHealth = 15700,
    MaxCoreHealth = 15700,
    BreachedAnomalies = {},
    WorkerNames = {"Michael", "Christina", "Tenna", "Ethan", "Andy", "Joe", "Richard", "Kaleb", "Brian"},
    GuardNames = {"Peter", "Rick", "Kyle", "Jayden", "Nolan", "Steven", "Spencer"},
    OwnedWorkers = {},
    OwnedGuards = {},
    OuterGuards = {}  -- New: Guards assigned as outer guards
}

-- Anomaly Database
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
        BaseMood = 10,
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
            Abilities = {"Chaos Strike", "Terror Pulse", "Equilibrium Drain", "Rage Surge"}
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
            Abilities = {"Harmony Beam", "Calming Aura", "Restorative Light", "Yin Pursuit"}
        },
        LinkedAnomaly = "Yin",
        BreachOnLinkedBreach = true
    },
    ["[ERROR]"] = {
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
            Abilities = {"Data Corruption", "Glitch Warp", "System Overload", "Error Cascade"}
        }
    },
    ["DISHEVELED MEAT MESS"] = {
        Description = "LET ME WEAR YOUR SKIN.",
        DangerClass = "XIV",
        BaseMood = 50,
        WorkResults = {
            Knowledge = {Success = 0.1, Crucible = 205, MoodChange = 5, MoodRequirement = 5},
            Social = {Success = 0.05, Crucible = 150, MoodChange = -10, MoodRequirement = 0},
            Hunt = {Success = 0.4, Crucible = 350, MoodChange = 45, MoodRequirement = 45},
            Passive = {Success = 0.2, Crucible = 500, MoodChange = -5, MoodRequirement = 0}
        },
        BreachChance = 0.05,
        BreachForm = {
            Name = "THE SCRAMBLER",
            Health = 14500,
            M1Damage = 450,
            Abilities = {"Skin Steal", "Meat Assimilate", "Flesh Rend", "Regenerative Feast"}
        }
    },
    ["Skeleton King"] = {
        Description = "The one who rules countless Skeleton, The one who's trapped here for decades after accidentally trusting the illusions. Would you join the force mortal and become my army?",
        DangerClass = "XIII",
        BaseMood = 30,
        WorkResults = {
            Knowledge = {Success = 0.6, Crucible = 100, MoodChange = 5, MoodRequirement = 5},
            Social = {Success = 0.5, Crucible = 95, MoodChange = 10, MoodRequirement = 10},
            Hunt = {Success = 0.6, Crucible = 120, MoodChange = 30, MoodRequirement = 30},
            Passive = {Success = 0.3, Crucible = 70, MoodChange = 5, MoodRequirement = 5}
        },
        BreachChance = 0.04,
        BreachForm = {
            Name = "The Skeleton Monarch",
            Health = 6500,
            M1Damage = 100,
            Abilities = {"Summon Skeleton Army", "Bone Curse", "Necrotic Conversion", "Monarch's Decree"}
        }
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
        BreachChance = 0.025,
        BreachForm = {
            Name = "GHz 7500",
            Health = 10,
            M1Damage = 80,
            Abilities = {"Broadcast Interference", "Frequency Overload", "Echo Haunt", "Signal Jam"}
        }
    },
    ["Theres Eyes in the Wall"] = {
        Description = "STOP STARING AT ME CREEPILY",
        DangerClass = "XII",
        BaseMood = 45,
        WorkResults = {
            Knowledge = {Success = 0.3, Crucible = 50, MoodChange = 10, MoodRequirement = 10},
            Social = {Success = 0.4, Crucible = 45, MoodChange = 5, MoodRequirement = 5},
            Hunt = {Success = 0.5, Crucible = 75, MoodChange = 20, MoodRequirement = 20},
            Passive = {Success = 0.1, Crucible = 35, MoodChange = -10, MoodRequirement = 0}
        },
        BreachChance = 0.03,
        BreachForm = {
            Name = "Spread The Rumors",
            Health = 10,
            M1Damage = 50,
            Abilities = {"Eye Spawn", "Stare Paralyze", "Rumor Spread", "Vision Overload"}
        }
    },
    ["Jar of Blood"] = {
        Description = "This Jar contains all the Grudge in the world.",
        DangerClass = "X",
        BaseMood = 50,
        WorkResults = {
            Knowledge = {Success = 0.7, Crucible = 10, MoodChange = 7, MoodRequirement = 7},
            Social = {Success = 0.5, Crucible = 27, MoodChange = 12, MoodRequirement = 12},
            Hunt = {Success = 0.3, Crucible = 50, MoodChange = 25, MoodRequirement = 25},
            Passive = {Success = 0.5, Crucible = 30, MoodChange = 5, MoodRequirement = 5}
        },
        BreachChance = 0,
        BreachForm = {
            Name = "None it cant breach",
            Health = 0,
            M1Damage = 0,
            Abilities = {}
        }
    }
}

-- Helper Functions
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
    -- Force update the label
    if CrucibleLabel then
        CrucibleLabel.Text = "Crucible: " .. GameData.Crucible
    end
end

local function UpdateRoomDisplay(anomalyInstance)
    local roomFrame = anomalyInstance.RoomFrame
    if not roomFrame then return end

    local moodLabel = roomFrame:FindFirstChild("MoodLabel")
    local moodBar = roomFrame:FindFirstChild("MoodBar")
    if moodLabel then
        moodLabel.Text = "Mood: " .. anomalyInstance.CurrentMood .. "/100"
    end
    if moodBar then
        local moodColor = anomalyInstance.CurrentMood > 50 and Color3.fromRGB(50, 150, 50) or 
                         anomalyInstance.CurrentMood > 20 and Color3.fromRGB(200, 150, 50) or 
                         Color3.fromRGB(200, 50, 50)
        TweenService:Create(moodBar, TweenInfo.new(0.3), {
            Size = UDim2.new(anomalyInstance.CurrentMood / 100, -10, 0, 8),
            BackgroundColor3 = moodColor
        }):Play()
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
        if child:IsA("TextButton") and child.Name ~= "InfoButton" then
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
        if child.Name == "AssignButton" then
            child.Active = not anomalyInstance.IsBreached
        end
    end
end

-- Mood decay loop
spawn(function()
    while true do
        wait(30)
        for _, anomalyInstance in ipairs(GameData.OwnedAnomalies) do
            if not anomalyInstance.IsBreached then
                local decay = 0
                local class = anomalyInstance.Data.DangerClass
                if class == "X" or class == "XI" then
                    decay = -5
                elseif class == "XII" or class == "XIII" then
                    decay = -10
                elseif class == "XIV" then
                    decay = -15
                end
                anomalyInstance.CurrentMood = math.clamp(anomalyInstance.CurrentMood + decay, 0, 100)
                UpdateRoomDisplay(anomalyInstance)
                if anomalyInstance.CurrentMood <= 0 then
                    TriggerBreach(anomalyInstance, anomalyInstance.RoomFrame)
                end
            end
        end
    end
end)

-- Worker auto-work loop
local function StartWorkerLoop(worker, anomalyInstance)
    spawn(function()
        while worker.AssignedTo == anomalyInstance and worker.HP > 0 and not anomalyInstance.IsBreached do
            wait(5)
            -- Perform work using Passive as default
            local workType = "Passive"
            local success = math.random() < worker.SuccessChance
            local workResult = anomalyInstance.Data.WorkResults[workType]
            local crucibleGain = success and workResult.Crucible or 0
            local moodChange = success and workResult.MoodChange or -math.abs(workResult.MoodChange * 2)
            UpdateCrucible(crucibleGain)
            anomalyInstance.CurrentMood = math.clamp(anomalyInstance.CurrentMood + moodChange, 0, 100)
            UpdateRoomDisplay(anomalyInstance)
            if anomalyInstance.CurrentMood <= 0 then
                TriggerBreach(anomalyInstance, anomalyInstance.RoomFrame)
                break
            end
        end
    end)
end

-- Create Main GUI
local MainGui = CreateInstance("ScreenGui", {
    Name = "SorchesusCompanyGUI",
    Parent = playerGui,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

-- Top Bar
local TopBar = CreateInstance("Frame", {
    Name = "TopBar",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0, 0)
})

local CompanyName = CreateInstance("TextLabel", {
    Name = "CompanyName",
    Parent = TopBar,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 300, 1, 0),
    Position = UDim2.new(0, 20, 0, 0),
    Text = "SORCHESUS COMPANY",
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
    Position = UDim2.new(0, 340, 0, 0),
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
    Position = UDim2.new(0, 460, 0, 0),
    Text = "Outer Guard",
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
    Position = UDim2.new(1, -220, 0, 0),
    Text = "Crucible: 100",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 215, 0),
    TextXAlignment = Enum.TextXAlignment.Right
})

-- Employee Shop GUI
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

-- Create employee cards in shop
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

for i, emp in ipairs(employees) do
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
                table.insert(GameData.OwnedWorkers, employee)
            else
                employee.Damage = emp.damage
                table.insert(GameData.OwnedGuards, employee)
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

-- Assign GUI
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

local AssignTitle = CreateInstance("TextLabel", {
    Name = "AssignTitle",
    Parent = AssignGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "ASSIGN WORKERS & GUARDS",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

-- Close button for Worker & Guards GUI (top right corner)
local CloseWGButton = CreateInstance("TextButton", {
    Name = "CloseWGButton",
    Parent = AssignGui,
    BackgroundColor3 = Color3.fromRGB(150, 50, 50),
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -35, 0, 5),
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    ZIndex = 11
})
CreateInstance("UICorner", {Parent = CloseWGButton, CornerRadius = UDim.new(0, 6)})

local WorkerSection = CreateInstance("ScrollingFrame", {
    Name = "WorkerSection",
    Parent = AssignGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    Size = UDim2.new(0.48, 0, 1, -100),
    Position = UDim2.new(0.01, 0, 0, 50),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6
})

local workerList = CreateInstance("UIListLayout", {
    Parent = WorkerSection,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local WorkerTitle = CreateInstance("TextLabel", {
    Parent = WorkerSection,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 30),
    Text = "Available Workers",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local GuardSection = CreateInstance("ScrollingFrame", {
    Name = "GuardSection",
    Parent = AssignGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    Size = UDim2.new(0.48, 0, 1, -100),
    Position = UDim2.new(0.51, 0, 0, 50),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6
})

local guardList = CreateInstance("UIListLayout", {
    Parent = GuardSection,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local GuardTitle = CreateInstance("TextLabel", {
    Parent = GuardSection,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 30),
    Text = "Available Guards",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local CloseAssignButtonBottom = CreateInstance("TextButton", {
    Name = "CloseButtonBottom",
    Parent = AssignGui,
    BackgroundColor3 = Color3.fromRGB(100, 100, 100),
    Size = UDim2.new(0, 100, 0, 35),
    Position = UDim2.new(0.5, -50, 1, -50),
    Text = "Close",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = CloseAssignButtonBottom, CornerRadius = UDim.new(0, 6)})

-- Outer Guard GUI
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

local OuterGuardTitle = CreateInstance("TextLabel", {
    Name = "OuterGuardTitle",
    Parent = OuterGuardGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "ASSIGN OUTER GUARDS",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local CloseOuterButton = CreateInstance("TextButton", {
    Name = "CloseOuterButton",
    Parent = OuterGuardGui,
    BackgroundColor3 = Color3.fromRGB(150, 50, 50),
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -35, 0, 5),
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    ZIndex = 11
})
CreateInstance("UICorner", {Parent = CloseOuterButton, CornerRadius = UDim.new(0, 6)})

local OuterGuardSection = CreateInstance("ScrollingFrame", {
    Name = "OuterGuardSection",
    Parent = OuterGuardGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    Size = UDim2.new(0.98, 0, 1, -100),
    Position = UDim2.new(0.01, 0, 0, 50),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 6
})

local outerGuardList = CreateInstance("UIListLayout", {
    Parent = OuterGuardSection,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local OuterGuardTitleLabel = CreateInstance("TextLabel", {
    Parent = OuterGuardSection,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 30),
    Text = "Available Guards for Outer",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local CloseOuterButtonBottom = CreateInstance("TextButton", {
    Name = "CloseButtonBottom",
    Parent = OuterGuardGui,
    BackgroundColor3 = Color3.fromRGB(100, 100, 100),
    Size = UDim2.new(0, 100, 0, 35),
    Position = UDim2.new(0.5, -50, 1, -50),
    Text = "Close",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = CloseOuterButtonBottom, CornerRadius = UDim.new(0, 6)})

-- Cosmic Shard Core Display
local CoreFrame = CreateInstance("Frame", {
    Name = "CoreFrame",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 30),
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(100, 200, 255),
    Size = UDim2.new(0.28, -20, 0.25, 0),
    Position = UDim2.new(0.72, 0, 0.5, 10)
})

CreateInstance("UICorner", {Parent = CoreFrame, CornerRadius = UDim.new(0, 10)})

local CoreTitle = CreateInstance("TextLabel", {
    Name = "CoreTitle",
    Parent = CoreFrame,
    BackgroundColor3 = Color3.fromRGB(30, 30, 50),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "COSMIC SHARD CORE",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(150, 220, 255)
})

CreateInstance("UICorner", {Parent = CoreTitle, CornerRadius = UDim.new(0, 10)})

local CoreHealthLabel = CreateInstance("TextLabel", {
    Name = "CoreHealthLabel",
    Parent = CoreFrame,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 50),
    Text = "Health: 15700 / 15700",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextXAlignment = Enum.TextXAlignment.Center
})

local CoreHealthBarBG = CreateInstance("Frame", {
    Name = "CoreHealthBarBG",
    Parent = CoreFrame,
    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
    BorderSizePixel = 0,
    Size = UDim2.new(1, -20, 0, 25),
    Position = UDim2.new(0, 10, 0, 85)
})

CreateInstance("UICorner", {Parent = CoreHealthBarBG, CornerRadius = UDim.new(0, 8)})

local CoreHealthBar = CreateInstance("Frame", {
    Name = "CoreHealthBar",
    Parent = CoreHealthBarBG,
    BackgroundColor3 = Color3.fromRGB(100, 200, 255),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0)
})

CreateInstance("UICorner", {Parent = CoreHealthBar, CornerRadius = UDim.new(0, 8)})

local CoreStatusLabel = CreateInstance("TextLabel", {
    Name = "CoreStatusLabel",
    Parent = CoreFrame,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 120),
    Text = "STATUS: PROTECTED",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(100, 255, 100),
    TextXAlignment = Enum.TextXAlignment.Center
})

-- Breach Alert Container
local BreachAlertContainer = CreateInstance("Frame", {
    Name = "BreachAlertContainer",
    Parent = MainGui,
    BackgroundTransparency = 1,
    Size = UDim2.new(0.28, -20, 0.15, 0),
    Position = UDim2.new(0.72, 0, 0.77, 0)
})

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
    CellSize = UDim2.new(isMobile and 1 or 0.5, -10, 0, 320),
    CellPadding = UDim2.new(0, 10, 0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder
})

-- White Train Panel
local TrainPanel = CreateInstance("Frame", {
    Name = "TrainPanel",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(25, 25, 35),
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(100, 100, 150),
    Size = UDim2.new(0.28, -20, 0.4, 0),
    Position = UDim2.new(0.72, 0, 0, 60)
})

local TrainTitle = CreateInstance("TextLabel", {
    Name = "TrainTitle",
    Parent = TrainPanel,
    BackgroundColor3 = Color3.fromRGB(35, 35, 50),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "THE WHITE TRAIN",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local TrainStatus = CreateInstance("TextLabel", {
    Name = "TrainStatus",
    Parent = TrainPanel,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 50),
    Text = "Arriving in 20:00...",
    Font = Enum.Font.Gotham,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(200, 200, 200),
    TextXAlignment = Enum.TextXAlignment.Left
})

local BuyDocButton = CreateInstance("TextButton", {
    Name = "BuyDocButton",
    Parent = TrainPanel,
    BackgroundColor3 = Color3.fromRGB(80, 50, 120),
    BorderSizePixel = 0,
    Size = UDim2.new(1, -20, 0, 50),
    Position = UDim2.new(0, 10, 0, 90),
    Text = "Get 3 Documents (-100 Crucible)",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Visible = false
})

CreateInstance("UICorner", {Parent = BuyDocButton, CornerRadius = UDim.new(0, 8)})

local TrainTimer = CreateInstance("TextLabel", {
    Name = "TrainTimer",
    Parent = TrainPanel,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 150),
    Text = "",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 100, 100),
    Visible = false
})

-- Document Selection GUI
local DocumentGui = CreateInstance("Frame", {
    Name = "DocumentGui",
    Parent = MainGui,
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    BorderSizePixel = 3,
    BorderColor3 = Color3.fromRGB(100, 100, 100),
    Size = isMobile and UDim2.new(0.95, 0, 0.95, 0) or UDim2.new(0, 600, 0, 450),
    Position = isMobile and UDim2.new(0.025, 0, 0.025, 0) or UDim2.new(0.5, -300, 0.5, -225),
    Visible = false,
    ZIndex = 10
})

local DocTitle = CreateInstance("TextLabel", {
    Name = "DocTitle",
    Parent = DocumentGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 40),
    Text = "SELECT ANOMALY DOCUMENT",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})

local DocContainer = CreateInstance("Frame", {
    Name = "DocContainer",
    Parent = DocumentGui,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -40, 0, 100),
    Position = UDim2.new(0, 20, 0, 60)
})

local docGrid = CreateInstance("UIGridLayout", {
    Parent = DocContainer,
    CellSize = UDim2.new(0.333, -10, 1, -10),
    CellPadding = UDim2.new(0, 10, 0, 0),
    SortOrder = Enum.SortOrder.LayoutOrder,
    FillDirection = Enum.FillDirection.Horizontal
})

for i = 1, 3 do
    local docBtn = CreateInstance("TextButton", {
        Name = "Document" .. i,
        Parent = DocContainer,
        BackgroundColor3 = Color3.fromRGB(50, 50, 60),
        BorderSizePixel = 2,
        BorderColor3 = Color3.fromRGB(100, 100, 120),
        Text = "Document " .. i,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255)
    })
    CreateInstance("UICorner", {Parent = docBtn, CornerRadius = UDim.new(0, 8)})
end

local AnomalyInfo = CreateInstance("Frame", {
    Name = "AnomalyInfo",
    Parent = DocumentGui,
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 2,
    BorderColor3 = Color3.fromRGB(70, 70, 70),
    Size = UDim2.new(1, -40, 0, 160),
    Position = UDim2.new(0, 20, 0, 160),
    Visible = false
})

local AnomalyNameLabel = CreateInstance("TextLabel", {
    Name = "AnomalyNameLabel",
    Parent = AnomalyInfo,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 5),
    Text = "",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = Color3.fromRGB(255, 200, 100),
    TextXAlignment = Enum.TextXAlignment.Left
})

local DangerClassLabel = CreateInstance("TextLabel", {
    Name = "DangerClassLabel",
    Parent = AnomalyInfo,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 25),
    Position = UDim2.new(0, 10, 0, 40),
    Text = "",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 100, 100),
    TextXAlignment = Enum.TextXAlignment.Left
})

local DescriptionLabel = CreateInstance("TextLabel", {
    Name = "DescriptionLabel",
    Parent = AnomalyInfo,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -20, 0, 50),
    Position = UDim2.new(0, 10, 0, 70),
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(200, 200, 200),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true
})

local AcceptButton = CreateInstance("TextButton", {
    Name = "AcceptButton",
    Parent = AnomalyInfo,
    BackgroundColor3 = Color3.fromRGB(50, 150, 50),
    Size = UDim2.new(0, 120, 0, 35),
    Position = UDim2.new(0, 10, 0, 125),
    Text = "Accept",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = AcceptButton, CornerRadius = UDim.new(0, 6)})

local DeclineButton = CreateInstance("TextButton", {
    Name = "DeclineButton",
    Parent = AnomalyInfo,
    BackgroundColor3 = Color3.fromRGB(150, 50, 50),
    Size = UDim2.new(0, 120, 0, 35),
    Position = UDim2.new(0, 140, 0, 125),
    Text = "Decline",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = DeclineButton, CornerRadius = UDim.new(0, 6)})

local CloseDocButton = CreateInstance("TextButton", {
    Name = "CloseButton",
    Parent = DocumentGui,
    BackgroundColor3 = Color3.fromRGB(100, 100, 100),
    Size = UDim2.new(0, 100, 0, 35),
    Position = UDim2.new(0.5, -50, 1, -50),
    Text = "Close",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 255, 255)
})
CreateInstance("UICorner", {Parent = CloseDocButton, CornerRadius = UDim.new(0, 6)})

-- Functions
local function PopulateOuterGuardGui()
    for _, child in pairs(OuterGuardSection:GetChildren()) do
        if child.Name ~= "UIGridLayout" and child.Name ~= "UIPadding" and child.Name ~= "TextLabel" and child.Name ~= "UIListLayout" then
            child:Destroy()
        end
    end

    for _, guard in ipairs(GameData.OwnedGuards) do
        if guard.HP > 0 and guard.AssignedTo == nil and not table.find(GameData.OuterGuards, guard) then
            local btn = CreateInstance("TextButton", {
                Parent = OuterGuardSection,
                BackgroundColor3 = Color3.fromRGB(60, 60, 80),
                Size = UDim2.new(1, -10, 0, 40),
                Text = guard.Name .. " (" .. guard.Type .. ") HP: " .. guard.HP,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
            CreateInstance("UICorner", {Parent = btn})
            btn.MouseButton1Click:Connect(function()
                table.insert(GameData.OuterGuards, guard)
                OuterGuardGui.Visible = false
                CreateNotification(guard.Name .. " assigned as Outer Guard", Color3.fromRGB(50, 200, 50))
            end
        end
    end
    OuterGuardSection.CanvasSize = UDim2.new(0, 0, 0, outerGuardList.AbsoluteContentSize.Y + 50)
end

local function PopulateAssignGui(anomalyInstance)
    AssignTitle.Text = "ASSIGN TO " .. anomalyInstance.Name:upper()
    
    for _, child in pairs(WorkerSection:GetChildren()) do
        if child.Name ~= "UIGridLayout" and child.Name ~= "UIPadding" and child.Name ~= "TextLabel" and child.Name ~= "UIListLayout" then
            child:Destroy()
        end
    end
    for _, child in pairs(GuardSection:GetChildren()) do
        if child.Name ~= "UIGridLayout" and child.Name ~= "UIPadding" and child.Name ~= "TextLabel" and child.Name ~= "UIListLayout" then
            child:Destroy()
        end
    end

    for _, worker in ipairs(GameData.OwnedWorkers) do
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

    for _, guard in ipairs(GameData.OwnedGuards) do
        if guard.HP > 0 and guard.AssignedTo == nil and not table.find(GameData.OuterGuards, guard) then
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

local function CreateAnomalyRoom(anomalyName)
    local anomalyData = AnomalyDatabase[anomalyName]
    if not anomalyData then return end
    
    local anomalyInstance = {
        Name = anomalyName,
        CurrentMood = anomalyData.BaseMood,
        Data = anomalyData,
        AssignedWorker = nil,
        AssignedGuards = {},
        IsBreached = false,
        RoomFrame = nil
    }
    
    table.insert(GameData.OwnedAnomalies, anomalyInstance)
    
    local roomFrame = CreateInstance("Frame", {
        Name = "AnomalyRoom_" .. #GameData.OwnedAnomalies,
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
        Text = anomalyName,
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
        Text = "Danger Class: " .. anomalyData.DangerClass,
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
    
    anomalyInstance.RoomFrame = roomFrame
    UpdateRoomDisplay(anomalyInstance)
    
    local function UpdateCanvasSize()
        local layout = AnomalyContainer:FindFirstChildOfClass("UIGridLayout")
        if layout then
            AnomalyContainer.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end
    end
    
    wait(0.1)
    UpdateCanvasSize()
    
    local layout = AnomalyContainer:FindFirstChildOfClass("UIGridLayout")
    if layout then
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSize)
    end
end

function PerformWork(anomalyInstance, workType, roomFrame)
    local workResult = anomalyInstance.Data.WorkResults[workType]
    if not workResult then return end
    
    local success = math.random() < workResult.Success
    local moodChange = 0

    if success then
        UpdateCrucible(workResult.Crucible)
        moodChange = workResult.MoodChange
        anomalyInstance.CurrentMood = math.clamp(anomalyInstance.CurrentMood + moodChange, 0, 100)

        if anomalyInstance.CurrentMood <= 0 then
            TriggerBreach(anomalyInstance, roomFrame)
        else
            if math.random() < anomalyInstance.Data.BreachChance then
                TriggerBreach(anomalyInstance, roomFrame)
            end
        end

        local moodText = moodChange >= 0 and ("+" .. moodChange) or tostring(moodChange)
        CreateNotification("Work Success! +" .. workResult.Crucible .. " Crucible (Mood: " .. moodText .. ")", Color3.fromRGB(50, 200, 50))
    else
        moodChange = math.abs(workResult.MoodChange) * 2 * -1
        anomalyInstance.CurrentMood = math.clamp(anomalyInstance.CurrentMood + moodChange, 0, 100)

        if anomalyInstance.CurrentMood <= 0 then
            TriggerBreach(anomalyInstance, roomFrame)
        else
            if math.random() < (anomalyInstance.Data.BreachChance * 3) then
                TriggerBreach(anomalyInstance, roomFrame)
            end
        end

        CreateNotification("Work Failed! Mood decreased by " .. math.abs(moodChange), Color3.fromRGB(200, 50, 50))
    end

    UpdateRoomDisplay(anomalyInstance)
end

function TriggerBreach(anomalyInstance, roomFrame)
    if anomalyInstance.IsBreached then return end

    local breachData = anomalyInstance.Data.BreachForm
    anomalyInstance.IsBreached = true
    anomalyInstance.BreachHP = breachData.Health

    table.insert(GameData.BreachedAnomalies, {
        Instance = anomalyInstance,
        BreachData = breachData,
        RoomFrame = roomFrame
    })

    CreateNotification("BREACH! " .. breachData.Name .. " has escaped!", Color3.fromRGB(255, 0, 0))

    UpdateRoomDisplay(anomalyInstance)
    UpdateBreachAlert()

    StartBreachLoop(anomalyInstance)
end

function StartBreachLoop(anomalyInstance)
    spawn(function()
        local breachData = anomalyInstance.Data.BreachForm
        while anomalyInstance.IsBreached do
            wait(2)

            local employees = {}
            if anomalyInstance.AssignedWorker and anomalyInstance.AssignedWorker.HP > 0 then
                table.insert(employees, anomalyInstance.AssignedWorker)
            end
            for _, guard in ipairs(anomalyInstance.AssignedGuards) do
                if guard.HP > 0 then
                    table.insert(employees, guard)
                end
            end

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

                for _, guard in ipairs(anomalyInstance.AssignedGuards) do
                    if guard.HP > 0 then
                        local gdamage = guard.Damage
                        anomalyInstance.BreachHP = math.max(0, anomalyInstance.BreachHP - gdamage)
                        CreateNotification(guard.Name .. " attacked " .. breachData.Name .. " for " .. gdamage, Color3.fromRGB(50, 200, 50))
                    end
                end

                if anomalyInstance.BreachHP <= 0 then
                    CreateNotification(breachData.Name .. " has been contained!", Color3.fromRGB(50, 200, 50))
                    anomalyInstance.IsBreached = false
                    anomalyInstance.CurrentMood = anomalyInstance.Data.BaseMood / 2
                    anomalyInstance.BreachHP = nil
                    for i, b in ipairs(GameData.BreachedAnomalies) do
                        if b.Instance == anomalyInstance then
                            table.remove(GameData.BreachedAnomalies, i)
                            break
                        end
                    end
                    UpdateRoomDisplay(anomalyInstance)
                    UpdateBreachAlert()
                    UpdateCoreDisplay()
                    break
                end
            else
                local damage = breachData.M1Damage
                GameData.CosmicShardCoreHealth = math.max(0, GameData.CosmicShardCoreHealth - damage)
                UpdateCoreDisplay()
                if GameData.CosmicShardCoreHealth <= 0 then
                    CompanyDestroyed()
                    break
                end
            end
        end
    end)
end

-- Button Connections
EmployeeButton.MouseButton1Click:Connect(function()
    EmployeeShop.Visible = true
end)

CloseShopButton.MouseButton1Click:Connect(function()
    EmployeeShop.Visible = false
end)

OuterGuardButton.MouseButton1Click:Connect(function()
    PopulateOuterGuardGui()
    OuterGuardGui.Visible = true
end)

CloseOuterButton.MouseButton1Click:Connect(function()
    OuterGuardGui.Visible = false
end)

CloseOuterButtonBottom.MouseButton1Click:Connect(function()
    OuterGuardGui.Visible = false
end)

CloseWGButton.MouseButton1Click:Connect(function()
    AssignGui.Visible = false
end)

CloseAssignButtonBottom.MouseButton1Click:Connect(function()
    AssignGui.Visible = false
end)

BuyDocButton.MouseButton1Click:Connect(function()
    if GameData.Crucible >= 100 then
        UpdateCrucible(-100)
        GameData.CurrentDocuments = GenerateRandomDocuments()
        DocumentGui.Visible = true
        AnomalyInfo.Visible = false
        CreateNotification("Documents purchased!", Color3.fromRGB(100, 200, 100))
    else
        CreateNotification("Not enough Crucible!", Color3.fromRGB(200, 50, 50))
    end
end)

for i = 1, 3 do
    local docBtn = DocContainer:FindFirstChild("Document" .. i)
    docBtn.MouseButton1Click:Connect(function()
        local selectedAnomaly = GameData.CurrentDocuments[i]
        if selectedAnomaly then
            local anomalyData = AnomalyDatabase[selectedAnomaly]
            
            AnomalyInfo.Visible = true
            AnomalyNameLabel.Text = "???"
            DangerClassLabel.Text = "Danger Class: ???"
            DescriptionLabel.Text = anomalyData.Description
            
            GameData.SelectedDocument = selectedAnomaly
            
            for j = 1, 3 do
                local btn = DocContainer:FindFirstChild("Document" .. j)
                btn.BorderColor3 = j == i and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(100, 100, 120)
                btn.BorderSizePixel = j == i and 3 or 2
            end
        end
    end)
end

AcceptButton.MouseButton1Click:Connect(function()
    if GameData.SelectedDocument then
        CreateAnomalyRoom(GameData.SelectedDocument)
        CreateNotification("Anomaly accepted: " .. GameData.SelectedDocument, Color3.fromRGB(50, 200, 50))
        DocumentGui.Visible = false
        AnomalyInfo.Visible = false
        GameData.SelectedDocument = nil
    end
end)

DeclineButton.MouseButton1Click:Connect(function()
    AnomalyInfo.Visible = false
    GameData.SelectedDocument = nil
    
    for i = 1, 3 do
        local btn = DocContainer:FindFirstChild("Document" .. i)
        btn.BorderColor3 = Color3.fromRGB(100, 100, 120)
        btn.BorderSizePixel = 2
    end
end)

CloseDocButton.MouseButton1Click:Connect(function()
    DocumentGui.Visible = false
    AnomalyInfo.Visible = false
    GameData.SelectedDocument = nil
end)

-- Initialize Game
wait(0.5)
CreateNotification("Welcome to Sorchesus Company!", Color3.fromRGB(200, 50, 50))
wait(2)

wait(3)
StartWhiteTrain()

print("Sorchesus Company GUI Loaded Successfully!")
