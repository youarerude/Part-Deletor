--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
	GUI redesigned for mobile — large touch targets, rounded modern layout, smooth tweens.
]]

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Cam = game.Workspace.CurrentCamera

-- ─────────────────────────────────────────
--  GUI CONSTRUCTION
-- ─────────────────────────────────────────

local AimbotGUI = Instance.new("ScreenGui")
AimbotGUI.Name = "AimbotGUI"
AimbotGUI.ResetOnSpawn = false
AimbotGUI.DisplayOrder = 999
AimbotGUI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Main panel
local Background = Instance.new("Frame")
Background.Name = "Background"
Background.Parent = AimbotGUI
Background.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
Background.BorderSizePixel = 0
Background.Position = UDim2.new(0.5, -125, 0.5, -130)
Background.Size = UDim2.new(0, 250, 0, 260)
Background.Active = true
Background.Draggable = true
Background.ZIndex = 2
Background.ClipsDescendants = false

local BgCorner = Instance.new("UICorner")
BgCorner.CornerRadius = UDim.new(0, 18)
BgCorner.Parent = Background

local BgStroke = Instance.new("UIStroke")
BgStroke.Color = Color3.fromRGB(100, 70, 200)
BgStroke.Thickness = 1.5
BgStroke.Transparency = 0.3
BgStroke.Parent = Background

-- Inner clip frame (so content respects rounded corners)
local Inner = Instance.new("Frame")
Inner.Name = "Inner"
Inner.Parent = Background
Inner.BackgroundTransparency = 1
Inner.Size = UDim2.new(1, 0, 1, 0)
Inner.ZIndex = 2
Inner.ClipsDescendants = true

local InnerCorner = Instance.new("UICorner")
InnerCorner.CornerRadius = UDim.new(0, 18)
InnerCorner.Parent = Inner

-- Top bar gradient
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = Inner
TopBar.BackgroundColor3 = Color3.fromRGB(30, 18, 60)
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 54)
TopBar.ZIndex = 3

local TopGradient = Instance.new("UIGradient")
TopGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 30, 160)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 18, 60)),
})
TopGradient.Rotation = 90
TopGradient.Parent = TopBar

-- Title icon (crosshair symbol)
local TitleIcon = Instance.new("TextLabel")
TitleIcon.Parent = TopBar
TitleIcon.BackgroundTransparency = 1
TitleIcon.Position = UDim2.new(0, 14, 0, 0)
TitleIcon.Size = UDim2.new(0, 30, 1, 0)
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.Text = "⊕"
TitleIcon.TextColor3 = Color3.fromRGB(180, 120, 255)
TitleIcon.TextSize = 22
TitleIcon.ZIndex = 4

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 50, 0, 0)
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "AIMBOT"
Title.TextColor3 = Color3.fromRGB(240, 220, 255)
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 4

-- Minimize button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Parent = TopBar
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 40, 100)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Position = UDim2.new(1, -44, 0.5, -15)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 160, 255)
MinimizeBtn.TextSize = 14
MinimizeBtn.ZIndex = 5

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinimizeBtn

-- Divider line
local Divider = Instance.new("Frame")
Divider.Parent = Inner
Divider.BackgroundColor3 = Color3.fromRGB(90, 50, 160)
Divider.BorderSizePixel = 0
Divider.Position = UDim2.new(0, 14, 0, 54)
Divider.Size = UDim2.new(1, -28, 0, 1)
Divider.ZIndex = 3

-- Status badge row
local StatusRow = Instance.new("Frame")
StatusRow.Parent = Inner
StatusRow.BackgroundColor3 = Color3.fromRGB(22, 14, 40)
StatusRow.BorderSizePixel = 0
StatusRow.Position = UDim2.new(0, 14, 0, 68)
StatusRow.Size = UDim2.new(1, -28, 0, 34)
StatusRow.ZIndex = 3

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 10)
StatusCorner.Parent = StatusRow

local StatusDot = Instance.new("Frame")
StatusDot.Parent = StatusRow
StatusDot.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
StatusDot.BorderSizePixel = 0
StatusDot.Position = UDim2.new(0, 12, 0.5, -6)
StatusDot.Size = UDim2.new(0, 12, 0, 12)
StatusDot.ZIndex = 4

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = StatusDot

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = StatusRow
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 32, 0, 0)
StatusLabel.Size = UDim2.new(1, -36, 1, 0)
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.Text = "AIMBOT  ·  INACTIVE"
StatusLabel.TextColor3 = Color3.fromRGB(180, 140, 220)
StatusLabel.TextSize = 13
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.ZIndex = 4

