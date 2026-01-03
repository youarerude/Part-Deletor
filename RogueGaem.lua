-- Rogue Cheat for Fun - Client-Sided Script with Full Tarot System
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
    foolReversedTimeStacks = 0
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
                        print("Wheel of Fortune: Granting random Level 1-10 buff")
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
        name = "The Fool",
        reversed = false,
        description = "The Fool depicts a youth walking joyfully into the world. He is taking his first steps, and he is exuberant, joyful, excited. He carries nothing with him except a small sack, caring nothing for the possible dangers that lie in his path. The dog at his heels barks at him in warning.",
        functionDesc = "• Under 35 HP: Random teleport (1m cooldown)\n• When damaged: +20 Speed for 10s (stacks, time doesn't)",
        apply = function()
            _G.TarotState.activeEffects.foolQuickEscape = true
            _G.TarotState.foolSpeedStacks = 0
        end,
        remove = function()
            _G.TarotState.activeEffects.foolQuickEscape = false
            -- Remove all fool speed stacks
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal and _G.TarotState.foolSpeedStacks > 0 then
                humLocal.WalkSpeed = humLocal.WalkSpeed - (_G.TarotState.foolSpeedStacks * 20)
                _G.TarotState.foolSpeedStacks = 0
            end
        end
    },
    {
        name = "The Hanged Man",
        reversed = false,
        description = "A man who is suspended upside-down, and he is hanging by his foot from the living world tree. This tree is rooted deep down in the underworld, and it is known to support the heavens. His wearing of red pants are a representation of the physical body and human's passion.",
        functionDesc = "• On death: Draw upright card instead of reversed\n• On respawn: +30 Speed, +30 Jump, +20 Hitbox for 2 minutes",
        apply = function()
            _G.TarotState.activeEffects.hangedManActive = true
        end,
        remove = function()
            _G.TarotState.activeEffects.hangedManActive = false
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
            if _G.TarotState.activeEffects.loversReversedCheck then
                _G.TarotState.activeEffects.loversReversedCheck:Disconnect()
                _G.TarotState.activeEffects.loversReversedCheck = nil
            end
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                local count = 0
                for _ in pairs(_G.TarotState.loversNearbyPlayers) do
                    count = count + 1
                end
                humLocal.WalkSpeed = humLocal.WalkSpeed + (count * 10)
                if humLocal.JumpPower then
                    humLocal.JumpPower = humLocal.JumpPower + (count * 10)
                else
                    humLocal.JumpHeight = humLocal.JumpHeight + (count * 10)
                end
            end
            _G.TarotState.loversNearbyPlayers = {}
        end
    },
    {
        name = "The Devil [REVERSED]",
        reversed = true,
        description = "The chains appear loose or removable, symbolizing awareness and the potential to reclaim personal autonomy.",
        functionDesc = "✨ BLESSING CARD (Appears after 10th reversed card)\n• Removes 3 random debuffs\n• Converts them to 3 random buffs\n• Removed debuffs NEVER return",
        isSpecial = true,
        triggerCount = 10,
        reversed = true,
        apply = function()
            print("✨ THE DEVIL [REVERSED] HAS APPEARED! 3 DEBUFFS WILL BE BLESSED!")
            for i = 1, 3 do
                if #activeDebuffs > 0 then
                    local randIdx = math.random(1, #activeDebuffs)
                    table.remove(activeDebuffs, randIdx)
                end
            end
            updateBuffDebuffUI()
        end,
        remove = function() end
    },
    {
        name = "The Magician [REVERSED]",
        reversed = true,
        description = "The tools of creation appear misused or ignored. Skills are present but misapplied.",
        functionDesc = "• Cooldowns increased by 100%\n• Tool uses halved\n• -25% XP gain",
        apply = function()
            _G.TarotState.activeEffects.magicianReversedDebuff = true
            stats.extraXPGain = stats.extraXPGain - 5
            print("The Magician [REVERSED]: Your power is weakened!")
        end,
        remove = function()
            _G.TarotState.activeEffects.magicianReversedDebuff = false
            stats.extraXPGain = stats.extraXPGain + 5
        end
    },
    {
        name = "The Star [REVERSED]",
        reversed = true,
        description = "The eight stars above fade or become obscured by clouds, representing lost hope and disillusionment.",
        functionDesc = "• Next buff becomes a debuff\n• -15 Speed & -10 Jump Power",
        apply = function()
            _G.TarotState.activeEffects.starReversedCurse = true
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                humLocal.WalkSpeed = math.max(1, humLocal.WalkSpeed - 15)
                if humLocal.JumpPower then
                    humLocal.JumpPower = math.max(1, humLocal.JumpPower - 10)
                else
                    humLocal.JumpHeight = math.max(1, humLocal.JumpHeight - 10)
                end
            end
            print("The Star [REVERSED]: Hope fades away...")
        end,
        remove = function()
            _G.TarotState.activeEffects.starReversedCurse = false
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                humLocal.WalkSpeed = humLocal.WalkSpeed + 15
                if humLocal.JumpPower then
                    humLocal.JumpPower = humLocal.JumpPower + 10
                else
                    humLocal.JumpHeight = humLocal.JumpHeight + 10
                end
            end
        end
    },
    {
        name = "The Emperor [REVERSED]",
        reversed = true,
        description = "The Emperor's throne appears unstable, suggesting tyranny or collapsed leadership.",
        functionDesc = "• -20 Speed & -15 Jump Power\n• Constant knockback vulnerability",
        apply = function()
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                humLocal.WalkSpeed = math.max(1, humLocal.WalkSpeed - 20)
                if humLocal.JumpPower then
                    humLocal.JumpPower = math.max(1, humLocal.JumpPower - 15)
                else
                    humLocal.JumpHeight = math.max(1, humLocal.JumpHeight - 15)
                end
            end
            _G.TarotState.activeEffects.emperorReversedWeakness = true
            print("The Emperor [REVERSED]: Your authority crumbles!")
        end,
        remove = function()
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                humLocal.WalkSpeed = humLocal.WalkSpeed + 20
                if humLocal.JumpPower then
                    humLocal.JumpPower = humLocal.JumpPower + 15
                else
                    humLocal.JumpHeight = humLocal.JumpHeight + 15
                end
            end
            _G.TarotState.activeEffects.emperorReversedWeakness = false
        end
    },
    {
        name = "Judgment [REVERSED]",
        reversed = true,
        description = "The angel's trumpet sounds faintly or not at all. Judgment reversed embodies harsh self-criticism.",
        functionDesc = "• Gain 2 random debuffs immediately\n• -30 Speed for 20 seconds\n• Cannot remove debuffs for 15 seconds",
        apply = function()
            _G.TarotState.activeEffects.judgmentReversedCurse = true
            for i = 1, 2 do
                applyRandomDebuff()
            end
            print("Judgment [REVERSED]: 2 random debuffs applied!")
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal then
                humLocal.WalkSpeed = math.max(1, humLocal.WalkSpeed - 30)
                spawn(function()
                    wait(20)
                    if humLocal then
                        humLocal.WalkSpeed = humLocal.WalkSpeed + 30
                    end
                end)
            end
            _G.TarotState.activeEffects.judgmentBlockRemoval = true
            spawn(function()
                wait(15)
                _G.TarotState.activeEffects.judgmentBlockRemoval = false
            end)
        end,
        remove = function()
            _G.TarotState.activeEffects.judgmentReversedCurse = false
        end
    },
    {
        name = "The Fool [REVERSED]",
        reversed = true,
        description = "The youth's joyful momentum is disrupted, suggesting hesitation, recklessness, or a lack of direction. The cliff before him becomes a clearer warning in reversal, emphasizing poor judgment and avoidance of responsibility.",
        functionDesc = "• Under 50 HP: Instant death\n• When damaged: -15 Speed for 15s (stacks speed AND time)",
        apply = function()
            _G.TarotState.activeEffects.foolReversedActive = true
            _G.TarotState.foolReversedSpeedStacks = 0
            _G.TarotState.foolReversedTimeStacks = 0
        end,
        remove = function()
            _G.TarotState.activeEffects.foolReversedActive = false
            -- Remove all fool reversed speed debuffs
            local humLocal = player.Character and player.Character:FindFirstChild("Humanoid")
            if humLocal and _G.TarotState.foolReversedSpeedStacks > 0 then
                humLocal.WalkSpeed = humLocal.WalkSpeed + (_G.TarotState.foolReversedSpeedStacks * 15)
                _G.TarotState.foolReversedSpeedStacks = 0
                _G.TarotState.foolReversedTimeStacks = 0
            end
        end
    },
    {
        name = "The Hanged Man [REVERSED]",
        reversed = true,
        description = "The man's suspension no longer reflects willing sacrifice or enlightened pause, but resistance, stagnation, and discomfort. Though he still hangs from the living world tree, his position now suggests being trapped by circumstance rather than choosing stillness for insight.",
        functionDesc = "• On death: Reversed card + 5 debuffs\n• On respawn: -15 Speed, -15 Jump for 2 min & lose all tool buffs",
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
        -- Check for Hanged Man (draw upright instead of reversed on death)
        if _G.TarotState.activeEffects.hangedManActive then
            _G.TarotState.cardCount = (_G.TarotState.cardCount or 0) + 1
            print("The Hanged Man: Drawing upright card instead of reversed!")
            -- Draw upright card
            for _, card in ipairs(tarotCards) do
                if not card.reversed and not card.isSpecial then
                    table.insert(availableCards, card)
                end
            end
            if #availableCards > 0 then
                return availableCards[math.random(1, #availableCards)]
            end
            return nil
        end
        
        _G.TarotState.cardCount = (_G.TarotState.cardCount or 0) + 1
        if _G.TarotState.cardCount % 10 == 0 then
            for _, card in ipairs(tarotCards) do
                if card.name == "The Devil [REVERSED]" then
                    return card
                end
            end
        end
        for _, card in ipairs(tarotCards) do
            if card.reversed and not card.isSpecial then
                table.insert(availableCards, card)
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
    
    -- Check for Hanged Man [REVERSED] - apply 5 additional debuffs
    if _G.TarotState.activeEffects.hangedManReversedActive then
        print("The Hanged Man [REVERSED]: Applying 5 additional debuffs!")
        for i = 1, 5 do
            applyRandomDebuff()
        end
    end
    
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
                    humanoid.JumpHeight = humanoid.JumpHeight - 10
                end
            end
        end,
        remove = function()
            print("Payment debuff cannot be removed!")
        end,
        isPayment = true
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

-- Active Buffs/Debuffs Buttons
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

-- Buff/Debuff Dropdowns
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

-- Button connections
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

-- Skip Button & Cheat Menu
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

-- Show Buff Cards (Level Up)
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

-- Add XP Function
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

-- Character Setup with Tarot Integration
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
    
    -- Respawn tool buffs
    local hasEmptyHanded = false
    for _, debuffName in ipairs(activeDebuffs) do
        if debuffName == "Empty Handed" then
            hasEmptyHanded = true
            break
        end
    end
    
    if not hasEmptyHanded then
        -- Check for Hanged Man [REVERSED] - lose all tool buffs
        if _G.TarotState.activeEffects.hangedManReversedActive then
            print("The Hanged Man [REVERSED]: All tool buffs removed!")
            for _, tool in ipairs(player.Backpack:GetChildren()) do
                if tool:IsA("Tool") and isToolBuff[tool.Name] then
                    tool:Destroy()
                end
            end
        else
            for _, effectFunc in ipairs(acquiredToolEffects) do
                effectFunc()
            end
        end
    end
    
    -- Apply Hanged Man respawn buff
    if _G.TarotState.activeEffects.hangedManActive and _G.TarotState.activeEffects.hangedManJustDied then
        _G.TarotState.activeEffects.hangedManJustDied = false
        print("The Hanged Man: Applying respawn buff (+30 Speed, +30 Jump, +20 Hitbox for 2 min)")
        humanoid.WalkSpeed = humanoid.WalkSpeed + 30
        if humanoid.JumpPower then
            humanoid.JumpPower = humanoid.JumpPower + 30
        else
            humanoid.JumpHeight = humanoid.JumpHeight + 30
        end
        stats.hitboxSize = stats.hitboxSize + 20
        _G.HeadSize = 10 + stats.hitboxSize
        _G.Disabled = true
        
        spawn(function()
            wait(120) -- 2 minutes
            if humanoid then
                humanoid.WalkSpeed = humanoid.WalkSpeed - 30
                if humanoid.JumpPower then
                    humanoid.JumpPower = humanoid.JumpPower - 30
                else
                    humanoid.JumpHeight = humanoid.JumpHeight - 30
                end
                stats.hitboxSize = stats.hitboxSize - 20
                _G.HeadSize = 10 + stats.hitboxSize
            end
            print("The Hanged Man: Respawn buff expired")
        end)
    end
    
    -- Apply Hanged Man [REVERSED] respawn debuff
    if _G.TarotState.activeEffects.hangedManReversedJustDied then
        _G.TarotState.activeEffects.hangedManReversedJustDied = false
        print("The Hanged Man [REVERSED]: Applying respawn debuff (-15 Speed, -15 Jump for 2 min)")
        humanoid.WalkSpeed = math.max(1, humanoid.WalkSpeed - 15)
        if humanoid.JumpPower then
            humanoid.JumpPower = math.max(1, humanoid.JumpPower - 15)
        else
            humanoid.JumpHeight = math.max(1, humanoid.JumpHeight - 15)
        end
        
        spawn(function()
            wait(120)
            if humanoid then
                humanoid.WalkSpeed = humanoid.WalkSpeed + 15
                if humanoid.JumpPower then
                    humanoid.JumpPower = humanoid.JumpPower + 15
                else
                    humanoid.JumpHeight = humanoid.JumpHeight + 15
                end
            end
            print("The Hanged Man [REVERSED]: Respawn debuff expired")
        end)
    end
    
    -- Death detection
    humanoid.Died:Connect(function()
        print("Player died! Waiting for respawn...")
        
        -- Mark Hanged Man effects for next respawn
        if _G.TarotState.activeEffects.hangedManActive then
            _G.TarotState.activeEffects.hangedManJustDied = true
        end
        if _G.TarotState.activeEffects.hangedManReversedActive then
            _G.TarotState.activeEffects.hangedManReversedJustDied = true
        end
        
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
    
    -- Health changed detection for Fool & Fool [REVERSED] cards
    humanoid.HealthChanged:Connect(function(health)
        -- The Fool: Quick Escape under 35 HP
        if _G.TarotState.activeEffects.foolQuickEscape and health < 35 and health > 0 then
            if os.time() - stats.quickEscapeLastTime >= 60 then
                stats.quickEscapeLastTime = os.time()
                local platforms = getAllPlatforms()
                if #platforms > 0 then
                    local randPart = platforms[math.random(1, #platforms)]
                    hrp.CFrame = CFrame.new(randPart.Position + Vector3.new(0, randPart.Size.Y / 2 + 5, 0))
                    print("The Fool: Quick Escape activated!")
                end
            end
        end
        
        -- The Fool: +20 Speed when damaged (stacks, time doesn't)
        if _G.TarotState.activeEffects.foolQuickEscape and health < lastHealth and health > 0 then
            _G.TarotState.foolSpeedStacks = _G.TarotState.foolSpeedStacks + 1
            humanoid.WalkSpeed = humanoid.WalkSpeed + 20
            print("The Fool: +20 Speed stack (" .. _G.TarotState.foolSpeedStacks .. " stacks)")
            
            spawn(function()
                wait(10)
                if humanoid and _G.TarotState.foolSpeedStacks > 0 then
                    humanoid.WalkSpeed = humanoid.WalkSpeed - 20
                    _G.TarotState.foolSpeedStacks = _G.TarotState.foolSpeedStacks - 1
                    print("The Fool: Speed stack expired (" .. _G.TarotState.foolSpeedStacks .. " remaining)")
                end
            end)
        end
        
        -- The Fool [REVERSED]: Instant death under 50 HP
        if _G.TarotState.activeEffects.foolReversedActive and health < 50 and health > 0 then
            print("The Fool [REVERSED]: Instant death under 50 HP!")
            humanoid.Health = 0
        end
        
        -- The Fool [REVERSED]: -15 Speed when damaged (stacks speed AND time)
        if _G.TarotState.activeEffects.foolReversedActive and health < lastHealth and health > 0 then
            _G.TarotState.foolReversedSpeedStacks = _G.TarotState.foolReversedSpeedStacks + 1
            humanoid.WalkSpeed = math.max(1, humanoid.WalkSpeed - 15)
            print("The Fool [REVERSED]: -15 Speed stack (" .. _G.TarotState.foolReversedSpeedStacks .. " stacks)")
            
            _G.TarotState.foolReversedTimeStacks = _G.TarotState.foolReversedTimeStacks + 1
            spawn(function()
                wait(15)
                if humanoid and _G.TarotState.foolReversedSpeedStacks > 0 then
                    humanoid.WalkSpeed = humanoid.WalkSpeed + 15
                    _G.TarotState.foolReversedSpeedStacks = _G.TarotState.foolReversedSpeedStacks - 1
                    _G.TarotState.foolReversedTimeStacks = _G.TarotState.foolReversedTimeStacks - 1
                    print("The Fool [REVERSED]: Speed debuff expired (" .. _G.TarotState.foolReversedSpeedStacks .. " remaining)")
                end
            end)
        end
        
        -- Scaredy Cat
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
        
        -- Quick Escape
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

-- Juggernaut/Gale Fighter Hitbox System
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

-- Kill/Death Detection System
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
                            
                            -- Mimicry debuff detection (11-25 studs)
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

print("✨ Rogue Cheat with Full Tarot System loaded!")
print("Kill players within 10 studs for XP!")
print("Reach Level 70 to unlock The Tenth Stars of Dignity!")
print("🎴 The Fool and The Hanged Man cards are now available!")
