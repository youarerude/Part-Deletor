--[[
    ██████╗ ██████╗  █████╗  ██████╗███████╗
   ██╔════╝ ██╔══██╗██╔══██╗██╔════╝██╔════╝
   ██║  ███╗██████╔╝███████║██║     █████╗
   ██║   ██║██╔══██╗██╔══██║██║     ██╔══╝
   ╚██████╔╝██║  ██║██║  ██║╚██████╗███████╗
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝
    F A N M A D E  —  by Wowiera
    Script by Claude (Anthropic) / Modified by Gemini

    [span_0](start_span)▸ FATE system      — yellow → white as health drains[span_0](end_span)
    ▸ Entity Panel   
    [span_1](start_span)— top-right 👁 button[span_1](end_span)
    [span_2](start_span)▸ GAZE             — Envy[span_2](end_span)
    [span_3](start_span)▸ ELUDE  v3        — Paranoia  (open ground spawn, outside camera)[span_3](end_span)
    [span_4](start_span)▸ NUMB             — Wrath     (blood rain, find cover or die)[span_4](end_span)
    ▸ MOUTHFEED        — Recklessness
    ▸ PIECE            — Injustice Robbing
    ▸ DELICTUM         — Past Mistakes
    ▸ NORM             — Self Pleasure
    ▸ BLUE SKY         — Treason (Nuclear Annihilation)

    Executor: Codex (mobile)  |
    [span_5](start_span)Game Script Category[span_5](end_span)
--]]

-- ═══════════════════════════════════════════════════════════
--                  SERVICES & CORE REFS
-- ═══════════════════════════════════════════════════════════
[span_6](start_span)local Players          = game:GetService("Players") --[span_6](end_span)
[span_7](start_span)local RunService       = game:GetService("RunService") --[span_7](end_span)
[span_8](start_span)local TweenService     = game:GetService("TweenService") --[span_8](end_span)
[span_9](start_span)local Workspace        = game:GetService("Workspace") --[span_9](end_span)
[span_10](start_span)local Lighting         = game:GetService("Lighting") --[span_10](end_span)

[span_11](start_span)local LocalPlayer      = Players.LocalPlayer --[span_11](end_span)
[span_12](start_span)local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui") --[span_12](end_span)
[span_13](start_span)local Camera           = Workspace.CurrentCamera --[span_13](end_span)
[span_14](start_span)local Character        = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() --[span_14](end_span)
[span_15](start_span)local Humanoid         = Character:WaitForChild("Humanoid") --[span_15](end_span)
[span_16](start_span)local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart") --[span_16](end_span)
[span_17](start_span)local Head             = Character:WaitForChild("Head") --[span_17](end_span)

[span_18](start_span)LocalPlayer.CharacterAdded:Connect(function(nc) --[span_18](end_span)
    [span_19](start_span)Character          = nc --[span_19](end_span)
    [span_20](start_span)Humanoid           = nc:WaitForChild("Humanoid") --[span_20](end_span)
    [span_21](start_span)HumanoidRootPart   = nc:WaitForChild("HumanoidRootPart") --[span_21](end_span)
    [span_22](start_span)Head               = nc:WaitForChild("Head") --[span_22](end_span)
end)

-- ═══════════════════════════════════════════════════════════
--                     FATE SYSTEM
-- ═══════════════════════════════════════════════════════════
local FateData = {
    [span_23](start_span)current    = 100, --[span_23](end_span)
    [span_24](start_span)max        = 100, --[span_24](end_span)
    [span_25](start_span)dead       = false, --[span_25](end_span)
    [span_26](start_span)drainRates = {}, --[span_26](end_span)
}

[span_27](start_span)local FATE_FULL  = Color3.fromRGB(255, 215, 0) --[span_27](end_span)
[span_28](start_span)local FATE_EMPTY = Color3.fromRGB(220, 220, 220) --[span_28](end_span)

local function GetFateColor(pct)   
    [span_29](start_span)return FATE_EMPTY:Lerp(FATE_FULL, pct)  --[span_29](end_span)
end

local function AddFateDrain(id,r)  
    [span_30](start_span)FateData.drainRates[id] = r  --[span_30](end_span)
end

local function RemoveFateDrain(id) 
    [span_31](start_span)FateData.drainRates[id] = nil  --[span_31](end_span)
end

local function ModifyFate(n)
    [span_32](start_span)FateData.current = math.clamp(FateData.current + n, 0, FateData.max) --[span_32](end_span)
end

-[span_33](start_span)- Use this for INSTANT burst damage (not drain-rate).[span_33](end_span)
-[span_34](start_span)- ModifyFate alone gets overwritten by SyncFateToHealth next frame[span_34](end_span)
-[span_35](start_span)- because SyncFateToHealth reads from Humanoid.Health.[span_35](end_span)
-[span_36](start_span)- This writes BOTH so they stay in sync.[span_36](end_span)
local function InstantFateDamage(pct)
    [span_37](start_span)ModifyFate(-pct) --[span_37](end_span)
    if Humanoid and Humanoid.MaxHealth > 0 then
        [span_38](start_span)local newHP = math.clamp(Humanoid.Health - (pct / 100) * Humanoid.MaxHealth, 0, Humanoid.MaxHealth) --[span_38](end_span)
        [span_39](start_span)Humanoid.Health = newHP --[span_39](end_span)
    end
end

-- ═══════════════════════════════════════════════════════════
--               ENTITY DEATH EFFECTS
-- ═══════════════════════════════════════════════════════════
-- Tracks which entity caused the most recent kill so the right
-[span_40](start_span)- death effect fires on Humanoid.Died.[span_40](end_span)
[span_41](start_span)local lastDeathCause   = nil   -- "Gaze"|"Elude"|"Numb"|"Mouthfeed"|"Piece"|"Delictum"|"Blue Sky"|nil[span_41](end_span)
[span_42](start_span)local pendingCorpse    = nil   -- pre-cloned corpse captured the moment damage is dealt[span_42](end_span)

-[span_43](start_span)- Tag a death cause AND immediately snapshot the character.[span_43](end_span)
-[span_44](start_span)- Must be called BEFORE setting Humanoid.Health = 0.[span_44](end_span)
local function TagDeathCause(cause)
    [span_45](start_span)lastDeathCause = cause --[span_45](end_span)
    -[span_46](start_span)- Clone right now while the character is 100% intact[span_46](end_span)
    local char = Character
    if char then
        local ok, clone = pcall(function()
            [span_47](start_span)local c = char:Clone() --[span_47](end_span)
            -[span_48](start_span)- Strip scripts so it stays static[span_48](end_span)
            [span_49](start_span)for _, obj in ipairs(c:GetDescendants()) do --[span_49](end_span)
                pcall(function()
                    [span_50](start_span)if obj:IsA("Script") or obj:IsA("LocalScript") --[span_50](end_span)
                    [span_51](start_span)or obj:IsA("Animator") or obj:IsA("Animation") then --[span_51](end_span)
                        [span_52](start_span)obj:Destroy() --[span_52](end_span)
                    [span_53](start_span)end --[span_53](end_span)
                end)
            end
            [span_54](start_span)local hum = c:FindFirstChildOfClass("Humanoid") --[span_54](end_span)
            if hum then
                [span_55](start_span)pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) --[span_55](end_span)
                [span_56](start_span)hum.PlatformStand = true --[span_56](end_span)
            end
            -[span_57](start_span)- Anchor everything initially; effects will unanchor what they need[span_57](end_span)
            [span_58](start_span)for _, p in ipairs(c:GetDescendants()) do --[span_58](end_span)
                pcall(function()
                    [span_59](start_span)if p:IsA("BasePart") then --[span_59](end_span)
                        [span_60](start_span)p.Anchored   = true --[span_60](end_span)
                        [span_61](start_span)p.CanCollide = false --[span_61](end_span)
                        [span_62](start_span)p.CastShadow = false --[span_62](end_span)
                    [span_63](start_span)end --[span_63](end_span)
                end)
            end
            [span_64](start_span)c.Parent = Workspace --[span_64](end_span)
            [span_65](start_span)return c --[span_65](end_span)
        end)
        if ok and clone then
            -[span_66](start_span)- Destroy any previous unclaimed corpse[span_66](end_span)
            if pendingCorpse then 
                [span_67](start_span)pcall(function() pendingCorpse:Destroy() end)  --[span_67](end_span)
            end
            [span_68](start_span)pendingCorpse = clone --[span_68](end_span)
        end
    end
end

-- ── Helpers ────────────────────────────────────────────────

-- Deep-clone the player's current avatar (shirts, pants, accessories, face)
-[span_69](start_span)- into Workspace as a static corpse model.[span_69](end_span)
-[span_70](start_span)- charSnapshot must be passed in (captured BEFORE Roblox cleans up the char).[span_70](end_span)
local function CloneAvatarAsCorpse(charSnapshot)
    [span_71](start_span)if not charSnapshot then return nil end --[span_71](end_span)
    [span_72](start_span)local ok, clone = pcall(function() return charSnapshot:Clone() end) --[span_72](end_span)
    [span_73](start_span)if not ok or not clone then return nil end --[span_73](end_span)
    
    [span_74](start_span)clone.Name = "GraceCorpse_"..tostring(tick()) --[span_74](end_span)
    -[span_75](start_span)- Strip live scripts / animator[span_75](end_span)
    [span_76](start_span)for _, obj in ipairs(clone:GetDescendants()) do --[span_76](end_span)
        if obj and obj.Parent then
            [span_77](start_span)local isOk, isScript = pcall(function() --[span_77](end_span)
                [span_78](start_span)return obj:IsA("Script") or obj:IsA("LocalScript") --[span_78](end_span)
                    [span_79](start_span)or obj:IsA("Animator") or obj:IsA("Animation") --[span_79](end_span)
            end)
            if isOk and isScript then
                [span_80](start_span)pcall(function() obj:Destroy() end) --[span_80](end_span)
            end
        [span_81](start_span)end --[span_81](end_span)
    end
    -[span_82](start_span)- Disable humanoid[span_82](end_span)
    [span_83](start_span)local hum = clone:FindFirstChildOfClass("Humanoid") --[span_83](end_span)
    if hum then
        [span_84](start_span)pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end) --[span_84](end_span)
        [span_85](start_span)hum.PlatformStand = true --[span_85](end_span)
    end
    -[span_86](start_span)- Unanchor every BasePart[span_86](end_span)
    [span_87](start_span)for _, p in ipairs(clone:GetDescendants()) do --[span_87](end_span)
        if p and p.Parent then
            pcall(function()
                [span_88](start_span)if p:IsA("BasePart") then --[span_88](end_span)
                    [span_89](start_span)p.Anchored   = false --[span_89](end_span)
                    [span_90](start_span)p.CanCollide = true --[span_90](end_span)
                    [span_91](start_span)p.CastShadow = false --[span_91](end_span)
                end
            [span_92](start_span)end) --[span_92](end_span)
        end
    end
    [span_93](start_span)clone.Parent = Workspace --[span_93](end_span)
    [span_94](start_span)return clone --[span_94](end_span)
end

-[span_95](start_span)- Spawn a flat blood puddle (Cylinder) at pos, growing over time[span_95](end_span)
local function SpawnBloodPuddle(pos, startR, endR, growTime)
    [span_96](start_span)startR   = startR  or 0.5 --[span_96](end_span)
    [span_97](start_span)endR     = endR    or 3 --[span_97](end_span)
    [span_98](start_span)growTime = growTime or 3 --[span_98](end_span)
    
    [span_99](start_span)local p  = Instance.new("Part") --[span_99](end_span)
    [span_100](start_span)p.Name        = "BloodPuddle" --[span_100](end_span)
    [span_101](start_span)p.Shape       = Enum.PartType.Cylinder --[span_101](end_span)
    [span_102](start_span)p.Size        = Vector3.new(0.18, startR*2, startR*2) --[span_102](end_span)
    [span_103](start_span)p.CFrame      = CFrame.new(pos + Vector3.new(0,0.06,0)) * CFrame.Angles(0,0,math.pi/2) --[span_103](end_span)
    [span_104](start_span)p.Anchored    = true --[span_104](end_span)
    [span_105](start_span)p.CanCollide  = false --[span_105](end_span)
    [span_106](start_span)p.CastShadow  = false --[span_106](end_span)
    [span_107](start_span)p.Color       = Color3.fromRGB(110,0,0) --[span_107](end_span)
    [span_108](start_span)p.Material    = Enum.Material.SmoothPlastic --[span_108](end_span)
    [span_109](start_span)p.Transparency = 0.15 --[span_109](end_span)
    [span_110](start_span)p.Parent      = Workspace --[span_110](end_span)
    
    [span_111](start_span)TweenService:Create(p, TweenInfo.new(growTime), {Size = Vector3.new(0.18, endR*2, endR*2)}):Play() --[span_111](end_span)
    [span_112](start_span)return p --[span_112](end_span)
end

-[span_113](start_span)- Spray small blood droplets from pos with random velocities[span_113](end_span)
local function SprayBlood(pos, count, speed)
    [span_114](start_span)speed = speed or 18 --[span_114](end_span)
    for _ = 1, count do
        [span_115](start_span)local d = Instance.new("Part") --[span_115](end_span)
        [span_116](start_span)d.Size        = Vector3.new(0.12,0.12,0.12) --[span_116](end_span)
        [span_117](start_span)d.Color       = Color3.fromRGB(100 + math.random(0, 40), 0, 0) --[span_117](end_span)
        [span_118](start_span)d.Material    = Enum.Material.SmoothPlastic --[span_118](end_span)
        [span_119](start_span)d.Transparency = 0.1 --[span_119](end_span)
        [span_120](start_span)d.CanCollide  = false --[span_120](end_span)
        [span_121](start_span)d.CastShadow  = false --[span_121](end_span)
        [span_122](start_span)d.CFrame      = CFrame.new(pos + Vector3.new((math.random()-0.5)*0.5, 0, (math.random()-0.5)*0.5)) --[span_122](end_span)
        [span_123](start_span)d.Parent      = Workspace --[span_123](end_span)
        
        [span_124](start_span)local bv = Instance.new("BodyVelocity") --[span_124](end_span)
        [span_125](start_span)local dir = Vector3.new(math.random()-0.5, math.random()*1.2-0.2, math.random()-0.5).Unit --[span_125](end_span)
        [span_126](start_span)bv.Velocity = dir * (speed * (0.5 + math.random()*0.8)) --[span_126](end_span)
        [span_127](start_span)bv.MaxForce = Vector3.new(1,1,1) * 9e8 --[span_127](end_span)
        [span_128](start_span)bv.P        = 9e8 --[span_128](end_span)
        [span_129](start_span)bv.Parent   = d --[span_129](end_span)
        
        [span_130](start_span)game:GetService("Debris"):AddItem(bv, 0.35) --[span_130](end_span)
        [span_131](start_span)game:GetService("Debris"):AddItem(d,  3) --[span_131](end_span)
    end
end

-[span_132](start_span)- Continuous drip from pos for duration seconds[span_132](end_span)
local function StartBloodDrip(posFunc, duration)
    [span_133](start_span)local running = true --[span_133](end_span)
    task.spawn(function()
        [span_134](start_span)while running do --[span_134](end_span)
            [span_135](start_span)local pos = posFunc() --[span_135](end_span)
            [span_136](start_span)if pos then SprayBlood(pos, 3, 4) end --[span_136](end_span)
            [span_137](start_span)task.wait(0.14) --[span_137](end_span)
        end
    end)
    [span_138](start_span)task.delay(duration, function() running = false end) --[span_138](end_span)
end

-[span_139](start_span)- Schedule any instance for destruction after 5 minutes[span_139](end_span)
local function AutoCleanup(inst)
    [span_140](start_span)game:GetService("Debris"):AddItem(inst, 300) --[span_140](end_span)
end

-- ── GAZE DEATH ──────────────────────────────────────────────
-[span_141](start_span)- Headless body at death position[span_141](end_span)
-[span_142](start_span)- + censored black bar on neck stump[span_142](end_span)
-[span_143](start_span)- + decapitated head tossed nearby with looping blood drip[span_143](end_span)
local function GazeDeathEffect(corpse)
    [span_144](start_span)if not corpse then return end --[span_144](end_span)
    [span_145](start_span)local hrp = corpse:FindFirstChild("HumanoidRootPart") --[span_145](end_span)
    [span_146](start_span)local deathPos = hrp and hrp.Position or Vector3.new(0,0,0) --[span_146](end_span)

    -[span_147](start_span)- Detach head from corpse[span_147](end_span)
    [span_148](start_span)local corpseHead = corpse:FindFirstChild("Head") --[span_148](end_span)
    [span_149](start_span)local neckPos    = deathPos + Vector3.new(0,1.5,0) --[span_149](end_span)
    if corpseHead then
        [span_150](start_span)neckPos = corpseHead.Position --[span_150](end_span)
        -[span_151](start_span)- Detach: remove motor/weld so it's free[span_151](end_span)
        [span_152](start_span)for _, w in ipairs(corpseHead:GetChildren()) do --[span_152](end_span)
            [span_153](start_span)if w:IsA("Motor6D") or w:IsA("Weld") or w:IsA("WeldConstraint") then --[span_153](end_span)
                [span_154](start_span)w:Destroy() --[span_154](end_span)
            end
        end
    end

    -[span_155](start_span)- Anchor body (headless static pose)[span_155](end_span)
    [span_156](start_span)for _, p in ipairs(corpse:GetDescendants()) do --[span_156](end_span)
        [span_157](start_span)if p:IsA("BasePart") then --[span_157](end_span)
            [span_158](start_span)p.Anchored   = true --[span_158](end_span)
            [span_159](start_span)p.CanCollide = false --[span_159](end_span)
        end
    end

    -[span_160](start_span)- Censored black bar over neck stump[span_160](end_span)
    [span_161](start_span)local torso = corpse:FindFirstChild("Torso") or corpse:FindFirstChild("UpperTorso") --[span_161](end_span)
    if torso then
        [span_162](start_span)local bb = Instance.new("BillboardGui") --[span_162](end_span)
        [span_163](start_span)bb.Size        = UDim2.new(0,100,0,24) --[span_163](end_span)
        [span_164](start_span)bb.StudsOffset = Vector3.new(0,1.45,0) --[span_164](end_span)
        [span_165](start_span)bb.AlwaysOnTop = false --[span_165](end_span)
        [span_166](start_span)bb.Adornee     = torso --[span_166](end_span)
        [span_167](start_span)bb.Parent      = torso --[span_167](end_span)

        [span_168](start_span)local bar = Instance.new("Frame") --[span_168](end_span)
        [span_169](start_span)bar.Size             = UDim2.new(1,0,1,0) --[span_169](end_span)
        [span_170](start_span)bar.BackgroundColor3 = Color3.fromRGB(0,0,0) --[span_170](end_span)
        [span_171](start_span)bar.BorderSizePixel  = 0 --[span_171](end_span)
        [span_172](start_span)bar.Parent           = bb --[span_172](end_span)

        [span_173](start_span)local ct = Instance.new("TextLabel") --[span_173](end_span)
        [span_174](start_span)ct.Size                   = UDim2.new(1,0,1,0) --[span_174](end_span)
        [span_175](start_span)ct.BackgroundTransparency = 1 --[span_175](end_span)
        [span_176](start_span)ct.Text                   = "████████████" --[span_176](end_span)
        [span_177](start_span)ct.Font                   = Enum.Font.GothamBold --[span_177](end_span)
        [span_178](start_span)ct.TextSize               = 13 --[span_178](end_span)
        [span_179](start_span)ct.TextColor3             = Color3.fromRGB(25,25,25) --[span_179](end_span)
        [span_180](start_span)ct.Parent                 = bb --[span_180](end_span)
    end

    -[span_181](start_span)- Blood spray from neck[span_181](end_span)
    [span_182](start_span)SprayBlood(neckPos, 30, 12) --[span_182](end_span)
    [span_183](start_span)local puddle = SpawnBloodPuddle(deathPos, 0.4, 3.5, 4) --[span_183](end_span)
    [span_184](start_span)AutoCleanup(puddle) --[span_184](end_span)

    -[span_185](start_span)- Toss decapitated head[span_185](end_span)
    if corpseHead and corpseHead.Parent then
        [span_186](start_span)corpseHead.Anchored   = false --[span_186](end_span)
        [span_187](start_span)corpseHead.CanCollide = true --[span_187](end_span)
        
        [span_188](start_span)local bv = Instance.new("BodyVelocity") --[span_188](end_span)
        [span_189](start_span)local dir = Vector3.new(math.random()-0.5, 0.8+math.random()*0.5, math.random()-0.5).Unit --[span_189](end_span)
        [span_190](start_span)bv.Velocity = dir * (10 + math.random()*8) --[span_190](end_span)
        [span_191](start_span)bv.MaxForce = Vector3.new(1,1,1)*1e5 --[span_191](end_span)
        [span_192](start_span)bv.P        = 5000 --[span_192](end_span)
        [span_193](start_span)bv.Parent   = corpseHead --[span_193](end_span)
        [span_194](start_span)game:GetService("Debris"):AddItem(bv, 0.5) --[span_194](end_span)

        -[span_195](start_span)- Settle then drip[span_195](end_span)
        task.delay(1.5, function()
            if corpseHead and corpseHead.Parent then
                [span_196](start_span)corpseHead.Anchored = true --[span_196](end_span)
                [span_197](start_span)local headPuddle = SpawnBloodPuddle(corpseHead.Position + Vector3.new(0,-0.5,0), 0.2, 1.8, 5) --[span_197](end_span)
                [span_198](start_span)AutoCleanup(headPuddle) --[span_198](end_span)
                
                StartBloodDrip(function()
                    [span_199](start_span)return corpseHead and corpseHead.Parent and (corpseHead.Position + Vector3.new(0,-0.5,0)) or nil --[span_199](end_span)
                [span_200](start_span)end, 60) --[span_200](end_span)
            end
        end)
        [span_201](start_span)AutoCleanup(corpseHead) --[span_201](end_span)
    end

    -[span_202](start_span)- Ongoing neck drip from body[span_202](end_span)
    StartBloodDrip(function()
        if torso and torso.Parent then
            [span_203](start_span)return torso.Position + Vector3.new(0,1.4,0) --[span_203](end_span)
        end
        [span_204](start_span)return nil --[span_204](end_span)
    [span_205](start_span)end, 30) --[span_205](end_span)

    [span_206](start_span)AutoCleanup(corpse) --[span_206](end_span)
