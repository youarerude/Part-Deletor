-- Gui to Lua
-- Version: 3.2

-- Instances:

local Gui = Instance.new("ScreenGui")
local Main = Instance.new("Frame")
local Box = Instance.new("TextBox")
local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
local Label = Instance.new("TextLabel")
local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")
local Button = Instance.new("TextButton")
local UITextSizeConstraint_3 = Instance.new("UITextSizeConstraint")

-- Window controls
local MinimizeButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local MinimizedCircle = Instance.new("Frame")
local CircleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local UICorner2 = Instance.new("UICorner")

-- Mode toggle button
local ModeButton = Instance.new("TextButton")
local UITextSizeConstraint_4 = Instance.new("UITextSizeConstraint")

-- Orbit mode textboxes
local RangeBox = Instance.new("TextBox")
local RangeLabel = Instance.new("TextLabel")
local RotationBox = Instance.new("TextBox")
local RotationLabel = Instance.new("TextLabel")
local OffsetBox = Instance.new("TextBox")
local OffsetLabel = Instance.new("TextLabel")
local SpeedBox = Instance.new("TextBox")
local SpeedLabel = Instance.new("TextLabel")
local SpacingBox = Instance.new("TextBox")
local SpacingLabel = Instance.new("TextLabel")

-- Black hole mode textboxes
local ForceRangeBox = Instance.new("TextBox")
local ForceRangeLabel = Instance.new("TextLabel")
local PowerBox = Instance.new("TextBox")
local PowerLabel = Instance.new("TextLabel")

--Properties:

Gui.Name = "Gui"
Gui.Parent = gethui()
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Main.Name = "Main"
Main.Parent = Gui
Main.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
Main.BorderColor3 = Color3.fromRGB(0, 0, 0)
Main.BorderSizePixel = 0
Main.Position = UDim2.new(0.1, 0, 0.1, 0)
Main.Size = UDim2.new(0.8, 0, 0.7, 0)
Main.Active = true
Main.Draggable = true

-- Window control buttons
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = Main
MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Position = UDim2.new(0.92, 0, 0.01, 0)
MinimizeButton.Size = UDim2.new(0.035, 0, 0.05, 0)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Text = "−"
MinimizeButton.TextColor3 = Color3.fromRGB(0, 0, 0)
MinimizeButton.TextScaled = true

CloseButton.Name = "CloseButton"
CloseButton.Parent = Main
CloseButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(0.96, 0, 0.01, 0)
CloseButton.Size = UDim2.new(0.035, 0, 0.05, 0)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextScaled = true

-- Minimized circle
MinimizedCircle.Name = "MinimizedCircle"
MinimizedCircle.Parent = Gui
MinimizedCircle.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
MinimizedCircle.BorderColor3 = Color3.fromRGB(255, 255, 255)
MinimizedCircle.BorderSizePixel = 2
MinimizedCircle.Position = UDim2.new(0.02, 0, 0.02, 0)
MinimizedCircle.Size = UDim2.new(0, 60, 0, 60)
MinimizedCircle.Active = true
MinimizedCircle.Draggable = true
MinimizedCircle.Visible = false

UICorner.Parent = MinimizedCircle
UICorner.CornerRadius = UDim.new(0.5, 0)

CircleButton.Name = "CircleButton"
CircleButton.Parent = MinimizedCircle
CircleButton.BackgroundTransparency = 1
CircleButton.Size = UDim2.new(1, 0, 1, 0)
CircleButton.Font = Enum.Font.GothamBold
CircleButton.Text = "O"
CircleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CircleButton.TextScaled = true

UICorner2.Parent = Main
UICorner2.CornerRadius = UDim.new(0, 8)

