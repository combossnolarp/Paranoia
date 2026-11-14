local Blossom = ...

local ASSET_BASE = "https://raw.githubusercontent.com/combossnolarp/Paranoia/claude/wizardly-dijkstra-5vzykn/assets/"
local ASSET_FOLDER = "Paranoia/assets_v2"
local ICON_KEYS = {
	"rage", "ragebot", "silent", "antiaim", "targeting", "legit", "aimassist", "recoil", "trigger",
	"players", "effects", "local", "world", "movement", "speed", "bhop", "exploits", "plugins", "settings",
	"profiles", "autoload", "theming", "menu", "background",
}
local ASSET_LIST = {
	"logo_base.png", "logo_tint.png", "logo_anim_base.png", "logo_anim_tint.png",
	"fx/snow.png", "fx/flake.png", "fx/petal.png", "fx/blossom.png", "fx/leaf.png", "fx/rain.png", "fx/star.png", "fx/glow.png",
}
for _, key in ipairs(ICON_KEYS) do
	table.insert(ASSET_LIST, "icons/" .. key .. ".png")
end

local Assets = {}
do
	local getAsset = getcustomasset or getsynasset
	if getAsset and writefile and isfile then
		pcall(function()
			if makefolder and isfolder then
				if not isfolder("Paranoia") then makefolder("Paranoia") end
				if not isfolder(ASSET_FOLDER) then makefolder(ASSET_FOLDER) end
			end
		end)
		local pending = 0
		for _, path in ipairs(ASSET_LIST) do
			pending += 1
			task.spawn(function()
				local file = ASSET_FOLDER .. "/" .. (string.gsub(path, "/", "_"))
				local ok, result = pcall(function()
					if not isfile(file) then
						local data = game:HttpGet(ASSET_BASE .. path)
						if type(data) ~= "string" or string.sub(data, 2, 4) ~= "PNG" then return nil end
						writefile(file, data)
					end
					return getAsset(file)
				end)
				if ok and result then Assets[path] = result end
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 15 do
			task.wait()
		end
	end
end

local function Icon(key, fallback)
	return Assets["icons/" .. key .. ".png"] or fallback
end
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

		local function replacePlain(text, target, replacement)
			local first, last = string.find(text, target, 1, true)
			if not first then return text end
			return string.sub(text, 1, first - 1) .. replacement .. string.sub(text, last + 1)
		end

		src = replacePlain(src,
			"label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })\n\toptions.Y = Metrics.DropdownH - Metrics.InputH\n\tlocal dropdown = buildDropdown(self.Window, item.Frame, options)\n\tdropdown.Item = item",
			"item.Label = label(item.Frame, { Text = options.Name, Truncate = Enum.TextTruncate.AtEnd })\n\tlocal _, inlineColor = addInlineControls(self, item, options, options.Name)\n\toptions.Y = Metrics.DropdownH - Metrics.InputH\n\tlocal dropdown = buildDropdown(self.Window, item.Frame, options)\n\tdropdown.Item = item\n\tdropdown.ColorPicker = inlineColor")

		for name, key in pairs({ Profiles = "profiles", Autoload = "autoload", Theming = "theming", Menu = "menu" }) do
			local asset = Icon(key)
			if asset then
				src = replacePlain(src, 'Name = "' .. name .. '", Icon = "cube"', 'Name = "' .. name .. '", Icon = ' .. string.format("%q", asset))
			end
		end

		src = replace(src, "swatch%.BackgroundColor3 = value\n\t\tif win%.Picker%.Target == color and not win%.Picker%.Dragging then win%.Picker%.Sync%(%) end\n\t\tif not silent then fire%(color%.Callback, value, color%.Alpha%) end",
			"swatch.BackgroundColor3 = value\n\t\tswatch.BackgroundTransparency = color.Alpha\n\t\tif win.Picker.Target == color and not win.Picker.Dragging then win.Picker.Sync() end\n\t\tif not silent then fire(color.Callback, value, color.Alpha) end")

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

local function newLogoLayer(parent, image, zindex, tinted)
	local layer = Instance.new("ImageLabel")
	layer.BackgroundTransparency = 1
	layer.BorderSizePixel = 0
	layer.Size = UDim2.fromScale(1, 1)
	layer.ScaleType = Enum.ScaleType.Fit
	layer.Image = image or ""
	layer.ZIndex = zindex
	layer.Parent = parent
	if tinted then trackLogo(layer) end
	return layer
end

local function applyLogo(container, images)
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
	logo.Image = images.Base or ""
	logo.ZIndex = icon.ZIndex + 1
	logo.Parent = icon
	newLogoLayer(logo, images.Tint, icon.ZIndex + 2, true)
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
	local tintLayer = newLogoLayer(logo, nil, 1002, true)
	tintLayer.ImageTransparency = 1
	local layers = { logo, tintLayer }

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
		for _, layer in ipairs(layers) do
			Tweens:Create(layer, fadeInfo, { ImageTransparency = 0 }):Play()
		end
	end

	local function hide()
		if not shown then return end
		shown = false
		local myGeneration = generation
		Tweens:Create(overlay, fadeInfo, { BackgroundTransparency = 1 }):Play()
		Tweens:Create(tintLayer, fadeInfo, { ImageTransparency = 1 }):Play()
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
			local offset = Vector2.new((frame % ANIM_COLUMNS) * ANIM_W, math.floor(frame / ANIM_COLUMNS) * ANIM_H)
			for _, layer in ipairs(layers) do layer.ImageRectOffset = offset end
		end
	end)

	return function(anim, static)
		if anim.Base or anim.Tint then
			animated = true
			for _, layer in ipairs(layers) do
				layer.ScaleType = Enum.ScaleType.Stretch
				layer.ImageRectSize = Vector2.new(ANIM_W, ANIM_H)
				layer.ImageRectOffset = Vector2.zero
			end
			logo.Image = anim.Base or ""
			tintLayer.Image = anim.Tint or ""
		else
			logo.Image = static.Base or ""
			tintLayer.Image = static.Tint or ""
		end
	end