end

-- ── ELUDE / MOUTHFEED DEATH ─────────────────────────────────
local function ExplodingLimbsDeathEffect(corpse)
    [span_207](start_span)if not corpse then return end --[span_207](end_span)
    [span_208](start_span)local hrp      = corpse:FindFirstChild("HumanoidRootPart") --[span_208](end_span)
    [span_209](start_span)local deathPos = hrp and hrp.Position or Vector3.new(0,0,0) --[span_209](end_span)

    [span_210](start_span)for _, p in ipairs(corpse:GetDescendants()) do --[span_210](end_span)
        if p and p.Parent then
            pcall(function()
                [span_211](start_span)if p:IsA("BasePart") then --[span_211](end_span)
                    [span_212](start_span)p.Anchored   = false --[span_212](end_span)
                    [span_213](start_span)p.CanCollide = true --[span_213](end_span)
                    
                    local dir = Vector3.new(
                        [span_214](start_span)math.random()-0.5, --[span_214](end_span)
                        [span_215](start_span)0.4 + math.random()*0.8, --[span_215](end_span)
                        [span_216](start_span)math.random()-0.5 --[span_216](end_span)
                    ).Unit
                    
                    [span_217](start_span)local bv = Instance.new("BodyVelocity") --[span_217](end_span)
                    [span_218](start_span)bv.Velocity = dir * (18 + math.random()*28) --[span_218](end_span)
                    [span_219](start_span)bv.MaxForce = Vector3.new(1,1,1) * 9e8 --[span_219](end_span)
                    [span_220](start_span)bv.P        = 9e8 --[span_220](end_span)
                    [span_221](start_span)bv.Parent   = p --[span_221](end_span)
                    
                    [span_222](start_span)game:GetService("Debris"):AddItem(bv, 0.4) --[span_222](end_span)
                end
            end)
        end
    end

    [span_223](start_span)SprayBlood(deathPos + Vector3.new(0,1,0), 35, 22) --[span_223](end_span)

    task.delay(0.6, function()
        [span_224](start_span)local puddle = SpawnBloodPuddle(deathPos, 0.4, 5, 3.5) --[span_224](end_span)
        [span_225](start_span)AutoCleanup(puddle) --[span_225](end_span)
    end)

    [span_226](start_span)AutoCleanup(corpse) --[span_226](end_span)
end

-- ── NUMB DEATH ──────────────────────────────────────────────
-[span_227](start_span)- Body squishes flat and turns red, then dissolves into blood puddle[span_227](end_span)
local function NumbDeathEffect(corpse)
    [span_228](start_span)if not corpse then return end --[span_228](end_span)
    [span_229](start_span)local hrp = corpse:FindFirstChild("HumanoidRootPart") --[span_229](end_span)
    [span_230](start_span)local deathPos = hrp and hrp.Position or Vector3.new(0,0,0) --[span_230](end_span)

    -[span_231](start_span)- Parts are already anchored by the dispatcher[span_231](end_span)

    -[span_232](start_span)- Phase 1 (0–1.5s): turn red[span_232](end_span)
    [span_233](start_span)for _, p in ipairs(corpse:GetDescendants()) do --[span_233](end_span)
        if p:IsA("BasePart") then
            [span_234](start_span)TweenService:Create(p, TweenInfo.new(1.5), {Color = Color3.fromRGB(150,0,0)}):Play() --[span_234](end_span)
        end
    end

    -[span_235](start_span)- Phase 2 (1.5–4s): squish flat downward[span_235](end_span)
    task.delay(1.5, function()
        [span_236](start_span)if not corpse or not corpse.Parent then return end --[span_236](end_span)
        
        [span_237](start_span)for _, p in ipairs(corpse:GetDescendants()) do --[span_237](end_span)
            if p:IsA("BasePart") then
                TweenService:Create(p,
                    [span_238](start_span)TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { --[span_238](end_span)
                    [span_239](start_span)Size  = Vector3.new(p.Size.X*1.8, math.max(p.Size.Y*0.04, 0.04), p.Size.Z*1.8), --[span_239](end_span)
                    CFrame = CFrame.new(
                        [span_240](start_span)deathPos.X + (p.Position.X-deathPos.X)*1.15, --[span_240](end_span)
                        [span_241](start_span)deathPos.Y + 0.05, --[span_241](end_span)
                        [span_242](start_span)deathPos.Z + (p.Position.Z-deathPos.Z)*1.15), --[span_242](end_span)
                    [span_243](start_span)Transparency = 0.65, --[span_243](end_span)
                [span_244](start_span)}):Play() --[span_244](end_span)
            end
        end

        [span_245](start_span)local puddle = SpawnBloodPuddle(deathPos, 0.3, 7, 2.8) --[span_245](end_span)
        [span_246](start_span)AutoCleanup(puddle) --[span_246](end_span)

        -[span_247](start_span)- Phase 3 (3.5s): fade out completely[span_247](end_span)
        task.delay(2.8, function()
            [span_248](start_span)if not corpse or not corpse.Parent then return end --[span_248](end_span)
            [span_249](start_span)for _, p in ipairs(corpse:GetDescendants()) do --[span_249](end_span)
                if p:IsA("BasePart") then
                    [span_250](start_span)TweenService:Create(p, TweenInfo.new(0.6), {Transparency=1}):Play() --[span_250](end_span)
                end
            end
            task.delay(0.7, function()
                [span_251](start_span)if corpse and corpse.Parent then corpse:Destroy() end --[span_251](end_span)
            end)
        end)
    end)

    [span_252](start_span)AutoCleanup(corpse) --[span_252](end_span)
end

-- ── PIECE DEATH ─────────────────────────────────────────────
-[span_253](start_span)- Ragdoll briefly, then both wrists yanked upward by infinite white chains[span_253](end_span)
local function PieceDeathEffect(corpse)
    [span_254](start_span)if not corpse then return end --[span_254](end_span)
    [span_255](start_span)local hrp = corpse:FindFirstChild("HumanoidRootPart") --[span_255](end_span)
    [span_256](start_span)local deathPos = hrp and hrp.Position or Vector3.new(0,0,0) --[span_256](end_span)

    -[span_257](start_span)- Unanchor briefly for ragdoll settle[span_257](end_span)
    [span_258](start_span)for _, p in ipairs(corpse:GetDescendants()) do --[span_258](end_span)
        if p and p.Parent then
            pcall(function()
                [span_259](start_span)if p:IsA("BasePart") then --[span_259](end_span)
                    [span_260](start_span)p.Anchored   = false --[span_260](end_span)
                    [span_261](start_span)p.CanCollide = true --[span_261](end_span)
                end
            end)
        end
    end

    task.delay(0.7, function()
        [span_262](start_span)if not corpse or not corpse.Parent then return end --[span_262](end_span)

        -[span_263](start_span)- Anchor everything[span_263](end_span)
        [span_264](start_span)for _, p in ipairs(corpse:GetDescendants()) do --[span_264](end_span)
            if p:IsA("BasePart") then
                [span_265](start_span)p.Anchored   = true --[span_265](end_span)
                [span_266](start_span)p.CanCollide = false --[span_266](end_span)
            end
        end

        -[span_267](start_span)- Find arm parts (R6 naming)[span_267](end_span)
        [span_268](start_span)local lArm = corpse:FindFirstChild("Left Arm")  or corpse:FindFirstChild("LeftHand") --[span_268](end_span)
        [span_269](start_span)local rArm = corpse:FindFirstChild("Right Arm") or corpse:FindFirstChild("RightHand") --[span_269](end_span)
        [span_270](start_span)local torso = corpse:FindFirstChild("Torso") or corpse:FindFirstChild("UpperTorso") --[span_270](end_span)

        -[span_271](start_span)- Tween whole corpse upward 12 studs over 2s[span_271](end_span)
        [span_272](start_span)for _, p in ipairs(corpse:GetDescendants()) do --[span_272](end_span)
            if p:IsA("BasePart") then
                [span_273](start_span)TweenService:Create(p, --[span_273](end_span)
                    [span_274](start_span)TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { --[span_274](end_span)
                    [span_275](start_span)CFrame = p.CFrame + Vector3.new(0,12,0) --[span_275](end_span)
                [span_276](start_span)}):Play() --[span_276](end_span)
            end
        end

        -[span_277](start_span)- After lift, spawn tall white chain segments from each hand going to sky[span_277](end_span)
        task.delay(2.1, function()
            local function MakeChain(armPart)
                [span_278](start_span)if not armPart or not armPart.Parent then return end --[span_278](end_span)
                
                [span_279](start_span)local chainPart = Instance.new("Part") --[span_279](end_span)
                [span_280](start_span)chainPart.Name        = "PieceChain" --[span_280](end_span)
                [span_281](start_span)chainPart.Size        = Vector3.new(0.18, 800, 0.18) --[span_281](end_span)
                [span_282](start_span)chainPart.Color       = Color3.fromRGB(245,245,255) --[span_282](end_span)
                [span_283](start_span)chainPart.Material    = Enum.Material.SmoothPlastic --[span_283](end_span)
                [span_284](start_span)chainPart.Transparency = 0.08 --[span_284](end_span)
                [span_285](start_span)chainPart.Anchored    = true --[span_285](end_span)
                [span_286](start_span)chainPart.CanCollide  = false --[span_286](end_span)
                [span_287](start_span)chainPart.CastShadow  = false --[span_287](end_span)
                
                -[span_288](start_span)- Centre the tall cylinder so bottom is at hand position[span_288](end_span)
                [span_289](start_span)chainPart.CFrame      = CFrame.new(armPart.Position + Vector3.new(0,400,0)) --[span_289](end_span)
                [span_290](start_span)chainPart.Parent      = Workspace --[span_290](end_span)
                [span_291](start_span)AutoCleanup(chainPart) --[span_291](end_span)

                -[span_292](start_span)- Subtle chain link texture via UIGradient BillboardGui won't work on Part,[span_292](end_span)
                -[span_293](start_span)- so add thin dark rings along the chain for visual rhythm[span_293](end_span)
                for i = 1, 12 do
                    [span_294](start_span)local ring = Instance.new("Part") --[span_294](end_span)
                    [span_295](start_span)ring.Size        = Vector3.new(0.35, 0.12, 0.35) --[span_295](end_span)
                    [span_296](start_span)ring.Color       = Color3.fromRGB(200,200,220) --[span_296](end_span)
                    [span_297](start_span)ring.Material    = Enum.Material.SmoothPlastic --[span_297](end_span)
                    [span_298](start_span)ring.Transparency = 0.2 --[span_298](end_span)
                    [span_299](start_span)ring.Anchored    = true --[span_299](end_span)
                    [span_300](start_span)ring.CanCollide  = false --[span_300](end_span)
                    [span_301](start_span)ring.CastShadow  = false --[span_301](end_span)
                    [span_302](start_span)ring.CFrame      = CFrame.new(armPart.Position + Vector3.new(0, i*4, 0)) --[span_302](end_span)
                    [span_303](start_span)ring.Parent      = Workspace --[span_303](end_span)
                    [span_304](start_span)AutoCleanup(ring) --[span_304](end_span)
                end
            end

            [span_305](start_span)MakeChain(lArm) --[span_305](end_span)
            [span_306](start_span)MakeChain(rArm) --[span_306](end_span)
        end)
    end)

    [span_307](start_span)AutoCleanup(corpse) --[span_307](end_span)
end

-- ── DELICTUM DEATH ──────────────────────────────────────────
-[span_308](start_span)- Only the head remains on the ground; rest of body gone; blood floods out[span_308](end_span)
local function DelictumDeathEffect(corpse)
    [span_309](start_span)if not corpse then return end --[span_309](end_span)
    [span_310](start_span)local hrp = corpse:FindFirstChild("HumanoidRootPart") --[span_310](end_span)
    [span_311](start_span)local deathPos = hrp and hrp.Position or Vector3.new(0,0,0) --[span_311](end_span)

    -[span_312](start_span)- Immediately destroy everything except Head and accessories[span_312](end_span)
    [span_313](start_span)for _, p in ipairs(corpse:GetChildren()) do --[span_313](end_span)
        [span_314](start_span)local keep = false --[span_314](end_span)
        [span_315](start_span)if p:IsA("BasePart") and p.Name == "Head" then keep = true end --[span_315](end_span)
        [span_316](start_span)if p:IsA("Accessory") then keep = true end  -- hats, hair stay[span_316](end_span)
        [span_317](start_span)if p:IsA("SpecialMesh") then keep = true end --[span_317](end_span)
        
        if not keep and p:IsA("BasePart") then 
            [span_318](start_span)p:Destroy() --[span_318](end_span)
        elseif not keep and p:IsA("Motor6D") then 
            [span_319](start_span)p:Destroy() --[span_319](end_span)
        end
    end
    
    -[span_320](start_span)- Also destroy any non-head BaseParts that snuck in[span_320](end_span)
    [span_321](start_span)for _, p in ipairs(corpse:GetDescendants()) do --[span_321](end_span)
        [span_322](start_span)if p:IsA("BasePart") and p.Name ~= "Head" then p:Destroy() end --[span_322](end_span)
    end

    [span_323](start_span)local head = corpse:FindFirstChild("Head") --[span_323](end_span)
    if head then
        [span_324](start_span)head.Anchored   = true --[span_324](end_span)
        [span_325](start_span)head.CanCollide = false --[span_325](end_span)
        
        -[span_326](start_span)- Drop it to the ground slightly[span_326](end_span)
        local groundRay = Workspace:Raycast(
            [span_327](start_span)deathPos + Vector3.new(0,5,0), Vector3.new(0,-15,0), --[span_327](end_span)
            [span_328](start_span)RaycastParams.new() --[span_328](end_span)
        )
        [span_329](start_span)local groundY = groundRay and groundRay.Position.Y or (deathPos.Y) --[span_329](end_span)
        
        [span_330](start_span)head.CFrame = CFrame.new(deathPos.X, groundY + 0.55, deathPos.Z) --[span_330](end_span)
            * [span_331](start_span)CFrame.Angles(0, math.random()*math.pi*2, math.random()*0.3-0.15) --[span_331](end_span)

        -[span_332](start_span)- Snap accessories to head position[span_332](end_span)
        [span_333](start_span)for _, acc in ipairs(corpse:GetChildren()) do --[span_333](end_span)
            [span_334](start_span)if acc:IsA("Accessory") then --[span_334](end_span)
                [span_335](start_span)local handle = acc:FindFirstChild("Handle") --[span_335](end_span)
                [span_336](start_span)if handle then --[span_336](end_span)
                    [span_337](start_span)handle.Anchored   = true --[span_337](end_span)
                    [span_338](start_span)handle.CanCollide = false --[span_338](end_span)
                    [span_339](start_span)handle.CFrame = head.CFrame * CFrame.new(0, 0.5 + math.random()*0.3, 0) --[span_339](end_span)
                [span_340](start_span)end --[span_340](end_span)
            end
        end

        -[span_341](start_span)- Growing blood pool from head[span_341](end_span)
        [span_342](start_span)local puddle = SpawnBloodPuddle(head.Position + Vector3.new(0,-0.5,0), 0.2, 5.5, 6) --[span_342](end_span)
        [span_343](start_span)AutoCleanup(puddle) --[span_343](end_span)

        -[span_344](start_span)- Long blood drip animation[span_344](end_span)
        StartBloodDrip(function()
            [span_345](start_span)return head and head.Parent and (head.Position + Vector3.new(0,-0.45,0)) or nil --[span_345](end_span)
        [span_346](start_span)end, 90) --[span_346](end_span)
    end

    [span_347](start_span)AutoCleanup(corpse) --[span_347](end_span)
end

-- ── BLUE SKY DEATH ──────────────────────────────────────────
-- NEW: Atomic Vaporization. Corpse turns blinding neon, expands, then vanishes to ash.
local function BlueSkyDeathEffect(corpse)
    if not corpse then return end
    
    local hrp = corpse:FindFirstChild("HumanoidRootPart")
    local deathPos = hrp and hrp.Position or Vector3.new(0,0,0)

    -- Anchor and suspend in mid-air for the vaporization process
    for _, p in ipairs(corpse:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored   = true
            p.CanCollide = false
            p.CastShadow = false
            
            -- Turn into burning neon orange
            TweenService:Create(p, TweenInfo.new(0.5), {
                Color = Color3.fromRGB(255, 80, 0),
                Material = Enum.Material.Neon
            }):Play()
        end
    end
    
    -- Phase 2: Rapid expansion and fade out (turning to ash)
    task.delay(0.5, function()
        if not corpse or not corpse.Parent then return end
        
        for _, p in ipairs(corpse:GetDescendants()) do
            if p:IsA("BasePart") then
                TweenService:Create(p, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = p.Size * 1.5,
                    Transparency = 1,
                    Color = Color3.fromRGB(20, 20, 20) -- burns to black ash before vanishing
                }):Play()
            end
        end
        
        -- Leave a scorched blast mark on the floor
        local scorch = Instance.new("Part")
        scorch.Name = "NuclearScorch"
        scorch.Shape = Enum.PartType.Cylinder
        scorch.Size = Vector3.new(0.1, 15, 15)
        scorch.CFrame = CFrame.new(deathPos) * CFrame.Angles(0, 0, math.pi/2)
        scorch.Color = Color3.fromRGB(15, 15, 15)
        scorch.Material = Enum.Material.Slate
        scorch.Anchored = true
        scorch.CanCollide = false
        scorch.Parent = Workspace
        
        TweenService:Create(scorch, TweenInfo.new(10), {Transparency = 1}):Play()
        AutoCleanup(scorch)
        
        task.delay(1.5, function()
            if corpse and corpse.Parent then corpse:Destroy() end
        end)
    end)
end

-- ── DISPATCH ────────────────────────────────────────────────
local function ConnectDeathEffect(targetChar)
    [span_348](start_span)targetChar = targetChar or Character --[span_348](end_span)
    [span_349](start_span)if not targetChar then return end --[span_349](end_span)
    
    [span_350](start_span)local hum = targetChar:FindFirstChildOfClass("Humanoid") --[span_350](end_span)
    if not hum then
        [span_351](start_span)hum = targetChar:WaitForChild("Humanoid", 5) --[span_351](end_span)
        [span_352](start_span)if not hum then return end --[span_352](end_span)
    end

    hum.Died:Connect(function()
        [span_353](start_span)local cause  = lastDeathCause --[span_353](end_span)
        [span_354](start_span)local corpse = pendingCorpse   -- grabbed BEFORE health hit 0, fully intact[span_354](end_span)
        [span_355](start_span)lastDeathCause = nil --[span_355](end_span)
        [span_356](start_span)pendingCorpse  = nil --[span_356](end_span)

        [span_357](start_span)if not corpse then return end  -- no snapshot = no effect (non-entity death)[span_357](end_span)

        task.delay(0.08, function()
            [span_358](start_span)if not corpse.Parent then return end --[span_358](end_span)
            
            [span_359](start_span)if      cause == "Gaze"      then GazeDeathEffect(corpse) --[span_359](end_span)
            [span_360](start_span)elseif  cause == "Elude"     then ExplodingLimbsDeathEffect(corpse) --[span_360](end_span)
            [span_361](start_span)elseif  cause == "Numb"      then NumbDeathEffect(corpse) --[span_361](end_span)
            [span_362](start_span)elseif  cause == "Mouthfeed" then ExplodingLimbsDeathEffect(corpse) --[span_362](end_span)
            [span_363](start_span)elseif  cause == "Piece"     then PieceDeathEffect(corpse) --[span_363](end_span)
            [span_364](start_span)elseif  cause == "Delictum"  then DelictumDeathEffect(corpse) --[span_364](end_span)
            [span_365](start_span)elseif  cause == "Norm"      then ExplodingLimbsDeathEffect(corpse) --[span_365](end_span)
            elseif  cause == "Blue Sky"  then BlueSkyDeathEffect(corpse) -- NEW
            [span_366](start_span)else    pcall(function() corpse:Destroy() end) --[span_366](end_span)
            end
        end)
    end)
end
task.defer(function()
    [span_367](start_span)ConnectDeathEffect(Character) --[span_367](end_span)
end)

-- ═══════════════════════════════════════════════════════════
--                     MAIN GUI
-- ═══════════════════════════════════════════════════════════
[span_368](start_span)local ScreenGui = Instance.new("ScreenGui") --[span_368](end_span)
[span_369](start_span)ScreenGui.Name            = "GraceGUI" --[span_369](end_span)
[span_370](start_span)ScreenGui.ResetOnSpawn    = false --[span_370](end_span)
[span_371](start_span)ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling --[span_371](end_span)
[span_372](start_span)ScreenGui.IgnoreGuiInset  = true --[span_372](end_span)
[span_373](start_span)ScreenGui.Parent          = PlayerGui --[span_373](end_span)

