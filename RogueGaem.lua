-- Rogue Cheat for Fun - Client-Sided Script
local player = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Player Stats
local stats = {
    level = 1,
    xp = 0,
    xpRequired = 10,
    baseSpeed = 16,
    baseJump = 50,
    baseGravity = workspace.Gravity,
    speedBoosts = 0,
    jumpBoosts = 0,
    gravityBoosts = 0,
    hitboxSize = 0,
    hasEmpathy = false,
    hasJuggernaut = false,
    hasScaredyCat = false,
    scaredyCatActive = false,
    hasQuickEscape = false,
    quickEscapeLastTime = 0,
    extraXPGain = 0,
    hasGaleFighter = false
}

-- Buff and Debuff Tracking
local activeBuffs = {}
local activeDebuffs = {}
local slothfulConnection = nil
local slothfulDecreaseAmount = 0 -- Track how much speed was decreased by Slothful
local hasImmunity = false

local character
local humanoid
local hrp
local lastHealth

local createTeleportTool
local createDashTool
local createWarpTool
local createRadarTool
local createIntesignalTool
local createGamblingTool
local createShadowStepsTool
local updateXPBar
local showBuffCards
local addXP
local findSafePlatform
local getAllPlatforms
local applyRandomDebuff
local clearDebuffs
local updateBuffDebuffUI

-- Juggernaut Variables
_G.HeadSize = 10
_G.Disabled = false

-- Tool Buff Tracking
local isToolBuff = {
    ["Disappear-o Lite!"] = true,
    ["Warper"] = true,
    ["Disappear-o!"] = true,
    ["Dashies"] = true,
    ["Soul Offer"] = true,
    ["Radar"] = true,
    ["intesignal"] = true,
    ["Miniature Gambling Slot"] = true,
    ["Shadow Steps"] = true
}
local acquiredToolEffects = {}