Box.Name = "Box"
Box.Parent = Main
Box.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
Box.BorderSizePixel = 0
Box.Position = UDim2.new(0.05, 0, 0.12, 0)
Box.Size = UDim2.new(0.4, 0, 0.08, 0)
Box.FontFace = Font.new("rbxasset://fonts/families/SourceSansSemibold.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
Box.PlaceholderText = "Player here"
Box.Text = ""
Box.TextColor3 = Color3.fromRGB(255, 255, 255)
Box.TextScaled = true
Box.TextSize = 31.000
Box.TextWrapped = true

UITextSizeConstraint.Parent = Box
UITextSizeConstraint.MaxTextSize = 31

Label.Name = "Label"
Label.Parent = Main
Label.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
Label.BorderColor3 = Color3.fromRGB(0, 0, 0)
Label.BorderSizePixel = 0
Label.Position = UDim2.new(0, 0, 0.07, 0)
Label.Size = UDim2.new(0.87, 0, 0.04, 0)
Label.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
Label.Text = "Orbit Parts | t.me/arceusxscripts"
Label.TextColor3 = Color3.fromRGB(255, 255, 255)
Label.TextScaled = true
Label.TextSize = 14.000
Label.TextWrapped = true

UITextSizeConstraint_2.Parent = Label
UITextSizeConstraint_2.MaxTextSize = 21

Button.Name = "Button"
Button.Parent = Main
Button.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
Button.BorderSizePixel = 0
Button.Position = UDim2.new(0.55, 0, 0.12, 0)
Button.Size = UDim2.new(0.4, 0, 0.08, 0)
Button.Font = Enum.Font.Nunito
Button.Text = "Orbit | Off"
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.TextScaled = true
Button.TextSize = 28.000
Button.TextWrapped = true

UITextSizeConstraint_3.Parent = Button
UITextSizeConstraint_3.MaxTextSize = 28

-- Mode toggle button
ModeButton.Name = "ModeButton"
ModeButton.Parent = Main
ModeButton.BackgroundColor3 = Color3.fromRGB(0, 162, 232)
ModeButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
ModeButton.BorderSizePixel = 0
ModeButton.Position = UDim2.new(0.05, 0, 0.22, 0)
ModeButton.Size = UDim2.new(0.9, 0, 0.06, 0)
ModeButton.Font = Enum.Font.Nunito
ModeButton.Text = "Orbit Mode (Default)"
ModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeButton.TextScaled = true
ModeButton.TextSize = 24.000
ModeButton.TextWrapped = true

UITextSizeConstraint_4.Parent = ModeButton
UITextSizeConstraint_4.MaxTextSize = 24

-- Range textbox and label (Orbit mode)
RangeLabel.Name = "RangeLabel"
RangeLabel.Parent = Main
RangeLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
RangeLabel.BorderSizePixel = 0
RangeLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
RangeLabel.Size = UDim2.new(0.15, 0, 0.06, 0)
RangeLabel.Font = Enum.Font.Nunito
RangeLabel.Text = "Range:"
RangeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RangeLabel.TextScaled = true

RangeBox.Name = "RangeBox"
RangeBox.Parent = Main
RangeBox.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
RangeBox.BorderSizePixel = 0
RangeBox.Position = UDim2.new(0.22, 0, 0.3, 0)
RangeBox.Size = UDim2.new(0.23, 0, 0.06, 0)
RangeBox.Font = Enum.Font.SourceSans
RangeBox.PlaceholderText = "10"
RangeBox.Text = "10"
RangeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
RangeBox.TextScaled = true

-- Rotation textbox and label (Orbit mode)
RotationLabel.Name = "RotationLabel"
RotationLabel.Parent = Main
RotationLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
RotationLabel.BorderSizePixel = 0
RotationLabel.Position = UDim2.new(0.52, 0, 0.3, 0)
RotationLabel.Size = UDim2.new(0.15, 0, 0.06, 0)
RotationLabel.Font = Enum.Font.Nunito
RotationLabel.Text = "Rotation:"
RotationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RotationLabel.TextScaled = true

RotationBox.Name = "RotationBox"
RotationBox.Parent = Main
RotationBox.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
RotationBox.BorderSizePixel = 0
RotationBox.Position = UDim2.new(0.69, 0, 0.3, 0)
RotationBox.Size = UDim2.new(0.26, 0, 0.06, 0)
RotationBox.Font = Enum.Font.SourceSans
RotationBox.PlaceholderText = "0"
RotationBox.Text = "0"
RotationBox.TextColor3 = Color3.fromRGB(255, 255, 255)
RotationBox.TextScaled = true

-- Offset textbox and label (Orbit mode)
OffsetLabel.Name = "OffsetLabel"
OffsetLabel.Parent = Main
OffsetLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
OffsetLabel.BorderSizePixel = 0
OffsetLabel.Position = UDim2.new(0.05, 0, 0.38, 0)
OffsetLabel.Size = UDim2.new(0.15, 0, 0.06, 0)
OffsetLabel.Font = Enum.Font.Nunito
OffsetLabel.Text = "Offset:"
OffsetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
OffsetLabel.TextScaled = true

OffsetBox.Name = "OffsetBox"
OffsetBox.Parent = Main
OffsetBox.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
OffsetBox.BorderSizePixel = 0
OffsetBox.Position = UDim2.new(0.22, 0, 0.38, 0)
OffsetBox.Size = UDim2.new(0.23, 0, 0.06, 0)
OffsetBox.Font = Enum.Font.SourceSans
OffsetBox.PlaceholderText = "3"
OffsetBox.Text = "3"
OffsetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
OffsetBox.TextScaled = true

-- Speed textbox and label (Orbit mode)
SpeedLabel.Name = "SpeedLabel"
SpeedLabel.Parent = Main
SpeedLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
SpeedLabel.BorderSizePixel = 0
SpeedLabel.Position = UDim2.new(0.52, 0, 0.38, 0)
SpeedLabel.Size = UDim2.new(0.15, 0, 0.06, 0)
SpeedLabel.Font = Enum.Font.Nunito
SpeedLabel.Text = "Speed:"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.TextScaled = true

SpeedBox.Name = "SpeedBox"
SpeedBox.Parent = Main
SpeedBox.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
SpeedBox.BorderSizePixel = 0
SpeedBox.Position = UDim2.new(0.69, 0, 0.38, 0)
SpeedBox.Size = UDim2.new(0.26, 0, 0.06, 0)
SpeedBox.Font = Enum.Font.SourceSans
SpeedBox.PlaceholderText = "2"
SpeedBox.Text = "2"
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.TextScaled = true

-- Spacing textbox and label (Orbit mode)
SpacingLabel.Name = "SpacingLabel"
SpacingLabel.Parent = Main
SpacingLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
SpacingLabel.BorderSizePixel = 0
SpacingLabel.Position = UDim2.new(0.05, 0, 0.46, 0)
SpacingLabel.Size = UDim2.new(0.15, 0, 0.06, 0)
SpacingLabel.Font = Enum.Font.Nunito
SpacingLabel.Text = "Spacing:"
SpacingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpacingLabel.TextScaled = true

SpacingBox.Name = "SpacingBox"
SpacingBox.Parent = Main
SpacingBox.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
SpacingBox.BorderSizePixel = 0
SpacingBox.Position = UDim2.new(0.22, 0, 0.46, 0)
SpacingBox.Size = UDim2.new(0.23, 0, 0.06, 0)
SpacingBox.Font = Enum.Font.SourceSans
SpacingBox.PlaceholderText = "1"
SpacingBox.Text = "1"
SpacingBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpacingBox.TextScaled = true

-- Force Range textbox and label (Black hole mode)
ForceRangeLabel.Name = "ForceRangeLabel"
ForceRangeLabel.Parent = Main
ForceRangeLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
ForceRangeLabel.BorderSizePixel = 0
ForceRangeLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
ForceRangeLabel.Size = UDim2.new(0.2, 0, 0.06, 0)
ForceRangeLabel.Font = Enum.Font.Nunito
ForceRangeLabel.Text = "Force Range:"
ForceRangeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ForceRangeLabel.TextScaled = true
ForceRangeLabel.Visible = false

ForceRangeBox.Name = "ForceRangeBox"
ForceRangeBox.Parent = Main
ForceRangeBox.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
ForceRangeBox.BorderSizePixel = 0
ForceRangeBox.Position = UDim2.new(0.27, 0, 0.3, 0)
ForceRangeBox.Size = UDim2.new(0.68, 0, 0.06, 0)
ForceRangeBox.Font = Enum.Font.SourceSans
ForceRangeBox.PlaceholderText = "50"
ForceRangeBox.Text = "50"
ForceRangeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
ForceRangeBox.TextScaled = true
ForceRangeBox.Visible = false

-- Power textbox and label (Black hole mode)
PowerLabel.Name = "PowerLabel"
PowerLabel.Parent = Main
PowerLabel.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
PowerLabel.BorderSizePixel = 0
PowerLabel.Position = UDim2.new(0.05, 0, 0.38, 0)
PowerLabel.Size = UDim2.new(0.2, 0, 0.06, 0)
PowerLabel.Font = Enum.Font.Nunito
PowerLabel.Text = "Power:"
PowerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PowerLabel.TextScaled = true
PowerLabel.Visible = false

PowerBox.Name = "PowerBox"
PowerBox.Parent = Main
PowerBox.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
PowerBox.BorderSizePixel = 0
PowerBox.Position = UDim2.new(0.27, 0, 0.38, 0)
PowerBox.Size = UDim2.new(0.68, 0, 0.06, 0)
PowerBox.Font = Enum.Font.SourceSans
PowerBox.PlaceholderText = "5"
PowerBox.Text = "5"
PowerBox.TextColor3 = Color3.fromRGB(255, 255, 255)
PowerBox.TextScaled = true
PowerBox.Visible = false

-- Scripts:

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local character
local humanoidRootPart

-- Window state
local isMinimized = false

-- Mode state
local isBlackHoleMode = false

mainStatus = true
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if input.KeyCode == Enum.KeyCode.RightControl and not gameProcessedEvent then
		mainStatus = not mainStatus
		if isMinimized then
			MinimizedCircle.Visible = mainStatus
		else
			Main.Visible = mainStatus
		end
	end
end)