-- ── FATE LABEL ─────────────────────────────────────────────
[span_374](start_span)local FateLabel = Instance.new("TextLabel") --[span_374](end_span)
[span_375](start_span)FateLabel.Name                   = "FateLabel" --[span_375](end_span)
[span_376](start_span)FateLabel.Size                   = UDim2.new(0, 220, 0, 60) --[span_376](end_span)
[span_377](start_span)FateLabel.AnchorPoint            = Vector2.new(0.5, 0) --[span_377](end_span)
[span_378](start_span)FateLabel.Position               = UDim2.new(0.5, 0, 0, 18) --[span_378](end_span)
[span_379](start_span)FateLabel.BackgroundTransparency = 1 --[span_379](end_span)
[span_380](start_span)FateLabel.Text                   = "FATE" --[span_380](end_span)
[span_381](start_span)FateLabel.Font                   = Enum.Font.GothamBold --[span_381](end_span)
[span_382](start_span)FateLabel.TextSize               = 46 --[span_382](end_span)
[span_383](start_span)FateLabel.TextColor3             = FATE_FULL --[span_383](end_span)
[span_384](start_span)FateLabel.TextStrokeTransparency = 0.4 --[span_384](end_span)
[span_385](start_span)FateLabel.TextStrokeColor3       = Color3.fromRGB(0,0,0) --[span_385](end_span)
[span_386](start_span)FateLabel.ZIndex                 = 10 --[span_386](end_span)
[span_387](start_span)FateLabel.Parent                 = ScreenGui --[span_387](end_span)

[span_388](start_span)local FateGlow = Instance.new("TextLabel") --[span_388](end_span)
[span_389](start_span)FateGlow.Size                   = FateLabel.Size --[span_389](end_span)
[span_390](start_span)FateGlow.AnchorPoint            = FateLabel.AnchorPoint --[span_390](end_span)
[span_391](start_span)FateGlow.Position               = FateLabel.Position --[span_391](end_span)
[span_392](start_span)FateGlow.BackgroundTransparency = 1 --[span_392](end_span)
[span_393](start_span)FateGlow.Text                   = "FATE" --[span_393](end_span)
[span_394](start_span)FateGlow.Font                   = Enum.Font.GothamBold --[span_394](end_span)
[span_395](start_span)FateGlow.TextSize               = 46 --[span_395](end_span)
[span_396](start_span)FateGlow.TextColor3             = FATE_FULL --[span_396](end_span)
[span_397](start_span)FateGlow.TextTransparency       = 0.75 --[span_397](end_span)
[span_398](start_span)FateGlow.ZIndex                 = 9 --[span_398](end_span)
[span_399](start_span)FateGlow.Parent                 = ScreenGui --[span_399](end_span)

-- ── FATE BAR ───────────────────────────────────────────────
[span_400](start_span)local FateBarBG = Instance.new("Frame") --[span_400](end_span)
[span_401](start_span)FateBarBG.Name             = "FateBarBG" --[span_401](end_span)
[span_402](start_span)FateBarBG.Size             = UDim2.new(0, 200, 0, 5) --[span_402](end_span)
[span_403](start_span)FateBarBG.AnchorPoint      = Vector2.new(0.5, 0) --[span_403](end_span)
[span_404](start_span)FateBarBG.Position         = UDim2.new(0.5, 0, 0, 72) --[span_404](end_span)
[span_405](start_span)FateBarBG.BackgroundColor3 = Color3.fromRGB(40,40,40) --[span_405](end_span)
[span_406](start_span)FateBarBG.BorderSizePixel  = 0 --[span_406](end_span)
[span_407](start_span)FateBarBG.ZIndex           = 10 --[span_407](end_span)
[span_408](start_span)FateBarBG.Parent           = ScreenGui --[span_408](end_span)
[span_409](start_span)Instance.new("UICorner", FateBarBG).CornerRadius = UDim.new(1,0) --[span_409](end_span)

[span_410](start_span)local FateBarFill = Instance.new("Frame") --[span_410](end_span)
[span_411](start_span)FateBarFill.Name             = "FateBarFill" --[span_411](end_span)
[span_412](start_span)FateBarFill.Size             = UDim2.new(1,0,1,0) --[span_412](end_span)
[span_413](start_span)FateBarFill.BackgroundColor3 = FATE_FULL --[span_413](end_span)
[span_414](start_span)FateBarFill.BorderSizePixel  = 0 --[span_414](end_span)
[span_415](start_span)FateBarFill.ZIndex           = 11 --[span_415](end_span)
[span_416](start_span)FateBarFill.Parent           = FateBarBG --[span_416](end_span)
[span_417](start_span)Instance.new("UICorner", FateBarFill).CornerRadius = UDim.new(1,0) --[span_417](end_span)

[span_418](start_span)local FatePct = Instance.new("TextLabel") --[span_418](end_span)
[span_419](start_span)FatePct.Name                   = "FatePct" --[span_419](end_span)
[span_420](start_span)FatePct.Size                   = UDim2.new(0,200,0,18) --[span_420](end_span)
[span_421](start_span)FatePct.AnchorPoint            = Vector2.new(0.5,0) --[span_421](end_span)
[span_422](start_span)FatePct.Position               = UDim2.new(0.5,0,0,80) --[span_422](end_span)
[span_423](start_span)FatePct.BackgroundTransparency = 1 --[span_423](end_span)
[span_424](start_span)FatePct.Text                   = "100%" --[span_424](end_span)
[span_425](start_span)FatePct.Font                   = Enum.Font.Gotham --[span_425](end_span)
[span_426](start_span)FatePct.TextSize               = 13 --[span_426](end_span)
[span_427](start_span)FatePct.TextColor3             = Color3.fromRGB(180,180,180) --[span_427](end_span)
[span_428](start_span)FatePct.TextStrokeTransparency = 0.6 --[span_428](end_span)
[span_429](start_span)FatePct.ZIndex                 = 10 --[span_429](end_span)
[span_430](start_span)FatePct.Parent                 = ScreenGui --[span_430](end_span)

-- ── DEATH SCREEN ───────────────────────────────────────────
[span_431](start_span)local DeathScreen = Instance.new("Frame") --[span_431](end_span)
[span_432](start_span)DeathScreen.Name                   = "DeathScreen" --[span_432](end_span)
[span_433](start_span)DeathScreen.Size                   = UDim2.new(1,0,1,0) --[span_433](end_span)
[span_434](start_span)DeathScreen.BackgroundColor3       = Color3.fromRGB(255,255,255) --[span_434](end_span)
[span_435](start_span)DeathScreen.BackgroundTransparency = 1 --[span_435](end_span)
[span_436](start_span)DeathScreen.ZIndex                 = 100 --[span_436](end_span)
[span_437](start_span)DeathScreen.Visible                = false --[span_437](end_span)
[span_438](start_span)DeathScreen.Parent                 = ScreenGui --[span_438](end_span)

[span_439](start_span)local DeathLabel = Instance.new("TextLabel") --[span_439](end_span)
[span_440](start_span)DeathLabel.Size                   = UDim2.new(1,0,0,80) --[span_440](end_span)
[span_441](start_span)DeathLabel.AnchorPoint            = Vector2.new(0.5,0.5) --[span_441](end_span)
[span_442](start_span)DeathLabel.Position               = UDim2.new(0.5,0,0.5,0) --[span_442](end_span)
[span_443](start_span)DeathLabel.BackgroundTransparency = 1 --[span_443](end_span)
DeathLabel.Text                   = "your fate ran out." -[span_444](start_span)-[span_444](end_span)
[span_445](start_span)DeathLabel.Font                   = Enum.Font.GothamBold --[span_445](end_span)
[span_446](start_span)DeathLabel.TextSize               = 38 --[span_446](end_span)
[span_447](start_span)DeathLabel.TextColor3             = Color3.fromRGB(30,30,30) --[span_447](end_span)
[span_448](start_span)DeathLabel.TextTransparency       = 1 --[span_448](end_span)
[span_449](start_span)DeathLabel.ZIndex                 = 101 --[span_449](end_span)
[span_450](start_span)DeathLabel.Parent                 = DeathScreen --[span_450](end_span)

-[span_451](start_span)- ── VIGNETTE (frame gradient, no rbxasset path) ────────────[span_451](end_span)
[span_452](start_span)local VigFrame = Instance.new("Frame") --[span_452](end_span)
[span_453](start_span)VigFrame.Size                   = UDim2.new(1,0,1,0) --[span_453](end_span)
[span_454](start_span)VigFrame.BackgroundTransparency = 1 --[span_454](end_span)
[span_455](start_span)VigFrame.BorderSizePixel        = 0 --[span_455](end_span)
[span_456](start_span)VigFrame.ZIndex                 = 8 --[span_456](end_span)
[span_457](start_span)VigFrame.Parent                 = ScreenGui --[span_457](end_span)

local function MakeVigEdge(ax, ay, sx, sy, rot)
    [span_458](start_span)local f = Instance.new("Frame") --[span_458](end_span)
    [span_459](start_span)f.Size             = UDim2.new(sx,0,sy,0) --[span_459](end_span)
    [span_460](start_span)f.AnchorPoint      = Vector2.new(ax,ay) --[span_460](end_span)
    [span_461](start_span)f.Position         = UDim2.new(ax,0,ay,0) --[span_461](end_span)
    [span_462](start_span)f.BackgroundColor3 = Color3.fromRGB(0,0,0) --[span_462](end_span)
    [span_463](start_span)f.BackgroundTransparency = 1 --[span_463](end_span)
    [span_464](start_span)f.BorderSizePixel  = 0 --[span_464](end_span)
    [span_465](start_span)f.ZIndex           = 8 --[span_465](end_span)
    [span_466](start_span)f.Parent           = VigFrame --[span_466](end_span)
    
    [span_467](start_span)local g = Instance.new("UIGradient") --[span_467](end_span)
    [span_468](start_span)g.Rotation     = rot --[span_468](end_span)
    [span_469](start_span)g.Transparency = NumberSequence.new({ --[span_469](end_span)
        [span_470](start_span)NumberSequenceKeypoint.new(0, 0), --[span_470](end_span)
        [span_471](start_span)NumberSequenceKeypoint.new(1, 1), --[span_471](end_span)
    [span_472](start_span)}) --[span_472](end_span)
    [span_473](start_span)g.Parent = f --[span_473](end_span)
    [span_474](start_span)return f --[span_474](end_span)
end

[span_475](start_span)local VigTop    = MakeVigEdge(0, 0,   1, 0.20,   0) --[span_475](end_span)
[span_476](start_span)local VigBottom = MakeVigEdge(0, 1,   1, 0.20, 180) --[span_476](end_span)
[span_477](start_span)local VigLeft   = MakeVigEdge(0, 0, 0.14, 1,    90) --[span_477](end_span)
[span_478](start_span)local VigRight  = MakeVigEdge(1, 0, 0.14, 1,   270) --[span_478](end_span)

local function SetVignette(alpha)
    [span_479](start_span)local trans = math.clamp(1 - alpha, 0, 1) --[span_479](end_span)
    [span_480](start_span)VigTop.BackgroundTransparency    = trans --[span_480](end_span)
    [span_481](start_span)VigBottom.BackgroundTransparency = trans --[span_481](end_span)
    [span_482](start_span)VigLeft.BackgroundTransparency   = trans --[span_482](end_span)
    [span_483](start_span)VigRight.BackgroundTransparency  = trans --[span_483](end_span)
end

-- ═══════════════════════════════════════════════════════════
--             ENTITY CONTROL PANEL  (top-right 👁)
-- ═══════════════════════════════════════════════════════════

[span_484](start_span)local EntityToggleBtn = Instance.new("TextButton") --[span_484](end_span)
[span_485](start_span)EntityToggleBtn.Name                    = "EntityToggle" --[span_485](end_span)
[span_486](start_span)EntityToggleBtn.Size                    = UDim2.new(0,42,0,42) --[span_486](end_span)
[span_487](start_span)EntityToggleBtn.AnchorPoint             = Vector2.new(1,0) --[span_487](end_span)
[span_488](start_span)EntityToggleBtn.Position                = UDim2.new(1,-12,0,12) --[span_488](end_span)
[span_489](start_span)EntityToggleBtn.BackgroundColor3        = Color3.fromRGB(20,20,20) --[span_489](end_span)
[span_490](start_span)EntityToggleBtn.BackgroundTransparency  = 0.25 --[span_490](end_span)
[span_491](start_span)EntityToggleBtn.Text                    = "👁" --[span_491](end_span)
[span_492](start_span)EntityToggleBtn.Font                    = Enum.Font.GothamBold --[span_492](end_span)
[span_493](start_span)EntityToggleBtn.TextSize                = 22 --[span_493](end_span)
[span_494](start_span)EntityToggleBtn.TextColor3              = Color3.fromRGB(255,215,0) --[span_494](end_span)
[span_495](start_span)EntityToggleBtn.BorderSizePixel         = 0 --[span_495](end_span)
[span_496](start_span)EntityToggleBtn.ZIndex                  = 20 --[span_496](end_span)
[span_497](start_span)EntityToggleBtn.Parent                  = ScreenGui --[span_497](end_span)
[span_498](start_span)Instance.new("UICorner", EntityToggleBtn).CornerRadius = UDim.new(0,8) --[span_498](end_span)

[span_499](start_span)local EntityPanel = Instance.new("Frame") --[span_499](end_span)
[span_500](start_span)EntityPanel.Name                    = "EntityPanel" --[span_500](end_span)
[span_501](start_span)EntityPanel.Size                    = UDim2.new(0,260,0,364)  -- fixed: 44 title + 320 scroll view[span_501](end_span)
[span_502](start_span)EntityPanel.AnchorPoint             = Vector2.new(1,0) --[span_502](end_span)
[span_503](start_span)EntityPanel.Position                = UDim2.new(1,-12,0,62) --[span_503](end_span)
[span_504](start_span)EntityPanel.BackgroundColor3        = Color3.fromRGB(10,10,10) --[span_504](end_span)
[span_505](start_span)EntityPanel.BackgroundTransparency  = 0.1 --[span_505](end_span)
[span_506](start_span)EntityPanel.BorderSizePixel         = 0 --[span_506](end_span)
[span_507](start_span)EntityPanel.Visible                 = false --[span_507](end_span)
[span_508](start_span)EntityPanel.ZIndex                  = 20 --[span_508](end_span)
[span_509](start_span)EntityPanel.ClipsDescendants        = true --[span_509](end_span)
[span_510](start_span)EntityPanel.Parent                  = ScreenGui --[span_510](end_span)
[span_511](start_span)Instance.new("UICorner", EntityPanel).CornerRadius = UDim.new(0,12) --[span_511](end_span)

[span_512](start_span)local PanelTitle = Instance.new("TextLabel") --[span_512](end_span)
[span_513](start_span)PanelTitle.Size                   = UDim2.new(1,0,0,40) --[span_513](end_span)
[span_514](start_span)PanelTitle.BackgroundColor3       = Color3.fromRGB(255,215,0) --[span_514](end_span)
[span_515](start_span)PanelTitle.BackgroundTransparency = 0 --[span_515](end_span)
[span_516](start_span)PanelTitle.Text                   = "  ENTITIES" --[span_516](end_span)
[span_517](start_span)PanelTitle.Font                   = Enum.Font.GothamBold --[span_517](end_span)
[span_518](start_span)PanelTitle.TextSize               = 16 --[span_518](end_span)
[span_519](start_span)PanelTitle.TextColor3             = Color3.fromRGB(10,10,10) --[span_519](end_span)
[span_520](start_span)PanelTitle.TextXAlignment         = Enum.TextXAlignment.Left --[span_520](end_span)
[span_521](start_span)PanelTitle.BorderSizePixel        = 0 --[span_521](end_span)
[span_522](start_span)PanelTitle.ZIndex                 = 21 --[span_522](end_span)
[span_523](start_span)PanelTitle.Parent                 = EntityPanel --[span_523](end_span)
[span_524](start_span)Instance.new("UICorner", PanelTitle).CornerRadius = UDim.new(0,12) --[span_524](end_span)

[span_525](start_span)local TitleFix = Instance.new("Frame") --[span_525](end_span)
[span_526](start_span)TitleFix.Size                     = UDim2.new(1,0,0,14) --[span_526](end_span)
[span_527](start_span)TitleFix.Position                 = UDim2.new(0,0,1,-14) --[span_527](end_span)
[span_528](start_span)TitleFix.BackgroundColor3         = Color3.fromRGB(255,215,0) --[span_528](end_span)
[span_529](start_span)TitleFix.BorderSizePixel          = 0 --[span_529](end_span)
[span_530](start_span)TitleFix.ZIndex                   = 22 --[span_530](end_span)
[span_531](start_span)TitleFix.Parent                   = PanelTitle --[span_531](end_span)

[span_532](start_span)local EntityScroll = Instance.new("ScrollingFrame") --[span_532](end_span)
[span_533](start_span)EntityScroll.Name                   = "EntityScroll" --[span_533](end_span)
[span_534](start_span)EntityScroll.Size                   = UDim2.new(1,0,1,-44) --[span_534](end_span)
[span_535](start_span)EntityScroll.Position               = UDim2.new(0,0,0,44) --[span_535](end_span)
[span_536](start_span)EntityScroll.BackgroundTransparency = 1 --[span_536](end_span)
[span_537](start_span)EntityScroll.BorderSizePixel        = 0 --[span_537](end_span)
[span_538](start_span)EntityScroll.ScrollBarThickness     = 5   -- thicker for mobile finger use[span_538](end_span)
[span_539](start_span)EntityScroll.ScrollBarImageColor3   = Color3.fromRGB(255,215,0) --[span_539](end_span)
[span_540](start_span)EntityScroll.ScrollingEnabled       = true --[span_540](end_span)
[span_541](start_span)EntityScroll.ElasticBehavior        = Enum.ElasticBehavior.Always  -- mobile rubber-band[span_541](end_span)
[span_542](start_span)EntityScroll.ScrollingDirection     = Enum.ScrollingDirection.Y --[span_542](end_span)
[span_543](start_span)EntityScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right --[span_543](end_span)
[span_544](start_span)EntityScroll.ZIndex                 = 21 --[span_544](end_span)
[span_545](start_span)EntityScroll.CanvasSize             = UDim2.new(0,0,0,0) --[span_545](end_span)
[span_546](start_span)EntityScroll.Parent                 = EntityPanel --[span_546](end_span)

[span_547](start_span)local EntityList = Instance.new("UIListLayout") --[span_547](end_span)
[span_548](start_span)EntityList.SortOrder = Enum.SortOrder.LayoutOrder --[span_548](end_span)
[span_549](start_span)EntityList.Padding   = UDim.new(0,6) --[span_549](end_span)
[span_550](start_span)EntityList.Parent    = EntityScroll --[span_550](end_span)

[span_551](start_span)local EntityPad = Instance.new("UIPadding") --[span_551](end_span)
[span_552](start_span)EntityPad.PaddingTop   = UDim.new(0,8) --[span_552](end_span)
[span_553](start_span)EntityPad.PaddingLeft  = UDim.new(0,10) --[span_553](end_span)
[span_554](start_span)EntityPad.PaddingRight = UDim.new(0,10) --[span_554](end_span)
[span_555](start_span)EntityPad.Parent       = EntityScroll --[span_555](end_span)

[span_556](start_span)EntityList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() --[span_556](end_span)
    -[span_557](start_span)- Only update canvas height so the scroll frame knows how far to scroll.[span_557](end_span)
    -[span_558](start_span)- Panel height is fixed (364px) — no auto-resize needed.[span_558](end_span)
    [span_559](start_span)local h = EntityList.AbsoluteContentSize.Y + 20 --[span_559](end_span)
    [span_560](start_span)EntityScroll.CanvasSize = UDim2.new(0,0,0,h) --[span_560](end_span)
end)

[span_561](start_span)local panelOpen = false --[span_561](end_span)
[span_562](start_span)EntityToggleBtn.MouseButton1Click:Connect(function() --[span_562](end_span)
    [span_563](start_span)panelOpen = not panelOpen --[span_563](end_span)
    [span_564](start_span)EntityPanel.Visible = panelOpen --[span_564](end_span)
    if panelOpen then
        [span_565](start_span)EntityToggleBtn.TextColor3       = Color3.fromRGB(30,30,30) --[span_565](end_span)
        [span_566](start_span)EntityToggleBtn.BackgroundColor3 = Color3.fromRGB(255,215,0) --[span_566](end_span)
    else
        [span_567](start_span)EntityToggleBtn.TextColor3       = Color3.fromRGB(255,215,0) --[span_567](end_span)
        [span_568](start_span)EntityToggleBtn.BackgroundColor3 = Color3.fromRGB(20,20,20) --[span_568](end_span)
    end
end)

-- ═══════════════════════════════════════════════════════════
--             ENTITY REGISTRY FRAMEWORK
-- ═══════════════════════════════════════════════════════════
local EntityRegistry = {}