-- Big toggle button
local EnableToggle = Instance.new("TextButton")
EnableToggle.Name = "EnableToggle"
EnableToggle.Parent = Inner
EnableToggle.BackgroundColor3 = Color3.fromRGB(70, 30, 140)
EnableToggle.BorderSizePixel = 0
EnableToggle.Position = UDim2.new(0, 14, 0, 116)
EnableToggle.Size = UDim2.new(1, -28, 0, 68)
EnableToggle.Font = Enum.Font.GothamBold
EnableToggle.Text = "ENABLE"
EnableToggle.TextColor3 = Color3.fromRGB(230, 200, 255)
EnableToggle.TextSize = 20
EnableToggle.ZIndex = 4
EnableToggle.AutoButtonColor = false

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 14)
ToggleCorner.Parent = EnableToggle

local ToggleGradient = Instance.new("UIGradient")
ToggleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 40, 200)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 20, 120)),
})
ToggleGradient.Rotation = 135
ToggleGradient.Parent = EnableToggle

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(160, 90, 255)
ToggleStroke.Thickness = 1.5
ToggleStroke.Transparency = 0.2
ToggleStroke.Parent = EnableToggle

-- FOV info row
local FovRow = Instance.new("Frame")
FovRow.Parent = Inner
FovRow.BackgroundColor3 = Color3.fromRGB(20, 12, 36)
FovRow.BorderSizePixel = 0
FovRow.Position = UDim2.new(0, 14, 0, 198)
FovRow.Size = UDim2.new(1, -28, 0, 30)
FovRow.ZIndex = 3

local FovRowCorner = Instance.new("UICorner")
FovRowCorner.CornerRadius = UDim.new(0, 8)
FovRowCorner.Parent = FovRow

local FovLabel = Instance.new("TextLabel")
FovLabel.Name = "FovLabel"
FovLabel.Parent = FovRow
FovLabel.BackgroundTransparency = 1
FovLabel.Size = UDim2.new(1, 0, 1, 0)
FovLabel.Font = Enum.Font.Gotham
FovLabel.Text = "FOV RADIUS  ·  100 px"
FovLabel.TextColor3 = Color3.fromRGB(130, 100, 180)
FovLabel.TextSize = 12
FovLabel.ZIndex = 4

-- Credits
local Credits = Instance.new("TextLabel")
Credits.Name = "Credits"
Credits.Parent = Inner
Credits.BackgroundTransparency = 1
Credits.Position = UDim2.new(0, 0, 0, 236)
Credits.Size = UDim2.new(1, 0, 0, 18)
Credits.Font = Enum.Font.Gotham
Credits.Text = "by Bloodscript"
Credits.TextColor3 = Color3.fromRGB(80, 60, 110)
Credits.TextSize = 11
Credits.ZIndex = 4

-- ─────────────────────────────────────────
--  MINIMIZE LOGIC
-- ─────────────────────────────────────────

local minimized = false
local fullHeight = 260
local miniHeight = 54
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

MinimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	local targetSize = minimized
		and UDim2.new(0, 250, 0, miniHeight)
		or  UDim2.new(0, 250, 0, fullHeight)
	MinimizeBtn.Text = minimized and "+" or "—"
	TweenService:Create(Background, tweenInfo, {Size = targetSize}):Play()
end)

-- Toggle hover effects
EnableToggle.MouseEnter:Connect(function()
	TweenService:Create(EnableToggle, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(90, 45, 170)
	}):Play()
end)
EnableToggle.MouseLeave:Connect(function()
	TweenService:Create(EnableToggle, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(70, 30, 140)
	}):Play()
end)

-- ─────────────────────────────────────────
--  FOV CIRCLE
-- ─────────────────────────────────────────

local fov = 100

local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Color = Color3.fromRGB(160, 80, 255)
FOVring.Filled = false
FOVring.Radius = fov
FOVring.Position = Cam.ViewportSize / 2

local function updateDrawings()
	FOVring.Position = Cam.ViewportSize / 2
end

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Delete then
		RunService:UnbindFromRenderStep("FOVUpdate")
		FOVring:Remove()
	end
end)

-- ─────────────────────────────────────────
--  AIMBOT LOGIC
-- ─────────────────────────────────────────

local aimbotEnabled = false

-- Touch tracking — while the player is swiping to look around, pause locking
-- so the camera moves freely. On release, instantly snap back to the target.
local isTouchDragging = false

