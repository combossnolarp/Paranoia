local Blossom = ...
if not Blossom then
	if script and script.Parent and script.Parent:FindFirstChild("Blossom") then
		local ok, result = pcall(function()
			return require(script.Parent.Blossom)
		end)
		if ok then Blossom = result end
	end
	if not Blossom then
		local src = game:HttpGet("https://raw.githubusercontent.com/mmr1337/Blossom/main/Blossom.luau")
		if not src or src == "" then
			return
		end

		local function replace(text, target, replacement)
			return string.gsub(text, target, function() return replacement end, 1)
		end

		src = replace(src, "if picker%.Target then picker%.Target:Set%(Color3%.fromHSV%(picker%.H, picker%.S, picker%.V%), picker%.Alpha%) end",
			"if picker.Target then picker.Target:Set(Color3.fromHSV(picker.H, picker.S, picker.V), picker.Alpha, true) end")

		src = replace(src, "swatch%.BackgroundColor3 = value\n\t\tif win%.Picker%.Target == color and not win%.Picker%.Dragging then win%.Picker%.Sync%(%) end\n\t\tif not silent then fire%(color%.Callback, value, color%.Alpha%) end",
			"swatch.BackgroundColor3 = value\n\t\tswatch.BackgroundTransparency = color.Alpha\n\t\tif win.Picker.Target == color and not win.Picker.Dragging then win.Picker.Sync() end\n\t\tif not silent then fire(color.Callback, value, color.Alpha) end")

		src = replace(src, "picker%.S, picker%.V, picker%.Alpha = s, v, target%.Alpha or 0",
			"picker.S, picker.V, picker.Alpha = s, v, target.Alpha or 0")
		src = replace(src, "if picker%.Target then picker%.Target:Set%(Color3%.fromHSV%(picker%.H, picker%.S, picker%.V%), picker%.Alpha%) end",
			"if picker.Target then picker.Target:Set(Color3.fromHSV(picker.H, picker.S, picker.V), picker.Alpha) end")

		local checkerboardCode = [[
		for i = 0, 60 do
			for j = 0, 3 do
				if (i + j) % 2 == 1 then
					new("Frame", { BackgroundTransparency = 0, BackgroundColor3 = RGB(160, 160, 160), Position = Offset(i * 4, j * 4), Size = Offset(4, 4) }, alphaBar)
				end
			end
		end
		local]]
		src = replace(src, "local alphaBar = new%(\"Frame\", { Bg = \"Background\", Position = Offset%(pad %+ 1, alphaY %+ 1%)", checkerboardCode .. " alphaBar = new(\"Frame\", { Bg = \"Background\", Position = Offset(pad + 1, alphaY + 1)")

		Blossom = loadstring(src)()
	end
end

local Themes = Blossom.Themes
local ThemeOrder = Blossom.ThemeOrder

if Themes and Themes.Blossom then
	Themes.Paranoia = {
		Background = Color3.fromRGB(8, 8, 8),
		Tab = Color3.fromRGB(8, 8, 8),
		Outline = Color3.fromRGB(35, 35, 35),
		Inline = Color3.fromRGB(8, 8, 8),
		Text = Color3.fromRGB(255, 255, 255),
		InactiveText = Color3.fromRGB(140, 140, 140),
		Accent = Color3.fromRGB(230, 160, 255),
		Element = Color3.fromRGB(8, 8, 8),
		Gradient = Color3.fromRGB(230, 160, 255),
		Shadow = Color3.fromRGB(0, 0, 0),
		HoveredElement = Color3.fromRGB(25, 25, 25),
	}
	Themes.Blossom = nil

	if ThemeOrder then
		for i, v in ipairs(ThemeOrder) do
			if v == "Blossom" then
				ThemeOrder[i] = "Paranoia"
				break
			end
		end
	end
end

local Window = Blossom.new({ Title = "Paranoia", Script = "Paranoia", Build = "Rivals", Theme = "Paranoia" })

local ASSET_BASE = "https://raw.githubusercontent.com/combossnolarp/Paranoia/claude/wizardly-dijkstra-5vzykn/assets/"
local LOGO = { Id = nil, Url = ASSET_BASE .. "logo_mono.png", File = "Paranoia/logo_mono_v1.png" }
local LOGO_ANIM = { Id = nil, Url = ASSET_BASE .. "logo_anim_mono.png", File = "Paranoia/logo_anim_mono_v1.png" }
local ANIM_FRAMES, ANIM_COLUMNS, ANIM_W, ANIM_H, ANIM_FRAME_TIME = 60, 6, 168, 89, 0.03