-- Window control functions
local function minimizeWindow()
	isMinimized = true
	Main.Visible = false
	MinimizedCircle.Visible = true
end

local function restoreWindow()
	isMinimized = false
	MinimizedCircle.Visible = false
	Main.Visible = true
end

local function closeWindow()
	Gui:Destroy()
end

-- Connect window control events
MinimizeButton.MouseButton1Click:Connect(minimizeWindow)
CloseButton.MouseButton1Click:Connect(closeWindow)
CircleButton.MouseButton1Click:Connect(restoreWindow)

-- Mode switching function
local function toggleMode()
	isBlackHoleMode = not isBlackHoleMode
	
	if isBlackHoleMode then
		-- Switch to Black Hole Mode
		ModeButton.Text = "Black Hole Mode"
		ModeButton.BackgroundColor3 = Color3.fromRGB(139, 0, 139) -- Dark purple
		
		-- Set button text based on current orbit status
		if orbitActive then
			Button.Text = "Black Hole | On"
		else
			Button.Text = "Black Hole | Off"
		end
		
		-- Hide orbit mode controls
		RangeLabel.Visible = false
		RangeBox.Visible = false
		RotationLabel.Visible = false
		RotationBox.Visible = false
		OffsetLabel.Visible = false
		OffsetBox.Visible = false
		SpeedLabel.Visible = false
		SpeedBox.Visible = false
		SpacingLabel.Visible = false
		SpacingBox.Visible = false
		
		-- Show black hole mode controls
		ForceRangeLabel.Visible = true
		ForceRangeBox.Visible = true
		PowerLabel.Visible = true
		PowerBox.Visible = true
	else
		-- Switch to Orbit Mode
		ModeButton.Text = "Orbit Mode (Default)"
		ModeButton.BackgroundColor3 = Color3.fromRGB(0, 162, 232) -- Blue
		
		-- Set button text based on current orbit status
		if orbitActive then
			Button.Text = "Orbit | On"
		else
			Button.Text = "Orbit | Off"
		end
		
		-- Show orbit mode controls
		RangeLabel.Visible = true
		RangeBox.Visible = true
		RotationLabel.Visible = true
		RotationBox.Visible = true
		OffsetLabel.Visible = true
		OffsetBox.Visible = true
		SpeedLabel.Visible = true
		SpeedBox.Visible = true
		SpacingLabel.Visible = true
		SpacingBox.Visible = true
		
		-- Hide black hole mode controls
		ForceRangeLabel.Visible = false
		ForceRangeBox.Visible = false
		PowerLabel.Visible = false
		PowerBox.Visible = false
	end