end

local setDragLogo = setupDragOverlay()

local staticLogo = { Base = Assets["logo_base.png"], Tint = Assets["logo_tint.png"] }
local animLogo = { Base = Assets["logo_anim_base.png"], Tint = Assets["logo_anim_tint.png"] }
if staticLogo.Base or staticLogo.Tint then
	applyLogo(Window.Sidebar, staticLogo)
	applyLogo(Window.Watermark, staticLogo)
end
if setDragLogo then setDragLogo(animLogo, staticLogo) end

local NavMetrics = Blossom.Metrics or {}
local NAV_PAD = NavMetrics.Pad or 10
local NAV_TAB_H = NavMetrics.TabH or 28
local NAV_TAB_PITCH = NavMetrics.TabPitch or 32
local NAV_CAT_TO_TAB = NavMetrics.CategoryToTab or 25
local NAV_TAB_TO_CAT = NavMetrics.TabToCategory or 25
local NAV_FIRST_CAT = NavMetrics.FirstCategory or 56
local NAV_CHILD_PITCH = 30
local NAV_CHILD_INDENT = 12
local NavTweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local NavTweens = game:GetService("TweenService")

local Nav = { Entries = {}, Groups = {}, ParentOf = {}, KnownLabels = {}, Open = nil }

local function navMove(inst, position, animated)
	if animated then
		NavTweens:Create(inst, NavTweenInfo, { Position = position }):Play()
	else
		inst.Position = position
	end
end

local function navLayout(animated)
	local y, hasTabs, afterCategory = NAV_FIRST_CAT, false, false
	local function placeTab(tab, tabY)
		tab.Y = tabY - NAV_TAB_H / 2
		navMove(tab.Button, UDim2.fromOffset(NAV_PAD, tab.Y), animated)
	end
	for _, entry in ipairs(Nav.Entries) do
		if entry.Kind == "Category" then
			y += hasTabs and NAV_TAB_TO_CAT or 0
			afterCategory = true
			if entry.Label then
				navMove(entry.Label, UDim2.new(entry.Label.Position.X.Scale, entry.Label.Position.X.Offset, 0, y - 6), animated)
			end
		else
			y += afterCategory and NAV_CAT_TO_TAB or NAV_TAB_PITCH
			afterCategory, hasTabs = false, true
			placeTab(entry.Tab, y)
			if entry.Kind == "Group" then
				local open = Nav.Open == entry
				local parentPosition = UDim2.fromOffset(NAV_PAD, entry.Tab.Y)
				if animated then
					NavTweens:Create(entry.Chevron, NavTweenInfo, { Rotation = open and 0 or -90 }):Play()
				else
					entry.Chevron.Rotation = open and 0 or -90
				end
				for _, child in ipairs(entry.Children) do
					if open then
						y += NAV_CHILD_PITCH
						if not child.Button.Visible then
							child.Button.Position = parentPosition
							child.Button.Visible = true
						end
						placeTab(child, y)
					else
						child.Button.Visible = false
						child.Y = entry.Tab.Y
						child.Button.Position = parentPosition
					end
				end
			end
		end
	end
	return y
end

local baseSelectTab = Window.SelectTab
Window.SelectTab = function(self, tab, instant)
	local group = Nav.Groups[tab]
	if group and #group.Children > 0 then
		tab = group.Last or group.Children[1]
	end
	local owner = Nav.ParentOf[tab]
	if owner then owner.Last = tab end
	if Nav.Open ~= owner then
		Nav.Open = owner
		navLayout(not instant)
	end
	return baseSelectTab(self, tab, instant)
end

local function Category(name)
	Window:Category(name)
	local found
	for _, child in ipairs(Window.Sidebar:GetChildren()) do
		if child:IsA("TextLabel") and not Nav.KnownLabels[child] and string.lower(child.Text) == string.lower(name) then
			found = child
		end
	end
	if found then Nav.KnownLabels[found] = true end
	table.insert(Nav.Entries, { Kind = "Category", Label = found })