local LogoImages = {}
local accentColor = (Themes and Themes.Paranoia and Themes.Paranoia.Accent) or Color3.fromRGB(230, 160, 255)

local function setAccent(color)
	accentColor = color
	for image in pairs(LogoImages) do
		image.ImageColor3 = color
	end
end

local function trackLogo(image)
	LogoImages[image] = true
	image.ImageColor3 = accentColor
	image.Destroying:Connect(function() LogoImages[image] = nil end)
end

local function watchAccent()
	local sidebar = Window.Sidebar
	local icon = sidebar and sidebar:FindFirstChild("Icon")
	local source
	if icon then
		for _, child in ipairs(icon:GetChildren()) do
			if child:IsA("Frame") then
				source = child
				break
			end
		end
	end
	if source then
		setAccent(source.BackgroundColor3)
		source:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
			setAccent(source.BackgroundColor3)
		end)
		return
	end
	local applyTheme, setThemeColor = Window.ApplyTheme, Window.SetThemeColor
	Window.ApplyTheme = function(self, name, ...)
		local theme = Themes and Themes[name]
		if theme and theme.Accent then setAccent(theme.Accent) end
		return applyTheme(self, name, ...)
	end
	Window.SetThemeColor = function(self, key, color, ...)
		if key == "Accent" then setAccent(color) end
		return setThemeColor(self, key, color, ...)
	end
end

watchAccent()

local function resolveAsset(asset)
	if asset.Id then return asset.Id end
	local getAsset = getcustomasset or getsynasset
	if not (getAsset and writefile and isfile) then return nil end
	local ok, result = pcall(function()
		if not isfile(asset.File) then
			if makefolder and isfolder and not isfolder("Paranoia") then makefolder("Paranoia") end
			local data = game:HttpGet(asset.Url)
			if not data or #data == 0 then return nil end
			writefile(asset.File, data)
		end
		return getAsset(asset.File)
	end)
	return ok and result or nil
end

local function applyLogo(container, image)
	if not container then return end
	local icon = container:FindFirstChild("Icon")
	if not icon then return end
	for _, child in ipairs(icon:GetChildren()) do
		if child:IsA("GuiObject") then child.Visible = false end
	end
	local logo = Instance.new("ImageLabel")
	logo.Name = "CustomLogo"
	logo.BackgroundTransparency = 1
	logo.BorderSizePixel = 0
	logo.Size = UDim2.fromScale(1.5, 1.5)
	logo.Position = UDim2.fromScale(0.5, 0.5)
	logo.AnchorPoint = Vector2.new(0.5, 0.5)
	logo.ScaleType = Enum.ScaleType.Fit
	logo.Image = image
	logo.ZIndex = icon.ZIndex + 1
	logo.Parent = icon
	trackLogo(logo)
end

