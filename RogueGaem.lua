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
    hasGaleFighter = false,
    hasOblivionAccel = false,
    hasSchizophrenia = false
}

-- Buff and Debuff Tracking
local activeBuffs = {}
local activeDebuffs = {}
local slothfulConnection = nil
local slothfulDecreaseAmount = 0
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
local applyRandomBuff
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

-- ==================== TAROT CARD SYSTEM ====================
_G.TarotState = _G.TarotState or {
    hasTenthStars = false,
    currentCard = nil,
    cardCount = 0,
    activeEffects = {},
    permanentSpeedBoost = 0,
    permanentJumpBoost = 0,
    loversNearbyPlayers = {},
    foolSpeedStacks = 0,
    foolReversedSpeedStacks = 0,
    foolReversedTimeStacks = 0,
    respawnBoost = false,
    respawnCurse = false
}

-- Forward declarations for tarot functions
local showTarotCard
local drawTarotCard
local replaceTarotCard
local onTarotKill
local onTarotDeath
local initializeTenthStars

-- Tarot Cards Database
local tarotCards = {
    {
        name = "Wheel of Fortune",
        reversed = false,
        description = "The books that each of the creatures hold represents the Torah which communicates wisdom and self-understanding. The snake indicates the act of descending into material world. On the wheel itself, rides a sphinx that sits at the top, and what appears to be either a devil, or Anubis himself arising at the bottom.",
        functionDesc = "• Level 10-45 buffs appear in level-up cards\n• Every 5 minutes: Random Level 1-10 buff",
        apply = function()
            _G.TarotState.activeEffects.wheelOfFortune = true
            spawn(function()
                while _G.TarotState.currentCard == "Wheel of Fortune" do
                    wait(300)
                    if _G.TarotState.currentCard == "Wheel of Fortune" then
                        applyRandomBuff(1, 10)
                    end
                end
            end)
        end,
        remove = function()
            _G.TarotState.activeEffects.wheelOfFortune = false
        end
    },
    {
        name = "Strength",
        reversed = false,
        description = "A woman who calmly holds the jaws of a fully grown lion. Despite the fact that the lion looks menacing and strong, the woman seems to have dominion over it. The lion is a symbol of courage, passion and desire.",
        functionDesc = "• Every 1 second: +1 Speed & +1 Jump Power\n• Boosts are PERMANENT (kept after card replacement)",
        apply = function()
            _G.TarotState.activeEffects.strengthTimer = game:GetService("RunService").Heartbeat:Connect(function()
                wait(1)
                if _G.TarotState.currentCard == "Strength" then
                    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                    if hum then
                        _G.TarotState.permanentSpeedBoost = _G.TarotState.permanentSpeedBoost + 1
                        _G.TarotState.permanentJumpBoost = _G.TarotState.permanentJumpBoost + 1
                        hum.WalkSpeed = hum.WalkSpeed + 1
                        if hum.JumpPower then
                            hum.JumpPower = hum.JumpPower + 1
                        else
                            hum.JumpHeight = hum.JumpHeight + 1
                        end
                        print("Strength: +1 Speed, +1 Jump (Total: +" .. _G.TarotState.permanentSpeedBoost .. " Speed, +" .. _G.TarotState.permanentJumpBoost .. " Jump)")
                    end
                end
            end)
        end,
        remove = function()
            if _G.TarotState.activeEffects.strengthTimer then
                _G.TarotState.activeEffects.strengthTimer:Disconnect()
                _G.TarotState.activeEffects.strengthTimer = nil
            end
        end
    },
    {
        name = "The Lovers",
        reversed = false,
        description = "The man and the woman are being protected and blessed by an angel above. The couple seems secure and happy in their home, which appears to be the Garden of Eden.",
        functionDesc = "• Players within 50 studs: +10 Speed & +10 Jump per player\n• Stacks with multiple players\n• Lost when players leave range",
        apply = function()
            _G.TarotState.loversNearbyPlayers = {}
            _G.TarotState.activeEffects.loversCheck = game:GetService("RunService").Heartbeat:Connect(function()
                wait(0.5)
                if _G.TarotState.currentCard ~= "The Lovers" then return end
                local char = player.Character
                if not char then return end
                local hrpLocal = char:FindFirstChild("HumanoidRootPart")
                local humLocal = char:FindFirstChild("Humanoid")
                if not hrpLocal or not humLocal then return end
                local currentNearby = {}
                for _, otherPlayer in pairs(game.Players:GetPlayers()) do
                    if otherPlayer ~= player and otherPlayer.Character then
                        local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if otherHrp then
                            local distance = (hrpLocal.Position - otherHrp.Position).Magnitude
                            if distance <= 50 then
                                currentNearby[otherPlayer.UserId] = true
                                if not _G.TarotState.loversNearbyPlayers[otherPlayer.UserId] then
                                    _G.TarotState.loversNearbyPlayers[otherPlayer.UserId] = true
                                    humLocal.WalkSpeed = humLocal.WalkSpeed + 10
                                    if humLocal.JumpPower then
                                        humLocal.JumpPower = humLocal.JumpPower + 10
                                    else
                                        humLocal.JumpHeight = humLocal.JumpHeight + 10
                                    end
                                    print("The Lovers: " .. otherPlayer.Name .. " entered range (+10 Speed, +10 Jump)")
                                end
                            end
                        end
                    end
                end
                for userId, _ in pairs(_G.TarotState.loversNearbyPlayers) do
                    if not currentNearby[userId] then
                        _G.TarotState.loversNearbyPlayers[userId] = nil
                        humLocal.WalkSpeed = humLocal.WalkSpeed - 10
                        if humLocal.JumpPower then
                            humLocal.JumpPower = humLocal.JumpPower - 10
                        else
                            humLocal.JumpHeight = humLocal.JumpHeight - 10
                        end
                        print("The Lovers: Player left range (-10 Speed, -10 Jump)")
                    end
                end
            end)
        end,
        remove = function()
            if _G.TarotState.activeEffects.loversCheck then
                _G.TarotState.activeEffects.loversCheck:Disconnect()
                _G.TarotState.activeEffects.loversCheck = nil
            end
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                local count = 0
                for _ in pairs(_G.TarotState.loversNearbyPlayers) do
                    count = count + 1
                end
                humLocal.WalkSpeed = humLocal.WalkSpeed - (count * 10)
                if humLocal.JumpPower then
                    humLocal.JumpPower = humLocal.JumpPower - (count * 10)
                else
                    humLocal.JumpHeight = humLocal.JumpHeight - (count * 10)
                end
            end
            _G.TarotState.loversNearbyPlayers = {}
        end
    },
    {
        name = "The Devil",
        reversed = false,
        description = "The Devil represented in his most well-known satyr form, otherwise known as Baphomet. Both the man and the woman have horns.",
        functionDesc = "⚠️ CURSE CARD (Appears after 10th card)\n• Removes 3 random buffs\n• Converts them to 3 random debuffs\n• Removed buffs NEVER return",
        isSpecial = true,
        triggerCount = 10,
        apply = function()
            print("⚠️ THE DEVIL HAS APPEARED! 3 BUFFS WILL BE CURSED!")
            for i = 1, 3 do
                if #activeBuffs > 0 then
                    local randIdx = math.random(1, #activeBuffs)
                    table.remove(activeBuffs, randIdx)
                end
            end
            for i = 1, 3 do
                applyRandomDebuff()
            end
            updateBuffDebuffUI()
        end,
        remove = function() end
    },
    {
        name = "The Magician",
        reversed = false,
        description = "The Magician stands before a table bearing the four suits of the Tarot. Above his head floats the infinity symbol.",
        functionDesc = "• Cooldowns reduced by 50%\n• Tool uses doubled\n• +25% XP gain",
        apply = function()
            _G.TarotState.activeEffects.magicianBoost = true
            stats.extraXPGain = stats.extraXPGain + 5
            print("The Magician: Enhanced efficiency activated!")
        end,
        remove = function()
            _G.TarotState.activeEffects.magicianBoost = false
            stats.extraXPGain = stats.extraXPGain - 5
        end
    },
    {
        name = "The Star",
        reversed = false,
        description = "A naked woman kneels by a pool of water, pouring liquid from two jugs. Above her shine eight stars.",
        functionDesc = "• Immunity to next debuff\n• +15 Speed & +10 Jump Power",
        apply = function()
            _G.TarotState.activeEffects.starImmunity = true
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                humLocal.WalkSpeed = humLocal.WalkSpeed + 15
                if humLocal.JumpPower then
                    humLocal.JumpPower = humLocal.JumpPower + 10
                else
                    humLocal.JumpHeight = humLocal.JumpHeight + 10
                end
            end
            print("The Star: Hope shines upon you!")
        end,
        remove = function()
            _G.TarotState.activeEffects.starImmunity = false
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                humLocal.WalkSpeed = humLocal.WalkSpeed - 15
                if humLocal.JumpPower then
                    humLocal.JumpPower = humLocal.JumpPower - 10
                else
                    humLocal.JumpHeight = humLocal.JumpHeight - 10
                end
            end
        end
    },
    {
        name = "The Emperor",
        reversed = false,
        description = "The Emperor sits upon a stone throne adorned with ram heads, symbolizing Aries and assertive leadership.",
        functionDesc = "• +20 Speed & +15 Jump Power\n• Knockback immunity",
        apply = function()
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                humLocal.WalkSpeed = humLocal.WalkSpeed + 20
                if humLocal.JumpPower then
                    humLocal.JumpPower = humLocal.JumpPower + 15
                else
                    humLocal.JumpHeight = humLocal.JumpHeight + 15
                end
            end
            _G.TarotState.activeEffects.emperorDefense = true
            print("The Emperor: Royal authority empowers you!")
        end,
        remove = function()
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                humLocal.WalkSpeed = humLocal.WalkSpeed - 20
                if humLocal.JumpPower then
                    humLocal.JumpPower = humLocal.JumpPower - 15
                else
                    humLocal.JumpHeight = humLocal.JumpHeight - 15
                end
            end
            _G.TarotState.activeEffects.emperorDefense = false
        end
    },
    {
        name = "Judgment",
        reversed = false,
        description = "An angel emerges from the clouds blowing a trumpet, calling forth the dead from their graves.",
        functionDesc = "• Removes all current debuffs\n• +30 Speed boost for 15 seconds\n• Immunity to debuffs for 10 seconds",
        apply = function()
            _G.TarotState.activeEffects.judgmentActive = true
            clearDebuffs()
            print("Judgment: All debuffs removed!")
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                humLocal.WalkSpeed = humLocal.WalkSpeed + 30
                spawn(function()
                    wait(15)
                    if humLocal then
                        humLocal.WalkSpeed = humLocal.WalkSpeed - 30
                    end
                end)
            end
            _G.TarotState.activeEffects.judgmentImmunity = true
            spawn(function()
                wait(10)
                _G.TarotState.activeEffects.judgmentImmunity = false
            end)
        end,
        remove = function()
            _G.TarotState.activeEffects.judgmentActive = false
        end
    },
    {
        name = "Wheel of Fortune [REVERSED]",
        reversed = true,
        description = "The books held by the creatures no longer signify accessible wisdom, but obscured knowledge and misinterpretation.",
        functionDesc = "• ONLY Level 1-5 buffs appear in level-up cards\n• Every 5 minutes: Random debuff",
        apply = function()
            _G.TarotState.activeEffects.wheelReversed = true
            spawn(function()
                while _G.TarotState.currentCard == "Wheel of Fortune [REVERSED]" do
                    wait(300)
                    if _G.TarotState.currentCard == "Wheel of Fortune [REVERSED]" then
                        print("Wheel of Fortune [REVERSED]: Applying random debuff")
                        applyRandomDebuff()
                    end
                end
            end)
        end,
        remove = function()
            _G.TarotState.activeEffects.wheelReversed = false
        end
    },
    {
        name = "Strength [REVERSED]",
        reversed = true,
        description = "The woman's calm authority over the lion is diminished, suggesting inner turmoil and self-doubt.",
        functionDesc = "• Every 1 second: -1 Speed & -1 Jump Power\n• Losses are PERMANENT (kept after card replacement)",
        apply = function()
            _G.TarotState.activeEffects.strengthReversedTimer = game:GetService("RunService").Heartbeat:Connect(function()
                wait(1)
                if _G.TarotState.currentCard == "Strength [REVERSED]" then
                    local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
                    if humLocal then
                        _G.TarotState.permanentSpeedBoost = _G.TarotState.permanentSpeedBoost - 1
                        _G.TarotState.permanentJumpBoost = _G.TarotState.permanentJumpBoost - 1
                        humLocal.WalkSpeed = math.max(1, humLocal.WalkSpeed - 1)
                        if humLocal.JumpPower then
                            humLocal.JumpPower = math.max(1, humLocal.JumpPower - 1)
                        else
                            humLocal.JumpHeight = math.max(1, humLocal.JumpHeight - 1)
                        end
                        print("Strength [REVERSED]: -1 Speed, -1 Jump")
                    end
                end
            end)
        end,
        remove = function()
            if _G.TarotState.activeEffects.strengthReversedTimer then
                _G.TarotState.activeEffects.strengthReversedTimer:Disconnect()
                _G.TarotState.activeEffects.strengthReversedTimer = nil
            end
        end
    },
    {
        name = "The Lovers [REVERSED]",
        reversed = true,
        description = "The blessing of the angel appears weakened, suggesting misalignment and disharmony.",
        functionDesc = "• Players within 50 studs: -10 Speed & -10 Jump per player\n• Stacks with multiple players\n• Restored when players leave range",
        apply = function()
            _G.TarotState.loversNearbyPlayers = {}
            _G.TarotState.activeEffects.loversReversedCheck = game:GetService("RunService").Heartbeat:Connect(function()
                wait(0.5)
                if _G.TarotState.currentCard ~= "The Lovers [REVERSED]" then return end
                local char = player.Character
                if not char then return end
                local hrpLocal = char:FindFirstChild("HumanoidRootPart")
                local humLocal = char:FindFirstChild("Humanoid")
                if not hrpLocal or not humLocal then return end
                local currentNearby = {}
                for _, otherPlayer in pairs(game.Players:GetPlayers()) do
                    if otherPlayer ~= player and otherPlayer.Character then
                        local otherHrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if otherHrp then
                            local distance = (hrpLocal.Position - otherHrp.Position).Magnitude
                            if distance <= 50 then
                                currentNearby[otherPlayer.UserId] = true
                                if not _G.TarotState.loversNearbyPlayers[otherPlayer.UserId] then
                                    _G.TarotState.loversNearbyPlayers[otherPlayer.UserId] = true
                                    humLocal.WalkSpeed = math.max(1, humLocal.WalkSpeed - 10)
                                    if humLocal.JumpPower then
                                        humLocal.JumpPower = math.max(1, humLocal.JumpPower - 10)
                                    else
                                        humLocal.JumpHeight = math.max(1, humLocal.JumpHeight - 10)
                                    end
                                    print("The Lovers [REVERSED]: " .. otherPlayer.Name .. " entered range (-10 Speed, -10 Jump)")
                                end
                            end
                        end
                    end
                end
                for userId, _ in pairs(_G.TarotState.loversNearbyPlayers) do
                    if not currentNearby[userId] then
                        _G.TarotState.loversNearbyPlayers[userId] = nil
                        humLocal.WalkSpeed = humLocal.WalkSpeed + 10
                        if humLocal.JumpPower then
                            humLocal.JumpPower = humLocal.JumpPower + 10
                        else
                            humLocal.JumpHeight = humLocal.JumpHeight + 10
                        end
                        print("The Lovers [REVERSED]: Player left range (+10 Speed, +10 Jump restored)")
                    end
                end
            end)
        end,
        remove = function()
            if _G.TarotState.activeEffects.loversReversedCheck then _G.TarotState.activeEffects.loversReversedCheck:Disconnect() end
            _G.TarotState.loversNearbyPlayers = {}
        end
    },
    {
        name = "The Devil [REVERSED]",
        reversed = true,
        description = "Chains break loose.",
        functionDesc = "✨ 10th Card Blessing\n• Remove 3 debuffs → 3 buffs",
        isSpecial = true,
        reversed = true,
        apply = function()
            for i = 1, 3 do if #activeDebuffs > 0 then table.remove(activeDebuffs, math.random(1, #activeDebuffs)) end end
            updateBuffDebuffUI()
        end,
        remove = function() end
    },
    {
        name = "The Magician [REVERSED]",
        reversed = true,
        description = "Tools misused.",
        functionDesc = "• +100% cooldowns\n• Half tool uses\n• -25% XP",
        apply = function()
            _G.TarotState.activeEffects.magicianReversedDebuff = true
            stats.extraXPGain = stats.extraXPGain - 5
        end,
        remove = function()
            _G.TarotState.activeEffects.magicianReversedDebuff = false
            stats.extraXPGain = stats.extraXPGain + 5
        end
    },
    {
        name = "The Star [REVERSED]",
        reversed = true,
        description = "Stars fade away.",
        functionDesc = "• Next buff → debuff\n• -15 Speed, -10 Jump",
        apply = function()
            _G.TarotState.activeEffects.starReversedCurse = true
            local humL = player.Character and player.Character:FindFirstChild("Humanoid")
            if humL then
                humL.WalkSpeed = math.max(1, humL.WalkSpeed - 15)
                if humL.JumpPower then humL.JumpPower = math.max(1, humL.JumpPower - 10) else humL.JumpHeight = math.max(1, humL.JumpHeight - 10) end
            end
        end,
        remove = function()
            _G.TarotState.activeEffects.starReversedCurse = false
            local humL = player.Character and player.Character:FindFirstChild("Humanoid")
            if humL then
                humL.WalkSpeed = humL.WalkSpeed + 15
                if humL.JumpPower then humL.JumpPower = humL.JumpPower + 10 else humL.JumpHeight = humL.JumpHeight + 10 end
            end
        end
    },
    {
        name = "The Emperor [REVERSED]",
        reversed = true,
        description = "Throne crumbles.",
        functionDesc = "• -20 Speed, -15 Jump\n• Knockback vulnerable",
        apply = function()
            local humL = player.Character and player.Character:FindFirstChild("Humanoid")
            if humL then
                humL.WalkSpeed = math.max(1, humL.WalkSpeed - 20)
                if humL.JumpPower then humL.JumpPower = math.max(1, humL.JumpPower - 15) else humL.JumpHeight = math.max(1, humL.JumpHeight - 15) end
            end
        end,
        remove = function()
            local humL = player.Character and player.Character:FindFirstChild("Humanoid")
            if humL then
                humL.WalkSpeed = humL.WalkSpeed + 20
                if humL.JumpPower then humL.JumpPower = humL.JumpPower + 15 else humL.JumpHeight = humL.JumpHeight + 15 end
            end
        end
    },
    {
        name = "Judgment [REVERSED]",
        reversed = true,
        description = "Trumpet sounds faintly.",
        functionDesc = "• +2 debuffs now\n• -30 Speed 20s\n• Can't remove debuffs 15s",
        apply = function()
            for i = 1, 2 do applyRandomDebuff() end
            local humL = player.Character and player.Character:FindFirstChild("Humanoid")
            if humL then
                humL.WalkSpeed = math.max(1, humL.WalkSpeed - 30)
                spawn(function() wait(20) if humL then humL.WalkSpeed = humL.WalkSpeed + 30 end end)
            end
            _G.TarotState.activeEffects.judgmentBlockRemoval = true
            spawn(function() wait(15) _G.TarotState.activeEffects.judgmentBlockRemoval = false end)
        end,
        remove = function() end
    },
    {
        name = "The Fool [REVERSED]",
        reversed = true,
        description = "Youth stumbles recklessly.",
        functionDesc = "• <50HP: Instant death\n• Damaged: -15 Speed 15s (stacks)",
        apply = function()
            _G.TarotState.activeEffects.foolReversedActive = true
            _G.TarotState.foolReversedSpeedStacks = 0
        end,
        remove = function()
            _G.TarotState.activeEffects.foolReversedActive = false
            local humL = player.Character and player.Character:FindFirstChild("Humanoid")
            if humL and _G.TarotState.foolReversedSpeedStacks > 0 then
                humL.WalkSpeed = humL.WalkSpeed + (_G.TarotState.foolReversedSpeedStacks * 15)
                _G.TarotState.foolReversedSpeedStacks = 0
            end
        end
    },
    {
        name = "The Hanged Man [REVERSED]",
        reversed = true,
        description = "Trapped without choice.",
        functionDesc = "• Death: Reversed + 5 debuffs\n• Respawn: -15 Speed/Jump 2min, lose tools",
        apply = function()
            _G.TarotState.activeEffects.hangedManReversedActive = true
        end,
        remove = function()
            _G.TarotState.activeEffects.hangedManReversedActive = false
        end
    }
}

-- Show Tarot Card GUI
showTarotCard = function(card)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TarotCardGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 600, 0, 500)
    frame.Position = UDim2.new(0.5, -300, 0.5, -250)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 3
    frame.BorderColor3 = card.reversed and Color3.fromRGB(150, 0, 200) or Color3.fromRGB(255, 200, 0)
    frame.BackgroundTransparency = 0.1
    frame.Parent = screenGui
    
    local cardName = Instance.new("TextLabel")
    cardName.Size = UDim2.new(1, 0, 0, 60)
    cardName.Position = UDim2.new(0, 0, 0, 10)
    cardName.BackgroundTransparency = 1
    cardName.Text = card.name
    cardName.TextColor3 = card.reversed and Color3.fromRGB(200, 50, 255) or Color3.fromRGB(255, 215, 0)
    cardName.Font = Enum.Font.GothamBold
    cardName.TextSize = 28
    cardName.TextStrokeTransparency = 0.5
    cardName.Parent = frame
    
    local descScrollFrame = Instance.new("ScrollingFrame")
    descScrollFrame.Size = UDim2.new(1, -40, 0, 200)
    descScrollFrame.Position = UDim2.new(0, 20, 0, 80)
    descScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    descScrollFrame.BorderSizePixel = 1
    descScrollFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
    descScrollFrame.ScrollBarThickness = 6
    descScrollFrame.Parent = frame
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -20, 0, 0)
    descLabel.Position = UDim2.new(0, 10, 0, 10)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = card.description
    descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 14
    descLabel.TextWrapped = true
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.Parent = descScrollFrame
    
    descLabel.Size = UDim2.new(1, -20, 0, descLabel.TextBounds.Y + 20)
    descScrollFrame.CanvasSize = UDim2.new(0, 0, 0, descLabel.TextBounds.Y + 30)
    
    local funcLabel = Instance.new("TextLabel")
    funcLabel.Size = UDim2.new(1, -40, 0, 150)
    funcLabel.Position = UDim2.new(0, 20, 0, 295)
    funcLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    funcLabel.BorderSizePixel = 1
    funcLabel.BorderColor3 = card.reversed and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 200, 0)
    funcLabel.Text = "EFFECTS:\n" .. card.functionDesc
    funcLabel.TextColor3 = card.reversed and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
    funcLabel.Font = Enum.Font.GothamBold
    funcLabel.TextSize = 14
    funcLabel.TextWrapped = true
    funcLabel.TextXAlignment = Enum.TextXAlignment.Left
    funcLabel.TextYAlignment = Enum.TextYAlignment.Top
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = funcLabel
    funcLabel.Parent = frame
    
    wait(5)
    local fadeInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local fadeTween = TweenService:Create(frame, fadeInfo, {BackgroundTransparency = 1})
    
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") then
            TweenService:Create(child, fadeInfo, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
        elseif child:IsA("Frame") or child:IsA("ScrollingFrame") then
            TweenService:Create(child, fadeInfo, {BackgroundTransparency = 1}):Play()
        end
    end
    
    fadeTween:Play()
    fadeTween.Completed:Connect(function()
        screenGui:Destroy()
    end)
end

-- Draw a random tarot card
drawTarotCard = function(isDeath)
    local availableCards = {}
    
    if isDeath then
        _G.TarotState.cardCount = (_G.TarotState.cardCount or 0) + 1
        if _G.TarotState.cardCount % 10 == 0 then
            for _, card in ipairs(tarotCards) do
                if card.name == "The Devil [REVERSED]" then
                    return card
                end
            end
        end
        if _G.TarotState.activeEffects.hangedManActive then
            for _, card in ipairs(tarotCards) do
                if not card.reversed and not card.isSpecial then
                    table.insert(availableCards, card)
                end
            end
        else
            for _, card in ipairs(tarotCards) do
                if card.reversed and not card.isSpecial then
                    table.insert(availableCards, card)
                end
            end
        end
    else
        _G.TarotState.cardCount = (_G.TarotState.cardCount or 0) + 1
        if _G.TarotState.cardCount % 10 == 0 then
            for _, card in ipairs(tarotCards) do
                if card.name == "The Devil" then
                    return card
                end
            end
        end
        for _, card in ipairs(tarotCards) do
            if not card.reversed and not card.isSpecial then
                table.insert(availableCards, card)
            end
        end
    end
    
    if #availableCards > 0 then
        return availableCards[math.random(1, #availableCards)]
    end
    return nil
end

-- Replace current tarot card
replaceTarotCard = function(newCard)
    if _G.TarotState.currentCard then
        for _, card in ipairs(tarotCards) do
            if card.name == _G.TarotState.currentCard then
                card.remove()
                break
            end
        end
    end
    
    _G.TarotState.currentCard = newCard.name
    newCard.apply()
    showTarotCard(newCard)
    print("Tarot Card drawn: " .. newCard.name)
end

-- Hook into kill detection
onTarotKill = function()
    if not _G.TarotState.hasTenthStars then return end
    local card = drawTarotCard(false)
    if card then
        replaceTarotCard(card)
    end
end

-- Hook into death detection
onTarotDeath = function()
    if not _G.TarotState.hasTenthStars then return end
    local card = drawTarotCard(true)
    if card then
        replaceTarotCard(card)
    end
end

-- Initialize The Tenth Stars of Dignity buff
initializeTenthStars = function()
    if _G.TarotState.hasTenthStars then
        print("The Tenth Stars of Dignity can only be applied ONCE!")
        return
    end
    _G.TarotState.hasTenthStars = true
    print("✨ THE TENTH STARS OF DIGNITY ACTIVATED!")
    print("Kill players to draw upright tarot cards (buffs)")
    print("Die to draw reversed tarot cards (debuffs)")
    print("Every 10th card will be a special card!")
end

-- ==================== END TAROT SYSTEM ====================

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
        remove = function() end
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
        remove = function() end
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
        apply = function() end,
        remove = function() end
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
        apply = function() end,
        remove = function() end
    },
    {
        name = "Genesis",
        desc = "2 debuffs on death instead of 1",
        apply = function() end,
        remove = function() end
    },
    {
        name = "Mimicry",
        desc = "Die if someone dies within 11-25 studs",
        apply = function() end,
        remove = function() end
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
                    humanoid.JumpHeight = humL.JumpHeight - 10
                end
            end
        end,
        remove = function()
            print("Payment debuff cannot be removed!")
        end,
        isPayment = true
    },
    {
        name = "Schizophrenia",
        desc = "All Player are invisible if they entered the 20 studs area closer to me.",
        apply = function()
            stats.hasSchizophrenia = true
        end,
        remove = function()
            stats.hasSchizophrenia = false
            for _, op in pairs(game.Players:GetPlayers()) do
                if op ~= player and op.Character then
                    setTransparency(op.Character, 0)
                end
            end
        end
    }
}

-- Apply Random Debuff on Death
applyRandomDebuff = function()
    -- Check for Star immunity
    if _G.TarotState.activeEffects.starImmunity then
        print("The Star immunity blocked a debuff!")
        _G.TarotState.activeEffects.starImmunity = false
        return
    end
    
    -- Check for Judgment immunity
    if _G.TarotState.activeEffects.judgmentImmunity then
        print("Judgment immunity blocked a debuff!")
        return
    end
    
    if hasImmunity then
        print("Immunity active! No debuff applied, but Payment cost will be added on respawn.")
        return
    end
    
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

-- Apply Random Buff
applyRandomBuff = function(minReq, maxReq)
    minReq = minReq or 1
    maxReq = maxReq or 100
    local availBuffs = {}
    for _, buff in ipairs(buffs) do
        if buff.req >= minReq and buff.req <= maxReq then
            table.insert(availBuffs, buff)
        end
    end
    if #availBuffs > 0 then
        local randBuff = availBuffs[math.random(1, #availBuffs)]
        randBuff.effect()
        if isToolBuff[randBuff.name] then
            table.insert(acquiredToolEffects, randBuff.effect)
        end
        print("Random buff applied: " .. randBuff.name)
        updateBuffDebuffUI()
    end
end

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

local function clearOneDebuff()
    -- Check if Judgment [REVERSED] is blocking removal
    if _G.TarotState.activeEffects.judgmentBlockRemoval then
        print("Judgment [REVERSED] prevents debuff removal!")
        return
    end
    
    if #activeDebuffs > 0 then
        local removableDebuffs = {}
        for i, debuffName in ipairs(activeDebuffs) do
            if debuffName ~= "Payment" then
                table.insert(removableDebuffs, {index = i, name = debuffName})
            end
        end
        
        if #removableDebuffs > 0 then
            local selected = removableDebuffs[math.random(1, #removableDebuffs)]
            local debuffName = selected.name
            
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

local function setTransparency(character, transparency)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.Transparency = transparency
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
    {
        name = "Shadow Steps", 
        desc = "Dash forward (20+ speed) with invisibility & noclip for 1.5s", 
        effect = function() 
            createShadowStepsTool()
            table.insert(activeBuffs, "Shadow Steps")
        end, 
        req = 45
    },
    {
        name = "Oblivion Accel",
        desc = "Decrease all buff tool's cooldown by 50% and 30+ speed and 30+ jump power",
        effect = function()
            stats.hasOblivionAccel = true
            stats.speedBoosts = stats.speedBoosts + 30
            stats.jumpBoosts = stats.jumpBoosts + 30
            if humanoid then
                humanoid.WalkSpeed = humanoid.WalkSpeed + 30
                if humanoid.JumpPower then
                    humanoid.JumpPower = humanoid.JumpPower + 30
                else
                    humanoid.JumpHeight = humanoid.JumpHeight + 30
                end
            end
            table.insert(activeBuffs, "Oblivion Accel")
        end,
        req = 45
    },
    {
        name = "The Tenth Stars of Dignity", 
        desc = "Draw tarot cards on kills (buffs) or deaths (debuffs). Only obtainable ONCE!", 
        effect = function() 
            initializeTenthStars()
            table.insert(activeBuffs, "The Tenth Stars of Dignity")
        end, 
        req = 70
    }
}

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RogueCheatGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

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

updateBuffDebuffUI = function()
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

updateXPBar = function()
    local progress = stats.xp / stats.xpRequired
    xpBar:TweenSize(UDim2.new(progress, 0, 1, 0), "Out", "Quad", 0.3, true)
    levelLabel.Text = "Level " .. stats.level
    xpLabel.Text = stats.xp .. " / " .. stats.xpRequired .. " XP"
end

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
        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then return end
        
        if os.time() - lastUse >= cooldown then
            lastUse = os.time()
            local originalSpeed = humanoid.WalkSpeed
            local dashSpeed = 20 + originalSpeed
            local dashDuration = 1.5
            
            setTransparency(character, 1)
            
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(100000, 0, 100000)
            bodyVel.Velocity = hrp.CFrame.LookVector * dashSpeed
            bodyVel.Parent = hrp
            
            wait(dashDuration)
            
            if bodyVel and bodyVel.Parent then
                bodyVel:Destroy()
            end
            
            setTransparency(character, 0)
            
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
            
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

createGamblingTool = function()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "Let's Go Gambling!"
    
    local cooldown = 5
    local lastUse = 0
    local isRolling = false
    
    tool.Activated:Connect(function()
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
        
        local symbols = {"🍎", "🍌", "💧", "🔥", "7"}
        
        local roll = math.random(1, 75)
        local finalSymbol
        
        if roll <= 37 then
            finalSymbol = nil
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
        
        spawn(function()
            for spin = 1, 20 do
                for i, slot in ipairs(slots) do
                    slot.Text = symbols[math.random(1, #symbols)]
                end
                wait(0.1)
            end
            
            for spin = 1, 10 do
                for i, slot in ipairs(slots) do
                    slot.Text = symbols[math.random(1, #symbols)]
                end
                wait(0.2)
            end
            
            if finalSymbol then
                for i, slot in ipairs(slots) do
                    slot.Text = finalSymbol
                end
                
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
    local hasSinner = false
    for _, debuffName in ipairs(activeDebuffs) do
        if debuffName == "Sinner" then
            hasSinner = true
            break
        end
    end
    
    if hasSinner then
        print("Sinner debuff active - cannot gain buffs! Removing Sinner debuff...")
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
        return
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
    
    local hasMisfortune = false
    local misfortuneIndex = nil
    for i, debuffName in ipairs(activeDebuffs) do
        if debuffName == "Misfortune" then
            hasMisfortune = true
            misfortuneIndex = i
            break
        end
    end
    
    -- Check for Wheel of Fortune / Wheel of Fortune [REVERSED]
    local wheelOfFortuneActive = _G.TarotState.activeEffects.wheelOfFortune
    local wheelReversedActive = _G.TarotState.activeEffects.wheelReversed
    
    local availableBuffs = {}
    for _, buff in ipairs(buffs) do
        local canAdd = stats.level >= buff.req
        if hasMisfortune and buff.req >= 10 and buff.req <= 50 then
            canAdd = false
        end
        if wheelOfFortuneActive and (buff.req < 10 or buff.req > 45) then
            canAdd = false
        end
        if wheelReversedActive and buff.req > 5 then
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
            -- Check for Star [REVERSED] curse
            if _G.TarotState.activeEffects.starReversedCurse then
                print("Star [REVERSED] curse activated! Buff becomes a debuff!")
                _G.TarotState.activeEffects.starReversedCurse = false
                applyRandomDebuff()
            else
                buff.effect()
                if isToolBuff[buff.name] then
                    table.insert(acquiredToolEffects, buff.effect)
                end
            end
            
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
        
        clearOneDebuff()
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
    
    humanoid.WalkSpeed = stats.baseSpeed + stats.speedBoosts + _G.TarotState.permanentSpeedBoost
    if humanoid.JumpPower then
        humanoid.JumpPower = stats.baseJump + stats.jumpBoosts + _G.TarotState.permanentJumpBoost
    else
        humanoid.JumpHeight = stats.baseJump + stats.jumpBoosts + _G.TarotState.permanentJumpBoost
    end
    workspace.Gravity = stats.baseGravity - stats.gravityBoosts
    
    lastHealth = humanoid.Health
    
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
    
    -- Apply active debuffs on respawn
    for _, debuffName in ipairs(activeDebuffs) do
        for _, debuff in ipairs(debuffs) do
            if debuff.name == debuffName then
                debuff.apply()
                break
            end
        end
    end
    
    humanoid.Died:Connect(function()
        print("Player died! Waiting for respawn...")
        
        -- Trigger tarot death card
        if _G.TarotState.hasTenthStars then
            onTarotDeath()
        end
        
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
        if _G.TarotState.activeEffects.foolQuickEscape and health < 35 and os.time() - stats.quickEscapeLastTime >= 60 then
            stats.quickEscapeLastTime = os.time()
            local platforms = getAllPlatforms()
            if #platforms > 0 then
                local randPart = platforms[math.random(1, #platforms)]
                hrp.CFrame = CFrame.new(randPart.Position + Vector3.new(0, randPart.Size.Y / 2 + 5, 0))
                print("The Fool Quick Escape activated!")
            end
        end
        if _G.TarotState.activeEffects.foolReversedActive and health < 50 then
            humanoid.Health = 0
            print("The Fool [REVERSED]: Instant death under 50 HP!")
        end
        if health < lastHealth then
            if _G.TarotState.currentCard == "The Fool" then
                local hum = humanoid
                hum.WalkSpeed = hum.WalkSpeed + 20
                _G.TarotState.foolSpeedStacks = _G.TarotState.foolSpeedStacks + 1
                spawn(function()
                    wait(10)
                    if hum then
                        hum.WalkSpeed = hum.WalkSpeed - 20
                        _G.TarotState.foolSpeedStacks = _G.TarotState.foolSpeedStacks - 1
                    end
                end)
            end
            if _G.TarotState.currentCard == "The Fool [REVERSED]" then
                local hum = humanoid
                hum.WalkSpeed = math.max(1, hum.WalkSpeed - 15)
                _G.TarotState.foolReversedSpeedStacks = _G.TarotState.foolReversedSpeedStacks + 1
                spawn(function()
                    wait(15)
                    if hum then
                        hum.WalkSpeed = hum.WalkSpeed + 15
                        _G.TarotState.foolReversedSpeedStacks = _G.TarotState.foolReversedSpeedStacks - 1
                    end
                end)
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
                            
                            if distance <= 10 and otherHum.Health <= 0 then
                                if not killedPlayers[otherPlayer.UserId] then
                                    killedPlayers[otherPlayer.UserId] = true
                                    addXP(5)
                                    
                                    -- Trigger tarot kill card
                                    if _G.TarotState.hasTenthStars then
                                        onTarotKill()
                                    end
                                    
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
                            
                            if distance > 10 and distance <= 25 and otherHum.Health <= 0 then
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
        remove = function() end
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
        remove = function() end
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
        apply = function() end,
        remove = function() end
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
        apply = function() end,
        remove = function() end
    },
    {
        name = "Genesis",
        desc = "2 debuffs on death instead of 1",
        apply = function() end,
        remove = function() end
    },
    {
        name = "Mimicry",
        desc = "Die if someone dies within 11-25 studs",
        apply = function() end,
        remove = function() end
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
            print("Payment debuff cannot be removed!")
        end,
        isPayment = true
    },
    {
        name = "Schizophrenia",
        desc = "All Player are invisible if they entered the 20 studs area closer to me.",
        apply = function()
            stats.hasSchizophrenia = true
        end,
        remove = function()
            stats.hasSchizophrenia = false
            for _, op in pairs(game.Players:GetPlayers()) do
                if op ~= player and op.Character then
                    setTransparency(op.Character, 0)
                end
            end
        end
    },
    {
        name = "Hallucination",
        desc = "White humanoids follow you, hide players when looked at",
        apply = function()
            _G.HallucinationState = {
                active = true,
                illusions = {},
                lookingAtIllusion = false
            }
            
            -- Spawn illusions every 30 seconds
            spawn(function()
                while _G.HallucinationState and _G.HallucinationState.active do
                    wait(30)
                    if _G.HallucinationState and _G.HallucinationState.active and #_G.HallucinationState.illusions < 10 then
                        local char = player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            local hrpPos = char.HumanoidRootPart.Position
                            local camera = workspace.CurrentCamera
                            
                            -- Spawn behind player (where camera isn't looking)
                            local spawnPos = hrpPos - (camera.CFrame.LookVector * 15) + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
                            
                            -- Create white humanoid illusion
                            local illusion = Instance.new("Model")
                            illusion.Name = "Illusion"
                            
                            local humanoidPart = Instance.new("Part")
                            humanoidPart.Size = Vector3.new(2, 2, 1)
                            humanoidPart.Position = spawnPos
                            humanoidPart.Anchored = false
                            humanoidPart.CanCollide = true
                            humanoidPart.BrickColor = BrickColor.new("Institutional white")
                            humanoidPart.Material = Enum.Material.Neon
                            humanoidPart.Name = "HumanoidRootPart"
                            humanoidPart.Parent = illusion
                            
                            local head = Instance.new("Part")
                            head.Size = Vector3.new(2, 1, 1)
                            head.Position = spawnPos + Vector3.new(0, 1.5, 0)
                            head.Anchored = false
                            head.CanCollide = false
                            head.BrickColor = BrickColor.new("Institutional white")
                            head.Material = Enum.Material.Neon
                            head.Name = "Head"
                            head.Parent = illusion
                            
                            local weld = Instance.new("WeldConstraint")
                            weld.Part0 = humanoidPart
                            weld.Part1 = head
                            weld.Parent = humanoidPart
                            
                            local illusionHum = Instance.new("Humanoid")
                            illusionHum.MaxHealth = 50
                            illusionHum.Health = 50
                            illusionHum.WalkSpeed = 12
                            illusionHum.Parent = illusion
                            
                            -- Make illusion follow player
                            local bodyPos = Instance.new("BodyPosition")
                            bodyPos.MaxForce = Vector3.new(4000, 4000, 4000)
                            bodyPos.P = 3000
                            bodyPos.Parent = humanoidPart
                            
                            spawn(function()
                                while illusion.Parent and char and char:FindFirstChild("HumanoidRootPart") do
                                    bodyPos.Position = char.HumanoidRootPart.Position + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
                                    wait(0.5)
                                end
                            end)
                            
                            -- Death detection
                            illusionHum.Died:Connect(function()
                                print("Illusion killed! -10 XP")
                                stats.xp = math.max(0, stats.xp - 10)
                                updateXPBar()
                                for i, illu in ipairs(_G.HallucinationState.illusions) do
                                    if illu == illusion then
                                        table.remove(_G.HallucinationState.illusions, i)
                                        break
                                    end
                                end
                                wait(2)
                                illusion:Destroy()
                            end)
                            
                            illusion.Parent = workspace
                            table.insert(_G.HallucinationState.illusions, illusion)
                            print("Illusion spawned (" .. #_G.HallucinationState.illusions .. "/10)")
                        end
                    end
                end
            end)
            
            -- Check if looking at illusions
            spawn(function()
                while _G.HallucinationState and _G.HallucinationState.active do
                    wait(0.1)
                    local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local camera = workspace.CurrentCamera
                        local lookingAt = false
                        
                        for _, illusion in ipairs(_G.HallucinationState.illusions) do
                            if illusion.Parent then
                                local illusionHrp = illusion:FindFirstChild("HumanoidRootPart")
                                if illusionHrp then
                                    local screenPos, onScreen = camera:WorldToScreenPoint(illusionHrp.Position)
                                    if onScreen then
                                        local distance = (camera.CFrame.Position - illusionHrp.Position).Magnitude
                                        if distance < 50 then
                                            lookingAt = true
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Make players invisible/visible
                        if lookingAt ~= _G.HallucinationState.lookingAtIllusion then
                            _G.HallucinationState.lookingAtIllusion = lookingAt
                            for _, otherPlayer in pairs(game.Players:GetPlayers()) do
                                if otherPlayer ~= player and otherPlayer.Character then
                                    for _, part in pairs(otherPlayer.Character:GetDescendants()) do
                                        if part:IsA("BasePart") or part:IsA("Decal") then
                                            part.Transparency = lookingAt and 1 or 0
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end,
        remove = function()
            if _G.HallucinationState then
                _G.HallucinationState.active = false
                -- Destroy all illusions
                for _, illusion in ipairs(_G.HallucinationState.illusions) do
                    if illusion and illusion.Parent then
                        illusion:Destroy()
                    end
                end
                -- Restore player visibility
                for _, otherPlayer in pairs(game.Players:GetPlayers()) do
                    if otherPlayer ~= player and otherPlayer.Character then
                        for _, part in pairs(otherPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") or part:IsA("Decal") then
                                part.Transparency = 0
                            end
                        end
                    end
                end
                _G.HallucinationState = nil
            end
            print("Hallucination removed")
        end
    }
}

-- Apply Random Debuff on Death
applyRandomDebuff = function()
    -- Check for Star immunity
    if _G.TarotState.activeEffects.starImmunity then
        print("The Star immunity blocked a debuff!")
        _G.TarotState.activeEffects.starImmunity = false
        return
    end
    
    -- Check for Judgment immunity
    if _G.TarotState.activeEffects.judgmentImmunity then
        print("Judgment immunity blocked a debuff!")
        return
    end
    
    if hasImmunity then
        print("Immunity active! No debuff applied, but Payment cost will be added on respawn.")
        return
    end
    
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

local function clearOneDebuff()
    -- Check if Judgment [REVERSED] is blocking removal
    if _G.TarotState.activeEffects.judgmentBlockRemoval then
        print("Judgment [REVERSED] prevents debuff removal!")
        return
    end
    
    if #activeDebuffs > 0 then
        local removableDebuffs = {}
        for i, debuffName in ipairs(activeDebuffs) do
            if debuffName ~= "Payment" then
                table.insert(removableDebuffs, {index = i, name = debuffName})
            end
        end
        
        if #removableDebuffs > 0 then
            local selected = removableDebuffs[math.random(1, #removableDebuffs)]
            local debuffName = selected.name
            
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

local function setTransparency(character, transparency)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.Transparency = transparency
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
    {
        name = "Shadow Steps", 
        desc = "Dash forward (20+ speed) with invisibility & noclip for 1.5s", 
        effect = function() 
            createShadowStepsTool()
            table.insert(activeBuffs, "Shadow Steps")
        end, 
        req = 45
    },
    {
        name = "The Tenth Stars of Dignity", 
        desc = "Draw tarot cards on kills (buffs) or deaths (debuffs). Only obtainable ONCE!", 
        effect = function() 
            initializeTenthStars()
            table.insert(activeBuffs, "The Tenth Stars of Dignity")
        end, 
        req = 70
    }
}

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RogueCheatGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

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

updateBuffDebuffUI = function()
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

updateXPBar = function()
    local progress = stats.xp / stats.xpRequired
    xpBar:TweenSize(UDim2.new(progress, 0, 1, 0), "Out", "Quad", 0.3, true)
    levelLabel.Text = "Level " .. stats.level
    xpLabel.Text = stats.xp .. " / " .. stats.xpRequired .. " XP"
end

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
        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then return end
        
        if os.time() - lastUse >= cooldown then
            lastUse = os.time()
            local originalSpeed = humanoid.WalkSpeed
            local dashSpeed = 20 + originalSpeed
            local dashDuration = 1.5
            
            setTransparency(character, 1)
            
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(100000, 0, 100000)
            bodyVel.Velocity = hrp.CFrame.LookVector * dashSpeed
            bodyVel.Parent = hrp
            
            wait(dashDuration)
            
            if bodyVel and bodyVel.Parent then
                bodyVel:Destroy()
            end
            
            setTransparency(character, 0)
            
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
            
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

createGamblingTool = function()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "Let's Go Gambling!"
    
    local cooldown = 5
    local lastUse = 0
    local isRolling = false
    
    tool.Activated:Connect(function()
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
        
        local symbols = {"🍎", "🍌", "💧", "🔥", "7"}
        
        local roll = math.random(1, 75)
        local finalSymbol
        
        if roll <= 37 then
            finalSymbol = nil
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
        
        spawn(function()
            for spin = 1, 20 do
                for i, slot in ipairs(slots) do
                    slot.Text = symbols[math.random(1, #symbols)]
                end
                wait(0.1)
            end
            
            for spin = 1, 10 do
                for i, slot in ipairs(slots) do
                    slot.Text = symbols[math.random(1, #symbols)]
                end
                wait(0.2)
            end
            
            if finalSymbol then
                for i, slot in ipairs(slots) do
                    slot.Text = finalSymbol
                end
                
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
    local hasSinner = false
    for _, debuffName in ipairs(activeDebuffs) do
        if debuffName == "Sinner" then
            hasSinner = true
            break
        end
    end
    
    if hasSinner then
        print("Sinner debuff active - cannot gain buffs! Removing Sinner debuff...")
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
        return
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
    
    local hasMisfortune = false
    local misfortuneIndex = nil
    for i, debuffName in ipairs(activeDebuffs) do
        if debuffName == "Misfortune" then
            hasMisfortune = true
            misfortuneIndex = i
            break
        end
    end
    
    -- Check for Wheel of Fortune / Wheel of Fortune [REVERSED]
    local wheelOfFortuneActive = _G.TarotState.activeEffects.wheelOfFortune
    local wheelReversedActive = _G.TarotState.activeEffects.wheelReversed
    
    local availableBuffs = {}
    for _, buff in ipairs(buffs) do
        local canAdd = stats.level >= buff.req
        if hasMisfortune and buff.req >= 10 and buff.req <= 50 then
            canAdd = false
        end
        if wheelOfFortuneActive and (buff.req < 10 or buff.req > 45) then
            canAdd = false
        end
        if wheelReversedActive and buff.req > 5 then
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
            -- Check for Star [REVERSED] curse
            if _G.TarotState.activeEffects.starReversedCurse then
                print("Star [REVERSED] curse activated! Buff becomes a debuff!")
                _G.TarotState.activeEffects.starReversedCurse = false
                applyRandomDebuff()
            else
                buff.effect()
                if isToolBuff[buff.name] then
                    table.insert(acquiredToolEffects, buff.effect)
                end
            end
            
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
        
        clearOneDebuff()
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
    
    humanoid.WalkSpeed = stats.baseSpeed + stats.speedBoosts + _G.TarotState.permanentSpeedBoost
    if humanoid.JumpPower then
        humanoid.JumpPower = stats.baseJump + stats.jumpBoosts + _G.TarotState.permanentJumpBoost
    else
        humanoid.JumpHeight = stats.baseJump + stats.jumpBoosts + _G.TarotState.permanentJumpBoost
    end
    workspace.Gravity = stats.baseGravity - stats.gravityBoosts
    
    lastHealth = humanoid.Health
    
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
    
    -- Apply active debuffs on respawn
    for _, debuffName in ipairs(activeDebuffs) do
        for _, debuff in ipairs(debuffs) do
            if debuff.name == debuffName then
                debuff.apply()
                break
            end
        end
    end
    
    humanoid.Died:Connect(function()
        print("Player died! Waiting for respawn...")
        
        -- Trigger tarot death card
        if _G.TarotState.hasTenthStars then
            onTarotDeath()
        end
        
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
        if _G.TarotState.activeEffects.foolQuickEscape and health < 35 and os.time() - stats.quickEscapeLastTime >= 60 then
            stats.quickEscapeLastTime = os.time()
            local platforms = getAllPlatforms()
            if #platforms > 0 then
                local randPart = platforms[math.random(1, #platforms)]
                hrp.CFrame = CFrame.new(randPart.Position + Vector3.new(0, randPart.Size.Y / 2 + 5, 0))
                print("The Fool Quick Escape activated!")
            end
        end
        if _G.TarotState.activeEffects.foolReversedActive and health < 50 then
            humanoid.Health = 0
            print("The Fool [REVERSED]: Instant death under 50 HP!")
        end
        if health < lastHealth then
            if _G.TarotState.currentCard == "The Fool" then
                local hum = humanoid
                hum.WalkSpeed = hum.WalkSpeed + 20
                _G.TarotState.foolSpeedStacks = _G.TarotState.foolSpeedStacks + 1
                spawn(function()
                    wait(10)
                    if hum then
                        hum.WalkSpeed = hum.WalkSpeed - 20
                        _G.TarotState.foolSpeedStacks = _G.TarotState.foolSpeedStacks - 1
                    end
                end)
            end
            if _G.TarotState.currentCard == "The Fool [REVERSED]" then
                local hum = humanoid
                hum.WalkSpeed = math.max(1, hum.WalkSpeed - 15)
                _G.TarotState.foolReversedSpeedStacks = _G.TarotState.foolReversedSpeedStacks + 1
                spawn(function()
                    wait(15)
                    if hum then
                        hum.WalkSpeed = hum.WalkSpeed + 15
                        _G.TarotState.foolReversedSpeedStacks = _G.TarotState.foolReversedSpeedStacks - 1
                    end
                end)
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
                            
                            if distance <= 10 and otherHum.Health <= 0 then
                                if not killedPlayers[otherPlayer.UserId] then
                                    killedPlayers[otherPlayer.UserId] = true
                                    addXP(5)
                                    
                                    -- Trigger tarot kill card
                                    if _G.TarotState.hasTenthStars then
                                        onTarotKill()
                                    end
                                    
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
                            
                            if distance > 10 and distance <= 25 and otherHum.Health <= 0 then
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
                            
                            -- Schizophrenia logic
                            if stats.hasSchizophrenia then
                                if distance <= 20 then
                                    setTransparency(otherChar, 1)
                                else
                                    setTransparency(otherChar, 0)
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

print("Rogue Cheat with Tarot System loaded!")
print("Kill players within 10 studs for XP!")
print("Reach Level 70 to unlock The Tenth Stars of Dignity!")