end

local function Tab(options)
	local tab = Window:Tab(options)
	table.insert(Nav.Entries, { Kind = "Tab", Tab = tab })
	return tab
end

local function makeChevron(button, label)
	local chevron = Instance.new("Frame")
	chevron.Name = "Chevron"
	chevron.BackgroundTransparency = 1
	chevron.AnchorPoint = Vector2.new(0.5, 0.5)
	chevron.Position = UDim2.new(1, -12, 0.5, 0)
	chevron.Size = UDim2.fromOffset(10, 10)
	chevron.Rotation = -90
	chevron.ZIndex = button.ZIndex + 1
	chevron.Parent = button
	local bars = {}
	for index, rotation in ipairs({ 45, -45 }) do
		local bar = Instance.new("Frame")
		bar.BorderSizePixel = 0
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.new(0.5, index == 1 and -2 or 2, 0.5, 0)
		bar.Size = UDim2.fromOffset(6, 2)
		bar.Rotation = rotation
		bar.ZIndex = chevron.ZIndex
		bar.Parent = chevron
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = bar
		table.insert(bars, bar)
	end
	local function paint()
		for _, bar in ipairs(bars) do
			bar.BackgroundColor3 = label and label.TextColor3 or Color3.new(1, 1, 1)
		end
	end
	paint()
	if label then label:GetPropertyChangedSignal("TextColor3"):Connect(paint) end
	return chevron
end

local function Group(options, children)
	local parent = Window:Tab(options)
	local group = { Kind = "Group", Tab = parent, Children = {}, Last = nil }
	group.Chevron = makeChevron(parent.Button, parent.Label)
	for _, childOptions in ipairs(children) do
		local child = Window:Tab(childOptions)
		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, NAV_CHILD_INDENT)
		padding.Parent = child.Button
		child.Button.Visible = false
		Nav.ParentOf[child] = group
		table.insert(group.Children, child)
	end
	Nav.Groups[parent] = group
	table.insert(Nav.Entries, group)
	if Window.CurrentTab == parent then
		Window:SelectTab(group.Children[1], true)
	end
	return table.unpack(group.Children)
end