local function setupDragOverlay()
	local holder = Window.Holder
	if not holder then return nil end
	local UIS = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local Tweens = game:GetService("TweenService")

	local overlay = Instance.new("Frame")
	overlay.Name = "DragOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1000
	overlay.Visible = false
	overlay.Parent = holder
	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(0, 6)
	overlayCorner.Parent = overlay

	local logo = Instance.new("ImageLabel")
	logo.Name = "Logo"
	logo.BackgroundTransparency = 1
	logo.AnchorPoint = Vector2.new(0.5, 0.5)
	logo.Position = UDim2.fromScale(0.5, 0.5)
	logo.Size = UDim2.fromOffset(ANIM_W * 1.4, ANIM_H * 1.4)
	logo.ScaleType = Enum.ScaleType.Fit
	logo.ImageTransparency = 1
	logo.ZIndex = 1001
	logo.Parent = overlay
	trackLogo(logo)

	local animated = false
	local fadeInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local elapsed, shown, generation = 0, false, 0
	local touches = 0

	local function pressed()
		return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or touches > 0
	end

	local function show()
		if shown then return end
		shown = true
		generation += 1
		elapsed = 0
		overlay.Visible = true
		Tweens:Create(overlay, fadeInfo, { BackgroundTransparency = 0 }):Play()
		Tweens:Create(logo, fadeInfo, { ImageTransparency = 0 }):Play()
	end

	local function hide()
		if not shown then return end
		shown = false
		local myGeneration = generation
		Tweens:Create(overlay, fadeInfo, { BackgroundTransparency = 1 }):Play()
		local tween = Tweens:Create(logo, fadeInfo, { ImageTransparency = 1 })
		tween.Completed:Connect(function()
			if generation == myGeneration then overlay.Visible = false end
		end)
		tween:Play()
	end

	local resizing = false
	local function overResizeHandle()
		local location = UIS:GetMouseLocation()
		local screen = Window.Screen
		local point = screen and location + screen.AbsolutePosition or location
		for _, handle in ipairs(Window.ResizeHandles or {}) do
			local p, size = handle.AbsolutePosition, handle.AbsoluteSize
			if point.X >= p.X and point.X <= p.X + size.X and point.Y >= p.Y and point.Y <= p.Y + size.Y then
				return true
			end
		end
		return false
	end

	UIS.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then touches += 1 end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = overResizeHandle()
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then touches = math.max(0, touches - 1) end
	end)

	holder:GetPropertyChangedSignal("Position"):Connect(function()
		if pressed() and not resizing and holder.Visible then show() end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if shown and not pressed() then hide() end
		if overlay.Visible and animated then
			elapsed += dt
			local frame = math.floor(elapsed / ANIM_FRAME_TIME) % ANIM_FRAMES
			logo.ImageRectOffset = Vector2.new((frame % ANIM_COLUMNS) * ANIM_W, math.floor(frame / ANIM_COLUMNS) * ANIM_H)
		end
	end)

	return function(animImage, staticImage)
		if animImage then
			animated = true
			logo.ScaleType = Enum.ScaleType.Stretch
			logo.ImageRectSize = Vector2.new(ANIM_W, ANIM_H)
			logo.ImageRectOffset = Vector2.zero
			logo.Image = animImage
		elseif staticImage then
			logo.Image = staticImage
		end
	end
end

local setDragLogo = setupDragOverlay()

task.spawn(function()
	local image = resolveAsset(LOGO)
	if image then
		applyLogo(Window.Sidebar, image)
		applyLogo(Window.Watermark, image)
	end
	local anim = resolveAsset(LOGO_ANIM)
	if setDragLogo then setDragLogo(anim, image) end
end)

Window:Category("Combat")
local Rage = Window:Tab({ Name = "Rage", Icon = "target" })
local Legit = Window:Tab({ Name = "Legit", Icon = "bullet" })
Window:Category("Visuals")
local PlayersTab = Window:Tab({ Name = "Players", Icon = "smile" })
local Effects = Window:Tab({ Name = "Effects", Icon = "globe" })
Window:Category("Player")
local Movement = Window:Tab({ Name = "Movement", Icon = "smile" })
local Exploits = Window:Tab({ Name = "Exploits", Icon = "bomb" })
local Plugins = Window:Tab({ Name = "Plugins", Icon = "file" })
local Settings = Window:Tab({ Name = "Settings", Icon = "gear" })

local Ragebot = Rage:Section({ Name = "Ragebot", Icon = "robot", Side = 1 })
Ragebot:Toggle({ Name = "Enabled", Default = true, Keybind = Enum.KeyCode.C })
Ragebot:Divider()
Ragebot:Toggle({ Name = "Auto Shoot", Default = true })
Ragebot:Toggle({ Name = "Auto Scope", Default = true })
Ragebot:Toggle({ Name = "Auto Reload", Default = false })
Ragebot:Toggle({ Name = "Force Headshot", Default = false })
Ragebot:Divider()
Ragebot:Toggle({ Name = "Autowall", Default = true })
Ragebot:Slider({ Name = "Min Damage", Min = 1, Max = 100, Default = 20, Suffix = "hp" })
Ragebot:Slider({ Name = "Hitchance", Min = 0, Max = 100, Default = 85, Suffix = "%" })
Ragebot:RangeSlider({ Name = "Damage Range", Min = 0, Max = 100, Default = { 20, 80 }, Suffix = "hp" })
Ragebot:Divider()
Ragebot:Dropdown({ Name = "Target Selection", Options = { "Closest to Crosshair", "Lowest Health", "Highest Threat", "Closest Distance" }, Default = "Closest to Crosshair" })
Ragebot:Slider({ Name = "Max Distance", Min = 0, Max = 2000, Default = 798, Suffix = "st" })

local Targeting = Rage:Section({ Name = "Targeting", Icon = "bullet", Side = 1 })
Targeting:Dropdown({ Name = "Hitboxes", Options = { "Head", "Torso", "Arms", "Legs" }, Default = { "Head", "Torso" }, Multi = true })