local function RegisterEntity(name, symbolizes, desc, onEnable, onDisable)
    local row = Instance.new("Frame")
    row.Name                   = name.."_Row"
    row.Size                   = UDim2.new(1,0,0,72)
    row.BackgroundColor3       = Color3.fromRGB(20,20,20)
    row.BackgroundTransparency = 0.3
    row.BorderSizePixel        = 0
    row.ZIndex                 = 22
    row.Parent                 = EntityScroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)

    local function lbl(txt, font, sz, col, pos, size, wrap)
        local l = Instance.new("TextLabel")
        l.Size                   = size
        l.Position               = pos
        l.BackgroundTransparency = 1
        l.Text                   = txt
        l.Font                   = font
        l.TextSize               = sz
        l.TextColor3             = col
        l.TextXAlignment         = Enum.TextXAlignment.Left
        l.ZIndex                 = 23
        l.TextWrapped            = wrap or false
        l.Parent                 = row
        return l
    end

    lbl(name:upper(),              Enum.Font.GothamBold, 14, Color3.fromRGB(255,215,0),  UDim2.new(0,10,0,6),  UDim2.new(1,-62,0,20))
    lbl("Symbolizes: "..symbolizes, Enum.Font.Gotham,    11, Color3.fromRGB(160,130,60), UDim2.new(0,10,0,28), UDim2.new(1,-62,0,16))
    lbl(desc,                      Enum.Font.Gotham,     10, Color3.fromRGB(150,150,150),UDim2.new(0,10,0,44), UDim2.new(1,-62,0,24), true)

    local tb = Instance.new("TextButton")
    tb.Size             = UDim2.new(0,46,0,24)
    tb.AnchorPoint      = Vector2.new(1,0.5)
    tb.Position         = UDim2.new(1,-8,0.5,0)
    tb.BackgroundColor3 = Color3.fromRGB(180,60,60)
    tb.Text             = "OFF"
    tb.Font             = Enum.Font.GothamBold
    tb.TextSize         = 11
    tb.TextColor3       = Color3.fromRGB(255,255,255)
    tb.BorderSizePixel  = 0
    tb.ZIndex           = 24
    tb.Parent           = row
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0,6)

    local entry = { name=name, enabled=false, onEnable=onEnable, onDisable=onDisable }
    EntityRegistry[name] = entry

    tb.MouseButton1Click:Connect(function()
        entry.enabled = not entry.enabled
        if entry.enabled then
            tb.Text = "ON"
            tb.BackgroundColor3 = Color3.fromRGB(60,180,60)
            if onEnable then pcall(onEnable) end
        else
            tb.Text = "OFF"
            tb.BackgroundColor3 = Color3.fromRGB(180,60,60)
            if onDisable then pcall(onDisable) end
        end
    end)

    return entry
end

-- ═══════════════════════════════════════════════════════════
--           ENTITY: GAZE  (Symbolizes: Envy)
-- ═══════════════════════════════════════════════════════════
--[[
    ▸ Every 5s → 35% chance: random player gets eye billboard on head
    ▸ 60% bias toward same-team friends
    ▸ Look at it (FOV + raycast, walls block, target head doesn't):
        → -5% fate/s while looking
    ▸ Eye disappears after 15s → 5s cooldown → cycle repeats
    ▸ Red screen tint + "you see it." while draining
--]]

local Gaze = {
    active   = false,  target  = nil,  eyeBB      = nil,
    conn     = nil,    draining= false, spawnTick  = 0,
    cdTick   = 0,      CD      = 5,    EYE_DUR    = 15,
}

local GazeTint = Instance.new("Frame")
GazeTint.Name = "GazeTint"
GazeTint.Size = UDim2.new(1,0,1,0)
GazeTint.BackgroundColor3 = Color3.fromRGB(180,0,0)
GazeTint.BackgroundTransparency = 1; GazeTint.ZIndex = 7; GazeTint.Parent = ScreenGui

local GazeWarn = Instance.new("TextLabel")
GazeWarn.Name = "GazeWarn"
GazeWarn.Size = UDim2.new(0,300,0,28)
GazeWarn.AnchorPoint = Vector2.new(0.5,1); GazeWarn.Position = UDim2.new(0.5,0,1,-80)
GazeWarn.BackgroundTransparency = 1; GazeWarn.Text = "you see it."
GazeWarn.Font = Enum.Font.GothamBold
GazeWarn.TextSize = 18
GazeWarn.TextColor3 = Color3.fromRGB(255,80,80); GazeWarn.TextTransparency = 1
GazeWarn.ZIndex = 12
GazeWarn.Parent = ScreenGui

local function BuildEyeBB(tp)
    local char = tp.Character
    if not char then return nil end
    local h = char:FindFirstChild("Head")
    if not h then return nil end
    local bb = Instance.new("BillboardGui")
    bb.Name = "GazeEye"
    bb.Size = UDim2.new(0,80,0,80)
    bb.StudsOffset = Vector3.new(0,0.5,0); bb.AlwaysOnTop = false
    bb.Adornee = h
    bb.Parent = h
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(1,0,1,0)
    ring.BackgroundColor3 = Color3.fromRGB(255,40,40)
    ring.BackgroundTransparency = 0.05; ring.BorderSizePixel = 0
    ring.Parent = bb
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1,0)
    local iris = Instance.new("Frame")
    iris.Size = UDim2.new(0.55,0,0.55,0)
    iris.AnchorPoint = Vector2.new(0.5,0.5)
    iris.Position = UDim2.new(0.5,0,0.5,0); iris.BackgroundColor3 = Color3.fromRGB(15,0,0)
    iris.BorderSizePixel = 0
    iris.Parent = bb
    Instance.new("UICorner", iris).CornerRadius = UDim.new(1,0)
    local pupil = Instance.new("Frame")
    pupil.Size = UDim2.new(0.28,0,0.28,0)
    pupil.AnchorPoint = Vector2.new(0.5,0.5)
    pupil.Position = UDim2.new(0.5,0,0.5,0); pupil.BackgroundColor3 = Color3.fromRGB(0,0,0)
    pupil.BorderSizePixel = 0
    pupil.Parent = bb
    Instance.new("UICorner", pupil).CornerRadius = UDim.new(1,0)
    TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundColor3 = Color3.fromRGB(255,140,0)}):Play()
    return bb
end

local function GazeLookCheck(tp)
    local char = tp.Character
    if not char then return false end
    local h = char:FindFirstChild("Head")
    if not h then return false end
    local camCF = Camera.CFrame
    local camPos = camCF.Position
    local toEye = h.Position - camPos
    local dist = toEye.Magnitude
    if camCF.LookVector:Dot(toEye.Unit) < 0.7 then return false end
    local excl = {}
    if Character then table.insert(excl, Character) end
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "Head" then table.insert(excl, p) end
    end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = excl
    local hit = Workspace:Raycast(camPos, toEye.Unit * (dist - 0.3), rp)
    return hit == nil or hit.Instance == h
end