-- Debuffs Database
local debuffs = {
    {
        name = "Heavy",
        desc = "-10 Speed",
        apply = function()
            if humanoid then
                humanoid.WalkSpeed = humanoid.WalkSpeed - 10
            end
        end,
        remove = function()
            if humanoid then
                humanoid.WalkSpeed = humanoid.WalkSpeed + 10
            end
        end
    },
    {
        name = "Anchored",
        desc = "-10 Jump Power",
        apply = function()
            if humanoid then
                if humanoid.JumpPower then
                    humanoid.JumpPower = humanoid.JumpPower - 10
                else
                    humanoid.JumpHeight = humanoid.JumpHeight - 10
                end
            end
        end,
        remove = function()
            if humanoid then
                if humanoid.JumpPower then
                    humanoid.JumpPower = humanoid.JumpPower + 10
                else
                    humanoid.JumpHeight = humanoid.JumpHeight + 10
                end
            end
        end
    },
    {
        name = "Empty Handed",
        desc = "Tool buffs don't respawn",
        apply = function()
            acquiredToolEffects = {}
        end,
        remove = function()
            -- Tools will naturally respawn on next death
        end
    },
    {
        name = "Hopeless",
        desc = "Remove 3 buffs",
        apply = function()
            for i = 1, 3 do
                if #activeBuffs > 0 then
                    local randIdx = math.random(1, #activeBuffs)
                    local buffName = activeBuffs[randIdx]
                    table.remove(activeBuffs, randIdx)
                    print("Lost buff: " .. buffName)
                end
            end
        end,
        remove = function()
            -- Buffs are permanently lost
        end
    },
    {
        name = "Meaningless",
        desc = "-5 XP Gain",
        apply = function()
            stats.extraXPGain = stats.extraXPGain - 5
        end,
        remove = function()
            stats.extraXPGain = stats.extraXPGain + 5
        end
    },
    {
        name = "Misfortune",
        desc = "Level 10-50 buffs can't spawn",
        apply = function()
            -- Handled in showBuffCards
        end,
        remove = function()
            -- Handled in showBuffCards
        end
    },
    {
        name = "Slothful",
        desc = "-1 Speed every 1 second (max -2)",
        apply = function()
            slothfulDecreaseAmount = 0
            slothfulConnection = game:GetService("RunService").Heartbeat:Connect(function()
                wait(1)
                if humanoid and humanoid.Health > 0 and slothfulDecreaseAmount < 2 then
                    humanoid.WalkSpeed = humanoid.WalkSpeed - 1
                    slothfulDecreaseAmount = slothfulDecreaseAmount + 1
                    print("Slothful: Speed decreased by 1 (Total: -" .. slothfulDecreaseAmount .. ")")
                end
            end)
        end,
        remove = function()
            if slothfulConnection then
                slothfulConnection:Disconnect()
                slothfulConnection = nil
            end
            -- Restore the speed that was lost
            if humanoid and slothfulDecreaseAmount > 0 then
                humanoid.WalkSpeed = humanoid.WalkSpeed + slothfulDecreaseAmount
                print("Slothful removed: Restored " .. slothfulDecreaseAmount .. " speed")
                slothfulDecreaseAmount = 0
            end
        end
    },
    {
        name = "Sinner",
        desc = "Can't gain buffs",
        apply = function()
            -- Handled in showBuffCards and buff selection
        end,
        remove = function()
            -- Handled in showBuffCards
        end
    },
    {
        name = "Genesis",
        desc = "2 debuffs on death instead of 1",
        apply = function()
            -- Handled in death detection
        end,
        remove = function()
            -- No special cleanup needed
        end
    },
    {
        name = "Mimicry",
        desc = "Die if someone dies within 11-25 studs",
        apply = function()
            -- Handled in kill detection system
        end,
        remove = function()
            -- No special cleanup needed
        end
    },
    {
        name = "Payment",
        desc = "-10 Speed, -10 Jump (Immunity Cost)",
        apply = function()
            if humanoid then
                humanoid.WalkSpeed = humanoid.WalkSpeed - 10
                if humanoid.JumpPower then
                    humanoid.JumpPower = humanoid.JumpPower - 10
                else
                    humanoid.JumpHeight = humanoid.JumpHeight - 10
                end
            end
        end,
        remove = function()
            -- Payment debuff cannot be removed
            print("Payment debuff cannot be removed!")
        end,
        isPayment = true -- Special flag
    }
}

-- Apply Random Debuff on Death
applyRandomDebuff = function()
    -- Check for Immunity buff
    if hasImmunity then
        print("Immunity active! No debuff applied, but Payment cost will be added on respawn.")
        return
    end
    
    -- Check for Genesis debuff (apply 2 debuffs instead of 1)
    local hasGenesis = false
    for _, debuffName in ipairs(activeDebuffs) do
        if debuffName == "Genesis" then
            hasGenesis = true
            break
        end
    end
    
    local numDebuffs = hasGenesis and 2 or 1
    
    for i = 1, numDebuffs do
        if #debuffs > 0 then
            local randDebuff = debuffs[math.random(1, #debuffs)]
            -- Skip Payment debuff from random selection
            while randDebuff.isPayment do
                randDebuff = debuffs[math.random(1, #debuffs)]
            end
            table.insert(activeDebuffs, randDebuff.name)
            randDebuff.apply()
            print("Debuff applied: " .. randDebuff.name)
        end
    end
    
    updateBuffDebuffUI()
end

-- Apply Payment Debuff (for Immunity)
local function applyPaymentDebuff()
    for _, debuff in ipairs(debuffs) do
        if debuff.isPayment then
            table.insert(activeDebuffs, debuff.name)
            debuff.apply()
            print("Payment debuff applied!")
            updateBuffDebuffUI()
            break
        end
    end
end

-- Clear One Random Debuff
local function clearOneDebuff()
    if #activeDebuffs > 0 then
        -- Filter out Payment debuffs (they cannot be removed)
        local removableDebuffs = {}
        for i, debuffName in ipairs(activeDebuffs) do
            if debuffName ~= "Payment" then
                table.insert(removableDebuffs, {index = i, name = debuffName})
            end
        end
        
        if #removableDebuffs > 0 then
            local selected = removableDebuffs[math.random(1, #removableDebuffs)]
            local debuffName = selected.name
            
            -- Find and remove the debuff
            for _, debuff in ipairs(debuffs) do
                if debuff.name == debuffName then
                    debuff.remove()
                    break
                end
            end
            
            table.remove(activeDebuffs, selected.index)
            updateBuffDebuffUI()
            print("Debuff removed: " .. debuffName)
        else
            print("Only Payment debuffs remain - cannot be removed!")
        end
    end
end

-- Clear All Debuffs (used for skip button)
clearDebuffs = function()
    for _, debuffName in ipairs(activeDebuffs) do
        for _, debuff in ipairs(debuffs) do
            if debuff.name == debuffName then
                debuff.remove()
                break
            end
        end
    end
    activeDebuffs = {}
    updateBuffDebuffUI()
    print("All debuffs cleared!")
end

local function setTransparency(char, transparency)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.Transparency = transparency
        end
    end
end

local function setNoClip(enabled)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end
end

-- Buffs Database
local buffs = {
    {name = "XP-E", desc = "+1 XP Gain", effect = function() 
        stats.extraXPGain = stats.extraXPGain + 1
        table.insert(activeBuffs, "XP-E")
    end, req = 1},
    {name = "Walkie", desc = "+1 Speed", effect = function() 
        stats.speedBoosts = stats.speedBoosts + 1
        if humanoid then
            humanoid.WalkSpeed = humanoid.WalkSpeed + 1
        end
        table.insert(activeBuffs, "Walkie")
    end, req = 1},
    {name = "Hopper", desc = "+1 Jump Power", effect = function() 
        stats.jumpBoosts = stats.jumpBoosts + 1
        if humanoid then
            if humanoid.JumpPower then
                humanoid.JumpPower = humanoid.JumpPower + 1
            else
                humanoid.JumpHeight = humanoid.JumpHeight + 1
            end
        end
        table.insert(activeBuffs, "Hopper")
    end, req = 1},
    {name = "Floating in Space", desc = "-0.5 Gravity", effect = function() 
        stats.gravityBoosts = stats.gravityBoosts + 0.5
        workspace.Gravity = workspace.Gravity - 0.5
        table.insert(activeBuffs, "Floating in Space")
    end, req = 1},
    {name = "Speedster", desc = "+5 Speed", effect = function() 
        stats.speedBoosts = stats.speedBoosts + 5
        if humanoid then
            humanoid.WalkSpeed = humanoid.WalkSpeed + 5
        end
        table.insert(activeBuffs, "Speedster")
    end, req = 3},
    {name = "Bunny Hopper", desc = "+5 Jump Power", effect = function() 
        stats.jumpBoosts = stats.jumpBoosts + 5
        if humanoid then
            if humanoid.JumpPower then
                humanoid.JumpPower = humanoid.JumpPower + 5
            else
                humanoid.JumpHeight = humanoid.JumpHeight + 5
            end
        end
        table.insert(activeBuffs, "Bunny Hopper")
    end, req = 3},
    {name = "Spaceborn", desc = "-2 Gravity", effect = function() 
        stats.gravityBoosts = stats.gravityBoosts + 2
        workspace.Gravity = workspace.Gravity - 2
        table.insert(activeBuffs, "Spaceborn")
    end, req = 3},
    {name = "Strong Feets", desc = "+10 Jump Power", effect = function() 
        stats.jumpBoosts = stats.jumpBoosts + 10
        if humanoid then
            if humanoid.JumpPower then
                humanoid.JumpPower = humanoid.JumpPower + 10
            else
                humanoid.JumpHeight = humanoid.JumpHeight + 10
            end
        end
        table.insert(activeBuffs, "Strong Feets")
    end, req = 3},
    {name = "Lightning Speed", desc = "+10 Speed", effect = function() 
        stats.speedBoosts = stats.speedBoosts + 10
        if humanoid then
            humanoid.WalkSpeed = humanoid.WalkSpeed + 10
        end
        table.insert(activeBuffs, "Lightning Speed")
    end, req = 5},
    {name = "Zero Gravity", desc = "-100 Gravity", effect = function() 
        stats.gravityBoosts = stats.gravityBoosts + 100
        workspace.Gravity = workspace.Gravity - 100
        table.insert(activeBuffs, "Zero Gravity")
    end, req = 5},
    {name = "Disappear-o Lite!", desc = "Teleport Tool (1 Use)", effect = function() 
        createTeleportTool(1)
        table.insert(activeBuffs, "Disappear-o Lite!")
    end, req = 5},
    {name = "Warper", desc = "Warp to Player by Username", effect = function() 
        createWarpTool()
        table.insert(activeBuffs, "Warper")
    end, req = 5},
    {name = "XP-ORT", desc = "+5 XP Gain", effect = function() 
        stats.extraXPGain = stats.extraXPGain + 5
        table.insert(activeBuffs, "XP-ORT")
    end, req = 10},
    {name = "Disappear-o!", desc = "5x Teleport Tool", effect = function() 
        createTeleportTool(5)
        table.insert(activeBuffs, "Disappear-o!")
    end, req = 10},
    {name = "Empathy", desc = "Kill: +3 Speed, -15 HP", effect = function() 
        stats.hasEmpathy = true
        table.insert(activeBuffs, "Empathy")
    end, req = 10},
    {name = "Scaredy Cat", desc = "When Damaged: +5 Speed for 3s", effect = function() 
        stats.hasScaredyCat = true
        table.insert(activeBuffs, "Scaredy Cat")
    end, req = 10},
    {name = "Quick Escape", desc = "Under 10 HP: Random TP (1m CD)", effect = function() 
        stats.hasQuickEscape = true
        table.insert(activeBuffs, "Quick Escape")
    end, req = 10},
    {name = "XP-AND", desc = "+15 XP Gain", effect = function() 
        stats.extraXPGain = stats.extraXPGain + 15
        table.insert(activeBuffs, "XP-AND")
    end, req = 25},
    {name = "Dashies", desc = "Dash Tool (Forward Boost)", effect = function() 
        createDashTool()
        table.insert(activeBuffs, "Dashies")
    end, req = 25},
    {name = "Juggernaut", desc = "Bigger Hitbox, -6 Speed", effect = function() 
        stats.speedBoosts = stats.speedBoosts - 6
        if humanoid then
            humanoid.WalkSpeed = humanoid.WalkSpeed - 6
        end
        stats.hasJuggernaut = true
        stats.hitboxSize = stats.hitboxSize + 10
        _G.HeadSize = 10 + stats.hitboxSize
        _G.Disabled = true
        table.insert(activeBuffs, "Juggernaut")
    end, req = 25},
    {name = "Soul Offer", desc = "Infinite TP, -90 HP per use", effect = function() 
        createTeleportTool(-1)
        table.insert(activeBuffs, "Soul Offer")
    end, req = 25},
    {name = "Radar", desc = "ESP Tool (3s duration)", effect = function() 
        createRadarTool()
        table.insert(activeBuffs, "Radar")
    end, req = 25},
    {name = "intesignal", desc = "Infinite ESP, 15s CD, Lose 3 buffs", effect = function() 
        -- Remove 3 random buffs
        for i = 1, 3 do
            if #activeBuffs > 0 then
                local randIdx = math.random(1, #activeBuffs)
                table.remove(activeBuffs, randIdx)
            end
        end
        createIntesignalTool()
        table.insert(activeBuffs, "intesignal")
    end, req = 45},
    {name = "Miniature Gambling Slot", desc = "Gambling Tool - Risk/Reward", effect = function() 
        createGamblingTool()
        table.insert(activeBuffs, "Miniature Gambling Slot")
    end, req = 45},
    {name = "Immunity", desc = "No debuff on death, but -10 Speed & Jump per death", effect = function() 
        hasImmunity = true
        table.insert(activeBuffs, "Immunity")
    end, req = 45},
    {name = "Gale Fighter", desc = "Every Kill: +5 Speed, +5 Jump, +5 Hitbox (Start 5, Max 50)", effect = function() 
        stats.hasGaleFighter = true
        stats.hitboxSize = stats.hitboxSize + 5
        _G.HeadSize = 10 + stats.hitboxSize
        _G.Disabled = true
        table.insert(activeBuffs, "Gale Fighter")
    end, req = 45},
    {name = "Shadow Steps", desc = "Dash Tool (Invisible, Noclip, 20+ Speed, 1.5s)", effect = function() 
        createShadowStepsTool()
        table.insert(activeBuffs, "Shadow Steps")
    end, req = 45}
}

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RogueCheatGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- XP Bar Frame
local xpFrame = Instance.new("Frame")
xpFrame.Size = UDim2.new(0, 300, 0, 60)
xpFrame.Position = UDim2.new(0.5, -150, 0, 20)
xpFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
xpFrame.BorderSizePixel = 2
xpFrame.BorderColor3 = Color3.fromRGB(255, 200, 0)
xpFrame.Parent = screenGui

local xpBarBg = Instance.new("Frame")
xpBarBg.Size = UDim2.new(1, -20, 0, 20)
xpBarBg.Position = UDim2.new(0, 10, 0, 30)
xpBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
xpBarBg.BorderSizePixel = 0
xpBarBg.Parent = xpFrame

local xpBar = Instance.new("Frame")
xpBar.Size = UDim2.new(0, 0, 1, 0)
xpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
xpBar.BorderSizePixel = 0
xpBar.Parent = xpBarBg

local levelLabel = Instance.new("TextLabel")
levelLabel.Size = UDim2.new(1, 0, 0, 20)
levelLabel.Position = UDim2.new(0, 0, 0, 5)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "Level 1"
levelLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextSize = 16
levelLabel.Parent = xpFrame

local xpLabel = Instance.new("TextLabel")
xpLabel.Size = UDim2.new(1, 0, 0, 15)
xpLabel.Position = UDim2.new(0, 0, 0, 32)
xpLabel.BackgroundTransparency = 1
xpLabel.Text = "0 / 10 XP"
xpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
xpLabel.Font = Enum.Font.Gotham
xpLabel.TextSize = 12
xpLabel.Parent = xpFrame

-- Active Buffs Button
local activeBuffsButton = Instance.new("TextButton")
activeBuffsButton.Size = UDim2.new(0, 70, 0, 25)
activeBuffsButton.Position = UDim2.new(0, 10, 1, 5)
activeBuffsButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
activeBuffsButton.BorderSizePixel = 2
activeBuffsButton.BorderColor3 = Color3.fromRGB(255, 200, 0)
activeBuffsButton.Text = "Buffs"
activeBuffsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
activeBuffsButton.Font = Enum.Font.GothamBold
activeBuffsButton.TextSize = 12
activeBuffsButton.Parent = xpFrame

-- Active Debuffs Button
local activeDebuffsButton = Instance.new("TextButton")
activeDebuffsButton.Size = UDim2.new(0, 70, 0, 25)
activeDebuffsButton.Position = UDim2.new(0, 90, 1, 5)
activeDebuffsButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
activeDebuffsButton.BorderSizePixel = 2
activeDebuffsButton.BorderColor3 = Color3.fromRGB(255, 200, 0)
activeDebuffsButton.Text = "Debuffs"
activeDebuffsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
activeDebuffsButton.Font = Enum.Font.GothamBold
activeDebuffsButton.TextSize = 12
activeDebuffsButton.Parent = xpFrame

-- Buffs Dropdown
local buffsDropdown = Instance.new("Frame")
buffsDropdown.Size = UDim2.new(0, 200, 0, 250)
buffsDropdown.Position = UDim2.new(0, 0, 1, 30)
buffsDropdown.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
buffsDropdown.BorderSizePixel = 2
buffsDropdown.BorderColor3 = Color3.fromRGB(0, 200, 0)
buffsDropdown.Visible = false
buffsDropdown.Parent = xpFrame

local buffsScrollFrame = Instance.new("ScrollingFrame")
buffsScrollFrame.Size = UDim2.new(1, 0, 1, -30)
buffsScrollFrame.Position = UDim2.new(0, 0, 0, 30)
buffsScrollFrame.BackgroundTransparency = 1
buffsScrollFrame.BorderSizePixel = 0
buffsScrollFrame.ScrollBarThickness = 4
buffsScrollFrame.Parent = buffsDropdown

local buffsListLayout = Instance.new("UIListLayout")
buffsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
buffsListLayout.Parent = buffsScrollFrame

local buffsTitle = Instance.new("TextLabel")
buffsTitle.Size = UDim2.new(1, 0, 0, 30)
buffsTitle.BackgroundTransparency = 1
buffsTitle.Text = "Active Buffs"
buffsTitle.TextColor3 = Color3.fromRGB(0, 255, 0)
buffsTitle.Font = Enum.Font.GothamBold
buffsTitle.TextSize = 14
buffsTitle.Parent = buffsDropdown

local closeBuffsButton = Instance.new("TextButton")
closeBuffsButton.Size = UDim2.new(0, 50, 0, 30)
closeBuffsButton.Position = UDim2.new(1, -50, 0, 0)
closeBuffsButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeBuffsButton.BorderSizePixel = 0
closeBuffsButton.Text = "Close"
closeBuffsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBuffsButton.Font = Enum.Font.GothamBold
closeBuffsButton.TextSize = 12
closeBuffsButton.Parent = buffsDropdown

-- Debuffs Dropdown
local debuffsDropdown = Instance.new("Frame")
debuffsDropdown.Size = UDim2.new(0, 200, 0, 250)
debuffsDropdown.Position = UDim2.new(0, 0, 1, 30)
debuffsDropdown.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
debuffsDropdown.BorderSizePixel = 2
debuffsDropdown.BorderColor3 = Color3.fromRGB(200, 0, 0)
debuffsDropdown.Visible = false
debuffsDropdown.Parent = xpFrame

local debuffsScrollFrame = Instance.new("ScrollingFrame")
debuffsScrollFrame.Size = UDim2.new(1, 0, 1, -30)
debuffsScrollFrame.Position = UDim2.new(0, 0, 0, 30)
debuffsScrollFrame.BackgroundTransparency = 1
debuffsScrollFrame.BorderSizePixel = 0
debuffsScrollFrame.ScrollBarThickness = 4
debuffsScrollFrame.Parent = debuffsDropdown

local debuffsListLayout = Instance.new("UIListLayout")
debuffsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
debuffsListLayout.Parent = debuffsScrollFrame

local debuffsTitle = Instance.new("TextLabel")
debuffsTitle.Size = UDim2.new(1, 0, 0, 30)
debuffsTitle.BackgroundTransparency = 1
debuffsTitle.Text = "Active Debuffs"
debuffsTitle.TextColor3 = Color3.fromRGB(255, 0, 0)
debuffsTitle.Font = Enum.Font.GothamBold
debuffsTitle.TextSize = 14
debuffsTitle.Parent = debuffsDropdown

local closeDebuffsButton = Instance.new("TextButton")
closeDebuffsButton.Size = UDim2.new(0, 50, 0, 30)
closeDebuffsButton.Position = UDim2.new(1, -50, 0, 0)
closeDebuffsButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeDebuffsButton.BorderSizePixel = 0
closeDebuffsButton.Text = "Close"
closeDebuffsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeDebuffsButton.Font = Enum.Font.GothamBold
closeDebuffsButton.TextSize = 12
closeDebuffsButton.Parent = debuffsDropdown

-- Button Connections
activeBuffsButton.MouseButton1Click:Connect(function()
    buffsDropdown.Visible = not buffsDropdown.Visible
    debuffsDropdown.Visible = false
end)

activeDebuffsButton.MouseButton1Click:Connect(function()
    debuffsDropdown.Visible = not debuffsDropdown.Visible
    buffsDropdown.Visible = false
end)

closeBuffsButton.MouseButton1Click:Connect(function()
    buffsDropdown.Visible = false
end)

closeDebuffsButton.MouseButton1Click:Connect(function()
    debuffsDropdown.Visible = false
end)

-- Update Buff/Debuff UI
updateBuffDebuffUI = function()
    -- Clear existing items
    for _, child in ipairs(buffsScrollFrame:GetChildren()) do
        if child:IsA("TextLabel") and child.Name == "BuffItem" then
            child:Destroy()
        end
    end
    for _, child in ipairs(debuffsScrollFrame:GetChildren()) do
        if child:IsA("TextLabel") and child.Name == "DebuffItem" then
            child:Destroy()
        end
    end
    
    -- Add active buffs
    for _, buffName in ipairs(activeBuffs) do
        local item = Instance.new("TextLabel")
        item.Name = "BuffItem"
        item.Size = UDim2.new(1, -10, 0, 25)
        item.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        item.BorderSizePixel = 0
        item.Text = "• " .. buffName
        item.TextColor3 = Color3.fromRGB(0, 255, 0)
        item.Font = Enum.Font.Gotham
        item.TextSize = 12
        item.TextXAlignment = Enum.TextXAlignment.Left
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 5)
        padding.Parent = item
        item.Parent = buffsScrollFrame
    end
    
    -- Add active debuffs
    for _, debuffName in ipairs(activeDebuffs) do
        local item = Instance.new("TextLabel")
        item.Name = "DebuffItem"
        item.Size = UDim2.new(1, -10, 0, 25)
        item.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        item.BorderSizePixel = 0
        item.Text = "• " .. debuffName
        item.TextColor3 = Color3.fromRGB(255, 0, 0)
        item.Font = Enum.Font.Gotham
        item.TextSize = 12
        item.TextXAlignment = Enum.TextXAlignment.Left
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 5)
        padding.Parent = item
        item.Parent = debuffsScrollFrame
    end
    
    buffsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, buffsListLayout.AbsoluteContentSize.Y)
    debuffsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, debuffsListLayout.AbsoluteContentSize.Y)
end

-- Skip to Next Level Button
local skipButton = Instance.new("TextButton")
skipButton.Size = UDim2.new(0, 150, 0, 40)
skipButton.Position = UDim2.new(1, -160, 0, 10)
skipButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
skipButton.BorderSizePixel = 2
skipButton.BorderColor3 = Color3.fromRGB(255, 200, 0)
skipButton.Text = "Skip to Next Level"
skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
skipButton.Font = Enum.Font.GothamBold
skipButton.TextSize = 14
skipButton.Parent = screenGui

skipButton.MouseButton1Click:Connect(function()
    stats.level = stats.level + 1
    stats.xp = 0
    stats.xpRequired = stats.xpRequired + 10
    clearDebuffs()
    updateXPBar()
    showBuffCards()
end)

-- Dropdown for all buffs (cheat menu)
local dropdownButton = Instance.new("TextButton")
dropdownButton.Size = UDim2.new(0, 100, 0, 30)
dropdownButton.Position = UDim2.new(0, 10, 0, 10)
dropdownButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
dropdownButton.BorderSizePixel = 2
dropdownButton.BorderColor3 = Color3.fromRGB(255, 200, 0)
dropdownButton.Text = "Buffs ▼"
dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownButton.Font = Enum.Font.GothamBold
dropdownButton.TextSize = 14
dropdownButton.Parent = screenGui

local buffListFrame = Instance.new("ScrollingFrame")
buffListFrame.Size = UDim2.new(0, 200, 0, 300)
buffListFrame.Position = UDim2.new(0, 10, 0, 50)
buffListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
buffListFrame.BorderSizePixel = 2
buffListFrame.BorderColor3 = Color3.fromRGB(255, 200, 0)
buffListFrame.Visible = false
buffListFrame.Parent = screenGui

local yPos = 0
for _, buff in ipairs(buffs) do
    local buffBtn = Instance.new("TextButton")
    buffBtn.Size = UDim2.new(1, 0, 0, 30)
    buffBtn.Position = UDim2.new(0, 0, 0, yPos)
    buffBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    buffBtn.BorderSizePixel = 0
    buffBtn.Text = buff.name
    buffBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    buffBtn.Font = Enum.Font.Gotham
    buffBtn.TextSize = 14
    buffBtn.Parent = buffListFrame
    
    buffBtn.MouseButton1Click:Connect(function()
        buff.effect()
        if isToolBuff[buff.name] then
            table.insert(acquiredToolEffects, buff.effect)
        end
        updateBuffDebuffUI()
    end)
    
    yPos = yPos + 30
end
buffListFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)

dropdownButton.MouseButton1Click:Connect(function()
    buffListFrame.Visible = not buffListFrame.Visible
end)

-- Update XP Bar Display
updateXPBar = function()
    local progress = stats.xp / stats.xpRequired
    xpBar:TweenSize(UDim2.new(progress, 0, 1, 0), "Out", "Quad", 0.3, true)
    levelLabel.Text = "Level " .. stats.level
    xpLabel.Text = stats.xp .. " / " .. stats.xpRequired .. " XP"
end

-- Create Teleport Tool
createTeleportTool = function(uses)
    local mouse = player:GetMouse()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    
    local baseName
    if uses == -1 then
        baseName = "Soul Offer TP (Infinite, -90 HP)"
        tool.Name = baseName
    else
        tool.Name = "Teleport Tool (" .. uses .. " Uses)"
    end
    
    local cooldown = 10
    local lastUse = 0
    local onCooldown = false
    
    tool.Activated:Connect(function()
        if not humanoid or not hrp then return end
        if uses == -1 then
            if os.time() - lastUse >= cooldown then
                lastUse = os.time()
                local pos = mouse.Hit + Vector3.new(0, 2.5, 0)
                pos = CFrame.new(pos.X, pos.Y, pos.Z)
                hrp.CFrame = pos
                humanoid.Health = math.max(humanoid.Health - 90, 1)
                spawn(function()
                    if onCooldown then return end
                    onCooldown = true
                    for i = cooldown, 1, -1 do
                        tool.Name = "Soul Offer TP (Cooldown: " .. i .. "s)"
                        wait(1)
                    end
                    tool.Name = baseName
                    onCooldown = false
                end)
            end
        elseif uses > 0 then
            local pos = mouse.Hit + Vector3.new(0, 2.5, 0)
            pos = CFrame.new(pos.X, pos.Y, pos.Z)
            hrp.CFrame = pos
            uses = uses - 1
            tool.Name = "Teleport Tool (" .. uses .. " Uses)"
            if uses <= 0 then
                tool:Destroy()
            end
        end
    end)
    
    tool.Parent = player.Backpack
end

createDashTool = function()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "Dash Tool"
    local cooldown = 10
    local lastUse = 0
    local onCooldown = false
    
    tool.Activated:Connect(function()
        if not humanoid or not hrp then return end
        if os.time() - lastUse >= cooldown then
            lastUse = os.time()
            local currentSpeed = humanoid.WalkSpeed
            local dashSpeed = 15 + currentSpeed
            
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(100000, 0, 100000)
            bodyVel.Velocity = hrp.CFrame.LookVector * dashSpeed
            bodyVel.Parent = hrp
            
            spawn(function()
                wait(1)
                bodyVel:Destroy()
            end)
            
            spawn(function()
                if onCooldown then return end
                onCooldown = true
                for i = cooldown, 1, -1 do
                    tool.Name = "Dash Tool (Cooldown: " .. i .. "s)"
                    wait(1)
                end
                tool.Name = "Dash Tool"
                onCooldown = false
            end)
        end
    end)
    
    tool.Parent = player.Backpack
end

createShadowStepsTool = function()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "Shadow Steps"
    local cooldown = 10
    local lastUse = 0
    local onCooldown = false
    
    tool.Activated:Connect(function()
        if not humanoid or not hrp or not character then return end
        if os.time() - lastUse >= cooldown then
            lastUse = os.time()
            local dashSpeed = 20 + humanoid.WalkSpeed
            
            -- Invis on
            local savedpos = hrp.CFrame
            wait()
            character:MoveTo(Vector3.new(-25.95, 84, 3537.55))
            wait(.15)
            local Seat = Instance.new('Seat', workspace)
            Seat.Anchored = false
            Seat.CanCollide = false
            Seat.Name = 'invischair'
            Seat.Transparency = 1
            Seat.Position = Vector3.new(-25.95, 84, 3537.55)
            local Weld = Instance.new("Weld", Seat)
            Weld.Part0 = Seat
            Weld.Part1 = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
            wait()
            Seat.CFrame = savedpos
            setTransparency(character, 0.5)
            
            -- Noclip on
            setNoClip(true)
            
            -- Dash
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(100000, 100000, 100000)
            bodyVel.Velocity = hrp.CFrame.LookVector * dashSpeed
            bodyVel.Parent = hrp
            
            spawn(function()
                wait(1.5)
                bodyVel:Destroy()
                -- Invis off
                local invisChair = workspace:FindFirstChild('invischair')
                if invisChair then
                    invisChair:Destroy()
                end
                setTransparency(character, 0)
                
                -- Noclip off
                setNoClip(false)
            end)
            
            spawn(function()
                if onCooldown then return end
                onCooldown = true
                for i = cooldown, 1, -1 do
                    tool.Name = "Shadow Steps (Cooldown: " .. i .. "s)"
                    wait(1)
                end
                tool.Name = "Shadow Steps"
                onCooldown = false
            end)
        end
    end)
    
    tool.Parent = player.Backpack
end

createWarpTool = function()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "Warp Tool"
    
    tool.Activated:Connect(function()
        if not hrp then return end
        local warpGui = Instance.new("ScreenGui")
        warpGui.Name = "WarpGui"
        warpGui.Parent = player.PlayerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 150)
        frame.Position = UDim2.new(0.5, -150, 0.5, -75)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 2
        frame.BorderColor3 = Color3.fromRGB(255, 200, 0)
        frame.Parent = warpGui
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 30)
        title.BackgroundTransparency = 1
        title.Text = "Warp to Player"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16
        title.Parent = frame
        
        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(1, -20, 0, 35)
        textBox.Position = UDim2.new(0, 10, 0, 40)
        textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        textBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
        textBox.Text = ""
        textBox.PlaceholderText = "Enter username..."
        textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        textBox.Font = Enum.Font.Gotham
        textBox.TextSize = 14
        textBox.Parent = frame
        
        local confirmBtn = Instance.new("TextButton")
        confirmBtn.Size = UDim2.new(0, 130, 0, 35)
        confirmBtn.Position = UDim2.new(0, 10, 0, 90)
        confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        confirmBtn.BorderSizePixel = 0
        confirmBtn.Text = "Confirm"
        confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        confirmBtn.Font = Enum.Font.GothamBold
        confirmBtn.TextSize = 14
        confirmBtn.Parent = frame
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 130, 0, 35)
        closeBtn.Position = UDim2.new(0, 160, 0, 90)
        closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "Close"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 14
        closeBtn.Parent = frame
        
        confirmBtn.MouseButton1Click:Connect(function()
            local targetName = textBox.Text
            local targetPlayer = game.Players:FindFirstChild(targetName)
            
            if targetPlayer and targetPlayer.Character then
                local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    hrp.CFrame = targetHrp.CFrame + Vector3.new(0, 3, 0)
                    warpGui:Destroy()
                    tool:Destroy()
                end
            else
                textBox.Text = ""
                textBox.PlaceholderText = "Player not found!"
            end
        end)
        
        closeBtn.MouseButton1Click:Connect(function()
            warpGui:Destroy()
        end)
    end)
    
    tool.Parent = player.Backpack