-- Only pause aimbot when the player is actually MOVING their finger (camera swipe).
-- A button hold stays still — a camera drag moves. We use a movement threshold
-- so tapping or holding shoot never pauses the lock.
local SWIPE_THRESHOLD = 12  -- pixels of movement before we consider it a camera drag
local touchStartPositions = {}  -- [touchId] = Vector2 start pos

UserInputService.TouchStarted:Connect(function(touch, processed)
	if processed then return end
	-- Record where this finger started
	touchStartPositions[touch] = Vector2.new(touch.Position.X, touch.Position.Y)
end)

UserInputService.TouchMoved:Connect(function(touch, processed)
	if processed then return end
	local startPos = touchStartPositions[touch]
	if startPos then
		local delta = (Vector2.new(touch.Position.X, touch.Position.Y) - startPos).Magnitude
		if delta >= SWIPE_THRESHOLD then
			-- This touch moved enough — it's a camera swipe, pause aimbot
			isTouchDragging = true
		end
	end
end)

UserInputService.TouchEnded:Connect(function(touch, processed)
	touchStartPositions[touch] = nil
	-- Check if any remaining tracked touches are still swiping
	-- If none left, release the pause
	local anyActive = false
	for _ in pairs(touchStartPositions) do
		anyActive = true
		break
	end
	if not anyActive then
		isTouchDragging = false
	end
end)

local function lookAt(target)
	local lookVector = (target - Cam.CFrame.Position).unit
	Cam.CFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lookVector)
end

-- Smooth snap-back: lerp the camera toward the target over snapSpeed.
-- Lower = snappier. 1 = instant. 0.1 = slow drift.
local snapSpeed = 0.18

local function smoothLookAt(target, dt)
	local currentLook = Cam.CFrame.LookVector
	local desiredLook = (target - Cam.CFrame.Position).Unit
	local blendedLook = currentLook:Lerp(desiredLook, math.min(1, snapSpeed + dt * 8))
	Cam.CFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + blendedLook)
end

local function getClosestPlayerInFOV(trg_part)
	local nearest = nil
	local last = math.huge
	local center = Cam.ViewportSize / 2
	local localPlayer = Players.LocalPlayer

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and (not player.Team or player.Team ~= localPlayer.Team) then
			local part = player.Character and player.Character:FindFirstChild(trg_part)
			if part then
				local ePos, isVisible = Cam:WorldToViewportPoint(part.Position)
				local dist = (Vector2.new(ePos.X, ePos.Y) - center).Magnitude
				if dist < last and isVisible and dist < fov then
					last = dist
					nearest = player
				end
			end
		end
	end

	return nearest
end

local function setAimbotState(enabled)
	aimbotEnabled = enabled

	if enabled then
		ToggleGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 180, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 100, 60)),
		})
		ToggleStroke.Color = Color3.fromRGB(60, 220, 120)
		EnableToggle.Text = "DISABLE"
		EnableToggle.TextColor3 = Color3.fromRGB(200, 255, 220)

		StatusDot.BackgroundColor3 = Color3.fromRGB(60, 220, 120)
		StatusLabel.Text = "AIMBOT  ·  ACTIVE"
		StatusLabel.TextColor3 = Color3.fromRGB(140, 220, 160)

		FOVring.Color = Color3.fromRGB(60, 220, 120)
		FOVring.Visible = true
	else
		ToggleGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 40, 200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 20, 120)),
		})
		ToggleStroke.Color = Color3.fromRGB(160, 90, 255)
		EnableToggle.Text = "ENABLE"
		EnableToggle.TextColor3 = Color3.fromRGB(230, 200, 255)

		StatusDot.BackgroundColor3 = Color3.fromRGB(255, 60, 80)
		StatusLabel.Text = "AIMBOT  ·  INACTIVE"
		StatusLabel.TextColor3 = Color3.fromRGB(180, 140, 220)

		FOVring.Color = Color3.fromRGB(160, 80, 255)
		FOVring.Visible = false
	end
end

EnableToggle.MouseButton1Click:Connect(function()
	setAimbotState(not aimbotEnabled)
end)

-- ─────────────────────────────────────────
--  RENDER LOOP
-- ─────────────────────────────────────────

RunService.RenderStepped:Connect(function(dt)
	updateDrawings()
	if aimbotEnabled then
		local closest = getClosestPlayerInFOV("Head")
		if closest and closest.Character and closest.Character:FindFirstChild("Head") then
			local headPos = closest.Character.Head.Position
			if isTouchDragging then
				-- Player is swiping: let the camera move freely, do nothing.
				-- FOV ring stays visible so they know aim is still locked on release.
			else
				-- Not touching: smoothly snap back toward the target.
				smoothLookAt(headPos, dt)
			end
		end
	end
end)