local function GazePickTarget()
    local fr, ot = {}, {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if p.Team == LocalPlayer.Team then table.insert(fr, p) else table.insert(ot, p) end
        end
    end
    local pool = (#fr > 0 and math.random() < 0.6) and fr or (#ot > 0 and ot) or (#fr > 0 and fr) or nil
    return pool and pool[math.random(1, #pool)] or nil
end

local function GazeClear()
    if Gaze.eyeBB then Gaze.eyeBB:Destroy()
        Gaze.eyeBB = nil 
    end
    Gaze.target = nil; Gaze.draining = false
    RemoveFateDrain("Gaze")
    TweenService:Create(GazeTint, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
    TweenService:Create(GazeWarn, TweenInfo.new(0.5), {TextTransparency=1}):Play()
end

local function GazeTrySpawn()
    if not Gaze.active or math.random() > 0.35 then return end
    local t = GazePickTarget()
    if not t then return end
    if Gaze.eyeBB then Gaze.eyeBB:Destroy() end
    Gaze.target = t
    Gaze.eyeBB = BuildEyeBB(t); Gaze.spawnTick = tick()
end

local function OnGazeEnable()
    Gaze.active = true
    Gaze.cdTick = tick()
    Gaze.conn = RunService.Heartbeat:Connect(function()
        if not Gaze.active then return end
        local now = tick()
        if Gaze.target then
            if now - Gaze.spawnTick >= Gaze.EYE_DUR then GazeClear(); Gaze.cdTick = now; return end
            if not Gaze.target.Character then GazeClear(); Gaze.cdTick = now; return end
            local looking = GazeLookCheck(Gaze.target)
            if looking ~= Gaze.draining then
                Gaze.draining = looking
                if looking then
                    AddFateDrain("Gaze", 5)
                    TweenService:Create(GazeTint, TweenInfo.new(0.3), {BackgroundTransparency=0.72}):Play()
                    TweenService:Create(GazeWarn, TweenInfo.new(0.2), {TextTransparency=0}):Play()
                else
                    RemoveFateDrain("Gaze")
                    TweenService:Create(GazeTint, TweenInfo.new(0.6), {BackgroundTransparency=1}):Play()
                    TweenService:Create(GazeWarn, TweenInfo.new(0.4), {TextTransparency=1}):Play()
                end
            end
        else
            if now - Gaze.cdTick >= Gaze.CD then Gaze.cdTick = now
                GazeTrySpawn() 
            end
        end
    end)
end

local function OnGazeDisable()
    Gaze.active = false
    if Gaze.conn then Gaze.conn:Disconnect()
        Gaze.conn = nil 
    end
    GazeClear()
end

RegisterEntity("Gaze","Envy",
    "You look at your friends. 3 years. They changed. You didn't. You hate it.",
    OnGazeEnable, OnGazeDisable)

-- ═══════════════════════════════════════════════════════════
--          ENTITY: ELUDE  (Symbolizes: Paranoia)  v3
-- ═══════════════════════════════════════════════════════════

local Elude = {
    active          = false,
    conn            = nil,
    switchTimer     = 0,
    SWITCH_INT      = 5,
    model           = nil,
    currentPos      = nil,
    dmgCooldown     = false,
    dmgCooldownTime = 2,
    dmgCDTimer      = 0,
}

local EludeHint = Instance.new("TextLabel")
EludeHint.Name = "EludeHint"
EludeHint.Size = UDim2.new(0,260,0,22)
EludeHint.AnchorPoint = Vector2.new(0,1); EludeHint.Position = UDim2.new(0,16,1,-70)
EludeHint.BackgroundTransparency = 1; EludeHint.Text = ""
EludeHint.Font = Enum.Font.Gotham
EludeHint.TextSize = 13
EludeHint.TextColor3 = Color3.fromRGB(100,200,200)
EludeHint.TextXAlignment = Enum.TextXAlignment.Left
EludeHint.TextTransparency = 1; EludeHint.ZIndex = 12; EludeHint.Parent = ScreenGui

local EludeFlicker = Instance.new("Frame")
EludeFlicker.Name = "EludeFlicker"
EludeFlicker.Size = UDim2.new(1,0,1,0)
EludeFlicker.BackgroundColor3 = Color3.fromRGB(0,80,80)
EludeFlicker.BackgroundTransparency = 1; EludeFlicker.ZIndex = 6
EludeFlicker.Parent = ScreenGui

local ELUDE_HINTS = {
    "did you hear that?","something moved.","you're being watched.",
    "don't look behind you.","it's somewhere close.","accept it.",
    "there's no safe direction.","your skin is crawling.","it already knows.",
    "you heard it again.","stop looking for it.","it never left.",
}

local function EludeFlash(hint, col)
    col = col or Color3.fromRGB(0,80,80)
    EludeFlicker.BackgroundColor3 = col
    TweenService:Create(EludeFlicker, TweenInfo.new(0.07), {BackgroundTransparency=0.86}):Play()
    task.delay(0.4, function()
        TweenService:Create(EludeFlicker, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
    end)
    if hint then
        EludeHint.Text = hint
        TweenService:Create(EludeHint, TweenInfo.new(0.3), {TextTransparency=0}):Play()
        task.delay(3.5, function()
            TweenService:Create(EludeHint, TweenInfo.new(1), {TextTransparency=1}):Play()
        end)
    end
end

local function BuildEludeModel()
    local m = Instance.new("Model")
    m.Name = "Elude_Entity"
    local DC = Color3.fromRGB(6,6,10)
    local function mkP(nm, sz, tr)
        local p = Instance.new("Part")
        p.Name=nm
        p.Size=sz; p.Anchored=true; p.CanCollide=false
        p.CastShadow=false; p.Material=Enum.Material.SmoothPlastic
        p.Color=DC
        p.Transparency=tr; p.Parent=m; return p
    end
    local torso = mkP("Torso",    Vector3.new(1.8,2,0.8),   0.12)
    mkP("Head",     Vector3.new(0.9,0.9,0.9), 0.12)
    mkP("LeftArm",  Vector3.new(0.8,1.8,0.8), 0.22)
    mkP("RightArm", Vector3.new(0.8,1.8,0.8), 0.22)
    mkP("LeftLeg",  Vector3.new(0.8,1.8,0.8), 0.22)
    mkP("RightLeg", Vector3.new(0.8,1.8,0.8), 0.22)
    m.PrimaryPart = torso
    
    local hd = m:FindFirstChild("Head")
    if hd then
        local eyeBB = Instance.new("BillboardGui")
        eyeBB.Size = UDim2.new(0,44,0,16); eyeBB.StudsOffset = Vector3.new(0,0,0.47)
        eyeBB.AlwaysOnTop = false
        eyeBB.Adornee = hd; eyeBB.Parent = hd
        local function mkEye(ax)
            local e = Instance.new("Frame")
            e.Size = UDim2.new(0.36,0,0.52,0)
            e.AnchorPoint = Vector2.new(ax,0.5)
            e.Position = UDim2.new(ax==0 and 0.06 or 0.94, 0, 0.5, 0)
            e.BackgroundColor3 = Color3.fromRGB(0,220,200)
            e.BorderSizePixel=0; e.Parent=eyeBB
            Instance.new("UICorner",e).CornerRadius = UDim.new(1,0)
            TweenService:Create(e, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {BackgroundColor3=Color3.fromRGB(0,100,90)}):Play()
        end
        mkEye(0)
        mkEye(1)
    end
    m.Parent = Workspace
    return m
end

local function PlaceElude(model, cf)
    local offsets = {
        Torso=CFrame.new(0,0,0), Head=CFrame.new(0,1.45,0),
        LeftArm=CFrame.new(-1.3,0,0), RightArm=CFrame.new(1.3,0,0),
        LeftLeg=CFrame.new(-0.5,-1.9,0), RightLeg=CFrame.new(0.5,-1.9,0),
    }
    for name, off in pairs(offsets) do
        local p = model:FindFirstChild(name)
        if p then p.CFrame = cf * off end
    end
end

local function EludeOutsideCameraView(pos)
    local camCF  = Camera.CFrame
    local camPos = camCF.Position
    local toPos  = pos - camPos
    local dist   = toPos.Magnitude
    if camCF.LookVector:Dot(toPos.Unit) < 0.34 then return true end
    local excl = {Character}
    if Elude.model then table.insert(excl, Elude.model) end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = excl
    local hit = Workspace:Raycast(camPos, toPos.Unit * (dist - 0.4), rp)
    return hit ~= nil
end

local function FindEludeSpot(tries)
    local hrp = HumanoidRootPart
    if not hrp then return nil end
    tries = tries or 32
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {Character}

    for _ = 1, tries do
        local angle = math.random() * math.pi * 2
        local dist  = 12 + math.random() * 88
        local dir   = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local sampleXZ = hrp.Position + dir * dist

        local downOrigin = sampleXZ + Vector3.new(0, 60, 0)
        local downHit    = Workspace:Raycast(downOrigin, Vector3.new(0, -120, 0), rp)
        if not downHit then continue end

        local groundPos = downHit.Position + Vector3.new(0, 1.2, 0)

        local openSides = 0
        local checkDirs = {
            Vector3.new(1,0,0), Vector3.new(-1,0,0),
            Vector3.new(0,0,1), Vector3.new(0,0,-1),
        }
        for _, cd in ipairs(checkDirs) do
            local sideHit = Workspace:Raycast(groundPos, cd * 1.2, rp)
            if not sideHit then openSides = openSides + 1 end
        end
        if openSides < 2 then continue end

        if not EludeOutsideCameraView(groundPos) then continue end
        return groundPos
    end
    return nil
end

local function EludeVisibleFromCam(pos)
    local camCF  = Camera.CFrame
    local camPos = camCF.Position
    local toE    = pos - camPos
    local dist = toE.Magnitude
    if camCF.LookVector:Dot(toE.Unit) < 0.45 then return false end
    local excl = {Character}
    if Elude.model then table.insert(excl, Elude.model) end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = excl
    local hit = Workspace:Raycast(camPos, toE.Unit * (dist - 0.4), rp)
    return hit == nil
end

local function EludeTeleport()
    if not Elude.active then return end
    local spot = FindEludeSpot(32)
    if not spot then return end
    Elude.currentPos = spot
    local hrp = HumanoidRootPart
    local floatY = math.sin(tick() * 1.8) * 0.12
    local faceCF
    if hrp then
        faceCF = CFrame.new(spot + Vector3.new(0, floatY, 0),
                            Vector3.new(hrp.Position.X, spot.Y + floatY, hrp.Position.Z))
    else
        faceCF = CFrame.new(spot + Vector3.new(0, floatY, 0))
    end
    if not Elude.model then Elude.model = BuildEludeModel() end
    PlaceElude(Elude.model, faceCF)
    EludeFlash(ELUDE_HINTS[math.random(1, #ELUDE_HINTS)])
end

local function OnEludeEnable()
    Elude.active       = true
    Elude.switchTimer  = 0
    Elude.dmgCooldown  = false
    Elude.dmgCDTimer   = 0
    task.delay(0.8, function()
        if Elude.active then task.spawn(EludeTeleport) end
    end)

    Elude.conn = RunService.Heartbeat:Connect(function(dt)
        if not Elude.active then return end
        local hrp = HumanoidRootPart; if not hrp then return end

        if Elude.dmgCooldown then
            Elude.dmgCDTimer = Elude.dmgCDTimer - dt
            if Elude.dmgCDTimer <= 0 then Elude.dmgCooldown = false end
        end

        Elude.switchTimer = Elude.switchTimer + dt
        if Elude.switchTimer >= Elude.SWITCH_INT then
            Elude.switchTimer = 0
            task.spawn(EludeTeleport)
        end

        if Elude.model and Elude.currentPos then
            local sp    = Elude.currentPos
            local floatY = math.sin(tick() * 1.8) * 0.12
            local faceCF = CFrame.new(
                sp + Vector3.new(0, floatY, 0),
                Vector3.new(hrp.Position.X, sp.Y + floatY, hrp.Position.Z)
            )
            PlaceElude(Elude.model, faceCF)
        end

        if not Elude.dmgCooldown and Elude.currentPos then
            local checkPos = Elude.currentPos + Vector3.new(0,1.5,0)
            if EludeVisibleFromCam(checkPos) then
                Elude.dmgCooldown = true
                Elude.dmgCDTimer = Elude.dmgCooldownTime
                TagDeathCause("Elude")
                InstantFateDamage(25)
                EludeFlash(nil, Color3.fromRGB(180,190,255))
                task.delay(0.12, function()
                    EludeFlicker.BackgroundColor3 = Color3.fromRGB(0,80,80)
                end)
                EludeHint.Text = "Accept it."
                TweenService:Create(EludeHint, TweenInfo.new(0.15), {TextTransparency=0}):Play()
                task.delay(2.2, function()
                    TweenService:Create(EludeHint, TweenInfo.new(1), {TextTransparency=1}):Play()
                end)
                task.spawn(EludeTeleport)
            end
        end
    end)
end

local function OnEludeDisable()
    Elude.active = false
    if Elude.conn then Elude.conn:Disconnect()
        Elude.conn = nil 
    end
    if Elude.model then Elude.model:Destroy()
        Elude.model = nil 
    end
    Elude.currentPos = nil
    TweenService:Create(EludeHint,    TweenInfo.new(0.4), {TextTransparency=1}):Play()
    TweenService:Create(EludeFlicker, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
end

RegisterEntity("Elude","Paranoia",
    "Did you hear that? Every step frightening. Every open field watched. Accept it.",
    OnEludeEnable, OnEludeDisable)

-- ═══════════════════════════════════════════════════════════
--           ENTITY: NUMB  (Symbolizes: Wrath)
-- ═══════════════════════════════════════════════════════════

local Numb = {
    active      = false,
    conn        = nil,
    cycleTimer  = 0,
    CYCLE_INT   = 10,
    inEvent     = false,
    bloodParts  = {},
    shakeConn   = nil,
}

local OrigLighting = {
    Ambient        = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogColor       = Lighting.FogColor,
    FogStart       = Lighting.FogStart,
    FogEnd         = Lighting.FogEnd,
    Brightness     = Lighting.Brightness,
}

local NumbOverlay = Instance.new("Frame")
NumbOverlay.Name = "NumbOverlay"
NumbOverlay.Size = UDim2.new(1,0,1,0)
NumbOverlay.BackgroundColor3 = Color3.fromRGB(80,0,0)
NumbOverlay.BackgroundTransparency = 1; NumbOverlay.ZIndex = 5
NumbOverlay.Parent = ScreenGui

local NumbText = Instance.new("TextLabel")
NumbText.Name = "NumbText"; NumbText.Size = UDim2.new(0,340,0,30)
NumbText.AnchorPoint = Vector2.new(0.5,1)
NumbText.Position = UDim2.new(0.5,0,1,-50)
NumbText.BackgroundTransparency = 1; NumbText.Text = "find cover."
NumbText.Font = Enum.Font.GothamBold; NumbText.TextSize = 20
NumbText.TextColor3 = Color3.fromRGB(200,40,40)
NumbText.TextTransparency = 1
NumbText.ZIndex = 13; NumbText.Parent = ScreenGui

local NumbShakeFlicker = Instance.new("Frame")
NumbShakeFlicker.Name = "NumbShake"
NumbShakeFlicker.Size = UDim2.new(1,0,1,0)
NumbShakeFlicker.BackgroundColor3 = Color3.fromRGB(120,0,0)
NumbShakeFlicker.BackgroundTransparency = 1; NumbShakeFlicker.ZIndex = 9
NumbShakeFlicker.Parent = ScreenGui

local function PlayerHasCover()
    local hrp = HumanoidRootPart
    if not hrp then return false end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {Character}
    local hit = Workspace:Raycast(hrp.Position + Vector3.new(0,1,0), Vector3.new(0,40,0), rp)
    return hit ~= nil
end

local function SpawnBloodDrop(heavy)
    local hrp = HumanoidRootPart
    if not hrp then return end
    local spread = heavy and 30 or 18
    local spawnX = hrp.Position.X + (math.random() * spread*2 - spread)
    local spawnZ = hrp.Position.Z + (math.random() * spread*2 - spread)
    local spawnY = hrp.Position.Y + 35 + math.random() * 10

    local drop = Instance.new("Part")
    drop.Name        = "BloodDrop"
    drop.Size        = heavy and Vector3.new(0.18,0.6,0.18) or Vector3.new(0.12,0.4,0.12)
    drop.Color       = Color3.fromRGB(120 + math.random()*30, 0, 0)
    drop.Material    = Enum.Material.SmoothPlastic
    drop.Anchored    = false
    drop.CanCollide  = false
    drop.CastShadow  = false
    drop.Transparency = 0.1
    drop.CFrame      = CFrame.new(spawnX, spawnY, spawnZ)
    drop.Parent      = Workspace

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(
        math.random()*2 - 1,
        heavy and -(55 + math.random()*15) or -(35 + math.random()*10),
        math.random()*2 - 1
    )
    bv.MaxForce = Vector3.new(0, 9e8, 0)
    bv.P        = 9e8
    bv.Parent   = drop

    table.insert(Numb.bloodParts, drop)
    task.delay(3, function()
        if drop and drop.Parent then drop:Destroy() end
    end)
end

local bloodSpawnConn = nil
local function StartBloodRain(heavy)
    if bloodSpawnConn then bloodSpawnConn:Disconnect() end
    local interval = heavy and 0.05 or 0.12
    local spawnTimer = 0
    bloodSpawnConn = RunService.Heartbeat:Connect(function(dt)
        spawnTimer = spawnTimer + dt
        if spawnTimer >= interval then
            spawnTimer = 0
            SpawnBloodDrop(heavy)
            if heavy then SpawnBloodDrop(true) end
        end
    end)
end

local function StopBloodRain()
    if bloodSpawnConn then bloodSpawnConn:Disconnect()
        bloodSpawnConn = nil 
    end
    for _, p in ipairs(Numb.bloodParts) do
        if p and p.Parent then p:Destroy() end
    end
    Numb.bloodParts = {}
end

local function RestoreLighting()
    TweenService:Create(Lighting, TweenInfo.new(1.5), {
        Ambient        = OrigLighting.Ambient,
        OutdoorAmbient = OrigLighting.OutdoorAmbient,
        FogColor       = OrigLighting.FogColor,
        FogStart       = OrigLighting.FogStart,
        FogEnd         = OrigLighting.FogEnd,
        Brightness     = OrigLighting.Brightness,
    }):Play()
end

local function StopScreenShake()
    if Numb.shakeConn then Numb.shakeConn:Disconnect()
        Numb.shakeConn = nil 
    end
    Camera.CFrame = Camera.CFrame 
end

local function StartScreenShake(intensity)
    if Numb.shakeConn then Numb.shakeConn:Disconnect() end
    local t = 0
    Numb.shakeConn = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        local ox = math.sin(t * 40)  * intensity
        local oy = math.cos(t * 53)  * intensity * 0.6
        local oz = math.sin(t * 31)  * intensity * 0.4
        Camera.CFrame = Camera.CFrame * CFrame.new(ox, oy, oz)
    end)
end

local function TriggerNumbEvent()
    if Numb.inEvent then return end
    Numb.inEvent = true

    TweenService:Create(Lighting, TweenInfo.new(1.2), {
        Ambient        = Color3.fromRGB(60, 0, 0),
        OutdoorAmbient = Color3.fromRGB(80, 10, 10),
        FogColor       = Color3.fromRGB(120, 0, 0),
        FogStart       = 80,
        FogEnd         = 300,
        Brightness     = 0.4,
    }):Play()
    TweenService:Create(NumbOverlay, TweenInfo.new(1), {BackgroundTransparency=0.82}):Play()

    NumbText.Text = "find cover."
    TweenService:Create(NumbText, TweenInfo.new(0.5), {TextTransparency=0}):Play()
    StartBloodRain(false)
    StartScreenShake(0.04)

    task.delay(5, function()
        if not Numb.inEvent then return end
        TweenService:Create(Lighting, TweenInfo.new(0.3), {
            FogStart = 10,
            FogEnd   = 30,
            Ambient  = Color3.fromRGB(80, 0, 0),
        }):Play()
        TweenService:Create(NumbOverlay, TweenInfo.new(0.2), {BackgroundTransparency=0.65}):Play()
        StartBloodRain(true)
        StartScreenShake(0.22)
        NumbText.Text = "No mercy."
        TweenService:Create(NumbText, TweenInfo.new(0.1), {TextTransparency=0}):Play()

        local flickTimer = 0
        local flickConn
        flickConn = RunService.Heartbeat:Connect(function(dt)
            flickTimer = flickTimer + dt
            if flickTimer >= 0.08 then
                flickTimer = 0
                NumbShakeFlicker.BackgroundTransparency =
                    NumbShakeFlicker.BackgroundTransparency < 0.9 and 1 or 0.82
            end
        end)

        task.delay(2, function()
            if flickConn then flickConn:Disconnect() end
            NumbShakeFlicker.BackgroundTransparency = 1
            StopScreenShake()
            StopBloodRain()

            if not PlayerHasCover() then
                TagDeathCause("Numb")
                ModifyFate(-100)
                if Humanoid then Humanoid.Health = 0 end
                NumbText.Text = "you didn't hide."
                NumbText.TextColor3 = Color3.fromRGB(255,255,255)
                TweenService:Create(NumbText, TweenInfo.new(0.1), {TextTransparency=0}):Play()
                task.delay(2.5, function()
                    NumbText.TextColor3 = Color3.fromRGB(200,40,40)
                    TweenService:Create(NumbText, TweenInfo.new(1), {TextTransparency=1}):Play()
                end)
            else
                NumbText.Text = "it's gone."
                TweenService:Create(NumbText, TweenInfo.new(0.4), {TextTransparency=0}):Play()
                task.delay(2, function()
                    TweenService:Create(NumbText, TweenInfo.new(1), {TextTransparency=1}):Play()
                end)
            end

            RestoreLighting()
            TweenService:Create(NumbOverlay, TweenInfo.new(2), {BackgroundTransparency=1}):Play()
            task.delay(2, function()
                Numb.inEvent = false
            end)
        end)
    end)
end

local function OnNumbEnable()
    Numb.active     = true
    Numb.cycleTimer = Numb.CYCLE_INT

    Numb.conn = RunService.Heartbeat:Connect(function(dt)
        if not Numb.active or Numb.inEvent then return end
        Numb.cycleTimer = Numb.cycleTimer - dt
        if Numb.cycleTimer <= 0 then
            Numb.cycleTimer = Numb.CYCLE_INT
            if math.random() <= 0.30 then
                task.spawn(TriggerNumbEvent)
            end
        end
    end)
end

local function OnNumbDisable()
    Numb.active = false
    if Numb.conn then Numb.conn:Disconnect()
        Numb.conn = nil 
    end
    StopBloodRain()
    StopScreenShake()
    if Numb.inEvent then
        Numb.inEvent = false
        RestoreLighting()
        TweenService:Create(NumbOverlay,      TweenInfo.new(0.8), {BackgroundTransparency=1}):Play()
        TweenService:Create(NumbText,         TweenInfo.new(0.4), {TextTransparency=1}):Play()
        TweenService:Create(NumbShakeFlicker, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
    end
end

RegisterEntity("Numb","Wrath",
    "I hate him. I want to choke him. I woke with blood on my hands. It felt... relieving.",
    OnNumbEnable, OnNumbDisable)

-- ═══════════════════════════════════════════════════════════
--         ENTITY: MOUTHFEED  (Symbolizes: Recklessness)
-- ═══════════════════════════════════════════════════════════

local Mouthfeed = {
    active       = false,
    conn         = nil,
    part         = nil,
    billboard    = nil,
    jawFrame     = nil,
    velocity     = Vector3.new(0,0,0),
    spawnPos     = nil,
    dmgCooldown  = false,
    dmgCDTimer   = 0,
    DMG_CD       = 1.5,
    SPRING_K     = 1.8,
    DAMPING      = 0.18,
    DRIFT_FORCE  = 0.35,
    MAX_SPEED    = 22,
}

local MouthPulse = Instance.new("Frame")
MouthPulse.Name                   = "MouthPulse"
MouthPulse.Size                   = UDim2.new(1,0,1,0)
MouthPulse.BackgroundColor3       = Color3.fromRGB(60,20,60)
MouthPulse.BackgroundTransparency = 1
MouthPulse.ZIndex                 = 5
MouthPulse.Parent                 = ScreenGui

local MouthWarn = Instance.new("TextLabel")
MouthWarn.Name                   = "MouthWarn"
MouthWarn.Size                   = UDim2.new(0,300,0,26)
MouthWarn.AnchorPoint            = Vector2.new(0.5,1)
MouthWarn.Position               = UDim2.new(0.5,0,1,-110)
MouthWarn.BackgroundTransparency = 1
MouthWarn.Text                   = "it bit you."
MouthWarn.Font                   = Enum.Font.GothamBold
MouthWarn.TextSize               = 16
MouthWarn.TextColor3             = Color3.fromRGB(200,80,200)
MouthWarn.TextTransparency       = 1
MouthWarn.ZIndex                 = 12
MouthWarn.Parent                 = ScreenGui

local function BuildMouthBillboard(anchorPart)
    local bb = Instance.new("BillboardGui")
    bb.Name         = "MouthfeedBB"
    bb.Size         = UDim2.new(0, 180, 0, 120)
    bb.StudsOffset  = Vector3.new(0, 0, 0)
    bb.AlwaysOnTop  = true
    bb.Adornee      = anchorPart
    bb.Parent       = anchorPart

    local face = Instance.new("Frame")
    face.Name             = "Face"
    face.Size             = UDim2.new(1,0,1,0)
    face.BackgroundColor3 = Color3.fromRGB(18,8,18)
    face.BackgroundTransparency = 0.05
    face.BorderSizePixel  = 0
    face.Parent           = bb
    Instance.new("UICorner", face).CornerRadius = UDim.new(0.4,0)

    local upperLip = Instance.new("Frame")
    upperLip.Name             = "UpperLip"
    upperLip.Size             = UDim2.new(0.82,0,0.28,0)
    upperLip.AnchorPoint      = Vector2.new(0.5,1)
    upperLip.Position         = UDim2.new(0.5,0,0.52,0)
    upperLip.BackgroundColor3 = Color3.fromRGB(160,40,60)
    upperLip.BorderSizePixel  = 0
    upperLip.Parent           = bb
    Instance.new("UICorner", upperLip).CornerRadius = UDim.new(0.5,0)

    local lowerJaw = Instance.new("Frame")
    lowerJaw.Name             = "LowerJaw"
    lowerJaw.Size             = UDim2.new(0.82,0,0.28,0)
    lowerJaw.AnchorPoint      = Vector2.new(0.5,0)
    lowerJaw.Position         = UDim2.new(0.5,0,0.52,0)
    lowerJaw.BackgroundColor3 = Color3.fromRGB(160,40,60)
    lowerJaw.BorderSizePixel  = 0
    lowerJaw.Parent           = bb
    Instance.new("UICorner", lowerJaw).CornerRadius = UDim.new(0.5,0)

    local cavity = Instance.new("Frame")
    cavity.Name             = "Cavity"
    cavity.Size             = UDim2.new(0.74,0,0.20,0)
    cavity.AnchorPoint      = Vector2.new(0.5,0.5)
    cavity.Position         = UDim2.new(0.5,0,0.52,0)
    cavity.BackgroundColor3 = Color3.fromRGB(4,0,4)
    cavity.BorderSizePixel  = 0
    cavity.ZIndex           = 2
    cavity.Parent           = bb
    Instance.new("UICorner", cavity).CornerRadius = UDim.new(0.4,0)

    for i = 1, 5 do
        local tooth = Instance.new("Frame")
        tooth.Size             = UDim2.new(0.10,0,0.16,0)
        tooth.AnchorPoint      = Vector2.new(0.5,1)
        tooth.Position         = UDim2.new(0.12 + (i-1)*0.18, 0, 0.52, 0)
        tooth.BackgroundColor3 = Color3.fromRGB(235,230,220)
        tooth.BorderSizePixel  = 0
        tooth.ZIndex           = 3
        tooth.Parent           = bb
        Instance.new("UICorner", tooth).CornerRadius = UDim.new(0,3)
    end

    for i = 1, 5 do
        local tooth = Instance.new("Frame")
        tooth.Name             = "LowerTooth"..i
        tooth.Size             = UDim2.new(0.10,0,0.16,0)
        tooth.AnchorPoint      = Vector2.new(0.5,0)
        tooth.Position         = UDim2.new(0.12 + (i-1)*0.18, 0, 0.52, 0)
        tooth.BackgroundColor3 = Color3.fromRGB(220,215,205)
        tooth.BorderSizePixel  = 0
        tooth.ZIndex           = 3
        tooth.Parent           = bb
        Instance.new("UICorner", tooth).CornerRadius = UDim.new(0,3)
    end

    local tongue = Instance.new("Frame")
    tongue.Size             = UDim2.new(0.44,0,0.14,0)
    tongue.AnchorPoint      = Vector2.new(0.5,1)
    tongue.Position         = UDim2.new(0.5,0,0.68,0)
    tongue.BackgroundColor3 = Color3.fromRGB(180,50,70)
    tongue.BorderSizePixel  = 0
    tongue.ZIndex           = 2
    tongue.Parent           = bb
    Instance.new("UICorner", tongue).CornerRadius = UDim.new(0.5,0)

    TweenService:Create(tongue,
        TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundColor3 = Color3.fromRGB(200,40,60)}
    ):Play()

    local drool = Instance.new("Frame")
    drool.Size             = UDim2.new(0.04,0,0.22,0)
    drool.AnchorPoint      = Vector2.new(0.5,0)
    drool.Position         = UDim2.new(0.5,0,0.68,0)
    drool.BackgroundColor3 = Color3.fromRGB(120,30,50)
    drool.BackgroundTransparency = 0.4
    drool.BorderSizePixel  = 0
    drool.ZIndex           = 2
    drool.Parent           = bb
    Instance.new("UICorner", drool).CornerRadius = UDim.new(0.5,0)

    TweenService:Create(drool,
        TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
        {Size = UDim2.new(0.04,0,0.35,0)}
    ):Play()

    return bb, lowerJaw, cavity
end

local function UpdateJawOpenAmount(lowerJaw, cavity, openPct)
    openPct = math.clamp(openPct, 0, 1)
    lowerJaw.Position = UDim2.new(0.5, 0, 0.52 + openPct * 0.26, 0)
    cavity.Size = UDim2.new(0.74, 0, 0.08 + openPct * 0.28, 0)
end

local function OnMouthfeedEnable()
    Mouthfeed.active    = true
    Mouthfeed.dmgCooldown  = false
    Mouthfeed.dmgCDTimer   = 0

    local hrp = HumanoidRootPart
    local spawnCF = hrp and (hrp.CFrame * CFrame.new(0,2,-15)) or CFrame.new(0,5,0)

    local anchor = Instance.new("Part")
    anchor.Name        = "MouthfeedAnchor"
    anchor.Size        = Vector3.new(1,1,1)
    anchor.Anchored    = true
    anchor.CanCollide  = false
    anchor.CastShadow  = false
    anchor.Transparency = 1
    anchor.CFrame      = spawnCF
    anchor.Parent      = Workspace

    local bb, lowerJaw, cavity = BuildMouthBillboard(anchor)
    Mouthfeed.part      = anchor
    Mouthfeed.billboard = bb
    Mouthfeed.jawFrame  = lowerJaw
    Mouthfeed.cavity    = cavity
    Mouthfeed.velocity  = Vector3.new(0,0,0)

    local pulseRunning = true
    task.spawn(function()
        while pulseRunning and Mouthfeed.active do
            TweenService:Create(MouthPulse, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {BackgroundTransparency=0.93}):Play()
            task.wait(1.4)
            TweenService:Create(MouthPulse, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {BackgroundTransparency=1}):Play()
            task.wait(1.4)
        end
    end)

    local vertTimer = 0

    Mouthfeed.conn = RunService.Heartbeat:Connect(function(dt)
        if not Mouthfeed.active then pulseRunning = false; return end
        local hrpNow = HumanoidRootPart; if not hrpNow then return end

        vertTimer = vertTimer + dt
        local bobY = math.sin(vertTimer * 1.2) * 3.5

        local targetPos = hrpNow.Position + Vector3.new(0, 1 + bobY, 0)
        local pos = Mouthfeed.part.Position
        local diff = targetPos - pos

        local attraction = diff * Mouthfeed.SPRING_K
        local drift = Vector3.new(
            (math.random()*2-1) * Mouthfeed.DRIFT_FORCE,
            0,
            (math.random()*2-1) * Mouthfeed.DRIFT_FORCE
        )

        local damping = -Mouthfeed.velocity * Mouthfeed.DAMPING
        Mouthfeed.velocity = Mouthfeed.velocity + (attraction + damping + drift) * dt

        local speed = Mouthfeed.velocity.Magnitude
        if speed > Mouthfeed.MAX_SPEED then
            Mouthfeed.velocity = Mouthfeed.velocity.Unit * Mouthfeed.MAX_SPEED
        end

        local newPos = pos + Mouthfeed.velocity * dt
        Mouthfeed.part.CFrame = CFrame.new(newPos)

        if Mouthfeed.billboard then
            local camDist = (Camera.CFrame.Position - newPos).Magnitude
            camDist = math.max(camDist, 1)
            local BASE_PX     = 180
            local BASE_PX_H   = 120
            local REF_DIST    = 20
            local scaledW = math.clamp(BASE_PX   * REF_DIST / camDist, 40,  500)
            local scaledH = math.clamp(BASE_PX_H * REF_DIST / camDist, 26,  330)
            Mouthfeed.billboard.Size = UDim2.new(0, scaledW, 0, scaledH)
        end

        local distToPlayer = (newPos - hrpNow.Position).Magnitude
        local openAmt = math.clamp(1 - (distToPlayer - 3) / 22, 0, 1)
        UpdateJawOpenAmount(Mouthfeed.jawFrame, Mouthfeed.cavity, openAmt)

        if Mouthfeed.dmgCooldown then
            Mouthfeed.dmgCDTimer = Mouthfeed.dmgCDTimer - dt
            if Mouthfeed.dmgCDTimer <= 0 then Mouthfeed.dmgCooldown = false end
        end

        if not Mouthfeed.dmgCooldown and distToPlayer < 5 then
            Mouthfeed.dmgCooldown = true
            Mouthfeed.dmgCDTimer  = Mouthfeed.DMG_CD
            TagDeathCause("Mouthfeed")
            InstantFateDamage(30)

            MouthPulse.BackgroundTransparency = 0.72
            TweenService:Create(MouthPulse, TweenInfo.new(0.6), {BackgroundTransparency=1}):Play()

            local awayDir = (newPos - hrpNow.Position)
            if awayDir.Magnitude > 0 then
                Mouthfeed.velocity = awayDir.Unit * (Mouthfeed.MAX_SPEED * 0.9)
            end

            MouthWarn.Text = "it bit you."
            TweenService:Create(MouthWarn, TweenInfo.new(0.15), {TextTransparency=0}):Play()
            task.delay(2, function()
                TweenService:Create(MouthWarn, TweenInfo.new(0.8), {TextTransparency=1}):Play()
            end)
        end
    end)
end

local function OnMouthfeedDisable()
    Mouthfeed.active = false
    if Mouthfeed.conn then Mouthfeed.conn:Disconnect()
        Mouthfeed.conn = nil 
    end
    if Mouthfeed.part then Mouthfeed.part:Destroy()
        Mouthfeed.part = nil 
    end
    Mouthfeed.billboard = nil; Mouthfeed.jawFrame = nil; Mouthfeed.cavity = nil
    TweenService:Create(MouthPulse, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
    TweenService:Create(MouthWarn,  TweenInfo.new(0.3), {TextTransparency=1}):Play()
end

RegisterEntity("Mouthfeed","Recklessness",
    "I left my son in the burning building. I killed my friends driving. But this wouldn't stop me.",
    OnMouthfeedEnable, OnMouthfeedDisable)

-- ═══════════════════════════════════════════════════════════
--           ENTITY: PIECE  (Symbolizes: Injustice Robbing)
-- ═══════════════════════════════════════════════════════════

local Piece = {
    active        = false,
    conn          = nil,
    limbs         = {},
    follower      = nil,
    followerParts = {},
    hudParts      = {},
    chasing       = false,
    chaseSpeed    = 0,
    chaseAccTimer = 0,
    CHASE_ACC_INT = 0.1,
    dmgCooldown   = false,
    dmgCDTimer    = 0,
    DMG_CD        = 1.5,
    pendingReset  = false,
}

local PIECE_LIMB_NAMES = {"Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg"}

local LIMB_ORBIT_OFFSETS = {
    Head     = Vector3.new( 0,   6,  -8),
    Torso    = Vector3.new(-8,   3,   4),
    LeftArm  = Vector3.new( 9,   4,   3),
    RightArm = Vector3.new(-6,   1,  -9),
    LeftLeg  = Vector3.new( 7,  -1,   8),
    RightLeg = Vector3.new(-3,   5,   9),
}

local LIMB_SIZES = {
    Head     = Vector3.new(2,2,2),
    Torso    = Vector3.new(2,2,1),
    LeftArm  = Vector3.new(1,2,1),
    RightArm = Vector3.new(1,2,1),
    LeftLeg  = Vector3.new(1,2,1),
    RightLeg = Vector3.new(1,2,1),
}

local PieceHUDFrame = Instance.new("Frame")
PieceHUDFrame.Name                   = "PieceHUD"
PieceHUDFrame.Size                   = UDim2.new(0,80,0,120)
PieceHUDFrame.AnchorPoint            = Vector2.new(0,0)
PieceHUDFrame.Position               = UDim2.new(0,12,0,12)
PieceHUDFrame.BackgroundColor3       = Color3.fromRGB(10,10,10)
PieceHUDFrame.BackgroundTransparency = 0.4
PieceHUDFrame.BorderSizePixel        = 0
PieceHUDFrame.Visible                = false
PieceHUDFrame.ZIndex                 = 15
PieceHUDFrame.Parent                 = ScreenGui
Instance.new("UICorner",PieceHUDFrame).CornerRadius = UDim.new(0,8)

local PieceHUDTitle = Instance.new("TextLabel")
PieceHUDTitle.Size                   = UDim2.new(1,0,0,14)
PieceHUDTitle.BackgroundTransparency = 1
PieceHUDTitle.Text                   = "P I E C E"
PieceHUDTitle.Font                   = Enum.Font.GothamBold
PieceHUDTitle.TextSize               = 9
PieceHUDTitle.TextColor3             = Color3.fromRGB(180,180,180)
PieceHUDTitle.ZIndex                 = 16
PieceHUDTitle.Parent                 = PieceHUDFrame

local HUD_PART_LAYOUT = {
    Head     = {x=30, y=15,  w=20, h=20},
    Torso    = {x=22, y=36,  w=36, h=28},
    LeftArm  = {x= 5, y=36,  w=16, h=28},
    RightArm = {x=59, y=36,  w=16, h=28},
    LeftLeg  = {x=22, y=65,  w=16, h=30},
    RightLeg = {x=42, y=65,  w=16, h=30},
}

for _, nm in ipairs(PIECE_LIMB_NAMES) do
    local layout = HUD_PART_LAYOUT[nm]
    local f = Instance.new("Frame")
    f.Name             = "HUD_"..nm
    f.Size             = UDim2.new(0, layout.w, 0, layout.h)
    f.Position         = UDim2.new(0, layout.x, 0, layout.y)
    f.BackgroundColor3 = Color3.fromRGB(160,160,160)
    f.BackgroundTransparency = 1
    f.BorderSizePixel  = 1
    f.BorderColor3     = Color3.fromRGB(80,80,80)
    f.ZIndex           = 16
    f.Parent           = PieceHUDFrame
    if nm == "Head" then
        Instance.new("UICorner", f).CornerRadius = UDim.new(0.2,0)
    end
    Piece.hudParts[nm] = f
end

local PieceWarn = Instance.new("TextLabel")
PieceWarn.Name                   = "PieceWarn"
PieceWarn.Size                   = UDim2.new(0,300,0,24)
PieceWarn.AnchorPoint            = Vector2.new(0.5,1)
PieceWarn.Position               = UDim2.new(0.5,0,1,-140)
PieceWarn.BackgroundTransparency = 1
PieceWarn.Text                   = ""
PieceWarn.Font                   = Enum.Font.GothamBold
PieceWarn.TextSize               = 14
PieceWarn.TextColor3             = Color3.fromRGB(180,180,180)
PieceWarn.TextTransparency       = 1
PieceWarn.ZIndex                 = 12
PieceWarn.Parent                 = ScreenGui

local function PieceShowWarn(txt)
    PieceWarn.Text = txt
    TweenService:Create(PieceWarn, TweenInfo.new(0.2), {TextTransparency=0}):Play()
    task.delay(2.5, function()
        TweenService:Create(PieceWarn, TweenInfo.new(0.8), {TextTransparency=1}):Play()
    end)
end

local function BuildFollowerModel()
    local model = Instance.new("Model")
    model.Name = "PieceFollower"
    local parts = {}
    for _, nm in ipairs(PIECE_LIMB_NAMES) do
        local p = Instance.new("Part")
        p.Name         = nm
        p.Size         = LIMB_SIZES[nm]
        p.Anchored     = true
        p.CanCollide   = false
        p.CastShadow   = false
        p.Material     = Enum.Material.SmoothPlastic
        p.Color        = Color3.fromRGB(160,160,160)
        p.Transparency = 1
        p.Parent       = model
        parts[nm]      = p
    end
    model.PrimaryPart = parts["Torso"]
    model.Parent      = Workspace
    return model, parts
end

local function UpdateFollowerPose(followerParts, baseCF)
    local offsets = {
        Torso    = CFrame.new(0,  0,   0),
        Head     = CFrame.new(0,  1.5, 0),
        LeftArm  = CFrame.new(-1.5, 0, 0),
        RightArm = CFrame.new( 1.5, 0, 0),
        LeftLeg  = CFrame.new(-0.5,-2, 0),
        RightLeg = CFrame.new( 0.5,-2, 0),
    }
    for nm, off in pairs(offsets) do
        if followerParts[nm] then
            followerParts[nm].CFrame = baseCF * off
        end
    end
end

local function BuildFloatingLimbs()
    local hrp = HumanoidRootPart
    local limbs = {}
    for _, nm in ipairs(PIECE_LIMB_NAMES) do
        local offset = LIMB_ORBIT_OFFSETS[nm]
        local startPos = hrp and (hrp.Position + offset) or Vector3.new(0,5,0)
        local p = Instance.new("Part")
        p.Name         = "PieceLimb_"..nm
        p.Size         = LIMB_SIZES[nm]
        p.Anchored     = true
        p.CanCollide   = false
        p.CastShadow   = false
        p.Material     = Enum.Material.SmoothPlastic
        p.Color        = Color3.fromRGB(180,180,180)
        p.Transparency = 0.45
        p.CFrame       = CFrame.new(startPos)
        p.Parent       = Workspace
        table.insert(limbs, {
            name   = nm,
            part   = p,
            stolen = false,
            vel    = Vector3.new(0,0,0),
            spinT  = math.random() * math.pi * 2,
        })
    end
    return limbs
end

local function StealLimb(limbEntry)
    if limbEntry.stolen then return end
    limbEntry.stolen = true

    if limbEntry.part then
        limbEntry.part:Destroy()
        limbEntry.part = nil
    end

    local nm = limbEntry.name
    local hudF = Piece.hudParts[nm]
    if hudF then
        TweenService:Create(hudF, TweenInfo.new(0.3), {BackgroundTransparency=0.2}):Play()
    end

    local fPart = Piece.followerParts[nm]
    if fPart then
        TweenService:Create(fPart, TweenInfo.new(0.4), {Transparency=0.35}):Play()
    end

    PieceShowWarn("you took the "..nm:lower()..".")

    local allStolen = true
    for _, le in ipairs(Piece.limbs) do
        if not le.stolen then allStolen = false; break end
    end

    if allStolen then
        task.delay(0.8, function()
            if not Piece.active then return end
            Piece.chasing      = true
            Piece.chaseSpeed   = 0
            Piece.chaseAccTimer = 0
            PieceShowWarn("Its complete.")
            for _, fp in pairs(Piece.followerParts) do
                TweenService:Create(fp, TweenInfo.new(0.6), {Transparency=0.1, Color=Color3.fromRGB(30,30,30)}):Play()
            end
        end)
    end
end

local function PieceHardReset()
    if Piece.conn then Piece.conn:Disconnect()
        Piece.conn = nil 
    end
    for _, le in ipairs(Piece.limbs) do
        if le.part then le.part:Destroy()
            le.part = nil 
        end
    end
    Piece.limbs = {}
    if Piece.follower then Piece.follower:Destroy()
        Piece.follower = nil 
    end
    Piece.followerParts = {}
    Piece.chasing       = false
    Piece.chaseSpeed    = 0
    Piece.chaseAccTimer = 0
    Piece.dmgCooldown   = false
    Piece.dmgCDTimer    = 0
    Piece.pendingReset  = false
    for _, nm in ipairs(PIECE_LIMB_NAMES) do
        local hf = Piece.hudParts[nm]
        if hf then hf.BackgroundTransparency = 1 end
    end
    task.delay(1.5, function()
        if not Piece.active then return end
        local followerModel, fParts = BuildFollowerModel()
        Piece.follower      = followerModel
        Piece.followerParts = fParts
        Piece.limbs         = BuildFloatingLimbs()
        PieceHUDFrame.Visible = true
        PieceShowWarn("Steal it.")
        OnPieceEnable()
    end)
end

local function OnPieceEnable()
    Piece.active      = true
    Piece.chasing     = false
    Piece.chaseSpeed  = 0
    Piece.dmgCooldown = false
    Piece.dmgCDTimer  = 0
    Piece.limbs = {}

    local followerModel, fParts = BuildFollowerModel()
    Piece.follower      = followerModel
    Piece.followerParts = fParts

    Piece.limbs = BuildFloatingLimbs()
    PieceHUDFrame.Visible = true
    for _, nm in ipairs(PIECE_LIMB_NAMES) do
        local hf = Piece.hudParts[nm]
        if hf then hf.BackgroundTransparency = 1 end
    end

    PieceShowWarn("Steal it.")

    Piece.conn = RunService.Heartbeat:Connect(function(dt)
        if not Piece.active then return end
        local hrp = HumanoidRootPart; if not hrp then return end

        if Piece.dmgCooldown then
            Piece.dmgCDTimer = Piece.dmgCDTimer - dt
            if Piece.dmgCDTimer <= 0 then Piece.dmgCooldown = false end
        end

        for _, le in ipairs(Piece.limbs) do
            if le.stolen or not le.part then continue end
            local p         = le.part
            local curPos    = p.Position
            local targetPos = hrp.Position + LIMB_ORBIT_OFFSETS[le.name]
            local distToTarget = (targetPos - curPos).Magnitude

            local speed = distToTarget > 30 and 100 or 4
            local dir = (targetPos - curPos)
            local dist = dir.Magnitude
            if dist > 0.1 then
                local moveAmt = math.min(speed * dt, dist)
                curPos = curPos + dir.Unit * moveAmt
            end

            le.spinT = le.spinT + dt * 2.2
            p.CFrame = CFrame.new(curPos) * CFrame.Angles(le.spinT, le.spinT * 0.7, 0)

            if (curPos - hrp.Position).Magnitude < 2.5 then
                StealLimb(le)
            end
        end

        if not Piece.chasing then
            local behindCF = hrp.CFrame * CFrame.new(0, 0, 3)
            UpdateFollowerPose(Piece.followerParts, behindCF)
        else
            Piece.chaseAccTimer = Piece.chaseAccTimer + dt
            if Piece.chaseAccTimer >= Piece.CHASE_ACC_INT then
                Piece.chaseAccTimer = 0
                Piece.chaseSpeed    = Piece.chaseSpeed + 1
            end

            local torso = Piece.followerParts["Torso"]
            if torso then
                local curTorsoPos = torso.Position
                local toPlayer    = hrp.Position - curTorsoPos
                local dist2       = toPlayer.Magnitude
                if dist2 > 0.3 then
                    local moveAmt = math.min(Piece.chaseSpeed * dt, dist2)
                    local newTorsoPos = curTorsoPos + toPlayer.Unit * moveAmt
                    local faceCF = CFrame.new(newTorsoPos,
                        Vector3.new(hrp.Position.X, newTorsoPos.Y, hrp.Position.Z))
                    UpdateFollowerPose(Piece.followerParts, faceCF)
                end

                if not Piece.dmgCooldown and (torso.Position - hrp.Position).Magnitude < 3 then
                    Piece.dmgCooldown = true
                    Piece.dmgCDTimer  = Piece.DMG_CD
                    TagDeathCause("Piece")
                    InstantFateDamage(100)
                    PieceShowWarn("Its just a piece of useless object.")
                    Piece.pendingReset = true
                end
            end
        end
    end)
end

local function OnPieceDisable()
    Piece.active  = false
    Piece.chasing = false
    if Piece.conn then Piece.conn:Disconnect()
        Piece.conn = nil 
    end
    for _, le in ipairs(Piece.limbs) do
        if le.part then le.part:Destroy()
            le.part = nil 
        end
    end
    Piece.limbs = {}
    if Piece.follower then Piece.follower:Destroy()
        Piece.follower = nil 
    end
    Piece.followerParts = {}
    PieceHUDFrame.Visible = false
    TweenService:Create(PieceWarn, TweenInfo.new(0.3), {TextTransparency=1}):Play()
end

RegisterEntity("Piece","Injustice Robbing",
    "Why waste money on a useless object? Steal it. Get it. Hide it. It's just a piece anyway.",
    OnPieceEnable, OnPieceDisable)


-- ═══════════════════════════════════════════════════════════
--        ENTITY: DELICTUM  (Symbolizes: Past Mistakes)
-- ═══════════════════════════════════════════════════════════

local Delictum = {
    active         = false,
    recordConn     = nil,
    shadowConn     = nil,
    currentRecord  = {},
    recordTimer    = 0,
    RECORD_INTERVAL = 0.05,
    shadows        = {},
    MAX_SHADOWS    = 8,
    dmgCooldown    = false,
    dmgCDTimer     = 0,
    DMG_CD         = 2,
}

local DelictumWarn = Instance.new("TextLabel")
DelictumWarn.Name                   = "DelictumWarn"
DelictumWarn.Size                   = UDim2.new(0,300,0,24)
DelictumWarn.AnchorPoint            = Vector2.new(0.5,1)
DelictumWarn.Position               = UDim2.new(0.5,0,1,-158)
DelictumWarn.BackgroundTransparency = 1
DelictumWarn.Text                   = ""
DelictumWarn.Font                   = Enum.Font.GothamBold
DelictumWarn.TextSize               = 14
DelictumWarn.TextColor3             = Color3.fromRGB(160,120,200)
DelictumWarn.TextTransparency       = 1
DelictumWarn.ZIndex                 = 12
DelictumWarn.Parent                 = ScreenGui

local DelictumTint = Instance.new("Frame")
DelictumTint.Size                   = UDim2.new(1,0,1,0)
DelictumTint.BackgroundColor3       = Color3.fromRGB(80,0,120)
DelictumTint.BackgroundTransparency = 1
DelictumTint.ZIndex                 = 7
DelictumTint.Parent                 = ScreenGui

local function DelictumShowWarn(txt)
    DelictumWarn.Text = txt
    TweenService:Create(DelictumWarn, TweenInfo.new(0.2), {TextTransparency=0}):Play()
    task.delay(2.5, function()
        TweenService:Create(DelictumWarn, TweenInfo.new(0.8), {TextTransparency=1}):Play()
    end)
end

local function BuildShadowModel()
    local m = Instance.new("Model")
    m.Name = "Delictum_Shadow_"..tostring(tick())
    local shadowCol = Color3.fromRGB(30, 10, 50)
    local function mkP(nm, sz)
        local p = Instance.new("Part")
        p.Name = nm; p.Size = sz; p.Anchored = true
        p.CanCollide = false; p.CastShadow = false
        p.Material = Enum.Material.SmoothPlastic
        p.Color = shadowCol; p.Transparency = 0.45
        p.Parent = m; return p
    end
    local torso = mkP("Torso",    Vector3.new(2,2,1))
    mkP("Head",     Vector3.new(1,1,1))
    mkP("LeftArm",  Vector3.new(1,2,1))
    mkP("RightArm", Vector3.new(1,2,1))
    mkP("LeftLeg",  Vector3.new(1,2,1))
    mkP("RightLeg", Vector3.new(1,2,1))
    m.PrimaryPart = torso

    local hd = m:FindFirstChild("Head")
    if hd then
        local eyeBB = Instance.new("BillboardGui")
        eyeBB.Size = UDim2.new(0,30,0,10); eyeBB.StudsOffset = Vector3.new(0,0,0.52)
        eyeBB.AlwaysOnTop = false; eyeBB.Adornee = hd; eyeBB.Parent = hd
        local function mkEye(ax)
            local e = Instance.new("Frame")
            e.Size = UDim2.new(0.35,0,0.7,0); e.AnchorPoint = Vector2.new(ax,0.5)
            e.Position = UDim2.new(ax==0 and 0.08 or 0.92, 0, 0.5, 0)
            e.BackgroundColor3 = Color3.fromRGB(160,80,255)
            e.BorderSizePixel = 0; e.Parent = eyeBB
            Instance.new("UICorner",e).CornerRadius = UDim.new(1,0)
            TweenService:Create(e, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,-1,true),
                {BackgroundColor3=Color3.fromRGB(80,20,140)}):Play()
        end
        mkEye(0); mkEye(1)
    end

    m.Parent = Workspace
    local parts = {}
    for _, p in ipairs(m:GetChildren()) do
        if p:IsA("BasePart") then parts[p.Name] = p end
    end
    return m, parts
end

local function PlaceShadowAt(shadowParts, cf)
    local offsets = {
        Torso    = CFrame.new(0, 0,  0),
        Head     = CFrame.new(0, 1.5,  0),
        LeftArm  = CFrame.new(-1.5, 0, 0),
        RightArm = CFrame.new( 1.5, 0, 0),
        LeftLeg  = CFrame.new(-0.5,-2, 0),
        RightLeg = CFrame.new( 0.5,-2, 0),
    }
    for nm, off in pairs(offsets) do
        if shadowParts[nm] then shadowParts[nm].CFrame = cf * off end
    end
end

local function SpawnShadowFromRecording(frames)
    if #frames < 2 then return end
    if #Delictum.shadows >= Delictum.MAX_SHADOWS then
        local oldest = table.remove(Delictum.shadows, 1)
        if oldest.model then oldest.model:Destroy() end
    end

    local model, parts = BuildShadowModel()
    local shadow = {
        frames = frames,
        index  = 1,
        model  = model,
        parts  = parts,
        timer  = 0,
        STEP   = 0.05,
    }
    table.insert(Delictum.shadows, shadow)
    PlaceShadowAt(parts, frames[1])
end

local function DelictumOnDeath()
    if not Delictum.active then return end
    local frames = Delictum.currentRecord
    Delictum.currentRecord = {}

    if #frames < 2 then return end
    task.delay(2, function()
        if not Delictum.active then return end
        SpawnShadowFromRecording(frames)
        DelictumShowWarn("mistakes don't disappear.")
    end)
end

local function OnDelictumEnable()
    Delictum.active        = true
    Delictum.currentRecord = {}
    Delictum.recordTimer   = 0
    Delictum.dmgCooldown   = false
    Delictum.dmgCDTimer    = 0

    Delictum.recordConn = RunService.Heartbeat:Connect(function(dt)
        if not Delictum.active then return end
        local hrp = HumanoidRootPart; if not hrp then return end

        Delictum.recordTimer = Delictum.recordTimer + dt
        if Delictum.recordTimer >= Delictum.RECORD_INTERVAL then
            Delictum.recordTimer = 0
            table.insert(Delictum.currentRecord, hrp.CFrame)
            if #Delictum.currentRecord > 24000 then
                table.remove(Delictum.currentRecord, 1)
            end
        end

        for _, shadow in ipairs(Delictum.shadows) do
            if not shadow.model or not shadow.model.Parent then continue end
            shadow.timer = shadow.timer + dt
            if shadow.timer >= shadow.STEP then
                shadow.timer = 0
                shadow.index = shadow.index + 1
                if shadow.index > #shadow.frames then
                    shadow.index = 1
                end
                PlaceShadowAt(shadow.parts, shadow.frames[shadow.index])
            end
        end

        if Delictum.dmgCooldown then
            Delictum.dmgCDTimer = Delictum.dmgCDTimer - dt
            if Delictum.dmgCDTimer <= 0 then Delictum.dmgCooldown = false end
        end

        if not Delictum.dmgCooldown and HumanoidRootPart then
            local playerPos = HumanoidRootPart.Position
            for _, shadow in ipairs(Delictum.shadows) do
                if shadow.parts and shadow.parts["Torso"] then
                    local d = (shadow.parts["Torso"].Position - playerPos).Magnitude
                    if d < 3 then
                        Delictum.dmgCooldown = true
                        Delictum.dmgCDTimer  = Delictum.DMG_CD
                        TagDeathCause("Delictum")
                        InstantFateDamage(45)
                        TweenService:Create(DelictumTint, TweenInfo.new(0.15), {BackgroundTransparency=0.75}):Play()
                        task.delay(0.3, function()
                            TweenService:Create(DelictumTint, TweenInfo.new(0.7), {BackgroundTransparency=1}):Play()
                        end)
                        DelictumShowWarn("that was you.")
                        break
                    end
                end
            end
        end
    end)
end

local function OnDelictumDisable()
    Delictum.active = false
    if Delictum.recordConn then Delictum.recordConn:Disconnect()
        Delictum.recordConn = nil 
    end
    for _, shadow in ipairs(Delictum.shadows) do
        if shadow.model then shadow.model:Destroy() end
    end
    Delictum.shadows       = {}
    Delictum.currentRecord = {}
    TweenService:Create(DelictumWarn, TweenInfo.new(0.3), {TextTransparency=1}):Play()
    TweenService:Create(DelictumTint, TweenInfo.new(0.3), {BackgroundTransparency=1}):Play()
end

RegisterEntity("Delictum","Past Mistakes",
    "Every mistake, every scar I left in the past... it affects the future. What else can I do?",
    OnDelictumEnable, OnDelictumDisable)


-- ═══════════════════════════════════════════════════════════
--          ENTITY: NORM  (Symbolizes: Self Pleasure)
-- ═══════════════════════════════════════════════════════════

local Norm = {
    active        = false,
    conn          = nil,
    cycleTimer    = 0,
    cycleInterval = 0,
    inCountdown   = false,
    countdownNum  = 5,
    countdownTimer = 0,
    blockingActive = false,
    blockPart      = nil,
    blockTimer    = 0,
    BLOCK_DUR      = 5,
    dmgCooldown    = false,
    dmgCDTimer     = 0,
    DMG_CD         = 2,
}

local NormEyeFrame = Instance.new("Frame")
NormEyeFrame.Name                   = "NormEyeFrame"
NormEyeFrame.Size                   = UDim2.new(0, 140, 0, 140)
NormEyeFrame.AnchorPoint            = Vector2.new(0.5, 0.5)
NormEyeFrame.Position               = UDim2.new(0.5, 0, 0.5, 0)
NormEyeFrame.BackgroundTransparency = 1
NormEyeFrame.Visible                = false
NormEyeFrame.ZIndex                 = 30
NormEyeFrame.Parent                 = ScreenGui 

local NormEyeWhite = Instance.new("Frame")
NormEyeWhite.Name             = "EyeWhite"
NormEyeWhite.Size             = UDim2.new(1, 0, 0.6, 0)
NormEyeWhite.AnchorPoint      = Vector2.new(0.5, 0.5)
NormEyeWhite.Position         = UDim2.new(0.5, 0, 0.5, 0)
NormEyeWhite.BackgroundColor3 = Color3.fromRGB(245, 240, 235)
NormEyeWhite.BorderSizePixel  = 0
NormEyeWhite.ZIndex           = 31
NormEyeWhite.Parent           = NormEyeFrame
Instance.new("UICorner", NormEyeWhite).CornerRadius = UDim.new(1, 0)

local NormIris = Instance.new("Frame")
NormIris.Name             = "Iris"
NormIris.Size             = UDim2.new(0.48, 0, 0.48, 0)
NormIris.AnchorPoint      = Vector2.new(0.5, 0.5)
NormIris.Position         = UDim2.new(0.5, 0, 0.5, 0)
NormIris.BackgroundColor3 = Color3.fromRGB(140, 80, 20)
NormIris.BorderSizePixel  = 0
NormIris.ZIndex           = 32
NormIris.Parent           = NormEyeFrame
Instance.new("UICorner", NormIris).CornerRadius = UDim.new(1, 0)

local NormPupil = Instance.new("Frame")
NormPupil.Name             = "Pupil"
NormPupil.Size             = UDim2.new(0.55, 0, 0.55, 0)
NormPupil.AnchorPoint      = Vector2.new(0.5, 0.5)
NormPupil.Position         = UDim2.new(0.5, 0, 0.5, 0)
NormPupil.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
NormPupil.BorderSizePixel  = 0
NormPupil.ZIndex           = 33
NormPupil.Parent           = NormIris
Instance.new("UICorner", NormPupil).CornerRadius = UDim.new(1, 0)

local NormCountLabel = Instance.new("TextLabel")
NormCountLabel.Size                   = UDim2.new(1, 0, 1, 0)
NormCountLabel.BackgroundTransparency = 1
NormCountLabel.Text                   = "5"
NormCountLabel.Font                   = Enum.Font.GothamBold
NormCountLabel.TextSize               = 36
NormCountLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
NormCountLabel.ZIndex                 = 34
NormCountLabel.Parent                 = NormPupil

local NormSubLabel = Instance.new("TextLabel")
NormSubLabel.Name                   = "NormSub"
NormSubLabel.Size                   = UDim2.new(0, 220, 0, 22)
NormSubLabel.AnchorPoint            = Vector2.new(0.5, 0)
NormSubLabel.Position               = UDim2.new(0.5, 0, 1, 10)
NormSubLabel.BackgroundTransparency = 1
NormSubLabel.Text                   = "Feels great isn't it?"
NormSubLabel.Font                   = Enum.Font.Gotham
NormSubLabel.TextSize               = 14
NormSubLabel.TextColor3             = Color3.fromRGB(200, 180, 140)
NormSubLabel.TextTransparency       = 1
NormSubLabel.ZIndex                 = 34
NormSubLabel.Parent                 = NormEyeFrame

local function BuildBlockingEye()
    local part = Instance.new("Part")
    part.Name        = "NormBlockingEye"
    part.Size        = Vector3.new(1, 1, 1)
    part.Anchored    = true
    part.CanCollide  = false
    part.CastShadow  = false
    part.Transparency = 1
    part.Parent      = Workspace

    local bb = Instance.new("BillboardGui")
    bb.Name         = "NormBlockBB"
    bb.Size         = UDim2.new(0, 260, 0, 180)
    bb.AlwaysOnTop  = false
    bb.Adornee      = part
    bb.Parent       = part

    local eWhite = Instance.new("Frame")
    eWhite.Size             = UDim2.new(1, 0, 0.55, 0)
    eWhite.AnchorPoint      = Vector2.new(0.5, 0.5)
    eWhite.Position         = UDim2.new(0.5, 0, 0.58, 0)
    eWhite.BackgroundColor3 = Color3.fromRGB(248, 244, 240)
    eWhite.BorderSizePixel  = 0
    eWhite.Parent           = bb
    Instance.new("UICorner", eWhite).CornerRadius = UDim.new(1, 0)

    local topLid = Instance.new("Frame")
    topLid.Size             = UDim2.new(1.08, 0, 0.38, 0)
    topLid.AnchorPoint      = Vector2.new(0.5, 1)
    topLid.Position         = UDim2.new(0.5, 0, 0.32, 0)
    topLid.BackgroundColor3 = Color3.fromRGB(18, 10, 18)
    topLid.BorderSizePixel  = 0
    topLid.ZIndex           = 2
    topLid.Parent           = bb
    Instance.new("UICorner", topLid).CornerRadius = UDim.new(0.5, 0)

    local botLid = Instance.new("Frame")
    botLid.Size             = UDim2.new(1.08, 0, 0.38, 0)
    botLid.AnchorPoint      = Vector2.new(0.5, 0)
    botLid.Position         = UDim2.new(0.5, 0, 0.75, 0)
    botLid.BackgroundColor3 = Color3.fromRGB(18, 10, 18)
    botLid.BorderSizePixel  = 0
    botLid.ZIndex           = 2
    botLid.Parent           = bb
    Instance.new("UICorner", botLid).CornerRadius = UDim.new(0.5, 0)

    local iris = Instance.new("Frame")
    iris.Size             = UDim2.new(0.34, 0, 0.50, 0)
    iris.AnchorPoint      = Vector2.new(0.5, 0.5)
    iris.Position         = UDim2.new(0.5, 0, 0.58, 0)
    iris.BackgroundColor3 = Color3.fromRGB(160, 100, 30)
    iris.BorderSizePixel  = 0
    iris.ZIndex           = 3
    iris.Parent           = bb
    Instance.new("UICorner", iris).CornerRadius = UDim.new(1, 0)

    local pupil = Instance.new("Frame")
    pupil.Size             = UDim2.new(0.55, 0, 0.55, 0)
    pupil.AnchorPoint      = Vector2.new(0.5, 0.5)
    pupil.Position         = UDim2.new(0.5, 0, 0.5, 0)
    pupil.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
    pupil.BorderSizePixel  = 0
    pupil.ZIndex           = 4
    pupil.Parent           = iris
    Instance.new("UICorner", pupil).CornerRadius = UDim.new(1, 0)

    local glint = Instance.new("Frame")
    glint.Size             = UDim2.new(0.28, 0, 0.28, 0)
    glint.AnchorPoint      = Vector2.new(0, 0)
    glint.Position         = UDim2.new(0.15, 0, 0.1, 0)
    glint.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glint.BackgroundTransparency = 0.2
    glint.BorderSizePixel  = 0
    glint.ZIndex           = 5
    glint.Parent           = pupil
    Instance.new("UICorner", glint).CornerRadius = UDim.new(1, 0)

    TweenService:Create(iris,
        TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundColor3 = Color3.fromRGB(200, 140, 50)}
    ):Play()

    return part, bb
end

local NORM_APPEAR_DIALOGUES = {
    "Jork it crazy style",
    "You know you want it right?",
    "Come here~",
    "Repent to god but you have to jork it",
}
local NORM_TOUCH_DIALOGUES = {
    "Good boy",
    "Do you feel that?",
    "Like the pleasure?",
    "Do it harder",
}

local NormDialogLabel = Instance.new("TextLabel")
NormDialogLabel.Name                   = "NormDialog"
NormDialogLabel.Size                   = UDim2.new(0, 300, 0, 26)
NormDialogLabel.AnchorPoint            = Vector2.new(0.5, 1)
NormDialogLabel.Position               = UDim2.new(0.5, 0, 1, -50)
NormDialogLabel.BackgroundTransparency = 1
NormDialogLabel.Text                   = ""
NormDialogLabel.Font                   = Enum.Font.GothamBold
NormDialogLabel.TextSize               = 15
NormDialogLabel.TextColor3             = Color3.fromRGB(220, 180, 120)
NormDialogLabel.TextTransparency       = 1
NormDialogLabel.ZIndex                 = 35
NormDialogLabel.Parent                 = ScreenGui

local function NormSayDialog(lines)
    local line = lines[math.random(1, #lines)]
    NormDialogLabel.Text = '"' .. line .. '"'
    TweenService:Create(NormDialogLabel, TweenInfo.new(0.25), {TextTransparency=0}):Play()
    task.delay(3, function()
        TweenService:Create(NormDialogLabel, TweenInfo.new(0.8), {TextTransparency=1}):Play()
    end)
end

local function OnNormEnable()
    Norm.active        = true
    Norm.cycleTimer    = 0
    Norm.cycleInterval = 10 + math.random() * 15
    Norm.inCountdown   = false
    Norm.blockingActive = false
    Norm.dmgCooldown   = false
    Norm.dmgCDTimer    = 0

    local shakeX, shakeY = 0, 0
    local shakeIntensity = 0

    Norm.conn = RunService.Heartbeat:Connect(function(dt)
        if not Norm.active then return end
        local hrp = HumanoidRootPart; if not hrp then return end

        if Norm.dmgCooldown then
            Norm.dmgCDTimer = Norm.dmgCDTimer - dt
            if Norm.dmgCDTimer <= 0 then Norm.dmgCooldown = false end
        end

        if not Norm.inCountdown and not Norm.blockingActive then
            Norm.cycleTimer = Norm.cycleTimer + dt
            if Norm.cycleTimer >= Norm.cycleInterval then
                Norm.cycleTimer    = 0
                Norm.cycleInterval = 10 + math.random() * 15
                Norm.inCountdown   = true
                Norm.countdownNum  = 5
                Norm.countdownTimer = 0
                NormEyeFrame.Visible = true
                NormCountLabel.Text  = "5"
                TweenService:Create(NormSubLabel, TweenInfo.new(0.5), {TextTransparency=0}):Play()
                NormSayDialog(NORM_APPEAR_DIALOGUES)
            end
        end

        if Norm.inCountdown then
            Norm.countdownTimer = Norm.countdownTimer + dt
            shakeIntensity = (6 - Norm.countdownNum) * 3.5 + 2

            shakeX = shakeX * 0.7 + (math.random()-0.5) * shakeIntensity * 2
            shakeY = shakeY * 0.7 + (math.random()-0.5) * shakeIntensity * 2
            NormEyeFrame.Position = UDim2.new(0.5, math.floor(shakeX), 0.5, math.floor(shakeY))

            if Norm.countdownTimer >= 1 then
                Norm.countdownTimer = 0
                Norm.countdownNum   = Norm.countdownNum - 1

                if Norm.countdownNum <= 0 then
                    Norm.inCountdown   = false
                    NormEyeFrame.Visible = false
                    NormEyeFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                    TweenService:Create(NormSubLabel, TweenInfo.new(0.3), {TextTransparency=1}):Play()

                    local spawnPos = hrp.Position + hrp.CFrame.LookVector * 8 + Vector3.new(0, 1.5, 0)
                    local bPart, _ = BuildBlockingEye()
                    bPart.CFrame   = CFrame.new(spawnPos)
                    Norm.blockPart  = bPart
                    Norm.blockTimer = 0
                    Norm.blockingActive = true
                else
                    NormCountLabel.Text = tostring(Norm.countdownNum)
                    TweenService:Create(NormPupil,
                        TweenInfo.new(0.08),
                        {BackgroundColor3 = Color3.fromRGB(60, 0, 0)}
                    ):Play()
                    task.delay(0.12, function()
                        TweenService:Create(NormPupil,
                            TweenInfo.new(0.1),
                            {BackgroundColor3 = Color3.fromRGB(5, 5, 5)}
                        ):Play()
                    end)
                end
            end
        end

        if Norm.blockingActive and Norm.blockPart and Norm.blockPart.Parent then
            Norm.blockTimer = Norm.blockTimer + dt

            if Norm.blockTimer >= Norm.BLOCK_DUR then
                Norm.blockPart:Destroy(); Norm.blockPart = nil
                Norm.blockingActive = false
            else
                -- Target spot is 6 studs directly in front of the player
                local targetPos = hrp.Position + hrp.CFrame.LookVector * 6 + Vector3.new(0, 1.5, 0)
                local curPos    = Norm.blockPart.Position
                
                -- Check distance to player to determine speed limit
                local distToPlayer = (curPos - hrp.Position).Magnitude
                local currentSpeed = distToPlayer > 15 and 100 or 13
                
                local diff = targetPos - curPos
                local moveDist = diff.Magnitude
                
                -- Move directly toward the target position at the calculated speed
                if moveDist > 0.1 then
                    local moveAmt = math.min(currentSpeed * dt, moveDist)
                    local newPos = curPos + diff.Unit * moveAmt
                    
                    -- Always snap Y directly so it stays firmly at eye level
                    newPos = Vector3.new(newPos.X, targetPos.Y, newPos.Z)
                    Norm.blockPart.CFrame = CFrame.new(newPos)
                end

                if not Norm.dmgCooldown then
                    local dist = (Norm.blockPart.Position - hrp.Position).Magnitude
                    if dist < 3.5 then
                        Norm.dmgCooldown = true
                        Norm.dmgCDTimer  = Norm.DMG_CD
                        TagDeathCause("Norm")
                        InstantFateDamage(50)
                        NormSayDialog(NORM_TOUCH_DIALOGUES)

                        TweenService:Create(NormEyeWhite,
                            TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}
                        ):Play()
                        task.delay(0.2, function()
                            pcall(function()
                                TweenService:Create(NormEyeWhite,
                                    TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(245,240,235)}
                                ):Play()
                            end)
                        end)
                    end
                end
            end
        end
    end)
end

local function OnNormDisable()
    Norm.active = false
    if Norm.conn then Norm.conn:Disconnect(); Norm.conn = nil end
    NormEyeFrame.Visible = false
    if Norm.blockPart then Norm.blockPart:Destroy(); Norm.blockPart = nil end
    Norm.inCountdown    = false
    Norm.blockingActive = false
    TweenService:Create(NormSubLabel,   TweenInfo.new(0.3), {TextTransparency=1}):Play()
    TweenService:Create(NormDialogLabel, TweenInfo.new(0.3), {TextTransparency=1}):Play()
end

NormEyeFrame.Parent = ScreenGui

RegisterEntity("Norm","Self Pleasure",
    "Feels great isn't it? The warmth. The silence. No one else. Just you and what you want.",
    OnNormEnable, OnNormDisable)

-- ═══════════════════════════════════════════════════════════
--       ENTITY: BLUE SKY  (Symbolizes: Treason)
-- ═══════════════════════════════════════════════════════════

local BlueSky = {
    active        = false,
    conn          = nil,
    cycleTimer    = 0,
    CYCLE_INT     = 180, -- 3 minutes
    inEvent       = false,
    eventTimer    = 0,
    EVENT_DUR     = 15,
    
    flashTimer    = 0,
    flashInterval = 3,
    
    targetPos     = nil,
    targetCircle  = nil,
    crosshair     = nil,
    
    nukeModel     = nil,
    hudElements   = {},
    shakeConn     = nil,
}

-- ── BLUE SKY HACKER HUD (ScreenGui) ─────────────────────────
local BlueSkyHUD = Instance.new("Frame")
BlueSkyHUD.Name                   = "BlueSkyHUD"
BlueSkyHUD.Size                   = UDim2.new(1, 0, 1, 0)
BlueSkyHUD.BackgroundColor3       = Color3.fromRGB(10, 0, 0)
BlueSkyHUD.BackgroundTransparency = 1
BlueSkyHUD.Visible                = false
BlueSkyHUD.ZIndex                 = 40
BlueSkyHUD.Parent                 = ScreenGui

local FlashOverlay = Instance.new("Frame")
FlashOverlay.Name                   = "BlueSkyFlash"
FlashOverlay.Size                   = UDim2.new(1, 0, 1, 0)
FlashOverlay.BackgroundColor3       = Color3.fromRGB(255, 0, 0)
FlashOverlay.BackgroundTransparency = 1
FlashOverlay.ZIndex                 = 45
FlashOverlay.Parent                 = BlueSkyHUD

local HackTitle = Instance.new("TextLabel")
HackTitle.Name                   = "HackTitle"
HackTitle.Size                   = UDim2.new(1, 0, 0, 60)
HackTitle.Position               = UDim2.new(0, 0, 0, 40)
HackTitle.BackgroundTransparency = 1
HackTitle.Text                   = "WARNING: GOVERNMENT MAINFRAME BREACHED"
HackTitle.Font                   = Enum.Font.Code
HackTitle.TextSize               = 28
HackTitle.TextColor3             = Color3.fromRGB(255, 50, 50)
HackTitle.TextTransparency       = 1
HackTitle.ZIndex                 = 41
HackTitle.Parent                 = BlueSkyHUD

local SubTitle = Instance.new("TextLabel")
SubTitle.Size                   = UDim2.new(1, 0, 0, 30)
SubTitle.Position               = UDim2.new(0, 0, 0, 90)
SubTitle.BackgroundTransparency = 1
SubTitle.Text                   = "NUCLEAR LAUNCH PROTOCOL INITIATED"
SubTitle.Font                   = Enum.Font.Code
SubTitle.TextSize               = 18
SubTitle.TextColor3             = Color3.fromRGB(255, 100, 100)
SubTitle.TextTransparency       = 1
SubTitle.ZIndex                 = 41
SubTitle.Parent                 = BlueSkyHUD

-- Generate scrolling binary/hex text for the "hacked" look
local CodeScroll = Instance.new("TextLabel")
CodeScroll.Size                   = UDim2.new(0, 300, 1, -120)
CodeScroll.Position               = UDim2.new(0, 20, 0, 120)
CodeScroll.BackgroundTransparency = 1
CodeScroll.Text                   = ""
CodeScroll.Font                   = Enum.Font.Code
CodeScroll.TextSize               = 12
CodeScroll.TextColor3             = Color3.fromRGB(255, 50, 50)
CodeScroll.TextXAlignment         = Enum.TextXAlignment.Left
CodeScroll.TextYAlignment         = Enum.TextYAlignment.Top
CodeScroll.TextTransparency       = 1
CodeScroll.ZIndex                 = 41
CodeScroll.Parent                 = BlueSkyHUD

local RightCodeScroll = Instance.new("TextLabel")
RightCodeScroll.Size                   = UDim2.new(0, 300, 1, -120)
RightCodeScroll.Position               = UDim2.new(1, -320, 0, 120)
RightCodeScroll.BackgroundTransparency = 1
RightCodeScroll.Text                   = ""
RightCodeScroll.Font                   = Enum.Font.Code
RightCodeScroll.TextSize               = 12
RightCodeScroll.TextColor3             = Color3.fromRGB(255, 50, 50)
RightCodeScroll.TextXAlignment         = Enum.TextXAlignment.Right
RightCodeScroll.TextYAlignment         = Enum.TextYAlignment.Top
RightCodeScroll.TextTransparency       = 1
RightCodeScroll.ZIndex                 = 41
RightCodeScroll.Parent                 = BlueSkyHUD

local TargetLockText = Instance.new("TextLabel")
TargetLockText.Size                   = UDim2.new(0, 400, 0, 40)
TargetLockText.AnchorPoint            = Vector2.new(0.5, 1)
TargetLockText.Position               = UDim2.new(0.5, 0, 1, -40)
TargetLockText.BackgroundTransparency = 1
TargetLockText.Text                   = "LOCKING TARGET..."
TargetLockText.Font                   = Enum.Font.GothamBold
TargetLockText.TextSize               = 24
TargetLockText.TextColor3             = Color3.fromRGB(255, 0, 0)
TargetLockText.TextTransparency       = 1
TargetLockText.ZIndex                 = 41
TargetLockText.Parent                 = BlueSkyHUD

-- ── GENERATORS ───────────────────────────────────────────────

local function GenerateHexLine()
    local str = ""
    for i = 1, 8 do
        local chars = "0123456789ABCDEF"
        local r1 = math.random(1, #chars)
        local r2 = math.random(1, #chars)
        str = str .. "0x" .. chars:sub(r1,r1) .. chars:sub(r2,r2) .. " "
    end
    return str
end

local function BuildESP_Part(name, shape, size, cf, parent)
    local p = Instance.new("Part")
    p.Name = name
    if shape == "Cylinder" then p.Shape = Enum.PartType.Cylinder
    elseif shape == "Ball" then p.Shape = Enum.PartType.Ball
    elseif shape == "Block" then p.Shape = Enum.PartType.Block end
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.CanCollide = false
    p.CastShadow = false
    p.Material = Enum.Material.ForceField -- Gives that see-through holographic/ESP look
    p.Color = Color3.fromRGB(255, 0, 0)
    p.Transparency = 0.2
    p.Parent = parent
    return p
end

local function BuildNukeModel()
    local m = Instance.new("Model")
    m.Name = "BlueSky_Nuke"

    -- Main Body
    local body = BuildESP_Part("Body", "Cylinder", Vector3.new(30, 12, 12), CFrame.new(), m)
    body.CFrame = body.CFrame * CFrame.Angles(0, 0, math.pi/2)
    m.PrimaryPart = body

    -- Nose Cone (Using a Wedge/Block combo or SpecialMesh for simplicity in raw script)
    local nose = BuildESP_Part("Nose", "Block", Vector3.new(10, 12, 12), CFrame.new(), m)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://1033714" -- Standard cone mesh
    mesh.Scale = Vector3.new(6, 10, 6)
    mesh.Parent = nose
    nose.CFrame = body.CFrame * CFrame.new(0, -20, 0) * CFrame.Angles(math.pi, 0, 0)

    -- Tail
    local tail = BuildESP_Part("Tail", "Cylinder", Vector3.new(10, 8, 8), CFrame.new(), m)
    tail.CFrame = body.CFrame * CFrame.new(0, 20, 0)

    -- Fins
    for i = 1, 4 do
        local fin = BuildESP_Part("Fin"..i, "Block", Vector3.new(8, 2, 8), CFrame.new(), m)
        local angle = (math.pi/2) * i
        fin.CFrame = tail.CFrame * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, 5)
    end

    return m
end

local function BuildTargetingCircle(pos)
    local m = Instance.new("Model")
    m.Name = "NukeTargetZone"

    -- The 50-stud red zone
    local zone = BuildESP_Part("Zone", "Cylinder", Vector3.new(0.2, 100, 100), CFrame.new(pos), m)
    zone.CFrame = zone.CFrame * CFrame.Angles(0, 0, math.pi/2)
    zone.Color = Color3.fromRGB(255, 0, 0)
    zone.Transparency = 0.6
    zone.Material = Enum.Material.Neon

    -- Outer rotating ring
    local ring = BuildESP_Part("Ring", "Cylinder", Vector3.new(0.3, 102, 102), CFrame.new(pos), m)
    ring.CFrame = ring.CFrame * CFrame.Angles(0, 0, math.pi/2)
    ring.Color = Color3.fromRGB(255, 50, 50)
    ring.Transparency = 0.4
    ring.Material = Enum.Material.Neon
    
    -- Inner hollow part to make ring (using negate in studio, but we'll use a visual trick here)
    local inner = BuildESP_Part("InnerCut", "Cylinder", Vector3.new(0.4, 98, 98), CFrame.new(pos), m)
    inner.CFrame = inner.CFrame * CFrame.Angles(0, 0, math.pi/2)
    inner.Color = Color3.fromRGB(10, 10, 10) -- Ground color trick or just leave transparent
    inner.Transparency = 1
    
    m.Parent = Workspace
    return m, zone, ring
end

local function ScreenShake(intensity, duration)
    if BlueSky.shakeConn then BlueSky.shakeConn:Disconnect() end
    local t = 0
    BlueSky.shakeConn = RunService.RenderStepped:Connect(function(dt)
        t = t + dt
        if t >= duration then
            BlueSky.shakeConn:Disconnect()
            BlueSky.shakeConn = nil
            Camera.CFrame = Camera.CFrame
            return
        end
        local dropoff = 1 - (t / duration)
        local ox = (math.random() - 0.5) * 2 * intensity * dropoff
        local oy = (math.random() - 0.5) * 2 * intensity * dropoff
        local oz = (math.random() - 0.5) * 2 * intensity * dropoff
        Camera.CFrame = Camera.CFrame * CFrame.Angles(math.rad(ox), math.rad(oy), math.rad(oz))
    end)
end

-- ── EXPLOSION VFX ────────────────────────────────────────────

local function TriggerNuclearExplosion(impactPos)
    -- 1. Blinding Flash
    local blind = Instance.new("ColorCorrectionEffect")
    blind.Brightness = 2
    blind.Contrast = 2
    blind.TintColor = Color3.fromRGB(255, 200, 200)
    blind.Parent = Lighting
    TweenService:Create(blind, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Brightness = 0, Contrast = 0, TintColor = Color3.fromRGB(255, 255, 255)
    }):Play()
    game:GetService("Debris"):AddItem(blind, 3.5)

    -- 2. Core Plasma Sphere
    local core = Instance.new("Part")
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(5, 5, 5)
    core.CFrame = CFrame.new(impactPos)
    core.Anchored = true
    core.CanCollide = false
    core.Material = Enum.Material.Neon
    core.Color = Color3.fromRGB(255, 255, 255)
    core.Parent = Workspace
    
    TweenService:Create(core, TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
        Size = Vector3.new(200, 200, 200),
        Color = Color3.fromRGB(255, 50, 0),
        Transparency = 0.2
    }):Play()

    -- 3. Shockwave Ring
    local shockwave = Instance.new("Part")
    shockwave.Shape = Enum.PartType.Cylinder
    shockwave.Size = Vector3.new(2, 10, 10)
    shockwave.CFrame = CFrame.new(impactPos + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.pi/2)
    shockwave.Anchored = true
    shockwave.CanCollide = false
    shockwave.Material = Enum.Material.Neon
    shockwave.Color = Color3.fromRGB(255, 100, 0)
    shockwave.Parent = Workspace

    TweenService:Create(shockwave, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(2, 400, 400),
        Transparency = 1
    }):Play()

    -- 4. Mushroom Stem
    local stem = Instance.new("Part")
    stem.Shape = Enum.PartType.Cylinder
    stem.Size = Vector3.new(200, 10, 10)
    stem.CFrame = CFrame.new(impactPos + Vector3.new(0, 100, 0)) * CFrame.Angles(0, 0, math.pi/2)
    stem.Anchored = true
    stem.CanCollide = false
    stem.Material = Enum.Material.Neon
    stem.Color = Color3.fromRGB(255, 80, 0)
    stem.Parent = Workspace

    TweenService:Create(stem, TweenInfo.new(4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
        Size = Vector3.new(200, 60, 60),
        Color = Color3.fromRGB(50, 10, 10),
        Transparency = 1
    }):Play()

    -- 5. Extreme Camera Shake
    ScreenShake(15, 6)

    -- Cleanup
    task.delay(1.6, function()
        TweenService:Create(core, TweenInfo.new(2), {Transparency = 1, Size = Vector3.new(250, 250, 250)}):Play()
    end)
    game:GetService("Debris"):AddItem(core, 4)
    game:GetService("Debris"):AddItem(shockwave, 3)
    game:GetService("Debris"):AddItem(stem, 5)
end

-- ── SEQUENCE LOGIC ───────────────────────────────────────────

local function BlueSkyFlashScreen()
    FlashOverlay.BackgroundTransparency = 0.2
    TweenService:Create(FlashOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
end

local function StartBlueSkySequence()
    local hrp = HumanoidRootPart
    if not hrp then return end

    BlueSky.inEvent = true
    BlueSky.eventTimer = 0
    BlueSky.flashTimer = 0
    BlueSky.targetPos = hrp.Position - Vector3.new(0, 2.5, 0) -- Ground level approx

    -- Spawn Target Zone
    local tModel, zone, ring = BuildTargetingCircle(BlueSky.targetPos)
    BlueSky.targetCircle = tModel

    -- Enable HUD
    BlueSkyHUD.Visible = true
    TweenService:Create(BlueSkyHUD, TweenInfo.new(1), {BackgroundTransparency = 0.4}):Play()
    TweenService:Create(HackTitle, TweenInfo.new(1), {TextTransparency = 0}):Play()
    TweenService:Create(SubTitle, TweenInfo.new(1), {TextTransparency = 0}):Play()
    TweenService:Create(CodeScroll, TweenInfo.new(1), {TextTransparency = 0}):Play()
    TweenService:Create(RightCodeScroll, TweenInfo.new(1), {TextTransparency = 0}):Play()
    TweenService:Create(TargetLockText, TweenInfo.new(1), {TextTransparency = 0}):Play()
    
    -- Hacker Dialog
    local function AddChat(txt)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1,0,0,20)
        t.BackgroundTransparency = 1
        t.Text = "> " .. txt
        t.Font = Enum.Font.Code
        t.TextSize = 16
        t.TextColor3 = Color3.fromRGB(255, 255, 255)
        t.TextXAlignment = Enum.TextXAlignment.Center
        t.Parent = BlueSkyHUD
        t.Position = UDim2.new(0, 0, 0, 160 + (#BlueSky.hudElements * 25))
        table.insert(BlueSky.hudElements, t)
    end
    
    AddChat("Ive leaked all of the government Information.")
    task.delay(3, function() AddChat("What else can it be?") end)
    task.delay(6, function() AddChat("Nobody can stop me.") end)
    task.delay(9, function() AddChat("I could even hack the nuke...") end)
    task.delay(12, function() AddChat("...and launch it to your own country.") end)
end

local function ExecuteNukeStrike()
    BlueSkyHUD.Visible = false
    for _, el in ipairs(BlueSky.hudElements) do el:Destroy() end
    BlueSky.hudElements = {}
    
    -- Spawn Nuke in sky
    local spawnPos = BlueSky.targetPos + Vector3.new(0, 250, 0)
    local nuke = BuildNukeModel()
    nuke.Parent = Workspace
    
    -- Orient Nuke facing down
    local primary = nuke.PrimaryPart
    primary.CFrame = CFrame.new(spawnPos, BlueSky.targetPos) * CFrame.Angles(math.pi/2, 0, 0)
    
    -- Drop Tween
    local dropInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
    
    for _, p in ipairs(nuke:GetDescendants()) do
        if p:IsA("BasePart") then
            local targetCFrame = p.CFrame - Vector3.new(0, 250, 0)
            TweenService:Create(p, dropInfo, {CFrame = targetCFrame}):Play()
        end
    end
    
    -- Impact
    task.delay(0.6, function()
        nuke:Destroy()
        if BlueSky.targetCircle then BlueSky.targetCircle:Destroy() end
        
        TriggerNuclearExplosion(BlueSky.targetPos)
        
        -- Damage Calculation (within 50 studs radius = 100 diameter)
        local hrp = HumanoidRootPart
        if hrp then
            local dist = (hrp.Position - BlueSky.targetPos).Magnitude
            -- 50 stud radius
            if dist <= 50 then
                TagDeathCause("Blue Sky")
                InstantFateDamage(100)
            end
        end
        
        task.delay(5, function()
            BlueSky.inEvent = false
            BlueSky.cycleTimer = 0
        end)
    end)
end

local function OnBlueSkyEnable()
    BlueSky.active = true
    BlueSky.cycleTimer = 0
    BlueSky.inEvent = false

    BlueSky.conn = RunService.Heartbeat:Connect(function(dt)
        if not BlueSky.active then return end
        local hrp = HumanoidRootPart; if not hrp then return end

        if not BlueSky.inEvent then
            BlueSky.cycleTimer = BlueSky.cycleTimer + dt
            if BlueSky.cycleTimer >= BlueSky.CYCLE_INT then
                StartBlueSkySequence()
            end
        else
            -- Event is active, handle 15s countdown
            BlueSky.eventTimer = BlueSky.eventTimer + dt
            local elapsed = BlueSky.eventTimer
            
            -- Rotate Target Ring
            if BlueSky.targetCircle then
                local ring = BlueSky.targetCircle:FindFirstChild("Ring")
                if ring then
                    ring.CFrame = ring.CFrame * CFrame.Angles(0, dt * 2, 0)
                end
            end
            
            -- Update HUD Matrix Code
            if math.random() > 0.5 then
                local txt1 = CodeScroll.Text .. "\n" .. GenerateHexLine()
                local txt2 = RightCodeScroll.Text .. "\n" .. GenerateHexLine()
                if #txt1 > 1000 then txt1 = string.sub(txt1, -1000) end
                if #txt2 > 1000 then txt2 = string.sub(txt2, -1000) end
                CodeScroll.Text = txt1
                RightCodeScroll.Text = txt2
            end

            -- Determine Flash Interval based on time elapsed
            if elapsed < 3 then BlueSky.flashInterval = 3
            elseif elapsed < 6 then BlueSky.flashInterval = 2
            elseif elapsed < 9 then BlueSky.flashInterval = 1
            elseif elapsed < 12 then BlueSky.flashInterval = 0.5
            elseif elapsed < 14 then BlueSky.flashInterval = 0.1
            else BlueSky.flashInterval = 0.05 end -- extremely fast

            -- Handle Flashing
            BlueSky.flashTimer = BlueSky.flashTimer + dt
            if BlueSky.flashTimer >= BlueSky.flashInterval then
                BlueSky.flashTimer = 0
                BlueSkyFlashScreen()
                TargetLockText.TextTransparency = TargetLockText.TextTransparency == 1 and 0 or 1
            end

            -- Execute Nuke Drop at 15s
            if elapsed >= BlueSky.EVENT_DUR then
                BlueSky.inEvent = false -- Stop timer
                ExecuteNukeStrike()
            end
        end
    end)
end

local function OnBlueSkyDisable()
    BlueSky.active = false
    if BlueSky.conn then BlueSky.conn:Disconnect(); BlueSky.conn = nil end
    if BlueSky.targetCircle then BlueSky.targetCircle:Destroy(); BlueSky.targetCircle = nil end
    BlueSkyHUD.Visible = false
    BlueSky.inEvent = false
end

RegisterEntity("Blue Sky","Treason",
    "I've leaked all the government information. What else can it be? Nobody can stop me, I could even hack the nuke and launch it.",
    OnBlueSkyEnable, OnBlueSkyDisable)

-- ═══════════════════════════════════════════════════════════
--                    FATE UPDATE LOOP
-- ═══════════════════════════════════════════════════════════
local fateAccum = 0
local FATE_TICK = 0.05

local function SyncFateToHealth()
    if Humanoid and Humanoid.MaxHealth > 0 then
        FateData.current = (Humanoid.Health / Humanoid.MaxHealth) * FateData.max
    end
end

RunService.Heartbeat:Connect(function(dt)
    SyncFateToHealth()
    fateAccum = fateAccum + dt
    if fateAccum < FATE_TICK then return end
    local elapsed = fateAccum
    fateAccum = 0

    local totalDrain = 0
    for _, rate in pairs(FateData.drainRates) do totalDrain = totalDrain + rate end
    if totalDrain ~= 0 then
        ModifyFate(-totalDrain * elapsed)
        if Humanoid and Humanoid.Health > 0 then
            local hp = Humanoid.MaxHealth
            Humanoid.Health = math.clamp(Humanoid.Health - (totalDrain * elapsed / 100) * hp, 0, hp)
        end
    end

    local pct = FateData.current / FateData.max
    local col = GetFateColor(pct)

    FateLabel.TextColor3         = col
    FateGlow.TextColor3          = col
    FateBarFill.BackgroundColor3 = col
    FateBarFill.Size             = UDim2.new(pct, 0, 1, 0)
    FatePct.Text                 = math.floor(pct * 100) .. "%"
    FatePct.TextColor3           = col

    SetVignette(math.clamp((1 - pct) * 1.1, 0, 1))

    if FateData.current <= 0 and not FateData.dead then
        FateData.dead = true
        if not lastDeathCause then
            if FateData.drainRates["Gaze"] and FateData.drainRates["Gaze"] > 0 then
                TagDeathCause("Gaze")
            end
        end
        DeathScreen.Visible = true
        TweenService:Create(DeathScreen, TweenInfo.new(1.5), {BackgroundTransparency=0}):Play()
        TweenService:Create(DeathLabel,  TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 1.5), {TextTransparency=0}):Play()
        if Humanoid then Humanoid.Health = 0 end
    end

    if pct < 0.25 and not FateData.dead then
        local w = (0.25 - pct) / 0.25
        FateLabel.TextTransparency = 0.15 + ((math.sin(tick()*(3+w*5))+1)/2)*0.3
    else
        FateLabel.TextTransparency = 0
    end
end)

-- ═══════════════════════════════════════════════════════════
--                   CHARACTER RESPAWN
-- ═══════════════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(newChar)
    FateData.dead    = false
    FateData.current = 100
    TweenService:Create(DeathScreen, TweenInfo.new(0.8), {BackgroundTransparency=1}):Play()
    TweenService:Create(DeathLabel,  TweenInfo.new(0.4), {TextTransparency=1}):Play()
    task.delay(1, function() DeathScreen.Visible = false end)
    
    if pendingCorpse then
        pcall(function() pendingCorpse:Destroy() end)
        pendingCorpse = nil
    end
    lastDeathCause = nil
    
    task.delay(0.3, function()
        ConnectDeathEffect(newChar)
    end)
    
    if Piece.pendingReset then PieceHardReset() end
    if Delictum.active then DelictumOnDeath() end
end)

-- ═══════════════════════════════════════════════════════════
--                     ATMOSPHERE
-- ═══════════════════════════════════════════════════════════
OrigLighting.Ambient        = Lighting.Ambient
OrigLighting.OutdoorAmbient = Lighting.OutdoorAmbient
OrigLighting.FogColor       = Lighting.FogColor
OrigLighting.FogStart       = Lighting.FogStart
OrigLighting.FogEnd         = Lighting.FogEnd
OrigLighting.Brightness     = Lighting.Brightness

local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not Atmosphere then
    Atmosphere = Instance.new("Atmosphere")
    Atmosphere.Parent = Lighting
end
Atmosphere.Density = 0.3;  Atmosphere.Offset = 0.05
Atmosphere.Color   = Color3.fromRGB(80,80,100)
Atmosphere.Decay   = Color3.fromRGB(50,40,60)
Atmosphere.Glare   = 0
Atmosphere.Haze    = 1.5

local GameCC = Instance.new("ColorCorrectionEffect")
GameCC.Name       = "GraceGameCC"
GameCC.Saturation = -0.2
GameCC.Contrast   = 0.05
GameCC.Brightness = -0.04; GameCC.TintColor = Color3.fromRGB(210,210,230)
GameCC.Parent     = Lighting

-- ═══════════════════════════════════════════════════════════
--                    INTRO SEQUENCE
-- ═══════════════════════════════════════════════════════════
local IntroFrame = Instance.new("Frame")
IntroFrame.Size = UDim2.new(1,0,1,0)
IntroFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
IntroFrame.BackgroundTransparency = 0; IntroFrame.ZIndex = 200; IntroFrame.Parent = ScreenGui

local IntroLabel = Instance.new("TextLabel")
IntroLabel.Size = UDim2.new(1,0,0,50)
IntroLabel.AnchorPoint = Vector2.new(0.5,0.5)
IntroLabel.Position = UDim2.new(0.5,0,0.5,0); IntroLabel.BackgroundTransparency = 1
IntroLabel.Text = "FATE"; IntroLabel.Font = Enum.Font.GothamBold; IntroLabel.TextSize = 52
IntroLabel.TextColor3 = Color3.fromRGB(255,215,0)
IntroLabel.TextTransparency = 1
IntroLabel.ZIndex = 201; IntroLabel.Parent = IntroFrame

local IntroSub = Instance.new("TextLabel")
IntroSub.Size = UDim2.new(1,0,0,26); IntroSub.AnchorPoint = Vector2.new(0.5,0)
IntroSub.Position = UDim2.new(0.5,0,0.5,36)
IntroSub.BackgroundTransparency = 1
IntroSub.Text = "a fanmade grace experience"; IntroSub.Font = Enum.Font.Gotham
IntroSub.TextSize = 15; IntroSub.TextColor3 = Color3.fromRGB(180,180,180)
IntroSub.TextTransparency = 1
IntroSub.ZIndex = 201; IntroSub.Parent = IntroFrame

task.spawn(function()
    task.wait(0.5)
    TweenService:Create(IntroLabel, TweenInfo.new(1.2), {TextTransparency=0}):Play()
    task.wait(0.6)
    TweenService:Create(IntroSub,   TweenInfo.new(1),   {TextTransparency=0}):Play()
    task.wait(2.8)
    TweenService:Create(IntroLabel, TweenInfo.new(1),   {TextTransparency=1}):Play()
    TweenService:Create(IntroSub,   TweenInfo.new(0.8), {TextTransparency=1}):Play()
    task.wait(1.2)
    TweenService:Create(IntroFrame, TweenInfo.new(1.5), {BackgroundTransparency=1}):Play()
    task.wait(1.6)
    IntroFrame:Destroy()
end)

-- ═══════════════════════════════════════════════════════════
print("╔══════════════════════════════════════════════════════╗")
print("║         GRACE Fanmade v10.1 — Final Loaded          ║")
print("║  GAZE / ELUDE / NUMB / MOUTHFEED  active            ║")
print("║  PIECE / DELICTUM / NORM          active            ║")
print("║  BLUE SKY (Nuclear Threat)        active            ║")
print("║  DEATH EFFECTS  — avatar corpse per entity          ║")
print("║  FIX: TagDeathCause snapshots avatar BEFORE kill    ║")
print("║  FIX: pendingCorpse cleared on CharacterAdded       ║")
print("╚══════════════════════════════════════════════════════╝")