end

createRadarTool = function()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "Radar"
    
    local esps = {}
    local used = false
    
    local function createESP(plr)
        if plr == player then return end
        local char = plr.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "ESP"
        bb.Adornee = head
        bb.Parent = char
        bb.Size = UDim2.new(0, 100, 0, 50)
        bb.StudsOffset = Vector3.new(0, 2, 0)
        bb.AlwaysOnTop = true
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.Parent = bb
        
        table.insert(esps, bb)
    end
    
    local function fadeESP()
        local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        for _, esp in ipairs(esps) do
            local label = esp:FindFirstChild("TextLabel")
            if label then
                local tween = TweenService:Create(label, tweenInfo, {TextTransparency = 1, TextStrokeTransparency = 1})
                tween:Play()
                tween.Completed:Connect(function()
                    esp:Destroy()
                end)
            end
        end
        esps = {}
    end
    
    tool.Activated:Connect(function()
        if not used then
            used = true
            for _, plr in pairs(game.Players:GetPlayers()) do
                createESP(plr)
            end
            wait(3)
            fadeESP()
            tool:Destroy()
        end
    end)
    
    tool.Parent = player.Backpack
end

createIntesignalTool = function()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "Intesignal"
    
    local cooldown = 15
    local lastUse = 0
    local onCooldown = false
    
    local function createESP(plr)
        if plr == player then return end
        local char = plr.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        
        local bb = Instance.new("BillboardGui")
        bb.Name = "IntesignalESP"
        bb.Adornee = head
        bb.Parent = char
        bb.Size = UDim2.new(0, 100, 0, 50)
        bb.StudsOffset = Vector3.new(0, 2, 0)
        bb.AlwaysOnTop = true
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.Parent = bb
        
        return bb
    end
    
    local function fadeESP(esps)
        local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        for _, esp in ipairs(esps) do
            local label = esp:FindFirstChild("TextLabel")
            if label then
                local tween = TweenService:Create(label, tweenInfo, {TextTransparency = 1, TextStrokeTransparency = 1})
                tween:Play()
                tween.Completed:Connect(function()
                    esp:Destroy()
                end)
            end
        end
    end
    
    tool.Activated:Connect(function()
        if os.time() - lastUse >= cooldown then
            lastUse = os.time()
            local esps = {}
            for _, plr in pairs(game.Players:GetPlayers()) do
                local esp = createESP(plr)
                if esp then
                    table.insert(esps, esp)
                end
            end
            wait(3)
            fadeESP(esps)
            
            spawn(function()
                if onCooldown then return end
                onCooldown = true
                for i = cooldown, 1, -1 do
                    tool.Name = "Intesignal (Cooldown: " .. i .. "s)"
                    wait(1)
                end
                tool.Name = "Intesignal"
                onCooldown = false
            end)
        end
    end)
    
    tool.Parent = player.Backpack