local function finishNav()
	local current = Window.CurrentTab
	Nav.Open = current and Nav.ParentOf[current] or nil
	local openY = navLayout(false)
	local collapsedY = openY
	if Nav.Open then collapsedY -= #Nav.Open.Children * NAV_CHILD_PITCH end
	local most = 0
	for _, entry in ipairs(Nav.Entries) do
		if entry.Kind == "Group" then most = math.max(most, #entry.Children) end
	end
	Window.SidebarY = collapsedY + most * NAV_CHILD_PITCH
	if current then
		pcall(function() Window.Indicator.Position = UDim2.fromOffset(NAV_PAD + 1, current.Y + 1) end)
	end
	pcall(function()
		local needed = Window:_minHeight()
		if Window.Height < needed then Window:SetSize(Window.Width, needed) end
	end)
end

Category("Combat")
local RageMain, RageSilent, RageAntiAim = Group({ Name = "Rage", Icon = Icon("rage", "target") }, {
	{ Name = "Ragebot", Icon = Icon("ragebot", "robot") },
	{ Name = "Silent Aim", Icon = Icon("silent", "bullet") },
	{ Name = "Anti Aim", Icon = Icon("antiaim", "wrench") },
})
local LegitAim, LegitRecoil, LegitTrigger = Group({ Name = "Legit", Icon = Icon("legit", "bullet") }, {
	{ Name = "Aim Assist", Icon = Icon("aimassist", "target") },
	{ Name = "Recoil", Icon = Icon("recoil", "wrench") },
	{ Name = "Triggerbot", Icon = Icon("trigger", "bullet") },
})
Category("Visuals")
local PlayersTab = Tab({ Name = "Players", Icon = Icon("players", "smile") })
local EffectsLocal, EffectsWorld = Group({ Name = "Effects", Icon = Icon("effects", "globe") }, {
	{ Name = "Local", Icon = Icon("local", "smile") },
	{ Name = "World", Icon = Icon("world", "globe") },
})
Category("Player")
local MovementMain, MovementHop = Group({ Name = "Movement", Icon = Icon("movement", "smile") }, {
	{ Name = "Speed & Fly", Icon = Icon("speed", "smile") },
	{ Name = "Bunny Hop", Icon = Icon("bhop", "smile") },
})
local Exploits = Tab({ Name = "Exploits", Icon = Icon("exploits", "bomb") })
local Plugins = Tab({ Name = "Plugins", Icon = Icon("plugins", "file") })
local Settings = Tab({ Name = "Settings", Icon = Icon("settings", "gear") })

local Ragebot = RageMain:Section({ Name = "Ragebot", Icon = Icon("ragebot", "robot"), Side = 1 })
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

local Targeting = RageMain:Section({ Name = "Targeting", Icon = Icon("targeting", "bullet"), Side = 2 })
Targeting:Dropdown({ Name = "Hitboxes", Options = { "Head", "Torso", "Arms", "Legs" }, Default = { "Head", "Torso" }, Multi = true })

local Silent = RageSilent:Section({ Name = "Silent Aim", Icon = Icon("silent", "bullet"), Side = 1 })
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

local AntiAim = RageAntiAim:Section({ Name = "Anti Aim", Icon = Icon("antiaim", "wrench"), Description = "Desync & angles", Side = 1 })
AntiAim:Toggle({ Name = "Enabled", Default = false, Keybind = Enum.KeyCode.Z })
AntiAim:Divider()
AntiAim:Dropdown({ Name = "Pitch", Options = { "None", "Down", "Up", "Zero", "Random" }, Default = "Zero" })
AntiAim:Dropdown({ Name = "Yaw", Options = { "Backward", "Spin", "Jitter" }, Default = "Backward" })
AntiAim:Slider({ Name = "Spin Speed", Min = 0, Max = 100, Default = 20 })
AntiAim:Slider({ Name = "Jitter Range", Min = 0, Max = 180, Default = 45 })
AntiAim:Divider()
AntiAim:Toggle({ Name = "Fake Duck", Default = false })
AntiAim:Toggle({ Name = "Freestanding", Default = true })

local Aim = LegitAim:Section({ Name = "Aim Assist", Icon = Icon("aimassist", "target"), Side = 1 })
Aim:Toggle({ Name = "Enabled", Default = true })
Aim:Divider()
Aim:Toggle({ Name = "Draw FOV", Default = true, Color = Color3.fromRGB(255, 255, 255) })
Aim:Slider({ Name = "FOV", Min = 0, Max = 500, Default = 200, Suffix = "px" })
Aim:Slider({ Name = "Smoothness", Min = 0, Max = 100, Default = 40, Suffix = "%" })
Aim:Dropdown({ Name = "Hitpart", Options = { "Head", "Torso" }, Default = "Head" })
Aim:Toggle({ Name = "Visible Only", Default = true })
Aim:Toggle({ Name = "Team Check", Default = true })

local Recoil = LegitRecoil:Section({ Name = "Recoil Control", Icon = Icon("recoil", "wrench"), Side = 1 })
Recoil:Toggle({ Name = "Enabled", Default = false })
Recoil:Slider({ Name = "Vertical", Min = 0, Max = 100, Default = 70, Suffix = "%" })

local Trigger = LegitTrigger:Section({ Name = "Triggerbot", Icon = Icon("trigger", "bullet"), Side = 1 })
Trigger:Toggle({ Name = "Enabled", Default = false, Keybind = Enum.KeyCode.T })
Trigger:Divider()
Trigger:Slider({ Name = "Reaction Delay", Min = 0, Max = 500, Default = 60, Suffix = "ms" })
Trigger:Toggle({ Name = "Magnet Trigger", Default = false })
Trigger:Slider({ Name = "Magnet FOV", Min = 0, Max = 100, Default = 25 })
Trigger:Toggle({ Name = "Head Only", Default = true })

local PlayerESP = PlayersTab:Section({ Name = "Players", Icon = Icon("players", "smile"), Side = 1 })
PlayerESP:Toggle({ Name = "Enabled", Default = false, Color = Color3.fromRGB(95, 136, 202) })
PlayerESP:Toggle({ Name = "Names", Default = true })
PlayerESP:Toggle({ Name = "Boxes", Default = true, Color = Color3.fromRGB(255, 255, 255) })
PlayerESP:Toggle({ Name = "Health", Default = true })

local World = EffectsLocal:Section({ Name = "Local", Icon = Icon("local", "smile"), Side = 1 })
World:Toggle({ Name = "Remove Flash", Default = false })
World:Toggle({ Name = "Third Person", Default = false })
World:Slider({ Name = "Third Person Distance", Min = 0, Max = 30, Default = 12 })
World:Slider({ Name = "Ratio", Min = 0, Max = 200, Default = 100 })

local Lighting = EffectsWorld:Section({ Name = "World", Icon = Icon("world", "globe"), Side = 1 })
Lighting:Toggle({ Name = "Ambience", Default = false, Color = Color3.fromRGB(180, 200, 255) })
Lighting:Toggle({ Name = "Fog", Default = false })
Lighting:Slider({ Name = "Fog Start", Min = 0, Max = 1000, Default = 100 })
Lighting:Slider({ Name = "Fog End", Min = 0, Max = 1000, Default = 800 })
Lighting:Slider({ Name = "Clock Time", Min = 0, Max = 24, Default = 14 })

local Move = MovementMain:Section({ Name = "Movement", Icon = Icon("speed", "smile"), Side = 1 })
Move:Toggle({ Name = "Speed", Default = true })
Move:Slider({ Name = "Speed Amount", Min = 16, Max = 200, Default = 50 })
Move:Dropdown({ Name = "Speed Type", Options = { "WalkSpeed", "CFrame", "Velocity" }, Default = "WalkSpeed" })
Move:Divider()
Move:Toggle({ Name = "Fly", Default = true, Keybind = Enum.KeyCode.F })
Move:Slider({ Name = "Fly Speed", Min = 1, Max = 300, Default = 60 })
Move:Toggle({ Name = "NoClip", Default = false, Keybind = Enum.KeyCode.N })

local Hop = MovementHop:Section({ Name = "Bunny Hop", Icon = Icon("bhop", "smile"), Side = 1 })
Hop:Toggle({ Name = "Enabled", Default = false })
Hop:Dropdown({ Name = "Mode", Options = { "Auto Strafe", "Legit" }, Default = "Auto Strafe" })
Hop:Slider({ Name = "Strafe Strength", Min = 0, Max = 100, Default = 40, Suffix = "%" })

local ExploitMain = Exploits:Section({ Name = "Main", Icon = Icon("exploits", "bomb"), Side = 1 })
ExploitMain:Toggle({ Name = "Double Tap", Default = false })
ExploitMain:Toggle({ Name = "Hide Shots", Default = false })

Plugins:Section({ Name = "Plugins", Icon = Icon("plugins", "file"), Side = 1 }):Label({ Name = "No plugins loaded" })

Window:BuildSettings(Settings)
finishNav()

do
	local EXTRA_FONTS = {
		{ "Fortnite Style", "Oswald" },
		{ "Phantom Forces Style", "TitilliumWeb" },
		{ "Call of Duty Style", "Sarpanch" },
		{ "Borderlands Style", "Bangers" },
		{ "Marshmello Style", "FredokaOne" },
		{ "Minecraft Style", "Arcade" },
		{ "Halo Style", "Michroma" },
		{ "Valorant Style", "RobotoCondensed" },
		{ "Cartoon", "LuckiestGuy" },
		{ "Graffiti", "PermanentMarker" },
		{ "Horror", "Creepster" },
		{ "Typewriter", "SpecialElite" },
		{ "Handwritten", "PatrickHand" },
		{ "Gothic", "GrenzeGotisch" },
	}
	local fonts = Blossom.Fonts
	local added = {}
	if fonts then
		for _, entry in ipairs(EXTRA_FONTS) do
			local ok, family = pcall(function()
				return Font.fromEnum(Enum.Font[entry[2]]).Family
			end)
			if ok and family then
				fonts[entry[1]] = family
				table.insert(added, entry[1])
			end
		end
	end
	if #added > 0 then
		for _, object in pairs(Window.FlagOwners or {}) do
			if type(object) == "table" and type(object.Options) == "table" and type(object.SetOptions) == "function" then
				local isFontList = table.find(object.Options, "Inter") and table.find(object.Options, "Arimo")
				if isFontList then
					local options = table.clone(object.Options)
					for _, name in ipairs(added) do
						if not table.find(options, name) then table.insert(options, name) end
					end
					object:SetOptions(options)
				end
			end
		end
	end
end

local MenuEffects = {}
do
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local FxTweens = game:GetService("TweenService")

	local state = { Blur = false, Effect = "None", Color = Color3.new(1, 1, 1), Amount = 50, Size = 1, Speed = 1, Glow = 40, ShowClosed = false }
	local MAX_PARTICLES = 220
	local BLUR_SIZE = 18
	local FALLBACK_IMAGE = "rbxasset://textures/particles/sparkles_main.dds"

	local PRESETS = {
		Snow = Color3.fromRGB(255, 255, 255),
		Blossoms = Color3.fromRGB(255, 183, 213),
		Leaves = Color3.fromRGB(236, 138, 58),
		Rain = Color3.fromRGB(170, 200, 255),
		Fireflies = Color3.fromRGB(255, 214, 110),
		Embers = Color3.fromRGB(255, 120, 50),
		Stars = Color3.fromRGB(255, 255, 255),
	}
	local EFFECT_ORDER = { "None", "Snow", "Blossoms", "Leaves", "Rain", "Fireflies", "Embers", "Stars" }

	local function img(path)
		return Assets["fx/" .. path .. ".png"] or FALLBACK_IMAGE
	end

	local oldBlur = Lighting:FindFirstChild("ParanoiaBlur")
	if oldBlur then oldBlur:Destroy() end
	local blur = Instance.new("BlurEffect")
	blur.Name = "ParanoiaBlur"
	blur.Size = 0
	blur.Parent = Lighting
	local blurTarget = -1

	local function updateBlur()
		if blur.Parent ~= Lighting then
			pcall(function() blur.Parent = Lighting end)
			blurTarget = -1
		end
		local target = (state.Blur and Window.Visible) and BLUR_SIZE or 0
		if target == blurTarget then return end
		blurTarget = target
		FxTweens:Create(blur, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = target }):Play()
	end

	local screenParent = Window.Screen and Window.Screen.Parent
	if screenParent then
		local old = screenParent:FindFirstChild("ParanoiaEffects")
		if old then old:Destroy() end
	end
	local layer = Instance.new("ScreenGui")
	layer.Name = "ParanoiaEffects"
	layer.IgnoreGuiInset = true
	layer.ResetOnSpawn = false
	layer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	layer.DisplayOrder = math.max((Window.Screen and Window.Screen.DisplayOrder or 100) - 1, 0)
	layer.Enabled = false
	layer.Parent = screenParent or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local particles = {}
	local rng = Random.new()

	local function newParticle()
		local glow = Instance.new("ImageLabel")
		glow.BackgroundTransparency = 1
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Image = img("glow")
		glow.ImageTransparency = 1
		glow.Visible = false
		glow.Parent = layer
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.ImageTransparency = 1
		image.Visible = false
		image.Parent = layer
		return { Image = image, Glow = glow }
	end

	local function tinted(base, kind)
		if kind == "Leaves" or kind == "Blossoms" then
			local h, s, v = base:ToHSV()
			h = (h + rng:NextNumber(-0.035, 0.035)) % 1
			s = math.clamp(s * rng:NextNumber(0.85, 1.1), 0, 1)
			v = math.clamp(v * rng:NextNumber(0.82, 1), 0, 1)
			return Color3.fromHSV(h, s, v)
		end
		return base:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.12))
	end

	local function spawnParticle(p, kind, w, h, anywhere)
		local depth = 0.3 + 0.7 * rng:NextNumber() ^ 1.6
		p.Depth = depth
		p.Phase = rng:NextNumber(0, math.pi * 2)
		p.Rot = rng:NextNumber(0, 360)
		p.RotSpeed = 0
		p.SwayAmp, p.SwayFreq, p.FlipFreq, p.Twinkle = 0, 0, 0, 0
		p.Vx, p.Vy = 0, 0
		p.Flip = false
		p.Kind = kind
		local margin = 40
		p.X = rng:NextNumber(-margin, w + margin)
		p.Y = anywhere and rng:NextNumber(-margin, h + margin) or -margin - rng:NextNumber(0, 60)
		local image
		if kind == "Snow" then
			local crystal = rng:NextNumber() < 0.18
			image = crystal and img("flake") or img("snow")
			p.W = (crystal and rng:NextNumber(10, 17) or rng:NextNumber(3, 8)) * (0.55 + depth * 0.65)
			p.H = p.W
			p.Vy = rng:NextNumber(22, 48) * (0.45 + depth)
			p.Vx = rng:NextNumber(4, 14)
			p.SwayAmp, p.SwayFreq = rng:NextNumber(10, 32), rng:NextNumber(0.25, 0.8)
			p.RotSpeed = crystal and rng:NextNumber(-40, 40) or 0
			p.Alpha = 0.45 + 0.55 * depth
			p.GlowScale = 2.6
		elseif kind == "Blossoms" then
			local flower = rng:NextNumber() < 0.28
			image = flower and img("blossom") or img("petal")
			p.W = (flower and rng:NextNumber(14, 22) or rng:NextNumber(9, 15)) * (0.55 + depth * 0.65)
			p.H = flower and p.W or p.W * 1.25
			p.Vy = rng:NextNumber(26, 50) * (0.45 + depth)
			p.Vx = rng:NextNumber(18, 46) * (0.5 + depth)
			p.SwayAmp, p.SwayFreq = rng:NextNumber(14, 36), rng:NextNumber(0.3, 0.9)
			p.RotSpeed = rng:NextNumber(-110, 110)
			p.FlipFreq, p.Flip = rng:NextNumber(0.8, 2.2), true
			p.Alpha = 0.6 + 0.4 * depth
			p.GlowScale = 2.2
			p.X = anywhere and p.X or rng:NextNumber(-w * 0.35, w)
		elseif kind == "Leaves" then
			image = img("leaf")
			p.W = rng:NextNumber(12, 20) * (0.55 + depth * 0.65)
			p.H = p.W * 1.45
			p.Vy = rng:NextNumber(34, 70) * (0.45 + depth)
			p.Vx = rng:NextNumber(-12, 34) * (0.5 + depth)
			p.SwayAmp, p.SwayFreq = rng:NextNumber(24, 60), rng:NextNumber(0.3, 0.75)
			p.RotSpeed = rng:NextNumber(-150, 150)
			p.FlipFreq, p.Flip = rng:NextNumber(0.6, 1.6), true
			p.Alpha = 0.7 + 0.3 * depth
			p.GlowScale = 2
		elseif kind == "Rain" then
			image = img("rain")
			p.W = 1.5 + depth * 1.6
			p.H = rng:NextNumber(26, 46) * (0.5 + depth * 0.7)
			p.Vy = rng:NextNumber(720, 980) * (0.55 + depth * 0.6)
			p.Vx = p.Vy * 0.12
			p.Rot = -math.deg(math.atan2(p.Vx, p.Vy))
			p.Alpha = 0.2 + 0.4 * depth
			p.GlowScale = 0
			p.X = anywhere and p.X or rng:NextNumber(-w * 0.15, w)
		elseif kind == "Fireflies" then
			image = img("snow")
			p.W = rng:NextNumber(3, 6) * (0.6 + depth * 0.6)
			p.H = p.W
			p.Y = rng:NextNumber(-margin, h + margin)
			p.Heading = rng:NextNumber(0, math.pi * 2)
			p.Speed = rng:NextNumber(10, 30) * (0.5 + depth)
			p.Twinkle = rng:NextNumber(0.6, 1.6)
			p.Alpha = 0.7 + 0.3 * depth
			p.GlowScale = 5
		elseif kind == "Embers" then
			image = img("snow")
			p.W = rng:NextNumber(2.5, 5.5) * (0.6 + depth * 0.6)
			p.H = p.W
			p.Y = anywhere and rng:NextNumber(-margin, h + margin) or h + margin + rng:NextNumber(0, 60)
			p.Vy = -rng:NextNumber(40, 95) * (0.45 + depth)
			p.SwayAmp, p.SwayFreq = rng:NextNumber(8, 26), rng:NextNumber(0.5, 1.3)
			p.Twinkle = rng:NextNumber(4, 9)
			p.Alpha = 0.6 + 0.4 * depth
			p.GlowScale = 4.5
		else
			image = img("star")
			p.W = rng:NextNumber(6, 15) * (0.5 + depth * 0.6)
			p.H = p.W
			p.Y = rng:NextNumber(-margin, h + margin)
			p.Vx = 3 + 5 * depth
			p.Twinkle = rng:NextNumber(0.5, 1.8)
			p.Rot = 0
			p.Alpha = 0.5 + 0.5 * depth
			p.GlowScale = 3
		end
		p.Image.Image = image
		p.Color = tinted(state.Color, kind)
		p.Image.ImageColor3 = p.Color
		p.Glow.ImageColor3 = p.Color
		local z = 2 + math.floor(depth * 10) * 2
		p.Image.ZIndex = z
		p.Glow.ZIndex = z - 1
	end

	local alphaMul = 0
	local clock = 0
	local needsReset = true

	local function viewport()
		local size = layer.AbsoluteSize
		if size.X < 2 then
			local camera = workspace.CurrentCamera
			size = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		end
		return size.X, size.Y
	end

	local function resetAll()
		local w, h = viewport()
		for _, p in ipairs(particles) do
			spawnParticle(p, state.Effect, w, h, true)
		end
		needsReset = false
	end

	local function step(dt)
		updateBlur()
		local active = state.Effect ~= "None" and (Window.Visible or state.ShowClosed)
		if active then
			alphaMul = math.min(1, alphaMul + dt / 0.4)
		else
			alphaMul = math.max(0, alphaMul - dt / 0.3)
		end
		if alphaMul <= 0 and not active then
			if layer.Enabled then
				layer.Enabled = false
				for _, p in ipairs(particles) do
					p.Image.Visible = false
					p.Glow.Visible = false
				end
			end
			return
		end
		layer.Enabled = true
		dt = math.min(dt, 0.1) * state.Speed
		clock += dt
		local w, h = viewport()
		local count = math.floor(state.Amount / 100 * MAX_PARTICLES + 0.5)
		while #particles < count do
			local p = newParticle()
			table.insert(particles, p)
			spawnParticle(p, state.Effect, w, h, true)
		end
		if needsReset then resetAll() end
		local glowAmount = state.Glow / 100
		local sizeScale = state.Size
		local margin = 50
		for index, p in ipairs(particles) do
			local image, glow = p.Image, p.Glow
			if index > count then
				image.Visible = false
				glow.Visible = false
				continue
			end
			local kind = p.Kind
			local alpha = p.Alpha
			local drawX, drawY = p.X, p.Y
			local width, height = p.W, p.H
			if kind == "Fireflies" then
				p.Heading += math.sin(clock * 0.9 + p.Phase) * 1.8 * dt
				p.X += math.cos(p.Heading) * p.Speed * dt
				p.Y += math.sin(p.Heading) * p.Speed * dt
				drawX, drawY = p.X, p.Y
				local pulse = 0.5 + 0.5 * math.sin(clock * p.Twinkle * 2 + p.Phase)
				alpha *= 0.15 + 0.85 * pulse * pulse
			elseif kind == "Stars" then
				p.X += p.Vx * dt
				drawX = p.X
				local pulse = 0.5 + 0.5 * math.sin(clock * p.Twinkle * 2 + p.Phase)
				alpha *= 0.2 + 0.8 * pulse ^ 3
				width = p.W * (0.75 + 0.35 * pulse)
				height = width
			else
				p.X += p.Vx * dt
				p.Y += p.Vy * dt
				if kind == "Leaves" then
					p.X += math.sin(clock * 0.35 + p.Phase * 0.2) * 22 * p.Depth * dt
				end
				drawX = p.X + math.sin(clock * p.SwayFreq * math.pi * 2 + p.Phase) * p.SwayAmp
				p.Rot += p.RotSpeed * dt
				if p.Flip then
					width = p.W * (0.2 + 0.8 * math.abs(math.cos(clock * p.FlipFreq + p.Phase)))
				end
				if kind == "Embers" then
					local flicker = 0.65 + 0.35 * math.sin(clock * p.Twinkle + p.Phase)
					alpha *= flicker * math.clamp(p.Y / (h * 0.7), 0, 1)
				end
			end
			if kind == "Embers" then
				if p.Y < -margin then spawnParticle(p, kind, w, h, false) end
			elseif kind == "Fireflies" or kind == "Stars" then
				if p.Y < -margin then p.Y += h + margin * 2 elseif p.Y > h + margin then p.Y -= h + margin * 2 end
			elseif p.Y > h + margin then
				spawnParticle(p, kind, w, h, false)
			end
			if p.X > w + margin then p.X -= w + margin * 2 elseif p.X < -margin then p.X += w + margin * 2 end

			width *= sizeScale
			height *= sizeScale
			local visibleAlpha = alpha * alphaMul
			image.Visible = true
			image.Position = UDim2.fromOffset(drawX, drawY)
			image.Size = UDim2.fromOffset(width, height)
			image.Rotation = p.Rot
			image.ImageTransparency = 1 - visibleAlpha
			if glowAmount > 0 and p.GlowScale > 0 and sizeScale > 0 then
				local size = math.max(p.W, p.H) * sizeScale * (p.GlowScale * (0.6 + glowAmount))
				glow.Visible = true
				glow.Position = image.Position
				glow.Size = UDim2.fromOffset(size, size)
				glow.ImageTransparency = 1 - math.clamp(visibleAlpha * glowAmount * 0.6, 0, 1)
			else
				glow.Visible = false
			end
		end
	end

	RunService.RenderStepped:Connect(step)

	local colorPicker
	local lastColorChange = -1

	local function setColor(color)
		state.Color = color
		lastColorChange = os.clock()
		for _, p in ipairs(particles) do
			p.Color = tinted(color, p.Kind)
			p.Image.ImageColor3 = p.Color
			p.Glow.ImageColor3 = p.Color
		end
	end

	local function sameColor(a, b)
		return math.abs(a.R - b.R) < 0.01 and math.abs(a.G - b.G) < 0.01 and math.abs(a.B - b.B) < 0.01
	end

	local function setEffect(name)
		local previous = state.Effect
		state.Effect = name
		needsReset = true
		local preset = PRESETS[name]
		if not (colorPicker and preset) then return end
		local wasPreset = PRESETS[previous] == nil or sameColor(state.Color, PRESETS[previous])
		if not wasPreset then return end
		local requested = os.clock()
		task.defer(function()
			if state.Effect ~= name or lastColorChange >= requested - 0.05 then return end
			colorPicker:Set(preset)
		end)
	end

	local menuSection
	for _, section in pairs(Window.Sections or {}) do
		if section.Name == "Menu" and section.Tab == Settings then
			menuSection = section
		end
	end

	if menuSection then
		menuSection:Divider()
		menuSection:Toggle({ Name = "Blur", Default = false, Callback = function(value) state.Blur = value end })
		local effectDropdown = menuSection:Dropdown({
			Name = "Background Effect", Options = EFFECT_ORDER, Default = "None",
			Color = state.Color, ColorCallback = setColor,
			Callback = setEffect,
		})
		colorPicker = effectDropdown and effectDropdown.ColorPicker
		if not colorPicker then
			colorPicker = menuSection:Colorpicker({ Name = "Effect Color", Default = state.Color, Callback = setColor })
		end
		menuSection:Slider({ Name = "Amount", Min = 0, Max = 100, Default = state.Amount, Suffix = "%", Callback = function(value) state.Amount = value end })
		menuSection:Slider({ Name = "Size", Min = 0, Max = 10, Default = state.Size, Decimals = 1, Suffix = "x", Callback = function(value) state.Size = value end })
		menuSection:Slider({ Name = "Speed", Min = 0, Max = 10, Default = state.Speed, Decimals = 1, Suffix = "x", Callback = function(value) state.Speed = value end })
		menuSection:Slider({ Name = "Glow", Min = 0, Max = 100, Default = state.Glow, Suffix = "%", Callback = function(value) state.Glow = value end })
		menuSection:Toggle({ Name = "Show When Menu Is Closed", Default = false, Callback = function(value) state.ShowClosed = value end })
	end

	MenuEffects.State = state
	MenuEffects.SetEffect = setEffect
	MenuEffects.SetColor = setColor
end

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