local Silent = Rage:Section({ Name = "Silent Aim", Icon = "bullet", Side = 2 })
Silent:Toggle({ Name = "Enabled", Default = false, Keybind = Enum.KeyCode.V })
Silent:Divider()
Silent:Toggle({ Name = "Use FOV", Default = true })
Silent:Toggle({ Name = "Draw FOV", Default = true, Color = Color3.fromRGB(216, 222, 218) })
Silent:Slider({ Name = "FOV Size", Min = 0, Max = 500, Default = 120, Suffix = "px" })
Silent:Divider()
Silent:Slider({ Name = "Hitchance", Min = 0, Max = 100, Default = 100, Suffix = "%" })
Silent:Dropdown({ Name = "Aim Point", Options = { "Head", "Torso", "Closest" }, Default = "Head" })
Silent:Toggle({ Name = "Prediction", Default = true })
Silent:Slider({ Name = "Prediction Amount", Min = 0, Max = 5, Default = 1.2, Decimals = 1, Suffix = "x" })

local AntiAim = Rage:Section({ Name = "Anti Aim", Icon = "wrench", Description = "Desync & angles", Side = 2 })
AntiAim:Toggle({ Name = "Enabled", Default = false, Keybind = Enum.KeyCode.Z })
AntiAim:Divider()
AntiAim:Dropdown({ Name = "Pitch", Options = { "None", "Down", "Up", "Zero", "Random" }, Default = "Zero" })
AntiAim:Dropdown({ Name = "Yaw", Options = { "Backward", "Spin", "Jitter" }, Default = "Backward" })
AntiAim:Slider({ Name = "Spin Speed", Min = 0, Max = 100, Default = 20 })
AntiAim:Slider({ Name = "Jitter Range", Min = 0, Max = 180, Default = 45 })
AntiAim:Divider()
AntiAim:Toggle({ Name = "Fake Duck", Default = false })
AntiAim:Toggle({ Name = "Freestanding", Default = true })

local Aim = Legit:Section({ Name = "Aim Assist", Icon = "target", Side = 1 })
Aim:Toggle({ Name = "Enabled", Default = true })
Aim:Divider()
Aim:Toggle({ Name = "Draw FOV", Default = true, Color = Color3.fromRGB(255, 255, 255) })
Aim:Slider({ Name = "FOV", Min = 0, Max = 500, Default = 200, Suffix = "px" })
Aim:Slider({ Name = "Smoothness", Min = 0, Max = 100, Default = 40, Suffix = "%" })
Aim:Dropdown({ Name = "Hitpart", Options = { "Head", "Torso" }, Default = "Head" })
Aim:Toggle({ Name = "Visible Only", Default = true })
Aim:Toggle({ Name = "Team Check", Default = true })

local Recoil = Legit:Section({ Name = "Recoil Control", Icon = "wrench", Side = 1 })
Recoil:Toggle({ Name = "Enabled", Default = false })
Recoil:Slider({ Name = "Vertical", Min = 0, Max = 100, Default = 70, Suffix = "%" })

local Trigger = Legit:Section({ Name = "Triggerbot", Icon = "bullet", Side = 2 })
Trigger:Toggle({ Name = "Enabled", Default = false, Keybind = Enum.KeyCode.T })
Trigger:Divider()
Trigger:Slider({ Name = "Reaction Delay", Min = 0, Max = 500, Default = 60, Suffix = "ms" })
Trigger:Toggle({ Name = "Magnet Trigger", Default = false })
Trigger:Slider({ Name = "Magnet FOV", Min = 0, Max = 100, Default = 25 })
Trigger:Toggle({ Name = "Head Only", Default = true })

local PlayerESP = PlayersTab:Section({ Name = "Players", Icon = "smile", Side = 1 })
PlayerESP:Toggle({ Name = "Enabled", Default = false, Color = Color3.fromRGB(95, 136, 202) })
PlayerESP:Toggle({ Name = "Names", Default = true })
PlayerESP:Toggle({ Name = "Boxes", Default = true, Color = Color3.fromRGB(255, 255, 255) })
PlayerESP:Toggle({ Name = "Health", Default = true })

local World = Effects:Section({ Name = "Local", Icon = "smile", Side = 1 })
World:Toggle({ Name = "Remove Flash", Default = false })
World:Toggle({ Name = "Third Person", Default = false })
World:Slider({ Name = "Third Person Distance", Min = 0, Max = 30, Default = 12 })
World:Slider({ Name = "Ratio", Min = 0, Max = 200, Default = 100 })