end

-- Connect mode button
ModeButton.MouseButton1Click:Connect(toggleMode)

local Folder = Instance.new("Folder", Workspace)
local Part = Instance.new("Part", Folder)
local Attachment1 = Instance.new("Attachment", Part)
Part.Anchored = true
Part.CanCollide = false
Part.Transparency = 1

-- Orbiting variables
local orbitRadius = 10 -- Distance from player
local orbitSpeed = 2 -- Speed of orbit (radians per second)
local orbitHeight = 3 -- Height offset from player
local orbitAngle = 0 -- Current angle
local rotationOffset = 0 -- Rotation offset
local partSpacing = 1 -- Spacing between parts

-- Black hole variables
local forceRange = 50 -- Range for black hole effect
local blackHolePower = 5 -- Power/strength of the black hole
local blackHoleParts = {} -- Store parts affected by black hole

-- Function to get values from textboxes
local function getSpinValues()
	if isBlackHoleMode then
		forceRange = tonumber(ForceRangeBox.Text) or 50
		blackHolePower = tonumber(PowerBox.Text) or 5
	else
		orbitRadius = tonumber(RangeBox.Text) or 10
		rotationOffset = math.rad(tonumber(RotationBox.Text) or 0)
		orbitHeight = tonumber(OffsetBox.Text) or 3
		orbitSpeed = tonumber(SpeedBox.Text) or 2
		partSpacing = tonumber(SpacingBox.Text) or 1
	end
end

if not getgenv().Network then
	getgenv().Network = {
		BaseParts = {},
		Velocity = Vector3.new