end

-- Create Gambling Tool
createGamblingTool = function()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "Let's Go Gambling!"
    
    local cooldown = 5
    local lastUse = 0
    local isRolling = false
    
    tool.Activated:Connect(function()
        -- Check if already rolling or on cooldown
        if isRolling then
            print("Gambling is already in progress!")
            return
        end
        
        if os.time() - lastUse < cooldown then
            local remaining = cooldown - (os.time() - lastUse)
            print("Gambling on cooldown! Wait " .. remaining .. " more seconds.")
            return
        end
        
        isRolling = true
        lastUse = os.time()
        
        -- Create slot machine GUI
        local slotGui = Instance.new("ScreenGui")
        slotGui.Name = "SlotMachineGui"
        slotGui.Parent = player.PlayerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 400, 0, 250)
        frame.Position = UDim2.new(0.5, -200, 0.5, -125)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 3
        frame.BorderColor3 = Color3.fromRGB(255, 200, 0)
        frame.Parent = slotGui
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundTransparency = 1
        title.Text = "🎰 GAMBLING TIME! 🎰"
        title.TextColor3 = Color3.fromRGB(255, 200, 0)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 20
        title.Parent = frame
        
        -- 3 slot reels
        local slots = {}
        for i = 1, 3 do
            local slot = Instance.new("TextLabel")
            slot.Size = UDim2.new(0, 100, 0, 120)
            slot.Position = UDim2.new(0, 30 + (i - 1) * 120, 0, 60)
            slot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            slot.BorderSizePixel = 2
            slot.BorderColor3 = Color3.fromRGB(100, 100, 100)
            slot.Text = "?"
            slot.TextColor3 = Color3.fromRGB(255, 255, 255)
            slot.Font = Enum.Font.GothamBold
            slot.TextSize = 60
            slot.Parent = frame
            table.insert(slots, slot)
        end
        
        local resultLabel = Instance.new("TextLabel")
        resultLabel.Size = UDim2.new(1, 0, 0, 40)
        resultLabel.Position = UDim2.new(0, 0, 0, 190)
        resultLabel.BackgroundTransparency = 1
        resultLabel.Text = "Rolling..."
        resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        resultLabel.Font = Enum.Font.GothamBold
        resultLabel.TextSize = 16
        resultLabel.Parent = frame
        
        -- Symbol pool
        local symbols = {"🍎", "🍌", "💧", "🔥", "7"}
        
        -- Determine outcome based on weighted chances
        local roll = math.random(1, 75)
        local finalSymbol
        
        if roll <= 37 then
            finalSymbol = nil -- Miss
        elseif roll <= 56 then
            finalSymbol = "🍎"
        elseif roll <= 64 then
            finalSymbol = "🍌"
        elseif roll <= 67 then
            finalSymbol = "💧"
        elseif roll <= 69 then
            finalSymbol = "🔥"
        else
            finalSymbol = "7"
        end
        
        -- Animate rolling
        spawn(function()
            for spin = 1, 20 do
                for i, slot in ipairs(slots) do
                    slot.Text = symbols[math.random(1, #symbols)]
                end
                wait(0.1)
            end
            
            -- Slow down animation
            for spin = 1, 10 do
                for i, slot in ipairs(slots) do
                    slot.Text = symbols[math.random(1, #symbols)]
                end
                wait(0.2)
            end
            
            -- Show final result
            if finalSymbol then
                for i, slot in ipairs(slots) do
                    slot.Text = finalSymbol
                end
                
                -- Grant buff based on symbol (dynamically reads from buffs table)
                if finalSymbol == "🍎" then
                    resultLabel.Text = "🍎 APPLE WIN! Random Level 1 Buff!"
                    resultLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    local level1Buffs = {}
                    for _, buff in ipairs(buffs) do
                        if buff.req == 1 and buff.name ~= "Miniature Gambling Slot" then
                            table.insert(level1Buffs, buff)
                        end
                    end
                    if #level1Buffs > 0 then
                        local randBuff = level1Buffs[math.random(1, #level1Buffs)]
                        wait(1)
                        randBuff.effect()
                        if isToolBuff[randBuff.name] then
                            table.insert(acquiredToolEffects, randBuff.effect)
                        end
                        updateBuffDebuffUI()
                    end
                elseif finalSymbol == "🍌" then
                    resultLabel.Text = "🍌 BANANA WIN! Random Level 3-5 Buff!"
                    resultLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    local midBuffs = {}
                    for _, buff in ipairs(buffs) do
                        if (buff.req >= 3 and buff.req <= 5) and buff.name ~= "Miniature Gambling Slot" then
                            table.insert(midBuffs, buff)
                        end
                    end
                    if #midBuffs > 0 then
                        local randBuff = midBuffs[math.random(1, #midBuffs)]
                        wait(1)
                        randBuff.effect()
                        if isToolBuff[randBuff.name] then
                            table.insert(acquiredToolEffects, randBuff.effect)
                        end
                        updateBuffDebuffUI()
                    end
                elseif finalSymbol == "💧" then
                    resultLabel.Text = "💧 WATER DROP WIN! Random Level 10 Buff!"
                    resultLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    local lv10Buffs = {}
                    for _, buff in ipairs(buffs) do
                        if buff.req == 10 and buff.name ~= "Miniature Gambling Slot" then
                            table.insert(lv10Buffs, buff)
                        end
                    end
                    if #lv10Buffs > 0 then
                        local randBuff = lv10Buffs[math.random(1, #lv10Buffs)]
                        wait(1)
                        randBuff.effect()
                        if isToolBuff[randBuff.name] then
                            table.insert(acquiredToolEffects, randBuff.effect)
                        end
                        updateBuffDebuffUI()
                    end
                elseif finalSymbol == "🔥" then
                    resultLabel.Text = "🔥 FLAME WIN! Random Level 25-45 Buff!"
                    resultLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                    local highBuffs = {}
                    for _, buff in ipairs(buffs) do
                        if (buff.req >= 25 and buff.req <= 45) and buff.name ~= "Miniature Gambling Slot" then
                            table.insert(highBuffs, buff)
                        end
                    end
                    if #highBuffs > 0 then
                        local randBuff = highBuffs[math.random(1, #highBuffs)]
                        wait(1)
                        randBuff.effect()
                        if isToolBuff[randBuff.name] then
                            table.insert(acquiredToolEffects, randBuff.effect)
                        end
                        updateBuffDebuffUI()
                    end
                elseif finalSymbol == "7" then
                    resultLabel.Text = "🎰 JACKPOT 777! Random Level 45 Buff!"
                    resultLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                    local jackpotBuffs = {}
                    for _, buff in ipairs(buffs) do
                        if buff.req == 45 and buff.name ~= "Miniature Gambling Slot" then
                            table.insert(jackpotBuffs, buff)
                        end
                    end
                    if #jackpotBuffs > 0 then
                        local randBuff = jackpotBuffs[math.random(1, #jackpotBuffs)]
                        wait(1)
                        randBuff.effect()
                        if isToolBuff[randBuff.name] then
                            table.insert(acquiredToolEffects, randBuff.effect)
                        end
                        updateBuffDebuffUI()
                    end
                end
            else
                -- Miss - random symbols
                slots[1].Text = symbols[math.random(1, #symbols)]
                slots[2].Text = symbols[math.random(1, #symbols)]
                slots[3].Text = symbols[math.random(1, #symbols)]
                resultLabel.Text = "❌ MISS! Random Debuff Applied!"
                resultLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                wait(1)
                applyRandomDebuff()
            end
            
            wait(2)
            slotGui:Destroy()
            isRolling = false
            
            -- Start cooldown AFTER result is shown
            spawn(function()
                for i = cooldown, 1, -1 do
                    tool.Name = "Let's Go Gambling! (Cooldown: " .. i .. "s)"
                    wait(1)
                end
                tool.Name = "Let's Go Gambling!"
            end)
        end)
    end)
    
    tool.Parent = player.Backpack
end

showBuffCards = function()
    -- Check for Sinner debuff
    local hasSinner = false
    for _, debuffName in ipairs(activeDebuffs) do
        if debuffName == "Sinner" then
            hasSinner = true
            break
        end
    end
    
    if hasSinner then
        print("Sinner debuff active - cannot gain buffs! Removing Sinner debuff...")
        -- Remove Sinner debuff
        for i, debuffName in ipairs(activeDebuffs) do
            if debuffName == "Sinner" then
                for _, debuff in ipairs(debuffs) do
                    if debuff.name == "Sinner" then
                        debuff.remove()
                        break
                    end
                end
                table.remove(activeDebuffs, i)
                break
            end
        end
        updateBuffDebuffUI()
        return -- Don't show cards
    end
    
    local cardFrame = Instance.new("Frame")
    cardFrame.Size = UDim2.new(0, 700, 0, 300)
    cardFrame.Position = UDim2.new(0.5, -350, 0.5, -150)
    cardFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    cardFrame.BorderSizePixel = 3
    cardFrame.BorderColor3 = Color3.fromRGB(255, 200, 0)
    cardFrame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🎉 LEVEL UP! Choose a Buff 🎉"
    title.TextColor3 = Color3.fromRGB(255, 200, 0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = cardFrame
    
    -- Check for Misfortune debuff
    local hasMisfortune = false
    local misfortuneIndex = nil
    for i, debuffName in ipairs(activeDebuffs) do
        if debuffName == "Misfortune" then
            hasMisfortune = true
            misfortuneIndex = i
            break
        end
    end
    
    local availableBuffs = {}
    for _, buff in ipairs(buffs) do
        local canAdd = stats.level >= buff.req
        if hasMisfortune and buff.req >= 10 and buff.req <= 50 then
            canAdd = false
        end
        if canAdd then
            table.insert(availableBuffs, buff)
        end
    end
    
    local selectedBuffs = {}
    local buffsCopy = {table.unpack(availableBuffs)}
    for i = 1, math.min(3, #buffsCopy) do
        local idx = math.random(1, #buffsCopy)
        table.insert(selectedBuffs, buffsCopy[idx])
        table.remove(buffsCopy, idx)
    end
    
    for i, buff in ipairs(selectedBuffs) do
        local card = Instance.new("TextButton")
        card.Size = UDim2.new(0, 200, 0, 220)
        card.Position = UDim2.new(0, 30 + (i - 1) * 220, 0, 60)
        card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        card.BorderSizePixel = 2
        card.BorderColor3 = Color3.fromRGB(100, 100, 100)
        card.AutoButtonColor = false
        card.Parent = cardFrame
        
        local cardName = Instance.new("TextLabel")
        cardName.Size = UDim2.new(1, 0, 0, 40)
        cardName.Position = UDim2.new(0, 0, 0, 10)
        cardName.BackgroundTransparency = 1
        cardName.Text = buff.name
        cardName.TextColor3 = Color3.fromRGB(255, 255, 255)
        cardName.Font = Enum.Font.GothamBold
        cardName.TextSize = 18
        cardName.Parent = card
        
        local cardDesc = Instance.new("TextLabel")
        cardDesc.Size = UDim2.new(1, -20, 1, -60)
        cardDesc.Position = UDim2.new(0, 10, 0, 50)
        cardDesc.BackgroundTransparency = 1
        cardDesc.Text = buff.desc
        cardDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
        cardDesc.Font = Enum.Font.Gotham
        cardDesc.TextSize = 14
        cardDesc.TextWrapped = true
        cardDesc.Parent = card
        
        card.MouseEnter:Connect(function()
            card.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            card.BorderColor3 = Color3.fromRGB(255, 200, 0)
        end)
        
        card.MouseLeave:Connect(function()
            card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            card.BorderColor3 = Color3.fromRGB(100, 100, 100)
        end)
        
        card.MouseButton1Click:Connect(function()
            buff.effect()
            if isToolBuff[buff.name] then
                table.insert(acquiredToolEffects, buff.effect)
            end
            
            -- Remove Misfortune debuff AFTER card is chosen
            if hasMisfortune and misfortuneIndex then
                for _, debuff in ipairs(debuffs) do
                    if debuff.name == "Misfortune" then
                        debuff.remove()
                        break
                    end
                end
                table.remove(activeDebuffs, misfortuneIndex)
                print("Misfortune debuff removed after buff selection!")
            end
            
            updateBuffDebuffUI()
            cardFrame:Destroy()
        end)
    end
end

addXP = function(amount)
    local totalGain = amount + stats.extraXPGain
    stats.xp = stats.xp + totalGain
    
    if stats.xp >= stats.xpRequired then
        stats.xp = stats.xp - stats.xpRequired
        stats.level = stats.level + 1
        stats.xpRequired = stats.xpRequired + 10
        
        clearOneDebuff() -- Remove only 1 random debuff
        updateXPBar()
        showBuffCards()
    else
        updateXPBar()
    end
end

local function setupCharacter(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    hrp = character:WaitForChild("HumanoidRootPart")
    
    humanoid.WalkSpeed = stats.baseSpeed + stats.speedBoosts
    if humanoid.JumpPower then
        humanoid.JumpPower = stats.baseJump + stats.jumpBoosts
    else
        humanoid.JumpHeight = stats.baseJump + stats.jumpBoosts
    end
    workspace.Gravity = stats.baseGravity - stats.gravityBoosts
    
    lastHealth = humanoid.Health
    
    -- Check for Empty Handed debuff
    local hasEmptyHanded = false
    for _, debuffName in ipairs(activeDebuffs) do
        if debuffName == "Empty Handed" then
            hasEmptyHanded = true
            break
        end
    end
    
    if not hasEmptyHanded then
        for _, effectFunc in ipairs(acquiredToolEffects) do
            effectFunc()
        end
    end
    
    -- Death detection for debuff application
    humanoid.Died:Connect(function()
        print("Player died! Waiting for respawn...")
        local newChar = player.CharacterAdded:Wait()
        wait(0.5)
        print("Applying debuff or Payment...")
        
        if hasImmunity then
            applyPaymentDebuff()
        else
            applyRandomDebuff()
        end
    end)
    
    humanoid.HealthChanged:Connect(function(health)
        if stats.hasScaredyCat and health < lastHealth and not stats.scaredyCatActive then
            stats.scaredyCatActive = true
            local previousSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = previousSpeed + 5
            print("Scaredy Cat activated! +5 Speed for 3 seconds")
            
            spawn(function()
                wait(3)
                if humanoid then
                    humanoid.WalkSpeed = previousSpeed
                end
                stats.scaredyCatActive = false
            end)
        end
        if stats.hasQuickEscape and health < 10 and os.time() - stats.quickEscapeLastTime >= 60 then
            stats.quickEscapeLastTime = os.time()
            local platforms = getAllPlatforms()
            if #platforms > 0 then
                local randPart = platforms[math.random(1, #platforms)]
                hrp.CFrame = CFrame.new(randPart.Position + Vector3.new(0, randPart.Size.Y / 2 + 5, 0))
                print("Quick Escape activated!")
            end
        end
        lastHealth = health
    end)
end

if player.Character then
    setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

game:GetService('RunService').RenderStepped:Connect(function()
    if _G.Disabled and (stats.hasJuggernaut or stats.hasGaleFighter) then
        for _, v in ipairs(game:GetService('Players'):GetPlayers()) do
            if v.Name ~= player.Name then
                pcall(function()
                    local otherChar = v.Character
                    if otherChar then
                        local otherHrp = otherChar:FindFirstChild("HumanoidRootPart")
                        if otherHrp then
                            otherHrp.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
                            otherHrp.Transparency = 0.7
                            otherHrp.BrickColor = BrickColor.new("Really blue")
                            otherHrp.Material = "Neon"
                            otherHrp.CanCollide = false
                        end
                    end
                end)
            end
        end
    end
end)

local killedPlayers = {}
spawn(function()
    while true do
        wait(0.5)
        if hrp and humanoid and humanoid.Health > 0 then
            for _, otherPlayer in pairs(game.Players:GetPlayers()) do
                if otherPlayer ~= player then
                    local otherChar = otherPlayer.Character
                    if otherChar then
                        local otherHrp = otherChar:FindFirstChild("HumanoidRootPart")
                        local otherHum = otherChar:FindFirstChild("Humanoid")
                        
                        if otherHrp and otherHum then
                            local distance = (hrp.Position - otherHrp.Position).Magnitude
                            
                            -- Kill detection (0-10 studs)
                            if distance <= 10 and otherHum.Health <= 0 then
                                if not killedPlayers[otherPlayer.UserId] then
                                    killedPlayers[otherPlayer.UserId] = true
                                    addXP(5)
                                    
                                    if stats.hasEmpathy then
                                        stats.speedBoosts = stats.speedBoosts + 3
                                        humanoid.WalkSpeed = humanoid.WalkSpeed + 3
                                        humanoid.Health = math.max(humanoid.Health - 15, 1)
                                        print("Empathy triggered! +3 Speed, -15 HP")
                                    end
                                    
                                    if stats.hasGaleFighter then
                                        stats.speedBoosts = stats.speedBoosts + 5
                                        humanoid.WalkSpeed = humanoid.WalkSpeed + 5
                                        stats.jumpBoosts = stats.jumpBoosts + 5
                                        if humanoid.JumpPower then
                                            humanoid.JumpPower = humanoid.JumpPower + 5
                                        else
                                            humanoid.JumpHeight = humanoid.JumpHeight + 5
                                        end
                                        stats.hitboxSize = stats.hitboxSize + 5
                                        _G.HeadSize = math.min(50, 10 + stats.hitboxSize)
                                        print("Gale Fighter triggered! +5 Speed, +5 Jump, +5 Hitbox")
                                    end
                                    
                                    spawn(function()
                                        wait(3)
                                        killedPlayers[otherPlayer.UserId] = nil
                                    end)
                                end
                            end
                            
                            -- Mimicry debuff detection (11-25 studs)
                            if distance > 10 and distance <= 25 and otherHum.Health <= 0 then
                                -- Check if player has Mimicry debuff
                                local hasMimicry = false
                                for _, debuffName in ipairs(activeDebuffs) do
                                    if debuffName == "Mimicry" then
                                        hasMimicry = true
                                        break
                                    end
                                end
                                
                                if hasMimicry then
                                    print("Mimicry triggered! You died because someone died nearby!")
                                    humanoid.Health = 0
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

updateXPBar()
updateBuffDebuffUI()

getAllPlatforms = function()
    local platforms = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "Void" and obj.CanCollide then
            local model = obj:FindFirstAncestorWhichIsA("Model")
            if model and model:FindFirstChild("Humanoid") then continue end
            table.insert(platforms, obj)
        end
    end
    return platforms
end

findSafePlatform = function(pos)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {character}
    
    local ray = workspace:Raycast(pos + Vector3.new(0, 100, 0), Vector3.new(0, -200, 0), rayParams)
    if ray and ray.Instance and ray.Instance.Name ~= "Void" then
        return ray
    end
    return nil
end

print("Rogue Cheat loaded! Kill players within 10 studs for XP!")