local Lighting = Effects:Section({ Name = "World", Icon = "globe", Side = 2 })
Lighting:Toggle({ Name = "Ambience", Default = false, Color = Color3.fromRGB(180, 200, 255) })
Lighting:Toggle({ Name = "Fog", Default = false })
Lighting:Slider({ Name = "Fog Start", Min = 0, Max = 1000, Default = 100 })
Lighting:Slider({ Name = "Fog End", Min = 0, Max = 1000, Default = 800 })
Lighting:Slider({ Name = "Clock Time", Min = 0, Max = 24, Default = 14 })

local Move = Movement:Section({ Name = "Movement", Icon = "smile", Side = 1 })
Move:Toggle({ Name = "Speed", Default = true })
Move:Slider({ Name = "Speed Amount", Min = 16, Max = 200, Default = 50 })
Move:Dropdown({ Name = "Speed Type", Options = { "WalkSpeed", "CFrame", "Velocity" }, Default = "WalkSpeed" })
Move:Divider()
Move:Toggle({ Name = "Fly", Default = true, Keybind = Enum.KeyCode.F })
Move:Slider({ Name = "Fly Speed", Min = 1, Max = 300, Default = 60 })
Move:Toggle({ Name = "NoClip", Default = false, Keybind = Enum.KeyCode.N })

local Hop = Movement:Section({ Name = "Bunny Hop", Icon = "smile", Side = 2 })
Hop:Toggle({ Name = "Enabled", Default = false })
Hop:Dropdown({ Name = "Mode", Options = { "Auto Strafe", "Legit" }, Default = "Auto Strafe" })
Hop:Slider({ Name = "Strafe Strength", Min = 0, Max = 100, Default = 40, Suffix = "%" })

local ExploitMain = Exploits:Section({ Name = "Main", Icon = "bomb", Side = 1 })
ExploitMain:Toggle({ Name = "Double Tap", Default = false })
ExploitMain:Toggle({ Name = "Hide Shots", Default = false })

Plugins:Section({ Name = "Plugins", Icon = "file", Side = 1 }):Label({ Name = "No plugins loaded" })

Window:BuildSettings(Settings)

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local existing = PlayerGui:FindFirstChild("ParanoiaMobileToggle")
if existing then existing:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ParanoiaMobileToggle"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = PlayerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Size = UDim2.new(0, 108, 0, 32)
toggleBtn.Position = UDim2.new(0, 14, 0.5, -16)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.BackgroundTransparency = 0
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = ""
toggleBtn.AutoButtonColor = false
toggleBtn.Active = true
toggleBtn.Draggable = true
toggleBtn.Visible = UserInputService.TouchEnabled
toggleBtn.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = toggleBtn

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(65, 68, 80)
stroke.Thickness = 1
stroke.Parent = toggleBtn

local label = Instance.new("TextLabel")
label.Name = "Label"
label.Size = UDim2.new(1, -10, 1, 0)
label.Position = UDim2.new(0, 5, 0, 0)
label.BackgroundTransparency = 1
label.Text = "Toggle UI"
label.TextColor3 = Color3.fromRGB(232, 234, 245)
label.Font = Enum.Font.GothamMedium
label.TextSize = 12
label.TextXAlignment = Enum.TextXAlignment.Center
label.TextYAlignment = Enum.TextYAlignment.Center
label.Parent = toggleBtn

local open = false

local function setOpen(state)
	open = state
	stroke.Color = open and Color3.fromRGB(230, 160, 255) or Color3.fromRGB(65, 68, 80)
end

local function toggle()
	setOpen(not open)
	pcall(function()
		Window:SetVisible(open)
	end)
end

local debounce = false
local function onClick()
	if debounce then return end
	debounce = true
	task.delay(0.15, function() debounce = false end)
	toggle()
end

toggleBtn.MouseButton1Click:Connect(onClick)
toggleBtn.TouchTap:Connect(onClick)

toggleBtn.MouseEnter:Connect(function()
	TweenService:Create(stroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(230, 160, 255) }):Play()
end)
toggleBtn.MouseLeave:Connect(function()
	TweenService:Create(stroke, TweenInfo.new(0.15), { Color = open and Color3.fromRGB(230, 160, 255) or Color3.fromRGB(65, 68, 80) }):Play()
end)

if not UserInputService.TouchEnabled then
	gui.Enabled = false
end

return Window
